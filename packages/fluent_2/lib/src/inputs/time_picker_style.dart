import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentTimePicker` — faceplate *and* listbox.
///
/// Shaped like `FluentInputStyle`, because a time picker *is* an input with a
/// listbox hung off it: every visual property is a [WidgetStateProperty], so
/// hover, focus and disabled values live on the property rather than being
/// branched on at build time.
///
/// The faceplate fields are duplicated here rather than nested, matching
/// `FluentTagPickerStyle` — a caller overriding a picker's fill should not have
/// to know which of two structs owns it. Listbox fields are prefixed `surface`.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance/size defaults derived from the theme
/// 2. the nearest `FluentTimePickerTheme`
/// 3. the widget's own `style`
@immutable
class FluentTimePickerStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentTimePickerStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.underlineColor,
    this.underlineWidth,
    this.accentColor,
    this.accentWidth,
    this.foregroundColor,
    this.placeholderColor,
    this.textStyle,
    this.padding,
    this.minimumSize,
    this.mouseCursor,
    this.iconColor,
    this.iconSize,
    this.trailingGap,
    this.trailingPadding,
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

  /// Faceplate fill.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Faceplate border colour. Null and transparent differ: Fluent's
  /// `transparentStroke` turns opaque in high contrast.
  final WidgetStateProperty<Color?>? borderColor;

  /// Faceplate border width.
  final WidgetStateProperty<double?>? borderWidth;

  /// Faceplate corner radius.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// The 1px rule along the bottom edge at rest.
  ///
  /// Null means the appearance draws none, which is a different claim from a
  /// transparent one — the filled appearances genuinely have no rule.
  final WidgetStateProperty<Color?>? underlineColor;

  /// Thickness of the resting bottom rule.
  final WidgetStateProperty<double?>? underlineWidth;

  /// The brand rule that grows across the bottom edge while the picker is
  /// focused. Upstream's `::after`.
  final WidgetStateProperty<Color?>? accentColor;

  /// Height of the accent rule.
  final WidgetStateProperty<double?>? accentWidth;

  /// Colour of the entered or selected time.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Colour of the placeholder, a separate ramp rather than a dimmed
  /// [foregroundColor].
  final WidgetStateProperty<Color?>? placeholderColor;

  /// Value and placeholder type ramp. Its colour is overridden by
  /// [foregroundColor] and [placeholderColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Inset of the value text inside the faceplate.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Minimum faceplate size. Only the height is meaningful; a time picker takes
  /// its width from its parent.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Cursor over the faceplate.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// Tone of the expand chevron and the clear glyph.
  final WidgetStateProperty<Color?>? iconColor;

  /// Edge length of the expand chevron and the clear glyph.
  final WidgetStateProperty<double?>? iconSize;

  /// Space between the clear glyph and the expand chevron.
  final WidgetStateProperty<double?>? trailingGap;

  /// Inset around the trailing slot.
  final WidgetStateProperty<EdgeInsetsGeometry?>? trailingPadding;

  /// Listbox fill.
  final WidgetStateProperty<Color?>? surfaceColor;

  /// Listbox border colour.
  final WidgetStateProperty<Color?>? surfaceBorderColor;

  /// Listbox border width.
  final WidgetStateProperty<double?>? surfaceBorderWidth;

  /// Listbox corner radius.
  final WidgetStateProperty<BorderRadius?>? surfaceRadius;

  /// Inset between the listbox edge and its rows.
  final WidgetStateProperty<EdgeInsetsGeometry?>? surfacePadding;

  /// Space between listbox rows.
  final WidgetStateProperty<double?>? surfaceGap;

  /// Elevation cast by the listbox.
  final WidgetStateProperty<List<BoxShadow>?>? surfaceShadow;

  /// Tallest the listbox may grow before it scrolls.
  final WidgetStateProperty<double?>? surfaceMaxHeight;

  /// Gap between the faceplate and the listbox.
  final WidgetStateProperty<double?>? surfaceOffset;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding one value keeps every
  /// other resolved one.
  FluentTimePickerStyle merge(FluentTimePickerStyle? other) {
    if (other == null) return this;
    return FluentTimePickerStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      underlineColor: other.underlineColor ?? underlineColor,
      underlineWidth: other.underlineWidth ?? underlineWidth,
      accentColor: other.accentColor ?? accentColor,
      accentWidth: other.accentWidth ?? accentWidth,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      placeholderColor: other.placeholderColor ?? placeholderColor,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      minimumSize: other.minimumSize ?? minimumSize,
      mouseCursor: other.mouseCursor ?? mouseCursor,
      iconColor: other.iconColor ?? iconColor,
      iconSize: other.iconSize ?? iconSize,
      trailingGap: other.trailingGap ?? trailingGap,
      trailingPadding: other.trailingPadding ?? trailingPadding,
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
  FluentTimePickerStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<Color?>? underlineColor,
    WidgetStateProperty<double?>? underlineWidth,
    WidgetStateProperty<Color?>? accentColor,
    WidgetStateProperty<double?>? accentWidth,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? placeholderColor,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    WidgetStateProperty<Color?>? iconColor,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<double?>? trailingGap,
    WidgetStateProperty<EdgeInsetsGeometry?>? trailingPadding,
    WidgetStateProperty<Color?>? surfaceColor,
    WidgetStateProperty<Color?>? surfaceBorderColor,
    WidgetStateProperty<double?>? surfaceBorderWidth,
    WidgetStateProperty<BorderRadius?>? surfaceRadius,
    WidgetStateProperty<EdgeInsetsGeometry?>? surfacePadding,
    WidgetStateProperty<double?>? surfaceGap,
    WidgetStateProperty<List<BoxShadow>?>? surfaceShadow,
    WidgetStateProperty<double?>? surfaceMaxHeight,
    WidgetStateProperty<double?>? surfaceOffset,
  }) => FluentTimePickerStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    underlineColor: underlineColor ?? this.underlineColor,
    underlineWidth: underlineWidth ?? this.underlineWidth,
    accentColor: accentColor ?? this.accentColor,
    accentWidth: accentWidth ?? this.accentWidth,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    placeholderColor: placeholderColor ?? this.placeholderColor,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    minimumSize: minimumSize ?? this.minimumSize,
    mouseCursor: mouseCursor ?? this.mouseCursor,
    iconColor: iconColor ?? this.iconColor,
    iconSize: iconSize ?? this.iconSize,
    trailingGap: trailingGap ?? this.trailingGap,
    trailingPadding: trailingPadding ?? this.trailingPadding,
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
  static FluentTimePickerStyle from({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    Color? underlineColor,
    double? underlineWidth,
    Color? accentColor,
    double? accentWidth,
    Color? foregroundColor,
    Color? placeholderColor,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    Size? minimumSize,
    MouseCursor? mouseCursor,
    Color? iconColor,
    double? iconSize,
    double? trailingGap,
    EdgeInsetsGeometry? trailingPadding,
    Color? surfaceColor,
    Color? surfaceBorderColor,
    double? surfaceBorderWidth,
    BorderRadius? surfaceRadius,
    EdgeInsetsGeometry? surfacePadding,
    double? surfaceGap,
    List<BoxShadow>? surfaceShadow,
    double? surfaceMaxHeight,
    double? surfaceOffset,
  }) => FluentTimePickerStyle(
    backgroundColor: _all(backgroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    underlineColor: _all(underlineColor),
    underlineWidth: _all(underlineWidth),
    accentColor: _all(accentColor),
    accentWidth: _all(accentWidth),
    foregroundColor: _all(foregroundColor),
    placeholderColor: _all(placeholderColor),
    textStyle: _all(textStyle),
    padding: _all(padding),
    minimumSize: _all(minimumSize),
    mouseCursor: _all(mouseCursor),
    iconColor: _all(iconColor),
    iconSize: _all(iconSize),
    trailingGap: _all(trailingGap),
    trailingPadding: _all(trailingPadding),
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
      other is FluentTimePickerStyle &&
      other.backgroundColor == backgroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.underlineColor == underlineColor &&
      other.underlineWidth == underlineWidth &&
      other.accentColor == accentColor &&
      other.accentWidth == accentWidth &&
      other.foregroundColor == foregroundColor &&
      other.placeholderColor == placeholderColor &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.minimumSize == minimumSize &&
      other.mouseCursor == mouseCursor &&
      other.iconColor == iconColor &&
      other.iconSize == iconSize &&
      other.trailingGap == trailingGap &&
      other.trailingPadding == trailingPadding &&
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
    borderColor,
    borderWidth,
    borderRadius,
    underlineColor,
    underlineWidth,
    accentColor,
    accentWidth,
    foregroundColor,
    placeholderColor,
    textStyle,
    padding,
    minimumSize,
    mouseCursor,
    iconColor,
    iconSize,
    trailingGap,
    trailingPadding,
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
