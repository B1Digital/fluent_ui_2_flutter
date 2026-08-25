import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Dropdown docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage dropdownPage = DocsPage(
  id: 'components-dropdown',
  title: 'Dropdown',
  description:
      'A Dropdown is a selection component composed of a button and a list of '
      'options. The button displays the current selected item or a placeholder, '
      'and the list is visible on demand by clicking the button. Dropdowns are '
      'typically used in forms.',
  source: 'lib/pages/components_dropdown.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-dropdown--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-dropdown--appearance',
      title: 'Appearance',
      description:
          'A Dropdown can have the following appearance variants: outline '
          '(default): has a border around all four sides. underline: only has a '
          'bottom border. filled-darker: no border, only a subtle background '
          'color difference against a white page. filled-lighter: no border, '
          'and a white background.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-dropdown--with-field',
      title: 'With Field',
      description:
          'Field can be used with Dropdown to provide a label, description, '
          'error message, and more.',
      builder: _withField,
    ),
    DocsSection(
      id: 'components-dropdown--grouped',
      title: 'Grouped',
      description:
          'Dropdown options can be semantically grouped with the OptionGroup '
          'element, with an optional group label.',
      builder: _grouped,
    ),
    DocsSection(
      id: 'components-dropdown--clearable',
      title: 'Clearable',
      description:
          'A Dropdown can be clearable and let users remove their selection. '
          'Note: this is not supported in multiselect mode yet.',
      builder: _clearable,
    ),
    DocsSection(
      id: 'components-dropdown--complex-options',
      title: 'Complex Options',
      description:
          'Options are defined as JSX children, and can include nested elements '
          "or other components. When this is the case, the Option's text prop "
          'should be the plain text version of the option, and is used as the '
          "Dropdown button's value when the option is selected. Options should "
          'never contain interactive elements, such as buttons or links.',
      builder: _complexOptions,
    ),
    DocsSection(
      id: 'components-dropdown--custom-options',
      title: 'Custom Options',
      description:
          'Options and OptionGroups can be extended and customized.Here '
          'OptionGroup is wrapped in CustomOptionGroup,which adds a custom '
          'label style and takes an options array prop which is mapped to child '
          'Option elements.Option is also wrapped in CustomOption, which adds a '
          'custom check icon and animal icon.The text prop is added to '
          '<Option>, since the children of <Option> are not a simple string.',
      builder: _customOptions,
    ),
    DocsSection(
      id: 'components-dropdown--controlled',
      title: 'Controlled',
      description:
          'A Dropdown may have controlled or controlled selection and value. '
          'When the selection is controlled or a default selection is provided, '
          'a controlled value or default value must also be defined. Otherwise, '
          'the Dropdown will not be able to display a value before the Options '
          'are rendered.',
      builder: _controlled,
    ),
    DocsSection(
      id: 'components-dropdown--multiselect',
      title: 'Multiselect',
      description:
          'Dropdown supports multiselect, and options within a multiselect will '
          'display checkbox icons.',
      builder: _multiselect,
    ),
    DocsSection(
      id: 'components-dropdown--size',
      title: 'Size',
      description:
          "A Dropdown's size can be set to small, medium (default), or large.",
      builder: _size,
    ),
    DocsSection(
      id: 'components-dropdown--disabled',
      title: 'Disabled',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-dropdown--truncated-value',
      title: 'Truncated Value',
      description:
          'The Dropdown button slot can be customized to render child JSX, '
          'which can be used to truncate the selected value text. Dropdown '
          'options can also be customized to overflow in various ways, e.g. by '
          'allowing long words to break and wrap.',
      builder: _truncatedValue,
    ),
    DocsSection(
      id: 'components-dropdown--active-option-change',
      title: 'Active Option Change',
      description:
          'OnActiveOptionChange notifies the user when the active option in the '
          'Dropdown was changed by keyboard. To react on mouse hover events, '
          'use onMouseEnter on the invididual options.',
      builder: _activeOptionChange,
    ),
    DocsSection(
      id: 'components-dropdown--controlling-open-and-close',
      title: 'Controlling Open And Close',
      description:
          'The opening and close of the Dropdown can be controlled with your '
          'own state. The onOpenChange callback will provide the hints for the '
          'state and triggers based on the appropriate event. When controlling '
          'the open state of the Dropdown, extra effort is required to ensure '
          'that interactions are still appropriate and that keyboard '
          'accessibility does not degrade.',
      builder: _controllingOpenAndClose,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'options',
      type: 'List<FluentDropdownOption<T>>',
      description:
          'The rows the popup shows, in order. Headers are included '
          'here.',
    ),
    PropRow(
      name: 'value',
      type: 'T?',
      defaultValue: 'null',
      description: 'The selected value, or null for none.',
    ),
    PropRow(
      name: 'onChanged',
      type: 'ValueChanged<T>?',
      defaultValue: 'null',
      description: 'Invoked with the chosen value. Null disables the dropdown.',
    ),
    PropRow(
      name: 'placeholder',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'What the trigger shows while value selects nothing.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentDropdownAppearance',
      defaultValue: 'FluentDropdownAppearance.outline',
      description: 'Fill and outline treatment.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentDropdownSize',
      defaultValue: 'FluentDropdownSize.medium',
      description: 'Height and type ramp.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentDropdownStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
    PropRow(
      name: 'optionStyle',
      type: 'FluentDropdownOptionStyle?',
      defaultValue: 'null',
      description:
          'Row overrides layered over the theme defaults. Merged '
          'last, so it wins.',
    ),
    PropRow(
      name: 'focusNode',
      type: 'FocusNode?',
      defaultValue: 'null',
      description: 'Focus node to use. One is created internally when omitted.',
    ),
    PropRow(
      name: 'autofocus',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether to take focus on mount.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description:
          'Announced by assistive technology alongside the selected value.',
    ),
  ],
);

// #docregion components-dropdown--default
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  static const List<String> _options = <String>[
    'Cat',
    'Caterpillar',
    'Corgi',
    'Chupacabra',
    'Dog',
    'Ferret',
    'Fish',
    'Fox',
    'Hamster',
    'Snake',
  ];

  String? _value;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    // Prevent the example from taking the full width of the page (optional)
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      // Stack the label above the field with a 2px gap
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        const FluentLabel(child: Text('Best pet')),
        FluentDropdown<String>(
          value: _value,
          placeholder: const Text('Select an animal'),
          onChanged: (String value) => setState(() => _value = value),
          options: <FluentDropdownOption<String>>[
            for (final String option in _options)
              FluentDropdownOption<String>(
                value: option,
                label: Text(option),
                enabled: option != 'Ferret',
              ),
          ],
        ),
      ],
    ),
  );
}
// #enddocregion components-dropdown--default

// #docregion components-dropdown--appearance
// Upstream's `underline` is `FluentDropdownAppearance.transparent` here: no
// fill, no border, only the bottom rule. The two filled variants are painted
// onto an inverted surface, as upstream does, so the contrast note in the
// description is visible.
Widget _appearance(BuildContext context) => const _Appearance();

class _Appearance extends StatefulWidget {
  const _Appearance();

  @override
  State<_Appearance> createState() => _AppearanceState();
}

class _AppearanceState extends State<_Appearance> {
  final Map<FluentDropdownAppearance, String> _values =
      <FluentDropdownAppearance, String>{};

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);
    final FluentColors colors = theme.colors;

    Widget field(
      String heading,
      FluentDropdownAppearance appearance, {
      bool inverted = false,
    }) => Container(
      color: inverted ? colors.neutralBackgroundInverted : null,
      // The griffel `> div` rule: `padding: 5px 20px 10px`.
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.xxs,
        children: <Widget>[
          Text(
            heading,
            style: theme.typography.subtitle2.copyWith(
              color: inverted ? colors.neutralForegroundInverted2 : null,
            ),
          ),
          FluentLabel(
            style: inverted
                ? FluentLabelStyle.from(
                    foregroundColor: colors.neutralForegroundInverted2,
                  )
                : null,
            child: const Text('Select an animal'),
          ),
          FluentDropdown<String>(
            appearance: appearance,
            value: _values[appearance],
            placeholder: const Text('-'),
            onChanged: (String value) =>
                setState(() => _values[appearance] = value),
            options: const <FluentDropdownOption<String>>[
              FluentDropdownOption<String>(value: 'Cat', label: Text('Cat')),
              FluentDropdownOption<String>(value: 'Dog', label: Text('Dog')),
              FluentDropdownOption<String>(value: 'Bird', label: Text('Bird')),
            ],
          ),
        ],
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.xl,
        children: <Widget>[
          field('Outline', FluentDropdownAppearance.outline),
          field('Underline', FluentDropdownAppearance.transparent),
          field(
            'Filled Darker',
            FluentDropdownAppearance.fillDarker,
            inverted: true,
          ),
          field(
            'Filled Lighter',
            FluentDropdownAppearance.fillLighter,
            inverted: true,
          ),
        ],
      ),
    );
  }
}
// #enddocregion components-dropdown--appearance

// #docregion components-dropdown--with-field
Widget _withField(BuildContext context) => const _WithField();

class _WithField extends StatefulWidget {
  const _WithField();

  @override
  State<_WithField> createState() => _WithFieldState();
}

class _WithFieldState extends State<_WithField> {
  static const List<String> _options = <String>[
    'Cat',
    'Caterpillar',
    'Corgi',
    'Chupacabra',
    'Dog',
    'Ferret',
    'Fish',
    'Fox',
    'Hamster',
    'Snake',
  ];

  String? _value;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: FluentField(
      label: const Text('Best pet'),
      required: true,
      hint: const Text("Try picking 'Cat'"),
      child: FluentDropdown<String>(
        value: _value,
        placeholder: const Text('Select an animal'),
        onChanged: (String value) => setState(() => _value = value),
        options: <FluentDropdownOption<String>>[
          for (final String option in _options)
            FluentDropdownOption<String>(
              value: option,
              label: Text(option),
              enabled: option != 'Ferret',
            ),
        ],
      ),
    ),
  );
}
// #enddocregion components-dropdown--with-field

// #docregion components-dropdown--grouped
// Upstream nests `Option`s inside an `OptionGroup`. `FluentDropdownOption` is a
// flat model, so a group is a `FluentDropdownOption.header` followed by its
// values — the popup draws the separator rule above every header but the first.
Widget _grouped(BuildContext context) => const _Grouped();

class _Grouped extends StatefulWidget {
  const _Grouped();

  @override
  State<_Grouped> createState() => _GroupedState();
}

class _GroupedState extends State<_Grouped> {
  static const List<String> _land = <String>['Cat', 'Dog', 'Ferret', 'Hamster'];
  static const List<String> _water = <String>[
    'Fish',
    'Jellyfish',
    'Octopus',
    'Seal',
  ];

  String? _value;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        const FluentLabel(child: Text('Best pet')),
        FluentDropdown<String>(
          value: _value,
          placeholder: const Text('Select an animal'),
          onChanged: (String value) => setState(() => _value = value),
          options: <FluentDropdownOption<String>>[
            const FluentDropdownOption<String>.header(label: Text('Land')),
            for (final String option in _land)
              FluentDropdownOption<String>(
                value: option,
                label: Text(option),
                enabled: option != 'Ferret',
              ),
            const FluentDropdownOption<String>.header(label: Text('Sea')),
            for (final String option in _water)
              FluentDropdownOption<String>(value: option, label: Text(option)),
          ],
        ),
      ],
    ),
  );
}
// #enddocregion components-dropdown--grouped

// #docregion components-dropdown--clearable
// `FluentDropdown` has no `clearable` flag and no clear-button slot inside the
// trigger, so the clear affordance is composed beside it: a subtle icon button
// that is disabled until something is selected.
Widget _clearable(BuildContext context) => const _Clearable();

class _Clearable extends StatefulWidget {
  const _Clearable();

  @override
  State<_Clearable> createState() => _ClearableState();
}

class _ClearableState extends State<_Clearable> {
  String? _value;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        const FluentLabel(child: Text('Pick a color')),
        Row(
          spacing: FluentSpacing.xs,
          children: <Widget>[
            Expanded(
              child: FluentDropdown<String>(
                value: _value,
                placeholder: const Text('Select a color'),
                onChanged: (String value) => setState(() => _value = value),
                options: const <FluentDropdownOption<String>>[
                  FluentDropdownOption<String>(
                    value: 'Red',
                    label: Text('Red'),
                  ),
                  FluentDropdownOption<String>(
                    value: 'Green',
                    label: Text('Green'),
                  ),
                  FluentDropdownOption<String>(
                    value: 'Blue',
                    label: Text('Blue'),
                  ),
                ],
              ),
            ),
            FluentButton.icon(
              icon: const Icon(FluentIcons.dismiss_20_regular),
              semanticLabel: 'Clear selection',
              appearance: FluentButtonAppearance.subtle,
              onPressed: _value == null
                  ? null
                  : () => setState(() => _value = null),
            ),
          ],
        ),
      ],
    ),
  );
}
// #enddocregion components-dropdown--clearable

// #docregion components-dropdown--complex-options
// The trigger renders the chosen option's `label` — here the whole persona —
// where upstream renders its `text`. `text` is still supplied, because it is
// what assistive technology announces for the row.
Widget _complexOptions(BuildContext context) => const _ComplexOptions();

class _ComplexOptions extends StatefulWidget {
  const _ComplexOptions();

  @override
  State<_ComplexOptions> createState() => _ComplexOptionsState();
}

class _ComplexOptionsState extends State<_ComplexOptions> {
  String? _value;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        const FluentLabel(child: Text('Schedule a meeting')),
        FluentDropdown<String>(
          value: _value,
          onChanged: (String value) => setState(() => _value = value),
          options: const <FluentDropdownOption<String>>[
            FluentDropdownOption<String>(
              value: 'Katri Athokas',
              text: 'Katri Athokas',
              label: FluentPersona(
                name: 'Katri Athokas',
                status: FluentPresenceStatus.available,
                secondary: Text('Available'),
              ),
            ),
            FluentDropdownOption<String>(
              value: 'Elvia Atkins',
              text: 'Elvia Atkins',
              label: FluentPersona(
                name: 'Elvia Atkins',
                status: FluentPresenceStatus.busy,
                secondary: Text('Busy'),
              ),
            ),
            FluentDropdownOption<String>(
              value: 'Cameron Evans',
              text: 'Cameron Evans',
              label: FluentPersona(
                name: 'Cameron Evans',
                status: FluentPresenceStatus.away,
                secondary: Text('Away'),
              ),
            ),
            FluentDropdownOption<String>(
              value: 'Wanda Howard',
              text: 'Wanda Howard',
              label: FluentPersona(
                name: 'Wanda Howard',
                status: FluentPresenceStatus.outOfOffice,
                secondary: Text('Out of office'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
// #enddocregion components-dropdown--complex-options

// #docregion components-dropdown--custom-options
// Upstream's `CustomOption` also swaps the row's check glyph for
// `CheckboxChecked24Regular`. The checkmark is not a slot here — `optionStyle`
// tints and sizes it but cannot replace it — so the row keeps Fluent's
// checkmark and only the animal icon and the italic group label are custom.
Widget _customOptions(BuildContext context) => const _CustomOptions();

class _CustomOptions extends StatefulWidget {
  const _CustomOptions();

  @override
  State<_CustomOptions> createState() => _CustomOptionsState();
}

class _CustomOptionsState extends State<_CustomOptions> {
  static const Map<String, IconData> _animalIcons = <String, IconData>{
    'Cat': FluentIcons.animal_cat_24_filled,
    'Dog': FluentIcons.animal_dog_24_filled,
    'Rabbit': FluentIcons.animal_rabbit_24_filled,
    'Turtle': FluentIcons.animal_turtle_24_filled,
    'Fish': FluentIcons.food_fish_24_filled,
  };

  static const List<String> _land = <String>['Cat', 'Dog', 'Rabbit'];
  static const List<String> _water = <String>['Fish', 'Turtle'];

  String? _value;

  FluentDropdownOption<String> _option(String animal) =>
      FluentDropdownOption<String>(
        value: animal,
        text: animal,
        label: Row(
          spacing: 5,
          children: <Widget>[
            Icon(_animalIcons[animal], size: 24),
            Flexible(child: Text(animal)),
          ],
        ),
      );

  FluentDropdownOption<String> _group(String label) =>
      FluentDropdownOption<String>.header(
        label: Text(label, style: const TextStyle(fontStyle: FontStyle.italic)),
      );

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        const FluentLabel(child: Text('Best pet')),
        FluentDropdown<String>(
          value: _value,
          placeholder: const Text('Select an animal'),
          onChanged: (String value) => setState(() => _value = value),
          // The griffel `listbox` rule: `maxHeight: 200px`.
          style: FluentDropdownStyle.from(surfaceMaxHeight: 200),
          options: <FluentDropdownOption<String>>[
            _group('Land'),
            ..._land.map(_option),
            _group('Sea'),
            ..._water.map(_option),
          ],
        ),
      ],
    ),
  );
}
// #enddocregion components-dropdown--custom-options

// #docregion components-dropdown--controlled
// Every Fluent control in this port is controlled, so upstream's "default
// selection" field is the same code as the controlled one with its state
// seeded to 'eatkins' — there is no uncontrolled mode to contrast it with.
Widget _controlled(BuildContext context) => const _Controlled();

class _Controlled extends StatefulWidget {
  const _Controlled();

  @override
  State<_Controlled> createState() => _ControlledState();
}

class _ControlledState extends State<_Controlled> {
  String? _defaultSelection = 'eatkins';
  String? _selectedOption = 'eatkins';

  static const List<FluentDropdownOption<String>> _options =
      <FluentDropdownOption<String>>[
        FluentDropdownOption<String>(
          value: 'kathok',
          text: 'Katri Athokas',
          label: FluentPersona(
            name: 'Katri Athokas',
            status: FluentPresenceStatus.available,
            secondary: Text('Available'),
          ),
        ),
        FluentDropdownOption<String>(
          value: 'eatkins',
          text: 'Elvia Atkins',
          label: FluentPersona(
            name: 'Elvia Atkins',
            status: FluentPresenceStatus.busy,
            secondary: Text('Busy'),
          ),
        ),
        FluentDropdownOption<String>(
          value: 'cevans',
          text: 'Cameron Evans',
          label: FluentPersona(
            name: 'Cameron Evans',
            status: FluentPresenceStatus.away,
            secondary: Text('Away'),
          ),
        ),
        FluentDropdownOption<String>(
          value: 'whoward',
          text: 'Wanda Howard',
          label: FluentPersona(
            name: 'Wanda Howard',
            status: FluentPresenceStatus.outOfOffice,
            secondary: Text('Out of office'),
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xl,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: FluentSpacing.xxs,
          children: <Widget>[
            const FluentLabel(
              child: Text('Schedule a meeting (default selection)'),
            ),
            FluentDropdown<String>(
              value: _defaultSelection,
              options: _options,
              onChanged: (String value) =>
                  setState(() => _defaultSelection = value),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: FluentSpacing.xxs,
          children: <Widget>[
            const FluentLabel(
              child: Text('Schedule a meeting (controlled selection)'),
            ),
            FluentDropdown<String>(
              value: _selectedOption,
              options: _options,
              onChanged: (String value) =>
                  setState(() => _selectedOption = value),
            ),
          ],
        ),
      ],
    ),
  );
}
// #enddocregion components-dropdown--controlled

// #docregion components-dropdown--multiselect
// `FluentDropdown` models single selection only — no `multiselect` flag, and
// `value` is one option's value. The set of chosen animals is held here
// instead: each row draws its own checkbox glyph, `onChanged` toggles
// membership rather than replacing the value, and the trigger shows the join
// through the placeholder slot. The popup still closes on each pick, where
// upstream's multiselect keeps it open.
Widget _multiselect(BuildContext context) => const _Multiselect();

class _Multiselect extends StatefulWidget {
  const _Multiselect();

  @override
  State<_Multiselect> createState() => _MultiselectState();
}

class _MultiselectState extends State<_Multiselect> {
  static const List<String> _options = <String>[
    'Cat',
    'Dog',
    'Ferret',
    'Fish',
    'Hamster',
    'Snake',
  ];

  final Set<String> _selected = <String>{};

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        const FluentLabel(child: Text('Best pet')),
        FluentDropdown<String>(
          placeholder: Text(
            _selected.isEmpty ? 'Select an animal' : _selected.join(', '),
          ),
          onChanged: (String value) => setState(() {
            if (!_selected.remove(value)) _selected.add(value);
          }),
          options: <FluentDropdownOption<String>>[
            for (final String option in _options)
              FluentDropdownOption<String>(
                value: option,
                text: option,
                enabled: option != 'Ferret',
                label: Row(
                  spacing: FluentSpacing.s,
                  children: <Widget>[
                    Icon(
                      _selected.contains(option)
                          ? FluentIcons.checkbox_checked_24_regular
                          : FluentIcons.checkbox_unchecked_24_regular,
                      size: 20,
                    ),
                    Flexible(child: Text(option)),
                  ],
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
// #enddocregion components-dropdown--multiselect

// #docregion components-dropdown--size
Widget _size(BuildContext context) => const _Size();

class _Size extends StatefulWidget {
  const _Size();

  @override
  State<_Size> createState() => _SizeState();
}

class _SizeState extends State<_Size> {
  final Map<FluentDropdownSize, String> _values =
      <FluentDropdownSize, String>{};

  @override
  Widget build(BuildContext context) {
    Widget field(String heading, FluentDropdownSize size) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        Text(heading, style: FluentTheme.of(context).typography.subtitle2),
        const FluentLabel(child: Text('Best pet')),
        FluentDropdown<String>(
          size: size,
          value: _values[size],
          placeholder: const Text('Select an animal'),
          onChanged: (String value) => setState(() => _values[size] = value),
          options: const <FluentDropdownOption<String>>[
            FluentDropdownOption<String>(value: 'Cat', label: Text('Cat')),
            FluentDropdownOption<String>(value: 'Dog', label: Text('Dog')),
            FluentDropdownOption<String>(value: 'Bird', label: Text('Bird')),
          ],
        ),
      ],
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FluentSpacing.xl,
        children: <Widget>[
          field('Small', FluentDropdownSize.small),
          field('Medium', FluentDropdownSize.medium),
          field('Large', FluentDropdownSize.large),
        ],
      ),
    );
  }
}
// #enddocregion components-dropdown--size

// #docregion components-dropdown--disabled
// `onChanged: null` disables the dropdown: it stops reporting hover and press,
// refuses focus, never opens, and swaps to the disabled token ramp.
Widget _disabled(BuildContext context) => ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 400),
  child: const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: FluentSpacing.xxs,
    children: <Widget>[
      FluentLabel(child: Text('Best pet')),
      FluentDropdown<String>(
        placeholder: Text('Select an animal'),
        options: <FluentDropdownOption<String>>[
          FluentDropdownOption<String>(value: 'Cat', label: Text('Cat')),
          FluentDropdownOption<String>(value: 'Dog', label: Text('Dog')),
          FluentDropdownOption<String>(value: 'Ferret', label: Text('Ferret')),
          FluentDropdownOption<String>(value: 'Fish', label: Text('Fish')),
          FluentDropdownOption<String>(
            value: 'Hamster',
            label: Text('Hamster'),
          ),
          FluentDropdownOption<String>(value: 'Snake', label: Text('Snake')),
        ],
      ),
    ],
  ),
);
// #enddocregion components-dropdown--disabled

// #docregion components-dropdown--truncated-value
// No `button` slot to override: the trigger already clamps its value to one
// line and ellipsizes it, so narrowing the example to 200 is the whole story.
// Option rows wrap their own text, which is upstream's `overflowWrap`.
Widget _truncatedValue(BuildContext context) => const _TruncatedValue();

class _TruncatedValue extends StatefulWidget {
  const _TruncatedValue();

  @override
  State<_TruncatedValue> createState() => _TruncatedValueState();
}

class _TruncatedValueState extends State<_TruncatedValue> {
  static const List<String> _options = <String>[
    'Cat',
    'Caterpillar',
    'Corgi',
    'Chupacabra',
    'Dog',
    'Ferret',
    'Fish',
    'Fox',
    'Hamster',
    'Snake',
    'SuperLongName_123456789_SomeMoreStuffToMakeItLonger@fluentui.dev',
    'Screaming hairy armadillo (Chaetophractus vellerosus)',
  ];

  // show truncated option by default
  String? _value = _options[11];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 200),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        const FluentLabel(child: Text('Best pet')),
        FluentDropdown<String>(
          value: _value,
          placeholder: const Text('Select an animal'),
          onChanged: (String value) => setState(() => _value = value),
          // The griffel `listbox` rule: `maxHeight: 200px`.
          style: FluentDropdownStyle.from(surfaceMaxHeight: 200),
          options: <FluentDropdownOption<String>>[
            for (final String option in _options)
              FluentDropdownOption<String>(
                value: option,
                text: option,
                label: Text(option),
                enabled: option != 'Ferret',
              ),
          ],
        ),
      ],
    ),
  );
}
// #enddocregion components-dropdown--truncated-value

// #docregion components-dropdown--active-option-change
// There is no `onActiveOptionChange`: the active row lives inside
// `FluentDropdown` and is never reported out, and rows are not hover
// callbacks either. `onChanged` is the nearest hook, so the line above the
// field reports the option that was committed rather than the one passed over.
Widget _activeOptionChange(BuildContext context) => const _ActiveOptionChange();

class _ActiveOptionChange extends StatefulWidget {
  const _ActiveOptionChange();

  @override
  State<_ActiveOptionChange> createState() => _ActiveOptionChangeState();
}

class _ActiveOptionChangeState extends State<_ActiveOptionChange> {
  String _activeOptionText = '';
  String? _value;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        Text(_activeOptionText),
        const FluentLabel(child: Text('Schedule a meeting')),
        FluentDropdown<String>(
          value: _value,
          onChanged: (String value) => setState(() {
            _value = value;
            _activeOptionText = value;
          }),
          options: const <FluentDropdownOption<String>>[
            FluentDropdownOption<String>(
              value: 'Katri Athokas',
              text: 'Katri Athokas',
              label: FluentPersona(
                name: 'Katri Athokas',
                status: FluentPresenceStatus.available,
                secondary: Text('Available'),
              ),
            ),
            FluentDropdownOption<String>(
              value: 'Elvia Atkins',
              text: 'Elvia Atkins',
              label: FluentPersona(
                name: 'Elvia Atkins',
                status: FluentPresenceStatus.busy,
                secondary: Text('Busy'),
              ),
            ),
            FluentDropdownOption<String>(
              value: 'Cameron Evans',
              text: 'Cameron Evans',
              label: FluentPersona(
                name: 'Cameron Evans',
                status: FluentPresenceStatus.away,
                secondary: Text('Away'),
              ),
            ),
            FluentDropdownOption<String>(
              value: 'Wanda Howard',
              text: 'Wanda Howard',
              label: FluentPersona(
                name: 'Wanda Howard',
                status: FluentPresenceStatus.outOfOffice,
                secondary: Text('Out of office'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
// #enddocregion components-dropdown--active-option-change

// #docregion components-dropdown--controlling-open-and-close
// `FluentDropdown` owns its popup: it takes neither `open` nor `onOpenChange`,
// and focus leaving the trigger closes the list, which is what makes "focus
// returns to the trigger on close" structural rather than remembered. So the
// checkbox drives the popup the way the keyboard does — through the trigger's
// own focus node and the intents the widget already binds Enter and Escape to.
// Focusing before activating is what a pointer press on the trigger does too:
// the arrow keys only reach the popup from the trigger's node.
//
// One gap remains, the same one `components_menu_menu.dart` documents: a list
// dismissed by clicking outside closes without telling the checkbox, because
// that is what an `onOpenChange` would carry and there is no hook for it. A
// commit is reported, so `onChanged` puts the checkbox back itself.
Widget _controllingOpenAndClose(BuildContext context) =>
    const _ControllingOpenAndClose();

class _ControllingOpenAndClose extends StatefulWidget {
  const _ControllingOpenAndClose();

  @override
  State<_ControllingOpenAndClose> createState() =>
      _ControllingOpenAndCloseState();
}

class _ControllingOpenAndCloseState extends State<_ControllingOpenAndClose> {
  static const List<String> _options = <String>[
    'Cat',
    'Caterpillar',
    'Corgi',
    'Chupacabra',
    'Dog',
    'Ferret',
    'Fish',
    'Fox',
    'Hamster',
    'Snake',
  ];

  final FocusNode _trigger = FocusNode(debugLabel: 'Controlled dropdown');
  bool _open = false;
  String? _value;

  @override
  void dispose() {
    _trigger.dispose();
    super.dispose();
  }

  void _setOpen(bool next) {
    if (next == _open) return;
    setState(() => _open = next);
    final BuildContext? trigger = _trigger.context;
    if (trigger == null) return;
    if (next) {
      _trigger.requestFocus();
      Actions.maybeInvoke(trigger, const FluentDropdownActivateIntent());
    } else {
      // Escape's intent, not activation's: activating an open list commits the
      // active row, and closing must not pick anything.
      Actions.maybeInvoke(trigger, const DismissIntent());
    }
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FluentSpacing.xxs,
      children: <Widget>[
        FluentCheckbox(
          checked: _open,
          label: const Text('open'),
          onChanged: (bool? checked) => _setOpen(checked ?? false),
        ),
        const FluentLabel(child: Text('Best pet')),
        FluentDropdown<String>(
          value: _value,
          focusNode: _trigger,
          placeholder: const Text('Select an animal'),
          onChanged: (String value) => setState(() {
            _value = value;
            // Committing closes the popup, so the checkbox has to follow.
            _open = false;
          }),
          options: <FluentDropdownOption<String>>[
            for (final String option in _options)
              FluentDropdownOption<String>(
                value: option,
                label: Text(option),
                enabled: option != 'Ferret',
              ),
          ],
        ),
      ],
    ),
  );
}

// #enddocregion components-dropdown--controlling-open-and-close
