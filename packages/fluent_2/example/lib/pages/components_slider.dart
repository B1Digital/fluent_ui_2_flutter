import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Slider docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage sliderPage = DocsPage(
  id: 'components-slider',
  title: 'Slider',
  description:
      'A Slider represents an input that allows user to choose a value from '
      'within a specific range.',
  source: 'lib/pages/components_slider.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-slider--default',
      title: 'Default',
      description: 'A default slider',
      builder: _default,
    ),
    DocsSection(
      id: 'components-slider--size',
      title: 'Size',
      description:
          'A slider comes in both medium and small size. Medium is the default.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-slider--controlled',
      title: 'Controlled',
      description:
          'A slider can be a controlled input where the slider value is stored '
          'in state and updated with onChange. This is also useful for setting '
          'custom aria-valuetext',
      builder: _controlled,
    ),
    DocsSection(
      id: 'components-slider--step',
      title: 'Step',
      description:
          'You can define the step value of a slider so that the value will '
          'always be a mutiple of that step',
      builder: _step,
    ),
    DocsSection(
      id: 'components-slider--min-max',
      title: 'Min Max',
      description: 'A slider with min and max values displayed',
      builder: _minMax,
    ),
    DocsSection(
      id: 'components-slider--vertical',
      title: 'Vertical',
      description:
          'A slider can be oriented vertically where the max value is at the '
          'top of the slider.',
      builder: _vertical,
    ),
    DocsSection(
      id: 'components-slider--disabled',
      title: 'Disabled',
      description:
          'A disabled slider will not change or fire events on click or '
          'keyboard press.',
      builder: _disabled,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'value',
      type: 'double',
      description: 'The current value. Clamped into min…max for rendering.',
    ),
    PropRow(
      name: 'onChanged',
      type: 'ValueChanged<double>?',
      defaultValue: 'null',
      description:
          'Called with the value a drag or a key landed on. Null disables the '
          'slider.',
    ),
    PropRow(
      name: 'min',
      type: 'double',
      defaultValue: '0',
      description: 'The value at the start of the rail.',
    ),
    PropRow(
      name: 'max',
      type: 'double',
      defaultValue: '100',
      description: 'The value at the end of the rail.',
    ),
    PropRow(
      name: 'step',
      type: 'double?',
      defaultValue: 'null',
      description:
          'The interval between selectable values. Null leaves the rail '
          'continuous and unticked.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentSliderSize',
      defaultValue: 'FluentSliderSize.medium',
      description: 'Thumb diameter and rail thickness.',
    ),
    PropRow(
      name: 'semanticFormatter',
      type: 'String Function(double value)?',
      defaultValue: 'null',
      description: 'Formats a value for assistive technology.',
    ),
  ],
);

// #docregion components-slider--default
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  // Upstream's `defaultValue`: FluentSlider is controlled, so the demo owns it.
  double _value = 20;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const FluentLabel(child: Text('Basic Example')),
      SizedBox(
        width: 120,
        child: FluentSlider(
          value: _value,
          semanticLabel: 'Basic Example',
          onChanged: (double value) => setState(() => _value = value),
        ),
      ),
    ],
  );
}
// #enddocregion components-slider--default

// #docregion components-slider--size
Widget _size(BuildContext context) => const _Size();

class _Size extends StatefulWidget {
  const _Size();

  @override
  State<_Size> createState() => _SizeState();
}

class _SizeState extends State<_Size> {
  double _medium = 20;
  double _small = 20;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const FluentLabel(child: Text('Medium Slider')),
      SizedBox(
        width: 120,
        child: FluentSlider(
          value: _medium,
          semanticLabel: 'Medium Slider',
          onChanged: (double value) => setState(() => _medium = value),
        ),
      ),
      const FluentLabel(child: Text('Small Slider')),
      SizedBox(
        width: 120,
        child: FluentSlider(
          size: FluentSliderSize.small,
          value: _small,
          semanticLabel: 'Small Slider',
          onChanged: (double value) => setState(() => _small = value),
        ),
      ),
    ],
  );
}
// #enddocregion components-slider--size

// #docregion components-slider--controlled
Widget _controlled(BuildContext context) => const _Controlled();

class _Controlled extends StatefulWidget {
  const _Controlled();

  @override
  State<_Controlled> createState() => _ControlledState();
}

class _ControlledState extends State<_Controlled> {
  double _sliderValue = 160;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentLabel(
        child: Text(
          'Control Slider [ Current Value: ${_sliderValue.round()} ]',
        ),
      ),
      SizedBox(
        width: 120,
        child: FluentSlider(
          value: _sliderValue,
          min: 20,
          max: 200,
          // Upstream's `aria-valuetext`.
          semanticFormatter: (double value) => 'Value is ${value.round()}',
          onChanged: (double value) => setState(() => _sliderValue = value),
        ),
      ),
      FluentButton(
        onPressed: () => setState(() => _sliderValue = 0),
        child: const Text('Reset'),
      ),
    ],
  );
}
// #enddocregion components-slider--controlled

// #docregion components-slider--step
Widget _step(BuildContext context) => const _Step();

class _Step extends StatefulWidget {
  const _Step();

  @override
  State<_Step> createState() => _StepState();
}

class _StepState extends State<_Step> {
  double _value = 6;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const FluentLabel(child: Text('Step Example')),
      SizedBox(
        width: 120,
        child: FluentSlider(
          value: _value,
          step: 3,
          min: 0,
          max: 12,
          semanticLabel: 'Step Example',
          onChanged: (double value) => setState(() => _value = value),
        ),
      ),
    ],
  );
}
// #enddocregion components-slider--step

// #docregion components-slider--min-max
Widget _minMax(BuildContext context) => const _MinMax();

class _MinMax extends StatefulWidget {
  const _MinMax();

  @override
  State<_MinMax> createState() => _MinMaxState();
}

class _MinMaxState extends State<_MinMax> {
  double _value = 20;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const FluentLabel(child: Text('Min/Max Example')),
      // Upstream's `wrapper`: display flex, align-items center.
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const ExcludeSemantics(child: FluentLabel(child: Text('10'))),
          SizedBox(
            width: 120,
            child: FluentSlider(
              min: 10,
              max: 50,
              value: _value,
              semanticLabel: 'Min/Max Example',
              onChanged: (double value) => setState(() => _value = value),
            ),
          ),
          const ExcludeSemantics(child: FluentLabel(child: Text('50'))),
        ],
      ),
    ],
  );
}
// #enddocregion components-slider--min-max

// #docregion components-slider--vertical
Widget _vertical(BuildContext context) => const _Vertical();

class _Vertical extends StatefulWidget {
  const _Vertical();

  @override
  State<_Vertical> createState() => _VerticalState();
}

class _VerticalState extends State<_Vertical> {
  double _value = 6;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      const FluentLabel(child: Text('Vertical Example')),
      // FluentSlider has no `vertical` flag, so the horizontal rail is turned a
      // quarter turn anticlockwise — which puts the max at the top, as upstream
      // documents. Dragging and the arrow keys keep working through the
      // rotation; only the flag is missing.
      SizedBox(
        width: 24,
        height: 120,
        child: RotatedBox(
          quarterTurns: 3,
          child: FluentSlider(
            step: 2,
            value: _value,
            min: 0,
            max: 10,
            semanticLabel: 'Vertical Example',
            onChanged: (double value) => setState(() => _value = value),
          ),
        ),
      ),
    ],
  );
}
// #enddocregion components-slider--vertical

// #docregion components-slider--disabled
// A slider with no `onChanged` is disabled: nothing to change, nothing to fire.
Widget _disabled(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    FluentLabel(child: Text('Disabled Example')),
    SizedBox(
      width: 120,
      child: FluentSlider(value: 30, semanticLabel: 'Disabled Example'),
    ),
  ],
);
// #enddocregion components-slider--disabled
