# Fluent 2 content design for Flutter

Official source: [Microsoft Fluent 2 content design](https://fluent2.microsoft.design/content-design/).

Treat words as design material. Deliver the information people need when they
need it, in a tone and amount appropriate to their goal and emotional state.

## Start with the audience

Before writing, answer:

- Who specifically is the audience?
- What are they trying to accomplish now?
- How might they feel—uncertain, anxious, exploratory, or successful?

Use those answers to prioritize decisions and next steps. Remove content that
does not help the current task.

## Write for comprehension and action

- Use plain language, short sentences, fragments where natural, and scannable
  grouping.
- Put the point, choice, or next step first and remove excess words.
- Use a conversational human voice and adjust tone to context.
- Prefer present tense and active voice. Use passive voice only when the action
  matters more than the actor or naming the actor would distract.
- Address the reader as “you.” Use first person only when writing from the
  reader's point of view.
- Replace specialist jargon with language the intended audience understands.

## Capitalize and punctuate by platform

Use sentence-style capitalization on Windows, Android, and web: capitalize the
first word and proper nouns. Follow native title-style guidance on iOS and
macOS where the surrounding platform requires it.

Use question marks for questions and periods for full sentences. Usually omit
periods from buttons, labels, headings, and short list items. Reserve
exclamation points for genuinely celebratory moments.

## Organize and globalize content

Use headings as an outline; use lists and tables when they make relationships
clear. Give links short destination-specific text rather than “Click here.”
Avoid “above,” “below,” “left,” and “right,” which assume vision, layout, and
direction. Give non-text content appropriate alternatives.

In Flutter, keep user-facing strings in the app's localization system. Pass
localized semantic labels, tooltip text, validation messages, dismiss labels,
and progress announcements into Fluent widgets. Use `Directionality`,
directional layout APIs, locale-aware formatting, and flexible constraints.
Never size a control from the English string.

## Match content to component behavior

- Name buttons with the action they perform.
- Keep persistent field labels; do not make placeholders carry the label.
- State errors in plain language, explain what happened, and give a recovery
  action when possible.
- Keep destructive and irreversible actions explicit.
- Make loading, success, and handoff messages describe the actual state.
- Keep visible text and accessibility labels consistent unless additional
  context is necessary for assistive technology.

## Review content

Read the interface without its visuals. Confirm that headings, labels, status,
errors, links, and next actions still form a complete task. Test localization,
RTL, screen-reader pronunciation/order, narrow layouts, large text, truncation,
empty data, failure states, and plural/date/number formatting.
