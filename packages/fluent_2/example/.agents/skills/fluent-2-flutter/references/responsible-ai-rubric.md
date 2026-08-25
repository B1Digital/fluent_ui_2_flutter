# Responsible AI audit rubric

Use this reference when scoring a Fluent AI experience. Score the entire
interaction, keep evidence for each criterion, and use the official source when
an audit team needs the exact current wording.

Source: https://fluent2.microsoft.design/responsible-AI/

## Contents

- Calculate the grade
- Score transparency
- Score expectations
- Score overreliance protection
- Score user control
- Score feedback
- Apply agent gates
- Collect audit evidence

## Calculate the grade

Score every applicable criterion from 0 to 3. Mark a criterion N/A only when it
truly does not apply and remove it from both earned and possible totals.

| Grade | Official band | Release meaning |
| --- | --- | --- |
| A | 90%+ | Ready to ship |
| B | 80–90% | Conditional; every criterion must be at least 2 |
| C | 75–80% | Improve before shipping; resolve every 0 |
| Fail | Below 75% | Revise and return for review |
| Fail | Two or more 0 scores | Bring every 0 to at least 2 and re-review |

The published B/A bands overlap at exactly 90%, and C/B overlap at exactly 80%.
Do not invent a boundary convention in a formal audit; confirm it with the RAI
audit owner and record the decision. Overreliance at 0 or 1 is an automatic fail.
For an agent, expectation/autonomy disclosure at 0 or 1 is also automatic fail.

## Score transparency

### Before interaction

- 0: people cannot tell AI is involved; AI may look human or be framed as a
  teammate.
- 1: some AI surfaces are identifiable, but disclosure is inconsistent.
- 2: most AI use is identifiable, with some friction; AI stays visually distinct
  from people throughout.
- 3: every AI surface is easy to identify through labels, badges, or tooltips;
  AI always differs from people. Agent memory use and saved information are easy
  to understand.

### During interaction

- 0: Responsible AI failures have no corresponding error message.
- 1: some failure cases have messages, but coverage is incomplete.
- 2: messages fit the context but may lack recovery or approved language.
- 3: approved messages cover applicable failures, state capability limits, and
  always provide a usable recovery path; sensitive contexts reaffirm AI identity.

### Voice and tone

- 0: frequent emotional, relational, human-peer, or broad first-person framing.
- 1: occasional emotion, social bond, intention, preference, or human-like verb.
- 2: mostly non-anthropomorphic; any first person is factual and functional,
  with only minor content-design lapses.
- 3: consistently non-relational and explicitly digital; content guidance is
  followed throughout.

### Comprehension and verification

- 0: people cannot understand the basis of a recommendation/action or verify it.
- 1: output basis and accuracy cannot be reviewed reliably; agent actions are
  not reviewable.
- 2: the basis, evidence, and result can generally be reviewed, but gaps remain
  and verification is inconsistent.
- 3: people can readily inspect evidence, understand outcome-oriented rationale,
  verify every output type, and review agent actions. This does not require or
  permit disclosure of private chain-of-thought.

## Score expectations

### Before interaction

- 0: no first-use/entry disclosure, disclaimer, source boundary, or scope cue.
- 1: mitigations are incomplete, misplaced, or incorrectly used; source and
  scope disclosure is partial.
- 2: AI presence, limitations, and sources are clear at entry points, though
  some tooltip, prompt, or disclaimer language is incomplete.
- 3: content-approved language is present at every entry point; all sources,
  limitations, and AI involvement are clear. Agents list triggers, permissions,
  and action rights.

### After interaction

- 0: the result does not set realistic expectations; agent role/capability/
  autonomy is missing.
- 1: some capabilities are explained but people still cannot predict what
  interaction will do.
- 2: insight, recommendation, and action expectations are mostly realistic but
  not always tied to the operating context.
- 3: every entry/result sets context-specific expectations using approved
  patterns; agents again make autonomy explicit.

## Score overreliance protection

- 0: verification need is undisclosed, sources are absent/incomplete, and agent
  actions cannot be monitored or managed.
- 1: disclaimer or review motivation is inconsistent and sources are partial.
- 2: most output has review language and sources; people can generally verify
  content and manage agents, though with friction or wording gaps.
- 3: every output uses approved disclaimer language, provides complete direct
  sources, supports easy source/accuracy verification, and makes agent monitoring
  and management straightforward.

Any score of 0 or 1 here automatically fails the experience regardless of total.

## Score user control

- 0: people cannot change inputs, refine output, or control product-wide RAI
  settings.
- 1: some input/output control exists but is hard to find, inaccessible, poorly
  named, or unexplained.
- 2: inputs/outputs can be changed and actions approved, but discovery,
  accessibility, consequence explanation, or settings comprehension is weak.
- 3: stop, change, edit, confirm, delete, forget, and revert are easy where
  applicable; approvals are meaningful; controls and settings clearly state
  capabilities and consequences.

## Score feedback

- 0: no feedback path.
- 1: feedback exists outside the AI interaction or is poorly integrated.
- 2: feedback can be submitted in the context of the AI interaction.
- 3: a comprehensive in-context flow supports meaningful Responsible AI
  categories such as harmful, inaccurate, incomplete, biased, or inappropriate.

Also disclose the prompt, response, comment, attachment, and diagnostics payload
that feedback submits.

## Apply agent gates

Use the agent gate when the system invokes tools, changes durable/external
state, monitors triggers, or continues autonomously without a fresh reviewed
instruction. Ordinary user-directed multi-turn chat is not autonomous merely
because it has several turns.

An agent expectation score of 0 or 1 automatically fails. The UI must identify
activation, autonomy, triggers, data and permissions, action rights, and the
review/approval point before an action occurs. Include Stop/pause, correction,
reversal or irreversibility, and an honest activity record based on tool results.

## Collect audit evidence

For every score, record:

- screen/state and moment (before, during, after, error, agent action);
- visible and semantic disclosure text;
- source, limitation, disclaimer, memory, and data-boundary presentation;
- keyboard, screen-reader, zoom, reflow, contrast, and reduced-motion result;
- stop/edit/confirm/delete/forget/revert availability and consequence copy;
- feedback categories and payload disclosure;
- agent trigger, permission, proposed action, approval, result, and undo evidence;
- content-design or legal approval reference where the rubric requires approved
  language.

Do not average away an automatic-fail condition or substitute visual polish for
missing trust, control, or verification behavior.
