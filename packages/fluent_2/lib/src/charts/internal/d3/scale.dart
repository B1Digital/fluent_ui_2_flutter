/// The single interface a chart holds a d3 scale through.
///
/// d3's scales are functions with properties; Dart has `call`, so a scale is a
/// callable object. Declaring the interface here rather than in `axis/` is what
/// lets `FluentAxisSpec` carry a scale while `internal/d3/` keeps its
/// zero-`package:flutter` constraint.
abstract interface class Scale {
  /// Maps a domain value to a pixel.
  ///
  /// Returns `null` for a band-scale domain miss (`d3-scale/src/ordinal.js`'s
  /// `unknown`, which the charts leave undefined) and for a continuous scale
  /// handed something non-numeric (`d3-scale/src/continuous.js:86`). Returns
  /// NaN — not null — for `scaleLog()(-1)`, because the input itself is a
  /// number and only the transform produces NaN.
  double? call(Object value);

  /// The current domain.
  List<Object> get domain;

  /// The current range, in pixels.
  List<double> get range;

  /// The width of one band, or `0` for a continuous scale
  /// (`d3-axis/src/axis.js:50` branches on the presence of this).
  double get bandwidth;

  /// The distance between consecutive band starts. For a continuous scale this
  /// is the range span.
  double get step;

  /// The domain value at [pixel], or `null` when the scale has no inverse.
  Object? invert(double pixel);

  /// Roughly [count] representative domain values.
  List<Object> ticks([int? count]);

  /// A formatter for the values [ticks] returns.
  ///
  /// [count] is the tick count the formatter should choose its precision for
  /// and [specifier] an optional d3-format specifier overriding that choice.
  String Function(Object value) tickFormat([int? count, String? specifier]);
}
