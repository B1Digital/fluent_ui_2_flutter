import 'package:fluent_2_web/src/charts/internal/d3/scale_time.dart';
import 'package:fluent_2_web/src/charts/internal/d3/time_interval.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

/// Rebuilds the scale for one corpus case. `nice` mutates the domain in place,
/// so the `niced` assertion needs its own instance.
ScaleTime _scaleFor(List<DateTime> domain) => scaleUtc()
  ..domainOfDates(domain)
  ..rangeOf(<double>[0, 600]);

void main() {
  test('the default domain is 2000-01-01 to 2000-01-02', () {
    expect(
      scaleTime().domain.cast<DateTime>().first,
      DateTime(2000),
      reason: 'd3-scale/src/time.js:70',
    );
  });

  test('a DateTime maps and inverts back to a DateTime', () {
    final s = scaleUtc()
      ..domainOfDates(<DateTime>[DateTime.utc(2024), DateTime.utc(2024, 1, 2)])
      ..rangeOf(<double>[0, 600]);
    expect(
      s(DateTime.utc(2024, 1, 1, 12)),
      300.0,
      reason: 'time.js:44 coerces each Date to its epoch milliseconds',
    );
    expect(
      s.invert(300),
      DateTime.utc(2024, 1, 1, 12),
      reason: 'time.js:39-41 wraps the numeric invert back into a Date',
    );
  });

  test('the multi-level default tick format', () {
    final s = scaleUtc()
      ..domainOfDates(<DateTime>[DateTime.utc(2024), DateTime.utc(2025)]);
    final f = s.tickFormat();
    expect(
      f(DateTime.utc(2024, 3)),
      'March',
      reason:
          'time.js:29-37 — a month boundary inside a year takes formatMonth',
    );
    expect(
      f(DateTime.utc(2024)),
      '2024',
      reason: 'a year boundary takes formatYear',
    );
  });

  test('nice takes an interval or a count', () {
    final s = scaleUtc()
      ..domainOfDates(<DateTime>[
        DateTime.utc(2024, 1, 1, 6, 30),
        DateTime.utc(2024, 1, 3, 17, 15),
      ]);
    s.nice();
    // DEVIATION from plan 01 Task 21 Step 1, which expected 2024-01-01T00:00Z.
    // The span is 2.45 days, so time.js:58 picks `utcHour.every(6)` for ten
    // ticks and floors 06:30 to 06:00 — not to midnight. Verified against the
    // pinned module: `d3.scaleUtc().domain([...]).nice().domain()` returns
    // ['2024-01-01T06:00:00.000Z', '2024-01-03T18:00:00.000Z'].
    expect(
      s.domain.cast<DateTime>(),
      <DateTime>[DateTime.utc(2024, 1, 1, 6), DateTime.utc(2024, 1, 3, 18)],
      reason: 'time.js:56-60 nices through the chosen tick interval',
    );
    // utcDay is an explicit interval, so time.js:58 skips tickInterval.
    final byInterval = scaleUtc()
      ..domainOfDates(<DateTime>[
        DateTime.utc(2024, 1, 1, 6, 30),
        DateTime.utc(2024, 1, 3, 17, 15),
      ])
      ..nice(utcDay);
    expect(
      byInterval.domain.cast<DateTime>(),
      <DateTime>[DateTime.utc(2024), DateTime.utc(2024, 1, 4)],
      reason: 'an explicit interval floors and ceils to whole days',
    );
  });

  test('against the d3 golden corpus', () async {
    final corpus = await loadD3Golden();
    for (final c in goldenCases(corpus, 'scaleTime')) {
      final domain = (c['domain']! as List<Object?>)
          .cast<int>()
          .map((int t) => DateTime.fromMillisecondsSinceEpoch(t, isUtc: true))
          .toList();
      final s = _scaleFor(domain);
      final inputs = (c['atInputs']! as List<Object?>).cast<num>();
      final at = c['at']! as List<Object?>;
      for (var i = 0; i < inputs.length; i++) {
        expect(
          s(
            DateTime.fromMillisecondsSinceEpoch(inputs[i].round(), isUtc: true),
          ),
          closeToJs(at[i]),
          reason: 'scaleUtc $domain at ${inputs[i]}',
        );
      }
      final wantInvert = (c['invert']! as List<Object?>).cast<int>();
      // [0, 300, 600] are the pixels `crawlers/d3-golden/generate.mjs:362`
      // inverted, matching the [0, 600] range above.
      const pixels = <double>[0, 300, 600];
      for (var i = 0; i < pixels.length; i++) {
        expect(
          s.invert(pixels[i])!.millisecondsSinceEpoch,
          wantInvert[i],
          reason: 'invert(${pixels[i]}) over $domain',
        );
      }
      expect(
        s.ticks().cast<DateTime>().map(
          (DateTime d) => d.millisecondsSinceEpoch,
        ),
        orderedEquals((c['ticks']! as List<Object?>).cast<int>()),
        reason: 'ticks() over $domain',
      );
      expect(
        s
            .ticks(4)
            .cast<DateTime>()
            .map((DateTime d) => d.millisecondsSinceEpoch),
        orderedEquals((c['ticks4']! as List<Object?>).cast<int>()),
        reason: 'ticks(4) over $domain',
      );
      final f = s.tickFormat();
      final want = (c['tickFormat']! as List<Object?>).cast<String>();
      final ticks = s.ticks();
      for (var i = 0; i < want.length; i++) {
        expect(f(ticks[i]), want[i], reason: 'tickFormat() of tick $i');
      }
      expect(
        _scaleFor(domain).nice().domain.cast<DateTime>().map(
          (DateTime d) => d.millisecondsSinceEpoch,
        ),
        orderedEquals((c['niced']! as List<Object?>).cast<int>()),
        reason: 'nice() over $domain',
      );
    }
  });
}
