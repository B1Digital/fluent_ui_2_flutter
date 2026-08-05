# Fluent 2 to Flutter coverage matrix

Status meanings:

- **Implemented**: a purpose-built public Flutter widget exists.
- **Compose**: use the listed existing API or raw Flutter primitive, but no
  one-to-one Fluent widget exists.
- **Missing**: no safe equivalent exists; report or implement the gap
  deliberately.

## Official web core components

| Fluent component | Status | Flutter mapping |
| --- | --- | --- |
| Accordion | Implemented | `FluentAccordion`, `FluentAccordionItem` |
| Avatar | Implemented | `FluentAvatar`, optional `FluentPresenceBadge` |
| Avatar group | Implemented | `FluentAvatarGroup` |
| Badge | Implemented | `FluentBadge` |
| Breadcrumb | Implemented | `FluentBreadcrumb` |
| Button | Implemented | `FluentButton`, `FluentCompoundButton`, `FluentSplitButton` |
| Card | Implemented | `FluentCard` |
| Carousel | Implemented | `FluentCarousel`, `FluentCarouselStep` |
| Checkbox | Implemented | `FluentCheckbox` |
| Combobox | Missing | No `FluentCombobox`; deliberate composite required |
| Dialog | Implemented | `FluentDialog` |
| Divider | Implemented | `FluentDivider` |
| Drawer | Implemented | `FluentDrawer` |
| Dropdown | Implemented | `FluentDropdown<T>`, `FluentDropdownOption<T>` |
| Field | Implemented | `FluentField` |
| Fluent provider | Implemented | `FluentApp`, `FluentTheme`, `FluentThemeOverride` |
| Icon | Compose | Flutter `Icon` plus `FluentIcons` |
| Image | Compose | Flutter `Image` plus semantics and fallback |
| Info label | Implemented | `FluentInfoLabel`, `FluentInfoButton` |
| Input | Implemented | `FluentInput` |
| Label | Implemented | `FluentLabel` |
| Link | Implemented | `FluentLink` |
| List | Implemented | `FluentList<T>`, `FluentListItem<T>` |
| Menu | Implemented | `FluentMenu` with `FluentMenuItem` data |
| Message bar | Implemented | `FluentMessageBar` |
| Nav | Implemented | `FluentNav` and nav item widgets |
| Persona | Implemented | `FluentPersona` |
| Popover | Implemented | `FluentPopover` |
| Progress bar | Implemented | `FluentProgressBar` |
| Radio group | Implemented | `FluentRadioGroup<T>`, `FluentRadio<T>` |
| Rating | Implemented | `FluentRating` |
| Search box | Implemented | `FluentSearchBox` |
| Select | Compose | Controlled single-select `FluentDropdown<T>` |
| Skeleton | Implemented | `FluentSkeleton` |
| Slider | Implemented | `FluentSlider` |
| Spin button | Implemented | `FluentSpinButton` |
| Spinner | Implemented | `FluentSpinner` |
| Switch | Implemented | `FluentSwitch` |
| Tab list | Implemented | `FluentTabList<T>`, `FluentTab<T>` |
| Tag | Implemented | `FluentTag`, `FluentInteractionTag` |
| Tag picker | Implemented | `FluentTagPicker<T>` |
| Text | Compose | Flutter `Text` with Fluent typography tokens |
| Textarea | Implemented | `FluentTextarea` |
| Toast | Implemented | `FluentToast`, `FluentToaster` |
| Toolbar | Implemented | `FluentToolbar`, `FluentToolbarDivider` |
| Tooltip | Implemented | `FluentTooltip` |
| Tree | Implemented | `FluentTree` with `FluentTreeItem` data |

## Repository extensions and exported building blocks

| Area | Public Flutter API |
| --- | --- |
| Acrylic | `FluentAcrylicSurface` |
| Data grid | `FluentDataGrid`, `FluentDataGridCell` |
| Status | `FluentStatusIndicator`, `FluentPresenceBadge` |
| Swatches | `FluentSwatchPicker`, `FluentSwatch` |
| Teaching | `FluentTeachingPopover` |
| Interaction | `FluentInteractive`, `FluentFocusRing` |
| Animation | `FluentAnimatedStyle`, `FluentPopoverEntrance` |
| Text editing | `FluentTextContextMenu`, `FluentInputFocusUnderline` |
| Low-level controls | `FluentSpinButtonStepper`, `FluentTagDismissGlyph` |

Use the low-level building blocks only when the complete component cannot meet
the requirement. Preserve the original resolver, style, semantics, focus, and
motion contracts when recomposing.

## Platform coverage

| Platform | Current repository status |
| --- | --- |
| Core | Tokens, themes, icons, typography, material, elevation, motion, app shell |
| Web/desktop | Broad component implementation through `fluent_2_web` |
| iOS/Android | `fluent_2_mobile` barrel must be inspected; no component parity should be assumed |
| Fluent AI | No dedicated AI component API; use explicit composition or report gaps |

## Keeping the matrix honest

Run `node scripts/audit-widget-coverage.mjs`. It compares the 47 official web
slugs with `widget-coverage.json` and checks every exported Flutter `Widget`
subclass against the mappings. Regenerate `flutter-api-surface.md` when the
public barrels change.
