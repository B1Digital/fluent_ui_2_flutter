import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The CounterBadge docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
///
/// fluent_2 ships no counter badge widget, because Fluent's Figma Badge set
/// has no `count`, `dot` or `overflowCount` property and no Shape axis at all.
/// Every demo here is a `FluentBadge` whose label is the count and whose corner
/// radius comes from the style slot.
const DocsPage counterBadgePage = DocsPage(
  id: 'components-badge-counter-badge',
  folder: 'Badge',
  title: 'Counter Badge',
  description: 'A counter badge is a badge that displays a numerical count.',
  source: 'lib/pages/components_badge_counter_badge.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-badge-counter-badge--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-badge-counter-badge--appearance',
      title: 'Appearance',
      description:
          'A counter badge can have a ghost or filled appearance. The default '
          'is filled.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-badge-counter-badge--shapes',
      title: 'Shapes',
      description:
          'A counter badge can have a rounded or circular shape. The default '
          'is circular.',
      builder: _shapes,
    ),
    DocsSection(
      id: 'components-badge-counter-badge--sizes',
      title: 'Sizes',
      description:
          'A counter badge supports tiny, extra-small, small, medium, large, '
          'and extra-large sizes. The default is medium.',
      builder: _sizes,
    ),
    DocsSection(
      id: 'components-badge-counter-badge--color',
      title: 'Color',
      description:
          'A counter badge can be different colors. The available colors are '
          'brand, danger, important, informative, severe, severe, success or '
          'warning. The default is brand. Information conveyed by color should '
          'also be communicated in another way to meet accessibility '
          'requirements.',
      builder: _color,
    ),
    DocsSection(
      id: 'components-badge-counter-badge--dot',
      title: 'Dot',
      description: 'A counter badge can display a small dot.',
      builder: _dot,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'child',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'The label. Null for an icon-only or empty badge.',
    ),
    PropRow(
      name: 'icon',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'Optional leading or trailing icon.',
    ),
    PropRow(
      name: 'color',
      type: 'FluentBadgeColor',
      defaultValue: 'FluentBadgeColor.brand',
      description: 'Semantic colour family.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentBadgeSize',
      defaultValue: 'FluentBadgeSize.medium',
      description: 'Height and type ramp.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentBadgeAppearance',
      defaultValue: 'FluentBadgeAppearance.filled',
      description: 'Fill and outline treatment.',
    ),
    PropRow(
      name: 'iconPosition',
      type: 'FluentBadgeIconPosition',
      defaultValue: 'FluentBadgeIconPosition.before',
      description: 'Which side of the label the icon sits on.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentBadgeStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description: 'Announced by assistive technology.',
    ),
  ],
);

// #docregion components-badge-counter-badge--default
// A counter badge is a FluentBadge whose label is the count. FluentBadge has no
// Shape axis — Fluent's Figma Badge set binds one 4px radius to every size — so
// the circular shape a counter badge defaults to comes from the style slot.
Widget _default(BuildContext context) => FluentBadge(
  style: FluentBadgeStyle.from(borderRadius: FluentRadius.allCircular),
  child: const Text('5'),
);
// #enddocregion components-badge-counter-badge--default

// #docregion components-badge-counter-badge--appearance
// Upstream's `ghost` appearance is Figma's `Appearance=Subtle`, which is what
// FluentBadgeAppearance.subtle carries.
Widget _appearance(BuildContext context) {
  final FluentBadgeStyle circular = FluentBadgeStyle.from(
    borderRadius: FluentRadius.allCircular,
  );
  return Wrap(
    spacing: 10,
    runSpacing: 10,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: <Widget>[
      FluentBadge(
        appearance: FluentBadgeAppearance.filled,
        style: circular,
        child: const Text('5'),
      ),
      FluentBadge(
        appearance: FluentBadgeAppearance.subtle,
        style: circular,
        child: const Text('5'),
      ),
    ],
  );
}
// #enddocregion components-badge-counter-badge--appearance

// #docregion components-badge-counter-badge--shapes
// FluentBadge has no Shape axis: Figma binds the same 4px radius to every size,
// which is upstream's `rounded`. `circular` comes from the style slot.
Widget _shapes(BuildContext context) => Wrap(
  spacing: 10,
  runSpacing: 10,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    FluentBadge(
      style: FluentBadgeStyle.from(borderRadius: FluentRadius.allCircular),
      child: const Text('5'),
    ),
    const FluentBadge(child: Text('5')),
  ],
);
// #enddocregion components-badge-counter-badge--shapes

// #docregion components-badge-counter-badge--sizes
// FluentBadgeSize ramps small, medium, large, extraLarge. Fluent's Figma Badge
// set has no tiny or extra-small stop, so upstream's first two sizes have no
// token-backed equivalent here and are left out rather than invented.
Widget _sizes(BuildContext context) {
  final FluentBadgeStyle circular = FluentBadgeStyle.from(
    borderRadius: FluentRadius.allCircular,
  );
  return Wrap(
    spacing: 10,
    runSpacing: 10,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: <Widget>[
      FluentBadge(
        size: FluentBadgeSize.small,
        style: circular,
        child: const Text('5'),
      ),
      FluentBadge(
        size: FluentBadgeSize.medium,
        style: circular,
        child: const Text('5'),
      ),
      FluentBadge(
        size: FluentBadgeSize.large,
        style: circular,
        child: const Text('5'),
      ),
      FluentBadge(
        size: FluentBadgeSize.extraLarge,
        style: circular,
        child: const Text('5'),
      ),
    ],
  );
}
// #enddocregion components-badge-counter-badge--sizes

// #docregion components-badge-counter-badge--color
Widget _color(BuildContext context) {
  final FluentBadgeStyle circular = FluentBadgeStyle.from(
    borderRadius: FluentRadius.allCircular,
  );
  return Wrap(
    spacing: 10,
    runSpacing: 10,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: <Widget>[
      FluentBadge(
        appearance: FluentBadgeAppearance.filled,
        color: FluentBadgeColor.brand,
        style: circular,
        child: const Text('5'),
      ),
      FluentBadge(
        appearance: FluentBadgeAppearance.filled,
        color: FluentBadgeColor.danger,
        style: circular,
        child: const Text('5'),
      ),
      FluentBadge(
        appearance: FluentBadgeAppearance.filled,
        color: FluentBadgeColor.important,
        style: circular,
        child: const Text('5'),
      ),
      FluentBadge(
        appearance: FluentBadgeAppearance.filled,
        color: FluentBadgeColor.informative,
        style: circular,
        child: const Text('5'),
      ),
    ],
  );
}
// #enddocregion components-badge-counter-badge--color

// #docregion components-badge-counter-badge--dot
// A FluentBadge with no label and no icon is already a bare dot; it just sizes
// itself to the badge height, so the style slot shrinks it to the 6px upstream
// draws and drops the padding that would otherwise stretch it into an ellipse.
Widget _dot(BuildContext context) => FluentBadge(
  semanticLabel: 'Unread',
  style: FluentBadgeStyle.from(
    borderRadius: FluentRadius.allCircular,
    minimumSize: const Size(6, 6),
    padding: EdgeInsets.zero,
  ),
);
// #enddocregion components-badge-counter-badge--dot
