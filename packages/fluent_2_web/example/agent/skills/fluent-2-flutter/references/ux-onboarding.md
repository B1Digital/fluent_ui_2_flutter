# Fluent 2 onboarding for Flutter

Official source: [Microsoft Fluent 2 onboarding](https://fluent2.microsoft.design/onboarding/).

Teach at relevant moments throughout the journey instead of placing everything
in a one-time first-run tour. Help people start or discover a feature without
blocking their primary goal.

## Apply the five principles

- **Relevant:** teach in the context of a closely related task.
- **Non-distracting:** do not become a barrier to the current goal.
- **Optional:** allow exit and offer a discoverable way to return later.
- **Benefit-focused:** state the practical benefit before explaining mechanics.
- **Coherent:** use standard Fluent components and familiar interaction.

Store dismissal/completion state deliberately and scope it to the relevant
user, feature version, and device/account policy. Do not repeatedly show an
experience after dismissal or hide critical setup behind “shown once” state.

## Choose one primary onboarding goal

| Goal | Suitable pattern | Current Flutter mapping |
| --- | --- | --- |
| Welcome | Welcome surface, banner, modal | Compose or use `FluentMessageBar`/`FluentDialog` |
| Orient | Contextual empty state or teaching popover | Compose empty state; use `FluentTeachingPopover` |
| Notify | Banner, empty state, popover, toast | `FluentMessageBar`, `FluentTeachingPopover`, `FluentToast` |
| Explain | Inline hint or short empty-state message | Compose text/illustration/action with semantics |
| Take action | First-run/setup steps, carousel, drawer | `FluentCarousel`, `FluentDrawer`, verified form controls |

Do not invent a generic `FluentOnboarding` or `FluentEmptyState`; neither is a
current public widget. Inspect each listed component's constructor and tests
before composing it.

## Design the flow

- Show a welcome once, keep it to one or two benefit-focused points, and expose
  later teaching contextually.
- Anchor orientation guidance to the actual feature and keep the target visible.
- Notify only when the change affects the person's work or unlocks a benefit.
- Explain at the point of uncertainty with the shortest useful hint.
- For required setup, show step count/progress, prerequisites, duration, back,
  cancel, resume, validation, and completion behavior.
- Never block escape unless the setup is genuinely required and the consequence
  is explained.

## Write onboarding content

Lead with what a person can accomplish. Prefer active voice and strong verbs;
make a CTA naturally complete “I want to …”. Break teaching into progressive,
interactive steps instead of long passive text.

Make help visible at the point of need through a tooltip, Learn more link, or
teaching popover, and keep support reachable later. Use inclusive,
nonjudgmental language such as “Need help?” State what will happen, how many
steps there are, and how long required setup is likely to take. Avoid surprises
except harmless delight.

## Make onboarding accessible and testable

Do not move focus merely because guidance appears. Give popovers/dialogs clear
names, logical initial focus, keyboard dismissal, and correct focus return.
Keep the feature usable at large text and narrow widths; do not obscure the
target. Announce important new guidance without repeatedly interrupting a
screen reader.

Test first use, repeat use, dismissal, rediscovery, resume after interruption,
feature updates, multiple accounts/devices, offline/failure states, keyboard,
screen reader, RTL, localization, 200% text, 320-pixel reflow, and reduced
motion.
