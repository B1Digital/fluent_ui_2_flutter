import 'dart:math' as math;

import 'array_stats.dart' as array;
import 'ticks.dart' as numeric;
import 'time_interval.dart';

/// One row of the tick ladder: the interval, the step, and the step's length
/// in milliseconds (`d3-time/src/ticks.js:14-33`).
typedef _Row = (TimeInterval interval, int step, int millis);

/// `unixDay` (`d3-time/src/day.js:25-33`) — UTC midnights, but counted in whole
/// days since the epoch rather than in days of the month.
///
/// This is the interval the UTC ladder passes as its `day` (`ticks.js:55`), and
/// it is not [utcDay]: the two differ only in their field, and therefore only
/// in [TimeInterval.every]. `utcDay.every(2)` tests `date - 1` and so restarts
/// its stride in every month — over January 2024 it would emit the 29th, the
/// 31st and then the 1st of February, a one-day gap. `unixDay.every(2)` tests
/// `floor(date / durationDay)` and strides evenly across the boundary, which is
/// what d3 emits: the 30th, then the 1st.
///
/// It lives here rather than in `time_interval.dart` because the tick ladder is
/// its only upstream consumer.
final TimeInterval _unixDay = TimeInterval(
  utcDay.floor,
  utcDay.offset,
  // day.js:29-31 — a UTC day is always exactly `durationDay` milliseconds, so
  // no timezone-offset correction is needed as it is in `timeDay`.
  (DateTime start, DateTime end) =>
      (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) / durationDay,
  // day.js:32 — whole days since the epoch, floored so that instants before it
  // count downwards.
  (DateTime date) => (date.millisecondsSinceEpoch / durationDay).floor(),
);

List<_Row> _ladder(
  TimeInterval year,
  TimeInterval month,
  TimeInterval week,
  TimeInterval day,
  TimeInterval hour,
  TimeInterval minute,
) => <_Row>[
  // Every multiplier below is the literal second column of `ticks.js:14-33`.
  (second, 1, durationSecond),
  (second, 5, 5 * durationSecond),
  (second, 15, 15 * durationSecond),
  (second, 30, 30 * durationSecond),
  (minute, 1, durationMinute),
  (minute, 5, 5 * durationMinute),
  (minute, 15, 15 * durationMinute),
  (minute, 30, 30 * durationMinute),
  (hour, 1, durationHour),
  (hour, 3, 3 * durationHour),
  (hour, 6, 6 * durationHour),
  (hour, 12, 12 * durationHour),
  (day, 1, durationDay),
  (day, 2, 2 * durationDay),
  (week, 1, durationWeek),
  (month, 1, durationMonth),
  (month, 3, 3 * durationMonth),
  (year, 1, durationYear),
];

TimeInterval? _tickInterval(
  List<_Row> rows,
  TimeInterval year,
  DateTime start,
  DateTime stop,
  int count,
) {
  final startMs = start.millisecondsSinceEpoch;
  final stopMs = stop.millisecondsSinceEpoch;
  final target = (stopMs - startMs).abs() / count;
  final bisect = array.bisector<_Row>((_Row row) => row.$3);
  final i = bisect.right(rows, target);
  if (i == rows.length) {
    // ticks.js:46 — beyond the ladder, step in whole years. Upstream leaves the
    // fractional step to `year.every`, which floors it (`year.js:15`); over a
    // span this long `tickStep` only ever returns a whole number, so rounding
    // and flooring agree.
    return year.every(
      numeric
          .tickStep(
            startMs / durationYear,
            stopMs / durationYear,
            count.toDouble(),
          )
          .round(),
    );
  }
  if (i == 0) {
    // ticks.js:47 — below the ladder, step in whole milliseconds. 1 is the
    // floor upstream clamps to, since a sub-millisecond step has no meaning.
    return millisecond.every(
      math
          .max(
            numeric.tickStep(
              startMs.toDouble(),
              stopMs.toDouble(),
              count.toDouble(),
            ),
            1,
          )
          .round(),
    );
  }
  // ticks.js:48 — the geometric-mean tiebreak between the two straddling rows.
  // 1 is subtracted to reach the row below the insertion point.
  final row = rows[target / rows[i - 1].$3 < rows[i].$3 / target ? i - 1 : i];
  return row.$1.every(row.$2);
}

List<DateTime> _ticks(
  List<_Row> rows,
  TimeInterval year,
  DateTime start,
  DateTime stop,
  int count,
) {
  final reverse = stop.isBefore(start);
  final lo = reverse ? stop : start;
  final hi = reverse ? start : stop;
  final interval = _tickInterval(rows, year, lo, hi, count);
  final result = interval == null
      ? <DateTime>[]
      : interval.range(
          lo,
          DateTime.fromMillisecondsSinceEpoch(
            // ticks.js:39 — 1 millisecond makes the exclusive stop inclusive.
            hi.millisecondsSinceEpoch + 1,
            isUtc: hi.isUtc,
          ),
        );
  return reverse ? result.reversed.toList() : result;
}

final List<_Row> _local = _ladder(
  timeYear,
  timeMonth,
  timeSunday,
  timeDay,
  timeHour,
  timeMinute,
);
final List<_Row> _utc = _ladder(
  utcYear,
  utcMonth,
  utcSunday,
  _unixDay,
  utcHour,
  utcMinute,
);

/// Roughly [count] local-time ticks spanning `[start, stop]`
/// (`d3-time/src/ticks.js:35-41`).
List<DateTime> timeTicks(DateTime start, DateTime stop, int count) =>
    _ticks(_local, timeYear, start, stop, count);

/// The interval [timeTicks] would use (`d3-time/src/ticks.js:43-50`).
TimeInterval? timeTickInterval(DateTime start, DateTime stop, int count) =>
    _tickInterval(_local, timeYear, start, stop, count);

/// Roughly [count] UTC ticks spanning `[start, stop]`.
List<DateTime> utcTicks(DateTime start, DateTime stop, int count) =>
    _ticks(_utc, utcYear, start, stop, count);

/// The interval [utcTicks] would use.
TimeInterval? utcTickInterval(DateTime start, DateTime stop, int count) =>
    _tickInterval(_utc, utcYear, start, stop, count);
