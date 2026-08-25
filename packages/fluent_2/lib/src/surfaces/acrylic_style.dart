import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentAcrylicSurface`.
///
/// Shaped exactly like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so a caller can drive the material from a parent's
/// interaction set if they want one. Acrylic itself has no states — Figma's
/// `Material acrylic` set is a single variant with no State axis — so the
/// resolver below fills every property with a [WidgetStatePropertyAll].
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the theme defaults from `resolveFluentAcrylicSurfaceStyle`
/// 2. the nearest `FluentAcrylicSurfaceTheme`
/// 3. the widget's own `style`
@immutable
class FluentAcrylicSurfaceStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentAcrylicSurfaceStyle({
    this.backgroundPrimary,
    this.backgroundSecondary,
    this.backgroundBlur,
    this.strokeStop1,
    this.strokeStop2,
    this.strokeStop3,
    this.strokeWidth,
    this.borderRadius,
    this.padding,
  });

  /// The upper tint, `Material/Acrylic/Background/Primary`.
  ///
  /// Painted *over* [backgroundSecondary]. The order is load-bearing: two
  /// translucent paints do not commute, and Figma paints the last one on top.
  final WidgetStateProperty<Color?>? backgroundPrimary;

  /// The lower tint, `Material/Acrylic/Background/Secondary`, painted directly
  /// on the blurred backdrop.
  final WidgetStateProperty<Color?>? backgroundSecondary;

  /// The backdrop blur **radius** in logical pixels, as Figma and CSS
  /// `filter: blur()` express it — `Material/Acrylic/Background/Blur`.
  ///
  /// Not a Gaussian sigma. `ImageFilter.blur` takes sigma, so the renderer
  /// halves this. Zero suppresses the backdrop filter altogether, which is what
  /// high contrast resolves to.
  final WidgetStateProperty<double?>? backgroundBlur;

  /// First stop of the hairline gradient, `Material/Acrylic/Stroke/Stop 1`, at
  /// gradient position 0.
  final WidgetStateProperty<Color?>? strokeStop1;

  /// Middle stop, `Material/Acrylic/Stroke/Stop 2`, at gradient position 0.5.
  ///
  /// Fully opaque in dark while its two siblings stay at `0x33` alpha. That
  /// asymmetry is real; see `doc/token-divergences.md`.
  final WidgetStateProperty<Color?>? strokeStop2;

  /// Last stop, `Material/Acrylic/Stroke/Stop 3`, at gradient position 1.
  final WidgetStateProperty<Color?>? strokeStop3;

  /// Hairline width. Zero paints no border, which is not the same as three
  /// transparent stops — a zero-width stroke cannot become visible anywhere.
  final WidgetStateProperty<double?>? strokeWidth;

  /// Corner radius. Figma binds this to the remote `material-radius` variable
  /// from the `MaterialShape` collection, whose modes are None, Small, Medium,
  /// Large, X-Large and Circular.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Inset applied to the content, inside the hairline.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour.
  FluentAcrylicSurfaceStyle merge(FluentAcrylicSurfaceStyle? other) {
    if (other == null) return this;
    return FluentAcrylicSurfaceStyle(
      backgroundPrimary: other.backgroundPrimary ?? backgroundPrimary,
      backgroundSecondary: other.backgroundSecondary ?? backgroundSecondary,
      backgroundBlur: other.backgroundBlur ?? backgroundBlur,
      strokeStop1: other.strokeStop1 ?? strokeStop1,
      strokeStop2: other.strokeStop2 ?? strokeStop2,
      strokeStop3: other.strokeStop3 ?? strokeStop3,
      strokeWidth: other.strokeWidth ?? strokeWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
    );
  }

  /// This style with the given properties replaced.
  FluentAcrylicSurfaceStyle copyWith({
    WidgetStateProperty<Color?>? backgroundPrimary,
    WidgetStateProperty<Color?>? backgroundSecondary,
    WidgetStateProperty<double?>? backgroundBlur,
    WidgetStateProperty<Color?>? strokeStop1,
    WidgetStateProperty<Color?>? strokeStop2,
    WidgetStateProperty<Color?>? strokeStop3,
    WidgetStateProperty<double?>? strokeWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
  }) => FluentAcrylicSurfaceStyle(
    backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
    backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
    backgroundBlur: backgroundBlur ?? this.backgroundBlur,
    strokeStop1: strokeStop1 ?? this.strokeStop1,
    strokeStop2: strokeStop2 ?? this.strokeStop2,
    strokeStop3: strokeStop3 ?? this.strokeStop3,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    padding: padding ?? this.padding,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`, and the constructor almost
  /// every caller wants here — a material has no states to differ across.
  static FluentAcrylicSurfaceStyle from({
    Color? backgroundPrimary,
    Color? backgroundSecondary,
    double? backgroundBlur,
    Color? strokeStop1,
    Color? strokeStop2,
    Color? strokeStop3,
    double? strokeWidth,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
  }) => FluentAcrylicSurfaceStyle(
    backgroundPrimary: _all(backgroundPrimary),
    backgroundSecondary: _all(backgroundSecondary),
    backgroundBlur: _all(backgroundBlur),
    strokeStop1: _all(strokeStop1),
    strokeStop2: _all(strokeStop2),
    strokeStop3: _all(strokeStop3),
    strokeWidth: _all(strokeWidth),
    borderRadius: _all(borderRadius),
    padding: _all(padding),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentAcrylicSurfaceStyle &&
      other.backgroundPrimary == backgroundPrimary &&
      other.backgroundSecondary == backgroundSecondary &&
      other.backgroundBlur == backgroundBlur &&
      other.strokeStop1 == strokeStop1 &&
      other.strokeStop2 == strokeStop2 &&
      other.strokeStop3 == strokeStop3 &&
      other.strokeWidth == strokeWidth &&
      other.borderRadius == borderRadius &&
      other.padding == padding;

  @override
  int get hashCode => Object.hash(
    backgroundPrimary,
    backgroundSecondary,
    backgroundBlur,
    strokeStop1,
    strokeStop2,
    strokeStop3,
    strokeWidth,
    borderRadius,
    padding,
  );
}
