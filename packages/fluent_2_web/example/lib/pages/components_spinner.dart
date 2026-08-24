import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Spinner docs page.
///
/// Sections, titles and sample data are upstream's, verbatim. Each section's
/// demo is delimited by a `#docregion` whose id is the section id, so the
/// "Show code" panel can read this file back and print exactly the code that
/// rendered.
const DocsPage spinnerPage = DocsPage(
  id: 'components-spinner',
  title: 'Spinner',
  description:
      'A spinner alerts a user that content is being loaded or processed and '
      'they should wait for the activity to complete.',
  source: 'lib/pages/components_spinner.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-spinner--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-spinner--appearance',
      title: 'Appearance',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-spinner--labels',
      title: 'Labels',
      builder: _labels,
    ),
    DocsSection(id: 'components-spinner--size', title: 'Size', builder: _size),
  ],
  props: <PropRow>[
    PropRow(
      name: 'label',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'The visible label. Null for a bare ring.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentSpinnerAppearance',
      defaultValue: 'FluentSpinnerAppearance.primary',
      description: 'Ring and label colouring.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentSpinnerSize',
      defaultValue: 'FluentSpinnerSize.medium',
      description: 'Diameter, thickness and type ramp.',
    ),
    PropRow(
      name: 'labelPosition',
      type: 'FluentSpinnerLabelPosition',
      defaultValue: 'FluentSpinnerLabelPosition.after',
      description: 'Where the label sits relative to the ring.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentSpinnerStyle?',
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

// #docregion components-spinner--default
Widget _default(BuildContext context) => const Center(child: FluentSpinner());
// #enddocregion components-spinner--default

// #docregion components-spinner--appearance
// Upstream's `appearance="inverted"` is our `FluentSpinnerAppearance.subtle`:
// the same white-on-translucent ring, named for the surface it sits on rather
// than for the inversion. Inverted spinners are meant as overlays (e.g., over
// an image or similar) so give it a solid, dark background so it is visible in
// all themes.
Widget _appearance(BuildContext context) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: <Widget>[
    const Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: FluentSpinner(
          appearance: FluentSpinnerAppearance.primary,
          label: Text('Primary Spinner'),
        ),
      ),
    ),
    ColoredBox(
      color: FluentTheme.of(context).colors.brandBackgroundStatic,
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: FluentSpinner(
            appearance: FluentSpinnerAppearance.subtle,
            label: Text('Inverted Spinner'),
          ),
        ),
      ),
    ),
  ],
);
// #enddocregion components-spinner--appearance

// #docregion components-spinner--labels
Widget _labels(BuildContext context) => const Column(
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    Padding(
      padding: EdgeInsets.all(20),
      child: FluentSpinner(
        labelPosition: FluentSpinnerLabelPosition.before,
        label: Text('Label Position Before...'),
      ),
    ),
    Padding(
      padding: EdgeInsets.all(20),
      child: FluentSpinner(
        labelPosition: FluentSpinnerLabelPosition.after,
        label: Text('Label Position After...'),
      ),
    ),
    Padding(
      padding: EdgeInsets.all(20),
      child: FluentSpinner(
        labelPosition: FluentSpinnerLabelPosition.above,
        label: Text('Label Position Above...'),
      ),
    ),
    Padding(
      padding: EdgeInsets.all(20),
      child: FluentSpinner(
        labelPosition: FluentSpinnerLabelPosition.below,
        label: Text('Label Position Below...'),
      ),
    ),
  ],
);
// #enddocregion components-spinner--labels

// #docregion components-spinner--size
Widget _size(BuildContext context) => const Column(
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    Padding(
      padding: EdgeInsets.all(20),
      child: FluentSpinner(
        size: FluentSpinnerSize.extraTiny,
        label: Text('Extra Tiny Spinner'),
      ),
    ),
    Padding(
      padding: EdgeInsets.all(20),
      child: FluentSpinner(
        size: FluentSpinnerSize.tiny,
        label: Text('Tiny Spinner'),
      ),
    ),
    Padding(
      padding: EdgeInsets.all(20),
      child: FluentSpinner(
        size: FluentSpinnerSize.extraSmall,
        label: Text('Extra Small Spinner'),
      ),
    ),
    Padding(
      padding: EdgeInsets.all(20),
      child: FluentSpinner(
        size: FluentSpinnerSize.small,
        label: Text('Small Spinner'),
      ),
    ),
    Padding(
      padding: EdgeInsets.all(20),
      child: FluentSpinner(
        size: FluentSpinnerSize.medium,
        label: Text('Medium Spinner'),
      ),
    ),
    Padding(
      padding: EdgeInsets.all(20),
      child: FluentSpinner(
        size: FluentSpinnerSize.large,
        label: Text('Large Spinner'),
      ),
    ),
    Padding(
      padding: EdgeInsets.all(20),
      child: FluentSpinner(
        size: FluentSpinnerSize.extraLarge,
        label: Text('Extra Large Spinner'),
      ),
    ),
    Padding(
      padding: EdgeInsets.all(20),
      child: FluentSpinner(
        size: FluentSpinnerSize.huge,
        label: Text('Huge Spinner'),
      ),
    ),
  ],
);
// #enddocregion components-spinner--size
