import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentTextarea`.
///
/// Shaped exactly like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed and disabled values live on the
/// property rather than being branched on at build time.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance/size defaults derived from the theme
/// 2. the nearest `FluentTextareaTheme`
/// 3. the widget's own `style`
///
/// ## A bottom border and a focus bar
///
/// Fluent's text inputs give the border a darker bottom side than the other
/// three, and slide a brand-coloured bar over it while the field holds focus.
/// Those are two independent layers upstream — the root's `border-bottom-color`
/// and an `::after` pseudo-element — so they are two independent properties
/// here: [underlineColor] / [underlineThickness] for the bottom side,
/// [focusUnderlineColor] / [focusUnderlineThickness] for the bar that animates
/// in.
///
/// The bar is not expressible as a `WidgetState`, because focus is not a state
/// this component reports — see `FluentTextarea` for why.
@immutable
class FluentTextareaStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentTextareaStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.underlineColor,
    this.underlineThickness,
    this.focusUnderlineColor,
    this.focusUnderlineThickness,
    this.foregroundColor,
    this.placeholderColor,
    this.cursorColor,
    this.selectionColor,
    this.textStyle,
    this.padding,
    this.minimumSize,
    this.mouseCursor,
  });

  /// Surface fill behind the text.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Colour of the border around all four sides. Null means no border at all —
  /// nothing is painted and nothing is inset. Null and transparent are
  /// different: a transparent border still takes its space, and Fluent's
  /// `transparentStroke` becomes opaque in high contrast.
  final WidgetStateProperty<Color?>? borderColor;

  /// Border width. As in CSS, the border insets the content by this much on
  /// every side, before [padding]. Zero means no border, which is not the same
  /// as a transparent one — a zero-width border cannot become visible in high
  /// contrast.
  final WidgetStateProperty<double?>? borderWidth;

  /// Corner radius of the surface.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// The bottom side's colour, when it differs from [borderColor].
  ///
  /// It is a side of the box border, not an overlay: it joins the side colour
  /// along each bottom corner's diagonal, as a CSS border does. Null means the
  /// bottom follows [borderColor] and [borderWidth] like the other three, which
  /// is what the filled appearances and the error and disabled states want.
  final WidgetStateProperty<Color?>? underlineColor;

  /// The bottom side's width, inset from the content like [borderWidth]. 1 in
  /// every state: upstream recolours it on press, it never thickens it.
  /// Ignored when [underlineColor] is null.
  final WidgetStateProperty<double?>? underlineThickness;

  /// The brand rule that scales in horizontally while the field holds focus.
  final WidgetStateProperty<Color?>? focusUnderlineColor;

  /// Thickness of [focusUnderlineColor].
  final WidgetStateProperty<double?>? focusUnderlineThickness;

  /// Colour of the text the user has entered.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Colour of the placeholder shown while the field is empty.
  final WidgetStateProperty<Color?>? placeholderColor;

  /// Caret colour.
  final WidgetStateProperty<Color?>? cursorColor;

  /// Fill painted behind selected text.
  final WidgetStateProperty<Color?>? selectionColor;

  /// Type ramp of both the value and the placeholder. Its colour is overridden
  /// by [foregroundColor] and [placeholderColor] respectively.
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Inset between the border and the text.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Minimum size of the border box. Extra height lands below the text, as a
  /// CSS `min-height` does.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Cursor shown while hovering.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour.
  FluentTextareaStyle merge(FluentTextareaStyle? other) {
    if (other == null) return this;
    return FluentTextareaStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      underlineColor: other.underlineColor ?? underlineColor,
      underlineThickness: other.underlineThickness ?? underlineThickness,
      focusUnderlineColor: other.focusUnderlineColor ?? focusUnderlineColor,
      focusUnderlineThickness:
          other.focusUnderlineThickness ?? focusUnderlineThickness,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      placeholderColor: other.placeholderColor ?? placeholderColor,
      cursorColor: other.cursorColor ?? cursorColor,
      selectionColor: other.selectionColor ?? selectionColor,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      minimumSize: other.minimumSize ?? minimumSize,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentTextareaStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<Color?>? underlineColor,
    WidgetStateProperty<double?>? underlineThickness,
    WidgetStateProperty<Color?>? focusUnderlineColor,
    WidgetStateProperty<double?>? focusUnderlineThickness,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? placeholderColor,
    WidgetStateProperty<Color?>? cursorColor,
    WidgetStateProperty<Color?>? selectionColor,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentTextareaStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    underlineColor: underlineColor ?? this.underlineColor,
    underlineThickness: underlineThickness ?? this.underlineThickness,
    focusUnderlineColor: focusUnderlineColor ?? this.focusUnderlineColor,
    focusUnderlineThickness:
        focusUnderlineThickness ?? this.focusUnderlineThickness,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    placeholderColor: placeholderColor ?? this.placeholderColor,
    cursorColor: cursorColor ?? this.cursorColor,
    selectionColor: selectionColor ?? this.selectionColor,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    minimumSize: minimumSize ?? this.minimumSize,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// Use the constructor directly when a property genuinely differs per state.
  static FluentTextareaStyle from({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    Color? underlineColor,
    double? underlineThickness,
    Color? focusUnderlineColor,
    double? focusUnderlineThickness,
    Color? foregroundColor,
    Color? placeholderColor,
    Color? cursorColor,
    Color? selectionColor,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    MouseCursor? mouseCursor,
  }) => FluentTextareaStyle(
    backgroundColor: _all(backgroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    underlineColor: _all(underlineColor),
    underlineThickness: _all(underlineThickness),
    focusUnderlineColor: _all(focusUnderlineColor),
    focusUnderlineThickness: _all(focusUnderlineThickness),
    foregroundColor: _all(foregroundColor),
    placeholderColor: _all(placeholderColor),
    cursorColor: _all(cursorColor),
    selectionColor: _all(selectionColor),
    textStyle: _all(textStyle),
    padding: _all(padding),
    minimumSize: _all(minimumSize),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentTextareaStyle &&
      other.backgroundColor == backgroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.underlineColor == underlineColor &&
      other.underlineThickness == underlineThickness &&
      other.focusUnderlineColor == focusUnderlineColor &&
      other.focusUnderlineThickness == focusUnderlineThickness &&
      other.foregroundColor == foregroundColor &&
      other.placeholderColor == placeholderColor &&
      other.cursorColor == cursorColor &&
      other.selectionColor == selectionColor &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.minimumSize == minimumSize &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    underlineColor,
    underlineThickness,
    focusUnderlineColor,
    focusUnderlineThickness,
    foregroundColor,
    placeholderColor,
    cursorColor,
    selectionColor,
    textStyle,
    padding,
    minimumSize,
    mouseCursor,
  );
}
