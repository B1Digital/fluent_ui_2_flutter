import 'package:fluent_2/src/charts/internal/d3/curves.dart';
import 'package:fluent_2/src/charts/internal/d3/shape_line_area.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  const data = <List<double>>[
    <double>[0, 5],
    <double>[10, double.nan],
    <double>[20, 15],
    <double>[30, double.nan],
    <double>[40, 25],
  ];

  bool plottable(List<double> d, int i, List<List<double>> all) =>
      d[0].isFinite && d[1].isFinite;

  test('a gapped line breaks into sub-paths', () {
    final sink = SvgPathSink();
    Line<List<double>>(
      x: (List<double> d, int i, List<List<double>> _) => d[0],
      y: (List<double> d, int i, List<List<double>> _) => d[1],
      defined: plottable,
    )(data, sink);
    expect(
      'M'.allMatches(sink.d).length,
      3,
      reason:
          'three defined points, each isolated, so d3-shape/src/line.js:'
          '27-30 opens three sub-paths — LineChart.tsx:678 relies on this',
    );
  });

  test('without defined the same data draws one path through the NaNs', () {
    final sink = SvgPathSink();
    Line<List<double>>(
      x: (List<double> d, int i, List<List<double>> _) => d[0],
      y: (List<double> d, int i, List<List<double>> _) => d[1],
    )(data, sink);
    expect(
      'M'.allMatches(sink.d).length,
      1,
      reason:
          'this is exactly the wrong rendering the recon would have '
          'shipped by hardcoding defined = true',
    );
  });

  test('the area baseline is replayed in reverse through the SAME curve', () {
    final sink = SvgPathSink();
    Area<List<double>>(
      x0: (List<double> d, int i, List<List<double>> _) => d[0],
      y0: (List<double> d, int i, List<List<double>> _) => 50,
      y1: (List<double> d, int i, List<List<double>> _) => d[1],
      curve: curveStep,
    )(const <List<double>>[
      <double>[0, 0],
      <double>[10, 10],
      <double>[20, 0],
    ], sink);
    expect(
      sink.d,
      endsWith('Z'),
      reason: 'area.js:42-46 closes after replaying the baseline',
    );
    expect(
      sink.d,
      'M0,0L5,0L5,10L15,10L15,0L20,0L20,50L15,50L15,50L5,50L5,50L0,50Z',
      reason:
          'the step risers at x = 5 and x = 15 appear on the top edge and '
          'again on the reversed baseline (the four degenerate L…,50 pairs), '
          'because area.js:42-44 pushes the baseline through the SAME curve '
          'instance rather than drawing a straight line. The plan asserted '
          "'L5,' twice; d3 itself emits it four times — verified against the "
          'pinned module, so the whole string is pinned instead of a count',
    );
    expect(
      'L5,'.allMatches(sink.d).length,
      4,
      reason:
          'two risers at x = 5: one on the top edge, one on the reversed '
          'baseline, each step emitting a horizontal then a vertical segment '
          '(`d3-shape/src/curve/step.js:22-33`)',
    );
  });

  test('the area honours defined on the reverse replay too', () {
    final sink = SvgPathSink();
    Area<List<double>>(
      x0: (List<double> d, int i, List<List<double>> _) => d[0],
      y0: (List<double> d, int i, List<List<double>> _) => 50,
      y1: (List<double> d, int i, List<List<double>> _) => d[1],
      defined: plottable,
    )(data, sink);
    expect(
      'Z'.allMatches(sink.d).length,
      3,
      reason:
          'each defined run closes its own polygon; PolarChart.tsx:450 '
          'depends on this branch, the hardest one in area()',
    );
  });

  test('against the d3 golden corpus', () async {
    final corpus = await loadD3Golden();
    var checked = 0;
    for (final c in goldenCases(corpus, 'shape')) {
      final kind = c['kind'];
      if (kind != 'line' && kind != 'area' && kind != 'lineAllDefined') {
        continue;
      }
      final points = (c['data']! as List<Object?>)
          .map(
            (Object? p) =>
                jsNums(p).map((double? v) => v ?? double.nan).toList(),
          )
          .toList();
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
      final sink = SvgPathSink();
      if (kind == 'area') {
        Area<List<double>>(
          x0: (List<double> d, int i, List<List<double>> _) => d[0],
          y0: (List<double> d, int i, List<List<double>> _) => 50,
          y1: (List<double> d, int i, List<List<double>> _) => d[1],
          defined: plottable,
          curve: factories[c['curve']]!,
        )(points, sink);
      } else {
        final line = Line<List<double>>(
          x: (List<double> d, int i, List<List<double>> _) => d[0],
          y: (List<double> d, int i, List<List<double>> _) => d[1],
          curve: factories[c['curve']]!,
        );
        // `lineAllDefined` is the same generator left on d3's own default
        // predicate (`crawlers/d3-golden/generate.mjs:415`), which is what
        // pins the default branch to the upstream string.
        if (kind == 'line') {
          line.defined = plottable;
        }
        line(points, sink);
      }
      expect(
        sink.d,
        c['d'] ?? '',
        reason:
            '$kind with ${c['curve']} over data set '
            '${c['dataIndex']}',
      );
      checked++;
    }
    expect(
      checked,
      95,
      reason:
          '9 curves x 5 data sets x 2 generators, plus the 5 '
          'default-predicate lines — a `kind` filter that silently matched '
          'nothing would otherwise pass this test',
    );
  });
}
