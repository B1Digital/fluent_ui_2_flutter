import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Checkbox docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage checkboxPage = DocsPage(
  id: 'components-checkbox',
  title: 'Checkbox',
  description: '',
  source: 'lib/pages/components_checkbox.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-checkbox--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-checkbox--checked',
      title: 'Checked',
      description:
          'A checkbox can be initially checked using defaultChecked, or '
          'controlled via the checked property.',
      builder: _checked,
    ),
    DocsSection(
      id: 'components-checkbox--mixed',
      title: 'Mixed',
      description:
          'A checkbox can be initially mixed (also known as indeterminate) '
          'using defaultChecked="mixed", or controlled via checked="mixed". In '
          'this example, the mixed state is used when a group of options has '
          'differing values.',
      builder: _mixed,
    ),
    DocsSection(
      id: 'components-checkbox--disabled',
      title: 'Disabled',
      description: 'A checkbox can be disabled.',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-checkbox--large',
      title: 'Large',
      description: 'A checkbox can be large in size.',
      builder: _large,
    ),
    DocsSection(
      id: 'components-checkbox--label-before',
      title: 'Label Before',
      description: 'The label can be placed before the checkbox.',
      builder: _labelBefore,
    ),
    DocsSection(
      id: 'components-checkbox--label-wrapping',
      title: 'Label Wrapping',
      description:
          'The label will wrap if it is wider than the available space. The '
          'checkbox indicator will stay aligned to the first line of text.',
      builder: _labelWrapping,
    ),
    DocsSection(
      id: 'components-checkbox--required',
      title: 'Required',
      description:
          'When a checkbox is marked as required, its label also gets the '
          'required styling.',
      builder: _required,
    ),
    DocsSection(
      id: 'components-checkbox--circular',
      title: 'Circular',
      description:
          'A checkbox can have a circular shape. Usage warning: Unless you are '
          'designing a tasks experience, we strongly discourage using this '
          'styling variant, as it can be confused with RadioItem.',
      builder: _circular,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'checked',
      type: 'bool?',
      defaultValue: 'false',
      description: 'The tri-state value. Null is the mixed state.',
    ),
    PropRow(
      name: 'onChanged',
      type: 'ValueChanged<bool?>?',
      defaultValue: 'null',
      description:
          'Invoked with the next value on tap and on Space or Enter. Null '
          'disables the checkbox.',
    ),
    PropRow(
      name: 'label',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'The label. Null renders the indicator alone, in which case '
          'semanticLabel carries the meaning.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentCheckboxSize',
      defaultValue: 'FluentCheckboxSize.medium',
      description: 'Indicator box and glyph size.',
    ),
    PropRow(
      name: 'shape',
      type: 'FluentCheckboxShape',
      defaultValue: 'FluentCheckboxShape.square',
      description: 'Corner treatment of the indicator box.',
    ),
    PropRow(
      name: 'labelPosition',
      type: 'FluentCheckboxLabelPosition',
      defaultValue: 'FluentCheckboxLabelPosition.after',
      description: 'Which side the label sits on.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentCheckboxStyle?',
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
          'Announced by assistive technology alongside the checked state.',
    ),
  ],
);

// #docregion components-checkbox--default
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  bool? _checked = false;

  @override
  Widget build(BuildContext context) => FluentCheckbox(
    checked: _checked,
    onChanged: (bool? value) => setState(() => _checked = value),
    // Upstream renders the bare indicator here. Without a label slot the
    // control has no accessible name, so semanticLabel supplies one.
    semanticLabel: 'Checkbox',
  );
}
// #enddocregion components-checkbox--default

// #docregion components-checkbox--checked
Widget _checked(BuildContext context) => const _Checked();

class _Checked extends StatefulWidget {
  const _Checked();

  @override
  State<_Checked> createState() => _CheckedState();
}

class _CheckedState extends State<_Checked> {
  bool? _checked = true;

  @override
  Widget build(BuildContext context) => FluentCheckbox(
    checked: _checked,
    onChanged: (bool? value) => setState(() => _checked = value),
    label: const Text('Checked'),
  );
}
// #enddocregion components-checkbox--checked

// #docregion components-checkbox--mixed
Widget _mixed(BuildContext context) => const _Mixed();

class _Mixed extends StatefulWidget {
  const _Mixed();

  @override
  State<_Mixed> createState() => _MixedState();
}

class _MixedState extends State<_Mixed> {
  bool _option1 = false;
  bool _option2 = true;
  bool _option3 = false;

  /// True when every option is on, false when none is, and null — the mixed
  /// state — in between. Upstream spells the same three-way result `"mixed"`.
  bool? get _all {
    if (_option1 && _option2 && _option3) {
      return true;
    }
    if (!(_option1 || _option2 || _option3)) {
      return false;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      FluentCheckbox(
        checked: _all,
        onChanged: (bool? value) => setState(() {
          _option1 = value ?? false;
          _option2 = value ?? false;
          _option3 = value ?? false;
        }),
        label: const Text('All options'),
      ),
      FluentCheckbox(
        checked: _option1,
        onChanged: (_) => setState(() => _option1 = !_option1),
        label: const Text('Option 1'),
      ),
      FluentCheckbox(
        checked: _option2,
        onChanged: (_) => setState(() => _option2 = !_option2),
        label: const Text('Option 2'),
      ),
      FluentCheckbox(
        checked: _option3,
        onChanged: (_) => setState(() => _option3 = !_option3),
        label: const Text('Option 3'),
      ),
    ],
  );
}
// #enddocregion components-checkbox--mixed

// #docregion components-checkbox--disabled
// `onChanged: null` is how a Fluent checkbox is disabled — a real state, not a
// visual treatment: it stops reporting hover and press and refuses focus.
Widget _disabled(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    FluentCheckbox(label: Text('Disabled')),
    FluentCheckbox(checked: true, label: Text('Disabled checked')),
    FluentCheckbox(checked: null, label: Text('Disabled mixed')),
  ],
);
// #enddocregion components-checkbox--disabled

// #docregion components-checkbox--large
Widget _large(BuildContext context) => const _Large();

class _Large extends StatefulWidget {
  const _Large();

  @override
  State<_Large> createState() => _LargeState();
}

class _LargeState extends State<_Large> {
  bool? _checked = false;

  @override
  Widget build(BuildContext context) => FluentCheckbox(
    size: FluentCheckboxSize.large,
    checked: _checked,
    onChanged: (bool? value) => setState(() => _checked = value),
    label: const Text('Large'),
  );
}
// #enddocregion components-checkbox--large

// #docregion components-checkbox--label-before
Widget _labelBefore(BuildContext context) => const _LabelBefore();

class _LabelBefore extends StatefulWidget {
  const _LabelBefore();

  @override
  State<_LabelBefore> createState() => _LabelBeforeState();
}

class _LabelBeforeState extends State<_LabelBefore> {
  bool? _checked = false;

  @override
  Widget build(BuildContext context) => FluentCheckbox(
    labelPosition: FluentCheckboxLabelPosition.before,
    checked: _checked,
    onChanged: (bool? value) => setState(() => _checked = value),
    label: const Text('Label before'),
  );
}
// #enddocregion components-checkbox--label-before

// #docregion components-checkbox--label-wrapping
Widget _labelWrapping(BuildContext context) => const _LabelWrapping();

class _LabelWrapping extends StatefulWidget {
  const _LabelWrapping();

  @override
  State<_LabelWrapping> createState() => _LabelWrappingState();
}

class _LabelWrappingState extends State<_LabelWrapping> {
  bool? _checked = false;

  @override
  Widget build(BuildContext context) => FluentCheckbox(
    checked: _checked,
    onChanged: (bool? value) => setState(() => _checked = value),
    // Upstream caps the whole control at 400px and lets the label reflow.
    // A Fluent checkbox lays its label out in a `MainAxisSize.min` Row, which
    // hands the label unbounded width, so the cap goes on the label itself:
    // 400 less the 32 indicator box and the 12 of label padding.
    label: const SizedBox(
      width: 356,
      child: Text(
        'Here is an example of a checkbox with a long label and it starts to '
        'wrap to a second line',
      ),
    ),
  );
}
// #enddocregion components-checkbox--label-wrapping

// #docregion components-checkbox--required
Widget _required(BuildContext context) => const _Required();

class _Required extends StatefulWidget {
  const _Required();

  @override
  State<_Required> createState() => _RequiredState();
}

class _RequiredState extends State<_Required> {
  bool? _checked = false;

  @override
  Widget build(BuildContext context) => FluentCheckbox(
    checked: _checked,
    onChanged: (bool? value) => setState(() => _checked = value),
    // `FluentCheckbox` has no `required` flag. Upstream's does nothing but
    // forward it to the label slot, so the asterisk comes from a `FluentLabel`
    // passed into that same slot.
    label: const FluentLabel(required: true, child: Text('Required')),
  );
}
// #enddocregion components-checkbox--required

// #docregion components-checkbox--circular
Widget _circular(BuildContext context) => const _Circular();

class _Circular extends StatefulWidget {
  const _Circular();

  @override
  State<_Circular> createState() => _CircularState();
}

class _CircularState extends State<_Circular> {
  bool? _checked = false;

  @override
  Widget build(BuildContext context) => FluentCheckbox(
    shape: FluentCheckboxShape.circular,
    checked: _checked,
    onChanged: (bool? value) => setState(() => _checked = value),
    label: const Text('Circular'),
  );
}

// #enddocregion components-checkbox--circular
