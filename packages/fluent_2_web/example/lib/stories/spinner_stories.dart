import 'dart:async';

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentSpinner].
final StorySection spinnerStories = StorySection(
  component: 'Spinner',
  description:
      'An indeterminate progress indicator: a ring whose tail grows and travels '
      'once every 1.5 seconds. Eight sizes, two appearances and four label '
      'positions — and no interaction at all, because a spinner is output '
      'rather than a control. Under reduced motion it holds a static quarter '
      'arc instead of stopping dead.',
  stories: [
    Story(
      name: 'Default',
      description:
          'A medium ring with a label after it. Every design axis is live: '
          'size, appearance, the label text and where the label sits.',
      knobs: const [
        OptionKnob<FluentSpinnerSize>(
          label: 'Size',
          id: 'size',
          initial: FluentSpinnerSize.medium,
          options: FluentSpinnerSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentSpinnerAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentSpinnerAppearance.primary,
          options: FluentSpinnerAppearance.values,
          labelOf: _appearanceLabel,
        ),
        TextKnob(label: 'Label', id: 'label', initial: 'Loading'),
        OptionKnob<FluentSpinnerLabelPosition>(
          label: 'Label position',
          id: 'labelPosition',
          initial: FluentSpinnerLabelPosition.after,
          options: FluentSpinnerLabelPosition.values,
          labelOf: _labelPositionLabel,
        ),
      ],
      builder: _defaultBuilder,
    ),
    Story(
      name: 'Sizes',
      description:
          'Eight diameters from 16 to 44. The ring thickness steps with them, '
          'and so does the label type ramp — turn the label on to see body1 '
          'become subtitle2 and then subtitle1.',
      knobs: const [BoolKnob(label: 'Label', id: 'label')],
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Appearances',
      description:
          'Primary is a brand tail for a neutral surface; subtle is a white '
          'tail for a brand or image surface, and is shown on one because that '
          'is the only place it is legible.',
      builder: _appearancesBuilder,
    ),
    const Story(
      name: 'With a label',
      description:
          'A label turns the ring into a sentence. A bare ring says nothing to '
          'a screen reader, so it takes a semanticLabel instead — both are '
          'announced as a live region.',
      builder: _labelBuilder,
    ),
    const Story(
      name: 'Label position',
      description:
          'Four layouts around the same ring. After and before lay out in '
          'reading order, so they flip under RTL; above and below never do.',
      builder: _labelPositionBuilder,
    ),
    const Story(
      name: 'Reduced motion',
      description:
          'With animations disabled the controller never starts and the ring '
          'holds a static quarter arc — a legible indicator rather than a blank '
          'box. The right-hand spinner has it forced on.',
      builder: _reducedMotionBuilder,
    ),
    const Story(
      name: 'While loading',
      description:
          'What the component is for: press the button and the spinner stands '
          'in for content that has not arrived yet.',
      builder: _loadingBuilder,
    ),
    const Story(
      name: 'Custom styling',
      description:
          'Three rungs of override — the size defaults, a FluentSpinnerTheme '
          'over a subtree, then the widget style, which is merged last and '
          'wins. A partial override keeps every other resolved value.',
      builder: _stylingBuilder,
    ),
  ],
);

String _sizeLabel(FluentSpinnerSize value) => value.name;

String _appearanceLabel(FluentSpinnerAppearance value) => value.name;

String _labelPositionLabel(FluentSpinnerLabelPosition value) => value.name;

Widget _defaultBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  final label = knobs.get<String>('label', 'Loading');
  final appearance = knobs.get<FluentSpinnerAppearance>(
    'appearance',
    FluentSpinnerAppearance.primary,
  );
  final spinner = FluentSpinner(
    appearance: appearance,
    size: knobs.get<FluentSpinnerSize>('size', FluentSpinnerSize.medium),
    labelPosition: knobs.get<FluentSpinnerLabelPosition>(
      'labelPosition',
      FluentSpinnerLabelPosition.after,
    ),
    label: label.isEmpty ? null : Text(label),
    semanticLabel: label.isEmpty ? 'Loading' : null,
  );

  return Align(
    alignment: AlignmentDirectional.centerStart,
    // Subtle is coloured for a brand surface, so it gets one — on the page's
    // own background its white rail and label would be invisible.
    child: appearance == FluentSpinnerAppearance.subtle
        ? _BrandSurface(child: spinner)
        : spinner,
  );
}

Widget _sizesBuilder(BuildContext context) {
  final withLabel = KnobsScope.of(context).get<bool>('label', false);
  return _Cases(
    children: [
      for (final size in FluentSpinnerSize.values)
        (
          size.name,
          FluentSpinner(
            size: size,
            label: withLabel ? const Text('Loading') : null,
            semanticLabel: withLabel ? null : 'Loading',
          ),
        ),
    ],
  );
}

Widget _appearancesBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'primary — on a neutral surface',
      FluentSpinner(
        appearance: FluentSpinnerAppearance.primary,
        label: Text('Loading'),
      ),
    ),
    (
      'subtle — on a brand surface',
      _BrandSurface(
        child: FluentSpinner(
          appearance: FluentSpinnerAppearance.subtle,
          label: Text('Loading'),
        ),
      ),
    ),
  ],
);

Widget _labelBuilder(BuildContext context) => const _Cases(
  children: [
    ('bare ring — semanticLabel only', FluentSpinner(semanticLabel: 'Loading')),
    ('with a label', FluentSpinner(label: Text('Loading'))),
    (
      'a label can be more than one word',
      FluentSpinner(
        size: FluentSpinnerSize.large,
        label: Text('Fetching your files'),
      ),
    ),
  ],
);

Widget _labelPositionBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'after',
      FluentSpinner(
        labelPosition: FluentSpinnerLabelPosition.after,
        label: Text('After'),
      ),
    ),
    (
      'before',
      FluentSpinner(
        labelPosition: FluentSpinnerLabelPosition.before,
        label: Text('Before'),
      ),
    ),
    (
      'above',
      FluentSpinner(
        labelPosition: FluentSpinnerLabelPosition.above,
        label: Text('Above'),
      ),
    ),
    (
      'below',
      FluentSpinner(
        labelPosition: FluentSpinnerLabelPosition.below,
        label: Text('Below'),
      ),
    ),
  ],
);

Widget _reducedMotionBuilder(BuildContext context) => _Cases(
  children: [
    (
      'animating',
      const FluentSpinner(size: FluentSpinnerSize.large, label: Text('Moving')),
    ),
    (
      'animations disabled',
      MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: const FluentSpinner(
          size: FluentSpinnerSize.large,
          label: Text('Resting'),
        ),
      ),
    ),
  ],
);

Widget _loadingBuilder(BuildContext context) => const _LoadOnDemand();

Widget _stylingBuilder(BuildContext context) {
  final colors = FluentTheme.of(context).colors;
  return FluentSpinnerTheme(
    style: FluentSpinnerStyle.from(
      indicatorColor: colors.neutralForeground1,
      trackColor: colors.neutralStroke2,
    ),
    child: _Cases(
      children: [
        ('size defaults, outside the subtree', _outsideTheSubtree),
        ('subtree theme — a neutral ring', const FluentSpinner()),
        (
          'widget style wins',
          FluentSpinner(
            style: FluentSpinnerStyle.from(
              indicatorColor: colors.brandStroke1,
              strokeWidth: FluentStroke.thickest,
            ),
          ),
        ),
        (
          'a partial override keeps the rest',
          const FluentSpinner(
            label: Text('Wider gap'),
            style: FluentSpinnerStyle(
              gap: WidgetStatePropertyAll<double?>(FluentSpacing.xxl),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Sits outside the [FluentSpinnerTheme] so the unthemed default is visible
/// beside the overridden ones.
const Widget _outsideTheSubtree = FluentSpinner();

/// A panel that fetches on demand, so the spinner has a real beginning and end
/// rather than running forever.
class _LoadOnDemand extends StatefulWidget {
  const _LoadOnDemand();

  @override
  State<_LoadOnDemand> createState() => _LoadOnDemandState();
}

class _LoadOnDemandState extends State<_LoadOnDemand> {
  Timer? _timer;
  bool _busy = false;
  bool _loaded = false;

  void _start() {
    setState(() {
      _busy = true;
      _loaded = false;
    });
    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _busy = false;
          _loaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.l,
      children: [
        FluentButton(
          appearance: FluentButtonAppearance.primary,
          icon: const Icon(FluentIcons.arrow_download_20_regular),
          onPressed: _busy ? null : _start,
          child: const Text('Load report'),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colors.neutralBackground3,
            borderRadius: FluentRadius.allMedium,
          ),
          child: SizedBox(
            width: 320,
            height: 96,
            child: Center(
              child: switch ((_busy, _loaded)) {
                (true, _) => const FluentSpinner(
                  size: FluentSpinnerSize.small,
                  label: Text('Fetching the report'),
                ),
                (_, true) => Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: FluentSpacing.s,
                  children: [
                    const Icon(FluentIcons.checkmark_circle_20_filled),
                    Text('Report ready', style: theme.typography.body1Strong),
                  ],
                ),
                _ => Text(
                  'Nothing loaded yet',
                  style: theme.typography.body1.copyWith(
                    color: theme.colors.neutralForeground3,
                  ),
                ),
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// A brand-filled panel, the surface the subtle appearance is coloured for.
class _BrandSurface extends StatelessWidget {
  const _BrandSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: FluentTheme.of(context).colors.brandBackground,
      borderRadius: FluentRadius.allMedium,
    ),
    child: Padding(
      padding: const EdgeInsets.all(FluentSpacing.l),
      child: child,
    ),
  );
}

/// Cases laid out in a wrapping row under their captions, so rings of different
/// sizes sit on one baseline and are directly comparable.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Wrap(
      spacing: FluentSpacing.xxxl,
      runSpacing: FluentSpacing.xxl,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final (caption, child) in children)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: FluentSpacing.s,
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
