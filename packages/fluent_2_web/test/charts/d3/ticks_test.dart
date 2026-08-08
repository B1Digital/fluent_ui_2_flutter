import 'package:fluent_2_web/src/charts/internal/d3/ticks.dart' as d3;
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  test('the constants are sqrt(50), sqrt(10) and sqrt(2)', () {
    expect(d3.e10, 7.0710678118654755, reason: 'd3-array/src/ticks.js:1');
    expect(d3.e5, 3.1622776601683795, reason: 'd3-array/src/ticks.js:2');
    expect(d3.e2, 1.4142135623730951, reason: 'd3-array/src/ticks.js:3');
  });

  test('the fractional branch DIVIDES by a negated inc', () {
    // This is design spec §4.2 risk 3. A port that computes `i * step` with
    // step == 0.1 produces 0.30000000000000004 at the third tick.
    expect(
      d3.ticks(0, 1, 10),
      orderedEquals(<double>[
        0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1,
      ]),
      reason: 'd3-array/src/ticks.js:40 evaluates (i1 + i) / -inc, and 3 / 10 '
          'is exactly 0.3 while 3 * 0.1 is 0.30000000000000004',
    );
    expect(
      3 * 0.1,
      isNot(0.3),
      reason: 'the arithmetic the division avoids',
    );
    expect(
      d3.tickIncrement(0, 1, 10),
      -10.0,
      reason: 'ticks.js:17 stores inc negated in the fractional branch, so the '
          'raw value is a reciprocal and callers must not treat it as a step',
    );
    expect(
      d3.tickStep(0, 1, 10),
      0.1,
      reason: 'ticks.js:54 un-negates it: inc < 0 ? 1 / -inc : inc',
    );
  });

  test('reversed, degenerate and non-positive counts', () {
    expect(
      d3.ticks(1, 0, 10).first,
      1.0,
      reason: 'ticks.js:33,37 walk the reversed spec from i2 downwards',
    );
    expect(d3.ticks(5, 5, 10), <double>[5], reason: 'ticks.js:32');
    expect(d3.ticks(0, 1, 0), isEmpty, reason: 'ticks.js:31, !(count > 0)');
    expect(d3.ticks(0, 1, -1), isEmpty, reason: 'ticks.js:31');
  });

  test('tickSpec retries once for a fractional count below 2', () {
    // ticks.js:25 — `if (i2 < i1 && 0.5 <= count && count < 2)` recurses with
    // count * 2. Without it, ticks(0, 1, 0.5) would be empty.
    expect(
      d3.ticks(0, 1, 0.5),
      isNotEmpty,
      reason: 'the count * 2 retry at d3-array/src/ticks.js:25',
    );
  });

  test('nice loops without a bound, unlike ScaleLinear.nice', () {
    expect(
      d3.nice(0.1, 0.9, 5),
      orderedEquals(<double>[0, 1]),
      reason: 'd3-array/src/nice.js:3-17 has no maxIter; d3-scale/src/linear.js'
          ':29 caps its own copy at 10',
    );
    expect(
      d3.nice(1, 1, 10),
      orderedEquals(<double>[1, 1]),
      reason: 'step is 0 on a degenerate domain, so nice.js:7 returns at once',
    );
  });

  group('against the d3 golden corpus', () {
    test('every ticks/tickIncrement/tickStep/nice case matches exactly',
        () async {
      final corpus = await loadD3Golden();
      final cases = goldenCases(corpus, 'ticks');
      expect(
        cases,
        isNotEmpty,
        reason: 'the corpus must actually have been read',
      );
      for (final c in cases) {
        final start = jsNum(c['start'])!;
        final stop = jsNum(c['stop'])!;
        final count = jsNum(c['count'])!;
        final label = 'ticks($start, $stop, $count)';

        final rawTicks = c['ticks']! as List<Object?>;
        final wantTicks = jsNums(rawTicks);
        final gotTicks = d3.ticks(start, stop, count);
        expect(
          gotTicks.length,
          wantTicks.length,
          reason: '$label tick count',
        );
        for (var i = 0; i < wantTicks.length; i++) {
          expect(
            gotTicks[i],
            closeToJs(rawTicks[i]),
            reason: '$label tick $i must be bit-identical, not close',
          );
        }
        expect(
          d3.tickIncrement(start, stop, count),
          closeToJs(c['tickIncrement']),
          reason: '$label tickIncrement',
        );
        expect(
          d3.tickStep(start, stop, count),
          closeToJs(c['tickStep']),
          reason: '$label tickStep',
        );
        final rawNice = c['nice']! as List<Object?>;
        final wantNice = jsNums(rawNice);
        final gotNice = d3.nice(start, stop, count);
        expect(gotNice[0], closeToJs(rawNice[0]), reason: '$label nice start');
        expect(gotNice[1], closeToJs(rawNice[1]), reason: '$label nice stop');
        expect(wantNice.length, 2, reason: 'nice always returns a pair');
      }
    });
  });
}
