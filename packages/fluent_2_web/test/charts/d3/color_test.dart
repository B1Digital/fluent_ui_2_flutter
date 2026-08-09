import 'package:fluent_2_web/src/charts/internal/d3/color.dart' as d3;
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  test('parses every CSS form d3 accepts', () {
    expect(d3.color('#f00')?.formatHex(), '#ff0000', reason: 'color.js:205');
    expect(d3.color('#ff0000')?.formatHex(), '#ff0000', reason: 'color.js:204');
    expect(
      d3.color('#ff000080')?.formatHex8(),
      '#ff000080',
      reason: 'color.js:206, 8-digit hex keeps the alpha byte',
    );
    expect(
      d3.color('rgb(100%, 0%, 0%)')?.formatHex(),
      '#ff0000',
      reason: 'color.js:210 scales each percentage by 255 / 100',
    );
    expect(
      d3.color('hsl(120, 50%, 50%)')?.formatHex(),
      '#40bf40',
      reason: 'color.js:213 then the FvD 13.37 conversion at color.js:391-396',
    );
    expect(
      d3.color('  #ABCDEF  ')?.formatHex(),
      '#abcdef',
      reason: 'color.js:203 trims and lower-cases first',
    );
    expect(
      d3.color('rebeccapurple')?.formatHex(),
      '#663399',
      reason: 'the 148-entry named table at color.js:19-168',
    );
    expect(
      d3.color('transparent')?.formatRgb(),
      'rgba(0, 0, 0, 0)',
      reason:
          'color.js:216 builds Rgb(NaN, NaN, NaN, 0) and clampi maps each '
          'NaN to 0 via `Math.round(v) || 0` (color.js:293)',
    );
    expect(d3.color('not-a-colour'), isNull, reason: 'color.js:217');
    expect(d3.color('#12345'), isNull, reason: 'color.js:208, invalid length');
  });

  test('formatRgb switches on the alpha', () {
    expect(
      d3.rgb('#ff0000')?.formatRgb(),
      'rgb(255, 0, 0)',
      reason: 'color.js:285, a == 1',
    );
    expect(
      d3.color('rgba(255, 0, 0, 0.5)')?.formatRgb(),
      'rgba(255, 0, 0, 0.5)',
      reason: 'color.js:285, a != 1',
    );
  });

  test('copyWith(opacity) then formatHex8 — the Plotly adapter path', () {
    expect(
      d3.rgb('#0078d4')!.copyWith(opacity: 0.4).formatHex8(),
      '#0078d466',
      reason:
          'PlotlySchemaAdapter.ts:1472 and 12 sibling call sites; '
          'color.js:280 rounds 0.4 * 255 to 102 = 0x66',
    );
  });

  test('clampi rounds with JS semantics and maps NaN to 0', () {
    expect(
      const d3.D3Rgb(-5, 300, double.nan).formatHex(),
      '#00ff00',
      reason: 'color.js:293, `Math.max(0, Math.min(255, Math.round(v) || 0))`',
    );
  });

  test('the named table is complete', () {
    // The 148 CSS names at d3-color/src/color.js:19-168, transcribed from the
    // same pinned module the corpus was generated from. A missing entry fails
    // silently as an unparsed colour, so every name is asserted rather than
    // the table trusted. 'transparent' is NOT one of them — it is the separate
    // special case at color.js:216.
    const names = <String>[
      'aliceblue',
      'antiquewhite',
      'aqua',
      'aquamarine',
      'azure',
      'beige',
      'bisque',
      'black',
      'blanchedalmond',
      'blue',
      'blueviolet',
      'brown',
      'burlywood',
      'cadetblue',
      'chartreuse',
      'chocolate',
      'coral',
      'cornflowerblue',
      'cornsilk',
      'crimson',
      'cyan',
      'darkblue',
      'darkcyan',
      'darkgoldenrod',
      'darkgray',
      'darkgreen',
      'darkgrey',
      'darkkhaki',
      'darkmagenta',
      'darkolivegreen',
      'darkorange',
      'darkorchid',
      'darkred',
      'darksalmon',
      'darkseagreen',
      'darkslateblue',
      'darkslategray',
      'darkslategrey',
      'darkturquoise',
      'darkviolet',
      'deeppink',
      'deepskyblue',
      'dimgray',
      'dimgrey',
      'dodgerblue',
      'firebrick',
      'floralwhite',
      'forestgreen',
      'fuchsia',
      'gainsboro',
      'ghostwhite',
      'gold',
      'goldenrod',
      'gray',
      'green',
      'greenyellow',
      'grey',
      'honeydew',
      'hotpink',
      'indianred',
      'indigo',
      'ivory',
      'khaki',
      'lavender',
      'lavenderblush',
      'lawngreen',
      'lemonchiffon',
      'lightblue',
      'lightcoral',
      'lightcyan',
      'lightgoldenrodyellow',
      'lightgray',
      'lightgreen',
      'lightgrey',
      'lightpink',
      'lightsalmon',
      'lightseagreen',
      'lightskyblue',
      'lightslategray',
      'lightslategrey',
      'lightsteelblue',
      'lightyellow',
      'lime',
      'limegreen',
      'linen',
      'magenta',
      'maroon',
      'mediumaquamarine',
      'mediumblue',
      'mediumorchid',
      'mediumpurple',
      'mediumseagreen',
      'mediumslateblue',
      'mediumspringgreen',
      'mediumturquoise',
      'mediumvioletred',
      'midnightblue',
      'mintcream',
      'mistyrose',
      'moccasin',
      'navajowhite',
      'navy',
      'oldlace',
      'olive',
      'olivedrab',
      'orange',
      'orangered',
      'orchid',
      'palegoldenrod',
      'palegreen',
      'paleturquoise',
      'palevioletred',
      'papayawhip',
      'peachpuff',
      'peru',
      'pink',
      'plum',
      'powderblue',
      'purple',
      'rebeccapurple',
      'red',
      'rosybrown',
      'royalblue',
      'saddlebrown',
      'salmon',
      'sandybrown',
      'seagreen',
      'seashell',
      'sienna',
      'silver',
      'skyblue',
      'slateblue',
      'slategray',
      'slategrey',
      'snow',
      'springgreen',
      'steelblue',
      'tan',
      'teal',
      'thistle',
      'tomato',
      'turquoise',
      'violet',
      'wheat',
      'white',
      'whitesmoke',
      'yellow',
      'yellowgreen',
    ];
    expect(
      names,
      hasLength(148),
      reason: 'the table at color.js:19-168 has exactly 148 entries',
    );
    for (final name in <String>[...names, 'transparent']) {
      expect(
        d3.color(name),
        isNotNull,
        reason: '"$name" must parse — it is in the CSS named table',
      );
    }
  });

  test('against the d3 golden corpus', () async {
    final corpus = await loadD3Golden();
    final cases = goldenCases(corpus, 'color');
    expect(
      cases,
      isNotEmpty,
      reason: 'the corpus must actually have been read',
    );
    for (final c in cases) {
      final input = c['input']! as String;
      final parsed = d3.color(input);
      expect(
        parsed != null,
        c['parsed'],
        reason: 'color("$input") parseability',
      );
      if (parsed == null) {
        continue;
      }
      expect(parsed.formatHex(), c['hex'], reason: 'formatHex("$input")');
      expect(parsed.formatHex8(), c['hex8'], reason: 'formatHex8("$input")');
      expect(parsed.formatRgb(), c['rgbString'], reason: 'formatRgb("$input")');
      final asRgb = parsed.rgb();
      expect(asRgb.r, closeToJs(c['r']), reason: 'r of "$input"');
      expect(asRgb.g, closeToJs(c['g']), reason: 'g of "$input"');
      expect(asRgb.b, closeToJs(c['b']), reason: 'b of "$input"');
      expect(asRgb.a, closeToJs(c['opacity']), reason: 'opacity of "$input"');
      expect(
        d3.rgb(input)!.copyWith(opacity: 0.4).formatHex8(),
        c['hex8At40'],
        reason: 'rgb("$input").copy({opacity: 0.4}).formatHex8()',
      );
      final asHsl = d3.hsl(input)!;
      expect(asHsl.h, closeToJs(c['hslH']), reason: 'hsl h of "$input"');
      expect(asHsl.s, closeToJs(c['hslS']), reason: 'hsl s of "$input"');
      expect(asHsl.l, closeToJs(c['hslL']), reason: 'hsl l of "$input"');
    }
  });
}
