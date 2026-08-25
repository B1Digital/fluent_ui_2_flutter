import '../d3/js_math.dart' as d3;

/// JavaScript's `undefined`, which Dart has no value for.
///
/// Dart's `null` stands for JavaScript's `null`, and the two are genuinely
/// distinct in the evaluator: `VegaLiteExpressionEvaluator.ts:173-178` emits
/// `undefined` as a `null`-typed token whose *value* is `undefined`, and
/// `:316-329` then has to tell `null == undefined` (true) from
/// `null === undefined` (false). Every function in this file therefore accepts
/// `Object?` and treats [JsUndefined.instance] as its own value.
class JsUndefined {
  const JsUndefined._();

  /// The one and only `undefined`.
  static const JsUndefined instance = JsUndefined._();

  @override
  String toString() => 'undefined';
}

/// True for every JavaScript value that is not falsy.
///
/// The falsy set is exactly `false`, `0`, `-0`, `NaN`, `''`, `null` and
/// `undefined`. Note what is **truthy**: `'0'`, `'false'`, the empty array and
/// the empty object. `VegaLiteExpressionEvaluator.ts:294-306` relies on this for
/// `&&` and `||`, which return an operand rather than a boolean.
bool jsTruthy(Object? v) {
  if (v == null || v is JsUndefined) {
    return false;
  }
  if (v is bool) {
    return v;
  }
  if (v is num) {
    return !v.isNaN && v != 0;
  }
  if (v is String) {
    return v.isNotEmpty;
  }
  // Every object, including `[]` and `{}`, is truthy.
  return true;
}

/// `typeof v`.
///
/// `typeof null` is `'object'`, which is the language's oldest bug and is
/// reproduced because an expression can test for it.
String jsTypeof(Object? v) {
  if (v is JsUndefined) {
    return 'undefined';
  }
  if (v == null) {
    return 'object';
  }
  if (v is bool) {
    return 'boolean';
  }
  if (v is num) {
    return 'number';
  }
  if (v is String) {
    return 'string';
  }
  if (v is Function) {
    return 'function';
  }
  return 'object';
}

/// `Number(v)`.
///
/// Differs from `parseFloat` in every case that matters: a trailing non-numeric
/// character makes the whole conversion NaN, the empty and whitespace-only
/// string are 0, and the radix prefixes are honoured.
double jsToNumber(Object? v) {
  if (v is JsUndefined) {
    return double.nan;
  }
  // `Number(null)` is 0; `Number(undefined)` is NaN.
  if (v == null) {
    return 0;
  }
  if (v is bool) {
    return v ? 1 : 0;
  }
  if (v is num) {
    return v.toDouble();
  }
  if (v is String) {
    final text = v.trim();
    // `Number('')` and `Number('   ')` are both 0.
    if (text.isEmpty) {
      return 0;
    }
    if (text == 'Infinity' || text == '+Infinity') {
      return double.infinity;
    }
    if (text == '-Infinity') {
      return double.negativeInfinity;
    }
    // The three ES2015 radix prefixes. A sign is NOT permitted before them, and
    // the two-character body — `0x` alone — is NaN, which is why the length
    // test is strict. 2 is the length of the prefix itself.
    if (text.length > 2 && text[0] == '0') {
      final marker = text[1].toLowerCase();
      // 16, 8 and 2 are the radices ES2015 spells for `0x`, `0o` and `0b`; 0
      // stands for "no prefix here" and falls through to the decimal parse.
      final radix = marker == 'x'
          ? 16
          : (marker == 'o' ? 8 : (marker == 'b' ? 2 : 0));
      if (radix != 0) {
        final parsed = int.tryParse(text.substring(2), radix: radix);
        return parsed == null ? double.nan : parsed.toDouble();
      }
    }
    // `double.tryParse` rejects a trailing remainder, which is exactly
    // `Number`'s behaviour. It also accepts `1.` and `.5`, as `Number` does.
    return double.tryParse(text) ?? double.nan;
  }
  if (v is List<Object?>) {
    // `Number([])` is 0 and `Number([5])` is 5, because `ToPrimitive` joins the
    // array first; anything longer joins to a string with a comma in it and so
    // fails to parse. 1 is the only length whose join is a bare element.
    if (v.isEmpty) {
      return 0;
    }
    if (v.length == 1) {
      return jsToNumber(v.first);
    }
    return double.nan;
  }
  // `Number({})` is NaN.
  return double.nan;
}

/// `String(v)`.
///
/// Number formatting routes through `d3.jsNumberToString` — the single owner of
/// JavaScript's `Number.prototype.toString` in this port — so `1.0` renders as
/// `1` and `1e21` as `1e+21`. Dart's `toString` would give `1.0`.
String jsToString(Object? v) {
  if (v is JsUndefined) {
    return 'undefined';
  }
  if (v == null) {
    return 'null';
  }
  if (v is num) {
    return d3.jsNumberToString(v.toDouble());
  }
  if (v is String) {
    return v;
  }
  if (v is bool) {
    return v ? 'true' : 'false';
  }
  if (v is List<Object?>) {
    // `Array.prototype.toString` joins with a comma and renders null and
    // undefined as the EMPTY string, not as their names.
    return v
        .map((e) => e == null || e is JsUndefined ? '' : jsToString(e))
        .join(',');
  }
  // `Object.prototype.toString`, which bracket access relies on
  // (`VegaLiteExpressionEvaluator.ts:432`).
  return '[object Object]';
}

/// `a === b`.
///
/// NaN is equal to nothing, `null` and `undefined` are distinct, and JavaScript
/// has one number type so `1 === 1.0`. Objects compare by identity.
bool jsStrictEquals(Object? a, Object? b) {
  if (a is JsUndefined) {
    return b is JsUndefined;
  }
  if (b is JsUndefined) {
    return false;
  }
  if (a == null || b == null) {
    return a == null && b == null;
  }
  if (a is num && b is num) {
    // NaN is equal to nothing, and Dart's `==` on doubles is already IEEE 754,
    // so it answers false for NaN without a branch — exactly as `-0.0 == 0` in
    // [jsTruthy] needs none. An explicit NaN guard here was measured against
    // the mutation suite and no test could kill it, because it can only ever
    // agree with the comparison below.
    return a.toDouble() == b.toDouble();
  }
  if (a is String && b is String) {
    return a == b;
  }
  if (a is bool && b is bool) {
    return a == b;
  }
  // Different primitive types, or two objects: identity.
  return identical(a, b);
}

/// True when [v] is `null` or `undefined`.
bool _isNullish(Object? v) => v == null || v is JsUndefined;

/// True when [v] is not a JavaScript object.
bool _isPrimitive(Object? v) =>
    _isNullish(v) || v is num || v is String || v is bool;

/// `a == b`, the abstract-equality algorithm
/// (`VegaLiteExpressionEvaluator.ts:316-329` chooses between this and
/// [jsStrictEquals]).
///
/// The steps are the specification's own order, and the surprising results are
/// all consequences of it: `null == 0` is **false** because null-ish values
/// equal only each other, while `'' == 0` is **true** because the string
/// coerces.
bool jsLooseEquals(Object? a, Object? b) {
  // Step 1: null and undefined equal each other and nothing else.
  if (_isNullish(a) || _isNullish(b)) {
    return _isNullish(a) && _isNullish(b);
  }
  // Step 2: same type, no coercion.
  if (a is num && b is num) {
    return jsStrictEquals(a, b);
  }
  if (a is String && b is String) {
    return a == b;
  }
  if (a is bool && b is bool) {
    return a == b;
  }
  // Step 3: a boolean coerces to a number first, on either side.
  if (a is bool) {
    return jsLooseEquals(jsToNumber(a), b);
  }
  if (b is bool) {
    return jsLooseEquals(a, jsToNumber(b));
  }
  // Step 4: number versus string coerces the string.
  if (a is num && b is String) {
    return jsStrictEquals(a, jsToNumber(b));
  }
  if (a is String && b is num) {
    return jsStrictEquals(jsToNumber(a), b);
  }
  // Step 5: object versus primitive coerces the object to a primitive, which
  // for both an array and a plain object is its string form.
  if (!_isPrimitive(a) && _isPrimitive(b)) {
    return jsLooseEquals(jsToString(a), b);
  }
  if (_isPrimitive(a) && !_isPrimitive(b)) {
    return jsLooseEquals(a, jsToString(b));
  }
  // Two objects: identity.
  return identical(a, b);
}

/// `a + b`.
///
/// `VegaLiteExpressionEvaluator.ts:364-367` tests **both** operands: if either
/// is a string the result is a concatenation, otherwise both coerce to number.
/// This is the one operator where the port cannot use Dart's own, because Dart's
/// `+` has no string-or-number union.
Object? jsAdd(Object? a, Object? b) {
  if (a is String || b is String) {
    return '${jsToString(a)}${jsToString(b)}';
  }
  return jsToNumber(a) + jsToNumber(b);
}

/// The abstract relational comparison shared by the four operators below.
///
/// Returns null for the "undefined" outcome — which is what makes every
/// comparison involving NaN false, in both directions.
bool? _relational(Object? a, Object? b) {
  // Two strings compare by UTF-16 code unit, not numerically: `'10' < '9'`.
  if (a is String && b is String) {
    return a.compareTo(b) < 0;
  }
  final x = jsToNumber(a);
  final y = jsToNumber(b);
  if (x.isNaN || y.isNaN) {
    return null;
  }
  return x < y;
}

/// `a < b` (`VegaLiteExpressionEvaluator.ts:341-343`).
bool jsLess(Object? a, Object? b) => _relational(a, b) ?? false;

/// `a > b` (`VegaLiteExpressionEvaluator.ts:344-346`), which the specification
/// evaluates as `b < a`.
bool jsGreater(Object? a, Object? b) => _relational(b, a) ?? false;

/// `a <= b` (`VegaLiteExpressionEvaluator.ts:347-349`), which the specification
/// evaluates as `!(b < a)`.
bool jsLessOrEqual(Object? a, Object? b) {
  final swapped = _relational(b, a);
  return swapped == null ? false : !swapped;
}

/// `a >= b` (`VegaLiteExpressionEvaluator.ts:350-352`), which the specification
/// evaluates as `!(a < b)`.
bool jsGreaterOrEqual(Object? a, Object? b) {
  final direct = _relational(a, b);
  return direct == null ? false : !direct;
}

/// [keys] reordered the way `Object.keys` enumerates them.
///
/// ECMA-262 `OrdinaryOwnPropertyKeys` lists ARRAY-INDEX keys first, ascending
/// *numerically*, and only then every other key in insertion order. An array
/// index is a string that round-trips a canonical integer in `[0, 2^32 - 2]`,
/// so `'3'` and `'4'` are indices while `'2.5'`, `'03'`, `'-1'` and `'1e2'` are
/// ordinary keys. A Dart map is insertion-ordered throughout, so a spec whose
/// keys are bare digit strings groups in a different order without this — in
/// `charts-vegadeclarativechart--default` the six `ctr` series enumerate
/// 3, 4, 2.5, 3.5, 2.4, 4.5 upstream against 2.5, 3.5, 3, 4, 2.4, 4.5 here,
/// and because the palette is handed out in that order four of the six come
/// out in the wrong colour.
List<String> jsObjectKeys(Iterable<String> keys) {
  // 2^32 - 2, the largest array index. `'4294967295'` is a length, not an
  // index, and enumerates as an ordinary key.
  const maxArrayIndex = 4294967294;
  final indices = <int>[];
  final rest = <String>[];
  for (final key in keys) {
    final n = int.tryParse(key);
    // `'$n' == key` is the canonical-form test: it rejects `'03'`, `'+3'` and
    // `' 3'`, which parse but are not the integer's own string.
    if (n != null && n >= 0 && n <= maxArrayIndex && '$n' == key) {
      indices.add(n);
    } else {
      rest.add(key);
    }
  }
  indices.sort();
  return <String>[for (final i in indices) '$i', ...rest];
}
