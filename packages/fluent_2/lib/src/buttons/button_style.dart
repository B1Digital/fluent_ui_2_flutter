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
    this.iconColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.textStyle,
    this.padding,
    this.gap,
    this.iconSize,
    this.menuIconSize,
    this.minimumSize,
    this.mouseCursor,
    this.focusRingInsets,
    this.focusRingInnerColor,
    this.shadow,
    this.animationDuration,
  });

  /// Surface fill.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Label colour, and the icon's unless [iconColor] says otherwise.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Icon colour, or null for the icon to follow [foregroundColor].
  ///
  /// Separate because upstream's subtle button recolours only its icon on
  /// hover and press — brand, while the label stays neutral.
  final WidgetStateProperty<Color?>? iconColor;

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

  /// Edge length of the menu icon after the label, which upstream sizes apart
  /// from the icon: 12, or 16 at large, beside a 20 or 24 icon.
  final WidgetStateProperty<double?>? menuIconSize;

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

  /// How long the fill, border and label take to reach a new state's colours.
  ///
  /// Null is upstream's Button transition, 100ms. [Duration.zero] lands them
  /// on the frame the state changes, for a control built on a button whose
  /// upstream counterpart declares no transition — the carousel's step is a
  /// `CarouselNavButton`, `transition: all` at 0s.
  final Duration? animationDuration;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour. This is what makes a partial override useful.
  FluentButtonStyle merge(FluentButtonStyle? other) {
    if (other == null) return this;
    return FluentButtonStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      iconColor: other.iconColor ?? iconColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
      iconSize: other.iconSize ?? iconSize,
      menuIconSize: other.menuIconSize ?? menuIconSize,
      minimumSize: other.minimumSize ?? minimumSize,
      mouseCursor: other.mouseCursor ?? mouseCursor,
      focusRingInsets: other.focusRingInsets ?? focusRingInsets,
      focusRingInnerColor: other.focusRingInnerColor ?? focusRingInnerColor,
      shadow: other.shadow ?? shadow,
      animationDuration: other.animationDuration ?? animationDuration,
    );
  }

  /// This style with the given properties replaced.
  FluentButtonStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? iconColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<double?>? menuIconSize,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    WidgetStateProperty<EdgeInsetsGeometry?>? focusRingInsets,
    WidgetStateProperty<Color?>? focusRingInnerColor,
    WidgetStateProperty<List<BoxShadow>?>? shadow,
    Duration? animationDuration,
  }) => FluentButtonStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    iconColor: iconColor ?? this.iconColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    menuIconSize: menuIconSize ?? this.menuIconSize,
    minimumSize: minimumSize ?? this.minimumSize,
    mouseCursor: mouseCursor ?? this.mouseCursor,
    focusRingInsets: focusRingInsets ?? this.focusRingInsets,
    focusRingInnerColor: focusRingInnerColor ?? this.focusRingInnerColor,
    shadow: shadow ?? this.shadow,
    animationDuration: animationDuration ?? this.animationDuration,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentButtonStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? iconColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? iconSize,
    double? menuIconSize,
    Size? minimumSize,
    MouseCursor? mouseCursor,
    EdgeInsetsGeometry? focusRingInsets,
    Color? focusRingInnerColor,
    List<BoxShadow>? shadow,
    Duration? animationDuration,
  }) => FluentButtonStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    iconColor: _all(iconColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    textStyle: _all(textStyle),
    padding: _all(padding),
    gap: _all(gap),
    iconSize: _all(iconSize),
    menuIconSize: _all(menuIconSize),
    minimumSize: _all(minimumSize),
    mouseCursor: _all(mouseCursor),
    focusRingInsets: _all(focusRingInsets),
    focusRingInnerColor: _all(focusRingInnerColor),
    shadow: _all(shadow),
    animationDuration: animationDuration,
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentButtonStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.iconColor == iconColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.menuIconSize == menuIconSize &&
      other.minimumSize == minimumSize &&
      other.mouseCursor == mouseCursor &&
      other.focusRingInsets == focusRingInsets &&
      other.focusRingInnerColor == focusRingInnerColor &&
      other.shadow == shadow &&
      other.animationDuration == animationDuration;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    iconColor,
    borderColor,
    borderWidth,
    borderRadius,
    textStyle,
    padding,
    gap,
    iconSize,
    menuIconSize,
    minimumSize,
    mouseCursor,
    focusRingInsets,
    focusRingInnerColor,
    shadow,
    animationDuration,
  );
}
