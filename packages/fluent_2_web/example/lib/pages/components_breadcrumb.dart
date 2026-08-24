import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Breadcrumb docs page.
///
/// Sections, titles and sample data are upstream's, verbatim. Each section's
/// demo is delimited by a `#docregion` whose id is the section id, so the
/// "Show code" panel can read this file back and print exactly the code that
/// rendered.
const DocsPage breadcrumbPage = DocsPage(
  id: 'components-breadcrumb',
  title: 'Breadcrumb',
  description:
      'For detailed guidance on when and how to use this component, go to '
      'Fluent 2 Breadcrumbs.',
  source: 'lib/pages/components_breadcrumb.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-breadcrumb--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-breadcrumb--breadcrumb-size',
      title: 'Breadcrumb Size',
      builder: _breadcrumbSize,
    ),
    DocsSection(
      id: 'components-breadcrumb--breadcrumb-with-overflow',
      title: 'Breadcrumb With Overflow',
      builder: _breadcrumbWithOverflow,
    ),
    DocsSection(
      id: 'components-breadcrumb--breadcrumb-with-tooltip',
      title: 'Breadcrumb With Tooltip',
      builder: _breadcrumbWithTooltip,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'items',
      type: 'List<FluentBreadcrumbItem>',
      description: 'The trail, root first. The last entry is the current page.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentBreadcrumbSize',
      defaultValue: 'FluentBreadcrumbSize.medium',
      description: 'Height and type ramp.',
    ),
    PropRow(
      name: 'maxDisplayedItems',
      type: 'int?',
      defaultValue: 'null',
      description:
          'How many crumbs may stay inline before the middle folds into the '
          'overflow popup. Null shows the whole trail.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentBreadcrumbStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description:
          'Announced by assistive technology for the trail as a whole.',
    ),
  ],
);

// #docregion components-breadcrumb--default
// Upstream links every crumb to https://www.bing.com/. A Flutter crumb takes a
// callback rather than an href, and the last crumb is the current page, so it
// is never interactive.
Widget _default(BuildContext context) => FluentBreadcrumb(
  semanticLabel: 'Breadcrumb default example',
  items: <FluentBreadcrumbItem>[
    FluentBreadcrumbItem(label: const Text('Item 1'), onPressed: () {}),
    FluentBreadcrumbItem(
      label: const Text('Item 2'),
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      onPressed: () {},
    ),
    FluentBreadcrumbItem(label: const Text('Item 3'), onPressed: () {}),
    const FluentBreadcrumbItem(label: Text('Item 4')),
  ],
);
// #enddocregion components-breadcrumb--default

// #docregion components-breadcrumb--breadcrumb-size
Widget _breadcrumbSize(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    FluentBreadcrumb(
      semanticLabel: 'Small breadcrumb example with buttons',
      size: FluentBreadcrumbSize.small,
      items: <FluentBreadcrumbItem>[
        FluentBreadcrumbItem(label: const Text('Item 1'), onPressed: () {}),
        FluentBreadcrumbItem(
          label: const Text('Item 2'),
          icon: const Icon(FluentIcons.calendar_month_20_regular),
          onPressed: () {},
        ),
        FluentBreadcrumbItem(label: const Text('Item 3'), onPressed: () {}),
        const FluentBreadcrumbItem(label: Text('Item 4')),
      ],
    ),
    FluentBreadcrumb(
      semanticLabel: 'Medium breadcrumb example with buttons',
      items: <FluentBreadcrumbItem>[
        FluentBreadcrumbItem(label: const Text('Item 1'), onPressed: () {}),
        FluentBreadcrumbItem(
          label: const Text('Item 2'),
          icon: const Icon(FluentIcons.calendar_month_20_regular),
          onPressed: () {},
        ),
        FluentBreadcrumbItem(label: const Text('Item 3'), onPressed: () {}),
        const FluentBreadcrumbItem(label: Text('Item 4')),
      ],
    ),
    FluentBreadcrumb(
      semanticLabel: 'Large breadcrumb example with buttons',
      size: FluentBreadcrumbSize.large,
      items: <FluentBreadcrumbItem>[
        FluentBreadcrumbItem(label: const Text('Item 1'), onPressed: () {}),
        FluentBreadcrumbItem(
          label: const Text('Item 2'),
          icon: const Icon(FluentIcons.calendar_month_20_regular),
          onPressed: () {},
        ),
        FluentBreadcrumbItem(label: const Text('Item 3'), onPressed: () {}),
        const FluentBreadcrumbItem(
          label: Text('Item 4'),
          icon: Icon(FluentIcons.calendar_month_20_regular),
        ),
      ],
    ),
  ],
);
// #enddocregion components-breadcrumb--breadcrumb-size

// #docregion components-breadcrumb--breadcrumb-with-overflow
// `maxDisplayedItems` is our port of upstream's `partitionBreadcrumbItems`:
// the root stays pinned, the tail stays visible and the middle folds behind an
// overflow trigger that opens a popup. Upstream's example box is also
// resize-draggable so the fold can be watched happening; a Flutter box has no
// such browser affordance, so this one is a plain 600 wide.
Widget _breadcrumbWithOverflow(BuildContext context) => SizedBox(
  width: 600,
  child: FluentBreadcrumb(
    maxDisplayedItems: 5,
    items: <FluentBreadcrumbItem>[
      FluentBreadcrumbItem(label: const Text('Item 0'), onPressed: () {}),
      FluentBreadcrumbItem(
        label: const Text('Item 1'),
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        onPressed: () {},
      ),
      FluentBreadcrumbItem(label: const Text('Item 2'), onPressed: () {}),
      FluentBreadcrumbItem(label: const Text('Item 3'), onPressed: () {}),
      FluentBreadcrumbItem(label: const Text('Item 4'), onPressed: () {}),
      FluentBreadcrumbItem(
        label: const Text('Item 5'),
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        enabled: false,
        onPressed: () {},
      ),
      FluentBreadcrumbItem(label: const Text('Item 6'), onPressed: () {}),
      const FluentBreadcrumbItem(label: Text('Item 7')),
    ],
  ),
);
// #enddocregion components-breadcrumb--breadcrumb-with-overflow

// #docregion components-breadcrumb--breadcrumb-with-tooltip
// Upstream pairs `isTruncatableBreadcrumbContent` with
// `truncateBreadcrumbLongName`: a crumb longer than 30 characters is cut at 30
// and wrapped in a tooltip carrying the whole name. Neither helper has a Dart
// port, so this docregion carries both.
const int _truncateBreadcrumbLength = 30;

FluentBreadcrumbItem _tooltipCrumb(String name) =>
    name.length > _truncateBreadcrumbLength
    ? FluentBreadcrumbItem(
        label: FluentTooltip(
          withArrow: true,
          content: Text(name),
          semanticLabel: name,
          child: Text('${name.substring(0, _truncateBreadcrumbLength)}...'),
        ),
        semanticLabel: name,
      )
    : FluentBreadcrumbItem(label: Text(name));

Widget _breadcrumbWithTooltip(BuildContext context) {
  const List<String> items = <String>[
    'Item 1',
    'Item 2',
    'Item 3',
    'Item 4',
    'Item 5',
    'Item 6',
    'Item 7',
    'Item 8',
  ];
  const List<String> itemsWithLongNames = <String>[
    'Item 1',
    'Item 2',
    "Item 3 is long. Don't think about what you want to be, but what you want to do.",
    'Item 4',
    'Item 5 which is longer than 30 characters',
  ];

  final FluentTypography type = FluentTheme.of(context).typography;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text('Breadcrumb with a tooltip', style: type.subtitle2),
      const SizedBox(height: 8),
      // Upstream hands this trail an aria-label of breadcrumb-with-tooltip and
      // the trail sets its own, typo and all, over the top. Its overflow
      // trigger also carries a tooltip listing the folded crumbs; ours builds
      // the trigger itself and has no slot for one, so the popup it opens is
      // what stands in.
      FluentBreadcrumb(
        semanticLabel: 'breadcrumb-with-tootip',
        maxDisplayedItems: 3,
        items: <FluentBreadcrumbItem>[
          for (final String name in items) _tooltipCrumb(name),
        ],
      ),
      const SizedBox(height: 16),
      Text('Breadcrumb with long names', style: type.subtitle2),
      const SizedBox(height: 8),
      FluentBreadcrumb(
        semanticLabel: 'breadcrumb-with-long-names',
        items: <FluentBreadcrumbItem>[
          for (final String name in itemsWithLongNames) _tooltipCrumb(name),
        ],
      ),
    ],
  );
}

// #enddocregion components-breadcrumb--breadcrumb-with-tooltip
