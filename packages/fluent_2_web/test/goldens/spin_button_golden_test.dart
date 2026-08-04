import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// A row per appearance and a column per state, medium above small.
///
/// The control has no intrinsic width, so every cell is pinned to 160 — a
/// golden of an unbounded spin button would just be the surface size. Cell
/// order is the legend: outline, underline, filled darker, filled lighter,
/// each as rest, error, disabled and read-only.
void main() {
  Widget cell({
    required FluentSpinButtonAppearance appearance,
    FluentSpinButtonSize size = FluentSpinButtonSize.medium,
    bool enabled = true,
    bool invalid = false,
    bool readOnly = false,
    bool autofocus = false,
  }) => SizedBox(
    width: 160,
    child: FluentSpinButton(
      value: 42,
      appearance: appearance,
      size: size,
      invalid: invalid,
      readOnly: readOnly,
      autofocus: autofocus,
      onChanged: enabled ? (_) {} : null,
    ),
  );

  goldenGridTest(
    'spin_button',
    () => goldenGrid(<Widget>[
      for (final size in FluentSpinButtonSize.values)
        for (final appearance in FluentSpinButtonAppearance.values) ...<Widget>[
          cell(appearance: appearance, size: size),
          cell(appearance: appearance, size: size, invalid: true),
          cell(appearance: appearance, size: size, enabled: false),
          cell(appearance: appearance, size: size, readOnly: true),
        ],
    ], columns: 4),
  );

  // The focus underline only exists while something holds focus, and only one
  // node in a grid can, so it gets an image of its own.
  goldenGridTest(
    'spin_button',
    suffix: '_focused',
    () => goldenGrid(<Widget>[
      cell(appearance: FluentSpinButtonAppearance.outline, autofocus: true),
    ], columns: 1),
  );
}
