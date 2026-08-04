import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Rows 1-3: every Appearance at every Size, at rest, showing the placeholder.
/// Row 4: the four remaining `State` columns of the Figma set — Error,
/// Disabled, Read only, and Focus (the one autofocused cell, so the brand bar
/// is fully grown by the time `pumpAndSettle` returns).
/// Row 5: the content-before / content-after slots and an obscured field.
///
/// The cells worth watching are the Outline ones: they carry two rules along
/// the bottom edge — the `Neutral/Stroke/Accessible` hairline over the box
/// border, and the brand focus bar over that.
void main() {
  Widget cell(Widget child) => SizedBox(width: 200, child: child);

  goldenGridTest(
    'input',
    () => goldenGrid(<Widget>[
      for (final size in FluentInputSize.values)
        for (final appearance in FluentInputAppearance.values)
          cell(
            FluentInput(
              appearance: appearance,
              size: size,
              placeholder: const Text('Placeholder'),
            ),
          ),
      cell(const FluentInput(error: true, placeholder: Text('Error'))),
      cell(const FluentInput(enabled: false, placeholder: Text('Disabled'))),
      cell(const FluentInput(readOnly: true, placeholder: Text('Read only'))),
      cell(const FluentInput(autofocus: true, placeholder: Text('Focus'))),
      cell(
        const FluentInput(
          contentBefore: Icon(IconData(0x21)),
          placeholder: Text('Before'),
        ),
      ),
      cell(
        const FluentInput(
          contentAfter: Icon(IconData(0x22)),
          placeholder: Text('After'),
        ),
      ),
      cell(
        const FluentInput(
          appearance: FluentInputAppearance.filledDarker,
          contentBefore: Icon(IconData(0x21)),
          contentAfter: Icon(IconData(0x22)),
          placeholder: Text('Both'),
        ),
      ),
      cell(
        const FluentInput(
          appearance: FluentInputAppearance.underline,
          error: true,
          placeholder: Text('Underline error'),
        ),
      ),
    ], columns: 4),
    surfaceSize: const Size(1200, 700),
  );
}
