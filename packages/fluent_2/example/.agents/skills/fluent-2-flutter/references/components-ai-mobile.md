# Fluent AI and mobile

The official site documents Fluent AI patterns and native iOS/Android subsets,
but this repository currently exports no dedicated AI widgets and may export no
mobile component widgets. Use these pages as product guidance, not evidence
that a Dart class exists.

## Contents

- AI route coverage
- AI composition rules
- iOS route coverage
- Android route coverage
- Flutter platform strategy

## AI route coverage

| Official pattern | Flutter status |
| --- | --- |
| Chat input | Compose; no dedicated widget |
| Chat input attachment | Compose; no dedicated widget |
| Chat input suggestions | Compose; no dedicated widget |
| Chat output | Compose; no dedicated widget |
| Citations and references | Compose; no dedicated widget |
| Copilot message | Compose; no dedicated widget |
| User message | Compose; no dedicated widget |
| Sensitivity | Compose; no dedicated widget |
| Timestamp | Compose; no dedicated widget |
| Copilot first-run experience | Missing |
| Entity cards | Compose from cards and content |
| Ghost text | Missing specialized behavior |
| Prompt starters | Compose from buttons/cards |
| System message | Compose from message/status surfaces |

## AI composition rules

- Distinguish user, assistant, system, error, and tool-generated content through
  semantics and structure, not color alone.
- Keep generated content attributable. Make citations keyboard reachable and
  connect citation markers to their sources.
- Represent streaming and pending states without moving focus or repeatedly
  announcing every token.
- Give attachment upload, cancel, retry, and removal separate accessible
  actions.
- Make prompt suggestions optional and editable; do not imply that examples are
  the only valid prompts.
- Label generated-content limitations and sensitivity states near the content
  they affect.
- Preserve selection, copy, link, and text-scaling behavior in chat output.
- Treat destructive tool actions as explicit confirmation workflows.

Use existing `FluentInput`, `FluentButton`, `FluentCard`, `FluentMessageBar`,
`FluentProgressBar`, `FluentSpinner`, `FluentTag`, `FluentTooltip`, and overlay
widgets only after verifying their roles fit the pattern. Composition does not
create an official `FluentChat*` API.

## iOS route coverage

The official Fluent iOS subset currently indexes activity indicator, avatar,
avatar group, button, card nudge, heads-up display, navigation bar, progress
bar, segmented control, shimmer, text field, and tooltip.

Treat these as UIKit/AppKit guidance. Check the `fluent_2` barrel before using a
Dart equivalent. Preserve iOS navigation, focus, text editing, Dynamic Type,
VoiceOver, and the 44x44 minimum target when composing a missing control.

## Android route coverage

The official Fluent Android subset currently indexes avatar, avatar group,
button, progress indicator, and shimmer.

Treat these as native Android guidance. Check the `fluent_2` barrel before
using a Dart equivalent. Preserve Android back behavior, text scaling,
TalkBack, keyboard/access-switch input, and the 48x48 minimum target.

## Flutter platform strategy

1. Inspect the target package barrel.
2. If a native Flutter component exists, use and test it.
3. If only the web widget exists, do not silently use its compact pointer
   geometry on mobile.
4. Share model, state, semantics, and tokens; allow platform-specific renderers
   for geometry and interaction.
5. If composition is in scope, implement with raw Flutter primitives and core
   tokens, then test on the actual target platforms.
6. If composition is not in scope, report the missing component and stop before
   inventing an API.

Do not use Material or Cupertino as an invisible fallback in a repository that
explicitly forbids those libraries.
