import 'package:fluent_2_web/src/charts/internal/d3/format_spec.dart' as d3;
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  test('an empty specifier takes every default', () {
    final s = d3.formatSpecifier('');
    expect(s.fill, ' ', reason: 'formatSpecifier.js:24');
    expect(s.align, '>', reason: 'formatSpecifier.js:25');
    expect(s.sign, '-', reason: 'formatSpecifier.js:26');
    expect(s.symbol, '', reason: 'formatSpecifier.js:27');
    expect(s.zero, isFalse, reason: 'formatSpecifier.js:28');
    expect(s.width, isNull, reason: 'formatSpecifier.js:29');
    expect(s.comma, isFalse, reason: 'formatSpecifier.js:30');
    expect(s.precision, isNull, reason: 'formatSpecifier.js:31');
    expect(s.trim, isFalse, reason: 'formatSpecifier.js:32');
    expect(s.type, '', reason: 'formatSpecifier.js:33');
  });

  test('the whole grammar in one string', () {
    final s = d3.formatSpecifier(r'*^+$08,.3~f');
    expect(s.fill, '*', reason: 'the [[fill]align] pair');
    expect(s.align, '^', reason: 'centre alignment');
    expect(s.sign, '+', reason: 'explicit sign');
    expect(s.symbol, r'$', reason: 'currency symbol');
    expect(s.zero, isTrue, reason: 'the literal 0 before the width');
    expect(s.width, 8, reason: 'width group');
    expect(s.comma, isTrue, reason: 'grouping flag');
    expect(s.precision, 3, reason: 'the ".3" group, sliced past the dot');
    expect(s.trim, isTrue, reason: 'the ~ flag');
    expect(s.type, 'f', reason: 'type');
  });

  test('an invalid specifier throws, and the message is the contract', () {
    // PlotlySchemaAdapter.ts:443 and :2865 and VegaLiteSchemaAdapter.ts:1079
    // all catch this and fall back, so returning null would silently change
    // three adapter code paths.
    expect(
      () => d3.formatSpecifier('zz'),
      throwsA(
        isA<FormatException>().having(
          (FormatException e) => e.message,
          'message',
          'invalid format: zz',
        ),
      ),
      reason: 'formatSpecifier.js:5 throws Error("invalid format: " + s)',
    );
  });

  test('toString round-trips through the documented clamps', () {
    final s = d3.formatSpecifier('.3f')
      ..width = 0
      ..precision = -2;
    expect(
      s.toString(),
      ' >-1.0f',
      reason:
          'formatSpecifier.js:42,44 clamp width to max(1, w) and precision '
          'to max(0, p) on the way out only',
    );
  });

  test('against the d3 golden corpus', () async {
    final corpus = await loadD3Golden();
    final cases = goldenCases(corpus, 'formatSpecifier');
    expect(
      cases,
      isNotEmpty,
      reason: 'the corpus must actually have been read',
    );
    for (final c in cases) {
      final input = c['specifier']! as String;
      if (c['error'] != null) {
        expect(
          () => d3.formatSpecifier(input),
          throwsFormatException,
          reason: 'formatSpecifier("$input") throws upstream',
        );
        continue;
      }
      final s = d3.formatSpecifier(input);
      expect(s.fill, c['fill'], reason: 'fill of "$input"');
      expect(s.align, c['align'], reason: 'align of "$input"');
      expect(s.sign, c['sign'], reason: 'sign of "$input"');
      expect(s.symbol, c['symbol'], reason: 'symbol of "$input"');
      expect(s.zero, c['zero'], reason: 'zero of "$input"');
      expect(s.width, c['width'], reason: 'width of "$input"');
      expect(s.comma, c['comma'], reason: 'comma of "$input"');
      expect(s.precision, c['precision'], reason: 'precision of "$input"');
      expect(s.trim, c['trim'], reason: 'trim of "$input"');
      expect(s.type, c['type'], reason: 'type of "$input"');
      expect(s.toString(), c['toString'], reason: 'toString of "$input"');
    }
  });
}
