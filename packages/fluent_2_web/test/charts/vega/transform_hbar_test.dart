import 'package:fluent_2_web/src/charts/internal/vega/spec.dart';
import 'package:fluent_2_web/src/charts/internal/vega/transform_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'the grouped transformer rejects a spec missing any of x, y or color',
    () {
      for (final missing in <String>['x', 'y', 'color']) {
        final encoding = <String, Object?>{
          'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
          'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
          'color': <String, Object?>{'field': 'g', 'type': 'nominal'},
        }..remove(missing);
        expect(
          () => transformVegaToGroupedBar(
            <String, Object?>{
              'mark': 'bar',
              'data': <String, Object?>{
                'values': <Object?>[
                  <String, Object?>{'c': 'a', 'v': 1, 'g': 'p'},
                ],
              },
              'encoding': encoding,
            },
            <String, String>{},
            isDark: false,
          ),
          throwsA(isA<VegaSpecException>()),
          reason: 'ts:2752-2754 throws when $missing is absent.',
        );
      }
    },
  );

  test(
    'the grouped transformer injects no height, round corners or truncation',
    () {
      final chart = transformVegaToGroupedBar(
        <String, Object?>{
          'mark': 'bar',
          'data': <String, Object?>{
            'values': <Object?>[
              <String, Object?>{'c': 'a', 'v': 1, 'g': 'p'},
            ],
          },
          'encoding': <String, Object?>{
            'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
            'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
            'color': <String, Object?>{'field': 'g', 'type': 'nominal'},
          },
        },
        <String, String>{},
        isDark: false,
      );
      expect(
        chart.props.hideTickOverlap,
        isTrue,
        reason:
            'ts:2741-2829 sets only titles and y-axis format, domain and scale '
            'type — no height, no roundCorners, no truncation — so every other '
            'property is the shell default, and `hideTickOverlap` defaults to '
            'true in cartesian_chart_props.dart. // parity',
      );
      expect(
        chart.roundCorners,
        isFalse,
        reason:
            'ts:2819-2828 spreads no roundCorners, so the widget default at '
            'grouped_vertical_bar_chart.dart:1050 stands.',
      );
    },
  );

  test(
    'the grouped transformer keys, legends and groups by the raw strings',
    () {
      final chart = transformVegaToGroupedBar(
        <String, Object?>{
          'mark': 'bar',
          'data': <String, Object?>{
            'values': <Object?>[
              <String, Object?>{'c': 'a', 'v': 1, 'g': 'p'},
              <String, Object?>{'c': 'a', 'v': 2, 'g': 'q'},
              <String, Object?>{'c': 'a', 'v': 9, 'g': 'p'},
              <String, Object?>{'c': 'b', 'v': 3, 'g': 'p'},
            ],
          },
          'encoding': <String, Object?>{
            'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
            'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
            'color': <String, Object?>{'field': 'g', 'type': 'nominal'},
          },
        },
        <String, String>{},
        isDark: false,
      );
      expect(
        chart.data.map((group) => group.name).toList(),
        <String>['a', 'b'],
        reason:
            'ts:2788 iterates `Object.keys(groupedData)` in insertion order.',
      );
      expect(
        chart.data.first.series.map((point) => point.data).toList(),
        <double>[9, 2],
        reason:
            'ts:2780 assigns into a nested map, so the third row OVERWRITES the '
            'first rather than accumulating: legend `p` keeps 9, not 1 and not '
            '10. // parity',
      );
      expect(
        chart.data.first.series.first.key,
        chart.data.first.series.first.legend,
        reason: 'ts:2789-2791 uses the same string for `key` and `legend`.',
      );
    },
  );

  test('the grouped transformer drops a non-numeric y and holds its colours', () {
    final colorMap = <String, String>{};
    final chart = transformVegaToGroupedBar(
      <String, Object?>{
        'mark': 'bar',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'c': 'a', 'v': '1', 'g': 'p'},
            <String, Object?>{'c': 'a', 'v': 2, 'g': 'q'},
            <String, Object?>{'c': 'b', 'v': 3, 'g': 'q'},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'c', 'type': 'nominal'},
          'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
          'color': <String, Object?>{
            'field': 'g',
            'type': 'nominal',
            'scale': <String, Object?>{
              'range': <Object?>['#ff0000', '#00ff00'],
            },
          },
        },
      },
      colorMap,
      isDark: false,
    );
    expect(
      chart.data.first.series.single.legend,
      'q',
      reason:
          "ts:2769-2771 drops the row whose y is the STRING '1', because the "
          'guard is `typeof yValue !== \'number\'`.',
    );
    expect(
      colorMap['q'],
      '#ff0000',
      reason:
          'ts:2793-2802 forwards colorScheme and colorRange, so the declared '
          "range's first entry colours the first legend seen.",
    );
    expect(
      chart.data.last.series.single.color,
      chart.data.first.series.single.color,
      reason:
          'ts:2126-2131 caches by legend, so the same group is the same colour '
          'in every category.',
    );
  });

  test('the horizontal transformer requires a y field unless x aggregates', () {
    expect(
      () => transformVegaToHorizontalBar(
        <String, Object?>{
          'mark': 'bar',
          'data': <String, Object?>{
            'values': <Object?>[
              <String, Object?>{'v': 1},
            ],
          },
          'encoding': <String, Object?>{
            'x': <String, Object?>{'field': 'v', 'type': 'quantitative'},
          },
        },
        <String, String>{},
        isDark: false,
      ),
      throwsA(isA<VegaSpecException>()),
      reason: 'ts:2856-2858.',
    );
  });

  test('an x aggregate makes one bar per y category, legend equal to it', () {
    final chart = transformVegaToHorizontalBar(
      <String, Object?>{
        'mark': 'bar',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'c': 'a', 'v': 1},
            <String, Object?>{'c': 'a', 'v': 4},
            <String, Object?>{'c': 'b', 'v': 2},
          ],
        },
        'encoding': <String, Object?>{
          'y': <String, Object?>{'field': 'c', 'type': 'nominal'},
          'x': <String, Object?>{
            'field': 'v',
            'type': 'quantitative',
            'aggregate': 'sum',
          },
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(
      chart.data.map((point) => point.x).toList(),
      <double>[5, 2],
      reason:
          'ts:2861-2864 passes the y field as the GROUP and the x field as the '
          'value, the reverse of the stacked bar call.',
    );
    expect(
      chart.data.first.legend,
      'a',
      reason: 'ts:2872 makes the legend the category itself.',
    );
    expect(
      chart.props.hideLegend,
      isTrue,
      reason:
          'ts:2989: no colour field hides the legend even when aggregating.',
    );
  });

  test('a temporal x2 becomes a rounded day count', () {
    final chart = transformVegaToHorizontalBar(
      <String, Object?>{
        'mark': 'bar',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{
              'task': 'design',
              'start': '2024-01-01',
              'end': '2024-01-04T12:00:00',
            },
          ],
        },
        'encoding': <String, Object?>{
          'y': <String, Object?>{'field': 'task', 'type': 'nominal'},
          'x': <String, Object?>{'field': 'start', 'type': 'temporal'},
          'x2': <String, Object?>{'field': 'end'},
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(
      chart.data.single.x,
      4,
      reason:
          'ts:2916: Math.round((end - start) / (1000 * 60 * 60 * 24)); 3.5 days '
          'rounds half-UP to 4 under jsRound.',
    );
    expect(
      chart.data.single.legend,
      'design',
      reason:
          "ts:2924: with no colour field the span's legend is the CATEGORY, "
          "not 'Bar' — the plain branch below is the only one that says 'Bar'.",
    );
  });

  test('an unparseable temporal endpoint drops the span', () {
    final chart = transformVegaToHorizontalBar(
      <String, Object?>{
        'mark': 'bar',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{
              'task': 'a',
              'start': 'never',
              'end': '2024-01-04',
            },
            <String, Object?>{
              'task': 'b',
              'start': '2024-01-01',
              'end': '2024-01-03',
            },
          ],
        },
        'encoding': <String, Object?>{
          'y': <String, Object?>{'field': 'task', 'type': 'nominal'},
          'x': <String, Object?>{'field': 'start', 'type': 'temporal'},
          'x2': <String, Object?>{'field': 'end'},
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(
      chart.data.map((point) => point.y).toList(),
      <Object>['b'],
      reason:
          "ts:2913 drops a row whose Date is Invalid, so only 'b' survives.",
    );
  });

  test('a non-temporal x2 subtracts the raw numbers', () {
    final chart = transformVegaToHorizontalBar(
      <String, Object?>{
        'mark': 'bar',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'task': 'a', 'start': 2, 'end': 7},
          ],
        },
        'encoding': <String, Object?>{
          'y': <String, Object?>{'field': 'task', 'type': 'nominal'},
          'x': <String, Object?>{'field': 'start', 'type': 'quantitative'},
          'x2': <String, Object?>{'field': 'end'},
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(
      chart.data.single.x,
      5,
      reason: 'ts:2917-2918: Number(end) - Number(start).',
    );
  });

  test(
    'a horizontal bar with no colour field hides its legend and labels every bar Bar',
    () {
      final chart = transformVegaToHorizontalBar(
        <String, Object?>{
          'mark': 'bar',
          'data': <String, Object?>{
            'values': <Object?>[
              <String, Object?>{'c': 'a', 'v': 1},
            ],
          },
          'encoding': <String, Object?>{
            'y': <String, Object?>{'field': 'c', 'type': 'nominal'},
            'x': <String, Object?>{'field': 'v', 'type': 'quantitative'},
          },
        },
        <String, String>{},
        isDark: false,
      );
      expect(chart.props.hideLegend, isTrue, reason: 'ts:2989.');
      expect(chart.data.single.legend, 'Bar', reason: 'ts:2952.');
      expect(
        chart.props.annotations,
        isEmpty,
        reason:
            'ts:2992-2994 assigns annotations only when non-empty, and this spec '
            'has no rule or text layer. ts:2841-3009 also injects no height, '
            'width or roundCorners at all — unlike the Plotly horizontal bar '
            'transformer, which computes a bar height at '
            'PlotlySchemaAdapter.ts:2263-2270. // parity',
      );
      expect(
        chart.props.xAxisTickCount,
        6,
        reason:
            'ts:3000-3002 spreads xAxisTickCount only when truthy, so the shell '
            'default of 6 at cartesian_chart_props.dart:96 stands for a spec '
            'that declares none.',
      );
    },
  );

  test('a colour field decides the legend row by row, and legend.disable wins', () {
    final chart = transformVegaToHorizontalBar(
      <String, Object?>{
        'mark': 'bar',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'c': 'a', 'v': 1, 'g': 'p'},
            <String, Object?>{'c': 'b', 'v': 2},
            <String, Object?>{'c': 'd', 'v': 'x', 'g': 'p'},
          ],
        },
        'encoding': <String, Object?>{
          'y': <String, Object?>{'field': 'c', 'type': 'nominal'},
          'x': <String, Object?>{'field': 'v', 'type': 'quantitative'},
          'color': <String, Object?>{
            'field': 'g',
            'type': 'nominal',
            'legend': <String, Object?>{'disable': true},
          },
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(
      chart.data.map((point) => point.legend).toList(),
      <String>['p', 'b'],
      reason:
          'ts:2952: a present colour value wins; a colour field whose value is '
          'absent on the row falls back to the y value; and ts:2946-2948 drops '
          "the third row outright because its x is the STRING 'x'.",
    );
    expect(
      chart.props.hideLegend,
      isTrue,
      reason:
          "ts:2989: with a colour field, the encoding's legend.disable decides.",
    );
  });

  test('a declared tick config reaches the horizontal bar props', () {
    final chart = transformVegaToHorizontalBar(
      <String, Object?>{
        'mark': 'bar',
        'data': <String, Object?>{
          'values': <Object?>[
            <String, Object?>{'c': 'a', 'v': 1},
          ],
        },
        'encoding': <String, Object?>{
          'y': <String, Object?>{
            'field': 'c',
            'type': 'nominal',
            'axis': <String, Object?>{'tickCount': 3},
          },
          'x': <String, Object?>{
            'field': 'v',
            'type': 'quantitative',
            'axis': <String, Object?>{
              'tickCount': 9,
              'values': <Object?>[0, 1],
            },
          },
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(chart.props.xAxisTickCount, 9, reason: 'ts:3000-3002.');
    expect(chart.props.yAxisTickCount, 3, reason: 'ts:3004-3006.');
    expect(
      chart.props.tickValues,
      <Object>[0, 1],
      reason: 'ts:2996-2998, from `encoding.x.axis.values`.',
    );
  });
}
