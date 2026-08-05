import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/internal/input_modality.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _anchor = DateTime(2026, 3, 10);

Future<void> _pump(
  WidgetTester tester, {
  DateTime? selectedTime,
  ValueChanged<FluentTimeSelectionData>? onTimeChange = _noop,
  bool freeform = false,
  bool clearable = false,
  int startHour = 8,
  int endHour = 11,
  int increment = 60,
  FluentTimePickerAppearance appearance = FluentTimePickerAppearance.outline,
}) async {
  await tester.pumpWidget(
    FluentApp(
      theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(
        child: SizedBox(
          width: 280,
          child: FluentTimePicker(
            dateAnchor: _anchor,
            selectedTime: selectedTime,
            onTimeChange: onTimeChange,
            freeform: freeform,
            clearable: clearable,
            startHour: startHour,
            endHour: endHour,
            increment: increment,
            appearance: appearance,
            hourCycle: FluentHourCycle.h23,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _noop(FluentTimeSelectionData _) {}

/// The faceplate's own painted box.
BoxDecoration _faceplate(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(FluentTimePicker),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((box) => box.decoration)
    .whereType<BoxDecoration>()
    .firstWhere((decoration) => decoration.borderRadius != null);

void main() {
  setUp(FluentInputModality.debugReset);

  group('fluentTimePickerOptions', () {
    test('a working day at half-hour steps', () {
      final options = fluentTimePickerOptions(
        dateAnchor: _anchor,
        startHour: 8,
        endHour: 17,
      );

      // endHour is exclusive: 08:00 through 16:30 is eighteen options.
      expect(options.length, 18);
      expect(options.first, DateTime(2026, 3, 10, 8));
      expect(options.last, DateTime(2026, 3, 10, 16, 30));
    });

    test('a range that wraps past midnight rolls into the next day', () {
      final options = fluentTimePickerOptions(
        dateAnchor: _anchor,
        startHour: 22,
        endHour: 2,
      );

      expect(options.length, 8);
      expect(options.first, DateTime(2026, 3, 10, 22));
      expect(options.last, DateTime(2026, 3, 11, 1, 30));
    });

    test('the default is a whole day, and so is start == end', () {
      expect(fluentTimePickerOptions(dateAnchor: _anchor).length, 48);
      expect(
        fluentTimePickerOptions(
          dateAnchor: _anchor,
          startHour: 8,
          endHour: 8,
        ).length,
        48,
      );
    });

    test('a non-positive increment yields nothing rather than hanging', () {
      expect(
        fluentTimePickerOptions(dateAnchor: _anchor, increment: 0),
        isEmpty,
      );
    });
  });

  group('fluentFormatTime', () {
    // The whole point of the four cycles: h11/h23 start at hour 0, h12/h24
    // start at hour 1.
    test('the four clocks disagree exactly where upstream says they do', () {
      final midnight = DateTime(2026, 3, 10, 0, 30);
      expect(fluentFormatTime(midnight, cycle: FluentHourCycle.h11), '0:30 AM');
      expect(
        fluentFormatTime(midnight, cycle: FluentHourCycle.h12),
        '12:30 AM',
      );
      expect(fluentFormatTime(midnight, cycle: FluentHourCycle.h23), '00:30');
      expect(fluentFormatTime(midnight, cycle: FluentHourCycle.h24), '24:30');

      final noon = DateTime(2026, 3, 10, 12, 30);
      expect(fluentFormatTime(noon, cycle: FluentHourCycle.h11), '0:30 PM');
      expect(fluentFormatTime(noon, cycle: FluentHourCycle.h12), '12:30 PM');
      expect(fluentFormatTime(noon, cycle: FluentHourCycle.h23), '12:30');
      expect(fluentFormatTime(noon, cycle: FluentHourCycle.h24), '12:30');
    });

    test('seconds are opt-in', () {
      final time = DateTime(2026, 3, 10, 21, 5, 9);
      expect(fluentFormatTime(time, cycle: FluentHourCycle.h23), '21:05');
      expect(
        fluentFormatTime(time, cycle: FluentHourCycle.h23, showSeconds: true),
        '21:05:09',
      );
      expect(fluentFormatTime(time), '9:05 PM');
    });
  });

  group('fluentParseTime', () {
    FluentTimeStringValidationResult parse(String text) =>
        fluentParseTime(text, dateAnchor: _anchor);

    test('accepts the shapes a user actually types', () {
      expect(parse('9').date, DateTime(2026, 3, 10, 9));
      expect(parse('9:05').date, DateTime(2026, 3, 10, 9, 5));
      expect(parse('9:05:30').date, DateTime(2026, 3, 10, 9, 5, 30));
      expect(parse('9 pm').date, DateTime(2026, 3, 10, 21));
      expect(parse('9:05 PM').date, DateTime(2026, 3, 10, 21, 5));
      expect(parse('9:05p').date, DateTime(2026, 3, 10, 21, 5));
      expect(parse('21:05').date, DateTime(2026, 3, 10, 21, 5));
      // Midnight on the h24 clock is the one place hour 24 is legal.
      expect(parse('24:00').date, DateTime(2026, 3, 10));
    });

    test('rejects what is not a time', () {
      for (final text in <String>['9:75', '25:00', 'abc', '13 pm', '9:1:2:3']) {
        expect(
          parse(text).error,
          FluentTimePickerErrorType.invalidInput,
          reason: text,
        );
        expect(parse(text).date, isNull, reason: text);
      }
    });

    test('an empty field is required-input only when required', () {
      expect(parse('').error, isNull);
      expect(
        fluentParseTime('', dateAnchor: _anchor, required: true).error,
        FluentTimePickerErrorType.requiredInput,
      );
    });

    // Upstream returns the parsed value alongside an out-of-bounds error, so an
    // application can say what it rejected.
    test('out of bounds still reports the parsed time', () {
      final result = fluentParseTime(
        '7:00',
        dateAnchor: _anchor,
        startHour: 8,
        endHour: 17,
      );
      expect(result.error, FluentTimePickerErrorType.outOfBounds);
      expect(result.date, isNotNull);
    });

    test('a wrapping range parses a small hour into the next day', () {
      final result = fluentParseTime(
        '1:30 AM',
        dateAnchor: _anchor,
        startHour: 22,
        endHour: 2,
      );
      expect(result.error, isNull);
      expect(result.date, DateTime(2026, 3, 11, 1, 30));
    });
  });

  group('FluentTimePicker — the read-only ramp', () {
    // resolveFluentInputStyle folds readOnly into the DISABLED ramp
    // (`inert = disabled || readOnly`). A non-freeform picker is read-only by
    // definition, so handing that flag straight through would render every
    // default picker looking greyed out. This is the regression that guards the
    // split.
    testWidgets('a default picker is not painted as disabled', (tester) async {
      await _pump(tester);
      final live = _faceplate(tester);

      await _pump(tester, onTimeChange: null);
      final disabled = _faceplate(tester);

      expect(
        live.color,
        isNot(disabled.color),
        reason: 'a read-only picker must not borrow the disabled fill',
      );
      expect(live.border, isNot(disabled.border));
    });

    testWidgets('a freeform picker paints the same faceplate', (tester) async {
      await _pump(tester);
      final readOnly = _faceplate(tester);

      await _pump(tester, freeform: true);
      expect(_faceplate(tester).color, readOnly.color);
    });
  });

  group('FluentTimePicker — listbox', () {
    testWidgets('tapping the field opens it and tapping again closes', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('09:00'), findsNothing);

      await tester.tap(find.byType(FluentTimePicker));
      await tester.pumpAndSettle();
      // 08:00, 09:00, 10:00 — endHour is exclusive.
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('11:00'), findsNothing);

      await tester.tap(find.byType(FluentTimePicker));
      await tester.pumpAndSettle();
      expect(find.text('09:00'), findsNothing);
    });

    testWidgets('picking a row reports the time and closes', (tester) async {
      final reported = <FluentTimeSelectionData>[];
      await _pump(tester, onTimeChange: reported.add);

      await tester.tap(find.byType(FluentTimePicker));
      await tester.pumpAndSettle();
      await tester.tap(find.text('09:00'));
      await tester.pumpAndSettle();

      expect(reported.single.selectedTime, DateTime(2026, 3, 10, 9));
      expect(reported.single.error, isNull);
      // The field now shows 09:00, so the listbox is proved gone by a row that
      // is not the selected value.
      expect(find.text('10:00'), findsNothing);
    });

    testWidgets('a disabled picker never opens', (tester) async {
      await _pump(tester, onTimeChange: null);
      await tester.tap(find.byType(FluentTimePicker));
      await tester.pumpAndSettle();
      expect(find.text('09:00'), findsNothing);
    });
  });

  group('FluentTimePicker — keyboard', () {
    testWidgets('Down opens, Enter commits, Escape closes', (tester) async {
      final reported = <FluentTimeSelectionData>[];
      await _pump(tester, onTimeChange: reported.add);
      await tester.tap(find.byType(FluentTimePicker));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FluentTimePicker));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('09:00'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(reported.single.selectedTime, DateTime(2026, 3, 10, 9));
    });

    testWidgets('Escape closes without committing', (tester) async {
      final reported = <FluentTimeSelectionData>[];
      await _pump(tester, onTimeChange: reported.add);

      await tester.tap(find.byType(FluentTimePicker));
      await tester.pumpAndSettle();
      expect(find.text('09:00'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('09:00'), findsNothing);
      expect(reported, isEmpty);
    });

    // Space must stay free to type a space so a user can write "12 PM".
    // FluentDropdown binds Space to activate; a combobox must not, or the key
    // would commit a row instead of reaching the field.
    testWidgets('Space is not bound, so it cannot commit a row', (
      tester,
    ) async {
      final reported = <FluentTimeSelectionData>[];
      await _pump(tester, freeform: true, onTimeChange: reported.add);

      await tester.tap(find.byType(FluentTimePicker));
      await tester.pumpAndSettle();
      expect(find.text('09:00'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      // Still open, nothing committed: Space did not reach an activate action.
      expect(find.text('09:00'), findsOneWidget);
      expect(reported, isEmpty);
    });
  });

  group('FluentTimePicker — freeform', () {
    testWidgets('unparseable text is left alone and reported', (tester) async {
      final reported = <FluentTimeSelectionData>[];
      await _pump(tester, freeform: true, onTimeChange: reported.add);

      await tester.tap(find.byType(FluentTimePicker));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'nonsense');
      // Blur commits, the way a browser change event does.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      expect(reported.single.error, FluentTimePickerErrorType.invalidInput);
      expect(reported.single.selectedTimeText, 'nonsense');
      // Not snapped back — the opposite of FluentSpinButton, deliberately.
      final controller = tester
          .widget<EditableText>(find.byType(EditableText))
          .controller;
      expect(controller.text, 'nonsense');
    });

    testWidgets('a valid typed time commits on blur', (tester) async {
      final reported = <FluentTimeSelectionData>[];
      await _pump(tester, freeform: true, onTimeChange: reported.add);

      await tester.tap(find.byType(FluentTimePicker));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), '09:30');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      expect(reported.single.selectedTime, DateTime(2026, 3, 10, 9, 30));
      expect(reported.single.error, isNull);
    });

    testWidgets('a non-freeform field refuses typed text', (tester) async {
      await _pump(tester);
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.readOnly, isTrue);
    });
  });

  group('FluentTimePicker — clearable', () {
    testWidgets('the glyph appears only with a value and clears it', (
      tester,
    ) async {
      final reported = <FluentTimeSelectionData>[];
      await _pump(tester, clearable: true, onTimeChange: reported.add);
      expect(find.bySemanticsLabel('Clear'), findsNothing);

      await _pump(
        tester,
        clearable: true,
        selectedTime: DateTime(2026, 3, 10, 9),
        onTimeChange: reported.add,
      );
      expect(find.bySemanticsLabel('Clear'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Clear'));
      await tester.pumpAndSettle();

      expect(reported.single.selectedTime, isNull);
      expect(reported.single.selectedTimeText, '');
      // Clearing is not a toggle: the listbox stays as it was.
      expect(find.text('09:00'), findsNothing);
    });
  });
}
