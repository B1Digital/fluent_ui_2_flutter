import 'package:fluent_2/src/charts/internal/d3/bin.dart' as d3;
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  const values = <double>[0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55];

  test('a count threshold produces uniform bins over the given domain', () {
    final bins = (d3.bin()
      ..domain(0, 60)
      ..thresholdCount(
        6,
      ))(values.cast<Object>(), value: (Object d) => d as double);
    expect(bins.first.x0, 0.0, reason: 'd3-array/src/bin.js:81');
    expect(bins.last.x1, 60.0, reason: 'bin.js:82');
    expect(
      bins.fold<int>(0, (int a, d3.Bin b) => a + b.values.length),
      values.length,
      reason: 'every value is inside [0, 60] so none is dropped (bin.js:89)',
    );
  });

  test('an explicit threshold list is respected and trimmed to the domain', () {
    final bins = (d3.bin()
      ..domain(0, 40)
      ..thresholdsList(<double>[
        0,
        10,
        20,
        30,
      ]))(values.cast<Object>(), value: (Object d) => d as double);
    expect(
      bins.length,
      4,
      reason:
          'bin.js:71 drops the leading threshold that equals x0, leaving '
          'three interior cuts and therefore four bins',
    );
  });

  test('values outside the domain are dropped', () {
    final bins = (d3.bin()
      ..domain(0, 10)
      ..thresholdCount(
        2,
      ))(<Object>[-5, 5, 50], value: (Object d) => (d as num).toDouble());
    expect(
      bins.fold<int>(0, (int a, d3.Bin b) => a + b.values.length),
      1,
      reason: 'bin.js:89 keeps only x0 <= x <= x1',
    );
  });

  test('against the d3 golden corpus', () async {
    final corpus = await loadD3Golden();
    for (final c in goldenCases(corpus, 'bin')) {
      final domain = jsNums(c['domain']).cast<double>();
      final binner = d3.bin()..domain(domain[0], domain[1]);
      if (c.containsKey('thresholdList')) {
        binner.thresholdsList(jsNums(c['thresholdList']).cast<double>());
      } else {
        binner.thresholdCount(c['thresholds']! as int);
      }
      final bins = binner(
        jsNums(c['values']).cast<double>().cast<Object>(),
        value: (Object d) => d as double,
      );
      final want = (c['bins']! as List<Object?>).cast<Map<String, dynamic>>();
      expect(bins.length, want.length, reason: 'bin count for ${c['domain']}');
      for (var i = 0; i < want.length; i++) {
        expect(bins[i].x0, closeToJs(want[i]['x0']), reason: 'bin $i x0');
        expect(bins[i].x1, closeToJs(want[i]['x1']), reason: 'bin $i x1');
        expect(
          bins[i].values.length,
          (want[i]['values']! as List<Object?>).length,
          reason: 'bin $i membership',
        );
      }
    }
  });
}
