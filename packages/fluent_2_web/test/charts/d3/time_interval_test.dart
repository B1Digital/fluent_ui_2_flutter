import 'package:fluent_2_web/src/charts/internal/d3/time_interval.dart' as d3;
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  DateTime utc(
    int y, [
    int m = 1,
    int d = 1,
    int h = 0,
    int mi = 0,
    int s = 0,
    int ms = 0,
  ]) => DateTime.utc(y, m, d, h, mi, s, ms);

  test('the duration constants', () {
    expect(d3.durationSecond, 1000, reason: 'd3-time/src/duration.js:1');
    expect(d3.durationMinute, 60000, reason: 'duration.js:2');
    expect(d3.durationHour, 3600000, reason: 'duration.js:3');
    expect(d3.durationDay, 86400000, reason: 'duration.js:4');
    expect(d3.durationWeek, 604800000, reason: 'duration.js:5');
    expect(
      d3.durationMonth,
      2592000000,
      reason:
          'duration.js:6 is durationDay * 30 — a nominal month, not a real '
          'one, and the tick ladder depends on the nominal value',
    );
    expect(d3.durationYear, 31536000000, reason: 'duration.js:7, 365 days');
  });

  test('ceil floors the instant before, offsets, then floors again', () {
    expect(
      d3.utcDay.ceil(utc(2024)),
      utc(2024),
      reason:
          'interval.js:14 — an instant already on the boundary is its own '
          'ceiling because it floors `date - 1` first',
    );
    expect(
      d3.utcDay.ceil(utc(2024, 1, 1, 0, 0, 0, 1)),
      utc(2024, 1, 2),
      reason: 'interval.js:14',
    );
  });

  test('round breaks its tie upwards', () {
    expect(
      d3.utcDay.round(utc(2024, 1, 1, 12)),
      utc(2024, 1, 2),
      reason:
          'interval.js:19 is `date - d0 < d1 - date ? d0 : d1`, and at '
          'exactly midday the strict < is false — d0 is returned only when '
          'the distance is strictly smaller, so midday rounds UP to d1. '
          'Verified against the pinned module: '
          'd3.utcDay.round(Date.UTC(2024, 0, 1, 12)) is 2024-01-02T00:00:00Z',
    );
    expect(
      d3.utcDay.round(utc(2024, 1, 1, 11, 59)),
      utc(2024),
      reason: 'interval.js:19',
    );
  });

  test('range is half-open and starts from the ceiling', () {
    expect(
      d3.utcDay.range(utc(2024, 1, 1, 6), utc(2024, 1, 4)),
      <DateTime>[utc(2024, 1, 2), utc(2024, 1, 3)],
      reason: 'interval.js:27-34 ceils the start and excludes the stop',
    );
    expect(
      d3.utcDay.range(utc(2024, 1, 4), utc(2024)),
      isEmpty,
      reason: 'interval.js:30, !(start < stop)',
    );
    expect(
      d3.utcDay.range(utc(2024), utc(2024, 1, 4), 0),
      isEmpty,
      reason: 'interval.js:30, !(step > 0)',
    );
  });

  test('every(k) filters, and every(k) of a non-positive k is null', () {
    expect(
      d3.utcYear.every(0),
      isNull,
      reason: 'interval.js:60 / year.js:16 return null for k <= 0',
    );
    final every5 = d3.utcYear.every(5)!;
    expect(
      every5.floor(utc(2023, 7, 4)),
      utc(2020),
      reason: 'year.js:17 floors the year to a multiple of k',
    );
    expect(
      d3.utcYear.every(1),
      same(d3.utcYear),
      reason: 'interval.js:61, !(step > 1) returns the interval itself',
    );
  });

  test('a filtered interval offsets by whole filtered steps', () {
    // interval.js:42-46 uses PRE-increment: `while (++step <= 0)` and
    // `while (--step >= 0)` each run |step| times, not |step| + 1. A port
    // written with Dart's postfix `step++` overshoots by one whole step, and
    // these three values are what the pinned module returns.
    final quarter = d3.utcMonth.every(3)!;
    expect(
      quarter.floor(utc(2024, 2, 15)),
      utc(2024),
      reason:
          'interval.js:39 floors, then walks back a millisecond at a time '
          'until the month index is a multiple of 3',
    );
    expect(
      quarter.offset(utc(2024, 2, 15), 1),
      utc(2024, 4, 15),
      reason: 'interval.js:44-45, one step forward from February is April',
    );
    expect(
      quarter.offset(utc(2024, 2, 15), 2),
      utc(2024, 7, 15),
      reason: 'interval.js:44-45, two steps forward is July',
    );
    expect(
      quarter.offset(utc(2024, 2, 15), -1),
      utc(2024, 1, 15),
      reason: 'interval.js:42-43, one step back from February is January',
    );
    expect(
      quarter.count(utc(2020), utc(2024)),
      isNull,
      reason:
          'interval.js:48 builds the filtered interval WITHOUT a counter, so '
          'd3 exposes neither count nor every on it',
    );
    expect(
      quarter.every(2),
      isNull,
      reason: 'interval.js:51-66 only defines every when a counter exists',
    );
  });

  test('local intervals honour the running zone, DST included', () {
    // The corpus carries UTC only — a committed local vector would fail on any
    // machine in another zone (see test/charts/d3/README.md).
    final noon = DateTime(2024, 6, 15, 12, 30, 45, 678);
    expect(
      d3.timeDay.floor(noon),
      DateTime(2024, 6, 15),
      reason: 'day.js:5 is setHours(0, 0, 0, 0) in LOCAL time',
    );
    expect(
      d3.timeDay.floor(noon).hour,
      0,
      reason:
          'a DST-shifted local midnight must still report hour 0; if the '
          'zone has no midnight that day, d3 steps back an hour',
    );
    expect(d3.timeMonth.floor(noon), DateTime(2024, 6), reason: 'month.js:4-5');
    expect(
      d3.timeWeek.floor(DateTime(2024, 6, 15)),
      DateTime(2024, 6, 9),
      reason:
          'week.js:6 floors to the preceding Sunday; 2024-06-15 is a '
          'Saturday, so the Sunday is the 9th',
    );
    expect(
      d3.timeWeek,
      same(d3.timeSunday),
      reason: 'd3-time/src/index.js exports timeWeek as timeSunday',
    );
    expect(
      d3.utcWeek,
      same(d3.utcSunday),
      reason: 'd3-time/src/index.js exports utcWeek as utcSunday',
    );
  });

  test('against the d3 golden corpus (UTC only)', () async {
    final corpus = await loadD3Golden();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final intervals = <String, d3.TimeInterval>{
      'millisecond': d3.millisecond,
      'second': d3.second,
      'minute': d3.utcMinute,
      'hour': d3.utcHour,
      'day': d3.utcDay,
      'week': d3.utcSunday,
      'month': d3.utcMonth,
      'year': d3.utcYear,
    };
    for (final c in goldenCases(corpus, 'timeInterval')) {
      final interval = intervals[c['interval']]!;
      if (c.containsKey('range')) {
        final from = DateTime.fromMillisecondsSinceEpoch(
          c['rangeFrom']! as int,
          isUtc: true,
        );
        final to = DateTime.fromMillisecondsSinceEpoch(
          c['rangeTo']! as int,
          isUtc: true,
        );
        final source = c['every'] != null
            ? interval.every(c['every']! as int)!
            : interval;
        expect(
          source.range(from, to).map((DateTime d) => d.millisecondsSinceEpoch),
          orderedEquals((c['range']! as List<Object?>).cast<int>()),
          reason: '${c['interval']}.range($from, $to)',
        );
        continue;
      }
      final input = DateTime.fromMillisecondsSinceEpoch(
        c['input']! as int,
        isUtc: true,
      );
      expect(
        interval.floor(input).millisecondsSinceEpoch,
        c['floor'],
        reason: '${c['interval']}.floor($input)',
      );
      expect(
        interval.ceil(input).millisecondsSinceEpoch,
        c['ceil'],
        reason: '${c['interval']}.ceil($input)',
      );
      expect(
        interval.round(input).millisecondsSinceEpoch,
        c['round'],
        reason: '${c['interval']}.round($input)',
      );
      expect(
        interval.offset(input, 3).millisecondsSinceEpoch,
        c['offset3'],
        reason: '${c['interval']}.offset($input, 3)',
      );
      expect(
        interval.offset(input, -2).millisecondsSinceEpoch,
        c['offsetMinus2'],
        reason: '${c['interval']}.offset($input, -2)',
      );
      // The generator records interval.count(new Date(0), input), which floors
      // BOTH ends (interval.js:53-55) — utcSunday.count therefore starts from
      // 1969-12-28, not from the epoch.
      expect(
        interval.count(epoch, input),
        c['count'],
        reason: '${c['interval']}.count(epoch, $input)',
      );
    }
  });
}
