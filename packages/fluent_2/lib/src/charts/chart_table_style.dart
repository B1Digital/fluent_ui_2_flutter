import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'internal/chart_text_styles.dart';

/// The visual configuration of a chart table.
///
/// ChartTable is the one component in this family that draws no marks — it is
/// a real table, so the style carries type, padding and border tokens rather
/// than stroke widths and opacities. Shaped like `FluentBadgeStyle`.
@immutable
class FluentChartTableStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentChartTableStyle({
    this.headerTextStyle,
    this.bodyTextStyle,
    this.titleTextStyle,
    this.headerBackgroundColor,
    this.cellForegroundColor,
    this.borderColor,
    this.titleBackgroundColor,
    this.cellPadding,
    this.borderWidth,
    this.defaultHeight,
    this.titleHeight,
  });

  /// Header-cell type. `useChartTableStyles.styles.ts:32-33` spreads
  /// `caption1` (12/16 regular) then overrides the weight to semibold.
  final WidgetStateProperty<TextStyle?>? headerTextStyle;

  /// Body-cell type — `caption1` with no weight override
  /// (`useChartTableStyles.styles.ts:45`).
  final WidgetStateProperty<TextStyle?>? bodyTextStyle;

  /// Chart-title type. `getChartTitleStyles()` (`utilities/Common.styles.ts:83`
  /// to `:91`) is `caption2Strong`, 10/14 semibold, and
  /// `useChartTableStyles.styles.ts:54` assigns it verbatim.
  final WidgetStateProperty<TextStyle?>? titleTextStyle;

  /// Header-row fill — `colorNeutralBackground3`
  /// (`useChartTableStyles.styles.ts:34`). Body cells declare none.
  final WidgetStateProperty<Color?>? headerBackgroundColor;

  /// Text colour for both header and body — `colorNeutralForeground1`
  /// (`useChartTableStyles.styles.ts:35` and `:48`).
  final WidgetStateProperty<Color?>? cellForegroundColor;

  /// Grid colour — `colorNeutralStroke2`
  /// (`useChartTableStyles.styles.ts:38`).
  final WidgetStateProperty<Color?>? borderColor;

  /// Fill of the title's backing rectangle — `colorNeutralBackground1`
  /// (`useChartTableStyles.styles.ts:55-56`, the `svgTooltip` slot).
  final WidgetStateProperty<Color?>? titleBackgroundColor;

  /// Padding inside every cell. Upstream's `padding: spacingHorizontalS` is a
  /// single-value shorthand (`useChartTableStyles.styles.ts:36`), so all four
  /// sides get 8 even though the token is named "horizontal".
  final WidgetStateProperty<EdgeInsetsGeometry?>? cellPadding;

  /// Grid line width — `strokeWidthThick`, i.e. 2
  /// (`useChartTableStyles.styles.ts:38`).
  final WidgetStateProperty<double?>? borderWidth;

  /// Height used when the caller gives none. Upstream falls back to 650
  /// (`ChartTable.tsx:94`).
  final WidgetStateProperty<double?>? defaultHeight;

  /// Vertical space the chart title takes out of the total height. Upstream is
  /// 30 when a title is set and 0 otherwise (`ChartTable.tsx:93`).
  final WidgetStateProperty<double?>? titleHeight;

  /// This style with the non-null properties of [other] layered on top.
  FluentChartTableStyle merge(FluentChartTableStyle? other) {
    if (other == null) {
      return this;
    }
    return FluentChartTableStyle(
      headerTextStyle: other.headerTextStyle ?? headerTextStyle,
      bodyTextStyle: other.bodyTextStyle ?? bodyTextStyle,
      titleTextStyle: other.titleTextStyle ?? titleTextStyle,
      headerBackgroundColor:
          other.headerBackgroundColor ?? headerBackgroundColor,
      cellForegroundColor: other.cellForegroundColor ?? cellForegroundColor,
      borderColor: other.borderColor ?? borderColor,
      titleBackgroundColor: other.titleBackgroundColor ?? titleBackgroundColor,
      cellPadding: other.cellPadding ?? cellPadding,
      borderWidth: other.borderWidth ?? borderWidth,
      defaultHeight: other.defaultHeight ?? defaultHeight,
      titleHeight: other.titleHeight ?? titleHeight,
    );
  }

  /// This style with the given properties replaced.
  FluentChartTableStyle copyWith({
    WidgetStateProperty<TextStyle?>? headerTextStyle,
    WidgetStateProperty<TextStyle?>? bodyTextStyle,
    WidgetStateProperty<TextStyle?>? titleTextStyle,
    WidgetStateProperty<Color?>? headerBackgroundColor,
    WidgetStateProperty<Color?>? cellForegroundColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<Color?>? titleBackgroundColor,
    WidgetStateProperty<EdgeInsetsGeometry?>? cellPadding,
    WidgetStateProperty<double?>? borderWidth,
    WidgetStateProperty<double?>? defaultHeight,
    WidgetStateProperty<double?>? titleHeight,
  }) => FluentChartTableStyle(
    headerTextStyle: headerTextStyle ?? this.headerTextStyle,
    bodyTextStyle: bodyTextStyle ?? this.bodyTextStyle,
    titleTextStyle: titleTextStyle ?? this.titleTextStyle,
    headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
    cellForegroundColor: cellForegroundColor ?? this.cellForegroundColor,
    borderColor: borderColor ?? this.borderColor,
    titleBackgroundColor: titleBackgroundColor ?? this.titleBackgroundColor,
    cellPadding: cellPadding ?? this.cellPadding,
    borderWidth: borderWidth ?? this.borderWidth,
    defaultHeight: defaultHeight ?? this.defaultHeight,
    titleHeight: titleHeight ?? this.titleHeight,
  );

  /// Convenience for the common case of one value across every state.
  static FluentChartTableStyle from({
    TextStyle? headerTextStyle,
    TextStyle? bodyTextStyle,
    TextStyle? titleTextStyle,
    Color? headerBackgroundColor,
    Color? cellForegroundColor,
    Color? borderColor,
    Color? titleBackgroundColor,
    EdgeInsetsGeometry? cellPadding,
    double? borderWidth,
    double? defaultHeight,
    double? titleHeight,
  }) => FluentChartTableStyle(
    headerTextStyle: _all(headerTextStyle),
    bodyTextStyle: _all(bodyTextStyle),
    titleTextStyle: _all(titleTextStyle),
    headerBackgroundColor: _all(headerBackgroundColor),
    cellForegroundColor: _all(cellForegroundColor),
    borderColor: _all(borderColor),
    titleBackgroundColor: _all(titleBackgroundColor),
    cellPadding: _all(cellPadding),
    borderWidth: _all(borderWidth),
    defaultHeight: _all(defaultHeight),
    titleHeight: _all(titleHeight),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentChartTableStyle &&
      other.headerTextStyle == headerTextStyle &&
      other.bodyTextStyle == bodyTextStyle &&
      other.titleTextStyle == titleTextStyle &&
      other.headerBackgroundColor == headerBackgroundColor &&
      other.cellForegroundColor == cellForegroundColor &&
      other.borderColor == borderColor &&
      other.titleBackgroundColor == titleBackgroundColor &&
      other.cellPadding == cellPadding &&
      other.borderWidth == borderWidth &&
      other.defaultHeight == defaultHeight &&
      other.titleHeight == titleHeight;

  @override
  int get hashCode => Object.hash(
    headerTextStyle,
    bodyTextStyle,
    titleTextStyle,
    headerBackgroundColor,
    cellForegroundColor,
    borderColor,
    titleBackgroundColor,
    cellPadding,
    borderWidth,
    defaultHeight,
    titleHeight,
  );
}

/// The derived defaults for a chart table, before any theme or widget
/// override.
FluentChartTableStyle resolveFluentChartTableStyle(FluentThemeData theme) {
  final text = FluentChartTextStyles.of(theme);
  return FluentChartTableStyle.from(
    headerTextStyle: theme.typography.caption1.copyWith(
      // useChartTableStyles.styles.ts:33 — the weight override wins over the
      // caption1 spread on the line above it.
      fontWeight: FluentFontWeight.semibold,
      color: theme.colors.neutralForeground1,
    ),
    bodyTextStyle: theme.typography.caption1.copyWith(
      color: theme.colors.neutralForeground1,
    ),
    titleTextStyle: text.chartTitle,
    headerBackgroundColor: theme.colors.neutralBackground3,
    cellForegroundColor: theme.colors.neutralForeground1,
    borderColor: theme.colors.neutralStroke2,
    titleBackgroundColor: theme.colors.neutralBackground1,
    // useChartTableStyles.styles.ts:36 — single-value shorthand, all sides.
    cellPadding: const EdgeInsets.all(8),
    // useChartTableStyles.styles.ts:38 — strokeWidthThick.
    borderWidth: 2,
    // ChartTable.tsx:94.
    defaultHeight: 650,
    // ChartTable.tsx:93.
    titleHeight: 30,
  );
}
