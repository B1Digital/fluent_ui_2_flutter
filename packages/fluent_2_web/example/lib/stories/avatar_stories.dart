import 'dart:convert';

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentAvatar] and [FluentAvatarGroup].
final StorySection avatarStories = StorySection(
  component: 'Avatar',
  description:
      'A person or entity as a photo, their initials, or a fallback glyph: '
      'thirteen sizes, two shapes, thirty-three colour modes, an activity ring '
      'that animates in and out, and a presence badge anchored to the corner. '
      'Several avatars become one unit with FluentAvatarGroup, which spreads, '
      'stacks or cuts them into a pie.',
  stories: [
    Story(
      name: 'Default',
      description:
          'Every design axis at once — a 72 neutral circle out of the box, '
          'with the initials, colour, size, shape, activity ring and presence '
          'badge all live.',
      knobs: [
        const TextKnob(label: 'Initials', id: 'initials', initial: 'AL'),
        OptionKnob<FluentAvatarColor>(
          label: 'Colour',
          id: 'color',
          initial: FluentAvatarColor.neutral,
          options: FluentAvatarColor.values,
          labelOf: _name,
        ),
        OptionKnob<FluentAvatarSize>(
          label: 'Size',
          id: 'size',
          initial: FluentAvatarSize.size72,
          options: FluentAvatarSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentAvatarShape>(
          label: 'Shape',
          id: 'shape',
          initial: FluentAvatarShape.circular,
          options: FluentAvatarShape.values,
          labelOf: _name,
        ),
        OptionKnob<FluentAvatarActive>(
          label: 'Active',
          id: 'active',
          initial: FluentAvatarActive.unset,
          options: FluentAvatarActive.values,
          labelOf: _name,
        ),
        OptionKnob<FluentPresenceStatus?>(
          label: 'Presence',
          id: 'status',
          initial: null,
          options: _statusOptions,
          labelOf: _statusLabel,
        ),
        const BoolKnob(label: 'Out of office', id: 'outOfOffice'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return FluentAvatar(
          name: 'Ada Lovelace',
          initials: knobs.get<String>('initials', 'AL'),
          color: knobs.get<FluentAvatarColor>(
            'color',
            FluentAvatarColor.neutral,
          ),
          size: knobs.get<FluentAvatarSize>('size', FluentAvatarSize.size72),
          shape: knobs.get<FluentAvatarShape>(
            'shape',
            FluentAvatarShape.circular,
          ),
          active: knobs.get<FluentAvatarActive>(
            'active',
            FluentAvatarActive.unset,
          ),
          status: knobs.get<FluentPresenceStatus?>('status', null),
          outOfOffice: knobs.get<bool>('outOfOffice', false),
        );
      },
    ),
    const Story(
      name: 'Content',
      description:
          'Precedence is photo, then initials, then icon, then the built-in '
          'person glyph — pass a photo and the initials are dropped rather '
          'than drawn over it.',
      builder: _contentBuilder,
    ),
    const Story(
      name: 'Sizes',
      description:
          'The thirteen edges Fluent draws. The type ramp, the glyph box and '
          'the presence badge each step on their own table, so a 16 avatar '
          'carries a 12 glyph and a 120 avatar a 48 one.',
      builder: _sizesBuilder,
    ),
    Story(
      name: 'Shapes',
      description:
          'Square is a rounded square, and its radius is Corner radius/Small '
          'at every size — change the size and the corner stays put while the '
          'circle keeps pace.',
      knobs: const [
        OptionKnob<FluentAvatarSize>(
          label: 'Size',
          id: 'size',
          initial: FluentAvatarSize.size48,
          options: FluentAvatarSize.values,
          labelOf: _sizeLabel,
        ),
      ],
      builder: (context) {
        final size = KnobsScope.of(
          context,
        ).get<FluentAvatarSize>('size', FluentAvatarSize.size48);
        return _Cases(
          children: [
            (
              'Circular',
              FluentAvatar(size: size, initials: 'AL', name: 'Ada Lovelace'),
            ),
            (
              'Square',
              FluentAvatar(
                size: size,
                shape: FluentAvatarShape.square,
                initials: 'AL',
                name: 'Ada Lovelace',
              ),
            ),
          ],
        );
      },
    ),
    const Story(
      name: 'Colours',
      description:
          'Three role modes — neutral, brand and the overflow tile — plus the '
          'thirty named palette families, each resolving its own background, '
          'foreground and activity-ring tokens.',
      builder: _coloursBuilder,
    ),
    Story(
      name: 'Activity ring',
      description:
          'A ring drawn one ring-width clear of the avatar, in the colour '
          "mode's own Active stroke token. Press the button: going inactive "
          'collapses the ring, shrinks the avatar to 0.875 and fades it to '
          '0.8, all as a transition.',
      knobs: [
        OptionKnob<FluentAvatarColor>(
          label: 'Colour',
          id: 'color',
          initial: FluentAvatarColor.neutral,
          options: FluentAvatarColor.values,
          labelOf: _name,
        ),
      ],
      builder: (context) => _ActivityRing(
        color: KnobsScope.of(
          context,
        ).get<FluentAvatarColor>('color', FluentAvatarColor.neutral),
      ),
    ),
    Story(
      name: 'Presence badge',
      description:
          'Eight availabilities, anchored flush to the bottom-right corner and '
          'sized from the avatar. The out-of-office flag changes the glyph, '
          'and for Away the colour too.',
      knobs: const [
        OptionKnob<FluentAvatarSize>(
          label: 'Size',
          id: 'size',
          initial: FluentAvatarSize.size48,
          options: FluentAvatarSize.values,
          labelOf: _sizeLabel,
        ),
        BoolKnob(label: 'Out of office', id: 'outOfOffice'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        final size = knobs.get<FluentAvatarSize>(
          'size',
          FluentAvatarSize.size48,
        );
        final outOfOffice = knobs.get<bool>('outOfOffice', false);
        return _Cases(
          children: [
            for (final status in FluentPresenceStatus.values)
              (
                status.name,
                FluentAvatar(
                  size: size,
                  initials: 'AL',
                  name: 'Ada Lovelace',
                  status: status,
                  outOfOffice: outOfOffice,
                ),
              ),
          ],
        );
      },
    ),
    const Story(
      name: 'Name',
      description:
          'The name is what assistive technology announces; the initials are '
          'decoration and are hidden from it. They are two separate '
          'properties — nothing here parses a name into letters, so an avatar '
          'given only a name falls back to the person glyph.',
      builder: _nameBuilder,
    ),
    Story(
      name: 'Group layouts',
      description:
          'Three ways to show several people as one unit: spread with a '
          'positive gap, stacked with a negative one and an outline per face, '
          'or cut into a single circle. Every gap comes from the size table, '
          'so changing the size re-spaces all three.',
      knobs: const [
        OptionKnob<FluentAvatarSize>(
          label: 'Size',
          id: 'size',
          initial: FluentAvatarSize.size48,
          options: FluentAvatarSize.values,
          labelOf: _sizeLabel,
        ),
      ],
      builder: (context) {
        final size = KnobsScope.of(
          context,
        ).get<FluentAvatarSize>('size', FluentAvatarSize.size48);
        return _Cases(
          children: [
            for (final layout in FluentAvatarGroupLayout.values)
              (
                layout.name,
                FluentAvatarGroup(
                  layout: layout,
                  size: size,
                  // The pie reads the first three members and drops the rest.
                  children: _members(
                    size,
                    layout == FluentAvatarGroupLayout.pie ? 3 : 4,
                  ),
                ),
              ),
          ],
        );
      },
    ),
    Story(
      name: 'Group overflow',
      description:
          'The tile at the end of a long group is an ordinary avatar in the '
          'overflow colour — the one mode with a visible inside stroke. The '
          'group counts nothing itself, so the label is yours to write.',
      knobs: const [
        OptionKnob<FluentAvatarGroupLayout>(
          label: 'Layout',
          id: 'layout',
          initial: FluentAvatarGroupLayout.stack,
          options: FluentAvatarGroupLayout.values,
          labelOf: _name,
        ),
      ],
      builder: (context) {
        final layout = KnobsScope.of(
          context,
        ).get<FluentAvatarGroupLayout>('layout', FluentAvatarGroupLayout.stack);
        return FluentAvatarGroup(
          layout: layout,
          children: <Widget>[
            ..._members(FluentAvatarSize.size32, 3),
            const FluentAvatar(
              color: FluentAvatarColor.overflow,
              initials: '+5',
              name: '5 more people',
            ),
          ],
        );
      },
    ),
    const Story(
      name: 'Group with tooltips',
      description:
          'A stacked group hides most of every face, so each member is wrapped '
          'in a tooltip. Hover or tab to a face to see whose it is.',
      builder: _groupTooltipBuilder,
    ),
    const Story(
      name: 'Custom styling',
      description:
          'Three rungs of override — theme defaults, a FluentAvatarTheme over '
          'a subtree, then the widget style, which is merged last and wins.',
      builder: _stylingBuilder,
    ),
  ],
);

String _name(Object? value) => switch (value) {
  Enum(:final String name) => name,
  _ => '$value',
};

String _sizeLabel(FluentAvatarSize value) => value.edge.toInt().toString();

String _statusLabel(FluentPresenceStatus? value) => value?.name ?? 'none';

const List<FluentPresenceStatus?> _statusOptions = <FluentPresenceStatus?>[
  null,
  ...FluentPresenceStatus.values,
];

/// Stand-in for a photograph, so the image story needs neither the network nor
/// an asset bundle. A 12 x 12 PNG, scaled up by `BoxFit.cover`; the bytes are
/// arbitrary colour, which is the one place a story may not read a token.
final MemoryImage _photo = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAIAAADZF8uwAAAAeElEQVR42mOIynuW'
    'UPwoveJ+Xu2d0qabNe3XmnoudU48P2HamemzT85bcGzp0sMMBFWsXrWfgaCKTev3'
    'MBBUsXPLTgaCKg7s3MZAUMXxfZsZCKo4e3g9A0EVV06sYSCo4vbZlQwEVTy6tIyB'
    'oIqX1xczEFTx4c4CAJmCJt7DdMf8AAAAAElFTkSuQmCC',
  ),
);

Widget _contentBuilder(BuildContext context) => _Cases(
  children: [
    (
      'Photo',
      FluentAvatar(
        size: FluentAvatarSize.size48,
        image: _photo,
        name: 'Ada Lovelace',
      ),
    ),
    (
      'Photo wins over initials',
      FluentAvatar(
        size: FluentAvatarSize.size48,
        image: _photo,
        initials: 'AL',
        name: 'Ada Lovelace',
      ),
    ),
    (
      'Initials',
      const FluentAvatar(
        size: FluentAvatarSize.size48,
        initials: 'AL',
        name: 'Ada Lovelace',
      ),
    ),
    (
      'Custom icon',
      const FluentAvatar(
        size: FluentAvatarSize.size48,
        color: FluentAvatarColor.brand,
        icon: Icon(FluentIcons.building_20_regular),
        name: 'Contoso',
      ),
    ),
    (
      'Fallback glyph',
      const FluentAvatar(size: FluentAvatarSize.size48, name: 'Unknown person'),
    ),
  ],
);

Widget _sizesBuilder(BuildContext context) {
  final theme = FluentTheme.of(context);
  return Wrap(
    spacing: FluentSpacing.l,
    runSpacing: FluentSpacing.l,
    crossAxisAlignment: WrapCrossAlignment.end,
    children: [
      for (final size in FluentAvatarSize.values)
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: FluentSpacing.xs,
          children: [
            FluentAvatar(size: size, initials: 'AL', name: 'Ada Lovelace'),
            Text(
              _sizeLabel(size),
              style: theme.typography.caption1.copyWith(
                color: theme.colors.neutralForeground3,
              ),
            ),
          ],
        ),
    ],
  );
}

Widget _coloursBuilder(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: FluentSpacing.xxl,
  children: [
    _Cases(
      children: [
        ('neutral', FluentAvatar(initials: 'AL', name: 'Ada Lovelace')),
        (
          'brand',
          FluentAvatar(
            color: FluentAvatarColor.brand,
            initials: 'AL',
            name: 'Ada Lovelace',
          ),
        ),
        (
          'overflow',
          FluentAvatar(
            color: FluentAvatarColor.overflow,
            initials: '+5',
            name: '5 more people',
          ),
        ),
      ],
    ),
    _Palette(),
  ],
);

Widget _nameBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Name and initials',
      FluentAvatar(
        size: FluentAvatarSize.size48,
        initials: 'AL',
        name: 'Ada Lovelace',
      ),
    ),
    (
      'Name only',
      FluentAvatar(size: FluentAvatarSize.size48, name: 'Ada Lovelace'),
    ),
    ('Neither', FluentAvatar(size: FluentAvatarSize.size48)),
  ],
);

Widget _groupTooltipBuilder(BuildContext context) => FluentAvatarGroup(
  layout: FluentAvatarGroupLayout.stack,
  size: FluentAvatarSize.size40,
  children: <Widget>[
    for (final (initials, color, name) in _people)
      FluentTooltip(
        content: Text(name),
        child: FluentAvatar(
          size: FluentAvatarSize.size40,
          initials: initials,
          color: color,
          name: name,
        ),
      ),
  ],
);

Widget _stylingBuilder(BuildContext context) {
  final colors = FluentTheme.of(context).colors;
  return FluentAvatarTheme(
    style: FluentAvatarStyle.from(
      borderRadius: FluentRadius.allMedium,
      backgroundColor: colors.brandBackground2,
      foregroundColor: colors.brandForeground2,
    ),
    child: _Cases(
      children: [
        (
          'Theme defaults',
          FluentAvatar(
            size: FluentAvatarSize.size48,
            initials: 'AL',
            name: 'Ada Lovelace',
            // Opting out of the surrounding theme by restating the defaults.
            style: FluentAvatarStyle.from(
              borderRadius: FluentRadius.allCircular,
              backgroundColor: colors.neutralBackground6,
              foregroundColor: colors.neutralForeground3,
            ),
          ),
        ),
        (
          'Subtree theme',
          const FluentAvatar(
            size: FluentAvatarSize.size48,
            initials: 'AL',
            name: 'Ada Lovelace',
          ),
        ),
        (
          'Widget style wins',
          FluentAvatar(
            size: FluentAvatarSize.size48,
            initials: 'AL',
            name: 'Ada Lovelace',
            style: FluentAvatarStyle.from(
              backgroundColor: colors.palette.background2Rest(
                FluentPaletteFamily.darkGreen,
              ),
              foregroundColor: colors.palette.foreground2Rest(
                FluentPaletteFamily.darkGreen,
              ),
              borderColor: colors.neutralStroke1,
              borderWidth: FluentStroke.thick,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Four faces reused wherever a story needs a plausible group.
const List<(String, FluentAvatarColor, String)> _people =
    <(String, FluentAvatarColor, String)>[
      ('AL', FluentAvatarColor.cornflower, 'Ada Lovelace'),
      ('GH', FluentAvatarColor.marigold, 'Grace Hopper'),
      ('KZ', FluentAvatarColor.seafoam, 'Katherine Johnson'),
      ('AT', FluentAvatarColor.lilac, 'Alan Turing'),
    ];

/// The first [count] of [_people], all at [size] — a group does not push its
/// size down into its children, so every member has to restate it.
List<Widget> _members(FluentAvatarSize size, int count) => <Widget>[
  for (final (initials, color, name) in _people.take(count))
    FluentAvatar(size: size, initials: initials, color: color, name: name),
];

/// The thirty named palette families, captioned.
class _Palette extends StatelessWidget {
  const _Palette();

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Wrap(
      spacing: FluentSpacing.m,
      runSpacing: FluentSpacing.m,
      children: [
        for (final color in FluentAvatarColor.values)
          if (color.family != null)
            SizedBox(
              width: 76,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: FluentSpacing.xs,
                children: [
                  FluentAvatar(color: color, initials: 'AL', name: color.name),
                  Text(
                    color.name,
                    textAlign: TextAlign.center,
                    style: theme.typography.caption1.copyWith(
                      color: theme.colors.neutralForeground3,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// The activity ring's three states, plus a live toggle so the transition
/// between the last two can actually be watched.
class _ActivityRing extends StatefulWidget {
  const _ActivityRing({required this.color});

  final FluentAvatarColor color;

  @override
  State<_ActivityRing> createState() => _ActivityRingState();
}

class _ActivityRingState extends State<_ActivityRing> {
  FluentAvatarActive _active = FluentAvatarActive.active;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.xxl,
    children: [
      _Cases(
        children: [
          for (final active in FluentAvatarActive.values)
            (
              active.name,
              // The ring paints outside the avatar's box, so it needs room.
              Padding(
                padding: const EdgeInsets.all(FluentSpacing.s),
                child: FluentAvatar(
                  size: FluentAvatarSize.size56,
                  color: widget.color,
                  active: active,
                  initials: 'AL',
                  name: 'Ada Lovelace',
                ),
              ),
            ),
        ],
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.l,
        children: [
          Padding(
            padding: const EdgeInsets.all(FluentSpacing.m),
            child: FluentAvatar(
              size: FluentAvatarSize.size72,
              color: widget.color,
              active: _active,
              initials: 'AL',
              name: 'Ada Lovelace',
            ),
          ),
          FluentButton(
            onPressed: () => setState(() {
              _active = _active == FluentAvatarActive.active
                  ? FluentAvatarActive.inactive
                  : FluentAvatarActive.active;
            }),
            child: Text(
              _active == FluentAvatarActive.active
                  ? 'Go inactive'
                  : 'Go active',
            ),
          ),
        ],
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
