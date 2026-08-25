import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentColorArea`.
///
/// Shaped exactly like `FluentSliderStyle`: every visual property is a
/// [WidgetStateProperty], so focus and disabled live on the property rather
/// than being branched on at build time.
///
/// A colour area is painted rather than composed — there is no [DecoratedBox]
/// to read a colour back from — so this struct is also the component's
/// observable surface. `FluentColorAreaPainter` takes every one of these
/// values as a public field for the same reason.
///
/// The three gradients are deliberately *not* here. They are a fixed
/// consequence of the current colour — pure hue at the bottom, white to
/// transparent across, transparent to black down — and upstream hard-codes all
/// three; a caller who wants a different colour model wants a different widget.
/// `FluentColorAreaPainter.saturationRamp` and `.valueRamp` are public consts
/// for anyone who needs to assert them.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the shape defaults derived from the theme
/// 2. the nearest `FluentColorPickerTheme`, then `FluentColorAreaTheme`
/// 3. the widget's own `style`
@immutable
class FluentColorAreaStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentColorAreaStyle({
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.minimumSize,
    this.margin,
    this.thumbSize,
    this.thumbBorderColor,
    this.thumbBorderWidth,
    this.thumbInnerColor,
    this.thumbInnerWidth,
    this.thumbShadow,
    this.mouseCursor,
  });

  /// The outline around the gradient square. Upstream's
  /// `border: 1px solid colorNeutralStroke1`.
  final WidgetStateProperty<Color?>? borderColor;

  /// Width of [borderColor], painted inside the box.
  final WidgetStateProperty<double?>? borderWidth;

  /// Corner radius. `borderRadiusMedium` for a rounded area, zero for a square
  /// one — upstream's `shape` prop.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Smallest the square may be. Upstream's `min-width` / `min-height`, both
  /// 300, border included.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Inset outside the square. Upstream's
  /// `margin-bottom: spacingVerticalSNudge`, which exists to make room for the
  /// thumb's overhang at v = 0.
  final WidgetStateProperty<EdgeInsetsGeometry?>? margin;

  /// Thumb diameter, **outline included** — 22 at rest, 24 while focused,
  /// because upstream's thumb is a content-box 20 plus its border on each side.
  ///
  /// The thumb's centre lands on the colour's coordinate whatever this is: the
  /// `translate(-50%, 50%)` in upstream's CSS cancels the thumb's own size
  /// exactly, which is why growing it on focus does not move it.
  final WidgetStateProperty<double?>? thumbSize;

  /// The thumb's outermost ring. `colorNeutralForeground4` at rest,
  /// `colorStrokeFocus2` while keyboard-focused.
  final WidgetStateProperty<Color?>? thumbBorderColor;

  /// Width of [thumbBorderColor]. `strokeWidthThin` at rest, `strokeWidthThick`
  /// while focused — upstream's focus treatment is the thumb's own border
  /// thickening, not a ring added outside it.
  final WidgetStateProperty<double?>? thumbBorderWidth;

  /// The ring between [thumbBorderColor] and the colour. Upstream's `::before`
  /// border, `colorNeutralBackground1`.
  final WidgetStateProperty<Color?>? thumbInnerColor;

  /// Width of [thumbInnerColor]. Upstream's `strokeWidthThick`.
  final WidgetStateProperty<double?>? thumbInnerWidth;

  /// The thumb's drop shadow. Upstream's `shadow4`.
  final WidgetStateProperty<List<BoxShadow>?>? thumbShadow;

  /// Cursor shown over the square.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour.
  FluentColorAreaStyle merge(FluentColorAreaStyle? other) {
    if (other == null) return this;
    return FluentColorAreaStyle(
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      minimumSize: other.minimumSize ?? minimumSize,
      margin: other.margin ?? margin,
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
  FluentColorAreaStyle copyWith({
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<EdgeInsetsGeometry?>? margin,
    WidgetStateProperty<double?>? thumbSize,
    WidgetStateProperty<Color?>? thumbBorderColor,
    WidgetStateProperty<double?>? thumbBorderWidth,
    WidgetStateProperty<Color?>? thumbInnerColor,
    WidgetStateProperty<double?>? thumbInnerWidth,
    WidgetStateProperty<List<BoxShadow>?>? thumbShadow,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentColorAreaStyle(
    borderColor: borderColor ?? this.borderColor,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    minimumSize: minimumSize ?? this.minimumSize,
    margin: margin ?? this.margin,
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
  static FluentColorAreaStyle from({
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    Size? minimumSize,
    EdgeInsetsGeometry? margin,
    double? thumbSize,
    Color? thumbBorderColor,
    double? thumbBorderWidth,
    Color? thumbInnerColor,
    double? thumbInnerWidth,
    List<BoxShadow>? thumbShadow,
    MouseCursor? mouseCursor,
  }) => FluentColorAreaStyle(
    borderColor: _all(borderColor),
    borderWidth: _all(borderWidth),
    borderRadius: _all(borderRadius),
    minimumSize: _all(minimumSize),
    margin: _all(margin),
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
      other is FluentColorAreaStyle &&
      other.borderColor == borderColor &&
      other.borderWidth == borderWidth &&
      other.borderRadius == borderRadius &&
      other.minimumSize == minimumSize &&
      other.margin == margin &&
      other.thumbSize == thumbSize &&
      other.thumbBorderColor == thumbBorderColor &&
      other.thumbBorderWidth == thumbBorderWidth &&
      other.thumbInnerColor == thumbInnerColor &&
      other.thumbInnerWidth == thumbInnerWidth &&
      other.thumbShadow == thumbShadow &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    borderColor,
    borderWidth,
    borderRadius,
    minimumSize,
    margin,
    thumbSize,
    thumbBorderColor,
    thumbBorderWidth,
    thumbInnerColor,
    thumbInnerWidth,
    thumbShadow,
    mouseCursor,
  );
}
