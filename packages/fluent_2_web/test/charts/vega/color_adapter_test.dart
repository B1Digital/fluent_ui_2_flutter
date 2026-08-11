import 'package:fluent_2_web/src/charts/internal/vega/color_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a custom range beats a named scheme', () {
    expect(
      getVegaColor(3, 'category10', <String>[
        '#111111',
        '#222222',
      ], isDark: false),
      '#222222',
      reason:
          'VegaLiteColorAdapter.ts:242-244 checks range first and cycles '
          'with index % length.',
    );
  });

  test('the unmapped schemes fall through to the Fluent qualitative cycle', () {
    const unmapped = <String>[
      'accent',
      'dark2',
      'paired',
      'pastel1',
      'pastel2',
      'set1',
      'set2',
      'set3',
    ];
    expect(
      unmapped,
      hasLength(8),
      reason:
          'VegaLiteColorAdapter.ts:211-218 lists exactly eight ColorBrewer '
          'qualitative schemes it has not mapped.',
    );
    for (final scheme in unmapped) {
      expect(
        getVegaColor(0, scheme, null, isDark: false),
        getVegaColor(0, null, null, isDark: false),
        reason:
            'VegaLiteColorAdapter.ts:211-220 returns undefined for '
            '$scheme, so getNextColor supplies the colour.',
      );
    }
  });

  test('category20b and category20c alias category20', () {
    final aliased = <String>[
      for (final scheme in <String>['category20b', 'category20c'])
        getVegaColor(0, scheme, null, isDark: false),
    ];
    expect(
      aliased,
      everyElement(getVegaColor(0, 'category20', null, isDark: false)),
      reason: 'VegaLiteColorAdapter.ts:202-205 shares one case block.',
    );
    expect(
      aliased.first,
      isNot(getVegaColor(0, null, null, isDark: false)),
      reason:
          'The alias must reach CATEGORY20_FLUENT_MAPPING '
          '(VegaLiteColorAdapter.ts:110, color26) rather than falling through '
          'to the qualitative cycle, which starts at color1.',
    );
  });

  test('a mapped scheme cycles through its own mapping, not the palette', () {
    expect(
      getVegaColor(10, 'category10', null, isDark: false),
      getVegaColor(0, 'category10', null, isDark: false),
      reason:
          'VegaLiteColorAdapter.ts:249 indexes with '
          'index % schemeMapping.length, and category10 has ten entries.',
    );
    // category10 rather than tableau10: TABLEAU10_FLUENT_MAPPING's first entry
    // is color1 (VegaLiteColorAdapter.ts:134), which is also where the
    // qualitative cycle starts, so an unrecognised 'TABLEAU10' would fall
    // through to the same colour and the assertion could not bite.
    // CATEGORY10_FLUENT_MAPPING starts at color26 (`:96`).
    expect(
      getVegaColor(0, 'CATEGORY10', null, isDark: false),
      getVegaColor(0, 'category10', null, isDark: false),
      reason:
          'VegaLiteColorAdapter.ts:197 lower-cases the scheme name before '
          'the switch.',
    );
  });

  test('a dark theme resolves a mapped token differently', () {
    // Index 1 of CATEGORY10_FLUENT_MAPPING is `warning`
    // (VegaLiteColorAdapter.ts:97), one of the seven semantic tokens that
    // carries a second, dark ramp entry (colors.ts:110). Index 0, color26, is
    // a single-entry qualitative ramp and would read the same in both themes.
    expect(
      getVegaColor(1, 'category10', null, isDark: true),
      isNot(getVegaColor(1, 'category10', null, isDark: false)),
      reason:
          'VegaLiteColorAdapter.ts:250 forwards isDarkTheme to '
          'getColorFromToken.',
    );
  });

  test('the colour map assigns by size and caches', () {
    final map = <String, String>{};
    final first = getVegaColorFromMap(
      'a',
      map,
      'category10',
      null,
      isDark: false,
    );
    final second = getVegaColorFromMap(
      'b',
      map,
      'category10',
      null,
      isDark: false,
    );
    expect(
      getVegaColorFromMap('a', map, 'category10', null, isDark: false),
      first,
      reason: 'VegaLiteColorAdapter.ts:275-277 returns the cached colour.',
    );
    expect(
      second,
      getVegaColor(1, 'category10', null, isDark: false),
      reason:
          'VegaLiteColorAdapter.ts:280 indexes by the map size at the '
          'moment of the first lookup, so the second legend takes index 1.',
    );
    expect(
      map.length,
      2,
      reason:
          'VegaLiteColorAdapter.ts:283 stores each new '
          'legend exactly once.',
    );
  });

  test('all sixteen sequential ramps are present with five stops each', () {
    expect(
      kVegaSequentialSchemes,
      hasLength(16),
      reason: 'VegaLiteColorAdapter.ts:291-308.',
    );
    for (final entry in kVegaSequentialSchemes.entries) {
      expect(
        entry.value,
        hasLength(5),
        reason:
            '${entry.key} must have five stops '
            '(VegaLiteColorAdapter.ts:289, ":291-308").',
      );
    }
    expect(kVegaSequentialSchemes['viridis'], <String>[
      '#440154',
      '#3b528b',
      '#21918c',
      '#5ec962',
      '#fde725',
    ], reason: 'VegaLiteColorAdapter.ts:298.');
    expect(kVegaSequentialSchemes['redblue'], <String>[
      '#ca0020',
      '#f4a582',
      '#f7f7f7',
      '#92c5de',
      '#0571b0',
    ], reason: 'VegaLiteColorAdapter.ts:307.');
  });

  test('a five-step request returns the ramp unchanged, but not the ramp', () {
    final ramp = getSequentialSchemeColors('blues');
    expect(
      ramp,
      kVegaSequentialSchemes['blues'],
      reason:
          'VegaLiteColorAdapter.ts:324-326 short-circuits when steps '
          'equals the ramp length.',
    );
    ramp!.setAll(0, <String>['#000000']);
    expect(
      kVegaSequentialSchemes['blues']!.first,
      '#deebf7',
      reason:
          "VegaLiteColorAdapter.ts:325's `[...ramp]` is a copy, so "
          "VegaLiteSchemaAdapter.ts:3477's in-place `.reverse()` cannot "
          'corrupt the shared table.',
    );
  });

  test('a one-step request samples the ramp midpoint', () {
    expect(
      getSequentialSchemeColors('blues', steps: 1),
      <String>[kVegaSequentialSchemes['blues']![2]],
      reason:
          'VegaLiteColorAdapter.ts:331: t is 0.5 when steps is 1, so pos '
          'is 2.0 and frac is 0.',
    );
  });

  test('a nine-step request interpolates every other stop', () {
    final ramp = kVegaSequentialSchemes['blues']!;
    expect(
      getSequentialSchemeColors('blues', steps: 9),
      <String>[
        ramp[0],
        interpolateHexColor(ramp[0], ramp[1], 0.5),
        ramp[1],
        interpolateHexColor(ramp[1], ramp[2], 0.5),
        ramp[2],
        interpolateHexColor(ramp[2], ramp[3], 0.5),
        ramp[3],
        interpolateHexColor(ramp[3], ramp[4], 0.5),
        ramp[4],
      ],
      reason:
          'VegaLiteColorAdapter.ts:330-342 walks pos = i/8 * 4, so the '
          'even i land exactly on a stop (frac 0) and the odd i sit halfway.',
    );
  });

  test('interpolation rounds each channel the JavaScript way', () {
    expect(
      interpolateHexColor('#000000', '#ffffff', 0.5),
      '#808080',
      reason:
          'VegaLiteColorAdapter.ts:357-359: Math.round(0 + 255 * 0.5) is '
          '128 = 0x80.',
    );
    expect(
      interpolateHexColor('#000000', '#0f0f0f', 0.1),
      '#020202',
      reason:
          'VegaLiteColorAdapter.ts:361 pads each channel to two digits, '
          'and Math.round(15 * 0.1) is 2.',
    );
    // Three distinct channels, so a mix-up of the 1, 3 and 5 offsets at
    // VegaLiteColorAdapter.ts:350-355 shows: 0x10..0x40 midpoint is 0x28,
    // 0x20..0x50 is 0x38, 0x30..0x60 is 0x48.
    expect(
      interpolateHexColor('#102030', '#405060', 0.5),
      '#283848',
      reason:
          'VegaLiteColorAdapter.ts:350-359 reads red at offset 1, green at 3 '
          'and blue at 5, and writes them back in that order.',
    );
  });

  test('an unknown ramp name yields null', () {
    expect(
      getSequentialSchemeColors('not-a-scheme'),
      isNull,
      reason: 'VegaLiteColorAdapter.ts:320-322.',
    );
    expect(
      getSequentialSchemeColors('BLUES'),
      kVegaSequentialSchemes['blues'],
      reason: 'VegaLiteColorAdapter.ts:319 lower-cases the scheme name first.',
    );
  });
}
