import 'dart:math' as math;

import 'array_stats.dart' as array;
import 'interpolate.dart';
import 'scale.dart';

/// A piecewise-linear mapping from a numeric domain to a numeric range
/// (`d3-scale/src/continuous.js:65-125`).
///
/// `clamp`, `rangeRound` and `unknown` are not ported: no upstream file sets
/// any of the three.
class ScaleContinuous implements Scale {
  /// Creates the unit scale, domain and range both `[0, 1]`
  /// (`d3-scale/src/continuous.js:6`).
  ScaleContinuous();

  List<double> _domain = <double>[0, 1];
  List<double> _range = <double>[0, 1];
  double Function(double)? _output;
  double Function(double)? _input;

  /// The forward transform (identity here; `math.log` in `ScaleLog`,
  /// milliseconds in `ScaleTime`).
  double transform(double x) => x;

  /// The inverse of [transform].
  double untransform(double x) => x;

  /// Replaces the domain and returns `this` for chaining.
  ScaleContinuous domainOf(List<double> values) {
    _domain = List<double>.of(values);
    _rescale();
    return this;
  }

  /// Replaces the range and returns `this`.
  ScaleContinuous rangeOf(List<double> values) {
    _range = List<double>.of(values);
    _rescale();
    return this;
  }

  /// The domain as raw doubles, for subclasses that must edit it in place.
  List<double> get rawDomain => _domain;

  void _rescale() {
    _output = null;
    _input = null;
  }

  /// `d3-scale/src/continuous.js:12-16`.
  ///
  /// A zero-width domain collapses to a **constant 0.5**, so a degenerate
  /// scale paints at the middle of its range rather than at either end. A NaN
  /// width stays NaN.
  static double Function(double) _normalize(double a, double b) {
    final span = b - a;
    if (span != 0 && !span.isNaN) {
      return (double x) => (x - a) / span;
    }
    // 0.5 is the midpoint constant of `continuous.js:15`.
    final constant = span.isNaN ? double.nan : 0.5;
    return (double _) => constant;
  }

  double Function(double) _piecewise(List<double> domain, List<double> range) {
    // 2 is the bimap/polymap threshold of `continuous.js:79`: more than two
    // stops on either side needs the bisecting form.
    if (math.min(domain.length, range.length) > 2) {
      // continuous.js:33-54.
      // 1 turns a stop count into a segment count.
      final j = math.min(domain.length, range.length) - 1;
      var d = domain;
      var r = range;
      if (d[j] < d[0]) {
        d = d.reversed.toList();
        r = r.reversed.toList();
      }
      final norms = <double Function(double)>[];
      final interps = <double Function(double)>[];
      for (var i = 0; i < j; i++) {
        norms.add(_normalize(d[i], d[i + 1]));
        interps.add(interpolateNumber(r[i], r[i + 1]));
      }
      final bisect = array.bisector<double>((double v) => v);
      final frozen = d;
      return (double x) {
        // 1 as the low bound keeps the first segment addressable, and the
        // trailing 1 converts the insertion point into a segment index
        // (`continuous.js:52`).
        final i = bisect.right(frozen, x, 1, j) - 1;
        return interps[i](norms[i](x));
      };
    }
    // continuous.js:26-31.
    final d0 = domain[0];
    final d1 = domain[1];
    final r0 = range[0];
    final r1 = range[1];
    if (d1 < d0) {
      final n = _normalize(d1, d0);
      final f = interpolateNumber(r1, r0);
      return (double x) => f(n(x));
    }
    final n = _normalize(d0, d1);
    final f = interpolateNumber(r0, r1);
    return (double x) => f(n(x));
  }

  @override
  double? call(Object value) {
    // continuous.js:86 — anything that does not coerce to a number is unknown.
    if (value is! num) {
      return null;
    }
    final x = value.toDouble();
    if (x.isNaN) {
      return null;
    }
    _output ??= _piecewise(
      _domain.map(transform).toList(growable: false),
      _range,
    );
    return _output!(transform(x));
  }

  @override
  Object? invert(double pixel) {
    _input ??= _piecewise(
      _range,
      _domain.map(transform).toList(growable: false),
    );
    return untransform(_input!(pixel));
  }

  @override
  List<Object> get domain => List<Object>.of(_domain);

  @override
  List<double> get range => List<double>.of(_range);

  @override
  double get bandwidth => 0;

  @override
  double get step => _range.last - _range.first;

  @override
  List<Object> ticks([int? count]) =>
      throw UnimplementedError('a bare ScaleContinuous has no tick generator');

  @override
  String Function(Object value) tickFormat([int? count, String? specifier]) =>
      throw UnimplementedError('a bare ScaleContinuous has no tick formatter');
}
