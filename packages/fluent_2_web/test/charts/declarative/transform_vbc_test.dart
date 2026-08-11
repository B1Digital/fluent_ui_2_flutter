import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/plotly/color_adapter.dart';
import 'package:fluent_2_web/src/charts/internal/plotly/transform_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentVerticalBarChart build(Map<String, Object?> input) =>
      transformPlotlyToVbc(
        input,
        isMultiPlot: false,
        colorMap: <String, String>{},
        colorwayType: FluentPlotlyColorway.byDefault,
        isDark: false,
      );

  test('a histogram bins its x values and labels the callout with a half-open '
      'interval', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'histogram',
          'x': <Object?>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
          'xbins': <String, Object?>{'start': 0, 'end': 10, 'size': 5},
        },
      ],
    });
    expect(
      chart.data,
      hasLength(2),
      reason:
          'Two five-wide bins over 0..10: createBins drops the degenerate '
          'trailing bin (PlotlySchemaAdapter.ts:3434-3438).',
    );
    expect(
      chart.data.first.xAxisCalloutData,
      '[0 - 5)',
      reason:
          'PlotlySchemaAdapter.ts:1882 formats the callout as `[x0 - x1)` '
          'exactly.',
    );
  });

  test('the injected scalar defaults', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'histogram',
          'x': <Object?>[1, 2, 3],
        },
      ],
    });
    expect(chart.mode, 'histogram', reason: 'PlotlySchemaAdapter.ts:1893.');
    expect(chart.maxBarWidth, 50, reason: 'PlotlySchemaAdapter.ts:1895.');
    expect(chart.roundCorners, isTrue, reason: 'PlotlySchemaAdapter.ts:1897.');
    expect(
      chart.props.hideTickOverlap,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:1894.',
    );
    expect(
      chart.props.showYAxisLables,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:1898.',
    );
    expect(
      chart.props.roundedTicks,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:1899.',
    );
  });

  test('histfunc sum aggregates y within each bin', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'histogram',
          'x': <Object?>[0, 1, 6, 7],
          'y': <Object?>[10, 20, 30, 40],
          'histfunc': 'sum',
          'xbins': <String, Object?>{'start': 0, 'end': 10, 'size': 5},
        },
      ],
    });
    expect(
      chart.data.map((point) => point.y).toList(),
      <double>[30, 70],
      reason:
          'PlotlySchemaAdapter.ts:1845-1849 reduces each bin with '
          'calculateHistFunc, whose `sum` arm is :3446.',
    );
  });

  test('histnorm percent normalises to a total of one hundred', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'histogram',
          'x': <Object?>[0, 1, 6, 7],
          'histnorm': 'percent',
          'xbins': <String, Object?>{'start': 0, 'end': 10, 'size': 5},
        },
      ],
    });
    expect(
      chart.data.map((point) => point.y).reduce((a, b) => a + b),
      closeTo(100, 1e-9),
      reason: 'PlotlySchemaAdapter.ts:3466-3467, the percent branch.',
    );
  });

  test('a bin of strings joins its members and carries no callout', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'histogram',
          'x': <Object?>['a', 'b', 'c'],
          'xbins': <String, Object?>{'size': 2},
        },
      ],
    });
    expect(
      chart.data.map((point) => point.x).toList(),
      <Object>['a, b', 'c'],
      reason:
          "PlotlySchemaAdapter.ts:1876 joins a string bin with ', ' where a "
          'numeric one takes its centre.',
    );
    expect(
      chart.data.every((point) => point.xAxisCalloutData == null),
      isTrue,
      reason:
          'PlotlySchemaAdapter.ts:1880-1882 spreads an empty object for a '
          'string bin, so no callout override is injected at all.',
    );
  });

  test('an explicit layout range reaches both axes', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'x': <Object?>['a'],
          'y': <Object?>[1],
        },
      ],
      'layout': <String, Object?>{
        'xaxis': <String, Object?>{
          'range': <Object?>[0, 4],
        },
        'yaxis': <String, Object?>{
          'range': <Object?>[0, 50],
        },
      },
    });
    expect(chart.props.xMinValue, 0, reason: 'PlotlySchemaAdapter.ts:1900.');
    expect(chart.props.xMaxValue, 4, reason: 'PlotlySchemaAdapter.ts:1900.');
    expect(
      chart.props.showRoundOffXTickValues,
      isFalse,
      reason: 'PlotlySchemaAdapter.ts:239 travels with the x range.',
    );
    expect(chart.props.yMaxValue, 50, reason: 'PlotlySchemaAdapter.ts:1902.');
  });

  test('no layout range leaves the shell defaults untouched', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'x': <Object?>['a'],
          'y': <Object?>[1],
        },
      ],
    });
    expect(
      chart.props.xMinValue,
      isNull,
      reason:
          'PlotlySchemaAdapter.ts:242 spreads nothing, so the prop stays unset.',
    );
    expect(
      chart.props.showRoundOffXTickValues,
      isTrue,
      reason:
          'The shell default survives an empty spread (contract section 7.1).',
    );
  });

  test('the declared category order reaches the widget, not the shell props', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'x': <Object?>['b', 'a'],
          'y': <Object?>[1, 2],
        },
      ],
      'layout': <String, Object?>{
        'xaxis': <String, Object?>{'categoryorder': 'category ascending'},
      },
    });
    expect(
      chart.xAxisCategoryOrder,
      FluentAxisCategoryOrder.categoryAscending,
      reason:
          'PlotlySchemaAdapter.ts:1903 spreads getAxisCategoryOrderProps, and '
          'vertical_bar_chart.dart:216 reads the WIDGET field — the identical '
          'props field is never read on this chart, so routing it there would '
          'be inert.',
    );
  });

  test('a bar whose text is templated carries the formatted label', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'histogram',
          'x': <Object?>[0, 1],
          'text': <Object?>['12.345', ''],
          'texttemplate': '%{text:.1f} units',
          'xbins': <String, Object?>{'start': 0, 'end': 2, 'size': 1},
        },
      ],
    });
    expect(
      chart.data.map((point) => point.barLabel).toList(),
      <String?>['12.3 units', null],
      reason:
          'PlotlySchemaAdapter.ts:1870-1873 formats a truthy label only, and '
          ':1883 spreads nothing for an empty one.',
    );
  });

  test('a declared log axis reaches the scale-type props', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'histogram',
          'x': <Object?>[1, 2],
        },
      ],
      'layout': <String, Object?>{
        'xaxis': <String, Object?>{'type': 'log'},
        'yaxis': <String, Object?>{'type': 'log'},
      },
    });
    expect(
      chart.props.xScaleType,
      FluentAxisScaleType.log,
      reason:
          'PlotlySchemaAdapter.ts:3943-3945 sets xScaleType for a declared log '
          'axis, and FluentCartesianChartProps carries the field.',
    );
    expect(
      chart.props.yScaleType,
      FluentAxisScaleType.log,
      reason: 'PlotlySchemaAdapter.ts:3947-3949, same spread.',
    );
  });
}
