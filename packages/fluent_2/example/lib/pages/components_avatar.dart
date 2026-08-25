import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Avatar docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage avatarPage = DocsPage(
  id: 'components-avatar',
  title: 'Avatar',
  description:
      'An Avatar is a graphical representation of a user, team, or entity. '
      'Avatar can display an image, icon, or initials, and supports various '
      'sizes and shapes.',
  source: 'lib/pages/components_avatar.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-avatar--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-avatar--name',
      title: 'Name',
      description:
          'The name is used to determine the initials displayed by the Avatar. '
          'It is also read by screen readers.',
      builder: _name,
    ),
    DocsSection(
      id: 'components-avatar--image',
      title: 'Image',
      description:
          'An avatar can display an image. It is recommended to also include a '
          'name in addition to the image: the initials from the name are '
          'displayed while the image is loading, and the name makes the Avatar '
          'accessible to screen readers.',
      builder: _image,
    ),
    DocsSection(
      id: 'components-avatar--icon',
      title: 'Icon',
      description:
          'An avatar can display an icon. The icon will only be shown when '
          'there is no image or initials available.',
      builder: _icon,
    ),
    DocsSection(
      id: 'components-avatar--badge',
      title: 'Badge',
      description:
          'An avatar can have a badge to indicate presence status. See the '
          'PresenceBadge component for more info.',
      builder: _badge,
    ),
    DocsSection(
      id: 'components-avatar--badge-icon',
      title: 'Badge Icon',
      description: 'An Avatar can have a custom icon inside the badge.',
      builder: _badgeIcon,
    ),
    DocsSection(
      id: 'components-avatar--square',
      title: 'Shape: square',
      description: 'An avatar can have a square shape.',
      builder: _square,
    ),
    DocsSection(
      id: 'components-avatar--color-brand',
      title: 'Color: brand',
      description:
          "An avatar can use the brand color from the theme's palette.",
      builder: _colorBrand,
    ),
    DocsSection(
      id: 'components-avatar--color-colorful',
      title: 'Color: colorful',
      description:
          'An avatar can have the color be automatically picked based on the '
          'name prop (or idForColor can be used if a name is not available).',
      builder: _colorColorful,
    ),
    DocsSection(
      id: 'components-avatar--color-palette',
      title: 'Color: named color',
      description:
          "An avatar can have a specific named color from the theme's color "
          'palette (e.g. seafoam, grape, or pumpkin)',
      builder: _colorPalette,
    ),
    DocsSection(
      id: 'components-avatar--active',
      title: 'Active',
      description:
          'An avatar can communicate whether a user is currently active (for '
          'example, speaking or typing). Avatar supports active, inactive, and '
          'unset. The default is unset.',
      builder: _active,
    ),
    DocsSection(
      id: 'components-avatar--active-appearance',
      title: 'Active Appearance',
      description:
          'An avatar can have different appearances when active="active". '
          'Avatar supports ring, shadow, and ring-shadow. The default is ring.',
      builder: _activeAppearance,
    ),
    DocsSection(
      id: 'components-avatar--initials',
      title: 'Initials: Custom Initials',
      description:
          'An avatar can display custom initials by setting the initials prop. '
          'It is generally recommended to use the name prop instead, as that '
          'will automatically determine the initials and display them.',
      builder: _initials,
    ),
    DocsSection(
      id: 'components-avatar--size',
      title: 'Size',
      description:
          'An avatar supports a range of sizes from 16 to 128. The default is '
          '32. Avoid using sizes 16 and 20 for interactive Avatars, or ensure '
          'that there is at least 8px or 4px spacing respectively to meet WCAG '
          'target size requirements.',
      builder: _size,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'image',
      type: 'ImageProvider<Object>?',
      defaultValue: 'null',
      description:
          "The photo, drawn cover-fit and clipped to the avatar's radius.",
    ),
    PropRow(
      name: 'initials',
      type: 'String?',
      defaultValue: 'null',
      description: 'One to three letters, drawn when there is no image.',
    ),
    PropRow(
      name: 'icon',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'Replaces the default person glyph. Sized and tinted by the style.',
    ),
    PropRow(
      name: 'name',
      type: 'String?',
      defaultValue: 'null',
      description: "The person's name, announced by assistive technology.",
    ),
    PropRow(
      name: 'color',
      type: 'FluentAvatarColor',
      defaultValue: 'FluentAvatarColor.neutral',
      description: 'Which Avatar color mode to paint in.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentAvatarSize',
      defaultValue: 'FluentAvatarSize.size32',
      description: 'Edge length.',
    ),
    PropRow(
      name: 'shape',
      type: 'FluentAvatarShape',
      defaultValue: 'FluentAvatarShape.circular',
      description: 'Corner treatment.',
    ),
    PropRow(
      name: 'active',
      type: 'FluentAvatarActive',
      defaultValue: 'FluentAvatarActive.unset',
      description: 'Whether the activity ring is drawn, and how.',
    ),
    PropRow(
      name: 'status',
      type: 'FluentPresenceStatus?',
      defaultValue: 'null',
      description:
          'Shows a FluentPresenceBadge in the bottom-right corner, sized from '
          'the avatar.',
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
      type: 'FluentAvatarStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
  ],
);

// #docregion components-avatar--default
Widget _default(BuildContext context) => const FluentAvatar(name: 'Guest');
// #enddocregion components-avatar--default

// #docregion components-avatar--name
// `FluentAvatar` does not derive initials from `name`: upstream's `getInitials`
// is a locale-sensitive parser, so the example passes them explicitly.
Widget _name(BuildContext context) =>
    const FluentAvatar(name: 'Ashley McCarthy', initials: 'AM');
// #enddocregion components-avatar--name

// #docregion components-avatar--image
Widget _image(BuildContext context) => const FluentAvatar(
  name: 'Katri Athokas',
  image: AssetImage('assets/storybook/KatriAthokas.jpg'),
);
// #enddocregion components-avatar--image

// #docregion components-avatar--icon
Widget _icon(BuildContext context) => const Wrap(
  spacing: 8,
  runSpacing: 8,
  children: <Widget>[
    FluentAvatar(icon: Icon(FluentIcons.guest_20_regular), name: 'Guest'),
    FluentAvatar(icon: Icon(FluentIcons.people_20_regular), name: 'Group'),
    FluentAvatar(
      icon: Icon(FluentIcons.people_team_20_regular),
      shape: FluentAvatarShape.square,
      name: 'Team',
    ),
    FluentAvatar(
      icon: Icon(FluentIcons.person_call_20_regular),
      name: 'Phone Contact',
    ),
    FluentAvatar(
      icon: Icon(FluentIcons.calendar_ltr_20_regular),
      name: 'Meeting',
    ),
    FluentAvatar(
      icon: Icon(FluentIcons.briefcase_20_regular),
      shape: FluentAvatarShape.square,
      name: 'Tenant',
    ),
    FluentAvatar(
      icon: Icon(FluentIcons.conference_room_20_regular),
      shape: FluentAvatarShape.square,
      name: 'Room',
    ),
  ],
);
// #enddocregion components-avatar--icon

// #docregion components-avatar--badge
// Initials are passed explicitly: `FluentAvatar` does not parse them out of
// `name` the way upstream's `getInitials` does.
Widget _badge(BuildContext context) => const Wrap(
  spacing: 8,
  runSpacing: 8,
  children: <Widget>[
    FluentAvatar(
      name: 'Lydia Bauer',
      initials: 'LB',
      status: FluentPresenceStatus.available,
    ),
    FluentAvatar(
      name: 'Amanda Brady',
      initials: 'AB',
      status: FluentPresenceStatus.busy,
    ),
    FluentAvatar(
      name: 'Henry Brill',
      initials: 'HB',
      status: FluentPresenceStatus.outOfOffice,
    ),
    FluentAvatar(
      name: 'Robin Counts',
      initials: 'RC',
      status: FluentPresenceStatus.away,
    ),
    FluentAvatar(
      name: 'Tim Deboer',
      initials: 'TD',
      status: FluentPresenceStatus.offline,
    ),
    FluentAvatar(
      name: 'Cameron Evans',
      initials: 'CE',
      status: FluentPresenceStatus.doNotDisturb,
    ),
    FluentAvatar(
      name: 'Wanda Howard',
      initials: 'WH',
      status: FluentPresenceStatus.blocked,
    ),
    FluentAvatar(
      name: 'Mona Kane',
      initials: 'MK',
      status: FluentPresenceStatus.available,
      outOfOffice: true,
    ),
    FluentAvatar(
      name: 'Allan Munger',
      initials: 'AM',
      status: FluentPresenceStatus.busy,
      outOfOffice: true,
    ),
    FluentAvatar(
      name: 'Erik Nason',
      initials: 'EN',
      status: FluentPresenceStatus.outOfOffice,
      outOfOffice: true,
    ),
    FluentAvatar(
      name: 'Daisy Phillips',
      initials: 'DP',
      status: FluentPresenceStatus.away,
      outOfOffice: true,
    ),
    FluentAvatar(
      name: 'Kevin Sturgis',
      initials: 'KS',
      status: FluentPresenceStatus.offline,
      outOfOffice: true,
    ),
    FluentAvatar(
      name: 'Elliot Woodward',
      initials: 'EW',
      status: FluentPresenceStatus.doNotDisturb,
      outOfOffice: true,
    ),
    FluentAvatar(
      name: 'Wanda Howard',
      initials: 'WH',
      status: FluentPresenceStatus.blocked,
      outOfOffice: true,
    ),
  ],
);
// #enddocregion components-avatar--badge

// #docregion components-avatar--badge-icon
// `FluentAvatar.status` builds a `FluentPresenceBadge`, which is presence only
// and takes no icon. A custom badge is composed instead: the avatar with a
// `FluentBadge` anchored to its bottom-right corner, as upstream's badge slot
// also renders a Badge.
Widget _badgeIcon(BuildContext context) => Stack(
  clipBehavior: Clip.none,
  children: const <Widget>[
    FluentAvatar(name: 'John Doe', initials: 'JD'),
    Positioned(
      right: -2,
      bottom: -2,
      child: FluentBadge(
        size: FluentBadgeSize.small,
        color: FluentBadgeColor.success,
        icon: Icon(FluentIcons.calendar_month_20_regular),
      ),
    ),
  ],
);
// #enddocregion components-avatar--badge-icon

// #docregion components-avatar--square
Widget _square(BuildContext context) => const FluentAvatar(
  shape: FluentAvatarShape.square,
  name: 'square avatar',
  icon: Icon(FluentIcons.people_team_20_regular),
);
// #enddocregion components-avatar--square

// #docregion components-avatar--color-brand
Widget _colorBrand(BuildContext context) => const FluentAvatar(
  color: FluentAvatarColor.brand,
  initials: 'BR',
  name: 'brand color avatar',
);
// #enddocregion components-avatar--color-brand

// #docregion components-avatar--color-colorful
// `FluentAvatarColor` has no `colorful` mode — our avatar always takes a
// concrete colour — so the hash upstream applies to `name` (or `idForColor`)
// lives in the example instead. Same idea, a different hash, so the individual
// picks differ from upstream's.
const List<FluentAvatarColor> _colorfulColors = <FluentAvatarColor>[
  FluentAvatarColor.darkRed,
  FluentAvatarColor.cranberry,
  FluentAvatarColor.red,
  FluentAvatarColor.pumpkin,
  FluentAvatarColor.peach,
  FluentAvatarColor.marigold,
  FluentAvatarColor.gold,
  FluentAvatarColor.brass,
  FluentAvatarColor.brown,
  FluentAvatarColor.forest,
  FluentAvatarColor.seafoam,
  FluentAvatarColor.darkGreen,
  FluentAvatarColor.lightTeal,
  FluentAvatarColor.teal,
  FluentAvatarColor.steel,
  FluentAvatarColor.blue,
  FluentAvatarColor.royalBlue,
  FluentAvatarColor.cornflower,
  FluentAvatarColor.navy,
  FluentAvatarColor.lavender,
  FluentAvatarColor.purple,
  FluentAvatarColor.grape,
  FluentAvatarColor.lilac,
  FluentAvatarColor.pink,
  FluentAvatarColor.magenta,
  FluentAvatarColor.plum,
];

FluentAvatarColor _colorful(String idForColor) {
  int hash = 0;
  for (final int unit in idForColor.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return _colorfulColors[hash % _colorfulColors.length];
}

Widget _colorColorful(BuildContext context) => Wrap(
  spacing: 8,
  runSpacing: 8,
  children: <Widget>[
    FluentAvatar(
      color: _colorful('Katri Athokas'),
      name: 'Katri Athokas',
      initials: 'KA',
    ),
    FluentAvatar(
      color: _colorful('Elvia Atkins'),
      name: 'Elvia Atkins',
      initials: 'EA',
    ),
    FluentAvatar(
      color: _colorful('Cameron Evans'),
      name: 'Cameron Evans',
      initials: 'CE',
    ),
    FluentAvatar(
      color: _colorful('Wanda Howard'),
      name: 'Wanda Howard',
      initials: 'WH',
    ),
    FluentAvatar(
      color: _colorful('Mona Kane'),
      name: 'Mona Kane',
      initials: 'MK',
    ),
    FluentAvatar(
      color: _colorful('Allan Munger'),
      name: 'Allan Munger',
      initials: 'AM',
    ),
    FluentAvatar(
      color: _colorful('Daisy Phillips'),
      name: 'Daisy Phillips',
      initials: 'DP',
    ),
    FluentAvatar(
      color: _colorful('Robert Tolbert'),
      name: 'Robert Tolbert',
      initials: 'RT',
    ),
    FluentAvatar(
      color: _colorful('Kevin Sturgis'),
      name: 'Kevin Sturgis',
      initials: 'KS',
    ),
    FluentAvatar(
      color: _colorful('Elliot Woodward'),
      name: 'Elliot Woodward',
      initials: 'EW',
    ),
    FluentAvatar(
      color: _colorful('id-123'),
      icon: const Icon(FluentIcons.guest_20_regular),
      name: 'Guest',
    ),
    FluentAvatar(
      color: _colorful('42'),
      icon: const Icon(FluentIcons.guest_20_regular),
      name: 'Guest',
    ),
    FluentAvatar(
      color: _colorful('93'),
      icon: const Icon(FluentIcons.guest_20_regular),
      name: 'Guest',
    ),
    FluentAvatar(
      color: _colorful('Guest-23'),
      icon: const Icon(FluentIcons.guest_20_regular),
      name: 'Guest',
    ),
  ],
);
// #enddocregion components-avatar--color-colorful

// #docregion components-avatar--color-palette
Widget _colorPalette(BuildContext context) => const Wrap(
  spacing: 8,
  runSpacing: 8,
  children: <Widget>[
    FluentAvatar(
      initials: 'DR',
      color: FluentAvatarColor.darkRed,
      name: 'darkRed avatar',
    ),
    FluentAvatar(
      initials: 'CR',
      color: FluentAvatarColor.cranberry,
      name: 'cranberry avatar',
    ),
    FluentAvatar(
      initials: 'RE',
      color: FluentAvatarColor.red,
      name: 'red avatar',
    ),
    FluentAvatar(
      initials: 'PU',
      color: FluentAvatarColor.pumpkin,
      name: 'pumpkin avatar',
    ),
    FluentAvatar(
      initials: 'PE',
      color: FluentAvatarColor.peach,
      name: 'peach avatar',
    ),
    FluentAvatar(
      initials: 'MA',
      color: FluentAvatarColor.marigold,
      name: 'marigold avatar',
    ),
    FluentAvatar(
      initials: 'GO',
      color: FluentAvatarColor.gold,
      name: 'gold avatar',
    ),
    FluentAvatar(
      initials: 'BS',
      color: FluentAvatarColor.brass,
      name: 'brass avatar',
    ),
    FluentAvatar(
      initials: 'BR',
      color: FluentAvatarColor.brown,
      name: 'brown avatar',
    ),
    FluentAvatar(
      initials: 'FO',
      color: FluentAvatarColor.forest,
      name: 'forest avatar',
    ),
    FluentAvatar(
      initials: 'SE',
      color: FluentAvatarColor.seafoam,
      name: 'seafoam avatar',
    ),
    FluentAvatar(
      initials: 'DG',
      color: FluentAvatarColor.darkGreen,
      name: 'darkGreen avatar',
    ),
    FluentAvatar(
      initials: 'LT',
      color: FluentAvatarColor.lightTeal,
      name: 'lightTeal avatar',
    ),
    FluentAvatar(
      initials: 'TE',
      color: FluentAvatarColor.teal,
      name: 'teal avatar',
    ),
    FluentAvatar(
      initials: 'ST',
      color: FluentAvatarColor.steel,
      name: 'steel avatar',
    ),
    FluentAvatar(
      initials: 'BL',
      color: FluentAvatarColor.blue,
      name: 'blue avatar',
    ),
    FluentAvatar(
      initials: 'RB',
      color: FluentAvatarColor.royalBlue,
      name: 'royalBlue avatar',
    ),
    FluentAvatar(
      initials: 'CO',
      color: FluentAvatarColor.cornflower,
      name: 'cornflower avatar',
    ),
    FluentAvatar(
      initials: 'NA',
      color: FluentAvatarColor.navy,
      name: 'navy avatar',
    ),
    FluentAvatar(
      initials: 'LA',
      color: FluentAvatarColor.lavender,
      name: 'lavender avatar',
    ),
    FluentAvatar(
      initials: 'PU',
      color: FluentAvatarColor.purple,
      name: 'purple avatar',
    ),
    FluentAvatar(
      initials: 'GR',
      color: FluentAvatarColor.grape,
      name: 'grape avatar',
    ),
    FluentAvatar(
      initials: 'LI',
      color: FluentAvatarColor.lilac,
      name: 'lilac avatar',
    ),
    FluentAvatar(
      initials: 'PI',
      color: FluentAvatarColor.pink,
      name: 'pink avatar',
    ),
    FluentAvatar(
      initials: 'MA',
      color: FluentAvatarColor.magenta,
      name: 'magenta avatar',
    ),
    FluentAvatar(
      initials: 'PL',
      color: FluentAvatarColor.plum,
      name: 'plum avatar',
    ),
    FluentAvatar(
      initials: 'BE',
      color: FluentAvatarColor.beige,
      name: 'beige avatar',
    ),
    FluentAvatar(
      initials: 'MI',
      color: FluentAvatarColor.mink,
      name: 'mink avatar',
    ),
    FluentAvatar(
      initials: 'PL',
      color: FluentAvatarColor.platinum,
      name: 'platinum avatar',
    ),
    FluentAvatar(
      initials: 'AN',
      color: FluentAvatarColor.anchor,
      name: 'anchor avatar',
    ),
  ],
);
// #enddocregion components-avatar--color-palette

// #docregion components-avatar--active
Widget _active(BuildContext context) => const Wrap(
  spacing: 20,
  runSpacing: 20,
  children: <Widget>[
    FluentAvatar(
      active: FluentAvatarActive.active,
      name: 'Ashley McCarthy',
      initials: 'AM',
    ),
    FluentAvatar(
      active: FluentAvatarActive.inactive,
      name: 'Isaac Fielder',
      initials: 'IF',
      status: FluentPresenceStatus.away,
    ),
  ],
);
// #enddocregion components-avatar--active

// #docregion components-avatar--active-appearance
// `FluentAvatarActive` carries no appearance axis: Figma's avatar set draws the
// ring only, so `shadow` and `ring-shadow` have no token-backed treatment to
// render. All three show the ring, and the labels stay upstream's.
Widget _activeAppearance(BuildContext context) => const Wrap(
  spacing: 20,
  runSpacing: 20,
  children: <Widget>[
    FluentAvatar(
      active: FluentAvatarActive.active,
      name: 'Ring',
      initials: 'R',
    ),
    FluentAvatar(
      active: FluentAvatarActive.active,
      name: 'Shadow',
      initials: 'S',
    ),
    FluentAvatar(
      active: FluentAvatarActive.active,
      name: 'Ring Shadow',
      initials: 'RS',
    ),
  ],
);
// #enddocregion components-avatar--active-appearance

// #docregion components-avatar--initials
Widget _initials(BuildContext context) =>
    const FluentAvatar(name: 'Cecil Robin Folk', initials: 'CRF');
// #enddocregion components-avatar--initials

// #docregion components-avatar--size
// `FluentAvatarSize` stops at 120 — Figma never draws the 128 variant — so the
// last avatar keeps upstream's `128` label at the next supported size.
Widget _size(BuildContext context) => const Wrap(
  spacing: 8,
  runSpacing: 8,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    FluentAvatar(initials: '16', size: FluentAvatarSize.size16),
    FluentAvatar(initials: '20', size: FluentAvatarSize.size20),
    FluentAvatar(initials: '24', size: FluentAvatarSize.size24),
    FluentAvatar(initials: '28', size: FluentAvatarSize.size28),
    FluentAvatar(initials: '32', size: FluentAvatarSize.size32),
    FluentAvatar(initials: '36', size: FluentAvatarSize.size36),
    FluentAvatar(initials: '40', size: FluentAvatarSize.size40),
    FluentAvatar(initials: '48', size: FluentAvatarSize.size48),
    FluentAvatar(initials: '56', size: FluentAvatarSize.size56),
    FluentAvatar(initials: '64', size: FluentAvatarSize.size64),
    FluentAvatar(initials: '72', size: FluentAvatarSize.size72),
    FluentAvatar(initials: '96', size: FluentAvatarSize.size96),
    FluentAvatar(initials: '120', size: FluentAvatarSize.size120),
    FluentAvatar(initials: '128', size: FluentAvatarSize.size120),
  ],
);
// #enddocregion components-avatar--size
