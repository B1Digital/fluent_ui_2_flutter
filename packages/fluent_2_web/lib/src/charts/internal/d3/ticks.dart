import 'dart:math' as math;

import 'js_math.dart';

/// √50 — the threshold above which the tick factor is 10
/// (`d3-array/src/ticks.js:1`).
const double e10 = 7.0710678118654755;

/// √10 — the threshold above which the tick factor is 5
/// (`d3-array/src/ticks.js:2`).
const double e5 = 3.1622776601683795;

/// √2 — the threshold above which the tick factor is 2
/// (`d3-array/src/ticks.js:3`).
const double e2 = 1.4142135623730951;

/// The `[i1, i2, inc]` triple behind every tick sequence
/// (`d3-array/src/ticks.js:5-27`).
///
/// `inc` is stored **negated** when the step is fractional, because the caller
/// then recovers each value by *division* rather than multiplication. That is
/// what makes `ticks(0, 1, 10)` produce an exact `0.3` instead of
/// `0.30000000000000004`, and reproducing it is the single most important
/// detail in this file.
List<double> tickSpec(double start, double stop, double count) {
  // 0 is the floor d3 clamps the count to, so a non-positive count yields an
  // infinite step rather than a negative one (`ticks.js:6`).
  final step = (stop - start) / math.max(0, count);
  final power = log10(step).floorToDouble();
  // `Math.pow`, not the decimal-string `pow10`: ticks.js:8 uses Math.pow and
  // the two disagree on inputs this can reach. Dart's math.pow with two double
  // arguments is the same C `pow` V8 calls. 10.0 is the decade base.
  final error = step / math.pow(10.0, power).toDouble();
  // The mantissa ladder of `ticks.js:9`: a step is rounded to 1, 2, 5 or 10
  // times the decade, whichever boundary the error falls above. The thresholds
  // are the geometric means of those factors, so each is chosen when it is the
  // multiplicatively nearest.
  final factor = error >= e10
      ? 10.0
      : error >= e5
          ? 5.0
          : error >= e2
              ? 2.0
              : 1.0;
  double i1;
  double i2;
  double inc;
  if (power < 0) {
    // 10.0 to a positive exponent is the reciprocal of the fractional step.
    inc = math.pow(10.0, -power).toDouble() / factor;
    i1 = jsRound(start * inc);
    i2 = jsRound(stop * inc);
    // 1 is a single tick's worth of index: the rounding may have stepped one
    // tick outside `[start, stop]`, and d3 pulls it back in (`ticks.js:15-16`).
    if (i1 / inc < start) {
      i1 += 1;
    }
    if (i2 / inc > stop) {
      i2 -= 1;
    }
    inc = -inc;
  } else {
    inc = math.pow(10.0, power).toDouble() * factor;
    i1 = jsRound(start / inc);
    i2 = jsRound(stop / inc);
    // As above (`ticks.js:22-23`).
    if (i1 * inc < start) {
      i1 += 1;
    }
    if (i2 * inc > stop) {
      i2 -= 1;
    }
  }
  // ticks.js:25 — a fractional count between 0.5 and 2 that produced an empty
  // span is retried once at double the count. 0.5 and 2 are the literal bounds
  // upstream uses, and 2 is the doubling factor.
  if (i2 < i1 && 0.5 <= count && count < 2) {
    return tickSpec(start, stop, count * 2);
  }
  return <double>[i1, i2, inc];
}

/// Approximately [count] evenly-spaced, human-readable values covering
/// `[start, stop]` (`d3-array/src/ticks.js:29-44`).
List<double> ticks(double start, double stop, double count) {
  if (!(count > 0)) {
    return <double>[];
  }
  if (start == stop) {
    return <double>[start];
  }
  final reverse = stop < start;
  final spec =
      reverse ? tickSpec(stop, start, count) : tickSpec(start, stop, count);
  // 0, 1 and 2 index the `[i1, i2, inc]` triple `tickSpec` returns.
  final i1 = spec[0];
  final i2 = spec[1];
  final inc = spec[2];
  if (!(i2 >= i1)) {
    return <double>[];
  }
  // Both indices are inclusive, hence the + 1 (`ticks.js:35`).
  final n = (i2 - i1 + 1).toInt();
  final result = List<double>.filled(n, 0);
  if (reverse) {
    if (inc < 0) {
      for (var i = 0; i < n; i++) {
        result[i] = (i2 - i) / -inc;
      }
    } else {
      for (var i = 0; i < n; i++) {
        result[i] = (i2 - i) * inc;
      }
    }
  } else {
    if (inc < 0) {
      for (var i = 0; i < n; i++) {
        result[i] = (i1 + i) / -inc;
      }
    } else {
      for (var i = 0; i < n; i++) {
        result[i] = (i1 + i) * inc;
      }
    }
  }
  return result;
}

/// The raw `inc` from [tickSpec] (`d3-array/src/ticks.js:46-49`).
///
/// A negative return value is a **reciprocal**, not a step: divide by its
/// negation. [tickStep] does that conversion; most callers want that instead.
double tickIncrement(double start, double stop, double count) =>
    // 2 is the `inc` slot of the `[i1, i2, inc]` triple.
    tickSpec(start, stop, count)[2];

/// The signed step between consecutive ticks
/// (`d3-array/src/ticks.js:51-55`).
double tickStep(double start, double stop, double count) {
  final reverse = stop < start;
  final inc = reverse
      ? tickIncrement(stop, start, count)
      : tickIncrement(start, stop, count);
  // -1 flips the sign for a descending domain; 1 leaves an ascending one alone.
  // 1 / -inc un-negates the fractional reciprocal (`ticks.js:54`).
  return (reverse ? -1 : 1) * (inc < 0 ? 1 / -inc : inc);
}

/// Extends `[start, stop]` outwards to the nearest round tick values
/// (`d3-array/src/nice.js:3-17`).
///
/// The loop is **unbounded**, unlike the copy inside `d3-scale`'s linear scale,
/// which caps itself at ten iterations (`d3-scale/src/linear.js:29`). It
/// terminates because the step either repeats, reaches zero or stops being
/// finite.
List<double> nice(double start, double stop, double count) {
  var lo = start;
  var hi = stop;
  double? prestep;
  while (true) {
    final step = tickIncrement(lo, hi, count);
    // 0 is the degenerate-domain step, and a repeated step means the interval
    // has stopped growing (`nice.js:7`).
    if (step == prestep || step == 0 || !step.isFinite) {
      return <double>[lo, hi];
    } else if (step > 0) {
      lo = (lo / step).floorToDouble() * step;
      hi = (hi / step).ceilToDouble() * step;
    } else if (step < 0) {
      // A negative step is a reciprocal, so multiply where the branch above
      // divides (`nice.js:12-13`).
      lo = (lo * step).ceilToDouble() / step;
      hi = (hi * step).floorToDouble() / step;
    }
    prestep = step;
  }
}
