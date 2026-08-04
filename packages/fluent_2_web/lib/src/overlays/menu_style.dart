import 'package:flutter/widgets.dart';

/// The visual configuration of the surface a `FluentMenu` paints.
///
/// Shaped like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], every field is nullable and means "inherit", and the
/// resolution order lowest to highest is
///
/// 1. the defaults derived from the theme
/// 2. the nearest `FluentMenuTheme`
/// 3. the widget's own `style`
///
/// A menu surface has no interaction states of its own — it is shown *because*
/// something else was activated — so in practice every property here resolves
/// to one value. It is still a [WidgetStateProperty] so that an override reads
/// the same as every other style in the package.
@immutable
class FluentMenuStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentMenuStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.gap,
    this.minWidth,
    this.maxWidth,
    this.maxHeight,
    this.offset,
    this.shadow,
  });

  /// Surface fill.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Border colour. Null and transparent are different: Fluent's
  /// `transparentStroke` becomes opaque in high contrast, and on a menu it is
  /// the only thing separating the surface from the page there.
  final WidgetStateProperty<Color?>? borderColor;

  /// Border width. Zero means no border, which is not the same as a transparent
  /// one — a zero-width border cannot become visible in high contrast.
  final WidgetStateProperty<double?>? borderWidth;

  /// Corner radius.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Padding between the border and the rows.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Vertical space between rows.
  final WidgetStateProperty<double?>? gap;

  /// The surface's minimum width.
  ///
  /// `useMenuPopoverStyles.styles.ts` states `minWidth: '138px'`; a menu never
  /// renders narrower than that however short its rows are.
  final WidgetStateProperty<double?>? minWidth;

  /// Width at which the surface stops growing.
  final WidgetStateProperty<double?>? maxWidth;

  /// Height at which the rows start scrolling.
  final WidgetStateProperty<double?>? maxHeight;

  /// Distance between the anchor and the surface, along the opening direction.
  final WidgetStateProperty<double?>? offset;

  /// Elevation shadow.
  final WidgetStateProperty<List<BoxShadow>?>? shadow;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour.
  FluentMenuStyle merge(FluentMenuStyle? other) {
    if (other == null) return this;
    return FluentMenuStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
      minWidth: other.minWidth ?? minWidth,
      maxWidth: other.maxWidth ?? maxWidth,
      maxHeight: other.maxHeight ?? maxHeight,
      offset: other.offset ?? offset,
      shadow: other.shadow ?? shadow,
    );
  }

  /// This style with the given properties replaced.
  FluentMenuStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<double?>? minWidth,
    WidgetStateProperty<double?>? maxWidth,
    WidgetStateProperty<double?>? maxHeight,
    WidgetStateProperty<double?>? offset,
    WidgetStateProperty<List<BoxShadow>?>? shadow,
  }) => FluentMenuStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    minWidth: minWidth ?? this.minWidth,
    maxWidth: maxWidth ?? this.maxWidth,
    maxHeight: maxHeight ?? this.maxHeight,
    offset: offset ?? this.offset,
    shadow: shadow ?? this.shadow,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`.
  static FluentMenuStyle from({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? minWidth,
    double? maxWidth,
    double? maxHeight,
    double? offset,
    List<BoxShadow>? shadow,
  }) => FluentMenuStyle(
    backgroundColor: _all(backgroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    padding: _all(padding),
    gap: _all(gap),
    minWidth: _all(minWidth),
    maxWidth: _all(maxWidth),
    maxHeight: _all(maxHeight),
    offset: _all(offset),
    shadow: _all(shadow),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentMenuStyle &&
      other.backgroundColor == backgroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.padding == padding &&
      other.gap == gap &&
      other.minWidth == minWidth &&
      other.maxWidth == maxWidth &&
      other.maxHeight == maxHeight &&
      other.offset == offset &&
      other.shadow == shadow;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    padding,
    gap,
    minWidth,
    maxWidth,
    maxHeight,
    offset,
    shadow,
  );
}
