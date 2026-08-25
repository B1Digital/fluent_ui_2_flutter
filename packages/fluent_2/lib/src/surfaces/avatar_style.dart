import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentAvatar`.
///
/// Same shape as `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], every field is nullable and means "inherit", and the
/// resolution order lowest to highest is
///
/// 1. the colour/size/shape defaults derived from the theme
/// 2. the nearest `FluentAvatarTheme`
/// 3. the widget's own `style`
///
/// An avatar takes no hover, press or focus of its own, so in practice every
/// property resolves the same value for every state. The state machinery is
/// kept anyway: an avatar dropped inside a button or a list item is styled from
/// *that* control's state set, which is exactly what `buildFluentAvatar`'s
/// `states` argument is for.
@immutable
class FluentAvatarStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentAvatarStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.ringColor,
    this.ringGapColor,
    this.ringWidth,
    this.textStyle,
    this.iconSize,
    this.diameter,
  });

  /// The disc behind the initials or icon. Figma's `Avatar color` →
  /// `Background`; unused when an image fills the avatar.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Initials and icon colour. Figma's `Avatar color` → `Foreground`.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// The hairline drawn *inside* the avatar's own box. Figma's
  /// `Avatar color` → `Inside stroke`, which is a transparent token for every
  /// mode except `Overflow (Avatar group)` — and transparent tokens turn opaque
  /// in high contrast, which is the point of keeping it rather than dropping it.
  final WidgetStateProperty<Color?>? borderColor;

  /// Width of [borderColor]. Ramps 1, 2, 3, 4 with the avatar's size.
  final WidgetStateProperty<double?>? borderWidth;

  /// Corner radius. Circular, or `FluentRadius.small` for the square shape.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// The activity ring's stroke. Figma's `Avatar color` → `Active stroke`.
  final WidgetStateProperty<Color?>? ringColor;

  /// Fills the gap between the avatar and the activity ring, so the ring reads
  /// against a coloured backdrop. Figma's `Neutral/Background/1/Rest`.
  final WidgetStateProperty<Color?>? ringGapColor;

  /// Activity ring stroke width. Also the width of the gap inside it — Figma
  /// and React agree that the ring sits one ring-width clear of the avatar.
  final WidgetStateProperty<double?>? ringWidth;

  /// Initials type ramp.
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Icon edge length, when the avatar shows an icon rather than initials.
  final WidgetStateProperty<double?>? iconSize;

  /// The avatar's own edge length. Square in every size.
  final WidgetStateProperty<double?>? diameter;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, so overriding only `borderRadius` keeps every
  /// resolved colour.
  FluentAvatarStyle merge(FluentAvatarStyle? other) {
    if (other == null) return this;
    return FluentAvatarStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      ringColor: other.ringColor ?? ringColor,
      ringGapColor: other.ringGapColor ?? ringGapColor,
      ringWidth: other.ringWidth ?? ringWidth,
      textStyle: other.textStyle ?? textStyle,
      iconSize: other.iconSize ?? iconSize,
      diameter: other.diameter ?? diameter,
    );
  }

  /// This style with the given properties replaced.
  FluentAvatarStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<Color?>? ringColor,
    WidgetStateProperty<Color?>? ringGapColor,
    WidgetStateProperty<double?>? ringWidth,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<double?>? diameter,
  }) => FluentAvatarStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    ringColor: ringColor ?? this.ringColor,
    ringGapColor: ringGapColor ?? this.ringGapColor,
    ringWidth: ringWidth ?? this.ringWidth,
    textStyle: textStyle ?? this.textStyle,
    iconSize: iconSize ?? this.iconSize,
    diameter: diameter ?? this.diameter,
  );

  /// Convenience for the common case of one value across every state.
  static FluentAvatarStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    Color? ringColor,
    Color? ringGapColor,
    double? ringWidth,
    TextStyle? textStyle,
    double? iconSize,
    double? diameter,
  }) => FluentAvatarStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    ringColor: _all(ringColor),
    ringGapColor: _all(ringGapColor),
    ringWidth: _all(ringWidth),
    textStyle: _all(textStyle),
    iconSize: _all(iconSize),
    diameter: _all(diameter),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentAvatarStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.ringColor == ringColor &&
      other.ringGapColor == ringGapColor &&
      other.ringWidth == ringWidth &&
      other.textStyle == textStyle &&
      other.iconSize == iconSize &&
      other.diameter == diameter;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    ringColor,
    ringGapColor,
    ringWidth,
    textStyle,
    iconSize,
    diameter,
  );
}
