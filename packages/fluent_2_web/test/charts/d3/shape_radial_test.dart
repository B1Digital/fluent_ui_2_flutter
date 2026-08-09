import 'dart:math' as math;

import 'package:fluent_2_web/src/charts/internal/d3/shape_radial.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  test('pointRadial rotates by -pi/2 — NOT the same as curveRadial', () {
    final p = pointRadial(0, 100);
    expect(p.dx, closeTo(0, 1e-9), reason: 'd3-shape/src/pointRadial.js:2');
    expect(
      p.dy,
      closeTo(-100, 1e-9),
      reason:
          'pointRadial uses (r cos(a - pi/2), r sin(a - pi/2)); the curve '
          'wrapper uses (r sin a, r -cos a). They agree here and diverge in '
          'sign convention elsewhere — the asymmetry is deliberate '
          '(design spec §6 / contract §2.25)',
    );
    expect(
      pointRadial(math.pi / 2, 100).dx,
      closeTo(100, 1e-9),
      reason: 'a quarter turn clockwise from twelve o\'clock',
    );
  });

  test('AreaRadial defaults to curveLinearClosed', () {
    final sink = SvgPathSink();
    AreaRadial<List<double>>(
      angle: (List<double> d, int i, List<List<double>> _) => d[0],
      innerRadius: (List<double> d, int i, List<List<double>> _) => 0,
      outerRadius: (List<double> d, int i, List<List<double>> _) => d[1],
    )(<List<double>>[
      <double>[0, 10],
      <double>[math.pi / 2, 20],
      <double>[math.pi, 30],
    ], sink);
    expect(
      sink.d,
      contains('Z'),
      reason:
          'PolarChart.tsx:448 passes curveLinearClosed as the default, and '
          'contract §2.25 fixes it as the parameter default',
    );
  });

  test('AreaRadial honours defined on the reverse-baseline replay', () {
    final sink = SvgPathSink();
    AreaRadial<List<double>>(
      angle: (List<double> d, int i, List<List<double>> _) => d[0],
      innerRadius: (List<double> d, int i, List<List<double>> _) => 0,
      outerRadius: (List<double> d, int i, List<List<double>> _) => d[1],
      defined: (List<double> d, int i, List<List<double>> _) => d[1].isFinite,
    )(<List<double>>[
      <double>[0, 10],
      <double>[math.pi / 2, double.nan],
      <double>[math.pi, 30],
    ], sink);
    expect(
      'M'.allMatches(sink.d).length,
      4,
      reason:
          'PolarChart.tsx:450 overrides defined with isPlottable, so the NaN '
          'splits the data into two runs. Each run is two sub-paths, not one: '
          'area.js:39-47 ends the topline and starts a fresh line for the '
          'reversed baseline, and curveLinearClosed closes both '
          '(linearClosed.js:14). Two runs therefore give four M commands — the '
          'corpus areaRadial vector shows exactly the same four',
    );
  });

  test('against the d3 golden corpus', () async {
    final corpus = await loadD3Golden();
    for (final c in goldenCases(corpus, 'shape')) {
      if (c['kind'] == 'pointRadial') {
        // The plan's test skipped these four vectors; they are the only
        // machine-checked evidence that the quarter turn matches d3 bit for
        // bit, including cos(-pi/2) landing on 6.123233995736766e-15 rather
        // than a tidy zero.
        final out = jsNums(c['out']);
        final p = pointRadial(jsNum(c['angle'])!, jsNum(c['radius'])!);
        expect(
          p.dx,
          closeToJs(out[0]),
          reason:
              'pointRadial x, angle '
              '${c['angle']} radius ${c['radius']}',
        );
        expect(
          p.dy,
          closeToJs(out[1]),
          reason:
              'pointRadial y, angle '
              '${c['angle']} radius ${c['radius']}',
        );
        continue;
      }
      if (c['kind'] != 'lineRadial' && c['kind'] != 'areaRadial') {
        continue;
      }
      final points = (c['data']! as List<Object?>)
          .map(
            (Object? p) =>
                jsNums(p).map((double? v) => v ?? double.nan).toList(),
          )
          .toList();
      bool defined(List<double> d, int i, List<List<double>> _) =>
          d[1].isFinite;
      final sink = SvgPathSink();
      if (c['kind'] == 'lineRadial') {
        LineRadial<List<double>>(
          angle: (List<double> d, int i, List<List<double>> _) => d[0],
          radius: (List<double> d, int i, List<List<double>> _) => d[1],
          defined: defined,
        )(points, sink);
      } else {
        AreaRadial<List<double>>(
          angle: (List<double> d, int i, List<List<double>> _) => d[0],
          innerRadius: (List<double> d, int i, List<List<double>> _) => 0,
          outerRadius: (List<double> d, int i, List<List<double>> _) => d[1],
          defined: defined,
        )(points, sink);
      }
      expect(sink.d, c['d'], reason: '${c['kind']} over the polar probe set');
    }
  });
}
