import 'package:fluent_2/src/charts/internal/vega/expression.dart';
import 'package:fluent_2/src/charts/internal/vega/js_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String> types(String expr) =>
      tokenizeVegaExpression(expr).map((t) => t.type).toList();

  test('numbers accept decimals and signed exponents', () {
    expect(
      tokenizeVegaExpression('1.5e-3').first.value,
      1.5e-3,
      reason: 'VegaLiteExpressionEvaluator.ts:99-113.',
    );
    expect(
      tokenizeVegaExpression('.5').first.value,
      0.5,
      reason:
          'VegaLiteExpressionEvaluator.ts:99 admits a leading dot when a '
          'digit follows.',
    );
  });

  test('a malformed numeric literal is reported rather than truncated', () {
    // hardened, and the only place this port departs from `:113`. The scanner
    // consumes `[0-9.]*`, so `1.2.3` reaches `parseFloat` whole and comes back
    // 1.2 with the trailing `.3` gone; `1e` comes back 1. Both are reported.
    expect(
      () => tokenizeVegaExpression('1.2.3'),
      throwsA(
        isA<VegaExpressionException>().having(
          (e) => e.message,
          'message',
          "Safe expression evaluator: malformed number '1.2.3' at position 0",
        ),
      ),
      reason:
          'VegaLiteExpressionEvaluator.ts:101-113 scans the second dot into '
          'the literal and parseFloat drops it silently.',
    );
    expect(
      () => tokenizeVegaExpression('a + 1e'),
      throwsA(
        isA<VegaExpressionException>().having(
          (e) => e.message,
          'message',
          "Safe expression evaluator: malformed number '1e' at position 4",
        ),
      ),
      reason:
          'VegaLiteExpressionEvaluator.ts:104-111 admits an exponent marker '
          'with no digits behind it; the position is the literal, not the '
          'expression.',
    );
  });

  test('a lone dot is punctuation, not a number', () {
    expect(
      types('a.b'),
      <String>['ident', '.', 'ident', 'eof'],
      reason:
          'VegaLiteExpressionEvaluator.ts:99 requires a digit after the dot.',
    );
  });

  test('strings handle both quote styles and the five escapes', () {
    expect(
      tokenizeVegaExpression(r"'a\nb\tc\\d\'e'").first.value,
      "a\nb\tc\\d'e",
      reason: 'VegaLiteExpressionEvaluator.ts:127-145.',
    );
    expect(
      tokenizeVegaExpression(r'"a\qb"').first.value,
      'aqb',
      reason:
          'VegaLiteExpressionEvaluator.ts:143-144: an unknown escape yields '
          'the raw character.',
    );
  });

  test('an unterminated string still emits a token', () {
    expect(
      tokenizeVegaExpression("'abc").first.value,
      'abc',
      reason:
          'VegaLiteExpressionEvaluator.ts:152-154 only skips the closing '
          'quote when present.',
    );
    // The value alone does not observe the `i < expr.length` guard at `:152` —
    // skipping a quote that is not there leaves the same string. The cursor is
    // where the difference shows, and `:213` writes it onto the eof token. 4 is
    // the length of "'abc", which is where an unterminated scan must stop.
    expect(
      tokenizeVegaExpression("'abc").last.start,
      4,
      reason:
          'VegaLiteExpressionEvaluator.ts:152-154: an absent closing quote '
          'advances the cursor past the end of the expression on no branch.',
    );
  });

  test('the four keywords become literal tokens', () {
    expect(
      tokenizeVegaExpression('true').first.type,
      'boolean',
      reason: 'ts:167-169.',
    );
    expect(
      tokenizeVegaExpression('false').first.value,
      false,
      reason: 'ts:170-172.',
    );
    expect(
      tokenizeVegaExpression('null').first.value,
      isNull,
      reason: 'ts:173-175.',
    );
    expect(
      tokenizeVegaExpression('undefined').first.value,
      same(JsUndefined.instance),
      reason:
          'ts:176-178 emits a null-typed token whose value is undefined, not '
          'null.',
    );
  });

  test('three-character operators win over two-character ones', () {
    expect(types('a===b'), <String>[
      'ident',
      '===',
      'ident',
      'eof',
    ], reason: 'ts:190-194.');
    expect(types('a!==b'), <String>[
      'ident',
      '!==',
      'ident',
      'eof',
    ], reason: 'ts:190-194.');
    expect(types('a==b'), <String>[
      'ident',
      '==',
      'ident',
      'eof',
    ], reason: 'ts:195-199.');
  });

  test('identifiers admit dollar and underscore', () {
    expect(
      tokenizeVegaExpression(r'$_a1').first.value,
      r'$_a1',
      reason: 'VegaLiteExpressionEvaluator.ts:160-165.',
    );
  });

  test('an unexpected character is rejected with its position', () {
    expect(
      () => tokenizeVegaExpression('a # b'),
      throwsA(
        isA<VegaExpressionException>().having(
          (e) => e.message,
          'message',
          "Safe expression evaluator: unexpected character '#' at position 2",
        ),
      ),
      reason: 'VegaLiteExpressionEvaluator.ts:210, message verbatim.',
    );
  });

  test('the token stream always ends with eof', () {
    expect(types('1'), <String>[
      'number',
      'eof',
    ], reason: 'VegaLiteExpressionEvaluator.ts:213.');
  });
}
