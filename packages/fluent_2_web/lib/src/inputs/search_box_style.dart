import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentSearchBox`.
///
/// Shaped exactly like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover and disabled values live on the property
/// rather than being branched on at build time.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance/size defaults derived from the theme
/// 2. the nearest `FluentSearchBoxTheme`
/// 3. the widget's own `style`
///
/// ## Which states actually move
///
/// Only **rest**, **hover** and **disabled** are resolved here. Figma's
/// `SearchBox` set has a `State` axis of `Rest`, `Focus` and `Hover`, and its
/// `Focus` variants bind the *rest* stroke tokens — focus is signalled by
/// [focusUnderlineColor] alone, not by the border. There is no `Pressed`
/// variant, and no `Selected` one.
@immutable
class FluentSearchBoxStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentSearchBoxStyle({
    this.backgroundColor,
    this.borderColor,
    this.bottomBorderColor,
    this.focusUnderlineColor,
    this.borderWidth,
    this.borderRadius,
    this.foregroundColor,
    this.placeholderColor,
    this.iconColor,
    this.cursorColor,
    this.selectionColor,
    this.textStyle,
    this.padding,
    this.gap,
    this.contentGap,
    this.iconSize,
    this.clearIconSize,
    this.minimumSize,
    this.maximumSize,
    this.mouseCursor,
  });

  /// Surface fill.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Colour of the border drawn on all four sides.
  ///
  /// Null and transparent are different: the filled appearances use Fluent's
  /// `transparentStroke` family, which becomes opaque in high contrast.
  final WidgetStateProperty<Color?>? borderColor;

  /// Colour of the 1px rule Figma draws across the bottom edge, over
  /// [borderColor].
  ///
  /// A separate property because Fluent gives the bottom edge its own,
  /// higher-contrast token (`neutralStrokeAccessible`) — and because Flutter
  /// refuses to paint a rounded rectangle whose border sides disagree, so the
  /// rule has to be an overlay rather than a `BorderSide`. Null on the filled
  /// appearances, which draw no rule at all.
  final WidgetStateProperty<Color?>? bottomBorderColor;

  /// Colour of the 2px focus underline. `compoundBrandStroke`.
  final WidgetStateProperty<Color?>? focusUnderlineColor;

  /// Border width. Zero means no border, which is not the same as a transparent
  /// one — a zero-width border cannot become visible in high contrast.
  final WidgetStateProperty<double?>? borderWidth;

  /// Corner radius.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Colour of the text the user has typed.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Colour of the placeholder shown while the field is empty.
  final WidgetStateProperty<Color?>? placeholderColor;

  /// Colour of the leading search glyph and the trailing clear glyph.
  final WidgetStateProperty<Color?>? iconColor;

  /// Caret colour.
  final WidgetStateProperty<Color?>? cursorColor;

  /// Selection highlight colour.
  final WidgetStateProperty<Color?>? selectionColor;

  /// Text style of both the value and the placeholder. Its colour is overridden
  /// by [foregroundColor] and [placeholderColor] respectively.
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Padding inside the border.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Space between the leading glyph and the text.
  final WidgetStateProperty<double?>? gap;

  /// Space between the text and the trailing clear button.
  final WidgetStateProperty<double?>? contentGap;

  /// Leading glyph edge length.
  final WidgetStateProperty<double?>? iconSize;

  /// Trailing clear glyph edge length. Not the same ramp as [iconSize].
  final WidgetStateProperty<double?>? clearIconSize;

  /// Minimum size. Only the height is meaningful.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Maximum size. Only the width is meaningful; Fluent caps a search box at
  /// 468.
  final WidgetStateProperty<Size?>? maximumSize;

  /// Cursor while hovering the field, outside the clear button.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour.
  FluentSearchBoxStyle merge(FluentSearchBoxStyle? other) {
    if (other == null) return this;
    return FluentSearchBoxStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      bottomBorderColor: other.bottomBorderColor ?? bottomBorderColor,
      focusUnderlineColor: other.focusUnderlineColor ?? focusUnderlineColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      placeholderColor: other.placeholderColor ?? placeholderColor,
      iconColor: other.iconColor ?? iconColor,
      cursorColor: other.cursorColor ?? cursorColor,
      selectionColor: other.selectionColor ?? selectionColor,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
      contentGap: other.contentGap ?? contentGap,
      iconSize: other.iconSize ?? iconSize,
      clearIconSize: other.clearIconSize ?? clearIconSize,
      minimumSize: other.minimumSize ?? minimumSize,
      maximumSize: other.maximumSize ?? maximumSize,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentSearchBoxStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<Color?>? bottomBorderColor,
    WidgetStateProperty<Color?>? focusUnderlineColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? placeholderColor,
    WidgetStateProperty<Color?>? iconColor,
    WidgetStateProperty<Color?>? cursorColor,
    WidgetStateProperty<Color?>? selectionColor,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<double?>? contentGap,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<double?>? clearIconSize,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<Size?>? maximumSize,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentSearchBoxStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    bottomBorderColor: bottomBorderColor ?? this.bottomBorderColor,
    focusUnderlineColor: focusUnderlineColor ?? this.focusUnderlineColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    placeholderColor: placeholderColor ?? this.placeholderColor,
    iconColor: iconColor ?? this.iconColor,
    cursorColor: cursorColor ?? this.cursorColor,
    selectionColor: selectionColor ?? this.selectionColor,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    contentGap: contentGap ?? this.contentGap,
    iconSize: iconSize ?? this.iconSize,
    clearIconSize: clearIconSize ?? this.clearIconSize,
    minimumSize: minimumSize ?? this.minimumSize,
    maximumSize: maximumSize ?? this.maximumSize,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentSearchBoxStyle from({
    Color? backgroundColor,
    Color? borderColor,
    Color? bottomBorderColor,
    Color? focusUnderlineColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    Color? foregroundColor,
    Color? placeholderColor,
    Color? iconColor,
    Color? cursorColor,
    Color? selectionColor,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? contentGap,
    double? iconSize,
    double? clearIconSize,
    Size? minimumSize,
    Size? maximumSize,
    MouseCursor? mouseCursor,
  }) => FluentSearchBoxStyle(
    backgroundColor: _all(backgroundColor),
    borderColor: _all(borderColor),
    bottomBorderColor: _all(bottomBorderColor),
    focusUnderlineColor: _all(focusUnderlineColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    foregroundColor: _all(foregroundColor),
    placeholderColor: _all(placeholderColor),
    iconColor: _all(iconColor),
    cursorColor: _all(cursorColor),
    selectionColor: _all(selectionColor),
    textStyle: _all(textStyle),
    padding: _all(padding),
    gap: _all(gap),
    contentGap: _all(contentGap),
    iconSize: _all(iconSize),
    clearIconSize: _all(clearIconSize),
    minimumSize: _all(minimumSize),
    maximumSize: _all(maximumSize),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentSearchBoxStyle &&
      other.backgroundColor == backgroundColor &&
      other.borderColor == borderColor &&
      other.bottomBorderColor == bottomBorderColor &&
      other.focusUnderlineColor == focusUnderlineColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.foregroundColor == foregroundColor &&
      other.placeholderColor == placeholderColor &&
      other.iconColor == iconColor &&
      other.cursorColor == cursorColor &&
      other.selectionColor == selectionColor &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.gap == gap &&
      other.contentGap == contentGap &&
      other.iconSize == iconSize &&
      other.clearIconSize == clearIconSize &&
      other.minimumSize == minimumSize &&
      other.maximumSize == maximumSize &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    bottomBorderColor,
    focusUnderlineColor,
    borderWidth,
    borderRadius,
    foregroundColor,
    placeholderColor,
    iconColor,
    cursorColor,
    selectionColor,
    textStyle,
    padding,
    gap,
    contentGap,
    iconSize,
    clearIconSize,
    minimumSize,
    Object.hash(maximumSize, mouseCursor),
  );
}
