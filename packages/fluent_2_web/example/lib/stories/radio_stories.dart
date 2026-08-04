import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentRadio] and [FluentRadioGroup].
final StorySection radioStories = StorySection(
  component: 'Radio',
  description:
      'One option in a mutually exclusive set. A radio is never used alone: '
      'FluentRadioGroup owns the selection and hands it down, so a radio placed '
      'anywhere under the group renders and reports correctly.',
  stories: [
    Story(
      name: 'Default',
      description:
          'The group owns the value and reports the next one through '
          'onChanged; the radios themselves are stateless. Layout and disabled '
          'are group-level axes, so both are knobs here.',
      knobs: const [
        OptionKnob<FluentRadioGroupLayout>(
          label: 'Layout',
          id: 'layout',
          initial: FluentRadioGroupLayout.vertical,
          options: FluentRadioGroupLayout.values,
          labelOf: _layoutLabel,
        ),
        BoolKnob(label: 'Disabled', id: 'disabled'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _FruitGroup(
          layout: knobs.get<FluentRadioGroupLayout>(
            'layout',
            FluentRadioGroupLayout.vertical,
          ),
          disabled: knobs.get<bool>('disabled', false),
        );
      },
    ),
    const Story(
      name: 'Preselected',
      description:
          'A group starts on whatever value the caller holds; passing null for '
          'the value starts it with nothing selected at all.',
      builder: _preselectedBuilder,
    ),
    const Story(
      name: 'Controlled value',
      description:
          'The selection is just the caller\'s state, so anything else can set '
          'it — here two buttons drive the same group the radios do.',
      builder: _controlledBuilder,
    ),
    const Story(
      name: 'Layouts',
      description:
          'Vertical stacks one option per row; horizontal flows them across; '
          'horizontal stacked also moves every label under its indicator.',
      builder: _layoutsBuilder,
    ),
    const Story(
      name: 'Disabled',
      description:
          'Disabling the group switches off every radio in it, or a single '
          'radio can opt out while its siblings stay live. Either way the '
          'disabled tokens replace the ramp rather than fading it.',
      builder: _disabledBuilder,
    ),
    const Story(
      name: 'Label with subtext',
      description:
          'The label is a widget, not a string, so a second explanatory line '
          'goes under the option title without any new API.',
      builder: _subtextBuilder,
    ),
    Story(
      name: 'In a field',
      description:
          'FluentField supplies the group heading, the required asterisk and '
          'the validation message; the group itself stays a plain control.',
      knobs: const [
        BoolKnob(label: 'Required', id: 'required', initial: true),
        BoolKnob(label: 'Show error', id: 'error'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _FieldGroup(
          required: knobs.get<bool>('required', true),
          error: knobs.get<bool>('error', false),
        );
      },
    ),
  ],
);

String _layoutLabel(FluentRadioGroupLayout value) => switch (value) {
  FluentRadioGroupLayout.vertical => 'vertical',
  FluentRadioGroupLayout.horizontal => 'horizontal',
  FluentRadioGroupLayout.horizontalStacked => 'horizontal stacked',
};

const _fruits = <String>['Apple', 'Pear', 'Banana'];

Widget _preselectedBuilder(BuildContext context) => const _Cases(
  children: [
    ('Starts on Pear', _FruitGroup(initial: 'Pear')),
    ('Starts on nothing', _FruitGroup(initial: null)),
  ],
);

Widget _controlledBuilder(BuildContext context) => const _ControlledGroup();

Widget _layoutsBuilder(BuildContext context) => const _Cases(
  children: [
    ('Vertical', _FruitGroup()),
    ('Horizontal', _FruitGroup(layout: FluentRadioGroupLayout.horizontal)),
    (
      'Horizontal stacked',
      _FruitGroup(layout: FluentRadioGroupLayout.horizontalStacked),
    ),
  ],
);

Widget _disabledBuilder(BuildContext context) => const _Cases(
  children: [
    ('Whole group', _FruitGroup(disabled: true)),
    ('One option', _FruitGroup(disabledValue: 'Banana')),
  ],
);

Widget _subtextBuilder(BuildContext context) => const _SubtextGroup();

/// A group over three fixed options that keeps its own selection, so the
/// gallery shows a real control rather than a frozen one.
class _FruitGroup extends StatefulWidget {
  const _FruitGroup({
    this.initial = 'Apple',
    this.layout = FluentRadioGroupLayout.vertical,
    this.disabled = false,
    this.disabledValue,
  });

  final String? initial;
  final FluentRadioGroupLayout layout;
  final bool disabled;

  /// The one option switched off while its siblings stay live.
  final String? disabledValue;

  @override
  State<_FruitGroup> createState() => _FruitGroupState();
}

class _FruitGroupState extends State<_FruitGroup> {
  late String? _value = widget.initial;

  @override
  Widget build(BuildContext context) => FluentRadioGroup<String>(
    value: _value,
    semanticLabel: 'Favourite fruit',
    layout: widget.layout,
    disabled: widget.disabled,
    onChanged: (value) => setState(() => _value = value),
    children: [
      for (final fruit in _fruits)
        FluentRadio<String>(
          value: fruit,
          disabled: fruit == widget.disabledValue,
          label: Text(fruit),
        ),
    ],
  );
}

/// The selection driven from outside the group as well as from inside it —
/// what "controlled" buys you.
class _ControlledGroup extends StatefulWidget {
  const _ControlledGroup();

  @override
  State<_ControlledGroup> createState() => _ControlledGroupState();
}

class _ControlledGroupState extends State<_ControlledGroup> {
  String _value = _fruits.first;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FluentSpacing.m,
      children: [
        FluentRadioGroup<String>(
          value: _value,
          semanticLabel: 'Favourite fruit',
          onChanged: (value) => setState(() => _value = value),
          children: [
            for (final fruit in _fruits)
              FluentRadio<String>(value: fruit, label: Text(fruit)),
          ],
        ),
        Text(
          'Selected: $_value',
          style: theme.typography.caption1.copyWith(
            color: theme.colors.neutralForeground3,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: FluentSpacing.s,
          children: [
            FluentButton(
              child: const Text('Pick the first'),
              onPressed: () => setState(() => _value = _fruits.first),
            ),
            FluentButton(
              child: const Text('Pick the last'),
              onPressed: () => setState(() => _value = _fruits.last),
            ),
          ],
        ),
      ],
    );
  }
}

/// Two-line labels: the option title over a quieter description.
class _SubtextGroup extends StatefulWidget {
  const _SubtextGroup();

  @override
  State<_SubtextGroup> createState() => _SubtextGroupState();
}

class _SubtextGroupState extends State<_SubtextGroup> {
  static const _plans = <(String, String)>[
    ('Every change', 'One message per edit, as it happens'),
    ('Daily digest', 'One summary each morning'),
    ('Nothing', 'Check back here whenever you like'),
  ];

  String _value = _plans.first.$1;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return FluentRadioGroup<String>(
      value: _value,
      semanticLabel: 'Notify me about',
      onChanged: (value) => setState(() => _value = value),
      children: [
        for (final (title, subtext) in _plans)
          FluentRadio<String>(
            value: title,
            label: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(
                  subtext,
                  style: theme.typography.caption1.copyWith(
                    color: theme.colors.neutralForeground3,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A group inside a [FluentField], which is where the heading, the required
/// asterisk and the validation message live.
class _FieldGroup extends StatefulWidget {
  const _FieldGroup({required this.required, required this.error});

  final bool required;
  final bool error;

  @override
  State<_FieldGroup> createState() => _FieldGroupState();
}

class _FieldGroupState extends State<_FieldGroup> {
  String? _value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 320,
    child: FluentField(
      label: const Text('Favourite fruit'),
      required: widget.required,
      hint: const Text('You can change this later'),
      validationState: widget.error
          ? FluentFieldValidationState.error
          : FluentFieldValidationState.none,
      validationMessage: widget.error
          ? const Text('Pick one to continue')
          : null,
      child: FluentRadioGroup<String>(
        value: _value,
        onChanged: (value) => setState(() => _value = value),
        children: [
          for (final fruit in _fruits)
            FluentRadio<String>(value: fruit, label: Text(fruit)),
        ],
      ),
    ),
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
