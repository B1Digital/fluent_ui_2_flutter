import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// One row of three ScatterChart cells.
///
/// 1. A numeric-x, numeric-y chart with two series and per-point marker sizes,
///    which is the only cell where `calculateMarkerRadius`'s continuous branch
///    (`utilities.ts:2349`) is visible.
/// 2. A category x axis, which shifts every centre by half a bandwidth and
///    swaps the radius branch to the normalised `[4, 16]` one.
/// 3. Point labels plus a hidden legend, so the label baseline drop of
///    `max(r + 12, 16)` (`ScatterChart.tsx:484`) is what the diff reads.
///
/// High contrast is load-bearing rather than decorative: a marker fill collapses
/// to canvasText and its halo to canvas in forced colours (design spec section
/// 5.3), so the high-contrast image is the only place a mark that forgot
/// `FluentChartColors.flattenMark` or `flattenMarkStroke` shows up.
void main() {
  Widget cell(Widget child) =>
      // 320x200 is a cell size, not a ported constant: three of them plus the
      // 16px grid gaps fit the 1080x320 surface below.
      SizedBox(width: 320, height: 200, child: child);

  const numeric = FluentChartData(
    chartTitle: 'Spend against reach',
    scatterChartData: <FluentScatterChartSeries>[
      FluentScatterChartSeries(
        legend: 'Store B',
        // The Fluent data-viz teal and purple, so the marks are fixed colours
        // rather than palette indices that could be renumbered under the grid.
        color: Color(0xFF2AA0A4),
        data: <FluentScatterChartDataPoint>[
          FluentScatterChartDataPoint(x: 10, y: 30, markerSize: 4),
          FluentScatterChartDataPoint(x: 20, y: 55, markerSize: 10),
          FluentScatterChartDataPoint(x: 35, y: 20, markerSize: 16),
          FluentScatterChartDataPoint(x: 50, y: 45, markerSize: 8),
        ],
      ),
      FluentScatterChartSeries(
        legend: 'Store A',
        color: Color(0xFF9373C0),
        data: <FluentScatterChartDataPoint>[
          FluentScatterChartDataPoint(x: 15, y: 15, markerSize: 12),
          FluentScatterChartDataPoint(x: 30, y: 40, markerSize: 6),
          FluentScatterChartDataPoint(x: 45, y: 60, markerSize: 14),
        ],
      ),
    ],
  );

  const category = FluentChartData(
    scatterChartData: <FluentScatterChartSeries>[
      FluentScatterChartSeries(
        legend: 'Store B',
        color: Color(0xFF2AA0A4),
        data: <FluentScatterChartDataPoint>[
          FluentScatterChartDataPoint(x: 'Toys', y: 50, markerSize: 2),
          FluentScatterChartDataPoint(x: 'Books', y: 30, markerSize: 8),
          FluentScatterChartDataPoint(x: 'Games', y: 20, markerSize: 13),
        ],
      ),
    ],
  );

  const labelled = FluentChartData(
    scatterChartData: <FluentScatterChartSeries>[
      FluentScatterChartSeries(
        legend: 'Store B',
        color: Color(0xFF2AA0A4),
        data: <FluentScatterChartDataPoint>[
          FluentScatterChartDataPoint(x: 10, y: 20, text: 'A'),
          FluentScatterChartDataPoint(x: 30, y: 50, text: 'B'),
          FluentScatterChartDataPoint(x: 50, y: 35, text: 'C'),
        ],
      ),
    ],
  );

  goldenGridTest(
    'charts_scatter',
    () => goldenGrid(<Widget>[
      cell(const FluentScatterChart(data: numeric)),
      cell(const FluentScatterChart(data: category)),
      cell(
        const FluentScatterChart(
          data: labelled,
          props: FluentCartesianChartProps(hideLegend: true),
        ),
      ),
    ], columns: 3),
    surfaceSize: const Size(1080, 320),
  );
}
