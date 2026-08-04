import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentTeachingPopover].
final StorySection teachingPopoverStories = StorySection(
  component: 'Teaching popover',
  description:
      'A coach mark: a popover that introduces a feature rather than merely '
      'describing it. On top of the popover surface it adds a caption, an '
      'optional image, a headline, a paragraph and a footer of one or two '
      'actions — plus, for a guided tour, a strip of carousel dots between '
      'them. Anchoring, Escape, outside-tap dismissal and the entrance are '
      "FluentPopover's, unchanged.",
  stories: [
    const Story(
      name: 'Default',
      description:
          'Every axis at once. Press the trigger to open it; Escape, a tap '
          'outside, the dismiss glyph and the primary action all close it '
          'again, and focus returns to the trigger.',
      knobs: [
        OptionKnob<FluentTeachingPopoverAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentTeachingPopoverAppearance.normal,
          options: FluentTeachingPopoverAppearance.values,
          labelOf: _appearanceLabel,
        ),
        OptionKnob<FluentPopoverPosition>(
          label: 'Position',
          id: 'position',
          initial: FluentPopoverPosition.below,
          options: FluentPopoverPosition.values,
          labelOf: _positionLabel,
        ),
        BoolKnob(label: 'With arrow', id: 'arrow'),
        BoolKnob(label: 'Dismiss button', id: 'dismiss', initial: true),
        BoolKnob(label: 'Secondary action', id: 'secondary', initial: true),
        BoolKnob(label: 'Caption and media', id: 'media'),
      ],
      builder: _defaultBuilder,
    ),
    const Story(
      name: 'Appearances',
      description:
          'Normal sits on the ambient surface; brand fills it, flips every '
          'text slot to the on-brand token and restyles both footer buttons '
          'so the primary reads as white-on-brand.',
      builder: _appearancesBuilder,
    ),
    const Story(
      name: 'Caption and media',
      description:
          'The two optional slots above the headline: a small caption for a '
          '"New" badge, and an image drawn exactly as handed over — the '
          'component sizes the column, never the artwork.',
      builder: _mediaBuilder,
    ),
    const Story(
      name: 'Carousel',
      description:
          'A multi-step tour. The dots are real buttons that jump between '
          'pages, and with no Back button on the first page the strip takes '
          'the leading edge instead of the centre.',
      knobs: [
        OptionKnob<FluentTeachingPopoverAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentTeachingPopoverAppearance.normal,
          options: FluentTeachingPopoverAppearance.values,
          labelOf: _appearanceLabel,
        ),
        BoolKnob(label: 'Page count', id: 'pageCount', initial: true),
      ],
      builder: _carouselBuilder,
    ),
    const Story(
      name: 'Availability',
      description:
          'A null onOpenChanged is a real state, not a greyed-out one: '
          'nothing reaches the overlay at all, and a surface already showing '
          'is torn down the moment it is switched off.',
      builder: _availabilityBuilder,
    ),
    const Story(
      name: 'Custom style',
      description:
          'Two components, so two style rungs: FluentTeachingPopoverStyle '
          'restyles the content and FluentPopoverStyle the surface under it. '
          'Both merge per property over the appearance defaults.',
      builder: _styledBuilder,
    ),
  ],
);

const String _title = 'Pin your favourites';

const String _body =
    'Anything you pin shows up at the top of this list, on every device you '
    'sign in from.';

String _appearanceLabel(FluentTeachingPopoverAppearance value) => value.name;

String _positionLabel(FluentPopoverPosition value) => value.name;

Widget _defaultBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  final withMedia = knobs.get<bool>('media', false);
  return _Demo(
    appearance: knobs.get<FluentTeachingPopoverAppearance>(
      'appearance',
      FluentTeachingPopoverAppearance.normal,
    ),
    position: knobs.get<FluentPopoverPosition>(
      'position',
      FluentPopoverPosition.below,
    ),
    withArrow: knobs.get<bool>('arrow', false),
    withDismiss: knobs.get<bool>('dismiss', true),
    withSecondary: knobs.get<bool>('secondary', true),
    withHeader: withMedia,
    withMedia: withMedia,
  );
}

Widget _appearancesBuilder(BuildContext context) => _Cases(
  children: [
    for (final appearance in FluentTeachingPopoverAppearance.values)
      (
        appearance.name,
        _Demo(
          appearance: appearance,
          withSecondary: true,
          triggerLabel: 'Show ${appearance.name}',
        ),
      ),
  ],
);

Widget _mediaBuilder(BuildContext context) => _Cases(
  children: const [
    ('Caption only', _Demo(withHeader: true)),
    ('Caption and media', _Demo(withHeader: true, withMedia: true)),
    ('Media only', _Demo(withMedia: true)),
  ],
);

Widget _carouselBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  return _CarouselDemo(
    appearance: knobs.get<FluentTeachingPopoverAppearance>(
      'appearance',
      FluentTeachingPopoverAppearance.normal,
    ),
    withPageCount: knobs.get<bool>('pageCount', true),
  );
}

Widget _availabilityBuilder(BuildContext context) => const _Availability();

Widget _styledBuilder(BuildContext context) {
  final colors = FluentTheme.of(context).colors;
  final typography = FluentTheme.of(context).typography;
  return _Cases(
    children: [
      ('Defaults', const _Demo(withHeader: true, withSecondary: true)),
      (
        'Subtree theme',
        FluentTeachingPopoverTheme(
          style: FluentTeachingPopoverStyle.from(
            titleColor: colors.brandForeground1,
            headerColor: colors.brandForeground2,
            titleTextStyle: typography.subtitle1,
          ),
          child: const _Demo(withHeader: true, withSecondary: true),
        ),
      ),
      (
        'Widget style',
        _Demo(
          withHeader: true,
          withSecondary: true,
          style: FluentTeachingPopoverStyle.from(
            contentWidth: 240,
            mainGap: FluentSpacing.xs,
          ),
          popoverStyle: FluentPopoverStyle.from(
            borderRadius: FluentRadius.allLarge,
            padding: const EdgeInsets.all(FluentSpacing.xl),
          ),
        ),
      ),
    ],
  );
}

/// One teaching popover behind a trigger, with the axes a story wants to vary.
///
/// Stateful because [FluentTeachingPopover.open] is controlled: the trigger,
/// the dismiss glyph, the primary action, Escape and an outside tap all write
/// to the same flag, which is the only arrangement that cannot disagree with
/// itself.
class _Demo extends StatefulWidget {
  const _Demo({
    this.appearance = FluentTeachingPopoverAppearance.normal,
    this.position = FluentPopoverPosition.below,
    this.withArrow = false,
    this.withDismiss = true,
    this.withSecondary = false,
    this.withHeader = false,
    this.withMedia = false,
    this.enabled = true,
    this.triggerLabel = 'Show me around',
    this.style,
    this.popoverStyle,
  });

  final FluentTeachingPopoverAppearance appearance;
  final FluentPopoverPosition position;
  final bool withArrow;
  final bool withDismiss;
  final bool withSecondary;
  final bool withHeader;
  final bool withMedia;
  final bool enabled;
  final String triggerLabel;
  final FluentTeachingPopoverStyle? style;
  final FluentPopoverStyle? popoverStyle;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final brand = widget.appearance == FluentTeachingPopoverAppearance.brand;
    return FluentTeachingPopover(
      open: _open,
      onOpenChanged: widget.enabled
          ? (open) => setState(() => _open = open)
          : null,
      appearance: widget.appearance,
      position: widget.position,
      withArrow: widget.withArrow,
      header: widget.withHeader ? const Text('New') : null,
      media: widget.withMedia ? _Media(brand: brand) : null,
      title: const Text(_title),
      body: const Text(_body),
      // The dismiss glyph closes the popover on its own; this hook is the
      // caller's place to record *how* it was closed, and its presence is what
      // decides the glyph is drawn at all.
      onDismiss: widget.withDismiss ? () {} : null,
      dismissSemanticLabel: 'Close the tip',
      primaryAction: FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: () => setState(() => _open = false),
        child: const Text('Got it'),
      ),
      secondaryAction: widget.withSecondary
          ? FluentButton(
              onPressed: () => setState(() => _open = false),
              child: const Text('Not now'),
            )
          : null,
      style: widget.style,
      popoverStyle: widget.popoverStyle,
      semanticLabel: _title,
      child: FluentButton(
        onPressed: () => setState(() => _open = !_open),
        child: Text(widget.triggerLabel),
      ),
    );
  }
}

/// A four-page tour driven by the carousel dots and the footer buttons.
class _CarouselDemo extends StatefulWidget {
  const _CarouselDemo({required this.appearance, required this.withPageCount});

  final FluentTeachingPopoverAppearance appearance;
  final bool withPageCount;

  @override
  State<_CarouselDemo> createState() => _CarouselDemoState();
}

class _CarouselDemoState extends State<_CarouselDemo> {
  static const List<(String, String)> _pages = [
    ('Pin your favourites', 'Anything you pin stays at the top of the list.'),
    ('Share in one step', 'Send a link straight from the toolbar.'),
    ('Work offline', 'Recent files stay available with no connection.'),
    ('Pick up anywhere', 'Everything syncs to every device you sign in from.'),
  ];

  bool _open = false;
  int _step = 0;

  void _close() => setState(() {
    _open = false;
    _step = 0;
  });

  @override
  Widget build(BuildContext context) {
    final brand = widget.appearance == FluentTeachingPopoverAppearance.brand;
    final last = _step == _pages.length - 1;
    final (title, body) = _pages[_step];

    return FluentTeachingPopover(
      open: _open,
      onOpenChanged: (open) => setState(() {
        _open = open;
        if (!open) _step = 0;
      }),
      appearance: widget.appearance,
      header: Text('Step ${_step + 1}'),
      media: _Media(brand: brand),
      title: Text(title),
      body: Text(body),
      onDismiss: () {},
      dismissSemanticLabel: 'Skip the tour',
      carousel: FluentTeachingPopoverCarousel(
        steps: _pages.length,
        activeStep: _step,
        onStepSelected: (step) => setState(() => _step = step),
        pageCount: widget.withPageCount
            ? Text(' ${_step + 1} of ${_pages.length}')
            : null,
      ),
      // No Back on the first page, which is what pushes the dots to the
      // leading edge rather than the centre.
      secondaryAction: _step == 0
          ? null
          : FluentButton(
              onPressed: () => setState(() => _step--),
              child: const Text('Back'),
            ),
      primaryAction: FluentButton(
        appearance: FluentButtonAppearance.primary,
        onPressed: last ? _close : () => setState(() => _step++),
        child: Text(last ? 'Done' : 'Next'),
      ),
      semanticLabel: title,
      child: FluentButton(
        onPressed: () => setState(() => _open = !_open),
        child: const Text('Take the tour'),
      ),
    );
  }
}

/// A teaching popover whose availability is switched live.
class _Availability extends StatefulWidget {
  const _Availability();

  @override
  State<_Availability> createState() => _AvailabilityState();
}

class _AvailabilityState extends State<_Availability> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.l,
    children: [
      _Demo(enabled: _enabled, withSecondary: true),
      FluentSwitch(
        checked: _enabled,
        onChanged: (value) => setState(() => _enabled = value),
        label: const Text('Popover enabled'),
      ),
    ],
  );
}

/// Stand-in artwork for the media slot.
///
/// Drawn from tokens rather than shipped as an asset so it recolours with the
/// theme and reads on the brand fill as well as the neutral one. A real caller
/// puts an illustration here.
class _Media extends StatelessWidget {
  const _Media({required this.brand});

  /// Whether it sits on a brand-filled surface.
  final bool brand;

  @override
  Widget build(BuildContext context) {
    final colors = FluentTheme.of(context).colors;
    return SizedBox(
      height: 90,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: brand ? colors.brandBackground2 : colors.neutralBackground4,
          borderRadius: FluentRadius.allMedium,
        ),
        child: Center(
          child: Icon(
            FluentIcons.lightbulb_20_regular,
            size: FluentSize.size320,
            color: brand ? colors.brandForeground2 : colors.neutralForeground3,
          ),
        ),
      ),
    );
  }
}

/// Side-by-side cases under a caption.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Wrap(
      spacing: FluentSpacing.xxl,
      runSpacing: FluentSpacing.xxl,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        for (final (caption, child) in children)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: FluentSpacing.xs,
            children: [
              Text(
                caption,
                style: theme.typography.caption1.copyWith(
                  color: theme.colors.neutralForeground3,
                ),
              ),
              child,
            ],
          ),
      ],
    );
  }
}
