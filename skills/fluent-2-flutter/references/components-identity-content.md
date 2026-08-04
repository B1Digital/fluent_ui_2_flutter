# Identity and content

Use this reference for people and groups, status, editable values, text, icons,
and images.

## Contents

- Avatar and avatar group
- Persona
- Badge, presence badge, and status indicator
- Tag and interaction tag
- Text
- Icon
- Image

## Avatar and avatar group

### Avatar — `FluentAvatar`, `FluentPresenceBadge`

Source: https://fluent2.microsoft.design/components/web/react/core/avatar/usage/

Use an avatar to represent a person or a real group. Standard circular avatars
generally represent individuals; square group avatars represent teams,
organizations, or companies. Prefer a meaningful image, then initials, then a
generic identity fallback. Use avatar group when several identities must be
shown together.

Presence badges indicate current availability; activity rings indicate active
shared behavior such as speaking or typing. Add either only when it matters to
the task and pair it with text semantics. Presence icons on medium (32-pixel)
and smaller avatars can be difficult to perceive, so provide visible text or a
hover/focus tooltip.

`FluentAvatar` accepts a name/identity semantic label, but its nested presence
badge does not expose a separate localized label through the avatar constructor.
When localized combined status is required, wrap/exclude semantics deliberately
or compose a separately labeled `FluentPresenceBadge`; do not accept its English
fallback silently.

Avatars are static by default. If an avatar opens information or performs an
action, author hover/pressed/focus/disabled states, add it to keyboard focus,
name the action, and make the hit target adequate. Do not use a human-looking
avatar to personify an AI system; distinguish AI identity, capability, memory,
and autonomy explicitly as described in the Working with AI reference.

### Avatar group — `FluentAvatarGroup`

Source: https://fluent2.microsoft.design/components/web/react/core/avatargroup/usage/

Choose spread for the default readable arrangement, stack for a denser overlap,
and pie for two or three identities in extremely limited space. Spread and
stack support activity rings; spread also supports presence; pie supports
neither. Keep stable ordering.

When more than five identities exist, use the fifth slot as an exact overflow
count that opens a complete named list. The overflow control is interactive
even when the individual avatars are not, so give it keyboard focus, a clear
name, and a managed popup. Provide text equivalents for small presence badges
and avoid exposing an unlabeled pile of images.

The current `FluentAvatarGroup` neither limits members nor calculates overflow.
The app must select the visible identities and compose an overflow-colored
`FluentAvatar` with `+n` inside a real interactive control and popup. Its group
layout currently uses physical `left` positioning and lacks RTL tests; verify
directionality and do not claim RTL parity until it is fixed or tested.

The shipped gallery includes a bot-like agent inside a people group. That
example predates and conflicts with the Responsible AI identity rule; do not
copy it. Official guidance and the skill's non-negotiable AI distinction take
precedence over a gallery composition.

## Persona — `FluentPersona`

Source: https://fluent2.microsoft.design/components/web/react/core/persona/usage/

Use persona when an identity needs an avatar/presence plus up to four short
lines such as name, role, or contact context. In dense layouts, presence-only
may place the badge near the name without an avatar. Text slots wrap instead of
truncating and should be at-a-glance words or phrases in sentence case without
periods. Put richer information in a deliberate popover.

Personas are static by default. If the composite becomes interactive, author
all states, give it a focus outline and keyboard position, and avoid making the
whole row one action when it contains independent actions.

## Badge, presence badge, and status indicator

### Badge — `FluentBadge`

Source: https://fluent2.microsoft.design/components/web/react/core/badge/usage/

Use a badge as a short status, description, or count for nearby content. Place
it on or close enough to its subject that the association is obvious. Keep one
size within a context. Color should direct attention by priority; pair warning
or danger with a way to resolve the state. Badges have no maximum width, so set
and test deliberate truncation rather than letting them grow unpredictably.

Use one or two sentence-case words. An icon-only badge needs an accessible name,
or its information must be included in the associated component's name. Badges
are static by default; if a tooltip or action makes one focusable, provide full
focus and keyboard behavior. Never use color alone.

### Presence badge — `FluentPresenceBadge`

Use presence only for current availability that materially supports
collaboration. Expose a readable status, state data freshness honestly, and
follow the Avatar small-size warning above.

### Status indicator — `FluentStatusIndicator`

This repository extension represents a semantic state. Pair the visual with
text or a semantic label, choose a status token, and never reuse the same
appearance as meaningless decoration.

## Tag and interaction tag

### Tag and interaction tag — `FluentTag`, `FluentInteractionTag`

Source: https://fluent2.microsoft.design/components/web/react/core/tag/usage/

Use a tag for a value selected by a person; use a badge for system-generated,
noneditable data. A plain tag is informational with optional dismissal. An
interaction tag may expose one primary action related directly to the represented
object; its secondary action, when present, is dismissal. Never add unrelated
or disruptive actions.

Enable dismissal to let someone undo a choice. A nondismissible tag means the
value is not editable in this state, while keeping the pattern recognizable for
a later editable state. Tags wrap by default. Alternatively, an interaction tag
with `+n` may reveal the exact overflow list. Choose wrapping when people need
to scan or edit every value. Do not truncate tag content in the ordinary tag
pattern. Use token spacing equivalent to at least 4, 6, and 8 pixels between
extra-small, small, and medium tags.

Text should come from the represented data or exact unmatched input, with the
most recognizable primary value shown first. Name every dismiss action and keep
selected/dismissible states perceivable without color. `FluentTagDismissGlyph`
is a low-level building block, not a complete control.

## Text — compose with `Text` and Fluent typography

Source: https://fluent2.microsoft.design/components/web/react/core/text/usage/

Official Fluent Text codifies the semantic typography presets; this repository
composes Flutter `Text` with the current Fluent theme/type tokens rather than
exporting a separate `FluentText`. Use plain text for content and `FluentLink`
for navigation. Choose a semantic role before a size, preserve the platform
font fallback, text scaling, selectable behavior where expected, and the
repository typography tokens. Do not invent web preset class names in Dart.

## Icon — compose with `Icon` and `FluentIcons`

Source: https://fluent2.microsoft.design/components/web/react/core/icon/usage/

Icons must represent a recognizable concept, object, or action. Use Flutter
`Icon` with a glyph that exists in `FluentIcons`; verify the current icon barrel.
Treat decorative icons as excluded from semantics and meaningful icons as named
either by adjacent text or a concise label. Use approved system icons, keep the
same metaphor across platforms unless native behavior differs, mirror only
directional glyphs under RTL, and never ship Microsoft product or brand assets
without the required license.

## Image — compose with Flutter image widgets

Source: https://fluent2.microsoft.design/components/web/react/core/image/usage/

Use photos or illustrations to reinforce meaning, not as the only place that
meaning exists. Apply image shadow sparingly because many elevated images make
a busy hierarchy. Provide brief, contextual alt text—usually one or two
sentences—and state a functional image's purpose. Do not repeat nearby text.
Exclude purely decorative images from semantics. Preserve aspect ratio, define
loading/error fallbacks, and test crop behavior under reflow and RTL.

## Review checklist

- Is the element a person, group, selected value, system status, plain text,
  semantic icon, or image—and is the chosen pattern accurate?
- Are fallback identity, presence, overflow, dismissal, and interaction states
  named and keyboard reachable?
- Can every status be understood without color, fine visual detail, or motion?
- Are AI systems visibly and semantically distinguished from human identities?
