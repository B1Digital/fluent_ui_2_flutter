import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Textarea docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage textareaPage = DocsPage(
  id: 'components-textarea',
  title: 'Textarea',
  description: 'Textarea allows the user to enter and edit multiline text.',
  source: 'lib/pages/components_textarea.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'components-textarea--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'components-textarea--appearance',
      title: 'Appearance',
      description:
          'Textarea can have different appearances. The colors adjacent to the '
          'Textarea should have a sufficient contrast. Particularly, the color '
          'of input with filled darker and lighter styles needs to provide a '
          'contrast ratio greater than 3 to 1 against the immediate '
          'surrounding color to pass accessibility requirement.',
      builder: _appearance,
    ),
    DocsSection(
      id: 'components-textarea--disabled',
      title: 'Disabled',
      builder: _disabled,
    ),
    DocsSection(
      id: 'components-textarea--placeholder',
      title: 'Placeholder',
      builder: _placeholder,
    ),
    DocsSection(
      id: 'components-textarea--resize',
      title: 'Resize',
      builder: _resize,
    ),
    DocsSection(id: 'components-textarea--size', title: 'Size', builder: _size),
    DocsSection(
      id: 'components-textarea--uncontrolled',
      title: 'Uncontrolled',
      builder: _uncontrolled,
    ),
    DocsSection(
      id: 'components-textarea--controlled',
      title: 'Controlled',
      builder: _controlled,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'controller',
      type: 'TextEditingController?',
      defaultValue: 'null',
      description:
          'The text being edited. One is created internally when omitted.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentTextareaAppearance',
      defaultValue: 'FluentTextareaAppearance.outline',
      description: 'Fill and outline treatment.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentTextareaSize',
      defaultValue: 'FluentTextareaSize.medium',
      description: 'Type ramp and inset.',
    ),
    PropRow(
      name: 'placeholder',
      type: 'String?',
      defaultValue: 'null',
      description: 'Shown while the field is empty.',
    ),
    PropRow(
      name: 'enabled',
      type: 'bool',
      defaultValue: 'true',
      description:
          'Whether the field accepts input. False is a real state, not a '
          'treatment.',
    ),
    PropRow(
      name: 'readOnly',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether the field refuses edits while staying focusable and '
          'selectable.',
    ),
    PropRow(
      name: 'invalid',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether to paint the error border.',
    ),
    PropRow(
      name: 'minLines',
      type: 'int?',
      defaultValue: '2',
      description: 'Smallest number of lines the field occupies.',
    ),
    PropRow(
      name: 'maxLines',
      type: 'int?',
      defaultValue: 'null',
      description:
          'Largest number of lines before the field scrolls internally. Null '
          'grows without bound.',
    ),
    PropRow(
      name: 'maxLength',
      type: 'int?',
      defaultValue: 'null',
      description:
          'Hard cap on the number of characters, enforced by an input '
          'formatter.',
    ),
    PropRow(
      name: 'onChanged',
      type: 'ValueChanged<String>?',
      defaultValue: 'null',
      description: 'Invoked on every edit.',
    ),
  ],
);

// #docregion components-textarea--default
Widget _default(BuildContext context) =>
    const FluentField(label: Text('Default Textarea'), child: FluentTextarea());
// #enddocregion components-textarea--default

// #docregion components-textarea--appearance
// Upstream also sets `resize="both"` on all three — see the Resize section for
// why that prop has no counterpart here.
Widget _appearance(BuildContext context) {
  final FluentColors colors = FluentTheme.of(context).colors;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: FluentSpacing.mNudge,
    children: <Widget>[
      const Padding(
        padding: EdgeInsets.symmetric(
          vertical: FluentSpacing.mNudge,
          horizontal: FluentSpacing.mNudge,
        ),
        child: FluentField(
          label: Text('Textarea with Outline appearance'),
          child: FluentTextarea(placeholder: 'type here...'),
        ),
      ),
      Container(
        color: colors.neutralBackgroundInverted,
        padding: const EdgeInsets.symmetric(
          vertical: FluentSpacing.mNudge,
          horizontal: FluentSpacing.mNudge,
        ),
        child: FluentField(
          label: Text(
            'Textarea with Filled Darker appearance',
            style: TextStyle(color: colors.neutralForegroundInverted2),
          ),
          child: const FluentTextarea(
            appearance: FluentTextareaAppearance.filledDarker,
            placeholder: 'type here...',
          ),
        ),
      ),
      Container(
        color: colors.neutralBackgroundInverted,
        padding: const EdgeInsets.symmetric(
          vertical: FluentSpacing.mNudge,
          horizontal: FluentSpacing.mNudge,
        ),
        child: FluentField(
          label: Text(
            'Textarea with Filled Lighter appearance',
            style: TextStyle(color: colors.neutralForegroundInverted2),
          ),
          child: const FluentTextarea(
            appearance: FluentTextareaAppearance.filledLighter,
            placeholder: 'type here...',
          ),
        ),
      ),
    ],
  );
}
// #enddocregion components-textarea--appearance

// #docregion components-textarea--disabled
Widget _disabled(BuildContext context) => const FluentField(
  label: Text('Disabled Textarea'),
  child: FluentTextarea(enabled: false),
);
// #enddocregion components-textarea--disabled

// #docregion components-textarea--placeholder
Widget _placeholder(BuildContext context) => const FluentField(
  label: Text('Textarea with placeholder'),
  child: FluentTextarea(placeholder: 'type here...'),
);
// #enddocregion components-textarea--placeholder

// #docregion components-textarea--resize
// Upstream's `resize` prop toggles the browser's native drag-to-resize grip on
// the `<textarea>`. Flutter has no such affordance, so each variant renders the
// nearest behaviour our widget does have: `maxLines: 2` pins the height, and
// the default `maxLines: null` lets the field grow as the text does. Nothing
// here can be widened by dragging, so the two horizontal variants are pinned.
Widget _resize(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  mainAxisSize: MainAxisSize.min,
  spacing: FluentSpacing.mNudge,
  children: <Widget>[
    FluentField(
      label: Text('Textarea with resize set to "none"'),
      child: FluentTextarea(maxLines: 2),
    ),
    FluentField(
      label: Text('Textarea with resize set to "vertical"'),
      child: FluentTextarea(),
    ),
    FluentField(
      label: Text('Textarea with resize set to "horizontal"'),
      child: FluentTextarea(maxLines: 2),
    ),
    FluentField(
      label: Text('Textarea with resize set to "both"'),
      child: FluentTextarea(),
    ),
  ],
);
// #enddocregion components-textarea--resize

// #docregion components-textarea--size
// Upstream sets the size on `Field` alone and the `Textarea` picks it up from
// the field's context. `FluentField` sizes only its own label, so the size goes
// on both widgets here to get the same rendering.
Widget _size(BuildContext context) => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  mainAxisSize: MainAxisSize.min,
  spacing: FluentSpacing.mNudge,
  children: <Widget>[
    FluentField(
      size: FluentFieldSize.small,
      label: Text('Small Textarea'),
      child: FluentTextarea(size: FluentTextareaSize.small),
    ),
    FluentField(
      size: FluentFieldSize.medium,
      label: Text('Medium Textarea'),
      child: FluentTextarea(size: FluentTextareaSize.medium),
    ),
    FluentField(
      size: FluentFieldSize.large,
      label: Text('Large Textarea'),
      child: FluentTextarea(size: FluentTextareaSize.large),
    ),
  ],
);
// #enddocregion components-textarea--size

// #docregion components-textarea--uncontrolled
Widget _uncontrolled(BuildContext context) => FluentField(
  label: const Text('Uncontrolled Textarea'),
  hint: const Text('Check console for new value'),
  child: FluentTextarea(
    // Uncontrolled inputs can be notified of changes to the value
    onChanged: (String value) => debugPrint('New value: "$value"'),
    placeholder: 'type here...',
  ),
);
// #enddocregion components-textarea--uncontrolled

// #docregion components-textarea--controlled
// A `FluentTextarea` is controlled by owning its `TextEditingController` rather
// than by passing `value` back in on every keystroke, so the 50-character limit
// upstream enforces inside `onChange` is enforced by `maxLength` instead.
Widget _controlled(BuildContext context) => const _Controlled();

class _Controlled extends StatefulWidget {
  const _Controlled();

  @override
  State<_Controlled> createState() => _ControlledState();
}

class _ControlledState extends State<_Controlled> {
  final TextEditingController _controller = TextEditingController(
    text: 'initial value',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FluentField(
    label: const Text(
      'Controlled Textarea limiting the value to 50 characters',
    ),
    child: FluentTextarea(controller: _controller, maxLength: 50),
  );
}

// #enddocregion components-textarea--controlled
