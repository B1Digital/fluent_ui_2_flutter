import 'package:flutter/widgets.dart';

/// The visual configuration of one row of a `FluentNav`.
///
/// One style covers every row kind — app item, category header, item and
/// sub-item — because Figma builds all four out of the same two boxes: an outer
/// frame carrying [outerPadding] and the selection indicator, and an inner
/// `Button` frame carrying [backgroundColor], [borderRadius] and [padding].
/// Splitting it four ways would duplicate nine identical properties to vary two.
///
/// Deliberately shaped like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed, selected and disabled values live
/// on the property rather than being branched on at build time.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the kind/size defaults derived from the theme
/// 2. the nearest `FluentNavItemTheme`
/// 3. the widget's own `style`
@immutable
class FluentNavItemStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentNavItemStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.iconColor,
    this.indicatorColor,
    this.textStyle,
    this.borderRadius,
    this.indicatorRadius,
    this.padding,
    this.outerPadding,
    this.gap,
    this.indicatorGap,
    this.indicatorSize,
    this.iconSize,
    this.minimumSize,
    this.mouseCursor,
  });

  /// Fill of the inner `Button` box.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Label colour.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Leading-icon colour.
  ///
  /// Separate from [foregroundColor] because a *selected* row paints its icon
  /// with the compound brand token while its label stays neutral.
  final WidgetStateProperty<Color?>? iconColor;

  /// The selection indicator — Fluent's "french fry" — colour.
  final WidgetStateProperty<Color?>? indicatorColor;

  /// Label text style. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Corner radius of the inner `Button` box.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Corner radius of the selection indicator.
  final WidgetStateProperty<BorderRadius?>? indicatorRadius;

  /// Padding inside the `Button` box.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Padding of the outer frame, outside the indicator.
  final WidgetStateProperty<EdgeInsetsGeometry?>? outerPadding;

  /// Space between icon, label and trailing slot.
  final WidgetStateProperty<double?>? gap;

  /// Space between the selection indicator and the `Button` box.
  final WidgetStateProperty<double?>? indicatorGap;

  /// Selection indicator size, width before height.
  final WidgetStateProperty<Size?>? indicatorSize;

  /// Icon edge length.
  final WidgetStateProperty<double?>? iconSize;

  /// Minimum size of the `Button` box. Only the height is load-bearing: a nav
  /// row fills the width it is given.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Cursor while hovering.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only [borderRadius]
  /// keeps every resolved colour.
  FluentNavItemStyle merge(FluentNavItemStyle? other) {
    if (other == null) return this;
    return FluentNavItemStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      iconColor: other.iconColor ?? iconColor,
      indicatorColor: other.indicatorColor ?? indicatorColor,
      textStyle: other.textStyle ?? textStyle,
      borderRadius: other.borderRadius ?? borderRadius,
      indicatorRadius: other.indicatorRadius ?? indicatorRadius,
      padding: other.padding ?? padding,
      outerPadding: other.outerPadding ?? outerPadding,
      gap: other.gap ?? gap,
      indicatorGap: other.indicatorGap ?? indicatorGap,
      indicatorSize: other.indicatorSize ?? indicatorSize,
      iconSize: other.iconSize ?? iconSize,
      minimumSize: other.minimumSize ?? minimumSize,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentNavItemStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? iconColor,
    WidgetStateProperty<Color?>? indicatorColor,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<BorderRadius?>? indicatorRadius,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<EdgeInsetsGeometry?>? outerPadding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<double?>? indicatorGap,
    WidgetStateProperty<Size?>? indicatorSize,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentNavItemStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    iconColor: iconColor ?? this.iconColor,
    indicatorColor: indicatorColor ?? this.indicatorColor,
    textStyle: textStyle ?? this.textStyle,
    borderRadius: borderRadius ?? this.borderRadius,
    indicatorRadius: indicatorRadius ?? this.indicatorRadius,
    padding: padding ?? this.padding,
    outerPadding: outerPadding ?? this.outerPadding,
    gap: gap ?? this.gap,
    indicatorGap: indicatorGap ?? this.indicatorGap,
    indicatorSize: indicatorSize ?? this.indicatorSize,
    iconSize: iconSize ?? this.iconSize,
    minimumSize: minimumSize ?? this.minimumSize,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentNavItemStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? iconColor,
    Color? indicatorColor,
    TextStyle? textStyle,
    BorderRadius? borderRadius,
    BorderRadius? indicatorRadius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? outerPadding,
    double? gap,
    double? indicatorGap,
    Size? indicatorSize,
    double? iconSize,
    Size? minimumSize,
    MouseCursor? mouseCursor,
  }) => FluentNavItemStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    iconColor: _all(iconColor),
    indicatorColor: _all(indicatorColor),
    textStyle: _all(textStyle),
    borderRadius: _all(borderRadius),
    indicatorRadius: _all(indicatorRadius),
    padding: _all(padding),
    outerPadding: _all(outerPadding),
    gap: _all(gap),
    indicatorGap: _all(indicatorGap),
    indicatorSize: _all(indicatorSize),
    iconSize: _all(iconSize),
    minimumSize: _all(minimumSize),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentNavItemStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.iconColor == iconColor &&
      other.indicatorColor == indicatorColor &&
      other.textStyle == textStyle &&
      other.borderRadius == borderRadius &&
      other.indicatorRadius == indicatorRadius &&
      other.padding == padding &&
      other.outerPadding == outerPadding &&
      other.gap == gap &&
      other.indicatorGap == indicatorGap &&
      other.indicatorSize == indicatorSize &&
      other.iconSize == iconSize &&
      other.minimumSize == minimumSize &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    iconColor,
    indicatorColor,
    textStyle,
    borderRadius,
    indicatorRadius,
    padding,
    outerPadding,
    gap,
    indicatorGap,
    indicatorSize,
    iconSize,
    minimumSize,
    mouseCursor,
  );
}
