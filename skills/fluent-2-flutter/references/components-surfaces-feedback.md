# Surfaces and feedback

Use this reference for containers, transient surfaces, progress, loading,
messages, notifications, and explanatory overlays.

## Contents

- Card and divider
- Acrylic surface extension
- Dialog and drawer
- Popover and teaching popover
- Tooltip
- Message bar
- Progress bar, spinner, and skeleton
- Toast and toaster

## Card and divider

### Card — `FluentCard`

Source: https://fluent2.microsoft.design/components/web/react/core/card/usage/

Use a card to group information and actions about one object or concept. Apply
the pattern consistently for the same use case across an experience. Establish
hierarchy with header, preview, body, and footer regions; choose vertical or
horizontal alignment based on the content, not decoration. Make the whole card
interactive only when it has one clear destination; otherwise keep individual
actions independently focusable. Prefer spacing and type hierarchy before
adding borders, elevation, or shadows.

### Divider — `FluentDivider`

Source: https://fluent2.microsoft.design/components/web/react/core/divider/usage/

Use a block divider for a strict section boundary and an inset divider to imply
closely related items. Dividers have no built-in margin: use at least 12 pixels
above/below default or text dividers and 8 around icon dividers when matching
web guidance, expressed through project spacing tokens. Put dividers above
headings; do not underline headings. Hide a purely visual divider from
assistive technology. Optional text is a short sentence-case preview of the
next section.

## Acrylic surface — `FluentAcrylicSurface`

This is a repository extension. Use acrylic only for supported, transient,
light-dismiss web/desktop surfaces. Provide a solid semantic-token fallback for
disabled transparency, high contrast, and weak rendering performance. Do not
blur ordinary content or use material as a substitute for hierarchy.

## Dialog and drawer

### Dialog — `FluentDialog`

Source: https://fluent2.microsoft.design/components/web/react/core/dialog/usage/

Use a dialog for an important supplemental task or decision. Modal dialogs
block page interaction; non-modal dialogs assist a continuing workflow; alert
dialogs are urgent modals reserved for potential loss or destructive action.
Use toast for a passive update and popover for nonessential context. Never nest
dialogs.

Modal dialogs may close through outside selection, Escape, or a footer action
when cancellation is allowed. Non-modal dialogs close through their close
button, Escape, or a footer action—not outside selection. Alert dialogs close
only through an explicit footer choice in the official usage guidance. The
current Flutter `FluentDialogModalType.alert` blocks scrim dismissal but still
handles Escape when `onOpenChange` is non-null. To implement the stricter
official alert contract, pass `onOpenChange: null` and let explicit footer
actions update the controlled owner state. Keep header and up to three footer
actions fixed while a bounded body scrolls. Keep forms short and task-specific.

Name the dialog with a concise, informative title; focus its first meaningful
control, trap focus only for modal/alert behavior, ensure at least one exit, and
restore focus to the trigger. The title states the message rather than a generic
"Error"; body adds consequences or instructions without repetition; buttons
answer the title directly.

### Drawer — `FluentDrawer`

Source: https://fluent2.microsoft.design/components/web/react/core/drawer/usage/

Use a drawer for supplemental information or simple actions tied to the parent
view. Inline drawers preserve simultaneous page interaction; overlay drawers
draw stronger attention and are modal by default. Use a popover/tooltip for
short local context and a dialog for confirmation. Never invoke several overlay
drawers together.

Keep drawer flows to two or three steps and use a more focused surface for
longer tasks. Warn before closing if entries could be lost. Put local errors
beside their section, several errors at the top, and whole-surface failures in
an empty state. Use a dialog sparingly for destructive confirmation. Wrap long
body content in its scrolling region.

Keep placement predictable (navigation commonly left, notifications right),
with required header/body and optional footer. Sticky header/footer become
non-sticky at 400% zoom so content gets priority. Choose small, medium, large,
or full width based on reference needs; do not use full width when page context
must remain visible. Name the contents in a brief title and keep body and button
copy immediately actionable.

## Popover and teaching popover

### Popover — `FluentPopover`, `FluentPopoverEntrance`

Source: https://fluent2.microsoft.design/components/web/react/core/popover/usage/

Use a popover for brief, nonessential structured or interactive content
anchored to a trigger. Use tooltip for plain text and dialog for complex or
blocking work. Constrain the otherwise unbounded surface to the viewport; if it
must scroll, prefer one axis and avoid covering information needed alongside it.
Position the beak toward its trigger. Never nest popovers or repeat information
already visible.

Close through documented light-dismiss and Escape paths and restore focus when
focus entered the surface. Focus trapping makes the rest of the surface hidden
to assistive technology, so enable it only when necessary and preserve a clear
exit. The current Flutter `FluentPopover` always uses an autofocus `FocusScope`
that cycles focus and exposes no `trapFocus` option. Use it only when that
behavior is acceptable, include a visible close path, or report the missing
nontrapping variant. Current before/after positioning is implemented with
physical alignments and lacks RTL tests, so verify placement on both directions.
`FluentPopoverEntrance` is an animation primitive; honor reduced motion.

### Teaching popover — `FluentTeachingPopover`

This repository extension supports a short, dismissible explanation attached
to one target. Keep it rare, optional, actionable, and suppress it after it has
served its purpose. Never place essential onboarding only in this transient
surface.

## Tooltip — `FluentTooltip`

Source: https://fluent2.microsoft.design/components/web/react/core/tooltip/usage/

Use a tooltip for nonessential plain text, especially an unfamiliar icon-only
control. It cannot contain interactive content, system feedback, or essential
instructions. Show on both hover and focus; dismiss on blur or pointer exit;
connect it to the trigger as a description without making it the trigger's only
name. The default web gap is 4 pixels; use spacing tokens and keep the arrow
pointing at the target without covering important UI. For enabled controls say
what can be done; for disabled controls say what condition enables them.

## Message bar — `FluentMessageBar`

Source: https://fluent2.microsoft.design/components/web/react/core/messagebar/usage/

Use a message bar for the state of the app, page, tab, card, form, dialog, or
drawer. Information can improve the experience; success states what changed;
warning signals a preventable risk and must offer a link or action; error blocks
progress and must offer a resolution. Use dialog to prevent destructive action
and toast for time-sensitive events from elsewhere.

Content never truncates. After about two lines, reflow actions below the body.
When stacking, order error, warning, success, information. An accordion may
collapse several bars but must expose the highest severity and remaining count.
Dismissal is available, yet unresolved warning/error returns in the next
session. Put the bar closest to its scope; after invalid form submission, move
focus to the summary and reinforce each field inline.

Warning/error announcements are assertive; information/success are polite, so
reserve interruption for critical cases. Use a specific optional title and one
or two short body sentences (roughly 100 characters per line), never generic
"Warning" or congratulatory "Successfully." Actions answer the message and
links describe their destination.

## Progress bar, spinner, and skeleton

### Progress bar — `FluentProgressBar`

Source: https://fluent2.microsoft.design/components/web/react/core/progressbar/usage/

Use progress bars only after about one second. Use determinate progress whenever
completion is measurable; use static progress for a standing percentage such
as storage; use indeterminate only for a short unknown task and switch to
determinate when enough data arrives, after completing the current animation
cycle. Combine related phases into one forward-only bar so progress never
appears to rewind. Expose value/max and label the operation. Status uses a brief
specific -ing phrase and informative units, not unreliable time estimates.

### Spinner — `FluentSpinner`

Source: https://fluent2.microsoft.design/components/web/react/core/spinner/usage/

Use a spinner for processing longer than one second when progress is unknown.
Center it over only the loading region and keep unrelated page regions usable.
If the wait is expected to exceed three seconds, provide a label announced to
screen readers. Mirror the triggering action where possible (for example,
"Connecting to data …"), use three words or fewer, and avoid vague "Working on
it" copy. Honor reduced motion.

### Skeleton — `FluentSkeleton`

Source: https://fluent2.microsoft.design/components/web/react/core/skeleton/usage/

Use skeletons when content structure is known, loading exceeds one second, and
the rest of the page remains usable. Do not skeleton fixed chrome or use the
pattern for a long process. Represent only stable high-level structure, not
every detail. Prefer the wave animation; synchronize all visible skeletons and
fetch concurrently to avoid a fragmented cascade.

Skeleton shapes are decorative. Name any still-focusable loading control,
preserve focus when content arrives, and consider one restrained live region
or `busy` state for a significant group. Announce completion only after all
items in that group are ready.

## Toast and toaster — `FluentToast`, `FluentToaster`

Source: https://fluent2.microsoft.design/components/web/react/core/toast/usage/

Use toast for useful but noncritical confirmation, progress, or communication.
Use dialog, inline field error, or message bar for critical information or
required action. A toast with no action times out after seven seconds and pauses
on pointer hover. Use conditional dismissal for ongoing work. Add an explicit
close control only when the information can be found later elsewhere.

Use either a determinate progress bar and percentage or an indeterminate
spinner—never both. Keep placement predictable where it does not block the main
task. Stack at most four toasts with 16 pixels between them, newest nearest the
edge. Pause timeouts during interaction. Map intent to correct live-region
urgency and avoid many assertive announcements.

Titles state the event ("File saved") or an ongoing -ing action ("Uploading
file"). Keep body copy easy to scan, ideally under about 60 characters. Status
may use time, percent, or amount when trustworthy. A short action label answers
the title directly.

## Review checklist

- Is the surface persistent, light-dismiss, modal, inline, or blocking for a
  clear reason?
- Are initial focus, containment, Escape, and focus restoration correct?
- Does feedback remain perceivable without color or animation?
- Is loading specific, scoped, forward-moving, and reduced-motion safe?
- Can time-limited content pause, and is every critical message persistent?
