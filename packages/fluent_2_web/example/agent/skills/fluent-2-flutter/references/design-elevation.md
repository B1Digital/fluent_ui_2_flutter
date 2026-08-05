# Fluent 2 elevation for Flutter

Official source: [Microsoft Fluent 2 elevation](https://fluent2.microsoft.design/elevation/).

Use elevation to express perceived distance, prominence, and focus. Do not use
shadow as decoration or as the only boundary between interactive regions.

## Model depth with shadow and light

Keep a consistent apparent light direction. Sharper shadows communicate a
surface close to its background; larger, softer shadows communicate greater
distance. Fluent combines two layers:

- a sharp directional key shadow that defines the edge; and
- a soft ambient shadow at zero offset that communicates distance.

Windows may use a stroke instead of the key shadow. Preserve that platform
distinction, especially in high contrast or when a shadow cannot provide a
clear boundary.

## Use the elevation ramp

The repository exposes all six documented levels through `FluentElevation`:

| Level | Official example uses |
| --- | --- |
| `shadow2` | Close or pressed floating elements |
| `shadow4` | Cards and collection items |
| `shadow8` | Raised cards, floating actions, app or command bars, tooltips |
| `shadow16` | Menus, callouts, hover cards, and other transient surfaces |
| `shadow28` | Bottom sheets, side navigation, and raised tab bars |
| `shadow64` | Panels and pop-up dialogs |

Treat these examples as role guidance, then inspect the relevant Fluent
component reference and existing widget style. Do not automatically increase
elevation on hover unless the component behavior calls for it.

Resolve neutral elevation through the theme:

```dart
final theme = FluentTheme.of(context);

DecoratedBox(
  decoration: BoxDecoration(
    color: theme.colors.neutralBackground1,
    boxShadow: theme.shadow(FluentElevation.shadow16),
  ),
  child: child,
)
```

This preserves Fluent's key-plus-ambient pair and light/dark opacities.

## Handle colored surfaces

The same fixed shadow can appear to sit at a different height on a colored
surface. For a surface over brand color, use
`theme.brandShadow(FluentElevation...)`. For another known surface color, use
`FluentShadowLuminosity.shadowsOn(surface, level)`; it implements the official
luminosity-based opacity model.

Do not place `theme.shadow(...)` unchanged over a brand surface and do not
replace the model with a guessed black opacity.

## Preserve hierarchy and accessibility

- Use elevation only where overlapping planes or transient UI require a depth
  relationship.
- Keep z-order, hit testing, focus order, and semantic order consistent with
  the visual stack.
- Add a semantic stroke or solid boundary when shadows disappear in high
  contrast.
- Avoid clipping the shadow accidentally; clip content and shadow at different
  layers when needed.
- Avoid many large blurred shadows in scrolling regions.

## Review elevation

- Confirm the chosen level matches the component role.
- Verify both shadow layers and their direction in light and dark themes.
- Verify colored surfaces use brand or luminosity-derived shadows.
- Test high contrast without depending on blur or shadow.
- Confirm overlay order, pointer routing, focus trapping, dismissal, and focus
  restoration match the apparent depth.
