import 'package:fluent_2_web/src/charts/internal/d3/shape_stack.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  test('series accumulate, and a NaN carries the previous lo instead', () {
    final rows = <Map<String, double>>[
      <String, double>{'a': 1, 'b': 2},
      <String, double>{'a': double.nan, 'b': 2},
    ];
    final series = stack(
      rows,
      <String>['a', 'b'],
      value: (Object d, String key) =>
          (d as Map<String, double>)[key] ?? double.nan,
    );
    expect(series[1][0].lo, 1.0, reason: 'offset/none.js:6, the normal carry');
    expect(
      series[1][1].lo,
      0.0,
      reason:
          'offset/none.js:6 — `isNaN(s0[j][1]) ? s0[j][0] : s0[j][1]`, so '
          "a NaN top falls back to the previous series' BOTTOM",
    );
  });

  test('each point keeps a back-reference to its row', () {
    final rows = <Map<String, double>>[
      <String, double>{'a': 1},
    ];
    final series = stack(rows, <String>[
      'a',
    ], value: (Object d, String key) => (d as Map<String, double>)[key]!);
    expect(
      identical(series[0][0].data, rows[0]),
      isTrue,
      reason:
          'stack.js:29 attaches .data, and AreaChart.tsx:317-319 reads '
          'd.data.xVal off it',
    );
  });

  test('against the d3 golden corpus', () async {
    final corpus = await loadD3Golden();
    final rows = <Map<String, double>>[
      <String, double>{'x': 0, 'a': 1, 'b': 2, 'c': 3},
      <String, double>{'x': 1, 'a': 4, 'b': 0, 'c': 1},
      <String, double>{'x': 2, 'a': double.nan, 'b': 2, 'c': 2},
    ];
    for (final c in goldenCases(corpus, 'shape')) {
      if (c['kind'] != 'stack') {
        continue;
      }
      final series = stack(
        rows,
        (c['keys']! as List<Object?>).cast<String>(),
        value: (Object d, String key) =>
            (d as Map<String, double>)[key] ?? double.nan,
      );
      final want = c['series']! as List<Object?>;
      for (var s = 0; s < want.length; s++) {
        final points = want[s]! as List<Object?>;
        for (var p = 0; p < points.length; p++) {
          final pair = jsNums(points[p]);
          expect(
            series[s][p].lo,
            closeToJs(
              pair[0] == null ? null : (points[p]! as List<Object?>)[0],
            ),
            reason: 'series $s point $p lo',
          );
          expect(
            series[s][p].hi,
            closeToJs((points[p]! as List<Object?>)[1]),
            reason: 'series $s point $p hi',
          );
        }
      }
    }
  });
}
