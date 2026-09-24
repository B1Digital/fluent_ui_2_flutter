import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The MenuButton docs page.
///
/// A menu button is not a widget of its own here. `fluent_2` documents it —
/// as Figma and upstream both do — as a [FluentButton] whose `menuIcon` is
/// [fluentMenuChevron], hung off a [FluentMenu].
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
const DocsPage menuButtonPage = DocsPage(
  id: 'components-button-menubutton',
  folder: 'Button',
  title: 'MenuButton',
  description:
      'A menu button is a button with a chevron icon after the text typically '
      'used to trigger a menu.',
  source: 'lib/pages/components_button_menubutton.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-button-menubutton--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-button-menubutton--shape',
      title: 'Shape',
      description: 'A menu button can be rounded, circular, or square.',
      builder: _shape,
    ),
    DocsSection(
      id: 'components-button-menubutton--appearance',
      title: 'Appearance',
      description:
          '- (undefined): the menu button appears with the default style\n'
          '- primary: emphasizes the menu button as a primary action.\n'
          '- outline: removes background styling.\n'
          '- subtle: minimizes emphasis to blend into the background until '
          'hovered or focused\n'
          '- transparent: removes background and border styling.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-button-menubutton--icon',
      title: 'Icon',
      description:
          'MenuButton has an icon slot that renders before the text, and '
          'menuIcon slot that renders after the text.',
      builder: _icon,
    ),
    DocsSection(
      id: 'components-button-menubutton--size',
      title: 'Size',
      description:
          'MenuButton supports small, medium and large size. Default size is '
          'medium.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-button-menubutton--size-small',
      title: 'Size: small',
      builder: _sizeSmall,
    ),
    DocsSection(
      id: 'components-button-menubutton--size-medium',
      title: 'Size: medium',
      builder: _sizeMedium,
    ),
    DocsSection(
      id: 'components-button-menubutton--size-large',
      title: 'Size: large',
      builder: _sizeLarge,
    ),
    DocsSection(
      id: 'components-button-menubutton--disabled',
      title: 'Disabled',
      description:
          'A menu button can be disabled or disabledFocusable. '
          'disabledFocusable is used in scenarios where it is important to '
          'keep a consistent tab order for screen reader and keyboard users. '
          'The primary example of this pattern is when the disabled menu '
          'button is in a menu or a commandbar and is seldom used for '
          'standalone buttons.',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-button-menubutton--with-long-text',
      title: 'With Long Text',
      description: 'Text wraps after it hits the max width of the component.',
      builder: _withLongText,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'child',
      type: 'Widget?',
      description: 'The label. Null for an icon-only button.',
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
      name: 'icon',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'Optional leading or trailing icon.',
    ),
    PropRow(
      name: 'activeIcon',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'Shown in place of icon while a subtle or transparent button is '
          "hovered or pressed: upstream's bundleIcon filled glyph.",
    ),
    PropRow(
      name: 'menuIcon',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'The menu affordance after the label; fluentMenuChevron makes this '
          'a menu button. Drawn 12 (16 at large) and 4 after the label.',
    ),
    PropRow(
      name: 'iconPosition',
      type: 'FluentButtonIconPosition',
      defaultValue: 'FluentButtonIconPosition.before',
      description: 'Which side of the label the icon sits on.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentButtonStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'focusNode',
      type: 'FocusNode?',
      defaultValue: 'null',
      description: 'Focus node to use. One is created internally when omitted.',
    ),
    PropRow(
      name: 'autofocus',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether to take focus on mount.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description: 'Announced by assistive technology.',
    ),
  ],
);

// #docregion components-button-menubutton--default
Widget _default(BuildContext context) => FluentMenu(
  items: <FluentMenuItem>[
    FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
    FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
  ],
  builder: (BuildContext context, VoidCallback toggle) => FluentButton(
    onPressed: toggle,
    menuIcon: fluentMenuChevron,
    child: const Text('Example'),
  ),
);
// #enddocregion components-button-menubutton--default

// #docregion components-button-menubutton--shape
Widget _shape(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        menuIcon: fluentMenuChevron,
        child: const Text('Rounded'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        shape: FluentButtonShape.circular,
        menuIcon: fluentMenuChevron,
        child: const Text('Circular'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        shape: FluentButtonShape.square,
        menuIcon: fluentMenuChevron,
        child: const Text('Square'),
      ),
    ),
  ],
);
// #enddocregion components-button-menubutton--shape

// #docregion components-button-menubutton--appearance
// Outline, Subtle and Transparent take upstream's `bundleIcon(CalendarMonth
// Filled, CalendarMonthRegular)`: `activeIcon` is the filled half, which
// subtle and transparent show under the pointer.
Widget _appearance(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        menuIcon: fluentMenuChevron,
        child: const Text('Default'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        appearance: FluentButtonAppearance.primary,
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        menuIcon: fluentMenuChevron,
        child: const Text('Primary'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        appearance: FluentButtonAppearance.outline,
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        activeIcon: const Icon(FluentIcons.calendar_month_20_filled),
        menuIcon: fluentMenuChevron,
        child: const Text('Outline'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        appearance: FluentButtonAppearance.subtle,
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        activeIcon: const Icon(FluentIcons.calendar_month_20_filled),
        menuIcon: fluentMenuChevron,
        child: const Text('Subtle'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        appearance: FluentButtonAppearance.transparent,
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        activeIcon: const Icon(FluentIcons.calendar_month_20_filled),
        menuIcon: fluentMenuChevron,
        child: const Text('Transparent'),
      ),
    ),
  ],
);
// #enddocregion components-button-menubutton--appearance

// #docregion components-button-menubutton--icon
// An icon-only MenuButton draws no menuIcon upstream (renderMenuButton skips it
// when `iconOnly`), so the third button is a plain FluentButton.icon.
Widget _icon(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        menuIcon: fluentMenuChevron,
        child: const Text('With calendar icon'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        menuIcon: const Icon(FluentIcons.filter_20_regular),
        child: const Text('With calendar icon and custom filter menu icon'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentTooltip(
        content: const Text('With calendar icon and no contents'),
        child: FluentButton.icon(
          onPressed: toggle,
          semanticLabel: 'With calendar icon and no contents',
          icon: const Icon(FluentIcons.calendar_month_20_regular),
        ),
      ),
    ),
  ],
);
// #enddocregion components-button-menubutton--icon

// #docregion components-button-menubutton--size
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
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        size: FluentButtonSize.small,
        menuIcon: fluentMenuChevron,
        child: const Text('Size: small'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        menuIcon: fluentMenuChevron,
        child: const Text('Size: medium'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        size: FluentButtonSize.large,
        menuIcon: fluentMenuChevron,
        child: const Text('Size: large'),
      ),
    ),
  ],
);
// #enddocregion components-button-menubutton--size

// #docregion components-button-menubutton--size-small
Widget _sizeSmall(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        size: FluentButtonSize.small,
        menuIcon: fluentMenuChevron,
        child: const Text('Small'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        size: FluentButtonSize.small,
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        menuIcon: fluentMenuChevron,
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
        child: FluentButton.icon(
          onPressed: toggle,
          size: FluentButtonSize.small,
          semanticLabel: 'Small with calendar icon only',
          icon: const Icon(FluentIcons.calendar_month_20_regular),
        ),
      ),
    ),
  ],
);
// #enddocregion components-button-menubutton--size-small

// #docregion components-button-menubutton--size-medium
Widget _sizeMedium(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        menuIcon: fluentMenuChevron,
        child: const Text('Medium'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        menuIcon: fluentMenuChevron,
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
        child: FluentButton.icon(
          onPressed: toggle,
          semanticLabel: 'Medium with calendar icon only',
          icon: const Icon(FluentIcons.calendar_month_20_regular),
        ),
      ),
    ),
  ],
);
// #enddocregion components-button-menubutton--size-medium

// #docregion components-button-menubutton--size-large
Widget _sizeLarge(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        size: FluentButtonSize.large,
        menuIcon: fluentMenuChevron,
        child: const Text('Large'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        size: FluentButtonSize.large,
        icon: const Icon(FluentIcons.calendar_month_20_regular),
        menuIcon: fluentMenuChevron,
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
        child: FluentButton.icon(
          onPressed: toggle,
          size: FluentButtonSize.large,
          semanticLabel: 'Large with calendar icon only',
          icon: const Icon(FluentIcons.calendar_month_20_regular),
        ),
      ),
    ),
  ],
);
// #enddocregion components-button-menubutton--size-large

// #docregion components-button-menubutton--disabled
Widget _disabled(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        menuIcon: fluentMenuChevron,
        child: const Text('Enabled state'),
      ),
    ),
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) =>
          const FluentButton(
            menuIcon: fluentMenuChevron,
            child: Text('Disabled state'),
          ),
    ),
    // FluentButton has no `disabledFocusable`: a null `onPressed` both disables
    // the button and drops it out of the tab order. `Focus` puts the disabled
    // button back into that order, which is the whole point of the upstream
    // flag.
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => const Focus(
        child: FluentButton(
          menuIcon: fluentMenuChevron,
          child: Text('Disabled focusable state'),
        ),
      ),
    ),
  ],
);
// #enddocregion components-button-menubutton--disabled

// #docregion components-button-menubutton--with-long-text
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
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        menuIcon: fluentMenuChevron,
        child: const Text('Short text'),
      ),
    ),
    // Upstream pins the button itself to 280px. FluentButton lays its label out
    // in an unbounded Row, so the width goes on the label instead: 280 less the
    // medium ramp's 12px inset and 1px border either side, and the 4px gap and
    // 12px chevron of the menuIcon slot.
    FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(label: const Text('Item a'), onPressed: () {}),
        FluentMenuItem(label: const Text('Item b'), onPressed: () {}),
      ],
      builder: (BuildContext context, VoidCallback toggle) => FluentButton(
        onPressed: toggle,
        menuIcon: fluentMenuChevron,
        child: const SizedBox(
          width:
              280 -
              (FluentSpacing.m + FluentStroke.thin) * 2 -
              FluentSpacing.xs -
              FluentSize.size120,
          child: Text(
            'Long text wraps after it hits the max width of the component',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  ],
);
// #enddocregion components-button-menubutton--with-long-text
