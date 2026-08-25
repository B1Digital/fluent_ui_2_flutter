import 'dart:math' as math;

/// τ, one full turn in radians (`d3-shape/src/math.js:12`).
const double tau = 2 * math.pi;

/// π/2 (`d3-shape/src/math.js:11`).
const double halfPi = math.pi / 2;

/// JavaScript's `Math.round`, which rounds halves **up** — towards positive
/// infinity — while Dart's `num.round()` rounds them away from zero.
///
/// They disagree on every negative half: `Math.round(-0.5)` is `-0` where
/// `(-0.5).round()` is `-1`, and `Math.round(-2.5)` is `-2` where
/// `(-2.5).round()` is `-3`. d3 rounds inside `tickSpec`
/// (`d3-array/src/ticks.js:13-14,20-21`), inside `clampi`
/// (`d3-color/src/color.js:293`) and inside the integer format types
/// (`d3-format/src/formatTypes.js:7,13,17,18`), so a bare `.round()` anywhere
/// in this directory is a parity bug. Also unlike `num.round()`, this returns
/// NaN and the infinities unchanged instead of throwing.
double jsRound(double x) {
  if (x.isNaN || x.isInfinite) {
    return x;
  }
  final floor = x.floorToDouble();
  // 0.5 is the tie, and JS breaks it towards positive infinity.
  final rounded = x - floor >= 0.5 ? floor + 1 : floor;
  // `floor + 1` produces +0.0 for inputs in [-0.5, 0), where JS produces -0.
  // The sign of zero is load-bearing at `d3-format/src/locale.js:77`, which
  // detects a negative value with `1 / value < 0`.
  return rounded == 0 && x.isNegative ? -0.0 : rounded;
}

/// JavaScript's `Math.log10`, which is exact at every decade boundary.
///
/// The naive `math.log(x) / math.ln10` is not: it evaluates `log10(1000)` as
/// `2.9999999999999996`, so the `Math.floor(Math.log10(step))` at
/// `d3-array/src/ticks.js:7` picks the wrong power and every tick on the chart
/// moves. Snapping the result when [x] is an exact power of ten is the whole
/// correction — no other input reaches a floor boundary.
double log10(double x) {
  final naive = math.log(x) / math.ln10;
  if (!naive.isFinite) {
    return naive;
  }
  final nearest = naive.roundToDouble();
  // 1e309 overflows to infinity and 1e-324 underflows to zero, so there is no
  // decade to snap to outside this window.
  if (nearest >= -323 && nearest <= 308 && pow10(nearest.toInt()) == x) {
    return nearest;
  }
  return naive;
}

/// JavaScript's `+('1e' + x)` — the decimal-string construction d3-scale uses
/// for powers of ten (`d3-scale/src/log.js:23-25`).
///
/// This is **not** `math.pow(10, x)`. Dart's `math.pow` with two `int`
/// arguments performs exact integer arithmetic and returns
/// `200376420520689664` for `pow(10, 23)`, which is not the double `1e23`.
/// Outside the representable window the string form saturates the way JS does:
/// `+('1e400')` is `Infinity` and `+('1e-400')` is `0`.
double pow10(int x) {
  // 1e308 is the largest finite decade and 1e-323 the smallest non-zero one.
  if (x < -323 || x > 308) {
    return x < 0 ? 0.0 : double.infinity;
  }
  return double.parse('1e$x');
}

/// JavaScript's `Math.sign`, which returns `-0` for `-0` and NaN for NaN
/// rather than collapsing either to an integer.
double jsSign(double x) {
  if (x.isNaN) {
    return double.nan;
  }
  if (x == 0) {
    return x;
  }
  return x > 0 ? 1.0 : -1.0;
}

/// JavaScript's `String(v)` for a number.
///
/// Dart appends `.0` to every integral double and prints negative zero as
/// `-0.0`; JavaScript does neither. Everything else already agrees — Dart and
/// JavaScript both print shortest round-trip digits and both switch to
/// exponential notation at or above `1e21` and below `1e-6`, verified over six
/// thousand random doubles spanning `1e-30` to `1e30`. d3 concatenates numbers
/// into strings in `formatTypes['c']` (`d3-format/src/formatTypes.js:8`), in
/// `formatDecimal` (`d3-format/src/formatDecimal.js:4`) and throughout
/// `d3-path`, so the difference is visible in formatted axis labels and in
/// exported path data.
String jsNumberToString(double v) {
  if (v.isNaN) {
    return 'NaN';
  }
  if (v.isInfinite) {
    return v.isNegative ? '-Infinity' : 'Infinity';
  }
  if (v == 0) {
    return '0';
  }
  final text = v.toString();
  // Dart writes `6.0` where `String(6)` is `6`.
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}
