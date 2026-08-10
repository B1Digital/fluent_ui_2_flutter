import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// Records the paths a painter draws, in call order, with their paint.
///
/// The order is the assertion: `Sparkline.tsx:89-105` emits the line before the
/// area, and SVG paints in document order, so the 20% fill tints the lower half
/// of the 2px stroke.
class _RecordingCanvas implements Canvas {
  final List<(Path, Paint)> paths = <(Path, Paint)>[];

  @override
  void drawPath(Path path, Paint paint) => paths.add((path, paint));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// The factor the recovered values are scaled by in [_recoverPoints].
///
/// Any positive factor reproduces the same pixels — the y scale normalises by
/// the data maximum — so a factor other than 1 is what proves the port divides
/// by that maximum rather than treating the recovered pixels as values.
const double _recoveryScale = 2.5;

/// Upstream's `margin.top`, the one non-zero margin (`Sparkline.tsx:21-26`).
const double _topMargin = 2;

/// The one svg of [story] that is [size] and carries a line-and-area pair.
///
/// Count-guarded: the Sparkline stories render the same component many times
/// over, so taking the first match would assert against a chart nobody chose.
OracleSvg _plot(OracleStory story, Size size) {
  final matches = story.svgs
      .where(
        (svg) =>
            svg.width == size.width &&
            svg.height == size.height &&
            svg.elements.length == 2,
      )
      .toList(growable: false);
  expect(
    matches,
    hasLength(1),
    reason:
        '${story.id} must contain exactly one ${size.width}x${size.height} '
        'plotted sparkline; a filtered fixture loop without a count guard '
        'asserts nothing when the filter goes empty.',
  );
  return matches.single;
}

/// The stroked polyline of [svg] — `Sparkline.tsx:89-96`, the first of the two
/// paths and the only one that is not closed.
OracleElement _linePath(OracleSvg svg) {
  final element = svg.elements.first;
  expect(
    element.d,
    isNot(endsWith('Z')),
    reason:
        'Sparkline.tsx:89 emits the open line path before the closed area '
        'path at :97, so element 0 is the line.',
  );
  return element;
}

/// The filled area of [svg] — `Sparkline.tsx:97-105`, closed with a `Z`.
OracleElement _areaPath(OracleSvg svg) {
  final element = svg.elements[1];
  expect(
    element.d,
    endsWith('Z'),
    reason: 'Sparkline.tsx:97 emits the closed area path second.',
  );
  return element;
}

/// The captured vertices of [element]'s line path, as offsets.
List<Offset> _vertices(OracleElement element) {
  final numbers = svgPathNumbers(element.d!);
  expect(
    numbers.length.isEven,
    isTrue,
    reason: 'A polyline `d` is a flat list of x,y pairs.',
  );
  return <Offset>[
    for (var i = 0; i * 2 < numbers.length; i++)
      Offset(numbers[i * 2], numbers[i * 2 + 1]),
  ];
}

/// The data that produced [svg], recovered from its own captured pixels.
///
/// The y scale is `p = H - v * (H - top) / max(v)`, so feeding back
/// `v = (H - p) * k` reproduces `p` for **any** positive `k` and any box, which
/// is what makes the cross-size predictions below non-circular: the values are
/// recovered once from the 80x20 capture and then have to predict the 200x60,
/// 150x20 and 80x40 captures of the same story unaided.
///
/// The recovery is only valid while the smallest captured y is the top margin,
/// which is the assertion below — that is the pixel the data maximum maps to.
List<FluentLineChartDataPoint> _recoverPoints(OracleSvg svg) {
  final vertices = _vertices(_linePath(svg));
  final top = vertices
      .map((vertex) => vertex.dy)
      .reduce((a, b) => a < b ? a : b);
  expectOracleNumber(
    '${svg.width}x${svg.height} line path top',
    _topMargin,
    top,
  );
  return <FluentLineChartDataPoint>[
    for (var i = 0; i < vertices.length; i++)
      FluentLineChartDataPoint(
        x: i.toDouble(),
        y: (svg.height - vertices[i].dy) * _recoveryScale,
      ),
  ];
}

/// Asserts that [points] laid out in [svg]'s box reproduces [svg].
void _expectPlotMatches(
  OracleStory story,
  OracleSvg svg,
  List<FluentLineChartDataPoint> points,
) {
  final layout = FluentSparklineLayout.compute(
    points: points,
    size: Size(svg.width, svg.height),
    topMargin: _topMargin,
  );
  final expected = _vertices(_linePath(svg));
  expect(
    layout.vertices,
    hasLength(expected.length),
    reason:
        '${story.id} at ${svg.width}x${svg.height}: one vertex per datum, '
        'Sparkline.tsx:91.',
  );
  for (var i = 0; i < expected.length; i++) {
    expectOracleOffset(
      '${story.id} ${svg.width}x${svg.height} vertex $i',
      expected[i],
      layout.vertices[i],
    );
  }
  expectOracleRect(
    '${story.id} ${svg.width}x${svg.height} area bounds',
    _areaPath(svg).bbox!,
    layout.areaPath.getBounds(),
  );
}

/// The vertex table below is the whole point of this file.
///
/// `Sparkline.tsx:61-68` builds `x` over `extent(points, d => d.x)` mapped to
/// `[margin.left, width - margin.right]` = `[0, 80]`, and `y` over
/// `[0, max(points, d => d.y)]` mapped to `[height - margin.bottom, margin.top]`
/// = `[20, 2]`. The recon brief's worked example transcribed the y values one
/// row out of step; the table here is recomputed from the source formula
/// `y(v) = 20 - 2.25 * v` for a maximum of 8.
void main() {
  const key = Key('sparkline');

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    FluentThemeData? theme,
    TextDirection direction = TextDirection.ltr,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Directionality(
        textDirection: direction,
        child: Center(child: child),
      ),
    ),
  );

  FluentChartData dataOf(List<(double, double)> xy, {Color? colour}) =>
      FluentChartData(
        lineChartData: <FluentLineChartSeries>[
          FluentLineChartSeries(
            legend: 'Series',
            color: colour ?? const Color(0xFF637CEF),
            data: <FluentLineChartDataPoint>[
              for (final (x, y) in xy) FluentLineChartDataPoint(x: x, y: y),
            ],
          ),
        ],
      );

  const sample = <(double, double)>[(0, 1), (1, 4), (2, 2), (3, 8)];

  test('layout maps x over the extent and y from zero to the maximum', () {
    final layout = FluentSparklineLayout.compute(
      points: <FluentLineChartDataPoint>[
        for (final (x, y) in sample) FluentLineChartDataPoint(x: x, y: y),
      ],
      size: const Size(80, 20),
      topMargin: 2,
    );
    const expected = <Offset>[
      Offset(0, 17.75),
      Offset(80 / 3, 11),
      Offset(160 / 3, 15.5),
      Offset(80, 2),
    ];
    for (var i = 0; i < expected.length; i++) {
      expect(
        layout.vertices[i].dx,
        closeTo(expected[i].dx, 1e-9),
        reason:
            'x[$i] = i/3 * 80 — Sparkline.tsx:61-63 ranges x over '
            '[margin.left, width - margin.right].',
      );
      expect(
        layout.vertices[i].dy,
        closeTo(expected[i].dy, 1e-9),
        reason:
            'y[$i] = 20 - 2.25 * value — Sparkline.tsx:65-68 ranges y over '
            '[height - margin.bottom, margin.top] with domain [0, max].',
      );
    }
  });

  test(
    'the y domain starts at zero, so negatives extrapolate below the box',
    () {
      final layout = FluentSparklineLayout.compute(
        points: const <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: 0, y: -4),
          FluentLineChartDataPoint(x: 1, y: 8),
        ],
        size: const Size(80, 20),
        topMargin: 2,
      );
      expect(
        layout.vertices.first.dy,
        closeTo(29, 1e-9),
        reason:
            'Sparkline.tsx:67 pins the y domain minimum at literal 0 rather '
            'than the data minimum, so -4 maps to 20 + 4 * 2.25 = 29, nine '
            'pixels below the 20px box.',
      );
    },
  );

  test('the area closes at the pixel bottom, not at the value zero', () {
    final layout = FluentSparklineLayout.compute(
      points: const <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(x: 0, y: 2),
        FluentLineChartDataPoint(x: 1, y: 8),
      ],
      // A non-zero top margin makes y(0) = 18 while height stays 20, so an
      // implementation that wrote y0 = y(0) instead of y0 = height fails here.
      size: const Size(80, 20),
      topMargin: 2,
    );
    expect(
      layout.areaPath.getBounds().bottom,
      closeTo(20, 1e-9),
      reason:
          'Sparkline.tsx:48 sets the area baseline to the raw pixel '
          '`height`, not to y(0).',
    );
  });

  test(
    'a degenerate x extent collapses every vertex to the range midpoint',
    () {
      final layout = FluentSparklineLayout.compute(
        points: const <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: 5, y: 1),
          FluentLineChartDataPoint(x: 5, y: 2),
        ],
        size: const Size(80, 20),
        topMargin: 2,
      );
      expect(
        layout.vertices.map((v) => v.dx),
        everyElement(closeTo(40, 1e-9)),
        reason:
            'd3 continuous scales normalise a degenerate domain to 0.5, '
            'which is 40 of an 80px range — scale_continuous.dart.',
      );
    },
  );

  test('a DateTime x is ranked by its epoch milliseconds', () {
    final layout = FluentSparklineLayout.compute(
      points: <FluentLineChartDataPoint>[
        FluentLineChartDataPoint(x: DateTime.utc(2020), y: 1),
        FluentLineChartDataPoint(x: DateTime.utc(2020, 1, 2), y: 2),
        FluentLineChartDataPoint(x: DateTime.utc(2020, 1, 5), y: 3),
      ],
      size: const Size(80, 20),
      topMargin: 2,
    );
    expect(
      layout.vertices[1].dx,
      closeTo(20, 1e-9),
      reason:
          'One day of four maps to a quarter of the range: `d3Extent` at '
          'Sparkline.tsx:58 compares Dates through their implicit valueOf, '
          'which is the epoch millisecond count.',
    );
  });

  group('charts-sparkline--sparkline-dimensions', () {
    final story = loadOracleStory('charts-sparkline--sparkline-dimensions');

    test('one dataset re-scales across every captured box', () {
      final points = _recoverPoints(_plot(story, const Size(80, 20)));
      // The 80x20 capture is the one the values were recovered from; the other
      // three are predictions the recovery had no sight of.
      const boxes = <Size>[
        Size(80, 20),
        Size(150, 20),
        Size(80, 40),
        Size(200, 60),
      ];
      for (final box in boxes) {
        _expectPlotMatches(story, _plot(story, box), points);
      }
    });
  });

  group('charts-sparkline--sparkline-basic', () {
    final story = loadOracleStory('charts-sparkline--sparkline-basic');

    test('the widest capture is reproduced vertex for vertex', () {
      final svg = story.primary;
      _expectPlotMatches(story, svg, _recoverPoints(svg));
    });

    test('the captured stroke and fill are the series colour at 20%', () {
      final svg = story.primary;
      expectOracleColour(
        '${story.id} line stroke',
        const Color(0xFF637CEF),
        _linePath(svg).stroke,
      );
      expectOracleColour(
        '${story.id} area fill',
        const Color(0xFF637CEF),
        _areaPath(svg).fill,
      );
      expectOracleNumber(
        '${story.id} line stroke width',
        2,
        _linePath(svg).strokeWidth,
      );
      expectOracleNumber(
        '${story.id} area fill opacity',
        0.2,
        _areaPath(svg).fillOpacity,
      );
    });
  });

  test('the painter strokes the line first and fills the area over it', () {
    final layout = FluentSparklineLayout.compute(
      points: <FluentLineChartDataPoint>[
        for (final (x, y) in sample) FluentLineChartDataPoint(x: x, y: y),
      ],
      size: const Size(80, 20),
      topMargin: 2,
    );
    final canvas = _RecordingCanvas();
    FluentSparklinePainter(
      layout: layout,
      colour: const Color(0xFF637CEF),
      strokeWidth: 2,
      areaOpacity: 0.2,
    ).paint(canvas, const Size(80, 20));
    expect(
      canvas.paths.map((entry) => entry.$2.style),
      <PaintingStyle>[PaintingStyle.stroke, PaintingStyle.fill],
      reason:
          'Sparkline.tsx:89-105 emits the line path before the area path, and '
          'SVG paints in document order, so the 20% fill tints the lower half '
          'of the stroke.',
    );
    expect(
      canvas.paths.first.$2.strokeWidth,
      2,
      reason: 'Sparkline.tsx:94 hard-codes strokeWidth 2.',
    );
    expect(
      canvas.paths.last.$2.color.a,
      closeTo(0.2, 1e-6),
      reason: 'Sparkline.tsx:101 hard-codes fillOpacity 0.2.',
    );
  });

  testWidgets('the plot is suppressed below 50x16 but the label is not', (
    tester,
  ) async {
    await pump(
      tester,
      FluentSparkline(
        key: key,
        data: dataOf(sample),
        width: 49,
        showLegend: true,
      ),
    );
    expect(
      find.descendant(of: find.byKey(key), matching: find.byType(CustomPaint)),
      findsNothing,
      reason:
          'Sparkline.tsx:114 replaces the chart svg with an empty fragment '
          'when width < 50, while :126 still renders the value-text svg.',
    );
    expect(
      find.text('Series'),
      findsOneWidget,
      reason:
          'Sparkline.tsx:126-131 gates the label on showLegend and the '
          'legend string only, never on the size.',
    );
  });

  testWidgets('the chart is one tab stop labelled with its legend', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, FluentSparkline(key: key, data: dataOf(sample)));
    final semantics = tester.getSemantics(
      find
          .descendant(of: find.byKey(key), matching: find.byType(Semantics))
          .first,
    );
    expect(
      semantics.label,
      'Sparkline with label Series',
      reason:
          'Sparkline.tsx:118 labels the svg '
          '`Sparkline with label \${legend}`.',
    );
    expect(
      find.descendant(of: find.byKey(key), matching: find.byType(Focus)),
      findsOneWidget,
      reason:
          'Sparkline.tsx:119 gives the chart svg tabIndex 0, and :111 wraps '
          'the container in one focusable group — one tab stop, no more.',
    );
    handle.dispose();
  });

  testWidgets('an empty series announces the no-data alert', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      const FluentSparkline(
        key: key,
        data: FluentChartData(lineChartData: <FluentLineChartSeries>[]),
      ),
    );
    expect(
      tester.getSemantics(find.byKey(key)).label,
      'Graph has no data to display',
      reason:
          'Sparkline.tsx:137 renders a hidden role="alert" node with that '
          'exact label when the chart is empty.',
    );
    handle.dispose();
  });

  testWidgets('the label baseline sits five pixels above the bottom', (
    tester,
  ) async {
    await pump(
      tester,
      FluentSparkline(key: key, data: dataOf(sample), showLegend: true),
    );
    final box = tester.getRect(find.text('Series'));
    final parent = tester.getRect(find.byKey(key));
    expect(
      parent.bottom - box.bottom,
      closeTo(0, 0.01),
      reason:
          'The label box is bottom-aligned inside the 20px strip; '
          'Sparkline.tsx:128 puts the alphabetic baseline at height - 5, which '
          'the widget realises with an explicit Baseline offset.',
    );
  });

  testWidgets('right-to-left anchors the label at 8 from the trailing edge', (
    tester,
  ) async {
    await pump(
      tester,
      FluentSparkline(key: key, data: dataOf(sample), showLegend: true),
      direction: TextDirection.rtl,
    );
    final chart = tester.getRect(find.byKey(key));
    final label = tester.getRect(find.text('Series'));
    expect(
      chart.right - label.right,
      closeTo(8, 0.01),
      reason:
          'Sparkline.tsx:128 flips textAnchor to "end" under RTL while '
          'keeping dx at 8, so the anchor moves to the trailing edge.',
    );
  });

  testWidgets('high contrast flattens the mark to the system foreground', (
    tester,
  ) async {
    final theme = FluentThemeData.highContrast(
      fontPlatform: FluentFontPlatform.web,
    );
    const seriesColour = Color(0xFF637CEF);
    await pump(
      tester,
      FluentSparkline(
        key: key,
        data: dataOf(sample, colour: seriesColour),
      ),
      theme: theme,
    );
    final painter =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byKey(key),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as FluentSparklinePainter;
    expect(
      painter.colour,
      FluentChartColors.of(theme).axisText,
      reason:
          'Design spec §5.3: upstream series marks carry no '
          'forced-color-adjust — useSparklineStyles.styles.ts:26 sets it to '
          '`auto` on the value text only — so forced-colours mode rewrites the '
          'stroke and fill to the system foreground.',
    );
    expect(
      painter.colour,
      isNot(seriesColour),
      reason:
          'A painter that kept the palette colour under high contrast would '
          'draw an invisible chart.',
    );
  });

  testWidgets('the palette colour survives outside high contrast', (
    tester,
  ) async {
    const seriesColour = Color(0xFFE3008C);
    await pump(
      tester,
      FluentSparkline(
        key: key,
        data: dataOf(sample, colour: seriesColour),
      ),
    );
    final painter =
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byKey(key),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as FluentSparklinePainter;
    expect(
      painter.colour,
      seriesColour,
      reason:
          'Sparkline.tsx:95 strokes with data.lineChartData[0].color; only '
          'high contrast may replace it.',
    );
  });
}
