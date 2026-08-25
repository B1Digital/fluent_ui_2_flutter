import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentBadge`.
///
/// Shaped exactly like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so a Flutter developer already knows how to read and
/// override it. A badge is not interactive — Fluent ships no hover, pressed or
/// disabled Badge tokens — so in practice every property here resolves to one
/// value. The state-property shape is kept anyway, because a badge composed
/// into an interactive surface (a tab, a menu item) has to be able to follow
/// that surface's states, and because one style shape across ~100 components is
/// worth more than a per-component saving.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the colour/size/appearance defaults derived from the theme
/// 2. the nearest `FluentBadgeTheme`
/// 3. the widget's own `style`
@immutable
class FluentBadgeStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentBadgeStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.textStyle,
    this.padding,
    this.gap,
    this.iconSize,
    this.minimumSize,
  });

  /// Surface fill.
  ///
  /// Never null in a resolved style: the Outline and Subtle appearances paint
  /// Fluent's `transparentBackground` token rather than nothing, because that
  /// token turns opaque in high contrast where a literal never would.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Label and icon colour.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Border colour, or null on the appearances Figma leaves unstroked.
  final WidgetStateProperty<Color?>? borderColor;

  /// Border width. Zero means no border, which is not the same as a transparent
  /// one — a zero-width border cannot become visible in high contrast.
  final WidgetStateProperty<double?>? borderWidth;

  /// Corner radius.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Label text style. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Padding inside the border.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Space between icon and label.
  final WidgetStateProperty<double?>? gap;

  /// Icon edge length.
  final WidgetStateProperty<double?>? iconSize;

  /// Minimum size. Figma pins the minimum *width* to the height on every size,
  /// which is what keeps an empty or single-digit badge round instead of
  /// collapsing onto its padding.
  final WidgetStateProperty<Size?>? minimumSize;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour.
  FluentBadgeStyle merge(FluentBadgeStyle? other) {
    if (other == null) return this;
    return FluentBadgeStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
      iconSize: other.iconSize ?? iconSize,
      minimumSize: other.minimumSize ?? minimumSize,
    );
  }

  /// This style with the given properties replaced.
  FluentBadgeStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<Size?>? minimumSize,
  }) => FluentBadgeStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    minimumSize: minimumSize ?? this.minimumSize,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentBadgeStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? iconSize,
    Size? minimumSize,
  }) => FluentBadgeStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    textStyle: _all(textStyle),
    padding: _all(padding),
    gap: _all(gap),
    iconSize: _all(iconSize),
    minimumSize: _all(minimumSize),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentBadgeStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.minimumSize == minimumSize;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    textStyle,
    padding,
    gap,
    iconSize,
    minimumSize,
  );
}
