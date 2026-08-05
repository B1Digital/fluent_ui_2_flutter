# Fluent 2 design tokens for Flutter

Official source: [Microsoft Fluent 2 design tokens](https://fluent2.microsoft.design/design-tokens/).

Use tokens as the shared language between design and implementation. Do not
hardcode pixels, hex colors, fonts, shadows, radii, or motion values when a
Fluent token or component default expresses the intended role.

## Preserve the two layers

### Global tokens

Global tokens are context-free stored values. In this repository they include:

- color ramps: `FluentGrey`, `FluentSharedRamp`, `FluentBrandRamp`;
- size and spacing: `FluentSize`, `FluentSpacing`;
- geometry: `FluentRadius`, `FluentStroke`;
- typography primitives: `FluentFontFamily`, `FluentFontSize`,
  `FluentLineHeight`, `FluentFontWeight`;
- elevation: `FluentElevation`; and
- motion: `FluentDuration`, `FluentCurve`.

Use globals while defining shared theme, alias, or component tokens. Product
screens should usually consume semantic aliases or component styles instead.

### Alias tokens

Alias tokens add intent such as foreground, surface, stroke, status, shadow,
and interaction state. Use `FluentTheme.of(context).colors` for resolved color
aliases, `FluentColorToken` for stable token identity, the theme's
`typography`, and `theme.shadow`/`brandShadow` for bundled values.

Choose an alias by function, not by its current raw value. Preserve separate
rest, hover, pressed, selected, disabled, invalid, and focus aliases rather than
deriving states with arbitrary opacity.

## Apply theming

Use `FluentThemeData.light`, `.dark`, `.teamsDark`, and `.highContrast` to
resolve coordinated tokens. Rebrand with a complete `FluentBrandRamp`.
Override a deliberate subtree through `FluentThemeOverride`; do not scatter
local raw values through individual widgets.

High contrast intentionally changes semantic behavior and can remove brand
color. Do not calculate it by modifying a light or dark theme. Keep typography
and foreground aliases coordinated when overriding a token.

## Work across design and code

- Record the token name and semantic purpose in design specs, not only the
  rendered value.
- Map Figma/global values to repository global APIs and semantic variables to
  alias or component style APIs.
- Inspect the checked-out public barrel and generated-token provenance before
  naming a Dart API.
- Add a missing reusable value to the correct token layer and regenerate
  generated sources when required; do not edit generated token files by hand.
- Document source divergences rather than silently changing a token to match a
  screenshot.
- Keep platform ramps separate where Fluent delegates to native metrics.

## Review tokens

- Can every visual value be traced to a token, component spec, or documented
  product/grid decision?
- Is a global value kept out of ordinary widget code when an alias exists?
- Does the alias name match the role rather than the present color/value?
- Do light, dark, high contrast, brand, platform, and interaction states
  resolve together?
- Are composite values such as type and shadows kept intact?
- Do tests detect missing tokens, incorrect generation, or raw-value drift?
