import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/area_chart.dart';
import 'package:fluent_2_web/src/charts/area_chart_style.dart';
import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2_web/src/charts/model/cartesian_series.dart';
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
}
