import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/charts/internal/plotly/transform_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentVerticalStackedBarChart build(Map<String, Object?> input) =>
      transformPlotlyToVsbc(
        input,
        isMultiPlot: false,
        colorMap: <String, String>{},
        colorwayType: FluentPlotlyColorway.byDefault,
        isDark: false,
      );

  final basic = <String, Object?>{
    'data': <Object?>[
      <String, Object?>{
        'type': 'bar',
        'name': 's1',
        'x': <Object?>['a', 'b'],
        'y': <Object?>[1, 2],
      },
      <String, Object?>{
        'type': 'bar',
        'name': 's2',
        'x': <Object?>['a', 'b'],
        'y': <Object?>[3, 4],
      },
    ],
  };

  test('bars group by x value in first-seen order', () {
    final chart = build(basic);
    expect(
      chart.data.map((group) => group.xAxisPoint).toList(),
      <Object>['a', 'b'],
      reason:
          'PlotlySchemaAdapter.ts:1406-1442 walks traces in order and keys '
          'groups by x.',
    );
    expect(
      chart.data.first.chartData.map((datum) => datum.legend).toList(),
      <String>['s1', 's2'],
      reason: 'Within a group the stack order is trace order.',
    );
  });

  test('the injected scalar defaults', () {
    final chart = build(basic);
    // `height` is deliberately absent: the plan's Step 3 block wrapped the
    // chart in a `SizedBox(height: 350)`, and task 20's audit note supersedes
    // that — the transformer returns the bare chart and task 28 supplies the
    // cell height from `kPlotlyDefaultCellHeight`
    // (`PlotlySchemaAdapter.ts:1584`).
    expect(chart.barWidth, 'auto', reason: 'PlotlySchemaAdapter.ts:1585.');
    expect(chart.mode, 'plotly', reason: 'PlotlySchemaAdapter.ts:1588.');
    expect(
      chart.props.hideTickOverlap,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:1590.',
    );
    expect(chart.barGapMax, 2, reason: 'PlotlySchemaAdapter.ts:1591.');
    expect(chart.roundCorners, isTrue, reason: 'PlotlySchemaAdapter.ts:1593.');
    expect(
      chart.props.showYAxisLables,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:1594.',
    );
    expect(
      chart.props.noOfCharsToTruncate,
      20,
      reason:
          'PlotlySchemaAdapter.ts:1595; the GVBC transformer deliberately '
          'omits this.',
    );
    expect(
      chart.props.showYAxisLablesTooltip,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:1596.',
    );
    expect(
      chart.props.roundedTicks,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:1597.',
    );
  });

  test('the y bounds seed at zero, so a legitimate all-negative series still '
      'shows zero', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'x': <Object?>['a'],
          'y': <Object?>[-5],
        },
      ],
    });
    expect(
      chart.props.yMaxValue,
      0,
      reason:
          'PlotlySchemaAdapter.ts:1399-1400 seeds yMaxValue and yMinValue at '
          '0, so an all-negative stack is drawn against a zero baseline, and '
          'with no layout range at :1604 nothing overwrites the seed. '
          '// parity',
    );
  });

  test('an explicit layout range overrides the zero-seeded y bounds', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'x': <Object?>['a'],
          'y': <Object?>[5],
        },
      ],
      'layout': <String, Object?>{
        'xaxis': <String, Object?>{
          'range': <Object?>[0, 10],
        },
        'yaxis': <String, Object?>{
          'range': <Object?>[-2, 20],
        },
      },
    });
    expect(
      chart.props.yMinValue,
      -2,
      reason:
          'PlotlySchemaAdapter.ts:1604 spreads getYMinMaxValues AFTER the '
          'seeded yMinValue at :1587, so the pinned range wins.',
    );
    expect(chart.props.yMaxValue, 20, reason: 'PlotlySchemaAdapter.ts:1604.');
    expect(chart.props.xMinValue, 0, reason: 'PlotlySchemaAdapter.ts:1598.');
    expect(chart.props.xMaxValue, 10, reason: 'PlotlySchemaAdapter.ts:1598.');
    expect(
      chart.props.showRoundOffXTickValues,
      isFalse,
      reason: 'PlotlySchemaAdapter.ts:239 rides along with the x range.',
    );
  });

  test('a scatter trace inside a bar figure becomes a line overlay', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'name': 'bars',
          'x': <Object?>['a', 'b'],
          'y': <Object?>[1, 2],
        },
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'name': 'line',
          'x': <Object?>['a', 'b'],
          'y': <Object?>[5, 6],
        },
      ],
    });
    expect(
      chart.data.first.lineData!.single.legend,
      'line',
      reason:
          'PlotlySchemaAdapter.ts:1479-1506 folds scatter traces into lineData '
          'per group.',
    );
  });

  test('a line shape becomes a reference line on the groups it lands in', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'name': 's1',
          'x': <Object?>['a', 'b'],
          'y': <Object?>[1, 2],
        },
      ],
      'layout': <String, Object?>{
        'shapes': <Object?>[
          <String, Object?>{
            'type': 'line',
            'xref': 'x domain',
            'yref': 'paper',
            'x0': 0,
            'x1': 1,
            'y0': 0,
            'y1': 1,
            'line': <String, Object?>{'color': 'red'},
          },
        ],
      },
    });
    expect(
      chart.data.map((group) => group.lineData!.single.legend).toList(),
      <String>['Reference_0', 'Reference_0'],
      reason:
          'PlotlySchemaAdapter.ts:1557-1575 pushes the shape at both of its x '
          'endpoints under one legend.',
    );
    expect(
      chart.data.map((group) => group.lineData!.single.y).toList(),
      <Object>[0.0, 2.0],
      reason:
          'PlotlySchemaAdapter.ts:1539-1553: a `paper` yref maps 0 to the '
          'running yMinValue and 1 to the running yMaxValue, which the two bars '
          'left at 0 and 2.',
    );
  });

  test('a line shape endpoint that matches no group is dropped', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'name': 's1',
          'x': <Object?>['a', 'b'],
          'y': <Object?>[1, 2],
        },
      ],
      'layout': <String, Object?>{
        'shapes': <Object?>[
          <String, Object?>{
            'type': 'line',
            'x0': 'nowhere',
            'x1': 1,
            'y0': 7,
            'y1': 8,
            'line': <String, Object?>{'color': 'red'},
          },
        ],
      },
    });
    expect(
      chart.data.first.lineData,
      isEmpty,
      reason:
          'PlotlySchemaAdapter.ts:1557 guards on the group existing, and no '
          "group is keyed 'nowhere'.",
    );
    expect(
      chart.data.last.lineData!.single.y,
      8,
      reason:
          'PlotlySchemaAdapter.ts:1527-1533 indexes xCategories with a numeric '
          "endpoint, so `x1: 1` is the category 'b', and :1567-1574 pushes "
          'there with the raw y1 because the yref is not `paper`.',
    );
  });

  test('a secondary y axis surfaces its own title and scale options', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'x': <Object?>['a'],
          'y': <Object?>[1],
        },
        <String, Object?>{
          'type': 'scatter',
          'mode': 'lines',
          'yaxis': 'y2',
          'x': <Object?>['a'],
          'y': <Object?>[100],
        },
      ],
      'layout': <String, Object?>{
        'yaxis2': <String, Object?>{'side': 'right', 'title': 'right axis'},
      },
    });
    expect(
      chart.props.secondaryYAxisTitle,
      'right axis',
      reason: 'PlotlySchemaAdapter.ts:304-355 getSecondaryYAxisValues.',
    );
    expect(
      chart.props.secondaryYScaleOptions?.yMaxValue,
      100,
      reason:
          'PlotlySchemaAdapter.ts:316-317 takes the min and max of the '
          'secondary trace only.',
    );
    expect(
      chart.data.first.lineData!.single.useSecondaryYScale,
      isTrue,
      reason:
          'PlotlySchemaAdapter.ts:300-302 — `yaxis: y2` plus a right-hand '
          'yaxis2 puts the line on the secondary scale.',
    );
  });
}
