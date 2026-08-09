import 'package:fluent_2_web/src/charts/internal/d3/js_math.dart' as jsm;
import 'package:fluent_2_web/src/charts/internal/d3/shape_pie.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  test('sort: null keeps input order (both comparators cleared)', () {
    final arcs = Pie<double>(value: (double d) => d)(<double>[1, 5, 2]);
    expect(
      arcs.map((PieArc a) => a.value).toList(),
      <double>[1, 5, 2],
      reason:
          'Pie.tsx:29 and :94 call .sort(null), and d3-shape/src/pie.js:64 '
          'clears sortValues too — the descending default never runs',
    );
  });

  test(
    'a non-positive value contributes no angle but still eats a padAngle',
    () {
      final arcs = Pie<double>(value: (double d) => d, padAngle: 0.02)(<double>[
        0,
        5,
        -2,
        3,
      ]);
      expect(
        arcs[0].endAngle - arcs[0].startAngle,
        closeTo(0.02, 1e-12),
        reason:
            'pie.js:42 — `v > 0 ? v * k : 0` plus pa, so a zero slice is '
            'exactly one padAngle wide',
      );
      expect(
        arcs.last.endAngle,
        closeTo(jsm.tau, 1e-9),
        reason: 'the sweep still closes at tau',
      );
    },
  );

  test('padAngle is capped at |da| / n', () {
    final arcs = Pie<double>(value: (double d) => d, padAngle: 99)(<double>[
      1,
      1,
    ]);
    expect(
      arcs.first.padAngle,
      closeTo(jsm.tau / 2, 1e-12),
      reason: 'pie.js:26, `Math.min(Math.abs(da) / n, padAngle)`',
    );
  });

  test('against the d3 golden corpus', () async {
    final corpus = await loadD3Golden();
    var checked = 0;
    for (final c in goldenCases(corpus, 'shape')) {
      if (c['kind'] != 'pie') {
        continue;
      }
      final values = jsNums(c['values']).cast<double>();
      final arcs = Pie<double>(
        value: (double d) => d,
        padAngle: jsNum(c['padAngle'])!,
      )(values);
      final want = (c['arcs']! as List<Object?>).cast<Map<String, dynamic>>();
      expect(arcs.length, want.length, reason: 'arc count for $values');
      for (var i = 0; i < want.length; i++) {
        expect(arcs[i].index, want[i]['index'], reason: 'arc $i index');
        expect(
          arcs[i].startAngle,
          closeToJs(want[i]['startAngle']),
          reason: 'arc $i startAngle for $values',
        );
        expect(
          arcs[i].endAngle,
          closeToJs(want[i]['endAngle']),
          reason: 'arc $i endAngle for $values',
        );
        expect(
          arcs[i].padAngle,
          closeToJs(want[i]['padAngle']),
          reason: 'arc $i padAngle for $values',
        );
      }
      checked++;
    }
    expect(
      checked,
      5,
      reason:
          "the corpus holds 5 cases with kind == 'pie'; a filter that "
          'silently matched nothing would otherwise pass this test',
    );
  });
}
