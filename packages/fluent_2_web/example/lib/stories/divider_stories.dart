import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentDivider].
final StorySection dividerStories = StorySection(
  component: 'Divider',
  description:
      'A hairline rule that separates content, optionally interrupted by an '
      'icon and a label. Four appearances, three label alignments, a vertical '
      'orientation and an inset mode — and no interaction at all: a divider is '
      'never hovered, focused or animated.',
  stories: [
    Story(
      name: 'Default',
      description:
          'Every axis at once — a centred caption over a neutral hairline, with '
          'the label, appearance, alignment, orientation, icon and inset live.',
      knobs: const [
        TextKnob(label: 'Label', id: 'label', initial: 'Today'),
        OptionKnob<FluentDividerAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentDividerAppearance.standard,
          options: FluentDividerAppearance.values,
          labelOf: _appearanceLabel,
        ),
        OptionKnob<FluentDividerAlignment>(
          label: 'Alignment',
          id: 'alignment',
          initial: FluentDividerAlignment.center,
          options: FluentDividerAlignment.values,
          labelOf: _alignmentLabel,
        ),
        BoolKnob(label: 'Icon', id: 'icon'),
        BoolKnob(label: 'Vertical', id: 'vertical'),
        BoolKnob(label: 'Inset', id: 'inset'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        final label = knobs.get<String>('label', 'Today');
        final vertical = knobs.get<bool>('vertical', false);
        final divider = FluentDivider(
          appearance: knobs.get<FluentDividerAppearance>(
            'appearance',
            FluentDividerAppearance.standard,
          ),
          alignment: knobs.get<FluentDividerAlignment>(
            'alignment',
            FluentDividerAlignment.center,
          ),
          vertical: vertical,
          inset: knobs.get<bool>('inset', false),
          icon: knobs.get<bool>('icon', false)
              ? const Icon(FluentIcons.calendar_20_regular)
              : null,
          child: label.isEmpty ? null : Text(label),
        );
        // A vertical divider hugs its width and stretches along its height, so
        // it needs a parent that bounds the height.
        return vertical
            ? Align(child: SizedBox(height: 120, child: divider))
            : divider;
      },
    ),
    const Story(
      name: 'Appearances',
      description:
          'Four strengths of the same rule, each a token pair that moves the '
          'stroke and the label colour together: subtle is the faintest, strong '
          'the heaviest neutral, brand the accented one.',
      builder: _appearancesBuilder,
    ),
    const Story(
      name: 'Alignment',
      description:
          'Where the label sits along the rule. Start and end pin the near rule '
          'to a fixed stub and let the far one fill; centre grows both equally.',
      builder: _alignmentBuilder,
    ),
    const Story(
      name: 'Vertical',
      description:
          'The same divider rotated: it stretches down the height it is given '
          'and hugs its width, so it separates items in a row.',
      builder: _verticalBuilder,
    ),
    Story(
      name: 'Inset',
      description:
          'Inset pads the whole divider away from its container — horizontally '
          'when the rule is horizontal, vertically when it is not. The tinted '
          'band is the container edge, so the gap is visible.',
      knobs: const [BoolKnob(label: 'Inset', id: 'inset', initial: true)],
      builder: _insetBuilder,
    ),
    const Story(
      name: 'With an icon',
      description:
          'An icon can precede the label, or stand alone between the two rules; '
          'it takes the same content colour as the text.',
      builder: _iconBuilder,
    ),
    const Story(
      name: 'Separating content',
      description:
          'What the component is for: a plain rule between stacked rows, and '
          'vertical rules between grouped actions.',
      builder: _compositionBuilder,
    ),
    const Story(
      name: 'Custom styling',
      description:
          'Three rungs of override — the appearance defaults, a '
          'FluentDividerTheme over a subtree, then the widget style, which is '
          'merged last and wins even over a brand appearance.',
      builder: _stylingBuilder,
    ),
  ],
);

String _appearanceLabel(FluentDividerAppearance value) => value.name;

String _alignmentLabel(FluentDividerAlignment value) => value.name;

Widget _appearancesBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'standard',
      FluentDivider(
        appearance: FluentDividerAppearance.standard,
        child: Text('Standard'),
      ),
    ),
    (
      'subtle',
      FluentDivider(
        appearance: FluentDividerAppearance.subtle,
        child: Text('Subtle'),
      ),
    ),
    (
      'strong',
      FluentDivider(
        appearance: FluentDividerAppearance.strong,
        child: Text('Strong'),
      ),
    ),
    (
      'brand',
      FluentDivider(
        appearance: FluentDividerAppearance.brand,
        child: Text('Brand'),
      ),
    ),
  ],
);

Widget _alignmentBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'start',
      FluentDivider(
        alignment: FluentDividerAlignment.start,
        child: Text('Start'),
      ),
    ),
    ('center', FluentDivider(child: Text('Center'))),
    (
      'end',
      FluentDivider(alignment: FluentDividerAlignment.end, child: Text('End')),
    ),
    ('no label — alignment has nothing to align', FluentDivider()),
  ],
);

Widget _verticalBuilder(BuildContext context) => const SizedBox(
  height: 120,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('Left'),
      FluentDivider(vertical: true),
      Text('Middle'),
      FluentDivider(vertical: true, child: Text('or')),
      Text('Right'),
      FluentDivider(
        vertical: true,
        appearance: FluentDividerAppearance.brand,
        alignment: FluentDividerAlignment.start,
        child: Text('Start'),
      ),
      Text('End'),
    ],
  ),
);

Widget _insetBuilder(BuildContext context) {
  final inset = KnobsScope.of(context).get<bool>('inset', true);
  return _Cases(
    children: [
      ('horizontal', _Container(child: FluentDivider(inset: inset))),
      (
        'horizontal, with a label',
        _Container(
          child: FluentDivider(inset: inset, child: const Text('Or')),
        ),
      ),
      (
        'vertical',
        _Container(
          child: SizedBox(
            height: 96,
            child: Align(child: FluentDivider(vertical: true, inset: inset)),
          ),
        ),
      ),
    ],
  );
}

Widget _iconBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'icon and label',
      FluentDivider(
        icon: Icon(FluentIcons.calendar_20_regular),
        child: Text('Yesterday'),
      ),
    ),
    ('icon only', FluentDivider(icon: Icon(FluentIcons.add_20_regular))),
    (
      'icon on a brand rule',
      FluentDivider(
        appearance: FluentDividerAppearance.brand,
        icon: Icon(FluentIcons.cloud_arrow_up_20_regular),
        child: Text('Uploads'),
      ),
    ),
  ],
);

Widget _compositionBuilder(BuildContext context) {
  final theme = FluentTheme.of(context);
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxl,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: FluentSpacing.s,
          children: [
            Text('Inbox', style: theme.typography.body1Strong),
            const FluentDivider(),
            Text('Drafts', style: theme.typography.body1),
            const FluentDivider(appearance: FluentDividerAppearance.subtle),
            Text('Archive', style: theme.typography.body1),
          ],
        ),
        SizedBox(
          height: FluentSize.size320,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: FluentSpacing.s,
            children: [
              FluentButton(
                appearance: FluentButtonAppearance.subtle,
                icon: const Icon(FluentIcons.save_20_regular),
                onPressed: () {},
                child: const Text('Save'),
              ),
              const FluentDivider(vertical: true, inset: true),
              FluentButton(
                appearance: FluentButtonAppearance.subtle,
                icon: const Icon(FluentIcons.share_20_regular),
                onPressed: () {},
                child: const Text('Share'),
              ),
              const FluentDivider(vertical: true, inset: true),
              FluentButton.icon(
                appearance: FluentButtonAppearance.subtle,
                icon: const Icon(FluentIcons.more_horizontal_20_regular),
                semanticLabel: 'More actions',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _stylingBuilder(BuildContext context) {
  final colors = FluentTheme.of(context).colors;
  return FluentDividerTheme(
    style: FluentDividerStyle.from(
      lineColor: colors.brandStroke1,
      lineThickness: FluentStroke.thick,
    ),
    child: _Cases(
      children: [
        ('appearance defaults, outside the subtree', _outsideTheSubtree),
        (
          'subtree theme — a thicker brand rule',
          const FluentDivider(child: Text('Theme')),
        ),
        (
          'widget style wins',
          FluentDivider(
            appearance: FluentDividerAppearance.brand,
            style: FluentDividerStyle.from(
              lineColor: colors.neutralStroke1,
              lineThickness: FluentStroke.thicker,
              contentColor: colors.neutralForeground3,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: FluentSpacing.xxl,
              ),
            ),
            child: const Text('Style'),
          ),
        ),
      ],
    ),
  );
}

/// Sits outside the [FluentDividerTheme] so the unthemed default is visible
/// beside the overridden ones.
const Widget _outsideTheSubtree = FluentDivider(child: Text('Default'));

/// A tinted band standing in for the divider's container, so an inset gap has
/// an edge to be measured against.
class _Container extends StatelessWidget {
  const _Container({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: FluentTheme.of(context).colors.neutralBackground3,
      borderRadius: FluentRadius.allMedium,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: FluentSpacing.m),
      child: child,
    ),
  );
}

/// Stacked cases under a caption, each stretched to the same width so the rules
/// are directly comparable.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.xl,
        children: [
          for (final (caption, child) in children)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
