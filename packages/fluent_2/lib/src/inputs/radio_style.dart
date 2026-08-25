import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentRadio`.
///
/// The same shape as `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed and disabled values live on the
/// property rather than being branched on at build time.
///
/// A radio's *checked* value is deliberately **not** a [WidgetState] here.
/// Fluent swaps the whole token family when a radio is checked — the ring goes
/// from `Neutral/Stroke/Accessible/*` to `Compound brand/Stroke/*` — so
/// `checked` is a design axis carried on `FluentRadioState`, exactly like a
/// button's appearance, and each of the two families resolves its own
/// rest/hover/pressed/disabled set. [WidgetState.selected] stays reserved for
/// components that have real Fluent `*Selected` tokens.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the checked/label-position defaults derived from the theme
/// 2. the nearest `FluentRadioTheme`
/// 3. the widget's own `style`
///
/// The consumer's own style therefore wins, matching upstream's rule that
/// `props.className` is passed last to `mergeClasses`.
@immutable
class FluentRadioStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentRadioStyle({
    this.indicatorColor,
    this.indicatorFillColor,
    this.foregroundColor,
    this.textStyle,
    this.indicatorSize,
    this.indicatorFillSize,
    this.indicatorBorderWidth,
    this.indicatorPadding,
    this.labelPadding,
    this.borderRadius,
    this.mouseCursor,
  });

  /// The ring around the indicator.
  ///
  /// Never transparent in any state: it is the only thing that marks an
  /// unchecked radio, so a transparent value would erase the control.
  final WidgetStateProperty<Color?>? indicatorColor;

  /// The dot inside the indicator, painted only while checked.
  ///
  /// Upstream sets the indicator's `color` and fills the `::after` circle with
  /// `currentColor`, which is why ring and dot track each other but are not the
  /// same token: the ring is a `Stroke`, the dot a `Foreground`.
  final WidgetStateProperty<Color?>? indicatorFillColor;

  /// Label colour.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Label text style. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Indicator edge length. 16 upstream, in every variant.
  final WidgetStateProperty<double?>? indicatorSize;

  /// Diameter of the checked dot.
  ///
  /// Upstream draws a full-size circle and applies `transform: scale(0.625)` to
  /// dodge a pixel-rounding bug at 125% DPI; 16 x 0.625 is 10, and a canvas has
  /// no such rounding problem, so this is stated as the diameter it resolves to.
  final WidgetStateProperty<double?>? indicatorFillSize;

  /// Ring width. Drawn *inside* the indicator box, matching upstream's
  /// `boxSizing: border-box`.
  final WidgetStateProperty<double?>? indicatorBorderWidth;

  /// Space around the indicator. Upstream's `margin` on the indicator slot.
  final WidgetStateProperty<EdgeInsetsGeometry?>? indicatorPadding;

  /// Space around the label. Differs by label position.
  final WidgetStateProperty<EdgeInsetsGeometry?>? labelPadding;

  /// Corner radius of the keyboard focus ring, which surrounds the whole
  /// control rather than just the indicator.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Cursor while hovering.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only [indicatorSize]
  /// keeps every resolved colour. This is what makes a partial override useful.
  FluentRadioStyle merge(FluentRadioStyle? other) {
    if (other == null) return this;
    return FluentRadioStyle(
      indicatorColor: other.indicatorColor ?? indicatorColor,
      indicatorFillColor: other.indicatorFillColor ?? indicatorFillColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      textStyle: other.textStyle ?? textStyle,
      indicatorSize: other.indicatorSize ?? indicatorSize,
      indicatorFillSize: other.indicatorFillSize ?? indicatorFillSize,
      indicatorBorderWidth: other.indicatorBorderWidth ?? indicatorBorderWidth,
      indicatorPadding: other.indicatorPadding ?? indicatorPadding,
      labelPadding: other.labelPadding ?? labelPadding,
      borderRadius: other.borderRadius ?? borderRadius,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentRadioStyle copyWith({
    WidgetStateProperty<Color?>? indicatorColor,
    WidgetStateProperty<Color?>? indicatorFillColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<double?>? indicatorSize,
    WidgetStateProperty<double?>? indicatorFillSize,
    WidgetStateProperty<double?>? indicatorBorderWidth,
    WidgetStateProperty<EdgeInsetsGeometry?>? indicatorPadding,
    WidgetStateProperty<EdgeInsetsGeometry?>? labelPadding,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentRadioStyle(
    indicatorColor: indicatorColor ?? this.indicatorColor,
    indicatorFillColor: indicatorFillColor ?? this.indicatorFillColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    textStyle: textStyle ?? this.textStyle,
    indicatorSize: indicatorSize ?? this.indicatorSize,
    indicatorFillSize: indicatorFillSize ?? this.indicatorFillSize,
    indicatorBorderWidth: indicatorBorderWidth ?? this.indicatorBorderWidth,
    indicatorPadding: indicatorPadding ?? this.indicatorPadding,
    labelPadding: labelPadding ?? this.labelPadding,
    borderRadius: borderRadius ?? this.borderRadius,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentRadioStyle from({
    Color? indicatorColor,
    Color? indicatorFillColor,
    Color? foregroundColor,
    TextStyle? textStyle,
    double? indicatorSize,
    double? indicatorFillSize,
    double? indicatorBorderWidth,
    EdgeInsetsGeometry? indicatorPadding,
    EdgeInsetsGeometry? labelPadding,
    BorderRadius? borderRadius,
    MouseCursor? mouseCursor,
  }) => FluentRadioStyle(
    indicatorColor: _all(indicatorColor),
    indicatorFillColor: _all(indicatorFillColor),
    foregroundColor: _all(foregroundColor),
    textStyle: _all(textStyle),
    indicatorSize: _all(indicatorSize),
    indicatorFillSize: _all(indicatorFillSize),
    indicatorBorderWidth: _all(indicatorBorderWidth),
    indicatorPadding: _all(indicatorPadding),
    labelPadding: _all(labelPadding),
    borderRadius: _all(borderRadius),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentRadioStyle &&
      other.indicatorColor == indicatorColor &&
      other.indicatorFillColor == indicatorFillColor &&
      other.foregroundColor == foregroundColor &&
      other.textStyle == textStyle &&
      other.indicatorSize == indicatorSize &&
      other.indicatorFillSize == indicatorFillSize &&
      other.indicatorBorderWidth == indicatorBorderWidth &&
      other.indicatorPadding == indicatorPadding &&
      other.labelPadding == labelPadding &&
      other.borderRadius == borderRadius &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    indicatorColor,
    indicatorFillColor,
    foregroundColor,
    textStyle,
    indicatorSize,
    indicatorFillSize,
    indicatorBorderWidth,
    indicatorPadding,
    labelPadding,
    borderRadius,
    mouseCursor,
  );
}
