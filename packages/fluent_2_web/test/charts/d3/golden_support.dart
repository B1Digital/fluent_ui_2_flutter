import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic>? _cache;

/// Reads `test/charts/d3/d3_golden.json`, the corpus dumped from the pinned
/// Node d3 modules (design spec §4.2). Cached, because 28 test files read it.
Future<Map<String, dynamic>> loadD3Golden() async {
  if (_cache != null) {
    return _cache!;
  }
  // `flutter test` runs with the package root as the working directory.
  final file = File('test/charts/d3/d3_golden.json');
  final decoded = jsonDecode(await file.readAsString());
  return _cache = decoded as Map<String, dynamic>;
}

/// Every case object in [section] of [corpus].
List<Map<String, dynamic>> goldenCases(
  Map<String, dynamic> corpus,
  String section,
) =>
    (corpus[section]! as List<Object?>)
        .cast<Map<String, dynamic>>()
        .toList(growable: false);

/// JSON has no NaN or Infinity literal, so the generator writes them as
/// strings. This turns them back into doubles; a JSON `null` stays null.
double? jsNum(Object? value) => switch (value) {
      null => null,
      'NaN' => double.nan,
      'Infinity' => double.infinity,
      '-Infinity' => double.negativeInfinity,
      final num n => n.toDouble(),
      _ => throw ArgumentError.value(value, 'value', 'not a JSON number'),
    };

/// [jsNum] over a JSON array.
List<double?> jsNums(Object? value) =>
    (value! as List<Object?>).map(jsNum).toList(growable: false);

/// Matches a double against a corpus entry. Finite values must be **exactly**
/// equal — the whole point of the corpus is that a last-ulp difference is a
/// bug, not noise (design spec §4.2 risk 3).
Matcher closeToJs(Object? expected) {
  final want = jsNum(expected);
  if (want == null) {
    return isNull;
  }
  if (want.isNaN) {
    return predicate<Object?>(
      (Object? v) => v is double && v.isNaN,
      'is NaN',
    );
  }
  return equals(want);
}

// ---------------------------------------------------------------------------
// SvgPathSink is written but commented out on purpose.
//
// It implements `PathSink` from `lib/src/charts/internal/d3/path_sink.dart` and
// depends on `tau` (js_math.dart, plan 01 Task 3), `tauEpsilon` and
// `pathEpsilon` (path_sink.dart, plan 01 Task 14). Neither file exists yet: the
// corpus is committed BEFORE the first line of the Dart port, per design spec
// §4.2, so this file has to analyse cleanly against an empty `internal/d3/`.
//
// Plan 01 Task 14 restores it by deleting the two comment delimiters below and
// re-enabling the `SvgPathSink emits d3-path syntax` test in
// `golden_support_test.dart`. Nothing before Task 22 needs it — the shape
// vectors are the first consumer.
//
// It reproduces `d3-path/src/path.js:26-145` exactly, including the
// arc-to-`A` conversion and the full-circle split at `tauEpsilon`, and it uses
// JS number formatting (`6`, not Dart's `6.0`). `UiPathSink` builds a `dart:ui`
// `Path`, which cannot be read back, so the shape vectors are compared through
// this instead.
// ---------------------------------------------------------------------------
/*
import 'dart:math' as math;

import 'package:fluent_2_web/src/charts/internal/d3/path_sink.dart';

/// The d3-path string emitter, in test code only.
final class SvgPathSink implements PathSink {
  final StringBuffer _buffer = StringBuffer();
  double? _x0;
  double? _y0;
  double? _x1;
  double? _y1;

  /// The accumulated SVG path data.
  String get d => _buffer.toString();

  static String _n(double v) {
    if (v.isNaN) {
      return 'NaN';
    }
    if (v.isInfinite) {
      return v.isNegative ? '-Infinity' : 'Infinity';
    }
    if (v == 0) {
      return '0';
    }
    final s = v.toString();
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  @override
  void moveTo(double x, double y) {
    _x0 = _x1 = x;
    _y0 = _y1 = y;
    _buffer.write('M${_n(x)},${_n(y)}');
  }

  @override
  void closePath() {
    if (_x1 != null) {
      _x1 = _x0;
      _y1 = _y0;
      _buffer.write('Z');
    }
  }

  @override
  void lineTo(double x, double y) {
    _x1 = x;
    _y1 = y;
    _buffer.write('L${_n(x)},${_n(y)}');
  }

  @override
  void quadraticCurveTo(double cx, double cy, double x, double y) {
    _x1 = x;
    _y1 = y;
    _buffer.write('Q${_n(cx)},${_n(cy)},${_n(x)},${_n(y)}');
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
    _x1 = x;
    _y1 = y;
    _buffer.write(
      'C${_n(c1x)},${_n(c1y)},${_n(c2x)},${_n(c2y)},${_n(x)},${_n(y)}',
    );
  }

  @override
  void arcTo(double x1, double y1, double x2, double y2, double r) {
    if (r < 0) {
      throw ArgumentError.value(r, 'r', 'negative radius');
    }
    final x0 = _x1;
    final y0 = _y1;
    final x21 = x2 - x1;
    final y21 = y2 - y1;
    if (x0 == null || y0 == null) {
      _x1 = x1;
      _y1 = y1;
      _buffer.write('M${_n(x1)},${_n(y1)}');
      return;
    }
    final x01 = x0 - x1;
    final y01 = y0 - y1;
    final l01Sq = x01 * x01 + y01 * y01;
    if (!(l01Sq > pathEpsilon)) {
      return;
    }
    if (!((y01 * x21 - y21 * x01).abs() > pathEpsilon) || r == 0) {
      _x1 = x1;
      _y1 = y1;
      _buffer.write('L${_n(x1)},${_n(y1)}');
      return;
    }
    final x20 = x2 - x0;
    final y20 = y2 - y0;
    final l21Sq = x21 * x21 + y21 * y21;
    final l20Sq = x20 * x20 + y20 * y20;
    final l21 = math.sqrt(l21Sq);
    final l01 = math.sqrt(l01Sq);
    final l = r *
        math.tan(
          (math.pi - math.acos((l21Sq + l01Sq - l20Sq) / (2 * l21 * l01))) / 2,
        );
    final t01 = l / l01;
    final t21 = l / l21;
    if ((t01 - 1).abs() > pathEpsilon) {
      _buffer.write('L${_n(x1 + t01 * x01)},${_n(y1 + t01 * y01)}');
    }
    _x1 = x1 + t21 * x21;
    _y1 = y1 + t21 * y21;
    final sweep = y01 * x20 > x01 * y20 ? 1 : 0;
    _buffer.write('A${_n(r)},${_n(r)},0,0,$sweep,${_n(_x1!)},${_n(_y1!)}');
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
    if (r < 0) {
      throw ArgumentError.value(r, 'r', 'negative radius');
    }
    final dx = r * math.cos(a0);
    final dy = r * math.sin(a0);
    final x0 = cx + dx;
    final y0 = cy + dy;
    final cw = ccw ? 0 : 1;
    var da = ccw ? a0 - a1 : a1 - a0;
    if (_x1 == null) {
      _buffer.write('M${_n(x0)},${_n(y0)}');
    } else if ((_x1! - x0).abs() > pathEpsilon ||
        (_y1! - y0).abs() > pathEpsilon) {
      _buffer.write('L${_n(x0)},${_n(y0)}');
    }
    if (r == 0) {
      return;
    }
    if (da < 0) {
      da = da % tau + tau;
    }
    if (da > tauEpsilon) {
      _x1 = x0;
      _y1 = y0;
      _buffer
        ..write('A${_n(r)},${_n(r)},0,1,$cw,${_n(cx - dx)},${_n(cy - dy)}')
        ..write('A${_n(r)},${_n(r)},0,1,$cw,${_n(x0)},${_n(y0)}');
    } else if (da > pathEpsilon) {
      _x1 = cx + r * math.cos(a1);
      _y1 = cy + r * math.sin(a1);
      final large = da >= math.pi ? 1 : 0;
      _buffer.write(
        'A${_n(r)},${_n(r)},0,$large,$cw,${_n(_x1!)},${_n(_y1!)}',
      );
    }
  }
}
*/
