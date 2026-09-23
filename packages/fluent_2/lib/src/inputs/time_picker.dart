import 'dart:async';
import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/gestures.dart'
    show
        PointerDeviceKind,
        TapDragDownDetails,
        TapDragStartDetails,
        TapDragUpDetails,
        TapDragUpdateDetails,
        kMiddleMouseButton,
        kSecondaryMouseButton;
import 'package:flutter/services.dart'
    show LogicalKeyboardKey, SelectionChangedCause;
import 'package:flutter/widgets.dart';

import '../internal/anchor_metrics.dart';
import '../internal/defer.dart';
import '../internal/input_modality.dart';
import '../internal/interaction.dart';
import '../internal/tap_group.dart';
import '../internal/text_selection_dismiss.dart';
import '../l10n/l10n.dart';
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

  /// 1-12 with AM/PM. Midnight reads `12:30 AM`. What a picker with no
  /// cycle writes, as upstream's en-US locale does.
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

// Upstream's four `REGEX_*_HOUR_*` patterns and its part reader, verbatim.
final RegExp _time12 = RegExp(r'^((1[0-2]|0?[0-9]):[0-5][0-9]\s([AaPp][Mm]))$');
final RegExp _time12Seconds = RegExp(
  r'^((1[0-2]|0?[0-9]):([0-5][0-9]):([0-5][0-9])\s([AaPp][Mm]))$',
);
final RegExp _time24 = RegExp(r'^([0-1]?[0-9]|2[0-4]):[0-5][0-9]$');
final RegExp _time24Seconds = RegExp(
  r'^([0-1]?[0-9]|2[0-4]):[0-5][0-9]:[0-5][0-9]$',
);
final RegExp _timeParts = RegExp(
  r'^(\d\d?):(\d\d):?(\d\d)? ?([ap]m)?',
  caseSensitive: false,
);

/// Parses a typed time against the day [dateAnchor] falls on.
///
/// Upstream's `getDateFromTimeString`, strict as it is: the text must read
/// exactly as [hourCycle] and [showSeconds] would write it. On
/// [FluentHourCycle.h11] and [FluentHourCycle.h12] that is `9:05 PM`, AM or PM
/// after one space; otherwise, and with no [hourCycle] at all, it is `9:05` or
/// `21:05`, hours up to 24. `9`, `9:5`, a stray space and anything
/// non-numeric are [FluentTimePickerErrorType.invalidInput]. A time earlier
/// than [startHour] rolls to the next day, which is what makes a range that
/// wraps past midnight parse the way its options read; `24:00` is the next
/// midnight.
FluentTimeStringValidationResult fluentParseTime(
  String text, {
  required DateTime dateAnchor,
  int startHour = 0,
  int endHour = 24,
  bool required = false,
  FluentHourCycle? hourCycle,
  bool showSeconds = false,
}) {
  if (text.isEmpty) {
    return FluentTimeStringValidationResult(
      error: required ? FluentTimePickerErrorType.requiredInput : null,
    );
  }
  final hour12 =
      hourCycle == FluentHourCycle.h11 || hourCycle == FluentHourCycle.h12;
  final pattern = hour12
      ? (showSeconds ? _time12Seconds : _time12)
      : (showSeconds ? _time24Seconds : _time24);
  final match = pattern.hasMatch(text) ? _timeParts.firstMatch(text) : null;
  if (match == null) {
    return const FluentTimeStringValidationResult(
      error: FluentTimePickerErrorType.invalidInput,
    );
  }

  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final second = int.tryParse(match.group(3) ?? '') ?? 0;
  final meridiem = match.group(4)?.toLowerCase();
  if (hour12 && meridiem == 'pm' && hour != 12) hour += 12;
  if (hour12 && meridiem == 'am' && hour == 12) hour = 0;

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

  /// Whether the field refuses edits.
  ///
  /// `FluentTimePicker` never sets it: upstream's picker is an editable
  /// `<input>` whether or not it is freeform, and a non-freeform one types
  /// ahead to an option.
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
  bool readOnly = false,
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
/// The faceplate's fill, type and size ramps are **derived from
/// `resolveFluentInputStyle`** rather than re-transcribed, so the two
/// components cannot drift where upstream shares them. The borders are not:
/// upstream's TimePicker is a `.fui-Combobox`, and `useComboboxStyles` differs
/// from `useInputStyles` in ways that render, as measured in Chrome:
///
/// * **Hover beats focus.** `outlineInteractive` writes `:focus-within` as a
///   rule of its own, which Griffel sorts before `:hover`, so a focused,
///   hovered picker shows the Hover stops. Input writes `:active,:focus-within`
///   as one rule and keeps Pressed.
/// * **Only Outline ramps.** Underline's bottom border stays
///   `colorNeutralStrokeAccessible` in every state, and the filled appearances
///   keep `colorTransparentStroke`; Combobox has no `underlineInteractive` or
///   `filledInteractive`.
/// * **The bar keeps its own 4px radii** on Underline, and overhangs the
///   borderless root by a pixel each side; see [buildFluentTimePicker].
///
/// Read-only costs nothing here: upstream ships no read-only styling, so a
/// read-only picker wears the live ramp.
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
      readOnly: state.readOnly,
      error: state.error,
      focused: state.focused,
      appearance: _inputAppearance(state.appearance),
      size: _inputSize(state.size),
    ),
    theme,
  );

  final disabled = !state.enabled;
  final focused = state.focused;
  final underline = state.appearance == FluentTimePickerAppearance.underline;
  final filled =
      state.appearance == FluentTimePickerAppearance.filledDarker ||
      state.appearance == FluentTimePickerAppearance.filledLighter;
  // `colorPaletteRedBorder2`, with the high-contrast guard
  // `resolveFluentInputStyle` uses.
  final danger = c is FluentHighContrastColors
      ? c.statusDangerBorder2
      : c.palette.stroke2Rest(FluentPaletteFamily.red)!;

  // `invalid` is written under `:not(:focus-within),:hover:not(:focus-within)`,
  // so a focused invalid picker falls back to the ordinary ramp — and, since
  // `useComboboxStyles` keeps the class on a disabled picker and that selector
  // out-specifies `disabled`'s plain class, a disabled invalid one stays red.
  final WidgetStateProperty<Color>? border;
  if (underline) {
    border = null;
  } else if (state.error && !focused) {
    border = FluentStateColor.tokens(rest: danger);
  } else if (disabled) {
    border = FluentStateColor.tokens(rest: c.neutralStrokeDisabled);
  } else if (filled) {
    border = FluentStateColor.tokens(rest: c.transparentStroke);
  } else {
    // Hover wins over focus: see the doc comment.
    border = FluentStateColor.tokens(
      rest: focused ? c.neutralStroke1Pressed : c.neutralStroke1,
      hover: c.neutralStroke1Hover,
      pressed: c.neutralStroke1Pressed,
    );
  }

  final WidgetStateProperty<Color>? bottomBorder;
  if (filled) {
    bottomBorder = null;
  } else if (state.error && !focused) {
    bottomBorder = FluentStateColor.tokens(rest: danger);
  } else if (disabled) {
    bottomBorder = FluentStateColor.tokens(rest: c.neutralStrokeDisabled);
  } else if (underline) {
    bottomBorder = FluentStateColor.tokens(rest: c.neutralStrokeAccessible);
  } else {
    bottomBorder = FluentStateColor.tokens(
      rest: focused
          ? c.neutralStrokeAccessiblePressed
          : c.neutralStrokeAccessible,
      hover: c.neutralStrokeAccessibleHover,
      pressed: c.neutralStrokeAccessiblePressed,
    );
  }

  // The `<input>`'s `padding-left` is SNudge / MNudge / M plus XXS / XXS /
  // SNudge, of which the root padding [FluentInputStyle.padding] already holds
  // the first; the field carries the rest. Between it and the chevron sit the
  // root's `columnGap` and the chevron's `marginLeft`, the same XXS / XXS /
  // SNudge each.
  final nudge = switch (state.size) {
    FluentTimePickerSize.small ||
    FluentTimePickerSize.medium => FluentSpacing.xxs,
    FluentTimePickerSize.large => FluentSpacing.sNudge,
  };
  final height = field.minimumSize?.resolve(const <WidgetState>{})?.height;

  return FluentTimePickerStyle(
    backgroundColor: field.backgroundColor,
    borderColor: border,
    borderWidth: field.borderWidth,
    borderRadius: field.borderRadius,
    underlineColor: bottomBorder,
    underlineWidth: field.bottomBorderWidth,
    accentColor: field.focusUnderlineColor,
    accentWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thick),
    foregroundColor: field.foregroundColor,
    placeholderColor: field.placeholderColor,
    textStyle: field.textStyle,
    padding: field.padding,
    // `.fui-Combobox` root: `minWidth: 250px`, beside Input's heights.
    minimumSize: WidgetStatePropertyAll<Size?>(Size(250, height ?? 0)),
    mouseCursor: field.mouseCursor,
    // `useComboboxStyles` icon: `colorNeutralStrokeAccessible`, not Input's
    // `colorNeutralForeground3` slot tone — the same in light and dark, apart
    // in high contrast.
    iconColor: FluentStateColor.tokens(
      rest: disabled ? c.neutralForegroundDisabled : c.neutralStrokeAccessible,
    ),
    iconSize: field.iconSize,
    trailingGap: WidgetStatePropertyAll<double?>(nudge * 2),
    trailingPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsetsDirectional.only(start: nudge),
    ),
    surfaceColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    // `useListboxStyles`: `outline: 1px solid colorTransparentStroke`. Invisible
    // in light and dark; it is what outlines the listbox in high contrast.
    // [buildFluentTimePickerSurface] paints it outside the box, as an outline
    // sits, so it takes no room from the rows.
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
    // No cap of its own: `useTimePickerStyles`' `min(80vh, 416px)` loses to
    // Combobox's `80vh`, and both to the inline max-height `autoSize` writes —
    // the room below the field (Chrome: 636px under a field 124px down a
    // 760px page). [FluentTimePicker] clamps to that room.
    surfaceOffset: const WidgetStatePropertyAll<double?>(FluentSpacing.xxs),
  );
}

/// The [FluentInputStyle] the faceplate is drawn with.
///
/// Everything but the focus bar, which [buildFluentTimePicker] draws itself:
/// `buildFluentInput` shapes its bar after Input's `::after`, and Combobox's
/// differs on Underline.
FluentInputStyle _fieldStyle(FluentTimePickerStyle style) => FluentInputStyle(
  backgroundColor: style.backgroundColor,
  borderColor: style.borderColor,
  borderWidth: style.borderWidth,
  borderRadius: style.borderRadius,
  bottomBorderColor: style.underlineColor,
  bottomBorderWidth: style.underlineWidth,
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

/// The focus bar's own corners: `::after`'s `borderBottom*Radius:
/// borderRadiusMedium`, whatever the root's radius is.
const BorderRadius _accentRadius = BorderRadius.vertical(
  bottom: FluentRadius.medium,
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
///
/// The clear glyph *replaces* the chevron rather than sitting beside it:
/// `useComboboxStyles` visually hides the expand icon while the clear icon
/// shows. The chevron stays in the semantics tree, as upstream's stays in the
/// accessibility tree.
///
/// [states] is the live interaction set: hovered, pressed and disabled.
Widget buildFluentTimePicker(
  FluentTimePickerBaseState state,
  FluentTimePickerStyle style,
  Set<WidgetState> states,
) {
  final accentColor = style.accentColor?.resolve(states);
  final accentWidth = style.accentWidth?.resolve(states) ?? FluentStroke.thick;
  final side = style.borderColor?.resolve(states) == null
      ? FluentStroke.none
      : style.borderWidth?.resolve(states) ?? FluentStroke.none;

  final trailing = switch ((state.clearIcon, state.expandIcon)) {
    (final clear?, final expand?) => Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Opacity(opacity: 0, alwaysIncludeSemantics: true, child: expand),
        clear,
      ],
    ),
    (final clear?, null) => clear,
    (null, final expand) => expand,
  };

  final field = buildFluentInput(
    FluentInputBaseState(
      enabled: state.enabled,
      // Its only effect: no caret, no edits. The style ignores it.
      readOnly: state.readOnly,
      error: state.error,
      focused: state.focused,
      controller: state.controller,
      focusNode: state.focusNode,
      editableTextKey: state.editableTextKey,
      placeholder: state.placeholder,
      contentAfter: trailing,
      onChanged: state.onChanged,
      onSubmitted: state.onSubmitted,
      autofocus: state.autofocus,
    ),
    _fieldStyle(style),
    states,
  );
  if (accentColor == null) return field;

  // In the field's tap region, like the bar `buildFluentInput` draws, so a
  // press on it is not a press outside the field.
  return TextFieldTapRegion(
    child: Stack(
      // The bar overhangs a borderless root: see below.
      clipBehavior: Clip.none,
      // Passthrough, so a parent's tight height reaches the field and stretches
      // the box, as a CSS `height` would. A loose Stack laid the field out at
      // its own height and pinned the bar to the bottom of the taller Stack.
      fit: StackFit.passthrough,
      children: <Widget>[
        field,
        // `::after { left: -1px; right: -1px; bottom: -1px }` against the
        // padding box: flush with the border box when the sides are 1px, a
        // pixel past it each side on Underline, which has none. Its 4px bottom
        // radii are its own — Combobox never zeroes them, as Input does — so
        // they stay rounded on Underline's square root.
        Positioned(
          left: side - FluentStroke.thin,
          right: side - FluentStroke.thin,
          bottom: 0,
          height: accentWidth,
          child: FluentInputFocusUnderline(
            focused: state.focused,
            color: accentColor,
            thickness: accentWidth,
            borderRadius: _accentRadius,
          ),
        ),
      ],
    ),
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
      // Outside the box, like the CSS `outline` it ports: it takes no room
      // from the rows, which sit at the surface padding exactly.
      border: borderColor == null || borderWidth <= 0
          ? null
          : Border.all(
              color: borderColor,
              width: borderWidth,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
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

/// Picks the open listbox's active option; with none active, commits a
/// freeform picker's typed text. Opens a shut listbox either way.
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

  // The glyphs never place the caret or select: upstream's icons prevent
  // their mousedown's default.

  @override
  void onTapDown(TapDragDownDetails details) {
    if (!_owner._glyphPress) super.onTapDown(details);
  }

  @override
  void onSingleTapUp(TapDragUpDetails details) {
    if (!_owner._glyphPress) super.onSingleTapUp(details);
    _owner._handleFieldTap();
  }

  // Every click of a double or triple click toggles the list upstream, as the
  // first does; the builder reports those as these instead (Chrome).

  @override
  void onDoubleTapDown(TapDragDownDetails details) {
    if (!_owner._glyphPress) super.onDoubleTapDown(details);
    _owner._handleFieldTap();
  }

  @override
  void onTripleTapDown(TapDragDownDetails details) {
    if (!_owner._glyphPress) super.onTripleTapDown(details);
    _owner._handleFieldTap();
  }

  @override
  void onDragSelectionStart(TapDragStartDetails details) {
    if (!_owner._glyphPress) super.onDragSelectionStart(details);
  }

  @override
  void onDragSelectionUpdate(TapDragUpdateDetails details) {
    if (!_owner._glyphPress) super.onDragSelectionUpdate(details);
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
/// move the caret while the listbox is closed, and jump it while it is open,
/// [freeform] or not. Each of those falls through by reporting
/// `isEnabled: false` rather than doing nothing, which is what lets
/// `DefaultTextEditingShortcuts` see the key.
///
/// | Key | Effect |
/// |---|---|
/// | Down / Up | open on the selection, a typed match or the first; or move |
/// | Home / End | jump the open listbox |
/// | Enter | pick the active row; with none, commit the text; open or close |
/// | Escape | close; a non-freeform picker's typed text reverts |
///
/// Typing, freeform or not, makes the first row whose text starts with what
/// was typed active, with its ring showing. A freeform picker keeps its text
/// as typed when it commits; a non-freeform one only types ahead, and its text
/// reverts to the selection when the listbox closes.
///
/// ## Light dismiss needs a [TapRegionSurface]
///
/// The listbox dismisses through [TapRegion] rather than an invisible
/// full-screen barrier, so a click outside it dismisses *and* lands — which is
/// what upstream's document-level `useOnClickOutside` does, and what a barrier
/// cannot do. That costs one ancestor: [TapRegion] only reports anything to a
/// [TapRegionSurface] above it. [WidgetsApp] installs one (`app.dart:1836`),
/// so `FluentApp` and every test built on it are fine — but a consumer
/// mounting this under a bare [Overlay] with no [WidgetsApp] gets **no
/// dismissal at all**, silently. Escape and a second click on the field still
/// close it there.
///
/// Transcribed from `@fluentui/react-timepicker-compat` 0.4.37 over
/// `@fluentui/react-combobox` 9.17.4.
class FluentTimePicker extends StatefulWidget {
  /// Creates a time picker.
  const FluentTimePicker({
    super.key,
    this.selectedTime,
    this.onTimeChange,
    this.hourCycle,
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
    this.clearSemanticLabel,
    this.expandSemanticLabel,
  });

  /// The chosen time. Null selects nothing.
  final DateTime? selectedTime;

  /// Called when the value changes. Null disables the picker.
  final ValueChanged<FluentTimeSelectionData>? onTimeChange;

  /// Which clock the options are written on, and typed text is parsed on.
  ///
  /// Null is upstream's unset `hourCycle`: the options read as
  /// [FluentHourCycle.h12] writes them, as the en-US locale does, yet typed
  /// text parses on the 24-hour clock — `21:05`, not `9:05 PM`. See
  /// [fluentParseTime].
  final FluentHourCycle? hourCycle;

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

  /// Whether typed text is parsed as a time. Without it, typing only moves
  /// the listbox to a matching row.
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
  ///
  /// Null takes the wording from the ambient [FluentLocalizations],
  /// which falls back to English when no delegate is installed.
  final String? clearSemanticLabel;

  /// Accessible name of the expand chevron.
  ///
  /// Null takes the wording from the ambient [FluentLocalizations],
  /// which falls back to English when no delegate is installed.
  final String? expandSemanticLabel;

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
  ScrollPosition? _scrollPosition;
  int? _active;
  bool _uncontrolledOpen = false;
  bool _focused = false;
  final Set<WidgetState> _interaction = <WidgetState>{};
  String? _committedText;

  /// Whether the latest press began on the chevron or the clear glyph, which
  /// focus the field and leave its caret alone. [_glyphDown] is the glyph's
  /// own report, which the faceplate's [Listener] — reached after it — takes.
  bool _glyphPress = false;
  bool _glyphDown = false;

  /// Whether typing chose [_active]. Upstream's type-ahead match is
  /// focus-visible whatever opened the list, so it rings after a mouse open.
  bool _typedActive = false;

  /// The field's value before its latest text change, selection and all, and
  /// its value now, so [_handleTyped] can tell a typed character from a
  /// deletion.
  TextEditingValue _valueBefore = TextEditingValue.empty;
  TextEditingValue _valueNow = TextEditingValue.empty;

  /// What [_commitText] or [_handleTyped] last reported, in a one-field record
  /// so a reported null is not "nothing". The parent handing it straight back
  /// as `selectedTime` is agreement, not a new value, and must not rewrite the
  /// text the user typed.
  (DateTime?,)? _reported;

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
              cycle: widget.hourCycle ?? FluentHourCycle.h12,
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
    _valueNow = _controller.value;
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_trackText);
  }

  void _trackText() {
    final value = _controller.value;
    if (value.text != _valueNow.text) _valueBefore = _valueNow;
    _valueNow = value;
  }

  /// The enclosing popup chain's group, or null when this popup is top-level.
  ///
  /// Read at THIS context and cached, never inside the [OverlayEntry] builder:
  /// an entry is inflated in the [Overlay]'s branch and [FluentTapGroup] is a
  /// plain [InheritedWidget], so it does not ride across on the entry's
  /// `InheritedTheme.capture`. Handed to [adoptFluentTapGroup] in the popup.
  Object? _hostTapGroup;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hostTapGroup = FluentTapGroup.maybeOf(context);
    // The popup builds from *this* State's context but lives in the Overlay's
    // branch of the tree, so nothing rebuilds it when a dependency here moves.
    // Two visible bugs came out of that: the max height was measured once at
    // open and never again, so resizing the window left the list running off
    // the screen; and a `FluentThemeOverride` swapped under a const subtree
    // left the open popup painting the old tokens. `FluentInfoButton` already
    // does this.
    deferOrRun(() => _entry?.markNeedsBuild());

    // The other half of the same bug, and the half no dependency can catch: the
    // page scrolling under an open listbox slides the field up the screen
    // without touching a single InheritedWidget, so both the room clamp and the
    // flip that picks a side are stale the moment the page moves — a listbox
    // that opened upward because the field sat low stayed upward, and stayed
    // short, after the field had scrolled to the top.
    // `@fluentui/react-positioning` repositions on scroll rather than closing,
    // so re-measuring is the faithful answer — `RawMenuAnchor` reads this same
    // notifier to CLOSE (raw_menu_anchor.dart:499-503, 544-550), which a
    // combobox must not do.
    //
    // Attached here rather than at open so a Scrollable swapped under the field
    // is picked up for free: `Scrollable.maybeOf` takes a dependency on
    // `_ScrollableScope`, which notifies when its position changes identity,
    // and `_handleScroll` is a null check while the listbox is closed.
    //
    // ponytail: gated on `isScrollingNotifier`, so the height re-measures when
    // a scroll starts and stops rather than on every frame between — a full day
    // of 30-minute rows would otherwise rebuild every row a frame for the
    // length of a fling, and those rows are exactly what the constraint exists
    // to clip. Wheel and trackpad scrolling flips the notifier once per tick
    // (scroll_position_with_single_context.dart:222-235), so the desktop and
    // web case this package targets does re-measure continuously; a
    // programmatic `jumpTo` flips it not at all. Listen to `_scrollPosition`
    // itself if a touch fling ever has to be frame-accurate.
    _scrollPosition?.isScrollingNotifier.removeListener(_handleScroll);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.isScrollingNotifier.addListener(_handleScroll);
  }

  /// Re-measures the listbox against the room left after the page moved.
  ///
  /// Deferred because `isScrollingNotifier` can flip during layout — a viewport
  /// whose content shrinks goes ballistic from `applyContentDimensions` — and
  /// invalidating an entry is a `setState` on the Overlay.
  void _handleScroll() => deferOrRun(() => _entry?.markNeedsBuild());

  @override
  void didUpdateWidget(FluentTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _internalNode?.removeListener(_handleFocusChange);
      _focusNode.addListener(_handleFocusChange);
    }
    final reported = _reported;
    _reported = null;
    // A parent echoing what the picker reported leaves the typed text alone:
    // upstream keeps '12:30' after Tab rather than rewriting it to the
    // option's '12:30 PM', and keeps 'abc' over a time picked before (Chrome).
    if (widget.selectedTime != oldWidget.selectedTime &&
        (reported == null || reported.$1 != widget.selectedTime)) {
      _setText(_format(widget.selectedTime));
    }
    // Deferred: `_syncEntry` inserts into the Overlay, which is a `setState` on
    // a branch that has already been built by the time `didUpdateWidget` runs.
    // A parent flipping a controlled `open:` from false to true would otherwise
    // throw.
    deferOrRun(_syncEntry);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    // The listener is what would outlive this State; the position itself is the
    // Scrollable's to dispose, and `removeListener` is documented as safe to
    // call on a notifier that has already gone.
    _scrollPosition?.isScrollingNotifier.removeListener(_handleScroll);
    _entry
      ?..remove()
      ..dispose();
    _entry = null;
    _controller
      ..removeListener(_trackText)
      ..dispose();
    _internalNode?.dispose();
    super.dispose();
  }

  /// Hover and press, fed by the faceplate's own [MouseRegion] and
  /// [Listener] as `FluentInput` feeds its own: the outline's Hover and Pressed
  /// stops and the bar's `:focus-within:active` colour read them.
  ///
  /// Tracked while disabled too and filtered in [build], because Chrome keeps
  /// a disabled root's `:hover`: re-enabled under a resting mouse, the picker
  /// hovers at once. The release of a press can land after [dispose], on the
  /// detached [Listener].
  void _setInteraction(WidgetState state, {required bool value}) {
    if (!mounted) return;
    final changed = value
        ? _interaction.add(state)
        : _interaction.remove(state);
    if (changed) setState(() {});
  }

  /// Chrome focuses the `<input>` on mousedown, whichever button, with the
  /// caret where the press landed, so the bar grows while a press is still
  /// held; the tap focuses only on release, and a middle press never. Touch
  /// focuses on the tap, as a browser's does.
  ///
  /// Through the field's own selection path, as `FluentInput._focusOnPress`
  /// does: a plain `requestFocus` trips `selectAllOnFocus` on desktop and the
  /// web, and `requestKeyboard` alone left the caret at the end. A focused
  /// freeform field leaves the primary and secondary buttons to its text
  /// gestures, which keep a selection a right press lands on for the context
  /// menu. The middle button has no gesture there, and a non-freeform field
  /// has none for any button, while Chrome moves the caret for both
  /// (compat-components-timepicker--default, --freeform-with-error-handling).
  ///
  /// ponytail: a right press on a focused non-freeform field puts the caret
  /// down where macOS Chrome selects the word under it. Give that field the
  /// text gestures if it ever matters, and teach them a wandering click.
  ///
  /// A press on a glyph only focuses: upstream's expandIcon prevents its
  /// mousedown's default and focuses the input itself, so the caret stays
  /// where it was (Chrome).
  void _focusOnPress(PointerDownEvent event, {required bool glyph}) {
    if (!mounted || !_enabled) return;
    if (glyph) {
      editableTextKey.currentState?.requestKeyboard();
      return;
    }
    if (_focusNode.hasFocus &&
        widget.freeform &&
        event.buttons != kMiddleMouseButton) {
      return;
    }
    editableTextKey.currentState?.renderEditable.selectPositionAt(
      from: event.position,
      cause: SelectionChangedCause.tap,
    );
  }

  void _handleFocusChange() {
    final focused = _focusNode.hasFocus;
    if (focused == _focused) return;
    setState(() => _focused = focused);
    if (!focused) {
      _commitText();
      // Upstream's collapsed blur: a non-freeform field left holding exactly
      // the active option's text, edited with the list shut, picks it — '11:00
      // AM' cut down to '1:00 AM' picks 1:00 AM (Chrome).
      final index = _active;
      final options = _options;
      if (!widget.freeform &&
          !_open &&
          index != null &&
          index < options.length &&
          _controller.text.trim().toLowerCase() ==
              _format(options[index]).toLowerCase()) {
        _select(options[index]);
      }
      collapseFluentSelectionOnBlur(_focusNode, _controller);
      deferOrRun(() => _setOpen(next: false));
    }
  }

  void _handleFieldTap() {
    if (!_enabled) return;
    // Focus is requested here rather than only by the text-selection builder's
    // `onSingleTapUp`, because a non-freeform picker does not go through it:
    // without this a touch would open a listbox the arrow keys cannot reach.
    // Idempotent for a mouse, which focused on the press. Through
    // `requestKeyboard`, as the press does: a plain `requestFocus` selects the
    // whole value on desktop and the web.
    editableTextKey.currentState?.requestKeyboard();
    _setOpen(next: !_open);
  }

  /// [committed] is what the same event just reported — a pick or typed text —
  /// which the parent has not handed back as [FluentTimePicker.selectedTime]
  /// yet. Reverting to the old selection there blanked a non-freeform field
  /// for a frame, and undid the keys pressed in it (Chrome keeps them).
  ///
  /// ponytail: taken as accepted, as upstream's uncontrolled picker takes it;
  /// a parent that refuses it sees the list open on that row, and a
  /// non-freeform field keeps the pick's text until it next closes.
  void _setOpen({required bool next, (DateTime?,)? committed}) {
    final selected = committed == null ? widget.selectedTime : committed.$1;
    // Upstream's `setOpen(false)` resets a non-freeform field's typed text to
    // the selection whether or not the listbox was open — a click away, Tab
    // and Escape all revert it, and so does a blur with the list shut.
    if (!next && !widget.freeform) _setText(_format(selected));
    if (next == _open) return;
    _typedActive = false;
    if (widget.open == null) {
      setState(() => _uncontrolledOpen = next);
    }
    widget.onOpenChange?.call(next);
    if (next) {
      // `useComboboxBaseState` opens on the selection, else on the row typing
      // left active with the list shut, else on the first — whichever key or
      // click opened it (Chrome).
      final index = selected == null ? -1 : _options.indexOf(selected);
      _active = index >= 0 ? index : _active ?? 0;
      _scrollActiveIntoView();
    } else {
      _active = null;
    }
    deferOrRun(_syncEntry);
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
      _entry!
        ..remove()
        ..dispose();
      _entry = null;
    }
    _entry?.markNeedsBuild();
    if (mounted) setState(() {});
  }

  void _moveActive(int delta) {
    final options = _options;
    if (options.isEmpty) return;
    // Down or Up on a shut list only opens it, on the selection or the first
    // row — Up never jumps to the last (Chrome).
    if (!_open) {
      _setOpen(next: true);
      return;
    }
    final from = _active ?? (delta > 0 ? -1 : options.length);
    _active = (from + delta).clamp(0, options.length - 1);
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

  /// Upstream's `scrollIntoView`, which typing, the arrows, Home and End and
  /// opening on a selection all run: the least scroll that shows the active
  /// row, 2px clear of the edge it was past (Chrome).
  void _scrollActiveIntoView() {
    final index = _active;
    if (index == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final row = _rowKeys[index]?.currentContext?.findRenderObject();
      if (row is RenderBox && row.attached) {
        row.showOnScreen(rect: (Offset.zero & row.size).inflate(2));
      }
    });
  }

  /// Writes [text] the way setting an `<input>`'s value does: the caret after
  /// it. A bare `controller.text` leaves no selection, which a focused
  /// `EditableText` on desktop and the web turns into the whole value selected,
  /// so the next key replaced a picked time instead of adding to it (Chrome).
  void _setText(String text) {
    _committedText = text;
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _select(DateTime time) {
    final text = _format(time);
    _setText(text);
    widget.onTimeChange?.call(
      FluentTimeSelectionData(selectedTime: time, selectedTimeText: text),
    );
    _setOpen(next: false, committed: (time,));
  }

  /// Upstream's `getOptionFromInput`, as Chrome runs it: typing makes the
  /// first option whose text starts with the trimmed text active, scrolled
  /// just into view, and that match rings whatever opened the list. A typed
  /// character opens a closed list; a deletion does not.
  ///
  /// Where no option starts with the text, a freeform picker leaves none
  /// active, so Enter commits the text; a non-freeform one falls back to the
  /// first, as `useComboboxBaseState` does for any open list left without one,
  /// and drops a selection the text no longer names. An emptied freeform
  /// field falls back to the first too: upstream's freeform check skips empty
  /// text (Chrome).
  void _handleTyped(String text) {
    final options = _options;
    final query = text.trim().toLowerCase();
    final found = query.isEmpty
        ? -1
        : options.indexWhere(
            (option) => _format(option).toLowerCase().startsWith(query),
          );
    // A key typed over a selection replaces it, so a character went in when
    // the text outgrew what the old value kept outside its selection.
    // ponytail: stands in for upstream's printable-keydown test, so a paste
    // opens the list here and not there.
    final before = _valueBefore;
    final kept =
        before.text.length - (before.selection.end - before.selection.start);
    if (!_open && text.length > kept) _setOpen(next: true);
    // The first-row fallback is the open list's: `useComboboxBaseState` runs
    // it only while open, so a deletion on a shut list leaves none active.
    _active = found >= 0
        ? found
        : !_open || (widget.freeform && text.isNotEmpty) || options.isEmpty
        ? null
        : 0;
    _typedActive = _active != null;
    _scrollActiveIntoView();
    if (!widget.freeform && found < 0 && widget.selectedTime != null) {
      _reported = (null,);
      widget.onTimeChange?.call(const FluentTimeSelectionData());
    }
    _entry?.markNeedsBuild();
    setState(() {});
  }

  /// Commits typed text, mirroring a browser's `change` event: on blur and on
  /// Enter, never per keystroke, and only when the text actually moved — or
  /// when the field is empty, which is reported however long it has been so.
  /// Returns what it reported, or null when it reported nothing.
  (DateTime?,)? _commitText() {
    if (!_enabled || !widget.freeform) return null;
    final text = _controller.text;
    // An empty field is checked even when the text has not moved: it is an
    // assertion about absence rather than about what was typed, so a required
    // picker that was never typed into still has to report on blur — the
    // section's own "leave the input empty and close the TimePicker" case.
    // `FluentDatePicker._commitText` orders its guards the same way.
    if (text.trim().isNotEmpty && text == _committedText) return null;
    _committedText = text;
    final result =
        (widget.parseTime ??
        (String value) => fluentParseTime(
          value,
          dateAnchor: _anchor,
          startHour: widget.startHour,
          endHour: widget.endHour,
          required: widget.required,
          hourCycle: widget.hourCycle,
          showSeconds: widget.showSeconds,
        ))(text);
    // The text is deliberately left alone, parsed or not — [_reported] keeps
    // the parent's echo from rewriting it. That is what a native text input
    // does on change, and it is the opposite of FluentSpinButton, which snaps
    // its value back.
    final time = result.error == FluentTimePickerErrorType.invalidInput
        ? null
        : result.date;
    final reported = _reported = (time,);
    widget.onTimeChange?.call(
      FluentTimeSelectionData(
        selectedTime: time,
        selectedTimeText: text,
        error: result.error,
      ),
    );
    return reported;
  }

  /// Enter picks the active row of an open list. With no row active a
  /// freeform picker commits its text — upstream's `useSelectTimeFromValue`
  /// asks for exactly that — and the list toggles either way: a shut list
  /// kept active by typing only opens on its row, and one opened by a commit
  /// opens on the time committed (Chrome).
  void _activate() {
    final index = _active;
    final options = _options;
    final active = index != null && index >= 0 && index < options.length;
    if (_open && active) {
      _select(options[index]);
      return;
    }
    // `_commitText` skips unmoved text itself.
    _setOpen(next: !_open, committed: active ? null : _commitText());
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
    final gap = style.surfaceGap?.resolve(states) ?? FluentSpacing.xxs;

    // The room actually left, as upstream's `autoSize` writes it — a fixed cap
    // says nothing about where the field sits, so a picker in the lower half
    // of the page ran off the bottom of the screen. Open upward when there is
    // more room there, which is what upstream's positioning layer does rather
    // than clipping. A style's `surfaceMaxHeight` caps it further.
    final room = fluentAnchorRoom(context);
    final flip = room.above > room.below;
    final available = flip ? room.above : room.below;
    final double maxHeight = math.min(
      style.surfaceMaxHeight?.resolve(states) ?? double.infinity,
      math.max(available - offset, 0),
    );

    // No light-dismiss barrier. A `Positioned.fill` over the whole viewport
    // swallows every press behind it, so a click on a button while the listbox
    // was open dismissed the listbox and did nothing else, hover never reached
    // what was underneath, and a `PointerScrollEvent` never reached the
    // `Scrollable` — the page could not even scroll. Upstream's combobox
    // dismisses from a document-level `useOnClickOutside` listener, so the
    // click dismisses *and* lands. [TapRegion] is that listener; the group is
    // joined at the trigger in [build].
    return Positioned(
      width: _link.leaderSize?.width,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: flip ? Alignment.topLeft : Alignment.bottomLeft,
        followerAnchor: flip ? Alignment.bottomLeft : Alignment.topLeft,
        offset: Offset(0, flip ? -offset : offset),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 160, maxHeight: maxHeight),
            // Focus never enters the popup: the field keeps it and the
            // active row is marked instead, which is the combobox model.
            child: ExcludeFocus(
              // Same group as the trigger, so a press on a row is "inside" the
              // picker and does not dismiss it. Inside the follower for the
              // same reason the tap region below is — `RenderTapRegion` is a
              // proxy box too, and is classified by whether it appears in the
              // hit-test path.
              child: adoptFluentTapGroup(
                _hostTapGroup,
                TapRegion(
                  groupId: this,
                  // The listbox counts as part of the field when the framework
                  // asks whether a press landed outside it. `EditableText`
                  // drops focus for any non-touch press outside its own tap
                  // region, and the listbox lives in an [Overlay] beyond it —
                  // so a mouse press on a row blurred the field, and the commit
                  // and close that blur runs happened before the press had the
                  // chance to become a tap. A synthetic tap arrives as a touch,
                  // which is why nothing showed it.
                  //
                  // Inside the follower rather than around it: a plain proxy
                  // box above [CompositedTransformFollower] hit-tests against
                  // its own untransformed bounds, which is not where the
                  // surface is painted, so rows past the leader's width would
                  // stop responding.
                  child: TextFieldTapRegion(
                    // The padding scrolls with the rows, as the listbox's own
                    // does upstream, so the first row's ring shows in it
                    // rather than being clipped at the scroller's edge.
                    child: buildFluentTimePickerSurface(
                      style.copyWith(
                        surfacePadding:
                            const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
                              EdgeInsets.zero,
                            ),
                      ),
                      states,
                      ValueListenableBuilder<bool>(
                        valueListenable: FluentInputModality.keyboard,
                        builder: (context, keyboard, _) =>
                            SingleChildScrollView(
                              padding: style.surfacePadding?.resolve(states),
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
        ),
      ),
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
            // as the Dropdown and TagPicker do, or on typing having chosen it.
            if (index == _active && (keyboard || _typedActive))
              WidgetState.focused,
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
      if (_enabled) ..._interaction,
    };
    final iconColor = style.iconColor?.resolve(states);
    final iconSize = style.iconSize?.resolve(states);
    final showClear =
        widget.clearable &&
        _enabled &&
        (widget.selectedTime != null || _controller.text.isNotEmpty);

    // Underline's box is a pixel shorter, so the glyph centres on a half
    // pixel (5.5 at medium). Chrome paints the SVG on the whole pixel below,
    // which lands it exactly where the bordered appearances draw it; a pixel
    // of top inset reproduces that.
    //
    // Both glyphs carry upstream's `cursor: pointer`; disabled, the faceplate's
    // `not-allowed` shows through.
    Widget glyph(Widget child) {
      child = Listener(onPointerDown: (_) => _glyphDown = true, child: child);
      if (_enabled) {
        child = MouseRegion(cursor: SystemMouseCursors.click, child: child);
      }
      return widget.appearance == FluentTimePickerAppearance.underline
          ? Padding(
              padding: const EdgeInsets.only(top: FluentStroke.thin),
              child: child,
            )
          : child;
    }

    var field = buildFluentTimePicker(
      resolveFluentTimePickerState(
        controller: _controller,
        focusNode: _focusNode,
        editableTextKey: editableTextKey,
        enabled: _enabled,
        error: widget.error,
        focused: _focused,
        open: _open,
        appearance: widget.appearance,
        size: widget.size,
        placeholder: widget.placeholder,
        autofocus: widget.autofocus,
        onChanged: _handleTyped,
        expandIcon: glyph(
          Semantics(
            button: true,
            label: widget.expandSemanticLabel ?? fluentL10n(context).open,
            child: Icon(
              fluentTimePickerChevron,
              size: iconSize,
              color: iconColor,
            ),
          ),
        ),
        clearIcon: showClear
            ? glyph(
                _ClearButton(
                  semanticLabel:
                      widget.clearSemanticLabel ?? fluentL10n(context).clear,
                  iconColor: iconColor,
                  iconSize: iconSize,
                  onPressed: _clear,
                ),
              )
            : null,
      ),
      style,
      states,
    );

    // Hover and press, wired the way `FluentInput` wires them: a text field
    // cannot be a `FluentInteractive`, whose focus node and activation would
    // fight the `EditableText`'s.
    field = MouseRegion(
      cursor: style.mouseCursor?.resolve(states) ?? SystemMouseCursors.text,
      onEnter: (_) => _setInteraction(WidgetState.hovered, value: true),
      onExit: (_) => _setInteraction(WidgetState.hovered, value: false),
      // Chrome sets `:active` for the primary and middle buttons, not for a
      // right press (storybook).
      child: Listener(
        onPointerDown: (event) {
          final glyph = _glyphPress = _glyphDown;
          _glyphDown = false;
          _setInteraction(
            WidgetState.pressed,
            value: event.buttons != kSecondaryMouseButton,
          );
          // A microtask later, so an outside-press blur dispatched after this
          // on the same event — another field's — cannot undo it.
          if (_enabled && event.kind == PointerDeviceKind.mouse) {
            scheduleMicrotask(() => _focusOnPress(event, glyph: glyph));
          }
        },
        onPointerUp: (_) => _setInteraction(WidgetState.pressed, value: false),
        onPointerCancel: (_) =>
            _setInteraction(WidgetState.pressed, value: false),
        child: field,
      ),
    );

    return Semantics(
      label: widget.semanticLabel,
      textField: true,
      expanded: _open,
      // The trigger half of the light-dismiss group the listbox joins in
      // [_buildPopup]. `groupId: this` — the State — is what ties the two
      // together across the [Overlay] boundary, so a press on the field or on
      // a row counts as inside and only a press elsewhere closes the listbox.
      //
      // Registered only while open, so nothing is listening the rest of the
      // time. It fires on pointer *down*, and `RenderTapRegionSurface` "does
      // not participate in the gesture disambiguation system"
      // (`tap_region.dart:189-192`), so a press that becomes a drag-scroll
      // dismisses too. That is the same trade upstream's `useOnClickOutside`
      // makes on touch, and it costs nothing on a mouse: `FluentScrollBehavior`
      // deliberately keeps `PointerDeviceKind.mouse` out of `dragDevices`, so a
      // wheel scroll is not a pointer press at all.
      child: TapRegion(
        groupId: this,
        onTapOutside: _open ? (_) => _setOpen(next: false) : null,
        // Any press, on the field or the listbox, takes a typed ring away, as
        // keyborg's mousedown does upstream; the row stays active (Chrome).
        onTapInside: (_) {
          if (!_typedActive) return;
          _typedActive = false;
          _entry?.markNeedsBuild();
        },
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
              SingleActivator(LogicalKeyboardKey.end):
                  FluentTimePickerEdgeIntent(last: true),
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
              // A picker that cannot select text has nothing for the
              // text-selection detector to do — with `selectionEnabled` false
              // every one of its handlers returns early, leaving only the
              // keyboard request — while the `TapAndPanGestureRecognizer` it
              // inherits still claims a precise pointer's gesture as a drag after
              // one logical pixel. A real mouse click wanders two or three, so
              // the faceplate never saw a tap, and the arena sweep took the clear
              // glyph's own recogniser down with it. Freeform keeps the detector:
              // there the drag *is* the text selection.
              child: selectionEnabled
                  ? _gestures.buildGestureDetector(child: field)
                  : GestureDetector(
                      // Excluded because the detector it stands in for is:
                      // announcing a tap action here as well would add a node to
                      // the tree that the freeform picker does not have.
                      excludeFromSemantics: true,
                      onTap: _handleFieldTap,
                      child: field,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Jumps the listbox — but only while it is open, freeform or not: upstream's
/// Combobox takes Home and End from the caret then, and leaves them to it
/// while closed (Chrome).
///
/// Reporting `isEnabled: false` rather than doing nothing is what lets Home and
/// End fall through to `DefaultTextEditingShortcuts` and move the caret.
class _EdgeAction extends Action<FluentTimePickerEdgeIntent> {
  _EdgeAction(this.state);

  final _FluentTimePickerState state;

  @override
  bool isEnabled(FluentTimePickerEdgeIntent intent) => state._open;

  @override
  Object? invoke(FluentTimePickerEdgeIntent intent) {
    state._edge(last: intent.last);
    return null;
  }
}

/// Closes the listbox. A non-freeform picker's typed text reverts with it; a
/// freeform picker keeps it for the blur to commit (Chrome).
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
