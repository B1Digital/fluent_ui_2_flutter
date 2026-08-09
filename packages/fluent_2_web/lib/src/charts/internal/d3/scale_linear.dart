import 'scale_continuous.dart';
import 'scale_tick_format.dart';
import 'ticks.dart' as numeric;

/// A linear scale (`d3-scale/src/linear.js:6-70`).
///
/// [ScaleContinuous] already carries the piecewise domain-to-range mapping; the
/// `linearish` mixin upstream adds only the three tick members below, so this
/// subclass is exactly those three.
class ScaleLinear extends ScaleContinuous {
  /// Creates the unit linear scale, domain and range both `[0, 1]`
  /// (`d3-scale/src/linear.js:61`).
  ScaleLinear();

  @override
  List<Object> ticks([int? count]) {
    // linear.js:9-12. The first and last stops are used, so a polylinear
    // domain is ticked across its full extent rather than per segment.
    final d = rawDomain;
    // 10 is the upstream default tick count (`linear.js:11`).
    return numeric
        .ticks(d.first, d.last, (count ?? 10).toDouble())
        .cast<Object>();
  }

  @override
  String Function(Object value) tickFormat([int? count, String? specifier]) {
    // linear.js:14-17. 10 is the same default as for [ticks] (`linear.js:16`).
    final d = rawDomain;
    return scaleTickFormat(d.first, d.last, count ?? 10, specifier);
  }

  /// Extends the domain endpoints to round values
  /// (`d3-scale/src/linear.js:19-55`).
  ///
  /// Two details differ from the `nice` in `ticks.dart`, d3's own copy in
  /// `d3-array`: the loop is capped at ten iterations (`linear.js:29`), and
  /// only the two **endpoints** are written (`linear.js:39-40`), so a
  /// polylinear domain keeps its interior stops. There is also no `isFinite`
  /// guard, so a zero-width domain runs the endpoints through NaN and leaves by
  /// the `break` at `:49` with the domain never reassigned.
  ///
  /// [count] is the tick count the rounding is sized for; 10 upstream
  /// (`linear.js:20`).
  ScaleLinear nice([int count = 10]) {
    final d = List<double>.of(rawDomain);
    // 0 and length - 1 are the two endpoint indices of `linear.js:23-24`.
    var i0 = 0;
    var i1 = d.length - 1;
    var start = d[i0];
    var stop = d[i1];
    double? prestep;
    // 10 is the iteration cap of `linear.js:29`.
    var maxIter = 10;

    if (stop < start) {
      // linear.js:31-34 swaps both the values and the indices, so a descending
      // domain is niced ascending and written back to the ends it came from.
      final swapValue = start;
      start = stop;
      stop = swapValue;
      final swapIndex = i0;
      i0 = i1;
      i1 = swapIndex;
    }

    // 0 is the exhausted-iteration floor (`linear.js:36`).
    while (maxIter-- > 0) {
      final step = numeric.tickIncrement(start, stop, count.toDouble());
      if (step == prestep) {
        d[i0] = start;
        d[i1] = stop;
        domainOf(d);
        return this;
      } else if (step > 0) {
        start = (start / step).floorToDouble() * step;
        stop = (stop / step).ceilToDouble() * step;
      } else if (step < 0) {
        // A negative increment is a reciprocal, so this multiplies where the
        // branch above divides (`linear.js:46-47`). That is what keeps a
        // fractional endpoint exact.
        start = (start * step).ceilToDouble() / step;
        stop = (stop * step).floorToDouble() / step;
      } else {
        break;
      }
      prestep = step;
    }
    // linear.js:54 — a zero or NaN step abandons the whole attempt and the
    // domain stays as it was.
    return this;
  }
}

/// A new [ScaleLinear] (`d3-scale/src/linear.js:60`).
ScaleLinear scaleLinear() => ScaleLinear();
