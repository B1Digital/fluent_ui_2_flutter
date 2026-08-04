import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Rows 1-2: every Status (unchecked, checked, mixed) at every Size, square
/// then circular. Row 3: the disabled ramp across all three statuses, then the
/// two label positions and a disabled label.
///
/// The mixed cells are the ones worth watching: Fluent 2 draws a filled square
/// (or circle) there, not Material's dash.
void main() {
  goldenGridTest(
    'checkbox',
    () => goldenGrid(<Widget>[
      for (final shape in FluentCheckboxShape.values)
        for (final size in FluentCheckboxSize.values)
          for (final checked in const <bool?>[false, true, null])
            FluentCheckbox(
              checked: checked,
              shape: shape,
              size: size,
              onChanged: (_) {},
            ),
      for (final checked in const <bool?>[false, true, null])
        FluentCheckbox(checked: checked),
      const FluentCheckbox(checked: true, label: Text('Label')),
      const FluentCheckbox(
        checked: null,
        labelPosition: FluentCheckboxLabelPosition.before,
        label: Text('Label'),
      ),
      const FluentCheckbox(label: Text('Label')),
    ], columns: 6),
  );
}
