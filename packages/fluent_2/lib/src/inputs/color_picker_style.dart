import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentColorPicker`.
///
/// Shaped exactly like `FluentSliderStyle`: every visual property is a
/// [WidgetStateProperty], every field is nullable and means "inherit".
///
/// A picker is a container, not a control — it has no interaction states of its
/// own, so in practice the one property here resolves the same value for every
/// state. The shape is kept anyway so a caller who knows one Fluent style knows
/// this one. Everything a colour picker actually *looks* like lives on
/// `FluentColorAreaStyle` and `FluentColorSliderStyle`; upstream's
/// `useColorPickerStyles.styles.ts` is likewise three declarations long.
///
/// Resolution order, lowest to highest precedence:
///
/// 1. the defaults derived from the theme
/// 2. the nearest `FluentColorPickerTheme`
/// 3. the widget's own `style`
@immutable
class FluentColorPickerStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentColorPickerStyle({this.spacing});

  /// Gap between the picker's children.
  ///
  /// Upstream's `gap: spacingVerticalXS` on the root flex column. Note the
  /// colour area adds `marginBottom: spacingVerticalSNudge` of its own, so the
  /// gap below it is 4 + 6 = 10 — that margin is
  /// `FluentColorAreaStyle.margin`, not this.
  final WidgetStateProperty<double?>? spacing;

  /// This style with the non-null properties of [other] layered on top.
  FluentColorPickerStyle merge(FluentColorPickerStyle? other) {
    if (other == null) return this;
    return FluentColorPickerStyle(spacing: other.spacing ?? spacing);
  }

  /// This style with the given properties replaced.
  FluentColorPickerStyle copyWith({WidgetStateProperty<double?>? spacing}) =>
      FluentColorPickerStyle(spacing: spacing ?? this.spacing);

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`.
  static FluentColorPickerStyle from({double? spacing}) =>
      FluentColorPickerStyle(spacing: _all(spacing));

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentColorPickerStyle && other.spacing == spacing;

  @override
  int get hashCode => spacing.hashCode;
}
