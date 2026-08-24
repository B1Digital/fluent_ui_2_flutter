import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The CompoundButton docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage compoundButtonPage = DocsPage(
  id: 'components-button-compoundbutton',
  folder: 'Button',
  title: 'CompoundButton',
  description:
      'A compound button is a button with an additional slot for secondary '
      'textual content.\n\n'
      "Since both primary and secondary textual contents are part of a "
      "compound button's name they should be kept concise.",
  source: 'lib/pages/components_button_compoundbutton.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-button-compoundbutton--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-button-compoundbutton--shape',
      title: 'Shape',
      description: 'A compound button can be rounded, circular, or square.',
      builder: _shape,
    ),
    DocsSection(
      id: 'components-button-compoundbutton--appearance',
      title: 'Appearance',
      description:
          '- (undefined): the compound button appears with the default style\n'
          '- primary: emphasizes the compound button as a primary action.\n'
          '- outline: removes background styling.\n'
          '- subtle: minimizes emphasis to blend into the background until '
          'hovered or focused\n'
          '- transparent: removes background and border styling.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-button-compoundbutton--icon',
      title: 'Icon',
      description:
          'The CompoundButton has an icon slot that, if specified, renders an '
          'icon either before or after the children, as specified by the '
          'iconPosition prop.',
      builder: _icon,
    ),
    DocsSection(
      id: 'components-button-compoundbutton--size',
      title: 'Size',
      description:
          'A compound button supports small, medium and large size. Default '
          'size is medium.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-button-compoundbutton--disabled',
      title: 'Disabled',
      description:
          'A compound button can be disabled or disabledFocusable. '
          'disabledFocusable is used in scenarios where it is important to '
          'keep a consistent tab order for screen reader and keyboard users. '
          'The primary example of this pattern is when the disabled compound '
          'button is in a menu or a commandbar and is seldom used for '
          'standalone buttons.',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-button-compoundbutton--with-long-text',
      title: 'With Long Text',
      description: 'Text wraps after it hits the max width of the component.',
      builder: _withLongText,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'child',
      type: 'Widget',
      description: 'The first, louder line.',
    ),
    PropRow(
      name: 'secondaryContent',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'The second, quieter line. Null renders a plain button with compound '
          'geometry.',
    ),
    PropRow(
      name: 'onPressed',
      type: 'VoidCallback?',
      defaultValue: 'null',
      description:
          'Invoked on tap and on Space or Enter. Null disables the button.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentButtonAppearance',
      defaultValue: 'FluentButtonAppearance.secondary',
      description: 'Fill and outline treatment.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentButtonSize',
      defaultValue: 'FluentButtonSize.medium',
      description: 'Height and type ramp.',
    ),
    PropRow(
      name: 'shape',
      type: 'FluentButtonShape',
      defaultValue: 'FluentButtonShape.rounded',
      description: 'Corner treatment.',
    ),
    PropRow(
      name: 'iconPosition',
      type: 'FluentButtonIconPosition',
      defaultValue: 'FluentButtonIconPosition.before',
      description: 'Which side of the label the icon sits on.',
    ),
    PropRow(
      name: 'icon',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'Optional leading or trailing icon, rendered at 40 logical pixels.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentCompoundButtonStyle?',
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

// #docregion components-button-compoundbutton--default
Widget _default(BuildContext context) => FluentCompoundButton(
  icon: const Icon(FluentIcons.calendar_month_20_regular),
  secondaryContent: const Text('Secondary content'),
  onPressed: () {},
  child: const Text('Example'),
);
// #enddocregion components-button-compoundbutton--default

// #docregion components-button-compoundbutton--shape
Widget _shape(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentCompoundButton(
      secondaryContent: const Text('Secondary content'),
      onPressed: () {},
      child: const Text('Rounded'),
    ),
    FluentCompoundButton(
      secondaryContent: const Text('Secondary content'),
      shape: FluentButtonShape.circular,
      onPressed: () {},
      child: const Text('Circular'),
    ),
    FluentCompoundButton(
      secondaryContent: const Text('Secondary content'),
      shape: FluentButtonShape.square,
      onPressed: () {},
      child: const Text('Square'),
    ),
  ],
);
// #enddocregion components-button-compoundbutton--shape

// #docregion components-button-compoundbutton--appearance
// Upstream bundles the filled and regular calendar icons so the glyph fills on
// hover. We have no bundled-icon widget, so every button shows the regular
// glyph, which is what upstream shows at rest.
Widget _appearance(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentCompoundButton(
      secondaryContent: const Text('Secondary content'),
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      onPressed: () {},
      child: const Text('Default'),
    ),
    FluentCompoundButton(
      secondaryContent: const Text('Secondary content'),
      appearance: FluentButtonAppearance.primary,
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      onPressed: () {},
      child: const Text('Primary'),
    ),
    FluentCompoundButton(
      secondaryContent: const Text('Secondary content'),
      appearance: FluentButtonAppearance.outline,
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      onPressed: () {},
      child: const Text('Outline'),
    ),
    FluentCompoundButton(
      secondaryContent: const Text('Secondary content'),
      appearance: FluentButtonAppearance.subtle,
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      onPressed: () {},
      child: const Text('Subtle'),
    ),
    FluentCompoundButton(
      secondaryContent: const Text('Secondary content'),
      appearance: FluentButtonAppearance.transparent,
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      onPressed: () {},
      child: const Text('Transparent'),
    ),
  ],
);
// #enddocregion components-button-compoundbutton--appearance

// #docregion components-button-compoundbutton--icon
Widget _icon(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    FluentCompoundButton(
      secondaryContent: const Text('Secondary content'),
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      onPressed: () {},
      child: const Text('With calendar icon before contents'),
    ),
    FluentCompoundButton(
      secondaryContent: const Text('Secondary content'),
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      iconPosition: FluentButtonIconPosition.after,
      onPressed: () {},
      child: const Text('With calendar icon after contents'),
    ),
    // FluentCompoundButton requires a label, so the icon-only case is a
    // FluentButton.icon — which is exactly what upstream renders here anyway,
    // a compound button with neither line of text.
    FluentTooltip(
      content: const Text('With calendar icon only'),
      child: FluentButton.icon(
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        semanticLabel: 'With calendar icon only',
        onPressed: () {},
      ),
    ),
  ],
);
// #enddocregion components-button-compoundbutton--icon

// #docregion components-button-compoundbutton--size
Widget _size(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    FluentCompoundButton(
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      secondaryContent: const Text('Secondary content'),
      size: FluentButtonSize.small,
      onPressed: () {},
      child: const Text('Size: small'),
    ),
    FluentCompoundButton(
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      secondaryContent: const Text('Secondary content'),
      onPressed: () {},
      child: const Text('Size: medium'),
    ),
    FluentCompoundButton(
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      secondaryContent: const Text('Secondary content'),
      size: FluentButtonSize.large,
      onPressed: () {},
      child: const Text('Size: large'),
    ),
  ],
);
// #enddocregion components-button-compoundbutton--size

// #docregion components-button-compoundbutton--disabled
// A null onPressed is our only disabled state, so the third button in each row
// renders disabled rather than disabled-but-focusable.
Widget _disabled(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  spacing: 15,
  children: <Widget>[
    Wrap(
      spacing: 15,
      runSpacing: 15,
      children: <Widget>[
        FluentCompoundButton(
          secondaryContent: const Text('Secondary content'),
          onPressed: () {},
          child: const Text('Enabled state'),
        ),
        const FluentCompoundButton(
          secondaryContent: Text('Secondary content'),
          child: Text('Disabled state'),
        ),
        const FluentCompoundButton(
          secondaryContent: Text('Secondary content'),
          child: Text('Disabled focusable state'),
        ),
      ],
    ),
    Wrap(
      spacing: 15,
      runSpacing: 15,
      children: <Widget>[
        FluentCompoundButton(
          appearance: FluentButtonAppearance.primary,
          secondaryContent: const Text('Secondary content'),
          onPressed: () {},
          child: const Text('Enabled state'),
        ),
        const FluentCompoundButton(
          appearance: FluentButtonAppearance.primary,
          secondaryContent: Text('Secondary content'),
          child: Text('Disabled state'),
        ),
        const FluentCompoundButton(
          appearance: FluentButtonAppearance.primary,
          secondaryContent: Text('Secondary content'),
          child: Text('Disabled focusable state'),
        ),
      ],
    ),
  ],
);
// #enddocregion components-button-compoundbutton--disabled

// #docregion components-button-compoundbutton--with-long-text
Widget _withLongText(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    FluentCompoundButton(
      secondaryContent: const Text('Secondary content'),
      onPressed: () {},
      child: const Text('Short text'),
    ),
    FluentCompoundButton(
      secondaryContent: const Text('Secondary content'),
      onPressed: () {},
      // Upstream sets width: 280px on the button. A Row hands its children
      // unbounded width, so the wrap has to be asked for on the label itself:
      // 280 less the medium compound button's 12px inset on either side.
      child: const SizedBox(
        width: 280 - FluentSpacing.m * 2,
        child: Text(
          'Long text wraps after it hits the max width of the component',
        ),
      ),
    ),
  ],
);
// #enddocregion components-button-compoundbutton--with-long-text
