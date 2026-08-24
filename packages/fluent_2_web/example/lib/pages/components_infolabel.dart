import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The InfoLabel docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage infoLabelPage = DocsPage(
  id: 'components-infolabel',
  title: 'InfoLabel',
  description:
      'An InfoLabel is a Label with an InfoButton at the end, properly '
      'handling layout and accessibility properties. It can be used as a '
      'drop-in replacement for Label when an InfoButton is also needed.',
  source: 'lib/pages/components_infolabel.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-infolabel--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-infolabel--required',
      title: 'Required',
      description:
          'When marked required, the indicator asterisk is placed before the '
          'InfoButton.',
      builder: _required,
    ),
    DocsSection(
      id: 'components-infolabel--size',
      title: 'Size',
      description:
          "InfoLabel's size prop affects the size of the Label and InfoButton. "
          "The default size is medium. The small size only meets WCAG's "
          'minimum target size requirement if it has at least 2px of '
          'non-interactive space on all sides.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-infolabel--in-field',
      title: 'In a Field',
      description:
          'An InfoLabel can be used in a Field by rendering the label prop as '
          'an InfoLabel. This uses the slot render function support. See the '
          'code from this story for an example.',
      builder: _inField,
    ),
  ],
  props: <PropRow>[
    PropRow(name: 'child', type: 'Widget', description: 'The label text.'),
    PropRow(
      name: 'info',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'The tip body. Null renders no trigger at all.',
    ),
    PropRow(
      name: 'infoSemanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description:
          'Announced by assistive technology for the trigger. Required '
          'whenever info is set.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentLabelSize',
      defaultValue: 'FluentLabelSize.medium',
      description: "Type ramp step, and the trigger's box with it.",
    ),
    PropRow(
      name: 'weight',
      type: 'FluentLabelWeight',
      defaultValue: 'FluentLabelWeight.regular',
      description: 'Label font weight.',
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
      description:
          'Whether the label renders in its disabled colour and the trigger '
          'stops responding.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentInfoLabelStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'focusNode',
      type: 'FocusNode?',
      defaultValue: 'null',
      description:
          'Focus node for the trigger. One is created internally when omitted.',
    ),
    PropRow(
      name: 'autofocus',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the trigger takes focus on mount.',
    ),
    PropRow(
      name: 'onOpenChanged',
      type: 'ValueChanged<bool>?',
      defaultValue: 'null',
      description:
          'Called with the new open state whenever the tip opens or closes.',
    ),
  ],
);

// #docregion components-infolabel--default
// `infoSemanticLabel` has no upstream counterpart: React derives the trigger's
// accessible name from the label it is wired to, and `FluentInfoLabel` asks for
// it outright rather than announce an unlabelled button.
Widget _default(BuildContext context) => FluentInfoLabel(
  info: Text.rich(
    TextSpan(
      children: <InlineSpan>[
        const TextSpan(text: 'This is example information for an InfoLabel. '),
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: FluentLink(
            inline: true,
            // Upstream links to https://react.fluentui.dev. This package
            // depends on no URL launcher, so the link is a callback.
            onPressed: () {},
            child: const Text('Learn more'),
          ),
        ),
      ],
    ),
  ),
  infoSemanticLabel: 'More information about Example label',
  child: const Text('Example label'),
);
// #enddocregion components-infolabel--default

// #docregion components-infolabel--required
Widget _required(BuildContext context) => const FluentInfoLabel(
  info: Text('Example info'),
  infoSemanticLabel: 'More information about Required label',
  required: true,
  child: Text('Required label'),
);
// #enddocregion components-infolabel--required

// #docregion components-infolabel--size
Widget _size(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  spacing: FluentSpacing.l,
  children: <Widget>[
    FluentInfoLabel(
      size: FluentLabelSize.small,
      info: Text('Example small InfoLabel'),
      infoSemanticLabel: 'More information about Small label',
      child: Text('Small label'),
    ),
    FluentInfoLabel(
      size: FluentLabelSize.medium,
      info: Text('Example medium InfoLabel'),
      infoSemanticLabel: 'More information about Medium label',
      child: Text('Medium label'),
    ),
    FluentInfoLabel(
      size: FluentLabelSize.large,
      info: Text('Example large InfoLabel'),
      infoSemanticLabel: 'More information about Large label',
      child: Text('Large label'),
    ),
  ],
);
// #enddocregion components-infolabel--size

// #docregion components-infolabel--in-field
// Upstream replaces the whole `label` slot with a render function.
// `FluentField.label` is a plain widget slot that it wraps in a `FluentLabel`
// of its own, so the info label goes in as the label's content instead: same
// rendering, one nesting level that upstream's slot API lets it skip.
Widget _inField(BuildContext context) => const FluentField(
  label: FluentInfoLabel(
    info: Text('Example info'),
    infoSemanticLabel: 'More information about Field with info label',
    child: Text('Field with info label'),
  ),
  child: FluentInput(),
);
// #enddocregion components-infolabel--in-field
