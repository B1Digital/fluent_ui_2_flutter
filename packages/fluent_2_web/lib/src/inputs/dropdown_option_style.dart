import 'package:flutter/widgets.dart';

/// The visual configuration of one row in a `FluentDropdown` popup.
///
/// Separate from `FluentDropdownStyle` because the row is a separate Figma
/// component set (`.ListItem`) with its own State axis, and because a consumer
/// restyling rows almost never wants to restate the trigger's twenty fields.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence: the defaults derived from the theme, then the nearest
/// `FluentDropdownOptionTheme`, then the widget's own `optionStyle`.
@immutable
class FluentDropdownOptionStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentDropdownOptionStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.checkmarkColor,
    this.checkmarkSize,
    this.checkmarkPadding,
    this.borderRadius,
    this.textStyle,
    this.padding,
    this.labelPadding,
    this.gap,
    this.minimumSize,
    this.mouseCursor,
  });

  /// Row fill.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Label colour.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Checkmark tone.
  final WidgetStateProperty<Color?>? checkmarkColor;

  /// Checkmark box edge length.
  final WidgetStateProperty<double?>? checkmarkSize;

  /// Inset around the checkmark box.
  final WidgetStateProperty<EdgeInsetsGeometry?>? checkmarkPadding;

  /// Row corner radius.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Label text style. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Inset between the row edge and its content.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Extra inset around the label alone, inside [padding].
  final WidgetStateProperty<EdgeInsetsGeometry?>? labelPadding;

  /// Space between the checkmark slot and the label.
  final WidgetStateProperty<double?>? gap;

  /// Minimum row size.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Cursor while hovering the row.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  FluentDropdownOptionStyle merge(FluentDropdownOptionStyle? other) {
    if (other == null) return this;
    return FluentDropdownOptionStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      checkmarkColor: other.checkmarkColor ?? checkmarkColor,
      checkmarkSize: other.checkmarkSize ?? checkmarkSize,
      checkmarkPadding: other.checkmarkPadding ?? checkmarkPadding,
      borderRadius: other.borderRadius ?? borderRadius,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      labelPadding: other.labelPadding ?? labelPadding,
      gap: other.gap ?? gap,
      minimumSize: other.minimumSize ?? minimumSize,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentDropdownOptionStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? checkmarkColor,
    WidgetStateProperty<double?>? checkmarkSize,
    WidgetStateProperty<EdgeInsetsGeometry?>? checkmarkPadding,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<EdgeInsetsGeometry?>? labelPadding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentDropdownOptionStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    checkmarkColor: checkmarkColor ?? this.checkmarkColor,
    checkmarkSize: checkmarkSize ?? this.checkmarkSize,
    checkmarkPadding: checkmarkPadding ?? this.checkmarkPadding,
    borderRadius: borderRadius ?? this.borderRadius,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    labelPadding: labelPadding ?? this.labelPadding,
    gap: gap ?? this.gap,
    minimumSize: minimumSize ?? this.minimumSize,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  static FluentDropdownOptionStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? checkmarkColor,
    double? checkmarkSize,
    EdgeInsetsGeometry? checkmarkPadding,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? labelPadding,
    double? gap,
    Size? minimumSize,
    MouseCursor? mouseCursor,
  }) => FluentDropdownOptionStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    checkmarkColor: _all(checkmarkColor),
    checkmarkSize: _all(checkmarkSize),
    checkmarkPadding: _all(checkmarkPadding),
    borderRadius: _all(borderRadius),
    textStyle: _all(textStyle),
    padding: _all(padding),
    labelPadding: _all(labelPadding),
    gap: _all(gap),
    minimumSize: _all(minimumSize),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentDropdownOptionStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.checkmarkColor == checkmarkColor &&
      other.checkmarkSize == checkmarkSize &&
      other.checkmarkPadding == checkmarkPadding &&
      other.borderRadius == borderRadius &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.labelPadding == labelPadding &&
      other.gap == gap &&
      other.minimumSize == minimumSize &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    checkmarkColor,
    checkmarkSize,
    checkmarkPadding,
    borderRadius,
    textStyle,
    padding,
    labelPadding,
    gap,
    minimumSize,
    mouseCursor,
  );
}
