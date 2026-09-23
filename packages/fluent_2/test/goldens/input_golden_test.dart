import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Rows 1-3: every Appearance at every Size, at rest, showing the placeholder.
/// Row 4: the four remaining `State` columns of the Figma set — Error,
/// Disabled, Read only, and Focus (the one autofocused cell, so the brand bar
/// is fully grown by the time `pumpAndSettle` returns).
/// Row 5: the content-before / content-after slots and an invalid Underline.
///
/// The cells worth watching are the Outline ones: their bottom border side is
/// `Neutral/Stroke/Accessible` while the other three are `Neutral/Stroke/1`,
/// and the two colours meet on the corner diagonal the way a CSS border does,
/// so the bottom corners carry the darker colour part-way up the curve. The
/// focused cell adds the brand bar over the bottom border, and its sides turn
/// `Neutral/Stroke/1/Pressed`.
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
