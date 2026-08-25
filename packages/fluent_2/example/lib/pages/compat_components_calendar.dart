import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The Calendar docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage calendarPage = DocsPage(
  id: 'compat-components-calendar',
  title: 'Calendar',
  description:
      'The calendar control lets people select and view a single date or a '
      'range of dates in their calendar. It’s made up of 3 separate views: the '
      'month view, year view, and decade view.',
  source: 'lib/pages/compat_components_calendar.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'compat-components-calendar--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'compat-components-calendar--calendar-month-only',
      title: 'Calendar Month Only',
      description:
          'A Calendar Compat allows you to only show the month and year picker '
          'leaving the day picker hidden.',
      builder: _calendarMonthOnly,
    ),
    DocsSection(
      id: 'compat-components-calendar--calendar-overlaid-month',
      title: 'Calendar Overlaid Month',
      description:
          'A Calendar Compat allows you to render the month picker over the day '
          'picker. This is useful when there are width constraints and the '
          'month picker is needed.',
      builder: _calendarOverlaidMonth,
    ),
    DocsSection(
      id: 'compat-components-calendar--calendar-date-boundaries',
      title: 'Calendar Date Boundaries',
      description:
          'A Calendar Compat can be modified to set a minDate and maxDate in '
          'order to restrict the dates that can be selected.',
      builder: _calendarDateBoundaries,
    ),
    DocsSection(
      id: 'compat-components-calendar--calendar-six-weeks',
      title: 'Calendar Six Weeks',
      description: 'A Calendar Compat allows you to set a six week month.',
      builder: _calendarSixWeeks,
    ),
    DocsSection(
      id: 'compat-components-calendar--calendar-week-numbers',
      title: 'Calendar Week Numbers',
      description:
          'A Calendar Compat allows you to show the week numbers next to the '
          'day grid for their respective week.',
      builder: _calendarWeekNumbers,
    ),
    DocsSection(
      id: 'compat-components-calendar--calendar-week-selection',
      title: 'Calendar Week Selection',
      description:
          'A Calendar Compat allows you to set a selection range of weeks '
          'instead of selecting a single day.',
      builder: _calendarWeekSelection,
    ),
    DocsSection(
      id: 'compat-components-calendar--calendar-marked-days',
      title: 'Calendar Marked Days',
      description:
          'A Calendar Compat allows you to pass a callback that returns an '
          'array of number that should bemarked. This callback provides a '
          'starting date and an ending date.',
      builder: _calendarMarkedDays,
    ),
    DocsSection(
      id: 'compat-components-calendar--calendar-month-selection',
      title: 'Calendar Month Selection',
      description:
          'A Calendar Compat allows you to set a selection range of months '
          'instead of selecting a single day.',
      builder: _calendarMonthSelection,
    ),
    DocsSection(
      id: 'compat-components-calendar--calendar-multiday-day-view',
      title: 'Calendar Multiday Day View',
      description:
          'A Calendar Compat allows you to pass a number of days that will be '
          'highlighted from the selected date and forward.',
      builder: _calendarMultidayDayView,
    ),
    DocsSection(
      id: 'compat-components-calendar--calendar-contiguous-work-week-days',
      title: 'Calendar Contiguous Work Week Days',
      description:
          'A Calendar Compat can be modified to allow selecting a contiguous (5 '
          'day) work week.',
      builder: _calendarContiguousWorkWeekDays,
    ),
    DocsSection(
      id: 'compat-components-calendar--calendar-non-contiguous-work-week-days',
      title: 'Calendar Non Contiguous Work Week Days',
      description:
          'A Calendar Compat can be modified to allow selecting a non '
          'contiguous (7 day) week.',
      builder: _calendarNonContiguousWorkWeekDays,
    ),
    DocsSection(
      id: 'compat-components-calendar--calendar-custom-day-cell-ref',
      title: 'Calendar Custom Day Cell Ref',
      description:
          'A Calendar Compat can be modified to allow selecting a non '
          'contiguous (7 day) week.',
      builder: _calendarCustomDayCellRef,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'value',
      type: 'DateTime?',
      defaultValue: 'null',
      description: 'The selected day. Null selects nothing.',
    ),
    PropRow(
      name: 'onSelectDate',
      type: 'ValueChanged<DateTime>?',
      defaultValue: 'null',
      description:
          'Called with local midnight when a day is chosen. Null disables the '
          'calendar.',
    ),
    PropRow(
      name: 'today',
      type: 'DateTime?',
      defaultValue: 'null',
      description: 'What counts as today. Defaults to the clock at mount.',
    ),
    PropRow(
      name: 'minDate',
      type: 'DateTime?',
      defaultValue: 'null',
      description: 'Earliest selectable day, inclusive.',
    ),
    PropRow(
      name: 'maxDate',
      type: 'DateTime?',
      defaultValue: 'null',
      description: 'Latest selectable day, inclusive.',
    ),
    PropRow(
      name: 'restrictedDates',
      type: 'List<DateTime>',
      defaultValue: '[]',
      description:
          'Individual days that cannot be chosen, whatever the bounds say.',
    ),
    PropRow(
      name: 'firstDayOfWeek',
      type: 'FluentDayOfWeek',
      defaultValue: 'FluentDayOfWeek.sunday',
      description: 'Which day the week starts on.',
    ),
    PropRow(
      name: 'initialPickerDate',
      type: 'DateTime?',
      defaultValue: 'null',
      description: 'The page shown at mount. Defaults to value, then to today.',
    ),
    PropRow(
      name: 'onPickerDateChanged',
      type: 'ValueChanged<DateTime>?',
      defaultValue: 'null',
      description:
          'Called with local midnight whenever the displayed page changes.',
    ),
    PropRow(
      name: 'initialView',
      type: 'FluentCalendarView',
      defaultValue: 'FluentCalendarView.month',
      description: 'The view the single panel shows at mount.',
    ),
    PropRow(
      name: 'isDayPickerVisible',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether to show the day grid.',
    ),
    PropRow(
      name: 'isMonthPickerVisible',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether to show the month picker beside the day grid.',
    ),
    PropRow(
      name: 'highlightCurrentMonth',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether the month and decade grids mark the current period.',
    ),
    PropRow(
      name: 'highlightSelectedMonth',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether the month and decade grids mark the selected period.',
    ),
    PropRow(
      name: 'showGoToToday',
      type: 'bool',
      defaultValue: 'true',
      description: 'Whether to offer the "go to today" link.',
    ),
    PropRow(
      name: 'showMonthPickerAsOverlay',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether the month picker is reached through the day caption rather '
          'than shown in a second column.',
    ),
    PropRow(
      name: 'showWeekNumbers',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether the day grid draws a week-number column down its leading '
          'edge.',
    ),
    PropRow(
      name: 'firstWeekOfYear',
      type: 'FluentFirstWeekOfYear',
      defaultValue: 'FluentFirstWeekOfYear.firstDay',
      description: 'Which week counts as week 1, when showWeekNumbers is set.',
    ),
    PropRow(
      name: 'allFocusable',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether unselectable days still take keyboard focus.',
    ),
    PropRow(
      name: 'onDismiss',
      type: 'VoidCallback?',
      defaultValue: 'null',
      description: 'Called when the close button is pressed.',
    ),
    PropRow(
      name: 'showCloseButton',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the header offers a close button.',
    ),
    PropRow(
      name: 'strings',
      type: 'FluentCalendarStrings',
      defaultValue: 'FluentCalendarStrings.english',
      description: 'Every label that is not a number.',
    ),
    PropRow(
      name: 'formatter',
      type: 'FluentCalendarDateFormatter',
      defaultValue: 'FluentCalendarDateFormatter()',
      description: 'How dates are rendered.',
    ),
    PropRow(
      name: 'semanticLabel',
      type: 'String?',
      defaultValue: 'null',
      description: 'Accessible name of the calendar as a whole.',
    ),
  ],
);

// #docregion compat-components-calendar--default
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) => FluentCalendar(
    value: _selectedDate,
    onSelectDate: (DateTime date) => setState(() => _selectedDate = date),
  );
}
// #enddocregion compat-components-calendar--default

// #docregion compat-components-calendar--calendar-month-only
Widget _calendarMonthOnly(BuildContext context) => const _CalendarMonthOnly();

class _CalendarMonthOnly extends StatefulWidget {
  const _CalendarMonthOnly();

  @override
  State<_CalendarMonthOnly> createState() => _CalendarMonthOnlyState();
}

class _CalendarMonthOnlyState extends State<_CalendarMonthOnly> {
  DateTime? _selectedDate;
  List<DateTime>? _selectedDateRange;

  /// `toDateString()` has no Dart counterpart; the package's own formatter
  /// renders the month-day-year order the Best practices section asks for.
  static String _dateString(DateTime date) =>
      fluentFormatCalendarMonthDayYear(date, FluentCalendarStrings.english);

  void _onSelectDate(DateTime date) => setState(() {
    _selectedDate = date;
    _selectedDateRange = <DateTime>[
      DateTime(date.year, date.month, 1),
      DateTime(date.year, date.month + 1, 0),
    ];
  });

  @override
  Widget build(BuildContext context) {
    final List<DateTime>? selectedDateRange = _selectedDateRange;
    String dateRangeString = 'Not set';
    if (selectedDateRange != null) {
      final DateTime rangeStart = selectedDateRange.first;
      final DateTime rangeEnd = selectedDateRange.last;
      dateRangeString = '${_dateString(rangeStart)}-${_dateString(rangeEnd)}';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        Text(
          'Selected date: '
          '${_selectedDate == null ? 'Not set' : _dateString(_selectedDate!)}',
        ),
        Text('Selected range: $dateRangeString'),
        // Upstream pairs `isDayPickerVisible={false}` with
        // `dateRangeType={DateRangeType.Month}`, so activating a month cell
        // selects that whole month. FluentCalendar has no `dateRangeType`, and
        // with the day grid hidden its month cells navigate rather than select,
        // so the range above is derived from the selected day instead.
        FluentCalendar(
          showGoToToday: true,
          highlightSelectedMonth: true,
          isDayPickerVisible: false,
          onSelectDate: _onSelectDate,
          value: _selectedDate,
        ),
      ],
    );
  }
}
// #enddocregion compat-components-calendar--calendar-month-only

// #docregion compat-components-calendar--calendar-overlaid-month
Widget _calendarOverlaidMonth(BuildContext context) =>
    const _CalendarOverlaidMonth();

class _CalendarOverlaidMonth extends StatefulWidget {
  const _CalendarOverlaidMonth();

  @override
  State<_CalendarOverlaidMonth> createState() => _CalendarOverlaidMonthState();
}

class _CalendarOverlaidMonthState extends State<_CalendarOverlaidMonth> {
  DateTime? _selectedDate;

  static String _dateString(DateTime date) =>
      fluentFormatCalendarMonthDayYear(date, FluentCalendarStrings.english);

  void _onSelectDate(DateTime date) => setState(() => _selectedDate = date);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: <Widget>[
      Text(
        'Selected date: '
        '${_selectedDate == null ? 'Not set' : _dateString(_selectedDate!)}',
      ),
      FluentCalendar(
        showMonthPickerAsOverlay: true,
        highlightSelectedMonth: true,
        showGoToToday: false,
        onSelectDate: _onSelectDate,
        value: _selectedDate,
      ),
    ],
  );
}
// #enddocregion compat-components-calendar--calendar-overlaid-month

// #docregion compat-components-calendar--calendar-date-boundaries
Widget _calendarDateBoundaries(BuildContext context) =>
    const _CalendarDateBoundaries();

class _CalendarDateBoundaries extends StatefulWidget {
  const _CalendarDateBoundaries();

  @override
  State<_CalendarDateBoundaries> createState() =>
      _CalendarDateBoundariesState();
}

class _CalendarDateBoundariesState extends State<_CalendarDateBoundaries> {
  // `addMonths`, `addYears` and `addDays` are upstream helpers; the DateTime
  // constructor normalises out-of-range fields on its own, so day arithmetic
  // goes through it rather than through Duration, which drifts across a
  // daylight-saving boundary.
  final DateTime _today = DateTime.now();
  late final DateTime _minDate = DateTime(
    _today.year,
    _today.month - 1,
    _today.day,
  );
  late final DateTime _maxDate = DateTime(
    _today.year + 1,
    _today.month,
    _today.day,
  );
  late final List<DateTime> _restrictedDates = <DateTime>[
    DateTime(_today.year, _today.month, _today.day - 2),
    DateTime(_today.year, _today.month, _today.day - 8),
    DateTime(_today.year, _today.month, _today.day + 2),
    DateTime(_today.year, _today.month, _today.day + 8),
  ];

  DateTime? _selectedDate;

  static String _dateString(DateTime date) =>
      fluentFormatCalendarMonthDayYear(date, FluentCalendarStrings.english);

  void _onSelectDate(DateTime date) => setState(() => _selectedDate = date);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: <Widget>[
      Text(
        'Selected date: '
        '${_selectedDate == null ? 'Not set' : _dateString(_selectedDate!)}',
      ),
      Text('Date boundary: ${_dateString(_minDate)}-${_dateString(_maxDate)}'),
      Text('Disabled dates: ${_restrictedDates.map(_dateString).join(', ')}'),
      FluentCalendar(
        highlightSelectedMonth: true,
        showGoToToday: false,
        minDate: _minDate,
        maxDate: _maxDate,
        restrictedDates: _restrictedDates,
        onSelectDate: _onSelectDate,
        value: _selectedDate,
      ),
    ],
  );
}
// #enddocregion compat-components-calendar--calendar-date-boundaries

// #docregion compat-components-calendar--calendar-six-weeks
Widget _calendarSixWeeks(BuildContext context) => const _CalendarSixWeeks();

class _CalendarSixWeeks extends StatefulWidget {
  const _CalendarSixWeeks();

  @override
  State<_CalendarSixWeeks> createState() => _CalendarSixWeeksState();
}

class _CalendarSixWeeksState extends State<_CalendarSixWeeks> {
  DateTime? _selectedDate;

  static String _dateString(DateTime date) =>
      fluentFormatCalendarMonthDayYear(date, FluentCalendarStrings.english);

  void _onSelectDate(DateTime date) => setState(() => _selectedDate = date);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: <Widget>[
      Text(
        'Selected date: '
        '${_selectedDate == null ? 'Not set' : _dateString(_selectedDate!)}',
      ),
      // FluentCalendar has no `showSixWeeksByDefault`: its day grid is four,
      // five or six rows, whichever the month actually needs, so a month that
      // fits in five never pads out to six.
      FluentCalendar(
        showGoToToday: true,
        onSelectDate: _onSelectDate,
        value: _selectedDate,
      ),
    ],
  );
}
// #enddocregion compat-components-calendar--calendar-six-weeks

// #docregion compat-components-calendar--calendar-week-numbers
Widget _calendarWeekNumbers(BuildContext context) =>
    const _CalendarWeekNumbers();

class _CalendarWeekNumbers extends StatefulWidget {
  const _CalendarWeekNumbers();

  @override
  State<_CalendarWeekNumbers> createState() => _CalendarWeekNumbersState();
}

class _CalendarWeekNumbersState extends State<_CalendarWeekNumbers> {
  DateTime? _selectedDate;

  static String _dateString(DateTime date) =>
      fluentFormatCalendarMonthDayYear(date, FluentCalendarStrings.english);

  void _onSelectDate(DateTime date) => setState(() => _selectedDate = date);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: <Widget>[
      Text(
        'Selected date: '
        '${_selectedDate == null ? 'Not set' : _dateString(_selectedDate!)}',
      ),
      FluentCalendar(
        showWeekNumbers: true,
        showGoToToday: true,
        onSelectDate: _onSelectDate,
        value: _selectedDate,
      ),
    ],
  );
}
// #enddocregion compat-components-calendar--calendar-week-numbers

// #docregion compat-components-calendar--calendar-week-selection
Widget _calendarWeekSelection(BuildContext context) =>
    const _CalendarWeekSelection();

class _CalendarWeekSelection extends StatefulWidget {
  const _CalendarWeekSelection();

  @override
  State<_CalendarWeekSelection> createState() => _CalendarWeekSelectionState();
}

class _CalendarWeekSelectionState extends State<_CalendarWeekSelection> {
  static const FluentDayOfWeek firstDayOfWeek = FluentDayOfWeek.sunday;

  DateTime? _selectedDate;
  List<DateTime>? _selectedDateRange;

  static String _dateString(DateTime date) =>
      fluentFormatCalendarMonthDayYear(date, FluentCalendarStrings.english);

  /// Upstream's `getDateRangeArray(date, DateRangeType.Week, firstDayOfWeek)`.
  static List<DateTime> _getDateRangeArray(DateTime date) {
    // Dart counts Monday 1 through Sunday 7; FluentDayOfWeek counts Sunday 0.
    final int offset = (date.weekday % 7 - firstDayOfWeek.index) % 7;
    return <DateTime>[
      for (int i = 0; i < 7; i++)
        DateTime(date.year, date.month, date.day - offset + i),
    ];
  }

  void _onSelectDate(DateTime date) => setState(() {
    _selectedDate = date;
    _selectedDateRange = _getDateRangeArray(date);
  });

  void _goPrevious() {
    final DateTime prevSelectedDate = _selectedDate ?? DateTime.now();
    final List<DateTime> dateRangeArray = _getDateRangeArray(prevSelectedDate);
    final DateTime subtractFrom = DateTime(
      dateRangeArray[0].year,
      dateRangeArray[0].month,
      1,
    );
    const int daysToSubtract = 1;
    _onSelectDate(
      DateTime(
        subtractFrom.year,
        subtractFrom.month,
        subtractFrom.day - daysToSubtract,
      ),
    );
  }

  void _goNext() {
    final DateTime prevSelectedDate = _selectedDate ?? DateTime.now();
    final DateTime last = _getDateRangeArray(prevSelectedDate).last;
    _onSelectDate(DateTime(last.year, last.month, last.day + 1));
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime>? selectedDateRange = _selectedDateRange;
    String dateRangeString = 'Not set';
    if (selectedDateRange != null) {
      final DateTime rangeStart = selectedDateRange.first;
      final DateTime rangeEnd = selectedDateRange.last;
      dateRangeString = '${_dateString(rangeStart)}-${_dateString(rangeEnd)}';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        Text(
          'Selected date: '
          '${_selectedDate == null ? 'Not set' : _dateString(_selectedDate!)}',
        ),
        Text('Selected range: $dateRangeString'),
        // Upstream's `dateRangeType={DateRangeType.Week}` paints the whole week
        // as one selection. FluentCalendar selects a single day, so the week is
        // derived here for the readout and only its anchor day is highlighted.
        FluentCalendar(
          highlightSelectedMonth: true,
          showGoToToday: true,
          onSelectDate: _onSelectDate,
          value: _selectedDate,
          firstDayOfWeek: firstDayOfWeek,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: <Widget>[
            FluentButton(onPressed: _goPrevious, child: const Text('Previous')),
            FluentButton(onPressed: _goNext, child: const Text('Next')),
          ],
        ),
      ],
    );
  }
}
// #enddocregion compat-components-calendar--calendar-week-selection

// #docregion compat-components-calendar--calendar-marked-days
Widget _calendarMarkedDays(BuildContext context) => const _CalendarMarkedDays();

class _CalendarMarkedDays extends StatefulWidget {
  const _CalendarMarkedDays();

  @override
  State<_CalendarMarkedDays> createState() => _CalendarMarkedDaysState();
}

class _CalendarMarkedDaysState extends State<_CalendarMarkedDays> {
  DateTime? _selectedDate = DateTime.now();

  static String _dateString(DateTime date) =>
      fluentFormatCalendarMonthDayYear(date, FluentCalendarStrings.english);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: <Widget>[
      Text(
        'Selected date: '
        '${_selectedDate == null ? 'Not set' : _dateString(_selectedDate!)}',
      ),
      // Upstream marks two days per page through
      // `calendarDayProps.getMarkedDays`. FluentCalendar's day cell has no
      // marker slot and no `calendarDayProps`, so the calendar renders without
      // the dots rather than faking them with a disabled or selected day, which
      // would mean something else entirely.
      FluentCalendar(
        showGoToToday: true,
        onSelectDate: (DateTime date) => setState(() => _selectedDate = date),
        value: _selectedDate,
      ),
    ],
  );
}
// #enddocregion compat-components-calendar--calendar-marked-days

// #docregion compat-components-calendar--calendar-month-selection
Widget _calendarMonthSelection(BuildContext context) =>
    const _CalendarMonthSelection();

class _CalendarMonthSelection extends StatefulWidget {
  const _CalendarMonthSelection();

  @override
  State<_CalendarMonthSelection> createState() =>
      _CalendarMonthSelectionState();
}

class _CalendarMonthSelectionState extends State<_CalendarMonthSelection> {
  static const FluentDayOfWeek firstDayOfWeek = FluentDayOfWeek.sunday;

  DateTime? _selectedDate;
  List<DateTime>? _selectedDateRange;

  static String _dateString(DateTime date) =>
      fluentFormatCalendarMonthDayYear(date, FluentCalendarStrings.english);

  /// Upstream's `getDateRangeArray(date, DateRangeType.Month, firstDayOfWeek)`,
  /// reduced to the two ends the story reads. Day zero of the next month is the
  /// last day of this one.
  static List<DateTime> _getDateRangeArray(DateTime date) => <DateTime>[
    DateTime(date.year, date.month, 1),
    DateTime(date.year, date.month + 1, 0),
  ];

  void _onSelectDate(DateTime date) => setState(() {
    _selectedDate = date;
    _selectedDateRange = _getDateRangeArray(date);
  });

  void _goPrevious() {
    final DateTime prevSelectedDate = _selectedDate ?? DateTime.now();
    final List<DateTime> dateRangeArray = _getDateRangeArray(prevSelectedDate);
    final DateTime subtractFrom = DateTime(
      dateRangeArray[0].year,
      dateRangeArray[0].month,
      1,
    );
    const int daysToSubtract = 1;
    _onSelectDate(
      DateTime(
        subtractFrom.year,
        subtractFrom.month,
        subtractFrom.day - daysToSubtract,
      ),
    );
  }

  void _goNext() {
    final DateTime prevSelectedDate = _selectedDate ?? DateTime.now();
    final DateTime last = _getDateRangeArray(prevSelectedDate).last;
    _onSelectDate(DateTime(last.year, last.month, last.day + 1));
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime>? selectedDateRange = _selectedDateRange;
    String dateRangeString = 'Not set';
    if (selectedDateRange != null) {
      final DateTime rangeStart = selectedDateRange.first;
      final DateTime rangeEnd = selectedDateRange.last;
      dateRangeString = '${_dateString(rangeStart)}-${_dateString(rangeEnd)}';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        Text(
          'Selected date: '
          '${_selectedDate == null ? 'Not set' : _dateString(_selectedDate!)}',
        ),
        Text('Selected range: $dateRangeString'),
        // `dateRangeType={DateRangeType.Month}` upstream paints the whole month
        // as one selection. FluentCalendar selects a single day, so the month is
        // derived here for the readout and `highlightSelectedMonth` marks the
        // month cell in the picker beside the grid.
        FluentCalendar(
          highlightSelectedMonth: true,
          showGoToToday: true,
          onSelectDate: _onSelectDate,
          value: _selectedDate,
          firstDayOfWeek: firstDayOfWeek,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: <Widget>[
            FluentButton(onPressed: _goPrevious, child: const Text('Previous')),
            FluentButton(onPressed: _goNext, child: const Text('Next')),
          ],
        ),
      ],
    );
  }
}
// #enddocregion compat-components-calendar--calendar-month-selection

// #docregion compat-components-calendar--calendar-multiday-day-view
Widget _calendarMultidayDayView(BuildContext context) =>
    const _CalendarMultidayDayView();

class _CalendarMultidayDayView extends StatefulWidget {
  const _CalendarMultidayDayView();

  @override
  State<_CalendarMultidayDayView> createState() =>
      _CalendarMultidayDayViewState();
}

class _CalendarMultidayDayViewState extends State<_CalendarMultidayDayView> {
  static const List<String> dayOptions = <String>['1', '2', '3', '4', '5', '6'];

  DateTime? _selectedDate;
  List<DateTime>? _selectedDateRange;
  int _daysToSelectInDayView = 4;

  /// Which of the two calendars made the standing pick, so that turning the
  /// knob re-counts the run the same way round rather than flipping it.
  bool _countBackwards = false;

  static String _dateString(DateTime date) =>
      fluentFormatCalendarMonthDayYear(date, FluentCalendarStrings.english);

  /// The run of days a positive or negative `daysToSelectInDayView` covers.
  static List<DateTime> _range(DateTime date, int days) => days >= 0
      ? <DateTime>[date, DateTime(date.year, date.month, date.day + days - 1)]
      : <DateTime>[DateTime(date.year, date.month, date.day + days + 1), date];

  void _onSelectDate(DateTime date, int days) => setState(() {
    _selectedDate = date;
    _countBackwards = days < 0;
    _selectedDateRange = _range(date, days);
  });

  void _onOptionSelect(String value) => setState(() {
    _daysToSelectInDayView = int.parse(value);
    // The knob's whole job is the length of the run, so the readout has to
    // follow it straight away; leaving it on the old length until the user
    // happens to pick another day makes the dropdown look inert.
    final DateTime? selectedDate = _selectedDate;
    if (selectedDate == null) return;
    _selectedDateRange = _range(
      selectedDate,
      _countBackwards ? -_daysToSelectInDayView : _daysToSelectInDayView,
    );
  });

  @override
  Widget build(BuildContext context) {
    final List<DateTime>? selectedDateRange = _selectedDateRange;
    String dateRangeString = 'Not set';
    if (selectedDateRange != null) {
      final DateTime rangeStart = selectedDateRange.first;
      final DateTime rangeEnd = selectedDateRange.last;
      dateRangeString = '${_dateString(rangeStart)}-${_dateString(rangeEnd)}';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        const Text(
          'This calendar uses dateRangeType = Day and '
          'daysToSelectInView = 4.',
        ),
        Text(
          'Selected date: '
          '${_selectedDate == null ? 'Not set' : _dateString(_selectedDate!)}',
        ),
        Text('Selected range: $dateRangeString'),
        // FluentCalendar has no `calendarDayProps.daysToSelectInDayView`, so the
        // run of days is computed here for the readout and the grid highlights
        // only the day that anchors it.
        FluentCalendar(
          highlightSelectedMonth: true,
          showGoToToday: true,
          onSelectDate: (DateTime date) =>
              _onSelectDate(date, _daysToSelectInDayView),
          value: _selectedDate,
        ),
        FluentField(
          label: const Text('Choose days to select'),
          child: SizedBox(
            width: 230,
            child: FluentDropdown<String>(
              value: '$_daysToSelectInDayView',
              onChanged: _onOptionSelect,
              options: <FluentDropdownOption<String>>[
                for (final String option in dayOptions)
                  FluentDropdownOption<String>(
                    value: option,
                    label: Text(option),
                  ),
              ],
            ),
          ),
        ),
        Text(
          'Selection with negative date range',
          style: FluentTheme.of(context).typography.subtitle2,
        ),
        FluentCalendar(
          highlightSelectedMonth: true,
          showGoToToday: true,
          onSelectDate: (DateTime date) =>
              _onSelectDate(date, -_daysToSelectInDayView),
          value: _selectedDate,
        ),
      ],
    );
  }
}
// #enddocregion compat-components-calendar--calendar-multiday-day-view

// #docregion compat-components-calendar--calendar-contiguous-work-week-days
Widget _calendarContiguousWorkWeekDays(BuildContext context) =>
    const _CalendarContiguousWorkWeekDays();

class _CalendarContiguousWorkWeekDays extends StatefulWidget {
  const _CalendarContiguousWorkWeekDays();

  @override
  State<_CalendarContiguousWorkWeekDays> createState() =>
      _CalendarContiguousWorkWeekDaysState();
}

class _CalendarContiguousWorkWeekDaysState
    extends State<_CalendarContiguousWorkWeekDays> {
  static const List<FluentDayOfWeek> workWeekDays = <FluentDayOfWeek>[
    FluentDayOfWeek.monday,
    FluentDayOfWeek.tuesday,
    FluentDayOfWeek.wednesday,
    FluentDayOfWeek.thursday,
    FluentDayOfWeek.friday,
  ];
  static const FluentDayOfWeek firstDayOfWeek = FluentDayOfWeek.sunday;

  DateTime? _selectedDate;
  List<DateTime>? _selectedDateRange;

  static String _dateString(DateTime date) =>
      fluentFormatCalendarMonthDayYear(date, FluentCalendarStrings.english);

  /// Upstream's `DateRangeType.WorkWeek` range: the days of [date]'s week that
  /// [workWeekDays] names, in grid order.
  static List<DateTime> _getDateRangeArray(DateTime date) {
    // Dart counts Monday 1 through Sunday 7; FluentDayOfWeek counts Sunday 0.
    final int offset = (date.weekday % 7 - firstDayOfWeek.index) % 7;
    return <DateTime>[
      for (int i = 0; i < 7; i++)
        if (workWeekDays.any(
          (FluentDayOfWeek day) => day.index == (firstDayOfWeek.index + i) % 7,
        ))
          DateTime(date.year, date.month, date.day - offset + i),
    ];
  }

  void _onSelectDate(DateTime date) => setState(() {
    _selectedDate = date;
    _selectedDateRange = _getDateRangeArray(date);
  });

  @override
  Widget build(BuildContext context) {
    final List<DateTime>? selectedDateRange = _selectedDateRange;
    String dateRangeString = 'Not set';
    if (selectedDateRange != null) {
      final DateTime rangeStart = selectedDateRange.first;
      final DateTime rangeEnd = selectedDateRange.last;
      dateRangeString = '${_dateString(rangeStart)}-${_dateString(rangeEnd)}';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        Text(
          'Selected date: '
          '${_selectedDate == null ? 'Not set' : _dateString(_selectedDate!)}',
        ),
        Text('Selected range: $dateRangeString'),
        // FluentCalendar has neither `dateRangeType` nor `workWeekDays`, so the
        // work week is computed here for the readout while the grid highlights
        // the single day that anchors it.
        FluentCalendar(
          highlightSelectedMonth: true,
          showGoToToday: true,
          onSelectDate: _onSelectDate,
          value: _selectedDate,
        ),
      ],
    );
  }
}
// #enddocregion compat-components-calendar--calendar-contiguous-work-week-days

// #docregion compat-components-calendar--calendar-non-contiguous-work-week-days
Widget _calendarNonContiguousWorkWeekDays(BuildContext context) =>
    const _CalendarNonContiguousWorkWeekDays();

class _CalendarNonContiguousWorkWeekDays extends StatefulWidget {
  const _CalendarNonContiguousWorkWeekDays();

  @override
  State<_CalendarNonContiguousWorkWeekDays> createState() =>
      _CalendarNonContiguousWorkWeekDaysState();
}

class _CalendarNonContiguousWorkWeekDaysState
    extends State<_CalendarNonContiguousWorkWeekDays> {
  static const List<FluentDayOfWeek> workWeekDays = <FluentDayOfWeek>[
    FluentDayOfWeek.tuesday,
    FluentDayOfWeek.saturday,
    FluentDayOfWeek.wednesday,
    FluentDayOfWeek.friday,
  ];
  static const FluentDayOfWeek firstDayOfWeek = FluentDayOfWeek.monday;

  DateTime? _selectedDate;
  List<DateTime>? _selectedDateRange;

  static String _dateString(DateTime date) =>
      fluentFormatCalendarMonthDayYear(date, FluentCalendarStrings.english);

  /// Upstream's `DateRangeType.WorkWeek` range: the days of [date]'s week that
  /// [workWeekDays] names, in grid order. Non-contiguous, so the first and last
  /// entries bound days that are not all in the range.
  static List<DateTime> _getDateRangeArray(DateTime date) {
    // Dart counts Monday 1 through Sunday 7; FluentDayOfWeek counts Sunday 0.
    final int offset = (date.weekday % 7 - firstDayOfWeek.index) % 7;
    return <DateTime>[
      for (int i = 0; i < 7; i++)
        if (workWeekDays.any(
          (FluentDayOfWeek day) => day.index == (firstDayOfWeek.index + i) % 7,
        ))
          DateTime(date.year, date.month, date.day - offset + i),
    ];
  }

  void _onSelectDate(DateTime date) => setState(() {
    _selectedDate = date;
    _selectedDateRange = _getDateRangeArray(date);
  });

  @override
  Widget build(BuildContext context) {
    final List<DateTime>? selectedDateRange = _selectedDateRange;
    String dateRangeString = 'Not set';
    if (selectedDateRange != null) {
      final DateTime rangeStart = selectedDateRange.first;
      final DateTime rangeEnd = selectedDateRange.last;
      dateRangeString = '${_dateString(rangeStart)}-${_dateString(rangeEnd)}';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: <Widget>[
        Text(
          'Selected date: '
          '${_selectedDate == null ? 'Not set' : _dateString(_selectedDate!)}',
        ),
        Text('Selected range: $dateRangeString'),
        // `firstDayOfWeek` is ours; `dateRangeType` and `workWeekDays` are not,
        // so the four scattered work days are computed here for the readout.
        FluentCalendar(
          firstDayOfWeek: firstDayOfWeek,
          highlightSelectedMonth: true,
          showGoToToday: true,
          onSelectDate: _onSelectDate,
          value: _selectedDate,
        ),
      ],
    );
  }
}
// #enddocregion compat-components-calendar--calendar-non-contiguous-work-week-days

// #docregion compat-components-calendar--calendar-custom-day-cell-ref
Widget _calendarCustomDayCellRef(BuildContext context) =>
    const _CalendarCustomDayCellRef();

class _CalendarCustomDayCellRef extends StatefulWidget {
  const _CalendarCustomDayCellRef();

  @override
  State<_CalendarCustomDayCellRef> createState() =>
      _CalendarCustomDayCellRefState();
}

class _CalendarCustomDayCellRefState extends State<_CalendarCustomDayCellRef> {
  final DateTime _today = DateTime.now();
  late final List<DateTime> _weekends = _weekendsAround(_today);

  DateTime? _selectedDate;

  static String _dateString(DateTime date) =>
      fluentFormatCalendarMonthDayYear(date, FluentCalendarStrings.english);

  /// Every Saturday and Sunday within half a year of [today], which is the
  /// window a reader can page to before the calendar runs out of restrictions.
  static List<DateTime> _weekendsAround(DateTime today) {
    final List<DateTime> days = <DateTime>[];
    for (int i = -180; i <= 180; i++) {
      final DateTime day = DateTime(today.year, today.month, today.day + i);
      if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
        days.add(day);
      }
    }
    return days;
  }

  void _onSelectDate(DateTime date) => setState(() => _selectedDate = date);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 8,
    children: <Widget>[
      Text(
        'Selected date: '
        '${_selectedDate == null ? 'Not set' : _dateString(_selectedDate!)}',
      ),
      // Upstream's `customDayCellRef` reaches into each day cell's DOM node to
      // set a `title` and disable the two weekend buttons. There is no per-cell
      // escape hatch here, so the weekends go through `restrictedDates` and the
      // title becomes a tooltip on the calendar itself.
      FluentTooltip(
        content: Text(
          'custom title from customDayCellRef: ${_selectedDate ?? _today}',
        ),
        child: FluentCalendar(
          highlightSelectedMonth: true,
          showGoToToday: true,
          restrictedDates: _weekends,
          onSelectDate: _onSelectDate,
          value: _selectedDate,
        ),
      ),
    ],
  );
}

// #enddocregion compat-components-calendar--calendar-custom-day-cell-ref
