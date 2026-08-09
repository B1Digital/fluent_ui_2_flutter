import 'package:fluent_2_web/src/charts/internal/d3/scale_tick_format.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  test('the default specifier is ",f"', () {
    expect(
      scaleTickFormat(0, 1, 10)(0.3),
      '0.3',
      reason:
          'd3-scale/src/tickFormat.js:7 defaults to ",f" and :24 then '
          'sets the precision from precisionFixed(tickStep)',
    );
    expect(
      scaleTickFormat(0, 1e6, 5)(500000),
      '500,000',
      reason: 'the comma of ",f" groups by thousands',
    );
  });

  test('the "e" type loses one precision', () {
    expect(
      scaleTickFormat(0, 1000, 5, 'e')(250),
      '3e+2',
      // tickStep(0, 1000, 5) is 200, so precisionRound(200, 1000) is 1 and
      // :19 takes one off for the "e" type, leaving no fractional digit at
      // all: 2.5e+2 rounds up to 3e+2. Verified against the pinned
      // d3-scale — `tickFormat(0, 1000, 5, 'e')(250)` answers "3e+2".
      reason: 'tickFormat.js:19 subtracts 1 for the e type',
    );
  });

  test('the "%" type loses two', () {
    expect(
      scaleTickFormat(0, 1, 10, '%')(0.3),
      '30%',
      reason: 'tickFormat.js:24 subtracts 2 for the % type',
    );
  });

  test('the "s" type routes through formatPrefix at the larger endpoint', () {
    expect(
      scaleTickFormat(0, 1e6, 5, 's')(500000),
      '0.5M',
      // :10 picks the prefix from max(|0|, |1e6|) = 1e6, which is the mega
      // group, so every label is expressed in millions — not the kilo prefix
      // the value alone would suggest. Verified against the pinned d3-scale.
      reason:
          'tickFormat.js:9-13 picks the SI prefix from max(|start|, |stop|)',
    );
  });

  test('against the d3 golden corpus', () async {
    final corpus = await loadD3Golden();
    for (final c in goldenCases(corpus, 'scaleTickFormat')) {
      final f = scaleTickFormat(
        jsNum(c['start'])!,
        jsNum(c['stop'])!,
        c['count']! as int,
        c['specifier'] as String?,
      );
      final values = jsNums(c['values']);
      final want = (c['out']! as List<Object?>).cast<String>();
      for (var i = 0; i < values.length; i++) {
        expect(
          f(values[i]!),
          want[i],
          reason:
              'scaleTickFormat(${c['start']}, ${c['stop']}, ${c['count']}, '
              '${c['specifier']}) applied to ${values[i]}',
        );
      }
    }
  });
}
