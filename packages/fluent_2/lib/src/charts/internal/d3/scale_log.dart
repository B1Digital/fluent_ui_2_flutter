import 'dart:math' as math;

import 'format.dart' as fmt;
import 'format_spec.dart';
import 'js_math.dart';
import 'scale_continuous.dart';
import 'ticks.dart' as numeric;

/// A base-10 logarithmic scale (`d3-scale/src/log.js:44-133`).
///
/// The base is fixed at 10: no upstream file calls `.base()` — `utilities.ts`
/// builds the scale at `:2210` and the two Polar call sites take the default —
/// so the `base % 1` guards of `log.js:80` and `:112`, which only matter for a
/// fractional base, are folded away as always true.
class ScaleLog extends ScaleContinuous {
  /// Creates a log scale on the default `[1, 10]` domain
  /// (`d3-scale/src/log.js:136`).
  ScaleLog() {
    domainOf(<double>[1, 10]);
  }

  /// The base, a constant 10 (`d3-scale/src/log.js:47`).
  static const double base = 10;

  /// Whether the domain lies below zero, in which case `log.js:53-55` wraps
  /// both `logs` and `pows` in `reflect`.
  bool get _reflected => rawDomain.first < 0;

  /// `logs` of `log.js:51`, reflected per `log.js:40-42`: `reflect(f)` is
  /// `(x) => -f(-x)`, so the argument is negated as well as the result.
  double _logs(double x) => _reflected ? -log10(-x) : log10(x);

  /// `pows` of `log.js:51`, reflected the same way as [_logs].
  double _pows(double x) => _reflected ? -_pow10(-x) : _pow10(x);

  /// `pow10` of `log.js:23-25`, `isFinite(x) ? +("1e" + x) : x < 0 ? 0 : x`.
  ///
  /// [pow10] is the decimal-string form and takes an `int`, which is all the
  /// upstream call sites ever produce: `ticks` and `nice` floor or ceil their
  /// argument and `tickFormat` rounds it. A fractional argument would make
  /// JavaScript's `+("1e2.5")` NaN; `math.pow` is used instead so that a
  /// caller reaching that path gets the mathematical answer rather than a
  /// silent NaN, and it never runs on the decade boundaries the corpus pins.
  static double _pow10(double x) {
    if (!x.isFinite) {
      return x < 0 ? 0 : x;
    }
    return x == x.roundToDouble()
        ? pow10(x.toInt())
        : math.pow(10.0, x) as double;
  }

  @override
  double transform(double x) => _reflected ? -math.log(-x) : math.log(x);

  @override
  double untransform(double x) => _reflected ? -math.exp(-x) : math.exp(x);

  @override
  List<Object> ticks([int? count]) {
    // log.js:70-107.
    final d = rawDomain;
    var u = d.first;
    var v = d.last;
    final reverse = v < u;
    if (reverse) {
      final swap = u;
      u = v;
      v = swap;
    }
    var i = _logs(u);
    var j = _logs(v);
    // 10 is d3's default tick count (`log.js:78`).
    final n = (count ?? 10).toDouble();
    var z = <double>[];
    if (j - i < n) {
      i = i.floorToDouble();
      j = j.ceilToDouble();
      if (u > 0) {
        for (; i <= j; i++) {
          // The mantissa runs 1..9 for a positive domain (`log.js:83`).
          for (var k = 1.0; k < base; k++) {
            final t = i < 0 ? k / _pows(-i) : k * _pows(i);
            if (t < u) {
              continue;
            }
            if (t > v) {
              break;
            }
            z.add(t);
          }
        }
      } else {
        for (; i <= j; i++) {
          // Reflected, the mantissa runs 9..1 so the output stays ascending
          // (`log.js:90`).
          for (var k = base - 1; k >= 1; k--) {
            final t = i > 0 ? k / _pows(-i) : k * _pows(i);
            if (t < u) {
              continue;
            }
            if (t > v) {
              break;
            }
            z.add(t);
          }
        }
      }
      // 2 is `log.js:99`: fewer than half the requested ticks means the domain
      // spans less than a decade, so the linear generator does better.
      if (z.length * 2 < n) {
        z = numeric.ticks(u, v, n);
      }
    } else {
      z = numeric.ticks(i, j, math.min(j - i, n)).map(_pows).toList();
    }
    return (reverse ? z.reversed.toList() : z).cast<Object>();
  }

  @override
  String Function(Object value) tickFormat([int? count, String? specifier]) {
    // log.js:109-123. `count == Infinity`, which `log.js:118` returns the bare
    // formatter for, cannot be expressed by an `int` count and so is dropped;
    // pass the specifier and read the labels through this formatter instead.
    // 10 is the default count of `log.js:110`.
    final n = count ?? 10;
    // "s" is the base-10 default of `log.js:111`.
    final spec = formatSpecifier(specifier ?? 's');
    if (spec.precision == null) {
      spec.trim = true;
    }
    final inner = fmt.formatFrom(spec);
    // log.js:120 — the divisor is the DEFAULT tick list, not the count passed
    // here. 1 is the floor: every scale labels at least the whole decades.
    final k = math.max(1.0, base * n / ticks().length);
    return (Object v) {
      final x = (v as num).toDouble();
      var i = x / _pows(jsRound(_logs(x)));
      // log.js:122 — 0.5 pulls a mantissa that rounded up into the decade
      // above back down into 1..9.
      if (i * base < base - 0.5) {
        i *= base;
      }
      // The blank is behaviour: utilities.ts:294 and :876 test for it.
      return i <= k ? inner(x) : '';
    };
  }

  /// Snaps the domain endpoints to whole decades
  /// (`d3-scale/src/log.js:125-130`, through `d3-scale/src/nice.js:1-17`).
  ScaleLog nice() {
    final d = List<double>.of(rawDomain);
    var i0 = 0;
    var i1 = d.length - 1;
    var x0 = d[i0];
    var x1 = d[i1];
    if (x1 < x0) {
      final swapIndex = i0;
      i0 = i1;
      i1 = swapIndex;
      final swapValue = x0;
      x0 = x1;
      x1 = swapValue;
    }
    d[i0] = _pows(_logs(x0).floorToDouble());
    d[i1] = _pows(_logs(x1).ceilToDouble());
    domainOf(d);
    return this;
  }
}

/// A new [ScaleLog] (`d3-scale/src/log.js:135`).
ScaleLog scaleLog() => ScaleLog();
