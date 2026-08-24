import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The TagPicker docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage tagpickerPage = DocsPage(
  id: 'components-tagpicker',
  title: 'TagPicker',
  description:
      'A TagPicker combines a text field and a dropdown giving people a way to '
      'select an option from a list or enter their own choice. It is a '
      'specialized version of a Combobox where selecting an option from a list '
      'results in a Tag being added close to the text field.',
  source: 'lib/pages/components_tagpicker.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-tagpicker--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-tagpicker--button',
      title: 'Button',
      description:
          'The component TagPickerButton renders an "invisible" button that can '
          'be used instead of TagPickerInput to opt-out of a text field and to '
          'provide something similar to a Dropdown behavior.',
      builder: _button,
    ),
    DocsSection(
      id: 'components-tagpicker--filtering',
      title: 'Filtering',
      description:
          'TagPicker can take advantage of the provided useTagPickerFilter hook '
          'to filter the options based on the user-typed string. It can be '
          'configured for a custom filter function, custom message, and custom '
          'render function. disableAutoFocus is used here to control whether '
          'the first option is automatically focused when the popover opens. '
          'When the user opens the popover via keyboard (no query), auto focus '
          'is disabled to avoid jumping to the first option. When the user '
          'types a query, auto focus is enabled so the first matching option is '
          'highlighted.',
      builder: _filtering,
    ),
    DocsSection(
      id: 'components-tagpicker--size',
      title: 'Size',
      description:
          "A TagPicker's size can be set to medium (default), large or "
          'extra-large.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-tagpicker--appearance',
      title: 'Appearance',
      description:
          'A TagPicker can have the following appearance variants: outline '
          '(default): has a border around all four sides. underline: only has a '
          'bottom border. filled-darker: no border, only a subtle background '
          'color difference against a white page. All tags will be by default '
          'outline. filled-lighter: no border, and a white background. This is '
          'equivalent to the Combobox appearance property.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-tagpicker--disabled',
      title: 'Disabled',
      description:
          'A TagPicker can be disabled. Disabling TagPicker will disable the '
          "access to the TagPickerList, but it'll still allow modifications to "
          'the selectedOptions. The Tag component can also be disabled, in the '
          'case where that given tag should not be reachable',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-tagpicker--expand-icon',
      title: 'Expand Icon',
      description:
          'TagPickerControl provides an expandIcon slot for modifying the '
          'default expandIcon chevron. You can also remove the slot entirely by '
          'providing null to it.',
      builder: _expandIcon,
    ),
    DocsSection(
      id: 'components-tagpicker--secondary-action',
      title: 'Secondary Action',
      description:
          'TagPickerControl provides a secondaryAction slot for possible extra '
          'functionalities that may be desired. secondaryAction slot is '
          'absolute positioned on the top right corner of the control component '
          'together with expandIcon slot.',
      builder: _secondaryAction,
    ),
    DocsSection(
      id: 'components-tagpicker--grouped',
      title: 'Grouped',
      builder: _grouped,
    ),
    DocsSection(
      id: 'components-tagpicker--truncated-text',
      title: 'Truncated Text',
      description:
          'Text truncation is a common pattern used to handle long text that '
          "doesn't fit within the available space. There are all sorts of ways "
          "to truncate text, in this example we're show casing two ways to "
          'truncate text: Using CSS to truncate text with ellipsis when the '
          'element reaches the end of its container. Using fixed width to '
          'truncate text with ellipsis when the text is longer than a certain '
          'width (50px in this case). We do not support text truncation out of '
          "the box, as it's a complex and opinionated problem. However, you can "
          'easily achieve text truncation by using patterns like the ones shown '
          'in this example.',
      builder: _truncatedText,
    ),
    DocsSection(
      id: 'components-tagpicker--single-select',
      title: 'Single Select',
      description:
          'By default, the TagPicker allows you to have multiple tags selected '
          '. To enable single selection, you can manage the selected options '
          'state yourself and pass only one selected option to the TagPicker '
          'component.',
      builder: _singleSelect,
    ),
    DocsSection(
      id: 'components-tagpicker--no-popover',
      title: 'No Popover',
      description:
          'You can use the TagPicker without the popover with the list of '
          'options by providing the noPopover property. This is useful when you '
          'want to allow users to input their own tags. All you have to do is '
          'control the TagPickerInput value and handle the onKeyDown event to '
          'add the tag to the TagPicker when the user presses the Enter key.',
      builder: _noPopover,
    ),
    DocsSection(
      id: 'components-tagpicker--single-line',
      title: 'Single Line',
      builder: _singleLine,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'options',
      type: 'List<FluentTagPickerOption<T>>',
      description:
          'Every row the popup can show, in order. Headers are '
          'included here.',
    ),
    PropRow(
      name: 'selected',
      type: 'List<T>',
      defaultValue: '[]',
      description: 'The chosen values, in the order they are shown.',
    ),
    PropRow(
      name: 'onChanged',
      type: 'ValueChanged<List<T>>?',
      defaultValue: 'null',
      description:
          'Invoked with the new selection whenever a chip is added or removed. '
          'Null disables the picker.',
    ),
    PropRow(
      name: 'placeholder',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'Shown while the field is empty.',
    ),
    PropRow(
      name: 'secondaryAction',
      type: 'Widget?',
      defaultValue: 'null',
      description: "The trailing action — Fluent's TagPicker/Secondary action.",
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentTagPickerAppearance',
      defaultValue: 'FluentTagPickerAppearance.outline',
      description: 'Fill and outline treatment.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentTagPickerSize',
      defaultValue: 'FluentTagPickerSize.medium',
      description: 'Control height.',
    ),
    PropRow(
      name: 'controller',
      type: 'TextEditingController?',
      defaultValue: 'null',
      description:
          'The query being typed. One is created internally when omitted.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description:
          'Announced by assistive technology. Use it when no visible label '
          'names the picker.',
    ),
    PropRow(
      name: 'dismissSemanticLabel',
      type: 'String',
      defaultValue: "'Remove'",
      description:
          "Announced for a chip's dismiss half, which has no text of its own.",
    ),
  ],
);

// #docregion components-tagpicker--default
// `Avatar color="colorful"` hashes the name to a palette family and `Avatar
// name` derives the initials; `FluentAvatar` does neither, so both are spelled
// out per employee. `TagPickerGroup aria-label="Selected Employees"` has no
// port either — the chips are not a separately labellable group here.
typedef _DefaultEmployee = ({
  String name,
  String initials,
  FluentAvatarColor color,
});

const List<_DefaultEmployee> _defaultEmployees = <_DefaultEmployee>[
  (name: 'John Doe', initials: 'JD', color: FluentAvatarColor.peach),
  (name: 'Jane Doe', initials: 'JD', color: FluentAvatarColor.platinum),
  (name: 'Max Mustermann', initials: 'MM', color: FluentAvatarColor.seafoam),
  (name: 'Erika Mustermann', initials: 'EM', color: FluentAvatarColor.lavender),
  (name: 'Pierre Dupont', initials: 'PD', color: FluentAvatarColor.cornflower),
  (name: 'Amelie Dupont', initials: 'AD', color: FluentAvatarColor.marigold),
  (name: 'Mario Rossi', initials: 'MR', color: FluentAvatarColor.steel),
  (name: 'Maria Rossi', initials: 'MR', color: FluentAvatarColor.teal),
];

FluentTagPickerOption<String> _defaultOption(_DefaultEmployee employee) =>
    FluentTagPickerOption<String>(
      value: employee.name,
      label: Text(employee.name),
      media: FluentAvatar(
        name: employee.name,
        initials: employee.initials,
        color: employee.color,
        shape: FluentAvatarShape.square,
        size: FluentAvatarSize.size16,
      ),
    );

Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  List<String> _selected = <String>[];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: FluentField(
      label: const Text('Select Employees'),
      child: FluentTagPicker<String>(
        semanticLabel: 'Select Employees',
        selected: _selected,
        onChanged: (List<String> values) => setState(() => _selected = values),
        options: <FluentTagPickerOption<String>>[
          // The picker already drops the chosen values from the popup, so the
          // whole list is handed over; it also needs every chosen value's
          // option to render that value's chip.
          for (final _DefaultEmployee employee in _defaultEmployees)
            _defaultOption(employee),
          if (_selected.length == _defaultEmployees.length)
            const FluentTagPickerOption<String>(
              value: 'no-options',
              label: Text('No options available'),
              enabled: false,
            ),
        ],
      ),
    ),
  );
}
// #enddocregion components-tagpicker--default

// #docregion components-tagpicker--button
// `TagPickerButton` — an invisible button in place of the text field — has no
// port: `FluentTagPicker` always composes a `FluentInput`. The picker below is
// therefore the ordinary one; only the typing is extra.
//
// `TagPickerOption secondaryContent` has no port either. The option's `label`
// doubles as the chip's content, so a second line there would land inside every
// tag; upstream's "Microsoft FTE" rides in `text` instead, which is what
// assistive technology reads.
typedef _ButtonEmployee = ({
  String name,
  String initials,
  FluentAvatarColor color,
});

const List<_ButtonEmployee> _buttonEmployees = <_ButtonEmployee>[
  (name: 'John Doe', initials: 'JD', color: FluentAvatarColor.peach),
  (name: 'Jane Doe', initials: 'JD', color: FluentAvatarColor.platinum),
  (name: 'Max Mustermann', initials: 'MM', color: FluentAvatarColor.seafoam),
  (name: 'Erika Mustermann', initials: 'EM', color: FluentAvatarColor.lavender),
  (name: 'Pierre Dupont', initials: 'PD', color: FluentAvatarColor.cornflower),
  (name: 'Amelie Dupont', initials: 'AD', color: FluentAvatarColor.marigold),
  (name: 'Mario Rossi', initials: 'MR', color: FluentAvatarColor.steel),
  (name: 'Maria Rossi', initials: 'MR', color: FluentAvatarColor.teal),
];

FluentTagPickerOption<String> _buttonOption(_ButtonEmployee employee) =>
    FluentTagPickerOption<String>(
      value: employee.name,
      label: Text(employee.name),
      text: '${employee.name}, Microsoft FTE',
      media: FluentAvatar(
        name: employee.name,
        initials: employee.initials,
        color: employee.color,
        shape: FluentAvatarShape.square,
        size: FluentAvatarSize.size16,
      ),
    );

Widget _button(BuildContext context) => const _Button();

class _Button extends StatefulWidget {
  const _Button();

  @override
  State<_Button> createState() => _ButtonState();
}

class _ButtonState extends State<_Button> {
  List<String> _selected = <String>[];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: FluentField(
      label: const Text('Select Employees'),
      child: FluentTagPicker<String>(
        semanticLabel: 'Select Employees',
        selected: _selected,
        onChanged: (List<String> values) => setState(() => _selected = values),
        options: <FluentTagPickerOption<String>>[
          for (final _ButtonEmployee employee in _buttonEmployees)
            _buttonOption(employee),
          if (_selected.length == _buttonEmployees.length)
            const FluentTagPickerOption<String>(
              value: 'no-options',
              label: Text('No options available'),
              enabled: false,
            ),
        ],
      ),
    ),
  );
}
// #enddocregion components-tagpicker--button

// #docregion components-tagpicker--filtering
// `useTagPickerFilter` has no port: `FluentTagPicker` renders the `options` it
// is given, so the filter is a list comprehension over the picker's own
// `controller`. `disableAutoFocus` has no port either — the first selectable
// row is always the active one when the popup opens.
//
// The filtered list is mutated in place and deliberately WITHOUT `setState`.
// The picker listens to the same controller and rebuilds itself on every
// keystroke, so it picks the new rows up; handing it a fresh list from here
// instead would rebuild the picker from its parent, and a parent rebuild while
// the popup is open asks an overlay to rebuild mid-build. The cost is that a
// popup already on screen keeps its rows until it is reopened.
typedef _FilteringEmployee = ({
  String name,
  String initials,
  FluentAvatarColor color,
});

const List<_FilteringEmployee> _filteringEmployees = <_FilteringEmployee>[
  (name: 'John Doe', initials: 'JD', color: FluentAvatarColor.peach),
  (name: 'Jane Doe', initials: 'JD', color: FluentAvatarColor.platinum),
  (name: 'Max Mustermann', initials: 'MM', color: FluentAvatarColor.seafoam),
  (name: 'Erika Mustermann', initials: 'EM', color: FluentAvatarColor.lavender),
  (name: 'Pierre Dupont', initials: 'PD', color: FluentAvatarColor.cornflower),
  (name: 'Amelie Dupont', initials: 'AD', color: FluentAvatarColor.marigold),
  (name: 'Mario Rossi', initials: 'MR', color: FluentAvatarColor.steel),
  (name: 'Maria Rossi', initials: 'MR', color: FluentAvatarColor.teal),
];

FluentTagPickerOption<String> _filteringOption(_FilteringEmployee employee) =>
    FluentTagPickerOption<String>(
      value: employee.name,
      label: Text(employee.name),
      text: '${employee.name}, Microsoft FTE',
      media: FluentAvatar(
        name: employee.name,
        initials: employee.initials,
        color: employee.color,
        shape: FluentAvatarShape.square,
        size: FluentAvatarSize.size16,
      ),
    );

Widget _filtering(BuildContext context) => const _Filtering();

class _Filtering extends StatefulWidget {
  const _Filtering();

  @override
  State<_Filtering> createState() => _FilteringState();
}

class _FilteringState extends State<_Filtering> {
  final TextEditingController _query = TextEditingController();
  final List<FluentTagPickerOption<String>> _options =
      <FluentTagPickerOption<String>>[];
  List<String> _selected = <String>[];

  @override
  void initState() {
    super.initState();
    _filter();
    _query.addListener(_filter);
  }

  @override
  void dispose() {
    _query
      ..removeListener(_filter)
      ..dispose();
    super.dispose();
  }

  void _filter() {
    final String query = _query.text.toLowerCase();
    final List<_FilteringEmployee> matches = <_FilteringEmployee>[
      for (final _FilteringEmployee employee in _filteringEmployees)
        if (!_selected.contains(employee.name) &&
            employee.name.toLowerCase().contains(query))
          employee,
    ];
    _options
      ..clear()
      ..addAll(<FluentTagPickerOption<String>>[
        for (final _FilteringEmployee employee in _filteringEmployees)
          // A chosen value keeps its option so its chip can still render; the
          // picker filters the chosen ones out of the popup itself.
          if (_selected.contains(employee.name) || matches.contains(employee))
            _filteringOption(employee),
        if (matches.isEmpty)
          const FluentTagPickerOption<String>(
            value: 'no-matches',
            label: Text("We couldn't find any matches"),
            enabled: false,
          ),
      ]);
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: FluentField(
      label: const Text('Select Employees'),
      child: FluentTagPicker<String>(
        semanticLabel: 'Select Employees',
        controller: _query,
        selected: _selected,
        options: _options,
        onChanged: (List<String> values) => setState(() {
          _selected = values;
          _filter();
        }),
      ),
    ),
  );
}
// #enddocregion components-tagpicker--filtering

// #docregion components-tagpicker--size
typedef _SizeEmployee = ({
  String name,
  String initials,
  FluentAvatarColor color,
});

const List<_SizeEmployee> _sizeEmployees = <_SizeEmployee>[
  (name: 'John Doe', initials: 'JD', color: FluentAvatarColor.peach),
  (name: 'Jane Doe', initials: 'JD', color: FluentAvatarColor.platinum),
  (name: 'Max Mustermann', initials: 'MM', color: FluentAvatarColor.seafoam),
  (name: 'Erika Mustermann', initials: 'EM', color: FluentAvatarColor.lavender),
  (name: 'Pierre Dupont', initials: 'PD', color: FluentAvatarColor.cornflower),
  (name: 'Amelie Dupont', initials: 'AD', color: FluentAvatarColor.marigold),
  (name: 'Mario Rossi', initials: 'MR', color: FluentAvatarColor.steel),
  (name: 'Maria Rossi', initials: 'MR', color: FluentAvatarColor.teal),
];

FluentTagPickerOption<String> _sizeOption(_SizeEmployee employee) =>
    FluentTagPickerOption<String>(
      value: employee.name,
      label: Text(employee.name),
      text: '${employee.name}, Microsoft FTE',
      media: FluentAvatar(
        name: employee.name,
        initials: employee.initials,
        color: employee.color,
        shape: FluentAvatarShape.square,
        size: FluentAvatarSize.size16,
      ),
    );

Widget _size(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  spacing: 20,
  children: <Widget>[
    _SizeExample(title: 'Extra Large', size: FluentTagPickerSize.extraLarge),
    _SizeExample(title: 'Large', size: FluentTagPickerSize.large),
    _SizeExample(title: 'Medium', size: FluentTagPickerSize.medium),
  ],
);

class _SizeExample extends StatefulWidget {
  const _SizeExample({required this.title, required this.size});

  final String title;
  final FluentTagPickerSize size;

  @override
  State<_SizeExample> createState() => _SizeExampleState();
}

class _SizeExampleState extends State<_SizeExample> {
  List<String> _selected = <String>[_sizeEmployees.first.name];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: <Widget>[
      Text(widget.title, style: FluentTheme.of(context).typography.subtitle2),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: FluentField(
          label: const Text('Select Employees'),
          child: FluentTagPicker<String>(
            semanticLabel: 'Select Employees',
            size: widget.size,
            selected: _selected,
            onChanged: (List<String> values) =>
                setState(() => _selected = values),
            options: <FluentTagPickerOption<String>>[
              for (final _SizeEmployee employee in _sizeEmployees)
                _sizeOption(employee),
              if (_selected.length == _sizeEmployees.length)
                const FluentTagPickerOption<String>(
                  value: 'no-options',
                  label: Text('No options available'),
                  enabled: false,
                ),
            ],
          ),
        ),
      ),
    ],
  );
}
// #enddocregion components-tagpicker--size

// #docregion components-tagpicker--appearance
// Upstream's `underline` is spelled `FluentTagPickerAppearance.transparent`
// here: the Figma `Tag picker` set names the bottom-rule-only variant that way.
typedef _AppearanceEmployee = ({
  String name,
  String initials,
  FluentAvatarColor color,
});

const List<_AppearanceEmployee> _appearanceEmployees = <_AppearanceEmployee>[
  (name: 'John Doe', initials: 'JD', color: FluentAvatarColor.peach),
  (name: 'Jane Doe', initials: 'JD', color: FluentAvatarColor.platinum),
  (name: 'Max Mustermann', initials: 'MM', color: FluentAvatarColor.seafoam),
  (name: 'Erika Mustermann', initials: 'EM', color: FluentAvatarColor.lavender),
  (name: 'Pierre Dupont', initials: 'PD', color: FluentAvatarColor.cornflower),
  (name: 'Amelie Dupont', initials: 'AD', color: FluentAvatarColor.marigold),
  (name: 'Mario Rossi', initials: 'MR', color: FluentAvatarColor.steel),
  (name: 'Maria Rossi', initials: 'MR', color: FluentAvatarColor.teal),
];

FluentTagPickerOption<String> _appearanceOption(_AppearanceEmployee employee) =>
    FluentTagPickerOption<String>(
      value: employee.name,
      label: Text(employee.name),
      text: '${employee.name}, Microsoft FTE',
      media: FluentAvatar(
        name: employee.name,
        initials: employee.initials,
        color: employee.color,
        shape: FluentAvatarShape.square,
        size: FluentAvatarSize.size16,
      ),
    );

Widget _appearance(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  spacing: 10,
  children: <Widget>[
    _AppearanceExample(
      title: 'Outline',
      appearance: FluentTagPickerAppearance.outline,
    ),
    _AppearanceExample(
      title: 'Underline',
      appearance: FluentTagPickerAppearance.transparent,
    ),
    _AppearanceExample(
      title: 'Filled Darker',
      appearance: FluentTagPickerAppearance.filledDarker,
      inverted: true,
    ),
    _AppearanceExample(
      title: 'Filled Lighter',
      appearance: FluentTagPickerAppearance.filledLighter,
      inverted: true,
    ),
  ],
);

class _AppearanceExample extends StatefulWidget {
  const _AppearanceExample({
    required this.title,
    required this.appearance,
    this.inverted = false,
  });

  final String title;
  final FluentTagPickerAppearance appearance;
  final bool inverted;

  @override
  State<_AppearanceExample> createState() => _AppearanceExampleState();
}

class _AppearanceExampleState extends State<_AppearanceExample> {
  List<String> _selected = <String>[_appearanceEmployees.first.name];

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);
    final Color? labelColor = widget.inverted
        ? theme.colors.neutralForegroundInverted2
        : null;

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: <Widget>[
        Text(
          widget.title,
          style: theme.typography.title3.copyWith(color: labelColor),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: FluentField(
            label: Text(
              'Select Employees',
              style: TextStyle(color: labelColor),
            ),
            child: FluentTagPicker<String>(
              semanticLabel: 'Select Employees',
              appearance: widget.appearance,
              selected: _selected,
              onChanged: (List<String> values) =>
                  setState(() => _selected = values),
              options: <FluentTagPickerOption<String>>[
                for (final _AppearanceEmployee employee in _appearanceEmployees)
                  _appearanceOption(employee),
                if (_selected.length == _appearanceEmployees.length)
                  const FluentTagPickerOption<String>(
                    value: 'no-options',
                    label: Text('No options available'),
                    enabled: false,
                  ),
              ],
            ),
          ),
        ),
      ],
    );

    if (!widget.inverted) return content;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.neutralBackgroundInverted,
        borderRadius: const BorderRadius.all(FluentRadius.medium),
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: content),
    );
  }
}
// #enddocregion components-tagpicker--appearance

// #docregion components-tagpicker--disabled
typedef _DisabledEmployee = ({
  String name,
  String initials,
  FluentAvatarColor color,
});

const List<_DisabledEmployee> _disabledEmployees = <_DisabledEmployee>[
  (name: 'John Doe', initials: 'JD', color: FluentAvatarColor.peach),
  (name: 'Jane Doe', initials: 'JD', color: FluentAvatarColor.platinum),
  (name: 'Max Mustermann', initials: 'MM', color: FluentAvatarColor.seafoam),
  (name: 'Erika Mustermann', initials: 'EM', color: FluentAvatarColor.lavender),
  (name: 'Pierre Dupont', initials: 'PD', color: FluentAvatarColor.cornflower),
  (name: 'Amelie Dupont', initials: 'AD', color: FluentAvatarColor.marigold),
  (name: 'Mario Rossi', initials: 'MR', color: FluentAvatarColor.steel),
  (name: 'Maria Rossi', initials: 'MR', color: FluentAvatarColor.teal),
];

FluentTagPickerOption<String> _disabledOption(_DisabledEmployee employee) =>
    FluentTagPickerOption<String>(
      value: employee.name,
      label: Text(employee.name),
      text: '${employee.name}, Microsoft FTE',
      media: FluentAvatar(
        name: employee.name,
        initials: employee.initials,
        color: employee.color,
        shape: FluentAvatarShape.square,
        size: FluentAvatarSize.size16,
      ),
    );

// `onChanged: null` is how a picker is disabled here — the chips lose their
// dismiss affordance with it, where upstream keeps `selectedOptions` editable
// from outside.
Widget _disabled(BuildContext context) => ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 400),
  child: FluentField(
    label: const Text('Select Employees'),
    child: FluentTagPicker<String>(
      semanticLabel: 'Select Employees',
      selected: <String>[
        for (final _DisabledEmployee employee in _disabledEmployees.take(4))
          employee.name,
      ],
      options: <FluentTagPickerOption<String>>[
        for (final _DisabledEmployee employee in _disabledEmployees)
          _disabledOption(employee),
      ],
    ),
  ),
);
// #enddocregion components-tagpicker--disabled

// #docregion components-tagpicker--expand-icon
// `TagPickerControl expandIcon` has no port: `FluentTagPicker` draws no chevron
// of its own, and `secondaryAction` is the only trailing slot on the control —
// so upstream's `ArrowDownFilled` goes there.
typedef _ExpandIconEmployee = ({
  String name,
  String initials,
  FluentAvatarColor color,
});

const List<_ExpandIconEmployee> _expandIconEmployees = <_ExpandIconEmployee>[
  (name: 'John Doe', initials: 'JD', color: FluentAvatarColor.peach),
  (name: 'Jane Doe', initials: 'JD', color: FluentAvatarColor.platinum),
  (name: 'Max Mustermann', initials: 'MM', color: FluentAvatarColor.seafoam),
  (name: 'Erika Mustermann', initials: 'EM', color: FluentAvatarColor.lavender),
  (name: 'Pierre Dupont', initials: 'PD', color: FluentAvatarColor.cornflower),
  (name: 'Amelie Dupont', initials: 'AD', color: FluentAvatarColor.marigold),
  (name: 'Mario Rossi', initials: 'MR', color: FluentAvatarColor.steel),
  (name: 'Maria Rossi', initials: 'MR', color: FluentAvatarColor.teal),
];

FluentTagPickerOption<String> _expandIconOption(_ExpandIconEmployee employee) =>
    FluentTagPickerOption<String>(
      value: employee.name,
      label: Text(employee.name),
      text: '${employee.name}, Microsoft FTE',
      media: FluentAvatar(
        name: employee.name,
        initials: employee.initials,
        color: employee.color,
        shape: FluentAvatarShape.square,
        size: FluentAvatarSize.size16,
      ),
    );

Widget _expandIcon(BuildContext context) => const _ExpandIcon();

class _ExpandIcon extends StatefulWidget {
  const _ExpandIcon();

  @override
  State<_ExpandIcon> createState() => _ExpandIconState();
}

class _ExpandIconState extends State<_ExpandIcon> {
  List<String> _selected = <String>[_expandIconEmployees.first.name];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: FluentField(
      label: const Text('Select Employees'),
      child: FluentTagPicker<String>(
        semanticLabel: 'Select Employees',
        secondaryAction: const Icon(FluentIcons.arrow_down_20_filled, size: 20),
        selected: _selected,
        onChanged: (List<String> values) => setState(() => _selected = values),
        options: <FluentTagPickerOption<String>>[
          for (final _ExpandIconEmployee employee in _expandIconEmployees)
            _expandIconOption(employee),
          if (_selected.length == _expandIconEmployees.length)
            const FluentTagPickerOption<String>(
              value: 'no-options',
              label: Text('No options available'),
              enabled: false,
            ),
        ],
      ),
    ),
  );
}
// #enddocregion components-tagpicker--expand-icon

// #docregion components-tagpicker--secondary-action
typedef _SecondaryActionEmployee = ({
  String name,
  String initials,
  FluentAvatarColor color,
});

const List<_SecondaryActionEmployee>
_secondaryActionEmployees = <_SecondaryActionEmployee>[
  (name: 'John Doe', initials: 'JD', color: FluentAvatarColor.peach),
  (name: 'Jane Doe', initials: 'JD', color: FluentAvatarColor.platinum),
  (name: 'Max Mustermann', initials: 'MM', color: FluentAvatarColor.seafoam),
  (name: 'Erika Mustermann', initials: 'EM', color: FluentAvatarColor.lavender),
  (name: 'Pierre Dupont', initials: 'PD', color: FluentAvatarColor.cornflower),
  (name: 'Amelie Dupont', initials: 'AD', color: FluentAvatarColor.marigold),
  (name: 'Mario Rossi', initials: 'MR', color: FluentAvatarColor.steel),
  (name: 'Maria Rossi', initials: 'MR', color: FluentAvatarColor.teal),
];

FluentTagPickerOption<String> _secondaryActionOption(
  _SecondaryActionEmployee employee,
) => FluentTagPickerOption<String>(
  value: employee.name,
  label: Text(employee.name),
  text: '${employee.name}, Microsoft FTE',
  media: FluentAvatar(
    name: employee.name,
    initials: employee.initials,
    color: employee.color,
    shape: FluentAvatarShape.square,
    size: FluentAvatarSize.size16,
  ),
);

Widget _secondaryAction(BuildContext context) => const _SecondaryAction();

class _SecondaryAction extends StatefulWidget {
  const _SecondaryAction();

  @override
  State<_SecondaryAction> createState() => _SecondaryActionState();
}

class _SecondaryActionState extends State<_SecondaryAction> {
  List<String> _selected = <String>[_secondaryActionEmployees.first.name];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: FluentField(
      label: const Text('Select Employees'),
      child: FluentTagPicker<String>(
        semanticLabel: 'Select Employees',
        secondaryAction: FluentButton(
          appearance: FluentButtonAppearance.transparent,
          size: FluentButtonSize.small,
          onPressed: () => setState(() => _selected = <String>[]),
          child: const Text('All Clear'),
        ),
        selected: _selected,
        onChanged: (List<String> values) => setState(() => _selected = values),
        options: <FluentTagPickerOption<String>>[
          for (final _SecondaryActionEmployee employee
              in _secondaryActionEmployees)
            _secondaryActionOption(employee),
          if (_selected.length == _secondaryActionEmployees.length)
            const FluentTagPickerOption<String>(
              value: 'no-options',
              label: Text('No options available'),
              enabled: false,
            ),
        ],
      ),
    ),
  );
}
// #enddocregion components-tagpicker--secondary-action

// #docregion components-tagpicker--grouped
// `TagPickerOptionGroup` is a wrapper upstream; here a group is a
// `FluentTagPickerOption.header` row followed by its members in the same flat
// list, so an empty group is omitted by leaving its header out.
typedef _GroupedEmployee = ({
  String name,
  String initials,
  FluentAvatarColor color,
});

const List<_GroupedEmployee> _groupedManagers = <_GroupedEmployee>[
  (name: 'John Doe', initials: 'JD', color: FluentAvatarColor.peach),
  (name: 'Jane Doe', initials: 'JD', color: FluentAvatarColor.platinum),
  (name: 'Max Mustermann', initials: 'MM', color: FluentAvatarColor.seafoam),
  (name: 'Erika Mustermann', initials: 'EM', color: FluentAvatarColor.lavender),
];

const List<_GroupedEmployee> _groupedDevs = <_GroupedEmployee>[
  (name: 'Pierre Dupont', initials: 'PD', color: FluentAvatarColor.cornflower),
  (name: 'Amelie Dupont', initials: 'AD', color: FluentAvatarColor.marigold),
  (name: 'Mario Rossi', initials: 'MR', color: FluentAvatarColor.steel),
  (name: 'Maria Rossi', initials: 'MR', color: FluentAvatarColor.teal),
];

FluentTagPickerOption<String> _groupedOption(_GroupedEmployee employee) =>
    FluentTagPickerOption<String>(
      value: employee.name,
      label: Text(employee.name),
      text: '${employee.name}, Microsoft FTE',
      media: FluentAvatar(
        name: employee.name,
        initials: employee.initials,
        color: employee.color,
        shape: FluentAvatarShape.square,
        size: FluentAvatarSize.size16,
      ),
    );

Widget _grouped(BuildContext context) => const _Grouped();

class _Grouped extends StatefulWidget {
  const _Grouped();

  @override
  State<_Grouped> createState() => _GroupedState();
}

class _GroupedState extends State<_Grouped> {
  List<String> _selected = <String>[];

  bool _anyLeft(List<_GroupedEmployee> group) =>
      group.any((_GroupedEmployee e) => !_selected.contains(e.name));

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: FluentField(
      label: const Text('Select Employees'),
      child: FluentTagPicker<String>(
        semanticLabel: 'Select Employees',
        selected: _selected,
        onChanged: (List<String> values) => setState(() => _selected = values),
        options: <FluentTagPickerOption<String>>[
          if (!_anyLeft(_groupedManagers) && !_anyLeft(_groupedDevs))
            const FluentTagPickerOption<String>(
              value: 'no-options',
              label: Text('No options available'),
              enabled: false,
            ),
          if (_anyLeft(_groupedManagers))
            const FluentTagPickerOption<String>.header(
              label: Text('Managers'),
              text: 'Managers',
            ),
          for (final _GroupedEmployee employee in _groupedManagers)
            _groupedOption(employee),
          if (_anyLeft(_groupedDevs))
            const FluentTagPickerOption<String>.header(
              label: Text('Devs'),
              text: 'Devs',
            ),
          for (final _GroupedEmployee employee in _groupedDevs)
            _groupedOption(employee),
        ],
      ),
    ),
  );
}
// #enddocregion components-tagpicker--grouped

// #docregion components-tagpicker--truncated-text
// The CSS pair — `text-overflow: ellipsis` on the container, and a 50px fixed
// width — becomes `TextOverflow.ellipsis` under a bounded box. A tag lays its
// content out in an unbounded `Row`, so the bound has to be explicit: `Text`
// alone would never truncate.
typedef _TruncatedEmployee = ({
  String name,
  String initials,
  FluentAvatarColor color,
  bool fixedWidth,
});

const List<_TruncatedEmployee> _truncatedEmployees = <_TruncatedEmployee>[
  (
    name: 'John Doe',
    initials: 'JD',
    color: FluentAvatarColor.peach,
    fixedWidth: false,
  ),
  (
    name: 'Jane Doe',
    initials: 'JD',
    color: FluentAvatarColor.platinum,
    fixedWidth: false,
  ),
  (
    name: 'Max Mustermann',
    initials: 'MM',
    color: FluentAvatarColor.seafoam,
    fixedWidth: false,
  ),
  (
    name: 'Erika Mustermann',
    initials: 'EM',
    color: FluentAvatarColor.lavender,
    fixedWidth: false,
  ),
  (
    name: 'Pierre Dupont',
    initials: 'PD',
    color: FluentAvatarColor.cornflower,
    fixedWidth: false,
  ),
  (
    name: 'Amelie Dupont',
    initials: 'AD',
    color: FluentAvatarColor.marigold,
    fixedWidth: false,
  ),
  (
    name: 'Maria Rossi',
    initials: 'MR',
    color: FluentAvatarColor.teal,
    fixedWidth: false,
  ),
  (
    name: 'This tag has text truncation based on a fixed width of 50px',
    initials: 'TT',
    color: FluentAvatarColor.steel,
    fixedWidth: true,
  ),
  (
    name:
        'This tag has text truncation based on its container width. This is a '
        'long text that will be truncated when it reaches the end of the '
        'container.',
    initials: 'TT',
    color: FluentAvatarColor.brass,
    fixedWidth: false,
  ),
];

FluentTagPickerOption<String> _truncatedOption(_TruncatedEmployee employee) =>
    FluentTagPickerOption<String>(
      value: employee.name,
      label: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: employee.fixedWidth ? 50 : 240),
        child: Text(
          employee.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      text: '${employee.name}, Microsoft FTE',
      media: FluentAvatar(
        name: employee.name,
        initials: employee.initials,
        color: employee.color,
        shape: FluentAvatarShape.square,
        size: FluentAvatarSize.size16,
      ),
    );

Widget _truncatedText(BuildContext context) => const _TruncatedText();

class _TruncatedText extends StatefulWidget {
  const _TruncatedText();

  @override
  State<_TruncatedText> createState() => _TruncatedTextState();
}

class _TruncatedTextState extends State<_TruncatedText> {
  List<String> _selected = <String>[
    for (final _TruncatedEmployee employee in _truncatedEmployees)
      employee.name,
  ];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: FluentField(
      label: const Text('Select Employees'),
      child: FluentTagPicker<String>(
        semanticLabel: 'Select Employees',
        selected: _selected,
        onChanged: (List<String> values) => setState(() => _selected = values),
        options: <FluentTagPickerOption<String>>[
          for (final _TruncatedEmployee employee in _truncatedEmployees)
            _truncatedOption(employee),
          if (_selected.length == _truncatedEmployees.length)
            const FluentTagPickerOption<String>(
              value: 'no-options',
              label: Text('No options available'),
              enabled: false,
            ),
        ],
      ),
    ),
  );
}
// #enddocregion components-tagpicker--truncated-text

// #docregion components-tagpicker--single-select
typedef _SingleSelectEmployee = ({
  String name,
  String initials,
  FluentAvatarColor color,
});

const List<_SingleSelectEmployee>
_singleSelectEmployees = <_SingleSelectEmployee>[
  (name: 'John Doe', initials: 'JD', color: FluentAvatarColor.peach),
  (name: 'Jane Doe', initials: 'JD', color: FluentAvatarColor.platinum),
  (name: 'Max Mustermann', initials: 'MM', color: FluentAvatarColor.seafoam),
  (name: 'Erika Mustermann', initials: 'EM', color: FluentAvatarColor.lavender),
  (name: 'Pierre Dupont', initials: 'PD', color: FluentAvatarColor.cornflower),
  (name: 'Amelie Dupont', initials: 'AD', color: FluentAvatarColor.marigold),
  (name: 'Mario Rossi', initials: 'MR', color: FluentAvatarColor.steel),
  (name: 'Maria Rossi', initials: 'MR', color: FluentAvatarColor.teal),
];

FluentTagPickerOption<String> _singleSelectOption(
  _SingleSelectEmployee employee,
) => FluentTagPickerOption<String>(
  value: employee.name,
  label: Text(employee.name),
  text: '${employee.name}, Microsoft FTE',
  media: FluentAvatar(
    name: employee.name,
    initials: employee.initials,
    color: employee.color,
    shape: FluentAvatarShape.square,
    size: FluentAvatarSize.size16,
  ),
);

Widget _singleSelect(BuildContext context) => const _SingleSelect();

class _SingleSelect extends StatefulWidget {
  const _SingleSelect();

  @override
  State<_SingleSelect> createState() => _SingleSelectState();
}

class _SingleSelectState extends State<_SingleSelect> {
  List<String> _selected = <String>[];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: FluentField(
      label: const Text('Select Employees'),
      child: FluentTagPicker<String>(
        semanticLabel: 'Select Employees',
        selected: _selected,
        // Single selection is the caller's job: keep only the value that was
        // just added and the picker never shows a second chip.
        onChanged: (List<String> values) => setState(
          () => _selected = values.isEmpty ? <String>[] : <String>[values.last],
        ),
        options: <FluentTagPickerOption<String>>[
          for (final _SingleSelectEmployee employee in _singleSelectEmployees)
            _singleSelectOption(employee),
        ],
      ),
    ),
  );
}
// #enddocregion components-tagpicker--single-select

// #docregion components-tagpicker--no-popover
// `noPopover` has no port, and neither does `TagPickerInput onKeyDown`:
// `FluentTagPicker` owns its field and binds Enter to "commit the active
// option". So the control is composed here from the parts the picker itself
// uses — a `FluentInput` whose `onSubmitted` adds the typed text, over a `Wrap`
// of `FluentInteractionTag` chips.
const List<FluentAvatarColor> _noPopoverColors = <FluentAvatarColor>[
  FluentAvatarColor.peach,
  FluentAvatarColor.platinum,
  FluentAvatarColor.seafoam,
  FluentAvatarColor.lavender,
  FluentAvatarColor.cornflower,
];

Widget _noPopover(BuildContext context) => const _NoPopover();

class _NoPopover extends StatefulWidget {
  const _NoPopover();

  @override
  State<_NoPopover> createState() => _NoPopoverState();
}

class _NoPopoverState extends State<_NoPopover> {
  final TextEditingController _controller = TextEditingController();
  List<String> _selected = <String>[];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String value) {
    if (value.isEmpty) return;
    setState(() {
      if (!_selected.contains(value)) _selected = <String>[..._selected, value];
      _controller.clear();
    });
  }

  void _remove(String value) => setState(
    () => _selected = <String>[
      for (final String selected in _selected)
        if (selected != value) selected,
    ],
  );

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: FluentField(
      label: const Text('Add Employees'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: <Widget>[
          if (_selected.isNotEmpty)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: <Widget>[
                for (final String value in _selected)
                  FluentInteractionTag(
                    key: ValueKey<String>(value),
                    size: FluentTagSize.small,
                    icon: FluentAvatar(
                      name: value,
                      initials: value.substring(0, 1).toUpperCase(),
                      color:
                          _noPopoverColors[_selected.indexOf(value) %
                              _noPopoverColors.length],
                      shape: FluentAvatarShape.square,
                      size: FluentAvatarSize.size16,
                    ),
                    onPressed: () {},
                    onDismiss: () => _remove(value),
                    child: Text(value),
                  ),
              ],
            ),
          FluentInput(
            controller: _controller,
            semanticLabel: 'Add Employees',
            onSubmitted: _add,
          ),
        ],
      ),
    ),
  );
}
// #enddocregion components-tagpicker--no-popover

// #docregion components-tagpicker--single-line
// `Overflow`/`useOverflowCount` have no port, so the chips wrap onto a second
// line instead of collapsing into a `+N` tag. The chevron is the one part that
// survives: `FluentTagPicker` draws none of its own, so it rides in
// `secondaryAction` and flips with focus, which is the closest signal this
// widget exposes to upstream's `open`.
typedef _SingleLineEmployee = ({
  String name,
  String initials,
  FluentAvatarColor color,
});

const List<_SingleLineEmployee> _singleLineEmployees = <_SingleLineEmployee>[
  (name: 'John Doe', initials: 'JD', color: FluentAvatarColor.peach),
  (name: 'Jane Doe', initials: 'JD', color: FluentAvatarColor.platinum),
  (name: 'Max Mustermann', initials: 'MM', color: FluentAvatarColor.seafoam),
  (name: 'Erika Mustermann', initials: 'EM', color: FluentAvatarColor.lavender),
  (name: 'Pierre Dupont', initials: 'PD', color: FluentAvatarColor.cornflower),
  (name: 'Amelie Dupont', initials: 'AD', color: FluentAvatarColor.marigold),
  (name: 'Mario Rossi', initials: 'MR', color: FluentAvatarColor.steel),
  (name: 'Maria Rossi', initials: 'MR', color: FluentAvatarColor.teal),
];

FluentTagPickerOption<String> _singleLineOption(_SingleLineEmployee employee) =>
    FluentTagPickerOption<String>(
      value: employee.name,
      label: Text(employee.name),
      text: '${employee.name}, Microsoft FTE',
      media: FluentAvatar(
        name: employee.name,
        initials: employee.initials,
        color: employee.color,
        shape: FluentAvatarShape.square,
        size: FluentAvatarSize.size16,
      ),
    );

Widget _singleLine(BuildContext context) => const _SingleLine();

class _SingleLine extends StatefulWidget {
  const _SingleLine();

  @override
  State<_SingleLine> createState() => _SingleLineState();
}

class _SingleLineState extends State<_SingleLine> {
  final FocusNode _focusNode = FocusNode();
  List<String> _selected = <String>[];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_rebuild);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: FluentTagPicker<String>(
      focusNode: _focusNode,
      semanticLabel: 'Select Employees',
      placeholder: const Text('Select Employees'),
      secondaryAction: Icon(
        _focusNode.hasFocus
            ? FluentIcons.chevron_up_20_regular
            : FluentIcons.chevron_down_20_regular,
        size: 20,
      ),
      selected: _selected,
      onChanged: (List<String> values) => setState(() => _selected = values),
      options: <FluentTagPickerOption<String>>[
        for (final _SingleLineEmployee employee in _singleLineEmployees)
          _singleLineOption(employee),
        if (_selected.length == _singleLineEmployees.length)
          const FluentTagPickerOption<String>(
            value: 'no-options',
            label: Text('No options available'),
            enabled: false,
          ),
      ],
    ),
  );
}

// #enddocregion components-tagpicker--single-line
