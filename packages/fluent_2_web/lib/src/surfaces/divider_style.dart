import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentDivider`.
///
/// Shaped exactly like `FluentButtonStyle`, [WidgetStateProperty] fields and
/// all, even though a divider is never hovered, pressed or focused. The
/// uniformity is the point: a consumer overriding two components should not have
/// to learn two struct shapes, and a component that later gains a state does not
/// change its public style type to get one. Every property here resolves against
/// the empty state set.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance/inset defaults derived from the theme
/// 2. the nearest `FluentDividerTheme`
/// 3. the widget's own `style`
@immutable
class FluentDividerStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentDividerStyle({
    this.lineColor,
    this.lineThickness,
    this.shortLineLength,
    this.contentColor,
    this.textStyle,
    this.padding,
    this.contentPadding,
    this.contentMinimumSize,
    this.gap,
    this.iconSize,
  });

  /// The rule's colour. Figma binds this to the `Stroke color` variable of the
  /// `Divider appearance` collection.
  final WidgetStateProperty<Color?>? lineColor;

  /// The rule's thickness across the divider — height when horizontal, width
  /// when vertical.
  final WidgetStateProperty<double?>? lineThickness;

  /// Length of the rule on the side the label is aligned to.
  ///
  /// Only consumed by `FluentDividerAlignment.start` and
  /// `FluentDividerAlignment.end`, where Figma pins the near rule to a fixed
  /// length and lets the far one grow.
  final WidgetStateProperty<double?>? shortLineLength;

  /// The label and icon colour. Figma's `Content color` variable.
  final WidgetStateProperty<Color?>? contentColor;

  /// Label text style. Its colour is overridden by [contentColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Inset applied outside both rules — Figma's `Divider padding` collection,
  /// which has exactly two modes, `Full` (zero) and `Inset`.
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// The gap the label box opens between itself and each rule.
  final WidgetStateProperty<EdgeInsetsGeometry?>? contentPadding;

  /// Minimum size of the label box.
  ///
  /// Figma authors the horizontal label row at a fixed 20 high so that an icon
  /// and a caption line up and the divider does not change height when the icon
  /// slot is empty. The vertical label box hugs, so only the height of this is
  /// non-zero by default.
  final WidgetStateProperty<Size?>? contentMinimumSize;

  /// Space between icon and label.
  final WidgetStateProperty<double?>? gap;

  /// Icon edge length.
  final WidgetStateProperty<double?>? iconSize;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only `lineThickness`
  /// keeps every resolved colour. This is what makes a partial override useful.
  FluentDividerStyle merge(FluentDividerStyle? other) {
    if (other == null) return this;
    return FluentDividerStyle(
      lineColor: other.lineColor ?? lineColor,
      lineThickness: other.lineThickness ?? lineThickness,
      shortLineLength: other.shortLineLength ?? shortLineLength,
      contentColor: other.contentColor ?? contentColor,
      textStyle: other.textStyle ?? textStyle,
      padding: other.padding ?? padding,
      contentPadding: other.contentPadding ?? contentPadding,
      contentMinimumSize: other.contentMinimumSize ?? contentMinimumSize,
      gap: other.gap ?? gap,
      iconSize: other.iconSize ?? iconSize,
    );
  }

  /// This style with the given properties replaced.
  FluentDividerStyle copyWith({
    WidgetStateProperty<Color?>? lineColor,
    WidgetStateProperty<double?>? lineThickness,
    WidgetStateProperty<double?>? shortLineLength,
    WidgetStateProperty<Color?>? contentColor,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<EdgeInsetsGeometry?>? contentPadding,
    WidgetStateProperty<Size?>? contentMinimumSize,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<double?>? iconSize,
  }) => FluentDividerStyle(
    lineColor: lineColor ?? this.lineColor,
    lineThickness: lineThickness ?? this.lineThickness,
    shortLineLength: shortLineLength ?? this.shortLineLength,
    contentColor: contentColor ?? this.contentColor,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    contentPadding: contentPadding ?? this.contentPadding,
    contentMinimumSize: contentMinimumSize ?? this.contentMinimumSize,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentDividerStyle from({
    Color? lineColor,
    double? lineThickness,
    double? shortLineLength,
    Color? contentColor,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? contentPadding,
    Size? contentMinimumSize,
    double? gap,
    double? iconSize,
  }) => FluentDividerStyle(
    lineColor: _all(lineColor),
    lineThickness: _all(lineThickness),
    shortLineLength: _all(shortLineLength),
    contentColor: _all(contentColor),
    textStyle: _all(textStyle),
    padding: _all(padding),
    contentPadding: _all(contentPadding),
    contentMinimumSize: _all(contentMinimumSize),
    gap: _all(gap),
    iconSize: _all(iconSize),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentDividerStyle &&
      other.lineColor == lineColor &&
      other.lineThickness == lineThickness &&
      other.shortLineLength == shortLineLength &&
      other.contentColor == contentColor &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.contentPadding == contentPadding &&
      other.contentMinimumSize == contentMinimumSize &&
      other.gap == gap &&
      other.iconSize == iconSize;

  @override
  int get hashCode => Object.hash(
    lineColor,
    lineThickness,
    shortLineLength,
    contentColor,
    textStyle,
    padding,
    contentPadding,
    contentMinimumSize,
    gap,
    iconSize,
  );
}
