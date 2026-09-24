import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Row 1: the three sizes, each with a required label, a control, a validation
/// message and a hint — the whole component at once.
/// Row 2: the four validation states, each with upstream's default glyph
/// (`none` has none). Watch the message text: `warning` and `success` tint the
/// glyph and leave the text neutral, which is upstream's rule and the detail
/// most likely to be "fixed" by someone who has only seen the error state.
/// Row 3: disabled, a field with no label, and a message with its glyph
/// switched off.
///
/// A field is block-level, so every cell is width-bounded; the control is a
/// real `FluentButton` rather than an invented placeholder so the cells stay
/// honest in all three themes.
void main() {
  goldenGridTest(
    'field',
    () => goldenGrid(<Widget>[
      for (final size in FluentFieldSize.values)
        _cell(
          FluentField(
            size: size,
            required: true,
            label: const Text('Label'),
            validationState: FluentFieldValidationState.error,
            validationMessage: const Text('Error text'),
            hint: const Text('Helper text'),
            child: _control,
          ),
        ),
      for (final state in FluentFieldValidationState.values)
        _cell(
          FluentField(
            label: const Text('Label'),
            validationState: state,
            validationMessage: const Text('Message'),
            child: _control,
          ),
        ),
      _cell(
        FluentField(
          enabled: false,
          required: true,
          label: const Text('Label'),
          validationState: FluentFieldValidationState.error,
          validationMessage: const Text('Error text'),
          hint: const Text('Helper text'),
          child: _control,
        ),
      ),
      _cell(FluentField(hint: const Text('Helper text'), child: _control)),
      _cell(
        FluentField(
          label: const Text('Label'),
          validationState: FluentFieldValidationState.warning,
          showValidationMessageIcon: false,
          validationMessage: const Text('No glyph on this one'),
          child: _control,
        ),
      ),
    ], columns: 3),
  );
}

/// A field has no intrinsic width — it stretches its rows to whatever it is
/// given, the same as upstream's `display: grid` root.
Widget _cell(Widget field) => SizedBox(width: 220, child: field);

final Widget _control = FluentButton(onPressed: () {}, child: const Text('Go'));
