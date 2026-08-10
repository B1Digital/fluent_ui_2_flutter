import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Row 1: a circular grid and a polygon grid, both counter-clockwise. Row 2: the same
/// data clockwise, and a doughnut variant with `hole: 0.4`. Every cell hides the legend
/// so the image is grid, series and ticks only.
void main() {
  const data = <FluentPolarSeries>[
    FluentAreaPolarSeries(
      legend: 'Area',
      data: <FluentPolarDataPoint>[
        FluentPolarDataPoint(r: 40, theta: 0),
        FluentPolarDataPoint(r: 90, theta: 72),
        FluentPolarDataPoint(r: 55, theta: 144),
        FluentPolarDataPoint(r: 80, theta: 216),
        FluentPolarDataPoint(r: 35, theta: 288),
      ],
    ),
    FluentScatterPolarSeries(
      legend: 'Scatter',
      data: <FluentPolarDataPoint>[
        FluentPolarDataPoint(r: 20, theta: 30, markerSize: 2),
        FluentPolarDataPoint(r: 70, theta: 150, markerSize: 8),
        FluentPolarDataPoint(r: 100, theta: 270, markerSize: 14),
      ],
    ),
  ];

  Widget cell({
    FluentPolarShape shape = FluentPolarShape.circle,
    FluentPolarDirection direction = FluentPolarDirection.counterclockwise,
    double hole = 0,
  }) => SizedBox(
    width: 260,
    height: 260,
    child: FluentPolarChart(
      data: data,
      shape: shape,
      direction: direction,
      hole: hole,
      hideLegend: true,
    ),
  );

  goldenGridTest(
    'polar_chart',
    () => goldenGrid(<Widget>[
      cell(),
      cell(shape: FluentPolarShape.polygon),
      cell(direction: FluentPolarDirection.clockwise),
      cell(hole: 0.4),
    ], columns: 2),
    surfaceSize: const Size(600, 600),
  );
}
