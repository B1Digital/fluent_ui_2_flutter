// `src/charts/horizontal_bar_chart_with_axis.dart` is not in
// `lib/fluent_2_web.dart` yet — that file is owned by the integration task —
// so this test deep-imports the widget exactly as
// `test/charts/horizontal_bar_chart_with_axis_test.dart` already does.
import 'package:fluent_2_web/src/charts/horizontal_bar_chart_with_axis.dart';
import 'package:fluent_2_web/src/charts/model/bar_data.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Cell 1: four string categories, one bar each, with the group total label
/// clear of every bar end and a legend row underneath.
/// Cell 2: one category stacking three segments, so the 2px inter-segment gaps
/// and the single label on the group's last positive bar are both visible.
/// Cell 3: a negative-and-positive dataset, whose bars grow both ways from the
/// zero origin and whose label sits before the last negative bar.
/// Cell 4: a numeric y axis with rounded corners, where the bar height comes
/// from the auto solve rather than a band.
///
/// The high-contrast image is the acceptance evidence for design spec section
/// 5.3: every bar fill flattens to the system colour while the legend keeps its
/// palette.
void main() {
  Widget cell(Widget chart) => SizedBox(
    // 260x180 is a cell size, not a ported constant: four of them plus the
    // 16px gaps and the harness margin fit the 1200x900 surface.
    width: 260,
    height: 180,
    child: chart,
  );

  goldenGridTest(
    'charts_horizontal_bar_axis',
    () => goldenGrid(<Widget>[
      cell(
        const FluentHorizontalBarChartWithAxis(
          data: <FluentHorizontalBarChartWithAxisDataPoint>[
            FluentHorizontalBarChartWithAxisDataPoint(
              x: 45,
              y: 'One',
              legend: 'Sales',
            ),
            FluentHorizontalBarChartWithAxisDataPoint(
              x: 30,
              y: 'Two',
              legend: 'Sales',
            ),
            FluentHorizontalBarChartWithAxisDataPoint(
              x: 60,
              y: 'Three',
              legend: 'Sales',
            ),
            FluentHorizontalBarChartWithAxisDataPoint(
              x: 20,
              y: 'Four',
              legend: 'Sales',
            ),
          ],
        ),
      ),
      cell(
        const FluentHorizontalBarChartWithAxis(
          data: <FluentHorizontalBarChartWithAxisDataPoint>[
            FluentHorizontalBarChartWithAxisDataPoint(
              x: 20,
              y: 'Stacked',
              legend: 'First',
            ),
            FluentHorizontalBarChartWithAxisDataPoint(
              x: 15,
              y: 'Stacked',
              legend: 'Second',
            ),
            FluentHorizontalBarChartWithAxisDataPoint(
              x: 25,
              y: 'Stacked',
              legend: 'Third',
            ),
          ],
        ),
      ),
      cell(
        const FluentHorizontalBarChartWithAxis(
          data: <FluentHorizontalBarChartWithAxisDataPoint>[
            FluentHorizontalBarChartWithAxisDataPoint(
              x: 30,
              y: 'Gain',
              legend: 'Up',
            ),
            FluentHorizontalBarChartWithAxisDataPoint(
              x: -20,
              y: 'Gain',
              legend: 'Down',
            ),
            FluentHorizontalBarChartWithAxisDataPoint(
              x: -40,
              y: 'Loss',
              legend: 'Down',
            ),
            FluentHorizontalBarChartWithAxisDataPoint(
              x: 10,
              y: 'Loss',
              legend: 'Up',
            ),
          ],
        ),
      ),
      cell(
        const FluentHorizontalBarChartWithAxis(
          roundCorners: true,
          data: <FluentHorizontalBarChartWithAxisDataPoint>[
            FluentHorizontalBarChartWithAxisDataPoint(
              x: 40,
              y: 10,
              legend: 'Numeric',
            ),
            FluentHorizontalBarChartWithAxisDataPoint(
              x: 25,
              y: 20,
              legend: 'Numeric',
            ),
            FluentHorizontalBarChartWithAxisDataPoint(
              x: 55,
              y: 30,
              legend: 'Numeric',
            ),
          ],
        ),
      ),
    ]),
  );
}
