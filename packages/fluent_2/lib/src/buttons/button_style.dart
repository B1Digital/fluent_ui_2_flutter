import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentButton`.
///
/// Deliberately shaped like Material's `ButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed, selected and disabled values live
/// on the property rather than being branched on at build time. A Flutter
/// developer already knows how to read and override this.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance/size defaults derived from the theme
/// 2. the nearest `FluentButtonTheme`
/// 3. the widget's own `style`
///
/// The consumer's own style therefore wins, matching upstream's rule that
/// `props.className` is passed last to `mergeClasses`.
@immutable
class FluentButtonStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentButtonStyle({
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
    this.mouseCursor,
    this.focusRingInsets,
    this.focusRingInnerColor,
    this.shadow,
  });

  /// Surface fill.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Label and icon colour.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Border colour. Null and transparent are different: Fluent's
  /// `transparentStroke` becomes opaque in high contrast.
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

  /// Minimum tap target.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Cursor while hovering.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// How deep the keyboard focus ring reaches in from each edge.
  ///
  /// Upstream's ring is the button's border turned `strokeFocus2` plus a 1px
  /// inset shadow, so it is 2px wherever the button has a border and 1px where
  /// it has none — the split button's chevron half, at the seam.
  final WidgetStateProperty<EdgeInsetsGeometry?>? focusRingInsets;

  /// A second, 1px ring just inside the focus ring, or null for none.
  ///
  /// Primary's white `colorNeutralForegroundOnBrand` step, which upstream drops
  /// while the button is hovered.
  final WidgetStateProperty<Color?>? focusRingInnerColor;

  /// Drop shadow. Upstream gives a focused primary button `shadow2`.
  final WidgetStateProperty<List<BoxShadow>?>? shadow;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour. This is what makes a partial override useful.
  FluentButtonStyle merge(FluentButtonStyle? other) {
    if (other == null) return this;
    return FluentButtonStyle(
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
      mouseCursor: other.mouseCursor ?? mouseCursor,
      focusRingInsets: other.focusRingInsets ?? focusRingInsets,
      focusRingInnerColor: other.focusRingInnerColor ?? focusRingInnerColor,
      shadow: other.shadow ?? shadow,
    );
  }

  /// This style with the given properties replaced.
  FluentButtonStyle copyWith({
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
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    WidgetStateProperty<EdgeInsetsGeometry?>? focusRingInsets,
    WidgetStateProperty<Color?>? focusRingInnerColor,
    WidgetStateProperty<List<BoxShadow>?>? shadow,
  }) => FluentButtonStyle(
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
    mouseCursor: mouseCursor ?? this.mouseCursor,
    focusRingInsets: focusRingInsets ?? this.focusRingInsets,
    focusRingInnerColor: focusRingInnerColor ?? this.focusRingInnerColor,
    shadow: shadow ?? this.shadow,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentButtonStyle from({
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
    MouseCursor? mouseCursor,
    EdgeInsetsGeometry? focusRingInsets,
    Color? focusRingInnerColor,
    List<BoxShadow>? shadow,
  }) => FluentButtonStyle(
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
    mouseCursor: _all(mouseCursor),
    focusRingInsets: _all(focusRingInsets),
    focusRingInnerColor: _all(focusRingInnerColor),
    shadow: _all(shadow),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentButtonStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.minimumSize == minimumSize &&
      other.mouseCursor == mouseCursor &&
      other.focusRingInsets == focusRingInsets &&
      other.focusRingInnerColor == focusRingInnerColor &&
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
    gap,
    iconSize,
    minimumSize,
    mouseCursor,
    focusRingInsets,
    focusRingInnerColor,
    shadow,
  );
}
