import 'package:fluent_2/src/charts/internal/vega/common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentVegaLegendProps build(Map<String, Object?> spec) =>
      getVegaLiteLegendsProps(spec, <String, String>{}, isDark: false);

  test('an unroutable spec still returns the three flags', () {
    // No `mark`, so `normalizeVegaSpec` matches neither the layer nor the unit
    // shape and returns the empty list (`routing.dart:454`,
    // `VegaLiteSchemaAdapter.ts:600`).
    final props = build(<String, Object?>{
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'x': 'a', 'v': 1},
        ],
      },
    });
    expect(
      props.legends,
      isEmpty,
      reason:
          'ts:1996-2003 returns the empty legend list it declared at :1994.',
    );
    expect(
      props.centerLegends,
      isTrue,
      reason:
          'ts:1999 — the flags are returned even on the unroutable path, so '
          'the caller never has to null-check them.',
    );
  });

  test('with no colour field the legend list is empty', () {
    final props = build(<String, Object?>{
      'mark': 'bar',
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'x': 'a', 'v': 1},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'nominal'},
        'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
      },
    });
    expect(
      props.legends,
      isEmpty,
      reason: 'ts:2010-2017 returns empty without a colour field.',
    );
  });

  test('one legend per distinct colour value, in first-seen order', () {
    final props = build(<String, Object?>{
      'mark': 'bar',
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'x': 'a', 'v': 1, 'g': 'q'},
          <String, Object?>{'x': 'b', 'v': 2, 'g': 'p'},
          <String, Object?>{'x': 'c', 'v': 3, 'g': 'q'},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'nominal'},
        'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
        'color': <String, Object?>{'field': 'g', 'type': 'nominal'},
      },
    });
    expect(
      props.legends.map((legend) => legend.title).toList(),
      <String>['q', 'p'],
      reason: 'ts:1988-2042 walks the rows once and dedupes.',
    );
  });

  test('a row missing the colour key is skipped, an explicit null is not', () {
    final props = build(<String, Object?>{
      'mark': 'bar',
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'x': 'a', 'v': 1, 'g': 'q'},
          // No `g` at all: `row[colorField]` is `undefined` upstream.
          <String, Object?>{'x': 'b', 'v': 2},
          // `g: null`: `null !== undefined`, so upstream adds `String(null)`.
          <String, Object?>{'x': 'c', 'v': 3, 'g': null},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'nominal'},
        'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
        'color': <String, Object?>{'field': 'g', 'type': 'nominal'},
      },
    });
    expect(
      props.legends.map((legend) => legend.title).toList(),
      <String>['q', 'null'],
      reason:
          'ts:2022 tests `!== undefined`, not `!= null`, so a present-but-'
          'null cell becomes a legend titled "null" (`String(null)` at :2023) '
          'while an absent key is skipped.',
    );
  });

  test('the shared legend ignores the colour scheme, which can disagree with '
      'the sub-charts', () {
    // TWO series, not one. The plan's own version of this test used a single
    // row, and it does not bite: `tableau10`'s first Fluent token is `color1`
    // (color_adapter.dart:50) and so is the qualitative cycle's first entry
    // (data_viz_palette.dart:173), so index 0 agrees whether or not the scheme
    // is forwarded. Index 1 is where they part — `color7`, pumpkin.primary
    // (:51), against `color2`, hotPink.primary (data_viz_palette.dart:174) —
    // so a second series is what makes the dropped scheme observable. Proven by
    // mutation: passing `'tableau10'` through at common.dart:703 leaves the
    // one-row form green and fails this one.
    const twoRows = <Object?>[
      <String, Object?>{'x': 'a', 'v': 1, 'g': 'p'},
      <String, Object?>{'x': 'b', 'v': 2, 'g': 'q'},
    ];
    final withScheme = build(<String, Object?>{
      'mark': 'bar',
      'data': <String, Object?>{'values': twoRows},
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'nominal'},
        'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
        'color': <String, Object?>{
          'field': 'g',
          'type': 'nominal',
          'scale': <String, Object?>{'scheme': 'tableau10'},
        },
      },
    });
    final withoutScheme = build(<String, Object?>{
      'mark': 'bar',
      'data': <String, Object?>{'values': twoRows},
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'nominal'},
        'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
        'color': <String, Object?>{'field': 'g', 'type': 'nominal'},
      },
    });
    expect(
      withScheme.legends.map((legend) => legend.color.toARGB32()).toList(),
      withoutScheme.legends.map((legend) => legend.color.toARGB32()).toList(),
      reason:
          'parity: ts:2029 calls getVegaColorFromMap(name, colorMap, undefined, '
          'undefined, isDark), passing neither the scheme nor the range, so the '
          'shared legend can show a different colour from the chart it labels. '
          'Each build gets its own empty colorMap, so agreement here is the '
          'dropped scheme rather than a cache hit.',
    );
    expect(
      withoutScheme.legends.map((legend) => legend.color.toARGB32()).toList(),
      <int>[0xFF637CEF, 0xFFE3008C],
      reason:
          'the qualitative cycle, indexed by the colour map size at first '
          'lookup: cornflower.tint10 and hotPink.primary '
          '(data_viz_palette.dart:173-174). Pinned as literals so that the '
          'equality above cannot pass by both sides drifting together.',
    );
  });

  test('the shared legend always centres, wraps and multi-selects', () {
    final props = build(<String, Object?>{
      'mark': 'bar',
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'x': 'a', 'v': 1, 'g': 'p'},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'nominal'},
        'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
        'color': <String, Object?>{'field': 'g', 'type': 'nominal'},
      },
    });
    expect(props.centerLegends, isTrue, reason: 'ts:2038.');
    expect(props.enabledWrapLines, isTrue, reason: 'ts:2039.');
    expect(props.canSelectMultipleLegends, isTrue, reason: 'ts:2040.');
  });

  test('the colour map is seeded in first-seen order and reused', () {
    final colorMap = <String, String>{};
    final spec = <String, Object?>{
      'mark': 'bar',
      'data': <String, Object?>{
        'values': <Object?>[
          <String, Object?>{'x': 'a', 'v': 1, 'g': 'q'},
          <String, Object?>{'x': 'b', 'v': 2, 'g': 'p'},
        ],
      },
      'encoding': <String, Object?>{
        'x': <String, Object?>{'field': 'x', 'type': 'nominal'},
        'y': <String, Object?>{'field': 'v', 'type': 'quantitative'},
        'color': <String, Object?>{'field': 'g', 'type': 'nominal'},
      },
    };
    final first = getVegaLiteLegendsProps(spec, colorMap, isDark: false);
    final second = getVegaLiteLegendsProps(spec, colorMap, isDark: false);
    expect(
      colorMap.keys.toList(),
      <String>['q', 'p'],
      reason:
          'ts:2029 writes through getVegaColorFromMap, whose palette index '
          'is the map size at first lookup (VegaLiteColorAdapter.ts:280), so '
          'the legend order IS the palette order.',
    );
    expect(
      second.legends.map((legend) => legend.color.toARGB32()).toList(),
      first.legends.map((legend) => legend.color.toARGB32()).toList(),
      reason:
          'VegaLiteColorAdapter.ts:275-277 returns the cached colour, so a '
          'second pass over the same spec is stable.',
    );
  });
}
