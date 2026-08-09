import 'dart:math' as math;

import '../internal/d3/js_math.dart' as d3;

/// Matches either the trailing zeros of an integer (group 1) or the digits
/// after a decimal point (group 2). Transcribed from `utilities.ts:2537`.
final RegExp _precisionPattern = RegExp(r'[1-9]([0]+$)|\.([0-9]*)');

/// Snaps a value that is within `1e-6` of an integer onto that integer.
///
/// Ports `handleFloatingPointPrecisionError` (`utilities.ts:651-654`, and
/// duplicated verbatim at
/// `chart-utilities/packages/charts/chart-utilities/src/formatter.ts:9-12`).
double handleFloatingPointPrecisionError(double n) {
  // 1e-6 is the epsilon at utilities.ts:653.
  final rounded = d3.jsRound(n);
  return (n - rounded).abs() < 1e-6 ? rounded : n;
}

/// Whether [n] is an exact power of ten.
///
/// Ports `isPowerOf10` (`utilities.ts:645-648`). Returns `false` for `0` and for
/// every negative, because `log10` yields `-Infinity` or `NaN` there and
/// `NaN % 1 == 0` is false in both languages.
bool isPowerOf10(double n) {
  final logged = d3.log10(handleFloatingPointPrecisionError(n));
  if (!logged.isFinite) {
    return false;
  }
  // 1 is the modulus at utilities.ts:647: a whole log10 means a whole decade.
  return logged % 1 == 0;
}

/// The number of digits [value] is meaningful to.
///
/// Ports `calculatePrecision` (`utilities.ts:2530-2548`). Trailing zeros on an
/// integer give a **negative** precision (`:2541-2542`), digits after a decimal
/// point give a positive one (`:2544-2545`), and anything else gives `0`
/// (`:2547`). Accepts [num] or [String], as the upstream union does.
///
/// The [num] branch renders through [d3.jsNumberToString] rather than
/// [Object.toString]: Dart prints `100.0` for the double `100`, which would
/// match the decimal group and answer `1` where upstream answers `-2`.
int calculatePrecision(Object value) {
  final text = value is num
      ? d3.jsNumberToString(value.toDouble())
      : value.toString();
  final match = _precisionPattern.firstMatch(text);
  if (match == null) {
    return 0;
  }
  final trailingZeros = match.group(1);
  if (trailingZeros != null && trailingZeros.isNotEmpty) {
    return -trailingZeros.length;
  }
  final decimals = match.group(2);
  if (decimals != null && decimals.isNotEmpty) {
    return decimals.length;
  }
  return 0;
}

/// Rounds [value] to [precision] digits, accepting a negative precision.
///
/// Ports `precisionRound` (`utilities.ts:2555-2558`). Named
/// `precisionRoundValue` so it does not collide with d3-format's own
/// `precisionRound`, which answers a different question. Rounds through
/// [d3.jsRound] because JavaScript rounds half-up while Dart rounds
/// half-away-from-zero.
double precisionRoundValue(double value, int precision, [int base = 10]) {
  // 10 is the default base at utilities.ts:2555; that branch goes through
  // [d3.pow10] because Dart's integer `math.pow` is exact where JavaScript's
  // `10 ** 23` is the double 1e23.
  final exp = base == 10
      ? d3.pow10(precision)
      : math.pow(base, precision).toDouble();
  return d3.jsRound(value * exp) / exp;
}
