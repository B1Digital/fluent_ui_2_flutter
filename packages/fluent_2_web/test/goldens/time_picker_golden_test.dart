import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// The faceplate grid is `Appearance` x `Size`; the listbox is captured
/// separately because an open picker lives in the [Overlay], which sits above
/// the RepaintBoundary these images are cropped to. Rendering the surface
/// through its own builder captures the same pixels without an overlay.
void main() {
  final anchor = DateTime(2026, 3, 10);

  Widget picker(
    FluentTimePickerAppearance appearance,
    FluentTimePickerSize size, {
    DateTime? selectedTime,
    bool enabled = true,
    bool error = false,
    bool clearable = false,
  }) => SizedBox(
    width: 220,
    child: FluentTimePicker(
      appearance: appearance,
      size: size,
      dateAnchor: anchor,
      selectedTime: selectedTime,
      error: error,
      clearable: clearable,
      hourCycle: FluentHourCycle.h23,
      placeholder: const Text('Select a time'),
      onTimeChange: enabled ? (_) {} : null,
    ),
  );

  goldenGridTest(
    'time_picker',
    () => goldenGrid(<Widget>[
      for (final appearance in FluentTimePickerAppearance.values)
        for (final size in FluentTimePickerSize.values)
          picker(appearance, size),
      picker(
        FluentTimePickerAppearance.outline,
        FluentTimePickerSize.medium,
        selectedTime: DateTime(2026, 3, 10, 9, 30),
      ),
      picker(
        FluentTimePickerAppearance.outline,
        FluentTimePickerSize.medium,
        selectedTime: DateTime(2026, 3, 10, 9, 30),
        clearable: true,
      ),
      picker(
        FluentTimePickerAppearance.outline,
        FluentTimePickerSize.medium,
        error: true,
      ),
      picker(
        FluentTimePickerAppearance.outline,
        FluentTimePickerSize.medium,
        enabled: false,
      ),
    ], columns: 3),
    surfaceSize: const Size(1200, 900),
  );

  goldenGridTest('time_picker', suffix: '.list', () {
    return Builder(
      builder: (context) {
        final theme = FluentTheme.of(context);
        final controller = TextEditingController();
        final style = resolveFluentTimePickerStyle(
          resolveFluentTimePickerState(
            controller: controller,
            focusNode: FocusNode(),
            editableTextKey: GlobalKey<EditableTextState>(),
          ),
          theme,
        );
        final optionState = resolveFluentDropdownOptionState(
          label: const Text('09:00'),
        );
        final optionStyle = resolveFluentDropdownOptionStyle(
          optionState,
          theme,
        );
        return SizedBox(
          width: 220,
          child: buildFluentTimePickerSurface(
            style,
            const <WidgetState>{},
            Column(
              mainAxisSize: MainAxisSize.min,
              spacing: FluentSpacing.xxs,
              children: <Widget>[
                for (final states in <Set<WidgetState>>[
                  <WidgetState>{},
                  <WidgetState>{WidgetState.hovered},
                  <WidgetState>{WidgetState.pressed},
                  <WidgetState>{WidgetState.focused},
                ])
                  buildFluentDropdownOption(optionState, optionStyle, states),
              ],
            ),
          ),
        );
      },
    );
  }, surfaceSize: const Size(600, 600));
}
