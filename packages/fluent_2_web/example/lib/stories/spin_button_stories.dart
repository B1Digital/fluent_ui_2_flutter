import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for `FluentSpinButton`.
final StorySection spinButtonStories = StorySection(
  component: 'Spin button',
  description:
      'A numeric field with an up/down stepper column, for a value the reader '
      'nudges rather than types — a quantity, a percentage, a font size.',
  stories: <Story>[
    Story(
      name: 'Default',
      description:
          'A spin button holding a number, steppable by chevron, by Up and '
          'Down, and editable by typing. Every design axis is a knob.',
      knobs: <Knob<Object?>>[
        const OptionKnob<FluentSpinButtonAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentSpinButtonAppearance.outline,
          options: FluentSpinButtonAppearance.values,
          labelOf: _appearanceLabel,
        ),
        const OptionKnob<FluentSpinButtonSize>(
          label: 'Size',
          id: 'size',
          initial: FluentSpinButtonSize.medium,
          options: FluentSpinButtonSize.values,
          labelOf: _sizeLabel,
        ),
        const BoolKnob(label: 'Disabled', id: 'disabled'),
        const BoolKnob(label: 'Read only', id: 'readOnly'),
        const BoolKnob(label: 'Invalid', id: 'invalid'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _SpinButtonDemo(
          label: 'Quantity',
          initial: 10,
          appearance: knobs.get<FluentSpinButtonAppearance>(
            'appearance',
            FluentSpinButtonAppearance.outline,
          ),
          size: knobs.get<FluentSpinButtonSize>(
            'size',
            FluentSpinButtonSize.medium,
          ),
          enabled: !knobs.get<bool>('disabled', false),
          readOnly: knobs.get<bool>('readOnly', false),
          invalid: knobs.get<bool>('invalid', false),
        );
      },
    ),
    Story(
      name: 'Appearances',
      description:
          'The four fills: an outlined box, a rule-only underline, and the two '
          'filled treatments that sit on a neutral surface.',
      builder: (context) => const Wrap(
        spacing: FluentSpacing.xxl,
        runSpacing: FluentSpacing.l,
        children: <Widget>[
          _SpinButtonDemo(label: 'Outline', initial: 10),
          _SpinButtonDemo(
            label: 'Underline',
            initial: 10,
            appearance: FluentSpinButtonAppearance.underline,
          ),
          _SpinButtonDemo(
            label: 'Filled darker',
            initial: 10,
            appearance: FluentSpinButtonAppearance.filledDarker,
          ),
          _SpinButtonDemo(
            label: 'Filled lighter',
            initial: 10,
            appearance: FluentSpinButtonAppearance.filledLighter,
          ),
        ],
      ),
    ),
    Story(
      name: 'Sizes',
      description:
          'Medium is 32 high on the body ramp; small is 24 on the caption ramp, '
          'with a shorter stepper column to match.',
      builder: (context) => const Wrap(
        spacing: FluentSpacing.xxl,
        runSpacing: FluentSpacing.l,
        children: <Widget>[
          _SpinButtonDemo(label: 'Medium', initial: 10),
          _SpinButtonDemo(
            label: 'Small',
            initial: 10,
            size: FluentSpinButtonSize.small,
          ),
        ],
      ),
    ),
    Story(
      name: 'Bounds',
      description:
          'A minimum and a maximum clamp every step and every commit. Home '
          'jumps to the minimum and End to the maximum.',
      knobs: <Knob<Object?>>[
        const NumberKnob(
          label: 'Minimum',
          id: 'min',
          initial: 0,
          min: -20,
          max: 0,
        ),
        const NumberKnob(
          label: 'Maximum',
          id: 'max',
          initial: 10,
          min: 0,
          max: 20,
        ),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _SpinButtonDemo(
          label: 'Bounded',
          initial: 5,
          min: knobs.get<double>('min', 0),
          max: knobs.get<double>('max', 10),
        );
      },
    ),
    Story(
      name: 'Step and precision',
      description:
          'A step of five with a page step of twenty-five, beside a quarter '
          'step — whose two decimals the control infers from the step itself.',
      builder: (context) => const Wrap(
        spacing: FluentSpacing.xxl,
        runSpacing: FluentSpacing.l,
        children: <Widget>[
          _SpinButtonDemo(
            label: 'Step 5, page 25',
            initial: 50,
            step: 5,
            pageStep: 25,
          ),
          _SpinButtonDemo(label: 'Step 0.25', initial: 1, step: 0.25),
        ],
      ),
    ),
    Story(
      name: 'Display value',
      description:
          'The field can read as something other than a bare number. Typing a '
          'plain number still commits, and the formatted text comes back.',
      builder: (context) => const _SpinButtonDemo(
        label: 'Zoom',
        initial: 100,
        min: 25,
        max: 400,
        step: 25,
        format: _percent,
      ),
    ),
    Story(
      name: 'Placeholder',
      description:
          'An empty spin button shows its placeholder; clearing the text and '
          'committing reports a null value back.',
      builder: (context) =>
          const _SpinButtonDemo(label: 'Weight', placeholder: 'Optional'),
    ),
    Story(
      name: 'Read only',
      description:
          'Read-only keeps the value at full contrast and stays focusable and '
          'copyable — only the steppers and the keys go inert.',
      builder: (context) => const _SpinButtonDemo(
        label: 'Serving size',
        initial: 4,
        readOnly: true,
      ),
    ),
    Story(
      name: 'Disabled',
      description:
          'Disabled dims the value and refuses focus, which is what separates '
          'it from read-only.',
      builder: (context) => const Wrap(
        spacing: FluentSpacing.xxl,
        runSpacing: FluentSpacing.l,
        children: <Widget>[
          _SpinButtonDemo(label: 'Disabled', initial: 4, enabled: false),
          _SpinButtonDemo(
            label: 'Disabled, empty',
            placeholder: 'Optional',
            enabled: false,
          ),
        ],
      ),
    ),
    Story(
      name: 'Controlled',
      description:
          'The value lives outside the control: it reports what a step or a '
          'commit landed on, and renders whatever is passed back.',
      builder: (context) => const _ControlledSpinButtonDemo(),
    ),
  ],
);

String _appearanceLabel(FluentSpinButtonAppearance value) => switch (value) {
  FluentSpinButtonAppearance.outline => 'Outline',
  FluentSpinButtonAppearance.underline => 'Underline',
  FluentSpinButtonAppearance.filledDarker => 'Filled darker',
  FluentSpinButtonAppearance.filledLighter => 'Filled lighter',
};

String _sizeLabel(FluentSpinButtonSize value) => switch (value) {
  FluentSpinButtonSize.medium => 'Medium',
  FluentSpinButtonSize.small => 'Small',
};

/// Renders a percentage rather than a bare number. See the `Display value`
/// story.
String _percent(double? value) =>
    value == null ? '' : '${value.toStringAsFixed(0)}%';

/// A spin button that owns its value, optionally under a [FluentField] label.
///
/// The control is controlled — it never stores the number — so every story
/// needs a holder around it. This is that holder, with one constructor argument
/// per axis a story wants to vary.
class _SpinButtonDemo extends StatefulWidget {
  const _SpinButtonDemo({
    this.label,
    this.initial,
    this.min,
    this.max,
    this.step = 1,
    this.pageStep = 1,
    this.placeholder,
    this.format,
    this.appearance = FluentSpinButtonAppearance.outline,
    this.size = FluentSpinButtonSize.medium,
    this.enabled = true,
    this.readOnly = false,
    this.invalid = false,
  });

  final String? label;
  final double? initial;
  final double? min;
  final double? max;
  final double step;
  final double pageStep;
  final String? placeholder;
  final String Function(double? value)? format;
  final FluentSpinButtonAppearance appearance;
  final FluentSpinButtonSize size;
  final bool enabled;
  final bool readOnly;
  final bool invalid;

  @override
  State<_SpinButtonDemo> createState() => _SpinButtonDemoState();
}

class _SpinButtonDemoState extends State<_SpinButtonDemo> {
  late double? _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final spinButton = SizedBox(
      width: 180,
      child: FluentSpinButton(
        value: _value,
        min: widget.min,
        max: widget.max,
        step: widget.step,
        pageStep: widget.pageStep,
        placeholder: widget.placeholder,
        displayValue: widget.format?.call(_value),
        appearance: widget.appearance,
        size: widget.size,
        readOnly: widget.readOnly,
        invalid: widget.invalid,
        semanticLabel: widget.label,
        onChanged: widget.enabled
            ? (next) => setState(() => _value = next)
            : null,
      ),
    );

    final label = widget.label;
    if (label == null) return spinButton;
    return FluentField(
      label: Text(label),
      enabled: widget.enabled,
      size: widget.size == FluentSpinButtonSize.small
          ? FluentFieldSize.small
          : FluentFieldSize.medium,
      validationState: widget.invalid
          ? FluentFieldValidationState.error
          : FluentFieldValidationState.none,
      child: spinButton,
    );
  }
}

/// A spin button whose value is also shown and set from outside it.
class _ControlledSpinButtonDemo extends StatefulWidget {
  const _ControlledSpinButtonDemo();

  @override
  State<_ControlledSpinButtonDemo> createState() =>
      _ControlledSpinButtonDemoState();
}

class _ControlledSpinButtonDemoState extends State<_ControlledSpinButtonDemo> {
  double? _value = 8;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.l,
      children: <Widget>[
        FluentField(
          label: const Text('Columns'),
          child: SizedBox(
            width: 180,
            child: FluentSpinButton(
              value: _value,
              min: 1,
              max: 12,
              semanticLabel: 'Columns',
              onChanged: (next) => setState(() => _value = next),
            ),
          ),
        ),
        Text(
          _value == null ? 'No value' : 'Value: ${_value!.toStringAsFixed(0)}',
          style: theme.typography.body1.copyWith(
            color: theme.colors.neutralForeground2,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: FluentSpacing.s,
          children: <Widget>[
            FluentButton(
              onPressed: () => setState(() => _value = 1),
              child: const Text('Set to 1'),
            ),
            FluentButton(
              onPressed: () => setState(() => _value = 12),
              child: const Text('Set to 12'),
            ),
            FluentButton(
              appearance: FluentButtonAppearance.subtle,
              onPressed: () => setState(() => _value = null),
              child: const Text('Clear'),
            ),
          ],
        ),
      ],
    );
  }
}
