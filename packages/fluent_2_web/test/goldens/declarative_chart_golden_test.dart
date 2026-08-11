import 'package:fluent_2_web/src/charts/declarative_chart.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// One image per theme, holding four variants in a fixed order:
///   row 1  single-plot vertical stacked bar
///   row 2  single-plot line
///   row 3  single-plot donut
///   row 4  two-cell multi-plot with its all-up legend
///
/// Cells are unlabelled — see `test/goldens/README.md`. The point of the net is
/// that nothing here names a chart type: every row is a Plotly figure that
/// `mapFluentChart` routes on its own, so a routing change that sends a figure
/// to the wrong widget shows up as a whole row changing shape.
void main() {
  /// 520x400 per cell, the storybook's own figure
  /// (`example/lib/storybook/components/charts_stories.dart:975-978`): 400 is
  /// the tallest intrinsic height either adapter asks for — a routed cell plus
  /// its own legend strip. The plan proposed 200, which overflows all four
  /// rows (by 150, 150, 76 and 198 pixels respectively); see the report.
  Widget cell(Map<String, Object?> schema) => SizedBox(
    width: 520,
    height: 400,
    child: FluentDeclarativeChart(
      chartSchema: FluentPlotlySchema(plotlySchema: schema),
    ),
  );

  goldenGridTest(
    'declarative_chart',
    () => goldenGrid(<Widget>[
      // No `barmode`, so the bar ladder stacks.
      cell(const <String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'bar',
            'name': 'Revenue',
            'x': <Object?>['Q1', 'Q2', 'Q3'],
            'y': <Object?>[42, 55, 38],
          },
        ],
      }),
      // A numeric x with `mode: 'lines'` is a line, not a scatter.
      cell(const <String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'scatter',
            'mode': 'lines',
            'name': 'Latency',
            'x': <Object?>[1, 2, 3, 4],
            'y': <Object?>[12, 19, 14, 22],
          },
        ],
      }),
      // A `pie` with a `hole` is a donut.
      cell(const <String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'pie',
            'hole': 0.5,
            'labels': <Object?>['Alpha', 'Beta'],
            'values': <Object?>[30, 70],
          },
        ],
      }),
      // Two traces on disjoint x domains: the multi-plot grid, with one all-up
      // legend beneath both cells.
      cell(const <String, Object?>{
        'data': <Object?>[
          <String, Object?>{
            'type': 'bar',
            'xaxis': 'x',
            'name': 'Left',
            'legendgroup': 'left',
            'x': <Object?>['a'],
            'y': <Object?>[1],
          },
          <String, Object?>{
            'type': 'bar',
            'xaxis': 'x2',
            'name': 'Right',
            'legendgroup': 'right',
            'x': <Object?>['b'],
            'y': <Object?>[2],
          },
        ],
        'layout': <String, Object?>{
          'xaxis': <String, Object?>{
            'domain': <Object?>[0, 0.45],
            'anchor': 'y',
          },
          'xaxis2': <String, Object?>{
            'domain': <Object?>[0.55, 1],
            'anchor': 'y2',
          },
          'yaxis': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x',
          },
          'yaxis2': <String, Object?>{
            'domain': <Object?>[0, 1],
            'anchor': 'x2',
          },
        },
      }),
    ], columns: 1),
    // Four 400-tall rows, three 16px gaps and the harness's 16px margin.
    surfaceSize: const Size(1200, 1700),
  );
}
