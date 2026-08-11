import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/plotly/color_adapter.dart';
import 'package:fluent_2_web/src/charts/internal/plotly/transform_bar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentGroupedVerticalBarChart build(Map<String, Object?> input) =>
      transformPlotlyToGvbc(
        input,
        isMultiPlot: false,
        colorMap: <String, String>{},
        colorwayType: FluentPlotlyColorway.byDefault,
        isDark: false,
      );

  final twoTraces = <String, Object?>{
    'data': <Object?>[
      <String, Object?>{
        'type': 'bar',
        'name': 's1',
        'x': <Object?>['a'],
        'y': <Object?>[1],
      },
      <String, Object?>{
        'type': 'bar',
        'name': 's2',
        'x': <Object?>['a'],
        'y': <Object?>[2],
      },
    ],
    'layout': <String, Object?>{'barmode': 'group'},
  };

  // The plan's Step 1 reads `chart.data`, the group shape. Upstream fills
  // `dataV2` (`PlotlySchemaAdapter.ts:1652`, `:1770`), which is the ONLY input
  // that carries the scatter overlay at `:1740-1763`; `GroupedVerticalBarChart`
  // then pivots it into groups itself (`.tsx:267-295`, ported at
  // `grouped_vertical_bar_chart.dart:1148`) and ignores `data` entirely while
  // `dataV2` is non-empty (`.tsx:296-304`). So the series assertion is made on
  // `dataV2` and the group assertion on the mounted chart, which is where the
  // pivot actually happens.
  test('one series per trace lands in dataV2, in trace order', () {
    final chart = build(twoTraces);
    expect(
      chart.dataV2!.map((series) => series.legend).toList(),
      <String>['s1', 's2'],
      reason:
          'PlotlySchemaAdapter.ts:1658-1765 walks the traces and pushes one series each.',
    );
    expect(
      chart.dataV2!.map((series) => series.data.length).toList(),
      <int>[1, 1],
      reason: 'One x value per trace, so one point each.',
    );
  });

  testWidgets('each x value becomes one group holding one bar per trace', (
    tester,
  ) async {
    await tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: Center(
          // 800x350 is the same box the chart's own widget tests mount in.
          child: SizedBox(width: 800, height: 350, child: build(twoTraces)),
        ),
      ),
    );
    final delegate =
        tester
                .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
                .delegate
            as FluentGroupedVerticalBarChartDelegate;
    expect(
      delegate.data.length,
      1,
      reason:
          'the two traces share one x value, so the pivot at '
          'GroupedVerticalBarChart.tsx:267-295 must produce ONE group, not '
          'one per trace',
    );
    expect(
      delegate.data.single.series.map((point) => point.legend).toList(),
      <String>['s1', 's2'],
      reason:
          'PlotlySchemaAdapter.ts:1673-1718 pushes one bar series per trace '
          'per group, and this is the mounted chart reading it — not the '
          'transformer output inspected in isolation',
    );
  });

  test('the injected scalar defaults, and no truncation count', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'x': <Object?>['a'],
          'y': <Object?>[1],
        },
      ],
      'layout': <String, Object?>{'barmode': 'group'},
    });
    // `height` is deliberately absent, as in task 18: the shell charts size to
    // their constraints (spec §2.2) and task 28 supplies
    // `PlotlySchemaAdapter.ts:1772`'s 350 from `kPlotlyDefaultCellHeight`.
    expect(chart.barWidth, 'auto', reason: 'PlotlySchemaAdapter.ts:1773.');
    expect(chart.mode, 'plotly', reason: 'PlotlySchemaAdapter.ts:1774.');
    expect(
      chart.props.hideTickOverlap,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:1776.',
    );
    expect(chart.roundCorners, isTrue, reason: 'PlotlySchemaAdapter.ts:1778.');
    expect(
      chart.props.showYAxisLables,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:1779.',
    );
    expect(
      chart.props.roundedTicks,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:1780.',
    );
    expect(
      chart.props.noOfCharsToTruncate,
      4,
      reason:
          'PlotlySchemaAdapter.ts:1769-1789 injects no noOfCharsToTruncate, '
          'unlike the VSBC transformer at :1595 which injects 20 — so the '
          "shell's own default of 4 (cartesian_chart_props.dart:101) stands. "
          'The plan asks for null here, which the non-nullable prop cannot '
          'hold. // parity',
    );
  });

  test('a scatter trace becomes a line series', () {
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
          'name': 'line',
          'mode': 'lines',
          'x': <Object?>['a', 'b'],
          'y': <Object?>[3, 4],
        },
      ],
      'layout': <String, Object?>{'barmode': 'group'},
    });
    expect(
      chart.dataV2!.map((series) => series.runtimeType.toString()).toList(),
      <String>['FluentBarSeries', 'FluentLineSeries'],
      reason:
          'PlotlySchemaAdapter.ts:1740-1763 pushes a line entry per valid xy '
          'range of a scatter trace.',
    );
  });

  test('a pinned layout range overrides the axis bounds', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'name': 's1',
          'x': <Object?>[1, 2],
          'y': <Object?>[10, 20],
        },
      ],
      'layout': <String, Object?>{
        'xaxis': <String, Object?>{
          'range': <Object?>[0, 5],
        },
        'yaxis': <String, Object?>{
          'range': <Object?>[-4, 40],
        },
      },
    });
    expect(
      <Object?>[chart.props.xMinValue, chart.props.xMaxValue],
      <Object?>[0, 5],
      reason: 'PlotlySchemaAdapter.ts:1781 spreads getXMinMaxValues.',
    );
    expect(
      chart.props.showRoundOffXTickValues,
      isFalse,
      reason: 'PlotlySchemaAdapter.ts:239 ships false with the range.',
    );
    expect(
      <double>[chart.props.yMinValue, chart.props.yMaxValue],
      <double>[-4, 40],
      reason:
          'PlotlySchemaAdapter.ts:1784 spreads getYMinMaxValues, and this '
          'transformer seeds no bounds of its own, so the range is the only '
          'source.',
    );
  });

  test('an absent range leaves the zero seeds', () {
    final chart = build(twoTraces);
    expect(
      <double>[chart.props.yMinValue, chart.props.yMaxValue],
      <double>[0, 0],
      reason:
          "PlotlySchemaAdapter.ts:1784's empty spread injects nothing, so the "
          'shell defaults stand — the y domain is derived from the data by '
          'the chart itself.',
    );
  });

  // The plan's Step 1 calls `normalizeObjectArrayForGvbc(trace)` and reads a
  // `'__series__'` key off a `Map` return. Upstream takes the object array and
  // the x labels and returns `{ traces, x }` (`:1169-1243`), which is what
  // `:1625-1645` destructures; a magic-keyed map cannot be spread the way
  // `:1637` spreads a trace, so the record shape is kept and the assertion is
  // made on the real per-key traces.
  test('an object-array y is normalised into one trace per numeric key', () {
    final normalised = normalizeObjectArrayForGvbc(
      <Map<String, Object?>>[
        <String, Object?>{'p': 1, 'q': 2},
        <String, Object?>{'p': 3, 'q': 4},
      ],
      <Object?>['a', 'b'],
    );
    expect(
      normalised.x,
      <Object?>['a', 'b'],
      reason:
          'PlotlySchemaAdapter.ts:1178 keeps the supplied labels when there '
          'is one per object.',
    );
    expect(
      normalised.traces.map((trace) => trace['name']).toList(),
      <Object?>['p', 'q'],
      reason: 'PlotlySchemaAdapter.ts:1211-1240 emits one trace per key.',
    );
    expect(
      normalised.traces.map((trace) => trace['y']).toList(),
      <Object?>[
        <double>[1, 3],
        <double>[2, 4],
      ],
      reason: 'PlotlySchemaAdapter.ts:1216-1227 columnises the key.',
    );
  });

  test('style and non-numeric keys are dropped, and labels default', () {
    final normalised = normalizeObjectArrayForGvbc(<Map<String, Object?>>[
      <String, Object?>{
        'p': '1',
        'color': 5,
        'labelStyle': 2,
        'name': 'x',
        'nested': <String, Object?>{'q': 7},
      },
    ]);
    expect(
      normalised.x,
      <Object?>['Item 1'],
      reason:
          'PlotlySchemaAdapter.ts:1178 falls back to `Item n` without labels.',
    );
    expect(
      normalised.traces.map((trace) => trace['name']).toList(),
      <Object?>['p', 'nested.q'],
      reason:
          'PlotlySchemaAdapter.ts:1186-1191 keeps numeric non-style keys only, '
          'flattened with dots by :520-538; `color` and `labelStyle` are '
          'ignored by :493-511 and the string `name` is not numeric.',
    );
    expect(
      normalised.traces.first['y'],
      <double>[1],
      reason: "PlotlySchemaAdapter.ts:1223 parses the numeric string '1'.",
    );
  });

  test('an object-array y trace is split before the chart is built', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'name': 'ignored',
          'x': <Object?>['a', 'b'],
          'y': <Object?>[
            <String, Object?>{'p': 1, 'q': 2},
            <String, Object?>{'p': 3, 'q': 4},
          ],
        },
      ],
      'layout': <String, Object?>{'barmode': 'group'},
    });
    expect(
      chart.dataV2!.map((series) => series.legend).toList(),
      <String>['p', 'q'],
      reason:
          'PlotlySchemaAdapter.ts:1625-1651 replaces the trace with one per '
          'key BEFORE the legends are read, so the legend names come from the '
          'generated traces and not from the original trace name.',
    );
  });
}
