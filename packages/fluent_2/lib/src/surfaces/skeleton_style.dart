import 'package:flutter/widgets.dart';

import '../internal/animated_style.dart';

/// The visual configuration of a `FluentSkeleton`.
///
/// Shaped exactly like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty] so a Flutter developer reads and overrides it the way
/// they read Material's `ButtonStyle`.
///
/// A skeleton is the one component in the set that never reports an interaction
/// state — it is a placeholder, not a control, so it is not hoverable,
/// pressable, focusable or disableable and every property resolves against an
/// empty state set. The properties stay [WidgetStateProperty] anyway so this
/// style merges, copies and composes identically to every other Fluent style;
/// a uniform shape across ~100 components is worth more than shaving a generic
/// off one of them.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the shape/animation defaults derived from the theme
/// 2. the nearest `FluentSkeletonTheme`
/// 3. the widget's own `style`
@immutable
class FluentSkeletonStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentSkeletonStyle({
    this.backgroundColor,
    this.waveColor,
    this.borderRadius,
    this.motion,
  });

  /// The stencil surface. `neutralStencil1` by default.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// The highlight the wave band sweeps across the surface.
  /// `neutralStencil2` by default.
  ///
  /// Null suppresses the band entirely, which is what a pulse skeleton wants:
  /// upstream's pulse animates opacity over a flat surface and draws no
  /// gradient at all.
  final WidgetStateProperty<Color?>? waveColor;

  /// Corner radius. `borderRadiusMedium` for a rectangle, `borderRadiusCircular`
  /// for a circle.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// The loop the skeleton runs.
  ///
  /// Not a [WidgetStateProperty]: no Fluent component varies its motion by
  /// interaction state, and a skeleton has no interaction state to vary it by.
  final FluentMotionSpec? motion;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `borderRadius`
  /// keeps every resolved colour. This is what makes a partial override useful.
  FluentSkeletonStyle merge(FluentSkeletonStyle? other) {
    if (other == null) return this;
    return FluentSkeletonStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      waveColor: other.waveColor ?? waveColor,
      borderRadius: other.borderRadius ?? borderRadius,
      motion: other.motion ?? motion,
    );
  }

  /// This style with the given properties replaced.
  FluentSkeletonStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? waveColor,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    FluentMotionSpec? motion,
  }) => FluentSkeletonStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    waveColor: waveColor ?? this.waveColor,
    borderRadius: borderRadius ?? this.borderRadius,
    motion: motion ?? this.motion,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state — which, for a skeleton, it
  /// never does.
  static FluentSkeletonStyle from({
    Color? backgroundColor,
    Color? waveColor,
    BorderRadius? borderRadius,
    FluentMotionSpec? motion,
  }) => FluentSkeletonStyle(
    backgroundColor: _all(backgroundColor),
    waveColor: _all(waveColor),
    borderRadius: _all(borderRadius),
    motion: motion,
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentSkeletonStyle &&
      other.backgroundColor == backgroundColor &&
      other.waveColor == waveColor &&
      other.borderRadius == borderRadius &&
      other.motion == motion;

  @override
  int get hashCode =>
      Object.hash(backgroundColor, waveColor, borderRadius, motion);
}
