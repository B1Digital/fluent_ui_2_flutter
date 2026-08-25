import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The SpinButton docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage spinButtonPage = DocsPage(
  id: 'components-spinbutton',
  title: 'SpinButton',
  description:
      'SpinButtons are used to allow numerical and non-numerical input bounded '
      'between minimum and maximum values with buttons to increment and '
      'decrement the input value. Values can also be manipulated via the '
      'keyboard.',
  source: 'lib/pages/components_spinbutton.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-spinbutton--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-spinbutton--controlled',
      title: 'Controlled',
      description:
          'SpinButton can be a controlled input where the value and, '
          'optionally, the display value are stored in state and updated with '
          'onChange.',
      builder: _controlled,
    ),
    DocsSection(
      id: 'components-spinbutton--uncontrolled',
      title: 'Uncontrolled',
      description: 'An uncontrolled SpinButton',
      builder: _uncontrolled,
    ),
    DocsSection(
      id: 'components-spinbutton--bounds',
      title: 'Bounds',
      description:
          'SpinButton can be bounded with the min and max props. Using the spin '
          'buttons or hotkeys will clamp values in the range of [min, max]. '
          'Users may type a value outside the range into the text input and it '
          'will not be clamped by the control. Pressing the "home" key will set '
          'the value to min and pressing the "end" key will set the value to '
          'max when the props are set.',
      builder: _bounds,
    ),
    DocsSection(
      id: 'components-spinbutton--display-value',
      title: 'Display Value',
      description: 'SpinButton supports formatted display values.',
      builder: _displayValue,
    ),
    DocsSection(
      id: 'components-spinbutton--step',
      title: 'Step',
      description:
          'SpinButton step size can be set. Additionally stepPage can be set to '
          'a large value to allow bulk steps via the Page Up and Page Down '
          'keys.',
      builder: _step,
    ),
    DocsSection(
      id: 'components-spinbutton--size',
      title: 'Size',
      description: 'SpinButton can have different sizes.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-spinbutton--appearance',
      title: 'Appearance',
      description:
          'SpinButton can have different appearances. The colors adjacent to '
          'the input should have a sufficient contrast. Particularly, the color '
          'of input with filled darker and lighter styles needs to provide '
          'greater than 3 to 1 contrast ratio against the immediate surrounding '
          'color to pass accessibility requirements.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-spinbutton--disabled',
      title: 'Disabled',
      description: 'SpinButton can be disabled.',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-spinbutton--read-only',
      title: 'Read Only',
      description:
          'SpinButton can be read-only which prevents user input but still '
          'allows the component to be focused and read by assistive '
          'technologies. This is different from disabled, which prevents all '
          'interaction with the component.',
      builder: _readOnly,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'value',
      type: 'double?',
      description: 'The current value, or null for an empty field.',
    ),
    PropRow(
      name: 'onChanged',
      type: 'ValueChanged<double?>?',
      defaultValue: 'null',
      description:
          'Called with the value a step or a commit landed on, already clamped '
          'and rounded. Null disables the control.',
    ),
    PropRow(
      name: 'min',
      type: 'double?',
      defaultValue: 'null',
      description:
          'Lower bound, or null for unbounded. Home jumps here when it is set.',
    ),
    PropRow(
      name: 'max',
      type: 'double?',
      defaultValue: 'null',
      description:
          'Upper bound, or null for unbounded. End jumps here when it is set.',
    ),
    PropRow(
      name: 'step',
      type: 'double',
      defaultValue: '1',
      description:
          'Travel per Up or Down press. Also decides precision when that is '
          'null.',
    ),
    PropRow(
      name: 'pageStep',
      type: 'double',
      defaultValue: '1',
      description: 'Travel per PageUp or PageDown press.',
    ),
    PropRow(
      name: 'precision',
      type: 'int?',
      defaultValue: 'null',
      description: 'Decimal places the value is rounded and rendered to.',
    ),
    PropRow(
      name: 'displayValue',
      type: 'String?',
      defaultValue: 'null',
      description: 'Text to show instead of the formatted value.',
    ),
    PropRow(
      name: 'placeholder',
      type: 'String?',
      defaultValue: 'null',
      description: 'Text shown while the field is empty.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentSpinButtonAppearance',
      defaultValue: 'FluentSpinButtonAppearance.outline',
      description: 'Fill and outline treatment.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentSpinButtonSize',
      defaultValue: 'FluentSpinButtonSize.medium',
      description: 'Height and type ramp.',
    ),
    PropRow(
      name: 'readOnly',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the value can be read and focused but not changed.',
    ),
    PropRow(
      name: 'invalid',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether the value fails validation. Paints the danger border.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description: 'Announced by assistive technology alongside the value.',
    ),
    PropRow(
      name: 'onSubmitted',
      type: 'ValueChanged<double?>?',
      defaultValue: 'null',
      description:
          'Called with the committed value when the action key is pressed.',
    ),
  ],
);

// #docregion components-spinbutton--default
// `FluentSpinButton` is always controlled — it has no `defaultValue`, so the
// seed value lives in the demo's own state.
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  double? _value = 10;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 500),
    child: Column(
      // Stack the label above the field, with a 2px gap (per the design system)
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        const FluentLabel(child: Text('Default SpinButton')),
        FluentSpinButton(
          value: _value,
          min: 0,
          max: 20,
          semanticLabel: 'Default SpinButton',
          onChanged: (double? value) => setState(() => _value = value),
        ),
      ],
    ),
  );
}
// #enddocregion components-spinbutton--default

// #docregion components-spinbutton--controlled
Widget _controlled(BuildContext context) => const _Controlled();

class _Controlled extends StatefulWidget {
  const _Controlled();

  @override
  State<_Controlled> createState() => _ControlledState();
}

class _ControlledState extends State<_Controlled> {
  double? _spinButtonValue = 10;

  void _onSpinButtonChange(double? value) {
    // `onChanged` reports the committed value already parsed, clamped and
    // rounded, so there is no display string left to parse back into a number.
    debugPrint('onSpinButtonChange $value');
    setState(() => _spinButtonValue = value);
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 500),
    child: Column(
      // Stack the label above the field, with a 2px gap (per the design system)
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        const FluentLabel(child: Text('Controlled SpinButton')),
        FluentSpinButton(
          value: _spinButtonValue,
          semanticLabel: 'Controlled SpinButton',
          onChanged: _onSpinButtonChange,
        ),
      ],
    ),
  );
}
// #enddocregion components-spinbutton--controlled

// #docregion components-spinbutton--uncontrolled
// There is no uncontrolled `FluentSpinButton`: `value` is required and every
// commit is reported through `onChanged`. The nearest equivalent is a demo that
// owns the value itself, which is what an uncontrolled React SpinButton does
// internally.
Widget _uncontrolled(BuildContext context) => const _Uncontrolled();

class _Uncontrolled extends StatefulWidget {
  const _Uncontrolled();

  @override
  State<_Uncontrolled> createState() => _UncontrolledState();
}

class _UncontrolledState extends State<_Uncontrolled> {
  double? _value = 10;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 500),
    child: Column(
      // Stack the label above the field, with a 2px gap (per the design system)
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        const FluentLabel(child: Text('Uncontrolled SpinButton')),
        FluentSpinButton(
          value: _value,
          semanticLabel: 'Uncontrolled SpinButton',
          onChanged: (double? value) => setState(() => _value = value),
        ),
      ],
    ),
  );
}
// #enddocregion components-spinbutton--uncontrolled

// #docregion components-spinbutton--bounds
Widget _bounds(BuildContext context) => const _Bounds();

class _Bounds extends StatefulWidget {
  const _Bounds();

  @override
  State<_Bounds> createState() => _BoundsState();
}

class _BoundsState extends State<_Bounds> {
  double? _value = 10;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 500),
    child: Column(
      // Stack the label above the field, with a 2px gap (per the design system)
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        const FluentLabel(child: Text('Bounded SpinButton')),
        FluentSpinButton(
          value: _value,
          min: 0,
          max: 20,
          semanticLabel: 'Bounded SpinButton',
          onChanged: (double? value) => setState(() => _value = value),
        ),
        Text(
          'min: 0, max: 20',
          style: FluentTheme.of(context).typography.body1,
        ),
      ],
    ),
  );
}
// #enddocregion components-spinbutton--bounds

// #docregion components-spinbutton--display-value
Widget _displayValue(BuildContext context) => const _DisplayValue();

class _DisplayValue extends StatefulWidget {
  const _DisplayValue();

  @override
  State<_DisplayValue> createState() => _DisplayValueState();
}

class _DisplayValueState extends State<_DisplayValue> {
  static String _formatter(double value) => '\$${value.toStringAsFixed(0)}';

  double? _spinButtonValue = 1;
  String _spinButtonDisplayValue = _formatter(1);

  // `FluentSpinButton` has no `parser` slot — it commits with `double.tryParse`
  // and puts the committed value back when that fails, so typing "$15" is
  // rejected while typing "15" is accepted and re-formatted. Clearing the field
  // is the one path that reports no value, and that is where "(null)" shows.
  void _onSpinButtonChange(double? value) => setState(() {
    _spinButtonValue = value;
    _spinButtonDisplayValue = value == null ? '(null)' : _formatter(value);
  });

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 500),
    child: Column(
      // Stack the label above the field, with a 2px gap (per the design system)
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        const FluentLabel(child: Text('Display Value')),
        FluentSpinButton(
          value: _spinButtonValue,
          displayValue: _spinButtonDisplayValue,
          semanticLabel: 'Display Value',
          onChanged: _onSpinButtonChange,
        ),
      ],
    ),
  );
}
// #enddocregion components-spinbutton--display-value

// #docregion components-spinbutton--step
Widget _step(BuildContext context) => const _Step();

class _Step extends StatefulWidget {
  const _Step();

  @override
  State<_Step> createState() => _StepState();
}

class _StepState extends State<_Step> {
  double? _value = 10;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 500),
    child: Column(
      // Stack the label above the field, with a 2px gap (per the design system)
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        const FluentLabel(child: Text('Step Size')),
        // React's `stepPage` is `pageStep` here — same Page Up / Page Down jump.
        FluentSpinButton(
          value: _value,
          step: 2,
          pageStep: 20,
          semanticLabel: 'Step Size',
          onChanged: (double? value) => setState(() => _value = value),
        ),
      ],
    ),
  );
}
// #enddocregion components-spinbutton--step

// #docregion components-spinbutton--size
Widget _size(BuildContext context) => const _Size();

class _Size extends StatefulWidget {
  const _Size();

  @override
  State<_Size> createState() => _SizeState();
}

class _SizeState extends State<_Size> {
  double? _small;
  double? _medium;

  Widget _field(String label, Widget spinButton) => Column(
    // Stack the label above the field, with a 2px gap (per the design system)
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: FluentSpacing.xxs,
    children: <Widget>[
      FluentLabel(child: Text(label)),
      spinButton,
    ],
  );

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 500),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.mNudge,
      children: <Widget>[
        _field(
          'Small',
          FluentSpinButton(
            size: FluentSpinButtonSize.small,
            value: _small,
            semanticLabel: 'Small',
            onChanged: (double? value) => setState(() => _small = value),
          ),
        ),
        _field(
          'Medium (default)',
          FluentSpinButton(
            value: _medium,
            semanticLabel: 'Medium (default)',
            onChanged: (double? value) => setState(() => _medium = value),
          ),
        ),
      ],
    ),
  );
}
// #enddocregion components-spinbutton--size

// #docregion components-spinbutton--appearance
Widget _appearance(BuildContext context) => const _Appearance();

class _Appearance extends StatefulWidget {
  const _Appearance();

  @override
  State<_Appearance> createState() => _AppearanceState();
}

class _AppearanceState extends State<_Appearance> {
  final Map<FluentSpinButtonAppearance, double?> _values =
      <FluentSpinButtonAppearance, double?>{};

  // Upstream paints the two filled fields onto an inverted surface so the
  // contrast note in the description is visible. Container is the griffel
  // `.field` / `.filledLighter` rule translated to Flutter layout.
  Widget _field(
    String label,
    FluentSpinButtonAppearance appearance, {
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
          FluentSpinButton(
            appearance: appearance,
            value: _values[appearance],
            semanticLabel: label,
            onChanged: (double? value) =>
                setState(() => _values[appearance] = value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 500),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _field('Outline (default)', FluentSpinButtonAppearance.outline),
        _field('Underline', FluentSpinButtonAppearance.underline),
        _field(
          'Filled Lighter',
          FluentSpinButtonAppearance.filledLighter,
          inverted: true,
        ),
        _field(
          'Filled Darker',
          FluentSpinButtonAppearance.filledDarker,
          inverted: true,
        ),
      ],
    ),
  );
}
// #enddocregion components-spinbutton--appearance

// #docregion components-spinbutton--disabled
// A null `onChanged` is the disabled state: there is no separate `disabled`
// flag, because a spin button nobody can be told about cannot be changed.
Widget _disabled(BuildContext context) => ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 500),
  child: const Column(
    // Stack the label above the field, with a 2px gap (per the design system)
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: FluentSpacing.xxs,
    children: <Widget>[
      FluentLabel(child: Text('Disabled')),
      FluentSpinButton(value: null, semanticLabel: 'Disabled'),
    ],
  ),
);
// #enddocregion components-spinbutton--disabled

// #docregion components-spinbutton--read-only
Widget _readOnly(BuildContext context) => const _ReadOnly();

class _ReadOnly extends StatefulWidget {
  const _ReadOnly();

  @override
  State<_ReadOnly> createState() => _ReadOnlyState();
}

class _ReadOnlyState extends State<_ReadOnly> {
  double? _value;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 500),
    child: Column(
      // Stack the label above the field, with a 2px gap (per the design system)
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        const FluentLabel(child: Text('Read-Only')),
        // `onChanged` stays wired so the control is enabled and focusable;
        // `readOnly` is what stops the value from changing.
        FluentSpinButton(
          readOnly: true,
          value: _value,
          semanticLabel: 'Read-Only',
          onChanged: (double? value) => setState(() => _value = value),
        ),
      ],
    ),
  );
}

// #enddocregion components-spinbutton--read-only
