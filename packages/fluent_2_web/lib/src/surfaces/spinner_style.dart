import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentSpinner`.
///
/// Shaped exactly like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so a consumer who has read one Fluent style has read
/// them all.
///
/// A spinner is the one component in the family that never resolves an
/// interaction state — it has no hover, press, focus or disabled rendering, and
/// the Figma set carries no `State` axis to give it one. `buildFluentSpinner`
/// therefore always resolves against the empty set. The properties are still
/// [WidgetStateProperty] rather than plain values for two reasons: the shape
/// stays uniform across ~100 components, and a consumer embedding a spinner
/// inside a control that *does* have states (a loading button, say) can pass
/// that control's state set straight through.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance/size defaults derived from the theme
/// 2. the nearest `FluentSpinnerTheme`
/// 3. the widget's own `style`
@immutable
class FluentSpinnerStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentSpinnerStyle({
    this.trackColor,
    this.indicatorColor,
    this.labelColor,
    this.strokeWidth,
    this.diameter,
    this.textStyle,
    this.gap,
  });

  /// The full-circle rail the tail travels along. Figma calls this layer
  /// `Track`.
  ///
  /// Never `Colors.transparent` and never a computed fade of
  /// [indicatorColor] — Fluent ships a real token for it, and that token turns
  /// opaque in high contrast where a literal would stay invisible.
  final WidgetStateProperty<Color?>? trackColor;

  /// The moving arc drawn over the track. Figma calls this layer `Tail`.
  final WidgetStateProperty<Color?>? indicatorColor;

  /// Label colour. Overrides the colour carried by [textStyle].
  final WidgetStateProperty<Color?>? labelColor;

  /// Ring thickness, for both the track and the tail.
  final WidgetStateProperty<double?>? strokeWidth;

  /// Outer edge length of the ring's square box.
  ///
  /// The stroke is centred on the circle, so the painted circle's radius is
  /// `(diameter - strokeWidth) / 2` and nothing spills outside the box.
  final WidgetStateProperty<double?>? diameter;

  /// Label text style. Its colour is overridden by [labelColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Space between the ring and the label, on whichever axis the label sits.
  final WidgetStateProperty<double?>? gap;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `diameter` keeps
  /// every resolved colour. This is what makes a partial override useful.
  FluentSpinnerStyle merge(FluentSpinnerStyle? other) {
    if (other == null) return this;
    return FluentSpinnerStyle(
      trackColor: other.trackColor ?? trackColor,
      indicatorColor: other.indicatorColor ?? indicatorColor,
      labelColor: other.labelColor ?? labelColor,
      strokeWidth: other.strokeWidth ?? strokeWidth,
      diameter: other.diameter ?? diameter,
      textStyle: other.textStyle ?? textStyle,
      gap: other.gap ?? gap,
    );
  }

  /// This style with the given properties replaced.
  FluentSpinnerStyle copyWith({
    WidgetStateProperty<Color?>? trackColor,
    WidgetStateProperty<Color?>? indicatorColor,
    WidgetStateProperty<Color?>? labelColor,
    WidgetStateProperty<double?>? strokeWidth,
    WidgetStateProperty<double?>? diameter,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<double?>? gap,
  }) => FluentSpinnerStyle(
    trackColor: trackColor ?? this.trackColor,
    indicatorColor: indicatorColor ?? this.indicatorColor,
    labelColor: labelColor ?? this.labelColor,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    diameter: diameter ?? this.diameter,
    textStyle: textStyle ?? this.textStyle,
    gap: gap ?? this.gap,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`, and the one to reach for on a
  /// spinner: with no interaction states to vary over, a spinner override is
  /// almost always a single value.
  static FluentSpinnerStyle from({
    Color? trackColor,
    Color? indicatorColor,
    Color? labelColor,
    double? strokeWidth,
    double? diameter,
    TextStyle? textStyle,
    double? gap,
  }) => FluentSpinnerStyle(
    trackColor: _all(trackColor),
    indicatorColor: _all(indicatorColor),
    labelColor: _all(labelColor),
    strokeWidth: _all(strokeWidth),
    diameter: _all(diameter),
    textStyle: _all(textStyle),
    gap: _all(gap),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentSpinnerStyle &&
      other.trackColor == trackColor &&
      other.indicatorColor == indicatorColor &&
      other.labelColor == labelColor &&
      other.strokeWidth == strokeWidth &&
      other.diameter == diameter &&
      other.textStyle == textStyle &&
      other.gap == gap;

  @override
  int get hashCode => Object.hash(
    trackColor,
    indicatorColor,
    labelColor,
    strokeWidth,
    diameter,
    textStyle,
    gap,
  );
}
