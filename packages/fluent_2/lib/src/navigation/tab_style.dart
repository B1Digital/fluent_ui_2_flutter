import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentTab`.
///
/// Shaped like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed, selected and disabled values live
/// on the property rather than being branched on at build time.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the orientation/appearance/size defaults derived from the theme
/// 2. the nearest `FluentTabTheme`
/// 3. the `FluentTabList`'s own `style`
/// 4. the tab's own `style`
///
/// ## The selection indicator
///
/// [indicatorColor], [indicatorThickness], [indicatorInset] and
/// [indicatorRadius] describe the bar Figma calls `Selector` and upstream draws
/// as the tab's `::after` pseudo-element. It runs along the bottom edge of a
/// horizontal tab and the leading edge of a vertical one, inset from both ends
/// by [indicatorInset]. A null [indicatorColor] — or a zero
/// [indicatorThickness] — means no bar at all, which is what an unselected tab
/// at rest and every pill-shaped tab paint.
@immutable
class FluentTabStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentTabStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.iconColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.focusRingRadius,
    this.textStyle,
    this.padding,
    this.gap,
    this.iconSize,
    this.minimumSize,
    this.indicatorColor,
    this.indicatorThickness,
    this.indicatorInset,
    this.indicatorRadius,
    this.mouseCursor,
  });

  /// Surface fill.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Label colour.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Icon colour.
  ///
  /// Separate from [foregroundColor] rather than derived from it: a selected
  /// tab's glyph takes `Brand/Foreground/Compound` while its label takes
  /// `Neutral/Foreground/1`, so the two genuinely differ.
  final WidgetStateProperty<Color?>? iconColor;

  /// Border colour. Null and transparent are different: Fluent's
  /// `transparentStroke` becomes opaque in high contrast.
  final WidgetStateProperty<Color?>? borderColor;

  /// Border width. Zero means no border, which is not the same as a transparent
  /// one — a zero-width border cannot become visible in high contrast.
  final WidgetStateProperty<double?>? borderWidth;

  /// Corner radius of the tab surface.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Corner radius of the keyboard focus ring.
  ///
  /// Not [borderRadius]: Figma's `State=Focus` variants draw the ring on
  /// `Corner radius/Small` over a surface rounded at `Corner radius/Medium`.
  final WidgetStateProperty<BorderRadius?>? focusRingRadius;

  /// Label text style. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Padding inside the border.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Space between icon and label.
  final WidgetStateProperty<double?>? gap;

  /// Icon edge length.
  final WidgetStateProperty<double?>? iconSize;

  /// Minimum tap target.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Selection indicator colour, or null for no indicator.
  final WidgetStateProperty<Color?>? indicatorColor;

  /// Selection indicator thickness. Zero suppresses it.
  final WidgetStateProperty<double?>? indicatorThickness;

  /// How far the indicator is held back from each end of the tab.
  final WidgetStateProperty<double?>? indicatorInset;

  /// Selection indicator corner radius.
  final WidgetStateProperty<BorderRadius?>? indicatorRadius;

  /// Cursor while hovering.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only [indicatorColor]
  /// keeps every resolved surface colour.
  FluentTabStyle merge(FluentTabStyle? other) {
    if (other == null) return this;
    return FluentTabStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      iconColor: other.iconColor ?? iconColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      focusRingRadius: other.focusRingRadius ?? focusRingRadius,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
      iconSize: other.iconSize ?? iconSize,
      minimumSize: other.minimumSize ?? minimumSize,
      indicatorColor: other.indicatorColor ?? indicatorColor,
      indicatorThickness: other.indicatorThickness ?? indicatorThickness,
      indicatorInset: other.indicatorInset ?? indicatorInset,
      indicatorRadius: other.indicatorRadius ?? indicatorRadius,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentTabStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? iconColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<BorderRadius?>? focusRingRadius,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<Color?>? indicatorColor,
    WidgetStateProperty<double?>? indicatorThickness,
    WidgetStateProperty<double?>? indicatorInset,
    WidgetStateProperty<BorderRadius?>? indicatorRadius,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentTabStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    iconColor: iconColor ?? this.iconColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    focusRingRadius: focusRingRadius ?? this.focusRingRadius,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    minimumSize: minimumSize ?? this.minimumSize,
    indicatorColor: indicatorColor ?? this.indicatorColor,
    indicatorThickness: indicatorThickness ?? this.indicatorThickness,
    indicatorInset: indicatorInset ?? this.indicatorInset,
    indicatorRadius: indicatorRadius ?? this.indicatorRadius,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// Use the constructor directly when a property genuinely differs per state.
  static FluentTabStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? iconColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    BorderRadius? focusRingRadius,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? iconSize,
    Size? minimumSize,
    Color? indicatorColor,
    double? indicatorThickness,
    double? indicatorInset,
    BorderRadius? indicatorRadius,
    MouseCursor? mouseCursor,
  }) => FluentTabStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    iconColor: _all(iconColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    focusRingRadius: _all(focusRingRadius),
    textStyle: _all(textStyle),
    padding: _all(padding),
    gap: _all(gap),
    iconSize: _all(iconSize),
    minimumSize: _all(minimumSize),
    indicatorColor: _all(indicatorColor),
    indicatorThickness: _all(indicatorThickness),
    indicatorInset: _all(indicatorInset),
    indicatorRadius: _all(indicatorRadius),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentTabStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.iconColor == iconColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.focusRingRadius == focusRingRadius &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.minimumSize == minimumSize &&
      other.indicatorColor == indicatorColor &&
      other.indicatorThickness == indicatorThickness &&
      other.indicatorInset == indicatorInset &&
      other.indicatorRadius == indicatorRadius &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    iconColor,
    borderColor,
    borderWidth,
    borderRadius,
    focusRingRadius,
    textStyle,
    padding,
    gap,
    iconSize,
    minimumSize,
    indicatorColor,
    indicatorThickness,
    indicatorInset,
    Object.hash(indicatorRadius, mouseCursor),
  );
}
