import 'package:flutter/foundation.dart';

import 'js_value.dart';

/// Raised for an expression this port refuses to read.
///
/// Separate from `VegaSpecException` in `spec.dart`: that one rejects the
/// document, this one rejects one `expr` string inside it.
class VegaExpressionException implements Exception {
  /// Creates an exception carrying [message].
  const VegaExpressionException(this.message);

  /// The failure, phrased exactly as upstream phrases it so a consumer matching
  /// on the string keeps working (`VegaLiteExpressionEvaluator.ts:210`).
  final String message;

  @override
  String toString() => message;
}

/// One token of a Vega-Lite expression
/// (`VegaLiteExpressionEvaluator.ts:25-29`).
@immutable
class VegaToken {
  /// Creates a token of [type] carrying [value], found at [start].
  const VegaToken({
    required this.type,
    required this.value,
    required this.start,
  });

  /// The token's kind.
  ///
  /// An operator or a piece of punctuation is its own spelling — `'==='`,
  /// `'('`, `'.'` — which is what lets the parser switch on this one field.
  /// The rest are `'number'`, `'string'`, `'boolean'`, `'null'`, `'ident'` and
  /// `'eof'`.
  final String type;

  /// The token's value: a `double` for a number, a `String` for a string or an
  /// identifier, a `bool` for a keyword, null for `null` and for `eof`, and
  /// [JsUndefined.instance] for `undefined`.
  final Object? value;

  /// The index in the source expression where this token begins.
  final int start;
}

/// Matches one whitespace character (`VegaLiteExpressionEvaluator.ts:93`).
///
/// Dart's `RegExp` is ECMAScript-compatible, so `\s` covers the same set on
/// both sides — including the non-breaking space and the Unicode separators.
final RegExp _whitespace = RegExp(r'\s');

/// Matches one decimal digit (`:99`, `:101`, `:109`).
final RegExp _digit = RegExp('[0-9]');

/// Matches one character the number scanner will consume (`:101`).
final RegExp _numberBody = RegExp(r'[0-9.]');

/// Matches a character that may open an identifier (`:160`).
final RegExp _identifierStart = RegExp(r'[a-zA-Z_$]');

/// Matches a character that may continue one (`:162`).
final RegExp _identifierBody = RegExp(r'[a-zA-Z0-9_$]');

/// The two-character operators (`VegaLiteExpressionEvaluator.ts:195`).
const Set<String> _twoCharacterOperators = <String>{
  '==',
  '!=',
  '<=',
  '>=',
  '&&',
  '||',
};

/// The single-character operators and punctuation, verbatim from `:203`.
const String _singleCharacterOperators = '+-*/%<>!.()[],?:';

/// Splits [expr] into tokens (`VegaLiteExpressionEvaluator.ts:87-215`).
///
/// The stream always ends with an `eof` token whose `start` is the length of
/// [expr], so the parser can peek one past the end without a bounds test.
///
/// Throws a [VegaExpressionException] for a character the grammar has no place
/// for, or for a malformed numeric literal.
List<VegaToken> tokenizeVegaExpression(String expr) {
  final tokens = <VegaToken>[];
  var i = 0;

  while (i < expr.length) {
    final ch = expr[i];

    // Skip whitespace (`:93-96`).
    if (_whitespace.hasMatch(ch)) {
      i++;
      continue;
    }

    // Numbers, including decimal and scientific notation (`:99-114`). A lone
    // dot is punctuation: the leading-dot form needs a digit behind it.
    if (_digit.hasMatch(ch) ||
        (ch == '.' && i + 1 < expr.length && _digit.hasMatch(expr[i + 1]))) {
      final start = i;
      while (i < expr.length && _numberBody.hasMatch(expr[i])) {
        i++;
      }
      if (i < expr.length && (expr[i] == 'e' || expr[i] == 'E')) {
        i++;
        if (i < expr.length && (expr[i] == '+' || expr[i] == '-')) {
          i++;
        }
        while (i < expr.length && _digit.hasMatch(expr[i])) {
          i++;
        }
      }
      final text = expr.substring(start, i);
      final value = double.tryParse(text);
      if (value == null) {
        // hardened: `parseFloat('1.2.3')` returns 1.2 and the trailing '.3'
        // vanishes silently (VegaLiteExpressionEvaluator.ts:113). Reporting the
        // malformed literal is strictly better and cannot change a valid
        // expression's result. The scanner admits two shapes `double.tryParse`
        // rejects — a second dot, and an exponent with no digits after it
        // (`'1e'`, which `parseFloat` reads as 1) — and both are reported here.
        throw VegaExpressionException(
          "Safe expression evaluator: malformed number '$text' at position "
          '$start',
        );
      }
      tokens.add(VegaToken(type: 'number', value: value, start: start));
      continue;
    }

    // Strings, single or double quoted (`:118-156`).
    if (ch == '"' || ch == "'") {
      final quote = ch;
      final start = i;
      i++;
      final buffer = StringBuffer();
      while (i < expr.length && expr[i] != quote) {
        if (expr[i] == r'\') {
          i++;
          if (i < expr.length) {
            // `:127-145`: five recognised escapes, and an unrecognised one
            // yields the raw character rather than the backslash before it.
            switch (expr[i]) {
              case 'n':
                buffer.write('\n');
              case 't':
                buffer.write('\t');
              case r'\':
                buffer.write(r'\');
              case "'":
                buffer.write("'");
              case '"':
                buffer.write('"');
              default:
                buffer.write(expr[i]);
            }
          }
        } else {
          buffer.write(expr[i]);
        }
        i++;
      }
      if (i < expr.length) {
        // `:152-154`: the closing quote is skipped only when there is one, so
        // an unterminated string still emits its token.
        i++;
      }
      tokens.add(
        VegaToken(type: 'string', value: buffer.toString(), start: start),
      );
      continue;
    }

    // Identifiers and keywords (`:160-182`).
    if (_identifierStart.hasMatch(ch)) {
      final start = i;
      while (i < expr.length && _identifierBody.hasMatch(expr[i])) {
        i++;
      }
      final word = expr.substring(start, i);
      switch (word) {
        case 'true':
          tokens.add(VegaToken(type: 'boolean', value: true, start: start));
        case 'false':
          tokens.add(VegaToken(type: 'boolean', value: false, start: start));
        case 'null':
          tokens.add(VegaToken(type: 'null', value: null, start: start));
        case 'undefined':
          // `:176-178`: a null-TYPED token whose value is `undefined`. The two
          // are distinct downstream — `null == undefined` is true and
          // `null === undefined` is false — so the distinction lives in the
          // value, not in the type.
          tokens.add(
            VegaToken(type: 'null', value: JsUndefined.instance, start: start),
          );
        default:
          tokens.add(VegaToken(type: 'ident', value: word, start: start));
      }
      continue;
    }

    final start = i;

    // Three-character operators first, so `===` is never read as `==` then `=`
    // (`:190-194`). `startsWith` is upstream's `slice(i, i + 3)` without the
    // end-of-string special case: a slice shorter than three characters cannot
    // equal either operator.
    if (expr.startsWith('===', i) || expr.startsWith('!==', i)) {
      final three = expr.substring(i, i + 3);
      tokens.add(VegaToken(type: three, value: three, start: start));
      i += 3;
      continue;
    }
    // 2 is the length of the operators in [_twoCharacterOperators] (`:195`).
    if (i + 2 <= expr.length) {
      final two = expr.substring(i, i + 2);
      if (_twoCharacterOperators.contains(two)) {
        tokens.add(VegaToken(type: two, value: two, start: start));
        i += 2;
        continue;
      }
    }

    // Single-character operators and punctuation (`:203-207`).
    if (_singleCharacterOperators.contains(ch)) {
      tokens.add(VegaToken(type: ch, value: ch, start: start));
      i++;
      continue;
    }

    // `:210`, message verbatim. This is the security boundary's outer wall: an
    // expression may only be built from the characters above.
    throw VegaExpressionException(
      "Safe expression evaluator: unexpected character '$ch' at position $i",
    );
  }

  // `:213`.
  tokens.add(VegaToken(type: 'eof', value: null, start: i));
  return tokens;
}
