import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/material.dart' show Icons, Icon;
import 'package:flutter/widgets.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

import 'story_kit.dart';

/// The Fluent 2 form inputs and selection controls.
List<Story> get inputsStories => [
  Story(
    name: 'Inputs/FluentCheckbox',
    description: 'A tri-state checkbox: checked, unchecked, or mixed (null).',
    builder: (context) {
      return DemoColumn(
        children: [
          DemoRail(
            title: 'States',
            children: [
              StatefulBuilder(
                builder: (context, setState) => FluentCheckbox(
                  checked: true,
                  onChanged: (_) {},
                  label: const Text('Checked'),
                ),
              ),
              StatefulBuilder(
                builder: (context, setState) => FluentCheckbox(
                  checked: false,
                  onChanged: (_) {},
                  label: const Text('Unchecked'),
                ),
              ),
              const FluentCheckbox(
                checked: null,
                onChanged: null,
                label: Text('Mixed (indeterminate)'),
              ),
              const FluentCheckbox(
                checked: false,
                onChanged: null,
                label: Text('Disabled'),
              ),
            ],
          ),
          DemoRail(
            title: 'Interactive',
            children: [
              StatefulBuilder(
                builder: (context, setState) => FluentCheckbox(
                  checked: context.knobs.boolean(
                    label: 'Checked',
                    initial: true,
                  ),
                  onChanged: (value) {},
                  label: const Text('Subscribe to updates'),
                ),
              ),
            ],
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Inputs/FluentRadioGroup',
    description: 'A mutually exclusive set of radio options.',
    builder: (context) {
      return DemoRail(
        title: 'Radio group',
        children: [
          StatefulBuilder(
            builder: (context, setState) => FluentRadioGroup<String>(
              value: 'b',
              onChanged: (value) {},
              layout: FluentRadioGroupLayout.vertical,
              children: const [
                FluentRadio<String>(value: 'a', label: Text('Option A')),
                FluentRadio<String>(value: 'b', label: Text('Option B')),
                FluentRadio<String>(value: 'c', label: Text('Option C')),
              ],
            ),
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Inputs/FluentSwitch',
    description: 'A boolean toggle switch.',
    builder: (context) {
      return DemoColumn(
        children: [
          DemoRail(
            title: 'States',
            children: [
              StatefulBuilder(
                builder: (context, setState) => FluentSwitch(
                  checked: true,
                  onChanged: (value) {},
                  label: const Text('On'),
                ),
              ),
              StatefulBuilder(
                builder: (context, setState) => FluentSwitch(
                  checked: false,
                  onChanged: (value) {},
                  label: const Text('Off'),
                ),
              ),
              const FluentSwitch(
                checked: false,
                onChanged: null,
                label: Text('Disabled'),
              ),
              FluentSwitch(
                checked: context.knobs.boolean(
                  label: 'Checked',
                  initial: false,
                ),
                onChanged: (value) {},
                label: const Text('Wi-Fi'),
              ),
            ],
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Inputs/FluentSlider',
    description: 'A draggable control for picking a value on a range.',
    builder: (context) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FluentLabel(
              size: FluentLabelSize.large,
              child: const Text('Slider'),
            ),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setState) => FluentSlider(
                value: context.knobs.slider(
                  label: 'Value',
                  initial: 40,
                  min: 0,
                  max: 100,
                ),
                min: 0,
                max: 100,
                onChanged: (value) {},
                semanticLabel: 'Value',
              ),
            ),
          ],
        ),
      );
    },
  ),
  Story(
    name: 'Inputs/FluentInput',
    description:
        'A single-line text field with prefix/affix content and '
        'appearance, size and error variants.',
    builder: (context) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: DemoColumn(
          children: [
            DemoRail(
              title: 'Appearances',
              children: [
                for (final appearance in FluentInputAppearance.values)
                  FluentInput(
                    appearance: appearance,
                    placeholder: const Text('Placeholder'),
                    contentBefore: appearance == FluentInputAppearance.underline
                        ? null
                        : const Icon(Icons.person),
                  ),
              ],
            ),
            const DemoRail(
              title: 'States',
              children: [
                FluentInput(placeholder: Text('Enabled')),
                FluentInput(enabled: false, placeholder: Text('Disabled')),
                FluentInput(error: true, placeholder: Text('Error')),
              ],
            ),
          ],
        ),
      );
    },
  ),
  Story(
    name: 'Inputs/FluentTextarea',
    description: 'A multi-line text field.',
    builder: (context) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: DemoColumn(
          children: [
            const DemoRail(
              title: 'Example',
              children: [
                FluentTextarea(minLines: 3, placeholder: 'Write a message…'),
              ],
            ),
            const DemoRail(
              title: 'States',
              children: [
                FluentTextarea(
                  enabled: false,
                  minLines: 2,
                  placeholder: 'Disabled',
                ),
                FluentTextarea(
                  invalid: true,
                  minLines: 2,
                  placeholder: 'Invalid',
                ),
              ],
            ),
          ],
        ),
      );
    },
  ),
  Story(
    name: 'Inputs/FluentSearchBox',
    description: 'A search field with a built-in magnifier and clear button.',
    builder: (context) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: DemoColumn(
          children: [
            DemoRail(
              title: 'Variants',
              children: [
                const FluentSearchBox(placeholder: 'Search'),
                for (final appearance in FluentSearchBoxAppearance.values)
                  FluentSearchBox(
                    appearance: appearance,
                    placeholder: 'Search',
                  ),
              ],
            ),
          ],
        ),
      );
    },
  ),
  Story(
    name: 'Inputs/FluentRating',
    description: 'A star rating that can be interactive or read-only.',
    builder: (context) {
      return DemoColumn(
        children: [
          DemoRail(
            title: 'Interactive',
            children: [
              StatefulBuilder(
                builder: (context, setState) => FluentRating(
                  value: context.knobs.slider(
                    label: 'Rating',
                    initial: 3,
                    min: 0,
                    max: 5,
                  ),
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
          DemoRail(
            title: 'Read-only',
            children: const [
              FluentRating(
                value: 4,
                onChanged: null,
                type: FluentRatingType.display,
              ),
            ],
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Inputs/FluentField with Label',
    description:
        'A labeled field composing FluentLabel/FluentInfoLabel with '
        'an input.',
    builder: (context) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const FluentField(
              label: FluentLabel(child: Text('First name')),
              hint: Text('Enter your name'),
              child: FluentInput(),
            ),
            const SizedBox(height: 20),
            FluentInfoLabel(
              info: const Text('Your full legal name.'),
              child: const Text('Full name'),
            ),
            const SizedBox(height: 20),
            const FluentLabel(required: true, child: Text('Required field')),
            const SizedBox(height: 8),
            const FluentInput(placeholder: Text('Email address')),
          ],
        ),
      );
    },
  ),
  Story(
    name: 'Inputs/FluentLink',
    description: 'An inline or standalone link.',
    builder: (context) {
      return DemoRow(
        children: [
          FluentLink(onPressed: () {}, child: const Text('This is a link')),
          const FluentLink(onPressed: null, child: Text('Disabled')),
          FluentLink(
            inline: true,
            onPressed: () {},
            child: const Text('Inline link'),
          ),
          FluentLink(
            appearance: FluentLinkAppearance.subtle,
            onPressed: () {},
            child: const Text('Subtle'),
          ),
        ],
      );
    },
  ),
  Story(
    name: 'Inputs/FluentDropdown',
    description: 'A control for picking a single value from a list.',
    builder: (context) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: FluentDropdown<String>(
          value: 'a',
          options: const [
            FluentDropdownOption<String>(value: 'a', label: Text('Apple')),
            FluentDropdownOption<String>(value: 'b', label: Text('Banana')),
            FluentDropdownOption<String>(value: 'c', label: Text('Cherry')),
          ],
          onChanged: (value) {},
        ),
      );
    },
  ),
  Story(
    name: 'Inputs/FluentSpinButton',
    description:
        'A numeric stepper with increment, decrement and inline entry.',
    builder: (context) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: FluentSpinButton(
          value: context.knobs.slider(
            label: 'Value',
            initial: 5,
            min: 0,
            max: 10,
          ),
          min: 0,
          max: 10,
          step: 1,
          onChanged: (value) {},
          semanticLabel: 'Quantity',
        ),
      );
    },
  ),
  Story(
    name: 'Inputs/FluentSwatchPicker',
    description: 'A picker of color swatches.',
    builder: (context) {
      return FluentSwatchPicker(
        semanticLabel: 'Theme color',
        children: const [
          FluentSwatch(
            color: Color(0xFF0F6CBD),
            semanticLabel: 'Blue',
            selected: true,
          ),
          FluentSwatch(color: Color(0xFF8764B8), semanticLabel: 'Purple'),
          FluentSwatch(color: Color(0xFF107C10), semanticLabel: 'Green'),
          FluentSwatch(color: Color(0xFFD13438), semanticLabel: 'Red'),
        ],
      );
    },
  ),
  Story(
    name: 'Inputs/FluentTagPicker',
    description: 'A multi-value picker that shows selections as tags.',
    builder: (context) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: FluentTagPicker<String>(
          options: const [
            FluentTagPickerOption<String>(
              value: 'js',
              label: Text('JavaScript'),
            ),
            FluentTagPickerOption<String>(value: 'dart', label: Text('Dart')),
            FluentTagPickerOption<String>(
              value: 'ts',
              label: Text('TypeScript'),
            ),
          ],
          selected: const ['dart'],
          placeholder: const Text('Add a language'),
          onChanged: (values) {},
        ),
      );
    },
  ),
  Story(
    name: 'Inputs/FluentInfoButton',
    description: 'A small control that reveals contextual information.',
    builder: (context) {
      return FluentInfoButton(
        semanticLabel: 'More info',
        info: const Text('This is supporting information.'),
        onOpenChanged: (value) {},
        icon: const Icon(Icons.info),
      );
    },
  ),

  Story(
    name: 'Inputs/FluentCalendar',
    description:
        'A single-date calendar with month, year and decade views, full '
        'keyboard grid navigation and upstream\'s page-slide motion.',
    builder: (context) {
      // Pinned so the story reads the same on any day.
      final today = DateTime(2026, 3, 10);
      return _CalendarDemo(
        today: today,
        monthPicker: context.knobs.boolean(
          label: 'Month picker beside the day grid',
          initial: true,
        ),
        mondayFirst: context.knobs.boolean(label: 'Week starts Monday'),
        bounded: context.knobs.boolean(label: 'Restrict to this month'),
        disabled: context.knobs.boolean(label: 'Disabled'),
      );
    },
  ),
  Story(
    name: 'Inputs/FluentDatePicker',
    description:
        'An input that opens a calendar popup. Click to open, click again to '
        'dismiss; Enter opens from the keyboard and Escape closes.',
    builder: (context) => _DatePickerDemo(
      today: DateTime(2026, 3, 10),
      allowTextInput: context.knobs.boolean(label: 'Allow text input'),
      monthPicker: context.knobs.boolean(
        label: 'Month picker beside the day grid',
        initial: true,
      ),
      openOnClick: context.knobs.boolean(label: 'Open on click', initial: true),
      borderless: context.knobs.boolean(label: 'Borderless'),
      required: context.knobs.boolean(label: 'Required'),
    ),
  ),
  Story(
    name: 'Inputs/FluentTimePicker',
    description:
        'A combobox of times. Freeform accepts typed times such as "9:05p"; '
        'Space types a space rather than committing a row.',
    builder: (context) => _TimePickerDemo(
      freeform: context.knobs.boolean(label: 'Freeform'),
      clearable: context.knobs.boolean(label: 'Clearable'),
      showSeconds: context.knobs.boolean(label: 'Show seconds'),
      hourCycle:
          FluentHourCycle.values[context.knobs.sliderInt(
            label: 'Hour cycle: 0 h11, 1 h12, 2 h23, 3 h24',
            initial: 1,
            min: 0,
            max: 3,
          )],
      increment: context.knobs.sliderInt(
        label: 'Increment (minutes)',
        initial: 30,
        min: 15,
        max: 60,
      ),
    ),
  ),
];

class _CalendarDemo extends StatefulWidget {
  const _CalendarDemo({
    required this.today,
    required this.monthPicker,
    required this.mondayFirst,
    required this.bounded,
    required this.disabled,
  });

  final DateTime today;
  final bool monthPicker;
  final bool mondayFirst;
  final bool bounded;
  final bool disabled;

  @override
  State<_CalendarDemo> createState() => _CalendarDemoState();
}

class _CalendarDemoState extends State<_CalendarDemo> {
  DateTime? _value;

  @override
  Widget build(BuildContext context) => DemoColumn(
    children: [
      DemoRail(
        title: 'Calendar',
        children: [
          FluentCalendar(
            today: widget.today,
            value: _value,
            isMonthPickerVisible: widget.monthPicker,
            firstDayOfWeek: widget.mondayFirst
                ? FluentDayOfWeek.monday
                : FluentDayOfWeek.sunday,
            minDate: widget.bounded ? DateTime(2026, 3, 5) : null,
            maxDate: widget.bounded ? DateTime(2026, 3, 24) : null,
            restrictedDates: widget.bounded
                ? <DateTime>[DateTime(2026, 3, 12)]
                : const <DateTime>[],
            onSelectDate: widget.disabled
                ? null
                : (date) => setState(() => _value = date),
          ),
        ],
      ),
      DemoRail(
        title: 'Selected',
        children: [Text(_value == null ? 'Nothing selected' : '$_value')],
      ),
    ],
  );
}

class _DatePickerDemo extends StatefulWidget {
  const _DatePickerDemo({
    required this.today,
    required this.allowTextInput,
    required this.monthPicker,
    required this.openOnClick,
    required this.borderless,
    required this.required,
  });

  final DateTime today;
  final bool allowTextInput;
  final bool monthPicker;
  final bool openOnClick;
  final bool borderless;
  final bool required;

  @override
  State<_DatePickerDemo> createState() => _DatePickerDemoState();
}

class _DatePickerDemoState extends State<_DatePickerDemo> {
  DateTime? _value;
  FluentDatePickerErrorType? _error;

  @override
  Widget build(BuildContext context) => DemoColumn(
    children: [
      DemoRail(
        title: 'Appearance',
        children: [
          for (final appearance in FluentDatePickerAppearance.values)
            SizedBox(
              width: 220,
              child: FluentDatePicker(
                today: widget.today,
                appearance: appearance,
                value: _value,
                borderless: widget.borderless,
                // Every knob reaches every picker in this story. Wiring them to
                // only one rail is what made "Allow text input" look broken:
                // toggling it and typing into a different instance does
                // nothing, because that instance is still read-only.
                allowTextInput: widget.allowTextInput,
                openOnClick: widget.openOnClick,
                isMonthPickerVisible: widget.monthPicker,
                placeholder: const Text('Select a date...'),
                onSelectDate: (date) => setState(() => _value = date),
              ),
            ),
        ],
      ),
      DemoRail(
        title: 'Size',
        children: [
          for (final size in FluentDatePickerSize.values)
            SizedBox(
              width: 220,
              child: FluentDatePicker(
                today: widget.today,
                size: size,
                allowTextInput: widget.allowTextInput,
                openOnClick: widget.openOnClick,
                isMonthPickerVisible: widget.monthPicker,
                placeholder: const Text('Select a date...'),
                onSelectDate: (_) {},
              ),
            ),
        ],
      ),
      DemoRail(
        title: 'With Field and validation',
        children: [
          SizedBox(
            width: 280,
            child: FluentField(
              label: const Text('Start date'),
              required: widget.required,
              validationState: _error == null
                  ? FluentFieldValidationState.none
                  : FluentFieldValidationState.error,
              validationMessage: Text(
                defaultFluentDatePickerErrorStrings.messageFor(_error) ?? '',
              ),
              child: FluentDatePicker(
                today: widget.today,
                value: _value,
                allowTextInput: widget.allowTextInput,
                openOnClick: widget.openOnClick,
                isMonthPickerVisible: widget.monthPicker,
                required: widget.required,
                minDate: DateTime(2026, 1, 1),
                maxDate: DateTime(2026, 12, 31),
                placeholder: const Text('Select a date...'),
                onValidationResult: (result) =>
                    setState(() => _error = result.error),
                onSelectDate: (date) => setState(() => _value = date),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _TimePickerDemo extends StatefulWidget {
  const _TimePickerDemo({
    required this.freeform,
    required this.clearable,
    required this.showSeconds,
    required this.hourCycle,
    required this.increment,
  });

  final bool freeform;
  final bool clearable;
  final bool showSeconds;
  final FluentHourCycle hourCycle;
  final int increment;

  @override
  State<_TimePickerDemo> createState() => _TimePickerDemoState();
}

class _TimePickerDemoState extends State<_TimePickerDemo> {
  DateTime? _value;
  FluentTimePickerErrorType? _error;

  @override
  Widget build(BuildContext context) {
    final anchor = DateTime(2026, 3, 10);
    return DemoColumn(
      children: [
        DemoRail(
          title: 'Appearance',
          children: [
            for (final appearance in FluentTimePickerAppearance.values)
              SizedBox(
                width: 200,
                child: FluentTimePicker(
                  appearance: appearance,
                  dateAnchor: anchor,
                  hourCycle: widget.hourCycle,
                  increment: widget.increment,
                  showSeconds: widget.showSeconds,
                  placeholder: const Text('Select a time'),
                  onTimeChange: (_) {},
                ),
              ),
          ],
        ),
        DemoRail(
          title: 'Interactive',
          children: [
            SizedBox(
              width: 240,
              child: FluentTimePicker(
                dateAnchor: anchor,
                selectedTime: _value,
                freeform: widget.freeform,
                clearable: widget.clearable,
                showSeconds: widget.showSeconds,
                hourCycle: widget.hourCycle,
                increment: widget.increment,
                startHour: 8,
                endHour: 18,
                error: _error != null,
                placeholder: const Text('Select a time'),
                onTimeChange: (data) => setState(() {
                  _value = data.selectedTime;
                  _error = data.error;
                }),
              ),
            ),
          ],
        ),
        DemoRail(
          title: 'Selected',
          children: [
            Text(
              _error != null
                  ? 'Error: ${_error!.name}'
                  : _value == null
                  ? 'Nothing selected'
                  : '$_value',
            ),
          ],
        ),
      ],
    );
  }
}
