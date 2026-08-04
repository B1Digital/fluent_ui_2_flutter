import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

String _sizeLabel(FluentSliderSize size) => switch (size) {
  FluentSliderSize.medium => 'Medium',
  FluentSliderSize.small => 'Small',
};

/// Stories for `FluentSlider`.
final StorySection sliderStories = StorySection(
  component: 'Slider',
  description:
      'A slider picks one value out of a range by dragging a thumb along a '
      'rail, or by pressing the arrow keys.',
  stories: [
    Story(
      name: 'Default',
      description:
          'A continuous 0–100 slider. The knobs switch the two axes the '
          'component has: thumb size, and whether it accepts input at all.',
      knobs: const [
        OptionKnob<FluentSliderSize>(
          label: 'Size',
          id: 'size',
          initial: FluentSliderSize.medium,
          options: FluentSliderSize.values,
          labelOf: _sizeLabel,
        ),
        BoolKnob(label: 'Disabled', id: 'disabled'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _SliderDemo(
          label: 'Volume',
          size: knobs.get('size', FluentSliderSize.medium),
          enabled: !knobs.get('disabled', false),
          showValue: true,
        );
      },
    ),
    Story(
      name: 'Controlled',
      description:
          'The value lives in the caller, never in the slider: the readout and '
          'the reset button drive the same piece of state the drag does.',
      builder: (context) => const _SliderDemo(
        label: 'Brightness',
        initial: 30,
        showValue: true,
        showReset: true,
      ),
    ),
    Story(
      name: 'Min and max',
      description:
          'A range other than 0–100. Both ends are live knobs, so you can '
          'watch the thumb re-map onto a range that no longer contains its '
          'old value.',
      knobs: const [
        NumberKnob(
          label: 'Min',
          id: 'min',
          initial: -50,
          min: -100,
          max: 0,
          step: 10,
        ),
        NumberKnob(
          label: 'Max',
          id: 'max',
          initial: 50,
          min: 10,
          max: 100,
          step: 10,
        ),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _SliderDemo(
          label: 'Offset',
          initial: 0,
          min: knobs.get('min', -50.0),
          max: knobs.get('max', 50.0),
          showValue: true,
        );
      },
    ),
    Story(
      name: 'Step',
      description:
          'A step snaps every drag to the interval and notches the rail once '
          'per interval; the arrow keys then travel one step instead of one '
          'unit.',
      knobs: const [
        NumberKnob(
          label: 'Step',
          id: 'step',
          initial: 10,
          min: 5,
          max: 50,
          step: 5,
        ),
      ],
      builder: (context) => _SliderDemo(
        label: 'Zoom',
        step: KnobsScope.of(context).get('step', 10.0),
        showValue: true,
      ),
    ),
    Story(
      name: 'Sizes',
      description:
          'Medium and small side by side: the thumb and the rail both shrink, '
          'while the control keeps the same 24-high box.',
      builder: (context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.xl,
        children: [
          _SliderDemo(label: 'Medium'),
          _SliderDemo(label: 'Small', size: FluentSliderSize.small),
        ],
      ),
    ),
    Story(
      name: 'Disabled',
      description:
          'Omitting the change callback disables the slider — a real state, '
          'not a grey repaint: it refuses focus, drags and keys as well.',
      builder: (context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.xl,
        children: [
          _SliderDemo(label: 'Enabled'),
          _SliderDemo(label: 'Disabled', enabled: false),
        ],
      ),
    ),
  ],
);

/// One labelled slider that holds its own value, with an optional readout and
/// reset button.
///
/// A slider is controlled, so every story needs somewhere for the value to
/// live; one small stateful widget serves all of them.
class _SliderDemo extends StatefulWidget {
  const _SliderDemo({
    required this.label,
    this.initial = 50,
    this.min = 0,
    this.max = 100,
    this.step,
    this.size = FluentSliderSize.medium,
    this.enabled = true,
    this.showValue = false,
    this.showReset = false,
  });

  final String label;
  final double initial;
  final double min;
  final double max;
  final double? step;
  final FluentSliderSize size;
  final bool enabled;
  final bool showValue;
  final bool showReset;

  @override
  State<_SliderDemo> createState() => _SliderDemoState();
}

class _SliderDemoState extends State<_SliderDemo> {
  late double _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    // ponytail: clamp at build rather than in didUpdateWidget — the min/max
    // knobs are the only thing that moves the range, and the slider clamps for
    // rendering anyway.
    final value = _value.clamp(widget.min, widget.max).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.s,
      children: [
        FluentLabel(disabled: !widget.enabled, child: Text(widget.label)),
        SizedBox(
          width: 320,
          child: FluentSlider(
            value: value,
            min: widget.min,
            max: widget.max,
            step: widget.step,
            size: widget.size,
            semanticLabel: widget.label,
            onChanged: widget.enabled
                ? (next) => setState(() => _value = next)
                : null,
          ),
        ),
        if (widget.showValue)
          Text(
            '${value.round()}',
            style: theme.typography.body1.copyWith(
              color: theme.colors.neutralForeground2,
            ),
          ),
        if (widget.showReset)
          FluentButton(
            size: FluentButtonSize.small,
            onPressed: () => setState(() => _value = widget.initial),
            child: const Text('Reset'),
          ),
      ],
    );
  }
}
