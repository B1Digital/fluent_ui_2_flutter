import 'package:fluent_2_web/fluent_2_web.dart';
// The seven shell-free chart widgets are not in `lib/fluent_2_web.dart` yet —
// that file is owned by the integration tasks — so this test deep-imports them,
// exactly as `cartesian_chart_golden_test.dart` already does for the shell.
import 'package:fluent_2_web/src/charts/annotation_only_chart.dart';
import 'package:fluent_2_web/src/charts/chart_table.dart';
import 'package:fluent_2_web/src/charts/donut_chart.dart';
import 'package:fluent_2_web/src/charts/funnel_chart.dart';
import 'package:fluent_2_web/src/charts/gauge_chart.dart';
import 'package:fluent_2_web/src/charts/horizontal_bar_chart.dart';
import 'package:fluent_2_web/src/charts/sparkline.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// One grid over the seven shell-free charts, four columns.
///
/// Row order, which is what a reviewer reads the diff against:
///
/// 1. Sparkline — plain, with a legend, below the render gate, and single
///    point. The last two cells are blank by design: below the gate the plot
///    is replaced by an empty box, and one point has no segment to stroke.
/// 2. ChartTable — two columns whose two different header background colours
///    collapse to one shared band, and the no-data state.
/// 3. HorizontalBarChart — part-to-whole, single value with the benchmark
///    triangle, and the absolute scale.
/// 4. AnnotationOnlyChart — one relative annotation with a connector, and one
///    with a title.
/// 5. DonutChart — solid, ringed with a centre value, labelled, and a
///    sub-one-percent slice.
/// 6. GaugeChart — two segments, rounded corners, a sublabel, and hidden
///    min/max.
/// 7. FunnelChart — vertical, horizontal, stacked vertical, stacked
///    horizontal.
///
/// High contrast is load-bearing here rather than decorative: every series
/// mark in this family collapses to canvas and canvasText in forced colours
/// (design spec section 5.3), so the high-contrast image is the only place a
/// mark that forgot to route through `FluentChartColors.flattenMark` shows up.
void main() {
  Widget cell(Widget child, {double width = 240, double height = 160}) =>
      SizedBox(width: width, height: height, child: child);

  // A group of fewer than four variants is padded out so that one grid row is
  // one component and the row list above stays readable as a legend.
  Widget blank() => const SizedBox(width: 240);

  const line = FluentChartData(
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'Traffic',
        // The Fluent data-viz blue, so the stroke is a fixed colour rather than
        // a palette index that could be renumbered under the grid.
        color: Color(0xFF637CEF),
        data: <FluentLineChartDataPoint>[
          FluentLineChartDataPoint(x: 0, y: 1),
          FluentLineChartDataPoint(x: 1, y: 4),
          FluentLineChartDataPoint(x: 2, y: 2),
          FluentLineChartDataPoint(x: 3, y: 8),
        ],
      ),
    ],
  );

  const donut = FluentChartData(
    chartTitle: 'Share',
    chartData: <FluentChartDataPoint>[
      FluentChartDataPoint(legend: 'A', data: 40),
      FluentChartDataPoint(legend: 'B', data: 30),
      FluentChartDataPoint(legend: 'C', data: 20),
      FluentChartDataPoint(legend: 'D', data: 10),
    ],
  );

  const gaugeSegments = <FluentGaugeChartSegment>[
    FluentGaugeChartSegment(legend: 'Low', size: 30),
    FluentGaugeChartSegment(legend: 'High', size: 70),
  ];

  const funnel = <FluentFunnelDataPoint>[
    FluentFunnelDataPoint(stage: 'Visits', value: 100),
    FluentFunnelDataPoint(stage: 'Signups', value: 60),
    FluentFunnelDataPoint(stage: 'Sales', value: 20),
  ];

  const stackedFunnel = <FluentFunnelDataPoint>[
    FluentFunnelDataPoint(
      stage: 'A',
      subValues: <FluentFunnelSubValue>[
        FluentFunnelSubValue(category: 'x', value: 60),
        FluentFunnelSubValue(category: 'y', value: 40),
      ],
    ),
    FluentFunnelDataPoint(
      stage: 'B',
      subValues: <FluentFunnelSubValue>[
        FluentFunnelSubValue(category: 'x', value: 30),
        FluentFunnelSubValue(category: 'y', value: 20),
      ],
    ),
  ];

  const bars = <FluentChartData>[
    FluentChartData(
      chartTitle: 'Storage',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'Used',
          horizontalBarChartData: FluentHorizontalDataPoint(x: 30, total: 100),
        ),
        FluentChartDataPoint(
          legend: 'Cached',
          horizontalBarChartData: FluentHorizontalDataPoint(x: 40, total: 100),
        ),
        FluentChartDataPoint(
          legend: 'Free',
          horizontalBarChartData: FluentHorizontalDataPoint(x: 30, total: 100),
        ),
      ],
    ),
  ];

  goldenGridTest(
    'charts_shell_free',
    () => goldenGrid(<Widget>[
      // 1 — Sparkline.
      cell(const FluentSparkline(data: line), height: 40),
      cell(const FluentSparkline(data: line, showLegend: true), height: 40),
      cell(const FluentSparkline(data: line, width: 40), height: 40),
      cell(
        const FluentSparkline(
          data: FluentChartData(
            lineChartData: <FluentLineChartSeries>[
              FluentLineChartSeries(
                legend: 'One',
                // The data-viz magenta, picked for the same reason as the blue
                // above: a literal cannot drift with the palette order.
                color: Color(0xFFE3008C),
                data: <FluentLineChartDataPoint>[
                  FluentLineChartDataPoint(x: 0, y: 3),
                ],
              ),
            ],
          ),
        ),
        height: 40,
      ),

      // 2 — ChartTable.
      cell(
        const FluentChartTable(
          headers: <FluentChartTableCell>[
            FluentChartTableCell(
              value: 'Region',
              textStyle: TextStyle(color: Color(0xFFFFFFFF)),
              // Two different greys, so the cell proves the header collapses to
              // one shared background rather than keeping per-cell colours.
              backgroundColor: Color(0xFF696969),
            ),
            FluentChartTableCell(
              value: 'Revenue',
              textStyle: TextStyle(color: Color(0xFFFFFFFF)),
              backgroundColor: Color(0xFF808080),
            ),
          ],
          rows: <List<FluentChartTableCell>>[
            <FluentChartTableCell>[
              FluentChartTableCell(value: 'North'),
              FluentChartTableCell(value: 1200),
            ],
            <FluentChartTableCell>[
              FluentChartTableCell(value: 'South'),
              FluentChartTableCell(value: 980),
            ],
          ],
          height: 140,
        ),
      ),
      cell(const FluentChartTable(headers: <FluentChartTableCell>[])),
      blank(),
      blank(),

      // 3 — HorizontalBarChart.
      cell(const FluentHorizontalBarChart(data: bars)),
      cell(
        const FluentHorizontalBarChart(
          data: <FluentChartData>[
            FluentChartData(
              chartTitle: 'Quota',
              chartData: <FluentChartDataPoint>[
                FluentChartDataPoint(
                  legend: 'Used',
                  data: 60,
                  horizontalBarChartData: FluentHorizontalDataPoint(
                    x: 45,
                    total: 100,
                  ),
                ),
              ],
            ),
          ],
          showTriangle: true,
        ),
      ),
      cell(
        const FluentHorizontalBarChart(
          variant: FluentHorizontalBarChartVariant.absoluteScale,
          data: <FluentChartData>[
            FluentChartData(
              chartTitle: 'Absolute',
              chartData: <FluentChartDataPoint>[
                FluentChartDataPoint(
                  legend: 'Used',
                  horizontalBarChartData: FluentHorizontalDataPoint(
                    x: 45,
                    total: 100,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      blank(),

      // 4 — AnnotationOnlyChart.
      cell(
        const FluentAnnotationOnlyChart(
          height: 160,
          annotations: <FluentChartAnnotation>[
            FluentChartAnnotation(
              text: 'Peak',
              // Mid-plot, so a shifted origin moves the label in the diff.
              coordinates: FluentRelativeCoordinate(x: 0.5, y: 0.4),
            ),
          ],
        ),
      ),
      cell(
        const FluentAnnotationOnlyChart(
          height: 160,
          chartTitle: 'Notes',
          annotations: <FluentChartAnnotation>[
            FluentChartAnnotation(
              text: 'Anchored',
              coordinates: FluentRelativeCoordinate(x: 0.3, y: 0.6),
              connector: FluentChartAnnotationConnector(),
            ),
          ],
        ),
      ),
      blank(),
      blank(),

      // 5 — DonutChart.
      cell(const FluentDonutChart(data: donut), height: 220),
      cell(
        const FluentDonutChart(
          // Wide enough to leave a visible hole inside a 240x220 cell.
          innerRadius: 40,
          data: donut,
          valueInsideDonut: '100',
        ),
        height: 220,
      ),
      cell(const FluentDonutChart(data: donut, hideLabels: false), height: 220),
      cell(
        const FluentDonutChart(
          innerRadius: 30,
          data: FluentChartData(
            chartData: <FluentChartDataPoint>[
              // 1 in 200 — under the one-percent floor upstream draws a
              // minimum slice for.
              FluentChartDataPoint(legend: 'Big', data: 199),
              FluentChartDataPoint(legend: 'Tiny', data: 1),
            ],
          ),
        ),
        height: 220,
      ),

      // 6 — GaugeChart.
      cell(
        const FluentGaugeChart(chartValue: 40, segments: gaugeSegments),
        height: 200,
      ),
      cell(
        const FluentGaugeChart(
          chartValue: 40,
          roundCorners: true,
          segments: gaugeSegments,
        ),
        height: 200,
      ),
      cell(
        const FluentGaugeChart(
          chartValue: 40,
          sublabel: 'of target',
          segments: gaugeSegments,
        ),
        height: 200,
      ),
      cell(
        const FluentGaugeChart(
          chartValue: 40,
          hideMinMax: true,
          segments: gaugeSegments,
        ),
        height: 200,
      ),

      // 7 — FunnelChart.
      cell(const FluentFunnelChart(data: funnel), height: 260),
      cell(
        const FluentFunnelChart(
          data: funnel,
          orientation: FluentFunnelOrientation.horizontal,
        ),
        height: 260,
      ),
      cell(const FluentFunnelChart(data: stackedFunnel), height: 260),
      cell(
        const FluentFunnelChart(
          data: stackedFunnel,
          orientation: FluentFunnelOrientation.horizontal,
        ),
        height: 260,
      ),
    ], columns: 4),
    // The grid is 4x240 plus three 16px gaps plus the harness's 16px margin on
    // each side = 1040 wide; the seven row heights (40, 160, 160, 160, 220,
    // 200, 260) plus six gaps plus the same margins = 1328 tall. The default
    // 1200x900 surface would overflow vertically and fail on the RenderFlex.
    surfaceSize: const Size(1060, 1360),
  );
}
