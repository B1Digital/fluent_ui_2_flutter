// `src/charts/vertical_stacked_bar_chart.dart` is not in `lib/fluent_2_web.dart`
// yet — that file is owned by the integration task — so this test deep-imports
// the widget exactly as `test/charts/vertical_stacked_bar_chart_test.dart` does.
import 'package:fluent_2_web/src/charts/model/bar_data.dart';
import 'package:fluent_2_web/src/charts/vertical_stacked_bar_chart.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Cell 1: three stacks on the deterministic five-token palette, the colour
/// rule that replaces upstream's `Math.random` pick at
/// `VerticalStackedBarChart.tsx:167`.
/// Cell 2: gaps plus a rounded top, the six-verb arc path at `.tsx:1092-1098`.
/// Cell 3: the line overlay's legend, which is appended AFTER the bar legends
/// (`.tsx:207`) — the reverse of GroupedVerticalBarChart. Only the legend is
/// under test here: the delegate paints the bars, and the line polyline it
/// already solves has no painter yet.
/// Cell 4: per-datum colours with a wider bar, the `point.color` arm that
/// bypasses the palette entirely.
void main() {
  Widget cell(Widget chart) => SizedBox(
    // 260x180 is a cell size, not a ported constant: four of them plus the
    // 16px gaps and the harness margin fit the 1200x900 surface.
    width: 260,
    height: 180,
    child: chart,
  );

  List<FluentVerticalStackedBarGroup> stacks() =>
      <FluentVerticalStackedBarGroup>[
        for (final (i, label) in <String>['a', 'b', 'c'].indexed)
          FluentVerticalStackedBarGroup(
            xAxisPoint: label,
            chartData: <FluentStackedBarDatum>[
              FluentStackedBarDatum(data: 10.0 + i, legend: 'Alpha'),
              FluentStackedBarDatum(data: 20.0 - i, legend: 'Beta'),
              FluentStackedBarDatum(data: 8.0 + 2 * i, legend: 'Gamma'),
            ],
          ),
      ];

  final withLine = <FluentVerticalStackedBarGroup>[
    for (final (i, label) in <String>['a', 'b', 'c'].indexed)
      FluentVerticalStackedBarGroup(
        xAxisPoint: label,
        chartData: <FluentStackedBarDatum>[
          FluentStackedBarDatum(data: 10.0 + 4 * i, legend: 'Alpha'),
        ],
        lineData: <FluentStackedBarLineDatum>[
          FluentStackedBarLineDatum(
            y: 30.0 + 4 * i,
            color: const Color(0xFF6E3FCF),
            legend: 'Trend',
          ),
        ],
      ),
  ];

  final coloured = <FluentVerticalStackedBarGroup>[
    for (final (i, label) in <String>['a', 'b', 'c'].indexed)
      FluentVerticalStackedBarGroup(
        xAxisPoint: label,
        chartData: <FluentStackedBarDatum>[
          FluentStackedBarDatum(
            data: 14.0 + i,
            legend: 'Alpha',
            color: const Color(0xFF0F6CBD),
          ),
          FluentStackedBarDatum(
            data: 9.0 + 2 * i,
            legend: 'Beta',
            color: const Color(0xFFE3008C),
          ),
        ],
      ),
  ];

  goldenGridTest(
    'charts_vertical_stacked_bar',
    () => goldenGrid(<Widget>[
      cell(FluentVerticalStackedBarChart(data: stacks())),
      cell(
        FluentVerticalStackedBarChart(
          data: stacks(),
          barGapMax: 2,
          barCornerRadius: 3,
          roundCorners: true,
        ),
      ),
      cell(FluentVerticalStackedBarChart(data: withLine)),
      cell(FluentVerticalStackedBarChart(data: coloured, maxBarWidth: 40)),
    ]),
  );
}
