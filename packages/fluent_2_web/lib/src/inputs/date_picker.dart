import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/gestures.dart' show TapDragUpDetails;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../internal/interaction.dart';
import '../overlays/popover.dart';
import 'calendar.dart';
import 'calendar_style.dart';
import 'date_picker_style.dart';
import 'input.dart';
import 'input_style.dart';

/// The colours and borders of a `FluentDatePicker`'s faceplate.
enum FluentDatePickerAppearance {
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

/// The height and type ramp of a `FluentDatePicker`.
enum FluentDatePickerSize {
  /// 24 high, `caption1`.
  small,

  /// 32 high, `body1`. The default.
  medium,

  /// 40 high, `body2`.
  large,
}

/// What went wrong when a typed date was validated.
///
/// Upstream's `DatePickerErrorType`, the same three members.
enum FluentDatePickerErrorType {
  /// The text is not a date at all.
  invalidInput,

  /// The date parsed but falls outside `minDate`/`maxDate`, or is restricted.
  outOfBounds,

  /// The field is required and empty.
  requiredInput,
}

/// The outcome of validating a `FluentDatePicker`'s field.
@immutable
class FluentDatePickerValidationResult {
  /// Creates a result.
  const FluentDatePickerValidationResult({this.error});

  /// What went wrong, or null.
  final FluentDatePickerErrorType? error;

  /// Whether the field holds a usable date.
  bool get isValid => error == null;
}

/// The messages a `FluentDatePicker` offers for each error.
///
/// The three error *types* are upstream's; these English *strings* are this
/// port's, because upstream's live in a locale bundle this package has no
/// equivalent of.
@immutable
class FluentDatePickerErrorStrings {
  /// Creates a set of messages.
  const FluentDatePickerErrorStrings({
    this.invalidInput = 'Invalid date format.',
    this.outOfBounds = 'Date is out of the allowed range.',
    this.requiredInput = 'This field is required.',
  });

  /// Shown when the text is not a date.
  final String invalidInput;

  /// Shown when the date is outside the allowed range.
  final String outOfBounds;

  /// Shown when a required field is empty.
  final String requiredInput;

  /// The message for [error], or null when there is no error.
  String? messageFor(FluentDatePickerErrorType? error) => switch (error) {
    FluentDatePickerErrorType.invalidInput => invalidInput,
    FluentDatePickerErrorType.outOfBounds => outOfBounds,
    FluentDatePickerErrorType.requiredInput => requiredInput,
    null => null,
  };
}

/// The default messages.
const FluentDatePickerErrorStrings defaultFluentDatePickerErrorStrings =
    FluentDatePickerErrorStrings();

/// Renders a date as `M/d/yyyy`.
///
/// **A deliberate divergence.** Upstream defaults to `date.toString()`, which in
/// Dart emits `2026-03-14 00:00:00.000` — a string nobody types. Its parser
/// default is `Date.parse`, whose Dart counterpart accepts ISO-8601 only. The
/// pair would therefore not round-trip, and `allowTextInput` would be broken out
/// of the box. This and [fluentParseDate] are reciprocal, and both are public so
/// an application can wrap rather than replace them.
String fluentFormatDate(DateTime date) =>
    '${date.month}/${date.day}/${date.year}';

/// Parses `M/d/yyyy` and the common separator variants, falling back to
/// ISO-8601.
///
/// Returns null when the text is not a date. Rejects an impossible day such as
/// `2/30` rather than letting [DateTime] roll it into March.
DateTime? fluentParseDate(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  final parts = trimmed.split(RegExp(r'[/\-.]'));
  if (parts.length == 3) {
    final month = int.tryParse(parts[0]);
    final day = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (month != null &&
        day != null &&
        year != null &&
        month >= 1 &&
        month <= 12) {
      final candidate = DateTime(year < 100 ? 2000 + year : year, month, day);
      // DateTime rolls an impossible day forward instead of throwing, so the
      // round trip is the check.
      if (candidate.month == month && candidate.day == day) return candidate;
      return null;
    }
  }
  return DateTime.tryParse(trimmed);
}

/// The [DateFormat] a picker formats and parses its field with.
///
/// [pattern] is an ICU pattern; null means the locale's own short numeric date
/// — `M/d/y` in `en_US`, `d.M.y` in `de_DE`. Same locale-data requirement as
/// [fluentCalendarStrings].
DateFormat fluentDateFormat(Locale locale, {String? pattern}) {
  final tag = fluentIntlLocale(locale);
  return pattern == null ? DateFormat.yMd(tag) : DateFormat(pattern, tag);
}

/// [fluentFormatDate]'s locale-aware counterpart.
String Function(DateTime date) fluentIntlFormatDate(
  Locale locale, {
  String? pattern,
}) => fluentDateFormat(locale, pattern: pattern).format;

/// [fluentParseDate]'s locale-aware counterpart. Null when the text is not a
/// date.
///
/// Strict on purpose: `parseStrict` re-formats what it read and rejects the
/// result unless it round-trips, which is what turns `2/30` into null instead
/// of letting [DateTime] roll it into March. ISO-8601 is accepted as a fallback
/// because that is what a machine hands over and it is unambiguous everywhere —
/// but the locale's own pattern is tried first, so `12/06/2026` is December in
/// `en_US` and June in `en_GB`.
DateTime? Function(String text) fluentIntlParseDate(
  Locale locale, {
  String? pattern,
}) {
  final format = fluentDateFormat(locale, pattern: pattern);
  return (String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    try {
      return format.parseStrict(trimmed);
    } on FormatException {
      return DateTime.tryParse(trimmed);
    }
  };
}

/// Everything needed to render a date picker, independent of its design axes.
@immutable
class FluentDatePickerBaseState {
  /// Creates a base state.
  const FluentDatePickerBaseState({
    required this.enabled,
    required this.readOnly,
    required this.error,
    required this.focused,
    required this.open,
    required this.controller,
    required this.focusNode,
    required this.editableTextKey,
    this.placeholder,
    this.icon,
    this.contentBefore,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// Whether the picker accepts input.
  final bool enabled;

  /// Whether the field refuses edits. True unless `allowTextInput` is set.
  final bool readOnly;

  /// Whether to paint the danger ramp.
  final bool error;

  /// Whether the field holds focus.
  final bool focused;

  /// Whether the calendar popup is showing.
  final bool open;

  /// The field's text.
  final TextEditingController controller;

  /// The field's focus node.
  final FocusNode focusNode;

  /// Key of the underlying [EditableText].
  final GlobalKey<EditableTextState> editableTextKey;

  /// Shown while the field is empty.
  final Widget? placeholder;

  /// The trailing slot — the calendar glyph unless a caller replaces it.
  final Widget? icon;

  /// Slot before the field in reading order.
  final Widget? contentBefore;

  /// Called on every keystroke.
  final ValueChanged<String>? onChanged;

  /// Called when the field is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Accessible name of the picker.
  final String? semanticLabel;
}

/// A date picker's fully resolved state, including the design axes.
@immutable
class FluentDatePickerState extends FluentDatePickerBaseState {
  /// Creates a state.
  const FluentDatePickerState({
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
    required this.borderless,
    super.placeholder,
    super.icon,
    super.contentBefore,
    super.onChanged,
    super.onSubmitted,
    super.autofocus,
    super.semanticLabel,
  });

  /// Colours and borders of the faceplate.
  final FluentDatePickerAppearance appearance;

  /// Height and type ramp of the faceplate.
  final FluentDatePickerSize size;

  /// Whether to drop the faceplate's borders entirely.
  ///
  /// A flag rather than a fifth appearance, because upstream keeps the two
  /// orthogonal — a borderless picker still picks a fill from its appearance.
  final bool borderless;
}

/// Assembles a [FluentDatePickerState].
///
/// The first of the three-function recomposition contract.
FluentDatePickerState resolveFluentDatePickerState({
  required TextEditingController controller,
  required FocusNode focusNode,
  required GlobalKey<EditableTextState> editableTextKey,
  bool enabled = true,
  bool readOnly = true,
  bool error = false,
  bool focused = false,
  bool open = false,
  FluentDatePickerAppearance appearance = FluentDatePickerAppearance.outline,
  FluentDatePickerSize size = FluentDatePickerSize.medium,
  bool borderless = false,
  Widget? placeholder,
  Widget? icon,
  Widget? contentBefore,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onSubmitted,
  bool autofocus = false,
  String? semanticLabel,
}) => FluentDatePickerState(
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
  borderless: borderless,
  placeholder: placeholder,
  icon: icon,
  contentBefore: contentBefore,
  onChanged: onChanged,
  onSubmitted: onSubmitted,
  autofocus: autofocus,
  semanticLabel: semanticLabel,
);

FluentInputAppearance _inputAppearance(FluentDatePickerAppearance value) =>
    switch (value) {
      FluentDatePickerAppearance.outline => FluentInputAppearance.outline,
      FluentDatePickerAppearance.underline => FluentInputAppearance.underline,
      FluentDatePickerAppearance.filledDarker =>
        FluentInputAppearance.filledDarker,
      FluentDatePickerAppearance.filledLighter =>
        FluentInputAppearance.filledLighter,
    };

FluentInputSize _inputSize(FluentDatePickerSize value) => switch (value) {
  FluentDatePickerSize.small => FluentInputSize.small,
  FluentDatePickerSize.medium => FluentInputSize.medium,
  FluentDatePickerSize.large => FluentInputSize.large,
};

/// Derives the default style for [state] from [theme].
///
/// The second of the three-function recomposition contract, and the only place
/// the design axes are read.
///
/// ## The read-only trap
///
/// `resolveFluentInputStyle` folds `readOnly` into the disabled ramp — it takes
/// `inert = disabled || readOnly` and paints on `transparentBackground` with a
/// `neutralStrokeDisabled` border. That column is Figma's alone; upstream ships
/// `readOnly` as a bare attribute with no styling.
///
/// `allowTextInput` defaults to **false**, so a date picker is read-only by
/// default — handing the real flag to the style resolver would render **every
/// default picker looking disabled**. The field is resolved with
/// `readOnly: false` and the real value reaches only the renderer, where it
/// stops the caret and the edits. React wins on behaviour.
FluentDatePickerStyle resolveFluentDatePickerStyle(
  FluentDatePickerState state,
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

  const none = WidgetStatePropertyAll<double?>(FluentStroke.none);

  return FluentDatePickerStyle(
    backgroundColor: field.backgroundColor,
    borderColor: field.borderColor,
    borderWidth: state.borderless ? none : field.borderWidth,
    borderRadius: field.borderRadius,
    underlineColor: field.bottomBorderColor,
    underlineWidth: state.borderless ? none : field.bottomBorderWidth,
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
    iconPadding: field.contentPadding,
    surfaceColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    surfaceBorderColor: FluentStateColor.tokens(rest: c.transparentStroke),
    surfaceBorderWidth: const WidgetStatePropertyAll<double?>(
      FluentStroke.thin,
    ),
    surfaceRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    // The calendar carries its own inset; a second one here would double it.
    surfacePadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.zero,
    ),
    surfaceShadow: WidgetStatePropertyAll<List<BoxShadow>?>(
      theme.shadow(FluentElevation.shadow16),
    ),
    // A real number, unlike the Dropdown's null: a calendar does not scroll, so
    // knowing its height up front is what makes the flip decidable in one pass.
    surfaceMaxHeight: const WidgetStatePropertyAll<double?>(360),
    surfaceOffset: const WidgetStatePropertyAll<double?>(FluentSpacing.xxs),
  );
}

FluentInputStyle _fieldStyle(FluentDatePickerStyle style) => FluentInputStyle(
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
  contentPadding: style.iconPadding,
  iconSize: style.iconSize,
  minimumSize: style.minimumSize,
  mouseCursor: style.mouseCursor,
);

/// The glyph a date picker draws in its trailing slot.
const IconData fluentDatePickerIcon = FluentIcons.calendar_month_20_regular;

/// Renders a date picker's faceplate from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentDatePickerBaseState] on purpose: it never reads the appearance or the
/// size.
Widget buildFluentDatePicker(
  FluentDatePickerBaseState state,
  FluentDatePickerStyle style,
  Set<WidgetState> states,
) => buildFluentInput(
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
    contentBefore: state.contentBefore,
    contentAfter: state.icon,
    onChanged: state.onChanged,
    onSubmitted: state.onSubmitted,
    autofocus: state.autofocus,
  ),
  _fieldStyle(style),
  states,
);

/// Renders the popup surface around [child].
///
/// Public because `expectGolden` never captures overlay content, so the golden
/// for the open state has to render the surface directly — the same workaround
/// `buildFluentDropdownSurface` exists for.
Widget buildFluentDatePickerSurface(
  FluentDatePickerStyle style,
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

/// Overrides the date picker style for a subtree.
class FluentDatePickerTheme extends InheritedTheme {
  /// Applies [style] to every [FluentDatePicker] in [child].
  const FluentDatePickerTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the theme defaults.
  final FluentDatePickerStyle style;

  /// The nearest date picker style, or null.
  static FluentDatePickerStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentDatePickerTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentDatePickerTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentDatePickerTheme(style: style, child: child);
}

/// Places the caret *and* toggles the popup on a tap.
class _DatePickerGestures extends TextSelectionGestureDetectorBuilder {
  _DatePickerGestures(this._owner) : super(delegate: _owner);

  final _FluentDatePickerState _owner;

  @override
  void onSingleTapUp(TapDragUpDetails details) {
    super.onSingleTapUp(details);
    _owner._handleFieldTap();
  }
}

/// An input that opens a calendar popup for picking a single date.
///
/// Selection is **controlled**: [value] is the truth and the picker never
/// mutates it. A null [onSelectDate] disables the control.
///
/// ## Focus goes into the calendar
///
/// Unlike `FluentDropdown` and `FluentTagPicker`, which keep focus on the
/// trigger and mark an active descendant, this popup takes focus. A calendar
/// grid has two-dimensional arrows, PageUp/PageDown, nav buttons and a view
/// toggle; forwarding all of that from the field would re-implement
/// [FluentCalendar]'s keyboard model here, and would steal Left and Right from
/// the text field when [allowTextInput] is set. Upstream traps focus in the
/// popup surface for the same reason.
///
/// ## Open and close
///
/// Upstream's contract, verbatim: *"Clicking the input field will open the
/// DatePicker, and clicking the field again will dismiss it and allow text
/// input. When using keyboard navigation, text input is allowed by default, and
/// pressing Enter will open the DatePicker."*
///
/// | Event | Effect |
/// |---|---|
/// | click, closed | open, when [openOnClick] |
/// | click, open | close; the caret lands, so typing is possible |
/// | Tab in | does not open |
/// | Enter, closed | commit typed text if there is any, else open |
/// | Escape | close, revert the text, focus the field |
/// | focus leaves both field and popup | close and validate |
///
/// `disableAutoFocus` is deliberately **not** offered: its only non-default
/// value is documented upstream as *"creates an accessibility violation and is
/// not recommended"*, and shipping a footgun to default it away is worse than
/// not shipping it.
///
/// Transcribed from `@fluentui/react-datepicker-compat` 0.6.35.
class FluentDatePicker extends StatefulWidget {
  /// Creates a date picker.
  const FluentDatePicker({
    super.key,
    this.value,
    this.onSelectDate,
    this.today,
    this.minDate,
    this.maxDate,
    this.restrictedDates = const <DateTime>[],
    this.firstDayOfWeek = FluentDayOfWeek.sunday,
    this.initialPickerDate,
    this.isDayPickerVisible = true,
    this.isMonthPickerVisible = true,
    this.showMonthPickerAsOverlay = false,
    this.inlinePopup = false,
    this.highlightCurrentMonth = false,
    this.highlightSelectedMonth = false,
    this.showGoToToday = true,
    this.showWeekNumbers = false,
    this.firstWeekOfYear = FluentFirstWeekOfYear.firstDay,
    this.allFocusable = false,
    this.showCloseButton = false,
    this.allowTextInput = false,
    this.openOnClick = true,
    this.required = false,
    this.error = false,
    this.onValidationResult,
    this.open,
    this.defaultOpen = false,
    this.onOpenChange,
    this.locale,
    this.formatDate,
    this.parseDate,
    this.strings,
    this.formatter,
    this.errorStrings = defaultFluentDatePickerErrorStrings,
    this.appearance = FluentDatePickerAppearance.outline,
    this.size = FluentDatePickerSize.medium,
    this.borderless = false,
    this.placeholder,
    this.contentBefore,
    this.contentAfter,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.style,
    this.calendarStyle,
    this.semanticLabel,
    this.calendarSemanticLabel = 'Open calendar',
  });

  /// The chosen date. Null selects nothing.
  final DateTime? value;

  /// Called with local midnight when a date is chosen or typed. Null disables
  /// the picker.
  final ValueChanged<DateTime?>? onSelectDate;

  /// What counts as today. Defaults to the clock at mount.
  final DateTime? today;

  /// Earliest selectable day, inclusive.
  final DateTime? minDate;

  /// Latest selectable day, inclusive.
  final DateTime? maxDate;

  /// Days that cannot be chosen whatever the bounds say.
  final List<DateTime> restrictedDates;

  /// Which day the calendar's week starts on.
  final FluentDayOfWeek firstDayOfWeek;

  /// The calendar page shown when the popup first opens.
  final DateTime? initialPickerDate;

  /// Whether the popup shows the day grid.
  final bool isDayPickerVisible;

  /// Whether the popup shows a month picker beside the day grid.
  ///
  /// True by default, as upstream. The popup is 440 wide in that layout and
  /// 220 with a single panel, so the flip-above decision moves with it.
  final bool isMonthPickerVisible;

  /// Whether the month picker is reached through the day caption rather than
  /// shown beside the day grid. Keeps the popup 220 wide instead of 440.
  final bool showMonthPickerAsOverlay;

  /// Whether the popup is rendered in the widget tree instead of the [Overlay].
  ///
  /// Upstream's `inlinePopup`, and the same trade. The surface still floats —
  /// it is out of flow, so the field's footprint is unchanged — but it now
  /// inherits and moves with this widget's ancestors, and is clipped by
  /// anything that clips them. There is no light-dismiss barrier and no
  /// flip-above; focus leaving the picker still closes it.
  final bool inlinePopup;

  /// Whether the month and decade grids mark the current period.
  final bool highlightCurrentMonth;

  /// Whether the month and decade grids mark the selected period.
  final bool highlightSelectedMonth;

  /// Whether the calendar offers its "go to today" link.
  final bool showGoToToday;

  /// Whether the day grid draws a week-number column.
  final bool showWeekNumbers;

  /// Which week counts as week 1, when [showWeekNumbers] is set.
  final FluentFirstWeekOfYear firstWeekOfYear;

  /// Whether unselectable days still take keyboard focus.
  final bool allFocusable;

  /// Whether the calendar header offers a close button.
  ///
  /// It closes the popup; unlike [FluentCalendar.showCloseButton] there is no
  /// separate callback to supply, because the picker already owns the popup.
  final bool showCloseButton;

  /// Whether the field accepts a typed date.
  final bool allowTextInput;

  /// Whether clicking the field opens the popup.
  final bool openOnClick;

  /// Whether an empty field is an error.
  final bool required;

  /// Whether to paint the danger ramp. Set it directly when an application does
  /// its own validation.
  final bool error;

  /// Called once per commit with the outcome.
  final ValueChanged<FluentDatePickerValidationResult>? onValidationResult;

  /// Whether the popup is showing. Null leaves it uncontrolled.
  final bool? open;

  /// The popup's open state at mount, when [open] is null.
  final bool defaultOpen;

  /// Called whenever the popup opens or closes.
  final ValueChanged<bool>? onOpenChange;

  /// The locale the field and the calendar are rendered in.
  ///
  /// Setting it swaps the four defaults below for their `package:intl`
  /// counterparts — [fluentIntlFormatDate], [fluentIntlParseDate],
  /// [fluentCalendarStrings] and [fluentCalendarDateFormatter] — so a
  /// `Locale('de', 'DE')` is all it takes to get `31.12.2026` and German month
  /// names. Any of the four passed explicitly still wins.
  ///
  /// **Null does not mean English.** The ambient [Localizations] locale is used
  /// instead, so a picker inside an app that already declares its locale is
  /// localized without being told twice. English is only the fallback when
  /// there is no ambient locale either.
  ///
  /// The two paths differ on missing locale data, deliberately. An explicit
  /// locale is honoured whatever intl knows about it, so a forgotten
  /// `initializeDateFormatting` fails loudly for whoever named that locale. An
  /// ambient one is taken up only when intl already holds its data — a picker
  /// must not start throwing because the app around it grew a [Localizations]
  /// widget. See [fluentCalendarStrings] for the loading call.
  final Locale? locale;

  /// Renders the chosen date into the field.
  ///
  /// Defaults to [fluentFormatDate], or to [locale]'s short date when a locale
  /// is set.
  final String Function(DateTime date)? formatDate;

  /// Parses typed text. Null means the text is not a date.
  ///
  /// Defaults to [fluentParseDate], or to [locale]'s parser when a locale is
  /// set.
  final DateTime? Function(String text)? parseDate;

  /// Every calendar label that is not a number.
  final FluentCalendarStrings? strings;

  /// How the calendar renders dates.
  final FluentCalendarDateFormatter? formatter;

  /// The messages offered for each error type.
  final FluentDatePickerErrorStrings errorStrings;

  /// Colours and borders of the faceplate.
  final FluentDatePickerAppearance appearance;

  /// Height and type ramp of the faceplate.
  final FluentDatePickerSize size;

  /// Whether to drop the faceplate's borders.
  final bool borderless;

  /// Shown while the field is empty.
  final Widget? placeholder;

  /// Slot before the field in reading order — an icon, a prefix, a button.
  final Widget? contentBefore;

  /// Slot after the field in reading order.
  ///
  /// Replaces the calendar glyph. Upstream models the glyph as the default
  /// `contentAfter` too, so passing one is a substitution rather than an
  /// addition — pass a [Row] to keep both.
  final Widget? contentAfter;

  /// Called on every keystroke with the field's raw text.
  ///
  /// Upstream's `onChange`. This is *not* selection: nothing is parsed or
  /// validated here, and [onSelectDate] still fires only on a commit.
  final ValueChanged<String>? onChanged;

  /// Focus node for the field.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Overrides layered over the resolved defaults.
  final FluentDatePickerStyle? style;

  /// Overrides for the calendar inside the popup.
  final FluentCalendarStyle? calendarStyle;

  /// Accessible name of the picker.
  final String? semanticLabel;

  /// Accessible name of the calendar glyph.
  final String calendarSemanticLabel;

  @override
  State<FluentDatePicker> createState() => _FluentDatePickerState();
}

class _FluentDatePickerState extends State<FluentDatePicker>
    implements TextSelectionGestureDetectorBuilderDelegate {
  final LayerLink _link = LayerLink();
  final FocusScopeNode _scope = FocusScopeNode(
    debugLabel: 'FluentDatePicker popup',
  );
  late final _DatePickerGestures _gestures = _DatePickerGestures(this);

  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => _enabled && widget.allowTextInput;

  late final TextEditingController _controller = TextEditingController(
    text: _format(widget.value),
  );
  late final DateTime _fallbackToday = DateTime.now();

  Locale? _ambientLocale;
  FocusNode? _internalNode;
  OverlayEntry? _entry;
  FocusNode? _restore;
  bool _uncontrolledOpen = false;
  bool _focused = false;
  bool _wasInside = false;
  bool _reducedMotion = false;
  String _lastFormatted = '';
  FluentDatePickerErrorType? _error;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalNode ??= FocusNode());

  bool get _enabled => widget.onSelectDate != null;

  bool get _open => widget.open ?? _uncontrolledOpen;

  DateTime get _today => widget.today ?? _fallbackToday;

  /// The locale the four defaults below are built from — the explicit one, or
  /// the ambient [Localizations] locale when intl already has its data.
  ///
  /// See [FluentDatePicker.locale] for why only the ambient path is gated on
  /// `localeExists`.
  Locale? get _locale {
    final explicit = widget.locale;
    if (explicit != null) return explicit;
    final ambient = _ambientLocale;
    if (ambient == null) return null;
    return fluentIntlLocaleAvailable(ambient) ? ambient : null;
  }

  /// The four localizable defaults. An explicit override always wins.
  String Function(DateTime) get _formatter {
    final locale = _locale;
    return widget.formatDate ??
        (locale == null ? fluentFormatDate : fluentIntlFormatDate(locale));
  }

  DateTime? Function(String) get _parser {
    final locale = _locale;
    return widget.parseDate ??
        (locale == null ? fluentParseDate : fluentIntlParseDate(locale));
  }

  FluentCalendarStrings get _strings {
    final locale = _locale;
    return widget.strings ??
        (locale == null
            ? FluentCalendarStrings.english
            : fluentCalendarStrings(locale));
  }

  FluentCalendarDateFormatter get _calendarFormatter {
    final locale = _locale;
    return widget.formatter ??
        (locale == null
            ? const FluentCalendarDateFormatter()
            : fluentCalendarDateFormatter(locale));
  }

  String _format(DateTime? date) => date == null ? '' : _formatter(date);

  /// Rewrites the field from [FluentDatePicker.value] in the current locale.
  void _reformat() {
    final text = _format(widget.value);
    _controller.text = text;
    _lastFormatted = text;
  }

  @override
  void initState() {
    super.initState();
    _uncontrolledOpen = widget.defaultOpen;
    _lastFormatted = _controller.text;
    _focusNode.addListener(_handleFocusChange);
    _scope.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(FluentDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _internalNode?.removeListener(_handleFocusChange);
      _focusNode.addListener(_handleFocusChange);
    }
    // Keyed on the locale but deliberately not on `formatDate`: a closure built
    // inline in `build` is a new object every frame, so comparing it would
    // clobber half-typed text on every rebuild.
    if (widget.value != oldWidget.value || widget.locale != oldWidget.locale) {
      _reformat();
    }
    _deferOrRun(_syncEntry);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Read at the trigger and handed across the overlay boundary explicitly:
    // MediaQuery does not ride along with InheritedTheme.capture.
    _reducedMotion = MediaQuery.disableAnimationsOf(context);

    // Not readable from initState — `Localizations.maybeLocaleOf` registers an
    // inherited dependency — so the controller is first filled with the English
    // default and rewritten here, before the first build.
    final ambient = Localizations.maybeLocaleOf(context);
    if (ambient == _ambientLocale) return;
    _ambientLocale = ambient;
    // Nothing to rewrite when an explicit locale is in charge; it never moved.
    if (widget.locale == null) _reformat();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _scope
      ..removeListener(_handleFocusChange)
      ..dispose();
    _entry?.remove();
    _entry = null;
    _controller.dispose();
    _internalNode?.dispose();
    super.dispose();
  }

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

  /// Closes and validates once focus has genuinely left both the field and the
  /// popup.
  ///
  /// **Post-frame, and registered on both nodes.** Opening the popup moves
  /// focus off the field on one frame and into the scope on the next, so a
  /// synchronous handler sees "neither has focus" in between and closes the
  /// popup the click just opened. A [FocusScopeNode]'s changes also do not
  /// notify the field's node, so one listener would miss half the transitions.
  /// `FluentDropdown` and `FluentTagPicker` never hit this because their popups
  /// never take focus.
  void _handleFocusChange() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final inside = _focusNode.hasFocus || _scope.hasFocus;
      if (inside != _focused) setState(() => _focused = _focusNode.hasFocus);
      if (inside == _wasInside) return;
      _wasInside = inside;
      if (inside) return;
      if (_open) _setOpen(next: false);
      _commitText();
    });
  }

  void _handleFieldTap() {
    if (!_enabled) return;
    if (_open) {
      _setOpen(next: false);
      return;
    }
    if (widget.openOnClick) _setOpen(next: true);
  }

  void _setOpen({required bool next}) {
    if (next == _open) return;
    if (widget.open == null) {
      setState(() => _uncontrolledOpen = next);
    }
    widget.onOpenChange?.call(next);
    _deferOrRun(_syncEntry);
  }

  void _syncEntry() {
    if (!mounted) return;
    // An inline popup lives in this widget's own tree, so there is no entry to
    // insert — only the focus hand-off, which the overlay path gets below.
    if (widget.inlinePopup) {
      if (_open && _enabled) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted && _open) _scope.requestFocus();
        });
      }
      setState(() {});
      return;
    }
    final shouldShow = _open && _enabled;
    if (shouldShow && _entry == null) {
      final overlay = Overlay.of(context, debugRequiredFor: widget);
      _restore = FocusManager.instance.primaryFocus;
      final captured = InheritedTheme.capture(
        from: context,
        to: overlay.context,
      );
      _entry = OverlayEntry(builder: (_) => captured.wrap(_buildPopup()));
      overlay.insert(_entry!);
      // Deferred: the scope is not attached until the overlay has built, and
      // `autofocus` alone will not do it — autofocus only applies when nothing
      // in the enclosing scope already holds focus, and the field does.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && _entry != null) _scope.requestFocus();
      });
    } else if (!shouldShow && _entry != null) {
      // Restore only when the thing being torn down was holding focus, so a
      // light-dismiss tap onto another field is not stolen back. FluentPopover
      // restores unconditionally; that is a bug this does not copy.
      final wasInside = _scope.hasFocus;
      _entry!.remove();
      _entry = null;
      final restore = _restore;
      _restore = null;
      if (wasInside &&
          restore != null &&
          restore.context != null &&
          restore.canRequestFocus) {
        restore.requestFocus();
      }
    }
    _entry?.markNeedsBuild();
    if (mounted) setState(() {});
  }

  bool _inBounds(DateTime date) {
    final day = fluentCalendarDay(date);
    final min = widget.minDate;
    final max = widget.maxDate;
    if (min != null && day.isBefore(fluentCalendarDay(min))) return false;
    if (max != null && day.isAfter(fluentCalendarDay(max))) return false;
    return !widget.restrictedDates.map(fluentCalendarDay).contains(day);
  }

  void _report(
    FluentDatePickerErrorType? error, {
    DateTime? value,
    bool changed = false,
  }) {
    if (error != _error) setState(() => _error = error);
    widget.onValidationResult?.call(
      FluentDatePickerValidationResult(error: error),
    );
    if (changed) widget.onSelectDate?.call(value);
  }

  /// Validates and commits the field's text.
  ///
  /// Runs on blur, and on Enter when there is unsaved text.
  void _commitText() {
    if (!_enabled || !widget.allowTextInput) return;
    final text = _controller.text.trim();

    // An empty required field is checked before the ambiguity guard below: it
    // is an error about absence, not about text, so "unchanged" is no reason to
    // skip it — a field that was never typed into still has to report.
    if (text.isEmpty) {
      final wasEmpty = _lastFormatted.isEmpty;
      _lastFormatted = text;
      _report(
        widget.required ? FluentDatePickerErrorType.requiredInput : null,
        changed: !wasEmpty,
      );
      return;
    }

    // Upstream's ambiguity rule: *"the control will avoid parsing the formatted
    // strings of dates selected using the UI"*. A format such as `dd/MM/yy` is
    // ambiguous, so re-parsing our own output can silently move the date. If the
    // field still holds exactly what was written, there is nothing to parse.
    if (text == _lastFormatted) {
      _report(null);
      return;
    }
    _lastFormatted = text;
    final parsed = _parser(text);
    if (parsed == null) {
      _report(FluentDatePickerErrorType.invalidInput);
      return;
    }
    if (!_inBounds(parsed)) {
      _report(FluentDatePickerErrorType.outOfBounds);
      return;
    }
    _report(null, value: fluentCalendarLocalDay(parsed), changed: true);
  }

  void _handleSelectDate(DateTime date) {
    final text = _format(date);
    _controller.text = text;
    _lastFormatted = text;
    if (_error != null) setState(() => _error = null);
    widget.onValidationResult?.call(const FluentDatePickerValidationResult());
    widget.onSelectDate?.call(date);
    _setOpen(next: false);
  }

  FluentDatePickerStyle _resolvedStyle(BuildContext context) =>
      resolveFluentDatePickerStyle(
        resolveFluentDatePickerState(
          controller: _controller,
          focusNode: _focusNode,
          editableTextKey: editableTextKey,
          enabled: _enabled,
          readOnly: !widget.allowTextInput,
          error: widget.error || _error != null,
          focused: _focused,
          open: _open,
          appearance: widget.appearance,
          size: widget.size,
          borderless: widget.borderless,
        ),
        FluentTheme.of(context),
      ).merge(FluentDatePickerTheme.maybeOf(context)).merge(widget.style);

  /// The focus-trapping calendar surface, shared by both popup strategies.
  Widget _surface(FluentDatePickerStyle style, Set<WidgetState> states) =>
      FocusScope(
        node: _scope,
        child: Actions(
          // Escape belongs here, not to the calendar: FluentCalendar binds no
          // DismissIntent precisely so this can.
          actions: <Type, Action<Intent>>{
            DismissIntent: _DismissDatePickerAction(this),
          },
          child: buildFluentDatePickerSurface(
            style,
            states,
            FluentCalendar(
              value: widget.value,
              onSelectDate: _handleSelectDate,
              today: _today,
              minDate: widget.minDate,
              maxDate: widget.maxDate,
              restrictedDates: widget.restrictedDates,
              firstDayOfWeek: widget.firstDayOfWeek,
              isDayPickerVisible: widget.isDayPickerVisible,
              isMonthPickerVisible: widget.isMonthPickerVisible,
              showMonthPickerAsOverlay: widget.showMonthPickerAsOverlay,
              highlightCurrentMonth: widget.highlightCurrentMonth,
              highlightSelectedMonth: widget.highlightSelectedMonth,
              initialPickerDate: widget.value ?? widget.initialPickerDate,
              showGoToToday: widget.showGoToToday,
              showWeekNumbers: widget.showWeekNumbers,
              firstWeekOfYear: widget.firstWeekOfYear,
              allFocusable: widget.allFocusable,
              showCloseButton: widget.showCloseButton,
              onDismiss: () => _setOpen(next: false),
              strings: _strings,
              formatter: _calendarFormatter,
              style: widget.calendarStyle,
              autofocus: true,
            ),
          ),
        ),
      );

  /// The popup rendered in the widget tree rather than the [Overlay].
  ///
  /// `inlinePopup`. In the tree but out of flow, which is what upstream's own
  /// inline popup is — a `position: absolute` surface rather than a portal — so
  /// the field's footprint does not change when it opens. What the tree buys is
  /// what the portal costs: the surface inherits and moves with its ancestors,
  /// and is clipped by anything that clips them. No light-dismiss barrier and
  /// no flip-above; focus leaving the picker still closes it.
  Widget _buildInlinePopup() {
    final style = _resolvedStyle(context);
    final states = <WidgetState>{if (!_enabled) WidgetState.disabled};
    final offset = style.surfaceOffset?.resolve(states) ?? FluentSpacing.xxs;
    return Padding(
      padding: EdgeInsets.only(top: offset),
      child: FluentPopoverEntrance(
        position: FluentPopoverPosition.below,
        reducedMotion: _reducedMotion,
        child: _surface(style, states),
      ),
    );
  }

  Widget _buildPopup() {
    final style = _resolvedStyle(context);
    final states = <WidgetState>{if (!_enabled) WidgetState.disabled};
    final offset = style.surfaceOffset?.resolve(states) ?? FluentSpacing.xxs;
    final estimated = style.surfaceMaxHeight?.resolve(states) ?? 360;

    // Decided in one pass from the link rather than measured and then moved: a
    // calendar's height is fixed, so there is nothing to wait for.
    final leader = _link.leader?.offset ?? Offset.zero;
    final leaderSize = _link.leaderSize ?? Size.zero;
    final viewport = MediaQuery.sizeOf(context).height;
    final below = viewport - leader.dy - leaderSize.height - offset;
    final above = leader.dy - offset;
    final flip = below < estimated && above > below;

    final (
      Alignment target,
      Alignment follower,
      Offset shift,
      FluentPopoverPosition position,
    ) = flip
        ? (
            Alignment.topLeft,
            Alignment.bottomLeft,
            Offset(0, -offset),
            FluentPopoverPosition.above,
          )
        : (
            Alignment.bottomLeft,
            Alignment.topLeft,
            Offset(0, offset),
            FluentPopoverPosition.below,
          );

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _setOpen(next: false),
          ),
        ),
        Positioned(
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: target,
            followerAnchor: follower,
            offset: shift,
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: FluentPopoverEntrance(
                position: position,
                reducedMotion: _reducedMotion,
                child: _surface(style, states),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _resolvedStyle(context);
    final states = <WidgetState>{
      if (!_enabled) WidgetState.disabled,
      if (_focused) WidgetState.focused,
    };

    final field = buildFluentDatePicker(
      resolveFluentDatePickerState(
        controller: _controller,
        focusNode: _focusNode,
        editableTextKey: editableTextKey,
        enabled: _enabled,
        readOnly: !widget.allowTextInput,
        error: widget.error || _error != null,
        focused: _focused,
        open: _open,
        appearance: widget.appearance,
        size: widget.size,
        borderless: widget.borderless,
        placeholder: widget.placeholder,
        autofocus: widget.autofocus,
        contentBefore: widget.contentBefore,
        onChanged: widget.onChanged,
        icon:
            widget.contentAfter ??
            Semantics(
              button: true,
              label: widget.calendarSemanticLabel,
              excludeSemantics: true,
              child: Icon(
                fluentDatePickerIcon,
                size: style.iconSize?.resolve(states),
                color: style.iconColor?.resolve(states),
              ),
            ),
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
            SingleActivator(LogicalKeyboardKey.enter):
                _FluentDatePickerOpenIntent(),
            SingleActivator(LogicalKeyboardKey.numpadEnter):
                _FluentDatePickerOpenIntent(),
            SingleActivator(LogicalKeyboardKey.arrowDown):
                _FluentDatePickerOpenIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _FluentDatePickerOpenIntent:
                  CallbackAction<_FluentDatePickerOpenIntent>(
                    onInvoke: (_) {
                      if (!_enabled) return null;
                      if (_open) return null;
                      if (widget.allowTextInput &&
                          _controller.text.trim() != _lastFormatted) {
                        _commitText();
                      } else {
                        _setOpen(next: true);
                      }
                      return null;
                    },
                  ),
              DismissIntent: _DismissDatePickerAction(this),
            },
            child: widget.inlinePopup
                ? Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      // Unpositioned, so the field alone sizes the stack and
                      // the picker keeps the footprint it has without a popup.
                      _gestures.buildGestureDetector(child: field),
                      if (_open && _enabled)
                        // Only `start` and `bottom` are pinned, which is what
                        // leaves the surface unbounded in both axes — a 440
                        // calendar under a 300 field lays out at its own size
                        // instead of overflowing the field's. The translation
                        // then drops it by its own height, landing its top on
                        // the field's bottom edge.
                        PositionedDirectional(
                          start: 0,
                          bottom: 0,
                          child: FractionalTranslation(
                            translation: const Offset(0, 1),
                            child: _buildInlinePopup(),
                          ),
                        ),
                    ],
                  )
                : _gestures.buildGestureDetector(child: field),
          ),
        ),
      ),
    );
  }
}

/// Opens the popup, or commits typed text when there is any.
class _FluentDatePickerOpenIntent extends Intent {
  const _FluentDatePickerOpenIntent();
}

/// Closes the popup, reverts the text and returns focus to the field.
///
/// Gated on the popup being open so Escape still reaches an ancestor when the
/// picker is closed.
class _DismissDatePickerAction extends Action<DismissIntent> {
  _DismissDatePickerAction(this.state);

  final _FluentDatePickerState state;

  @override
  bool isEnabled(DismissIntent intent) => state._open;

  @override
  Object? invoke(DismissIntent intent) {
    state._controller.text = state._format(state.widget.value);
    state._lastFormatted = state._controller.text;
    state._setOpen(next: false);
    state._focusNode.requestFocus();
    return null;
  }
}
