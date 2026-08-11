import 'package:fluent_2_web/src/charts/internal/vega/transforms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<Map<String, Object?>> line(int n) => <Map<String, Object?>>[
    for (var i = 0; i < n; i++) <String, Object?>{'x': i, 'y': 2 * i + 1},
  ];

  test('regression replaces the dataset with exactly two endpoints', () {
    final out = applyVegaTransforms(line(20), <Object?>[
      <String, Object?>{'regression': 'y', 'on': 'x'},
    ]);
    expect(
      out,
      hasLength(2),
      reason: 'VegaLiteSchemaAdapter.ts:436-439 emits xMin and xMax only.',
    );
    expect(
      out.first['y'],
      closeTo(1, 1e-9),
      reason: 'A perfect line y = 2x + 1 gives intercept 1 at x = 0.',
    );
    expect(
      out.last['y'],
      closeTo(39, 1e-9),
      reason:
          'Slope 2 at x = 19 gives 39; the OLS denominator n*sumX2 - sumX*sumX '
          'must not catastrophically cancel here.',
    );
  });

  test('regression needs at least two points and is otherwise a no-op', () {
    final one = <Map<String, Object?>>[
      <String, Object?>{'x': 1, 'y': 1},
    ];
    expect(
      applyVegaTransforms(one, <Object?>[
        <String, Object?>{'regression': 'y', 'on': 'x'},
      ]),
      hasLength(1),
      reason: 'VegaLiteSchemaAdapter.ts:426 guards on points.length >= 2.',
    );
  });

  test('loess keeps every row and uses an asymmetric window at the tails', () {
    final out = applyVegaTransforms(line(20), <Object?>[
      <String, Object?>{'loess': 'y', 'on': 'x'},
    ]);
    expect(
      out,
      hasLength(20),
      reason: 'VegaLiteSchemaAdapter.ts:451-457 maps one-to-one.',
    );
    // windowSize = max(3, floor(20 / 4)) = 5; at i = 0 the window is [0, 5),
    // so the mean of y over x in 0..4 is (1 + 3 + 5 + 7 + 9) / 5 = 5.
    expect(
      out.first['y'],
      closeTo(5, 1e-9),
      reason:
          'VegaLiteSchemaAdapter.ts:450, :452-453: start = max(0, i - '
          'floor(w / 2)) so the first window is NOT centred.',
    );
    // At i = 1 the clamp still pins start to 0, and `:453` measures end from
    // START, not from i — so the window is again [0, 5) and the mean again 5.
    // An end of `min(n, i + w)` would reach x = 5 and give 6.
    expect(
      out[1]['y'],
      closeTo(5, 1e-9),
      reason:
          'VegaLiteSchemaAdapter.ts:453: end = min(n, start + w), so a clamped '
          'start SHRINKS the window rather than sliding it.',
    );
  });

  test('density emits exactly bins + 1 = 21 points per group', () {
    final out = applyVegaTransforms(line(100), <Object?>[
      <String, Object?>{'density': 'y'},
    ]);
    expect(
      out,
      hasLength(21),
      reason:
          'VegaLiteSchemaAdapter.ts:479, :488: bins = 20 and the loop is '
          'i <= bins.',
    );
    expect(
      out.first.keys.toSet(),
      <String>{'value', 'density'},
      reason:
          'VegaLiteSchemaAdapter.ts:492 emits value and density plus the group '
          'fields.',
    );
  });

  test('density counts values strictly inside one bandwidth of the sample '
      'point', () {
    final out = applyVegaTransforms(
      <Map<String, Object?>>[
        <String, Object?>{'v': 0},
        <String, Object?>{'v': 10},
      ],
      <Object?>[
        <String, Object?>{'density': 'v'},
      ],
    );
    // range 10, bandwidth 0.5; at x = 0 exactly one value is within 0.5,
    // so density = 1 / (2 * 0.5) = 1.
    expect(
      out.first['density'],
      closeTo(1, 1e-12),
      reason:
          'VegaLiteSchemaAdapter.ts:490-491: count / (values.length * '
          'bandwidth), with a STRICT less-than on the distance.',
    );
    // The strictness itself only shows at a value exactly one bandwidth away.
    // Over 0 and 20 the range is 20 and the bandwidth 1, so the i = 1 sample
    // point x = 1 sits at distance exactly 1 from the value 0: `<` excludes it
    // and `<=` would not.
    final boundary = applyVegaTransforms(
      <Map<String, Object?>>[
        <String, Object?>{'v': 0},
        <String, Object?>{'v': 20},
      ],
      <Object?>[
        <String, Object?>{'density': 'v'},
      ],
    );
    expect(
      boundary[1]['density'],
      0,
      reason:
          'VegaLiteSchemaAdapter.ts:490 is Math.abs(v - x) < bandwidth, so a '
          'value exactly one bandwidth away does NOT count.',
    );
  });

  test('quantile uses nearest rank, not interpolation', () {
    final out = applyVegaTransforms(
      <Map<String, Object?>>[
        for (final v in <int>[1, 2, 3, 4]) <String, Object?>{'v': v},
      ],
      <Object?>[
        <String, Object?>{'quantile': 'v'},
      ],
    );
    expect(
      out.map((r) => r['value']).toList(),
      <Object?>[2, 3, 4],
      reason:
          'VegaLiteSchemaAdapter.ts:501, :508: probs default to '
          '[0.25, 0.5, 0.75] and the index is min(floor(p * len), len - 1), '
          'i.e. 1, 2 and 3.',
    );
    expect(
      out.first['prob'],
      '0.25',
      reason: 'VegaLiteSchemaAdapter.ts:509 stringifies the probability.',
    );
  });

  test('impute fills every missing integer key from min to max', () {
    final out = applyVegaTransforms(
      <Map<String, Object?>>[
        <String, Object?>{'k': 1, 'v': 10},
        <String, Object?>{'k': 4, 'v': 40},
      ],
      <Object?>[
        <String, Object?>{'impute': 'v', 'key': 'k', 'value': -1},
      ],
    );
    expect(
      out.map((r) => r['k']).toList(),
      <Object?>[1, 2, 3, 4],
      reason:
          'VegaLiteSchemaAdapter.ts:524-526 walks integers from minKey to '
          'maxKey inclusive.',
    );
    expect(
      out[1]['v'],
      -1,
      reason:
          "VegaLiteSchemaAdapter.ts:518, :529: method defaults to 'value' so "
          'transform.value is used.',
    );
  });

  test('impute matches existing keys on the RAW cell, so a stringified key is '
      'imputed again', () {
    final out = applyVegaTransforms(
      <Map<String, Object?>>[
        <String, Object?>{'k': 1, 'v': 10},
        <String, Object?>{'k': '4', 'v': 40},
      ],
      <Object?>[
        <String, Object?>{'impute': 'v', 'key': 'k', 'value': -1},
      ],
    );
    // The Set at `:521` holds '4', which never equals the number 4 the loop
    // walks, so maxKey itself is imputed: 1, the two gaps, the original '4'
    // row and a numeric 4. This is the only fixture in which the loop's
    // INCLUSIVE upper bound is observable.
    expect(
      out,
      hasLength(5),
      reason:
          "VegaLiteSchemaAdapter.ts:521, :526: existingKeys holds the raw '4' "
          'while `k <= maxKey` still reaches the number 4.',
    );
    expect(
      out.last['v'],
      -1,
      reason:
          'VegaLiteSchemaAdapter.ts:533 sorts on Number(key) and is stable, so '
          "the imputed 4 lands after the original '4' row.",
    );
  });

  test('a missing cell reads as undefined, not as zero', () {
    final out = applyVegaTransforms(
      <Map<String, Object?>>[
        for (final v in <int>[1, 2, 3, 4]) <String, Object?>{'v': v},
        <String, Object?>{'other': 9},
      ],
      <Object?>[
        <String, Object?>{'quantile': 'v'},
      ],
    );
    // Number(undefined) is NaN, which `:504` drops; Number(null) would be 0 and
    // would both survive the filter and sort to the front, shifting every rank.
    expect(
      out.map((r) => r['value']).toList(),
      <Object?>[2, 3, 4],
      reason:
          'VegaLiteSchemaAdapter.ts:503-504: a row without the field '
          'contributes nothing, so values.length stays 4.',
    );
  });

  test('an aggregate mean skips a row that lacks the column', () {
    final out = applyVegaTransforms(
      <Map<String, Object?>>[
        <String, Object?>{'g': 'a', 'v': 10},
        <String, Object?>{'g': 'a'},
      ],
      <Object?>[
        <String, Object?>{
          'aggregate': <Object?>[
            <String, Object?>{'op': 'mean', 'field': 'v', 'as': 'm'},
          ],
          'groupby': <Object?>['g'],
        },
      ],
    );
    expect(
      out.single['m'],
      10,
      reason:
          'VegaLiteSchemaAdapter.ts:281 filters Number(undefined) out, so the '
          'mean is over one value; treating the absent cell as 0 would give 5.',
    );
  });

  test('lookup joins only the named fields from an inline dataset', () {
    final out = applyVegaTransforms(
      <Map<String, Object?>>[
        <String, Object?>{'id': 'a'},
      ],
      <Object?>[
        <String, Object?>{
          'lookup': 'id',
          'from': <String, Object?>{
            'data': <String, Object?>{
              'values': <Object?>[
                <String, Object?>{'id': 'a', 'label': 'Alpha', 'secret': 'no'},
              ],
            },
            'key': 'id',
            'fields': <Object?>['label'],
          },
        },
      ],
    );
    expect(
      out.single['label'],
      'Alpha',
      reason: 'VegaLiteSchemaAdapter.ts:550-560.',
    );
    expect(
      out.single.containsKey('secret'),
      isFalse,
      reason: 'VegaLiteSchemaAdapter.ts:553-556 copies only the listed fields.',
    );
  });

  test('a chained pipeline runs the transforms in array order', () {
    final out = applyVegaTransforms(
      <Map<String, Object?>>[
        <String, Object?>{'g': 'a', 'v': 1},
        <String, Object?>{'g': 'a', 'v': 9},
        <String, Object?>{'g': 'b', 'v': 5},
      ],
      <Object?>[
        <String, Object?>{'filter': 'datum.v > 2'},
        <String, Object?>{'calculate': 'datum.v * 10', 'as': 'big'},
        <String, Object?>{
          'aggregate': <Object?>[
            <String, Object?>{'op': 'sum', 'field': 'big', 'as': 'total'},
          ],
          'groupby': <Object?>['g'],
        },
      ],
    );
    expect(
      out.map((r) => r['total']).toList(),
      <Object?>[90, 50],
      reason: 'VegaLiteSchemaAdapter.ts:224 iterates the array in order.',
    );
  });
}
