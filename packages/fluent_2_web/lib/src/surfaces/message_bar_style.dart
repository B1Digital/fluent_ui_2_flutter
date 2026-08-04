import 'package:flutter/widgets.dart';

import '../buttons/button_style.dart';

/// The visual configuration of a `FluentMessageBar`.
///
/// Shaped like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so the struct reads the same whether or not the
/// component it configures has interaction states. A message bar has none —
/// see `FluentMessageBar` — so every property here resolves against the empty
/// state set, and the shape is kept for consistency and for the day a `State`
/// axis appears in the design file.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the intent/layout/shape defaults derived from the theme
/// 2. the nearest `FluentMessageBarTheme`
/// 3. the widget's own `style`
@immutable
class FluentMessageBarStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentMessageBarStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.iconColor,
    this.iconSize,
    this.titleTextStyle,
    this.textStyle,
    this.padding,
    this.gap,
    this.multilineGap,
    this.iconPadding,
    this.bodyPadding,
    this.minimumSize,
    this.dismissButtonStyle,
  });

  /// Surface fill. The intent axis moves this and [borderColor] together.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Title and body colour. `Neutral/Foreground/1/Rest` on every intent —
  /// Fluent tints the glyph, never the prose.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Border colour. Null and transparent are different: Fluent's transparent
  /// tokens become opaque in high contrast.
  final WidgetStateProperty<Color?>? borderColor;

  /// Border width. Zero means no border, which is not the same as a transparent
  /// one — a zero-width border cannot become visible in high contrast.
  final WidgetStateProperty<double?>? borderWidth;

  /// Corner radius.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Status glyph tint. The only property the intent axis tints.
  final WidgetStateProperty<Color?>? iconColor;

  /// Status glyph edge length.
  final WidgetStateProperty<double?>? iconSize;

  /// Title type ramp. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? titleTextStyle;

  /// Body type ramp. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Padding inside the border.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Horizontal spacing between the glyph, the body, each action and the
  /// dismiss button.
  ///
  /// One property rather than three because Figma binds `Spacing/Horizontal/S`
  /// to all of them — the variant frame's own `itemSpacing`, the `Actions
  /// container`'s and the multi-line `Content container`'s.
  final WidgetStateProperty<double?>? gap;

  /// Vertical spacing between the content row and the actions row. Multi-line
  /// only; a single-line bar puts its actions in the content row at [gap].
  final WidgetStateProperty<double?>? multilineGap;

  /// Inset above the glyph. Zero on a single-line bar, whose row centres
  /// instead.
  final WidgetStateProperty<EdgeInsetsGeometry?>? iconPadding;

  /// Inset above the body. Zero on a single-line bar, whose row centres
  /// instead.
  final WidgetStateProperty<EdgeInsetsGeometry?>? bodyPadding;

  /// Minimum size of the bar.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Style handed to the dismiss button.
  ///
  /// Not a [WidgetStateProperty]: it is a nested style that already resolves
  /// per state on its own. The message bar's dismiss affordance is a real
  /// `FluentButton`, and its 24-square box with a 2px inset is *message bar*
  /// geometry rather than button geometry — which is why it travels here and
  /// not in the button's own defaults.
  final FluentButtonStyle? dismissButtonStyle;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour.
  FluentMessageBarStyle merge(FluentMessageBarStyle? other) {
    if (other == null) return this;
    return FluentMessageBarStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      iconColor: other.iconColor ?? iconColor,
      iconSize: other.iconSize ?? iconSize,
      titleTextStyle: other.titleTextStyle ?? titleTextStyle,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
      multilineGap: other.multilineGap ?? multilineGap,
      iconPadding: other.iconPadding ?? iconPadding,
      bodyPadding: other.bodyPadding ?? bodyPadding,
      minimumSize: other.minimumSize ?? minimumSize,
      // Merged rather than replaced, so overriding only the dismiss button's
      // radius keeps the message bar's own 24-square geometry.
      dismissButtonStyle:
          dismissButtonStyle?.merge(other.dismissButtonStyle) ??
          other.dismissButtonStyle,
    );
  }

  /// This style with the given properties replaced.
  FluentMessageBarStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<Color?>? iconColor,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<TextStyle?>? titleTextStyle,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<double?>? multilineGap,
    WidgetStateProperty<EdgeInsetsGeometry?>? iconPadding,
    WidgetStateProperty<EdgeInsetsGeometry?>? bodyPadding,
    WidgetStateProperty<Size?>? minimumSize,
    FluentButtonStyle? dismissButtonStyle,
  }) => FluentMessageBarStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    iconColor: iconColor ?? this.iconColor,
    iconSize: iconSize ?? this.iconSize,
    titleTextStyle: titleTextStyle ?? this.titleTextStyle,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    multilineGap: multilineGap ?? this.multilineGap,
    iconPadding: iconPadding ?? this.iconPadding,
    bodyPadding: bodyPadding ?? this.bodyPadding,
    minimumSize: minimumSize ?? this.minimumSize,
    dismissButtonStyle: dismissButtonStyle ?? this.dismissButtonStyle,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. [dismissButtonStyle] is absent
  /// on purpose — it is already a style, not a scalar, so pass it to the
  /// constructor.
  static FluentMessageBarStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    Color? iconColor,
    double? iconSize,
    TextStyle? titleTextStyle,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? multilineGap,
    EdgeInsetsGeometry? iconPadding,
    EdgeInsetsGeometry? bodyPadding,
    Size? minimumSize,
  }) => FluentMessageBarStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    iconColor: _all(iconColor),
    iconSize: _all(iconSize),
    titleTextStyle: _all(titleTextStyle),
    textStyle: _all(textStyle),
    padding: _all(padding),
    gap: _all(gap),
    multilineGap: _all(multilineGap),
    iconPadding: _all(iconPadding),
    bodyPadding: _all(bodyPadding),
    minimumSize: _all(minimumSize),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentMessageBarStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.iconColor == iconColor &&
      other.iconSize == iconSize &&
      other.titleTextStyle == titleTextStyle &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.gap == gap &&
      other.multilineGap == multilineGap &&
      other.iconPadding == iconPadding &&
      other.bodyPadding == bodyPadding &&
      other.minimumSize == minimumSize &&
      other.dismissButtonStyle == dismissButtonStyle;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    iconColor,
    iconSize,
    titleTextStyle,
    textStyle,
    padding,
    gap,
    multilineGap,
    iconPadding,
    bodyPadding,
    minimumSize,
    dismissButtonStyle,
  );
}
