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
  Story(
    name: 'Charts/FluentPolarChart',
    description:
        'Plots r against theta on a radial grid, with a circular or polygonal '
        'shape and either rotation direction.',
    builder: (context) {
      return const DemoColumn(
        children: [
          // charts-polarchart--polar-chart-basic: two areapolar series over six
          // subjects, 600x350, polygonal grid, clockwise
          // (PolarChartDefault.stories.tsx).
          DemoRail(
            title: 'PolarChartBasic',
            children: [
              FluentPolarChart(
                data: _polarSubjectScores,
                width: 600,
                height: 350,
                shape: FluentPolarShape.polygon,
                direction: FluentPolarDirection.clockwise,
              ),
            ],
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Charts/FluentSankeyChart',
    description:
        'Flow diagram of nodes and weighted streams, with hover selection and '
        'min-width reflow.',
    builder: (context) {
      return DemoColumn(
        children: [
          // charts-sankeychart--sankey-chart-basic: 820x412 with min-width
          // reflow (SankeyChartBasic.stories.tsx).
          DemoRail(
            title: 'SankeyChartBasic',
            children: [
              SizedBox(
                width: 820,
                height: 412,
                child: FluentSankeyChart(
                  data: _sankeyBasic,
                  chartTitle: 'Sankey Chart',
                  reflowMode: FluentSankeyReflowMode.minWidth,
                ),
              ),
            ],
          ),
          // charts-sankeychart--sankey-chart-inbox: 820x400 and the only story
          // that overrides the semantic templates
          // (SankeyChartInbox.stories.tsx `strings` and `accessibility`).
          DemoRail(
            title: 'SankeyChartInbox',
            children: [
              SizedBox(
                width: 820,
                height: 400,
                child: FluentSankeyChart(
                  data: _sankeyInbox,
                  chartTitle: 'Sankey Chart',
                  linkFromLabel: 'from category {0}',
                  emptySemanticLabel: 'Graph has no data to display',
                  nodeSemanticLabel: 'Category {0} with email count {1}',
                  linkSemanticLabel: '{2} items moved from category {0} to {1}',
                ),
              ),
            ],
          ),
          // charts-sankeychart--sankey-chart-rebalance: the simple dataset only.
          // 10000 against 1 is what drives the one-percent normalisation
          // (SankeyChart.tsx:695); upstream's 43-node complex dataset behind the
          // Switch adds no behaviour and is not ported.
          DemoRail(
            title: 'SankeyChartRebalance',
            children: [
              SizedBox(
                width: 820,
                height: 412,
                child: FluentSankeyChart(
                  data: _sankeyRebalance,
                  chartTitle: 'Sankey Chart',
                ),
              ),
            ],
          ),
          // charts-sankeychart--sankey-chart-responsive: upstream wraps this in
          // ResponsiveContainer. The Flutter chart honours its BoxConstraints
          // (spec section 2.2), so a narrow box is the equivalent — and 480 is
          // below kSankeyDefaultWidth, which is what exercises minWidth reflow.
          DemoRail(
            title: 'SankeyChartResponsive',
            children: [
              SizedBox(
                width: 480,
                height: 320,
                child: FluentSankeyChart(
                  data: _sankeyResponsive,
                  chartTitle: 'Sankey Chart',
                  reflowMode: FluentSankeyReflowMode.minWidth,
                ),
              ),
            ],
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Charts/FluentDeclarativeChart',
    description:
        'Renders a Plotly figure by routing it to one of the Fluent charts, '
        'with no chart type named by the caller.',
    builder: (context) {
      return DemoColumn(
        children: [
          for (final entry in _plotlyStorySchemas.entries)
            DemoRail(
              title: entry.key,
              children: [
                SizedBox(
                  // DemoRail lays its children out in a Wrap, which offers
                  // unbounded width, so a cell has to state both extents.
                  // 400 is the tallest intrinsic height either adapter asks
                  // for — a routed cell plus its own legend strip — and is
                  // what stops the Column inside the chart overflowing; 520
                  // keeps the axis labels legible on a laptop canvas.
                  width: 520,
                  height: 400,
                  child: FluentDeclarativeChart(
                    chartSchema: FluentPlotlySchema(plotlySchema: entry.value),
                  ),
                ),
              ],
            ),
        ],
      );
    },
  ),
  Story(
    name: 'Charts/FluentVegaDeclarativeChart',
    description:
        'Renders a Vega-Lite specification by routing it to one of the Fluent '
        'charts.',
    builder: (context) {
      return DemoColumn(
        children: [
          for (final entry in _vegaStorySpecs.entries)
            DemoRail(
              title: entry.key,
              children: [
                SizedBox(
                  // As above. The stacked bar is the cell that needs all 400:
                  // kVegaDefaultCellHeight gives it 350 and its lifted legend
                  // takes the rest.
                  width: 520,
                  height: 400,
                  child: FluentVegaDeclarativeChart(
                    chartSchema: FluentVegaSchema(vegaLiteSpec: entry.value),
                  ),
                ),
              ],
            ),
        ],
      );
    },
  ),
];

/// Plotly schemas the FluentDeclarativeChart story renders, one per output
/// kind.
///
/// Each is a minimal figure exercising a different branch of `mapFluentChart`
/// so a reviewer can see the router working: a bar trace with no `barmode`
/// stacks, a numeric-x `mode: 'lines'` scatter is a line, and a `pie` with a
/// `hole` is a donut.
const Map<String, Map<String, Object?>> _plotlyStorySchemas =
    <String, Map<String, Object?>>{
      'Vertical stacked bar': <String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'bar',
            'name': 'Revenue',
            'x': <Object?>['Q1', 'Q2', 'Q3', 'Q4'],
            'y': <Object?>[42, 55, 38, 61],
          },
        ],
      },
      'Line': <String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'scatter',
            'mode': 'lines',
            'name': 'Latency',
            'x': <Object?>[1, 2, 3, 4, 5],
            'y': <Object?>[12, 19, 14, 22, 17],
          },
        ],
      },
      'Donut': <String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'pie',
            'hole': 0.5,
            'labels': <Object?>['Alpha', 'Beta', 'Gamma'],
            'values': <Object?>[30, 45, 25],
          },
        ],
      },
    };

/// Vega-Lite specs the FluentVegaDeclarativeChart story renders.
///
/// The pair differs only in the `color` channel, which is the whole of the
/// bar-versus-stacked-bar decision in the routing ladder.
const Map<String, Map<String, Object?>> _vegaStorySpecs =
    <String, Map<String, Object?>>{
      'Bar': <String, Object?>{
        'mark': 'bar',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'category': 'A', 'amount': 28},
            <String, Object?>{'category': 'B', 'amount': 55},
            <String, Object?>{'category': 'C', 'amount': 43},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'category', 'type': 'nominal'},
          'y': <String, Object?>{'field': 'amount', 'type': 'quantitative'},
        },
      },
      'Stacked bar': <String, Object?>{
        'mark': 'bar',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'category': 'A', 'group': 'x', 'amount': 12},
            <String, Object?>{'category': 'A', 'group': 'y', 'amount': 16},
            <String, Object?>{'category': 'B', 'group': 'x', 'amount': 30},
            <String, Object?>{'category': 'B', 'group': 'y', 'amount': 25},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'category', 'type': 'nominal'},
          'y': <String, Object?>{'field': 'amount', 'type': 'quantitative'},
          'color': <String, Object?>{'field': 'group', 'type': 'nominal'},
        },
      },
    };

/// The six-subject radar data of `charts-polarchart--polar-chart-basic`
/// (PolarChartDefault.stories.tsx). The two hex colours are the story's own
/// literals, not palette tokens.
const _polarSubjectScores = <FluentPolarSeries>[
  FluentAreaPolarSeries(
    legend: 'Mike',
    color: Color(0xFF8884D8),
    data: [
      FluentPolarDataPoint(r: 120, theta: 'Math'),
      FluentPolarDataPoint(r: 98, theta: 'Chinese'),
      FluentPolarDataPoint(r: 86, theta: 'English'),
      FluentPolarDataPoint(r: 99, theta: 'Geography'),
      FluentPolarDataPoint(r: 85, theta: 'Physics'),
      FluentPolarDataPoint(r: 65, theta: 'History'),
    ],
  ),
  FluentAreaPolarSeries(
    legend: 'Lily',
    color: Color(0xFF82CA9D),
    data: [
      FluentPolarDataPoint(r: 110, theta: 'Math'),
      FluentPolarDataPoint(r: 130, theta: 'Chinese'),
      FluentPolarDataPoint(r: 130, theta: 'English'),
      FluentPolarDataPoint(r: 100, theta: 'Geography'),
      FluentPolarDataPoint(r: 90, theta: 'Physics'),
      FluentPolarDataPoint(r: 85, theta: 'History'),
    ],
  ),
];

/// Every sankey story calls `getColorFromToken(DataVizPalette.colorN)`, which is
/// [FluentDataVizPalette.resolve] here. Not const, so the fixtures below are
/// lazily initialised top-level finals.
FluentSankeyNode _node(
  int id,
  String name,
  FluentDataVizToken fill,
  FluentDataVizToken border,
) => FluentSankeyNode(
  nodeId: id,
  name: name,
  color: FluentDataVizPalette.resolve(fill),
  borderColor: FluentDataVizPalette.resolve(border),
);

/// A weighted stream from [source] to [target].
FluentSankeyLink _link(int source, int target, double value) =>
    FluentSankeyLink(source: source, target: target, value: value);

/// `charts-sankeychart--sankey-chart-basic` (SankeyChartBasic.stories.tsx).
final _sankeyBasic = FluentSankeyChartData(
  nodes: [
    _node(0, 'node0', FluentDataVizToken.color2, FluentDataVizToken.color22),
    _node(1, 'node1', FluentDataVizToken.color7, FluentDataVizToken.color27),
    _node(2, 'node2', FluentDataVizToken.color8, FluentDataVizToken.color28),
    _node(3, 'node3', FluentDataVizToken.color9, FluentDataVizToken.color29),
    // node4's border is color8, not color24 — the story is inconsistent here.
    _node(4, 'node4', FluentDataVizToken.color11, FluentDataVizToken.color8),
    _node(5, 'node5', FluentDataVizToken.color12, FluentDataVizToken.color24),
  ],
  links: [
    _link(0, 2, 2),
    _link(1, 2, 2),
    _link(1, 3, 2),
    _link(0, 4, 2),
    _link(2, 3, 2),
    _link(2, 4, 2),
    _link(3, 4, 4),
    _link(3, 5, 4),
  ],
);

/// `charts-sankeychart--sankey-chart-inbox` (SankeyChartInbox.stories.tsx).
///
/// Node 11's name keeps the story's leading and doubled spaces verbatim,
/// because it is what exercises the truncation of task 15.
final _sankeyInbox = FluentSankeyChartData(
  nodes: [
    _node(
      0,
      '192.168.42.72',
      FluentDataVizToken.color2,
      FluentDataVizToken.color22,
    ),
    _node(
      1,
      '172.152.48.13',
      FluentDataVizToken.color2,
      FluentDataVizToken.color22,
    ),
    _node(
      2,
      '124.360.55.1',
      FluentDataVizToken.color2,
      FluentDataVizToken.color22,
    ),
    _node(
      3,
      '192.564.10.2',
      FluentDataVizToken.color2,
      FluentDataVizToken.color22,
    ),
    _node(
      4,
      '124.124.50.1',
      FluentDataVizToken.color2,
      FluentDataVizToken.color22,
    ),
    _node(
      5,
      '172.630.89.4',
      FluentDataVizToken.color2,
      FluentDataVizToken.color22,
    ),
    _node(6, 'inbox', FluentDataVizToken.color7, FluentDataVizToken.color27),
    _node(
      7,
      'Junk Folder',
      FluentDataVizToken.color7,
      FluentDataVizToken.color27,
    ),
    _node(
      8,
      'Deleted Folder',
      FluentDataVizToken.color7,
      FluentDataVizToken.color27,
    ),
    _node(9, 'Clicked', FluentDataVizToken.color8, FluentDataVizToken.color28),
    _node(10, 'Opened', FluentDataVizToken.color8, FluentDataVizToken.color28),
    _node(
      11,
      ' No further action  required',
      FluentDataVizToken.color8,
      FluentDataVizToken.color28,
    ),
  ],
  links: [
    _link(0, 6, 80),
    _link(1, 6, 50),
    _link(1, 7, 28),
    _link(2, 7, 14),
    _link(3, 7, 7),
    _link(3, 8, 20),
    _link(4, 7, 10),
    _link(5, 7, 10),
    _link(6, 9, 30),
    _link(6, 10, 55),
    _link(7, 11, 60),
    _link(8, 11, 2),
  ],
);

/// The simple dataset of `charts-sankeychart--sankey-chart-rebalance`
/// (SankeyChartRebalance.stories.tsx). The 10 000-to-1 spread is the point: the
/// one-percent nodes are the ones task 13 renormalises.
final _sankeyRebalance = FluentSankeyChartData(
  nodes: [
    _node(
      0,
      'Large Source',
      FluentDataVizToken.color11,
      FluentDataVizToken.color21,
    ),
    _node(
      1,
      'Tiny Source',
      FluentDataVizToken.color12,
      FluentDataVizToken.color22,
    ),
    _node(
      2,
      'Large Target',
      FluentDataVizToken.color13,
      FluentDataVizToken.color23,
    ),
    _node(
      3,
      'Tiny Target',
      FluentDataVizToken.color14,
      FluentDataVizToken.color24,
    ),
  ],
  links: [_link(0, 2, 10000), _link(1, 2, 1), _link(0, 3, 1), _link(1, 3, 1)],
);

/// `charts-sankeychart--sankey-chart-responsive`
/// (SankeyChartResponsive.stories.tsx) — the basic topology under a different
/// palette.
final _sankeyResponsive = FluentSankeyChartData(
  nodes: [
    _node(0, 'node0', FluentDataVizToken.color11, FluentDataVizToken.color21),
    _node(1, 'node1', FluentDataVizToken.color12, FluentDataVizToken.color22),
    _node(2, 'node2', FluentDataVizToken.color13, FluentDataVizToken.color23),
    _node(3, 'node3', FluentDataVizToken.color14, FluentDataVizToken.color24),
    _node(4, 'node4', FluentDataVizToken.color2, FluentDataVizToken.color22),
    _node(5, 'node5', FluentDataVizToken.color15, FluentDataVizToken.color25),
  ],
  links: [
    _link(0, 2, 2),
    _link(1, 2, 2),
    _link(1, 3, 2),
    _link(0, 4, 2),
    _link(2, 3, 2),
    _link(2, 4, 2),
    _link(3, 4, 4),
    _link(3, 5, 4),
  ],
);

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
