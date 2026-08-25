import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Three grids. The avatar's own: the size ramp in initials and in the fallback
/// glyph, then every one of the 33 `Avatar color` modes, then shape, activity
/// and presence. Then one per group layout.
///
/// The image type is absent on purpose — a golden of a network or asset image
/// tests the loader, not the avatar.
void main() {
  goldenGridTest(
    'avatar',
    () => goldenGrid(<Widget>[
      for (final size in FluentAvatarSize.values)
        FluentAvatar(size: size, initials: 'AL'),
      for (final size in FluentAvatarSize.values) FluentAvatar(size: size),
      for (final color in FluentAvatarColor.values)
        FluentAvatar(color: color, initials: 'AL'),
      for (final size in <FluentAvatarSize>[
        FluentAvatarSize.size24,
        FluentAvatarSize.size48,
        FluentAvatarSize.size72,
        FluentAvatarSize.size120,
      ])
        FluentAvatar(
          size: size,
          shape: FluentAvatarShape.square,
          initials: 'AL',
        ),
      for (final active in FluentAvatarActive.values)
        FluentAvatar(
          size: FluentAvatarSize.size48,
          active: active,
          initials: 'AL',
        ),
      for (final active in FluentAvatarActive.values)
        FluentAvatar(
          size: FluentAvatarSize.size72,
          color: FluentAvatarColor.cranberry,
          active: active,
          initials: 'AL',
        ),
      for (final status in <FluentPresenceStatus>[
        FluentPresenceStatus.available,
        FluentPresenceStatus.busy,
        FluentPresenceStatus.away,
        FluentPresenceStatus.offline,
      ])
        FluentAvatar(
          size: FluentAvatarSize.size48,
          status: status,
          initials: 'AL',
        ),
    ], columns: 13),
    surfaceSize: const Size(2400, 1600),
  );

  goldenGridTest(
    'avatar_group',
    () => goldenGrid(<Widget>[
      for (final layout in <FluentAvatarGroupLayout>[
        FluentAvatarGroupLayout.spread,
        FluentAvatarGroupLayout.stack,
      ])
        FluentAvatarGroup(
          layout: layout,
          size: FluentAvatarSize.size48,
          children: _members(4, FluentAvatarSize.size48),
        ),
      for (final count in <int>[2, 3])
        FluentAvatarGroup(
          layout: FluentAvatarGroupLayout.pie,
          size: FluentAvatarSize.size72,
          children: _members(count, FluentAvatarSize.size72),
        ),
      FluentAvatarGroup(
        layout: FluentAvatarGroupLayout.stack,
        size: FluentAvatarSize.size96,
        children: <Widget>[
          ..._members(3, FluentAvatarSize.size96),
          const FluentAvatar(
            size: FluentAvatarSize.size96,
            color: FluentAvatarColor.overflow,
            initials: '+7',
          ),
        ],
      ),
    ], columns: 2),
    surfaceSize: const Size(1600, 1200),
  );
}

/// Four different palette families, so the slices and the overlap are legible
/// rather than one grey smear.
List<Widget> _members(int count, FluentAvatarSize size) {
  const colors = <FluentAvatarColor>[
    FluentAvatarColor.cornflower,
    FluentAvatarColor.marigold,
    FluentAvatarColor.forest,
    FluentAvatarColor.plum,
  ];
  return <Widget>[
    for (var i = 0; i < count; i++)
      FluentAvatar(
        size: size,
        color: colors[i % colors.length],
        initials: 'A$i',
      ),
  ];
}
