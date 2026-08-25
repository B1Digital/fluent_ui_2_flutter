import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentToolbar` and of the
/// `FluentToolbarDivider`s inside it.
///
/// Shaped like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], every field is nullable and means "inherit", and
/// resolution runs lowest to highest precedence:
///
/// 1. the size/type defaults derived from the theme
/// 2. the nearest `FluentToolbarTheme`
/// 3. the widget's own `style`
///
/// A toolbar has no interaction states of its own — it is a container, not a
/// control — so every property here resolves the same value for every state.
/// They are still [WidgetStateProperty] so that a caller who wants, say, a
/// different surface while a child is focused can express it without a fork.
@immutable
class FluentToolbarStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentToolbarStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.gap,
    this.shadow,
    this.dividerWidth,
    this.dividerPadding,
  });

  /// Surface fill.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Border colour. Null and transparent are different: Fluent's
  /// `transparentStroke` becomes opaque in high contrast, which is the only
  /// thing that outlines a toolbar there.
  final WidgetStateProperty<Color?>? borderColor;

  /// Border width. Zero means no border, which is not the same as a transparent
  /// one — a zero-width border cannot become visible in high contrast.
  final WidgetStateProperty<double?>? borderWidth;

  /// Corner radius.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Padding inside the border.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Space between items. Zero in every Figma variant; toolbar items are
  /// self-padding and butt against each other.
  final WidgetStateProperty<double?>? gap;

  /// Elevation cast by the surface, or null for a flat one.
  final WidgetStateProperty<List<BoxShadow>?>? shadow;

  /// Total width of a `FluentToolbarDivider`'s slot, hairline included.
  final WidgetStateProperty<double?>? dividerWidth;

  /// Inset between the divider's rule and the top and bottom of the item row.
  final WidgetStateProperty<EdgeInsetsGeometry?>? dividerPadding;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour.
  FluentToolbarStyle merge(FluentToolbarStyle? other) {
    if (other == null) return this;
    return FluentToolbarStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
      shadow: other.shadow ?? shadow,
      dividerWidth: other.dividerWidth ?? dividerWidth,
      dividerPadding: other.dividerPadding ?? dividerPadding,
    );
  }

  /// This style with the given properties replaced.
  FluentToolbarStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<List<BoxShadow>?>? shadow,
    WidgetStateProperty<double?>? dividerWidth,
    WidgetStateProperty<EdgeInsetsGeometry?>? dividerPadding,
  }) => FluentToolbarStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    shadow: shadow ?? this.shadow,
    dividerWidth: dividerWidth ?? this.dividerWidth,
    dividerPadding: dividerPadding ?? this.dividerPadding,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`.
  static FluentToolbarStyle from({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    double? gap,
    List<BoxShadow>? shadow,
    double? dividerWidth,
    EdgeInsetsGeometry? dividerPadding,
  }) => FluentToolbarStyle(
    backgroundColor: _all(backgroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    padding: _all(padding),
    gap: _all(gap),
    shadow: _all(shadow),
    dividerWidth: _all(dividerWidth),
    dividerPadding: _all(dividerPadding),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentToolbarStyle &&
      other.backgroundColor == backgroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.padding == padding &&
      other.gap == gap &&
      other.shadow == shadow &&
      other.dividerWidth == dividerWidth &&
      other.dividerPadding == dividerPadding;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    padding,
    gap,
    shadow,
    dividerWidth,
    dividerPadding,
  );
}
