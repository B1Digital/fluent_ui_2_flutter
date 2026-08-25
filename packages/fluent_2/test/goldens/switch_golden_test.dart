import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Row per size: unchecked and checked, each enabled and disabled.
/// Final row: the three label positions plus the label-less switch.
void main() {
  goldenGridTest(
    'switch',
    () => goldenGrid(<Widget>[
      for (final size in FluentSwitchSize.values)
        for (final checked in <bool>[false, true]) ...<Widget>[
          FluentSwitch(
            size: size,
            checked: checked,
            onChanged: (_) {},
            label: const Text('Switch'),
          ),
          FluentSwitch(
            size: size,
            checked: checked,
            label: const Text('Switch'),
          ),
        ],
      for (final position in FluentSwitchLabelPosition.values)
        FluentSwitch(
          checked: true,
          labelPosition: position,
          onChanged: (_) {},
          label: const Text('Switch'),
        ),
      FluentSwitch(checked: true, onChanged: (_) {}),
    ]),
  );
}
