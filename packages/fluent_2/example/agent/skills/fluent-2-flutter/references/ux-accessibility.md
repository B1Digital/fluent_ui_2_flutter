# Fluent 2 accessibility for Flutter

Official source: [Microsoft Fluent 2 accessibility](https://fluent2.microsoft.design/accessibility/).

Design for different backgrounds, perspectives, and abilities from the first
wireframe. Use Fluent components as an accessible foundation, then verify that
the product's composition, content, navigation, and state remain operable.

## Structure, hierarchy, and navigation

Organize information in a logical, predictable hierarchy. Use semantic type
roles, headings, color, dividers, and spacing to show relationships without
mixing heading levels or using large text as decoration.

In Flutter, keep widget, visual, focus, and semantic order aligned. Add
`Semantics(header: true)` for real headings and use `MergeSemantics` or
`ExcludeSemantics` only after checking the resulting screen-reader output.

## Keyboard and assistive technology

Make every action reachable and operable with keyboard and assistive
technology. Keep focus visible, follow the reading flow, and restore focus to
the trigger after a dialog, menu, drawer, popover, or other temporary UI closes.
Trap focus only for a modal surface.

Use `FocusTraversalGroup`, `FocusTraversalOrder`, `Shortcuts`, `Actions`, and
`FocusableActionDetector` when built-in Fluent behavior is insufficient. Do not
paint a focus ring on an unfocusable object or attach semantics to an action
that cannot be invoked.

## Color and contrast

- Keep standard text contrast at least 4.5:1.
- Keep large text at least 3:1. The source defines large as above 18.5 pixels
  bold or 24 pixels regular.
- Keep interactive controls, icons, and other meaningful non-text UI at least
  3:1 against adjacent colors.
- Never communicate status, selection, validity, or focus through color alone.

Use Fluent semantic aliases and verify light, dark, and
`FluentThemeData.highContrast()`. Treat high contrast as a distinct system
mode, not a darker brand palette.

## Responsive layouts

Preserve information and operation across portrait/landscape preferences,
platform scaling, and zoom. Reflow without ordinary horizontal scrolling at
400% browser zoom, design down to 320 logical pixels, and support 200% text
zoom without clipping. Test Android devices because manufacturer scaling can
vary.

## Media and alternatives

Give meaningful images, charts, graphics, audio, and video equivalent text or
audio alternatives. Exclude decorative media from semantics. Provide captions
and transcripts for time-based media; allow caption contrast customization or
use sufficient contrast when customization is not possible.

Use `Semantics(label: ...)` around a meaningful custom visual and make complex
charts available as structured text or data. An icon tooltip is not a complete
text alternative for an icon-only action.

## Meaningful text and semantic code

Use concise, consistent, descriptive language. Prefer semantic widgets and
Flutter's semantics tree over visual-only custom painting. On web, verify the
generated accessibility tree and browser keyboard behavior; do not assume a
Flutter `Semantics` node produces every ARIA pattern automatically.

Use one owner for each dynamic announcement. If a Fluent component already
creates a live region for its message or validation state, do not wrap it in a
second live region that repeats the same content.

## Specify and test accessibility

Document heading structure, names, roles, values, states, focus order, initial
focus, keyboard commands, announcements, modal boundaries, and focus return in
the design handoff—not only dimensions and colors.

Test keyboard-only use, screen readers on target platforms, text/braille
output where relevant, light/dark/high contrast, reduced motion, bold/large
text, 320-pixel reflow, 400% zoom, RTL, localization, and media alternatives.
Inspect Flutter semantics tests as well as the rendered accessibility tree.
