# Fluent 2 layout for Flutter

Official source: [Microsoft Fluent 2 layout](https://fluent2.microsoft.design/layout/).

Use space to express relationships, hierarchy, and focus. Prefer proximity and
empty space over extra rules or containers when grouping alone communicates the
structure.

## Use spacing and proximity deliberately

Place related elements closer together and separate unrelated groups. Repeat a
spacing pattern to communicate equal weight and connection. Give a primary
region enough surrounding space to be discoverable, but avoid density that
overwhelms or empty space that separates content that belongs together.

Fluent's multi-platform spacing system is based on four units. The 2, 6, and 10
stops deliberately compensate for icon geometry and alignment; do not round
them away. Measure from an element's bounding box.

Use:

- `FluentSpacing` for semantic web spacing aliases from `xxs` through `xxxl`;
- `FluentSpacing.horizontal` and `.vertical` where axis intent matters; and
- `FluentSize` for the complete shared logical-size ramp.

These values are Flutter logical pixels. Interpret them as CSS pixels on web,
points on iOS, and density-independent pixels on Android while allowing the
platform to handle device pixel density.

## Build responsive structure

Use `LayoutBuilder` constraints for the space a widget actually receives. Use
`MediaQuery` for viewport preferences such as text scale, high contrast,
reduced motion, padding, and input capabilities. Do not infer interaction mode
from width or device name.

The repository's `FluentBreakpoint` ranges are:

| Size class | Logical width |
| --- | ---: |
| `small` | 320–479 |
| `medium` | 480–639 |
| `large` | 640–1023 |
| `xLarge` | 1024–1365 |
| `xxLarge` | 1366–1919 |
| `xxxLarge` | 1920 and above |

Use `FluentBreakpoint.of(constraints.maxWidth)` when the design changes by size
class. Fluent describes a 12-column grid, but does not prescribe one universal
margin and gutter for every breakpoint. Choose those values deliberately as
multiples of four and document them instead of inventing official tokens.

## Reflow instead of shrink

- Let rows wrap, stack, or become scrollable content regions before labels
  clip or controls fall below their usable size.
- Keep ordinary reading flows free of essential horizontal scrolling.
- Preserve visual, semantic, and keyboard reading order when columns move.
- Use `start`/`end`, `AlignmentDirectional`, and `EdgeInsetsDirectional` so
  directional layout mirrors under RTL.
- Keep nondirectional media, charts, clocks, and brand marks unmirrored.
- Allow localized copy and dynamic text to determine height.
- Use `SafeArea` or `MediaQuery.paddingOf` where system intrusions matter.

## Preserve target sizes

Use at least `FluentTouchTarget.web` or `.ios` (44 logical pixels) and
`FluentTouchTarget.android` (48 logical pixels) for interactive regions unless
stricter platform guidance applies. A glyph or visible control may be smaller;
expand padding and semantics without creating overlapping hit targets.

## Review layout

- Check 320 logical-pixel width, every defined breakpoint, and very wide
  windows.
- Check 200% text scaling and 400% browser zoom.
- Check long localized copy, RTL, keyboard focus order, and screen-reader order.
- Check safe areas, on-screen keyboard insets, scroll reachability, and focus
  visibility.
- Confirm every spacing and size value comes from a token or an explicitly
  documented component/grid decision.
- Reject fixed English-sized widths, clipped text, overlapping targets, and
  breakpoint logic that assumes all users have one input method.
