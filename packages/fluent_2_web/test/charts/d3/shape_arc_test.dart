import 'dart:math' as math;

import 'package:fluent_2_web/src/charts/internal/d3/shape_arc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  test('epsilon is 1e-12, not d3-path\'s 1e-6', () {
    expect(
      arcEpsilon,
      1e-12,
      reason:
          'd3-shape/src/math.js:9 — d3-shape and d3-path use different '
          'epsilons and mixing them changes which branch an arc takes',
    );
  });

  test('the origin is shifted a quarter turn so 0 points up', () {
    final sink = SvgPathSink();
    Arc()(
      const ArcDatum(
        startAngle: 0,
        endAngle: math.pi,
        innerRadius: 0,
        outerRadius: 100,
      ),
      sink,
    );
    expect(
      sink.d,
      startsWith('M6.123233995736766e-15,-100'),
      reason:
          'd3-shape/src/arc.js:93-94 subtract halfPi, so startAngle 0 is '
          'straight up. The plan asserted `M0,-100`, which d3 never emits: '
          'cos(-pi/2) is 6.123233995736766e-17, not zero, so x is 6.12e-15 at '
          'r = 100. The corpus entry for this very arc is '
          '`M6.123233995736766e-15,-100A100,100,0,1,1,…`, and the y of -100 is '
          'what makes twelve o\'clock the origin',
    );
  });

  test('a full turn takes the annulus branch, drawn as two half arcs', () {
    final sink = SvgPathSink();
    Arc()(
      const ArcDatum(
        startAngle: 0,
        endAngle: 2 * math.pi,
        innerRadius: 50,
        outerRadius: 100,
      ),
      sink,
    );
    expect(
      'A'.allMatches(sink.d).length,
      4,
      reason:
          'arc.js:107-113 draws the outer ring then the inner one, and '
          'd3-path splits each full circle into two A commands (path.js:131)',
    );
  });

  test('a sector collapsed by padding degenerates to a moveTo', () {
    final sink = SvgPathSink();
    Arc()(
      const ArcDatum(
        startAngle: 0,
        endAngle: 0.001,
        padAngle: 0.5,
        innerRadius: 50,
        outerRadius: 100,
      ),
      sink,
    );
    expect(
      'A'.allMatches(sink.d).length,
      0,
      reason: 'arc.js:175 — !(da1 > epsilon) after padding leaves only a move',
    );
  });

  test('centroid is the mid-radius at the mid-angle', () {
    final c = Arc().centroid(
      const ArcDatum(
        startAngle: 0,
        endAngle: math.pi,
        innerRadius: 0,
        outerRadius: 100,
      ),
    );
    expect(c.dx, closeTo(50, 1e-9), reason: 'arc.js:230-233');
    expect(c.dy, closeTo(0, 1e-9), reason: 'arc.js:230-233');
  });

  test('an inverted radius pair is swapped', () {
    final sink = SvgPathSink();
    Arc()(
      const ArcDatum(
        startAngle: 1,
        endAngle: 0.5,
        innerRadius: 100,
        outerRadius: 50,
      ),
      sink,
    );
    expect(
      sink.d,
      isNotEmpty,
      reason: 'arc.js:101 swaps r0 and r1 so the outer is always the larger',
    );
  });

  test('against the d3 golden corpus', () async {
    final corpus = await loadD3Golden();
    for (final c in goldenCases(corpus, 'shape')) {
      if (c['kind'] != 'arc') {
        continue;
      }
      final spec = c['arc']! as Map<String, dynamic>;
      final datum = ArcDatum(
        startAngle: jsNum(spec['startAngle'])!,
        endAngle: jsNum(spec['endAngle'])!,
        padAngle: jsNum(spec['padAngle'])!,
        innerRadius: jsNum(spec['innerRadius'])!,
        outerRadius: jsNum(spec['outerRadius'])!,
      );
      final arc = Arc(
        cornerRadius: jsNum(spec['cornerRadius'])!,
        padRadius: jsNum(spec['padRadius']),
      );
      final sink = SvgPathSink();
      arc(datum, sink);
      expect(sink.d, c['d'], reason: 'arc $spec');
      final centroid = arc.centroid(datum);
      final want = jsNums(c['centroid']);
      // The `d` strings above are compared exactly, which is the point of the
      // corpus. The centroid is not: `sin` is not required to be correctly
      // rounded, and Dart's libm and V8's fdlibm disagree by one unit in the
      // last place on the last vector here — sin(-0.8207963267948966) is
      // -0.7316888688738209 in Dart and -0.7316888688738208 in Node, giving
      // -54.876665165536565 against -54.87666516553656. No arrangement of the
      // Dart source closes that gap; the shared angle is bit-identical. 1e-12
      // is roughly seventy of those ulps at r = 100, far below any real
      // transcription error, which would be off by whole units.
      expect(
        centroid.dx,
        closeTo(want[0]!, 1e-12),
        reason: 'centroid dx of $spec',
      );
      expect(
        centroid.dy,
        closeTo(want[1]!, 1e-12),
        reason: 'centroid dy of $spec',
      );
    }
  });
}
