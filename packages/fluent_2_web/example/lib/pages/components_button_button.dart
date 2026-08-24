import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Button docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage buttonPage = DocsPage(
  id: 'components-button-button',
  folder: 'Button',
  title: 'Button',
  description: 'A button triggers an action or event when activated.',
  source: 'lib/pages/components_button_button.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-button-button--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-button-button--shape',
      title: 'Shape',
      description: 'A button can be rounded, circular, or square.',
      builder: _shape,
    ),
    DocsSection(
      id: 'components-button-button--appearance',
      title: 'Appearance',
      description:
          '- (undefined): the button appears with the default style\n'
          '- primary: emphasizes the button as a primary action.\n'
          '- outline: removes background styling.\n'
          '- subtle: minimizes emphasis to blend into the background until '
          'hovered or focused\n'
          '- transparent: removes background and border styling.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-button-button--icon',
      title: 'Icon',
      description:
          'Button has an icon slot that, if specified, renders an icon either '
          'before or after the children, as specified by the iconPosition prop.',
      builder: _icon,
    ),
    DocsSection(
      id: 'components-button-button--size',
      title: 'Size',
      description:
          'A button supports small, medium and large size. Default size is '
          'medium.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-button-button--disabled',
      title: 'Disabled',
      description:
          'A button can be disabled or disabledFocusable. disabledFocusable is '
          'used in scenarios where it is important to keep a consistent tab '
          'order for screen reader and keyboard users. The primary example of '
          'this pattern is when the disabled button is in a menu or a '
          'commandbar and is seldom used for standalone buttons.',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-button-button--loading',
      title: 'Loading',
      description:
          "You can customize a Button's contents and styles to simulate a "
          'convincing loading state.',
      builder: _loading,
    ),
    DocsSection(
      id: 'components-button-button--with-long-text',
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

// #docregion components-button-button--default
Widget _default(BuildContext context) =>
    FluentButton(onPressed: () {}, child: const Text('Example'));
// #enddocregion components-button-button--default

// #docregion components-button-button--shape
Widget _shape(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentButton(onPressed: () {}, child: const Text('Rounded')),
    FluentButton(
      shape: FluentButtonShape.circular,
      onPressed: () {},
      child: const Text('Circular'),
    ),
    FluentButton(
      shape: FluentButtonShape.square,
      onPressed: () {},
      child: const Text('Square'),
    ),
  ],
);
// #enddocregion components-button-button--shape

// #docregion components-button-button--appearance
// Upstream bundles the filled and regular calendar icons so the glyph fills on
// hover. `icon` is a plain widget here, so every button keeps the regular one.
Widget _appearance(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentButton(
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      onPressed: () {},
      child: const Text('Default'),
    ),
    FluentButton(
      appearance: FluentButtonAppearance.primary,
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      onPressed: () {},
      child: const Text('Primary'),
    ),
    FluentButton(
      appearance: FluentButtonAppearance.outline,
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      onPressed: () {},
      child: const Text('Outline'),
    ),
    FluentButton(
      appearance: FluentButtonAppearance.subtle,
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      onPressed: () {},
      child: const Text('Subtle'),
    ),
    FluentButton(
      appearance: FluentButtonAppearance.transparent,
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      onPressed: () {},
      child: const Text('Transparent'),
    ),
  ],
);
// #enddocregion components-button-button--appearance

// #docregion components-button-button--icon
Widget _icon(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  children: <Widget>[
    FluentButton(
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      onPressed: () {},
      child: const Text('With calendar icon before contents'),
    ),
    FluentButton(
      icon: const Icon(FluentIcons.calendar_month_20_regular),
      iconPosition: FluentButtonIconPosition.after,
      onPressed: () {},
      child: const Text('With calendar icon after contents'),
    ),
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
// #enddocregion components-button-button--icon

// #docregion components-button-button--size
Widget _size(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    Wrap(
      spacing: 15,
      runSpacing: 15,
      children: <Widget>[
        FluentButton(
          size: FluentButtonSize.small,
          onPressed: () {},
          child: const Text('Small'),
        ),
        FluentButton(
          size: FluentButtonSize.small,
          icon: const Icon(FluentIcons.calendar_month_20_regular),
          onPressed: () {},
          child: const Text('Small with calendar icon'),
        ),
        FluentTooltip(
          content: const Text('Small with calendar icon only'),
          child: FluentButton.icon(
            size: FluentButtonSize.small,
            icon: const Icon(FluentIcons.calendar_month_20_regular),
            semanticLabel: 'Small with calendar icon only',
            onPressed: () {},
          ),
        ),
      ],
    ),
    const SizedBox(height: 15),
    Wrap(
      spacing: 15,
      runSpacing: 15,
      children: <Widget>[
        FluentButton(onPressed: () {}, child: const Text('Medium')),
        FluentButton(
          icon: const Icon(FluentIcons.calendar_month_20_regular),
          onPressed: () {},
          child: const Text('Medium with calendar icon'),
        ),
        FluentTooltip(
          content: const Text('Medium with calendar icon only'),
          child: FluentButton.icon(
            icon: const Icon(FluentIcons.calendar_month_20_regular),
            semanticLabel: 'Medium with calendar icon only',
            onPressed: () {},
          ),
        ),
      ],
    ),
    const SizedBox(height: 15),
    Wrap(
      spacing: 15,
      runSpacing: 15,
      children: <Widget>[
        FluentButton(
          size: FluentButtonSize.large,
          onPressed: () {},
          child: const Text('Large'),
        ),
        FluentButton(
          size: FluentButtonSize.large,
          icon: const Icon(FluentIcons.calendar_month_20_regular),
          onPressed: () {},
          child: const Text('Large with calendar icon'),
        ),
        FluentTooltip(
          content: const Text('Large with calendar icon only'),
          child: FluentButton.icon(
            size: FluentButtonSize.large,
            icon: const Icon(FluentIcons.calendar_month_20_regular),
            semanticLabel: 'Large with calendar icon only',
            onPressed: () {},
          ),
        ),
      ],
    ),
  ],
);
// #enddocregion components-button-button--size

// #docregion components-button-button--disabled
// A null `onPressed` is our disabled state, and it also refuses focus. Upstream's
// `disabledFocusable` — disabled, but still in the tab order — is a `Focus` node
// wrapped around the disabled button, which is the one thing the flag adds.
Widget _disabled(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    Wrap(
      spacing: 15,
      runSpacing: 15,
      children: <Widget>[
        FluentButton(onPressed: () {}, child: const Text('Enabled state')),
        const FluentButton(child: Text('Disabled state')),
        const Focus(
          child: FluentButton(child: Text('Disabled focusable state')),
        ),
      ],
    ),
    const SizedBox(height: 15),
    Wrap(
      spacing: 15,
      runSpacing: 15,
      children: <Widget>[
        FluentButton(
          appearance: FluentButtonAppearance.primary,
          onPressed: () {},
          child: const Text('Enabled state'),
        ),
        const FluentButton(
          appearance: FluentButtonAppearance.primary,
          child: Text('Disabled state'),
        ),
        const Focus(
          child: FluentButton(
            appearance: FluentButtonAppearance.primary,
            child: Text('Disabled focusable state'),
          ),
        ),
      ],
    ),
  ],
);
// #enddocregion components-button-button--disabled

// #docregion components-button-button--loading
Widget _loading(BuildContext context) => const _Loading();

enum _LoadingPhase { initial, loading, loaded }

class _Loading extends StatefulWidget {
  const _Loading();

  @override
  State<_Loading> createState() => _LoadingState();
}

class _LoadingState extends State<_Loading> {
  _LoadingPhase _phase = _LoadingPhase.initial;

  /// Bumped on every start and reset, so a reset makes the pending delay a
  /// no-op — the equivalent of upstream's `cancelTimeout`.
  int _run = 0;

  void _startLoading() {
    final int run = ++_run;
    setState(() => _phase = _LoadingPhase.loading);
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (!mounted || run != _run) return;
      setState(() => _phase = _LoadingPhase.loaded);
    });
  }

  void _resetLoadingState() {
    _run++;
    setState(() => _phase = _LoadingPhase.initial);
  }

  @override
  Widget build(BuildContext context) {
    final FluentColors colors = FluentTheme.of(context).colors;

    final String label = switch (_phase) {
      _LoadingPhase.loading => 'Loading',
      _LoadingPhase.loaded => 'Loaded',
      _LoadingPhase.initial => 'Start loading',
    };

    final Widget? icon = switch (_phase) {
      _LoadingPhase.loading => const FluentSpinner(
        size: FluentSpinnerSize.tiny,
      ),
      _LoadingPhase.loaded => Icon(
        FluentIcons.checkmark_20_filled,
        color: colors.statusSuccessForeground1,
      ),
      _LoadingPhase.initial => null,
    };

    // Once loading starts the button stops responding but keeps its resting
    // colours, so it reads as busy rather than as switched off.
    final FluentButtonStyle? style = _phase == _LoadingPhase.initial
        ? null
        : FluentButtonStyle(
            backgroundColor: WidgetStatePropertyAll<Color?>(
              colors.neutralBackground1,
            ),
            foregroundColor: WidgetStatePropertyAll<Color?>(
              colors.neutralForeground1,
            ),
            borderColor: WidgetStatePropertyAll<Color?>(colors.neutralStroke1),
            borderWidth: const WidgetStatePropertyAll<double?>(
              FluentStroke.thin,
            ),
          );

    return Wrap(
      spacing: 15,
      runSpacing: 15,
      children: <Widget>[
        FluentButton(
          onPressed: _phase == _LoadingPhase.initial ? _startLoading : null,
          style: style,
          icon: icon,
          child: Text(label),
        ),
        FluentButton(
          onPressed: _resetLoadingState,
          child: const Text('Reset loading state'),
        ),
      ],
    );
  }
}
// #enddocregion components-button-button--loading

// #docregion components-button-button--with-long-text
Widget _withLongText(BuildContext context) => Wrap(
  spacing: 15,
  runSpacing: 15,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: <Widget>[
    FluentButton(onPressed: () {}, child: const Text('Short text')),
    SizedBox(
      width: 280,
      child: FluentButton(
        onPressed: () {},
        // `Flexible`, because FluentButton lays its label out in a Row and a
        // Row gives non-flexible children unbounded width — so without this the
        // label runs past the 280px box instead of wrapping inside it. Upstream
        // needs no equivalent; its label is a block that wraps at max-width.
        child: const Flexible(
          child: Text(
            'Long text wraps after it hits the max width of the component',
          ),
        ),
      ),
    ),
  ],
);
// #enddocregion components-button-button--with-long-text
