import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentSpinButton`.
///
/// Shaped exactly like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed and disabled values live on the
/// property rather than being branched on at build time.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance/size defaults derived from the theme
/// 2. the nearest `FluentSpinButtonTheme`
/// 3. the widget's own `style`
///
/// Three properties have no counterpart on a plain button and are worth calling
/// out, because they are how Fluent's input chrome is actually assembled:
/// [bottomRuleColor] is the *darker bottom edge* an Outline or Underline input
/// carries in addition to (Outline) or instead of (Underline) its border, and
/// [focusUnderlineColor] with [focusUnderlineWidth] is the brand rule that
/// grows out of the centre on focus.
@immutable
class FluentSpinButtonStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentSpinButtonStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.bottomRuleColor,
    this.bottomRuleWidth,
    this.focusUnderlineColor,
    this.focusUnderlineWidth,
    this.foregroundColor,
    this.placeholderColor,
    this.cursorColor,
    this.selectionColor,
    this.stepperForegroundColor,
    this.stepperBackgroundColor,
    this.textStyle,
    this.padding,
    this.contentPadding,
    this.stepperSize,
    this.stepperPadding,
    this.glyphSize,
    this.minimumSize,
    this.mouseCursor,
  });

  /// Surface fill behind the text and the steppers.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Border colour, uniform on all four sides. Null and transparent are
  /// different: Fluent's `transparentStroke` family becomes opaque in high
  /// contrast, which is the only thing outlining a filled input there.
  final WidgetStateProperty<Color?>? borderColor;

  /// Border width. Zero means no border, which is not the same as a transparent
  /// one — a zero-width border cannot become visible in high contrast.
  final WidgetStateProperty<double?>? borderWidth;

  /// Corner radius.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// The rule along the bottom edge, drawn over the border.
  ///
  /// Null means the border alone carries the bottom edge — which is what a
  /// disabled or filled input does. Outline draws it in the
  /// `neutralStrokeAccessible` ramp; Underline draws it *as* the whole border.
  final WidgetStateProperty<Color?>? bottomRuleColor;

  /// Thickness of [bottomRuleColor]'s rule.
  final WidgetStateProperty<double?>? bottomRuleWidth;

  /// The brand rule that grows from the centre when the field takes focus.
  final WidgetStateProperty<Color?>? focusUnderlineColor;

  /// Thickness of the focus rule. `FluentStroke.thick` upstream and in Figma.
  final WidgetStateProperty<double?>? focusUnderlineWidth;

  /// Colour of the value text.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Colour of the placeholder text. A different token from
  /// [foregroundColor] — never the same colour at a lower opacity.
  final WidgetStateProperty<Color?>? placeholderColor;

  /// Caret colour.
  final WidgetStateProperty<Color?>? cursorColor;

  /// Selection highlight colour.
  final WidgetStateProperty<Color?>? selectionColor;

  /// Chevron colour on the stepper column. Resolved against the *stepper's* own
  /// interaction states, not the field's.
  final WidgetStateProperty<Color?>? stepperForegroundColor;

  /// Fill behind one stepper, resolved against that stepper's own states.
  final WidgetStateProperty<Color?>? stepperBackgroundColor;

  /// Text ramp of the value and the placeholder alike.
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Inset from the control's edge to the content row. Left only in Fluent —
  /// the stepper column sits flush against the right edge.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Inset around the editable text itself, inside [padding].
  final WidgetStateProperty<EdgeInsetsGeometry?>? contentPadding;

  /// Size of one stepper. Both halves are the same size, and the column is two
  /// of them stacked.
  final WidgetStateProperty<Size?>? stepperSize;

  /// Inset from one stepper's box to its chevron glyph box. Asymmetric: the
  /// increase half is padded at the top, the decrease half at the bottom, so
  /// the value given here is applied to whichever edge faces away from the
  /// middle.
  final WidgetStateProperty<EdgeInsetsGeometry?>? stepperPadding;

  /// Edge length of a chevron's glyph box.
  final WidgetStateProperty<double?>? glyphSize;

  /// Minimum size of the whole control. Only the height is a Fluent number; the
  /// width is whatever the caller gives it.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Cursor while hovering the text area.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour.
  FluentSpinButtonStyle merge(FluentSpinButtonStyle? other) {
    if (other == null) return this;
    return FluentSpinButtonStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      bottomRuleColor: other.bottomRuleColor ?? bottomRuleColor,
      bottomRuleWidth: other.bottomRuleWidth ?? bottomRuleWidth,
      focusUnderlineColor: other.focusUnderlineColor ?? focusUnderlineColor,
      focusUnderlineWidth: other.focusUnderlineWidth ?? focusUnderlineWidth,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      placeholderColor: other.placeholderColor ?? placeholderColor,
      cursorColor: other.cursorColor ?? cursorColor,
      selectionColor: other.selectionColor ?? selectionColor,
      stepperForegroundColor:
          other.stepperForegroundColor ?? stepperForegroundColor,
      stepperBackgroundColor:
          other.stepperBackgroundColor ?? stepperBackgroundColor,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      contentPadding: other.contentPadding ?? contentPadding,
      stepperSize: other.stepperSize ?? stepperSize,
      stepperPadding: other.stepperPadding ?? stepperPadding,
      glyphSize: other.glyphSize ?? glyphSize,
      minimumSize: other.minimumSize ?? minimumSize,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentSpinButtonStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<Color?>? bottomRuleColor,
    WidgetStateProperty<double?>? bottomRuleWidth,
    WidgetStateProperty<Color?>? focusUnderlineColor,
    WidgetStateProperty<double?>? focusUnderlineWidth,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? placeholderColor,
    WidgetStateProperty<Color?>? cursorColor,
    WidgetStateProperty<Color?>? selectionColor,
    WidgetStateProperty<Color?>? stepperForegroundColor,
    WidgetStateProperty<Color?>? stepperBackgroundColor,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<EdgeInsetsGeometry?>? contentPadding,
    WidgetStateProperty<Size?>? stepperSize,
    WidgetStateProperty<EdgeInsetsGeometry?>? stepperPadding,
    WidgetStateProperty<double?>? glyphSize,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentSpinButtonStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    bottomRuleColor: bottomRuleColor ?? this.bottomRuleColor,
    bottomRuleWidth: bottomRuleWidth ?? this.bottomRuleWidth,
    focusUnderlineColor: focusUnderlineColor ?? this.focusUnderlineColor,
    focusUnderlineWidth: focusUnderlineWidth ?? this.focusUnderlineWidth,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    placeholderColor: placeholderColor ?? this.placeholderColor,
    cursorColor: cursorColor ?? this.cursorColor,
    selectionColor: selectionColor ?? this.selectionColor,
    stepperForegroundColor:
        stepperForegroundColor ?? this.stepperForegroundColor,
    stepperBackgroundColor:
        stepperBackgroundColor ?? this.stepperBackgroundColor,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    contentPadding: contentPadding ?? this.contentPadding,
    stepperSize: stepperSize ?? this.stepperSize,
    stepperPadding: stepperPadding ?? this.stepperPadding,
    glyphSize: glyphSize ?? this.glyphSize,
    minimumSize: minimumSize ?? this.minimumSize,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentSpinButtonStyle from({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    Color? bottomRuleColor,
    double? bottomRuleWidth,
    Color? focusUnderlineColor,
    double? focusUnderlineWidth,
    Color? foregroundColor,
    Color? placeholderColor,
    Color? cursorColor,
    Color? selectionColor,
    Color? stepperForegroundColor,
    Color? stepperBackgroundColor,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? contentPadding,
    Size? stepperSize,
    EdgeInsetsGeometry? stepperPadding,
    double? glyphSize,
    Size? minimumSize,
    MouseCursor? mouseCursor,
  }) => FluentSpinButtonStyle(
    backgroundColor: _all(backgroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    bottomRuleColor: _all(bottomRuleColor),
    bottomRuleWidth: _all(bottomRuleWidth),
    focusUnderlineColor: _all(focusUnderlineColor),
    focusUnderlineWidth: _all(focusUnderlineWidth),
    foregroundColor: _all(foregroundColor),
    placeholderColor: _all(placeholderColor),
    cursorColor: _all(cursorColor),
    selectionColor: _all(selectionColor),
    stepperForegroundColor: _all(stepperForegroundColor),
    stepperBackgroundColor: _all(stepperBackgroundColor),
    textStyle: _all(textStyle),
    padding: _all(padding),
    contentPadding: _all(contentPadding),
    stepperSize: _all(stepperSize),
    stepperPadding: _all(stepperPadding),
    glyphSize: _all(glyphSize),
    minimumSize: _all(minimumSize),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentSpinButtonStyle &&
      other.backgroundColor == backgroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.bottomRuleColor == bottomRuleColor &&
      other.bottomRuleWidth == bottomRuleWidth &&
      other.focusUnderlineColor == focusUnderlineColor &&
      other.focusUnderlineWidth == focusUnderlineWidth &&
      other.foregroundColor == foregroundColor &&
      other.placeholderColor == placeholderColor &&
      other.cursorColor == cursorColor &&
      other.selectionColor == selectionColor &&
      other.stepperForegroundColor == stepperForegroundColor &&
      other.stepperBackgroundColor == stepperBackgroundColor &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.contentPadding == contentPadding &&
      other.stepperSize == stepperSize &&
      other.stepperPadding == stepperPadding &&
      other.glyphSize == glyphSize &&
      other.minimumSize == minimumSize &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    bottomRuleColor,
    bottomRuleWidth,
    focusUnderlineColor,
    focusUnderlineWidth,
    foregroundColor,
    placeholderColor,
    cursorColor,
    selectionColor,
    stepperForegroundColor,
    stepperBackgroundColor,
    textStyle,
    padding,
    contentPadding,
    stepperSize,
    stepperPadding,
    glyphSize,
    minimumSize,
    mouseCursor,
  ]);
}
