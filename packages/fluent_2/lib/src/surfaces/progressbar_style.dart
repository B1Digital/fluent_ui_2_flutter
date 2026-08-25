import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentProgressBar`.
///
/// Deliberately shaped like Material's `ButtonStyle` and identical in structure
/// to `FluentButtonStyle`: every visual property is a [WidgetStateProperty], so
/// a component that does gain interaction states later needs no new shape.
///
/// A progress bar has **no** interaction states of its own — Figma's
/// `Static_ProgressBar` set has no Hover, Pressed, Selected or Disabled variant,
/// and `FluentProgressBar` resolves every property against an empty state set.
/// The [WidgetStateProperty] wrapper is kept anyway, because a consumer
/// composing a bar inside something interactive (a card that dims on hover, a
/// disabled form section) can then drive it from the ambient state set without
/// a different style type.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the size/status defaults derived from the theme
/// 2. the nearest `FluentProgressBarTheme`
/// 3. the widget's own `style`
///
/// The consumer's own style therefore wins, matching upstream's rule that
/// `props.className` is passed last to `mergeClasses`.
@immutable
class FluentProgressBarStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentProgressBarStyle({
    this.railColor,
    this.indicatorColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.thickness,
  });

  /// The unfilled groove behind the indicator.
  ///
  /// Figma's `Neutral/Background/6/Rest`; upstream calls this element the
  /// `rail`.
  final WidgetStateProperty<Color?>? railColor;

  /// The filled portion.
  ///
  /// Upstream calls this element the `bar`. Figma names the layer `Track`,
  /// which is the opposite of the usual slider vocabulary — do not read the
  /// layer name as the semantic.
  final WidgetStateProperty<Color?>? indicatorColor;

  /// Outline colour. Null and transparent are different: Fluent's
  /// `transparentStroke` becomes opaque in high contrast, and this outline is
  /// the only thing that keeps the rail visible there.
  final WidgetStateProperty<Color?>? borderColor;

  /// Outline width. Zero means no outline, which is not the same as a
  /// transparent one — a zero-width outline cannot become visible in high
  /// contrast.
  final WidgetStateProperty<double?>? borderWidth;

  /// Corner radius of both the rail and the indicator.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// The bar's height. Figma states this as a raw number per size — 2 and 4 —
  /// and binds no variable to it.
  final WidgetStateProperty<double?>? thickness;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour. This is what makes a partial override useful.
  FluentProgressBarStyle merge(FluentProgressBarStyle? other) {
    if (other == null) return this;
    return FluentProgressBarStyle(
      railColor: other.railColor ?? railColor,
      indicatorColor: other.indicatorColor ?? indicatorColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      thickness: other.thickness ?? thickness,
    );
  }

  /// This style with the given properties replaced.
  FluentProgressBarStyle copyWith({
    WidgetStateProperty<Color?>? railColor,
    WidgetStateProperty<Color?>? indicatorColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<double?>? thickness,
  }) => FluentProgressBarStyle(
    railColor: railColor ?? this.railColor,
    indicatorColor: indicatorColor ?? this.indicatorColor,
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    thickness: thickness ?? this.thickness,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentProgressBarStyle from({
    Color? railColor,
    Color? indicatorColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    double? thickness,
  }) => FluentProgressBarStyle(
    railColor: _all(railColor),
    indicatorColor: _all(indicatorColor),
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    thickness: _all(thickness),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentProgressBarStyle &&
      other.railColor == railColor &&
      other.indicatorColor == indicatorColor &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.thickness == thickness;

  @override
  int get hashCode => Object.hash(
    railColor,
    indicatorColor,
    borderColor,
    borderWidth,
    borderRadius,
    thickness,
  );
}
