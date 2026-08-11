import 'package:fluent_2_web/src/charts/internal/plotly/router.dart';
import 'package:flutter_test/flutter_test.dart';

/// One row of the routing corpus.
typedef _Case = ({
  String name,
  Map<String, Object?> figure,
  FluentPlotlyChartKind kind,
});

void main() {
  Map<String, Object?> fig(
    List<Map<String, Object?>> data, [
    Map<String, Object?>? layout,
    // The plan writes this entry as `if (layout != null) 'layout': layout`;
    // `use_null_aware_elements` is an error under `--fatal-infos` here, so the
    // null-aware entry says the same thing.
  ]) => <String, Object?>{'data': data, 'layout': ?layout};

  const numX = <Object?>[1, 2, 3];
  const strX = <Object?>['a', 'b', 'c'];
  const dateX = <Object?>['2024-01-01', '2024-01-02', '2024-01-03'];
  const numY = <Object?>[10, 20, 30];
  const strY = <Object?>['p', 'q', 'r'];

  final cases = <_Case>[
    (
      name: 'lines over a numeric x',
      figure: fig(<Map<String, Object?>>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'x': numX,
          'y': numY,
        },
      ]),
      kind: FluentPlotlyChartKind.line,
    ),
    (
      name: 'lines over a string x fall back',
      figure: fig(<Map<String, Object?>>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'x': strX,
          'y': numY,
        },
      ]),
      kind: FluentPlotlyChartKind.fallback,
    ),
    (
      name: 'lines over a year x fall back',
      figure: fig(<Map<String, Object?>>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'x': <Object?>[1999, 2000, 2001],
          'y': numY,
        },
      ]),
      kind: FluentPlotlyChartKind.fallback,
    ),
    (
      name: 'markers over a string x stay a scatter',
      figure: fig(<Map<String, Object?>>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'markers',
          'x': strX,
          'y': numY,
        },
      ]),
      kind: FluentPlotlyChartKind.scatter,
    ),
    (
      name:
          'markers plus a layout line shape become a line when the x '
          'supports it',
      figure: fig(
        <Map<String, Object?>>[
          <String, Object?>{
            'type': 'scatter',
            'mode': 'markers',
            'x': numX,
            'y': numY,
          },
        ],
        <String, Object?>{
          'shapes': <Object?>[
            <String, Object?>{'type': 'line'},
          ],
        },
      ),
      kind: FluentPlotlyChartKind.line,
    ),
    (
      name: 'tozeroy fill over a date x is an area',
      figure: fig(<Map<String, Object?>>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'fill': 'tozeroy',
          'x': dateX,
          'y': numY,
        },
      ]),
      kind: FluentPlotlyChartKind.area,
    ),
    (
      name: 'a stackgroup over a date x is an area',
      figure: fig(<Map<String, Object?>>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'stackgroup': 'g',
          'x': dateX,
          'y': numY,
        },
      ]),
      kind: FluentPlotlyChartKind.area,
    ),
    (
      name: 'a category x axis forces the fallback even for numeric x',
      figure: fig(
        <Map<String, Object?>>[
          <String, Object?>{
            'type': 'scatter',
            'mode': 'lines',
            'x': numX,
            'y': numY,
          },
        ],
        <String, Object?>{
          'xaxis': <String, Object?>{'type': 'category'},
        },
      ),
      kind: FluentPlotlyChartKind.fallback,
    ),
    (
      name: 'a string y forces the fallback',
      figure: fig(<Map<String, Object?>>[
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'x': numX,
          'y': strY,
        },
      ]),
      kind: FluentPlotlyChartKind.fallback,
    ),
    (
      name: 'a vertical bar defaults to stacked',
      figure: fig(<Map<String, Object?>>[
        <String, Object?>{'type': 'bar', 'x': strX, 'y': numY},
      ]),
      kind: FluentPlotlyChartKind.verticalStackedBar,
    ),
    (
      name: 'barmode overlay routes to grouped',
      figure: fig(
        <Map<String, Object?>>[
          <String, Object?>{'type': 'bar', 'x': strX, 'y': numY},
        ],
        <String, Object?>{'barmode': 'overlay'},
      ),
      kind: FluentPlotlyChartKind.groupedVerticalBar,
    ),
    (
      name: 'a horizontal bar without a base is a horizontal bar',
      figure: fig(<Map<String, Object?>>[
        <String, Object?>{
          'type': 'bar',
          'orientation': 'h',
          'x': numY,
          'y': strY,
        },
      ]),
      kind: FluentPlotlyChartKind.horizontalBar,
    ),
    (
      name: 'a histogram routes to the vertical bar chart',
      figure: fig(<Map<String, Object?>>[
        <String, Object?>{'type': 'histogram', 'x': numX},
      ]),
      kind: FluentPlotlyChartKind.verticalStackedBar,
    ),
    (
      name: 'histogram2d routes to heatmap',
      figure: fig(<Map<String, Object?>>[
        <String, Object?>{'type': 'histogram2d', 'x': numX, 'y': numY},
      ]),
      kind: FluentPlotlyChartKind.heatmap,
    ),
    (
      name: 'an indicator in gauge mode routes to gauge',
      figure: fig(<Map<String, Object?>>[
        <String, Object?>{
          'type': 'indicator',
          'mode': 'gauge+number',
          'value': 5,
        },
      ]),
      kind: FluentPlotlyChartKind.gauge,
    ),
    (
      name: 'funnelarea routes to funnel',
      figure: fig(<Map<String, Object?>>[
        <String, Object?>{'type': 'funnelarea', 'labels': strX, 'values': numY},
      ]),
      kind: FluentPlotlyChartKind.funnel,
    ),
    (
      name: 'scatterpolar routes to polar',
      figure: fig(<Map<String, Object?>>[
        <String, Object?>{'type': 'scatterpolar', 'theta': numX, 'r': numY},
      ]),
      kind: FluentPlotlyChartKind.scatterPolar,
    ),
    (
      name: 'table routes to table',
      figure: fig(<Map<String, Object?>>[
        <String, Object?>{'type': 'table'},
      ]),
      kind: FluentPlotlyChartKind.table,
    ),
  ];

  for (final c in cases) {
    test('routes ${c.name}', () {
      final route = mapFluentChart(c.figure);
      expect(route.isValid, isTrue, reason: '${c.name}: ${route.errorMessage}');
      expect(
        route.kind,
        c.kind,
        reason:
            '${c.name} must route to ${c.kind}; a mis-ordered branch in '
            'PlotlySchemaConverter.ts:506-579 renders the wrong chart silently.',
      );
    });
  }

  test('the corpus covers every reachable single-trace kind', () {
    final covered = cases.map((c) => c.kind).toSet();
    const unreachableAlone = <FluentPlotlyChartKind>{
      FluentPlotlyChartKind.composite,
      FluentPlotlyChartKind.annotation,
      FluentPlotlyChartKind.donut,
      FluentPlotlyChartKind.sankey,
      FluentPlotlyChartKind.gantt,
    };
    final missing = FluentPlotlyChartKind.values.toSet()
      ..removeAll(covered)
      ..removeAll(unreachableAlone);
    expect(
      missing,
      isEmpty,
      reason:
          'Every single-trace kind needs a corpus row; '
          'donut/sankey/gantt/annotation/composite are covered in '
          'router_mapping_test.dart.',
    );
  });
}
