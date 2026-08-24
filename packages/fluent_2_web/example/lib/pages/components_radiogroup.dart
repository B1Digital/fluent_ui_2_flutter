import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The RadioGroup docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage radioGroupPage = DocsPage(
  id: 'components-radiogroup',
  title: 'RadioGroup',
  description:
      'RadioGroup lets people select a single option from two or more Radio '
      "items. Use RadioGroup to present all available choices if there's "
      'enough space. For more than 5 choices, consider using a different '
      'component such as Dropdown.',
  source: 'lib/pages/components_radiogroup.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-radiogroup--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-radiogroup--horizontal',
      title: 'Layout: horizontal',
      description:
          'The horizontal layout places each radio item in a row, with labels '
          'after the radio indicator.',
      builder: _horizontal,
    ),
    DocsSection(
      id: 'components-radiogroup--horizontal-stacked',
      title: 'Layout: horizontal-stacked',
      description:
          'The horizontal-stacked layout places each radio item in a row, with '
          'labels below the radio indicator.',
      builder: _horizontalStacked,
    ),
    DocsSection(
      id: 'components-radiogroup--default-value',
      title: 'Default Value',
      description:
          'The initially selected item can be set by setting the defaultValue '
          'of RadioGroup. Alternatively, one Radio item can have defaultChecked '
          'set. Both methods have the same effect, but only one should be used '
          'in a given RadioGroup.',
      builder: _defaultValue,
    ),
    DocsSection(
      id: 'components-radiogroup--controlled-value',
      title: 'Controlled Value',
      description:
          'The selected radio item can be controlled using the value and '
          'onChange props.',
      builder: _controlledValue,
    ),
    DocsSection(
      id: 'components-radiogroup--required',
      title: 'Required',
      description:
          'Use the required prop to indicate that one of the radio items must '
          'be selected. Or, if the RadioGroup is inside a Field, it will '
          'inherit the required prop from the Field.',
      builder: _required,
    ),
    DocsSection(
      id: 'components-radiogroup--disabled',
      title: 'Disabled',
      description:
          'RadioGroup can be disabled, which disables all Radio items inside.',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-radiogroup--disabled-item',
      title: 'Disabled Item',
      description: 'Radio items can be disabled individually.',
      builder: _disabledItem,
    ),
    DocsSection(
      id: 'components-radiogroup--label-subtext',
      title: 'Label Subtext',
      description:
          "Radio's label supports any formatted text. In this example, smaller "
          'text is below the main label text.',
      builder: _labelSubtext,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'children',
      type: 'List<Widget>',
      description:
          'The radios, and anything else the caller wants to lay out among '
          'them.',
    ),
    PropRow(
      name: 'value',
      type: 'T?',
      defaultValue: 'null',
      description:
          'The currently selected value, or null when nothing is selected.',
    ),
    PropRow(
      name: 'onChanged',
      type: 'ValueChanged<T>?',
      defaultValue: 'null',
      description:
          'Invoked with the newly selected value. Null disables the whole '
          'group.',
    ),
    PropRow(
      name: 'layout',
      type: 'FluentRadioGroupLayout',
      defaultValue: 'FluentRadioGroupLayout.vertical',
      description:
          'How the radios are laid out. horizontalStacked also moves every '
          'label below its indicator.',
    ),
    PropRow(
      name: 'disabled',
      type: 'bool',
      defaultValue: 'false',
      description: 'Disables every radio in the group.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description:
          'Announced by assistive technology as the name of the group, which '
          'is what a screen reader reads before the selected option.',
    ),
  ],
);

// #docregion components-radiogroup--default
// FluentRadioGroup is controlled-only — it has no uncontrolled mode, so the
// demo owns the selection instead of upstream's implicit internal state.
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  String? _value;

  @override
  Widget build(BuildContext context) => FluentField(
    label: const Text('Favorite Fruit'),
    child: FluentRadioGroup<String>(
      value: _value,
      onChanged: (String value) => setState(() => _value = value),
      children: const <Widget>[
        FluentRadio<String>(value: 'apple', label: Text('Apple')),
        FluentRadio<String>(value: 'pear', label: Text('Pear')),
        FluentRadio<String>(value: 'banana', label: Text('Banana')),
        FluentRadio<String>(value: 'orange', label: Text('Orange')),
      ],
    ),
  );
}
// #enddocregion components-radiogroup--default

// #docregion components-radiogroup--horizontal
Widget _horizontal(BuildContext context) => const _Horizontal();

class _Horizontal extends StatefulWidget {
  const _Horizontal();

  @override
  State<_Horizontal> createState() => _HorizontalState();
}

class _HorizontalState extends State<_Horizontal> {
  String? _value;

  @override
  Widget build(BuildContext context) => FluentField(
    label: const Text('Favorite Fruit'),
    child: FluentRadioGroup<String>(
      layout: FluentRadioGroupLayout.horizontal,
      value: _value,
      onChanged: (String value) => setState(() => _value = value),
      children: const <Widget>[
        FluentRadio<String>(value: 'apple', label: Text('Apple')),
        FluentRadio<String>(value: 'pear', label: Text('Pear')),
        FluentRadio<String>(value: 'banana', label: Text('Banana')),
        FluentRadio<String>(value: 'orange', label: Text('Orange')),
      ],
    ),
  );
}
// #enddocregion components-radiogroup--horizontal

// #docregion components-radiogroup--horizontal-stacked
Widget _horizontalStacked(BuildContext context) => const _HorizontalStacked();

class _HorizontalStacked extends StatefulWidget {
  const _HorizontalStacked();

  @override
  State<_HorizontalStacked> createState() => _HorizontalStackedState();
}

class _HorizontalStackedState extends State<_HorizontalStacked> {
  String? _value;

  @override
  Widget build(BuildContext context) => FluentField(
    label: const Text('Favorite Fruit'),
    child: FluentRadioGroup<String>(
      layout: FluentRadioGroupLayout.horizontalStacked,
      value: _value,
      onChanged: (String value) => setState(() => _value = value),
      children: const <Widget>[
        FluentRadio<String>(value: 'apple', label: Text('Apple')),
        FluentRadio<String>(value: 'pear', label: Text('Pear')),
        FluentRadio<String>(value: 'banana', label: Text('Banana')),
        FluentRadio<String>(value: 'orange', label: Text('Orange')),
      ],
    ),
  );
}
// #enddocregion components-radiogroup--horizontal-stacked

// #docregion components-radiogroup--default-value
// Upstream's `defaultValue` seeds an uncontrolled group. Ours is controlled, so
// the same thing is said by seeding the state field.
Widget _defaultValue(BuildContext context) => const _DefaultValue();

class _DefaultValue extends StatefulWidget {
  const _DefaultValue();

  @override
  State<_DefaultValue> createState() => _DefaultValueState();
}

class _DefaultValueState extends State<_DefaultValue> {
  String? _value = 'pear';

  @override
  Widget build(BuildContext context) => FluentField(
    label: const Text('Favorite Fruit'),
    child: FluentRadioGroup<String>(
      value: _value,
      onChanged: (String value) => setState(() => _value = value),
      children: const <Widget>[
        FluentRadio<String>(value: 'apple', label: Text('Apple')),
        FluentRadio<String>(value: 'pear', label: Text('Pear')),
        FluentRadio<String>(value: 'banana', label: Text('Banana')),
        FluentRadio<String>(value: 'orange', label: Text('Orange')),
      ],
    ),
  );
}
// #enddocregion components-radiogroup--default-value

// #docregion components-radiogroup--controlled-value
// Upstream clears to the empty string and keeps the button focusable while
// disabled (`disabledFocusable`). FluentRadioGroup spells "nothing selected" as
// a null value, and FluentButton has no disabled-but-focusable mode: a null
// onPressed is what disables it.
Widget _controlledValue(BuildContext context) => const _ControlledValue();

class _ControlledValue extends StatefulWidget {
  const _ControlledValue();

  @override
  State<_ControlledValue> createState() => _ControlledValueState();
}

class _ControlledValueState extends State<_ControlledValue> {
  String? _value = 'banana';

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      FluentField(
        label: const Text('Favorite Fruit'),
        child: FluentRadioGroup<String>(
          value: _value,
          onChanged: (String value) => setState(() => _value = value),
          children: const <Widget>[
            FluentRadio<String>(value: 'apple', label: Text('Apple')),
            FluentRadio<String>(value: 'pear', label: Text('Pear')),
            FluentRadio<String>(value: 'banana', label: Text('Banana')),
            FluentRadio<String>(value: 'orange', label: Text('Orange')),
          ],
        ),
      ),
      const SizedBox(height: 8),
      FluentButton(
        onPressed: _value == null ? null : () => setState(() => _value = null),
        child: const Text('Clear selection'),
      ),
    ],
  );
}
// #enddocregion components-radiogroup--controlled-value

// #docregion components-radiogroup--required
Widget _required(BuildContext context) => const _Required();

class _Required extends StatefulWidget {
  const _Required();

  @override
  State<_Required> createState() => _RequiredState();
}

class _RequiredState extends State<_Required> {
  String? _value;

  @override
  Widget build(BuildContext context) => FluentField(
    label: const Text('Favorite Fruit'),
    required: true,
    child: FluentRadioGroup<String>(
      value: _value,
      onChanged: (String value) => setState(() => _value = value),
      children: const <Widget>[
        FluentRadio<String>(value: 'apple', label: Text('Apple')),
        FluentRadio<String>(value: 'pear', label: Text('Pear')),
        FluentRadio<String>(value: 'banana', label: Text('Banana')),
        FluentRadio<String>(value: 'orange', label: Text('Orange')),
      ],
    ),
  );
}
// #enddocregion components-radiogroup--required

// #docregion components-radiogroup--disabled
Widget _disabled(BuildContext context) => const FluentField(
  label: Text('Favorite Fruit'),
  child: FluentRadioGroup<String>(
    value: 'apple',
    disabled: true,
    children: <Widget>[
      FluentRadio<String>(value: 'apple', label: Text('Apple')),
      FluentRadio<String>(value: 'pear', label: Text('Pear')),
      FluentRadio<String>(value: 'banana', label: Text('Banana')),
      FluentRadio<String>(value: 'orange', label: Text('Orange')),
    ],
  ),
);
// #enddocregion components-radiogroup--disabled

// #docregion components-radiogroup--disabled-item
Widget _disabledItem(BuildContext context) => const _DisabledItem();

class _DisabledItem extends StatefulWidget {
  const _DisabledItem();

  @override
  State<_DisabledItem> createState() => _DisabledItemState();
}

class _DisabledItemState extends State<_DisabledItem> {
  String? _value = 'apple';

  @override
  Widget build(BuildContext context) => FluentField(
    label: const Text('Favorite Fruit'),
    child: FluentRadioGroup<String>(
      value: _value,
      onChanged: (String value) => setState(() => _value = value),
      children: const <Widget>[
        FluentRadio<String>(value: 'apple', label: Text('Apple')),
        FluentRadio<String>(value: 'pear', label: Text('Pear')),
        FluentRadio<String>(
          value: 'banana',
          label: Text('Banana'),
          disabled: true,
        ),
        FluentRadio<String>(value: 'orange', label: Text('Orange')),
      ],
    ),
  );
}
// #enddocregion components-radiogroup--disabled-item

// #docregion components-radiogroup--label-subtext
// Upstream's label is a fragment holding a `<br />` and a `Text size={200}`.
// A Column of two Text widgets is the same shape here, and size 200 is the
// caption1 step of the theme's type ramp.
Widget _labelSubtext(BuildContext context) => const _LabelSubtext();

class _LabelSubtext extends StatefulWidget {
  const _LabelSubtext();

  @override
  State<_LabelSubtext> createState() => _LabelSubtextState();
}

class _LabelSubtextState extends State<_LabelSubtext> {
  String? _value;

  @override
  Widget build(BuildContext context) {
    final TextStyle subtext = FluentTheme.of(context).typography.caption1;
    return FluentField(
      label: const Text('Favorite Fruit'),
      child: FluentRadioGroup<String>(
        value: _value,
        onChanged: (String value) => setState(() => _value = value),
        children: <Widget>[
          FluentRadio<String>(
            value: 'A',
            label: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Banana'),
                Text(
                  'This is an example subtext of the first option',
                  style: subtext,
                ),
              ],
            ),
          ),
          FluentRadio<String>(
            value: 'B',
            label: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Pear'),
                Text('This is some more example subtext', style: subtext),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// #enddocregion components-radiogroup--label-subtext
