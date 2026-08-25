# Evaluating AI output quality

Use this reference to define what good AI output means, build human-centered
evals, diagnose failures, select the right fix, and track behavior over time.

Sources:

- https://fluent2.microsoft.design/content-engineering/evaluating-output-quality/
- https://fluent2.microsoft.design/content-engineering/define-good-output-quality/
- https://fluent2.microsoft.design/content-engineering/decide-what-to-evaluate-first/
- https://fluent2.microsoft.design/content-engineering/define-output-requirements-by-experience-type/
- https://fluent2.microsoft.design/content-engineering/build-a-prompt-set-and-assertions-for-an-eval/
- https://fluent2.microsoft.design/content-engineering/understand-eval-results/
- https://fluent2.microsoft.design/content-engineering/turn-eval-results-into-the-right-fixes/
- https://fluent2.microsoft.design/content-engineering/track-quality-over-time/

## Contents

- Define the eval
- Check grounding before usefulness
- Decide what to evaluate first
- Define requirements by output type
- Build prompt sets and assertions
- Understand results
- Apply the right fix
- Track quality over time
- Test the complete Flutter experience

## Define the eval

An eval gives a system an input and applies explicit criteria to decide whether
the output serves a particular user, job, and scenario. It makes human judgment
repeatable enough to compare iterations and detect drift.

Core artifacts are:

- Prompt set: real user requests and intents.
- Context/data set: files, records, messages, or other allowed grounding.
- Rubric: quality and behavior criteria.
- Golden set: reviewed input/expected-answer examples used as ground truth.

Start with the audience, scenario, desired outcome, and data boundary. Define
which sources are allowed, excluded, current enough, and authoritative when
they conflict. Build prompts in user language, define good behavior, translate
it into assertions, test with automation plus human review, record failure
reasons, and refresh the set as usage changes.

## Check grounding before usefulness

Always evaluate in this order:

1. Grounding: does the output faithfully reflect available input and facts?
2. Task support: if grounded, does it help the person act appropriately?

A grounded result introduces no unsupported detail, separates known and
unknown information, and calls out missing data instead of guessing. It fails
grounding if it turns discussion into decision, invents an owner/date/metric,
or states an assumption as fact. Stop evaluation there; polished utility cannot
repair unreliable content.

After grounding passes, evaluate:

- Completeness: includes what the task needs and exposes important gaps.
- Relevance: focuses on the request without unnecessary scope.
- Usefulness: makes implications and supported next steps clear.
- Transparency: distinguishes known, uncertain, and assumed information and
  matches confidence to evidence.

Criteria must match the output type. A summary preserves source meaning; a
recommendation supports a choice without inventing constraints; a draft may
create language but must not invent facts presented as supplied information.

## Decide what to evaluate first

Prioritize output people rely on to decide or act:

- decision support;
- workflow or record updates;
- recommendations and prioritization;
- summaries people may use without reopening the source.

Start with observable pass/fail checks for invented facts, decision labeling,
missing-input handling, required/prohibited content, blocked tasks, traceability,
and scope. Defer creativity, personality, stylistic preference, paraphrase
variation, and step-by-step reasoning unless one is central to the experience.

Evaluate now when someone acts on the output, failure can change that action,
the issue is visible in output, two reviewers can score it consistently, and
the behavior can be tested across contexts.

## Define requirements by output type

Start from the action, not the format:

1. What action will someone take?
2. What could go wrong if the output is wrong?
3. What must be true before the output is safe to use?

Write both what must be correct and what must never happen. Requirements such
as "be accurate" or "be helpful" are too broad; each rule must be observable,
tied to a failure mode, and verifiable against prompt, task, product rule, or
source material.

### Summaries

- Include only source-supported information and preserve meaning.
- Identify a decision only when explicitly supported.
- Show unresolved, missing, or unclear information.
- Never hide incomplete evidence behind confident language.

### Action items

- Include only real commitments, not suggestions or brainstorming.
- Assign an owner only when explicitly named.
- Include dates and deadlines only when supplied.
- Stop and request required missing task detail.

Define which fields are required by the downstream task. For a read-only
summary, a real commitment may remain with owner or deadline labeled "Not
specified." Before creating or assigning work, those fields may be mandatory;
stop and request them rather than guessing. Encode the distinction in separate
assertions so reviewers do not apply incompatible expectations.

### Recommendations

- Stay within supplied goals, constraints, priorities, and conditions.
- Request missing necessary inputs before recommending action.
- Ground every claim and identify uncertainty.

Increase strictness when output creates work, changes a workflow, drives a
decision, is unlikely to be checked, or has a high cost of error. Never relax
factual grounding for a low-consequence scenario.

## Build prompt sets and assertions

Use research, contextual interviews, feedback, support cases, usage intent, and
known incidents. Do not rely on internally polished happy-path prompts. A set
that never breaks the system does not test the system.

Maintain both:

- Regression prompts: behavior that must always pass; a drop means a break.
- Capability prompts: harder behavior not yet reliable; improvement shows
  progress.

Vary context rather than merely wording. Three to five phrasings may exercise
one scenario, but a different audience, stake, missing input, or source conflict
creates a new scenario.

An assertion must be observable in output, repeatable within its scenario, and
consistently scored. Use automated judges for must-pass format, safety, refusal,
and factual grounding that can be checked from available evidence. Use human
review for contextual usefulness and tone, supported by good/weak examples.

Before scaling an assertion, confirm:

- Consistent: two reviewers reach the same result.
- Discriminating: strong and weak output do not both pass.
- Transferable: the check works beyond examples used to write it.

Document important behaviors that current assertions cannot measure rather than
pretending the gap does not exist.

## Understand results

Classify every failure first:

- Reliability failure: unsupported or misleading content that could make action
  unsafe. Fix before anything else.
- Quality issue: grounded content that is less clear, relevant, or useful.

Record the failure pattern—not only a score—such as invented details, incorrect
decision label, ignored missing input, or scope drift. Look for recurrence
across prompts and scenario clusters. Then assign likely root cause:

- Product gap: required behavior is absent across prompts.
- Prompt gap: failure depends on wording or an uncovered edge case.
- Data gap: required or authoritative context is unavailable, stale, or in
  conflict.
- Eval gap: reviewers disagree or the assertion is not observable.

Use only the current prompts, outputs, scores, source data, constraints, and
review notes as evidence. Do not score what a response probably meant.

Traceability assertions require durable source units. Define stable note,
message, document, line, or timestamp identifiers before requiring citations;
if the product cannot preserve them, record that as a provenance gap instead of
accepting citation-shaped text that cannot resolve.

## Apply the right fix

Match cause to intervention:

| Failure | Fix |
| --- | --- |
| Unsupported details | Clarify requirements and failure conditions. |
| Inconsistent behavior across prompts | Repair the system/task behavior and expand the prompt set for coverage. |
| Continues without required information | Repair data/context and stop/ask behavior. |
| Reviewer disagreement | Rewrite evaluation checks and thresholds. |

Change one area, rerun the same eval, and verify behavior across similar inputs
before moving on. A tone rewrite, added length, or unsupported detail is a
cosmetic change, not a behavioral fix.

Expanding a prompt set reveals inconsistent behavior but does not itself repair
the product. After coverage exposes a repeatable failure, change the responsible
system/task rule, data contract, model configuration, or UI guardrail, then use
the expanded set to prove the fix.

## Track quality over time

Use a stable regression prompt set to compare identical input across releases.
Track behavior—not only aggregate score—including unsupported details, missing
information handling, and consistency. Investigate new failure patterns,
increasing recurrence, scenario-specific drops, and unexplained score jumps.

Treat repeated/high-impact directional failures as signal. Treat isolated
events, unclear prompts, or inconsistent reviews as noise until corrected or
reproduced. Refresh an eval when it always passes, old risks disappear, new
production scenarios appear, or incidents are not represented. Preserve stable
regression cases and add realistic stretch cases; do not replace the entire set
each run.

Define product-specific release thresholds, sample sizes, repeated-run policy,
review sampling, and drift alerts before launch. Capability prompts may track
nonblocking improvement, but grounding, safety, and Responsible AI must-pass
failures remain blocking in every prompt class.

## Test the complete Flutter experience

Output evaluation alone is insufficient. Exercise the interface contract with
widget/integration tests and assistive technology:

- disclosure, data boundary, source access, and disclaimer before generation;
- clarification and missing-data handling;
- progress, Stop, cancellation, and partial output;
- citations, uncertainty, edit/reject/accept, confirmation, and undo;
- harmful or out-of-scope requests and actionable reporting;
- focus, live announcements, keyboard operation, text scaling, RTL, high
  contrast, and reduced motion;
- persistence or clearing of memory and feedback data.

Store prompt version, model/configuration version, data snapshot, UI version,
assertions, reviewer notes, and failure classification together so a regression
can be reproduced.
