# Fluent 2 typography for Flutter

Official source: [Microsoft Fluent 2 typography](https://fluent2.microsoft.design/typography/).

Use typographic hierarchy to organize content and help people scan, navigate,
and understand an experience. Select a semantic role from the platform ramp;
do not assemble isolated sizes and weights per screen.

## Use the platform font stack

Segoe UI is Microsoft's signature typeface for Windows and Fluent web, but
Fluent uses native system type on each platform for familiarity and
accessibility.

The repository exposes:

- `FluentTypography.web()` using Segoe UI with web/system fallbacks;
- `FluentTypography.ios()` using the San Francisco system family; and
- `FluentTypography.android()` using Roboto and Android tracking where needed.

`FluentThemeData.from`, `.light`, `.dark`, and `.highContrast` select a ramp
from the target platform. Override the platform only when testing or building a
deliberately platform-specific surface. Do not bundle or redistribute Segoe UI;
allow the configured fallback stack to resolve when it is not installed.

Use `FluentFontFamily.monospace` for code-like content and
`FluentFontFamily.numeric` when tabular numeric figures are required. Confirm
the chosen fonts are available or accept their fallbacks.

## Use the semantic type ramp

Read styles from `FluentTheme.of(context).typography`:

| Purpose | Available styles |
| --- | --- |
| Supporting text | `caption2`, `caption2Strong`, `caption1`, `caption1Strong`, `caption1Stronger` |
| Reading text | `body1`, `body1Strong`, `body1Stronger`, `body2`, `body2Strong` |
| Section hierarchy | `subtitle2`, `subtitle2Stronger`, `subtitle1` |
| Page hierarchy | `title3`, `title2`, `title1`, `largeTitle`, `display` |

Use stronger variants to emphasize within one semantic level. Move to a title
role only when the content's structural level changes. Keep headings in a
logical order and add `Semantics(header: true)` when the Flutter structure does
not already expose heading intent.

The global `FluentFontSize`, `FluentLineHeight`, and `FluentFontWeight` ramps
exist for token/component authors. Product screens should consume the semantic
`FluentTypography` styles so platform metrics, line height, foreground color,
and future theme changes stay coordinated.

## Compose text correctly

- Let `FluentApp` provide the default body style and override locally with
  `DefaultTextStyle` or a `Text` style from the current theme.
- Preserve line height and leading from the semantic style; do not replace it
  with a raw font size.
- Use sentence case and concise labels. Do not use capitalization or color as
  the only hierarchy cue.
- Avoid fixed-height text containers and fixed widths tuned to English.
- Keep labels visible after input; a placeholder is not a field label.
- Use `TextAlign.start`, directional padding, and locale-aware line breaking.
- Allow user text scaling; do not clamp it merely to preserve a screenshot.
- Use `TextOverflow` only when loss is acceptable and provide access to the full
  content where needed.

## Handle platform and content differences

Do not force the web ramp onto native iOS or Android UI. Dynamic Type, Android
font scaling, script-specific glyph metrics, bold-text preferences, and font
fallback can change wrapping and height. Test actual localized scripts rather
than assuming Latin metrics.

For custom text roles, start from the closest semantic style with `copyWith`
and preserve its family, fallback, height, weight intent, and theme color. If a
new role repeats across components, add it to the shared token model rather than
duplicating it.

## Review typography

- Is every style tied to a semantic role and the correct platform ramp?
- Is hierarchy visible through structure, size, weight, and spacing—not color
  alone?
- Do headings and reading order make sense to assistive technology?
- Does content survive 200% text scale, 400% web zoom, bold text, RTL, and long
  localization without clipping or overlap?
- Are system font fallbacks and missing Segoe handled safely?
- Are line height, truncation, and numeric/monospace choices deliberate?
