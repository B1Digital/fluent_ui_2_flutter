## Unreleased

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

### Fixed

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
