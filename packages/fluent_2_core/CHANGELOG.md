## 0.0.3

### Added

- **`FluentScrollBehavior` now supplies a scrollbar.** `buildScrollbar` returned
  its child unchanged, on a doc comment claiming Fluent drew its own scrollbar in
  the UI packages — it did not. `fluent_2` contained no scrollbar at all,
  `FluentColors.scrollbarOverlay` (upstream `colorScrollbarOverlay`) was
  referenced by nothing, and the showroom had to hand-roll a `RawScrollbar` with
  a hardcoded thumb colour to get one. Every consuming app inherited a
  scrollbar-less UI with no way to opt back in short of replacing the class.
  It is now a `RawScrollbar` — from `package:flutter/widgets.dart`, so still no
  Material dependency — painted in `colorScrollbarOverlay`, on vertical
  scrollers on desktop platforms only. **This is a visible change in every app
  using `FluentApp`.** Pass your own `scrollBehavior` to opt out.

### Added

- **React parity is now pinned by a test.** `test/token_parity_test.dart`
  checks all 228 alias tokens across the four theme variants against a
  machine-generated snapshot of the real `@fluentui/react-theme` themes
  (`test/fixtures/react_tokens.json`, regenerated with
  `node tool/dump_react_tokens.js`). It asserts three things: every token with a
  React counterpart matches it; the **deliberate** divergences are exactly the
  pinned ones — a divergence that *disappears* fails just as loudly as one that
  appears, so nobody diffing against React can quietly restore the
  black-on-black high contrast foregrounds; and the Dart-only tokens are pinned,
  so adding one is a conscious act rather than a typo that is never compared
  against anything.

### Fixed

- **Four status colours did not match Fluent UI React v9.** Diffed all 228 alias
  tokens across the four theme variants against `@fluentui/react-theme` (9.2.1,
  re-checked against 9.2.2): 860 of 864 values matched. The four that did not
  were transcription slips in the **dark** column only —
  `colorStatusSuccessForegroundInverted` (both brightnesses),
  `colorStatusWarningForeground1`, `colorStatusWarningForeground3` and
  `colorStatusWarningBorder1` — where the dark warning ramp had values in the
  wrong slots (dark `WarningForeground3` held React's *light* `WarningBorder1`
  value). Now matches React exactly.

  The remaining four differences are deliberate and stay: in high contrast,
  `colorNeutralForegroundInverted` and its hover/pressed/selected siblings are
  white where React is `#000000`. React's value pairs black on a black
  `colorNeutralBackgroundInverted`, which renders every inverted surface —
  tooltip, popover, teaching popover — outlined but empty. See the note at
  `tokens/theme_variants.dart:252`.

  Also confirmed: 12 Dart tokens have no React counterpart
  (`colorStatusSevere*`, `colorStatusAvailableForeground3`,
  `colorStatusAwayBackground3`, `colorStatusOofForeground3`). These are genuine
  extensions backing `FluentPresenceBadge` and the severe ramp — React sources
  those at component level rather than promoting them to theme aliases.

- **`FluentPageRoute` no longer allocates a `CurvedAnimation` per frame.**
  `buildTransitions` runs from the route's own `AnimatedBuilder`, so every frame
  of a transition built — and never disposed — a new curve holding a status
  listener on its parent. It is now built once and disposed with the route.
- **`FluentThemeOverride` no longer takes a theme dependency when it has nothing
  to override.** It read the ancestor theme before its own early return, so a
  no-op override rebuilt its whole subtree on any ancestor theme change.

## 0.0.2

- Use the Fluent 2 project logo as the pub.dev thumbnail.
- Require `fluent_2_fonts` 0.0.2.

## 0.0.1

- Initial release: Fluent 2 token tables (color, typography, spacing, radius,
  stroke, elevation, motion), `FluentTheme` / `FluentThemeData`, `FluentApp`,
  the light / dark / teamsDark / highContrast variants, and a Dart port of the
  Theme Designer brand-ramp generator.
- Use the open-source Selawik family from `fluent_2_fonts` for the web and
  Windows typography ramp instead of selecting Segoe UI.
- Select distinct Web, Windows, macOS, iOS, and Android typography metrics and
  expose `fontPlatform` for explicit previews.
- Preload the build-selected dynamic font before `FluentApp` paints.
