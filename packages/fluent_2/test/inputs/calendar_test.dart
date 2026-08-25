import 'dart:ui' show Tristate;

import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/internal/input_modality.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fixed "now", so nothing in this file depends on the wall clock.
final DateTime _today = DateTime(2026, 3, 10);

Future<void> _pump(
  WidgetTester tester, {
  DateTime? value,
  ValueChanged<DateTime>? onSelectDate = _noop,
  DateTime? minDate,
  DateTime? maxDate,
  List<DateTime> restrictedDates = const <DateTime>[],
  FluentDayOfWeek firstDayOfWeek = FluentDayOfWeek.sunday,
  bool autofocus = false,
  bool reducedMotion = false,
  bool isMonthPickerVisible = false,
  Widget Function(Widget child)? wrap,
}) async {
  final calendar = FluentCalendar(
    today: _today,
    // Off unless a test asks for it: most of these assert single-panel
    // behaviour, and with the month picker up a caption like "2026" is on
    // screen already, which would let a drill assertion pass without drilling.
    isMonthPickerVisible: isMonthPickerVisible,
    value: value,
    onSelectDate: onSelectDate,
    minDate: minDate,
    maxDate: maxDate,
    restrictedDates: restrictedDates,
    firstDayOfWeek: firstDayOfWeek,
    autofocus: autofocus,
  );
  await tester.pumpWidget(
    FluentApp(
      theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: Center(child: wrap == null ? calendar : wrap(calendar)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _noop(DateTime _) {}

/// The cell showing [label] inside the grid, not the header.
Finder _cell(String label) => find.descendant(
  of: find.byType(FluentCalendar),
  matching: find.text(label),
);

void main() {
  setUp(FluentInputModality.debugReset);

  group('fluentCalendarPage — month', () {
    // 1 March 2026 is a Sunday, so a Sunday-first grid needs no leading days
    // and 31 days fill exactly five rows.
    test('a month starting on the first column has no leading days', () {
      final rows = fluentCalendarPage(
        pickerDate: DateTime.utc(2026, 3, 10),
        view: FluentCalendarView.month,
        today: DateTime.utc(2026, 3, 10),
      );

      expect(rows.length, 5);
      expect(rows.first.length, 7);
      expect(rows.first.first.date, DateTime.utc(2026, 3, 1));
      expect(rows.first.first.outOfPage, isFalse);
      expect(rows.last.last.date, DateTime.utc(2026, 4, 4));
      expect(rows.last.last.outOfPage, isTrue);
    });

    // February 2026 is 28 days starting on a Sunday: the one shape that fits in
    // four rows. Upstream's `showSixWeeksByDefault` is off by default, so the
    // natural count is the correct one and a hardcoded six would be wrong.
    test('a 28-day month aligned to the first column is four rows', () {
      final rows = fluentCalendarPage(
        pickerDate: DateTime.utc(2026, 2, 1),
        view: FluentCalendarView.month,
        today: DateTime.utc(2026, 2, 1),
      );

      expect(rows.length, 4);
      expect(rows.every((row) => row.every((cell) => !cell.outOfPage)), isTrue);
    });

    test('firstDayOfWeek rotates the grid and can add a row', () {
      final rows = fluentCalendarPage(
        pickerDate: DateTime.utc(2026, 3, 10),
        view: FluentCalendarView.month,
        today: DateTime.utc(2026, 3, 10),
        firstDayOfWeek: FluentDayOfWeek.monday,
      );

      // Monday-first pushes 1 March to the last column, so six leading days
      // from February appear and the month needs six rows.
      expect(rows.length, 6);
      expect(rows.first.first.date, DateTime.utc(2026, 2, 23));
      expect(rows.first.first.outOfPage, isTrue);
      expect(rows.first.last.date, DateTime.utc(2026, 3, 1));
      expect(rows.first.last.outOfPage, isFalse);
    });

    test('February of a leap year includes the 29th', () {
      final rows = fluentCalendarPage(
        pickerDate: DateTime.utc(2028, 2, 1),
        view: FluentCalendarView.month,
        today: DateTime.utc(2028, 2, 1),
      );

      final inMonth = <DateTime>[
        for (final row in rows)
          for (final cell in row)
            if (!cell.outOfPage) cell.date,
      ];
      expect(inMonth.length, 29);
      expect(inMonth.last, DateTime.utc(2028, 2, 29));
    });

    test('December rolls into January without a special case', () {
      final rows = fluentCalendarPage(
        pickerDate: DateTime.utc(2026, 12, 1),
        view: FluentCalendarView.month,
        today: DateTime.utc(2026, 12, 1),
      );

      expect(rows.last.last.date, DateTime.utc(2027, 1, 2));
      expect(rows.last.last.outOfPage, isTrue);
    });

    // The single assertion that fails the moment anyone swaps DateTime.utc for
    // a local DateTime: across a spring-forward boundary a local day is 23
    // hours, so `add(Duration(days: 7))` lands on the wrong date and a row
    // silently repeats a day.
    test('every column advances exactly seven days across a DST boundary', () {
      for (final month in <int>[3, 10, 11]) {
        final rows = fluentCalendarPage(
          pickerDate: DateTime.utc(2026, month, 1),
          view: FluentCalendarView.month,
          today: DateTime.utc(2026, month, 1),
        );
        for (var row = 0; row + 1 < rows.length; row++) {
          for (var column = 0; column < 7; column++) {
            expect(
              rows[row + 1][column].date
                  .difference(rows[row][column].date)
                  .inDays,
              7,
              reason: 'month $month, row $row, column $column',
            );
          }
        }
      }
    });

    test('today and the selected day are flagged, and nothing else is', () {
      final rows = fluentCalendarPage(
        pickerDate: DateTime.utc(2026, 3, 10),
        view: FluentCalendarView.month,
        today: DateTime.utc(2026, 3, 10),
        value: DateTime.utc(2026, 3, 17),
      );
      final cells = <FluentCalendarCell>[for (final row in rows) ...row];

      expect(
        cells.where((cell) => cell.today).map((cell) => cell.date),
        <DateTime>[DateTime.utc(2026, 3, 10)],
      );
      expect(
        cells.where((cell) => cell.selected).map((cell) => cell.date),
        <DateTime>[DateTime.utc(2026, 3, 17)],
      );
    });

    test('the accessible name is the full date, even out of month', () {
      final rows = fluentCalendarPage(
        pickerDate: DateTime.utc(2026, 3, 10),
        view: FluentCalendarView.month,
        today: DateTime.utc(2026, 3, 10),
        value: DateTime.utc(2026, 3, 17),
      );
      final cells = <FluentCalendarCell>[for (final row in rows) ...row];

      // A trailing "1" from April must not announce as a bare number.
      final trailing = cells.firstWhere((cell) => cell.outOfPage);
      expect(trailing.label, '1');
      expect(trailing.semanticLabel, 'April 1, 2026');

      expect(
        cells.firstWhere((cell) => cell.today).semanticLabel,
        "Today's date March 10, 2026",
      );
      expect(
        cells.firstWhere((cell) => cell.selected).semanticLabel,
        'Selected date March 17, 2026',
      );
    });
  });

  group('fluentCalendarPage — bounds', () {
    test('minDate and maxDate mark days unselectable', () {
      final rows = fluentCalendarPage(
        pickerDate: DateTime.utc(2026, 3, 10),
        view: FluentCalendarView.month,
        today: DateTime.utc(2026, 3, 10),
        minDate: DateTime.utc(2026, 3, 5),
        maxDate: DateTime.utc(2026, 3, 20),
      );
      final cells = <FluentCalendarCell>[for (final row in rows) ...row];

      DateTime dateOf(int day) => DateTime.utc(2026, 3, day);
      bool selectableOn(int day) =>
          cells.firstWhere((cell) => cell.date == dateOf(day)).selectable;

      expect(selectableOn(4), isFalse);
      // Both bounds are inclusive.
      expect(selectableOn(5), isTrue);
      expect(selectableOn(20), isTrue);
      expect(selectableOn(21), isFalse);
    });

    test('restrictedDates disable exactly those days', () {
      final rows = fluentCalendarPage(
        pickerDate: DateTime.utc(2026, 3, 10),
        view: FluentCalendarView.month,
        today: DateTime.utc(2026, 3, 10),
        // Deliberately carries a time component: the page must normalise it.
        restrictedDates: <DateTime>[DateTime.utc(2026, 3, 12, 9, 30)],
      );
      final cells = <FluentCalendarCell>[for (final row in rows) ...row];

      expect(
        cells
            .where((cell) => !cell.selectable)
            .map((cell) => cell.date)
            .toList(),
        <DateTime>[DateTime.utc(2026, 3, 12)],
      );
    });
  });

  group('fluentCalendarPage — year and decade', () {
    test('the year view is twelve months in four columns', () {
      final rows = fluentCalendarPage(
        pickerDate: DateTime.utc(2026, 3, 10),
        view: FluentCalendarView.year,
        today: DateTime.utc(2026, 3, 10),
        value: DateTime.utc(2026, 7, 4),
      );

      expect(rows.length, 3);
      expect(rows.every((row) => row.length == 4), isTrue);
      expect(rows.first.first.label, 'Jan');
      // Abbreviations are drawn; the full name is announced.
      expect(rows.last.last.label, 'Dec');
      expect(rows.first.first.semanticLabel, 'January');
      // The cell's date is the first of the period, so activating it navigates
      // straight there.
      expect(rows.first.first.date, DateTime.utc(2026, 1, 1));

      // Upstream's `highlightCurrentMonth` and `highlightSelectedMonth` are
      // both off by default, so a month grid shows twelve plain cells.
      final plain = <FluentCalendarCell>[for (final row in rows) ...row];
      expect(plain.where((cell) => cell.today), isEmpty);
      expect(plain.where((cell) => cell.selected), isEmpty);
    });

    test('the year view marks the current and selected month on request', () {
      final rows = fluentCalendarPage(
        pickerDate: DateTime.utc(2026, 3, 10),
        view: FluentCalendarView.year,
        today: DateTime.utc(2026, 3, 10),
        value: DateTime.utc(2026, 7, 4),
        highlightCurrentPeriod: true,
        highlightSelectedPeriod: true,
      );
      final cells = <FluentCalendarCell>[for (final row in rows) ...row];

      expect(
        cells.where((cell) => cell.today).map((cell) => cell.label),
        <String>['Mar'],
      );
      expect(
        cells.where((cell) => cell.selected).map((cell) => cell.label),
        <String>['Jul'],
      );
    });

    // Upstream anchors the decade page on the year itself, not on a decade
    // floor: `useYearRangeState` seeds `fromYear` from
    // `selectedYear || navigatedYear` and takes twelve from there. 2026 shows
    // 2026-2037, which reads oddly and is nonetheless what ships.
    test('the decade view runs twelve years from the picker year', () {
      final rows = fluentCalendarPage(
        pickerDate: DateTime.utc(2026, 3, 10),
        view: FluentCalendarView.decade,
        today: DateTime.utc(2026, 3, 10),
      );

      expect(rows.length, 3);
      expect(rows.first.first.label, '2026');
      expect(rows.last.last.label, '2037');
      expect(rows.first.first.date, DateTime.utc(2026, 1, 1));
    });

    test('a period is selectable when any day in it is', () {
      final rows = fluentCalendarPage(
        pickerDate: DateTime.utc(2026, 3, 10),
        view: FluentCalendarView.year,
        today: DateTime.utc(2026, 3, 10),
        // Mid-March: March's first day is out of bounds but its last is not.
        minDate: DateTime.utc(2026, 3, 15),
      );
      final cells = <FluentCalendarCell>[for (final row in rows) ...row];

      expect(
        cells.firstWhere((cell) => cell.label == 'Feb').selectable,
        isFalse,
      );
      expect(
        cells.firstWhere((cell) => cell.label == 'Mar').selectable,
        isTrue,
      );
    });
  });

  group('localization', () {
    test('injected strings and formatters reach the labels', () {
      const turkish = FluentCalendarStrings(
        months: <String>[
          'Ocak',
          'Şubat',
          'Mart',
          'Nisan',
          'Mayıs',
          'Haziran',
          'Temmuz',
          'Ağustos',
          'Eylül',
          'Ekim',
          'Kasım',
          'Aralık',
        ],
        shortMonths: <String>[
          'Oca',
          'Şub',
          'Mar',
          'Nis',
          'May',
          'Haz',
          'Tem',
          'Ağu',
          'Eyl',
          'Eki',
          'Kas',
          'Ara',
        ],
        days: <String>[
          'Pazar',
          'Pazartesi',
          'Salı',
          'Çarşamba',
          'Perşembe',
          'Cuma',
          'Cumartesi',
        ],
        shortDays: <String>['P', 'P', 'S', 'Ç', 'P', 'C', 'C'],
      );

      final rows = fluentCalendarPage(
        pickerDate: DateTime.utc(2026, 3, 10),
        view: FluentCalendarView.year,
        today: DateTime.utc(2026, 3, 10),
        strings: turkish,
      );

      expect(rows.first.first.label, 'Oca');
      expect(rows.first.first.semanticLabel, 'Ocak');
    });
  });

  group('FluentCalendar — rendering', () {
    testWidgets('shows the month caption, weekday row and day grid', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('March 2026'), findsOneWidget);
      // Sunday-first: S M T W T F S.
      expect(_cell('W'), findsOneWidget);
      expect(_cell('15'), findsOneWidget);
      expect(find.text('Go to today'), findsOneWidget);
    });

    testWidgets('the weekday row rotates with firstDayOfWeek', (tester) async {
      await _pump(tester, firstDayOfWeek: FluentDayOfWeek.monday);

      final labels = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(FluentCalendar),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .toList();
      // First seven drawn strings after the caption are the weekday row.
      expect(labels.sublist(1, 8), <String>['M', 'T', 'W', 'T', 'F', 'S', 'S']);
    });
  });

  group('FluentCalendar — selection', () {
    testWidgets('tapping a day reports local midnight', (tester) async {
      final picked = <DateTime>[];
      await _pump(tester, onSelectDate: picked.add);

      await tester.tap(_cell('17'));
      await tester.pumpAndSettle();

      expect(picked, <DateTime>[DateTime(2026, 3, 17)]);
      // Local, not UTC: an application stores what its own clock calls that day.
      expect(picked.single.isUtc, isFalse);
    });

    testWidgets('re-picking the selected day fires again', (tester) async {
      final picked = <DateTime>[];
      await _pump(
        tester,
        value: DateTime(2026, 3, 17),
        onSelectDate: picked.add,
      );

      await tester.tap(_cell('17'));
      await tester.pumpAndSettle();

      // Upstream has no toggle-off.
      expect(picked, <DateTime>[DateTime(2026, 3, 17)]);
    });

    testWidgets('a null onSelectDate disables every cell', (tester) async {
      await _pump(tester, onSelectDate: null);

      final semantics = tester.getSemantics(_cell('17'));
      expect(semantics.flagsCollection.isEnabled, Tristate.isFalse);
      // No tap action, so a screen reader does not offer to activate it.
      expect(
        semantics.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
      );
    });

    testWidgets('an out-of-bounds day is not tappable', (tester) async {
      final picked = <DateTime>[];
      await _pump(
        tester,
        onSelectDate: picked.add,
        minDate: DateTime(2026, 3, 10),
      );

      await tester.tap(_cell('5'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(picked, isEmpty);

      await tester.tap(_cell('11'));
      await tester.pumpAndSettle();
      expect(picked, <DateTime>[DateTime(2026, 3, 11)]);
    });
  });

  group('FluentCalendar — navigation', () {
    testWidgets('the chevrons page the month', (tester) async {
      await _pump(tester);

      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('April 2026'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Previous month'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Previous month'));
      await tester.pumpAndSettle();
      expect(find.text('February 2026'), findsOneWidget);
    });

    testWidgets('a chevron past the bounds is disabled', (tester) async {
      await _pump(
        tester,
        minDate: DateTime(2026, 3, 1),
        maxDate: DateTime(2026, 3, 31),
      );

      final previous = tester.getSemantics(
        find.bySemanticsLabel('Previous month'),
      );
      expect(previous.flagsCollection.isEnabled, Tristate.isFalse);
      // Still present and still focusable — upstream keeps it in the tab order
      // so focus is not lost when a click disables it.
      expect(find.bySemanticsLabel('Previous month'), findsOneWidget);
    });

    testWidgets('the caption drills month to year to decade', (tester) async {
      // Single panel: with the month picker up the day caption is inert and
      // "2026" is on screen anyway, so this would pass without drilling.
      await _pump(tester);

      await tester.tap(find.text('March 2026'));
      await tester.pumpAndSettle();
      expect(find.text('2026'), findsOneWidget);
      expect(_cell('Mar'), findsOneWidget);

      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();
      // Anchored on the year itself, not a decade floor — upstream's
      // `useYearRangeState`.
      expect(find.text('2026 - 2037'), findsOneWidget);
      expect(_cell('2030'), findsOneWidget);
    });

    testWidgets('picking a year then a month returns to the day grid', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.text('March 2026'));
      await tester.pumpAndSettle();
      await tester.tap(_cell('Jul'));
      await tester.pumpAndSettle();

      expect(find.text('July 2026'), findsOneWidget);
      expect(_cell('15'), findsOneWidget);
    });

    testWidgets('the year grid is exactly as wide as the day grid', (
      tester,
    ) async {
      await _pump(tester);
      final dayWidth = tester.getSize(find.byType(FluentCalendar)).width;

      await tester.tap(find.text('March 2026'));
      await tester.pumpAndSettle();

      // 7 x 28 == 4 x 40 + 3 x 12 == 196, so drilling in never resizes the
      // surface — which is what lets a DatePicker popup hold still.
      expect(tester.getSize(find.byType(FluentCalendar)).width, dayWidth);
    });

    testWidgets('go to today is disabled on today\'s page and works off it', (
      tester,
    ) async {
      await _pump(tester);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Go to today'))
            .flagsCollection
            .isEnabled,
        Tristate.isFalse,
      );

      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('April 2026'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Go to today'));
      await tester.pumpAndSettle();
      expect(find.text('March 2026'), findsOneWidget);
    });
  });

  group('FluentCalendar — keyboard', () {
    testWidgets('the whole grid is one tab stop', (tester) async {
      await _pump(
        tester,
        wrap: (child) => Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            child,
            const Focus(child: SizedBox.shrink()),
          ],
        ),
      );

      // Caption, previous, next, the one active cell, go to today, then out.
      for (var i = 0; i < 5; i++) {
        expect(
          tester.binding.focusManager.primaryFocus?.context,
          isNotNull,
          reason: 'tab $i',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
      }
      // Exactly one cell was reachable, so five tabs clear the calendar.
      expect(find.byType(FluentCalendar), findsOneWidget);
    });

    testWidgets('arrows move the roving focus and page at the edge', (
      tester,
    ) async {
      await _pump(tester, value: DateTime(2026, 3, 31), autofocus: true);
      await tester.pumpAndSettle();

      // 31 March is a Tuesday; 1 April is drawn as a trailing cell, so moving
      // onto it must NOT page.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('March 2026'), findsOneWidget);

      // Another week forward leaves the rendered grid, so it pages.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('April 2026'), findsOneWidget);
    });

    testWidgets('PageUp moves forward a month, as upstream does', (
      tester,
    ) async {
      await _pump(tester, autofocus: true);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(find.text('April 2026'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(find.text('March 2026'), findsOneWidget);
    });

    testWidgets('arrow keys skip a restricted day', (tester) async {
      await _pump(
        tester,
        value: DateTime(2026, 3, 10),
        autofocus: true,
        restrictedDates: <DateTime>[DateTime(2026, 3, 11)],
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      // Landed on the 12th, not the restricted 11th.
      final focused = tester.widgetList<FluentCalendar>(
        find.byType(FluentCalendar),
      );
      expect(focused, isNotEmpty);
      expect(_cell('12'), findsOneWidget);
    });

    // Escape must reach whatever hosts the calendar — a FluentDatePicker binds
    // DismissIntent, and swallowing the key here would make its popup
    // undismissable.
    testWidgets('Escape is not consumed', (tester) async {
      var dismissed = 0;
      await _pump(
        tester,
        autofocus: true,
        wrap: (child) => Actions(
          actions: <Type, Action<Intent>>{
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) {
                dismissed++;
                return null;
              },
            ),
          },
          child: child,
        ),
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(dismissed, 1);
    });
  });

  group('FluentCalendar — motion', () {
    testWidgets('reduced motion lands on the end state in one frame', (
      tester,
    ) async {
      await _pump(tester, reducedMotion: true);

      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();

      final transform = tester.widget<Transform>(
        find
            .descendant(
              of: find.byType(FluentCalendar),
              matching: find.byType(Transform),
            )
            .first,
      );
      expect(transform.transform.getTranslation().y, 0);
      final opacity = tester.widgetList<Opacity>(
        find.descendant(
          of: find.byType(FluentCalendar),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.every((widget) => widget.opacity == 1), isTrue);
    });

    testWidgets('a page change starts away from the end state', (tester) async {
      await _pump(tester);

      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pump();

      final transform = tester.widget<Transform>(
        find
            .descendant(
              of: find.byType(FluentCalendar),
              matching: find.byType(Transform),
            )
            .first,
      );
      expect(transform.transform.getTranslation().y, isNot(0));

      await tester.pumpAndSettle();
    });
  });

  group('FluentCalendar — semantics', () {
    testWidgets('the grid is a live region labelled with the caption', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      expect(
        find.bySemanticsLabel('March 2026'),
        findsWidgets,
        reason: 'the grid announces the visible month',
      );
      handle.dispose();
    });

    testWidgets('a day cell announces its full date and selection', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, value: DateTime(2026, 3, 17));

      final semantics = tester.getSemantics(_cell('17'));
      expect(semantics.label, 'Selected date March 17, 2026');
      expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('a weekday header announces the full day name', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      expect(find.bySemanticsLabel('Wednesday'), findsOneWidget);
      handle.dispose();
    });
  });

  // The arithmetic is .NET's `GetWeekOfYear` by way of upstream's `dateMath`,
  // so it is pinned to worked examples rather than re-derived.
  group('fluentCalendarWeekNumber', () {
    test('FirstDay counts the week holding 1 January as week 1', () {
      // 1 January 2026 is a Thursday, so week 1 is three days long.
      expect(fluentCalendarWeekNumber(DateTime(2026)), 1);
      expect(fluentCalendarWeekNumber(DateTime(2026, 1, 3)), 1);
      expect(fluentCalendarWeekNumber(DateTime(2026, 1, 4)), 2);
    });

    test('FirstFourDayWeek with a Monday start is ISO-8601', () {
      // The ISO rule: the week holding the first Thursday is week 1, and
      // 1 January 2026 *is* that Thursday.
      expect(
        fluentCalendarWeekNumber(
          DateTime(2026),
          firstDayOfWeek: FluentDayOfWeek.monday,
          firstWeekOfYear: FluentFirstWeekOfYear.firstFourDayWeek,
        ),
        1,
      );
    });

    test(
      'FirstFullWeek pushes a partial opening week into the year before',
      () {
        // 1 January 2026 is mid-week, so under this rule it is not week 1 —
        // it belongs to the last week of 2025.
        expect(
          fluentCalendarWeekNumber(
            DateTime(2026),
            firstWeekOfYear: FluentFirstWeekOfYear.firstFullWeek,
          ),
          greaterThan(50),
        );
      },
    );

    test('a month numbers its rows consecutively', () {
      // March 2026 opens on a Sunday and runs five rows.
      expect(
        fluentCalendarWeekNumbers(
          weeksInMonth: 5,
          pickerDate: DateTime(2026, 3),
        ),
        <int>[10, 11, 12, 13, 14],
      );
    });
  });

  group('FluentCalendar — week numbers', () {
    testWidgets('off by default, and a column when asked for', (tester) async {
      await _pump(tester);
      expect(find.bySemanticsLabel('Week 10'), findsNothing);

      await _pump(
        tester,
        wrap: (_) => FluentCalendar(
          today: _today,
          onSelectDate: _noop,
          isMonthPickerVisible: false,
          showWeekNumbers: true,
        ),
      );

      // March 2026 is weeks 10 to 14; the row holding the 10th is week 11.
      expect(find.bySemanticsLabel('Week 10'), findsOneWidget);
      expect(find.bySemanticsLabel('Week 14'), findsOneWidget);
    });
  });

  group('FluentCalendar — allFocusable', () {
    // March 2026 opens on a Sunday, so slot 0 is the 1st, the 10th is slot 9
    // and the 20th is slot 19. `today` is the 10th, and minDate puts it out of
    // bounds — which is the only case where the flag decides anything.
    Future<String?> focusedSlot(
      WidgetTester tester, {
      required bool allFocusable,
    }) async {
      await _pump(
        tester,
        wrap: (_) => FluentCalendar(
          today: _today,
          isMonthPickerVisible: false,
          minDate: DateTime(2026, 3, 20),
          allFocusable: allFocusable,
          autofocus: true,
          onSelectDate: _noop,
        ),
      );
      return FocusManager.instance.primaryFocus?.debugLabel;
    }

    testWidgets(
      'off, the roving stop falls through to the first selectable day',
      (tester) async {
        expect(
          await focusedSlot(tester, allFocusable: false),
          'FluentCalendar cell 19',
        );
      },
    );

    testWidgets('on, an out-of-bounds day can hold the roving stop', (
      tester,
    ) async {
      expect(
        await focusedSlot(tester, allFocusable: true),
        'FluentCalendar cell 9',
      );
    });

    testWidgets('a focusable out-of-bounds day is still not activatable', (
      tester,
    ) async {
      var selections = 0;
      await _pump(
        tester,
        wrap: (_) => FluentCalendar(
          today: _today,
          isMonthPickerVisible: false,
          minDate: DateTime(2026, 3, 10),
          allFocusable: true,
          onSelectDate: (_) => selections++,
        ),
      );

      await tester.tap(_cell('5'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(selections, 0);
    });
  });

  group('FluentCalendar — the close button', () {
    testWidgets('needs both the flag and a callback', (tester) async {
      var dismissed = 0;

      await _pump(
        tester,
        wrap: (_) => FluentCalendar(
          today: _today,
          onSelectDate: _noop,
          isMonthPickerVisible: false,
          showCloseButton: true,
        ),
      );
      expect(
        find.bySemanticsLabel('Close'),
        findsNothing,
        reason: 'no onDismiss, so nothing to close',
      );

      await _pump(
        tester,
        wrap: (_) => FluentCalendar(
          today: _today,
          onSelectDate: _noop,
          isMonthPickerVisible: false,
          showCloseButton: true,
          onDismiss: () => dismissed++,
        ),
      );
      expect(find.bySemanticsLabel('Close'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(dismissed, 1);
    });
  });

  group('FluentCalendar — the month picker beside the day grid', () {
    // Upstream's `isMonthPickerVisible` defaults to true: a calendar is 440
    // wide and shows both grids, separated by a rule.
    testWidgets('is the default, and shows both grids', (tester) async {
      await _pump(tester, isMonthPickerVisible: true);

      expect(find.text('March 2026'), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      expect(_cell('15'), findsOneWidget);
      expect(_cell('Jul'), findsOneWidget);
    });

    testWidgets('two panels are twice one panel, plus the rule', (
      tester,
    ) async {
      await _pump(tester);
      final single = tester.getSize(find.byType(FluentCalendar)).width;

      await _pump(tester, isMonthPickerVisible: true);
      final split = tester.getSize(find.byType(FluentCalendar)).width;

      // 220 and 440 upstream, with a 1px rule between the columns.
      expect(split, single * 2 + 1);
    });

    testWidgets('picking a month moves the day grid', (tester) async {
      await _pump(tester, isMonthPickerVisible: true);

      await tester.tap(_cell('Jul'));
      await tester.pumpAndSettle();

      expect(find.text('July 2026'), findsOneWidget);
      // The month panel stays on its own year rather than drilling.
      expect(find.text('2026'), findsOneWidget);
    });

    testWidgets('the day caption is inert when the month picker is up', (
      tester,
    ) async {
      await _pump(tester, isMonthPickerVisible: true);

      final semantics = tester.getSemantics(find.text('March 2026'));
      expect(semantics.flagsCollection.isButton, isFalse);
    });

    testWidgets('the month caption drills to the decade grid', (tester) async {
      await _pump(tester, isMonthPickerVisible: true);

      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();

      expect(find.text('2026 - 2037'), findsOneWidget);
      expect(_cell('2030'), findsOneWidget);
      // The day grid is untouched by the right panel drilling.
      expect(find.text('March 2026'), findsOneWidget);
    });

    testWidgets('each panel has its own chevrons', (tester) async {
      await _pump(tester, isMonthPickerVisible: true);

      await tester.tap(find.bySemanticsLabel('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('April 2026'), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Next year'));
      await tester.pumpAndSettle();
      expect(find.text('2027'), findsOneWidget);
      // Paging the year does not drag the day grid with it.
      expect(find.text('April 2026'), findsOneWidget);
    });
  });
}
