import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/area_chart.dart';
import 'package:fluent_2_web/src/charts/area_chart_style.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_layout.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_series_delegate.dart';
import 'package:fluent_2_web/src/charts/chrome/chart_popover.dart';
import 'package:fluent_2_web/src/charts/internal/chart_colors.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_measurer.dart';
import 'package:fluent_2_web/src/charts/internal/d3/curves.dart' as d3;
import 'package:fluent_2_web/src/charts/internal/d3/scale_linear.dart' as d3;
import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2_web/src/charts/model/cartesian_series.dart';
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// A series whose points sit at x = 1, 2, 3 … in [ys] order.
FluentLineChartSeries _series(String legend, List<double> ys) =>
    FluentLineChartSeries(
      legend: legend,
      data: <Object>[
        for (var i = 0; i < ys.length; i++)
          FluentLineChartDataPoint(x: i + 1, y: ys[i]),
      ],
    );

List<FluentLineChartSeries> _twoSeries({
  required List<double> a,
  required List<double> b,
}) => <FluentLineChartSeries>[_series('a', a), _series('b', b)];

/// Two series that disagree on their x sets: `b` never reports x = 2.
List<FluentLineChartSeries> _seriesWithHoles() => <FluentLineChartSeries>[
  _series('a', <double>[1, 2, 3]),
  const FluentLineChartSeries(
    legend: 'b',
    data: <Object>[
      FluentLineChartDataPoint(x: 1, y: 10),
      FluentLineChartDataPoint(x: 3, y: 30),
    ],
  ),
];

/// One series that reports x = 1 twice.
List<FluentLineChartSeries> _seriesWithDuplicateX() => <FluentLineChartSeries>[
  const FluentLineChartSeries(
    legend: 'a',
    data: <Object>[
      FluentLineChartDataPoint(x: 1, y: 10),
      FluentLineChartDataPoint(x: 1, y: 20),
      FluentLineChartDataPoint(x: 2, y: 30),
    ],
  ),
];

/// Three series that agree on x = 1, 2, 3.
FluentChartData _threeSeriesData({String? chartTitle}) => FluentChartData(
  chartTitle: chartTitle,
  lineChartData: <FluentLineChartSeries>[
    _series('a', <double>[10, 20, 30]),
    _series('b', <double>[5, 15, 25]),
    _series('c', <double>[1, 2, 3]),
  ],
);

/// Series 0 carries x = 1, 2, 3; series 1 and 2 also carry the halves between
/// them, so a bisector run over the wrong series answers 1.5 where series 0
/// answers 2.
FluentChartData _seriesZeroIsCoarserData() => FluentChartData(
  lineChartData: <FluentLineChartSeries>[
    _series('coarse', <double>[10, 20, 30]),
    _halfStepSeries('fine1'),
    _halfStepSeries('fine2'),
  ],
);

/// A series at x = 1, 1.5, 2, 2.5, 3.
FluentLineChartSeries _halfStepSeries(String legend) => FluentLineChartSeries(
  legend: legend,
  data: <Object>[
    for (var i = 0; i < 5; i++)
      FluentLineChartDataPoint(x: 1 + i * 0.5, y: 10.0 + i),
  ],
);

/// One series at x = 1, 2, 3 — the tie-break case.
FluentChartData _evenlySpacedData() => FluentChartData(
  lineChartData: <FluentLineChartSeries>[
    _series('a', <double>[10, 20, 30]),
  ],
);

/// A dataset whose only series reports x = 1 twice.
FluentChartData _duplicateXData() =>
    FluentChartData(lineChartData: _seriesWithDuplicateX());

/// The delegate the shell is currently rendering.
FluentAreaChartDelegate _renderedDelegate(WidgetTester tester) =>
    tester
            .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
            .delegate
        as FluentAreaChartDelegate;

/// The captured x-axis domain path of [story].
///
/// `d3-axis` writes the bottom axis as `M{r0},{k}V0.5H{r1}V{k}` and the left
/// axis as `M{-k},{r0}H0.5V{r1}H{-k}` (`d3-axis/src/axis.js:60-70`), so the
/// horizontal one is the domain path with exactly one `H`.
OracleElement _xDomainPath(OracleStory story) {
  final domains = story
      .byTag('path')
      .where(
        (element) =>
            element.fill == null &&
            element.d != null &&
            tokeniseSvgPath(element.d!).where((t) => t == 'H').length == 1,
      )
      .toList(growable: false);
  expect(
    domains,
    hasLength(1),
    reason:
        '${story.id} must contain exactly one horizontal axis domain path; a '
        'filtered fixture loop without a count guard asserts nothing when the '
        'filter goes empty.',
  );
  return domains.single;
}

/// The on-path vertices of [d]: the `M` point and the end point of every
/// command after it, with the cubic control points dropped.
///
/// `d3-shape`'s area writes the top edge first, then a single `L` onto the
/// baseline and the bottom edge in reverse (`AreaChart.tsx:671-678` builds it
/// with `.y0` and `.y1`), so the first half of this list is `yScale(values[1])`
/// and the reversed second half is `yScale(values[0])`.
List<Offset> _vertices(String d) {
  final tokens = tokeniseSvgPath(d);
  final out = <Offset>[];
  var i = 0;
  while (i < tokens.length) {
    final command = tokens[i++];
    switch (command) {
      case 'M':
      case 'L':
        out.add(Offset(double.parse(tokens[i++]), double.parse(tokens[i++])));
      case 'C':
        // The two control points are not on the path.
        i += 4;
        out.add(Offset(double.parse(tokens[i++]), double.parse(tokens[i++])));
      case 'Z':
        break;
      default:
        fail('unexpected path command "$command" in $d');
    }
  }
  return out;
}

/// The top and bottom edge of one captured area path, both left to right.
({List<double> tops, List<double> bottoms}) _edges(String d) {
  final vertices = _vertices(d);
  expect(
    vertices.length.isEven && vertices.isNotEmpty,
    isTrue,
    reason: 'an area path is a top edge and a bottom edge of equal length',
  );
  final half = vertices.length ~/ 2;
  return (
    tops: <double>[for (final v in vertices.take(half)) v.dy],
    bottoms: <double>[
      for (final v in vertices.skip(half).toList().reversed) v.dy,
    ],
  );
}

/// The filled area paths of [story], in document order.
///
/// The stroked line over each area carries `fill="rgba(0,0,0,0)"` and the axis
/// domains carry `fill="none"`, so "has a fill and no stroke" selects exactly
/// the areas (`AreaChart.tsx:727-732` against `:696-701`).
List<OracleElement> _areaPaths(OracleStory story, int expectedCount) {
  final areas = story
      .byTag('path')
      .where((element) => element.fill != null && element.stroke == null)
      .toList(growable: false);
  expect(
    areas,
    hasLength(expectedCount),
    reason:
        '${story.id} must contain exactly $expectedCount filled area paths; a '
        'filtered fixture loop without a count guard asserts nothing when the '
        'filter goes empty.',
  );
  return areas;
}

/// Rebuilds the dataset the capture was drawn from, in pixel units.
///
/// The y scale is unknown, so the recovered values are pixel heights above
/// [baseline]: `value = baseline - y`. Any positive factor reproduces the same
/// stack — the carry is additive — so pixels are used directly and the
/// assertions are made back in pixel space.
List<FluentLineChartSeries> _recoverSeries(
  List<OracleElement> areas,
  double baseline,
) => <FluentLineChartSeries>[
  for (var i = 0; i < areas.length; i++)
    () {
      final edges = _edges(areas[i].d!);
      return _series('layer$i', <double>[
        for (var j = 0; j < edges.tops.length; j++)
          edges.bottoms[j] - edges.tops[j],
      ]);
    }(),
];

/// The on-path vertices of the top edge of one captured area path, with their
/// x pixels kept — [_edges] throws the x away because the dataset tests only
/// need the heights, but the delegate tests need the x scale the capture was
/// drawn with.
List<Offset> _topVertices(String d) {
  final all = _vertices(d);
  expect(
    all.length.isEven && all.isNotEmpty,
    isTrue,
    reason: 'an area path is a top edge and a bottom edge of equal length',
  );
  return all.take(all.length ~/ 2).toList(growable: false);
}

/// Rebuilds a captured `d` attribute as a `dart:ui` [Path], so the delegate's
/// own path can be compared against it geometrically.
Path _pathOf(String d) {
  final tokens = tokeniseSvgPath(d);
  final path = Path();
  var i = 0;
  double next() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    switch (tokens[i++]) {
      case 'M':
        path.moveTo(next(), next());
      case 'L':
        path.lineTo(next(), next());
      case 'C':
        path.cubicTo(next(), next(), next(), next(), next(), next());
      case 'Z':
        path.close();
      case final String command:
        fail('unexpected path command "$command" in $d');
    }
  }
  return path;
}

/// [count] + 1 points along [path], evenly spaced by arc length.
///
/// Two paths built from the same commands sample identically, so this compares
/// the cubics themselves — bounds alone would not tell curveMonotoneX from
/// curveLinear.
List<Offset> _samplePath(Path path, int count) {
  final metric = path.computeMetrics().first;
  return <Offset>[
    for (var i = 0; i <= count; i++)
      metric.getTangentForOffset(metric.length * i / count)!.position,
  ];
}

/// A layout big enough to hold [_linearContext]; the delegate reads nothing off
/// it, but the shell hands one to every call.
FluentCartesianLayout _layout() => FluentCartesianLayout.resolve(
  size: const Size(700, 300),
  margins: const FluentChartMargins(left: 0, right: 0, top: 0, bottom: 0),
  xAxisLabelReserve: 0,
  isRtl: false,
  startFromX: 0,
);

/// Records the fills and strokes [FluentAreaChartDelegate.paintSeries] issues.
///
/// High-contrast flattening is a paint property; no geometry proves it, so the
/// only way to assert it is to capture the paints themselves.
class _RecordingCanvas implements Canvas {
  final List<Color> pathFills = <Color>[];
  final List<Color> pathStrokes = <Color>[];
  final List<Color> circleFills = <Color>[];
  final List<Color> circleStrokes = <Color>[];
  final List<double> circleRadii = <double>[];

  @override
  void drawPath(Path path, Paint paint) {
    (paint.style == PaintingStyle.stroke ? pathStrokes : pathFills).add(
      paint.color,
    );
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    circleRadii.add(radius);
    (paint.style == PaintingStyle.stroke ? circleStrokes : circleFills).add(
      paint.color,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final _delegateTheme = FluentThemeData.light(
  fontPlatform: FluentFontPlatform.web,
);

const _placeholder = Color(0xFF010203);
const _canvasText = Color(0xFFFFFFFF);
const _canvas = Color(0xFF000000);

/// The eleven-field colour set, so `isHighContrast` can be flipped without a
/// second [FluentThemeData].
FluentChartColors _colours({bool isHighContrast = false}) => FluentChartColors(
  axisText: _canvasText,
  axisTick: _placeholder,
  axisTitle: _placeholder,
  gridLine: _placeholder,
  markStroke: _placeholder,
  surface: _canvas,
  popoverSurface: _placeholder,
  tooltipSurface: _placeholder,
  legendDimmed: _placeholder,
  isHighContrast: isHighContrast,
);

/// A child context whose x scale maps `1..points` onto `0..width` and whose y
/// scale maps `0..yMax` onto `height..0`, so every assertion below is in the
/// pixel space the delegate actually paints in.
FluentCartesianChildContext _linearContext({
  required double width,
  int points = 3,
  double yMax = 100,
  double height = 300,
}) {
  final xScale = d3.scaleLinear()
    ..domainOf(<double>[1, points.toDouble()])
    ..rangeOf(<double>[0, width]);
  final yScale = d3.scaleLinear()
    ..domainOf(<double>[0, yMax])
    ..rangeOf(<double>[height, 0]);
  return FluentCartesianChildContext(
    xScale: xScale,
    yScalePrimary: yScale,
    containerWidth: width,
    containerHeight: height,
  );
}

FluentAreaChartDelegate _delegateFor(
  List<FluentLineChartSeries> series, {
  FluentAreaChartMode mode = FluentAreaChartMode.toNextY,
  List<String> selectedLegends = const <String>[],
  String? activeLegend,
  Object? nearestX,
  bool isCircleClicked = false,
  bool isPopoverOpen = false,
  bool isHighContrast = false,
}) => FluentAreaChartDelegate(
  series: series,
  dataSet: buildFluentAreaChartDataSet(
    series: series,
    mode: mode,
    hasSecondaryYScale: false,
    hasSelectedLegends: selectedLegends.isNotEmpty,
  ),
  style: resolveFluentAreaChartStyle(_delegateTheme),
  colors: _colours(isHighContrast: isHighContrast),
  measurer: FluentChartTextMeasurer(),
  selectedLegends: selectedLegends,
  activeLegend: activeLegend,
  nearestX: nearestX,
  isCircleClicked: isCircleClicked,
  isPopoverOpen: isPopoverOpen,
  mode: mode,
);

/// One series at x = 1, 2, 3, so the chart is a single stack.
FluentAreaChartDelegate _areaDelegate({
  FluentAreaChartMode mode = FluentAreaChartMode.toNextY,
  Object? nearestX,
  bool isCircleClicked = false,
  bool isHighContrast = false,
}) => _delegateFor(
  <FluentLineChartSeries>[
    _series('a', <double>[10, 20, 30]),
  ],
  mode: mode,
  nearestX: nearestX,
  isCircleClicked: isCircleClicked,
  isHighContrast: isHighContrast,
);

/// Two stacked series, which is what makes `_isMultiStackChart` true.
FluentAreaChartDelegate _multiStackDelegate({
  List<String> selectedLegends = const <String>[],
  String? activeLegend,
  bool isPopoverOpen = false,
}) => _delegateFor(
  _twoSeries(a: <double>[10, 20, 30], b: <double>[5, 15, 25]),
  selectedLegends: selectedLegends,
  activeLegend: activeLegend,
  isPopoverOpen: isPopoverOpen,
);

/// One series carrying exactly one datum.
FluentAreaChartDelegate _singlePointAreaDelegate() =>
    _delegateFor(<FluentLineChartSeries>[
      _series('a', <double>[10]),
    ]);

void main() {
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  group('buildFluentAreaChartDataSet', () {
    test('tonexty stacks each layer on the previous one', () {
      final set = buildFluentAreaChartDataSet(
        series: _twoSeries(a: <double>[1, 2, 3], b: <double>[10, 20, 30]),
        mode: FluentAreaChartMode.toNextY,
        hasSecondaryYScale: false,
        hasSelectedLegends: false,
      );
      expect(
        set.layers[1].map((p) => p.hi).toList(),
        <double>[11, 22, 33],
        reason: 'd3.stack carries the running total, AreaChart.tsx:312-320',
      );
      expect(
        set.maxOfYVal,
        33,
        reason: 'maxOfYVal is d3Max over the LAST layer, AreaChart.tsx:313',
      );
    });

    test('tozeroy flattens every layer onto the baseline', () {
      final set = buildFluentAreaChartDataSet(
        series: _twoSeries(a: <double>[1, 2], b: <double>[10, 20]),
        mode: FluentAreaChartMode.toZeroY,
        hasSecondaryYScale: false,
        hasSelectedLegends: false,
      );
      expect(
        set.layers[1].map((p) => p.lo).toList(),
        <double>[0, 0],
        reason: 'tozeroy uses [0, d[key]] literally, AreaChart.tsx:296-310',
      );
      expect(
        set.maxOfYVal,
        20,
        reason: 'tozeroy takes the max across all keys, not the last layer',
      );
    });

    test('a secondary y scale forces tozeroy even in tonexty mode', () {
      final set = buildFluentAreaChartDataSet(
        series: _twoSeries(a: <double>[1, 2], b: <double>[10, 20]),
        mode: FluentAreaChartMode.toNextY,
        hasSecondaryYScale: true,
        hasSelectedLegends: false,
      );
      expect(
        set.layers[1].map((p) => p.lo).toList(),
        <double>[0, 0],
        reason: '_shouldFillToZeroY at AreaChart.tsx:1065-1067',
      );
    });

    test('missing x values are back-filled with zero and then sorted', () {
      final set = buildFluentAreaChartDataSet(
        series: _seriesWithHoles(),
        mode: FluentAreaChartMode.toNextY,
        hasSecondaryYScale: false,
        hasSelectedLegends: false,
      );
      expect(
        set.hasMissingXValues,
        isTrue,
        reason: 'AreaChart.tsx:891-937 detects the union mismatch',
      );
      expect(
        set.rows.map((r) => r.xValue).toList(),
        <Object>[1, 2, 3],
        reason:
            'each series is re-sorted ascending after back-filling, :909-921',
      );
      expect(
        set.rows[1].values,
        <double>[2, 0],
        reason: 'the injected point carries y: 0, AreaChart.tsx:909-913',
      );
    });

    test('duplicate x values are detected and suppress the popover', () {
      final set = buildFluentAreaChartDataSet(
        series: _seriesWithDuplicateX(),
        mode: FluentAreaChartMode.toNextY,
        hasSecondaryYScale: false,
        hasSelectedLegends: false,
      );
      expect(
        set.hasDuplicateXValues,
        isTrue,
        reason: 'AreaChart.tsx:1093 forces isPopoverOpen false in this case',
      );
    });

    test('multi-stack is one-layer-or-more when legends are controlled', () {
      final controlled = buildFluentAreaChartDataSet(
        series: _twoSeries(a: <double>[1], b: <double>[2]).sublist(0, 1),
        mode: FluentAreaChartMode.toNextY,
        hasSecondaryYScale: false,
        hasSelectedLegends: true,
      );
      expect(
        controlled.isMultiStack,
        isTrue,
        reason: 'AreaChart.tsx:328-330 uses >= 1 when selectedLegends is set',
      );
      final uncontrolled = buildFluentAreaChartDataSet(
        series: _twoSeries(a: <double>[1], b: <double>[2]).sublist(0, 1),
        mode: FluentAreaChartMode.toNextY,
        hasSecondaryYScale: false,
        hasSelectedLegends: false,
      );
      expect(uncontrolled.isMultiStack, isFalse, reason: 'and > 1 otherwise');
    });

    test('a series without a colour takes the palette in index order', () {
      final set = buildFluentAreaChartDataSet(
        series: _twoSeries(a: <double>[1], b: <double>[2]),
        mode: FluentAreaChartMode.toNextY,
        hasSecondaryYScale: false,
        hasSelectedLegends: false,
      );
      expect(
        set.colours[1].toARGB32(),
        FluentDataVizPalette.next(1).toARGB32(),
        reason: 'getNextColor(index, 0) at AreaChart.tsx:929',
      );
    });
  });

  group('buildFluentAreaChartDataSet against the oracle corpus', () {
    test('reproduces every stacked edge of charts-areachart--area-chart-'
        'multiple', () {
      final story = loadOracleStory('charts-areachart--area-chart-multiple');
      final areas = _areaPaths(story, 3);
      final captured = <({List<double> tops, List<double> bottoms})>[
        for (final area in areas) _edges(area.d!),
      ];
      // Layer 0 sits on the plot floor, so its bottom edge is the baseline.
      final baseline = captured.first.bottoms.first;
      final set = buildFluentAreaChartDataSet(
        series: _recoverSeries(areas, baseline),
        mode: FluentAreaChartMode.toNextY,
        hasSecondaryYScale: false,
        hasSelectedLegends: false,
      );
      expect(
        set.layers,
        hasLength(3),
        reason: 'one layer per captured area path',
      );
      for (final edges in captured) {
        expect(
          edges.tops,
          hasLength(10),
          reason:
              'each captured layer spans the same ten x values; without this '
              'guard an empty edge list would assert nothing below',
        );
      }
      for (var i = 0; i < captured.length; i++) {
        for (var j = 0; j < captured[i].tops.length; j++) {
          expectOracleNumber(
            'layer $i point $j top — yScale(values[1]), AreaChart.tsx:677',
            captured[i].tops[j],
            baseline - set.layers[i][j].hi,
          );
          expectOracleNumber(
            'layer $i point $j bottom — yScale(values[0]), AreaChart.tsx:675',
            captured[i].bottoms[j],
            baseline - set.layers[i][j].lo,
          );
        }
      }
      expectOracleNumber(
        'maxOfYVal is the highest point of the last layer, :313',
        baseline - captured.last.tops.reduce((a, b) => a < b ? a : b),
        set.maxOfYVal,
      );
    });

    test('the secondary-y-axis story draws every layer from the baseline', () {
      final story = loadOracleStory(
        'charts-areachart--area-chart-secondary-y-axis',
      );
      final areas = _areaPaths(story, 2);
      final captured = <({List<double> tops, List<double> bottoms})>[
        for (final area in areas) _edges(area.d!),
      ];
      final baseline = captured.first.bottoms.first;
      for (final edges in captured) {
        expect(
          edges.tops,
          hasLength(15),
          reason:
              'each captured layer spans the same fifteen x values; without '
              'this guard an empty edge list would assert nothing below',
        );
        expect(
          edges.bottoms.every(
            (y) => (y - baseline).abs() <= kOracleGeometryTolerance,
          ),
          isTrue,
          reason:
              'a secondary y axis forces tozeroy, so every captured area '
              'returns to the same floor, AreaChart.tsx:1065-1067',
        );
      }
      final set = buildFluentAreaChartDataSet(
        series: _recoverSeries(areas, baseline),
        mode: FluentAreaChartMode.toNextY,
        hasSecondaryYScale: true,
        hasSelectedLegends: false,
      );
      for (var i = 0; i < captured.length; i++) {
        for (var j = 0; j < captured[i].tops.length; j++) {
          expectOracleNumber(
            'layer $i point $j top',
            captured[i].tops[j],
            baseline - set.layers[i][j].hi,
          );
          expect(
            set.layers[i][j].lo,
            0,
            reason: 'tozeroy starts every layer at zero, AreaChart.tsx:302',
          );
        }
      }
    });
  });

  group('resolveFluentAreaChartStyle', () {
    test('matches the paint the multiple story was captured with', () {
      final style = resolveFluentAreaChartStyle(theme);
      final story = loadOracleStory('charts-areachart--area-chart-multiple');
      final area = _areaPaths(story, 3).first;
      expectOracleNumber(
        'area fill-opacity — _getOpacity, AreaChart.tsx:621',
        area.fillOpacity,
        style.areaOpacity!.resolve(<WidgetState>{})!,
      );
      expectOracleNumber(
        'area opacity — layerOpacity in tonexty mode is opacity || 1, :685',
        area.opacity,
        1,
      );
      final lines = story
          .byTag('path')
          .where((element) => element.stroke != null && element.fill != null)
          .toList(growable: false);
      expect(
        lines,
        hasLength(3),
        reason:
            'one stroked line per area, each with a transparent fill '
            '(AreaChart.tsx:696-701)',
      );
      for (final line in lines) {
        expectOracleNumber(
          'line stroke-width, AreaChart.tsx:700',
          line.strokeWidth,
          style.lineStrokeWidth!.resolve(<WidgetState>{})!,
        );
        expectOracleNumber(
          'multi-stack line opacity with nothing highlighted, :632',
          line.opacity,
          style.lineOpacityMultiStack!.resolve(<WidgetState>{})!,
        );
      }
      final circles = story.byTag('circle');
      expect(
        circles,
        hasLength(30),
        reason: 'three series of ten points each carry a marker circle',
      );
      for (final circle in circles) {
        expectOracleNumber(
          'marker stroke-width, AreaChart.tsx:780',
          circle.strokeWidth,
          style.pointStrokeWidth!.resolve(<WidgetState>{})!,
        );
        expectOracleNumber(
          'an unhovered marker has radius 0, _getCircleRadius :866',
          circle.r!,
          0,
        );
      }
    });

    test('the tozeroy layer opacity is the one the secondary-y story '
        'captured', () {
      final style = resolveFluentAreaChartStyle(theme);
      final story = loadOracleStory(
        'charts-areachart--area-chart-secondary-y-axis',
      );
      for (final area in _areaPaths(story, 2)) {
        expectOracleNumber(
          'layerOpacity is 0.8 once tozeroy is forced, AreaChart.tsx:685',
          area.opacity,
          style.areaOpacityToZeroY!.resolve(<WidgetState>{})!,
        );
      }
    });

    test('dims a deselected layer to one tenth', () {
      final style = resolveFluentAreaChartStyle(theme);
      expect(
        style.areaOpacity!.resolve(<WidgetState>{WidgetState.disabled}),
        0.1,
        reason: 'AreaChart.tsx:623 dims an unhighlighted stack to 0.1',
      );
    });

    test('the highlighted line is hidden rather than emphasised', () {
      final style = resolveFluentAreaChartStyle(theme);
      expect(
        style.lineOpacityMultiStack!.resolve(<WidgetState>{
          WidgetState.hovered,
        }),
        0,
        reason: 'AreaChart.tsx:637 returns 0 for the highlighted legend',
      );
      expect(
        style.lineOpacityMultiStack!.resolve(<WidgetState>{
          WidgetState.selected,
        }),
        1,
        reason: 'AreaChart.tsx:634 raises every line while the popover is open',
      );
    });

    test('the active marker inverts to the canvas colour', () {
      final style = resolveFluentAreaChartStyle(theme);
      expect(
        style.activePointFillColor!.resolve(<WidgetState>{})!.toARGB32(),
        theme.colors.neutralBackground1.toARGB32(),
        reason: 'AreaChart.tsx:647 fills with colorNeutralBackground1',
      );
    });

    test('the hover rule is a dashed half-opacity hairline', () {
      final style = resolveFluentAreaChartStyle(theme);
      expect(
        style.hoverLineWidth!.resolve(<WidgetState>{}),
        1,
        reason: 'AreaChart.tsx:835 strokeWidth={1}',
      );
      expect(
        style.hoverLineDashPattern!.resolve(<WidgetState>{}),
        <double>[5.5],
        reason: 'AreaChart.tsx:836 strokeDasharray={5.5}',
      );
      expect(
        style.hoverLineOpacity!.resolve(<WidgetState>{}),
        0.5,
        reason: 'AreaChart.tsx:838 opacity={0.5}',
      );
    });

    test('merge lets the caller win field by field', () {
      final merged = resolveFluentAreaChartStyle(
        theme,
      ).merge(FluentAreaChartStyle.from(pointRadius: 12));
      expect(
        merged.pointRadius!.resolve(<WidgetState>{}),
        12.0,
        reason: 'the overriding style must win',
      );
      expect(
        merged.singlePointRadius!.resolve(<WidgetState>{}),
        6.0,
        reason: 'fields absent from the override must be inherited, :715',
      );
    });

    test('copyWith replaces one field and keeps the rest', () {
      final base = FluentAreaChartStyle.from(pointRadius: 8, hoverLineWidth: 1);
      final copy = base.copyWith(
        hoverLineWidth: const WidgetStatePropertyAll<double?>(2),
      );
      expect(
        copy.hoverLineWidth!.resolve(<WidgetState>{}),
        2.0,
        reason: 'copyWith must replace the named field',
      );
      expect(
        copy.pointRadius!.resolve(<WidgetState>{}),
        8.0,
        reason: 'copyWith must keep every other field',
      );
    });

    test('equal styles compare equal and hash equal', () {
      final a = FluentAreaChartStyle.from(pointRadius: 8);
      final b = FluentAreaChartStyle.from(pointRadius: 8);
      expect(
        a,
        b,
        reason: 'value equality is part of the house style contract',
      );
      expect(a.hashCode, b.hashCode, reason: 'hashCode must agree with ==');
    });
  });

  group('FluentAreaChartTheme', () {
    testWidgets('supplies a style to the subtree', (tester) async {
      FluentAreaChartStyle? seen;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: FluentAreaChartTheme(
            style: FluentAreaChartStyle.from(pointRadius: 3),
            child: Builder(
              builder: (context) {
                seen = FluentAreaChartTheme.maybeOf(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(
        seen?.pointRadius!.resolve(<WidgetState>{}),
        3.0,
        reason: 'maybeOf must read the nearest theme',
      );
    });
  });

  group('FluentAreaChartDelegate', () {
    test('the default curve is monotone-X, not linear', () {
      final delegate = _areaDelegate();
      expect(
        delegate.curveFactory,
        same(d3.curveMonotoneX),
        reason:
            'parity: AreaChart.tsx:7 imports curveMonotoneX under the '
            'misleading alias d3CurveBasis',
      );
    });

    test('the area top edge and the line share control points', () {
      final delegate = _areaDelegate();
      final layer = delegate.layersFor(_linearContext(width: 700)).single;
      final areaTop = layer.areaPath.getBounds();
      final lineBounds = layer.linePath.getBounds();
      expect(
        areaTop.left,
        closeTo(lineBounds.left, 1e-9),
        reason: 'the fill must sit exactly under the stroke',
      );
      expect(
        areaTop.top,
        closeTo(lineBounds.top, 1e-9),
        reason: 'both use the same y1 accessor and the same curve',
      );
    });

    test('a single-datum layer resolves a circle, not an area', () {
      final delegate = _singlePointAreaDelegate();
      expect(
        delegate.layersFor(_linearContext(width: 700)).single.singlePointCentre,
        isNotNull,
        reason: 'AreaChart.tsx:711-725 swaps the path for an r=6 circle',
      );
    });

    test('a single-stack chart holds fill 0.7 and line 1', () {
      final delegate = _areaDelegate();
      final layer = delegate.layersFor(_linearContext(width: 700)).single;
      expect(
        layer.fillOpacity,
        0.7,
        reason: 'AreaChart.tsx:620 returns 0.7 when not multi-stack',
      );
      expect(
        layer.lineOpacity,
        1,
        reason: 'AreaChart.tsx:630 returns 1 when not multi-stack',
      );
    });

    test('a highlighted line in a multi-stack chart goes to opacity ZERO', () {
      final delegate = _multiStackDelegate(selectedLegends: <String>['a']);
      expect(
        delegate.layersFor(_linearContext(width: 700))[0].lineOpacity,
        0,
        reason:
            'parity: AreaChart.tsx:637 sets the highlighted line to 0 and '
            'lets the fill carry it',
      );
      expect(
        delegate.layersFor(_linearContext(width: 700))[1].lineOpacity,
        0.1,
        reason: 'the non-highlighted line drops to 0.1',
      );
    });

    test('an open popover lifts every multi-stack line to 1', () {
      final delegate = _multiStackDelegate(isPopoverOpen: true);
      expect(
        delegate.layersFor(_linearContext(width: 700))[0].lineOpacity,
        1,
        reason: 'AreaChart.tsx:634 overwrites the 0.3 rest value',
      );
    });

    test('tozeroy pins every layer opacity to 0.8', () {
      final delegate = _areaDelegate(mode: FluentAreaChartMode.toZeroY);
      expect(
        delegate.layersFor(_linearContext(width: 700)).single.layerOpacity,
        0.8,
        reason: 'AreaChart.tsx:685',
      );
    });

    test('circles are invisible until hovered or focused', () {
      final delegate = _areaDelegate();
      expect(
        delegate.circleRadiusFor(0, 2),
        0,
        reason: 'AreaChart.tsx:855-868 returns 0 for an unhighlighted point',
      );
      expect(
        _areaDelegate(nearestX: 3).circleRadiusFor(0, 2),
        8,
        reason: 'the nearest circle grows to pointOptions.r ?? 8, :749',
      );
      expect(
        _areaDelegate(nearestX: 3, isCircleClicked: true).circleRadiusFor(0, 2),
        1,
        reason: 'a clicked circle shrinks to 1, :861',
      );
    });

    test('a dimmed legend hides its circles outright', () {
      final delegate = _multiStackDelegate(selectedLegends: <String>['a']);
      expect(
        delegate.circleRadiusFor(1, 2),
        0,
        reason:
            'AreaChart.tsx:857-859 returns 0 before the nearest-point checks '
            'once another legend owns the highlight',
      );
    });

    test('the stack hit region carries every series reading', () {
      final delegate = _multiStackDelegate();
      final regions = delegate.buildHitRegions(
        _linearContext(width: 700),
        _layout(),
      );
      expect(regions, hasLength(3), reason: 'one region per distinct x value');
      expect(
        regions[1].popoverData.isCalloutForStack,
        isTrue,
        reason: 'AreaChart.tsx:1105 opens the stacked popover body',
      );
      expect(
        regions[1].popoverData.yValues!.map((v) => v.y).toList(),
        <double>[20, 15],
        reason: 'the popover lists the raw y of every series at that x',
      );
    });
  });

  group('FluentAreaChartDelegate under forced colours', () {
    _RecordingCanvas paint({required bool isHighContrast}) {
      final delegate = _areaDelegate(
        nearestX: 3,
        isHighContrast: isHighContrast,
      );
      final canvas = _RecordingCanvas();
      delegate.paintSeries(
        canvas,
        _linearContext(width: 700),
        _layout(),
        delegate.colors,
      );
      return canvas;
    }

    // The alpha channel carries `layerOpacity * fillOpacity`, which the
    // opacity tests above already pin, so the flattening assertions compare
    // the RGB triple only.
    int rgb(Color colour) => colour.toARGB32() & 0x00FFFFFF;

    test('an ordinary theme keeps the series colour on fill and stroke', () {
      final canvas = paint(isHighContrast: false);
      final palette = rgb(FluentDataVizPalette.next(0));
      expect(
        rgb(canvas.pathFills.single),
        palette,
        reason: 'flattenMark is the identity outside high contrast',
      );
      expect(
        rgb(canvas.pathStrokes.single),
        palette,
        reason: 'and so is flattenMarkStroke',
      );
    });

    test('high contrast flattens the fill and keeps the line a hairline', () {
      final canvas = paint(isHighContrast: true);
      expect(
        rgb(canvas.pathFills.single),
        rgb(_canvasText),
        reason:
            'design spec section 5.3: a forced-colours browser rewrites every '
            'series fill to CanvasText, so FluentChartColors.flattenMark must '
            "be on the area body's fill",
      );
      expect(
        rgb(canvas.pathStrokes.single),
        rgb(_canvas),
        reason:
            'FluentChartColors.flattenMarkStroke sends the top edge to Canvas '
            'instead, which is the only thing keeping two stacked areas from '
            'merging into one indistinguishable CanvasText block',
      );
    });

    test('high contrast leaves the marker ring readable', () {
      final canvas = paint(isHighContrast: true);
      expect(
        rgb(canvas.circleFills.single),
        rgb(
          resolveFluentAreaChartStyle(
            _delegateTheme,
          ).activePointFillColor!.resolve(<WidgetState>{})!,
        ),
        reason:
            'AreaChart.tsx:647 inverts the nearest marker to '
            'colorNeutralBackground1, which is a theme token rather than a '
            'flattened series colour',
      );
      expect(
        rgb(canvas.circleStrokes.single),
        rgb(_canvasText),
        reason:
            'the ring keeps the flattenMark colour, so the inverted marker is '
            'still visible against the flattened area',
      );
    });
  });

  group('FluentAreaChartDelegate against the oracle corpus', () {
    test('regenerates every curve of charts-areachart--area-chart-basic', () {
      final story = loadOracleStory('charts-areachart--area-chart-basic');
      final areas = _areaPaths(story, 3);
      final lines = story
          .byTag('path')
          .where((element) => element.stroke != null && element.fill != null)
          .toList(growable: false);
      expect(
        lines,
        hasLength(3),
        reason:
            'one stroked top edge per area, each with a transparent fill '
            '(AreaChart.tsx:696-701); without this guard the loop below would '
            'assert nothing',
      );
      final tops = <List<Offset>>[
        for (final area in areas) _topVertices(area.d!),
      ];
      expect(
        tops.first,
        hasLength(15),
        reason: 'the story plots fifteen x values per layer',
      );
      final baseline = _edges(areas.first.d!).bottoms.first;
      final recovered = _recoverSeries(areas, baseline);
      // The recovered values are pixel heights above the captured baseline, so
      // the y scale that reproduces the capture is simply `baseline - value`
      // and the x scale is the even 44px step the capture was laid out on.
      final xScale = d3.scaleLinear()
        ..domainOf(<double>[1, tops.first.length.toDouble()])
        ..rangeOf(<double>[tops.first.first.dx, tops.first.last.dx]);
      final yScale = d3.scaleLinear()
        ..domainOf(<double>[0, 1])
        ..rangeOf(<double>[baseline, baseline - 1]);
      final context = FluentCartesianChildContext(
        xScale: xScale,
        yScalePrimary: yScale,
        containerWidth: story.width,
        containerHeight: story.height,
      );
      final layers = _delegateFor(recovered).layersFor(context);
      expect(layers, hasLength(3), reason: 'one layer per captured area path');
      for (var i = 0; i < layers.length; i++) {
        final capturedLine = _samplePath(_pathOf(lines[i].d!), 60);
        final ourLine = _samplePath(layers[i].linePath, 60);
        for (var k = 0; k < capturedLine.length; k++) {
          expectOracleOffset(
            'layer $i top edge sample $k — d3Line with curveMonotoneX, '
            'AreaChart.tsx:690-695',
            capturedLine[k],
            ourLine[k],
          );
        }
        final capturedArea = _samplePath(_pathOf(areas[i].d!), 60);
        final ourArea = _samplePath(layers[i].areaPath, 60);
        for (var k = 0; k < capturedArea.length; k++) {
          expectOracleOffset(
            'layer $i body sample $k — d3Area with the same curve instance, '
            'AreaChart.tsx:670-681',
            capturedArea[k],
            ourArea[k],
          );
        }
      }
    });
  });

  group('FluentAreaChart hover', () {
    Future<void> pump(WidgetTester tester, Widget chart) => tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        // The oracle story `charts-areachart--area-chart-basic` was captured at
        // exactly 700x260, so the chart-space geometry below is the geometry
        // that fixture records.
        home: Center(child: SizedBox(width: 700, height: 260, child: chart)),
      ),
    );

    /// Moves a fresh mouse pointer onto the middle of the plot.
    Future<TestGesture> hoverPlot(WidgetTester tester) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      final chart = tester.getRect(find.byType(FluentCartesianChart));
      // Above the legend row, inside the plot.
      await gesture.moveTo(
        Offset(chart.center.dx, chart.top + chart.height / 3),
      );
      await tester.pumpAndSettle();
      return gesture;
    }

    testWidgets('the bisector runs on series 0 only', (tester) async {
      await pump(tester, FluentAreaChart(data: _seriesZeroIsCoarserData()));
      final state = tester.state<FluentAreaChartState>(
        find.byType(FluentAreaChart),
      );
      expect(
        state.nearestXValueForInverted(1.6),
        2,
        reason:
            'AreaChart.tsx:194 bisects lineChartData[0] even for stacks; the '
            'other two series carry x = 1.5, which would win here',
      );
    });

    testWidgets('an exact midpoint resolves by absolute distance', (
      tester,
    ) async {
      await pump(tester, FluentAreaChart(data: _evenlySpacedData()));
      final state = tester.state<FluentAreaChartState>(
        find.byType(FluentAreaChart),
      );
      expect(
        state.nearestXValueForInverted(1.5),
        1,
        reason:
            'AreaChart.tsx:207-215 compares |x - d0| against |d1 - x| and '
            'keeps d0 on a tie',
      );
    });

    testWidgets('a duplicate-x dataset never opens the popover', (
      tester,
    ) async {
      await pump(tester, FluentAreaChart(data: _duplicateXData()));
      await hoverPlot(tester);
      expect(
        _renderedDelegate(tester).isPopoverOpen,
        isFalse,
        reason: 'AreaChart.tsx:1093 forces isPopoverOpen false',
      );
      expect(
        find.byType(FluentChartPopover),
        findsNothing,
        reason: 'AreaChart.tsx:1093 forces isPopoverOpen false',
      );
    });

    testWidgets('a clean dataset does open it', (tester) async {
      await pump(tester, FluentAreaChart(data: _threeSeriesData()));
      await hoverPlot(tester);
      expect(
        _renderedDelegate(tester).isPopoverOpen,
        isTrue,
        reason:
            'without this the duplicate-x assertion above would hold for a '
            'chart that never opens the popover at all',
      );
    });

    testWidgets('the pointer position is chart-local, not plot-relative', (
      tester,
    ) async {
      await pump(tester, FluentAreaChart(data: _evenlySpacedData()));
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      final chart = tester.getRect(find.byType(FluentCartesianChart));
      final state = tester.state<FluentAreaChartState>(
        find.byType(FluentAreaChart),
      );

      /// The chart-local x at which the highlighted value stops being [below].
      Future<double> flipAfter(Object below, double lo, double hi) async {
        // 24 halvings of a 700px chart resolve the boundary to well under the
        // 0.01 oracle tolerance.
        for (var i = 0; i < 24; i++) {
          final mid = (lo + hi) / 2;
          await gesture.moveTo(Offset(chart.left + mid, chart.top + 60));
          await tester.pump();
          if (state.nearestX == below) {
            lo = mid;
          } else {
            hi = mid;
          }
        }
        return (lo + hi) / 2;
      }

      // The domain is 1, 2, 3, so the two boundaries sit a quarter and three
      // quarters along the x range: solving the pair recovers the range itself.
      final quarter = await flipAfter(1, 0, 350);
      final threeQuarters = await flipAfter(2, 350, 690);
      final span = 2 * (threeQuarters - quarter);
      final rangeStart = quarter - (threeQuarters - quarter) / 2;
      final story = loadOracleStory('charts-areachart--area-chart-basic');
      final numbers = svgPathNumbers(_xDomainPath(story).d!);
      // `d3-axis` shifts the whole domain path by the crisp offset
      // (`d3-axis/src/axis.js:38`); the scale range itself is not shifted.
      final capturedRangeStart = numbers[0] - story.crispOffset;
      final capturedRangeEnd = numbers[3] - story.crispOffset;
      expectOracleNumber(
        'the x range the pointer is inverted through ends at the captured '
        'domain path — chart space, so no left margin may be subtracted '
        '(AreaChart.tsx:185-192 inverts the raw event x)',
        capturedRangeEnd,
        rangeStart + span,
      );
      // Recorded divergence: the capture starts the range at 64, this port at
      // 40, because the left margin is the width of the y tick labels and the
      // harness substitutes a placeholder font for upstream's.
      expect(
        rangeStart,
        lessThan(capturedRangeStart),
        reason:
            'the placeholder test font measures the y tick labels narrower '
            'than the captured one, so only the right edge is comparable',
      );
    });

    testWidgets(
      'leaving a shape keeps the state; leaving the chart clears it',
      (tester) async {
        await pump(tester, FluentAreaChart(data: _threeSeriesData()));
        final gesture = await hoverPlot(tester);
        final state = tester.state<FluentAreaChartState>(
          find.byType(FluentAreaChart),
        );
        expect(
          state.nearestX,
          isNotNull,
          reason: '_onRectMouseOut is a no-op at AreaChart.tsx:263-265',
        );
        await gesture.moveTo(const Offset(-50, -50));
        await tester.pumpAndSettle();
        expect(
          state.nearestX,
          isNull,
          reason: '_handleChartMouseLeave resets everything, :279-289',
        );
      },
    );

    testWidgets('the semantic title names the series count', (tester) async {
      await pump(
        tester,
        FluentAreaChart(data: _threeSeriesData(chartTitle: 'Traffic')),
      );
      expect(
        tester
            .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
            .props
            .chartTitleForSemantics,
        'Traffic. Area chart with 3 data series. ',
        reason: 'AreaChart.tsx:1012-1015',
      );
    });

    testWidgets('a legend selection reaches the delegate and the dataset', (
      tester,
    ) async {
      await pump(tester, FluentAreaChart(data: _threeSeriesData()));
      // `capitalizeLegendLabel` titles the rendered text (`utilities.ts`).
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();
      expect(
        _renderedDelegate(tester).selectedLegends,
        <String>['a'],
        reason:
            'the selection lives in this State, fed by the shell onLegendChange',
      );
    });
  });
}
