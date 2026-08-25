import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

/// The visual configuration of a `FluentHorizontalBarChart`.
///
/// The chart uses no d3 at all — every position is percentage arithmetic over
/// the row width (`HorizontalBarChart.tsx:218-333`) — so this style carries the
/// literals that arithmetic reads.
///
/// Every field is nullable and means "inherit". Resolution order, lowest to
/// highest precedence: the theme-derived defaults from
/// [resolveFluentHorizontalBarChartStyle], the nearest chart theme, then the
/// widget's own `style`.
@immutable
class FluentHorizontalBarChartStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentHorizontalBarChartStyle({
    this.barHeight,
    this.barGap,
    this.dimmedOpacity,
    this.rowSpacing,
    this.rowSpacingWithTriangle,
    this.titleBottomSpacing,
    this.titleBottomSpacingAbsolute,
    this.benchmarkWidth,
    this.benchmarkHeight,
    this.barLabelOffset,
    this.legendTopPadding,
    this.titleTextStyle,
    this.valueTextStyle,
    this.denominatorTextStyle,
    this.barLabelTextStyle,
    this.benchmarkColor,
    this.placeholderColor,
    this.defaultPalette,
  });

  /// Height of each bar strip. Upstream is `props.barHeight || 12`
  /// (`HorizontalBarChart.tsx:106`). Note the svg's own height is hard-coded to
  /// 12 with `overflow: visible`
  /// (`useHorizontalBarChartStyles.styles.ts:45-50`), so a taller bar bleeds
  /// into the next row rather than being clipped.
  final WidgetStateProperty<double?>? barHeight;

  /// Gap between adjacent bars. `MARGIN_WIDTH_IN_PX = 3`
  /// (`HorizontalBarChart.tsx:364`).
  final WidgetStateProperty<double?>? barGap;

  /// Opacity of a bar that is not highlighted
  /// (`HorizontalBarChart.tsx:327`).
  final WidgetStateProperty<double?>? dimmedOpacity;

  /// Space below a row — `spacingVerticalMNudge`, 10
  /// (`useHorizontalBarChartStyles.styles.ts:39-41`).
  final WidgetStateProperty<double?>? rowSpacing;

  /// Space below a row that shows a benchmark triangle, or a row in the
  /// absolute-scale variant — `spacingVerticalL`, 16
  /// (`useHorizontalBarChartStyles.styles.ts:42-44`, `:119-125`).
  final WidgetStateProperty<double?>? rowSpacingWithTriangle;

  /// Space under the row title — 5
  /// (`useHorizontalBarChartStyles.styles.ts:67-69`).
  final WidgetStateProperty<double?>? titleBottomSpacing;

  /// Space under the row title in the absolute-scale variant — 4
  /// (`useHorizontalBarChartStyles.styles.ts:64-66`).
  final WidgetStateProperty<double?>? titleBottomSpacingAbsolute;

  /// Width of the benchmark triangle — 4 + 4 transparent side borders
  /// (`useHorizontalBarChartStyles.styles.ts:87-88`).
  final WidgetStateProperty<double?>? benchmarkWidth;

  /// Height of the benchmark triangle — the 7px top border
  /// (`useHorizontalBarChartStyles.styles.ts:89`).
  final WidgetStateProperty<double?>? benchmarkHeight;

  /// Directional offset of the absolute-scale bar label from the bar's
  /// starting point. Upstream is `translate(±4)`
  /// (`HorizontalBarChart.tsx:297`).
  final WidgetStateProperty<double?>? barLabelOffset;

  /// Space above the legend strip — `spacingVerticalL`, 16
  /// (`useHorizontalBarChartStyles.styles.ts:107`).
  final WidgetStateProperty<double?>? legendTopPadding;

  /// Row title type — `caption1`, 12/16 regular
  /// (`useHorizontalBarChartStyles.styles.ts:52-56`).
  final WidgetStateProperty<TextStyle?>? titleTextStyle;

  /// Row value type — `body1Strong`, 14/20 semibold
  /// (`useHorizontalBarChartStyles.styles.ts:70-73`).
  final WidgetStateProperty<TextStyle?>? valueTextStyle;

  /// Fraction denominator type — `body1`, 14/20 regular
  /// (`useHorizontalBarChartStyles.styles.ts:74-77`).
  final WidgetStateProperty<TextStyle?>? denominatorTextStyle;

  /// Absolute-scale bar label type — `caption1Strong`, 12/16 semibold
  /// (`useHorizontalBarChartStyles.styles.ts:94-100`).
  final WidgetStateProperty<TextStyle?>? barLabelTextStyle;

  /// Benchmark triangle fill — `colorPaletteBlueBorderActive`
  /// (`useHorizontalBarChartStyles.styles.ts:90`).
  final WidgetStateProperty<Color?>? benchmarkColor;

  /// Fill of the synthesised remainder bar — `colorBackgroundOverlay`
  /// (`HorizontalBarChart.tsx:411`).
  final WidgetStateProperty<Color?>? placeholderColor;

  /// The five fallback series colours, in upstream order
  /// (`HorizontalBarChart.tsx:223-229`).
  final WidgetStateProperty<List<Color>?>? defaultPalette;

  /// This style with the non-null properties of [other] layered on top.
  FluentHorizontalBarChartStyle merge(FluentHorizontalBarChartStyle? other) {
    if (other == null) return this;
    return FluentHorizontalBarChartStyle(
      barHeight: other.barHeight ?? barHeight,
      barGap: other.barGap ?? barGap,
      dimmedOpacity: other.dimmedOpacity ?? dimmedOpacity,
      rowSpacing: other.rowSpacing ?? rowSpacing,
      rowSpacingWithTriangle:
          other.rowSpacingWithTriangle ?? rowSpacingWithTriangle,
      titleBottomSpacing: other.titleBottomSpacing ?? titleBottomSpacing,
      titleBottomSpacingAbsolute:
          other.titleBottomSpacingAbsolute ?? titleBottomSpacingAbsolute,
      benchmarkWidth: other.benchmarkWidth ?? benchmarkWidth,
      benchmarkHeight: other.benchmarkHeight ?? benchmarkHeight,
      barLabelOffset: other.barLabelOffset ?? barLabelOffset,
      legendTopPadding: other.legendTopPadding ?? legendTopPadding,
      titleTextStyle: other.titleTextStyle ?? titleTextStyle,
      valueTextStyle: other.valueTextStyle ?? valueTextStyle,
      denominatorTextStyle: other.denominatorTextStyle ?? denominatorTextStyle,
      barLabelTextStyle: other.barLabelTextStyle ?? barLabelTextStyle,
      benchmarkColor: other.benchmarkColor ?? benchmarkColor,
      placeholderColor: other.placeholderColor ?? placeholderColor,
      defaultPalette: other.defaultPalette ?? defaultPalette,
    );
  }

  /// This style with the given properties replaced.
  FluentHorizontalBarChartStyle copyWith({
    WidgetStateProperty<double?>? barHeight,
    WidgetStateProperty<double?>? barGap,
    WidgetStateProperty<double?>? dimmedOpacity,
    WidgetStateProperty<double?>? rowSpacing,
    WidgetStateProperty<double?>? rowSpacingWithTriangle,
    WidgetStateProperty<double?>? titleBottomSpacing,
    WidgetStateProperty<double?>? titleBottomSpacingAbsolute,
    WidgetStateProperty<double?>? benchmarkWidth,
    WidgetStateProperty<double?>? benchmarkHeight,
    WidgetStateProperty<double?>? barLabelOffset,
    WidgetStateProperty<double?>? legendTopPadding,
    WidgetStateProperty<TextStyle?>? titleTextStyle,
    WidgetStateProperty<TextStyle?>? valueTextStyle,
    WidgetStateProperty<TextStyle?>? denominatorTextStyle,
    WidgetStateProperty<TextStyle?>? barLabelTextStyle,
    WidgetStateProperty<Color?>? benchmarkColor,
    WidgetStateProperty<Color?>? placeholderColor,
    WidgetStateProperty<List<Color>?>? defaultPalette,
  }) => FluentHorizontalBarChartStyle(
    barHeight: barHeight ?? this.barHeight,
    barGap: barGap ?? this.barGap,
    dimmedOpacity: dimmedOpacity ?? this.dimmedOpacity,
    rowSpacing: rowSpacing ?? this.rowSpacing,
    rowSpacingWithTriangle:
        rowSpacingWithTriangle ?? this.rowSpacingWithTriangle,
    titleBottomSpacing: titleBottomSpacing ?? this.titleBottomSpacing,
    titleBottomSpacingAbsolute:
        titleBottomSpacingAbsolute ?? this.titleBottomSpacingAbsolute,
    benchmarkWidth: benchmarkWidth ?? this.benchmarkWidth,
    benchmarkHeight: benchmarkHeight ?? this.benchmarkHeight,
    barLabelOffset: barLabelOffset ?? this.barLabelOffset,
    legendTopPadding: legendTopPadding ?? this.legendTopPadding,
    titleTextStyle: titleTextStyle ?? this.titleTextStyle,
    valueTextStyle: valueTextStyle ?? this.valueTextStyle,
    denominatorTextStyle: denominatorTextStyle ?? this.denominatorTextStyle,
    barLabelTextStyle: barLabelTextStyle ?? this.barLabelTextStyle,
    benchmarkColor: benchmarkColor ?? this.benchmarkColor,
    placeholderColor: placeholderColor ?? this.placeholderColor,
    defaultPalette: defaultPalette ?? this.defaultPalette,
  );

  /// Convenience for the common case of one value across every state.
  static FluentHorizontalBarChartStyle from({
    double? barHeight,
    double? barGap,
    double? dimmedOpacity,
    double? rowSpacing,
    double? rowSpacingWithTriangle,
    double? titleBottomSpacing,
    double? titleBottomSpacingAbsolute,
    double? benchmarkWidth,
    double? benchmarkHeight,
    double? barLabelOffset,
    double? legendTopPadding,
    TextStyle? titleTextStyle,
    TextStyle? valueTextStyle,
    TextStyle? denominatorTextStyle,
    TextStyle? barLabelTextStyle,
    Color? benchmarkColor,
    Color? placeholderColor,
    List<Color>? defaultPalette,
  }) => FluentHorizontalBarChartStyle(
    barHeight: _all(barHeight),
    barGap: _all(barGap),
    dimmedOpacity: _all(dimmedOpacity),
    rowSpacing: _all(rowSpacing),
    rowSpacingWithTriangle: _all(rowSpacingWithTriangle),
    titleBottomSpacing: _all(titleBottomSpacing),
    titleBottomSpacingAbsolute: _all(titleBottomSpacingAbsolute),
    benchmarkWidth: _all(benchmarkWidth),
    benchmarkHeight: _all(benchmarkHeight),
    barLabelOffset: _all(barLabelOffset),
    legendTopPadding: _all(legendTopPadding),
    titleTextStyle: _all(titleTextStyle),
    valueTextStyle: _all(valueTextStyle),
    denominatorTextStyle: _all(denominatorTextStyle),
    barLabelTextStyle: _all(barLabelTextStyle),
    benchmarkColor: _all(benchmarkColor),
    placeholderColor: _all(placeholderColor),
    defaultPalette: _all(defaultPalette),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentHorizontalBarChartStyle &&
      other.barHeight == barHeight &&
      other.barGap == barGap &&
      other.dimmedOpacity == dimmedOpacity &&
      other.rowSpacing == rowSpacing &&
      other.rowSpacingWithTriangle == rowSpacingWithTriangle &&
      other.titleBottomSpacing == titleBottomSpacing &&
      other.titleBottomSpacingAbsolute == titleBottomSpacingAbsolute &&
      other.benchmarkWidth == benchmarkWidth &&
      other.benchmarkHeight == benchmarkHeight &&
      other.barLabelOffset == barLabelOffset &&
      other.legendTopPadding == legendTopPadding &&
      other.titleTextStyle == titleTextStyle &&
      other.valueTextStyle == valueTextStyle &&
      other.denominatorTextStyle == denominatorTextStyle &&
      other.barLabelTextStyle == barLabelTextStyle &&
      other.benchmarkColor == benchmarkColor &&
      other.placeholderColor == placeholderColor &&
      other.defaultPalette == defaultPalette;

  @override
  int get hashCode => Object.hash(
    barHeight,
    barGap,
    dimmedOpacity,
    rowSpacing,
    rowSpacingWithTriangle,
    titleBottomSpacing,
    titleBottomSpacingAbsolute,
    benchmarkWidth,
    benchmarkHeight,
    barLabelOffset,
    legendTopPadding,
    titleTextStyle,
    valueTextStyle,
    denominatorTextStyle,
    barLabelTextStyle,
    benchmarkColor,
    placeholderColor,
    defaultPalette,
  );
}

/// The derived defaults for a horizontal bar chart.
FluentHorizontalBarChartStyle resolveFluentHorizontalBarChartStyle(
  FluentThemeData theme,
) {
  final palette = theme.colors.palette;
  return FluentHorizontalBarChartStyle.from(
    // HorizontalBarChart.tsx:106 — the code's 12 beats the documented 15.
    barHeight: 12,
    // HorizontalBarChart.tsx:364 — MARGIN_WIDTH_IN_PX.
    barGap: 3,
    // HorizontalBarChart.tsx:327.
    dimmedOpacity: 0.1,
    // useHorizontalBarChartStyles.styles.ts:40 — spacingVerticalMNudge.
    rowSpacing: 10,
    // useHorizontalBarChartStyles.styles.ts:43 — spacingVerticalL.
    rowSpacingWithTriangle: 16,
    // useHorizontalBarChartStyles.styles.ts:68.
    titleBottomSpacing: 5,
    // useHorizontalBarChartStyles.styles.ts:65.
    titleBottomSpacingAbsolute: 4,
    // useHorizontalBarChartStyles.styles.ts:87-88 — 4 + 4.
    benchmarkWidth: 8,
    // useHorizontalBarChartStyles.styles.ts:89.
    benchmarkHeight: 7,
    // HorizontalBarChart.tsx:297 — translate(±4).
    barLabelOffset: 4,
    // useHorizontalBarChartStyles.styles.ts:107 — spacingVerticalL.
    legendTopPadding: 16,
    titleTextStyle: theme.typography.caption1.copyWith(
      color: theme.colors.neutralForeground1,
    ),
    valueTextStyle: theme.typography.body1Strong.copyWith(
      color: theme.colors.neutralForeground1,
    ),
    denominatorTextStyle: theme.typography.body1.copyWith(
      color: theme.colors.neutralForeground1,
    ),
    barLabelTextStyle: theme.typography.caption1Strong.copyWith(
      color: theme.colors.neutralForeground1,
    ),
    benchmarkColor: palette.strokeActiveRest(FluentPaletteFamily.blue),
    placeholderColor: theme.colors.backgroundOverlay,
    // HorizontalBarChart.tsx:223-229, in order.
    defaultPalette: <Color>[
      palette.foreground2Rest(FluentPaletteFamily.blue),
      palette.foreground2Rest(FluentPaletteFamily.cornflower),
      palette.foreground2Rest(FluentPaletteFamily.darkGreen),
      palette.foreground2Rest(FluentPaletteFamily.navy),
      palette.foreground2Rest(FluentPaletteFamily.darkOrange),
    ],
  );
}
