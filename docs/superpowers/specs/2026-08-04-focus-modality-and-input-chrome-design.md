# Design — input modality, input chrome, and nav motion

**Date:** 2026-08-04
**Status:** approved (two open decisions resolved; popup sizing pending a separate investigation)
**Scope:** `packages/fluent_2_web`

Five reported fidelity defects, root-caused against Fluent UI React v9 by live
probe and source read. Three of the five reports were mis-attributed; the real
defects are recorded here, not the reported symptoms.

## Summary of findings

| Reported | Actual root cause | Verdict |
|---|---|---|
| Ring on a menu item and on a tab that React does not show | **Two independent producers** of `WidgetState.focused`, neither gated on input modality | real, and bigger than reported |
| Dropdown focus underline "not curving" | Skia clamps a 4px corner radius on a 2px-tall box to 2px | real, different mechanism than assumed |
| SearchBox missing an appearance variant | No variant is missing. A `ConstrainedBox` outside a `Stack` collapses the box to 20px, orphaning the focus bar 12px below it | real, misdiagnosed |
| Nav indicator should slide between items | React's indicator is a per-item `::after` and **cannot** travel. We do drop the 100 ms fade it has | premise wrong, smaller real defect behind it |
| Vertical TabList indicator does not animate | **Not reproduced.** Vertical and horizontal already share one code path | no defect; a separate one-frame flash exists |

---

## 1. Input modality — the only new primitive

### The mechanism React actually uses

Not CSS `:focus-visible`. `react-tabster`'s `focusVisiblePolyfill.ts` delegates to
**keyborg**, which maintains one global "navigating with keyboard" flag per window:

- `keydown` → `true` (Tab always; other keys unless the target is an input/textarea/contentEditable)
- `mousedown` with real coordinates, `touchstart`, `touchend`, `touchcancel` → `false`

Focus-visible is a **live AND** of *(element has focus)* × *(flag)*, re-evaluated when
the flag flips even if focus has not moved.

**Decisive probe.** Keyboard-open a menu, `ArrowDown` twice, then *mouse-hover* a
different item: React still draws the ring, because hover does not clear the flag —
only `mousedown`/touch does. A per-widget "suppress on pointer-down" scheme cannot
reproduce this. The flag must be global.

### Why Flutter gets it wrong today

`FocusManager`'s highlight mode is **touch vs not-touch**, not keyboard vs pointer.
`_HighlightModeManager.handlePointerEvent` maps `mouse | trackpad | unknown` to
`_lastInteractionWasTouch = false` → `FocusHighlightMode.traditional` — the identical
value a key press produces. So `FocusableActionDetector.onShowFocusHighlight` fires for
mouse-originated focus on web and desktop.

### Two producers, not one

**Producer A — `FluentInteractive`.** `lib/src/internal/interaction.dart:169` raises
`WidgetState.focused` from `onShowFocusHighlight`. Affects tab, button, checkbox,
radio, switch, slider, card, accordion, tree, list item, and every other consumer.

`tab_list.dart:1008` calls `requestFocus()` on pointer selection, so clicking a tab
focuses it, the mode is already `traditional`, and the ring paints. The comment at
`tab_list.dart:1131` ("focus arriving by pointer never raises `WidgetState.focused`")
is false on web and desktop and must be corrected.

**Producer B — synthesised active-descendant state.** Menu rows are deliberately
outside the traversal order and wrapped in `ExcludeFocus` (`menu.dart:805`, `:837`), so
Producer A never fires for them. Instead `menu.dart:815` synthesises the state
unconditionally:

```dart
if (level.active == index) WidgetState.focused,
```

and `level.active` is set by **hover** (`menu.dart:799` `onEnter` → `:569`). It is also
`0` on open. So the menu ring means "active row", with no modality gate whatsoever.

Three siblings share Producer B verbatim: `dropdown.dart:1016`,
`breadcrumb.dart:1050`, `tag_picker.dart:1184`.

React separates these two ideas explicitly: the dropdown option carries
`data-activedescendant` when it is merely active, and gains
`data-activedescendant-focusvisible` only under keyboard — and rings only then.

### Design

Add `lib/src/internal/input_modality.dart`:

```dart
/// Whether the user is currently navigating with the keyboard.
///
/// The Dart counterpart of keyborg, which `react-tabster` uses to implement
/// focus-visible. Flutter's own `FocusHighlightMode` cannot serve: it
/// distinguishes touch from not-touch, so a mouse click resolves to
/// `traditional` exactly as a key press does.
abstract final class FluentInputModality {
  /// True while the last input was a key rather than a pointer.
  static ValueListenable<bool> get keyboard;
}
```

Backed by one lazily-installed listener pair — `GestureBinding.instance.pointerRouter`
for `PointerDownEvent` (→ false) and `HardwareKeyboard.instance` for key down
(→ true) — holding a single `ValueNotifier<bool>`.

Both producers then AND their focus signal with `FluentInputModality.keyboard`:

- Producer A: in `FluentInteractive`, gate the `WidgetState.focused` update.
- Producer B: at each of the four synthesis sites.

Because the notifier is a `ValueListenable`, a widget that is already focused
rebuilds when the flag flips — reproducing keyborg's live re-evaluation.

Two points that would otherwise be ambiguous:

- **How each producer observes it.** Producer A already owns a
  `WidgetStatesController`, so `FluentInteractive` subscribes in `initState` and
  re-runs its `focused` update when the flag changes. Producer B's four sites build
  a `Set<WidgetState>` inline during `build`, so each wraps the affected subtree in a
  `ValueListenableBuilder<bool>` rather than reading the value once. Reading it
  without listening is the failure mode that would pass a naive test and still not
  re-evaluate — the test above is written specifically to catch it.
- **Tests that inject state directly are unaffected.** The fixture-driven tests call
  `buildFluentX(state, style, {WidgetState.focused})` and never go through either
  producer, so they keep asserting the *rendering* of a focused control. Only tests
  that drive real focus need revisiting. This is deliberate: the gate belongs to state
  resolution, not to rendering, which keeps `buildFluentX` a pure function of its
  inputs and preserves the three-function recomposition contract.

**Decision taken:** `WidgetState.focused` itself becomes keyboard-only across the
design system, rather than adding a second parallel concept. The doc comment at
`interaction.dart:161` already claims this meaning; the change makes it true.

**Also folded in:** `toaster.dart:655` and `tooltip.dart:474` hand-roll
`mode == FocusHighlightMode.traditional`. Both are the same bug and both move onto
the primitive.

### Test strategy

A widget test that focuses via `tester.tap` and asserts no ring, then sends a key
event and asserts the ring appears **without focus moving** — that last part is what
proves the live re-evaluation rather than a one-shot check. Make each fail first.

---

## 2. Focus underline — shape

`dropdown.dart:468` paints the accent as a 2px-tall box carrying a 4px bottom radius.
Skia's `SkRRect` scales every radius by `min(edge / sum-of-radii-on-that-edge)` =
`2 / 4` = 0.5, so the shipped radius is **2, not 4**, and half of that is consumed by
the bar's own height. The ends read square.

React hits the identical CSS clamp and works around it deliberately
(`useDropdownStyles.styles.ts:45`): make the `::after` **4px tall**
(`height: max(strokeWidthThick, borderRadiusMedium)`), put the radii on its bottom
corners, then trim back to 2px with `clipPath: inset(calc(100% - 2px) 0 0 0)`. The
source comment says why: *"Otherwise the radius would be automatically reduced to fit
available space."*

### Design

Fix inside the existing primitive `FluentInputFocusUnderline` (`input.dart:623`),
which gains a `thickness` parameter (default `FluentStroke.thick`):

```dart
ClipRect(
  child: OverflowBox(
    alignment: Alignment.bottomCenter,
    maxHeight: math.max(thickness, radius),
    child: DecoratedBox(...bottom-only borderRadius...),
  ),
)
```

The parent `Positioned(height: thickness)` keeps the layout slot at 2; `OverflowBox`
lets the painted rect be 4 tall so the radius survives; `ClipRect` trims the top. Three
stock widgets — no painter, no `RenderObject`.

**Decision taken:** migrate all copies. Dropdown, SearchBox, SpinButton and Textarea
each hand-roll the same stack and move onto the primitive; Input and TagPicker already
use it. Six components, one shape.

---

## 3. SearchBox — layout, not a variant

`search_box.dart:461` puts the `ConstrainedBox(minHeight:)` **outside** the `Stack`.
`RenderStack` lays non-positioned children out with `StackFit.loose`, which drops
`minHeight` to 0. The surface then sizes to its content — `max(icon 20, body1 line
height 20)` = 20 — and its padding is horizontal-only, so nothing else supplies
height. Both `Positioned(bottom: 0)` overlays land ~12px **below** the bordered box.
That detached 1px line is the reported "stray rule".

`input.dart:565` already does this correctly, with the `ConstrainedBox` inside the
`Stack`. Adopt that arrangement verbatim. No token, style class or public API moves.

No appearance variant is missing; that part of the report is withdrawn.

---

## 4. Nav indicator — fade, not travel

React's Nav indicator is a per-item `::after` absolutely positioned inside its own
row (`sharedNavStyles.styles.ts:87`). It has no `transform`, no offset/scale custom
properties and no previous-rect registration — it **cannot** move between rows. Probed
live: `transform: none`, `transitionDuration: 0s`.

What it does have is a 100 ms linear `background` keyframe, and we drop it:
`nav.dart:488` swaps the bar in as a boolean, so it appears at full alpha on the first
frame after selection.

**Decision taken:** match React — fade only, no travelling bar.

Reuse what exists: `FluentAnimatedStyle<Color>` + `fluentLerpColor` +
`fluentNavSurfaceMotion` (already `FluentDuration.faster` / `FluentCurve.linear`,
bit-for-bit the upstream tokens). `fluentLerpColor` already implements the
"one endpoint fully transparent, move alpha only" behaviour a CSS
`transparent → brand` keyframe has, so the bar fades up without dragging through
darker blues.

One edit at `nav.dart:488`, inside the single shared row builder — it covers
`FluentNavItem`, `FluentNavCategoryItem`, `FluentNavSubItem` and the category →
sub-item delegation.

Reduced motion is inherited: `FluentAnimatedStyle` already collapses under
`MediaQuery.disableAnimationsOf`.

---

## 5. Vertical TabList — no defect

The flip is wired for both orientations. `tab_list.dart:551` writes
`setEntry(0,0)/(0,3)` for horizontal and `setEntry(1,1)/(1,3)` for vertical; the
vertical arm is not a no-op. `_extentOf` (`:961`) branches `dx/width` vs `dy/height`.
One `AnimationController`, one `_scheduleFlip`, both orientation-free. The recent
`IntrinsicWidth` + `CrossAxisAlignment.stretch` change constrains the cross axis while
the flip runs on the main axis, so they do not interact. Measured: the vertical bar
held 3px wide × 16px tall for every frame.

No shared "sliding indicator" primitive: TabList is the only consumer, and Nav is now
explicitly not one. Extracting one would be a speculative abstraction.

**One real bug worth fixing while here:** `_scheduleFlip` measures the outgoing rect in
an `addPostFrameCallback` (`tab_list.dart:988`), which yields a one-frame flash. Measure
both rects synchronously instead.

---

## Testing

Every change gets a test that fails first. Specifically:

- modality: tap → no ring; key → ring, focus unmoved
- underline: assert the painted rect is `max(thickness, radius)` tall and clipped to
  `thickness`, and that the bottom radius survives at 4
- SearchBox: assert the decorated box's height equals `minimumSize.height` at all three
  sizes, and that the rule's bottom edge coincides with the box's
- Nav: pump mid-transition and assert an intermediate alpha, plus a reduced-motion case
  that lands on frame one
- TabList flash: assert the indicator's rect on the first frame after selection

Goldens are regenerated centrally at the end, never by parallel agents.

## Risks

- **Blast radius of the modality change.** Every resolver branching on
  `WidgetState.focused` changes meaning. The counted consumers must be reviewed for any
  that genuinely wanted "focused by any means".
- **Touch.** Keyborg treats touch as *not* keyboard. The Dart primitive must too, or
  touch devices grow rings they should not have.
- **Underline migration** touches six components; the shape change is visible in
  goldens for all of them.

## 6. Popup sizing

React gives each overlay surface a **different** sizing rule. Conflating them is the
bug; there is no single "popup width" to fix.

| Surface | React rule | Ours | Action |
|---|---|---|---|
| **Menu / submenu** | content-sized, clamped `[138, 300]` | **fixed 300, always** | **fix — causes the report** |
| Dropdown / Combobox listbox | trigger-matched, floor 160, height = free space | width correct; height fixed 300 | fix height |
| TagPicker popup | trigger-matched, floor 160 | trigger-matched, **no floor** | add floor |
| Tooltip | content-sized, fixed 240 cap | identical | **no change** |
| Popover | content-sized, no max | identical | **no change** |
| TeachingPopover | `min-width: 320`, grows | fixed `SizedBox(288)` | see §4 note below |

### The reported defect — Menu

Two independent causes in `buildFluentMenu` (`menu.dart:148`):

1. `CrossAxisAlignment.stretch` (`menu.dart:180`) makes the Column consume the whole
   incoming `maxWidth`. The surface sits in `Positioned(left: 0, top: 0)` inside a
   `Stack`, which supplies **loose** constraints (0 → overlay width), so the
   `ConstrainedBox` at `:160` caps them at 300 and the Column fills it.
2. No 138 floor exists at all.

Net: our menu is unconditionally 300 wide regardless of its content, which is exactly
the screenshot.

**Fix.** Size to content and clamp:

- add `minWidth` to `FluentMenuStyle` beside the existing `maxWidth` (const / merge /
  copyWith / from / `==` / `hashCode`), defaulting to 138 so it stays overridable;
- give the `ConstrainedBox` `minWidth` as well as `maxWidth`;
- make the surface content-sized. `CrossAxisAlignment.stretch` must stay — rows need
  to fill the surface so hover fills span it — so wrap the Column in `IntrinsicWidth`,
  which sets the cross-axis size from the widest child and lets `stretch` fill *that*
  rather than the incoming maximum. Same shape as the vertical-TabList fix.

### Height

Dropdown's `surfaceMaxHeight` and Menu's `maxHeight` are both a hard-coded 300 where
React writes the free space below the anchor inline on every reposition (measured 680 /
380 / 880 at viewport heights 800 / 500 / 1000). Derive it from
`MediaQuery.sizeOf(context).height` minus the anchor's bottom, keeping the existing
property as the caller's override hook.

### Explicit non-goals

Recorded because they are the tempting over-corrections:

- **Do not** put a `minWidth` on Tooltip — it is content-sized with a cap and nothing
  else, and a floor would visibly widen short tips.
- **Do not** make Popover trigger-matched. It has no width rule upstream at all.
- **Do not** make Menu trigger-matched. `usePopoverContext` never passes
  `matchTargetSize`; that flag belongs to the combobox positioning hook only.
