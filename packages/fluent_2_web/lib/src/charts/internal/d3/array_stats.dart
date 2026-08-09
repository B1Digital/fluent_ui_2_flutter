import 'dart:math' as math;

/// JavaScript's `<` for the value kinds d3 is fed here: numbers, dates and
/// strings. Returns `false` whenever either side is NaN or the kinds differ,
/// which is what a JS relational comparison against a non-number does.
bool _lessThan(Object a, Object b) {
  if (a is num && b is num) {
    return a < b;
  }
  if (a is DateTime && b is DateTime) {
    return a.isBefore(b);
  }
  if (a is String && b is String) {
    return a.compareTo(b) < 0;
  }
  return false;
}

/// Reproduces d3's `value >= value` self-test, which rejects NaN and anything
/// that is not comparable with itself (`d3-array/src/min.js:6`).
bool _selfComparable(Object v) => !(v is num && v.isNaN);

/// JavaScript's unary `+` for the same value kinds.
///
/// A `null` stays `null` so callers can reproduce d3's `value != null` guard;
/// everything uncoercible becomes NaN, which every caller below then skips.
double? _toNumber(Object? v) {
  if (v is num) {
    return v.toDouble();
  }
  if (v is DateTime) {
    return v.millisecondsSinceEpoch.toDouble();
  }
  if (v is String) {
    return double.tryParse(v) ?? double.nan;
  }
  return v == null ? null : double.nan;
}

/// The smallest value in [values], or `null` when there is none
/// (`d3-array/src/min.js:1-20`).
///
/// Nulls and NaNs are skipped, and an empty input yields `null` rather than
/// throwing: 32 upstream call sites dereference the result with TypeScript's
/// `!`, so a caller must be free to reproduce the resulting NaN.
T? min<T extends Comparable<Object>>(
  Iterable<Object?> values, {
  T? Function(Object? d, int i)? accessor,
}) {
  T? result;
  // -1 pre-increments to 0 on the first element, as `min.js:11` does.
  var index = -1;
  for (final raw in values) {
    index++;
    final value = accessor == null ? raw as T? : accessor(raw, index);
    if (value == null) {
      continue;
    }
    if (result == null) {
      if (_selfComparable(value)) {
        result = value;
      }
    } else if (_lessThan(value, result)) {
      result = value;
    }
  }
  return result;
}

/// The largest value in [values], or `null` (`d3-array/src/max.js:1-20`).
///
/// Empty and NaN handling matches [min].
T? max<T extends Comparable<Object>>(
  Iterable<Object?> values, {
  T? Function(Object? d, int i)? accessor,
}) {
  T? result;
  // As in [min] (`max.js:11`).
  var index = -1;
  for (final raw in values) {
    index++;
    final value = accessor == null ? raw as T? : accessor(raw, index);
    if (value == null) {
      continue;
    }
    if (result == null) {
      if (_selfComparable(value)) {
        result = value;
      }
    } else if (_lessThan(result, value)) {
      result = value;
    }
  }
  return result;
}

/// `(min, max)` in one pass (`d3-array/src/extent.js:1-29`). Both halves are
/// `null` when nothing comparable was seen.
(T?, T?) extent<T extends Comparable<Object>>(
  Iterable<Object?> values, {
  T? Function(Object? d, int i)? accessor,
}) {
  T? lo;
  T? hi;
  // As in [min] (`extent.js:16`).
  var index = -1;
  for (final raw in values) {
    index++;
    final value = accessor == null ? raw as T? : accessor(raw, index);
    if (value == null) {
      continue;
    }
    if (lo == null) {
      if (_selfComparable(value)) {
        lo = value;
        hi = value;
      }
    } else {
      if (_lessThan(value, lo)) {
        lo = value;
      }
      if (_lessThan(hi!, value)) {
        hi = value;
      }
    }
  }
  return (lo, hi);
}

/// The sum of [values] (`d3-array/src/sum.js:1-18`).
///
/// `sum.js:5` is `if (value = +value)`, a truthiness test: it skips `0`, `-0`,
/// `NaN` and anything that coerces to them. Skipping a zero is harmless;
/// skipping a NaN is not, and is the reason the result is never NaN. An empty
/// input returns `0.0`, not `null`.
double sum(
  Iterable<Object?> values, {
  num? Function(Object? d, int i)? accessor,
}) {
  // 0 is the seed `sum.js:2` uses, and the value returned for an empty input.
  var total = 0.0;
  // As in [min] (`sum.js:10`).
  var index = -1;
  for (final raw in values) {
    index++;
    final value = accessor == null
        ? _toNumber(raw)
        : accessor(raw, index)?.toDouble();
    // 0 is skipped because it is falsy in JavaScript (`sum.js:5`).
    if (value == null || value.isNaN || value == 0) {
      continue;
    }
    total += value;
  }
  return total;
}

/// The arithmetic mean, or `null` when nothing numeric was seen
/// (`d3-array/src/mean.js:1-19`).
double? mean(
  Iterable<Object?> values, {
  num? Function(Object? d, int i)? accessor,
}) {
  var count = 0;
  // 0 is the accumulator seed of `mean.js:3`.
  var total = 0.0;
  // As in [min] (`mean.js:11`).
  var index = -1;
  for (final raw in values) {
    index++;
    final value = accessor == null
        ? _toNumber(raw)
        : accessor(raw, index)?.toDouble();
    if (value == null || value.isNaN) {
      continue;
    }
    count++;
    total += value;
  }
  // `mean.js:18` is `if (count) return sum / count`, so nothing numeric means
  // no result at all rather than a division by zero.
  return count == 0 ? null : total / count;
}

/// The median (`d3-array/src/median.js:3-5`, which is `quantile(values, 0.5)`).
double? median(
  Iterable<Object?> values, {
  num? Function(Object? d, int i)? accessor,
}) {
  final numbers = <double>[];
  // As in [min] (`number.js:8`, the `numbers` generator quantile filters with).
  var index = -1;
  for (final raw in values) {
    index++;
    final value = accessor == null
        ? _toNumber(raw)
        : accessor(raw, index)?.toDouble();
    if (value == null || value.isNaN) {
      continue;
    }
    numbers.add(value);
  }
  numbers.sort();
  // 0.5 is the median's quantile probability (`median.js:4`).
  return quantile(numbers, 0.5);
}

/// The R-7 quantile of an already-ascending [sorted]
/// (`d3-array/src/quantile.js:10-21`).
///
/// d3 selects with quickselect over an unsorted copy; sorting first reaches the
/// same answer, and every caller in this port already holds sorted data.
double? quantile(List<double> sorted, double p) {
  final n = sorted.length;
  // 0 elements or a NaN probability returns undefined upstream
  // (`quantile.js:12`).
  if (n == 0 || p.isNaN) {
    return null;
  }
  // 0 and 2 are the bounds of `quantile.js:13`: at or below the first
  // probability, or with too few values to interpolate between, the minimum is
  // the answer.
  if (p <= 0 || n < 2) {
    return sorted.first;
  }
  // 1 is the upper probability bound (`quantile.js:14`).
  if (p >= 1) {
    return sorted.last;
  }
  // 1 converts the length to the largest index (`quantile.js:16`).
  final i = (n - 1) * p;
  final i0 = i.floor();
  final value0 = sorted[i0];
  // 1 is the neighbour R-7 interpolates towards (`quantile.js:19`).
  final value1 = sorted[i0 + 1];
  return value0 + (value1 - value0) * (i - i0);
}

/// `[start, start + step, …)` up to but excluding [stop]
/// (`d3-array/src/range.js:1-13`).
///
/// Each element is `start + i * step`, not a running total, so the accumulated
/// error matches JavaScript's exactly — `range(0, 1, 0.1)` yields
/// `0.30000000000000004` at the fourth element in both.
List<double> range(double start, double stop, [double step = 1]) {
  // 0 is the floor `range.js:5` clamps the count to, so a stop behind start
  // with a positive step produces an empty list rather than a negative length.
  final n = math.max(0, ((stop - start) / step).ceil());
  return List<double>.generate(n, (int i) => start + i * step, growable: false);
}

/// Ascending order for the value kinds d3 sorts here
/// (`d3-array/src/ascending.js:2`).
///
/// d3 returns `NaN` for a null or incomparable pair. A Dart comparator must
/// return an `int`, and V8's sort coerces a NaN comparator result to "equal",
/// so this returns `0` in exactly those cases. [Bisector] therefore cannot use
/// the return value alone to detect an incomparable needle, and tests for NaN
/// itself.
int ascending(Object? a, Object? b) {
  if (a == null || b == null) {
    // 0 stands in for upstream's NaN, per the note above.
    return 0;
  }
  if (_lessThan(a, b)) {
    // -1 orders a before b (`ascending.js:2`).
    return -1;
  }
  if (_lessThan(b, a)) {
    // 1 orders a after b (`ascending.js:2`).
    return 1;
  }
  return 0;
}

/// Binary search over a sorted list, keyed by an accessor
/// (`d3-array/src/bisector.js:4-52`).
class Bisector<T> {
  /// Creates a bisector reading its sort key with [accessor].
  Bisector(this.accessor);

  /// Extracts the sort key from an element.
  final Comparable<Object> Function(T d) accessor;

  /// The lowest index at which [x] could be inserted keeping the order
  /// (`d3-array/src/bisector.js:22-32`).
  ///
  /// Returns [hi] immediately when [x] is not comparable with itself — NaN,
  /// most often — rather than looping (`bisector.js:24`).
  int left(List<T> array, Object x, [int lo = 0, int? hi]) {
    var low = lo;
    var high = hi ?? array.length;
    if (low < high) {
      if (ascending(x, x) != 0 || (x is num && x.isNaN)) {
        return high;
      }
      do {
        // 1 halves the interval: `>>> 1` is the unsigned midpoint of
        // `bisector.js:26`.
        final mid = (low + high) >>> 1;
        if (ascending(accessor(array[mid]), x) < 0) {
          // 1 moves past the midpoint, which is known to be too small.
          low = mid + 1;
        } else {
          high = mid;
        }
      } while (low < high);
    }
    return low;
  }

  /// The highest such index (`d3-array/src/bisector.js:34-44`).
  ///
  /// Differs from [left] only in comparing with `<=`, which steps past an
  /// equal element instead of stopping at it (`bisector.js:39`).
  int right(List<T> array, Object x, [int lo = 0, int? hi]) {
    var low = lo;
    var high = hi ?? array.length;
    if (low < high) {
      if (ascending(x, x) != 0 || (x is num && x.isNaN)) {
        return high;
      }
      do {
        // As in [left] (`bisector.js:38`).
        final mid = (low + high) >>> 1;
        if (ascending(accessor(array[mid]), x) <= 0) {
          low = mid + 1;
        } else {
          high = mid;
        }
      } while (low < high);
    }
    return low;
  }

  /// The index of the element nearest [x] (`d3-array/src/bisector.js:46-49`).
  int center(List<T> array, Object x, [int lo = 0, int? hi]) {
    final high = hi ?? array.length;
    // 1 is subtracted so `left` can never return the length itself, leaving
    // `array[i]` addressable below (`bisector.js:47`).
    final i = left(array, x, lo, high - 1);
    if (i > lo) {
      final before = _delta(array[i - 1], x);
      final at = _delta(array[i], x);
      // `before > -at` compares the two distances without an `abs`, because
      // `before` is negative and `at` positive when `x` sits between them
      // (`bisector.js:48`).
      if (before > -at) {
        return i - 1;
      }
    }
    return i;
  }

  /// The signed distance from the key of [d] to [x] (`bisector.js:15`, which
  /// is a bare subtraction and therefore only defined for numbers).
  double _delta(T d, Object x) {
    final key = accessor(d);
    if (key is num && x is num) {
      return key.toDouble() - x.toDouble();
    }
    if (key is DateTime && x is DateTime) {
      return (key.millisecondsSinceEpoch - x.millisecondsSinceEpoch).toDouble();
    }
    return ascending(key, x).toDouble();
  }
}

/// A [Bisector] over [accessor] (`d3-array/src/bisector.js:4`).
Bisector<T> bisector<T>(Comparable<Object> Function(T d) accessor) =>
    Bisector<T>(accessor);
