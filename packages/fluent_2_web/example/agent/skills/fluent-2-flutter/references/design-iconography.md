# Fluent 2 iconography for Flutter

Official source: [Microsoft Fluent 2 iconography](https://fluent2.microsoft.design/iconography/).

Use icons as recognizable, functional symbols. An icon must communicate a
concept, object, action, navigation destination, or state; do not add one only
to fill space.

## Choose the correct collection

### System icons

Use system icons inside UI controls, navigation, commands, and status. The
repository re-exports the MIT-licensed `fluentui_system_icons` package as
`FluentIcons`. There is no `FluentIcon` widget; render a glyph with Flutter's
widgets-layer `Icon`.

Use a regular glyph for an available action or ordinary wayfinding. Use the
matching filled glyph for a selected state or a small moment that needs more
visual weight. Do not change between unrelated metaphors when selection
changes.

Choose the size variant that exists in the icon family, for example:

```dart
const Icon(FluentIcons.settings_20_regular, size: 20)
```

A 12-pixel icon can reinforce information but is generally too small to be an
interaction. Scale the control's hit region separately from its glyph and use
`FluentTouchTarget.web`, `.ios`, or `.android` for the minimum target.

### Product launch icons

Use product launch icons only to identify or launch the corresponding Microsoft
capability. They are not the Microsoft corporate logo and must not replace it.
The system-icons dependency does not grant product-icon rights.

Below 48 pixels, use an official size-specific simplified asset instead of
shrinking a detailed master. Above 48 pixels, use the full-fidelity asset and
prefer multiples of four such as 48, 64, 96, and 192. Never recolor product
launch icons.

### File type icons

Use file type icons to identify a file or format. Official multicolor assets are
optimized around 16, 48, and 96 pixels. Supply an appropriately licensed SVG or
raster asset at a crisp target size. These assets are not bundled by this
repository.

## Apply icon construction rules

- Select by literal visual metaphor: for example, search for the object
  represented rather than the feature name.
- Add a modifier only when it makes the base metaphor more specific without
  becoming visually or semantically ambiguous.
- Use a filled modifier and place it at the bottom-right of the base icon.
- Use one semantic color for a system icon. Avoid multicolor treatment that
  destroys its visual balance.
- Keep regular and filled variants at compatible optical sizes.
- Validate symbols in every target culture; some metaphors require
  localization or replacement.
- Do not redistribute Microsoft logos, product icons, design-site illustrations,
  or fonts as if they were part of the open system-icon set.

## Make icons accessible

Decorative icons next to visible text should be excluded from semantics. An
icon-only action must expose a concise action name through the owning Fluent
control or a `Semantics` wrapper; a tooltip alone is not an accessible name.
Keep disabled, selected, expanded, checked, and busy state on the control's
semantics rather than encoding it only in the glyph.

## Review iconography

- Does the icon have a necessary semantic purpose?
- Is the collection and license correct?
- Does regular versus filled communicate availability versus selection?
- Is the glyph crisp at its intended size and contained in a large enough hit
  target?
- Does an icon-only action have an accessible name and keyboard operation?
- Does the metaphor survive localization, RTL, light, dark, and high contrast?
- Are product and file icons used without unauthorized recoloring or scaling?
