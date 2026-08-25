import 'scale_continuous.dart';
import 'time_format.dart' as tf;
import 'time_interval.dart';
import 'time_ticks.dart' as tt;

/// The tick count d3 falls back to when none is given
/// (`d3-scale/src/time.js:49` and `:58`).
const int _defaultTickCount = 10;

/// A time scale (`d3-scale/src/time.js:15-67`).
///
/// d3 builds the local and the UTC scale from one `calendar` closure, passing
/// it either the `time*` or the `utc*` interval family; this port carries the
/// choice in [utc] instead and selects the family per call.
class ScaleTime extends ScaleContinuous {
  /// Creates a scale in [utc] or local time, on d3's default one-day domain
  /// (`d3-scale/src/time.js:70` and `d3-scale/src/utcTime.js:7`).
  ScaleTime({required this.utc}) {
    domainOfDates(<DateTime>[
      utc ? DateTime.utc(2000) : DateTime(2000),
      utc ? DateTime.utc(2000, 1, 2) : DateTime(2000, 1, 2),
    ]);
  }

  /// Whether this scale works in UTC.
  final bool utc;

  /// `d3-scale/src/time.js:7-9` — `new Date(t)`, in this scale's zone.
  DateTime _date(double ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms.round(), isUtc: utc);

  /// Replaces the domain with dates (`d3-scale/src/time.js:43-45`).
  ///
  /// Returns `this`, so a call chains the way [rangeOf] does.
  ScaleTime domainOfDates(List<DateTime> dates) {
    domainOf(
      dates
          .map((DateTime d) => d.millisecondsSinceEpoch.toDouble())
          .toList(growable: false),
    );
    return this;
  }

  @override
  List<Object> get domain =>
      rawDomain.map<Object>(_date).toList(growable: false);

  @override
  double? call(Object value) {
    // time.js:11-13 — a Date coerces to its epoch milliseconds, and anything
    // already numeric passes straight through.
    if (value is DateTime) {
      return super.call(value.millisecondsSinceEpoch);
    }
    return super.call(value);
  }

  @override
  DateTime? invert(double pixel) {
    final ms = super.invert(pixel);
    return ms is double ? _date(ms) : null;
  }

  @override
  List<Object> ticks([int? count]) {
    // time.js:47-50 — the *first* and the *last* domain entry, not the
    // extent, so a descending domain yields descending ticks.
    final d = rawDomain;
    final start = _date(d.first);
    final stop = _date(d.last);
    final n = count ?? _defaultTickCount;
    return (utc ? tt.utcTicks(start, stop, n) : tt.timeTicks(start, stop, n))
        .cast<Object>();
  }

  @override
  String Function(Object value) tickFormat([int? count, String? specifier]) {
    // time.js:52-54 — `count` never reaches a time formatter; only an explicit
    // specifier overrides the cascade below.
    if (specifier != null) {
      final f = utc ? tf.utcFormat(specifier) : tf.timeFormat(specifier);
      return (Object v) => f(v as DateTime);
    }
    final minute = utc ? utcMinute : timeMinute;
    final hour = utc ? utcHour : timeHour;
    final day = utc ? utcDay : timeDay;
    final week = utc ? utcSunday : timeSunday;
    final month = utc ? utcMonth : timeMonth;
    final year = utc ? utcYear : timeYear;
    final fmt = utc ? tf.utcFormat : tf.timeFormat;
    // time.js:20-27 — the eight formats of the default cascade.
    final millisecondFormat = fmt('.%L');
    final secondFormat = fmt(':%S');
    final minuteFormat = fmt('%I:%M');
    final hourFormat = fmt('%I %p');
    final dayFormat = fmt('%a %d');
    final weekFormat = fmt('%b %d');
    final monthFormat = fmt('%B');
    final yearFormat = fmt('%Y');
    return (Object v) {
      final date = v as DateTime;
      // time.js:29-37. Each test asks "is this instant finer than the interval
      // above it?", so the label names the smallest unit that changed. There
      // is one `second` instance for both zones, because a second boundary is
      // zone-independent (`d3-time/src/second.js:4`).
      if (second.floor(date).isBefore(date)) {
        return millisecondFormat(date);
      }
      if (minute.floor(date).isBefore(date)) {
        return secondFormat(date);
      }
      if (hour.floor(date).isBefore(date)) {
        return minuteFormat(date);
      }
      if (day.floor(date).isBefore(date)) {
        return hourFormat(date);
      }
      if (month.floor(date).isBefore(date)) {
        return week.floor(date).isBefore(date)
            ? dayFormat(date)
            : weekFormat(date);
      }
      if (year.floor(date).isBefore(date)) {
        return monthFormat(date);
      }
      return yearFormat(date);
    };
  }

  /// Extends the domain to whole intervals (`d3-scale/src/time.js:56-60`).
  ///
  /// [intervalOrCount] may be a [TimeInterval] or an `int` tick count; `null`
  /// means ten ticks. Returns `this`.
  ScaleTime nice([Object? intervalOrCount]) {
    final d = rawDomain;
    final start = _date(d.first);
    final stop = _date(d.last);
    final count = intervalOrCount is int ? intervalOrCount : _defaultTickCount;
    final interval = intervalOrCount is TimeInterval
        ? intervalOrCount
        : utc
        ? tt.utcTickInterval(start, stop, count)
        : tt.timeTickInterval(start, stop, count);
    if (interval == null) {
      return this;
    }
    // d3-scale/src/nice.js:1-18 — floor the low end, ceil the high one, with
    // the indices swapped for a descending domain.
    final ascending = d.first <= d.last;
    final lo = ascending ? start : stop;
    final hi = ascending ? stop : start;
    final niced = <double>[
      interval.floor(lo).millisecondsSinceEpoch.toDouble(),
      interval.ceil(hi).millisecondsSinceEpoch.toDouble(),
    ];
    domainOf(ascending ? niced : niced.reversed.toList());
    return this;
  }
}

/// A local-time scale (`d3-scale/src/time.js:69-71`).
ScaleTime scaleTime() => ScaleTime(utc: false);

/// A UTC scale (`d3-scale/src/utcTime.js:6-8`).
ScaleTime scaleUtc() => ScaleTime(utc: true);
