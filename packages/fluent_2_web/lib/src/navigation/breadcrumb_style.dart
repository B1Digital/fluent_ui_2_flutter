import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentBreadcrumb` and its crumbs.
///
/// Same shape as `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed and disabled values live on the
/// property rather than being branched on at build time.
///
/// One struct covers the trail, the crumbs and the overflow popup, the way
/// `FluentDropdownStyle` covers a trigger and its listbox. That is not a
/// shortcut — the Figma `Breadcrumb` frame (node `9077:5932`) paints nothing at
/// all: no fill, no stroke, no padding, and `itemSpacing` bound to
/// `Spacing/Horizontal/None`. Every number in the design file lives on the
/// `.Breadcrumb Item` set, so the crumb *is* this component's styling surface.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the size defaults derived from the theme
/// 2. the nearest `FluentBreadcrumbTheme`
/// 3. the widget's own `style`
@immutable
class FluentBreadcrumbStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentBreadcrumbStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.iconColor,
    this.separatorColor,
    this.borderRadius,
    this.textStyle,
    this.padding,
    this.gap,
    this.iconSize,
    this.separatorSize,
    this.minimumSize,
    this.mouseCursor,
    this.surfaceColor,
    this.surfaceBorderColor,
    this.surfaceBorderWidth,
    this.surfaceRadius,
    this.surfacePadding,
    this.surfaceGap,
    this.surfaceShadow,
    this.surfaceMaxHeight,
    this.surfaceOffset,
  });

  /// The crumb's own surface fill.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Label colour.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Leading icon colour.
  ///
  /// Deliberately **not** [foregroundColor]. Figma takes the icon to
  /// `Neutral/Foreground/2/Brand/Hover` on hover while leaving the label on
  /// `Neutral/Foreground/2/Rest`, so a breadcrumb crumb needs two independent
  /// ramps where a button needs one.
  final WidgetStateProperty<Color?>? iconColor;

  /// Separator chevron colour.
  final WidgetStateProperty<Color?>? separatorColor;

  /// Corner radius of the crumb's surface.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Label text style. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Inset between the crumb's surface edge and its content.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Space between the leading icon and the label.
  final WidgetStateProperty<double?>? gap;

  /// Leading icon edge length.
  final WidgetStateProperty<double?>? iconSize;

  /// Separator chevron edge length.
  final WidgetStateProperty<double?>? separatorSize;

  /// Minimum crumb size. Its height is what holds the trail's row height.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Cursor while hovering an interactive crumb.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// Overflow popup surface fill.
  final WidgetStateProperty<Color?>? surfaceColor;

  /// Overflow popup border colour. Null and transparent are different: Fluent's
  /// `transparentStroke` becomes opaque in high contrast.
  final WidgetStateProperty<Color?>? surfaceBorderColor;

  /// Overflow popup border width.
  final WidgetStateProperty<double?>? surfaceBorderWidth;

  /// Overflow popup corner radius.
  final WidgetStateProperty<BorderRadius?>? surfaceRadius;

  /// Overflow popup inset.
  final WidgetStateProperty<EdgeInsetsGeometry?>? surfacePadding;

  /// Space between overflow popup rows.
  final WidgetStateProperty<double?>? surfaceGap;

  /// Overflow popup elevation.
  final WidgetStateProperty<List<BoxShadow>?>? surfaceShadow;

  /// Height at which the overflow popup starts scrolling.
  final WidgetStateProperty<double?>? surfaceMaxHeight;

  /// Vertical distance between the overflow trigger and its popup.
  final WidgetStateProperty<double?>? surfaceOffset;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only [borderRadius]
  /// keeps every resolved colour.
  FluentBreadcrumbStyle merge(FluentBreadcrumbStyle? other) {
    if (other == null) return this;
    return FluentBreadcrumbStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      iconColor: other.iconColor ?? iconColor,
      separatorColor: other.separatorColor ?? separatorColor,
      borderRadius: other.borderRadius ?? borderRadius,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
      iconSize: other.iconSize ?? iconSize,
      separatorSize: other.separatorSize ?? separatorSize,
      minimumSize: other.minimumSize ?? minimumSize,
      mouseCursor: other.mouseCursor ?? mouseCursor,
      surfaceColor: other.surfaceColor ?? surfaceColor,
      surfaceBorderColor: other.surfaceBorderColor ?? surfaceBorderColor,
      surfaceBorderWidth: other.surfaceBorderWidth ?? surfaceBorderWidth,
      surfaceRadius: other.surfaceRadius ?? surfaceRadius,
      surfacePadding: other.surfacePadding ?? surfacePadding,
      surfaceGap: other.surfaceGap ?? surfaceGap,
      surfaceShadow: other.surfaceShadow ?? surfaceShadow,
      surfaceMaxHeight: other.surfaceMaxHeight ?? surfaceMaxHeight,
      surfaceOffset: other.surfaceOffset ?? surfaceOffset,
    );
  }

  /// This style with the given properties replaced.
  FluentBreadcrumbStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? iconColor,
    WidgetStateProperty<Color?>? separatorColor,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<double?>? separatorSize,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    WidgetStateProperty<Color?>? surfaceColor,
    WidgetStateProperty<Color?>? surfaceBorderColor,
    WidgetStateProperty<double?>? surfaceBorderWidth,
    WidgetStateProperty<BorderRadius?>? surfaceRadius,
    WidgetStateProperty<EdgeInsetsGeometry?>? surfacePadding,
    WidgetStateProperty<double?>? surfaceGap,
    WidgetStateProperty<List<BoxShadow>?>? surfaceShadow,
    WidgetStateProperty<double?>? surfaceMaxHeight,
    WidgetStateProperty<double?>? surfaceOffset,
  }) => FluentBreadcrumbStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    iconColor: iconColor ?? this.iconColor,
    separatorColor: separatorColor ?? this.separatorColor,
    borderRadius: borderRadius ?? this.borderRadius,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    separatorSize: separatorSize ?? this.separatorSize,
    minimumSize: minimumSize ?? this.minimumSize,
    mouseCursor: mouseCursor ?? this.mouseCursor,
    surfaceColor: surfaceColor ?? this.surfaceColor,
    surfaceBorderColor: surfaceBorderColor ?? this.surfaceBorderColor,
    surfaceBorderWidth: surfaceBorderWidth ?? this.surfaceBorderWidth,
    surfaceRadius: surfaceRadius ?? this.surfaceRadius,
    surfacePadding: surfacePadding ?? this.surfacePadding,
    surfaceGap: surfaceGap ?? this.surfaceGap,
    surfaceShadow: surfaceShadow ?? this.surfaceShadow,
    surfaceMaxHeight: surfaceMaxHeight ?? this.surfaceMaxHeight,
    surfaceOffset: surfaceOffset ?? this.surfaceOffset,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentBreadcrumbStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? iconColor,
    Color? separatorColor,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? iconSize,
    double? separatorSize,
    Size? minimumSize,
    MouseCursor? mouseCursor,
    Color? surfaceColor,
    Color? surfaceBorderColor,
    double? surfaceBorderWidth,
    BorderRadius? surfaceRadius,
    EdgeInsetsGeometry? surfacePadding,
    double? surfaceGap,
    List<BoxShadow>? surfaceShadow,
    double? surfaceMaxHeight,
    double? surfaceOffset,
  }) => FluentBreadcrumbStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    iconColor: _all(iconColor),
    separatorColor: _all(separatorColor),
    borderRadius: _all(borderRadius),
    textStyle: _all(textStyle),
    padding: _all(padding),
    gap: _all(gap),
    iconSize: _all(iconSize),
    separatorSize: _all(separatorSize),
    minimumSize: _all(minimumSize),
    mouseCursor: _all(mouseCursor),
    surfaceColor: _all(surfaceColor),
    surfaceBorderColor: _all(surfaceBorderColor),
    surfaceBorderWidth: _all(surfaceBorderWidth),
    surfaceRadius: _all(surfaceRadius),
    surfacePadding: _all(surfacePadding),
    surfaceGap: _all(surfaceGap),
    surfaceShadow: _all(surfaceShadow),
    surfaceMaxHeight: _all(surfaceMaxHeight),
    surfaceOffset: _all(surfaceOffset),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentBreadcrumbStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.iconColor == iconColor &&
      other.separatorColor == separatorColor &&
      other.borderRadius == borderRadius &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.separatorSize == separatorSize &&
      other.minimumSize == minimumSize &&
      other.mouseCursor == mouseCursor &&
      other.surfaceColor == surfaceColor &&
      other.surfaceBorderColor == surfaceBorderColor &&
      other.surfaceBorderWidth == surfaceBorderWidth &&
      other.surfaceRadius == surfaceRadius &&
      other.surfacePadding == surfacePadding &&
      other.surfaceGap == surfaceGap &&
      other.surfaceShadow == surfaceShadow &&
      other.surfaceMaxHeight == surfaceMaxHeight &&
      other.surfaceOffset == surfaceOffset;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    backgroundColor,
    foregroundColor,
    iconColor,
    separatorColor,
    borderRadius,
    textStyle,
    padding,
    gap,
    iconSize,
    separatorSize,
    minimumSize,
    mouseCursor,
    surfaceColor,
    surfaceBorderColor,
    surfaceBorderWidth,
    surfaceRadius,
    surfacePadding,
    surfaceGap,
    surfaceShadow,
    surfaceMaxHeight,
    surfaceOffset,
  ]);
}
