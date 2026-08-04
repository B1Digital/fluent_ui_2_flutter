import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentSwatchPicker`.
///
/// Same shape as `FluentButtonStyle` and `FluentSwatchStyle`: every property
/// is a [WidgetStateProperty] and every field is nullable, meaning "inherit".
/// A picker has no interaction states of its own — it is a container, not a
/// control — so in practice every property resolves the same value for every
/// state. The shape is kept anyway so a caller who already knows one Fluent
/// style knows this one.
///
/// Resolution order, lowest to highest precedence:
///
/// 1. the size and spacing defaults derived from the theme
/// 2. the nearest `FluentSwatchPickerTheme`
/// 3. the widget's own `style`
@immutable
class FluentSwatchPickerStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentSwatchPickerStyle({this.padding, this.spacing});

  /// Inset between the picker's edge and its swatches.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Gap between adjacent swatches, on both axes.
  final WidgetStateProperty<double?>? spacing;

  /// This style with the non-null properties of [other] layered on top.
  FluentSwatchPickerStyle merge(FluentSwatchPickerStyle? other) {
    if (other == null) return this;
    return FluentSwatchPickerStyle(
      padding: other.padding ?? padding,
      spacing: other.spacing ?? spacing,
    );
  }

  /// This style with the given properties replaced.
  FluentSwatchPickerStyle copyWith({
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? spacing,
  }) => FluentSwatchPickerStyle(
    padding: padding ?? this.padding,
    spacing: spacing ?? this.spacing,
  );

  /// Convenience for the common case of one value across every state.
  static FluentSwatchPickerStyle from({
    EdgeInsetsGeometry? padding,
    double? spacing,
  }) => FluentSwatchPickerStyle(padding: _all(padding), spacing: _all(spacing));

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentSwatchPickerStyle &&
      other.padding == padding &&
      other.spacing == spacing;

  @override
  int get hashCode => Object.hash(padding, spacing);
}
