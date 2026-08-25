import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Label docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage labelPage = DocsPage(
  id: 'components-label',
  title: 'Label',
  description: 'A label provides a name or title for an input.',
  source: 'lib/pages/components_label.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-label--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-label--size',
      title: 'Size',
      description: 'A Label supports small, medium, and large sizes.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-label--weight',
      title: 'Weight',
      description: 'A Label with a semibold font weight.',
      builder: _weight,
    ),
    DocsSection(
      id: 'components-label--disabled',
      title: 'Disabled',
      description:
          'A Label can be disabled. Since this state does not meet the '
          'required accessibility contrast ratio, it should be used sparingly '
          "and make it clear that there's no interaction with the control "
          'associated with it.',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-label--required',
      title: 'Required',
      description:
          'A Label can display a required asterisk or a custom required '
          'indicator. This custom required indicator canbe a custom string or '
          'jsx content.',
      builder: _required,
    ),
  ],
  props: <PropRow>[
    PropRow(name: 'child', type: 'Widget', description: 'The label text.'),
    PropRow(
      name: 'size',
      type: 'FluentLabelSize',
      defaultValue: 'FluentLabelSize.medium',
      description: 'Type ramp step.',
    ),
    PropRow(
      name: 'weight',
      type: 'FluentLabelWeight',
      defaultValue: 'FluentLabelWeight.regular',
      description: 'Font weight.',
    ),
    PropRow(
      name: 'required',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether to render the required-field asterisk after the child.',
    ),
    PropRow(
      name: 'disabled',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the label renders in its disabled colour.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentLabelStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
  ],
);

// #docregion components-label--default
Widget _default(BuildContext context) =>
    const FluentLabel(child: Text('This is a label'));
// #enddocregion components-label--default

// #docregion components-label--size
Widget _size(BuildContext context) => const Wrap(
  spacing: 16,
  runSpacing: 12,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    FluentLabel(size: FluentLabelSize.small, child: Text('Small')),
    FluentLabel(child: Text('Medium')),
    FluentLabel(size: FluentLabelSize.large, child: Text('Large')),
  ],
);
// #enddocregion components-label--size

// #docregion components-label--weight
Widget _weight(BuildContext context) => const FluentLabel(
  weight: FluentLabelWeight.semibold,
  child: Text('Strong label'),
);
// #enddocregion components-label--weight

// #docregion components-label--disabled
Widget _disabled(BuildContext context) => const FluentLabel(
  disabled: true,
  required: true,
  child: Text('Disabled label'),
);
// #enddocregion components-label--disabled

// #docregion components-label--required
// Upstream's `required` prop doubles as a slot: `required="***"` replaces the
// asterisk with a string or JSX. Ours is a plain bool, so the custom indicator
// is composed next to the label using the same statusDangerForeground3 token
// FluentLabel paints its own asterisk with.
Widget _required(BuildContext context) => Wrap(
  spacing: 16,
  runSpacing: 12,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    const FluentLabel(required: true, child: Text('Required label')),
    Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: FluentSpacing.xs,
      children: <Widget>[
        const FluentLabel(child: Text('Required label')),
        Text(
          '***',
          style: TextStyle(
            color: FluentTheme.of(context).colors.statusDangerForeground3,
          ),
        ),
      ],
    ),
  ],
);
// #enddocregion components-label--required
