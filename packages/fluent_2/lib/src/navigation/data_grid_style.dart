import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentDataGrid`.
///
/// Shaped like `FluentButtonStyle`: every visual property is a
/// [WidgetStateProperty], so hover, selected and disabled values live on the
/// property rather than being branched on at build time.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence:
///
/// 1. the size defaults derived from the theme
/// 2. the nearest `FluentDataGridTheme`
/// 3. the widget's own `style`
///
/// ## Two colour families, not one
///
/// A data grid paints two different surfaces — the header row and the body
/// rows — from two different Figma variable collections (`DataGrid header row`
/// and `DataGrid row`), whose ramps genuinely disagree: the header has a
/// Pressed mode and no Selected mode, the body has Selected and Brand-selected
/// modes and no Pressed mode. Folding them into one property would mean
/// inventing a value for four of the six states, so they are separate.
@immutable
class FluentDataGridStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentDataGridStyle({
    this.backgroundColor,
    this.headerBackgroundColor,
    this.dividerColor,
    this.dividerWidth,
    this.primaryForegroundColor,
    this.secondaryForegroundColor,
    this.headerForegroundColor,
    this.primaryTextStyle,
    this.secondaryTextStyle,
    this.headerTextStyle,
    this.cellPadding,
    this.selectionCellPadding,
    this.headerPadding,
    this.gap,
    this.headerGap,
    this.rowHeight,
    this.iconSize,
    this.sortButtonPadding,
    this.mouseCursor,
  });

  /// Body-row surface fill. Resolves the whole `DataGrid row` ramp, including
  /// [WidgetState.selected].
  final WidgetStateProperty<Color?>? backgroundColor;

  /// Header-row surface fill. Resolves the `DataGrid header row` ramp, which
  /// has a Pressed mode the body ramp does not.
  final WidgetStateProperty<Color?>? headerBackgroundColor;

  /// The rule under every row, header included.
  ///
  /// Never null and never `Colors.transparent`: Fluent's stroke tokens turn
  /// opaque in high contrast, where this rule is the only thing separating one
  /// row from the next.
  final WidgetStateProperty<Color?>? dividerColor;

  /// Thickness of the rule under every row.
  final WidgetStateProperty<double?>? dividerWidth;

  /// Colour of a cell's primary line.
  final WidgetStateProperty<Color?>? primaryForegroundColor;

  /// Colour of a cell's secondary line.
  final WidgetStateProperty<Color?>? secondaryForegroundColor;

  /// Colour of a header cell's label.
  final WidgetStateProperty<Color?>? headerForegroundColor;

  /// Type ramp of a cell's primary line. Its colour is overridden by
  /// [primaryForegroundColor].
  final WidgetStateProperty<TextStyle?>? primaryTextStyle;

  /// Type ramp of a cell's secondary line. Its colour is overridden by
  /// [secondaryForegroundColor].
  final WidgetStateProperty<TextStyle?>? secondaryTextStyle;

  /// Type ramp of a header cell's label. Its colour is overridden by
  /// [headerForegroundColor].
  final WidgetStateProperty<TextStyle?>? headerTextStyle;

  /// Inset of a content cell. Horizontal only; the content is centred
  /// vertically inside [rowHeight].
  final WidgetStateProperty<EdgeInsetsGeometry?>? cellPadding;

  /// Inset of a selection cell, around the bare 16px indicator.
  ///
  /// Vertical here, unlike [cellPadding]: Figma states the selection column's
  /// four insets explicitly and they sum exactly to [rowHeight].
  final WidgetStateProperty<EdgeInsetsGeometry?>? selectionCellPadding;

  /// Inset of a header cell. Horizontal only, like [cellPadding].
  final WidgetStateProperty<EdgeInsetsGeometry?>? headerPadding;

  /// Space between a cell's leading slot and its content.
  final WidgetStateProperty<double?>? gap;

  /// Space between a header label and its sort affordance.
  final WidgetStateProperty<double?>? headerGap;

  /// Height of one row, the rule included.
  final WidgetStateProperty<double?>? rowHeight;

  /// Edge length applied to icons in a cell's leading slot, through
  /// [IconTheme].
  final WidgetStateProperty<double?>? iconSize;

  /// Inset inside the header's sort button, which Figma squares off rather
  /// than using `FluentButton`'s horizontal ramp.
  final WidgetStateProperty<EdgeInsetsGeometry?>? sortButtonPadding;

  /// Cursor over an interactive row.
  final WidgetStateProperty<MouseCursor?>? mouseCursor;

  /// This style with the non-null properties of [other] layered on top.
  ///
  /// Merging is per-property, not wholesale: overriding only [rowHeight] keeps
  /// every resolved colour.
  FluentDataGridStyle merge(FluentDataGridStyle? other) {
    if (other == null) return this;
    return FluentDataGridStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      headerBackgroundColor:
          other.headerBackgroundColor ?? headerBackgroundColor,
      dividerColor: other.dividerColor ?? dividerColor,
      dividerWidth: other.dividerWidth ?? dividerWidth,
      primaryForegroundColor:
          other.primaryForegroundColor ?? primaryForegroundColor,
      secondaryForegroundColor:
          other.secondaryForegroundColor ?? secondaryForegroundColor,
      headerForegroundColor:
          other.headerForegroundColor ?? headerForegroundColor,
      primaryTextStyle: other.primaryTextStyle ?? primaryTextStyle,
      secondaryTextStyle: other.secondaryTextStyle ?? secondaryTextStyle,
      headerTextStyle: other.headerTextStyle ?? headerTextStyle,
      cellPadding: other.cellPadding ?? cellPadding,
      selectionCellPadding: other.selectionCellPadding ?? selectionCellPadding,
      headerPadding: other.headerPadding ?? headerPadding,
      gap: other.gap ?? gap,
      headerGap: other.headerGap ?? headerGap,
      rowHeight: other.rowHeight ?? rowHeight,
      iconSize: other.iconSize ?? iconSize,
      sortButtonPadding: other.sortButtonPadding ?? sortButtonPadding,
      mouseCursor: other.mouseCursor ?? mouseCursor,
    );
  }

  /// This style with the given properties replaced.
  FluentDataGridStyle copyWith({
    WidgetStateProperty<Color?>? backgroundColor,
    WidgetStateProperty<Color?>? headerBackgroundColor,
    WidgetStateProperty<Color?>? dividerColor,
    WidgetStateProperty<double?>? dividerWidth,
    WidgetStateProperty<Color?>? primaryForegroundColor,
    WidgetStateProperty<Color?>? secondaryForegroundColor,
    WidgetStateProperty<Color?>? headerForegroundColor,
    WidgetStateProperty<TextStyle?>? primaryTextStyle,
    WidgetStateProperty<TextStyle?>? secondaryTextStyle,
    WidgetStateProperty<TextStyle?>? headerTextStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? cellPadding,
    WidgetStateProperty<EdgeInsetsGeometry?>? selectionCellPadding,
    WidgetStateProperty<EdgeInsetsGeometry?>? headerPadding,
    WidgetStateProperty<double?>? gap,
    WidgetStateProperty<double?>? headerGap,
    WidgetStateProperty<double?>? rowHeight,
    WidgetStateProperty<double?>? iconSize,
    WidgetStateProperty<EdgeInsetsGeometry?>? sortButtonPadding,
    WidgetStateProperty<MouseCursor?>? mouseCursor,
  }) => FluentDataGridStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
    dividerColor: dividerColor ?? this.dividerColor,
    dividerWidth: dividerWidth ?? this.dividerWidth,
    primaryForegroundColor:
        primaryForegroundColor ?? this.primaryForegroundColor,
    secondaryForegroundColor:
        secondaryForegroundColor ?? this.secondaryForegroundColor,
    headerForegroundColor: headerForegroundColor ?? this.headerForegroundColor,
    primaryTextStyle: primaryTextStyle ?? this.primaryTextStyle,
    secondaryTextStyle: secondaryTextStyle ?? this.secondaryTextStyle,
    headerTextStyle: headerTextStyle ?? this.headerTextStyle,
    cellPadding: cellPadding ?? this.cellPadding,
    selectionCellPadding: selectionCellPadding ?? this.selectionCellPadding,
    headerPadding: headerPadding ?? this.headerPadding,
    gap: gap ?? this.gap,
    headerGap: headerGap ?? this.headerGap,
    rowHeight: rowHeight ?? this.rowHeight,
    iconSize: iconSize ?? this.iconSize,
    sortButtonPadding: sortButtonPadding ?? this.sortButtonPadding,
    mouseCursor: mouseCursor ?? this.mouseCursor,
  );

  /// Convenience for the common case of one value across every state.
  ///
  /// The counterpart of Material's `styleFrom`. Use the constructor directly
  /// when a property genuinely differs per state — which, for a data grid, is
  /// most of the colours.
  static FluentDataGridStyle from({
    Color? backgroundColor,
    Color? headerBackgroundColor,
    Color? dividerColor,
    double? dividerWidth,
    Color? primaryForegroundColor,
    Color? secondaryForegroundColor,
    Color? headerForegroundColor,
    TextStyle? primaryTextStyle,
    TextStyle? secondaryTextStyle,
    TextStyle? headerTextStyle,
    EdgeInsetsGeometry? cellPadding,
    EdgeInsetsGeometry? selectionCellPadding,
    EdgeInsetsGeometry? headerPadding,
    double? gap,
    double? headerGap,
    double? rowHeight,
    double? iconSize,
    EdgeInsetsGeometry? sortButtonPadding,
    MouseCursor? mouseCursor,
  }) => FluentDataGridStyle(
    backgroundColor: _all(backgroundColor),
    headerBackgroundColor: _all(headerBackgroundColor),
    dividerColor: _all(dividerColor),
    dividerWidth: _all(dividerWidth),
    primaryForegroundColor: _all(primaryForegroundColor),
    secondaryForegroundColor: _all(secondaryForegroundColor),
    headerForegroundColor: _all(headerForegroundColor),
    primaryTextStyle: _all(primaryTextStyle),
    secondaryTextStyle: _all(secondaryTextStyle),
    headerTextStyle: _all(headerTextStyle),
    cellPadding: _all(cellPadding),
    selectionCellPadding: _all(selectionCellPadding),
    headerPadding: _all(headerPadding),
    gap: _all(gap),
    headerGap: _all(headerGap),
    rowHeight: _all(rowHeight),
    iconSize: _all(iconSize),
    sortButtonPadding: _all(sortButtonPadding),
    mouseCursor: _all(mouseCursor),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentDataGridStyle &&
      other.backgroundColor == backgroundColor &&
      other.headerBackgroundColor == headerBackgroundColor &&
      other.dividerColor == dividerColor &&
      other.dividerWidth == dividerWidth &&
      other.primaryForegroundColor == primaryForegroundColor &&
      other.secondaryForegroundColor == secondaryForegroundColor &&
      other.headerForegroundColor == headerForegroundColor &&
      other.primaryTextStyle == primaryTextStyle &&
      other.secondaryTextStyle == secondaryTextStyle &&
      other.headerTextStyle == headerTextStyle &&
      other.cellPadding == cellPadding &&
      other.selectionCellPadding == selectionCellPadding &&
      other.headerPadding == headerPadding &&
      other.gap == gap &&
      other.headerGap == headerGap &&
      other.rowHeight == rowHeight &&
      other.iconSize == iconSize &&
      other.sortButtonPadding == sortButtonPadding &&
      other.mouseCursor == mouseCursor;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    backgroundColor,
    headerBackgroundColor,
    dividerColor,
    dividerWidth,
    primaryForegroundColor,
    secondaryForegroundColor,
    headerForegroundColor,
    primaryTextStyle,
    secondaryTextStyle,
    headerTextStyle,
    cellPadding,
    selectionCellPadding,
    headerPadding,
    gap,
    headerGap,
    rowHeight,
    iconSize,
    sortButtonPadding,
    mouseCursor,
  ]);
}
