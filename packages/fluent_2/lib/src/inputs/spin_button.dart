import 'package:fluent_2_core/fluent_2_core.dart';
// For clampDouble, which widgets.dart does not re-export.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import '../internal/text_context_menu.dart';
import 'input.dart';
import 'spin_button_style.dart';

/// How a spin button is filled and outlined. Figma's `Style` axis.
enum FluentSpinButtonAppearance {
  /// Neutral fill, a border on all four sides and a darker bottom rule. The
  /// default.
  outline,

  /// No fill and no box border — a single rule along the bottom edge.
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
  /// A distinct Figma variant, not a flavour of disabled: read-only keeps the
  /// value at full contrast (`neutralForeground1`) where disabled dims it.
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

  /// Whether the surface uses the disabled token ramp.
  ///
  /// Read-only and disabled share every surface token in Figma — the same
  /// absent fill and the same `neutralStrokeDisabled` border — and differ only
  /// in the colour of the text and in whether focus is possible.
  bool get inert => !enabled || readOnly;
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
/// Token sources are the Figma `Spin button` set (56 variants) and the
/// `.Spin button stepper` set (8), extracted into
/// `test/fixtures/spin_button.json` and `test/fixtures/spin_button_stepper.json`
/// and asserted variant-by-variant in the tests.
///
/// Three things here are worth reading before changing them.
///
/// **The bottom edge is two rules, not one.** Outline paints a full box border
/// in the `neutralStroke1` ramp *and* a 1px `neutralStrokeAccessible` rule over
/// its bottom edge; Underline paints only that rule; the two filled appearances
/// paint neither. Figma models this as a separate rectangle under the frame,
/// which is why `bottomRuleColor` is a property rather than a fourth border
/// side — Flutter refuses a rounded rectangle whose sides disagree.
///
/// **Read-only is not disabled.** Both drop the fill and take
/// `neutralStrokeDisabled`, and both use the *disabled* stepper, but read-only
/// keeps `neutralForeground1` on the value while disabled takes
/// `neutralForegroundDisabled`.
///
/// **The filled appearances carry a transparent border.** Figma paints no
/// stroke at all on `Filled darker` / `Filled lighter` at rest, hover and
/// pressed. `useSpinButtonStyles.styles.ts` declares
/// `colorTransparentStroke` / `colorTransparentStrokeInteractive` there, and
/// React wins on this one point: the two are pixel-identical in a normal theme,
/// but Fluent's transparent tokens turn opaque in high contrast, where that
/// border is the only thing outlining a filled input. This is the same call
/// `FluentSwitch` makes about its checked track.
FluentSpinButtonStyle resolveFluentSpinButtonStyle(
  FluentSpinButtonState state,
  FluentThemeData theme,
) {
  final c = theme.colors;
  final underline = state.appearance == FluentSpinButtonAppearance.underline;
  // The invalid treatment is gated on focus because upstream gates it:
  // `useSpinButtonStyles.styles.ts` writes `colorPaletteRedBorder2` under
  // `':not(:focus-within),:hover:not(:focus-within)'`, so a focused invalid
  // spin button falls back to the ordinary ramp and the brand rule marks it
  // instead. Figma cannot contradict this — Error and Selected are two values
  // of one `State` axis there, so the file has no Error-while-focused variant.
  final invalid = state.invalid && !state.focused;

  // Surface. Figma binds one Rest token per appearance and never ramps it —
  // hover and pressed carry the identical fill on all 56 variants.
  final background = state.inert
      ? FluentStateColor.tokens(rest: c.transparentBackground)
      : switch (state.appearance) {
          FluentSpinButtonAppearance.outline ||
          FluentSpinButtonAppearance.filledLighter => FluentStateColor.tokens(
            rest: c.neutralBackground1,
          ),
          FluentSpinButtonAppearance.filledDarker => FluentStateColor.tokens(
            rest: c.neutralBackground3,
          ),
          // Figma paints no fill on an Underline input. React declares
          // `colorNeutralBackground1`; Figma wins, so the canvas shows through.
          FluentSpinButtonAppearance.underline => FluentStateColor.tokens(
            rest: c.transparentBackground,
          ),
        };

  final border = state.inert
      ? FluentStateColor.tokens(rest: c.neutralStrokeDisabled)
      : invalid
      ? FluentStateColor.tokens(rest: c.statusDangerBorder2)
      : switch (state.appearance) {
          FluentSpinButtonAppearance.outline => FluentStateColor.tokens(
            rest: c.neutralStroke1,
            hover: c.neutralStroke1Hover,
            pressed: c.neutralStroke1Pressed,
          ),
          // See the note above: transparent in light and dark, the highlight in
          // high contrast.
          FluentSpinButtonAppearance.filledDarker ||
          FluentSpinButtonAppearance.filledLighter ||
          FluentSpinButtonAppearance.underline => FluentStateColor.tokens(
            rest: c.transparentStrokeInteractive,
          ),
        };

  // Underline has no box border at all; every other appearance has a thin one.
  final borderWidth = underline ? FluentStroke.none : FluentStroke.thin;

  // The darker rule over the bottom edge. Null where the box border already is
  // the bottom edge, which is every inert or invalid Outline variant and every
  // filled variant in every state.
  final rule = switch ((underline, state.inert, invalid)) {
    (true, true, _) => FluentStateColor.tokens(rest: c.neutralStrokeDisabled),
    (true, false, true) => FluentStateColor.tokens(rest: c.statusDangerBorder2),
    (_, false, false)
        when state.appearance == FluentSpinButtonAppearance.outline ||
            underline =>
      FluentStateColor.tokens(
        rest: c.neutralStrokeAccessible,
        hover: c.neutralStrokeAccessibleHover,
        pressed: c.neutralStrokeAccessiblePressed,
      ),
    _ => null,
  };

  // Geometry, verbatim from the Figma frames. `padding` is the Contents inset
  // and is left-only: the stepper column sits flush against the right edge.
  final (
    height,
    textStyle,
    leftInset,
    contentInset,
    stepper,
    stepperInset,
  ) = switch (state.size) {
    FluentSpinButtonSize.medium => (
      32.0,
      theme.typography.body1,
      FluentSpacing.mNudge,
      const EdgeInsets.symmetric(
        horizontal: FluentSpacing.xxs,
        vertical: FluentSpacing.sNudge,
      ),
      const Size(24, 16),
      const EdgeInsets.fromLTRB(
        FluentSpacing.sNudge,
        FluentSpacing.xs,
        FluentSpacing.sNudge,
        0,
      ),
    ),
    FluentSpinButtonSize.small => (
      24.0,
      theme.typography.caption1,
      // Figma insets a small input by SNudge (6). React's
      // `spacingHorizontalS` is 8. Figma wins.
      FluentSpacing.sNudge,
      const EdgeInsets.symmetric(
        horizontal: FluentSpacing.xxs,
        vertical: FluentSpacing.xs,
      ),
      const Size(24, 12),
      const EdgeInsets.fromLTRB(
        FluentSpacing.sNudge,
        FluentSpacing.xxs,
        FluentSpacing.sNudge,
        0,
      ),
    ),
  };

  return FluentSpinButtonStyle(
    backgroundColor: background,
    borderColor: border,
    borderWidth: WidgetStatePropertyAll<double?>(borderWidth),
    // `Corner-radius/Input/Small` resolves to 4, which is FluentRadius.medium.
    // Underline squares its corners off entirely.
    borderRadius: WidgetStatePropertyAll<BorderRadius?>(
      underline ? BorderRadius.zero : FluentRadius.allMedium,
    ),
    bottomRuleColor: rule,
    bottomRuleWidth: const WidgetStatePropertyAll<double?>(FluentStroke.thin),
    // Figma binds `Neutral/Stroke/Accessible/Selected`; React writes
    // `colorCompoundBrandStroke`. Both resolve to the same value in all three
    // themes, and Figma's is the one the file states. The Pressed stop is
    // React's alone — `':focus-within:active::after'` moves the rule to
    // `colorCompoundBrandStrokePressed`, and Figma has no Selected+Pressed
    // variant to disagree with. `FluentInput` and `FluentTextarea` already
    // carry it.
    focusUnderlineColor: FluentStateColor.tokens(
      rest: c.neutralStrokeAccessibleSelected,
      pressed: c.compoundBrandStrokePressed,
    ),
    focusUnderlineWidth: const WidgetStatePropertyAll<double?>(
      FluentStroke.thick,
    ),
    // Figma only ever draws a placeholder, except in `Read only`, where the
    // text is a real value and binds `Neutral/Foreground/1/Rest`. That variant
    // is what pins the value colour.
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
      // Figma binds `Neutral/Foreground/3/Hover` on Pressed too. Core defines
      // `neutralForeground3Pressed` *as* the hover value, so naming the
      // pressed token keeps React's spelling without changing a pixel.
      pressed: c.neutralForeground3Pressed,
      disabled: c.neutralForegroundDisabled,
    ),
    // `.Spin button stepper` has its own two-value Style axis, and the Spin
    // button set pins `Darker` on exactly the Filled darker variants and
    // `Default` on the other three. React reaches for
    // `colorSubtleBackgroundHover` here, which is the same value as
    // `neutralBackground1Hover`; Figma names the neutral one.
    stepperBackgroundColor:
        state.appearance == FluentSpinButtonAppearance.filledDarker
        ? FluentStateColor.tokens(
            rest: c.transparentBackground,
            hover: c.neutralBackground3Hover,
            pressed: c.neutralBackground3Pressed,
            disabled: c.transparentBackground,
          )
        : FluentStateColor.tokens(
            rest: c.transparentBackground,
            hover: c.neutralBackground1Hover,
            pressed: c.neutralBackground1Pressed,
            disabled: c.transparentBackground,
          ),
    textStyle: WidgetStatePropertyAll<TextStyle?>(textStyle),
    padding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsetsDirectional.only(start: leftInset),
    ),
    contentPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(contentInset),
    stepperSize: WidgetStatePropertyAll<Size?>(stepper),
    stepperPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(stepperInset),
    glyphSize: const WidgetStatePropertyAll<double?>(FluentSize.size120),
    minimumSize: WidgetStatePropertyAll<Size?>(Size(0, height)),
    mouseCursor: const WidgetStatePropertyAll<MouseCursor?>(
      SystemMouseCursors.text,
    ),
  );
}

/// Renders a spin button from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentSpinButtonBaseState] rather than [FluentSpinButtonState] on purpose:
/// it never reads appearance or size, so a consumer can supply their own style
/// and still use Fluent's layout, rules and stepper column.
///
/// [states] is the live interaction set of the *control* — hover, press and
/// disabled. Each stepper resolves its own set independently, which is what
/// makes a stepper hold at rest while the field around it is hovered.
///
/// The only thing that animates is the focus underline, which grows from the
/// centre — `useSpinButtonStyles.styles.ts` declares exactly one transition,
/// `transform` on the root `::after`. That bar is [FluentInputFocusUnderline],
/// whose [fluentInputFocusUnderlineEnter] and [fluentInputFocusUnderlineExit]
/// are bit-for-bit the pair this file used to keep privately: `durationNormal`
/// on `curveDecelerateMid` in, `durationUltraFast` on `curveAccelerateMid`
/// out. Reduced motion is handled inside that widget.
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

  Widget field = Padding(padding: contentPadding, child: state.field);
  if (textStyle != null || foreground != null) {
    field = DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      child: field,
    );
  }

  final content = Row(
    // Not `stretch`: the control is laid out under unbounded height (a Column,
    // a Center) as often as not, and stretch would demand a bounded one. The
    // padding table already makes the field box exactly as tall as the stepper
    // column — 6 + 20 + 6 and 4 + 16 + 4 — so centring lands on the same pixel.
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      Expanded(child: field),
      // The steppers duplicate the increment and decrement actions the control
      // already publishes on itself, so announcing them again would read the
      // field twice.
      ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FluentSpinButtonStepper(
              direction: FluentSpinButtonStepperDirection.increase,
              style: style,
              onPressed: state.onIncrease,
            ),
            FluentSpinButtonStepper(
              direction: FluentSpinButtonStepperDirection.decrease,
              style: style,
              onPressed: state.onDecrease,
            ),
          ],
        ),
      ),
    ],
  );

  // The two rules are overlays rather than a fourth border side: Flutter
  // refuses a rounded rectangle whose sides disagree in colour, and the bottom
  // edge of an Outline input is a different token from its other three. Figma
  // models them as separate rectangles anyway.
  //
  // Both carry the field's own bottom corners. The radius has to be painted on
  // a TALLER box and clipped back — Skia scales every corner by
  // `min(edge / sum-of-radii-on-that-edge)`, so a 4px corner on a 1px rule
  // ships as 0.5 and the ends read square against a rounded field.
  // FluentInputUnderline is that clip, and it is upstream's own trick:
  // `height: max(2px, borderRadiusMedium)` plus
  // `clipPath: inset(calc(100% - 2px) 0 0 0)` on the `::after`.
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
          child: Padding(padding: padding, child: content),
        ),
      ),
      if (ruleColor != null && ruleWidth > 0)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: ruleWidth,
          child: FluentInputUnderline(
            color: ruleColor,
            thickness: ruleWidth,
            borderRadius: ruleRadius,
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
            borderRadius: ruleRadius,
            thickness: focusWidth,
          ),
        ),
    ],
  );
}

/// Paints one stepper's chevron.
///
/// A painter rather than an icon widget because this package does not ship
/// Fluent's icon font. The proportions are read off the Figma vector:
/// `ChevronUp12`'s ink is **8 x 4.5** inside a 12 glyph box, so the chevron is
/// two thirds of the box wide and three eighths of it tall at every size.
class FluentSpinButtonChevronPainter extends CustomPainter {
  /// Creates a painter for one chevron.
  const FluentSpinButtonChevronPainter({
    required this.direction,
    required this.color,
    required this.glyphSize,
    this.strokeWidth = FluentStroke.width15,
  });

  /// Which way the chevron points.
  final FluentSpinButtonStepperDirection direction;

  /// Chevron tone. A `neutralForeground3` ramp stop, never derived from the
  /// surface behind it.
  final Color color;

  /// Edge length of the glyph box the ink is proportioned against.
  final double glyphSize;

  /// Thickness of the stroke. `FluentStroke.width15` reads as the same weight
  /// as the filled 12px glyph without needing its outline.
  final double strokeWidth;

  /// Ink width as a fraction of the glyph box: 8 of 12.
  static const double _inkWidth = 8 / 12;

  /// Ink height as a fraction of the glyph box: 4.5 of 12.
  static const double _inkHeight = 4.5 / 12;

  @override
  void paint(Canvas canvas, Size size) {
    // ponytail: the ink is centred in the box. Figma seats it 0.75 higher in a
    // 12 box; that is the icon's own optical nudge and is below the threshold
    // the fixture asserts.
    final width = glyphSize * _inkWidth;
    final height = glyphSize * _inkHeight;
    final left = (size.width - width) / 2;
    final top = (size.height - height) / 2;
    final radius = strokeWidth / 2;

    final up = direction == FluentSpinButtonStepperDirection.increase;
    final ends = up ? top + height - radius : top + radius;
    final apex = up ? top + radius : top + height - radius;

    canvas.drawPath(
      Path()
        ..moveTo(left + radius, ends)
        ..lineTo(left + width / 2, apex)
        ..lineTo(left + width - radius, ends),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(FluentSpinButtonChevronPainter oldDelegate) =>
      oldDelegate.direction != direction ||
      oldDelegate.color != color ||
      oldDelegate.glyphSize != glyphSize ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// One half of a spin button's stepper column.
///
/// Its own Figma component set (`.Spin button stepper`, 8 variants) and its own
/// interaction surface: hovering the increase half must not light the decrease
/// half, and neither may take focus — upstream gives both `tabIndex={-1}` and
/// keeps the whole control a single tab stop.
///
/// Public because [buildFluentSpinButton] places it, and a consumer
/// substituting their own build needs to be able to place it too.
class FluentSpinButtonStepper extends StatelessWidget {
  /// Creates one stepper half.
  const FluentSpinButtonStepper({
    super.key,
    required this.direction,
    required this.style,
    this.onPressed,
  });

  /// Which half this is.
  final FluentSpinButtonStepperDirection direction;

  /// The resolved spin button style. Only the `stepper*` and `glyphSize`
  /// properties are read.
  final FluentSpinButtonStyle style;

  /// Invoked on tap. Null makes the half inert, which is what a disabled *or*
  /// read-only spin button does — Figma pins the `State=Disabled` stepper on
  /// both.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const rest = <WidgetState>{};
    final box = style.stepperSize?.resolve(rest) ?? const Size(24, 16);
    final glyph = style.glyphSize?.resolve(rest) ?? FluentSize.size120;
    final inset = (style.stepperPadding?.resolve(rest) ?? EdgeInsets.zero)
        .resolve(Directionality.of(context));
    // The style states one inset, for the increase half. The decrease half is
    // its vertical mirror: the padding always sits on the edge facing away
    // from the middle of the column.
    final padding = direction == FluentSpinButtonStepperDirection.increase
        ? inset
        : EdgeInsets.fromLTRB(inset.left, inset.bottom, inset.right, inset.top);

    return ExcludeFocus(
      child: FluentInteractive(
        onPressed: onPressed,
        enabled: onPressed != null,
        builder: (context, states, _) {
          final foreground =
              style.stepperForegroundColor?.resolve(states) ??
              const Color(0x00000000);
          return SizedBox.fromSize(
            size: box,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: style.stepperBackgroundColor?.resolve(states),
              ),
              child: Padding(
                padding: padding,
                child: SizedBox.expand(
                  child: CustomPaint(
                    painter: FluentSpinButtonChevronPainter(
                      direction: direction,
                      color: foreground,
                      glyphSize: glyph,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
    if (!focused) _commit(_controller.text);
  }

  void _setState(WidgetState state, {required bool value}) {
    if (!_enabled && value) return;
    _states.update(state, value);
  }

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
    if (next != widget.value) widget.onChanged?.call(next);
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

  void _handleSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    final show = switch (cause) {
      SelectionChangedCause.longPress ||
      SelectionChangedCause.drag ||
      SelectionChangedCause.stylusHandwriting => true,
      SelectionChangedCause.tap => !selection.isCollapsed,
      _ => false,
    };
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

    final field = Stack(
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
    );

    final resolvedState = resolveFluentSpinButtonState(
      field: field,
      enabled: _enabled,
      readOnly: widget.readOnly,
      invalid: widget.invalid,
      focused: _focused,
      appearance: widget.appearance,
      size: widget.size,
      onIncrease: _editable ? () => _step(const _StepIntent.by(1)) : null,
      onDecrease: _editable ? () => _step(const _StepIntent.by(-1)) : null,
    );

    // FluentInteractive is deliberately NOT used for the control itself: it
    // owns a FocusNode, and a text input's focus node has to belong to the
    // EditableText. Hover and press are therefore tracked here, on the same
    // WidgetState set every other component reports, and `focused` is carried
    // on the resolved state instead — Fluent's focus underline is a
    // `:focus-within` rule, so it must light for pointer focus too.
    final control = MouseRegion(
      cursor: _enabled
          ? resolved.mouseCursor?.resolve(states) ?? SystemMouseCursors.text
          : SystemMouseCursors.basic,
      onEnter: (_) => _setState(WidgetState.hovered, value: true),
      onExit: (_) => _setState(WidgetState.hovered, value: false),
      child: Listener(
        onPointerDown: (_) => _setState(WidgetState.pressed, value: true),
        onPointerUp: (_) => _setState(WidgetState.pressed, value: false),
        onPointerCancel: (_) => _setState(WidgetState.pressed, value: false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // A tap anywhere on the chrome puts the caret in the field, the way
          // clicking a browser input's padding does.
          onTap: _enabled ? _focusNode.requestFocus : null,
          child: buildFluentSpinButton(resolvedState, resolved, states),
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
