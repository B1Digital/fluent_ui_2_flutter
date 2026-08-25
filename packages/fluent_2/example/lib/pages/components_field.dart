import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Field docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage fieldPage = DocsPage(
  id: 'components-field',
  title: 'Field',
  description:
      'Field adds a label, validation message, and hint text to a control.',
  source: 'lib/pages/components_field.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-field--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-field--horizontal',
      title: 'Horizontal Orientation',
      description:
          'Setting orientation="horizontal" places the label beside the input. '
          'The validationMessage and hint still appear below the input. The '
          'label width is a fixed 33% of the width of the field. This makes it '
          'so horizontal fields are aligned when stacked together.',
      builder: _horizontal,
    ),
    DocsSection(
      id: 'components-field--required',
      title: 'Required',
      description:
          'When a Field is marked as required, the label has a red asterisk, '
          'and the input gets the aria-required property for accessiblity '
          'tools.',
      builder: _required,
    ),
    DocsSection(
      id: 'components-field--info',
      title: 'Info button',
      description:
          "Add an info button to the label by replacing the Field's label with "
          'an InfoLabel. This can be done using a slot render function. See the '
          'code from this story for more details.',
      builder: _info,
    ),
    DocsSection(
      id: 'components-field--disabled',
      title: 'Disabled control',
      description:
          'When the control inside the Field is disabled, the label should not '
          'be marked disabled. This ensures the label remains readable to '
          'users.',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-field--size',
      title: 'Size',
      description:
          "The size prop affects the size of the Field's label, as well as form "
          'controls that support a size prop.',
      builder: _size,
    ),
    DocsSection(
      id: 'components-field--validation-message',
      title: 'Validation Message',
      description:
          'The validationMessage is used to give the user feedback about the '
          'value entered. Field does not do validation itself, but can be used '
          'to report the result of form validation. The validationState affects '
          'the behavior and appearance of the message: error - (default) The '
          'validation message has red text with a red error icon. It has '
          'role="alert" so it is announced by accessibility tools. '
          'Additionally, the control inside the field has aria-invalid set, '
          'which adds a red border to some field components (such as Input). '
          'success - The validation message has gray text with a green '
          'checkmark icon. warning - The validation message has gray text with '
          'a yellow exclamation icon. none - The validation message has gray '
          'text with no icon. Optionally, validationMessageIcon can be used to '
          'override the default icon (or add an icon in the case of '
          'validationState="none").',
      builder: _validationMessage,
    ),
    DocsSection(
      id: 'components-field--hint',
      title: 'Hint',
      description:
          'The hint provides additional descriptive information about the '
          'field. Hint text should be used sparingly.',
      builder: _hint,
    ),
    DocsSection(
      id: 'components-field--component-examples',
      title: 'Component Examples',
      description:
          'Field can be used with any input components in this library. This '
          'story shows some examples. It can also be used to add a label or '
          'error text to components like ProgressBar.',
      builder: _componentExamples,
    ),
    DocsSection(
      id: 'components-field--render-function',
      title: 'Third party controls a Field',
      description:
          'Field uses context to associate its label and message text with its '
          'child form control. All of the form controls in this library support '
          'FieldContext. To use a third party control that does not support '
          'FieldContext, the child of Field may be a function that takes props '
          'to pass to the control. See the code in this example for more '
          'details.',
      builder: _renderFunction,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'child',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'The control being wrapped.',
    ),
    PropRow(
      name: 'label',
      type: 'Widget?',
      defaultValue: 'null',
      description:
          'The label content. Wrapped in a FluentLabel sized from '
          'size.',
    ),
    PropRow(
      name: 'hint',
      type: 'Widget?',
      defaultValue: 'null',
      description: "The hint below the control. Upstream's hint slot.",
    ),
    PropRow(
      name: 'validationMessage',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'The validation message below the control.',
    ),
    PropRow(
      name: 'validationMessageIcon',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'The glyph beside validationMessage.',
    ),
    PropRow(
      name: 'validationState',
      type: 'FluentFieldValidationState',
      defaultValue: 'FluentFieldValidationState.none',
      description: "What the field is reporting about child's value.",
    ),
    PropRow(
      name: 'size',
      type: 'FluentFieldSize',
      defaultValue: 'FluentFieldSize.medium',
      description: 'Label ramp and label-to-control gap.',
    ),
    PropRow(
      name: 'required',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether to render the required-field asterisk after label.',
    ),
    PropRow(
      name: 'enabled',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether the field renders in its enabled colours.',
    ),
    PropRow(
      name: 'style',
      type: 'FluentFieldStyle?',
      defaultValue: 'null',
      description:
          'Overrides layered over the theme defaults. Merged last, so it wins.',
    ),
  ],
);

// #docregion components-field--default
// FluentField supplies no default validation glyph — the icon set is not part
// of the package — so the story passes upstream's success default explicitly.
// The 400px box is upstream's story decorator, not part of Field.
Widget _default(BuildContext context) => const SizedBox(
  width: 400,
  child: FluentField(
    label: Text('Example field'),
    validationState: FluentFieldValidationState.success,
    validationMessage: Text('This is a success message.'),
    validationMessageIcon: Icon(FluentIcons.checkmark_circle_12_filled),
    child: FluentInput(),
  ),
);
// #enddocregion components-field--default

// #docregion components-field--horizontal
// FluentField has no `orientation`: its label always sits above the control.
// Upstream's horizontal layout is a row whose label column is a fixed 33% of
// the field, so that is what the 33/67 flex split reproduces — with the hint
// still under the input, because the field itself is the row's second cell.
Widget _horizontal(BuildContext context) => const SizedBox(
  width: 400,
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Expanded(
        flex: 33,
        // 32 is the height of a medium FluentInput, so the label centres
        // against the control rather than against the control plus its hint.
        child: SizedBox(
          height: 32,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FluentLabel(child: Text('Horizontal')),
          ),
        ),
      ),
      Expanded(
        flex: 67,
        child: FluentField(
          hint: Text('Validation message and hint are below the input.'),
          child: FluentInput(),
        ),
      ),
    ],
  ),
);
// #enddocregion components-field--horizontal

// #docregion components-field--required
Widget _required(BuildContext context) => const SizedBox(
  width: 400,
  child: FluentField(
    label: Text('Required field'),
    required: true,
    child: FluentInput(),
  ),
);
// #enddocregion components-field--required

// #docregion components-field--info
// Upstream replaces the whole label slot with an `InfoLabel` through a slot
// render function. FluentField takes a plain widget there, so handing it a
// FluentInfoLabel is the same substitution without the indirection.
// `infoSemanticLabel` has no upstream counterpart; FluentInfoLabel requires one
// so the trigger is not announced as an unlabelled button.
Widget _info(BuildContext context) => const SizedBox(
  width: 400,
  child: FluentField(
    label: FluentInfoLabel(
      info: Text('Example info'),
      infoSemanticLabel: 'More information',
      child: Text('Field with an info button'),
    ),
    child: FluentInput(),
  ),
);
// #enddocregion components-field--info

// #docregion components-field--disabled
// The field stays `enabled`, so only the control is disabled and the label
// keeps its readable colour.
Widget _disabled(BuildContext context) => const SizedBox(
  width: 400,
  child: FluentField(
    label: Text('Field with disabled control'),
    child: FluentInput(enabled: false),
  ),
);
// #enddocregion components-field--disabled

// #docregion components-field--size
// FluentField.size scales the label only, so each control is given the matching
// FluentInputSize by hand.
Widget _size(BuildContext context) => const SizedBox(
  width: 400,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: <Widget>[
      FluentField(
        label: Text('Size small'),
        size: FluentFieldSize.small,
        child: FluentInput(size: FluentInputSize.small),
      ),
      FluentField(
        label: Text('Size medium'),
        size: FluentFieldSize.medium,
        child: FluentInput(),
      ),
      FluentField(
        label: Text('Size large'),
        size: FluentFieldSize.large,
        child: FluentInput(size: FluentInputSize.large),
      ),
    ],
  ),
);
// #enddocregion components-field--size

// #docregion components-field--validation-message
// Upstream defaults the glyph per validation state; this port leaves the slot
// empty because the icon set is not part of the package, so each state names
// its own default here.
Widget _validationMessage(BuildContext context) => const SizedBox(
  width: 400,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 16,
    children: <Widget>[
      FluentField(
        label: Text('Error state'),
        validationState: FluentFieldValidationState.error,
        validationMessage: Text('This is an error message.'),
        validationMessageIcon: Icon(FluentIcons.error_circle_12_filled),
        child: FluentInput(error: true),
      ),
      FluentField(
        label: Text('Warning state'),
        validationState: FluentFieldValidationState.warning,
        validationMessage: Text('This is a warning message.'),
        validationMessageIcon: Icon(FluentIcons.warning_12_filled),
        child: FluentInput(),
      ),
      FluentField(
        label: Text('Success state'),
        validationState: FluentFieldValidationState.success,
        validationMessage: Text('This is a success message.'),
        validationMessageIcon: Icon(FluentIcons.checkmark_circle_12_filled),
        child: FluentInput(),
      ),
      FluentField(
        label: Text('Custom state'),
        validationMessage: Text('This is a custom message.'),
        validationMessageIcon: Icon(FluentIcons.sparkle_20_filled),
        child: FluentInput(),
      ),
    ],
  ),
);
// #enddocregion components-field--validation-message

// #docregion components-field--hint
Widget _hint(BuildContext context) => const SizedBox(
  width: 400,
  child: FluentField(
    label: Text('Example with hint'),
    hint: Text('Sample hint text.'),
    child: FluentInput(),
  ),
);
// #enddocregion components-field--hint

// #docregion components-field--component-examples
// Upstream's controls are uncontrolled; every Fluent control in this port is
// controlled, so the story owns one piece of state per control.
// Combobox has no port yet — FluentDropdown is the nearest select.
Widget _componentExamples(BuildContext context) => const _ComponentExamples();

class _ComponentExamples extends StatefulWidget {
  const _ComponentExamples();

  @override
  State<_ComponentExamples> createState() => _ComponentExamplesState();
}

class _ComponentExamplesState extends State<_ComponentExamples> {
  String? _option;
  double? _spin = 0;
  bool _checked = false;
  double _slider = 25;
  bool _switched = false;
  String? _radio;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 400,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: <Widget>[
        const FluentField(label: Text('Input'), child: FluentInput()),
        const FluentField(label: Text('Textarea'), child: FluentTextarea()),
        FluentField(
          label: const Text('Combobox'),
          child: FluentDropdown<String>(
            value: _option,
            onChanged: (String value) => setState(() => _option = value),
            options: const <FluentDropdownOption<String>>[
              FluentDropdownOption<String>(
                value: 'Option 1',
                label: Text('Option 1'),
              ),
              FluentDropdownOption<String>(
                value: 'Option 2',
                label: Text('Option 2'),
              ),
              FluentDropdownOption<String>(
                value: 'Option 3',
                label: Text('Option 3'),
              ),
            ],
          ),
        ),
        FluentField(
          label: const Text('SpinButton'),
          child: FluentSpinButton(
            value: _spin,
            onChanged: (double? value) => setState(() => _spin = value),
          ),
        ),
        FluentField(
          hint: const Text(
            'Checkboxes use their own label instead of the Field label.',
          ),
          child: FluentCheckbox(
            checked: _checked,
            label: const Text('Checkbox'),
            onChanged: (bool? value) =>
                setState(() => _checked = value ?? false),
          ),
        ),
        FluentField(
          label: const Text('Slider'),
          child: FluentSlider(
            value: _slider,
            onChanged: (double value) => setState(() => _slider = value),
          ),
        ),
        FluentField(
          label: const Text('Switch'),
          child: FluentSwitch(
            checked: _switched,
            onChanged: (bool value) => setState(() => _switched = value),
          ),
        ),
        FluentField(
          label: const Text('RadioGroup'),
          child: FluentRadioGroup<String>(
            value: _radio,
            onChanged: (String value) => setState(() => _radio = value),
            children: const <Widget>[
              FluentRadio<String>(value: 'Option 1', label: Text('Option 1')),
              FluentRadio<String>(value: 'Option 2', label: Text('Option 2')),
              FluentRadio<String>(value: 'Option 3', label: Text('Option 3')),
            ],
          ),
        ),
      ],
    ),
  );
}
// #enddocregion components-field--component-examples

// #docregion components-field--render-function
// Flutter has no FieldContext to opt into, so no render function is needed:
// FluentField wraps whatever it is given in one semantics container, which is
// what associates the label with a control the field knows nothing about.
Widget _renderFunction(BuildContext context) => const SizedBox(
  width: 400,
  child: FluentField(
    label: Text('Third party input'),
    hint: Text(
      'Use a render function to properly associate the label with the control.',
    ),
    child: _CatInput(),
  ),
);

class _CatInput extends StatelessWidget {
  const _CatInput();

  @override
  Widget build(BuildContext context) => const Row(
    spacing: 4,
    children: <Widget>[
      Icon(FluentIcons.animal_cat_24_regular, size: 24),
      Expanded(child: FluentInput()),
    ],
  );
}

// #enddocregion components-field--render-function
