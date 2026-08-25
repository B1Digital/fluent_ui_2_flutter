import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../d3/js_math.dart' as d3;
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

/// Argument [index] of a call, or `undefined` when the call passed fewer.
///
/// JavaScript binds a missing parameter to `undefined`, not to `null`, and the
/// two coerce differently: `Number(undefined)` is NaN where `Number(null)` is 0,
/// so `abs()` is NaN rather than 0.
Object? _arg(List<Object?> args, int index) =>
    index < args.length ? args[index] : JsUndefined.instance;

/// The safe built-in functions (`VegaLiteExpressionEvaluator.ts:43-66`).
///
/// There are twenty-two, not the nineteen the file's own header lists at
/// `:12-14`: that comment predates `isString`, `isBoolean` and `isArray` and is
/// stale. Every one takes the whole argument list, because `min` and `max` are
/// variadic (`:60-61`) and JavaScript lets any of them be called with the wrong
/// arity.
final Map<String, Object? Function(List<Object?>)> _safeFunctions =
    <String, Object? Function(List<Object?>)>{
      // `:44`. Zero and the empty string are valid; only null, undefined and
      // NaN are not.
      'isValid': (args) {
        final x = _arg(args, 0);
        return x != null && x is! JsUndefined && !(x is num && x.isNaN);
      },
      // `:45`. `x instanceof Date`.
      'isDate': (args) => _arg(args, 0) is DateTime,
      // `:46`.
      'isNumber': (args) {
        final x = _arg(args, 0);
        return x is num && !x.isNaN;
      },
      // `:47`.
      'isString': (args) => _arg(args, 0) is String,
      // `:48`.
      'isBoolean': (args) => _arg(args, 0) is bool,
      // `:49`.
      'isArray': (args) => _arg(args, 0) is List,
      // `:50` is the GLOBAL `isNaN`, which coerces its argument first, so
      // `isNaN('x')` is true. `Number.isNaN` would answer false.
      'isNaN': (args) => jsToNumber(_arg(args, 0)).isNaN,
      // `:51` is `Number.isFinite`, which does NOT coerce, so `isFinite('1')`
      // is false where the global `isFinite` answers true.
      'isFinite': (args) {
        final x = _arg(args, 0);
        return x is num && x.isFinite;
      },
      // `:52-58`. Each is `Math`'s own, and NaN flows through every one.
      'abs': (args) => jsToNumber(_arg(args, 0)).abs(),
      'ceil': (args) => jsToNumber(_arg(args, 0)).ceilToDouble(),
      'floor': (args) => jsToNumber(_arg(args, 0)).floorToDouble(),
      // `Math.round` is half-UP, so Math.round(-0.5) is -0 and Math.round(-1.5)
      // is -1. Dart's round() is half-away-from-zero and gives -1 and -2. Every
      // rounding site in this evaluator goes through d3.jsRound.
      'round': (args) => d3.jsRound(jsToNumber(_arg(args, 0))),
      'sqrt': (args) => math.sqrt(jsToNumber(_arg(args, 0))),
      'log': (args) => math.log(jsToNumber(_arg(args, 0))),
      'exp': (args) => math.exp(jsToNumber(_arg(args, 0))),
      // `:59`, the `**` operator over two coerced numbers.
      'pow': (args) => math
          .pow(jsToNumber(_arg(args, 0)), jsToNumber(_arg(args, 1)))
          .toDouble(),
      // `:60-61`. `Math.min()` with no arguments is +Infinity and `Math.max()`
      // is -Infinity, and one NaN anywhere poisons the whole call.
      'min': (args) => _extreme(args, takeSmaller: true),
      'max': (args) => _extreme(args, takeSmaller: false),
      // `:62`. A string's length is its UTF-16 code unit count on both sides.
      'length': (args) {
        final x = _arg(args, 0);
        if (x is String) {
          return x.length;
        }
        if (x is List) {
          return x.length;
        }
        // 0 is upstream's own fallback for every other type, including an
        // object — `length({})` is 0, not undefined.
        return 0;
      },
      // `:63-65`.
      'toNumber': (args) => jsToNumber(_arg(args, 0)),
      'toString': (args) => jsToString(_arg(args, 0)),
      'toBoolean': (args) => jsTruthy(_arg(args, 0)),
    };

/// `Math.min` when [takeSmaller], `Math.max` otherwise
/// (`VegaLiteExpressionEvaluator.ts:60-61`).
double _extreme(List<Object?> args, {required bool takeSmaller}) {
  // The identity of an empty call: `Math.min()` is +Infinity and `Math.max()`
  // is -Infinity, so the first real argument always replaces it.
  var result = takeSmaller ? double.infinity : double.negativeInfinity;
  for (final arg in args) {
    final x = jsToNumber(arg);
    if (x.isNaN) {
      return double.nan;
    }
    if (takeSmaller ? x < result : x > result) {
      result = x;
    }
  }
  return result;
}

/// The safe constants (`VegaLiteExpressionEvaluator.ts:71-79`).
const Map<String, Object?> _safeConstants = <String, Object?>{
  'PI': math.pi,
  'E': math.e,
  'SQRT2': math.sqrt2,
  'LN2': math.ln2,
  'LN10': math.ln10,
  'NaN': double.nan,
  'Infinity': double.infinity,
};

/// Every identifier an expression may name (`VegaLiteExpressionEvaluator.ts:82`).
///
/// This is the security boundary's inner wall and the reason `globalThis`,
/// `window`, `process`, `require`, `eval` and `Function` cannot be reached: a
/// name outside this set is refused at `:475-477` before any lookup happens.
/// Derived from the two tables above rather than restated, so the set cannot
/// drift from what is actually callable — the plan asked for a `const`, and a
/// hand-written copy of thirty names kept equal by eye is exactly the defect
/// `kPointWidthRatios` was deleted for.
final Set<String> kVegaAllowedIdentifiers = <String>{
  'datum',
  ..._safeFunctions.keys,
  ..._safeConstants.keys,
};

/// Recursive-descent parser and evaluator
/// (`VegaLiteExpressionEvaluator.ts:233-502`).
///
/// Upstream evaluates as it parses rather than building a tree, and so does
/// this: each level returns a *value*, not a node.
/// How deeply [evaluateVegaExpression] will re-enter its own grammar before it
/// refuses the expression.
///
/// hardened, spec §5.2 exception 2: `VegaLiteExpressionEvaluator.ts` recurses
/// unbounded, and `kVegaMaxJsonDepth` does not cover this — that guard counts
/// object nesting, and an expression arrives as one string value at JSON depth
/// 3 inside `{"transform": [{"calculate": …}]}`. So `((((…1…))))` clears the
/// depth guard however deep the parentheses go. Measured on this tree: each
/// level costs about ten frames (ternary down to primary), 2,000 levels
/// evaluated and 10,000 threw `StackOverflowError` — an `Error`, which the
/// widget's `on VegaExpressionException` clause does not catch, so it escaped
/// `build()`.
///
/// 1000 is five times the deepest expression anything in this port evaluates
/// (the 200-level parenthesis nest in `expression_matrix_test.dart`) and an
/// order of magnitude below the measured overflow, so it refuses only what no
/// authored `calculate` or `filter` contains.
const int kVegaMaxExpressionDepth = 1000;

class _VegaExpressionParser {
  _VegaExpressionParser(this._tokens, this._datum);

  final List<VegaToken> _tokens;

  /// The one binding `datum` resolves to (`:479-481`, via the context object
  /// `:522` builds).
  final Map<String, Object?> _datum;

  int _pos = 0;

  /// `:244-252`.
  Object? parse() {
    final result = _parseExpression();
    if (_peek().type != 'eof') {
      throw VegaExpressionException(
        "Safe expression evaluator: unexpected token '${_peek().type}' at "
        'position ${_peek().start}',
      );
    }
    return result;
  }

  /// `:254-256`. The stream always ends with `eof`, so this needs no bound.
  VegaToken _peek() => _tokens[_pos];

  /// `:258-262`.
  VegaToken _advance() => _tokens[_pos++];

  /// `:264-272`.
  VegaToken _expect(String type) {
    final token = _peek();
    if (token.type != type) {
      throw VegaExpressionException(
        "Safe expression evaluator: expected '$type' but got '${token.type}' "
        'at position ${token.start}',
      );
    }
    return _advance();
  }

  /// How many grammar re-entries are open, guarded by
  /// [kVegaMaxExpressionDepth].
  int _depth = 0;

  /// Runs [parse] one level deeper, refusing past [kVegaMaxExpressionDepth].
  ///
  /// The two re-entrant points are wrapped rather than the ten descent levels
  /// between them: [_parseExpression] is where a parenthesised group, a bracket
  /// index, a call argument and both ternary branches come back in, and
  /// [_parseUnary] is the one level that recurses into itself without passing
  /// through it. A parenthesis therefore costs two counts and a `!` one, so the
  /// effective ceilings are about 500 nested groups and 1000 negations — both
  /// far past anything an authored expression contains, and both short of the
  /// stack.
  T _descend<T>(T Function() parse) {
    if (++_depth > kVegaMaxExpressionDepth) {
      throw const VegaExpressionException(
        'Safe expression evaluator: Maximum expression depth exceeded',
      );
    }
    try {
      return parse();
    } finally {
      _depth--;
    }
  }

  /// `:274-276`. The grammar's entry point, which a bracket index (`:429`) and
  /// a parenthesised group (`:493`) re-enter through.
  Object? _parseExpression() => _descend(_parseTernary);

  /// `:278-288`.
  Object? _parseTernary() {
    final condition = _parseOr();
    if (_peek().type == '?') {
      _advance();
      final trueValue = _parseExpression();
      _expect(':');
      final falseValue = _parseExpression();
      // `:285` selects on JavaScript truthiness, so `'' ? a : b` is b. A Dart
      // bool cast would have thrown on every non-boolean condition.
      //
      // Both branches are evaluated before one is picked, exactly as upstream
      // does. That is not a transcription choice: this is a single-pass
      // parser-evaluator, so the untaken branch still has to be walked to
      // consume its tokens, and walking it is evaluating it. Nothing in the
      // grammar has a side effect and division by zero yields Infinity rather
      // than throwing, so the eager result is the lazy one.
      return jsTruthy(condition) ? trueValue : falseValue;
    }
    return condition;
  }

  /// `:290-298`.
  ///
  /// JavaScript's `||` returns an OPERAND, not a boolean (`:295`): `0 || 'x'`
  /// is `'x'`. Dart's `||` is typed bool-to-bool, so the port branches on
  /// [jsTruthy] and returns the untouched operand.
  Object? _parseOr() {
    var left = _parseAnd();
    while (_peek().type == '||') {
      _advance();
      final right = _parseAnd();
      left = jsTruthy(left) ? left : right;
    }
    return left;
  }

  /// `:300-308`.
  ///
  /// The mirror of [_parseOr]: `&&` yields the last operand when the left is
  /// truthy and the falsy left operand unchanged otherwise (`:305`), so
  /// `0 && 'x'` is `0` rather than `false`.
  Object? _parseAnd() {
    var left = _parseEquality();
    while (_peek().type == '&&') {
      _advance();
      final right = _parseEquality();
      left = jsTruthy(left) ? right : left;
    }
    return left;
  }

  /// `:310-333`.
  ///
  /// The loop is what makes `1 == 1 == 1` parse as `(1 == 1) == 1`, i.e.
  /// `true == 1`, i.e. true.
  Object? _parseEquality() {
    var left = _parseComparison();
    while (_peek().type == '==' ||
        _peek().type == '===' ||
        _peek().type == '!=' ||
        _peek().type == '!==') {
      final op = _advance().type;
      final right = _parseComparison();
      switch (op) {
        // `:316-318`.
        case '==':
          left = jsLooseEquals(left, right);
        // `:320-321`.
        case '===':
          left = jsStrictEquals(left, right);
        // `:323-325`.
        case '!=':
          left = !jsLooseEquals(left, right);
        // `:327-328`.
        default:
          left = !jsStrictEquals(left, right);
      }
    }
    return left;
  }

  /// `:335-356`.
  ///
  /// Upstream's `as number` casts are erased at runtime, so the four operators
  /// are JavaScript's own: two strings compare by code unit, anything else
  /// coerces to number, and every comparison against NaN is false in both
  /// directions. The four helpers in `js_value.dart` own that algorithm.
  Object? _parseComparison() {
    var left = _parseAdditive();
    while (_peek().type == '<' ||
        _peek().type == '>' ||
        _peek().type == '<=' ||
        _peek().type == '>=') {
      final op = _advance().type;
      final right = _parseAdditive();
      switch (op) {
        // `:341-343`.
        case '<':
          left = jsLess(left, right);
        // `:344-346`.
        case '>':
          left = jsGreater(left, right);
        // `:347-349`.
        case '<=':
          left = jsLessOrEqual(left, right);
        // `:350-352`.
        default:
          left = jsGreaterOrEqual(left, right);
      }
    }
    return left;
  }

  /// `:358-373`.
  Object? _parseAdditive() {
    var left = _parseMultiplicative();
    while (_peek().type == '+' || _peek().type == '-') {
      final op = _advance().type;
      final right = _parseMultiplicative();
      // `:363-367` tests BOTH operands for stringness, which [jsAdd] owns;
      // subtraction has no such branch and coerces unconditionally.
      left = op == '+'
          ? jsAdd(left, right)
          : jsToNumber(left) - jsToNumber(right);
    }
    return left;
  }

  /// `:375-393`.
  Object? _parseMultiplicative() {
    var left = _parseUnary();
    while (_peek().type == '*' || _peek().type == '/' || _peek().type == '%') {
      final op = _advance().type;
      final right = _parseUnary();
      switch (op) {
        case '*':
          left = jsToNumber(left) * jsToNumber(right);
        case '/':
          // Dart's `/` on doubles is JavaScript's: `7 / 2` is 3.5 and `1 / 0`
          // is Infinity rather than a throw.
          left = jsToNumber(left) / jsToNumber(right);
        case '%':
          // JavaScript's remainder keeps the sign of the dividend; Dart's `%`
          // is a modulo that keeps the sign of the divisor. `-7 % 3` is -1 in
          // JavaScript and 2 in Dart, so use remainder().
          left = jsToNumber(left).remainder(jsToNumber(right));
      }
    }
    return left;
  }

  /// `:395-409`. Wrapped because its three arms recurse into it directly,
  /// which is a path [_parseExpression] never sees.
  Object? _parseUnary() => _descend(_parseUnaryOperand);

  Object? _parseUnaryOperand() {
    switch (_peek().type) {
      case '!':
        _advance();
        // `:398` negates with JavaScript truthiness, so `!''` is true. A Dart
        // bool cast would have thrown on every non-boolean operand.
        return !jsTruthy(_parseUnary());
      case '-':
        _advance();
        return -jsToNumber(_parseUnary());
      case '+':
        _advance();
        return jsToNumber(_parseUnary());
    }
    return _parsePostfix();
  }

  /// `:411-460`.
  Object? _parsePostfix() {
    var value = _parsePrimary();

    while (true) {
      switch (_peek().type) {
        // `:415-425`: property access, own properties only.
        case '.':
          _advance();
          value = _member(value, _expect('ident').value! as String);
        // `:426-437`: bracket access, own properties only, key stringified.
        case '[':
          _advance();
          final index = _parseExpression();
          _expect(']');
          value = _member(value, jsToString(index));
        // `:438-453`: a call, and only a built-in is callable.
        case '(':
          if (value is! Object? Function(List<Object?>)) {
            throw const VegaExpressionException(
              'Safe expression evaluator: function calls are only allowed for '
              'built-in functions',
            );
          }
          _advance();
          final args = <Object?>[];
          if (_peek().type != ')') {
            args.add(_parseExpression());
            while (_peek().type == ',') {
              _advance();
              args.add(_parseExpression());
            }
          }
          _expect(')');
          value = value(args);
        default:
          return value;
      }
    }
  }

  /// `value[key]`, restricted to own properties
  /// (`VegaLiteExpressionEvaluator.ts:37-38`, applied at `:421` and `:433`).
  ///
  /// Dart has no prototype chain, so the half of upstream's model that blocks
  /// `constructor`, `__proto__`, `toString` and `valueOf` is satisfied
  /// structurally: a `Map` holds only what was put in it. The identifier
  /// allowlist is the half that still does work, and it stays.
  ///
  /// A miss yields `undefined`, never `null` and never a throw, because the two
  /// are distinguishable downstream: `datum.missing == null` is true while
  /// `datum.missing === null` is false.
  Object? _member(Object? value, String key) {
    if (value is Map<String, Object?>) {
      return value.containsKey(key) ? value[key] : JsUndefined.instance;
    }
    if (value is List<Object?>) {
      // An array's own properties are its in-range indices and `length` —
      // `Object.prototype.hasOwnProperty.call([1, 2], '0')` and `'length'` are
      // both true — so `datum.arr[0]` and `datum.arr.length` are reads upstream
      // allows.
      if (key == 'length') {
        return value.length;
      }
      final index = int.tryParse(key);
      if (index != null && index >= 0 && index < value.length) {
        return value[index];
      }
    }
    return JsUndefined.instance;
  }

  /// `:462-501`.
  Object? _parsePrimary() {
    final token = _peek();

    switch (token.type) {
      case 'number':
      case 'string':
      case 'boolean':
      case 'null':
        _advance();
        return token.value;

      case 'ident':
        final name = token.value! as String;
        if (!kVegaAllowedIdentifiers.contains(name)) {
          // `:476`, message verbatim.
          throw VegaExpressionException(
            "Safe expression evaluator: unknown identifier '$name'",
          );
        }
        _advance();
        if (name == 'datum') {
          return _datum;
        }
        // The allowlist is derived from these two tables, so a name that
        // reached here is in exactly one of them.
        return _safeFunctions[name] ?? _safeConstants[name];

      case '(':
        _advance();
        final result = _parseExpression();
        _expect(')');
        return result;

      default:
        // `:499`, message verbatim.
        throw VegaExpressionException(
          "Safe expression evaluator: unexpected token '${token.type}' at "
          'position ${token.start}',
        );
    }
  }
}

/// Evaluates the Vega-Lite expression [expr] against [datum]
/// (`VegaLiteExpressionEvaluator.ts:520-524`).
///
/// Only property access, arithmetic, comparison, logical operators, the
/// ternary, literals and the built-ins in [kVegaAllowedIdentifiers] are
/// reachable; assignment, an arbitrary call and any global are refused.
///
/// Returns JavaScript values: a `double` for every number, [JsUndefined] for a
/// missing property, and whatever the datum holds for a present one. Throws a
/// [VegaExpressionException] for anything the grammar or the allowlist refuses.
Object? evaluateVegaExpression(String expr, Map<String, Object?> datum) =>
    _VegaExpressionParser(tokenizeVegaExpression(expr), datum).parse();
