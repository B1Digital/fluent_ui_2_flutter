import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/focus_ring.dart';
import '../internal/interaction.dart';
import 'dropdown_option_style.dart';

/// What a row in a dropdown popup is. Figma's `.ListItem` `Type` axis.
///
/// `Multi select` is **not ported**: this wave models single selection only, so
/// there is no checkbox-leading row and no `List content` with more than one
/// value chosen. Its Figma variants are still in `test/fixtures/dropdown_option.json`
/// and are asserted there as absent from this enum.
enum FluentDropdownOptionType {
  /// A selectable value. Figma `Type=Single select`. The default.
  singleSelect,

  /// A non-interactive caption above a group of values. Figma `Type=Header`.
  header,
}

/// One row of a `FluentDropdown` popup.
///
/// A plain description rather than a widget: the popup owns hover, press,
/// keyboard activity and the focus ring, so an option only has to say what it
/// *is*. `FluentDropdown` turns each of these into a row with
/// [buildFluentDropdownOption].
///
/// ```dart
/// const FluentDropdownOption<int>(value: 1, label: Text('One'))
/// ```
@immutable
class FluentDropdownOption<T> {
  /// Creates a selectable option carrying [value].
  const FluentDropdownOption({
    required T value,
    required this.label,
    this.enabled = true,
    this.text,
    // An initializing formal cannot be written here: the field is private and a
    // named parameter may not be, so `value` has to be copied across by hand.
    // ignore: prefer_initializing_formals
  }) : _value = value,
       type = FluentDropdownOptionType.singleSelect;

  /// Creates a non-interactive group header.
  ///
  /// Never selectable, never focusable, and skipped by keyboard navigation —
  /// which is why it carries no value.
  const FluentDropdownOption.header({required this.label, this.text})
    : _value = null,
      enabled = false,
      type = FluentDropdownOptionType.header;

  final T? _value;

  /// The value reported to `onChanged` when this option is chosen.
  ///
  /// Reading it on a [FluentDropdownOptionType.header] is a mistake — a header
  /// has none, and the popup never asks. It returns null there, which for a
  /// non-nullable `T` will throw.
  T get value => _value as T;

  /// What the row renders, and what the trigger renders once selected.
  final Widget label;

  /// Whether the option can be chosen. Headers are never enabled.
  final bool enabled;

  /// What this row is.
  final FluentDropdownOptionType type;

  /// Plain text for assistive technology, and for the trigger's semantic value.
  ///
  /// Optional because [label] usually carries a `Text` that a screen reader can
  /// already read; supply it when the label is a glyph or a rich widget.
  final String? text;

  /// Whether this row is a header rather than a value.
  bool get isHeader => type == FluentDropdownOptionType.header;
}

/// Everything needed to render one popup row, independent of its type.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentDropdownOption]
/// takes this rather than [FluentDropdownOptionState], which is what makes
/// "Fluent's state, my own styling, Fluent's rendering" a supported path rather
/// than a fork.
@immutable
class FluentDropdownOptionBaseState {
  /// Creates a base state.
  const FluentDropdownOptionBaseState({
    required this.enabled,
    required this.selected,
    required this.showCheckmark,
    required this.reserveCheckmark,
    required this.label,
  });

  /// Whether the row responds to input.
  final bool enabled;

  /// Whether this row's value is the dropdown's current value.
  ///
  /// Deliberately **not** a [WidgetState]. The `.ListItem` set has no `Selected`
  /// variant and paints no selected fill — selection is the checkmark and
  /// nothing else — and `FluentStateColor` resolves disabled, pressed and
  /// hovered ahead of selected, so a hovered selected row would lose it anyway.
  final bool selected;

  /// Whether the checkmark is painted.
  final bool showCheckmark;

  /// Whether the checkmark's slot is laid out even when nothing is painted.
  ///
  /// True for every value row, so labels line up down the list whether or not
  /// their row is the selected one — upstream hides the glyph with
  /// `visibility: hidden` for the same reason. False for a header, which has no
  /// slot at all.
  final bool reserveCheckmark;

  /// What the row renders.
  final Widget label;
}

/// A popup row's fully resolved state, including the design axis.
@immutable
class FluentDropdownOptionState extends FluentDropdownOptionBaseState {
  /// Creates a resolved state.
  const FluentDropdownOptionState({
    required super.enabled,
    required super.selected,
    required super.showCheckmark,
    required super.reserveCheckmark,
    required super.label,
    required this.type,
  });

  /// What this row is.
  final FluentDropdownOptionType type;
}

/// Builds the state one popup row will be styled and rendered from.
///
/// The first of the three-function recomposition contract, and the only place
/// the checkmark is decided: a header never has one, a value row always
/// reserves its slot and paints it only when selected.
FluentDropdownOptionState resolveFluentDropdownOptionState({
  required Widget label,
  bool enabled = true,
  bool selected = false,
  FluentDropdownOptionType type = FluentDropdownOptionType.singleSelect,
}) {
  final header = type == FluentDropdownOptionType.header;
  return FluentDropdownOptionState(
    enabled: enabled && !header,
    selected: selected && !header,
    showCheckmark: selected && !header,
    reserveCheckmark: !header,
    label: label,
    type: type,
  );
}

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract. Every value comes
/// from a Fluent token; nothing here computes a colour.
///
/// Token sources are the Figma `.ListItem` set, extracted into
/// `test/fixtures/dropdown_option.json`. Two notes on that extraction:
///
/// * **Rest paints no fill at all.** `State=Rest` has no fill on the variant
///   frame, so the row is `transparentBackground` and the popup surface shows
///   through. `State=Disabled` *does* paint `Neutral/Background/1/Rest`, which
///   is the popup surface's own colour repeated on the row rather than a
///   disabled fill; it is read as silence and the disabled row stays
///   transparent too.
/// * **The checkmark walks the label's ramp.** Figma binds the glyph to
///   `Neutral/Foreground/2/Rest` at rest and `Neutral/Foreground/1/Rest` on
///   hover and press, while the label goes `Neutral/Foreground/2/{Hover,Pressed}`.
///   Those resolve to the same value in every shipped theme, so one ramp drives
///   both and the two cannot drift apart under a partial override.
FluentDropdownOptionStyle resolveFluentDropdownOptionStyle(
  FluentDropdownOptionState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  final background = state.enabled
      ? FluentStateColor.tokens(
          rest: c.transparentBackground,
          hover: c.neutralBackground1Hover,
          pressed: c.neutralBackground1Pressed,
        )
      : FluentStateColor.tokens(rest: c.transparentBackground);

  final foreground = switch ((state.enabled, state.type)) {
    (_, FluentDropdownOptionType.header) => FluentStateColor.tokens(
      rest: c.neutralForeground3,
    ),
    (false, _) => FluentStateColor.tokens(rest: c.neutralForegroundDisabled),
    (true, _) => FluentStateColor.tokens(
      rest: c.neutralForeground2,
      hover: c.neutralForeground2Hover,
      pressed: c.neutralForeground2Pressed,
      disabled: c.neutralForegroundDisabled,
    ),
  };

  // Geometry, verbatim from the Figma `.ListItem` frames. The value row's
  // `List-container` is inset 6 on the left and 0 on the right — upstream says
  // `spacingHorizontalS` (8) on both — and the label's own `Text` frame adds 2
  // either side, which is where the right inset actually comes from.
  final padding = switch (state.type) {
    FluentDropdownOptionType.header => const EdgeInsets.symmetric(
      horizontal: FluentSpacing.sNudge,
      vertical: FluentSpacing.s,
    ),
    FluentDropdownOptionType.singleSelect => const EdgeInsets.fromLTRB(
      FluentSpacing.sNudge,
      FluentSpacing.sNudge,
      FluentSpacing.none,
      FluentSpacing.sNudge,
    ),
  };

  return FluentDropdownOptionStyle(
    backgroundColor: background,
    foregroundColor: foreground,
    checkmarkColor: foreground,
    checkmarkSize: const WidgetStatePropertyAll<double?>(FluentSize.size160),
    // The Figma `Checkmark-control` frame is 18 wide around a 16 glyph box.
    checkmarkPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.only(right: FluentSpacing.xxs),
    ),
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(switch (state.type) {
      FluentDropdownOptionType.header => theme.typography.caption1Strong,
      FluentDropdownOptionType.singleSelect => theme.typography.body1,
    }),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(padding),
    labelPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(horizontal: FluentSpacing.xxs),
    ),
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.xs),
    minimumSize: const WidgetStatePropertyAll<Size?>(Size(0, _rowHeight)),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// Every `.ListItem` variant is 32 tall, header included.
const double _rowHeight = 32;

/// The glyph a selected row draws.
///
/// `Checkmark16Filled`, which is what upstream's `Option` renders and what the
/// Figma `Shape` vector is — a 14-unit tick inside a 16 box.
const IconData fluentDropdownCheckmark = FluentIcons.checkmark_16_filled;

/// Renders one popup row from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentDropdownOptionBaseState] rather than [FluentDropdownOptionState] on
/// purpose: it never reads the type, so a consumer can supply their own style
/// and still use Fluent's layout, checkmark slot and focus ring.
///
/// **Nothing animates.** `useOptionStyles.styles.ts` contains no `transition`,
/// no `animation` and no `motionTokens` reference at all: a row's fill changes
/// on the frame the pointer arrives. That also makes it trivially correct under
/// `MediaQuery.disableAnimationsOf` — there is no animation to shorten.
///
/// [states] is the live interaction set from [FluentInteractive], with
/// [WidgetState.focused] set by the popup on the *active* row — the one the
/// arrow keys have moved to. That is genuine keyboard-visible focus even though
/// the framework's focus never leaves the trigger.
Widget buildFluentDropdownOption(
  FluentDropdownOptionBaseState state,
  FluentDropdownOptionStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final background = style.backgroundColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final checkmarkColor = style.checkmarkColor?.resolve(states);
  final checkmarkSize =
      style.checkmarkSize?.resolve(states) ?? FluentSize.size160;
  final checkmarkPadding =
      style.checkmarkPadding?.resolve(states) ?? EdgeInsets.zero;
  final textStyle = style.textStyle?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final labelPadding = style.labelPadding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.xs;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;

  Widget label = Padding(padding: labelPadding, child: state.label);
  if (textStyle != null || foreground != null) {
    label = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      child: label,
    );
  }

  return FluentFocusRing(
    visible: states.contains(WidgetState.focused),
    borderRadius: radius,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minimumSize.height,
        minWidth: minimumSize.width,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(color: background, borderRadius: radius),
        child: Padding(
          padding: padding,
          child: Row(
            spacing: state.reserveCheckmark ? gap : 0,
            children: <Widget>[
              if (state.reserveCheckmark)
                Padding(
                  padding: checkmarkPadding,
                  child: SizedBox.square(
                    dimension: checkmarkSize,
                    // The slot is laid out whether or not the glyph is painted,
                    // so a list of rows keeps one text baseline column.
                    child: state.showCheckmark
                        ? Icon(
                            fluentDropdownCheckmark,
                            size: checkmarkSize,
                            color: checkmarkColor,
                          )
                        : null,
                  ),
                ),
              Expanded(child: label),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Overrides the popup row style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `optionStyle`.
class FluentDropdownOptionTheme extends InheritedTheme {
  /// Applies [style] to every `FluentDropdown` row in [child].
  const FluentDropdownOptionTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the type defaults.
  final FluentDropdownOptionStyle style;

  /// The nearest popup row style, or null.
  static FluentDropdownOptionStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentDropdownOptionTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentDropdownOptionTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentDropdownOptionTheme(style: style, child: child);
}
