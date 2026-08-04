import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentSlider`.
///
/// Shaped exactly like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed and disabled values live on the
/// property rather than being branched on at build time.
///
/// A slider is painted rather than composed — there is no [DecoratedBox] to
/// read a colour back from — so this struct is also the component's observable
/// surface. `FluentSliderPainter` takes every one of these values as a public
/// field for the same reason.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the size defaults derived from the theme
/// 2. the nearest `FluentSliderTheme`
/// 3. the widget's own `style`
@immutable
class FluentSliderStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentSliderStyle({
    this.railColor,
    this.progressColor,
    this.stepColor,
    this.thumbColor,
    this.thumbInnerColor,
    this.thumbBorderColor,
    this.railThickness,
    this.railInset,
    this.railRadius,
    this.thumbSize,
    this.thumbInnerRadius,
    this.thumbBorderWidth,
    this.minimumSize,
    this.mouseCursor,
  });

  /// The unfilled part of the rail. Upstream's `sliderRailColorVar`.
  final WidgetStateProperty<Color?>? railColor;

  /// The filled part of the rail, from the minimum up to the thumb.
  /// Upstream's `sliderProgressColorVar`.
  final WidgetStateProperty<Color?>? progressColor;

  /// The tick marks a stepped slider draws across the rail.
  final WidgetStateProperty<Color?>? stepColor;

  /// The thumb's centre disc. Upstream's `sliderThumbColorVar`.
  final WidgetStateProperty<Color?>? thumbColor;

  /// The ring between [thumbColor] and [thumbBorderColor].
  ///
  /// Upstream draws it as an inset box shadow rather than a second circle, but
  /// it is a real Fluent token — `colorNeutralBackground1` — not a hole.
  final WidgetStateProperty<Color?>? thumbInnerColor;

  /// The thumb's outline.
  final WidgetStateProperty<Color?>? thumbBorderColor;

  /// Rail height.
  final WidgetStateProperty<double?>? railThickness;

  /// How far the rail stops short of each end of the control.
  ///
  /// Figma's `Rail` frame insets its fill by `Spacing/Horizontal/S` on both
  /// sides, in both sizes — it is not half a thumb, and the thumb travels
  /// exactly between the two insets.
  final WidgetStateProperty<double?>? railInset;

  /// Rail corner radius.
  final WidgetStateProperty<BorderRadius?>? railRadius;

  /// Thumb diameter, outline included.
  final WidgetStateProperty<double?>? thumbSize;

  /// Radius of the thumb's centre disc.
  final WidgetStateProperty<double?>? thumbInnerRadius;

  /// Thumb outline width.
  final WidgetStateProperty<double?>? thumbBorderWidth;

  /// Minimum size of the whole control.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Cursor while hovering.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `thumbSize` keeps
  /// every resolved colour.
  FluentSliderStyle merge(FluentSliderStyle? other) {
    if (other == null) return this;
    return FluentSliderStyle(
      railColor: other.railColor ?? railColor,
      progressColor: other.progressColor ?? progressColor,
      stepColor: other.stepColor ?? stepColor,
      thumbColor: other.thumbColor ?? thumbColor,
      thumbInnerColor: other.thumbInnerColor ?? thumbInnerColor,
      thumbBorderColor: other.thumbBorderColor ?? thumbBorderColor,
      railThickness: other.railThickness ?? railThickness,
      railInset: other.railInset ?? railInset,
      railRadius: other.railRadius ?? railRadius,
      thumbSize: other.thumbSize ?? thumbSize,
      thumbInnerRadius: other.thumbInnerRadius ?? thumbInnerRadius,
      thumbBorderWidth: other.thumbBorderWidth ?? thumbBorderWidth,
      minimumSize: other.minimumSize ?? minimumSize,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentSliderStyle copyWith({
    WidgetStateProperty<Color?>? railColor,
    WidgetStateProperty<Color?>? progressColor,
    WidgetStateProperty<Color?>? stepColor,
    WidgetStateProperty<Color?>? thumbColor,
    WidgetStateProperty<Color?>? thumbInnerColor,
    WidgetStateProperty<Color?>? thumbBorderColor,
    WidgetStateProperty<double?>? railThickness,
    WidgetStateProperty<double?>? railInset,
    WidgetStateProperty<BorderRadius?>? railRadius,
    WidgetStateProperty<double?>? thumbSize,
    WidgetStateProperty<double?>? thumbInnerRadius,
    WidgetStateProperty<double?>? thumbBorderWidth,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentSliderStyle(
    railColor: railColor ?? this.railColor,
    progressColor: progressColor ?? this.progressColor,
    stepColor: stepColor ?? this.stepColor,
    thumbColor: thumbColor ?? this.thumbColor,
    thumbInnerColor: thumbInnerColor ?? this.thumbInnerColor,
    thumbBorderColor: thumbBorderColor ?? this.thumbBorderColor,
    railThickness: railThickness ?? this.railThickness,
    railInset: railInset ?? this.railInset,
    railRadius: railRadius ?? this.railRadius,
    thumbSize: thumbSize ?? this.thumbSize,
    thumbInnerRadius: thumbInnerRadius ?? this.thumbInnerRadius,
    thumbBorderWidth: thumbBorderWidth ?? this.thumbBorderWidth,
    minimumSize: minimumSize ?? this.minimumSize,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentSliderStyle from({
    Color? railColor,
    Color? progressColor,
    Color? stepColor,
    Color? thumbColor,
    Color? thumbInnerColor,
    Color? thumbBorderColor,
    double? railThickness,
    double? railInset,
    BorderRadius? railRadius,
    double? thumbSize,
    double? thumbInnerRadius,
    double? thumbBorderWidth,
    Size? minimumSize,
    MouseCursor? mouseCursor,
  }) => FluentSliderStyle(
    railColor: _all(railColor),
    progressColor: _all(progressColor),
    stepColor: _all(stepColor),
    thumbColor: _all(thumbColor),
    thumbInnerColor: _all(thumbInnerColor),
    thumbBorderColor: _all(thumbBorderColor),
    railThickness: _all(railThickness),
    railInset: _all(railInset),
    railRadius: _all(railRadius),
    thumbSize: _all(thumbSize),
    thumbInnerRadius: _all(thumbInnerRadius),
    thumbBorderWidth: _all(thumbBorderWidth),
    minimumSize: _all(minimumSize),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentSliderStyle &&
      other.railColor == railColor &&
      other.progressColor == progressColor &&
      other.stepColor == stepColor &&
      other.thumbColor == thumbColor &&
      other.thumbInnerColor == thumbInnerColor &&
      other.thumbBorderColor == thumbBorderColor &&
      other.railThickness == railThickness &&
      other.railInset == railInset &&
      other.railRadius == railRadius &&
      other.thumbSize == thumbSize &&
      other.thumbInnerRadius == thumbInnerRadius &&
      other.thumbBorderWidth == thumbBorderWidth &&
      other.minimumSize == minimumSize &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    railColor,
    progressColor,
    stepColor,
    thumbColor,
    thumbInnerColor,
    thumbBorderColor,
    railThickness,
    railInset,
    railRadius,
    thumbSize,
    thumbInnerRadius,
    thumbBorderWidth,
    minimumSize,
    mouseCursor,
  );
}
