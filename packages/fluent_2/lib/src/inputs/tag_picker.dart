import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/anchor_metrics.dart';
import '../internal/animated_style.dart';
import '../internal/defer.dart';
import '../internal/input_modality.dart';
import '../internal/interaction.dart';
import '../internal/tap_group.dart';
import '../l10n/l10n.dart';
import '../surfaces/tag.dart';
import 'dropdown_option.dart';
import 'dropdown_option_style.dart';
import 'input.dart';
import 'tag_picker_style.dart';

/// `useListboxStyles.styles.ts` — `minWidth: '160px'` on the popup, which only
/// bites once the trigger it matches is narrower than 160. The same floor
/// `dropdown.dart` carries, for the same reason: both popups render a Listbox.
const double _listboxMinWidth = 160;

/// The focus bar's own corners: `::after`'s `borderBottom*Radius:
/// borderRadiusMedium`, whatever the root's radius is.
const BorderRadius _accentRadius = BorderRadius.vertical(
  bottom: FluentRadius.medium,
);

/// The chevron a tag picker draws by default — upstream's
/// `ChevronDownRegular`, rendered unless the picker has no popover.
const IconData fluentTagPickerChevron = FluentIcons.chevron_down_20_regular;

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
/// Unlike `FluentInput`, the type ramp does **not** move with the size: every
/// upstream size and all 72 Figma variants use `body1` (14/20). Only the
/// height and the insets change.
///
/// The height is the field's, not the root's: upstream floors the root at
/// 32 / 40 / 44, but `TagPickerInput` pads its 20px line by 6 / 10 / 12 either
/// side, so an empty control renders 34 / 42 / 46 with its borders — one less
/// on Transparent, which has only a bottom border.
enum FluentTagPickerSize {
  /// 34 high (32 minimum). The default.
  medium,

  /// 42 high (40 minimum).
  large,

  /// 46 high (44 minimum).
  extraLarge,
}

/// The brand bar growing across the bottom of a focused tag picker.
///
/// `useTagPickerControlStyles.styles.ts` carries the same `::after` rule as
/// `useInputStyles`, down to the same defect — the curve is written into
/// `transitionDelay` rather than `transitionTimingFunction`, so a browser drops
/// it and runs CSS `ease` ([FluentCssCubic.ease]). The port ports what renders,
/// and it renders exactly the input's bar, which is why the constant below is
/// [fluentInputFocusUnderlineEnter] rather than a second copy of it.
const FluentMotionSpec fluentTagPickerAccentEnter =
    fluentInputFocusUnderlineEnter;

/// The brand bar collapsing as focus leaves.
///
/// `durationUltraFast`, on `ease` for the same reason — four times quicker than
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
    this.tagMedia,
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
      tagMedia = null,
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

  /// The chip's leading media once the option is chosen. Null reuses [media].
  ///
  /// Upstream renders the row and the chip as separate elements, and its
  /// stories give them different avatars: 32 in a row, and in the chip the
  /// size the tag sets — 16 / 20 / 28 on the extra-small / small / medium tag
  /// a medium / large / extra-large picker uses.
  final Widget? tagMedia;

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
    this.error = false,
    this.tags = const <Widget>[],
    this.secondaryAction,
    this.expandIcon,
  });

  /// Whether the control accepts input.
  final bool enabled;

  /// Whether the control shows the validation-error treatment. Upstream reads
  /// it from the enclosing `Field`'s `validationState === 'error'`.
  final bool error;

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

  /// The chevron after the content. It needs no tap of its own: a click on it
  /// lands on the control's, which toggles the popup. Null draws none.
  final Widget? expandIcon;
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
    super.error,
    super.tags,
    super.secondaryAction,
    super.expandIcon,
  });

  /// Fill and outline treatment.
  final FluentTagPickerAppearance appearance;

  /// Control height.
  final FluentTagPickerSize size;

  /// Whether the popup is showing. Figma's `Expanded` axis. Styled exactly as
  /// focus is: upstream has no open rule, and an open picker holds focus.
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
  bool error = false,
  FluentTagPickerAppearance appearance = FluentTagPickerAppearance.outline,
  FluentTagPickerSize size = FluentTagPickerSize.medium,
  List<Widget> tags = const <Widget>[],
  Widget? secondaryAction,
  Widget? expandIcon,
}) => FluentTagPickerState(
  enabled: enabled,
  focused: focused,
  open: open,
  error: error,
  appearance: appearance,
  size: size,
  field: field,
  tags: tags,
  secondaryAction: secondaryAction,
  expandIcon: expandIcon,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// The oracle is upstream as it renders — `useTagPickerControlStyles.styles.ts`
/// and `useTagPickerInputStyles.styles.ts` measured in Chrome on the live
/// storybook — not the Figma `Tag picker/TagPicker` set. Where the two
/// disagree, upstream wins:
///
/// * **The type ramp does not move.** Every size renders `body1`, which Figma
///   agrees with; `FluentInput` ramps `caption1`/`body1`/`body2`, the tag
///   picker deliberately does not.
/// * **Only Outline ramps, and hover beats focus.** `outlineInteractive` moves
///   the border to `Stroke1Hover` on `:hover` and to `Stroke1Pressed` on
///   `:active` and on `:focus-within` — a rule of its own, which Griffel sorts
///   before `:hover`. Open is focus: upstream has no open rule, so Figma's
///   `Stroke1Selected` on `Expanded=True` is not what renders. Transparent's
///   bottom border and the filled appearances' `colorTransparentStroke` never
///   move.
/// * **Disabled is transparent**, with `colorNeutralStrokeDisabled` on every
///   side that has a width, for every appearance — not Figma's disabled fill.
/// * **The bar is `colorCompoundBrandStroke`**, Pressed only under
///   `:focus-within:active`, rather than Figma's Accessible/Selected alias.
/// * **Invalid is `colorPaletteRedBorder2`**, on all four sides (the bottom
///   only on Transparent), and only while focus is elsewhere. It outranks
///   Disabled: the class is kept on a disabled control, and its
///   `:not(:focus-within)` selector out-specifies the disabled one, so a
///   disabled invalid control renders red in Chrome.
FluentTagPickerStyle resolveFluentTagPickerStyle(
  FluentTagPickerState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final disabled = !state.enabled;
  final focused = state.focused || state.open;
  final filled =
      state.appearance == FluentTagPickerAppearance.filledDarker ||
      state.appearance == FluentTagPickerAppearance.filledLighter;
  final transparent = state.appearance == FluentTagPickerAppearance.transparent;
  // `colorPaletteRedBorder2`. The palette layer knows nothing of high contrast,
  // where the status token is the system text colour instead — the same
  // expression `resolveFluentInputStyle` uses.
  final danger = c is FluentHighContrastColors
      ? c.statusDangerBorder2
      : c.palette.stroke2Rest(FluentPaletteFamily.red)!;

  final background = switch (state.appearance) {
    _ when disabled => c.transparentBackground,
    FluentTagPickerAppearance.transparent => c.transparentBackground,
    FluentTagPickerAppearance.filledDarker => c.neutralBackground3,
    FluentTagPickerAppearance.outline ||
    FluentTagPickerAppearance.filledLighter => c.neutralBackground1,
  };

  // Transparent has no box border — upstream's `underline` sets only
  // `borderBottom`. The filled appearances keep a `colorTransparentStroke`
  // border rather than none, which is what outlines them in high contrast.
  //
  // The error branch is gated on focus because upstream gates it: `invalid`
  // is written under `:not(:focus-within),:hover:not(:focus-within)`. It
  // comes before disabled for the same reason: that selector out-specifies
  // `disabled`'s plain class.
  final WidgetStateProperty<Color>? border;
  if (transparent) {
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

  // The bottom border side. The filled appearances have none of their own:
  // their box border runs round all four sides.
  final WidgetStateProperty<Color>? underline;
  if (filled) {
    underline = null;
  } else if (state.error && !focused) {
    underline = FluentStateColor.tokens(rest: danger);
  } else if (disabled) {
    underline = FluentStateColor.tokens(rest: c.neutralStrokeDisabled);
  } else if (transparent) {
    underline = FluentStateColor.tokens(rest: c.neutralStrokeAccessible);
  } else {
    underline = FluentStateColor.tokens(
      rest: focused
          ? c.neutralStrokeAccessiblePressed
          : c.neutralStrokeAccessible,
      hover: c.neutralStrokeAccessibleHover,
      pressed: c.neutralStrokeAccessiblePressed,
    );
  }

  // `TagPickerInput` pads its 20px line by SNudge / MNudge / M vertically,
  // which is what sets the height; the root's `minHeight` is only a floor.
  // The expand icon is 16 / 20 / 24 in a box of that same minimum height,
  // pinned to the top and centred, with `marginLeft` XXS / XXS / SNudge.
  //
  // The chip gap is upstream's, not Figma's: `useTagPickerGroupStyles` sets
  // `medium: { gap: spacingHorizontalXS }` and gives BOTH `large` and
  // `'extra-large'` `spacingHorizontalSNudge` — so the ramp is 4 / 6 / 6, and
  // it stops at large rather than continuing to 8.
  final (
    minHeight,
    inputInset,
    iconSize,
    iconGap,
    chipGap,
  ) = switch (state.size) {
    FluentTagPickerSize.medium => (
      32.0,
      FluentSpacing.sNudge,
      FluentSize.size160,
      FluentSpacing.xxs,
      FluentSpacing.xs,
    ),
    FluentTagPickerSize.large => (
      40.0,
      FluentSpacing.mNudge,
      FluentSize.size200,
      FluentSpacing.xxs,
      FluentSpacing.sNudge,
    ),
    FluentTagPickerSize.extraLarge => (
      44.0,
      FluentSpacing.m,
      FluentSize.size240,
      FluentSpacing.sNudge,
      FluentSpacing.sNudge,
    ),
  };
  final iconInset = (minHeight - iconSize) / 2;

  return FluentTagPickerStyle(
    backgroundColor: WidgetStatePropertyAll<Color?>(background),
    borderColor: border,
    borderWidth: WidgetStatePropertyAll<double?>(
      border == null ? FluentStroke.none : FluentStroke.thin,
    ),
    // `underline: { borderRadius: '0' }` — a flat rule with square ends.
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(
      transparent ? BorderRadius.zero : FluentRadius.allMedium,
    ),
    underlineColor: underline,
    underlineWidth: WidgetStatePropertyAll<double?>(
      underline == null ? FluentStroke.none : FluentStroke.thin,
    ),
    // Upstream's `::after` has no disabled rule, but a disabled control cannot
    // take focus, so the bar never shows. Null says so directly.
    accentColor: disabled
        ? null
        : FluentStateColor.tokens(
            rest: c.compoundBrandStroke,
            pressed: c.compoundBrandStrokePressed,
          ),
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
    // `useTagPickerControlStyles` expandIcon: `colorNeutralStrokeAccessible`,
    // `colorNeutralForegroundDisabled` when disabled; no hover rule.
    expandIconColor: FluentStateColor.tokens(
      rest: disabled ? c.neutralForegroundDisabled : c.neutralStrokeAccessible,
    ),
    expandIconSize: WidgetStatePropertyAll<double?>(iconSize),
    expandIconPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsetsDirectional.fromSTEB(iconGap, iconInset, 0, iconInset),
    ),
    // `paddingLeft: spacingHorizontalM` at every size, and `paddingRight` the
    // same plus the aside the chevron sits in.
    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(horizontal: FluentSpacing.m),
    ),
    contentPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(vertical: inputInset),
    ),
    tagSpacing: WidgetStatePropertyAll<double?>(chipGap),
    // ponytail: a fixed field width once chips are present. CSS lets the input
    // flex-grow into whatever is left of the last wrapped line; Flutter's Wrap
    // has no such measurement, and faking it needs a custom RenderBox. Raise
    // `fieldWidth` if a host app types long values.
    fieldWidth: const WidgetStatePropertyAll<double?>(96),
    // `useTagPickerControlStyles` pins `minWidth: 250px`, and the live control
    // reports it at every size, beside the `minHeight` floor.
    minimumSize: WidgetStatePropertyAll<Size?>(Size(250, minHeight)),
    mouseCursor: WidgetStatePropertyAll<MouseCursor?>(
      disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.text,
    ),
    // The popup, from the Figma `TagPicker/Dropdown` set (`9064:15397`).
    surfaceColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    // `useListboxStyles`: `outline: 1px solid colorTransparentStroke`. Invisible
    // in light and dark; it is what outlines the popup in high contrast.
    // [buildFluentTagPickerSurface] paints it outside the box, as an outline
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
/// a second renderer that would drift from it.
///
/// The numbers are upstream's, not Figma's 48-tall `TagPicker/Item`:
/// `TagPickerOption` runs `useOptionStyles` with `checkIcon: undefined`, so a
/// row is the combobox `Option` with no check slot — `padding: 6px 8px` around
/// a `body1` line, 32 tall, `columnGap: spacingHorizontalXS` between media and
/// label, `colorNeutralForeground1` on no fill of its own until hovered.
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
          rest: c.transparentBackground,
          hover: c.neutralBackground1Hover,
          pressed: c.neutralBackground1Pressed,
        )
      : FluentStateColor.tokens(rest: c.transparentBackground);
  final foreground = state.enabled
      ? FluentStateColor.tokens(
          rest: c.neutralForeground1,
          hover: c.neutralForeground1Hover,
          pressed: c.neutralForeground1Pressed,
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
      EdgeInsets.symmetric(
        horizontal: FluentSpacing.s,
        vertical: FluentSpacing.sNudge,
      ),
    ),
    labelPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.zero,
    ),
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.xs),
    minimumSize: const WidgetStatePropertyAll<Size?>(Size(0, 32)),
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
  final expandIconColor = style.expandIconColor?.resolve(states);
  final expandIconSize =
      style.expandIconSize?.resolve(states) ?? FluentSize.size200;
  final expandIconPadding =
      style.expandIconPadding?.resolve(states) ?? EdgeInsets.zero;

  // With no chips the field takes the whole line, which is the common case and
  // the one an empty picker must get right. With chips it joins the wrap at a
  // fixed width; see `FluentTagPickerStyle.fieldWidth`.
  //
  // One Wrap either way, with the field always its last child, so the field's
  // element survives the first chip arriving. A Row swapped for a Wrap there
  // remounted the `EditableText` under a node that already had focus, and a
  // new `EditableText` opens no input connection until focus *changes* — so
  // after the first pick the field looked focused and swallowed every key.
  final Widget content = Wrap(
    spacing: spacing,
    runSpacing: spacing,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: <Widget>[
      ...state.tags,
      SizedBox(
        width: state.tags.isEmpty ? double.infinity : fieldWidth,
        child: state.field,
      ),
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

  final expandIcon = state.expandIcon == null
      ? null
      : Padding(
          padding: expandIconPadding,
          child: IconTheme.merge(
            data: IconThemeData(color: expandIconColor, size: expandIconSize),
            child: state.expandIcon!,
          ),
        );

  // CSS box model: a border that exists takes space, so the content sits inside
  // it — 1px on every side for Outline and the filled appearances (whose
  // transparent border still counts), the bottom only for Transparent. A null
  // colour is no border at all.
  final side = borderColor == null ? FluentStroke.none : borderWidth;
  final widths = EdgeInsets.fromLTRB(
    side,
    side,
    side,
    underlineColor == null ? side : underlineWidth,
  );

  return Stack(
    // The bar overhangs a borderless root: see below.
    clipBehavior: Clip.none,
    // Passthrough, so a parent's tight height stretches the box itself, as a
    // CSS `height` would. A loose Stack laid the box out at its own height and
    // pinned the bar to the bottom of the taller Stack, below it.
    fit: StackFit.passthrough,
    children: <Widget>[
      ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minimumSize.height,
          minWidth: minimumSize.width,
        ),
        // Background, then border, then content, then the bar: CSS's paint
        // order for a root and its positioned `::after`. The border is the
        // painter `FluentInput` uses, which joins the darker bottom side to the
        // others on the CSS corner diagonal.
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: style.backgroundColor?.resolve(states),
            borderRadius: radius,
          ),
          child: CustomPaint(
            painter: FluentInputBorderPainter(
              radius: radius,
              borderColor: borderColor,
              borderWidth: side,
              bottomBorderColor: underlineColor,
              bottomBorderWidth: widths.bottom,
            ),
            child: Padding(
              padding: padding.add(widths),
              // Upstream's aside is positioned over the root's right padding,
              // top to bottom, and follows the content directly. The
              // secondary action stretches with it — its button runs the full
              // inner height, label centred — while the expand icon alone is
              // `alignSelf: flex-start`, so wrapped chips grow the control
              // downwards past a chevron that stays on the first line. The
              // content is the root's `alignItems: center`.
              //
              // ponytail: IntrinsicHeight is what lets a Row stretch to its
              // tallest child under an unbounded parent; it costs a second
              // measuring pass of a handful of chips, and it asserts on a
              // `LayoutBuilder` in a chip label or the secondary action. A
              // render object that lays the aside out after the content is
              // the upgrade, if either ever matters.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Padding(padding: contentPadding, child: content),
                        ],
                      ),
                    ),
                    ?secondary,
                    if (expandIcon != null)
                      Align(
                        alignment: AlignmentDirectional.topCenter,
                        child: expandIcon,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      // `::after { left: -1px; right: -1px; bottom: -1px }` against the padding
      // box: flush with the border box when the sides are 1px, a pixel past it
      // each side on Transparent, which has none. Its 4px bottom radii are its
      // own, not the root's, so they stay rounded on Transparent's square root.
      if (accentColor != null)
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
        // Outside the box, like the CSS `outline` it ports: it takes no room
        // from the rows, which sit at the surface padding exactly.
        border: borderWidth > 0 && borderColor != null
            ? Border.all(
                color: borderColor,
                width: borderWidth,
                strokeAlign: BorderSide.strokeAlignOutside,
              )
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
/// are dismissible `FluentTag`s, the field is a `FluentInput` with its chrome
/// switched off (see [FluentTagPickerStyle.strippedInputStyle]), the popup rows
/// are rendered by [buildFluentDropdownOption], and the accent bar is
/// [FluentInputFocusUnderline]. Only the control's surface — the fill and the
/// border, painted by [FluentInputBorderPainter] — and the expand chevron are
/// drawn here, because the tag picker wraps its content where an input lays
/// out a single row.
///
/// A click on the control outside its text field — the padding, the space
/// around the chips, the chevron and the band above and below it — toggles the
/// popup, as upstream's mousedown handler does. A click in the text field only
/// ever opens it, so a caret placement leaves an open list alone (see
/// `build`); upstream's input toggles there too.
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
/// ## Dismissing by pointer needs a [TapRegionSurface]
///
/// An open popup is dismissed by a tap outside it via [TapRegion], which does
/// nothing without a [TapRegionSurface] above it. [WidgetsApp] installs one
/// (`widgets/app.dart:1836`) and `FluentApp` wraps [WidgetsApp], so an ordinary
/// app — and the widget tests — are covered. A picker mounted under a bare
/// [Overlay] with no [WidgetsApp] anywhere above it silently loses outside-tap
/// dismissal; Escape, choosing a row and moving focus away still close it.
///
/// Nothing is drawn over the page while the popup is up, deliberately. A click
/// on a control behind an open popup dismisses the popup *and* presses that
/// control, hover still tracks, and the page still scrolls — which is what
/// upstream's document-level `useOnClickOutside` gives React.
///
/// Clicking the control itself while the popup is open does **not** dismiss it:
/// the field is a text input, so a click there is a caret placement, and the
/// list has to survive it. That is a combobox, not a toggle.
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
    this.expandIcon = const Icon(fluentTagPickerChevron),
    this.appearance = FluentTagPickerAppearance.outline,
    this.size = FluentTagPickerSize.medium,
    this.error = false,
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

  /// The chevron after the content, which toggles the popup. Pass null to
  /// draw none; upstream renders `ChevronDownRegular` unless told otherwise.
  final Widget? expandIcon;

  /// Fill and outline treatment.
  final FluentTagPickerAppearance appearance;

  /// Control height.
  final FluentTagPickerSize size;

  /// Whether to paint the validation-error treatment: a
  /// `colorPaletteRedBorder2` border while the control is not focused.
  /// Upstream takes it from the enclosing `Field`'s error state.
  final bool error;

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

  /// Announced for a chip's dismiss glyph, which has no text of its own.
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
  ScrollPosition? _scrollPosition;

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
    // page scrolling under an open popup slides the control up the screen
    // without touching a single InheritedWidget, so the `min(80vh, room below)`
    // measured at open is stale the moment the page moves — a picker opened a
    // few rows tall at the bottom edge stayed that tall with the whole viewport
    // free beneath it. `@fluentui/react-positioning` repositions on scroll
    // rather than closing, so re-measuring is the faithful answer —
    // `RawMenuAnchor` reads this same notifier to CLOSE
    // (raw_menu_anchor.dart:499-503, 544-550), which a combobox must not do.
    //
    // Attached here rather than at open so a Scrollable swapped under the
    // control is picked up for free: `Scrollable.maybeOf` takes a dependency on
    // `_ScrollableScope`, which notifies when its position changes identity,
    // and `_handleScroll` is a null check while the popup is closed.
    //
    // ponytail: gated on `isScrollingNotifier`, so the height re-measures when
    // a scroll starts and stops rather than on every frame between — a long
    // list would otherwise rebuild every row a frame for the length of a fling,
    // and those rows are exactly what the constraint exists to clip. Wheel and
    // trackpad scrolling flips the notifier once per tick
    // (scroll_position_with_single_context.dart:222-235), so the desktop and
    // web case this package targets does re-measure continuously; a
    // programmatic `jumpTo` flips it not at all. Listen to `_scrollPosition`
    // itself if a touch fling ever has to be frame-accurate.
    _scrollPosition?.isScrollingNotifier.removeListener(_handleScroll);
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.isScrollingNotifier.addListener(_handleScroll);
  }

  /// Re-measures the popup against the room left after the page moved under it.
  ///
  /// Deferred because `isScrollingNotifier` can flip during layout — a viewport
  /// whose content shrinks goes ballistic from `applyContentDimensions` — and
  /// invalidating an entry is a `setState` on the Overlay.
  void _handleScroll() => deferOrRun(() => _entry?.markNeedsBuild());

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
    // The listener is what would outlive this State; the position itself is the
    // Scrollable's to dispose, and `removeListener` is documented as safe to
    // call on a notifier that has already gone.
    _scrollPosition?.isScrollingNotifier.removeListener(_handleScroll);
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

  /// A click on the control outside the field: `useTagPickerControl`'s
  /// mousedown handler runs `setOpen(!open)` for the root, the tag group, the
  /// aside and the expand icon, and focuses the field.
  void _toggle() {
    if (_open) {
      _close();
      return;
    }
    _handleTap();
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

  /// Upstream's `tagPickerSizeToTagSize`: each picker size takes the tag one
  /// step smaller than its name.
  FluentTagSize get _tagSize => switch (widget.size) {
    FluentTagPickerSize.medium => FluentTagSize.extraSmall,
    FluentTagPickerSize.large => FluentTagSize.small,
    FluentTagPickerSize.extraLarge => FluentTagSize.medium,
  };

  /// Upstream's `tagPickerAppearanceToTagAppearance`: an outlined tag on the
  /// darker fill, a filled one everywhere else.
  FluentTagAppearance get _tagAppearance =>
      widget.appearance == FluentTagPickerAppearance.filledDarker
      ? FluentTagAppearance.outline
      : FluentTagAppearance.filled;

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

    // Nothing is drawn over the page: the outside-tap barrier this used to
    // carry is gone, and dismissal lives on the trigger's TapRegion group in
    // `build`. See the note there.
    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: Offset(0, offset),
        // Same group as the control, so a pointer landing on a row — or on the
        // padding between rows, or dragging the list — is "inside" and does not
        // dismiss. Orthogonal to the ExcludeFocus below: that governs
        // traversal, this governs taps.
        child: adoptFluentTapGroup(
          _hostTapGroup,
          TapRegion(
            groupId: this,
            // And in the *field's* group as well, so a pointer on a row does not
            // read as a tap outside the text field. Without this, `EditableText`
            // unfocuses on pointer-down on every desktop platform
            // (`_EditableTextTapOutsideAction`, `editable_text.dart:6876`), which
            // trips `_handleFocusChange` and tears the popup down before the
            // pointer is even released — so a mouse click on a row selected
            // nothing at all. `TextFieldTapRegion` is the framework's own answer
            // to "this widget belongs to that text field".
            child: TextFieldTapRegion(
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
        ),
      ),
    );
  }

  Widget _buildRow(
    List<FluentTagPickerOption<T>> rows,
    int index,
    FluentThemeData theme,
    FluentDropdownOptionStyle? themeStyle,
  ) {
    final option = rows[index];
    // The combobox `Option`'s `columnGap: spacingHorizontalXS`.
    const gap = FluentSpacing.xs;
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

    // No check slot: `TagPickerOption` hands `useOptionStyles` an undefined
    // `checkIcon`, so the label starts at the row's own 8px inset.
    final state = option.isHeader
        ? resolveFluentDropdownOptionState(label: label, type: option.type)
        : FluentDropdownOptionState(
            enabled: option.enabled,
            selected: false,
            showCheckmark: false,
            reserveCheckmark: false,
            label: label,
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
    error: widget.error,
    appearance: widget.appearance,
    size: widget.size,
    // Upstream's stories put a plain dismissible `Tag` in the group, not an
    // InteractionTag: no divider, and the small dismiss glyph. A disabled
    // picker keeps the glyph, greyed and inert, as upstream's disabled story
    // does.
    //
    // That `Tag` is one `<button>`, so a left click anywhere on it dismisses
    // it, over the arrow cursor, and the control's mousedown toggle skips it:
    // that fires only on the root, the group itself, the aside and the expand
    // icon (Chrome). `FluentTag` makes only its glyph a button, hence the tap
    // here; the glyph's own still wins over it.
    tags: <Widget>[
      for (final value in widget.selected)
        if (_optionFor(value) case final option?)
          GestureDetector(
            key: ValueKey<T>(value),
            // The glyph is the chip's announced dismiss action.
            excludeFromSemantics: true,
            onTap: _enabled ? () => _remove(value) : null,
            child: MouseRegion(
              cursor: _enabled ? SystemMouseCursors.basic : MouseCursor.defer,
              child: FluentTag(
                size: _tagSize,
                appearance: _tagAppearance,
                enabled: _enabled,
                icon: option.tagMedia ?? option.media,
                onDismiss: () => _remove(value),
                dismissSemanticLabel:
                    widget.dismissSemanticLabel ?? fluentL10n(context).remove,
                child: option.label,
              ),
            ),
          ),
    ],
    secondaryAction: widget.secondaryAction,
    expandIcon: widget.expandIcon == null
        ? null
        // No tap of its own: a click falls through to the control's, which
        // toggles — the same for the chevron as for the band around it, which
        // upstream's 32 / 40 / 44 tall icon span also covers. The cursor is
        // upstream's `cursor: pointer` on the icon.
        : MouseRegion(
            cursor: _enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden,
            child: widget.expandIcon,
          ),
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
    // The control's tap below therefore never fires for the same click, which
    // matters: it toggles, and firing after this would close what this opened.
    //
    // `_openPopup` self-guards on disabled and on already-open, so clicking the
    // field while the list is up moves the caret and leaves the list exactly
    // as it was: no close, no close-then-reopen.
    final field = Listener(
      onPointerUp: (_) => _openPopup(),
      // Typing opens the list, as upstream's input does after a pick or an
      // Escape has closed it — on the key, not the edit: its
      // `getDropdownActionFromKey` says 'Type' for one printable character
      // that is not Space, with no Alt, Ctrl or Meta, so Space, Backspace and
      // a paste change the text and leave the list shut (Chrome). A desktop
      // embedder reports Escape, Backspace, Enter and Tab as control
      // characters, which are not typing either. Ignored either way, so the
      // key still reaches the field.
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onKeyEvent: (_, event) {
          final character = event.character;
          final keyboard = HardwareKeyboard.instance;
          if (event is KeyDownEvent &&
              character != null &&
              character.length == 1 &&
              character.trim().isNotEmpty &&
              !LogicalKeyboardKey.isControlCharacter(character) &&
              !keyboard.isAltPressed &&
              !keyboard.isControlPressed &&
              !keyboard.isMetaPressed) {
            _openPopup();
          }
          return KeyEventResult.ignored;
        },
        child: FluentInput(
          controller: _controller,
          focusNode: _focusNode,
          enabled: _enabled,
          autofocus: widget.autofocus,
          placeholder: widget.placeholder,
          style: style.strippedInputStyle(),
          onSubmitted: (_) => _activate(),
        ),
      ),
    );

    final state = _state(field);

    Widget control = MouseRegion(
      cursor: style.mouseCursor?.resolve(states) ?? SystemMouseCursors.text,
      onEnter: (_) => _set(WidgetState.hovered, value: true),
      onExit: (_) => _set(WidgetState.hovered, value: false),
      // Chrome sets `:active` for the primary and middle buttons, not for a
      // right press (storybook).
      child: Listener(
        onPointerDown: (event) => _set(
          WidgetState.pressed,
          value: event.buttons != kSecondaryMouseButton,
        ),
        onPointerUp: (_) => _set(WidgetState.pressed, value: false),
        onPointerCancel: (_) => _set(WidgetState.pressed, value: false),
        child: GestureDetector(
          // A tap on the control but not on the field — the padding, the gaps
          // around the chips, the chevron — focuses the field and toggles the
          // list, as upstream's mousedown handler does. Never `_activate`: a
          // pointer user has chosen nothing yet, so a second press must never
          // commit the active row. Anything in the control that claims taps for
          // itself — the field, a chip, a `secondaryAction` button — wins the
          // arena over this and so still does its own thing; a bare
          // `secondaryAction` chevron, which claims nothing, falls through to
          // here and toggles, which is the only meaning it has.
          behavior: HitTestBehavior.opaque,
          onTap: _enabled ? _toggle : null,
          child: buildFluentTagPicker(state, style, states),
        ),
      ),
    );

    control = CompositedTransformTarget(link: _link, child: control);

    // Outside taps dismiss the popup, replacing a full-screen
    // `HitTestBehavior.opaque` barrier that used to be drawn over the page from
    // inside the OverlayEntry. That barrier swallowed the click that dismissed:
    // a button behind an open popup needed two clicks, hover never reached it,
    // and a wheel event never reached the enclosing Scrollable, so the page
    // could not scroll either. Upstream's `useOnClickOutside` is a
    // document-level listener — the click dismisses AND lands — and a TapRegion
    // group is the same shape.
    //
    // `groupId: this` ties the control to the popup across the Overlay
    // boundary. Everything the user can point at that belongs to this picker is
    // inside this subtree — the field, every chip including its dismiss glyph,
    // and `secondaryAction` — so none of them dismiss.
    //
    // Known cost: `RenderTapRegionSurface` "does not participate in the gesture
    // disambiguation system" (`widgets/tap_region.dart:189-193`), so a
    // pointer-down outside that turns into a drag-scroll counts as an outside
    // tap and dismisses. Touch and trackpad only — the wheel is not a
    // pointer-down, and `FluentScrollBehavior` deliberately keeps the mouse out
    // of `dragDevices`. Left as is; the browser does the same thing.
    control = TapRegion(
      groupId: this,
      // Registered only while the popup is up, so nothing is listening for
      // outside taps the rest of the time.
      onTapOutside: _open ? (_) => _close() : null,
      // In the field's group too — see the note in `_buildPopup`. The chips and
      // `secondaryAction` sit beside the `EditableText`, not inside it, so
      // without this a click on a chip's dismiss glyph is a tap OUTSIDE the text
      // field: the field unfocuses, `_handleFocusChange` closes the popup, and
      // removing one chip collapses the list the user was still picking from.
      child: TextFieldTapRegion(child: control),
    );

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
