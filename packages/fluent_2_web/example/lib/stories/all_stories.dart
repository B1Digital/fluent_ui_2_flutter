import '../gallery/story.dart';
import 'accordion_stories.dart';
import 'acrylic_surface_stories.dart';
import 'avatar_group_stories.dart';
import 'avatar_stories.dart';
import 'badge_stories.dart';
import 'breadcrumb_stories.dart';
import 'button_stories.dart';
import 'card_stories.dart';
import 'carousel_stories.dart';
import 'checkbox_stories.dart';
import 'compound_button_stories.dart';
import 'data_grid_stories.dart';
import 'dialog_stories.dart';
import 'divider_stories.dart';
import 'drawer_stories.dart';
import 'dropdown_stories.dart';
import 'field_stories.dart';
import 'info_label_stories.dart';
import 'input_stories.dart';
import 'interaction_tag_stories.dart';
import 'label_stories.dart';
import 'link_stories.dart';
import 'list_item_stories.dart';
import 'menu_stories.dart';
import 'message_bar_stories.dart';
import 'nav_stories.dart';
import 'persona_stories.dart';
import 'popover_stories.dart';
import 'presence_badge_stories.dart';
import 'progress_bar_stories.dart';
import 'radio_stories.dart';
import 'rating_stories.dart';
import 'search_box_stories.dart';
import 'skeleton_stories.dart';
import 'slider_stories.dart';
import 'spin_button_stories.dart';
import 'spinner_stories.dart';
import 'split_button_stories.dart';
import 'status_indicator_stories.dart';
import 'swatch_picker_stories.dart';
import 'switch_stories.dart';
import 'tab_list_stories.dart';
import 'tag_picker_stories.dart';
import 'tag_stories.dart';
import 'teaching_popover_stories.dart';
import 'textarea_stories.dart';
import 'toast_stories.dart';
import 'toolbar_stories.dart';
import 'tooltip_stories.dart';
import 'tree_stories.dart';

/// Every component's stories, in sidebar order.
///
/// One file per component under `stories/`, each exporting a single
/// [StorySection]. Generated from what is on disk, so a component whose page is
/// missing simply does not appear and a partial build still runs.
final List<StorySection> allStories = <StorySection>[
  accordionStories,
  acrylicSurfaceStories,
  avatarGroupStories,
  avatarStories,
  badgeStories,
  breadcrumbStories,
  buttonStories,
  cardStories,
  carouselStories,
  checkboxStories,
  compoundButtonStories,
  dataGridStories,
  dialogStories,
  dividerStories,
  drawerStories,
  dropdownStories,
  fieldStories,
  infoLabelStories,
  inputStories,
  interactionTagStories,
  labelStories,
  linkStories,
  listItemStories,
  menuStories,
  messageBarStories,
  navStories,
  personaStories,
  popoverStories,
  presenceBadgeStories,
  progressBarStories,
  radioStories,
  ratingStories,
  searchBoxStories,
  skeletonStories,
  sliderStories,
  spinButtonStories,
  spinnerStories,
  splitButtonStories,
  statusIndicatorStories,
  swatchPickerStories,
  switchStories,
  tabListStories,
  tagPickerStories,
  tagStories,
  teachingPopoverStories,
  textareaStories,
  toastStories,
  toolbarStories,
  tooltipStories,
  treeStories,
];
