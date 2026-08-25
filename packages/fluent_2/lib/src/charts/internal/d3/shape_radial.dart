import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'curves.dart';
import 'path_sink.dart';
import 'shape_line_area.dart';

/// Cartesian coordinates for a polar point
/// (`d3-shape/src/pointRadial.js:2`).
///
/// This is `(r cos(a - π/2), r sin(a - π/2))`, whereas the radial *curve*
/// wrapper is `(r sin a, r −cos a)` (`d3-shape/src/curve/radial.js:23`). The
/// two look different, agree where the charts use them, and must not be
/// "simplified" into each other.
Offset pointRadial(double angle, double radius) {
  // The π/2 is d3's own quarter-turn so that zero radians points at twelve
  // o'clock rather than three (`pointRadial.js:2`).
  final a = angle - math.pi / 2;
  return Offset(radius * math.cos(a), radius * math.sin(a));
}

/// A radial line generator (`d3-shape/src/lineRadial.js:4-18`).
///
/// `PolarChart.tsx:467-471` is the consumer, with `.defined(isPlottable)` at
/// `:473`.
class LineRadial<T> {
  /// Creates a radial line generator.
  LineRadial({
    required this.angle,
    required this.radius,
    this.defined = _defaultDefined,
    this.curve = curveLinear,
  });

  /// The angle accessor, in radians.
  Accessor<T> angle;

  /// The radius accessor.
  Accessor<T> radius;

  /// The gap predicate.
  Defined<T> defined;

  /// The inner curve; it is wrapped in [curveRadial] before use.
  D3CurveFactory curve;

  /// Emits [data] into [sink].
  void call(List<T> data, PathSink sink) => Line<T>(
    x: angle,
    y: radius,
    defined: defined,
    curve: curveRadial(curve),
  )(data, sink);
}

/// A radial area generator (`d3-shape/src/areaRadial.js:5-29`).
///
/// `PolarChart.tsx:443-448` is the consumer, with `.defined(isPlottable)` at
/// `:450` — and the reverse-baseline replay inside [Area] honours it, which is
/// the hardest branch in the whole shape port.
class AreaRadial<T> {
  /// Creates a radial area generator. The default curve is
  /// [curveLinearClosed], matching `PolarChart.tsx:448`.
  AreaRadial({
    required this.angle,
    required this.innerRadius,
    required this.outerRadius,
    this.defined = _defaultDefined,
    this.curve = curveLinearClosed,
  });

  /// The angle accessor, in radians.
  Accessor<T> angle;

  /// The inner-radius accessor.
  Accessor<T> innerRadius;

  /// The outer-radius accessor.
  Accessor<T> outerRadius;

  /// The gap predicate, honoured on the reverse replay.
  Defined<T> defined;

  /// The inner curve; it is wrapped in [curveRadial] before use.
  D3CurveFactory curve;

  /// Emits [data] into [sink].
  ///
  /// `areaRadial.js:6-7` binds one angle accessor to both `startAngle` and
  /// `endAngle`, which is what leaving [Area.x1] `null` does: the baseline
  /// replay reuses the buffered angle.
  void call(List<T> data, PathSink sink) => Area<T>(
    x0: angle,
    y0: innerRadius,
    y1: outerRadius,
    defined: defined,
    curve: curveRadial(curve),
  )(data, sink);
}

/// d3's default `defined` (`d3-shape/src/line.js:11`), spelled over `Object?`
/// rather than a type variable: a default parameter value must be a constant,
/// and a generic tear-off instantiated at `T` is not one. The contravariance of
/// function parameters makes it a `Defined<T>` for every `T`, exactly as
/// `shape_line_area.dart:17` does for [Line] and [Area].
bool _defaultDefined(Object? d, int i, List<Object?> data) => true;
