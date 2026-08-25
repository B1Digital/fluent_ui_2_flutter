import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// TimePicker is a combobox: a field, a listbox of generated times in an
/// [Overlay], and — where the section turns it on — freeform text that is
/// parsed on blur. So every group below drives one of those three paths and
/// asserts what came back out into the field, the readout or the validation
/// message.
///
/// Option labels are computed with [fluentFormatTime] rather than written out,
/// so a change to the h12 rendering fails the component's own tests rather than
/// quietly rewriting what this suite expects.
void main() {
  const String page = 'compat-components-timepicker';

  group('default', () {
    final DocsSection section = sectionOf(
      'compat-components-timepicker--default',
    );

    testWidgets('the field opens the listbox and a row fills the field', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_fieldText(tester), isEmpty);
      expect(_row(9, 0), findsNothing);

      await _open(tester);
      expect(
        _row(0, 0),
        findsOneWidget,
        reason: 'the default range is the whole day, starting at midnight',
      );
      expect(_row(23, 30), findsOneWidget);

      await tapAndSettle(tester, _row(9, 0), what: 'the 9:00 AM row');
      expect(_fieldText(tester), _time(9, 0));
      expect(
        _row(9, 30),
        findsNothing,
        reason: 'committing a row must close the listbox',
      );

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('a second click on the field closes the listbox', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await _open(tester);

      await tapAndSettle(
        tester,
        find.byType(FluentTimePicker),
        what: 'the field, a second time',
        warnIfMissed: false,
      );
      expect(_row(9, 0), findsNothing);
      expect(_fieldText(tester), isEmpty);
    });

    testWidgets('a row commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await _open(tester);

      // The distinction `tester.tap` cannot make: a synthetic tap arrives as a
      // touch, and `EditableText`'s default `onTapOutside` only drops focus for
      // a non-touch press. So a mouse press on a row blurs the field, and
      // anything the picker does on blur happens before the press has had the
      // chance to become a tap.
      await mouseClick(tester, _row(9, 0));
      expect(
        _fieldText(tester),
        _time(9, 0),
        reason: 'a mouse press on a row must commit it, not dismiss the list',
      );
    });

    testWidgets('the field opens under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // `mouseClick` moves the pointer two pixels between press and release,
      // which is what a hand does. The faceplate is the only affordance this
      // control has, so a click that misses it leaves the picker unusable.
      await mouseClick(tester, find.byType(FluentTimePicker));
      expect(
        _row(9, 0),
        findsOneWidget,
        reason: 'a mouse press on the faceplate must open the listbox',
      );
    });
  });

  group('controlled', () {
    final DocsSection section = sectionOf(
      'compat-components-timepicker--controlled',
    );

    testWidgets('both pickers start on the seeded time', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(_fieldText(tester, 0), _time(12, 30));
      expect(_fieldText(tester, 1), _time(12, 30));
    });

    testWidgets('startHour and endHour bound the generated options', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await _open(tester);

      expect(_row(8, 0), findsOneWidget);
      expect(_row(19, 30), findsOneWidget);
      expect(
        _row(7, 30),
        findsNothing,
        reason: 'startHour: 8 must drop everything before it',
      );
      expect(
        _row(20, 0),
        findsNothing,
        reason: 'endHour is exclusive, so 8 PM is not offered',
      );
    });

    testWidgets('each picker owns its own value', (WidgetTester tester) async {
      await pumpSection(tester, section);

      await _open(tester);
      await tapAndSettle(tester, _row(9, 0), what: 'the 9:00 AM row');

      expect(_fieldText(tester, 0), _time(9, 0));
      expect(
        _fieldText(tester, 1),
        _time(12, 30),
        reason: 'the second picker holds its own state and must not follow',
      );
    });
  });

  group('clearable', () {
    final DocsSection section = sectionOf(
      'compat-components-timepicker--clearable',
    );

    testWidgets('the clear glyph appears with a value and empties it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        find.bySemanticsLabel('Clear'),
        findsNothing,
        reason: 'there is nothing to clear until something is chosen',
      );

      await _open(tester);
      await tapAndSettle(tester, _row(9, 0), what: 'the 9:00 AM row');
      expect(_fieldText(tester), _time(9, 0));
      expect(find.bySemanticsLabel('Clear'), findsOneWidget);

      await tapAndSettle(
        tester,
        find.bySemanticsLabel('Clear'),
        what: 'the clear glyph',
      );
      expect(_fieldText(tester), isEmpty);
      expect(
        find.bySemanticsLabel('Clear'),
        findsNothing,
        reason: 'the glyph must retract once the value is gone',
      );
    });

    testWidgets('the clear glyph fires under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await _open(tester);
      await tapAndSettle(tester, _row(9, 0), what: 'the 9:00 AM row');

      // The glyph sits inside the faceplate, so its own tap recogniser shares
      // an arena with the field's. A click that wanders two pixels must still
      // clear the value rather than being read as a text-selection drag.
      await mouseClick(tester, find.bySemanticsLabel('Clear'));
      expect(_fieldText(tester), isEmpty);
    });
  });

  group('freeform with error handling', () {
    final DocsSection section = sectionOf(
      'compat-components-timepicker--freeform-with-error-handling',
    );

    testWidgets('a typed time inside the range commits', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await typeAndBlur(tester, find.byType(FluentTimePicker), '11:30');
      expect(_fieldText(tester), _time(11, 30));
      expect(
        find.textContaining('Time out of'),
        findsNothing,
        reason: '11:30 is inside the 10:00 to 19:59 range',
      );
    });

    testWidgets('a typed time outside the range reports outOfBounds', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await typeAndBlur(tester, find.byType(FluentTimePicker), '09:00');
      expect(
        find.text('Time out of the 10:00 to 19:59 range.'),
        findsOneWidget,
      );
    });

    testWidgets('text that is not a time reports invalidInput', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await typeAndBlur(tester, find.byType(FluentTimePicker), 'coffee');
      expect(
        find.text('Invalid time format. Please use the 24-hour format HH:MM.'),
        findsOneWidget,
      );
    });

    testWidgets('emptying a typed time reports requiredInput', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await typeAndBlur(tester, find.byType(FluentTimePicker), '11:30');

      await typeAndBlur(tester, find.byType(FluentTimePicker), '');
      expect(find.text('Time is required.'), findsOneWidget);
    });

    testWidgets('opening and closing an empty required picker reports it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The section's own instructions: "leave the input empty and close the
      // TimePicker". Closing is what blur does, and a required field that has
      // never been typed into is exactly the case the message exists for.
      await _open(tester);
      expect(_row(11, 0), findsOneWidget);
      await _blur(tester);

      expect(_row(11, 0), findsNothing, reason: 'blur must close the listbox');
      expect(find.text('Time is required.'), findsOneWidget);
    });
  });

  group('freeform custom parsing', () {
    final DocsSection section = sectionOf(
      'compat-components-timepicker--freeform-custom-parsing',
    );

    testWidgets('formatTime rewrites every row and the field', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.textContaining('Selected time:'), findsNothing);

      await _open(tester);
      expect(_label('Morning: ${_time(9, 0)}'), findsOneWidget);
      expect(_label('Afternoon: ${_time(13, 0)}'), findsOneWidget);

      await tapAndSettle(
        tester,
        _label('Morning: ${_time(9, 0)}'),
        what: 'the 9 AM row',
      );
      expect(_fieldText(tester), 'Morning: ${_time(9, 0)}');
      expect(
        find.text('Selected time: Morning: ${_time(9, 0)}'),
        findsOneWidget,
        reason: 'the readout prints selectedTimeText, which the row supplies',
      );
    });

    testWidgets('parseTime reads the custom wording back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await typeAndBlur(
        tester,
        find.byType(FluentTimePicker),
        'Afternoon: 3:30',
      );
      expect(
        find.text('Selected time: Afternoon: 3:30'),
        findsOneWidget,
        reason: 'the readout echoes the text exactly as it was typed',
      );
      expect(
        _fieldText(tester),
        'Afternoon: ${_time(15, 30)}',
        reason: 'the committed value is written back through formatTime',
      );
    });
  });

  group('time picker with date picker', () {
    final DocsSection section = sectionOf(
      'compat-components-timepicker--time-picker-with-date-picker',
    );

    testWidgets('the readout appears with the date and then takes the time', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.textContaining('Selected date time:'), findsNothing);

      await tapAndSettle(
        tester,
        find.byType(FluentDatePicker),
        what: 'the date field',
      );
      await tapAndSettle(
        tester,
        find.bySemanticsLabel(
          fluentFormatCalendarMonthDayYear(
            _target,
            FluentCalendarStrings.english,
          ),
        ),
        what: 'a day cell',
      );
      expect(find.text('Selected date time: $_target'), findsOneWidget);

      await tapAndSettle(
        tester,
        find.byType(FluentTimePicker),
        what: 'the time field',
      );
      await tapAndSettle(tester, _row(9, 0), what: 'the 9:00 AM row');

      // dateAnchor is the chosen date, so the option is built on that day
      // rather than on the clock — which is the whole point of pairing them.
      expect(
        find.text(
          'Selected date time: '
          '${DateTime(_target.year, _target.month, _target.day, 9)}',
        ),
        findsOneWidget,
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

    testWidgets('a section unmounts with its listbox still open', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('compat-components-timepicker--default'),
      );
      await _open(tester);

      // The overlay entry outlives the widget unless dispose removes it, and
      // that is the class of defect `render_test` cannot see.
      await expectCleanTeardown(tester, 'the open listbox');
    });
  });
}

/// The day the paired demo picks, never today so its cell announces a plain
/// date rather than "Today's date".
final DateTime _target = () {
  final DateTime today = DateTime.now();
  return DateTime(today.year, today.month, today.day == 15 ? 16 : 15);
}();

/// An option's label on the h12 clock the demos leave at its default.
String _time(int hour, int minute) =>
    fluentFormatTime(DateTime(2026, 1, 1, hour, minute));

/// A drawn label reading [text].
///
/// Deliberately not `find.text`, which matches an [EditableText] holding the
/// same string as well: every row here reappears in the faceplate the moment
/// it is chosen, so "the listbox is closed" would go on passing against the
/// field's own text.
Finder _label(String text) => find.byWidgetPredicate(
  (Widget widget) => widget is Text && widget.data == text,
  description: 'a label reading "$text"',
);

/// The listbox row for [hour]:[minute].
Finder _row(int hour, int minute) => _label(_time(hour, minute));

/// Opens the listbox from the field and proves it arrived.
Future<void> _open(WidgetTester tester) async {
  await tapAndSettle(
    tester,
    find.byType(FluentTimePicker),
    what: 'the time picker field',
    warnIfMissed: false,
  );
}

/// Drops focus, which is what commits typed text and closes the listbox.
Future<void> _blur(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await settle(tester);
  expectClean(tester, 'blurring the field');
}

/// What the [index]-th faceplate on the page currently holds.
String _fieldText(WidgetTester tester, [int index = 0]) =>
    editedText(tester, find.byType(FluentTimePicker).at(index));
