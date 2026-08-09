/// Fluent 2 components for web and desktop surfaces.
///
/// Re-exports `fluent_2_core`, so consumers need a single import:
///
/// ```dart
/// import 'package:fluent_2_web/fluent_2_web.dart';
/// ```
///
/// ## Surface, not platform
///
/// This package holds the *web* rendering of each component — the sizes,
/// densities and hover/focus affordances Fluent 2 specifies for pointer-driven
/// surfaces. `fluent_2_mobile` holds the touch rendering of the same
/// components. They are different widgets, not one widget with a platform
/// switch, because the specs genuinely diverge.
///
/// Tokens, theming and the app shell live in `fluent_2_core` and are shared by
/// both. Nothing here imports `package:flutter/material.dart` — see the
/// repository README for why, and `melos run no-material` for the check that
/// enforces it.
///
/// ## Status
///
/// Shared primitives are landing first; component work starts against the
/// inventory in the repository README once they are locked.
library;

export 'package:fluent_2_core/fluent_2_core.dart';

export 'src/buttons/button.dart';
export 'src/buttons/button_style.dart';
export 'src/buttons/compound_button.dart';
export 'src/buttons/split_button.dart';
// The chart foundation. `src/charts/internal/d3/**` and
// `src/charts/internal/responsive.dart` are deliberately NOT exported: the d3
// port is 28 files of unprefixed globals kept internal on purpose, and the
// responsive helper has no public symbol. Tests reach both by deep import,
// which is existing precedent in this repository.
export 'src/charts/axis/axis_builders.dart';
export 'src/charts/axis/axis_label_layout.dart';
export 'src/charts/axis/axis_painter.dart';
export 'src/charts/axis/axis_types.dart';
export 'src/charts/axis/domain_range.dart';
export 'src/charts/axis/tick_format.dart';
export 'src/charts/axis/tick_values.dart';
export 'src/charts/chrome/legend_shape.dart';
export 'src/charts/internal/chart_colors.dart';
export 'src/charts/internal/chart_semantics.dart';
export 'src/charts/internal/chart_text_measurer.dart';
export 'src/charts/internal/chart_text_styles.dart';
export 'src/charts/internal/chart_utils.dart';
export 'src/charts/internal/data_viz_palette.dart';
export 'src/charts/model/bar_data.dart';
export 'src/charts/model/callout_data.dart';
export 'src/charts/model/cartesian_series.dart';
export 'src/charts/model/chart_annotation.dart';
export 'src/charts/model/chart_common.dart';
export 'src/charts/model/chart_value.dart';
export 'src/charts/model/heatmap_data.dart';
export 'src/charts/model/line_options.dart';
export 'src/charts/model/polar_data.dart';
export 'src/charts/model/sankey_data.dart';
export 'src/charts/model/series_v2.dart';
export 'src/inputs/calendar.dart';
export 'src/inputs/calendar_style.dart';
export 'src/inputs/checkbox.dart';
export 'src/inputs/checkbox_style.dart';
export 'src/inputs/date_picker.dart';
export 'src/inputs/date_picker_style.dart';
export 'src/inputs/dropdown.dart';
export 'src/inputs/dropdown_option.dart';
export 'src/inputs/dropdown_option_style.dart';
export 'src/inputs/dropdown_style.dart';
export 'src/inputs/field.dart';
export 'src/inputs/field_style.dart';
export 'src/inputs/info_button.dart';
export 'src/inputs/info_button_style.dart';
export 'src/inputs/info_label.dart';
export 'src/inputs/info_label_style.dart';
export 'src/inputs/input.dart';
export 'src/inputs/input_style.dart';
export 'src/inputs/label.dart';
export 'src/inputs/label_style.dart';
export 'src/inputs/link.dart';
export 'src/inputs/link_style.dart';
export 'src/inputs/radio.dart';
export 'src/inputs/radio_group.dart';
export 'src/inputs/radio_style.dart';
export 'src/inputs/rating.dart';
export 'src/inputs/rating_style.dart';
export 'src/inputs/search_box.dart';
export 'src/inputs/search_box_style.dart';
export 'src/inputs/slider.dart';
export 'src/inputs/slider_style.dart';
export 'src/inputs/spin_button.dart';
export 'src/inputs/spin_button_style.dart';
export 'src/inputs/swatch.dart';
export 'src/inputs/swatch_picker.dart';
export 'src/inputs/swatch_picker_style.dart';
export 'src/inputs/swatch_style.dart';
export 'src/inputs/switch.dart';
export 'src/inputs/switch_style.dart';
export 'src/inputs/tag_picker.dart';
export 'src/inputs/tag_picker_style.dart';
export 'src/inputs/textarea.dart';
export 'src/inputs/textarea_style.dart';
export 'src/inputs/time_picker.dart';
export 'src/inputs/time_picker_style.dart';
export 'src/internal/animated_style.dart';
export 'src/internal/focus_ring.dart';
export 'src/internal/interaction.dart';
export 'src/internal/text_context_menu.dart';
export 'src/navigation/breadcrumb.dart';
export 'src/navigation/breadcrumb_style.dart';
export 'src/navigation/data_grid.dart';
export 'src/navigation/data_grid_style.dart';
export 'src/navigation/hamburger.dart';
export 'src/navigation/list_item.dart';
export 'src/navigation/list_item_style.dart';
export 'src/navigation/nav.dart';
export 'src/navigation/nav_drawer.dart';
export 'src/navigation/nav_style.dart';
export 'src/navigation/tab_list.dart';
export 'src/navigation/tab_style.dart';
export 'src/navigation/toolbar.dart';
export 'src/navigation/toolbar_style.dart';
export 'src/navigation/tree.dart';
export 'src/navigation/tree_style.dart';
export 'src/overlays/dialog.dart';
export 'src/overlays/dialog_style.dart';
export 'src/overlays/drawer.dart';
export 'src/overlays/drawer_style.dart';
export 'src/overlays/menu.dart';
export 'src/overlays/menu_item.dart';
export 'src/overlays/menu_item_style.dart';
export 'src/overlays/menu_style.dart';
export 'src/overlays/popover.dart';
export 'src/overlays/popover_style.dart';
export 'src/overlays/teaching_popover.dart';
export 'src/overlays/teaching_popover_style.dart';
export 'src/overlays/toast.dart';
export 'src/overlays/toast_style.dart';
export 'src/overlays/toaster.dart';
export 'src/surfaces/accordion.dart';
export 'src/surfaces/accordion_style.dart';
export 'src/surfaces/acrylic.dart';
export 'src/surfaces/acrylic_style.dart';
export 'src/surfaces/avatar.dart';
export 'src/surfaces/avatar_group.dart';
export 'src/surfaces/avatar_group_style.dart';
export 'src/surfaces/avatar_style.dart';
export 'src/surfaces/badge.dart';
export 'src/surfaces/badge_style.dart';
export 'src/surfaces/card.dart';
export 'src/surfaces/card_style.dart';
export 'src/surfaces/carousel.dart';
export 'src/surfaces/carousel_style.dart';
export 'src/surfaces/divider.dart';
export 'src/surfaces/divider_style.dart';
export 'src/surfaces/interaction_tag.dart';
export 'src/surfaces/message_bar.dart';
export 'src/surfaces/message_bar_style.dart';
export 'src/surfaces/persona.dart';
export 'src/surfaces/persona_style.dart';
export 'src/surfaces/presence_badge.dart';
export 'src/surfaces/presence_badge_style.dart';
export 'src/surfaces/progressbar.dart';
export 'src/surfaces/progressbar_style.dart';
export 'src/surfaces/skeleton.dart';
export 'src/surfaces/skeleton_style.dart';
export 'src/surfaces/spinner.dart';
export 'src/surfaces/spinner_style.dart';
export 'src/surfaces/status_indicator.dart';
export 'src/surfaces/status_indicator_style.dart';
export 'src/surfaces/tag.dart';
export 'src/surfaces/tag_style.dart';
export 'src/surfaces/tooltip.dart';
export 'src/surfaces/tooltip_style.dart';
