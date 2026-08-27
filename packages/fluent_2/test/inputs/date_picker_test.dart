import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/internal/input_modality.dart';
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

TextEditingController _controller(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller;

void main() {
  setUp(FluentInputModality.debugReset);

  group('FluentDatePicker — the read-only ramp', () {
    // `allowTextInput` defaults to false, so a date picker is read-only by
    // default. resolveFluentInputStyle folds readOnly into the DISABLED ramp
    // (`inert = disabled || readOnly`), so passing it straight through would
    // paint every default picker as greyed out.
    testWidgets('a default picker is not painted as disabled', (tester) async {
      await _pump(tester);
      final live = _faceplate(tester);

      await _pump(tester, onSelectDate: null);
      final disabled = _faceplate(tester);

      expect(live.color, isNot(disabled.color));
      expect(live.border, isNot(disabled.border));
    });
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
    testWidgets('clicking opens, clicking again closes', (tester) async {
      await _pump(tester);
      expect(find.byType(FluentCalendar), findsNothing);

      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();
      expect(find.byType(FluentCalendar), findsOneWidget);
      expect(find.text('March 2026'), findsOneWidget);

      await tester.tap(find.byType(FluentDatePicker));
      await tester.pumpAndSettle();
      expect(find.byType(FluentCalendar), findsNothing);
    });

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
    // has to close exactly once rather than close-then-reopen.
    testWidgets('clicking the field while open closes it exactly once', (
      tester,
    ) async {
      final opens = <bool>[];
      await _pump(tester, onOpenChange: opens.add);

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
}
