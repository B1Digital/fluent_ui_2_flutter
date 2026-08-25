import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Carousel docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
///
/// Upstream composes a carousel out of eight elements — `Carousel`,
/// `CarouselViewport`, `CarouselSlider`, `CarouselCard`, `CarouselNavContainer`,
/// `CarouselNav`, `CarouselNavButton` and `CarouselButton`. [FluentCarousel] is
/// one widget that owns all of them: `slides` is the slider, `previews` picks
/// the image indicator, and `layout`/`chevronPlacement`/`pauseButton` are the
/// nav container's arrangement. So every section below reads as one constructor
/// call rather than a tree, and the per-section notes say where that costs
/// something.
const DocsPage carouselPage = DocsPage(
  id: 'components-carousel-carousel',
  folder: 'Carousel',
  title: 'Carousel',
  description:
      'A Carousel component is a sliding window of elements controlled by '
      'previous, next, and direct pagination buttons. Carousel allows banners '
      'or a series of cards to be displayed in a way that takes up minimal '
      'screen space. It offers an accessible method of viewing content that is '
      'out of bounds via keyboard interactions. CarouselNavContainer offers '
      'multiple layouts of the underlying controls which can be suitable for '
      'full screen banners, multiple cards within a view, or large image box '
      'previews and displays, or use the underlying controls directly for '
      'precision placement. A CarouselCard can be full screen, responsive, or '
      'partial sizes, it is recommended to enable the cardFocus prop on the '
      'CarouselSlider if the cards are not full width banners (this provided '
      'keyboard navigation and accessibility tool access). If cards are '
      'intended to be full-screen banners, we recommend relying on the tab '
      'index of the internal elements only, while the out-of-view cards will '
      'be set to aria-hidden by default to prevent unnecessary tabbing and '
      'quick control access. For aria-live announcements to work correctly you '
      'should configure you application with a AriaLiveAnnouncer towards the '
      'top of the React tree.',
  source: 'lib/pages/components_carousel_carousel.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-carousel-carousel--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-carousel-carousel--top-navigation',
      title: 'Top Navigation',
      description:
          'Top navigation places carousel controls at the header so users can '
          'see the title, page position, and navigation in one line. This '
          'story shows the default variant with previous and next buttons and '
          'dot pagination using CarouselNav inside CarouselNavContainer.',
      builder: _topNavigation,
    ),
    DocsSection(
      id: 'components-carousel-carousel--appearance',
      title: 'Appearance',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-carousel-carousel--responsive',
      title: 'Responsive',
      description:
          'Carousel can have responsive cards that adjust their size based on '
          'the content, using autoSize prop on CarouselCard.',
      builder: _responsive,
    ),
    DocsSection(
      id: 'components-carousel-carousel--controlled',
      title: 'Controlled',
      description:
          'Carousel can be controlled by setting activeIndex and '
          'onActiveIndexChange props.',
      builder: _controlled,
    ),
    DocsSection(
      id: 'components-carousel-carousel--image-slideshow',
      title: 'Image Slideshow',
      builder: _imageSlideshow,
    ),
    DocsSection(
      id: 'components-carousel-carousel--alignment-and-whitespace',
      title: 'Alignment And Whitespace',
      description:
          'Carousel can have slides aligned relative to the carousel viewport, '
          'use the align prop to set the alignment. Note, the whitespace prop '
          'could be used to clear leading and trailing empty space that causes '
          'excessive scrolling.',
      builder: _alignmentAndWhitespace,
    ),
    DocsSection(
      id: 'components-carousel-carousel--autoplay',
      title: 'Autoplay',
      description:
          'The Autoplay button must be present to enable autoplay as it is an '
          'accessibility requirement. To enable, any valid prop (recommended '
          'ariaLabel) must be passed in, while setting the autoplay prop in '
          'CarouselNav to undefined will disable and remove it. The '
          'autoplayInterval prop controls the delay between slide transitions '
          'in milliseconds (defaults to 4000ms).',
      builder: _autoplay,
    ),
    DocsSection(
      id: 'components-carousel-carousel--first-run-experience',
      title: 'First Run Experience',
      description:
          'Carousel can be used in a Dialog to create a first-run experience.',
      builder: _firstRunExperience,
    ),
    DocsSection(
      id: 'components-carousel-carousel--eventing',
      title: 'Eventing',
      description:
          'Carousel provides callbacks on index change with a multitude of '
          'event types.',
      builder: _eventing,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'slides',
      type: 'List<Widget>',
      description: 'The slides, in order. One page each.',
    ),
    PropRow(
      name: 'previews',
      type: 'List<Widget>?',
      defaultValue: 'null',
      description:
          'Thumbnails for the image-preview indicator, one per slide. Non-null '
          'selects the image indicator.',
    ),
    PropRow(
      name: 'header',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'Optional title/description block above the slides.',
    ),
    PropRow(
      name: 'initialIndex',
      type: 'int',
      defaultValue: '0',
      description: 'The slide shown on mount.',
    ),
    PropRow(
      name: 'onIndexChanged',
      type: 'ValueChanged<int>?',
      defaultValue: 'null',
      description:
          'Invoked whenever the current slide changes — by chevron, by step, '
          'by drag or by autoplay.',
    ),
    PropRow(
      name: 'enabled',
      type: 'bool',
      defaultValue: 'true',
      description:
          'Whether the carousel responds to input. False disables every '
          'control.',
    ),
    PropRow(
      name: 'loop',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the chevrons wrap around at the ends.',
    ),
    PropRow(
      name: 'autoplay',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the slides advance on their own.',
    ),
    PropRow(
      name: 'autoplayInterval',
      type: 'Duration',
      defaultValue: 'fluentCarouselAutoplayInterval',
      description: "How long each slide is shown. Upstream's 4000ms.",
    ),
    PropRow(
      name: 'layout',
      type: 'FluentCarouselLayout',
      defaultValue: 'FluentCarouselLayout.outsideContent',
      description: 'Where the nav strip sits.',
    ),
    PropRow(
      name: 'chevronPlacement',
      type: 'FluentCarouselChevronPlacement',
      defaultValue: 'FluentCarouselChevronPlacement.flexibleToEdges',
      description: 'Where the chevrons sit.',
    ),
    PropRow(
      name: 'pauseButton',
      type: 'FluentCarouselPauseButton',
      defaultValue: 'FluentCarouselPauseButton.onContentClick',
      description: 'Where the autoplay affordance lives.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentCarouselStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description:
          'Announced by assistive technology for the carousel as a whole.',
    ),
    PropRow(
      name: 'stepLabel',
      type: 'String Function(int index, int count)',
      defaultValue: 'defaultFluentCarouselStepLabel',
      description: 'Announced for the step at a given index.',
    ),
  ],
);

// #docregion components-carousel-carousel--default
// `groupSize={1} circular` is `loop: true` — one slide per page is all a
// `PageView` does. Upstream's `CarouselNavContainer` keeps the autoplay button
// in the strip whenever any autoplay prop is passed, even while it is paused;
// ours is drawn only while `autoplay` is on, so the demo starts playing. It
// pauses on hover, on focus, and under reduced motion, exactly as upstream's
// does. There is no `announcement` slot either: Flutter's live region is
// `Semantics(liveRegion: true)` on whatever the reader should hear, so each
// slide carries its own `1 of 6` label instead.
const List<String> _defaultImages = <String>[
  'sea-full-img.jpg',
  'bridge-full-img.jpg',
  'park-full-img.jpg',
  'sea-full-img.jpg',
  'bridge-full-img.jpg',
  'park-full-img.jpg',
];

class _DefaultBannerCard extends StatelessWidget {
  const _DefaultBannerCard({
    required this.imageSrc,
    required this.index,
    required this.title,
  });

  final String imageSrc;
  final int index;
  final String title;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);

    return Semantics(
      label: '${index + 1} of ${_defaultImages.length}',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image(
              image: AssetImage('assets/storybook/$imageSrc'),
              fit: BoxFit.cover,
            ),
            // `left: 10%; top: 25%` of the card. A `Positioned` rather than an
            // aligned child, so a line that wraps past the bottom of the image
            // is clipped by the `Stack` the way the absolutely positioned
            // `<div>` upstream is, instead of reporting an overflow.
            Positioned(
              left: constraints.maxWidth * 0.1,
              top: constraints.maxHeight * 0.25,
              width: 270,
              child: Container(
                color: theme.colors.neutralBackground1,
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: <Widget>[
                    Text(title, style: theme.typography.title1),
                    Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing '
                      'elit, sed do eiusmod tempor incididunt ut labore et '
                      'dolore magna aliqua. Ut enim ad minim veniam.',
                      style: theme.typography.body1,
                    ),
                    // FluentButton puts its label straight in a Row, so a
                    // label wider than the card needs a Flexible.
                    FluentButton(
                      size: FluentButtonSize.small,
                      shape: FluentButtonShape.square,
                      appearance: FluentButtonAppearance.primary,
                      onPressed: () {},
                      child: const Flexible(child: Text('Call to action')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _default(BuildContext context) => SizedBox(
  height: 486,
  child: FluentCarousel(
    loop: true,
    autoplay: true,
    pauseButton: FluentCarouselPauseButton.inNav,
    chevronPlacement: FluentCarouselChevronPlacement.groupedToSteps,
    previousLabel: 'Go to prev',
    nextLabel: 'Go to next',
    playLabel: 'Autoplay',
    pauseLabel: 'Autoplay',
    stepLabel: (int index, int count) => 'Carousel Nav Button $index',
    slides: <Widget>[
      for (int index = 0; index < _defaultImages.length; index++)
        _DefaultBannerCard(
          imageSrc: _defaultImages[index],
          index: index,
          title: 'Card ${index + 1}',
        ),
    ],
  ),
);
// #enddocregion components-carousel-carousel--default

// #docregion components-carousel-carousel--top-navigation
// Upstream puts the whole `CarouselNavContainer` in a header row above the
// viewport. [FluentCarousel] builds its own strip and only ever places it below
// the slides (`outsideContent`) or floating over them (`overContent`) — the
// `header` slot takes content, not controls. So the title moves into `header`
// and the chevrons and dots stay under the slide.
const List<String> _topNavigationImages = <String>[
  'sea-full-img.jpg',
  'bridge-full-img.jpg',
  'park-full-img.jpg',
  'sea-full-img.jpg',
  'bridge-full-img.jpg',
  'park-full-img.jpg',
];

class _TopNavigationBannerCard extends StatelessWidget {
  const _TopNavigationBannerCard({
    required this.imageSrc,
    required this.index,
    required this.title,
  });

  final String imageSrc;
  final int index;
  final String title;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);

    return Semantics(
      label: '${index + 1} of ${_topNavigationImages.length}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: FluentRadius.allXLarge,
          boxShadow: theme.shadow(FluentElevation.shadow16),
        ),
        child: ClipRRect(
          borderRadius: FluentRadius.allXLarge,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) =>
                Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image(
                      image: AssetImage('assets/storybook/$imageSrc'),
                      fit: BoxFit.cover,
                    ),
                    // `left: 10%; top: 25%` of the card. A `Positioned` rather
                    // than an aligned child, so a line that wraps past the
                    // bottom of the image is clipped by the `Stack` the way the
                    // absolutely positioned `<div>` upstream is.
                    Positioned(
                      left: constraints.maxWidth * 0.1,
                      top: constraints.maxHeight * 0.25,
                      width: 270,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colors.neutralBackground1,
                          borderRadius: FluentRadius.allLarge,
                          boxShadow: theme.shadow(FluentElevation.shadow8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: FluentSpacing.xxl,
                          vertical: FluentSpacing.xxxl,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: FluentSpacing.s,
                          children: <Widget>[
                            Text(title, style: theme.typography.title3),
                            Text(
                              'Lorem ipsum dolor sit amet, consectetur '
                              'adipiscing elit, sed do eiusmod tempor '
                              'incididunt ut labore et dolore magna aliqua. Ut '
                              'enim ad minim veniam.',
                              style: theme.typography.body1,
                            ),
                            const SizedBox(height: FluentSpacing.m),
                            // FluentButton puts its label straight in a Row, so
                            // a label wider than the card needs a Flexible.
                            FluentButton(
                              appearance: FluentButtonAppearance.primary,
                              onPressed: () {},
                              child: const Flexible(
                                child: Text('Call to action'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

Widget _topNavigation(BuildContext context) => SizedBox(
  height: 530,
  child: FluentCarousel(
    loop: true,
    header: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'Carousel Title',
        style: FluentTheme.of(context).typography.subtitle1,
      ),
    ),
    previousLabel: 'go to prev',
    nextLabel: 'go to next',
    stepLabel: (int index, int count) => 'Carousel Nav Button $index',
    slides: <Widget>[
      for (int index = 0; index < _topNavigationImages.length; index++)
        _TopNavigationBannerCard(
          imageSrc: _topNavigationImages[index],
          index: index,
          title: 'Card ${index + 1}',
        ),
    ],
  ),
);
// #enddocregion components-carousel-carousel--top-navigation

// #docregion components-carousel-carousel--appearance
// `appearance="elevated"` is a shadow on the carousel's own container. There is
// no Dart axis for it — [FluentCarousel] has no `appearance` — so the shadow is
// applied where upstream applies it, on the box around the carousel.
const List<String> _appearanceImages = <String>[
  'sea-full-img.jpg',
  'bridge-full-img.jpg',
  'park-full-img.jpg',
  'sea-full-img.jpg',
  'bridge-full-img.jpg',
  'park-full-img.jpg',
];

class _AppearanceBannerCard extends StatelessWidget {
  const _AppearanceBannerCard({
    required this.imageSrc,
    required this.index,
    required this.title,
  });

  final String imageSrc;
  final int index;
  final String title;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);

    return Semantics(
      label: '${index + 1} of ${_appearanceImages.length}',
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image(
              image: AssetImage('assets/storybook/$imageSrc'),
              fit: BoxFit.cover,
            ),
            // `left: 10%; top: 25%` of the card. A `Positioned` rather than an
            // aligned child, so a line that wraps past the bottom of the image
            // is clipped by the `Stack` the way the absolutely positioned
            // `<div>` upstream is, instead of reporting an overflow.
            Positioned(
              left: constraints.maxWidth * 0.1,
              top: constraints.maxHeight * 0.25,
              width: 270,
              child: Container(
                color: theme.colors.neutralBackground1,
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: <Widget>[
                    Text(title, style: theme.typography.title1),
                    Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing '
                      'elit, sed do eiusmod tempor incididunt ut labore et '
                      'dolore magna aliqua. Ut enim ad minim veniam.',
                      style: theme.typography.body1,
                    ),
                    // FluentButton puts its label straight in a Row, so a
                    // label wider than the card needs a Flexible.
                    FluentButton(
                      size: FluentButtonSize.small,
                      shape: FluentButtonShape.square,
                      appearance: FluentButtonAppearance.primary,
                      onPressed: () {},
                      child: const Flexible(child: Text('Call to action')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _appearance(BuildContext context) => DecoratedBox(
  decoration: BoxDecoration(
    color: FluentTheme.of(context).colors.neutralBackground1,
    borderRadius: FluentRadius.allMedium,
    boxShadow: FluentTheme.of(context).shadow(FluentElevation.shadow16),
  ),
  child: SizedBox(
    height: 486,
    child: FluentCarousel(
      loop: true,
      autoplay: true,
      pauseButton: FluentCarouselPauseButton.inNav,
      chevronPlacement: FluentCarouselChevronPlacement.groupedToSteps,
      previousLabel: 'Go to prev',
      nextLabel: 'Go to next',
      playLabel: 'Autoplay',
      pauseLabel: 'Autoplay',
      stepLabel: (int index, int count) => 'Carousel Nav Button $index',
      slides: <Widget>[
        for (int index = 0; index < _appearanceImages.length; index++)
          _AppearanceBannerCard(
            imageSrc: _appearanceImages[index],
            index: index,
            title: 'Card ${index + 1}',
          ),
      ],
    ),
  ),
);
// #enddocregion components-carousel-carousel--appearance

// #docregion components-carousel-carousel--responsive
// `autoSize` lets a `CarouselCard` take only the width its content needs, so
// several of them share one view. [FluentCarousel]'s viewport is a `PageView`:
// one slide fills the page, always. The seven cards keep their upstream minimum
// widths and sit centred in their own page instead of packing side by side.
class _ResponsiveWireframe extends StatelessWidget {
  const _ResponsiveWireframe({
    required this.even,
    required this.size,
    required this.children,
  });

  final bool even;
  final String size;
  final List<Widget> children;

  /// `minWidth` upstream, a width here: one card fills the page either way, so
  /// the sized ones keep theirs and `auto` takes what it is given.
  double? get _width => switch (size) {
    'small' => 100,
    'medium' => 200,
    'large' => 350,
    _ => null,
  };

  EdgeInsets get _padding => size == 'small' || size == 'medium'
      ? const EdgeInsets.symmetric(horizontal: 20, vertical: 40)
      : const EdgeInsets.all(40);

  @override
  Widget build(BuildContext context) {
    final FluentColors colors = FluentTheme.of(context).colors;

    return Center(
      child: Container(
        width: _width,
        height: 200,
        decoration: BoxDecoration(
          color: even ? colors.brandBackground2 : colors.neutralBackground3,
          border: Border.all(
            color: even ? colors.brandStroke1 : colors.neutralStroke1,
            width: FluentStroke.thin,
          ),
        ),
        child: Stack(
          children: <Widget>[
            // `place-content: center` on a fixed-height box: the content is
            // centred and whatever does not fit is clipped rather than
            // reported, which is what the CSS does and what a 100-wide card
            // full of Lorem Ipsum needs.
            ClipRect(
              child: OverflowBox(
                maxHeight: double.infinity,
                child: Padding(
                  padding: _padding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: children,
                  ),
                ),
              ),
            ),
            Positioned(right: 12, top: 12, child: _ResponsiveInfo(size: size)),
          ],
        ),
      ),
    );
  }
}

class _ResponsiveInfo extends StatelessWidget {
  const _ResponsiveInfo({required this.size});

  final String size;

  @override
  Widget build(BuildContext context) {
    final FluentColors colors = FluentTheme.of(context).colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.palette.background2Rest(FluentPaletteFamily.red),
        border: Border.all(
          color:
              colors.palette.stroke2Rest(FluentPaletteFamily.red) ??
              colors.neutralStroke1,
          width: FluentStroke.thin,
        ),
      ),
      child: Text(
        'size: $size',
        style: const TextStyle(
          fontFamily: FluentFontFamily.monospace,
          fontFamilyFallback: FluentFontFamily.monospaceFallback,
          fontSize: 12,
        ),
      ),
    );
  }
}

Widget _responsive(BuildContext context) {
  final FluentTypography type = FluentTheme.of(context).typography;

  return SizedBox(
    height: 236,
    child: FluentCarousel(
      previousLabel: 'go to prev',
      nextLabel: 'go to next',
      chevronPlacement: FluentCarouselChevronPlacement.groupedToSteps,
      stepLabel: (int index, int count) => 'Carousel Nav Button $index',
      slides: <Widget>[
        Semantics(
          label: '1 of 7',
          child: _ResponsiveWireframe(
            even: false,
            size: 'auto',
            children: <Widget>[
              Text(
                'Lorem Ipsum',
                textAlign: TextAlign.center,
                style: type.title1,
              ),
              Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed '
                'do eiusmod tempor...',
                textAlign: TextAlign.center,
                style: type.body1,
              ),
            ],
          ),
        ),
        Semantics(
          label: '2 of 7',
          child: _ResponsiveWireframe(
            even: true,
            size: 'small',
            children: <Widget>[
              Text(
                'Lorem Ipsum',
                textAlign: TextAlign.center,
                style: type.subtitle2,
              ),
              Text(
                'Lorem ipsum...',
                textAlign: TextAlign.center,
                style: type.caption1,
              ),
            ],
          ),
        ),
        Semantics(
          label: '3 of 7',
          child: _ResponsiveWireframe(
            even: false,
            size: 'medium',
            children: <Widget>[
              Text(
                'Lorem Ipsum',
                textAlign: TextAlign.center,
                style: type.title1,
              ),
              Text(
                'Lorem ipsum dolor sit amet...',
                textAlign: TextAlign.center,
                style: type.caption1,
              ),
            ],
          ),
        ),
        Semantics(
          label: '4 of 7',
          child: _ResponsiveWireframe(
            even: true,
            size: 'large',
            children: <Widget>[
              Text(
                'Lorem Ipsum',
                textAlign: TextAlign.center,
                style: type.title1,
              ),
              Text(
                'Lorem ipsum dolor sit amet...',
                textAlign: TextAlign.center,
                style: type.body1,
              ),
            ],
          ),
        ),
        Semantics(
          label: '5 of 7',
          child: _ResponsiveWireframe(
            even: false,
            size: 'medium',
            children: <Widget>[
              Text(
                'Lorem Ipsum',
                textAlign: TextAlign.center,
                style: type.title1,
              ),
              Text(
                'Lorem ipsum dolor sit amet...',
                textAlign: TextAlign.center,
                style: type.caption1,
              ),
            ],
          ),
        ),
        Semantics(
          label: '6 of 7',
          child: _ResponsiveWireframe(
            even: true,
            size: 'large',
            children: <Widget>[
              Text(
                'Lorem Ipsum',
                textAlign: TextAlign.center,
                style: type.title1,
              ),
              Text(
                'Lorem ipsum dolor sit amet...',
                textAlign: TextAlign.center,
                style: type.body1,
              ),
            ],
          ),
        ),
        Semantics(
          label: '7 of 7',
          child: _ResponsiveWireframe(
            even: false,
            size: 'small',
            children: <Widget>[
              Text(
                'Lorem Ipsum',
                textAlign: TextAlign.center,
                style: type.subtitle2,
              ),
              Text(
                'Lorem ipsum...',
                textAlign: TextAlign.center,
                style: type.caption1,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
// #enddocregion components-carousel-carousel--responsive

// #docregion components-carousel-carousel--controlled
// [FluentCarousel] is uncontrolled on purpose — autoplay has to own the index —
// so it takes `initialIndex` plus `onIndexChanged` rather than `activeIndex`.
// A page owning the index therefore reads it back from `onIndexChanged` and
// pushes it in by remounting on a key, which is the one thing a `PageController`
// cannot be told after the fact.
//
// Upstream wraps each chevron in a `Tooltip` — 'Go To Previous Page' and
// 'Go To Next Page'. Ours are built inside the carousel, so only their
// accessible names, 'Previous Carousel Page Button' and 'Next Carousel Page
// Button', are reachable from here.
Widget _controlled(BuildContext context) => const _Controlled();

class _Controlled extends StatefulWidget {
  const _Controlled();

  @override
  State<_Controlled> createState() => _ControlledState();
}

class _ControlledState extends State<_Controlled> {
  static const int _slideCount = 5;

  int _activeIndex = 1;
  int _generation = 0;
  bool _autoplaying = false;

  void _setActiveIndex(int index) => setState(() {
    _activeIndex = index;
    _generation++;
  });

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 20,
      children: <Widget>[
        SizedBox(
          height: 236,
          child: FluentCarousel(
            key: ValueKey<int>(_generation),
            initialIndex: _activeIndex,
            onIndexChanged: (int index) => setState(() => _activeIndex = index),
            autoplay: _autoplaying,
            chevronPlacement: FluentCarouselChevronPlacement.centeredToContent,
            previousLabel: 'Previous Carousel Page Button',
            nextLabel: 'Next Carousel Page Button',
            stepLabel: (int index, int count) => 'Carousel Nav Button $index',
            slides: <Widget>[
              Semantics(label: '1 of 5', child: _ControlledWireframe(index: 0)),
              Semantics(label: '2 of 5', child: _ControlledWireframe(index: 1)),
              Semantics(label: '3 of 5', child: _ControlledWireframe(index: 2)),
              Semantics(label: '4 of 5', child: _ControlledWireframe(index: 3)),
              Semantics(label: '5 of 5', child: _ControlledWireframe(index: 4)),
            ],
          ),
        ),
        Align(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colors.neutralBackground1,
              border: Border.all(
                color: theme.colors.neutralStroke1,
                width: FluentStroke.thin,
              ),
              borderRadius: FluentRadius.allMedium,
              boxShadow: theme.shadow(FluentElevation.shadow16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: <Widget>[
                FluentButton.icon(
                  icon: Icon(
                    _autoplaying
                        ? FluentIcons.pause_20_regular
                        : FluentIcons.play_20_regular,
                  ),
                  semanticLabel: 'Enable autoplay',
                  appearance: FluentButtonAppearance.subtle,
                  onPressed: () => setState(() => _autoplaying = !_autoplaying),
                ),
                const SizedBox(
                  height: 24,
                  child: FluentDivider(vertical: true),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colors.neutralBackground4,
                    borderRadius: FluentRadius.allMedium,
                  ),
                  child: Text(
                    '{ "activeIndex": $_activeIndex }',
                    style: const TextStyle(
                      fontFamily: FluentFontFamily.monospace,
                      fontFamilyFallback: FluentFontFamily.monospaceFallback,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 24,
                  child: FluentDivider(vertical: true),
                ),
                FluentToolbar(
                  items: <Widget>[
                    for (int index = 0; index < _slideCount; index++)
                      FluentButton(
                        appearance: FluentButtonAppearance.subtle,
                        semanticLabel: 'Carousel Nav Button $index ',
                        onPressed: index == _activeIndex
                            ? null
                            : () => _setActiveIndex(index),
                        child: Text('$index'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlledWireframe extends StatelessWidget {
  const _ControlledWireframe({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);
    final FluentColors colors = theme.colors;
    final bool even = index.isEven;

    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: even ? colors.brandBackground2 : colors.neutralBackground3,
        border: Border.all(
          color: even ? colors.brandStroke1 : colors.neutralStroke1,
          width: FluentStroke.thin,
        ),
      ),
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: <Widget>[
                Text(
                  'Lorem Ipsum',
                  textAlign: TextAlign.center,
                  style: theme.typography.title1,
                ),
                Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, '
                  'sed do eiusmod tempor...',
                  textAlign: TextAlign.center,
                  style: theme.typography.body1,
                ),
              ],
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.palette.background2Rest(FluentPaletteFamily.red),
                border: Border.all(
                  color:
                      colors.palette.stroke2Rest(FluentPaletteFamily.red) ??
                      colors.neutralStroke1,
                  width: FluentStroke.thin,
                ),
              ),
              child: Text(
                'index: $index',
                style: const TextStyle(
                  fontFamily: FluentFontFamily.monospace,
                  fontFamilyFallback: FluentFontFamily.monospaceFallback,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// #enddocregion components-carousel-carousel--controlled

// #docregion components-carousel-carousel--image-slideshow
// The one section our API models exactly: `previews` is upstream's
// `CarouselNavImageButton` row, and passing it switches the indicator from dots
// to thumbnails. Upstream's `layout="overlay-expanded"` floats the chevrons
// over the image and the thumbnails below it; the nearest arrangement here is
// `centeredToContent`, which flanks the slide with the chevrons and leaves the
// thumbnail strip alone underneath. A single step cannot be disabled on its own
// — upstream marks 'bridge' `disabled: true` — so all three stay live.
class _SlideshowImage {
  const _SlideshowImage({
    required this.previewUrl,
    required this.url,
    required this.label,
    this.disabled = false,
  });

  final String previewUrl;
  final String url;
  final String label;
  final bool disabled;
}

const List<_SlideshowImage> _slideshowImages = <_SlideshowImage>[
  _SlideshowImage(
    previewUrl: 'sea-swatch.jpg',
    url: 'sea-full-img.jpg',
    label: 'sea',
  ),
  _SlideshowImage(
    previewUrl: 'bridge-swatch.jpg',
    url: 'bridge-full-img.jpg',
    label: 'bridge',
    disabled: true,
  ),
  _SlideshowImage(
    previewUrl: 'park-swatch.jpg',
    url: 'park-full-img.jpg',
    label: 'park',
  ),
];

Widget _imageSlideshow(BuildContext context) => SizedBox(
  height: 502,
  child: FluentCarousel(
    chevronPlacement: FluentCarouselChevronPlacement.centeredToContent,
    previousLabel: 'go to prev',
    nextLabel: 'go to next',
    stepLabel: (int index, int count) => 'Carousel Nav Button $index',
    previews: <Widget>[
      for (final _SlideshowImage image in _slideshowImages)
        Image(
          image: AssetImage('assets/storybook/${image.previewUrl}'),
          fit: BoxFit.cover,
        ),
    ],
    slides: <Widget>[
      for (int index = 0; index < _slideshowImages.length; index++)
        Semantics(
          label: '${index + 1} of ${_slideshowImages.length}',
          child: Image(
            image: AssetImage(
              'assets/storybook/${_slideshowImages[index].url}',
            ),
            fit: BoxFit.contain,
          ),
        ),
    ],
  ),
);
// #enddocregion components-carousel-carousel--image-slideshow

// #docregion components-carousel-carousel--alignment-and-whitespace
// `align` and `whitespace` are embla settings on a slider that shows several
// cards at once. [FluentCarousel] pages one slide at a time, so there is nothing
// to align *within the viewport* — the nearest live equivalent is where the card
// sits inside its own page, and whether leading and trailing space is left
// around it. Both controls drive that, so flipping them still shows something.
class _AlignmentPost {
  const _AlignmentPost({
    required this.avatarUrl,
    required this.name,
    required this.text,
    required this.description,
  });

  final String avatarUrl;
  final String name;
  final String text;
  final String description;
}

const List<_AlignmentPost> _alignmentPosts = <_AlignmentPost>[
  _AlignmentPost(
    avatarUrl: 'AllanMunger.jpg',
    name: 'Allan Munger',
    text: 'Meeting notes',
    description: '2 days ago by Kathryn Murphy',
  ),
  _AlignmentPost(
    avatarUrl: 'AmandaBrady.jpg',
    name: 'Amanda Brady',
    text: 'FY24 Hiring Budget',
    description: 'Wed at 3:38pm',
  ),
  _AlignmentPost(
    avatarUrl: 'AshleyMcCarthy.jpg',
    name: 'Ashley McCarthy',
    text: 'Test edited this',
    description: 'Thu at 4:38pm',
  ),
  _AlignmentPost(
    avatarUrl: 'CameronEvans.jpg',
    name: 'Cameron Evans',
    text: 'Review 1:1 Recap',
    description: 'You recently opened this',
  ),
  _AlignmentPost(
    avatarUrl: 'CarlosSlattery.jpg',
    name: 'Carlos Slattery',
    text: 'FY24 Hiring Test',
    description: '2 days ago by Cecil Folk',
  ),
];

const String _alignmentSwapImage = 'image-square.png';

class _AlignmentActionCard extends StatelessWidget {
  const _AlignmentActionCard({required this.post, required this.index});

  final _AlignmentPost post;
  final int index;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);

    return Semantics(
      label: 'Card ${index + 1} of ${_alignmentPosts.length}',
      child: Container(
        width: 350,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: theme.colors.neutralBackground1,
          borderRadius: FluentRadius.allLarge,
          boxShadow: theme.shadow(FluentElevation.shadow16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Stack(
              children: <Widget>[
                SizedBox(
                  height: 200,
                  child: Image(
                    image: const AssetImage(
                      'assets/storybook/$_alignmentSwapImage',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: FluentButton.icon(
                    icon: const Icon(FluentIcons.document_link_20_regular),
                    semanticLabel: 'Go to document',
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: <Widget>[
                  // FluentPersona composes a `Row(mainAxisSize: min)`, which
                  // lays its text column out unbounded — an `Expanded` around
                  // the persona will not make a long secondary line wrap. The
                  // width the card has left for it does.
                  FluentPersona(
                    name: post.name,
                    primary: SizedBox(width: 220, child: Text(post.text)),
                    secondary: SizedBox(
                      width: 220,
                      child: Text(post.description),
                    ),
                    status: FluentPresenceStatus.available,
                    image: AssetImage('assets/storybook/${post.avatarUrl}'),
                  ),
                  const Spacer(),
                  FluentButton.icon(
                    icon: const Icon(FluentIcons.more_horizontal_20_regular),
                    semanticLabel: 'More options',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _alignmentAndWhitespace(BuildContext context) =>
    const _AlignmentAndWhitespace();

class _AlignmentAndWhitespace extends StatefulWidget {
  const _AlignmentAndWhitespace();

  @override
  State<_AlignmentAndWhitespace> createState() =>
      _AlignmentAndWhitespaceState();
}

class _AlignmentAndWhitespaceState extends State<_AlignmentAndWhitespace> {
  String _alignment = 'center';
  bool _whitespace = false;

  Alignment get _cardAlignment => switch (_alignment) {
    'start' => Alignment.centerLeft,
    'end' => Alignment.centerRight,
    _ => Alignment.center,
  };

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);
    final BorderSide side = BorderSide(
      color: theme.colors.neutralForeground3,
      width: FluentStroke.thicker,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.neutralBackground1,
        boxShadow: theme.shadow(FluentElevation.shadow16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Upstream lays each control out with `Field orientation="horizontal"`.
          // FluentField only stacks, so the label sits in a fixed-width cell
          // beside the control instead.
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border(top: side, left: side, right: side),
              borderRadius: const BorderRadius.only(
                topLeft: FluentRadius.medium,
                topRight: FluentRadius.medium,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const SizedBox(width: 100, child: Text('Alignment')),
                    Expanded(
                      child: FluentDropdown<String>(
                        value: _alignment,
                        placeholder: const Text('Select an alignment'),
                        onChanged: (String value) =>
                            setState(() => _alignment = value),
                        options: const <FluentDropdownOption<String>>[
                          FluentDropdownOption<String>(
                            value: 'start',
                            label: Text('start'),
                          ),
                          FluentDropdownOption<String>(
                            value: 'center',
                            label: Text('center'),
                          ),
                          FluentDropdownOption<String>(
                            value: 'end',
                            label: Text('end'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    const SizedBox(width: 100, child: Text('Whitespace')),
                    FluentSwitch(
                      checked: _whitespace,
                      onChanged: (bool checked) =>
                          setState(() => _whitespace = checked),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.fromBorderSide(side),
              borderRadius: const BorderRadius.only(
                bottomLeft: FluentRadius.medium,
                bottomRight: FluentRadius.medium,
              ),
            ),
            child: SizedBox(
              height: 420,
              child: FluentCarousel(
                semanticLabel:
                    'Use the left and right arrow keys to navigate focused carousel card',
                previousLabel: 'go to prev',
                nextLabel: 'go to next',
                chevronPlacement: FluentCarouselChevronPlacement.groupedToSteps,
                stepLabel: (int index, int count) =>
                    'Carousel Nav Button $index',
                slides: <Widget>[
                  for (int index = 0; index < _alignmentPosts.length; index++)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: _whitespace ? 40 : 0,
                        vertical: 20,
                      ),
                      child: Align(
                        alignment: _cardAlignment,
                        child: _AlignmentActionCard(
                          post: _alignmentPosts[index],
                          index: index,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// #enddocregion components-carousel-carousel--alignment-and-whitespace

// #docregion components-carousel-carousel--autoplay
// All three controls map onto real parameters: 'Autoplay Present' picks between
// [FluentCarouselPauseButton.inNav] and the default on-content click,
// 'Autoplay Enabled' is `autoplay`, and the interval is `autoplayInterval`.
// One behaviour is ours rather than upstream's, and deliberately: the button is
// only drawn while `autoplay` is on, and autoplay never runs at all under
// reduced motion.
const List<String> _autoplayImages = <String>[
  'sea-full-img.jpg',
  'bridge-full-img.jpg',
  'park-full-img.jpg',
  'sea-full-img.jpg',
  'bridge-full-img.jpg',
  'park-full-img.jpg',
];

class _AutoplayBannerCard extends StatelessWidget {
  const _AutoplayBannerCard({
    required this.imageSrc,
    required this.index,
    required this.title,
  });

  final String imageSrc;
  final int index;
  final String title;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);

    return Semantics(
      label: '${index + 1} of ${_autoplayImages.length}',
      child: ClipRRect(
        borderRadius: FluentRadius.allLarge,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) => Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image(
                image: AssetImage('assets/storybook/$imageSrc'),
                fit: BoxFit.cover,
              ),
              // `left: 10%; top: 25%` of the card. A `Positioned` rather than an
              // aligned child, so a line that wraps past the bottom of the image
              // is clipped by the `Stack` the way the absolutely positioned
              // `<div>` upstream is, instead of reporting an overflow.
              Positioned(
                left: constraints.maxWidth * 0.1,
                top: constraints.maxHeight * 0.25,
                width: 270,
                child: Container(
                  color: theme.colors.neutralBackground1,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: <Widget>[
                      Text(title, style: theme.typography.title1),
                      Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing '
                        'elit, sed do eiusmod tempor incididunt ut labore et '
                        'dolore magna aliqua. Ut enim ad minim veniam.',
                        style: theme.typography.body1,
                      ),
                      // FluentButton puts its label straight in a Row, so a
                      // label wider than the card needs a Flexible.
                      FluentButton(
                        size: FluentButtonSize.small,
                        shape: FluentButtonShape.square,
                        appearance: FluentButtonAppearance.primary,
                        onPressed: () {},
                        child: const Flexible(child: Text('Call to action')),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _autoplay(BuildContext context) => const _Autoplay();

class _Autoplay extends StatefulWidget {
  const _Autoplay();

  @override
  State<_Autoplay> createState() => _AutoplayState();
}

class _AutoplayState extends State<_Autoplay> {
  bool _autoplayEnabled = false;
  bool _autoplayButton = true;
  double _autoplayInterval = 4000;

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);
    final BorderSide side = BorderSide(
      color: theme.colors.neutralForeground3,
      width: FluentStroke.thicker,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.neutralBackground1,
        boxShadow: theme.shadow(FluentElevation.shadow16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border(top: side, left: side, right: side),
              borderRadius: const BorderRadius.only(
                topLeft: FluentRadius.medium,
                topRight: FluentRadius.medium,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const SizedBox(width: 140, child: Text('Autoplay Present')),
                    FluentSwitch(
                      checked: _autoplayButton,
                      onChanged: (bool checked) =>
                          setState(() => _autoplayButton = checked),
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    const SizedBox(width: 140, child: Text('Autoplay Enabled')),
                    FluentSwitch(
                      checked: _autoplayEnabled,
                      onChanged: (bool checked) =>
                          setState(() => _autoplayEnabled = checked),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(
                      width: 140,
                      child: Text('Autoplay Interval (ms)'),
                    ),
                    Expanded(
                      child: FluentField(
                        hint: Text(
                          'Delay between slides: '
                          '${_autoplayInterval.round()}ms',
                        ),
                        child: FluentSpinButton(
                          value: _autoplayInterval,
                          min: 1000,
                          step: 1000,
                          semanticLabel: 'Autoplay Interval (ms)',
                          onChanged: (double? value) =>
                              setState(() => _autoplayInterval = value ?? 4000),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.fromBorderSide(side),
              borderRadius: const BorderRadius.only(
                bottomLeft: FluentRadius.medium,
                bottomRight: FluentRadius.medium,
              ),
            ),
            child: SizedBox(
              height: 486,
              child: FluentCarousel(
                loop: true,
                autoplay: _autoplayEnabled,
                autoplayInterval: Duration(
                  milliseconds: _autoplayInterval.round(),
                ),
                pauseButton: _autoplayButton
                    ? FluentCarouselPauseButton.inNav
                    : FluentCarouselPauseButton.onContentClick,
                chevronPlacement: FluentCarouselChevronPlacement.groupedToSteps,
                previousLabel: 'go to prev',
                nextLabel: 'go to next',
                playLabel: 'Enable autoplay',
                pauseLabel: 'Enable autoplay',
                stepLabel: (int index, int count) =>
                    'Carousel Nav Button $index',
                slides: <Widget>[
                  for (int index = 0; index < _autoplayImages.length; index++)
                    _AutoplayBannerCard(
                      imageSrc: _autoplayImages[index],
                      index: index,
                      title: 'Card ${index + 1}',
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// #enddocregion components-carousel-carousel--autoplay

// #docregion components-carousel-carousel--first-run-experience
// Upstream keeps the two footer buttons inside the carousel, flanking the nav
// dots. [FluentCarousel] owns its strip, so the buttons move to the dialog's own
// footer — `secondaryActions` at the start, `actions` at the end — and the dots
// stay where the carousel draws them. `motion="fade"` has no counterpart: our
// slide transition is the transcribed embla slide, not a cross-fade.
class _FirstRunPage {
  const _FirstRunPage({
    required this.id,
    required this.alt,
    required this.imgSrc,
    required this.header,
    required this.text,
  });

  final String id;
  final String alt;
  final String imgSrc;
  final String header;
  final String text;
}

const List<_FirstRunPage> _firstRunPages = <_FirstRunPage>[
  _FirstRunPage(
    id: 'Copilot-page-1',
    alt: 'Copilot logo',
    imgSrc: 'sea-full-img.jpg',
    header: 'Discover Copilot, a whole new way to work',
    text:
        'Explore new ways to work smarter and faster using the power of AI. '
        'Copilot in [Word] can help you [get started from scratch], [work from '
        'an existing file], [get actionable insights about documents], and '
        'more.',
  ),
  _FirstRunPage(
    id: 'Copilot-page-2',
    alt: 'Copilot logo 2',
    imgSrc: 'bridge-full-img.jpg',
    header: 'Use your own judgment',
    text:
        'Copilot can make mistakes so remember to verify the results. To help '
        'improve the experience, please share your feedback with us.',
  ),
];

Widget _firstRunExperience(BuildContext context) => const _FirstRunExperience();

class _FirstRunExperience extends StatefulWidget {
  const _FirstRunExperience();

  @override
  State<_FirstRunExperience> createState() => _FirstRunExperienceState();
}

class _FirstRunExperienceState extends State<_FirstRunExperience> {
  int _activeIndex = 0;
  int _generation = 0;
  bool _open = false;

  void _setPage(int page) {
    if (page < 0 || page >= _firstRunPages.length) {
      setState(() => _open = false);
      return;
    }
    setState(() {
      _activeIndex = page;
      _generation++;
    });
  }

  void _setOpen(bool open) => setState(() {
    _open = open;
    if (open) {
      _activeIndex = 0;
      _generation++;
    }
  });

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: FluentDialog(
        open: _open,
        onOpenChange: _setOpen,
        showCloseButton: false,
        semanticLabel: 'Discover Copilot',
        content: SizedBox(
          height: 520,
          child: FluentCarousel(
            key: ValueKey<int>(_generation),
            loop: true,
            initialIndex: _activeIndex,
            onIndexChanged: (int index) => setState(() => _activeIndex = index),
            chevronPlacement: FluentCarouselChevronPlacement.groupedToSteps,
            stepLabel: (int index, int count) => 'Carousel Nav Button $index',
            slides: <Widget>[
              for (final _FirstRunPage page in _firstRunPages)
                Semantics(
                  label: page.alt,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(
                        width: 600,
                        height: 324,
                        child: Image(
                          image: AssetImage('assets/storybook/${page.imgSrc}'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: FluentSpacing.xxl,
                          bottom: FluentSpacing.s,
                        ),
                        child: Text(
                          page.header,
                          style: theme.typography.subtitle1,
                        ),
                      ),
                      Text(page.text, style: theme.typography.body1),
                    ],
                  ),
                ),
            ],
          ),
        ),
        secondaryActions: <Widget>[
          FluentButton(
            onPressed: () => _setPage(_activeIndex - 1),
            child: Text(_activeIndex <= 0 ? 'Not Now' : 'Previous'),
          ),
        ],
        actions: <Widget>[
          FluentButton(
            appearance: FluentButtonAppearance.primary,
            onPressed: () => _setPage(_activeIndex + 1),
            child: Text(
              _activeIndex == _firstRunPages.length - 1
                  ? 'Try Copilot'
                  : 'Next',
            ),
          ),
        ],
        child: FluentButton(
          onPressed: () => _setOpen(true),
          child: const Text('Open Dialog'),
        ),
      ),
    );
  }
}
// #enddocregion components-carousel-carousel--first-run-experience

// #docregion components-carousel-carousel--eventing
// Upstream's `onActiveIndexChange` reports both the new index and *what moved
// it* — click, focus, drag or autoplay. `onIndexChanged` reports the index
// only, so the log below records the index and the time and stops there rather
// than guessing at a cause.
class _EventingWireframe extends StatelessWidget {
  const _EventingWireframe({
    required this.even,
    required this.size,
    required this.children,
  });

  final bool even;
  final String size;
  final List<Widget> children;

  /// `minWidth` upstream, a width here: one card fills the page either way, so
  /// the sized ones keep theirs and `auto` takes what it is given.
  double? get _width => switch (size) {
    'small' => 100,
    'medium' => 200,
    'large' => 350,
    _ => null,
  };

  EdgeInsets get _padding => size == 'small' || size == 'medium'
      ? const EdgeInsets.symmetric(horizontal: 20, vertical: 40)
      : const EdgeInsets.all(40);

  @override
  Widget build(BuildContext context) {
    final FluentColors colors = FluentTheme.of(context).colors;

    return Center(
      child: Container(
        width: _width,
        height: 100,
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: even ? colors.brandBackground2 : colors.neutralBackground3,
          border: Border.all(
            color: even ? colors.brandStroke1 : colors.neutralStroke1,
            width: FluentStroke.thin,
          ),
        ),
        child: Stack(
          children: <Widget>[
            // `place-content: center` on a 100-tall box: centre the content and
            // clip what does not fit, which is what the CSS does.
            ClipRect(
              child: OverflowBox(
                maxHeight: double.infinity,
                child: Padding(
                  padding: _padding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: children,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.palette.background2Rest(
                    FluentPaletteFamily.red,
                  ),
                  border: Border.all(
                    color:
                        colors.palette.stroke2Rest(FluentPaletteFamily.red) ??
                        colors.neutralStroke1,
                    width: FluentStroke.thin,
                  ),
                ),
                child: Text(
                  'size: $size',
                  style: const TextStyle(
                    fontFamily: FluentFontFamily.monospace,
                    fontFamilyFallback: FluentFontFamily.monospaceFallback,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _eventing(BuildContext context) => const _Eventing();

class _Eventing extends StatefulWidget {
  const _Eventing();

  @override
  State<_Eventing> createState() => _EventingState();
}

class _EventingState extends State<_Eventing> {
  final List<({DateTime time, int index})> _statusLog =
      <({DateTime time, int index})>[];

  static String _clock(DateTime time) =>
      '${time.hour}:${time.minute.toString().padLeft(2, '0')}:'
      '${time.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);
    final FluentTypography type = theme.typography;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20,
      children: <Widget>[
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: theme.colors.neutralBackground1,
              border: Border.all(
                color: theme.colors.neutralStroke1,
                width: FluentStroke.thick,
              ),
              borderRadius: FluentRadius.allMedium,
              boxShadow: theme.shadow(FluentElevation.shadow16),
            ),
            child: SizedBox(
              height: 176,
              child: FluentCarousel(
                loop: true,
                autoplay: true,
                pauseButton: FluentCarouselPauseButton.inNav,
                chevronPlacement: FluentCarouselChevronPlacement.groupedToSteps,
                previousLabel: 'go to prev',
                nextLabel: 'go to next',
                playLabel: 'Carousel autoplay',
                pauseLabel: 'Carousel autoplay',
                stepLabel: (int index, int count) =>
                    'Carousel Nav Button $index',
                onIndexChanged: (int index) => setState(
                  () => _statusLog.insert(0, (
                    time: DateTime.now(),
                    index: index,
                  )),
                ),
                slides: <Widget>[
                  Semantics(
                    label: '1 of 7',
                    child: _EventingWireframe(
                      even: false,
                      size: 'auto',
                      children: <Widget>[
                        Text(
                          'Lorem Ipsum',
                          textAlign: TextAlign.center,
                          style: type.title1,
                        ),
                        Text(
                          'Lorem ipsum dolor sit amet, consectetur adipiscing '
                          'elit, sed do eiusmod tempor...',
                          textAlign: TextAlign.center,
                          style: type.body1,
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: '2 of 7',
                    child: _EventingWireframe(
                      even: true,
                      size: 'small',
                      children: <Widget>[
                        Text(
                          'Lorem Ipsum',
                          textAlign: TextAlign.center,
                          style: type.subtitle2,
                        ),
                        Text(
                          'Lorem ipsum...',
                          textAlign: TextAlign.center,
                          style: type.caption1,
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: '3 of 7',
                    child: _EventingWireframe(
                      even: false,
                      size: 'medium',
                      children: <Widget>[
                        Text(
                          'Lorem Ipsum',
                          textAlign: TextAlign.center,
                          style: type.title1,
                        ),
                        Text(
                          'Lorem ipsum dolor sit amet...',
                          textAlign: TextAlign.center,
                          style: type.caption1,
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: '4 of 7',
                    child: _EventingWireframe(
                      even: true,
                      size: 'large',
                      children: <Widget>[
                        Text(
                          'Lorem Ipsum',
                          textAlign: TextAlign.center,
                          style: type.title1,
                        ),
                        Text(
                          'Lorem ipsum dolor sit amet...',
                          textAlign: TextAlign.center,
                          style: type.body1,
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: '5 of 7',
                    child: _EventingWireframe(
                      even: false,
                      size: 'medium',
                      children: <Widget>[
                        Text(
                          'Lorem Ipsum',
                          textAlign: TextAlign.center,
                          style: type.title1,
                        ),
                        Text(
                          'Lorem ipsum dolor sit amet...',
                          textAlign: TextAlign.center,
                          style: type.caption1,
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: '6 of 7',
                    child: _EventingWireframe(
                      even: true,
                      size: 'large',
                      children: <Widget>[
                        Text(
                          'Lorem Ipsum',
                          textAlign: TextAlign.center,
                          style: type.title1,
                        ),
                        Text(
                          'Lorem ipsum dolor sit amet...',
                          textAlign: TextAlign.center,
                          style: type.body1,
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: '7 of 7',
                    child: _EventingWireframe(
                      even: false,
                      size: 'small',
                      children: <Widget>[
                        Text(
                          'Lorem Ipsum',
                          textAlign: TextAlign.center,
                          style: type.subtitle2,
                        ),
                        Text(
                          'Lorem ipsum...',
                          textAlign: TextAlign.center,
                          style: type.caption1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colors.brandBackground,
                  borderRadius: const BorderRadius.only(
                    topLeft: FluentRadius.medium,
                    topRight: FluentRadius.medium,
                  ),
                ),
                child: Text(
                  'Events log',
                  style: type.body1Strong.copyWith(
                    color: theme.colors.neutralForegroundOnBrand,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(
                  minWidth: 240,
                  maxHeight: 250,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colors.neutralBackground1,
                  border: Border.all(
                    color: theme.colors.brandBackground,
                    width: FluentStroke.thick,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: FluentRadius.medium,
                    bottomLeft: FluentRadius.medium,
                    bottomRight: FluentRadius.medium,
                  ),
                  boxShadow: theme.shadow(FluentElevation.shadow16),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (final ({DateTime time, int index}) status
                          in _statusLog)
                        Text.rich(
                          TextSpan(
                            children: <InlineSpan>[
                              TextSpan(text: '${_clock(status.time)} '),
                              TextSpan(
                                text: '{ index: ${status.index} }',
                                style: type.body1Strong,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// #enddocregion components-carousel-carousel--eventing
