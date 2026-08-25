# Fluent 2 design language

## Contents

- Principles
- Tokens and theming
- Detailed design-language references
- Accessibility
- Flutter review checklist

## Principles

Microsoft defines four Fluent principles. Use all four as a decision gate, not
as decorative aspirations.

### Natural on every platform

Make interactions behave as people expect on the target platform so the
experience feels dependable. Preserve native navigation, input, dismissal,
selection, and system-back conventions. Adapt Fluent visuals without forcing a
web interaction model onto iOS or Android.

In Flutter, branch on capabilities and platform rather than screen width alone.
Treat pointer hover, keyboard traversal, touch targets, text scaling, high
contrast, and system navigation as independent concerns. If Fluent appearance
conflicts with established platform behavior, preserve the behavior.

### Built for focus

Help people remain in their task flow. Give the primary action and current
content clear hierarchy; remove redundant decoration, competing emphasis, and
avoidable interruptions. Technology should enable the task instead of becoming
the task.

In Flutter, use semantic tokens and spacing to establish hierarchy before
adding borders, shadows, or brand color. Keep loading, validation, navigation,
and confirmation close to the action they affect. Do not add motion, surfaces,
or controls without a user-task reason.

### One for all, all for one

Include a range of abilities and perspectives from the start. Accessibility is
an input to component selection, layout, content, interaction, and testing—not
a repair pass after the visual design is finished.

In Flutter, provide meaningful semantics, logical traversal, keyboard and
assistive-technology operation, sufficient targets and contrast, non-color
cues, scalable text, RTL behavior, localization headroom, and reduced motion.
Test these constraints early because they often produce a better layout for
everyone.

### Unmistakably Microsoft

Create continuity with the Microsoft product family through deliberate Fluent
signature experiences: semantic color, type hierarchy, iconography, materials,
motion, and component behavior. Recognition should come from a coherent system,
not from covering the interface in brand color or copying protected assets.

In Flutter, use the repository's Fluent themes, alias tokens, widgets, and
licensed system icons consistently. Reserve stronger brand treatment for
meaningful identity and key moments. A small amount of personality is more
effective than decorative imitation.

### Resolve tradeoffs

When the principles pull in different directions, protect platform-native
behavior, inclusion, and task focus before decorative brand expression. During
review, ask:

- Does this behave naturally for this platform and input method?
- Does it keep attention on the user's goal?
- Can people with different abilities, languages, and preferences complete it?
- Does it feel coherently Fluent without unnecessary branding?

Source: [Microsoft Fluent 2 design principles](https://fluent2.microsoft.design/design-principles/).

## Tokens and theming

Use the two-layer Fluent token model:

- Global tokens store context-free ramps and measurements.
- Alias tokens express intent such as foreground, surface, stroke, status, or
  interaction state.

Consume aliases in widgets. Keep global values inside the theme/token layer.
This allows light, dark, high-contrast, and branded themes to change without
rewriting component logic.

In Flutter:

- Read values from `FluentTheme.of(context)` and shared token classes.
- Apply `FluentThemeOverride` to a subtree when only a small token set changes.
- Keep hover, pressed, selected, disabled, and focus colors explicit.
- Never derive a semantic state with arbitrary opacity when a state token
  exists.
- Test light, dark, and high-contrast variants after any visual change.

## Detailed design-language references

Load only the topic needed for the current decision:

- [Color](design-color.md): neutral, shared, semantic, and brand palettes;
  theme and interaction-state resolution.
- [Elevation](design-elevation.md): depth, two-layer shadows, low/high ramps,
  colored surfaces, and platform boundaries.
- [Iconography](design-iconography.md): system, product-launch, and file icons;
  size, theme, modifiers, color, licensing, and localization.
- [Layout](design-layout.md): spacing, proximity, responsive structure, grids,
  reflow, directional layout, and touch targets.
- [Material](design-material.md): solid, acrylic, Mica, and smoke, including
  platform support and fallbacks.
- [Motion](design-motion.md): principles, duration, easing, transitions,
  choreography, and accessible reduced motion.
- [Shapes](design-shapes.md): rectangle, circle, pill, beak, radius mapping,
  strokes, caps, and adjacency rules.
- [Typography](design-typography.md): platform font stacks, semantic type ramp,
  hierarchy, scaling, localization, and fallbacks.

## Accessibility

Build accessibility into structure and behavior:

- Keep headings and semantic groups in a logical hierarchy.
- Support keyboard traversal and screen-reader operation for every action.
- Make focus order follow the visual reading flow and restore focus to the
  trigger after a dialog, menu, or popover closes.
- Trap focus only for truly modal surfaces.
- Provide names for icon-only actions and text alternatives for meaningful
  imagery.
- Keep error and status messages available to assistive technology.
- Ensure disabled state is understandable and not represented by opacity alone.
- Test with large text, RTL, high contrast, reduced motion, keyboard-only input,
  and a screen reader.

Use Flutter `Semantics`, `Focus`, `FocusTraversalGroup`, `Shortcuts`, `Actions`,
and `FocusableActionDetector` deliberately. A painted focus ring without focus
behavior is incomplete; semantics without operability is also incomplete.

## Flutter review checklist

- Are all values tokens or component-defined constants?
- Does the component render in light, dark, and high contrast?
- Are rest, hover, press, focus, selected, disabled, invalid, and loading states
  distinct where applicable?
- Can every action be reached and activated by keyboard and assistive tech?
- Does focus return correctly after transient UI closes?
- Does the layout survive 320px width, 200% text, RTL, and long localization?
- Are touch targets large enough for the target platform?
- Is reduced motion honored without losing information?
- Does status have a non-color cue?
- Are icons licensed, semantic, correctly sized, and labeled when icon-only?
