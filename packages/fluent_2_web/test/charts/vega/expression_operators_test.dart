import 'package:fluent_2_web/src/charts/internal/vega/expression.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Object? eval(
    String expr, [
    Map<String, Object?> datum = const <String, Object?>{},
  ]) => evaluateVegaExpression(expr, datum);

  test('logical and and or return the OPERAND, not a boolean', () {
    expect(
      eval("0 || 'fallback'"),
      'fallback',
      reason: 'ts:290-298: JavaScript || yields the first truthy operand.',
    );
    expect(
      eval("'a' || 'b'"),
      'a',
      reason: 'ts:295 short-circuits on the first truthy value.',
    );
    expect(
      eval("'a' && 'b'"),
      'b',
      reason: 'ts:300-307: && yields the last operand.',
    );
    expect(
      eval("0 && 'b'"),
      0,
      reason: 'ts:305 yields the falsy left operand unchanged.',
    );
  });

  test('plus concatenates when either operand is a string', () {
    expect(eval("'a' + 1"), 'a1', reason: 'ts:364-367.');
    expect(eval("1 + 'a'"), '1a', reason: 'ts:364-367.');
    expect(eval('1 + 2'), 3, reason: 'ts:367.');
    expect(
      eval("'a' + null"),
      'anull',
      reason: 'String(null) is the four-letter word.',
    );
  });

  test('loose and strict equality differ across types', () {
    expect(eval("1 == '1'"), true, reason: 'ts:316-318.');
    expect(eval("1 === '1'"), false, reason: 'ts:320-321.');
    expect(eval("1 != '1'"), false, reason: 'ts:323-325.');
    expect(eval("1 !== '1'"), true, reason: 'ts:327-328.');
  });

  test(
    'equality chains left-associatively, which is a real JavaScript trap',
    () {
      expect(
        eval('1 == 1 == 1'),
        true,
        reason:
            'ts:311-331 loops, so this is (1 == 1) == 1, i.e. true == 1, i.e. '
            'true.',
      );
    },
  );

  test('comparison coerces mixed operands to number', () {
    expect(eval("'10' > 9"), true, reason: 'ts:335-355 coerces the string.');
    expect(
      eval("'a' < 'b'"),
      true,
      reason: 'Two strings compare lexicographically.',
    );
    // The other two arms of ts:335-356. Without these, swapping `case '<='`
    // for `case '>='` in the comparison level is a mutation no test kills.
    expect(
      eval('1 <= 2'),
      true,
      reason:
          "ts:347-349: the `case '<='` arm, which is `!(b < a)`. The operands "
          'differ deliberately — `2 <= 2` is also true under `>=`, so it '
          'cannot tell the two arms apart.',
    );
    expect(
      eval('1 >= 2'),
      false,
      reason: "ts:350-352: the `case '>='` arm, which is `!(a < b)`.",
    );
  });

  test('the ternary selects the right branch', () {
    expect(eval("1 ? 'y' : 'n'"), 'y', reason: 'ts:278-288.');
    expect(
      eval("0 ? 'y' : 'n'"),
      'n',
      reason: 'ts:285 uses JavaScript truthiness.',
    );
    expect(
      eval("'' ? 'y' : 'n'"),
      'n',
      reason:
          'The empty string is falsy; a Dart bool cast would have thrown here.',
    );
  });

  test('the ternary is eager, evaluating both branches before selecting', () {
    expect(
      eval('1 ? 1 : (1 / 0)'),
      1,
      reason:
          'ts:282-285 parses both branches then picks. The port matches: this '
          'is a single-pass parser-evaluator, so the untaken branch has to be '
          'walked to consume its tokens, and walking it evaluates it.',
    );
  });

  test('a realistic Vega filter expression', () {
    expect(
      eval("datum.value > 10 && datum.category != 'x'", <String, Object?>{
        'value': 20,
        'category': 'y',
      }),
      true,
      reason: 'The composite of ts:300-307 and ts:311-331 over a real datum.',
    );
  });

  test('precedence: multiplicative binds tighter than additive, which binds '
      'tighter than comparison', () {
    expect(eval('1 + 2 * 3'), 7, reason: 'ts:220-231 grammar.');
    expect(eval('1 + 2 > 2'), true, reason: 'ts:220-231 grammar.');
    expect(eval('1 > 2 == false'), true, reason: 'ts:220-231 grammar.');
  });

  test('NaN propagates through arithmetic and poisons every comparison', () {
    expect(
      (eval("toNumber('x') + 1")! as double).isNaN,
      isTrue,
      reason: 'NaN + 1 is NaN.',
    );
    expect(
      eval("toNumber('x') > 0"),
      false,
      reason: 'Every NaN comparison is false.',
    );
    expect(
      eval("toNumber('x') == toNumber('x')"),
      false,
      reason: 'NaN equals nothing.',
    );
  });
}
