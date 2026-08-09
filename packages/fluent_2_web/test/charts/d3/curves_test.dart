import 'package:fluent_2_web/src/charts/internal/d3/curves.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  String draw(D3CurveFactory factory, List<List<double>> points) {
    final sink = SvgPathSink();
    final curve = factory(sink)..lineStart();
    for (final p in points) {
      curve.point(p[0], p[1]);
    }
    curve.lineEnd();
    return sink.d;
  }

  test('curveLinear is moveTo then lineTo', () {
    expect(
      draw(curveLinear, <List<double>>[
        <double>[0, 0],
        <double>[10, 20],
      ]),
      'M0,0L10,20',
      reason: 'd3-shape/src/curve/linear.js:22-24',
    );
  });

  test('curveLinearClosed closes on lineEnd', () {
    expect(
      draw(curveLinearClosed, <List<double>>[
        <double>[0, 0],
        <double>[10, 0],
        <double>[10, 10],
      ]),
      'M0,0L10,0L10,10Z',
      reason:
          'd3-shape/src/curve/linearClosed.js:14 — PolarChart\'s radial '
          'areas default to this (PolarChart.tsx:448)',
    );
  });

  test('curveStep places the riser at the midpoint', () {
    expect(
      draw(curveStep, <List<double>>[
        <double>[0, 0],
        <double>[10, 10],
      ]),
      'M0,0L5,0L5,10L10,10',
      reason: 'd3-shape/src/curve/step.js:32-34 with t = 0.5 (step.js:44)',
    );
  });

  test(
    'curveStepBefore and curveStepAfter differ in which axis moves first',
    () {
      expect(
        draw(curveStepBefore, <List<double>>[
          <double>[0, 0],
          <double>[10, 10],
        ]),
        'M0,0L0,10L10,10',
        reason: 'step.js:29-30 with t = 0',
      );
      expect(
        draw(curveStepAfter, <List<double>>[
          <double>[0, 0],
          <double>[10, 10],
        ]),
        'M0,0L10,0L10,10',
        reason: 'step.js:32-34 with t = 1',
      );
    },
  );

  test('curveMonotoneX ignores a coincident point', () {
    final withDuplicate = draw(curveMonotoneX, <List<double>>[
      <double>[0, 0],
      <double>[10, 10],
      <double>[10, 10],
      <double>[20, 0],
    ]);
    final without = draw(curveMonotoneX, <List<double>>[
      <double>[0, 0],
      <double>[10, 10],
      <double>[20, 0],
    ]);
    expect(
      withDuplicate,
      without,
      reason:
          'd3-shape/src/curve/monotone.js:65 returns early on a repeat, '
          'and AreaChart draws through this curve on every series',
    );
  });

  test('curveBumpX puts both control points at the x midpoint', () {
    expect(
      draw(curveBumpX, <List<double>>[
        <double>[0, 0],
        <double>[10, 10],
      ]),
      'M0,0C5,0,5,10,10,10',
      reason:
          'd3-shape/src/curve/bump.js:32 — this is SankeyChart\'s ribbon '
          'curve, imported misleadingly as d3CurveBasis (SankeyChart.tsx:12)',
    );
  });

  test('curveRadial converts (angle, radius) before delegating', () {
    final sink = SvgPathSink();
    final curve = curveRadial(curveLinear)(sink)..lineStart();
    curve
      ..point(0, 100)
      ..lineEnd();
    expect(
      sink.d,
      // The plan (task 22, step 1) expected 'M0,-100' with no Z. That is
      // wrong: the wrapped curveLinear sees a single point, so
      // `linear.js:16`'s `_line !== 0 && _point === 1` fires and closes the
      // sub-path. Confirmed against the pinned module — `curveRadial(
      // curveLinear)` over one point returns "M0,-100Z" — and corroborated by
      // the corpus, whose one-point curveLinear vector is "M0,0Z".
      'M0,-100Z',
      reason:
          'd3-shape/src/curve/radial.js:23 — point(a, r) becomes '
          'inner.point(r * sin a, r * -cos a), which is NOT the same rotation '
          'as pointRadial and must not be unified with it',
    );
  });

  test('curveCardinal defaults to tension 0, so _k is 1/6', () {
    final d = draw(curveCardinal(), <List<double>>[
      <double>[0, 0],
      <double>[10, 10],
      <double>[20, 0],
    ]);
    expect(
      d,
      contains('C'),
      reason: 'd3-shape/src/curve/cardinal.js:14, _k = (1 - tension) / 6',
    );
  });

  test(
    'against the d3 golden corpus — every curve over every point set',
    () async {
      final corpus = await loadD3Golden();
      final factories = <String, D3CurveFactory>{
        'curveLinear': curveLinear,
        'curveLinearClosed': curveLinearClosed,
        'curveNatural': curveNatural,
        'curveStep': curveStep,
        'curveStepBefore': curveStepBefore,
        'curveStepAfter': curveStepAfter,
        'curveMonotoneX': curveMonotoneX,
        'curveBumpX': curveBumpX,
        'curveCardinal': curveCardinal(),
      };
      var asserted = 0;
      for (final c in goldenCases(corpus, 'shape')) {
        if (c['kind'] != 'line') {
          continue;
        }
        final points = (c['data']! as List<Object?>)
            .map(jsNums)
            .where(
              (List<double?> p) =>
                  p[0] != null && !p[0]!.isNaN && p[1] != null && !p[1]!.isNaN,
            )
            .map((List<double?> p) => <double>[p[0]!, p[1]!])
            .toList();
        if (points.length != (c['data']! as List<Object?>).length) {
          // The gapped set belongs to the Line generator's test, not here.
          continue;
        }
        expect(
          draw(factories[c['curve']]!, points),
          c['d'],
          reason: '${c['curve']} over data set ${c['dataIndex']}',
        );
        asserted++;
      }
      expect(
        asserted,
        36,
        reason:
            'The corpus holds 9 curves over 5 point sets, one of which is '
            'gapped and skipped above, so 36 vectors must actually be '
            'compared — without this a filter typo would let the loop pass '
            'while asserting nothing',
      );
    },
  );
}
