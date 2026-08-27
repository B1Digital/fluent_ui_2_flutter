## Unreleased

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
