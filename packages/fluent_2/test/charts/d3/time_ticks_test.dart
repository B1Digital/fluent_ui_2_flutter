import 'package:fluent_2/src/charts/internal/d3/time_ticks.dart' as d3;
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  test('the tick interval is chosen by the geometric-mean tiebreak', () {
    final start = DateTime.utc(2024);
    final stop = DateTime.utc(2024, 1, 1, 0, 0, 45);
    // target = 45000 / 10 = 4500 ms. The bisector lands between the 1 s and 5 s
    // rows; ticks.js:48 picks i-1 when target / t[i-1] < t[i] / target, i.e.
    // 4500 / 1000 = 4.5 vs 5000 / 4500 = 1.11 — so it takes row i, the 5 s one.
    final interval = d3.utcTickInterval(start, stop, 10)!;
    expect(
      interval.range(start, stop).length,
      9,
      reason:
          'a 5-second step over 45 seconds, exclusive of the stop '
          '(d3-time/src/ticks.js:48)',
    );
  });

  test('above the ladder it falls through to year.every(tickStep)', () {
    final ticks = d3.utcTicks(DateTime.utc(1900), DateTime.utc(2100), 10);
    expect(
      ticks.first,
      DateTime.utc(1900),
      reason: 'ticks.js:46 — beyond the 18-row table it uses year.every()',
    );
    expect(
      ticks.every((DateTime d) => d.year % 20 == 0),
      isTrue,
      reason: 'tickStep(1900, 2100, 10) is 20 years',
    );
  });

  test('below the ladder it falls through to millisecond.every', () {
    final ticks = d3.utcTicks(
      DateTime.utc(2024),
      DateTime.utc(2024, 1, 1, 0, 0, 0, 5),
      10,
    );
    expect(
      ticks.length,
      6,
      reason:
          'ticks.js:47 — millisecond.every(max(tickStep, 1)) over a 5 ms '
          'span, with the stop made inclusive at ticks.js:39',
    );
  });

  test('a reversed span comes back reversed', () {
    final forward = d3.utcTicks(
      DateTime.utc(2024),
      DateTime.utc(2024, 1, 8),
      7,
    );
    final reverse = d3.utcTicks(
      DateTime.utc(2024, 1, 8),
      DateTime.utc(2024),
      7,
    );
    expect(
      reverse,
      orderedEquals(forward.reversed.toList()),
      reason: 'ticks.js:36-40',
    );
  });

  test('the two-day row strides across a month boundary', () {
    // target = 31 days / 18 = 1.72 days, which the tiebreak resolves to the
    // 2-day row (ticks.js:28). The UTC ladder passes `unixDay`, not `utcDay`
    // (ticks.js:55), so the stride is counted from the epoch and does not
    // restart in February. Verified against the pinned module:
    // `utcTicks(2024-01-01, 2024-02-01, 18)`.
    expect(
      d3
          .utcTicks(DateTime.utc(2024), DateTime.utc(2024, 2), 18)
          .map((DateTime d) => d.toIso8601String())
          .toList(),
      orderedEquals(<String>[
        for (int day = 2; day <= 30; day += 2)
          DateTime.utc(2024, 1, day).toIso8601String(),
        DateTime.utc(2024, 2).toIso8601String(),
      ]),
      reason:
          'unixDay.every(2) tests floor(date / durationDay) '
          '(d3-time/src/day.js:32); utcDay.every(2) would emit the 31st of '
          'January instead of the 30th',
    );
  });

  test('against the d3 golden corpus', () async {
    final corpus = await loadD3Golden();
    for (final c in goldenCases(corpus, 'timeTicks')) {
      final start = DateTime.fromMillisecondsSinceEpoch(
        c['start']! as int,
        isUtc: true,
      );
      final stop = DateTime.fromMillisecondsSinceEpoch(
        c['stop']! as int,
        isUtc: true,
      );
      expect(
        d3
            .utcTicks(start, stop, c['count']! as int)
            .map((DateTime d) => d.millisecondsSinceEpoch)
            .toList(),
        orderedEquals((c['utcTicks']! as List<Object?>).cast<int>()),
        reason: 'utcTicks($start, $stop, ${c['count']})',
      );
    }
  });
}
