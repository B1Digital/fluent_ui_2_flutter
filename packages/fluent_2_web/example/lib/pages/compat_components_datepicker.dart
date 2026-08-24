import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The DatePicker docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage datePickerPage = DocsPage(
  id: 'compat-components-datepicker',
  title: 'DatePicker',
  description:
      'Picking a date can be tough without context. A date picker (DatePicker) '
      'offers a popup control that’s optimized for picking a single date from '
      'a calendar view where contextual information like the day of the week '
      'or fullness of the calendar is important. You can modify the calendar '
      'to provide additional context or to limit available dates. Note: '
      'DatePicker is a compat component - its internal architecture does not '
      'follow all the principles regular Fluent UI v9 components follow - it '
      'is not composed of atomic hooks and it might be more difficult to tweak '
      'its appearance and behavior. It however follows Fluent 2 design and '
      'uses design tokens, it is production ready and it is stable.',
  source: 'lib/pages/compat_components_datepicker.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'compat-components-datepicker--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'compat-components-datepicker--text-input',
      title: 'Text Input',
      description:
          'A DatePicker supports user input. Clicking the input field will '
          'open the DatePicker, and clicking the field again will dismiss the '
          'DatePicker and allow text input. When using keyboard navigation '
          '(tabbing into the field), text input is allowed by default, and '
          'pressing Enter will open the DatePicker.',
      builder: _textInput,
    ),
    DocsSection(
      id: 'compat-components-datepicker--first-day-of-the-week',
      title: 'First Day Of The Week',
      description: 'A DatePicker allows you to set the first day of the week.',
      builder: _firstDayOfTheWeek,
    ),
    DocsSection(
      id: 'compat-components-datepicker--week-numbers',
      title: 'Week Numbers',
      description:
          'A DatePicker allows you to show the number of the week on the left '
          'when showWeekNumbers is set to true.',
      builder: _weekNumbers,
    ),
    DocsSection(
      id: 'compat-components-datepicker--date-range',
      title: 'Date Range',
      description:
          'DatePicker allows you to set the selection range type. The range '
          'can be Day, Month, Week, and WorkWeek. The default is Day.',
      builder: _dateRange,
    ),
    DocsSection(
      id: 'compat-components-datepicker--date-boundaries',
      title: 'Date Boundaries',
      description:
          'A DatePicker allows setting date boundaries. To set a max boundary, '
          'use the maxDate prop. To set a minimum boundary, use the minDate '
          'prop. When date boundaries are set the DatePicker will not allow '
          'out-of-bounds dates to be picked or entered.',
      builder: _dateBoundaries,
    ),
    DocsSection(
      id: 'compat-components-datepicker--custom-date-formatting',
      title: 'Custom Date Formatting',
      description:
          'Applications can customize how dates are formatted and parsed. '
          'Formatted dates can be ambiguous, so the control will avoid parsing '
          'the formatted strings of dates selected using the UI when text '
          'input is allowed. In this example, we are formatting and parsing '
          'dates as dd/MM/yy.',
      builder: _customDateFormatting,
    ),
    DocsSection(
      id: 'compat-components-datepicker--localized',
      title: 'Localized',
      description:
          'DatePicker accepts a strings prop that allows custom localization.',
      builder: _localized,
    ),
    DocsSection(
      id: 'compat-components-datepicker--error-handling',
      title: 'Error Handling',
      description:
          'To add error handling to a DatePicker, use onValidationResult along '
          'with Field. onValidationResult provides an error type string that '
          'can be used with defaultDatePickerErrorStrings to get default '
          'messages.',
      builder: _errorHandling,
    ),
    DocsSection(
      id: 'compat-components-datepicker--controlled',
      title: 'Controlled',
      description:
          'A DatePicker can be controlled by manually keeping track of the '
          'state and updating it. When controlled, the value prop should use '
          'null instead of undefined to clear the value of the DatePicker.',
      builder: _controlled,
    ),
    DocsSection(
      id: 'compat-components-datepicker--required',
      title: 'Required',
      description:
          'DatePicker supports required validation. The validation will happen '
          'when the DatePicker loses focus.',
      builder: _required,
    ),
    DocsSection(
      id: 'compat-components-datepicker--disabled',
      title: 'Disabled',
      description: 'DatePicker can be disabled to restrict user interaction.',
      builder: _disabled,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'value',
      type: 'DateTime?',
      defaultValue: 'null',
      description: 'The chosen date. Null selects nothing.',
    ),
    PropRow(
      name: 'onSelectDate',
      type: 'ValueChanged<DateTime?>?',
      defaultValue: 'null',
      description:
          'Called with local midnight when a date is chosen or typed. Null '
          'disables the picker.',
    ),
    PropRow(
      name: 'placeholder',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'Shown while the field is empty.',
    ),
    PropRow(
      name: 'allowTextInput',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the field accepts a typed date.',
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
      name: 'firstDayOfWeek',
      type: 'FluentDayOfWeek',
      defaultValue: 'FluentDayOfWeek.sunday',
      description: "Which day the calendar's week starts on.",
    ),
    PropRow(
      name: 'showWeekNumbers',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the day grid draws a week-number column.',
    ),
    PropRow(
      name: 'firstWeekOfYear',
      type: 'FluentFirstWeekOfYear',
      defaultValue: 'FluentFirstWeekOfYear.firstDay',
      description: 'Which week counts as week 1, when showWeekNumbers is set.',
    ),
    PropRow(
      name: 'showMonthPickerAsOverlay',
      type: 'bool',
      defaultValue: 'false',
      description:
          'Whether the month picker is reached through the day caption rather '
          'than shown beside the day grid.',
    ),
    PropRow(
      name: 'formatDate',
      type: 'String Function(DateTime date)?',
      defaultValue: 'null',
      description: 'Renders the chosen date into the field.',
    ),
    PropRow(
      name: 'parseDate',
      type: 'DateTime? Function(String text)?',
      defaultValue: 'null',
      description: 'Parses typed text. Null means the text is not a date.',
    ),
    PropRow(
      name: 'strings',
      type: 'FluentCalendarStrings?',
      defaultValue: 'null',
      description: 'Every calendar label that is not a number.',
    ),
    PropRow(
      name: 'required',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether an empty field is an error.',
    ),
    PropRow(
      name: 'onValidationResult',
      type: 'ValueChanged<FluentDatePickerValidationResult>?',
      defaultValue: 'null',
      description: 'Called once per commit with the outcome.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentDatePickerAppearance',
      defaultValue: 'FluentDatePickerAppearance.outline',
      description: 'Colours and borders of the faceplate.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentDatePickerSize',
      defaultValue: 'FluentDatePickerSize.medium',
      description: 'Height and type ramp of the faceplate.',
    ),
    PropRow(
      name: 'borderless',
      type: 'bool',
      defaultValue: 'false',
      description: "Whether to drop the faceplate's borders.",
    ),
  ],
);

// #docregion compat-components-datepicker--default
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  DateTime? _value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: FluentField(
      label: const Text('Select a date'),
      child: FluentDatePicker(
        value: _value,
        onSelectDate: (DateTime? date) => setState(() => _value = date),
        placeholder: const Text('Select a date...'),
      ),
    ),
  );
}
// #enddocregion compat-components-datepicker--default

// #docregion compat-components-datepicker--text-input
Widget _textInput(BuildContext context) => const _TextInput();

class _TextInput extends StatefulWidget {
  const _TextInput();

  @override
  State<_TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<_TextInput> {
  DateTime? _value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: FluentField(
      label: const Text('Select a date'),
      child: FluentDatePicker(
        allowTextInput: true,
        value: _value,
        onSelectDate: (DateTime? date) => setState(() => _value = date),
        placeholder: const Text('Select a date...'),
      ),
    ),
  );
}
// #enddocregion compat-components-datepicker--text-input

// #docregion compat-components-datepicker--first-day-of-the-week
Widget _firstDayOfTheWeek(BuildContext context) => const _FirstDayOfTheWeek();

class _FirstDayOfTheWeek extends StatefulWidget {
  const _FirstDayOfTheWeek();

  @override
  State<_FirstDayOfTheWeek> createState() => _FirstDayOfTheWeekState();
}

class _FirstDayOfTheWeekState extends State<_FirstDayOfTheWeek> {
  // Sunday first, which is the order FluentDayOfWeek indexes by.
  static const List<String> _days = <String>[
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  DateTime? _value;
  FluentDayOfWeek _firstDayOfWeek = FluentDayOfWeek.sunday;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 250,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 15,
      children: <Widget>[
        FluentField(
          label: const Text('Start date'),
          child: FluentDatePicker(
            firstDayOfWeek: _firstDayOfWeek,
            value: _value,
            onSelectDate: (DateTime? date) => setState(() => _value = date),
            placeholder: const Text('Select a date...'),
          ),
        ),
        FluentField(
          label: const Text('Select the first day of the week'),
          child: FluentDropdown<FluentDayOfWeek>(
            value: _firstDayOfWeek,
            onChanged: (FluentDayOfWeek day) =>
                setState(() => _firstDayOfWeek = day),
            options: <FluentDropdownOption<FluentDayOfWeek>>[
              for (final FluentDayOfWeek day in FluentDayOfWeek.values)
                FluentDropdownOption<FluentDayOfWeek>(
                  value: day,
                  label: Text(_days[day.index]),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
// #enddocregion compat-components-datepicker--first-day-of-the-week

// #docregion compat-components-datepicker--week-numbers
Widget _weekNumbers(BuildContext context) => const _WeekNumbers();

class _WeekNumbers extends StatefulWidget {
  const _WeekNumbers();

  @override
  State<_WeekNumbers> createState() => _WeekNumbersState();
}

class _WeekNumbersState extends State<_WeekNumbers> {
  DateTime? _value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: FluentField(
      label: const Text('Start date'),
      child: FluentDatePicker(
        showWeekNumbers: true,
        // Upstream's `firstWeekOfYear={1}` — FirstWeekOfYear.FirstFullWeek.
        firstWeekOfYear: FluentFirstWeekOfYear.firstFullWeek,
        showMonthPickerAsOverlay: true,
        value: _value,
        onSelectDate: (DateTime? date) => setState(() => _value = date),
        placeholder: const Text('Select a date...'),
      ),
    ),
  );
}
// #enddocregion compat-components-datepicker--week-numbers

// #docregion compat-components-datepicker--date-range
// Upstream drives `calendar.dateRangeType`, which paints a whole week, work
// week or month as one selection. `FluentCalendar` selects a single day and has
// no range axis, so the control below is live and the calendar is not — a
// `reduced` adaptation rather than a knob dressed up as working.
Widget _dateRange(BuildContext context) => const _DateRange();

class _DateRange extends StatefulWidget {
  const _DateRange();

  @override
  State<_DateRange> createState() => _DateRangeState();
}

class _DateRangeState extends State<_DateRange> {
  static const List<String> _dateRangeOptions = <String>[
    'Day',
    'Work Week',
    'Week',
    'Month',
  ];

  DateTime? _value;
  String _dateRangeType = 'Week';

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 20,
      children: <Widget>[
        FluentField(
          label: const Text('Select a date'),
          child: FluentDatePicker(
            value: _value,
            onSelectDate: (DateTime? date) => setState(() => _value = date),
            placeholder: const Text('Select a date...'),
          ),
        ),
        FluentField(
          label: const Text('Select a DateRangeType'),
          child: FluentDropdown<String>(
            value: _dateRangeType,
            onChanged: (String value) => setState(() => _dateRangeType = value),
            options: <FluentDropdownOption<String>>[
              for (final String key in _dateRangeOptions)
                FluentDropdownOption<String>(value: key, label: Text(key)),
            ],
          ),
        ),
      ],
    ),
  );
}
// #enddocregion compat-components-datepicker--date-range

// #docregion compat-components-datepicker--date-boundaries
Widget _dateBoundaries(BuildContext context) => const _DateBoundaries();

class _DateBoundaries extends StatefulWidget {
  const _DateBoundaries();

  @override
  State<_DateBoundaries> createState() => _DateBoundariesState();
}

class _DateBoundariesState extends State<_DateBoundaries> {
  static const List<String> _weekdays = <String>[
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static final DateTime _today = DateTime.now();
  static final DateTime _minDate = _addMonths(_today, -1);
  static final DateTime _maxDate = _addMonths(_today, 12);

  /// Upstream's `addMonths`, which clamps rather than rolling 31 March into
  /// April. `addYears(today, 1)` is the same call with twelve months.
  static DateTime _addMonths(DateTime date, int months) {
    final DateTime target = DateTime(date.year, date.month + months);
    final int lastDay = DateTime(target.year, target.month + 1, 0).day;
    return DateTime(
      target.year,
      target.month,
      date.day < lastDay ? date.day : lastDay,
    );
  }

  /// JavaScript's `Date.prototype.toDateString()` — `Mon Aug 24 2026`.
  static String _toDateString(DateTime date) =>
      '${_weekdays[date.weekday % 7]} ${_months[date.month - 1]} '
      '${date.day.toString().padLeft(2, '0')} ${date.year}';

  DateTime? _value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: FluentField(
      label: SizedBox(
        width: 280,
        child: Text(
          'The date boundaries for this example are ${_toDateString(_minDate)} '
          'to ${_toDateString(_maxDate)}.',
        ),
      ),
      // Upstream's `onFormatDate` renders `M/d/yyyy`, which is exactly what
      // `fluentFormatDate` — the default — already does.
      child: FluentDatePicker(
        minDate: _minDate,
        maxDate: _maxDate,
        allowTextInput: true,
        value: _value,
        onSelectDate: (DateTime? date) => setState(() => _value = date),
        placeholder: const Text('Select a date...'),
      ),
    ),
  );
}
// #enddocregion compat-components-datepicker--date-boundaries

// #docregion compat-components-datepicker--custom-date-formatting
Widget _customDateFormatting(BuildContext context) =>
    const _CustomDateFormatting();

class _CustomDateFormatting extends StatefulWidget {
  const _CustomDateFormatting();

  @override
  State<_CustomDateFormatting> createState() => _CustomDateFormattingState();
}

class _CustomDateFormattingState extends State<_CustomDateFormatting> {
  final FocusNode _focusNode = FocusNode();

  DateTime? _value;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year % 100}';

  DateTime? _parseDateFromString(String text) {
    final DateTime previousValue = _value ?? DateTime.now();
    final List<String> newValueParts = text.trim().split('/');
    final int? rawDay = int.tryParse(newValueParts[0]);
    if (rawDay == null) return null;
    final int day = rawDay.clamp(1, 31);
    final int? rawMonth = newValueParts.length > 1
        ? int.tryParse(newValueParts[1])
        : null;
    final int month = rawMonth == null
        ? previousValue.month
        : rawMonth.clamp(1, 12);
    int year = newValueParts.length > 2
        ? (int.tryParse(newValueParts[2]) ?? previousValue.year)
        : previousValue.year;
    if (year < 100) {
      year += previousValue.year - (previousValue.year % 100);
    }
    return DateTime(year, month, day);
  }

  void _clear() {
    setState(() => _value = null);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 15,
      children: <Widget>[
        FluentField(
          label: const Text(
            'Select a date. Input format is day slash month slash year.',
          ),
          child: FluentDatePicker(
            focusNode: _focusNode,
            allowTextInput: true,
            value: _value,
            onSelectDate: (DateTime? date) => setState(() => _value = date),
            formatDate: _formatDate,
            parseDate: _parseDateFromString,
            placeholder: const Text('Select a date...'),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: <Widget>[
            FluentButton(onPressed: _clear, child: const Text('Clear')),
            Text('Selected date: ${_value?.toString() ?? ''}'),
          ],
        ),
      ],
    ),
  );
}
// #enddocregion compat-components-datepicker--custom-date-formatting

// #docregion compat-components-datepicker--localized
const FluentCalendarStrings _localizedStrings = FluentCalendarStrings(
  days: <String>[
    'Domingo',
    'Lunes',
    'Martes',
    'Miercoles',
    'Jueves',
    'Viernes',
    'Sabado',
  ],
  shortDays: <String>['D', 'L', 'M', 'M', 'J', 'V', 'S'],
  months: <String>[
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ],
  shortMonths: <String>[
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ],
  goToToday: 'Ir a hoy',
);

String _formatLocalizedDate(DateTime date) =>
    '${_localizedStrings.months[date.month - 1]} ${date.day}, ${date.year}';

Widget _localized(BuildContext context) => const _Localized();

class _Localized extends StatefulWidget {
  const _Localized();

  @override
  State<_Localized> createState() => _LocalizedState();
}

class _LocalizedState extends State<_Localized> {
  DateTime? _value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: FluentField(
      label: const Text('Selecciona una fecha'),
      child: FluentDatePicker(
        strings: _localizedStrings,
        value: _value,
        onSelectDate: (DateTime? date) => setState(() => _value = date),
        formatDate: _formatLocalizedDate,
        placeholder: const Text('Selecciona una fecha...'),
      ),
    ),
  );
}
// #enddocregion compat-components-datepicker--localized

// #docregion compat-components-datepicker--error-handling
Widget _errorHandling(BuildContext context) => const _ErrorHandling();

class _ErrorHandling extends StatefulWidget {
  const _ErrorHandling();

  @override
  State<_ErrorHandling> createState() => _ErrorHandlingState();
}

class _ErrorHandlingState extends State<_ErrorHandling> {
  static const List<String> _weekdays = <String>[
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static final DateTime _today = DateTime.now();
  static final DateTime _minDate = _addMonths(_today, -1);
  static final DateTime _maxDate = _addMonths(_today, 12);

  /// Upstream's `addMonths`, which clamps rather than rolling 31 March into
  /// April. `addYears(today, 1)` is the same call with twelve months.
  static DateTime _addMonths(DateTime date, int months) {
    final DateTime target = DateTime(date.year, date.month + months);
    final int lastDay = DateTime(target.year, target.month + 1, 0).day;
    return DateTime(
      target.year,
      target.month,
      date.day < lastDay ? date.day : lastDay,
    );
  }

  /// JavaScript's `Date.prototype.toDateString()` — `Mon Aug 24 2026`.
  static String _toDateString(DateTime date) =>
      '${_weekdays[date.weekday % 7]} ${_months[date.month - 1]} '
      '${date.day.toString().padLeft(2, '0')} ${date.year}';

  DateTime? _value;
  FluentDatePickerErrorType? _error;

  @override
  Widget build(BuildContext context) {
    final String? message = defaultFluentDatePickerErrorStrings.messageFor(
      _error,
    );
    return SizedBox(
      width: 300,
      child: FluentField(
        required: true,
        label: SizedBox(
          width: 280,
          child: Text(
            'Select a date out of bounds (minDate: ${_toDateString(_minDate)}, '
            'maxDate: ${_toDateString(_maxDate)}), type an invalid input, or '
            'leave the input empty and close the DatePicker.',
          ),
        ),
        validationState: message == null
            ? FluentFieldValidationState.none
            : FluentFieldValidationState.error,
        validationMessage: message == null ? null : Text(message),
        child: FluentDatePicker(
          minDate: _minDate,
          maxDate: _maxDate,
          required: true,
          allowTextInput: true,
          value: _value,
          onSelectDate: (DateTime? date) => setState(() => _value = date),
          onValidationResult: (FluentDatePickerValidationResult result) =>
              setState(() => _error = result.error),
          placeholder: const Text('Select a date...'),
        ),
      ),
    );
  }
}
// #enddocregion compat-components-datepicker--error-handling

// #docregion compat-components-datepicker--controlled
// Upstream wraps this story in an `AriaLiveAnnouncer` and announces each new
// date. `SemanticsService` lives in `package:flutter/semantics.dart`, which this
// showroom does not import, so the announcement is dropped and the stepping is
// kept.
Widget _controlled(BuildContext context) => const _Controlled();

class _Controlled extends StatefulWidget {
  const _Controlled();

  @override
  State<_Controlled> createState() => _ControlledState();
}

class _ControlledState extends State<_Controlled> {
  DateTime? _selectedDate;

  void _step(int days) => setState(() {
    final DateTime? previous = _selectedDate;
    _selectedDate = previous == null
        ? DateTime.now()
        : DateTime(previous.year, previous.month, previous.day + days);
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 15,
      children: <Widget>[
        FluentField(
          label: const Text('Select a date'),
          child: FluentDatePicker(
            value: _selectedDate,
            onSelectDate: (DateTime? date) =>
                setState(() => _selectedDate = date),
            placeholder: const Text('Select a date...'),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: <Widget>[
            FluentButton(
              onPressed: () => _step(-1),
              child: const Text('Previous'),
            ),
            FluentButton(onPressed: () => _step(1), child: const Text('Next')),
          ],
        ),
      ],
    ),
  );
}
// #enddocregion compat-components-datepicker--controlled

// #docregion compat-components-datepicker--required
Widget _required(BuildContext context) => const _Required();

class _Required extends StatefulWidget {
  const _Required();

  @override
  State<_Required> createState() => _RequiredState();
}

class _RequiredState extends State<_Required> {
  DateTime? _value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: FluentField(
      label: const Text('Date required'),
      required: true,
      child: FluentDatePicker(
        required: true,
        value: _value,
        onSelectDate: (DateTime? date) => setState(() => _value = date),
        placeholder: const Text('Select a date...'),
      ),
    ),
  );
}
// #enddocregion compat-components-datepicker--required

// #docregion compat-components-datepicker--disabled
// A null `onSelectDate` is what disables a FluentDatePicker — there is no
// separate `disabled` flag, the same contract every other input here follows.
Widget _disabled(BuildContext context) => const SizedBox(
  width: 300,
  child: FluentField(
    label: Text('Disabled DatePicker'),
    child: FluentDatePicker(placeholder: Text('Select a date...')),
  ),
);
// #enddocregion compat-components-datepicker--disabled
