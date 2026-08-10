import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// The nine upstream components this plan owns, spelled exactly as plan 10
/// spells them in [OracleStory.component] and
/// [OracleManifest.storiesPerComponent], sorted.
///
/// Plan 10 writes all 90 captured stories from all 20 components into one flat
/// directory, so this list is what separates this plan's charts from the eleven
/// components belonging to plans 04, 06 and 08 — none of which
/// [buildChartForOracleStory] can build.
const List<String> shellChartComponents = <String>[
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

/// Builds the chart a captured story describes, keyed on
/// [OracleStory.component] rather than on an id prefix.
///
/// There is no decoder and there never can be: plan 10's fixtures record
/// *rendered SVG geometry* (`svgs`, `elements`, `htmlBoxes`) and carry no
/// `props` object, so a story's input data cannot be reconstructed from a
/// capture. Each arm therefore mounts a small sample dataset mirroring the
/// upstream story of that name; the fixture supplies the captured
/// [OracleStory.width] / [OracleStory.height] the chart is mounted at.
Widget buildChartForOracleStory(OracleStory story) {
  switch (story.component) {
    case 'AreaChart':
      return const FluentAreaChart(data: sampleAreaData);
    case 'GanttChart':
      return FluentGanttChart(data: sampleGanttPoints);
    case 'GroupedVerticalBarChart':
      return const FluentGroupedVerticalBarChart(data: sampleGroupedData);
    case 'HeatMapChart':
      return const FluentHeatMapChart(
        data: sampleHeatMapData,
        // Three stops over the 0..100 the sample values span: the two ends of
        // the scale plus a midpoint, which is the smallest domain that
        // exercises the interpolator's segment search.
        domainValuesForColorScale: <double>[0, 50, 100],
        rangeValuesForColorScale: <Color>[
          Color(0xFFDEECF9),
          Color(0xFF71AFE5),
          Color(0xFF004578),
        ],
      );
    case 'HorizontalBarChartWithAxis':
      return const FluentHorizontalBarChartWithAxis(data: sampleHbwaPoints);
    case 'LineChart':
      return const FluentLineChart(data: sampleLineData);
    case 'ScatterChart':
      return const FluentScatterChart(data: sampleScatterData);
    case 'VerticalBarChart':
      return const FluentVerticalBarChart(data: sampleVerticalBarPoints);
    case 'VerticalStackedBarChart':
      return const FluentVerticalStackedBarChart(data: sampleStackedGroups);
  }
  throw StateError(
    'no builder for Oracle B story ${story.id}: component '
    '${story.component} is not one of $shellChartComponents, so it belongs to '
    'plan 04, 06 or 08 and oracleStoryIds(component:) should never have '
    'yielded it here',
  );
}

/// The scatter sample: one series of four points on a numeric x, the smallest
/// dataset that gives the marker-radius scale a non-degenerate extent.
const FluentChartData sampleScatterData = FluentChartData(
  chartTitle: 'Scatter chart basic',
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

/// Four string-x bars, the band scale's smallest interesting domain.
const List<FluentVerticalBarChartDataPoint> sampleVerticalBarPoints =
    <FluentVerticalBarChartDataPoint>[
      FluentVerticalBarChartDataPoint(x: 'Jan', y: 3500),
      FluentVerticalBarChartDataPoint(x: 'Feb', y: 2500),
      FluentVerticalBarChartDataPoint(x: 'Mar', y: 1900),
      FluentVerticalBarChartDataPoint(x: 'Apr', y: 4200),
    ];

/// Two series so the area stack has something to stack.
const FluentChartData sampleAreaData = FluentChartData(
  chartTitle: 'Area chart basic',
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
const FluentChartData sampleLineData = FluentChartData(
  chartTitle: 'Line chart basic',
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

/// Three string-y bars: the horizontal chart's axes are the transpose of
/// [sampleVerticalBarPoints]'.
const List<FluentHorizontalBarChartWithAxisDataPoint> sampleHbwaPoints =
    <FluentHorizontalBarChartWithAxisDataPoint>[
      FluentHorizontalBarChartWithAxisDataPoint(x: 4000, y: 'One'),
      FluentHorizontalBarChartWithAxisDataPoint(x: 3000, y: 'Two'),
      FluentHorizontalBarChartWithAxisDataPoint(x: 2000, y: 'Three'),
    ];

/// Two overlapping spans, which is what makes the Gantt time domain wider than
/// either bar.
final List<FluentGanttChartDataPoint> sampleGanttPoints =
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

/// Two groups of two series: the smallest data that gives the inner band scale
/// more than one slot.
const List<FluentGroupedVerticalBarChartData> sampleGroupedData =
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
const List<FluentVerticalStackedBarGroup> sampleStackedGroups =
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

/// A two-by-two grid with one cell missing, which is the branch that proves the
/// heat map builds its axes from the union of the points rather than from a
/// rectangular assumption.
const List<FluentHeatMapChartData> sampleHeatMapData = <FluentHeatMapChartData>[
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

/// Mounts the nine shell-consuming charts at the sizes plan 10's Oracle B
/// harness captured from the upstream storybook (spec §4.3).
///
/// Every fixture read goes through plan 10's typed loader,
/// `test/support/oracle_fixture.dart`: ids from [oracleStoryIds], the story from
/// [loadOracleStory], coverage from [loadOracleManifest], and each number
/// through [expectOracleNumber] at [kOracleGeometryTolerance]. This file
/// decodes no JSON and invents no tolerance; a second fixture reader would drift
/// from the loader's.
///
/// Ids are enumerated, never constructed: spec §4.3 records that upstream uses
/// five story-naming conventions, so a constructed id names nothing and reads as
/// a passing test with no fixtures.
void main() {
  // Plan 10 is not a gate on Tasks 1-29. Its loader walks up from
  // Directory.current for test/fixtures/charts/oracle_b/_manifest.json and
  // throws a StateError naming the capture command when no ancestor has it.
  // Catching it HERE, around the enumeration only, degrades to one skipped test
  // instead of reddening the baseline at collection time. Nothing below catches.
  final OracleManifest manifest;
  final Map<String, List<String>> idsPerComponent;
  try {
    manifest = loadOracleManifest();
    idsPerComponent = <String, List<String>>{
      for (final component in shellChartComponents)
        component: oracleStoryIds(component: component),
    };
  } on StateError catch (error) {
    test(
      'the Oracle B corpus is absent',
      () {},
      skip:
          'plan 10 (fluent-2-charts-10-oracle-b) owns the capture harness spec '
          '§4.3 describes and its corpus is not on disk: ${error.message}',
    );
    return;
  }

  test('the Oracle B corpus covers all nine shell charts', () {
    for (final component in shellChartComponents) {
      expect(
        idsPerComponent[component],
        isNotEmpty,
        reason:
            'plan 10 captured no $component story, so this suite verifies '
            'nothing about that chart. Its skip register says what it could '
            'not capture: ${manifest.skipped}. Re-run plan 10\'s capture '
            'script rather than dropping the assertion',
      );
      // Counts, not ids: a skipped story writes no fixture, so enumeration
      // cannot see it. This is what stops "no fixture" reading as "nothing to
      // check" — OracleSkip.toString() prints the recorded reason.
      expect(
        manifest.capturedPerComponent[component],
        manifest.storiesPerComponent[component],
        reason:
            'plan 10 captured ${manifest.capturedPerComponent[component]} of '
            '${manifest.storiesPerComponent[component]} upstream $component '
            'stories; the skip register says why: ${manifest.skipped}',
      );
    }
  });

  for (final component in shellChartComponents) {
    group(component, () {
      Future<void> pump(WidgetTester tester, Widget chart, Size size) {
        // PLAN CORRECTION: the default 800x600 test surface is narrower than
        // two captures — `line-chart-annotations-example` at 960 and
        // `vertical-bar-chart-responsive` at 944 — so `Center` clamped the
        // SizedBox and the width assertion read 800. The surface is widened to
        // the capture before pumping, at the device pixel ratio plan 10
        // captured at (`OracleManifest.deviceScaleFactor`, always 1).
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.reset);
        return tester.pumpWidget(
          FluentApp(
            theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
            home: Center(
              child: SizedBox.fromSize(size: size, child: chart),
            ),
          ),
        );
      }

      for (final storyId in idsPerComponent[component]!) {
        testWidgets('$storyId mounts and paints at its captured size', (
          tester,
        ) async {
          // loadOracleStory, never a decode: an id whose fixture vanished, or
          // one in the skip register, raises plan 10's two distinct
          // StateErrors rather than silently yielding an empty story.
          final story = loadOracleStory(storyId);
          await pump(
            tester,
            buildChartForOracleStory(story),
            Size(story.width, story.height),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$storyId threw while painting at its captured size',
          );
          // At the loader's 0.01 px tolerance, not a local closeTo: a chart
          // that does not fill the captured box makes every geometry
          // comparison against that capture meaningless.
          //
          // PLAN CORRECTION: the plan's `find.byType(CustomPaint).first` picks
          // up FluentApp's own 800x600 CustomPaint, so every arm failed with
          // "expected 700, got 800". Scoped to the shell's descendants, whose
          // first CustomPaint is the plot — the shell puts the plot ahead of
          // the legend in its Column (`cartesian_chart.dart:370-383`) — and
          // painted at `size: size`, the full chart width (`:542`).
          expectOracleNumber(
            '$storyId painted width',
            story.width,
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
          );
        });
      }
    });
  }
}
