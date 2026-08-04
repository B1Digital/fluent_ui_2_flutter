import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../gallery/story.dart';

/// Stories for [FluentDropdown].
final StorySection dropdownStories = StorySection(
  component: 'Dropdown',
  description:
      'A trigger that opens a list of options over the page and reports the '
      'one chosen. Selection is single: the value is one option, or null.',
  stories: [
    Story(
      name: 'Default',
      description:
          'The dropdown owns nothing but the popup — the value lives with the '
          'caller and arrives through onChanged. Every design axis is a knob.',
      knobs: const [
        TextKnob(
          label: 'Placeholder',
          id: 'placeholder',
          initial: 'Select a city',
        ),
        OptionKnob<FluentDropdownAppearance>(
          label: 'Appearance',
          id: 'appearance',
          initial: FluentDropdownAppearance.outline,
          options: FluentDropdownAppearance.values,
          labelOf: _appearanceLabel,
        ),
        OptionKnob<FluentDropdownSize>(
          label: 'Size',
          id: 'size',
          initial: FluentDropdownSize.medium,
          options: FluentDropdownSize.values,
          labelOf: _sizeLabel,
        ),
        BoolKnob(label: 'Disabled', id: 'disabled'),
      ],
      builder: (context) {
        final knobs = KnobsScope.of(context);
        return _CityDropdown(
          placeholder: knobs.get<String>('placeholder', 'Select a city'),
          appearance: knobs.get<FluentDropdownAppearance>(
            'appearance',
            FluentDropdownAppearance.outline,
          ),
          size: knobs.get<FluentDropdownSize>(
            'size',
            FluentDropdownSize.medium,
          ),
          enabled: !knobs.get<bool>('disabled', false),
        );
      },
    ),
    const Story(
      name: 'Appearances',
      description:
          'Four fills. Outline and transparent carry the thin accessible rule '
          'along the bottom; the two filled ones rely on their fill alone.',
      builder: _appearancesBuilder,
    ),
    const Story(
      name: 'Sizes',
      description:
          'Small, medium and large: 24, 32 and 40 tall, each with its own type '
          'ramp and chevron size. The popup rows stay 32 tall at every size.',
      builder: _sizesBuilder,
    ),
    const Story(
      name: 'Grouped',
      description:
          'A header option captions a run of values. Headers are never '
          'selectable and the arrow keys step straight over them.',
      builder: _groupedBuilder,
    ),
    const Story(
      name: 'Disabled',
      description:
          'A null onChanged disables the whole trigger — it refuses focus and '
          'never opens. A single option can be disabled on its own instead.',
      builder: _disabledBuilder,
    ),
    const Story(
      name: 'Controlled',
      description:
          'The value is a plain field on the caller, so anything else on the '
          'page can set it and the trigger follows.',
      builder: _controlledBuilder,
    ),
    const Story(
      name: 'Clearing the selection',
      description:
          'The value is nullable: put it back to null and the trigger returns '
          'to its placeholder. The dropdown itself has no clear affordance.',
      builder: _clearableBuilder,
    ),
    const Story(
      name: 'Complex options',
      description:
          'An option is a widget, not a string. Give it a `text` as well so a '
          'screen reader has something to read when the label is a glyph.',
      builder: _complexBuilder,
    ),
    const Story(
      name: 'Custom styling',
      description:
          'Trigger and rows restyle through the same three rungs: theme '
          'defaults, a subtree theme, then `style` and `optionStyle` last.',
      builder: _customStylingBuilder,
    ),
    Story(
      name: 'Truncation',
      description:
          'The trigger is a single line: a label wider than the trigger '
          'ellipsises rather than wrapping or overflowing.',
      knobs: const [
        NumberKnob(
          label: 'Trigger width',
          id: 'width',
          initial: 220,
          min: 120,
          max: 520,
          step: 10,
        ),
      ],
      builder: (context) => _CityDropdown(
        options: _longNames,
        initial: 'llan',
        width: KnobsScope.of(context).get<double>('width', 220),
      ),
    ),
    Story(
      name: 'In a field',
      description:
          'FluentField owns the label, hint and validation message; the '
          'dropdown is only the control it wraps.',
      knobs: const [
        OptionKnob<FluentFieldValidationState>(
          label: 'Validation',
          id: 'validation',
          initial: FluentFieldValidationState.error,
          options: FluentFieldValidationState.values,
          labelOf: _validationLabel,
        ),
      ],
      builder: (context) => _fieldExample(
        KnobsScope.of(context).get<FluentFieldValidationState>(
          'validation',
          FluentFieldValidationState.error,
        ),
      ),
    ),
    const Story(
      name: 'Keyboard',
      description:
          'Down or Up opens on the selected row, arrows and Home/End move it, '
          'Enter commits and Escape closes. Focus never leaves the trigger.',
      builder: _keyboardBuilder,
    ),
  ],
);

String _appearanceLabel(FluentDropdownAppearance value) => value.name;

String _sizeLabel(FluentDropdownSize value) => value.name;

String _validationLabel(FluentFieldValidationState value) => value.name;

const _cities = <FluentDropdownOption<String>>[
  FluentDropdownOption<String>(value: 'osl', label: Text('Oslo')),
  FluentDropdownOption<String>(value: 'hel', label: Text('Helsinki')),
  FluentDropdownOption<String>(value: 'lis', label: Text('Lisbon')),
  FluentDropdownOption<String>(value: 'ber', label: Text('Berlin')),
  FluentDropdownOption<String>(value: 'dub', label: Text('Dublin')),
];

const _grouped = <FluentDropdownOption<String>>[
  FluentDropdownOption<String>.header(label: Text('Nordics')),
  FluentDropdownOption<String>(value: 'osl', label: Text('Oslo')),
  FluentDropdownOption<String>(value: 'hel', label: Text('Helsinki')),
  FluentDropdownOption<String>.header(label: Text('Southern Europe')),
  FluentDropdownOption<String>(value: 'lis', label: Text('Lisbon')),
  FluentDropdownOption<String>(value: 'ath', label: Text('Athens')),
];

const _someDisabled = <FluentDropdownOption<String>>[
  FluentDropdownOption<String>(value: 'osl', label: Text('Oslo')),
  FluentDropdownOption<String>(
    value: 'rvk',
    label: Text('Reykjavik'),
    enabled: false,
  ),
  FluentDropdownOption<String>(value: 'lis', label: Text('Lisbon')),
];

const _longNames = <FluentDropdownOption<String>>[
  FluentDropdownOption<String>(
    value: 'llan',
    label: Text(
      'Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch, Anglesey',
    ),
  ),
  FluentDropdownOption<String>(
    value: 'chg',
    label: Text('Chargoggagoggmanchauggagoggchaubunagungamaugg, Massachusetts'),
  ),
  FluentDropdownOption<String>(value: 'yrk', label: Text('York')),
];

Widget _appearancesBuilder(BuildContext context) => const _Cases(
  children: [
    ('Outline', _CityDropdown(initial: 'osl', width: 200)),
    (
      'Transparent',
      _CityDropdown(
        initial: 'osl',
        appearance: FluentDropdownAppearance.transparent,
        width: 200,
      ),
    ),
    (
      'Fill lighter',
      _CityDropdown(
        initial: 'osl',
        appearance: FluentDropdownAppearance.fillLighter,
        width: 200,
      ),
    ),
    (
      'Fill darker',
      _CityDropdown(
        initial: 'osl',
        appearance: FluentDropdownAppearance.fillDarker,
        width: 200,
      ),
    ),
  ],
);

Widget _sizesBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Small',
      _CityDropdown(initial: 'osl', size: FluentDropdownSize.small, width: 200),
    ),
    ('Medium', _CityDropdown(initial: 'osl', width: 200)),
    (
      'Large',
      _CityDropdown(initial: 'osl', size: FluentDropdownSize.large, width: 200),
    ),
  ],
);

Widget _groupedBuilder(BuildContext context) =>
    const _CityDropdown(options: _grouped, placeholder: 'Pick a destination');

Widget _disabledBuilder(BuildContext context) => const _Cases(
  children: [
    (
      'Whole dropdown',
      _CityDropdown(initial: 'osl', enabled: false, width: 220),
    ),
    (
      'One option',
      _CityDropdown(
        options: _someDisabled,
        placeholder: 'Reykjavik is full',
        width: 220,
      ),
    ),
  ],
);

Widget _controlledBuilder(BuildContext context) =>
    const _ExternalValue(presets: [('osl', 'Set Oslo'), ('lis', 'Set Lisbon')]);

Widget _clearableBuilder(BuildContext context) =>
    const _ExternalValue(initial: 'ber', presets: [], clearable: true);

Widget _keyboardBuilder(BuildContext context) =>
    const _CityDropdown(autofocus: true, initial: 'hel');

Widget _customStylingBuilder(BuildContext context) => _CityDropdown(
  initial: 'osl',
  style: FluentDropdownStyle.from(borderRadius: FluentRadius.allCircular),
  optionStyle: FluentDropdownOptionStyle.from(
    borderRadius: FluentRadius.allCircular,
    minimumSize: const Size(0, 40),
  ),
);

/// One option per person, each a row rather than a bare string.
Widget _complexBuilder(BuildContext context) {
  final theme = FluentTheme.of(context);
  const people = <(String, String, String, IconData)>[
    ('ann', 'Anna Bergström', 'Oslo', FluentIcons.person_20_regular),
    ('kai', 'Kai Nakamura', 'Remote', FluentIcons.globe_20_regular),
    ('rui', 'Rui Almeida', 'Lisbon HQ', FluentIcons.building_20_regular),
  ];

  return _CityDropdown(
    width: 320,
    placeholder: 'Assign to',
    options: [
      for (final (value, name, where, icon) in people)
        FluentDropdownOption<String>(
          value: value,
          text: '$name, $where',
          label: Row(
            spacing: FluentSpacing.s,
            children: [
              Icon(icon, size: FluentSize.size160),
              Text(name),
              Text(
                where,
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

Widget _fieldExample(FluentFieldValidationState state) {
  final (message, icon) = switch (state) {
    FluentFieldValidationState.none => (null, null),
    FluentFieldValidationState.error => (
      'Pick a city to continue',
      FluentIcons.error_circle_12_filled,
    ),
    FluentFieldValidationState.warning => (
      'We do not deliver there yet',
      FluentIcons.warning_12_filled,
    ),
    FluentFieldValidationState.success => (
      'Delivery confirmed',
      FluentIcons.checkmark_circle_12_filled,
    ),
  };

  return SizedBox(
    width: 320,
    child: FluentField(
      label: const Text('Home city'),
      required: true,
      hint: const Text('Sets your default time zone'),
      validationState: state,
      validationMessage: message == null ? null : Text(message),
      validationMessageIcon: icon == null ? null : Icon(icon),
      child: const _CityDropdown(width: double.infinity),
    ),
  );
}

/// A dropdown that keeps its own value, so the gallery shows a live control
/// rather than a frozen one. Every axis is forwarded untouched.
class _CityDropdown extends StatefulWidget {
  const _CityDropdown({
    this.options = _cities,
    this.initial,
    this.placeholder = 'Select a city',
    this.appearance = FluentDropdownAppearance.outline,
    this.size = FluentDropdownSize.medium,
    this.enabled = true,
    this.autofocus = false,
    this.width = 260,
    this.style,
    this.optionStyle,
  });

  final List<FluentDropdownOption<String>> options;
  final String? initial;
  final String placeholder;
  final FluentDropdownAppearance appearance;
  final FluentDropdownSize size;
  final bool enabled;
  final bool autofocus;
  final double width;
  final FluentDropdownStyle? style;
  final FluentDropdownOptionStyle? optionStyle;

  @override
  State<_CityDropdown> createState() => _CityDropdownState();
}

class _CityDropdownState extends State<_CityDropdown> {
  late String? _value = widget.initial;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.width,
    child: FluentDropdown<String>(
      value: _value,
      options: widget.options,
      placeholder: Text(widget.placeholder),
      appearance: widget.appearance,
      size: widget.size,
      autofocus: widget.autofocus,
      style: widget.style,
      optionStyle: widget.optionStyle,
      semanticLabel: 'City',
      onChanged: widget.enabled
          ? (value) => setState(() => _value = value)
          : null,
    ),
  );
}

/// A dropdown whose value is owned, displayed and written from outside it —
/// which is all "controlled" means here, and all clearing needs.
class _ExternalValue extends StatefulWidget {
  const _ExternalValue({
    required this.presets,
    this.initial,
    this.clearable = false,
  });

  /// Value and button label for each preset.
  final List<(String, String)> presets;
  final String? initial;
  final bool clearable;

  @override
  State<_ExternalValue> createState() => _ExternalValueState();
}

class _ExternalValueState extends State<_ExternalValue> {
  late String? _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.m,
      children: [
        SizedBox(
          width: 260,
          child: FluentDropdown<String>(
            value: _value,
            options: _cities,
            placeholder: const Text('Select a city'),
            semanticLabel: 'City',
            onChanged: (value) => setState(() => _value = value),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: FluentSpacing.s,
          children: [
            for (final (value, label) in widget.presets)
              FluentButton(
                size: FluentButtonSize.small,
                onPressed: () => setState(() => _value = value),
                child: Text(label),
              ),
            if (widget.clearable)
              FluentButton(
                size: FluentButtonSize.small,
                appearance: FluentButtonAppearance.subtle,
                onPressed: _value == null
                    ? null
                    : () => setState(() => _value = null),
                child: const Text('Clear'),
              ),
          ],
        ),
        Text(
          'value: ${_value ?? 'null'}',
          style: theme.typography.caption1.copyWith(
            color: theme.colors.neutralForeground3,
          ),
        ),
      ],
    );
  }
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
