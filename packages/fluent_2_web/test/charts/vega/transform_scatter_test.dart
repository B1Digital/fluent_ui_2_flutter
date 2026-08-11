import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/vega/transform_line.dart';
import 'package:flutter/widgets.dart' show Color;
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentScatterChart build(
    Map<String, Object?> encoding,
    List<Object?> values,
  ) => transformVegaToScatter(
    <String, Object?>{
      'mark': 'point',
      'data': <String, Object?>{'values': values},
      'encoding': encoding,
    },
    <String, String>{},
    isDark: false,
  );

  test('every scatter series draws a circle swatch', () {
    final chart = build(
      <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
        'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
      },
      <Object?>[
        <String, Object?>{'x': 1, 'y': 2},
      ],
    );
    expect(
      chart.data.scatterChartData!.single.legendShape,
      FluentChartLegendShape.circle,
      reason: 'ts:3173.',
    );
  });

  test('a colour field splits the points into one series per category', () {
    final chart = build(
      <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
        'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
        'color': <String, Object?>{'field': 'c', 'type': 'nominal'},
      },
      <Object?>[
        <String, Object?>{'x': 1, 'y': 2, 'c': 'a'},
        <String, Object?>{'x': 3, 'y': 4, 'c': 'b'},
      ],
    );
    expect(
      chart.data.scatterChartData!.map((series) => series.legend).toList(),
      <String>['a', 'b'],
      reason: 'ts:3070-3170 groups by the colour field.',
    );
  });

  test(
    'a nominal y uses the same half-unit padding as the line transformer',
    () {
      final chart = build(
        <String, Object?>{
          'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
          'y': <String, Object?>{'field': 'y', 'type': 'nominal'},
        },
        <Object?>[
          <String, Object?>{'x': 1, 'y': 'p'},
          <String, Object?>{'x': 2, 'y': 'q'},
          <String, Object?>{'x': 3, 'y': 'r'},
        ],
      );
      expect(chart.props.yMinValue, -0.5, reason: 'ts:3208.');
      expect(
        chart.props.yMaxValue,
        2.5,
        reason: 'ts:3209: n - 0.5 with n = 3.',
      );
    },
  );

  test('no height default, unlike the stacked bar and heatmap transformers', () {
    final chart = build(
      <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
        'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
      },
      <Object?>[
        <String, Object?>{'x': 1, 'y': 2},
      ],
    );
    expect(
      chart.props.hideLegend,
      isFalse,
      reason:
          'ts:3212 defaults hideLegend to false. ts:3070-3232 sets no height '
          'either, and FluentScatterChart is a shell chart with no height '
          'parameter, so nothing here needs unwrapping — a spec height reaches '
          'the chart as the SizedBox task 52 wraps it in.',
    );
  });

  test('the legend disable flag is honoured', () {
    final chart = build(
      <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
        'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
        'color': <String, Object?>{
          'field': 'c',
          'legend': <String, Object?>{'disable': true},
        },
      },
      <Object?>[
        <String, Object?>{'x': 1, 'y': 2, 'c': 'a'},
      ],
    );
    expect(chart.props.hideLegend, isTrue, reason: 'ts:3212.');
  });

  test('a nominal y renames each index and plots the points at it', () {
    final chart = build(
      <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
        'y': <String, Object?>{
          'field': 'y',
          'type': 'nominal',
          'axis': <String, Object?>{'format': '.2f'},
        },
      },
      <Object?>[
        <String, Object?>{'x': 1, 'y': 'p'},
        <String, Object?>{'x': 2, 'y': 'q'},
        <String, Object?>{'x': 3, 'y': 'p'},
      ],
    );
    expect(
      chart.props.yAxisTickValues,
      <Object>[0, 1],
      reason:
          'ts:3206 emits one tick per DISTINCT label, so the repeated p is not '
          'a third tick.',
    );
    expect(
      <String>[
        chart.props.yAxisTickFormat!(0),
        chart.props.yAxisTickFormat!(1),
        chart.props.yAxisTickFormat!(7),
      ],
      <String>['p', 'q', '7'],
      reason:
          'ts:3207 renames an index to its label and falls back to String(val) '
          'off the end of the list. The renamer also wins over the `.2f` at '
          'ts:3198, which is spread earlier and would have answered "0.00".',
    );
    expect(
      chart.data.scatterChartData!.single.data.map((point) => point.y).toList(),
      <double>[0, 1, 0],
      reason:
          'ts:3135-3138 replaces a categorical y by its first-seen ordinal, so '
          'the third row shares p with the first.',
    );
  });

  test('a colour range is indexed by the series ordinal', () {
    final chart = transformVegaToScatter(
      <String, Object?>{
        'mark': <String, Object?>{'type': 'point', 'color': '#0000ff'},
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'x': 1, 'y': 2, 'c': 'a'},
            <String, Object?>{'x': 3, 'y': 4, 'c': 'b'},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
          'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
          'color': <String, Object?>{
            'field': 'c',
            'type': 'nominal',
            'scale': <String, Object?>{
              'range': <Object?>['#ff0000'],
            },
          },
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(
      chart.data.scatterChartData!.first.color,
      const Color(0xffff0000),
      reason: 'ts:3150 reads range[index] for the first series.',
    );
    expect(
      chart.data.scatterChartData!.last.color,
      isNot(const Color(0xff0000ff)),
      reason:
          'ts:3150 reads range[1] on a one-entry array, which is undefined, so '
          'ts:3152 fails its string test and ts:3155-3164 resolves a palette '
          "colour. It does NOT fall back to the mark's own #0000ff — the mark "
          'colour is the other arm of the ts:3148-3151 conditional, not a '
          'second fallback inside it.',
    );
  });

  test('a named colour scheme is ignored on the scatter path', () {
    FluentScatterChart withScheme(Object? scheme) => transformVegaToScatter(
      <String, Object?>{
        'mark': 'point',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'x': 1, 'y': 2, 'c': 'a'},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
          'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
          'color': <String, Object?>{
            'field': 'c',
            'type': 'nominal',
            if (scheme != null) 'scale': <String, Object?>{'scheme': scheme},
          },
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(
      withScheme('blues').data.scatterChartData!.single.color,
      withScheme(null).data.scatterChartData!.single.color,
      reason:
          'ts:3161-3162 passes undefined for both the scheme and the range, so '
          'a declared scale.scheme changes nothing here even though '
          'scale.range at ts:3150 is honoured. // parity.',
    );
  });

  test('a size column becomes the marker size and an absent one does not', () {
    final chart = build(
      <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
        'y': <String, Object?>{'field': 'y', 'type': 'quantitative'},
        'size': <String, Object?>{'field': 's', 'type': 'quantitative'},
      },
      <Object?>[
        <String, Object?>{'x': 1, 'y': 2, 's': 12},
        <String, Object?>{'x': 3, 'y': 4},
      ],
    );
    expect(
      chart.data.scatterChartData!.single.data
          .map((point) => point.markerSize)
          .toList(),
      <double?>[12, null],
      reason:
          'ts:3132: `sizeField && row[sizeField] !== undefined`, so the row '
          'without the column carries no marker size at all rather than a zero.',
    );
  });

  test('a spec missing either axis is rejected', () {
    expect(
      () => build(
        <String, Object?>{
          'x': <String, Object?>{'field': 'x', 'type': 'quantitative'},
        },
        <Object?>[
          <String, Object?>{'x': 1},
        ],
      ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Both x and y encodings are required for scatter charts'),
        ),
      ),
      reason: 'ts:3081-3083, message verbatim.',
    );
  });
}
