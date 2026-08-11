import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/chrome/chart_popover.dart';
import 'package:fluent_2_web/src/charts/chrome/legend.dart';
import 'package:fluent_2_web/src/charts/horizontal_bar_chart.dart';
import 'package:fluent_2_web/src/charts/internal/chart_colors.dart';
import 'package:fluent_2_web/src/charts/model/bar_data.dart';
import 'package:fluent_2_web/src/charts/model/cartesian_series.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// The six-state highlight matrix is the point of this file. Selection is
/// single-select and toggling (`HorizontalBarChart.tsx:127`), hover is a second
/// independent source (`:128-132`), and the predicate that combines them is
/// `isLegendHighlightedSingleGuarded` — model B plus the undefined-to-false
/// guard at `HorizontalBarChart.tsx:371-376`.
///
/// Oracle B carries seven `HorizontalBarChart` stories. Two are asserted here,
/// at the widget level rather than the layout level
/// (`horizontal_bar_chart_layout_test.dart` already drives
/// [FluentHorizontalBarRowLayout] directly): what these prove is the wiring —
/// that the widget feeds the measured row width and the right point list into
/// that layout, synthesises the placeholder bar the basic story shows, and
/// picks the value-text branch the captured `fui-hbc__chartTitleRight` box
/// holds.
void main() {
  const key = Key('hbc');
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(
    WidgetTester tester,
    Widget chart, {
    double width = 400,
    FluentThemeData? themeOverride,
  }) => tester.pumpWidget(
    FluentApp(
      theme: themeOverride ?? theme,
      home: Center(
        child: SizedBox(width: width, child: chart),
      ),
    ),
  );

  FluentChartDataPoint bar(
    String legend,
    double x, {
    Color? colour,
    double? total = 100,
  }) => FluentChartDataPoint(
    legend: legend,
    color: colour,
    horizontalBarChartData: FluentHorizontalDataPoint(x: x, total: total),
  );

  final threeLegends = <FluentChartData>[
    FluentChartData(
      chartTitle: 'Row one',
      chartData: <FluentChartDataPoint>[
        bar('A', 30, colour: const Color(0xFF111111)),
        bar('B', 40, colour: const Color(0xFF222222)),
        bar('C', 30, colour: const Color(0xFF333333)),
      ],
    ),
  ];

  /// The strip painter of row [row].
  ///
  /// Filtered on the painter type rather than taken from the first
  /// [CustomPaint]: a row with a benchmark mounts
  /// [FluentBenchmarkTrianglePainter] ahead of the strip, so an unfiltered
  /// `.first` would silently assert against the triangle.
  FluentHorizontalBarStripPainter painterOf(
    WidgetTester tester, {
    int row = 0,
  }) {
    final painters = tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(CustomPaint),
          ),
        )
        .map((paint) => paint.painter)
        .whereType<FluentHorizontalBarStripPainter>()
        .toList(growable: false);
    expect(
      painters.length,
      greaterThan(row),
      reason:
          'row $row must have mounted a FluentHorizontalBarStripPainter; '
          'found ${painters.length}.',
    );
    return painters[row];
  }

  List<double> opacitiesOf(WidgetTester tester) => painterOf(tester).opacities;

  testWidgets('with nothing highlighted every bar is fully opaque', (
    tester,
  ) async {
    await pump(tester, FluentHorizontalBarChart(key: key, data: threeLegends));
    expect(
      opacitiesOf(tester),
      everyElement(1.0),
      reason:
          'HorizontalBarChart.tsx:381-383 — _noLegendHighlighted is true '
          'when both selectedLegend and activeLegend are empty, and :327 then '
          'gives every bar opacity 1.',
    );
  });

  testWidgets('selecting a legend dims the other two', (tester) async {
    await pump(tester, FluentHorizontalBarChart(key: key, data: threeLegends));
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(
      opacitiesOf(tester),
      <double>[1.0, 0.1, 0.1],
      reason:
          'HorizontalBarChart.tsx:371-376 — selectedLegend === legend '
          'highlights exactly one bar, and :327 dims the rest to 0.1.',
    );
  });

  testWidgets('selecting the same legend twice clears the selection', (
    tester,
  ) async {
    await pump(tester, FluentHorizontalBarChart(key: key, data: threeLegends));
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(
      opacitiesOf(tester),
      everyElement(1.0),
      reason:
          'HorizontalBarChart.tsx:127 toggles: '
          'setSelectedLegend(selectedLegend === legend ? "" : legend).',
    );
  });

  testWidgets('a selection wins over a hover on a different legend', (
    tester,
  ) async {
    await pump(tester, FluentHorizontalBarChart(key: key, data: threeLegends));
    await tester.tap(find.text('A'));
    await tester.pump();
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      pointer.hover(tester.getCenter(find.text('B'))),
    );
    await tester.pump();
    expect(
      opacitiesOf(tester),
      <double>[1.0, 0.1, 0.1],
      reason:
          'HorizontalBarChart.tsx:375 requires selectedLegend === "" '
          'before activeLegend is consulted, so a live selection suppresses '
          'the hover entirely.',
    );
  });

  testWidgets('a hover alone highlights, with nothing selected', (
    tester,
  ) async {
    await pump(tester, FluentHorizontalBarChart(key: key, data: threeLegends));
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(
      pointer.hover(tester.getCenter(find.text('B'))),
    );
    await tester.pump();
    expect(
      opacitiesOf(tester),
      <double>[0.1, 1.0, 0.1],
      reason:
          'HorizontalBarChart.tsx:375 — the hover arm of the predicate is '
          'reachable exactly while selectedLegend is the empty string.',
    );
  });

  testWidgets('only highlighted bars stay in the tab order', (tester) async {
    await pump(tester, FluentHorizontalBarChart(key: key, data: threeLegends));
    await tester.tap(find.text('A'));
    await tester.pump();
    // Scoped by debugLabel, not by `find.byType(Focus)` alone: the legend
    // strip below the row is itself a stack of focusable rows, and counting
    // those would measure the legend's tab order rather than the bars'.
    final focusable = tester
        .widgetList<Focus>(
          find.descendant(of: find.byKey(key), matching: find.byType(Focus)),
        )
        .where((f) => f.debugLabel == 'FluentHorizontalBarChart bar')
        .where((f) => f.canRequestFocus)
        .length;
    expect(
      focusable,
      1,
      reason:
          'HorizontalBarChart.tsx:328 removes tabIndex from a bar that is '
          'neither highlighted nor part of an unhighlighted chart, in lockstep '
          'with the opacity at :327.',
    );
  });

  testWidgets('hovering a bar opens the popover, and leaving the chart '
      'closes it', (tester) async {
    await pump(tester, FluentHorizontalBarChart(key: key, data: threeLegends));
    final strip = tester.getRect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is FluentHorizontalBarStripPainter,
      ),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    // Added away from the chart and then moved onto it: only a move emits the
    // PointerHoverEvent the bar listens for.
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();
    // 20 into the first bar, which spans 0..120 of the 400-wide row, and half
    // way down the 12px strip.
    await gesture.moveTo(strip.topLeft + const Offset(20, 6));
    await tester.pump();
    expect(
      find.byType(FluentChartPopover),
      findsOneWidget,
      reason:
          'HorizontalBarChart.tsx:318-320 wires onMouseOver on every bar whose '
          'legend is not the empty string.',
    );
    expect(
      find.text('30'),
      findsOneWidget,
      reason:
          'HorizontalBarChart.tsx:472 passes YValue, which is the hovered '
          "point's x.",
    );
    final anchor = tester.widget<FluentChartPopover>(
      find.byType(FluentChartPopover),
    );
    await gesture.moveTo(strip.topLeft + const Offset(20.5, 6));
    await tester.pump();
    expect(
      tester.widget<FluentChartPopover>(find.byType(FluentChartPopover)).anchor,
      anchor.anchor,
      reason:
          'HorizontalBarChart.tsx:349-359 — updatePosition only commits a new '
          'position once the pointer has travelled more than one pixel.',
    );
    await gesture.moveTo(Offset.zero);
    await tester.pump();
    expect(
      find.byType(FluentChartPopover),
      findsNothing,
      reason:
          'HorizontalBarChart.tsx:95-103, wired at :393 — only leaving the '
          'whole chart closes the popover.',
    );
  });

  testWidgets('a single-value row is drawn as value plus remainder', (
    tester,
  ) async {
    await pump(
      tester,
      FluentHorizontalBarChart(
        key: key,
        data: <FluentChartData>[
          FluentChartData(
            chartTitle: 'Solo',
            chartData: <FluentChartDataPoint>[bar('A', 30)],
          ),
        ],
      ),
    );
    final painter = painterOf(tester);
    expect(
      painter.layout.segments.length,
      2,
      reason:
          'HorizontalBarChart.tsx:400-413 synthesises a placeholder bar of '
          'total - x whenever the row has one point.',
    );
    expect(
      painter.fills[1].toARGB32(),
      theme.colors.backgroundOverlay.toARGB32(),
      reason:
          'HorizontalBarChart.tsx:411 fills the placeholder with '
          'colorBackgroundOverlay.',
    );
    expect(
      find.byType(FluentChartLegend),
      findsNothing,
      reason:
          'HorizontalBarChart.tsx:485 gates the legend strip on !isSingleBar.',
    );
  });

  testWidgets('showLegendForSinglePointBar suppresses the synthesis', (
    tester,
  ) async {
    await pump(
      tester,
      FluentHorizontalBarChart(
        key: key,
        showLegendForSinglePointBar: true,
        data: <FluentChartData>[
          FluentChartData(chartData: <FluentChartDataPoint>[bar('A', 30)]),
        ],
      ),
    );
    expect(
      find.text('A'),
      findsOneWidget,
      reason:
          'HorizontalBarChart.tsx:400-401 forces isSingleBar to false, '
          'which both skips the placeholder and re-enables the legend strip at '
          ':485.',
    );
    expect(
      painterOf(tester).layout.segments.length,
      1,
      reason:
          'HorizontalBarChart.tsx:403 never runs, so no placeholder exists.',
    );
  });

  group('chartDataMode', () {
    Future<void> pumpMode(WidgetTester tester, FluentChartDataMode mode) =>
        pump(
          tester,
          FluentHorizontalBarChart(
            key: key,
            chartDataMode: mode,
            data: <FluentChartData>[
              FluentChartData(
                chartTitle: 'Row',
                chartData: <FluentChartDataPoint>[bar('A', 25)],
              ),
            ],
          ),
        );

    testWidgets('byDefault shows the value', (tester) async {
      await pumpMode(tester, FluentChartDataMode.byDefault);
      expect(
        find.text('25'),
        findsOneWidget,
        reason:
            'HorizontalBarChart.tsx:169-174 renders formatToLocaleString(x).',
      );
    });

    testWidgets('fraction keeps the literal spaces round the slash', (
      tester,
    ) async {
      await pumpMode(tester, FluentChartDataMode.fraction);
      expect(
        find.text(' / 100'),
        findsOneWidget,
        reason:
            'HorizontalBarChart.tsx:179 concatenates the string '
            "' / ' onto formatToLocaleString(total), spaces included.",
      );
    });

    testWidgets('percentage rounds to a whole number and appends a sign', (
      tester,
    ) async {
      await pumpMode(tester, FluentChartDataMode.percentage);
      expect(
        find.text('25%'),
        findsOneWidget,
        reason:
            'HorizontalBarChart.tsx:183 is '
            'formatToLocaleString(Math.round(x / total * 100)) + "%".',
      );
    });

    testWidgets('hidden renders nothing', (tester) async {
      await pumpMode(tester, FluentChartDataMode.hidden);
      expect(
        find.text('25'),
        findsNothing,
        reason: 'HorizontalBarChart.tsx:145-147 returns early for hidden.',
      );
    });
  });

  testWidgets('the absolute-scale variant suppresses the right-hand value', (
    tester,
  ) async {
    await pump(
      tester,
      FluentHorizontalBarChart(
        key: key,
        variant: FluentHorizontalBarChartVariant.absoluteScale,
        data: <FluentChartData>[
          FluentChartData(
            chartTitle: 'Row',
            chartData: <FluentChartDataPoint>[bar('A', 25)],
          ),
        ],
      ),
    );
    expect(
      find.text('25'),
      findsNothing,
      reason:
          'HorizontalBarChart.tsx:416-417 sets chartDataText to null for '
          'the absolute-scale variant; the value moves inside the bar instead.',
    );
    expect(
      painterOf(tester).absoluteLabel,
      '25',
      reason:
          'HorizontalBarChart.tsx:289-302 draws formatScientificLimitWidth(x) '
          'in place of the placeholder rect.',
    );
    expect(
      painterOf(tester).absoluteLabelIndex,
      1,
      reason:
          'HorizontalBarChart.tsx:284 swaps the rect for a text on the '
          'placeholder point, which is the one :404 synthesised.',
    );
  });

  // The vertical metrics of a row, which are the whole of what
  // `charts-horizontalbarchart--horizontal-bar-basic` measured wrong.
  //
  // Upstream stacks: a `chartTitle` flex line, then the 12px svg, then the
  // `items` margin-bottom. The gap under the title hangs on the LEFT span alone
  // (`chartTitleLeft5pMargin`, `useHorizontalBarChartStyles.styles.ts:67-69`,
  // selected at `:129-136`), so the flex line is
  // max(caption1 16 + 5, body1Strong 20) = **21** and both spans sit at its
  // top — not max(16, 20) + 5 = 25 with the title centred. Oracle B measures
  // `fui-hbc__chartTitle` at `[24, 48, 600, 21]` and `fui-hbc__chartTitleLeft`
  // at `[24, 48, 20.109375, 16]`: same top, and 21 against 16.
  group('row metrics', () {
    final threeRows = <FluentChartData>[
      for (final title in <String>['Row one', 'Row two', 'Row three'])
        FluentChartData(
          chartTitle: title,
          chartData: <FluentChartDataPoint>[bar(title, 30)],
        ),
    ];

    // 21 title + 12 svg per row, 10 between rows. Eight rows of this is the
    // 334px box the reference is captured at.
    const rowHeight = 33.0;
    const rowSpacing = 10.0;

    final strips = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is FluentHorizontalBarStripPainter,
    );

    testWidgets('the title line is 21 tall and its text sits at the top', (
      tester,
    ) async {
      await pump(
        tester,
        FluentHorizontalBarChart(key: key, data: threeRows),
        width: 600,
      );
      final top = tester.getRect(find.byKey(key)).top;
      expect(
        tester.getRect(strips.first).top - top,
        21,
        reason:
            'useHorizontalBarChartStyles.styles.ts:52-56 is a flex row whose '
            'line is max(16 + 5, 20); the svg starts below it.',
      );
      expect(
        tester.getRect(find.text('Row one')).top - top,
        0,
        reason:
            'The 5px is chartTitleLeft\'s margin-BOTTOM (:67-69), so the '
            'title box starts at the top of the line, as oracle B\'s '
            'fui-hbc__chartTitleLeft does at the same y as its chartTitle.',
      );
    });

    testWidgets('rows pitch at 43 and the last one carries no trailing gap', (
      tester,
    ) async {
      // Exactly the height three rows need. A trailing row margin would make
      // this a RenderFlex overflow, which is what the reference's own clip
      // proves upstream does not have: capture_png.mjs unions the chartTitle
      // and chart boxes, and the `items` margin below the last row is outside
      // both, so eight rows measured 8 x 33 + 7 x 10 = 334.
      const exact = rowHeight * 3 + rowSpacing * 2;
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: Center(
            child: SizedBox(
              width: 600,
              height: exact,
              child: FluentHorizontalBarChart(key: key, data: threeRows),
            ),
          ),
        ),
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '$exact is exactly what three rows need; nothing overflows.',
      );
      final tops = <double>[
        for (var i = 0; i < 3; i++) tester.getRect(strips.at(i)).top,
      ];
      expect(
        <double>[tops[1] - tops[0], tops[2] - tops[1]],
        <double>[rowHeight + rowSpacing, rowHeight + rowSpacing],
        reason:
            'useHorizontalBarChartStyles.styles.ts:39-41 is '
            'spacingVerticalMNudge, 10, under a 33px row — oracle B puts the '
            'eight captured chartTitle boxes 43 apart.',
      );
      expect(
        tester.getRect(find.byKey(key)).bottom - tops[2],
        12,
        reason:
            'The chart ends at the bottom of the last svg. Upstream\'s own '
            'trailing margin is outside every box the capture clips to, and a '
            'Padding-per-row would have overflowed the box above.',
      );
    });

    testWidgets('a legend strip is 26 below the last row', (tester) async {
      await pump(
        tester,
        FluentHorizontalBarChart(key: key, data: threeLegends),
        width: 600,
      );
      expect(
        tester.getRect(find.byType(FluentChartLegend)).top -
            tester.getRect(strips.first).bottom,
        rowSpacing + 16,
        reason:
            'The row keeps its own 10px margin-bottom when something follows '
            'it, and legendContainer adds spacingVerticalL on top '
            '(useHorizontalBarChartStyles.styles.ts:107).',
      );
    });
  });

  testWidgets('an empty data set announces the no-data alert', (tester) async {
    // Disposed inline, not through addTearDown: flutter_test verifies that
    // every handle is gone BEFORE the tear-downs run.
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      const FluentHorizontalBarChart(key: key, data: <FluentChartData>[]),
    );
    expect(
      tester.getSemantics(find.byKey(key)).label,
      'Graph has no data to display',
      reason:
          'HorizontalBarChart.tsx:497 renders a hidden role="alert" with '
          'that exact label.',
    );
    handle.dispose();
  });

  testWidgets('each bar carries the upstream aria label', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, FluentHorizontalBarChart(key: key, data: threeLegends));
    expect(
      find.bySemanticsLabel('A, 30/100.'),
      findsOneWidget,
      reason:
          'HorizontalBarChart.tsx:335-343 — "\${legend}, " followed by '
          '"\${x}/\${total ?? \'\'}." with a trailing full stop.',
    );
    handle.dispose();
  });

  testWidgets('a row past the per-mark focus bound trips the assertion', (
    tester,
  ) async {
    await pump(
      tester,
      FluentHorizontalBarChart(
        key: key,
        data: <FluentChartData>[
          FluentChartData(
            chartTitle: 'Too many',
            chartData: <FluentChartDataPoint>[
              // 33 bars — one past the 32-mark bound the chart asserts.
              for (var i = 0; i < 33; i++) bar('L$i', 3),
            ],
          ),
        ],
      ),
    );
    expect(
      tester.takeException(),
      isAssertionError,
      reason:
          'this chart takes design spec §5.7\'s bounded-cardinality '
          'exemption and mints one Focus per bar, which is only sound while '
          'the mark count stays a handful; exceeding the stated bound must '
          'fail loudly rather than quietly become the 500-node case §5.7 '
          'warns about.',
    );
  });

  testWidgets('high contrast flattens every bar to the system foreground', (
    tester,
  ) async {
    final highContrast = FluentThemeData.highContrast(
      fontPlatform: FluentFontPlatform.web,
    );
    await pump(
      tester,
      FluentHorizontalBarChart(key: key, data: threeLegends),
      themeOverride: highContrast,
    );
    final flattened = FluentChartColors.of(highContrast).axisText.toARGB32();
    expect(
      painterOf(tester).fills.map((c) => c.toARGB32()).toSet(),
      <int>{flattened},
      reason:
          'Design spec §5.3: upstream bars carry no forced-color-adjust, so '
          'forced-colours mode rewrites every rect fill to CanvasText and the '
          'forty-colour palette disappears. A bar that kept 0xFF111111 here '
          'would be invisible.',
    );
  });

  testWidgets('the palette colour survives outside high contrast', (
    tester,
  ) async {
    await pump(tester, FluentHorizontalBarChart(key: key, data: threeLegends));
    expect(
      painterOf(tester).fills.first.toARGB32(),
      const Color(0xFF111111).toARGB32(),
      reason:
          'FluentChartColors.flattenMark is a no-op outside '
          'FluentHighContrastColors (chart_colors.dart:145).',
    );
  });

  group('oracle B', () {
    const basicId = 'charts-horizontalbarchart--horizontal-bar-basic';
    const stackedId = 'charts-horizontalbarchart--horizontal-bar-stacked';

    test('both named stories are in the corpus', () {
      expect(
        oracleStoryIds(component: 'HorizontalBarChart').toSet(),
        containsAll(<String>[basicId, stackedId]),
        reason:
            'The widget tests below assert nothing if a story id drifts; '
            'this guard is what fails instead.',
      );
    });

    /// The `fui-hbc__chartTitleRight` box of row [row], which is the only slot
    /// that carries the resolved value text.
    OracleHtmlBox valueBox(OracleStory story, int row) {
      final boxes = story.htmlBoxes
          .where((box) => box.slot == 'fui-hbc__chartTitleRight')
          .toList(growable: false);
      expect(
        boxes.length,
        greaterThan(row),
        reason: '${story.id} must have captured a value box for row $row.',
      );
      return boxes[row];
    }

    testWidgets('$basicId row 0 reproduces both rects and its value', (
      tester,
    ) async {
      final story = loadOracleStory(basicId);
      final svg = story.svgs.first;
      // The captured rect widths are percentage strings, so row 0's first bar
      // is 10.286667% of its total. The captured value text is 1543, which
      // fixes the total at 15000.
      await pump(
        tester,
        FluentHorizontalBarChart(
          key: key,
          data: <FluentChartData>[
            FluentChartData(
              chartTitle: 'Basic',
              chartData: <FluentChartDataPoint>[
                bar('One', 1543, total: 15000, colour: svg.elements[1].fill),
              ],
            ),
          ],
        ),
        width: svg.width,
      );
      final painter = painterOf(tester);
      final rects = svg.elements
          .where((element) => element.tag == 'rect')
          .toList(growable: false);
      expect(
        painter.layout.segments.length,
        rects.length,
        reason:
            '$basicId row 0 draws the value bar and the placeholder '
            'HorizontalBarChart.tsx:404 synthesises.',
      );
      for (var i = 0; i < rects.length; i++) {
        expectOracleNumber(
          '$basicId row 0 rect $i: x percent',
          rects[i].x!,
          painter.layout.segments[i].xPercent,
        );
        expectOracleRect(
          '$basicId row 0 rect $i: painted pixels',
          rects[i].bbox!,
          painter.layout.rectOf(i, rects[i].height!),
        );
        expectOracleColour(
          '$basicId row 0 rect $i: fill',
          rects[i].fill,
          painter.fills[i],
        );
      }
      expect(
        find.text(valueBox(story, 0).text!),
        findsOneWidget,
        reason:
            '$basicId row 0 captured "${valueBox(story, 0).text}" in '
            'fui-hbc__chartTitleRight — the default chartDataMode branch at '
            'HorizontalBarChart.tsx:169-174.',
      );
    });

    testWidgets('$basicId row 3 groups its five-figure value', (tester) async {
      final story = loadOracleStory(basicId);
      await pump(
        tester,
        FluentHorizontalBarChart(
          key: key,
          data: <FluentChartData>[
            FluentChartData(
              chartTitle: 'Basic',
              chartData: <FluentChartDataPoint>[
                bar('Four', 15888, total: 15888),
              ],
            ),
          ],
        ),
        width: story.svgs[3].width,
      );
      expect(
        find.text(valueBox(story, 3).text!),
        findsOneWidget,
        reason:
            'formatToLocaleString groups at 10000 (formatter.ts:40), which is '
            'why the capture reads "${valueBox(story, 3).text}".',
      );
    });

    testWidgets('$stackedId row 0 reproduces three rects and the sum', (
      tester,
    ) async {
      final story = loadOracleStory(stackedId);
      final svg = story.svgs.first;
      final rects = svg.elements
          .where((element) => element.tag == 'rect')
          .toList(growable: false);
      expect(
        rects.length,
        3,
        reason: '$stackedId row 0 is the three-segment row.',
      );
      await pump(
        tester,
        FluentHorizontalBarChart(
          key: key,
          data: <FluentChartData>[
            FluentChartData(
              chartTitle: 'Stacked',
              chartData: <FluentChartDataPoint>[
                bar('One.One', 1543, total: null, colour: rects[0].fill),
                bar('One.Two', 1000, total: null, colour: rects[1].fill),
                bar('One.Three', 547, total: null, colour: rects[2].fill),
              ],
            ),
          ],
        ),
        width: svg.width,
      );
      final painter = painterOf(tester);
      for (var i = 0; i < rects.length; i++) {
        expectOracleNumber(
          '$stackedId row 0 rect $i: width percent',
          rects[i].width!,
          painter.layout.segments[i].widthPercent,
        );
        expectOracleRect(
          '$stackedId row 0 rect $i: painted pixels',
          rects[i].bbox!,
          painter.layout.rectOf(i, rects[i].height!),
        );
      }
      expect(
        find.text(valueBox(story, 0).text!),
        findsOneWidget,
        reason:
            'A multi-segment row ignores chartDataMode and shows the summed '
            'value (HorizontalBarChart.tsx:151-161); the capture reads '
            '"${valueBox(story, 0).text}" for 1543 + 1000 + 547.',
      );
    });

    testWidgets('$stackedId puts all seven legends in one strip', (
      tester,
    ) async {
      final story = loadOracleStory(stackedId);
      final captured = story.htmlBoxes
          .where((box) => box.slot == 'fui-legend__text')
          .map((box) => box.text)
          .toList(growable: false);
      expect(
        captured,
        hasLength(7),
        reason: '$stackedId captured one legend per point across three rows.',
      );
      await pump(
        tester,
        FluentHorizontalBarChart(
          key: key,
          data: <FluentChartData>[
            FluentChartData(
              chartData: <FluentChartDataPoint>[
                bar('One.One', 1543),
                bar('One.Two', 1000),
                bar('One.Three', 547),
              ],
            ),
            FluentChartData(
              chartData: <FluentChartDataPoint>[
                bar('Two.One', 987),
                bar('Two.Two', 1987),
              ],
            ),
            FluentChartData(
              chartData: <FluentChartDataPoint>[
                bar('Three.One', 872),
                bar('Three.Two', 128),
              ],
            ),
          ],
        ),
        width: story.svgs.first.width,
      );
      expect(
        tester
            .widget<FluentChartLegend>(find.byType(FluentChartLegend))
            .legends
            .map((item) => item.title)
            .toList(growable: false),
        captured,
        reason:
            'HorizontalBarChart.tsx:118-135 flat-maps every row into ONE '
            'legend list, in data order, which is the order the capture '
            'recorded.',
      );
    });
  });
}
