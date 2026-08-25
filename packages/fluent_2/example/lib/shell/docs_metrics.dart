import 'package:flutter/widgets.dart';

/// Every measurement taken off the live Fluent UI React Storybook.
///
/// Read from <https://storybooks.fluentui.dev/react> at a 1600x1100 viewport,
/// device pixel ratio 1, via `getBoundingClientRect` and `getComputedStyle`
/// rather than by eye. The capture script beside the crawler
/// (`crawlers/storybooks-fluentui/capture_docs.mjs`) writes a reference PNG per
/// section so these can be re-checked against a picture.
///
/// ## Why these are literals and not theme tokens
///
/// This is Storybook's chrome, not Fluent's design language. The two only look
/// related. `#0078D4` here is Storybook's selection blue, which is
/// *communication blue* — not `brandBackground`, which is `#0F6CBD` on the web
/// ramp. More importantly the chrome has to stay readable while the preview
/// underneath is rendering a dark or high-contrast variant, so it cannot follow
/// the selected theme even where the values coincide. Nothing in this file
/// touches `FluentTheme.of(context)`, and that is deliberate.
abstract final class DocsMetrics {
  // --- Shell ---------------------------------------------------------------

  /// Total width of the sidebar column, including its 12px gutters.
  static const double sidebarWidth = 300;

  /// Width of a sidebar row: the full 275px hit target, inset 12px from the
  /// window edge.
  static const double sidebarItemWidth = 275;

  /// Height of a sidebar row. Not derived from the text — 14/24 type in a 33px
  /// box means the padding below is 1px tighter than the padding above.
  static const double sidebarItemHeight = 33;

  /// `padding: 5px 0 4px 22px` on a leaf row. Nested rows add [sidebarIndent].
  static const EdgeInsets sidebarItemPadding = EdgeInsets.fromLTRB(22, 5, 0, 4);

  /// Extra leading inset per nesting level below a group heading.
  static const double sidebarIndent = 18;

  /// The search field is 28px tall with 14/14 type — line height equal to font
  /// size, which is why it reads tighter than any other control in the chrome.
  static const double searchHeight = 28;

  // --- Docs body -----------------------------------------------------------

  /// The docs column caps at 1200px and is inset 50px from the content pane.
  static const double contentMaxWidth = 1200;

  /// Horizontal inset of the docs column inside the content pane.
  static const double contentInset = 50;

  /// Width of the story column once the "On this page" rail has taken its share
  /// of [contentMaxWidth].
  static const double storyColumnWidth = 984;

  /// Width of the right-hand "On this page" rail.
  static const double railWidth = 216;

  // --- Preview card --------------------------------------------------------

  /// `margin: 25px 0 40px` between consecutive preview cards.
  static const EdgeInsets cardMargin = EdgeInsets.only(top: 25, bottom: 40);

  /// The card reserves 40px above the story for the zoom toolbar.
  static const double cardTopPadding = 40;

  static const double cardRadius = 16;

  /// Height of a card action button ("Open in new tab", "Show code").
  static const double cardActionHeight = 29;

  /// Action buttons are rounded at the top only — they sit flush against the
  /// card's bottom edge, and against the code panel when it is open.
  static const BorderRadius cardActionRadius = BorderRadius.only(
    topLeft: Radius.circular(5),
    topRight: Radius.circular(5),
  );

  static const EdgeInsets cardActionPadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 4,
  );

  // --- Toolbar -------------------------------------------------------------

  /// Height of the "Copy Page" split button under the page title.
  static const double toolbarButtonHeight = 36;

  // --- Rules ---------------------------------------------------------------

  static const double ruleThickness = 1;

  /// `margin: 48px 0` around the rule that closes the page header.
  static const double ruleGap = 48;

  // --- Colours -------------------------------------------------------------

  /// Sidebar row label.
  static const Color sidebarText = Color(0xFF11100F);

  /// Selected sidebar row. Storybook's blue, not Fluent's brand ramp.
  static const Color sidebarSelected = Color(0xFF0078D4);

  static const Color sidebarSelectedText = Color(0xFFFFFFFF);

  /// Body copy, and the code panel's background — the same value in both roles.
  static const Color bodyText = Color(0xFF242424);

  /// Page and section titles.
  static const Color headingText = Color(0xFF000000);

  /// Card borders, and the outline on toolbar buttons.
  static const Color border = Color(0xFFD1D1D1);

  /// The horizontal rule under the page header.
  static const Color rule = Color(0xFFE1DFDD);

  /// The continuous vertical rule down the "On this page" rail. Sampled off the
  /// live rail rather than reused from [rule] — they are two pixels apart and
  /// this one is the measured value.
  static const Color railLine = Color(0xFFEDEBE9);

  /// The current section's segment on that rule. Not the sidebar's selection
  /// blue: the rail uses its own, bluer value.
  static const Color railActive = Color(0xFF436DCD);

  /// Card action button background.
  static const Color actionBackground = Color(0xFFF8F8F8);

  /// Card action button label.
  static const Color actionText = Color(0xFF201F1E);

  static const Color canvas = Color(0xFFFFFFFF);

  // --- Type ----------------------------------------------------------------

  /// Segoe UI is not licensable, so the chrome renders in Selawik — the
  /// metric-compatible open substitute the rest of this design system already
  /// ships. Sizes and line heights below are Storybook's, unchanged.
  static const String fontFamily = 'Selawik';

  static const List<String> fontFamilyFallback = <String>[
    '-apple-system',
    'BlinkMacSystemFont',
    'Roboto',
    'Helvetica Neue',
    'sans-serif',
  ];

  static TextStyle get _base => const TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Page title. The tracking is genuinely -1.76px at 44px — Storybook sets
  /// `letter-spacing: -0.04em` on its h1 and this is what that resolves to.
  static TextStyle get h1 => _base.copyWith(
    fontSize: 44,
    height: 60 / 44,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.76,
    color: headingText,
  );

  /// Section-group heading ("Stories").
  static TextStyle get h2 => _base.copyWith(
    fontSize: 24,
    height: 28 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.96,
    color: headingText,
  );

  /// Story section title. 16.38px is not a typo: Storybook sizes its h3 in `em`
  /// against a 14px root, and 1.17em lands here.
  static TextStyle get h3 => _base.copyWith(
    fontSize: 16.38,
    height: 20 / 16.38,
    fontWeight: FontWeight.w700,
    color: bodyText,
  );

  static TextStyle get body =>
      _base.copyWith(fontSize: 14, height: 20 / 14, color: bodyText);

  static TextStyle get sidebarItem =>
      _base.copyWith(fontSize: 14, height: 24 / 14, color: sidebarText);

  static TextStyle get sidebarGroup => _base.copyWith(
    fontSize: 15,
    height: 24 / 15,
    fontWeight: FontWeight.w700,
    color: headingText,
  );

  static TextStyle get action => _base.copyWith(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: actionText,
  );

  /// The "ON THIS PAGE" rail label.
  static TextStyle get railLabel => _base.copyWith(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: bodyText,
  );
}
