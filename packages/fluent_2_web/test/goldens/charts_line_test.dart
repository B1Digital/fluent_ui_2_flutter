// `src/charts/line_chart.dart` is not in `lib/fluent_2_web.dart` yet — that
// file is owned by the integration task — so this test deep-imports the widget
// exactly as `test/charts/line_chart_test.dart` already does.
import 'package:fluent_2_web/src/charts/line_chart.dart';
import 'package:fluent_2_web/src/charts/model/cartesian_series.dart';
import 'package:fluent_2_web/src/charts/model/chart_annotation.dart';
import 'package:fluent_2_web/src/charts/model/line_options.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Cell 1: two plain lines, the engine-A default.
/// Cell 2: a dashed line over a halo — the border stroke shows through the
/// gaps, which is the one place `flattenMarkStroke` is visible in high
/// contrast.
/// Cell 3: a date axis carrying three event annotations, two of which collapse
/// into the merged label.
/// Cell 4: a run of gaps, where the segments inside the gap are simply absent.
void main() {
  Widget cell(Widget chart) => SizedBox(
    // 260x180 is a cell size, not a ported constant: four of them plus the
    // 16px gaps and the harness margin fit the 1200x900 surface.
    width: 260,
    height: 180,
    child: chart,
  );

  FluentLineChartSeries series(
    String legend,
    List<double> ys, {
    FluentLineOptions? lineOptions,
    List<FluentLineChartGap>? gaps,
  }) => FluentLineChartSeries(
    legend: legend,
    lineOptions: lineOptions,
    gaps: gaps,
    data: <Object>[
      for (var i = 0; i < ys.length; i++)
        FluentLineChartDataPoint(x: i + 1, y: ys[i]),
    ],
  );

  final plain = FluentChartData(
    lineChartData: <FluentLineChartSeries>[
      series('first', <double>[10, 30, 20, 40]),
      series('second', <double>[20, 10, 30, 15]),
    ],
  );

  final dated = FluentChartData(
    lineChartData: <FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'sessions',
        data: <Object>[
          for (var day = 10; day <= 20; day += 2)
            FluentLineChartDataPoint(x: DateTime.utc(2024, 3, day), y: day * 2),
        ],
      ),
    ],
  );

  goldenGridTest(
    'charts_line',
    () => goldenGrid(<Widget>[
      cell(FluentLineChart(data: plain)),
      cell(
        FluentLineChart(
          data: FluentChartData(
            lineChartData: <FluentLineChartSeries>[
              series(
                'dashed',
                <double>[10, 30, 20, 40],
                lineOptions: const FluentLineOptions(
                  strokeDasharray: '6',
                  lineBorderWidth: 4,
                ),
              ),
            ],
          ),
        ),
      ),
      cell(
        FluentLineChart(
          data: dated,
          eventAnnotationMergedLabel: (count) => '$count events',
          eventAnnotations: <FluentEventAnnotation>[
            FluentEventAnnotation(
              date: DateTime.utc(2024, 3, 12),
              event: 'ship',
            ),
            FluentEventAnnotation(
              date: DateTime.utc(2024, 3, 13),
              event: 'rollback',
            ),
            FluentEventAnnotation(
              date: DateTime.utc(2024, 3, 18),
              event: 'reship',
            ),
          ],
        ),
      ),
      cell(
        FluentLineChart(
          data: FluentChartData(
            lineChartData: <FluentLineChartSeries>[
              series(
                'gapped',
                <double>[10, 30, 20, 40, 25, 35],
                gaps: const <FluentLineChartGap>[
                  FluentLineChartGap(startIndex: 1, endIndex: 3),
                ],
              ),
            ],
          ),
        ),
      ),
    ]),
  );
}
