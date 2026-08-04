import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentTag].
///
/// A tag is inert on purpose: it labels something, it does not act. The one
/// interactive part is the optional dismiss glyph, so every story here is about
/// the surface — appearance, size, media, selection — rather than about press
/// behaviour. `FluentInteractionTag` is the tag that is also a control and has
/// its own page.
final StorySection tagStories = StorySection(
  component: 'Tag',
  description:
      'A compact label for a keyword, a person or a filter. The tag itself has '
      'no hover or pressed treatment — Fluent paints the same fill in all '
      'three states — and only the dismiss glyph reacts to the pointer.',
  stories: [
    Story(
      name: 'Default',
      description:
          'Every axis at once: appearance, size, selection, media, a second '
          'line and the dismiss affordance.',
      knobs: const [
        TextKnob(label: 'Label', id: 'label', initial: 'Design'),
        OptionKnob<FluentTagAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentTagAppearance.filled,
          options: FluentTagAppearance.values,
          labelOf: _appearanceLabel,
        ),
        OptionKnob<FluentTagSize>(
          label: 'Size',
          id: 'size',
          initial: FluentTagSize.medium,
          options: FluentTagSize.values,
          labelOf: _sizeLabel,
        ),
        BoolKnob(label: 'Selected', id: 'selected'),
        BoolKnob(label: 'Enabled', id: 'enabled', initial: true),
        BoolKnob(label: 'Icon', id: 'icon'),
        BoolKnob(label: 'Secondary text', id: 'secondary'),
        BoolKnob(label: 'Dismissible', id: 'dismiss', initial: true),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _Start(
          child: FluentTag(
            appearance: knobs.get<FluentTagAppearance>(
              'appearance',
              FluentTagAppearance.filled,
            ),
            size: knobs.get<FluentTagSize>('size', FluentTagSize.medium),
            selected: knobs.get<bool>('selected', false),
            enabled: knobs.get<bool>('enabled', true),
            icon: knobs.get<bool>('icon', false)
                ? const Icon(FluentIcons.calendar_20_regular)
                : null,
            secondaryChild: knobs.get<bool>('secondary', false)
                ? const Text('Secondary')
                : null,
            onDismiss: knobs.get<bool>('dismiss', true) ? () {} : null,
            child: Text(knobs.get<String>('label', 'Design')),
          ),
        );
      },
    ),
    Story(
      name: 'Appearances',
      description:
          'Filled, outline and brand. Outline paints no fill at all, so it is '
          'the one appearance that reads on a coloured surface.',
      knobs: const [BoolKnob(label: 'Dismissible', id: 'dismiss')],
      builder: (context) {
        final dismiss = KnobsScope.of(context).get<bool>('dismiss', false);
        return _Cases(
          children: [
            for (final appearance in FluentTagAppearance.values)
              (
                _appearanceLabel(appearance),
                FluentTag(
                  appearance: appearance,
                  onDismiss: dismiss ? () {} : null,
                  child: const Text('Design'),
                ),
              ),
          ],
        );
      },
    ),
    Story(
      name: 'Sizes',
      description:
          'Three heights — 20, 24 and 32 — each with its own type step and '
          'glyph ramp: 12, 16, 20.',
      knobs: const [
        BoolKnob(label: 'Icon', id: 'icon', initial: true),
        BoolKnob(label: 'Dismissible', id: 'dismiss', initial: true),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        final icon = knobs.get<bool>('icon', true);
        final dismiss = knobs.get<bool>('dismiss', true);
        return _Cases(
          children: [
            for (final size in FluentTagSize.values)
              (
                _sizeLabel(size),
                FluentTag(
                  size: size,
                  icon: icon
                      ? const Icon(FluentIcons.calendar_20_regular)
                      : null,
                  onDismiss: dismiss ? () {} : null,
                  child: const Text('Design'),
                ),
              ),
          ],
        );
      },
    ),
    const Story(
      name: 'Media',
      description:
          'The leading slot takes any widget and inherits the tag\'s glyph size '
          'and label colour — an icon, or an avatar for a person tag.',
      builder: _mediaBuilder,
    ),
    const Story(
      name: 'Secondary text',
      description:
          'A second line, drawn only at the medium size. Adding it drops the '
          'primary line from body to caption so the pair still fits 32px.',
      builder: _secondaryBuilder,
    ),
    Story(
      name: 'Selected',
      description:
          'Selected erases the appearance: all three render as the same '
          'brand-filled tag.',
      knobs: const [
        OptionKnob<FluentTagSize>(
          label: 'Size',
          id: 'size',
          initial: FluentTagSize.medium,
          options: FluentTagSize.values,
          labelOf: _sizeLabel,
        ),
      ],
      builder: (context) {
        final size = KnobsScope.of(
          context,
        ).get<FluentTagSize>('size', FluentTagSize.medium);
        return _Cases(
          children: [
            for (final appearance in FluentTagAppearance.values)
              (
                _appearanceLabel(appearance),
                _SelectedPair(appearance: appearance, size: size),
              ),
          ],
        );
      },
    ),
    const Story(
      name: 'Dismiss',
      description:
          'Supplying a dismiss callback adds a glyph with its own focus ring, '
          'Space/Enter activation and brand hover colour. Remove a few and put '
          'them back.',
      builder: _dismissBuilder,
    ),
    Story(
      name: 'Disabled',
      description:
          'A disabled tag greys its fill and label and its dismiss glyph stops '
          'responding. Outline keeps its border and still paints no fill.',
      knobs: const [BoolKnob(label: 'Selected', id: 'selected')],
      builder: (context) {
        final selected = KnobsScope.of(context).get<bool>('selected', false);
        return _Cases(
          children: [
            for (final appearance in FluentTagAppearance.values)
              (
                _appearanceLabel(appearance),
                FluentTag(
                  appearance: appearance,
                  selected: selected,
                  enabled: false,
                  icon: const Icon(FluentIcons.calendar_20_regular),
                  onDismiss: () {},
                  child: const Text('Design'),
                ),
              ),
          ],
        );
      },
    ),
    const Story(
      name: 'Custom shape',
      description:
          'Tag has no shape axis; every Figma variant is a 4px radius. A pill '
          'or a square tag is a style override, and merging is per-property so '
          'the resolved colours survive.',
      builder: _shapeBuilder,
    ),
  ],
);

String _appearanceLabel(FluentTagAppearance value) => value.name;

String _sizeLabel(FluentTagSize value) => value.name;

Widget _mediaBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Icon',
      FluentTag(
        icon: Icon(FluentIcons.calendar_20_regular),
        child: Text('Tuesday'),
      ),
    ),
    (
      'Avatar',
      FluentTag(
        icon: FluentAvatar(
          initials: 'AL',
          name: 'Amanda Lee',
          size: FluentAvatarSize.size20,
        ),
        child: Text('Amanda Lee'),
      ),
    ),
    (
      'Avatar with secondary text',
      FluentTag(
        icon: FluentAvatar(
          initials: 'AL',
          name: 'Amanda Lee',
          size: FluentAvatarSize.size20,
        ),
        secondaryChild: Text('Reviewer'),
        child: Text('Amanda Lee'),
      ),
    ),
  ],
);

Widget _secondaryBuilder(BuildContext context) => const _Cases(
  children: [
    ('One line', FluentTag(child: Text('Amanda Lee'))),
    (
      'Two lines',
      FluentTag(secondaryChild: Text('Reviewer'), child: Text('Amanda Lee')),
    ),
    (
      'Two lines, dismissible',
      FluentTag(
        icon: Icon(FluentIcons.person_20_regular),
        secondaryChild: Text('Reviewer'),
        onDismiss: _noop,
        child: Text('Amanda Lee'),
      ),
    ),
  ],
);

Widget _shapeBuilder(BuildContext context) => _Cases(
  children: [
    ('Default (4px)', const FluentTag(child: Text('Design'))),
    (
      'Pill',
      FluentTag(
        style: FluentTagStyle.from(
          borderRadius: FluentRadius.allCircular,
          padding: const EdgeInsets.symmetric(horizontal: FluentSpacing.m),
        ),
        child: const Text('Design'),
      ),
    ),
    (
      'Square',
      FluentTag(
        style: FluentTagStyle.from(
          borderRadius: const BorderRadius.all(FluentRadius.none),
        ),
        child: const Text('Design'),
      ),
    ),
  ],
);

Widget _dismissBuilder(BuildContext context) => const _DismissibleTags();

/// A tag that cannot be dismissed still wants a callback in a const story, and
/// this is cheaper than making three of them stateful.
void _noop() {}

/// One appearance at rest and selected, so the collapse onto the brand fill is
/// visible in a single glance rather than across a knob change.
class _SelectedPair extends StatelessWidget {
  const _SelectedPair({required this.appearance, required this.size});

  final FluentTagAppearance appearance;
  final FluentTagSize size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: FluentSpacing.m,
    children: [
      FluentTag(
        appearance: appearance,
        size: size,
        child: const Text('Design'),
      ),
      FluentTag(
        appearance: appearance,
        size: size,
        selected: true,
        child: const Text('Design'),
      ),
    ],
  );
}

/// A real list of tags the reader can empty and refill, so dismissing actually
/// removes something instead of firing an invisible callback.
class _DismissibleTags extends StatefulWidget {
  const _DismissibleTags();

  @override
  State<_DismissibleTags> createState() => _DismissibleTagsState();
}

class _DismissibleTagsState extends State<_DismissibleTags> {
  static const List<String> _all = [
    'Design',
    'Research',
    'Engineering',
    'Accessibility',
  ];

  List<String> _tags = _all;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.l,
      children: [
        if (_tags.isEmpty)
          Text(
            'No tags left.',
            style: theme.typography.body1.copyWith(
              color: theme.colors.neutralForeground3,
            ),
          )
        else
          Wrap(
            spacing: FluentSpacing.s,
            runSpacing: FluentSpacing.s,
            children: [
              for (final tag in _tags)
                FluentTag(
                  dismissSemanticLabel: 'Remove $tag',
                  onDismiss: () => setState(() {
                    _tags = _tags.where((other) => other != tag).toList();
                  }),
                  child: Text(tag),
                ),
            ],
          ),
        FluentButton(
          onPressed: _tags.length == _all.length
              ? null
              : () => setState(() => _tags = _all),
          child: const Text('Reset'),
        ),
      ],
    );
  }
}

/// Keeps a single example at its intrinsic width instead of letting the canvas
/// stretch it across the page.
class _Start extends StatelessWidget {
  const _Start({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Align(alignment: AlignmentDirectional.centerStart, child: child);
}

/// Side-by-side cases under a caption, the layout most of these stories want.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Wrap(
      spacing: FluentSpacing.xxl,
      runSpacing: FluentSpacing.l,
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
