import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Input docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage inputPage = DocsPage(
  id: 'components-input',
  title: 'Input',
  description: 'Input allows the user to enter and edit text.',
  source: 'lib/pages/components_input.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-input--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-input--appearance',
      title: 'Appearance',
      description:
          'An input can have different appearances. The colors adjacent to the '
          'input should have a sufficient contrast. Particularly, the color of '
          'input with filled darker and lighter styles needs to provide greater '
          'than 3 to 1 contrast ratio against the immediate surrounding color '
          'to pass accessibility requirements.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-input--content-before-after',
      title: 'Content before/after',
      description:
          'An input can have elements such as an icon or a button before or '
          'after the entered text. These elements are displayed inside the '
          'input border.',
      builder: _contentBeforeAfter,
    ),
    DocsSection(
      id: 'components-input--disabled',
      title: 'Disabled',
      description: 'An input can be disabled.',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-input--inline',
      title: 'Inline',
      description: 'An input can be rendered inline with text.',
      builder: _inline,
    ),
    DocsSection(
      id: 'components-input--placeholder',
      title: 'Placeholder',
      description:
          'An input can have placeholder text. If using the placeholder as a '
          'label (which is not recommended for usability), be sure to provide '
          'an aria-label for screen reader users.',
      builder: _placeholder,
    ),
    DocsSection(
      id: 'components-input--size',
      title: 'Size',
      description: 'An input can have different sizes.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-input--type',
      title: 'Type',
      description:
          'An input can have a custom text-based type such as email, url, or '
          'password based on the type of value the user will enter. Note that '
          'no custom styling is currently applied for alternative types, and '
          'some types may activate browser-default styling which does not match '
          'the Fluent design language.',
      builder: _type,
    ),
    DocsSection(
      id: 'components-input--uncontrolled',
      title: 'Uncontrolled',
      description:
          'By default, an input is uncontrolled: it tracks all updates '
          'internally. You can optionally provide a default value.',
      builder: _uncontrolled,
    ),
    DocsSection(
      id: 'components-input--controlled',
      title: 'Controlled',
      description:
          "An input can be controlled: the consuming component tracks the "
          "input's value in its state and manually handles all updates.",
      builder: _controlled,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'controller',
      type: 'TextEditingController?',
      defaultValue: 'null',
      description:
          'The value being edited. One is created internally when omitted.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentInputAppearance',
      defaultValue: 'FluentInputAppearance.outline',
      description: 'Fill and outline treatment.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentInputSize',
      defaultValue: 'FluentInputSize.medium',
      description: 'Height and type ramp.',
    ),
    PropRow(
      name: 'placeholder',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'Shown while the value is empty.',
    ),
    PropRow(
      name: 'contentBefore',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'Slot before the field in reading order — an icon, a prefix, a '
          'button.',
    ),
    PropRow(
      name: 'contentAfter',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'Slot after the field in reading order.',
    ),
    PropRow(
      name: 'enabled',
      type: 'bool',
      defaultValue: 'true',
      description:
          'Whether the field accepts input. False is a real disabled state.',
    ),
    PropRow(
      name: 'readOnly',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether the value can be selected and copied but not edited.',
    ),
    PropRow(
      name: 'error',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether to paint the validation-error treatment.',
    ),
    PropRow(
      name: 'obscureText',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether characters are replaced by the obscuring character.',
    ),
    PropRow(
      name: 'keyboardType',
      type: 'TextInputType?',
      defaultValue: 'null',
      description: 'Which soft keyboard to request.',
    ),
    PropRow(
      name: 'onChanged',
      type: 'ValueChanged<String>?',
      defaultValue: 'null',
      description: 'Invoked on every edit.',
    ),
    PropRow(
      name: 'onSubmitted',
      type: 'ValueChanged<String>?',
      defaultValue: 'null',
      description: 'Invoked when the action key is pressed.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description:
          'Announced by assistive technology. Use it when no visible label '
          'names the field — a placeholder is not a label.',
    ),
  ],
);

// #docregion components-input--default
Widget _default(BuildContext context) => ConstrainedBox(
  // Prevent the example from taking the full width of the page (optional)
  constraints: const BoxConstraints(maxWidth: 400),
  child: const Column(
    // Stack the label above the field, with a 2px gap (per the design system)
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 2,
    children: <Widget>[
      FluentLabel(child: Text('Sample input')),
      FluentInput(),
    ],
  ),
);
// #enddocregion components-input--default

// #docregion components-input--appearance
Widget _appearance(BuildContext context) {
  final FluentColors colors = FluentTheme.of(context).colors;

  // Upstream paints the two filled fields onto an inverted surface so the
  // contrast note in the description is visible. Container is the griffel
  // `.field` / `.filledLighter` rule translated to Flutter layout.
  Widget field(
    String label,
    FluentInputAppearance appearance, {
    bool inverted = false,
  }) => Container(
    color: inverted ? colors.neutralBackgroundInverted : null,
    margin: const EdgeInsets.only(top: FluentSpacing.mNudge),
    padding: const EdgeInsets.all(FluentSpacing.mNudge),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        FluentLabel(
          style: inverted
              ? FluentLabelStyle.from(
                  foregroundColor: colors.neutralForegroundInverted2,
                )
              : null,
          child: Text(label),
        ),
        FluentInput(appearance: appearance),
      ],
    ),
  );

  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        field('Outline appearance (default)', FluentInputAppearance.outline),
        field('Underline appearance', FluentInputAppearance.underline),
        field(
          'Filled lighter appearance',
          FluentInputAppearance.filledLighter,
          inverted: true,
        ),
        field(
          'Filled darker appearance',
          FluentInputAppearance.filledDarker,
          inverted: true,
        ),
      ],
    ),
  );
}
// #enddocregion components-input--appearance

// #docregion components-input--content-before-after
Widget _contentBeforeAfter(BuildContext context) {
  Widget field(String label, Widget input, String caption) => Column(
    // Stack the label above the field (with 2px gap per the design system)
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: FluentSpacing.xxs,
    children: <Widget>[
      FluentLabel(child: Text(label)),
      input,
      Text(caption, style: FluentTheme.of(context).typography.body1),
    ],
  );

  return ConstrainedBox(
    // Prevent the example from taking the full width of the page (optional)
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 20,
      children: <Widget>[
        field(
          'Full name',
          const FluentInput(contentBefore: Icon(FluentIcons.person_20_regular)),
          'An input with a decorative icon in the contentBefore slot.',
        ),
        field(
          'First name',
          FluentInput(
            contentAfter: FluentButton.icon(
              icon: const Icon(FluentIcons.mic_20_regular),
              semanticLabel: 'Enter by voice',
              appearance: FluentButtonAppearance.transparent,
              size: FluentButtonSize.small,
              onPressed: () {},
            ),
          ),
          'An input with a button in the contentAfter slot.',
        ),
        field(
          'Amount to pay',
          const FluentInput(
            contentBefore: Text(r'$'),
            contentAfter: Text('.00'),
            semanticLabel: 'Amount to pay',
          ),
          'An input with a presentational value in the contentBefore slot and '
              'another presentational value in the contentAfter slot.',
        ),
      ],
    ),
  );
}
// #enddocregion components-input--content-before-after

// #docregion components-input--disabled
Widget _disabled(BuildContext context) => const _Disabled();

class _Disabled extends StatefulWidget {
  const _Disabled();

  @override
  State<_Disabled> createState() => _DisabledState();
}

class _DisabledState extends State<_Disabled> {
  // `FluentInput` has no `defaultValue`; an uncontrolled field seeded with a
  // value is a controller the demo owns and disposes.
  final TextEditingController _outline = TextEditingController(
    text: 'disabled value',
  );
  final TextEditingController _underline = TextEditingController(
    text: 'disabled value',
  );
  final TextEditingController _filledLighter = TextEditingController(
    text: 'disabled value',
  );
  final TextEditingController _filledDarker = TextEditingController(
    text: 'disabled value',
  );

  bool _disabled = true;

  @override
  void dispose() {
    _outline.dispose();
    _underline.dispose();
    _filledLighter.dispose();
    _filledDarker.dispose();
    super.dispose();
  }

  Widget _field(
    String label,
    FluentInputAppearance appearance,
    TextEditingController controller, {
    bool inverted = false,
  }) {
    final FluentColors colors = FluentTheme.of(context).colors;
    return Container(
      color: inverted ? colors.neutralBackgroundInverted : null,
      margin: const EdgeInsets.only(top: FluentSpacing.mNudge),
      padding: const EdgeInsets.all(FluentSpacing.mNudge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.xxs,
        children: <Widget>[
          FluentLabel(
            style: inverted
                ? FluentLabelStyle.from(
                    foregroundColor: colors.neutralForegroundInverted2,
                  )
                : null,
            child: Text(label),
          ),
          FluentInput(
            appearance: appearance,
            controller: controller,
            enabled: !_disabled,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _field(
          'Disabled (default outline appearance)',
          FluentInputAppearance.outline,
          _outline,
        ),
        _field(
          'Disabled (underline appearance)',
          FluentInputAppearance.underline,
          _underline,
        ),
        _field(
          'Disabled (filled lighter appearance)',
          FluentInputAppearance.filledLighter,
          _filledLighter,
          inverted: true,
        ),
        _field(
          'Disabled (filled darker appearance)',
          FluentInputAppearance.filledDarker,
          _filledDarker,
          inverted: true,
        ),
        Padding(
          padding: const EdgeInsets.only(top: FluentSpacing.xl),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FluentSwitch(
              checked: _disabled,
              label: const Text('Disabled'),
              onChanged: (bool value) => setState(() => _disabled = value),
            ),
          ),
        ),
      ],
    ),
  );
}
// #enddocregion components-input--disabled

// #docregion components-input--inline
// An inline `<input>` sizes itself from the browser's default field width;
// Flutter's field fills whatever box it is given, so each inline field is
// given an explicit width instead.
Widget _inline(BuildContext context) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  spacing: FluentSpacing.m,
  children: <Widget>[
    const Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: EdgeInsetsDirectional.only(end: 12),
          child: FluentLabel(child: Text('Sample inline input')),
        ),
        SizedBox(width: 160, child: FluentInput()),
      ],
    ),
    Text.rich(
      const TextSpan(
        children: <InlineSpan>[
          TextSpan(text: 'This input is '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SizedBox(
              width: 160,
              child: FluentInput(
                placeholder: Text('inline'),
                semanticLabel: 'inline',
              ),
            ),
          ),
          TextSpan(
            text:
                ' within a paragraph of text (be sure to provide an aria-label).',
          ),
        ],
      ),
      style: FluentTheme.of(context).typography.body1,
    ),
  ],
);
// #enddocregion components-input--inline

// #docregion components-input--placeholder
Widget _placeholder(BuildContext context) => ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 300),
  child: const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 5,
    children: <Widget>[
      FluentLabel(child: Text('Input with a placeholder')),
      FluentInput(placeholder: Text('This is a placeholder')),
    ],
  ),
);
// #enddocregion components-input--placeholder

// #docregion components-input--size
Widget _size(BuildContext context) {
  Widget field(String label, FluentLabelSize labelSize, FluentInputSize size) =>
      Column(
        // Stack the label above the field (with 2px gap per the design system)
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.xxs,
        children: <Widget>[
          FluentLabel(size: labelSize, child: Text(label)),
          FluentInput(size: size),
        ],
      );

  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 20,
      children: <Widget>[
        field('Small input', FluentLabelSize.small, FluentInputSize.small),
        field('Medium input', FluentLabelSize.medium, FluentInputSize.medium),
        field('Large input', FluentLabelSize.large, FluentInputSize.large),
      ],
    ),
  );
}
// #enddocregion components-input--size

// #docregion components-input--type
Widget _type(BuildContext context) => const _Type();

class _Type extends StatefulWidget {
  const _Type();

  @override
  State<_Type> createState() => _TypeState();
}

class _TypeState extends State<_Type> {
  // HTML's `type` is two independent things in Flutter: `keyboardType` picks
  // the soft keyboard, `obscureText` masks the value. There is no single
  // `type` field to set.
  final TextEditingController _password = TextEditingController(
    text: 'password',
  );

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Widget _field(String label, Widget input) => Column(
    // Stack the label above the field (with 2px gap per the design system)
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: FluentSpacing.xxs,
    children: <Widget>[
      FluentLabel(child: Text(label)),
      input,
    ],
  );

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 20,
      children: <Widget>[
        _field(
          'Email input',
          const FluentInput(keyboardType: TextInputType.emailAddress),
        ),
        _field('URL input', const FluentInput(keyboardType: TextInputType.url)),
        _field(
          'Password input',
          FluentInput(controller: _password, obscureText: true),
        ),
      ],
    ),
  );
}
// #enddocregion components-input--type

// #docregion components-input--uncontrolled
Widget _uncontrolled(BuildContext context) => const _Uncontrolled();

class _Uncontrolled extends StatefulWidget {
  const _Uncontrolled();

  @override
  State<_Uncontrolled> createState() => _UncontrolledState();
}

class _UncontrolledState extends State<_Uncontrolled> {
  // `FluentInput` has no `defaultValue`; seeding the value is a controller the
  // demo owns and disposes. The field still tracks its own updates.
  final TextEditingController _controller = TextEditingController(
    text: 'default value',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    // Prevent the example from taking the full width of the page (optional)
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      // Stack the label above the field, with a 2px gap (per the design system)
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        const FluentLabel(child: Text('Uncontrolled input with default value')),
        FluentInput(
          controller: _controller,
          onChanged: (String value) {
            // Uncontrolled inputs can be notified of changes to the value
            debugPrint('New value: "$value"');
          },
        ),
      ],
    ),
  );
}
// #enddocregion components-input--uncontrolled

// #docregion components-input--controlled
Widget _controlled(BuildContext context) => const _Controlled();

class _Controlled extends StatefulWidget {
  const _Controlled();

  @override
  State<_Controlled> createState() => _ControlledState();
}

class _ControlledState extends State<_Controlled> {
  String _value = 'initial value';

  late final TextEditingController _controller = TextEditingController(
    text: _value,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // The controlled input pattern can be used for other purposes besides
    // validation, but validation is a useful example
    if (value.length <= 20) {
      _value = value;
      return;
    }
    // Flutter's field has already applied the edit, so rejecting it means
    // putting the accepted value back.
    _controller.value = TextEditingValue(
      text: _value,
      selection: TextSelection.collapsed(offset: _value.length),
    );
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    // Prevent the example from taking the full width of the page (optional)
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      // Use 2px gap below the label (per the design system)
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        const FluentLabel(
          child: Text('Controlled input limiting the value to 20 characters'),
        ),
        FluentInput(controller: _controller, onChanged: _onChanged),
      ],
    ),
  );
}

// #enddocregion components-input--controlled
