## Unreleased

### Added

- **`FluentBoxDecoration` paints `boxShadow` the way CSS does — outside the box
  only.** A `BoxDecoration` shadow is a blurred copy of the box drawn *under*
  it, which a transparent box shows as a grey wash (`shadow16` darkens the
  inside to about 76%). Upstream shadows unfilled elements routinely, so this is
  the decoration for them; the blur also uses CSS's σ = blur / 2. Everything
  else paints as `BoxDecoration`. The CarouselNav and Carousel demos use it,
  which is what stopped the CarouselNav card rendering solid grey.

- **Charts:**
  - `calloutPropsPerDataPoint` on `FluentHorizontalBarChart` and
    `FluentDonutChart`, spread over the built-in reading as ChartPopover does,
    and `legends` / `enabledWrapLines` on `FluentHorizontalBarChart`
    (upstream's `legendProps`), whose wrapped rows render each legend's
    `annotationBuilder`.
  - `FluentChartTooltipBox`, the box a cut-short axis label shows its whole
    text in on hover or a touch tap.
  - `FluentChartPopover.anchorRect`, `FluentChartPopoverData.isCartesian` and
    `contentMaxWidth`, `FluentChartHitRegion.popoverAnchor`,
    `FluentCartesianChartProps.popoverFollowsPointer` and
    `FluentYValueHover.shouldDrawBorderBottom`.
  - `FluentChartHitRegion.hitTest` (a mark hovers and clicks as its painted
    shape, a circle as a circle), `focusable` and `followsPointer`, and
    `FluentCartesianSeriesDelegate.hoveredRegionAt`, which names the hovered
    region on the same pointer event the chart hears.
- **Components:**
  - `FluentButton.activeIcon` (upstream's `bundleIcon` filled glyph, shown
    while a subtle or transparent button is hovered or pressed; also on
    `FluentCompoundButton`) and `FluentButton.menuIcon` (MenuButton's chevron
    slot: 12, or 16 at large, 4 after the label, in the label colour).
  - `FluentButtonStyle.iconColor`, `menuIconSize` and `animationDuration`.
  - `FluentLinkUnderline`, which paints a link's underline as a crisp 1px
    line under every line of the label.
  - `FluentCarouselNavAppearance`, `FluentCarousel.navAppearance` and
    `FluentCarouselStep.appearance` (upstream's brand CarouselNav).
  - `FluentTreeItem.aside`, the always-visible trailing slot.
  - `FluentInteractive.disabledMouseCursor` and `pressedRequiresHover`
    (upstream's `:hover:active`).
  - `FluentInteractionTag.activeIcon`, the filled glyph an outline tag shows
    while hovered or pressed, and `FluentTagStyle.iconColor`.

### Changed

- **BREAKING (custom styles): `FluentInputStyle.borderWidth`,
  `bottomBorderColor` and `bottomBorderWidth` now describe a real CSS-style
  border.** The border takes space and the content row sits inside it, on top
  of `padding` — the bottom side used to be a rule overlaid on the box's bottom
  edge that cost no layout. A null `borderColor` means no border and no inset
  whatever `borderWidth` says; a null `bottomBorderColor` means the bottom
  follows `borderColor`. A custom style that set a wide bottom rule, or relied
  on the border not moving the text, will lay out differently. The same holds
  for the bottom-side fields of `FluentSearchBoxStyle`, `FluentTextareaStyle`,
  `FluentSpinButtonStyle`, `FluentDropdownStyle`, `FluentTagPickerStyle`,
  `FluentDatePickerStyle` and `FluentTimePickerStyle`.
- **BREAKING (sibling APIs), each to match upstream:**
  - `FluentSpinButtonBaseState.inert` is gone — read-only no longer styles the
    surface, only the steppers go inert;
  - `FluentSpinButtonChevronPainter` no longer takes `glyphSize` or
    `strokeWidth`: it fills upstream's 14px svg path;
  - `FluentTextarea.maxLines: null` holds the field at `minLines` rows and
    scrolls, as upstream's `rows` does; pass `maxLines` to let it grow;
  - `FluentTimePickerStyle.trailingGap` is now the space between the text
    field and the trailing glyph, and `trailingPadding` the inset around the
    text field;
  - `FluentDropdown` and `FluentTimePicker` take upstream's 250px minimum
    width;
  - `FluentTagPicker` draws upstream's expand chevron by default (`expandIcon`,
    `fluentTagPickerChevron`), is 34/42/46 tall, and has 32px option rows and
    upstream-sized tags;
  - `FluentTagDismissPainter.inkRatio` is gone: the dismiss glyph fills
    upstream's `DismissRegular` path instead of a scaled cross;
  - `FluentSpinButtonStepper` is now a `StatefulWidget` (it repeats while
    held).
- **`FluentTag.media` is new** — upstream's `media` slot, for an avatar, 1px
  inside the border; `icon` stays at the content inset. A `FluentTagPicker`
  chip puts its avatar there (new `FluentTagPickerOption.tagMedia`, which
  falls back to `media`).
- **`FluentInputBorderPainter` is new** and is what paints the border. Where the
  bottom colour differs from the sides, the two meet along each bottom corner's
  diagonal the way a browser joins adjacent border colours, instead of the
  bottom colour stopping a pixel up the arc. Public with its fields, so tests
  read the resolved tones off it, as with `FluentRadioIndicatorPainter`.
- **The focus bar eases on CSS `ease` and reverses the way CSS does.** Upstream
  writes the curve tokens into `transitionDelay` — a typo for
  `transitionTimingFunction` — so every browser drops them and runs `ease`,
  which the port had been reading as intent and replacing with
  `curveDecelerateMid` / `curveAccelerateMid` (45% of the bar drawn 20ms in,
  against upstream's 9.5%). `fluentInputFocusUnderlineEnter` / `Exit` are now
  `FluentCssCubic.ease` — new, a `cubic-bezier()` solved to 1e-7 as Chromium
  solves it, where Flutter's `Cubic` stops at 1e-3 and drew the bar's ends up
  to 0.4px off Chrome's — and a focus change mid-flight starts a fresh `ease`
  from the current scale over the direction's duration times the distance
  left, instead of retracing the old curve. Every field sharing the bar picks
  this up: `FluentInput`, `FluentTextarea`, `FluentSearchBox`,
  `FluentDropdown`, `FluentTagPicker`, `FluentSpinButton`, `FluentDatePicker`
  and `FluentTimePicker`, whose alias constants follow.
- **`FluentInput` matches upstream as rendered in Chrome rather than the Figma
  set**, and so does `FluentDatePicker`, which is `.fui-Input` upstream and
  derives its faceplate from it:
  - a focused outline field keeps `neutralStroke1Pressed` /
    `neutralStrokeAccessiblePressed` even while hovered;
  - a read-only `FluentInput` is styled exactly like rest — it was on the
    disabled ramp;
  - invalid is `colorPaletteRedBorder2` (`#d13438` light), not
    `statusDangerBorder2`; high contrast keeps the status token;
  - underline has square corners, on the root and the focus bar;
  - the bottom border stays 1px while pressed — it was 2px;
  - text and slots sit inside the border: 1px further in on outline and filled,
    and 0.5px higher on underline, whose only border is the bottom one;
  - large's text inset is 18 (12 + `SNudge`), not Figma's 14;
  - the caret is 1px, a browser's width, not `EditableText`'s 2 (also in
    `FluentTagPicker`, which composes `FluentInput`).
- **`FluentSearchBox`, `FluentTextarea`, `FluentSpinButton`, `FluentDropdown`,
  `FluentTagPicker` and `FluentTimePicker` match upstream as rendered in
  Chrome**, each measured across its appearances, sizes and states at a pixel
  ratio of 4:
  - read-only is styled like rest on all of them — it was on the disabled
    ramp;
  - invalid is `colorPaletteRedBorder2`, with new `error` parameters on
    `FluentSearchBox`, `FluentDropdown` and `FluentTagPicker`;
  - the bottom border is 1px in every state, joins the sides on the corner
    diagonal and, like the rest of the border, sits outside the content;
  - the caret is 1px, and a disabled field shows `not-allowed`;
  - focus follows each component's own cascade. SearchBox and SpinButton write
    `:active,:focus-within` as one rule, so a focused field keeps the Pressed
    stop through a hover, as Input does. Textarea, Dropdown, TagPicker and
    TimePicker write `:focus-within` alone, which Griffel sorts before
    `:hover`, so hover wins there; a focused Textarea's bottom border is
    `compoundBrandStroke`;
  - Textarea is 44/56/68 tall (new `FluentTextareaStyle.minimumSize`);
    SpinButton's border is drawn over its steppers, whose fills follow the
    appearance; TimePicker follows Combobox's padding and ramp rather than
    Input's, and gained hover and press states; Dropdown's fill no longer
    ramps on hover and press — only Outline's border does, as upstream.
- **`FluentDatePicker` and `FluentTimePicker` pass their real `readOnly` to the
  style resolver.** They used to hide it so a default, read-only picker did not
  render greyed out; with read-only unstyled there is nothing left to hide.

- **Every text field focuses on mouse-down, as Chrome does, so the focus bar
  grows under a held press.** Flutter's text gestures focus on tap-down, which
  a middle press never reaches and which waits for the gesture arena whenever
  it is contested: the bar started a whole click late. `FluentInput` (and so
  `FluentTagPicker`), `FluentTextarea`, `FluentSearchBox`, `FluentSpinButton`,
  `FluentDatePicker`, `FluentTimePicker` and `FluentDropdown` now focus on a
  mouse press of any button, with the caret where it landed, through the
  field's own selection path so desktop's select-all-on-focus stays out.
  SearchBox focuses only from its `<input>` box, not the icon or padding, and a
  right press that moves focus there is not `:active` (Chrome).
- **Behaviour now follows upstream in Chrome:**
  - SpinButton steppers step on press and repeat while held (305 / 541 /
    725ms…, within a frame of upstream); a stepper whose value equals its
    bound goes inert — greyed glyph, no fill, `not-allowed` — and a press
    there takes focus away;
  - TagPicker keeps its field (and focus) when the first tag appears, so
    typing continues after a pick; a printable key reopens the list and
    highlights the first option starting with the text, which Enter adds; the
    list refreshes while typing; a click anywhere on a chip removes it; the
    secondary-action aside stretches to the full height;
  - DatePicker gained hover and press, and shows the hover ramp rather than
    the focused one while the calendar holds focus;
  - a right press shows `:active` on Input, DatePicker, Textarea, SearchBox and
    SpinButton's text, but not on a live stepper or the Combobox family;
  - Textarea shows touch selection handles for touch only;
  - a disabled field shows `not-allowed` over its text, and a disabled
    Dropdown over its whole trigger.
- **A fixed parent height stretches every text field**, with the focus bar on
  its bottom edge, as CSS `height` does — it used to draw the box at its
  natural height and the bar below it.
- **BREAKING (behaviour), to match upstream's Combobox family:**
  - `FluentTagPickerRemoveLastIntent` (Backspace in an empty field) focuses
    the last chip instead of removing it; Delete, Backspace, Enter or Space
    (on release) then removes the focused chip;
  - `FluentTagPickerStyle.fieldWidth` is a minimum (24) rather than a fixed
    96: the field takes the rest of the chips' last line and wraps below it
    or when its text no longer fits; `contentPadding` changed meaning, and
    `tagRunSpacing`, `tagPadding` and `fieldSpacing` are new;
  - a non-freeform `FluentTimePicker` takes a caret and typing (type-ahead;
    its text reverts on close or picks an exact match), and
    `resolveFluentTimePickerState(readOnly:)` defaults to false; `hourCycle`
    is nullable; the default parser accepts upstream's formats only (`8` is
    no longer a time); the 416px `surfaceMaxHeight` default is gone — the
    list takes the room below the field;
  - `FluentInteractive` reports `pressed` for middle and right presses (new
    `pressedOnSecondary`, which the Dropdown trigger turns off) and tracks
    hover while disabled.
- **Pickers behave as upstream's in Chrome** (each measured there first):
  - TimePicker: freeform typing rings the matching option; typed text is kept
    after Tab, blur and Escape instead of being reformatted; Enter with a
    typed match only opens, with none it commits and opens on the committed
    time; Space picks on an open list not being typed into; a chevron press
    toggles on mousedown for any button and leaves the caret; a click that
    drifts still counts; the list keeps its scroll across a reopen;
  - TagPicker: typed text is cleared on blur or close; chips are focusable,
    and a press on one while open removes it and moves focus to the next; a
    click on the field toggles the list (primary button only), and a press on
    the chevron, padding or aside toggles on mousedown; Up opens on the first
    row, disabled rows are visited, and a pick leaves a caller's controller
    alone;
  - Dropdown: PageUp/PageDown move ten rows, Alt+Up selects and closes,
    Alt+Down opens or moves on, keypad Enter commits, and every key but Alt+Up
    reads the same under Shift, Ctrl or Meta; disabled rows are reachable;
    Escape on a shut list reaches a dialog around it;
  - DatePicker: a click while the calendar is open leaves it open unless text
    input is on; with text input the popup keeps focus under a held press and
    the closing click puts the caret where it landed; a press dragged off the
    field opens nothing;
  - lists scroll their active row just into view, 2px clear, instead of
    centring it.
- **`FluentField` takes upstream's validation colours and glyphs:** the message
  and glyph are `colorPalette*Foreground1` per state (error `#bc2f32`), and a
  default glyph is drawn per state (new `FluentFieldValidationGlyph`) unless
  one is passed. `FluentLabel` wraps a long label with the required asterisk
  inline after the last word.
- **`FluentTooltip.position` is now a preference.** A tooltip with no room on
  that side opens on the opposite one; see the Positioning section of
  `FluentTooltip`. `buildFluentTooltip` is unchanged and still stacks the
  arrow on exactly the side its state names.

- **BREAKING (charts):**
  - `FluentChartPopoverLayoutDelegate` is replaced by `FluentChartPopoverLayout`
    (and `RenderFluentChartPopoverLayout`), which places the surface as
    upstream's ChartPopover does: above and centred, flipped, shifted into the
    chart root and height-capped with its body clipped.
  - `FluentVerticalBarChartDelegate.barDomain` is now
    `barDomainFor(FluentCartesianChildContext)`, and
    `FluentScatterChartDelegate.popoverFor` returns `FluentChartPopoverData?`
    (null where no point at that x shows a callout).
  - The HorizontalBar, Donut, Funnel and Polar popovers float in the app's
    `Overlay`, as upstream's overhang their chart, so hovering one needs an
    `Overlay` ancestor (`FluentApp` and `WidgetsApp` provide it).
  - `FluentChartHitRegion.popoverData` is nullable: null opens no callout and
    closes an open one, as a mark another legend dims does upstream. A custom
    delegate that reads `region.popoverData` needs a null check.
- **BREAKING (components), each to match the storybook:**
  - `FluentDialog.showCloseButton` is nullable; null draws the header close
    button on a non-modal dialog only, and the close is a bare 20px glyph;
  - every popover surface lays out its 1px border (2px larger, content 1px
    further in), flips and shifts to stay in the viewport, and
    `FluentPopoverStyle.arrowInset` defaults to 8;
  - tree item actions show only while the row is hovered, pressed or focused,
    over a 32px row; list items paint no fill; carousel previous, next and
    autoplay are 32x32;
  - compound button padding, type and icon gap follow upstream (60/72/80 high
    with an icon).
- **Charts match the storybook's hover** (each measured against the live
  storybook): line, area, scatter, vertical, stacked, grouped and horizontal
  bar charts, donut, gauge, funnel, heat map, gantt, polar, sankey and
  sparkline open, place, follow and close their callouts as upstream does, and
  grow markers and draw hover rules where upstream does.
- **Components match the storybook's hover and press:** buttons tween border
  and label colour, subtle icons turn brand on their own, checked toggles
  draw upstream's border and icon, radio labels ramp, nav, tree, data grid,
  list item, breadcrumb and carousel dots follow React's ramps where Figma
  disagreed, and swatch rings keep their white hairline.
- **Disabled controls show `not-allowed`, and a press dragged off falls back
  to rest, where upstream writes them:**
  - `FluentInteractive` shows `not-allowed` over a disabled surface by
    default, as Button, Link, menu rows, Tab, Tag (the whole tag),
    InteractionTag, ColorSwatch, AccordionHeader, Card and Breadcrumb do;
    Checkbox, Radio, Switch, Slider, ListItem, listbox options, Calendar, the
    colour pickers, InfoButton, Nav and Tree keep the arrow;
  - Button, CompoundButton, SplitButton, Switch, Radio, ColorSwatch,
    InfoButton, the Calendar's navigation, caption, today and month/year
    cells, menu rows and breadcrumbs are pressed only while the mouse is over
    them, so a press dragged off shows rest and presses again on the way back;
    a touch press holds.
- **Charts answer touch and legends as upstream does:** a touch tap hovers
  what it lands on (markers, hover rules and VerticalBarChart's line dots
  included) and a tap outside the chart ends it; a mark another legend dims
  opens no callout and takes no tab stop but still clicks; a LineChart
  segment opens its start point's callout on the move that reaches it; a
  following callout moves only once the pointer has moved more than 1px.
- **More components follow React over Figma:**
  - the Tag dismiss glyph (every appearance) and brand InteractionTags ramp
    through `colorCompoundBrandForeground1Hover` / `Pressed`;
  - `FluentSwatchPicker` pads by 0, so its swatches sit flush with the picker
    (they were 10px in);
  - a vertical `FluentField` pads its label 2px above and below (1px at
    large), so the control starts 26px below the field's top, not 22;
  - `FluentCalendar` pages with upstream's arrow glyphs instead of chevrons;
  - the hamburger stays transparent and only its glyph ramps, a disabled
    unselected subtle-circular tab is unfilled, and an autoplaying carousel's
    toggle rests checked while it plays.

### Fixed

- **Turning reduced motion off again left the focus bar snapping.** The bar
  zeroed its durations when `MediaQuery.disableAnimations` came on and never
  restored them; they are now set on every dependency change.
- **Pressing another field while a `FluentDropdown` held focus focused
  nothing until release.** The Dropdown's outside-tap blur ran on the same
  pointer-down and parked focus on the route's scope, cancelling the pressed
  field's own request. It now blurs only if focus is still its own once that
  event has settled, as a click on the page body does.
- **A field removed mid-press threw on the release.** `FluentInteractive`,
  `FluentInput`, `FluentTextarea`, `FluentSearchBox`, `FluentSpinButton`,
  `FluentDatePicker`, `FluentTimePicker` and `FluentTagPicker` ignore a press
  that ends after they are gone.
- **Hover and press were lost when a field was re-enabled under the mouse.**
  `FluentDatePicker`, `FluentTimePicker`, `FluentTagPicker`, `FluentTextarea`
  and `FluentSearchBox` track them while disabled and filter them in the
  build, as Chrome keeps a disabled root's `:hover` and `:active`.
- **A `FluentDropdown` whose options shrank under the open list threw** on
  Enter; the active row now falls back to the first option.
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

- **Charts:**
  - an unknown `culture` (such as `'rs-ss'`) falls back to the default locale
    instead of throwing during build;
  - a log y axis draws its default log ticks; mixed number and `Date` x values
    compare by value, and a `Date` extent on a numeric axis no longer throws;
  - annotation boxes lay out and paint as the CSS container (max-width,
    border, outer shadows, dashed and dotted borders);
  - legend swatches and popover row markers snap to device pixels, swatches
    rotate about their centre, line swatches in a bar chart are 14x6,
    wrapped legend rows start at the leading edge, and the overflow chevron
    sits in the menu icon slot;
  - VerticalBar and VerticalStackedBar place date bars on upstream's un-niced
    time scale and stand on the height above the label reserve; the
    HorizontalBarChart benchmark triangle sits where upstream draws it;
  - the funnel legend sits right under its `height`-tall plot and each stage
    paints on its own, so the seam between categories shows; the heat map
    callout body is capped at upstream's 238px, and heat map and gantt
    readings take title2 as non-cartesian callouts;
  - a secondary y axis fills areas to zero; line segments honour
    `strokeDashoffset`; colour fill bars top out at the data maximum; the
    sparkline stroke is clipped to its plot; a sankey node name collapses its
    white space;
  - a stack callout with two or more line rows no longer throws
    'Duplicate keys found';
  - a numeric `yAxisCalloutData` reads as a formatted number (`'12345'` is
    `12,345`) and an empty one falls back to the y value; a secondary y axis
    no series is on spans 0 to its `yMaxValue` instead of asserting on NaN;
  - a sankey node name cut short shows whole in the tooltip box beside the
    pointer; a dimmed line series draws no white halo across the highlighted
    one; HorizontalBarChartWithAxis dims its bars on legend hover and prints
    readings as JS does (`5000`, not `5000.0`);
  - hovering a large chart costs less: VerticalBarChart's hover is linear in
    the bar count, stacked bars read their hover targets back instead of
    re-solving them, and a move no longer rebuilds number formats or
    re-measures every tick label.
- **Components:** the toast clips only while its height animates; a popover's
  surface is capped only in width, so a tall one no longer squeezes its
  content; the teaching popover dismiss is upstream's bare 12px glyph; a
  labelled list item announces its label once; `FluentSearchBox` keeps its
  468px cap inside a stretching parent such as `FluentField`; a hovered
  carousel step mark stays visible in high contrast.

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
