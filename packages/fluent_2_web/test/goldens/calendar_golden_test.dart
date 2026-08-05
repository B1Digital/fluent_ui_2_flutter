import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Every cell pins `today` and `value` to fixed dates.
///
/// No other golden in this package has to: `FluentCalendar`'s `today` defaults
/// to `DateTime.now()`, so an unpinned image would go stale at midnight and
/// again on the first of every month.
void main() {
  final today = DateTime(2026, 3, 10);

  Widget calendar({
    DateTime? value,
    DateTime? minDate,
    DateTime? maxDate,
    List<DateTime> restrictedDates = const <DateTime>[],
    FluentDayOfWeek firstDayOfWeek = FluentDayOfWeek.sunday,
    FluentCalendarView view = FluentCalendarView.month,
    bool enabled = true,
    bool monthPicker = false,
  }) => FluentCalendar(
    isMonthPickerVisible: monthPicker,
    today: today,
    value: value,
    minDate: minDate,
    maxDate: maxDate,
    restrictedDates: restrictedDates,
    firstDayOfWeek: firstDayOfWeek,
    initialView: view,
    onSelectDate: enabled ? (_) {} : null,
  );

  Widget scene() => goldenGrid(<Widget>[
    calendar(),
    calendar(value: DateTime(2026, 3, 17)),
    calendar(
      minDate: DateTime(2026, 3, 5),
      maxDate: DateTime(2026, 3, 24),
      restrictedDates: <DateTime>[DateTime(2026, 3, 12)],
    ),
    calendar(firstDayOfWeek: FluentDayOfWeek.monday),
    calendar(view: FluentCalendarView.year, value: DateTime(2026, 7, 4)),
    calendar(view: FluentCalendarView.decade),
    calendar(enabled: false),
    // Upstream's default layout: day grid and month picker side by side.
    calendar(monthPicker: true, value: DateTime(2026, 3, 17)),
  ], columns: 3);

  goldenGridTest('calendar', scene, surfaceSize: const Size(1400, 1400));
  goldenGridTest(
    'calendar',
    scene,
    surfaceSize: const Size(1400, 1400),
    reducedMotion: true,
    suffix: '.reduced_motion',
  );
}
