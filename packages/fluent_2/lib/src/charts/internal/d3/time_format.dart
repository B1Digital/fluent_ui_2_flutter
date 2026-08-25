import 'time_interval.dart';

/// Names and composite patterns for one locale
/// (`d3-time-format/src/locale.js:36-44`).
class TimeLocaleDefinition {
  /// Creates a locale definition. Every field is required, matching d3, whose
  /// `formatLocale` reads all eight without defaults.
  const TimeLocaleDefinition({
    required this.dateTime,
    required this.date,
    required this.time,
    required this.periods,
    required this.days,
    required this.shortDays,
    required this.months,
    required this.shortMonths,
  });

  /// The `%c` pattern.
  final String dateTime;

  /// The `%x` pattern.
  final String date;

  /// The `%X` pattern.
  final String time;

  /// AM and PM, in that order.
  final List<String> periods;

  /// Full weekday names, Sunday first.
  final List<String> days;

  /// Abbreviated weekday names, Sunday first.
  final List<String> shortDays;

  /// Full month names, January first.
  final List<String> months;

  /// Abbreviated month names, January first.
  final List<String> shortMonths;
}

/// en-US (`d3-time-format/src/defaultLocale.js:9-18`).
const TimeLocaleDefinition defaultTimeLocale = TimeLocaleDefinition(
  dateTime: '%x, %X',
  date: '%-m/%-d/%Y',
  time: '%-I:%M:%S %p',
  periods: <String>['AM', 'PM'],
  days: <String>[
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ],
  shortDays: <String>['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
  months: <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ],
  shortMonths: <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ],
);

/// `d3-time-format/src/locale.js:388` — the three pad modifiers.
const Map<String, String> _pads = <String, String>{'-': '', '_': ' ', '0': '0'};

/// `d3-time-format/src/locale.js:393-398`.
String _pad(num value, String fill, int width) {
  final negative = value < 0;
  final text = (negative ? -value : value).toInt().toString();
  final padded = text.length < width
      ? fill * (width - text.length) + text
      : text;
  return negative ? '-$padded' : padded;
}

/// JS `Date.getDay()`: 0 for Sunday. Dart's `weekday` is 1 for Monday and 7 for
/// Sunday, so the conversion is a modulo.
int _jsDay(DateTime d) => d.weekday % 7;

/// A locale-bound pair of formatters (`d3-time-format/src/locale.js:36`).
class TimeLocale {
  TimeLocale._(this._definition);

  final TimeLocaleDefinition _definition;

  /// A local-time formatter for [specifier].
  String Function(DateTime date) format(String specifier) =>
      _build(specifier, utc: false);

  /// A UTC formatter for [specifier].
  String Function(DateTime date) utcFormat(String specifier) =>
      _build(specifier, utc: true);

  String Function(DateTime) _build(String specifier, {required bool utc}) =>
      (DateTime date) =>
          _run(specifier, utc ? date.toUtc() : date.toLocal(), utc: utc);

  /// `d3-time-format/src/locale.js:171-196` — the scanner.
  String _run(String specifier, DateTime date, {required bool utc}) {
    final out = StringBuffer();
    var j = 0;
    var i = 0;
    final n = specifier.length;
    while (i < n) {
      // 37 is the code unit of "%".
      if (specifier.codeUnitAt(i) == 37) {
        out.write(specifier.substring(j, i));
        i++;
        var c = i < n ? specifier[i] : '';
        var pad = _pads[c];
        if (pad != null) {
          i++;
          c = i < n ? specifier[i] : '';
        } else {
          // locale.js:57 — "e" defaults to a space pad; everything else to "0".
          pad = c == 'e' ? ' ' : '0';
        }
        out.write(_directive(c, date, pad, utc: utc) ?? c);
        j = i + 1;
      }
      i++;
    }
    // A specifier ending in a bare "%" leaves j one past the end. JavaScript's
    // String.prototype.slice clamps that to the empty string; Dart's substring
    // throws a RangeError, so the clamp is explicit here.
    out.write(specifier.substring(j > n ? n : j, n));
    return out.toString();
  }

  /// The directives (`d3-time-format/src/locale.js:57-89` and their UTC twins
  /// at `:92-124`). Returns `null` for an unrecognised one, which the scanner
  /// then emits literally.
  String? _directive(String c, DateTime d, String pad, {required bool utc}) {
    final day = utc ? utcDay : timeDay;
    final year = utc ? utcYear : timeYear;
    final sunday = utc ? utcSunday : timeSunday;
    final monday = utc ? utcMonday : timeMonday;
    final thursday = utc ? utcThursday : timeThursday;

    DateTime isoAnchor(DateTime x) {
      // locale.js:646-649 — the Thursday of the ISO week. A Sunday (0) belongs
      // to the week that started before it, so it tests with the 4..6 tail.
      final w = _jsDay(x);
      return w >= 4 || w == 0 ? thursday.floor(x) : thursday.ceil(x);
    }

    switch (c) {
      case 'a':
        return _definition.shortDays[_jsDay(d)];
      case 'A':
        return _definition.days[_jsDay(d)];
      case 'b':
        // Dart's month is 1-based, the name list 0-based.
        return _definition.shortMonths[d.month - 1];
      case 'B':
        return _definition.months[d.month - 1];
      case 'c':
        return _run(_definition.dateTime, d, utc: utc);
      case 'd':
      case 'e':
        // 2 digits for a day of the month.
        return _pad(d.day, pad, 2);
      case 'f':
        // locale.js:588 — milliseconds padded to 3, then a literal "000",
        // because a JS Date has no sub-millisecond field to read.
        return '${_pad(d.millisecond, pad, 3)}000';
      case 'g':
        // 2 digits, the ISO year modulo 100.
        return _pad(isoAnchor(d).year % 100, pad, 2);
      case 'G':
        // 4 digits, the ISO year modulo 10000.
        return _pad(isoAnchor(d).year % 10000, pad, 4);
      case 'H':
        // 2 digits for a 24-hour clock.
        return _pad(d.hour, pad, 2);
      case 'I':
        // locale.js:571 — `hours % 12 || 12`, so midnight and noon print 12.
        return _pad(d.hour % 12 == 0 ? 12 : d.hour % 12, pad, 2);
      case 'j':
        // 3 digits for a day of the year, counted from 1.
        return _pad(1 + day.count(year.floor(d), d)!, pad, 3);
      case 'L':
        // 3 digits for milliseconds.
        return _pad(d.millisecond, pad, 3);
      case 'm':
        // 2 digits for a month number.
        return _pad(d.month, pad, 2);
      case 'M':
        // 2 digits for minutes.
        return _pad(d.minute, pad, 2);
      case 'p':
        return _definition.periods[d.hour >= 12 ? 1 : 0];
      case 'q':
        // locale.js:337 — `1 + ~~(month / 3)`: three months to the quarter.
        return '${1 + (d.month - 1) ~/ 3}';
      case 'Q':
        return '${d.millisecondsSinceEpoch}';
      case 's':
        // 1000 milliseconds to the second; JS floors, so a pre-epoch instant
        // rounds away from zero.
        return '${(d.millisecondsSinceEpoch / 1000).floor()}';
      case 'S':
        // 2 digits for seconds.
        return _pad(d.second, pad, 2);
      case 'u':
        // locale.js:616 — Monday is 1, Sunday is 7. That is Dart's `weekday`.
        return '${d.weekday}';
      case 'U':
        // locale.js:621 — counted from one millisecond before the year start,
        // padded to 2 digits.
        return _pad(sunday.count(_msBefore(year.floor(d)), d)!, pad, 2);
      case 'V':
        final anchor = isoAnchor(d);
        // locale.js:651 — the `+ (timeYear(d).getDay() === 4)` coercion adds
        // one when 1 January is itself a Thursday. 4 is Thursday in
        // `getDay()`'s Sunday-first numbering; 2 digits for the week number.
        return _pad(
          thursday.count(year.floor(anchor), anchor)! +
              (_jsDay(year.floor(anchor)) == 4 ? 1 : 0),
          pad,
          2,
        );
      case 'w':
        return '${_jsDay(d)}';
      case 'W':
        // As for `%U`, but Monday-based; 2 digits.
        return _pad(monday.count(_msBefore(year.floor(d)), d)!, pad, 2);
      case 'x':
        return _run(_definition.date, d, utc: utc);
      case 'X':
        return _run(_definition.time, d, utc: utc);
      case 'y':
        // 2 digits, the year modulo 100.
        return _pad(d.year % 100, pad, 2);
      case 'Y':
        // 4 digits, the year modulo 10000.
        return _pad(d.year % 10000, pad, 4);
      case 'Z':
        if (utc) {
          // locale.js:683 — a UTC formatter always reports +0000.
          return '+0000';
        }
        // locale.js:661-666. Dart's timeZoneOffset is the negation of JS's
        // getTimezoneOffset(), so the sign test flips. 60 minutes to the hour,
        // and both halves are 2 digits.
        final minutes = d.timeZoneOffset.inMinutes;
        final sign = minutes < 0 ? '-' : '+';
        final abs = minutes.abs();
        return '$sign${_pad(abs ~/ 60, '0', 2)}${_pad(abs % 60, '0', 2)}';
      case '%':
        return '%';
      default:
        return null;
    }
  }

  static DateTime _msBefore(DateTime d) => DateTime.fromMillisecondsSinceEpoch(
    // One millisecond, matching upstream's `timeYear(d) - 1` arithmetic on a
    // Date coerced to a number.
    d.millisecondsSinceEpoch - 1,
    isUtc: d.isUtc,
  );
}

/// A [TimeLocale] for [definition] (`d3-time-format/src/locale.js:36`).
///
/// `CartesianChartProps.timeFormatLocale` reaches this through
/// `utilities.ts:475`.
TimeLocale timeFormatLocale(TimeLocaleDefinition definition) =>
    TimeLocale._(definition);

final TimeLocale _default = TimeLocale._(defaultTimeLocale);

/// A local-time formatter in the default locale
/// (`d3-time-format/src/defaultLocale.js:22`).
String Function(DateTime date) timeFormat(String specifier) =>
    _default.format(specifier);

/// A UTC formatter in the default locale
/// (`d3-time-format/src/defaultLocale.js:24`).
String Function(DateTime date) utcFormat(String specifier) =>
    _default.utcFormat(specifier);
