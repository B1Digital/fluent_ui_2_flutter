import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// DatePicker is a field plus a calendar in an [Overlay], so every section on
/// this page has the same two questions behind it: does the popup open from the
/// affordance the section documents, and does what happens inside it come back
/// out into the field. The calendar's own grid is proven in
/// `compat_components_calendar_test.dart`; the suite below only ever reaches
/// into it far enough to commit a date.
///
/// Expectations are computed from [_today] rather than hard-coded, because
/// every demo here seeds itself from the clock.
void main() {
  const String page = 'compat-components-datepicker';

  group('default', () {
    final DocsSection section = sectionOf(
      'compat-components-datepicker--default',
    );

    testWidgets('the field opens the calendar and a day fills the field', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Select a date...'), findsOneWidget);

      await _open(tester);
      await tapAndSettle(tester, _dayCell(_target), what: 'a day cell');

      expect(
        find.byType(FluentCalendar),
        findsNothing,
        reason: 'picking a day must close the popup',
      );
      expect(_fieldText(tester), fluentFormatDate(_target));
      expect(
        find.text('Select a date...'),
        findsNothing,
        reason: 'the placeholder must give way to the chosen date',
      );

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('a second click on the field closes the calendar', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await _open(tester);

      // Not warnIfMissed: the open popup covers the page with its light-dismiss
      // barrier, so the second click lands there rather than on the faceplate.
      await tapAndSettle(
        tester,
        find.byType(FluentDatePicker),
        what: 'the field, a second time',
        warnIfMissed: false,
      );
      expect(find.byType(FluentCalendar), findsNothing);
      expect(_fieldText(tester), isEmpty);
    });

    testWidgets('a day commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await _open(tester);

      await mouseClick(tester, _dayCell(_target));
      expect(
        _fieldText(tester),
        fluentFormatDate(_target),
        reason: 'a mouse press on a day must commit it, not just dismiss',
      );
    });

    testWidgets('the field opens under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // `mouseClick` moves the pointer two pixels between press and release,
      // which is what a hand does. Anything that only opens under a pixel-
      // perfect press is unreachable with a real mouse, and the faceplate is
      // this control's only affordance. The day cells above are reached with
      // the same gesture and commit fine, so the loss is the faceplate's own.
      await mouseClick(tester, find.byType(FluentDatePicker));
      expect(
        find.byType(FluentCalendar),
        findsOneWidget,
        reason: 'a mouse press on the faceplate must open the popup',
      );
    });
  });

  group('text input', () {
    final DocsSection section = sectionOf(
      'compat-components-datepicker--text-input',
    );

    testWidgets('a typed date is parsed and reformatted on blur', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // ISO in, `M/d/yyyy` out: the rewrite is the proof that the text was
      // parsed and handed to onSelectDate rather than merely left sitting in
      // the controller.
      await typeAndBlur(tester, find.byType(FluentDatePicker), '2026-03-05');
      expect(_fieldText(tester), fluentFormatDate(DateTime(2026, 3, 5)));
    });

    testWidgets('Enter opens the calendar once the field holds focus', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await _open(tester);
      await _escape(tester);
      expect(find.byType(FluentCalendar), findsNothing);

      // Escape hands focus back to the field, which is what makes this the
      // documented keyboard path rather than a lucky one.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(
        find.byType(FluentCalendar),
        findsOneWidget,
        reason: 'Enter on a focused field with no unsaved text must open',
      );
    });
  });

  group('first day of the week', () {
    final DocsSection section = sectionOf(
      'compat-components-datepicker--first-day-of-the-week',
    );

    testWidgets('the dropdown rotates the calendar grid', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await _open(tester);
      expect(
        _columnOf(tester, 'Sunday'),
        lessThan(_columnOf(tester, 'Friday')),
      );
      await _escape(tester);

      final Finder dropdown = find.byType(FluentDropdown<FluentDayOfWeek>);
      expect(
        await pickDropdown<FluentDayOfWeek>(tester, dropdown, 'Friday'),
        FluentDayOfWeek.friday,
      );

      await _open(tester);
      expect(
        _columnOf(tester, 'Friday'),
        lessThan(_columnOf(tester, 'Sunday')),
        reason: 'firstDayOfWeek must move Friday to the leading column',
      );

      await _escape(tester);
      expect(
        await pickDropdown<FluentDayOfWeek>(tester, dropdown, 'Sunday'),
        FluentDayOfWeek.sunday,
      );
      await _open(tester);
      expect(
        _columnOf(tester, 'Sunday'),
        lessThan(_columnOf(tester, 'Friday')),
      );
    });

    testWidgets('the dropdown commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder dropdown = find.byType(FluentDropdown<FluentDayOfWeek>);

      await mouseClick(tester, dropdown);
      expect(
        find.text('Wednesday'),
        findsWidgets,
        reason: 'a mouse press on the trigger must open the listbox',
      );

      await mouseClick(tester, find.text('Wednesday').last);
      expect(
        tester.widget<FluentDropdown<FluentDayOfWeek>>(dropdown).value,
        FluentDayOfWeek.wednesday,
        reason: 'a mouse press on a row must commit, not just dismiss',
      );

      await _open(tester);
      expect(
        _columnOf(tester, 'Wednesday'),
        lessThan(_columnOf(tester, 'Sunday')),
      );
    });
  });

  group('week numbers', () {
    final DocsSection section = sectionOf(
      'compat-components-datepicker--week-numbers',
    );

    testWidgets('the popup numbers every row of its grid', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await _open(tester);

      final int rows = _weeksInMonth(_today);
      expect(find.bySemanticsLabel(RegExp(r'^Week \d+$')), findsNWidgets(rows));
      // firstWeekOfYear is FirstFullWeek here rather than the picker's own
      // default, so the numbers themselves are what proves the flag arrived.
      for (final int week in fluentCalendarWeekNumbers(
        weeksInMonth: rows,
        pickerDate: DateTime.utc(_today.year, _today.month),
        firstWeekOfYear: FluentFirstWeekOfYear.firstFullWeek,
      )) {
        expect(find.bySemanticsLabel('Week $week'), findsWidgets);
      }
    });

    testWidgets('showMonthPickerAsOverlay leaves one panel', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await _open(tester);

      expect(
        find.text('${_today.year}'),
        findsNothing,
        reason: 'a second panel would put a bare year caption on screen',
      );
      await tapAndSettle(tester, find.text(_monthYear(_today)));
      expect(
        find.text('${_today.year}'),
        findsOneWidget,
        reason: 'the day caption must drill to the month grid instead',
      );
    });
  });

  group('date range', () {
    final DocsSection section = sectionOf(
      'compat-components-datepicker--date-range',
    );

    testWidgets('the range dropdown commits and the picker keeps working', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder dropdown = find.byType(FluentDropdown<String>);
      expect(tester.widget<FluentDropdown<String>>(dropdown).value, 'Week');

      // FluentCalendar has no range axis, so this control is documented in the
      // page as live-but-unwired; asserting a range would be asserting a
      // feature the demo never claims to have. What must still hold is that
      // turning it does not break the picker beside it.
      expect(await pickDropdown<String>(tester, dropdown, 'Month'), 'Month');

      await _open(tester);
      await tapAndSettle(tester, _dayCell(_target), what: 'a day cell');
      expect(_fieldText(tester), fluentFormatDate(_target));
    });
  });

  group('date boundaries', () {
    final DocsSection section = sectionOf(
      'compat-components-datepicker--date-boundaries',
    );

    testWidgets('an in-bounds typed date commits', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final DateTime inBounds = DateTime(_today.year, _today.month, 3);

      await typeAndBlur(
        tester,
        find.byType(FluentDatePicker),
        fluentFormatDate(inBounds),
      );
      await _open(tester);
      expect(
        _selectedCell(inBounds),
        findsOneWidget,
        reason: 'the popup must open on the date the field committed',
      );
    });

    testWidgets('an out-of-bounds typed date is refused', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await typeAndBlur(tester, find.byType(FluentDatePicker), '1/1/1990');
      await _open(tester);

      // A commit would have moved the calendar to January 1990 and marked the
      // cell; the page staying on this month is the observable refusal.
      expect(find.text(_monthYear(_today)), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Selected date ')), findsNothing);
    });
  });

  group('custom date formatting', () {
    final DocsSection section = sectionOf(
      'compat-components-datepicker--custom-date-formatting',
    );

    testWidgets('a picked date is written in the custom format', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await _open(tester);
      await tapAndSettle(tester, _dayCell(_target), what: 'a day cell');

      expect(
        _fieldText(tester),
        '${_target.day}/${_target.month}/${_target.year % 100}',
        reason: 'formatDate, not the M/d/yyyy default, owns the field text',
      );
      expect(find.text('Selected date: $_target'), findsOneWidget);
    });

    testWidgets('Clear empties both the field and the readout', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await _open(tester);
      await tapAndSettle(tester, _dayCell(_target), what: 'a day cell');

      await tapAndSettle(tester, find.text('Clear'), what: 'Clear');
      expect(_fieldText(tester), isEmpty);
      expect(find.text('Selected date: '), findsOneWidget);
      expect(find.text('Select a date...'), findsOneWidget);
    });
  });

  group('localized', () {
    final DocsSection section = sectionOf(
      'compat-components-datepicker--localized',
    );

    testWidgets('the chrome and the field speak the supplied strings', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await _open(tester);

      expect(find.text('Ir a hoy'), findsOneWidget);
      expect(
        find.text('Ago'),
        findsOneWidget,
        reason: 'the month cells must come from strings.shortMonths',
      );

      // By day number rather than by announced name: the announcement is what
      // the test below is about, and this one is about the field.
      await tapAndSettle(tester, _dayNumber(_target.day), what: 'a day cell');
      expect(_fieldText(tester), _spanishDate(_target));
    });

    testWidgets('the caption and the cells speak the supplied strings', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await _open(tester);

      // Half a translation is worse than none: the month picker beside this
      // caption already reads Ene/Feb/Mar and the link already reads "Ir a
      // hoy", so a caption in another language is a visible inconsistency
      // inside one surface.
      expect(
        find.text('${_spanishMonths[_today.month - 1]} ${_today.year}'),
        findsOneWidget,
        reason: 'the caption must come from the strings prop',
      );
      expect(
        find.bySemanticsLabel(_spanishDate(_target)),
        findsOneWidget,
        reason: 'a day cell must announce itself with the supplied months',
      );
    });
  });

  group('error handling', () {
    final DocsSection section = sectionOf(
      'compat-components-datepicker--error-handling',
    );

    testWidgets('text that is not a date reports invalidInput', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await typeAndBlur(tester, find.byType(FluentDatePicker), 'not a date');
      expect(
        find.text(defaultFluentDatePickerErrorStrings.invalidInput),
        findsOneWidget,
      );
    });

    testWidgets('a date outside the bounds reports outOfBounds', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await typeAndBlur(tester, find.byType(FluentDatePicker), '1/1/1990');
      expect(
        find.text(defaultFluentDatePickerErrorStrings.outOfBounds),
        findsOneWidget,
      );
    });

    testWidgets('leaving a required field empty reports requiredInput', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await typeAndBlur(tester, find.byType(FluentDatePicker), '');
      expect(
        find.text(defaultFluentDatePickerErrorStrings.requiredInput),
        findsOneWidget,
      );
    });

    testWidgets('a valid date clears the message again', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await typeAndBlur(tester, find.byType(FluentDatePicker), 'not a date');
      expect(
        find.text(defaultFluentDatePickerErrorStrings.invalidInput),
        findsOneWidget,
      );

      await _open(tester);
      await tapAndSettle(tester, _dayCell(_target), what: 'a day cell');
      expect(
        find.text(defaultFluentDatePickerErrorStrings.invalidInput),
        findsNothing,
        reason: 'picking a valid date must retract the error',
      );
    });
  });

  group('controlled', () {
    final DocsSection section = sectionOf(
      'compat-components-datepicker--controlled',
    );

    testWidgets('Next and Previous step the field a day at a time', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_fieldText(tester), isEmpty);

      await tapAndSettle(tester, find.text('Next'), what: 'Next');
      expect(
        _fieldText(tester),
        fluentFormatDate(_today),
        reason: 'the first step seeds the empty picker with today',
      );

      await tapAndSettle(tester, find.text('Next'), what: 'Next');
      expect(_fieldText(tester), fluentFormatDate(_plusDays(_today, 1)));

      await tapAndSettle(tester, find.text('Previous'), what: 'Previous');
      expect(
        _fieldText(tester),
        fluentFormatDate(_today),
        reason: 'stepping back must land on the day it stepped off',
      );
    });
  });

  group('required', () {
    final DocsSection section = sectionOf(
      'compat-components-datepicker--required',
    );

    testWidgets('the label is marked and the picker still commits', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        find.text('*'),
        findsOneWidget,
        reason: 'required must draw the asterisk beside the label',
      );

      await _open(tester);
      await tapAndSettle(tester, _dayCell(_target), what: 'a day cell');
      expect(_fieldText(tester), fluentFormatDate(_target));
    });
  });

  group('disabled', () {
    final DocsSection section = sectionOf(
      'compat-components-datepicker--disabled',
    );

    testWidgets('neither a tap nor a click opens the calendar', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(
        tester,
        find.byType(FluentDatePicker),
        what: 'a disabled field',
      );
      expect(find.byType(FluentCalendar), findsNothing);

      await mouseClick(tester, find.byType(FluentDatePicker));
      expect(
        find.byType(FluentCalendar),
        findsNothing,
        reason: 'a null onSelectDate must refuse the pointer entirely',
      );
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

    testWidgets('a section unmounts with its popup still open', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf(
        'compat-components-datepicker--default',
      );
      await pumpSection(tester, section);
      await _open(tester);

      // The overlay entry outlives the widget unless dispose removes it, and
      // that is exactly the class of defect `render_test` cannot see.
      await expectCleanTeardown(tester, 'the open popup');
    });
  });
}

/// The clock every demo on this page is seeded from, read once.
final DateTime _today = DateTime.now();

/// A day of the current month that is never today.
final DateTime _target = DateTime(
  _today.year,
  _today.month,
  _today.day == 15 ? 16 : 15,
);

/// The month names the Localized section supplies.
const List<String> _spanishMonths = <String>[
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

/// Opens the popup from the field and proves it arrived.
Future<void> _open(WidgetTester tester) async {
  await tapAndSettle(
    tester,
    find.byType(FluentDatePicker),
    what: 'the date picker field',
    warnIfMissed: false,
  );
  expect(
    find.byType(FluentCalendar),
    findsOneWidget,
    reason: 'clicking the field must open the calendar popup',
  );
}

/// Dismisses the popup with the key the picker documents for it.
Future<void> _escape(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);
  await settle(tester);
  expectClean(tester, 'pressing Escape');
}

/// What the faceplate currently holds.
String _fieldText(WidgetTester tester) =>
    editedText(tester, find.byType(FluentDatePicker));

/// The x of the weekday header named [day], which is what `firstDayOfWeek`
/// rotates.
///
/// Scoped to the popup: the First Day Of The Week demo lists the same seven
/// names in a dropdown, and its trigger renders the chosen one, so an unscoped
/// finder matches two nodes as soon as the knob is turned.
double _columnOf(WidgetTester tester, String day) => tester
    .getRect(
      find.descendant(
        of: find.byType(FluentCalendar),
        matching: find.bySemanticsLabel(day),
      ),
    )
    .left;

String _monthYear(DateTime date) =>
    fluentFormatCalendarMonthYear(date, FluentCalendarStrings.english);

String _fullDate(DateTime date) =>
    fluentFormatCalendarMonthDayYear(date, FluentCalendarStrings.english);

/// Day arithmetic through the constructor rather than [Duration], which drifts
/// by an hour across a daylight-saving boundary.
DateTime _plusDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

/// A day cell in the open popup, addressed by what it announces.
Finder _dayCell(DateTime date) => find.bySemanticsLabel(_fullDate(date));

/// A day cell addressed by the number it draws.
///
/// Only safe for a day in the middle of the month — the first and last few
/// numbers appear twice in a grid that spills into its neighbours.
Finder _dayNumber(int day) => find.descendant(
  of: find.byType(FluentCalendar),
  matching: find.text('$day'),
);

/// [date] written with the month names the Localized section supplies.
String _spanishDate(DateTime date) =>
    '${_spanishMonths[date.month - 1]} ${date.day}, ${date.year}';

/// The same cell once it holds the picker's value.
Finder _selectedCell(DateTime date) =>
    find.bySemanticsLabel('Selected date ${_fullDate(date)}');

/// How many rows a Sunday-first grid needs for [month].
int _weeksInMonth(DateTime month) {
  final int lead = DateTime.utc(month.year, month.month).weekday % 7;
  final int days = DateTime.utc(month.year, month.month + 1, 0).day;
  return ((lead + days) / 7).ceil();
}
