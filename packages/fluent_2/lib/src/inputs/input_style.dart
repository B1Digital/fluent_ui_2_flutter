import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentInput`.
///
/// Shaped exactly like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed and disabled values live on the
/// property rather than being branched on at build time.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance/size defaults derived from the theme
/// 2. the nearest `FluentInputTheme`
/// 3. the widget's own `style`
///
/// Three properties describe the lines Fluent draws round and under the field
/// and are easy to confuse:
///
/// * [borderColor] / [borderWidth] — the box border: top, left and right, and
///   the bottom too when [bottomBorderColor] is null.
/// * [bottomBorderColor] / [bottomBorderWidth] — the bottom side of that same
///   border in its own colour, which upstream writes as `borderBottomColor`.
///   On `outline` this is the `Neutral/Stroke/Accessible/*` ramp; on
///   `underline` it is the only side the field has.
/// * [focusUnderlineColor] / [focusUnderlineWidth] — the brand bar that grows
///   across the bottom while the field holds focus. Upstream's `::after`
///   pseudo-element.
///
/// The border is a real CSS-style border, painted by `FluentInputBorderPainter`:
/// it takes space, so the content row sits inside it, and where the bottom
/// colour differs from the sides the two meet along the corner diagonal, the
/// way a browser joins them.
@immutable
class FluentInputStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentInputStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.bottomBorderColor,
    this.bottomBorderWidth,
    this.focusUnderlineColor,
    this.focusUnderlineWidth,
    this.foregroundColor,
    this.placeholderColor,
    this.contentColor,
    this.textStyle,
    this.padding,
    this.contentPadding,
    this.gap,
    this.iconSize,
    this.minimumSize,
    this.cursorColor,
    this.selectionColor,
    this.mouseCursor,
  });

  /// Surface fill.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Box border colour. Null means no border at all — nothing is painted and
  /// nothing is inset, whatever [borderWidth] says. Null and transparent are
  /// different: a transparent border still takes its space, and Fluent's
  /// `transparentStroke` becomes opaque in high contrast.
  final WidgetStateProperty<Color?>? borderColor;

  /// Box border width. As in CSS, the border insets the content by this much
  /// on every side it is drawn on, before [padding]. Zero means no border,
  /// which is not the same as a transparent one.
  final WidgetStateProperty<double?>? borderWidth;

  /// Corner radius.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// The bottom side's colour, when it differs from [borderColor]. It is a side
  /// of the box border, not an overlay: it joins the side colour along each
  /// bottom corner's diagonal. Null means the bottom follows [borderColor] and
  /// [borderWidth] like the other three, which is what the two filled
  /// appearances want.
  final WidgetStateProperty<Color?>? bottomBorderColor;

  /// The bottom side's width, inset from the content like [borderWidth]. 1 in
  /// every state: upstream recolours it on press, it never thickens it.
  /// Ignored when [bottomBorderColor] is null.
  final WidgetStateProperty<double?>? bottomBorderWidth;

  /// The brand focus bar's colour. Its thickness is [focusUnderlineWidth].
  final WidgetStateProperty<Color?>? focusUnderlineColor;

  /// The brand focus bar's thickness. Null is `FluentStroke.thick`, as upstream
  /// hard-codes `2px solid`.
  final WidgetStateProperty<double?>? focusUnderlineWidth;

  /// Typed-text colour.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Placeholder colour. A separate ramp from [foregroundColor] — Figma's
  /// `.Text` layer binds `Neutral/Foreground/4/Rest` in every state but
  /// `Read only`, which is the placeholder, not the value.
  final WidgetStateProperty<Color?>? placeholderColor;

  /// Colour of the content-before and content-after slots.
  final WidgetStateProperty<Color?>? contentColor;

  /// Text style shared by the value, the placeholder and both slots.
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Inset between the border and the content row, on top of the border's own
  /// width.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Extra inset applied to the editable field alone, inside [padding].
  final WidgetStateProperty<EdgeInsetsGeometry?>? contentPadding;

  /// Space between the slots and the field.
  final WidgetStateProperty<double?>? gap;

  /// Icon edge length in the two content slots.
  final WidgetStateProperty<double?>? iconSize;

  /// Minimum size. Only the height is used.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Caret colour.
  final WidgetStateProperty<Color?>? cursorColor;

  /// Selection highlight colour.
  final WidgetStateProperty<Color?>? selectionColor;

  /// Cursor while hovering.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour.
  FluentInputStyle merge(FluentInputStyle? other) {
    if (other == null) return this;
    return FluentInputStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      bottomBorderColor: other.bottomBorderColor ?? bottomBorderColor,
      bottomBorderWidth: other.bottomBorderWidth ?? bottomBorderWidth,
      focusUnderlineColor: other.focusUnderlineColor ?? focusUnderlineColor,
      focusUnderlineWidth: other.focusUnderlineWidth ?? focusUnderlineWidth,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      placeholderColor: other.placeholderColor ?? placeholderColor,
      contentColor: other.contentColor ?? contentColor,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      contentPadding: other.contentPadding ?? contentPadding,
      gap: other.gap ?? gap,
      iconSize: other.iconSize ?? iconSize,
      minimumSize: other.minimumSize ?? minimumSize,
      cursorColor: other.cursorColor ?? cursorColor,
      selectionColor: other.selectionColor ?? selectionColor,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentInputStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<Color?>? bottomBorderColor,
    WidgetStateProperty<double?>? bottomBorderWidth,
    WidgetStateProperty<Color?>? focusUnderlineColor,
    WidgetStateProperty<double?>? focusUnderlineWidth,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? placeholderColor,
    WidgetStateProperty<Color?>? contentColor,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<EdgeInsetsGeometry?>? contentPadding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<Color?>? cursorColor,
    WidgetStateProperty<Color?>? selectionColor,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentInputStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    bottomBorderColor: bottomBorderColor ?? this.bottomBorderColor,
    bottomBorderWidth: bottomBorderWidth ?? this.bottomBorderWidth,
    focusUnderlineColor: focusUnderlineColor ?? this.focusUnderlineColor,
    focusUnderlineWidth: focusUnderlineWidth ?? this.focusUnderlineWidth,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    placeholderColor: placeholderColor ?? this.placeholderColor,
    contentColor: contentColor ?? this.contentColor,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    contentPadding: contentPadding ?? this.contentPadding,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    minimumSize: minimumSize ?? this.minimumSize,
    cursorColor: cursorColor ?? this.cursorColor,
    selectionColor: selectionColor ?? this.selectionColor,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentInputStyle from({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    Color? bottomBorderColor,
    double? bottomBorderWidth,
    Color? focusUnderlineColor,
    double? focusUnderlineWidth,
    Color? foregroundColor,
    Color? placeholderColor,
    Color? contentColor,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? contentPadding,
    double? gap,
    double? iconSize,
    Size? minimumSize,
    Color? cursorColor,
    Color? selectionColor,
    MouseCursor? mouseCursor,
  }) => FluentInputStyle(
    backgroundColor: _all(backgroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    bottomBorderColor: _all(bottomBorderColor),
    bottomBorderWidth: _all(bottomBorderWidth),
    focusUnderlineColor: _all(focusUnderlineColor),
    focusUnderlineWidth: _all(focusUnderlineWidth),
    foregroundColor: _all(foregroundColor),
    placeholderColor: _all(placeholderColor),
    contentColor: _all(contentColor),
    textStyle: _all(textStyle),
    padding: _all(padding),
    contentPadding: _all(contentPadding),
    gap: _all(gap),
    iconSize: _all(iconSize),
    minimumSize: _all(minimumSize),
    cursorColor: _all(cursorColor),
    selectionColor: _all(selectionColor),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentInputStyle &&
      other.backgroundColor == backgroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.bottomBorderColor == bottomBorderColor &&
      other.bottomBorderWidth == bottomBorderWidth &&
      other.focusUnderlineColor == focusUnderlineColor &&
      other.focusUnderlineWidth == focusUnderlineWidth &&
      other.foregroundColor == foregroundColor &&
      other.placeholderColor == placeholderColor &&
      other.contentColor == contentColor &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.contentPadding == contentPadding &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.minimumSize == minimumSize &&
      other.cursorColor == cursorColor &&
      other.selectionColor == selectionColor &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    bottomBorderColor,
    bottomBorderWidth,
    focusUnderlineColor,
    focusUnderlineWidth,
    foregroundColor,
    placeholderColor,
    contentColor,
    textStyle,
    padding,
    contentPadding,
    gap,
    iconSize,
    minimumSize,
    cursorColor,
    selectionColor,
    mouseCursor,
  );
}
