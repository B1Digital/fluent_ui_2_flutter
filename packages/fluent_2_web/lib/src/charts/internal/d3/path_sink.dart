import 'dart:math' as math;
import 'dart:ui' show Offset, Path, Radius, Rect;

import 'js_math.dart';

/// The collinearity and coincidence tolerance d3-path uses
/// (`d3-path/src/path.js:3`).
const double pathEpsilon = 1e-6;

/// One full turn less [pathEpsilon] (`d3-path/src/path.js:4`).
///
/// A sweep wider than this is a complete circle and is drawn as two half arcs.
const double tauEpsilon = tau - pathEpsilon;

/// Where the d3 shape generators emit their geometry.
///
/// The method names are `d3-path`'s, so a reader can follow
/// `d3-shape/src/curve/*.js` line for line. Two implementations exist:
/// [UiPathSink] in production, and a string-emitting recorder in
/// `test/charts/d3/golden_support.dart` that the golden vectors compare
/// against.
abstract interface class PathSink {
  /// Starts a new sub-path at ([x], [y]).
  void moveTo(double x, double y);

  /// Draws a straight segment to ([x], [y]).
  void lineTo(double x, double y);

  /// Draws a quadratic Bézier through the control point ([cx], [cy]).
  void quadraticCurveTo(double cx, double cy, double x, double y);

  /// Draws a cubic Bézier through two control points.
  void bezierCurveTo(
    double c1x,
    double c1y,
    double c2x,
    double c2y,
    double x,
    double y,
  );

  /// Draws the arc tangent to the two lines through the current point,
  /// ([x1], [y1]) and ([x2], [y2]).
  void arcTo(double x1, double y1, double x2, double y2, double r);

  /// Draws an arc of radius [r] about ([cx], [cy]) from [a0] to [a1],
  /// anticlockwise when [ccw] is set.
  void arc(
    double cx,
    double cy,
    double r,
    double a0,
    double a1, {
    bool ccw = false,
  });

  /// Closes the current sub-path.
  void closePath();
}

/// A [PathSink] backed by a `dart:ui` `Path`.
///
/// Unlike `d3-shape`, which wraps `new Path(3)` and rounds every coordinate to
/// three decimals for SVG serialisation (`d3-path/src/path.js:13-24`), this
/// rounds nothing: the rounding is a ≤0.0005 px artefact of writing numbers
/// into a `d` attribute and has no meaning on a canvas.
final class UiPathSink implements PathSink {
  /// Wraps [path], or starts a new one.
  UiPathSink([Path? path]) : path = path ?? Path();

  /// The accumulated path.
  final Path path;

  /// The start of the current sub-path, which [closePath] returns to
  /// (`d3-path/src/path.js:28`).
  double? _x0;
  double? _y0;

  /// The end of the current sub-path, or null while the path is empty
  /// (`d3-path/src/path.js:29`). d3 branches on it in both [arcTo] and [arc].
  double? _x1;
  double? _y1;

  @override
  void moveTo(double x, double y) {
    // `d3-path/src/path.js:33-35`.
    _x0 = _x1 = x;
    _y0 = _y1 = y;
    path.moveTo(x, y);
  }

  @override
  void lineTo(double x, double y) {
    // `d3-path/src/path.js:42-44`.
    _x1 = x;
    _y1 = y;
    path.lineTo(x, y);
  }

  @override
  void quadraticCurveTo(double cx, double cy, double x, double y) {
    // `d3-path/src/path.js:45-47`.
    _x1 = x;
    _y1 = y;
    path.quadraticBezierTo(cx, cy, x, y);
  }

  @override
  void bezierCurveTo(
    double c1x,
    double c1y,
    double c2x,
    double c2y,
    double x,
    double y,
  ) {
    // `d3-path/src/path.js:48-50`.
    _x1 = x;
    _y1 = y;
    path.cubicTo(c1x, c1y, c2x, c2y, x, y);
  }

  @override
  void arcTo(double x1, double y1, double x2, double y2, double r) {
    // `d3-path/src/path.js:51-99`. `dart:ui` has `Path.arcToPoint`, but it
    // takes an end point on the circle rather than two tangent lines, so the
    // tangent solve is transcribed rather than delegated.
    if (r < 0) {
      throw ArgumentError.value(r, 'r', 'negative radius');
    }
    final x0 = _x1;
    final y0 = _y1;
    if (x0 == null || y0 == null) {
      moveTo(x1, y1);
      return;
    }
    final x21 = x2 - x1;
    final y21 = y2 - y1;
    final x01 = x0 - x1;
    final y01 = y0 - y1;
    final l01Sq = x01 * x01 + y01 * y01;
    // Written as a negated `>` so that a NaN length falls through to doing
    // nothing, exactly as `!(l01_2 > epsilon)` does (`path.js:71`).
    if (!(l01Sq > pathEpsilon)) {
      return;
    }
    if (!((y01 * x21 - y21 * x01).abs() > pathEpsilon) || r == 0) {
      lineTo(x1, y1);
      return;
    }
    final x20 = x2 - x0;
    final y20 = y2 - y0;
    final l21Sq = x21 * x21 + y21 * y21;
    final l20Sq = x20 * x20 + y20 * y20;
    final l21 = math.sqrt(l21Sq);
    final l01 = math.sqrt(l01Sq);
    // The tangent length: half the angle between the two lines, from the law
    // of cosines (`path.js:88`). The 2 is the law of cosines' own factor.
    final l =
        r *
        math.tan(
          (math.pi - math.acos((l21Sq + l01Sq - l20Sq) / (2 * l21 * l01))) / 2,
        );
    final t01 = l / l01;
    final t21 = l / l21;
    // The 1 is the far end of the incoming segment: when the tangent point
    // lands there, the join needs no lead-in line (`path.js:93`).
    if ((t01 - 1).abs() > pathEpsilon) {
      path.lineTo(x1 + t01 * x01, y1 + t01 * y01);
    }
    final endX = x1 + t21 * x21;
    final endY = y1 + t21 * y21;
    path.arcToPoint(
      Offset(endX, endY),
      radius: Radius.circular(r),
      // d3 writes this cross product straight into the sweep flag
      // (`path.js:97`).
      clockwise: y01 * x20 > x01 * y20,
    );
    _x1 = endX;
    _y1 = endY;
  }

  @override
  void arc(
    double cx,
    double cy,
    double r,
    double a0,
    double a1, {
    bool ccw = false,
  }) {
    // `d3-path/src/path.js:100-138`.
    if (r < 0) {
      throw ArgumentError.value(r, 'r', 'negative radius');
    }
    final dx = r * math.cos(a0);
    final dy = r * math.sin(a0);
    final x0 = cx + dx;
    final y0 = cy + dy;
    if (_x1 == null) {
      moveTo(x0, y0);
    } else if ((_x1! - x0).abs() > pathEpsilon ||
        (_y1! - y0).abs() > pathEpsilon) {
      lineTo(x0, y0);
    }
    if (r == 0) {
      return;
    }
    var da = ccw ? a0 - a1 : a1 - a0;
    if (da < 0) {
      // `path.js:127` is `da % tau + tau`, and JavaScript's `%` truncates
      // towards zero, so it keeps the sign of `da`. Dart's `%` is always
      // non-negative, which would push the result a whole turn past
      // [tauEpsilon] and turn every backwards sweep into a full circle;
      // `remainder` is the truncating one.
      da = da.remainder(tau) + tau;
    }
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    final sweep = ccw ? -da : da;
    if (da > tauEpsilon) {
      // A single arcTo cannot sweep a whole turn, which is exactly why
      // `d3-path/src/path.js:131` emits two. The 2 is that halving.
      final half = sweep / 2;
      path
        ..arcTo(rect, a0, half, false)
        ..arcTo(rect, a0 + half, half, false);
      _x1 = x0;
      _y1 = y0;
    } else if (da > pathEpsilon) {
      path.arcTo(rect, a0, sweep, false);
      _x1 = cx + r * math.cos(a1);
      _y1 = cy + r * math.sin(a1);
    }
  }

  @override
  void closePath() {
    // `d3-path/src/path.js:36-41`: closing an empty path emits nothing.
    if (_x1 != null) {
      _x1 = _x0;
      _y1 = _y0;
      path.close();
    }
  }
}
