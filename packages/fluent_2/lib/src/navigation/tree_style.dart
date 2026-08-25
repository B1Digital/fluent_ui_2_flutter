import 'package:flutter/widgets.dart';

/// The visual configuration of one row of a `FluentTree`.
///
/// Shaped exactly like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, pressed, selected and disabled values live
/// on the property rather than being branched on at build time.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the appearance/size defaults derived from the theme
/// 2. the nearest `FluentTreeItemTheme`
/// 3. the widget's own `style`
@immutable
class FluentTreeItemStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentTreeItemStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.expandIconColor,
    this.borderRadius,
    this.textStyle,
    this.padding,
    this.innerPadding,
    this.contentPadding,
    this.actionsPadding,
    this.gap,
    this.iconSize,
    this.expandIconSize,
    this.expandIconExtent,
    this.indent,
    this.rowGap,
    this.minimumSize,
    this.mouseCursor,
  });

  /// Row fill. Fluent's `Neutral/Background/{Subtle,Transparent}/*` ramps.
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Label and leading-icon colour. `Neutral/Foreground/2/*`.
  final WidgetStateProperty<Color?>? foregroundColor;

  /// Chevron colour. A separate ramp from [foregroundColor] — Figma binds
  /// `Neutral/Foreground/3/*` on the chevron and `2/*` on the label, and
  /// upstream's `useTreeItemLayoutStyles` says the same.
  final WidgetStateProperty<Color?>? expandIconColor;

  /// Row corner radius. `Corner radius/Medium`.
  final WidgetStateProperty<BorderRadius?>? borderRadius;

  /// Label text style. Its colour is overridden by [foregroundColor].
  final WidgetStateProperty<TextStyle?>? textStyle;

  /// Inset around the whole row, before the per-level indent is added.
  ///
  /// The indent is not baked in here: it depends on the item's level, which is
  /// a property of the tree rather than of the style. See [indent].
  final WidgetStateProperty<EdgeInsetsGeometry?>? padding;

  /// Vertical inset around the icon-and-label group. Figma's `Start content`,
  /// which is what actually sets the row height: 6 + 20 + 6 = 32 medium,
  /// 4 + 16 + 4 = 24 small. The row frame itself carries no vertical padding.
  final WidgetStateProperty<EdgeInsetsGeometry?>? innerPadding;

  /// Inset around the label alone. Figma's `Content slot`.
  final WidgetStateProperty<EdgeInsetsGeometry?>? contentPadding;

  /// Inset around the trailing actions slot. Figma's `Quick actions`.
  final WidgetStateProperty<EdgeInsetsGeometry?>? actionsPadding;

  /// Space between the leading icon, the selector and the label.
  final WidgetStateProperty<double?>? gap;

  /// Leading icon box.
  final WidgetStateProperty<double?>? iconSize;

  /// Chevron glyph box.
  final WidgetStateProperty<double?>? expandIconSize;

  /// Width reserved for the chevron, occupied by a spacer on a leaf.
  ///
  /// The same number as [indent], and deliberately so: a leaf is indented by
  /// one extra step precisely because it has no chevron, which is how its label
  /// lines up with its siblings' labels.
  final WidgetStateProperty<double?>? expandIconExtent;

  /// Horizontal inset added per level of nesting.
  final WidgetStateProperty<double?>? indent;

  /// Vertical space between rows.
  final WidgetStateProperty<double?>? rowGap;

  /// Minimum row size. Only the height is used.
  final WidgetStateProperty<Size?>? minimumSize;

  /// Cursor shown over an enabled row.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// Returns a copy with every non-null property of [other] layered on top.
  FluentTreeItemStyle merge(FluentTreeItemStyle? other) => other == null
      ? this
      : FluentTreeItemStyle(
          backgroundColor: other.backgroundColor ?? backgroundColor,
          foregroundColor: other.foregroundColor ?? foregroundColor,
          expandIconColor: other.expandIconColor ?? expandIconColor,
          borderRadius: other.borderRadius ?? borderRadius,
          textStyle: other.textStyle ?? textStyle,
          padding: other.padding ?? padding,
          innerPadding: other.innerPadding ?? innerPadding,
          contentPadding: other.contentPadding ?? contentPadding,
          actionsPadding: other.actionsPadding ?? actionsPadding,
          gap: other.gap ?? gap,
          iconSize: other.iconSize ?? iconSize,
          expandIconSize: other.expandIconSize ?? expandIconSize,
          expandIconExtent: other.expandIconExtent ?? expandIconExtent,
          indent: other.indent ?? indent,
          rowGap: other.rowGap ?? rowGap,
          minimumSize: other.minimumSize ?? minimumSize,
          mouseCursor: other.mouseCursor ?? mouseCursor,
        );

  /// Returns a copy with the given properties replaced.
  FluentTreeItemStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? foregroundColor,
    WidgetStateProperty<Color?>? expandIconColor,
    WidgetStateProperty<BorderRadius?>? borderRadius,
    WidgetStateProperty<TextStyle?>? textStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? padding,
    WidgetStateProperty<EdgeInsetsGeometry?>? innerPadding,
    WidgetStateProperty<EdgeInsetsGeometry?>? contentPadding,
    WidgetStateProperty<EdgeInsetsGeometry?>? actionsPadding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<double?>? expandIconSize,
    WidgetStateProperty<double?>? expandIconExtent,
    WidgetStateProperty<double?>? indent,
    WidgetStateProperty<double?>? rowGap,
    WidgetStateProperty<Size?>? minimumSize,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentTreeItemStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    expandIconColor: expandIconColor ?? this.expandIconColor,
    borderRadius: borderRadius ?? this.borderRadius,
    textStyle: textStyle ?? this.textStyle,
    padding: padding ?? this.padding,
    innerPadding: innerPadding ?? this.innerPadding,
    contentPadding: contentPadding ?? this.contentPadding,
    actionsPadding: actionsPadding ?? this.actionsPadding,
    gap: gap ?? this.gap,
    iconSize: iconSize ?? this.iconSize,
    expandIconSize: expandIconSize ?? this.expandIconSize,
    expandIconExtent: expandIconExtent ?? this.expandIconExtent,
    indent: indent ?? this.indent,
    rowGap: rowGap ?? this.rowGap,
    minimumSize: minimumSize ?? this.minimumSize,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state.
  static FluentTreeItemStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? expandIconColor,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? innerPadding,
    EdgeInsetsGeometry? contentPadding,
    EdgeInsetsGeometry? actionsPadding,
    double? gap,
    double? iconSize,
    double? expandIconSize,
    double? expandIconExtent,
    double? indent,
    double? rowGap,
    Size? minimumSize,
    MouseCursor? mouseCursor,
  }) => FluentTreeItemStyle(
    backgroundColor: _all(backgroundColor),
    foregroundColor: _all(foregroundColor),
    expandIconColor: _all(expandIconColor),
    borderRadius: _all(borderRadius),
    textStyle: _all(textStyle),
    padding: _all(padding),
    innerPadding: _all(innerPadding),
    contentPadding: _all(contentPadding),
    actionsPadding: _all(actionsPadding),
    gap: _all(gap),
    iconSize: _all(iconSize),
    expandIconSize: _all(expandIconSize),
    expandIconExtent: _all(expandIconExtent),
    indent: _all(indent),
    rowGap: _all(rowGap),
    minimumSize: _all(minimumSize),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentTreeItemStyle &&
      other.backgroundColor == backgroundColor &&
      other.foregroundColor == foregroundColor &&
      other.expandIconColor == expandIconColor &&
      other.borderRadius == borderRadius &&
      other.textStyle == textStyle &&
      other.padding == padding &&
      other.innerPadding == innerPadding &&
      other.contentPadding == contentPadding &&
      other.actionsPadding == actionsPadding &&
      other.gap == gap &&
      other.iconSize == iconSize &&
      other.expandIconSize == expandIconSize &&
      other.expandIconExtent == expandIconExtent &&
      other.indent == indent &&
      other.rowGap == rowGap &&
      other.minimumSize == minimumSize &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    foregroundColor,
    expandIconColor,
    borderRadius,
    textStyle,
    padding,
    innerPadding,
    contentPadding,
    actionsPadding,
    gap,
    iconSize,
    expandIconSize,
    expandIconExtent,
    indent,
    rowGap,
    minimumSize,
    mouseCursor,
  );
}
