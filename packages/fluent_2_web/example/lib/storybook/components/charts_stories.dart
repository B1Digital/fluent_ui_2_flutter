// The seven shell-free chart widgets are not exported from
// `lib/fluent_2_web.dart` yet — that file is owned by the integration tasks —
// so this file deep-imports them, exactly as
// `test/goldens/charts_shell_free_golden_test.dart` already does. Swap these
// seven lines for the barrel once the exports land.
// ignore_for_file: implementation_imports
import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/annotation_only_chart.dart';
import 'package:fluent_2_web/src/charts/chart_table.dart';
import 'package:fluent_2_web/src/charts/donut_chart.dart';
import 'package:fluent_2_web/src/charts/funnel_chart.dart';
import 'package:fluent_2_web/src/charts/gauge_chart.dart';
import 'package:fluent_2_web/src/charts/horizontal_bar_chart.dart';
import 'package:fluent_2_web/src/charts/sparkline.dart';
import 'package:flutter/widgets.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import 'story_kit.dart';

/// Stories for the shared chart chrome, then the seven charts that bypass the
/// cartesian shell.
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
