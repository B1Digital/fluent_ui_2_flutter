import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Badge docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage badgePage = DocsPage(
  id: 'components-badge-badge',
  folder: 'Badge',
  title: 'Badge',
  description:
      'A badge is a visual decoration for UI elements. Different badges can '
      'display different content. Badge displays text and/or an icon. '
      'CounterBadge displays numerical values. PresenceBadge displays status.',
  source: 'lib/pages/components_badge_badge.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-badge-badge--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-badge-badge--appearance',
      title: 'Appearance',
      description:
          'A badge can have a filled, ghost, outline, or tint appearance. The '
          'default is filled.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-badge-badge--sizes',
      title: 'Sizes',
      description:
          'A badge supports tiny, extra-small, small, medium, large, and '
          'extra-large sizes. The default is medium.',
      builder: _sizes,
    ),
    DocsSection(
      id: 'components-badge-badge--shapes',
      title: 'Shapes',
      description:
          'A badge can have square, rounded or circular shape. The default is '
          'circular.',
      builder: _shapes,
    ),
    DocsSection(
      id: 'components-badge-badge--color',
      title: 'Color',
      description:
          'A badge can have different colors. The available colors are brand, '
          'danger, important, informative, severe, subtle, success or warning. '
          'The default is brand. Information conveyed by color should also be '
          'communicated in another way to meet accessibility requirements.',
      builder: _color,
    ),
    DocsSection(
      id: 'components-badge-badge--icon',
      title: 'Icon',
      description:
          'A badge can display an icon. If the icon is meaningful, then either '
          "the icon must have a label or the parent control's label must "
          'include the information conveyed by the icon.',
      builder: _icon,
    ),
    DocsSection(
      id: 'components-badge-badge--color-and-appearance',
      title: 'Color And Appearance',
      description:
          'Note: ghost-subtle and outline-subtle are intended only for use on '
          'brand background.',
      builder: _colorAndAppearance,
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

// #docregion components-badge-badge--default
Widget _default(BuildContext context) => const FluentBadge();
// #enddocregion components-badge-badge--default

// #docregion components-badge-badge--appearance
// Upstream's `ghost` appearance is our `FluentBadgeAppearance.subtle` — Figma
// names the no-fill, no-border variant `Subtle`, and React renamed it.
Widget _appearance(BuildContext context) => const Wrap(
  spacing: 8,
  runSpacing: 8,
  children: <Widget>[
    FluentBadge(child: Text('999+')),
    FluentBadge(appearance: FluentBadgeAppearance.subtle, child: Text('999+')),
    FluentBadge(appearance: FluentBadgeAppearance.outline, child: Text('999+')),
    FluentBadge(appearance: FluentBadgeAppearance.tint, child: Text('999+')),
  ],
);
// #enddocregion components-badge-badge--appearance

// #docregion components-badge-badge--sizes
// Fluent's Figma Badge set has four sizes, not six: upstream's `tiny` and
// `extra-small` are CounterBadge-only stops that `FluentBadgeSize` does not
// carry, so the four real ones render here.
Widget _sizes(BuildContext context) => const Wrap(
  spacing: 8,
  runSpacing: 8,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    FluentBadge(size: FluentBadgeSize.small),
    FluentBadge(),
    FluentBadge(size: FluentBadgeSize.large),
    FluentBadge(size: FluentBadgeSize.extraLarge),
  ],
);
// #enddocregion components-badge-badge--sizes

// #docregion components-badge-badge--shapes
// `FluentBadge` has no shape axis — the Figma Badge set binds one 4px radius to
// every size — so the three upstream shapes are expressed as the radius each
// one actually is, through the public `style` hook.
Widget _shapes(BuildContext context) => const Wrap(
  spacing: 8,
  runSpacing: 8,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    FluentBadge(
      style: FluentBadgeStyle(
        borderRadius: WidgetStatePropertyAll<BorderRadius?>(BorderRadius.zero),
      ),
    ),
    FluentBadge(
      style: FluentBadgeStyle(
        borderRadius: WidgetStatePropertyAll<BorderRadius?>(
          FluentRadius.allMedium,
        ),
      ),
    ),
    FluentBadge(
      style: FluentBadgeStyle(
        borderRadius: WidgetStatePropertyAll<BorderRadius?>(
          FluentRadius.allCircular,
        ),
      ),
    ),
  ],
);
// #enddocregion components-badge-badge--shapes

// #docregion components-badge-badge--color
// Upstream lists eight colours; `FluentBadgeColor` has seven. Fluent ships no
// `Status/Severe/*` ramp, so there is no `severe` badge to render.
Widget _color(BuildContext context) => const Wrap(
  spacing: 8,
  runSpacing: 8,
  children: <Widget>[
    FluentBadge(child: Text('999+')),
    FluentBadge(color: FluentBadgeColor.danger, child: Text('999+')),
    FluentBadge(color: FluentBadgeColor.important, child: Text('999+')),
    FluentBadge(color: FluentBadgeColor.informative, child: Text('999+')),
    FluentBadge(color: FluentBadgeColor.subtle, child: Text('999+')),
    FluentBadge(color: FluentBadgeColor.success, child: Text('999+')),
    FluentBadge(color: FluentBadgeColor.warning, child: Text('999+')),
  ],
);
// #enddocregion components-badge-badge--color

// #docregion components-badge-badge--icon
Widget _icon(BuildContext context) =>
    const FluentBadge(icon: Icon(FluentIcons.clipboard_paste_20_regular));
// #enddocregion components-badge-badge--icon

// #docregion components-badge-badge--color-and-appearance
// Same two departures as the Color and Appearance sections above: no `severe`
// colour exists, and upstream's `ghost` is `FluentBadgeAppearance.subtle`.
Widget _colorAndAppearance(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  spacing: 8,
  children: const <Widget>[
    _Heading('Filled'),
    _Badges(appearance: FluentBadgeAppearance.filled),
    _Heading('Ghost'),
    _Badges(appearance: FluentBadgeAppearance.subtle),
    _Heading('Outline'),
    _Badges(appearance: FluentBadgeAppearance.outline),
    _Heading('Tint'),
    _Badges(appearance: FluentBadgeAppearance.tint),
  ],
);

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: FluentTheme.of(context).typography.subtitle2);
}

class _Badges extends StatelessWidget {
  const _Badges({required this.appearance});

  final FluentBadgeAppearance appearance;

  static const List<FluentBadgeColor> _colors = <FluentBadgeColor>[
    FluentBadgeColor.brand,
    FluentBadgeColor.danger,
    FluentBadgeColor.important,
    FluentBadgeColor.informative,
    FluentBadgeColor.subtle,
    FluentBadgeColor.success,
    FluentBadgeColor.warning,
  ];

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: <Widget>[
      for (final FluentBadgeColor color in _colors)
        // The subtle colour is drawn for a brand surface, so on ghost and
        // outline it is shown on one — otherwise it is white on white.
        if (color == FluentBadgeColor.subtle &&
            (appearance == FluentBadgeAppearance.subtle ||
                appearance == FluentBadgeAppearance.outline))
          ColoredBox(
            color: FluentTheme.of(context).colors.brandBackground,
            child: Padding(
              padding: const EdgeInsets.all(FluentSpacing.xxs),
              child: FluentBadge(
                appearance: appearance,
                color: color,
                icon: const Icon(FluentIcons.clipboard_paste_20_regular),
                child: const Text('999+'),
              ),
            ),
          )
        else
          FluentBadge(
            appearance: appearance,
            color: color,
            icon: const Icon(FluentIcons.clipboard_paste_20_regular),
            child: const Text('999+'),
          ),
    ],
  );
}

// #enddocregion components-badge-badge--color-and-appearance
