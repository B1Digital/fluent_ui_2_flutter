import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Cell 1: three category rows with a legend row underneath.
/// Cell 2: the same rows with rounded corners and gradients on.
/// Cell 3: a numeric y axis, where the bar height comes from the 24px default
/// rather than a band.
/// Cell 4: a date x axis, whose ticks are formatted rather than stringified.
void main() {
  Widget cell(Widget chart) => SizedBox(
    // 260x180 is a cell size, not a ported constant: four of them plus the
    // 16px gaps and the harness margin fit the 1200x900 surface.
    width: 260,
    height: 180,
    child: chart,
  );

  const categoryData = <FluentGanttChartDataPoint>[
    FluentGanttChartDataPoint(
      x: FluentGanttSpan(start: 0, end: 40),
      y: 'Design',
      legend: 'Planned',
    ),
    FluentGanttChartDataPoint(
      x: FluentGanttSpan(start: 30, end: 80),
      y: 'Build',
      legend: 'Active',
    ),
    FluentGanttChartDataPoint(
      x: FluentGanttSpan(start: 70, end: 100),
      y: 'Ship',
      legend: 'Done',
    ),
  ];

  goldenGridTest(
    'charts_gantt',
    () => goldenGrid(<Widget>[
      cell(const FluentGanttChart(data: categoryData)),
      cell(
        const FluentGanttChart(
          data: <FluentGanttChartDataPoint>[
            FluentGanttChartDataPoint(
              x: FluentGanttSpan(start: 0, end: 40),
              y: 'Design',
              legend: 'Planned',
              gradient: (Color(0xFF0078D4), Color(0xFF50E6FF)),
            ),
            FluentGanttChartDataPoint(
              x: FluentGanttSpan(start: 30, end: 80),
              y: 'Build',
              legend: 'Active',
              gradient: (Color(0xFF107C10), Color(0xFF9FD89F)),
            ),
          ],
          enableGradient: true,
          roundCorners: true,
        ),
      ),
      cell(
        const FluentGanttChart(
          data: <FluentGanttChartDataPoint>[
            FluentGanttChartDataPoint(
              x: FluentGanttSpan(start: 0, end: 40),
              y: 0,
              legend: 'Planned',
            ),
            FluentGanttChartDataPoint(
              x: FluentGanttSpan(start: 30, end: 80),
              y: 10,
              legend: 'Active',
            ),
          ],
        ),
      ),
      cell(
        FluentGanttChart(
          data: <FluentGanttChartDataPoint>[
            FluentGanttChartDataPoint(
              x: FluentGanttSpan(
                start: DateTime.utc(2024, 3),
                end: DateTime.utc(2024, 5),
              ),
              y: 'Design',
              legend: 'Planned',
            ),
            FluentGanttChartDataPoint(
              x: FluentGanttSpan(
                start: DateTime.utc(2024, 4),
                end: DateTime.utc(2024, 7),
              ),
              y: 'Build',
              legend: 'Active',
            ),
          ],
        ),
      ),
    ]),
  );
}
