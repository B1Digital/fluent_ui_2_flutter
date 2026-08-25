import 'package:fluent_2/src/charts/internal/vega/spec.dart';
import 'package:flutter_test/flutter_test.dart';

/// One more level of nesting than the guard tolerates would be enough; 20 is
/// used so the fixture still overflows if `kVegaMaxJsonDepth` is raised a
/// little, and it is small enough that the recursion the test provokes is not
/// itself a stack risk.
const int _overDeepLevels = 20;

void main() {
  test('a spec deeper than fifteen levels is rejected', () {
    Object? nested = 'leaf';
    for (var i = 0; i < _overDeepLevels; i++) {
      nested = <String, Object?>{'k': nested};
    }
    expect(
      () => validateVegaJsonDepth(nested),
      throwsA(
        isA<VegaSpecException>().having(
          (e) => e.message,
          'message',
          'VegaDeclarativeChart: Maximum JSON depth exceeded',
        ),
      ),
      reason: 'VegaDeclarativeChart.tsx:49-52, message verbatim.',
    );
  });

  test('a spec at the depth ceiling is accepted', () {
    Object? nested = 'leaf';
    for (var i = 0; i < kVegaMaxJsonDepth; i++) {
      nested = <String, Object?>{'k': nested};
    }
    expect(
      () => validateVegaJsonDepth(nested),
      returnsNormally,
      reason:
          'VegaDeclarativeChart.tsx:50 rejects on `depth > MAX_DEPTH`, not on '
          '`>=`, so a spec exactly at the ceiling renders. Without this the '
          'guard could be off by one in the direction that refuses valid work.',
    );
  });

  test('the clone is deep, so auto-correction never touches the caller spec', () {
    final original = <String, Object?>{
      'encoding': <String, Object?>{
        'x': <String, Object?>{'type': 'quantitative'},
      },
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'a': 1},
        ],
      },
    };
    final clone = deepCloneVegaSpec(original);
    ((clone['encoding']! as Map<String, Object?>)['x']!
            as Map<String, Object?>)['type'] =
        'nominal';
    expect(
      ((original['encoding']! as Map<String, Object?>)['x']!
          as Map<String, Object?>)['type'],
      'quantitative',
      reason:
          'hardened: autoCorrectEncodingTypes mutates its argument in place '
          '(VegaLiteSchemaAdapter.ts:1553-1627) and even rewrites data rows at '
          ':1599-1612. Upstream hands it the caller object; the port clones '
          'first.',
    );
  });

  test('the clone copies list elements too, not just map values', () {
    final original = <String, Object?>{
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'a': 1},
        ],
      },
    };
    final clone = deepCloneVegaSpec(original);
    (((clone['data']! as Map<String, Object?>)['values']! as List<Object?>)
                .first!
            as Map<String, Object?>)['a'] =
        2;
    expect(
      (((original['data']! as Map<String, Object?>)['values']! as List<Object?>)
              .first!
          as Map<String, Object?>)['a'],
      1,
      reason:
          'the rows VegaLiteSchemaAdapter.ts:1606-1610 rewrites live inside '
          '`data.values`, a list — a clone that copied only map values would '
          'hand those very rows straight back to the caller.',
    );
  });

  test('getMarkType handles both the string and the object mark forms', () {
    expect(
      getMarkType('bar'),
      'bar',
      reason: 'VegaLiteSchemaAdapter.ts:95-99.',
    );
    expect(
      getMarkType(<String, Object?>{'type': 'line'}),
      'line',
      reason: 'VegaLiteSchemaAdapter.ts:95-99.',
    );
    expect(
      getMarkType(null),
      isNull,
      reason: 'VegaLiteSchemaAdapter.ts:96-98, the `!mark` guard.',
    );
    expect(
      getMarkType(''),
      isNull,
      reason:
          "VegaLiteSchemaAdapter.ts:96 is `if (!mark)`, and '' is falsy in "
          'JavaScript, so an empty mark reads as absent rather than as a mark '
          'named the empty string.',
    );
  });

  test(
    'inline data values are extracted and a url or name yields an empty list',
    () {
      expect(
        extractVegaDataValues(<String, Object?>{
          'values': <Object?>[
            <String, Object?>{'a': 1},
          ],
        }),
        hasLength(1),
        reason: 'VegaLiteSchemaAdapter.ts:146-148.',
      );
      expect(
        extractVegaDataValues(<String, Object?>{
          'url': 'https://example.com/data.json',
        }),
        isEmpty,
        reason:
            'VegaLiteSchemaAdapter.ts:150-154 returns [] with a TODO; the port '
            'keeps the silent empty behaviour rather than fetching, because a '
            'chart widget must not do network I/O.',
      );
      expect(
        extractVegaDataValues(<String, Object?>{'name': 'named'}),
        isEmpty,
        reason: 'VegaLiteSchemaAdapter.ts:156-160.',
      );
      expect(
        extractVegaDataValues(null),
        isEmpty,
        reason: 'VegaLiteSchemaAdapter.ts:142-144, the absent-data guard.',
      );
    },
  );

  test('a layer spec is a layer spec, and an empty layer array is not', () {
    final spec = <String, Object?>{
      'layer': <Object?>[
        <String, Object?>{
          'mark': 'bar',
          'encoding': <String, Object?>{
            'x': <String, Object?>{'field': 'a'},
          },
        },
      ],
    };
    expect(
      isVegaLayerSpec(spec),
      isTrue,
      reason: 'VegaLiteSchemaAdapter.ts:81-83.',
    );
    expect(
      isVegaLayerSpec(<String, Object?>{'layer': <Object?>[]}),
      isFalse,
      reason:
          'VegaLiteSchemaAdapter.ts:82 requires `spec.layer.length > 0`, which '
          'is what stops a layered spec with no layers normalising to a chart.',
    );
  });

  test('a unit spec needs both a mark and an encoding', () {
    expect(
      isVegaUnitSpec(<String, Object?>{
        'mark': 'bar',
        'encoding': <String, Object?>{
          'x': <String, Object?>{'field': 'a'},
        },
      }),
      isTrue,
      reason: 'VegaLiteSchemaAdapter.ts:88-90.',
    );
    expect(
      isVegaUnitSpec(<String, Object?>{'mark': 'bar'}),
      isFalse,
      reason:
          'VegaLiteSchemaAdapter.ts:89 tests both, so a mark without an '
          'encoding normalises to nothing rather than to an empty chart.',
    );
  });

  test('a list nested past the limit is also rejected', () {
    Object? nested = 'leaf';
    for (var i = 0; i < _overDeepLevels; i++) {
      nested = <Object?>[nested];
    }
    expect(
      () => validateVegaJsonDepth(nested),
      throwsA(isA<VegaSpecException>()),
      reason:
          'parity, not hardening: VegaDeclarativeChart.tsx:53 tests `typeof '
          "value === 'object'`, which is true for an array, and :54's "
          '`Object.keys` enumerates its indices — so upstream already descends '
          'a chain of arrays and this port must too.',
    );
  });
}
