import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentTooltip`.
///
/// Deliberately shaped like `FluentButtonStyle`, and through it like Material's
/// `ButtonStyle`: every visual property is a [WidgetStateProperty], so a
/// component that does have hover, pressed, selected and disabled values keeps
/// them on the property rather than branching at build time. A tooltip surface
/// is never itself hovered or pressed — it resolves against an empty state set —
/// but keeping the shape identical is what lets a consumer move between the two
/// styles without relearning either.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance defaults derived from the theme
/// 2. the nearest `FluentTooltipTheme`
/// 3. the widget's own `style`
///
/// The consumer's own style therefore wins, matching upstream's rule that
/// `props.className` is passed last to `mergeClasses`.
@immutable
class FluentTooltipStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentTooltipStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.textStyle,
    this.padding,
    this.maxWidth,
    this.arrowSize,
    this.offset,
    this.shadow,
  });

  /// Surface fill. The arrow takes the same value, as it does in Figma.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Content colour.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Border colour. Null and transparent are different: Fluent's
  /// `transparentStroke` becomes opaque in high contrast.
  final WidgetStateProperty<Color?>? borderColor;

  /// Border width. Zero means no border, which is not the same as a transparent
  /// one — a zero-width border cannot become visible in high contrast.
  final WidgetStateProperty<double?>? borderWidth;

  /// Corner radius.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Content text style. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Padding inside the border.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Width at which the content wraps. The surface hugs anything narrower.
  final WidgetStateProperty<double?>? maxWidth;

  /// Arrow base and height, in the orientation Figma draws it — 16 wide by 8
  /// tall for a tooltip above or below its target, transposed for one beside it.
  final WidgetStateProperty<Size?>? arrowSize;

  /// Extra separation between the target and the surface.
  ///
  /// Only meaningful without an arrow: an arrow already occupies the gap, so the
  /// default resolves to zero whenever one is drawn.
  final WidgetStateProperty<double?>? offset;

  /// Elevation shadow cast by the surface.
  final WidgetStateProperty<List<BoxShadow>?>? shadow;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour. This is what makes a partial override useful.
  FluentTooltipStyle merge(FluentTooltipStyle? other) {
    if (other == null) return this;
    return FluentTooltipStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      maxWidth: other.maxWidth ?? maxWidth,
      arrowSize: other.arrowSize ?? arrowSize,
      offset: other.offset ?? offset,
      shadow: other.shadow ?? shadow,
    );
  }

  /// This style with the given properties replaced.
  FluentTooltipStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? maxWidth,
    WidgetStateProperty<Size?>? arrowSize,
    WidgetStateProperty<double?>? offset,
    WidgetStateProperty<List<BoxShadow>?>? shadow,
  }) => FluentTooltipStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    maxWidth: maxWidth ?? this.maxWidth,
    arrowSize: arrowSize ?? this.arrowSize,
    offset: offset ?? this.offset,
    shadow: shadow ?? this.shadow,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentTooltipStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    double? maxWidth,
    Size? arrowSize,
    double? offset,
    List<BoxShadow>? shadow,
  }) => FluentTooltipStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    textStyle: _all(textStyle),
    padding: _all(padding),
    maxWidth: _all(maxWidth),
    arrowSize: _all(arrowSize),
    offset: _all(offset),
    shadow: _all(shadow),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentTooltipStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.maxWidth == maxWidth &&
      other.arrowSize == arrowSize &&
      other.offset == offset &&
      other.shadow == shadow;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    textStyle,
    padding,
    maxWidth,
    arrowSize,
    offset,
    shadow,
  );
}
