import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentLabel`.
///
/// The same shape as `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so the disabled value lives on the property rather
/// than being branched on at build time. A label is not interactive, so the
/// only state it ever resolves against is [WidgetState.disabled] — but it
/// resolves it the same way every other Fluent component does, which is what
/// keeps `disabled` a real state instead of a visual treatment.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the size/weight defaults derived from the theme
/// 2. the nearest `FluentLabelTheme`
/// 3. the widget's own `style`
///
/// The consumer's own style therefore wins, matching upstream's rule that
/// `props.className` is passed last to `mergeClasses`.
@immutable
class FluentLabelStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentLabelStyle({
    this.foregroundColor,
    this.requiredColor,
    this.textStyle,
    this.gap,
  });

  /// Label text colour.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Required-field asterisk colour.
  ///
  /// A separate property rather than a tint of [foregroundColor]: Figma binds
  /// the asterisk to `Status/Danger/Foreground/3/Rest` while enabled and to
  /// `Neutral/Foreground/Disabled/Rest` while disabled, which is two unrelated
  /// tokens rather than one colour under two treatments.
  final WidgetStateProperty<Color?>? requiredColor;

  /// The type ramp step. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Space between the label and the asterisk.
  final WidgetStateProperty<double?>? gap;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only [gap] keeps every
  /// resolved colour. This is what makes a partial override useful.
  FluentLabelStyle merge(FluentLabelStyle? other) {
    if (other == null) return this;
    return FluentLabelStyle(
      foregroundColor: other.foregroundColor ?? foregroundColor,
      requiredColor: other.requiredColor ?? requiredColor,
      textStyle: other.textStyle ?? textStyle,
      gap: other.gap ?? gap,
    );
  }

  /// This style with the given properties replaced.
  FluentLabelStyle copyWith({
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? requiredColor,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<double?>? gap,
  }) => FluentLabelStyle(
    foregroundColor: foregroundColor ?? this.foregroundColor,
    requiredColor: requiredColor ?? this.requiredColor,
    textStyle: textStyle ?? this.textStyle,
    gap: gap ?? this.gap,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentLabelStyle from({
    Color? foregroundColor,
    Color? requiredColor,
    TextStyle? textStyle,
    double? gap,
  }) => FluentLabelStyle(
    foregroundColor: _all(foregroundColor),
    requiredColor: _all(requiredColor),
    textStyle: _all(textStyle),
    gap: _all(gap),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentLabelStyle &&
      other.foregroundColor == foregroundColor &&
      other.requiredColor == requiredColor &&
      other.textStyle == textStyle &&
      other.gap == gap;

  @override
  int get hashCode =>
      Object.hash(foregroundColor, requiredColor, textStyle, gap);
}
