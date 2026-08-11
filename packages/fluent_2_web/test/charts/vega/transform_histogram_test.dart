import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/internal/vega/transform_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentVerticalBarChart build(List<Object?> values, {Object? bin = true}) =>
      transformVegaToHistogram(
        <String, Object?>{
          'mark': 'bar',
          'data': <String, Object?>{'values': values},
          'encoding': <String, Object?>{
            'x': <String, Object?>{
              'field': 'v',
              'type': 'quantitative',
              'bin': bin,
            },
            'y': <String, Object?>{'aggregate': 'count'},
          },
        },
        <String, String>{},
        isDark: false,
      );

  test('the injected scalar defaults', () {
    final chart = build(<Object?>[
      for (var i = 0; i < 20; i++) <String, Object?>{'v': i},
    ]);
    expect(chart.roundCorners, isTrue, reason: 'ts:3688.');
    expect(
      chart.maxBarWidth,
      50,
      reason: 'ts:3690 uses DEFAULT_MAX_BAR_WIDTH (ts:75).',
    );
    expect(chart.mode, 'histogram', reason: 'ts:3693.');
    expect(chart.props.hideTickOverlap, isTrue, reason: 'ts:3689.');
  });

  test('the callout string is the half-open interval, exactly', () {
    final chart = build(<Object?>[
      for (var i = 0; i < 20; i++) <String, Object?>{'v': i},
    ]);
    expect(
      chart.data.first.xAxisCalloutData,
      matches(RegExp(r'^\[.+ - .+\)$')),
      reason: r'ts:3667 formats it as `[${bin.x0} - ${bin.x1})`.',
    );
    expect(
      chart.data.first.xAxisCalloutData,
      '[0 - 5)',
      reason:
          'the edges go through the same number-to-string rule JavaScript '
          'template interpolation uses, so an integral edge carries no `.0` — '
          "Dart's own `toString` would write `[0.0 - 5.0)` and still satisfy "
          'the shape above. 0 and 5 are the first bin of 20 rows over [0, 19]: '
          "Sturges asks for ceil(log2(20)) + 1 = 6 bins, d3's tick generator "
          'answers a step of 5.',
    );
    expect(
      chart.data.first.x,
      2.5,
      reason:
          'ts:3642 plots the bar at the bin MID-POINT (ts:3524-3526), which for '
          '[0, 5) is 2.5 rather than either edge.',
    );
  });

  test('maxbins is forwarded to the threshold count', () {
    final rows = <Object?>[
      for (var i = 0; i < 20; i++) <String, Object?>{'v': i},
    ];
    expect(
      build(rows, bin: <String, Object?>{'maxbins': 2}).data.length,
      2,
      reason:
          "ts:3626-3628 hands maxbins to d3's threshold COUNT, so 2 over "
          '[0, 19] asks for a step of 10 and yields [0, 10) and [10, 19]. '
          "Ignore maxbins and Sturges' default answers 4 bins instead.",
    );
    expect(
      build(rows).data.length,
      4,
      reason:
          'the same rows with no maxbins take the default threshold function, '
          'which is the count this test contrasts against.',
    );
  });

  test('the default legend is the literal Frequency', () {
    final chart = build(<Object?>[
      for (var i = 0; i < 20; i++) <String, Object?>{'v': i},
    ]);
    expect(chart.data.first.legend, 'Frequency', reason: 'ts:3637.');
  });

  test('the last bin is inclusive on the right', () {
    final chart = build(<Object?>[
      for (var i = 0; i <= 10; i++) <String, Object?>{'v': i},
    ]);
    final total = chart.data.map((d) => d.y).reduce((a, b) => a + b);
    expect(
      total,
      11,
      reason:
          "d3.bin's final bin is closed on the right, so the maximum lands in "
          'it rather than in a degenerate bin of its own, and no row is lost. '
          'ts:3654-3661 restates that rule by hand for the non-count '
          'aggregates, where the rows are re-filtered with a half-open '
          '`x >= x0 && x < x1` at ts:3650 and the maximum would otherwise be '
          'dropped.',
    );
  });

  // The plan's `count` case above exercises `d3.bin` alone; the hand-written
  // restatement of the same rule at ts:3654-3661 only runs on the NON-count
  // path, which nothing else here reaches.
  test('a non-count aggregate adds the maximum back to the final bin', () {
    final chart = transformVegaToHistogram(
      <String, Object?>{
        'mark': 'bar',
        'data': <String, Object?>{
          'values': <Object?>[
            for (var i = 0; i <= 10; i++) <String, Object?>{'v': i, 'w': 2},
          ],
        },
        'encoding': <String, Object?>{
          'x': <String, Object?>{
            'field': 'v',
            'type': 'quantitative',
            'bin': true,
          },
          'y': <String, Object?>{'field': 'w', 'aggregate': 'sum'},
        },
      },
      <String, String>{},
      isDark: false,
    );
    expect(
      chart.data.last.y,
      6,
      reason:
          'the final bin spans [8, 10] and every row carries w = 2. The '
          'half-open re-filter at ts:3649-3650 selects v = 8 and v = 9 only, '
          'summing w to 4; ts:3655-3661 then appends every row whose v equals '
          "the bin's x1 exactly, which is the single v = 10 row, for 6. Drop "
          'that block and this reads 4; count the rows instead of summing w '
          'and it reads 3.',
    );
  });

  test('a string column is rejected with the suggestion its shape earns', () {
    expect(
      () => build(<Object?>[
        <String, Object?>{'v': 'apples'},
        <String, Object?>{'v': 'pears'},
      ]),
      throwsA(
        isA<Object>().having(
          (e) => e.toString(),
          'message',
          allOf(
            contains(
              'No numeric values found for histogram binning on field '
              '"v"',
            ),
            contains('Found string values instead.'),
            contains('The data contains categorical strings (e.g., "apples")'),
          ),
        ),
      ),
      reason: 'ts:3605-3608 and ts:3614-3617.',
    );
    expect(
      () => build(<Object?>[
        <String, Object?>{'v': '40 salads'},
      ]),
      throwsA(
        isA<Object>().having(
          (e) => e.toString(),
          'message',
          contains('The data contains strings with embedded numbers'),
        ),
      ),
      reason: 'ts:3599-3603: any decimal digit in any value takes this arm.',
    );
  });

  test(
    'the axis titles fall back to the field name and the aggregate name',
    () {
      final chart = build(<Object?>[
        for (var i = 0; i < 20; i++) <String, Object?>{'v': i},
      ]);
      expect(chart.props.xAxisTitle, 'v', reason: 'ts:3685.');
      expect(chart.props.yAxisTitle, 'count', reason: 'ts:3686.');
    },
  );
}
