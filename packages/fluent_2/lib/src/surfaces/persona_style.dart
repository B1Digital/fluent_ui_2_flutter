import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentPersona`.
///
/// Same shape as `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], every field is nullable and means "inherit", and the
/// resolution order lowest to highest is
///
/// 1. the size defaults derived from the theme
/// 2. the nearest `FluentPersonaTheme`
/// 3. the widget's own `style`
///
/// A persona takes no hover, press or focus of its own — the Figma `Persona`
/// set has no `State` axis and upstream declares no interactive rule — so in
/// practice every property resolves the same value for every state. The state
/// machinery is kept anyway: a persona dropped inside a list item or a button
/// is styled from *that* control's state set, which is exactly what
/// `buildFluentPersona`'s `states` argument is for.
///
/// There is no colour, radius or stroke here. A persona paints no surface of
/// its own: everything with a fill is inside the composed `FluentAvatar` or
/// `FluentPresenceBadge`, which carry their own styles and their own themes.
@immutable
class FluentPersonaStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentPersonaStyle({
    this.primaryTextStyle,
    this.secondaryTextStyle,
    this.primaryColor,
    this.secondaryColor,
    this.gap,
    this.contentPadding,
    this.lineOverlap,
  });

  /// Type ramp of the first line. `body1`, or `subtitle2` from the two largest
  /// sizes up.
  final WidgetStateProperty<TextStyle?>? primaryTextStyle;

  /// Type ramp shared by the second, third and fourth lines — upstream styles
  /// all three through one `optionalText` class, and Figma ramps all three
  /// together.
  final WidgetStateProperty<TextStyle?>? secondaryTextStyle;

  /// First-line colour. Figma's `Neutral/Foreground/1/Rest`.
  final WidgetStateProperty<Color?>? primaryColor;

  /// Colour of the second, third and fourth lines. Figma's
  /// `Neutral/Foreground/2/Rest`.
  final WidgetStateProperty<Color?>? secondaryColor;

  /// Space between the avatar (or presence badge) and the text block. Figma's
  /// `Avatar spacing` / `Presence badge spacing`.
  final WidgetStateProperty<double?>? gap;

  /// Inset above and below the whole text block. Figma's `Content` frame binds
  /// `Spacing/Vertical/XXS` top and bottom — but only when there is a second
  /// line to inset from; the single-line variant carries no wrapper at all.
  final WidgetStateProperty<EdgeInsets?>? contentPadding;

  /// How far the second line is pulled *up* into the first. Figma's `Content`
  /// frame states `itemSpacing: -2` and upstream writes the same number as
  /// `secondLineSpacing { marginTop: -2px }`.
  final WidgetStateProperty<double?>? lineOverlap;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, so overriding only `gap` keeps every resolved
  /// type ramp.
  FluentPersonaStyle merge(FluentPersonaStyle? other) {
    if (other == null) return this;
    return FluentPersonaStyle(
      primaryTextStyle: other.primaryTextStyle ?? primaryTextStyle,
      secondaryTextStyle: other.secondaryTextStyle ?? secondaryTextStyle,
      primaryColor: other.primaryColor ?? primaryColor,
      secondaryColor: other.secondaryColor ?? secondaryColor,
      gap: other.gap ?? gap,
      contentPadding: other.contentPadding ?? contentPadding,
      lineOverlap: other.lineOverlap ?? lineOverlap,
    );
  }

  /// This style with the given properties replaced.
  FluentPersonaStyle copyWith({
    WidgetStateProperty<TextStyle?>? primaryTextStyle,
    WidgetStateProperty<TextStyle?>? secondaryTextStyle,
    WidgetStateProperty<Color?>? primaryColor,
    WidgetStateProperty<Color?>? secondaryColor,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<EdgeInsets?>? contentPadding,
    WidgetStateProperty<double?>? lineOverlap,
  }) => FluentPersonaStyle(
    primaryTextStyle: primaryTextStyle ?? this.primaryTextStyle,
    secondaryTextStyle: secondaryTextStyle ?? this.secondaryTextStyle,
    primaryColor: primaryColor ?? this.primaryColor,
    secondaryColor: secondaryColor ?? this.secondaryColor,
    gap: gap ?? this.gap,
    contentPadding: contentPadding ?? this.contentPadding,
    lineOverlap: lineOverlap ?? this.lineOverlap,
  );

  /// Convenience for the common case of one value across every state.
  static FluentPersonaStyle from({
    TextStyle? primaryTextStyle,
    TextStyle? secondaryTextStyle,
    Color? primaryColor,
    Color? secondaryColor,
    double? gap,
    EdgeInsets? contentPadding,
    double? lineOverlap,
  }) => FluentPersonaStyle(
    primaryTextStyle: _all(primaryTextStyle),
    secondaryTextStyle: _all(secondaryTextStyle),
    primaryColor: _all(primaryColor),
    secondaryColor: _all(secondaryColor),
    gap: _all(gap),
    contentPadding: _all(contentPadding),
    lineOverlap: _all(lineOverlap),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentPersonaStyle &&
      other.primaryTextStyle == primaryTextStyle &&
      other.secondaryTextStyle == secondaryTextStyle &&
      other.primaryColor == primaryColor &&
      other.secondaryColor == secondaryColor &&
      other.gap == gap &&
      other.contentPadding == contentPadding &&
      other.lineOverlap == lineOverlap;

  @override
  int get hashCode => Object.hash(
    primaryTextStyle,
    secondaryTextStyle,
    primaryColor,
    secondaryColor,
    gap,
    contentPadding,
    lineOverlap,
  );
}
