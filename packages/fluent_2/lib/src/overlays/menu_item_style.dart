import 'package:flutter/widgets.dart';

/// The visual configuration of one row of a `FluentMenu`.
///
/// Same shape as `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed, selected and disabled values live
/// on the property rather than being branched on at build time. Every field is
/// nullable and means "inherit"; resolution order lowest to highest is the
/// type defaults derived from the theme, then the nearest `FluentMenuItemTheme`,
/// then the widget's own `itemStyle`.
@immutable
class FluentMenuItemStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentMenuItemStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.secondaryColor,
    this.iconColor,
    this.checkmarkColor,
    this.dividerColor,
    this.dividerThickness,
    this.borderRadius,
    this.textStyle,
    this.secondaryTextStyle,
    this.padding,
    this.labelPadding,
    this.gap,
    this.iconSize,
    this.checkmarkSize,
    this.minimumSize,
    this.mouseCursor,
  });

  /// Row fill.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Label colour. Also drives the trailing shortcut text.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Secondary line colour.
  final WidgetStateProperty<Color?>? secondaryColor;

  /// Leading icon colour. Brand on hover and press, unlike the label's ramp.
  ///
  /// The submenu chevron is not on this ramp — it follows [foregroundColor],
  /// which is what upstream's uncoloured `submenuIndicator` slot inherits.
  final WidgetStateProperty<Color?>? iconColor;

  /// Checkmark colour. A brand-compound ramp, not the label's.
  final WidgetStateProperty<Color?>? checkmarkColor;

  /// Rule colour on a `FluentMenuItem.divider` row.
  final WidgetStateProperty<Color?>? dividerColor;

  /// Rule thickness on a `FluentMenuItem.divider` row.
  final WidgetStateProperty<double?>? dividerThickness;

  /// Corner radius.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Label text style. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Secondary line text style. Its colour is overridden by [secondaryColor].
  final WidgetStateProperty<TextStyle?>? secondaryTextStyle;

  /// Padding inside the row.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Extra inset around the label column, inside [padding].
  final WidgetStateProperty<EdgeInsetsGeometry?>? labelPadding;

  /// Space between the row's slots.
  final WidgetStateProperty<double?>? gap;

  /// Leading icon and submenu chevron edge length.
  final WidgetStateProperty<double?>? iconSize;

  /// Checkmark edge length.
  final WidgetStateProperty<double?>? checkmarkSize;

  /// Minimum row size.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Cursor while hovering.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour.
  FluentMenuItemStyle merge(FluentMenuItemStyle? other) {
    if (other == null) return this;
    return FluentMenuItemStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      secondaryColor: other.secondaryColor ?? secondaryColor,
      iconColor: other.iconColor ?? iconColor,
      checkmarkColor: other.checkmarkColor ?? checkmarkColor,
      dividerColor: other.dividerColor ?? dividerColor,
      dividerThickness: other.dividerThickness ?? dividerThickness,
      borderRadius: other.borderRadius ?? borderRadius,
      textStyle: other.textStyle ?? textStyle,
      secondaryTextStyle: other.secondaryTextStyle ?? secondaryTextStyle,
      padding: other.padding ?? padding,
      labelPadding: other.labelPadding ?? labelPadding,
      gap: other.gap ?? gap,
      iconSize: other.iconSize ?? iconSize,
      checkmarkSize: other.checkmarkSize ?? checkmarkSize,
      minimumSize: other.minimumSize ?? minimumSize,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentMenuItemStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? secondaryColor,
    WidgetStateProperty<Color?>? iconColor,
    WidgetStateProperty<Color?>? checkmarkColor,
    WidgetStateProperty<Color?>? dividerColor,
    WidgetStateProperty<double?>? dividerThickness,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<TextStyle?>? secondaryTextStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<EdgeInsetsGeometry?>? labelPadding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<double?>? checkmarkSize,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentMenuItemStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    secondaryColor: secondaryColor ?? this.secondaryColor,
    iconColor: iconColor ?? this.iconColor,
    checkmarkColor: checkmarkColor ?? this.checkmarkColor,
    dividerColor: dividerColor ?? this.dividerColor,
    dividerThickness: dividerThickness ?? this.dividerThickness,
    borderRadius: borderRadius ?? this.borderRadius,
    textStyle: textStyle ?? this.textStyle,
    secondaryTextStyle: secondaryTextStyle ?? this.secondaryTextStyle,
    padding: padding ?? this.padding,
    labelPadding: labelPadding ?? this.labelPadding,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    checkmarkSize: checkmarkSize ?? this.checkmarkSize,
    minimumSize: minimumSize ?? this.minimumSize,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  static FluentMenuItemStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? secondaryColor,
    Color? iconColor,
    Color? checkmarkColor,
    Color? dividerColor,
    double? dividerThickness,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
    TextStyle? secondaryTextStyle,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? labelPadding,
    double? gap,
    double? iconSize,
    double? checkmarkSize,
    Size? minimumSize,
    MouseCursor? mouseCursor,
  }) => FluentMenuItemStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    secondaryColor: _all(secondaryColor),
    iconColor: _all(iconColor),
    checkmarkColor: _all(checkmarkColor),
    dividerColor: _all(dividerColor),
    dividerThickness: _all(dividerThickness),
    borderRadius: _all(borderRadius),
    textStyle: _all(textStyle),
    secondaryTextStyle: _all(secondaryTextStyle),
    padding: _all(padding),
    labelPadding: _all(labelPadding),
    gap: _all(gap),
    iconSize: _all(iconSize),
    checkmarkSize: _all(checkmarkSize),
    minimumSize: _all(minimumSize),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentMenuItemStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.secondaryColor == secondaryColor &&
      other.iconColor == iconColor &&
      other.checkmarkColor == checkmarkColor &&
      other.dividerColor == dividerColor &&
      other.dividerThickness == dividerThickness &&
      other.borderRadius == borderRadius &&
      other.textStyle == textStyle &&
      other.secondaryTextStyle == secondaryTextStyle &&
      other.padding == padding &&
      other.labelPadding == labelPadding &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.checkmarkSize == checkmarkSize &&
      other.minimumSize == minimumSize &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    backgroundColor,
    foregroundColor,
    secondaryColor,
    iconColor,
    checkmarkColor,
    dividerColor,
    dividerThickness,
    borderRadius,
    textStyle,
    secondaryTextStyle,
    padding,
    labelPadding,
    gap,
    iconSize,
    checkmarkSize,
    minimumSize,
    mouseCursor,
  ]);
}
