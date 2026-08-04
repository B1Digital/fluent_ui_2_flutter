import 'package:flutter/widgets.dart';

import '../buttons/button_style.dart';

/// The visual configuration of a `FluentToast`.
///
/// Shaped like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], every field is nullable and means "inherit", and the
/// resolution order lowest to highest is
///
/// 1. the intent defaults derived from the theme,
/// 2. the nearest `FluentToastTheme`,
/// 3. the widget's own `style`.
///
/// A toast has no interaction states of its own — the Figma component has no
/// `State` axis and `useToastStyles.styles.ts` declares no hover, pressed or
/// disabled rule — so most of these resolve to a single value. They are still
/// spelled as state properties so a consumer who *adds* a state gets the usual
/// precedence for free, and so overriding one reads the same as overriding one
/// on a button.
@immutable
class FluentToastStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentToastStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.subtitleColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.shadow,
    this.padding,
    this.titleTextStyle,
    this.bodyTextStyle,
    this.subtitleTextStyle,
    this.timestampTextStyle,
    this.iconColor,
    this.iconSize,
    this.mediaGap,
    this.endGap,
    this.bodyIndent,
    this.bodyPadding,
    this.subtitlePadding,
    this.footerPadding,
    this.footerGap,
    this.width,
    this.stackGap,
    this.mouseCursor,
    this.dismissButtonStyle,
  });

  /// Surface fill.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Title, body and timestamp colour.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Subtitle colour, which is a ramp step quieter than [foregroundColor].
  final WidgetStateProperty<Color?>? subtitleColor;

  /// Border colour. Null and transparent are different: Fluent's
  /// `transparentStroke` becomes opaque in high contrast, and on a toast it is
  /// the only thing separating a `neutralBackground1` surface from a
  /// `neutralBackground1` page.
  final WidgetStateProperty<Color?>? borderColor;

  /// Border width. Zero means no border, which is not the same as a transparent
  /// one — a zero-width border cannot become visible in high contrast.
  final WidgetStateProperty<double?>? borderWidth;

  /// Corner radius.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Elevation shadow under the surface.
  final WidgetStateProperty<List<BoxShadow>?>? shadow;

  /// Padding inside the border.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Title ramp. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? titleTextStyle;

  /// Body ramp.
  final WidgetStateProperty<TextStyle?>? bodyTextStyle;

  /// Subtitle ramp. Its colour is overridden by [subtitleColor].
  final WidgetStateProperty<TextStyle?>? subtitleTextStyle;

  /// Timestamp ramp, for the end slot.
  final WidgetStateProperty<TextStyle?>? timestampTextStyle;

  /// Status glyph colour. The one property the intent actually moves.
  final WidgetStateProperty<Color?>? iconColor;

  /// Status glyph box edge length.
  final WidgetStateProperty<double?>? iconSize;

  /// Space between the status glyph and the title.
  final WidgetStateProperty<double?>? mediaGap;

  /// Space between the title and the end slot.
  final WidgetStateProperty<double?>? endGap;

  /// How far the body is indented, so it lines up under the title rather than
  /// under the glyph.
  final WidgetStateProperty<double?>? bodyIndent;

  /// Inset above the body.
  final WidgetStateProperty<EdgeInsetsGeometry?>? bodyPadding;

  /// Inset above the subtitle.
  final WidgetStateProperty<EdgeInsetsGeometry?>? subtitlePadding;

  /// Inset above the footer row.
  final WidgetStateProperty<EdgeInsetsGeometry?>? footerPadding;

  /// Space between footer actions.
  final WidgetStateProperty<double?>? footerGap;

  /// Surface width. Fixed rather than hugging — see `FluentToaster`.
  final WidgetStateProperty<double?>? width;

  /// Space between stacked toasts, which collapses with the toast it belongs
  /// to rather than being left behind as a gap.
  final WidgetStateProperty<double?>? stackGap;

  /// Cursor while hovering the surface.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// Geometry for the dismiss button, which is a real `FluentButton` wearing
  /// the toast's own numbers.
  final FluentButtonStyle? dismissButtonStyle;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour.
  FluentToastStyle merge(FluentToastStyle? other) {
    if (other == null) return this;
    return FluentToastStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      subtitleColor: other.subtitleColor ?? subtitleColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      shadow: other.shadow ?? shadow,
      padding: other.padding ?? padding,
      titleTextStyle: other.titleTextStyle ?? titleTextStyle,
      bodyTextStyle: other.bodyTextStyle ?? bodyTextStyle,
      subtitleTextStyle: other.subtitleTextStyle ?? subtitleTextStyle,
      timestampTextStyle: other.timestampTextStyle ?? timestampTextStyle,
      iconColor: other.iconColor ?? iconColor,
      iconSize: other.iconSize ?? iconSize,
      mediaGap: other.mediaGap ?? mediaGap,
      endGap: other.endGap ?? endGap,
      bodyIndent: other.bodyIndent ?? bodyIndent,
      bodyPadding: other.bodyPadding ?? bodyPadding,
      subtitlePadding: other.subtitlePadding ?? subtitlePadding,
      footerPadding: other.footerPadding ?? footerPadding,
      footerGap: other.footerGap ?? footerGap,
      width: other.width ?? width,
      stackGap: other.stackGap ?? stackGap,
      mouseCursor: other.mouseCursor ?? mouseCursor,
      dismissButtonStyle:
          dismissButtonStyle?.merge(other.dismissButtonStyle) ??
          other.dismissButtonStyle,
    );
  }

  /// This style with the given properties replaced.
  FluentToastStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? subtitleColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<List<BoxShadow>?>? shadow,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<TextStyle?>? titleTextStyle,
    WidgetStateProperty<TextStyle?>? bodyTextStyle,
    WidgetStateProperty<TextStyle?>? subtitleTextStyle,
    WidgetStateProperty<TextStyle?>? timestampTextStyle,
    WidgetStateProperty<Color?>? iconColor,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<double?>? mediaGap,
    WidgetStateProperty<double?>? endGap,
    WidgetStateProperty<double?>? bodyIndent,
    WidgetStateProperty<EdgeInsetsGeometry?>? bodyPadding,
    WidgetStateProperty<EdgeInsetsGeometry?>? subtitlePadding,
    WidgetStateProperty<EdgeInsetsGeometry?>? footerPadding,
    WidgetStateProperty<double?>? footerGap,
    WidgetStateProperty<double?>? width,
    WidgetStateProperty<double?>? stackGap,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
    FluentButtonStyle? dismissButtonStyle,
  }) => FluentToastStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    subtitleColor: subtitleColor ?? this.subtitleColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    shadow: shadow ?? this.shadow,
    padding: padding ?? this.padding,
    titleTextStyle: titleTextStyle ?? this.titleTextStyle,
    bodyTextStyle: bodyTextStyle ?? this.bodyTextStyle,
    subtitleTextStyle: subtitleTextStyle ?? this.subtitleTextStyle,
    timestampTextStyle: timestampTextStyle ?? this.timestampTextStyle,
    iconColor: iconColor ?? this.iconColor,
    iconSize: iconSize ?? this.iconSize,
    mediaGap: mediaGap ?? this.mediaGap,
    endGap: endGap ?? this.endGap,
    bodyIndent: bodyIndent ?? this.bodyIndent,
    bodyPadding: bodyPadding ?? this.bodyPadding,
    subtitlePadding: subtitlePadding ?? this.subtitlePadding,
    footerPadding: footerPadding ?? this.footerPadding,
    footerGap: footerGap ?? this.footerGap,
    width: width ?? this.width,
    stackGap: stackGap ?? this.stackGap,
    mouseCursor: mouseCursor ?? this.mouseCursor,
    dismissButtonStyle: dismissButtonStyle ?? this.dismissButtonStyle,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentToastStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? subtitleColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadow,
    EdgeInsetsGeometry? padding,
    TextStyle? titleTextStyle,
    TextStyle? bodyTextStyle,
    TextStyle? subtitleTextStyle,
    TextStyle? timestampTextStyle,
    Color? iconColor,
    double? iconSize,
    double? mediaGap,
    double? endGap,
    double? bodyIndent,
    EdgeInsetsGeometry? bodyPadding,
    EdgeInsetsGeometry? subtitlePadding,
    EdgeInsetsGeometry? footerPadding,
    double? footerGap,
    double? width,
    double? stackGap,
    MouseCursor? mouseCursor,
    FluentButtonStyle? dismissButtonStyle,
  }) => FluentToastStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    subtitleColor: _all(subtitleColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    shadow: _all(shadow),
    padding: _all(padding),
    titleTextStyle: _all(titleTextStyle),
    bodyTextStyle: _all(bodyTextStyle),
    subtitleTextStyle: _all(subtitleTextStyle),
    timestampTextStyle: _all(timestampTextStyle),
    iconColor: _all(iconColor),
    iconSize: _all(iconSize),
    mediaGap: _all(mediaGap),
    endGap: _all(endGap),
    bodyIndent: _all(bodyIndent),
    bodyPadding: _all(bodyPadding),
    subtitlePadding: _all(subtitlePadding),
    footerPadding: _all(footerPadding),
    footerGap: _all(footerGap),
    width: _all(width),
    stackGap: _all(stackGap),
    mouseCursor: _all(mouseCursor),
    dismissButtonStyle: dismissButtonStyle,
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentToastStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.subtitleColor == subtitleColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.shadow == shadow &&
      other.padding == padding &&
      other.titleTextStyle == titleTextStyle &&
      other.bodyTextStyle == bodyTextStyle &&
      other.subtitleTextStyle == subtitleTextStyle &&
      other.timestampTextStyle == timestampTextStyle &&
      other.iconColor == iconColor &&
      other.iconSize == iconSize &&
      other.mediaGap == mediaGap &&
      other.endGap == endGap &&
      other.bodyIndent == bodyIndent &&
      other.bodyPadding == bodyPadding &&
      other.subtitlePadding == subtitlePadding &&
      other.footerPadding == footerPadding &&
      other.footerGap == footerGap &&
      other.width == width &&
      other.stackGap == stackGap &&
      other.mouseCursor == mouseCursor &&
      other.dismissButtonStyle == dismissButtonStyle;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    backgroundColor,
    foregroundColor,
    subtitleColor,
    borderColor,
    borderWidth,
    borderRadius,
    shadow,
    padding,
    titleTextStyle,
    bodyTextStyle,
    subtitleTextStyle,
    timestampTextStyle,
    iconColor,
    iconSize,
    mediaGap,
    endGap,
    bodyIndent,
    bodyPadding,
    subtitlePadding,
    footerPadding,
    footerGap,
    width,
    stackGap,
    mouseCursor,
    dismissButtonStyle,
  ]);
}
