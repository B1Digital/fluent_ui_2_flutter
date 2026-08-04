import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentCarousel].
///
/// The slide area is a viewport like any other, so every example below hands
/// the carousel a bounded height. That is the component's contract rather than
/// a quirk of the gallery — a carousel in an unbounded column has no height to
/// page through.
final StorySection carouselStories = StorySection(
  component: 'Carousel',
  description:
      'A paged set of slides with a step indicator, previous/next chevrons and '
      'optional autoplay. Every control is a real FluentButton, so focus, '
      'hover, keyboard activation and the disabled state come from the button '
      'rather than from a second interaction surface.',
  stories: [
    Story(
      name: 'Default',
      description:
          'Five slides with the dot indicator below them. All four design axes '
          'are live: where the nav strip sits, where the chevrons sit, whether '
          'the ends wrap and whether the slides advance on their own.',
      knobs: const [
        OptionKnob<FluentCarouselLayout>(
          label: 'Layout',
          id: 'layout',
          initial: FluentCarouselLayout.outsideContent,
          options: FluentCarouselLayout.values,
          labelOf: _layoutLabel,
        ),
        OptionKnob<FluentCarouselChevronPlacement>(
          label: 'Chevron placement',
          id: 'placement',
          initial: FluentCarouselChevronPlacement.flexibleToEdges,
          options: FluentCarouselChevronPlacement.values,
          labelOf: _placementLabel,
        ),
        BoolKnob(label: 'Loop', id: 'loop'),
        BoolKnob(label: 'Autoplay', id: 'autoplay'),
        BoolKnob(label: 'Enabled', id: 'enabled', initial: true),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return SizedBox(
          height: 280,
          child: FluentCarousel(
            slides: _slides(5),
            layout: knobs.get<FluentCarouselLayout>(
              'layout',
              FluentCarouselLayout.outsideContent,
            ),
            chevronPlacement: knobs.get<FluentCarouselChevronPlacement>(
              'placement',
              FluentCarouselChevronPlacement.flexibleToEdges,
            ),
            loop: knobs.get<bool>('loop', false),
            autoplay: knobs.get<bool>('autoplay', false),
            enabled: knobs.get<bool>('enabled', true),
            semanticLabel: 'Product highlights',
          ),
        );
      },
    ),
    Story(
      name: 'Chevron placement',
      description:
          'The three placements side by side: pushed to the carousel edges, '
          'hugging the indicator as one centred group, or flanking the slide '
          'itself. Switch the layout knob to float the whole strip over the '
          'slide instead of below it.',
      knobs: const [
        OptionKnob<FluentCarouselLayout>(
          label: 'Layout',
          id: 'layout',
          initial: FluentCarouselLayout.outsideContent,
          options: FluentCarouselLayout.values,
          labelOf: _layoutLabel,
        ),
      ],
      builder: (context) {
        final layout = KnobsScope.of(context).get<FluentCarouselLayout>(
          'layout',
          FluentCarouselLayout.outsideContent,
        );
        return _Cases(
          children: [
            for (final placement in FluentCarouselChevronPlacement.values)
              (
                _placementLabel(placement),
                FluentCarousel(
                  slides: _slides(3),
                  layout: layout,
                  chevronPlacement: placement,
                  semanticLabel: _placementLabel(placement),
                ),
              ),
          ],
        );
      },
    ),
    Story(
      name: 'Autoplay',
      description:
          'The slides advance on their own, and stop while the pointer is over '
          'the carousel, while focus is anywhere inside it, and entirely under '
          'reduced motion — flip the toolbar switch to see that. The affordance '
          'is either a button in the nav or a click anywhere on the slide.',
      knobs: const [
        OptionKnob<FluentCarouselPauseButton>(
          label: 'Pause affordance',
          id: 'pause',
          initial: FluentCarouselPauseButton.inNav,
          options: FluentCarouselPauseButton.values,
          labelOf: _pauseLabel,
        ),
        NumberKnob(
          label: 'Interval (seconds)',
          id: 'interval',
          initial: 4,
          min: 1,
          max: 10,
        ),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return SizedBox(
          height: 280,
          child: FluentCarousel(
            slides: _slides(4),
            autoplay: true,
            loop: true,
            pauseButton: knobs.get<FluentCarouselPauseButton>(
              'pause',
              FluentCarouselPauseButton.inNav,
            ),
            autoplayInterval: Duration(
              milliseconds: (knobs.get<double>('interval', 4) * 1000).round(),
            ),
            semanticLabel: 'Featured stories',
          ),
        );
      },
    ),
    const Story(
      name: 'Looping',
      description:
          'Without looping the previous chevron is disabled on the first slide '
          'and the next chevron on the last — a real disabled state, not a '
          'greyed-out one. Looping wraps both, and lets autoplay keep going '
          'past the end.',
      builder: _loopingBuilder,
    ),
    const Story(
      name: 'Image preview nav',
      description:
          'Passing one preview per slide swaps the dot indicator for a row of '
          'thumbnails; the current one is drawn larger. The previews are '
          'ordinary widgets, so they can be images, initials or anything else.',
      builder: _previewNavBuilder,
    ),
    const Story(
      name: 'Header',
      description:
          'An optional block above the slides for a title and a description. '
          'It is a plain widget, so the arrangement is a composition rather '
          'than a fixed grid.',
      builder: _headerBuilder,
    ),
    Story(
      name: 'Disabled',
      description:
          'Disabled is a state, not a paint job: every chevron and step refuses '
          'focus and never fires, and the slide will not drag either.',
      knobs: const [BoolKnob(label: 'Enabled', id: 'enabled')],
      builder: (context) => SizedBox(
        height: 260,
        child: FluentCarousel(
          slides: _slides(4),
          enabled: KnobsScope.of(context).get<bool>('enabled', false),
          semanticLabel: 'Archived campaign',
        ),
      ),
    ),
    const Story(
      name: 'Index changes',
      description:
          'onIndexChanged reports every move — by chevron, by step, by arrow '
          'key, by drag or by autoplay — with the index that is now in view. '
          'The carousel starts on the slide given by initialIndex.',
      builder: _eventingBuilder,
    ),
    const Story(
      name: 'Action cards',
      description:
          'A slide is any widget, so a page can hold a row of cards with their '
          'own buttons. Focus stays inside the slide, and moving focus into it '
          'pauses autoplay.',
      builder: _actionCardsBuilder,
    ),
    const Story(
      name: 'Responsive slides',
      description:
          'How many cards fit on a page is the caller\'s decision: a '
          'LayoutBuilder groups the same list into wider or narrower pages, and '
          'the indicator follows because the slide count changed.',
      builder: _responsiveBuilder,
    ),
    const Story(
      name: 'First run experience',
      description:
          'The onboarding pattern: a header, one idea per slide, and a primary '
          'action on the last one. Nothing here is a carousel feature — it is '
          'the header slot plus ordinary content.',
      builder: _freBuilder,
    ),
    const Story(
      name: 'Custom styling',
      description:
          'A FluentCarouselTheme restyles every carousel beneath it, and a '
          'widget\'s own style still wins over the subtree — the same three-rung '
          'order every Fluent component resolves through.',
      builder: _stylingBuilder,
    ),
  ],
);

String _layoutLabel(FluentCarouselLayout value) =>
    value == FluentCarouselLayout.overContent
    ? 'over content'
    : 'outside content';

String _placementLabel(FluentCarouselChevronPlacement value) => switch (value) {
  FluentCarouselChevronPlacement.flexibleToEdges => 'flexible to edges',
  FluentCarouselChevronPlacement.groupedToSteps => 'grouped to steps',
  FluentCarouselChevronPlacement.centeredToContent => 'centered to content',
};

String _pauseLabel(FluentCarouselPauseButton value) =>
    value == FluentCarouselPauseButton.inNav
    ? 'button in nav'
    : 'click the slide';

/// One slide per entry, each a token-filled block with its title on it.
List<Widget> _slides(int count) => <Widget>[
  for (var i = 0; i < count; i++) _Slide(index: i, label: 'Slide ${i + 1}'),
];

Widget _loopingBuilder(BuildContext context) => _Cases(
  children: [
    (
      'loop: false',
      FluentCarousel(
        slides: _slides(3),
        chevronPlacement: FluentCarouselChevronPlacement.groupedToSteps,
        semanticLabel: 'Stops at the ends',
      ),
    ),
    (
      'loop: true',
      FluentCarousel(
        slides: _slides(3),
        loop: true,
        chevronPlacement: FluentCarouselChevronPlacement.groupedToSteps,
        semanticLabel: 'Wraps at the ends',
      ),
    ),
  ],
);

Widget _previewNavBuilder(BuildContext context) => SizedBox(
  height: 300,
  child: FluentCarousel(
    slides: _slides(4),
    previews: <Widget>[for (var i = 0; i < 4; i++) _Slide(index: i)],
    chevronPlacement: FluentCarouselChevronPlacement.groupedToSteps,
    semanticLabel: 'Room photos',
  ),
);

Widget _headerBuilder(BuildContext context) {
  final theme = FluentTheme.of(context);
  return SizedBox(
    height: 300,
    child: FluentCarousel(
      slides: _slides(3),
      semanticLabel: 'What is new',
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FluentSpacing.xxs,
        children: [
          Text('What is new this month', style: theme.typography.subtitle2),
          Text(
            'Three changes worth a look before you upgrade.',
            style: theme.typography.caption1.copyWith(
              color: theme.colors.neutralForeground3,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _eventingBuilder(BuildContext context) => const _IndexLog();

Widget _actionCardsBuilder(BuildContext context) => SizedBox(
  height: 300,
  child: FluentCarousel(
    semanticLabel: 'Recommended actions',
    slides: <Widget>[
      for (var i = 0; i < _features.length; i += 2)
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: FluentSpacing.m,
          children: <Widget>[
            for (final feature in _features.skip(i).take(2))
              Expanded(child: _FeatureCard(feature: feature)),
          ],
        ),
    ],
  ),
);

Widget _responsiveBuilder(BuildContext context) => SizedBox(
  height: 300,
  child: LayoutBuilder(
    builder: (context, constraints) {
      // One card per 240 logical pixels of slide, at least one.
      final perSlide = (constraints.maxWidth / 240).floor().clamp(1, 4);
      return FluentCarousel(
        semanticLabel: 'Recommended actions',
        slides: <Widget>[
          for (var i = 0; i < _features.length; i += perSlide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FluentSpacing.m,
              children: <Widget>[
                for (final feature in _features.skip(i).take(perSlide))
                  Expanded(child: _FeatureCard(feature: feature)),
              ],
            ),
        ],
      );
    },
  ),
);

Widget _freBuilder(BuildContext context) {
  final theme = FluentTheme.of(context);
  return SizedBox(
    height: 380,
    child: FluentCarousel(
      semanticLabel: 'Welcome tour',
      chevronPlacement: FluentCarouselChevronPlacement.groupedToSteps,
      header: Text('Welcome to Contoso', style: theme.typography.title3),
      slides: <Widget>[
        for (final (index, step) in _tour.indexed)
          _TourSlide(index: index, step: step, last: index == _tour.length - 1),
      ],
    ),
  );
}

Widget _stylingBuilder(BuildContext context) {
  final colors = FluentTheme.of(context).colors;
  return FluentCarouselTheme(
    style: FluentCarouselStyle.from(
      stepColor: colors.brandForeground1,
      navGap: FluentSpacing.xxl,
    ),
    child: _Cases(
      children: [
        (
          'the subtree theme',
          FluentCarousel(
            slides: _slides(3),
            chevronPlacement: FluentCarouselChevronPlacement.groupedToSteps,
            semanticLabel: 'Themed carousel',
          ),
        ),
        (
          'and a style that beats it',
          FluentCarousel(
            slides: _slides(3),
            chevronPlacement: FluentCarouselChevronPlacement.groupedToSteps,
            semanticLabel: 'Restyled carousel',
            style: FluentCarouselStyle.from(
              stepColor: colors.neutralForeground3,
              activeStepSize: const Size(FluentSize.size240, FluentSize.size80),
            ),
          ),
        ),
      ],
    ),
  );
}

/// The slide titles used by the first-run story.
const List<(String, String)> _tour = <(String, String)>[
  (
    'Everything in one place',
    'Files, chats and meetings share a single timeline, so nothing needs '
        'hunting for twice.',
  ),
  (
    'Bring your team along',
    'Invite anyone with a link. Guests see only the channels you share with '
        'them.',
  ),
  (
    'Make it yours',
    'Pick a theme, set your working hours and decide what is allowed to '
        'notify you.',
  ),
];

/// Card content for the action-card and responsive stories.
const List<(String, String)> _features = <(String, String)>[
  ('Connect a calendar', 'See your meetings beside your tasks.'),
  ('Invite your team', 'Three seats are included on this plan.'),
  ('Import from Drive', 'Bring existing documents across in one pass.'),
  ('Set a working week', 'Notifications pause outside your hours.'),
  ('Turn on backups', 'A nightly copy, kept for thirty days.'),
  ('Add a custom domain', 'Send from an address your customers know.'),
];

/// A carousel that reports every index change, so the callback can be watched.
class _IndexLog extends StatefulWidget {
  const _IndexLog();

  @override
  State<_IndexLog> createState() => _IndexLogState();
}

class _IndexLogState extends State<_IndexLog> {
  static const _count = 5;
  int _index = 2;
  int _changes = 0;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: [
        SizedBox(
          height: 260,
          child: FluentCarousel(
            slides: _slides(_count),
            initialIndex: 2,
            loop: true,
            semanticLabel: 'Release notes',
            onIndexChanged: (index) => setState(() {
              _index = index;
              _changes++;
            }),
          ),
        ),
        Text(
          'Slide ${_index + 1} of $_count · $_changes change'
          '${_changes == 1 ? '' : 's'} reported',
          style: theme.typography.body1.copyWith(
            color: theme.colors.neutralForeground2,
          ),
        ),
      ],
    );
  }
}

/// A stand-in for slide artwork: a block filled from the accent palette with
/// its title centred on it.
///
/// The palette family is picked per slide so consecutive slides are told apart
/// while paging — the one place a story reaches past the alias tokens, and it
/// still reads real tokens rather than a literal colour.
class _Slide extends StatelessWidget {
  const _Slide({required this.index, this.label});

  final int index;

  final String? label;

  static const _families = <FluentPaletteFamily>[
    FluentPaletteFamily.blue,
    FluentPaletteFamily.forest,
    FluentPaletteFamily.marigold,
    FluentPaletteFamily.grape,
    FluentPaletteFamily.teal,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final family = _families[index % _families.length];
    final text = label;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.palette.background2Rest(family),
        borderRadius: FluentRadius.allMedium,
      ),
      child: text == null
          ? const SizedBox.expand()
          : Center(
              child: Text(
                text,
                style: theme.typography.subtitle2.copyWith(
                  color: theme.colors.palette.foreground2Rest(family),
                ),
              ),
            ),
    );
  }
}

/// One card on an action-card slide.
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final (String, String) feature;

  @override
  Widget build(BuildContext context) {
    final (title, body) = feature;
    return FluentCard(
      appearance: FluentCardAppearance.outline,
      header: Text(
        title,
        style: FluentTheme.of(context).typography.body1Strong,
      ),
      footer: FluentButton(
        appearance: FluentButtonAppearance.primary,
        size: FluentButtonSize.small,
        onPressed: () {},
        child: const Text('Set up'),
      ),
      child: Text(body),
    );
  }
}

/// One step of the first-run tour.
class _TourSlide extends StatelessWidget {
  const _TourSlide({
    required this.index,
    required this.step,
    required this.last,
  });

  final int index;

  final (String, String) step;

  /// The last step carries the primary action.
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final (title, body) = step;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: [
        Expanded(child: _Slide(index: index)),
        Text(title, style: theme.typography.subtitle2),
        Text(
          body,
          style: theme.typography.body1.copyWith(
            color: theme.colors.neutralForeground2,
          ),
        ),
        FluentButton(
          appearance: last
              ? FluentButtonAppearance.primary
              : FluentButtonAppearance.secondary,
          onPressed: () {},
          child: Text(last ? 'Get started' : 'Skip the tour'),
        ),
      ],
    );
  }
}

/// Side-by-side carousels under a caption, each in a box of its own — a
/// carousel needs both a bounded width and a bounded height.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Wrap(
      spacing: FluentSpacing.xl,
      runSpacing: FluentSpacing.l,
      children: [
        for (final (caption, child) in children)
          SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FluentSpacing.xs,
              children: [
                Text(
                  caption,
                  style: theme.typography.caption1.copyWith(
                    color: theme.colors.neutralForeground3,
                  ),
                ),
                SizedBox(height: 240, child: child),
              ],
            ),
          ),
      ],
    );
  }
}
