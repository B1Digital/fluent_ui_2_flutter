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

/// Whether one hover or one keyboard stop covers a single mark or a whole group
/// of them.
///
/// Upstream calls this `isCalloutForStack` and documents it as callout-only
/// (`CartesianChart.types.ts:666-670`), but
/// `VerticalStackedBarChart.tsx:1141-1153` uses the same flag to move
/// `tabIndex`, `aria-label` and every pointer handler off each rect and onto the
/// stack's `<g>`, so it selects the interaction unit, not just the callout body.
enum FluentChartHitGranularity {
  /// Every region the delegate emits is its own hover target and its own
  /// keyboard stop. `isCalloutForStack` defaults to false
  /// (`CartesianChart.types.ts:669`).
  mark,

  /// Regions that share a `FluentChartHitRegion.index` are merged into one
  /// target whose bounds are their union.
  ///
  /// The **first** region of each index supplies the merged target's popover
  /// data and narration, which is where a group-mode chart puts its stack-wide
  /// values: `_getAriaLabel(singleChartData)` with no point argument
  /// (`VerticalStackedBarChart.tsx:1146`) and the reversed stack-wide
  /// `YValueHover` (`:281-292`).
  group,
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
    this.xAxisCategoryOrder,
    this.yAxisCategoryOrder,
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
    this.chartTitleForSemantics,
    this.eventLabelHeight,
    this.popoverBuilder,
    this.hitRegionGranularity = FluentChartHitGranularity.mark,
    this.closePopoverOnRegionExit = false,
    this.popoverAnchorsToRegion = false,
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

  /// Ordering applied to x categories, or null when the caller named none.
  ///
  /// `xAxisCategoryOrder?: AxisCategoryOrder` (`CartesianChart.types.ts:492`)
  /// is optional, and null here is that absent prop — **not** a synonym for
  /// [FluentAxisCategoryOrder.defaultOrder]. The doc comment says
  /// `@default 'default'`, but only the charts that fill the prop in with a
  /// spread or a destructuring default (VerticalBarChart.tsx:68,
  /// GroupedVerticalBarChart.tsx:79, VerticalStackedBarChart.tsx:88,
  /// GanttChart.tsx:45) actually see the string. HeatMapChart, ScatterChart and
  /// HorizontalBarChartWithAxis do not — their `props = {...}` parameter
  /// default only fires when React passes no props object at all, which it
  /// never does — so `props.xAxisCategoryOrder !== 'default'` is true for them,
  /// and an unset prop routes to `sortAxisCategories(…, undefined)` and its
  /// insertion-order arm rather than to the legacy sort.
  final FluentAxisCategoryOrder? xAxisCategoryOrder;

  /// Ordering applied to y categories, or null when the caller named none.
  ///
  /// See [xAxisCategoryOrder]: null is upstream's absent
  /// `yAxisCategoryOrder?: AxisCategoryOrder`
  /// (`CartesianChart.types.ts:498`), which several charts distinguish from the
  /// explicit `'default'`.
  final FluentAxisCategoryOrder? yAxisCategoryOrder;

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

  /// The narration prefix, composed by the chart.
  ///
  /// `CartesianChart.tsx:553` reads `props.chartTitle || 'Chart. '`, and each
  /// chart passes down a sentence that counts its own series — LineChart's
  /// `'${chartTitle}. Line chart with ${n} lines. '`
  /// (`LineChart.tsx:1843-1846`). Null falls back to the delegate's own
  /// `chartTitle`, and then to the generic prefix inside
  /// `buildFluentCartesianChartDescription`.
  final String? chartTitleForSemantics;

  /// The height of the event-annotation band above the plot.
  ///
  /// `LineChart.tsx:165` initialises it to 36 and `:179-181` overrides it from
  /// `eventAnnotationProps.labelHeight`. `LineChart.tsx:1958` reads
  /// `margins.top + eventLabelHeight` as the band's baseline, which is what a
  /// chart's `FluentCartesianChart.overlayBuilder` recomputes.
  ///
  /// // parity: the shell does NOT forward this into `FluentYAxisParams`.
  /// `CartesianChart.tsx:295-312` builds `YAxisParams` without
  /// `eventAnnotationProps` or `eventLabelHeight` and no other caller populates
  /// them (they exist only at `utilities.ts:210-211`), so the
  /// `margins.top! + (eventAnnotationProps! ? eventLabelHeight! : 0)` arm of
  /// `utilities.ts:848` never runs upstream and the labels overlap the top of
  /// the plot. Forwarding it would move every annotated line chart's y range
  /// 36 logical pixels down relative to upstream.
  final double? eventLabelHeight;

  /// A caller-supplied popover body, used in place of the built-in one.
  ///
  /// `ChartPopover.tsx:54` renders `customCallout.customizedCallout` when it is
  /// present and `:56` and `:60` both suppress the default bodies when it is.
  final WidgetBuilder? popoverBuilder;

  /// Whether a hover and a keyboard stop cover one mark or a whole group.
  final FluentChartHitGranularity hitRegionGranularity;

  /// Whether moving the pointer off a mark, but still inside the plot, closes
  /// the popover.
  ///
  /// `HorizontalBarChartWithAxis.tsx:266-268` is the only per-mark leave
  /// handler in the library that closes the callout. The same handler is an
  /// empty stub at `VerticalBarChart.tsx:496-498`,
  /// `VerticalStackedBarChart.tsx:802-804` and `HeatMapChart.tsx:166-168`, so
  /// the default false reproduces a callout that stays on the last mark until
  /// the pointer leaves the chart altogether.
  final bool closePopoverOnRegionExit;

  /// Whether the popover anchors to the hovered region's centre rather than to
  /// the pointer.
  ///
  /// `GroupedVerticalBarChart.tsx:437` and `:970` hand `Popover` the hovered
  /// bar element as its positioning target; every other chart builds a
  /// zero-size virtual element at the pointer (`ChartPopover.tsx:23-40`). A
  /// keyboard stop has no pointer, so it anchors to the region either way.
  final bool popoverAnchorsToRegion;

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

  /// A copy of this bag with the listed fields replaced.
  ///
  /// // ponytail: only the eleven fields a chart actually rebrands are
  /// parameters. Every shell chart wraps its caller's bag to add its own
  /// narration (`LineChart.tsx:1843-1846`), its band height (`:165`), its
  /// popover body (`GanttChart.tsx:604`), its focus granularity
  /// (`VerticalStackedBarChart.tsx:486-489`), the scatterpolar y bounds at
  /// `LineChart.tsx:1922` and `ScatterChart.tsx:742`, and the hard-coded tick
  /// values at `HeatMapChart.tsx:805-807` and
  /// `GroupedVerticalBarChart.tsx:1006`; the other 39 fields belong to the
  /// caller. Add a parameter when a caller needs one. An omitted parameter
  /// keeps the current value, so a null can never be written over a field that
  /// was set.
  FluentCartesianChartProps copyWith({
    String? chartTitleForSemantics,
    double? eventLabelHeight,
    WidgetBuilder? popoverBuilder,
    FluentChartHitGranularity? hitRegionGranularity,
    bool? closePopoverOnRegionExit,
    bool? popoverAnchorsToRegion,
    double? tickPadding,
    double? xAxistickSize,
    bool? showRoundOffXTickValues,
    double? yMinValue,
    double? yMaxValue,
  }) => FluentCartesianChartProps(
    margins: margins,
    hideLegend: hideLegend,
    hideTooltip: hideTooltip,
    tickValues: tickValues,
    yAxisTickFormat: yAxisTickFormat,
    secondaryYScaleOptions: secondaryYScaleOptions,
    yMinValue: yMinValue ?? this.yMinValue,
    yMaxValue: yMaxValue ?? this.yMaxValue,
    xMinValue: xMinValue,
    xMaxValue: xMaxValue,
    yAxisTickCount: yAxisTickCount,
    xAxisTickCount: xAxisTickCount,
    xAxistickSize: xAxistickSize ?? this.xAxistickSize,
    annotations: annotations,
    tickPadding: tickPadding ?? this.tickPadding,
    showXAxisLablesTooltip: showXAxisLablesTooltip,
    noOfCharsToTruncate: noOfCharsToTruncate,
    wrapXAxisLables: wrapXAxisLables,
    rotateXAxisLables: rotateXAxisLables,
    dateLocalizeOptions: dateLocalizeOptions,
    timeFormatLocale: timeFormatLocale,
    customDateTimeFormatter: customDateTimeFormatter,
    reflowMode: reflowMode,
    xAxisTitle: xAxisTitle,
    yAxisTitle: yAxisTitle,
    secondaryYAxisTitle: secondaryYAxisTitle,
    useUTC: useUTC,
    roundedTicks: roundedTicks,
    hideTickOverlap: hideTickOverlap,
    xAxisAnnotation: xAxisAnnotation,
    yAxisAnnotation: yAxisAnnotation,
    xAxisCategoryOrder: xAxisCategoryOrder,
    yAxisCategoryOrder: yAxisCategoryOrder,
    xScaleType: xScaleType,
    yScaleType: yScaleType,
    secondaryYScaleType: secondaryYScaleType,
    yAxisTickValues: yAxisTickValues,
    xAxis: xAxis,
    yAxis: yAxis,
    showYAxisLables: showYAxisLables,
    showYAxisLablesTooltip: showYAxisLablesTooltip,
    showRoundOffXTickValues:
        showRoundOffXTickValues ?? this.showRoundOffXTickValues,
    enableFirstRenderOptimization: enableFirstRenderOptimization,
    chartTitleForSemantics:
        chartTitleForSemantics ?? this.chartTitleForSemantics,
    eventLabelHeight: eventLabelHeight ?? this.eventLabelHeight,
    popoverBuilder: popoverBuilder ?? this.popoverBuilder,
    hitRegionGranularity: hitRegionGranularity ?? this.hitRegionGranularity,
    closePopoverOnRegionExit:
        closePopoverOnRegionExit ?? this.closePopoverOnRegionExit,
    popoverAnchorsToRegion:
        popoverAnchorsToRegion ?? this.popoverAnchorsToRegion,
  );
}
