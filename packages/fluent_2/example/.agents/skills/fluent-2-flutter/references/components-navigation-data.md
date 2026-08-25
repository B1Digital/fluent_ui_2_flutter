# Navigation and data

Use this reference for disclosure, wayfinding, collections, command groups,
and hierarchical data. Inspect the current Dart constructor and tests before
emitting code.

## Contents

- Accordion
- Breadcrumb
- Carousel
- List
- Menu
- Nav
- Tab list
- Toolbar
- Tree
- Data grid extension

## Accordion — `FluentAccordion`, `FluentAccordionItem`

Source: https://fluent2.microsoft.design/components/web/react/core/accordion/usage/

Use accordion to reduce the initial density of related optional sections, such
as an FAQ. Never hide information required for the current task or information
that must be compared across panels. Items are closed by default; open a useful
starting section deliberately. Allow several panels to remain open only when
that helps comparison without becoming overwhelming.

Keep the disclosure chevron consistently at the same edge. Headers are brief,
sentence-case descriptions with no period, retain heading hierarchy, and act
as buttons. Expose expanded state; Enter or Space toggles and the documented
arrow behavior moves among headers.

## Breadcrumb — `FluentBreadcrumb`

Source: https://fluent2.microsoft.design/components/web/react/core/breadcrumb/usage/

Use breadcrumbs as secondary navigation inside a deep hierarchy; always pair
them with primary top or side navigation. Show hierarchy, never session history.
The first item is the root, the final item is the current location, and a
disabled item means that hierarchy level has no landing page. A noninteractive
file path is plain text with spaced chevron or slash separators—not links.

Keep a trail around 30–50% of the surface width when practical so it retains
context at 400% zoom. Breadcrumbs never wrap. On overflow, keep first and last
visible and collapse from the second item into a menu. Add a hover/focus tooltip
for overflow; use a count instead of an unreadably long list. Interactive labels
normally truncate beyond 30 characters and tooltip text beyond 80; never wrap a
long item and always expose its full name on hover and focus. At 400% zoom or a
small viewport, shorten the trail to the final level.

Wrap web breadcrumbs in a named navigation landmark and ordered-list hierarchy;
mark the current location and keep visual dividers noninteractive and ignored by
assistive technology. Disabled levels remain focusable and announce the full
hierarchy. Mirror direction under RTL.

Current Flutter gaps: `FluentBreadcrumbItem(enabled: false)` refuses focus,
the overflow trigger's semantic label is hardcoded to English "More," and no
overflow-count/tooltip parameter exists. The widget exposes a named semantics
container and selected current item but does not guarantee browser `nav` and
ordered-list roles. Treat these as real gaps; do not claim parity. Use
`maxDisplayedItems` plus app-owned responsive logic, wrap truncated label
widgets in tooltips where possible, and test the rendered web accessibility
tree. Overflow rows keep framework focus on the trigger, so verify screen-reader
announcement of Arrow-key changes rather than assuming it. Overflow placement
also uses physical left alignment and lacks RTL coverage; test or fix the
anchoring before claiming directional parity.

## Carousel — `FluentCarousel`, `FluentCarouselStep`

Source: https://fluent2.microsoft.design/components/web/react/core/carousel/usage/

Use a carousel when related cards, media, or promotions can share one region
without simultaneous comparison. Content may contain actions, but navigation
is self-contained and independent of the page. Choose step controls for ordinary
content or image previews for a gallery. Provide previous/next and position
information plus direct navigation when useful.

Avoid automatic advancement for task-critical content. If autoplay exists,
provide a visible pause control and pause on interaction; honor reduced motion.
At 400% zoom and widths of 600 pixels or less, snap to full width and reflow
responsively down to 320 pixels while preserving media aspect ratio.

## List — `FluentList<T>`, `FluentListItem<T>`

Source: https://fluent2.microsoft.design/components/web/react/core/list/usage/

Use a list for independent peer items in a vertical stack. Use a data grid or
table for related columns and a tree for nested hierarchy. Keep item structures
parallel, similar in length, and never include empty or disabled placeholders.
Use list semantics when there is no selection and listbox/option semantics when
selection is the behavior; grid is not an appropriate fallback for irregular
item actions.

Define one primary action. When selection is primary, click, Enter, or Space
selects the parent. When another action is primary, click/Enter invokes it and
Space toggles selection. Right Arrow can enter secondary actions; Left Arrow or
Escape returns to the parent. Child controls keep their own actions. Introduce
the list clearly and number it only when sequence or rank matters.

## Menu — `FluentMenu`, `FluentMenuItem`

Source: https://fluent2.microsoft.design/components/web/react/core/menu/usage/

Use a menu for a transient list of immediate commands or destinations, not to
collect form data. Choose default command items, checkbox items for several
independent settings, or radio items for one setting. Order frequent actions
first and dangerous actions last; group sparingly with spacing, headings, or
dividers. Keep labels short enough for the 300-pixel maximum width and avoid
wrapped menu rows.

Avoid deep submenus and name any submenu trigger. Support Up/Down, Home/End,
Enter or Space, Escape, type-ahead where available, and focus restoration.
Secondary content is reserved for a keyboard shortcut that performs the same
command. `FluentMenuItem` is item data, not a standalone widget.

## Nav — `FluentNav` and nav item widgets

Source: https://fluent2.microsoft.design/components/web/react/core/nav/usage/

Use Nav for persistent movement among an app's main sections. It supports only
two visible levels (items or category plus subitems); use Tree for deeper
hierarchy. Choose a task-oriented verb taxonomy or feature-oriented noun
taxonomy from research, keep labels brief and plain, prioritize user goals, and
hold item order consistent across platforms. Search and pinning do not repair
incoherent navigation.

Categories disclose subitems and are not destinations. Keep selection separate
from focus; when a selected subitem's category closes, show selection on the
category. Limit a node to one secondary action or move several into overflow.
Secondary actions must exist in the semantics tree even when visually revealed
only on hover, and must also be reachable through a context menu.

Use recognizable category icons or omit icons consistently; icon-only Nav is
unsupported. Do not move the category chevron. Avoid the optional footer because
it can obscure content at 400% zoom. The standard web layout is about 260 pixels
wide and becomes an overlay around 640 pixels; Flutter should reproduce the
responsive intent with project breakpoints, not copy a web constant blindly.

`FluentNavSectionHeader` groups items without collapsing them. Reach for it when a
label should organise a list rather than hide it, and for `FluentNavCategory`
only when the group genuinely needs to open and close. It is the one nav part
that works outside a `FluentNav`, so it is safe in any nav-shaped list.

`FluentNavDrawer` is the panel a nav sits in: 260 wide by default, on the nav
surface, with the body gutters already applied. Leave `size` unset unless a
project genuinely needs another width, since passing one hands both width and
transition length back to `FluentDrawer`. Pair it with `FluentHamburger`, which
owns no state: the app decides whether the drawer is open, and the same button
appears in the drawer header to close and in page content to open. Set
`expanded` on the page-side button of an inline nav only; an overlay nav does
not need it.

Keyboard: up and down walk the rows and wrap at both ends, home and end jump to
the ends, and the whole nav is a single tab stop unless `tabbable: true` is
passed. Rows that cannot take focus are skipped, so a divider, a section header,
a static app item and a disabled row never interrupt the sequence. Selection and
focus stay separate: moving focus does not select, and clicking a row selects
without moving the roving index.

Styling: `FluentNavItemTheme` takes a catch-all `style` plus per-kind slots, so a
project can make category headers read differently from their subitems without
passing `style` to every widget. Resolution is per-property and innermost wins:
defaults, `style`, the kind slot, then the widget's own `style`.

## Tab list — `FluentTabList<T>`, `FluentTab<T>`

Source: https://fluent2.microsoft.design/components/web/react/core/tablist/usage/

Use tabs for peer categories in one context or a small set of closely related,
frequent pages. Use links for broader navigation and buttons for actions. Keep
one tab selected initially, usually the first. Horizontal tabs never wrap or
scroll; move excess items to an overflow menu or choose dropdown/accordion when
small layouts would hide too many tabs. Use one label format—text, text plus
icon, or icon-only—across the set.

Associate every tab with a panel and expose the current selection. Decide
whether arrow focus activates immediately or Enter/Space confirms, then stay
consistent. Icon-only tabs require both a semantic label and tooltip. A custom
overflow trigger needs tab semantics. Labels are short, parallel nouns or
phrases in sentence case with no punctuation.

## Toolbar — `FluentToolbar`, `FluentToolbarDivider`

Source: https://fluent2.microsoft.design/components/web/react/core/toolbar/usage/

Use a toolbar for frequent actions related to the current view or task. Group
related controls with whitespace or dividers and separate destructive or
state-changing actions. Place it where the main task needs it; if it is
secondary, let people hide it to reduce distraction. A toolbar grows but never
wraps; move overflow into a final menu and include text beside icons there.

Use roving focus so Tab enters/leaves the group and arrows move within it while
embedded controls retain their native behavior. Name each toolbar when more
than one exists. Use only familiar icons and give icon buttons concise tooltips
and semantic labels.

## Tree — `FluentTree`, `FluentTreeItem`

Source: https://fluent2.microsoft.design/components/web/react/core/tree/usage/

Use Tree only for real parent/child hierarchy such as folders or nested
categories. Choose basic rows or persona rows, then one interaction mode:
expand/collapse-only, navigation, or multiselect. In multiselect, selecting a
parent selects descendants and deselecting a child makes the parent mixed.

Wrap labels by default. Truncate only when early words still distinguish items,
and expose every full label in a tooltip. Indent children consistently; reserve
chevron space for leaves. Use simple icons, textual badge equivalents, and at
most one or two quick actions. Because quick actions in a tree are unexpected,
also expose them through a visible toolbar or menu. Name the tree and expose
level, position, set size, expanded, mixed, and selected states. Mirror
Left/Right hierarchy behavior under RTL.

## Data grid — `FluentDataGrid`, `FluentDataGridCell`

Data grid is a repository extension rather than one of the 47 indexed web-core
usage pages. Use it for related rows and columns that need grid navigation,
sorting, or row state. Define columns with `FluentDataGridColumn` and rows with
`FluentDataGridRow` from the current API.

Expose headers, row/column position, sorting, selection, and focus. Do not put
every cell control in the page Tab order; use grid navigation and enter an
interactive cell deliberately. Provide a narrow-screen alternative when the
table cannot reflow.

## Review checklist

- Does the component represent disclosure, hierarchy, location, peer views,
  commands, or selection accurately?
- Are selection, focus, expansion, and the current location distinct?
- Do keyboard behavior, focus restoration, RTL, semantics, and overflow match
  the chosen pattern?
- Does the layout remain usable at 400% zoom and large text sizes?
