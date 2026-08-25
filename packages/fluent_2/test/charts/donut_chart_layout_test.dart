import 'dart:math' as math;

import 'package:fluent_2/src/charts/donut_chart.dart';
import 'package:fluent_2/src/charts/internal/d3/shape_arc.dart' as d3;
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/bar_data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';
import 'd3/golden_support.dart';

/// The order of operations decides every angle, and the recon brief got one
/// step of it wrong.
///
/// `DonutChart.tsx:331` calls `_createLegends(points.filter(d => d.data >= 0))`
/// — `filter` returns a NEW list. The in-place `chartData.sort()` at
/// `DonutChart.tsx:108` therefore sorts that copy and nothing else. `points`
/// itself, built at `:327` and handed to `_elevateToMinimums` at `:336` and
/// then to `Pie`, is never reordered. So `order: 'sorted'` reorders the
/// **legend** and leaves the arcs in input order.
void main() {
  FluentChartDataPoint slice(String legend, double value) =>
      FluentChartDataPoint(legend: legend, data: value);

  FluentDonutLayout layoutOf(
    List<FluentChartDataPoint> points, {
    FluentDonutOrder order = FluentDonutOrder.byDefault,
  }) => FluentDonutLayout.compute(
    points: points,
    order: order,
    size: const Size(200, 200),
    innerRadius: 0,
    hideLabels: true,
    titleHeight: 0,
    labelMarginHorizontal: 0,
    labelMarginVertical: 0,
    padAngle: 0.02,
    isDark: false,
  );

  /// The `d` string `Arc` would serialise for [entry], which is what the Oracle
  /// B capture holds. `Pie` never sets `roundCorners`, so the corner radius is
  /// 0 (`Arc.tsx:114`, asserted in `donut_chart_style_test.dart`).
  String arcPathOf(FluentDonutSlice entry, FluentDonutLayout layout) {
    final sink = SvgPathSink();
    d3.Arc()(
      d3.ArcDatum(
        startAngle: entry.startAngle,
        endAngle: entry.endAngle,
        padAngle: entry.padAngle,
        innerRadius: layout.innerRadius,
        outerRadius: layout.outerRadius,
      ),
      sink,
    );
    return sink.d;
  }

  test('three positive slices reproduce d3.pie exactly', () {
    final layout = layoutOf(<FluentChartDataPoint>[
      slice('A', 3),
      slice('B', 1),
      slice('C', 1),
    ]);
    const expected = <(double, double)>[
      (0.0, 3.7539111843077517),
      (3.7539111843077517, 5.018548245743668),
      (5.018548245743668, 6.2831853071795845),
    ];
    for (var i = 0; i < 3; i++) {
      expect(
        layout.slices[i].startAngle,
        closeTo(expected[i].$1, 1e-12),
        reason:
            'Pie.tsx:94-98 runs sort(null).value(d => d.data)'
            '.padAngle(0.02) with the d3 defaults startAngle 0 and endAngle '
            '2*PI; k is (2*PI - 3*0.02) / 5.',
      );
      expect(
        layout.slices[i].endAngle,
        closeTo(expected[i].$2, 1e-12),
        reason: 'Every arc consumes one pad angle regardless of its value.',
      );
    }
  });

  test('sort(null) preserves input order rather than sorting by value', () {
    final layout = layoutOf(<FluentChartDataPoint>[
      slice('small', 1),
      slice('large', 9),
    ]);
    expect(
      layout.slices.map((s) => s.point.legend).toList(),
      <String>['small', 'large'],
      reason:
          'Pie.tsx:95 calls .sort(null), which nulls BOTH sort and '
          'sortValues, so the layout keeps the data order.',
    );
  });

  test('a zero value is excluded from the arcs but kept in the legend', () {
    final layout = layoutOf(<FluentChartDataPoint>[
      slice('A', 5),
      slice('Zero', 0),
      slice('B', 5),
    ]);
    expect(
      layout.slices.length,
      2,
      reason: 'Pie.tsx:90 filters d.data !== 0 before the layout runs.',
    );
    expect(
      layout.legendPoints.map((p) => p.legend).toList(),
      <String>['A', 'Zero', 'B'],
      reason:
          'DonutChart.tsx:331 filters d.data >= 0 for the legend, which '
          'keeps zero. The legend and the arcs deliberately disagree.',
    );
  });

  test('a negative value is excluded from both, but still pads the pie', () {
    final layout = layoutOf(<FluentChartDataPoint>[
      slice('A', 5),
      slice('Neg', -3),
      slice('B', 5),
    ]);
    expect(
      layout.legendPoints.map((p) => p.legend).toList(),
      <String>['A', 'B'],
      reason: 'DonutChart.tsx:331 — d.data >= 0 drops a negative.',
    );
    expect(
      layout.slices.length,
      3,
      reason:
          'Pie.tsx:90 only removes exact zeroes, so the negative survives '
          'into d3.pie, contributes nothing to the sum, and still consumes one '
          'pad angle.',
    );
    expect(
      layout.slices[1].endAngle - layout.slices[1].startAngle,
      closeTo(0.02, 1e-12),
      reason:
          'shape_pie.dart adds the pad angle unconditionally and the '
          'value term only when the value is positive.',
    );
  });

  test('a sub-one-percent slice is elevated to one percent of the sum', () {
    final layout = layoutOf(<FluentChartDataPoint>[
      slice('big', 100),
      slice('tiny', 0.5),
      slice('mid', 99.5),
    ]);
    expect(
      layout.slices[1].value,
      closeTo(2.0, 1e-12),
      reason:
          'DonutChart.tsx:85-105 — minPercent is 0.01 and the sum is 200, '
          'so 0.5 is raised to 2.0.',
    );
  });

  test('elevation records the original value as the callout text', () {
    final layout = layoutOf(<FluentChartDataPoint>[
      slice('big', 100),
      slice('tiny', 0.5),
      slice('mid', 99.5),
    ]);
    expect(
      layout.slices[1].point.yAxisCalloutData,
      '0.5',
      reason:
          'DonutChart.tsx:97-98 stores the pre-elevation value in '
          'yAxisCalloutData when the caller supplied none, so the popover '
          'still shows the truth.',
    );
  });

  test('the elevation callout text is grouped the way toLocaleString is', () {
    final layout = layoutOf(<FluentChartDataPoint>[
      slice('tiny', 12345),
      slice('huge', 9987655),
    ]);
    expect(
      layout.slices[0].point.yAxisCalloutData,
      '12,345',
      reason:
          'DonutChart.tsx:98 is item.data!.toLocaleString(), so the recorded '
          'value is grouped. String interpolation would write "12345.0".',
    );
  });

  test('elevation leaves a value at exactly one percent alone', () {
    final layout = layoutOf(<FluentChartDataPoint>[
      slice('a', 1),
      slice('b', 99),
    ]);
    expect(
      layout.slices[0].value,
      closeTo(1.0, 1e-12),
      reason:
          'DonutChart.tsx:93 is `minPercent * sum > item.data`, a strict '
          'comparison, so a value exactly at the threshold is untouched.',
    );
  });

  test('sorted order reorders the legend and NOT the arcs', () {
    final layout = layoutOf(<FluentChartDataPoint>[
      slice('small', 1),
      slice('large', 9),
      slice('mid', 5),
    ], order: FluentDonutOrder.sorted);
    expect(
      layout.legendPoints.map((p) => p.legend).toList(),
      <String>['large', 'mid', 'small'],
      reason: 'DonutChart.tsx:107-111 sorts descending by data.',
    );
    expect(
      layout.slices.map((s) => s.point.legend).toList(),
      <String>['small', 'large', 'mid'],
      reason:
          'DonutChart.tsx:331 passes points.filter(...), a NEW list, so '
          'the in-place sort at :108 never reaches the list the pie reads at '
          ':336. The recon brief claimed it did.',
    );
  });

  test('an uncoloured slice takes the next qualitative colour by index', () {
    final layout = layoutOf(<FluentChartDataPoint>[
      slice('A', 1),
      slice('B', 1),
    ]);
    expect(
      layout.slices[1].colour.toARGB32(),
      FluentDataVizPalette.next(1).toARGB32(),
      reason:
          'DonutChart.tsx:257-269 assigns getNextColor(index, 0) by '
          'position in the ORIGINAL list. Upstream then writes the result to a '
          '`defaultColor` field that Arc never reads (Pie.tsx:61 reads '
          '`d.data.color`), so an uncoloured slice renders black; that is a '
          'defect that removes all colour, so the port assigns the palette '
          'colour to the slice it computed it for.',
    );
  });

  test('the outer radius halves the smaller free dimension', () {
    final layout = FluentDonutLayout.compute(
      points: <FluentChartDataPoint>[slice('A', 1)],
      order: FluentDonutOrder.byDefault,
      size: const Size(300, 200),
      innerRadius: 0,
      hideLabels: false,
      titleHeight: 36,
      labelMarginHorizontal: 80,
      labelMarginVertical: 40,
      padAngle: 0.02,
      isDark: false,
    );
    expect(
      layout.outerRadius,
      closeTo(62, 1e-12),
      reason:
          'DonutChart.tsx:335 is '
          'min(width - 80, height - 40 - titleHeight) / 2, and '
          'min(220, 124) / 2 is 62.',
    );
  });

  test('the label radius is measured from the larger of the two radii', () {
    final layout = FluentDonutLayout.compute(
      points: <FluentChartDataPoint>[slice('A', 1)],
      order: FluentDonutOrder.byDefault,
      size: const Size(200, 200),
      innerRadius: 150,
      hideLabels: false,
      titleHeight: 0,
      labelMarginHorizontal: 80,
      labelMarginVertical: 40,
      padAngle: 0.02,
      isDark: false,
    );
    expect(
      layout.labelRadius(2),
      closeTo(152, 1e-12),
      reason:
          'Arc.tsx:79 is max(innerRadius, outerRadius) + 2, so an inner '
          'radius larger than the outer one wins.',
    );
  });

  test('a full circle of one slice still leaves one pad angle', () {
    final layout = layoutOf(<FluentChartDataPoint>[slice('only', 7)]);
    expect(
      layout.slices.single.endAngle - layout.slices.single.startAngle,
      closeTo(2 * math.pi, 1e-12),
      reason:
          'shape_pie.dart computes k as (da - n * pa) / sum with n = 1, so '
          'the single arc gets (2*PI - 0.02) of value plus 0.02 of pad — the '
          'full turn.',
    );
  });

  // Oracle B. Both donut stories below were captured from the live component,
  // so they pin the whole chain at once: the radius formula, the centre, the
  // palette assignment, the pie angles and — through `shape_arc` — the
  // padAngle branch with d3's default padRadius of sqrt(r0^2 + r1^2), which no
  // production caller had exercised before this chart.
  group('Oracle B', () {
    test('charts-donutchart--donut-chart-basic reproduces both arcs', () {
      final story = loadOracleStory('charts-donutchart--donut-chart-basic');
      final paths = story.byTag('path');
      expect(
        paths.length,
        2,
        reason:
            'The story has two slices; a different count means the fixture '
            'changed and the values reconstructed below no longer apply.',
      );

      // `_height` is not the svg height: DonutChart.tsx:358 renders the svg
      // `titleHeight / 2` taller, so 238 captured is 220 laid out. The title
      // is present, so _getTitleHeight (:274-283) is max(13 + 20, 36) = 36.
      // 20000 and 35000 are recovered from the capture: 92*sin and -92*cos of
      // the first arc's end angle are exactly (69.901, 59.815).
      final layout = FluentDonutLayout.compute(
        points: <FluentChartDataPoint>[
          slice('first', 20000),
          slice('second', 35000),
        ],
        order: FluentDonutOrder.byDefault,
        size: const Size(944, 220),
        innerRadius: 55,
        hideLabels: true,
        titleHeight: 36,
        labelMarginHorizontal: 80,
        labelMarginVertical: 40,
        padAngle: 0.02,
        isDark: false,
      );

      expectOracleNumber(
        'donut outer radius (DonutChart.tsx:335, min(944, 220 - 36) / 2)',
        92,
        layout.outerRadius,
      );
      expectOracleOffset(
        'donut centre (Pie.tsx:99, translate(width / 2, height / 2))',
        const Offset(472, 110),
        layout.centre,
      );
      for (var i = 0; i < paths.length; i++) {
        expectOracleSvgPath(
          'donut arc $i',
          paths[i].d!,
          arcPathOf(layout.slices[i], layout),
        );
        expectOracleColour(
          'donut arc $i fill',
          paths[i].fill,
          layout.slices[i].colour,
        );
      }
    });

    test('charts-donutchart--donut-chart-dynamic reproduces four arcs', () {
      final story = loadOracleStory('charts-donutchart--donut-chart-dynamic');
      final paths = story.byTag('path');
      final labels = story.byTag('text');
      expect(
        paths.length,
        4,
        reason: 'The dynamic story has four slices, one path each.',
      );
      expect(
        labels.length,
        5,
        reason:
            'Four arc labels (hideLabels is false here) plus the chart title '
            'at the svg root.',
      );

      // 40/20/30/10 are the arc labels the capture holds, and hideLabels is
      // false, so the margins at DonutChart.tsx:332-333 are 80 and 40:
      // min(944 - 80, 248 - 40 - 36) / 2 is 86, the captured outer radius.
      final layout = FluentDonutLayout.compute(
        points: <FluentChartDataPoint>[
          slice('first', 40),
          slice('second', 20),
          slice('third', 30),
          slice('fourth', 10),
        ],
        order: FluentDonutOrder.byDefault,
        size: const Size(944, 248),
        innerRadius: 35,
        hideLabels: false,
        titleHeight: 36,
        labelMarginHorizontal: 80,
        labelMarginVertical: 40,
        padAngle: 0.02,
        isDark: false,
      );

      expectOracleNumber(
        'dynamic donut outer radius (DonutChart.tsx:335, min(864, 172) / 2)',
        86,
        layout.outerRadius,
      );
      expectOracleOffset(
        'dynamic donut centre (Pie.tsx:99, translate(944 / 2, 248 / 2))',
        const Offset(472, 124),
        layout.centre,
      );
      for (var i = 0; i < paths.length; i++) {
        expectOracleSvgPath(
          'dynamic donut arc $i',
          paths[i].d!,
          arcPathOf(layout.slices[i], layout),
        );
        expectOracleColour(
          'dynamic donut arc $i fill',
          paths[i].fill,
          layout.slices[i].colour,
        );
      }

      // Arc.tsx:83-85 places each label on the circle of radius
      // max(inner, outer) + 2, so every captured label sits exactly
      // labelRadius(2) from the centre.
      final arcLabels = labels
          .where((element) => element.parent >= 0 && element.x != null)
          .toList();
      expect(
        arcLabels.length,
        4,
        reason:
            'One label per slice. A smaller count would leave the loop below '
            'asserting nothing.',
      );
      for (final label in arcLabels) {
        expectOracleNumber(
          'label radius of "${label.text}" (Arc.tsx:79, max(35, 86) + 2 = 88)',
          layout.labelRadius(2),
          math.sqrt(label.x! * label.x! + label.y! * label.y!),
        );
      }
    });
  });
}
