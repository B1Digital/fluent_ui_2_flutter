import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/internal/input_modality.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
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
  });

  group('disabled', () {
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
