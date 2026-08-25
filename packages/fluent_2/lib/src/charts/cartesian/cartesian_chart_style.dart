import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/chart_colors.dart';
import '../internal/chart_text_styles.dart';

/// The visual configuration of a Fluent cartesian chart.
///
/// Shaped exactly like `FluentBadgeStyle`: every visual property is a
/// [WidgetStateProperty], every field is nullable and means "inherit", and
/// resolution runs derived defaults, then the nearest cartesian chart theme,
/// then the widget's own style.
///
/// Only ten properties, because upstream only wires four of its nine style
/// slots: `root`, `chartWrapper`, `svgTooltip` and `chart`. The rest are
/// commented out at `useCartesianChartStyles.styles.ts:132-162`, so a bag
/// mirroring them would resolve into nothing.
@immutable
class FluentCartesianChartStyle {
  /// Creates a style. Omitted properties inherit.
  const FluentCartesianChartStyle({
    this.axisTextStyle,
    this.axisLineColor,
    this.gridLineColor,
    this.gridLineOpacity,
    this.axisTitleStyle,
    this.legendRowPadding,
    this.plotPadding,
    this.dimmedOpacity,
    this.tooltipBackgroundColor,
    this.tooltipBorderRadius,
  });

  /// Tick label text. `caption2Strong` upstream
  /// (`useCartesianChartStyles.styles.ts:63-66`).
  final WidgetStateProperty<TextStyle?>? axisTextStyle;

  /// The tick line colour (`useCartesianChartStyles.styles.ts:69`).
  ///
  /// The undimmed stroke token; [gridLineOpacity] carries the `opacity: 0.2`
  /// that sits beside it in the same rule.
  final WidgetStateProperty<Color?>? axisLineColor;

  /// The gridline colour. Same token as [axisLineColor] — gridlines are just
  /// tick lines with a negative inner size (`utilities.ts:851`).
  final WidgetStateProperty<Color?>? gridLineColor;

  /// Gridline and tick-line opacity
  /// (`useCartesianChartStyles.styles.ts:68`, `:84`).
  final WidgetStateProperty<double?>? gridLineOpacity;

  /// Axis title and axis annotation text (`Common.styles.ts:51-62`).
  final WidgetStateProperty<TextStyle?>? axisTitleStyle;

  /// Inset of the legend row beneath the plot
  /// (`useCartesianChartStyles.styles.ts:102-105`).
  final WidgetStateProperty<EdgeInsetsGeometry?>? legendRowPadding;

  /// Extra inset applied inside the plot box. Zero upstream; exposed so a chart
  /// embedded in a dense surface can breathe without restyling its margins.
  final WidgetStateProperty<EdgeInsetsGeometry?>? plotPadding;

  /// Opacity applied to a mark the legend has dimmed
  /// (`useCartesianChartStyles.styles.ts:98-101`).
  final WidgetStateProperty<double?>? dimmedOpacity;

  /// Fill behind an axis-label tooltip (`Common.styles.ts:44`).
  final WidgetStateProperty<Color?>? tooltipBackgroundColor;

  /// Corner radius of that tooltip (`Common.styles.ts:45`).
  final WidgetStateProperty<BorderRadius?>? tooltipBorderRadius;

  /// This style with the non-null properties of [other] layered on top.
  FluentCartesianChartStyle merge(FluentCartesianChartStyle? other) {
    if (other == null) return this;
    return FluentCartesianChartStyle(
      axisTextStyle: other.axisTextStyle ?? axisTextStyle,
      axisLineColor: other.axisLineColor ?? axisLineColor,
      gridLineColor: other.gridLineColor ?? gridLineColor,
      gridLineOpacity: other.gridLineOpacity ?? gridLineOpacity,
      axisTitleStyle: other.axisTitleStyle ?? axisTitleStyle,
      legendRowPadding: other.legendRowPadding ?? legendRowPadding,
      plotPadding: other.plotPadding ?? plotPadding,
      dimmedOpacity: other.dimmedOpacity ?? dimmedOpacity,
      tooltipBackgroundColor:
          other.tooltipBackgroundColor ?? tooltipBackgroundColor,
      tooltipBorderRadius: other.tooltipBorderRadius ?? tooltipBorderRadius,
    );
  }

  /// This style with the given properties replaced.
  FluentCartesianChartStyle copyWith({
    WidgetStateProperty<TextStyle?>? axisTextStyle,
    WidgetStateProperty<Color?>? axisLineColor,
    WidgetStateProperty<Color?>? gridLineColor,
    WidgetStateProperty<double?>? gridLineOpacity,
    WidgetStateProperty<TextStyle?>? axisTitleStyle,
    WidgetStateProperty<EdgeInsetsGeometry?>? legendRowPadding,
    WidgetStateProperty<EdgeInsetsGeometry?>? plotPadding,
    WidgetStateProperty<double?>? dimmedOpacity,
    WidgetStateProperty<Color?>? tooltipBackgroundColor,
    WidgetStateProperty<BorderRadius?>? tooltipBorderRadius,
  }) => FluentCartesianChartStyle(
    axisTextStyle: axisTextStyle ?? this.axisTextStyle,
    axisLineColor: axisLineColor ?? this.axisLineColor,
    gridLineColor: gridLineColor ?? this.gridLineColor,
    gridLineOpacity: gridLineOpacity ?? this.gridLineOpacity,
    axisTitleStyle: axisTitleStyle ?? this.axisTitleStyle,
    legendRowPadding: legendRowPadding ?? this.legendRowPadding,
    plotPadding: plotPadding ?? this.plotPadding,
    dimmedOpacity: dimmedOpacity ?? this.dimmedOpacity,
    tooltipBackgroundColor:
        tooltipBackgroundColor ?? this.tooltipBackgroundColor,
    tooltipBorderRadius: tooltipBorderRadius ?? this.tooltipBorderRadius,
  );

  /// Convenience for the common case of one value across every state.
  static FluentCartesianChartStyle from({
    TextStyle? axisTextStyle,
    Color? axisLineColor,
    Color? gridLineColor,
    double? gridLineOpacity,
    TextStyle? axisTitleStyle,
    EdgeInsetsGeometry? legendRowPadding,
    EdgeInsetsGeometry? plotPadding,
    double? dimmedOpacity,
    Color? tooltipBackgroundColor,
    BorderRadius? tooltipBorderRadius,
  }) => FluentCartesianChartStyle(
    axisTextStyle: _all(axisTextStyle),
    axisLineColor: _all(axisLineColor),
    gridLineColor: _all(gridLineColor),
    gridLineOpacity: _all(gridLineOpacity),
    axisTitleStyle: _all(axisTitleStyle),
    legendRowPadding: _all(legendRowPadding),
    plotPadding: _all(plotPadding),
    dimmedOpacity: _all(dimmedOpacity),
    tooltipBackgroundColor: _all(tooltipBackgroundColor),
    tooltipBorderRadius: _all(tooltipBorderRadius),
  );

  static WidgetStateProperty<T?>? _all<T>(T? value) =>
      value == null ? null : WidgetStatePropertyAll<T?>(value);

  @override
  bool operator ==(Object other) =>
      other is FluentCartesianChartStyle &&
      other.axisTextStyle == axisTextStyle &&
      other.axisLineColor == axisLineColor &&
      other.gridLineColor == gridLineColor &&
      other.gridLineOpacity == gridLineOpacity &&
      other.axisTitleStyle == axisTitleStyle &&
      other.legendRowPadding == legendRowPadding &&
      other.plotPadding == plotPadding &&
      other.dimmedOpacity == dimmedOpacity &&
      other.tooltipBackgroundColor == tooltipBackgroundColor &&
      other.tooltipBorderRadius == tooltipBorderRadius;

  @override
  int get hashCode => Object.hash(
    axisTextStyle,
    axisLineColor,
    gridLineColor,
    gridLineOpacity,
    axisTitleStyle,
    legendRowPadding,
    plotPadding,
    dimmedOpacity,
    tooltipBackgroundColor,
    tooltipBorderRadius,
  );
}

/// Derives the default cartesian chart style from [theme].
///
/// Colours and type come from the two stage-3 owners, [FluentChartColors] and
/// [FluentChartTextStyles], so that a chart, an axis and an exported image
/// never disagree about what `caption2Strong` resolved to.
FluentCartesianChartStyle resolveFluentCartesianChartStyle(
  FluentThemeData theme,
) {
  final colors = FluentChartColors.of(theme);
  final text = FluentChartTextStyles.of(theme);
  return FluentCartesianChartStyle.from(
    axisTextStyle: text.axisTick,
    // `stroke: tokens.colorNeutralForeground1`
    // (`useCartesianChartStyles.styles.ts:69`, `:85`), undimmed.
    // `FluentChartColors.axisTick` and `.gridLine` bake the 0.2 into the
    // colour; this bag keeps colour and opacity apart in `gridLineOpacity` so
    // a painter can dim a gridline further without recovering the token, and
    // taking the pre-multiplied slot here would square the 0.2.
    axisLineColor: colors.axisText,
    gridLineColor: colors.axisText,
    // `opacity: 0.2` on both axis line rules
    // (`useCartesianChartStyles.styles.ts:68`, `:84`).
    gridLineOpacity: 0.2,
    axisTitleStyle: text.axisTitle,
    // `marginTop: spacingVerticalS` and `marginLeft: spacingHorizontalXL`
    // (`useCartesianChartStyles.styles.ts:103-104`) — 8 and 20. Note this is
    // the *shell's* legend row, not the legend component's own 12px start
    // margin at `useLegendsStyles.styles.ts:11`, which only the SVG export
    // path uses.
    legendRowPadding: const EdgeInsetsDirectional.only(
      top: FluentSpacing.s,
      start: FluentSpacing.xl,
    ),
    // Upstream has no plot inset; the plot box is the margin box.
    plotPadding: EdgeInsets.zero,
    // `opacityChangeOnHover` (`useCartesianChartStyles.styles.ts:98-99`).
    dimmedOpacity: 0.1,
    tooltipBackgroundColor: colors.tooltipSurface,
    // `borderRadius: tokens.borderRadiusSmall` (`Common.styles.ts:45`) = 2.
    tooltipBorderRadius: const BorderRadius.all(FluentRadius.small),
  );
}
