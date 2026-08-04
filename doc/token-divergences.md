# Where the Figma file and the shipped TypeScript disagree

This port targets the official **Fluent 2 Web (Community)** Figma file
(`Heyk4N9SnwfIzupHlk3l7s`). Where that file and `@fluentui/react-components`
disagree on a value, **Figma wins** and the divergence is recorded here.

Every entry below was found by independently re-deriving the upstream value from
`microsoft/fluentui@master` and comparing it to ours. None of them is a porting
defect — the Dart matches Figma exactly in all cases. They are listed so nobody
"corrects" them later after diffing against the React source.

First, the part that agrees: **all 588 shared ramp stops are byte-identical
between Figma ` Global` `Colors/Shared/*` and upstream `global/colors.ts`.** So
every divergence below lives in the alias layer, never in the substrate. The
Figma ` Brand` collection is likewise byte-identical to upstream's hand-authored
`brandWeb` across all 16 stops.

## Status colours — 4 value divergences

Upstream generates `colorStatus*` in `alias/{light,dark}ColorPalette.ts` by
reducing `statusColorMapping` (success→green, warning→orange, danger→cranberry)
over the ramps, then applying a block of one-off overrides. Reconstructing all
32 of those and mapping them onto Figma's `Status/*` keys gives 58 comparisons,
53 of which agree.

| Token | Upstream | Figma / ours | Reading |
|---|---|---|---|
| `successForegroundInvertedRest` | light `#54b054` (green tint30), dark `#0e700e` (green shade10) | light `#359b35` (tint20), dark `#107c10` (primary) | Differs in **both** themes. Figma is also internally inconsistent here — Danger and Warning both use tint30/shade10-ish and agree with upstream; only Success is a one-off. Either an unrecorded contrast fix or community-file drift. |
| `warningForeground3Rest` (dark) | `#f98845` (orange tint20) | `#fdcfb4` (orange tint40) | Most likely an **upstream** bug. `darkColorPalette.ts` applies a dark `Foreground3 → tint40` override for danger and success but omits warning, so warning falls through to the generic rule — directly under a literal `// TODO: double check the mapping with design`. Figma applies tint40 uniformly. |
| `warningForeground1Rest` (dark) | `#faa06b` (orange tint30) | `#f98845` (orange tint20) | Part of a consistent Figma pattern: the two high-luminance orange families (Warning, Severe) sit one stop darker than Danger/Success in dark mode. Reads as a deliberate perceived-brightness correction. |
| `warningStroke1Rest` (dark) | `#f7630c` (orange primary) | `#de590b` (orange shade10) | Same Warning/Severe pattern — Severe dark `Stroke/1` is likewise `darkOrange.shade10`. Danger and Success are both `primary` and both agree with upstream. |

Light mode agrees in all three warning cases.

## Status colours — naming and coverage gaps

- **`dangerForeground3Hover` / `dangerForeground3Pressed`.** Values are identical
  to upstream (`#b10e1c`, `#960b18`), but Figma files them under `Foreground/3/*`
  where upstream names them `colorStatusDangerBackground3Hover/Pressed`. We
  follow Figma. Anyone porting from React will search for the `Background` name
  and not find it.
- **Absent here, present upstream:** `colorStatusDangerBorderActive`,
  `SuccessBorderActive`, `WarningBorderActive`. No corresponding Figma variable
  exists, so no Dart member was emitted. This is a coverage gap against React
  parity, not a dropped value.
- **Present here, absent upstream:** the entire 12-token **Severe** family, plus
  three presence tokens — Available (`lightGreen.primary` `#13a10e`), Away
  (`marigold.primary` `#eaa300`) and Oof (`berry.primary` `#c239b3`). All resolve
  to sensible upstream ramp stops; React simply has no `colorStatusSevere*`.

## Palette colours — 3 divergences

| Token | Upstream | Figma / ours |
|---|---|---|
| `background3Rest(red)` dark | `red.primary` `#d13438` | `#750b1c` — that is `darkRed.primary` |
| `foreground3Rest(green)` / `stroke2Rest(green)` dark | `green.tint40` `#9fd89f` (a dark one-off patch) | `#54b054` — `green.tint30` |
| `strokeActiveRest(darkRed)` dark | `darkRed.tint30` `#ac4f5e` | `#962f3f` — `darkRed.tint20` |

## Apparent authoring bugs inside Figma itself

These are cases where a Figma palette variable aliases a ramp from a *different*
family. They are carried through verbatim rather than silently corrected,
because guessing at intent is how a port stops being a port.

- `Palette/Red/Foreground/2/Rest` (dark) aliases `Colors/Shared/Cranberry/Tint 40`
- `Palette/Lavender/Background/2/Rest` (light) aliases `Colors/Shared/Navy/Tint 40`
- `Palette/Plum/Stroke/Active/Rest` aliases Magenta in **both** modes
- `Palette/Marigold/Foreground/1/Rest 2` — an oddly-named duplicate, preserved
  with a distinct Dart identifier

## Typography — the published ramp beats the shipped TypeScript

`subtitle1` on Web is **20/26**, per the platform type ramp at
<https://fluent2.microsoft.design/typography>.

React renders it 20/**28**: `typographyStyles.subtitle1` binds
`lineHeightBase500`, and `global/fonts.ts` sets that token to `28px`. The Figma
community file agrees with the TypeScript — every `Typography/Line height/500`
binding in the fixtures resolves to 28 — so on this one value the *documentation*
is the odd one out, and it is the one we follow. Every other stop on the Web
ramp agrees across all three sources.

The 2px lands on anything that stacks a `subtitle1` line box, and each of those
components states it rather than absorbing it:

| Component | Where |
|---|---|
| Drawer | `drawer_test.dart` — "the header follows the published Web subtitle metric" |
| Dialog | title line height asserted against the ramp, font size against the fixture |
| Accordion | header line height |
| Avatar | initials line height |
| Spinner | label line height, and the stacked-layout frame height |

Spinner is the one worth understanding: a label *above* or *below* the glyph adds
its line box to the frame, so the component measures exactly 2px shorter than
Figma's frame. A label *beside* the glyph does not, because the glyph is taller
than either line box. The tests derive that difference from the fixture's own
token rather than hard-coding 2, so it tracks if either authority moves.

## Focus ring — one ring, following React

**Reversed 2026-08-04.** This section previously said Figma draws two rings on
*every* interactive component and that we followed it. Both halves were wrong,
and the resulting double ring is what made a focused tab read as a heavy black
box next to React's thin one.

| | Figma | React v9 (what we ship) |
|---|---|---|
| Rings | **one on `tab`, `vertical_tab`, `list_item`; two elsewhere** | one, everywhere |
| Outer | 2px, `strokeAlign: OUTSIDE`, `strokeFocus2` | 2px `colorStrokeFocus2`, offset `-2px` |
| Inner | 1px, `strokeAlign: INSIDE`, `strokeFocus1` | — none — |
| Drawn as | `CustomPaint` foreground painter | `::after` pseudo-element with a border |
| Radius | the component's own | `borderRadiusMedium` (4px), hard-coded |
| Transition | none | none |

Figma is **not uniform**, which is what the old claim missed. Grepping the
fixtures for focus strokes:

- one `Neutral/Stroke/Focus/2` stroke only — `tab`, `vertical_tab`, `list_item`
- `Focus/2` plus an inner `Focus/1` — `breadcrumb`, `checkbox`, `dropdown_option`,
  `info_button`, `radio`, `slider`, `switch`

So on the first group Figma and React **agree** on a single ring and this port
was simply wrong; on the second they genuinely disagree.

React's side was confirmed empirically, not just read: probing
`storybooks.fluentui.dev` with real tab-order focus resolves
`.fui-Checkbox::after`, `.fui-Radio::after`, `.fui-Switch::after`,
`.fui-Slider::after`, `.fui-AccordionHeader__button::after` and
`.fui-InfoButton::after` to a lone `border: 2px solid` `strokeFocus2` at
`inset: -2px` and `border-radius: 4px`. `Tab` and `Button` express the same
single ring as a spread shadow instead (`Tab`: `shadow4, 0 0 0 2px`; `Button`:
`inset 0 0 0 1px`). Nothing anywhere draws `colorStrokeFocus1` — it is
referenced nowhere in `react-tabster`, and only by `react-swatch-picker` in all
of `packages/react-components`. The white-inner / black-outer double ring lives
in Fluent **web-components v3**.

We now ship React's single ring by default; `FluentFocusRing.twoTone`
reproduces Figma's pair for anyone who needs it.

Three details worth keeping:

- **Two radius idioms upstream, and they disagree.** `Tab` and `Button` draw the
  ring as `box-shadow: 0 0 0 2px`, and CSS grows a shadow's corner radius by its
  spread — so the ring's outer radius is the component's own **plus 2** (6 on a
  radius-4 tab). Everything on `createFocusOutlineStyle` instead gets an
  `::after` box at inset `-2px` carrying a flat `border-radius: 4px`, i.e. an
  outer radius of **4 regardless** of the component. `FluentFocusRingPainter`
  paints concentric rings, which is the first idiom; a component on the second
  passes a `borderRadius` two smaller (Slider's `allSmall` is exactly this).
- **What was given up**: the two tones **invert** between light and dark
  (`strokeFocus1` is white on light and black on dark; `strokeFocus2` the
  reverse), so Figma's second ring is what keeps focus legible against an
  unknown backdrop. A single ring relies on `strokeFocus2` resolving from the
  theme, plus high contrast substituting a system colour. Reach for
  `.twoTone` on any surface where that assumption does not hold. The test
  asserting `light.outer == dark.inner` still guards the tokens.
- Upstream hard-codes the width as the string `'2px'` with the comment
  `// FIXME: tokens.strokeWidthThick causes some weird bugs`, directly above the
  line. `strokeWidthThick` is also `2px`, so we use `FluentStroke.thick` and note
  the upstream quirk rather than copying the workaround.

The outer ring paints **outside** the child's bounds, so an ancestor clipping
tightly to the child will shave it. `FluentInteractive` does not clip.

## Transparent tokens — and why the surface tween needs a custom lerp

Figma cannot store a colour without an RGB triple, so it records fully
transparent tokens as `#00FFFFFF` — transparent **white**. Upstream's TypeScript
says `colorTransparentBackground: 'transparent'`, and CSS `transparent` is
defined as `rgba(0,0,0,0)` — transparent **black**, which is what core stores.

Both are invisible, so this is not a fidelity bug and the fixture comparison
asserts only the alpha for zero-alpha fills.

It does matter for animation, though, and this one is a real rendering bug that
the mismatch surfaced. Flutter's `Color.lerp` interpolates channels **directly**,
not in premultiplied alpha space the way a browser does. So a subtle or
transparent button fading from `transparentBackground` (transparent black) up to
an opaque grey drags its RGB through the tween and passes through visibly darker
greys on the way. Browsers show no such fringe.

`fluentLerpColor` in `lib/src/internal/animated_style.dart` fixes it: when one
endpoint is fully transparent it adopts the other's RGB so only alpha moves,
which is the same result as premultiplying. **Any component animating a surface
colour should use it rather than `Color.lerp`** — it matters most for `subtle`
and `transparent` appearances, which are exactly the ones whose rest state is
fully transparent.

## Acrylic

Figma's `Material/Acrylic/*` and WinUI's `AcrylicBrush` describe the same visual
effect through different pipelines and do not agree — most visibly on blur
(**60** in Figma, **30** in WinUI). Both are ported, as `FluentAcrylic` and
`FluentWindowsAcrylic` respectively. Note also that Figma's `Stroke/Stop 2` is
fully opaque `#2c3136` in dark while its two siblings are `0x33` alpha in both
themes; that asymmetry is real and is asserted in the tests.

`backgroundBlur` is a **blur radius**, as Figma and CSS `filter: blur()` express
it. Flutter's `ImageFilter.blur` takes a Gaussian sigma — halve it.

## Slider — seven divergences, all resolved toward Figma

Component set `9121:2771` (page `8934:15`), 10 variants, extracted to
`test/fixtures/slider.json`. The component was first ported from
`useSliderStyles.styles.ts` with no Figma access; every row below is a value
that reconciliation changed.

| | React v9 | Figma / ours |
|---|---|---|
| Control height | 32 medium, 24 small | **24 in both sizes** |
| Rail inset | half a thumb (grid `1fr calc(100% - thumbSize) 1fr`) | **8** (`Spacing/Horizontal/S`) in both sizes |
| Rail corner radius | pill | **`Corner radius/Small`** (2) |
| Rail outline | — | — (we had invented a `transparentStroke` outline; Figma paints none) |
| Rail, disabled | `colorNeutralBackgroundDisabled` | **`Neutral/Stroke/Transparent/Disabled/Rest`** — invisible except where the progress covers it, opaque in high contrast |
| Thumb outline, disabled | `colorNeutralForegroundDisabled` | **`Neutral/Stroke/Disabled/Rest`** |
| Thumb outline width | `thumbSize * 0.05` (0.8 at 16) | **1** in both sizes |
| Thumb centre disc | `thumbSize * 0.3` (4.8 at 16) | **6** medium, **5** small |

Two consequences worth knowing. The rail inset is *not* half a thumb, so a
medium thumb overhangs the control's box by 1 at either extreme — that is what
the Figma frame does. And `thumbSize` here means the **outer** diameter: Figma's
`Thumb` frame is 18 (14) with its 1px stroke aligned OUTSIDE, which is where 20
(16) comes from, so that number happens to agree with React.

Everything else agreed: rail thickness 4/2, the compound-brand ramp on progress
and thumb disc across rest/hover/pressed, `neutralForegroundDisabled` on both
when disabled, `neutralBackground1` for the thumb fill, and `neutralStroke1` for
its outline. Figma has no stepped variant, so the tick colour is still the
upstream value.

## Radio — two token divergences and one inset

Found by extracting the Figma `Radio` set (30 variants) and diffing it against
`react-radio/library/src/components/Radio/useRadioStyles.styles.ts`, which is
what the first pass was built from.

| Property | React | Figma / ours |
|---|---|---|
| Disabled ring **and** dot | `colorNeutralStrokeDisabled` — light `#E0E0E0` (grey 88) | `Neutral/Foreground/Disabled/Rest` — light `#BDBDBD` (grey 74) |
| Label colour, unchecked | `colorNeutralForeground3` at rest, `2` on hover, `1` on press | `Neutral/Foreground/1/Rest` in **every** state |

The disabled one matters visually: the ring is the only mark an unchecked radio
makes, and `#E0E0E0` against `neutralBackground1` `#FFFFFF` is barely a shape.
Figma binds the ring, the dot and (via the nested `Radio icon`) both circles to
the same `Neutral/Foreground/Disabled` token in all four disabled variants.

The label one is a genuine flattening: all 30 variants bind
`Neutral/Foreground/1/Rest` on the text, including Hover and Pressed, so the
React ramp has no counterpart in the design file.

**Where we do not follow Figma:** the *disabled* label. Figma binds
`Neutral/Foreground/1/Rest` there too — the nested `Label` instance was simply
never switched — which would render a disabled radio's text at full contrast.
We keep `neutralForegroundDisabled`, matching React and every other component in
this port. This is the one place in the file where Figma is read as silent
rather than authoritative.

Geometry: `Icon+Label below` insets its label by `Spacing/Horizontal/SNudge`
(6), not `S` (8) — `6 + 33 + 6` is Figma's 45-wide frame. `Icon+Label after`
agrees with React throughout (XS gap, S right, SNudge top and bottom). The
`RadioGroup` `Direction` axis agrees exactly: `Vertical` is a column, both
horizontal layouts are rows, every one with `itemSpacing: 0` and start
alignment; `Horizontal stacked` centres each label under its indicator.

## Other, already documented in code

- `borderRadiusCircular`: upstream React says `10000px`; Figma says **9999**, and
  core already had 9999. Figma wins, core was right.
- Web `subtitle1` is **20/26** in the current Fluent typography table, while
  the Community Figma file still points to the global 28px line-height token.
  The platform-specific ramp follows the published platform table.
- `body2Strong` does not exist upstream on web; aliased to `subtitle2`.

## Switch

The Figma `Switch` set (page `8934:18`, set `9116:20025`, 40 variants) has no
Size axis: only `Layout`, `Checked` and `State`. Everything design-verified in
`FluentSwitch` therefore describes the **medium** ramp; `FluentSwitchSize.small`
still comes from upstream's `useSwitchStyles.styles.ts` alone.

- **Thumb diameter**: Figma draws a plain **14** px ellipse. React renders a
  `CircleFilled` glyph at `fontSize: trackHeight - 2` = 18, whose 20-unit
  viewBox paints 0.8 of the glyph box — **14.4**. Figma wins. The resting inset
  is 3, the travel stays 20, and 3 + 14 + 20 + 3 = 40 keeps the two end
  positions symmetric. Small's 11.2 is left alone: it is the same 0.7 of its
  track height that Figma's 14 is of 20, so the correction made the two ramps
  more consistent, not less.
- **Label above**: Figma's stacked switch is **60** tall — a 4 top inset on the
  wrapper, a 20 label row with 8 horizontal padding and nothing below, then the
  full 56x36 indicator. React zeroes the indicator's *top* margin instead, which
  gives 56. Figma wins.
- **Checked track border**: Figma paints **no stroke at all** on a checked track
  except in Disabled, where it uses `transparentStrokeDisabled`. React declares
  `border: 1px solid` with a transparent token in every state. React wins here,
  and this is the one deliberate exception on this component: the two are
  pixel-identical in a normal theme, but Fluent's transparent tokens turn opaque
  in high contrast, where that border is the only thing outlining a brand-filled
  switch.

## Accordion

The Figma `Accordion` set (page `8911:3184`, set `9074:913`, 24 variants over
`Size`, `State`, `Expanded`, `Chevron`) disagrees with
`useAccordionHeaderStyles.styles.ts` and `useAccordionPanelStyles.styles.ts` in
four places. Figma wins in all four.

| | React | Figma / ours |
|---|---|---|
| Header padding | `0 spacingHorizontalM 0 spacingHorizontalMNudge`, plus `buttonExpandIconEnd` (right → MNudge) and `buttonExpandIconEndNoIcon` (left → M) | `Spacing/Horizontal/MNudge` (10) on **both** sides, identically on all 24 variants. Neither chevron override exists in the file. |
| Small header height | `buttonSmall: { minHeight: '32px' }` | **44**. Every variant's `Content` frame is a fixed 44, small included; only the label ramp changes with size. |
| Small label | `...typographyStyles.body1` with `fontSize: fontSizeBase200` — 12 over body1's **20** line height | **12/16** — `Font size/200` *and* `Line height/200`. That is exactly `caption1`. |
| Large / Extra large weight | keeps body1's **regular**, overriding only size and line height | `Typography/Weight/Semibold`. 16/22 semibold is `subtitle2`, 20/28 semibold is `subtitle1`. |
| Panel inset | `margin: 0 spacingHorizontalM` — no bottom | `Spacing/Horizontal/M` each side **and** `Spacing/Vertical/M` below, `paddingTop` 0. |

Because all four label steps land on named ramp steps, the Dart selects
`caption1` / `body1` / `subtitle2` / `subtitle1` rather than restating web
pixels on top of `body1`. That keeps the iOS and Android ramps honoured instead
of overwritten.

Two things Figma has that are **not** ported:

- **`Text-offset`**, a wrapper around the label with `paddingBottom` bound to
  `Spacing/Vertical/XXS` (2), lifting the glyphs one pixel above centre. That is
  a correction for Figma's text-box metrics; Flutter's line box, with an
  explicit `TextStyle.height` and `leadingDistribution: even`, already centres
  the way the browser does. Copying the 2 would be reproducing a compensation
  for a renderer we do not use.
- **A Hover or Pressed variant.** The `State` axis is `Rest` and `Disabled`
  only, and the header frame carries no fill in either — confirming rather than
  contradicting React's flat header.

### Chevron rotation curve

`useAccordionHeader.tsx` writes the transition inline as
`transform ${motionTokens.durationNormal}ms ease-out` — a raw CSS keyword, not a
curve token. CSS `ease-out` is `cubic-bezier(0, 0, 0.58, 1)`: full speed at the
start, decelerating, no ease-in.

`FluentMotionSpec.accordionChevron` used `curveEasyEase` `(0.33, 0, 0.67, 1)`,
which is symmetric and eases **in**. Sampled a third of the way along, the
browser is 50% rotated, `decelerateMin` `(0.33, 0, 0.1, 1)` is 63%, and
`easyEase` only 27%. At 70% along: 87%, 95%, 73%. `decelerateMin` is closer at
both points and is the right *category* — a one-way decelerating rotation — so
the constant now uses it.

## Card — three token divergences, one elevation, one Figma self-contradiction

The Figma `Card` set (page `8911:3189`, set `9230:4927`, 28 variants over
`Layout`, `State`, `Style`) disagrees with `useCardStyles.styles.ts` in four
places. Figma wins in all four.

| | React | Figma / ours |
|---|---|---|
| Non-outline border, Rest / Hover / Pressed | `colorTransparentStroke` | `Neutral/Stroke/Transparent/Interactive/Rest`. Identical (invisible) in light and dark; in **high contrast** the plain token is the text colour and the Interactive one is the highlight. |
| Non-outline border, Disabled | `disabledStyles` paints `colorNeutralStrokeDisabled` on every appearance | `Neutral/Stroke/Transparent/Disabled/Rest` — **no visible border at all**. Only `outlineDisabled` keeps `Neutral/Stroke/Disabled/Rest`, and there the two agree. Visible in light, not just high contrast: React outlines a disabled Filled card in `#E0E0E0`, Figma does not. |
| Outline fill, Hover / Pressed / Selected | `colorTransparentBackgroundHover` / `Pressed` / `Selected` | `Neutral/Background/Transparent/Rest` on all four states. Again invisible in light and dark, but the three interactive members turn **opaque highlight** in high contrast, which would flood an outline card and bury its content. Outline signals state through its border. |
| Disabled elevation | `disabledStyles` drops every card to `shadow2` | the Disabled variants carry the **same `shadow4` effect style as their Rest siblings** — ambient `(0,0)` blur 2 plus key `(0,2)` blur 4. Outline and Subtle stay flat in both. |

Everything else agrees. Fill ramps match token for token across all four styles;
`Stroke width/Thin` is 1; the selected border is `Neutral/Stroke/1/Selected`
everywhere; hover elevation is `shadow8` on both filled styles.

**Radius and padding.** The variant frames bind a fixed
`Corner-radius/Card/Container/Medium`, but the `Card padding` collection — whose
mode the component pins — carries a `Card corner radius` that resolves Small → 2,
Medium → 4, Large → 6, exactly as React's `cardBorderRadiusVar` does. The
size-aware variable is the intent; the frame binding is a leftover. Padding, gap
and content gap all resolve to a single number per mode (8 / 12 / 16), which is
why one value drives the inset and the gap at every size.

**A Figma self-contradiction, not ported.** `Style=Subtle, State=Rest,
Layout=Default` binds `Shadow/Key` + `Shadow/Ambient`, while Subtle Hover,
Pressed, Selected, Disabled *and* its own `Layout=Custom` Rest twin bind nothing.
One shadow across six Subtle variants is an authoring slip. Subtle stays flat, as
React has it, and `card_test.dart` pins the anomaly explicitly so it is not
rediscovered as a bug.

**Present in Figma, not ported.** `State=Draggable` (every style renders as a
lifted Filled card, `Neutral/Background/1/Rest` on `shadow8`) has no counterpart
in the widget. The `Card media padding` collection has an `Inset` mode — preview
inset by 12 with its own 4px radius — where we ship only `Full`, the mode the
component pins; `Card media layout` likewise offers `Hero media` and
`Preview media` placements where we expose one `preview` slot.

## Split button and compound button — where React was wrong

Both were ported with no Figma access, from `useSplitButtonStyles.styles.ts` and
`useCompoundButtonStyles.styles.ts`. Reconciling them against the file found six
value divergences, all resolved in Figma's favour.

| | React / what we shipped | Figma (`Split button` 9026:1317, `.Secondary action` 9026:1241, `Compound button` 9026:2278) |
|---|---|---|
| Divider on Primary | `colorNeutralStrokeOnBrand`, rest only | `Neutral/Stroke/on Brand/**2**/{Rest,Hover,Pressed,Selected}` — a full ramp, and **no rule at all** when disabled |
| Divider on Subtle / Transparent | a transparent `borderRightColor` | **no stroke anywhere**, on either half, in any state |
| Chevron half | the button's size ramp plus a 24px floor | its own component with no size axis: **24 wide** at every size, `sNudge` horizontal inset, no vertical inset, a **12px** chevron (the ramp would have drawn 20) |
| Compound inset | asymmetric, `fromLTRB(8,8,8,10)` / `(12,14,12,16)` / `(16,18,16,20)` | **uniform** `Spacing/{S,M,L}` on all four sides, and the same number is the icon gap |
| Compound type ramp | steps with the size axis; Large is `subtitle2` over `body1`, and the second line is pinned to `lineHeight: 100%` | **size-invariant**: `body1Strong` (14/20) over `caption1` (12/16) in all 75 variants, each keeping its own line height |
| Compound foreground | the button's table verbatim | the first line takes `Neutral/Foreground/1/Rest` even on Subtle and Transparent, where a plain button's label is `Foreground/2/Rest`; and `Selected` resolves to the real `Foreground/{1,2}/Selected` rather than borrowing `Pressed` the way the button set does |

### Figma disagreeing with itself

Two more, carried through rather than harmonised:

- **Disabled stroke.** `Button` and `Compound button` bind
  `Neutral/Stroke/Disabled/Rest`; `.Secondary action` and the `Split button`
  halves bind `Neutral/Stroke/**Transparent**/Disabled/Rest`. We follow the
  Button table, since the divider *is* the primary half's border and forking one
  token on one state for one component is how two components drift apart.
- **Outline + Selected is 2px.** All three sets bind
  `Stroke width/Thick` there (and the chevron half keeps its shared edge at
  `Thin` so the rule does not double). `resolveFluentButtonStyle` still returns
  `FluentStroke.thin` for every state — a pre-existing `FluentButton`
  divergence, not split/compound drift, and left alone here because it belongs
  to the reference component.
- **Icon-only padding.** Figma's `Layout=Icon only` variants are square-padded
  (8 / 6 / 2 on all four sides); `resolveFluentButtonStyle` keeps the horizontal
  ramp. Also `FluentButton`'s, also left alone.

## Rating (`Rating` 9151:6563, page 8995:6)

Shipped from `useRating.tsx` / `useRatingItemStyles.styles.ts` with no Figma
access; reconciling against the 36-variant set found three divergences, all
resolved in Figma's favour.

| | React / what we shipped | Figma |
|---|---|---|
| Item spacing | no gap at all — upstream's root is a bare `display: flex`, and the optical margin is the padding inside each glyph's box | the `Shape` row is auto-layout with `itemSpacing` bound to `Spacing/Horizontal/XXS` (2) at **every** size: 5 × 28 + 4 × 2 = the 148 the XLarge row measures |
| Display fill, neutral | `colorNeutralBackground6` | `Rating color` → `Background Display` → `Neutral/Stroke/2/Rest` |
| Display fill, brand | `colorBrandBackground2` | `Rating color` → `Background Display` → `Brand/Stroke/2/Rest` |

Marigold already agreed (`Palette/Marigold/Background/2/Rest`), as did the whole
`Foreground` row (`Neutral/Foreground/1/Rest`, `Palette/Marigold/Stroke/Active/Rest`,
`Brand/Foreground/1/Rest`) and the 12/16/20/28 size ramp.

The silhouettes were also corrected. They had been traced once from the 20px
icon and scaled; Fluent draws them optically per size, so the ink width is now a
four-step table read off the Figma vectors — a circle fills 10 of a 12 box but
24 of a 28 one, and the rounded square's corner goes 2, 2.5, 3, 3.75 rather than
staying a fixed fraction.

### Where Figma is not followed

- **Forced colors.** `Background Display` cannot be used there: every stroke
  token collapses onto CanvasText, which is also the selected colour, so an
  unselected shape would be indistinguishable from a full one. The design file
  has no high-contrast mode; upstream's `@media (forced-colors)` rule
  (`color: Canvas; stroke: CanvasText`) is the authority for that one case, and
  `neutralBackground6` + `transparentStroke` is what resolves to it.
- **`Rating value` (11 modes).** Not transcribed. It is Figma authoring
  machinery: a per-size float that positions the mask revealing the filled
  layer, as `rowWidth − value`. Eight of its eleven XLarge stops land exactly on
  `index × (item + gap) + fraction × item` — which is what the painter already
  clips to — and the other three (1★ = 30 not 28, 4★ = 116 not 118) are hand
  nudges that contradict the same variable's own half-star stops. The clean
  model is the one Figma mostly agrees with.
- **The Figma component is wider than ours.** Its variant frame also carries a
  `Rating value` label — "4.5" plus a separator plus a count. That is upstream's
  separate `RatingDisplay`, not `Rating`, and `FluentRating` renders no text.

## Avatar (`Avatar/Avatar` 9278:11242, page 8911:3185)

39 variants over `Type` × `Size`, extracted to `test/fixtures/avatar.json`, plus
the `Avatar/Avatar group` (9278:11479) and `Avatar/Avatar pie` (9278:11492) sets
and four variable collections — `Avatar color` (33 modes), `Avatar shape`,
`Avatar group size` and the `Persona avatar size` table. Eight values disagree
with `useAvatarStyles.styles.ts` / `useAvatarGroupItemStyles.styles.ts`. Figma
wins in all eight.

| | React v9 | Figma / ours |
|---|---|---|
| Initials ramp at **48** | `textSubtitle2` — 16/22 (`size <= 56`) | **14/20**, `Font size/300` + `Line height/300`, i.e. `body1Strong` |
| Initials ramp at **96** | `textSubtitle1` — 20/28 (`size <= 96`) | **24/32**, `Typography/Title 3/*`, i.e. `title3` |
| Square radius | ramps `borderRadiusSmall` → `Medium` → `Large` → `XLarge` with size | **`Corner radius/Small`** at every size. The `Avatar shape` collection has two modes, `Circular` and `Rounded square`, and no size axis at all, so `Avatar corner radius` cannot ramp |
| Ring width above 64 | `strokeWidthThickest` (4) | **`Stroke width/Thicker`** (3). The hidden `Activity ring` rectangle binds Thick up to 48 and Thicker from 56 up — it never reaches Thickest |
| Ring interior | transparent; only the `::before` border paints | **`Neutral/Background/1/Rest`** fills the gap between the avatar and the ring, so the ring reads over a coloured backdrop |
| Inside stroke width | flat `strokeWidthThin` on the icon/initials slot | **1 / 2 / 3 / 4** with the size, the same ramp the variant frame's own transparent outline uses |
| Group `spread` gap, 32–56 | `spacingHorizontalL` (16) — `size < 64` | **`Spacing/Horizontal/M`** (12). At 64 and 72 React is already at `XL` (20) where Figma is at **`L`** (16); only 96 and 120 agree on `XL` |
| Pie divider | width ramps thick/thicker/thickest with size, and the rule is the group's own `colorTransparentStroke` showing between clipped slices | a real `Divider` rectangle, **`Stroke width/Thick`** (2) on all 26 variants, filled **`Neutral/Stroke/on Brand/1/Rest`** |

Everything else agrees, including the parts most likely to drift: the 13-step
size ladder, the whole `Avatar color` table (30 palette families on
`Background/2/Rest`, `Foreground/2/Rest` and `Stroke/Active/Rest`, plus
`Neutral/Background/6/Rest` + `Neutral/Foreground/3/Rest` for neutral and
`Brand/Background/1/Rest` + `Neutral/Foreground/On Brand/Rest` for brand), the
`person` glyph ladder (12, 16, 20, 24, 28, 32, 48 — never the avatar's own
edge), the group `stack` overlap table (−2, −4, −8, −16) and the ring's
geometry: Figma's rectangle inflated by one ring-width with its stroke aligned
OUTSIDE is exactly upstream's `margin: calc(-2 * ringWidth)` plus
`border-width: ringWidth`.

### Where Figma is not followed

- **The stack outline.** Figma draws overlapping avatars with nothing between
  them, which at −4 overlap is an unreadable smear. Upstream's
  `boxShadow: 0 0 0 <thick|thicker|thickest> colorNeutralBackground2` is
  transcribed instead. This is the one place a silent design file is read as an
  omission rather than a decision.
- **The pie's first slice.** Figma builds it by resizing an Avatar instance to
  half width, which squashes a circle into an ellipse. React crops the middle
  half of a full-size, square-cornered avatar and lets the group's circular clip
  make the shape; that is what we do. Every *number* (half, quadrant, 2px rule)
  is still Figma's.
- **The badge cut-out.** Figma inflates a `Badge icon` frame 2px around the
  presence badge and upstream punches a `radial-gradient` mask through the
  avatar. `FluentPresenceBadge` already paints its own `Neutral/Background/1`
  ring outside its bounds, which produces the same reading with no mask.

### Motion — verified, and it exists

`useAvatarStyles.styles.ts` declares four transitions, all of them on the
activity ring or on the avatar's own transform. There is **no** transition on
colour, size or shape.

| | Property | Duration | Curve |
|---|---|---|---|
| root `::before` (ring) | `margin` | `durationUltraSlow` (500) | `curveEasyEaseMax` |
| root `::before` (ring) | `opacity` | `durationSlower` (400) | `curveLinear` |
| root, when active/inactive | `transform` | `durationUltraSlow` (500) | `curveEasyEaseMax` |
| root, when active/inactive | `opacity` | `durationFaster` (100) | `curveLinear` |

The `inactive` rule then swaps the first curve of each pair for
`curveDecelerateMin`, so the destination decides the easing. `inactive` itself
is `opacity: 0.8` + `scale(0.875)`, with the ring at `margin: 0; opacity: 0`.
Both blocks carry a `prefers-reduced-motion` clamp to `0.01ms`, which
`FluentAnimatedStyle` already handles for every component. An avatar with
`active: unset` has no ring and therefore nothing to animate at all.

## Tag and Interaction tag

Extracted from the two biggest sets in the file — `Tag` (`9112:9115`, 60
variants) and `Interaction tag` (`9112:9659`, 168), plus the three
`.Secondary action` sets that carry the dismiss half's own hover and press.
Reconciled against `useTagStyles.styles.ts`,
`useInteractionTagPrimaryStyles.styles.ts` and
`useInteractionTagSecondaryStyles.styles.ts`.

### Motion: none, and that is the spec

All three upstream styles files declare **no transition, no animation and no
`motionTokens` reference at all**. A tag's fill changes on the frame the pointer
arrives, so neither component uses `FluentAnimatedStyle` and there is nothing
for `MediaQuery.disableAnimations` to shorten. This is the Checkbox/Tooltip
category, not an omission.

### Value divergences, all resolved toward Figma

| | React v9 | Figma / ours |
|---|---|---|
| Divider, Filled | `colorNeutralStroke1` | **`Neutral/Stroke/2/Rest`** |
| Brand foreground, hover / press | `colorCompoundBrandForeground1Hover` / `Pressed` | **`Brand/Foreground/2/Hover`** / `Pressed` |
| Filled and Brand border | `colorTransparentStroke` | **`Neutral/Stroke/Transparent/Interactive/Rest`** — identical (invisible) in light and dark; in high contrast the plain token is the text colour and the Interactive one is the highlight |
| Selected border | `colorBrandStroke1` all round | **no outer brand border at all**: selected keeps the transparent-interactive border and puts `Neutral/Stroke/on Brand/2/Rest` on the divider only |
| Dismiss half surface | no background of its own | **the primary half's ramp**, resolved against the dismiss half's own states — so it holds at rest while the primary hovers |
| Dismiss half width | padding 5 / 3 / 5 around a 12 / 16 / 20 glyph — 22 / 22 / 30 | **24 / 24 / 32** |
| Divider side | the secondary half's **left** border | the primary half's **right** border (same pixel) |

Everything else agreed: the 20 / 24 / 32 height ramp, `6 / 6 / 8` content
padding (React writes `5 / 5 / 7` plus a 1px border, which is the same
border-box number), the `XXS / XXS / XS` item gap, `borderRadiusMedium`, the
12 / 16 / 20 glyph ramp, and the whole Outline table
(`subtleBackground` × `neutralStroke1`, both fully ramped).

### Selected erases the appearance

All 60 `Tag` variants and all 168 `Interaction tag` variants bind the **same**
brand fill and `Neutral/Foreground/On Brand/Rest` when `Selected=True`,
whichever of the three styles they are. `selected` is therefore an axis on the
resolved state, not a `WidgetState`: `FluentStateColor`'s precedence is
disabled, pressed, hovered, *then* selected, so a `WidgetState.selected` tag
would lose its brand fill the moment a pointer touched it.

### A tag is inert, and its `State` axis proves it

Across all 45 unselected `Tag` variants, `Rest`, `Hover` and `Pressed` bind the
identical fill **and** the identical label colour. The only thing that moves is
the trailing dismiss glyph, which goes `Neutral/Foreground/2/Brand/Hover` — a
*brand* token. So the `State` axis on the inert set describes hovering the
dismiss affordance, not the tag, and `FluentTag` has no `onPressed`.

### Where Figma is not followed

- **Filled and Brand primary border.** Figma strokes the dismiss half on three
  sides with the transparent-interactive token but leaves the primary half's
  top, left and bottom bare (`strokeWeight` `[0,1,0,0]`), and drops the border
  entirely on the non-dismissible variants — while the inert `Tag` set strokes
  every one of its 60 variants. Carried through, a filled interaction tag would
  have no outline at all in high contrast. Both halves are squared up on
  `Neutral/Stroke/Transparent/Interactive/Rest`, the same call the Switch's
  checked track already makes.
- **Outline disabled.** Figma disagrees with itself: the dismissible variants
  paint no fill and keep `Neutral/Stroke/Disabled/Rest`, the non-dismissible
  ones paint `Neutral/Background/Disabled/Rest` and no border. The border-only
  form wins, because that is what the inert `Tag` set does too.
- **Medium, one line, no dismiss.** That one `Interaction tag` frame hugs to
  **22** where its own dismissible twin, and every `Tag` medium variant, is a
  fixed **32**. The fixed height is the intent; 22 is a missing constraint on
  one frame.
- **The `Text slot`'s 2px bottom inset.** Ported horizontally (it keeps the
  label off the media) but not vertically — that is a compensation for Figma's
  text-box metrics, the same call `FluentAccordion` makes about its
  `Text-offset` wrapper.

### Rendering note, not a token

Flutter refuses to paint a rounded rectangle whose border sides disagree
(`A borderRadius can only be given on borders with uniform colors`), which is
exactly what a half-rounded tag with a one-edge divider is. The seam is drawn
as a square-cornered foreground `Border(right:)` over the primary half instead,
and the dismiss half keeps a uniform border whose left side lands underneath it.
On Outline — where the divider and the border are the same tone — the overlay is
skipped and the dismiss half's own left border is the seam, so the rule is 1px
on every appearance.

### Present in Figma, not ported

The `Tag shape` collection has a `Circular` mode (`Corner-radius/Tag/Circular`)
alongside `Rounded`. Neither set has a `Shape` axis and all 228 variants pin
`Rounded`, so there is no `shape` parameter; `style.borderRadius` covers it.
