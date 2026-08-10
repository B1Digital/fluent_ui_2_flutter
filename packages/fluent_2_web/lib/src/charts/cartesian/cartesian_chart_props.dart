import 'package:flutter/widgets.dart';

import '../axis/axis_builders.dart';
import '../axis/tick_format.dart';
import '../internal/d3/time_format.dart' as d3;
import '../model/chart_annotation.dart';
import '../model/chart_common.dart';

/// How a cartesian chart behaves when its box is narrower than its content.
enum FluentChartReflowMode {
  /// The chart shrinks with its box. Upstream `'none'`
  /// (`CartesianChart.types.ts:415-417`).
  none,

  /// The chart refuses to shrink below its computed minimum width and scrolls
  /// horizontally instead.
  ///
  /// Upstream pairs `'min-width'` with `chartWrapper { overflow: auto }`
  /// (`useCartesianChartStyles.styles.ts:51-52`). Flutter has no automatic
  /// equivalent, so `FluentCartesianChart` mounts an explicit horizontal
  /// [SingleChildScrollView] — design spec section 5.1.
  minWidth,
}

/// Bounds for the optional secondary y-scale.
@immutable
class FluentSecondaryYScaleOptions {
  /// Creates secondary-scale bounds.
  const FluentSecondaryYScaleOptions({
    this.yMinValue = 0,
    this.yMaxValue = 100,
  });

  /// The lower bound. `CartesianChart.tsx:344` reads `|| 0`.
  final double yMinValue;

  /// The upper bound.
  ///
  /// `CartesianChart.tsx:345` reads `?? 100`, which makes this the only y bound
  /// in the shell whose default is not zero.
  final double yMaxValue;
}

/// Every public prop `CartesianChart` accepts, with the defaults read out of
/// the implementation rather than out of its doc comments — the two disagree in
/// at least one place (`xAxistickSize` is 6 in `utilities.ts:266` and 10 in the
/// `@default` tag at `CartesianChart.types.ts:314`).
///
/// Seven upstream props are deliberately absent.
/// // ponytail: `className`, `xAxisTickPadding`, `enableReflow`, `strokeWidth`
/// and `href` are declared upstream and never read by the shell; `height` and
/// `width` are used only as React change-detection keys
/// (`CartesianChart.tsx:112`) and never as sizes, which is what [BoxConstraints]
/// already does; `optimizeLargeData` is never populated, making
/// `LineChart.tsx:1945` a dead branch.
@immutable
class FluentCartesianChartProps {
  /// Creates a config bag. Every default here is code-verified.
  const FluentCartesianChartProps({
    this.margins,
    this.hideLegend = false,
    this.hideTooltip = false,
    this.tickValues,
    this.yAxisTickFormat,
    this.secondaryYScaleOptions,
    this.yMinValue = 0,
    this.yMaxValue = 0,
    this.xMinValue,
    this.xMaxValue,
    this.yAxisTickCount = 4,
    this.xAxisTickCount = 6,
    this.xAxistickSize = 6,
    this.annotations = const <FluentChartAnnotation>[],
    this.tickPadding,
    this.showXAxisLablesTooltip = false,
    this.noOfCharsToTruncate = 4,
    this.wrapXAxisLables = false,
    this.rotateXAxisLables = false,
    this.dateLocalizeOptions,
    this.timeFormatLocale,
    this.customDateTimeFormatter,
    this.reflowMode = FluentChartReflowMode.none,
    this.xAxisTitle,
    this.yAxisTitle,
    this.secondaryYAxisTitle,
    this.useUTC,
    this.roundedTicks = false,
    this.hideTickOverlap = true,
    this.xAxisAnnotation,
    this.yAxisAnnotation,
    this.xAxisCategoryOrder = FluentAxisCategoryOrder.defaultOrder,
    this.yAxisCategoryOrder = FluentAxisCategoryOrder.defaultOrder,
    this.xScaleType = FluentAxisScaleType.auto,
    this.yScaleType = FluentAxisScaleType.auto,
    this.secondaryYScaleType = FluentAxisScaleType.auto,
    this.yAxisTickValues,
    this.xAxis,
    this.yAxis,
    this.showYAxisLables = false,
    this.showYAxisLablesTooltip = false,
    this.showRoundOffXTickValues = true,
    this.enableFirstRenderOptimization = false,
  }) : assert(
         useUTC == null || useUTC is bool || useUTC is String,
         'useUTC is `string | boolean` upstream (CartesianChart.types.ts:448).',
       );

  /// Physical margin overrides, merged **last** and never RTL-swapped.
  ///
  /// `CartesianChart.tsx:665-668` spreads this over the computed margins after
  /// the swap at `:661-663`, so a user value is interpreted in physical
  /// left/right terms even in a right-to-left chart.
  final FluentChartMargins? margins;

  /// Whether the legend row is omitted. `CartesianChart.types.ts:226`.
  final bool hideLegend;

  /// Whether the hover popover is suppressed. `CartesianChart.types.ts:232`.
  final bool hideTooltip;

  /// Explicit x tick values, forwarded into the domain/range solve
  /// (`CartesianChart.tsx:201`).
  final List<Object>? tickValues;

  /// Formatter for y tick labels, replacing the default numeric formatter.
  final String Function(double value)? yAxisTickFormat;

  /// Bounds for the secondary y-scale, or null for no secondary axis.
  final FluentSecondaryYScaleOptions? secondaryYScaleOptions;

  /// Lower y bound. `CartesianChart.tsx:302`.
  final double yMinValue;

  /// Upper y bound. `CartesianChart.tsx:303`.
  final double yMaxValue;

  /// Lower x bound, or null. `CartesianChart.tsx:222`.
  final double? xMinValue;

  /// Upper x bound, or null. `CartesianChart.tsx:223`.
  final double? xMaxValue;

  /// Requested y tick count. `utilities.ts:811`.
  final int yAxisTickCount;

  /// Requested x tick count. `utilities.ts:285`.
  final int xAxisTickCount;

  /// Length of an x tick line. `utilities.ts:266`.
  final double xAxistickSize;

  /// Annotations drawn over the plot. `CartesianChart.tsx:463`.
  final List<FluentChartAnnotation> annotations;

  /// The user's requested gap between an x tick line and its label.
  ///
  /// Read through [resolvedXAxisTickPadding], which reproduces the defect that
  /// discards it.
  final double? tickPadding;

  /// Whether x tick labels are truncated and given a hover tooltip.
  /// `CartesianChart.types.ts:351`.
  final bool showXAxisLablesTooltip;

  /// How many characters survive truncation. `CartesianChart.tsx:153`.
  final int noOfCharsToTruncate;

  /// Whether x tick labels word-wrap. `CartesianChart.types.ts:364`.
  final bool wrapXAxisLables;

  /// Whether x tick labels rotate by -45 degrees.
  /// `CartesianChart.types.ts:370`.
  final bool rotateXAxisLables;

  /// Locale options for date tick labels. `CartesianChart.tsx:253`.
  final FluentDateTimeFormatOptions? dateLocalizeOptions;

  /// A d3-time-format locale for date tick labels. `CartesianChart.tsx:254`.
  final d3.TimeLocaleDefinition? timeFormatLocale;

  /// A caller-supplied date formatter, tried before the locale formatters.
  /// `CartesianChart.tsx:255`.
  final String Function(DateTime date)? customDateTimeFormatter;

  /// Reflow behaviour. `CartesianChart.types.ts:417`.
  final FluentChartReflowMode reflowMode;

  /// The x-axis title, or null. Adds 20 to the bottom margin when non-empty.
  final String? xAxisTitle;

  /// The y-axis title, or null. Adds 24 to the left margin when non-empty.
  final String? yAxisTitle;

  /// The secondary y-axis title, or null. Adds 24 to the right margin.
  final String? secondaryYAxisTitle;

  /// `true` or `'utc'` selects a UTC time scale. `CartesianChart.tsx:256`.
  final Object? useUTC;

  /// Whether y ticks are rounded to nice values. `utilities.ts:796`.
  final bool roundedTicks;

  /// Whether overlapping x ticks are dropped.
  ///
  /// Read through [resolveHideTickOverlap], which reproduces the override at
  /// `CartesianChart.tsx:220`.
  final bool hideTickOverlap;

  /// Text drawn above the plot, sharing the x-title constant.
  /// `CartesianChart.tsx:700`.
  final String? xAxisAnnotation;

  /// Text drawn alongside the secondary y position.
  /// `CartesianChart.tsx:704`.
  final String? yAxisAnnotation;

  /// Ordering applied to x categories.
  final FluentAxisCategoryOrder xAxisCategoryOrder;

  /// Ordering applied to y categories.
  final FluentAxisCategoryOrder yAxisCategoryOrder;

  /// Linear or logarithmic x scale. `CartesianChart.tsx:244`.
  final FluentAxisScaleType xScaleType;

  /// Linear or logarithmic primary y scale. `CartesianChart.tsx:371`.
  final FluentAxisScaleType yScaleType;

  /// Linear or logarithmic secondary y scale. `CartesianChart.tsx:359`.
  final FluentAxisScaleType secondaryYScaleType;

  /// Explicit y tick values. `CartesianChart.tsx:311`.
  final List<Object>? yAxisTickValues;

  /// Extra x-axis configuration, spread last into the x params
  /// (`CartesianChart.tsx:224`).
  final FluentAxisConfig? xAxis;

  /// Extra y-axis configuration, spread last into the y params
  /// (`CartesianChart.tsx:312`).
  final FluentAxisConfig? yAxis;

  /// Whether the left margin grows to fit the longest y tick label.
  /// `CartesianChart.types.ts:549`.
  final bool showYAxisLables;

  /// Whether y tick labels are truncated and given a hover tooltip.
  /// `CartesianChart.types.ts:555`.
  final bool showYAxisLablesTooltip;

  /// Whether the numeric x domain is passed through `nice()`.
  /// `CartesianChart.tsx:212`.
  final bool showRoundOffXTickValues;

  /// Whether the first frame is skipped until the box has a usable size.
  /// `CartesianChart.tsx:190`.
  final bool enableFirstRenderOptimization;

  /// The gap between an x tick line and its label.
  ///
  /// `CartesianChart.tsx:215` is written
  /// `tickPadding: props.tickPadding || props.showXAxisLablesTooltip ? 5 : 10`,
  /// which JavaScript parses as
  /// `(tickPadding || showXAxisLablesTooltip) ? 5 : 10`. A caller's number is
  /// therefore never used: supplying `12` yields `5`. An explicit `0` is
  /// JavaScript-falsy and skips the first operand entirely.
  ///
  /// The defect itself lives in [resolveShellXAxisTickPadding], which the axis
  /// builders were written against; this getter is the shell's only caller of
  /// it, so the two can never drift.
  double get resolvedXAxisTickPadding => resolveShellXAxisTickPadding(
    tickPadding: tickPadding,
    showXAxisLablesTooltip: showXAxisLablesTooltip,
  );

  /// Whether overlapping x ticks are dropped, given the resolved tick layout.
  ///
  /// `CartesianChart.tsx:220`: rotation and the automatic tick layout both turn
  /// overlap hiding off outright, because each already resolves overlap itself.
  bool resolveHideTickOverlap(FluentTickLayout tickLayout) =>
      rotateXAxisLables || tickLayout == FluentTickLayout.auto
      ? false
      : hideTickOverlap;
}
