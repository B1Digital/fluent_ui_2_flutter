import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'hue_map.dart';

/// Generates a 16-stop Fluent brand ramp from a single key color, porting the
/// algorithm behind Fluent's Theme Designer.
///
/// A ramp is a continuous curve through CIE Lab space: two quadratic bezier
/// segments running black → key color → white. Shades are sampled off that
/// curve at lightnesses taken from a per-hue snapping table, then each is
/// chroma-reduced until it lands inside the sRGB gamut.
///
/// **This does not reproduce the shipped ramps.** `FluentBrandRamp.web` and
/// friends are hand-authored; running this on `#0F6CBD` matches none of their 16
/// stops. Notably the key color you pass in generally does *not* appear at stop
/// 80, because the lightness ladder comes from [kHueToSnappingPoints] and not
/// from the key color's own lightness. Use this for custom brands; use the named
/// constants when you need to match Microsoft's actual themes.
///
/// Source: `packages/react-components/theme-designer/src/` — `palettes.ts`,
/// `geometry.ts`, `csswg.ts`, `hueMap.ts`.
abstract final class FluentBrandGenerator {
  /// Builds 16 shades, ordered stop 10 (darkest) → 160 (lightest).
  ///
  /// [vibrancy] maps to the Theme Designer's single slider, which drives both
  /// bezier control points. Upstream defaults them separately — `darkCp` 2/3 and
  /// `lightCp` 1/3 — so leaving [vibrancy] null reproduces those defaults.
  /// Higher values push the control points toward the ends of the gamut, so
  /// chroma falls off more slowly near the key color.
  ///
  /// [hueTorsion] rotates the curve's points in Lab space, making the ramp
  /// travel through neighbouring hues (a helix rather than a plane curve).
  /// The designer UI clamps it to -0.5…0.5.
  static List<Color> shades(
    Color keyColor, {
    double? vibrancy,
    double hueTorsion = 0,
    int shadeCount = 16,
  }) {
    final darkCp = vibrancy ?? 2 / 3;
    final lightCp = vibrancy ?? 1 / 3;
    final keyLch = _srgbToLch(_colorToSrgb(keyColor));

    final curve = _curvePathFromPalette(keyLch, darkCp, lightCp);

    // Upstream: ceil((curveDepth * (1 + abs(torsion || 1))) / 2). The `|| 1` is
    // a JS falsy check, so torsion 0 behaves as 1 — reproduced deliberately,
    // Dart's `??` would not.
    final torsionOrOne = hueTorsion == 0 ? 1.0 : hueTorsion;
    final divisions = (24 * (1 + torsionOrOne.abs()) / 2).ceil();

    final points = _pointsOnCurvePath(
      curve,
      divisions,
    ).map((p) => _pointOnHelix(p, hueTorsion, keyLch[0])).toList();

    return _shadesFromCurvePoints(
      points,
      shadeCount,
      _hueOf(keyColor),
    ).map(_labToColor).toList();
  }

  // ------------------------------------------------------------------ curve

  /// Two quadratic beziers meeting at the key color, anchored at black and
  /// white. Control points carry the key color's a/b, which is what keeps
  /// chroma up as the curve approaches the ends.
  static List<List<List<double>>> _curvePathFromPalette(
    List<double> keyLch,
    double darkCp,
    double lightCp,
  ) {
    final key = _lchToLab(keyLch);
    final l = key[0], a = key[1], b = key[2];
    return [
      [
        [0, 0, 0],
        [l * (1 - darkCp), a, b],
        key,
      ],
      [
        key,
        [l + (100 - l) * lightCp, a, b],
        [100, 0, 0],
      ],
    ];
  }

  static double _quadBezier(double t, double p0, double p1, double p2) {
    final k = 1 - t;
    return k * k * p0 + 2 * k * t * p1 + t * t * p2;
  }

  static List<double> _pointOnCurve(List<List<double>> curve, double t) => [
    _quadBezier(t, curve[0][0], curve[1][0], curve[2][0]),
    _quadBezier(t, curve[0][1], curve[1][1], curve[2][1]),
    _quadBezier(t, curve[0][2], curve[1][2], curve[2][2]),
  ];

  /// Samples each segment independently at uniform `t`, then concatenates.
  ///
  /// Note there is no arc-length reparameterisation: upstream's arc-length
  /// machinery exists but this path never calls it. The shared junction point
  /// (the key color) is emitted once.
  static List<List<double>> _pointsOnCurvePath(
    List<List<List<double>>> curves,
    int divisions,
  ) {
    final points = <List<double>>[];
    List<double>? last;
    for (final curve in curves) {
      for (var d = 0; d <= divisions; d++) {
        final point = _pointOnCurve(curve, d / divisions);
        if (last != null &&
            last[0] == point[0] &&
            last[1] == point[1] &&
            last[2] == point[2]) {
          continue;
        }
        points.add(point);
        last = point;
      }
    }
    return points;
  }

  /// Rotates hue proportionally to distance from the key color's lightness,
  /// turning the plane curve into a helix.
  static List<double> _pointOnHelix(
    List<double> pointOnCurve,
    double torsion,
    double torsionT0,
  ) {
    final t = pointOnCurve[0];
    final lch = _labToLch(pointOnCurve);
    return _lchToLab([lch[0], lch[1], lch[2] + torsion * (t - torsionT0)]);
  }

  // ----------------------------------------------------------------- shades

  static List<List<double>> _shadesFromCurvePoints(
    List<List<double>> curvePoints,
    int shadeCount,
    int hue,
  ) {
    if (curvePoints.length <= 2) return const [];

    final snap = kHueToSnappingPoints[hue];
    final min = snap[0] * 100, center = snap[1] * 100, max = snap[2] * 100;
    final ladder = _interpolateThroughPoint(min, max, center, 16);

    final shades = <List<double>>[];
    var c = 0;
    for (var i = 0; i < shadeCount; i++) {
      // linearity is 1 in the shipped path, so the logarithmic term upstream
      // blends at zero weight and is omitted here.
      final l = math.min(max, math.max(min, ladder[i]));

      // Upstream has no upper bound on this walk and throws past the last
      // point; clamped so an extreme key color degrades instead of crashing.
      while (c + 1 < curvePoints.length - 1 && l > curvePoints[c + 1][0]) {
        c++;
      }

      final p1 = curvePoints[c], p2 = curvePoints[c + 1];
      final span = p2[0] - p1[0];
      final u = span == 0 ? 0.0 : (l - p1[0]) / span;

      shades.add(
        _snapIntoGamut([
          p1[0] + (p2[0] - p1[0]) * u,
          p1[1] + (p2[1] - p1[1]) * u,
          p1[2] + (p2[2] - p1[2]) * u,
        ]),
      );
    }
    return shades;
  }

  /// Evenly spaces [numSamples] values from [start] to [end], forcing one
  /// sample to land exactly on [inBetween]. The two halves get different step
  /// sizes, which is why ramps are asymmetric about the key color.
  static List<double> _interpolateThroughPoint(
    double start,
    double end,
    double inBetween,
    int numSamples,
  ) {
    if (numSamples < 3) {
      throw ArgumentError.value(numSamples, 'numSamples', 'Must be at least 3');
    }
    final ratio = (inBetween - start) / (end - start);
    final idx = ((numSamples - 1) * ratio).floor();

    final result = List<double>.filled(numSamples, 0);
    result[0] = start;
    result[idx] = inBetween;
    result[numSamples - 1] = end;

    final stepBefore = idx == 0 ? 0.0 : (inBetween - start) / idx;
    final stepAfter = (end - inBetween) / (numSamples - 1 - idx);
    for (var i = 1; i < idx; i++) {
      result[i] = start + i * stepBefore;
    }
    for (var i = idx + 1; i < numSamples - 1; i++) {
      result[i] = inBetween + (i - idx) * stepAfter;
    }
    return result;
  }

  // ------------------------------------------------------------ gamut mapping

  static const double _gamutSlack = 0.000005;
  static const double _chromaEpsilon = 0.0001;

  static bool _lchInSrgb(double l, double c, double h) {
    final rgb = _lchToSrgb([l, c, h]);
    return rgb.every((v) => v >= 0 - _gamutSlack && v <= 1 + _gamutSlack);
  }

  /// Holds lightness and hue, bisecting chroma down until the color sits on the
  /// sRGB boundary. Clipping RGB directly would shift hue instead.
  static List<double> _snapIntoGamut(List<double> lab) {
    final lch = _labToLch(lab);
    final l = lch[0], h = lch[2];
    var c = lch[1];
    if (_lchInSrgb(l, c, h)) return lab;

    var hiC = c, loC = 0.0;
    c /= 2;
    while (hiC - loC > _chromaEpsilon) {
      if (_lchInSrgb(l, c, h)) {
        loC = c;
      } else {
        hiC = c;
      }
      c = (hiC + loC) / 2;
    }
    return _lchToLab([l, c, h]);
  }

  // -------------------------------------------------------- color conversions
  // CSS Color 4 reference conversions. D50 white point for Lab, D65 sRGB
  // primaries, Bradford adaptation between them on every round trip.

  static const List<double> _d50White = [0.96422, 1.0, 0.82521];
  static const double _epsilon = 216 / 24389;
  static const double _kappa = 24389 / 27;

  static const List<List<double>> _linSrgbToXyz = [
    [0.41239079926595934, 0.357584339383878, 0.1804807884018343],
    [0.21263900587151027, 0.715168678767756, 0.07219231536073371],
    [0.01933081871559182, 0.11919477979462598, 0.9505321522496607],
  ];
  static const List<List<double>> _xyzToLinSrgb = [
    [3.2409699419045226, -1.537383177570094, -0.4986107602930034],
    [-0.9692436362808796, 1.8759675015077202, 0.04155505740717559],
    [0.05563007969699366, -0.20397695888897652, 1.0569715142428786],
  ];
  static const List<List<double>> _d65ToD50 = [
    [1.0479298208405488, 0.022946793341019088, -0.05019222954313557],
    [0.029627815688159344, 0.990434484573249, -0.01707382502938514],
    [-0.009243058152591178, 0.015055144896577895, 0.7518742899580008],
  ];
  static const List<List<double>> _d50ToD65 = [
    [0.9554734527042182, -0.023098536874261423, 0.0632593086610217],
    [-0.028369706963208136, 1.0099954580058226, 0.021041398966943008],
    [0.012314001688319899, -0.020507696433477912, 1.3303659366080753],
  ];

  static List<double> _mul(List<List<double>> m, List<double> v) => [
    m[0][0] * v[0] + m[0][1] * v[1] + m[0][2] * v[2],
    m[1][0] * v[0] + m[1][1] * v[1] + m[1][2] * v[2],
    m[2][0] * v[0] + m[2][1] * v[1] + m[2][2] * v[2],
  ];

  static List<double> _linSrgb(List<double> rgb) => rgb.map((val) {
    final sign = val < 0 ? -1.0 : 1.0;
    final abs = val.abs();
    if (abs < 0.04045) return val / 12.92;
    return sign * math.pow((abs + 0.055) / 1.055, 2.4).toDouble();
  }).toList();

  static List<double> _gamSrgb(List<double> rgb) => rgb.map((val) {
    final sign = val < 0 ? -1.0 : 1.0;
    final abs = val.abs();
    if (abs > 0.0031308) {
      return sign * (1.055 * math.pow(abs, 1 / 2.4).toDouble() - 0.055);
    }
    return 12.92 * val;
  }).toList();

  static List<double> _xyzToLab(List<double> xyz) {
    final scaled = [
      xyz[0] / _d50White[0],
      xyz[1] / _d50White[1],
      xyz[2] / _d50White[2],
    ];
    final f = scaled
        .map((v) => v > _epsilon ? _cbrt(v) : (_kappa * v + 16) / 116)
        .toList();
    return [116 * f[1] - 16, 500 * (f[0] - f[1]), 200 * (f[1] - f[2])];
  }

  static List<double> _labToXyz(List<double> lab) {
    final f1 = (lab[0] + 16) / 116;
    final f0 = lab[1] / 500 + f1;
    final f2 = f1 - lab[2] / 200;
    final xyz = [
      math.pow(f0, 3) > _epsilon
          ? math.pow(f0, 3).toDouble()
          : (116 * f0 - 16) / _kappa,
      lab[0] > _kappa * _epsilon
          ? math.pow((lab[0] + 16) / 116, 3).toDouble()
          : lab[0] / _kappa,
      math.pow(f2, 3) > _epsilon
          ? math.pow(f2, 3).toDouble()
          : (116 * f2 - 16) / _kappa,
    ];
    return [
      xyz[0] * _d50White[0],
      xyz[1] * _d50White[1],
      xyz[2] * _d50White[2],
    ];
  }

  static List<double> _labToLch(List<double> lab) {
    final hue = math.atan2(lab[2], lab[1]) * 180 / math.pi;
    return [
      lab[0],
      math.sqrt(lab[1] * lab[1] + lab[2] * lab[2]),
      hue >= 0 ? hue : hue + 360,
    ];
  }

  static List<double> _lchToLab(List<double> lch) => [
    lch[0],
    lch[1] * math.cos(lch[2] * math.pi / 180),
    lch[1] * math.sin(lch[2] * math.pi / 180),
  ];

  static List<double> _srgbToLch(List<double> rgb) =>
      _labToLch(_xyzToLab(_mul(_d65ToD50, _mul(_linSrgbToXyz, _linSrgb(rgb)))));

  static List<double> _labToSrgb(List<double> lab) =>
      _gamSrgb(_mul(_xyzToLinSrgb, _mul(_d50ToD65, _labToXyz(lab))));

  static List<double> _lchToSrgb(List<double> lch) =>
      _labToSrgb(_lchToLab(lch));

  static double _cbrt(double v) =>
      v < 0 ? -math.pow(-v, 1 / 3).toDouble() : math.pow(v, 1 / 3).toDouble();

  // ---------------------------------------------------------------- plumbing

  static List<double> _colorToSrgb(Color color) {
    final argb = color.toARGB32();
    return [
      ((argb >> 16) & 0xFF) / 255,
      ((argb >> 8) & 0xFF) / 255,
      (argb & 0xFF) / 255,
    ];
  }

  /// Quantises with `floor(x * 256)`, matching upstream. Using the more usual
  /// `round(x * 255)` shifts most channels by one.
  static Color _labToColor(List<double> lab) {
    final rgb = _labToSrgb(lab).map((x) {
      if (x < 0) return 0;
      return x >= 1.0 ? 255 : (x * 256).floor();
    }).toList();
    return Color.fromARGB(255, rgb[0], rgb[1], rgb[2]);
  }

  /// HSL hue in integer degrees, computed off the 8-bit channels exactly as
  /// upstream does — this indexes [kHueToSnappingPoints].
  static int _hueOf(Color color) {
    final argb = color.toARGB32();
    final r = ((argb >> 16) & 0xFF) / 255;
    final g = ((argb >> 8) & 0xFF) / 255;
    final b = (argb & 0xFF) / 255;
    final cmax = math.max(r, math.max(g, b));
    final cmin = math.min(r, math.min(g, b));
    final delta = cmax - cmin;

    double hue;
    if (delta == 0) {
      hue = 0;
    } else if (cmax == r) {
      hue = ((g - b) / delta) % 6;
    } else if (cmax == g) {
      hue = (b - r) / delta + 2;
    } else {
      hue = (r - g) / delta + 4;
    }
    final degrees = (hue * 60).round();
    return degrees < 0 ? degrees + 360 : degrees % 360;
  }
}
