import 'package:fluent_2/src/charts/internal/d3/format.dart' as d3;
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  test('the SI prefixes use MICRO SIGN and the minus is U+2212', () {
    expect(d3.siPrefixes.length, 17, reason: 'd3-format/src/locale.js:11');
    expect(
      d3.siPrefixes[6],
      'µ',
      reason:
          'MICRO SIGN U+00B5, not GREEK SMALL LETTER MU U+03BC — locale.js:11',
    );
    expect(d3.siPrefixes[8], '', reason: 'the unprefixed slot');
    expect(
      d3.minusSign,
      '−',
      reason:
          'locale.js:20 defaults minus to U+2212 MINUS SIGN, and the '
          'default locale (defaultLocale.js:7-11) does not override it, so '
          'every negative axis label uses it — not ASCII hyphen',
    );
  });

  test('an unknown or empty type is an alias for .12~g', () {
    expect(
      d3.format('')(1 / 3),
      '0.333333333333',
      reason: 'locale.js:41 sets precision 12, trim and type g',
    );
    expect(
      d3.format('.2~')(1234.5),
      '1.2e+3',
      reason: 'the empty type with an explicit precision keeps that precision',
    );
    expect(
      d3.format('n')(1234567),
      '1.23457e+6',
      reason:
          'locale.js:38 aliases "n" to ",g", and the g type at precision 6 '
          'turns 1234567 into exponential notation, which locale.js:94-103 '
          'moves out of the groupable part entirely',
    );
    expect(
      d3.format('n')(999999),
      '999,999',
      reason: 'locale.js:38, the comma the alias switches on',
    );
  });

  test('formatPrefix with a zero anchor produces NaN, not a stray suffix', () {
    // exponent(0) is NaN (formatDecimal.js:11), so locale.js:135-136 computes
    // e = NaN and k = NaN, and locale.js:49 drops the undefined suffix.
    expect(
      d3.formatPrefix('.2~', 0)(1500000),
      'NaN',
      reason: 'verified against the pinned d3-format 3.1.2',
    );
  });

  test('the default y-axis formatter — formatPrefix(".2~", value)', () {
    // utilities.ts:218 is `d3FormatPrefix('.2~', value)` and utilities.ts:242
    // makes it defaultYAxisTickFormatter, so this string is on almost every
    // chart in the library.
    expect(
      d3.formatPrefix('.2~', 1e6)(1500000),
      '1.5M',
      reason: 'utilities.ts:218',
    );
    expect(
      d3.formatPrefix('.2~', 1e9)(2.5e9),
      '2.5G',
      reason: 'the G that utilities.ts:232 then rewrites to B',
    );
    expect(d3.formatPrefix('.2~', 1000)(1000), '1k', reason: 'trim drops ".0"');
  });

  test('negative zero is suppressed unless the sign is explicit', () {
    expect(
      d3.format('.1f')(-0.04),
      '0.0',
      reason:
          'locale.js:86 hides the sign when the FORMATTED value parses back '
          'to zero: -0.04 formats to "0.0", +"0.0" is 0 and the default sign '
          'is "-", so the minus is dropped',
    );
    expect(
      d3.format('+.1f')(-0.04),
      '−0.0',
      reason: 'locale.js:86, `sign !== "+"` keeps the sign when + is asked for',
    );
    expect(
      d3.format('+.2f')(-0.0),
      '−0.00',
      reason:
          'locale.js:77 detects negative zero with `1 / value < 0`, which '
          '`value < 0` alone would miss',
    );
    expect(
      d3.format('.2f')(-0.0),
      '0.00',
      reason: 'locale.js:86 then drops that sign again without an explicit +',
    );
  });

  test('precision helpers', () {
    expect(d3.precisionFixed(0.01), 2, reason: 'precisionFixed.js:4');
    expect(d3.precisionPrefix(1e-6, 1e-9), 0, reason: 'precisionPrefix.js:4');
    expect(d3.precisionRound(0.01, 1.01), 3, reason: 'precisionRound.js:5');
    expect(
      d3.precisionRound(1, 1),
      isNaN,
      reason:
          'precisionRound.js:4-5 subtracts the step from the max, and '
          'exponent(0) is NaN (formatDecimal.js:11) — tickFormat.js:19 tests '
          'for exactly this, so the helpers return double, not int',
    );
    expect(
      d3.precisionFixed(0),
      isNaN,
      reason: 'exponent(0) is NaN (formatDecimal.js:11), so -NaN is NaN',
    );
    expect(
      d3.precisionPrefix(0, 1),
      isNaN,
      reason: 'precisionPrefix.js:4 subtracts exponent(0), which is NaN',
    );
  });

  test(
    'against the d3 golden corpus — every specifier over every value',
    () async {
      final corpus = await loadD3Golden();
      final cases = goldenCases(corpus, 'format');
      expect(
        cases,
        isNotEmpty,
        reason: 'the format section supplies the real d3 label strings',
      );
      for (final c in cases) {
        final values = jsNums(c['values']);
        // `crawlers/d3-golden/generate.mjs:95` sweeps `0, -0, 1, …`, but
        // `JSON.stringify(-0)` is "0", so the sign of the second value has to
        // be restored here. It is the only reason the "+.2f" row expects
        // "−0.00": `locale.js:77` finds the sign with `1 / value < 0`.
        values[1] = -0.0;
        final want = (c['out']! as List<Object?>).cast<String>();
        final f = c.containsKey('formatPrefix')
            ? d3.formatPrefix(c['formatPrefix']! as String, jsNum(c['anchor'])!)
            : d3.format(c['specifier']! as String);
        final label = c.containsKey('formatPrefix')
            ? 'formatPrefix("${c['formatPrefix']}", ${c['anchor']})'
            : 'format("${c['specifier']}")';
        for (var i = 0; i < values.length; i++) {
          expect(
            f(values[i]!),
            want[i],
            reason: '$label applied to ${values[i]}',
          );
        }
      }
    },
  );

  test('against the d3 golden corpus — precision helpers', () async {
    final corpus = await loadD3Golden();
    final cases = goldenCases(corpus, 'precision');
    expect(cases, isNotEmpty, reason: 'the precision section must be present');
    for (final c in cases) {
      final step = jsNum(c['step'])!;
      final value = jsNum(c['value'])!;
      expect(
        d3.precisionFixed(step),
        closeToJs(c['fixed']),
        reason: 'precisionFixed($step)',
      );
      expect(
        d3.precisionPrefix(step, value),
        closeToJs(c['prefix']),
        reason: 'precisionPrefix($step, $value)',
      );
      expect(
        d3.precisionRound(step, value),
        closeToJs(c['round']),
        reason: 'precisionRound($step, $value)',
      );
    }
  });
}
