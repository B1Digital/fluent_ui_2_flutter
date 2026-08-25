/// Regression net for `FluentTagPicker`, in light, dark and high contrast.
///
/// The grid is, in reading order: the four appearances at Medium with a
/// placeholder, then Medium / Large / Extra large carrying two chips, then a
/// disabled control and one with a trailing secondary action. The popup is not
/// captured — it lives in the [Overlay], which is outside the repaint boundary
/// these images are cropped to.
library;

import 'package:fluent_2/fluent_2.dart';

import 'package:flutter/widgets.dart';

import '../support/golden.dart';

void main() {
  const options = <FluentTagPickerOption<String>>[
    FluentTagPickerOption<String>(value: 'kat', label: Text('Katri')),
    FluentTagPickerOption<String>(value: 'ben', label: Text('Ben')),
  ];

  Widget cell(Widget child) => SizedBox(width: 240, child: child);

  Widget picker({
    FluentTagPickerAppearance appearance = FluentTagPickerAppearance.outline,
    FluentTagPickerSize size = FluentTagPickerSize.medium,
    List<String> selected = const <String>[],
    bool enabled = true,
    Widget? secondaryAction,
  }) => cell(
    FluentTagPicker<String>(
      options: options,
      appearance: appearance,
      size: size,
      selected: selected,
      placeholder: const Text('Select people'),
      secondaryAction: secondaryAction,
      onChanged: enabled ? (_) {} : null,
    ),
  );

  goldenGridTest(
    'tag_picker',
    () => goldenGrid(<Widget>[
      for (final appearance in FluentTagPickerAppearance.values)
        picker(appearance: appearance),
      for (final size in FluentTagPickerSize.values)
        picker(size: size, selected: const <String>['kat', 'ben']),
      picker(enabled: false, selected: const <String>['kat']),
      picker(secondaryAction: const Text('Clear all')),
      picker(
        appearance: FluentTagPickerAppearance.filledDarker,
        size: FluentTagPickerSize.extraLarge,
        selected: const <String>['kat'],
      ),
    ], columns: 4),
    surfaceSize: const Size(1200, 900),
  );
}
