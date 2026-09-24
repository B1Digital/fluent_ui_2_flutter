import 'dart:async';

import 'package:fluent_2_core/fluent_2_core.dart';
// For clampDouble, which widgets.dart does not re-export.
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart'
    show PointerDeviceKind, kSecondaryMouseButton;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import '../internal/text_context_menu.dart';
import '../internal/text_selection_dismiss.dart';
import 'input.dart';
import 'spin_button_style.dart';

/// How a spin button is filled and outlined. Figma's `Style` axis.
enum FluentSpinButtonAppearance {
  /// Neutral fill, a border on all four sides and a darker bottom side. The
  /// default.
  outline,

  /// Neutral fill like [outline], but a border on the bottom side only, with
  /// square ends.
  underline,

  /// `neutralBackground3` fill and no visible border.
  filledDarker,

  /// `neutralBackground1` fill and no visible border.
  filledLighter,
}

/// Control height and type ramp. Figma's `Size` axis.
enum FluentSpinButtonSize {
  /// 32 high, `body1` text, 16-tall steppers. The default.
  medium,

  /// 24 high, `caption1` text, 12-tall steppers.
  small,
}

/// Which way one stepper half moves the value.
enum FluentSpinButtonStepperDirection {
  /// The upper half. Adds one step.
  increase,

  /// The lower half. Subtracts one step.
  decrease,
}

/// Everything needed to render a spin button, independent of appearance and
/// size.
///
/// The Dart counterpart of upstream's `SpinButtonState` minus the design axes.
/// [buildFluentSpinButton] takes this rather than [FluentSpinButtonState],
/// which is what makes "Fluent's state, my own styling, Fluent's rendering" a
/// supported path rather than a fork.
///
/// [field] and the two stepper callbacks live here for the same reason
/// `FluentCheckboxBaseState.label` does: the build function has to place them,
/// and it must not need to know how they were produced.
@immutable
class FluentSpinButtonBaseState {
  /// Creates a base state.
  const FluentSpinButtonBaseState({
    required this.enabled,
    required this.readOnly,
    required this.invalid,
    required this.focused,
    required this.field,
    this.onIncrease,
    this.onDecrease,
  });

  /// Whether the control responds to input at all.
  final bool enabled;

  /// Whether the value can be read and focused but not changed.
  ///
  /// Not a flavour of disabled: upstream styles a read-only spin button
  /// exactly like rest, and only its steppers go inert.
  final bool readOnly;

  /// Whether the value fails validation. Figma's `State=Error`.
  final bool invalid;

  /// Whether the field currently holds focus.
  ///
  /// This is *focus-within*, not keyboard-visible focus: Fluent's focus
  /// underline is a `:focus-within` rule and appears whether focus arrived by
  /// click or by Tab. That is why it is carried here rather than read off
  /// `WidgetState.focused`, which in this package means keyboard-visible focus.
  final bool focused;

  /// The editable text, already wired to its controller and focus node.
  final Widget field;

  /// Adds one step. Null makes the increase half inert.
  final VoidCallback? onIncrease;

  /// Subtracts one step. Null makes the decrease half inert.
  final VoidCallback? onDecrease;
}

/// A spin button's fully resolved state, including the design axes.
///
/// The counterpart of upstream's `SpinButtonState`: base state plus exactly
/// `appearance` and `size`.
@immutable
class FluentSpinButtonState extends FluentSpinButtonBaseState {
  /// Creates a resolved state.
  const FluentSpinButtonState({
    required super.enabled,
    required super.readOnly,
    required super.invalid,
    required super.focused,
    required super.field,
    required this.appearance,
    required this.size,
    super.onIncrease,
    super.onDecrease,
  });

  /// Fill and outline treatment.
  final FluentSpinButtonAppearance appearance;

  /// Height and type ramp.
  final FluentSpinButtonSize size;
}

/// Builds the state a spin button will be styled and rendered from.
///
/// The first of the three-function recomposition contract.
FluentSpinButtonState resolveFluentSpinButtonState({
  required Widget field,
  bool enabled = true,
  bool readOnly = false,
  bool invalid = false,
  bool focused = false,
  FluentSpinButtonAppearance appearance = FluentSpinButtonAppearance.outline,
  FluentSpinButtonSize size = FluentSpinButtonSize.medium,
  VoidCallback? onIncrease,
  VoidCallback? onDecrease,
}) => FluentSpinButtonState(
  enabled: enabled,
  readOnly: readOnly,
  invalid: invalid,
  focused: focused,
  field: field,
  appearance: appearance,
  size: size,
  onIncrease: onIncrease,
  onDecrease: onDecrease,
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// The oracle is upstream as it renders — `useSpinButtonStyles.styles.ts`
/// measured in Chrome on the live storybook — not the Figma `Spin button` set.
/// Where the two disagree, upstream wins:
///
/// * **Read only has no styling.** Upstream has no read-only rule: the surface
///   keeps its fill and every interactive border rule, and only the steppers
///   change, because it renders both `disabled`. Only
///   [FluentSpinButtonBaseState.enabled] changes the ramp.
/// * **Focus moves the outline border.** `outlineInteractive` writes
///   `:active,:focus-within` as one rule, which Griffel sorts after `:hover`,
///   so a focused field shows `Stroke1Pressed` / `StrokeAccessiblePressed`
///   whether or not it is hovered — as `FluentInput` does.
/// * **The border is one CSS border**, on `::before`, whose bottom side takes
///   [FluentSpinButtonStyle.bottomRuleColor]. [FluentInputBorderPainter] joins
///   the two colours on the corner diagonal, as the browser does.
/// * **Underline keeps the root's fill and radius.** Only `::before` and the
///   focus bar are squared off.
/// * **Invalid is `colorPaletteRedBorder2`**, not the status danger token.
/// * **The filled appearances carry a transparent border**:
///   `colorTransparentStroke` at rest, `colorTransparentStrokeInteractive` on
///   hover and focus. Invisible in light and dark; in high contrast the tokens
///   turn opaque and it is the only thing outlining a filled field.
FluentSpinButtonStyle resolveFluentSpinButtonStyle(
  FluentSpinButtonState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final disabled = !state.enabled;
  final focused = state.focused;
  final underline = state.appearance == FluentSpinButtonAppearance.underline;
  final filled =
      state.appearance == FluentSpinButtonAppearance.filledDarker ||
      state.appearance == FluentSpinButtonAppearance.filledLighter;
  // The invalid treatment is gated on focus because upstream gates it:
  // `useSpinButtonStyles.styles.ts` writes `colorPaletteRedBorder2` under
  // `':not(:focus-within),:hover:not(:focus-within)'`, so a focused invalid
  // spin button falls back to the ordinary ramp and the brand bar marks it
  // instead.
  final invalid = state.invalid && !focused;
  // `colorPaletteRedBorder2`. The palette layer knows nothing of high contrast,
  // where the status token is the system text colour instead.
  final danger = c is FluentHighContrastColors
      ? c.statusDangerBorder2
      : c.palette.stroke2Rest(FluentPaletteFamily.red)!;

  // The root's `colorNeutralBackground1`, which underline keeps. Hover and
  // press never move it.
  final background = switch (state.appearance) {
    _ when disabled => c.transparentBackground,
    FluentSpinButtonAppearance.filledDarker => c.neutralBackground3,
    FluentSpinButtonAppearance.outline ||
    FluentSpinButtonAppearance.underline ||
    FluentSpinButtonAppearance.filledLighter => c.neutralBackground1,
  };

  // The top, left and right sides of `::before`. Underline has none: its
  // widths are `0 0 1px 0`.
  final WidgetStateProperty<Color>? border;
  if (underline) {
    border = null;
  } else if (disabled) {
    border = FluentStateColor.tokens(rest: c.neutralStrokeDisabled);
  } else if (invalid) {
    border = FluentStateColor.tokens(rest: danger);
  } else if (filled) {
    // `filledInteractive` moves both `:hover` and `:focus-within` (and so
    // `:active`) to the Interactive token.
    border = FluentStateColor.tokens(
      rest: focused ? c.transparentStrokeInteractive : c.transparentStroke,
      hover: c.transparentStrokeInteractive,
      pressed: c.transparentStrokeInteractive,
    );
  } else {
    // Focus holds the Pressed stop through a hover: see the doc comment.
    border = FluentStateColor.tokens(
      rest: focused ? c.neutralStroke1Pressed : c.neutralStroke1,
      hover: focused ? c.neutralStroke1Pressed : c.neutralStroke1Hover,
      pressed: c.neutralStroke1Pressed,
    );
  }

  // The bottom side. Null on the filled appearances, whose transparent border
  // runs round all four sides; the accessible-contrast ramp on outline, and
  // the only side there is on underline.
  final WidgetStateProperty<Color>? rule;
  if (filled) {
    rule = null;
  } else if (disabled) {
    rule = FluentStateColor.tokens(rest: c.neutralStrokeDisabled);
  } else if (invalid) {
    rule = FluentStateColor.tokens(rest: danger);
  } else {
    rule = FluentStateColor.tokens(
      rest: focused
          ? c.neutralStrokeAccessiblePressed
          : c.neutralStrokeAccessible,
      hover: focused
          ? c.neutralStrokeAccessiblePressed
          : c.neutralStrokeAccessibleHover,
      pressed: c.neutralStrokeAccessiblePressed,
    );
  }

  // Geometry, as measured in Chrome. The root pads its start edge only — the
  // stepper column sits flush against the end — and the `<input>` has no
  // padding of its own, so the content padding only centres the line box.
  //
  // The stepper insets are upstream's own, "computed by hand" to seat a 16px
  // icon: 4 and 1 top and bottom, 5 each side on medium; 3 and 0, 4 start and
  // 6 end on small. Stated for the increase half; the decrease half mirrors
  // them top to bottom.
  final (
    height,
    textStyle,
    inset,
    lineInset,
    stepper,
    stepperInset,
  ) = switch (state.size) {
    FluentSpinButtonSize.medium => (
      32.0,
      theme.typography.body1,
      FluentSpacing.mNudge,
      FluentSpacing.sNudge,
      const Size(24, 16),
      const EdgeInsetsDirectional.fromSTEB(5, 4, 5, 1),
    ),
    FluentSpinButtonSize.small => (
      24.0,
      theme.typography.caption1,
      FluentSpacing.s,
      FluentSpacing.xs,
      const Size(24, 12),
      const EdgeInsetsDirectional.fromSTEB(4, 3, 6, 0),
    ),
  };

  return FluentSpinButtonStyle(
    backgroundColor: WidgetStatePropertyAll<Color?>(background),
    borderColor: border,
    borderWidth: WidgetStatePropertyAll<double?>(
      underline ? FluentStroke.none : FluentStroke.thin,
    ),
    // `borderRadiusMedium` on the root in every appearance, underline too.
    // `buildFluentSpinButton` squares off the border and the focus bar of an
    // appearance with no side border.
    borderRadius: const WidgetStatePropertyAll<BorderRadius?>(
      FluentRadius.allMedium,
    ),
    bottomRuleColor: rule,
    // 1px in every state: upstream recolours the bottom side, never thickens
    // it.
    bottomRuleWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    // `colorCompoundBrandStroke`, and `colorCompoundBrandStrokePressed` under
    // `':focus-within:active::after'`: a field pressed while it holds focus.
    focusUnderlineColor: FluentStateColor.tokens(
      rest: c.compoundBrandStroke,
      pressed: c.compoundBrandStrokePressed,
    ),
    focusUnderlineWidth: const WidgetStatePropertyAll<double?>(
      FluentStroke.thick,
    ),
    foregroundColor: FluentStateColor.tokens(
      rest: c.neutralForeground1,
      disabled: c.neutralForegroundDisabled,
    ),
    placeholderColor: FluentStateColor.tokens(
      rest: c.neutralForeground4,
      disabled: c.neutralForegroundDisabled,
    ),
    // CSS `caret-color` defaults to `currentColor` and Fluent never overrides
    // it, so the caret is the value colour rather than a brand accent.
    cursorColor: FluentStateColor.tokens(rest: c.neutralForeground1),
    // Fluent styles no `::selection`, leaving the browser's own highlight.
    // `brandBackground2` is the package's stand-in: a tint in light, a shade in
    // dark, legible under `neutralForeground1` in both.
    selectionColor: FluentStateColor.tokens(rest: c.brandBackground2),
    stepperForegroundColor: FluentStateColor.tokens(
      rest: c.neutralForeground3,
      hover: c.neutralForeground3Hover,
      pressed: c.neutralForeground3Pressed,
      disabled: c.neutralForegroundDisabled,
    ),
    // Per appearance, as upstream's button styles: the subtle ramp on outline
    // and underline, the ramp of the field's own fill on the filled two.
    // Subtle and `neutralBackground1` agree in light only.
    stepperBackgroundColor: switch (state.appearance) {
      FluentSpinButtonAppearance.outline ||
      FluentSpinButtonAppearance.underline => FluentStateColor.tokens(
        rest: c.transparentBackground,
        hover: c.subtleBackgroundHover,
        pressed: c.subtleBackgroundPressed,
        disabled: c.transparentBackground,
      ),
      FluentSpinButtonAppearance.filledLighter => FluentStateColor.tokens(
        rest: c.transparentBackground,
        hover: c.neutralBackground1Hover,
        pressed: c.neutralBackground1Pressed,
        disabled: c.transparentBackground,
      ),
      FluentSpinButtonAppearance.filledDarker => FluentStateColor.tokens(
        rest: c.transparentBackground,
        hover: c.neutralBackground3Hover,
        pressed: c.neutralBackground3Pressed,
        disabled: c.transparentBackground,
      ),
    },
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsetsDirectional.only(start: inset),
    ),
    contentPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.symmetric(vertical: lineInset),
    ),
    stepperSize: WidgetStatePropertyAll<Size?>(stepper),
    stepperPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(stepperInset),
    // `ChevronUp16Regular` / `ChevronDown16Regular`: a 16px svg that the 14px
    // wide content box shrinks to 14 square.
    glyphSize: const WidgetStatePropertyAll<double?>(FluentSize.size140),
    minimumSize: WidgetStatePropertyAll<Size?>(Size(0, height)),
    mouseCursor: WidgetStatePropertyAll<MouseCursor?>(
      disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.text,
    ),
  );
}

/// Renders a spin button from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentSpinButtonBaseState] rather than [FluentSpinButtonState] on purpose:
/// it never reads appearance or size, so a consumer can supply their own style
/// and still use Fluent's layout, border and stepper column.
///
/// [states] is the live interaction set of the *control* — hover, press and
/// disabled. Each stepper resolves its own set independently, which is what
/// makes a stepper hold at rest while the field around it is hovered.
///
/// Paint order is upstream's: the fill, the content (steppers included), the
/// border over both — upstream draws it on `::before` at `z-index: 10`, so a
/// hovered stepper never covers it — and the focus bar (`::after`, 20) on top.
/// That `::before` is an absolute overlay, so unlike `buildFluentInput` the
/// border does not inset the content.
///
/// The only thing that animates is the focus underline, which grows from the
/// centre — `useSpinButtonStyles.styles.ts` declares exactly one transition,
/// `transform` on the root `::after`. That bar is [FluentInputFocusUnderline],
/// whose [fluentInputFocusUnderlineEnter] and [fluentInputFocusUnderlineExit]
/// are `durationNormal` in and `durationUltraFast` out, both on CSS `ease` —
/// upstream's curve tokens sit in `transitionDelay`, which the browser drops,
/// and the port ports what renders. Reduced motion is handled inside that
/// widget.
Widget buildFluentSpinButton(
  FluentSpinButtonBaseState state,
  FluentSpinButtonStyle style,
  Set<WidgetState> states,
) {
  final radius = style.borderRadius?.resolve(states) ?? BorderRadius.zero;
  final borderWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final borderColor = style.borderColor?.resolve(states);
  final background = style.backgroundColor?.resolve(states);
  final ruleColor = style.bottomRuleColor?.resolve(states);
  final ruleWidth = style.bottomRuleWidth?.resolve(states) ?? FluentStroke.none;
  final focusColor = style.focusUnderlineColor?.resolve(states);
  final focusWidth =
      style.focusUnderlineWidth?.resolve(states) ?? FluentStroke.none;
  final foreground = style.foregroundColor?.resolve(states);
  final textStyle = style.textStyle?.resolve(states);
  final padding = style.padding?.resolve(states) ?? EdgeInsets.zero;
  final contentPadding =
      style.contentPadding?.resolve(states) ?? EdgeInsets.zero;
  final minimumSize = style.minimumSize?.resolve(states) ?? Size.zero;

  // The `<input>` spans the control's full height, and so does its cursor;
  // its text sits in the middle of it. `heightFactor` keeps it at its own
  // height when the parent's is loose, and centres it in a taller tight one.
  Widget field = MouseRegion(
    cursor: style.mouseCursor?.resolve(states) ?? MouseCursor.defer,
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      heightFactor: 1,
      child: Padding(padding: contentPadding, child: state.field),
    ),
  );
  if (textStyle != null || foreground != null) {
    field = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      child: field,
    );
  }

  // Upstream's grid: two `1fr` rows the `<input>` spans, a button at the
  // start of each. At the natural 32 / 24 the rows are the buttons, 16 / 12;
  // a taller box leaves each button atop its half, as Chrome does.
  Widget stepper(FluentSpinButtonStepperDirection direction) => Expanded(
    child: Align(
      alignment: Alignment.topCenter,
      child: FluentSpinButtonStepper(
        direction: direction,
        style: style,
        onPressed: direction == FluentSpinButtonStepperDirection.increase
            ? state.onIncrease
            : state.onDecrease,
      ),
    ),
  );

  // The grid's `auto` height is the taller of the field and the two stepper
  // rows. The stepper column's size is known from the style, so the field
  // sizes the box and the column is pinned over its end: no intrinsic pass,
  // which a caller's field (a LayoutBuilder, say) may be unable to answer.
  const rest = <WidgetState>{};
  final stepperBox = style.stepperSize?.resolve(rest) ?? const Size(24, 16);
  final content = ConstrainedBox(
    constraints: BoxConstraints(minHeight: stepperBox.height * 2),
    child: Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        Padding(
          // Upstream's grid `columnGap: spacingHorizontalXS`, at both sizes.
          padding: EdgeInsetsDirectional.only(
            end: stepperBox.width + FluentSpacing.xs,
          ),
          child: field,
        ),
        // The steppers duplicate the increment and decrement actions the
        // control already publishes on itself, so announcing them again would
        // read the field twice.
        PositionedDirectional(
          end: 0,
          top: 0,
          bottom: 0,
          width: stepperBox.width,
          child: ExcludeSemantics(
            child: Column(
              children: <Widget>[
                stepper(FluentSpinButtonStepperDirection.increase),
                stepper(FluentSpinButtonStepperDirection.decrease),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  // A null colour is no side at all, whatever the width says.
  final side = borderColor == null ? FluentStroke.none : borderWidth;
  // A border with no sides is drawn square: upstream's underline zeroes the
  // radius of `::before` ("corners look strange if rounded") and of the focus
  // bar, and keeps the root's for the fill. Underline is the only appearance
  // with no side border, so that is what tells it apart here.
  // ponytail: keyed on the side width, not a style property of its own; add
  // one if a caller ever needs a rounded bottom-only border.
  final edge = side > 0 ? radius : BorderRadius.zero;

  return Stack(
    // Passthrough, so a parent's tight height stretches the box itself, as a
    // CSS `height` would. A loose Stack laid the box out at its own 24 / 32 and
    // pinned the bar to the bottom of the taller Stack, below it.
    fit: StackFit.passthrough,
    children: <Widget>[
      ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minimumSize.height,
          minWidth: minimumSize.width,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: background, borderRadius: radius),
          child: CustomPaint(
            foregroundPainter: FluentInputBorderPainter(
              radius: edge,
              borderColor: borderColor,
              borderWidth: side,
              bottomBorderColor: ruleColor,
              bottomBorderWidth: ruleColor == null ? side : ruleWidth,
            ),
            child: Padding(padding: padding, child: content),
          ),
        ),
      ),
      if (focusColor != null && focusWidth > 0)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: focusWidth,
          child: FluentInputFocusUnderline(
            focused: state.focused,
            color: focusColor,
            borderRadius: BorderRadius.only(
              bottomLeft: edge.bottomLeft,
              bottomRight: edge.bottomRight,
            ),
            thickness: focusWidth,
          ),
        ),
    ],
  );
}

/// Paints one stepper's chevron: upstream's `ChevronUp16Regular` /
/// `ChevronDown16Regular`, from the svg's own path.
///
/// Not the icon font's glyph of the same name: a text rasterizer darkens small
/// glyphs, and on macOS it drew this one a third heavier than Chrome fills the
/// svg, and half a pixel higher. A path fills the way the browser does.
///
/// Public, with its fields, so tests can read the resolved tone directly.
class FluentSpinButtonChevronPainter extends CustomPainter {
  /// Creates a painter for one chevron.
  const FluentSpinButtonChevronPainter({
    required this.direction,
    required this.color,
  });

  /// Which way the chevron points.
  final FluentSpinButtonStepperDirection direction;

  /// Chevron tone. A `neutralForeground3` ramp stop, never derived from the
  /// surface behind it.
  final Color color;

  /// `ChevronUp16Regular`'s `d`, in its 16-unit viewBox:
  /// `M3.15 10.35c.2.2.5.2.7 0L8 6.21l4.15 4.14a.5.5 0 0 0 .7-.7l-4.5-4.5`
  /// `a.5.5 0 0 0-.7 0l-4.5 4.5a.5.5 0 0 0 0 .7Z`. The down chevron's is the
  /// same path mirrored about y = 8.
  static final Path _up = Path()
    ..moveTo(3.15, 10.35)
    ..relativeCubicTo(.2, .2, .5, .2, .7, 0)
    ..lineTo(8, 6.21)
    ..relativeLineTo(4.15, 4.14)
    ..relativeArcToPoint(const Offset(.7, -.7), radius: _arc, clockwise: false)
    ..relativeLineTo(-4.5, -4.5)
    ..relativeArcToPoint(const Offset(-.7, 0), radius: _arc, clockwise: false)
    ..relativeLineTo(-4.5, 4.5)
    ..relativeArcToPoint(const Offset(0, .7), radius: _arc, clockwise: false)
    ..close();

  static const Radius _arc = Radius.circular(.5);

  @override
  void paint(Canvas canvas, Size size) {
    // Scaled to fit and centred, which is what the svg's default
    // `preserveAspectRatio` does with a 16 viewBox.
    final scale = size.shortestSide / 16;
    final up = direction == FluentSpinButtonStepperDirection.increase;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(scale, up ? scale : -scale)
      ..translate(-8, -8)
      ..drawPath(_up, Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(FluentSpinButtonChevronPainter oldDelegate) =>
      oldDelegate.direction != direction || oldDelegate.color != color;
}

/// One half of a spin button's stepper column.
///
/// Its own interaction surface: hovering the increase half must not light the
/// decrease half, and neither may take focus — upstream gives both
/// `tabIndex={-1}` and keeps the whole control a single tab stop.
///
/// The chevron is [FluentSpinButtonChevronPainter] at
/// [FluentSpinButtonStyle.glyphSize], centred in the padded box and allowed to
/// overflow it top and bottom, as upstream's svg does. The fill takes the
/// field's outer corner — upstream rounds the increment's top-end and the
/// decrement's bottom-end corner in every appearance — so a hovered stepper
/// follows the curve under the border.
///
/// Public because [buildFluentSpinButton] places it, and a consumer
/// substituting their own build needs to be able to place it too.
class FluentSpinButtonStepper extends StatefulWidget {
  /// Creates one stepper half.
  const FluentSpinButtonStepper({
    super.key,
    required this.direction,
    required this.style,
    this.onPressed,
  });

  /// Which half this is.
  final FluentSpinButtonStepperDirection direction;

  /// The resolved spin button style. Only the `stepper*`, `glyphSize` and
  /// `borderRadius` properties are read.
  final FluentSpinButtonStyle style;

  /// Takes one step. A mouse or pen takes the first on the press and repeats
  /// while the button is held, as upstream's `useSpinButton` does; a finger
  /// takes one on release. Null makes the half inert, which is what a
  /// disabled, read-only or at-bound spin button does: upstream renders those
  /// buttons `disabled`.
  ///
  /// The repeat is upstream's: 300ms after the press, then after each delay
  /// lerped from 300 towards 80 by the time spun over 1000ms, floored at the
  /// 4ms Chrome clamps a deeply nested timeout to. It stops on release, when
  /// the pointer leaves this half, and when this callback turns null.
  final VoidCallback? onPressed;

  @override
  State<FluentSpinButtonStepper> createState() =>
      _FluentSpinButtonStepperState();
}

/// The last pointer down a stepper took, which stepper took it, and whether
/// that stepper was live when it did.
///
/// Flutter hands a pointer event to the deepest hit first, so a stepper sees a
/// press before the control around it does. [FluentSpinButton] reads this to
/// tell a press on a `disabled` stepper — which Chrome answers by leaving
/// nothing focused — from one on the field or the padding, and a right press
/// on a live stepper, which Chrome leaves off the root's `:active`, from one
/// on a stepper that was already `disabled`, which it does not.
///
/// ponytail: one library-wide slot, matched by identity against the very event
/// being dispatched, so a stale entry never matches a later press. Pass the
/// press down an InheritedWidget instead if a second reader ever needs it.
(PointerEvent, FluentSpinButtonStepperDirection, bool)? _stepperPress;

class _FluentSpinButtonStepperState extends State<FluentSpinButtonStepper> {
  // `useSpinButton.tsx`'s DEFAULT_SPIN_DELAY_MS, MIN_SPIN_DELAY_MS and
  // MAX_SPIN_TIME_MS. Its lerp is unclamped, so the delay shrinks by 22% a
  // step and never reaches zero.
  static const double _firstDelay = 300;
  static const double _minDelay = 80;
  static const double _maxTime = 1000;

  // Chrome clamps a timeout nested more than five deep to 4ms, and upstream's
  // delay only falls under that eighteen steps in. Measured, Chrome's tail runs
  // one step per 4-5ms.
  static const double _floor = 4;

  Timer? _repeat;
  double _time = 0;
  double _delay = _firstDelay;
  bool _hovered = false;
  bool _pressed = false;

  @override
  void didUpdateWidget(FluentSpinButtonStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Upstream's button turns `disabled` under a held pointer at the bound:
    // the spin ends, and a later release has nothing to clear.
    if (widget.onPressed == null) {
      _stop();
      _pressed = false;
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  /// Steps, then schedules the next step on upstream's clock.
  void _spin() {
    widget.onPressed?.call();
    final wait = _delay > _floor ? _delay : _floor;
    _repeat = Timer(Duration(microseconds: (wait * 1000).round()), () {
      _time += _delay;
      _delay = _firstDelay + (_minDelay - _firstDelay) * _time / _maxTime;
      _spin();
    });
  }

  void _stop() {
    _repeat?.cancel();
    _repeat = null;
    _time = 0;
    _delay = _firstDelay;
  }

  void _handleDown(PointerDownEvent event) {
    _stepperPress = (
      event.original ?? event,
      widget.direction,
      widget.onPressed != null,
    );
    if (widget.onPressed == null) return;
    // Chrome sets `:active` for the primary and middle buttons, not for a
    // right press, which still steps: upstream's `onMouseDown` never asks
    // which button went down.
    if (event.buttons != kSecondaryMouseButton) {
      setState(() => _pressed = true);
    }
    if (_held(event.kind)) {
      _stop();
      _spin();
    }
  }

  // Chrome sends a mouse's and a pen's compatibility mousedown on the press,
  // and a finger's only after touchend.
  static bool _held(PointerDeviceKind kind) => switch (kind) {
    PointerDeviceKind.mouse ||
    PointerDeviceKind.stylus ||
    PointerDeviceKind.invertedStylus => true,
    _ => false,
  };

  // Also reaches a stepper unmounted under a held pointer: Flutter delivers
  // the release along the path the press was hit-tested on.
  void _handleUp(PointerEvent _) {
    _stop();
    if (mounted && _pressed) setState(() => _pressed = false);
  }

  // A finger steps once, on release: there is no hold to repeat. Also the
  // semantics tap, which reports an unknown device.
  void _handleTapUp(TapUpDetails details) {
    if (!_held(details.kind)) widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final direction = widget.direction;
    const rest = <WidgetState>{};
    final up = direction == FluentSpinButtonStepperDirection.increase;
    final box = style.stepperSize?.resolve(rest) ?? const Size(24, 16);
    final glyph = style.glyphSize?.resolve(rest) ?? FluentSize.size140;
    final radius = style.borderRadius?.resolve(rest) ?? BorderRadius.zero;
    final inset = (style.stepperPadding?.resolve(rest) ?? EdgeInsets.zero)
        .resolve(Directionality.of(context));
    // The style states one inset, for the increase half. The decrease half is
    // its vertical mirror: the larger inset always sits on the edge facing
    // away from the middle of the column.
    final padding = up
        ? inset
        : EdgeInsets.fromLTRB(inset.left, inset.bottom, inset.right, inset.top);
    // Griffel flips upstream's `borderTopRightRadius` in RTL, as `End` does.
    final corner = up
        ? BorderRadiusDirectional.only(topEnd: radius.topRight)
        : BorderRadiusDirectional.only(bottomEnd: radius.bottomRight);
    // Chrome paints upstream's svg — 16 tall, centred in the padded box, the
    // glyph centred in it — from a whole-pixel top. That top is x.5 at both
    // sizes, so the chevron lands half a pixel below the box's centre.
    // ponytail: snapped against the stepper's own top, which assumes the
    // control sits on a whole pixel; Chrome snaps against the page.
    const svg = 16.0;
    final svgTop = padding.top + (box.height - padding.vertical - svg) / 2;
    final nudge = (svgTop + .5).floorToDouble() - svgTop;

    // Upstream's `disabled` button: no hover, no press, `cursor: not-allowed`.
    final enabled = widget.onPressed != null;
    final states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (enabled && _hovered) WidgetState.hovered,
      if (enabled && _pressed) WidgetState.pressed,
    };

    final face = SizedBox.fromSize(
      size: box,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.stepperBackgroundColor?.resolve(states),
          borderRadius: corner,
        ),
        child: Padding(
          padding: padding,
          // Centred at full size in a box shorter than it, 14 in 11 (medium)
          // or 9 (small), as upstream's flex-centred svg is.
          child: Transform.translate(
            offset: Offset(0, nudge),
            child: OverflowBox(
              maxWidth: glyph,
              maxHeight: glyph,
              child: CustomPaint(
                size: Size.square(glyph),
                painter: FluentSpinButtonChevronPainter(
                  direction: direction,
                  color:
                      style.stepperForegroundColor?.resolve(states) ??
                      const Color(0x00000000),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // No focus of its own: upstream's `tabIndex={-1}` buttons are no tab stop,
    // and the control focuses its field on the press instead.
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      // Upstream's `mouseleave` ends a spin; coming back does not restart it.
      onExit: (_) {
        _stop();
        setState(() => _hovered = false);
      },
      child: Listener(
        onPointerDown: _handleDown,
        onPointerUp: _handleUp,
        onPointerCancel: _handleUp,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Live or not, the stepper takes the tap, so the control's own
          // tap-to-focus never sees it.
          onTapUp: _handleTapUp,
          // An inert half must not announce a tap it will not act on.
          excludeFromSemantics: !enabled,
          child: face,
        ),
      ),
    );
  }
}

/// Overrides the spin button style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentSpinButtonTheme extends InheritedTheme {
  /// Applies [style] to every `FluentSpinButton` in [child].
  const FluentSpinButtonTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the appearance and size defaults.
  final FluentSpinButtonStyle style;

  /// The nearest spin button style, or null.
  static FluentSpinButtonStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentSpinButtonTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentSpinButtonTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentSpinButtonTheme(style: style, child: child);
}

/// Moves the value by one step, one page, or to an end of the range.
class _StepIntent extends Intent {
  const _StepIntent.by(this.sign) : page = false, toEnd = false;
  const _StepIntent.byPage(this.sign) : page = true, toEnd = false;
  const _StepIntent.toEnd(this.sign) : page = false, toEnd = true;

  /// Direction of travel: -1 or 1.
  final int sign;

  /// Whether to move by a page rather than a step.
  final bool page;

  /// Whether to jump to an end of the range.
  final bool toEnd;
}

/// Reverts the field to the committed value.
class _RevertIntent extends Intent {
  const _RevertIntent();
}

/// Commits whatever has been typed. Enter, which `useSpinButton` handles on
/// keydown rather than leaving to the platform's text-input action.
class _CommitIntent extends Intent {
  const _CommitIntent();
}

/// A Fluent 2 spin button: a numeric field with an up/down stepper column.
///
/// ```dart
/// FluentSpinButton(
///   value: quantity,
///   min: 0,
///   max: 99,
///   onChanged: (next) => setState(() => quantity = next),
/// )
/// ```
///
/// Controlled, like every other input here: it never owns the value. It reports
/// the value a step, a commit or a key landed on and rebuilds when the caller
/// passes it back. The text is committed on Enter and on losing focus; Escape
/// puts back whatever the last committed value was.
///
/// Keyboard, matching `useSpinButton.tsx`: Up and Down move by [step], PageUp
/// and PageDown by [pageStep], Home goes to [min] and End to [max] when those
/// are set. Those bindings sit above the framework's own text-editing
/// shortcuts, so Home and End move the value rather than the caret — which is
/// what a spin button does everywhere.
///
/// The steppers step on the press and, held, repeat on `useSpinButton`'s
/// clock. A stepper at its bound is upstream's `disabled` button: grey, inert,
/// and a press on it leaves nothing focused.
///
/// Pass `onChanged: null` to disable it, or `readOnly: true` to keep it
/// focusable but fixed. The two are different states, not two names for one:
/// a read-only spin button shows its value at full contrast and can still be
/// tabbed to and copied from.
///
/// **No Material.** This is [EditableText] wired directly to a
/// [TextEditingController] and a [FocusNode]. There is no `TextField` in this
/// package.
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentSpinButtonTheme] restyles a subtree; and for anything further,
/// [resolveFluentSpinButtonState], [resolveFluentSpinButtonStyle] and
/// [buildFluentSpinButton] are public so any one of them can be replaced
/// without forking this widget.
class FluentSpinButton extends StatefulWidget {
  /// Creates a spin button. Omit [onChanged] to disable it.
  const FluentSpinButton({
    super.key,
    required this.value,
    this.onChanged,
    this.min,
    this.max,
    this.step = 1,
    this.pageStep = 1,
    this.precision,
    this.displayValue,
    this.placeholder,
    this.appearance = FluentSpinButtonAppearance.outline,
    this.size = FluentSpinButtonSize.medium,
    this.readOnly = false,
    this.invalid = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.keyboardType = const TextInputType.numberWithOptions(
      signed: true,
      decimal: true,
    ),
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
  });

  /// The current value, or null for an empty field.
  final double? value;

  /// Called with the value a step or a commit landed on, already clamped and
  /// rounded. Null disables the control.
  final ValueChanged<double?>? onChanged;

  /// Lower bound, or null for unbounded. Home jumps here when it is set.
  final double? min;

  /// Upper bound, or null for unbounded. End jumps here when it is set.
  final double? max;

  /// Travel per Up or Down press. Also decides [precision] when that is null.
  final double step;

  /// Travel per PageUp or PageDown press.
  ///
  /// Upstream's `stepPage`, and upstream's default of `1` — the same as
  /// [step]'s — is kept rather than "improved" to a multiple of it.
  final double pageStep;

  /// Decimal places the value is rounded and rendered to.
  ///
  /// Defaults to the number of decimals in [step], which is what
  /// `calculatePrecision` does upstream.
  final int? precision;

  /// Text to show instead of the formatted [value].
  ///
  /// For a value that reads as something other than a bare number — "50%",
  /// "3 items". Announced as the semantic value, matching upstream's
  /// `aria-valuetext`.
  final String? displayValue;

  /// Text shown while the field is empty.
  final String? placeholder;

  /// Fill and outline treatment.
  final FluentSpinButtonAppearance appearance;

  /// Height and type ramp.
  final FluentSpinButtonSize size;

  /// Whether the value can be read and focused but not changed.
  final bool readOnly;

  /// Whether the value fails validation. Paints the danger border.
  final bool invalid;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentSpinButtonStyle? style;

  /// Focus node to use. One is created internally when omitted.
  final FocusNode? focusNode;

  /// Whether to take focus on mount.
  final bool autofocus;

  /// Announced by assistive technology alongside the value.
  final String? semanticLabel;

  /// Soft-keyboard type. Numeric with a sign and a decimal point by default.
  final TextInputType keyboardType;

  /// Soft-keyboard action key.
  final TextInputAction textInputAction;

  /// Called with the committed value when the action key is pressed.
  final ValueChanged<double?>? onSubmitted;

  @override
  State<FluentSpinButton> createState() => _FluentSpinButtonState();
}

class _FluentSpinButtonState extends State<FluentSpinButton>
    implements TextSelectionGestureDetectorBuilderDelegate {
  final GlobalKey<EditableTextState> _editableKey =
      GlobalKey<EditableTextState>();
  final WidgetStatesController _states = WidgetStatesController();
  late final TextSelectionGestureDetectorBuilder _gestures;
  late final TextEditingController _controller;
  late final _SpinButtonSelectionControls _selectionControls;

  FocusNode? _internalNode;
  bool _focused = false;
  bool _showHandles = false;

  /// The value last reported, until the caller rebuilds this widget. A held
  /// stepper ticks faster than frames, so the ticks between reaching a bound
  /// and the rebuild that disables it would otherwise report it again.
  double? _reported;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalNode ??= FocusNode());

  bool get _enabled => widget.onChanged != null;

  bool get _editable => _enabled && !widget.readOnly;

  @override
  GlobalKey<EditableTextState> get editableTextKey => _editableKey;

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => true;

  @override
  void initState() {
    super.initState();
    _gestures = TextSelectionGestureDetectorBuilder(delegate: this);
    _selectionControls = _SpinButtonSelectionControls();
    _controller = TextEditingController(text: _display)
      ..addListener(_onTextChanged);
    _states.update(WidgetState.disabled, !_enabled);
    _states.addListener(_onStatesChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(FluentSpinButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reported = null;
    if (oldWidget.focusNode != widget.focusNode) {
      // `?? _internalNode`: when the old widget had no node the listener is on
      // the internal one, and `oldWidget.focusNode?.` skips it entirely —
      // leaving a live listener behind and adding a second one the next time
      // the internal node comes back into use.
      (oldWidget.focusNode ?? _internalNode)?.removeListener(_onFocusChanged);
      if (widget.focusNode == null) _internalNode ??= FocusNode();
      _focusNode.addListener(_onFocusChanged);
      _focused = _focusNode.hasFocus;
    }
    if (!_enabled) {
      _states
        ..update(WidgetState.hovered, false)
        ..update(WidgetState.pressed, false);
    }
    _states.update(WidgetState.disabled, !_enabled);
    // Only re-seat the text when the *committed* value moved. Re-seating on
    // every rebuild would fight the caret while the user is typing.
    if (oldWidget.value != widget.value ||
        oldWidget.displayValue != widget.displayValue ||
        oldWidget.precision != widget.precision ||
        oldWidget.step != widget.step) {
      _syncText();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _internalNode?.dispose();
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    _states
      ..removeListener(_onStatesChanged)
      ..dispose();
    super.dispose();
  }

  void _onStatesChanged() => setState(() {});

  // The placeholder appears and disappears with the text, so the field has to
  // rebuild on every keystroke whether or not the value changed.
  void _onTextChanged() => setState(() {});

  void _onFocusChanged() {
    final focused = _focusNode.hasFocus;
    if (focused == _focused) return;
    setState(() => _focused = focused);
    // Losing focus commits, the way a browser's number input does.
    if (!focused) {
      _commit(_controller.text);
      // Ordered after the commit for readability rather than necessity: a
      // commit that rewrites the field lands an already-collapsed selection
      // (`_syncText`, `_report`), which the helper then no-ops on, and a commit
      // that changes nothing leaves the range for it to clear.
      collapseFluentSelectionOnBlur(_focusNode, _controller);
    }
  }

  void _setState(WidgetState state, {required bool value}) {
    // A release reaches a control unmounted under a held pointer, along the
    // path the press was hit-tested on.
    if (!mounted || (!_enabled && value)) return;
    _states.update(state, value);
  }

  /// Focuses the field the way its own tap does. A bare `requestFocus` is
  /// focus from outside, and on desktop and the web `EditableText` answers
  /// that by selecting the whole value — a browser selects nothing on a click.
  void _focusField() => _editableKey.currentState?.requestKeyboard();

  int get _precision => widget.precision ?? _decimalsOf(widget.step);

  static int _decimalsOf(double step) {
    if (step == step.roundToDouble()) return 0;
    final text = step.abs().toString();
    final dot = text.indexOf('.');
    return dot < 0 ? 0 : text.length - dot - 1;
  }

  String _format(double value) => value.toStringAsFixed(_precision);

  double _normalise(double raw) => clampDouble(
    double.parse(_format(raw)),
    widget.min ?? double.negativeInfinity,
    widget.max ?? double.infinity,
  );

  String get _display {
    final custom = widget.displayValue;
    if (custom != null) return custom;
    final value = widget.value;
    return value == null ? '' : _format(value);
  }

  void _syncText() {
    final text = _display;
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Reports [raw], clamped and rounded, and puts the same number in the field.
  void _report(double raw) {
    final next = _normalise(raw);
    final text = widget.displayValue ?? _format(next);
    if (_controller.text != text) {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    if (next == (_reported ?? widget.value)) return;
    _reported = next;
    widget.onChanged?.call(next);
  }

  /// Commits whatever is in the field. An empty field clears the value; text
  /// that is not a number is discarded and the committed value put back.
  void _commit(String text) {
    if (!_editable) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      if (widget.value != null) widget.onChanged?.call(null);
      _syncText();
      return;
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      _syncText();
      return;
    }
    _report(parsed);
  }

  /// The number a step starts from: whatever is legible in the field, falling
  /// back to the committed value and then to the bottom of the range.
  double get _base =>
      double.tryParse(_controller.text.trim()) ??
      widget.value ??
      widget.min ??
      0;

  void _step(_StepIntent intent) {
    if (!_editable) return;
    if (intent.toEnd) {
      final end = intent.sign > 0 ? widget.max : widget.min;
      // Home and End do nothing when that end of the range is unbounded, which
      // is what `useSpinButton` checks for before handling either key.
      if (end == null) return;
      _report(end);
      return;
    }
    _report(
      _base + intent.sign * (intent.page ? widget.pageStep : widget.step),
    );
  }

  /// Whether [sign]'s stepper is upstream's `disabled` button: on a disabled
  /// or read-only control, and at its bound. `getBound` reads the committed
  /// value, rounded — here the one just reported, until the caller passes it
  /// back — and asks for equality: a value past the bound leaves the stepper
  /// live, and its press clamps back onto it.
  bool _stepperInert(int sign) {
    if (!_editable) return true;
    final value = _reported ?? widget.value;
    final end = sign > 0 ? widget.max : widget.min;
    if (value == null || end == null) return false;
    return double.parse(_format(value)) == end;
  }

  /// One step from a stepper. Upstream's stepper is a focused `<button>`, so
  /// the step that reaches its bound disables it under the pointer, and Chrome
  /// takes focus from a disabled control: the bar retracts. The keyboard steps
  /// from the `<input>`, which keeps it.
  void _stepperStep(int sign) {
    _step(_StepIntent.by(sign));
    if (_stepperInert(sign)) _focusNode.unfocus();
  }

  // TextField's rule: the builder records whether the gesture that moved the
  // selection was a touch or a stylus, so a mouse drag and a right click never
  // show the touch handles, and a disabled field shows none at all.
  void _handleSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    final show =
        _enabled &&
        _gestures.shouldShowSelectionHandles &&
        cause != SelectionChangedCause.keyboard &&
        !(widget.readOnly && selection.isCollapsed) &&
        (cause == SelectionChangedCause.longPress ||
            cause == SelectionChangedCause.stylusHandwriting ||
            _controller.text.isNotEmpty);
    if (show != _showHandles) setState(() => _showHandles = show);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final states = <WidgetState>{..._states.value};
    // Disabled is a real state: the control refuses focus rather than merely
    // ignoring what is typed into it. Mutating the node here is what Material's
    // own TextField does, and it works for a caller-supplied node too.
    _focusNode.canRequestFocus = _enabled;

    final base = resolveFluentSpinButtonState(
      field: const SizedBox.shrink(),
      enabled: _enabled,
      readOnly: widget.readOnly,
      invalid: widget.invalid,
      focused: _focused,
      appearance: widget.appearance,
      size: widget.size,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentSpinButtonStyle(
      base,
      theme,
    ).merge(FluentSpinButtonTheme.maybeOf(context)).merge(widget.style);

    final textStyle = resolved.textStyle?.resolve(states) ?? const TextStyle();
    final foreground = resolved.foregroundColor?.resolve(states);
    final placeholderColor = resolved.placeholderColor?.resolve(states);
    final cursorColor =
        resolved.cursorColor?.resolve(states) ??
        theme.colors.neutralForeground1;

    final editable = EditableText(
      key: _editableKey,
      controller: _controller,
      focusNode: _focusNode,
      readOnly: !_editable,
      autofocus: widget.autofocus,
      style: textStyle.copyWith(color: foreground),
      cursorColor: cursorColor,
      // The browser's caret is 1px; `EditableText`'s default is 2.
      cursorWidth: FluentStroke.thin,
      // `buildFluentSpinButton` sets the cursor over the whole field column,
      // where upstream's `<input>` sits. The text box's own `text` would
      // otherwise win over a disabled field's `not-allowed`.
      mouseCursor: MouseCursor.defer,
      backgroundCursorColor: theme.colors.neutralForeground4,
      selectionColor: _focused
          ? resolved.selectionColor?.resolve(states)
          : null,
      selectionControls: _selectionControls,
      contextMenuBuilder: fluentTextContextMenuBuilder,
      showSelectionHandles: _showHandles,
      onSelectionChanged: _handleSelectionChanged,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onSubmitted: (text) {
        _commit(text);
        widget.onSubmitted?.call(widget.value);
      },
      maxLines: 1,
      // The gesture detector below owns the pointer; EditableText's own
      // RenderEditable must not also claim it.
      rendererIgnoresPointer: true,
      enableInteractiveSelection: true,
      cursorOpacityAnimates: false,
    );

    final field = Listener(
      // A read-only `<input>` focuses on mousedown too. The control's handler
      // below skips read-only, whose steppers must not take focus.
      onPointerDown: (event) {
        if (_enabled && event.kind == PointerDeviceKind.mouse) _focusField();
      },
      child: Stack(
        children: <Widget>[
          if (_controller.text.isEmpty && widget.placeholder != null)
            IgnorePointer(
              child: ExcludeSemantics(
                child: Text(
                  widget.placeholder!,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: textStyle.copyWith(color: placeholderColor),
                ),
              ),
            ),
          _gestures.buildGestureDetector(
            behavior: HitTestBehavior.translucent,
            child: editable,
          ),
        ],
      ),
    );

    final resolvedState = resolveFluentSpinButtonState(
      field: field,
      enabled: _enabled,
      readOnly: widget.readOnly,
      invalid: widget.invalid,
      focused: _focused,
      appearance: widget.appearance,
      size: widget.size,
      onIncrease: _stepperInert(1) ? null : () => _stepperStep(1),
      onDecrease: _stepperInert(-1) ? null : () => _stepperStep(-1),
    );

    // FluentInteractive is deliberately NOT used for the control itself: it
    // owns a FocusNode, and a text input's focus node has to belong to the
    // EditableText. Hover and press are therefore tracked here, on the same
    // WidgetState set every other component reports, and `focused` is carried
    // on the resolved state instead — Fluent's focus underline is a
    // `:focus-within` rule, so it must light for pointer focus too.
    final control = MouseRegion(
      // Upstream's root: the default arrow over its padding, `not-allowed`
      // everywhere once disabled. The field and the steppers set their own.
      cursor: _enabled ? MouseCursor.defer : SystemMouseCursors.forbidden,
      onEnter: (_) => _setState(WidgetState.hovered, value: true),
      onExit: (_) => _setState(WidgetState.hovered, value: false),
      child: Listener(
        onPointerDown: (event) {
          // The stepper under the press, if any, saw it first.
          final stored = _stepperPress;
          final press =
              stored != null && identical(stored.$1, event.original ?? event)
              ? stored
              : null;
          final sign = press == null
              ? 0
              : press.$2 == FluentSpinButtonStepperDirection.increase
              ? 1
              : -1;
          // `:active` holds on the root for a press anywhere inside it. Chrome
          // sets it for a right press on the `<input>`, the padding and a
          // stepper already `disabled`, but not for one on a live stepper
          // `<button>` — not even one the press steps onto its bound.
          _setState(
            WidgetState.pressed,
            value:
                event.buttons != kSecondaryMouseButton || !(press?.$3 ?? false),
          );
          // Mouse only: a finger landing here may be starting a scroll, and
          // must not raise the keyboard.
          if (event.kind != PointerDeviceKind.mouse) return;
          if (sign != 0 && _stepperInert(sign)) {
            // A `disabled` stepper — read only, or at its bound, including
            // the one this very press stepped onto it — cannot take focus, so
            // Chrome's mousedown on it leaves nothing focused.
            _focusNode.unfocus();
          } else if (_editable) {
            // A browser focuses on mousedown — the `<input>`, or a stepper's
            // `<button tabindex=-1>` — so the root is `:focus-within` and the
            // bar grows while a stepper is still held. Focus goes to the field
            // rather than the stepper, which keeps the arrow keys working.
            _focusField();
          }
        },
        onPointerUp: (_) => _setState(WidgetState.pressed, value: false),
        onPointerCancel: (_) => _setState(WidgetState.pressed, value: false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // A tap anywhere on the chrome puts the caret in the field, the way
          // clicking a browser input's padding does.
          onTap: _enabled ? _focusField : null,
          // The steppers and the faceplate are chrome, outside the region
          // `EditableText` installs for itself — so every chevron click read as
          // a tap outside the field and dropped focus on pointer down, which
          // now also collapses the selection. `buildFluentInput` carries the
          // same wrapper.
          child: TextFieldTapRegion(
            child: buildFluentSpinButton(resolvedState, resolved, states),
          ),
        ),
      ),
    );

    final semanticValue = widget.displayValue ?? _display;
    // The framework asserts that a node carrying an increase action states
    // either both a value and an increased value or neither, so an empty field
    // publishes neither. The steppers themselves stay live — this is only what
    // assistive technology is told.
    final steppable = _editable && semanticValue.isNotEmpty;

    return Semantics(
      enabled: _enabled,
      readOnly: widget.readOnly,
      label: widget.semanticLabel,
      value: semanticValue,
      increasedValue: steppable ? _stepPreview(1) : null,
      decreasedValue: steppable ? _stepPreview(-1) : null,
      onIncrease: steppable ? () => _step(const _StepIntent.by(1)) : null,
      onDecrease: steppable ? () => _step(const _StepIntent.by(-1)) : null,
      // Above the field, so these beat the framework's own text-editing
      // shortcuts: Home and End move the value, not the caret.
      child: Shortcuts(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.arrowUp): _StepIntent.by(1),
          SingleActivator(LogicalKeyboardKey.arrowDown): _StepIntent.by(-1),
          SingleActivator(LogicalKeyboardKey.pageUp): _StepIntent.byPage(1),
          SingleActivator(LogicalKeyboardKey.pageDown): _StepIntent.byPage(-1),
          SingleActivator(LogicalKeyboardKey.home): _StepIntent.toEnd(-1),
          SingleActivator(LogicalKeyboardKey.end): _StepIntent.toEnd(1),
          SingleActivator(LogicalKeyboardKey.escape): _RevertIntent(),
          SingleActivator(LogicalKeyboardKey.enter): _CommitIntent(),
          SingleActivator(LogicalKeyboardKey.numpadEnter): _CommitIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _StepIntent: CallbackAction<_StepIntent>(
              onInvoke: (intent) {
                _step(intent);
                return null;
              },
            ),
            _RevertIntent: CallbackAction<_RevertIntent>(
              onInvoke: (_) {
                _syncText();
                return null;
              },
            ),
            _CommitIntent: CallbackAction<_CommitIntent>(
              onInvoke: (_) {
                _commit(_controller.text);
                widget.onSubmitted?.call(widget.value);
                return null;
              },
            ),
          },
          child: control,
        ),
      ),
    );
  }

  /// What the value would read as after one step in [sign]'s direction.
  String _stepPreview(int sign) {
    final next = _normalise(_base + sign * widget.step);
    return widget.displayValue ?? _format(next);
  }
}

/// Selection handles for the spin button's field.
///
/// A minimal set: a round grabber per handle and no toolbar. Fluent has no
/// selection-handle spec of its own — the browser draws the platform's — and
/// the context menu is the platform's too, which is why `contextMenuBuilder` is
/// left unset rather than reimplemented here without Material.
///
/// ponytail: private on purpose. Hoist it to `lib/src/internal/` the moment a
/// second text-bearing component needs it.
class _SpinButtonSelectionControls extends TextSelectionControls {
  _SpinButtonSelectionControls();

  static const double _diameter = FluentSize.size120;

  @override
  Size getHandleSize(double textLineHeight) => const Size(_diameter, _diameter);

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) =>
      switch (type) {
        TextSelectionHandleType.left => const Offset(_diameter, 0),
        TextSelectionHandleType.right => Offset.zero,
        TextSelectionHandleType.collapsed => const Offset(_diameter / 2, 0),
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
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: SizedBox(
        width: _diameter,
        height: _diameter,
        child: CustomPaint(painter: _HandlePainter(color)),
      ),
    );
  }

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
  ) => const SizedBox.shrink();
}

class _HandlePainter extends CustomPainter {
  const _HandlePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawCircle(
    size.center(Offset.zero),
    size.shortestSide / 2,
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_HandlePainter oldDelegate) => oldDelegate.color != color;
}
