import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentDrawer`.
///
/// Shaped like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], every field is nullable and means "inherit", and
/// resolution runs lowest to highest precedence:
///
/// 1. the type/size/position defaults derived from the theme
/// 2. the nearest `FluentDrawerTheme`
/// 3. the widget's own `style`
///
/// A drawer has no interaction states of its own — the Figma sets have no
/// `State` axis at all — so callers normally resolve these against an empty
/// state set. The properties stay [WidgetStateProperty] anyway so a consumer
/// can drive them from one if they want to.
///
/// Motion is deliberately **not** here. Upstream keys the drawer's duration off
/// its size rather than off any styling, so it lives in `fluentDrawerEnter`,
/// `fluentDrawerExit` and `fluentDrawerScrimFade` instead.
@immutable
class FluentDrawerStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentDrawerStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.scrimColor,
    this.shadow,
    this.width,
    this.headerPadding,
    this.headerGap,
    this.headerTextStyle,
    this.bodyPadding,
    this.footerPadding,
    this.footerGap,
  });

  /// Surface fill of the whole panel.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Default text and icon colour inside the panel.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Colour of the single rule along the drawer's inboard edge — the trailing
  /// edge for a `start` drawer, the leading edge for an `end` one.
  ///
  /// Null and transparent are different: an overlay drawer's rule is
  /// `transparentStroke`, which turns opaque in high contrast and is the only
  /// thing separating the panel from the page there.
  final WidgetStateProperty<Color?>? borderColor;

  /// Width of that rule. Zero means none, which is not the same as a
  /// transparent one — a zero-width rule cannot become visible in high
  /// contrast.
  final WidgetStateProperty<double?>? borderWidth;

  /// The modal scrim behind an overlay drawer.
  ///
  /// Never `Colors.transparent`: `backgroundOverlay` is a real alias token and
  /// stays opaque in high contrast, where a hardcoded transparent scrim would
  /// silently stop dimming anything.
  final WidgetStateProperty<Color?>? scrimColor;

  /// Elevation shadow. Null for an inline drawer, which sits flat in the
  /// layout.
  final WidgetStateProperty<List<BoxShadow>?>? shadow;

  /// Panel width. [double.infinity] means "as wide as the parent allows",
  /// which is how `FluentDrawerSize.full` is expressed.
  final WidgetStateProperty<double?>? width;

  /// Inset around the header slot.
  final WidgetStateProperty<EdgeInsetsGeometry?>? headerPadding;

  /// Vertical space between header children.
  final WidgetStateProperty<double?>? headerGap;

  /// Type ramp applied to the header slot. Its colour is overridden by
  /// [foregroundColor].
  final WidgetStateProperty<TextStyle?>? headerTextStyle;

  /// Inset around the body.
  final WidgetStateProperty<EdgeInsetsGeometry?>? bodyPadding;

  /// Inset around the footer slot.
  final WidgetStateProperty<EdgeInsetsGeometry?>? footerPadding;

  /// Horizontal space between footer children.
  final WidgetStateProperty<double?>? footerGap;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, so overriding only `width` keeps every resolved
  /// colour and inset.
  FluentDrawerStyle merge(FluentDrawerStyle? other) {
    if (other == null) return this;
    return FluentDrawerStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      scrimColor: other.scrimColor ?? scrimColor,
      shadow: other.shadow ?? shadow,
      width: other.width ?? width,
      headerPadding: other.headerPadding ?? headerPadding,
      headerGap: other.headerGap ?? headerGap,
      headerTextStyle: other.headerTextStyle ?? headerTextStyle,
      bodyPadding: other.bodyPadding ?? bodyPadding,
      footerPadding: other.footerPadding ?? footerPadding,
      footerGap: other.footerGap ?? footerGap,
    );
  }

  /// This style with the given properties replaced.
  FluentDrawerStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<Color?>? scrimColor,
    WidgetStateProperty<List<BoxShadow>?>? shadow,
    WidgetStateProperty<double?>? width,
    WidgetStateProperty<EdgeInsetsGeometry?>? headerPadding,
    WidgetStateProperty<double?>? headerGap,
    WidgetStateProperty<TextStyle?>? headerTextStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? bodyPadding,
    WidgetStateProperty<EdgeInsetsGeometry?>? footerPadding,
    WidgetStateProperty<double?>? footerGap,
  }) => FluentDrawerStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    scrimColor: scrimColor ?? this.scrimColor,
    shadow: shadow ?? this.shadow,
    width: width ?? this.width,
    headerPadding: headerPadding ?? this.headerPadding,
    headerGap: headerGap ?? this.headerGap,
    headerTextStyle: headerTextStyle ?? this.headerTextStyle,
    bodyPadding: bodyPadding ?? this.bodyPadding,
    footerPadding: footerPadding ?? this.footerPadding,
    footerGap: footerGap ?? this.footerGap,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`.
  static FluentDrawerStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    double? borderWidth,
    Color? scrimColor,
    List<BoxShadow>? shadow,
    double? width,
    EdgeInsetsGeometry? headerPadding,
    double? headerGap,
    TextStyle? headerTextStyle,
    EdgeInsetsGeometry? bodyPadding,
    EdgeInsetsGeometry? footerPadding,
    double? footerGap,
  }) => FluentDrawerStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    scrimColor: _all(scrimColor),
    shadow: _all(shadow),
    width: _all(width),
    headerPadding: _all(headerPadding),
    headerGap: _all(headerGap),
    headerTextStyle: _all(headerTextStyle),
    bodyPadding: _all(bodyPadding),
    footerPadding: _all(footerPadding),
    footerGap: _all(footerGap),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentDrawerStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.scrimColor == scrimColor &&
      other.shadow == shadow &&
      other.width == width &&
      other.headerPadding == headerPadding &&
      other.headerGap == headerGap &&
      other.headerTextStyle == headerTextStyle &&
      other.bodyPadding == bodyPadding &&
      other.footerPadding == footerPadding &&
      other.footerGap == footerGap;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    borderColor,
    borderWidth,
    scrimColor,
    shadow,
    width,
    headerPadding,
    headerGap,
    headerTextStyle,
    bodyPadding,
    footerPadding,
    footerGap,
  );
}
