# Focus Modality and Input Chrome Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make keyboard focus, input chrome and popup sizing match Fluent UI React v9, fixing six defects at the design-system level rather than per component.

**Architecture:** One new internal primitive (`FluentInputModality`) supplies a global "navigating with keyboard" flag, mirroring the keyborg library `react-tabster` uses; the two independent producers of `WidgetState.focused` both AND against it. The remaining five workstreams are localised fixes to existing shared widgets — the focus-underline primitive, the SearchBox surface, the Nav row builder, the TabList flip scheduler, and the menu/popup constraint chain.

**Tech Stack:** Dart / Flutter (widgets layer only), melos monorepo, `flutter_test`.

## Global Constraints

Copied verbatim from the spec and the repo's CI. Every task's requirements implicitly include this section.

- **No `package:flutter/material.dart` or `package:flutter/cupertino.dart`.** Use `package:flutter/widgets.dart`. `melos run no-material` greps for the import directives and fails the build. `WidgetState*` lives in the widgets layer.
- **Never compute a colour.** No `withOpacity`, no `Color.lerp` on a surface — use `fluentLerpColor`. Fluent ships explicit `*Hover`/`*Pressed`/`*Selected`/`*Disabled` tokens; reaching for arithmetic means the wrong token was chosen.
- **Never hardcode `Colors.transparent`.** Fluent's transparent tokens turn *opaque* in high contrast.
- **`public_member_api_docs`, `comment_references`, `unused_import` are errors.** Every new public member needs a doc comment.
- **Verification command:** `cd /Users/alisinancobani/IdeaProjects/flutent_2_web && melos run ci` = analyze + format + no-material + test. Baseline before this plan: **1920 web tests, 55 core, 2 gallery, all green.**
- **Per-task test command:** `cd packages/fluent_2_web && flutter test test/<area>/<file>_test.dart`
- **Goldens are regenerated ONCE, centrally, in the final task.** Never run `flutter test --update-goldens` in any other task, and never in parallel — concurrent runs race and cross-contaminate. A golden failing mid-plan because of an intended visual change is expected.
- **Comment style:** these files explain *why* a value is what it is and cite upstream (`useXStyles.styles.ts`) or the Figma fixture. When changing a value, rewrite the comment that justified the old one. A stale comment asserting the old number is worse than none.

---

## File Structure

**Create**
- `packages/fluent_2_web/lib/src/internal/input_modality.dart` — the global keyboard-modality flag. Sole responsibility: observe raw input and expose one `ValueListenable<bool>`.
- `packages/fluent_2_web/test/internal/input_modality_test.dart`

**Modify**
- `lib/src/internal/interaction.dart` — Producer A gate
- `lib/src/overlays/menu.dart` — Producer B gate; menu surface sizing; max height
- `lib/src/inputs/dropdown.dart` — Producer B gate; underline migration; max height
- `lib/src/navigation/breadcrumb.dart` — Producer B gate
- `lib/src/inputs/tag_picker.dart` — Producer B gate; popup 160 floor
- `lib/src/overlays/toaster.dart`, `lib/src/surfaces/tooltip.dart` — retire hand-rolled copies
- `lib/src/inputs/input.dart` — underline primitive shape
- `lib/src/inputs/search_box.dart` — Stack layout fix; underline migration
- `lib/src/inputs/spin_button.dart`, `lib/src/inputs/textarea.dart` — underline migration
- `lib/src/navigation/nav.dart` — indicator fade
- `lib/src/navigation/tab_list.dart` — flip flash
- `lib/src/overlays/menu_style.dart` — add `minWidth`

---

## Task 1: `FluentInputModality` primitive

**Files:**
- Create: `packages/fluent_2_web/lib/src/internal/input_modality.dart`
- Test: `packages/fluent_2_web/test/internal/input_modality_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `FluentInputModality.keyboard` → `ValueListenable<bool>`; `FluentInputModality.debugReset()` → `void`.

- [ ] **Step 1: Write the failing test**

Create `packages/fluent_2_web/test/internal/input_modality_test.dart`:

```dart
import 'package:fluent_2_web/src/internal/input_modality.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(FluentInputModality.debugReset);
  tearDown(FluentInputModality.debugReset);

  test('starts pointer-first, matching keyborg', () {
    expect(FluentInputModality.keyboard.value, isFalse);
  });

  testWidgets('a key press raises it and a pointer down clears it', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    expect(FluentInputModality.keyboard.value, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(FluentInputModality.keyboard.value, isTrue);

    // A real pointer-down, routed the way GestureBinding delivers it.
    final gesture = await tester.createGesture();
    await gesture.down(Offset.zero);
    await gesture.up();
    expect(FluentInputModality.keyboard.value, isFalse);
  });

  testWidgets('typing does not flip it — keyborg ignores character keys', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    expect(FluentInputModality.keyboard.value, isFalse);
  });

  testWidgets('notifies listeners so a focused widget can re-evaluate', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    var notifications = 0;
    void listener() => notifications++;
    FluentInputModality.keyboard.addListener(listener);
    addTearDown(() => FluentInputModality.keyboard.removeListener(listener));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(notifications, 1);

    // Idempotent: the same modality twice must not rebuild the world.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(notifications, 1);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd packages/fluent_2_web && flutter test test/internal/input_modality_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:fluent_2_web/src/internal/input_modality.dart'`.

- [ ] **Step 3: Write the implementation**

Create `packages/fluent_2_web/lib/src/internal/input_modality.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

/// Whether the user is currently navigating with the keyboard.
///
/// The Dart counterpart of [keyborg][], which `react-tabster` uses to implement
/// focus-visible: one flag per app, set true by a key and false by a pointer,
/// and ANDed with "has focus" to decide whether a focus ring is drawn.
///
/// Flutter's own `FocusHighlightMode` cannot serve. `_HighlightModeManager`
/// distinguishes *touch* from *not-touch*, so a mouse click resolves to
/// `FocusHighlightMode.traditional` — the identical value a key press produces
/// — and `FocusableActionDetector.onShowFocusHighlight` fires for pointer
/// focus on web and desktop. That is the whole defect this exists to fix.
///
/// The flag is global rather than per-widget because upstream's is: keyboard-
/// open a menu, arrow onto a row, then move the mouse over a different row and
/// React still draws the ring, because *hover* does not clear the flag — only
/// a pointer *down* does. A per-widget "suppress while the pointer is here"
/// scheme cannot reproduce that.
///
/// [keyborg]: https://github.com/microsoft/keyborg
abstract final class FluentInputModality {
  static final ValueNotifier<bool> _keyboard = ValueNotifier<bool>(false);
  static bool _installed = false;

  /// True while the last input was a key rather than a pointer.
  ///
  /// Listen to it: a widget that already holds focus must repaint when the
  /// modality flips even though focus has not moved.
  static ValueListenable<bool> get keyboard {
    _install();
    return _keyboard;
  }

  /// Drops the global listeners and returns to the pointer-first default.
  ///
  /// Tests only — the flag is process-wide, so one test's key press would
  /// otherwise leak into the next.
  @visibleForTesting
  static void debugReset() {
    if (_installed) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_handlePointer);
      HardwareKeyboard.instance.removeHandler(_handleKey);
      _installed = false;
    }
    _keyboard.value = false;
  }

  static void _install() {
    if (_installed) return;
    _installed = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointer);
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  static void _handlePointer(PointerEvent event) {
    // Down, not hover: keyborg listens for `mousedown`/`touchstart` and
    // deliberately ignores movement, which is what lets a keyboard-navigated
    // ring survive the mouse passing over the control.
    if (event is PointerDownEvent) _keyboard.value = false;
  }

  static bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent && _isNavigationKey(event.logicalKey)) {
      _keyboard.value = true;
    }
    // Never consume: this observes, it does not handle.
    return false;
  }

  // ponytail: keyborg flips on ANY key whose target is not a text field, which
  // in Flutter would mean walking the focus tree for an EditableText on every
  // keystroke. This lists the keys that actually move or activate focus
  // instead — the observable difference is nil for ring behaviour, and typing
  // into a field still cannot raise a ring elsewhere, which is the property
  // keyborg's text-field exemption exists to protect.
  static bool _isNavigationKey(LogicalKeyboardKey key) => const <
    LogicalKeyboardKey
  >{
    LogicalKeyboardKey.tab,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.home,
    LogicalKeyboardKey.end,
    LogicalKeyboardKey.pageUp,
    LogicalKeyboardKey.pageDown,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.escape,
    LogicalKeyboardKey.space,
  }.contains(key);
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/fluent_2_web && flutter test test/internal/input_modality_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 5: Analyze and commit**

```bash
cd /Users/alisinancobani/IdeaProjects/flutent_2_web/packages/fluent_2_web
dart analyze lib/src/internal/input_modality.dart && dart format lib test
cd /Users/alisinancobani/IdeaProjects/flutent_2_web
git add packages/fluent_2_web/lib/src/internal/input_modality.dart packages/fluent_2_web/test/internal/input_modality_test.dart
git commit -m "feat(web): add FluentInputModality, the keyborg equivalent"
```

---

## Task 2: Gate Producer A — `FluentInteractive`

**Files:**
- Modify: `packages/fluent_2_web/lib/src/internal/interaction.dart:154-169`
- Test: `packages/fluent_2_web/test/internal/interaction_test.dart`

**Interfaces:**
- Consumes: `FluentInputModality.keyboard` from Task 1.
- Produces: `WidgetState.focused` now means keyboard-visible focus for every `FluentInteractive` consumer.

- [ ] **Step 1: Write the failing test**

Append to `packages/fluent_2_web/test/internal/interaction_test.dart`, inside the top-level `main()`:

```dart
  group('focus modality', () {
    setUp(FluentInputModality.debugReset);
    tearDown(FluentInputModality.debugReset);

    testWidgets('a pointer tap does not raise WidgetState.focused', (
      tester,
    ) async {
      final states = <Set<WidgetState>>[];
      await tester.pumpWidget(
        FluentApp(
          home: Center(
            child: FluentInteractive(
              onPressed: () {},
              builder: (context, s, _) {
                states.add(s);
                return const SizedBox(width: 40, height: 40);
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byType(FluentInteractive));
      await tester.pumpAndSettle();
      expect(
        states.last.contains(WidgetState.focused),
        isFalse,
        reason: 'React draws no ring after a mouse click',
      );
    });

    testWidgets('a key raises it without focus moving', (tester) async {
      final states = <Set<WidgetState>>[];
      await tester.pumpWidget(
        FluentApp(
          home: Center(
            child: FluentInteractive(
              autofocus: true,
              onPressed: () {},
              builder: (context, s, _) {
                states.add(s);
                return const SizedBox(width: 40, height: 40);
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byType(FluentInteractive));
      await tester.pumpAndSettle();
      expect(states.last.contains(WidgetState.focused), isFalse);

      // Focus does not move here. Only the modality flips — which is exactly
      // the live re-evaluation keyborg does and a one-shot read would miss.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(states.last.contains(WidgetState.focused), isTrue);
    });
  });
```

Add `import 'package:fluent_2_web/src/internal/input_modality.dart';` and `import 'package:flutter/services.dart';` to the file's imports if absent.

- [ ] **Step 2: Run it to verify it fails**

Run: `cd packages/fluent_2_web && flutter test test/internal/interaction_test.dart --plain-name 'focus modality'`
Expected: FAIL — the first test reports `focused` present after a tap.

- [ ] **Step 3: Implement the gate**

In `lib/src/internal/interaction.dart`, replace the `onShowFocusHighlight` line (currently `:169`) and add modality bookkeeping to the State class.

Add to the State's fields and lifecycle:

```dart
  bool _highlight = false;

  @override
  void initState() {
    super.initState();
    FluentInputModality.keyboard.addListener(_syncFocusVisible);
  }

  @override
  void dispose() {
    FluentInputModality.keyboard.removeListener(_syncFocusVisible);
    super.dispose();
  }

  /// `focused` is the AND of "the framework wants a highlight" and "the last
  /// input was a key". Re-run on either changing: the modality can flip while
  /// focus stands still, and upstream repaints when it does.
  void _syncFocusVisible() => _set(
    WidgetState.focused,
    value: _highlight && FluentInputModality.keyboard.value,
  );
```

Replace the `onShowFocusHighlight` argument and its comment with:

```dart
      // Deliberately wired from onShowFocusHighlight, not onFocusChange — but
      // that alone is NOT enough. Flutter's highlight mode is touch-vs-not-
      // touch, so a mouse click resolves to `traditional` exactly as a key
      // does and this fires for pointer focus. FluentInputModality supplies
      // the missing half, matching upstream's keyborg-driven
      // data-fui-focus-visible.
      //
      // WidgetState.selected is deliberately left untouched — Fluent has real
      // *Selected tokens (tabs, menu items, toggle buttons) and borrowing it
      // for focus would paint rings on selected items.
      onShowFocusHighlight: (value) {
        _highlight = value;
        _syncFocusVisible();
      },
```

Add the import: `import 'input_modality.dart';`

If the State class already declares `initState`/`dispose`, merge these lines into the existing overrides rather than adding a second one.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/fluent_2_web && flutter test test/internal/interaction_test.dart`
Expected: PASS.

- [ ] **Step 5: Audit every other consumer**

Run: `cd packages/fluent_2_web && grep -rn "WidgetState.focused" lib/ | grep -v internal/input_modality.dart`

For each hit, confirm it wants *keyboard-visible* focus. Record any that genuinely want "focused by any means" in the commit message. Do not change them in this task.

- [ ] **Step 6: Run the full suite to find fallout**

Run: `cd packages/fluent_2_web && flutter test 2>&1 | grep -oE "test/[a-z_/]+\.dart: .*\[E\]" | sort -u`
Expected: only golden failures, if any. Fix any non-golden failure before committing; a test that drove focus with `tester.tap` and asserted a ring must be rewritten to use a key.

- [ ] **Step 7: Commit**

```bash
cd /Users/alisinancobani/IdeaProjects/flutent_2_web
git add packages/fluent_2_web/lib/src/internal/interaction.dart packages/fluent_2_web/test/internal/interaction_test.dart
git commit -m "fix(web): the focus ring no longer appears on pointer focus"
```

---

## Task 3: Gate Producer B — the four synthesised sites

**Files:**
- Modify: `packages/fluent_2_web/lib/src/overlays/menu.dart:815`
- Modify: `packages/fluent_2_web/lib/src/inputs/dropdown.dart:1016`
- Modify: `packages/fluent_2_web/lib/src/navigation/breadcrumb.dart:1050`
- Modify: `packages/fluent_2_web/lib/src/inputs/tag_picker.dart:1184`
- Test: `packages/fluent_2_web/test/overlays/menu_test.dart`

**Interfaces:**
- Consumes: `FluentInputModality.keyboard` from Task 1.
- Produces: nothing new; the four builders keep their current signatures.

These four are NOT covered by Task 2. Menu rows sit outside the traversal order (`menu.dart:805`) inside `ExcludeFocus` (`:837`), so `FluentInteractive` never sees focus for them. Each site instead synthesises the state from an "active index" that **hover** sets (`menu.dart:799` `onEnter` → `:569`). Without a gate the ring means "the mouse is here".

- [ ] **Step 1: Write the failing test**

Append to `packages/fluent_2_web/test/overlays/menu_test.dart` inside `main()`:

```dart
  group('focus modality', () {
    setUp(FluentInputModality.debugReset);
    tearDown(FluentInputModality.debugReset);

    testWidgets('hovering a row does not ring it', (tester) async {
      await tester.pumpWidget(
        FluentApp(
          home: Center(
            child: FluentMenu(
              trigger: const FluentButton(child: Text('Open')),
              items: <FluentMenuItemData>[
                FluentMenuItemData(label: const Text('One'), onPressed: () {}),
                FluentMenuItemData(label: const Text('Two'), onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('One')));
      await tester.pumpAndSettle();

      expect(
        find.byType(FluentMenu),
        isNot(paints..rrect(strokeWidth: FluentStroke.thick)),
        reason: 'React paints the hover fill, never a ring, on mouse',
      );
    });

    testWidgets('arrowing onto a row rings it', (tester) async {
      await tester.pumpWidget(
        FluentApp(
          home: Center(
            child: FluentMenu(
              trigger: const FluentButton(child: Text('Open')),
              items: <FluentMenuItemData>[
                FluentMenuItemData(label: const Text('One'), onPressed: () {}),
                FluentMenuItemData(label: const Text('Two'), onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(
        find.byType(FluentMenu),
        paints..rrect(strokeWidth: FluentStroke.thick),
      );
    });
  });
```

Adjust `FluentMenu`'s constructor arguments to the real API if they differ — read `lib/src/overlays/menu.dart`'s `FluentMenu` class before writing, and mirror an existing test in the same file.

- [ ] **Step 2: Run it to verify it fails**

Run: `cd packages/fluent_2_web && flutter test test/overlays/menu_test.dart --plain-name 'focus modality'`
Expected: FAIL — the hover test finds a ring.

- [ ] **Step 3: Gate all four sites**

The rows rebuild when the modality flips, so each site wraps its subtree in a `ValueListenableBuilder<bool>`. Reading the value once without listening compiles, passes a naive test, and does not re-evaluate — that is the failure mode the second test above exists to catch.

In `lib/src/overlays/menu.dart`, wrap the row builder's result and gate the state:

```dart
          builder: (context, states, _) => ValueListenableBuilder<bool>(
            valueListenable: FluentInputModality.keyboard,
            builder: (context, keyboard, _) =>
                buildFluentMenuItem(state, style, <WidgetState>{
                  ...states,
                  // The active row is where the keyboard is, even though the
                  // framework's focus sits on the level rather than the row.
                  // `level.active` is also set by hover (:799), so it alone
                  // means "active descendant" — upstream's
                  // `data-activedescendant`. The ring belongs to its
                  // focus-visible sibling, which is this AND.
                  if (level.active == index && keyboard) WidgetState.focused,
                  if (submenuOpen) WidgetState.hovered,
                  if (item.selected) WidgetState.selected,
                }),
          ),
```

Apply the identical shape at `dropdown.dart:1016`, `breadcrumb.dart:1050` and `tag_picker.dart:1184` — read each site first; they differ in which local holds the active index and in the surrounding builder's parameter names.

Add `import '../internal/input_modality.dart';` to each of the four files.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/fluent_2_web && flutter test test/overlays/menu_test.dart test/inputs/dropdown_test.dart test/navigation/breadcrumb_test.dart test/inputs/tag_picker_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/alisinancobani/IdeaProjects/flutent_2_web
git add packages/fluent_2_web/lib/src/overlays/menu.dart packages/fluent_2_web/lib/src/inputs/dropdown.dart packages/fluent_2_web/lib/src/navigation/breadcrumb.dart packages/fluent_2_web/lib/src/inputs/tag_picker.dart packages/fluent_2_web/test/overlays/menu_test.dart
git commit -m "fix(web): active-descendant rows ring only under keyboard"
```

---

## Task 4: Retire the two hand-rolled modality copies

**Files:**
- Modify: `packages/fluent_2_web/lib/src/overlays/toaster.dart:655-662`
- Modify: `packages/fluent_2_web/lib/src/surfaces/tooltip.dart:474, 515-516`

**Interfaces:**
- Consumes: `FluentInputModality.keyboard` from Task 1.
- Produces: nothing new.

Both read `FocusManager.instance.highlightMode == FocusHighlightMode.traditional`, which is the same wrong signal Task 2 replaced. `react-tooltip`'s `useTooltipBase.tsx:212` calls `useIsNavigatingWithKeyboard()` — the same keyborg flag — so `tooltip.dart:474` is a direct port of the right idea onto the wrong source.

- [ ] **Step 1: Write the failing test**

Append to `packages/fluent_2_web/test/surfaces/tooltip_test.dart` inside `main()`:

```dart
  testWidgets('a mouse click does not count as keyboard navigation', (
    tester,
  ) async {
    FluentInputModality.debugReset();
    addTearDown(FluentInputModality.debugReset);

    await tester.pumpWidget(
      FluentApp(
        home: Center(
          child: FluentTooltip(
            content: const Text('Tip', key: Key('tip')),
            child: const Text('trigger', key: Key('trigger')),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('trigger')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('tip')),
      findsNothing,
      reason: 'pointer focus must not open a tooltip the way a key does',
    );
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd packages/fluent_2_web && flutter test test/surfaces/tooltip_test.dart --plain-name 'mouse click does not count'`
Expected: FAIL — the tip is found.

- [ ] **Step 3: Replace both sources**

In `lib/src/surfaces/tooltip.dart`, delete the `FocusManager`-derived `_keyboardMode` field and its listener, and read `FluentInputModality.keyboard.value` where `_keyboardMode` was used, subscribing to the listenable in `initState`/`dispose` so a mid-flight flip is honoured.

In `lib/src/overlays/toaster.dart:655`, replace
`_focusNode.hasFocus && FocusManager.instance.highlightMode == FocusHighlightMode.traditional`
with
`_focusNode.hasFocus && FluentInputModality.keyboard.value`,
adding the same listener pair so the toast repaints when the modality flips.

Add `import '../internal/input_modality.dart';` to both files. Remove any now-unused `FocusManager`/`FocusHighlightMode` references — `unused_import` is an error.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/fluent_2_web && flutter test test/surfaces/tooltip_test.dart test/overlays/toaster_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/alisinancobani/IdeaProjects/flutent_2_web
git add packages/fluent_2_web/lib/src/surfaces/tooltip.dart packages/fluent_2_web/lib/src/overlays/toaster.dart packages/fluent_2_web/test/surfaces/tooltip_test.dart
git commit -m "refactor(web): tooltip and toaster read the shared modality flag"
```

---

## Task 5: Focus underline — fix the shape in the primitive

**Files:**
- Modify: `packages/fluent_2_web/lib/src/inputs/input.dart:623-711`
- Test: `packages/fluent_2_web/test/inputs/input_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `FluentInputFocusUnderline({Key? key, required bool focused, required Color color, BorderRadius borderRadius, double thickness})` — `thickness` is new and defaults to `FluentStroke.thick`.

A 4px radius on a 2px-tall box cannot survive: Skia scales every radius by `min(edge / sum-of-radii-on-that-edge)` = `2 / 4` = 0.5, so the shipped radius is 2 and half of that is consumed by the bar's own height. React hits the same CSS clamp and works around it in `useDropdownStyles.styles.ts:45` — make the `::after` `max(strokeWidthThick, borderRadiusMedium)` tall, put the radii on its bottom corners, then trim back with `clipPath: inset(calc(100% - 2px) 0 0 0)`.

- [ ] **Step 1: Write the failing test**

Append to `packages/fluent_2_web/test/inputs/input_test.dart` inside `main()`:

```dart
  group('focus underline shape', () {
    testWidgets('paints at the radius height and clips back to the bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        FluentApp(
          home: Center(
            child: SizedBox(
              width: 200,
              height: 40,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: FluentStroke.thick,
                  child: FluentInputFocusUnderline(
                    focused: true,
                    color: const Color(0xFF0F6CBD),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The layout slot stays 2 tall...
      expect(
        tester.getSize(find.byType(FluentInputFocusUnderline)).height,
        FluentStroke.thick,
      );
      // ...while the painted box is 4, so the 4px radius is not clamped away.
      final painted = tester.getSize(
        find.descendant(
          of: find.byType(FluentInputFocusUnderline),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(
        painted.height,
        4.0,
        reason: 'Skia halves a 4px radius on a 2px box; React pads then clips',
      );
      expect(
        find.byType(FluentInputFocusUnderline),
        paints..clipRect(),
        reason: 'the extra 2px must be trimmed, not shown',
      );
    });
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd packages/fluent_2_web && flutter test test/inputs/input_test.dart --plain-name 'focus underline shape'`
Expected: FAIL — painted height is 2.0, and no `clipRect` is recorded.

- [ ] **Step 3: Implement**

In `lib/src/inputs/input.dart`, add the parameter to the widget:

```dart
  /// The bar's own height. The painted rect is grown to at least the corner
  /// radius and clipped back to this, which is the only way a radius larger
  /// than the bar survives.
  final double thickness;
```

with `this.thickness = FluentStroke.thick,` in the constructor.

Replace the `child:` of the `AnimatedBuilder` in `build` with:

```dart
    // `borderRadius` is the container's bottom corners — 4 by default — on a
    // bar only 2 tall. Skia scales every radius by
    // `min(edge / sum-of-radii-on-that-edge)`, so drawing it directly ships a
    // 2px radius, half of it lost to the bar's own height, and the ends read
    // square. `useDropdownStyles.styles.ts:45` hits the identical CSS clamp
    // and solves it the same way: draw at `max(thickness, radius)` and clip
    // back, upstream's `clipPath: inset(calc(100% - 2px) 0 0 0)`.
    child: ClipRect(
      child: OverflowBox(
        alignment: Alignment.bottomCenter,
        maxHeight: math.max(thickness, _maxRadius(borderRadius)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
          ),
        ),
      ),
    ),
```

Note `build` is on the State, so reference `widget.color`, `widget.borderRadius`, `widget.thickness`.

Add a file-private helper beside the class:

```dart
/// The largest corner radius on [radius], which is how tall the bar has to be
/// painted for that corner to survive Skia's scaling.
double _maxRadius(BorderRadius radius) => math.max(
  math.max(radius.bottomLeft.y, radius.bottomRight.y),
  math.max(radius.topLeft.y, radius.topRight.y),
);
```

Add `import 'dart:math' as math;` if absent.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/fluent_2_web && flutter test test/inputs/input_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/alisinancobani/IdeaProjects/flutent_2_web
git add packages/fluent_2_web/lib/src/inputs/input.dart packages/fluent_2_web/test/inputs/input_test.dart
git commit -m "fix(web): the focus underline keeps its corner radius"
```

---

## Task 6: SearchBox — move the constraints inside the Stack

**Files:**
- Modify: `packages/fluent_2_web/lib/src/inputs/search_box.dart:461-469`
- Test: `packages/fluent_2_web/test/inputs/search_box_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: nothing new.

Do this **before** Task 7 — the migration edits the same block, and fixing the layout first keeps each diff readable.

`RenderStack` lays non-positioned children out with `StackFit.loose`, i.e. `BoxConstraints.loose(constraints.biggest)`, which drops `minHeight` to 0. The surface then sizes to its content — `max(icon 20, body1 line height 20)` = 20 — because its padding is horizontal-only. Both `Positioned(bottom: 0)` overlays therefore land ~12px below the bordered box. That detached 1px line is the reported "stray rule". `input.dart:565` already puts the `ConstrainedBox` inside the `Stack` and renders correctly.

- [ ] **Step 1: Write the failing test**

Append to `packages/fluent_2_web/test/inputs/search_box_test.dart` inside `main()`:

```dart
  testWidgets('the bordered box fills the control height at every size', (
    tester,
  ) async {
    const heights = <FluentSearchBoxSize, double>{
      FluentSearchBoxSize.small: 24,
      FluentSearchBoxSize.medium: 32,
      FluentSearchBoxSize.large: 40,
    };

    for (final entry in heights.entries) {
      await tester.pumpWidget(
        FluentApp(
          home: Center(
            child: SizedBox(
              width: 300,
              child: FluentSearchBox(key: const Key('sb'), size: entry.key),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final box = tester.getRect(
        find
            .descendant(
              of: find.byKey(const Key('sb')),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        box.height,
        entry.value,
        reason: '${entry.key.name}: the decorated surface must fill the slot',
      );
      // The rule sits ON the box's bottom edge, not below it.
      final rule = tester.getRect(
        find
            .descendant(
              of: find.byKey(const Key('sb')),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(
        rule.bottom,
        box.bottom,
        reason: '${entry.key.name}: the underline must not detach',
      );
    }
  });
```

Adjust `FluentSearchBoxSize`'s member names and `FluentSearchBox`'s constructor to the real API — read `lib/src/inputs/search_box.dart` first.

- [ ] **Step 2: Run it to verify it fails**

Run: `cd packages/fluent_2_web && flutter test test/inputs/search_box_test.dart --plain-name 'fills the control height'`
Expected: FAIL — box height 20, and the rule's bottom is ~12px past the box's.

- [ ] **Step 3: Implement**

In `search_box.dart`, replace the `return ConstrainedBox(...)` block at `:461` with the `Stack`-inside arrangement:

```dart
  return ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maximumSize.width),
    child: Stack(
      children: <Widget>[
        // The minimum has to reach the DECORATED box, not the Stack.
        // RenderStack lays non-positioned children out with StackFit.loose,
        // which drops minHeight to 0 — so a ConstrainedBox wrapped around the
        // Stack leaves the surface to size to its 20px content and strands
        // both bottom-pinned overlays below it. FluentInput (input.dart:565)
        // already nests it this way.
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: minimumSize.height,
            minWidth: minimumSize.width,
          ),
          child: surface,
        ),
        // ... the two Positioned children unchanged ...
      ],
    ),
  );
```

Keep both `Positioned` children exactly as they are.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/fluent_2_web && flutter test test/inputs/search_box_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/alisinancobani/IdeaProjects/flutent_2_web
git add packages/fluent_2_web/lib/src/inputs/search_box.dart packages/fluent_2_web/test/inputs/search_box_test.dart
git commit -m "fix(web): the search box surface fills its height again"
```

---

## Task 7: Migrate the four hand-rolled underlines onto the primitive

**Files:**
- Modify: `packages/fluent_2_web/lib/src/inputs/dropdown.dart:468-481`
- Modify: `packages/fluent_2_web/lib/src/inputs/search_box.dart` (the `underlineColor` `Positioned`)
- Modify: `packages/fluent_2_web/lib/src/inputs/spin_button.dart`
- Modify: `packages/fluent_2_web/lib/src/inputs/textarea.dart`
- Test: the four matching `test/inputs/*_test.dart`

**Interfaces:**
- Consumes: `FluentInputFocusUnderline` with `thickness` from Task 5.
- Produces: nothing new.

Input and TagPicker already use the primitive and are fixed for free by Task 5.

- [ ] **Step 1: Write the failing test**

For each of the four components, append to its test file:

```dart
  testWidgets('the focus bar comes from the shared primitive', (tester) async {
    await tester.pumpWidget(
      FluentApp(
        home: Center(
          child: SizedBox(width: 300, child: /* the component, focused */),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(/* the component */),
        matching: find.byType(FluentInputFocusUnderline),
      ),
      findsOneWidget,
      reason: 'one shape, one implementation — see input.dart:623',
    );
  });
```

Fill in the component and the focus mechanism from an existing focused-state test in the same file.

- [ ] **Step 2: Run them to verify they fail**

Run: `cd packages/fluent_2_web && flutter test test/inputs/dropdown_test.dart test/inputs/search_box_test.dart test/inputs/spin_button_test.dart test/inputs/textarea_test.dart --plain-name 'shared primitive'`
Expected: FAIL — `findsNothing` at each.

- [ ] **Step 3: Replace each hand-rolled stack**

In each file, replace the `Transform.scale`/`FluentAnimatedStyle` + `DecoratedBox` pair inside the underline `Positioned` with:

```dart
          child: FluentInputFocusUnderline(
            focused: state.focused && state.enabled,
            color: underlineColor,
            borderRadius: BorderRadius.only(
              bottomLeft: radius.bottomLeft,
              bottomRight: radius.bottomRight,
            ),
          ),
```

Keep each `Positioned(left: 0, right: 0, bottom: 0, height: FluentStroke.thick)` wrapper. Where a component used its own motion spec constants (e.g. `fluentSearchBoxUnderlineEnter`), confirm they are identical to `fluentInputFocusUnderlineEnter`/`Exit`; if any differs, stop and report rather than silently changing the motion. Delete constants left unreferenced — `unused_import` and dead public constants both trip the analyzer.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/fluent_2_web && flutter test test/inputs/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/alisinancobani/IdeaProjects/flutent_2_web
git add packages/fluent_2_web/lib/src/inputs packages/fluent_2_web/test/inputs
git commit -m "refactor(web): one focus underline implementation for six inputs"
```

---

## Task 8: Nav indicator fade

**Files:**
- Modify: `packages/fluent_2_web/lib/src/navigation/nav.dart:472-502`
- Test: `packages/fluent_2_web/test/navigation/nav_test.dart`

**Interfaces:**
- Consumes: `FluentAnimatedStyle<Color>`, `fluentLerpColor`, `fluentNavSurfaceMotion` (all existing).
- Produces: nothing new.

React's Nav indicator is a per-item `::after` with no transform and no transition on position — it **cannot** travel between rows. It does ramp `background: transparent → colorCompoundBrandForeground1` over 100 ms linear, and we drop that: `nav.dart:488` swaps the bar in as a boolean, so it appears at full alpha on frame one. `fluentNavSurfaceMotion` is already `FluentDuration.faster` / `FluentCurve.linear` — bit-for-bit the upstream tokens.

- [ ] **Step 1: Write the failing test**

Append to `packages/fluent_2_web/test/navigation/nav_test.dart` inside `main()`:

```dart
  testWidgets('the indicator fades up rather than appearing', (tester) async {
    Widget nav({required String selected}) => FluentApp(
      home: Center(
        child: FluentNav(
          selectedValue: selected,
          onSelect: (_) {},
          items: <FluentNavItem>[
            const FluentNavItem(value: 'a', label: Text('A')),
            const FluentNavItem(value: 'b', label: Text('B')),
          ],
        ),
      ),
    );

    await tester.pumpWidget(nav(selected: 'a'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(nav(selected: 'b'));

    // Half a frame into a 100ms ramp the bar must be partly transparent.
    await tester.pump(const Duration(milliseconds: 50));
    final decoration = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.color != null && d.color!.a > 0 && d.color!.a < 1);
    expect(decoration.color!.a, greaterThan(0));
    expect(decoration.color!.a, lessThan(1));

    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion lands the indicator on the first frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      FluentApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Center(
            child: FluentNav(
              selectedValue: 'a',
              onSelect: (_) {},
              items: <FluentNavItem>[
                const FluentNavItem(value: 'a', label: Text('A')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // No frame is scheduled: the bar is already at its final alpha.
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
```

Adjust `FluentNav`/`FluentNavItem` constructor arguments to the real API — read `lib/src/navigation/nav.dart` first and mirror an existing test.

- [ ] **Step 2: Run them to verify they fail**

Run: `cd packages/fluent_2_web && flutter test test/navigation/nav_test.dart --plain-name 'indicator'`
Expected: FAIL — no partly-transparent decoration exists; the bar is 0 or 1.

- [ ] **Step 3: Implement**

Replace the `child:` of the indicator `SizedBox` at `nav.dart:487-497` with:

```dart
          // Upstream ramps `background: transparent -> compoundBrandForeground1`
          // over `navItemTokens.animationTokens` — 100ms linear, which
          // `fluentNavSurfaceMotion` already carries. The bar does NOT travel
          // between rows: React's indicator is a per-item `::after` with no
          // transform, so there is nothing to slide.
          //
          // The column is reserved whether or not it paints, so moving the
          // selection does not shift every label sideways. fluentLerpColor
          // moves alpha only when one endpoint is fully transparent, so the
          // bar fades up without dragging through a darker blue.
          child: indicatorColor == null
              ? null
              : FluentAnimatedStyle<Color>(
                  value: state.selected
                      ? indicatorColor
                      : indicatorColor.withAlpha(0),
                  spec: fluentNavSurfaceMotion,
                  lerp: fluentLerpColor,
                  builder: (context, color) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius:
                          style.indicatorRadius?.resolve(states) ??
                          FluentRadius.allSmall,
                    ),
                  ),
                ),
```

`withAlpha(0)` is not a computed colour in the prohibited sense — it is the CSS `transparent` endpoint of the same keyframe, and `fluentLerpColor` exists precisely to interpolate it. Say so in the comment if a reviewer queries it.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/fluent_2_web && flutter test test/navigation/nav_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/alisinancobani/IdeaProjects/flutent_2_web
git add packages/fluent_2_web/lib/src/navigation/nav.dart packages/fluent_2_web/test/navigation/nav_test.dart
git commit -m "fix(web): the nav indicator fades in, matching upstream's keyframe"
```

---

## Task 9: TabList — remove the one-frame flash

**Files:**
- Modify: `packages/fluent_2_web/lib/src/navigation/tab_list.dart:983-1006`
- Test: `packages/fluent_2_web/test/navigation/tab_list_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: nothing new. `buildFluentTab`'s signature is unchanged.

There is **no vertical-orientation defect** — the flip is wired for both axes and measured correct. The real bug is that `_scheduleFlip` measures the outgoing rect inside `addPostFrameCallback`, so the indicator paints once at its new position before the flip starts.

- [ ] **Step 1: Write the failing test**

Append to `packages/fluent_2_web/test/navigation/tab_list_test.dart` inside `main()`:

```dart
  testWidgets('the indicator does not flash at the new tab before flipping', (
    tester,
  ) async {
    Widget list({required String selected}) => FluentApp(
      home: Center(
        child: FluentTabList<String>(
          selectedValue: selected,
          onSelect: (_) {},
          tabs: <FluentTab<String>>[
            const FluentTab<String>(value: 'a', child: Text('aaaa')),
            const FluentTab<String>(value: 'b', child: Text('bbbbbbbb')),
          ],
        ),
      ),
    );

    await tester.pumpWidget(list(selected: 'a'));
    await tester.pumpAndSettle();
    final from = tester.getRect(find.text('aaaa'));

    await tester.pumpWidget(list(selected: 'b'));
    // Exactly one frame. The flip must already be applied — no frame may show
    // the bar sitting under 'b' at full size.
    await tester.pump();

    final transform = tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(FluentTabList<String>),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(
      transform.transform.getTranslation().x,
      isNot(0),
      reason: 'the outgoing offset must be applied on the first frame',
    );
    expect(from.left, isNotNull);
    await tester.pumpAndSettle();
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd packages/fluent_2_web && flutter test test/navigation/tab_list_test.dart --plain-name 'does not flash'`
Expected: FAIL — translation is 0 on the first frame.

- [ ] **Step 3: Implement**

In `_scheduleFlip`, measure the incoming rect synchronously instead of deferring:

```dart
  void _scheduleFlip((double, double) outgoing, T to) {
    // Upstream clamps the transition to 0.01ms under prefers-reduced-motion,
    // which is a jump. Not starting the controller at all is the same picture
    // with no frame scheduled.
    if (_reducedMotion) return;
    // Measured synchronously: deferring to addPostFrameCallback let one frame
    // paint the bar already at its destination, which reads as a flash before
    // the flip runs.
    final incoming = _extentOf(to);
    if (incoming == null) return;
    final inset = _indicatorInset;
    final fromLength = outgoing.$2 - 2 * inset;
    final toLength = incoming.$2 - 2 * inset;
    if (fromLength <= 0 || toLength <= 0) return;
    _flip = _TabFlip(
      value: to,
      animation: _flipAnimation,
      translation: outgoing.$1 - incoming.$1,
      scale: fromLength / toLength,
    );
    _controller.forward(from: 0);
  }
```

`_scheduleFlip` is called from `didUpdateWidget`, so assigning `_flip` without `setState` is correct — a rebuild is already in flight. If `_extentOf(to)` returns null because the incoming tab has not been laid out yet, the early return leaves the indicator unanimated, which is the pre-existing behaviour for that case.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/fluent_2_web && flutter test test/navigation/tab_list_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/alisinancobani/IdeaProjects/flutent_2_web
git add packages/fluent_2_web/lib/src/navigation/tab_list.dart packages/fluent_2_web/test/navigation/tab_list_test.dart
git commit -m "fix(web): the tab indicator no longer flashes before flipping"
```

---

## Task 10: Menu — content sizing and the 138 floor

**Files:**
- Modify: `packages/fluent_2_web/lib/src/overlays/menu_style.dart`
- Modify: `packages/fluent_2_web/lib/src/overlays/menu.dart:107-129, 148-186`
- Test: `packages/fluent_2_web/test/overlays/menu_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `FluentMenuStyle.minWidth` → `WidgetStateProperty<double?>?`.

`useMenuPopoverStyles.styles.ts` sets `width: 'max-content'`, `minWidth: '138px'`, `maxWidth: '300px'`. Ours is unconditionally 300: the surface sits in `Positioned(left: 0, top: 0)` inside a `Stack`, which supplies **loose** constraints, the `ConstrainedBox` caps them at 300, and `CrossAxisAlignment.stretch` makes the Column fill that maximum.

`stretch` must stay — rows need to fill the surface so hover fills span it. `IntrinsicWidth` sets the cross-axis size from the widest child and lets `stretch` fill *that* instead of the incoming maximum.

- [ ] **Step 1: Write the failing test**

Append to `packages/fluent_2_web/test/overlays/menu_test.dart` inside `main()`:

```dart
  group('surface width', () {
    Future<double> widthOf(WidgetTester tester, List<String> labels) async {
      await tester.pumpWidget(
        FluentApp(
          home: Center(
            child: FluentMenu(
              trigger: const FluentButton(child: Text('Open')),
              items: <FluentMenuItemData>[
                for (final l in labels)
                  FluentMenuItemData(label: Text(l), onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return tester.getSize(find.byType(FluentMenuSurface)).width;
    }

    testWidgets('short labels do not stretch the surface to the cap', (
      tester,
    ) async {
      expect(await widthOf(tester, <String>['Grid', 'Rulers']), lessThan(300));
    });

    testWidgets('the surface never renders narrower than 138', (tester) async {
      expect(
        await widthOf(tester, <String>['A']),
        greaterThanOrEqualTo(138),
      );
    });

    testWidgets('a very long label is capped at 300', (tester) async {
      expect(
        await widthOf(tester, <String>['A label far longer than three '
            'hundred logical pixels could ever hope to be, and then some']),
        300,
      );
    });
  });
```

Replace `FluentMenuSurface` with whatever `buildFluentMenu` returns as its outermost identifiable widget — if there is no such type, key the `ConstrainedBox` in Step 3 and find it by key.

- [ ] **Step 2: Run them to verify they fail**

Run: `cd packages/fluent_2_web && flutter test test/overlays/menu_test.dart --plain-name 'surface width'`
Expected: FAIL — the first returns 300.

- [ ] **Step 3: Add `minWidth` to the style**

In `menu_style.dart`, add the field beside `maxWidth`, wiring it through the constructor, `merge`, `copyWith`, `from`, `==` and `hashCode` exactly as `maxWidth` is:

```dart
  /// The surface's minimum width.
  ///
  /// `useMenuPopoverStyles.styles.ts` states `minWidth: '138px'`; a menu never
  /// renders narrower than that however short its rows are.
  final WidgetStateProperty<double?>? minWidth;
```

- [ ] **Step 4: Default it and apply it**

In `menu.dart`'s `resolveFluentMenuStyle`, beside the existing `maxWidth: const WidgetStatePropertyAll<double?>(300)`:

```dart
    minWidth: const WidgetStatePropertyAll<double?>(138),
```

and update the doc comment at `:107` that currently mentions only `maxWidth: '300px'` to state the full rule: `width: max-content` clamped to `[138, 300]`.

In `buildFluentMenu`, read it and rebuild the constraint chain:

```dart
  final minWidth = style.minWidth?.resolve(states) ?? 0;
  final maxWidth = style.maxWidth?.resolve(states) ?? double.infinity;
  final maxHeight = style.maxHeight?.resolve(states) ?? double.infinity;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.xxs;

  return ConstrainedBox(
    constraints: BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    ),
    child: DecoratedBox(
      // ...unchanged...
      child: Padding(
        padding: style.padding?.resolve(states) ?? EdgeInsets.zero,
        // The surface is `width: max-content` upstream, not trigger-matched
        // and not stretched to the cap. The overlay hands this subtree LOOSE
        // constraints, so without IntrinsicWidth the CrossAxisAlignment.stretch
        // below would fill the whole 300 whatever the rows measure.
        // IntrinsicWidth sizes the column to its widest row and lets `stretch`
        // fill that, which is what keeps hover fills spanning the surface.
        child: IntrinsicWidth(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: gap,
              children: state.children,
            ),
          ),
        ),
      ),
    ),
  );
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `cd packages/fluent_2_web && flutter test test/overlays/menu_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
cd /Users/alisinancobani/IdeaProjects/flutent_2_web
git add packages/fluent_2_web/lib/src/overlays/menu.dart packages/fluent_2_web/lib/src/overlays/menu_style.dart packages/fluent_2_web/test/overlays/menu_test.dart
git commit -m "fix(web): the menu surface sizes to its content, clamped 138..300"
```

---

## Task 11: TagPicker popup — the 160 floor

**Files:**
- Modify: `packages/fluent_2_web/lib/src/inputs/tag_picker.dart:1105-1106`
- Test: `packages/fluent_2_web/test/inputs/tag_picker_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: nothing new.

`useTagPicker.ts` passes `matchTargetSize: 'width'` and the popup renders a `Listbox`, whose `useListboxStyles` carries `minWidth: '160px'`. Ours is trigger-matched with no floor. This mirrors `dropdown.dart`, which already has it.

- [ ] **Step 1: Write the failing test**

```dart
  testWidgets('the popup never renders narrower than 160', (tester) async {
    await tester.pumpWidget(
      FluentApp(
        home: Center(
          child: SizedBox(
            width: 80,
            child: FluentTagPicker(
              options: const <String>['One'],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FluentTagPicker));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.text('One')).width,
      greaterThan(0),
    );
    final popup = tester.getSize(
      find.ancestor(
        of: find.text('One'),
        matching: find.byType(ConstrainedBox),
      ).first,
    );
    expect(popup.width, greaterThanOrEqualTo(160));
  });
```

Adjust the constructor to the real `FluentTagPicker` API.

- [ ] **Step 2: Run it to verify it fails**

Run: `cd packages/fluent_2_web && flutter test test/inputs/tag_picker_test.dart --plain-name 'narrower than 160'`
Expected: FAIL — width is 80.

- [ ] **Step 3: Implement**

Wrap the existing `SizedBox` in `_buildPopup`:

```dart
            // `useListboxStyles` floors the popup at 160 even when
            // `matchTargetSize: 'width'` hands it a narrower trigger — the
            // same pairing dropdown.dart already carries.
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 160),
              child: SizedBox(
                width: _link.leaderSize?.width,
                // ...unchanged...
              ),
            ),
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/fluent_2_web && flutter test test/inputs/tag_picker_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/alisinancobani/IdeaProjects/flutent_2_web
git add packages/fluent_2_web/lib/src/inputs/tag_picker.dart packages/fluent_2_web/test/inputs/tag_picker_test.dart
git commit -m "fix(web): the tag picker popup floors at 160 like the listbox"
```

---

## Task 12: Viewport-derived popup max height

**Files:**
- Modify: `packages/fluent_2_web/lib/src/overlays/menu.dart` (`maxHeight` default and use)
- Modify: `packages/fluent_2_web/lib/src/inputs/dropdown.dart:357` (`surfaceMaxHeight`) and its popup builder
- Test: `packages/fluent_2_web/test/overlays/menu_test.dart`, `test/inputs/dropdown_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: nothing new. Both style properties keep their types and remain the caller's override hook.

React's positioning layer writes the cap inline from the free space below the anchor on every reposition — measured 680 / 380 / 880 at viewport heights 800 / 500 / 1000. Ours is a hard-coded 300 in both.

- [ ] **Step 1: Write the failing test**

```dart
  testWidgets('the popup grows with the viewport instead of stopping at 300', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      FluentApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: FluentMenu(
            trigger: const FluentButton(child: Text('Open')),
            items: <FluentMenuItemData>[
              for (var i = 0; i < 40; i++)
                FluentMenuItemData(label: Text('Item $i'), onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(FluentMenuSurface)).height,
      greaterThan(300),
      reason: 'a 2000px viewport has far more than 300px below the trigger',
    );
  });
```

- [ ] **Step 2: Run it to verify it fails**

Run: `cd packages/fluent_2_web && flutter test test/overlays/menu_test.dart --plain-name 'grows with the viewport'`
Expected: FAIL — height is exactly 300.

- [ ] **Step 3: Implement**

Default both properties to `null` and resolve the fallback from the viewport at build time, inside the widget that has the anchor's position. In each popup builder, replace the fixed fallback with:

```dart
    // Upstream's positioning layer writes `max-height` inline from the space
    // left below the anchor, recomputed on every reposition. The style
    // property stays as the caller's override; this is only the default.
    final anchorBottom =
        (_link.leader?.offset.dy ?? 0) + (_link.leaderSize?.height ?? 0);
    final available = MediaQuery.sizeOf(context).height - anchorBottom - offset;
    final maxHeight =
        style.maxHeight?.resolve(states) ?? math.max(available, 0);
```

Change `resolveFluentMenuStyle`'s `maxHeight` and `resolveFluentDropdownStyle`'s `surfaceMaxHeight` defaults from `300` to `null`, and update the comments that justified the 300 to state the new rule.

Add `import 'dart:math' as math;` where absent.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `cd packages/fluent_2_web && flutter test test/overlays/menu_test.dart test/inputs/dropdown_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/alisinancobani/IdeaProjects/flutent_2_web
git add packages/fluent_2_web/lib/src/overlays/menu.dart packages/fluent_2_web/lib/src/inputs/dropdown.dart packages/fluent_2_web/test/overlays/menu_test.dart packages/fluent_2_web/test/inputs/dropdown_test.dart
git commit -m "fix(web): popup height follows the viewport, not a fixed 300"
```

---

## Task 13: Regenerate goldens, update the divergence record, verify

**Files:**
- Modify: `packages/fluent_2_web/test/goldens/goldens/*.png`
- Modify: `doc/token-divergences.md`

**Interfaces:**
- Consumes: every preceding task.
- Produces: a green `melos run ci`.

- [ ] **Step 1: Confirm only goldens are failing**

Run: `cd packages/fluent_2_web && flutter test 2>&1 | grep -oE "test/[a-z_/]+\.dart: .*\[E\]" | sort -u`
Expected: every line begins `test/goldens/`. If anything else fails, fix it before regenerating — regenerating hides real regressions behind intended ones.

- [ ] **Step 2: Regenerate**

```bash
cd /Users/alisinancobani/IdeaProjects/flutent_2_web/packages/fluent_2_web
flutter test --update-goldens test/goldens/
rm -rf test/goldens/failures && git checkout -- test/goldens/failures/ 2>/dev/null || true
```

- [ ] **Step 3: Review each changed golden**

Run: `cd /Users/alisinancobani/IdeaProjects/flutent_2_web && git status --short packages/fluent_2_web/test/goldens/goldens/`

For each, state in one line why it changed. Any golden changing for a reason not traceable to a task in this plan is a bug — investigate before continuing.

- [ ] **Step 4: Record the divergences**

Append to `doc/token-divergences.md` a section covering: focus-visible modality (React uses keyborg, not `:focus-visible`; Flutter's highlight mode cannot express it), the focus-underline `max(thickness, radius)` + clip technique, and the popup sizing taxonomy from the spec's §6 — including the three explicit non-goals (no `minWidth` on Tooltip, no trigger-matching on Popover or Menu).

- [ ] **Step 5: Full CI**

```bash
cd /Users/alisinancobani/IdeaProjects/flutent_2_web && melos run ci
```

Expected: analyze clean on all four packages, format clean, no-material clean, all tests pass. Test count should be **above 1920** — this plan adds roughly 20 tests and removes none.

- [ ] **Step 6: Verify the gallery still builds**

```bash
cd /Users/alisinancobani/IdeaProjects/flutent_2_web/packages/fluent_2_web/example && flutter build web --no-tree-shake-icons
```

Expected: `✓ Built build/web`.

- [ ] **Step 7: Commit**

```bash
cd /Users/alisinancobani/IdeaProjects/flutent_2_web
git add packages/fluent_2_web/test/goldens doc/token-divergences.md
git commit -m "test(web): regenerate goldens; record the new divergences"
```

---

## Self-review notes

**Spec coverage.** §1 modality → Tasks 1–4. §2 underline → Tasks 5, 7. §3 SearchBox → Task 6. §4 Nav → Task 8. §5 TabList flash → Task 9. §6 popup sizing → Tasks 10–12 (Tooltip and Popover are explicit no-change; TeachingPopover's fixed-288-vs-320 is **deliberately out of scope** — it is entangled with the button width-floor decision recorded in `button.dart`'s `minimumSize` comment and should be taken as one change with it).

**Ordering.** Task 6 precedes Task 7 because both edit the same SearchBox block. Task 5 precedes Task 7 because the migration targets the fixed primitive. Tasks 2–4 all depend on Task 1.

**Known risk carried into execution.** Task 2 changes the meaning of `WidgetState.focused` for every consumer; its Step 5 audit is the gate. If a consumer genuinely needs pointer focus, stop and raise it rather than working around it — that would mean the spec's chosen option was wrong and the second option (a separate `focusVisible` signal) should be reconsidered.
