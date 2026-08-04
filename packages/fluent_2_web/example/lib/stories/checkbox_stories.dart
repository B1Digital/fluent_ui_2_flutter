import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentCheckbox].
final StorySection checkboxStories = StorySection(
  component: 'Checkbox',
  description:
      'A tri-state control for a single independent choice: on, off, or mixed '
      'when it stands for a set of children that disagree.',
  stories: [
    Story(
      name: 'Default',
      description:
          'A checkbox owns nothing: the value lives with the caller and comes '
          'back through onChanged. Every design axis is a knob here.',
      knobs: const [
        TextKnob(label: 'Label', id: 'label', initial: 'Keep me signed in'),
        OptionKnob<FluentCheckboxSize>(
          label: 'Size',
          id: 'size',
          initial: FluentCheckboxSize.medium,
          options: FluentCheckboxSize.values,
          labelOf: _sizeLabel,
        ),
        OptionKnob<FluentCheckboxShape>(
          label: 'Shape',
          id: 'shape',
          initial: FluentCheckboxShape.square,
          options: FluentCheckboxShape.values,
          labelOf: _shapeLabel,
        ),
        OptionKnob<FluentCheckboxLabelPosition>(
          label: 'Label position',
          id: 'position',
          initial: FluentCheckboxLabelPosition.after,
          options: FluentCheckboxLabelPosition.values,
          labelOf: _positionLabel,
        ),
        BoolKnob(label: 'Disabled', id: 'disabled'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _ToggleCheckbox(
          label: Text(knobs.get<String>('label', 'Keep me signed in')),
          size: knobs.get<FluentCheckboxSize>(
            'size',
            FluentCheckboxSize.medium,
          ),
          shape: knobs.get<FluentCheckboxShape>(
            'shape',
            FluentCheckboxShape.square,
          ),
          labelPosition: knobs.get<FluentCheckboxLabelPosition>(
            'position',
            FluentCheckboxLabelPosition.after,
          ),
          enabled: !knobs.get<bool>('disabled', false),
        );
      },
    ),
    const Story(
      name: 'Checked',
      description:
          'Starting checked is just a starting value — the control still '
          'reports the next value and never changes itself.',
      builder: _checkedBuilder,
    ),
    const Story(
      name: 'Mixed',
      description:
          'Null is the mixed state, used by a parent whose children disagree. '
          'Tapping a mixed checkbox reports true, never mixed.',
      builder: _mixedBuilder,
    ),
    const Story(
      name: 'Disabled',
      description:
          'Disabling replaces the whole colour ramp rather than fading it, so '
          'a disabled checked box loses its brand fill entirely.',
      builder: _disabledBuilder,
    ),
    const Story(
      name: 'Sizes',
      description:
          'Medium (16px box) and large (20px box). The label keeps the same '
          'type ramp at both sizes; only the indicator grows.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Circular',
      description:
          'A circular indicator for checklists. Its mixed state draws a dot '
          'rather than the square the standard shape uses.',
      builder: _circularBuilder,
    ),
    const Story(
      name: 'Label before',
      description:
          'The label can lead the indicator in reading order; the tight 4px '
          'gap follows it to the side facing the box.',
      builder: _labelBeforeBuilder,
    ),
    Story(
      name: 'Label wrapping',
      description:
          'A long label wraps and the indicator stays beside its first line, '
          'not centred against the whole block.',
      knobs: const [
        NumberKnob(
          label: 'Available width',
          id: 'width',
          initial: 260,
          min: 140,
          max: 520,
          step: 10,
        ),
      ],
      builder: (context) => SizedBox(
        width: KnobsScope.of(context).get<double>('width', 260),
        child: const _ToggleCheckbox(
          initial: true,
          label: Text(
            'Send me a summary of everything that happened while I was away, '
            'even when nothing did',
          ),
        ),
      ),
    ),
    const Story(
      name: 'Required',
      description:
          'A required checkbox marks its label with an asterisk by composing '
          'FluentLabel, which owns that treatment.',
      builder: _requiredBuilder,
    ),
  ],
);

String _sizeLabel(FluentCheckboxSize value) => value.name;

String _shapeLabel(FluentCheckboxShape value) => value.name;

String _positionLabel(FluentCheckboxLabelPosition value) => value.name;

Widget _checkedBuilder(BuildContext context) => const _ToggleCheckbox(
  initial: true,
  label: Text('Notify me about replies'),
);

Widget _mixedBuilder(BuildContext context) => const _MixedParent();

Widget _disabledBuilder(BuildContext context) => const _Cases(
  children: [
    ('Unchecked', FluentCheckbox(label: Text('Unchecked'))),
    ('Checked', FluentCheckbox(checked: true, label: Text('Checked'))),
    ('Mixed', FluentCheckbox(checked: null, label: Text('Mixed'))),
  ],
);

Widget _sizesBuilder(BuildContext context) => const _Cases(
  children: [
    ('Medium', _ToggleCheckbox(initial: true, label: Text('Medium'))),
    (
      'Large',
      _ToggleCheckbox(
        initial: true,
        size: FluentCheckboxSize.large,
        label: Text('Large'),
      ),
    ),
  ],
);

Widget _circularBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Square',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ToggleCheckbox(label: Text('Unchecked')),
          _ToggleCheckbox(initial: true, label: Text('Checked')),
          FluentCheckbox(checked: null, label: Text('Mixed'), onChanged: _noop),
        ],
      ),
    ),
    (
      'Circular',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ToggleCheckbox(
            shape: FluentCheckboxShape.circular,
            label: Text('Unchecked'),
          ),
          _ToggleCheckbox(
            initial: true,
            shape: FluentCheckboxShape.circular,
            label: Text('Checked'),
          ),
          FluentCheckbox(
            checked: null,
            shape: FluentCheckboxShape.circular,
            label: Text('Mixed'),
            onChanged: _noop,
          ),
        ],
      ),
    ),
  ],
);

Widget _labelBeforeBuilder(BuildContext context) => const _Cases(
  children: [
    ('After (default)', _ToggleCheckbox(label: Text('Label after'))),
    (
      'Before',
      _ToggleCheckbox(
        labelPosition: FluentCheckboxLabelPosition.before,
        label: Text('Label before'),
      ),
    ),
  ],
);

Widget _requiredBuilder(BuildContext context) => const _ToggleCheckbox(
  label: FluentLabel(required: true, child: Text('I accept the terms')),
);

/// The mixed row above is a display of the state, not a control of it — the
/// callback keeps it enabled so it shows the enabled ramp.
void _noop(bool? value) {}

/// A checkbox that keeps its own value, so the gallery shows a real control
/// rather than a frozen one. Every axis is forwarded untouched.
class _ToggleCheckbox extends StatefulWidget {
  const _ToggleCheckbox({
    this.initial = false,
    this.label,
    this.size = FluentCheckboxSize.medium,
    this.shape = FluentCheckboxShape.square,
    this.labelPosition = FluentCheckboxLabelPosition.after,
    this.enabled = true,
  });

  final bool initial;
  final Widget? label;
  final FluentCheckboxSize size;
  final FluentCheckboxShape shape;
  final FluentCheckboxLabelPosition labelPosition;
  final bool enabled;

  @override
  State<_ToggleCheckbox> createState() => _ToggleCheckboxState();
}

class _ToggleCheckboxState extends State<_ToggleCheckbox> {
  late bool? _checked = widget.initial;

  @override
  Widget build(BuildContext context) => FluentCheckbox(
    checked: _checked,
    label: widget.label,
    size: widget.size,
    shape: widget.shape,
    labelPosition: widget.labelPosition,
    onChanged: widget.enabled
        ? (value) => setState(() => _checked = value)
        : null,
  );
}

/// A parent checkbox that reports its children: checked when they all are,
/// unchecked when none are, mixed in between.
class _MixedParent extends StatefulWidget {
  const _MixedParent();

  @override
  State<_MixedParent> createState() => _MixedParentState();
}

class _MixedParentState extends State<_MixedParent> {
  static const _names = ['Email', 'Push', 'SMS'];
  final _children = <bool>[true, false, false];

  bool? get _parent => _children.every((c) => c)
      ? true
      : _children.every((c) => !c)
      ? false
      : null;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FluentCheckbox(
        checked: _parent,
        label: const Text('All notifications'),
        onChanged: (value) => setState(
          () => _children.fillRange(0, _children.length, value ?? true),
        ),
      ),
      for (var i = 0; i < _names.length; i++)
        Padding(
          padding: const EdgeInsetsDirectional.only(start: FluentSpacing.xl),
          child: FluentCheckbox(
            checked: _children[i],
            label: Text(_names[i]),
            onChanged: (value) => setState(() => _children[i] = value ?? false),
          ),
        ),
    ],
  );
}

/// Side-by-side cases under a caption, the layout most of these stories want.
class _Cases extends StatelessWidget {
  const _Cases({required this.children});

  final List<(String, Widget)> children;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Wrap(
      spacing: FluentSpacing.xxl,
      runSpacing: FluentSpacing.l,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        for (final (caption, child) in children)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}
