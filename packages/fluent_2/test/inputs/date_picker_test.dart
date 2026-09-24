import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/internal/input_modality.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _today = DateTime(2026, 3, 10);

Future<void> _pump(
  WidgetTester tester, {
  DateTime? value,
  ValueChanged<DateTime?>? onSelectDate = _noop,
  bool allowTextInput = false,
  bool openOnClick = true,
  bool required = false,
  DateTime? minDate,
  DateTime? maxDate,
  ValueChanged<FluentDatePickerValidationResult>? onValidationResult,
  FluentDatePickerErrorStrings? errorStrings,
  bool reducedMotion = false,
  Widget? placeholder,
  ValueChanged<bool>? onOpenChange,
  Widget Function(Widget child)? wrap,
}) async {
  final picker = FluentDatePicker(
    today: _today,
    value: value,
    onSelectDate: onSelectDate,
    allowTextInput: allowTextInput,
    openOnClick: openOnClick,
    required: required,
    minDate: minDate,
    maxDate: maxDate,
    onValidationResult: onValidationResult,
    errorStrings: errorStrings,
    placeholder: placeholder,
    onOpenChange: onOpenChange,
  );
  await tester.pumpWidget(
    FluentApp(
      theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      // copyWith, never a bare MediaQueryData: constructing one from scratch
      // sets `size` to zero, and the popup reads the viewport height to decide
      // whether to flip above the field.
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reducedMotion),
          // Top-aligned with a little headroom: centring a picker in a 600px
          // test view leaves too little space either side and the popup flips
          // above into nothing, which is a property of the view, not the widget.
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: SizedBox(
                width: 300,
                child: wrap == null ? picker : wrap(picker),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _noop(DateTime? _) {}

/// The faceplate's own painted box.
BoxDecoration _faceplate(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(FluentDatePicker),
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
        of: find.byType(FluentDatePicker),
        matching: find.byType(CustomPaint),
      ),
    )
    .map((paint) => paint.painter)
    .whereType<FluentInputBorderPainter>()
    .single;

TextEditingController _controller(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller;

/// Whether the primary focus sits inside the popup's calendar.
bool _focusInCalendar() =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<FluentCalendar>() !=
    null;

/// A left mouse press at [from], moved to [to] in steps, then released.
Future<void> _drag(WidgetTester tester, Offset from, Offset to) async {
  final mouse = await tester.startGesture(
    from,
    kind: PointerDeviceKind.mouse,
    buttons: kPrimaryMouseButton,
  );
  await tester.pump(const Duration(milliseconds: 80));
  for (var i = 1; i <= 5; i++) {
    await mouse.moveTo(Offset.lerp(from, to, i / 5)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await mouse.up();
  await tester.pumpAndSettle();
}

/// A left mouse click at [at], held 80ms as a hand holds it.
Future<void> _click(WidgetTester tester, Offset at) => _drag(tester, at, at);

void main() {
  setUp(FluentInputModality.debugReset);

  group('FluentDatePicker — the read-only ramp', () {
    // `allowTextInput` defaults to false, so a date picker is read-only by
    // default. Upstream gives `readOnly` no styling at all, so a default picker
    // must resolve the live ramp — only `enabled` may grey it out. The picker
    // once had to hide its read-only flag from the style resolver to get this;
    // this guards against the flag ever being styled again.
    testWidgets('a default picker is not painted as disabled', (tester) async {
      await _pump(tester);
      final live = _faceplate(tester);
      final liveBorder = _border(tester).borderColor;

      await _pump(tester, onSelectDate: null);
      final disabled = _faceplate(tester);

      expect(live.color, isNot(disabled.color));
      expect(liveBorder, isNot(_border(tester).borderColor));
    });
  });

  // Upstream's DatePicker is a `.fui-Input`: `useInputStyles` as it renders in
  // Chrome on the live storybook, driven with a real mouse.
  group('FluentDatePicker — upstream Input rules', () {
    final colors = FluentThemeData.light(
      fontPlatform: FluentFontPlatform.web,
    ).colors;
    final picker = find.byType(FluentDatePicker);
    final bar = find.descendant(
      of: picker,
      matching: find.byType(FluentInputFocusUnderline),
    );

    testWidgets('hover ramps the border; any button presses and focuses it', (
      tester,
    ) async {
      // Chrome sets `:active` on `.fui-Input` for the right button as well as
      // the left and middle, and focuses the `<input>` on mousedown for all
      // three, so `:focus-within:active::after` grows the bar Pressed under
      // each of them. The focus outlives the press: #b3b3b3 sides and the
      // #0f6cbd bar after a middle or right release (storybook).
      await _pump(tester);
      expect(_border(tester).borderColor, colors.neutralStroke1);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(picker));
      await tester.pump();
      expect(_border(tester).borderColor, colors.neutralStroke1Hover);
      expect(
        _border(tester).bottomBorderColor,
        colors.neutralStrokeAccessibleHover,
      );

      for (final button in <int>[
        kPrimaryMouseButton,
        kMiddleMouseButton,
        kSecondaryMouseButton,
      ]) {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(tester.widget<FluentInputFocusUnderline>(bar).focused, isFalse);
        expect(_border(tester).borderColor, colors.neutralStroke1Hover);

        final press = await tester.startGesture(
          tester.getCenter(picker),
          kind: PointerDeviceKind.mouse,
          buttons: button,
        );
        await tester.pump();
        await tester.pump();
        expect(
          _border(tester).borderColor,
          colors.neutralStroke1Pressed,
          reason: 'button $button: sides',
        );
        expect(
          _border(tester).bottomBorderColor,
          colors.neutralStrokeAccessiblePressed,
          reason: 'button $button: bottom',
        );
        expect(
          tester.widget<FluentInputFocusUnderline>(bar).focused,
          isTrue,
          reason: 'button $button: the bar grows while held',
        );
        expect(
          tester.widget<FluentInputFocusUnderline>(bar).color,
          colors.compoundBrandStrokePressed,
          reason: 'button $button: bar, #0f548c',
        );
        // Cancelled rather than released, so no tap opens the popup.
        await press.cancel();
        await tester.pump();
        expect(find.byType(FluentCalendar), findsNothing);
        expect(
          _border(tester).borderColor,
          colors.neutralStroke1Pressed,
          reason: 'button $button: focus holds the Pressed sides',
        );
        expect(
          tester.widget<FluentInputFocusUnderline>(bar).color,
          colors.compoundBrandStroke,
          reason: 'button $button: bar, #0f6cbd',
        );
      }
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('a left press focuses at once; the click still opens', (
      tester,
    ) async {
      // Chrome focuses the `<input>` on mousedown, so the #0f548c bar grows
      // under a held press, and the popup opens on the click. Focus arrives
      // the way the field's own tap brings it: a bare `requestFocus` on
      // desktop selects the whole value, where a browser selects nothing.
      await _pump(tester, value: DateTime(2026, 3, 14));
      final press = await tester.startGesture(
        tester.getCenter(picker),
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );
      await tester.pump();
      await tester.pump();
      expect(tester.widget<FluentInputFocusUnderline>(bar).focused, isTrue);
      expect(
        tester.widget<FluentInputFocusUnderline>(bar).color,
        colors.compoundBrandStrokePressed,
      );
      expect(_controller(tester).selection.isCollapsed, isTrue);
      expect(find.byType(FluentCalendar), findsNothing);

      await press.up();
      await tester.pumpAndSettle();
      expect(find.byType(FluentCalendar), findsOneWidget);
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('focus in the open calendar is not focus in the field', (
      tester,
    ) async {
      // The calendar takes focus, so `.fui-Input` loses `:focus-within`: no
      // bar, and the resting mouse shows the Hover ramp, #c7c7c7 / #575757
      // (Chrome). Escape hands focus back, and the bar with it.
      await _pump(tester);
      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );
      await mouse.addPointer(location: tester.getCenter(picker));
      addTearDown(mouse.removePointer);
      await mouse.down(tester.getCenter(picker));
      await tester.pump(const Duration(milliseconds: 80));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(find.byType(FluentCalendar), findsOneWidget);

      expect(tester.widget<FluentInputFocusUnderline>(bar).focused, isFalse);
      expect(_border(tester).borderColor, colors.neutralStroke1Hover);
      expect(
        _border(tester).bottomBorderColor,
        colors.neutralStrokeAccessibleHover,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(FluentCalendar), findsNothing);
      expect(tester.widget<FluentInputFocusUnderline>(bar).focused, isTrue);
      expect(_border(tester).borderColor, colors.neutralStroke1Pressed);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('a press while the calendar is open leaves focus in it', (
      tester,
    ) async {
      // Upstream traps focus in the popup (`legacyTrapFocus`), so a mousedown
      // on the `<input>` never focuses it while the calendar is open: any
      // button, held, shows the Pressed sides (#b3b3b3) and no bar, and the
      // popup keeps focus (Chrome).
      await _pump(tester);
      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );
      await mouse.addPointer(location: tester.getCenter(picker));
      addTearDown(mouse.removePointer);
      await mouse.down(tester.getCenter(picker));
      await mouse.up();
      await tester.pumpAndSettle();
      final calendar = find.byType(FluentCalendar);
      expect(calendar, findsOneWidget);

      for (final button in <int>[
        kPrimaryMouseButton,
        kMiddleMouseButton,
        kSecondaryMouseButton,
      ]) {
        final press = await tester.startGesture(
          tester.getCenter(picker),
          kind: PointerDeviceKind.mouse,
          buttons: button,
        );
        await tester.pump();
        await tester.pump();
        expect(
          tester.widget<FluentInputFocusUnderline>(bar).focused,
          isFalse,
          reason: 'button $button: no bar',
        );
        expect(
          _border(tester).borderColor,
          colors.neutralStroke1Pressed,
          reason: 'button $button: sides',
        );
        expect(
          find.ancestor(
            of: find.byWidgetPredicate(
              (w) =>
                  w is Focus &&
                  w.focusNode == FocusManager.instance.primaryFocus,
            ),
            matching: calendar,
          ),
          findsOneWidget,
          reason: 'button $button: focus stays in the calendar',
        );
        await press.cancel();
        await tester.pumpAndSettle();
        expect(calendar, findsOneWidget, reason: 'button $button: still open');
      }
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('focus holds the Pressed stops through a hover', (
      tester,
    ) async {
      await _pump(
        tester,
        wrap: (_) => FluentDatePicker(
          today: _today,
          onSelectDate: _noop,
          autofocus: true,
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(picker));
      await tester.pump();
      expect(_border(tester).borderColor, colors.neutralStroke1Pressed);
      expect(
        _border(tester).bottomBorderColor,
        colors.neutralStrokeAccessiblePressed,
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('the cursor is a pointer, or the arrow when disabled', (
      tester,
    ) async {
      // Chrome: root, input and calendar glyph are all `pointer` — typing
      // allowed or not — and all `default` when disabled, where Input's own
      // `not-allowed` is overridden. A disabled picker does not ramp either.
      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        pointer: 1,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      for (final (enabled, allowTextInput) in <(bool, bool)>[
        (true, false),
        (true, true),
        (false, false),
      ]) {
        await _pump(
          tester,
          onSelectDate: enabled ? _noop : null,
          allowTextInput: allowTextInput,
        );
        final expected = enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic;
        for (final at in <Finder>[
          find.byType(EditableText),
          find.byIcon(fluentDatePickerIcon),
        ]) {
          await mouse.moveTo(tester.getCenter(at));
          await tester.pump();
          expect(
            RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
            expected,
            reason: 'enabled: $enabled, text: $allowTextInput, over $at',
          );
        }
        if (!enabled) {
          expect(_border(tester).borderColor, colors.neutralStrokeDisabled);
          final press = await tester.startGesture(
            tester.getCenter(picker),
            kind: PointerDeviceKind.mouse,
          );
          await tester.pump();
          expect(_border(tester).borderColor, colors.neutralStrokeDisabled);
          await press.cancel();
        }
        await mouse.moveTo(Offset.zero);
        await tester.pump();
      }
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('a tight parent height stretches the box, bar and all', (
      tester,
    ) async {
      // A CSS `height` sizes the border box, and `::after` sits on its bottom.
      for (final inline in <bool>[false, true]) {
        await _pump(
          tester,
          wrap: (_) => SizedBox(
            height: 60,
            child: FluentDatePicker(
              today: _today,
              onSelectDate: _noop,
              inlinePopup: inline,
            ),
          ),
        );
        final painted = find.descendant(
          of: picker,
          matching: find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is FluentInputBorderPainter,
          ),
        );
        expect(tester.getRect(painted).height, 60, reason: 'inline: $inline');
        expect(
          tester.getRect(bar).bottom,
          tester.getRect(painted).bottom,
          reason: 'inline: $inline',
        );
      }
    });

    testWidgets('re-enabled under a resting mouse, it hovers and presses', (
      tester,
    ) async {
      // Chrome: a disabled root still matches `:hover`, and `:active` under a
      // held press, so dropping `disabled` shows both at once, unmoved.
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await _pump(tester);
      await mouse.moveTo(tester.getCenter(picker));
      await tester.pump();
      await _pump(tester, onSelectDate: null);
      expect(_border(tester).borderColor, colors.neutralStrokeDisabled);
      await _pump(tester);
      expect(_border(tester).borderColor, colors.neutralStroke1Hover);

      await _pump(tester, onSelectDate: null);
      final press = await tester.startGesture(
        tester.getCenter(picker),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await _pump(tester);
      expect(_border(tester).borderColor, colors.neutralStroke1Pressed);
      await press.cancel();
      await tester.pump();
      expect(_border(tester).borderColor, colors.neutralStroke1Hover);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('a picker removed mid-press takes the release quietly', (
      tester,
    ) async {
      await _pump(tester);
      final press = await tester.startGesture(
        tester.getCenter(picker),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await _pump(tester, wrap: (_) => const SizedBox());
      await press.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  });

  // The picker owns its controller and does not rebuild on a keystroke, so a
  // placeholder whose visibility was read at build time stayed painted over
  // whatever was typed underneath it.
  group('FluentDatePicker — the placeholder', () {
    testWidgets('is hidden by a typed date', (tester) async {
      await _pump(
        tester,
        allowTextInput: true,
        openOnClick: false,
        placeholder: const Text('M/D/YYYY'),
      );
      expect(find.text('M/D/YYYY'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), '12/12/2026');
      await tester.pump();
      expect(find.text('M/D/YYYY'), findsNothing);

      await tester.enterText(find.byType(EditableText), '');
      await tester.pump();
      expect(find.text('M/D/YYYY'), findsOneWidget);
    });

    testWidgets('is hidden by an initial value', (tester) async {
      await _pump(
        tester,
        value: DateTime(2026, 12, 12),
        placeholder: const Text('M/D/YYYY'),
      );
      expect(find.text('M/D/YYYY'), findsNothing);
      expect(_controller(tester).text, '12/12/2026');
    });

    testWidgets('is hidden by a date picked from the calendar', (tester) async {
      await _pump(tester, placeholder: const Text('M/D/YYYY'));
      expect(find.text('M/D/YYYY'), findsOneWidget);

      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();
      await tester.tap(find.text('12').first);
      await tester.pumpAndSettle();

      expect(find.text('M/D/YYYY'), findsNothing);
    });
  });

  // Upstream's Input slots and `onChange`, which the picker forwards.
  group('FluentDatePicker — slots and onChanged', () {
    testWidgets('contentBefore is rendered', (tester) async {
      await _pump(
        tester,
        wrap: (_) => FluentDatePicker(
          today: _today,
          onSelectDate: _noop,
          contentBefore: const Text('BEFORE'),
        ),
      );
      expect(find.text('BEFORE'), findsOneWidget);
    });

    testWidgets('contentAfter replaces the calendar glyph', (tester) async {
      await _pump(tester);
      expect(find.byIcon(fluentDatePickerIcon), findsOneWidget);

      await _pump(
        tester,
        wrap: (_) => FluentDatePicker(
          today: _today,
          onSelectDate: _noop,
          contentAfter: const Text('AFTER'),
        ),
      );
      expect(find.text('AFTER'), findsOneWidget);
      expect(find.byIcon(fluentDatePickerIcon), findsNothing);
    });

    testWidgets('onChanged fires per keystroke, onSelectDate does not', (
      tester,
    ) async {
      final typed = <String>[];
      var selections = 0;
      await _pump(
        tester,
        wrap: (_) => FluentDatePicker(
          today: _today,
          allowTextInput: true,
          openOnClick: false,
          onChanged: typed.add,
          onSelectDate: (_) => selections++,
        ),
      );

      await tester.enterText(find.byType(EditableText), '3/5/2026');
      await tester.pump();

      expect(typed, <String>['3/5/2026']);
      expect(selections, 0, reason: 'typing is not a commit');
    });
  });

  group('FluentDatePicker — popup placement', () {
    testWidgets('inlinePopup renders in the tree, not the Overlay', (
      tester,
    ) async {
      await _pump(
        tester,
        wrap: (_) => FluentDatePicker(
          today: _today,
          onSelectDate: _noop,
          inlinePopup: true,
        ),
      );

      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();

      expect(find.byType(FluentCalendar), findsOneWidget);
      // The distinguishing property: a portalled popup is a sibling of the app,
      // an inline one is a descendant of the picker.
      expect(
        find.descendant(
          of: find.byType(FluentDatePicker),
          matching: find.byType(FluentCalendar),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the overlay popup is not a descendant of the picker', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();

      expect(find.byType(FluentCalendar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FluentDatePicker),
          matching: find.byType(FluentCalendar),
        ),
        findsNothing,
      );
    });

    testWidgets('showMonthPickerAsOverlay keeps one panel and drills', (
      tester,
    ) async {
      await _pump(
        tester,
        wrap: (_) => FluentDatePicker(
          today: _today,
          onSelectDate: _noop,
          showMonthPickerAsOverlay: true,
        ),
      );
      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();

      // Side by side, "2026" is already on screen as the second panel's
      // caption; with the overlay it only appears after drilling.
      expect(find.text('2026'), findsNothing);
      await tester.tap(find.text('March 2026'));
      await tester.pumpAndSettle();
      expect(find.text('2026'), findsOneWidget);
    });
  });

  group('FluentDatePicker — forwarded calendar props', () {
    testWidgets('showWeekNumbers reaches the calendar', (tester) async {
      await _pump(
        tester,
        wrap: (_) => FluentDatePicker(
          today: _today,
          onSelectDate: _noop,
          showWeekNumbers: true,
        ),
      );
      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Week 10'), findsOneWidget);
    });

    testWidgets('showCloseButton closes the popup', (tester) async {
      await _pump(
        tester,
        wrap: (_) => FluentDatePicker(
          today: _today,
          onSelectDate: _noop,
          showCloseButton: true,
        ),
      );
      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();
      expect(find.byType(FluentCalendar), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(FluentCalendar), findsNothing);
    });
  });

  group('FluentDatePicker — open and close', () {
    final picker = find.byType(FluentDatePicker);
    final calendar = find.byType(FluentCalendar);
    bool barFocused(WidgetTester tester) => tester
        .widget<FluentInputFocusUnderline>(
          find.descendant(
            of: picker,
            matching: find.byType(FluentInputFocusUnderline),
          ),
        )
        .focused;

    testWidgets('clicking opens, clicking again leaves it open', (
      tester,
    ) async {
      // Upstream's `onInputClick` dismisses only when `allowTextInput` is set;
      // without it a click on the open picker's input does nothing, and the
      // focus trap keeps focus in the calendar (Chrome).
      final opens = <bool>[];
      await _pump(tester, onOpenChange: opens.add);
      expect(calendar, findsNothing);

      await _click(tester, tester.getCenter(picker));
      expect(calendar, findsOneWidget);
      expect(find.text('March 2026'), findsOneWidget);

      await _click(tester, tester.getCenter(picker));
      expect(calendar, findsOneWidget);
      expect(opens, <bool>[true]);
      expect(_focusInCalendar(), isTrue);
      expect(barFocused(tester), isFalse);
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('with allowTextInput, the click that closes it lands the caret '
        'where it went down; one on the glyph keeps it', (tester) async {
      // Chrome, text-input story with a value, opened by a click near the
      // start: the trap takes focus from the closing press but not its caret,
      // so the dismissing `focus()` shows the caret where that press went down
      // — a drag's press included, and no range — never the select-all a
      // tab-in gives. A click on the glyph beside the `<input>` moves nothing.
      final opens = <bool>[];
      await _pump(
        tester,
        allowTextInput: true,
        value: DateTime(2026, 3, 14),
        onOpenChange: opens.add,
      );
      final text = tester.getRect(find.byType(EditableText));
      final near = Offset(text.left + 8, text.center.dy);
      final far = Offset(text.left + 60, text.center.dy);
      TextSelection caretAt(Offset at) => TextSelection.fromPosition(
        tester
            .state<EditableTextState>(find.byType(EditableText))
            .renderEditable
            .getPositionForPoint(at),
      );
      expect(caretAt(near), isNot(caretAt(far)));

      await _click(tester, near);
      expect(calendar, findsOneWidget);
      expect(_controller(tester).selection, caretAt(near));

      await _click(tester, far);
      expect(calendar, findsNothing);
      expect(opens, <bool>[true, false]);
      expect(barFocused(tester), isTrue);
      expect(_controller(tester).selection, caretAt(far), reason: 'click');

      await _click(tester, near);
      await _click(tester, tester.getCenter(find.byIcon(fluentDatePickerIcon)));
      expect(calendar, findsNothing);
      expect(_controller(tester).selection, caretAt(near), reason: 'glyph');

      await _click(tester, near);
      await _drag(tester, far, far + const Offset(40, 0));
      expect(calendar, findsNothing);
      expect(_controller(tester).selection, caretAt(far), reason: 'drag');
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('a quick second click counts, as Chrome fires one per click', (
      tester,
    ) async {
      // Chrome, 50–250ms between two clicks or a native dblclick: text-input
      // closes again with the input focused, default stays open. Flutter
      // reports the second as a double tap, never a single tap up.
      for (final allowTextInput in <bool>[false, true]) {
        await tester.pumpWidget(const SizedBox());
        final opens = <bool>[];
        await _pump(
          tester,
          allowTextInput: allowTextInput,
          onOpenChange: opens.add,
        );
        final center = tester.getCenter(picker);
        for (var i = 0; i < 2; i++) {
          final mouse = await tester.startGesture(
            center,
            kind: PointerDeviceKind.mouse,
            buttons: kPrimaryMouseButton,
          );
          await tester.pump(const Duration(milliseconds: 60));
          await mouse.up();
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
        final mode = 'allowTextInput $allowTextInput';
        if (allowTextInput) {
          expect(opens, <bool>[true, false], reason: mode);
          expect(barFocused(tester), isTrue, reason: mode);
        } else {
          expect(opens, <bool>[true], reason: mode);
          expect(_focusInCalendar(), isTrue, reason: mode);
        }
      }
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('a drag released on a zoomed field still opens it', (
      tester,
    ) async {
      // The example's preview zoom scales its story with a Transform.scale,
      // so the release is tested in the field's own coordinates rather than
      // against its unscaled rect. Pressed inside the unscaled box too, since
      // the test's SizedBox parent only hit-tests that much; released past it,
      // still on the field as painted.
      await _pump(
        tester,
        wrap: (child) => Transform.scale(
          scale: 2,
          alignment: Alignment.topLeft,
          child: child,
        ),
      );
      final origin = tester.getTopLeft(picker);
      await _drag(
        tester,
        origin + const Offset(150, 16),
        origin + const Offset(350, 20),
      );
      expect(calendar, findsOneWidget);
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('with allowTextInput, a press on the open picker keeps focus '
        'in the calendar', (tester) async {
      // Chrome, text-input story, calendar open: every button, held, leaves
      // focus in the popup and the bar down. A left release is the click that
      // closes; a middle or right release fires no click and changes nothing.
      await _pump(tester, allowTextInput: true, value: DateTime(2026, 3, 14));
      final center = tester.getCenter(picker);
      for (final button in <int>[
        kPrimaryMouseButton,
        kMiddleMouseButton,
        kSecondaryMouseButton,
      ]) {
        if (calendar.evaluate().isEmpty) await _click(tester, center);
        expect(calendar, findsOneWidget, reason: 'button $button: open');

        final press = await tester.startGesture(
          center,
          kind: PointerDeviceKind.mouse,
          buttons: button,
        );
        await tester.pump();
        await tester.pump();
        expect(_focusInCalendar(), isTrue, reason: 'button $button: held');
        expect(barFocused(tester), isFalse, reason: 'button $button: held');

        await press.up();
        await tester.pumpAndSettle();
        if (button == kPrimaryMouseButton) {
          expect(calendar, findsNothing, reason: 'the left click closes');
          expect(barFocused(tester), isTrue, reason: 'and focuses the field');
        } else {
          expect(calendar, findsOneWidget, reason: 'button $button: released');
          expect(_focusInCalendar(), isTrue, reason: 'button $button: up');
          expect(barFocused(tester), isFalse, reason: 'button $button: up');
        }
      }
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('a press dragged off the field and released outside does '
        'nothing more', (tester) async {
      // Chrome fires `click` on the common ancestor of the press and the
      // release, so a press on the `<input>` let go above it never reaches
      // `onInputClick`: closed, the field keeps the focus the press gave it
      // and does not open; open, nothing changes. A drag that ends back on
      // the field is still a click on it, and opens.
      for (final allowTextInput in <bool>[false, true]) {
        final mode = 'allowTextInput $allowTextInput';
        await tester.pumpWidget(const SizedBox());
        await _pump(tester, allowTextInput: allowTextInput);
        final center = tester.getCenter(picker);
        final above = Offset(center.dx, tester.getTopLeft(picker).dy - 20);

        await _drag(tester, center, above);
        expect(calendar, findsNothing, reason: '$mode: closed, released off');
        expect(barFocused(tester), isTrue, reason: '$mode: focus kept');

        await _drag(tester, center, center + const Offset(30, 0));
        expect(calendar, findsOneWidget, reason: '$mode: released on it');

        await _drag(tester, center, above);
        expect(calendar, findsOneWidget, reason: '$mode: open, released off');
        expect(_focusInCalendar(), isTrue, reason: '$mode: focus stays');
      }
    }, variant: TargetPlatformVariant.desktop());

    // Opening moves focus off the field on one frame and into the popup scope
    // on the next. A synchronous blur handler sees "neither has focus" in
    // between and closes the popup the click just opened; the guard is
    // post-frame precisely so it does not.
    testWidgets('the popup survives the frame after it opens', (tester) async {
      await _pump(tester);

      await tester.tap(find.byType(FluentDatePicker));
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(FluentCalendar), findsOneWidget);
    });

    testWidgets('openOnClick false blocks the click but not Enter', (
      tester,
    ) async {
      await _pump(tester, openOnClick: false);

      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();
      expect(find.byType(FluentCalendar), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(FluentCalendar), findsOneWidget);
    });

    testWidgets('a disabled picker never opens', (tester) async {
      await _pump(tester, onSelectDate: null);
      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();
      expect(find.byType(FluentCalendar), findsNothing);
    });

    // Load-bearing for the TapRegion, not just for closing: focus is inside
    // the calendar here, and a tap on empty canvas moves it nowhere, so the
    // focus-leaves-the-picker path cannot be what closes this.
    testWidgets('a light-dismiss tap closes it', (tester) async {
      await _pump(tester);
      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(FluentCalendar), findsNothing);
    });

    // The regression this pins: the popup used to hang a full-screen
    // `HitTestBehavior.opaque` barrier under itself, so a click on anything
    // behind an open calendar dismissed the calendar and went nowhere else —
    // the user had to click twice. Upstream dismisses from a document-level
    // `useOnClickOutside`, where the click dismisses AND lands.
    testWidgets('an outside click dismisses the popup and still lands', (
      tester,
    ) async {
      var taps = 0;
      final behind = FocusNode();
      addTearDown(behind.dispose);

      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Stack(
            children: <Widget>[
              Positioned(
                top: 0,
                left: 0,
                width: 300,
                child: FluentDatePicker(today: _today, onSelectDate: _noop),
              ),
              // Far enough down that the calendar never covers it.
              Positioned(
                bottom: 0,
                left: 0,
                width: 200,
                height: 80,
                child: Focus(
                  focusNode: behind,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      taps++;
                      behind.requestFocus();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();
      expect(find.byType(FluentCalendar), findsOneWidget);

      await tester.tapAt(const Offset(100, 560));
      await tester.pumpAndSettle();

      expect(
        find.byType(FluentCalendar),
        findsNothing,
        reason: 'the click dismissed',
      );
      expect(taps, 1, reason: 'and the click also landed');
      // `_syncEntry` restores focus only when the surface being torn down was
      // holding it. The tap-outside now fires on pointer *down*, before the
      // thing behind takes focus on pointer up, so that restore must not steal
      // the focus back off it.
      expect(behind.hasFocus, isTrue, reason: 'and the focus was not stolen');
    });

    // Nothing covered this before: the barrier sat ABOVE the trigger, so the
    // field's own toggle could not fire while the calendar was open and this
    // path was dead. With the barrier gone the click reaches the field, and it
    // has to close exactly once rather than close-then-reopen. Only with
    // `allowTextInput`: without it upstream's click leaves the popup open.
    testWidgets('clicking the field while open closes it exactly once', (
      tester,
    ) async {
      final opens = <bool>[];
      await _pump(tester, allowTextInput: true, onOpenChange: opens.add);

      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();

      expect(opens, <bool>[true, false]);
      expect(find.byType(FluentCalendar), findsNothing);
    });

    // `inlinePopup` is documented as having no light dismiss — it is a surface
    // in this widget's own tree, closed by focus leaving the picker — so no
    // outside-tap handler is registered for it.
    testWidgets('inlinePopup does not light-dismiss', (tester) async {
      await _pump(
        tester,
        wrap: (_) => FluentDatePicker(
          today: _today,
          onSelectDate: _noop,
          inlinePopup: true,
        ),
      );
      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();
      expect(find.byType(FluentCalendar), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(FluentCalendar), findsOneWidget);
    });
  });

  group('FluentDatePicker — selection', () {
    testWidgets('picking a day fills the field and closes', (tester) async {
      final picked = <DateTime?>[];
      await _pump(tester, onSelectDate: picked.add);

      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(FluentCalendar),
          matching: find.text('17'),
        ),
      );
      await tester.pumpAndSettle();

      expect(picked, <DateTime>[DateTime(2026, 3, 17)]);
      expect(_controller(tester).text, '3/17/2026');
      expect(find.byType(FluentCalendar), findsNothing);
    });

    testWidgets('a controlled value fills the field', (tester) async {
      await _pump(tester, value: DateTime(2026, 7, 4));
      expect(_controller(tester).text, '7/4/2026');
    });
  });

  group('FluentDatePicker — keyboard', () {
    // FluentCalendar binds no DismissIntent precisely so this can.
    testWidgets('Escape closes the popup from inside the calendar', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();
      expect(find.byType(FluentCalendar), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(FluentCalendar), findsNothing);
    });

    testWidgets('Escape hands focus back with the caret where it was', (
      tester,
    ) async {
      // Chrome, text-input story: Escape `focus()`es the `<input>`, and its
      // caret is where the opening click put it rather than select-all.
      await _pump(tester, allowTextInput: true, value: DateTime(2026, 3, 14));
      await _click(tester, tester.getCenter(find.byType(FluentDatePicker)));
      final caret = _controller(tester).selection;
      expect(caret.isCollapsed, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(FluentCalendar), findsNothing);
      expect(_controller(tester).selection, caret);
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('a picked day hands focus back with the caret after it', (
      tester,
    ) async {
      // Chrome, text-input story: after a pick the `<input>` is focused with
      // its caret after the new text. The parent echoing the value back must
      // not wipe that caret — rewriting unchanged text drops the selection.
      DateTime? value;
      await _pump(
        tester,
        allowTextInput: true,
        wrap: (_) => StatefulBuilder(
          builder: (context, setState) => FluentDatePicker(
            today: _today,
            value: value,
            allowTextInput: true,
            onSelectDate: (date) => setState(() => value = date),
          ),
        ),
      );
      await _click(tester, tester.getCenter(find.byType(FluentDatePicker)));
      await _click(tester, tester.getCenter(find.text('15').last));
      expect(find.byType(FluentCalendar), findsNothing);
      expect(value, DateTime(2026, 3, 15));
      final text = _controller(tester).text;
      expect(text, isNotEmpty);
      expect(
        _controller(tester).selection,
        TextSelection.collapsed(offset: text.length),
      );

      // Typed text committed with Enter comes back reformatted, and a
      // browser setting `value` leaves the caret after it.
      _controller(tester).value = const TextEditingValue(
        text: '2026-03-20',
        selection: TextSelection.collapsed(offset: 2),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(value, DateTime(2026, 3, 20));
      expect(_controller(tester).text, '3/20/2026');
      expect(
        _controller(tester).selection,
        const TextSelection.collapsed(offset: 9),
      );
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('ArrowDown opens the popup', (tester) async {
      await _pump(tester, openOnClick: false);
      // Tab in rather than click: openOnClick is off, so this focuses without
      // opening, which is the state the key has to act on.
      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.byType(FluentCalendar), findsOneWidget);
    });
  });

  group('FluentDatePicker — validation', () {
    Future<FluentDatePickerErrorType?> commit(
      WidgetTester tester,
      String text, {
      bool required = false,
      DateTime? maxDate,
    }) async {
      FluentDatePickerErrorType? error;
      await _pump(
        tester,
        allowTextInput: true,
        required: required,
        maxDate: maxDate,
        onValidationResult: (result) => error = result.error,
      );
      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), text);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      return error;
    }

    testWidgets('garbage is invalid-input', (tester) async {
      expect(
        await commit(tester, 'not a date'),
        FluentDatePickerErrorType.invalidInput,
      );
    });

    testWidgets('an impossible day is invalid-input, not rolled over', (
      tester,
    ) async {
      // DateTime(2026, 2, 30) silently becomes 2 March; the parser rejects it.
      expect(
        await commit(tester, '2/30/2026'),
        FluentDatePickerErrorType.invalidInput,
      );
    });

    testWidgets('past maxDate is out-of-bounds', (tester) async {
      expect(
        await commit(tester, '5/1/2026', maxDate: DateTime(2026, 3, 31)),
        FluentDatePickerErrorType.outOfBounds,
      );
    });

    testWidgets('empty and required is required-input', (tester) async {
      expect(
        await commit(tester, '', required: true),
        FluentDatePickerErrorType.requiredInput,
      );
    });

    testWidgets('a valid date commits and reports no error', (tester) async {
      final picked = <DateTime?>[];
      FluentDatePickerErrorType? error;
      await _pump(
        tester,
        allowTextInput: true,
        onSelectDate: picked.add,
        onValidationResult: (result) => error = result.error,
      );

      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), '4/2/2027');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      expect(error, isNull);
      expect(picked, <DateTime>[DateTime(2027, 4, 2)]);
    });

    // #17: errorStrings was stored and never read, so no message reached anyone.
    Future<FluentDatePickerValidationResult?> commitResult(
      WidgetTester tester, {
      FluentDatePickerErrorStrings? errorStrings,
      Widget Function(Widget child)? wrap,
    }) async {
      FluentDatePickerValidationResult? result;
      await _pump(
        tester,
        allowTextInput: true,
        errorStrings: errorStrings,
        onValidationResult: (r) => result = r,
        wrap: wrap,
      );
      await tester.enterText(find.byType(EditableText), 'not a date');
      // Let the picker see the focus arrive, so the blur below is a commit.
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('errorStrings supplies the reported message', (tester) async {
      final result = await commitResult(
        tester,
        errorStrings: const FluentDatePickerErrorStrings(invalidInput: 'Nope'),
      );
      expect(result?.error, FluentDatePickerErrorType.invalidInput);
      expect(result?.message, 'Nope');
    });

    testWidgets("without errorStrings the message is the ambient locale's", (
      tester,
    ) async {
      const turkish = Locale('tr');
      final result = await commitResult(
        tester,
        wrap: (picker) => Builder(
          builder: (context) => Localizations.override(
            context: context,
            locale: turkish,
            delegates: const <LocalizationsDelegate<dynamic>>[
              FluentLocalizations.delegate,
            ],
            child: picker,
          ),
        ),
      );
      expect(result?.error, FluentDatePickerErrorType.invalidInput);
      expect(
        result?.message,
        lookupFluentLocalizations(turkish).invalidDateFormat,
      );
    });

    // Upstream's ambiguity rule: a format may not round-trip, so re-parsing our
    // own output could silently move the date.
    testWidgets('text we wrote ourselves is never re-parsed', (tester) async {
      var reports = 0;
      FluentDatePickerErrorType? error;
      await _pump(
        tester,
        allowTextInput: true,
        value: DateTime(2026, 3, 17),
        onValidationResult: (result) {
          reports++;
          error = result.error;
        },
      );

      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      expect(error, isNull);
      expect(reports, lessThanOrEqualTo(1));
    });
  });

  group('FluentDatePicker — theming and motion across the overlay', () {
    // FluentTheme is an InheritedTheme and would be lost across the Overlay
    // boundary without InheritedTheme.capture.
    testWidgets('a theme override reaches the popup', (tester) async {
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: FluentThemeOverride(
            colors: const <FluentColorToken, Color>{
              FluentColorToken.neutralBackground1: Color(0xFF123456),
            },
            child: Center(
              child: SizedBox(
                width: 300,
                child: FluentDatePicker(today: _today, onSelectDate: _noop),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();

      final surfaces = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.color);
      expect(surfaces, contains(const Color(0xFF123456)));
    });

    // MediaQuery does NOT ride along with InheritedTheme.capture, so the flag
    // has to be read at the trigger and handed across explicitly.
    testWidgets('reduced motion lands the entrance on its first frame', (
      tester,
    ) async {
      await _pump(tester, reducedMotion: true);

      await tester.tap(find.byType(FluentDatePicker));
      await tester.pump();
      await tester.pump();

      final opacities = tester
          .widgetList<Opacity>(
            find.ancestor(
              of: find.byType(FluentCalendar),
              matching: find.byType(Opacity),
            ),
          )
          .map((widget) => widget.opacity);
      expect(opacities.every((value) => value == 1), isTrue);
    });
  });

  // #30: accentWidth was resolved into the style and then dropped, because the
  // shared faceplate drew its focus bar at a constant FluentStroke.thick.
  testWidgets('style.accentWidth sizes the focus bar', (tester) async {
    await _pump(
      tester,
      wrap: (_) => FluentDatePicker(
        today: _today,
        onSelectDate: _noop,
        autofocus: true,
        style: const FluentDatePickerStyle(
          accentWidth: WidgetStatePropertyAll<double?>(8),
        ),
      ),
    );
    final bar = find.descendant(
      of: find.byType(FluentDatePicker),
      matching: find.byType(FluentInputFocusUnderline),
    );
    expect(tester.widget<FluentInputFocusUnderline>(bar).thickness, 8);
    expect(tester.getSize(bar).height, 8);
  });
}
