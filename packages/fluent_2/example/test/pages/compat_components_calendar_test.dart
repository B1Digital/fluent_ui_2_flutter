import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Calendar's page is thirteen calendars that differ by one flag each, so the
/// interesting question per section is never "does it render" — `render_test`
/// settles that — but "does the flag reach the grid, and does the readout the
/// demo prints under it ever move". Each group below drives the affordance its
/// section exists to demonstrate and asserts the *demo* changed: a caption, a
/// selected cell, a derived range.
///
/// Every expectation is computed from [_today] with the same arithmetic the
/// page uses, because these demos are seeded from the clock: hard-coding a
/// date would pass in August and fail in September.
void main() {
  const String page = 'compat-components-calendar';

  group('default', () {
    final DocsSection section = sectionOf(
      'compat-components-calendar--default',
    );

    testWidgets('a day cell commits the selection', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_selectedCell(_target), findsNothing);

      await tapAndSettle(tester, _dayCell(_target), what: 'a day cell');
      expect(
        _selectedCell(_target),
        findsOneWidget,
        reason: 'the tapped day must come back announced as selected',
      );

      // A single-date calendar, so the second pick has to move the selection
      // rather than add to it — the defect would be a grid that paints two.
      final DateTime other = _plusDays(_target, 1);
      await tapAndSettle(tester, _dayCell(other), what: 'a second day cell');
      expect(_selectedCell(other), findsOneWidget);
      expect(_selectedCell(_target), findsNothing);

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('a day cell commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, _dayCell(_target));
      expect(
        _selectedCell(_target),
        findsOneWidget,
        reason:
            'a mouse press must select the day, not merely hover it — the cell '
            'is a FluentInteractive, whose press path differs from a tap',
      );
    });

    testWidgets('the chevrons page each panel on its own', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text(_monthYear(_today)), findsOneWidget);
      expect(find.text('${_today.year}'), findsOneWidget);

      final DateTime nextMonth = DateTime(_today.year, _today.month + 1);
      await tapAndSettle(tester, find.bySemanticsLabel('Next month'));
      expect(find.text(_monthYear(nextMonth)), findsOneWidget);
      expect(
        find.text('${_today.year}'),
        findsOneWidget,
        reason: 'paging the day grid must leave the month picker where it was',
      );

      await tapAndSettle(tester, find.bySemanticsLabel('Next year'));
      expect(find.text('${_today.year + 1}'), findsOneWidget);
      expect(
        find.text(_monthYear(nextMonth)),
        findsOneWidget,
        reason: 'paging the month picker must leave the day grid where it was',
      );

      await tapAndSettle(tester, find.bySemanticsLabel('Previous month'));
      expect(find.text(_monthYear(_today)), findsOneWidget);
    });

    testWidgets('the month picker moves the day grid', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // A month cell beside the day grid navigates rather than selects, so the
      // day caption is the only thing that may move.
      final int month = _today.month == 12 ? 1 : 12;
      final String label = FluentCalendarStrings.english.shortMonths[month - 1];
      await tapAndSettle(tester, find.text(label), what: 'a month cell');

      expect(
        find.text(_monthYear(DateTime(_today.year, month))),
        findsOneWidget,
        reason: 'activating a month cell must page the day grid to that month',
      );
    });

    testWidgets('the month caption drills out to the decade grid and back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(
        tester,
        find.text('${_today.year}'),
        what: 'the year caption',
      );
      expect(
        find.text('${_today.year} - ${_today.year + 11}'),
        findsOneWidget,
        reason: 'the year caption must drill to a twelve-year block',
      );

      await tapAndSettle(tester, find.text('${_today.year + 2}'));
      expect(
        find.text('${_today.year + 2}'),
        findsOneWidget,
        reason: 'activating a year cell must come back on that year',
      );
      expect(find.text('${_today.year} - ${_today.year + 11}'), findsNothing);
    });

    testWidgets('go to today returns a paged grid', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tapAndSettle(tester, find.bySemanticsLabel('Next month'));
      expect(find.text(_monthYear(_today)), findsNothing);

      await tapAndSettle(tester, find.text('Go to today'));
      expect(
        find.text(_monthYear(_today)),
        findsOneWidget,
        reason: 'the link must page the day grid back to the current month',
      );
    });
  });

  group('calendar month only', () {
    final DocsSection section = sectionOf(
      'compat-components-calendar--calendar-month-only',
    );

    testWidgets('the panel is a month grid, with no day cells', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(find.text('${_today.year}'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Sunday'),
        findsNothing,
        reason: 'isDayPickerVisible: false must drop the weekday header too',
      );
      for (final String month in FluentCalendarStrings.english.shortMonths) {
        expect(find.text(month), findsOneWidget);
      }
    });

    testWidgets('the year chevrons page the month grid', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(tester, find.bySemanticsLabel('Next year'));
      expect(find.text('${_today.year + 1}'), findsOneWidget);
      await tapAndSettle(tester, find.bySemanticsLabel('Previous year'));
      expect(find.text('${_today.year}'), findsOneWidget);
    });

    testWidgets('the caption drills out to the decade grid', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(tester, find.text('${_today.year}'));
      expect(find.text('${_today.year} - ${_today.year + 11}'), findsOneWidget);
    });

    testWidgets('activating a month cell fills the readouts', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Selected date: Not set'), findsOneWidget);
      expect(find.text('Selected range: Not set'), findsOneWidget);

      final int month = _today.month == 12 ? 1 : 12;
      final String label = FluentCalendarStrings.english.shortMonths[month - 1];
      await tapAndSettle(tester, find.text(label), what: 'a month cell');

      // The two readouts are this demo's whole output, and with the day grid
      // hidden a month cell is the only affordance that could ever fill them.
      // A calendar whose only cells neither select nor navigate has no working
      // interaction at all.
      expect(
        find.text('Selected date: Not set'),
        findsNothing,
        reason: 'activating a month cell must report a selection',
      );
      expect(find.text('Selected range: Not set'), findsNothing);
    });

    testWidgets('a month cell responds under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final String before = textSnapshot(tester);

      final int month = _today.month == 12 ? 1 : 12;
      await mouseClick(
        tester,
        find.text(FluentCalendarStrings.english.shortMonths[month - 1]),
      );

      expect(
        textSnapshot(tester),
        isNot(before),
        reason: 'a mouse press on a month cell changed nothing on the page',
      );
    });
  });

  group('calendar overlaid month', () {
    final DocsSection section = sectionOf(
      'compat-components-calendar--calendar-overlaid-month',
    );

    testWidgets('the day caption drills to the month grid and back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // One panel, so the caption has somewhere to drill to — the whole point
      // of showMonthPickerAsOverlay.
      expect(find.text('${_today.year}'), findsNothing);

      await tapAndSettle(tester, find.text(_monthYear(_today)));
      expect(
        find.text('${_today.year}'),
        findsOneWidget,
        reason: 'the day caption must swap the panel for the month grid',
      );
      expect(find.bySemanticsLabel('Sunday'), findsNothing);

      final int month = _today.month == 12 ? 1 : 12;
      final String label = FluentCalendarStrings.english.shortMonths[month - 1];
      await tapAndSettle(tester, find.text(label));
      expect(
        find.text(_monthYear(DateTime(_today.year, month))),
        findsOneWidget,
        reason: 'a month cell must drill back in to that month of days',
      );
      expect(find.bySemanticsLabel('Sunday'), findsOneWidget);
    });

    testWidgets('a day cell fills the readout', (WidgetTester tester) async {
      await pumpSection(tester, section);
      expect(find.text('Selected date: Not set'), findsOneWidget);

      await tapAndSettle(tester, _dayCell(_target));
      expect(find.text('Selected date: ${_fullDate(_target)}'), findsOneWidget);
    });

    testWidgets('showGoToToday: false draws no link', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Go to today'), findsNothing);
    });
  });

  group('calendar date boundaries', () {
    final DocsSection section = sectionOf(
      'compat-components-calendar--calendar-date-boundaries',
    );

    testWidgets('a restricted day refuses the selection', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final DateTime restricted = _restrictedDates.firstWhere(
        (DateTime date) => _dayCell(date).evaluate().isNotEmpty,
        orElse: () => fail('no restricted day is on the current page'),
      );
      await tapAndSettle(
        tester,
        _dayCell(restricted),
        what: 'a restricted day',
        warnIfMissed: false,
      );
      expect(
        find.text('Selected date: Not set'),
        findsOneWidget,
        reason: 'a day listed in restrictedDates must not be selectable',
      );

      await tapAndSettle(tester, _dayCell(_openDay));
      expect(
        find.text('Selected date: ${_fullDate(_openDay)}'),
        findsOneWidget,
        reason: 'restrictedDates must not disable the rest of the month',
      );
    });

    testWidgets('the previous chevron stops at minDate', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // minDate sits one month back, so exactly one step is legal; the third
      // press has to be a no-op rather than an unbounded walk backwards.
      for (int i = 0; i < 3; i++) {
        await tapAndSettle(
          tester,
          find.bySemanticsLabel('Previous month'),
          warnIfMissed: false,
        );
      }
      expect(
        find.text(_monthYear(_minDate)),
        findsOneWidget,
        reason: 'paging must stop on the page holding minDate',
      );
    });
  });

  group('calendar six weeks', () {
    final DocsSection section = sectionOf(
      'compat-components-calendar--calendar-six-weeks',
    );

    testWidgets('a day cell fills the readout and the chevrons page', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(tester, _dayCell(_target));
      expect(find.text('Selected date: ${_fullDate(_target)}'), findsOneWidget);

      await tapAndSettle(tester, find.bySemanticsLabel('Next month'));
      expect(
        find.text(_monthYear(DateTime(_today.year, _today.month + 1))),
        findsOneWidget,
      );
      expect(
        find.text('Selected date: ${_fullDate(_target)}'),
        findsOneWidget,
        reason: 'paging away from the selection must not clear it',
      );
    });
  });

  group('calendar week numbers', () {
    final DocsSection section = sectionOf(
      'compat-components-calendar--calendar-week-numbers',
    );

    testWidgets('the week column numbers every row of the grid', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final int rows = _weeksInMonth(_today);
      final List<int> weeks = fluentCalendarWeekNumbers(
        weeksInMonth: rows,
        pickerDate: DateTime.utc(_today.year, _today.month),
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Week \d+$')),
        findsNWidgets(rows),
        reason: 'showWeekNumbers must draw one cell per grid row',
      );
      for (final int week in weeks) {
        expect(find.bySemanticsLabel('Week $week'), findsWidgets);
      }
    });

    testWidgets('a day cell still selects beside the week column', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(tester, _dayCell(_target));
      expect(find.text('Selected date: ${_fullDate(_target)}'), findsOneWidget);
    });
  });

  group('calendar week selection', () {
    final DocsSection section = sectionOf(
      'compat-components-calendar--calendar-week-selection',
    );

    testWidgets('a day cell reports the whole week it falls in', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Selected range: Not set'), findsOneWidget);

      await tapAndSettle(tester, _dayCell(_target));
      final List<DateTime> week = _weekOf(_target, FluentDayOfWeek.sunday);
      expect(
        find.text(
          'Selected range: ${_fullDate(week.first)}-${_fullDate(week.last)}',
        ),
        findsOneWidget,
        reason: 'the readout must span Sunday through Saturday of that week',
      );
    });

    testWidgets('Next and Previous step the selection off the week', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tapAndSettle(tester, _dayCell(_target));
      final List<DateTime> week = _weekOf(_target, FluentDayOfWeek.sunday);

      await tapAndSettle(tester, find.text('Next'), what: 'Next');
      final DateTime after = _plusDays(week.last, 1);
      expect(
        find.text('Selected date: ${_fullDate(after)}'),
        findsOneWidget,
        reason: 'Next must land on the day after the selected week',
      );

      // Previous is not Next's inverse, and deliberately so: upstream walks to
      // the day before the first of the month the selected week starts in.
      await tapAndSettle(tester, find.text('Previous'), what: 'Previous');
      final DateTime weekStart = _weekOf(after, FluentDayOfWeek.sunday).first;
      final DateTime before = _plusDays(
        DateTime(weekStart.year, weekStart.month),
        -1,
      );
      expect(find.text('Selected date: ${_fullDate(before)}'), findsOneWidget);
    });
  });

  group('calendar marked days', () {
    final DocsSection section = sectionOf(
      'compat-components-calendar--calendar-marked-days',
    );

    testWidgets('the readout starts on today and follows the grid', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Selected date: ${_fullDate(_today)}'), findsOneWidget);
      expect(_selectedCell(_today), findsOneWidget);

      await tapAndSettle(tester, _dayCell(_target));
      expect(find.text('Selected date: ${_fullDate(_target)}'), findsOneWidget);
    });
  });

  group('calendar month selection', () {
    final DocsSection section = sectionOf(
      'compat-components-calendar--calendar-month-selection',
    );

    testWidgets('a day cell reports the whole month it falls in', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(tester, _dayCell(_target));
      final DateTime first = DateTime(_target.year, _target.month);
      final DateTime last = DateTime(_target.year, _target.month + 1, 0);
      expect(
        find.text('Selected range: ${_fullDate(first)}-${_fullDate(last)}'),
        findsOneWidget,
      );
    });

    testWidgets('Next steps the selection into the following month', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tapAndSettle(tester, _dayCell(_target));

      await tapAndSettle(tester, find.text('Next'), what: 'Next');
      final DateTime nextMonth = DateTime(_target.year, _target.month + 1);
      expect(
        find.text('Selected date: ${_fullDate(nextMonth)}'),
        findsOneWidget,
        reason: 'Next must land on the first day of the following month',
      );
      expect(
        find.text(
          'Selected range: ${_fullDate(nextMonth)}-'
          '${_fullDate(DateTime(_target.year, _target.month + 2, 0))}',
        ),
        findsOneWidget,
      );
    });
  });

  group('calendar multiday day view', () {
    final DocsSection section = sectionOf(
      'compat-components-calendar--calendar-multiday-day-view',
    );

    Finder calendar(int index) => find.byType(FluentCalendar).at(index);

    Finder dayIn(int index, DateTime date) =>
        find.descendant(of: calendar(index), matching: _dayCell(date));

    testWidgets('a day cell reports the run of days it anchors', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(tester, dayIn(0, _target), what: 'a day cell');
      expect(
        find.text(
          'Selected range: ${_fullDate(_target)}-'
          '${_fullDate(_plusDays(_target, 3))}',
        ),
        findsOneWidget,
        reason: 'the default knob is 4 days, counted forwards from the pick',
      );
    });

    testWidgets('the second calendar counts the run backwards', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(tester, dayIn(1, _target), what: 'a day cell');
      expect(
        find.text(
          'Selected range: ${_fullDate(_plusDays(_target, -3))}-'
          '${_fullDate(_target)}',
        ),
        findsOneWidget,
        reason: 'the negative-range calendar must end on the picked day',
      );
    });

    testWidgets('the days dropdown re-reports the selected run', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tapAndSettle(tester, dayIn(0, _target), what: 'a day cell');

      final Finder dropdown = find.byType(FluentDropdown<String>);
      expect(await pickDropdown<String>(tester, dropdown, '6'), '6');

      // The knob's whole job is the length of the highlighted run. Leaving the
      // readout on the previous length until the user happens to pick another
      // day makes the control look inert.
      expect(
        find.text(
          'Selected range: ${_fullDate(_target)}-'
          '${_fullDate(_plusDays(_target, 5))}',
        ),
        findsOneWidget,
        reason: 'turning the knob must re-report the run already selected',
      );
    });

    testWidgets('the days dropdown drives the next selection', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder dropdown = find.byType(FluentDropdown<String>);
      expect(await pickDropdown<String>(tester, dropdown, '2'), '2');

      await tapAndSettle(tester, dayIn(0, _target), what: 'a day cell');
      expect(
        find.text(
          'Selected range: ${_fullDate(_target)}-'
          '${_fullDate(_plusDays(_target, 1))}',
        ),
        findsOneWidget,
        reason: 'a pick after the knob moved must use the new length',
      );
    });

    testWidgets('the days dropdown commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder dropdown = find.byType(FluentDropdown<String>);

      await mouseClick(tester, dropdown);
      expect(
        find.text('5'),
        findsWidgets,
        reason: 'a mouse press on the trigger must open the listbox',
      );

      await mouseClick(tester, find.text('5').last);
      expect(
        tester.widget<FluentDropdown<String>>(dropdown).value,
        '5',
        reason: 'a mouse press on a row must commit, not just dismiss',
      );
    });
  });

  group('calendar contiguous work week days', () {
    final DocsSection section = sectionOf(
      'compat-components-calendar--calendar-contiguous-work-week-days',
    );

    testWidgets('a day cell reports Monday through Friday of its week', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(tester, _dayCell(_target));
      final List<DateTime> week = _weekOf(_target, FluentDayOfWeek.sunday);
      expect(
        find.text(
          'Selected range: ${_fullDate(week[1])}-${_fullDate(week[5])}',
        ),
        findsOneWidget,
        reason: 'the five work days run from the Monday to the Friday',
      );
    });

    testWidgets('the grid starts on Sunday', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await settle(tester, frames: 10);

      expect(
        tester.getRect(find.bySemanticsLabel('Sunday')).left,
        lessThan(tester.getRect(find.bySemanticsLabel('Monday')).left),
      );
    });
  });

  group('calendar non contiguous work week days', () {
    final DocsSection section = sectionOf(
      'compat-components-calendar--calendar-non-contiguous-work-week-days',
    );

    testWidgets('a day cell reports the scattered work days it bounds', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(tester, _dayCell(_target));
      // firstDayOfWeek is Monday here, so the row runs Mon..Sun and the four
      // work days — Tue, Wed, Fri, Sat — are its columns 1, 2, 4 and 5.
      final List<DateTime> week = _weekOf(_target, FluentDayOfWeek.monday);
      expect(
        find.text(
          'Selected range: ${_fullDate(week[1])}-${_fullDate(week[5])}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('firstDayOfWeek rotates the grid to Monday', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await settle(tester, frames: 10);

      expect(
        tester.getRect(find.bySemanticsLabel('Monday')).left,
        lessThan(tester.getRect(find.bySemanticsLabel('Sunday')).left),
        reason: 'firstDayOfWeek: monday must move Sunday to the last column',
      );
    });
  });

  group('calendar custom day cell ref', () {
    final DocsSection section = sectionOf(
      'compat-components-calendar--calendar-custom-day-cell-ref',
    );

    testWidgets('the weekends are restricted and the weekdays are not', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final DateTime saturday = _firstWeekday(DateTime.saturday);
      await tapAndSettle(
        tester,
        _dayCell(saturday),
        what: 'a weekend day',
        warnIfMissed: false,
      );
      expect(
        find.text('Selected date: Not set'),
        findsOneWidget,
        reason: 'every weekend goes through restrictedDates',
      );

      final DateTime weekday = _firstWeekday(DateTime.wednesday);
      await tapAndSettle(tester, _dayCell(weekday));
      expect(find.text('Selected date: ${_fullDate(weekday)}'), findsOneWidget);
    });

    testWidgets('hovering the calendar shows the tooltip', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The tooltip is this section's stand-in for upstream's per-cell `title`
      // attribute, and hover is the only way to reach it — a synthetic tap
      // would never show it.
      final TestGesture mouse = await mouseHover(
        tester,
        find.byType(FluentCalendar),
      );
      expect(
        find.textContaining('custom title from customDayCellRef'),
        findsOneWidget,
        reason: 'a 250ms hover must raise the tooltip surface',
      );
      await mouseAway(tester, mouse);
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// The clock every demo on this page is seeded from.
///
/// Read once: a suite that straddled midnight would otherwise build half its
/// expectations from one day and half from the next.
final DateTime _today = DateTime.now();

/// A day of the current month that is never today, so its cell announces the
/// plain date rather than "Today's date".
final DateTime _target = DateTime(
  _today.year,
  _today.month,
  _today.day == 15 ? 16 : 15,
);

/// The boundaries demo's own `minDate`, transcribed from the page.
final DateTime _minDate = DateTime(_today.year, _today.month - 1, _today.day);

/// The boundaries demo's own `restrictedDates`, transcribed from the page.
final List<DateTime> _restrictedDates = <DateTime>[
  DateTime(_today.year, _today.month, _today.day - 2),
  DateTime(_today.year, _today.month, _today.day - 8),
  DateTime(_today.year, _today.month, _today.day + 2),
  DateTime(_today.year, _today.month, _today.day + 8),
];

/// The first day of the current month the boundaries demo leaves selectable.
final DateTime _openDay = () {
  for (int day = 1; day <= 28; day++) {
    final DateTime candidate = DateTime(_today.year, _today.month, day);
    final bool blocked = _restrictedDates.any(
      (DateTime date) => fluentCalendarIsSameDay(date, candidate),
    );
    if (!blocked && !fluentCalendarIsSameDay(candidate, _today)) {
      return candidate;
    }
  }
  throw StateError('every day of the month is restricted');
}();

String _monthYear(DateTime date) =>
    fluentFormatCalendarMonthYear(date, FluentCalendarStrings.english);

String _fullDate(DateTime date) =>
    fluentFormatCalendarMonthDayYear(date, FluentCalendarStrings.english);

/// Day arithmetic through the constructor rather than [Duration], which drifts
/// by an hour across a daylight-saving boundary and can land back on the same
/// date.
DateTime _plusDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

/// A day cell, addressed by what it announces — the label is the full date, so
/// a trailing `1` from the next month cannot be confused for this month's.
Finder _dayCell(DateTime date) => find.bySemanticsLabel(_fullDate(date));

/// The same cell once it holds the selection.
Finder _selectedCell(DateTime date) =>
    find.bySemanticsLabel('Selected date ${_fullDate(date)}');

/// The seven days of [date]'s week, in grid order for [firstDayOfWeek].
List<DateTime> _weekOf(DateTime date, FluentDayOfWeek firstDayOfWeek) {
  final int offset = (date.weekday % 7 - firstDayOfWeek.index) % 7;
  return <DateTime>[for (int i = 0; i < 7; i++) _plusDays(date, i - offset)];
}

/// How many rows a Sunday-first grid needs for [month].
int _weeksInMonth(DateTime month) {
  final int lead = DateTime.utc(month.year, month.month).weekday % 7;
  final int days = DateTime.utc(month.year, month.month + 1, 0).day;
  return ((lead + days) / 7).ceil();
}

/// The first [weekday] of the current month, as a local date.
DateTime _firstWeekday(int weekday) {
  for (int day = 1; day <= 7; day++) {
    final DateTime candidate = DateTime(_today.year, _today.month, day);
    if (candidate.weekday == weekday) return candidate;
  }
  throw StateError('no $weekday in the first week of the month');
}
