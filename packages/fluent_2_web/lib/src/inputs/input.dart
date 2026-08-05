import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';
import '../internal/interaction.dart';
import '../internal/text_context_menu.dart';
import 'input_style.dart';

/// How an input is filled and outlined. Figma's `Style` axis.
enum FluentInputAppearance {
  /// Neutral fill, a border on all four sides, and an accessible-contrast rule
  /// along the bottom edge. The default.
  outline,

  /// No fill and no box border — only the bottom rule.
  underline,

  /// `neutralBackground3` fill with an invisible border.
  filledDarker,

  /// `neutralBackground1` fill with an invisible border.
  filledLighter,
}

/// Input height and type ramp. Figma's `Size` axis.
enum FluentInputSize {
  /// 24 high, `caption1`.
  small,

  /// 32 high, `body1`. The default.
  medium,

  /// 40 high, `body2`.
  large,
}

/// The focus bar growing in, verified against `useInputStyles.styles.ts`.
///
/// Upstream's `:focus-within::after` sets `transform: scaleX(1)`,
/// `transitionProperty: transform` and `transitionDuration: durationNormal`.
///
/// **Upstream defect, ported as intent.** The same block writes
/// `transitionDelay: tokens.curveDecelerateMid` — a *curve* assigned to
/// `transition-delay`, which is not a valid delay, so every browser drops the
/// declaration and runs the transition on the default `ease` with no delay.
/// The obvious intent is `transitionTimingFunction`, so the curve is used as
/// the easing here rather than reproducing a typo.
const FluentMotionSpec fluentInputFocusUnderlineEnter = FluentMotionSpec(
  duration: FluentDuration.normal,
  curve: FluentCurve.decelerateMid,
);

/// The focus bar shrinking out.
///
/// Upstream's base `::after` rule: `transform: scaleX(0)` at
/// `durationUltraFast`, four times quicker than the entrance. Same
/// `transitionDelay` defect as [fluentInputFocusUnderlineEnter]; the curve is
/// read as the intended easing.
const FluentMotionSpec fluentInputFocusUnderlineExit = FluentMotionSpec(
  duration: FluentDuration.ultraFast,
  curve: FluentCurve.accelerateMid,
);

/// Everything needed to render an input, independent of appearance and size.
///
/// The Dart counterpart of upstream's `InputState` minus its two design axes.
/// [buildFluentInput] takes this rather than [FluentInputState], which is what
/// makes "Fluent's state, my own styling, Fluent's rendering" a supported path
/// rather than a fork.
@immutable
class FluentInputBaseState {
  /// Creates a base state.
  const FluentInputBaseState({
    required this.enabled,
    required this.readOnly,
    required this.error,
    required this.focused,
    required this.controller,
    required this.focusNode,
    required this.editableTextKey,
    this.placeholder,
    this.contentBefore,
    this.contentAfter,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  /// Whether the field accepts input at all.
  final bool enabled;

  /// Whether the value can be selected and copied but not edited.
  ///
  /// A separate axis from [enabled]: a read-only field still takes focus.
  final bool readOnly;

  /// Whether the field is showing a validation error. Figma's `State=Error`,
  /// upstream's `aria-invalid="true"`.
  final bool error;

  /// Whether the field currently holds focus.
  ///
  /// **Not** `WidgetState.focused`, which in this package means
  /// *keyboard-visible* focus. A text field's brand underline has to appear
  /// when focus arrives by click as well, so real focus is an axis on the state
  /// rather than an interaction state — the same call
  /// `FluentTag` makes about `selected`.
  final bool focused;

  /// The value being edited.
  final TextEditingController controller;

  /// The node this field's focus is tracked on.
  final FocusNode focusNode;

  /// Identifies the [EditableText] for the selection gesture machinery.
  final GlobalKey<EditableTextState> editableTextKey;

  /// Shown while the value is empty.
  final Widget? placeholder;

  /// Slot before the field in reading order — an icon, a prefix, a button.
  final Widget? contentBefore;

  /// Slot after the field in reading order.
  final Widget? contentAfter;

  /// Whether characters are replaced by the obscuring character.
  final bool obscureText;

  /// Maximum rendered lines, or null to grow without bound.
  final int? maxLines;

  /// Minimum rendered lines.
  final int? minLines;

  /// Which soft keyboard to request.
  final TextInputType? keyboardType;

  /// The soft keyboard's action key.
  final TextInputAction? textInputAction;

  /// Invoked on every edit.
  final ValueChanged<String>? onChanged;

  /// Invoked when the action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Whether the placeholder should be painted, as of this instant.
  ///
  /// A snapshot, not a subscription: [buildFluentInput] watches [controller]
  /// instead, because the widgets that own their own controller do not rebuild
  /// on every keystroke.
  bool get placeholderVisible => placeholder != null && controller.text.isEmpty;
}

/// An input's fully resolved state, including the design axes.
@immutable
class FluentInputState extends FluentInputBaseState {
  /// Creates a resolved state.
  const FluentInputState({
    required super.enabled,
    required super.readOnly,
    required super.error,
    required super.focused,
    required super.controller,
    required super.focusNode,
    required super.editableTextKey,
    required this.appearance,
    required this.size,
    super.placeholder,
    super.contentBefore,
    super.contentAfter,
    super.obscureText,
    super.maxLines,
    super.minLines,
    super.keyboardType,
    super.textInputAction,
    super.onChanged,
    super.onSubmitted,
    super.autofocus,
  });

  /// Fill and outline treatment.
  final FluentInputAppearance appearance;

  /// Height and type ramp.
  final FluentInputSize size;
}

/// Builds the state an input will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentInputState resolveFluentInputState({
  required TextEditingController controller,
  required FocusNode focusNode,
  required GlobalKey<EditableTextState> editableTextKey,
  bool enabled = true,
  bool readOnly = false,
  bool error = false,
  bool focused = false,
  FluentInputAppearance appearance = FluentInputAppearance.outline,
  FluentInputSize size = FluentInputSize.medium,
  Widget? placeholder,
  Widget? contentBefore,
  Widget? contentAfter,
  bool obscureText = false,
  int? maxLines = 1,
  int? minLines,
  TextInputType? keyboardType,
  TextInputAction? textInputAction,
  ValueChanged<String>? onChanged,
  ValueChanged<String>? onSubmitted,
  bool autofocus = false,
}) => FluentInputState(
  enabled: enabled,
  readOnly: readOnly,
  error: error,
  focused: focused,
  controller: controller,
  focusNode: focusNode,
  editableTextKey: editableTextKey,
  appearance: appearance,
  size: size,
  placeholder: placeholder,
  contentBefore: contentBefore,
  contentAfter: contentAfter,
  obscureText: obscureText,
  maxLines: maxLines,
  minLines: minLines,
  keyboardType: keyboardType,
  textInputAction: textInputAction,
  onChanged: onChanged,
  onSubmitted: onSubmitted,
  autofocus: autofocus,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the Figma `Input` component set (`9115:8452`, 84 variants
/// over Style × Size × State), extracted into `test/fixtures/input.json` and
/// asserted variant-by-variant in the tests.
///
/// Three things about this table are worth knowing before "fixing" it:
///
/// * **Disabled and Read only are one ramp.** Figma paints both with
///   `Neutral/Background/Transparent/Rest` and `Neutral/Stroke/Disabled/Rest`
///   on all four appearances; only the text colour differs, because a read-only
///   field shows a *value* (`Neutral/Foreground/1/Rest`) where every other
///   state shows the *placeholder* (`Neutral/Foreground/4/Rest`). Upstream has
///   no read-only styling at all — `readOnly` is a bare attribute there — so
///   this whole column is Figma's.
/// * **Focus does not change the outline border.** All 12 `Style=Outline,
///   State=Focus` variants keep `Neutral/Stroke/1/Rest`, where React's
///   `outlineInteractive` moves `:focus-within` to `Stroke1Pressed`. Figma
///   wins; the brand bar is what marks focus.
/// * **The bottom rule is a separate node, not `border-bottom`.** Figma draws
///   `Thin underline` / `Thick underline` rectangles over the box's bottom
///   edge, which is also the only way Flutter can paint a rounded box whose
///   bottom side differs in colour. [FluentInputStyle.bottomBorderColor] is
///   that rectangle.
FluentInputStyle resolveFluentInputStyle(
  FluentInputState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final disabled = !state.enabled;
  // Figma's Disabled and Read only columns are byte-identical apart from the
  // text colour, so the surface and border tables branch on this pair together.
  final inert = disabled || state.readOnly;
  final filled =
      state.appearance == FluentInputAppearance.filledDarker ||
      state.appearance == FluentInputAppearance.filledLighter;
  final underline = state.appearance == FluentInputAppearance.underline;

  final background = switch (state.appearance) {
    _ when inert => c.transparentBackground,
    FluentInputAppearance.underline => c.transparentBackground,
    FluentInputAppearance.filledDarker => c.neutralBackground3,
    FluentInputAppearance.outline ||
    FluentInputAppearance.filledLighter => c.neutralBackground1,
  };

  // The box outline. Underline has none at all — its only rule is the bottom
  // one below, which is why `borderWidth` goes to zero rather than the colour
  // going transparent: a zero-width border cannot reappear in high contrast.
  //
  // The error branch is gated on focus because upstream gates it:
  // `useInputStyles.styles.ts` writes the danger colour under
  // `':not(:focus-within),:hover:not(:focus-within)'`, so a focused invalid
  // field falls back to the ordinary ramp and the brand bar is what marks it.
  // Figma cannot contradict this — Error and Focus are two values of one
  // `State` axis there, so the file has no Error-while-focused variant.
  final WidgetStateProperty<Color>? border;
  if (underline) {
    border = null;
  } else if (inert) {
    border = FluentStateColor.tokens(rest: c.neutralStrokeDisabled);
  } else if (state.error && !state.focused) {
    border = FluentStateColor.tokens(rest: c.statusDangerBorder2);
  } else if (filled) {
    // Upstream's `filledInteractive` moves both `:hover` and `:focus-within`
    // (and therefore `:active`) to the Interactive token. Figma agrees on
    // Filled lighter and contradicts itself on Filled darker, where Hover and
    // Pressed keep the plain `Neutral/Stroke/Transparent/Rest` while Focus
    // takes the Interactive one. React's rule is the consistent reading.
    border = FluentStateColor.tokens(
      rest: state.focused
          ? c.transparentStrokeInteractive
          : c.transparentStroke,
      hover: c.transparentStrokeInteractive,
      pressed: c.transparentStrokeInteractive,
    );
  } else {
    border = FluentStateColor.tokens(
      rest: c.neutralStroke1,
      hover: c.neutralStroke1Hover,
      pressed: c.neutralStroke1Pressed,
    );
  }

  // The bottom rule. Filled appearances draw none; on Outline it sits over the
  // box border, on Underline it *is* the border.
  final WidgetStateProperty<Color>? bottomBorder;
  if (filled) {
    bottomBorder = null;
  } else if (inert) {
    bottomBorder = FluentStateColor.tokens(rest: c.neutralStrokeDisabled);
  } else if (state.error && !state.focused) {
    bottomBorder = FluentStateColor.tokens(rest: c.statusDangerBorder2);
  } else {
    bottomBorder = FluentStateColor.tokens(
      rest: c.neutralStrokeAccessible,
      hover: c.neutralStrokeAccessibleHover,
      pressed: c.neutralStrokeAccessiblePressed,
    );
  }

  final (height, textStyle, inset, iconSize, gap) = switch (state.size) {
    FluentInputSize.small => (
      24.0,
      theme.typography.caption1,
      FluentSpacing.sNudge,
      FluentSize.size160,
      FluentSpacing.xxs,
    ),
    FluentInputSize.medium => (
      32.0,
      theme.typography.body1,
      FluentSpacing.mNudge,
      FluentSize.size200,
      FluentSpacing.xxs,
    ),
    FluentInputSize.large => (
      40.0,
      theme.typography.body2,
      FluentSpacing.m,
      FluentSize.size240,
      FluentSpacing.sNudge,
    ),
  };

  return FluentInputStyle(
    backgroundColor: WidgetStatePropertyAll<Color?>(background),
    borderColor: border,
    borderWidth: WidgetStatePropertyAll<double?>(
      underline ? FluentStroke.none : FluentStroke.thin,
    ),
    // Every one of the 84 variants binds `Corner-radius/Input/{Small,Medium}`,
    // both of which resolve to 4, Underline included — React zeroes the radius
    // there instead. Nothing but the rule's own ends is observable either way.
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    bottomBorderColor: bottomBorder,
    bottomBorderWidth: WidgetStateProperty.resolveWith<double?>(
      (states) => bottomBorder == null
          ? FluentStroke.none
          // Figma swaps `Thin underline` for `Thick underline` on Pressed, in
          // `Neutral/Stroke/Accessible/Pressed`. React keeps 1px and only
          // recolours. Figma wins; the rule is an overlay, so 2px costs no
          // layout.
          : states.contains(WidgetState.pressed)
          ? FluentStroke.thick
          : FluentStroke.thin,
    ),
    // Upstream's disabled rule is `::after { content: unset }` — a disabled
    // field has no focus bar at all. Read only keeps one: it still takes focus.
    focusUnderlineColor: disabled
        ? null
        : FluentStateColor.tokens(
            rest: c.compoundBrandStroke,
            pressed: c.compoundBrandStrokePressed,
          ),
    foregroundColor: FluentStateColor.tokens(
      rest: disabled ? c.neutralForegroundDisabled : c.neutralForeground1,
    ),
    placeholderColor: FluentStateColor.tokens(
      rest: disabled ? c.neutralForegroundDisabled : c.neutralForeground4,
    ),
    contentColor: FluentStateColor.tokens(
      rest: disabled ? c.neutralForegroundDisabled : c.neutralForeground3,
    ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(horizontal: inset),
    ),
    // Figma binds `Spacing/Horizontal/XXS` on the `.Text` layer at every size,
    // so the total inset is 8 / 12 / 14. React's `horizontalPadding.input.large`
    // is `SNudge`, which would make Large 18; Figma wins.
    contentPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(horizontal: FluentSpacing.xxs),
    ),
    gap: WidgetStatePropertyAll<double?>(gap),
    iconSize: WidgetStatePropertyAll<double?>(iconSize),
    minimumSize: WidgetStatePropertyAll<Size?>(Size(0, height)),
    cursorColor: FluentStateColor.tokens(
      rest: disabled ? c.neutralForegroundDisabled : c.neutralForeground1,
    ),
    // The one value Fluent does not specify: neither the Figma file nor
    // `useInputStyles.styles.ts` names a selection colour, so the browser's own
    // highlight is what upstream ships. `brandBackground2` is the palette's
    // subtle brand wash and is the closest real token; override it through
    // `style` if a host app has its own.
    selectionColor: FluentStateColor.tokens(rest: c.brandBackground2),
    mouseCursor: WidgetStatePropertyAll<MouseCursor?>(
      disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.text,
    ),
  );
}

/// Renders an input from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentInputBaseState] rather than [FluentInputState] on purpose: it never
/// reads appearance or size, so a consumer can supply their own style and still
/// use Fluent's layout, bottom rule and focus animation.
///
/// The result is *chrome plus an [EditableText]* — it carries no gesture
/// recognisers, so a caller placing it by hand must wrap it in a
/// [TextSelectionGestureDetectorBuilder] the way [FluentInput] does, or taps
/// will not move the caret.
///
/// [states] is the live interaction set: hovered, pressed and disabled.
Widget buildFluentInput(
  FluentInputBaseState state,
  FluentInputStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? FluentRadius.allMedium;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final background = style.backgroundColor?.resolve(states);
  final bottomColor = style.bottomBorderColor?.resolve(states);
  final bottomWidth =
      style.bottomBorderWidth?.resolve(states) ?? FluentStroke.none;
  final focusColor = style.focusUnderlineColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final placeholderColor = style.placeholderColor?.resolve(states);
  final contentColor = style.contentColor?.resolve(states);
  final textStyle = style.textStyle?.resolve(states) ?? const TextStyle();
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final contentPadding =
      style.contentPadding?.resolve(states) ?? EdgeInsets.zero;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.xxs;
  final iconSize = style.iconSize?.resolve(states) ?? FluentSize.size200;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;
  final cursorColor = style.cursorColor?.resolve(states);
  final selectionColor = style.selectionColor?.resolve(states);

  final valueStyle = textStyle.copyWith(color: foreground);

  Widget field = EditableText(
    key: state.editableTextKey,
    controller: state.controller,
    focusNode: state.focusNode,
    autofocus: state.autofocus,
    readOnly: state.readOnly || !state.enabled,
    obscureText: state.obscureText,
    style: valueStyle,
    // Fluent has no caret token, so the caret takes the text colour — which is
    // exactly what a browser does with no `caret-color` declared, and what
    // upstream therefore ships.
    cursorColor: cursorColor ?? foreground ?? const Color(0xFF000000),
    // iOS floating-cursor ghost. Deliberately the placeholder tone rather than
    // a computed grey.
    backgroundCursorColor: placeholderColor ?? const Color(0x00000000),
    selectionColor: selectionColor,
    selectionControls: fluentTextSelectionControls,
    contextMenuBuilder: fluentTextContextMenuBuilder,
    enableInteractiveSelection: state.enabled,
    maxLines: state.maxLines,
    minLines: state.minLines,
    keyboardType: state.keyboardType,
    textInputAction: state.textInputAction,
    onChanged: state.onChanged,
    onSubmitted: state.onSubmitted,
    // The gesture detector built by `FluentInput` owns pointer handling.
    rendererIgnoresPointer: true,
    showCursor: state.enabled && !state.readOnly,
  );

  if (state.placeholder != null) {
    field = Stack(
      children: <Widget>[
        field,
        Positioned.fill(
          child: IgnorePointer(
            // Subscribed to the controller rather than read once at build time.
            // Visibility is a function of live text, and only `FluentInput`
            // rebuilds on every keystroke — `FluentDatePicker` and
            // `FluentTimePicker` own their controller and do not, so a
            // build-time read left the placeholder painted over typed text.
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: state.controller,
              builder: (context, value, child) =>
                  value.text.isEmpty ? child! : const SizedBox.shrink(),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: DefaultTextStyle(
                  style: textStyle.copyWith(color: placeholderColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: state.placeholder!,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget? slot(Widget? child) => child == null
      ? null
      : IconTheme.merge(
          data: IconThemeData(color: contentColor, size: iconSize),
          child: DefaultTextStyle.merge(
            style: textStyle.copyWith(color: contentColor),
            child: child,
          ),
        );

  final row = Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    spacing: gap,
    children: <Widget>[
      ?slot(state.contentBefore),
      Expanded(
        child: Padding(padding: contentPadding, child: field),
      ),
      ?slot(state.contentAfter),
    ],
  );

  // The bottom rule and the focus bar are drawn as overlays rather than as a
  // one-sided border: Flutter refuses to paint a rounded rectangle whose sides
  // disagree in colour ("A borderRadius can only be given on borders with
  // uniform colors"), and Figma models them as separate rectangles anyway.
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
            color: background,
            borderRadius: radius,
            border: borderWidth > 0 && borderColor != null
                ? Border.all(color: borderColor, width: borderWidth)
                : null,
          ),
          child: Padding(padding: padding, child: row),
        ),
      ),
      if (bottomColor != null && bottomWidth > 0)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: bottomWidth,
          // The radius has to be painted on a TALLER box and clipped back.
          // Setting it on a 1px-high DecoratedBox looks right and does nothing:
          // Skia scales every corner by `min(edge / sum-of-radii-on-that-edge)`,
          // so a 4px corner on a 1px rule ships as 0.5 and the ends read square
          // against a rounded field. FluentInputUnderline is that clip.
          child: FluentInputUnderline(
            color: bottomColor,
            thickness: bottomWidth,
            borderRadius: ruleRadius,
          ),
        ),
      if (focusColor != null)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: FluentStroke.thick,
          child: FluentInputFocusUnderline(
            focused: state.focused,
            color: focusColor,
            borderRadius: ruleRadius,
          ),
        ),
    ],
  );
}

/// The brand bar that grows across the bottom of a focused input.
///
/// Upstream animates it as `transform: scaleX(0 → 1)` on the root's `::after`
/// pseudo-element, with a **different duration and curve per direction**, which
/// is why this is a raw [AnimationController] rather than a
/// [FluentAnimatedStyle]: that widget carries one [FluentMotionSpec], and this
/// needs two — [fluentInputFocusUnderlineEnter] and
/// [fluentInputFocusUnderlineExit].
///
/// Reduced motion collapses both to [Duration.zero], matching upstream's own
/// `prefers-reduced-motion` clamp to `0.01ms`.
class FluentInputFocusUnderline extends StatefulWidget {
  /// Creates a focus bar.
  const FluentInputFocusUnderline({
    super.key,
    required this.focused,
    required this.color,
    this.borderRadius = BorderRadius.zero,
    this.thickness = FluentStroke.thick,
  });

  /// Whether the field holds focus. The bar is fully grown while true.
  final bool focused;

  /// The bar's colour — `compoundBrandStroke`, or its Pressed sibling.
  final Color color;

  /// The bar's own corner radius: the container's two bottom corners.
  final BorderRadius borderRadius;

  /// The bar's own height. The painted rect is grown to at least the corner
  /// radius and clipped back to this, which is the only way a radius larger
  /// than the bar survives.
  final double thickness;

  @override
  State<FluentInputFocusUnderline> createState() =>
      _FluentInputFocusUnderlineState();
}

class _FluentInputFocusUnderlineState extends State<FluentInputFocusUnderline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: fluentInputFocusUnderlineEnter.duration,
    reverseDuration: fluentInputFocusUnderlineExit.duration,
    value: widget.focused ? 1 : 0,
  );
  late final CurvedAnimation _scale = CurvedAnimation(
    parent: _controller,
    curve: fluentInputFocusUnderlineEnter.curve,
    reverseCurve: fluentInputFocusUnderlineExit.curve,
  );
  bool _reducedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _applyReducedMotion();
  }

  @override
  void didUpdateWidget(FluentInputFocusUnderline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focused == oldWidget.focused) return;
    if (widget.focused) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _applyReducedMotion();
  }

  void _applyReducedMotion() {
    if (!_reducedMotion) return;
    _controller
      ..duration = Duration.zero
      ..reverseDuration = Duration.zero;
    // Setting `value` stops the ticker as well as jumping, so nothing is left
    // scheduled when reduced motion is switched on mid-flight.
    if (_controller.isAnimating) _controller.value = widget.focused ? 1 : 0;
  }

  @override
  void dispose() {
    _scale.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _scale,
    // CSS `scaleX` has its origin at 50%, so the bar grows out from the middle
    // in both directions rather than sweeping in from one edge.
    builder: (context, child) =>
        Transform.scale(scaleX: _scale.value, child: child),
    child: FluentInputUnderline(
      color: widget.color,
      thickness: widget.thickness,
      borderRadius: widget.borderRadius,
    ),
  );
}

/// A rule pinned to a field's bottom edge that keeps the field's corner radius.
///
/// Both rules on an input are this: the 1px resting one in
/// `neutralStrokeAccessible`, and the 2px focus accent that
/// [FluentInputFocusUnderline] animates. Neither can simply draw a rounded box,
/// because a corner radius larger than the rule is thick cannot survive on its
/// own — Skia scales every radius by `min(edge / sum-of-radii-on-that-edge)`,
/// so a 4px corner on a 2px bar ships as 2, half of that is lost to the bar's
/// own height, and the ends read square against a rounded field.
///
/// React hits the identical CSS clamp and answers it the same way
/// (`useDropdownStyles.styles.ts:45`): draw the pseudo-element at
/// `max(strokeWidthThick, borderRadiusMedium)` tall, put the radii on its
/// bottom corners, then trim it back with
/// `clipPath: inset(calc(100% - 2px) 0 0 0)`. The source comment there says
/// why outright — *"Use the whole border-radius as the height ... Otherwise the
/// radius would be automatically reduced to fit available space."*
///
/// The parent keeps the layout slot at [thickness]; only the painted rect grows.
class FluentInputUnderline extends StatelessWidget {
  /// Creates a rule [thickness] tall that paints on [borderRadius].
  const FluentInputUnderline({
    super.key,
    required this.color,
    required this.thickness,
    this.borderRadius = BorderRadius.zero,
  });

  /// The rule's colour.
  final Color color;

  /// The rule's height in layout. The painted rect may be taller.
  final double thickness;

  /// The field's bottom corners, which the rule's ends follow.
  final BorderRadius borderRadius;

  /// How tall the rule is painted before the clip trims it back.
  double get _paintedHeight => math.max(thickness, _maxRadius(borderRadius));

  @override
  Widget build(BuildContext context) => ClipRect(
    child: OverflowBox(
      alignment: Alignment.bottomCenter,
      // Both bounds, not just the maximum: a childless [DecoratedBox] is a
      // [RenderProxyBox], which sizes to `constraints.smallest`, so a loose
      // maximum alone would leave it at the incoming thickness.
      minHeight: _paintedHeight,
      maxHeight: _paintedHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, borderRadius: borderRadius),
      ),
    ),
  );
}

/// The largest corner radius on [radius], which is how tall the bar has to be
/// painted for that corner to survive Skia's scaling.
double _maxRadius(BorderRadius radius) => math.max(
  math.max(radius.bottomLeft.y, radius.bottomRight.y),
  math.max(radius.topLeft.y, radius.topRight.y),
);

/// Fluent's text selection handles.
///
/// Neither the Figma file nor `react-input` draws a selection handle — the web
/// uses the browser's own, and there is no Fluent asset to transcribe. This
/// draws the plainest thing that reads correctly: a filled
/// `compoundBrandStroke` disc hanging below the selection edge, anchored so it
/// points at the character boundary.
///
/// ponytail: a plain disc, not Material's teardrop. Give it a directional point
/// if a design ever specifies one.
class FluentTextSelectionControls extends TextSelectionControls {
  /// Creates a handle painter. Prefer [fluentTextSelectionControls].
  FluentTextSelectionControls();

  /// Handle diameter.
  static const double handleSize = 16;

  @override
  Size getHandleSize(double textLineHeight) =>
      const Size(handleSize, handleSize);

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) =>
      switch (type) {
        // The left handle hangs off the left of its anchor and the right handle
        // off the right, so neither covers the character it marks.
        TextSelectionHandleType.left => const Offset(handleSize, 0),
        TextSelectionHandleType.right => Offset.zero,
        TextSelectionHandleType.collapsed => const Offset(handleSize / 2, 0),
      };

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    final color = FluentTheme.of(context).colors.compoundBrandStroke;
    return GestureDetector(
      onTapDown: (_) => onTap?.call(),
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: handleSize,
        height: handleSize,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }

  @Deprecated(
    'Use `contextMenuBuilder` instead. '
    'This feature was deprecated after v3.3.0-0.5.pre.',
  )
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) =>
      // Fluent's context menu is a Menu surface, not a text-selection toolbar,
      // and the framework routes that through `EditableText.contextMenuBuilder`
      // now. Nothing to build here.
      const SizedBox.shrink();
}

/// The shared [FluentTextSelectionControls], mirroring Material's
/// `materialTextSelectionControls`.
///
/// One instance rather than a fresh object per build: [EditableText] compares
/// `selectionControls` by identity when deciding whether to rebuild its
/// selection overlay.
final FluentTextSelectionControls fluentTextSelectionControls =
    FluentTextSelectionControls();

/// Overrides the input style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentInputTheme extends InheritedTheme {
  /// Applies [style] to every `FluentInput` in [child].
  const FluentInputTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the appearance and size defaults.
  final FluentInputStyle style;

  /// The nearest input style, or null.
  static FluentInputStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentInputTheme>()?.style;

  @override
  bool updateShouldNotify(FluentInputTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentInputTheme(style: style, child: child);
}

/// A Fluent 2 single-line text field.
///
/// ```dart
/// FluentInput(
///   controller: controller,
///   placeholder: const Text('Search'),
///   contentBefore: const Icon(FluentIcons.search_20_regular),
///   onSubmitted: search,
/// )
/// ```
///
/// Built directly on [EditableText] — `package:flutter/material.dart` is not a
/// dependency of this package, so `TextField` does not exist here. Caret
/// placement, drag selection, double-tap word selection and long-press come
/// from [TextSelectionGestureDetectorBuilder], the widgets-layer machinery
/// `TextField` itself uses; the handles come from
/// [FluentTextSelectionControls].
///
/// Pass `enabled: false` to disable it — disabled is a real state here, not a
/// visual treatment: the field stops reporting hover and press, refuses edits,
/// swaps to the disabled token ramp wholesale, and loses its focus bar
/// entirely, matching upstream's `::after { content: unset }`.
///
/// **There is no focus ring.** Upstream writes
/// `:focus-within { outline: 2px solid transparent }` — deliberately
/// suppressing the shared ring — and Figma's twelve `State=Focus` variants draw
/// only the brand bar. The growing underline *is* the focus indicator.
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentInputTheme] restyles a subtree; and for anything further,
/// [resolveFluentInputState], [resolveFluentInputStyle] and [buildFluentInput]
/// are public so any one of them can be replaced without forking this widget.
class FluentInput extends StatefulWidget {
  /// Creates a text field.
  const FluentInput({
    super.key,
    this.controller,
    this.focusNode,
    this.appearance = FluentInputAppearance.outline,
    this.size = FluentInputSize.medium,
    this.placeholder,
    this.contentBefore,
    this.contentAfter,
    this.enabled = true,
    this.readOnly = false,
    this.error = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.style,
    this.semanticLabel,
  });

  /// The value being edited. One is created internally when omitted.
  final TextEditingController? controller;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Fill and outline treatment.
  final FluentInputAppearance appearance;

  /// Height and type ramp.
  final FluentInputSize size;

  /// Shown while the value is empty.
  final Widget? placeholder;

  /// Slot before the field in reading order — an icon, a prefix, a button.
  final Widget? contentBefore;

  /// Slot after the field in reading order.
  final Widget? contentAfter;

  /// Whether the field accepts input. False is a real disabled state.
  final bool enabled;

  /// Whether the value can be selected and copied but not edited.
  final bool readOnly;

  /// Whether to paint the validation-error treatment.
  final bool error;

  /// Whether characters are replaced by the obscuring character.
  final bool obscureText;

  /// Maximum rendered lines, or null to grow without bound.
  final int? maxLines;

  /// Minimum rendered lines.
  final int? minLines;

  /// Which soft keyboard to request.
  final TextInputType? keyboardType;

  /// The soft keyboard's action key.
  final TextInputAction? textInputAction;

  /// Invoked on every edit.
  final ValueChanged<String>? onChanged;

  /// Invoked when the action key is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentInputStyle? style;

  /// Announced by assistive technology. Use it when no visible label names the
  /// field — a placeholder is not a label.
  final String? semanticLabel;

  @override
  State<FluentInput> createState() => _FluentInputState();
}

class _FluentInputState extends State<FluentInput>
    implements TextSelectionGestureDetectorBuilderDelegate {
  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => widget.enabled;

  late final TextSelectionGestureDetectorBuilder _gestures =
      TextSelectionGestureDetectorBuilder(delegate: this);

  final WidgetStatesController _states = WidgetStatesController();

  TextEditingController? _internalController;
  FocusNode? _internalNode;

  TextEditingController get _controller =>
      widget.controller ?? (_internalController ??= TextEditingController());

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _states
      ..update(WidgetState.disabled, !widget.enabled)
      ..addListener(_rebuild);
    _focusNode.addListener(_rebuild);
    // The placeholder's visibility is a function of the value, so the field has
    // to rebuild on the first and last character typed.
    _controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(FluentInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalNode)?.removeListener(_rebuild);
      _focusNode.addListener(_rebuild);
    }
    if (widget.controller != oldWidget.controller) {
      (oldWidget.controller ?? _internalController)?.removeListener(_rebuild);
      _controller.addListener(_rebuild);
    }
    if (!widget.enabled) {
      // Clear the interaction states rather than leaving a stale hover behind
      // when a field is disabled mid-gesture.
      _states
        ..update(WidgetState.hovered, false)
        ..update(WidgetState.pressed, false);
    }
    _states.update(WidgetState.disabled, !widget.enabled);
  }

  @override
  void dispose() {
    _states
      ..removeListener(_rebuild)
      ..dispose();
    (widget.focusNode ?? _internalNode)?.removeListener(_rebuild);
    (widget.controller ?? _internalController)?.removeListener(_rebuild);
    _internalNode?.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _set(WidgetState state, {required bool value}) {
    if (!widget.enabled && value) return;
    _states.update(state, value);
  }

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentInputState(
      controller: _controller,
      focusNode: _focusNode,
      editableTextKey: editableTextKey,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      error: widget.error,
      focused: _focusNode.hasFocus,
      appearance: widget.appearance,
      size: widget.size,
      placeholder: widget.placeholder,
      contentBefore: widget.contentBefore,
      contentAfter: widget.contentAfter,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      autofocus: widget.autofocus,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentInputStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentInputTheme.maybeOf(context)).merge(widget.style);

    final states = <WidgetState>{..._states.value};

    // Not FluentInteractive, and that is deliberate. It owns a FocusNode
    // through FocusableActionDetector and binds ActivateIntent to a tap
    // callback — a text field needs its node to belong to the EditableText, and
    // needs Space and Enter to reach the input rather than "activate" the
    // control. Hover and press are wired the same way FluentInteractive wires
    // them, onto the same WidgetState vocabulary.
    Widget input = MouseRegion(
      cursor: resolved.mouseCursor?.resolve(states) ?? SystemMouseCursors.text,
      onEnter: (_) => _set(WidgetState.hovered, value: true),
      onExit: (_) => _set(WidgetState.hovered, value: false),
      child: Listener(
        onPointerDown: (_) => _set(WidgetState.pressed, value: true),
        onPointerUp: (_) => _set(WidgetState.pressed, value: false),
        onPointerCancel: (_) => _set(WidgetState.pressed, value: false),
        child: buildFluentInput(state, resolved, states),
      ),
    );

    if (widget.enabled) {
      input = _gestures.buildGestureDetector(
        behavior: HitTestBehavior.deferToChild,
        child: input,
      );
    }

    return Semantics(
      textField: true,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      label: widget.semanticLabel,
      child: input,
    );
  }
}
