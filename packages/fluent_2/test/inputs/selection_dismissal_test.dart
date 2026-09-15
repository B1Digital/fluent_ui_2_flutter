import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Clicking away from a Fluent text control dismisses its selection.
///
/// Flutter gives this to nobody for free. `focusNode.unfocus()` is the whole of
/// the framework's tap-outside default (`_EditableTextTapOutsideAction`), and
/// blur touches neither `controller.selection` nor the highlight painter — so a
/// control that keeps handing `EditableText` a `selectionColor` keeps the
/// selection lit after the pointer has gone somewhere else. `TextField` gates
/// that colour on focus (`material/text_field.dart:1714`) and every control
/// here has to do the same.
///
/// These assertions read the resolved `selectionColor` straight off the
/// `RenderEditable` rather than diffing pixels. That is deliberate: it is a
/// paint *input*, with no gesture arena anywhere in the causal chain, so a
/// synthetic tap cannot flatter it the way it can flatter a hit-test bug.
///
/// The one gesture-sensitive half — focus actually dropping — is asserted
/// alongside it, and is the half to distrust if this suite ever goes green
/// while the running app misbehaves.
void main() {
  const outside = Key('outside');

  FluentThemeData light() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  /// Pumps [field] above a large, opaque, unmistakably-not-the-field target.
  ///
  /// `FluentApp` matters: it installs the `TapRegionSurface` that
  /// `onTapOutside` is delivered through. A bare `pumpWidget(field)` has no
  /// surface, so the callback never fires and the test would pass for the
  /// wrong reason.
  Future<void> pump(WidgetTester tester, Widget field) => tester.pumpWidget(
    FluentApp(
      theme: light(),
      home: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(width: 280, child: field),
          ),
          const Expanded(
            child: ColoredBox(
              color: Color(0xFFEEEEEE),
              child: SizedBox.expand(key: outside),
            ),
          ),
        ],
      ),
    ),
  );

  RenderEditable editable(WidgetTester tester) =>
      tester.state<EditableTextState>(find.byType(EditableText)).renderEditable;

  /// The controller the field actually handed to its `EditableText`, whether
  /// the test injected it or the widget made its own.
  TextEditingController controllerOf(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText)).controller;

  /// Focuses [field] by tapping it, selects every character, and asserts the
  /// selection really is lit before the outside tap is delivered.
  ///
  /// Without this pre-assertion a regression that stopped the highlight from
  /// ever appearing would sail through the post-assertion.
  Future<void> selectAll(WidgetTester tester, String label) async {
    await tester.tap(find.byType(EditableText), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();

    final controller = controllerOf(tester);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
    await tester.pumpAndSettle();

    expect(
      editable(tester).selection?.isCollapsed,
      isFalse,
      reason: '$label: nothing was selected, so the test proves nothing',
    );
    expect(
      editable(tester).selectionColor,
      isNotNull,
      reason: '$label: a focused field must paint its selection',
    );
  }

  /// Clicks the outside target with a **mouse**.
  ///
  /// The pointer kind is load-bearing, not incidental. `flutter_test` reports
  /// `TargetPlatform.android` and `kIsWeb == false`, and on that combination
  /// `_EditableTextTapOutsideAction` deliberately does NOT unfocus for a
  /// `touch` pointer — so the default `tapAt` would leave the field focused and
  /// this suite would "reproduce" a bug that no mouse user ever sees. A mouse
  /// pointer takes the same branch on every platform value, which is the one
  /// the report describes.
  Future<void> tapOutside(WidgetTester tester) async {
    await tester.tapAt(
      tester.getCenter(find.byKey(outside)),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
  }

  void expectDismissed(WidgetTester tester, String label, String text) {
    expect(
      editable(tester).selectionColor,
      isNull,
      reason:
          '$label: selectionColor survived the blur, so the highlight is '
          'still painted — this is the bug',
    );
    expect(
      controllerOf(tester).selection.isCollapsed,
      isTrue,
      reason: '$label: the range outlived focus',
    );
    // Pinned because every other assertion here would also pass if dismissal
    // were implemented by deleting the user's text.
    expect(
      controllerOf(tester).text,
      text,
      reason: '$label: dismissing a selection must not touch the value',
    );
  }

  group('clicking outside dismisses the selection', () {
    testWidgets('FluentInput', (tester) async {
      final controller = TextEditingController(text: 'hello world');
      final node = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(node.dispose);

      await pump(tester, FluentInput(controller: controller, focusNode: node));
      await selectAll(tester, 'FluentInput');

      await tapOutside(tester);

      expect(node.hasFocus, isFalse, reason: 'FluentInput kept focus');
      expectDismissed(tester, 'FluentInput', 'hello world');
    });

    testWidgets('FluentTextarea', (tester) async {
      final controller = TextEditingController(text: 'hello world');
      final node = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(node.dispose);

      await pump(
        tester,
        FluentTextarea(controller: controller, focusNode: node),
      );
      await selectAll(tester, 'FluentTextarea');

      await tapOutside(tester);

      expect(node.hasFocus, isFalse, reason: 'FluentTextarea kept focus');
      expectDismissed(tester, 'FluentTextarea', 'hello world');
    });

    testWidgets('FluentSearchBox', (tester) async {
      final controller = TextEditingController(text: 'hello world');
      final node = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(node.dispose);

      await pump(
        tester,
        FluentSearchBox(controller: controller, focusNode: node),
      );
      await selectAll(tester, 'FluentSearchBox');

      await tapOutside(tester);

      expect(node.hasFocus, isFalse, reason: 'FluentSearchBox kept focus');
      expectDismissed(tester, 'FluentSearchBox', 'hello world');
    });

    // Already correct before this change — pinned so it stays that way, since
    // it is the control the other three were fixed to match.
    testWidgets('FluentSpinButton', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await pump(
        tester,
        // `onChanged` is what makes a spin button enabled (`_enabled` is
        // `widget.onChanged != null`); without it the field never takes focus.
        FluentSpinButton(value: 42, focusNode: node, onChanged: (_) {}),
      );
      await selectAll(tester, 'FluentSpinButton');

      await tapOutside(tester);

      expect(node.hasFocus, isFalse, reason: 'FluentSpinButton kept focus');
      expectDismissed(tester, 'FluentSpinButton', '42');
    });
  });

  testWidgets('a focused field still paints its selection', (tester) async {
    final controller = TextEditingController(text: 'hello world');
    final node = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(node.dispose);

    await pump(tester, FluentInput(controller: controller, focusNode: node));
    await selectAll(tester, 'FluentInput');

    // The negative control for the focus gate: if `selectionColor` were simply
    // hardcoded to null the whole group above would pass and selection would be
    // invisible in the running app.
    expect(node.hasFocus, isTrue);
    expect(editable(tester).selectionColor, isNotNull);
    expect(editable(tester).selection?.isCollapsed, isFalse);
  });

  testWidgets('tab-away dismisses too, not just an outside click', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'hello world');
    final node = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(node.dispose);

    await pump(tester, FluentInput(controller: controller, focusNode: node));
    await selectAll(tester, 'FluentInput');

    // Not every blur is a pointer event. Dismissal hangs off the focus node,
    // so keyboard traversal and a programmatic unfocus have to behave like a
    // click away — and neither routes through `_EditableTextTapOutsideAction`.
    node.unfocus();
    await tester.pumpAndSettle();

    expect(node.hasFocus, isFalse);
    expectDismissed(tester, 'FluentInput', 'hello world');
  });

  testWidgets('a focus-property write is not a blur', (tester) async {
    final controller = TextEditingController(text: 'hello world');
    final node = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(node.dispose);

    // Never focused. A host highlighting a search match on an untouched field
    // is the realistic shape of this.
    await pump(tester, FluentInput(controller: controller, focusNode: node));
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
    await tester.pumpAndSettle();

    // `FocusNode` notifies listeners for property writes as well as focus
    // changes, and `hasFocus` is false on those too. Without a transition
    // latch the collapse fires here and eats a range the user never made and
    // never left.
    node.canRequestFocus = false;
    await tester.pumpAndSettle();

    expect(
      controller.selection,
      const TextSelection(baseOffset: 0, extentOffset: 5),
      reason: 'a property write was mistaken for a blur',
    );
  });

  group('pressing a field\'s own chrome neither blurs nor dismisses', () {
    /// Presses [target] and asserts mid-gesture, between down and up.
    ///
    /// `_EditableTextTapOutsideAction` fires on pointer DOWN while the
    /// selection gesture detector hands focus back on pointer UP, so a
    /// completed tap ends focused either way — the damage only exists in the
    /// gap, where a focus-reactive slot unmounts under the cursor. Asserting
    /// after the release would pass with every tap region removed.
    Future<void> expectChromeHeld(
      WidgetTester tester,
      String label,
      Offset target,
    ) async {
      final press = await tester.startGesture(
        target,
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(() async {
        await press.up();
      });
      await tester.pump();

      expect(
        controllerOf(tester).selection.isCollapsed,
        isFalse,
        reason: '$label: pressing its own chrome destroyed the selection',
      );
      expect(
        editable(tester).selectionColor,
        isNotNull,
        reason: '$label: pressing its own chrome unlit the selection',
      );
    }

    testWidgets('FluentTextarea padding', (tester) async {
      final controller = TextEditingController(text: 'hello world');
      final node = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(node.dispose);

      await pump(
        tester,
        FluentTextarea(controller: controller, focusNode: node),
      );
      await selectAll(tester, 'FluentTextarea');

      await expectChromeHeld(
        tester,
        'FluentTextarea',
        tester.getBottomLeft(find.byType(FluentTextarea)) +
            const Offset(20, -3),
      );
      expect(node.hasFocus, isTrue);
    });

    testWidgets('FluentSearchBox leading glyph', (tester) async {
      final controller = TextEditingController(text: 'hello world');
      final node = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(node.dispose);

      await pump(
        tester,
        FluentSearchBox(controller: controller, focusNode: node),
      );
      await selectAll(tester, 'FluentSearchBox');

      await expectChromeHeld(
        tester,
        'FluentSearchBox',
        tester.getTopLeft(find.byType(FluentSearchBox)) + const Offset(6, 16),
      );
      expect(node.hasFocus, isTrue);
    });

    testWidgets('FluentSpinButton stepper', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await pump(
        tester,
        FluentSpinButton(value: 42, focusNode: node, onChanged: (_) {}),
      );
      await selectAll(tester, 'FluentSpinButton');

      // The steppers are the reason this one matters most: incrementing is a
      // normal interaction, not an edge case.
      await expectChromeHeld(
        tester,
        'FluentSpinButton',
        tester.getTopRight(find.byType(FluentSpinButton)) +
            const Offset(-10, 10),
      );
      expect(node.hasFocus, isTrue);
    });
  });

  testWidgets('tapping the chrome does not drop focus', (tester) async {
    final controller = TextEditingController(text: 'hello world');
    final node = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(node.dispose);

    const slot = Key('trailing');
    await pump(
      tester,
      FluentInput(
        controller: controller,
        focusNode: node,
        contentAfter: const SizedBox.square(dimension: 16, key: slot),
      ),
    );
    await tester.tap(find.byType(EditableText), kind: PointerDeviceKind.mouse);
    await tester.pumpAndSettle();
    expect(node.hasFocus, isTrue);

    // Asserted mid-gesture, between press and release, and that is the whole
    // point of the test. `_EditableTextTapOutsideAction` fires on pointer
    // DOWN, and the selection gesture detector hands focus back on pointer UP —
    // so a completed tap ends focused either way and a `tapAt` here would pass
    // with the tap region removed. The damage lives in the gap: a trailing slot
    // that reacts to focus unmounts under the cursor before the click resolves.
    //
    // Aimed at the slot itself rather than an offset from the field's centre,
    // too: the `EditableText` fills the `Expanded` between the slots, so
    // anything short of the slot's own box lands back inside the region
    // `EditableText` installs for itself.
    final press = await tester.startGesture(
      tester.getCenter(find.byKey(slot)),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();

    expect(
      node.hasFocus,
      isTrue,
      reason:
          'pressing the field\'s own chrome unfocused it — the chrome is '
          'outside the EditableText\'s own tap region, so buildFluentInput '
          'has to supply one',
    );

    await press.up();
    await tester.pumpAndSettle();
    expect(node.hasFocus, isTrue, reason: 'focus did not survive the release');
  });
}
