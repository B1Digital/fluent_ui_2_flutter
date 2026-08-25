import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Switch docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage switchPage = DocsPage(
  id: 'components-switch',
  title: 'Switch',
  description:
      'A switch represents a physical switch that allows someone to choose '
      'between two mutually exclusive options. For example, "On/Off" and '
      '"Show/Hide". Choosing an option should produce an immediate result.',
  source: 'lib/pages/components_switch.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-switch--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-switch--checked',
      title: 'Checked',
      description:
          'A Switch can be initially checked by passing a value to the '
          'defaultChecked property, or have its checked value controlled via '
          'the checked property.',
      builder: _checked,
    ),
    DocsSection(
      id: 'components-switch--size',
      title: 'Size',
      description: 'A Switch can have different sizes.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-switch--disabled',
      title: 'Disabled',
      description: 'A Switch can be disabled.',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-switch--label',
      title: 'Label',
      description:
          'A label can be provided to the Switch and is positioned above, '
          'before or after the component.',
      builder: _label,
    ),
    DocsSection(
      id: 'components-switch--label-wrapping',
      title: 'Label Wrapping',
      description:
          'The label will wrap if it is wider than the available space. The '
          'Switch track will stay aligned to the first line of text.',
      builder: _labelWrapping,
    ),
    DocsSection(
      id: 'components-switch--required',
      title: 'Required',
      description:
          'When a Switch is marked as required, its label also gets the '
          'required styling.',
      builder: _required,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'checked',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the switch is on.',
    ),
    PropRow(
      name: 'onChanged',
      type: 'ValueChanged<bool>?',
      defaultValue: 'null',
      description:
          'Invoked with the requested value on tap and on Space or Enter. '
          'Null disables the switch.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentSwitchSize',
      defaultValue: 'FluentSwitchSize.medium',
      description: 'Track height and type ramp.',
    ),
    PropRow(
      name: 'labelPosition',
      type: 'FluentSwitchLabelPosition',
      defaultValue: 'FluentSwitchLabelPosition.after',
      description: 'Where the label sits relative to the track.',
    ),
    PropRow(
      name: 'label',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'The label. Optional — a switch inside a settings row often has its '
          'text somewhere else entirely.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentSwitchStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
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
          'Announced by assistive technology in place of the label text.',
    ),
  ],
);

// #docregion components-switch--default
// FluentSwitch is controlled — there is no uncontrolled `defaultChecked`
// counterpart — so the demo owns the value upstream's story leaves to the DOM.
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) => FluentSwitch(
    checked: _checked,
    onChanged: (bool value) => setState(() => _checked = value),
    label: const Text('This is a switch'),
  );
}
// #enddocregion components-switch--default

// #docregion components-switch--checked
Widget _checked(BuildContext context) => const _Checked();

class _Checked extends StatefulWidget {
  const _Checked();

  @override
  State<_Checked> createState() => _CheckedState();
}

class _CheckedState extends State<_Checked> {
  bool _checked = true;

  @override
  Widget build(BuildContext context) => FluentSwitch(
    checked: _checked,
    onChanged: (bool value) => setState(() => _checked = value),
    label: Text(_checked ? 'Checked' : 'Unchecked'),
  );
}
// #enddocregion components-switch--checked

// #docregion components-switch--size
Widget _size(BuildContext context) => const _Size();

class _Size extends StatefulWidget {
  const _Size();

  @override
  State<_Size> createState() => _SizeState();
}

class _SizeState extends State<_Size> {
  bool _small = false;
  bool _medium = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentSwitch(
        checked: _small,
        onChanged: (bool value) => setState(() => _small = value),
        size: FluentSwitchSize.small,
        label: const Text('Small'),
      ),
      FluentSwitch(
        checked: _medium,
        onChanged: (bool value) => setState(() => _medium = value),
        label: const Text('Medium'),
      ),
    ],
  );
}
// #enddocregion components-switch--size

// #docregion components-switch--disabled
// Upstream's last two switches are `disabledFocusable`: disabled, but still in
// the tab order. FluentSwitch has no such flag — `onChanged: null` is the whole
// of disabled here, and it refuses focus — so they render as plain disabled.
Widget _disabled(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    FluentSwitch(label: Text('Unchecked and disabled')),
    FluentSwitch(checked: true, label: Text('Checked and disabled')),
    FluentSwitch(label: Text('Unchecked and disabled focusable')),
    FluentSwitch(checked: true, label: Text('Checked and disabled focusable')),
  ],
);
// #enddocregion components-switch--disabled

// #docregion components-switch--label
Widget _label(BuildContext context) => const _Label();

class _Label extends StatefulWidget {
  const _Label();

  @override
  State<_Label> createState() => _LabelState();
}

class _LabelState extends State<_Label> {
  bool _checked = false;
  bool _checked2 = false;
  bool _checked3 = false;

  @override
  Widget build(BuildContext context) {
    final String checkedString = _checked ? 'checked' : 'unchecked';
    final String checkedString2 = _checked2 ? 'checked' : 'unchecked';
    final String checkedString3 = _checked3 ? 'checked' : 'unchecked';

    // Upstream spreads the three across the full width with
    // `justify-content: space-around`. A Wrap does the same and drops to a
    // second row instead of overflowing when the demo pane is narrow.
    return Wrap(
      alignment: WrapAlignment.spaceAround,
      spacing: 16,
      runSpacing: 8,
      children: <Widget>[
        FluentSwitch(
          checked: _checked,
          label: Text('With label before and $checkedString'),
          labelPosition: FluentSwitchLabelPosition.before,
          onChanged: (bool value) => setState(() => _checked = value),
        ),
        FluentSwitch(
          checked: _checked2,
          label: Text('With label above and $checkedString2'),
          labelPosition: FluentSwitchLabelPosition.above,
          onChanged: (bool value) => setState(() => _checked2 = value),
        ),
        FluentSwitch(
          checked: _checked3,
          label: Text('With label after and $checkedString3'),
          labelPosition: FluentSwitchLabelPosition.after,
          onChanged: (bool value) => setState(() => _checked3 = value),
        ),
      ],
    );
  }
}
// #enddocregion components-switch--label

// #docregion components-switch--label-wrapping
Widget _labelWrapping(BuildContext context) => const _LabelWrapping();

class _LabelWrapping extends StatefulWidget {
  const _LabelWrapping();

  @override
  State<_LabelWrapping> createState() => _LabelWrappingState();
}

class _LabelWrappingState extends State<_LabelWrapping> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) => FluentSwitch(
    checked: _checked,
    onChanged: (bool value) => setState(() => _checked = value),
    // Upstream caps the whole control at 400px. FluentSwitch lays the label out
    // in a Row without a Flexible, so the bound goes on the label itself: 400
    // less the 56 the padded track takes and the 12 of label padding.
    label: const SizedBox(
      width: 332,
      child: Text(
        'Here is an example of a Switch with a long label and it starts to wrap to a second line.',
      ),
    ),
  );
}
// #enddocregion components-switch--label-wrapping

// #docregion components-switch--required
Widget _required(BuildContext context) => const _Required();

class _Required extends StatefulWidget {
  const _Required();

  @override
  State<_Required> createState() => _RequiredState();
}

class _RequiredState extends State<_Required> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) => FluentSwitch(
    checked: _checked,
    onChanged: (bool value) => setState(() => _checked = value),
    // `required` is a Label concern here, not a Switch one: FluentLabel draws
    // the asterisk upstream's `required` prop forwards to its own label slot.
    label: const FluentLabel(required: true, child: Text('Required')),
  );
}

// #enddocregion components-switch--required
