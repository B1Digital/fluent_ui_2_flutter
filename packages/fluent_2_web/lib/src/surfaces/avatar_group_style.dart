import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentAvatarGroup`.
///
/// Same shape as `FluentAvatarStyle`: nullable [WidgetStateProperty] fields
/// that mean "inherit", merged defaults → subtree theme → the widget's own
/// `style`.
@immutable
class FluentAvatarGroupStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentAvatarGroupStyle({
    this.spacing,
    this.outlineColor,
    this.outlineWidth,
    this.dividerColor,
    this.dividerWidth,
    this.borderRadius,
    this.diameter,
  });

  /// Gap between neighbouring avatars. **Negative** for
  /// `FluentAvatarGroupLayout.stack`, which is how the overlap is expressed.
  final WidgetStateProperty<double?>? spacing;

  /// The ring each avatar takes in a stacked group, so an overlapped avatar
  /// still reads as a separate person.
  final WidgetStateProperty<Color?>? outlineColor;

  /// Width of [outlineColor]. Zero in the spread and pie layouts.
  final WidgetStateProperty<double?>? outlineWidth;

  /// The rule between two pie slices.
  final WidgetStateProperty<Color?>? dividerColor;

  /// Width of [dividerColor].
  final WidgetStateProperty<double?>? dividerWidth;

  /// The pie's own clip, and the outline radius in a stacked group.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// One avatar's edge length. The pie is exactly this big; a spread or stacked
  /// group is this tall.
  final WidgetStateProperty<double?>? diameter;

  /// This style with the non-null properties of [other] layered on top.
  FluentAvatarGroupStyle merge(FluentAvatarGroupStyle? other) {
    if (other == null) return this;
    return FluentAvatarGroupStyle(
      spacing: other.spacing ?? spacing,
      outlineColor: other.outlineColor ?? outlineColor,
      outlineWidth: other.outlineWidth ?? outlineWidth,
      dividerColor: other.dividerColor ?? dividerColor,
      dividerWidth: other.dividerWidth ?? dividerWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      diameter: other.diameter ?? diameter,
    );
  }

  /// This style with the given properties replaced.
  FluentAvatarGroupStyle copyWith({
    WidgetStateProperty<double?>? spacing,
    WidgetStateProperty<Color?>? outlineColor,
    WidgetStateProperty<double?>? outlineWidth,
    WidgetStateProperty<Color?>? dividerColor,
    WidgetStateProperty<double?>? dividerWidth,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<double?>? diameter,
  }) => FluentAvatarGroupStyle(
    spacing: spacing ?? this.spacing,
    outlineColor: outlineColor ?? this.outlineColor,
    outlineWidth: outlineWidth ?? this.outlineWidth,
    dividerColor: dividerColor ?? this.dividerColor,
    dividerWidth: dividerWidth ?? this.dividerWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    diameter: diameter ?? this.diameter,
  );

  /// Convenience for the common case of one value across every state.
  static FluentAvatarGroupStyle from({
    double? spacing,
    Color? outlineColor,
    double? outlineWidth,
    Color? dividerColor,
    double? dividerWidth,
    BorderRadius? borderRadius,
    double? diameter,
  }) => FluentAvatarGroupStyle(
    spacing: _all(spacing),
    outlineColor: _all(outlineColor),
    outlineWidth: _all(outlineWidth),
    dividerColor: _all(dividerColor),
    dividerWidth: _all(dividerWidth),
    borderRadius: _all(borderRadius),
    diameter: _all(diameter),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentAvatarGroupStyle &&
      other.spacing == spacing &&
      other.outlineColor == outlineColor &&
      other.outlineWidth == outlineWidth &&
      other.dividerColor == dividerColor &&
      other.dividerWidth == dividerWidth &&
      other.borderRadius == borderRadius &&
      other.diameter == diameter;

  @override
  int get hashCode => Object.hash(
    spacing,
    outlineColor,
    outlineWidth,
    dividerColor,
    dividerWidth,
    borderRadius,
    diameter,
  );
}
