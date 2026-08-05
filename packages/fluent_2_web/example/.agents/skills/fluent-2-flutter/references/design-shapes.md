# Fluent 2 shapes for Flutter

Official source: [Microsoft Fluent 2 shapes](https://fluent2.microsoft.design/shapes/).

Use form, corner radius, fill, and stroke to create a consistent visual
vocabulary. Select a shape because it communicates a component role, not
because rounded UI is fashionable.

## Use the four forms

- **Rectangle:** default for buttons, text areas, menus, cards, images, and
  most containers.
- **Circle:** avatars and other components that represent people.
- **Pill:** slider tracks, toggle channels, tags, keywords, and selections.
- **Beak:** a pointer that associates a floating surface with one object, such
  as a callout or popover.

Distinguish a form with a semantic fill or border. Do not create a beak by
inventing geometry when the owning Fluent component already provides one.

## Map the official radius roles correctly

The official page's role labels do not map one-for-one to every repository
identifier. Use the value and component role:

| Official role | Value | Repository token |
| --- | ---: | --- |
| None | 0 | `FluentRadius.none` |
| Small | 2 | `FluentRadius.small` |
| Medium | 4 | `FluentRadius.medium` |
| Large | 8 | `FluentRadius.xLarge` |
| X-Large | 12 | `FluentRadius.xxLarge` |
| Circle/pill | fully rounded | `FluentRadius.circular` |

The repository also exposes platform/source-specific 6, 16, 24, 32, and 40
stops. `FluentRadius.large` is 6, not the official table's 8-pixel “Large”
role. Prefer the existing component default or use the value mapping above;
never infer a value from the Dart suffix alone.

Use the matching `BorderRadius` conveniences such as `allSmall`, `allMedium`,
`allXLarge`, and `allCircular` when all corners are equal. Follow native iOS
and Android guidance for mobile components.

## Know when not to round

- Remove internal corner radii where adjacent segments share one container,
  such as the joined halves of a split button.
- Do not round a component edge that meets the screen edge.
- Avoid gaps created only because neighboring shapes were rounded separately.
- Preserve a component's specified asymmetric radius during attachment,
  expansion, or directional placement.

## Apply strokes

Use `FluentStroke` and semantic stroke colors. The official web ramp is thin 1,
thick 2, thicker 3, and thickest 4 logical pixels. Mobile visual weights can
use 1, 2, 4, and 6; the repository exposes additional `hairline`, `width15`,
and `width60` tokens for verified platform/component needs.

Scale stroke weight with element size so a ring or outline retains consistent
visual weight. Use rounded stroke caps where the design calls for an open line;
avoid square caps that conflict with Fluent geometry.

For dashed strokes, scale dashes and gaps proportionally with thickness and use
the approved component/design asset. The design page presents the dash formulas
graphically; do not invent numeric ratios that are not present in the checked-
out token source.

## Preserve semantics and interaction

Shape does not replace state or semantics. Keep selected, checked, invalid,
focused, and disabled state accessible without depending on fill or outline
alone. Ensure clipping a shape does not clip focus rings, shadows, ink-free
pressed treatments, tooltips, or hit regions.

## Review shapes

- Does the form match rectangle, circle, pill, or beak usage?
- Is the radius selected by role/value rather than a misleading suffix?
- Are joined and screen-edge corners handled without gaps?
- Are stroke width, color, dashes, and caps token-based and scale-aware?
- Does the shape survive RTL, high contrast, text scaling, and every state?
- Is visual clipping separated from focus and touch-target geometry?
