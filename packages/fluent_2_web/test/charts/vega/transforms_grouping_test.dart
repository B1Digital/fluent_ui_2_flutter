import 'package:fluent_2_web/src/charts/internal/vega/transforms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<Map<String, Object?>> rows() => <Map<String, Object?>>[
    <String, Object?>{'g': 'a', 'v': 1},
    <String, Object?>{'g': 'a', 'v': 3},
    <String, Object?>{'g': 'b', 'v': 5},
  ];

  test('fold defaults its output names to key and value', () {
    final out = applyVegaTransforms(
      <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'p': 10, 'q': 20},
      ],
      <Object?>[
        <String, Object?>{
          'fold': <Object?>['p', 'q'],
        },
      ],
    );
    expect(
      out,
      hasLength(2),
      reason:
          'VegaLiteSchemaAdapter.ts:192-200 emits one row per folded field.',
    );
    expect(
      out.first['key'],
      'p',
      reason: 'VegaLiteSchemaAdapter.ts:228 defaults as to [key, value].',
    );
    expect(out.first['value'], 10, reason: 'VegaLiteSchemaAdapter.ts:228.');
    expect(
      out.first['id'],
      1,
      reason:
          'VegaLiteSchemaAdapter.ts:184-189 carries every non-folded '
          'column onto each emitted row.',
    );
  });

  test('applyFoldTransform carries its own defaults and skips absent fields', () {
    // Called directly rather than through the transform loop: the loop supplies
    // ['key', 'value'] itself at the `VegaLiteSchemaAdapter.ts:228` position, so
    // the defaults on the parameter at `:177` are a SECOND copy of the same two
    // names and nothing reaching the function through `applyVegaTransforms` can
    // tell them apart. Upstream carries both copies too; this is what keeps them
    // equal.
    final out = applyFoldTransform(
      <Map<String, Object?>>[
        <String, Object?>{'id': 1, 'p': 10},
      ],
      <String>['p', 'absent'],
      const <String>[],
    );
    expect(
      out.map((row) => <Object?>[row['key'], row['value'], row['id']]).toList(),
      <List<Object?>>[
        <Object?>['p', 10, 1],
      ],
      reason:
          "VegaLiteSchemaAdapter.ts:177 defaults asFields to ['key', 'value'], "
          'and `:193` emits nothing for a folded field the row does not carry.',
    );
  });

  test('a filter whose expression throws KEEPS the row', () {
    final out = applyVegaTransforms(rows(), <Object?>[
      <String, Object?>{'filter': 'globalThis'},
    ]);
    expect(
      out,
      hasLength(3),
      reason:
          'VegaLiteSchemaAdapter.ts:239-241 catches and returns true, so an '
          'unparseable filter is a no-op rather than an empty chart. // parity',
    );
  });

  test('a filter selects with JavaScript truthiness', () {
    final out = applyVegaTransforms(rows(), <Object?>[
      <String, Object?>{'filter': 'datum.v > 2'},
    ]);
    expect(
      out.map((row) => row['v']).toList(),
      <Object?>[3, 5],
      reason: 'VegaLiteSchemaAdapter.ts:233-243.',
    );
  });

  test('a filter keeps a row only when the result is JavaScript-truthy', () {
    final out = applyVegaTransforms(
      <Map<String, Object?>>[
        <String, Object?>{'v': 0},
        <String, Object?>{'v': 2},
      ],
      <Object?>[
        <String, Object?>{'filter': 'datum.v'},
      ],
    );
    expect(
      out.map((row) => row['v']).toList(),
      <Object?>[2],
      reason:
          'VegaLiteSchemaAdapter.ts:238 hands the raw result to '
          'Array.prototype.filter, which applies JavaScript truthiness, so 0 '
          'drops the row.',
    );
  });

  test('a calculate whose expression throws leaves the row unchanged', () {
    final out = applyVegaTransforms(rows(), <Object?>[
      <String, Object?>{'calculate': 'globalThis', 'as': 'x'},
    ]);
    expect(
      out.first.containsKey('x'),
      isFalse,
      reason:
          'VegaLiteSchemaAdapter.ts:254-256 returns the untouched row on error.',
    );
  });

  test('aggregate groups by the joined key and supports six ops', () {
    final out = applyVegaTransforms(rows(), <Object?>[
      <String, Object?>{
        'aggregate': <Object?>[
          <String, Object?>{'op': 'sum', 'field': 'v', 'as': 's'},
          <String, Object?>{'op': 'mean', 'field': 'v', 'as': 'm'},
          <String, Object?>{'op': 'count', 'as': 'c'},
          <String, Object?>{'op': 'min', 'field': 'v', 'as': 'lo'},
          <String, Object?>{'op': 'max', 'field': 'v', 'as': 'hi'},
        ],
        'groupby': <Object?>['g'],
      },
    ]);
    expect(out, hasLength(2), reason: 'Two groups.');
    expect(
      out.first['g'],
      'a',
      reason:
          'VegaLiteSchemaAdapter.ts:276-278 copies each group column off the '
          'first row of the group.',
    );
    expect(out.first['s'], 4, reason: 'VegaLiteSchemaAdapter.ts:286-288.');
    expect(out.first['m'], 2, reason: 'VegaLiteSchemaAdapter.ts:289-292.');
    expect(out.first['c'], 2, reason: 'VegaLiteSchemaAdapter.ts:283-285.');
    expect(out.first['lo'], 1, reason: 'VegaLiteSchemaAdapter.ts:293-295.');
    expect(out.first['hi'], 3, reason: 'VegaLiteSchemaAdapter.ts:296-298.');
  });

  test('an aggregate op with no field reads the empty list', () {
    final out = applyVegaTransforms(rows(), <Object?>[
      <String, Object?>{
        'aggregate': <Object?>[
          <String, Object?>{'op': 'sum', 'as': 's'},
          <String, Object?>{'op': 'min', 'as': 'lo'},
        ],
        'groupby': <Object?>['g'],
      },
    ]);
    expect(
      out.first['s'],
      0,
      reason:
          'VegaLiteSchemaAdapter.ts:281 reads [] when spec.field is absent, and '
          'd3Sum([]) is 0.',
    );
    expect(
      out.first['lo'],
      0,
      reason:
          'VegaLiteSchemaAdapter.ts:294 falls through d3Min([]) to its ?? 0.',
    );
  });

  test('an unknown aggregate op falls back to the row count', () {
    final out = applyVegaTransforms(rows(), <Object?>[
      <String, Object?>{
        'aggregate': <Object?>[
          <String, Object?>{'op': 'median', 'field': 'v', 'as': 'x'},
        ],
        'groupby': <Object?>['g'],
      },
    ]);
    expect(
      out.first['x'],
      2,
      reason: 'VegaLiteSchemaAdapter.ts:299-300 default arm.',
    );
  });

  test('a window sum runs cumulatively within each group', () {
    final out = applyVegaTransforms(rows(), <Object?>[
      <String, Object?>{
        'window': <Object?>[
          <String, Object?>{'op': 'sum', 'field': 'v', 'as': 'cum'},
        ],
        'groupby': <Object?>['g'],
      },
    ]);
    expect(
      out.map((row) => row['cum']).toList(),
      <Object?>[1, 4, 5],
      reason:
          'VegaLiteSchemaAdapter.ts:345-348; the running total RESETS between '
          'groups because runningSum is declared at :340, inside the '
          'groups.forEach that opens at :324 — group b therefore starts from 0 '
          'and reads 5 rather than 9. What the one accumulator is shared by is '
          'the window list, not the groups. // parity',
    );
  });

  test('one running total is shared by every sum op in the window list', () {
    final out = applyVegaTransforms(rows(), <Object?>[
      <String, Object?>{
        'window': <Object?>[
          <String, Object?>{'op': 'sum', 'field': 'v', 'as': 'first'},
          <String, Object?>{'op': 'sum', 'field': 'v', 'as': 'second'},
        ],
      },
    ]);
    expect(
      out.map((row) => <Object?>[row['first'], row['second']]).toList(),
      <List<Object?>>[
        <Object?>[1, 2],
        <Object?>[5, 8],
        <Object?>[13, 18],
      ],
      reason:
          'VegaLiteSchemaAdapter.ts:340 declares ONE runningSum outside the '
          'windowOps.forEach at :343, so the second sum op accumulates on top '
          'of the first rather than repeating it. // parity',
    );
  });

  test('rank, row_number and count all produce the one-based index', () {
    final out = applyVegaTransforms(rows(), <Object?>[
      <String, Object?>{
        'window': <Object?>[
          <String, Object?>{'op': 'rank', 'as': 'r'},
          <String, Object?>{'op': 'row_number', 'as': 'n'},
          <String, Object?>{'op': 'count', 'as': 'c'},
        ],
      },
    ]);
    expect(
      out.map((row) => <Object?>[row['r'], row['n'], row['c']]).toList(),
      <List<Object?>>[
        <Object?>[1, 1, 1],
        <Object?>[2, 2, 2],
        <Object?>[3, 3, 3],
      ],
      reason:
          'VegaLiteSchemaAdapter.ts:349-359 gives all three, and the default '
          'arm, the same idx + 1. // parity',
    );
  });

  test('a window sort orders the rows inside each group', () {
    final out = applyVegaTransforms(
      <Map<String, Object?>>[
        <String, Object?>{'g': 'a', 'v': 1, 't': 2},
        <String, Object?>{'g': 'a', 'v': 3, 't': 1},
        <String, Object?>{'g': 'b', 'v': 5, 't': 9},
      ],
      <Object?>[
        <String, Object?>{
          'window': <Object?>[
            <String, Object?>{'op': 'sum', 'field': 'v', 'as': 'cum'},
          ],
          'groupby': <Object?>['g'],
          'sort': <Object?>[
            <String, Object?>{'field': 't'},
          ],
        },
      ],
    );
    expect(
      out.map((row) => <Object?>[row['v'], row['cum']]).toList(),
      <List<Object?>>[
        <Object?>[3, 3],
        <Object?>[1, 4],
        <Object?>[5, 5],
      ],
      reason:
          'VegaLiteSchemaAdapter.ts:326-338 sorts inside the group before '
          ':341 walks it, so the emitted row order is the sorted one and the '
          'running total follows it.',
    );
  });

  test('a descending window sort reverses the comparator', () {
    final out = applyVegaTransforms(
      <Map<String, Object?>>[
        <String, Object?>{'v': 1, 't': 2},
        <String, Object?>{'v': 3, 't': 1},
        <String, Object?>{'v': 5, 't': 9},
      ],
      <Object?>[
        <String, Object?>{
          'window': <Object?>[
            <String, Object?>{'op': 'row_number', 'as': 'n'},
          ],
          'sort': <Object?>[
            <String, Object?>{'field': 't', 'order': 'descending'},
          ],
        },
      ],
    );
    expect(
      out.map((row) => <Object?>[row['t'], row['n']]).toList(),
      <List<Object?>>[
        <Object?>[9, 1],
        <Object?>[2, 2],
        <Object?>[1, 3],
      ],
      reason: 'VegaLiteSchemaAdapter.ts:331 swaps the operands for descending.',
    );
  });

  test('joinaggregate adds the group aggregate onto every row', () {
    final out = applyVegaTransforms(rows(), <Object?>[
      <String, Object?>{
        'joinaggregate': <Object?>[
          <String, Object?>{'op': 'sum', 'field': 'v', 'as': 'total'},
        ],
        'groupby': <Object?>['g'],
      },
    ]);
    expect(
      out.map((row) => row['total']).toList(),
      <Object?>[4, 4, 5],
      reason: 'VegaLiteSchemaAdapter.ts:369-417.',
    );
    expect(
      out.map((row) => row['v']).toList(),
      <Object?>[1, 3, 5],
      reason:
          'VegaLiteSchemaAdapter.ts:413-416 maps rather than replaces, so the '
          'row count and every original column survive.',
    );
  });

  test('joinaggregate with no groupby aggregates the whole dataset', () {
    final out = applyVegaTransforms(rows(), <Object?>[
      <String, Object?>{
        'joinaggregate': <Object?>[
          <String, Object?>{'op': 'sum', 'field': 'v', 'as': 'total'},
        ],
      },
    ]);
    expect(
      out.map((row) => row['total']).toList(),
      <Object?>[9, 9, 9],
      reason:
          'VegaLiteSchemaAdapter.ts:376 and :414 both fall back to the single '
          "'__all__' key when groupby is empty.",
    );
  });

  test('several keys on one transform object all fire, in source order', () {
    final out = applyVegaTransforms(rows(), <Object?>[
      <String, Object?>{
        'filter': 'datum.v > 1',
        'calculate': 'datum.v * 2',
        'as': 'doubled',
      },
    ]);
    expect(
      out.map((row) => row['doubled']).toList(),
      <Object?>[6, 10],
      reason:
          'VegaLiteSchemaAdapter.ts:224-563 uses independent ifs, so filter '
          'runs before calculate on the same transform object.',
    );
  });

  test('an empty or absent transform list returns the data unchanged', () {
    final data = rows();
    expect(
      identical(applyVegaTransforms(data, null), data),
      isTrue,
      reason: 'VegaLiteSchemaAdapter.ts:218-220.',
    );
    expect(
      identical(applyVegaTransforms(data, <Object?>[]), data),
      isTrue,
      reason: 'VegaLiteSchemaAdapter.ts:218-220, the length === 0 arm.',
    );
  });
}
