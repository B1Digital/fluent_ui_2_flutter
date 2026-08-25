import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentDatePicker` — faceplate *and* popup.
///
/// Shaped like `FluentInputStyle`, because a date picker *is* an input with a
/// calendar hung off it: every visual property is a [WidgetStateProperty], so
/// hover, focus and disabled values live on the property rather than being
/// branched on at build time.
///
/// The faceplate fields are duplicated here rather than nested, matching
/// `FluentTagPickerStyle`. Popup fields are prefixed `surface`; the calendar
/// inside it is styled through `FluentCalendarTheme` or the widget's own
/// `calendarStyle`, not from here.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance/size defaults derived from the theme
/// 2. the nearest `FluentDatePickerTheme`
/// 3. the widget's own `style`
@immutable
class FluentDatePickerStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentDatePickerStyle({
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
    this.iconPadding,
    this.surfaceColor,
    this.surfaceBorderColor,
    this.surfaceBorderWidth,
    this.surfaceRadius,
    this.surfacePadding,
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
  /// transparent one.
  final WidgetStateProperty<Color?>? underlineColor;

  /// Thickness of the resting bottom rule.
  final WidgetStateProperty<double?>? underlineWidth;

  /// The brand rule that grows across the bottom edge while the picker is
  /// focused. Upstream's `::after`.
  final WidgetStateProperty<Color?>? accentColor;

  /// Height of the accent rule.
  final WidgetStateProperty<double?>? accentWidth;

  /// Colour of the formatted date.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Colour of the placeholder, a separate ramp rather than a dimmed
  /// [foregroundColor].
  final WidgetStateProperty<Color?>? placeholderColor;

  /// Value and placeholder type ramp. Its colour is overridden by
  /// [foregroundColor] and [placeholderColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Inset of the value text inside the faceplate.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Minimum faceplate size. Only the height is meaningful.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Cursor over the faceplate.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// Tone of the calendar glyph.
  final WidgetStateProperty<Color?>? iconColor;

  /// Edge length of the calendar glyph.
  final WidgetStateProperty<double?>? iconSize;

  /// Inset around the calendar glyph.
  final WidgetStateProperty<EdgeInsetsGeometry?>? iconPadding;

  /// Popup fill.
  final WidgetStateProperty<Color?>? surfaceColor;

  /// Popup border colour.
  final WidgetStateProperty<Color?>? surfaceBorderColor;

  /// Popup border width.
  final WidgetStateProperty<double?>? surfaceBorderWidth;

  /// Popup corner radius.
  final WidgetStateProperty<BorderRadius?>? surfaceRadius;

  /// Inset between the popup edge and the calendar.
  ///
  /// Zero by default: the calendar carries its own inset, and a second one here
  /// would double it.
  final WidgetStateProperty<EdgeInsetsGeometry?>? surfacePadding;

  /// Elevation cast by the popup.
  final WidgetStateProperty<List<BoxShadow>?>? surfaceShadow;

  /// Tallest the popup may grow.
  ///
  /// Unlike a listbox, a calendar's height is essentially fixed, and this is a
  /// real number rather than null precisely so the flip-above decision can be
  /// made in one pass instead of measuring and then jumping.
  final WidgetStateProperty<double?>? surfaceMaxHeight;

  /// Gap between the faceplate and the popup.
  final WidgetStateProperty<double?>? surfaceOffset;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding one value keeps every
  /// other resolved one.
  FluentDatePickerStyle merge(FluentDatePickerStyle? other) {
    if (other == null) return this;
    return FluentDatePickerStyle(
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
      iconPadding: other.iconPadding ?? iconPadding,
      surfaceColor: other.surfaceColor ?? surfaceColor,
      surfaceBorderColor: other.surfaceBorderColor ?? surfaceBorderColor,
      surfaceBorderWidth: other.surfaceBorderWidth ?? surfaceBorderWidth,
      surfaceRadius: other.surfaceRadius ?? surfaceRadius,
      surfacePadding: other.surfacePadding ?? surfacePadding,
      surfaceShadow: other.surfaceShadow ?? surfaceShadow,
      surfaceMaxHeight: other.surfaceMaxHeight ?? surfaceMaxHeight,
      surfaceOffset: other.surfaceOffset ?? surfaceOffset,
    );
  }

  /// This style with the given properties replaced.
  FluentDatePickerStyle copyWith({
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
    WidgetStateProperty<EdgeInsetsGeometry?>? iconPadding,
    WidgetStateProperty<Color?>? surfaceColor,
    WidgetStateProperty<Color?>? surfaceBorderColor,
    WidgetStateProperty<double?>? surfaceBorderWidth,
    WidgetStateProperty<BorderRadius?>? surfaceRadius,
    WidgetStateProperty<EdgeInsetsGeometry?>? surfacePadding,
    WidgetStateProperty<List<BoxShadow>?>? surfaceShadow,
    WidgetStateProperty<double?>? surfaceMaxHeight,
    WidgetStateProperty<double?>? surfaceOffset,
  }) => FluentDatePickerStyle(
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
    iconPadding: iconPadding ?? this.iconPadding,
    surfaceColor: surfaceColor ?? this.surfaceColor,
    surfaceBorderColor: surfaceBorderColor ?? this.surfaceBorderColor,
    surfaceBorderWidth: surfaceBorderWidth ?? this.surfaceBorderWidth,
    surfaceRadius: surfaceRadius ?? this.surfaceRadius,
    surfacePadding: surfacePadding ?? this.surfacePadding,
    surfaceShadow: surfaceShadow ?? this.surfaceShadow,
    surfaceMaxHeight: surfaceMaxHeight ?? this.surfaceMaxHeight,
    surfaceOffset: surfaceOffset ?? this.surfaceOffset,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentDatePickerStyle from({
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
    EdgeInsetsGeometry? iconPadding,
    Color? surfaceColor,
    Color? surfaceBorderColor,
    double? surfaceBorderWidth,
    BorderRadius? surfaceRadius,
    EdgeInsetsGeometry? surfacePadding,
    List<BoxShadow>? surfaceShadow,
    double? surfaceMaxHeight,
    double? surfaceOffset,
  }) => FluentDatePickerStyle(
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
    iconPadding: _all(iconPadding),
    surfaceColor: _all(surfaceColor),
    surfaceBorderColor: _all(surfaceBorderColor),
    surfaceBorderWidth: _all(surfaceBorderWidth),
    surfaceRadius: _all(surfaceRadius),
    surfacePadding: _all(surfacePadding),
    surfaceShadow: _all(surfaceShadow),
    surfaceMaxHeight: _all(surfaceMaxHeight),
    surfaceOffset: _all(surfaceOffset),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentDatePickerStyle &&
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
      other.iconPadding == iconPadding &&
      other.surfaceColor == surfaceColor &&
      other.surfaceBorderColor == surfaceBorderColor &&
      other.surfaceBorderWidth == surfaceBorderWidth &&
      other.surfaceRadius == surfaceRadius &&
      other.surfacePadding == surfacePadding &&
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
    iconPadding,
    surfaceColor,
    surfaceBorderColor,
    surfaceBorderWidth,
    surfaceRadius,
    surfacePadding,
    surfaceShadow,
    surfaceMaxHeight,
    surfaceOffset,
  ]);
}
