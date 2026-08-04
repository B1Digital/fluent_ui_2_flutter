import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentTag` or a `FluentInteractionTag`.
///
/// One style type covers both components on purpose: an interaction tag *is* a
/// tag with a pressable surface and an optional dismiss half, and the Figma
/// `Tag` and `Interaction tag` sets share every axis, every geometry number and
/// most of their token table. A second struct would be the same fifteen fields
/// with a different name.
///
/// Shaped like Material's `ButtonStyle` — every visual property is a
/// [WidgetStateProperty], so hover, pressed and disabled values live on the
/// property rather than being branched on at build time.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance/size/selected defaults derived from the theme
/// 2. the nearest `FluentTagTheme` or `FluentInteractionTagTheme`
/// 3. the widget's own `style`
@immutable
class FluentTagStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentTagStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.dismissForegroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.dividerColor,
    this.dismissSize,
    this.textStyle,
    this.secondaryTextStyle,
    this.padding,
    this.gap,
    this.iconSize,
    this.minimumSize,
    this.mouseCursor,
  });

  /// Surface fill. Drives the dismiss half too — Figma paints both from the
  /// same ramp, each resolved against its own interaction states.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Label and media colour.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Dismiss glyph colour.
  ///
  /// A separate ramp from [foregroundColor] rather than a duplicate of it: the
  /// dismiss glyph takes *brand* colour on hover and press
  /// (`neutralForeground2BrandHover`), which is what marks it as the
  /// interactive part of an otherwise inert tag.
  final WidgetStateProperty<Color?>? dismissForegroundColor;

  /// Border colour. Null and transparent are different: Fluent's
  /// `transparentStrokeInteractive` becomes opaque in high contrast.
  final WidgetStateProperty<Color?>? borderColor;

  /// Border width. Zero means no border, which is not the same as a transparent
  /// one — a zero-width border cannot become visible in high contrast.
  final WidgetStateProperty<double?>? borderWidth;

  /// Corner radius of the whole tag. The two halves of a dismissible
  /// interaction tag each take the half of it that faces outward.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// The rule between the primary half and the dismiss half.
  ///
  /// Drawn as the primary half's right border, which is where Figma puts it;
  /// React draws the same pixel as the secondary half's left border.
  final WidgetStateProperty<Color?>? dividerColor;

  /// Fixed size of the dismiss half. Null on a non-dismissible tag.
  final WidgetStateProperty<Size?>? dismissSize;

  /// Primary label text style. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Second-line text style, for the two-line medium layout.
  final WidgetStateProperty<TextStyle?>? secondaryTextStyle;

  /// Padding inside the border.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Space between media, label and dismiss glyph.
  final WidgetStateProperty<double?>? gap;

  /// Media and dismiss glyph edge length.
  final WidgetStateProperty<double?>? iconSize;

  /// Minimum tap target.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Cursor while hovering.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour.
  FluentTagStyle merge(FluentTagStyle? other) {
    if (other == null) return this;
    return FluentTagStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      dismissForegroundColor:
          other.dismissForegroundColor ?? dismissForegroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      dividerColor: other.dividerColor ?? dividerColor,
      dismissSize: other.dismissSize ?? dismissSize,
      textStyle: other.textStyle ?? textStyle,
      secondaryTextStyle: other.secondaryTextStyle ?? secondaryTextStyle,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
      iconSize: other.iconSize ?? iconSize,
      minimumSize: other.minimumSize ?? minimumSize,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentTagStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? dismissForegroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<Color?>? dividerColor,
    WidgetStateProperty<Size?>? dismissSize,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<TextStyle?>? secondaryTextStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentTagStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    dismissForegroundColor:
        dismissForegroundColor ?? this.dismissForegroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    dividerColor: dividerColor ?? this.dividerColor,
    dismissSize: dismissSize ?? this.dismissSize,
    textStyle: textStyle ?? this.textStyle,
    secondaryTextStyle: secondaryTextStyle ?? this.secondaryTextStyle,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    minimumSize: minimumSize ?? this.minimumSize,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentTagStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? dismissForegroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    Color? dividerColor,
    Size? dismissSize,
    TextStyle? textStyle,
    TextStyle? secondaryTextStyle,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? iconSize,
    Size? minimumSize,
    MouseCursor? mouseCursor,
  }) => FluentTagStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    dismissForegroundColor: _all(dismissForegroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    dividerColor: _all(dividerColor),
    dismissSize: _all(dismissSize),
    textStyle: _all(textStyle),
    secondaryTextStyle: _all(secondaryTextStyle),
    padding: _all(padding),
    gap: _all(gap),
    iconSize: _all(iconSize),
    minimumSize: _all(minimumSize),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentTagStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.dismissForegroundColor == dismissForegroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.dividerColor == dividerColor &&
      other.dismissSize == dismissSize &&
      other.textStyle == textStyle &&
      other.secondaryTextStyle == secondaryTextStyle &&
      other.padding == padding &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.minimumSize == minimumSize &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    dismissForegroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    dividerColor,
    dismissSize,
    textStyle,
    secondaryTextStyle,
    padding,
    gap,
    iconSize,
    minimumSize,
    mouseCursor,
  );
}
