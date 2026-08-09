/// One second in milliseconds (`d3-time/src/duration.js:1`).
const int durationSecond = 1000;

/// One minute in milliseconds (`d3-time/src/duration.js:2`).
const int durationMinute = durationSecond * 60;

/// One hour in milliseconds (`d3-time/src/duration.js:3`).
const int durationHour = durationMinute * 60;

/// One day in milliseconds (`d3-time/src/duration.js:4`).
const int durationDay = durationHour * 24;

/// One week in milliseconds (`d3-time/src/duration.js:5`).
const int durationWeek = durationDay * 7;

/// A *nominal* month, 30 days (`d3-time/src/duration.js:6`). The tick ladder in
/// `time_ticks.dart` compares against this, not against a calendar month.
const int durationMonth = durationDay * 30;

/// A *nominal* year, 365 days (`d3-time/src/duration.js:7`).
const int durationYear = durationDay * 365;

/// Truncates a date to the start of its interval.
///
/// d3 mutates the `Date` in place; Dart's `DateTime` is immutable, so this
/// returns the floored value instead. Only this file constructs one.
typedef TimeFloor = DateTime Function(DateTime date);

/// Shifts a date by whole intervals. Returns the shifted value for the same
/// reason as [TimeFloor].
typedef TimeOffset = DateTime Function(DateTime date, int step);

/// A repeating unit of time (`d3-time/src/interval.js:3-68`).
class TimeInterval {
  /// Creates an interval from its flooring and offsetting rules. The third
  /// argument, the counter, is what enables [count] and [every]; the fourth,
  /// the field, gives [every] a cheap modulo test instead of a count.
  TimeInterval(this._floori, this._offseti, [this._counti, this._field]);

  final TimeFloor _floori;
  final TimeOffset _offseti;
  final double Function(DateTime start, DateTime end)? _counti;
  final num Function(DateTime date)? _field;

  /// The largest interval boundary at or before [date]
  /// (`d3-time/src/interval.js:9-11`).
  DateTime floor(DateTime date) => _floori(date);

  /// The smallest interval boundary at or after [date]
  /// (`d3-time/src/interval.js:13-15`).
  ///
  /// d3 floors `date - 1` first, offsets by one, then floors again — so an
  /// instant already on a boundary is its own ceiling.
  DateTime ceil(DateTime date) => _floori(
    _offseti(_floori(date.subtract(const Duration(milliseconds: 1))), 1),
  );

  /// The nearer of [floor] and [ceil] (`d3-time/src/interval.js:17-20`).
  ///
  /// The comparison is strict, so an exact midpoint rounds **up**.
  DateTime round(DateTime date) {
    final d0 = floor(date);
    final d1 = ceil(date);
    final toStart = date.difference(d0).inMicroseconds;
    final toEnd = d1.difference(date).inMicroseconds;
    return toStart < toEnd ? d0 : d1;
  }

  /// [date] shifted by [step] intervals, without flooring
  /// (`d3-time/src/interval.js:22-24`).
  DateTime offset(DateTime date, [int step = 1]) => _offseti(date, step);

  /// Every boundary in `[start, stop)` (`d3-time/src/interval.js:26-35`).
  List<DateTime> range(DateTime start, DateTime stop, [int step = 1]) {
    final result = <DateTime>[];
    var current = ceil(start);
    if (!current.isBefore(stop) || step <= 0) {
      return result;
    }
    DateTime previous;
    do {
      previous = current;
      result.add(current);
      current = _floori(_offseti(current, step));
    } while (previous.isBefore(current) && current.isBefore(stop));
    return result;
  }

  /// Whole intervals between [start] and [end], or `null` when this interval
  /// has no counter (`d3-time/src/interval.js:52-56`).
  ///
  /// Both ends are floored first, so `utcSunday.count` of the epoch starts from
  /// 1969-12-28 rather than from 1970-01-01.
  int? count(DateTime start, DateTime end) {
    final counter = _counti;
    if (counter == null) {
      return null;
    }
    return counter(_floori(start), _floori(end)).floor();
  }

  /// Every [step]th boundary of this interval, or `null` when [step] is not
  /// positive or this interval has no counter
  /// (`d3-time/src/interval.js:58-65`).
  TimeInterval? every(int step) {
    if (_counti == null || step <= 0) {
      return null;
    }
    if (step == 1) {
      return this;
    }
    final field = _field;
    // interval.js:62-64 prefers the field test; without one it counts from the
    // epoch, in whichever zone the date being tested carries.
    return filter(
      field != null
          ? (DateTime d) => field(d) % step == 0
          : (DateTime d) =>
                count(
                      DateTime.fromMillisecondsSinceEpoch(0, isUtc: d.isUtc),
                      d,
                    )! %
                    step ==
                0,
    );
  }

  /// The sub-interval whose boundaries satisfy [test]
  /// (`d3-time/src/interval.js:37-49`).
  ///
  /// The result carries no counter, exactly as upstream (`interval.js:48` calls
  /// `timeInterval` with two arguments), so its [count] and [every] are unusable.
  TimeInterval filter(bool Function(DateTime date) test) => TimeInterval(
    (DateTime date) {
      var d = _floori(date);
      while (!test(d)) {
        d = _floori(d.subtract(const Duration(milliseconds: 1)));
      }
      return d;
    },
    (DateTime date, int step) {
      var d = date;
      var remaining = step;
      // interval.js:42-46 uses PRE-increment, so each loop runs |step| times.
      // Dart's postfix form would run |step| + 1 times and overshoot by a
      // whole interval.
      if (remaining < 0) {
        while (++remaining <= 0) {
          do {
            d = _offseti(d, -1);
          } while (!test(d));
        }
      } else {
        while (--remaining >= 0) {
          do {
            d = _offseti(d, 1);
          } while (!test(d));
        }
      }
      return d;
    },
  );
}

DateTime _shiftMs(DateTime date, int ms) => DateTime.fromMillisecondsSinceEpoch(
  date.millisecondsSinceEpoch + ms,
  isUtc: date.isUtc,
);

/// Builds a local `DateTime` and steps back one hour if the calendar arithmetic
/// jumped forward over a DST gap.
///
/// d3 relies on `Date.prototype.setHours` doing this; Dart's `DateTime`
/// constructor picks *a* valid instant instead, which can land after the input.
DateTime _localFloor(DateTime candidate, DateTime input) {
  if (candidate.isAfter(input)) {
    return candidate.subtract(const Duration(hours: 1));
  }
  return candidate;
}

/// Milliseconds — the finest interval (`d3-time/src/millisecond.js:3-9`).
///
/// d3 also ships an optimised `millisecond.every`
/// (`d3-time/src/millisecond.js:12-23`); this port leaves the generic
/// [TimeInterval.every] in place. Both pick the same boundaries — the multiples
/// of `k` — so [TimeInterval.floor], [TimeInterval.ceil] and
/// [TimeInterval.range] agree; only [TimeInterval.offset] from an instant that
/// is *not* already a boundary differs, and no caller in this port does that.
final TimeInterval millisecond = TimeInterval(
  (DateTime date) => date,
  _shiftMs,
  (DateTime start, DateTime end) =>
      (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch).toDouble(),
);

/// Seconds. d3 exports one instance for both zones, because a second boundary
/// is zone-independent (`d3-time/src/second.js:4-12`, and `utcSecond` is an
/// alias of it in `d3-time/src/index.js`).
final TimeInterval second = TimeInterval(
  (DateTime date) => _shiftMs(date, -date.millisecond),
  (DateTime date, int step) => _shiftMs(date, step * durationSecond),
  (DateTime start, DateTime end) =>
      (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) /
      durationSecond,
  (DateTime date) => date.second,
);

/// Local minutes (`d3-time/src/minute.js:4-12`).
final TimeInterval timeMinute = TimeInterval(
  (DateTime date) =>
      _shiftMs(date, -date.millisecond - date.second * durationSecond),
  (DateTime date, int step) => _shiftMs(date, step * durationMinute),
  (DateTime start, DateTime end) =>
      (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) /
      durationMinute,
  (DateTime date) => date.minute,
);

/// Local hours (`d3-time/src/hour.js:4-12`).
final TimeInterval timeHour = TimeInterval(
  (DateTime date) => _shiftMs(
    date,
    -date.millisecond -
        date.second * durationSecond -
        date.minute * durationMinute,
  ),
  (DateTime date, int step) => _shiftMs(date, step * durationHour),
  (DateTime start, DateTime end) =>
      (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) /
      durationHour,
  (DateTime date) => date.hour,
);

/// Local days (`d3-time/src/day.js:4-9`).
final TimeInterval timeDay = TimeInterval(
  (DateTime date) =>
      _localFloor(DateTime(date.year, date.month, date.day), date),
  (DateTime date, int step) => DateTime(
    date.year,
    date.month,
    date.day + step,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
  ),
  // day.js:7 corrects for a DST transition inside the span. JS
  // `getTimezoneOffset()` is the negation of Dart's `timeZoneOffset`, so the
  // subtraction upstream becomes an addition here.
  (DateTime start, DateTime end) =>
      (end.millisecondsSinceEpoch -
          start.millisecondsSinceEpoch +
          (end.timeZoneOffset.inMinutes - start.timeZoneOffset.inMinutes) *
              durationMinute) /
      durationDay,
  (DateTime date) => date.day - 1,
);

TimeInterval _timeWeekday(int i) => TimeInterval(
  (DateTime date) {
    // week.js:6 — DateTime.weekday is 1..7 Monday-first; JS getDay() is
    // 0..6 Sunday-first, so it is `weekday % 7`.
    final day = date.weekday % 7;
    // The 7 keeps the modulo non-negative for weekdays before `i`.
    final back = (day + 7 - i) % 7;
    return _localFloor(DateTime(date.year, date.month, date.day - back), date);
  },
  (DateTime date, int step) => DateTime(
    date.year,
    date.month,
    date.day + step * 7,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
  ),
  (DateTime start, DateTime end) =>
      (end.millisecondsSinceEpoch -
          start.millisecondsSinceEpoch +
          (end.timeZoneOffset.inMinutes - start.timeZoneOffset.inMinutes) *
              durationMinute) /
      durationWeek,
);

/// Local weeks beginning on Sunday (`d3-time/src/week.js:15`).
final TimeInterval timeSunday = _timeWeekday(0);

/// `timeWeek` is `timeSunday` (`d3-time/src/index.js`).
final TimeInterval timeWeek = timeSunday;

/// Local months (`d3-time/src/month.js:3-12`).
final TimeInterval timeMonth = TimeInterval(
  (DateTime date) => _localFloor(DateTime(date.year, date.month), date),
  (DateTime date, int step) => DateTime(
    date.year,
    date.month + step,
    date.day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
  ),
  // month.js:9. Dart's month is 1-based where JS is 0-based, but the
  // difference cancels. The 12 is months per year.
  (DateTime start, DateTime end) =>
      (end.month - start.month + (end.year - start.year) * 12).toDouble(),
  (DateTime date) => date.month - 1,
);

/// Local years (`d3-time/src/year.js:3-23`).
final TimeInterval timeYear = _yearish(utc: false);

/// UTC minutes (`d3-time/src/minute.js:16-24`).
///
/// The body is identical to [timeMinute] because a Dart `DateTime` carries its
/// own zone: `date.second` reads the UTC second of a UTC value and the local
/// second of a local one, where JS needs `setUTCSeconds` against `getSeconds`.
final TimeInterval utcMinute = TimeInterval(
  (DateTime date) =>
      _shiftMs(date, -date.millisecond - date.second * durationSecond),
  (DateTime date, int step) => _shiftMs(date, step * durationMinute),
  (DateTime start, DateTime end) =>
      (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) /
      durationMinute,
  (DateTime date) => date.minute,
);

/// UTC hours (`d3-time/src/hour.js:16-24`). Identical in body to [timeHour],
/// for the reason given on [utcMinute].
final TimeInterval utcHour = TimeInterval(
  (DateTime date) => _shiftMs(
    date,
    -date.millisecond -
        date.second * durationSecond -
        date.minute * durationMinute,
  ),
  (DateTime date, int step) => _shiftMs(date, step * durationHour),
  (DateTime start, DateTime end) =>
      (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) /
      durationHour,
  (DateTime date) => date.hour,
);

/// UTC days (`d3-time/src/day.js:13-21`).
final TimeInterval utcDay = TimeInterval(
  (DateTime date) => DateTime.utc(date.year, date.month, date.day),
  (DateTime date, int step) => DateTime.utc(
    date.year,
    date.month,
    date.day + step,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
  ),
  // day.js:18 needs no zone correction: UTC has no transitions.
  (DateTime start, DateTime end) =>
      (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) / durationDay,
  (DateTime date) => date.day - 1,
);

TimeInterval _utcWeekday(int i) => TimeInterval(
  (DateTime date) {
    final day = date.weekday % 7;
    return DateTime.utc(date.year, date.month, date.day - (day + 7 - i) % 7);
  },
  (DateTime date, int step) => DateTime.utc(
    date.year,
    date.month,
    date.day + step * 7,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
  ),
  (DateTime start, DateTime end) =>
      (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) /
      durationWeek,
);

/// UTC weeks beginning on Sunday (`d3-time/src/week.js:42`).
final TimeInterval utcSunday = _utcWeekday(0);

/// `utcWeek` is `utcSunday` (`d3-time/src/index.js`).
final TimeInterval utcWeek = utcSunday;

/// UTC months (`d3-time/src/month.js:16-25`).
final TimeInterval utcMonth = TimeInterval(
  (DateTime date) => DateTime.utc(date.year, date.month),
  (DateTime date, int step) => DateTime.utc(
    date.year,
    date.month + step,
    date.day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
  ),
  // month.js:22, as for [timeMonth]: 12 months to the year.
  (DateTime start, DateTime end) =>
      (end.month - start.month + (end.year - start.year) * 12).toDouble(),
  (DateTime date) => date.month - 1,
);

/// UTC years (`d3-time/src/year.js:27-47`).
final TimeInterval utcYear = _yearish(utc: true);

TimeInterval _yearish({required bool utc}) {
  DateTime build(
    int y, [
    int mo = 1,
    int d = 1,
    int h = 0,
    int mi = 0,
    int s = 0,
    int ms = 0,
  ]) => utc
      ? DateTime.utc(y, mo, d, h, mi, s, ms)
      : DateTime(y, mo, d, h, mi, s, ms);
  return _YearInterval(
    (DateTime date) {
      final candidate = build(date.year);
      return utc ? candidate : _localFloor(candidate, date);
    },
    (DateTime date, int step) => build(
      date.year + step,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
    ),
    (DateTime start, DateTime end) => (end.year - start.year).toDouble(),
    (DateTime date) => date.year,
    build,
  );
}

/// `timeYear.every` and `utcYear.every` are overridden with a direct
/// implementation rather than the generic filter (`d3-time/src/year.js:15-23`,
/// `:39-47`), because flooring to a multiple of k is exact.
class _YearInterval extends TimeInterval {
  _YearInterval(
    super.floori,
    super.offseti,
    super.counti,
    super.field,
    this._build,
  );

  final DateTime Function(int y, [int mo, int d, int h, int mi, int s, int ms])
  _build;

  @override
  TimeInterval? every(int step) {
    if (step <= 0) {
      return null;
    }
    if (step == 1) {
      return this;
    }
    return TimeInterval(
      (DateTime date) => _build((date.year / step).floor() * step),
      (DateTime date, int s) => _build(
        date.year + s * step,
        date.month,
        date.day,
        date.hour,
        date.minute,
        date.second,
        date.millisecond,
      ),
    );
  }
}
