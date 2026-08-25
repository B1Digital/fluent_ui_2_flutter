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
