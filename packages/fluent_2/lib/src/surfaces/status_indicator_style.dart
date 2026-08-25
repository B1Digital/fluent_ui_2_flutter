import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentStatusIndicator`.
///
/// Deliberately shaped like Material's `ButtonStyle` and like
/// `FluentButtonStyle`: every visual property is a [WidgetStateProperty], so one
/// override shape covers the whole component library.
///
/// A status indicator is **non-interactive**, so the state set it resolves
/// against is always empty and every property collapses to its rest value. The
/// shape is kept anyway: a consumer restyling ten Fluent components should not
/// have to remember which two of them take a plain value instead.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the category/size defaults derived from the theme
/// 2. the nearest `FluentStatusIndicatorTheme`
/// 3. the widget's own `style`
@immutable
class FluentStatusIndicatorStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentStatusIndicatorStyle({
    this.iconColor,
    this.foregroundColor,
    this.textStyle,
    this.padding,
    this.gap,
    this.iconSize,
    this.minimumSize,
  });

  /// Glyph tint. This is the property the category axis drives — and the only
  /// one that does, which is why it is separate from [foregroundColor].
  final WidgetStateProperty<Color?>? iconColor;

  /// Label colour. `Neutral/Foreground/1/Rest` on every one of the 48 Figma
  /// variants: the status reads from the glyph, never from the text.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Label text style. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Padding around the icon and label. Zero on every Figma variant — the
  /// component hugs its content and leaves spacing to its container.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Space between glyph and label.
  final WidgetStateProperty<double?>? gap;

  /// Glyph edge length.
  final WidgetStateProperty<double?>? iconSize;

  /// Minimum size of the whole indicator.
  ///
  /// Its height doubles as the glyph's line box: Figma centres the icon inside
  /// an `IconHolder` exactly this tall, which is what keeps a 20px glyph
  /// optically centred against a 22px line of text in the large size.
  final WidgetStateProperty<Size?>? minimumSize;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `gap` keeps every
  /// resolved colour. This is what makes a partial override useful.
  FluentStatusIndicatorStyle merge(FluentStatusIndicatorStyle? other) {
    if (other == null) return this;
    return FluentStatusIndicatorStyle(
      iconColor: other.iconColor ?? iconColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
      iconSize: other.iconSize ?? iconSize,
      minimumSize: other.minimumSize ?? minimumSize,
    );
  }

  /// This style with the given properties replaced.
  FluentStatusIndicatorStyle copyWith({
    WidgetStateProperty<Color?>? iconColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<Size?>? minimumSize,
  }) => FluentStatusIndicatorStyle(
    iconColor: iconColor ?? this.iconColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    minimumSize: minimumSize ?? this.minimumSize,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. For this component that is the
  /// *only* case, since it has no interaction states at all.
  static FluentStatusIndicatorStyle from({
    Color? iconColor,
    Color? foregroundColor,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    double? gap,
    double? iconSize,
    Size? minimumSize,
  }) => FluentStatusIndicatorStyle(
    iconColor: _all(iconColor),
    foregroundColor: _all(foregroundColor),
    textStyle: _all(textStyle),
    padding: _all(padding),
    gap: _all(gap),
    iconSize: _all(iconSize),
    minimumSize: _all(minimumSize),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentStatusIndicatorStyle &&
      other.iconColor == iconColor &&
      other.foregroundColor == foregroundColor &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.minimumSize == minimumSize;

  @override
  int get hashCode => Object.hash(
    iconColor,
    foregroundColor,
    textStyle,
    padding,
    gap,
    iconSize,
    minimumSize,
  );
}
