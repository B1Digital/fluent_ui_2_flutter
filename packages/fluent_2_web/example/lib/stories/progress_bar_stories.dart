import 'dart:async';

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentProgressBar].
final StorySection progressBarStories = StorySection(
  component: 'Progress bar',
  description:
      'A horizontal report of how far along something is. `value` is the whole '
      'mode switch — a fraction from 0 to 1 fills the rail, `null` sweeps for a '
      'wait of unknown length. Two heights, four status colours, and no '
      'interaction at all: a progress bar is never hovered, focused or '
      'disabled.',
  stories: [
    Story(
      name: 'Default',
      description:
          'Every axis at once — drag the value, switch the height and the '
          'status colour, or drop the value entirely to get the indeterminate '
          'sweep.',
      knobs: [
        const BoolKnob(label: 'Indeterminate', id: 'indeterminate'),
        const NumberKnob(
          label: 'Value (%)',
          id: 'value',
          initial: 40,
          max: 100,
        ),
        OptionKnob<FluentProgressBarSize>(
          label: 'Size',
          id: 'size',
          initial: FluentProgressBarSize.medium,
          options: FluentProgressBarSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentProgressBarStatus>(
          label: 'Status',
          id: 'status',
          initial: FluentProgressBarStatus.none,
          options: FluentProgressBarStatus.values,
          labelOf: _statusLabel,
        ),
      ],
      builder: _defaultBuilder,
    ),
    const Story(
      name: 'Value',
      description:
          'The fraction the indicator fills, from empty to full. A value outside '
          '0 to 1 is clamped rather than overflowing the rail.',
      builder: _valueBuilder,
    ),
    const Story(
      name: 'Indeterminate',
      description:
          'Omitting the value sweeps a third of the rail forever, for a wait '
          'whose length is unknown. Turn on Reduced motion in the toolbar: the '
          'sweep parks where Figma draws the static variant instead of stopping '
          'somewhere arbitrary.',
      builder: _indeterminateBuilder,
    ),
    const Story(
      name: 'Sizes',
      description:
          'Two rail heights — medium is 2 high, large is 4. Both sizes carry '
          'every status and both modes.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Status colours',
      description:
          'The indicator colour is validation, not interaction: brand while a '
          'task runs, then success, error or warning once it resolves.',
      builder: _statusBuilder,
    ),
    Story(
      name: 'Shape',
      description:
          'The corner radius is a style property rather than a shape prop, so '
          'square ends are a one-line override that keeps every resolved colour.',
      knobs: const [BoolKnob(label: 'Square', id: 'square', initial: true)],
      builder: _shapeBuilder,
    ),
    Story(
      name: 'Custom styling',
      description:
          'Three rungs of override — the size and status defaults, a '
          'FluentProgressBarTheme over a subtree, then the widget style, which '
          'is merged last and wins.',
      knobs: const [
        NumberKnob(
          label: 'Thickness',
          id: 'thickness',
          initial: 8,
          min: 2,
          max: 24,
        ),
      ],
      builder: _stylingBuilder,
    ),
    const Story(
      name: 'Reporting a task',
      description:
          'What the component is for: a labelled upload that reports a real '
          'fraction, then lands on success — and announces both through '
          'semanticLabel.',
      builder: _taskBuilder,
    ),
  ],
);

String _sizeLabel(FluentProgressBarSize value) => value.name;

String _statusLabel(FluentProgressBarStatus value) => value.name;

Widget _defaultBuilder(BuildContext context) {
  final knobs = KnobsScope.of(context);
  final indeterminate = knobs.get<bool>('indeterminate', false);
  return _Rail(
    child: FluentProgressBar(
      value: indeterminate ? null : knobs.get<double>('value', 40) / 100,
      size: knobs.get<FluentProgressBarSize>(
        'size',
        FluentProgressBarSize.medium,
      ),
      status: knobs.get<FluentProgressBarStatus>(
        'status',
        FluentProgressBarStatus.none,
      ),
      semanticLabel: 'Progress',
    ),
  );
}

Widget _valueBuilder(BuildContext context) => const _Cases(
  children: [
    ('0 — empty', FluentProgressBar(value: 0)),
    ('0.25', FluentProgressBar(value: 0.25)),
    ('0.5', FluentProgressBar(value: 0.5)),
    ('1 — full', FluentProgressBar(value: 1)),
    ('1.8 — clamped to full', FluentProgressBar(value: 1.8)),
    ('-0.4 — clamped to empty', FluentProgressBar(value: -0.4)),
  ],
);

Widget _indeterminateBuilder(BuildContext context) => const _Cases(
  children: [
    ('no value — sweeping', FluentProgressBar(semanticLabel: 'Loading')),
    (
      'no value, large',
      FluentProgressBar(
        size: FluentProgressBarSize.large,
        semanticLabel: 'Loading',
      ),
    ),
    (
      'no value, error — a stalled retry still has no percentage',
      FluentProgressBar(
        status: FluentProgressBarStatus.error,
        semanticLabel: 'Retrying',
      ),
    ),
    (
      'value 0 — determinate and genuinely at zero',
      FluentProgressBar(value: 0),
    ),
  ],
);

Widget _sizesBuilder(BuildContext context) => const _Cases(
  children: [
    ('medium — 2 high', FluentProgressBar(value: 0.6)),
    (
      'large — 4 high',
      FluentProgressBar(value: 0.6, size: FluentProgressBarSize.large),
    ),
    ('medium, indeterminate', FluentProgressBar()),
    (
      'large, indeterminate',
      FluentProgressBar(size: FluentProgressBarSize.large),
    ),
  ],
);

Widget _statusBuilder(BuildContext context) => const _Cases(
  children: [
    ('none — the brand colour', FluentProgressBar(value: 0.6)),
    (
      'success',
      FluentProgressBar(
        value: 1,
        size: FluentProgressBarSize.large,
        status: FluentProgressBarStatus.success,
      ),
    ),
    (
      'error',
      FluentProgressBar(
        value: 0.35,
        size: FluentProgressBarSize.large,
        status: FluentProgressBarStatus.error,
      ),
    ),
    (
      'warning',
      FluentProgressBar(
        value: 0.8,
        size: FluentProgressBarSize.large,
        status: FluentProgressBarStatus.warning,
      ),
    ),
  ],
);

Widget _shapeBuilder(BuildContext context) {
  final square = KnobsScope.of(context).get<bool>('square', true);
  final radius = square ? BorderRadius.zero : FluentRadius.allCircular;
  return _Cases(
    children: [
      (
        'the default — fully rounded ends',
        const FluentProgressBar(value: 0.6, size: FluentProgressBarSize.large),
      ),
      (
        square ? 'borderRadius: zero' : 'borderRadius: circular',
        FluentProgressBar(
          value: 0.6,
          size: FluentProgressBarSize.large,
          style: FluentProgressBarStyle.from(borderRadius: radius),
        ),
      ),
      (
        'any other radius is the same one property',
        FluentProgressBar(
          value: 0.6,
          size: FluentProgressBarSize.large,
          style: FluentProgressBarStyle.from(
            borderRadius: FluentRadius.allSmall,
          ),
        ),
      ),
    ],
  );
}

Widget _stylingBuilder(BuildContext context) {
  final colors = FluentTheme.of(context).colors;
  final thickness = KnobsScope.of(context).get<double>('thickness', 8);
  return FluentProgressBarTheme(
    style: FluentProgressBarStyle.from(
      railColor: colors.neutralBackground3,
      thickness: thickness,
    ),
    child: _Cases(
      children: [
        ('status defaults, outside the subtree', _outsideTheSubtree),
        (
          'subtree theme — a thicker bar on a lighter rail',
          const FluentProgressBar(value: 0.55),
        ),
        (
          'widget style wins',
          FluentProgressBar(
            value: 0.55,
            status: FluentProgressBarStatus.success,
            style: FluentProgressBarStyle.from(
              indicatorColor: colors.brandBackground,
              railColor: colors.neutralBackground5,
              borderRadius: FluentRadius.allSmall,
              thickness: thickness * 2,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Sits outside the [FluentProgressBarTheme] so the unthemed default is visible
/// beside the overridden ones.
const Widget _outsideTheSubtree = FluentProgressBar(
  value: 0.55,
  status: FluentProgressBarStatus.warning,
);

Widget _taskBuilder(BuildContext context) => const _UploadDemo();

/// A real upload report: a trigger, a fraction that actually moves, and a
/// terminal status.
class _UploadDemo extends StatefulWidget {
  const _UploadDemo();

  @override
  State<_UploadDemo> createState() => _UploadDemoState();
}

class _UploadDemoState extends State<_UploadDemo> {
  static const _files = 12;

  Timer? _timer;
  int _done = 0;
  bool _running = false;

  void _start() {
    _timer?.cancel();
    setState(() {
      _done = 0;
      _running = true;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 350), (timer) {
      setState(() {
        _done++;
        if (_done >= _files) {
          _running = false;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final complete = _done >= _files;
    return _Rail(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.s,
        children: [
          const FluentLabel(child: Text('Uploading photos')),
          FluentProgressBar(
            value: _done / _files,
            size: FluentProgressBarSize.large,
            status: complete
                ? FluentProgressBarStatus.success
                : FluentProgressBarStatus.none,
            semanticLabel: 'Uploading photos',
          ),
          Text(
            complete ? 'Done — $_files of $_files' : '$_done of $_files',
            style: theme.typography.caption1.copyWith(
              color: theme.colors.neutralForeground3,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FluentButton(
              onPressed: _running ? null : _start,
              child: Text(complete ? 'Upload again' : 'Start upload'),
            ),
          ),
        ],
      ),
    );
  }
}

/// A bounded width for the bar to fill — it expands to whatever it is given.
class _Rail extends StatelessWidget {
  const _Rail({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: child,
  );
}

/// Stacked cases under a caption, each stretched to the same width so the bars
/// are directly comparable.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return _Rail(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.xl,
        children: [
          for (final (caption, child) in children)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: FluentSpacing.xs,
              children: [
                Text(
                  caption,
                  style: theme.typography.caption1.copyWith(
                    color: theme.colors.neutralForeground3,
                  ),
                ),
                child,
              ],
            ),
        ],
      ),
    );
  }
}
