import 'shell/catalog.dart';

import 'pages/concepts_introduction.dart';
import 'pages/concepts_package_maturity_levels.dart';
import 'pages/theme_border_radii.dart';
import 'pages/theme_colors.dart';
import 'pages/theme_fonts.dart';
import 'pages/theme_shadows.dart';
import 'pages/theme_spacing.dart';
import 'pages/theme_stroke_widths.dart';
import 'pages/theme_typography.dart';
import 'pages/components_accordion.dart';
import 'pages/components_avatar.dart';
import 'pages/components_avatargroup.dart';
import 'pages/components_badge_badge.dart';
import 'pages/components_badge_counter_badge.dart';
import 'pages/components_badge_presencebadge.dart';
import 'pages/components_breadcrumb.dart';
import 'pages/components_button_button.dart';
import 'pages/components_button_compoundbutton.dart';
import 'pages/components_button_menubutton.dart';
import 'pages/components_button_splitbutton.dart';
import 'pages/components_button_togglebutton.dart';
import 'pages/components_card_card.dart';
import 'pages/components_card_cardfooter.dart';
import 'pages/components_card_cardheader.dart';
import 'pages/components_card_cardpreview.dart';
import 'pages/components_carousel_carousel.dart';
import 'pages/components_carousel_carouselnav.dart';
import 'pages/components_checkbox.dart';
import 'pages/components_datagrid.dart';
import 'pages/components_dialog.dart';
import 'pages/components_divider.dart';
import 'pages/components_drawer.dart';
import 'pages/components_dropdown.dart';
import 'pages/components_field.dart';
import 'pages/components_infolabel.dart';
import 'pages/components_input.dart';
import 'pages/components_label.dart';
import 'pages/components_link.dart';
import 'pages/components_list.dart';
import 'pages/components_menu_menu.dart';
import 'pages/components_menu_menulist.dart';
import 'pages/components_messagebar.dart';
import 'pages/components_nav.dart';
import 'pages/components_persona.dart';
import 'pages/components_popover.dart';
import 'pages/components_progressbar.dart';
import 'pages/components_radiogroup.dart';
import 'pages/components_rating.dart';
import 'pages/components_searchbox.dart';
import 'pages/components_skeleton.dart';
import 'pages/components_slider.dart';
import 'pages/components_spinbutton.dart';
import 'pages/components_spinner.dart';
import 'pages/components_swatchpicker.dart';
import 'pages/components_switch.dart';
import 'pages/components_tablist.dart';
import 'pages/components_tag_interactiontag.dart';
import 'pages/components_tag_tag.dart';
import 'pages/components_tag_taggroup.dart';
import 'pages/components_tagpicker.dart';
import 'pages/components_teachingpopover.dart';
import 'pages/components_textarea.dart';
import 'pages/components_toast.dart';
import 'pages/components_toolbar.dart';
import 'pages/components_tooltip.dart';
import 'pages/components_tree.dart';
import 'pages/compat_components_calendar.dart';
import 'pages/compat_components_datepicker.dart';
import 'pages/compat_components_timepicker.dart';
import 'pages/charts_areachart.dart';
import 'pages/charts_charttable.dart';
import 'pages/charts_declarativechart.dart';
import 'pages/charts_donutchart.dart';
import 'pages/charts_funnelchart.dart';
import 'pages/charts_ganttchart.dart';
import 'pages/charts_gaugechart.dart';
import 'pages/charts_groupedverticalbarchart.dart';
import 'pages/charts_heatmapchart.dart';
import 'pages/charts_horizontalbarchart.dart';
import 'pages/charts_horizontalbarchartwithaxis.dart';
import 'pages/charts_legends.dart';
import 'pages/charts_linechart.dart';
import 'pages/charts_polarchart.dart';
import 'pages/charts_sankeychart.dart';
import 'pages/charts_scatterchart.dart';
import 'pages/charts_sparkline.dart';
import 'pages/charts_vegadeclarativechart.dart';
import 'pages/charts_verticalbarchart.dart';
import 'pages/charts_verticalstackedbarchart.dart';

/// The sidebar, in order.
///
/// Group order and page order mirror the Fluent UI React Storybook's own
/// sidebar, taken from `test/fixtures/storybook_contract.json`. Generated —
/// re-run the generator rather than editing this list, or the registry and
/// the reference will drift.
const List<DocsGroup> catalog = <DocsGroup>[
  DocsGroup(
    title: 'Concepts',
    pages: <DocsPage>[introductionPage, packageMaturityLevelsPage],
  ),
  DocsGroup(
    title: 'Theme',
    pages: <DocsPage>[
      themeBorderRadiiPage,
      themeColorsPage,
      themeFontsPage,
      themeShadowsPage,
      themeSpacingPage,
      themeStrokeWidthsPage,
      themeTypographyPage,
    ],
  ),
  DocsGroup(
    title: 'Components',
    pages: <DocsPage>[
      accordionPage,
      avatarPage,
      avatarGroupPage,
      badgePage,
      counterBadgePage,
      presenceBadgePage,
      breadcrumbPage,
      buttonPage,
      compoundButtonPage,
      menuButtonPage,
      splitButtonPage,
      toggleButtonPage,
      cardPage,
      cardFooterPage,
      cardHeaderPage,
      cardPreviewPage,
      carouselPage,
      carouselNavPage,
      checkboxPage,
      dataGridPage,
      dialogPage,
      dividerPage,
      drawerPage,
      dropdownPage,
      fieldPage,
      infoLabelPage,
      inputPage,
      labelPage,
      linkPage,
      listPage,
      menuPage,
      menuListPage,
      messageBarPage,
      navPage,
      personaPage,
      popoverPage,
      progressBarPage,
      radioGroupPage,
      ratingPage,
      searchBoxPage,
      skeletonPage,
      sliderPage,
      spinButtonPage,
      spinnerPage,
      swatchPickerPage,
      switchPage,
      tablistPage,
      interactionTagPage,
      tagPage,
      tagTagGroupPage,
      tagpickerPage,
      teachingPopoverPage,
      textareaPage,
      toastPage,
      toolbarPage,
      tooltipPage,
      treePage,
    ],
  ),
  DocsGroup(
    title: 'Compat Components',
    pages: <DocsPage>[calendarPage, datePickerPage, timePickerPage],
  ),
  DocsGroup(
    title: 'Charts',
    pages: <DocsPage>[
      areaChartPage,
      chartTablePage,
      declarativeChartPage,
      donutChartPage,
      funnelChartPage,
      ganttChartPage,
      gaugeChartPage,
      groupedVerticalBarChartPage,
      heatMapChartPage,
      horizontalBarChartPage,
      horizontalBarChartWithAxisPage,
      legendsPage,
      lineChartPage,
      polarChartPage,
      sankeyChartPage,
      scatterChartPage,
      sparklinePage,
      vegaDeclarativeChartPage,
      verticalBarChartPage,
      verticalStackedBarChartPage,
    ],
  ),
];

/// Every page, flattened.
Iterable<DocsPage> get allPages =>
    catalog.expand((DocsGroup group) => group.pages);

/// The page with this id, or null.
DocsPage? pageById(String id) {
  for (final DocsGroup group in catalog) {
    for (final DocsPage page in group.pages) {
      if (page.id == id) {
        return page;
      }
    }
  }
  return null;
}

/// The section with this id, and the page it belongs to.
({DocsPage page, DocsSection section})? sectionById(String id) {
  for (final DocsPage page in allPages) {
    for (final DocsSection section in page.sections) {
      if (section.id == id) {
        return (page: page, section: section);
      }
    }
  }
  return null;
}
