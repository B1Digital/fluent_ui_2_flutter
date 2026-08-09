import 'dart:math' as math;

import '../internal/d3/js_math.dart' as d3;
import '../internal/d3/ticks.dart' as d3;

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

/// The rounded tick set used when `roundOffTickValues` is on.
///
/// Ports `calculateRoundedTicks` (`utilities.ts:663-672`). A degenerate extent
/// is floored or ceiled at zero depending on its sign, then d3's [d3.nice] and
/// [d3.ticks] do the work; the final tick is dropped when it overshoots a
/// maximum that is itself a power of ten.
List<double> calculateRoundedTicks(
  double minVal,
  double maxVal,
  int splitInto,
) {
  final finalYmin = minVal >= 0 && minVal == maxVal ? 0.0 : minVal;
  final finalYmax = minVal < 0 && minVal == maxVal ? 0.0 : maxVal;
  final ticksInterval = d3.nice(finalYmin, finalYmax, splitInto.toDouble());
  // `.toList()` is not cosmetic: [d3.ticks] builds its result with
  // `List.filled`, which is fixed-length, so [List.removeLast] below would throw
  // an UnsupportedError on it.
  final values = d3
      .ticks(ticksInterval.first, ticksInterval.last, splitInto.toDouble())
      .toList();
  if (values.isNotEmpty && values.last > finalYmax && isPowerOf10(finalYmax)) {
    values.removeLast();
  }
  return values;
}

/// The y-axis tick set, and the domain the scale is built from.
///
/// Ports `prepareDatapoints` (`utilities.ts:683-723`). Three consequences worth
/// stating, all load-bearing for the charts:
///
/// * when the data straddles zero, `0` is always a tick, because the walk starts
///   there and runs outwards in both directions;
/// * the last entry is greater than or equal to [maxVal], so the domain top is
///   stretched to the next whole interval;
/// * [splitInto] is a *target* interval count, so the returned length is at
///   least `splitInto + 1` and often more.
List<double> prepareDatapoints(
  double maxVal,
  double minVal,
  int splitInto, {
  required bool isIntegralDataset,
  bool roundedTicks = false,
}) {
  if (roundedTicks) {
    return calculateRoundedTicks(minVal, maxVal, splitInto);
  }
  final rawInterval = (maxVal - minVal) / splitInto;
  // A non-integral dataset keeps a sub-unit interval fractional and rounds
  // anything else up; 1 is the threshold at utilities.ts:695.
  final val = isIntegralDataset
      ? rawInterval.ceilToDouble()
      : (rawInterval >= 1 ? rawInterval.ceilToDouble() : rawInterval);

  final straddlesZero = minVal < 0 && maxVal >= 0;
  final points = <double>[straddlesZero ? 0 : minVal];
  // For an all-positive or all-negative dataset the seed is minVal itself, so a
  // second entry is pushed to guarantee at least one interval
  // (utilities.ts:710-711).
  if (points.first == minVal) {
    points.add(minVal + val);
  }
  if (straddlesZero) {
    while (points.last > minVal) {
      points.add(points.last - val);
    }
    final reversed = points.reversed.toList();
    points
      ..clear()
      ..addAll(reversed);
  }
  while (points.last < maxVal) {
    points.add(points.last + val);
  }
  return points;
}
