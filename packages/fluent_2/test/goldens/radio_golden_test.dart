import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Row 1: unchecked and checked, enabled then disabled, label after.
/// Row 2: the same four with the label below.
/// Row 3: the three `Direction` layouts of a two-option group.
void main() {
  Widget cell({
    required bool checked,
    required bool disabled,
    required FluentRadioLabelPosition position,
  }) => FluentRadio<String>(
    value: 'a',
    groupValue: checked ? 'a' : 'b',
    onChanged: (_) {},
    disabled: disabled,
    labelPosition: position,
    label: const Text('Option'),
  );

  Widget group(FluentRadioGroupLayout layout) => FluentRadioGroup<String>(
    layout: layout,
    value: 'a',
    onChanged: (_) {},
    children: const <Widget>[
      FluentRadio<String>(value: 'a', label: Text('One')),
      FluentRadio<String>(value: 'b', label: Text('Two')),
    ],
  );

  goldenGridTest(
    'radio',
    () => goldenGrid(<Widget>[
      for (final position in FluentRadioLabelPosition.values)
        for (final checked in <bool>[false, true])
          for (final disabled in <bool>[false, true])
            cell(checked: checked, disabled: disabled, position: position),
      for (final layout in FluentRadioGroupLayout.values) group(layout),
      // Indicator-only, which is what a radio in a data grid cell looks like.
      const FluentRadio<String>(value: 'a', groupValue: 'a'),
    ], columns: 4),
  );
}
