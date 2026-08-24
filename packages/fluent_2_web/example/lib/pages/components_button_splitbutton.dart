import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The SplitButton docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage splitButtonPage = DocsPage(
  id: 'components-button-splitbutton',
  folder: 'Button',
  title: 'SplitButton',
  description:
      'A split button is a button with a primary action and a secondary action '
      'primarily used for opening a menu.',
  source: 'lib/pages/components_button_splitbutton.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-button-splitbutton--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-button-splitbutton--shape',
      title: 'Shape',
      description: 'A split button can be rounded, circular, or square.',
      builder: _shape,
    ),
    DocsSection(
      id: 'components-button-splitbutton--appearance',
      title: 'Appearance',
      description:
          '- (undefined): the split button appears with the default style\n'
          '- primary: emphasizes the split button as a primary action.\n'
          '- outline: removes background styling.\n'
          '- subtle: minimizes emphasis to blend into the background until '
          'hovered or focused\n'
          '- transparent: removes background and border styling.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-button-splitbutton--icon',
      title: 'Icon',
      description:
          'SplitButton has an icon slot that renders before the text, and '
          'menuIcon slot that renders after the text.',
      builder: _icon,
    ),
    DocsSection(
      id: 'components-button-splitbutton--size',
      title: 'Size',
      description:
          'SplitButton supports small, medium and large size. Default size is '
          'medium.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-button-splitbutton--size-small',
      title: 'Size: small',
      description:
          'WARNING: the small SplitButton does not meet WCAG target size '
          'requirements. Only use this variant if there is an equally '
          'accessible alternative way to perform the same action, or if it is '
          'part of a user-selected compact theme.',
      builder: _sizeSmall,
    ),
    DocsSection(
      id: 'components-button-splitbutton--size-medium',
      title: 'Size: medium',
      builder: _sizeMedium,
    ),
    DocsSection(
      id: 'components-button-splitbutton--size-large',
      title: 'Size: large',
      builder: _sizeLarge,
    ),
    DocsSection(
      id: 'components-button-splitbutton--disabled',
      title: 'Disabled',
      description:
          'A split button can be disabled or disabledFocusable. '
          'disabledFocusable is used in scenarios where it is important to '
          'keep a consistent tab order for screen reader and keyboard users. '
          'The primary example of this pattern is when the disabled split '
          'button is in a menu or a commandbar and is seldom used for '
          'standalone buttons.',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-button-splitbutton--with-long-text',
      title: 'With Long Text',
      description: 'Text wraps after it hits the max width of the component.',
      builder: _withLongText,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'child',
      type: 'Widget',
      description: "The primary action's label.",
    ),
    PropRow(
      name: 'menuSemanticLabel',
      type: 'String',
      description:
          'Announced for the chevron half, which has no text of its own.',
    ),
    PropRow(
      name: 'onPressed',
      type: 'VoidCallback?',
      defaultValue: 'null',
      description:
          'Invoked on tap and on Space or Enter on the primary half. Null '
          'disables that half.',
    ),
    PropRow(
      name: 'onMenuPressed',
      type: 'VoidCallback?',
      defaultValue: 'null',
      description:
          'Invoked on tap and on Space or Enter on the chevron half. Null '
          'disables that half.',
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
      description:
          "Corner treatment. Applies to the pair's outer corners only.",
    ),
    PropRow(
      name: 'iconPosition',
      type: 'FluentButtonIconPosition',
      defaultValue: 'FluentButtonIconPosition.before',
      description: "Which side of the label the primary half's icon sits on.",
    ),
    PropRow(
      name: 'icon',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'Optional icon on the primary half.',
    ),
    PropRow(
      name: 'menuIcon',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'The chevron. Defaults to fluentMenuChevron.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentSplitButtonStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'focusNode',
      type: 'FocusNode?',
      defaultValue: 'null',
      description:
          'Focus node for the primary half. One is created internally when '
          'omitted.',
    ),
    PropRow(
      name: 'menuFocusNode',
      type: 'FocusNode?',
      defaultValue: 'null',
      description:
          'Focus node for the chevron half. One is created internally when '
          'omitted.',
    ),
    PropRow(
      name: 'autofocus',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the primary half takes focus on mount.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description:
          'Announced for the primary half. Optional; the label already carries '
          'the meaning.',
    ),
  ],
);

// #docregion components-button-splitbutton--default
// Upstream's primary action calls `alert()`. Flutter has no such thing, so the
// message lands under the button instead — nothing is shown until it is
// clicked, which is what the browser dialog amounts to on first render.
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  String? _message;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentMenu(
        items: <FluentMenuItem>[
          FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
          FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
        ],
        builder: (BuildContext context, VoidCallback toggle) =>
            FluentSplitButton(
              menuSemanticLabel: 'Open menu',
              onPressed: () =>
                  setState(() => _message = 'Primary action button clicked.'),
              onMenuPressed: toggle,
              child: const Text('Example'),
            ),
      ),
      if (_message != null) ...<Widget>[
        const SizedBox(height: 8),
        Text(_message!),
      ],
    ],
  );
}
// #enddocregion components-button-splitbutton--default

// #docregion components-button-splitbutton--shape
Widget _shape(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Rounded'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        shape: FluentButtonShape.circular,
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Circular'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        shape: FluentButtonShape.square,
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Square'),
      ),
    ),
  ],
);
// #enddocregion components-button-splitbutton--shape

// #docregion components-button-splitbutton--appearance
Widget _appearance(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Default'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        appearance: FluentButtonAppearance.primary,
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Primary'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        appearance: FluentButtonAppearance.outline,
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Outline'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        appearance: FluentButtonAppearance.subtle,
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Subtle'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        appearance: FluentButtonAppearance.transparent,
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Transparent'),
      ),
    ),
  ],
);
// #enddocregion components-button-splitbutton--appearance

// #docregion components-button-splitbutton--icon
Widget _icon(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('With calendar icon before contents'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        iconPosition: FluentButtonIconPosition.after,
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('With calendar icon after contents'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        menuIcon: const Icon(FluentIcons.filter_20_regular),
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('With calendar icon and custom filter menu icon'),
      ),
    ),
    // `child` is required, so an icon-only split button passes an empty label
    // rather than omitting one.
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentTooltip(
        content: const Text('With calendar icon only'),
        child: FluentSplitButton(
          menuSemanticLabel: 'Open menu',
          semanticLabel: 'With calendar icon only',
          icon: const Icon(FluentIcons.calendar_month_20_regular),
          onPressed: () {},
          onMenuPressed: toggle,
          child: const SizedBox.shrink(),
        ),
      ),
    ),
  ],
);
// #enddocregion components-button-splitbutton--icon

// #docregion components-button-splitbutton--size
Widget _size(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        size: FluentButtonSize.small,
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Size: small'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Size: medium'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        size: FluentButtonSize.large,
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Size: large'),
      ),
    ),
  ],
);
// #enddocregion components-button-splitbutton--size

// #docregion components-button-splitbutton--size-small
Widget _sizeSmall(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        size: FluentButtonSize.small,
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Small'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        size: FluentButtonSize.small,
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Small with calendar icon'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentTooltip(
        content: const Text('Small with calendar icon only'),
        child: FluentSplitButton(
          menuSemanticLabel: 'Open menu',
          semanticLabel: 'Small with calendar icon only',
          size: FluentButtonSize.small,
          icon: const Icon(FluentIcons.calendar_month_20_regular),
          onPressed: () {},
          onMenuPressed: toggle,
          child: const SizedBox.shrink(),
        ),
      ),
    ),
  ],
);
// #enddocregion components-button-splitbutton--size-small

// #docregion components-button-splitbutton--size-medium
Widget _sizeMedium(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Medium'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Medium with calendar icon'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentTooltip(
        content: const Text('Medium with calendar icon only'),
        child: FluentSplitButton(
          menuSemanticLabel: 'Open menu',
          semanticLabel: 'Medium with calendar icon only',
          icon: const Icon(FluentIcons.calendar_month_20_regular),
          onPressed: () {},
          onMenuPressed: toggle,
          child: const SizedBox.shrink(),
        ),
      ),
    ),
  ],
);
// #enddocregion components-button-splitbutton--size-medium

// #docregion components-button-splitbutton--size-large
Widget _sizeLarge(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        size: FluentButtonSize.large,
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Large'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        size: FluentButtonSize.large,
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Large with calendar icon'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentTooltip(
        content: const Text('Large with calendar icon only'),
        child: FluentSplitButton(
          menuSemanticLabel: 'Open menu',
          semanticLabel: 'Large with calendar icon only',
          size: FluentButtonSize.large,
          icon: const Icon(FluentIcons.calendar_month_20_regular),
          onPressed: () {},
          onMenuPressed: toggle,
          child: const SizedBox.shrink(),
        ),
      ),
    ),
  ],
);
// #enddocregion components-button-splitbutton--size-large

// #docregion components-button-splitbutton--disabled
// A disabled half is one whose callback is null, so a disabled split button
// needs no menu behind it. `FluentSplitButton` has no `disabledFocusable`
// counterpart — a disabled half refuses focus — so the third button renders as
// plain disabled.
Widget _disabled(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Enabled state'),
      ),
    ),
    const FluentSplitButton(
      menuSemanticLabel: 'Open menu',
      child: Text('Disabled state'),
    ),
    const FluentSplitButton(
      menuSemanticLabel: 'Open menu',
      child: Text('Disabled focusable state'),
    ),
  ],
);
// #enddocregion components-button-splitbutton--disabled

// #docregion components-button-splitbutton--with-long-text
Widget _withLongText(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        onPressed: () {},
        onMenuPressed: toggle,
        child: const Text('Short text'),
      ),
    ),
    // Upstream widths the primary action half itself; here the label carries
    // the width, which is what makes the text wrap.
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentSplitButton(
        menuSemanticLabel: 'Open menu',
        onPressed: () {},
        onMenuPressed: toggle,
        child: const SizedBox(
          width: 280,
          child: Text(
            'Long text wraps after it hits the max width of the component',
          ),
        ),
      ),
    ),
  ],
);
// #enddocregion components-button-splitbutton--with-long-text
