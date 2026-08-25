# Fluent 2 color for Flutter

Official source: [Microsoft Fluent 2 color](https://fluent2.microsoft.design/color/).

Use color to establish hierarchy, communicate meaning, and create consistent
product identity. Select colors by semantic role; do not copy a swatch because
it looks similar.

## Use the three Fluent palettes

### Neutral

Use black, white, and gray for surfaces, text, strokes, layout structure, and
many interaction states. Create hierarchy by placing lighter neutral surfaces
around the area of primary focus rather than branding every important region.

In Flutter, read neutral aliases from `FluentTheme.of(context).colors`, such as
`neutralBackground1`, `neutralForeground1`, and state-specific hover, pressed,
selected, disabled, and stroke aliases. Use `FluentGrey` only while defining a
token; ordinary widgets should not select raw ramp stops.

### Shared

Use shared colors for concepts that must remain recognizable across Microsoft
experiences, including avatars, calendars, badges, presence, and status. Apply
them sparingly. Their light and dark values differ so saturation and brightness
remain comfortable and accessible.

Use `FluentSharedColor` with `FluentSharedRamp.all` for raw shared ramps. Resolve
semantic palette roles through `FluentTheme.of(context).colors.palette` with a
`FluentPaletteFamily`; this returns a brightness-aware `FluentPaletteColors`.
Prefer an existing component or palette alias over choosing a shared shade
directly.

Semantic colors are the status-bearing subset. Reserve them for feedback,
urgency, or state—not decoration. Pair danger, warning, success, and
informational color with text, an icon, shape, or semantics so meaning never
depends on color alone.

### Brand

Use brand color for product identity and primary emphasis. Keep neutral color
dominant enough to preserve hierarchy. Rebrand by providing a complete
`FluentBrandRamp` to `FluentThemeData.light` and `.dark`, not by replacing
individual component colors throughout the tree.

Use `FluentBrandRamp.web`, `.teams`, `.teamsV21`, `.office`, or
`.communicationBlue` when matching those shipped ramps. Use
`FluentBrandRamp.fromKeyColor` for a custom brand and review every generated
stop; the generator does not reproduce Microsoft's hand-authored ramps.

## Follow the Flutter token layers

| Need | Flutter API |
| --- | --- |
| Theme-aware semantic color | `FluentTheme.of(context).colors` |
| Stable token identity | `FluentColorToken` |
| Subtree override | `FluentThemeOverride` |
| Neutral global ramp | `FluentGrey` |
| Shared global ramps | `FluentSharedRamp` |
| Brand ramp | `FluentBrandRamp` |
| Light/dark/high contrast | `FluentThemeData.light`, `.dark`, `.highContrast` |

Keep global ramps context-free and keep alias tokens role-based. A component
should consume aliases for foreground, background, stroke, status, interaction,
and shadow. Add a missing semantic token to core rather than embedding a raw
`Color` or opacity calculation in a widget.

## Implement state and theme behavior

- Resolve rest, hover, pressed, focused, selected, disabled, and invalid colors
  independently when those states exist.
- Treat focus as a keyboard affordance, not another hover shade.
- Use the correct foreground-on-brand or inverted alias instead of assuming
  white text.
- Keep theme changes reactive through `FluentTheme`; do not cache resolved
  colors across brightness changes.
- Use `FluentThemeData.highContrast()` when high contrast is requested. Brand
  color is intentionally absent from that theme.
- Use `FluentThemeOverride(colors: {...})` for a deliberate local exception and
  document why the semantic role changes.

## Review color

- Verify light, dark, Teams dark where applicable, and high contrast.
- Check text contrast, non-text contrast, and every interactive state.
- Confirm that status and selection still make sense in grayscale and to a
  screen reader.
- Check shared and semantic color usage for cultural or product-specific
  meaning.
- Reject decorative semantic color, raw hex values in widgets, arbitrary
  opacity states, and hardcoded light-theme assumptions.
