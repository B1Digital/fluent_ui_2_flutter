import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Cell 1: three legends over three categories, the default 24px bars with
/// their per-column total labels.
/// Cell 2: the same data with rounded corners and the labels suppressed.
/// Cell 3: a category whose legend repeats, which stacks inside the group, plus
/// a negative column.
/// Cell 4: the v2 input — two bar series with a line series drawn over them,
/// haloed and dotted.
void main() {
  Widget cell(Widget chart) => SizedBox(
    // 260x180 is a cell size, not a ported constant: four of them plus the
    // 16px gaps and the harness margin fit the 1200x900 surface.
    width: 260,
    height: 180,
    child: chart,
  );

  const grouped = <FluentGroupedVerticalBarChartData>[
    FluentGroupedVerticalBarChartData(
      name: 'Q1',
      series: <FluentGroupedBarSeriesPoint>[
        FluentGroupedBarSeriesPoint(key: 'a', data: 33, legend: 'Alpha'),
        FluentGroupedBarSeriesPoint(key: 'b', data: 44, legend: 'Beta'),
        FluentGroupedBarSeriesPoint(key: 'c', data: 24, legend: 'Gamma'),
      ],
    ),
    FluentGroupedVerticalBarChartData(
      name: 'Q2',
      series: <FluentGroupedBarSeriesPoint>[
        FluentGroupedBarSeriesPoint(key: 'a', data: 14, legend: 'Alpha'),
        FluentGroupedBarSeriesPoint(key: 'b', data: 50, legend: 'Beta'),
        FluentGroupedBarSeriesPoint(key: 'c', data: 10, legend: 'Gamma'),
      ],
    ),
    FluentGroupedVerticalBarChartData(
      name: 'Q3',
      series: <FluentGroupedBarSeriesPoint>[
        FluentGroupedBarSeriesPoint(key: 'a', data: 30, legend: 'Alpha'),
        FluentGroupedBarSeriesPoint(key: 'b', data: 15, legend: 'Beta'),
        FluentGroupedBarSeriesPoint(key: 'c', data: 40, legend: 'Gamma'),
      ],
    ),
  ];

  goldenGridTest(
    'charts_grouped_vertical_bar',
    () => goldenGrid(<Widget>[
      cell(const FluentGroupedVerticalBarChart(data: grouped)),
      cell(
        const FluentGroupedVerticalBarChart(
          data: grouped,
          roundCorners: true,
          hideLabels: true,
        ),
      ),
      cell(
        const FluentGroupedVerticalBarChart(
          data: <FluentGroupedVerticalBarChartData>[
            FluentGroupedVerticalBarChartData(
              name: 'Q1',
              series: <FluentGroupedBarSeriesPoint>[
                FluentGroupedBarSeriesPoint(
                  key: 'a',
                  data: 20,
                  legend: 'Alpha',
                ),
                FluentGroupedBarSeriesPoint(
                  key: 'a',
                  data: 30,
                  legend: 'Alpha',
                ),
                FluentGroupedBarSeriesPoint(key: 'b', data: 25, legend: 'Beta'),
              ],
            ),
            FluentGroupedVerticalBarChartData(
              name: 'Q2',
              series: <FluentGroupedBarSeriesPoint>[
                FluentGroupedBarSeriesPoint(
                  key: 'a',
                  data: -18,
                  legend: 'Alpha',
                ),
                FluentGroupedBarSeriesPoint(key: 'b', data: 35, legend: 'Beta'),
              ],
            ),
          ],
        ),
      ),
      cell(
        const FluentGroupedVerticalBarChart(
          dataV2: <FluentDataSeries>[
            FluentBarSeries(
              legend: 'Alpha',
              data: <FluentDataPointV2>[
                FluentDataPointV2(x: 'Q1', y: 33),
                FluentDataPointV2(x: 'Q2', y: 14),
                FluentDataPointV2(x: 'Q3', y: 30),
              ],
            ),
            FluentBarSeries(
              legend: 'Beta',
              data: <FluentDataPointV2>[
                FluentDataPointV2(x: 'Q1', y: 44),
                FluentDataPointV2(x: 'Q2', y: 50),
                FluentDataPointV2(x: 'Q3', y: 15),
              ],
            ),
            FluentLineSeries(
              legend: 'Trend',
              lineOptions: FluentLineOptions(lineBorderWidth: 2),
              data: <FluentDataPointV2>[
                FluentDataPointV2(x: 'Q1', y: 20),
                FluentDataPointV2(x: 'Q2', y: 45),
                FluentDataPointV2(x: 'Q3', y: 25),
              ],
            ),
          ],
        ),
      ),
    ]),
  );
}
