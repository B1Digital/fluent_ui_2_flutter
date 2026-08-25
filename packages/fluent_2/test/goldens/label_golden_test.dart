import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Row per weight, one cell per size. Final row: the required asterisk and the
/// disabled foreground, both at medium.
///
/// Glyphs are placeholder boxes, so what this regresses is the type ramp's
/// metrics — box height and baseline move with font size and line height — plus
/// the required marker's colour and position.
void main() {
  goldenGridTest(
    'label',
    () => goldenGrid(columns: 3, <Widget>[
      for (final weight in FluentLabelWeight.values)
        for (final size in FluentLabelSize.values)
          FluentLabel(size: size, weight: weight, child: const Text('Label')),
      const FluentLabel(required: true, child: Text('Label')),
      const FluentLabel(disabled: true, child: Text('Label')),
      const FluentLabel(
        required: true,
        disabled: true,
        weight: FluentLabelWeight.semibold,
        child: Text('Label'),
      ),
    ]),
  );
}
