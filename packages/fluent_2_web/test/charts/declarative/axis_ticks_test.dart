import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/plotly/axis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a category x axis forces the auto tick layout', () {
    final props = getAxisTickProps(<Object?>[
      <String, Object?>{
        'type': 'bar',
        'x': <Object?>['a', 'b'],
        'y': <Object?>[1, 2],
      },
    ], null);
    expect(
      props.xAxisTickLayout,
      FluentTickLayout.auto,
      reason: 'PlotlySchemaAdapter.ts:3976-3980.',
    );
  });

  test('tickvals with ticktext produce explicit tick values and labels', () {
    final props = getAxisTickProps(
      <Object?>[
        <String, Object?>{
          'type': 'scatter',
          'x': <Object?>[1, 2],
          'y': <Object?>[1, 2],
        },
      ],
      <String, Object?>{
        'xaxis': <String, Object?>{
          'tickvals': <Object?>[1, 2],
          'ticktext': <Object?>['one', 'two'],
        },
      },
    );
    expect(props.xAxisTickValues, <Object?>[
      1,
      2,
    ], reason: 'PlotlySchemaAdapter.ts:3982-3986.');
    expect(props.xAxisTickText, <String>[
      'one',
      'two',
    ], reason: 'PlotlySchemaAdapter.ts:3987-3989.');
  });

  test('a date axis maps tickvals through DateTime', () {
    final props = getAxisTickProps(
      <Object?>[
        <String, Object?>{
          'type': 'scatter',
          'x': <Object?>['2024-01-01'],
          'y': <Object?>[1],
        },
      ],
      <String, Object?>{
        'xaxis': <String, Object?>{
          'type': 'date',
          'tickvals': <Object?>['2024-01-01'],
        },
      },
    );
    expect(
      props.xAxisTickValues!.single,
      isA<DateTime>(),
      reason: 'PlotlySchemaAdapter.ts:3983 wraps date tickvals in new Date(v).',
    );
  });

  test('nticks becomes a tick count on both axes', () {
    final props = getAxisTickProps(
      <Object?>[
        <String, Object?>{
          'type': 'scatter',
          'x': <Object?>[1],
          'y': <Object?>[1],
        },
      ],
      <String, Object?>{
        'xaxis': <String, Object?>{'nticks': 3},
        'yaxis': <String, Object?>{'nticks': 7},
      },
    );
    expect(
      props.xAxisTickCount,
      3,
      reason: 'PlotlySchemaAdapter.ts:4021-4027.',
    );
    expect(
      props.yAxisTickCount,
      7,
      reason: 'PlotlySchemaAdapter.ts:4021-4027.',
    );
  });

  test('plotlyDtick defaults differ between date and non-date axes', () {
    expect(
      plotlyDtick(null, FluentPlotlyAxisType.date),
      86400000,
      reason:
          'PlotlySchemaAdapter.ts:4040 defaults a date dtick to one day in '
          'milliseconds.',
    );
    expect(
      plotlyDtick(null, FluentPlotlyAxisType.linear),
      1,
      reason: 'PlotlySchemaAdapter.ts:4040 defaults everything else to 1.',
    );
  });

  test(
    'a category dtick rounds up to at least 1 and a date dtick floors at 0.1',
    () {
      expect(
        plotlyDtick(0.4, FluentPlotlyAxisType.category),
        1,
        reason:
            'PlotlySchemaAdapter.ts:4051-4053 category branch: '
            'max(1, jsRound(dtick)).',
      );
      expect(
        plotlyDtick(0.05, FluentPlotlyAxisType.date),
        0.1,
        reason:
            'PlotlySchemaAdapter.ts:4055-4057 date branch: max(0.1, dtick).',
      );
    },
  );

  test('string dtick forms are accepted only in their own axis kinds', () {
    expect(
      plotlyDtick('M3', FluentPlotlyAxisType.date),
      'M3',
      reason: 'Month step on a date axis (PlotlySchemaAdapter.ts:4071).',
    );
    expect(
      plotlyDtick('L0.5', FluentPlotlyAxisType.log),
      'L0.5',
      reason: 'Linear step on a log axis (PlotlySchemaAdapter.ts:4073).',
    );
    expect(
      plotlyDtick('D1', FluentPlotlyAxisType.log),
      'D1',
      reason: 'Decade sub-tick on a log axis (PlotlySchemaAdapter.ts:4075).',
    );
    expect(
      plotlyDtick('M3', FluentPlotlyAxisType.linear),
      1,
      reason:
          'A month step on a linear axis falls back to the default of 1 '
          '(PlotlySchemaAdapter.ts:4062-4064).',
    );
  });

  test(
    'plotlyTick0 defaults a date axis to the Fluent default date string',
    () {
      expect(
        plotlyTick0(null, FluentPlotlyAxisType.date, 86400000),
        DateTime.parse(kDefaultDateString),
        reason:
            'PlotlySchemaAdapter.ts:4091-4093 with DEFAULT_DATE_STRING from '
            'utilities.ts:91.',
      );
    },
  );

  test('plotlyTick0 is undefined for the D1 and D2 log forms', () {
    expect(
      plotlyTick0(0, FluentPlotlyAxisType.log, 'D1'),
      isNull,
      reason:
          'PlotlySchemaAdapter.ts:4095-4097 skips tick0 for the decade '
          'sub-tick modes.',
    );
  });

  // The plan's Step 1 left the y arm of the dtick branch and the whole of
  // getPolarAxisProps unexercised. Both are added here rather than left to a
  // later task: an untested helper that nothing calls is the exact shape this
  // programme has shipped seven times.
  test('a y axis dtick produces a y tick step and tick0, and no x ones', () {
    final props = getAxisTickProps(
      <Object?>[
        <String, Object?>{
          'type': 'scatter',
          'x': <Object?>[1, 2],
          'y': <Object?>[1, 2],
        },
      ],
      <String, Object?>{
        'yaxis': <String, Object?>{'dtick': 5, 'tick0': 2},
      },
    );
    expect(
      props.yAxisTickStep,
      5,
      reason: 'PlotlySchemaAdapter.ts:4014 writes the cleaned dtick to yAxis.',
    );
    expect(
      props.yAxisTick0,
      2,
      reason: 'PlotlySchemaAdapter.ts:4015 writes the cleaned tick0 with it.',
    );
    expect(
      props.xAxisTickStep,
      isNull,
      reason:
          'PlotlySchemaAdapter.ts:4005 only writes the x arm for axId "x", so '
          'a y-only dtick must leave x untouched.',
    );
  });

  test('a polar layout fills both axes, the unit and the direction', () {
    final props = getPolarAxisProps(
      <Object?>[
        <String, Object?>{
          'type': 'scatterpolar',
          'r': <Object?>[1, 2],
          'theta': <Object?>['a', 'b'],
        },
      ],
      <String, Object?>{
        'polar': <String, Object?>{
          'radialaxis': <String, Object?>{
            'range': <Object?>[0, 4],
            'nticks': 5,
          },
          'angularaxis': <String, Object?>{
            'thetaunit': 'degrees',
            'direction': 'clockwise',
            'categoryarray': <Object?>['b', 'a'],
          },
        },
      },
    );
    expect(
      props.radialAxis.rangeStart,
      0.0,
      reason: 'PlotlySchemaAdapter.ts:4351 spreads range[0] as rangeStart.',
    );
    expect(
      props.radialAxis.rangeEnd,
      4.0,
      reason: 'PlotlySchemaAdapter.ts:4351 spreads range[1] as rangeEnd.',
    );
    expect(
      props.radialAxis.tickCount,
      5,
      reason: 'PlotlySchemaAdapter.ts:4313-4315, the polar nticks arm.',
    );
    expect(
      props.radialAxis.scaleType,
      FluentAxisScaleType.auto,
      reason:
          'PlotlySchemaAdapter.ts:4347 maps everything but a log axis to '
          "upstream's 'default'.",
    );
    expect(
      props.angularAxis.categoryOrder,
      isA<FluentAxisCategoryOrderExplicit>().having(
        (FluentAxisCategoryOrderExplicit order) => order.categories,
        'categories',
        <String>['b', 'a'],
      ),
      reason:
          'PlotlySchemaAdapter.ts:4326-4327 returns categoryarray as declared '
          'for a category theta axis.',
    );
    expect(
      props.angularUnit,
      'degrees',
      reason:
          'PlotlySchemaAdapter.ts:4355 reads thetaunit off the angular '
          'axis only.',
    );
    expect(
      props.direction,
      'clockwise',
      reason: 'PlotlySchemaAdapter.ts:4356.',
    );
  });

  test('a polar range with a non-numeric endpoint is dropped, not thrown', () {
    final props = getPolarAxisProps(
      <Object?>[
        <String, Object?>{
          'type': 'scatterpolar',
          'r': <Object?>[1],
          'theta': <Object?>[0],
        },
      ],
      <String, Object?>{
        'polar': <String, Object?>{
          'radialaxis': <String, Object?>{
            'range': <Object?>['low', 'high'],
          },
        },
      },
    );
    expect(
      props.radialAxis.rangeStart,
      isNull,
      reason:
          'The range arrives from author-supplied JSON, so a string endpoint '
          'has to read as absent rather than throw on the render path.',
    );
  });

  test('a log y axis surfaces as a log scale type', () {
    final scales = getAxisScaleTypeProps(
      <Object?>[
        <String, Object?>{
          'type': 'scatter',
          'x': <Object?>[1],
          'y': <Object?>[1],
        },
      ],
      <String, Object?>{
        'yaxis': <String, Object?>{'type': 'log'},
      },
    );
    expect(
      scales.y,
      FluentAxisScaleType.log,
      reason: 'PlotlySchemaAdapter.ts:3938-3954.',
    );
  });

  test('categoryorder maps onto the Fluent axis category order presets', () {
    final orders = getAxisCategoryOrderProps(
      <Object?>[
        <String, Object?>{
          'type': 'bar',
          'x': <Object?>['a'],
          'y': <Object?>[1],
        },
      ],
      <String, Object?>{
        'xaxis': <String, Object?>{'categoryorder': 'total descending'},
      },
    );
    expect(
      orders.x,
      FluentAxisCategoryOrder.parse('total descending'),
      reason:
          'PlotlySchemaAdapter.ts:3837-3881, plotly.js '
          'category_order_defaults.js#L50.',
    );
  });

  test('an explicit categoryarray becomes the explicit order arm', () {
    final orders = getAxisCategoryOrderProps(
      <Object?>[
        <String, Object?>{
          'type': 'bar',
          'x': <Object?>['a'],
          'y': <Object?>[1],
        },
      ],
      <String, Object?>{
        'xaxis': <String, Object?>{
          'categoryorder': 'array',
          'categoryarray': <Object?>['b', 'a'],
        },
      },
    );
    expect(
      orders.x,
      isA<FluentAxisCategoryOrderExplicit>().having(
        (FluentAxisCategoryOrderExplicit order) => order.categories,
        'categories',
        <String>['b', 'a'],
      ),
      reason:
          'PlotlySchemaAdapter.ts:3865-3868 array branch. The assertion reads '
          'the field rather than comparing whole values because '
          'FluentAxisCategoryOrderExplicit (model/chart_common.dart:342) '
          'declares no operator ==, so a value comparison against '
          'FluentAxisCategoryOrder.explicit(...) compares identity and can '
          'never hold.',
    );
  });

  test(
    'an explicit x range becomes the x bounds and stops the tick round-off',
    () {
      final range = getXMinMaxValues(<String, Object?>{
        'xaxis': <String, Object?>{
          'range': <Object?>[-5, 25],
        },
      });
      expect(range.xMinValue, -5, reason: 'PlotlySchemaAdapter.ts:237.');
      expect(range.xMaxValue, 25, reason: 'PlotlySchemaAdapter.ts:238.');
      expect(
        range.showRoundOffXTickValues,
        isFalse,
        reason:
            'PlotlySchemaAdapter.ts:239 switches the round-off off whenever the '
            'author pinned a range, because nice() would widen a domain that '
            'was chosen deliberately (utilities.ts:283).',
      );
    },
  );

  test('an explicit y range becomes the y bounds', () {
    final range = getYMinMaxValues(<String, Object?>{
      'yaxis': <String, Object?>{
        'range': <Object?>[10, 90],
      },
    });
    expect(range.yMinValue, 10, reason: 'PlotlySchemaAdapter.ts:226.');
    expect(range.yMaxValue, 90, reason: 'PlotlySchemaAdapter.ts:227.');
  });

  test('an absent, short or non-numeric range injects nothing', () {
    expect(
      getXMinMaxValues(null).xMinValue,
      isNull,
      reason:
          'PlotlySchemaAdapter.ts:242 returns an empty object, which spreads '
          'to nothing.',
    );
    expect(
      getXMinMaxValues(null).showRoundOffXTickValues,
      isTrue,
      reason:
          'With nothing spread, the shell default of true survives '
          '(FluentCartesianChartProps, contract section 7.1).',
    );
    expect(
      getYMinMaxValues(<String, Object?>{
        'yaxis': <String, Object?>{
          'range': <Object?>[0],
        },
      }).yMinValue,
      isNull,
      reason: 'PlotlySchemaAdapter.ts:224 requires exactly two entries.',
    );
    expect(
      getXMinMaxValues(<String, Object?>{
        'xaxis': <String, Object?>{
          'range': <Object?>['2024-01-01', '2024-02-01'],
        },
      }).xMinValue,
      isNull,
      reason:
          'A date range endpoint has nowhere to land: utilities.ts:278-279 '
          'reads xMinValue only on the numeric x scale, so upstream discards '
          'it too.',
    );
  });
}
