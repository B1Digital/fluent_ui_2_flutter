import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/internal/input_modality.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart'
    show
        PointerDeviceKind,
        kMiddleMouseButton,
        kPrimaryButton,
        kSecondaryMouseButton;
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

/// A picker whose parent takes every reported time, as upstream's
/// uncontrolled pickers do, above a second focus stop for Tab to reach.
/// Returns what the picker reported.
Future<List<FluentTimeSelectionData>> _pumpLive(
  WidgetTester tester, {
  bool freeform = false,
  DateTime? selectedTime,
  int startHour = 0,
  int endHour = 24,
}) async {
  final reported = <FluentTimeSelectionData>[];
  var selected = selectedTime;
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    FluentApp(
      theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              StatefulBuilder(
                builder: (context, setState) => FluentTimePicker(
                  dateAnchor: _anchor,
                  selectedTime: selected,
                  freeform: freeform,
                  startHour: startHour,
                  endHour: endHour,
                  onTimeChange: (data) {
                    reported.add(data);
                    setState(() => selected = data.selectedTime);
                  },
                ),
              ),
              const Focus(child: SizedBox.square(dimension: 8)),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return reported;
}

/// A mouse click, pressed and released where it landed.
Future<void> _click(
  WidgetTester tester,
  Offset at, {
  int buttons = kPrimaryButton,
}) async {
  final mouse = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
    buttons: buttons,
  );
  await mouse.addPointer(location: at);
  await mouse.down(at);
  await tester.pump();
  await mouse.up();
  await tester.pumpAndSettle();
  await mouse.removePointer();
}

/// What the field holds.
String _text(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

/// Where the field's caret or selection is.
TextSelection _selection(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.selection;

/// A listbox row reading [text] — not the field, which may hold the same.
Finder _row(String text) => find.byWidgetPredicate(
  (widget) => widget is Text && widget.data == text,
  description: 'a row reading "$text"',
);

/// Whether the row reading [text] shows its focus ring.
bool _ringOn(WidgetTester tester, String text) => tester
    .widget<FluentFocusRing>(
      find
          .ancestor(of: _row(text), matching: find.byType(FluentFocusRing))
          .first,
    )
    .visible;

/// The rows whose ring shows.
List<String> _rung(WidgetTester tester) => <String>[
  for (final row
      in find
          .descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Text),
          )
          .evaluate())
    if (_ringOn(tester, (row.widget as Text).data!)) (row.widget as Text).data!,
];

/// The open listbox's scroll position.
ScrollPosition _list(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    )
    .position;

/// How far the row reading [text] sits inside the listbox's scrolling
/// viewport, from its top and its bottom edge.
({double top, double bottom}) _clearance(WidgetTester tester, String text) {
  final viewport = tester.getRect(
    find.descendant(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(Scrollable),
    ),
  );
  final row = tester.getRect(
    find.ancestor(of: _row(text), matching: find.byType(FluentInteractive)),
  );
  return (top: row.top - viewport.top, bottom: viewport.bottom - row.bottom);
}

/// The open listbox's max height.
double _cap(WidgetTester tester) => tester
    .widget<ConstrainedBox>(
      find.descendant(
        of: find.byType(CompositedTransformFollower),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is ConstrainedBox && widget.constraints.maxHeight.isFinite,
        ),
      ),
    )
    .constraints
    .maxHeight;

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

    // Upstream's `getDateFromTimeString`: with no hourCycle — the
    // freeform-with-error-handling story's — it takes `H:MM` or `HH:MM` and
    // nothing else, AM/PM included, though the options read '10:00 AM'.
    // Chrome, close_timepicker/up_parse: '10:00' and '19:59' pass, '8:00',
    // '0:30', '20:00' and '24:00' are out of range, and the rest invalid.
    test('with no hourCycle, only H:MM on the 24-hour clock', () {
      expect(parse('9:05').date, DateTime(2026, 3, 10, 9, 5));
      expect(parse('09:05').date, DateTime(2026, 3, 10, 9, 5));
      expect(parse('21:05').date, DateTime(2026, 3, 10, 21, 5));
      expect(parse('0:30').date, DateTime(2026, 3, 10, 0, 30));
      for (final text in <String>[
        '8',
        '12',
        '9:5',
        '1000',
        '11.30',
        '11:30:00',
        '10:00 AM',
        '11:30am',
        ' 11:30',
        '11:30 ',
        '9:75',
        '25:00',
        'abc',
      ]) {
        expect(
          parse(text).error,
          FluentTimePickerErrorType.invalidInput,
          reason: text,
        );
        expect(parse(text).date, isNull, reason: text);
      }
    });

    test('24:00 is the next midnight, past a whole day', () {
      final result = parse('24:00');
      expect(result.date, DateTime(2026, 3, 11));
      expect(result.error, FluentTimePickerErrorType.outOfBounds);
    });

    test('the 12-hour clocks need AM or PM after one space', () {
      for (final cycle in <FluentHourCycle>[
        FluentHourCycle.h11,
        FluentHourCycle.h12,
      ]) {
        FluentTimeStringValidationResult parse12(String text) =>
            fluentParseTime(text, dateAnchor: _anchor, hourCycle: cycle);
        expect(parse12('9:05 PM').date, DateTime(2026, 3, 10, 21, 5));
        expect(parse12('12:30 am').date, DateTime(2026, 3, 10, 0, 30));
        expect(parse12('12:30 PM').date, DateTime(2026, 3, 10, 12, 30));
        for (final text in <String>['9:05', '9:05PM', '13:00 PM', '9 pm']) {
          expect(
            parse12(text).error,
            FluentTimePickerErrorType.invalidInput,
            reason: '$cycle, $text',
          );
        }
      }
      expect(
        fluentParseTime(
          '21:05',
          dateAnchor: _anchor,
          hourCycle: FluentHourCycle.h23,
        ).date,
        DateTime(2026, 3, 10, 21, 5),
      );
    });

    test('showSeconds asks for the seconds too', () {
      expect(
        fluentParseTime('9:05:30', dateAnchor: _anchor, showSeconds: true).date,
        DateTime(2026, 3, 10, 9, 5, 30),
      );
      expect(
        fluentParseTime('9:05', dateAnchor: _anchor, showSeconds: true).error,
        FluentTimePickerErrorType.invalidInput,
      );
      expect(
        fluentParseTime(
          '9:05:30 PM',
          dateAnchor: _anchor,
          hourCycle: FluentHourCycle.h12,
          showSeconds: true,
        ).date,
        DateTime(2026, 3, 10, 21, 5, 30),
      );
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
        hourCycle: FluentHourCycle.h12,
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
      // tall after the page carried the field up, where more room shows.
      // `@fluentui/react-positioning` repositions on scroll rather than
      // closing, so the entry re-measures.
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
      // Puts the field 250 down a 600 viewport; the listbox takes the room
      // below it, less the 2px offset, as Combobox's `autoSize` does.
      controller.jumpTo(650);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FluentTimePicker));
      await tester.pumpAndSettle();

      double room() =>
          600 - tester.getRect(find.byType(FluentTimePicker)).bottom;
      expect(_cap(tester), room() - 2);
      final before = _cap(tester);

      // A wheel, not a drag: `TapRegion` cannot tell a drag from a tap, so a
      // touch drag dismisses (see the light-dismiss group), and `jumpTo` never
      // flips `isScrollingNotifier`, which the rebuild is gated on.
      final wheel = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(wheel.hover(const Offset(400, 100)));
      await tester.sendEventToBinding(wheel.scroll(const Offset(0, 200)));
      await tester.pumpAndSettle();

      expect(find.text('09:00'), findsOneWidget, reason: 'still open');
      expect(controller.offset, 850, reason: 'the wheel has to have landed');
      // 200 further down the page leaves 200 more below the field.
      expect(_cap(tester), room() - 2);
      expect(_cap(tester), before + 200);
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

    testWidgets('the picker parses on its own hourCycle', (tester) async {
      // Upstream hands `getDateFromTimeString` the picker's own cycle: an h12
      // picker wants '9:30 AM', and '09:30' is not a time to it.
      for (final (text, time) in <(String, DateTime?)>[
        ('9:30 AM', DateTime(2026, 3, 10, 9, 30)),
        ('09:30', null),
      ]) {
        final reported = <FluentTimeSelectionData>[];
        await tester.pumpWidget(
          FluentApp(
            home: Center(
              child: SizedBox(
                width: 280,
                child: FluentTimePicker(
                  key: ValueKey<String>(text),
                  dateAnchor: _anchor,
                  freeform: true,
                  hourCycle: FluentHourCycle.h12,
                  onTimeChange: reported.add,
                ),
              ),
            ),
          ),
        );
        await tester.enterText(find.byType(EditableText), text);
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(reported.single.selectedTime, time, reason: text);
      }
    });

    // Upstream's non-freeform picker is still an editable `<input>`: it takes
    // a caret and types ahead (compat-components-timepicker--default in
    // Chrome). This used to assert the opposite.
    testWidgets('a non-freeform field takes a caret and typed text', (
      tester,
    ) async {
      await _pump(tester);
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.readOnly, isFalse);
      expect(editable.showCursor, isTrue);
    });
  });

  // Measured on compat-components-timepicker--freeform-with-error-handling
  // (10:00 to 19:30, h12) and --default (the whole day) in Chrome; evidence in
  // the session scratchpad's final_timepicker/up.
  group('FluentTimePicker — typing, as upstream does in Chrome', () {
    testWidgets('freeform: the typed prefix rings its option; Enter picks it', (
      tester,
    ) async {
      final reported = await _pumpLive(
        tester,
        freeform: true,
        startHour: 10,
        endHour: 20,
      );
      await _click(tester, tester.getCenter(find.byType(EditableText)));
      expect(_rung(tester), isEmpty, reason: 'opened by the mouse');

      tester.testTextInput.enterText('12:30');
      await tester.pumpAndSettle();
      expect(_rung(tester), <String>['12:30 PM']);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(reported.single.selectedTime, DateTime(2026, 3, 10, 12, 30));
      expect(reported.single.selectedTimeText, '12:30 PM');
      expect(_text(tester), '12:30 PM');
      // Chrome leaves the caret after the picked text, so the next key adds
      // to it rather than replacing it.
      expect(_selection(tester), const TextSelection.collapsed(offset: 8));
      expect(_row('1:00 PM'), findsNothing, reason: 'closed');
    }, variant: TargetPlatformVariant.desktop());

    testWidgets(
      'freeform: text no option starts rings none; Enter commits it',
      (tester) async {
        final reported = await _pumpLive(
          tester,
          freeform: true,
          startHour: 10,
          endHour: 20,
        );
        await _click(tester, tester.getCenter(find.byType(EditableText)));
        tester.testTextInput.enterText('12:15');
        await tester.pumpAndSettle();
        expect(_rung(tester), isEmpty);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(reported.single.selectedTime, DateTime(2026, 3, 10, 12, 15));
        expect(reported.single.selectedTimeText, '12:15');
        expect(_text(tester), '12:15');
        expect(_row('1:00 PM'), findsNothing, reason: 'closed');
      },
    );

    testWidgets('freeform: Tab and a click away keep the typed text', (
      tester,
    ) async {
      // Chrome: '12:30' stays '12:30' — not the option's '12:30 PM' — and
      // 'abc' stays 'abc' even over a time picked before.
      for (final (typed, leave, picked, time, error)
          in <
            (String, String, DateTime?, DateTime?, FluentTimePickerErrorType?)
          >[
            ('12:30', 'Tab', null, DateTime(2026, 3, 10, 12, 30), null),
            ('12:30', 'click', null, DateTime(2026, 3, 10, 12, 30), null),
            ('abc', 'Tab', null, null, FluentTimePickerErrorType.invalidInput),
            // A bare hour is not a time to upstream's default parser (Chrome,
            // close_timepicker/up_parse).
            ('8', 'Tab', null, null, FluentTimePickerErrorType.invalidInput),
            (
              'abc',
              'Tab',
              DateTime(2026, 3, 10, 12, 30),
              null,
              FluentTimePickerErrorType.invalidInput,
            ),
          ]) {
        final reason = '$typed, $leave, picked $picked';
        final reported = await _pumpLive(
          tester,
          freeform: true,
          startHour: 10,
          endHour: 20,
          selectedTime: picked,
        );
        await _click(tester, tester.getCenter(find.byType(EditableText)));
        tester.testTextInput.enterText(typed);
        await tester.pumpAndSettle();
        if (leave == 'Tab') {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
        } else {
          await _click(tester, const Offset(790, 590));
        }
        expect(reported.single.selectedTime, time, reason: reason);
        expect(reported.single.selectedTimeText, typed, reason: reason);
        expect(reported.single.error, error, reason: reason);
        expect(_text(tester), typed, reason: reason);
      }
    });

    testWidgets('freeform: Escape closes and keeps the typed text', (
      tester,
    ) async {
      final reported = await _pumpLive(
        tester,
        freeform: true,
        startHour: 10,
        endHour: 20,
      );
      await _click(tester, tester.getCenter(find.byType(EditableText)));
      tester.testTextInput.enterText('12:30');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_row('1:00 PM'), findsNothing, reason: 'closed');
      expect(_text(tester), '12:30');
      expect(reported, isEmpty);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(reported.single.selectedTime, DateTime(2026, 3, 10, 12, 30));
      expect(_text(tester), '12:30');
    });

    testWidgets('non-freeform: a click opens with a caret; Enter picks the '
        'typed match', (tester) async {
      final reported = await _pumpLive(tester);
      await _click(tester, tester.getCenter(find.byType(EditableText)));
      final editable = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      expect(editable.widget.focusNode.hasFocus, isTrue);
      expect(editable.widget.readOnly, isFalse);
      expect(editable.widget.showCursor, isTrue);
      expect(_rung(tester), isEmpty, reason: 'opened by the mouse');

      tester.testTextInput.enterText('1');
      await tester.pumpAndSettle();
      expect(_rung(tester), <String>['12:00 AM']);
      tester.testTextInput.enterText('12:3');
      await tester.pumpAndSettle();
      expect(_rung(tester), <String>['12:30 AM']);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(reported.single.selectedTime, DateTime(2026, 3, 10, 0, 30));
      expect(_text(tester), '12:30 AM');
      expect(_selection(tester), const TextSelection.collapsed(offset: 8));
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('a pick keeps its text while the parent takes it, so keys '
        'pressed at once still land', (tester) async {
      // Chrome (verify_timepicker/up_rapid.out): '11:00', Enter and six
      // ArrowLefts with no pause leave the caret at 2, freeform or not. A
      // non-freeform port blanked the text until the parent rebuilt with the
      // pick, then wrote it back with the caret at the end (port.out: 8).
      for (final freeform in <bool>[false, true]) {
        await _pumpLive(tester, freeform: freeform);
        await _click(tester, tester.getCenter(find.byType(EditableText)));
        tester.testTextInput.enterText('11:00');
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(_text(tester), '11:00 AM', reason: 'freeform $freeform');
        for (var i = 0; i < 6; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        }
        await tester.pumpAndSettle();
        expect(_text(tester), '11:00 AM', reason: 'freeform $freeform');
        expect(
          _selection(tester),
          const TextSelection.collapsed(offset: 2),
          reason: 'freeform $freeform',
        );
      }
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('non-freeform: text nothing picked reverts on Tab, a click '
        'away and Escape', (tester) async {
      for (final (typed, leave) in <(String, String)>[
        ('12:3', 'Tab'),
        ('12:3', 'click'),
        ('x', 'Tab'),
        ('3', 'Escape'),
      ]) {
        final reason = '$typed, $leave';
        final reported = await _pumpLive(tester);
        await _click(tester, tester.getCenter(find.byType(EditableText)));
        tester.testTextInput.enterText(typed);
        await tester.pumpAndSettle();
        switch (leave) {
          case 'Tab':
            await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          case 'Escape':
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          default:
            await _click(tester, const Offset(790, 590));
        }
        await tester.pumpAndSettle();
        expect(reported, isEmpty, reason: reason);
        expect(_text(tester), isEmpty, reason: reason);
        expect(_row('1:00 AM'), findsNothing, reason: '$reason, closed');
      }
    });

    testWidgets('non-freeform: text no option starts rings the first; Enter '
        'picks it', (tester) async {
      final reported = await _pumpLive(tester);
      await _click(tester, tester.getCenter(find.byType(EditableText)));
      tester.testTextInput.enterText('x');
      await tester.pumpAndSettle();
      expect(_rung(tester), <String>['12:00 AM']);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(reported.single.selectedTime, DateTime(2026, 3, 10));
      expect(_text(tester), '12:00 AM');
      expect(_selection(tester), const TextSelection.collapsed(offset: 8));
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('non-freeform: typing into a closed field opens it', (
      tester,
    ) async {
      await _pumpLive(tester);
      final field = tester.getCenter(find.byType(EditableText));
      await _click(tester, field);
      await _click(tester, field);
      expect(_row('1:00 AM'), findsNothing, reason: 'closed again');

      tester.testTextInput.enterText('3');
      await tester.pumpAndSettle();
      expect(_rung(tester), <String>['3:00 AM']);
    });

    // Chrome scrolls the active row just into view, 2px clear of the edge it
    // was past, however it became active: typing '8' with 8:00 AM seventeen
    // rows down scrolls it to the bottom edge, whether the key opened the list
    // or not, and emptying the text scrolls back up to the first, 2px down
    // (scrollTop 2, close_timepicker/up_scroll_empty). This test used to
    // assert no scroll at all, measured where 8:00 AM already showed.
    testWidgets('a typed match below the fold scrolls just into view', (
      tester,
    ) async {
      for (final shut in <bool>[false, true]) {
        final reason = shut ? 'typed into the shut list' : 'typed when open';
        await _pumpLive(tester);
        final field = tester.getCenter(find.byType(EditableText));
        await _click(tester, field);
        if (shut) {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
        }
        tester.testTextInput.enterText('8');
        await tester.pumpAndSettle();
        expect(_rung(tester), <String>['8:00 AM'], reason: reason);
        expect(_list(tester).pixels, greaterThan(0), reason: reason);
        expect(
          _clearance(tester, '8:00 AM').bottom,
          closeTo(2, 0.01),
          reason: reason,
        );

        tester.testTextInput.enterText('');
        await tester.pumpAndSettle();
        expect(
          _list(tester).pixels,
          closeTo(2, 0.01),
          reason: '$reason, emptied',
        );
      }
    });

    testWidgets('opening scrolls the selected row into view', (tester) async {
      // Chrome: 11:00 PM picked, a click reopens the list scrolled to it.
      await _pumpLive(tester, selectedTime: DateTime(2026, 3, 10, 23));
      await _click(tester, tester.getCenter(find.byType(EditableText)));
      expect(_clearance(tester, '11:00 PM').bottom, closeTo(2, 0.01));
    });

    testWidgets('the arrows scroll the active row just into view', (
      tester,
    ) async {
      // Chrome: twenty Downs leave 10:00 AM 2px off the bottom edge; five Ups
      // stay in view and do not scroll.
      await _pumpLive(tester);
      await _click(tester, tester.getCenter(find.byType(EditableText)));
      for (var i = 0; i < 20; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      }
      await tester.pumpAndSettle();
      expect(_rung(tester), <String>['10:00 AM']);
      expect(_clearance(tester, '10:00 AM').bottom, closeTo(2, 0.01));
      final scrolled = _list(tester).pixels;
      for (var i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      }
      await tester.pumpAndSettle();
      expect(_rung(tester), <String>['7:30 AM']);
      expect(_list(tester).pixels, scrolled);
    });

    testWidgets('Down or Up on a shut list opens on the selection, or the '
        'first row', (tester) async {
      // Chrome: neither key moves on the key that opens; Up does not jump to
      // the last row.
      for (final key in <LogicalKeyboardKey>[
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowUp,
      ]) {
        for (final (picked, row) in <(DateTime?, String)>[
          (null, '12:00 AM'),
          (DateTime(2026, 3, 10, 3), '3:00 AM'),
        ]) {
          final reason = '${key.keyLabel}, picked $picked';
          await _pumpLive(tester, selectedTime: picked);
          await _click(tester, tester.getCenter(find.byType(EditableText)));
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();
          expect(_rung(tester), <String>[row], reason: reason);
        }
      }
    });

    testWidgets('the listbox grows to the room below the field', (
      tester,
    ) async {
      // Chrome: Combobox's `autoSize` writes the room below as an inline
      // max-height, over the `min(80vh, 416px)` class — 636px under a field
      // 124px down a 760px page.
      await _pumpLive(tester);
      await _click(tester, tester.getCenter(find.byType(EditableText)));
      final room = 600 - tester.getRect(find.byType(FluentTimePicker)).bottom;
      expect(room - 2, greaterThan(416), reason: 'else this proves nothing');
      expect(_cap(tester), room - 2);
    });

    testWidgets('non-freeform: text no option starts clears the selection', (
      tester,
    ) async {
      final reported = await _pumpLive(
        tester,
        selectedTime: DateTime(2026, 3, 10, 1),
      );
      await _click(tester, tester.getCenter(find.byType(EditableText)));
      tester.testTextInput.enterText('1:00 AMx');
      await tester.pumpAndSettle();
      expect(reported.single.selectedTime, isNull);
      expect(_rung(tester), <String>['12:00 AM']);

      await _click(tester, const Offset(790, 590));
      expect(_text(tester), isEmpty);
    });

    // Evidence for the rest of this group: the session scratchpad's tp_verify.
    testWidgets('a character typed over a selection opens the shut list', (
      tester,
    ) async {
      // Chrome: a picked time, the list shut, Cmd+A then '3' opens it on the
      // 3:00 row, rung, and Enter picks that row — freeform or not.
      for (final (freeform, picked, row, time)
          in <(bool, DateTime, String, DateTime)>[
            (
              true,
              DateTime(2026, 3, 10, 12, 30),
              '3:00 PM',
              DateTime(2026, 3, 10, 15),
            ),
            (
              false,
              DateTime(2026, 3, 10, 1),
              '3:00 AM',
              DateTime(2026, 3, 10, 3),
            ),
          ]) {
        final reason = 'freeform $freeform';
        final reported = await _pumpLive(
          tester,
          freeform: freeform,
          selectedTime: picked,
          startHour: freeform ? 10 : 0,
          endHour: freeform ? 20 : 24,
        );
        await _click(tester, tester.getCenter(find.byType(EditableText)));
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(_row(row), findsNothing, reason: '$reason, shut');

        final value = tester
            .state<EditableTextState>(find.byType(EditableText))
            .textEditingValue;
        tester.testTextInput.updateEditingValue(
          value.copyWith(
            selection: TextSelection(
              baseOffset: 0,
              extentOffset: value.text.length,
            ),
          ),
        );
        await tester.pump();
        tester.testTextInput.enterText('3');
        await tester.pumpAndSettle();
        expect(_rung(tester), <String>[row], reason: reason);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(reported.last.selectedTime, time, reason: reason);
        expect(_text(tester), row, reason: reason);
      }
    });

    testWidgets('freeform: text deleted to nothing rings the first; Enter '
        'picks it', (tester) async {
      // Chrome: '1' then Backspace leaves 10:00 AM active and rung.
      final reported = await _pumpLive(
        tester,
        freeform: true,
        startHour: 10,
        endHour: 20,
      );
      await _click(tester, tester.getCenter(find.byType(EditableText)));
      tester.testTextInput.enterText('1');
      await tester.pumpAndSettle();
      expect(_rung(tester), <String>['10:00 AM']);
      tester.testTextInput.enterText('');
      await tester.pumpAndSettle();
      expect(_rung(tester), <String>['10:00 AM']);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(reported.single.selectedTime, DateTime(2026, 3, 10, 10));
      expect(_text(tester), '10:00 AM');
    });

    testWidgets('freeform: Enter on the shut list commits the text and opens '
        'it', (tester) async {
      // Chrome: 'abc', Escape, then Enter reports the invalid text and opens
      // on 10:00 AM, rung.
      final reported = await _pumpLive(
        tester,
        freeform: true,
        startHour: 10,
        endHour: 20,
      );
      await _click(tester, tester.getCenter(find.byType(EditableText)));
      tester.testTextInput.enterText('abc');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(_row('10:00 AM'), findsNothing, reason: 'shut');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(reported.single.error, FluentTimePickerErrorType.invalidInput);
      expect(_text(tester), 'abc');
      expect(_rung(tester), <String>['10:00 AM']);
    });

    testWidgets('freeform: Enter on the shut list opens on the time it just '
        'committed', (tester) async {
      // Chrome (verify_timepicker/up_m1.out, up_m1b.out): '10:30', Escape,
      // Enter reports 10:30 and opens on 10:30 AM, rung — over an earlier
      // 11:00 AM too — and '18:30' on 6:30 PM. 'abc' over 11:00 AM drops the
      // selection and opens on the first, as '10:15', which no row reads,
      // does. The commit and the open are one event upstream.
      for (final (typed, over, rung) in <(String, DateTime?, String)>[
        ('10:30', null, '10:30 AM'),
        ('10:30', DateTime(2026, 3, 10, 11), '10:30 AM'),
        ('18:30', null, '6:30 PM'),
        ('abc', DateTime(2026, 3, 10, 11), '10:00 AM'),
        ('10:15', null, '10:00 AM'),
      ]) {
        final reason = "'$typed' over $over";
        await _pumpLive(
          tester,
          freeform: true,
          selectedTime: over,
          startHour: 10,
          endHour: 20,
        );
        await _click(tester, tester.getCenter(find.byType(EditableText)));
        tester.testTextInput.enterText(typed);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(_rung(tester), <String>[rung], reason: reason);
        expect(_text(tester), typed, reason: reason);
      }
    });

    testWidgets('freeform: a match the shut list kept is where it reopens; '
        'Enter commits nothing', (tester) async {
      // Chrome (close_timepicker/up_enter, up_reopen): '12:30 PM', Escape,
      // Backspace leaves '12:30 P' with 12:30 PM active and the list shut.
      // Enter, Down, a click on the text or on the chevron each open it on
      // 12:30 PM and commit nothing; a further Enter picks 12:30 PM.
      for (final reopen in <String>['Enter', 'Down', 'text', 'chevron']) {
        final reported = await _pumpLive(
          tester,
          freeform: true,
          startHour: 10,
          endHour: 20,
        );
        await _click(tester, tester.getCenter(find.byType(EditableText)));
        tester.testTextInput.enterText('12:30 PM');
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        tester.testTextInput.enterText('12:30 P');
        await tester.pumpAndSettle();
        expect(_row('1:00 PM'), findsNothing, reason: '$reopen, still shut');

        switch (reopen) {
          case 'Enter':
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          case 'Down':
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          case 'text':
            await _click(tester, tester.getCenter(find.byType(EditableText)));
          default:
            await _click(
              tester,
              tester.getCenter(find.byIcon(fluentTimePickerChevron)),
            );
        }
        await tester.pumpAndSettle();
        expect(_row('1:00 PM'), findsOneWidget, reason: '$reopen, open');
        expect(reported, isEmpty, reason: reopen);
        expect(_text(tester), '12:30 P', reason: reopen);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(
          reported.single.selectedTime,
          DateTime(2026, 3, 10, 12, 30),
          reason: reopen,
        );
        expect(_text(tester), '12:30 PM', reason: reopen);
      }
    });

    testWidgets('freeform: text emptied on the shut list leaves no row '
        'active; Enter commits it and opens', (tester) async {
      // Chrome (close_timepicker/up_emptied): '1', Escape, Backspace, Enter
      // reports the empty text — the story's "Time is required." — and opens
      // on 10:00 AM, rung. The first-row fallback is the open list's only.
      final reported = await _pumpLive(
        tester,
        freeform: true,
        startHour: 10,
        endHour: 20,
      );
      await _click(tester, tester.getCenter(find.byType(EditableText)));
      tester.testTextInput.enterText('1');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      tester.testTextInput.enterText('');
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(reported.single.selectedTimeText, '');
      expect(_rung(tester), <String>['10:00 AM']);
    });

    testWidgets('the first row keeps its ring in view at the top', (
      tester,
    ) async {
      // Chrome (close_timepicker/up_scroll): the listbox's 4px padding scrolls
      // with its rows, so the first row opens 4px down; twenty Downs then
      // Home, or twenty Ups, leave it 2px down (scrollTop 2), its 2px ring in
      // full. The ring was clipped when the padding sat outside the scroller.
      for (final back in <String>['Home', 'Up']) {
        await _pumpLive(tester);
        await _click(tester, tester.getCenter(find.byType(EditableText)));
        expect(_clearance(tester, '12:00 AM').top, 4, reason: back);

        for (var i = 0; i < 20; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        }
        await tester.pumpAndSettle();
        expect(_list(tester).pixels, greaterThan(2), reason: back);
        if (back == 'Home') {
          await tester.sendKeyEvent(LogicalKeyboardKey.home);
        } else {
          for (var i = 0; i < 20; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          }
        }
        await tester.pumpAndSettle();
        expect(_rung(tester), <String>['12:00 AM'], reason: back);
        expect(_list(tester).pixels, closeTo(2, 0.01), reason: back);
        expect(_clearance(tester, '12:00 AM').top, closeTo(2, 0.01));
      }
    });

    testWidgets('freeform: Home and End jump the open list, not the caret', (
      tester,
    ) async {
      // Chrome: '12' typed, Home rings 10:00 AM and End 7:30 PM, and the
      // caret stays at (2,2).
      await _pumpLive(tester, freeform: true, startHour: 10, endHour: 20);
      await _click(tester, tester.getCenter(find.byType(EditableText)));
      tester.testTextInput.enterText('12');
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(_rung(tester), <String>['10:00 AM']);
      expect(_selection(tester), const TextSelection.collapsed(offset: 2));
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(_rung(tester), <String>['7:30 PM']);
      expect(_selection(tester), const TextSelection.collapsed(offset: 2));
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('non-freeform: text cut down to an option with the list shut '
        'is picked on blur', (tester) async {
      // Chrome: 11:00 AM picked, the list shut, Home then Delete leaves
      // '1:00 AM', which a click away picks.
      final reported = await _pumpLive(
        tester,
        selectedTime: DateTime(2026, 3, 10, 11),
      );
      await _click(tester, tester.getCenter(find.byType(EditableText)));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: '1:00 AM',
          selection: TextSelection.collapsed(offset: 0),
        ),
      );
      await tester.pumpAndSettle();
      expect(_row('3:00 AM'), findsNothing, reason: 'a deletion keeps it shut');

      await _click(tester, const Offset(790, 590));
      expect(reported.single.selectedTime, DateTime(2026, 3, 10, 1));
      expect(_text(tester), '1:00 AM');
    });

    testWidgets('a later press takes the typed ring away', (tester) async {
      // Chrome: '12' rings 12:00 PM; a middle press on the field leaves the
      // list open and the row active, unrung.
      await _pumpLive(tester, freeform: true, startHour: 10, endHour: 20);
      final field = tester.getCenter(find.byType(EditableText));
      await _click(tester, field);
      tester.testTextInput.enterText('12');
      await tester.pumpAndSettle();
      expect(_rung(tester), <String>['12:00 PM']);

      await _click(tester, field, buttons: kMiddleMouseButton);
      expect(_row('12:00 PM'), findsOneWidget, reason: 'still open');
      expect(_rung(tester), isEmpty);
    });

    testWidgets(
      'a middle press puts the caret where it lands, focused or not',
      (tester) async {
        // Chrome, '1:00 AM' / '12:30' with the press 18px into the text: (3,3)
        // on a blurred field and on a focused one whose caret was at the end.
        for (final freeform in <bool>[false, true]) {
          await _pumpLive(
            tester,
            freeform: freeform,
            selectedTime: DateTime(2026, 3, 10, 1),
          );
          final editable = tester.state<EditableTextState>(
            find.byType(EditableText),
          );
          final box = tester.getRect(find.byType(EditableText));
          for (final dx in <double>[18, 34]) {
            final at = Offset(box.left + dx, box.center.dy);
            final landed = editable.renderEditable.getPositionForPoint(at);
            final reason = 'freeform $freeform, ${dx}px';
            expect(landed.offset, inInclusiveRange(1, 6), reason: reason);
            final mouse = await tester.createGesture(
              kind: PointerDeviceKind.mouse,
              buttons: kMiddleMouseButton,
            );
            await mouse.addPointer(location: at);
            await mouse.down(at);
            await tester.pump();
            expect(editable.widget.focusNode.hasFocus, isTrue, reason: reason);
            expect(
              editable.textEditingValue.selection,
              TextSelection.fromPosition(landed),
              reason: '$reason, held',
            );
            await mouse.up();
            await tester.pumpAndSettle();
            await mouse.removePointer();
            expect(
              editable.textEditingValue.selection,
              TextSelection.fromPosition(landed),
              reason: '$reason, released',
            );
            expect(_text(tester), '1:00 AM', reason: reason);
          }
        }
      },
    );
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

    testWidgets('a mouse press focuses without selecting the value', (
      tester,
    ) async {
      // Chrome focuses the `<input>` on mousedown and leaves its text alone;
      // an external `requestFocus` would trip `selectAllOnFocus` on Windows,
      // Linux and the web, selecting the whole time on a right or middle press.
      for (final buttons in <int>[
        kPrimaryButton,
        kSecondaryMouseButton,
        kMiddleMouseButton,
      ]) {
        await tester.pumpWidget(const SizedBox());
        await _pump(
          tester,
          freeform: true,
          selectedTime: DateTime(2026, 3, 10, 9, 30),
        );
        final editable = tester.state<EditableTextState>(
          find.byType(EditableText),
        );
        final text = tester.getRect(find.byType(EditableText));
        final at = Offset(text.left + 10, text.center.dy);
        final mouse = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          buttons: buttons,
        );
        await mouse.addPointer(location: at);
        await mouse.down(at);
        await tester.pump();
        expect(editable.widget.focusNode.hasFocus, isTrue);
        expect(editable.textEditingValue.text, '09:30');
        expect(
          editable.textEditingValue.selection.isCollapsed,
          isTrue,
          reason: 'buttons $buttons, held',
        );
        await mouse.up();
        await tester.pumpAndSettle();
        // A right click on macOS selects the word under it, natively and in
        // Chrome alike.
        if (buttons != kSecondaryMouseButton ||
            defaultTargetPlatform != TargetPlatform.macOS) {
          expect(
            editable.textEditingValue.selection.isCollapsed,
            isTrue,
            reason: 'buttons $buttons, released',
          );
        }
        await mouse.removePointer();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      }
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('a press on the chevron leaves the caret where it was', (
      tester,
    ) async {
      // Chrome (close_timepicker/up_chevron): '11:00 AM' focused with the
      // caret at 2 keeps it at 2 through a chevron press, held and released,
      // and the click opens the list — freeform or not. Upstream's expandIcon
      // prevents its mousedown's default and focuses the input itself.
      for (final freeform in <bool>[false, true]) {
        final reason = 'freeform $freeform';
        await _pumpLive(
          tester,
          freeform: freeform,
          selectedTime: DateTime(2026, 3, 10, 11),
        );
        final editable = tester.state<EditableTextState>(
          find.byType(EditableText),
        );
        await _click(tester, tester.getCenter(find.byType(EditableText)));
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        tester.testTextInput.updateEditingValue(
          editable.textEditingValue.copyWith(
            selection: const TextSelection.collapsed(offset: 2),
          ),
        );
        await tester.pump();

        final chevron = tester.getCenter(find.byIcon(fluentTimePickerChevron));
        final mouse = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          buttons: kPrimaryButton,
        );
        await mouse.addPointer(location: chevron);
        await mouse.down(chevron);
        await tester.pump();
        expect(
          editable.textEditingValue.selection,
          const TextSelection.collapsed(offset: 2),
          reason: '$reason, held',
        );
        await mouse.up();
        await tester.pumpAndSettle();
        expect(editable.widget.focusNode.hasFocus, isTrue, reason: reason);
        expect(
          editable.textEditingValue.selection,
          const TextSelection.collapsed(offset: 2),
          reason: '$reason, released',
        );
        expect(_row('1:00 AM'), findsOneWidget, reason: '$reason, open');

        // Nor does a drag from it select: the prevented mousedown starts none.
        await mouse.down(chevron);
        await tester.pump();
        await mouse.moveBy(const Offset(-60, 0));
        await tester.pump();
        await mouse.up();
        await tester.pumpAndSettle();
        await mouse.removePointer();
        expect(
          editable.textEditingValue.selection,
          const TextSelection.collapsed(offset: 2),
          reason: '$reason, dragged',
        );
      }
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('every click of a double or triple click toggles the list; '
        'on the chevron none moves the caret', (tester) async {
      // Chrome (verify_timepicker/up_m2.out, up_m1b.out): '11:00 AM' with the
      // caret at 2 keeps it there through a double click on the chevron,
      // which opens and shuts the list, and a triple, which leaves it open —
      // freeform or not. A double click on a freeform field's text selects a
      // word and leaves the list shut.
      Future<void> clicks(Offset at, int count) async {
        final mouse = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          buttons: kPrimaryButton,
        );
        await mouse.addPointer(location: at);
        for (var i = 0; i < count; i++) {
          await mouse.down(at);
          await tester.pump(const Duration(milliseconds: 30));
          await mouse.up();
          await tester.pump(const Duration(milliseconds: 30));
        }
        await tester.pumpAndSettle();
        await mouse.removePointer();
      }

      for (final freeform in <bool>[false, true]) {
        for (final count in <int>[2, 3]) {
          final reason = 'freeform $freeform, $count clicks';
          await _pumpLive(
            tester,
            freeform: freeform,
            selectedTime: DateTime(2026, 3, 10, 11),
          );
          final editable = tester.state<EditableTextState>(
            find.byType(EditableText),
          );
          await _click(tester, tester.getCenter(find.byType(EditableText)));
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          tester.testTextInput.updateEditingValue(
            editable.textEditingValue.copyWith(
              selection: const TextSelection.collapsed(offset: 2),
            ),
          );
          await tester.pump();

          await clicks(
            tester.getCenter(find.byIcon(fluentTimePickerChevron)),
            count,
          );
          expect(
            editable.textEditingValue.selection,
            const TextSelection.collapsed(offset: 2),
            reason: reason,
          );
          expect(
            _row('1:00 AM'),
            count == 2 ? findsNothing : findsOneWidget,
            reason: reason,
          );
        }
      }

      await _pumpLive(
        tester,
        freeform: true,
        selectedTime: DateTime(2026, 3, 10, 11),
      );
      final text = tester.getRect(find.byType(EditableText));
      await clicks(text.centerLeft + const Offset(10, 0), 2);
      expect(
        tester
            .state<EditableTextState>(find.byType(EditableText))
            .textEditingValue
            .selection
            .isCollapsed,
        isFalse,
        reason: 'the text, a word selected',
      );
      expect(_row('1:00 AM'), findsNothing, reason: 'the text, shut');
    }, variant: TargetPlatformVariant.desktop());

    testWidgets('a press released after the picker is gone is harmless', (
      tester,
    ) async {
      await _pump(tester);
      final at = tester.getCenter(find.byType(FluentTimePicker));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: at);
      addTearDown(mouse.removePointer);
      await mouse.down(at);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await mouse.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('re-enabled under a resting mouse, it hovers at once', (
      tester,
    ) async {
      // Chrome keeps a disabled root's `:hover`, so no new mouseenter is
      // needed once the picker is enabled again.
      await _pump(tester, onTimeChange: null);
      await hover(tester);
      await _pump(tester);
      expect(_border(tester).borderColor, colors.neutralStroke1Hover);
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
