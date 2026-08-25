import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentSwatch`.
///
/// Same shape as `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed, selected and disabled values live
/// on the property rather than being branched on at build time.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the kind/size/shape defaults derived from the theme
/// 2. the nearest `FluentSwatchTheme` — which is how `FluentSwatchPicker`
///    pushes one size and shape onto every swatch inside it
/// 3. the widget's own `style`
///
/// ## Two borders, not one
///
/// A swatch draws its selection ring *inside* its own box, as upstream does
/// with stacked `inset` box-shadows. [borderColor] is the outer band and
/// [innerBorderColor] the one nested inside it — upstream's second shadow, a
/// `colorStrokeFocus1` hairline that separates the brand ring from the swatch
/// colour. Only the selected states have one; hover and press draw a single
/// band, which is all the Figma file paints.
@immutable
class FluentSwatchStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentSwatchStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.innerBorderColor,
    this.innerBorderWidth,
    this.borderRadius,
    this.size,
    this.iconSize,
    this.iconColor,
    this.markColor,
    this.mouseCursor,
  });

  /// The swatch surface — the colour being offered, or Fluent's transparent
  /// token for the image, empty and transparent kinds.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Outer border band. Never `Colors.transparent`: Fluent's
  /// `transparentStroke` becomes opaque in high contrast, which is the only
  /// thing outlining a dark swatch on a dark canvas there.
  final WidgetStateProperty<Color?>? borderColor;

  /// Outer border width. Zero means no border, which is not the same as a
  /// transparent one.
  final WidgetStateProperty<double?>? borderWidth;

  /// Inner border band, drawn immediately inside [borderColor]. Null in every
  /// state but selected.
  final WidgetStateProperty<Color?>? innerBorderColor;

  /// Inner border width. Zero suppresses the band entirely.
  final WidgetStateProperty<double?>? innerBorderWidth;

  /// Corner radius. Driven by the Figma `Shape` collection, whose
  /// `Swatch/Default` entry the component set pins to `Corner radius/None`.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// The swatch's fixed square footprint — 20, 24, 28 or 32.
  final WidgetStateProperty<Size?>? size;

  /// Edge length of the icon slot and of the disabled mark.
  final WidgetStateProperty<double?>? iconSize;

  /// Colour of the icon slot and of the disabled mark.
  final WidgetStateProperty<Color?>? iconColor;

  /// Colour of the diagonal bar drawn across a transparent swatch.
  final WidgetStateProperty<Color?>? markColor;

  /// Cursor while hovering.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour.
  FluentSwatchStyle merge(FluentSwatchStyle? other) {
    if (other == null) return this;
    return FluentSwatchStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      innerBorderColor: other.innerBorderColor ?? innerBorderColor,
      innerBorderWidth: other.innerBorderWidth ?? innerBorderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      size: other.size ?? size,
      iconSize: other.iconSize ?? iconSize,
      iconColor: other.iconColor ?? iconColor,
      markColor: other.markColor ?? markColor,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentSwatchStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<Color?>? innerBorderColor,
    WidgetStateProperty<double?>? innerBorderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<Size?>? size,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<Color?>? iconColor,
    WidgetStateProperty<Color?>? markColor,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentSwatchStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    innerBorderColor: innerBorderColor ?? this.innerBorderColor,
    innerBorderWidth: innerBorderWidth ?? this.innerBorderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    size: size ?? this.size,
    iconSize: iconSize ?? this.iconSize,
    iconColor: iconColor ?? this.iconColor,
    markColor: markColor ?? this.markColor,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  static FluentSwatchStyle from({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    Color? innerBorderColor,
    double? innerBorderWidth,
    BorderRadius? borderRadius,
    Size? size,
    double? iconSize,
    Color? iconColor,
    Color? markColor,
    MouseCursor? mouseCursor,
  }) => FluentSwatchStyle(
    backgroundColor: _all(backgroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    innerBorderColor: _all(innerBorderColor),
    innerBorderWidth: _all(innerBorderWidth),
    borderRadius: _all(borderRadius),
    size: _all(size),
    iconSize: _all(iconSize),
    iconColor: _all(iconColor),
    markColor: _all(markColor),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentSwatchStyle &&
      other.backgroundColor == backgroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.innerBorderColor == innerBorderColor &&
      other.innerBorderWidth == innerBorderWidth &&
      other.borderRadius == borderRadius &&
      other.size == size &&
      other.iconSize == iconSize &&
      other.iconColor == iconColor &&
      other.markColor == markColor &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    innerBorderColor,
    innerBorderWidth,
    borderRadius,
    size,
    iconSize,
    iconColor,
    markColor,
    mouseCursor,
  );
}
