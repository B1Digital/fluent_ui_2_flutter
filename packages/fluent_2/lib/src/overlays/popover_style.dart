import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentPopover`.
///
/// Deliberately shaped like `FluentTooltipStyle`, and through it like
/// `FluentButtonStyle` and Material's `ButtonStyle`: every visual property is a
/// [WidgetStateProperty]. A popover surface is never itself hovered or pressed —
/// it resolves against an empty state set — but keeping the shape identical is
/// what lets a consumer move between the styles without relearning either.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance and size defaults derived from the theme
/// 2. the nearest `FluentPopoverTheme`
/// 3. the widget's own `style`
///
/// The consumer's own style therefore wins, matching upstream's rule that
/// `props.className` is passed last to `mergeClasses`.
@immutable
class FluentPopoverStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentPopoverStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.textStyle,
    this.padding,
    this.arrowSize,
    this.arrowInset,
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

  /// Arrow base and height, in the orientation Figma draws it — 16 wide by 8
  /// tall for a popover above or below its anchor, transposed for one beside it.
  final WidgetStateProperty<Size?>? arrowSize;

  /// How far the arrow sits from the surface's leading or trailing edge when
  /// the popover is aligned to one end of its anchor rather than centred.
  ///
  /// Ignored by a centred popover, whose arrow is centred instead.
  final WidgetStateProperty<double?>? arrowInset;

  /// Extra separation between the anchor and the surface.
  ///
  /// Zero by default in both directions: an arrow already occupies the gap, and
  /// upstream leaves the positioning offset unset when there is no arrow.
  final WidgetStateProperty<double?>? offset;

  /// Elevation shadow cast by the surface.
  final WidgetStateProperty<List<BoxShadow>?>? shadow;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour. This is what makes a partial override useful.
  FluentPopoverStyle merge(FluentPopoverStyle? other) {
    if (other == null) return this;
    return FluentPopoverStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      arrowSize: other.arrowSize ?? arrowSize,
      arrowInset: other.arrowInset ?? arrowInset,
      offset: other.offset ?? offset,
      shadow: other.shadow ?? shadow,
    );
  }

  /// This style with the given properties replaced.
  FluentPopoverStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<Size?>? arrowSize,
    WidgetStateProperty<double?>? arrowInset,
    WidgetStateProperty<double?>? offset,
    WidgetStateProperty<List<BoxShadow>?>? shadow,
  }) => FluentPopoverStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    arrowSize: arrowSize ?? this.arrowSize,
    arrowInset: arrowInset ?? this.arrowInset,
    offset: offset ?? this.offset,
    shadow: shadow ?? this.shadow,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentPopoverStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    Size? arrowSize,
    double? arrowInset,
    double? offset,
    List<BoxShadow>? shadow,
  }) => FluentPopoverStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    textStyle: _all(textStyle),
    padding: _all(padding),
    arrowSize: _all(arrowSize),
    arrowInset: _all(arrowInset),
    offset: _all(offset),
    shadow: _all(shadow),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentPopoverStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.arrowSize == arrowSize &&
      other.arrowInset == arrowInset &&
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
    arrowSize,
    arrowInset,
    offset,
    shadow,
  );
}
