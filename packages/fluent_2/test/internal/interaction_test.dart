import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/internal/input_modality.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// [FluentInteractive] is the one place hover / press / focus is resolved, so
/// no component reinvents it. It reports the framework's own [WidgetState] set
/// rather than a bespoke enum, which is what lets component styles be plain
/// [WidgetStateProperty] structs like Material's `ButtonStyle`.
void main() {
  const target = Key('target');

  Future<Set<WidgetState> Function()> pumpInteractive(
    WidgetTester tester, {
    bool enabled = true,
    VoidCallback? onPressed,
    FocusNode? focusNode,
    bool pressedOnSecondary = true,
    bool pressedRequiresHover = false,
    MouseCursor disabledMouseCursor = SystemMouseCursors.forbidden,
  }) async {
    var latest = <WidgetState>{};
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: FluentInteractive(
            enabled: enabled,
            onPressed: onPressed ?? () {},
            focusNode: focusNode,
            pressedOnSecondary: pressedOnSecondary,
            pressedRequiresHover: pressedRequiresHover,
            disabledMouseCursor: disabledMouseCursor,
            builder: (context, states, child) {
              latest = states;
              return const SizedBox(key: target, width: 60, height: 30);
            },
          ),
        ),
      ),
    );
    return () => latest;
  }

  group('pointer', () {
    testWidgets('reports hover on enter and drops it on exit', (tester) async {
      final states = await pumpInteractive(tester);
      await tester.pump();
      expect(states().contains(WidgetState.hovered), isFalse);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      // FocusableActionDetector gates its hover highlight on
      // MouseTracker.mouseIsConnected, which only becomes true after the added
      // pointer has been flushed.
      await tester.pump();

      await mouse.moveTo(tester.getCenter(find.byKey(target)));
      await tester.pump();
      expect(states().contains(WidgetState.hovered), isTrue);

      await mouse.moveTo(const Offset(1000, 1000));
      await tester.pump();
      expect(states().contains(WidgetState.hovered), isFalse);
    });

    testWidgets('reports pressed only while held', (tester) async {
      final states = await pumpInteractive(tester);
      await tester.pump();

      final press = await tester.startGesture(
        tester.getCenter(find.byKey(target)),
      );
      await tester.pump();
      expect(states().contains(WidgetState.pressed), isTrue);

      await press.up();
      await tester.pump();
      expect(states().contains(WidgetState.pressed), isFalse);
    });

    testWidgets('fires onPressed on tap', (tester) async {
      var fired = 0;
      await pumpInteractive(tester, onPressed: () => fired++);
      await tester.pump();
      await tester.tap(find.byKey(target));
      await tester.pump();
      expect(fired, 1);
    });

    // Chrome sets `:active` under whichever mouse button is held, so an
    // upstream Button, MenuItem, Tab, Link and listbox Option all paint their
    // pressed tokens under a middle or right press. Only the left button
    // clicks: the others fire `auxclick`, which nothing handles.
    for (final (name, buttons) in <(String, int)>[
      ('middle', kMiddleMouseButton),
      ('right', kSecondaryMouseButton),
    ]) {
      testWidgets('a $name press shows pressed but never activates', (
        tester,
      ) async {
        var fired = 0;
        final states = await pumpInteractive(tester, onPressed: () => fired++);
        final mouse = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          buttons: buttons,
        );
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.down(tester.getCenter(find.byKey(target)));
        await tester.pump();
        expect(states().contains(WidgetState.pressed), isTrue);

        await mouse.up();
        await tester.pump();
        expect(states().contains(WidgetState.pressed), isFalse);
        expect(fired, 0);
      });
    }

    testWidgets('pressedOnSecondary: false leaves a right press unpressed', (
      tester,
    ) async {
      // Upstream's Combobox-family roots (Dropdown's button) lose `:active` a
      // task after a right press's `contextmenu`; a middle press keeps it.
      final states = await pumpInteractive(tester, pressedOnSecondary: false);
      for (final buttons in <int>[kSecondaryMouseButton, kMiddleMouseButton]) {
        final mouse = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          buttons: buttons,
        );
        await mouse.down(tester.getCenter(find.byKey(target)));
        await tester.pump();
        expect(
          states().contains(WidgetState.pressed),
          buttons == kMiddleMouseButton,
          reason: 'buttons $buttons',
        );
        await mouse.up();
        await mouse.removePointer();
        await tester.pump();
      }
    });
  });

  group('drag-off', () {
    // Chrome moves `:hover` with a held mouse, but `:active` stays where the
    // press landed. Upstream's Button family, Switch, Radio and ColorSwatch
    // paint pressed under `:hover:active`, the rest under a plain `:active`.
    Future<TestGesture> pressAndLeave(
      WidgetTester tester, {
      PointerDeviceKind kind = PointerDeviceKind.mouse,
    }) async {
      final pointer = await tester.createGesture(kind: kind);
      if (kind == PointerDeviceKind.mouse) {
        await pointer.addPointer(location: Offset.zero);
        await pointer.moveTo(tester.getCenter(find.byKey(target)));
      }
      await pointer.down(tester.getCenter(find.byKey(target)));
      await tester.pump();
      await pointer.moveBy(const Offset(1, 0));
      await pointer.moveTo(const Offset(5, 5));
      await tester.pump();
      return pointer;
    }

    testWidgets('pressedRequiresHover: a mouse dragged off is not pressed', (
      tester,
    ) async {
      final states = await pumpInteractive(tester, pressedRequiresHover: true);
      final mouse = await pressAndLeave(tester);
      expect(states().contains(WidgetState.pressed), isFalse);

      await mouse.moveTo(tester.getCenter(find.byKey(target)));
      await tester.pump();
      expect(
        states().contains(WidgetState.pressed),
        isTrue,
        reason: 'dragged back over the control, it is :hover:active again',
      );

      await mouse.up();
      await tester.pump();
      expect(states().contains(WidgetState.pressed), isFalse);
      await mouse.removePointer();
    });

    testWidgets('pressedRequiresHover: a finger dragged off stays pressed', (
      tester,
    ) async {
      final states = await pumpInteractive(tester, pressedRequiresHover: true);
      final finger = await pressAndLeave(tester, kind: PointerDeviceKind.touch);
      expect(states().contains(WidgetState.pressed), isTrue);
      await finger.up();
      await tester.pump();
      expect(states().contains(WidgetState.pressed), isFalse);
    });

    testWidgets('by default a mouse dragged off stays pressed', (tester) async {
      final states = await pumpInteractive(tester);
      final mouse = await pressAndLeave(tester);
      expect(states().contains(WidgetState.pressed), isTrue);
      await mouse.up();
      await mouse.removePointer();
    });

    testWidgets('pressedRequiresHover keeps a right press out if asked', (
      tester,
    ) async {
      final states = await pumpInteractive(
        tester,
        pressedRequiresHover: true,
        pressedOnSecondary: false,
      );
      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byKey(target)));
      await mouse.down(tester.getCenter(find.byKey(target)));
      await mouse.moveBy(const Offset(1, 0));
      await tester.pump();
      expect(states().contains(WidgetState.pressed), isFalse);
      await mouse.up();
      await mouse.removePointer();
    });
  });

  group('disabled', () {
    testWidgets('shows not-allowed, or the cursor it is given', (tester) async {
      // Upstream's disabled Button, Link, MenuItem, Tab, Tag and ColorSwatch
      // are `not-allowed`; Checkbox, Radio, Switch and Slider are `default`.
      MouseCursor? cursor() =>
          RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);
      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        pointer: 1,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);

      await pumpInteractive(tester);
      await mouse.moveTo(tester.getCenter(find.byKey(target)));
      await tester.pump();
      expect(cursor(), SystemMouseCursors.click);

      await pumpInteractive(tester, enabled: false);
      await mouse.moveBy(const Offset(1, 0));
      await tester.pump();
      expect(cursor(), SystemMouseCursors.forbidden);

      await pumpInteractive(
        tester,
        enabled: false,
        disabledMouseCursor: SystemMouseCursors.basic,
      );
      await mouse.moveBy(const Offset(1, 0));
      await tester.pump();
      expect(cursor(), SystemMouseCursors.basic);
    });

    testWidgets('is a real state, not a visual-only grey-out', (tester) async {
      var fired = 0;
      final states = await pumpInteractive(
        tester,
        enabled: false,
        onPressed: () => fired++,
      );
      await tester.pump();
      expect(states().contains(WidgetState.disabled), isTrue);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byKey(target)));
      await tester.pump();
      expect(
        states().contains(WidgetState.hovered),
        isFalse,
        reason: 'a disabled control must not report hover',
      );

      await tester.tap(find.byKey(target), warnIfMissed: false);
      await tester.pump();
      expect(fired, 0);
      expect(states().contains(WidgetState.pressed), isFalse);
    });

    testWidgets('re-enabled under a resting mouse, it hovers at once', (
      tester,
    ) async {
      // Chrome keeps `:hover` on a disabled element, so a control enabled
      // under a still pointer shows its hover tokens without the mouse moving.
      var states = await pumpInteractive(tester, enabled: false);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(find.byKey(target)));
      addTearDown(mouse.removePointer);
      await tester.pump();
      expect(states().contains(WidgetState.hovered), isFalse);

      states = await pumpInteractive(tester);
      await tester.pump();
      expect(states().contains(WidgetState.hovered), isTrue);
    });

    // Chrome, on a <button>: disabling it under a held press drops `:active`
    // and re-enabling it under the same press does not bring it back, yet a
    // press that lands while it is disabled is `:active` the moment it is
    // enabled.
    testWidgets('disabled under a held press, a re-enable stays unpressed', (
      tester,
    ) async {
      var states = await pumpInteractive(tester);
      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );
      await mouse.down(tester.getCenter(find.byKey(target)));
      await tester.pump();
      expect(states().contains(WidgetState.pressed), isTrue);

      await pumpInteractive(tester, enabled: false);
      states = await pumpInteractive(tester);
      await tester.pump();
      expect(states().contains(WidgetState.pressed), isFalse);
      await mouse.up();
    });

    testWidgets('pressed while disabled, it is pressed once enabled', (
      tester,
    ) async {
      var states = await pumpInteractive(tester, enabled: false);
      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      );
      await mouse.down(tester.getCenter(find.byKey(target)));
      await tester.pump();
      expect(states().contains(WidgetState.pressed), isFalse);

      states = await pumpInteractive(tester);
      await tester.pump();
      expect(states().contains(WidgetState.pressed), isTrue);

      await mouse.up();
      await tester.pump();
      expect(states().contains(WidgetState.pressed), isFalse);
    });

    testWidgets('advertises no tap action to assistive technology', (
      tester,
    ) async {
      // An attached onTap handler puts a tap ACTION in the semantics tree even
      // when it no-ops, so a screen reader announces a disabled control as
      // activatable. Every component routes through here, so the guard belongs
      // here rather than in each of them.
      final handle = tester.ensureSemantics();
      await pumpInteractive(tester, enabled: false);
      await tester.pump();
      expect(
        tester
            .getSemantics(find.byKey(target))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
      handle.dispose();
    });
  });

  group('focus', () {
    setUp(FluentInputModality.debugReset);
    tearDown(() {
      FluentInputModality.debugReset();
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
    });

    testWidgets('focused means keyboard-visible focus, not pointer focus', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final states = await pumpInteractive(tester, focusNode: node);
      await tester.pump();
      // Focus-visible is the AND of the framework's highlight and the modality
      // flag, so the modality has to be raised before the highlight can show.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);

      // Focus arriving on a touch device must not raise a ring. That half of
      // upstream's keyborg-driven data-fui-focus-visible is the framework's
      // highlight mode; the other half is the modality flag above.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      node.requestFocus();
      await tester.pump();
      expect(
        states().contains(WidgetState.focused),
        isFalse,
        reason: 'pointer focus must not read as focused',
      );

      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      await tester.pump();
      expect(states().contains(WidgetState.focused), isTrue);
    });

    testWidgets('never borrows WidgetState.selected for focus', (tester) async {
      // Fluent has real *Selected tokens; borrowing the state for focus would
      // paint a ring on every selected tab and menu item.
      final node = FocusNode();
      addTearDown(node.dispose);
      final states = await pumpInteractive(tester, focusNode: node);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      node.requestFocus();
      await tester.pump();
      expect(states().contains(WidgetState.focused), isTrue);
      expect(states().contains(WidgetState.selected), isFalse);
    });
  });

  group('focus modality', () {
    // `alwaysTraditional` is not a contrivance: it is what desktop and web
    // report unconditionally. `_HighlightModeManager` only distinguishes touch
    // from not-touch, so on those platforms the framework says "show the
    // highlight" for pointer focus exactly as loudly as for keyboard focus.
    // Pinning the strategy reproduces that here without depending on the host
    // platform the tests happen to run on.
    setUp(() {
      FluentInputModality.debugReset();
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
    });
    tearDown(() {
      FluentInputModality.debugReset();
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
    });

    testWidgets('a pointer tap does not raise WidgetState.focused', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final states = await pumpInteractive(tester, focusNode: node);
      await tester.pump();

      await tester.tap(
        find.byKey(target),
        kind: PointerDeviceKind.mouse,
        warnIfMissed: false,
      );
      node.requestFocus();
      await tester.pumpAndSettle();

      expect(
        states().contains(WidgetState.focused),
        isFalse,
        reason: 'React draws no ring after a mouse click',
      );
    });

    testWidgets('a key raises it without focus moving', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final states = await pumpInteractive(tester, focusNode: node);
      await tester.pump();
      await tester.tap(
        find.byKey(target),
        kind: PointerDeviceKind.mouse,
        warnIfMissed: false,
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(states().contains(WidgetState.focused), isFalse);

      // Focus does not move here. Only the modality flips — which is exactly
      // the live re-evaluation keyborg does and a one-shot read would miss.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(states().contains(WidgetState.focused), isTrue);
    });

    testWidgets('a pointer down after keyboard navigation drops the ring', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final states = await pumpInteractive(tester, focusNode: node);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(states().contains(WidgetState.focused), isTrue);

      await tester.tap(
        find.byKey(target),
        kind: PointerDeviceKind.mouse,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(
        states().contains(WidgetState.focused),
        isFalse,
        reason: 'keyborg clears the flag on pointer down, ring and all',
      );
    });
  });

  group('FluentStateColor', () {
    const rest = Color(0xFF000001);
    const hover = Color(0xFF000002);
    const pressed = Color(0xFF000003);
    const selected = Color(0xFF000004);
    const disabled = Color(0xFF000005);

    final property = FluentStateColor.tokens(
      rest: rest,
      hover: hover,
      pressed: pressed,
      selected: selected,
      disabled: disabled,
    );

    test('selects a token per state, never computes one', () {
      expect(property.resolve({}), rest);
      expect(property.resolve({WidgetState.hovered}), hover);
      expect(property.resolve({WidgetState.pressed}), pressed);
      expect(property.resolve({WidgetState.selected}), selected);
      expect(property.resolve({WidgetState.disabled}), disabled);
    });

    test('disabled beats every other state', () {
      expect(
        property.resolve({
          WidgetState.disabled,
          WidgetState.hovered,
          WidgetState.pressed,
        }),
        disabled,
      );
    });

    test('pressed beats hovered, matching upstream precedence', () {
      expect(
        property.resolve({WidgetState.hovered, WidgetState.pressed}),
        pressed,
      );
    });

    test('omitted tokens fall back to rest rather than being computed', () {
      final sparse = FluentStateColor.tokens(rest: rest);
      expect(sparse.resolve({WidgetState.hovered}), rest);
      expect(sparse.resolve({WidgetState.disabled}), rest);
    });
  });
}
