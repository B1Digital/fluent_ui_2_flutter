# Fluent 2 handoffs for Flutter

Official source: [Microsoft Fluent 2 handoffs](https://fluent2.microsoft.design/handoffs/).

A handoff moves a person between workflow stages, surfaces, or apps while
preserving what is needed to continue confidently. Treat it as a state and
wayfinding contract, not merely a deep link.

## Apply the three principles

- **Guide seamlessly:** explain why another surface is the logical next step,
  what will happen, and where the action goes.
- **Maintain context:** carry only the content, state, permissions, and
  breadcrumbs needed to continue; remove obsolete context.
- **Unify experiences:** use coherent visuals, language, and explicit CTAs so
  the person initiates and remains in control of the transition.

Bookend a cross-app transition with concise messages in the initiating and
destination experiences. Provide a clear route back when the workflow allows.

## Match certainty to user intent

- For strong, specific intent, suggest or perform the relevant next step after
  any required confirmation.
- For semi-formed intent, preview the likely outcome and offer focused choices
  or clarification.
- For loose, exploratory intent, present optional capabilities without forcing
  a destination or pretending certainty.

Never infer permission, irreversible transformation, data sharing, or external
navigation from intent alone.

## Use AI responsibly

AI may understand, transform, enhance, route, or adapt content to the target
surface. Show what will transfer or change and provide previews or adjustments
when the transformation is meaningful. Keep the source available, identify the
destination, avoid anthropomorphic claims, and do not expose private context in
route parameters, logs, analytics, or user-visible URLs.

The current Flutter packages have no dedicated handoff or Copilot artifact
widgets. Compose verified Fluent controls and report that gap rather than
inventing `FluentHandoff`, artifact, entity, or side-by-side APIs.

## Select a visual pattern

Use chat responses and editable artifacts within the current conversation;
entities for existing files; side-by-side views when destination functionality
must remain visible; and inline modules for a CTA embedded in the primary flow.
Choose only patterns supported by the product and current widget API.

## Write handoff content

Use a brief third-person, full-sentence system message describing what the
assistant did and where, ending with a period. Use consistent CTAs:

- **Create … / Create in [app] / Create [file type]:** make something new from
  existing content.
- **Open in [app]:** access existing content with little or no transformation.
- **Continue in [app]:** keep working in a surface with deeper capability.
- **Try in [app]:** explore an outcome, especially for loose intent or test
  data.

## Implement and verify the transition

Serialize the minimum context in a versioned model. Validate destination
availability, authentication, authorization, network state, and URI support
before navigating. Save or confirm unsaved work, expose progress, handle
cancellation/failure, and make retries idempotent. Restore focus and announce
the transition result when the current Flutter view remains active.

Test same-app routes, deep links, cold/warm destination launches, app absence,
expired authentication, offline/failure paths, cancellation, duplicate taps,
back navigation, source/destination bookends, localization, accessibility, and
privacy boundaries.
