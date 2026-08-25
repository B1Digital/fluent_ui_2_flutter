# Working with AI

Use this reference when a Flutter experience generates, transforms, recommends,
or acts through AI. It summarizes Microsoft's Fluent 2 Responsible AI and AI
harm guidance and translates it into product and interface decisions.

Sources:

- https://fluent2.microsoft.design/responsible-AI/
- https://fluent2.microsoft.design/ai-harm/

## Contents

- Apply the five responsible AI principles
- Handle agents and autonomy
- Use transparent visual and content patterns
- Anticipate AI harms
- Collect feedback and harm reports
- Evaluate responsible AI behavior
- Implement in Flutter

## Apply the five responsible AI principles

### Be transparent

- Label AI entry points and generated output so people can distinguish them
  from human-authored content.
- Explain the system's purpose, data boundary, sources, memory, and material
  limitations at the point where each matters.
- Show citations or provenance for important claims and make the reasoning scope
  inspectable without exposing private chain-of-thought.
- Keep the system explicitly digital. Do not represent it as a person, friend,
  colleague, or team member, or imply emotions, beliefs, care, or understanding.
  Functional first-person statements about observable activity are acceptable
  when the product voice permits them; neutral status copy is the safest choice
  when cross-surface content rules would otherwise conflict.

### Set appropriate expectations

- State what the feature can and cannot do, the scope of the current entry
  point, and which sources it can access.
- Use the approved product disclaimer that AI output may be incorrect and should
  be reviewed before consequential use.
- During latency, describe real observable work such as "Gathering sources …"
  instead of vague filler or invented internal reasoning.
- Never claim a tool call, verification, action, or data access that did not
  actually happen.

Fluent requires an approved disclaimer pattern but does not supply one universal
legal string for every product, market, and risk level. Obtain the product's
approved text; do not invent or silently standardize legal copy in the skill.

### Prevent overreliance

- Preserve visible distinctions between AI and non-AI content.
- Provide sources, limitations, uncertainty, and review controls close to the
  output rather than burying them in settings.
- Add deliberate review or confirmation before high-impact actions. Do not make
  generated content look final, authoritative, or guaranteed.
- Match confidence to evidence and separate known facts, unknowns, and
  assumptions.

### Keep users in control

- Let people stop generation, change the request, edit output, accept or reject
  suggestions, confirm actions, undo or revert changes, delete data, and clear
  memory where those capabilities exist.
- Make AI activation and consent explicit. Use plain language about what data is
  sent, retained, shared, or used for personalization.
- Keep controls discoverable and available before commitment, not only after an
  action has completed.

### Collect feedback on output

- Explain why feedback is requested and what prompt, response, or diagnostic
  data will be submitted.
- Use specific categories that can drive remediation, not only a generic
  thumbs-up/down control.
- Treat behavioral telemetry as feedback too, but disclose collection and avoid
  interpreting abandonment as a reliable sentiment signal without evidence.

## Handle agents and autonomy

Agent experiences follow every principle above with extra disclosure and
control because the system may take actions rather than only generate text.

A feature that only generates a reviewable draft is not automatically an
autonomous agent. Apply the agent-specific gate when it independently invokes
tools, changes external state, schedules or assigns work, or continues beyond a
single reviewed response without a fresh user-reviewed instruction. Ordinary
user-directed multi-turn chat is not autonomous merely because it has several
turns. When uncertain, use the stricter disclosure and confirmation path.

- State when the agent is active, what triggers it, what permissions and data it
  has, and which actions it may take autonomously.
- Before a consequential action, present the proposed action, target, important
  consequences, and available alternatives. Require approve/reject when human
  authorization is expected.
- Report completion, partial completion, failure, and skipped actions honestly.
- Provide correction, cancellation, and reversal paths. If an action is not
  reversible, make that clear before confirmation.
- Never portray an agent with a human avatar or place it in a people group as if
  it were a coworker. Use a labeled AI/agent indicator and preserve real human
  identity patterns for people.

## Use transparent visual and content patterns

### Entry-point indicator

Identify AI before interaction begins. Keep the label available to assistive
technology and do not depend on a sparkle icon or color alone. State the scoped
task near the entry point when a feature name could overpromise.

### Reasoning or sources panel

Use a progressive-disclosure panel for sources, applied inputs, assumptions,
and an outcome-oriented explanation. Do not reveal hidden chain-of-thought or
pretend that a generated narrative is a faithful internal trace.

### Memory indicator

Show when personalization or memory affects the result. Let people inspect,
change, forget, or disable remembered information as the product permits.

### Disclaimers and errors

Place the approved AI disclaimer where people decide whether to rely on output.
Errors should identify what failed, what was or was not changed, and a specific
recovery action. Avoid anthropomorphic apology, blame, or empty reassurance.

## Anticipate AI harms

### Inaccurate output

Risk: invented or wrong facts can lead to wrong actions. Mitigate with grounding,
citations, uncertainty, review language, and verification paths.

### Incomplete output

Risk: people may treat a partial answer as complete. State scope and omissions,
use progressive disclosure, and explicitly name unavailable inputs.

### Biased output

Risk: stereotypes or uneven outcomes can disadvantage groups. Review content
inclusively, test with varied audiences and contexts, and provide a specific
reporting path.

### Inappropriate or unsafe output

Risk: harmful content or guidance can cause direct damage. Combine model and
system guardrails with visible reporting, refusal behavior, and escalation.

### Nontransparent output

Risk: hidden AI involvement, sources, or data use prevents informed decisions.
Label AI, show scope and provenance, request meaningful consent, and disclose
memory and data handling.

### Overreliance

Risk: confident presentation can cause people to skip review. Use caveats,
sources, edit/reject controls, and appropriate friction before consequential
use. Do not style output as authoritative merely to make it feel polished.

## Collect feedback and harm reports

Offer categories that identify the failure, for example:

- Factually wrong
- Incomplete
- Missing sources
- Questionable sources
- Unsafe or inappropriate
- Other

Keep the reporting flow accessible and short. State what prompt, output, user
comment, attachments, and technical metadata will be sent. Provide confirmation
and an escalation route where the reported harm may be urgent.

## Evaluate responsible AI behavior

Use Microsoft's 0–3 criterion scale and evaluate the whole interaction before,
during, and after generation. Include AI disclosure, expectations, tone,
comprehension/verification, overreliance protections, user control, and feedback.

- A: at least 90%.
- B: 80–90%, with every criterion at least 2.
- C: 75–80%.
- Fail: below 75% or two or more zeroes.
- Automatic fail: overreliance protection scores 0 or 1.
- Automatic fail for agents: agent expectation/autonomy disclosure scores 0 or
  1.

Record evidence for every score. Treat a high visual-quality score as irrelevant
when an automatic-fail safety or trust condition is present.

Use the source page's criterion-specific 0–3 anchors during an actual audit;
do not replace them with one generic scoring definition. Product teams must also
define evidence policy, retention/consent requirements, and any jurisdictional
or high-risk escalation rules that the Fluent page cannot decide for them.

## Implement in Flutter

- Compose AI entry labels, source links, memory state, disclaimers, feedback,
  and confirmation using exported Fluent widgets; this repository has no
  dedicated Fluent AI widget API.
- Do not invent classes from the React AI library. Check the coverage matrix and
  `components-ai-mobile.md` before composing a pattern.
- Use semantic status text and live regions for generation updates, offer Stop
  during active work, and preserve focus when content updates.
- Honor text scaling, reflow, keyboard navigation, high contrast, and reduced
  motion. AI identity and provenance must survive every mode.
- Test cancellation, partial output, unavailable sources, refused requests,
  invalid feedback, failed actions, undo, and irreversible confirmation—not
  only the happy path.
