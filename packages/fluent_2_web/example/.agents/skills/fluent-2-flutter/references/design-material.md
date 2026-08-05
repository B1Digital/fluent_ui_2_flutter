# Fluent 2 material for Flutter

Official source: [Microsoft Fluent 2 material](https://fluent2.microsoft.design/material/).

Material describes surface texture. Select it by surface role, platform, and
rendering capability. Fluent defines solid, acrylic, mica, and smoke; they are
not interchangeable styles.

## Select the material

| Material | Use | Flutter support in this repository |
| --- | --- | --- |
| Solid | Default opaque regions and controls | Compose with theme alias colors and elevation |
| Acrylic | Transient, light-dismiss menus and popovers | `FluentAcrylicSurface` in `fluent_2_web` |
| Mica | Windows base layer tied to desktop/window activity | No public Mica widget; report the gap |
| Smoke | Dim and block content under a modal surface | `backgroundOverlay`; built into modal overlays |

Check platform and performance limits before selecting a material. Always
provide a readable solid fallback when backdrop sampling, blur, compositing, or
transparency is unavailable or inappropriate.

## Solid

Use solid most often. It combines an opaque semantic color with optional
elevation to distinguish regions and interaction. Resolve light/dark-aware
surface, foreground, and stroke aliases from `FluentTheme.of(context).colors`.
Do not treat plain white or black as universal Fluent surfaces.

## Acrylic

Use acrylic for transient, light-dismiss surfaces such as popovers and menus.
It is a blurred backdrop with mode-aware translucent tints and a gradient
hairline. In web Flutter, use `FluentAcrylicSurface`; customize it with
`FluentAcrylicSurfaceStyle` or `FluentAcrylicSurfaceTheme`.

The core `FluentAcrylic` class is a token bundle, not a widget. The separate
`FluentWindowsAcrylic` class describes WinUI effect-graph constants and is not a
substitute for `FluentAcrylicSurface`.

`FluentAcrylicSurface` already bounds the backdrop blur, halves the published
blur radius into Flutter's Gaussian sigma, paints both tints in order, and
falls back to an opaque surface for high contrast. Do not rebuild that pipeline
with an unbounded `BackdropFilter`. Prefer one larger acrylic layer to many
small layers because backdrop filters are expensive.

## Mica

Use Mica only as a Windows base-layer treatment. On an active window it is
subtly tinted by the desktop background; on an inactive window it becomes
neutral. It supports light and dark modes through the Windows compositor.

The current Flutter packages expose no `FluentMica` widget or public Mica token
recipe. Do not invent one and do not rename acrylic as Mica. Use an opaque
semantic base surface as a fallback or integrate a verified platform-native
implementation behind a Windows capability boundary.

## Smoke

Use smoke beneath a modal component to dim the rest of the interface and signal
that interaction below is blocked. It is always translucent black rather than
mode-aware.

Prefer `FluentDialog`, modal `FluentDrawer`, or another component that already
owns its barrier behavior. For a custom modal overlay, use
`FluentTheme.of(context).colors.backgroundOverlay`, block hit testing below,
trap focus only while modal, support Escape/system back as appropriate, and
restore focus to the trigger.

## Review material

- Does the material match the surface role and target platform?
- Does solid mode preserve foreground and boundary contrast?
- Is acrylic transient, clipped, performant, and replaced by a solid high-
  contrast fallback?
- Is Mica used only through verified Windows support?
- Does smoke actually block interaction and expose modal semantics?
- Do light, dark, high contrast, reduced transparency, low-power, and missing
  backdrop cases remain usable?
