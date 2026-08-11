import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import 'story_kit.dart';

/// The "show me everything" companion to `chartsStories`.
///
/// `chartsStories` is deliberately minimal — one series of three or four points
/// per chart — because its sample data is shared with
/// `test/goldens/charts_shell_free_golden_test.dart`, so moving a value there
/// moves a golden. These stories carry their own data instead, sized so the
/// multi-series, multi-layer and per-point options are actually visible.
///
/// Every number below is invented sample telemetry for a fictional cloud
/// platform: months, regions and service names rather than 1/2/3, because the
/// point of this file is how the charts *look* under a plausible dataset. The
/// box sizes are the only load-bearing constants — roughly 700x300 for a
/// cartesian chart, smaller for the radial ones — and they are the smallest
/// cells in which the axis labels stay legible on a laptop canvas.
List<Story> get chartsShowcaseStories => [
  Story(
    name: 'Charts showcase/FluentLineChart',
    description:
        'Four series over twelve months, then stroke options, curves, '
        'per-point marker sizes and a secondary y scale.',
    builder: (context) => DemoColumn(
      children: [
        DemoRail(
          title: 'Four services, twelve months, one gap',
          children: [
            SizedBox(
              width: 700,
              height: 300,
              child: FluentLineChart(
                // A different marker shape per series, which is the only thing
                // keeping four overlapping lines apart in monochrome.
                allowMultipleShapesForPoints: true,
                props: const FluentCartesianChartProps(
                  xAxisTitle: 'Month',
                  yAxisTitle: 'p95 latency (ms)',
                ),
                data: FluentChartData(
                  chartTitle: 'p95 latency by service, 2025',
                  lineChartData: [
                    _monthly('API gateway', _apiLatency),
                    _monthly('Identity', _identityLatency),
                    _monthly('Search', _searchLatency),
                    _monthly(
                      'Media',
                      _mediaLatency,
                      // The May-to-July migration window: the points are still
                      // measured, the connecting segments are not drawn.
                      gaps: const [
                        FluentLineChartGap(startIndex: 4, endIndex: 6),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        DemoRail(
          title: 'FluentLineOptions: width, dashes and halos',
          children: [
            SizedBox(
              width: 700,
              height: 300,
              child: FluentLineChart(
                data: FluentChartData(
                  chartTitle: 'Stroke options',
                  lineChartData: [
                    _monthly(
                      'Hairline',
                      _band(20),
                      lineOptions: const FluentLineOptions(strokeWidth: 1),
                    ),
                    _monthly(
                      'Heavy',
                      _band(40),
                      lineOptions: const FluentLineOptions(strokeWidth: 6),
                    ),
                    _monthly(
                      'Forecast',
                      _band(60),
                      lineOptions: const FluentLineOptions(
                        strokeWidth: 3,
                        strokeDasharray: '8 4',
                      ),
                    ),
                    _monthly(
                      'Halo, theme colour',
                      _band(80),
                      lineOptions: const FluentLineOptions(
                        strokeWidth: 3,
                        // A null lineBorderColor resolves against the theme, so
                        // the halo stays a canvas-coloured cut-out in the dark
                        // theme as well as the light one.
                        lineBorderWidth: 9,
                      ),
                    ),
                    _monthly(
                      'Halo, explicit colour',
                      _band(100),
                      lineOptions: const FluentLineOptions(
                        strokeWidth: 3,
                        lineBorderWidth: 9,
                        lineBorderColor: Color(0xFFFFB900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        DemoRail(
          title: 'FluentLineCurve: all five interpolations',
          children: [
            SizedBox(
              width: 700,
              height: 300,
              child: FluentLineChart(
                data: FluentChartData(
                  chartTitle: 'The same six points, five curves',
                  lineChartData: _curveSeries,
                ),
              ),
            ),
          ],
        ),
        DemoRail(
          title: 'Per-point markerSize',
          children: [
            SizedBox(
              width: 700,
              height: 300,
              child: FluentLineChart(
                data: FluentChartData(
                  chartTitle: 'Latency, marker scaled by order volume',
                  lineChartData: [
                    FluentLineChartSeries(
                      legend: 'Checkout',
                      // A marker size is only measured against the plot's pixel
                      // budget in markers mode; without it every marker falls
                      // back to the same four-pixel floor.
                      lineOptions: const FluentLineOptions(
                        mode: FluentLineMode(markers: true),
                      ),
                      data: [
                        for (var index = 0; index < _months.length; index++)
                          FluentLineChartDataPoint(
                            x: _months[index],
                            y: _checkoutLatency[index],
                            markerSize: _checkoutVolume[index],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        DemoRail(
          title: 'useSecondaryYScale',
          children: [
            SizedBox(
              width: 700,
              height: 300,
              child: FluentLineChart(
                props: const FluentCartesianChartProps(
                  // Without bounds there is no second scale to plot against.
                  secondaryYScaleOptions: FluentSecondaryYScaleOptions(
                    yMaxValue: 5,
                  ),
                  yAxisTitle: 'p95 latency (ms)',
                  secondaryYAxisTitle: 'Error rate (%)',
                ),
                data: FluentChartData(
                  chartTitle: 'Latency against error rate',
                  lineChartData: [
                    _monthly('API gateway', _apiLatency),
                    _monthly('Search', _searchLatency),
                    _monthly(
                      'Error rate',
                      _errorRate,
                      useSecondaryYScale: true,
                      lineOptions: const FluentLineOptions(
                        strokeDasharray: '4 4',
                      ),
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
    name: 'Charts showcase/FluentAreaChart',
    description:
        'Three layers stacked on one another over a twelve-month axis.',
    builder: (context) => DemoColumn(
      children: [
        DemoRail(
          title: 'Three stacked layers',
          children: [
            SizedBox(
              width: 700,
              height: 300,
              child: FluentAreaChart(
                data: FluentChartData(
                  chartTitle: 'Sessions by acquisition channel',
                  lineChartData: _channelLayers,
                ),
              ),
            ),
          ],
        ),
        DemoRail(
          title: 'The same three layers, unstacked and gradient filled',
          children: [
            SizedBox(
              width: 700,
              height: 300,
              child: FluentAreaChart(
                // Every layer sits on zero instead of on the one below it.
                mode: FluentAreaChartMode.toZeroY,
                enableGradient: true,
                data: FluentChartData(
                  chartTitle: 'Sessions by acquisition channel',
                  lineChartData: _channelLayers,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts showcase/FluentVerticalStackedBarChart',
    description:
        'Three-segment stacks under a two-line overlay, one of the lines on '
        'the secondary y scale.',
    builder: (context) => DemoColumn(
      children: [
        DemoRail(
          title: 'Three segments plus a lineData overlay',
          children: [
            SizedBox(
              width: 700,
              height: 300,
              child: FluentVerticalStackedBarChart(
                chartTitle: 'Cloud spend by workload',
                roundCorners: true,
                props: const FluentCartesianChartProps(
                  secondaryYScaleOptions: FluentSecondaryYScaleOptions(),
                  yAxisTitle: 'Spend (thousands)',
                  secondaryYAxisTitle: 'Reserved capacity used (%)',
                ),
                data: _spendStacks,
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts showcase/FluentGroupedVerticalBarChart',
    description: 'Four quarters, three series side by side inside each band.',
    builder: (context) => DemoColumn(
      children: [
        DemoRail(
          title: 'Four groups by three series',
          children: [
            SizedBox(
              width: 700,
              height: 300,
              child: FluentGroupedVerticalBarChart(
                chartTitle: 'Net new seats by region',
                roundCorners: true,
                props: const FluentCartesianChartProps(
                  yAxisTitle: 'Seats (thousands)',
                ),
                data: _seatsByQuarter,
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts showcase/FluentScatterChart',
    description: 'Three series whose marker radius carries a third variable.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Marker radius scaled per point',
          children: [
            SizedBox(
              width: 700,
              height: 300,
              child: FluentScatterChart(
                props: FluentCartesianChartProps(
                  xAxisTitle: 'Monthly active users (thousands)',
                  yAxisTitle: 'Retention (%)',
                ),
                data: FluentChartData(
                  chartTitle: 'Retention against reach, radius is revenue',
                  scatterChartData: _tierScatter,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts showcase/FluentHeatMapChart',
    description: 'A six by five grid over a three-stop colour ramp.',
    builder: (context) => DemoColumn(
      children: [
        DemoRail(
          title: 'Six days by five time bands',
          children: [
            SizedBox(
              width: 700,
              height: 320,
              child: FluentHeatMapChart(
                chartTitle: 'Cluster utilisation by day and hour',
                // Three stops rather than two, so the ramp reads as cool to
                // warm instead of as one fade.
                domainValuesForColorScale: const [0, 50, 100],
                rangeValuesForColorScale: const [
                  Color(0xFFEDF8FB),
                  Color(0xFF41B6C4),
                  Color(0xFF0B2E4F),
                ],
                // The rows are already in the order they should read in.
                sortAlphabetically: false,
                data: [_utilisationGrid],
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts showcase/FluentDonutChart',
    description:
        'Six segments: as a pie, as a ring with a centred total, and with arc '
        'labels in per cent.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Six segments',
          children: [
            SizedBox(
              width: 280,
              height: 260,
              child: FluentDonutChart(data: _spendShare),
            ),
            SizedBox(
              width: 280,
              height: 260,
              child: FluentDonutChart(
                data: _spendShare,
                // Wide enough to leave a legible hole in a 280x260 cell.
                innerRadius: 55,
                valueInsideDonut: '1.42M',
              ),
            ),
            SizedBox(
              width: 280,
              height: 260,
              child: FluentDonutChart(
                data: _spendShare,
                innerRadius: 55,
                hideLabels: false,
                showLabelsInPercent: true,
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts showcase/FluentGaugeChart',
    description:
        'Five breakpoints, with a sublabel, rounded corners and the '
        'single-segment variant beside them.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Five breakpoints',
          children: [
            SizedBox(
              width: 320,
              height: 240,
              child: FluentGaugeChart(
                chartTitle: 'Service health',
                chartValue: 68,
                sublabel: 'of SLO budget',
                segments: _healthBands,
              ),
            ),
            SizedBox(
              width: 320,
              height: 240,
              child: FluentGaugeChart(
                chartTitle: 'Service health',
                chartValue: 68,
                roundCorners: true,
                segments: _healthBands,
              ),
            ),
            SizedBox(
              width: 320,
              height: 240,
              child: FluentGaugeChart(
                chartTitle: 'Storage used',
                chartValue: 68,
                variant: FluentGaugeChartVariant.singleSegment,
                segments: [FluentGaugeChartSegment(legend: 'Used', size: 100)],
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts showcase/FluentFunnelChart',
    description:
        'Six stages, then the same funnel split into two categories per stage.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Six stages',
          children: [
            SizedBox(
              width: 300,
              height: 320,
              child: FluentFunnelChart(
                chartTitle: 'Trial to paid',
                data: _trialFunnel,
              ),
            ),
            SizedBox(
              width: 340,
              height: 320,
              child: FluentFunnelChart(
                chartTitle: 'Trial to paid',
                orientation: FluentFunnelOrientation.horizontal,
                data: _trialFunnel,
              ),
            ),
          ],
        ),
        DemoRail(
          title: 'Stacked stages',
          children: [
            SizedBox(
              width: 300,
              height: 320,
              child: FluentFunnelChart(
                chartTitle: 'Trial to paid by plan',
                data: _trialFunnelByPlan,
              ),
            ),
            SizedBox(
              width: 340,
              height: 320,
              child: FluentFunnelChart(
                chartTitle: 'Trial to paid by plan',
                orientation: FluentFunnelOrientation.horizontal,
                data: _trialFunnelByPlan,
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts showcase/FluentHorizontalBarChartWithAxis',
    description:
        'Five regions with three stacked series each, on a band y axis.',
    builder: (context) => DemoColumn(
      children: [
        DemoRail(
          title: 'Three series across five regions',
          children: [
            SizedBox(
              width: 700,
              height: 300,
              child: FluentHorizontalBarChartWithAxis(
                chartTitle: 'Spend by region and workload',
                roundCorners: true,
                props: const FluentCartesianChartProps(
                  xAxisTitle: 'Spend (thousands)',
                ),
                data: _regionSpend,
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts showcase/FluentGanttChart',
    description:
        'Six workstreams across three phases on a date axis, gradient filled.',
    builder: (context) => DemoColumn(
      children: [
        DemoRail(
          title: 'Three phases across six workstreams',
          children: [
            SizedBox(
              width: 700,
              height: 320,
              child: FluentGanttChart(
                chartTitle: 'Platform migration, 2025',
                roundCorners: true,
                enableGradient: true,
                data: _migrationPlan,
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts showcase/FluentPolarChart',
    description:
        'Three series over eight axes, as a polygon grid and as a circular one '
        'with a hole.',
    builder: (context) => const DemoColumn(
      children: [
        DemoRail(
          title: 'Three series, eight axes',
          children: [
            FluentPolarChart(
              data: _capabilityScores,
              chartTitle: 'Capability coverage',
              width: 480,
              height: 340,
              shape: FluentPolarShape.polygon,
              direction: FluentPolarDirection.clockwise,
            ),
            FluentPolarChart(
              data: _capabilityScores,
              chartTitle: 'Capability coverage',
              width: 480,
              height: 340,
              // A hole keeps the low-scoring centre readable.
              hole: 0.25,
            ),
          ],
        ),
      ],
    ),
  ),
  Story(
    name: 'Charts showcase/FluentChartLegend',
    description:
        'Fourteen rows in overflow and in wrapped mode, every shape, and the '
        'striped and line-in-bar swatches.',
    builder: (context) => DemoColumn(
      children: [
        DemoRail(
          title: 'Overflow: more rows than the strip can hold',
          children: [
            SizedBox(
              // Narrow enough that the fourteen rows cannot all fit, which is
              // what puts the remainder behind the "+n services" trigger.
              width: 520,
              child: FluentChartLegend(
                legends: _serviceLegends,
                overflowText: 'services',
                selectionMode: FluentChartLegendSelectionMode.multiple,
              ),
            ),
          ],
        ),
        DemoRail(
          title: 'Wrapped: the same rows over as many lines as it takes',
          children: [
            SizedBox(
              width: 520,
              child: FluentChartLegend(
                legends: _serviceLegends,
                enabledWrapLines: true,
                centerLegends: true,
                selectionMode: FluentChartLegendSelectionMode.multiple,
              ),
            ),
          ],
        ),
        DemoRail(
          title: 'Every FluentChartLegendShape',
          children: [
            SizedBox(
              width: 700,
              child: FluentChartLegend(
                enabledWrapLines: true,
                legends: [
                  for (final (index, shape)
                      in FluentChartLegendShape.values.indexed)
                    FluentChartLegendItem(
                      title: shape.name,
                      color: FluentDataVizPalette.next(index),
                      shape: shape,
                    ),
                ],
              ),
            ),
          ],
        ),
        DemoRail(
          title: 'Striped and line-in-bar swatches',
          children: [
            SizedBox(
              width: 700,
              child: FluentChartLegend(
                enabledWrapLines: true,
                legends: [
                  FluentChartLegendItem(
                    title: 'measured',
                    color: FluentDataVizPalette.next(0),
                  ),
                  FluentChartLegendItem(
                    title: 'projected',
                    color: FluentDataVizPalette.next(1),
                    stripePattern: true,
                  ),
                  FluentChartLegendItem(
                    title: 'target',
                    color: FluentDataVizPalette.next(2),
                    isLineLegendInBarChart: true,
                  ),
                  FluentChartLegendItem(
                    title: 'retired',
                    color: FluentDataVizPalette.next(3),
                    // A dimmed swatch; its border keeps the full colour.
                    opacity: 0.3,
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

// ---------------------------------------------------------------------------
// Shared sample data — invented telemetry for a fictional cloud platform.
// ---------------------------------------------------------------------------

/// The twelve month starts of 2025, shared by every time-series rail.
final List<DateTime> _months = [
  for (var month = 1; month <= 12; month++) DateTime.utc(2025, month),
];

/// A line series over [_months], one y per month.
FluentLineChartSeries _monthly(
  String legend,
  List<double> values, {
  List<FluentLineChartGap>? gaps,
  FluentLineOptions? lineOptions,
  bool useSecondaryYScale = false,
}) => FluentLineChartSeries(
  legend: legend,
  gaps: gaps,
  lineOptions: lineOptions,
  useSecondaryYScale: useSecondaryYScale,
  data: [
    for (var index = 0; index < _months.length; index++)
      FluentLineChartDataPoint(x: _months[index], y: values[index]),
  ],
);

/// A gently wobbling twelve-month series centred on [centre].
///
/// The stroke rail is about the stroke and not the shape, so each of its series
/// gets the same wobble in a band of its own.
List<double> _band(double centre) => [
  for (final offset in const [0, 4, -3, 6, 1, -4, 3, -2, 5, 0, -3, 2])
    centre + offset,
];

const List<double> _apiLatency = [
  182,
  176,
  191,
  205,
  198,
  187,
  176,
  169,
  174,
  188,
  203,
  196,
];

const List<double> _identityLatency = [
  96,
  101,
  94,
  89,
  92,
  88,
  85,
  91,
  97,
  103,
  99,
  94,
];

const List<double> _searchLatency = [
  248,
  262,
  255,
  241,
  236,
  229,
  244,
  258,
  271,
  264,
  252,
  243,
];

const List<double> _mediaLatency = [
  312,
  305,
  318,
  296,
  288,
  301,
  334,
  327,
  309,
  294,
  286,
  291,
];

const List<double> _errorRate = [
  1.2,
  1.4,
  0.9,
  2.1,
  3.4,
  2.8,
  1.1,
  0.7,
  0.9,
  1.6,
  2.2,
  1.3,
];

const List<double> _checkoutLatency = [
  142,
  138,
  151,
  147,
  133,
  129,
  158,
  164,
  149,
  141,
  136,
  144,
];

/// Marker radii for the markerSize rail: monthly orders in hundreds of
/// thousands, which is what the marker is standing in for.
const List<double> _checkoutVolume = [
  6,
  7,
  9,
  8,
  11,
  14,
  12,
  10,
  13,
  16,
  22,
  28,
];

/// The six-point shape every curve series traces before it is lifted into a
/// band of its own.
const List<double> _curveShape = [12, 34, 22, 41, 28, 36];

/// One series per [FluentLineCurve], each raised clear of the one below it so
/// the five interpolations can be compared in a single plot.
List<FluentLineChartSeries> get _curveSeries => [
  for (final (index, curve) in FluentLineCurve.values.indexed)
    FluentLineChartSeries(
      legend: curve.name,
      lineOptions: FluentLineOptions(
        curve: curve,
        // Any curve switches the chart to the single-path engine, and that
        // engine draws markers only in markers mode.
        mode: const FluentLineMode(markers: true),
      ),
      data: [
        for (final (pointIndex, value) in _curveShape.indexed)
          FluentLineChartDataPoint(x: pointIndex, y: value + index * 55),
      ],
    ),
];

/// The three area layers, stacked bottom to top by the default
/// [FluentAreaChartMode.toNextY].
List<FluentLineChartSeries> get _channelLayers => [
  _monthly('Direct', const [41, 44, 39, 47, 52, 49, 45, 43, 51, 58, 64, 71]),
  _monthly('Organic search', const [
    28,
    31,
    34,
    33,
    37,
    41,
    44,
    46,
    45,
    49,
    53,
    58,
  ]),
  _monthly('Partner referral', const [
    12,
    14,
    13,
    18,
    21,
    19,
    17,
    22,
    26,
    24,
    29,
    33,
  ]),
];

/// Six months of three-segment stacks, each carrying two overlay line points —
/// one on the primary scale, one on the secondary.
List<FluentVerticalStackedBarGroup> get _spendStacks {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
  const compute = [48.0, 52.0, 57.0, 55.0, 61.0, 66.0];
  const storage = [22.0, 24.0, 23.0, 27.0, 29.0, 31.0];
  const network = [11.0, 13.0, 12.0, 16.0, 15.0, 18.0];
  const budget = [85.0, 88.0, 92.0, 96.0, 100.0, 104.0];
  const reserved = [62.0, 66.0, 71.0, 68.0, 74.0, 81.0];
  return [
    for (var index = 0; index < months.length; index++)
      FluentVerticalStackedBarGroup(
        xAxisPoint: months[index],
        chartData: [
          FluentStackedBarDatum(data: compute[index], legend: 'Compute'),
          FluentStackedBarDatum(data: storage[index], legend: 'Storage'),
          FluentStackedBarDatum(data: network[index], legend: 'Network'),
        ],
        lineData: [
          FluentStackedBarLineDatum(
            y: budget[index],
            legend: 'Budget',
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color9),
          ),
          FluentStackedBarLineDatum(
            y: reserved[index],
            legend: 'Reserved capacity used',
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
            useSecondaryYScale: true,
            lineOptions: const FluentLineOptions(strokeDasharray: '6 3'),
          ),
        ],
      ),
  ];
}

/// Four quarters, three regions in each.
List<FluentGroupedVerticalBarChartData> get _seatsByQuarter {
  const quarters = ['Q1', 'Q2', 'Q3', 'Q4'];
  const americas = [34.0, 41.0, 38.0, 52.0];
  const emea = [27.0, 25.0, 33.0, 39.0];
  const apac = [18.0, 24.0, 29.0, 31.0];
  return [
    for (var index = 0; index < quarters.length; index++)
      FluentGroupedVerticalBarChartData(
        name: quarters[index],
        series: [
          FluentGroupedBarSeriesPoint(
            key: 'americas',
            data: americas[index],
            legend: 'Americas',
          ),
          FluentGroupedBarSeriesPoint(
            key: 'emea',
            data: emea[index],
            legend: 'EMEA',
          ),
          FluentGroupedBarSeriesPoint(
            key: 'apac',
            data: apac[index],
            legend: 'Asia Pacific',
          ),
        ],
      ),
  ];
}

/// Three plan tiers, the radius standing in for annual revenue.
const List<FluentScatterChartSeries> _tierScatter = [
  FluentScatterChartSeries(
    legend: 'Enterprise',
    data: [
      FluentScatterChartDataPoint(x: 120, y: 94, markerSize: 26),
      FluentScatterChartDataPoint(x: 165, y: 91, markerSize: 34),
      FluentScatterChartDataPoint(x: 210, y: 96, markerSize: 44),
      FluentScatterChartDataPoint(x: 148, y: 88, markerSize: 30),
      FluentScatterChartDataPoint(x: 188, y: 93, markerSize: 38),
    ],
  ),
  FluentScatterChartSeries(
    legend: 'Business',
    data: [
      FluentScatterChartDataPoint(x: 64, y: 81, markerSize: 14),
      FluentScatterChartDataPoint(x: 92, y: 78, markerSize: 18),
      FluentScatterChartDataPoint(x: 118, y: 84, markerSize: 22),
      FluentScatterChartDataPoint(x: 78, y: 74, markerSize: 16),
      FluentScatterChartDataPoint(x: 105, y: 79, markerSize: 20),
    ],
  ),
  FluentScatterChartSeries(
    legend: 'Starter',
    data: [
      FluentScatterChartDataPoint(x: 22, y: 61, markerSize: 6),
      FluentScatterChartDataPoint(x: 38, y: 58, markerSize: 8),
      FluentScatterChartDataPoint(x: 54, y: 66, markerSize: 10),
      FluentScatterChartDataPoint(x: 30, y: 52, markerSize: 7),
      FluentScatterChartDataPoint(x: 46, y: 63, markerSize: 9),
    ],
  ),
];

/// A thirty-cell grid: six days across, five time bands down.
FluentHeatMapChartData get _utilisationGrid {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const bands = ['22:00', '18:00', '12:00', '06:00', '00:00'];
  // One row per band, in the order of `bands`.
  const values = [
    [38.0, 41.0, 44.0, 47.0, 62.0, 71.0],
    [66.0, 71.0, 74.0, 78.0, 88.0, 54.0],
    [82.0, 88.0, 94.0, 91.0, 76.0, 31.0],
    [44.0, 49.0, 52.0, 55.0, 48.0, 18.0],
    [12.0, 14.0, 17.0, 19.0, 24.0, 9.0],
  ];
  return FluentHeatMapChartData(
    legend: 'Utilisation',
    // The band's own legend colour is chosen from this, not from the cells.
    value: 60,
    data: [
      for (var row = 0; row < bands.length; row++)
        for (var column = 0; column < days.length; column++)
          FluentHeatMapChartDataPoint(
            x: days[column],
            y: bands[row],
            value: values[row][column],
            rectText: '${values[row][column].round()}%',
          ),
    ],
  );
}

const FluentChartData _spendShare = FluentChartData(
  chartTitle: 'Spend by service',
  chartData: [
    FluentChartDataPoint(legend: 'Compute', data: 420),
    FluentChartDataPoint(legend: 'Storage', data: 310),
    FluentChartDataPoint(legend: 'Networking', data: 245),
    FluentChartDataPoint(legend: 'Databases', data: 190),
    FluentChartDataPoint(legend: 'Analytics', data: 155),
    FluentChartDataPoint(legend: 'Support', data: 100),
  ],
);

/// Five breakpoints whose sizes sum to the gauge's full span.
const List<FluentGaugeChartSegment> _healthBands = [
  FluentGaugeChartSegment(legend: 'Critical', size: 20),
  FluentGaugeChartSegment(legend: 'Degraded', size: 20),
  FluentGaugeChartSegment(legend: 'Fair', size: 20),
  FluentGaugeChartSegment(legend: 'Good', size: 20),
  FluentGaugeChartSegment(legend: 'Excellent', size: 20),
];

const List<FluentFunnelDataPoint> _trialFunnel = [
  FluentFunnelDataPoint(stage: 'Visited', value: 12400),
  FluentFunnelDataPoint(stage: 'Signed up', value: 7300),
  FluentFunnelDataPoint(stage: 'Activated', value: 4850),
  FluentFunnelDataPoint(stage: 'Invited a team', value: 2600),
  FluentFunnelDataPoint(stage: 'Added billing', value: 1450),
  FluentFunnelDataPoint(stage: 'Renewed', value: 980),
];

/// The same funnel with every stage split by plan, which is what makes a
/// funnel stacked.
const List<FluentFunnelDataPoint> _trialFunnelByPlan = [
  FluentFunnelDataPoint(
    stage: 'Visited',
    subValues: [
      FluentFunnelSubValue(category: 'Business', value: 8100),
      FluentFunnelSubValue(category: 'Enterprise', value: 4300),
    ],
  ),
  FluentFunnelDataPoint(
    stage: 'Signed up',
    subValues: [
      FluentFunnelSubValue(category: 'Business', value: 4700),
      FluentFunnelSubValue(category: 'Enterprise', value: 2600),
    ],
  ),
  FluentFunnelDataPoint(
    stage: 'Activated',
    subValues: [
      FluentFunnelSubValue(category: 'Business', value: 3000),
      FluentFunnelSubValue(category: 'Enterprise', value: 1850),
    ],
  ),
  FluentFunnelDataPoint(
    stage: 'Invited a team',
    subValues: [
      FluentFunnelSubValue(category: 'Business', value: 1500),
      FluentFunnelSubValue(category: 'Enterprise', value: 1100),
    ],
  ),
  FluentFunnelDataPoint(
    stage: 'Added billing',
    subValues: [
      FluentFunnelSubValue(category: 'Business', value: 800),
      FluentFunnelSubValue(category: 'Enterprise', value: 650),
    ],
  ),
  FluentFunnelDataPoint(
    stage: 'Renewed',
    subValues: [
      FluentFunnelSubValue(category: 'Business', value: 520),
      FluentFunnelSubValue(category: 'Enterprise', value: 460),
    ],
  ),
];

/// Five regions, each carrying the same three workload series.
List<FluentHorizontalBarChartWithAxisDataPoint> get _regionSpend {
  const regions = [
    'North America',
    'Europe',
    'Asia Pacific',
    'South America',
    'Middle East',
  ];
  const compute = [148.0, 121.0, 96.0, 54.0, 38.0];
  const storage = [72.0, 64.0, 51.0, 29.0, 21.0];
  const network = [41.0, 33.0, 28.0, 17.0, 12.0];
  return [
    for (var index = 0; index < regions.length; index++) ...[
      FluentHorizontalBarChartWithAxisDataPoint(
        x: compute[index],
        y: regions[index],
        legend: 'Compute',
      ),
      FluentHorizontalBarChartWithAxisDataPoint(
        x: storage[index],
        y: regions[index],
        legend: 'Storage',
      ),
      FluentHorizontalBarChartWithAxisDataPoint(
        x: network[index],
        y: regions[index],
        legend: 'Network',
      ),
    ],
  ];
}

/// Six workstreams, each a span on the date axis, grouped into three phases.
final List<FluentGanttChartDataPoint> _migrationPlan = [
  FluentGanttChartDataPoint(
    x: FluentGanttSpan(start: DateTime.utc(2025), end: DateTime.utc(2025, 3)),
    y: 'Discovery',
    legend: 'Plan',
  ),
  FluentGanttChartDataPoint(
    x: FluentGanttSpan(
      start: DateTime.utc(2025, 2, 15),
      end: DateTime.utc(2025, 5),
    ),
    y: 'Data model',
    legend: 'Plan',
  ),
  FluentGanttChartDataPoint(
    x: FluentGanttSpan(
      start: DateTime.utc(2025, 4),
      end: DateTime.utc(2025, 8, 15),
    ),
    y: 'Service port',
    legend: 'Build',
  ),
  FluentGanttChartDataPoint(
    x: FluentGanttSpan(
      start: DateTime.utc(2025, 6),
      end: DateTime.utc(2025, 9),
    ),
    y: 'Integration',
    legend: 'Build',
  ),
  FluentGanttChartDataPoint(
    x: FluentGanttSpan(
      start: DateTime.utc(2025, 8),
      end: DateTime.utc(2025, 11),
    ),
    y: 'Private beta',
    legend: 'Ship',
  ),
  FluentGanttChartDataPoint(
    x: FluentGanttSpan(
      start: DateTime.utc(2025, 10, 15),
      end: DateTime.utc(2026),
    ),
    y: 'Cutover',
    legend: 'Ship',
  ),
];

/// Three polar series over eight axes: two filled regions and one stroked
/// outline.
const List<FluentPolarSeries> _capabilityScores = [
  FluentAreaPolarSeries(
    legend: 'Our platform',
    data: [
      FluentPolarDataPoint(r: 88, theta: 'Identity'),
      FluentPolarDataPoint(r: 74, theta: 'Storage'),
      FluentPolarDataPoint(r: 91, theta: 'Compute'),
      FluentPolarDataPoint(r: 66, theta: 'Analytics'),
      FluentPolarDataPoint(r: 79, theta: 'Networking'),
      FluentPolarDataPoint(r: 58, theta: 'Machine learning'),
      FluentPolarDataPoint(r: 83, theta: 'Security'),
      FluentPolarDataPoint(r: 70, theta: 'Support'),
    ],
  ),
  FluentAreaPolarSeries(
    legend: 'Nearest rival',
    data: [
      FluentPolarDataPoint(r: 72, theta: 'Identity'),
      FluentPolarDataPoint(r: 86, theta: 'Storage'),
      FluentPolarDataPoint(r: 68, theta: 'Compute'),
      FluentPolarDataPoint(r: 81, theta: 'Analytics'),
      FluentPolarDataPoint(r: 61, theta: 'Networking'),
      FluentPolarDataPoint(r: 77, theta: 'Machine learning'),
      FluentPolarDataPoint(r: 64, theta: 'Security'),
      FluentPolarDataPoint(r: 55, theta: 'Support'),
    ],
  ),
  FluentLinePolarSeries(
    legend: 'Market median',
    lineOptions: FluentLineOptions(strokeWidth: 2, strokeDasharray: '6 4'),
    data: [
      FluentPolarDataPoint(r: 60, theta: 'Identity'),
      FluentPolarDataPoint(r: 60, theta: 'Storage'),
      FluentPolarDataPoint(r: 60, theta: 'Compute'),
      FluentPolarDataPoint(r: 60, theta: 'Analytics'),
      FluentPolarDataPoint(r: 60, theta: 'Networking'),
      FluentPolarDataPoint(r: 60, theta: 'Machine learning'),
      FluentPolarDataPoint(r: 60, theta: 'Security'),
      FluentPolarDataPoint(r: 60, theta: 'Support'),
    ],
  ),
];

/// Fourteen service names: more rows than a 520-wide strip can hold, which is
/// what the overflow rail is demonstrating.
const List<String> _serviceNames = [
  'api gateway',
  'identity',
  'search',
  'media',
  'billing',
  'notifications',
  'analytics',
  'workflows',
  'storage',
  'scheduler',
  'audit log',
  'feature flags',
  'telemetry',
  'support desk',
];

/// [_serviceNames] as legend rows, each taking the next palette entry.
List<FluentChartLegendItem> get _serviceLegends => [
  for (final (index, name) in _serviceNames.indexed)
    FluentChartLegendItem(title: name, color: FluentDataVizPalette.next(index)),
];
