# Fluent 2 motion for Flutter

Official source: [Microsoft Fluent 2 motion](https://fluent2.microsoft.design/motion/).

Use motion to explain relationships and changes, guide people toward their
goal, and add restrained personality. Never make animation a prerequisite for
understanding state.

## Apply the four motion principles

- **Functional:** reveal the next step, explain a UI change, or acknowledge an
  accomplishment.
- **Natural:** use believable inertia, weight, velocity, and continuity so the
  result is predictable.
- **Consistent:** reuse durations, curves, directions, and transition families
  across the product.
- **Appealing:** add delight only after function, comfort, and timing are
  correct.

Remove animation that has no purpose under these principles.

## Choose duration and easing

Give larger elements and longer travel slightly more time, while keeping the
interaction quick enough that people do not wait. Use the repository ramp:

| Token | Duration |
| --- | ---: |
| `FluentDuration.ultraFast` | 50 ms |
| `faster` | 100 ms |
| `fast` | 150 ms |
| `normal` | 200 ms |
| `gentle` | 250 ms |
| `slow` | 300 ms |
| `slower` | 400 ms |
| `ultraSlow` | 500 ms |

Use `FluentCurve.decelerate*` for entrances, `accelerate*` for exits,
`easyEase`/`easyEaseMax` for changes that remain on screen, and `linear` only
for constant-rate motion such as rotation. Inspect existing component motion
specs before selecting a token by eye.

## Use the four common transition families

### Enter and exit

Introduce or dismiss transient UI from within or beyond the viewport. Use it
for menus, dialogs, drawers, popovers, and similar surfaces. Preserve spatial
origin, dismissal direction, focus transfer, and focus restoration.

### Elevation

Animate a depth change to clarify press, drag, window, or hierarchy state. Keep
shadow progression aligned with `FluentElevation`; do not imply a z-order that
disagrees with hit testing or focus.

### Top level

Use a quick fade for large page or destination changes. Sliding a whole
top-level surface can imply unintended hierarchy and cause disorientation.

### Container transform

Resize or reposition a container to connect related states, including
responsive layout changes. Preserve content identity and avoid abrupt semantic
or focus-order changes during the transform.

## Choreograph related motion

Use short stagger offsets to guide gaze through a manageable collection. For a
very large group, synchronize or virtualize rather than making completion take
too long. Include the parent transition in total timing.

Give important elements clearer movement and, when justified, slightly longer
duration. Group secondary elements with synchronized timing. Avoid independent
motion in unrelated screen regions because it competes for attention.

## Make motion accessible

Read `MediaQuery.disableAnimationsOf(context)`. Collapse optional animation to
`Duration.zero` and render the correct final state immediately. Keep motion
short, natural, and local to the focused element. Avoid flashes, large sudden
movement, parallax that cannot be disabled, and animation that traps task flow.

Expose dynamic information through Flutter semantics or an appropriate live
announcement; do not rely on movement. Preserve focus and semantics while an
element fades or transforms, and dispose custom animation controllers.

## Review motion

- Can the purpose of every animation be named?
- Does size and distance justify its duration?
- Does the curve match entrance, exit, continuous, or persistent movement?
- Is the transition one of the established families or deliberately justified?
- Does choreography finish promptly and direct attention correctly?
- Is the final state immediate and complete when animations are disabled?
- Is information also available without motion, color, or sound?
