import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import 'story_kit.dart';

/// Stories for the shared chart chrome, then the seven charts that bypass the
/// cartesian shell, then the nine that consume it.
///
/// A getter, not a function, because `all_stories.dart` spreads every sibling
/// as `...xStories`. The chart sample data below is shared with
/// `test/goldens/charts_shell_free_golden_test.dart` so a story and its golden
/// cell cannot drift apart.
List<Story> get chartsStories => [
  Story(
    name: 'Charts/FluentChartLegend',
    description:
        'The legend strip: a swatch and a title-cased label per series, with '
        'selection and hover highlighting.',
    builder: (context) => DemoColumn(
      children: [
        DemoRail(
          title: 'Selection',
          children: [
            FluentChartLegend(
              legends: const [
                FluentChartLegendItem(
                  title: 'first series',
                  color: Color(0xFF0078D4),
                ),
                FluentChartLegendItem(
                  title: 'second series',
                  color: Color(0xFF107C10),
                ),
                FluentChartLegendItem(
                  title: 'third series',
                  color: Color(0xFFD13438),
                  stripePattern: true,
                ),
              ],
              selectionMode: FluentChartLegendSelectionMode.multiple,
              onChange: (selected, current) {},
            ),
          ],
        ),
        DemoRail(
          title: 'Shapes',
          children: [
            FluentChartLegend(
              legends: [
                for (final shape in FluentChartLegendShape.values)
                  FluentChartLegendItem(
                    title: shape.name,
                    color: const Color(0xFF0078D4),
                    shape: shape,
                  ),
              ],
              enabledWrapLines: true,
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts/FluentChartPopover',
    description:
        'The hover callout a chart shows for the datum under the cursor.',
    builder: (context) => DemoColumn(
      children: const [
        DemoRail(
          title: 'Single value',
          children: [
            SizedBox(
              width: 320,
              height: 200,
              child: FluentChartPopover(
                anchor: Offset(8, 8),
                data: FluentChartPopoverData(
                  xValue: 'January',
                  legend: 'first series',
                  yValue: '42',
                  color: Color(0xFF0078D4),
                  descriptionMessage: 'Year to date',
                ),
              ),
            ),
          ],
        ),
        DemoRail(
          title: 'Stacked',
          children: [
            SizedBox(
              width: 420,
              height: 220,
              child: FluentChartPopover(
                anchor: Offset(8, 8),
                data: FluentChartPopoverData(
                  isCalloutForStack: true,
                  xValue: 'January',
                  yValues: [
                    FluentYValueHover(
                      legend: 'first series',
                      y: 12,
                      index: 0,
                      color: Color(0xFF0078D4),
                    ),
                    FluentYValueHover(
                      legend: 'second series',
                      y: 8,
                      index: 1,
                      color: Color(0xFF107C10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts/FluentChartAnnotationLayer',
    description:
        'Free-standing callout boxes placed against chart coordinates, '
        'optionally joined to their datum by a connector.',
    builder: (context) => const SizedBox(
      width: 400,
      height: 240,
      child: FluentChartAnnotationLayer(
        annotations: [
          FluentChartAnnotation(
            text: '<b>Peak</b><br />Q3 2026',
            coordinates: FluentPixelCoordinate(x: 200, y: 80),
            layout: FluentChartAnnotationLayout(offsetY: -60),
            connector: FluentChartAnnotationConnector(),
          ),
        ],
        context: FluentChartAnnotationContext(
          plotRect: Rect.fromLTWH(0, 0, 400, 240),
          chartSize: Size(400, 240),
          isRtl: false,
        ),
      ),
    ),
  ),
  Story(
    name: 'Charts/FluentSparkline',
    description: 'A tiny trend line with an optional filled area.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Standard',
          children: [
            SizedBox(
              width: 240,
              height: 40,
              child: FluentSparkline(data: _line),
            ),
            SizedBox(
              width: 240,
              height: 40,
              child: FluentSparkline(data: _line, showLegend: true),
            ),
          ],
        ),
        DemoRail(
          title: 'Below the 50x16 render gate',
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: FluentSparkline(data: _line, width: 40),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts/FluentChartTable',
    description: 'A data table with contrast-safe header colours.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Shared header background',
          children: [
            SizedBox(
              width: 320,
              height: 160,
              child: FluentChartTable(
                headers: [
                  FluentChartTableCell(
                    value: 'Region',
                    textStyle: TextStyle(color: Color(0xFFFFFFFF)),
                    // Two different greys, so the demo shows the header
                    // collapsing to one shared band rather than keeping the
                    // per-cell colours it was given.
                    backgroundColor: Color(0xFF696969),
                  ),
                  FluentChartTableCell(
                    value: 'Revenue',
                    textStyle: TextStyle(color: Color(0xFFFFFFFF)),
                    backgroundColor: Color(0xFF808080),
                  ),
                ],
                rows: [
                  [
                    FluentChartTableCell(value: 'North'),
                    FluentChartTableCell(value: 1200),
                  ],
                  [
                    FluentChartTableCell(value: 'South'),
                    FluentChartTableCell(value: 980),
                  ],
                ],
                height: 140,
              ),
            ),
          ],
        ),
        DemoRail(
          title: 'No data',
          children: [
            SizedBox(
              width: 320,
              height: 80,
              child: FluentChartTable(headers: []),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts/FluentHorizontalBarChart',
    description: 'Part-to-whole rows, with an optional benchmark triangle.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Part to whole',
          children: [
            SizedBox(
              width: 320,
              height: 160,
              child: FluentHorizontalBarChart(data: _bars),
            ),
          ],
        ),
        DemoRail(
          title: 'Benchmark',
          children: [
            SizedBox(
              width: 320,
              height: 120,
              child: FluentHorizontalBarChart(
                showTriangle: true,
                data: [
                  FluentChartData(
                    chartTitle: 'Quota',
                    chartData: [
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
              ),
            ),
          ],
        ),
        DemoRail(
          title: 'Absolute scale',
          children: [
            SizedBox(
              width: 320,
              height: 120,
              child: FluentHorizontalBarChart(
                variant: FluentHorizontalBarChartVariant.absoluteScale,
                data: [
                  FluentChartData(
                    chartTitle: 'Absolute',
                    chartData: [
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
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts/FluentAnnotationOnlyChart',
    description: 'Annotations with no plot behind them.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Relative coordinates',
          children: [
            SizedBox(
              width: 260,
              height: 160,
              child: FluentAnnotationOnlyChart(
                annotations: [
                  FluentChartAnnotation(
                    text: 'Peak',
                    coordinates: FluentRelativeCoordinate(x: 0.5, y: 0.4),
                  ),
                ],
              ),
            ),
          ],
        ),
        DemoRail(
          title: 'With a title and a connector',
          children: [
            SizedBox(
              width: 260,
              height: 160,
              child: FluentAnnotationOnlyChart(
                chartTitle: 'Notes',
                annotations: [
                  FluentChartAnnotation(
                    text: 'Anchored',
                    coordinates: FluentRelativeCoordinate(x: 0.3, y: 0.6),
                    connector: FluentChartAnnotationConnector(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts/FluentDonutChart',
    description: 'A pie or ring, optionally with a value in the hole.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Solid and ringed',
          children: [
            SizedBox(
              width: 240,
              height: 220,
              child: FluentDonutChart(data: _donut),
            ),
            SizedBox(
              width: 240,
              height: 220,
              child: FluentDonutChart(
                data: _donut,
                // Wide enough to leave a visible hole in a 240x220 cell.
                innerRadius: 40,
                valueInsideDonut: '100',
              ),
            ),
          ],
        ),
        DemoRail(
          title: 'Arc labels, and a slice under one per cent',
          children: [
            SizedBox(
              width: 240,
              height: 220,
              child: FluentDonutChart(data: _donut, hideLabels: false),
            ),
            SizedBox(
              width: 240,
              height: 220,
              child: FluentDonutChart(
                innerRadius: 30,
                data: FluentChartData(
                  chartData: [
                    // 1 in 200 — under the one-per-cent floor upstream draws a
                    // minimum slice for.
                    FluentChartDataPoint(legend: 'Big', data: 199),
                    FluentChartDataPoint(legend: 'Tiny', data: 1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts/FluentGaugeChart',
    description: 'A half-disc of segments with a needle.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Standard and rounded',
          children: [
            SizedBox(
              width: 240,
              height: 200,
              child: FluentGaugeChart(chartValue: 40, segments: _gauge),
            ),
            SizedBox(
              width: 240,
              height: 200,
              child: FluentGaugeChart(
                chartValue: 40,
                roundCorners: true,
                segments: _gauge,
              ),
            ),
          ],
        ),
        DemoRail(
          title: 'Sublabel, and hidden limits',
          children: [
            SizedBox(
              width: 240,
              height: 200,
              child: FluentGaugeChart(
                chartValue: 40,
                sublabel: 'of target',
                segments: _gauge,
              ),
            ),
            SizedBox(
              width: 240,
              height: 200,
              child: FluentGaugeChart(
                chartValue: 40,
                hideMinMax: true,
                segments: _gauge,
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts/FluentFunnelChart',
    description: 'Stacked trapezia narrowing stage by stage.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Vertical and horizontal',
          children: [
            SizedBox(
              width: 240,
              height: 260,
              child: FluentFunnelChart(data: _funnel),
            ),
            SizedBox(
              width: 240,
              height: 260,
              child: FluentFunnelChart(
                data: _funnel,
                orientation: FluentFunnelOrientation.horizontal,
              ),
            ),
          ],
        ),
        DemoRail(
          title: 'Stacked',
          children: [
            SizedBox(
              width: 240,
              height: 260,
              child: FluentFunnelChart(data: _stackedFunnel),
            ),
            SizedBox(
              width: 240,
              height: 260,
              child: FluentFunnelChart(
                data: _stackedFunnel,
                orientation: FluentFunnelOrientation.horizontal,
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  // The nine charts that consume the cartesian shell. Each mirrors the upstream
  // storybook's basic story so a reviewer can put the two side by side, at the
  // size plan 10's Oracle B capture recorded for that story (the widths and
  // heights below are those captures, not chosen numbers).
  Story(
    name: 'Charts/FluentScatterChart',
    description: 'Markers on two continuous axes, radius scaled by the plot.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Basic',
          children: [
            SizedBox(
              width: 650,
              height: 310,
              child: FluentScatterChart(
                data: FluentChartData(
                  chartTitle: 'Scatter chart basic',
                  scatterChartData: [
                    FluentScatterChartSeries(
                      legend: 'Series 1',
                      data: [
                        FluentScatterChartDataPoint(x: 20, y: 33),
                        FluentScatterChartDataPoint(x: 25, y: 42),
                        FluentScatterChartDataPoint(x: 32, y: 18),
                        FluentScatterChartDataPoint(x: 41, y: 55),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts/FluentVerticalBarChart',
    description: 'One bar per category on a band x axis.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Basic',
          children: [
            SizedBox(
              width: 650,
              height: 310,
              child: FluentVerticalBarChart(
                chartTitle: 'Vertical bar chart basic',
                data: [
                  FluentVerticalBarChartDataPoint(
                    x: 'Jan',
                    y: 3500,
                    legend: 'Q1',
                  ),
                  FluentVerticalBarChartDataPoint(
                    x: 'Feb',
                    y: 2500,
                    legend: 'Q1',
                  ),
                  FluentVerticalBarChartDataPoint(
                    x: 'Mar',
                    y: 1900,
                    legend: 'Q1',
                  ),
                  FluentVerticalBarChartDataPoint(
                    x: 'Apr',
                    y: 4200,
                    legend: 'Q2',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts/FluentAreaChart',
    description: 'Stacked bands over a time axis.',
    builder: (context) => DemoColumn(
      children: [
        DemoRail(
          title: 'Basic',
          children: [
            SizedBox(
              width: 700,
              height: 260,
              child: FluentAreaChart(
                data: FluentChartData(
                  chartTitle: 'Area chart basic',
                  lineChartData: [
                    FluentLineChartSeries(
                      legend: 'First',
                      data: [
                        FluentLineChartDataPoint(
                          x: DateTime.utc(2024, 3),
                          y: 10,
                        ),
                        FluentLineChartDataPoint(
                          x: DateTime.utc(2024, 3, 8),
                          y: 30,
                        ),
                        FluentLineChartDataPoint(
                          x: DateTime.utc(2024, 3, 15),
                          y: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts/FluentLineChart',
    description: 'One stroked path per series, with markers at each point.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Basic',
          children: [
            SizedBox(
              width: 700,
              height: 260,
              child: FluentLineChart(
                data: FluentChartData(
                  chartTitle: 'Line chart basic',
                  lineChartData: [
                    FluentLineChartSeries(
                      legend: 'Latency',
                      data: [
                        FluentLineChartDataPoint(x: 1, y: 10),
                        FluentLineChartDataPoint(x: 2, y: 30),
                        FluentLineChartDataPoint(x: 3, y: 25),
                        FluentLineChartDataPoint(x: 4, y: 40),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts/FluentHorizontalBarChartWithAxis',
    description: 'The vertical bar chart transposed: band y, continuous x.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Basic',
          children: [
            SizedBox(
              width: 650,
              height: 310,
              child: FluentHorizontalBarChartWithAxis(
                chartTitle: 'Horizontal bar chart with axis',
                data: [
                  FluentHorizontalBarChartWithAxisDataPoint(
                    x: 40,
                    y: 'alpha',
                    legend: 'A',
                  ),
                  FluentHorizontalBarChartWithAxisDataPoint(
                    x: 25,
                    y: 'beta',
                    legend: 'B',
                  ),
                  FluentHorizontalBarChartWithAxisDataPoint(
                    x: 60,
                    y: 'gamma',
                    legend: 'C',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts/FluentGanttChart',
    description: 'One span per row on a time axis.',
    builder: (context) => DemoColumn(
      children: [
        DemoRail(
          title: 'Basic',
          children: [
            SizedBox(
              width: 600,
              height: 310,
              child: FluentGanttChart(
                chartTitle: 'Gantt chart basic',
                data: [
                  FluentGanttChartDataPoint(
                    x: FluentGanttSpan(
                      start: DateTime.utc(2024, 3),
                      end: DateTime.utc(2024, 3, 15),
                    ),
                    y: 'Design',
                    legend: 'Phase 1',
                  ),
                  FluentGanttChartDataPoint(
                    x: FluentGanttSpan(
                      start: DateTime.utc(2024, 3, 10),
                      end: DateTime.utc(2024, 4, 2),
                    ),
                    y: 'Build',
                    legend: 'Phase 2',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts/FluentGroupedVerticalBarChart',
    description: 'Series side by side inside each category band.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Basic',
          children: [
            SizedBox(
              width: 650,
              height: 310,
              child: FluentGroupedVerticalBarChart(
                chartTitle: 'Grouped vertical bar chart',
                data: [
                  FluentGroupedVerticalBarChartData(
                    name: 'Jan',
                    series: [
                      FluentGroupedBarSeriesPoint(
                        key: 'a',
                        data: 30,
                        legend: 'A',
                      ),
                      FluentGroupedBarSeriesPoint(
                        key: 'b',
                        data: 44,
                        legend: 'B',
                      ),
                    ],
                  ),
                  FluentGroupedVerticalBarChartData(
                    name: 'Feb',
                    series: [
                      FluentGroupedBarSeriesPoint(
                        key: 'a',
                        data: 20,
                        legend: 'A',
                      ),
                      FluentGroupedBarSeriesPoint(
                        key: 'b',
                        data: 61,
                        legend: 'B',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts/FluentVerticalStackedBarChart',
    description: 'Series stacked within one bar per category.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Basic',
          children: [
            SizedBox(
              width: 650,
              height: 310,
              child: FluentVerticalStackedBarChart(
                chartTitle: 'Vertical stacked bar chart',
                data: [
                  FluentVerticalStackedBarGroup(
                    xAxisPoint: 'Jan',
                    chartData: [
                      FluentStackedBarDatum(data: 40, legend: 'A'),
                      FluentStackedBarDatum(data: 30, legend: 'B'),
                    ],
                  ),
                  FluentVerticalStackedBarGroup(
                    xAxisPoint: 'Feb',
                    chartData: [
                      FluentStackedBarDatum(data: 25, legend: 'A'),
                      FluentStackedBarDatum(data: 45, legend: 'B'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts/FluentHeatMapChart',
    description: 'A cell per x/y pair, coloured by an interpolated scale.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Basic',
          children: [
            SizedBox(
              width: 450,
              height: 310,
              child: FluentHeatMapChart(
                chartTitle: 'Heat map chart basic',
                domainValuesForColorScale: [0, 100],
                rangeValuesForColorScale: [
                  Color(0xFFEDF8FB),
                  Color(0xFF005A9E),
                ],
                data: [
                  FluentHeatMapChartData(
                    legend: 'Utilisation',
                    value: 60,
                    data: [
                      FluentHeatMapChartDataPoint(x: 'Mon', y: 'AM', value: 20),
                      FluentHeatMapChartDataPoint(x: 'Mon', y: 'PM', value: 80),
                      FluentHeatMapChartDataPoint(x: 'Tue', y: 'AM', value: 55),
                      FluentHeatMapChartDataPoint(x: 'Tue', y: 'PM', value: 95),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  ),
];

/// Shared with `test/goldens/charts_shell_free_golden_test.dart`, so a story
/// and its golden cell always show the same thing.
const FluentChartData _line = FluentChartData(
  lineChartData: [
    FluentLineChartSeries(
      legend: 'Traffic',
      // The Fluent data-viz blue as a literal, so the stroke cannot drift with
      // the palette order.
      color: Color(0xFF637CEF),
      data: [
        FluentLineChartDataPoint(x: 0, y: 1),
        FluentLineChartDataPoint(x: 1, y: 4),
        FluentLineChartDataPoint(x: 2, y: 2),
        FluentLineChartDataPoint(x: 3, y: 8),
      ],
    ),
  ],
);

const FluentChartData _donut = FluentChartData(
  chartTitle: 'Share',
  chartData: [
    FluentChartDataPoint(legend: 'A', data: 40),
    FluentChartDataPoint(legend: 'B', data: 30),
    FluentChartDataPoint(legend: 'C', data: 20),
    FluentChartDataPoint(legend: 'D', data: 10),
  ],
);

const List<FluentGaugeChartSegment> _gauge = [
  FluentGaugeChartSegment(legend: 'Low', size: 30),
  FluentGaugeChartSegment(legend: 'High', size: 70),
];

const List<FluentFunnelDataPoint> _funnel = [
  FluentFunnelDataPoint(stage: 'Visits', value: 100),
  FluentFunnelDataPoint(stage: 'Signups', value: 60),
  FluentFunnelDataPoint(stage: 'Sales', value: 20),
];

const List<FluentFunnelDataPoint> _stackedFunnel = [
  FluentFunnelDataPoint(
    stage: 'A',
    subValues: [
      FluentFunnelSubValue(category: 'x', value: 60),
      FluentFunnelSubValue(category: 'y', value: 40),
    ],
  ),
  FluentFunnelDataPoint(
    stage: 'B',
    subValues: [
      FluentFunnelSubValue(category: 'x', value: 30),
      FluentFunnelSubValue(category: 'y', value: 20),
    ],
  ),
];

const List<FluentChartData> _bars = [
  FluentChartData(
    chartTitle: 'Storage',
    chartData: [
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
