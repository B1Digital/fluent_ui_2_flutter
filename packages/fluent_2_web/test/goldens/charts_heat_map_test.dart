// The `src/charts/heat_map_chart.dart` barrel line is not in
// `lib/fluent_2_web.dart` yet — that file is owned by the integration tasks —
// so this test deep-imports the chart exactly as
// `test/goldens/cartesian_chart_golden_test.dart` deep-imports the shell.
import 'package:fluent_2_web/src/charts/heat_map_chart.dart';
import 'package:fluent_2_web/src/charts/model/heatmap_data.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Cell 1: the plain grid with its legend row.
/// Cell 2: the same grid with a hole, so a transparent placeholder is captured
/// next to a painted cell.
/// Cell 3: right-to-left, where the band x range is reversed by
/// `domainRangeOfXStringAxis` rather than the domain.
///
/// The high-contrast image is the acceptance evidence for spec section 5.3:
/// every cell fill collapses to the system foreground while the legend keeps
/// its ramp colours.
void main() {
  /// A five-by-three grid whose values climb left to right, so the ramp is
  /// visible across a row and the contrast flip fires on the dark end.
  List<FluentHeatMapChartData> data({bool withHole = false}) =>
      <FluentHeatMapChartData>[
        FluentHeatMapChartData(
          legend: 'Load',
          // The series value picks the legend swatch off the same ramp
          // (`HeatMapChart.tsx:334`); the midpoint keeps it distinguishable
          // from either end.
          value: 70,
          data: <FluentHeatMapChartDataPoint>[
            for (var row = 0; row < 3; row++)
              for (var column = 0; column < 5; column++)
                if (!withHole || row != 1 || column != 2)
                  FluentHeatMapChartDataPoint(
                    x: 'c$column',
                    y: 'r$row',
                    value: (row * 5 + column) * 10,
                  ),
          ],
        ),
      ];

  Widget cell({
    bool withHole = false,
    TextDirection direction = TextDirection.ltr,
  }) => Directionality(
    textDirection: direction,
    child: SizedBox(
      // 370x260 is a cell size, not a ported constant: three of them plus the
      // 16px grid gaps fit inside the 1200x900 surface with room for the
      // legend row.
      width: 370,
      height: 260,
      child: FluentHeatMapChart(
        data: data(withHole: withHole),
        // A two-stop ramp from the Fluent brand primary to near-white, so the
        // captured colours are fixed literals rather than palette indices that
        // could be renumbered.
        domainValuesForColorScale: const <double>[0, 140],
        rangeValuesForColorScale: const <Color>[
          Color(0xFF0078D4),
          Color(0xFFF3F9FD),
        ],
      ),
    ),
  );

  goldenGridTest(
    'charts_heat_map',
    () => goldenGrid(<Widget>[
      cell(),
      cell(withHole: true),
      cell(direction: TextDirection.rtl),
    ], columns: 3),
  );
}
