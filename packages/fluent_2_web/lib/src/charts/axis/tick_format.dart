import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../internal/d3/format.dart' as d3;
import '../internal/d3/time_interval.dart' as d3;
import 'tick_values.dart';

/// Formats a y-axis value with an SI prefix.
///
/// Ports `yAxisTickFormatterInternal` (`utilities.ts:216-235`). The default is
/// `formatPrefix('.2~', value)` — two decimals with insignificant zeros trimmed,
/// scaled by whichever SI prefix suits the value. Two overrides apply: values
/// below one drop out of SI notation entirely because it reads badly there, and
/// when [limitWidth] is set a value of a thousand or more falls back to one
/// decimal. Finally `G` becomes `B` from `1e9` up, which is the commoner
/// convention for money and counts.
String yAxisTickFormatterInternal(double value, {bool limitWidth = false}) {
  var formatter = d3.formatPrefix('.2~', value);
  if (value.abs() < 1) {
    formatter = d3.format('.2~g');
  } else if (limitWidth && value.abs() >= 1000) {
    // 1000 is the threshold at utilities.ts:223.
    formatter = d3.formatPrefix('.1~', value);
  }
  final formatted = formatter(value);
  // 1e9 is the threshold at utilities.ts:230.
  if (value.abs() >= 1e9) {
    return formatted.replaceAll('G', 'B');
  }
  return formatted;
}

/// The default y-axis tick label formatter.
///
/// Ports `defaultYAxisTickFormatter` (`utilities.ts:242-244`).
String defaultYAxisTickFormatter(double value) =>
    yAxisTickFormatterInternal(value);

/// The width-constrained variant used for bar value labels, for example at
/// `VerticalBarChart.tsx:960`.
///
/// Ports `formatScientificLimitWidth` (`utilities.ts:1887-1889`).
String formatScientificLimitWidth(double value) =>
    yAxisTickFormatterInternal(value, limitWidth: true);

/// How one field of a date is rendered.
///
/// The subset of ECMA-402's `Intl.DateTimeFormatOptions` field values that
/// `chart-utilities/formatter.ts:110-293` actually uses.
enum FluentDateTimeField {
  /// `'numeric'` — as many digits as the value needs.
  numeric,

  /// `'2-digit'` — zero-padded to two digits.
  twoDigit,

  /// `'short'` — the abbreviated name, for months and weekdays.
  short,

  /// `'long'` — the full name, for months.
  long,
}

/// A date format described as a field bag rather than a pattern.
///
/// Ports `Intl.DateTimeFormatOptions` as far as
/// `chart-utilities/formatter.ts:53-293` uses it. Held as a bag rather than a
/// pattern because the 8x8 table at `getMultiLevelDateTimeFormatOptions`
/// (`formatter.ts:110-293`) is written that way upstream; [pattern] does the
/// one-way translation to a `package:intl` pattern at format time.
@immutable
class FluentDateTimeFormatOptions {
  /// Creates a date format bag.
  const FluentDateTimeFormatOptions({
    this.year,
    this.month,
    this.day,
    this.weekday,
    this.hour,
    this.minute,
    this.second,
    this.hour12,
  });

  /// How the year is rendered, or null to omit it.
  final FluentDateTimeField? year;

  /// How the month is rendered, or null to omit it.
  final FluentDateTimeField? month;

  /// How the day of the month is rendered, or null to omit it.
  final FluentDateTimeField? day;

  /// How the weekday is rendered, or null to omit it.
  final FluentDateTimeField? weekday;

  /// How the hour is rendered, or null to omit it.
  final FluentDateTimeField? hour;

  /// How the minute is rendered, or null to omit it.
  final FluentDateTimeField? minute;

  /// How the second is rendered, or null to omit it.
  final FluentDateTimeField? second;

  /// Whether the hour is on a twelve-hour clock with a day period.
  final bool? hour12;

  /// The `package:intl` pattern this bag resolves to.
  ///
  /// Assembled in the field order `weekday, month, day, year` then
  /// `hour:minute:second`, which is the order the en-US locale renders the
  /// upstream bags in. A numeric or two-digit month makes the month, day and
  /// year run slash-joined, as `toLocaleString` renders it; a named month
  /// leaves the whole run space-joined.
  String get pattern {
    final datePart = <String>[
      if (weekday == FluentDateTimeField.short) 'EEE',
      if (weekday == FluentDateTimeField.long) 'EEEE',
      if (month == FluentDateTimeField.short) 'MMM',
      if (month == FluentDateTimeField.long) 'MMMM',
      if (month == FluentDateTimeField.twoDigit) 'MM',
      if (month == FluentDateTimeField.numeric) 'M',
      if (day == FluentDateTimeField.twoDigit) 'dd',
      if (day == FluentDateTimeField.numeric) 'd',
      if (year == FluentDateTimeField.numeric) 'yyyy',
      if (year == FluentDateTimeField.twoDigit) 'yy',
    ];
    final timePart = <String>[
      if (hour != null)
        (hour12 ?? false)
            ? (hour == FluentDateTimeField.twoDigit ? 'hh' : 'h')
            : (hour == FluentDateTimeField.twoDigit ? 'HH' : 'H'),
      if (minute != null) minute == FluentDateTimeField.twoDigit ? 'mm' : 'm',
      if (second != null) second == FluentDateTimeField.twoDigit ? 'ss' : 's',
    ];
    final slashed = <String>[
      if (month == FluentDateTimeField.twoDigit ||
          month == FluentDateTimeField.numeric)
        ...datePart.where(
          (part) =>
              part.startsWith('M') ||
              part.startsWith('d') ||
              part.startsWith('y'),
        ),
    ];
    final head = slashed.isNotEmpty
        ? <String>[
            ...datePart.where((part) => !slashed.contains(part)),
            slashed.join('/'),
          ].join(' ')
        : datePart.join(' ');
    final tail = timePart.join(':');
    final period = (hour12 ?? false) && hour != null ? ' a' : '';
    if (head.isEmpty) {
      return '$tail$period';
    }
    if (tail.isEmpty) {
      return head;
    }
    return '$head, $tail$period';
  }
}

/// The bag every out-of-range lookup falls back to.
///
/// `DEFAULT_DATE_TIME_FORMAT_OPTION` (`chart-utilities/formatter.ts:53-62`).
const FluentDateTimeFormatOptions kDefaultDateTimeFormatOptions =
    FluentDateTimeFormatOptions(
      year: FluentDateTimeField.numeric,
      month: FluentDateTimeField.twoDigit,
      day: FluentDateTimeField.twoDigit,
      hour: FluentDateTimeField.twoDigit,
      minute: FluentDateTimeField.twoDigit,
      second: FluentDateTimeField.twoDigit,
      hour12: true,
    );

/// Formats a date for display on an axis or in a popover.
///
/// Ports `formatDateToLocaleString` (`chart-utilities/formatter.ts:78-95`).
/// [showTZname] defaults to `true` here exactly as it does upstream;
/// `createDateXAxis` (`utilities.ts:515`) is the one caller that passes `false`.
String formatDateToLocaleString(
  DateTime date, {
  String? culture,
  bool useUtc = false,
  bool showTZname = true,
  FluentDateTimeFormatOptions? options,
}) {
  final bag = options ?? kDefaultDateTimeFormatOptions;
  final subject = useUtc ? date.toUtc() : date;
  final formatted = DateFormat(bag.pattern, culture).format(subject);
  if (!showTZname) {
    return formatted;
  }
  // Intl's timeZoneName 'short' renders the UTC zone as 'UTC' (formatter.ts:88
  // pins timeZone to UTC whenever useUtc is set); the local zone name comes
  // from the platform.
  final zone = useUtc ? 'UTC' : subject.timeZoneName;
  return '$formatted $zone';
}

/// Formats a number, numeric string or date for display.
///
/// Ports `formatToLocaleString` (`chart-utilities/formatter.ts:30-51`). The
/// grouping threshold is **10000**, not 1000 (`:39`), and every numeric path
/// runs through [handleFloatingPointPrecisionError] first. Null, the empty
/// string and `NaN` are returned untouched.
String formatToLocaleString(
  Object? data, {
  String? culture,
  bool useUtc = false,
}) {
  if (data == null) {
    return '';
  }
  if (data is String && data.isEmpty) {
    return '';
  }
  if (data is num && data.isNaN) {
    return 'NaN';
  }
  final effectiveCulture = (culture == null || culture.isEmpty)
      ? null
      : culture;

  double? asNumber;
  if (data is num) {
    asNumber = data.toDouble();
  } else if (data is String) {
    asNumber = double.tryParse(data);
  }
  if (asNumber != null) {
    // 10000 is the grouping threshold at formatter.ts:40 and :44.
    final grouped = asNumber.abs() >= 10000;
    final snapped = handleFloatingPointPrecisionError(asNumber);
    final format = grouped
        ? NumberFormat.decimalPattern(effectiveCulture)
        : (NumberFormat.decimalPattern(effectiveCulture)..turnOffGrouping());
    return format.format(snapped);
  }
  if (data is DateTime) {
    return formatDateToLocaleString(
      data,
      culture: effectiveCulture,
      useUtc: useUtc,
    );
  }
  return data.toString();
}

/// How coarse a date is — `0` for milliseconds up to `7` for years.
///
/// Ports `getDateFormatLevel` (`utilities.ts:410-433`). Each level asks whether
/// flooring to the next coarser interval loses information; the first that says
/// yes wins, and years are the default (`:427`). d3 exports one `second`
/// interval that serves both the local and the UTC side, because a second
/// boundary is the same instant either way, so the `d3UtcSecond`/`d3TimeSecond`
/// choice at `:411` has no counterpart here.
int getDateFormatLevel(DateTime date, {bool useUtc = false}) {
  final minute = useUtc ? d3.utcMinute : d3.timeMinute;
  final hour = useUtc ? d3.utcHour : d3.timeHour;
  final day = useUtc ? d3.utcDay : d3.timeDay;
  final month = useUtc ? d3.utcMonth : d3.timeMonth;
  final week = useUtc ? d3.utcWeek : d3.timeWeek;
  final year = useUtc ? d3.utcYear : d3.timeYear;

  if (d3.second.floor(date).isBefore(date)) {
    return 0;
  }
  if (minute.floor(date).isBefore(date)) {
    return 1;
  }
  if (hour.floor(date).isBefore(date)) {
    return 2;
  }
  if (day.floor(date).isBefore(date)) {
    return 3;
  }
  if (month.floor(date).isBefore(date) && week.floor(date).isBefore(date)) {
    return 4;
  }
  if (month.floor(date).isBefore(date)) {
    return 5;
  }
  if (year.floor(date).isBefore(date)) {
    return 6;
  }
  return 7;
}

/// The strftime specifier that spans levels [startLevel] to [endLevel].
///
/// Ports the 8x8 table inside `getMultiLevelD3DateFormatter`
/// (`utilities.ts:347-408`). The table is Fluent's, not d3's, which is why it
/// lives here rather than in `internal/d3/time_format.dart`; that file owns only
/// the strftime engine.
///
/// Both arguments must be in `0..7`. Upstream indexes the table unguarded
/// (`:406`), so an out-of-range level there yields `undefined` and d3 formats the
/// literal string `'undefined'`; the only caller derives both levels from
/// [getDateFormatLevel] over a non-empty tick list, so the range always holds.
// ponytail: an assert rather than a clamp — a clamp would silently paper over a
// caller bug that upstream would have made loudly visible.
String multiLevelD3DateFormat(int startLevel, int endLevel) {
  // 8 is the number of granularity levels, ms through y (utilities.ts:395).
  assert(
    startLevel >= 0 && startLevel < 8 && endLevel >= 0 && endLevel < 8,
    'Format levels must be 0..7; got $startLevel..$endLevel.',
  );
  return _multiLevelD3Formats[startLevel][endLevel];
}

// Literal specifiers, named as at utilities.ts:356-392. The aliased upstream
// constants (MS_S_MIN_H_D_W_M = MS_S_MIN_H_D_W, W = D_W, and so on) are not
// restated; the table below reuses the one they alias.
const String _fmtDefault = '%c';
const String _fmtMs = '.%L';
const String _fmtMsS = ':%S.%L';
const String _fmtMsSMin = '%M:%S.%L';
const String _fmtMsSMinH = '%-I:%M:%S.%L %p';
const String _fmtMsSMinHD = '%a %d, %X';
const String _fmtMsSMinHDW = '%b %d, %X';
const String _fmtS = ':%S';
const String _fmtSMin = '%-I:%M:%S';
const String _fmtSMinH = '%X';
const String _fmtMin = '%-I:%M %p';
const String _fmtMinHD = '%a %d, %-I:%M %p';
const String _fmtMinHDW = '%b %d, %-I:%M %p';
const String _fmtMinHDWMY = '%x, %-I:%M %p';
const String _fmtH = '%-I %p';
const String _fmtHD = '%a %d, %-I %p';
const String _fmtHDW = '%b %d, %-I %p';
const String _fmtHDWMY = '%x, %-I %p';
const String _fmtD = '%a %d';
const String _fmtDW = '%b %d';
const String _fmtDWMY = '%x';
const String _fmtM = '%B';
const String _fmtMY = '%b %Y';
const String _fmtY = '%Y';

/// Rows are the start level, columns the end level, both ordered
/// ms, s, min, h, d, w, m, y (`utilities.ts:394-404`).
const List<List<String>> _multiLevelD3Formats = <List<String>>[
  // ms
  <String>[
    _fmtMs,
    _fmtMsS,
    _fmtMsSMin,
    _fmtMsSMinH,
    _fmtMsSMinHD,
    _fmtMsSMinHDW,
    _fmtMsSMinHDW,
    _fmtDefault,
  ],
  // s
  <String>[
    _fmtDefault,
    _fmtS,
    _fmtSMin,
    _fmtSMinH,
    _fmtMsSMinHD,
    _fmtMsSMinHDW,
    _fmtMsSMinHDW,
    _fmtDefault,
  ],
  // min
  <String>[
    _fmtDefault,
    _fmtDefault,
    _fmtMin,
    _fmtMin,
    _fmtMinHD,
    _fmtMinHDW,
    _fmtMinHDW,
    _fmtMinHDWMY,
  ],
  // h
  <String>[
    _fmtDefault,
    _fmtDefault,
    _fmtDefault,
    _fmtH,
    _fmtHD,
    _fmtHDW,
    _fmtHDW,
    _fmtHDWMY,
  ],
  // d
  <String>[
    _fmtDefault,
    _fmtDefault,
    _fmtDefault,
    _fmtDefault,
    _fmtD,
    _fmtDW,
    _fmtDW,
    _fmtDWMY,
  ],
  // w
  <String>[
    _fmtDefault,
    _fmtDefault,
    _fmtDefault,
    _fmtDefault,
    _fmtDefault,
    _fmtDW,
    _fmtDW,
    _fmtDWMY,
  ],
  // m
  <String>[
    _fmtDefault,
    _fmtDefault,
    _fmtDefault,
    _fmtDefault,
    _fmtDefault,
    _fmtDefault,
    _fmtM,
    _fmtMY,
  ],
  // y
  <String>[
    _fmtDefault,
    _fmtDefault,
    _fmtDefault,
    _fmtDefault,
    _fmtDefault,
    _fmtDefault,
    _fmtDefault,
    _fmtY,
  ],
];
