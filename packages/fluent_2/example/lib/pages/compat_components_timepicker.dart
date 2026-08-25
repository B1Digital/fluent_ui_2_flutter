import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../shell/catalog.dart';

/// The TimePicker docs page.
///
/// Sections, titles, descriptions and sample data are upstream's, verbatim.
/// Each section's demo is delimited by a `#docregion` whose id is the section
/// id, so the "Show code" panel can read this file back and print exactly the
/// code that rendered.
const DocsPage timePickerPage = DocsPage(
  id: 'compat-components-timepicker',
  title: 'TimePicker',
  description:
      'TimePicker offers a control that’s optimized for selecting a time from '
      'a drop-down list or using free-form input to enter a custom time. Note: '
      'TimePicker is a compat component - its internal architecture does not '
      'follow all the principles regular Fluent UI v9 components follow - it '
      'is not composed of atomic hooks and it might be more difficult to tweak '
      'its appearance and behavior. It however follows Fluent 2 design and '
      'uses design tokens, it is production ready and it is stable.',
  source: 'lib/pages/compat_components_timepicker.dart',
  sections: <DocsSection>[
    DocsSection(
      id: 'compat-components-timepicker--default',
      title: 'Default',
      builder: _default,
    ),
    DocsSection(
      id: 'compat-components-timepicker--controlled',
      title: 'Controlled',
      description:
          'A TimePicker may have controlled selection and value. There are a '
          'few things to keep in mind: Control selectedTime with value (or '
          'defaultSelectedTime with defaultValue): When the selectedTime is '
          'controlled or a defaultSelectedTime is provided, a controlled value '
          'or defaultValue must also be defined. Otherwise, the TimePicker '
          'will not be able to display a value before the Options are '
          'rendered. Clearing input with null: when controlled, the '
          'selectedTime prop should use null instead of undefined to clear the '
          'value of the TimePicker.',
      builder: _controlled,
    ),
    DocsSection(
      id: 'compat-components-timepicker--clearable',
      title: 'Clearable',
      description:
          'A TimePicker can be clearable and let users remove their selection.',
      builder: _clearable,
    ),
    DocsSection(
      id: 'compat-components-timepicker--freeform-with-error-handling',
      title: 'Freeform With Error Handling',
      description:
          'TimePicker supports the freeform prop, which allows freeform text '
          'input. The selection behavior of freeform TimePicker aligns with '
          'the native change event behavior for text input: When the value in '
          'the TimePicker input changes, and the TimePicker loses focus, the '
          'selected time is computed from the input value. When TimePicker '
          'input value has changed and Enter key is pressed on the input: if '
          'the dropdown is expanded and the input value is prefix of an '
          'option, the selected time is set to the matching option. if the '
          'dropdown is collapsed or the input value does not match any option, '
          'the selected time is computed from input value. The selected time '
          'is available in onTimeChange callback. Use Field to display the '
          'error message based on the error type provided by onTimeChange.',
      builder: _freeformWithErrorHandling,
    ),
    DocsSection(
      id: 'compat-components-timepicker--freeform-custom-parsing',
      title: 'Freeform Custom Parsing',
      description:
          'This story sets custom time string in the dropdown options, and '
          'performs custom parsing from the input text to Date object on '
          'selection. The time display format in the dropdown can be '
          'customized using formatDateToTimeString. Freefrom TimePicker can '
          'have custom parsing for input text to Date object using '
          'parseTimeStringToDate.',
      builder: _freeformCustomParsing,
    ),
    DocsSection(
      id: 'compat-components-timepicker--time-picker-with-date-picker',
      title: 'Time Picker With Date Picker',
      builder: _timePickerWithDatePicker,
    ),
  ],
  props: <PropRow>[
    PropRow(
      name: 'selectedTime',
      type: 'DateTime?',
      defaultValue: 'null',
      description: 'The chosen time. Null selects nothing.',
    ),
    PropRow(
      name: 'onTimeChange',
      type: 'ValueChanged<FluentTimeSelectionData>?',
      defaultValue: 'null',
      description: 'Called when the value changes. Null disables the picker.',
    ),
    PropRow(
      name: 'hourCycle',
      type: 'FluentHourCycle',
      defaultValue: 'FluentHourCycle.h12',
      description: 'Which clock the options are written on.',
    ),
    PropRow(
      name: 'showSeconds',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether options and validation carry seconds.',
    ),
    PropRow(
      name: 'startHour',
      type: 'int',
      defaultValue: '0',
      description: 'First hour offered, inclusive.',
    ),
    PropRow(
      name: 'endHour',
      type: 'int',
      defaultValue: '24',
      description: 'Last hour offered, exclusive.',
    ),
    PropRow(
      name: 'increment',
      type: 'int',
      defaultValue: '30',
      description: 'Minutes between options.',
    ),
    PropRow(
      name: 'dateAnchor',
      type: 'DateTime?',
      defaultValue: 'null',
      description:
          'The day every option is built on. Defaults to selectedTime, then to '
          'the clock at mount.',
    ),
    PropRow(
      name: 'freeform',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether the field accepts typed times.',
    ),
    PropRow(
      name: 'clearable',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether to offer a glyph that clears the value.',
    ),
    PropRow(
      name: 'required',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether an empty field is an error.',
    ),
    PropRow(
      name: 'error',
      type: 'bool',
      defaultValue: 'false',
      description: 'Whether to paint the danger ramp.',
    ),
    PropRow(
      name: 'formatTime',
      type: 'String Function(DateTime time)?',
      defaultValue: 'null',
      description: "Renders an option and the field's own text.",
    ),
    PropRow(
      name: 'parseTime',
      type: 'FluentTimeStringValidationResult Function(String text)?',
      defaultValue: 'null',
      description:
          'Parses typed text. Returns the parsed time and any error, so an '
          'application can supply its own validation.',
    ),
    PropRow(
      name: 'appearance',
      type: 'FluentTimePickerAppearance',
      defaultValue: 'FluentTimePickerAppearance.outline',
      description: 'Colours and borders of the faceplate.',
    ),
    PropRow(
      name: 'size',
      type: 'FluentTimePickerSize',
      defaultValue: 'FluentTimePickerSize.medium',
      description: 'Height and type ramp of the faceplate.',
    ),
    PropRow(
      name: 'placeholder',
      type: 'Widget?',
      defaultValue: 'null',
      description: 'Shown while the field is empty.',
    ),
  ],
);

// #docregion compat-components-timepicker--default
// `FluentTimePicker` is always controlled — it has no uncontrolled mode, so
// even the plainest demo owns a `selectedTime` and writes it back from
// `onTimeChange`. A null `onTimeChange` disables the picker.
Widget _default(BuildContext context) => const _Default();

class _Default extends StatefulWidget {
  const _Default();

  @override
  State<_Default> createState() => _DefaultState();
}

class _DefaultState extends State<_Default> {
  DateTime? _selectedTime;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: FluentField(
      label: const Text('Coffee time'),
      child: FluentTimePicker(
        selectedTime: _selectedTime,
        onTimeChange: (FluentTimeSelectionData data) =>
            setState(() => _selectedTime = data.selectedTime),
      ),
    ),
  );
}
// #enddocregion compat-components-timepicker--default

// #docregion compat-components-timepicker--controlled
// Upstream contrasts an uncontrolled picker seeded with `defaultSelectedTime`
// against a fully controlled one, and needs a separate `value`/`defaultValue`
// string because its field text is independent of the selection. Neither half
// applies here: `FluentTimePicker` has no uncontrolled mode and derives its own
// field text from `selectedTime`, so both demos are controlled and the second
// pair of props disappears. The two labels and the shared seed are upstream's.
Widget _controlled(BuildContext context) => const SizedBox(
  width: 300,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      _DefaultSelection(),
      SizedBox(height: 20),
      _ControlledSelection(),
    ],
  ),
);

class _DefaultSelection extends StatefulWidget {
  const _DefaultSelection();

  @override
  State<_DefaultSelection> createState() => _DefaultSelectionState();
}

class _DefaultSelectionState extends State<_DefaultSelection> {
  // new Date("November 25, 2023 12:30:00")
  DateTime? _selectedTime = DateTime(2023, 11, 25, 12, 30);

  @override
  Widget build(BuildContext context) => FluentField(
    label: const Text('Select a time (default Selection)'),
    child: FluentTimePicker(
      startHour: 8,
      endHour: 20,
      selectedTime: _selectedTime,
      onTimeChange: (FluentTimeSelectionData data) =>
          setState(() => _selectedTime = data.selectedTime),
    ),
  );
}

class _ControlledSelection extends StatefulWidget {
  const _ControlledSelection();

  @override
  State<_ControlledSelection> createState() => _ControlledSelectionState();
}

class _ControlledSelectionState extends State<_ControlledSelection> {
  // new Date("November 25, 2023 12:30:00")
  DateTime? _selectedTime = DateTime(2023, 11, 25, 12, 30);

  @override
  Widget build(BuildContext context) => FluentField(
    label: const Text('Select a time (controlled Selection)'),
    child: FluentTimePicker(
      startHour: 8,
      endHour: 20,
      selectedTime: _selectedTime,
      onTimeChange: (FluentTimeSelectionData data) =>
          setState(() => _selectedTime = data.selectedTime),
    ),
  );
}
// #enddocregion compat-components-timepicker--controlled

// #docregion compat-components-timepicker--clearable
Widget _clearable(BuildContext context) => const _Clearable();

class _Clearable extends StatefulWidget {
  const _Clearable();

  @override
  State<_Clearable> createState() => _ClearableState();
}

class _ClearableState extends State<_Clearable> {
  DateTime? _selectedTime;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: FluentField(
      label: const Text('Coffee time'),
      child: FluentTimePicker(
        clearable: true,
        selectedTime: _selectedTime,
        onTimeChange: (FluentTimeSelectionData data) =>
            setState(() => _selectedTime = data.selectedTime),
      ),
    ),
  );
}
// #enddocregion compat-components-timepicker--clearable

// #docregion compat-components-timepicker--freeform-with-error-handling
Widget _freeformWithErrorHandling(BuildContext context) =>
    const _FreeformWithErrorHandling();

class _FreeformWithErrorHandling extends StatefulWidget {
  const _FreeformWithErrorHandling();

  @override
  State<_FreeformWithErrorHandling> createState() =>
      _FreeformWithErrorHandlingState();
}

class _FreeformWithErrorHandlingState
    extends State<_FreeformWithErrorHandling> {
  DateTime? _selectedTime;
  FluentTimePickerErrorType? _errorType;

  String? _getErrorMessage(FluentTimePickerErrorType? error) => switch (error) {
    FluentTimePickerErrorType.invalidInput =>
      'Invalid time format. Please use the 24-hour format HH:MM.',
    FluentTimePickerErrorType.outOfBounds =>
      'Time out of the 10:00 to 19:59 range.',
    FluentTimePickerErrorType.requiredInput => 'Time is required.',
    null => null,
  };

  @override
  Widget build(BuildContext context) {
    final String? message = _getErrorMessage(_errorType);
    return FluentField(
      required: true,
      // The label carries its own width. FluentField lays its label out in a
      // Row beside the required asterisk without a Flexible, so a long label
      // takes its intrinsic width and overflows instead of wrapping.
      label: const SizedBox(
        width: 300,
        child: Text(
          'Type a time outside of 10:00 to 19:59, type an invalid time, or '
          'leave the input empty and close the TimePicker.',
        ),
      ),
      validationState: message == null
          ? FluentFieldValidationState.none
          : FluentFieldValidationState.error,
      validationMessage: message == null ? null : Text(message),
      child: SizedBox(
        width: 300,
        child: FluentTimePicker(
          freeform: true,
          required: true,
          startHour: 10,
          endHour: 20,
          selectedTime: _selectedTime,
          onTimeChange: (FluentTimeSelectionData data) => setState(() {
            _selectedTime = data.selectedTime;
            _errorType = data.error;
          }),
        ),
      ),
    );
  }
}
// #enddocregion compat-components-timepicker--freeform-with-error-handling

// #docregion compat-components-timepicker--freeform-custom-parsing
Widget _freeformCustomParsing(BuildContext context) =>
    const _FreeformCustomParsing();

class _FreeformCustomParsing extends StatefulWidget {
  const _FreeformCustomParsing();

  @override
  State<_FreeformCustomParsing> createState() => _FreeformCustomParsingState();
}

class _FreeformCustomParsingState extends State<_FreeformCustomParsing> {
  // JavaScript months are 0-based, so `new Date(2023, 1, 1)` is 1 February.
  static final DateTime _anchor = DateTime(2023, 2, 1);

  DateTime? _selectedTime;
  String? _selectedTimeText;

  // Upstream's `toLocaleTimeString` with hour "numeric", minute "2-digit" and
  // hourCycle "h12" is exactly what `fluentFormatTime` writes on the h12 clock.
  String _formatDateToTimeString(DateTime date) {
    final String localeTimeString = fluentFormatTime(
      date,
      cycle: FluentHourCycle.h12,
    );
    if (date.hour < 12) {
      return 'Morning: $localeTimeString';
    }
    return 'Afternoon: $localeTimeString';
  }

  FluentTimeStringValidationResult _parseTimeStringToDate(String time) {
    if (time.isEmpty) {
      return const FluentTimeStringValidationResult();
    }

    final List<String> words = time.split(' ');
    final List<int> digits = words.length < 2
        ? const <int>[]
        : RegExp(r'\d+')
              .allMatches(words[1])
              .map((RegExpMatch match) => int.parse(match.group(0)!))
              .toList();
    // JavaScript reads a missing group as NaN and builds an Invalid Date;
    // reporting invalid-input is the same outcome said out loud.
    if (digits.length < 2) {
      return const FluentTimeStringValidationResult(
        error: FluentTimePickerErrorType.invalidInput,
      );
    }

    final int hours = digits[0];
    final int minutes = digits[1];
    final int adjustedHours = time.contains('Afternoon: ') && hours != 12
        ? hours + 12
        : hours;
    final DateTime date = DateTime(
      _anchor.year,
      _anchor.month,
      _anchor.day,
      adjustedHours,
      minutes,
    );

    return FluentTimeStringValidationResult(date: date);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SizedBox(
        width: 300,
        child: FluentField(
          label: const Text('Coffee time'),
          child: FluentTimePicker(
            freeform: true,
            dateAnchor: _anchor,
            formatTime: _formatDateToTimeString,
            parseTime: _parseTimeStringToDate,
            selectedTime: _selectedTime,
            onTimeChange: (FluentTimeSelectionData data) => setState(() {
              _selectedTime = data.selectedTime;
              _selectedTimeText = data.selectedTimeText;
            }),
          ),
        ),
      ),
      if (_selectedTimeText != null && _selectedTimeText!.isNotEmpty)
        Text('Selected time: $_selectedTimeText'),
    ],
  );
}
// #enddocregion compat-components-timepicker--freeform-custom-parsing

// #docregion compat-components-timepicker--time-picker-with-date-picker
Widget _timePickerWithDatePicker(BuildContext context) =>
    const _TimePickerWithDatePicker();

class _TimePickerWithDatePicker extends StatefulWidget {
  const _TimePickerWithDatePicker();

  @override
  State<_TimePickerWithDatePicker> createState() =>
      _TimePickerWithDatePickerState();
}

class _TimePickerWithDatePickerState extends State<_TimePickerWithDatePicker> {
  DateTime? _selectedDate;
  DateTime? _selectedTime;

  void _onSelectDate(DateTime? date) {
    setState(() {
      _selectedDate = date;
      final DateTime? time = _selectedTime;
      if (date != null && time != null) {
        _selectedTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      // Upstream's two-column CSS grid: 600 wide, a 20 gutter, equal tracks.
      SizedBox(
        width: 600,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: FluentField(
                label: const Text('Select a date'),
                child: FluentDatePicker(
                  placeholder: const Text('Select a date...'),
                  value: _selectedDate,
                  onSelectDate: _onSelectDate,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: FluentField(
                label: const Text('Select a time'),
                child: FluentTimePicker(
                  placeholder: const Text('Select a time...'),
                  freeform: true,
                  dateAnchor: _selectedDate,
                  selectedTime: _selectedTime,
                  onTimeChange: (FluentTimeSelectionData data) =>
                      setState(() => _selectedTime = data.selectedTime),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      if (_selectedDate != null)
        // `DateTime.toString()` is Dart's counterpart to JavaScript's
        // `Date.prototype.toString()`, so the readout is ISO-shaped rather
        // than the browser's locale string.
        Text('Selected date time: ${_selectedTime ?? _selectedDate}'),
    ],
  );
}

// #enddocregion compat-components-timepicker--time-picker-with-date-picker
