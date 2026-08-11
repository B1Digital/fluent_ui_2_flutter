import 'package:fluent_2_web/src/charts/vega_declarative_chart.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// One image per theme, holding four variants in a fixed order:
///   row 1  single bar
///   row 2  single line
///   row 3  an `hconcat` pair under one shared, lifted legend
///   row 4  heatmap
///
/// Cells are unlabelled — see `test/goldens/README.md`. As with the Plotly
/// gallery, no row names a chart type: each is a Vega-Lite specification the
/// routing ladder decides for itself, so a mis-route changes a whole row.
void main() {
  /// 520x400 per cell, matching the Plotly gallery and the storybook
  /// (`example/lib/storybook/components/charts_stories.dart:1005-1008`): the
  /// stacked-bar row needs all 400, because its cells declare 300 and the
  /// lifted legend takes the rest.
  Widget cell(Map<String, Object?> spec) => SizedBox(
    width: 520,
    height: 400,
    child: FluentVegaDeclarativeChart(
      chartSchema: FluentVegaSchema(vegaLiteSpec: spec),
    ),
  );

  const bars = <Object?>[
    <String, Object?>{'category': 'A', 'amount': 28},
    <String, Object?>{'category': 'B', 'amount': 55},
    <String, Object?>{'category': 'C', 'amount': 43},
  ];

  goldenGridTest(
    'vega_declarative_chart',
    () => goldenGrid(<Widget>[
      // No colour channel, so the bar ladder stops at the plain vertical bar.
      cell(const <String, Object?>{
        'mark': 'bar',
        'data': <String, Object?>{'values': bars},
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'category', 'type': 'nominal'},
          'y': <String, Object?>{'field': 'amount', 'type': 'quantitative'},
        },
      }),
      // A `line` mark, and the default arm of the ladder besides.
      cell(const <String, Object?>{
        'mark': 'line',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'t': 1, 'v': 12},
            <String, Object?>{'t': 2, 'v': 19},
            <String, Object?>{'t': 3, 'v': 14},
            <String, Object?>{'t': 4, 'v': 22},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 't', 'type': 'quantitative'},
          'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
        },
      }),
      // Two cells sharing the parent's data, encoding and colour scale. The
      // colour channel routes both to the stacked bar, whose chart-owned
      // legend is suppressed so the widget can draw one lifted legend for the
      // pair. 300 is the declared cell height: the 350 default plus the legend
      // row would not fit the 400-tall cell.
      cell(const <String, Object?>{
        'height': 300,
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'c': 'a', 'v': 12, 'g': 'p'},
            <String, Object?>{'c': 'a', 'v': 16, 'g': 'q'},
            <String, Object?>{'c': 'b', 'v': 30, 'g': 'p'},
            <String, Object?>{'c': 'b', 'v': 25, 'g': 'q'},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
          'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
          'color': <String, Object?>{'field': 'g', 'type': 'nominal'},
        },
        'hconcat': <Object?>[
          <String, Object?>{'mark': 'bar'},
          <String, Object?>{'mark': 'bar'},
        ],
      }),
      // A `rect` mark with x, y and a quantitative colour: the heatmap arm,
      // the one kind whose transformer hard-codes `hideLegend`.
      cell(const <String, Object?>{
        'height': 300,
        'mark': 'rect',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'x': 'a', 'y': 'p', 'v': 0},
            <String, Object?>{'x': 'a', 'y': 'q', 'v': 4},
            <String, Object?>{'x': 'b', 'y': 'p', 'v': 6},
            <String, Object?>{'x': 'b', 'y': 'q', 'v': 8},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'x', 'type': 'nominal'},
          'y': <String, Object?>{'field': 'y', 'type': 'nominal'},
          'color': <String, Object?>{'field': 'v', 'type': 'quantitative'},
        },
      }),
    ], columns: 1),
    // Four 400-tall rows, three 16px gaps and the harness's 16px margin.
    surfaceSize: const Size(1200, 1700),
  );
}
