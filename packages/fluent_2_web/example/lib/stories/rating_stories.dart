import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

String _sizeLabel(FluentRatingSize size) => switch (size) {
  FluentRatingSize.small => 'Small',
  FluentRatingSize.medium => 'Medium',
  FluentRatingSize.large => 'Large',
  FluentRatingSize.extraLarge => 'Extra large',
};

String _shapeLabel(FluentRatingShape shape) => switch (shape) {
  FluentRatingShape.star => 'Star',
  FluentRatingShape.circle => 'Circle',
  FluentRatingShape.square => 'Square',
};

String _colorLabel(FluentRatingColor color) => switch (color) {
  FluentRatingColor.neutral => 'Neutral',
  FluentRatingColor.brand => 'Brand',
  FluentRatingColor.marigold => 'Marigold',
};

/// Stories for `FluentRating`.
final StorySection ratingStories = StorySection(
  component: 'Rating',
  description:
      'A rating takes or reports a score as a row of shapes. Interactive by '
      'default — hover previews, click and the arrow keys commit — or inert '
      'with `FluentRatingType.display`.',
  stories: [
    Story(
      name: 'Default',
      description:
          'Five stars that take input. Hover to preview a value, click or use '
          'the arrow keys to commit it; every design axis is a live knob.',
      knobs: const [
        OptionKnob<FluentRatingSize>(
          label: 'Size',
          id: 'size',
          initial: FluentRatingSize.extraLarge,
          options: FluentRatingSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentRatingShape>(
          label: 'Shape',
          id: 'shape',
          initial: FluentRatingShape.star,
          options: FluentRatingShape.values,
          labelOf: _shapeLabel,
        ),
        OptionKnob<FluentRatingColor>(
          label: 'Colour',
          id: 'color',
          initial: FluentRatingColor.neutral,
          options: FluentRatingColor.values,
          labelOf: _colorLabel,
        ),
        BoolKnob(label: 'Disabled', id: 'disabled'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _RatingDemo(
          label: 'Rate this article',
          size: knobs.get('size', FluentRatingSize.extraLarge),
          shape: knobs.get('shape', FluentRatingShape.star),
          color: knobs.get('color', FluentRatingColor.neutral),
          enabled: !knobs.get('disabled', false),
          showValue: true,
        );
      },
    ),
    Story(
      name: 'Controlled value',
      description:
          'The value lives in the caller, never in the rating: the readout, '
          'the reset button and the shapes all read the same piece of state.',
      builder: (context) => const _RatingDemo(
        label: 'Your score',
        initial: 3,
        color: FluentRatingColor.marigold,
        showValue: true,
        showReset: true,
      ),
    ),
    Story(
      name: 'Half values',
      description:
          'A step of 0.5 commits a half when you press the left half of a '
          'shape, and moves the arrow keys by a half at a time.',
      knobs: const [
        OptionKnob<double>(
          label: 'Step',
          id: 'step',
          initial: 0.5,
          options: [1, 0.5],
          labelOf: _stepLabel,
        ),
      ],
      builder: (context) => _RatingDemo(
        label: 'Precision',
        initial: 2.5,
        step: KnobsScope.of(context).get('step', 0.5),
        color: FluentRatingColor.marigold,
        showValue: true,
      ),
    ),
    Story(
      name: 'Max',
      description:
          'How many shapes a full rating is worth. Anything above one works; '
          'the arrow keys clamp at the new ceiling.',
      knobs: const [
        NumberKnob(label: 'Max', id: 'max', initial: 5, min: 2, max: 10),
      ],
      builder: (context) {
        final max = KnobsScope.of(context).get('max', 5.0).round();
        return _RatingDemo(
          label: 'Out of $max',
          initial: 3,
          max: max,
          size: FluentRatingSize.large,
          showValue: true,
        );
      },
    ),
    Story(
      name: 'Sizes',
      description:
          'The four boxes of the size ramp — 12, 16, 20 and 28 — with the gap '
          'between shapes staying at 2 throughout.',
      builder: (context) => _Rows(
        children: [
          for (final size in FluentRatingSize.values)
            (
              _sizeLabel(size),
              FluentRating(
                value: 3.5,
                size: size,
                color: FluentRatingColor.marigold,
                type: FluentRatingType.display,
              ),
            ),
        ],
      ),
    ),
    Story(
      name: 'Shapes',
      description:
          'Star, circle and square. Each silhouette is drawn optically per '
          'size rather than scaled, so the ink matches the Fluent icon.',
      knobs: const [BoolKnob(label: 'Interactive', id: 'interactive')],
      builder: (context) {
        final interactive = KnobsScope.of(context).get('interactive', false);
        return _Rows(
          children: [
            for (final shape in FluentRatingShape.values)
              (
                _shapeLabel(shape),
                interactive
                    ? _RatingDemo(label: '', initial: 3.5, shape: shape)
                    : FluentRating(
                        value: 3.5,
                        shape: shape,
                        type: FluentRatingType.display,
                      ),
              ),
          ],
        );
      },
    ),
    Story(
      name: 'Colours',
      description:
          'Neutral, brand and marigold — the last being the conventional gold '
          'star. The unselected treatment takes its own token per family.',
      knobs: const [BoolKnob(label: 'Interactive', id: 'interactive')],
      builder: (context) {
        final interactive = KnobsScope.of(context).get('interactive', false);
        return _Rows(
          children: [
            for (final color in FluentRatingColor.values)
              (
                _colorLabel(color),
                interactive
                    ? _RatingDemo(label: '', initial: 3, color: color)
                    : FluentRating(
                        value: 3,
                        color: color,
                        type: FluentRatingType.display,
                      ),
              ),
          ],
        );
      },
    ),
    Story(
      name: 'Display',
      description:
          'A display rating is inert: it ignores the pointer and the keyboard '
          'and fills its unselected shapes instead of outlining them.',
      builder: (context) => _Rows(
        children: [
          (
            'Interactive',
            const _RatingDemo(
              label: '',
              initial: 3.5,
              color: FluentRatingColor.marigold,
            ),
          ),
          (
            'Display',
            const FluentRating(
              value: 3.5,
              color: FluentRatingColor.marigold,
              type: FluentRatingType.display,
            ),
          ),
        ],
      ),
    ),
    Story(
      name: 'Compact',
      description:
          'One filled shape stands in for the whole row, with the score and '
          'the review count written beside it — the form for a dense list.',
      builder: (context) => const _CompactRating(value: 4.5, count: 1239),
    ),
    Story(
      name: 'Disabled',
      description:
          'Omitting the change callback disables the rating — a real state, '
          'not a grey repaint: it refuses focus, the pointer and the keys.',
      builder: (context) => const _Rows(
        children: [
          ('Enabled', _RatingDemo(label: '', initial: 3)),
          ('Disabled', _RatingDemo(label: '', initial: 3, enabled: false)),
        ],
      ),
    ),
  ],
);

String _stepLabel(double step) => step == 1 ? 'Whole (1)' : 'Half (0.5)';

/// `3.0` reads as `3`, `2.5` stays `2.5`.
String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toString();

/// One rating that holds its own value, with an optional readout and reset.
///
/// A rating is controlled, so every interactive story needs somewhere for the
/// value to live; one small stateful widget serves all of them.
class _RatingDemo extends StatefulWidget {
  const _RatingDemo({
    required this.label,
    this.initial = 0,
    this.max = 5,
    this.step = 1,
    this.size = FluentRatingSize.extraLarge,
    this.shape = FluentRatingShape.star,
    this.color = FluentRatingColor.neutral,
    this.enabled = true,
    this.showValue = false,
    this.showReset = false,
  });

  final String label;
  final double initial;
  final int max;
  final double step;
  final FluentRatingSize size;
  final FluentRatingShape shape;
  final FluentRatingColor color;
  final bool enabled;
  final bool showValue;
  final bool showReset;

  @override
  State<_RatingDemo> createState() => _RatingDemoState();
}

class _RatingDemoState extends State<_RatingDemo> {
  late double _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    // ponytail: clamp at build — the max knob is the only thing that moves the
    // ceiling, and the rating draws a value above it as a full row anyway.
    final value = _value.clamp(0, widget.max.toDouble()).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.s,
      children: [
        if (widget.label.isNotEmpty)
          FluentLabel(disabled: !widget.enabled, child: Text(widget.label)),
        FluentRating(
          value: value,
          max: widget.max,
          step: widget.step,
          size: widget.size,
          shape: widget.shape,
          color: widget.color,
          semanticLabel: widget.label.isEmpty ? null : widget.label,
          onChanged: widget.enabled
              ? (next) => setState(() => _value = next)
              : null,
        ),
        if (widget.showValue)
          Text(
            '${_number(value)} of ${widget.max}',
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

/// The compact display form: one shape, then the score and the count.
///
/// `FluentRating` paints shapes and nothing else, so the numbers beside a
/// compact rating are the caller's — upstream's `RatingDisplay` renders them
/// itself.
class _CompactRating extends StatelessWidget {
  const _CompactRating({required this.value, required this.count});

  final double value;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: FluentSpacing.s,
      children: [
        FluentRating(
          value: value,
          compact: true,
          size: FluentRatingSize.large,
          color: FluentRatingColor.marigold,
          type: FluentRatingType.display,
          semanticLabel: '$value out of 5, $count ratings',
        ),
        Text(_number(value), style: theme.typography.body1Strong),
        Text(
          '($count)',
          style: theme.typography.body1.copyWith(
            color: theme.colors.neutralForeground2,
          ),
        ),
      ],
    );
  }
}

/// A stack of labelled examples, one per row.
class _Rows extends StatelessWidget {
  const _Rows({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.l,
      children: [
        for (final (label, child) in children)
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: FluentSpacing.l,
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  label,
                  style: theme.typography.caption1.copyWith(
                    color: theme.colors.neutralForeground2,
                  ),
                ),
              ),
              child,
            ],
          ),
      ],
    );
  }
}
