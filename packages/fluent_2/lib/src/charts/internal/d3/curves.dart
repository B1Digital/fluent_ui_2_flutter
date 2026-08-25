import 'dart:math' as math;

import 'path_sink.dart';

/// A curve, in d3's sense: a stateful sink adaptor the line and area generators
/// feed points to.
///
/// Named `D3Curve` rather than `Curve` so it does not collide with
/// `package:flutter/animation.dart`'s `Curve` in every chart file. The factory
/// constants below keep d3's own names, because those are what a reader diffs.
abstract interface class D3Curve {
  /// Begins an area (`d3-shape/src/curve/linear.js:6-8`).
  void areaStart();

  /// Ends an area (`d3-shape/src/curve/linear.js:9-11`).
  void areaEnd();

  /// Begins one sub-path (`d3-shape/src/curve/linear.js:12-14`).
  void lineStart();

  /// Ends one sub-path (`d3-shape/src/curve/linear.js:15-18`).
  void lineEnd();

  /// Adds a point (`d3-shape/src/curve/linear.js:19-26`).
  void point(double x, double y);
}

/// Builds a [D3Curve] over [sink].
typedef D3CurveFactory = D3Curve Function(PathSink sink);

/// `d3-shape/src/curve/linear.js:1-27`.
class _Linear implements D3Curve {
  _Linear(this._sink);

  final PathSink _sink;

  /// `linear.js:7,10` — 0 while an area's top edge is drawn, 1 while its
  /// baseline is replayed, and NaN outside an area. Every comparison below is
  /// the Dart spelling of a JavaScript truth test on this three-valued field,
  /// and NaN is falsy there.
  double _line = double.nan;
  int _point = 0;

  @override
  void areaStart() => _line = 0;

  @override
  void areaEnd() => _line = double.nan;

  @override
  void lineStart() => _point = 0;

  @override
  void lineEnd() {
    // `linear.js:16`. The 1 is the baseline pass and the 0 is the top edge.
    if (_line == 1 || (_line != 0 && _point == 1)) {
      _sink.closePath();
    }
    _line = 1 - _line;
  }

  @override
  void point(double x, double y) {
    switch (_point) {
      case 0:
        // `linear.js:22`. 1 marks "one point seen".
        _point = 1;
        if (_line == 1) {
          _sink.lineTo(x, y);
        } else {
          _sink.moveTo(x, y);
        }
      case 1:
        // `linear.js:23` falls through to the default; 2 means "two or more".
        _point = 2;
        _sink.lineTo(x, y);
      default:
        _sink.lineTo(x, y);
    }
  }
}

/// Straight segments (`d3-shape/src/curve/linear.js:29-31`). The default for
/// `getCurveFactory` (`utilities.ts:57,2014,2022`).
const D3CurveFactory curveLinear = _linear;
D3Curve _linear(PathSink sink) => _Linear(sink);

/// `d3-shape/src/curve/linearClosed.js:1-21`.
class _LinearClosed implements D3Curve {
  _LinearClosed(this._sink);

  final PathSink _sink;
  int _point = 0;

  @override
  void areaStart() {
    // `linearClosed.js:8` is d3's `noop`.
  }

  @override
  void areaEnd() {
    // `linearClosed.js:9` is d3's `noop`.
  }

  @override
  void lineStart() => _point = 0;

  @override
  void lineEnd() {
    // `linearClosed.js:14`.
    if (_point != 0) {
      _sink.closePath();
    }
  }

  @override
  void point(double x, double y) {
    // `linearClosed.js:18-19`. The 1 is "at least one point seen".
    if (_point != 0) {
      _sink.lineTo(x, y);
    } else {
      _point = 1;
      _sink.moveTo(x, y);
    }
  }
}

/// Straight segments with an implicit closing edge
/// (`d3-shape/src/curve/linearClosed.js:23-25`). PolarChart's radial areas
/// default to it (`PolarChart.tsx:448`).
const D3CurveFactory curveLinearClosed = _linearClosed;
D3Curve _linearClosed(PathSink sink) => _LinearClosed(sink);

/// `d3-shape/src/curve/natural.js:1-61`.
class _Natural implements D3Curve {
  _Natural(this._sink);

  final PathSink _sink;

  /// See the note on `_Linear._line` (`natural.js:7,10`).
  double _line = double.nan;
  List<double> _x = <double>[];
  List<double> _y = <double>[];

  @override
  void areaStart() => _line = 0;

  @override
  void areaEnd() => _line = double.nan;

  @override
  void lineStart() {
    // `natural.js:13-14`.
    _x = <double>[];
    _y = <double>[];
  }

  @override
  void lineEnd() {
    // `natural.js:16-37`.
    final n = _x.length;
    if (n != 0) {
      if (_line == 1) {
        _sink.lineTo(_x[0], _y[0]);
      } else {
        _sink.moveTo(_x[0], _y[0]);
      }
      // `natural.js:23` — 2 points are a straight segment, not a spline.
      if (n == 2) {
        _sink.lineTo(_x[1], _y[1]);
      } else if (n > 2) {
        // `natural.js:26-30`. The `n > 2` guard is a deliberate deviation from
        // the JavaScript, which calls `controlPoints` unconditionally here: on
        // a single point that walks off both ends of a zero-length array, which
        // JavaScript tolerates (it invents an index `-1` property and yields
        // NaNs) and a Dart fixed-length list does not. The Bézier loop below
        // never runs when n == 1, so the values were never read; skipping the
        // solve is behaviour-identical and merely avoids a `RangeError`.
        final px = _controlPoints(_x);
        final py = _controlPoints(_y);
        for (var i0 = 0, i1 = 1; i1 < n; i0++, i1++) {
          _sink.bezierCurveTo(
            px.$1[i0],
            py.$1[i0],
            px.$2[i0],
            py.$2[i0],
            _x[i1],
            _y[i1],
          );
        }
      }
    }
    // `natural.js:34`. The 1 is the baseline pass; a lone point closes so that
    // it still paints as a degenerate sub-path.
    if (_line == 1 || (_line != 0 && n == 1)) {
      _sink.closePath();
    }
    _line = 1 - _line;
    _x = <double>[];
    _y = <double>[];
  }

  @override
  void point(double x, double y) {
    // `natural.js:39-40`.
    _x.add(x);
    _y.add(y);
  }

  /// The Thomas tridiagonal solve at `d3-shape/src/curve/natural.js:45-61`.
  ///
  /// Every literal here is a coefficient of the natural cubic spline's
  /// tridiagonal system, derived at
  /// <https://www.particleincell.com/2012/bezier-splines/> and cited by
  /// `natural.js:44`: the first row is `2 P1 = x0 + 2 x1`, the interior rows
  /// are `P(i-1) + 4 Pi + P(i+1) = 4 xi + 2 x(i+1)`, and the last is
  /// `2 P(n-1) + 7 Pn = 8 x(n-1) + xn`.
  static (List<double>, List<double>) _controlPoints(List<double> x) {
    final n = x.length - 1;
    final a = List<double>.filled(n, 0);
    final b = List<double>.filled(n, 0);
    final r = List<double>.filled(n, 0);
    a[0] = 0;
    b[0] = 2;
    r[0] = x[0] + 2 * x[1];
    for (var i = 1; i < n - 1; i++) {
      a[i] = 1;
      b[i] = 4;
      r[i] = 4 * x[i] + 2 * x[i + 1];
    }
    a[n - 1] = 2;
    b[n - 1] = 7;
    r[n - 1] = 8 * x[n - 1] + x[n];
    for (var i = 1; i < n; i++) {
      final m = a[i] / b[i - 1];
      b[i] -= m;
      r[i] -= m * r[i - 1];
    }
    a[n - 1] = r[n - 1] / b[n - 1];
    for (var i = n - 2; i >= 0; i--) {
      a[i] = (r[i] - a[i + 1]) / b[i];
    }
    // `natural.js:58-59`. The 2 is the reflection of the first control point
    // about the knot, which is what makes the join C1-continuous.
    b[n - 1] = (x[n] + a[n - 1]) / 2;
    for (var i = 0; i < n - 1; i++) {
      b[i] = 2 * x[i + 1] - a[i + 1];
    }
    return (a, b);
  }
}

/// A natural cubic spline (`d3-shape/src/curve/natural.js:63-65`), selected by
/// `curve: 'natural'` (`utilities.ts:58,2024`).
const D3CurveFactory curveNatural = _natural;
D3Curve _natural(PathSink sink) => _Natural(sink);

/// `d3-shape/src/curve/step.js:1-41`.
class _Step implements D3Curve {
  _Step(this._sink, this._t);

  final PathSink _sink;

  /// Where along the run the riser sits: 0 before the point, 1 after it, 0.5 at
  /// the midpoint (`step.js:3`). Not final, because [lineEnd] flips it.
  double _t;

  /// See the note on `_Linear._line` (`step.js:8,11`).
  double _line = double.nan;
  double _x = double.nan;
  double _y = double.nan;
  int _point = 0;

  @override
  void areaStart() => _line = 0;

  @override
  void areaEnd() => _line = double.nan;

  @override
  void lineStart() {
    // `step.js:14-15`.
    _x = _y = double.nan;
    _point = 0;
  }

  @override
  void lineEnd() {
    // `step.js:18` — only an interior riser leaves a trailing segment to draw;
    // at t = 0 or t = 1 the last point has already been emitted.
    if (0 < _t && _t < 1 && _point == 2) {
      _sink.lineTo(_x, _y);
    }
    if (_line == 1 || (_line != 0 && _point == 1)) {
      _sink.closePath();
    }
    // step.js:20 — flipping _t is what makes an area's baseline replay mirror
    // the top edge instead of duplicating it. The guard excludes the NaN case,
    // where there is no area and nothing to mirror.
    if (_line >= 0) {
      _t = 1 - _t;
      _line = 1 - _line;
    }
  }

  @override
  void point(double x, double y) {
    switch (_point) {
      case 0:
        // `step.js:25`.
        _point = 1;
        if (_line == 1) {
          _sink.lineTo(x, y);
        } else {
          _sink.moveTo(x, y);
        }
      case 1:
        // `step.js:26` falls through to the default.
        _point = 2;
        _emit(x, y);
      default:
        _emit(x, y);
    }
    _x = x;
    _y = y;
  }

  /// `step.js:27-37`.
  void _emit(double x, double y) {
    if (_t <= 0) {
      _sink
        ..lineTo(_x, y)
        ..lineTo(x, y);
    } else {
      // `step.js:32` — a linear interpolation of the two x values by _t.
      final x1 = _x * (1 - _t) + x * _t;
      _sink
        ..lineTo(x1, _y)
        ..lineTo(x1, y);
    }
  }
}

/// A step at the midpoint (`d3-shape/src/curve/step.js:43-45`). The 0.5 is
/// d3's own default `t`.
const D3CurveFactory curveStep = _step;
D3Curve _step(PathSink sink) => _Step(sink, 0.5);

/// A step before the point (`d3-shape/src/curve/step.js:47-49`, `t` = 0).
const D3CurveFactory curveStepBefore = _stepBefore;
D3Curve _stepBefore(PathSink sink) => _Step(sink, 0);

/// A step after the point (`d3-shape/src/curve/step.js:51-53`, `t` = 1).
const D3CurveFactory curveStepAfter = _stepAfter;
D3Curve _stepAfter(PathSink sink) => _Step(sink, 1);

/// `d3-shape/src/curve/monotone.js:1-77` — Steffen 1990.
class _MonotoneX implements D3Curve {
  _MonotoneX(this._sink);

  final PathSink _sink;

  /// See the note on `_Linear._line` (`monotone.js:42,45`).
  double _line = double.nan;
  double _x0 = double.nan;
  double _x1 = double.nan;
  double _y0 = double.nan;
  double _y1 = double.nan;
  double _t0 = double.nan;
  int _point = 0;

  /// `monotone.js:1-3`. Note that this maps both zeroes to +1, unlike
  /// `jsSign`, so it must not be replaced by it.
  static double _sign(double x) => x < 0 ? -1 : 1;

  /// `monotone.js:9-16`. The `h0 || (h1 < 0 && -0)` idiom deliberately divides
  /// by a signed zero to produce a signed infinity, so that a vertical run
  /// still yields a slope with the right sign.
  double _slope3(double x2, double y2) {
    final h0 = _x1 - _x0;
    final h1 = x2 - _x1;
    final d0 = h0 != 0 ? h0 : (h1 < 0 ? -0.0 : 0.0);
    final d1 = h1 != 0 ? h1 : (h0 < 0 ? -0.0 : 0.0);
    final s0 = (_y1 - _y0) / d0;
    final s1 = (y2 - _y1) / d1;
    final p = (s0 * h1 + s1 * h0) / (h0 + h1);
    // `monotone.js:15`. The 0.5 halves the parabolic slope, which is Steffen's
    // monotonicity limiter.
    final result =
        (_sign(s0) + _sign(s1)) *
        math.min(math.min(s0.abs(), s1.abs()), 0.5 * p.abs());
    // The trailing `|| 0` of `monotone.js:15` is falsy for NaN *and* for either
    // signed zero, so a -0 result normalises to +0 as well.
    return result.isNaN || result == 0 ? 0 : result;
  }

  /// `monotone.js:19-22`. The 3 and the 2 come from the one-sided end
  /// condition of the Hermite spline.
  double _slope2(double t) {
    final h = _x1 - _x0;
    return h != 0 ? (3 * (_y1 - _y0) / h - t) / 2 : t;
  }

  /// `monotone.js:27-34`. The 3 is the cubic Bézier's own factor: a Hermite
  /// segment with tangents `m0`, `m1` is `p0, p0 + m0 / 3, p1 - m1 / 3, p1`.
  void _emit(double t0, double t1) {
    final dx = (_x1 - _x0) / 3;
    _sink.bezierCurveTo(
      _x0 + dx,
      _y0 + dx * t0,
      _x1 - dx,
      _y1 - dx * t1,
      _x1,
      _y1,
    );
  }

  @override
  void areaStart() => _line = 0;

  @override
  void areaEnd() => _line = double.nan;

  @override
  void lineStart() {
    // `monotone.js:48-51`.
    _x0 = _x1 = _y0 = _y1 = _t0 = double.nan;
    _point = 0;
  }

  @override
  void lineEnd() {
    switch (_point) {
      // `monotone.js:55` — two points never earned a tangent, so they join
      // straight.
      case 2:
        _sink.lineTo(_x1, _y1);
      // `monotone.js:56` — the final segment takes the one-sided end slope.
      case 3:
        _emit(_t0, _slope2(_t0));
    }
    if (_line == 1 || (_line != 0 && _point == 1)) {
      _sink.closePath();
    }
    _line = 1 - _line;
  }

  @override
  void point(double x, double y) {
    var t1 = double.nan;
    // monotone.js:65 — coincident points are dropped outright.
    if (x == _x1 && y == _y1) {
      return;
    }
    switch (_point) {
      case 0:
        _point = 1;
        if (_line == 1) {
          _sink.lineTo(x, y);
        } else {
          _sink.moveTo(x, y);
        }
      // `monotone.js:68` — the second point only primes the window.
      case 1:
        _point = 2;
      // `monotone.js:69` — the third point is the first that has a neighbour
      // on each side, so the first segment can finally be drawn, its left
      // tangent being the one-sided start slope.
      case 2:
        _point = 3;
        t1 = _slope3(x, y);
        _emit(_slope2(t1), t1);
      default:
        t1 = _slope3(x, y);
        _emit(_t0, t1);
    }
    // `monotone.js:73-75`.
    _x0 = _x1;
    _x1 = x;
    _y0 = _y1;
    _y1 = y;
    _t0 = t1;
  }
}

/// A monotone cubic in x (`d3-shape/src/curve/monotone.js:98-100`).
///
/// `AreaChart.tsx:7` imports this **as `d3CurveBasis`** and uses it as the area
/// default at `:670`. It is not `curveBasis`, which is not ported.
const D3CurveFactory curveMonotoneX = _monotoneX;
D3Curve _monotoneX(PathSink sink) => _MonotoneX(sink);

/// `d3-shape/src/curve/bump.js:3-39`, x variant only.
class _BumpX implements D3Curve {
  _BumpX(this._sink);

  final PathSink _sink;

  /// See the note on `_Linear._line` (`bump.js:9,12`).
  double _line = double.nan;
  int _point = 0;
  double _x0 = double.nan;
  double _y0 = double.nan;

  @override
  void areaStart() => _line = 0;

  @override
  void areaEnd() => _line = double.nan;

  @override
  void lineStart() => _point = 0;

  @override
  void lineEnd() {
    // `bump.js:18`.
    if (_line == 1 || (_line != 0 && _point == 1)) {
      _sink.closePath();
    }
    _line = 1 - _line;
  }

  @override
  void point(double x, double y) {
    switch (_point) {
      case 0:
        // `bump.js:24-29`.
        _point = 1;
        if (_line == 1) {
          _sink.lineTo(x, y);
        } else {
          _sink.moveTo(x, y);
        }
      case 1:
        // `bump.js:30` falls through to the default.
        _point = 2;
        _bump(x, y);
      default:
        _bump(x, y);
    }
    _x0 = x;
    _y0 = y;
  }

  void _bump(double x, double y) {
    // bump.js:32 — note that _x0 is REASSIGNED inside the call, so both control
    // points share the midpoint. The 2 is that midpoint.
    _x0 = (_x0 + x) / 2;
    _sink.bezierCurveTo(_x0, _y0, _x0, y, x, y);
  }
}

/// A horizontal bump (`d3-shape/src/curve/bump.js:65-67`).
///
/// `SankeyChart.tsx:12` imports this **as `d3CurveBasis`** and draws every
/// ribbon with it at `:518`.
const D3CurveFactory curveBumpX = _bumpX;
D3Curve _bumpX(PathSink sink) => _BumpX(sink);

/// `d3-shape/src/curve/cardinal.js:1-48`.
class _Cardinal implements D3Curve {
  // `cardinal.js:14`. The 6 is the cardinal spline's own scale factor, so that
  // a tension of 0 gives the Catmull-Rom tangent of a sixth of the span.
  _Cardinal(this._sink, double tension) : _k = (1 - tension) / 6;

  final PathSink _sink;
  final double _k;

  /// See the note on `_Linear._line` (`cardinal.js:19,22`).
  double _line = double.nan;
  int _point = 0;
  double _x0 = double.nan;
  double _x1 = double.nan;
  double _x2 = double.nan;
  double _y0 = double.nan;
  double _y1 = double.nan;
  double _y2 = double.nan;

  /// `cardinal.js:1-10`.
  void _emit(double x, double y) {
    _sink.bezierCurveTo(
      _x1 + _k * (_x2 - _x0),
      _y1 + _k * (_y2 - _y0),
      _x2 + _k * (_x1 - x),
      _y2 + _k * (_y1 - y),
      _x2,
      _y2,
    );
  }

  @override
  void areaStart() => _line = 0;

  @override
  void areaEnd() => _line = double.nan;

  @override
  void lineStart() {
    // `cardinal.js:25-27`.
    _x0 = _x1 = _x2 = _y0 = _y1 = _y2 = double.nan;
    _point = 0;
  }

  @override
  void lineEnd() {
    switch (_point) {
      // `cardinal.js:31` — two points join straight.
      case 2:
        _sink.lineTo(_x2, _y2);
      // `cardinal.js:32` — the last segment reuses the previous knot as the
      // phantom point beyond the end.
      case 3:
        _emit(_x1, _y1);
    }
    if (_line == 1 || (_line != 0 && _point == 1)) {
      _sink.closePath();
    }
    _line = 1 - _line;
  }

  @override
  void point(double x, double y) {
    switch (_point) {
      case 0:
        // `cardinal.js:40`.
        _point = 1;
        if (_line == 1) {
          _sink.lineTo(x, y);
        } else {
          _sink.moveTo(x, y);
        }
      case 1:
        // `cardinal.js:41` — the second point seeds the phantom start knot.
        _point = 2;
        _x1 = x;
        _y1 = y;
      case 2:
        // `cardinal.js:42` falls through to the default.
        _point = 3;
        _emit(x, y);
      default:
        _emit(x, y);
    }
    // `cardinal.js:45-46`.
    _x0 = _x1;
    _x1 = _x2;
    _x2 = x;
    _y0 = _y1;
    _y1 = _y2;
    _y2 = y;
  }
}

/// A cardinal spline (`d3-shape/src/curve/cardinal.js:50-61`).
///
/// `PlotlySchemaAdapter.ts:83` is the only consumer and never sets a
/// [tension], so `_k` is 1/6 there — d3's own default (`cardinal.js:61`).
D3CurveFactory curveCardinal({double tension = 0}) =>
    (PathSink sink) => _Cardinal(sink, tension);

/// `d3-shape/src/curve/radial.js:5-25`.
class _Radial implements D3Curve {
  _Radial(this._inner);

  final D3Curve _inner;

  @override
  void areaStart() => _inner.areaStart();

  @override
  void areaEnd() => _inner.areaEnd();

  @override
  void lineStart() => _inner.lineStart();

  @override
  void lineEnd() => _inner.lineEnd();

  @override
  void point(double a, double r) =>
      // radial.js:23. NOT the same rotation as `pointRadial`; the asymmetry is
      // deliberate and must not be unified.
      _inner.point(r * math.sin(a), r * -math.cos(a));
}

/// Wraps [inner] so its points arrive as (angle, radius)
/// (`d3-shape/src/curve/radial.js:27-36`).
D3CurveFactory curveRadial(D3CurveFactory inner) =>
    (PathSink sink) => _Radial(inner(sink));
