## Unreleased

### Added

- **`FluentBoxDecoration` paints `boxShadow` the way CSS does — outside the box
  only.** A `BoxDecoration` shadow is a blurred copy of the box drawn *under*
  it, which a transparent box shows as a grey wash (`shadow16` darkens the
  inside to about 76%). Upstream shadows unfilled elements routinely, so this is
  the decoration for them; the blur also uses CSS's σ = blur / 2. Everything
  else paints as `BoxDecoration`. The CarouselNav and Carousel demos use it,
  which is what stopped the CarouselNav card rendering solid grey.

### Fixed

- **A `FluentTooltip` near the edge of the window was drawn outside it.** The
  surface always sat on the side `position` named (`above` by default) and was
  centred on its trigger with no bounds check, so a tooltip on a bar at the
  top of the window landed above the window entirely, and one on a bar's
  end button ran off the side. Upstream's tooltip never pins its placement,
  so `usePositioning` applies floating-ui's `flip` and `shift` to it: the
  surface now flips to the opposite side when the preferred one cannot hold it
  and the opposite one has more room (`before`/`after` in reading order), and
  slides along the trigger's edge to stay inside the `Overlay`. The arrow is
  drawn for the side the surface landed on and stays centred on the trigger,
  8px clear of the surface's corners, the way floating-ui's `arrow` middleware
  places it. With room on every side nothing moves. It is settled in one
  layout pass — no frame shows the surface on the wrong side, and nothing is
  scheduled while it is open — and the surface still follows a trigger that
  moves.

### Changed

- **`FluentTooltip.position` is now a preference.** A tooltip with no room on
  that side opens on the opposite one; see the Positioning section of
  `FluentTooltip`. `buildFluentTooltip` is unchanged and still stacks the
  arrow on exactly the side its state names.

## 0.0.5

### Fixed

- **Selected text stayed highlighted after clicking away from a field.** Flutter
  hides a selection in exactly one way — by handing `EditableText` a null
  `selectionColor`. Blur does none of the work itself: `_handleFocusChanged`
  leaves `controller.selection` alone and `RenderEditable`'s highlight painter
  draws from (range, colour) with no focus term, so a control that keeps passing
  a colour keeps painting the selection after the pointer has gone elsewhere.
  Focus was dropping correctly all along; only the paint outlived it.
  `FluentInput` (and so `FluentDatePicker`, `FluentTimePicker` and
  `FluentTagPicker`, which share `buildFluentInput`), `FluentTextarea` and
  `FluentSearchBox` now gate the colour on real focus, the way `TextField` and
  `CupertinoTextField` both do and `FluentSpinButton` already did.
  `FluentSearchBox` had a guard on `enabled && !readOnly`, which is true for an
  ordinary field's whole lifetime — it read as a gate in a diff and did nothing
  at runtime; both terms are now applied.
- **Pressing a field's own chrome dropped its focus.** The padding, the border
  and the `contentBefore`/`contentAfter` slots are built *around* the
  `EditableText`, so they fall outside the `TextFieldTapRegion` it installs for
  itself and a pointer-down there ran `_EditableTextTapOutsideAction`. The
  selection gesture detector handed focus back on pointer-up, so it read as a
  flicker rather than a fault — but a focus-reactive slot unmounts under the
  cursor between press and release, and a spin button's steppers are outside
  the field too, so every increment blurred it. `buildFluentInput`,
  `FluentTextarea`, `FluentSearchBox` and `FluentSpinButton` now each wrap their
  faceplate, as `TextField` wraps its decoration. All use the default group id,
  so the pickers wrapping the result again for their popups stays a no-op.

### Changed

- **Blurring a Fluent text control now collapses its selection**, rather than
  only hiding the highlight. Material and Cupertino keep the range and restore
  it on refocus; these controls deliberately do not, so returning to a field
  lands a caret where the selection ended. The value is never touched — only
  `controller.selection` — but an application that reads a selection back from
  its own controller after the field has lost focus will now find it collapsed.
- **`collapseFluentSelectionOnBlur` is new.** An internal helper in
  `lib/src/internal/text_selection_dismiss.dart`, called from the focus listener
  each control already owned. It writes as little as it can: nothing while
  focused, nothing for an invalid or already-collapsed range, and it clamps the
  caret to the current text — `TextEditingController.selection`'s setter throws
  rather than asserts past `text.length`, so that guard holds in release too.
  `FluentDatePicker` and `FluentTimePicker` key it to focus leaving the *whole
  control*, not just the field, so an open calendar or listbox keeps its range.

## 0.0.4

### Fixed

- **A popup opened from inside a `FluentPopover` collapsed the popover on the
  first click.** Every popup light-dismisses through a `TapRegion` group; the
  seven non-popover popups hardcoded `groupId: this` and inflated their surface
  into a sibling `OverlayEntry`, so a pointer-down on the popup carried none of
  the popover's regions and its `onTapOutside` fired on the down, tearing down
  the subtree the popup lived in. This broke five controls in popover-hosted
  panels: the column and operator dropdowns, the value tag picker, and the date
  and time pickers. Popups now adopt the enclosing chain's group around their
  own via `adoptFluentTapGroup` — a click on the popup is inside both, a click
  on the host's surface closes just the popup, and a click outside closes both.
  Placement and caching are documented at each call site; the wrapper must sit
  inside the `CompositedTransformFollower` and the group must be read at the
  trigger's context, both of which fail silently if wrong.

### Changed

- **`adoptFluentTapGroup` is new.** An internal helper in
  `lib/src/internal/tap_group.dart` that wraps a popup surface in a second
  `TapRegion` carrying the enclosing chain's id. Returns the child untouched
  when there is no enclosing group.

## 0.0.3

### Changed

- **BREAKING: `FluentRadioGroupScope` no longer carries `value` or `onChanged`.**
  Selection now travels through the framework's `RadioGroup<T>` /
  `RadioGroupRegistry` instead, so the scope keeps only `disabled` and
  `labelPosition`. Code constructing or reading the scope directly breaks at
  compile time; code using `FluentRadioGroup` and `FluentRadio` is unaffected.
- **`FluentRadio<T>` is now a `StatefulWidget`.** Its constructor is unchanged,
  so ordinary callers are unaffected — only subclasses and `is StatelessWidget`
  checks break.
- **Two radios sharing one value in a group now assert.** The framework's
  `RadioGroupPolicy` rejects it (*"can't be used for a radio group that allows
  multiple selection"*) where it previously just painted two checked dots. That
  is a caller bug the framework is now diagnosing; suppressing it would mean not
  registering with the group at all.
- **A determinate `FluentProgressBar` announces `50`, not `50%`.** The role
  requires a parseable number: at the declared floor of Flutter 3.41 the
  framework's own `double.parse` throws a `FlutterError` on a trailing `%`
  (3.47 later relaxed this). The `progressBar` role plus the new
  `minValue`/`maxValue` is what makes a screen reader say "percent"; upstream
  Flutter's own `ProgressIndicator` emits a bare number for the same reason.
- **`FluentPopoverArrowPainter` takes a `textDirection`.** The painter drew a
  fixed physical apex while `buildFluentPopover` lays its arrow out with a
  direction-aware `Row`, so in an RTL subtree the arrow appeared on the wrong
  edge, pointing into its own surface. Pass `Directionality.of(context)`.
  Optional, defaulting to `TextDirection.ltr` — which is precisely the behaviour
  the painter had before the field existed, so this is **not** a breaking
  change and callers that omit it are unaffected.

### Fixed

- **Every popup swallowed the click, hover and scroll behind it.** All seven —
  `FluentPopover`, `FluentMenu`, `FluentDropdown`, `FluentTagPicker`,
  `FluentTimePicker`, `FluentDatePicker` and `FluentBreadcrumb`'s overflow —
  painted an opaque full-screen `Positioned.fill` barrier to catch outside taps.
  It caught everything else too: a button behind an open popup needed two
  clicks, hover never reached it, and the page could not be scrolled. Dismissal
  is now a `TapRegion` group, matching upstream's document-level
  `useOnClickOutside` — the click dismisses *and* lands. Two consequences worth
  knowing: a `TapRegionSurface` ancestor is required, which `WidgetsApp` (and so
  `FluentApp`) provides but a bare `Overlay` does not; and on touch or trackpad a
  drag-scroll now dismisses, because `RenderTapRegionSurface` does not take part
  in gesture disambiguation. Mouse wheel is unaffected.
- **A popover opened from inside another popover collapsed the chain.** The
  inner surface lives in its own `OverlayEntry`, so it fell outside the outer
  popover's tap group and merely opening it read as an outside tap. Nested
  popups now share one group via `FluentTapGroup`.
- **Closing a popover no longer steals focus** from the control an outside tap
  just landed on — it restores to the trigger only when the popover itself held
  focus, the rule `FluentDatePicker` already documented.
- **A `FluentSwitch` inside a `FluentField` rendered a stretched track.**
  With no label the switch's content was a bare `SizedBox.fromSize`, and
  `FluentField` lays its children out with `CrossAxisAlignment.stretch`
  (deliberately, matching upstream's `display: grid` root) — so a tight width
  constraint forced the 40x20 track to the full field width, measured at 584px
  on the Field page's component example. Upstream's switch root is
  `display: inline-flex` and never stretches, so the switch now always wraps in
  a `mainAxisSize: min` row, exactly as `FluentCheckbox` already did.
- **`FluentSwatchPicker` was N tab stops with dead arrow keys**, while telling
  assistive technology it was a mutually-exclusive group. It now has a roving
  tabindex: one tab stop, arrows move within it. The arrow model follows
  upstream's `useArrowNavigationGroup` — a row wraps on all four arrows; a grid
  steps Left/Right across row boundaries and wraps, moves Up/Down by row without
  wrapping, and Home/End reach the ends of the current row.
- **An open popup no longer keeps a stale height when the page scrolls under
  it.** `FluentDropdown`, `FluentTagPicker`, `FluentTimePicker`,
  `FluentDatePicker`, `FluentInfoButton`, `FluentBreadcrumb` and `FluentMenu`
  all cap their surface at the room left beside the anchor, and nothing
  re-measured it once open: the surface correctly followed its trigger up the
  viewport while keeping the height it was given near the bottom. They now
  re-measure on scroll, matching upstream's reposition-rather-than-close
  behaviour. Gated on `ScrollPosition.isScrollingNotifier`, so it re-measures at
  scroll start and stop rather than every frame.
- **`FluentRadioGroup` was N tab stops, not one.** A radio group is a single
  composite control: Tab enters it once and arrows move within it. It now adopts
  the framework's `RadioGroup`/`RadioClient`, which also fixes a group whose
  *selected* radio is disabled becoming entirely unreachable by Tab.
- **`FluentTabList` and `FluentList` were N tab stops each**, contradicting the
  `SemanticsRole.tab`/`tabBar` they already declared. Both now use the roving
  tabindex `FluentToolbar` already implemented.
- **Semantics roles.** `FluentDataGrid` now exposes `table`/`row`/`cell`/
  `columnHeader`; `FluentSpinner` `loadingSpinner`; `FluentPresenceBadge` and
  `FluentStatusIndicator` `status`; `FluentProgressBar` `progressBar` with a
  range. `FluentNav`, `FluentNavDrawer` and `FluentBreadcrumb` take the
  `navigation` landmark role **only when given a non-empty `semanticLabel`** —
  two unnamed landmarks on one page is a framework assertion, and an unnamed
  nav beside an unnamed breadcrumb is the ordinary case.
- **Text controls had no context menu at all.** `FluentTextSelectionControls`
  extended `TextSelectionControls` rather than mixing in
  `TextSelectionHandleControls`, so `TextSelectionOverlay.showToolbar` took the
  legacy `buildToolbar` path — which returned an empty widget — and never
  consulted `EditableText.contextMenuBuilder`. Right-click and long-press
  produced nothing on `FluentInput`, `FluentTextarea`, `FluentSearchBox` and
  `FluentSpinButton`.
- **A subtree `FluentThemeOverride` no longer leaks out of the text context
  menu.** `ContextMenuController.show` captures inherited themes from inside its
  own `OverlayEntry.builder`, where `from:` and `to:` are both already below the
  `Navigator`, so the capture came back empty; `fluentTextContextMenuBuilder`
  now captures at the call site.
- **`FluentNav` and `FluentToolbar` could become permanently unreachable by
  Tab.** Disabling the row or item holding the roving tab stop left the control
  with zero tab stops, and no registration event fired to re-park it. The
  toolbar additionally had to clear the derived `skipTraversal` its item latched
  onto its own node while its gate was shut.
- **`FluentDataGrid` painted no focus ring on the first cell reached by Tab** —
  the rebuild was gated on the cell having moved, and the cell you enter is
  always the one already holding the roving index.
- **Popups no longer open off-screen.** `FluentTagPicker`, `FluentTimePicker`,
  `FluentBreadcrumb`'s overflow, `FluentInfoButton` and `FluentMenu` now clamp
  to the room actually left beside their anchor and flip to the other side
  rather than collapsing. A bottom-edge `FluentMenu` trigger previously rendered
  a surface of height zero — focus moved into it, Escape bound to it, and
  nothing painted. Submenus measured their anchor row's position inside the
  parent surface and read it as a screen coordinate, overhanging the viewport by
  exactly the parent's own `y`.
- **Open popups no longer go stale.** `FluentDropdown`, `FluentTagPicker` and
  `FluentTimePicker` rebuild their overlay when a dependency moves, so resizing
  the window re-measures the maximum height and a theme swap repaints the popup.
- **RTL.** `FluentPopover` implemented its documented reading-order positioning
  physically; `FluentTooltip` picked the wrong side and mirrored its arrow
  wrongly; `FluentCarousel`'s arrow keys ran opposite to its visible motion and
  its buttons were pinned to physical edges; `FluentRating` painted, hit-tested
  and arrow-keyed left-to-right only. `Directionality` also does not cross an
  `OverlayEntry` boundary and is now carried explicitly into the popover,
  dialog, toast and menu overlays.
- **Leaks and lifecycle.** Four `OverlayEntry`s were removed without being
  disposed (`FluentDatePicker`, `FluentTimePicker`); `FluentDatePicker` disposed
  its `FocusScope` node before removing the entry that builds under it;
  `FluentTree` never pruned focus nodes for removed items; `FluentTabList` never
  disposed its flip `CurvedAnimation`; `FluentSpinButton` left a focus listener
  on its internal node.
- **`FluentMenu` no longer closes an open submenu on an unrelated rebuild.** It
  compared its `items` list by identity, which is false for any caller passing a
  fresh list literal.
- **A right-click no longer paints the pressed token** on every control built on
  `FluentInteractive`.
- **An overlay `FluentDrawer` now hides the page behind it from assistive
  technology**, and `FluentBreadcrumb`'s invisible dismiss scrim no longer
  appears in the semantics tree as an unlabelled full-screen button.
- **`FluentTooltip` no longer announces its content twice** when a
  `semanticLabel` is set.

### Publishing

- Require `fluent_2_core` 0.0.3.

## 0.0.2

### Added

- **ColorPicker.** `FluentColorPicker`, `FluentColorArea`, `FluentColorSlider`
  and `FluentAlphaSlider`, ported from `@fluentui/react-color-picker-preview`,
  with `FluentColorPickerStyle`, `FluentColorAreaStyle` and
  `FluentColorSliderStyle`, the three matching `*Theme` widgets and the usual
  `resolve*State` / `resolve*Style` / `build*` trio per component. The colour is
  Flutter's own `HSVColor` — no new colour type reaches the API — and a picker
  publishes it to its children through `FluentColorPickerScope`, so all four
  controls always agree. Controlled only: there is no `defaultColor`, because
  upstream's uncontrolled mode gives each child its own copy of the value and
  they drift apart on the first drag. A new showroom page covers all eight
  upstream stories.

### Fixed

- **`FluentSlider` no longer loses a touch drag to a scrolling ancestor.** It
  used a `GestureDetector` with `onTapDown` + `onHorizontalDrag*`, which does not
  claim the pointer until the drag slop is exceeded — long enough for a
  horizontally scrolling parent to win the arena. It now claims at pointer-down
  through the same `EagerGestureRecognizer` path the colour controls use. Mouse
  input was never affected, because Flutter leaves mouse out of
  `ScrollBehavior.dragDevices`, which is why no test caught it.

### Breaking

- **Removed `FluentSpinButtonUnderlinePainter`.** The spin button's two bottom
  rules now come from the shared `FluentInputUnderline` /
  `FluentInputFocusUnderline` pair, like every other input. The painter drew both
  with `canvas.drawRect`, so they were square and overhung the field's rounded
  corners; upstream's `useSpinButtonStyles` rounds them via
  `height: max(2px, borderRadiusMedium)` plus
  `clipPath: inset(calc(100% - 2px) 0 0 0)`. `FluentSpinButtonChevronPainter` is
  unaffected. Anyone who subclassed or instantiated the removed painter should
  use the two widgets instead.

### Publishing

- Use the Fluent 2 project logo as the first pub.dev screenshot and thumbnail.
- Require `fluent_2_core` and `fluent_2_fonts_web` 0.0.2.

## 0.0.1

- Initial release.
