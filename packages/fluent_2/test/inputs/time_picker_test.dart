import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/internal/input_modality.dart';
import 'package:flutter/gestures.dart'
    show PointerDeviceKind, kPrimaryButton, kSecondaryMouseButton;
import 'package:flutter/rendering.dart' show RendererBinding;
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
  Widget? placeholder,
  ValueChanged<bool>? onOpenChange,
  bool autofocus = false,
  bool error = false,
  FluentTimePickerStyle? style,
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
            placeholder: placeholder,
            onOpenChange: onOpenChange,
            autofocus: autofocus,
            error: error,
            style: style,
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

/// The faceplate's border, which `buildFluentInput` paints rather than
/// decorates — the box above carries only the fill and the radius.
FluentInputBorderPainter _border(WidgetTester tester) => tester
    .widgetList<CustomPaint>(
      find.descendant(
        of: find.byType(FluentTimePicker),
        matching: find.byType(CustomPaint),
      ),
    )
    .map((paint) => paint.painter)
    .whereType<FluentInputBorderPainter>()
    .single;

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
    // A non-freeform picker is read-only by definition. Upstream gives
    // `readOnly` no styling at all, so a default picker must resolve the live
    // ramp — only `enabled` may grey it out. The picker once had to hide its
    // read-only flag from the style resolver to get this; this guards against
    // the flag ever being styled again.
    testWidgets('a default picker is not painted as disabled', (tester) async {
      await _pump(tester);
      final live = _faceplate(tester);
      final liveBorder = _border(tester).borderColor;

      await _pump(tester, onTimeChange: null);
      final disabled = _faceplate(tester);

      expect(
        live.color,
        isNot(disabled.color),
        reason: 'a read-only picker must not borrow the disabled fill',
      );
      expect(
        liveBorder,
        isNot(_border(tester).borderColor),
        reason: 'nor the disabled stroke',
      );
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

    testWidgets('re-measures its max height when the page scrolls under it', (
      tester,
    ) async {
      // The room around the field is measured once at open, and the entry
      // lives in the Overlay, so nothing rebuilt it when the page moved: a
      // listbox clamped to the 300 of room a mid-page field left stayed 300
      // tall after the page carried the field to the top, where the full 416
      // cap fits. `@fluentui/react-positioning` repositions on scroll rather
      // than closing, so the entry re-measures.
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: SingleChildScrollView(
            controller: controller,
            child: const Column(
              children: <Widget>[
                SizedBox(height: 900),
                SizedBox(
                  width: 280,
                  child: FluentTimePicker(
                    startHour: 8,
                    endHour: 11,
                    increment: 60,
                    onTimeChange: _noop,
                    hourCycle: FluentHourCycle.h23,
                  ),
                ),
                SizedBox(height: 900),
              ],
            ),
          ),
        ),
      );
      // Puts the field 250 down a 600 viewport, so neither side of it has the
      // 416 the cap wants and the clamp is what decides the height.
      controller.jumpTo(650);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FluentTimePicker));
      await tester.pumpAndSettle();

      final surface = find.descendant(
        of: find.byType(CompositedTransformFollower),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is ConstrainedBox && widget.constraints.maxHeight.isFinite,
        ),
      );
      expect(surface, findsOneWidget);
      double cap() =>
          tester.widget<ConstrainedBox>(surface).constraints.maxHeight;

      expect(cap(), lessThan(416), reason: 'else this proves nothing');

      // A wheel, not a drag: `TapRegion` cannot tell a drag from a tap, so a
      // touch drag dismisses (see the light-dismiss group), and `jumpTo` never
      // flips `isScrollingNotifier`, which the rebuild is gated on.
      final wheel = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(wheel.hover(const Offset(400, 100)));
      await tester.sendEventToBinding(wheel.scroll(const Offset(0, 200)));
      await tester.pumpAndSettle();

      expect(find.text('09:00'), findsOneWidget, reason: 'still open');
      expect(controller.offset, 850, reason: 'the wheel has to have landed');
      // 200 further down the page leaves 518 below the field, so upstream's
      // `min(80vh, 416px)` is now the binding half.
      expect(cap(), 416);
    });
  });

  group('FluentTimePicker — light dismiss', () {
    // The regression this pins: the listbox used to hang a full-screen
    // `HitTestBehavior.opaque` barrier under itself, so a click on anything
    // behind an open listbox dismissed the listbox and went nowhere else — the
    // user had to click twice. Upstream's combobox dismisses from a
    // document-level `useOnClickOutside`, where the click dismisses AND lands.
    testWidgets('an outside click dismisses the listbox and still lands', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Stack(
            children: <Widget>[
              Positioned(
                top: 0,
                left: 0,
                width: 280,
                child: FluentTimePicker(
                  dateAnchor: _anchor,
                  onTimeChange: _noop,
                  startHour: 8,
                  endHour: 11,
                  increment: 60,
                  hourCycle: FluentHourCycle.h23,
                ),
              ),
              // Far enough down that the listbox never covers it.
              Positioned(
                bottom: 0,
                left: 0,
                width: 200,
                height: 80,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FluentTimePicker));
      await tester.pumpAndSettle();
      expect(find.text('09:00'), findsOneWidget);

      await tester.tapAt(const Offset(100, 560));
      await tester.pumpAndSettle();

      expect(find.text('09:00'), findsNothing, reason: 'the click dismissed');
      expect(taps, 1, reason: 'and the click also landed');
    });

    // Nothing covered this before: the barrier sat ABOVE the trigger, so the
    // field's own toggle could not fire while the listbox was open and this
    // path was dead. With the barrier gone the click reaches the field, and it
    // has to close exactly once rather than close-then-reopen.
    testWidgets('clicking the field while open closes it exactly once', (
      tester,
    ) async {
      final opens = <bool>[];
      await _pump(tester, onOpenChange: opens.add);

      await tester.tap(find.byType(FluentTimePicker));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FluentTimePicker));
      await tester.pumpAndSettle();

      expect(opens, <bool>[true, false]);
      expect(find.text('09:00'), findsNothing);
    });

    // The other half of the group, and the only part of it a click cannot
    // show: a press that lands on the listbox has to count as *inside*. A
    // scroll drag starts with a press, and `RenderTapRegionSurface` reads
    // presses, not taps — so a listbox outside the trigger's group would
    // dismiss itself the moment the user reached in to scroll it. A row click
    // would not reveal that: the recogniser keeps the pointer route it
    // captured on the press, so the row still commits either way.
    testWidgets('a scroll drag inside the listbox does not dismiss it', (
      tester,
    ) async {
      await _pump(tester, startHour: 0, endHour: 24, increment: 15);

      await tester.tap(find.byType(FluentTimePicker));
      await tester.pumpAndSettle();
      expect(find.text('00:15'), findsOneWidget);

      await tester.drag(find.text('00:15'), const Offset(0, -120));
      await tester.pumpAndSettle();

      expect(
        find.byType(SingleChildScrollView),
        findsOneWidget,
        reason: 'the listbox is still open',
      );
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

  // The sibling of the date picker's bug: this picker owns its controller too,
  // so a build-time placeholder read left the hint painted over typed text.
  group('FluentTimePicker — the placeholder', () {
    testWidgets('is hidden by typed text', (tester) async {
      await _pump(tester, freeform: true, placeholder: const Text('hh:mm'));
      expect(find.text('hh:mm'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), '09:30');
      await tester.pump();
      expect(find.text('hh:mm'), findsNothing);
    });

    testWidgets('is hidden by an initial value', (tester) async {
      await _pump(
        tester,
        selectedTime: DateTime(2026, 3, 10, 9, 30),
        placeholder: const Text('hh:mm'),
      );
      expect(find.text('hh:mm'), findsNothing);
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

  // #30: accentWidth was resolved into the style and then dropped, because the
  // shared faceplate drew its focus bar at a constant FluentStroke.thick.
  testWidgets('style.accentWidth sizes the focus bar', (tester) async {
    await _pump(
      tester,
      autofocus: true,
      style: const FluentTimePickerStyle(
        accentWidth: WidgetStatePropertyAll<double?>(8),
      ),
    );
    final bar = find.descendant(
      of: find.byType(FluentTimePicker),
      matching: find.byType(FluentInputFocusUnderline),
    );
    expect(tester.widget<FluentInputFocusUnderline>(bar).thickness, 8);
    expect(tester.getSize(bar).height, 8);
  });

  // Upstream's TimePicker is a `.fui-Combobox`: `useComboboxStyles.styles.ts`
  // as it renders in Chrome on the live storybook, driven with a real mouse.
  group('FluentTimePicker — upstream Combobox rules', () {
    final colors = FluentThemeData.light(
      fontPlatform: FluentFontPlatform.web,
    ).colors;
    final bar = find.descendant(
      of: find.byType(FluentTimePicker),
      matching: find.byType(FluentInputFocusUnderline),
    );

    Future<TestGesture> hover(WidgetTester tester) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byType(FluentTimePicker)));
      await tester.pump();
      return mouse;
    }

    testWidgets('hover wins over focus; a press turns the bar Pressed', (
      tester,
    ) async {
      // `:focus-within` is its own rule, sorted before `:hover` — unlike
      // Input's combined `:active,:focus-within`, which holds Pressed.
      await _pump(tester, autofocus: true);
      expect(_border(tester).borderColor, colors.neutralStroke1Pressed);
      expect(
        _border(tester).bottomBorderColor,
        colors.neutralStrokeAccessiblePressed,
      );

      final mouse = await hover(tester);
      expect(_border(tester).borderColor, colors.neutralStroke1Hover);
      expect(
        _border(tester).bottomBorderColor,
        colors.neutralStrokeAccessibleHover,
      );
      expect(
        tester.widget<FluentInputFocusUnderline>(bar).color,
        colors.compoundBrandStroke,
      );

      // `:focus-within:active::after`.
      await mouse.down(tester.getCenter(find.byType(FluentTimePicker)));
      await tester.pump();
      expect(_border(tester).borderColor, colors.neutralStroke1Pressed);
      expect(
        tester.widget<FluentInputFocusUnderline>(bar).color,
        colors.compoundBrandStrokePressed,
      );
      await mouse.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a held mouse press focuses at pointer-down; the click opens', (
      tester,
    ) async {
      // Chrome focuses the `<input>` on mousedown — left or right — so the
      // bar grows while the press is held; the listbox waits for the click,
      // and a right press never opens it. The picker above holds focus
      // first: its outside-press blur must not undo this one's focus.
      for (final freeform in <bool>[false, true]) {
        final first = FocusNode();
        final node = FocusNode();
        addTearDown(first.dispose);
        addTearDown(node.dispose);
        await tester.pumpWidget(
          FluentApp(
            theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
            home: Center(
              child: SizedBox(
                width: 280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FluentTimePicker(
                      dateAnchor: _anchor,
                      focusNode: first,
                      onTimeChange: _noop,
                    ),
                    FluentTimePicker(
                      key: const Key('picker'),
                      dateAnchor: _anchor,
                      focusNode: node,
                      freeform: freeform,
                      startHour: 8,
                      endHour: 11,
                      increment: 60,
                      hourCycle: FluentHourCycle.h23,
                      onTimeChange: _noop,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        final picker = find.byKey(const Key('picker'));
        final bar = find.descendant(
          of: picker,
          matching: find.byType(FluentInputFocusUnderline),
        );
        final centre = tester.getCenter(picker);

        for (final buttons in <int>[kPrimaryButton, kSecondaryMouseButton]) {
          final reason = 'freeform $freeform, buttons $buttons';
          first.requestFocus();
          await tester.pumpAndSettle();
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
            buttons: buttons,
          );
          await mouse.addPointer(location: centre);
          await mouse.down(centre);
          await tester.pumpAndSettle();
          expect(node.hasFocus, isTrue, reason: '$reason, held');
          expect(
            tester.widget<FluentInputFocusUnderline>(bar).focused,
            isTrue,
            reason: '$reason, held',
          );
          expect(find.text('09:00'), findsNothing, reason: '$reason, held');

          await mouse.up();
          await tester.pumpAndSettle();
          expect(
            find.text('09:00'),
            buttons == kPrimaryButton ? findsOneWidget : findsNothing,
            reason: '$reason, released',
          );
          await mouse.removePointer();
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        }
      }
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('a right press is not :active; the chevron is a pointer', (
      tester,
    ) async {
      // Chrome sets `:active` for the primary and middle buttons only, and
      // `useComboboxStyles` gives the icon `cursor: pointer`.
      await _pump(tester);
      final chevron = tester.getCenter(find.byIcon(fluentTimePickerChevron));
      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await mouse.addPointer(location: chevron);
      addTearDown(mouse.removePointer);
      await tester.pump();
      expect(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
        SystemMouseCursors.click,
      );
      await mouse.down(chevron);
      await tester.pump();
      expect(_border(tester).borderColor, colors.neutralStroke1Hover);
      await mouse.up();
      await tester.pumpAndSettle();
    });

    testWidgets('Underline and the filled appearances never ramp', (
      tester,
    ) async {
      // Combobox has no `underlineInteractive` or `filledInteractive`.
      await _pump(
        tester,
        autofocus: true,
        appearance: FluentTimePickerAppearance.underline,
      );
      await hover(tester);
      expect(_border(tester).borderColor, isNull);
      expect(_border(tester).bottomBorderColor, colors.neutralStrokeAccessible);

      await _pump(
        tester,
        autofocus: true,
        appearance: FluentTimePickerAppearance.filledDarker,
      );
      expect(_border(tester).borderColor, colors.transparentStroke);
      expect(_border(tester).bottomBorderColor, isNull);
    });

    testWidgets('error outranks disabled, as Chrome renders it', (
      tester,
    ) async {
      // `useComboboxStyles` keeps `invalid` on a disabled picker, and its
      // `:not(:focus-within)` out-specifies `disabled`'s plain class: Chrome
      // reads rgb(209, 52, 56) on a disabled, aria-invalid TimePicker.
      final danger = colors.palette.stroke2Rest(FluentPaletteFamily.red);
      for (final appearance in FluentTimePickerAppearance.values) {
        await _pump(
          tester,
          onTimeChange: null,
          error: true,
          appearance: appearance,
        );
        final underline = appearance == FluentTimePickerAppearance.underline;
        expect(
          _border(tester).borderColor,
          underline ? isNull : danger,
          reason: appearance.name,
        );
        if (underline) expect(_border(tester).bottomBorderColor, danger);
      }
    });

    testWidgets('Underline keeps the bar\'s 4px radii and overhangs a pixel', (
      tester,
    ) async {
      // Combobox never zeroes `::after`'s radius, as Input does; with no side
      // borders, `left/right: -1px` puts it a pixel past the root each side.
      for (final appearance in [
        FluentTimePickerAppearance.outline,
        FluentTimePickerAppearance.underline,
      ]) {
        await _pump(tester, autofocus: true, appearance: appearance);
        final overhang = appearance == FluentTimePickerAppearance.underline
            ? 1.0
            : 0.0;
        final box = tester.getRect(find.byType(FluentTimePicker));
        expect(tester.getRect(bar).left, box.left - overhang);
        expect(tester.getRect(bar).right, box.right + overhang);
        expect(
          tester.widget<FluentInputFocusUnderline>(bar).borderRadius,
          const BorderRadius.vertical(bottom: FluentRadius.medium),
        );
      }
    });

    testWidgets('a tight parent height stretches the box, bar and all', (
      tester,
    ) async {
      // A CSS `height` sizes the border box, and `::after` sits on its bottom.
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Center(
            child: SizedBox(
              width: 280,
              height: 60,
              child: FluentTimePicker(dateAnchor: _anchor, onTimeChange: _noop),
            ),
          ),
        ),
      );
      final painted = find.descendant(
        of: find.byType(FluentTimePicker),
        matching: find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is FluentInputBorderPainter,
        ),
      );
      expect(tester.getRect(painted).height, 60);
      expect(tester.getRect(bar).bottom, tester.getRect(painted).bottom);
    });

    testWidgets('the text and the chevron sit on upstream\'s pixels', (
      tester,
    ) async {
      // The `<input>`'s `padding-left` is 8 / 12 / 18 inside the 1px border;
      // `columnGap` and the chevron's `marginLeft` put 4 / 4 / 12 between the
      // field and the glyph.
      const upstream = {
        FluentTimePickerSize.small: (text: 9.0, gap: 4.0),
        FluentTimePickerSize.medium: (text: 13.0, gap: 4.0),
        FluentTimePickerSize.large: (text: 19.0, gap: 12.0),
      };
      for (final entry in upstream.entries) {
        await tester.pumpWidget(
          FluentApp(
            theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
            home: Center(
              child: SizedBox(
                width: 280,
                child: FluentTimePicker(
                  dateAnchor: _anchor,
                  size: entry.key,
                  onTimeChange: _noop,
                ),
              ),
            ),
          ),
        );
        final box = tester.getRect(find.byType(FluentTimePicker));
        final field = tester.getRect(find.byType(EditableText));
        final chevron = tester.getRect(find.byIcon(fluentTimePickerChevron));
        expect(field.left - box.left, entry.value.text, reason: '${entry.key}');
        expect(
          chevron.left - field.right,
          entry.value.gap,
          reason: '${entry.key}',
        );
      }
    });

    test('the root carries upstream\'s 250px minimum width', () {
      for (final size in FluentTimePickerSize.values) {
        final style = resolveFluentTimePickerStyle(
          resolveFluentTimePickerState(
            controller: TextEditingController(),
            focusNode: FocusNode(),
            editableTextKey: GlobalKey<EditableTextState>(),
            size: size,
          ),
          FluentThemeData.light(),
        );
        expect(
          style.minimumSize!.resolve(const <WidgetState>{})!.width,
          250,
          reason: size.name,
        );
      }
    });

    testWidgets('the clear glyph replaces the chevron, which stays announced', (
      tester,
    ) async {
      // `showClearIcon && iconStyles.visuallyHidden` on the expand icon: one
      // glyph shows at a time, and the chevron stays in the accessibility
      // tree.
      await _pump(
        tester,
        clearable: true,
        selectedTime: DateTime(2026, 3, 10, 9),
      );
      final clear = tester.getRect(find.byIcon(fluentTimePickerClear));
      final chevron = find.byIcon(fluentTimePickerChevron);
      expect(tester.getRect(chevron), clear, reason: 'the same slot');
      expect(
        tester
            .widget<Opacity>(
              find.ancestor(of: chevron, matching: find.byType(Opacity)),
            )
            .opacity,
        0,
      );
      expect(find.bySemanticsLabel('Open'), findsOneWidget);
    });
  });
}
