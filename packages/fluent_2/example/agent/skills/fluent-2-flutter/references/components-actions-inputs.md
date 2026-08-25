# Actions and inputs

Use this reference for Fluent actions, selection controls, form fields, text
entry, pickers, and value controls. Official sources define product intent;
the checked-out Dart source defines the API that can actually be called.

## Contents

- Button and link
- Checkbox, radio group, switch, and rating
- Field, label, and info label
- Input, textarea, and search box
- Dropdown, select, and combobox
- Slider and spin button
- Tag picker and swatch picker

## Button and link

### Button — `FluentButton`, `FluentCompoundButton`, `FluentSplitButton`

Source: https://fluent2.microsoft.design/components/web/react/core/button/usage/

Use a button for an immediate action and a link for navigation. Choose a
standard button for one action, a split button for one dominant action plus
related alternatives, a menu button when no action is dominant, and a compound
button only when a second line materially clarifies the action. Never repeat a
split button's dominant action in its menu. Use toggle behavior mainly in
toolbars; use a switch for an immediately applied setting.

Put only one primary button in a region and place it first in reading order
(mirrored for RTL). If more than two actions have equal priority, make them all
neutral. Button text must reach 4.5:1 contrast and icons 3:1 in every
interactive state. Icon-only buttons need a semantic label; each split-button
part is a separate target and focus stop. Explain why a disabled action is
unavailable in a tooltip. Use brief, active, sentence-case labels and choose
Save, Finish, Done, Close, Cancel, Got it, or Dismiss by the actual outcome.

### Link — `FluentLink`

Source: https://fluent2.microsoft.design/components/web/react/core/link/usage/

Prefer the default link. Use subtle links cautiously and only where navigation
is already obvious; inline links in prose should remain underlined at rest and
in the visited state. Provide at least two interaction cues from color,
underline, icon, focus, and cursor change. Keep adjacent links far enough apart
to target reliably.

Link text must make sense outside its sentence, identify the destination, and
avoid bare URLs, "Click here," or an unexplained "Learn more." Warn visually
and semantically before opening a new tab or window. Do not style a link as a
button to trigger an in-place action.

## Checkbox, radio group, switch, and rating

### Checkbox — `FluentCheckbox`

Source: https://fluent2.microsoft.design/components/web/react/core/checkbox/usage/

Use checkboxes for independent choices or multiple selection. They normally
defer changes until form submission; use a switch for an immediate binary
change. Use an indeterminate parent only to summarize partially selected
children, and visually indent or otherwise separate those children. Keep a
visible group to about seven options; split larger sets or choose a picker.
Phrase labels positively so checked means yes, use parallel fragments, and
order choices logically (safest to riskiest where consequences matter).

### Radio group — `FluentRadioGroup`, `FluentRadio`

Source: https://fluent2.microsoft.design/components/web/react/core/radiogroup/usage/

Use a radio group for one choice among five or fewer visible options. Select
the most logical first option by default. Prefer vertical layout for scanning
and localization; use a horizontal row only when constrained. Arrow keys move
within the group and Tab enters or leaves it. Never truncate labels. Use
parallel sentence-case fragments with no period or colon; add complete-sentence
subtext only when every option needs explanation.

### Switch — `FluentSwitch`

Source: https://fluent2.microsoft.design/components/web/react/core/switch/usage/

Use a switch for an immediately applied on/off setting. Keep its label close
and name the setting with a noun or positive-state verb; do not write a question
or "Turn on/Turn off." A label may be visually omitted only when context such
as a data-grid column names every switch, and it still needs a hidden accessible
name. Use a checkbox for changes applied only on submission or for mixed state.

### Rating — `FluentRating`

Source: https://fluent2.microsoft.design/components/web/react/core/rating/usage/

Use interactive outlined rating for input, full rating display when score and
review count fit, and compact display when space is tight. Use the largest
supported input size for easier targeting. Empty, half-filled, and filled icons
may use star, circle, or square shapes, but one scale must remain consistent.
Expose the current value and range, support keyboard adjustment, and keep
foreground/background and selected/unselected contrast at 3:1—or make an
explicit numeric value the authoritative text alternative.

## Field, label, and info label

### Field — `FluentField`

Source: https://fluent2.microsoft.design/components/web/react/core/field/usage/

Use `FluentField` to combine one visible label, required state, helper text,
validation, and one form control. Prefer labels above controls; left alignment
is an exception for consistent, space-constrained fields. Use success, warning,
and error messages to explain the state and next step without relying on red.
If every field is required, state that once before the form instead of marking
every field; a simple two-field sign-in needs no required marker. A disabled
control may look disabled while its label and prior helper or validation text
remain perceivable.

### Label — `FluentLabel`

Source: https://fluent2.microsoft.design/components/web/react/core/label/usage/

Use a short sentence-case label to name one control or related group. Place it
above by default, preserve the programmatic association through reflow, let it
wrap, and never truncate it. Do not add a colon or end punctuation unless the
label is a question. Never substitute placeholder text for a label.

### Info label and button — `FluentInfoLabel`, `FluentInfoButton`

Source: https://fluent2.microsoft.design/components/web/react/core/infolabel/usage/

Use an info label only for supplemental, nonessential explanation. Limit a
local area to roughly two or three info buttons; more usually means the base
design is unclear. Keep the popover to one or two short sentences and at most
one specifically named link. The button stays in the Tab order and the popover
closes on outside selection or Escape. A 20-by-20 small control needs at least
2 pixels from nearby interactive elements and is only for explicitly compact
density. Keep critical instructions and errors permanently visible.

## Input, textarea, and search box

### Input — `FluentInput`

Source: https://fluent2.microsoft.design/components/web/react/core/input/usage/

Use input for one line of free-form text and size it near the expected answer
length. Choose the correct keyboard/input type and distinguish disabled from
read-only. Masks may demonstrate formats, but browser-native input types can
introduce presentation that differs from Fluent. Keep format requirements in a
visible label or helper; placeholders are short supplemental examples with no
period and are never the label.

### Textarea — `FluentTextarea`

Source: https://fluent2.microsoft.design/components/web/react/core/textarea/usage/

Use textarea for long or multiline text and choose initial dimensions for the
expected volume. Fluent textareas are not resizable by default and scroll on
overflow; enable resize only when control over the visible writing area is
useful. Preserve selection and scrolling at large text scales. Put essential
requirements, limits, and validation outside the placeholder.

### Search box — `FluentSearchBox`

Source: https://fluent2.microsoft.design/components/web/react/core/searchbox/usage/

Make clear whether search updates live or after submission. Keep search, clear,
optional filter, and result behavior consistent. Show recent topics on focus,
replace them with ranked suggestions as the query develops, and put the most
relevant matches first. Preserve the query on return where useful and announce
meaningful result changes without narrating every keystroke. At 400% zoom or a
narrow viewport, an icon may open a full-width field, but all search behavior
must remain available.

## Dropdown, select, and combobox

### Dropdown — `FluentDropdown<T>`

Source: https://fluent2.microsoft.design/components/web/react/core/dropdown/usage/

Use dropdown when a constrained list needs custom styling or drives filtering
or sorting. The current Flutter widget is controlled and single-select even
though official Fluent also describes multi-select. Keep focus on the trigger;
use Arrows/Home/End to move, Enter or Space to select, Escape to close, and
close before Tab continues. Disabled options stay visible but inactive.

Give rich options a plain-text equivalent for type-ahead and closed-state
display, and do not put interactive controls inside an option. Prefer an inline
popup relationship where a platform screen reader cannot follow an owned
overlay. Placeholder text is only a hint, never the visible label.

### Select — compose with `FluentDropdown<T>`

Source: https://fluent2.microsoft.design/components/web/react/core/select/usage/

Official Select is browser-native, single-choice, intended for at least four
options, and especially suitable for forms and mobile accessibility. This
repository exports no `FluentSelect`; `FluentDropdown<T>` is only a deliberate
composition after its behavior is verified. Preserve native platform behavior
when that matters. Choose an intentional default and use short parallel options,
including "None" when no selection is valid.

### Combobox — missing

Source: https://fluent2.microsoft.design/components/web/react/core/combobox/usage/

Use combobox for a long list that benefits from filtering, free-form answers,
or multiple selection. Multi-select keeps the popup open until dismissal and
should show choices as tags. Treat Space as typed input while filtering
multiword choices, but as selection after keyboard navigation activates an
option. Give rich options a text equivalent and maintain an accessible inline
relationship to the popup.

No `FluentCombobox` is currently exported. Do not rename dropdown or tag picker
to imply parity. Report the gap or deliberately compose input, overlay, options,
and complete listbox keyboard/assistive-technology behavior.

## Slider and spin button

### Slider — `FluentSlider`

Source: https://fluent2.microsoft.design/components/web/react/core/slider/usage/

Use a slider for an approximate value in a bounded range. Choose continuous
behavior for unmarked values and stepped behavior for defined increments.
Avoid extremely small or large ranges and pair with numeric entry when precision
matters. Support thumb drag and track selection with pointer, keyboard, and
touch; mirror horizontal direction under RTL. Always provide a label, expose
min/max/step/current value, and make tooltip value text available to screen
readers.

### Spin button — `FluentSpinButton`, `FluentSpinButtonStepper`

Source: https://fluent2.microsoft.design/components/web/react/core/spin/usage/

Use a spin button for precise increments in a modest range—not fewer than three
choices or an enormous range. Support direct entry, Arrow increments, Page
Up/Down bulk steps, and Home/End bounds. Disable only the reached stepper at a
limit; keep the input enabled so the composite remains a usable target. Expose
minimum and maximum semantics, validate intentionally, and show the unit in the
value or hint.

## Tag picker and swatch picker

### Tag picker — `FluentTagPicker`

Source: https://fluent2.microsoft.design/components/web/react/core/tagpicker/usage/

Use tag picker for multiple named values chosen by typing and suggestions.
Focus opens suggestions, typing filters them, Arrow keys change the active
match, and Enter inserts a tag. Tags wrap and grow the field by default; apply
truncation only with an explicit product rule. Name the input, label each
dismiss action, prevent duplicates, and communicate that Backspace removes the
last tag. Use the secondary slot sparingly, such as for Clear all.

### Swatch picker — `FluentSwatchPicker`, `FluentSwatch`

This is a repository extension rather than one of the 47 indexed Fluent web
core pages. Use it for a compact set of visual choices such as colors. Give
every swatch a textual name and provide a non-color selection cue.

## Review checklist

- Is the control correct for action, navigation, one choice, multiple choices,
  immediate settings, deferred form changes, free-form entry, or approximate
  versus precise values?
- Does every control have a persistent accessible name and complete keyboard
  path?
- Are required, invalid, disabled, read-only, mixed, loading, and selected
  states exposed without relying on color?
- Do popups close predictably and preserve or restore focus?
- Does content remain understandable when localized, zoomed, or reflowed?
