import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Three grids: the six-step size ramp, then the three text positions crossed
/// with both alignments, then the presence-only form — which is the one where
/// the badge's own inset changes with the alignment rather than the row's.
///
/// The line count is varied on purpose. The `-2` line overlap and the 2px
/// content inset only exist when there is a second line, so a grid of
/// name-only personas would prove nothing about either.
void main() {
  goldenGridTest(
    'persona',
    () => goldenGrid(<Widget>[
      for (final size in FluentPersonaSize.values)
        FluentPersona(
          size: size,
          name: 'Ada Lovelace',
          initials: 'AL',
          secondary: const Text('Software engineer'),
          color: FluentAvatarColor.cornflower,
        ),
      for (final size in FluentPersonaSize.values)
        FluentPersona(size: size, name: 'Ada Lovelace', initials: 'AL'),
      for (final size in FluentPersonaSize.values)
        FluentPersona(
          size: size,
          name: 'Ada Lovelace',
          initials: 'AL',
          secondary: const Text('Software engineer'),
          tertiary: const Text('Redmond'),
          quaternary: const Text('UTC-8'),
          status: FluentPresenceStatus.available,
        ),
    ], columns: 3),
    surfaceSize: const Size(1600, 1400),
  );

  goldenGridTest(
    'persona_layout',
    () => goldenGrid(<Widget>[
      for (final position in FluentPersonaTextPosition.values)
        for (final alignment in FluentPersonaTextAlignment.values)
          FluentPersona(
            textPosition: position,
            textAlignment: alignment,
            size: FluentPersonaSize.extraLarge,
            name: 'Ada Lovelace',
            initials: 'AL',
            secondary: const Text('Software engineer'),
            tertiary: const Text('Redmond'),
            color: FluentAvatarColor.marigold,
          ),
    ], columns: 2),
    surfaceSize: const Size(1200, 1000),
  );

  goldenGridTest(
    'persona_presence',
    () => goldenGrid(<Widget>[
      for (final alignment in FluentPersonaTextAlignment.values)
        for (final size in FluentPersonaSize.values)
          FluentPersona(
            presenceOnly: true,
            status: FluentPresenceStatus.available,
            textAlignment: alignment,
            size: size,
            name: 'Ada Lovelace',
            secondary: size == FluentPersonaSize.extraSmall
                ? null
                : const Text('Software engineer'),
          ),
      for (final status in <FluentPresenceStatus>[
        FluentPresenceStatus.busy,
        FluentPresenceStatus.away,
        FluentPresenceStatus.doNotDisturb,
        FluentPresenceStatus.offline,
        FluentPresenceStatus.outOfOffice,
        FluentPresenceStatus.unknown,
      ])
        FluentPersona(
          presenceOnly: true,
          status: status,
          name: 'Ada Lovelace',
          secondary: const Text('Software engineer'),
        ),
    ], columns: 6),
    surfaceSize: const Size(1600, 1000),
  );
}
