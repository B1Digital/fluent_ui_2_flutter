import 'dart:math' as math;

import 'array_stats.dart' as array;
import 'ticks.dart' as numeric;

/// One histogram bin (`d3-array/src/bin.js:80-83`).
class Bin {
  /// Creates an empty bin spanning `[x0, x1]`.
  Bin(this.x0, this.x1);

  /// The lower bound, inclusive.
  final double x0;

  /// The upper bound, exclusive except in the last bin.
  final double x1;

  /// The data that fell in this bin, in input order.
  final List<Object> values = <Object>[];
}

/// The histogram generator (`d3-array/src/bin.js:10-125`).
///
/// ponytail: the automatic-domain path is not ported. Both upstream call sites
/// — `PlotlySchemaAdapter.ts:8` and `VegaLiteSchemaAdapter.ts:50` — set an
/// explicit constant domain, which makes `bin.js:37` (`nice`) and
/// `bin.js:52-65` (extend the upper bound by one tick) unreachable. Add them
/// only if a caller ever omits the domain.
class Binner {
  /// Creates a binner with no domain and no thresholds.
  ///
  /// Both must be set — via [domain] and one of [thresholdsList] or
  /// [thresholdCount] — before [call], because the defaults upstream infers
  /// (`extent` and `sturges`, `bin.js:11-13`) are part of the omitted
  /// automatic-domain path.
  Binner();

  double? _x0;
  double? _x1;
  List<double>? _thresholds;
  int? _count;

  /// Sets the constant domain to `[x0, x1]` (`bin.js:116-118`).
  Binner domain(double x0, double x1) {
    _x0 = x0;
    _x1 = x1;
    return this;
  }

  /// Sets the explicit thresholds [tz] (`bin.js:120-122`).
  ///
  /// The list is copied, because `bin.js:69` is careful never to mutate an
  /// array owned by the caller and [call] trims in place.
  Binner thresholdsList(List<double> tz) {
    _thresholds = List<double>.of(tz);
    _count = null;
    return this;
  }

  /// Asks for roughly [maxbins] uniform bins (`bin.js:35-38`).
  Binner thresholdCount(int maxbins) {
    _count = maxbins;
    _thresholds = null;
    return this;
  }

  /// Bins [data], reading each datum's value with [value].
  ///
  /// [value] defaults to `d3.identity` (`bin.js:11`), which here means casting
  /// the datum to a `double`.
  List<Bin> call(List<Object> data, {double Function(Object d)? value}) {
    final read = value ?? ((Object d) => d as double);
    final values = data.map(read).toList(growable: false);
    final x0 = _x0!;
    final x1 = _x1!;

    double? step;
    List<double> tz;
    if (_thresholds != null) {
      tz = List<double>.of(_thresholds!);
    } else {
      final tn = _count!.toDouble();
      tz = numeric.ticks(x0, x1, tn);
      // bin.js:43 — a domain aligned with the first tick lets the assignment
      // quantize instead of bisecting.
      if (tz.isNotEmpty && tz.first <= x0) {
        step = numeric.tickIncrement(x0, x1, tn);
      }
      if (tz.isNotEmpty && tz.last >= x1) {
        // bin.js:63 — with an explicit domain the last threshold is dropped
        // rather than the domain being extended. `sublist` rather than
        // `removeLast`, because `ticks` returns a fixed-length list
        // (`ticks.dart` builds it with `List<double>.filled`), so the plan's
        // `removeLast` threw `Unsupported operation`. 1 is the single trailing
        // threshold being dropped.
        tz = tz.sublist(0, tz.length - 1);
      }
    }

    // bin.js:70-73 — trim thresholds outside the domain. Upstream relies on an
    // out-of-range index reading `undefined`, which compares false; the bounds
    // checks below are that same stop condition written explicitly.
    var a = 0;
    var b = tz.length;
    while (a < tz.length && tz[a] <= x0) {
      a++;
    }
    while (b > a && tz[b - 1] > x1) {
      b--;
    }
    tz = tz.sublist(a, b);
    final m = tz.length;

    // 1 extra bin, because m interior cuts divide the domain into m + 1 spans
    // (`bin.js:75`).
    final bins = List<Bin>.generate(
      m + 1,
      (int i) => Bin(i > 0 ? tz[i - 1] : x0, i < m ? tz[i] : x1),
      growable: false,
    );

    // 0 would make the quantisation below divide by zero; upstream reaches the
    // same conclusion by testing `step > 0` and `step < 0` separately
    // (`bin.js:87,93`).
    if (step != null && step.isFinite && step != 0) {
      // bin.js:86-100.
      for (var i = 0; i < values.length; i++) {
        final x = values[i];
        if (x.isNaN || x < x0 || x > x1) {
          continue;
        }
        if (step > 0) {
          bins[math.min(m, ((x - x0) / step).floor())].values.add(data[i]);
        } else {
          // A negative `step` is a reciprocal, so this multiplies where the
          // positive branch divides (`ticks.dart`'s note on `tickIncrement`).
          final j = ((x0 - x) * step).floor();
          // 1 corrects the off-by-one that rounding can leave (`bin.js:97`).
          bins[math.min(m, j + (j < m && tz[j] <= x ? 1 : 0))].values.add(
            data[i],
          );
        }
      }
    } else {
      // bin.js:102-107.
      final bisect = array.bisector<double>((double v) => v);
      for (var i = 0; i < values.length; i++) {
        final x = values[i];
        if (x.isNaN || x < x0 || x > x1) {
          continue;
        }
        // 0 and m bound the search to the trimmed thresholds (`bin.js:104`).
        bins[bisect.right(tz, x, 0, m)].values.add(data[i]);
      }
    }
    return bins;
  }
}

/// A new [Binner] (`d3-array/src/bin.js:10`).
Binner bin() => Binner();
