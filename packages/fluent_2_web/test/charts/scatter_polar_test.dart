import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_layout.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_series_delegate.dart';
import 'package:fluent_2_web/src/charts/internal/chart_colors.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_measurer.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_styles.dart';
import 'package:fluent_2_web/src/charts/internal/d3/curves.dart';
import 'package:fluent_2_web/src/charts/internal/d3/scale_linear.dart' as d3;
import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2_web/src/charts/internal/scatter_polar.dart';
import 'package:fluent_2_web/src/charts/line_chart.dart';
import 'package:fluent_2_web/src/charts/line_chart_style.dart';
import 'package:fluent_2_web/src/charts/model/cartesian_series.dart';
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:fluent_2_web/src/charts/model/line_options.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `LineChart.tsx:1318` gates the fill on `data.length >= 3`, and
/// `scatterpolar-utils.tsx:38-63` places one label per equal angular slot,
/// dropping any that lands within 40px of one already placed.
void main() {
  test('fewer than three points paint no fill at all', () {
    expect(
      scatterPolarFillPath(
        points: const <Offset>[Offset(0, 0), Offset(10, 10)],
        curve: curveLinear,
      ),
      isNull,
      reason: 'LineChart.tsx:1318 requires _points[i].data.length >= 3',
    );
  });

  test('three points close the path with Z', () {
    final path = scatterPolarFillPath(
      points: const <Offset>[Offset(0, 0), Offset(10, 0), Offset(10, 10)],
      curve: curveLinear,
    );
    expect(path, isNotNull, reason: 'three points clear the >= 3 gate');
    expect(
      path!.contains(const Offset(8, 2)),
      isTrue,
      reason: 'LineChart.tsx:1334 appends Z, so the interior is filled',
    );
    expect(
      path.contains(const Offset(1, 8)),
      isFalse,
      reason: 'the point sits outside the closed triangle',
    );
  });

  test('non-finite points break the path, honouring defined()', () {
    final path = scatterPolarFillPath(
      points: const <Offset>[
        Offset(0, 0),
        Offset(10, 0),
        Offset(double.nan, 5),
        Offset(10, 10),
        Offset(0, 10),
      ],
      curve: curveLinear,
    );
    expect(
      path!.computeMetrics().length,
      2,
      reason:
          'isPlottable (utilities.ts:2278) makes the NaN undefined, which splits '
          'the line into two sub-paths',
    );
  });

  test('constant fill paint values come from LineChart.tsx:1336-1339', () {
    expect(kScatterPolarFillOpacity, 0.5, reason: 'LineChart.tsx:1336');
    expect(kScatterPolarFillStrokeWidth, 2, reason: 'LineChart.tsx:1338');
    expect(kScatterPolarFillStrokeOpacity, 0.8, reason: 'LineChart.tsx:1339');
  });

  test('labels sit at equal angles counter-clockwise by default', () {
    double identity(double v) => v * 100;
    final labels = scatterPolarCategoryLabels(
      labels: const <String>['a', 'b', 'c', 'd'],
      xScale: identity,
      yScale: identity,
      minPixelGap: 0,
    );
    expect(labels.length, 4, reason: 'no gap filtering at minPixelGap 0');
    expect(
      labels[0].position.dx,
      closeTo(70, 1e-9),
      reason: 'scatterpolar-utils.tsx:41 — cos(0) * 0.7 scaled by 100',
    );
    expect(
      labels[1].position.dy,
      closeTo(70, 1e-9),
      reason: 'counter-clockwise multiplier +1 puts index 1 at pi/2',
    );
  });

  test('clockwise flips the angular sweep', () {
    double identity(double v) => v * 100;
    final labels = scatterPolarCategoryLabels(
      labels: const <String>['a', 'b', 'c', 'd'],
      xScale: identity,
      yScale: identity,
      direction: 'clockwise',
      minPixelGap: 0,
    );
    expect(
      labels[1].position.dy,
      closeTo(-70, 1e-9),
      reason: 'scatterpolar-utils.tsx:35 sets dirMultiplier to -1',
    );
  });

  test('rotation and originXOffset shift the ring', () {
    double identity(double v) => v * 100;
    final labels = scatterPolarCategoryLabels(
      labels: const <String>['a', 'b'],
      xScale: identity,
      yScale: identity,
      rotationDegrees: 90,
      originXOffset: 1,
      minPixelGap: 0,
    );
    expect(
      labels[0].position.dx,
      closeTo(0.7 * math.cos(math.pi / 2) * 100 - 50, 1e-9),
      reason: 'scatterpolar-utils.tsx:41 subtracts originXOffset / 2',
    );
  });

  test('labels closer than the gap are dropped, the first always kept', () {
    double squash(double v) => v;
    final labels = scatterPolarCategoryLabels(
      labels: const <String>['a', 'b', 'c'],
      xScale: squash,
      yScale: squash,
      minPixelGap: 40,
    );
    expect(
      labels.length,
      1,
      reason:
          'scatterpolar-utils.tsx:47 keeps a label only when the list is empty '
          'or it clears every placed position by minPixelGap',
    );
  });

  // There is NO captured story for `fill: 'toself'` — `grep -i toself` over the
  // Oracle corpus matches only upstream sources (`LineChart.tsx`,
  // `PlotlySchema*.ts`), never a fixture — so every number asserted below is
  // hand-derived from `LineChart.tsx:1315-1344` rather than read off a capture.
  group('FluentLineChart fill: toself', () {
    test('every condition met — one closed area, series last first', () {
      final fills = _polarDelegate(<FluentLineChartSeries>[
        _polarSeries(),
      ]).scatterPolarFillsFor(_polarCtx());
      expect(
        fills,
        hasLength(1),
        reason: 'all four conjuncts of LineChart.tsx:1318 hold',
      );
      expect(fills.single.seriesIndex, 0, reason: 'the only series is index 0');
      expect(
        fills.single.path.contains(_kScaledOrigin),
        isTrue,
        reason:
            'the four points are the unit rhombus, so the scaled origin is '
            'interior to the closed path LineChart.tsx:1334 produces',
      );
    });

    test('condition 1 — a fill that is not exactly toself paints nothing', () {
      const inert = <String?>[null, 'tonexty', 'tozeroy', 'toSelf'];
      expect(inert, hasLength(4), reason: 'guards the loop below against zero');
      for (final fill in inert) {
        expect(
          _polarDelegate(<FluentLineChartSeries>[
            _polarSeries(fill: fill),
          ]).scatterPolarFillsFor(_polarCtx()),
          isEmpty,
          reason:
              'LineChart.tsx:1318 compares fillMode === "toself" with strict '
              'equality, so $fill is inert',
        );
      }
    });

    test('condition 2 — three points is the boundary the gate admits', () {
      expect(
        _polarDelegate(<FluentLineChartSeries>[
          _polarSeries(points: 2),
        ]).scatterPolarFillsFor(_polarCtx()),
        isEmpty,
        reason:
            'LineChart.tsx:1318 requires data.length >= 3; two points enclose '
            'no area',
      );
      expect(
        _polarDelegate(<FluentLineChartSeries>[
          _polarSeries(points: 3),
        ]).scatterPolarFillsFor(_polarCtx()),
        hasLength(1),
        reason: 'three is admitted by the same >=',
      );
    });

    test('condition 3 — a highlighted legend elsewhere suppresses it', () {
      final series = <FluentLineChartSeries>[
        _polarSeries(),
        _polarSeries(legend: 'other'),
      ];
      expect(
        _polarDelegate(series).scatterPolarFillsFor(_polarCtx()),
        hasLength(2),
        reason:
            '_noLegendHighlighted() is the middle arm of LineChart.tsx:1317, '
            'so with nothing highlighted every trace fills',
      );
      expect(
        _polarDelegate(series, activeLegend: 'other')
            .scatterPolarFillsFor(_polarCtx())
            .map((area) => area.seriesIndex)
            .toList(),
        <int>[1],
        reason:
            '_legendHighlighted(legendVal), the first arm of the same '
            'expression, leaves only the hovered trace filled',
      );
      expect(
        _polarDelegate(series, selectedLegend: 'radar')
            .scatterPolarFillsFor(_polarCtx())
            .map((area) => area.seriesIndex)
            .toList(),
        <int>[0],
        reason:
            'a click selects rather than hovers, which LineChart.tsx:1818 '
            'answers through the same _legendHighlighted',
      );
    });

    test('condition 4 — a chart with no scatterpolar trace never fills', () {
      expect(
        _polarDelegate(<FluentLineChartSeries>[
          _polarSeries(mode: 'lines'),
        ]).scatterPolarFillsFor(_polarCtx()),
        isEmpty,
        reason:
            'the _isScatterPolar conjunct of LineChart.tsx:1318; '
            'utilities.ts:2207 compares the whole mode literal, so "lines" '
            'does not qualify however it is spelt',
      );
      expect(
        _polarDelegate(<FluentLineChartSeries>[
          _polarSeries(mode: null),
        ]).scatterPolarFillsFor(_polarCtx()),
        isEmpty,
        reason: 'an absent mode is not the literal either',
      );
    });

    test('condition 4 is chart-wide, not per series', () {
      expect(
        _polarDelegate(<FluentLineChartSeries>[
          _polarSeries(legend: 'plain', mode: 'lines'),
          _polarSeries(),
        ]).scatterPolarFillsFor(_polarCtx()),
        hasLength(2),
        reason:
            'LineChart.tsx:273 computes _isScatterPolar once for the chart and '
            'utilities.ts:2205 is a .some, so one scatterpolar trace lets a '
            'plain toself line beside it fill as well',
      );
    });

    test('condition 5 — a trace with no plottable point paints nothing', () {
      expect(
        _polarDelegate(<FluentLineChartSeries>[
          _polarSeries(plottable: false),
        ]).scatterPolarFillsFor(_polarCtx()),
        isEmpty,
        reason:
            'LineChart.tsx:1330 — d3Line() returns null once defined() has '
            'rejected every point, so no <path> is pushed at :1331',
      );
    });

    test('an uncoloured trace takes its palette entry', () {
      expect(
        _polarDelegate(<FluentLineChartSeries>[
          _polarSeries(colour: null),
          _polarSeries(legend: 'second', colour: null),
        ]).scatterPolarFillsFor(_polarCtx()).map((area) => area.fill).toList(),
        <Color>[FluentDataVizPalette.next(1), FluentDataVizPalette.next(0)],
        reason:
            'lineColor is _points[i].color, already defaulted to '
            'getNextColor(index, 0) at LineChart.tsx:277-278, and :535 walks '
            'the series last first',
      );
    });

    test('high contrast flattens the area and its outline differently', () {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      final colours = FluentChartColors.of(theme);
      final area = _polarDelegate(<FluentLineChartSeries>[
        _polarSeries(),
      ], theme: theme).scatterPolarFillsFor(_polarCtx()).single;
      expect(
        area.fill,
        colours.flattenMark(_kSeriesColour),
        reason: 'spec §5.3 — a series mark flattens to the system foreground',
      );
      expect(
        area.stroke,
        colours.flattenMarkStroke(_kSeriesColour),
        reason:
            'upstream spells lineColor at both LineChart.tsx:1335 and :1337; '
            'flattening both to CanvasText would erase the 2px outline',
      );
      expect(
        area.fill,
        isNot(area.stroke),
        reason: 'flattening both the same way is the defect §5.3 forbids',
      );
    });

    test('the area declares no hit region', () {
      expect(
        _polarDelegate(<FluentLineChartSeries>[
          _polarSeries(),
        ]).buildHitRegions(_polarCtx(), _polarLayout()),
        isEmpty,
        reason:
            'pointerEvents="none" (LineChart.tsx:1340) — the area is painted '
            'onto the canvas and declares nothing the shell can hover, focus '
            'or narrate',
      );
    });

    testWidgets('a mounted scatterpolar chart paints its closed area', (
      tester,
    ) async {
      // The gate at `LineChart.tsx:1318` and the `<path>` at `:1332-1341` live
      // inside `_createLines`, so nothing short of the real widget proves they
      // are reached: `scatterPolarFillPath` alone is a helper nobody calls.
      final recorder = await _paintChart(tester, _polarData());
      final fills = recorder.fills.toList();
      expect(
        fills,
        hasLength(1),
        reason:
            'the four-point scatterpolar trace of _polarData clears all four '
            'conjuncts of LineChart.tsx:1318, so exactly one filled <path> is '
            'pushed at :1331',
      );
      final fill = fills.single;
      expect(
        // Compared as packed bytes, not as Colors: a Paint round-trips its
        // channels through float32, so two colours that print identically are
        // not `==`.
        fill.colour.toARGB32(),
        _kSeriesColour.withValues(alpha: kScatterPolarFillOpacity).toARGB32(),
        reason:
            'fill={lineColor} at LineChart.tsx:1335 with fillOpacity 0.5 at '
            ':1336; the light theme flattens to the series colour unchanged',
      );
      expect(
        fill.path!.computeMetrics().single.isClosed,
        isTrue,
        reason:
            'LineChart.tsx:1334 appends a literal Z, which closes the contour; '
            'an open contour would still fill, so isClosed and not contains() '
            'is what proves the Z happened',
      );
      expect(
        fill.path!.contains(fill.path!.getBounds().center),
        isTrue,
        reason:
            'the four points are a rhombus about the scaled origin, so its own '
            'centre is interior — an empty or collapsed path would not contain '
            'it',
      );
      final strokes = recorder.fillStrokes.toList();
      expect(
        strokes,
        hasLength(1),
        reason:
            'stroke={lineColor} strokeWidth={2} strokeOpacity={0.8} at '
            'LineChart.tsx:1337-1339 outlines the same area exactly once',
      );
      expect(
        strokes.single.colour.toARGB32(),
        _kSeriesColour
            .withValues(alpha: kScatterPolarFillStrokeOpacity)
            .toARGB32(),
        reason: 'LineChart.tsx:1337 and :1339',
      );
    });

    testWidgets('the area sits above its own line and below its markers', (
      tester,
    ) async {
      // `LineChart.tsx:1331` pushes the fill onto `linesForLine`, which
      // `:1363-1365` renders after `bordersForLine` and before `pointsForLine`.
      final recorder = await _paintChart(tester, _polarData());
      final fillIndex = recorder.ops.indexOf(recorder.fills.single);
      expect(
        fillIndex,
        greaterThan(recorder.ops.lastIndexWhere((op) => op.path == null)),
        reason:
            'every stroked line — the axes, the gridlines and this series own '
            'segments — is drawn before the fill, because LineChart.tsx:1331 '
            'appends to linesForLine after the segment loop closes at :1313',
      );
      expect(
        fillIndex,
        lessThan(recorder.ops.indexWhere(_isMarker)),
        reason:
            'pointsForLine renders after linesForLine (LineChart.tsx:1364-1365)'
            ', so a marker never disappears under its own trace fill',
      );
    });
  });
}

/// One recorded canvas operation, reduced to the fields the assertions read.
///
/// [path] is null for a `drawLine`, which is how a stroked segment is told
/// apart from a filled area without comparing geometry.
class _Op {
  const _Op({
    required this.path,
    required this.colour,
    required this.style,
    required this.strokeWidth,
  });

  final Path? path;
  final Color colour;
  final PaintingStyle style;
  final double strokeWidth;
}

/// Records what the mounted chart's painter draws, in paint order.
///
/// `implements Canvas` plus `noSuchMethod`, the same trick the other chart
/// tests use: the subject is the paint order and the paint fields, not pixels.
class _PolarRecorder implements Canvas {
  final List<_Op> ops = <_Op>[];

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) => ops.add(
    _Op(
      path: null,
      colour: paint.color,
      style: paint.style,
      strokeWidth: paint.strokeWidth,
    ),
  );

  @override
  void drawPath(Path path, Paint paint) => ops.add(
    _Op(
      path: path,
      colour: paint.color,
      style: paint.style,
      strokeWidth: paint.strokeWidth,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  /// The filled areas: a path whose alpha is `fillOpacity` 0.5
  /// (`LineChart.tsx:1336`). Nothing else under the shell fills at that alpha —
  /// a marker fills at its legend opacity, which is 1 with no legend
  /// highlighted.
  Iterable<_Op> get fills => ops.where(
    (op) =>
        op.path != null &&
        op.style == PaintingStyle.fill &&
        op.colour.a == kScatterPolarFillOpacity,
  );

  /// The 2px outlines of those areas (`LineChart.tsx:1338`).
  Iterable<_Op> get fillStrokes => ops.where(
    (op) =>
        op.path != null &&
        op.style == PaintingStyle.stroke &&
        op.strokeWidth == kScatterPolarFillStrokeWidth,
  );
}

/// Whether [op] is a data-point marker: a path filled at full opacity.
bool _isMarker(_Op op) =>
    op.path != null && op.style == PaintingStyle.fill && op.colour.a == 1;

/// The trace colour, named so a flattening assertion has something other than a
/// palette entry to compare against.
const Color _kSeriesColour = Color(0xFF0078D4);

/// North, east, south and west on the unit circle — the `-1..1` box
/// `LineChart.tsx:1922` pins a scatterpolar chart's y axis to. Four points
/// clear the `>= 3` gate at `:1318` with one to spare.
const List<(double, double)> _kRhombus = <(double, double)>[
  (0, 1),
  (1, 0),
  (0, -1),
  (-1, 0),
];

/// Where [_polarCtx] maps the domain origin, which is interior to the rhombus.
const Offset _kScaledOrigin = Offset(100, 100);

/// One `mode: 'scatterpolar'`, `fill: 'toself'` trace over [_kRhombus].
///
/// [points] truncates the ring, [plottable] sends every x to NaN, and a null
/// [mode], [fill] or [colour] switches off the matching upstream condition.
FluentLineChartSeries _polarSeries({
  String legend = 'radar',
  String? fill = 'toself',
  String? mode = 'scatterpolar',
  int points = 4,
  Color? colour = _kSeriesColour,
  bool plottable = true,
}) => FluentLineChartSeries(
  legend: legend,
  color: colour,
  lineOptions: FluentLineOptions(
    fill: fill,
    // `utilities.ts:2207` compares the whole mode literal, so the parsed flag
    // set is all false and only `upstreamName` carries it.
    mode: mode == null ? null : FluentLineMode.parse(mode),
  ),
  data: <FluentLineChartDataPoint>[
    for (final (x, y) in _kRhombus.take(points))
      FluentLineChartDataPoint(x: plottable ? x : double.nan, y: y),
  ],
);

/// A [FluentLineChartDelegate] over [series] with nothing mounted.
FluentLineChartDelegate _polarDelegate(
  List<FluentLineChartSeries> series, {
  FluentThemeData? theme,
  String selectedLegend = '',
  String? activeLegend,
}) {
  final resolved =
      theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  return FluentLineChartDelegate(
    series: series,
    style: resolveFluentLineChartStyle(resolved),
    colors: FluentChartColors.of(resolved),
    measurer: FluentChartTextMeasurer(),
    textStyles: FluentChartTextStyles.of(resolved),
    selectedLegend: selectedLegend,
    activeLegend: activeLegend,
  );
}

/// Both axes over the scatterpolar domain `-1..1` (`LineChart.tsx:1922`),
/// mapped to a 200px square with y inverted the way a screen scale is.
FluentCartesianChildContext _polarCtx() => FluentCartesianChildContext(
  xScale: d3.scaleLinear()
    ..domainOf(<double>[-1, 1])
    ..rangeOf(<double>[0, 200]),
  yScalePrimary: d3.scaleLinear()
    ..domainOf(<double>[-1, 1])
    ..rangeOf(<double>[200, 0]),
  containerWidth: 200,
  containerHeight: 200,
);

/// The layout [_polarCtx] belongs to, needed only by `buildHitRegions`.
FluentCartesianLayout _polarLayout() => FluentCartesianLayout.resolve(
  size: const Size(200, 200),
  margins: const FluentChartMargins(left: 0, right: 0, top: 0, bottom: 0),
  xAxisLabelReserve: 0,
  isRtl: false,
  startFromX: 0,
);

/// One `mode: 'scatterpolar'`, `fill: 'toself'` trace, ready to mount.
FluentChartData _polarData() =>
    FluentChartData(lineChartData: <FluentLineChartSeries>[_polarSeries()]);

/// Mounts [data] in a real [FluentLineChart] and replays its painter into a
/// recorder.
Future<_PolarRecorder> _paintChart(
  WidgetTester tester,
  FluentChartData data,
) async {
  await tester.pumpWidget(
    FluentApp(
      theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(
        child: SizedBox(
          width: 400,
          height: 400,
          child: FluentLineChart(data: data),
        ),
      ),
    ),
  );
  // The plot is the first CustomPaint under the shell: the Column puts it ahead
  // of the legend (`cartesian_chart.dart:370-382`).
  final plot = find
      .descendant(
        of: find.byType(FluentCartesianChart),
        matching: find.byType(CustomPaint),
      )
      .first;
  final recorder = _PolarRecorder();
  tester
      .widget<CustomPaint>(plot)
      .painter!
      .paint(recorder, tester.getSize(plot));
  return recorder;
}
