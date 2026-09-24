import 'dart:async';
import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/anchor_metrics.dart';
import '../internal/animated_style.dart';
import '../internal/defer.dart';
import '../internal/input_modality.dart';
import '../internal/interaction.dart';
import '../internal/tap_group.dart';
import 'dropdown_option.dart';
import 'dropdown_option_style.dart';
import 'dropdown_style.dart';
import 'input.dart';

/// `useDropdownStyles.styles.ts` — `minWidth: '250px'` on the trigger root, at
/// every size.
const double _triggerMinWidth = 250;

/// `useListboxStyles.styles.ts` — `minWidth: '160px'` on the popup, which only
/// bites once the trigger it matches is narrower than 160.
const double _listboxMinWidth = 160;

/// The focus bar's own corners: `::after`'s `borderBottom*Radius:
/// borderRadiusMedium`, whatever the root's radius is.
const BorderRadius _accentRadius = BorderRadius.vertical(
  bottom: FluentRadius.medium,
);

/// How a dropdown trigger is filled and outlined.
///
/// Names follow the Figma `Appearance` axis verbatim. Upstream calls
/// [FluentDropdownAppearance.transparent] `underline` and hyphenates the two
/// filled members; the values are identical.
enum FluentDropdownAppearance {
  /// Neutral fill, a border all round, and an accessible rule along the bottom.
  /// The default, and upstream's `outline`.
  outline,

  /// No fill and no border — only the bottom rule. Upstream's `underline`.
  transparent,

  /// `neutralBackground1` with no visible border and no bottom rule. Upstream's
  /// `filled-lighter`.
  fillLighter,

  /// `neutralBackground3` with no visible border and no bottom rule. Upstream's
  /// `filled-darker`.
  fillDarker,
}

/// Trigger height and type ramp. Figma's `Size` axis.
enum FluentDropdownSize {
  /// 24 high, caption type.
  small,

  /// 32 high, body type. The default.
  medium,

  /// 40 high, `body2` type.
  large,
}

/// The accent rule arriving as the dropdown takes focus or opens.
///
/// Transcribed from `useDropdownStyles.styles.ts`:
///
/// ```ts
/// ':focus-within::after': {
///   transform: 'scaleX(1)',
///   transitionProperty: 'transform',
///   transitionDuration: tokens.durationNormal,
///   transitionDelay: tokens.curveDecelerateMid,
/// }
/// ```
///
/// Upstream puts the curve in `transitionDelay` rather than
/// `transitionTimingFunction` — a cubic-bezier is not a valid delay value, so a
/// browser drops it and runs the transition on the CSS default `ease`
/// ([FluentCssCubic.ease]) with no delay, which is what the live storybook
/// samples. The port ports what renders, not what the typo suggests was meant.
///
/// The bar itself is [FluentInputFocusUnderline], whose spec comes off the same
/// `::after` rule — so this is an alias rather than a second copy of it.
const FluentMotionSpec fluentDropdownAccentEnter =
    fluentInputFocusUnderlineEnter;

/// The accent rule collapsing as the dropdown closes.
///
/// `durationUltraFast` from the same `::after` rule, on `ease` for the same
/// reason. Four times faster than [fluentDropdownAccentEnter], which is
/// upstream's asymmetry, not a typo.
///
/// An alias of [fluentInputFocusUnderlineExit], for the reason given on
/// [fluentDropdownAccentEnter].
const FluentMotionSpec fluentDropdownAccentExit = fluentInputFocusUnderlineExit;

/// The chevron every Fluent dropdown trigger carries.
const IconData fluentDropdownChevron = FluentIcons.chevron_down_20_regular;

/// Everything needed to render a dropdown trigger, independent of the design
/// axes.
///
/// The counterpart of `FluentButtonBaseState`. [buildFluentDropdown] takes this
/// rather than [FluentDropdownState], which is what makes "Fluent's state, my
/// own styling, Fluent's rendering" a supported path rather than a fork.
@immutable
class FluentDropdownBaseState {
  /// Creates a base state.
  const FluentDropdownBaseState({
    required this.enabled,
    required this.open,
    required this.chevron,
    this.focused = false,
    this.error = false,
    this.value,
    this.placeholder,
  });

  /// Whether the trigger responds to input.
  final bool enabled;

  /// Whether the popup is showing. Drives the accent rule exactly as focus
  /// does, because upstream's selector is `:focus-within` and an open dropdown
  /// always contains focus.
  final bool open;

  /// Whether the trigger holds focus, however it arrived.
  ///
  /// **Not** `WidgetState.focused`, which in this package means
  /// *keyboard-visible* focus. Upstream hangs the bar and the focused border
  /// off `:focus-within`, which a click satisfies too — the trigger is a
  /// `<button>`, and a browser focuses a button on mousedown — so the bar stays
  /// after a pointer open and close, until focus leaves. The same call
  /// `FluentInput` makes.
  final bool focused;

  /// Whether the trigger shows the validation-error treatment. Upstream's
  /// `aria-invalid="true"` on the button.
  final bool error;

  /// The chevron widget.
  final Widget chevron;

  /// The selected option's label, or null when nothing is selected.
  final Widget? value;

  /// What to show while [value] is null.
  final Widget? placeholder;
}

/// A dropdown's fully resolved state, including the design axes.
@immutable
class FluentDropdownState extends FluentDropdownBaseState {
  /// Creates a resolved state.
  const FluentDropdownState({
    required super.enabled,
    required super.open,
    required super.chevron,
    required this.appearance,
    required this.size,
    super.focused,
    super.error,
    super.value,
    super.placeholder,
  });

  /// Fill and outline treatment.
  final FluentDropdownAppearance appearance;

  /// Height and type ramp.
  final FluentDropdownSize size;
}

/// Builds the state a dropdown trigger will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentDropdownState resolveFluentDropdownState({
  bool enabled = true,
  bool open = false,
  bool focused = false,
  bool error = false,
  FluentDropdownAppearance appearance = FluentDropdownAppearance.outline,
  FluentDropdownSize size = FluentDropdownSize.medium,
  Widget chevron = const Icon(fluentDropdownChevron),
  Widget? value,
  Widget? placeholder,
}) => FluentDropdownState(
  enabled: enabled,
  open: open,
  focused: focused,
  error: error,
  appearance: appearance,
  size: size,
  chevron: chevron,
  value: value,
  placeholder: placeholder,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// The oracle is upstream as it renders — `useDropdownStyles.styles.ts`
/// measured in Chrome on the live storybook — not the Figma `Dropdown` set,
/// which has no State axis at all. Where the two disagree, upstream wins:
///
/// * **Only the outline moves.** The fill is fixed per appearance and the
///   chevron is `colorNeutralStrokeAccessible` in every state: no rule touches
///   either on `:hover` or `:active`. Of the borders, only `outlineInteractive`
///   has interaction rules; Underline's bottom border and the filled
///   appearances' `colorTransparentStroke` never change.
/// * **Hover beats focus.** `outlineInteractive` writes `:focus-within` as a
///   rule of its own, which Griffel sorts *before* `:hover`, so a focused
///   trigger shows `Stroke1Pressed` / `StrokeAccessiblePressed` until the
///   pointer is over it, and the Hover stops then. `FluentInput` differs:
///   there `:active,:focus-within` is one rule and focus holds through a hover.
/// * **The bar turns Pressed only under `:focus-within:active`.**
/// * **Disabled** is a transparent fill with `colorNeutralStrokeDisabled` on
///   every side that has a width, for every appearance.
/// * **Invalid is `colorPaletteRedBorder2`**, on all four sides (the bottom
///   only on Transparent), and only while focus is elsewhere. It outranks
///   Disabled: unlike Input's, the class is not dropped on a disabled trigger,
///   and its `:not(:focus-within)` selector out-specifies the disabled one, so
///   a disabled invalid trigger renders red in Chrome.
FluentDropdownStyle resolveFluentDropdownStyle(
  FluentDropdownState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final disabled = !state.enabled;
  final focused = state.focused || state.open;
  final transparent = state.appearance == FluentDropdownAppearance.transparent;
  final filled =
      state.appearance == FluentDropdownAppearance.fillLighter ||
      state.appearance == FluentDropdownAppearance.fillDarker;
  // `colorPaletteRedBorder2`. The palette layer knows nothing of high contrast,
  // where the status token is the system text colour instead — the same
  // expression `resolveFluentInputStyle` uses.
  final danger = c is FluentHighContrastColors
      ? c.statusDangerBorder2
      : c.palette.stroke2Rest(FluentPaletteFamily.red)!;

  final background = switch (state.appearance) {
    _ when disabled => c.transparentBackground,
    FluentDropdownAppearance.transparent => c.transparentBackground,
    FluentDropdownAppearance.fillDarker => c.neutralBackground3,
    FluentDropdownAppearance.outline ||
    FluentDropdownAppearance.fillLighter => c.neutralBackground1,
  };

  // Transparent is the one appearance with no box border at all — upstream's
  // `underline` sets only `borderBottom`. The filled appearances keep a
  // `colorTransparentStroke` border rather than none, which is what outlines
  // them in high contrast.
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

  // Upstream's button padding is `3px 6px 3px 8px` / `5px 10px 5px 12px` /
  // `7px 12px 7px 18px` inside the 1px border — the left side is the right
  // side plus the column gap — with `columnGap` XXS / XXS / SNudge between the
  // text and the chevron, and the chevron's own `marginLeft` the same again.
  // The vertical inset is what centres a 16 / 20 / 24 glyph in 24 / 32 / 40.
  final (height, inset, gap, chevronSize, textStyle) = switch (state.size) {
    FluentDropdownSize.small => (
      24.0,
      FluentSpacing.sNudge,
      FluentSpacing.xxs,
      FluentSize.size160,
      theme.typography.caption1,
    ),
    FluentDropdownSize.medium => (
      32.0,
      FluentSpacing.mNudge,
      FluentSpacing.xxs,
      FluentSize.size200,
      theme.typography.body1,
    ),
    FluentDropdownSize.large => (
      40.0,
      FluentSpacing.m,
      FluentSpacing.sNudge,
      FluentSize.size240,
      theme.typography.body2,
    ),
  };
  final vertical = (height - 2 * FluentStroke.thin - chevronSize) / 2;

  return FluentDropdownStyle(
    backgroundColor: WidgetStatePropertyAll<Color?>(background),
    foregroundColor: FluentStateColor.tokens(
      rest: c.neutralForeground1,
      disabled: c.neutralForegroundDisabled,
    ),
    // Upstream's `.placeholder` rule, which the Figma trigger text agrees with.
    placeholderColor: FluentStateColor.tokens(
      rest: c.neutralForeground4,
      disabled: c.neutralForegroundDisabled,
    ),
    borderColor: border,
    borderWidth: WidgetStatePropertyAll<double?>(
      border == null ? FluentStroke.none : FluentStroke.thin,
    ),
    // `underline: { borderRadius: '0' }` — a flat rule with square ends.
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(
      transparent ? BorderRadius.zero : FluentRadius.allMedium,
    ),
    underlineColor: underline,
    // Upstream's `::after` has no disabled rule, but a disabled `<button>`
    // cannot hold focus, so the bar never shows. Null says so directly.
    accentColor: disabled
        ? null
        : FluentStateColor.tokens(
            rest: c.compoundBrandStroke,
            pressed: c.compoundBrandStrokePressed,
          ),
    accentWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thick),
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    // No vertical inset on the text: the chevron's sets the height, and the
    // text centres in it as upstream's grid centres it. Padding the text too
    // would let a taller platform type ramp grow the trigger past 24/32/40,
    // which `FluentInput` does not do either.
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsetsDirectional.only(start: inset + gap),
    ),
    gap: WidgetStatePropertyAll<double?>(gap),
    // `useDropdownStyles.expandIcon`: `colorNeutralStrokeAccessible`, with no
    // hover or press rule; `colorNeutralForegroundDisabled` when disabled.
    chevronColor: FluentStateColor.tokens(
      rest: disabled ? c.neutralForegroundDisabled : c.neutralStrokeAccessible,
    ),
    chevronSize: WidgetStatePropertyAll<double?>(chevronSize),
    chevronPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsetsDirectional.fromSTEB(gap, vertical, inset, vertical),
    ),
    // `useDropdownStyles.styles.ts` puts `minWidth: '250px'` on the root, and a
    // live probe reads 250 at all three sizes. Without it the trigger collapses
    // to its content, which is the most visible way this diverges from React.
    // The root states no height: 22 / 30 / 38 of button plus its borders, so
    // Transparent, with a bottom border only, is a pixel shorter.
    minimumSize: WidgetStatePropertyAll<Size?>(
      Size(_triggerMinWidth, transparent ? height - FluentStroke.thin : height),
    ),
    // `cursor: 'pointer'` on the button; `disabled` makes it `not-allowed`.
    mouseCursor: WidgetStatePropertyAll<MouseCursor?>(
      disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
    ),
    surfaceColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    // `useListboxStyles`: `outline: 1px solid colorTransparentStroke`. Invisible
    // in light and dark; it is what outlines the popup in high contrast.
    // [buildFluentDropdownSurface] paints it outside the box, as an outline
    // sits, so it takes no room from the rows.
    surfaceBorderColor: FluentStateColor.tokens(rest: c.transparentStroke),
    surfaceBorderWidth: const WidgetStatePropertyAll<double?>(
      FluentStroke.thin,
    ),
    // Figma binds `Corner-radius/Modal/Medium`; upstream's listbox states none
    // and inherits the popover surface's `borderRadiusMedium`. Same 4.
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
    // Deliberately null. Neither Figma nor `useListboxStyles.styles.ts` states
    // a maximum, because upstream's positioning layer writes one inline from
    // the space left below the trigger and recomputes it on every reposition.
    // `FluentDropdown` reproduces that at build time; a non-null value here —
    // or on `FluentDropdownTheme`, or on the widget's own `style` — is the
    // caller's override and wins.
    surfaceMaxHeight: null,
    // Figma stacks the popup flush against the trigger, but `useComboboxPositioning`
    // offsets it `{ crossAxis: 0, mainAxis: 2 }` and a live probe reads the 2px
    // gap. React wins: flush against the trigger reads as one merged surface.
    surfaceOffset: const WidgetStatePropertyAll<double?>(FluentSpacing.xxs),
  );
}

/// Renders a dropdown trigger from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentDropdownBaseState] rather than [FluentDropdownState] on purpose: it
/// never reads the appearance or the size, so a consumer can supply their own
/// style and still use Fluent's layout and accent animation. It renders the
/// trigger only — the popup is an [Overlay] concern, and its surface has its
/// own builder in [buildFluentDropdownSurface].
///
/// ## Motion
///
/// One thing animates, and it is the bottom accent rule: upstream's `::after`
/// is `transform: scaleX(0)` at rest and `scaleX(1)` under `:focus-within`, so
/// the brand rule grows from the centre outwards. See
/// [fluentDropdownAccentEnter] and [fluentDropdownAccentExit] for the two
/// durations. Nothing else moves — the border changes on the frame the pointer
/// arrives, because `useDropdownStyles` declares no transition on it.
///
/// [states] is the live interaction set from [FluentInteractive].
Widget buildFluentDropdown(
  FluentDropdownBaseState state,
  FluentDropdownStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final underlineColor = style.underlineColor?.resolve(states);
  final accentColor = style.accentColor?.resolve(states);
  final accentWidth = style.accentWidth?.resolve(states) ?? FluentStroke.thick;
  final foreground = state.value == null
      ? style.placeholderColor?.resolve(states)
      : style.foregroundColor?.resolve(states);
  final textStyle = style.textStyle?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.mNudge;
  final chevronColor = style.chevronColor?.resolve(states);
  final chevronSize = style.chevronSize?.resolve(states) ?? FluentSize.size200;
  final chevronPadding =
      style.chevronPadding?.resolve(states) ?? EdgeInsets.zero;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;

  Widget label = Padding(
    padding: padding,
    // heightFactor, or the Align fills the whole loose height it is offered and
    // a dropdown in a Column becomes as tall as the screen.
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      heightFactor: 1,
      child: state.value ?? state.placeholder ?? const SizedBox.shrink(),
    ),
  );
  if (textStyle != null || foreground != null) {
    label = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      child: label,
    );
  }

  final content = Row(
    children: <Widget>[
      Expanded(child: label),
      SizedBox(width: gap),
      Padding(
        padding: chevronPadding,
        child: IconTheme.merge(
          data: IconThemeData(color: chevronColor, size: chevronSize),
          child: state.chevron,
        ),
      ),
    ],
  );

  // CSS box model: a border that exists takes space, so the content sits inside
  // it — 1px on every side for Outline and the filled appearances (whose
  // transparent border still counts), the bottom only for Transparent. A null
  // colour is no border at all. The bottom side is as wide as the others, as a
  // CSS `border-width` makes it; 1px when there are no others.
  final side = borderColor == null ? FluentStroke.none : borderWidth;
  final widths = EdgeInsets.fromLTRB(
    side,
    side,
    side,
    underlineColor == null || side > 0 ? side : FluentStroke.thin,
  );

  return Stack(
    // The bar overhangs a borderless root: see below.
    clipBehavior: Clip.none,
    // Passthrough, so a parent's tight height stretches the box itself, as a
    // CSS `height` would. A loose Stack laid the box out at its own 24 / 32 /
    // 40 and pinned the bar to the bottom of the taller Stack, below it.
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
            child: Padding(padding: widths, child: content),
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
            focused: state.focused || state.open,
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
/// Separate from [buildFluentDropdown] because the two are rendered into
/// different branches of the tree: the trigger into the caller's subtree, this
/// into the [Overlay]. Both read the same [FluentDropdownStyle].
Widget buildFluentDropdownSurface(
  FluentDropdownStyle style,
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

/// Overrides the dropdown style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentDropdownTheme extends InheritedTheme {
  /// Applies [style] to every `FluentDropdown` in [child].
  const FluentDropdownTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the appearance and size defaults.
  final FluentDropdownStyle style;

  /// The nearest dropdown style, or null.
  static FluentDropdownStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentDropdownTheme>()?.style;

  @override
  bool updateShouldNotify(FluentDropdownTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentDropdownTheme(style: style, child: child);
}

/// Moves the active option by [delta] rows, opening the popup if it is closed.
class FluentDropdownMoveIntent extends Intent {
  /// Creates an intent to move the active option.
  const FluentDropdownMoveIntent(this.delta);

  /// How many rows to move. Negative walks towards the top of the list.
  final int delta;
}

/// Jumps the active option to the first or last option row.
class FluentDropdownEdgeIntent extends Intent {
  /// Creates an intent to jump to an end of the list.
  const FluentDropdownEdgeIntent({required this.last});

  /// Whether to jump to the last row rather than the first.
  final bool last;
}

/// Opens the popup, or commits the active option when it is already open.
class FluentDropdownActivateIntent extends Intent {
  /// Creates an activation intent.
  const FluentDropdownActivateIntent();
}

/// A Fluent 2 single-select dropdown.
///
/// ```dart
/// FluentDropdown<String>(
///   value: city,
///   placeholder: const Text('Pick a city'),
///   options: const [
///     FluentDropdownOption(value: 'lis', label: Text('Lisbon')),
///     FluentDropdownOption(value: 'osl', label: Text('Oslo')),
///   ],
///   onChanged: (value) => setState(() => city = value),
/// )
/// ```
///
/// Pass `onChanged: null` to disable it — disabled is a real state here, not a
/// visual treatment: the trigger stops reporting hover and press, refuses
/// focus, never opens, and swaps to the disabled token ramp.
///
/// ## Single select only
///
/// Multi-select is **not modelled**. Figma's `.ListItem` set has a
/// `Type=Multi select` variant whose leading slot is a checkbox rather than a
/// checkmark, and upstream's `Dropdown` takes `multiselect` with an array
/// value; neither is ported. [value] is one option's value or null.
///
/// ## Keyboard
///
/// | Key | Closed | Open |
/// |---|---|---|
/// | Down / Up | opens, active on the selected option, else the first | moves the active option, disabled rows included |
/// | Alt+Up | as Up | as Enter |
/// | Home / End | — | jumps to first / last |
/// | PageUp / PageDown | — | moves ten options, stopping at either end |
/// | Enter (either) / Space | opens | selects the active option and closes; nothing on a disabled one |
/// | Escape | — | closes, nothing selected |
/// | Tab | moves on | closes, then moves on |
///
/// Shift, Ctrl, Meta and Alt change none of these keys but Up, as upstream
/// reads the key alone. A key marked — is not taken at all, so it still
/// reaches an ancestor: PageUp and PageDown scroll the page, as upstream leaves
/// them to the browser, and Escape closes a dialog around the dropdown.
///
/// Focus never leaves the trigger while the popup is open — the rows are
/// deliberately outside the traversal order, so "focus returns to the trigger
/// on close" is structural rather than something this widget has to remember to
/// do. The active row is marked with [WidgetState.focused] all the same,
/// because that is what keyboard-visible focus *means* to the user.
///
/// ## Dismissing by pointer needs a [TapRegionSurface]
///
/// An open popup is dismissed by a tap outside it via [TapRegion], which does
/// nothing without a [TapRegionSurface] above it. [WidgetsApp] installs one
/// (`widgets/app.dart:1836`) and `FluentApp` wraps [WidgetsApp], so an ordinary
/// app — and the widget tests — are covered. A dropdown mounted under a bare
/// [Overlay] with no [WidgetsApp] anywhere above it silently loses outside-tap
/// dismissal; Escape, Tab and choosing a row still close it.
///
/// Nothing is drawn over the page while the popup is up, deliberately. A click
/// on a control behind an open popup dismisses the popup *and* presses that
/// control, hover still tracks, and the page still scrolls — which is what
/// upstream's document-level `useOnClickOutside` gives React.
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentDropdownTheme] restyles a subtree; and for anything further,
/// [resolveFluentDropdownState], [resolveFluentDropdownStyle] and
/// [buildFluentDropdown] are public so any one of them can be replaced without
/// forking this widget. Rows follow the same three rungs through [optionStyle]
/// and [FluentDropdownOptionTheme].
class FluentDropdown<T> extends StatefulWidget {
  /// Creates a dropdown over [options].
  const FluentDropdown({
    super.key,
    required this.options,
    this.value,
    this.onChanged,
    this.placeholder,
    this.appearance = FluentDropdownAppearance.outline,
    this.size = FluentDropdownSize.medium,
    this.error = false,
    this.style,
    this.optionStyle,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// The rows the popup shows, in order. Headers are included here.
  final List<FluentDropdownOption<T>> options;

  /// The selected value, or null for none.
  ///
  /// A value with no matching option renders as the placeholder rather than
  /// throwing — a list that changes under a stale value is a normal state, not
  /// a programming error.
  final T? value;

  /// Invoked with the chosen value. Null disables the dropdown.
  final ValueChanged<T>? onChanged;

  /// What the trigger shows while [value] selects nothing.
  final Widget? placeholder;

  /// Fill and outline treatment.
  final FluentDropdownAppearance appearance;

  /// Height and type ramp.
  final FluentDropdownSize size;

  /// Whether to paint the validation-error treatment: a
  /// `colorPaletteRedBorder2` border while the trigger is not focused.
  final bool error;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentDropdownStyle? style;

  /// Row overrides layered over the theme defaults. Merged last, so it wins.
  final FluentDropdownOptionStyle? optionStyle;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Announced by assistive technology alongside the selected value.
  final String? semanticLabel;

  @override
  State<FluentDropdown<T>> createState() => _FluentDropdownState<T>();
}

class _FluentDropdownState<T> extends State<FluentDropdown<T>> {
  final LayerLink _link = LayerLink();
  final Map<int, GlobalKey> _rowKeys = <int, GlobalKey>{};
  OverlayEntry? _entry;
  FocusNode? _internalNode;
  int? _active;
  ScrollPosition? _scrollPosition;

  /// Mirrors the node, so a property-only notification is not read as a blur.
  bool _focused = false;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalNode ??= FocusNode());

  bool get _enabled => widget.onChanged != null;

  bool get _open => _entry != null;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    _focused = _focusNode.hasFocus;
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
    // page scrolling under an open popup slides the trigger up the screen
    // without touching a single InheritedWidget. A dropdown opened 78 high in
    // the last strip of the viewport stayed 78 high after the page scrolled
    // 460, with the room it had been measured against now empty beneath it.
    // `@fluentui/react-positioning` repositions on scroll rather than closing,
    // so re-measuring is the faithful answer — `RawMenuAnchor` reads this same
    // notifier to CLOSE (raw_menu_anchor.dart:499-503, 544-550), which a
    // dropdown must not do.
    //
    // Attached here rather than at open so a Scrollable swapped under the
    // trigger is picked up for free: `Scrollable.maybeOf` takes a dependency on
    // `_ScrollableScope`, which notifies when its position changes identity,
    // and `_handleScroll` is a null check while the popup is closed.
    //
    // ponytail: gated on `isScrollingNotifier`, so the height re-measures when
    // a scroll starts and stops rather than on every frame between — a 40-row
    // list would otherwise rebuild 40 rows a frame for the length of a fling,
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
  void didUpdateWidget(FluentDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _focusNode.addListener(_handleFocusChange);
      _focused = _focusNode.hasFocus;
    }
    if (!_enabled) {
      deferOrRun(_close);
    } else if (_open) {
      // A list that changed under the popup can leave `_active` past its end
      // or on a header. Upstream re-runs `first()` when the children change
      // with nothing active, and a row gone from the DOM is not active.
      // ponytail: by index, so a row removed ABOVE the active one shifts it;
      // track the active value if that ever matters.
      final active = _active;
      if (active == null ||
          active >= widget.options.length ||
          widget.options[active].isHeader) {
        _active = _seek(0, 1);
        _revealActive();
      }
      // Deferred for the same reason the close above is: `didUpdateWidget` runs
      // inside the parent's build, and the entry lives in the Overlay's branch,
      // which that build has already passed. A parent that rebuilds while the
      // popup is up — anything driving the list from its own state — would
      // otherwise trip "markNeedsBuild() called during build".
      deferOrRun(() => _entry?.markNeedsBuild());
    }
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
    _internalNode?.dispose();
    super.dispose();
  }

  /// Latched on a real transition, because a [FocusNode] notifies for property
  /// writes too; see `FluentInput`'s own listener.
  void _handleFocusChange() {
    if (_focused == _focusNode.hasFocus) return;
    // The bar and the focused border follow focus itself, not just the popup.
    setState(() => _focused = _focusNode.hasFocus);
    // Tab, or a click on something else, takes focus away; the popup must not
    // outlive it.
    if (!_focused && _open) deferOrRun(_close);
  }

  /// A press anywhere outside the dropdown and its popup.
  ///
  /// Closes the popup and gives up focus, which is what a browser does to a
  /// focused `<button>` when the page is clicked elsewhere — and therefore what
  /// retracts upstream's bar. Flutter keeps a button's focus through an outside
  /// tap, so without this the bar would outlive the click.
  void _handleTapOutside() {
    _close();
    // Blur only if nothing else took focus. The press may have landed on a
    // field that focuses itself on pointer-down, as Chrome's mousedown does —
    // synchronously, or a microtask later (TimePicker, another Dropdown).
    // Blurring on this same event parked focus on the route's scope and
    // cancelled that request, so a held press on another field focused
    // nothing. Two microtasks on, the FocusManager has applied every such
    // request; if focus is still here, the press hit the page body, which
    // blurs in a browser too. Still inside this event, so the bar's exit
    // starts on the same frame as before.
    //
    // ponytail: assumes a requester defers at most one microtask; a later one
    // would lose to this blur. Move the check to a post-frame callback then.
    scheduleMicrotask(
      () => scheduleMicrotask(() {
        if (mounted && _focusNode.hasFocus) _focusNode.unfocus();
      }),
    );
  }

  int? get _selectedIndex {
    for (var i = 0; i < widget.options.length; i++) {
      final option = widget.options[i];
      if (!option.isHeader && option.value == widget.value) return i;
    }
    return null;
  }

  /// The first option row at or after [from], walking by [delta]. Disabled
  /// rows count: upstream's option walker visits them (Chrome), and only a
  /// header is not an option.
  int? _seek(int from, int delta) {
    for (var i = from; i >= 0 && i < widget.options.length; i += delta) {
      if (!widget.options[i].isHeader) return i;
    }
    return null;
  }

  void _openPopup() {
    if (_open || !_enabled) return;
    final overlay = Overlay.of(context, debugRequiredFor: widget);
    // FluentTheme is an InheritedTheme, so this carries it — and any other
    // InheritedTheme between here and the overlay, including
    // FluentDropdownOptionTheme — across the boundary.
    final captured = InheritedTheme.capture(from: context, to: overlay.context);
    _active = _selectedIndex ?? _seek(0, 1);
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

  void _toggle() {
    if (_open) {
      _close();
      return;
    }
    // Focus the trigger before opening. Arrow handling lives in this widget's
    // Shortcuts, and the rows are deliberately outside the traversal order, so
    // focus has to be HERE for the keyboard to reach the popup at all. Opening
    // by pointer used to leave focus wherever it was, which left the list
    // stranded on whichever row `_openPopup` seeded — the selected one.
    // Upstream gets this free: its trigger is a real `<button>`, and a browser
    // focuses a button on mousedown.
    _focusNode.requestFocus();
    _openPopup();
  }

  void _select(int index) {
    final option = widget.options[index];
    _close();
    widget.onChanged!(option.value);
  }

  void _setActive(int? index) {
    if (index == null || index == _active) return;
    _active = index;
    _entry?.markNeedsBuild();
    _revealActive();
  }

  /// Upstream's `scrollIntoView`, run on the next frame once the row exists:
  /// nothing while the row is fully in view, else the least scroll that shows
  /// it 2px clear of the edge it was past (Chrome: arrows, Home/End and
  /// opening on a selection alike).
  void _revealActive() {
    final index = _active;
    if (index == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final target = _rowKeys[index]?.currentContext;
      final row = target?.findRenderObject();
      if (row is! RenderBox || !row.attached) return;
      final position = Scrollable.of(target!).position;
      final top = RenderAbstractViewport.of(
        row,
      ).getOffsetToReveal(row, 0).offset;
      final bottom = top + row.size.height;
      const buffer = 2.0;
      final double to;
      if (top < position.pixels) {
        to = top - buffer;
      } else if (bottom > position.pixels + position.viewportDimension) {
        to = bottom - position.viewportDimension + buffer;
      } else {
        return;
      }
      position.jumpTo(
        to.clamp(position.minScrollExtent, position.maxScrollExtent),
      );
    });
  }

  void _move(int delta) {
    // Up opens exactly as Down does, on the selection or the first row.
    if (!_open) {
      _openPopup();
      return;
    }
    // One option row at a time, each revealed in turn, staying put at an end:
    // upstream's PageDown is `next()` ten times, each with its own
    // `scrollIntoView`, and `next()` on the last row stays there (Chrome).
    final step = delta.sign;
    for (var i = 0; i < delta.abs(); i++) {
      final from = _active ?? (step > 0 ? -1 : widget.options.length);
      _setActive(_seek(from + step, step));
    }
  }

  int get _last => widget.options.length - 1;

  void _edge({required bool last}) =>
      _setActive(last ? _seek(_last, -1) : _seek(0, 1));

  void _activate() {
    if (!_open) {
      _openPopup();
      return;
    }
    // On a disabled row Enter and Space do nothing; the list stays open.
    final index = _active;
    if (index == null) {
      _close();
    } else if (widget.options[index].enabled) {
      _select(index);
    }
  }

  FluentDropdownStyle _resolvedStyle(FluentDropdownState state) =>
      resolveFluentDropdownStyle(
        state,
        FluentTheme.of(context),
      ).merge(FluentDropdownTheme.maybeOf(context)).merge(widget.style);

  FluentDropdownState _state() {
    final selected = _selectedIndex;
    return resolveFluentDropdownState(
      enabled: _enabled,
      open: _open,
      focused: _focused,
      error: widget.error,
      appearance: widget.appearance,
      size: widget.size,
      value: selected == null ? null : widget.options[selected].label,
      placeholder: widget.placeholder,
    );
  }

  Widget _buildPopup() {
    final style = _resolvedStyle(_state());
    const surfaceStates = <WidgetState>{};
    final gap = style.surfaceGap?.resolve(surfaceStates) ?? FluentSpacing.xxs;
    final offset = style.surfaceOffset?.resolve(surfaceStates) ?? 0;

    // Upstream's positioning layer writes `max-height` inline from the space
    // left below the trigger and recomputes it on every reposition; a fixed
    // number would clip a long list on a tall screen and overflow a short one.
    // The popup opens under the trigger, so it starts at the trigger's bottom
    // edge plus the 2px gap.
    //
    // Measured off the trigger's render box rather than the leader layer — see
    // [fluentAnchorRect] for why the layer lies once the page has scrolled.
    final anchor = fluentAnchorRect(context);
    // The listbox's padding sits INSIDE its scroller upstream, so rows scroll
    // through it and `scrollIntoView` measures its 2px from the listbox's own
    // edge. Moved into the SingleChildScrollView below; the surface gets none.
    final padding =
        style.surfacePadding?.resolve(surfaceStates) ?? EdgeInsets.zero;
    final surfaceStyle = style.copyWith(
      surfacePadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
        EdgeInsets.zero,
      ),
      surfaceMaxHeight:
          style.surfaceMaxHeight ??
          WidgetStatePropertyAll<double?>(
            math.max(
              MediaQuery.sizeOf(context).height -
                  (anchor?.bottom ?? 0) -
                  offset,
              0,
            ),
          ),
    );
    final optionThemeStyle = FluentDropdownOptionTheme.maybeOf(context);
    final theme = FluentTheme.of(context);

    final rows = <Widget>[
      for (var i = 0; i < widget.options.length; i++) ...<Widget>[
        // `useOptionGroupStyles.styles.ts` — every `OptionGroup` but the last
        // draws `borderBottom: strokeWidthThin solid colorNeutralStroke2`
        // below itself, with `paddingBottom: spacingHorizontalXS` (4) above the
        // rule and `marginBottom: spacingVerticalXS` (4) below it. That
        // pseudo-element is itself a flex item, so those 4s stack ON TOP of the
        // list's own `rowGap: spacingHorizontalXXS` (2) rather than absorbing
        // it: the real gap is 6 above and 6 below. A group starts at a header
        // here, so the rule goes before every header that is not the first row,
        // and 4 of inset plus the Column's 2 of gap reproduces the 6.
        //
        // ponytail: the rule spans the content width. Upstream's `margin: 0
        // -4px` bleeds it across the surface padding, which Flutter cannot
        // express as a negative inset — an `OverflowBox` sized from
        // `_link.leaderSize` would, if the 4 either side ever shows.
        if (i > 0 && widget.options[i].isHeader)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: FluentSpacing.xs),
            child: SizedBox(
              height: FluentStroke.thin,
              child: ColoredBox(color: theme.colors.neutralStroke2),
            ),
          ),
        KeyedSubtree(
          key: _rowKeys.putIfAbsent(i, GlobalKey.new),
          child: _buildRow(i, theme, optionThemeStyle),
        ),
      ],
    ];

    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: Offset(0, offset),
        // Same group as the trigger, so a pointer landing on a row — or on the
        // padding between rows — is "inside" and does not dismiss. Orthogonal
        // to the ExcludeFocus below: that governs traversal, this governs taps.
        child: adoptFluentTapGroup(
          _hostTapGroup,
          TapRegion(
            groupId: this,
            // Upstream positions the listbox with `matchTargetSize: 'width'`,
            // and Figma draws it exactly as wide as the trigger — but
            // `useListboxStyles` also floors it at `minWidth: 160px`, which
            // only shows once the trigger is narrower than that.
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: _listboxMinWidth),
              child: SizedBox(
                width: _link.leaderSize?.width,
                // The rows are outside the traversal order on purpose: focus
                // stays on the trigger the whole time the popup is open, which
                // is what makes "focus returns to the trigger on close"
                // structural.
                child: ExcludeFocus(
                  child: buildFluentDropdownSurface(
                    surfaceStyle,
                    surfaceStates,
                    SingleChildScrollView(
                      padding: padding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: gap,
                        children: rows,
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
    int index,
    FluentThemeData theme,
    FluentDropdownOptionStyle? themeStyle,
  ) {
    final option = widget.options[index];
    final state = resolveFluentDropdownOptionState(
      label: option.label,
      enabled: option.enabled,
      selected: !option.isHeader && option.value == widget.value,
      type: option.type,
    );
    final style = resolveFluentDropdownOptionStyle(
      state,
      theme,
    ).merge(themeStyle).merge(widget.optionStyle);

    if (option.isHeader) {
      return Semantics(
        header: true,
        child: buildFluentDropdownOption(state, style, const <WidgetState>{}),
      );
    }

    final row = FluentInteractive(
      enabled: option.enabled,
      onPressed: option.enabled ? () => _select(index) : null,
      mouseCursor:
          style.mouseCursor?.resolve(const <WidgetState>{}) ??
          SystemMouseCursors.click,
      builder: (context, states, _) => ValueListenableBuilder<bool>(
        valueListenable: FluentInputModality.keyboard,
        builder: (context, keyboard, _) =>
            buildFluentDropdownOption(state, style, <WidgetState>{
              ...states,
              // The active row is where the keyboard is, even though the
              // framework's focus never leaves the trigger. `_active` is
              // upstream's `data-activedescendant`: only opening and the keys
              // move it, never hover, which is the row's own state here as
              // upstream. The ring belongs to its focus-visible sibling, which
              // is this AND.
              if (index == _active && keyboard) WidgetState.focused,
            }),
      ),
    );

    return Semantics(
      button: true,
      selected: state.selected,
      enabled: option.enabled,
      inMutuallyExclusiveGroup: true,
      label: option.text,
      child: row,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _state();
    final style = _resolvedStyle(state);

    final cursor =
        style.mouseCursor?.resolve(const <WidgetState>{}) ??
        SystemMouseCursors.click;
    final trigger = FluentInteractive(
      // Tapping an open trigger closes it; it never commits, because a pointer
      // user has not chosen anything yet. Enter and Space go through
      // FluentDropdownActivateIntent below instead, which does commit.
      onPressed: _enabled ? _toggle : null,
      enabled: _enabled,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      mouseCursor: cursor,
      // A held right press keeps the hover look in Chrome (#c7c7c7 sides,
      // #0f6cbd bar); a middle one is `:active`.
      pressedOnSecondary: false,
      // Here as well, because `FluentInteractive` shows the arrow while
      // disabled, and the resolved style's is upstream's `not-allowed`.
      builder: (context, states, _) => MouseRegion(
        cursor: cursor,
        child: buildFluentDropdown(state, style, states),
      ),
    );

    // No `value:` here on purpose. The selected option's own label is already
    // in the tree and merges into this node, so announcing it a second time as
    // a semantic value made a screen reader say it twice — the same call
    // Material's own dropdown makes.
    return Semantics(
      button: true,
      enabled: _enabled,
      expanded: _open,
      label: widget.semanticLabel,
      child: TapRegion(
        groupId: this,
        // Registered only while the popup is up or the trigger holds focus, so
        // nothing is listening for outside taps the rest of the time. See
        // [_handleTapOutside] for why focus alone is enough.
        //
        // This replaced a full-screen `HitTestBehavior.opaque` barrier drawn
        // over the page. The barrier swallowed the click that dismissed: a
        // button behind an open popup needed two clicks, hover never reached
        // it, and a wheel event never reached the enclosing Scrollable.
        // Upstream's `useOnClickOutside` is a document-level listener — the
        // click dismisses AND lands — and a TapRegion group is the same shape.
        //
        // Known cost: `RenderTapRegionSurface` "does not participate in the
        // gesture disambiguation system" (`widgets/tap_region.dart:189-193`),
        // so a pointer-down outside that turns into a drag-scroll counts as an
        // outside tap and dismisses. That is touch and trackpad only — the
        // wheel is not a pointer-down, and `FluentScrollBehavior` deliberately
        // keeps the mouse out of `dragDevices`. Left as is; the browser does
        // the same thing.
        onTapOutside: _open || _focused ? (_) => _handleTapOutside() : null,
        child: CompositedTransformTarget(
          link: _link,
          // Bound here rather than on the focus node so they sit *below* the
          // app's own Enter/Space -> ActivateIntent mapping and above the
          // trigger's, which is the only way Enter can mean "commit the active
          // option" while a tap still only toggles.
          child: Shortcuts(
            shortcuts: const <ShortcutActivator, Intent>{
              // Alt+Up is upstream's 'CloseSelect', Enter's action, while open
              // and 'Open', as Up, while closed (getDropdownActionFromKey,
              // Chrome). First, so plain Up below never sees it.
              _AnyModifiers(LogicalKeyboardKey.arrowUp, alt: true):
                  FluentDropdownActivateIntent(),
              _AnyModifiers(LogicalKeyboardKey.arrowDown):
                  FluentDropdownMoveIntent(1),
              _AnyModifiers(LogicalKeyboardKey.arrowUp):
                  FluentDropdownMoveIntent(-1),
              _AnyModifiers(LogicalKeyboardKey.home): FluentDropdownEdgeIntent(
                last: false,
              ),
              _AnyModifiers(LogicalKeyboardKey.end): FluentDropdownEdgeIntent(
                last: true,
              ),
              _AnyModifiers(LogicalKeyboardKey.pageUp): _PageIntent(-10),
              _AnyModifiers(LogicalKeyboardKey.pageDown): _PageIntent(10),
              // The keypad's Enter is `e.key` 'Enter' upstream too; left to
              // the app's ActivateIntent it would only toggle, never commit.
              _AnyModifiers(LogicalKeyboardKey.enter):
                  FluentDropdownActivateIntent(),
              _AnyModifiers(LogicalKeyboardKey.numpadEnter):
                  FluentDropdownActivateIntent(),
              _AnyModifiers(LogicalKeyboardKey.space):
                  FluentDropdownActivateIntent(),
              _AnyModifiers(LogicalKeyboardKey.escape): _CloseIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                FluentDropdownMoveIntent:
                    CallbackAction<FluentDropdownMoveIntent>(
                      onInvoke: (intent) {
                        _move(intent.delta);
                        return null;
                      },
                    ),
                FluentDropdownEdgeIntent:
                    _WhileOpenAction<FluentDropdownEdgeIntent>(
                      this,
                      onInvoke: (intent) {
                        _edge(last: intent.last);
                        return null;
                      },
                    ),
                _PageIntent: _WhileOpenAction<_PageIntent>(
                  this,
                  onInvoke: (intent) {
                    _move(intent.delta);
                    return null;
                  },
                ),
                FluentDropdownActivateIntent:
                    CallbackAction<FluentDropdownActivateIntent>(
                      onInvoke: (_) {
                        _activate();
                        return null;
                      },
                    ),
                // Not DismissIntent: `Actions.maybeFind` stops at the nearest
                // action for an intent, enabled or not, so a closed trigger
                // holding one hid a FluentDialog's own from the app's Escape.
                _CloseIntent: _WhileOpenAction<_CloseIntent>(
                  this,
                  onInvoke: (_) {
                    _close();
                    return null;
                  },
                ),
              },
              // Chrome focuses a `<button>` on mousedown, whichever button, so
              // the bar grows while a press is still held; a tap would focus
              // only on release. A microtask later, so an outside-press blur
              // dispatched after this on the same event — another focused
              // dropdown's, a text field's — cannot undo it. Touch focuses on
              // the tap, as a browser's does.
              child: Listener(
                onPointerDown: (event) {
                  if (!_enabled || event.kind != PointerDeviceKind.mouse) {
                    return;
                  }
                  scheduleMicrotask(() {
                    if (mounted && _enabled) _focusNode.requestFocus();
                  });
                },
                child: trigger,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// PageUp and PageDown: [delta] option rows, and only while open.
class _PageIntent extends Intent {
  const _PageIntent(this.delta);

  final int delta;
}

/// Escape: closes the popup, and only while there is one.
class _CloseIntent extends Intent {
  const _CloseIntent();
}

/// [key] under any modifiers; with [alt], only while Alt is among them.
///
/// Upstream's `getDropdownActionFromKey` reads `e.key` alone: Shift, Ctrl,
/// Meta and Alt change nothing but Up, where Alt commits (Chrome, the Default
/// story). A [SingleActivator] wants its modifiers exact, so Shift+PageDown or
/// Ctrl+Home slipped past the list.
class _AnyModifiers extends ShortcutActivator {
  const _AnyModifiers(this.key, {this.alt = false});

  final LogicalKeyboardKey key;
  final bool alt;

  @override
  Iterable<LogicalKeyboardKey> get triggers => <LogicalKeyboardKey>[key];

  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) =>
      event is! KeyUpEvent &&
      event.logicalKey == key &&
      (!alt || state.isAltPressed);

  @override
  String debugDescribeKeys() => '${alt ? 'Alt + ' : ''}${key.keyLabel}';
}

/// A key the popup takes only while it is up.
///
/// Closed, upstream's trigger maps Home, End, PageUp, PageDown and Escape to
/// 'None' (`getDropdownActionFromKey`) and never calls preventDefault on them
/// (Chrome), so the page still gets them. Reporting disabled rather than doing
/// nothing is what lets them fall through here too: to WidgetsApp's page
/// scroll, or its Escape -> DismissIntent and a dialog's action for it.
class _WhileOpenAction<I extends Intent> extends CallbackAction<I> {
  _WhileOpenAction(this.state, {required super.onInvoke});

  final _FluentDropdownState<Object?> state;

  @override
  bool isEnabled(I intent) => state._open;
}
