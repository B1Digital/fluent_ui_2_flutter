import 'color.dart';

/// Linear interpolation between [a] and [b]
/// (`d3-interpolate/src/number.js:2-5`).
///
/// The expression is `a * (1 - t) + b * t`, not `a + t * (b - a)`. They are
/// algebraically equal and numerically different, and `d3-scale`'s `invert`
/// runs through this on every pointer move.
double Function(double t) interpolateNumber(double a, double b) =>
    (double t) => a * (1 - t) + b * t;

/// `d3-interpolate/src/color.js:26-29` at gamma 1 — the only gamma d3-scale
/// ever uses (`d3-interpolate/src/rgb.js:26` instantiates `rgbGamma(1)`).
double Function(double t) _nogamma(double a, double b) {
  final d = b - a;
  // Upstream tests `d ?`, and JavaScript treats both 0 and NaN as falsy. A NaN
  // delta is reached whenever one endpoint is a fully transparent colour, whose
  // channels `d3-color/src/color.js:224-227` erases to NaN.
  if (d != 0 && !d.isNaN) {
    return (double t) => a + t * d;
  }
  final constant = a.isNaN ? b : a;
  return (double t) => constant;
}

/// Interpolates between two colours, emitting `rgb()` / `rgba()` strings
/// (`d3-interpolate/src/rgb.js:9-21`).
String Function(double t) interpolateRgb(Object a, Object b) {
  // 0, 0, 0 stands in for upstream's `new Rgb` on an unparseable specifier
  // (`d3-color/src/color.js:231`), which yields NaN channels there.
  final start = rgb(a) ?? const D3Rgb(0, 0, 0);
  final end = rgb(b) ?? const D3Rgb(0, 0, 0);
  final r = _nogamma(start.r, end.r);
  final g = _nogamma(start.g, end.g);
  final blue = _nogamma(start.b, end.b);
  final opacity = _nogamma(start.a, end.a);
  return (double t) => D3Rgb(r(t), g(t), blue(t), opacity(t)).formatRgb();
}

/// Dispatches on the type of [b] (`d3-interpolate/src/value.js:11-22`).
///
/// Only the number and colour branches are reachable: `d3-scale`'s
/// `transformer` (`d3-scale/src/continuous.js:68`) is the sole consumer and
/// every range it is given is numeric or a colour string.
Object Function(double t) interpolateValue(Object a, Object b) {
  if (b is num) {
    final f = interpolateNumber(
      // A non-numeric left endpoint gives NaN, exactly as JS coercion would.
      a is num ? a.toDouble() : double.nan,
      b.toDouble(),
    );
    // Returned as a tearoff: `(t) => f(t)` trips `unnecessary_lambdas`, and
    // `double Function(double)` already satisfies `Object Function(double)`.
    return f;
  }
  if (b is String && color(b) != null) {
    return interpolateRgb(a, b);
  }
  if (b is D3Color) {
    return interpolateRgb(a, b);
  }
  // value.js:21 falls through to `constant(b)` for anything else.
  return (double t) => b;
}
