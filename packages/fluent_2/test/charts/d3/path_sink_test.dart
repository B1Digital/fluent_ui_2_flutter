import 'dart:math' as math;

import 'package:fluent_2/src/charts/internal/d3/js_math.dart' as jsm;
import 'package:fluent_2/src/charts/internal/d3/path_sink.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  test('tauEpsilon is tau minus epsilon, not epsilon', () {
    expect(pathEpsilon, 1e-6, reason: 'd3-path/src/path.js:3');
    expect(
      tauEpsilon,
      jsm.tau - 1e-6,
      reason:
          'd3-path/src/path.js:4 — the frozen contract mis-transcribed '
          'this as 1e-6, which would make every arc a full circle',
    );
  });

  test('UiPathSink builds a dart:ui Path that reports its bounds', () {
    final sink = UiPathSink()
      ..moveTo(0, 0)
      ..lineTo(10, 20)
      ..closePath();
    expect(
      sink.path.getBounds().right,
      10.0,
      reason: 'the sink must actually feed the ui.Path, not just record',
    );
  });

  test('UiPathSink.arc splits a full circle into two half arcs', () {
    // dart:ui's arcTo cannot sweep a full turn in one call, and d3-path splits
    // it for the same reason (path.js:130-132).
    final sink = UiPathSink()..arc(50, 50, 20, 0, jsm.tau);
    final bounds = sink.path.getBounds();
    expect(bounds.left, closeTo(30, 1e-6), reason: 'a full circle at r = 20');
    expect(bounds.right, closeTo(70, 1e-6), reason: 'a full circle at r = 20');
  });

  test('SvgPathSink reproduces d3-path syntax for arcs', () {
    final sink = SvgPathSink()..arc(0, 0, 10, 0, math.pi / 2);
    expect(
      sink.d,
      startsWith('M10,0A10,10,0,0,1,'),
      reason:
          'd3-path/src/path.js:115,136 — the move-to then a quarter arc '
          'with large-arc 0 and sweep 1',
    );
  });

  test('a backwards sweep wraps by one turn, JavaScript-style', () {
    // `d3-path/src/path.js:127` normalises a negative `da` with `da % tau +
    // tau`, and JavaScript's `%` keeps the sign of the dividend. Dart's `%`
    // does not, so the naive transcription would land a whole turn higher,
    // clear of `tauEpsilon`, and draw a full circle instead of three quarters.
    // These strings are `d3.path().arc(0, 0, 10, 0, -pi / 2)` and
    // `(0, 0, 10, 0, -tau)` run against d3-path 3.1.0.
    expect(
      (SvgPathSink()..arc(0, 0, 10, 0, -jsm.halfPi)).d,
      'M10,0A10,10,0,1,1,6.123233995736766e-16,-10',
      reason: 'three quarters of a turn: large-arc 1, sweep 1, one A',
    );
    expect(
      (SvgPathSink()..arc(0, 0, 10, 0, -jsm.tau)).d,
      'M10,0A10,10,0,1,1,-10,0A10,10,0,1,1,10,0',
      reason: 'a whole turn backwards is still a whole turn, so still two arcs',
    );
  });

  group('against the d3 corpus', () {
    late List<Map<String, dynamic>> shape;

    setUpAll(() async => shape = goldenCases(await loadD3Golden(), 'shape'));

    test('SvgPathSink emits M/L/Z exactly as d3-path does', () {
      // The `curveLinear` line and area vectors are pure moveTo/lineTo/close
      // sequences, so replaying them needs no curve implementation — only the
      // emitter under test. Their coordinates are the integers of the fixture
      // plus the y0 baseline of 50, so nothing here depends on libm.
      var checked = 0;
      for (final vector in shape) {
        if (vector['curve'] != 'curveLinear') {
          continue;
        }
        final raw = (vector['data']! as List<Object?>)
            .map(jsNums)
            .toList(growable: false);
        // A gap splits the line into several sub-paths and a single point
        // closes a degenerate one (`d3-shape/src/curve/linear.js:12-30`); both
        // are the curve's business, which is Task 22's, not the sink's.
        if (raw.length < 2 ||
            raw.any((p) => p.any((v) => v == null || !v.isFinite))) {
          continue;
        }
        final points = raw
            .map((p) => (x: p[0]!, y: p[1]!))
            .toList(growable: false);
        final kind = vector['kind']! as String;
        if (kind != 'line' && kind != 'lineAllDefined' && kind != 'area') {
          continue;
        }
        final sink = SvgPathSink()..moveTo(points.first.x, points.first.y);
        for (final point in points.skip(1)) {
          sink.lineTo(point.x, point.y);
        }
        if (kind == 'area') {
          // `d3-shape/src/area.js:33` walks the baseline back in reverse and
          // then closes; y0 is the constant 50 of the fixture.
          for (final point in points.reversed) {
            sink.lineTo(point.x, 50);
          }
          sink.closePath();
        }
        expect(
          sink.d,
          vector['d'],
          reason:
              'shape vector $kind/${vector['dataIndex']} — d3-path writes M, L '
              'and Z with no spaces and no trailing ".0"',
        );
        checked++;
      }
      expect(
        checked,
        greaterThan(4),
        reason: 'a silently empty loop would pass with no assertions',
      );
    });

    test('SvgPathSink converts arc to A with d3-path flags and endpoints', () {
      // `d3-shape/src/arc.js:83-141` reduces a plain wedge — no pad angle, no
      // corner radius — to one `arc` per radius, so these three vectors test
      // the sink's arc-to-`A` conversion directly against d3-path.
      final arcs = shape.where((v) => v['kind'] == 'arc').toList();
      Map<String, dynamic> vector(double inner, double outer, double end) =>
          arcs.firstWhere((v) {
            final arc = v['arc']! as Map<String, dynamic>;
            return arc['innerRadius'] == inner &&
                arc['outerRadius'] == outer &&
                jsNum(arc['endAngle']) == end &&
                arc['padAngle'] == 0 &&
                arc['cornerRadius'] == 0;
          });
      // d3 offsets every angle by a quarter turn so that zero points up
      // (`d3-shape/src/arc.js:76`).
      const up = -jsm.halfPi;

      final semicircle = SvgPathSink()
        ..arc(0, 0, 100, up, up + math.pi)
        ..lineTo(0, 0)
        ..closePath();
      expect(
        semicircle.d,
        vector(0, 100, math.pi)['d'],
        reason:
            'a half turn sets large-arc 1 and sweep 1 '
            '(d3-path/src/path.js:136)',
      );

      final annulus = SvgPathSink()
        ..arc(0, 0, 100, up, up + jsm.halfPi)
        ..arc(0, 0, 50, up + jsm.halfPi, up, ccw: true)
        ..closePath();
      expect(
        annulus.d,
        vector(50, 100, jsm.halfPi)['d'],
        reason:
            'the inner arc runs anticlockwise, so sweep is 0, and the jump to '
            'its start is an L because the radii differ '
            '(d3-path/src/path.js:118)',
      );

      final full = SvgPathSink()..arc(0, 0, 100, up, up + jsm.tau);
      expect(
        vector(50, 100, jsm.tau)['d'],
        startsWith(full.d),
        reason:
            'a full turn is two half arcs, each with large-arc 1 '
            '(d3-path/src/path.js:131)',
      );
    });
  });
}
