import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/anchor_metrics.dart';
import '../internal/animated_style.dart';
import '../internal/defer.dart';
import '../internal/input_modality.dart';
import '../internal/interaction.dart';
import '../l10n/l10n.dart';
import '../surfaces/interaction_tag.dart';
import '../surfaces/tag.dart';
import 'dropdown_option.dart';
import 'dropdown_option_style.dart';
import 'input.dart';
import 'tag_picker_style.dart';

/// `useListboxStyles.styles.ts` — `minWidth: '160px'` on the popup, which only
/// bites once the trigger it matches is narrower than 160. The same floor
/// `dropdown.dart` carries, for the same reason: both popups render a Listbox.
const double _listboxMinWidth = 160;

/// How a tag picker's control is filled and outlined. Figma's `Style` axis.
///
/// The four values map one-for-one onto [FluentInputAppearance]; the names
/// follow the Figma `Tag picker/TagPicker` set rather than upstream's, which
/// calls [FluentTagPickerAppearance.transparent] `underline`.
enum FluentTagPickerAppearance {
  /// `neutralBackground1` with a border on all four sides and an
  /// accessible-contrast rule along the bottom. The default.
  outline,

  /// No fill and no box border — only the bottom rule.
  transparent,

  /// `neutralBackground3` with an invisible border and no bottom rule.
  filledDarker,

  /// `neutralBackground1` with an invisible border and no bottom rule.
  filledLighter,
}

/// Control height. Figma's `Size` axis.
///
/// Unlike `FluentInput`, the type ramp does **not** move with the size: all 72
/// Figma variants bind `Typography/Font size/300` (14/20). Only the height and
/// the insets change.
enum FluentTagPickerSize {
  /// 32 high. The default.
  medium,

  /// 40 high.
  large,

  /// 48 high.
  extraLarge,
}

/// The brand bar growing across the bottom of a focused tag picker.
///
/// `useTagPickerControlStyles.styles.ts` carries the same `::after` rule as
/// `useInputStyles`, down to the same defect — the curve is written into
/// `transitionDelay` rather than `transitionTimingFunction`, so a browser drops
/// it. This package reads the curve as the intent, which is why the constant
/// below is [fluentInputFocusUnderlineEnter] rather than a second copy of it.
const FluentMotionSpec fluentTagPickerAccentEnter =
    fluentInputFocusUnderlineEnter;

/// The brand bar collapsing as focus leaves.
///
/// `durationUltraFast` with `curveAccelerateMid` — four times quicker than
/// [fluentTagPickerAccentEnter], which is upstream's asymmetry, not a typo.
const FluentMotionSpec fluentTagPickerAccentExit =
    fluentInputFocusUnderlineExit;

/// One row of a `FluentTagPicker` popup.
///
/// A plain description rather than a widget: the picker owns hover, press,
/// keyboard activity and the focus ring, so an option only has to say what it
/// *is*.
///
/// ```dart
/// const FluentTagPickerOption<String>(value: 'kat', label: Text('Katri'))
/// ```
@immutable
class FluentTagPickerOption<T> {
  /// Creates a selectable option carrying [value].
  const FluentTagPickerOption({
    required T value,
    required this.label,
    this.media,
    this.enabled = true,
    this.text,
    // An initializing formal cannot be written here: the field is private and a
    // named parameter may not be, so `value` has to be copied across by hand.
    // ignore: prefer_initializing_formals
  }) : _value = value,
       type = FluentDropdownOptionType.singleSelect;

  /// Creates a non-interactive group header.
  ///
  /// Never selectable and skipped by keyboard navigation, which is why it
  /// carries no value.
  const FluentTagPickerOption.header({required this.label, this.text})
    : _value = null,
      media = null,
      enabled = false,
      type = FluentDropdownOptionType.header;

  final T? _value;

  /// The value handed to `onSelected`, and the identity a chip is keyed by.
  ///
  /// Reading it on a header is a mistake — a header has none, and the popup
  /// never asks.
  T get value => _value as T;

  /// What the row renders.
  final Widget label;

  /// Leading media — normally a `FluentAvatar`. Null leaves the slot out
  /// entirely rather than reserving it.
  final Widget? media;

  /// Whether the option can be chosen. Headers never are.
  final bool enabled;

  /// Plain text for assistive technology. Supply it when [label] is a glyph or
  /// a rich widget rather than a `Text`.
  final String? text;

  /// What this row is.
  final FluentDropdownOptionType type;

  /// Whether this row is a header rather than a value.
  bool get isHeader => type == FluentDropdownOptionType.header;
}

/// Everything needed to render a tag picker control, independent of the design
/// axes.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentTagPicker] takes
/// this rather than [FluentTagPickerState], which is what makes "Fluent's
/// state, my own styling, Fluent's rendering" a supported path rather than a
/// fork.
@immutable
class FluentTagPickerBaseState {
  /// Creates a base state.
  const FluentTagPickerBaseState({
    required this.enabled,
    required this.focused,
    required this.field,
    this.tags = const <Widget>[],
    this.secondaryAction,
  });

  /// Whether the control accepts input.
  final bool enabled;

  /// Whether the control holds focus.
  ///
  /// **Not** `WidgetState.focused`, which in this package means
  /// *keyboard-visible* focus. The brand bar has to appear when focus arrives
  /// by click as well, so real focus is an axis on the state — the same call
  /// `FluentInput` makes.
  final bool focused;

  /// The text field, already composed by the caller.
  final Widget field;

  /// The selected chips, in order.
  final List<Widget> tags;

  /// The trailing action — Fluent's `TagPicker/Secondary action`, normally a
  /// "Clear all" link.
  final Widget? secondaryAction;
}

/// A tag picker's fully resolved state, including the design axes.
@immutable
class FluentTagPickerState extends FluentTagPickerBaseState {
  /// Creates a resolved state.
  const FluentTagPickerState({
    required super.enabled,
    required super.focused,
    required super.field,
    required this.appearance,
    required this.size,
    required this.open,
    super.tags,
    super.secondaryAction,
  });

  /// Fill and outline treatment.
  final FluentTagPickerAppearance appearance;

  /// Control height.
  final FluentTagPickerSize size;

  /// Whether the popup is showing. Figma's `Expanded` axis, and the only thing
  /// that moves the box border to its Selected token.
  final bool open;
}

/// Builds the state a tag picker will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentTagPickerState resolveFluentTagPickerState({
  required Widget field,
  bool enabled = true,
  bool focused = false,
  bool open = false,
  FluentTagPickerAppearance appearance = FluentTagPickerAppearance.outline,
  FluentTagPickerSize size = FluentTagPickerSize.medium,
  List<Widget> tags = const <Widget>[],
  Widget? secondaryAction,
}) => FluentTagPickerState(
  enabled: enabled,
  focused: focused,
  open: open,
  appearance: appearance,
  size: size,
  field: field,
  tags: tags,
  secondaryAction: secondaryAction,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the Figma `Tag picker/TagPicker` set (`9064:14049`, all 72
/// variants over Style x Size x State x Expanded), extracted into
/// `test/fixtures/tag_picker.json` and asserted variant-by-variant.
///
/// Four things about this table are worth knowing before "fixing" it:
///
/// * **The type ramp does not move.** Every one of the 72 variants binds
///   `Typography/Font size/300`, so Medium, Large and Extra large all render
///   `body1`. `FluentInput` ramps `caption1`/`body1`/`body2` across its three
///   sizes; the tag picker deliberately does not.
/// * **Disabled paints a real fill.** Figma binds
///   `Neutral/Background/Disabled/Rest` on Outline, Filled darker and Filled
///   lighter, where `FluentInput`'s disabled column goes transparent. Only
///   Transparent keeps `Neutral/Background/Transparent/Rest`.
/// * **Only Outline has a box border**, and only at `Size=Medium` does it ramp.
///   The Medium column binds `Neutral/Stroke/1/Hover` on Hover, Pressed *and*
///   Focused, and `Neutral/Stroke/1/Selected` on `Expanded=True`; the Large and
///   Extra large columns bind `Neutral/Stroke/1/Rest` in every state, which is
///   Figma authoring drift rather than a design decision. The Medium ramp wins
///   for all three sizes. Recorded in `doc/token-divergences.md`.
/// * **The bottom rule is two rules.** Outline and Transparent carry a 1px
///   `Neutral/Stroke/Accessible/*` rectangle at rest; every appearance replaces
///   it with a 2px `Neutral/Stroke/Accessible/Selected` bar on Pressed and
///   Focused. React names `colorCompoundBrandStroke` for that bar; Figma binds
///   the Accessible/Selected alias, which is the same value, and Figma wins.
FluentTagPickerStyle resolveFluentTagPickerStyle(
  FluentTagPickerState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final disabled = !state.enabled;
  final filled =
      state.appearance == FluentTagPickerAppearance.filledDarker ||
      state.appearance == FluentTagPickerAppearance.filledLighter;
  final transparent = state.appearance == FluentTagPickerAppearance.transparent;

  final background = switch (state.appearance) {
    _ when disabled && transparent => c.transparentBackground,
    _ when disabled => c.neutralBackgroundDisabled,
    FluentTagPickerAppearance.transparent => c.transparentBackground,
    FluentTagPickerAppearance.filledDarker => c.neutralBackground3,
    FluentTagPickerAppearance.outline ||
    FluentTagPickerAppearance.filledLighter => c.neutralBackground1,
  };

  // Figma paints no stroke at all on Transparent, Filled darker and Filled
  // lighter. The two filled appearances still get the *transparent* token here
  // rather than no border: `transparentStrokeInteractive` turns opaque in high
  // contrast, and a fill-only control with no outline would vanish into the
  // surface there. Recorded in doc/token-divergences.md, and the same call
  // `FluentDropdown` makes about its filled triggers.
  final WidgetStateProperty<Color>? border;
  if (transparent) {
    border = null;
  } else if (filled) {
    // Invisible in light and dark, opaque in high contrast, disabled included:
    // Figma paints no stroke on either filled appearance in any state, so the
    // only thing keeping them outlined in high contrast is this token.
    border = FluentStateColor.tokens(
      rest: disabled
          ? c.transparentStrokeDisabled
          : c.transparentStrokeInteractive,
    );
  } else if (disabled) {
    border = FluentStateColor.tokens(rest: c.neutralStrokeDisabled);
  } else {
    border = FluentStateColor.tokens(
      // Focus moves the outline here, unlike `FluentInput` where all twelve
      // `State=Focus` variants keep `Neutral/Stroke/1/Rest`. Expanded goes one
      // step further, to the Selected token.
      rest: state.open
          ? c.neutralStroke1Selected
          : state.focused
          ? c.neutralStroke1Hover
          : c.neutralStroke1,
      // Figma binds the *Hover* token on Pressed as well; React's
      // `outlineInteractive` moves `:active` to Stroke1Pressed. Figma wins.
      hover: c.neutralStroke1Hover,
      pressed: c.neutralStroke1Hover,
    );
  }

  final WidgetStateProperty<Color>? underline;
  if (filled) {
    underline = null;
  } else if (disabled) {
    underline = FluentStateColor.tokens(rest: c.neutralStrokeDisabled);
  } else {
    underline = FluentStateColor.tokens(
      rest: state.focused
          ? c.neutralStrokeAccessibleHover
          : c.neutralStrokeAccessible,
      hover: c.neutralStrokeAccessibleHover,
      // Figma binds the Hover token on Pressed here too, exactly as it does on
      // the box border.
      pressed: c.neutralStrokeAccessibleHover,
    );
  }

  // The chip gap is upstream's, not Figma's: `useTagPickerGroupStyles` sets
  // `medium: { gap: spacingHorizontalXS }` and gives BOTH `large` and
  // `'extra-large'` `spacingHorizontalSNudge` — so the ramp is 4 / 6 / 6, and
  // it stops at large rather than continuing to 8. Figma's Rest variants hold
  // no tags, so it records no chip-to-chip spacing to contradict it.
  final (height, inset, contentInset, chipGap) = switch (state.size) {
    // The vertical inset is derived rather than transcribed: Figma states the
    // padding around its *text* row (6 / 10 / 12), and this pads a wrapping
    // strip whose tallest child is a chip. Centring a chip in the stated height
    // is what keeps 32 / 40 / 48 true once a tag is present.
    FluentTagPickerSize.medium => (
      32.0,
      FluentSpacing.mNudge,
      4.0,
      FluentSpacing.xs,
    ),
    FluentTagPickerSize.large => (
      40.0,
      FluentSpacing.m,
      4.0,
      FluentSpacing.sNudge,
    ),
    FluentTagPickerSize.extraLarge => (
      48.0,
      FluentSpacing.m,
      8.0,
      FluentSpacing.sNudge,
    ),
  };

  return FluentTagPickerStyle(
    backgroundColor: WidgetStatePropertyAll<Color?>(background),
    borderColor: border,
    borderWidth: WidgetStatePropertyAll<double?>(
      border == null ? FluentStroke.none : FluentStroke.thin,
    ),
    // Every variant binds `Corner-radius/Input/Medium`, which resolves to 4.
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    underlineColor: underline,
    underlineWidth: WidgetStatePropertyAll<double?>(
      underline == null ? FluentStroke.none : FluentStroke.thin,
    ),
    // Upstream's disabled rule is `::after { content: unset }` — a disabled
    // control has no focus bar at all.
    accentColor: disabled
        ? null
        : FluentStateColor.tokens(rest: c.neutralStrokeAccessibleSelected),
    accentWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thick),
    foregroundColor: FluentStateColor.tokens(
      rest: disabled ? c.neutralForegroundDisabled : c.neutralForeground1,
    ),
    placeholderColor: FluentStateColor.tokens(
      rest: disabled ? c.neutralForegroundDisabled : c.neutralForeground4,
    ),
    // The `TagPicker/Secondary action` set (`9064:15390`): caption1 on the
    // `Neutral/Foreground/3` ramp.
    secondaryColor: disabled
        ? FluentStateColor.tokens(rest: c.neutralForegroundDisabled)
        : FluentStateColor.tokens(
            rest: c.neutralForeground3,
            hover: c.neutralForeground3Hover,
            pressed: c.neutralForeground3Pressed,
          ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(theme.typography.body1),
    secondaryTextStyle: WidgetStatePropertyAll<TextStyle?>(
      theme.typography.caption1,
    ),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(horizontal: inset),
    ),
    contentPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(vertical: contentInset),
    ),
    tagSpacing: WidgetStatePropertyAll<double?>(chipGap),
    // ponytail: a fixed field width once chips are present. CSS lets the input
    // flex-grow into whatever is left of the last wrapped line; Flutter's Wrap
    // has no such measurement, and faking it needs a custom RenderBox. Raise
    // `fieldWidth` if a host app types long values.
    fieldWidth: const WidgetStatePropertyAll<double?>(96),
    // `useTagPickerControlStyles` pins `minWidth: 250px`, and the live control
    // reports it at every size. Figma draws all 72 variants at a fixed 320, so
    // it states a design width but no minimum and does not contradict this.
    minimumSize: WidgetStatePropertyAll<Size?>(Size(250, height)),
    mouseCursor: WidgetStatePropertyAll<MouseCursor?>(
      disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.text,
    ),
    // The popup, from the Figma `TagPicker/Dropdown` set (`9064:15397`).
    surfaceColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    // Figma paints no stroke on the popup. A transparent one is kept for the
    // same high-contrast reason as the filled control border above.
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
    // `useTagPickerListStyles` clamps the popup to `maxHeight: 80vh`. There is
    // no viewport here, so this is the fallback the widget uses when no
    // `MediaQuery` is in scope; `FluentTagPicker` overrides it with 80% of the
    // media height wherever there is one.
    surfaceMaxHeight: const WidgetStatePropertyAll<double?>(300),
    // `useTagPicker`'s `usePositioning({ offset: { crossAxis: 0, mainAxis: 2 } })`
    // — the live popup's top edge sits exactly 2px under the control's bottom.
    surfaceOffset: const WidgetStatePropertyAll<double?>(FluentSpacing.xxs),
  );
}

/// Resolves the style of one popup row.
///
/// Returns a [FluentDropdownOptionStyle] on purpose: a tag picker row *is* a
/// listbox row, so it is rendered by [buildFluentDropdownOption] rather than by
/// a second renderer that would drift from it. Only the numbers differ — Figma's
/// `TagPicker/Item` set (`9064:15304`) is 48 tall with a 6px horizontal inset
/// and an 8px gap, where `.ListItem` is 32 tall with a checkmark slot.
///
/// Headers fall through to [resolveFluentDropdownOptionStyle] untouched: the
/// `TagPicker/Dropdown` section header and the dropdown's own are the same
/// 32-tall `caption1Strong` row on `neutralForeground3`.
FluentDropdownOptionStyle resolveFluentTagPickerOptionStyle(
  FluentDropdownOptionState state,
  FluentThemeData theme,
) {
  if (state.type == FluentDropdownOptionType.header) {
    return resolveFluentDropdownOptionStyle(state, theme);
  }

  final c = theme.colors;
  final background = state.enabled
      ? FluentStateColor.tokens(
          rest: c.neutralBackground1,
          hover: c.neutralBackground1Hover,
          pressed: c.neutralBackground1Pressed,
        )
      : FluentStateColor.tokens(rest: c.neutralBackground1);
  final foreground = state.enabled
      ? FluentStateColor.tokens(
          rest: c.neutralForeground2,
          hover: c.neutralForeground2Hover,
          pressed: c.neutralForeground2Pressed,
          disabled: c.neutralForegroundDisabled,
        )
      : FluentStateColor.tokens(rest: c.neutralForegroundDisabled);

  return FluentDropdownOptionStyle(
    backgroundColor: background,
    foregroundColor: foreground,
    checkmarkColor: foreground,
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(theme.typography.body1),
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(horizontal: FluentSpacing.sNudge),
    ),
    labelPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(vertical: FluentSpacing.sNudge),
    ),
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.s),
    minimumSize: const WidgetStatePropertyAll<Size?>(Size(0, 48)),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.click,
    ),
  );
}

/// Renders a tag picker's control from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentTagPickerBaseState] rather than [FluentTagPickerState] on purpose: it
/// never reads the appearance or the size, so a consumer can supply their own
/// style and still use Fluent's layout, bottom rule and accent animation. It
/// renders the control only — the popup is an [Overlay] concern, and its surface
/// has its own builder in [buildFluentTagPickerSurface].
///
/// ## Motion
///
/// One thing animates, and it is the bottom accent bar. That is
/// [FluentInputFocusUnderline], reused verbatim: `useTagPickerControlStyles`
/// and `useInputStyles` declare the same `::after` transition, with the same
/// asymmetric enter/exit durations and the same `prefers-reduced-motion` clamp.
/// Nothing else moves — no transition is declared on the fill, the border or
/// the chips.
///
/// [states] is the live interaction set: hovered, pressed and disabled.
Widget buildFluentTagPicker(
  FluentTagPickerBaseState state,
  FluentTagPickerStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final underlineColor = style.underlineColor?.resolve(states);
  final underlineWidth =
      style.underlineWidth?.resolve(states) ?? FluentStroke.none;
  final accentColor = style.accentColor?.resolve(states);
  final accentWidth = style.accentWidth?.resolve(states) ?? FluentStroke.thick;
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final contentPadding =
      style.contentPadding?.resolve(states) ?? EdgeInsets.zero;
  final spacing = style.tagSpacing?.resolve(states) ?? FluentSpacing.xs;
  final fieldWidth = style.fieldWidth?.resolve(states) ?? 96;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;
  final secondaryColor = style.secondaryColor?.resolve(states);
  final secondaryTextStyle = style.secondaryTextStyle?.resolve(states);

  // With no chips the field takes the whole line, which is the common case and
  // the one an empty picker must get right. With chips it joins the wrap at a
  // fixed width; see `FluentTagPickerStyle.fieldWidth`.
  final Widget content = state.tags.isEmpty
      ? Row(children: <Widget>[Expanded(child: state.field)])
      : Wrap(
          spacing: spacing,
          runSpacing: spacing,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            ...state.tags,
            SizedBox(width: fieldWidth, child: state.field),
          ],
        );

  final secondary = state.secondaryAction == null
      ? null
      : DefaultTextStyle.merge(
          style: (secondaryTextStyle ?? const TextStyle()).copyWith(
            color: secondaryColor,
          ),
          child: state.secondaryAction!,
        );

  // The bottom rule and the accent bar are overlays rather than a one-sided
  // border: Flutter refuses to paint a rounded rectangle whose sides disagree
  // in colour, and Figma models them as separate rectangles anyway.
  final ruleRadius = BorderRadius.only(
    bottomLeft: radius.bottomLeft,
    bottomRight: radius.bottomRight,
  );

  return Stack(
    children: <Widget>[
      ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minimumSize.height,
          minWidth: minimumSize.width,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.backgroundColor?.resolve(states),
            borderRadius: radius,
            border: borderWidth > 0 && borderColor != null
                ? Border.all(color: borderColor, width: borderWidth)
                : null,
          ),
          child: Padding(
            padding: padding.add(contentPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(child: content),
                if (secondary != null)
                  Padding(
                    padding: const EdgeInsets.only(left: FluentSpacing.sNudge),
                    child: secondary,
                  ),
              ],
            ),
          ),
        ),
      ),
      if (underlineColor != null && underlineWidth > 0)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: underlineWidth,
          // The radius has to be painted on a TALLER box and clipped back.
          // Setting it on a 1px-high DecoratedBox looks right and does nothing:
          // Skia scales every corner by `min(edge / sum-of-radii-on-that-edge)`,
          // so a 4px corner on a 1px rule ships as 0.5 and the ends read square
          // against a rounded field. FluentInputUnderline is that clip.
          child: FluentInputUnderline(
            color: underlineColor,
            thickness: underlineWidth,
            borderRadius: ruleRadius,
          ),
        ),
      if (accentColor != null)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: accentWidth,
          child: FluentInputFocusUnderline(
            focused: state.focused,
            color: accentColor,
            borderRadius: ruleRadius,
          ),
        ),
    ],
  );
}

/// Renders the popup surface [child] sits on.
///
/// Separate from [buildFluentTagPicker] because the two are rendered into
/// different branches of the tree: the control into the caller's subtree, this
/// into the [Overlay]. Both read the same [FluentTagPickerStyle].
Widget buildFluentTagPickerSurface(
  FluentTagPickerStyle style,
  Set<WidgetState> states,
  Widget child,
) {
  final radius = style.surfaceRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth =
      style.surfaceBorderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.surfaceBorderColor?.resolve(states);
  final maxHeight = style.surfaceMaxHeight?.resolve(states) ?? double.infinity;

  return ConstrainedBox(
    constraints: BoxConstraints(maxHeight: maxHeight),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: style.surfaceColor?.resolve(states),
        borderRadius: radius,
        border: borderWidth > 0 && borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        boxShadow: style.surfaceShadow?.resolve(states),
      ),
      child: Padding(
        padding: style.surfacePadding?.resolve(states) ?? EdgeInsets.zero,
        child: child,
      ),
    ),
  );
}

/// Overrides the tag picker style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentTagPickerTheme extends InheritedTheme {
  /// Applies [style] to every `FluentTagPicker` in [child].
  const FluentTagPickerTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the appearance and size defaults.
  final FluentTagPickerStyle style;

  /// The nearest tag picker style, or null.
  static FluentTagPickerStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentTagPickerTheme>()?.style;

  @override
  bool updateShouldNotify(FluentTagPickerTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentTagPickerTheme(style: style, child: child);
}

/// Moves the active option by [delta] rows, opening the popup if it is closed.
class FluentTagPickerMoveIntent extends Intent {
  /// Creates an intent to move the active option.
  const FluentTagPickerMoveIntent(this.delta);

  /// How many rows to move. Negative walks towards the top of the list.
  final int delta;
}

/// Commits the active option, or opens the popup when it is closed.
class FluentTagPickerActivateIntent extends Intent {
  /// Creates an activation intent.
  const FluentTagPickerActivateIntent();
}

/// Removes the last chip. Only ever enabled while the field is empty.
class FluentTagPickerRemoveLastIntent extends Intent {
  /// Creates a backspace intent.
  const FluentTagPickerRemoveLastIntent();
}

/// A Fluent 2 tag picker: a text field whose value is a list of chips, with a
/// filtered listbox underneath.
///
/// ```dart
/// FluentTagPicker<String>(
///   selected: chosen,
///   options: const <FluentTagPickerOption<String>>[
///     FluentTagPickerOption<String>(value: 'kat', label: Text('Katri')),
///     FluentTagPickerOption<String>(value: 'ben', label: Text('Ben')),
///   ],
///   onChanged: (values) => setState(() => chosen = values),
/// )
/// ```
///
/// Pass `onChanged: null` to disable it — disabled is a real state here, not a
/// visual treatment: the control stops reporting hover and press, refuses
/// edits, never opens, loses its accent bar entirely, and swaps to the disabled
/// token ramp.
///
/// ## Composition
///
/// Nothing here re-implements a component this package already ships. The chips
/// are `FluentInteractionTag`s, the field is a `FluentInput` with its chrome
/// switched off (see [FluentTagPickerStyle.strippedInputStyle]), the popup rows
/// are rendered by [buildFluentDropdownOption], and the accent bar is
/// [FluentInputFocusUnderline]. Only the control's surface — the fill, the box
/// border and the resting bottom rule — is drawn here, because the tag picker
/// wraps its content where an input lays out a single row.
///
/// ## Keyboard
///
/// | Key | Closed | Open |
/// |---|---|---|
/// | Down / Up | opens on the first option | moves the active option |
/// | Enter | opens | selects the active option |
/// | Escape | — | closes, nothing selected |
/// | Backspace on an empty field | removes the last chip | removes the last chip |
///
/// Backspace is bound through [FluentTagPickerRemoveLastIntent], whose action
/// reports `isEnabled: false` while the field holds text — so the key falls
/// through to the framework's own text editing shortcuts and deletes a
/// character instead. Focus never leaves the field: the popup rows sit outside
/// the traversal order, which is what makes "focus returns to the field on
/// close" structural rather than something this widget has to remember.
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentTagPickerTheme] restyles a subtree; and for anything further,
/// [resolveFluentTagPickerState], [resolveFluentTagPickerStyle] and
/// [buildFluentTagPicker] are public so any one of them can be replaced without
/// forking this widget.
class FluentTagPicker<T> extends StatefulWidget {
  /// Creates a tag picker over [options].
  const FluentTagPicker({
    super.key,
    required this.options,
    this.selected = const <Never>[],
    this.onChanged,
    this.placeholder,
    this.secondaryAction,
    this.appearance = FluentTagPickerAppearance.outline,
    this.size = FluentTagPickerSize.medium,
    this.controller,
    this.focusNode,
    this.style,
    this.optionStyle,
    this.autofocus = false,
    this.semanticLabel,
    this.dismissSemanticLabel,
  });

  /// Every row the popup can show, in order. Headers are included here.
  final List<FluentTagPickerOption<T>> options;

  /// The chosen values, in the order they are shown.
  ///
  /// A value with no matching option is skipped rather than throwing — a list
  /// that changes under a stale selection is a normal state, not a programming
  /// error.
  final List<T> selected;

  /// Invoked with the new selection whenever a chip is added or removed. Null
  /// disables the picker.
  final ValueChanged<List<T>>? onChanged;

  /// Shown while the field is empty.
  final Widget? placeholder;

  /// The trailing action — Fluent's `TagPicker/Secondary action`.
  final Widget? secondaryAction;

  /// Fill and outline treatment.
  final FluentTagPickerAppearance appearance;

  /// Control height.
  final FluentTagPickerSize size;

  /// The query being typed. One is created internally when omitted.
  final TextEditingController? controller;

  /// Focus node for the field. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentTagPickerStyle? style;

  /// Row overrides layered over the theme defaults. Merged last, so it wins.
  final FluentDropdownOptionStyle? optionStyle;

  /// Whether the field takes focus on mount.
  final bool autofocus;

  /// Announced by assistive technology. Use it when no visible label names the
  /// picker — a placeholder is not a label.
  final String? semanticLabel;

  /// Announced for a chip's dismiss half, which has no text of its own.
  ///
  /// Null takes the wording from the ambient [FluentLocalizations],
  /// which falls back to English when no delegate is installed.
  final String? dismissSemanticLabel;

  @override
  State<FluentTagPicker<T>> createState() => _FluentTagPickerState<T>();
}

class _FluentTagPickerState<T> extends State<FluentTagPicker<T>> {
  final LayerLink _link = LayerLink();
  final WidgetStatesController _states = WidgetStatesController();
  final Map<int, GlobalKey> _rowKeys = <int, GlobalKey>{};
  OverlayEntry? _entry;
  TextEditingController? _internalController;
  FocusNode? _internalNode;
  int? _active;

  TextEditingController get _controller =>
      widget.controller ?? (_internalController ??= TextEditingController());

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalNode ??= FocusNode());

  bool get _enabled => widget.onChanged != null;

  bool get _open => _entry != null;

  @override
  void initState() {
    super.initState();
    _states
      ..update(WidgetState.disabled, !_enabled)
      ..addListener(_rebuild);
    _focusNode.addListener(_handleFocusChange);
    // The accent bar and the placeholder both track the field, so the control
    // has to rebuild on the first and last character typed.
    _controller.addListener(_rebuild);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The popup builds from *this* State's context but lives in the Overlay's
    // branch of the tree, so nothing rebuilds it when a dependency here moves.
    // Two visible bugs came out of that: the max height was measured once at
    // open and never again, so resizing the window left the list running off
    // the screen; and a `FluentThemeOverride` swapped under a const subtree
    // left the open popup painting the old tokens. `FluentInfoButton` already
    // does this.
    deferOrRun(() => _entry?.markNeedsBuild());
  }

  @override
  void didUpdateWidget(FluentTagPicker<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalNode)?.removeListener(
        _handleFocusChange,
      );
      _focusNode.addListener(_handleFocusChange);
    }
    if (widget.controller != oldWidget.controller) {
      (oldWidget.controller ?? _internalController)?.removeListener(_rebuild);
      _controller.addListener(_rebuild);
    }
    if (!_enabled) {
      // Clear the interaction states rather than leaving a stale hover behind
      // when a control is disabled mid-gesture.
      _states
        ..update(WidgetState.hovered, false)
        ..update(WidgetState.pressed, false);
      deferOrRun(_close);
    } else if (_open) {
      // `markNeedsBuild` is a `setState` on the Overlay, same as an insert —
      // deferred for the same reason the branch above is.
      deferOrRun(() => _entry?.markNeedsBuild());
    }
    _states.update(WidgetState.disabled, !_enabled);
  }

  @override
  void dispose() {
    _states
      ..removeListener(_rebuild)
      ..dispose();
    (widget.focusNode ?? _internalNode)?.removeListener(_handleFocusChange);
    (widget.controller ?? _internalController)?.removeListener(_rebuild);
    _entry
      ?..remove()
      ..dispose();
    _entry = null;
    _internalNode?.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && _open) deferOrRun(_close);
    _rebuild();
  }

  void _set(WidgetState state, {required bool value}) {
    if (!_enabled && value) return;
    _states.update(state, value);
  }

  /// The options that are not already chosen, which is what the popup lists.
  List<FluentTagPickerOption<T>> get _rows => <FluentTagPickerOption<T>>[
    for (final option in widget.options)
      if (option.isHeader || !widget.selected.contains(option.value)) option,
  ];

  bool _selectable(List<FluentTagPickerOption<T>> rows, int index) =>
      rows[index].enabled && !rows[index].isHeader;

  int? _seek(List<FluentTagPickerOption<T>> rows, int from, int delta) {
    for (var i = from; i >= 0 && i < rows.length; i += delta) {
      if (_selectable(rows, i)) return i;
    }
    return null;
  }

  void _openPopup({int? active}) {
    if (_open || !_enabled) return;
    final overlay = Overlay.of(context, debugRequiredFor: widget);
    // FluentTheme is an InheritedTheme, so this carries it — and any other
    // InheritedTheme between here and the overlay, FluentTagPickerTheme
    // included — across the boundary. MediaQuery does NOT ride along, which is
    // why the popup rows animate nothing.
    final captured = InheritedTheme.capture(from: context, to: overlay.context);
    _active = active ?? _seek(_rows, 0, 1);
    _entry = OverlayEntry(builder: (_) => captured.wrap(_buildPopup()));
    overlay.insert(_entry!);
    setState(() {});
    _revealActive();
  }

  void _close() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    _active = null;
    _rowKeys.clear();
    entry
      ..remove()
      ..dispose();
    if (mounted) setState(() {});
  }

  void _revealActive() {
    final index = _active;
    if (index == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final target = _rowKeys[index]?.currentContext;
      if (target != null) Scrollable.ensureVisible(target, alignment: 0.5);
    });
  }

  void _setActive(int? index) {
    if (index == null || index == _active) return;
    _active = index;
    _entry?.markNeedsBuild();
    _revealActive();
  }

  void _move(int delta) {
    final rows = _rows;
    if (!_open) {
      _openPopup(active: _seek(rows, delta > 0 ? 0 : rows.length - 1, delta));
      return;
    }
    final from = (_active ?? (delta > 0 ? -1 : rows.length)) + delta;
    _setActive(_seek(rows, from, delta));
  }

  void _handleTap() {
    _focusNode.requestFocus();
    _openPopup();
  }

  void _activate() {
    if (!_open) {
      _openPopup();
      return;
    }
    final rows = _rows;
    final index = _active;
    if (index != null && index < rows.length && _selectable(rows, index)) {
      _select(rows[index]);
    } else {
      _close();
    }
  }

  void _select(FluentTagPickerOption<T> option) {
    _controller.clear();
    _close();
    widget.onChanged!(<T>[...widget.selected, option.value]);
    // The popup lists what is left, so committing one row invalidates the
    // active index; reopening starts from the top.
    _focusNode.requestFocus();
  }

  void _remove(T value) {
    if (!_enabled) return;
    widget.onChanged!(<T>[
      for (final selected in widget.selected)
        if (selected != value) selected,
    ]);
  }

  void _removeLast() {
    if (!_enabled || widget.selected.isEmpty) return;
    _remove(widget.selected.last);
  }

  FluentTagSize get _tagSize => switch (widget.size) {
    FluentTagPickerSize.medium => FluentTagSize.small,
    FluentTagPickerSize.large ||
    FluentTagPickerSize.extraLarge => FluentTagSize.medium,
  };

  FluentTagPickerOption<T>? _optionFor(T value) {
    for (final option in widget.options) {
      if (!option.isHeader && option.value == value) return option;
    }
    return null;
  }

  FluentTagPickerStyle _resolvedStyle(FluentTagPickerState state) {
    // Upstream's `maxHeight: 80vh`. The resolver has no `BuildContext` and so
    // cannot read a viewport; it is applied here, below the theme and the
    // caller's style, so either can still override it. With no `MediaQuery` in
    // scope the resolver's own fallback stands.
    //
    // 80vh is a CAP, not a fit: on its own it says nothing about where the
    // field sits, so a picker low on the page threw most of the list off the
    // bottom of the screen. The room left below the trigger is the other half
    // of the constraint, exactly as `FluentDropdown` computes it.
    final viewport = MediaQuery.maybeSizeOf(context)?.height;
    final room = fluentAnchorRoom(context).below;
    return resolveFluentTagPickerStyle(state, FluentTheme.of(context))
        .copyWith(
          surfaceMaxHeight: viewport == null
              ? null
              : WidgetStatePropertyAll<double?>(math.min(viewport * 0.8, room)),
        )
        .merge(FluentTagPickerTheme.maybeOf(context))
        .merge(widget.style);
  }

  Widget _buildPopup() {
    final rows = _rows;
    final theme = FluentTheme.of(context);
    final style = _resolvedStyle(_state(const SizedBox.shrink()));
    const surfaceStates = <WidgetState>{};
    final gap = style.surfaceGap?.resolve(surfaceStates) ?? FluentSpacing.xxs;
    final offset = style.surfaceOffset?.resolve(surfaceStates) ?? 0;
    final themeStyle = FluentDropdownOptionTheme.maybeOf(context);

    return Stack(
      children: <Widget>[
        // A pointer landing anywhere else dismisses without selecting. Nothing
        // is painted, so this is invisible; it exists because a click on inert
        // scenery moves no focus and would otherwise leave the popup open.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: Offset(0, offset),
            // `useListboxStyles` floors the popup at 160 even when
            // `matchTargetSize: 'width'` hands it a narrower trigger — the
            // same pairing `dropdown.dart` already carries.
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: _listboxMinWidth),
              child: SizedBox(
                width: _link.leaderSize?.width,
                // The rows are outside the traversal order on purpose: focus
                // stays on the field the whole time the popup is open.
                child: ExcludeFocus(
                  child: buildFluentTagPickerSurface(
                    style,
                    surfaceStates,
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: gap,
                        children: <Widget>[
                          for (var i = 0; i < rows.length; i++)
                            KeyedSubtree(
                              key: _rowKeys.putIfAbsent(i, GlobalKey.new),
                              child: _buildRow(rows, i, theme, themeStyle),
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
      ],
    );
  }

  Widget _buildRow(
    List<FluentTagPickerOption<T>> rows,
    int index,
    FluentThemeData theme,
    FluentDropdownOptionStyle? themeStyle,
  ) {
    final option = rows[index];
    const gap = FluentSpacing.s;
    final label = option.media == null
        ? option.label
        : Row(
            mainAxisSize: MainAxisSize.min,
            spacing: gap,
            children: <Widget>[
              option.media!,
              Flexible(child: option.label),
            ],
          );

    final state = resolveFluentDropdownOptionState(
      label: label,
      enabled: option.enabled,
      type: option.type,
    );
    final style = resolveFluentTagPickerOptionStyle(
      state,
      theme,
    ).merge(themeStyle).merge(widget.optionStyle);

    if (option.isHeader) {
      return Semantics(
        header: true,
        child: buildFluentDropdownOption(state, style, const <WidgetState>{}),
      );
    }

    return Semantics(
      button: true,
      enabled: option.enabled,
      label: option.text,
      child: FluentInteractive(
        enabled: option.enabled,
        onPressed: option.enabled ? () => _select(option) : null,
        builder: (context, states, _) => ValueListenableBuilder<bool>(
          valueListenable: FluentInputModality.keyboard,
          builder: (context, keyboard, _) =>
              buildFluentDropdownOption(state, style, <WidgetState>{
                ...states,
                // The active row is where the keyboard is, even though the
                // framework's focus never leaves the field. `_active` is set by
                // hover too, so on its own it means "active descendant" —
                // upstream's `data-activedescendant`. The ring belongs to its
                // focus-visible sibling, which is this AND.
                if (index == _active && keyboard) WidgetState.focused,
              }),
        ),
      ),
    );
  }

  FluentTagPickerState _state(Widget field) => resolveFluentTagPickerState(
    field: field,
    enabled: _enabled,
    focused: _focusNode.hasFocus,
    open: _open,
    appearance: widget.appearance,
    size: widget.size,
    tags: <Widget>[
      for (final value in widget.selected)
        if (_optionFor(value) case final option?)
          FluentInteractionTag(
            key: ValueKey<T>(value),
            size: _tagSize,
            icon: option.media,
            onPressed: _enabled ? () => _focusNode.requestFocus() : null,
            onDismiss: _enabled ? () => _remove(value) : null,
            dismissSemanticLabel:
                widget.dismissSemanticLabel ?? fluentL10n(context).remove,
            child: option.label,
          ),
    ],
    secondaryAction: widget.secondaryAction,
  );

  @override
  Widget build(BuildContext context) {
    final states = <WidgetState>{..._states.value};
    // Resolved twice: once without a field to get the style the stripped input
    // is built from, then once with it. The first pass never renders.
    final probe = _state(const SizedBox.shrink());
    final style = _resolvedStyle(probe);

    // A Listener rather than a tap: the input builds its own
    // TextSelectionGestureDetector, and being the innermost member of the arena
    // that one wins every tap over the control's — so a GestureDetector here,
    // or on any ancestor, never fires over the field, which covers nearly the
    // whole control. Raw pointers are not arena members, so this sees the
    // release whoever claims the gesture. Release rather than press, so the
    // list opens under a finished click, the way every other press here reads.
    // `_openPopup` self-guards on disabled and on already-open, so a click that
    // also reaches the control's own tap below opens exactly once.
    final field = Listener(
      onPointerUp: (_) => _openPopup(),
      child: FluentInput(
        controller: _controller,
        focusNode: _focusNode,
        enabled: _enabled,
        autofocus: widget.autofocus,
        placeholder: widget.placeholder,
        style: style.strippedInputStyle(),
        onSubmitted: (_) => _activate(),
      ),
    );

    final state = _state(field);

    Widget control = MouseRegion(
      cursor: style.mouseCursor?.resolve(states) ?? SystemMouseCursors.text,
      onEnter: (_) => _set(WidgetState.hovered, value: true),
      onExit: (_) => _set(WidgetState.hovered, value: false),
      child: Listener(
        onPointerDown: (_) => _set(WidgetState.pressed, value: true),
        onPointerUp: (_) => _set(WidgetState.pressed, value: false),
        onPointerCancel: (_) => _set(WidgetState.pressed, value: false),
        child: GestureDetector(
          // A tap on the padding, not on the field itself, still focuses — and
          // opens, because pointing at the control IS how a mouse reaches the
          // list. `_openPopup` rather than `_activate`: a pointer user has
          // chosen nothing yet, so a second press must never commit the active
          // row. Anything in the control that claims taps for itself — a chip,
          // a `secondaryAction` button — wins the arena over this and so still
          // does its own thing without opening; a bare `secondaryAction`
          // chevron, which claims nothing, falls through to here and expands,
          // which is the only meaning it has.
          behavior: HitTestBehavior.opaque,
          onTap: _enabled ? _handleTap : null,
          child: buildFluentTagPicker(state, style, states),
        ),
      ),
    );

    control = CompositedTransformTarget(link: _link, child: control);

    // Bound here rather than on the focus node so they sit BELOW the app's own
    // text editing shortcuts in lookup order and therefore win — and so that a
    // disabled Backspace action falls through to the character delete.
    return Semantics(
      container: true,
      enabled: _enabled,
      expanded: _open,
      label: widget.semanticLabel,
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.arrowDown):
              FluentTagPickerMoveIntent(1),
          SingleActivator(LogicalKeyboardKey.arrowUp):
              FluentTagPickerMoveIntent(-1),
          SingleActivator(LogicalKeyboardKey.enter):
              FluentTagPickerActivateIntent(),
          SingleActivator(LogicalKeyboardKey.backspace):
              FluentTagPickerRemoveLastIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            FluentTagPickerMoveIntent:
                CallbackAction<FluentTagPickerMoveIntent>(
                  onInvoke: (intent) {
                    _move(intent.delta);
                    return null;
                  },
                ),
            FluentTagPickerActivateIntent:
                CallbackAction<FluentTagPickerActivateIntent>(
                  onInvoke: (_) {
                    _activate();
                    return null;
                  },
                ),
            FluentTagPickerRemoveLastIntent: _RemoveLastAction<T>(this),
            // Only enabled while the popup is open, so Escape still reaches
            // whatever an ancestor does with it when there is nothing to
            // dismiss here.
            DismissIntent: _DismissTagPickerAction<T>(this),
          },
          child: control,
        ),
      ),
    );
  }
}

/// Removes the last chip, and only while the field is empty.
///
/// Reporting `isEnabled: false` rather than doing nothing is what lets the key
/// fall through to `DefaultTextEditingShortcuts` and delete a character.
class _RemoveLastAction<T> extends Action<FluentTagPickerRemoveLastIntent> {
  _RemoveLastAction(this.state);

  final _FluentTagPickerState<T> state;

  @override
  bool isEnabled(FluentTagPickerRemoveLastIntent intent) =>
      state._enabled &&
      state._controller.text.isEmpty &&
      state.widget.selected.isNotEmpty;

  @override
  Object? invoke(FluentTagPickerRemoveLastIntent intent) {
    state._removeLast();
    return null;
  }
}

/// Closes the popup on Escape, and only while there is one to close.
class _DismissTagPickerAction<T> extends Action<DismissIntent> {
  _DismissTagPickerAction(this.state);

  final _FluentTagPickerState<T> state;

  @override
  bool isEnabled(DismissIntent intent) => state._open;

  @override
  Object? invoke(DismissIntent intent) {
    state._close();
    return null;
  }
}
