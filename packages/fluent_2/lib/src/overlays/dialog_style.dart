import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentDialog`.
///
/// Shaped like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so the handful of states a dialog does have — and the
/// `disabled` one its close button reaches — live on the property rather than
/// being branched on at build time.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the size defaults derived from the theme
/// 2. the nearest `FluentDialogTheme`
/// 3. the widget's own `style`
///
/// A dialog surface has **no** Hover, Pressed or Disabled variant in either
/// Figma or `useDialogSurfaceStyles.styles.ts`, so most of these resolve to a
/// single token. They are still [WidgetStateProperty] so a consumer can add a
/// state ramp of their own without a different type.
@immutable
class FluentDialogStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentDialogStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.scrimColor,
    this.shadow,
    this.padding,
    this.gap,
    this.headerGap,
    this.closeButtonPadding,
    this.actionsPadding,
    this.actionsGap,
    this.titleTextStyle,
    this.bodyTextStyle,
    this.maxWidth,
  });

  /// Surface fill.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Title and body colour.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Surface border colour. Null and transparent are different: Fluent's
  /// `transparentStroke` becomes opaque in high contrast, where it is the only
  /// thing separating the surface from the scrim behind it.
  final WidgetStateProperty<Color?>? borderColor;

  /// Surface border width. Zero means no border, which is not the same as a
  /// transparent one — a zero-width border cannot become visible in high
  /// contrast.
  final WidgetStateProperty<double?>? borderWidth;

  /// Surface corner radius.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// The full-viewport backdrop behind a modal or alert dialog.
  ///
  /// A real Fluent token, never a hand-rolled black: `colorBackgroundOverlay`
  /// is semi-transparent in light and dark and stays a defined colour in high
  /// contrast, which a hardcoded `Color(0x00000000)` would not.
  final WidgetStateProperty<Color?>? scrimColor;

  /// Surface elevation.
  final WidgetStateProperty<List<BoxShadow>?>? shadow;

  /// Inset between the surface border and its content.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Space between the header, the body and the actions.
  final WidgetStateProperty<double?>? gap;

  /// Space between the title and the close button.
  final WidgetStateProperty<double?>? headerGap;

  /// Extra inset before the close button, on top of [headerGap].
  final WidgetStateProperty<EdgeInsetsGeometry?>? closeButtonPadding;

  /// Inset above the actions row, on top of [gap].
  final WidgetStateProperty<EdgeInsetsGeometry?>? actionsPadding;

  /// Space between adjacent action buttons.
  final WidgetStateProperty<double?>? actionsGap;

  /// Title text style. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? titleTextStyle;

  /// Body text style. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? bodyTextStyle;

  /// Width the surface grows to, viewport permitting.
  final WidgetStateProperty<double?>? maxWidth;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour.
  FluentDialogStyle merge(FluentDialogStyle? other) {
    if (other == null) return this;
    return FluentDialogStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      scrimColor: other.scrimColor ?? scrimColor,
      shadow: other.shadow ?? shadow,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
      headerGap: other.headerGap ?? headerGap,
      closeButtonPadding: other.closeButtonPadding ?? closeButtonPadding,
      actionsPadding: other.actionsPadding ?? actionsPadding,
      actionsGap: other.actionsGap ?? actionsGap,
      titleTextStyle: other.titleTextStyle ?? titleTextStyle,
      bodyTextStyle: other.bodyTextStyle ?? bodyTextStyle,
      maxWidth: other.maxWidth ?? maxWidth,
    );
  }

  /// This style with the given properties replaced.
  FluentDialogStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<Color?>? scrimColor,
    WidgetStateProperty<List<BoxShadow>?>? shadow,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<double?>? headerGap,
    WidgetStateProperty<EdgeInsetsGeometry?>? closeButtonPadding,
    WidgetStateProperty<EdgeInsetsGeometry?>? actionsPadding,
    WidgetStateProperty<double?>? actionsGap,
    WidgetStateProperty<TextStyle?>? titleTextStyle,
    WidgetStateProperty<TextStyle?>? bodyTextStyle,
    WidgetStateProperty<double?>? maxWidth,
  }) => FluentDialogStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    scrimColor: scrimColor ?? this.scrimColor,
    shadow: shadow ?? this.shadow,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    headerGap: headerGap ?? this.headerGap,
    closeButtonPadding: closeButtonPadding ?? this.closeButtonPadding,
    actionsPadding: actionsPadding ?? this.actionsPadding,
    actionsGap: actionsGap ?? this.actionsGap,
    titleTextStyle: titleTextStyle ?? this.titleTextStyle,
    bodyTextStyle: bodyTextStyle ?? this.bodyTextStyle,
    maxWidth: maxWidth ?? this.maxWidth,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentDialogStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    Color? scrimColor,
    List<BoxShadow>? shadow,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? headerGap,
    EdgeInsetsGeometry? closeButtonPadding,
    EdgeInsetsGeometry? actionsPadding,
    double? actionsGap,
    TextStyle? titleTextStyle,
    TextStyle? bodyTextStyle,
    double? maxWidth,
  }) => FluentDialogStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    scrimColor: _all(scrimColor),
    shadow: _all(shadow),
    padding: _all(padding),
    gap: _all(gap),
    headerGap: _all(headerGap),
    closeButtonPadding: _all(closeButtonPadding),
    actionsPadding: _all(actionsPadding),
    actionsGap: _all(actionsGap),
    titleTextStyle: _all(titleTextStyle),
    bodyTextStyle: _all(bodyTextStyle),
    maxWidth: _all(maxWidth),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentDialogStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.scrimColor == scrimColor &&
      other.shadow == shadow &&
      other.padding == padding &&
      other.gap == gap &&
      other.headerGap == headerGap &&
      other.closeButtonPadding == closeButtonPadding &&
      other.actionsPadding == actionsPadding &&
      other.actionsGap == actionsGap &&
      other.titleTextStyle == titleTextStyle &&
      other.bodyTextStyle == bodyTextStyle &&
      other.maxWidth == maxWidth;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    scrimColor,
    shadow,
    padding,
    gap,
    headerGap,
    closeButtonPadding,
    actionsPadding,
    actionsGap,
    titleTextStyle,
    bodyTextStyle,
    maxWidth,
  );
}
