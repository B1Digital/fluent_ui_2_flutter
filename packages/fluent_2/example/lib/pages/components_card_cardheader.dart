import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The CardHeader docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage cardHeaderPage = DocsPage(
  id: 'components-card-cardheader',
  folder: 'Card',
  title: 'CardHeader',
  description:
      'The CardHeader component, used inside of a Card, represents a Fluent UI '
      'compliant card header.',
  source: 'lib/pages/components_card_cardheader.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-card-cardheader--default',
      title: 'Default',
      builder: _default,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'image',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'An image or avatar related to the card, before the title.',
    ),
    PropRow(
      name: 'header',
      type: 'Widget',
      description: 'The main header title. Carries body1Strong.',
    ),
    PropRow(
      name: 'description',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'A short description under the title. Carries caption1.',
    ),
    PropRow(
      name: 'action',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'Action affordance pinned to the far end of the row.',
    ),
  ],
);

// #docregion components-card-cardheader--default
// Upstream's `CardHeader` is a four-slot CSS grid rather than a component we
// ship: `FluentCard.header` takes a plain widget, deliberately, so the grid is
// composed at the call site. `_CardHeader` below is that composition — image,
// title, description and a trailing action — and it is what a caller would
// hand to `FluentCard(header: ...)`.
//
// The PowerPoint logo `pptx.png` is not one of the checked-in storybook
// assets, so the image slot carries the nearest Fluent icon and keeps
// upstream's alt text as its semantics label.
Widget _default(BuildContext context) => SizedBox(
  width: 300,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: <Widget>[
      _CardHeader(
        image: const _PowerPointLogo(),
        header: const Text('App Name'),
        description: const Text('Developer'),
        action: _moreOptions(),
      ),
      _CardHeader(
        header: const Text('App Name'),
        description: const Text('Developer'),
        action: _moreOptions(),
      ),
      _CardHeader(
        image: const _PowerPointLogo(),
        header: const Text('App Name'),
        action: _moreOptions(),
      ),
      const _CardHeader(
        image: _PowerPointLogo(),
        header: Text('App Name'),
        description: Text('Developer'),
      ),
      _CardHeader(header: const Text('App Name'), action: _moreOptions()),
      const _CardHeader(
        header: Text('App Name'),
        description: Text('Developer'),
      ),
      const _CardHeader(image: _PowerPointLogo(), header: Text('App Name')),
      const _CardHeader(header: Text('App Name')),
    ],
  ),
);

FluentButton _moreOptions() => FluentButton.icon(
  appearance: FluentButtonAppearance.transparent,
  icon: const Icon(FluentIcons.more_horizontal_20_regular),
  semanticLabel: 'More options',
  onPressed: () {},
);

class _PowerPointLogo extends StatelessWidget {
  const _PowerPointLogo();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Microsoft PowerPoint logo',
    image: true,
    child: const Icon(FluentIcons.slide_layout_24_regular, size: 32),
  );
}

/// The four-slot header row Fluent's `CardHeader` lays out as a grid: [image]
/// spanning both text rows, [header] over [description], and [action] pinned
/// to the far end.
class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.header,
    this.image,
    this.description,
    this.action,
  });

  final Widget header;
  final Widget? image;
  final Widget? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final FluentTypography type = FluentTheme.of(context).typography;
    return Row(
      children: <Widget>[
        if (image != null) ...<Widget>[image!, const SizedBox(width: 12)],
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DefaultTextStyle(style: type.body1Strong, child: header),
              if (description != null)
                DefaultTextStyle(style: type.caption1, child: description!),
            ],
          ),
        ),
        if (action != null) ...<Widget>[const SizedBox(width: 12), action!],
      ],
    );
  }
}

// #enddocregion components-card-cardheader--default
