import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show DateFormat, Intl;

import '../internal/animated_style.dart';
import '../internal/focus_ring.dart';
import '../internal/interaction.dart';
import 'calendar_style.dart';

/// The first column of the day grid.
///
/// Upstream's `DayOfWeek`, whose Sunday is 0. Deliberately not Dart's
/// [DateTime.weekday], which runs Monday = 1 through Sunday = 7 — the
/// conversion between the two is exactly `weekday % 7`, and doing it in one
/// place is what keeps [fluentCalendarPage] free of off-by-one arithmetic.
enum FluentDayOfWeek {
  /// Sunday, upstream's default and the US convention.
  sunday,

  /// Monday, the ISO-8601 and most-of-Europe convention.
  monday,

  /// Tuesday.
  tuesday,

  /// Wednesday.
  wednesday,

  /// Thursday.
  thursday,

  /// Friday.
  friday,

  /// Saturday.
  saturday,
}

/// Which of the three grids a `FluentCalendar` is showing.
///
/// The single design axis: it is the only thing `resolveFluentCalendarStyle`
/// branches on, because it is the only thing that changes cell geometry.
enum FluentCalendarView {
  /// Days of one month, seven columns wide.
  month,

  /// The twelve months of one year, four columns wide.
  year,

  /// Twelve consecutive years, four columns wide.
  decade,
}

/// Strips the time and the zone: every date a calendar reasons about internally
/// is a UTC midnight.
///
/// Local [DateTime] arithmetic is wrong across a daylight-saving boundary. On
/// the day a clock springs forward the calendar day is 23 hours long, so
/// `DateTime(2026, 3, 8).add(const Duration(days: 1))` lands at 23:00 on the
/// *same* date — and a week row silently repeats a day. [DateTime.utc] has no
/// DST at all, so `add(const Duration(days: 7))` is exactly one week, always.
///
/// Normalising to noon is the other common answer and is strictly weaker: it
/// survives the ±1h zones but not a 30-minute shift stacked on a historical
/// offset change, and it leaves every value carrying a 12:00 the caller has to
/// strip anyway.
///
/// Dates handed *back* to the caller are converted to local midnight — see
/// [fluentCalendarLocalDay] — because that is what an application expects to
/// store.
DateTime fluentCalendarDay(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);

/// The local-midnight counterpart of [fluentCalendarDay], used on the way out.
DateTime fluentCalendarLocalDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

/// Whether two dates fall on the same calendar day, ignoring time and zone.
bool fluentCalendarIsSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Every label a `FluentCalendar` renders that is not a number.
///
/// Mirrors upstream's `CalendarStrings`. There is no `intl` dependency in this
/// package and there will not be one, so a locale other than US English is
/// supplied by the caller rather than looked up — which is also how upstream
/// works, and what makes the widget testable without a locale database.
///
/// [days] and [shortDays] are indexed **Sunday first**, matching
/// [FluentDayOfWeek], regardless of which day the grid starts on.
@immutable
class FluentCalendarStrings {
  /// Creates a set of labels.
  const FluentCalendarStrings({
    required this.months,
    required this.shortMonths,
    required this.days,
    required this.shortDays,
    this.goToToday = 'Go to today',
    this.previousMonth = 'Previous month',
    this.nextMonth = 'Next month',
    this.previousYear = 'Previous year',
    this.nextYear = 'Next year',
    this.previousYearRange = 'Previous year range',
    this.nextYearRange = 'Next year range',
    this.monthPickerHeader = '{0}, change year',
    this.yearPickerHeader = '{0}, change month',
    this.selectedDateFormat = 'Selected date {0}',
    this.todayDateFormat = "Today's date {0}",
    this.weekNumberFormat = 'Week {0}',
    this.closeButtonLabel = 'Close',
  });

  /// The twelve month names, January first.
  final List<String> months;

  /// The twelve abbreviated month names, January first.
  final List<String> shortMonths;

  /// The seven day names, **Sunday first**. Used as the accessible name of a
  /// weekday header, where [shortDays] is what is drawn.
  final List<String> days;

  /// The seven abbreviated day names, **Sunday first**. Drawn in the weekday
  /// header row.
  final List<String> shortDays;

  /// Label of the link that returns the calendar to the current month.
  final String goToToday;

  /// Accessible name of the previous chevron in the month view.
  final String previousMonth;

  /// Accessible name of the next chevron in the month view.
  final String nextMonth;

  /// Accessible name of the previous chevron in the year view.
  final String previousYear;

  /// Accessible name of the next chevron in the year view.
  final String nextYear;

  /// Accessible name of the previous chevron in the decade view.
  final String previousYearRange;

  /// Accessible name of the next chevron in the decade view.
  final String nextYearRange;

  /// Accessible name of the caption in the month view. `{0}` is replaced by the
  /// caption text.
  final String monthPickerHeader;

  /// Accessible name of the caption in the year view. `{0}` is replaced by the
  /// caption text.
  final String yearPickerHeader;

  /// Announced for the selected cell. `{0}` is replaced by the formatted date.
  final String selectedDateFormat;

  /// Announced for today's cell. `{0}` is replaced by the formatted date.
  final String todayDateFormat;

  /// Announced for a week-number cell. `{0}` is the number.
  ///
  /// Upstream's `weekNumberFormatString`. The cell draws the bare number; a
  /// screen reader needs to be told what it counts.
  final String weekNumberFormat;

  /// Accessible name of the close button, when one is shown.
  final String closeButtonLabel;

  /// US English, the only locale this package ships.
  ///
  /// Every other locale is the caller's to supply, for the reason given on the
  /// class: there is no `intl` here to look one up with.
  static const FluentCalendarStrings english = FluentCalendarStrings(
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
    days: <String>[
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ],
    shortDays: <String>['S', 'M', 'T', 'W', 'T', 'F', 'S'],
  );
}

/// Renders a day number — `15`.
String fluentFormatCalendarDay(DateTime date) => '${date.day}';

/// Renders a year — `2026`.
String fluentFormatCalendarYear(DateTime date) => '${date.year}';

/// Renders a month name — `March`.
String fluentFormatCalendarMonth(
  DateTime date,
  FluentCalendarStrings strings,
) => strings.months[date.month - 1];

/// Renders a month and year — `March 2026`.
String fluentFormatCalendarMonthYear(
  DateTime date,
  FluentCalendarStrings strings,
) => '${strings.months[date.month - 1]} ${date.year}';

/// Renders a full date — `March 15, 2026`.
String fluentFormatCalendarMonthDayYear(
  DateTime date,
  FluentCalendarStrings strings,
) => '${strings.months[date.month - 1]} ${date.day}, ${date.year}';

/// Formats a date without a locale database.
///
/// Mirrors upstream's `DateFormatting`. Each callback has a US-English default;
/// supplying one replaces exactly that rendering and leaves the rest alone.
@immutable
class FluentCalendarDateFormatter {
  /// Creates a formatter. Omitted callbacks keep their English default.
  const FluentCalendarDateFormatter({
    this.formatDay = fluentFormatCalendarDay,
    this.formatYear = fluentFormatCalendarYear,
    this.formatMonth = fluentFormatCalendarMonth,
    this.formatMonthYear = fluentFormatCalendarMonthYear,
    this.formatMonthDayYear = fluentFormatCalendarMonthDayYear,
  });

  /// Renders the number inside a day cell.
  final String Function(DateTime date) formatDay;

  /// Renders a year, in a decade cell and in the year view's caption.
  final String Function(DateTime date) formatYear;

  /// Renders a month name, in a year cell.
  final String Function(DateTime date, FluentCalendarStrings strings)
  formatMonth;

  /// Renders the month view's caption.
  final String Function(DateTime date, FluentCalendarStrings strings)
  formatMonthYear;

  /// Renders a full date, used in the accessible name of a day cell.
  final String Function(DateTime date, FluentCalendarStrings strings)
  formatMonthDayYear;

  @override
  bool operator ==(Object other) =>
      other is FluentCalendarDateFormatter &&
      other.formatDay == formatDay &&
      other.formatYear == formatYear &&
      other.formatMonth == formatMonth &&
      other.formatMonthYear == formatMonthYear &&
      other.formatMonthDayYear == formatMonthDayYear;

  @override
  int get hashCode => Object.hash(
    formatDay,
    formatYear,
    formatMonth,
    formatMonthYear,
    formatMonthDayYear,
  );
}

/// intl's locale identifier for [locale] — `en_US`, not `en-US`.
String fluentIntlLocale(Locale locale) =>
    locale.toLanguageTag().replaceAll('-', '_');

/// Whether intl can format [locale], by its own rules.
///
/// Not `DateFormat.localeExists` on its own, which is stricter than the
/// formatters are: intl files Germany under `de` rather than `de_DE`, so that
/// call is false for `de_DE` while `DateFormat.yMd('de_DE')` works perfectly.
/// `verifiedLocale` applies the same fallback chain a formatter would, so this
/// answers the question that actually matters — *will formatting throw*.
bool fluentIntlLocaleAvailable(Locale locale) =>
    Intl.verifiedLocale(
      fluentIntlLocale(locale),
      DateFormat.localeExists,
      // The empty string stands in for "no match"; `verifiedLocale` throws by
      // default, and a probe must not.
      onFailure: (_) => '',
    )?.isNotEmpty ??
    false;

/// [FluentCalendarStrings] with [locale]'s month and day names.
///
/// ## Load the locale data first
///
/// `intl` compiles in `en_US` only; every other locale is data an application
/// has to load before it is read:
///
/// ```dart
/// import 'package:intl/date_symbol_data_local.dart';
///
/// await initializeDateFormatting('de_DE');
/// ```
///
/// Skipping it throws intl's own `LocaleDataException`. That is deliberate and
/// not caught here — quietly falling back to English would put a date in front
/// of someone in a format they do not read, and `12/06` means two different
/// days either side of that fallback.
///
/// ## What is not localized
///
/// The chrome — "Go to today", "Previous month", the announcement templates —
/// has no counterpart in intl's data, which carries date symbols rather than UI
/// copy. Only the month and day names come from [locale]; everything else is
/// copied from [template], so pass a translated [FluentCalendarStrings] there
/// to localize the whole surface.
FluentCalendarStrings fluentCalendarStrings(
  Locale locale, {
  FluentCalendarStrings template = FluentCalendarStrings.english,
}) {
  final symbols = DateFormat('', fluentIntlLocale(locale)).dateSymbols;
  return FluentCalendarStrings(
    // CLDR carries 13 months for the lunisolar calendars; the Gregorian grid
    // reads the first twelve, and taking them is what keeps `months[11]`
    // meaning December rather than throwing on a locale with a leap month.
    months: List<String>.unmodifiable(symbols.MONTHS.take(12)),
    shortMonths: List<String>.unmodifiable(symbols.SHORTMONTHS.take(12)),
    // Both weekday lists arrive in CLDR order — Sunday first — which is the
    // order this class indexes by, so neither needs rotating here.
    // `firstDayOfWeek` rotates the *grid*, not the table.
    days: List<String>.unmodifiable(symbols.WEEKDAYS),
    shortDays: List<String>.unmodifiable(symbols.NARROWWEEKDAYS),
    goToToday: template.goToToday,
    previousMonth: template.previousMonth,
    nextMonth: template.nextMonth,
    previousYear: template.previousYear,
    nextYear: template.nextYear,
    previousYearRange: template.previousYearRange,
    nextYearRange: template.nextYearRange,
    monthPickerHeader: template.monthPickerHeader,
    yearPickerHeader: template.yearPickerHeader,
    selectedDateFormat: template.selectedDateFormat,
    todayDateFormat: template.todayDateFormat,
    weekNumberFormat: template.weekNumberFormat,
    closeButtonLabel: template.closeButtonLabel,
  );
}

/// A [FluentCalendarDateFormatter] that renders every cell and caption through
/// [locale]. Same locale-data requirement as [fluentCalendarStrings].
FluentCalendarDateFormatter fluentCalendarDateFormatter(Locale locale) {
  final tag = fluentIntlLocale(locale);
  final day = DateFormat.d(tag);
  final year = DateFormat.y(tag);
  final month = DateFormat.MMMM(tag);
  final monthYear = DateFormat.yMMMM(tag);
  final monthDayYear = DateFormat.yMMMMd(tag);
  return FluentCalendarDateFormatter(
    formatDay: day.format,
    formatYear: year.format,
    // The strings table is ignored on purpose: intl's own symbols are the
    // localized names here, and reading both would let the two disagree.
    formatMonth: (date, _) => month.format(date),
    formatMonthYear: (date, _) => monthYear.format(date),
    formatMonthDayYear: (date, _) => monthDayYear.format(date),
  );
}

/// Which week counts as week 1 of the year.
///
/// Upstream's `FirstWeekOfYear`, the same three members and the same ordinals.
enum FluentFirstWeekOfYear {
  /// The week containing 1 January, however few days of it fall in the year.
  /// Upstream's default *for the date picker* — `Calendar` itself defaults to
  /// [firstFullWeek], and `useDatePicker` overrides it back to this.
  firstDay,

  /// The first week wholly inside the year.
  firstFullWeek,

  /// The first week with at least four days in the year — the ISO-8601 rule.
  firstFourDayWeek,
}

/// The 1-based day of the year, so 1 January is 1.
int _dayOfYear(DateTime date) =>
    fluentCalendarDay(date).difference(DateTime.utc(date.year)).inDays + 1;

/// The day-of-week index upstream reads, Sunday 0 through Saturday 6.
///
/// JavaScript's `Date.getDay()`; Dart counts Monday 1 through Sunday 7, and
/// `% 7` is the whole conversion.
int _weekDayIndex(DateTime date) => date.weekday % 7;

/// The week of the year [date] falls in.
///
/// Transcribed from `dateMath.ts` — `getWeekNumber` and the two helpers it
/// dispatches to — including their variable names, because the arithmetic is
/// .NET's `Calendar.GetWeekOfYear` reimplemented in JavaScript and is not
/// re-derivable from the doc comment. Do not "simplify" it without a fixture.
int fluentCalendarWeekNumber(
  DateTime date, {
  FluentDayOfWeek firstDayOfWeek = FluentDayOfWeek.sunday,
  FluentFirstWeekOfYear firstWeekOfYear = FluentFirstWeekOfYear.firstDay,
}) => switch (firstWeekOfYear) {
  FluentFirstWeekOfYear.firstFullWeek => _weekOfYearFullDays(
    date,
    firstDayOfWeek.index,
    7,
  ),
  FluentFirstWeekOfYear.firstFourDayWeek => _weekOfYearFullDays(
    date,
    firstDayOfWeek.index,
    4,
  ),
  FluentFirstWeekOfYear.firstDay => _firstDayWeekOfYear(
    date,
    firstDayOfWeek.index,
  ),
};

int _firstDayWeekOfYear(DateTime date, int firstDayOfWeek) {
  final num = _dayOfYear(date) - 1;
  final num2 = _weekDayIndex(date) - (num % 7);
  final num3 = (num2 - firstDayOfWeek + 2 * 7) % 7;
  return ((num + num3) / 7 + 1).floor();
}

int _weekOfYearFullDays(
  DateTime date,
  int firstDayOfWeek,
  int numberOfFullDays,
) {
  final dayOfYear = _dayOfYear(date) - 1;
  var num = _weekDayIndex(date) - (dayOfYear % 7);

  final lastDayOfPrevYear = DateTime.utc(date.year - 1, 12, 31);
  final daysInYear = _dayOfYear(lastDayOfPrevYear) - 1;

  var num2 = (firstDayOfWeek - num + 2 * 7) % 7;
  if (num2 != 0 && num2 >= numberOfFullDays) num2 -= 7;

  var num3 = dayOfYear - num2;
  if (num3 < 0) {
    num -= daysInYear % 7;
    num2 = (firstDayOfWeek - num + 2 * 7) % 7;
    if (num2 != 0 && num2 + 1 >= numberOfFullDays) num2 -= 7;
    num3 = daysInYear - num2;
  }

  return (num3 / 7 + 1).floor();
}

/// The week number beside each of [weeksInMonth] rows of the page holding
/// [pickerDate].
///
/// Transcribed from `getWeekNumbersInMonth`. Each row is numbered by the week
/// its **last** day falls in, which is why a row spilling into the next month
/// still reads as that month's week.
List<int> fluentCalendarWeekNumbers({
  required int weeksInMonth,
  required DateTime pickerDate,
  FluentDayOfWeek firstDayOfWeek = FluentDayOfWeek.sunday,
  FluentFirstWeekOfYear firstWeekOfYear = FluentFirstWeekOfYear.firstDay,
}) {
  final year = pickerDate.year;
  final month = pickerDate.month;
  final first = DateTime.utc(year, month);
  // `adjustWeekDay`: a day earlier in the week than the first day of week
  // belongs to the previous cycle, so it counts a week higher.
  final weekDay = _weekDayIndex(first);
  final adjusted =
      firstDayOfWeek != FluentDayOfWeek.sunday && weekDay < firstDayOfWeek.index
      ? weekDay + 7
      : weekDay;
  var dayOfMonth = 1 + (firstDayOfWeek.index + 7 - 1) - adjusted;

  return <int>[
    for (var i = 0; i < weeksInMonth; i++, dayOfMonth += 7)
      fluentCalendarWeekNumber(
        // Day 33 of March is 2 April; DateTime rolls it exactly as `new Date`
        // does, which is what makes a single running counter correct here.
        DateTime.utc(year, month, dayOfMonth),
        firstDayOfWeek: firstDayOfWeek,
        firstWeekOfYear: firstWeekOfYear,
      ),
  ];
}

/// One slot of a `FluentCalendar` grid — a day, a month or a year.
@immutable
class FluentCalendarCell {
  /// Creates a cell.
  const FluentCalendarCell({
    required this.date,
    required this.label,
    required this.semanticLabel,
    required this.selectable,
    required this.selected,
    required this.today,
    required this.outOfPage,
  });

  /// The date this slot stands for, as a UTC midnight.
  ///
  /// In the year and decade views this is the first day of the period, so
  /// activating the cell can navigate straight to it.
  final DateTime date;

  /// What is drawn — `15`, `Mar`, `2026`.
  final String label;

  /// What is announced. Always the full date, so a trailing `1` from the next
  /// month reads as `April 1, 2026` rather than a bare number.
  final String semanticLabel;

  /// Whether the cell can be chosen. False outside `minDate`/`maxDate` and for
  /// a restricted date.
  final bool selectable;

  /// Whether the cell holds the current value.
  final bool selected;

  /// Whether the cell holds today.
  final bool today;

  /// Whether the cell belongs to an adjacent month or, in the decade view, to
  /// no page at all.
  ///
  /// Deliberately not a [WidgetState]: Flutter has none for this, and minting
  /// one would collide with a caller's own.
  final bool outOfPage;
}

/// Builds one page of a calendar, in row-major order.
///
/// Pure arithmetic — no widgets, no theme, no [BuildContext]. Separate from
/// `FluentCalendar` because this is the half worth testing on its own (leap
/// years, month rollover, daylight saving) and because the widget has to wrap
/// each cell in a focus node before it can resolve its state.
///
/// The grid is seven columns wide in [FluentCalendarView.month] and four in the
/// other two. Row count is **variable** in the month view — four, five or six,
/// whichever the month needs — matching upstream, whose `showSixWeeksByDefault`
/// is off by default.
///
/// In [FluentCalendarView.decade] the page runs from `pickerDate.year` for
/// twelve years. That reads oddly — opening the decade view on 2026 shows
/// 2026-2037, not 2020-2029 — but it is what upstream does:
/// `CalendarYear.tsx`'s `useYearRangeState` seeds `fromYear` from
/// `selectedYear || navigatedYear` and sets `toYear = fromYear + CELL_COUNT - 1`
/// with `CELL_COUNT = 12`. Only when there is neither a selection nor a
/// navigated date does it fall back to a decade floor.
List<List<FluentCalendarCell>> fluentCalendarPage({
  required DateTime pickerDate,
  required FluentCalendarView view,
  required DateTime today,
  DateTime? value,
  DateTime? minDate,
  DateTime? maxDate,
  Iterable<DateTime> restrictedDates = const <DateTime>[],
  FluentDayOfWeek firstDayOfWeek = FluentDayOfWeek.sunday,
  FluentCalendarStrings strings = FluentCalendarStrings.english,
  FluentCalendarDateFormatter formatter = const FluentCalendarDateFormatter(),
  bool highlightCurrentPeriod = false,
  bool highlightSelectedPeriod = false,
}) {
  final page = fluentCalendarDay(pickerDate);
  final todayDay = fluentCalendarDay(today);
  final selectedDay = value == null ? null : fluentCalendarDay(value);
  final min = minDate == null ? null : fluentCalendarDay(minDate);
  final max = maxDate == null ? null : fluentCalendarDay(maxDate);
  // Normalised once into a set rather than scanned per cell: `DateTime` has
  // value equality and a real hashCode, so this turns 42 linear scans into 42
  // lookups.
  final restricted = <DateTime>{
    for (final date in restrictedDates) fluentCalendarDay(date),
  };

  bool selectable(DateTime date) =>
      (min == null || !date.isBefore(min)) &&
      (max == null || !date.isAfter(max)) &&
      !restricted.contains(date);

  switch (view) {
    case FluentCalendarView.month:
      final first = DateTime.utc(page.year, page.month, 1);
      // Dart counts Monday = 1 through Sunday = 7; FluentDayOfWeek counts
      // Sunday = 0. `% 7` is the whole conversion.
      final firstColumn = first.weekday % 7;
      // Dart's `%` on int is always non-negative, so this needs no `+ 7`.
      final lead = (firstColumn - firstDayOfWeek.index) % 7;
      // Day zero of the next month is the last day of this one. Month 13 rolls
      // into January on its own, so there is no leap-year table and no December
      // special case anywhere here.
      final daysInMonth = DateTime.utc(page.year, page.month + 1, 0).day;
      final rows = ((lead + daysInMonth) / 7).ceil();
      final start = first.subtract(Duration(days: lead));

      return <List<FluentCalendarCell>>[
        for (var row = 0; row < rows; row++)
          <FluentCalendarCell>[
            for (var column = 0; column < 7; column++)
              _dayCell(
                date: start.add(Duration(days: row * 7 + column)),
                page: page,
                today: todayDay,
                selected: selectedDay,
                selectable: selectable,
                strings: strings,
                formatter: formatter,
              ),
          ],
      ];

    case FluentCalendarView.year:
      return _grid(
        12,
        (index) => _periodCell(
          date: DateTime.utc(page.year, index + 1, 1),
          // The abbreviation is drawn and the full name is announced, which is
          // what upstream does: `CalendarMonth.tsx` renders
          // `strings.shortMonths` and passes `formatMonth` as the aria-label.
          // A 40px cell cannot hold "September" without wrapping.
          label: strings.shortMonths[index],
          semanticLabel: formatter.formatMonth(
            DateTime.utc(page.year, index + 1, 1),
            strings,
          ),
          today: highlightCurrentPeriod ? todayDay : null,
          selected: highlightSelectedPeriod ? selectedDay : null,
          selectable: selectable,
          samePeriod: _sameMonth,
          periodEnd: DateTime.utc(page.year, index + 2, 0),
        ),
      );

    case FluentCalendarView.decade:
      return _grid(12, (index) {
        final year = page.year + index;
        final date = DateTime.utc(year, 1, 1);
        return _periodCell(
          date: date,
          label: formatter.formatYear(date),
          semanticLabel: formatter.formatYear(date),
          today: highlightCurrentPeriod ? todayDay : null,
          selected: highlightSelectedPeriod ? selectedDay : null,
          selectable: selectable,
          samePeriod: _sameYear,
          periodEnd: DateTime.utc(year, 12, 31),
        );
      });
  }
}

/// Four-column layout shared by the year and decade views.
List<List<FluentCalendarCell>> _grid(
  int count,
  FluentCalendarCell Function(int index) build,
) => <List<FluentCalendarCell>>[
  for (var row = 0; row * 4 < count; row++)
    <FluentCalendarCell>[
      for (var column = 0; column < 4 && row * 4 + column < count; column++)
        build(row * 4 + column),
    ],
];

FluentCalendarCell _dayCell({
  required DateTime date,
  required DateTime page,
  required DateTime today,
  required DateTime? selected,
  required bool Function(DateTime) selectable,
  required FluentCalendarStrings strings,
  required FluentCalendarDateFormatter formatter,
}) {
  final isToday = date == today;
  final isSelected = selected != null && date == selected;
  final full = formatter.formatMonthDayYear(date, strings);
  return FluentCalendarCell(
    date: date,
    label: formatter.formatDay(date),
    semanticLabel: switch ((isSelected, isToday)) {
      (true, _) => strings.selectedDateFormat.replaceFirst('{0}', full),
      (_, true) => strings.todayDateFormat.replaceFirst('{0}', full),
      _ => full,
    },
    selectable: selectable(date),
    selected: isSelected,
    today: isToday,
    outOfPage: date.month != page.month || date.year != page.year,
  );
}

/// A month or a year cell.
///
/// A period is selectable when *any* day in it is, so a year whose first day
/// precedes `minDate` is still reachable if its last day does not.
FluentCalendarCell _periodCell({
  required DateTime date,
  required String label,
  required String semanticLabel,
  required DateTime? today,
  required DateTime? selected,
  required bool Function(DateTime) selectable,
  required bool Function(DateTime, DateTime) samePeriod,
  required DateTime periodEnd,
}) => FluentCalendarCell(
  date: date,
  label: label,
  semanticLabel: semanticLabel,
  selectable: selectable(date) || selectable(periodEnd),
  selected: selected != null && samePeriod(date, selected),
  today: today != null && samePeriod(date, today),
  outOfPage: false,
);

bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

bool _sameYear(DateTime a, DateTime b) => a.year == b.year;

/// The grid slide when the page or the view changes.
///
/// Transcribed, not chosen. `calendarMotions.tsx` builds `DirectionalSlideIn`
/// with `duration = motionTokens.durationSlower` and
/// `easing = motionTokens.curveDecelerateMax`, and its own comment explains the
/// duration: *"Using durationSlower (400ms) as the closest token to the
/// original 367ms"* — so 400 is upstream's rounding, not ours.
/// `SLIDE_DISTANCE` is `'20px'`, which is [FluentSize.size200].
///
/// Enter only. The outgoing grid has no exit keyframe upstream; it is simply
/// gone on the next frame. Do not pair this with an exit — the asymmetry is
/// upstream's, the same call [FluentMotionSpec.popover] makes.
const FluentMotionSpec fluentCalendarViewSlide = FluentMotionSpec(
  duration: FluentDuration.slower,
  curve: FluentCurve.decelerateMax,
);

/// The weekday header labels fading in behind the sliding grid.
///
/// `CalendarMonthHeaderRow.tsx` wraps each label in
/// `<Fade.In duration={motionTokens.durationGentle}>`, and `Fade`'s default
/// easing is `curveEasyEase`. It rides the same controller as
/// [fluentCalendarViewSlide] and therefore finishes first.
const FluentMotionSpec fluentCalendarWeekdayFade = FluentMotionSpec(
  duration: FluentDuration.gentle,
  curve: FluentCurve.easyEase,
);

/// How far the grid travels on a page change, in logical pixels.
const double _slideDistance = FluentSize.size200;

/// One column of a calendar: a caption, its chevrons, and a grid.
///
/// A calendar is one or two of these side by side. Upstream splits the same way
/// — `CalendarDay` and `CalendarMonth` are separate components sharing a
/// navigated date — and the split is what makes `isMonthPickerVisible` a layout
/// question rather than a rewrite.
@immutable
class FluentCalendarPanel {
  /// Creates a panel.
  const FluentCalendarPanel({
    required this.columns,
    required this.rows,
    required this.caption,
    required this.captionSemanticLabel,
    this.weekdayLabels = const <String>[],
    this.weekdaySemanticLabels = const <String>[],
    this.weekNumbers = const <String>[],
    this.weekNumberSemanticLabels = const <String>[],
    this.onClose,
    this.closeLabel = '',
    this.onPrevious,
    this.onNext,
    this.onCaptionPressed,
    this.previousLabel = '',
    this.nextLabel = '',
    this.style,
  });

  /// Cells per row — seven for a day grid, four otherwise.
  final int columns;

  /// The grid, row-major. Already-built widgets, because `FluentCalendar` has
  /// to attach a focus node to each cell before it can resolve its state.
  final List<List<Widget>> rows;

  /// What the caption reads — `March 2026`, `2026`, `2026 - 2037`.
  final String caption;

  /// Accessible name of the caption button, which says what pressing it does.
  final String captionSemanticLabel;

  /// Drawn weekday abbreviations, already rotated for the first day of week.
  /// Empty on anything but a day grid.
  final List<String> weekdayLabels;

  /// Full weekday names, parallel to [weekdayLabels] — a one-letter column
  /// heading is not a usable accessible name.
  final List<String> weekdaySemanticLabels;

  /// One drawn week number per grid row, or empty for no week column.
  ///
  /// Parallel to [rows]; a shorter list simply stops drawing.
  final List<String> weekNumbers;

  /// Announced names for [weekNumbers] — "Week 12", not "12".
  final List<String> weekNumberSemanticLabels;

  /// Dismisses the calendar. Null hides the close button entirely.
  final VoidCallback? onClose;

  /// Accessible name of the close button.
  final String closeLabel;

  /// Steps back a page. Null disables the chevron — upstream keeps an
  /// out-of-bounds chevron focusable rather than removing it, so focus is not
  /// lost when it becomes disabled after a click.
  final VoidCallback? onPrevious;

  /// Steps forward a page.
  final VoidCallback? onNext;

  /// Drills this panel out to a coarser view. Null when there is none — a day
  /// panel sitting beside a month panel has nothing to drill to, because the
  /// coarser view is already on screen.
  final VoidCallback? onCaptionPressed;

  /// Accessible name of the previous chevron.
  final String previousLabel;

  /// Accessible name of the next chevron.
  final String nextLabel;

  /// The style this panel is drawn with, when it differs from the calendar's.
  ///
  /// Two panels genuinely have different geometry — a day cell is 28 and a
  /// month or year cell is 40 — and the style owns geometry, so the second
  /// panel has to carry its own or its cells overflow the box its column was
  /// sized to. Null uses the calendar's.
  final FluentCalendarStyle? style;
}

/// Everything needed to render a calendar, independent of which view it is.
@immutable
class FluentCalendarBaseState {
  /// Creates a base state.
  const FluentCalendarBaseState({
    required this.panels,
    required this.enabled,
    this.slideProgress = 1,
    this.slideForwards = true,
    this.onGoToToday,
    this.goToTodayLabel,
    this.semanticLabel,
  });

  /// The columns to render, in reading order. One or two.
  final List<FluentCalendarPanel> panels;

  /// Whether the calendar accepts input at all.
  final bool enabled;

  /// How far through the entrance the grids are, 0 to 1. One at rest.
  final double slideProgress;

  /// Which way the last page change went, deciding the slide's direction.
  final bool slideForwards;

  /// Returns the calendar to today. Null renders the link disabled.
  final VoidCallback? onGoToToday;

  /// Label of the "go to today" link. Null hides it entirely.
  final String? goToTodayLabel;

  /// Accessible name of the calendar as a whole.
  final String? semanticLabel;
}

/// A calendar's fully resolved state, including the design axis.
@immutable
class FluentCalendarState extends FluentCalendarBaseState {
  /// Creates a state.
  const FluentCalendarState({
    required super.panels,
    required super.enabled,
    required this.view,
    super.slideProgress,
    super.slideForwards,
    super.onGoToToday,
    super.goToTodayLabel,
    super.semanticLabel,
  });

  /// Which grid the *primary* panel is showing. The only design axis, and the
  /// only thing [resolveFluentCalendarStyle] reads.
  final FluentCalendarView view;
}

/// Assembles a [FluentCalendarState].
///
/// The first of the three-function recomposition contract.
FluentCalendarState resolveFluentCalendarState({
  required List<FluentCalendarPanel> panels,
  required FluentCalendarView view,
  bool enabled = true,
  double slideProgress = 1,
  bool slideForwards = true,
  VoidCallback? onGoToToday,
  String? goToTodayLabel,
  String? semanticLabel,
}) => FluentCalendarState(
  panels: panels,
  enabled: enabled,
  view: view,
  slideProgress: slideProgress,
  slideForwards: slideForwards,
  onGoToToday: onGoToToday,
  goToTodayLabel: goToTodayLabel,
  semanticLabel: semanticLabel,
);

/// Derives the default style for [state] from [theme].
///
/// The second of the three-function recomposition contract, and the only place
/// [FluentCalendarState.view] is read.
///
/// ## Provenance
///
/// There is no Fluent 2 Figma component set for the calendar — upstream ships
/// it as `@fluentui/react-calendar-compat`, outside the design kit — so unlike
/// every other component in this package these values are transcribed from
/// `useCalendarStyles`, `useCalendarDayStyles`, `useCalendarDayGridStyles` and
/// `useCalendarPickerStyles` in `@fluentui/react-calendar-compat` 0.4.4 rather
/// than extracted from Figma.
///
/// The geometry is upstream's and it is self-consistent: a 24px day button in a
/// 2px-padded cell tiles to `7 x 28 == 196`, and the month and year grids of
/// 40px cells with a 12px gutter come to `4 * 40 + 3 * 12 == 196` — so one
/// panel is `196 + 2 * 12 == 220` wide and two are 440, which are exactly the
/// widths `useCalendarStyles` states.
FluentCalendarStyle resolveFluentCalendarStyle(
  FluentCalendarState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final t = theme.typography;
  final month = state.view == FluentCalendarView.month;

  return FluentCalendarStyle(
    backgroundColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    borderColor: FluentStateColor.tokens(rest: c.neutralStroke2),
    borderWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    // A calendar hosted in a popup already sits on an elevated surface.
    shadow: const WidgetStatePropertyAll<List<BoxShadow>?>(<BoxShadow>[]),
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.all(FluentSpacing.m),
    ),
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.xs),
    dividerColor: FluentStateColor.tokens(rest: c.neutralStroke2),
    dividerWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),

    headerTextStyle: WidgetStatePropertyAll<TextStyle?>(t.body1Strong),
    headerForegroundColor: FluentStateColor.tokens(
      rest: c.neutralForeground1,
      hover: c.brandForegroundOnLightHover,
      pressed: c.brandForegroundOnLightPressed,
      disabled: c.neutralForegroundDisabled,
    ),
    headerBackgroundColor: FluentStateColor.tokens(
      rest: c.transparentBackground,
      hover: c.brandBackgroundInvertedHover,
      pressed: c.brandBackgroundInvertedPressed,
    ),
    // `padding: '0 4px 0 10px'` — asymmetric upstream, so the caption sits
    // further from the surface edge than from the chevrons beside it.
    headerPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.only(left: FluentSpacing.mNudge, right: FluentSpacing.xs),
    ),
    headerBorderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    headerHeight: const WidgetStatePropertyAll<double?>(FluentSize.size280),

    navButtonSize: const WidgetStatePropertyAll<Size?>(
      Size.square(FluentSize.size280),
    ),
    navButtonForegroundColor: FluentStateColor.tokens(
      rest: c.neutralForeground3,
      hover: c.brandForegroundOnLightHover,
      pressed: c.brandForegroundOnLightPressed,
      disabled: c.neutralForegroundDisabled,
    ),
    navButtonBackgroundColor: FluentStateColor.tokens(
      rest: c.transparentBackground,
      hover: c.brandBackgroundInvertedHover,
      pressed: c.brandBackgroundInvertedPressed,
    ),
    navButtonBorderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    navIconSize: const WidgetStatePropertyAll<double?>(FluentSize.size160),

    // Upstream sets neither a type ramp nor a colour on the weekday header:
    // `useWeekDayLabelCellStyles` is `userSelect: none` and nothing else, so
    // the cell inherits from the surface it is hosted on. These are the values
    // it inherits inside a DatePicker popup, whose surface carries
    // `typographyStyles.body1` and `colorNeutralForeground1`.
    weekdayTextStyle: WidgetStatePropertyAll<TextStyle?>(t.body1),
    weekdayForegroundColor: FluentStateColor.tokens(
      rest: c.neutralForeground1,
      disabled: c.neutralForegroundDisabled,
    ),

    cellSize: WidgetStatePropertyAll<Size?>(
      month
          ? const Size.square(FluentSize.size280)
          : const Size.square(FluentSize.size400),
    ),
    cellSpacing: WidgetStatePropertyAll<double?>(
      month ? FluentSpacing.none : FluentSpacing.m,
    ),
    rowSpacing: WidgetStatePropertyAll<double?>(
      month ? FluentSpacing.none : FluentSpacing.l,
    ),
    dayButtonSize: const WidgetStatePropertyAll<Size?>(
      Size.square(FluentSize.size240),
    ),
    cellBorderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    // `fontSizeBase200` in every view — upstream sets it on the day cell, the
    // month cell and the year cell alike.
    cellTextStyle: WidgetStatePropertyAll<TextStyle?>(t.caption1),
    cellBackgroundColor: FluentStateColor.tokens(
      rest: c.transparentBackground,
      hover: c.brandBackgroundInvertedHover,
      pressed: c.brandBackgroundInvertedPressed,
      disabled: c.transparentBackground,
    ),
    cellForegroundColor: FluentStateColor.tokens(
      rest: c.neutralForeground1,
      hover: c.neutralForeground1Static,
      pressed: c.neutralForeground1Static,
      disabled: c.neutralForegroundDisabled,
    ),
    outOfPageForegroundColor: FluentStateColor.tokens(
      rest: c.neutralForeground4,
      hover: c.neutralForeground1Static,
      pressed: c.neutralForeground1Static,
      disabled: c.neutralForegroundDisabled,
    ),
    // The today marker keeps its brand fill under hover and press: upstream
    // changes the surrounding cell, never the disc.
    todayBackgroundColor: FluentStateColor.tokens(rest: c.brandBackground),
    todayForegroundColor: FluentStateColor.tokens(
      rest: c.neutralForegroundOnBrand,
    ),
    todayMarkerSize: const WidgetStatePropertyAll<Size?>(
      Size.square(FluentSize.size200),
    ),
    // Selected outranks hover: upstream re-states the selected background
    // inside its own `:hover` block rather than letting the hover token win.
    selectedBackgroundColor: FluentStateColor.tokens(
      rest: c.brandBackgroundInvertedSelected,
    ),
    selectedForegroundColor: FluentStateColor.tokens(
      rest: c.neutralForeground1Static,
    ),
    selectedBorderColor: FluentStateColor.tokens(rest: c.brandStroke1),
    selectedBorderWidth: const WidgetStatePropertyAll<double?>(
      FluentStroke.thin,
    ),

    goToTodayTextStyle: WidgetStatePropertyAll<TextStyle?>(t.caption1),
    goToTodayForegroundColor: FluentStateColor.tokens(
      rest: c.neutralForeground1,
      hover: c.brandForeground1,
      pressed: c.brandForeground2,
      disabled: c.neutralForegroundDisabled,
    ),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// Renders one grid cell from a resolved [cell], [style] and interaction set.
///
/// Public for the same reason `buildFluentDropdownOption` is: a caller
/// composing their own grid should not have to re-derive the role precedence,
/// which is **disabled, then selected, then today, then out-of-page, then
/// ordinary**.
///
/// Today is drawn differently per view, following upstream: in the month view
/// it is a filled disc *inside* the day button (`useDayTodayMarkerStyles`, a
/// 20px circle on `colorBrandBackground`), while in the year and decade views
/// the whole cell takes the brand fill (`useCurrentStyles.highlightCurrent`).
Widget buildFluentCalendarCell(
  FluentCalendarCell cell,
  FluentCalendarStyle style,
  Set<WidgetState> states,
  FluentCalendarView view,
) {
  final month = view == FluentCalendarView.month;
  final size = style.cellSize?.resolve(states) ?? const Size.square(28);
  final surface = month
      ? (style.dayButtonSize?.resolve(states) ?? const Size.square(24))
      : size;
  final radius =
      style.cellBorderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final markerSize =
      style.todayMarkerSize?.resolve(states) ?? const Size.square(20);

  final disabled = states.contains(WidgetState.disabled);
  // Today outside the month view fills the whole cell, so it owns the surface
  // there the way a selection does.
  final todayFillsSurface = cell.today && !month;

  final background = switch ((disabled, cell.selected, todayFillsSurface)) {
    (true, _, _) => style.cellBackgroundColor?.resolve(states),
    (_, true, _) => style.selectedBackgroundColor?.resolve(states),
    (_, _, true) => style.todayBackgroundColor?.resolve(states),
    _ => style.cellBackgroundColor?.resolve(states),
  };
  final foreground = switch ((disabled, cell.today, cell.selected)) {
    (true, _, _) => style.cellForegroundColor?.resolve(states),
    (_, true, _) => style.todayForegroundColor?.resolve(states),
    (_, _, true) => style.selectedForegroundColor?.resolve(states),
    _ =>
      cell.outOfPage
          ? style.outOfPageForegroundColor?.resolve(states)
          : style.cellForegroundColor?.resolve(states),
  };
  final borderColor = cell.selected && !disabled
      ? style.selectedBorderColor?.resolve(states)
      : null;
  final borderWidth =
      style.selectedBorderWidth?.resolve(states) ?? FluentStroke.thin;

  Widget label = Text(
    cell.label,
    textAlign: TextAlign.center,
    style: (style.cellTextStyle?.resolve(states) ?? const TextStyle()).copyWith(
      color: foreground,
    ),
  );

  if (cell.today && month) {
    label = DecoratedBox(
      decoration: BoxDecoration(
        color: style.todayBackgroundColor?.resolve(states),
        shape: BoxShape.circle,
      ),
      child: SizedBox(
        width: markerSize.width,
        height: markerSize.height,
        child: Center(child: label),
      ),
    );
  }

  return SizedBox(
    width: size.width,
    height: size.height,
    child: Center(
      child: FluentFocusRing(
        visible: states.contains(WidgetState.focused),
        borderRadius: radius,
        child: SizedBox(
          width: surface.width,
          height: surface.height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: radius,
              border: borderColor == null
                  ? null
                  : Border.all(color: borderColor, width: borderWidth),
            ),
            child: Center(child: label),
          ),
        ),
      ),
    ),
  );
}

/// Renders a calendar from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentCalendarBaseState] rather than [FluentCalendarState] on purpose: it
/// never reads the view — each panel's own `columns` and grid shape already say
/// everything the layout needs — so a consumer can supply their own style and
/// still use Fluent's header, grid and motion.
///
/// Two panels are laid out side by side with a rule between them, which is what
/// `useCalendarStyles` does: the root is `display: flex` and the divider is a
/// `1px solid colorNeutralStroke2` border. One panel is 220 wide, two are 440.
///
/// The entrance is a plain function of
/// [FluentCalendarBaseState.slideProgress], which keeps this pure: the caller
/// drives that value from a ticker, and under
/// `MediaQuery.disableAnimationsOf` simply never leaves 1.
Widget buildFluentCalendar(
  FluentCalendarBaseState state,
  FluentCalendarStyle style,
  Set<WidgetState> states,
) {
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final dividerWidth = style.dividerWidth?.resolve(states) ?? FluentStroke.thin;
  final dividerColor = style.dividerColor?.resolve(states);

  final progress = state.slideProgress.clamp(0.0, 1.0);
  final slide = fluentCalendarViewSlide.curve.transform(progress);
  // The weekday labels fade over `durationGentle` while the grid slides over
  // `durationSlower`, so their progress runs ahead of the grid's on the same
  // controller.
  final fade = fluentCalendarWeekdayFade.curve.transform(
    (progress *
            fluentCalendarViewSlide.duration.inMilliseconds /
            fluentCalendarWeekdayFade.duration.inMilliseconds)
        .clamp(0.0, 1.0),
  );

  final columns = <Widget>[];
  for (var i = 0; i < state.panels.length; i++) {
    if (i > 0 && dividerColor != null && dividerWidth > 0) {
      columns.add(
        SizedBox(
          width: dividerWidth,
          child: ColoredBox(color: dividerColor),
        ),
      );
    }
    columns.add(
      _CalendarPanelView(
        panel: state.panels[i],
        state: state,
        style: style,
        states: states,
        slide: slide,
        fade: fade,
        // The link belongs under the last panel, which is where upstream puts
        // it: `monthPickerWrapper` holds it when a month picker is showing.
        showGoToToday: i == state.panels.length - 1,
      ),
    );
  }

  return Semantics(
    container: true,
    label: state.semanticLabel,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: style.backgroundColor?.resolve(states),
        borderRadius: radius,
        border: borderWidth <= 0 || borderColor == null
            ? null
            : Border.all(color: borderColor, width: borderWidth),
        boxShadow: style.shadow?.resolve(states),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: columns,
        ),
      ),
    ),
  );
}

/// One rendered panel: caption, chevrons, optional weekday row, grid.
class _CalendarPanelView extends StatelessWidget {
  const _CalendarPanelView({
    required this.panel,
    required this.state,
    required this.style,
    required this.states,
    required this.slide,
    required this.fade,
    required this.showGoToToday,
  });

  final FluentCalendarPanel panel;
  final FluentCalendarBaseState state;
  final FluentCalendarStyle style;
  final Set<WidgetState> states;
  final double slide;
  final double fade;
  final bool showGoToToday;

  @override
  Widget build(BuildContext context) {
    final style = panel.style ?? this.style;
    final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
    final gap = style.gap?.resolve(states) ?? FluentSpacing.xs;
    final cellSize = style.cellSize?.resolve(states) ?? const Size.square(28);
    final cellSpacing = style.cellSpacing?.resolve(states) ?? 0;
    final rowSpacing = style.rowSpacing?.resolve(states) ?? 0;
    final headerHeight =
        style.headerHeight?.resolve(states) ?? FluentSize.size280;

    // The week-number column is an extra grid column: it widens the panel and
    // takes a blank slot in the weekday row so the two stay aligned.
    final weeks = panel.weekNumbers.isNotEmpty;
    final columns = panel.columns + (weeks ? 1 : 0);

    // Every panel is held to its grid's width. Without this the header's Row
    // takes MainAxisSize.max and the panel stretches to whatever the parent
    // offers instead of the 196 upstream sizes it to.
    final gridWidth = columns * cellSize.width + (columns - 1) * cellSpacing;

    Widget weekNumber(int row) => SizedBox(
      width: cellSize.width,
      height: cellSize.height,
      child: Semantics(
        // A cell rather than a rowHeader: the framework accepts only row roles
        // under a table and only cells under a row, and the announced label is
        // what carries the meaning anyway.
        role: SemanticsRole.cell,
        container: true,
        excludeSemantics: true,
        label: row < panel.weekNumberSemanticLabels.length
            ? panel.weekNumberSemanticLabels[row]
            : null,
        child: Center(
          child: Text(
            panel.weekNumbers[row],
            textAlign: TextAlign.center,
            // Deliberately the weekday ramp, not a fourth token: upstream draws
            // both as the same muted grid chrome, and inventing a token here
            // would be a colour this package chose rather than transcribed.
            style:
                (style.weekdayTextStyle?.resolve(states) ?? const TextStyle())
                    .copyWith(
                      color: style.weekdayForegroundColor?.resolve(states),
                    ),
          ),
        ),
      ),
    );

    final grid = Column(
      mainAxisSize: MainAxisSize.min,
      spacing: rowSpacing,
      children: <Widget>[
        for (var r = 0; r < panel.rows.length; r++)
          // The row role is not decoration: Flutter asserts that a node with
          // `SemanticsRole.table` has only `SemanticsRole.row` children, so
          // omitting it crashes the semantics update rather than merely reading
          // oddly.
          Semantics(
            role: SemanticsRole.row,
            container: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: cellSpacing,
              children: <Widget>[
                if (weeks && r < panel.weekNumbers.length) weekNumber(r),
                ...panel.rows[r],
              ],
            ),
          ),
      ],
    );

    return Padding(
      padding: padding,
      child: SizedBox(
        width: gridWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: headerHeight,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _CalendarCaption(
                      panel: panel,
                      enabled: state.enabled,
                      style: style,
                    ),
                  ),
                  _CalendarNavButton(
                    icon: FluentIcons.chevron_up_20_regular,
                    semanticLabel: panel.previousLabel,
                    onPressed: state.enabled ? panel.onPrevious : null,
                    style: style,
                  ),
                  _CalendarNavButton(
                    icon: FluentIcons.chevron_down_20_regular,
                    semanticLabel: panel.nextLabel,
                    onPressed: state.enabled ? panel.onNext : null,
                    style: style,
                  ),
                  // Last in the header row, as upstream places it.
                  if (panel.onClose != null)
                    _CalendarNavButton(
                      icon: FluentIcons.dismiss_20_regular,
                      semanticLabel: panel.closeLabel,
                      onPressed: state.enabled ? panel.onClose : null,
                      style: style,
                    ),
                ],
              ),
            ),
            SizedBox(height: gap),
            if (panel.weekdayLabels.isNotEmpty)
              Opacity(
                opacity: fade,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: cellSpacing,
                  children: <Widget>[
                    // The blank corner above the week-number column.
                    if (weeks) SizedBox(width: cellSize.width),
                    for (var i = 0; i < panel.weekdayLabels.length; i++)
                      SizedBox(
                        width: cellSize.width,
                        height: cellSize.height,
                        child: Semantics(
                          // The drawn abbreviation is one letter; the full day
                          // name is what a screen reader must announce.
                          label: i < panel.weekdaySemanticLabels.length
                              ? panel.weekdaySemanticLabels[i]
                              : null,
                          // Without a container there is nothing to hang the
                          // label on once the child's own semantics are
                          // excluded, so no node is produced at all.
                          container: true,
                          excludeSemantics: true,
                          child: Center(
                            child: Text(
                              panel.weekdayLabels[i],
                              textAlign: TextAlign.center,
                              style:
                                  (style.weekdayTextStyle?.resolve(states) ??
                                          const TextStyle())
                                      .copyWith(
                                        color: style.weekdayForegroundColor
                                            ?.resolve(states),
                                      ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            // The caption is the live region, not the header button: paging
            // changes this label, and a button re-announces on every focus.
            Semantics(
              role: SemanticsRole.table,
              container: true,
              // A labelled node with structured children merges its descendants
              // unless the children are made explicit, which would both destroy
              // the per-cell announcement and leave the table with no row-role
              // children for the framework to accept.
              explicitChildNodes: true,
              liveRegion: true,
              label: panel.caption,
              child: ClipRect(
                child: Opacity(
                  opacity: slide,
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      (state.slideForwards ? _slideDistance : -_slideDistance) *
                          (1 - slide),
                    ),
                    child: grid,
                  ),
                ),
              ),
            ),
            if (showGoToToday && state.goToTodayLabel != null) ...[
              // Pushed to the bottom so the link sits on the surface's lower
              // edge even when this panel is the shorter of the two.
              const Spacer(),
              SizedBox(height: gap),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: _CalendarGoToToday(state: state, style: style),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The caption button, which drills out to a coarser view when there is one.
class _CalendarCaption extends StatelessWidget {
  const _CalendarCaption({
    required this.panel,
    required this.enabled,
    required this.style,
  });

  final FluentCalendarPanel panel;
  final bool enabled;
  final FluentCalendarStyle style;

  @override
  Widget build(BuildContext context) => FluentInteractive(
    enabled: enabled && panel.onCaptionPressed != null,
    onPressed: panel.onCaptionPressed,
    builder: (context, interactionStates, child) {
      // A caption with nothing to drill to is inert, not disabled: with the
      // month picker beside it the coarser view is already on screen, and
      // upstream still paints that header `colorNeutralForeground1`. Routing
      // the colour through FluentInteractive's disabled state would grey out
      // the month name in the default layout.
      final states = panel.onCaptionPressed == null && enabled
          ? const <WidgetState>{}
          : interactionStates;
      final radius =
          style.headerBorderRadius?.resolve(states) ?? FluentRadius.allMedium;
      return Semantics(
        button: panel.onCaptionPressed != null,
        label: panel.captionSemanticLabel,
        excludeSemantics: true,
        child: FluentFocusRing(
          visible: states.contains(WidgetState.focused),
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: style.headerBackgroundColor?.resolve(states),
              borderRadius: radius,
            ),
            child: Padding(
              padding: style.headerPadding?.resolve(states) ?? EdgeInsets.zero,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  panel.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (style.headerTextStyle?.resolve(states) ??
                              const TextStyle())
                          .copyWith(
                            color: style.headerForegroundColor?.resolve(states),
                          ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// A previous/next chevron.
class _CalendarNavButton extends StatelessWidget {
  const _CalendarNavButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    required this.style,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final FluentCalendarStyle style;

  @override
  Widget build(BuildContext context) => FluentInteractive(
    enabled: onPressed != null,
    onPressed: onPressed,
    builder: (context, states, child) {
      final size =
          style.navButtonSize?.resolve(states) ??
          const Size.square(FluentSize.size280);
      final radius =
          style.navButtonBorderRadius?.resolve(states) ??
          FluentRadius.allMedium;
      return Semantics(
        button: true,
        label: semanticLabel,
        enabled: onPressed != null,
        excludeSemantics: true,
        child: FluentFocusRing(
          visible: states.contains(WidgetState.focused),
          borderRadius: radius,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: style.navButtonBackgroundColor?.resolve(states),
                borderRadius: radius,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: style.navIconSize?.resolve(states),
                  color: style.navButtonForegroundColor?.resolve(states),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// The "go to today" link under the grid.
class _CalendarGoToToday extends StatelessWidget {
  const _CalendarGoToToday({required this.state, required this.style});

  final FluentCalendarBaseState state;
  final FluentCalendarStyle style;

  @override
  Widget build(BuildContext context) => FluentInteractive(
    enabled: state.enabled && state.onGoToToday != null,
    onPressed: state.onGoToToday,
    builder: (context, states, child) => Semantics(
      button: true,
      // The link stays in place and greys out once the calendar is already on
      // today's page, so it needs a real enabled state to report.
      enabled: state.enabled && state.onGoToToday != null,
      excludeSemantics: true,
      label: state.goToTodayLabel,
      child: FluentFocusRing(
        visible: states.contains(WidgetState.focused),
        borderRadius: FluentRadius.allSmall,
        child: Text(
          state.goToTodayLabel ?? '',
          style:
              (style.goToTodayTextStyle?.resolve(states) ?? const TextStyle())
                  .copyWith(
                    color: style.goToTodayForegroundColor?.resolve(states),
                  ),
        ),
      ),
    ),
  );
}

/// One interactive grid cell, wrapping [buildFluentCalendarCell].
class _CalendarCellWidget extends StatelessWidget {
  const _CalendarCellWidget({
    required this.cell,
    required this.focusNode,
    required this.style,
    required this.view,
    required this.onPressed,
    this.focusableWhenUnselectable = false,
  });

  final FluentCalendarCell cell;
  final FocusNode focusNode;
  final FluentCalendarStyle style;
  final FluentCalendarView view;
  final VoidCallback? onPressed;

  /// `allFocusable`. See [FluentCalendar.allFocusable].
  final bool focusableWhenUnselectable;

  @override
  Widget build(BuildContext context) {
    final interactive = cell.selectable && onPressed != null;
    if (!interactive && focusableWhenUnselectable) {
      // `FluentInteractive` derives its focusability from `enabled &&
      // onPressed != null`, so a disabled one detaches the node and the roving
      // machinery loses the cell entirely. A bare `Focus` keeps the same node
      // attached with no tap action and no hover or press states — which is
      // exactly what an unselectable-but-reachable day is.
      return Focus(
        focusNode: focusNode,
        child: Semantics(
          role: SemanticsRole.cell,
          button: true,
          label: cell.semanticLabel,
          selected: cell.selected,
          enabled: false,
          excludeSemantics: true,
          child: buildFluentCalendarCell(cell, style, const <WidgetState>{
            WidgetState.disabled,
          }, view),
        ),
      );
    }
    return FluentInteractive(
      // Null rather than a no-op when the cell cannot be chosen: an attached
      // tap handler puts a tap ACTION in the semantics tree, so a screen reader
      // announces an unselectable day as activatable.
      enabled: interactive,
      onPressed: onPressed,
      focusNode: focusNode,
      mouseCursor:
          style.mouseCursor?.resolve(const <WidgetState>{}) ??
          SystemMouseCursors.click,
      builder: (context, states, child) => Semantics(
        role: SemanticsRole.cell,
        button: true,
        label: cell.semanticLabel,
        selected: cell.selected,
        // Both halves: a day inside the bounds of a calendar whose
        // `onSelectDate` is null is still not activatable, and reporting it as
        // enabled would have a screen reader offer an action that does nothing.
        enabled: interactive,
        excludeSemantics: true,
        child: buildFluentCalendarCell(cell, style, states, view),
      ),
    );
  }
}

/// Moves the roving cell focus by cells, rows, pages or years.
///
/// Public so an application can rebind the calendar keys without forking
/// [FluentCalendar]. Expressed in **cells** rather than days so one intent
/// serves all three views: `cells: 1` is one day, one month or one year
/// depending on which grid holds focus.
class FluentCalendarMoveIntent extends Intent {
  /// Creates a move.
  const FluentCalendarMoveIntent({
    this.cells = 0,
    this.rows = 0,
    this.pages = 0,
    this.years = 0,
  });

  /// Steps along the current row.
  final int cells;

  /// Steps down or up a whole row.
  final int rows;

  /// Steps whole pages — a month, a year, or a twelve-year block.
  final int pages;

  /// Steps whole years, which `pages` already does outside the month view.
  final int years;
}

/// An edge the roving cell focus can jump to.
enum FluentCalendarEdge {
  /// The first cell of the focused row.
  rowStart,

  /// The last cell of the focused row.
  rowEnd,

  /// The first cell of the page.
  pageStart,

  /// The last cell of the page.
  pageEnd,
}

/// Jumps the roving cell focus to an edge of the current row or page.
class FluentCalendarEdgeIntent extends Intent {
  /// Creates a jump to [edge].
  const FluentCalendarEdgeIntent(this.edge);

  /// Which edge to jump to.
  final FluentCalendarEdge edge;
}

/// Drills the focused panel out to its coarser view.
///
/// Only ever outwards: drilling *in* is activating a cell, which is an
/// [ActivateIntent] on the cell itself and needs no intent of its own.
class FluentCalendarViewIntent extends Intent {
  /// Creates a drill-out.
  const FluentCalendarViewIntent();
}

/// Overrides the calendar style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentCalendarTheme extends InheritedTheme {
  /// Applies [style] to every [FluentCalendar] in [child].
  const FluentCalendarTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the view defaults.
  final FluentCalendarStyle style;

  /// The nearest calendar style, or null.
  static FluentCalendarStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentCalendarTheme>()?.style;

  @override
  bool updateShouldNotify(FluentCalendarTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentCalendarTheme(style: style, child: child);
}

/// A single-date calendar with a day grid, a month picker, and a decade view.
///
/// Selection is **controlled**: [value] is the truth and the calendar never
/// mutates it. A null [onSelectDate] disables the whole grid, matching every
/// other selection control in this package.
///
/// The *displayed page*, by contrast, is internal state seeded from
/// [initialPickerDate] and re-seeded whenever [value] moves to another page.
/// That is deliberate and it is what a `FluentDatePicker` needs: typing a date
/// into the field has to move the open calendar with no code on the picker's
/// side. Upstream has no navigated-date prop either.
///
/// ## Two panels, and how they differ
///
/// [isMonthPickerVisible] defaults to **true**, matching upstream: a calendar
/// shows the day grid *and* a month picker beside it, separated by a rule, and
/// is 440 wide rather than 220. In that layout the day caption is inert — the
/// coarser view is already on screen — and the month caption drills to the
/// decade grid. Turning the month picker off collapses to a single panel whose
/// caption walks month, year and decade in turn.
///
/// ## Keyboard
///
/// Real focus roves between cells — one [FocusNode] per grid slot, with
/// `skipTraversal` clearing on exactly one per panel, so each panel is a single
/// tab stop. That is what upstream does (`useArrowNavigationGroup` with
/// `axis: 'grid-linear'` over `tabIndex`-bearing cells), and it is why Enter
/// and Space need no binding here: [FluentInteractive] already maps
/// [ActivateIntent], and the ring already follows the package's keyboard
/// modality flag. Arrow keys act on whichever panel currently holds focus.
///
/// | Key | Day grid | Month grid | Decade grid |
/// |---|---|---|---|
/// | Left / Right | ∓1 day | ∓1 month | ∓1 year |
/// | Up / Down | ∓7 days | ∓4 months | ∓4 years |
/// | Home / End | ends of the week | January / December | ends of the page |
/// | Ctrl+Home / End | ends of the month | January / December | ends of the page |
/// | PageUp / PageDown | ∓1 month | ∓1 year | ∓1 page |
/// | Shift+PageUp / PageDown | ∓1 year | ∓1 year | — |
/// | Enter / Space | select | drill in | drill in |
///
/// `PageUp` moving *forward* looks inverted and is upstream's: `Calendar.tsx`
/// maps `PageUp` to `addMonths(navigatedDay, 1)`, comment and all.
///
/// **Escape is deliberately unbound.** A calendar has nothing to dismiss, and
/// a hosting `FluentDatePicker` owns [DismissIntent] — swallowing the key here
/// would make its popup undismissable.
///
/// Transcribed from `@fluentui/react-calendar-compat` 0.4.4. There is no Fluent
/// 2 Figma component set for this component; see [resolveFluentCalendarStyle].
class FluentCalendar extends StatefulWidget {
  /// Creates a calendar.
  const FluentCalendar({
    super.key,
    this.value,
    this.onSelectDate,
    this.today,
    this.minDate,
    this.maxDate,
    this.restrictedDates = const <DateTime>[],
    this.firstDayOfWeek = FluentDayOfWeek.sunday,
    this.initialPickerDate,
    this.onPickerDateChanged,
    this.initialView = FluentCalendarView.month,
    this.isDayPickerVisible = true,
    this.isMonthPickerVisible = true,
    this.highlightCurrentMonth = false,
    this.highlightSelectedMonth = false,
    this.showGoToToday = true,
    this.showMonthPickerAsOverlay = false,
    this.showWeekNumbers = false,
    this.firstWeekOfYear = FluentFirstWeekOfYear.firstDay,
    this.allFocusable = false,
    this.onDismiss,
    this.showCloseButton = false,
    this.strings = FluentCalendarStrings.english,
    this.formatter = const FluentCalendarDateFormatter(),
    this.style,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The selected day. Null selects nothing.
  final DateTime? value;

  /// Called with local midnight when a day is chosen.
  ///
  /// Null disables the calendar. Choosing the already-selected day fires again;
  /// upstream has no toggle-off.
  final ValueChanged<DateTime>? onSelectDate;

  /// What counts as today. Defaults to the clock at mount.
  ///
  /// Inject it in tests and goldens — an image built from `DateTime.now()`
  /// changes at midnight.
  final DateTime? today;

  /// Earliest selectable day, inclusive.
  final DateTime? minDate;

  /// Latest selectable day, inclusive.
  final DateTime? maxDate;

  /// Individual days that cannot be chosen, whatever the bounds say.
  final List<DateTime> restrictedDates;

  /// Which day the week starts on.
  final FluentDayOfWeek firstDayOfWeek;

  /// The page shown at mount. Defaults to [value], then to [today].
  final DateTime? initialPickerDate;

  /// Called with local midnight whenever the displayed page changes.
  final ValueChanged<DateTime>? onPickerDateChanged;

  /// The view the single panel shows at mount.
  ///
  /// Only consulted when [isMonthPickerVisible] is false; with both panels up,
  /// the left is always the day grid and the right starts on its month grid.
  final FluentCalendarView initialView;

  /// Whether to show the day grid.
  final bool isDayPickerVisible;

  /// Whether to show the month picker beside the day grid.
  ///
  /// True by default, as upstream. Setting it false collapses the calendar to
  /// one panel whose caption drills month, year and decade in turn.
  final bool isMonthPickerVisible;

  /// Whether the month and decade grids mark the current period.
  ///
  /// False by default, as upstream — `highlightCurrentMonth` and
  /// `highlightCurrentYear` are both off there, so a month picker beside a day
  /// grid shows twelve plain months.
  final bool highlightCurrentMonth;

  /// Whether the month and decade grids mark the selected period.
  final bool highlightSelectedMonth;

  /// Whether to offer the "go to today" link.
  final bool showGoToToday;

  /// Whether the month picker is reached through the day caption rather than
  /// shown in a second column.
  ///
  /// One panel either way, so the popup stays 220 wide instead of 440.
  ///
  /// **A superset of upstream, deliberately.** There, a month picker exists
  /// only while `isMonthPickerVisible` is true, so `isMonthPickerVisible:
  /// false` leaves an inert caption. Here that combination keeps drilling —
  /// it is the behaviour this package shipped and tested first, and removing a
  /// working keyboard path to match a `false` default would be a regression
  /// dressed as parity.
  final bool showMonthPickerAsOverlay;

  /// Whether the day grid draws a week-number column down its leading edge.
  final bool showWeekNumbers;

  /// Which week counts as week 1, when [showWeekNumbers] is set.
  ///
  /// [FluentFirstWeekOfYear.firstDay] here rather than upstream `Calendar`'s
  /// `FirstFullWeek`, because `useDatePicker` overrides it to `FirstDay` and a
  /// calendar inside a picker is by far the common case.
  final FluentFirstWeekOfYear firstWeekOfYear;

  /// Whether unselectable days still take keyboard focus.
  ///
  /// Upstream's `allFocusable`. Off by default: a roving grid that stops on
  /// days nothing can be done with is slower to drive. On, an out-of-bounds day
  /// is reachable and announced but still not activatable.
  final bool allFocusable;

  /// Called when the close button is pressed.
  final VoidCallback? onDismiss;

  /// Whether the header offers a close button.
  ///
  /// Draws nothing unless [onDismiss] is also given — a button that dismisses
  /// nothing is worse than no button.
  final bool showCloseButton;

  /// Every label that is not a number.
  final FluentCalendarStrings strings;

  /// How dates are rendered.
  final FluentCalendarDateFormatter formatter;

  /// Overrides layered over the resolved defaults.
  final FluentCalendarStyle? style;

  /// Whether to take focus on mount, landing on [value] or else [today].
  final bool autofocus;

  /// Accessible name of the calendar as a whole.
  final String? semanticLabel;

  @override
  State<FluentCalendar> createState() => _FluentCalendarState();
}

class _FluentCalendarState extends State<FluentCalendar>
    with SingleTickerProviderStateMixin {
  /// Six rows of seven is the largest month; a month or decade grid needs
  /// twelve. Allocated once so paging never churns a node and never drops
  /// focus.
  static const int _slots = 42;
  static const int _sideSlots = 12;

  final List<FocusNode> _nodes = List<FocusNode>.generate(
    _slots,
    (index) => FocusNode(debugLabel: 'FluentCalendar cell $index'),
    growable: false,
  );
  final List<FocusNode> _sideNodes = List<FocusNode>.generate(
    _sideSlots,
    (index) => FocusNode(debugLabel: 'FluentCalendar month cell $index'),
    growable: false,
  );

  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: fluentCalendarViewSlide.duration,
    // Settled at mount: nothing slides on the first paint.
    value: 1,
  );

  late DateTime _today;
  late DateTime _pickerDate;
  late DateTime _sidePickerDate;
  late DateTime _focusedDate;
  late DateTime _sideFocusedDate;
  late FluentCalendarView _view;
  FluentCalendarView _sideView = FluentCalendarView.year;
  bool _forwards = true;
  bool _focusOnNextBuild = false;
  bool _focusSideOnNextBuild = false;
  bool _reducedMotion = false;

  bool get _enabled => widget.onSelectDate != null;

  /// Whether both panels are up, which is what makes the day caption inert.
  /// Whether the month picker sits *beside* the day grid in a second column.
  ///
  /// `showMonthPickerAsOverlay` is upstream's other way of having one: the same
  /// picker reached by the day caption, in the same column. Turning it on drops
  /// the panel count back to one and re-arms the caption, because
  /// `onCaptionPressed` is already gated on this.
  bool get _split =>
      widget.isDayPickerVisible &&
      widget.isMonthPickerVisible &&
      !widget.showMonthPickerAsOverlay;

  /// The view the primary (left, or only) panel is showing.
  FluentCalendarView get _primaryView =>
      widget.isDayPickerVisible ? _view : _sideView;

  bool get _sideHasFocus => _sideNodes.any((node) => node.hasFocus);

  DateTime? get _min =>
      widget.minDate == null ? null : fluentCalendarDay(widget.minDate!);

  DateTime? get _max =>
      widget.maxDate == null ? null : fluentCalendarDay(widget.maxDate!);

  @override
  void initState() {
    super.initState();
    _today = fluentCalendarDay(widget.today ?? DateTime.now());
    _view = widget.isDayPickerVisible && widget.isMonthPickerVisible
        ? FluentCalendarView.month
        : widget.initialView;
    _focusedDate = fluentCalendarDay(widget.value ?? _today);
    _sideFocusedDate = _focusedDate;
    final seed = fluentCalendarDay(
      widget.initialPickerDate ?? widget.value ?? _today,
    );
    // Both anchors are seeded before either is normalised: `_pageFor` reads
    // `_sidePickerDate` in the decade branch, because a twelve-year block is
    // anchored wherever the previous one left off rather than snapping to a
    // decade. Calling it against an uninitialised field is a late-init error.
    _sidePickerDate = DateTime.utc(seed.year, 1, 1);
    _pickerDate = seed;
    _pickerDate = _pageFor(seed, _primaryView);
    _focusOnNextBuild = widget.autofocus;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _slide.duration = _reducedMotion
        ? Duration.zero
        : fluentCalendarViewSlide.duration;
  }

  @override
  void didUpdateWidget(FluentCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.today != oldWidget.today) {
      _today = fluentCalendarDay(widget.today ?? DateTime.now());
    }
    final value = widget.value;
    if (value != null && value != oldWidget.value) {
      // A DatePicker whose field is typed into moves `value` while the popup is
      // open; the page has to follow or the user is looking at the wrong month.
      // Only the PAGE moves — nothing here selects anything.
      final day = fluentCalendarDay(value);
      _focusedDate = day;
      final page = _pageFor(day, _primaryView);
      if (page != _pickerDate) _pickerDate = page;
      _sidePickerDate = DateTime.utc(day.year, 1, 1);
    }
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    for (final node in _sideNodes) {
      node.dispose();
    }
    _slide.dispose();
    super.dispose();
  }

  // --- date arithmetic -------------------------------------------------------

  /// Adds whole months, clamping the day so 31 January plus one month is the
  /// last day of February rather than rolling into March.
  DateTime _addMonths(DateTime date, int months) {
    final target = date.month + months;
    final lastDay = DateTime.utc(date.year, target + 1, 0).day;
    return DateTime.utc(
      date.year,
      target,
      date.day > lastDay ? lastDay : date.day,
    );
  }

  /// The page a date belongs to in [view], as its anchor.
  DateTime _pageFor(DateTime date, FluentCalendarView view) => switch (view) {
    FluentCalendarView.month => DateTime.utc(date.year, date.month, 1),
    FluentCalendarView.year => DateTime.utc(date.year, 1, 1),
    // Twelve-year blocks are free-running from wherever the page started, so
    // the anchor moves in whole pages rather than snapping to a decade.
    FluentCalendarView.decade => DateTime.utc(
      _sidePickerDate.year +
          ((date.year - _sidePickerDate.year) / 12).floor() * 12,
      1,
      1,
    ),
  };

  DateTime _pageStart(DateTime page, FluentCalendarView view) => switch (view) {
    FluentCalendarView.month => DateTime.utc(page.year, page.month, 1),
    FluentCalendarView.year => DateTime.utc(page.year, 1, 1),
    FluentCalendarView.decade => DateTime.utc(page.year, 1, 1),
  };

  DateTime _pageEnd(DateTime page, FluentCalendarView view) => switch (view) {
    FluentCalendarView.month => DateTime.utc(page.year, page.month + 1, 0),
    FluentCalendarView.year => DateTime.utc(page.year, 12, 31),
    FluentCalendarView.decade => DateTime.utc(page.year + 11, 12, 31),
  };

  DateTime _shiftPage(DateTime page, int pages, FluentCalendarView view) =>
      switch (view) {
        FluentCalendarView.month => _addMonths(page, pages),
        FluentCalendarView.year => DateTime.utc(page.year + pages, 1, 1),
        FluentCalendarView.decade => DateTime.utc(page.year + pages * 12, 1, 1),
      };

  /// One step in a view's unit, used when seeking past a cell that cannot be
  /// chosen.
  DateTime _step(DateTime date, int direction, FluentCalendarView view) =>
      switch (view) {
        FluentCalendarView.month => date.add(Duration(days: direction)),
        FluentCalendarView.year => _addMonths(date, direction),
        FluentCalendarView.decade => DateTime.utc(
          date.year + direction,
          date.month,
          1,
        ),
      };

  bool _dayIsSelectable(DateTime date) {
    final min = _min;
    final max = _max;
    if (min != null && date.isBefore(min)) return false;
    if (max != null && date.isAfter(max)) return false;
    return !widget.restrictedDates
        .map(fluentCalendarDay)
        .contains(fluentCalendarDay(date));
  }

  /// Whether a cell standing for [date] in [view] can be reached.
  ///
  /// Outside the day grid a cell stands for a whole period, and a period is
  /// reachable when any day in it is.
  bool _isSelectable(DateTime date, FluentCalendarView view) => switch (view) {
    FluentCalendarView.month => _dayIsSelectable(date),
    FluentCalendarView.year =>
      _dayIsSelectable(DateTime.utc(date.year, date.month, 1)) ||
          _dayIsSelectable(DateTime.utc(date.year, date.month + 1, 0)),
    FluentCalendarView.decade =>
      _dayIsSelectable(DateTime.utc(date.year, 1, 1)) ||
          _dayIsSelectable(DateTime.utc(date.year, 12, 31)),
  };

  bool _outOfBounds(DateTime date, int direction) {
    final min = _min;
    final max = _max;
    if (direction > 0 && max != null && date.isAfter(max)) return true;
    if (direction < 0 && min != null && date.isBefore(min)) return true;
    return false;
  }

  // --- pages -----------------------------------------------------------------

  List<List<FluentCalendarCell>> _cellsFor(
    DateTime page,
    FluentCalendarView view,
  ) => fluentCalendarPage(
    pickerDate: page,
    view: view,
    today: _today,
    value: widget.value,
    minDate: widget.minDate,
    maxDate: widget.maxDate,
    restrictedDates: widget.restrictedDates,
    firstDayOfWeek: widget.firstDayOfWeek,
    strings: widget.strings,
    formatter: widget.formatter,
    highlightCurrentPeriod: widget.highlightCurrentMonth,
    highlightSelectedPeriod: widget.highlightSelectedMonth,
  );

  bool _matches(
    FluentCalendarCell cell,
    DateTime date,
    FluentCalendarView view,
  ) => switch (view) {
    FluentCalendarView.month => cell.date == date,
    FluentCalendarView.year =>
      cell.date.year == date.year && cell.date.month == date.month,
    FluentCalendarView.decade => cell.date.year == date.year,
  };

  bool _onScreen(
    DateTime date,
    List<List<FluentCalendarCell>> cells,
    FluentCalendarView view,
  ) {
    for (final row in cells) {
      for (final cell in row) {
        if (_matches(cell, date, view)) return true;
      }
    }
    return false;
  }

  void _restartSlide() {
    if (_reducedMotion) {
      _slide.value = 1;
      return;
    }
    _slide.forward(from: 0);
  }

  // --- navigation ------------------------------------------------------------

  void _focusTo(DateTime date, {required bool side}) {
    setState(() {
      final view = side ? _sideView : _primaryView;
      if (side) {
        _sideFocusedDate = date;
        if (!_onScreen(date, _cellsFor(_sidePickerDate, view), view)) {
          _forwards = date.isAfter(_sidePickerDate);
          _sidePickerDate = _pageFor(date, view);
          _restartSlide();
        }
        _focusSideOnNextBuild = true;
      } else {
        _focusedDate = date;
        if (!_onScreen(date, _cellsFor(_pickerDate, view), view)) {
          _forwards = date.isAfter(_pickerDate);
          _pickerDate = _pageFor(date, view);
          _restartSlide();
          widget.onPickerDateChanged?.call(fluentCalendarLocalDay(_pickerDate));
        }
        _focusOnNextBuild = true;
      }
    });
  }

  void _seekAndFocus(DateTime target, int direction, {required bool side}) {
    final view = side ? _sideView : _primaryView;
    var candidate = target;
    // The bound is what guarantees termination; the counter is a backstop for a
    // caller with no bounds and a pathological `restrictedDates`.
    for (var guard = 0; guard < 800; guard++) {
      if (_outOfBounds(candidate, direction)) return;
      if (_isSelectable(candidate, view)) {
        _focusTo(candidate, side: side);
        return;
      }
      candidate = _step(candidate, direction, view);
    }
  }

  void _move(FluentCalendarMoveIntent intent) {
    final side = _sideHasFocus;
    final view = side ? _sideView : _primaryView;
    final from = side ? _sideFocusedDate : _focusedDate;
    final total = intent.cells + intent.rows + intent.pages + intent.years;
    final direction = total >= 0 ? 1 : -1;
    final target = switch (view) {
      FluentCalendarView.month => _addMonths(
        from.add(Duration(days: intent.cells + intent.rows * 7)),
        intent.pages + intent.years * 12,
      ),
      FluentCalendarView.year => _addMonths(
        from,
        intent.cells + intent.rows * 4 + (intent.pages + intent.years) * 12,
      ),
      FluentCalendarView.decade => _addMonths(
        from,
        (intent.cells + intent.rows * 4 + intent.pages * 12) * 12,
      ),
    };
    _seekAndFocus(target, direction, side: side);
  }

  void _edge(FluentCalendarEdge edge) {
    final side = _sideHasFocus;
    final view = side ? _sideView : _primaryView;
    final page = side ? _sidePickerDate : _pickerDate;
    final focused = side ? _sideFocusedDate : _focusedDate;
    final cells = _cellsFor(page, view);
    switch (edge) {
      case FluentCalendarEdge.rowStart:
      case FluentCalendarEdge.rowEnd:
        for (final row in cells) {
          final index = row.indexWhere((cell) => _matches(cell, focused, view));
          if (index < 0) continue;
          _seekAndFocus(
            edge == FluentCalendarEdge.rowStart
                ? row.first.date
                : row.last.date,
            edge == FluentCalendarEdge.rowStart ? -1 : 1,
            side: side,
          );
          return;
        }
      case FluentCalendarEdge.pageStart:
        _seekAndFocus(_pageStart(page, view), 1, side: side);
      case FluentCalendarEdge.pageEnd:
        _seekAndFocus(
          view == FluentCalendarView.month
              ? _pageEnd(page, view)
              : cells.last.last.date,
          -1,
          side: side,
        );
    }
  }

  void _page(int pages, {required bool side}) {
    setState(() {
      _forwards = pages > 0;
      if (side) {
        _sidePickerDate = _shiftPage(_sidePickerDate, pages, _sideView);
        _restartSlide();
        if (!_onScreen(
          _sideFocusedDate,
          _cellsFor(_sidePickerDate, _sideView),
          _sideView,
        )) {
          _sideFocusedDate = _pageStart(_sidePickerDate, _sideView);
        }
      } else {
        _pickerDate = _shiftPage(_pickerDate, pages, _primaryView);
        _restartSlide();
        widget.onPickerDateChanged?.call(fluentCalendarLocalDay(_pickerDate));
        if (!_onScreen(
          _focusedDate,
          _cellsFor(_pickerDate, _primaryView),
          _primaryView,
        )) {
          _focusedDate = _pageStart(_pickerDate, _primaryView);
        }
      }
    });
  }

  /// Drills the side panel out — month grid to decade grid.
  void _drillSide() {
    if (_sideView != FluentCalendarView.year) return;
    setState(() {
      _sideView = FluentCalendarView.decade;
      _sidePickerDate = DateTime.utc(_sideFocusedDate.year, 1, 1);
      _forwards = false;
      _restartSlide();
      _focusSideOnNextBuild = true;
    });
  }

  /// Drills the single panel out — month, then year, then decade.
  void _drillPrimary() {
    if (_split) return;
    final next = switch (_primaryView) {
      FluentCalendarView.month => FluentCalendarView.year,
      FluentCalendarView.year => FluentCalendarView.decade,
      FluentCalendarView.decade => null,
    };
    if (next == null) return;
    setState(() {
      if (widget.isDayPickerVisible) {
        _view = next;
        _pickerDate = _pageFor(_focusedDate, next);
      } else {
        _sideView = next;
        _pickerDate = _pageFor(_focusedDate, next);
      }
      _forwards = false;
      _restartSlide();
      _focusOnNextBuild = true;
    });
  }

  void _activatePrimary(FluentCalendarCell cell) {
    if (!_enabled || !cell.selectable) return;
    switch (_primaryView) {
      case FluentCalendarView.month:
        widget.onSelectDate!(fluentCalendarLocalDay(cell.date));
      case FluentCalendarView.year:
        setState(() {
          if (widget.isDayPickerVisible) {
            _view = FluentCalendarView.month;
          } else {
            _sideView = FluentCalendarView.year;
          }
          _focusedDate = cell.date;
          _pickerDate = _pageFor(cell.date, FluentCalendarView.month);
          _forwards = true;
          _restartSlide();
          _focusOnNextBuild = true;
        });
      case FluentCalendarView.decade:
        setState(() {
          _sideView = FluentCalendarView.year;
          _view = FluentCalendarView.year;
          _focusedDate = cell.date;
          _pickerDate = _pageFor(cell.date, FluentCalendarView.year);
          _forwards = true;
          _restartSlide();
          _focusOnNextBuild = true;
        });
    }
  }

  /// Activating a side cell moves the day grid rather than selecting anything.
  void _activateSide(FluentCalendarCell cell) {
    if (!_enabled || !cell.selectable) return;
    setState(() {
      if (_sideView == FluentCalendarView.decade) {
        _sideView = FluentCalendarView.year;
        _sidePickerDate = DateTime.utc(cell.date.year, 1, 1);
        _sideFocusedDate = cell.date;
      } else {
        _focusedDate = cell.date;
        _pickerDate = DateTime.utc(cell.date.year, cell.date.month, 1);
        _sideFocusedDate = cell.date;
        widget.onPickerDateChanged?.call(fluentCalendarLocalDay(_pickerDate));
      }
      _forwards = true;
      _restartSlide();
    });
  }

  // --- build -----------------------------------------------------------------

  String _captionFor(DateTime page, FluentCalendarView view) => switch (view) {
    FluentCalendarView.month => widget.formatter.formatMonthYear(
      page,
      widget.strings,
    ),
    FluentCalendarView.year => widget.formatter.formatYear(page),
    FluentCalendarView.decade =>
      '${widget.formatter.formatYear(page)} - '
          '${widget.formatter.formatYear(DateTime.utc(page.year + 11, 1, 1))}',
  };

  /// Builds one panel's cells and the panel itself.
  FluentCalendarPanel _buildPanel({
    required DateTime page,
    required FluentCalendarView view,
    required FluentCalendarStyle style,
    required List<FocusNode> nodes,
    required DateTime focused,
    required bool side,
    required VoidCallback? onCaptionPressed,
  }) {
    final cells = _cellsFor(page, view);

    // Exactly one cell leaves the tab order open. Without this a month would be
    // 42 tab stops, which is the most common way an ARIA grid is got wrong.
    // `allFocusable` widens what may hold the roving stop to every cell, which
    // is the whole point of the flag: an out-of-bounds day is reachable.
    bool focusable(FluentCalendarCell cell) =>
        cell.selectable || widget.allFocusable;

    var active = -1;
    var slot = 0;
    for (final row in cells) {
      for (final cell in row) {
        if (_matches(cell, focused, view) && focusable(cell)) active = slot;
        slot++;
      }
    }
    if (active < 0) {
      slot = 0;
      for (final row in cells) {
        for (final cell in row) {
          if (active < 0 && focusable(cell)) active = slot;
          slot++;
        }
      }
    }

    slot = 0;
    final rows = <List<Widget>>[];
    for (final row in cells) {
      final built = <Widget>[];
      for (final cell in row) {
        final node = nodes[slot];
        node.skipTraversal = slot != active;
        built.add(
          _CalendarCellWidget(
            cell: cell,
            focusNode: node,
            style: style,
            view: view,
            focusableWhenUnselectable: widget.allFocusable,
            onPressed: _enabled
                ? () => side ? _activateSide(cell) : _activatePrimary(cell)
                : null,
          ),
        );
        slot++;
      }
      rows.add(built);
    }

    final pendingFocus = side ? _focusSideOnNextBuild : _focusOnNextBuild;
    if (pendingFocus) {
      if (side) {
        _focusSideOnNextBuild = false;
      } else {
        _focusOnNextBuild = false;
      }
      final target = active;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && target >= 0) nodes[target].requestFocus();
      });
    }

    final min = _min;
    final max = _max;
    final previousPage = _shiftPage(page, -1, view);
    final nextPage = _shiftPage(page, 1, view);
    final month = view == FluentCalendarView.month;
    final caption = _captionFor(page, view);
    final weekNumbers = month && widget.showWeekNumbers
        ? fluentCalendarWeekNumbers(
            weeksInMonth: cells.length,
            pickerDate: page,
            firstDayOfWeek: widget.firstDayOfWeek,
            firstWeekOfYear: widget.firstWeekOfYear,
          )
        : const <int>[];
    final showClose =
        widget.showCloseButton && widget.onDismiss != null && !side;

    return FluentCalendarPanel(
      columns: month ? 7 : 4,
      rows: rows,
      caption: caption,
      captionSemanticLabel: onCaptionPressed == null
          ? caption
          : switch (view) {
              FluentCalendarView.month =>
                widget.strings.monthPickerHeader.replaceFirst('{0}', caption),
              FluentCalendarView.year =>
                widget.strings.yearPickerHeader.replaceFirst('{0}', caption),
              FluentCalendarView.decade => caption,
            },
      weekdayLabels: month
          ? <String>[
              for (var i = 0; i < 7; i++)
                widget.strings.shortDays[(i + widget.firstDayOfWeek.index) % 7],
            ]
          : const <String>[],
      weekdaySemanticLabels: month
          ? <String>[
              for (var i = 0; i < 7; i++)
                widget.strings.days[(i + widget.firstDayOfWeek.index) % 7],
            ]
          : const <String>[],
      weekNumbers: weekNumbers.map((week) => '$week').toList(growable: false),
      weekNumberSemanticLabels: weekNumbers
          .map(
            (week) =>
                widget.strings.weekNumberFormat.replaceFirst('{0}', '$week'),
          )
          .toList(growable: false),
      // Only the panel that owns the header gets it, which with two panels is
      // the day grid on the left — the same place upstream's `CalendarDay`
      // renders it.
      onClose: showClose ? widget.onDismiss : null,
      closeLabel: widget.strings.closeButtonLabel,
      onPrevious: min == null || !_pageEnd(previousPage, view).isBefore(min)
          ? () => _page(-1, side: side)
          : null,
      onNext: max == null || !_pageStart(nextPage, view).isAfter(max)
          ? () => _page(1, side: side)
          : null,
      onCaptionPressed: onCaptionPressed,
      previousLabel: switch (view) {
        FluentCalendarView.month => widget.strings.previousMonth,
        FluentCalendarView.year => widget.strings.previousYear,
        FluentCalendarView.decade => widget.strings.previousYearRange,
      },
      nextLabel: switch (view) {
        FluentCalendarView.month => widget.strings.nextMonth,
        FluentCalendarView.year => widget.strings.nextYear,
        FluentCalendarView.decade => widget.strings.nextYearRange,
      },
      style: style,
    );
  }

  FluentCalendarStyle _styleFor(
    FluentCalendarView view,
    FluentThemeData theme,
    BuildContext context,
  ) => resolveFluentCalendarStyle(
    resolveFluentCalendarState(
      panels: const <FluentCalendarPanel>[],
      view: view,
      enabled: _enabled,
    ),
    theme,
  ).merge(FluentCalendarTheme.maybeOf(context)).merge(widget.style);

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final states = <WidgetState>{if (!_enabled) WidgetState.disabled};

    // One style per panel, because the two grids have different geometry: a day
    // cell is 28 and a month or year cell is 40. `buildFluentCalendar` stays
    // pure by taking the primary style and letting each panel carry its own.
    final primaryStyle = _styleFor(_primaryView, theme, context);
    final sideStyle = _styleFor(_sideView, theme, context);

    final panels = <FluentCalendarPanel>[];
    if (widget.isDayPickerVisible) {
      panels.add(
        _buildPanel(
          page: _pickerDate,
          view: _primaryView,
          style: primaryStyle,
          nodes: _nodes,
          focused: _focusedDate,
          side: false,
          // With the month picker beside it there is nothing to drill to, so
          // upstream leaves the day caption inert.
          onCaptionPressed: _split ? null : _drillPrimary,
        ),
      );
    }
    if (widget.isMonthPickerVisible && (_split || !widget.isDayPickerVisible)) {
      panels.add(
        _buildPanel(
          page: widget.isDayPickerVisible ? _sidePickerDate : _pickerDate,
          view: _sideView,
          style: sideStyle,
          nodes: widget.isDayPickerVisible ? _sideNodes : _nodes,
          focused: widget.isDayPickerVisible ? _sideFocusedDate : _focusedDate,
          side: widget.isDayPickerVisible,
          onCaptionPressed: widget.isDayPickerVisible
              ? (_sideView == FluentCalendarView.year ? _drillSide : null)
              : _drillPrimary,
        ),
      );
    }

    final onToday =
        widget.showGoToToday &&
            _enabled &&
            _pageFor(_today, _primaryView) != _pickerDate
        ? () {
            setState(() {
              _forwards = _today.isAfter(_pickerDate);
              if (widget.isDayPickerVisible) _view = FluentCalendarView.month;
              _sideView = FluentCalendarView.year;
              _pickerDate = _pageFor(_today, FluentCalendarView.month);
              _sidePickerDate = DateTime.utc(_today.year, 1, 1);
              _focusedDate = _today;
              _sideFocusedDate = _today;
              _restartSlide();
              widget.onPickerDateChanged?.call(
                fluentCalendarLocalDay(_pickerDate),
              );
            });
          }
        : null;

    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Shortcuts(
      // Arrow keys are physical; the grid is logical, so the two swap under
      // RTL exactly as they do in FluentDataGrid.
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            FluentCalendarMoveIntent(cells: rtl ? 1 : -1),
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            FluentCalendarMoveIntent(cells: rtl ? -1 : 1),
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            const FluentCalendarMoveIntent(rows: -1),
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            const FluentCalendarMoveIntent(rows: 1),
        const SingleActivator(LogicalKeyboardKey.home):
            const FluentCalendarEdgeIntent(FluentCalendarEdge.rowStart),
        const SingleActivator(LogicalKeyboardKey.end):
            const FluentCalendarEdgeIntent(FluentCalendarEdge.rowEnd),
        const SingleActivator(LogicalKeyboardKey.home, control: true):
            const FluentCalendarEdgeIntent(FluentCalendarEdge.pageStart),
        const SingleActivator(LogicalKeyboardKey.end, control: true):
            const FluentCalendarEdgeIntent(FluentCalendarEdge.pageEnd),
        // PageUp moves FORWARD. Upstream's `Calendar.tsx` maps it to
        // `addMonths(navigatedDay, 1)`; it reads backwards and it is what ships.
        const SingleActivator(LogicalKeyboardKey.pageUp):
            const FluentCalendarMoveIntent(pages: 1),
        const SingleActivator(LogicalKeyboardKey.pageDown):
            const FluentCalendarMoveIntent(pages: -1),
        const SingleActivator(LogicalKeyboardKey.pageUp, shift: true):
            const FluentCalendarMoveIntent(years: 1),
        const SingleActivator(LogicalKeyboardKey.pageDown, shift: true):
            const FluentCalendarMoveIntent(years: -1),
      },
      child: Actions(
        // No DismissIntent. See the class doc: Escape belongs to whatever hosts
        // the calendar.
        actions: <Type, Action<Intent>>{
          FluentCalendarMoveIntent: CallbackAction<FluentCalendarMoveIntent>(
            onInvoke: (intent) {
              _move(intent);
              return null;
            },
          ),
          FluentCalendarEdgeIntent: CallbackAction<FluentCalendarEdgeIntent>(
            onInvoke: (intent) {
              _edge(intent.edge);
              return null;
            },
          ),
          FluentCalendarViewIntent: CallbackAction<FluentCalendarViewIntent>(
            onInvoke: (_) {
              if (_sideHasFocus) {
                _drillSide();
              } else {
                _drillPrimary();
              }
              return null;
            },
          ),
        },
        child: AnimatedBuilder(
          animation: _slide,
          builder: (context, _) => buildFluentCalendar(
            resolveFluentCalendarState(
              panels: panels,
              view: _primaryView,
              enabled: _enabled,
              slideProgress: _slide.value,
              slideForwards: _forwards,
              onGoToToday: onToday,
              goToTodayLabel: widget.showGoToToday
                  ? widget.strings.goToToday
                  : null,
              semanticLabel: widget.semanticLabel,
            ),
            primaryStyle,
            states,
          ),
        ),
      ),
    );
  }
}
