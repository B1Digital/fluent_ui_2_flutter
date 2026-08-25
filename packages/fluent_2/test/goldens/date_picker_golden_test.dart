import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// The faceplate grid is `Appearance` x `Size`; the calendar popup is captured
/// separately because it lives in the [Overlay], which sits above the
/// RepaintBoundary these images are cropped to.
///
/// Every date is pinned — see `calendar_golden_test.dart` for why.
void main() {
  final today = DateTime(2026, 3, 10);

  Widget picker(
    FluentDatePickerAppearance appearance,
    FluentDatePickerSize size, {
    DateTime? value,
    bool enabled = true,
    bool error = false,
    bool borderless = false,
  }) => SizedBox(
    width: 240,
    child: FluentDatePicker(
      appearance: appearance,
      size: size,
      today: today,
      value: value,
      error: error,
      borderless: borderless,
      placeholder: const Text('Select a date'),
      onSelectDate: enabled ? (_) {} : null,
    ),
  );

  goldenGridTest(
    'date_picker',
    () => goldenGrid(<Widget>[
      for (final appearance in FluentDatePickerAppearance.values)
        for (final size in FluentDatePickerSize.values)
          picker(appearance, size),
      picker(
        FluentDatePickerAppearance.outline,
        FluentDatePickerSize.medium,
        value: DateTime(2026, 3, 17),
      ),
      picker(
        FluentDatePickerAppearance.outline,
        FluentDatePickerSize.medium,
        error: true,
      ),
      picker(
        FluentDatePickerAppearance.outline,
        FluentDatePickerSize.medium,
        borderless: true,
      ),
      picker(
        FluentDatePickerAppearance.outline,
        FluentDatePickerSize.medium,
        enabled: false,
      ),
    ], columns: 3),
    surfaceSize: const Size(1200, 900),
  );

  goldenGridTest('date_picker', suffix: '.popup', () {
    return Builder(
      builder: (context) {
        final controller = TextEditingController();
        final style = resolveFluentDatePickerStyle(
          resolveFluentDatePickerState(
            controller: controller,
            focusNode: FocusNode(),
            editableTextKey: GlobalKey<EditableTextState>(),
          ),
          FluentTheme.of(context),
        );
        return buildFluentDatePickerSurface(
          style,
          const <WidgetState>{},
          FluentCalendar(
            today: today,
            value: DateTime(2026, 3, 17),
            onSelectDate: (_) {},
          ),
        );
      },
    );
  }, surfaceSize: const Size(600, 700));
}
