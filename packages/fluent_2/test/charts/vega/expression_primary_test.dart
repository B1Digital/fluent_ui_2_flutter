import 'package:fluent_2/src/charts/internal/vega/expression.dart';
import 'package:fluent_2/src/charts/internal/vega/js_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Object? eval(
    String expr, [
    Map<String, Object?> datum = const <String, Object?>{},
  ]) => evaluateVegaExpression(expr, datum);

  test('dot access reads an own property and misses become undefined', () {
    expect(
      eval('datum.a', <String, Object?>{'a': 7}),
      7,
      reason: 'VegaLiteExpressionEvaluator.ts:415-425.',
    );
    expect(
      eval('datum.missing', <String, Object?>{'a': 7}),
      JsUndefined.instance,
      reason:
          'VegaLiteExpressionEvaluator.ts:423-424 assigns undefined rather '
          'than throwing, and undefined is distinct from null: `datum.missing '
          '=== null` is false while `== null` is true.',
    );
  });

  test(
    'the prototype chain is unreachable, which is the whole security model',
    () {
      for (final expr in <String>[
        'datum.constructor',
        'datum.__proto__',
        'datum.toString',
        'datum.valueOf',
        'datum.hasOwnProperty',
      ]) {
        expect(
          jsTypeof(eval(expr, <String, Object?>{'a': 1})),
          'undefined',
          reason:
              'VegaLiteExpressionEvaluator.ts:37-38 uses hasOwnProperty, so '
              'every inherited member reads as undefined. Expression: $expr',
        );
      }
    },
  );

  test('an unknown identifier is rejected by name', () {
    expect(
      () => eval('globalThis'),
      throwsA(
        isA<VegaExpressionException>().having(
          (e) => e.message,
          'message',
          "Safe expression evaluator: unknown identifier 'globalThis'",
        ),
      ),
      reason: 'VegaLiteExpressionEvaluator.ts:476, message verbatim.',
    );
    expect(
      () => eval('window.alert'),
      throwsA(isA<VegaExpressionException>()),
      reason:
          'VegaLiteExpressionEvaluator.ts:475-477 rejects before any access '
          'happens.',
    );
  });

  test('calling a non-function is rejected', () {
    expect(
      () => eval('datum.a()', <String, Object?>{'a': 1}),
      throwsA(
        isA<VegaExpressionException>().having(
          (e) => e.message,
          'message',
          'Safe expression evaluator: function calls are only allowed for '
              'built-in functions',
        ),
      ),
      reason: 'VegaLiteExpressionEvaluator.ts:440-442, message verbatim.',
    );
  });

  test('bracket access stringifies its index', () {
    expect(
      eval("datum['a b']", <String, Object?>{'a b': 3}),
      3,
      reason: 'VegaLiteExpressionEvaluator.ts:426-437.',
    );
    expect(
      eval('datum[1]', <String, Object?>{'1': 'x'}),
      'x',
      reason:
          'VegaLiteExpressionEvaluator.ts:432 uses String(index) as the key, '
          'and String(1) is "1", not Dart\'s "1.0".',
    );
    expect(
      eval('datum.arr[1]', <String, Object?>{
        'arr': <Object?>[10, 20],
      }),
      20,
      reason:
          "An array's own properties are its in-range indices "
          '(`Object.prototype.hasOwnProperty.call([10, 20], "1")` is true), so '
          'VegaLiteExpressionEvaluator.ts:433 admits them.',
    );
  });

  test('the twenty-two safe functions are callable and behave like Math', () {
    expect(eval('abs(-3)'), 3, reason: 'VegaLiteExpressionEvaluator.ts:52.');
    expect(eval('ceil(1.2)'), 2, reason: 'VegaLiteExpressionEvaluator.ts:53.');
    expect(eval('floor(1.8)'), 1, reason: 'VegaLiteExpressionEvaluator.ts:54.');
    expect(
      eval('round(-0.5)'),
      -0,
      reason:
          'VegaLiteExpressionEvaluator.ts:55 uses Math.round, which is '
          "half-UP: Math.round(-0.5) is -0, whereas Dart's round() gives -1. "
          'The port routes through jsRound.',
    );
    expect(eval('sqrt(9)'), 3, reason: 'VegaLiteExpressionEvaluator.ts:56.');
    expect(
      eval('log(1)'),
      0,
      reason: 'VegaLiteExpressionEvaluator.ts:57 is the natural logarithm.',
    );
    expect(eval('exp(0)'), 1, reason: 'VegaLiteExpressionEvaluator.ts:58.');
    expect(
      eval('pow(2, 10)'),
      1024,
      reason: 'VegaLiteExpressionEvaluator.ts:59.',
    );
    expect(
      eval('min(3, 1, 2)'),
      1,
      reason: 'VegaLiteExpressionEvaluator.ts:60 is variadic.',
    );
    expect(
      eval('max(3, 1, 2)'),
      3,
      reason: 'VegaLiteExpressionEvaluator.ts:61.',
    );
    expect(
      eval("length('abc')"),
      3,
      reason: 'VegaLiteExpressionEvaluator.ts:62.',
    );
    expect(
      eval('length(1)'),
      0,
      reason:
          'VegaLiteExpressionEvaluator.ts:62 returns 0 for anything but a '
          'string or array.',
    );
    expect(
      eval("toNumber('12')"),
      12,
      reason: 'VegaLiteExpressionEvaluator.ts:63.',
    );
    expect(
      eval('toString(1)'),
      '1',
      reason: 'VegaLiteExpressionEvaluator.ts:64.',
    );
    expect(
      eval("toBoolean('')"),
      false,
      reason: 'VegaLiteExpressionEvaluator.ts:65.',
    );
    expect(
      eval('isValid(null)'),
      false,
      reason: 'VegaLiteExpressionEvaluator.ts:44.',
    );
    expect(
      eval('isValid(0)'),
      true,
      reason: 'VegaLiteExpressionEvaluator.ts:44 keeps zero.',
    );
    expect(
      eval('isNumber(NaN)'),
      false,
      reason: 'VegaLiteExpressionEvaluator.ts:46 excludes NaN.',
    );
    expect(
      eval("isString('a')"),
      true,
      reason: 'VegaLiteExpressionEvaluator.ts:47.',
    );
    expect(
      eval('isBoolean(true)'),
      true,
      reason: 'VegaLiteExpressionEvaluator.ts:48.',
    );
    expect(
      eval('isArray(1)'),
      false,
      reason: 'VegaLiteExpressionEvaluator.ts:49.',
    );
    expect(
      eval("isNaN('x')"),
      true,
      reason:
          'VegaLiteExpressionEvaluator.ts:50 is the GLOBAL isNaN, which '
          'coerces first, so a non-numeric string is NaN.',
    );
    expect(
      eval('isFinite(Infinity)'),
      false,
      reason: 'VegaLiteExpressionEvaluator.ts:51.',
    );
    expect(
      eval("isFinite('1')"),
      false,
      reason:
          'VegaLiteExpressionEvaluator.ts:51 is Number.isFinite, which does '
          'NOT coerce — unlike the global isFinite, which answers true here.',
    );
    expect(
      eval('isDate(1)'),
      false,
      reason: 'VegaLiteExpressionEvaluator.ts:45.',
    );
  });

  test('the seven constants resolve', () {
    expect(
      eval('PI'),
      closeTo(3.141592653589793, 1e-15),
      reason: 'VegaLiteExpressionEvaluator.ts:72.',
    );
    expect(
      eval('E'),
      closeTo(2.718281828459045, 1e-15),
      reason: 'VegaLiteExpressionEvaluator.ts:73.',
    );
    expect(
      eval('SQRT2'),
      closeTo(1.4142135623730951, 1e-15),
      reason: 'VegaLiteExpressionEvaluator.ts:74.',
    );
    expect(
      eval('LN2'),
      closeTo(0.6931471805599453, 1e-15),
      reason: 'VegaLiteExpressionEvaluator.ts:75.',
    );
    expect(
      eval('LN10'),
      closeTo(2.302585092994046, 1e-15),
      reason: 'VegaLiteExpressionEvaluator.ts:76.',
    );
    expect(
      (eval('NaN')! as double).isNaN,
      isTrue,
      reason: 'VegaLiteExpressionEvaluator.ts:77.',
    );
    expect(
      eval('Infinity'),
      double.infinity,
      reason: 'VegaLiteExpressionEvaluator.ts:78.',
    );
  });

  test('unary minus, plus and not', () {
    expect(eval('-3'), -3, reason: 'VegaLiteExpressionEvaluator.ts:400-403.');
    expect(
      eval("+'3'"),
      3,
      reason: 'VegaLiteExpressionEvaluator.ts:404-407 coerces with unary plus.',
    );
    expect(
      eval('!0'),
      true,
      reason:
          'VegaLiteExpressionEvaluator.ts:396-399 uses JavaScript truthiness.',
    );
    expect(
      eval("!'a'"),
      false,
      reason: 'VegaLiteExpressionEvaluator.ts:396-399.',
    );
  });

  test('multiplicative operators including the sign of the remainder', () {
    expect(
      eval('7 * 6'),
      42,
      reason: 'VegaLiteExpressionEvaluator.ts:381-383.',
    );
    expect(
      eval('7 / 2'),
      3.5,
      reason:
          'VegaLiteExpressionEvaluator.ts:384-386: JavaScript division is '
          'always floating point.',
    );
    expect(
      eval('-7 % 3'),
      -1,
      reason:
          "VegaLiteExpressionEvaluator.ts:387-389: JavaScript's % keeps the "
          "dividend's sign, unlike Dart's %, which returns 2 here.",
    );
  });

  test('a parenthesised expression parses', () {
    expect(
      eval('(1 + 2) * 3'),
      9,
      reason: 'VegaLiteExpressionEvaluator.ts:491-496.',
    );
  });

  test('trailing junk is rejected', () {
    expect(
      () => eval('1 2'),
      throwsA(isA<VegaExpressionException>()),
      reason:
          'VegaLiteExpressionEvaluator.ts:246-250 requires eof after the '
          'expression.',
    );
  });
}
