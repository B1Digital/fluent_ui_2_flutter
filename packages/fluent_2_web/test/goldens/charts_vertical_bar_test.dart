// `src/charts/vertical_bar_chart.dart` is not in `lib/fluent_2_web.dart` yet —
// that file is owned by the integration task — so this test deep-imports the
// widget exactly as `test/charts/vertical_bar_chart_test.dart` already does.
import 'package:fluent_2_web/src/charts/model/bar_data.dart';
import 'package:fluent_2_web/src/charts/vertical_bar_chart.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Cell 1: the default ramp, one colour per bar interpolated from its y.
/// Cell 2: `useSingleColor` with rounded corners, the `rx = 3` branch.
/// Cell 3: the overlaid line with its own legend, which leads the legend row.
/// Cell 4: a dataset straddling zero, where the negative bars hang below the
/// baseline and their labels sit under the foot rather than over the top.
void main() {
  Widget cell(Widget chart) => SizedBox(
    // 260x180 is a cell size, not a ported constant: four of them plus the
    // 16px gaps and the harness margin fit the 1200x900 surface.
    width: 260,
    height: 180,
    child: chart,
  );

  const bars = <FluentVerticalBarChartDataPoint>[
    FluentVerticalBarChartDataPoint(x: 'a', y: 10, legend: 'Alpha'),
    FluentVerticalBarChartDataPoint(x: 'b', y: 40, legend: 'Beta'),
    FluentVerticalBarChartDataPoint(x: 'c', y: 25, legend: 'Gamma'),
    FluentVerticalBarChartDataPoint(x: 'd', y: 35, legend: 'Delta'),
  ];

  const withLine = <FluentVerticalBarChartDataPoint>[
    FluentVerticalBarChartDataPoint(
      x: 'a',
      y: 10,
      legend: 'Alpha',
      lineData: FluentBarLineDatum(y: 8),
    ),
    FluentVerticalBarChartDataPoint(
      x: 'b',
      y: 40,
      legend: 'Beta',
      lineData: FluentBarLineDatum(y: 30),
    ),
    FluentVerticalBarChartDataPoint(
      x: 'c',
      y: 25,
      legend: 'Gamma',
      lineData: FluentBarLineDatum(y: 20),
    ),
  ];

  const straddlingZero = <FluentVerticalBarChartDataPoint>[
    FluentVerticalBarChartDataPoint(x: 'a', y: 20, legend: 'Alpha'),
    FluentVerticalBarChartDataPoint(x: 'b', y: -15, legend: 'Beta'),
    FluentVerticalBarChartDataPoint(x: 'c', y: 30, legend: 'Gamma'),
    FluentVerticalBarChartDataPoint(x: 'd', y: -25, legend: 'Delta'),
  ];

  goldenGridTest(
    'charts_vertical_bar',
    () => goldenGrid(<Widget>[
      cell(const FluentVerticalBarChart(data: bars)),
      cell(
        const FluentVerticalBarChart(
          data: bars,
          useSingleColor: true,
          roundCorners: true,
        ),
      ),
      cell(
        const FluentVerticalBarChart(data: withLine, lineLegendText: 'Trend'),
      ),
      cell(const FluentVerticalBarChart(data: straddlingZero)),
    ]),
  );
}
