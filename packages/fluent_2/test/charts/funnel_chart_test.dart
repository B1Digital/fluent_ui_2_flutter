import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// The default orientation is the one the documentation gets wrong:
/// `FunnelChart.types.ts:98` says `'horizontal'`, but the destructured default
/// at `FunnelChart.tsx:28` is `'vertical'`, and the code wins.
void main() {
  const key = Key('funnel');
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  const data = <FluentFunnelDataPoint>[
    FluentFunnelDataPoint(
      stage: 'Visits',
      value: 100,
      color: Color(0xFF0F6CBD),
    ),
    FluentFunnelDataPoint(
      stage: 'Signups',
      value: 60,
      color: Color(0xFF115EA3),
    ),
    FluentFunnelDataPoint(stage: 'Sales', value: 20, color: Color(0xFF0C3B5E)),
  ];

  Future<void> pump(
    WidgetTester tester,
    Widget chart, {
    TextDirection direction = TextDirection.ltr,
    // FunnelChart.tsx:462-463 — upstream's own defaults, so the derived
    // numbers below read the same as the source.
    Size box = const Size(350, 500),
    FluentThemeData? withTheme,
  }) => tester.pumpWidget(
    FluentApp(
      theme: withTheme ?? theme,
      home: Directionality(
        textDirection: direction,
        child: Center(
          child: SizedBox(width: box.width, height: box.height, child: chart),
        ),
      ),
    ),
  );

  /// The plot painter of the chart under [key].
  ///
  /// `.first` is the plot: the title above it is a `Text` and the legend below
  /// it only reaches a `CustomPaint` inside its swatches, both of which come
  /// after the plot in depth-first order.
  FluentFunnelChartPainter painterOf(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find
                    .descendant(
                      of: find.byKey(key),
                      matching: find.byType(CustomPaint),
                    )
                    .first,
              )
              .painter!
          as FluentFunnelChartPainter;

  /// The per-segment focus stops, which carry a `'funnel-segment-'` key so they
  /// can be told apart from the legend's own focus nodes.
  Iterable<Focus> segmentFocuses(WidgetTester tester) =>
      tester.widgetList<Focus>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Focus &&
              widget.key is ValueKey<String> &&
              (widget.key! as ValueKey<String>).value.startsWith(
                'funnel-segment-',
              ),
        ),
      );

  testWidgets('the default orientation is vertical', (tester) async {
    await pump(tester, const FluentFunnelChart(key: key, data: data));
    final first = painterOf(tester).segments.first.geometry.path!.getBounds();
    final second = painterOf(tester).segments[1].geometry.path!.getBounds();
    expect(
      second.top,
      greaterThan(first.top),
      reason:
          'FunnelChart.tsx:28 destructures orientation with a default of '
          "'vertical', so stages stack downwards. The 'horizontal' at "
          'FunnelChart.types.ts:98 is documentation only.',
    );
  });

  testWidgets('the plot occupies four fifths of the width, centred', (
    tester,
  ) async {
    await pump(tester, const FluentFunnelChart(key: key, data: data));
    expect(
      painterOf(tester).funnelWidth,
      closeTo(280, 1e-9),
      reason: 'FunnelChart.tsx:473 — 350 * 0.8.',
    );
  });

  testWidgets('the plot starts 40 below the top even with no title', (
    tester,
  ) async {
    await pump(tester, const FluentFunnelChart(key: key, data: data));
    expect(
      painterOf(tester).segments.first.geometry.path!.getBounds().top,
      closeTo(0, 1e-9),
      reason:
          'The painter is offset by funnelMarginTop, so within its own '
          'coordinate space the first stage starts at zero; '
          'FunnelChart.tsx:465-472 reserves 40 above it whether or not a title '
          'is drawn.',
    );
  });

  testWidgets('right-to-left mirrors the path x values about the funnel width', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentFunnelChart(
        key: key,
        orientation: FluentFunnelOrientation.horizontal,
        data: data,
      ),
    );
    final ltr = painterOf(tester).segments.first.geometry.path!.getBounds();
    await pump(
      tester,
      const FluentFunnelChart(
        key: key,
        orientation: FluentFunnelOrientation.horizontal,
        data: data,
      ),
      direction: TextDirection.rtl,
    );
    final rtl = painterOf(tester).segments.first.geometry.path!.getBounds();
    expect(
      rtl.left,
      // 1e-4, not the 1e-9 the rest of this file uses: the mirrored path goes
      // through `Path.transform`, and Skia stores path points as float32, so a
      // coordinate near 187 comes back with about 1e-5 of rounding.
      closeTo(280 - ltr.right, 1e-4),
      reason:
          'FunnelChart.tsx:505 wraps the plot in '
          'translate(offsetX + funnelWidth) scale(-1,1), which mirrors every x '
          'about funnelWidth. The horizontal generator itself ignores isRtl.',
    );
  });

  testWidgets('the value text is not mirrored under right-to-left', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentFunnelChart(key: key, data: data),
      direction: TextDirection.rtl,
    );
    expect(
      painterOf(tester).textDirection,
      TextDirection.rtl,
      reason:
          'FunnelChart.tsx:224 wraps the label in its own scale(-1,1) to '
          'un-mirror the glyphs, so the text reads normally; the painter '
          'therefore draws it unflipped and only mirrors the anchor.',
    );
  });

  testWidgets('hiding the legend also hides the title', (tester) async {
    await pump(
      tester,
      const FluentFunnelChart(
        key: key,
        chartTitle: 'Pipeline',
        hideLegend: true,
        data: data,
      ),
    );
    expect(
      find.text('Pipeline'),
      findsNothing,
      reason:
          'FunnelChart.tsx:490 gates the title on '
          '!props.hideLegend && props.chartTitle. The 40px reservation stays '
          'either way.',
    );
  });

  testWidgets('one legend per stage for a plain funnel', (tester) async {
    await pump(tester, const FluentFunnelChart(key: key, data: data));
    expect(
      find.text('Visits'),
      findsOneWidget,
      reason: 'FunnelChart.tsx:405-412 — title = d.stage.',
    );
  });

  testWidgets('one legend per unique category for a stacked funnel', (
    tester,
  ) async {
    await pump(
      tester,
      const FluentFunnelChart(
        key: key,
        data: <FluentFunnelDataPoint>[
          FluentFunnelDataPoint(
            stage: 'A',
            subValues: <FluentFunnelSubValue>[
              FluentFunnelSubValue(
                category: 'x',
                value: 60,
                color: Color(0xFF0F6CBD),
              ),
              FluentFunnelSubValue(
                category: 'y',
                value: 40,
                color: Color(0xFF115EA3),
              ),
            ],
          ),
          FluentFunnelDataPoint(
            stage: 'B',
            subValues: <FluentFunnelSubValue>[
              FluentFunnelSubValue(
                category: 'x',
                value: 30,
                color: Color(0xFFAAAAAA),
              ),
            ],
          ),
        ],
      ),
    );
    // DEVIATION from the plan's `find.text('x')`: the legend title-cases every
    // label through `capitalizeLegendLabel` before painting it
    // (`legend.dart:830`, `useLegendsStyles.styles.ts:56`), so the rendered
    // glyph is 'X'. The assertion below is about the count, which is what the
    // reason describes, and that is unchanged.
    expect(
      find.text('X'),
      findsOneWidget,
      reason:
          'FunnelChart.tsx:413-420 keeps one entry per category and takes '
          'the colour from the FIRST occurrence in document order, so the '
          'grey in stage B never reaches the legend.',
    );
  });

  testWidgets('a selection wins over a hover entirely', (tester) async {
    await pump(tester, const FluentFunnelChart(key: key, data: data));
    await tester.tap(find.text('Visits'));
    await tester.pump();
    expect(
      painterOf(tester).segments.map((s) => s.opacity).toList(),
      <double>[1.0, 0.1, 0.1],
      reason:
          'FunnelChart.tsx:127-129 — selectedLegends wins whenever it is '
          'non-empty, and hoveredStage is only consulted when it is empty.',
    );
  });

  testWidgets('a dimmed segment is inert to hover but still focusable', (
    tester,
  ) async {
    await pump(tester, const FluentFunnelChart(key: key, data: data));
    await tester.tap(find.text('Visits'));
    await tester.pump();
    expect(
      segmentFocuses(tester).length,
      3,
      reason:
          'FunnelChart.tsx:163-170 attaches the hover handlers only when '
          'the opacity is 1, but onFocus at :233 always fires; only the '
          'tabIndex at :305 is withdrawn.',
    );
    expect(
      segmentFocuses(tester).map((focus) => focus.canRequestFocus).toList(),
      <bool>[true, false, false],
      reason:
          'FunnelChart.tsx:305 sets tabIndex only at full opacity, so the two '
          'dimmed stages leave the tab order while keeping their nodes.',
    );
  });

  testWidgets('the chart is a region labelled with its segment count', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const FluentFunnelChart(key: key, data: data));
    expect(
      find.bySemanticsLabel('Funnel chart with 3 segments'),
      findsOneWidget,
      reason:
          'FunnelChart.tsx:476-478 — the count sums subValues.length when '
          'stacked and is data.length otherwise.',
    );
    handle.dispose();
  });

  testWidgets('each segment carries the stage-and-value aria label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const FluentFunnelChart(key: key, data: data));
    expect(
      find.bySemanticsLabel('Visits, 100.'),
      findsOneWidget,
      reason:
          'FunnelChart.tsx:139-151 — `\${stage}, \${value}.` for a plain '
          'funnel, with the trailing full stop.',
    );
    handle.dispose();
  });

  testWidgets('an empty data set announces the no-data alert', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      const FluentFunnelChart(key: key, data: <FluentFunnelDataPoint>[]),
    );
    expect(
      tester.getSemantics(find.byKey(key)).label,
      'Graph has no data to display',
      reason: 'FunnelChart.tsx:531.',
    );
    handle.dispose();
  });

  testWidgets(
    'more segments than the per-mark focus bound trips the assertion',
    (tester) async {
      await pump(
        tester,
        FluentFunnelChart(
          key: key,
          data: <FluentFunnelDataPoint>[
            // 33 stages — one past the 32-segment bound the chart asserts.
            for (var i = 0; i < 33; i++)
              FluentFunnelDataPoint(stage: 'S$i', value: (33 - i).toDouble()),
          ],
        ),
      );
      expect(
        tester.takeException(),
        isAssertionError,
        reason:
            "this chart takes design spec §5.7's bounded-cardinality "
            'exemption and mints one Focus per segment, which is only sound '
            'while the stage count stays a handful; exceeding the stated bound '
            'must fail loudly rather than quietly become the 500-node case §5.7 '
            'warns about.',
      );
    },
  );

  testWidgets('every fill flattens to one system colour under high contrast', (
    tester,
  ) async {
    final highContrast = FluentThemeData.highContrast(
      fontPlatform: FluentFontPlatform.web,
    );
    await pump(
      tester,
      const FluentFunnelChart(key: key, data: data),
      withTheme: highContrast,
    );
    final painter = painterOf(tester);
    expect(
      painter.segments
          .map((segment) => painter.fillColorFor(segment).toARGB32())
          .toSet(),
      <int>{
        FluentChartColors.of(
          highContrast,
        ).flattenMark(data.first.color!).toARGB32(),
      },
      reason:
          'Spec 5.3 — upstream series marks carry no forced-color-adjust, so a '
          'forced-colours browser rewrites every fill to CanvasText. The widget '
          'must hand the painter its resolved FluentChartColors, or the '
          'forty-colour palette survives and the funnel is invisible.',
    );
  });

  group('Oracle B', () {
    testWidgets(
      'charts-funnelchart--funnel-chart-basic reproduces every segment',
      (tester) async {
        final story = loadOracleStory('charts-funnelchart--funnel-chart-basic');
        final paths = story.byTag('path');
        expect(
          paths.length,
          4,
          reason:
              'FunnelChartBasic draws one path per stage and the story has '
              'four stages; a different count means the fixture changed under '
              'the assertions below.',
        );
        // The capture is 600 x 500 with the four stage values its <text>
        // labels read.
        await pump(
          tester,
          const FluentFunnelChart(
            key: key,
            chartTitle: 'Basic Funnel Chart',
            orientation: FluentFunnelOrientation.horizontal,
            data: <FluentFunnelDataPoint>[
              FluentFunnelDataPoint(stage: 'Impressions', value: 1000),
              FluentFunnelDataPoint(stage: 'Clicks', value: 600),
              FluentFunnelDataPoint(stage: 'Leads', value: 300),
              FluentFunnelDataPoint(stage: 'Sales', value: 250),
            ],
          ),
          box: Size(story.width, story.height),
        );
        final painter = painterOf(tester);
        expect(
          painter.funnelWidth,
          closeTo(480, kOracleGeometryTolerance),
          reason:
              'The capture wraps the plot in `translate(60, 40)` over a 480 '
              'wide funnel, which is 600 * 0.8 with the remainder split evenly '
              '(`FunnelChart.tsx:473-474`).',
        );
        // The whole widget-level layout chain — titleHeight, funnelWidth and
        // funnelHeight — is what these polygons prove: the geometry generators
        // are already asserted against the same story by
        // funnel_geometry_test.dart, so anything that differs here is the
        // widget feeding them the wrong box.
        for (var i = 0; i < paths.length; i++) {
          final numbers = svgPathNumbers(paths[i].d!);
          expect(
            numbers.length,
            8,
            reason: 'segment $i: every funnel segment is four vertices.',
          );
          final wanted = Path()..moveTo(numbers[0], numbers[1]);
          for (var n = 2; n < numbers.length; n += 2) {
            wanted.lineTo(numbers[n], numbers[n + 1]);
          }
          wanted.close();
          final residue = Path.combine(
            PathOperation.xor,
            wanted,
            painter.segments[i].geometry.path!,
          ).getBounds();
          expect(
            residue.isEmpty ||
                (residue.width <= kOracleGeometryTolerance &&
                    residue.height <= kOracleGeometryTolerance),
            isTrue,
            reason:
                'segment $i: the symmetric difference against the captured '
                '`d` is $residue, not empty, so the widget laid the funnel out '
                'in a different box from the capture.',
          );
        }
      },
    );
  });
}
