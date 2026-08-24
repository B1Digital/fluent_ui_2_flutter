import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The ToggleButton docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
///
/// fluent_2_web has no toggle button widget. Every demo here uses
/// `_ToggleButton`, defined in the Default section, which composes one out of
/// `FluentButton` by re-resolving the button's own style with
/// `WidgetState.selected` folded in — the state Fluent's `*Selected` tokens
/// key on.
const DocsPage toggleButtonPage = DocsPage(
  id: 'components-button-togglebutton',
  folder: 'Button',
  title: 'ToggleButton',
  description: 'A toggle button is a button that can be checked on and off.',
  source: 'lib/pages/components_button_togglebutton.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-button-togglebutton--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-button-togglebutton--shape',
      title: 'Shape',
      description: 'A toggle button can be rounded, circular, or square.',
      builder: _shape,
    ),
    DocsSection(
      id: 'components-button-togglebutton--appearance',
      title: 'Appearance',
      description:
          '- (undefined): the toggle button appears with the default style\n'
          '- primary: emphasizes the toggle button as a primary action.\n'
          '- outline: removes background styling.\n'
          '- subtle: minimizes emphasis to blend into the background until '
          'hovered or focused\n'
          '- transparent: removes background and border styling.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-button-togglebutton--accessible-appearance',
      title: 'Accessible Appearance',
      description:
          'Appearance variants with isAccessible set, showing more contrasting '
          'colors when checked. The primary variant uses the same colors, but '
          'with an inset stroke for the checked state.\n\nThis approach is '
          'available for when the icon is not used to differentiate checked '
          'vs. unchecked states.',
      builder: _accessibleAppearance,
    ),
    DocsSection(
      id: 'components-button-togglebutton--icon',
      title: 'Icon',
      description:
          'The ToggleButton has an icon slot that, if specified, renders an '
          'icon either before or after the children, as specified by the '
          'iconPosition prop.',
      builder: _icon,
    ),
    DocsSection(
      id: 'components-button-togglebutton--size',
      title: 'Size',
      description:
          'A toggle button supports small, medium and large size. Default size '
          'is medium.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-button-togglebutton--disabled',
      title: 'Disabled',
      description:
          'A toggle button can be disabled or disabledFocusable. '
          'disabledFocusable is used in scenarios where it is important to '
          'keep a consistent tab order for screen reader and keyboard users. '
          'The primary example of this pattern is when the disabled toggle '
          'button is in a menu or a commandbar and is seldom used for '
          'standalone buttons.',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-button-togglebutton--checked',
      title: 'Checked',
      description:
          'A toggle button can be checked or unchecked. Unchecked is default. '
          "If a checked value is given, the button is 'controlled' and will "
          'only change state when the props value changes.',
      builder: _checked,
    ),
    DocsSection(
      id: 'components-button-togglebutton--with-long-text',
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
      name: 'iconPosition',
      type: 'FluentButtonIconPosition',
      defaultValue: 'FluentButtonIconPosition.before',
      description: 'Which side of the label the icon sits on.',
    ),
    PropRow(
      name: 'icon',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'Optional leading or trailing icon.',
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

// #docregion components-button-togglebutton--default
Widget _default(BuildContext context) =>
    const _ToggleButton(child: Text('Example'));

// fluent_2_web ships no toggle button, so this file composes one. A checked
// toggle button is a FluentButton whose colours are the button's own, resolved
// with WidgetState.selected folded into the live interaction states — that is
// exactly the state Fluent's *Selected tokens key on, and folding it in rather
// than pinning a colour keeps hover, press and disabled winning as they should.
class _ToggleButton extends StatefulWidget {
  const _ToggleButton({
    this.child,
    this.icon,
    this.checkedIcon,
    this.iconPosition = FluentButtonIconPosition.before,
    this.appearance = FluentButtonAppearance.secondary,
    this.size = FluentButtonSize.medium,
    this.shape = FluentButtonShape.rounded,
    this.checked,
    this.enabled = true,
    this.semanticLabel,
  });

  /// The label. Null renders an icon-only toggle button.
  final Widget? child;

  /// The icon shown while unchecked.
  final Widget? icon;

  /// The icon shown while checked. Upstream's bundleIcon, which swaps the
  /// regular glyph for the filled one once the button is checked.
  final Widget? checkedIcon;

  final FluentButtonIconPosition iconPosition;
  final FluentButtonAppearance appearance;
  final FluentButtonSize size;
  final FluentButtonShape shape;

  /// Non-null makes the button controlled: a press no longer changes it.
  final bool? checked;

  final bool enabled;
  final String? semanticLabel;

  @override
  State<_ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<_ToggleButton> {
  bool _selfChecked = false;

  bool get _isChecked => widget.checked ?? _selfChecked;

  FluentButtonStyle _checkedStyle(BuildContext context) {
    final FluentButtonStyle base = resolveFluentButtonStyle(
      resolveFluentButtonState(
        enabled: widget.enabled,
        appearance: widget.appearance,
        size: widget.size,
        shape: widget.shape,
      ),
      FluentTheme.of(context),
    );

    WidgetStateProperty<Color?> selected(WidgetStateProperty<Color?>? color) =>
        WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) =>
              color?.resolve(<WidgetState>{...states, WidgetState.selected}),
        );

    return FluentButtonStyle(
      backgroundColor: selected(base.backgroundColor),
      foregroundColor: selected(base.foregroundColor),
      borderColor: selected(base.borderColor),
    );
  }

  @override
  Widget build(BuildContext context) => FluentButton(
    appearance: widget.appearance,
    size: widget.size,
    shape: widget.shape,
    icon: _isChecked ? widget.checkedIcon ?? widget.icon : widget.icon,
    iconPosition: widget.iconPosition,
    semanticLabel: widget.semanticLabel,
    style: _isChecked ? _checkedStyle(context) : null,
    onPressed: widget.enabled
        ? () => setState(() => _selfChecked = !_isChecked)
        : null,
    child: widget.child,
  );
}
// #enddocregion components-button-togglebutton--default

// #docregion components-button-togglebutton--shape
// _ToggleButton is the composed toggle button defined in the Default section.
Widget _shape(BuildContext context) => const Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    _ToggleButton(child: Text('Rounded')),
    _ToggleButton(shape: FluentButtonShape.circular, child: Text('Circular')),
    _ToggleButton(shape: FluentButtonShape.square, child: Text('Square')),
  ],
);
// #enddocregion components-button-togglebutton--shape

// #docregion components-button-togglebutton--appearance
// _ToggleButton is the composed toggle button defined in the Default section.
// checkedIcon stands in for upstream's bundleIcon: the filled glyph while
// checked, the regular one otherwise.
Widget _appearance(BuildContext context) => const Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    _ToggleButton(
      icon: Icon(FluentIcons.calendar_month_20_regular),
      checkedIcon: Icon(FluentIcons.calendar_month_20_filled),
      child: Text('Default'),
    ),
    _ToggleButton(
      appearance: FluentButtonAppearance.primary,
      icon: Icon(FluentIcons.calendar_month_20_regular),
      checkedIcon: Icon(FluentIcons.calendar_month_20_filled),
      child: Text('Primary'),
    ),
    _ToggleButton(
      appearance: FluentButtonAppearance.outline,
      icon: Icon(FluentIcons.calendar_month_20_regular),
      checkedIcon: Icon(FluentIcons.calendar_month_20_filled),
      child: Text('Outline'),
    ),
    _ToggleButton(
      appearance: FluentButtonAppearance.subtle,
      icon: Icon(FluentIcons.calendar_month_20_regular),
      checkedIcon: Icon(FluentIcons.calendar_month_20_filled),
      child: Text('Subtle'),
    ),
    _ToggleButton(
      appearance: FluentButtonAppearance.transparent,
      icon: Icon(FluentIcons.calendar_month_20_regular),
      checkedIcon: Icon(FluentIcons.calendar_month_20_filled),
      child: Text('Transparent'),
    ),
  ],
);
// #enddocregion components-button-togglebutton--appearance

// #docregion components-button-togglebutton--accessible-appearance
// _ToggleButton is the composed toggle button defined in the Default section.
// Our FluentButton has no isAccessible axis — there is one set of checked
// tokens, not two — so these are the same colours the Appearance section shows.
Widget _accessibleAppearance(BuildContext context) => const Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    _ToggleButton(child: Text('Default')),
    _ToggleButton(
      appearance: FluentButtonAppearance.primary,
      child: Text('Primary'),
    ),
    _ToggleButton(
      appearance: FluentButtonAppearance.outline,
      child: Text('Outline'),
    ),
    _ToggleButton(
      appearance: FluentButtonAppearance.subtle,
      child: Text('Subtle'),
    ),
    _ToggleButton(
      appearance: FluentButtonAppearance.transparent,
      child: Text('Transparent'),
    ),
  ],
);
// #enddocregion components-button-togglebutton--accessible-appearance

// #docregion components-button-togglebutton--icon
// _ToggleButton is the composed toggle button defined in the Default section.
// The icon-only button carries its label in a tooltip, so it also passes a
// semanticLabel — a tooltip is not announced on its own.
Widget _icon(BuildContext context) => const Wrap(
  spacing: 15,
  runSpacing: 15,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    _ToggleButton(
      icon: Icon(FluentIcons.calendar_month_20_regular),
      checkedIcon: Icon(FluentIcons.calendar_month_20_filled),
      child: Text('With calendar icon before contents'),
    ),
    _ToggleButton(
      icon: Icon(FluentIcons.calendar_month_20_regular),
      checkedIcon: Icon(FluentIcons.calendar_month_20_filled),
      iconPosition: FluentButtonIconPosition.after,
      child: Text('With calendar icon after contents'),
    ),
    FluentTooltip(
      content: Text('With calendar icon only'),
      semanticLabel: 'With calendar icon only',
      child: _ToggleButton(
        icon: Icon(FluentIcons.calendar_month_20_regular),
        checkedIcon: Icon(FluentIcons.calendar_month_20_filled),
        semanticLabel: 'With calendar icon only',
      ),
    ),
  ],
);
// #enddocregion components-button-togglebutton--icon

// #docregion components-button-togglebutton--size
// _ToggleButton is the composed toggle button defined in the Default section.
Widget _size(BuildContext context) => const Wrap(
  spacing: 15,
  runSpacing: 15,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    _ToggleButton(size: FluentButtonSize.small, child: Text('Size: small')),
    _ToggleButton(size: FluentButtonSize.medium, child: Text('Size: medium')),
    _ToggleButton(size: FluentButtonSize.large, child: Text('Size: large')),
  ],
);
// #enddocregion components-button-togglebutton--size

// #docregion components-button-togglebutton--disabled
// _ToggleButton is the composed toggle button defined in the Default section.
// Disabled is a real state in FluentButton: it refuses focus. There is no
// disabledFocusable, so the third button in each row renders as plain disabled.
Widget _disabled(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  spacing: 15,
  children: <Widget>[
    Wrap(
      spacing: 15,
      runSpacing: 15,
      children: <Widget>[
        _ToggleButton(child: Text('Enabled state')),
        _ToggleButton(enabled: false, child: Text('Disabled state')),
        _ToggleButton(enabled: false, child: Text('Disabled focusable state')),
      ],
    ),
    Wrap(
      spacing: 15,
      runSpacing: 15,
      children: <Widget>[
        _ToggleButton(
          appearance: FluentButtonAppearance.primary,
          child: Text('Enabled state'),
        ),
        _ToggleButton(
          appearance: FluentButtonAppearance.primary,
          enabled: false,
          child: Text('Disabled state'),
        ),
        _ToggleButton(
          appearance: FluentButtonAppearance.primary,
          enabled: false,
          child: Text('Disabled focusable state'),
        ),
      ],
    ),
  ],
);
// #enddocregion components-button-togglebutton--disabled

// #docregion components-button-togglebutton--checked
// _ToggleButton is the composed toggle button defined in the Default section.
// Passing checked makes it controlled: pressing these two changes nothing.
Widget _checked(BuildContext context) => const Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    _ToggleButton(checked: true, child: Text('Controlled checked state')),
    _ToggleButton(checked: false, child: Text('Controlled unchecked state')),
  ],
);
// #enddocregion components-button-togglebutton--checked

// #docregion components-button-togglebutton--with-long-text
// _ToggleButton is the composed toggle button defined in the Default section.
// The label goes in a Flexible because it lands directly in the button's Row,
// where an unconstrained Text would overflow instead of wrapping.
Widget _withLongText(BuildContext context) => const Wrap(
  spacing: 15,
  runSpacing: 15,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    _ToggleButton(child: Text('Short text')),
    SizedBox(
      width: 280,
      child: _ToggleButton(
        child: Flexible(
          child: Text(
            'Long text wraps after it hits the max width of the component',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  ],
);
// #enddocregion components-button-togglebutton--with-long-text
