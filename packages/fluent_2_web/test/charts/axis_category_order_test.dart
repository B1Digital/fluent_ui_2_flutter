// What an ABSENT `xAxisCategoryOrder` / `yAxisCategoryOrder` means.
//
// `AxisCategoryOrder` is optional upstream (`CartesianChart.types.ts:492`,
// `:498`) and the charts do not agree on what an absent one resolves to:
//
//  * HeatMapChart (`:49-56`), HorizontalBarChartWithAxis (`:52`) and
//    ScatterChart (no default at all) leave it `undefined`, so
//    `props.…CategoryOrder !== 'default'` is TRUE and they route to
//    `sortAxisCategories(…, undefined)`, whose fall-through arm is
//    `Object.keys(categoryToValues)` — insertion order;
//  * GanttChart's destructuring default (`:45`) and the spread defaults in
//    GroupedVerticalBarChart (`:79`), VerticalStackedBarChart (`:88-89`) and
//    VerticalBarChart (`:68`) DO fire, so those really do see `'default'`.
//
// The port spells the absent prop `null` and the explicit one
// `FluentAxisCategoryOrder.defaultOrder`. Every assertion below is about the
// difference between those two, so each one fails if the prop goes back to
// being non-nullable.
import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/gantt_chart.dart';
import 'package:fluent_2_web/src/charts/gantt_chart_style.dart';
import 'package:fluent_2_web/src/charts/heat_map_chart.dart';
import 'package:fluent_2_web/src/charts/horizontal_bar_chart_with_axis.dart';
import 'package:fluent_2_web/src/charts/horizontal_bar_chart_with_axis_style.dart';
import 'package:fluent_2_web/src/charts/internal/chart_colors.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_measurer.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_styles.dart';
import 'package:fluent_2_web/src/charts/internal/chart_utils.dart';
import 'package:fluent_2_web/src/charts/model/bar_data.dart';
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:fluent_2_web/src/charts/model/heatmap_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// Three cells whose y keys arrive as p3, p2, p1 and whose x dates arrive out
/// of chronological order, so insertion order, raw-key order and formatted
/// order are three different answers.
///
/// The y formatter is the `yPointMapping` shape the captured story uses: it
/// deliberately reverses the alphabetical relation between the raw key and the
/// label, so a sort on the formatted label ('Alaska' < 'Ohio' < 'Texas') and a
/// sort on the raw key (p1 < p2 < p3, i.e. Ohio, Alaska, Texas) disagree.
final _heatMapData = <FluentHeatMapChartData>[
  FluentHeatMapChartData(
    legend: 'only',
    value: 1,
    data: <FluentHeatMapChartDataPoint>[
      FluentHeatMapChartDataPoint(
        x: DateTime.utc(2020, 3, 5),
        y: 'p3',
        value: 46,
      ),
      FluentHeatMapChartDataPoint(
        x: DateTime.utc(2020, 3, 3),
        y: 'p2',
        value: 10,
      ),
      FluentHeatMapChartDataPoint(
        x: DateTime.utc(2020, 3, 4),
        y: 'p1',
        value: 20,
      ),
    ],
  ),
];

const _yLabels = <String, String>{'p1': 'Ohio', 'p2': 'Alaska', 'p3': 'Texas'};

FluentHeatMapDataSet _heatMap({
  FluentAxisCategoryOrder? xAxisCategoryOrder,
  FluentAxisCategoryOrder? yAxisCategoryOrder,
  bool alphabeticalSort = true,
}) => buildFluentHeatMapDataSet(
  data: _heatMapData,
  xAxisCategoryOrder: xAxisCategoryOrder,
  yAxisCategoryOrder: yAxisCategoryOrder,
  alphabeticalSort: alphabeticalSort,
  yAxisStringFormatter: (point) => _yLabels[point]!,
);

void main() {
  group('sortAxisCategories', () {
    test('a null order is upstream undefined and keeps insertion order', () {
      // `categoryOrder?.match(...)` is null, so `utilities.ts:2110` returns
      // `Object.keys(categoryToValues)` unsorted. Passing
      // `FluentAxisCategoryOrder.defaultOrder` reaches the same arm — the
      // difference between the two lives in the callers, not here — so this
      // pins only that null is accepted and does not throw on the
      // `FluentAxisCategoryOrderPreset` cast.
      final values = <String, List<double>>{
        'c': <double>[3],
        'a': <double>[1],
        'b': <double>[2],
      };
      expect(sortAxisCategories(values, null), <String>['c', 'a', 'b']);
      expect(
        sortAxisCategories(values, FluentAxisCategoryOrder.categoryAscending),
        <String>['a', 'b', 'c'],
        reason: 'a named order still sorts',
      );
    });
  });

  group('HeatMapChart', () {
    test('an absent y order keeps first-appearance order', () {
      // `charts-heatmapchart--heat-map-chart-basic` is the captured proof: its
      // y ticks sit at ty 249.09 (Texas), 198.30 (Alaska), 147.50 (Ohio),
      // 96.70 (DC), 45.91 (NYC), and a band domain's first entry is its
      // bottom-most band — so upstream renders the order the keys first appear
      // in, not any sort of them.
      expect(_heatMap().yAxisPoints, <String>['Texas', 'Alaska', 'Ohio']);
    });

    test(
      'an explicit default order is the legacy sort, not the absent one',
      () {
        // `sortOrder` sorts the RAW keys (`HeatMapChart.tsx:648`, which runs
        // before `:433-445` formats them), so p1, p2, p3 comes out as Ohio,
        // Alaska, Texas — neither insertion order nor the formatted labels
        // sorted, which would be Alaska, Ohio, Texas.
        expect(
          _heatMap(
            yAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
          ).yAxisPoints,
          <String>['Ohio', 'Alaska', 'Texas'],
        );
      },
    );

    test('sortOrder: none on the legacy path keeps insertion order', () {
      expect(
        _heatMap(
          yAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
          alphabeticalSort: false,
        ).yAxisPoints,
        <String>['Texas', 'Alaska', 'Ohio'],
      );
    });

    test('a date x axis ignores the category order entirely', () {
      // `_xAxisType.current === XAxisTypes.StringAxis && …` at
      // `HeatMapChart.tsx:711-713`: BOTH halves gate the branch, so a date axis
      // never reaches `sortAxisCategories` and sorts `+a - +b` over the
      // epoch-millisecond index keys whatever the prop says. Insertion order
      // here would be Mar/05, Mar/03, Mar/04.
      const chronological = <String>['Mar/03', 'Mar/04', 'Mar/05'];
      expect(_heatMap().xAxisPoints, chronological);
      expect(
        _heatMap(
          xAxisCategoryOrder: FluentAxisCategoryOrder.categoryDescending,
        ).xAxisPoints,
        chronological,
        reason: 'even a named order cannot reorder a non-category axis',
      );
    });
  });

  group('HorizontalBarChartWithAxis', () {
    // `charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-string-axis-
    // tooltip` passes no `yAxisCategoryOrder`. Its four points are String One
    // at x 1000, String Two at 5000, String Three at 3000 and String Four at
    // 2000, and the capture's bar widths are proportional to x, so the width of
    // the bar in each band names the category upstream put there.
    const points = <FluentHorizontalBarChartWithAxisDataPoint>[
      FluentHorizontalBarChartWithAxisDataPoint(x: 1000, y: 'String One'),
      FluentHorizontalBarChartWithAxisDataPoint(x: 5000, y: 'String Two'),
      FluentHorizontalBarChartWithAxisDataPoint(x: 3000, y: 'String Three'),
      FluentHorizontalBarChartWithAxisDataPoint(x: 2000, y: 'String Four'),
    ];

    List<String>? domain(FluentAxisCategoryOrder? order) {
      final theme = FluentThemeData.light();
      return FluentHorizontalBarChartWithAxisDelegate(
        points: points,
        style: resolveFluentHorizontalBarChartWithAxisStyle(theme),
        colors: FluentChartColors.of(theme),
        measurer: FluentChartTextMeasurer(),
        textStyles: FluentChartTextStyles.of(theme),
        selectedLegends: const <String>[],
        yAxisCategoryOrder: order,
      ).stringDatasetForYAxisDomain;
    }

    test('an absent y order matches the captured band order', () {
      final story = loadOracleStory(
        'charts-horizontalbarchartwithaxis--'
        'horizontal-bar-with-axis-string-axis-tooltip',
      );
      final rects = story.byTag('rect');
      expect(rects.length, points.length);
      // Bottom band first, which is domain index 0.
      final bottomUp = <OracleElement>[...rects]
        ..sort((a, b) => b.y!.compareTo(a.y!));
      final unit =
          bottomUp.map((rect) => rect.width!).reduce(math.min) / 1000.0;
      final capturedXBottomUp = <double>[
        for (final rect in bottomUp)
          (rect.width! / unit / 1000).roundToDouble() * 1000,
      ];
      expect(capturedXBottomUp, <double>[
        1000,
        5000,
        3000,
        2000,
      ], reason: 'the capture is in the story\'s own data order');

      final xOf = <String, double>{
        for (final point in points) point.y as String: point.x,
      };
      expect(<double>[
        for (final category in domain(null)!) xOf[category]!,
      ], capturedXBottomUp);
    });

    test('an explicit default order is the legacy reversed order', () {
      // `[...points].reverse().map(p => p.y)` (`.tsx:822-827`) — the branch an
      // absent prop must NOT take.
      expect(domain(FluentAxisCategoryOrder.defaultOrder), <String>[
        'String Four',
        'String Three',
        'String Two',
        'String One',
      ]);
    });
  });

  group('GanttChart', () {
    // The one chart in the family whose upstream default really does fire:
    // `yAxisCategoryOrder = 'default'` at `GanttChart.tsx:45` is a
    // destructuring default, so null and `defaultOrder` must stay synonyms
    // here and both take the reversed order at `:156`.
    List<String> labels(FluentAxisCategoryOrder? order) {
      final theme = FluentThemeData.light();
      return FluentGanttChartDelegate(
        points: <FluentGanttChartDataPoint>[
          for (final (i, y) in <String>['a', 'b', 'c'].indexed)
            FluentGanttChartDataPoint(
              x: FluentGanttSpan(start: i * 10, end: i * 10 + 5),
              y: y,
            ),
        ],
        style: resolveFluentGanttChartStyle(theme),
        colors: FluentChartColors.of(theme),
        measurer: FluentChartTextMeasurer(),
        selectedLegends: const <String>[],
        yAxisCategoryOrder: order,
      ).orderedYAxisLabels;
    }

    test('an absent y order is the destructuring default', () {
      expect(labels(null), <String>['c', 'b', 'a']);
      expect(labels(FluentAxisCategoryOrder.defaultOrder), labels(null));
    });
  });
}
