// `src/charts/area_chart.dart` is not in `lib/fluent_2_web.dart` yet — that
// file is owned by the integration task — so this test deep-imports the widget
// exactly as `test/charts/area_chart_test.dart` already does.
import 'package:fluent_2_web/src/charts/area_chart.dart';
import 'package:fluent_2_web/src/charts/model/cartesian_series.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Cell 1: three stacked layers, the `tonexty` default.
/// Cell 2: the same data flattened onto zero, where the layers overlap and the
/// whole-layer opacity drops to 0.8.
/// Cell 3: the gradient fill, which fades each body to transparent downwards.
/// Cell 4: one series of one point, the branch that paints a circle instead of
/// a path.
void main() {
  Widget cell(Widget chart) => SizedBox(
    // 260x180 is a cell size, not a ported constant: four of them plus the
    // 16px gaps and the harness margin fit the 1200x900 surface.
    width: 260,
    height: 180,
    child: chart,
  );

  FluentLineChartSeries series(String legend, List<double> ys) =>
      FluentLineChartSeries(
        legend: legend,
        data: <Object>[
          for (var i = 0; i < ys.length; i++)
            FluentLineChartDataPoint(x: i + 1, y: ys[i]),
        ],
      );

  final stacked = FluentChartData(
    lineChartData: <FluentLineChartSeries>[
      series('first', <double>[10, 30, 20, 40]),
      series('second', <double>[20, 10, 30, 15]),
      series('third', <double>[5, 25, 10, 30]),
    ],
  );

  goldenGridTest(
    'charts_area',
    () => goldenGrid(<Widget>[
      cell(FluentAreaChart(data: stacked)),
      cell(FluentAreaChart(data: stacked, mode: FluentAreaChartMode.toZeroY)),
      cell(FluentAreaChart(data: stacked, enableGradient: true)),
      cell(
        FluentAreaChart(
          data: FluentChartData(
            lineChartData: <FluentLineChartSeries>[
              series('only', <double>[20]),
            ],
          ),
        ),
      ),
    ]),
  );
}
