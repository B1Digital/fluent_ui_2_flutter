// A layout smoke sweep. NOT an Oracle B gate: it asserts no captured geometry,
// and the datasets below mirror no upstream story.
//
// This file used to be called oracle_b_shell_charts_test.dart, which was a
// claim a mutation disproved: replacing the area data with two absurd points
// AND pumping every chart at 333x222 — a size no capture records — left all 58
// tests green. Nothing here ever depended on a capture. It was renamed rather
// than deleted because the mounting itself is worth keeping, and renamed rather
// than fixed because the real gate already exists.
//
// THE REAL ORACLE B GATE IS PER CHART, in each chart's own test file — 45 test
// blocks across the nine that call an expectOracle* helper, each comparing the
// port's output to a number read out of a fixture:
//
//   AreaChart                   area_chart_test.dart                       6
//   GanttChart                  gantt_chart_test.dart                    1+1
//   GroupedVerticalBarChart     grouped_vertical_bar_chart_test.dart       5
//                               grouped_vertical_bar_chart_style_test      2
//   HeatMapChart                heat_map_chart_test.dart                   2
//   HorizontalBarChartWithAxis  horizontal_bar_chart_with_axis_test.dart   6
//   LineChart                   line_chart_test.dart                       7
//   ScatterChart                scatter_chart_test.dart                    3
//   VerticalBarChart            vertical_bar_chart_test.dart               8
//   VerticalStackedBarChart     vertical_stacked_bar_chart_test.dart       5
//
// Counted as blocks holding a direct expectOracle* call, so re-derivable with
// `grep -rlc expectOracle` over test/charts and counting enclosing test blocks — a bare
// `grep -c expectOracle` counts call lines (104), not blocks; GanttChart's second block asserts through the shared
// `expectBarsMatch`, hence 1+1. It is a floor, not a total. Fifteen further
// blocks load a story to drive the port — grouped_vertical_bar_chart_test.dart
// feeds it through `contextOf(story)` — while taking their expected value from
// upstream source instead of the capture, and several of the 45 are
// parameterised over every captured story of their component, so they run more
// than once.
//
// Those files can assert capture geometry because they solve the problem this
// one could not: a fixture records RENDERED SVG (`svgs`, `elements`,
// `htmlBoxes`) and carries no `props`, so a story's input data is not in the
// capture. Each of them recovers the input from the capture instead —
// gantt_chart_test.dart:847 inverts the captured bar x and width back through
// the time scale onto midnight UTC — and then asserts the round trip. That
// recovery is per chart and per story; there is no generic version of it, which
// is why one nine-chart file cannot be the gate.
//
// What is left, and what this file now does: mount each of the nine
// shell-consuming charts at each distinct size upstream renders it at, and
// check it paints without throwing and fills the width it is given. The corpus
// supplies only those sizes.
//
// One arm per DISTINCT (component, size) pair, not one per story. The nine
// components hold 57 captured stories between them but only 22 distinct sizes,
// so a per-story sweep ran 35 arms byte-identical to another arm in the same
// file — same widget, same data, same size, different name. That is the same
// "reads as coverage" failure in miniature.
import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// The nine charts built on [FluentCartesianChart], spelled as
/// [OracleStory.component] spells them, sorted.
///
/// The corpus holds 20 components; the other eleven belong to plans 04, 06 and
/// 08 and do not use the cartesian shell, so [_buildChart] cannot build them
/// and the width invariant below would not apply.
const List<String> _shellChartComponents = <String>[
  'AreaChart',
  'GanttChart',
  'GroupedVerticalBarChart',
  'HeatMapChart',
  'HorizontalBarChartWithAxis',
  'LineChart',
  'ScatterChart',
  'VerticalBarChart',
  'VerticalStackedBarChart',
];

/// Builds the shell chart named by [OracleStory.component].
///
/// Keyed on the component, never on the story: every story of a component gets
/// the same dataset, because the dataset is arbitrary. Nothing below is
/// asserted about — the datasets exist only to give each chart enough points
/// that its scales, band maths and label solver actually run.
Widget _buildChart(String component) {
  switch (component) {
    case 'AreaChart':
      return const FluentAreaChart(data: _areaData);
    case 'GanttChart':
      return FluentGanttChart(data: _ganttPoints);
    case 'GroupedVerticalBarChart':
      return const FluentGroupedVerticalBarChart(data: _groupedData);
    case 'HeatMapChart':
      return const FluentHeatMapChart(
        data: _heatMapData,
        // Three stops spanning the values in _heatMapData, which is the
        // smallest domain that makes the interpolator search a segment rather
        // than return an endpoint.
        domainValuesForColorScale: <double>[0, 50, 100],
        rangeValuesForColorScale: <Color>[
          Color(0xFFDEECF9),
          Color(0xFF71AFE5),
          Color(0xFF004578),
        ],
      );
    case 'HorizontalBarChartWithAxis':
      return const FluentHorizontalBarChartWithAxis(data: _hbwaPoints);
    case 'LineChart':
      return const FluentLineChart(data: _lineData);
    case 'ScatterChart':
      return const FluentScatterChart(data: _scatterData);
    case 'VerticalBarChart':
      return const FluentVerticalBarChart(data: _verticalBarPoints);
    case 'VerticalStackedBarChart':
      return const FluentVerticalStackedBarChart(data: _stackedGroups);
  }
  throw StateError(
    'no builder for component $component, which is not one of '
    '$_shellChartComponents, so oracleStoryIds(component:) should never have '
    'yielded it here',
  );
}

/// One series of four points on a numeric x, enough for a non-degenerate
/// marker-radius extent.
const FluentChartData _scatterData = FluentChartData(
  chartTitle: 'Scatter smoke',
  scatterChartData: <FluentScatterChartSeries>[
    FluentScatterChartSeries(
      legend: 'Series 1',
      data: <FluentScatterChartDataPoint>[
        FluentScatterChartDataPoint(x: 20, y: 33),
        FluentScatterChartDataPoint(x: 25, y: 42),
        FluentScatterChartDataPoint(x: 32, y: 18),
        FluentScatterChartDataPoint(x: 41, y: 55),
      ],
    ),
  ],
);

/// Four string-x bars: the band scale's smallest interesting domain.
const List<FluentVerticalBarChartDataPoint> _verticalBarPoints =
    <FluentVerticalBarChartDataPoint>[
      FluentVerticalBarChartDataPoint(x: 'Jan', y: 3500),
      FluentVerticalBarChartDataPoint(x: 'Feb', y: 2500),
      FluentVerticalBarChartDataPoint(x: 'Mar', y: 1900),
      FluentVerticalBarChartDataPoint(x: 'Apr', y: 4200),
    ];

/// Two series, so the area stack has something to stack.
const FluentChartData _areaData = FluentChartData(
  chartTitle: 'Area smoke',
  lineChartData: <FluentLineChartSeries>[
    FluentLineChartSeries(
      legend: 'Series 1',
      data: <Object>[
        FluentLineChartDataPoint(x: 0, y: 10),
        FluentLineChartDataPoint(x: 1, y: 30),
        FluentLineChartDataPoint(x: 2, y: 20),
      ],
    ),
    FluentLineChartSeries(
      legend: 'Series 2',
      data: <Object>[
        FluentLineChartDataPoint(x: 0, y: 5),
        FluentLineChartDataPoint(x: 1, y: 15),
        FluentLineChartDataPoint(x: 2, y: 25),
      ],
    ),
  ],
);

/// One line series on a numeric x.
const FluentChartData _lineData = FluentChartData(
  chartTitle: 'Line smoke',
  lineChartData: <FluentLineChartSeries>[
    FluentLineChartSeries(
      legend: 'Series 1',
      data: <Object>[
        FluentLineChartDataPoint(x: 0, y: 10),
        FluentLineChartDataPoint(x: 10, y: 45),
        FluentLineChartDataPoint(x: 20, y: 30),
        FluentLineChartDataPoint(x: 30, y: 60),
      ],
    ),
  ],
);

/// Three string-y bars: the transpose of [_verticalBarPoints]' axes.
const List<FluentHorizontalBarChartWithAxisDataPoint> _hbwaPoints =
    <FluentHorizontalBarChartWithAxisDataPoint>[
      FluentHorizontalBarChartWithAxisDataPoint(x: 4000, y: 'One'),
      FluentHorizontalBarChartWithAxisDataPoint(x: 3000, y: 'Two'),
      FluentHorizontalBarChartWithAxisDataPoint(x: 2000, y: 'Three'),
    ];

/// Two overlapping spans, which is what makes the time domain wider than
/// either bar.
final List<FluentGanttChartDataPoint> _ganttPoints =
    <FluentGanttChartDataPoint>[
      FluentGanttChartDataPoint(
        x: FluentGanttSpan(
          start: DateTime.utc(2024, 1),
          end: DateTime.utc(2024, 1, 10),
        ),
        y: 'Task A',
      ),
      FluentGanttChartDataPoint(
        x: FluentGanttSpan(
          start: DateTime.utc(2024, 1, 6),
          end: DateTime.utc(2024, 1, 20),
        ),
        y: 'Task B',
      ),
    ];

/// Two groups of two series: the smallest data giving the inner band scale
/// more than one slot.
const List<FluentGroupedVerticalBarChartData> _groupedData =
    <FluentGroupedVerticalBarChartData>[
      FluentGroupedVerticalBarChartData(
        name: 'Jan',
        series: <FluentGroupedBarSeriesPoint>[
          FluentGroupedBarSeriesPoint(key: 'a', data: 33, legend: 'Series 1'),
          FluentGroupedBarSeriesPoint(key: 'b', data: 44, legend: 'Series 2'),
        ],
      ),
      FluentGroupedVerticalBarChartData(
        name: 'Feb',
        series: <FluentGroupedBarSeriesPoint>[
          FluentGroupedBarSeriesPoint(key: 'a', data: 22, legend: 'Series 1'),
          FluentGroupedBarSeriesPoint(key: 'b', data: 55, legend: 'Series 2'),
        ],
      ),
    ];

/// Two stacks of two segments.
const List<FluentVerticalStackedBarGroup> _stackedGroups =
    <FluentVerticalStackedBarGroup>[
      FluentVerticalStackedBarGroup(
        xAxisPoint: 'Jan',
        chartData: <FluentStackedBarDatum>[
          FluentStackedBarDatum(data: 30, legend: 'Series 1'),
          FluentStackedBarDatum(data: 20, legend: 'Series 2'),
        ],
      ),
      FluentVerticalStackedBarGroup(
        xAxisPoint: 'Feb',
        chartData: <FluentStackedBarDatum>[
          FluentStackedBarDatum(data: 40, legend: 'Series 1'),
          FluentStackedBarDatum(data: 10, legend: 'Series 2'),
        ],
      ),
    ];

/// A two-by-two grid with one cell missing, so the heat map has to build its
/// axes from the union of the points rather than from a rectangular assumption.
const List<FluentHeatMapChartData> _heatMapData = <FluentHeatMapChartData>[
  FluentHeatMapChartData(
    legend: 'Series 1',
    value: 60,
    data: <FluentHeatMapChartDataPoint>[
      FluentHeatMapChartDataPoint(x: 'A', y: 'One', value: 10),
      FluentHeatMapChartDataPoint(x: 'B', y: 'One', value: 60),
      FluentHeatMapChartDataPoint(x: 'A', y: 'Two', value: 95),
    ],
  ),
];

/// The distinct sizes the stories named by [ids] were captured at, ordered by
/// width then height so the sweep's arm names are stable across runs.
List<Size> _distinctSizes(Iterable<String> ids) {
  final sizes = <Size>{};
  for (final id in ids) {
    // loadOracleStory, never a decode: an id whose fixture vanished, or one in
    // the skip register, raises the loader's two distinct StateErrors rather
    // than silently yielding an empty story.
    final story = loadOracleStory(id);
    sizes.add(Size(story.width, story.height));
  }
  return sizes.toList(growable: false)..sort(
    (a, b) => a.width == b.width
        ? a.height.compareTo(b.height)
        : a.width.compareTo(b.width),
  );
}

void main() {
  // The corpus is not a prerequisite of this package's tests. Its loader walks
  // up from Directory.current for test/fixtures/charts/oracle_b/_manifest.json
  // and throws a StateError naming the capture command when no ancestor has it.
  // Catching it HERE, around the enumeration only, degrades to one skipped test
  // instead of reddening the baseline at collection time. Nothing below catches.
  final OracleManifest manifest;
  final Map<String, List<String>> idsPerComponent;
  final Map<String, List<Size>> sizesPerComponent;
  try {
    manifest = loadOracleManifest();
    idsPerComponent = <String, List<String>>{
      for (final component in _shellChartComponents)
        component: oracleStoryIds(component: component),
    };
    sizesPerComponent = <String, List<Size>>{
      for (final entry in idsPerComponent.entries)
        entry.key: _distinctSizes(entry.value),
    };
  } on StateError catch (error) {
    test(
      'the Oracle B corpus is absent',
      () {},
      skip:
          'this sweep takes its sizes from the Oracle B corpus (spec §4.3) and '
          'the corpus is not on disk: ${error.message}',
    );
    return;
  }

  test('every shell chart still contributes a size to the sweep', () {
    for (final component in _shellChartComponents) {
      // Without this the sweep is silently vacuous: a component whose stories
      // all vanished contributes zero arms and zero failures.
      expect(
        sizesPerComponent[component],
        isNotEmpty,
        reason:
            'no $component story is in the corpus, so this sweep never mounts '
            'that chart at all. The skip register says what could not be '
            'captured: ${manifest.skipped}',
      );
      // Counts, not ids: a skipped story writes no fixture, so enumeration
      // cannot see it, and a component that lost a story with an unusual size
      // loses that arm without changing any assertion here.
      expect(
        manifest.capturedPerComponent[component],
        manifest.storiesPerComponent[component],
        reason:
            'the corpus holds ${manifest.capturedPerComponent[component]} of '
            '${manifest.storiesPerComponent[component]} upstream $component '
            'stories; the skip register says why: ${manifest.skipped}',
      );
    }
  });

  for (final component in _shellChartComponents) {
    group(component, () {
      for (final size in sizesPerComponent[component]!) {
        testWidgets('fills a ${size.width}x${size.height} box', (tester) async {
          // The surface is widened to the size under test before pumping:
          // the default 800x600 is narrower than two captured sizes (960 and
          // 944 wide), and Center would otherwise clamp the SizedBox so the
          // width assertion below read 800 and passed for the wrong reason.
          tester.view.devicePixelRatio = manifest.deviceScaleFactor.toDouble();
          tester.view.physicalSize = size;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            FluentApp(
              theme: FluentThemeData.light(
                fontPlatform: FluentFontPlatform.web,
              ),
              home: Center(
                child: SizedBox.fromSize(
                  size: size,
                  child: _buildChart(component),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$component threw while painting at $size',
          );
          // The one real invariant here: the shell hands its full incoming
          // width down to the plot painter. `_buildPlot` sizes the painter
          // from the layout constraints
          // (`cartesian_chart.dart:417`, painted at `:542-543`), and the plot
          // is the first CustomPaint under the shell because the Column puts
          // it ahead of the legend (`:370-382`). A shell that shrink-wrapped,
          // or one whose plot stopped tracking its constraints, fails here.
          //
          // Scoped to the shell's descendants: an unscoped
          // `find.byType(CustomPaint).first` picks up FluentApp's own
          // full-surface CustomPaint instead.
          expect(
            tester
                .getSize(
                  find
                      .descendant(
                        of: find.byType(FluentCartesianChart),
                        matching: find.byType(CustomPaint),
                      )
                      .first,
                )
                .width,
            size.width,
            reason:
                '$component did not paint its plot at the full width it was '
                'given',
          );
        });
      }
    });
  }
}
