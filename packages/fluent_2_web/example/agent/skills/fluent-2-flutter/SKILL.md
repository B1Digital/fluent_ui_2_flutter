---
description: "Build, migrate, review, and troubleshoot Flutter interfaces that follow Microsoft's Fluent 2 design system, component usage, UX frameworks, Responsible AI, and Content Engineering guidance. Use when working with fluent_2_core, fluent_2_web, fluent_2_mobile, Fluent widgets, themes, accessibility, content, prompts, AI output evaluation, tokens, handoffs, onboarding, Wait UX, responsive behavior, or official color, elevation, iconography, layout, material, motion, shapes, typography, component, and design-principle guidance in Dart and Flutter."
---
# Fluent 2 Flutter

Build Fluent 2 interfaces from the official guidance and the Flutter API that
actually exists. Treat design fidelity, platform behavior, accessibility, and
compile correctness as one requirement.

## Follow this workflow

1. Inspect the target repository before proposing an API.
   - Read its agent instructions, package manifests, public barrels, tests, and
     representative examples.
   - Detect whether it forbids Material or Cupertino imports.
2. Identify the target surface: web/desktop, iOS, Android, or adaptive.
3. Find the component in [the coverage matrix](references/coverage-matrix.md).
   - Use an `implemented` mapping directly.
   - Use a `compose` mapping only with the listed Flutter primitives.
   - Treat `missing` as a real gap. Never invent a class or constructor.
4. Load only the references needed for the task:
   - Read [design principles and accessibility](references/design-language.md)
     for cross-cutting decisions.
   - Read the relevant detailed design-language reference: [color](references/design-color.md),
     [elevation](references/design-elevation.md),
     [iconography](references/design-iconography.md),
     [layout](references/design-layout.md),
     [material](references/design-material.md), [motion](references/design-motion.md),
     [shapes](references/design-shapes.md), or
     [typography](references/design-typography.md).
   - Read the relevant UX framework reference for accessibility, content,
     token architecture, cross-surface handoffs, onboarding, or wait states.
   - Read [Flutter foundations](references/flutter-foundations.md) for package,
     theme, token, platform, and validation patterns.
   - Read the relevant component group listed below. Every one of the 47
     official web-core components has a sourced decision section.
   - For AI output or agent behavior, also read Working with AI and the relevant
     Content Engineering reference before designing the Flutter surface.
5. Read the component's field-level API reference below, then inspect the
   current constructor and tests before emitting code. The generated reference
   records exact checked-out signatures, fields, defaults, and related public
   types; source remains authoritative when a newer checkout drifts.
   - Read its "Behavior and parity notes" section first when present. It
     records hand-audited behavior no signature can express, such as a missing
     keyboard path. Report a documented gap; never paper over it.
   - Add a newly verified gap to that component's `notes` array in
     `references/widget-coverage.json`, then regenerate. Never hand-edit an
     `api-*.md` file.
6. Implement with semantic tokens, explicit interaction states, keyboard and
   focus behavior, text scaling, RTL, high contrast, and reduced motion.
7. Format, analyze, and test the smallest affected package, then run the
   repository's full verification command when available.

## Route component work

- Button, link, checkbox, radio group, switch, rating, field, label, info
  label, input, textarea, search box, dropdown, select, combobox, slider, spin
  button, and tag picker: read
  [actions and inputs](references/components-actions-inputs.md).
- Accordion, breadcrumb, carousel, list, menu, nav, tab list, toolbar, tree, and
  the repository data-grid extension: read
  [navigation and data](references/components-navigation-data.md).
- Card, divider, dialog, drawer, popover, tooltip, message bar, progress bar,
  spinner, skeleton, toast, and the acrylic/teaching extensions: read
  [surfaces and feedback](references/components-surfaces-feedback.md).
- Avatar, avatar group, persona, badge, tag, text, icon, image, presence, and
  status: read [identity and content](references/components-identity-content.md).
- Fluent AI patterns and native mobile differences: read
  [AI and mobile](references/components-ai-mobile.md).
- Exact public Flutter classes, including theme and internal building blocks:
  read [the Flutter API surface](references/flutter-api-surface.md).
- Provenance, crawl scope, and update policy: read
  [sources](references/sources.md).

## Route exact Flutter widget APIs

Each official web-core component has its own source-derived Flutter API
reference. Read the matching file before writing Dart. A `compose` or `missing`
reference deliberately has no invented widget fields.

- Identity and content: [avatar](references/api-avatar.md),
  [avatar group](references/api-avatargroup.md), [badge](references/api-badge.md),
  [persona](references/api-persona.md), [tag](references/api-tag.md),
  [icon](references/api-icon.md), [image](references/api-image.md), and
  [text](references/api-text.md).
- Actions and inputs: [button](references/api-button.md),
  [checkbox](references/api-checkbox.md), [combobox](references/api-combobox.md),
  [dropdown](references/api-dropdown.md), [field](references/api-field.md),
  [info label](references/api-infolabel.md), [input](references/api-input.md),
  [label](references/api-label.md), [link](references/api-link.md),
  [radio group](references/api-radiogroup.md), [rating](references/api-rating.md),
  [search box](references/api-searchbox.md), [select](references/api-select.md),
  [slider](references/api-slider.md), [spin button](references/api-spin.md),
  [switch](references/api-switch.md), [tag picker](references/api-tagpicker.md),
  and [text area](references/api-textarea.md).
- Navigation and data: [accordion](references/api-accordion.md),
  [breadcrumb](references/api-breadcrumb.md), [carousel](references/api-carousel.md),
  [list](references/api-list.md), [menu](references/api-menu.md),
  [nav](references/api-nav.md), [tab list](references/api-tablist.md),
  [toolbar](references/api-toolbar.md), and [tree](references/api-tree.md).
- Surfaces and feedback: [card](references/api-card.md),
  [dialog](references/api-dialog.md), [divider](references/api-divider.md),
  [drawer](references/api-drawer.md), [message bar](references/api-messagebar.md),
  [popover](references/api-popover.md),
  [progress bar](references/api-progressbar.md),
  [skeleton](references/api-skeleton.md), [spinner](references/api-spinner.md),
  [toast](references/api-toast.md), and [tooltip](references/api-tooltip.md).
- Foundation: [Fluent provider](references/api-fluentprovider.md).

## Route AI and content-engineering work

- AI disclosure, expectations, overreliance, user control, agents, autonomy,
  harm prevention, feedback, and Responsible AI scoring: read
  [Working with AI](references/working-with-ai.md).
- For a release or design audit, apply the criterion-specific
  [Responsible AI audit rubric](references/responsible-ai-rubric.md); do not
  infer score anchors from the overall percentage alone.
- System prompts, role/task/rules/examples, baseline behavior, reusable task
  patterns, complex tasks, clarification, interaction, and tone: read
  [Content engineering and system prompts](references/content-engineering-prompts.md).
- Grounding, output requirements, prompt sets, assertions, result diagnosis,
  fixes, regression, and quality tracking: read
  [evaluating AI output quality](references/content-engineering-evaluation.md).

## Route UX framework work

- Inclusive structure, focus, contrast, reflow, alternatives, and accessible
  specifications: read [accessibility](references/ux-accessibility.md).
- Audience, voice, capitalization, punctuation, localization, and action copy:
  read [content design](references/ux-content-design.md).
- Global/alias layers, theming, design-to-code names, and value governance: read
  [design tokens](references/ux-design-tokens.md).
- Same-app, cross-app, and AI-assisted workflow transitions: read
  [handoffs](references/ux-handoffs.md).
- Welcome, orientation, notification, explanation, and setup experiences: read
  [onboarding](references/ux-onboarding.md).
- Loading thresholds, indicators, progress, skeletons, background work, and
  announcements: read [Wait UX](references/ux-wait.md).

## Apply these non-negotiable rules

- Apply Microsoft's four-principle gate: natural on every platform, built for
  focus, one for all/all for one, and unmistakably Microsoft. When they
  conflict, preserve platform behavior, inclusion, and task focus before
  decorative brand expression.
- Prefer the official Fluent 2 usage guidance for product intent and the
  checked-out Flutter source for available APIs.
- Prefer semantic alias tokens over raw colors or opacity arithmetic. Add a
  missing token to the shared token package rather than hardcoding a value.
- Preserve every meaningful state: rest, hover, pressed, focused, selected,
  disabled, invalid, loading, expanded, and high contrast where applicable.
- Give every interactive control a keyboard path, visible focus, correct
  semantics, and predictable focus restoration after transient UI closes.
- Do not use color alone for status. Pair it with text, an icon, shape, or
  another semantic cue.
- Identify AI before interaction and distinguish generated output from human
  content. Never represent an AI system with a human avatar or imply emotion,
  social identity, unsupported capability, or unwarranted certainty.
- Put consequential AI actions behind review and confirmation; provide Stop,
  edit, reject, undo, source, limitation, and feedback paths where applicable.
- Reflow at narrow widths and large text sizes. Do not hide essential content
  or require horizontal scrolling for ordinary reading flows.
- Honor `MediaQuery.disableAnimationsOf(context)`. Keep motion purposeful and
  local to the element whose state changed.
- Follow native interaction expectations. A Fluent appearance does not justify
  replacing platform behavior with a web interaction model.
- In this repository, import `package:flutter/widgets.dart` and never Material
  or Cupertino. In another repository, follow that repository's policy.
- Do not bundle Segoe UI, Microsoft logos, product icons, or other restricted
  assets. Reference installed fonts and use appropriately licensed system
  icons.

## Work with this repository

Use these package roles:

- `fluent_2_core`: app shell, theme, semantic tokens, typography, layout,
  elevation, materials, and motion.
- `fluent_2_web`: pointer-oriented web and desktop widgets. It re-exports core.
- `fluent_2_mobile`: touch-oriented package. Check its barrel before use; the
  current repository may expose fewer components than the official mobile
  guidance.

Use the shipped gallery stories and widget tests as executable API examples.
Do not trust stale README status text over the public barrel and source tree.

## Run the bundled checks

From the skill directory:

```bash
node scripts/validate-skill.mjs
node scripts/audit-widget-coverage.mjs
node scripts/generate-component-api.mjs
```

From a repository checkout, compile-check the Dart examples this skill ships.
An example that no longer analyzes is a broken instruction, not a stale
comment:

```bash
dart analyze skills/fluent-2-flutter/scripts/flutter_examples_smoke.dart
```

After a public Dart API change, refresh and review all per-component field
snapshots:

```bash
node scripts/generate-component-api.mjs --write
```

Refresh the Microsoft route snapshot only when current network access is
available:

```bash
node scripts/crawl-fluent2.mjs --write
```

Review the generated diff after a refresh. A new route is not covered until it
has a deliberate mapping and guidance entry.

## Judge completion

Complete a Fluent Flutter task only when:

- every referenced class exists in the current package version;
- the selected component matches the documented use case;
- semantics, focus, keyboard, RTL, scaling, contrast, and reduced motion were
  considered and tested where relevant;
- no raw design values bypass an available token;
- formatting, static analysis, and applicable tests pass; and
- missing platform support is reported plainly instead of being approximated
  silently.
