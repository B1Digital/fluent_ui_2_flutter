import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Two grids. The first is the whole `Style` x `Size` matrix at rest and then
/// the three states that replace the appearance wholesale — Error, Disabled and
/// Read only — so a regression that drops the danger border or lets a disabled
/// field keep its fill shows up as one changed cell.
///
/// The second is focus, which needs a real focused field and therefore its own
/// image. One appearance is enough: the brand rule is the same
/// `compoundBrandStroke` at 2px on all three, which `textarea_test.dart`
/// asserts numerically.
///
/// High contrast is the image that matters most here — the two filled
/// appearances paint a *transparent* border in light and dark, and it is only
/// there that it must become visible.
void main() {
  goldenGridTest(
    'textarea',
    () => goldenGrid(<Widget>[
      for (final appearance in FluentTextareaAppearance.values)
        for (final size in FluentTextareaSize.values)
          _cell(
            FluentTextarea(
              appearance: appearance,
              size: size,
              placeholder: 'Placeholder text',
            ),
          ),
      for (final appearance in FluentTextareaAppearance.values)
        _cell(
          FluentTextarea(
            appearance: appearance,
            invalid: true,
            placeholder: 'Placeholder text',
          ),
        ),
      for (final appearance in FluentTextareaAppearance.values)
        _cell(
          FluentTextarea(
            appearance: appearance,
            enabled: false,
            placeholder: 'Placeholder text',
          ),
        ),
      for (final appearance in FluentTextareaAppearance.values)
        _cell(
          FluentTextarea(
            appearance: appearance,
            readOnly: true,
            controller: _readOnly,
          ),
        ),
      for (final appearance in FluentTextareaAppearance.values)
        _cell(FluentTextarea(appearance: appearance, controller: _filled)),
    ], columns: 3),
    surfaceSize: const Size(1200, 1200),
  );

  goldenGridTest(
    'textarea',
    () => _cell(
      const FluentTextarea(autofocus: true, placeholder: 'Placeholder text'),
    ),
    suffix: '_focus',
    surfaceSize: const Size(600, 300),
  );
}

/// A textarea hugs its parent's width, so every cell has to state one.
Widget _cell(Widget textarea) => SizedBox(width: 280, child: textarea);

/// Held at library scope rather than built per cell: a controller created
/// inside the grid builder would be handed to a widget that does not own it,
/// and so would never be disposed.
final TextEditingController _readOnly = TextEditingController(
  text: 'Read-only content reads at full contrast.',
);
final TextEditingController _filled = TextEditingController(
  text: 'Entered text.',
);
