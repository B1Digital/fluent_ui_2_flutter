import 'package:fluent_2_web/src/charts/internal/vega/js_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the falsy set is exactly false, 0, -0, NaN, empty string, null and '
      'undefined', () {
    for (final falsy in <Object?>[
      false,
      0,
      -0.0,
      double.nan,
      '',
      null,
      JsUndefined.instance,
    ]) {
      expect(
        jsTruthy(falsy),
        isFalse,
        reason: 'JavaScript falsy value $falsy.',
      );
    }
    for (final truthy in <Object?>[
      true,
      1,
      -1,
      'a',
      '0',
      <Object?>[],
      <String, Object?>{},
    ]) {
      expect(
        jsTruthy(truthy),
        isTrue,
        reason:
            "JavaScript truthy value $truthy — note that '0' and the empty "
            'array are truthy.',
      );
    }
  });

  test('loose equality coerces across types the way JavaScript does', () {
    expect(jsLooseEquals(1, '1'), isTrue, reason: "1 == '1' in JavaScript.");
    expect(jsLooseEquals(true, 1), isTrue, reason: 'true == 1.');
    expect(
      jsLooseEquals(null, JsUndefined.instance),
      isTrue,
      reason: 'null == undefined.',
    );
    expect(
      jsLooseEquals(null, 0),
      isFalse,
      reason: 'null == 0 is FALSE in JavaScript.',
    );
    expect(jsLooseEquals('', 0), isTrue, reason: "'' == 0.");
    expect(
      jsLooseEquals(double.nan, double.nan),
      isFalse,
      reason: 'NaN equals nothing.',
    );
  });

  test('strict equality never coerces', () {
    expect(jsStrictEquals(1, '1'), isFalse, reason: "1 === '1' is false.");
    expect(
      jsStrictEquals(1, 1.0),
      isTrue,
      reason: 'JavaScript has one number type.',
    );
    expect(
      jsStrictEquals(null, JsUndefined.instance),
      isFalse,
      reason: 'null !== undefined.',
    );
    expect(
      jsStrictEquals(double.nan, double.nan),
      isFalse,
      reason: 'NaN !== NaN.',
    );
  });

  test('plus concatenates when either side is a string', () {
    expect(
      jsAdd('a', 1),
      'a1',
      reason: 'VegaLiteExpressionEvaluator.ts:364-367 tests both operands.',
    );
    expect(
      jsAdd(1, 'a'),
      '1a',
      reason: 'VegaLiteExpressionEvaluator.ts:364-367.',
    );
    expect(jsAdd(1, 2), 3, reason: 'Two numbers add.');
    expect(
      jsAdd(true, 1),
      2,
      reason:
          'Neither operand is a string, so both coerce to number: true becomes '
          '1.',
    );
  });

  test('Number() semantics, including the empty string and whitespace', () {
    expect(jsToNumber(''), 0, reason: "Number('') is 0.");
    expect(jsToNumber('  12  '), 12, reason: 'Number trims whitespace.');
    // `double.tryParse` trims on its own, so `'  12  '` alone cannot tell a
    // present trim from an absent one — measured, and the mutation survived.
    // The whitespace-only string is the case that can: without the trim it
    // reaches `tryParse` and comes back NaN, where JavaScript answers 0.
    expect(
      jsToNumber('   '),
      0,
      reason: "Number('   ') is 0, the same as Number('').",
    );
    expect(
      jsToNumber('12abc'),
      isNaN,
      reason: "Number('12abc') is NaN, unlike parseFloat.",
    );
    expect(jsToNumber(null), 0, reason: 'Number(null) is 0.');
    expect(
      jsToNumber(JsUndefined.instance),
      isNaN,
      reason: 'Number(undefined) is NaN.',
    );
    expect(jsToNumber(true), 1, reason: 'Number(true) is 1.');
    expect(jsToNumber(<Object?>[]), 0, reason: 'Number([]) is 0.');
    expect(jsToNumber(<Object?>[5]), 5, reason: 'Number([5]) is 5.');
    expect(
      jsToNumber(<Object?>[1, 2]),
      isNaN,
      reason: 'Number([1, 2]) is NaN.',
    );
    expect(
      jsToNumber('0x10'),
      16,
      reason: 'Number accepts hexadecimal literals.',
    );
  });

  test('String() renders an integral double without a decimal point', () {
    expect(
      jsToString(1.0),
      '1',
      reason: "String(1.0) is '1' in JavaScript, not '1.0'.",
    );
    expect(
      jsToString(1.5),
      '1.5',
      reason: 'Fractional values keep their digits.',
    );
    expect(jsToString(null), 'null', reason: 'String(null).');
    expect(
      jsToString(JsUndefined.instance),
      'undefined',
      reason: 'String(undefined).',
    );
    expect(
      jsToString(<Object?>[1, 2]),
      '1,2',
      reason: 'Array toString joins with commas.',
    );
    expect(
      jsToString(<String, Object?>{}),
      '[object Object]',
      reason:
          'A plain object stringifies to [object Object]; the evaluator relies '
          'on this for bracket access keys '
          '(VegaLiteExpressionEvaluator.ts:432).',
    );
  });

  test('relational comparison compares strings lexicographically and numbers '
      'numerically', () {
    expect(
      jsLess('a', 'b'),
      isTrue,
      reason: 'Two strings compare lexicographically.',
    );
    expect(
      jsLess('10', 9),
      isFalse,
      reason: 'A mixed comparison coerces to number: 10 < 9 is false.',
    );
    expect(
      jsLess(double.nan, 1),
      isFalse,
      reason: 'Every NaN comparison is false.',
    );
    expect(
      jsGreaterOrEqual(double.nan, double.nan),
      isFalse,
      reason: 'Every NaN comparison is false.',
    );
    // The plan's Step 1 test never exercises jsGreater or jsLessOrEqual, so
    // neither would die under mutation. Both are defined by swapping the
    // operands of `<`, and an asymmetric pair is what catches a swap that was
    // dropped: `'9' > '10'` is TRUE lexicographically and false numerically.
    expect(
      jsGreater('9', '10'),
      isTrue,
      reason:
          "'9' > '10' compares two strings by code unit, so it is true where "
          'the numeric comparison would be false.',
    );
    expect(
      jsGreater(1, 2),
      isFalse,
      reason: '1 > 2 is `2 < 1`, which is false.',
    );
    // Equality is the only input that separates `b < a` from `!(a < b)`: both
    // answer the same on every strict ordering and on NaN, and they disagree
    // here. Measured — writing jsGreater as the negation survived every other
    // assertion in this test.
    expect(
      jsGreater(2, 2),
      isFalse,
      reason: '2 > 2 is `2 < 2`, which is false — not the negation of `2 < 2`.',
    );
    expect(
      jsLessOrEqual(2, 2),
      isTrue,
      reason:
          '2 <= 2 is `!(2 < 2)`, which is true — the equal case is the '
          'whole point of the negation.',
    );
    expect(
      jsLessOrEqual(3, 2),
      isFalse,
      reason: '3 <= 2 is `!(2 < 3)`, which is false.',
    );
    expect(
      jsLessOrEqual(double.nan, double.nan),
      isFalse,
      reason:
          'Both NaN operators are false rather than one being true, which is '
          'the consequence of the negation being guarded by the undefined '
          'outcome instead of applied to it.',
    );
    expect(
      jsGreaterOrEqual(2, 2),
      isTrue,
      reason: '2 >= 2 is `!(2 < 2)`, which is true.',
    );
  });

  test('typeof reports the JavaScript names', () {
    expect(jsTypeof(1), 'number', reason: 'JavaScript has one number type.');
    expect(jsTypeof('a'), 'string', reason: 'typeof a string.');
    expect(
      jsTypeof(null),
      'object',
      reason: 'typeof null is object, a famous JavaScript quirk.',
    );
    expect(
      jsTypeof(JsUndefined.instance),
      'undefined',
      reason: 'typeof undefined.',
    );
    expect(
      jsTypeof(<Object?>[]),
      'object',
      reason: 'typeof an array is object.',
    );
  });
}
