import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentColorSlider` — and of a
/// `FluentAlphaSlider`, which shares it.
///
/// One struct for both, because upstream shares one too:
/// `useAlphaSliderStyles_unstable` ends by *calling*
/// `useColorSliderStyles_unstable`, and `AlphaSliderSlots` is a type alias for
/// `ColorSliderSlots`. An alpha slider is a colour slider on a fourth channel
/// with a checkerboard behind its rail and a visible rail border; every other
/// value below is identical.
///
/// Shaped exactly like `FluentSliderStyle`: every visual property is a
/// [WidgetStateProperty], and because the rail and thumb are painted rather
/// than composed, this struct is also the component's observable surface —
/// `FluentColorSliderPainter` takes every one of these values as a public
/// field so tests can read the resolved tokens back.
///
/// The rail's gradient is not here: it is a fixed consequence of the channel
/// and the current colour, and upstream hard-codes all four ramps. The hue
/// ramp is `FluentColorSliderPainter.hueRamp`, a public const.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the channel and shape defaults derived from the theme
/// 2. the nearest `FluentColorPickerTheme`, then `FluentColorSliderTheme`
/// 3. the widget's own `style`
@immutable
class FluentColorSliderStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentColorSliderStyle({
    this.railThickness,
    this.railRadius,
    this.railBorderColor,
    this.railBorderWidth,
    this.minimumSize,
    this.thumbSize,
    this.thumbBorderColor,
    this.thumbBorderWidth,
    this.thumbInnerColor,
    this.thumbInnerWidth,
    this.thumbShadow,
    this.mouseCursor,
  });

  /// Rail depth across the slider — height when horizontal, width when
  /// vertical. Upstream's `--fui-Slider__rail--size`, 20 in both orientations.
  final WidgetStateProperty<double?>? railThickness;

  /// Rail corner radius. `borderRadiusMedium` when rounded, zero when square.
  final WidgetStateProperty<BorderRadius?>? railRadius;

  /// The rail's outline.
  ///
  /// `colorTransparentStroke` on hue, saturation and value — invisible on every
  /// ordinary surface and a real edge under forced colours, which is exactly
  /// why it is this token and not [Color] transparent. `colorNeutralStroke1`
  /// on an alpha rail, where upstream draws a visible border so the
  /// checkerboard reads as part of the control.
  final WidgetStateProperty<Color?>? railBorderColor;

  /// Width of [railBorderColor], painted inside the rail.
  final WidgetStateProperty<double?>? railBorderWidth;

  /// Smallest the whole control may be: 200 x 32 horizontal, 20 x 280
  /// vertical. Upstream's `min-width` / `min-height` per orientation.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Thumb diameter, **outline included** — 22 at rest, 24 while focused. See
  /// `FluentColorAreaStyle.thumbSize`; the two thumbs are the same object.
  final WidgetStateProperty<double?>? thumbSize;

  /// The thumb's outermost ring. `colorNeutralForeground4` at rest,
  /// `colorStrokeFocus2` while keyboard-focused — upstream's
  /// `input:focus-visible ~ .thumb` rule.
  final WidgetStateProperty<Color?>? thumbBorderColor;

  /// Width of [thumbBorderColor]. `strokeWidthThin` at rest,
  /// `strokeWidthThick` while focused.
  final WidgetStateProperty<double?>? thumbBorderWidth;

  /// The ring between [thumbBorderColor] and the colour. Upstream's `::before`
  /// border, `colorNeutralBackground1`.
  ///
  /// On an alpha slider it is also the thumb's *fill*, which is why a
  /// half-transparent colour reads as itself over a solid surface rather than
  /// over the rail's checkerboard.
  final WidgetStateProperty<Color?>? thumbInnerColor;

  /// Width of [thumbInnerColor]. Upstream's `strokeWidthThick`.
  final WidgetStateProperty<double?>? thumbInnerWidth;

  /// The thumb's drop shadow. Upstream's `shadow4`.
  final WidgetStateProperty<List<BoxShadow>?>? thumbShadow;

  /// Cursor shown over the control. Upstream puts `cursor: pointer` on the
  /// input, which spans the whole grid.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `railRadius`
  /// keeps every resolved colour.
  FluentColorSliderStyle merge(FluentColorSliderStyle? other) {
    if (other == null) return this;
    return FluentColorSliderStyle(
      railThickness: other.railThickness ?? railThickness,
      railRadius: other.railRadius ?? railRadius,
      railBorderColor: other.railBorderColor ?? railBorderColor,
      railBorderWidth: other.railBorderWidth ?? railBorderWidth,
      minimumSize: other.minimumSize ?? minimumSize,
      thumbSize: other.thumbSize ?? thumbSize,
      thumbBorderColor: other.thumbBorderColor ?? thumbBorderColor,
      thumbBorderWidth: other.thumbBorderWidth ?? thumbBorderWidth,
      thumbInnerColor: other.thumbInnerColor ?? thumbInnerColor,
      thumbInnerWidth: other.thumbInnerWidth ?? thumbInnerWidth,
      thumbShadow: other.thumbShadow ?? thumbShadow,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentColorSliderStyle copyWith({
    WidgetStateProperty<double?>? railThickness,
    WidgetStateProperty<BorderRadius?>? railRadius,
    WidgetStateProperty<Color?>? railBorderColor,
    WidgetStateProperty<double?>? railBorderWidth,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<double?>? thumbSize,
    WidgetStateProperty<Color?>? thumbBorderColor,
    WidgetStateProperty<double?>? thumbBorderWidth,
    WidgetStateProperty<Color?>? thumbInnerColor,
    WidgetStateProperty<double?>? thumbInnerWidth,
    WidgetStateProperty<List<BoxShadow>?>? thumbShadow,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentColorSliderStyle(
    railThickness: railThickness ?? this.railThickness,
    railRadius: railRadius ?? this.railRadius,
    railBorderColor: railBorderColor ?? this.railBorderColor,
    railBorderWidth: railBorderWidth ?? this.railBorderWidth,
    minimumSize: minimumSize ?? this.minimumSize,
    thumbSize: thumbSize ?? this.thumbSize,
    thumbBorderColor: thumbBorderColor ?? this.thumbBorderColor,
    thumbBorderWidth: thumbBorderWidth ?? this.thumbBorderWidth,
    thumbInnerColor: thumbInnerColor ?? this.thumbInnerColor,
    thumbInnerWidth: thumbInnerWidth ?? this.thumbInnerWidth,
    thumbShadow: thumbShadow ?? this.thumbShadow,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state — the thumb's border does,
  /// which is the whole of the focus treatment.
  static FluentColorSliderStyle from({
    double? railThickness,
    BorderRadius? railRadius,
    Color? railBorderColor,
    double? railBorderWidth,
    Size? minimumSize,
    double? thumbSize,
    Color? thumbBorderColor,
    double? thumbBorderWidth,
    Color? thumbInnerColor,
    double? thumbInnerWidth,
    List<BoxShadow>? thumbShadow,
    MouseCursor? mouseCursor,
  }) => FluentColorSliderStyle(
    railThickness: _all(railThickness),
    railRadius: _all(railRadius),
    railBorderColor: _all(railBorderColor),
    railBorderWidth: _all(railBorderWidth),
    minimumSize: _all(minimumSize),
    thumbSize: _all(thumbSize),
    thumbBorderColor: _all(thumbBorderColor),
    thumbBorderWidth: _all(thumbBorderWidth),
    thumbInnerColor: _all(thumbInnerColor),
    thumbInnerWidth: _all(thumbInnerWidth),
    thumbShadow: _all(thumbShadow),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentColorSliderStyle &&
      other.railThickness == railThickness &&
      other.railRadius == railRadius &&
      other.railBorderColor == railBorderColor &&
      other.railBorderWidth == railBorderWidth &&
      other.minimumSize == minimumSize &&
      other.thumbSize == thumbSize &&
      other.thumbBorderColor == thumbBorderColor &&
      other.thumbBorderWidth == thumbBorderWidth &&
      other.thumbInnerColor == thumbInnerColor &&
      other.thumbInnerWidth == thumbInnerWidth &&
      other.thumbShadow == thumbShadow &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    railThickness,
    railRadius,
    railBorderColor,
    railBorderWidth,
    minimumSize,
    thumbSize,
    thumbBorderColor,
    thumbBorderWidth,
    thumbInnerColor,
    thumbInnerWidth,
    thumbShadow,
    mouseCursor,
  );
}
