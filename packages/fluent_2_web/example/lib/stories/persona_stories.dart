import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentPersona].
final StorySection personaStories = StorySection(
  component: 'Persona',
  description:
      'A person as one row of meaning: a real FluentAvatar — or, on its own, a '
      'real FluentPresenceBadge — beside up to four lines of text. Six size '
      'steps ramp the avatar, the badge and both type ramps together; the text '
      'can sit after, before or below the avatar, and line up with the whole '
      'block or with its first line. It is inert by design, with no hover, '
      'focus or pressed state of its own.',
  stories: [
    Story(
      name: 'Default',
      description:
          'Every axis at once — the size ramp, the two text slots, where the '
          'text sits, how it lines up, and whether presence rides on the '
          'avatar or replaces it.',
      knobs: [
        const TextKnob(label: 'Name', id: 'name', initial: 'Ada Lovelace'),
        const TextKnob(
          label: 'Second line',
          id: 'secondary',
          initial: 'Available',
        ),
        OptionKnob<FluentPersonaSize>(
          label: 'Size',
          id: 'size',
          initial: FluentPersonaSize.medium,
          options: FluentPersonaSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentPersonaTextPosition>(
          label: 'Text position',
          id: 'textPosition',
          initial: FluentPersonaTextPosition.after,
          options: FluentPersonaTextPosition.values,
          labelOf: _name,
        ),
        OptionKnob<FluentPersonaTextAlignment>(
          label: 'Text alignment',
          id: 'textAlignment',
          initial: FluentPersonaTextAlignment.center,
          options: FluentPersonaTextAlignment.values,
          labelOf: _name,
        ),
        OptionKnob<FluentPresenceStatus?>(
          label: 'Presence',
          id: 'status',
          initial: FluentPresenceStatus.available,
          options: _statusOptions,
          labelOf: _statusLabel,
        ),
        const BoolKnob(label: 'Presence only', id: 'presenceOnly'),
        const BoolKnob(label: 'Out of office', id: 'outOfOffice'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        final secondary = knobs.get<String>('secondary', 'Available');
        return FluentPersona(
          name: knobs.get<String>('name', 'Ada Lovelace'),
          secondary: secondary.isEmpty ? null : Text(secondary),
          initials: 'AL',
          size: knobs.get<FluentPersonaSize>('size', FluentPersonaSize.medium),
          textPosition: knobs.get<FluentPersonaTextPosition>(
            'textPosition',
            FluentPersonaTextPosition.after,
          ),
          textAlignment: knobs.get<FluentPersonaTextAlignment>(
            'textAlignment',
            FluentPersonaTextAlignment.center,
          ),
          presenceOnly: knobs.get<bool>('presenceOnly', false),
          status: knobs.get<FluentPresenceStatus?>(
            'status',
            FluentPresenceStatus.available,
          ),
          outOfOffice: knobs.get<bool>('outOfOffice', false),
        );
      },
    ),
    Story(
      name: 'Sizes',
      description:
          'The six steps of the ramp. One axis moves the avatar edge, the '
          'presence badge diameter and both type ramps together — the first '
          'line steps up to subtitle2 from extraLarge, and the second to '
          'body1 with it.',
      knobs: const [BoolKnob(label: 'Presence only', id: 'presenceOnly')],
      builder: (context) => _Sizes(
        presenceOnly: KnobsScope.of(context).get<bool>('presenceOnly', false),
      ),
    ),
    const Story(
      name: 'Text lines',
      description:
          'Four text slots. The first carries its own ramp and colour, the '
          'other three share the second ramp — and the block is pulled two up '
          'into the first line, which is the seam Fluent asks for.',
      builder: _linesBuilder,
    ),
    Story(
      name: 'Text position',
      description:
          'Text after the avatar, before it, or below it with both columns '
          'centred. Only the reading order changes: the lines themselves stay '
          'start-aligned in the before layout.',
      knobs: const [
        OptionKnob<FluentPersonaSize>(
          label: 'Size',
          id: 'size',
          initial: FluentPersonaSize.extraLarge,
          options: FluentPersonaSize.values,
          labelOf: _sizeLabel,
        ),
      ],
      builder: (context) => _TextPosition(
        size: KnobsScope.of(
          context,
        ).get<FluentPersonaSize>('size', FluentPersonaSize.extraLarge),
      ),
    ),
    const Story(
      name: 'Text alignment',
      description:
          'Center hangs the avatar off the middle of the whole text block, '
          'start off its top — except for a presence badge, which centres on '
          'the first line instead so it reads as belonging to the name.',
      builder: _alignmentBuilder,
    ),
    Story(
      name: 'Presence',
      description:
          'Eight availabilities, either as the corner badge on the avatar or '
          'as the whole media slot. The badge is the real FluentPresenceBadge '
          'in both cases, so out-of-office changes the glyph the same way.',
      knobs: const [
        BoolKnob(label: 'Presence only', id: 'presenceOnly'),
        BoolKnob(label: 'Out of office', id: 'outOfOffice'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _Presence(
          presenceOnly: knobs.get<bool>('presenceOnly', false),
          outOfOffice: knobs.get<bool>('outOfOffice', false),
        );
      },
    ),
    const Story(
      name: 'Avatar content',
      description:
          'Initials, a custom glyph, a palette colour, the square shape and '
          'the activity ring are all handed straight through to the composed '
          'avatar — the persona only decides how big it is.',
      builder: _contentBuilder,
    ),
    const Story(
      name: 'Custom styling',
      description:
          'Three rungs of override — the size defaults, a FluentPersonaTheme '
          'across a subtree, then the widget style, which is merged last and '
          'wins.',
      builder: _stylingBuilder,
    ),
  ],
);

String _name(Object? value) => switch (value) {
  Enum(:final String name) => name,
  _ => '$value',
};

/// The step name plus the avatar edge it chooses, which is what the ramp is
/// actually keyed on.
String _sizeLabel(FluentPersonaSize value) =>
    '${value.name} (${value.avatarSize.edge.toInt()})';

String _statusLabel(FluentPresenceStatus? value) => value?.name ?? 'none';

const List<FluentPresenceStatus?> _statusOptions = <FluentPresenceStatus?>[
  null,
  ...FluentPresenceStatus.values,
];

Widget _linesBuilder(BuildContext context) => const _Cases(
  children: [
    ('One line', FluentPersona(name: 'Ada Lovelace', initials: 'AL')),
    (
      'Two',
      FluentPersona(
        name: 'Ada Lovelace',
        initials: 'AL',
        secondary: Text('Software engineer'),
      ),
    ),
    (
      'Three',
      FluentPersona(
        name: 'Ada Lovelace',
        initials: 'AL',
        secondary: Text('Software engineer'),
        tertiary: Text('Analytical Engine'),
      ),
    ),
    (
      'Four',
      FluentPersona(
        name: 'Ada Lovelace',
        initials: 'AL',
        secondary: Text('Software engineer'),
        tertiary: Text('Analytical Engine'),
        quaternary: Text('London'),
      ),
    ),
    (
      'Custom first line',
      FluentPersona(
        initials: 'AL',
        primary: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: FluentSpacing.xs,
          children: [
            Text('Ada Lovelace'),
            Icon(FluentIcons.star_16_filled, size: 16),
          ],
        ),
        secondary: Text('Software engineer'),
      ),
    ),
  ],
);

Widget _alignmentBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Avatar, center',
      FluentPersona(
        name: 'Ada Lovelace',
        initials: 'AL',
        secondary: Text('Software engineer'),
        tertiary: Text('London'),
      ),
    ),
    (
      'Avatar, start',
      FluentPersona(
        name: 'Ada Lovelace',
        initials: 'AL',
        secondary: Text('Software engineer'),
        tertiary: Text('London'),
        textAlignment: FluentPersonaTextAlignment.start,
      ),
    ),
    (
      'Badge, center',
      FluentPersona(
        name: 'Ada Lovelace',
        presenceOnly: true,
        status: FluentPresenceStatus.available,
        secondary: Text('Software engineer'),
        tertiary: Text('London'),
      ),
    ),
    (
      'Badge, start',
      FluentPersona(
        name: 'Ada Lovelace',
        presenceOnly: true,
        status: FluentPresenceStatus.available,
        secondary: Text('Software engineer'),
        tertiary: Text('London'),
        textAlignment: FluentPersonaTextAlignment.start,
      ),
    ),
  ],
);

Widget _contentBuilder(BuildContext context) => _Cases(
  children: [
    (
      'Initials',
      const FluentPersona(
        name: 'Ada Lovelace',
        initials: 'AL',
        secondary: Text('Software engineer'),
        size: FluentPersonaSize.extraLarge,
      ),
    ),
    (
      'Custom glyph',
      const FluentPersona(
        name: 'Contoso',
        icon: Icon(FluentIcons.building_20_regular),
        color: FluentAvatarColor.brand,
        secondary: Text('Organisation'),
        size: FluentPersonaSize.extraLarge,
      ),
    ),
    (
      'Palette colour, square',
      const FluentPersona(
        name: 'Grace Hopper',
        initials: 'GH',
        color: FluentAvatarColor.seafoam,
        shape: FluentAvatarShape.square,
        secondary: Text('Rear admiral'),
        size: FluentPersonaSize.extraLarge,
      ),
    ),
    (
      'Activity ring',
      // The ring paints outside the avatar's box, so the persona needs room
      // for it or it draws over the text.
      const Padding(
        padding: EdgeInsets.all(FluentSpacing.s),
        child: FluentPersona(
          name: 'Alan Turing',
          initials: 'AT',
          color: FluentAvatarColor.lilac,
          active: FluentAvatarActive.active,
          secondary: Text('Mathematician'),
          size: FluentPersonaSize.extraLarge,
        ),
      ),
    ),
    (
      'Fallback glyph',
      const FluentPersona(
        name: 'Unknown person',
        secondary: Text('No account'),
        size: FluentPersonaSize.extraLarge,
      ),
    ),
  ],
);

Widget _stylingBuilder(BuildContext context) {
  final theme = FluentTheme.of(context);
  return FluentPersonaTheme(
    style: FluentPersonaStyle.from(
      gap: FluentSpacing.xxl,
      secondaryColor: theme.colors.brandForeground1,
    ),
    child: _Cases(
      children: [
        (
          'Size defaults',
          FluentPersona(
            name: 'Ada Lovelace',
            initials: 'AL',
            secondary: const Text('Software engineer'),
            // Opting back out of the surrounding theme by restating them.
            style: FluentPersonaStyle.from(
              gap: FluentSpacing.s,
              secondaryColor: theme.colors.neutralForeground2,
            ),
          ),
        ),
        (
          'Subtree theme',
          const FluentPersona(
            name: 'Ada Lovelace',
            initials: 'AL',
            secondary: Text('Software engineer'),
          ),
        ),
        (
          'Widget style wins',
          FluentPersona(
            name: 'Ada Lovelace',
            initials: 'AL',
            secondary: const Text('Software engineer'),
            style: FluentPersonaStyle.from(
              primaryTextStyle: theme.typography.subtitle2,
              primaryColor: theme.colors.brandForeground1,
              secondaryColor: theme.colors.neutralForeground3,
              gap: FluentSpacing.m,
              lineOverlap: 0,
            ),
          ),
        ),
      ],
    ),
  );
}

/// The whole size ramp, captioned with the avatar edge each step chooses.
class _Sizes extends StatelessWidget {
  const _Sizes({required this.presenceOnly});

  final bool presenceOnly;

  @override
  Widget build(BuildContext context) => _Cases(
    children: [
      for (final size in FluentPersonaSize.values)
        (
          _sizeLabel(size),
          FluentPersona(
            name: 'Ada Lovelace',
            initials: 'AL',
            secondary: const Text('Software engineer'),
            size: size,
            presenceOnly: presenceOnly,
            status: presenceOnly ? FluentPresenceStatus.available : null,
          ),
        ),
    ],
  );
}

/// The three layouts, at one size so the gap between them is comparable.
class _TextPosition extends StatelessWidget {
  const _TextPosition({required this.size});

  final FluentPersonaSize size;

  @override
  Widget build(BuildContext context) => _Cases(
    children: [
      for (final position in FluentPersonaTextPosition.values)
        (
          position.name,
          FluentPersona(
            name: 'Ada Lovelace',
            initials: 'AL',
            secondary: const Text('Software engineer'),
            size: size,
            textPosition: position,
          ),
        ),
    ],
  );
}

/// Every availability, on the avatar or in place of it.
class _Presence extends StatelessWidget {
  const _Presence({required this.presenceOnly, required this.outOfOffice});

  final bool presenceOnly;
  final bool outOfOffice;

  @override
  Widget build(BuildContext context) => _Cases(
    children: [
      for (final status in FluentPresenceStatus.values)
        (
          status.name,
          FluentPersona(
            name: 'Ada Lovelace',
            initials: 'AL',
            secondary: Text(status.name),
            size: FluentPersonaSize.extraLarge,
            presenceOnly: presenceOnly,
            status: status,
            outOfOffice: outOfOffice,
          ),
        ),
    ],
  );
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
