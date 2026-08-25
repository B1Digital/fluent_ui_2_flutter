import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/charts/internal/plotly/transform_bar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentHorizontalBarChartWithAxis build(Map<String, Object?> input) =>
      transformPlotlyToHbwa(
        input,
        isMultiPlot: false,
        colorMap: <String, String>{},
        colorwayType: FluentPlotlyColorway.byDefault,
        isDark: false,
      );

  test('the bar height follows the documented seven-step formula', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'orientation': 'h',
          'x': <Object?>[1, 2, 3, 4],
          'y': <Object?>['a', 'b', 'c', 'd'],
        },
      ],
    });
    // chartHeight 450 (:2263), margin 0 (:2264), padding 0 (:2265)
    // availableHeight 450, numberOfRows 4 (:2267)
    // gapFactor = 1 / (1 + 0.01 * 4) = 0.9615384615384616 (:2269)
    // barHeight = 450 / (4 * 1.9615384615384617) = 57.35294117647059 (:2270)
    expect(
      chart.barHeight,
      closeTo(57.35294117647059, 1e-9),
      reason: 'PlotlySchemaAdapter.ts:2263-2270.',
    );
  });

  test('the layout margin and padding are subtracted from the available '
      'height', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'orientation': 'h',
          'x': <Object?>[1],
          'y': <Object?>['a'],
        },
      ],
      'layout': <String, Object?>{
        'height': 200,
        'margin': <String, Object?>{'l': 40, 'pad': 10},
      },
    });
    // availableHeight = 200 - 40 - 10 = 150; rows 1; gapFactor = 1 / 1.01
    // barHeight = 150 / (1 * (1 + 1 / 1.01)) = 75.3731343283582
    expect(
      chart.barHeight,
      closeTo(75.3731343283582, 1e-9),
      reason: 'PlotlySchemaAdapter.ts:2264-2270.',
    );
  });

  test('zero unique y values still divides by one', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'orientation': 'h',
          'x': <Object?>[],
          'y': <Object?>[],
        },
      ],
    });
    expect(
      // `FluentHorizontalBarChartWithAxis.barHeight` is a `double?` — absent
      // means "solve one from the band" — and this transformer always supplies
      // it, which is what the bang asserts.
      chart.barHeight!.isFinite,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:2267 guards the row count with `|| 1`.',
    );
  });

  test('the injected scalar defaults', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'orientation': 'h',
          'x': <Object?>[1],
          'y': <Object?>['a'],
        },
      ],
    });
    // Five of the six live on the shared cartesian props record rather than on
    // the widget; `roundCorners` is the one the widget itself carries.
    expect(
      chart.props.showYAxisLables,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:2279.',
    );
    expect(
      chart.props.hideTickOverlap,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:2282.',
    );
    expect(
      chart.props.noOfCharsToTruncate,
      20,
      reason: 'PlotlySchemaAdapter.ts:2283.',
    );
    expect(
      chart.props.showYAxisLablesTooltip,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:2284.',
    );
    expect(chart.roundCorners, isTrue, reason: 'PlotlySchemaAdapter.ts:2286.');
    expect(
      chart.props.roundedTicks,
      isTrue,
      reason: 'PlotlySchemaAdapter.ts:2287.',
    );
  });

  test('a pinned x range reaches the chart and the y range is ignored', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'orientation': 'h',
          'x': <Object?>[1],
          'y': <Object?>['a'],
        },
      ],
      'layout': <String, Object?>{
        'xaxis': <String, Object?>{
          'range': <Object?>[0, 6],
        },
        'yaxis': <String, Object?>{
          'range': <Object?>[0, 99],
        },
      },
    });
    expect(chart.props.xMaxValue, 6, reason: 'PlotlySchemaAdapter.ts:2288.');
    expect(
      chart.props.showRoundOffXTickValues,
      isFalse,
      reason: 'PlotlySchemaAdapter.ts:239 travels with the x range.',
    );
    expect(
      chart.props.yMaxValue,
      0,
      reason:
          'PlotlySchemaAdapter.ts:2288 spreads getXMinMaxValues only; there is '
          'no getYMinMaxValues call in this transformer. // parity',
    );
  });

  test('every point carries its trace legend, its x and its label', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'orientation': 'h',
          'name': 'north',
          'x': <Object?>[3, null],
          'y': <Object?>['a', 'b'],
          'text': <Object?>['three'],
        },
      ],
    });
    expect(
      chart.data.map((FluentHorizontalBarChartWithAxisDataPoint p) => p.x),
      <double>[3, 0],
      reason:
          'PlotlySchemaAdapter.ts:2251 reads x per point and substitutes 0 for '
          'an invalid one.',
    );
    expect(
      chart.data.map((FluentHorizontalBarChartWithAxisDataPoint p) => p.legend),
      <String>['north', 'north'],
      reason: 'PlotlySchemaAdapter.ts:2229 onto :2253.',
    );
    expect(
      chart.data
          .map((FluentHorizontalBarChartWithAxisDataPoint p) => p.barLabel)
          .toList(),
      <String?>['three', null],
      reason:
          'PlotlySchemaAdapter.ts:2255 sets barLabel only where series.text[i] '
          'is truthy.',
    );
  });

  test('an invalid y drops the whole point', () {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'orientation': 'h',
          'x': <Object?>[1, 2],
          'y': <Object?>[null, 'b'],
        },
      ],
    });
    expect(
      chart.data.map((FluentHorizontalBarChartWithAxisDataPoint p) => p.y),
      <Object>['b'],
      reason: 'PlotlySchemaAdapter.ts:2233-2235 filters on y, not on x.',
    );
    // The dropped row must also drop out of the row count the geometry divides
    // by: one surviving row, so the single-row formula applies.
    expect(
      chart.barHeight,
      closeTo(450 / (1 * (1 + 1 / 1.01)), 1e-9),
      reason:
          'PlotlySchemaAdapter.ts:2267 counts unique y over the FILTERED '
          'chartData, not over the raw column.',
    );
  });

  testWidgets('a transformed figure mounts and reaches the render delegate', (
    tester,
  ) async {
    final chart = build(<String, Object?>{
      'data': <Object?>[
        <String, Object?>{
          'type': 'bar',
          'orientation': 'h',
          'name': 'north',
          'x': <Object?>[3, 5],
          'y': <Object?>['a', 'b'],
        },
      ],
    });
    await tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: Center(
          // Large enough that the plot area survives the legend and axis
          // reservations rather than collapsing to nothing.
          child: SizedBox(width: 500, height: 400, child: chart),
        ),
      ),
    );
    final delegate =
        tester
                .widget<FluentCartesianChart>(find.byType(FluentCartesianChart))
                .delegate
            as FluentHorizontalBarChartWithAxisDelegate;
    expect(
      delegate.points
          .map((FluentHorizontalBarChartWithAxisDataPoint p) => p.y)
          .toList(),
      <Object>['a', 'b'],
      reason:
          'the categories this transformer copies off the traces '
          '(PlotlySchemaAdapter.ts:2252) reach the delegate a real mounted '
          'FluentHorizontalBarChartWithAxis paints from. Task 28 owns the '
          'production call site, so this is the proof the produced widget is '
          'consumable rather than a shape only a unit test ever reads.',
    );
    expect(
      delegate.barHeightProp,
      closeTo(450 / (2 * (1 + 1 / 1.02)), 1e-9),
      reason:
          'the pixel geometry at PlotlySchemaAdapter.ts:2263-2270 is the one '
          'thing this transformer computes that no other does, and it must '
          'reach the delegate rather than stopping at the widget field.',
    );
  });
}
