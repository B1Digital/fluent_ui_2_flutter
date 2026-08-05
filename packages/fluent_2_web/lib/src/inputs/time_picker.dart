import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/gestures.dart' show TapDragUpDetails;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../internal/input_modality.dart';
import '../internal/interaction.dart';
import 'dropdown_option.dart';
import 'dropdown_option_style.dart';
import 'input.dart';
import 'input_style.dart';
import 'time_picker_style.dart';

/// The colours and borders of a `FluentTimePicker`'s faceplate.
///
/// The same four upstream offers, and the same four `FluentInput` has — a time
/// picker is an input with a listbox hung off it.
enum FluentTimePickerAppearance {
  /// Neutral fill, a border on all four sides, and a rule along the bottom
  /// edge. The default.
  outline,

  /// No fill and no box border — only the bottom rule.
  underline,

  /// `neutralBackground3` fill with an invisible border.
  filledDarker,

  /// `neutralBackground1` fill with an invisible border.
  filledLighter,
}

/// The height and type ramp of a `FluentTimePicker`.
enum FluentTimePickerSize {
  /// 24 high, `caption1`.
  small,

  /// 32 high, `body1`. The default.
  medium,

  /// 40 high, `body2`.
  large,
}

/// Which clock the options are written on.
///
/// Upstream's `hourCycle`, and the distinction it draws is real:
/// `h11` and `h23` start at hour **0**, `h12` and `h24` start at hour **1**.
enum FluentHourCycle {
  /// 0-11 with AM/PM. Midnight reads `0:30 AM`.
  h11,

  /// 1-12 with AM/PM. Midnight reads `12:30 AM`. The default here.
  h12,

  /// 00-23. Midnight reads `00:30`.
  h23,

  /// 1-24. Midnight reads `24:30`.
  h24,
}

/// What went wrong when a typed time was validated.
///
/// Upstream's `TimePickerErrorType`, which is a string union there and the same
/// three members here.
enum FluentTimePickerErrorType {
  /// The text is not a time at all.
  invalidInput,

  /// The text parsed but falls outside `startHour`/`endHour`.
  outOfBounds,

  /// The field is required and empty.
  requiredInput,
}

/// The outcome of parsing a typed time.
///
/// `date` is non-null even for [FluentTimePickerErrorType.outOfBounds] —
/// upstream returns the parsed value alongside the error there, and only
/// [FluentTimePickerErrorType.invalidInput] and
/// [FluentTimePickerErrorType.requiredInput] have nothing to report.
@immutable
class FluentTimeStringValidationResult {
  /// Creates a result.
  const FluentTimeStringValidationResult({this.date, this.error});

  /// The parsed time, if the text was a time at all.
  final DateTime? date;

  /// What went wrong, or null.
  final FluentTimePickerErrorType? error;
}

/// What a `FluentTimePicker` reports when its value changes.
@immutable
class FluentTimeSelectionData {
  /// Creates a selection report.
  const FluentTimeSelectionData({
    this.selectedTime,
    this.selectedTimeText,
    this.error,
  });

  /// The chosen time, or null when the text could not be parsed.
  final DateTime? selectedTime;

  /// Exactly what the field held. Non-null even when [selectedTime] is null, so
  /// an application can echo the user's own text back in an error message.
  final String? selectedTimeText;

  /// What went wrong, or null.
  final FluentTimePickerErrorType? error;
}

/// Every time a `FluentTimePicker` offers, in order.
///
/// Public so an application can compute the same list, and so the arithmetic
/// can be tested without pumping a widget.
///
/// [endHour] is **exclusive**. When it does not exceed [startHour] the range
/// wraps past midnight — 20 to 4 is eight hours — and the degenerate
/// `startHour == endHour` reads as a full day, which the same expression gives
/// for free.
///
/// Uses [DateTime.add] on a local date deliberately: it is the one arithmetic
/// that crosses a daylight-saving discontinuity correctly, which matters
/// because a generated list may span midnight.
List<DateTime> fluentTimePickerOptions({
  required DateTime dateAnchor,
  int startHour = 0,
  int endHour = 24,
  int increment = 30,
}) {
  if (increment <= 0) return const <DateTime>[];
  final span = endHour > startHour
      ? endHour - startHour
      : endHour + 24 - startHour;
  final midnight = DateTime(dateAnchor.year, dateAnchor.month, dateAnchor.day);
  final count = span * 60 ~/ increment;
  return <DateTime>[
    for (var i = 0; i < count; i++)
      midnight.add(Duration(hours: startHour, minutes: i * increment)),
  ];
}

/// Renders a time on the given clock.
///
/// There is no `intl` in this package, so the rules upstream delegates to
/// `Intl.DateTimeFormat` are stated here: `h11`/`h23` start at hour 0,
/// `h12`/`h24` start at hour 1, and the 24-hour clocks pad the hour where the
/// 12-hour clocks do not.
String fluentFormatTime(
  DateTime time, {
  FluentHourCycle cycle = FluentHourCycle.h12,
  bool showSeconds = false,
}) {
  final hour24 = time.hour;
  final (int hour, String meridiem) = switch (cycle) {
    FluentHourCycle.h23 => (hour24, ''),
    FluentHourCycle.h24 => (hour24 == 0 ? 24 : hour24, ''),
    FluentHourCycle.h11 => (hour24 % 12, hour24 < 12 ? ' AM' : ' PM'),
    FluentHourCycle.h12 => (
      hour24 % 12 == 0 ? 12 : hour24 % 12,
      hour24 < 12 ? ' AM' : ' PM',
    ),
  };
  final h = meridiem.isEmpty ? hour.toString().padLeft(2, '0') : '$hour';
  final m = time.minute.toString().padLeft(2, '0');
  final s = showSeconds ? ':${time.second.toString().padLeft(2, '0')}' : '';
  return '$h:$m$s$meridiem';
}

final RegExp _timePattern = RegExp(
  r'^(\d{1,2})(?::(\d{1,2}))?(?::(\d{1,2}))?\s*(?:([ap])\.?\s*m?\.?)?$',
  caseSensitive: false,
);

/// Parses a typed time against the day [dateAnchor] falls on.
///
/// Accepts `9`, `9:05`, `9:05:30`, `9 pm`, `9:05 PM`, `9:05p` and `21:05`;
/// rejects `9:75`, `25:00` and anything non-numeric. A time earlier than
/// [dateAnchor]'s own time of day rolls to the next day, which is what makes a
/// range that wraps past midnight parse the way its options read.
FluentTimeStringValidationResult fluentParseTime(
  String text, {
  required DateTime dateAnchor,
  int startHour = 0,
  int endHour = 24,
  bool required = false,
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return FluentTimeStringValidationResult(
      error: required ? FluentTimePickerErrorType.requiredInput : null,
    );
  }
  final match = _timePattern.firstMatch(trimmed);
  if (match == null) {
    return const FluentTimeStringValidationResult(
      error: FluentTimePickerErrorType.invalidInput,
    );
  }

  final meridiem = match.group(4)?.toLowerCase();
  var hour = int.parse(match.group(1)!);
  final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
  final second = int.tryParse(match.group(3) ?? '0') ?? 0;
  if (minute > 59 || second > 59) {
    return const FluentTimeStringValidationResult(
      error: FluentTimePickerErrorType.invalidInput,
    );
  }
  if (meridiem != null) {
    if (hour < 1 || hour > 12) {
      return const FluentTimeStringValidationResult(
        error: FluentTimePickerErrorType.invalidInput,
      );
    }
    if (meridiem == 'p' && hour != 12) hour += 12;
    if (meridiem == 'a' && hour == 12) hour = 0;
  } else {
    if (hour > 24) {
      return const FluentTimeStringValidationResult(
        error: FluentTimePickerErrorType.invalidInput,
      );
    }
    // 24 is midnight on the h24 clock, which is the one place an hour may
    // equal 24 rather than being out of range.
    if (hour == 24) hour = 0;
  }

  final options = fluentTimePickerOptions(
    dateAnchor: dateAnchor,
    startHour: startHour,
    endHour: endHour,
    increment: 60,
  );
  final start = options.isEmpty
      ? DateTime(dateAnchor.year, dateAnchor.month, dateAnchor.day)
      : options.first;
  var parsed = DateTime(
    start.year,
    start.month,
    start.day,
    hour,
    minute,
    second,
  );
  if (parsed.isBefore(start)) parsed = parsed.add(const Duration(days: 1));

  final span = endHour > startHour
      ? endHour - startHour
      : endHour + 24 - startHour;
  final end = start.add(Duration(hours: span));
  if (!parsed.isBefore(end)) {
    return FluentTimeStringValidationResult(
      date: parsed,
      error: FluentTimePickerErrorType.outOfBounds,
    );
  }
  return FluentTimeStringValidationResult(date: parsed);
}

/// Everything needed to render a time picker, independent of its design axes.
@immutable
class FluentTimePickerBaseState {
  /// Creates a base state.
  const FluentTimePickerBaseState({
    required this.enabled,
    required this.readOnly,
    required this.error,
    required this.focused,
    required this.open,
    required this.controller,
    required this.focusNode,
    required this.editableTextKey,
    this.placeholder,
    this.expandIcon,
    this.clearIcon,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// Whether the picker accepts input.
  final bool enabled;

  /// Whether the field refuses edits. True for a non-freeform picker, whose
  /// value can only come from the listbox.
  final bool readOnly;

  /// Whether to paint the danger ramp.
  final bool error;

  /// Whether the field holds focus.
  ///
  /// A field on the state rather than a [WidgetState], because
  /// [WidgetState.focused] means *keyboard-visible* focus in this package and
  /// the brand bar has to appear on a click too.
  final bool focused;

  /// Whether the listbox is showing.
  final bool open;

  /// The field's text.
  final TextEditingController controller;

  /// The field's focus node.
  final FocusNode focusNode;

  /// Key of the underlying [EditableText].
  final GlobalKey<EditableTextState> editableTextKey;

  /// Shown while the field is empty.
  final Widget? placeholder;

  /// The chevron that opens the listbox.
  final Widget? expandIcon;

  /// The glyph that clears the value, or null when there is nothing to clear.
  final Widget? clearIcon;

  /// Called on every keystroke.
  final ValueChanged<String>? onChanged;

  /// Called when the field is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Accessible name of the picker.
  final String? semanticLabel;
}

/// A time picker's fully resolved state, including the design axes.
@immutable
class FluentTimePickerState extends FluentTimePickerBaseState {
  /// Creates a state.
  const FluentTimePickerState({
    required super.enabled,
    required super.readOnly,
    required super.error,
    required super.focused,
    required super.open,
    required super.controller,
    required super.focusNode,
    required super.editableTextKey,
    required this.appearance,
    required this.size,
    super.placeholder,
    super.expandIcon,
    super.clearIcon,
    super.onChanged,
    super.onSubmitted,
    super.autofocus,
    super.semanticLabel,
  });

  /// Colours and borders of the faceplate.
  final FluentTimePickerAppearance appearance;

  /// Height and type ramp of the faceplate.
  final FluentTimePickerSize size;
}

/// Assembles a [FluentTimePickerState].
///
/// The first of the three-function recomposition contract.
FluentTimePickerState resolveFluentTimePickerState({
  required TextEditingController controller,
  required FocusNode focusNode,
  required GlobalKey<EditableTextState> editableTextKey,
  bool enabled = true,
  bool readOnly = true,
  bool error = false,
  bool focused = false,
  bool open = false,
  FluentTimePickerAppearance appearance = FluentTimePickerAppearance.outline,
  FluentTimePickerSize size = FluentTimePickerSize.medium,
  Widget? placeholder,
  Widget? expandIcon,
  Widget? clearIcon,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onSubmitted,
  bool autofocus = false,
  String? semanticLabel,
}) => FluentTimePickerState(
  enabled: enabled,
  readOnly: readOnly,
  error: error,
  focused: focused,
  open: open,
  controller: controller,
  focusNode: focusNode,
  editableTextKey: editableTextKey,
  appearance: appearance,
  size: size,
  placeholder: placeholder,
  expandIcon: expandIcon,
  clearIcon: clearIcon,
  onChanged: onChanged,
  onSubmitted: onSubmitted,
  autofocus: autofocus,
  semanticLabel: semanticLabel,
);

FluentInputAppearance _inputAppearance(FluentTimePickerAppearance value) =>
    switch (value) {
      FluentTimePickerAppearance.outline => FluentInputAppearance.outline,
      FluentTimePickerAppearance.underline => FluentInputAppearance.underline,
      FluentTimePickerAppearance.filledDarker =>
        FluentInputAppearance.filledDarker,
      FluentTimePickerAppearance.filledLighter =>
        FluentInputAppearance.filledLighter,
    };

FluentInputSize _inputSize(FluentTimePickerSize value) => switch (value) {
  FluentTimePickerSize.small => FluentInputSize.small,
  FluentTimePickerSize.medium => FluentInputSize.medium,
  FluentTimePickerSize.large => FluentInputSize.large,
};

/// Derives the default style for [state] from [theme].
///
/// The second of the three-function recomposition contract, and the only place
/// the design axes are read.
///
/// The faceplate is **derived from `resolveFluentInputStyle`** rather than
/// re-transcribing Figma's Input variants, so the two components cannot drift.
///
/// ## The read-only trap
///
/// `resolveFluentInputStyle` folds `readOnly` into the disabled ramp — it takes
/// `inert = disabled || readOnly` and paints a read-only field on
/// `transparentBackground` with a `neutralStrokeDisabled` border. That column
/// is Figma's alone; upstream ships `readOnly` as a bare attribute with no
/// styling at all.
///
/// A non-freeform time picker is read-only by definition, so handing the real
/// flag to the style resolver would render **every default picker looking
/// disabled**. The field is therefore resolved with `readOnly: false` and the
/// real value is passed only to the renderer, where it stops the caret and the
/// edits. React wins on behaviour.
FluentTimePickerStyle resolveFluentTimePickerStyle(
  FluentTimePickerState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final field = resolveFluentInputStyle(
    resolveFluentInputState(
      controller: state.controller,
      focusNode: state.focusNode,
      editableTextKey: state.editableTextKey,
      enabled: state.enabled,
      // Deliberately not `state.readOnly`. See the doc comment above.
      error: state.error,
      focused: state.focused,
      appearance: _inputAppearance(state.appearance),
      size: _inputSize(state.size),
    ),
    theme,
  );

  return FluentTimePickerStyle(
    backgroundColor: field.backgroundColor,
    borderColor: field.borderColor,
    borderWidth: field.borderWidth,
    borderRadius: field.borderRadius,
    underlineColor: field.bottomBorderColor,
    underlineWidth: field.bottomBorderWidth,
    accentColor: field.focusUnderlineColor,
    accentWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thick),
    foregroundColor: field.foregroundColor,
    placeholderColor: field.placeholderColor,
    textStyle: field.textStyle,
    padding: field.padding,
    minimumSize: field.minimumSize,
    mouseCursor: field.mouseCursor,
    iconColor: field.contentColor,
    iconSize: field.iconSize,
    trailingGap: const WidgetStatePropertyAll<double?>(FluentSpacing.xxs),
    trailingPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.zero,
    ),
    surfaceColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    surfaceBorderColor: FluentStateColor.tokens(rest: c.transparentStroke),
    surfaceBorderWidth: const WidgetStatePropertyAll<double?>(
      FluentStroke.thin,
    ),
    surfaceRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    surfacePadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.all(FluentSpacing.xs),
    ),
    surfaceGap: const WidgetStatePropertyAll<double?>(FluentSpacing.xxs),
    surfaceShadow: WidgetStatePropertyAll<List<BoxShadow>?>(
      theme.shadow(FluentElevation.shadow16),
    ),
    // `min(80vh, 416px)` upstream — 416 is twelve rows plus the surface inset,
    // and it is the only number `useTimePickerStyles` contributes on top of
    // Combobox.
    surfaceMaxHeight: const WidgetStatePropertyAll<double?>(416),
    surfaceOffset: const WidgetStatePropertyAll<double?>(FluentSpacing.xxs),
  );
}

/// The [FluentInputStyle] the faceplate is drawn with.
FluentInputStyle _fieldStyle(FluentTimePickerStyle style) => FluentInputStyle(
  backgroundColor: style.backgroundColor,
  borderColor: style.borderColor,
  borderWidth: style.borderWidth,
  borderRadius: style.borderRadius,
  bottomBorderColor: style.underlineColor,
  bottomBorderWidth: style.underlineWidth,
  focusUnderlineColor: style.accentColor,
  foregroundColor: style.foregroundColor,
  placeholderColor: style.placeholderColor,
  contentColor: style.iconColor,
  textStyle: style.textStyle,
  padding: style.padding,
  contentPadding: style.trailingPadding,
  gap: style.trailingGap,
  iconSize: style.iconSize,
  minimumSize: style.minimumSize,
  mouseCursor: style.mouseCursor,
);

/// The chevron a closed time picker draws.
const IconData fluentTimePickerChevron = FluentIcons.chevron_down_20_regular;

/// The glyph a clearable time picker draws once it has a value.
const IconData fluentTimePickerClear = FluentIcons.dismiss_20_regular;

/// Renders a time picker's faceplate from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentTimePickerBaseState] on purpose: it never reads the appearance or the
/// size, so a consumer can supply their own style and still use Fluent's
/// layout, trailing slot and focus underline.
Widget buildFluentTimePicker(
  FluentTimePickerBaseState state,
  FluentTimePickerStyle style,
  Set<WidgetState> states,
) {
  final gap = style.trailingGap?.resolve(states) ?? FluentSpacing.xxs;
  return buildFluentInput(
    FluentInputBaseState(
      enabled: state.enabled,
      // The REAL value here, unlike in the style resolver: no caret, no edits.
      readOnly: state.readOnly,
      error: state.error,
      focused: state.focused,
      controller: state.controller,
      focusNode: state.focusNode,
      editableTextKey: state.editableTextKey,
      placeholder: state.placeholder,
      contentAfter: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: gap,
        children: <Widget>[
          if (state.clearIcon != null) state.clearIcon!,
          if (state.expandIcon != null) state.expandIcon!,
        ],
      ),
      onChanged: state.onChanged,
      onSubmitted: state.onSubmitted,
      autofocus: state.autofocus,
    ),
    _fieldStyle(style),
    states,
  );
}

/// Renders the listbox surface around [child].
///
/// Public because `expectGolden` never captures overlay content, so the golden
/// for the open state has to render the surface directly — the same workaround
/// `buildFluentDropdownSurface` exists for.
Widget buildFluentTimePickerSurface(
  FluentTimePickerStyle style,
  Set<WidgetState> states,
  Widget child,
) {
  final radius = style.surfaceRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth =
      style.surfaceBorderWidth?.resolve(states) ?? FluentStroke.thin;
  final borderColor = style.surfaceBorderColor?.resolve(states);
  return DecoratedBox(
    decoration: BoxDecoration(
      color: style.surfaceColor?.resolve(states),
      borderRadius: radius,
      border: borderColor == null || borderWidth <= 0
          ? null
          : Border.all(color: borderColor, width: borderWidth),
      boxShadow: style.surfaceShadow?.resolve(states),
    ),
    child: Padding(
      padding: style.surfacePadding?.resolve(states) ?? EdgeInsets.zero,
      child: child,
    ),
  );
}

/// Overrides the time picker style for a subtree.
class FluentTimePickerTheme extends InheritedTheme {
  /// Applies [style] to every [FluentTimePicker] in [child].
  const FluentTimePickerTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the theme defaults.
  final FluentTimePickerStyle style;

  /// The nearest time picker style, or null.
  static FluentTimePickerStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentTimePickerTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentTimePickerTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentTimePickerTheme(style: style, child: child);
}

/// Moves the active option in an open time picker listbox.
class FluentTimePickerMoveIntent extends Intent {
  /// Creates a move of [delta] rows.
  const FluentTimePickerMoveIntent(this.delta);

  /// How many rows to move, signed.
  final int delta;
}

/// Jumps the active option to the first or last row.
class FluentTimePickerEdgeIntent extends Intent {
  /// Creates a jump. [last] selects the end rather than the start.
  const FluentTimePickerEdgeIntent({required this.last});

  /// Whether to jump to the last row.
  final bool last;
}

/// Commits the active option, or the typed text in a freeform picker.
class FluentTimePickerActivateIntent extends Intent {
  /// Creates a commit.
  const FluentTimePickerActivateIntent();
}

/// Places the caret *and* toggles the listbox on a tap.
///
/// Subclassed rather than nesting a second [GestureDetector]: two competing
/// recognisers on the same field would make a tap either move the caret or open
/// the popup, never both, and a freeform picker needs both.
class _TimePickerGestures extends TextSelectionGestureDetectorBuilder {
  _TimePickerGestures(this._owner) : super(delegate: _owner);

  final _FluentTimePickerState _owner;

  @override
  void onSingleTapUp(TapDragUpDetails details) {
    super.onSingleTapUp(details);
    _owner._handleFieldTap();
  }
}

/// A combobox of times, with optional freeform entry.
///
/// Selection is **controlled**: [selectedTime] is the truth and the picker
/// never mutates it. A null [onTimeChange] disables the whole control.
///
/// Structurally this is `FluentTagPicker`'s shape — an editable field with a
/// listbox in an [Overlay] — because upstream's TimePicker is a Combobox. It
/// deliberately does **not** introduce a public `FluentCombobox`; that gap is
/// still open in the coverage matrix.
///
/// ## Keyboard
///
/// What is bound matters less than what is not. `Space` types a space, so a
/// user can write `12 PM`; `Backspace` deletes a character; `Home` and `End`
/// move the caret whenever the picker is [freeform], and only jump the listbox
/// when it is not. Each of those falls through by reporting `isEnabled: false`
/// rather than doing nothing, which is what lets
/// `DefaultTextEditingShortcuts` see the key.
///
/// | Key | Effect |
/// |---|---|
/// | Down / Up | open on the first or last row, or move the active row |
/// | Home / End | jump the listbox — only when not freeform |
/// | Enter | commit the active row, or the typed text |
/// | Escape | close and revert |
///
/// Transcribed from `@fluentui/react-timepicker-compat` 0.4.37 over
/// `@fluentui/react-combobox` 9.17.4.
class FluentTimePicker extends StatefulWidget {
  /// Creates a time picker.
  const FluentTimePicker({
    super.key,
    this.selectedTime,
    this.onTimeChange,
    this.hourCycle = FluentHourCycle.h12,
    this.showSeconds = false,
    this.startHour = 0,
    this.endHour = 24,
    this.increment = 30,
    this.dateAnchor,
    this.freeform = false,
    this.clearable = false,
    this.required = false,
    this.error = false,
    this.open,
    this.defaultOpen = false,
    this.onOpenChange,
    this.formatTime,
    this.parseTime,
    this.appearance = FluentTimePickerAppearance.outline,
    this.size = FluentTimePickerSize.medium,
    this.placeholder,
    this.focusNode,
    this.autofocus = false,
    this.style,
    this.optionStyle,
    this.semanticLabel,
    this.clearSemanticLabel = 'Clear',
    this.expandSemanticLabel = 'Open',
  });

  /// The chosen time. Null selects nothing.
  final DateTime? selectedTime;

  /// Called when the value changes. Null disables the picker.
  final ValueChanged<FluentTimeSelectionData>? onTimeChange;

  /// Which clock the options are written on.
  final FluentHourCycle hourCycle;

  /// Whether options and validation carry seconds.
  final bool showSeconds;

  /// First hour offered, inclusive.
  final int startHour;

  /// Last hour offered, **exclusive**.
  final int endHour;

  /// Minutes between options.
  final int increment;

  /// The day every option is built on. Defaults to [selectedTime], then to the
  /// clock at mount — captured once, so the option list is stable.
  final DateTime? dateAnchor;

  /// Whether the field accepts typed times.
  final bool freeform;

  /// Whether to offer a glyph that clears the value.
  final bool clearable;

  /// Whether an empty field is an error.
  final bool required;

  /// Whether to paint the danger ramp. Set it directly when an application does
  /// its own validation.
  final bool error;

  /// Whether the listbox is showing. Null leaves it uncontrolled.
  final bool? open;

  /// The listbox's open state at mount, when [open] is null.
  final bool defaultOpen;

  /// Called whenever the listbox opens or closes.
  final ValueChanged<bool>? onOpenChange;

  /// Renders an option and the field's own text.
  final String Function(DateTime time)? formatTime;

  /// Parses typed text. Returns the parsed time *and* any error, so an
  /// application can supply its own validation the way upstream does.
  final FluentTimeStringValidationResult Function(String text)? parseTime;

  /// Colours and borders of the faceplate.
  final FluentTimePickerAppearance appearance;

  /// Height and type ramp of the faceplate.
  final FluentTimePickerSize size;

  /// Shown while the field is empty.
  final Widget? placeholder;

  /// Focus node for the field.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Overrides layered over the resolved defaults.
  final FluentTimePickerStyle? style;

  /// Overrides for the listbox rows.
  final FluentDropdownOptionStyle? optionStyle;

  /// Accessible name of the picker.
  final String? semanticLabel;

  /// Accessible name of the clear glyph.
  final String clearSemanticLabel;

  /// Accessible name of the expand chevron.
  final String expandSemanticLabel;

  @override
  State<FluentTimePicker> createState() => _FluentTimePickerState();
}

class _FluentTimePickerState extends State<FluentTimePicker>
    implements TextSelectionGestureDetectorBuilderDelegate {
  final LayerLink _link = LayerLink();
  final Map<int, GlobalKey> _rowKeys = <int, GlobalKey>{};
  late final _TimePickerGestures _gestures = _TimePickerGestures(this);

  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => _enabled && widget.freeform;

  late final TextEditingController _controller = TextEditingController(
    text: _format(widget.selectedTime),
  );
  late final DateTime _fallbackAnchor = DateTime.now();

  FocusNode? _internalNode;
  OverlayEntry? _entry;
  int? _active;
  bool _uncontrolledOpen = false;
  bool _focused = false;
  String? _committedText;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalNode ??= FocusNode());

  bool get _enabled => widget.onTimeChange != null;

  bool get _open => widget.open ?? _uncontrolledOpen;

  DateTime get _anchor =>
      widget.dateAnchor ?? widget.selectedTime ?? _fallbackAnchor;

  String _format(DateTime? time) => time == null
      ? ''
      : (widget.formatTime ??
            (DateTime value) => fluentFormatTime(
              value,
              cycle: widget.hourCycle,
              showSeconds: widget.showSeconds,
            ))(time);

  List<DateTime> get _options => fluentTimePickerOptions(
    dateAnchor: _anchor,
    startHour: widget.startHour,
    endHour: widget.endHour,
    increment: widget.increment,
  );

  @override
  void initState() {
    super.initState();
    _uncontrolledOpen = widget.defaultOpen;
    _committedText = _controller.text;
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(FluentTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _internalNode?.removeListener(_handleFocusChange);
      _focusNode.addListener(_handleFocusChange);
    }
    if (widget.selectedTime != oldWidget.selectedTime) {
      final text = _format(widget.selectedTime);
      _controller.text = text;
      _committedText = text;
    }
    _syncEntry();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _entry?.remove();
    _entry = null;
    _controller.dispose();
    _internalNode?.dispose();
    super.dispose();
  }

  /// Inserting or removing an [OverlayEntry] is a `setState` on the [Overlay],
  /// which is illegal while the framework is already building.
  void _deferOrRun(VoidCallback action) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) action();
      });
      return;
    }
    action();
  }

  void _handleFocusChange() {
    final focused = _focusNode.hasFocus;
    if (focused == _focused) return;
    setState(() => _focused = focused);
    if (!focused) {
      _commitText();
      _deferOrRun(() => _setOpen(next: false));
    }
  }

  void _handleFieldTap() {
    if (!_enabled) return;
    _setOpen(next: !_open);
  }

  void _setOpen({required bool next}) {
    if (next == _open) return;
    if (widget.open == null) {
      setState(() => _uncontrolledOpen = next);
    }
    widget.onOpenChange?.call(next);
    if (next) {
      final options = _options;
      final selected = widget.selectedTime;
      _active = selected == null
          ? 0
          : options
                .indexWhere((option) => option == selected)
                .clamp(0, options.isEmpty ? 0 : options.length - 1);
    } else {
      _active = null;
    }
    _deferOrRun(_syncEntry);
  }

  void _syncEntry() {
    if (!mounted) return;
    final shouldShow = _open && _enabled;
    if (shouldShow && _entry == null) {
      final overlay = Overlay.of(context, debugRequiredFor: widget);
      final captured = InheritedTheme.capture(
        from: context,
        to: overlay.context,
      );
      _entry = OverlayEntry(builder: (_) => captured.wrap(_buildPopup()));
      overlay.insert(_entry!);
    } else if (!shouldShow && _entry != null) {
      _entry!.remove();
      _entry = null;
    }
    _entry?.markNeedsBuild();
    if (mounted) setState(() {});
  }

  void _moveActive(int delta) {
    final options = _options;
    if (options.isEmpty) return;
    if (!_open) {
      _setOpen(next: true);
      _active = delta > 0 ? 0 : options.length - 1;
    } else {
      final from = _active ?? (delta > 0 ? -1 : options.length);
      _active = (from + delta).clamp(0, options.length - 1);
    }
    _scrollActiveIntoView();
    _entry?.markNeedsBuild();
    setState(() {});
  }

  void _edge({required bool last}) {
    final options = _options;
    if (options.isEmpty) return;
    _active = last ? options.length - 1 : 0;
    _scrollActiveIntoView();
    _entry?.markNeedsBuild();
    setState(() {});
  }

  void _scrollActiveIntoView() {
    final index = _active;
    if (index == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _rowKeys[index]?.currentContext;
      if (target != null) Scrollable.ensureVisible(target, alignment: 0.5);
    });
  }

  void _select(DateTime time) {
    final text = _format(time);
    _controller.text = text;
    _committedText = text;
    widget.onTimeChange?.call(
      FluentTimeSelectionData(selectedTime: time, selectedTimeText: text),
    );
    _setOpen(next: false);
  }

  /// Commits typed text, mirroring a browser's `change` event: on blur and on
  /// Enter, never per keystroke, and only when the text actually moved.
  void _commitText() {
    if (!_enabled || !widget.freeform) return;
    final text = _controller.text;
    if (text == _committedText) return;
    _committedText = text;
    final result =
        (widget.parseTime ??
        (String value) => fluentParseTime(
          value,
          dateAnchor: _anchor,
          startHour: widget.startHour,
          endHour: widget.endHour,
          required: widget.required,
        ))(text);
    // The text is deliberately left alone when it does not parse. That is what
    // a native text input does on change, and it is the opposite of
    // FluentSpinButton, which snaps its value back.
    widget.onTimeChange?.call(
      FluentTimeSelectionData(
        selectedTime: result.error == FluentTimePickerErrorType.invalidInput
            ? null
            : result.date,
        selectedTimeText: text,
        error: result.error,
      ),
    );
  }

  void _activate() {
    final index = _active;
    final options = _options;
    if (_open && index != null && index >= 0 && index < options.length) {
      _select(options[index]);
      return;
    }
    if (!_open) {
      if (widget.freeform && _controller.text != _committedText) {
        _commitText();
      } else {
        _setOpen(next: true);
      }
      return;
    }
    _commitText();
    _setOpen(next: false);
  }

  void _clear() {
    _controller.clear();
    _committedText = '';
    widget.onTimeChange?.call(
      const FluentTimeSelectionData(selectedTimeText: ''),
    );
    // Focus returns to the field so the user can keep typing, and the popup is
    // left exactly as it was — clearing is not a toggle.
    _focusNode.requestFocus();
    setState(() {});
  }

  FluentTimePickerStyle _resolvedStyle(BuildContext context) =>
      resolveFluentTimePickerStyle(
        resolveFluentTimePickerState(
          controller: _controller,
          focusNode: _focusNode,
          editableTextKey: editableTextKey,
          enabled: _enabled,
          readOnly: !widget.freeform,
          error: widget.error,
          focused: _focused,
          open: _open,
          appearance: widget.appearance,
          size: widget.size,
        ),
        FluentTheme.of(context),
      ).merge(FluentTimePickerTheme.maybeOf(context)).merge(widget.style);

  Widget _buildPopup() {
    final style = _resolvedStyle(context);
    final states = <WidgetState>{if (!_enabled) WidgetState.disabled};
    final theme = FluentTheme.of(context);
    final options = _options;
    final offset = style.surfaceOffset?.resolve(states) ?? FluentSpacing.xxs;
    final maxHeight = style.surfaceMaxHeight?.resolve(states) ?? 416;
    final gap = style.surfaceGap?.resolve(states) ?? FluentSpacing.xxs;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _setOpen(next: false),
          ),
        ),
        Positioned(
          width: _link.leaderSize?.width,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: Offset(0, offset),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: 160,
                  maxHeight: maxHeight,
                ),
                // Focus never enters the popup: the field keeps it and the
                // active row is marked instead, which is the combobox model.
                child: ExcludeFocus(
                  child: buildFluentTimePickerSurface(
                    style,
                    states,
                    ValueListenableBuilder<bool>(
                      valueListenable: FluentInputModality.keyboard,
                      builder: (context, keyboard, _) => SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          spacing: gap,
                          children: <Widget>[
                            for (var i = 0; i < options.length; i++)
                              _buildRow(
                                theme,
                                options[i],
                                i,
                                keyboard: keyboard,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(
    FluentThemeData theme,
    DateTime option,
    int index, {
    required bool keyboard,
  }) {
    final selected = widget.selectedTime == option;
    final optionState = resolveFluentDropdownOptionState(
      label: Text(_format(option)),
      selected: selected,
    );
    final optionStyle = resolveFluentDropdownOptionStyle(optionState, theme)
        .merge(FluentDropdownOptionTheme.maybeOf(context))
        .merge(widget.optionStyle);

    return KeyedSubtree(
      key: _rowKeys.putIfAbsent(index, GlobalKey.new),
      child: FluentInteractive(
        onPressed: () => _select(option),
        builder: (context, states, child) => buildFluentDropdownOption(
          optionState,
          optionStyle,
          <WidgetState>{
            ...states,
            // The framework's focus never leaves the field, so the active row's
            // ring is synthesised — and gated on the keyboard modality, exactly
            // as the Dropdown and TagPicker do.
            if (index == _active && keyboard) WidgetState.focused,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolvedStyle(context);
    final states = <WidgetState>{
      if (!_enabled) WidgetState.disabled,
      if (_focused) WidgetState.focused,
    };
    final iconColor = style.iconColor?.resolve(states);
    final iconSize = style.iconSize?.resolve(states);
    final showClear =
        widget.clearable &&
        _enabled &&
        (widget.selectedTime != null || _controller.text.isNotEmpty);

    final field = buildFluentTimePicker(
      resolveFluentTimePickerState(
        controller: _controller,
        focusNode: _focusNode,
        editableTextKey: editableTextKey,
        enabled: _enabled,
        readOnly: !widget.freeform,
        error: widget.error,
        focused: _focused,
        open: _open,
        appearance: widget.appearance,
        size: widget.size,
        placeholder: widget.placeholder,
        autofocus: widget.autofocus,
        expandIcon: Semantics(
          button: true,
          label: widget.expandSemanticLabel,
          child: Icon(
            fluentTimePickerChevron,
            size: iconSize,
            color: iconColor,
          ),
        ),
        clearIcon: showClear
            ? _ClearButton(
                semanticLabel: widget.clearSemanticLabel,
                iconColor: iconColor,
                iconSize: iconSize,
                onPressed: _clear,
              )
            : null,
      ),
      style,
      states,
    );

    return Semantics(
      label: widget.semanticLabel,
      textField: true,
      expanded: _open,
      child: CompositedTransformTarget(
        link: _link,
        child: Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.arrowDown):
                FluentTimePickerMoveIntent(1),
            SingleActivator(LogicalKeyboardKey.arrowUp):
                FluentTimePickerMoveIntent(-1),
            SingleActivator(LogicalKeyboardKey.home):
                FluentTimePickerEdgeIntent(last: false),
            SingleActivator(LogicalKeyboardKey.end): FluentTimePickerEdgeIntent(
              last: true,
            ),
            SingleActivator(LogicalKeyboardKey.enter):
                FluentTimePickerActivateIntent(),
            SingleActivator(LogicalKeyboardKey.numpadEnter):
                FluentTimePickerActivateIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              FluentTimePickerMoveIntent:
                  CallbackAction<FluentTimePickerMoveIntent>(
                    onInvoke: (intent) {
                      _moveActive(intent.delta);
                      return null;
                    },
                  ),
              FluentTimePickerEdgeIntent: _EdgeAction(this),
              FluentTimePickerActivateIntent:
                  CallbackAction<FluentTimePickerActivateIntent>(
                    onInvoke: (_) {
                      _activate();
                      return null;
                    },
                  ),
              DismissIntent: _DismissTimePickerAction(this),
            },
            child: _gestures.buildGestureDetector(child: field),
          ),
        ),
      ),
    );
  }
}

/// Jumps the listbox — but only when the field is not freeform.
///
/// Reporting `isEnabled: false` rather than doing nothing is what lets Home and
/// End fall through to `DefaultTextEditingShortcuts` and move the caret, which
/// is what a field accepting typed text has to do.
class _EdgeAction extends Action<FluentTimePickerEdgeIntent> {
  _EdgeAction(this.state);

  final _FluentTimePickerState state;

  @override
  bool isEnabled(FluentTimePickerEdgeIntent intent) =>
      state._open && !state.widget.freeform;

  @override
  Object? invoke(FluentTimePickerEdgeIntent intent) {
    state._edge(last: intent.last);
    return null;
  }
}

/// Closes the listbox and reverts the text.
///
/// Gated on the listbox being open so Escape still reaches an ancestor — a
/// dialog, a popover — when the picker is closed.
class _DismissTimePickerAction extends Action<DismissIntent> {
  _DismissTimePickerAction(this.state);

  final _FluentTimePickerState state;

  @override
  bool isEnabled(DismissIntent intent) => state._open;

  @override
  Object? invoke(DismissIntent intent) {
    state._controller.text = state._format(state.widget.selectedTime);
    state._committedText = state._controller.text;
    state._setOpen(next: false);
    return null;
  }
}

/// The clear glyph, on a node that never takes traversal focus.
class _ClearButton extends StatelessWidget {
  const _ClearButton({
    required this.semanticLabel,
    required this.iconColor,
    required this.iconSize,
    required this.onPressed,
  });

  final String semanticLabel;
  final Color? iconColor;
  final double? iconSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    child: GestureDetector(
      // Opaque so the tap never reaches the faceplate's own toggle: clearing
      // must not also open or close the listbox.
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: Icon(fluentTimePickerClear, size: iconSize, color: iconColor),
    ),
  );
}
