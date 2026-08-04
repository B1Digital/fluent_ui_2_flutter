import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentSwitch`.
///
/// The same shape as `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed and disabled values live on the
/// property rather than being branched on at build time.
///
/// The checked/unchecked axis is deliberately **not** a [WidgetState] here.
/// [WidgetState.selected] is reserved for Fluent's real `*Selected` tokens, and
/// a checked switch reaches for an entirely different family
/// (`compoundBrandBackground*`, `neutralForegroundInverted`) rather than a
/// selected variant of its resting one. Checked is therefore part of
/// `FluentSwitchState`, exactly as `appearance` is for a button, and
/// `resolveFluentSwitchStyle` returns a different token set for each.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the size/checked defaults derived from the theme
/// 2. the nearest `FluentSwitchTheme`
/// 3. the widget's own `style`
///
/// The consumer's own style therefore wins, matching upstream's rule that
/// `props.className` is passed last to `mergeClasses`.
@immutable
class FluentSwitchStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentSwitchStyle({
    this.trackColor,
    this.trackBorderColor,
    this.trackBorderWidth,
    this.trackBorderRadius,
    this.thumbColor,
    this.labelColor,
    this.textStyle,
    this.trackSize,
    this.thumbSize,
    this.thumbTravel,
    this.trackPadding,
    this.labelPadding,
    this.mouseCursor,
  });

  /// Track fill. Transparent while unchecked — as a token, never as
  /// `Colors.transparent`.
  final WidgetStateProperty<Color?>? trackColor;

  /// Track outline colour. Null and transparent are different: Fluent's
  /// `transparentStroke` becomes opaque `CanvasText` in high contrast, which is
  /// the only thing outlining a checked switch there.
  final WidgetStateProperty<Color?>? trackBorderColor;

  /// Track outline width. Upstream declares `border: 1px solid` on the
  /// indicator in every state, checked included.
  final WidgetStateProperty<double?>? trackBorderWidth;

  /// Track corner radius. `borderRadiusCircular` upstream.
  final WidgetStateProperty<BorderRadius?>? trackBorderRadius;

  /// Thumb fill. Upstream paints it with the indicator's `color`, which is why
  /// it transitions on the same spec as the track.
  final WidgetStateProperty<Color?>? thumbColor;

  /// Label colour. Separate from [thumbColor] because upstream recolours the
  /// label only for disabled, and never on hover or press.
  final WidgetStateProperty<Color?>? labelColor;

  /// Label text style. Its colour is overridden by [labelColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Outer size of the track, border included — upstream sets
  /// `box-sizing: border-box`, so the 1px outline eats into these numbers
  /// rather than growing them.
  final WidgetStateProperty<Size?>? trackSize;

  /// Painted diameter of the thumb.
  final WidgetStateProperty<double?>? thumbSize;

  /// How far the thumb travels when checked, in the reading direction.
  ///
  /// A hardcoded distance rather than a fraction of the track: upstream writes
  /// `translateX(20px)` for medium and `translateX(16px)` for small, and
  /// griffel mirrors it under RTL.
  final WidgetStateProperty<double?>? thumbTravel;

  /// Space around the track. Upstream's `margin` on the indicator.
  final WidgetStateProperty<EdgeInsetsGeometry?>? trackPadding;

  /// Space around the label. Directional, because upstream shrinks the padding
  /// on whichever side faces the track.
  final WidgetStateProperty<EdgeInsetsGeometry?>? labelPadding;

  /// Cursor while hovering.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only [thumbSize] keeps
  /// every resolved colour. This is what makes a partial override useful.
  FluentSwitchStyle merge(FluentSwitchStyle? other) {
    if (other == null) return this;
    return FluentSwitchStyle(
      trackColor: other.trackColor ?? trackColor,
      trackBorderColor: other.trackBorderColor ?? trackBorderColor,
      trackBorderWidth: other.trackBorderWidth ?? trackBorderWidth,
      trackBorderRadius: other.trackBorderRadius ?? trackBorderRadius,
      thumbColor: other.thumbColor ?? thumbColor,
      labelColor: other.labelColor ?? labelColor,
      textStyle: other.textStyle ?? textStyle,
      trackSize: other.trackSize ?? trackSize,
      thumbSize: other.thumbSize ?? thumbSize,
      thumbTravel: other.thumbTravel ?? thumbTravel,
      trackPadding: other.trackPadding ?? trackPadding,
      labelPadding: other.labelPadding ?? labelPadding,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentSwitchStyle copyWith({
    WidgetStateProperty<Color?>? trackColor,
    WidgetStateProperty<Color?>? trackBorderColor,
    WidgetStateProperty<double?>? trackBorderWidth,
    WidgetStateProperty<BorderRadius?>? trackBorderRadius,
    WidgetStateProperty<Color?>? thumbColor,
    WidgetStateProperty<Color?>? labelColor,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<Size?>? trackSize,
    WidgetStateProperty<double?>? thumbSize,
    WidgetStateProperty<double?>? thumbTravel,
    WidgetStateProperty<EdgeInsetsGeometry?>? trackPadding,
    WidgetStateProperty<EdgeInsetsGeometry?>? labelPadding,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentSwitchStyle(
    trackColor: trackColor ?? this.trackColor,
    trackBorderColor: trackBorderColor ?? this.trackBorderColor,
    trackBorderWidth: trackBorderWidth ?? this.trackBorderWidth,
    trackBorderRadius: trackBorderRadius ?? this.trackBorderRadius,
    thumbColor: thumbColor ?? this.thumbColor,
    labelColor: labelColor ?? this.labelColor,
    textStyle: textStyle ?? this.textStyle,
    trackSize: trackSize ?? this.trackSize,
    thumbSize: thumbSize ?? this.thumbSize,
    thumbTravel: thumbTravel ?? this.thumbTravel,
    trackPadding: trackPadding ?? this.trackPadding,
    labelPadding: labelPadding ?? this.labelPadding,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentSwitchStyle from({
    Color? trackColor,
    Color? trackBorderColor,
    double? trackBorderWidth,
    BorderRadius? trackBorderRadius,
    Color? thumbColor,
    Color? labelColor,
    TextStyle? textStyle,
    Size? trackSize,
    double? thumbSize,
    double? thumbTravel,
    EdgeInsetsGeometry? trackPadding,
    EdgeInsetsGeometry? labelPadding,
    MouseCursor? mouseCursor,
  }) => FluentSwitchStyle(
    trackColor: _all(trackColor),
    trackBorderColor: _all(trackBorderColor),
    trackBorderWidth: _all(trackBorderWidth),
    trackBorderRadius: _all(trackBorderRadius),
    thumbColor: _all(thumbColor),
    labelColor: _all(labelColor),
    textStyle: _all(textStyle),
    trackSize: _all(trackSize),
    thumbSize: _all(thumbSize),
    thumbTravel: _all(thumbTravel),
    trackPadding: _all(trackPadding),
    labelPadding: _all(labelPadding),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentSwitchStyle &&
      other.trackColor == trackColor &&
      other.trackBorderColor == trackBorderColor &&
      other.trackBorderWidth == trackBorderWidth &&
      other.trackBorderRadius == trackBorderRadius &&
      other.thumbColor == thumbColor &&
      other.labelColor == labelColor &&
      other.textStyle == textStyle &&
      other.trackSize == trackSize &&
      other.thumbSize == thumbSize &&
      other.thumbTravel == thumbTravel &&
      other.trackPadding == trackPadding &&
      other.labelPadding == labelPadding &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    trackColor,
    trackBorderColor,
    trackBorderWidth,
    trackBorderRadius,
    thumbColor,
    labelColor,
    textStyle,
    trackSize,
    thumbSize,
    thumbTravel,
    trackPadding,
    labelPadding,
    mouseCursor,
  );
}
