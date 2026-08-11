import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/vega/spec.dart'
    show VegaSpecException;
import 'package:fluent_2_web/src/charts/internal/vega/transform_other.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'the Vega donut inner radius defaults to ZERO, not the Plotly minimum of '
    'one',
    () {
      final chart = transformVegaToDonut(
        <String, Object?>{
          'mark': 'arc',
          'data': <String, Object?>{
            'values': <Object?>[
              <String, Object?>{'c': 'a', 'v': 1},
            ],
          },
          'encoding': <String, Object?>{
            'theta': <String, Object?>{'field': 'v', 'type': 'quantitative'},
            'color': <String, Object?>{'field': 'c', 'type': 'nominal'},
          },
        },
        <String, String>{},
        isDark: false,
      );
      expect(
        chart.innerRadius,
        0,
        reason:
            'VegaLiteSchemaAdapter.ts:3264 defaults mark.innerRadius to 0, '
            'unlike the Plotly path which uses MIN_DONUT_RADIUS = 1 '
            '(PlotlySchemaAdapter.ts:1356).',
      );
    },
  );

  test('a donut with no colour field labels each slice with its value', () {
    final chart = transformVegaToDonut(
      <String, Object?>{
        'mark': 'arc',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'v': 7},
          ],
        },
        'encoding': <String, Object?>{
          'theta': <String, Object?>{'field': 'v', 'type': 'quantitative'},
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(
      chart.data.chartData!.single.legend,
      '7',
      reason: 'VegaLiteSchemaAdapter.ts:3272 falls back to String(value).',
    );
  });

  test('a donut arc keeps the mark radius the spec declares', () {
    final chart = transformVegaToDonut(
      <String, Object?>{
        // 30 is an arbitrary hole radius; the point is that it survives.
        'mark': <String, Object?>{'type': 'arc', 'innerRadius': 30},
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'v': 1},
            // Dropped by `:3274`: a string theta is not a JavaScript number.
            <String, Object?>{'v': 'x'},
          ],
        },
        'encoding': <String, Object?>{
          'theta': <String, Object?>{'field': 'v', 'type': 'quantitative'},
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(
      chart.innerRadius,
      30,
      reason: 'VegaLiteSchemaAdapter.ts:3264 reads mark.innerRadius.',
    );
    expect(
      chart.data.chartData!.length,
      1,
      reason:
          'VegaLiteSchemaAdapter.ts:3274 drops every row whose theta value is '
          'not a number.',
    );
  });

  FluentHeatMapChart heatmap({
    Object? colorEncoding,
    List<Object?>? values,
    bool isDark = false,
  }) => transformVegaToHeatmap(
    <String, Object?>{
      'mark': 'rect',
      'data': <String, Object?>{
        'values':
            values ??
            <Object?>[
              <String, Object?>{'x': 'a', 'y': 'p', 'v': 0},
              <String, Object?>{'x': 'b', 'y': 'q', 'v': 8},
            ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'nominal'},
        'y': <String, Object?>{'field': 'y', 'type': 'nominal'},
        'color':
            colorEncoding ??
            <String, Object?>{'field': 'v', 'type': 'quantitative'},
      },
    },
    <String, String>{},
    isDark: isDark,
  );

  test('the quantitative colour scale has five evenly-spaced stops', () {
    final chart = heatmap();
    expect(
      chart.domainValuesForColorScale,
      hasLength(5),
      reason: 'VegaLiteSchemaAdapter.ts:3465-3469: steps = 5.',
    );
    expect(
      chart.domainValuesForColorScale,
      <double>[0, 2, 4, 6, 8],
      reason:
          'VegaLiteSchemaAdapter.ts:3468: minValue + (maxValue - minValue) * '
          'i / 4, over a 0..8 extent.',
    );
  });

  test('the light default gradient runs blue to red through the documented '
      'stops', () {
    final chart = heatmap();
    expect(
      chart.rangeValuesForColorScale
          .map((colour) => colour.toARGB32())
          .toList(),
      <int>[
        0xFF0096FF, // rgb(0, 150, 255)   `:3492-3494` at t = 0
        0xFF4071BF, // rgb(64, 113, 191)  at t = 0.25
        0xFF804B80, // rgb(128, 75, 128)  at t = 0.5
        0xFFBF2640, // rgb(191, 38, 64)   at t = 0.75
        0xFFFF0000, // rgb(255, 0, 0)     at t = 1
      ],
      reason:
          'VegaLiteSchemaAdapter.ts:3492-3494: r = round(255t), '
          'g = round(150 - 150t), b = round(255 - 255t).',
    );
  });

  test('the dark default gradient runs blue to orange', () {
    final chart = heatmap(isDark: true);
    expect(
      chart.rangeValuesForColorScale.first.toARGB32(),
      0xFF0064FF,
      reason: 'VegaLiteSchemaAdapter.ts:3487-3489 at t = 0: rgb(0, 100, 255).',
    );
    expect(
      chart.rangeValuesForColorScale.last.toARGB32(),
      0xFFFFA500,
      reason: 'VegaLiteSchemaAdapter.ts:3487-3489 at t = 1: rgb(255, 165, 0).',
    );
  });

  test('a descending colour sort reverses the ramp', () {
    final normal = heatmap(
      colorEncoding: <String, Object?>{
        'field': 'v',
        'type': 'quantitative',
        'scale': <String, Object?>{'scheme': 'blues'},
      },
    );
    final reversed = heatmap(
      colorEncoding: <String, Object?>{
        'field': 'v',
        'type': 'quantitative',
        'sort': 'descending',
        'scale': <String, Object?>{'scheme': 'blues'},
      },
    );
    expect(
      normal.rangeValuesForColorScale.first.toARGB32(),
      isNot(normal.rangeValuesForColorScale.last.toARGB32()),
      reason:
          'the blues ramp is not symmetrical, so the reversal below is '
          'observable at all (VegaLiteColorAdapter.ts:292).',
    );
    expect(
      reversed.rangeValuesForColorScale.first.toARGB32(),
      normal.rangeValuesForColorScale.last.toARGB32(),
      reason:
          'VegaLiteSchemaAdapter.ts:3476-3478 reverses when sort is '
          'descending or scale.reverse is true.',
    );
  });

  test('an explicit scale range wins over every scheme', () {
    final chart = heatmap(
      colorEncoding: <String, Object?>{
        'field': 'v',
        'type': 'quantitative',
        'scale': <String, Object?>{
          'scheme': 'blues',
          'range': <Object?>['#000000', '#ffffff'],
        },
      },
    );
    expect(
      chart.rangeValuesForColorScale
          .map((colour) => colour.toARGB32())
          .toList(),
      <int>[0xFF000000, 0xFFFFFFFF],
      reason:
          'VegaLiteSchemaAdapter.ts:3471-3472 takes the whole custom range '
          'when it is shorter than the five steps, and never consults the '
          'scheme.',
    );
  });

  test('missing grid cells are filled with zero', () {
    final chart = heatmap(
      values: <Object?>[
        <String, Object?>{'x': 'a', 'y': 'p', 'v': 5},
        <String, Object?>{'x': 'b', 'y': 'q', 'v': 6},
      ],
    );
    expect(
      chart.data.expand((band) => band.data).length,
      4,
      reason:
          'VegaLiteSchemaAdapter.ts:3414-3417 completes the 2 x 2 grid, '
          'filling the two absent cells with 0.',
    );
    expect(
      chart.domainValuesForColorScale.first,
      5,
      reason:
          'VegaLiteSchemaAdapter.ts:3420 skips the min/max update for a '
          'filled 0, so the domain still starts at the smallest REAL value.',
    );
  });

  test('the heatmap scalar defaults', () {
    final chart = heatmap();
    // `:3510`'s `height: spec.height ?? DEFAULT_CHART_HEIGHT` has no
    // counterpart here, and neither does `:3509`'s width: FluentHeatMapChart
    // is a shell chart and takes its size from its BoxConstraints (spec §2.2),
    // so the 350 becomes the cell SizedBox Task 52 wraps the chart in
    // (`kVegaDefaultCellHeight`, plan 09 line 19357). Nothing to assert on the
    // widget; stated here so the omission is not read as a miss.
    expect(
      chart.props.hideLegend,
      isTrue,
      reason: 'VegaLiteSchemaAdapter.ts:3511.',
    );
    expect(
      chart.props.showYAxisLables,
      isTrue,
      reason: 'VegaLiteSchemaAdapter.ts:3512.',
    );
    expect(
      chart.sortAlphabetically,
      isFalse,
      reason:
          "VegaLiteSchemaAdapter.ts:3513 sends sortOrder: 'none', which "
          'heat_map_chart.dart:667 spells as sortAlphabetically: false.',
    );
    expect(
      chart.props.hideTickOverlap,
      isTrue,
      reason: 'VegaLiteSchemaAdapter.ts:3514.',
    );
    expect(
      chart.props.noOfCharsToTruncate,
      20,
      reason:
          'VegaLiteSchemaAdapter.ts:3515, the else arm of the ladder — two '
          'distinct x values clear neither the 20 nor the 10 rung.',
    );
    expect(
      chart.props.showYAxisLablesTooltip,
      isTrue,
      reason: 'VegaLiteSchemaAdapter.ts:3516.',
    );
    expect(
      chart.props.wrapXAxisLables,
      isTrue,
      reason: 'VegaLiteSchemaAdapter.ts:3517.',
    );
  });

  test('a nominal colour field indexes the categories instead of scaling '
      'them', () {
    final chart = heatmap(
      colorEncoding: <String, Object?>{'field': 'v', 'type': 'nominal'},
      values: <Object?>[
        <String, Object?>{'x': 'a', 'y': 'p', 'v': 'low'},
        <String, Object?>{'x': 'b', 'y': 'p', 'v': 'high'},
      ],
    );
    expect(
      chart.domainValuesForColorScale,
      <double>[0, 1],
      reason:
          'VegaLiteSchemaAdapter.ts:3452-3453: one domain entry per distinct '
          'category, and the entry IS the index.',
    );
    expect(
      chart.data.single.data.first.rectText,
      'low',
      reason:
          'VegaLiteSchemaAdapter.ts:3376 keeps the category name as the cell '
          'text while the value carries its index.',
    );
  });

  FluentPolarChart polar({
    Object? mark,
    Map<String, Object?>? thetaEncoding,
    List<Object?>? values,
  }) => transformVegaToPolar(
    <String, Object?>{
      'mark': mark ?? 'arc',
      'data': <String, Object?>{
        'values':
            values ??
            <Object?>[
              <String, Object?>{'t': 0, 'r': 1},
            ],
      },
      'encoding': <String, Object?>{
        'theta':
            thetaEncoding ??
            <String, Object?>{'field': 't', 'type': 'quantitative'},
        'radius': <String, Object?>{'field': 'r', 'type': 'quantitative'},
      },
    },
    <String, String>{},
    isDark: false,
  );

  test('an arc mark with theta and radius is an area polar series, and '
      'defaults to 400 high', () {
    final chart = polar();
    expect(chart.height, 400, reason: 'VegaLiteSchemaAdapter.ts:3856.');
    expect(
      chart.data.single,
      isA<FluentAreaPolarSeries>(),
      reason:
          'VegaLiteSchemaAdapter.ts:3729 treats an arc mark with theta and '
          "radius as areapolar. The port's series union is sealed rather than "
          'tagged (model/polar_data.dart:104), so the runtime type is what '
          "upstream's `type: 'areapolar'` discriminator spells.",
    );
  });

  test('a point mark falls through to a scatter polar series', () {
    final chart = polar(mark: 'point');
    expect(
      chart.data.single,
      isA<FluentScatterPolarSeries>(),
      reason:
          'VegaLiteSchemaAdapter.ts:3824-3832, the else arm after area and '
          'line.',
    );
    expect(
      chart.data.single.legend,
      'default',
      reason:
          'VegaLiteSchemaAdapter.ts:3749: the literal series name when no '
          'colour field is encoded.',
    );
  });

  test("a line mark's dash and width reach the series line options", () {
    final chart = polar(
      mark: <String, Object?>{
        'type': 'line',
        // 4 and 2 are an arbitrary dash pattern; 3 an arbitrary width.
        'strokeDash': <Object?>[4, 2],
        'strokeWidth': 3,
      },
    );
    final series = chart.data.single;
    expect(
      series,
      isA<FluentLinePolarSeries>(),
      reason: 'VegaLiteSchemaAdapter.ts:3730, :3815-3823.',
    );
    expect(
      (series as FluentLinePolarSeries).lineOptions?.strokeDasharray,
      '4 2',
      reason:
          'VegaLiteSchemaAdapter.ts:3800 joins the dash list with a space, '
          'and JavaScript stringifies 4 as `4` rather than `4.0`.',
    );
    expect(
      series.lineOptions?.strokeWidth,
      3,
      reason: 'VegaLiteSchemaAdapter.ts:3802-3804.',
    );
  });

  test('a categorical theta names the angular axis order', () {
    final chart = polar(
      thetaEncoding: <String, Object?>{'field': 't', 'type': 'nominal'},
      values: <Object?>[
        <String, Object?>{'t': 'north', 'r': 1},
        <String, Object?>{'t': 'east', 'r': 2},
        <String, Object?>{'t': 'north', 'r': 3},
      ],
    );
    expect(
      chart.angularAxis?.categoryOrder,
      isA<FluentAxisCategoryOrderExplicit>().having(
        (order) => order.categories,
        'categories',
        <String>['north', 'east'],
      ),
      reason:
          'VegaLiteSchemaAdapter.ts:3845-3848 casts the DISTINCT theta values, '
          'in first-seen order, into the category-order union — which '
          'model/chart_common.dart:342 spells as its explicit arm.',
    );
  });

  test('a polar spec missing an encoding is rejected with the upstream '
      'message', () {
    expect(
      () => transformVegaToPolar(
        <String, Object?>{
          'mark': 'line',
          'data': <String, Object?>{
            'values': <Object?>[
              <String, Object?>{'t': 1},
            ],
          },
          'encoding': <String, Object?>{
            'theta': <String, Object?>{'field': 't', 'type': 'quantitative'},
          },
        },
        <String, String>{},
        isDark: false,
      ),
      throwsA(
        isA<VegaSpecException>().having(
          (error) => error.message,
          'message',
          'VegaLiteSchemaAdapter: Both theta and radius encodings are '
              'required for polar charts',
        ),
      ),
      reason: 'VegaLiteSchemaAdapter.ts:3718-3720, message verbatim.',
    );
  });
}
