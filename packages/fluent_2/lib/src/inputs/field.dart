import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import 'field_style.dart';
import 'label.dart';

/// Label ramp and label-to-control gap. Figma's `Size` axis, and the only axis
/// the `Field` component set has.
enum FluentFieldSize {
  /// 12/16 label over a 2px gap.
  small,

  /// 14/20 label over a 2px gap. The default.
  medium,

  /// 16/22 **semibold** label over a 4px gap.
  large,
}

/// What the field is reporting about the value of the control it wraps.
///
/// **Upstream-only as an axis.** The Figma `Field` set has no validation
/// property: all three variants draw one error message, bound to
/// `Status/Danger/Foreground/1/Rest`. Every state's glyph and tint is
/// therefore upstream's, as `useField` and `useFieldStyles.styles.ts` render it
/// in Chrome.
enum FluentFieldValidationState {
  /// No condition is being reported. The validation message, if any, reads as
  /// a second hint. The default.
  none,

  /// The value is invalid. The only state Figma draws.
  error,

  /// The value is accepted but questionable.
  warning,

  /// The value has been confirmed good.
  success,
}

/// Everything needed to render a field, independent of size and validation
/// state.
///
/// The Dart counterpart of upstream's `FieldState` minus its design axes.
/// [buildFluentField] takes this rather than [FluentFieldState], which is what
/// makes "Fluent's state, my own styling, Fluent's rendering" a supported path
/// rather than a fork.
///
/// [label] is a **finished widget**, not a string: by the time
/// [resolveFluentFieldState] has run it is already a [FluentLabel] carrying the
/// size, weight, required-asterisk and disabled treatment the field's own size
/// implies. A consumer building this state by hand can put any widget there.
@immutable
class FluentFieldBaseState {
  /// Creates a base state.
  const FluentFieldBaseState({
    required this.enabled,
    this.label,
    this.hint,
    this.validationMessage,
    this.validationMessageIcon,
    this.child,
  });

  /// Whether the field renders in its enabled colours.
  ///
  /// A field is not interactive — the control inside it is — so this is the
  /// only interaction state it has, and it is a real one:
  /// [resolveFluentFieldStyle] selects `neutralForegroundDisabled` for it
  /// rather than fading the enabled colours.
  final bool enabled;

  /// The label above the control, if any.
  final Widget? label;

  /// The hint below the control, if any. Upstream's `hint` slot; Figma's
  /// `Helper text` row.
  final Widget? hint;

  /// The validation message below the control, if any.
  final Widget? validationMessage;

  /// The glyph beside [validationMessage], if any.
  ///
  /// Tinted and sized through [IconTheme], so any [Icon]-shaped widget picks
  /// the right values up automatically. [resolveFluentFieldState] fills it
  /// with upstream's default, a [FluentFieldValidationGlyph], for every state
  /// but `none`.
  final Widget? validationMessageIcon;

  /// The control being wrapped. Any widget: the field never inspects it.
  final Widget? child;
}

/// A field's fully resolved state, including the design axes.
///
/// The counterpart of upstream's `FieldState`: base state plus exactly `size`
/// and `validationState`.
@immutable
class FluentFieldState extends FluentFieldBaseState {
  /// Creates a resolved state.
  const FluentFieldState({
    required super.enabled,
    required this.size,
    required this.validationState,
    super.label,
    super.hint,
    super.validationMessage,
    super.validationMessageIcon,
    super.child,
  });

  /// Label ramp and label-to-control gap.
  final FluentFieldSize size;

  /// What the field is reporting.
  final FluentFieldValidationState validationState;
}

/// Builds the state a field will be styled and rendered from.
///
/// The first of the three-function recomposition contract, and the only place
/// the label is composed: `label` goes in as its own content and comes out
/// wrapped in a [FluentLabel] whose size and weight are read off [size].
///
/// It is also where the default validation glyph is chosen, as upstream's
/// `useField_unstable` does: `validationMessageIcon` overrides the
/// [FluentFieldValidationGlyph] `validationState` would otherwise draw, and
/// `showValidationMessageIcon: false` drops the glyph and its gutter — the
/// counterpart of passing `validationMessageIcon={null}` to the React slot.
///
/// The weight is not a free choice. Figma's `Size=Large` variant draws its
/// label 16/22 **semibold**, and upstream's `useLabelStyles` gives `large` the
/// same `typographyStyles.subtitle2`. `FluentLabel` reaches that ramp step
/// only as `large` + `semibold` — `large` + `regular` is `body2`, the 16/22
/// regular step Figma's Label set does not ship at all.
FluentFieldState resolveFluentFieldState({
  bool enabled = true,
  FluentFieldSize size = FluentFieldSize.medium,
  FluentFieldValidationState validationState = FluentFieldValidationState.none,
  bool required = false,
  Widget? label,
  Widget? hint,
  Widget? validationMessage,
  Widget? validationMessageIcon,
  bool showValidationMessageIcon = true,
  Widget? child,
}) {
  final (labelSize, labelWeight) = switch (size) {
    FluentFieldSize.small => (FluentLabelSize.small, FluentLabelWeight.regular),
    FluentFieldSize.medium => (
      FluentLabelSize.medium,
      FluentLabelWeight.regular,
    ),
    FluentFieldSize.large => (
      FluentLabelSize.large,
      FluentLabelWeight.semibold,
    ),
  };

  return FluentFieldState(
    enabled: enabled,
    size: size,
    validationState: validationState,
    label: label == null
        ? null
        : FluentLabel(
            size: labelSize,
            weight: labelWeight,
            required: required,
            disabled: !enabled,
            child: label,
          ),
    hint: hint,
    validationMessage: validationMessage,
    validationMessageIcon: !showValidationMessageIcon
        ? null
        : validationMessageIcon ??
              (validationState == FluentFieldValidationState.none
                  ? null
                  : FluentFieldValidationGlyph(state: validationState)),
    child: child,
  );
}

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes. Every value comes from a Fluent token; nothing
/// here computes a colour.
///
/// Token sources are the Figma `Field` component set, extracted into
/// `test/fixtures/field.json` and asserted variant-by-variant in the tests,
/// with colours measured off upstream as Chrome renders it. Two readings
/// deserve to be stated out loud, because both look like bugs:
///
/// * **Only `error` recolours the message text.** Upstream applies
///   `secondaryTextStyles.error` when `validationState === 'error'` and nothing
///   at all for `warning` and `success`, whose messages stay
///   `colorNeutralForeground3`. The *glyph* takes a tint in all three. That
///   asymmetry is reproduced verbatim below.
/// * **Palette, not status.** Upstream names `colorPaletteRedForeground1`,
///   `colorPaletteDarkOrangeForeground1` and `colorPaletteGreenForeground1`,
///   and Chrome paints them #bc2f32, #c43501 and #0e700e (web-light), #e37d80,
///   #e9835e and #54b054 (web-dark). Figma binds the error text to
///   `Status/Danger/Foreground/1/Rest` (#b10e1c) instead; the rendered upstream
///   wins. They are read off the palette layer, as Input reads its red border,
///   so a `FluentThemeOverride` of a status token does not reach them. High
///   contrast maps all three to the system text colour, which is what the
///   status tokens hold there.
FluentFieldStyle resolveFluentFieldStyle(
  FluentFieldState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  // Disabled is a separate ramp on every row rather than a treatment applied
  // over the enabled one. Neither Figma nor upstream states it — Figma's set
  // has no Disabled axis and React's Field has no `disabled` prop — so this is
  // the same call `FluentRadio` makes for its label: `neutralForegroundDisabled`
  // is what every other component in this port greys down to.
  final hint = FluentStateColor.tokens(
    rest: c.neutralForeground3,
    disabled: c.neutralForegroundDisabled,
  );

  // `colorPalette{Red,DarkOrange,Green}Foreground1`. The palette layer knows
  // nothing of high contrast, where the status token is the system text colour.
  Color foreground1(FluentPaletteFamily family, Color highContrast) =>
      c is FluentHighContrastColors
      ? highContrast
      : c.palette.foreground1Rest(family)!;

  final tint = switch (state.validationState) {
    FluentFieldValidationState.none => c.neutralForeground3,
    FluentFieldValidationState.error => foreground1(
      FluentPaletteFamily.red,
      c.statusDangerForeground1,
    ),
    FluentFieldValidationState.warning => foreground1(
      FluentPaletteFamily.darkOrange,
      c.statusWarningForeground1,
    ),
    FluentFieldValidationState.success => foreground1(
      FluentPaletteFamily.green,
      c.statusSuccessForeground1,
    ),
  };

  final message = FluentStateColor.tokens(
    rest: state.validationState == FluentFieldValidationState.error
        ? tint
        : c.neutralForeground3,
    disabled: c.neutralForegroundDisabled,
  );

  final icon = FluentStateColor.tokens(
    rest: tint,
    disabled: c.neutralForegroundDisabled,
  );

  // The gap under the label, verbatim from the `Label + Icon` frame's
  // paddingBottom. Small leaves it unbound at 2, medium binds
  // `Spacing/Horizontal/XXS` (an axis slip in the file — the value is 2 either
  // way) and large binds `Spacing/Vertical/XS`.
  final labelGap = switch (state.size) {
    FluentFieldSize.small || FluentFieldSize.medium => FluentSpacing.xxs,
    FluentFieldSize.large => FluentSpacing.xs,
  };

  return FluentFieldStyle(
    hintColor: hint,
    validationMessageColor: message,
    validationMessageIconColor: icon,
    // Figma draws the gap alone; upstream's `useFieldStyles.styles.ts` also
    // pads a vertical label XXS above and below (`1px` at large), so Chrome's
    // label box is 24 and the control starts 26 down (field--default). React
    // wins.
    labelPadding: WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      state.size == FluentFieldSize.large
          ? EdgeInsets.only(top: 1, bottom: 1 + labelGap)
          : EdgeInsets.only(
              top: FluentSpacing.xxs,
              bottom: FluentSpacing.xxs + labelGap,
            ),
    ),
    secondaryTextPadding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
      EdgeInsets.only(top: FluentSpacing.xxs),
    ),
    // Size-invariant: all three variants draw the hint and the validation
    // message at 12/16, which is `caption1`. The Size axis moves the label
    // ramp and the label gap, nothing else.
    secondaryTextStyle: WidgetStatePropertyAll<TextStyle?>(
      theme.typography.caption1,
    ),
    validationMessageIconPadding:
        const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
          EdgeInsets.only(top: FluentSpacing.xxs),
        ),
    validationMessageIconSize: const WidgetStatePropertyAll<double?>(
      FluentSize.size120,
    ),
    gap: const WidgetStatePropertyAll<double?>(FluentSpacing.xs),
  );
}

/// Renders a field from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentFieldBaseState] rather than [FluentFieldState] on purpose: it never
/// reads size or validation state, so a consumer can supply their own style and
/// still use Fluent's layout.
///
/// [states] is the interaction set — for a field, `{WidgetState.disabled}` or
/// nothing at all.
///
/// **Nothing animates, deliberately.** `useFieldStyles.styles.ts` contains no
/// `transition`, no `animation` and no `motionTokens` reference of any kind, so
/// a validation message appears, disappears and recolours on the frame the
/// state changes. This is the Checkbox and Tag category, not an omission — and
/// it makes the component trivially correct under
/// `MediaQuery.disableAnimationsOf`, because there is nothing to shorten.
///
/// The children are stretched to the field's own width, which is what upstream's
/// `display: grid` root does. A field therefore needs a bounded width, exactly
/// as a block-level `<div>` does.
Widget buildFluentField(
  FluentFieldBaseState state,
  FluentFieldStyle style,
  Set<WidgetState> states,
) {
  final labelPadding = style.labelPadding?.resolve(states) ?? EdgeInsets.zero;
  final secondaryPadding =
      style.secondaryTextPadding?.resolve(states) ?? EdgeInsets.zero;
  final secondaryStyle = style.secondaryTextStyle?.resolve(states);
  final hintColor = style.hintColor?.resolve(states);
  final messageColor = style.validationMessageColor?.resolve(states);
  final iconColor = style.validationMessageIconColor?.resolve(states);
  final iconPadding =
      style.validationMessageIconPadding?.resolve(states) ?? EdgeInsets.zero;
  final iconSize =
      style.validationMessageIconSize?.resolve(states) ?? FluentSize.size120;
  final gap = style.gap?.resolve(states) ?? FluentSpacing.xs;

  Widget secondary(Widget content, Color? color) => DefaultTextStyle.merge(
    style: (secondaryStyle ?? const TextStyle()).copyWith(color: color),
    child: Padding(padding: secondaryPadding, child: content),
  );

  Widget? validation;
  final validationMessage = state.validationMessage;
  if (validationMessage != null) {
    final icon = state.validationMessageIcon;
    validation = secondary(
      icon == null
          ? validationMessage
          : Row(
              // Start, not centre: the glyph belongs beside the FIRST line of a
              // message that wraps, and `iconPadding` already places it against
              // that line's box.
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: gap,
              children: <Widget>[
                Padding(
                  padding: iconPadding,
                  child: IconTheme.merge(
                    data: IconThemeData(color: iconColor, size: iconSize),
                    child: icon,
                  ),
                ),
                // Flexible so a long message wraps inside the row rather than
                // overflowing it.
                Flexible(child: validationMessage),
              ],
            ),
      messageColor,
    );
    // The closest thing Flutter has to upstream's `role="alert"`: a message
    // that appears after the fact is announced, rather than sitting silently
    // under a control the user has already left. `container` is what keeps it
    // a node of its own — without it the flag would merge upwards and turn the
    // entire field into a live region.
    validation = Semantics(
      container: true,
      liveRegion: true,
      child: validation,
    );
  }

  // Figma's order, and upstream's render order: label, control, validation
  // message, hint.
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      if (state.label != null)
        Padding(
          padding: labelPadding,
          // Upstream's label is `maxWidth: max-content` in the stretching
          // grid: as wide as its text, wrapping at the field's width.
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: state.label,
          ),
        ),
      ?state.child,
      ?validation,
      if (state.hint != null) secondary(state.hint!, hintColor),
    ],
  );
}

/// Upstream's default validation glyph for [state], drawn rather than imported.
///
/// `useField_unstable` renders `DiamondDismiss12Filled`, `Warning12Filled` and
/// `CheckmarkCircle12Filled` for `error`, `warning` and `success`; the first is
/// not in `fluentui_system_icons`, so all three are painted from their svg
/// paths by [FluentFieldValidationGlyphPainter]. `none` paints nothing.
///
/// Takes its colour and its box from the ambient [IconTheme], exactly as an
/// `Icon` would.
class FluentFieldValidationGlyph extends StatelessWidget {
  /// Creates the glyph for [state].
  const FluentFieldValidationGlyph({super.key, required this.state});

  /// Which of upstream's glyphs to draw.
  final FluentFieldValidationState state;

  @override
  Widget build(BuildContext context) {
    final icon = IconTheme.of(context);
    return SizedBox.square(
      dimension: icon.size ?? FluentSize.size120,
      child: CustomPaint(
        painter: FluentFieldValidationGlyphPainter(
          state: state,
          color: icon.color ?? const Color(0xFF000000),
        ),
      ),
    );
  }
}

/// Paints [FluentFieldValidationGlyph].
///
/// The 12-unit paths of `@fluentui/react-icons`' `DiamondDismiss12Filled`,
/// `Warning12Filled` and `CheckmarkCircle12Filled`, transcribed command for
/// command and scaled to the box as the browser scales the 12px svg.
class FluentFieldValidationGlyphPainter extends CustomPainter {
  /// Creates a painter for [state] in [color].
  const FluentFieldValidationGlyphPainter({
    required this.state,
    required this.color,
  });

  /// Which glyph to paint. `none` paints nothing.
  final FluentFieldValidationState state;

  /// The fill colour.
  final Color color;

  static const Radius _r05 = Radius.circular(0.5);

  static final Path _diamondDismiss = Path()
    ..moveTo(4.58, 1.58)
    ..relativeArcToPoint(
      const Offset(2.83, 0),
      radius: const Radius.circular(2),
    )
    ..relativeLineTo(3, 3)
    ..relativeArcToPoint(
      const Offset(0, 2.83),
      radius: const Radius.circular(2),
    )
    ..relativeLineTo(-3, 3)
    ..relativeArcToPoint(
      const Offset(-2.83, 0),
      radius: const Radius.circular(2),
    )
    ..relativeLineTo(-3, -3)
    ..relativeArcToPoint(
      const Offset(-0.14, -2.68),
      radius: const Radius.circular(2),
    )
    ..relativeLineTo(0.14, -0.15)
    ..relativeLineTo(3, -3)
    ..close()
    ..moveTo(7.85, 4.15)
    ..relativeArcToPoint(const Offset(-0.7, 0), radius: _r05, clockwise: false)
    ..lineTo(6, 5.29)
    ..lineTo(4.85, 4.15)
    ..relativeLineTo(-0.07, -0.07)
    ..relativeArcToPoint(
      const Offset(-0.7, 0.7),
      radius: _r05,
      clockwise: false,
    )
    ..relativeLineTo(0.07, 0.07)
    ..lineTo(5.29, 6)
    ..lineTo(4.15, 7.15)
    ..relativeArcToPoint(const Offset(0.7, 0.7), radius: _r05, clockwise: false)
    ..lineTo(6, 6.71)
    ..relativeLineTo(1.15, 1.14)
    ..relativeLineTo(0.07, 0.07)
    ..relativeArcToPoint(
      const Offset(0.7, -0.7),
      radius: _r05,
      clockwise: false,
    )
    ..relativeLineTo(-0.07, -0.07)
    ..lineTo(6.71, 6)
    ..relativeLineTo(1.14, -1.15)
    ..relativeArcToPoint(const Offset(0, -0.7), radius: _r05, clockwise: false)
    ..close();

  static final Path _warning = Path()
    ..moveTo(5.21, 1.46)
    ..relativeArcToPoint(
      const Offset(1.58, 0),
      radius: const Radius.circular(0.9),
    )
    ..relativeLineTo(4.09, 7.17)
    ..relativeArcToPoint(
      const Offset(-0.79, 1.37),
      radius: const Radius.circular(0.92),
    )
    ..lineTo(1.91, 10)
    ..relativeArcToPoint(
      const Offset(-0.79, -1.37),
      radius: const Radius.circular(0.92),
    )
    ..relativeLineTo(4.1, -7.17)
    ..close()
    ..moveTo(5.5, 4.5)
    ..relativeLineTo(0, 1)
    ..relativeArcToPoint(const Offset(1, 0), radius: _r05, clockwise: false)
    ..relativeLineTo(0, -1)
    ..relativeArcToPoint(const Offset(-1, 0), radius: _r05, clockwise: false)
    ..close()
    ..moveTo(6, 6.75)
    ..relativeArcToPoint(
      const Offset(0, 1.5),
      radius: const Radius.circular(0.75),
      largeArc: true,
      clockwise: false,
    )
    ..relativeArcToPoint(
      const Offset(0, -1.5),
      radius: const Radius.circular(0.75),
      clockwise: false,
    )
    ..close();

  static final Path _checkmarkCircle = Path()
    ..moveTo(1, 6)
    ..relativeArcToPoint(
      const Offset(10, 0),
      radius: const Radius.circular(5),
      largeArc: true,
    )
    ..arcToPoint(const Offset(1, 6), radius: const Radius.circular(5))
    ..close()
    ..moveTo(8.35, 5.1)
    ..relativeArcToPoint(
      const Offset(-0.7, -0.7),
      radius: _r05,
      largeArc: true,
      clockwise: false,
    )
    ..lineTo(5.5, 6.54)
    ..lineTo(4.35, 5.4)
    ..relativeArcToPoint(
      const Offset(-0.7, 0.7),
      radius: _r05,
      largeArc: true,
      clockwise: false,
    )
    ..relativeLineTo(1.5, 1.5)
    ..relativeCubicTo(0.2, 0.2, 0.5, 0.2, 0.7, 0)
    ..relativeLineTo(2.5, -2.5)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final path = switch (state) {
      FluentFieldValidationState.none => null,
      FluentFieldValidationState.error => _diamondDismiss,
      FluentFieldValidationState.warning => _warning,
      FluentFieldValidationState.success => _checkmarkCircle,
    };
    if (path == null) return;
    canvas
      ..save()
      ..translate(
        (size.width - size.shortestSide) / 2,
        (size.height - size.shortestSide) / 2,
      )
      ..scale(size.shortestSide / 12)
      ..drawPath(path, Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(FluentFieldValidationGlyphPainter oldDelegate) =>
      oldDelegate.state != state || oldDelegate.color != color;
}

/// Overrides the field style for a subtree.
///
/// The middle rung of the resolution order: theme defaults, then this, then the
/// widget's own `style`.
class FluentFieldTheme extends InheritedTheme {
  /// Applies [style] to every `FluentField` in [child].
  const FluentFieldTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the size and validation-state defaults.
  final FluentFieldStyle style;

  /// The nearest field style, or null.
  static FluentFieldStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentFieldTheme>()?.style;

  @override
  bool updateShouldNotify(FluentFieldTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentFieldTheme(style: style, child: child);
}

/// A Fluent 2 field: the label, hint and validation message around a control.
///
/// ```dart
/// FluentField(
///   label: const Text('Email address'),
///   required: true,
///   validationState: FluentFieldValidationState.error,
///   validationMessage: const Text('That address is already registered'),
///   child: myTextInput,
/// )
/// ```
///
/// A pure wrapper: [child] is any widget and the field never inspects it, so
/// this composes with a text input, a slider, a radio group or a control that
/// does not exist yet. It is block-level — the children are stretched to the
/// field's own width, matching upstream's `display: grid` root — so give it a
/// bounded width.
///
/// [validationState] picks upstream's glyph and tints it and the message; it
/// does **not** touch the control. Wiring a red border onto an invalid input is
/// the input's own job, which is exactly how upstream splits it.
///
/// [enabled] is a real state rather than a visual treatment: every colour is
/// resolved from `neutralForegroundDisabled` rather than faded, so it stays
/// correct on any background and in high contrast, and the label greys through
/// [FluentLabel]'s own disabled token. It does not disable [child] — a wrapper
/// that reached into an arbitrary widget to switch it off would be guessing.
///
/// **Nothing animates.** See [buildFluentField].
///
/// Customisation follows the usual three rungs. [style] is merged last and
/// wins; [FluentFieldTheme] restyles a subtree; and for anything further,
/// [resolveFluentFieldState], [resolveFluentFieldStyle] and [buildFluentField]
/// are public so any one of them can be replaced without forking this widget.
/// The label is the one exception: it is a real [FluentLabel], so
/// [FluentLabelTheme] is what restyles it.
class FluentField extends StatelessWidget {
  /// Creates a field around [child].
  const FluentField({
    super.key,
    this.child,
    this.label,
    this.hint,
    this.validationMessage,
    this.validationMessageIcon,
    this.showValidationMessageIcon = true,
    this.validationState = FluentFieldValidationState.none,
    this.size = FluentFieldSize.medium,
    this.required = false,
    this.enabled = true,
    this.style,
  });

  /// The control being wrapped.
  final Widget? child;

  /// The label content. Wrapped in a [FluentLabel] sized from [size].
  final Widget? label;

  /// The hint below the control. Upstream's `hint` slot.
  final Widget? hint;

  /// The validation message below the control.
  final Widget? validationMessage;

  /// Overrides the glyph [validationState] would otherwise draw beside
  /// [validationMessage]. Tinted and sized through [IconTheme]; see
  /// [FluentFieldBaseState.validationMessageIcon].
  final Widget? validationMessageIcon;

  /// Whether a glyph is drawn beside [validationMessage] at all. False removes
  /// it and its gutter, as `validationMessageIcon={null}` does upstream.
  final bool showValidationMessageIcon;

  /// What the field is reporting about [child]'s value.
  final FluentFieldValidationState validationState;

  /// Label ramp and label-to-control gap.
  final FluentFieldSize size;

  /// Whether to render the required-field asterisk after [label].
  ///
  /// Also marks the field itself required in the semantics tree, which is where
  /// the meaning belongs: [FluentLabel] excludes its asterisk from semantics on
  /// purpose, because "Label*" is not what a screen reader should announce.
  final bool required;

  /// Whether the field renders in its enabled colours.
  final bool enabled;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentFieldStyle? style;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentFieldState(
      enabled: enabled,
      size: size,
      validationState: validationState,
      required: required,
      label: label,
      hint: hint,
      validationMessage: validationMessage,
      validationMessageIcon: validationMessageIcon,
      showValidationMessageIcon: showValidationMessageIcon,
      child: child,
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentFieldStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentFieldTheme.maybeOf(context)).merge(style);

    return Semantics(
      // One node, so assistive technology reads the label, the control and the
      // message as one field rather than three unrelated fragments — the port
      // of upstream's `aria-describedby` wiring. Deliberately `container` and
      // not `MergeSemantics`: flattening a text input into its label would
      // destroy the editing semantics the input publishes.
      container: true,
      enabled: enabled,
      // Required-ness belongs to the field, not to the text of its label —
      // which is exactly why `FluentLabel` excludes its asterisk from
      // semantics.
      isRequired: required,
      child: buildFluentField(state, resolved, <WidgetState>{
        if (!enabled) WidgetState.disabled,
      }),
    );
  }
}
