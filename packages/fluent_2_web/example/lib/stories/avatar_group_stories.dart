import 'dart:convert';

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentAvatarGroup].
final StorySection avatarGroupStories = StorySection(
  component: 'Avatar group',
  description:
      'Several people shown as one unit: spread along a row, stacked with an '
      'outline so each still reads as a person, or cut into a single pie the '
      'size of one avatar. The group owns the arrangement only — every member '
      'is an ordinary FluentAvatar and keeps its own colour, content, shape '
      'and presence badge.',
  stories: [
    Story(
      name: 'Default',
      description:
          'A spread row of four members at 32. Both design axes are live: '
          'layout decides the structure, size decides the gap and the outline '
          'width the group derives from it.',
      knobs: const [
        OptionKnob<FluentAvatarGroupLayout>(
          label: 'Layout',
          id: 'layout',
          initial: FluentAvatarGroupLayout.spread,
          options: FluentAvatarGroupLayout.values,
          labelOf: _layoutLabel,
        ),
        OptionKnob<FluentAvatarSize>(
          label: 'Size',
          id: 'size',
          initial: FluentAvatarSize.size32,
          options: FluentAvatarSize.values,
          labelOf: _sizeLabel,
        ),
        NumberKnob(label: 'Members', id: 'count', initial: 4, min: 1, max: 6),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        final size = knobs.get<FluentAvatarSize>(
          'size',
          FluentAvatarSize.size32,
        );
        return FluentAvatarGroup(
          layout: knobs.get<FluentAvatarGroupLayout>(
            'layout',
            FluentAvatarGroupLayout.spread,
          ),
          size: size,
          children: _team(knobs.get<double>('count', 4).round(), size: size),
        );
      },
    ),
    const Story(
      name: 'Layouts',
      description:
          'The three arrangements side by side: spread leaves a positive gap, '
          'stack overlaps with a background-coloured ring per member, and pie '
          'crops the first three members into one avatar-sized circle.',
      builder: _layoutsBuilder,
    ),
    Story(
      name: 'Sizes',
      description:
          'The gap is not proportional — it steps through the Avatar group '
          'size table, so 16 spreads by 4 and 120 by 20, and the stack overlap '
          'goes the other way as a negative gap.',
      knobs: const [
        OptionKnob<FluentAvatarGroupLayout>(
          label: 'Layout',
          id: 'layout',
          initial: FluentAvatarGroupLayout.spread,
          options: FluentAvatarGroupLayout.values,
          labelOf: _layoutLabel,
        ),
      ],
      builder: (context) {
        final layout = KnobsScope.of(context).get<FluentAvatarGroupLayout>(
          'layout',
          FluentAvatarGroupLayout.spread,
        );
        return _Cases(
          children: [
            for (final size in const [
              FluentAvatarSize.size16,
              FluentAvatarSize.size24,
              FluentAvatarSize.size32,
              FluentAvatarSize.size48,
              FluentAvatarSize.size72,
              FluentAvatarSize.size96,
            ])
              (
                '${size.edge.round()}',
                FluentAvatarGroup(
                  layout: layout,
                  size: size,
                  children: _team(3, size: size),
                ),
              ),
          ],
        );
      },
    ),
    Story(
      name: 'Stack',
      description:
          'Each stacked member is ringed in the page background so the overlap '
          'still reads as separate people; the ring thickens with size, 2 '
          'below 56, 3 below 72, 4 above.',
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
        return FluentAvatarGroup(
          layout: FluentAvatarGroupLayout.stack,
          size: size,
          children: _team(4, size: size),
        );
      },
    ),
    Story(
      name: 'Pie',
      description:
          'One member fills the circle, two split it down the middle, three '
          'quarter the right half. A fourth is not drawn at all — the pie '
          'reads the first three and stops.',
      knobs: const [
        OptionKnob<FluentAvatarSize>(
          label: 'Size',
          id: 'size',
          initial: FluentAvatarSize.size72,
          options: FluentAvatarSize.values,
          labelOf: _sizeLabel,
        ),
      ],
      builder: (context) {
        final size = KnobsScope.of(
          context,
        ).get<FluentAvatarSize>('size', FluentAvatarSize.size72);
        return _Cases(
          children: [
            for (var count = 1; count <= 4; count++)
              (
                count == 4 ? '4 members, 3 drawn' : '$count',
                FluentAvatarGroup(
                  layout: FluentAvatarGroupLayout.pie,
                  size: size,
                  children: _team(count, size: size),
                ),
              ),
          ],
        );
      },
    ),
    const Story(
      name: 'Overflow tile',
      description:
          'The `+3` at the end is an ordinary member in the overflow colour — '
          'the group counts nothing itself, so the truncation and the label '
          'are the caller\'s decision.',
      builder: _overflowBuilder,
    ),
    const Story(
      name: 'Member content',
      description:
          'Members are plain avatars, so one group can mix a photo, initials '
          'and a fallback glyph; with no image and no initials the person icon '
          'is drawn at the size the avatar dictates.',
      builder: _contentBuilder,
    ),
    const Story(
      name: 'Member colours',
      description:
          'Each member picks its own Avatar colour mode: neutral, brand, one '
          'of the thirty palette families, or overflow. The group never tints '
          'its members.',
      builder: _colourBuilder,
    ),
    const Story(
      name: 'Presence badges',
      description:
          'A member with a status shows a presence badge sized from its own '
          'avatar. Spread leaves room for it; a stack overlaps the badge of '
          'every member but the last.',
      builder: _presenceBuilder,
    ),
    const Story(
      name: 'Square members',
      description:
          'Square members need the group told too: the stack ring is drawn by '
          'the group, so its radius comes from the group style, not from the '
          'avatars it rings.',
      builder: _squareBuilder,
    ),
    const Story(
      name: 'Activity ring',
      description:
          'Toggling a member to inactive collapses its ring, scales it to '
          '0.875 and fades it to 0.8 — animated, and clipped by the group only '
          'in the pie layout, where a member has no room outside its slice.',
      builder: _activeBuilder,
    ),
    const Story(
      name: 'Tooltips',
      description:
          'Naming members: `name` is what assistive technology announces, and '
          'a FluentTooltip around each avatar gives a pointer user the same '
          'thing on hover.',
      builder: _tooltipBuilder,
    ),
    const Story(
      name: 'Custom styling',
      description:
          'Three rungs of override — theme defaults, a FluentAvatarGroupTheme '
          'over a subtree, then the widget style, which is merged last and '
          'wins.',
      builder: _stylingBuilder,
    ),
  ],
);

String _layoutLabel(FluentAvatarGroupLayout value) => value.name;

String _sizeLabel(FluentAvatarSize value) => value.edge.round().toString();

/// The people every story draws from, so a reader compares arrangements rather
/// than casts.
const List<(String, String, FluentAvatarColor)> _people = [
  ('Ada Lovelace', 'AL', FluentAvatarColor.cornflower),
  ('Grace Hopper', 'GH', FluentAvatarColor.forest),
  ('Katherine Johnson', 'KJ', FluentAvatarColor.marigold),
  ('Alan Turing', 'AT', FluentAvatarColor.magenta),
  ('Radia Perlman', 'RP', FluentAvatarColor.teal),
  ('Barbara Liskov', 'BL', FluentAvatarColor.brass),
];

/// [count] members at [size]. The group does not push its size down into its
/// children, so every story states it on both.
List<Widget> _team(
  int count, {
  FluentAvatarSize size = FluentAvatarSize.size32,
  FluentAvatarShape shape = FluentAvatarShape.circular,
}) => <Widget>[
  for (final (name, initials, colour) in _people.take(count))
    FluentAvatar(
      name: name,
      initials: initials,
      color: colour,
      size: size,
      shape: shape,
    ),
];

Widget _layoutsBuilder(BuildContext context) => _Cases(
  children: [
    for (final layout in FluentAvatarGroupLayout.values)
      (
        layout.name,
        FluentAvatarGroup(
          layout: layout,
          size: FluentAvatarSize.size48,
          children: _team(3, size: FluentAvatarSize.size48),
        ),
      ),
  ],
);

Widget _overflowBuilder(BuildContext context) => _Cases(
  children: [
    (
      'Spread',
      FluentAvatarGroup(
        size: FluentAvatarSize.size40,
        children: <Widget>[
          ..._team(3, size: FluentAvatarSize.size40),
          const FluentAvatar(
            name: '3 more people',
            initials: '+3',
            color: FluentAvatarColor.overflow,
            size: FluentAvatarSize.size40,
          ),
        ],
      ),
    ),
    (
      'Stack',
      FluentAvatarGroup(
        layout: FluentAvatarGroupLayout.stack,
        size: FluentAvatarSize.size40,
        children: <Widget>[
          ..._team(3, size: FluentAvatarSize.size40),
          const FluentAvatar(
            name: '3 more people',
            initials: '+3',
            color: FluentAvatarColor.overflow,
            size: FluentAvatarSize.size40,
          ),
        ],
      ),
    ),
  ],
);

Widget _contentBuilder(BuildContext context) => _Cases(
  children: [
    for (final layout in FluentAvatarGroupLayout.values)
      (
        layout.name,
        FluentAvatarGroup(
          layout: layout,
          size: FluentAvatarSize.size56,
          children: <Widget>[
            FluentAvatar(
              name: 'Ada Lovelace',
              image: _photos[0],
              size: FluentAvatarSize.size56,
            ),
            const FluentAvatar(
              name: 'Grace Hopper',
              initials: 'GH',
              color: FluentAvatarColor.forest,
              size: FluentAvatarSize.size56,
            ),
            const FluentAvatar(
              name: 'Build agent',
              icon: Icon(FluentIcons.bot_28_filled),
              color: FluentAvatarColor.steel,
              size: FluentAvatarSize.size56,
            ),
          ],
        ),
      ),
  ],
);

Widget _colourBuilder(BuildContext context) => _Cases(
  children: [
    (
      'Roles',
      const FluentAvatarGroup(
        size: FluentAvatarSize.size40,
        children: <Widget>[
          FluentAvatar(
            name: 'Neutral',
            initials: 'NE',
            size: FluentAvatarSize.size40,
          ),
          FluentAvatar(
            name: 'Brand',
            initials: 'BR',
            color: FluentAvatarColor.brand,
            size: FluentAvatarSize.size40,
          ),
          FluentAvatar(
            name: 'Overflow',
            initials: '+9',
            color: FluentAvatarColor.overflow,
            size: FluentAvatarSize.size40,
          ),
        ],
      ),
    ),
    (
      'Palette families',
      FluentAvatarGroup(
        size: FluentAvatarSize.size40,
        children: _team(6, size: FluentAvatarSize.size40),
      ),
    ),
    (
      'Stacked',
      FluentAvatarGroup(
        layout: FluentAvatarGroupLayout.stack,
        size: FluentAvatarSize.size40,
        children: _team(6, size: FluentAvatarSize.size40),
      ),
    ),
  ],
);

Widget _presenceBuilder(BuildContext context) {
  const statuses = <FluentPresenceStatus>[
    FluentPresenceStatus.available,
    FluentPresenceStatus.busy,
    FluentPresenceStatus.doNotDisturb,
    FluentPresenceStatus.away,
    FluentPresenceStatus.offline,
  ];
  List<Widget> members({bool outOfOffice = false}) => <Widget>[
    for (var i = 0; i < statuses.length; i++)
      FluentAvatar(
        name: _people[i].$1,
        initials: _people[i].$2,
        color: _people[i].$3,
        size: FluentAvatarSize.size48,
        status: statuses[i],
        outOfOffice: outOfOffice,
      ),
  ];

  return _Cases(
    children: [
      (
        'Spread',
        FluentAvatarGroup(size: FluentAvatarSize.size48, children: members()),
      ),
      (
        'Out of office',
        FluentAvatarGroup(
          size: FluentAvatarSize.size48,
          children: members(outOfOffice: true),
        ),
      ),
      (
        'Stack — badges collide',
        FluentAvatarGroup(
          layout: FluentAvatarGroupLayout.stack,
          size: FluentAvatarSize.size48,
          children: members(),
        ),
      ),
    ],
  );
}

Widget _squareBuilder(BuildContext context) => _Cases(
  children: [
    (
      'Spread',
      FluentAvatarGroup(
        size: FluentAvatarSize.size48,
        children: _team(
          3,
          size: FluentAvatarSize.size48,
          shape: FluentAvatarShape.square,
        ),
      ),
    ),
    (
      'Stack, circular ring',
      FluentAvatarGroup(
        layout: FluentAvatarGroupLayout.stack,
        size: FluentAvatarSize.size48,
        children: _team(
          3,
          size: FluentAvatarSize.size48,
          shape: FluentAvatarShape.square,
        ),
      ),
    ),
    (
      'Stack, ring told to match',
      FluentAvatarGroup(
        layout: FluentAvatarGroupLayout.stack,
        size: FluentAvatarSize.size48,
        style: FluentAvatarGroupStyle.from(borderRadius: FluentRadius.allSmall),
        children: _team(
          3,
          size: FluentAvatarSize.size48,
          shape: FluentAvatarShape.square,
        ),
      ),
    ),
  ],
);

Widget _activeBuilder(BuildContext context) => const _ActiveDemo();

Widget _tooltipBuilder(BuildContext context) => FluentAvatarGroup(
  layout: FluentAvatarGroupLayout.stack,
  size: FluentAvatarSize.size48,
  children: <Widget>[
    for (final (name, initials, colour) in _people.take(4))
      FluentTooltip(
        content: Text(name),
        semanticLabel: name,
        child: FluentAvatar(
          name: name,
          initials: initials,
          color: colour,
          size: FluentAvatarSize.size48,
        ),
      ),
  ],
);

Widget _stylingBuilder(BuildContext context) {
  final colors = FluentTheme.of(context).colors;
  return FluentAvatarGroupTheme(
    style: FluentAvatarGroupStyle.from(spacing: FluentSpacing.xxl),
    child: _Cases(
      children: [
        (
          'Subtree theme',
          FluentAvatarGroup(
            size: FluentAvatarSize.size40,
            children: _team(3, size: FluentAvatarSize.size40),
          ),
        ),
        (
          'Widget style wins',
          FluentAvatarGroup(
            layout: FluentAvatarGroupLayout.stack,
            size: FluentAvatarSize.size40,
            style: FluentAvatarGroupStyle.from(
              spacing: -FluentSpacing.xxl,
              outlineColor: colors.brandBackground,
              outlineWidth: FluentStroke.thickest,
            ),
            children: _team(3, size: FluentAvatarSize.size40),
          ),
        ),
        (
          'Pie rule recoloured',
          FluentAvatarGroup(
            layout: FluentAvatarGroupLayout.pie,
            size: FluentAvatarSize.size40,
            style: FluentAvatarGroupStyle.from(
              dividerColor: colors.brandBackground,
              dividerWidth: FluentStroke.thickest,
            ),
            children: _team(3, size: FluentAvatarSize.size40),
          ),
        ),
      ],
    ),
  );
}

/// Three photographs, inlined as 8×8 gradients.
///
/// The exception the gallery allows to the no-hardcoded-colour rule: an avatar
/// photo is arbitrary content, not a token, and the example package ships no
/// asset bundle to load one from.
final List<ImageProvider<Object>> _photos = <ImageProvider<Object>>[
  for (final data in const <String>[
    'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAAT0lEQVR42mPgz9krVnRAtvKIav0J'
        'nbYzJj0XrCdfcZ55gwGrqNeCOwxYRQOXPWDAKhq59gkDVtGEzS8YsIpm7HrDgFU0/8AHBqyi'
        '5ce/AADbQWz36Iy+EwAAAABJRU5ErkJggg==',
    'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAATklEQVR42mM4Yuh9wtL/jGPIBc+I'
        'K0GxN6MS7yalPczOYsAq+rQ4nwGr6MvqYgasou+aKxiwin7qqWHAKvptSiMDVtFfc1oZsIr+'
        'X9oFAHKZbXfDvnjjAAAAAElFTkSuQmCC',
    'iVBORw0KGgoAAAANSUhEUgAAAAgAAAAICAIAAABLbSncAAAATUlEQVR42mPgzuIWLxJRqZI1aFaz'
        '7db3nGwRNscxaYkXA1bR/DXBDFhFq7fGMGAV7dibyoBVdMrRPAasogvPlTNgFV17rYEBq+iu'
        '+10AlntUE49q1AIAAAAASUVORK5CYII=',
  ])
    MemoryImage(base64Decode(data)),
];

/// A group whose middle member can be switched between the three activity
/// states, so the ring's arrive and leave transitions are watchable.
class _ActiveDemo extends StatefulWidget {
  const _ActiveDemo();

  @override
  State<_ActiveDemo> createState() => _ActiveDemoState();
}

class _ActiveDemoState extends State<_ActiveDemo> {
  FluentAvatarActive _active = FluentAvatarActive.active;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FluentSpacing.xxl,
    children: [
      Wrap(
        spacing: FluentSpacing.s,
        children: [
          for (final value in FluentAvatarActive.values)
            FluentButton(
              appearance: value == _active
                  ? FluentButtonAppearance.primary
                  : FluentButtonAppearance.secondary,
              onPressed: () => setState(() => _active = value),
              child: Text(value.name),
            ),
        ],
      ),
      _Cases(
        children: [
          for (final layout in FluentAvatarGroupLayout.values)
            (
              layout.name,
              FluentAvatarGroup(
                layout: layout,
                size: FluentAvatarSize.size48,
                children: <Widget>[
                  for (final (index, person) in _people.take(3).indexed)
                    FluentAvatar(
                      name: person.$1,
                      initials: person.$2,
                      color: person.$3,
                      size: FluentAvatarSize.size48,
                      active: index == 1 ? _active : FluentAvatarActive.unset,
                    ),
                ],
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
      runSpacing: FluentSpacing.xxl,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        for (final (caption, child) in children)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
