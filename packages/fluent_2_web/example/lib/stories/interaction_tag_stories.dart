import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentInteractionTag].
///
/// Where [FluentTag] labels something, this one acts. The stories below are
/// therefore about behaviour as much as about the surface: each half is its own
/// button, so hover, press and focus land on one half without touching the
/// other.
final StorySection interactionTagStories = StorySection(
  component: 'Interaction tag',
  description:
      'A tag that is also a control. The primary half opens or toggles '
      'something, the optional dismiss half removes it, and the two are '
      'independently hoverable, focusable and pressable.',
  stories: [
    Story(
      name: 'Default',
      description:
          'Every axis at once: appearance, size, selection, media, a second '
          'line, the dismiss half and the disabled state.',
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
        final enabled = knobs.get<bool>('enabled', true);
        final dismissible = knobs.get<bool>('dismiss', true);
        return _Start(
          child: FluentInteractionTag(
            appearance: knobs.get<FluentTagAppearance>(
              'appearance',
              FluentTagAppearance.filled,
            ),
            size: knobs.get<FluentTagSize>('size', FluentTagSize.medium),
            selected: knobs.get<bool>('selected', false),
            onPressed: enabled ? _noop : null,
            // Kept when disabled: the half still draws, it just stops reacting.
            onDismiss: dismissible ? _noop : null,
            icon: knobs.get<bool>('icon', false)
                ? const Icon(FluentIcons.calendar_20_regular)
                : null,
            secondaryChild: knobs.get<bool>('secondary', false)
                ? const Text('Secondary')
                : null,
            child: Text(knobs.get<String>('label', 'Design')),
          ),
        );
      },
    ),
    Story(
      name: 'Appearances',
      description:
          'Filled, outline and brand. Each ramps its own hover and pressed '
          'fill — put the pointer on one to see it.',
      knobs: const [BoolKnob(label: 'Dismissible', id: 'dismiss')],
      builder: (context) {
        final dismiss = KnobsScope.of(context).get<bool>('dismiss', false);
        return _Cases(
          children: [
            for (final appearance in FluentTagAppearance.values)
              (
                _appearanceLabel(appearance),
                FluentInteractionTag(
                  appearance: appearance,
                  onPressed: _noop,
                  onDismiss: dismiss ? _noop : null,
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
          'Three heights — 20, 24 and 32 — each with its own type step, glyph '
          'ramp and dismiss hit target.',
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
                FluentInteractionTag(
                  size: size,
                  onPressed: _noop,
                  onDismiss: dismiss ? _noop : null,
                  icon: icon
                      ? const Icon(FluentIcons.calendar_20_regular)
                      : null,
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
    const Story(
      name: 'Selected',
      description:
          'Selection is the point of a pressable tag: press one to toggle it. '
          'Selected erases the appearance — all three become a brand fill.',
      builder: _selectedBuilder,
    ),
    const Story(
      name: 'Dismiss',
      description:
          'The dismiss half is a second button with its own focus ring, '
          'Space/Enter activation and brand hover colour. Remove a few and put '
          'them back.',
      builder: _dismissBuilder,
    ),
    const Story(
      name: 'Primary action',
      description:
          'An interaction tag whose primary half acts, beside a plain tag with '
          'a dismiss glyph — the shape to reach for when only removal is '
          'actionable.',
      builder: _primaryActionBuilder,
    ),
    Story(
      name: 'Disabled',
      description:
          'A null press callback disables both halves at once: no hover, no '
          'focus, and neither callback ever fires.',
      knobs: const [BoolKnob(label: 'Selected', id: 'selected')],
      builder: (context) {
        final selected = KnobsScope.of(context).get<bool>('selected', false);
        return _Cases(
          children: [
            for (final appearance in FluentTagAppearance.values)
              (
                _appearanceLabel(appearance),
                FluentInteractionTag(
                  appearance: appearance,
                  selected: selected,
                  onPressed: null,
                  onDismiss: _noop,
                  icon: const Icon(FluentIcons.calendar_20_regular),
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
          'There is no shape axis; every Figma variant is a 4px radius. A pill '
          'or a square tag is a style override, and each half keeps only its '
          'own outer corners.',
      builder: _shapeBuilder,
    ),
  ],
);

String _appearanceLabel(FluentTagAppearance value) => value.name;

String _sizeLabel(FluentTagSize value) => value.name;

/// A press that deliberately does nothing, for the stories whose subject is the
/// surface rather than the behaviour.
void _noop() {}

Widget _mediaBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Icon',
      FluentInteractionTag(
        icon: Icon(FluentIcons.calendar_20_regular),
        onPressed: _noop,
        child: Text('Tuesday'),
      ),
    ),
    (
      'Avatar',
      FluentInteractionTag(
        icon: FluentAvatar(
          initials: 'AL',
          name: 'Amanda Lee',
          size: FluentAvatarSize.size20,
        ),
        onPressed: _noop,
        child: Text('Amanda Lee'),
      ),
    ),
    (
      'Avatar, dismissible',
      FluentInteractionTag(
        icon: FluentAvatar(
          initials: 'AL',
          name: 'Amanda Lee',
          size: FluentAvatarSize.size20,
        ),
        onPressed: _noop,
        onDismiss: _noop,
        child: Text('Amanda Lee'),
      ),
    ),
  ],
);

Widget _secondaryBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'One line',
      FluentInteractionTag(onPressed: _noop, child: Text('Amanda Lee')),
    ),
    (
      'Two lines',
      FluentInteractionTag(
        onPressed: _noop,
        secondaryChild: Text('Reviewer'),
        child: Text('Amanda Lee'),
      ),
    ),
    (
      'Two lines, dismissible',
      FluentInteractionTag(
        icon: Icon(FluentIcons.person_20_regular),
        onPressed: _noop,
        onDismiss: _noop,
        secondaryChild: Text('Reviewer'),
        child: Text('Amanda Lee'),
      ),
    ),
  ],
);

Widget _selectedBuilder(BuildContext context) => const _FilterTags();

Widget _dismissBuilder(BuildContext context) => const _DismissibleTags();

Widget _primaryActionBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Both halves act',
      FluentInteractionTag(
        onPressed: _noop,
        onDismiss: _noop,
        child: Text('Design'),
      ),
    ),
    (
      'Only dismiss acts (FluentTag)',
      FluentTag(onDismiss: _noop, child: Text('Design')),
    ),
  ],
);

Widget _shapeBuilder(BuildContext context) => _Cases(
  children: [
    (
      'Default (4px)',
      FluentInteractionTag(
        onPressed: _noop,
        onDismiss: _noop,
        child: const Text('Design'),
      ),
    ),
    (
      'Pill',
      FluentInteractionTag(
        style: FluentTagStyle.from(
          borderRadius: FluentRadius.allCircular,
          padding: const EdgeInsets.symmetric(horizontal: FluentSpacing.m),
        ),
        onPressed: _noop,
        onDismiss: _noop,
        child: const Text('Design'),
      ),
    ),
    (
      'Square',
      FluentInteractionTag(
        style: FluentTagStyle.from(
          borderRadius: const BorderRadius.all(FluentRadius.none),
        ),
        onPressed: _noop,
        onDismiss: _noop,
        child: const Text('Design'),
      ),
    ),
  ],
);

/// A row of filters the reader can actually toggle, so `selected` is driven by
/// the press rather than by a knob.
class _FilterTags extends StatefulWidget {
  const _FilterTags();

  @override
  State<_FilterTags> createState() => _FilterTagsState();
}

class _FilterTagsState extends State<_FilterTags> {
  static const List<String> _all = [
    'Design',
    'Research',
    'Engineering',
    'Accessibility',
  ];

  Set<String> _selected = const {'Design'};

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.l,
      children: [
        Wrap(
          spacing: FluentSpacing.s,
          runSpacing: FluentSpacing.s,
          children: [
            for (final tag in _all)
              FluentInteractionTag(
                selected: _selected.contains(tag),
                onPressed: () => setState(() {
                  _selected = _selected.contains(tag)
                      ? (_selected.toSet()..remove(tag))
                      : (_selected.toSet()..add(tag));
                }),
                child: Text(tag),
              ),
          ],
        ),
        Text(
          _selected.isEmpty
              ? 'No filters applied.'
              : 'Filtering by ${_selected.join(', ')}.',
          style: theme.typography.caption1.copyWith(
            color: theme.colors.neutralForeground3,
          ),
        ),
      ],
    );
  }
}

/// A real list of tags the reader can empty and refill, so dismissing removes
/// something instead of firing an invisible callback.
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
                FluentInteractionTag(
                  dismissSemanticLabel: 'Remove $tag',
                  onPressed: _noop,
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
