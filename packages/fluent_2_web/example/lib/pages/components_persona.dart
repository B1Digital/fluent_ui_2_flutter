import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Persona docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage personaPage = DocsPage(
  id: 'components-persona',
  title: 'Persona',
  description:
      'A Persona is a visual representation of a person or status that '
      'showcases an Avatar, PresenceBadge, or an Avatar with a PresenceBadge.',
  source: 'lib/pages/components_persona.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-persona--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-persona--text-alignment',
      title: 'Text Alignment',
      description:
          'A Persona supports two text alignments, start being the default '
          'position.',
      builder: _textAlignment,
    ),
    DocsSection(
      id: 'components-persona--text-position',
      title: 'Text Position',
      description:
          'A Persona supports three text positions, after being the default '
          'position.',
      builder: _textPosition,
    ),
    DocsSection(
      id: 'components-persona--presence-previous-behavior',
      title: 'Presence Previous Behavior',
      description:
          'PresenceBadge maps its presence to the behavior in v8. If the '
          'previous behavior is desired, it is possible to override the icon '
          'and className to match it. Note that Persona maps to one size '
          'smaller, such as huge to large and medium to small. As the size '
          'prop shows, Persona does not support tiny.',
      builder: _presencePreviousBehavior,
    ),
    DocsSection(
      id: 'components-persona--presence-size',
      title: 'Presence Size',
      description:
          'A Persona supports different sizes, medium being the default.',
      builder: _presenceSize,
    ),
    DocsSection(
      id: 'components-persona--avatar-size',
      title: 'Avatar Size',
      description:
          'A Persona supports different sizes, medium being the default.',
      builder: _avatarSize,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'name',
      type: 'String?',
      defaultValue: 'null',
      description: "The person's name, used as the default primary line.",
    ),
    PropRow(
      name: 'primary',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'The first and largest line. Defaults to name as plain text.',
    ),
    PropRow(
      name: 'secondary',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'The second line.',
    ),
    PropRow(
      name: 'tertiary',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'The third line.',
    ),
    PropRow(
      name: 'quaternary',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'The fourth line.',
    ),
    PropRow(
      name: 'presenceOnly',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Shows a presence badge instead of the avatar. Nothing is drawn '
          'unless status is also set.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentPersonaSize',
      defaultValue: 'FluentPersonaSize.medium',
      description: 'Avatar, badge and type ramp step.',
    ),
    PropRow(
      name: 'textPosition',
      type: 'FluentPersonaTextPosition',
      defaultValue: 'FluentPersonaTextPosition.after',
      description: 'Where the text sits relative to the avatar.',
    ),
    PropRow(
      name: 'textAlignment',
      type: 'FluentPersonaTextAlignment',
      defaultValue: 'FluentPersonaTextAlignment.center',
      description: 'How the avatar lines up with the text.',
    ),
    PropRow(
      name: 'image',
      type: 'ImageProvider<Object>?',
      defaultValue: 'null',
      description: 'Photo for the composed avatar.',
    ),
    PropRow(
      name: 'initials',
      type: 'String?',
      defaultValue: 'null',
      description: 'Initials for the composed avatar.',
    ),
    PropRow(
      name: 'icon',
      type: 'Widget?',
      defaultValue: 'null',
      description: "Replaces the composed avatar's default person glyph.",
    ),
    PropRow(
      name: 'color',
      type: 'FluentAvatarColor',
      defaultValue: 'FluentAvatarColor.neutral',
      description: 'Which Avatar color mode the composed avatar paints in.',
    ),
    PropRow(
      name: 'shape',
      type: 'FluentAvatarShape',
      defaultValue: 'FluentAvatarShape.circular',
      description: 'Corner treatment of the composed avatar.',
    ),
    PropRow(
      name: 'active',
      type: 'FluentAvatarActive',
      defaultValue: 'FluentAvatarActive.unset',
      description: 'Whether the composed avatar draws its activity ring.',
    ),
    PropRow(
      name: 'status',
      type: 'FluentPresenceStatus?',
      defaultValue: 'null',
      description: "The person's availability.",
    ),
    PropRow(
      name: 'outOfOffice',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether the person is out of office. Only read when status is set.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentPersonaStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
  ],
);

// #docregion components-persona--default
Widget _default(BuildContext context) => const FluentPersona(
  name: 'Kevin Sturgis',
  secondary: Text('Available'),
  status: FluentPresenceStatus.available,
  image: AssetImage('assets/storybook/persona-male.png'),
);
// #enddocregion components-persona--default

// #docregion components-persona--text-alignment
// Upstream lays the two personas out in a three-column grid, so they sit at the
// first and second third of the row and the last column stays empty.
Widget _textAlignment(BuildContext context) => const Row(
  children: <Widget>[
    Expanded(
      child: Center(
        child: FluentPersona(
          textAlignment: FluentPersonaTextAlignment.start,
          name: 'Kevin Sturgis',
          status: FluentPresenceStatus.available,
          secondary: Text('Available'),
          tertiary: Text('Software Engineer'),
          quaternary: Text('Microsoft'),
        ),
      ),
    ),
    Expanded(
      child: Center(
        child: FluentPersona(
          textAlignment: FluentPersonaTextAlignment.center,
          name: 'Kevin Sturgis',
          status: FluentPresenceStatus.available,
          secondary: Text('Available'),
          tertiary: Text('Software Engineer'),
          quaternary: Text('Microsoft'),
        ),
      ),
    ),
    Spacer(),
  ],
);
// #enddocregion components-persona--text-alignment

// #docregion components-persona--text-position
Widget _textPosition(BuildContext context) => const Row(
  children: <Widget>[
    Expanded(
      child: Center(
        child: FluentPersona(
          textPosition: FluentPersonaTextPosition.after,
          name: 'Kevin Sturgis',
          status: FluentPresenceStatus.available,
          secondary: Text('Available'),
        ),
      ),
    ),
    Expanded(
      child: Center(
        child: FluentPersona(
          textPosition: FluentPersonaTextPosition.below,
          name: 'Kevin Sturgis',
          status: FluentPresenceStatus.available,
          secondary: Text('Available'),
        ),
      ),
    ),
    Expanded(
      child: Center(
        child: FluentPersona(
          textPosition: FluentPersonaTextPosition.before,
          name: 'Kevin Sturgis',
          status: FluentPresenceStatus.available,
          secondary: Text('Available'),
        ),
      ),
    ),
  ],
);
// #enddocregion components-persona--text-position

// #docregion components-persona--presence-previous-behavior
// Upstream reaches past the badge and swaps its icon and colour outright.
// `FluentPersona` composes its own `FluentPresenceBadge`, so there is no icon
// slot to hand a glyph to — but the glyph a status resolves to is the same
// table upstream is picking from, so the previous behaviour is reachable by
// choosing the status that already draws it and restyling the colour through
// `FluentPresenceBadgeTheme`, which is our stand-in for `className`:
//
//   * away out of office previously drew the *available regular* glyph in
//     marigold, which is what `available` + `outOfOffice` resolves to here;
//   * offline previously drew the *offline regular* glyph in
//     `neutralForeground3` — which is exactly what `offline` still draws, so
//     that row needs no override at all.
Widget _presencePreviousBehavior(BuildContext context) {
  final FluentColors colors = FluentTheme.of(context).colors;

  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 20,
    children: <Widget>[
      const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: <Widget>[
          Text('Current Behavior'),
          FluentPersona(
            status: FluentPresenceStatus.away,
            outOfOffice: true,
            name: 'Kevin Sturgis',
            secondary: Text('Away - OOF'),
          ),
          FluentPersona(
            status: FluentPresenceStatus.offline,
            outOfOffice: true,
            name: 'Kevin Sturgis',
            secondary: Text('Offline - OOF'),
          ),
        ],
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: <Widget>[
          const Text('Previous Behavior'),
          FluentPresenceBadgeTheme(
            style: FluentPresenceBadgeStyle.from(
              foregroundColor: colors.statusAwayBackground3,
            ),
            child: const FluentPersona(
              status: FluentPresenceStatus.available,
              outOfOffice: true,
              name: 'Kevin Sturgis',
              secondary: Text('Away - OOF'),
            ),
          ),
          const FluentPersona(
            status: FluentPresenceStatus.offline,
            name: 'Kevin Sturgis',
            secondary: Text('Offline - OOF'),
          ),
        ],
      ),
    ],
  );
}
// #enddocregion components-persona--presence-previous-behavior

// #docregion components-persona--presence-size
Widget _presenceSize(BuildContext context) => const Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: 10,
  children: <Widget>[
    Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: <Widget>[
        FluentPersona(
          size: FluentPersonaSize.extraSmall,
          presenceOnly: true,
          status: FluentPresenceStatus.available,
          name: 'Kevin Sturgis',
          secondary: Text('Available'),
        ),
        FluentPersona(
          size: FluentPersonaSize.small,
          presenceOnly: true,
          status: FluentPresenceStatus.available,
          name: 'Kevin Sturgis',
          secondary: Text('Available'),
        ),
      ],
    ),
    Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: <Widget>[
        FluentPersona(
          size: FluentPersonaSize.medium,
          presenceOnly: true,
          status: FluentPresenceStatus.available,
          name: 'Kevin Sturgis',
          secondary: Text('Available'),
        ),
        FluentPersona(
          size: FluentPersonaSize.large,
          presenceOnly: true,
          status: FluentPresenceStatus.available,
          name: 'Kevin Sturgis',
          secondary: Text('Available'),
        ),
      ],
    ),
    Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: <Widget>[
        FluentPersona(
          size: FluentPersonaSize.extraLarge,
          presenceOnly: true,
          status: FluentPresenceStatus.available,
          name: 'Kevin Sturgis',
          secondary: Text('Available'),
        ),
        FluentPersona(
          size: FluentPersonaSize.huge,
          presenceOnly: true,
          status: FluentPresenceStatus.available,
          name: 'Kevin Sturgis',
          secondary: Text('Available'),
        ),
      ],
    ),
  ],
);
// #enddocregion components-persona--presence-size

// #docregion components-persona--avatar-size
// Upstream asks the avatar for `color: "colorful"`, which hashes the name to
// one of the palette families. Our `FluentAvatarColor` names the families
// directly and has no hashing mode, so the family "Kevin Sturgis" hashes to
// upstream — lavender — is named here instead.
Widget _avatarSize(BuildContext context) => const Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: 10,
  children: <Widget>[
    Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: <Widget>[
        FluentPersona(
          status: FluentPresenceStatus.available,
          size: FluentPersonaSize.extraSmall,
          name: 'Kevin Sturgis',
          color: FluentAvatarColor.lavender,
          secondary: Text('Available'),
        ),
        FluentPersona(
          status: FluentPresenceStatus.available,
          size: FluentPersonaSize.small,
          name: 'Kevin Sturgis',
          color: FluentAvatarColor.lavender,
          secondary: Text('Available'),
        ),
      ],
    ),
    Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: <Widget>[
        FluentPersona(
          status: FluentPresenceStatus.available,
          size: FluentPersonaSize.medium,
          name: 'Kevin Sturgis',
          color: FluentAvatarColor.lavender,
          secondary: Text('Available'),
        ),
        FluentPersona(
          status: FluentPresenceStatus.available,
          size: FluentPersonaSize.large,
          name: 'Kevin Sturgis',
          color: FluentAvatarColor.lavender,
          secondary: Text('Available'),
        ),
      ],
    ),
    Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: <Widget>[
        FluentPersona(
          status: FluentPresenceStatus.available,
          size: FluentPersonaSize.extraLarge,
          name: 'Kevin Sturgis',
          color: FluentAvatarColor.lavender,
          secondary: Text('Available'),
        ),
        FluentPersona(
          status: FluentPresenceStatus.available,
          size: FluentPersonaSize.huge,
          name: 'Kevin Sturgis',
          color: FluentAvatarColor.lavender,
          secondary: Text('Available'),
        ),
      ],
    ),
  ],
);
// #enddocregion components-persona--avatar-size
