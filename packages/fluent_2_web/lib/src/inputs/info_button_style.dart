import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentInfoButton`.
///
/// The same shape as `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed, selected and disabled values live
/// on the property rather than being branched on at build time.
///
/// The properties split in two. The unprefixed ones describe the **trigger** —
/// the 20/24 square carrying the info glyph. The `info*` ones describe the
/// **tip surface** the trigger opens, which upstream styles in the very same
/// file (`useInfoButtonStyles.styles.ts` sets `maxWidth` and the type ramp on
/// its `popover` slot). They live here for the same reason: they belong to the
/// info button's `info` slot, not to the popover component that happens to
/// carry it. When `FluentPopover` lands in Wave 4 it owns the *positioning and
/// dismissal*; these numbers stay where upstream keeps them.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the size defaults derived from the theme
/// 2. the nearest `FluentInfoButtonTheme`
/// 3. the widget's own `style`
///
/// The consumer's own style therefore wins, matching upstream's rule that
/// `props.className` is passed last to `mergeClasses`.
@immutable
class FluentInfoButtonStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentInfoButtonStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.padding,
    this.iconSize,
    this.mouseCursor,
    this.infoBackgroundColor,
    this.infoForegroundColor,
    this.infoBorderColor,
    this.infoBorderWidth,
    this.infoBorderRadius,
    this.infoPadding,
    this.infoMaxWidth,
    this.infoTextStyle,
    this.infoShadow,
    this.infoOffset,
  });

  /// Trigger surface fill.
  ///
  /// Fully transparent at rest, and a real token rather than a bare
  /// transparent colour: `transparentBackground` turns opaque in high
  /// contrast, where a hardcoded transparent would stay invisible.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Info glyph colour.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Trigger corner radius.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Inset between the trigger's edge and the glyph box.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Glyph edge length. 12, 16 or 20, matching upstream's three icon
  /// components.
  final WidgetStateProperty<double?>? iconSize;

  /// Cursor while hovering the trigger.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// Tip surface fill.
  final WidgetStateProperty<Color?>? infoBackgroundColor;

  /// Tip content colour.
  final WidgetStateProperty<Color?>? infoForegroundColor;

  /// Tip border colour. Null and transparent are different: `transparentStroke`
  /// becomes opaque in high contrast, where it is the only thing separating the
  /// surface from the page behind it.
  final WidgetStateProperty<Color?>? infoBorderColor;

  /// Tip border width.
  final WidgetStateProperty<double?>? infoBorderWidth;

  /// Tip corner radius.
  final WidgetStateProperty<BorderRadius?>? infoBorderRadius;

  /// Inset inside the tip surface.
  final WidgetStateProperty<EdgeInsetsGeometry?>? infoPadding;

  /// Width at which tip content wraps.
  final WidgetStateProperty<double?>? infoMaxWidth;

  /// Tip type ramp. Its colour is overridden by [infoForegroundColor].
  final WidgetStateProperty<TextStyle?>? infoTextStyle;

  /// Tip elevation.
  final WidgetStateProperty<List<BoxShadow>?>? infoShadow;

  /// Gap between the trigger and the tip surface.
  final WidgetStateProperty<double?>? infoOffset;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only [infoMaxWidth]
  /// keeps every resolved colour. This is what makes a partial override useful.
  FluentInfoButtonStyle merge(FluentInfoButtonStyle? other) {
    if (other == null) return this;
    return FluentInfoButtonStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      iconSize: other.iconSize ?? iconSize,
      mouseCursor: other.mouseCursor ?? mouseCursor,
      infoBackgroundColor: other.infoBackgroundColor ?? infoBackgroundColor,
      infoForegroundColor: other.infoForegroundColor ?? infoForegroundColor,
      infoBorderColor: other.infoBorderColor ?? infoBorderColor,
      infoBorderWidth: other.infoBorderWidth ?? infoBorderWidth,
      infoBorderRadius: other.infoBorderRadius ?? infoBorderRadius,
      infoPadding: other.infoPadding ?? infoPadding,
      infoMaxWidth: other.infoMaxWidth ?? infoMaxWidth,
      infoTextStyle: other.infoTextStyle ?? infoTextStyle,
      infoShadow: other.infoShadow ?? infoShadow,
      infoOffset: other.infoOffset ?? infoOffset,
    );
  }

  /// This style with the given properties replaced.
  FluentInfoButtonStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    WidgetStateProperty<Color?>? infoBackgroundColor,
    WidgetStateProperty<Color?>? infoForegroundColor,
    WidgetStateProperty<Color?>? infoBorderColor,
    WidgetStateProperty<double?>? infoBorderWidth,
    WidgetStateProperty<BorderRadius?>? infoBorderRadius,
    WidgetStateProperty<EdgeInsetsGeometry?>? infoPadding,
    WidgetStateProperty<double?>? infoMaxWidth,
    WidgetStateProperty<TextStyle?>? infoTextStyle,
    WidgetStateProperty<List<BoxShadow>?>? infoShadow,
    WidgetStateProperty<double?>? infoOffset,
  }) => FluentInfoButtonStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    borderRadius: borderRadius ?? this.borderRadius,
    padding: padding ?? this.padding,
    iconSize: iconSize ?? this.iconSize,
    mouseCursor: mouseCursor ?? this.mouseCursor,
    infoBackgroundColor: infoBackgroundColor ?? this.infoBackgroundColor,
    infoForegroundColor: infoForegroundColor ?? this.infoForegroundColor,
    infoBorderColor: infoBorderColor ?? this.infoBorderColor,
    infoBorderWidth: infoBorderWidth ?? this.infoBorderWidth,
    infoBorderRadius: infoBorderRadius ?? this.infoBorderRadius,
    infoPadding: infoPadding ?? this.infoPadding,
    infoMaxWidth: infoMaxWidth ?? this.infoMaxWidth,
    infoTextStyle: infoTextStyle ?? this.infoTextStyle,
    infoShadow: infoShadow ?? this.infoShadow,
    infoOffset: infoOffset ?? this.infoOffset,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state — which, for the trigger's
  /// fill and glyph, it always does.
  static FluentInfoButtonStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    double? iconSize,
    MouseCursor? mouseCursor,
    Color? infoBackgroundColor,
    Color? infoForegroundColor,
    Color? infoBorderColor,
    double? infoBorderWidth,
    BorderRadius? infoBorderRadius,
    EdgeInsetsGeometry? infoPadding,
    double? infoMaxWidth,
    TextStyle? infoTextStyle,
    List<BoxShadow>? infoShadow,
    double? infoOffset,
  }) => FluentInfoButtonStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    borderRadius: _all(borderRadius),
    padding: _all(padding),
    iconSize: _all(iconSize),
    mouseCursor: _all(mouseCursor),
    infoBackgroundColor: _all(infoBackgroundColor),
    infoForegroundColor: _all(infoForegroundColor),
    infoBorderColor: _all(infoBorderColor),
    infoBorderWidth: _all(infoBorderWidth),
    infoBorderRadius: _all(infoBorderRadius),
    infoPadding: _all(infoPadding),
    infoMaxWidth: _all(infoMaxWidth),
    infoTextStyle: _all(infoTextStyle),
    infoShadow: _all(infoShadow),
    infoOffset: _all(infoOffset),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentInfoButtonStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.borderRadius == borderRadius &&
      other.padding == padding &&
      other.iconSize == iconSize &&
      other.mouseCursor == mouseCursor &&
      other.infoBackgroundColor == infoBackgroundColor &&
      other.infoForegroundColor == infoForegroundColor &&
      other.infoBorderColor == infoBorderColor &&
      other.infoBorderWidth == infoBorderWidth &&
      other.infoBorderRadius == infoBorderRadius &&
      other.infoPadding == infoPadding &&
      other.infoMaxWidth == infoMaxWidth &&
      other.infoTextStyle == infoTextStyle &&
      other.infoShadow == infoShadow &&
      other.infoOffset == infoOffset;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    borderRadius,
    padding,
    iconSize,
    mouseCursor,
    infoBackgroundColor,
    infoForegroundColor,
    infoBorderColor,
    infoBorderWidth,
    infoBorderRadius,
    infoPadding,
    infoMaxWidth,
    infoTextStyle,
    infoShadow,
    infoOffset,
  );
}
