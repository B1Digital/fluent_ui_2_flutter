import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The PresenceBadge docs page.
///
/// Sections, titles and descriptions are upstream's, verbatim. Each section's
/// demo is delimited by a `#docregion` whose id is the section id, so the
/// "Show code" panel can read this file back and print exactly the code that
/// rendered.
const DocsPage presenceBadgePage = DocsPage(
  id: 'components-badge-presencebadge',
  folder: 'Badge',
  title: 'PresenceBadge',
  description:
      'A presence badge is a badge that displays a status indicator such as '
      'available, away, or busy.',
  source: 'lib/pages/components_badge_presencebadge.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-badge-presencebadge--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-badge-presencebadge--sizes',
      title: 'Sizes',
      description:
          'A presence badge supports tiny, extra-small, small, medium, and '
          'extra-large sizes. The default is medium.',
      builder: _sizes,
    ),
    DocsSection(
      id: 'components-badge-presencebadge--status',
      title: 'Status',
      description:
          'A presence badge supports available, away, busy, do-not-disturb, '
          'offline, out-of-office, blocked and unknown status. The default is '
          'available.',
      builder: _status,
    ),
    DocsSection(
      id: 'components-badge-presencebadge--out-of-office',
      title: 'Out Of Office',
      description:
          'A presence badge supports available, away, busy, do-not-disturb, '
          'offline, out-of-office, blocked and unknown status when outOfOffice '
          'is set.',
      builder: _outOfOffice,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'status',
      type: 'FluentPresenceStatus',
      description: 'The availability being shown.',
    ),
    PropRow(
      name: 'outOfOffice',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether the person is out of office. Changes the glyph, and for '
          'away the colour too.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentPresenceBadgeSize',
      defaultValue: 'FluentPresenceBadgeSize.medium',
      description: 'Badge diameter.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentPresenceBadgeStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description:
          'Announced by assistive technology. Defaults to an English name for '
          'the status.',
    ),
  ],
);

// #docregion components-badge-presencebadge--default
// `status` is required here where React defaults it, so the default story
// spells out the status React would have picked.
Widget _default(BuildContext context) =>
    const FluentPresenceBadge(status: FluentPresenceStatus.available);
// #enddocregion components-badge-presencebadge--default

// #docregion components-badge-presencebadge--sizes
Widget _sizes(BuildContext context) => const Wrap(
  spacing: 8,
  runSpacing: 8,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    FluentPresenceBadge(
      status: FluentPresenceStatus.available,
      size: FluentPresenceBadgeSize.tiny,
    ),
    FluentPresenceBadge(
      status: FluentPresenceStatus.available,
      size: FluentPresenceBadgeSize.extraSmall,
    ),
    FluentPresenceBadge(
      status: FluentPresenceStatus.available,
      size: FluentPresenceBadgeSize.small,
    ),
    FluentPresenceBadge(
      status: FluentPresenceStatus.available,
      size: FluentPresenceBadgeSize.medium,
    ),
    FluentPresenceBadge(
      status: FluentPresenceStatus.available,
      size: FluentPresenceBadgeSize.large,
    ),
    FluentPresenceBadge(
      status: FluentPresenceStatus.available,
      size: FluentPresenceBadgeSize.extraLarge,
    ),
  ],
);
// #enddocregion components-badge-presencebadge--sizes

// #docregion components-badge-presencebadge--status
Widget _status(BuildContext context) => const Wrap(
  spacing: 8,
  runSpacing: 8,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    FluentPresenceBadge(status: FluentPresenceStatus.available),
    FluentPresenceBadge(status: FluentPresenceStatus.away),
    FluentPresenceBadge(status: FluentPresenceStatus.busy),
    FluentPresenceBadge(status: FluentPresenceStatus.doNotDisturb),
    FluentPresenceBadge(status: FluentPresenceStatus.offline),
    FluentPresenceBadge(status: FluentPresenceStatus.outOfOffice),
    FluentPresenceBadge(status: FluentPresenceStatus.blocked),
    FluentPresenceBadge(status: FluentPresenceStatus.unknown),
  ],
);
// #enddocregion components-badge-presencebadge--status

// #docregion components-badge-presencebadge--out-of-office
Widget _outOfOffice(BuildContext context) => const Wrap(
  spacing: 8,
  runSpacing: 8,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    FluentPresenceBadge(
      status: FluentPresenceStatus.available,
      outOfOffice: true,
    ),
    FluentPresenceBadge(status: FluentPresenceStatus.away, outOfOffice: true),
    FluentPresenceBadge(status: FluentPresenceStatus.busy, outOfOffice: true),
    FluentPresenceBadge(
      status: FluentPresenceStatus.doNotDisturb,
      outOfOffice: true,
    ),
    FluentPresenceBadge(
      status: FluentPresenceStatus.offline,
      outOfOffice: true,
    ),
    FluentPresenceBadge(
      status: FluentPresenceStatus.outOfOffice,
      outOfOffice: true,
    ),
    FluentPresenceBadge(
      status: FluentPresenceStatus.blocked,
      outOfOffice: true,
    ),
    FluentPresenceBadge(
      status: FluentPresenceStatus.unknown,
      outOfOffice: true,
    ),
  ],
);
// #enddocregion components-badge-presencebadge--out-of-office
