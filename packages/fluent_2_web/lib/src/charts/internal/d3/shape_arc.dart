import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'js_math.dart';
import 'path_sink.dart';

/// d3-shape's tolerance (`d3-shape/src/math.js:9`).
///
/// It is **1e-12**, six orders finer than d3-path's [pathEpsilon]. Mixing the
/// two changes which branch an arc takes.
const double arcEpsilon = 1e-12;

/// `d3-shape/src/math.js:14-16` — `acos` clamped to its domain.
double _acos(double x) => x > 1
    ? 0
    : x < -1
    ? math.pi
    : math.acos(x);

/// `d3-shape/src/math.js:18-20` — `asin` clamped to its domain.
double _asin(double x) => x >= 1
    ? halfPi
    : x <= -1
    ? -halfPi
    : math.asin(x);

/// One arc's geometry (the datum `d3Arc()` is invoked with).
class ArcDatum {
  /// Creates an arc datum.
  const ArcDatum({
    required this.startAngle,
    required this.endAngle,
    required this.innerRadius,
    required this.outerRadius,
    this.padAngle = 0,
  });

  /// The start angle in radians, clockwise from twelve o'clock.
  final double startAngle;

  /// The end angle in radians.
  final double endAngle;

  /// The angular gap between neighbouring arcs. `Pie.tsx:98` sets 0.02 and the
  /// spread at `Arc.tsx:18` carries it into the generator.
  final double padAngle;

  /// The inner radius.
  final double innerRadius;

  /// The outer radius.
  final double outerRadius;
}

/// The arc generator (`d3-shape/src/arc.js:77-268`).
class Arc {
  /// Creates a generator. [padRadius] defaults to `sqrt(r0² + r1²)`
  /// (`d3-shape/src/arc.js:125`).
  Arc({this.cornerRadius = 0, this.padRadius});

  /// The corner radius. `Arc.tsx:114,123,136` sets 3 when `roundCorners`.
  final double cornerRadius;

  /// The radius at which the padding is measured, or `null` for d3's default.
  final double? padRadius;

  /// `d3-shape/src/arc.js:25-32`.
  static List<double>? _intersect(
    double x0,
    double y0,
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) {
    final x10 = x1 - x0;
    final y10 = y1 - y0;
    final x32 = x3 - x2;
    final y32 = y3 - y2;
    var t = y32 * x10 - x32 * y10;
    if (t * t < arcEpsilon) {
      return null;
    }
    t = (x32 * (y0 - y2) - y32 * (x0 - x2)) / t;
    return <double>[x0 + t * x10, y0 + t * y10];
  }

  /// `d3-shape/src/arc.js:36-75`.
  static _Tangents _cornerTangents(
    double x0,
    double y0,
    double x1,
    double y1,
    double r1,
    double rc, {
    required bool cw,
  }) {
    final x01 = x0 - x1;
    final y01 = y0 - y1;
    final lo = (cw ? rc : -rc) / math.sqrt(x01 * x01 + y01 * y01);
    final ox = lo * y01;
    final oy = -lo * x01;
    final x11 = x0 + ox;
    final y11 = y0 + oy;
    final x10 = x1 + ox;
    final y10 = y1 + oy;
    // The midpoint of the offset chord: d3 picks whichever of the two circle
    // centres lies nearer to it (`arc.js:70`), so the 2 is that halving.
    final x00 = (x11 + x10) / 2;
    final y00 = (y11 + y10) / 2;
    final dx = x10 - x11;
    final dy = y10 - y11;
    final d2 = dx * dx + dy * dy;
    final r = r1 - rc;
    final bigD = x11 * y10 - x10 * y11;
    // `arc.js:57` — the sign of `dy` chooses the branch of the square root,
    // and `max(0, …)` guards a discriminant driven negative by rounding. The
    // literals 0, -1 and 1 are that sign selection, not measurements.
    final d =
        (dy < 0 ? -1 : 1) * math.sqrt(math.max(0, r * r * d2 - bigD * bigD));
    var cx0 = (bigD * dy - dx * d) / d2;
    var cy0 = (-bigD * dx - dy * d) / d2;
    final cx1 = (bigD * dy + dx * d) / d2;
    final cy1 = (-bigD * dx + dy * d) / d2;
    final dx0 = cx0 - x00;
    final dy0 = cy0 - y00;
    final dx1 = cx1 - x00;
    final dy1 = cy1 - y00;
    if (dx0 * dx0 + dy0 * dy0 > dx1 * dx1 + dy1 * dy1) {
      cx0 = cx1;
      cy0 = cy1;
    }
    return _Tangents(
      cx: cx0,
      cy: cy0,
      x01: -ox,
      y01: -oy,
      // `arc.js:73-74` — the vector from the corner centre out to the ring,
      // scaled by `r1 / r - 1`; the 1 is the centre's own radius.
      x11: cx0 * (r1 / r - 1),
      y11: cy0 * (r1 / r - 1),
    );
  }

  /// Emits [d] into [sink] (`d3-shape/src/arc.js:88-227`).
  void call(ArcDatum d, PathSink sink) {
    var r0 = d.innerRadius;
    var r1 = d.outerRadius;
    // `arc.js:93-94` — the quarter-turn origin shift that puts angle 0 at
    // twelve o'clock rather than three o'clock.
    final a0 = d.startAngle - halfPi;
    final a1 = d.endAngle - halfPi;
    final da = (a1 - a0).abs();
    final cw = a1 > a0;

    // `arc.js:101` — ensure the outer radius is always the larger.
    if (r1 < r0) {
      final swap = r1;
      r1 = r0;
      r0 = swap;
    }

    if (!(r1 > arcEpsilon)) {
      // `arc.js:104` — a point.
      sink.moveTo(0, 0);
    } else if (da > tau - arcEpsilon) {
      // `arc.js:107-113` — a circle or annulus. Each full turn reaches
      // `PathSink.arc` above [tauEpsilon] and comes out as two `A` commands.
      sink
        ..moveTo(r1 * math.cos(a0), r1 * math.sin(a0))
        ..arc(0, 0, r1, a0, a1, ccw: !cw);
      if (r0 > arcEpsilon) {
        sink
          ..moveTo(r0 * math.cos(a1), r0 * math.sin(a1))
          ..arc(0, 0, r0, a1, a0, ccw: cw);
      }
    } else {
      // `arc.js:117-226` — a circular or annular sector.
      var a01 = a0;
      var a11 = a1;
      var a00 = a0;
      var a10 = a1;
      var da0 = da;
      var da1 = da;
      // `arc.js:124` — the padding is split evenly between the two ends, so
      // the 2 is that halving.
      final ap = d.padAngle / 2;
      final rp = ap > arcEpsilon
          ? (padRadius ?? math.sqrt(r0 * r0 + r1 * r1))
          : 0.0;
      // `arc.js:126` — a corner can never be wider than half the ring.
      final rc = math.min((r1 - r0).abs() / 2, cornerRadius);
      var rc0 = rc;
      var rc1 = rc;

      if (rp > arcEpsilon) {
        // `arc.js:133-140`. Note that since r1 ≥ r0, da1 ≥ da0. Each end gives
        // up `p` radians, hence the `* 2`.
        var p0 = _asin(rp / r0 * math.sin(ap));
        var p1 = _asin(rp / r1 * math.sin(ap));
        da0 -= p0 * 2;
        if (da0 > arcEpsilon) {
          p0 *= cw ? 1 : -1;
          a00 += p0;
          a10 -= p0;
        } else {
          da0 = 0;
          a00 = a10 = (a0 + a1) / 2;
        }
        da1 -= p1 * 2;
        if (da1 > arcEpsilon) {
          p1 *= cw ? 1 : -1;
          a01 += p1;
          a11 -= p1;
        } else {
          da1 = 0;
          a01 = a11 = (a0 + a1) / 2;
        }
      }

      final x01 = r1 * math.cos(a01);
      final y01 = r1 * math.sin(a01);
      final x10 = r0 * math.cos(a10);
      final y10 = r0 * math.sin(a10);
      // `arc.js:150-153` declares these inside the corner branch; `var` hoists
      // them to function scope in JavaScript, so lifting them here is the same
      // computation and they are only ever read once `rc > arcEpsilon`.
      final x11 = r1 * math.cos(a11);
      final y11 = r1 * math.sin(a11);
      final x00 = r0 * math.cos(a00);
      final y00 = r0 * math.sin(a00);

      // `arc.js:158-171` — clamp the corner radius to the sector angle. A
      // sector of half a turn or more has no crossing to clamp against.
      if (rc > arcEpsilon && da < math.pi) {
        final oc = _intersect(x01, y01, x00, y00, x11, y11, x10, y10);
        if (oc != null) {
          final ax = x01 - oc[0];
          final ay = y01 - oc[1];
          final bx = x11 - oc[0];
          final by = y11 - oc[1];
          // `arc.js:166` — the cosecant of the half-angle between the two
          // radial edges, so the 2 halves that angle.
          final kc =
              1 /
              math.sin(
                _acos(
                      (ax * bx + ay * by) /
                          (math.sqrt(ax * ax + ay * ay) *
                              math.sqrt(bx * bx + by * by)),
                    ) /
                    2,
              );
          final lc = math.sqrt(oc[0] * oc[0] + oc[1] * oc[1]);
          // `arc.js:168-169` — the ∓1 is the corner circle's own radius, which
          // sits inside the outer ring and outside the inner one.
          rc0 = math.min(rc, (r0 - lc) / (kc - 1));
          rc1 = math.min(rc, (r1 - lc) / (kc + 1));
        } else {
          rc0 = rc1 = 0;
        }
      }

      if (!(da1 > arcEpsilon)) {
        // `arc.js:175` — the sector has collapsed to a line.
        sink.moveTo(x01, y01);
      } else if (rc1 > arcEpsilon) {
        // `arc.js:178-192` — the outer ring has rounded corners.
        final t0 = _cornerTangents(x00, y00, x01, y01, r1, rc1, cw: cw);
        final t1 = _cornerTangents(x11, y11, x10, y10, r1, rc1, cw: cw);
        sink.moveTo(t0.cx + t0.x01, t0.cy + t0.y01);
        if (rc1 < rc) {
          // `arc.js:185` — the two corners have merged, so one arc joins them.
          sink.arc(
            t0.cx,
            t0.cy,
            rc1,
            math.atan2(t0.y01, t0.x01),
            math.atan2(t1.y01, t1.x01),
            ccw: !cw,
          );
        } else {
          // `arc.js:189-191` — the two corners and the ring between them.
          sink
            ..arc(
              t0.cx,
              t0.cy,
              rc1,
              math.atan2(t0.y01, t0.x01),
              math.atan2(t0.y11, t0.x11),
              ccw: !cw,
            )
            ..arc(
              0,
              0,
              r1,
              math.atan2(t0.cy + t0.y11, t0.cx + t0.x11),
              math.atan2(t1.cy + t1.y11, t1.cx + t1.x11),
              ccw: !cw,
            )
            ..arc(
              t1.cx,
              t1.cy,
              rc1,
              math.atan2(t1.y11, t1.x11),
              math.atan2(t1.y01, t1.x01),
              ccw: !cw,
            );
        }
      } else {
        // `arc.js:196` — the outer ring is a plain circular arc.
        sink
          ..moveTo(x01, y01)
          ..arc(0, 0, r1, a01, a11, ccw: !cw);
      }

      if (!(r0 > arcEpsilon) || !(da0 > arcEpsilon)) {
        // `arc.js:200` — no inner ring, or one collapsed by padding.
        sink.lineTo(x10, y10);
      } else if (rc0 > arcEpsilon) {
        // `arc.js:203-217` — the inner ring has rounded corners. The corner
        // radius is negated because the corners bulge outwards from the hole.
        final t0 = _cornerTangents(x10, y10, x11, y11, r0, -rc0, cw: cw);
        final t1 = _cornerTangents(x01, y01, x00, y00, r0, -rc0, cw: cw);
        sink.lineTo(t0.cx + t0.x01, t0.cy + t0.y01);
        if (rc0 < rc) {
          // `arc.js:210` — merged corners.
          sink.arc(
            t0.cx,
            t0.cy,
            rc0,
            math.atan2(t0.y01, t0.x01),
            math.atan2(t1.y01, t1.x01),
            ccw: !cw,
          );
        } else {
          // `arc.js:214-216`. The middle arc runs back along the inner ring,
          // so its winding is `cw`, not `!cw`.
          sink
            ..arc(
              t0.cx,
              t0.cy,
              rc0,
              math.atan2(t0.y01, t0.x01),
              math.atan2(t0.y11, t0.x11),
              ccw: !cw,
            )
            ..arc(
              0,
              0,
              r0,
              math.atan2(t0.cy + t0.y11, t0.cx + t0.x11),
              math.atan2(t1.cy + t1.y11, t1.cx + t1.x11),
              ccw: cw,
            )
            ..arc(
              t1.cx,
              t1.cy,
              rc0,
              math.atan2(t1.y11, t1.x11),
              math.atan2(t1.y01, t1.x01),
              ccw: !cw,
            );
        }
      } else {
        // `arc.js:221` — the inner ring is a plain circular arc, run
        // backwards.
        sink.arc(0, 0, r0, a10, a00, ccw: cw);
      }
    }
    sink.closePath();
  }

  /// The label anchor (`d3-shape/src/arc.js:229-233`).
  ///
  /// The mid-radius at the mid-angle: both 2s are those midpoints, and the
  /// `pi / 2` is the same origin shift [call] applies.
  Offset centroid(ArcDatum d) {
    final r = (d.innerRadius + d.outerRadius) / 2;
    final a = (d.startAngle + d.endAngle) / 2 - math.pi / 2;
    return Offset(math.cos(a) * r, math.sin(a) * r);
  }
}

/// The corner circle `_cornerTangents` solves for (`d3-shape/src/arc.js:68-75`).
class _Tangents {
  const _Tangents({
    required this.cx,
    required this.cy,
    required this.x01,
    required this.y01,
    required this.x11,
    required this.y11,
  });

  /// The corner circle's centre.
  final double cx;
  final double cy;

  /// The offset from the centre to where the corner meets the radial edge.
  final double x01;
  final double y01;

  /// The offset from the centre to where the corner meets the ring.
  final double x11;
  final double y11;
}
