# Fluent 2 Wait UX for Flutter

Official source: [Microsoft Fluent 2 Wait UX](https://fluent2.microsoft.design/wait-ux/).

Communicate delay honestly, preserve context, and minimize perceived wait.
Attach one clear status to the content or action it affects; avoid blank screens
and competing indicators.

## Apply the timing thresholds

| Expected wait | Pattern |
| --- | --- |
| Under 1 second | Show no indicator; a flash is more confusing than helpful |
| 1–3 seconds | Use a labeled `FluentSpinner` for indeterminate work |
| Over 3 seconds | Prefer determinate `FluentProgressBar` or a reassuring status string |
| AI conversation | Show an immediate response indicator to preserve conversational flow |

Use measured progress whenever it is trustworthy. Never display invented
percentages or time estimates. Keep people in the same view unless navigation
is required and let nonblocking work continue where appropriate. No repository
widget schedules the one- and three-second thresholds; the application must
cancel its timers when work completes, fails, cancels, or is superseded.

## Select a visual pattern

### Spinner

Use for short indeterminate waits, normally under three seconds. Add a concise
visible `-ing` label and a matching `semanticLabel`. Use a nonbreaking space
before the ellipsis: `Loading\u00A0…`.

### Progress bar

Use `FluentProgressBar(value: fraction, semanticLabel: task)` when progress is
measurable; omit `value` only when an indeterminate bar is justified. Put the
task label above and optional status/estimate below. Explain recovery when
leaving early has consequences.

### Skeleton

Use `FluentSkeleton` when the shape of pending content is known. Label the
pending region or one skeleton, not every placeholder. The shipped animation
stops under reduced motion. The packages do not include a Copilot gradient
asset; do not fabricate or redistribute one.

### Toast

Use `FluentToast` through `FluentToaster` for long background work that affects
current content but should not hold the person in place. Keep one progress
message updated instead of spawning many toasts.

Morse-code and pulsing-dot animations are specialized AI/Copilot patterns with
no dedicated public Flutter widgets. Implement them only from an approved
product spec and licensed assets; do not present hidden chain-of-thought.

## Handle behavior and fallback messaging

When details are unavailable, use an honest short message such as
“Working on it\u00A0…” or “Getting things ready\u00A0…”. Productivity apps may
use controlled strings for consistency; AI experiences may generate contextual
messages, but generated text must remain truthful, concise, safe, and stable
enough for assistive announcements.

Allow cancellation when the operation supports it, prevent duplicate work,
handle timeouts and retry, and replace the wait state with explicit success,
empty, partial, cancelled, or failure content. Preserve prior content when a
refresh does not need to blank the screen.

## Make waiting accessible

Use each widget's semantic label or a parent `Semantics(liveRegion: true)` to
announce meaningful state changes. Announce progress at useful intervals, not
every frame. Use an `-ing` verb for active work and past tense for completion;
keep messages to one phrase or short sentence. Provide estimates in non-AI
flows when reliable.

`FluentSpinner`, `FluentToast`, and `FluentMessageBar` already support live
announcements; avoid a duplicate parent live region. `FluentProgressBar`
exposes its label and percentage but is not itself live, so pair long-running
progress with one throttled status announcement—for example at phase changes or
10% boundaries. `FluentSkeleton` is not live; label the pending region or one
representative skeleton. Flutter exposes a boolean live-region flag here, not a
polite/assertive priority choice.

Verify that spinners and skeletons render a static legible state when
`MediaQuery.disableAnimationsOf(context)` is true. Test fast completion before
the threshold, slow/unknown duration, cancellation, retry, backgrounding,
offline/timeouts, determinate progress, screen-reader announcements, reduced
motion, high contrast, and simultaneous operations.
