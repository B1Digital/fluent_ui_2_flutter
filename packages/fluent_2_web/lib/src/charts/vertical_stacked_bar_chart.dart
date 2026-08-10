import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'axis/axis_builders.dart' as builders;
import 'axis/axis_types.dart';
import 'axis/domain_range.dart';
import 'cartesian/cartesian_layout.dart';
import 'cartesian/cartesian_series_delegate.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/chart_text_styles.dart';
import 'internal/chart_utils.dart';
import 'internal/d3/array_stats.dart' as d3;
import 'internal/d3/scale.dart';
import 'internal/d3/scale_linear.dart';
import 'model/bar_data.dart';
import 'model/chart_common.dart';
import 'model/chart_value.dart';
import 'vertical_stacked_bar_chart_style.dart';

/// Fraction of a stack's height that may be spent on gaps
/// (`VerticalStackedBarChart.tsx:64`).
const double kBarGapMultiplier = 0.2;

/// Floor on a gap once gaps are enabled (`VerticalStackedBarChart.tsx:65`).
const double kBarGapMin = 1;

/// The y value a numeric stack is measured from — `Y_ORIGIN`, which upstream
/// fixes at 0 (`VerticalStackedBarChart.tsx:118`).
const double kStackedBarYOrigin = 0;

/// The output of the vertical stacked bar chart's gap-and-scale solve.
@immutable
class FluentStackedBarGapMetrics {
  /// Creates the metrics.
  const FluentStackedBarGapMetrics({
    required this.gapHeight,
    required this.heightValueScale,
    required this.absStackTotal,
  });

  /// Pixels between adjacent segments, 0 when `barGapMax` is 0.
  final double gapHeight;

  /// Pixels per data unit once the gaps have been deducted. Always 0 on a
  /// category y axis.
  final double heightValueScale;

  /// The sum of the segments' absolute values, 0 on a category y axis.
  final double absStackTotal;
}

/// Ports `_getBarGapAndScale` (`VerticalStackedBarChart.tsx:806-847`).
///
/// The subtle part is the one-percent floor: each segment's share is raised to
/// 1% **before** the shares are summed (`:829-835`), so `scalingRatio` can
/// exceed 1 and shrink every segment in the stack. A share of exactly 0 is
/// exempt, which is why the guard reads `v < 1 && v !== 0`.
///
/// [defaultTotalHeight] overrides the height measured through [yBarScale], as
/// upstream's `defaultTotalHeight ??` arms do (`:821-822`, `:827-828`).
FluentStackedBarGapMetrics computeFluentStackedBarGapMetrics({
  required List<FluentStackedBarDatum> bars,
  required Scale yBarScale,
  required bool isStringYAxis,
  required double barGapMax,
  double? defaultTotalHeight,
}) {
  double totalData = 0;
  final double totalHeight;
  double scalingRatio = 1;

  if (isStringYAxis) {
    totalHeight =
        defaultTotalHeight ??
        bars.fold<double>(
          0,
          (double acc, FluentStackedBarDatum b) =>
              acc + (yBarScale(b.data) ?? 0),
        );
  } else {
    for (final b in bars) {
      totalData += (b.data as num).toDouble().abs();
    }
    totalHeight =
        defaultTotalHeight ??
        ((yBarScale(totalData) ?? 0) - (yBarScale(kStackedBarYOrigin) ?? 0))
            .abs();
    double sumOfPercent = 0;
    for (final b in bars) {
      // `:830` — the share as a percentage, then the floor at `:831-833`.
      var value = ((b.data as num).toDouble().abs() / totalData) * 100;
      if (value < 1 && value != 0) {
        value = 1;
      }
      sumOfPercent += value;
    }
    scalingRatio = sumOfPercent != 0 ? sumOfPercent / 100 : 1;
  }

  // `gaps = barGapMax && bars.length - 1` (`:838`) — JS `&&` yields 0, not
  // false, when barGapMax is 0.
  final gaps = barGapMax == 0 ? 0.0 : (bars.length - 1).toDouble();
  final gapHeight = gaps == 0
      ? 0.0
      : math.max(
          kBarGapMin,
          math.min(barGapMax, (totalHeight * kBarGapMultiplier) / gaps),
        );
  return FluentStackedBarGapMetrics(
    gapHeight: gapHeight,
    heightValueScale: isStringYAxis
        ? 0
        : (totalHeight - gapHeight * gaps) / (totalData * scalingRatio),
    absStackTotal: totalData,
  );
}

/// One placed stack segment.
@immutable
class FluentStackedBarSegmentLayout {
  /// Creates a segment layout.
  const FluentStackedBarSegmentLayout({
    required this.rect,
    required this.colour,
    required this.opacity,
    required this.stackIndex,
    required this.segmentIndex,
    required this.isLast,
    this.roundedTopPath,
  });

  /// The segment's rectangle.
  final Rect rect;

  /// Resolved fill, already flattened for high contrast.
  final Color colour;

  /// 1 highlighted, 0.1 dimmed (`VerticalStackedBarChart.tsx:1101`).
  final double opacity;

  /// Index of the owning stack.
  final int stackIndex;

  /// Index inside the filtered segment list.
  final int segmentIndex;

  /// Whether this is the topmost drawn segment of its stack.
  final bool isLast;

  /// The arc-topped path used instead of a plain rect when the stack corner
  /// radius applies (`VerticalStackedBarChart.tsx:1089-1099`).
  final Path? roundedTopPath;
}

/// Renders stacked vertical bars into the shared cartesian shell.
///
/// Ports `VerticalStackedBarChart.tsx` (1426 lines) — the largest of the bar
/// charts and the only one supporting a category y axis.
class FluentVerticalStackedBarChartDelegate
    extends FluentCartesianSeriesDelegate {
  /// Creates a delegate.
  const FluentVerticalStackedBarChartDelegate({
    required this.stacks,
    required this.style,
    required this.colors,
    required this.measurer,
    required this.textStyles,
    required this.selectedLegends,
    required this.palette,
    this.activeLegend,
    this.activeXAxisDataPoint,
    this.barWidthProp,
    this.maxBarWidth = 24,
    this.barGapMax = 0,
    this.barCornerRadius = 0,
    this.barMinimumHeight = 0,
    this.hideLabels = false,
    this.roundCorners = false,
    this.mode,
    this.useUtc = false,
    this.yMinValue,
    this.yMaxValue,
    this.xAxisInnerPadding,
    this.xAxisOuterPadding,
    this.xAxisPadding,
    this.xAxisCategoryOrder = FluentAxisCategoryOrder.defaultOrder,
    this.yAxisCategoryOrder = FluentAxisCategoryOrder.defaultOrder,
    this.yAxisTickFormat,
  });

  /// The stacks, in author order.
  final List<FluentVerticalStackedBarGroup> stacks;

  /// The resolved style.
  final FluentVerticalStackedBarChartStyle style;

  /// Resolved chart colours.
  final FluentChartColors colors;

  /// The chart subtree's single text measurer.
  final FluentChartTextMeasurer measurer;

  /// Resolved chart text styles.
  final FluentChartTextStyles textStyles;

  /// Legend titles selected by the user.
  final List<String> selectedLegends;

  /// The five-token segment palette (`VerticalStackedBarChart.tsx:316-322`).
  final List<Color> palette;

  /// Legend title currently hovered.
  final String? activeLegend;

  /// The x value whose line dot is enlarged.
  final Object? activeXAxisDataPoint;

  /// `number | 'default' | 'auto'`.
  final Object? barWidthProp;

  /// Bar width ceiling — 24 (`VerticalStackedBarChart.tsx:90`).
  final double maxBarWidth;

  /// Maximum gap between segments — 0 disables gaps
  /// (`VerticalStackedBarChart.tsx:815`).
  final double barGapMax;

  /// Corner radius applied to the topmost segment only
  /// (`VerticalStackedBarChart.tsx:986`).
  final double barCornerRadius;

  /// Floor on a segment's height (`VerticalStackedBarChart.tsx:986`).
  final double barMinimumHeight;

  /// Whether the stack total labels are suppressed.
  final bool hideLabels;

  /// Whether segments get a 3px corner radius.
  final bool roundCorners;

  /// `'plotly'` or null.
  final String? mode;

  /// Whether a date x axis uses UTC. VSBC branches here where
  /// VerticalBarChart always uses UTC (`VerticalStackedBarChart.tsx:873`).
  final bool useUtc;

  /// The caller's y floor, `props.yMinValue` (`VerticalStackedBarChart.tsx:404`).
  final double? yMinValue;

  /// The caller's y ceiling, `props.yMaxValue`
  /// (`VerticalStackedBarChart.tsx:403`).
  final double? yMaxValue;

  /// Band inner padding override.
  @override
  final double? xAxisInnerPadding;

  /// Band outer padding override.
  @override
  final double? xAxisOuterPadding;

  /// Legacy shorthand feeding both paddings.
  @override
  final double? xAxisPadding;

  /// Ordering applied to a category x axis.
  final FluentAxisCategoryOrder xAxisCategoryOrder;

  /// Ordering applied to a category y axis.
  final FluentAxisCategoryOrder yAxisCategoryOrder;

  /// Caller-supplied y tick formatter, reused for total labels.
  final String Function(double value)? yAxisTickFormat;

  @override
  FluentChartType get chartType => FluentChartType.verticalStackedBarChart;

  @override
  FluentChartAxisType get xAxisType => stacks.isEmpty
      // `_adjustProps` (`VerticalStackedBarChart.tsx:325-326`) — an absent or
      // invalid first x makes the axis categorical.
      ? FluentChartAxisType.category
      : isInvalidChartValue(stacks.first.xAxisPoint)
      ? FluentChartAxisType.category
      : getTypeOfAxis(stacks.first.xAxisPoint, isXAxis: true);

  @override
  FluentChartAxisType get yAxisType =>
      // `_initYAxisParams` (`VerticalStackedBarChart.tsx:1247-1249`). The
      // line-data fallback at `:1250-1256` lands with the line overlay.
      stacks.isEmpty || stacks.first.chartData.isEmpty
      ? FluentChartAxisType.numeric
      : getTypeOfAxis(stacks.first.chartData.first.data, isXAxis: false);

  /// The colour segment [index] of a stack draws in, before high-contrast
  /// flattening. The legend reads this too, so a swatch and its segments can
  /// never disagree.
  ///
  /// ponytail: `_getLegendData` picks this with
  /// `defaultPalette[Math.floor(Math.random() * 4 + 1)]`
  /// (`VerticalStackedBarChart.tsx:167`), re-rolled on every render and never
  /// yielding entry 0, so a legend swatch changes colour on an unrelated state
  /// change and never matches its own bars. Spec section 5.2 exception 1
  /// exempts non-determinism from bug fidelity: no golden can pin a random
  /// colour. The deterministic rule below is the same one the marks use
  /// upstream, `_colors[index]` (`:1035`), extended with `% length` because
  /// that index is `undefined` from the sixth segment on and leaves the bar
  /// unpainted.
  Color segmentPaletteColour(FluentStackedBarDatum datum, int index) =>
      datum.color ?? palette[index % palette.length];

  /// The `{ x, y }` row per stack that the axis solves read.
  ///
  /// Ports `_createDataSetLayer` (`VerticalStackedBarChart.tsx:336-353`): the y
  /// is the stack total, or 0 on a category y axis.
  List<Object> get dataset => <Object>[
    for (final stack in stacks)
      if (stack.xAxisPoint is DateTime)
        FluentVerticalStackedBarDataPoint(
          x: stack.xAxisPoint,
          y: _stackTotal(stack),
        )
      else
        FluentChartXYPoint(x: stack.xAxisPoint, y: _stackTotal(stack)),
  ];

  double _stackTotal(FluentVerticalStackedBarGroup stack) {
    if (yAxisType == FluentChartAxisType.category) {
      // VerticalStackedBarChart.tsx:338-342.
      return 0;
    }
    var total = 0.0;
    for (final segment in stack.chartData) {
      total += (segment.data as num).toDouble();
    }
    return total;
  }

  /// Builds the six-verb rounded-top path.
  ///
  /// `M x (y+r) a r r 0 0 1 r -r h (w-2r) a r r 0 0 1 r r v (h-r) h -w z`
  /// (`VerticalStackedBarChart.tsx:1089-1099`).
  static Path roundedTopPath({
    required double x,
    required double y,
    required double width,
    required double height,
    required double radius,
  }) => Path()
    ..moveTo(x, y + radius)
    ..arcToPoint(Offset(x + radius, y), radius: Radius.circular(radius))
    // The 2 is the two corners the straight top run has to clear.
    ..relativeLineTo(width - 2 * radius, 0)
    ..arcToPoint(Offset(x + width, y + radius), radius: Radius.circular(radius))
    ..relativeLineTo(0, height - radius)
    ..relativeLineTo(-width, 0)
    ..close();

  /// Resolves every stack segment.
  ///
  /// Ports `_createBar` (`VerticalStackedBarChart.tsx:980-1223`) for the
  /// numeric y axis; the category y branch lands with the line overlay.
  List<FluentStackedBarSegmentLayout> segmentsFor(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) {
    if (stacks.isEmpty) {
      return const <FluentStackedBarSegmentLayout>[];
    }
    final isBandX = xAxisType == FluentChartAxisType.category;
    // `VerticalStackedBarChart.tsx:988-991` — only the band axis re-solves the
    // width against the bandwidth.
    final barWidth = isBandX
        ? getBarWidth(
            barWidthProp,
            maxBarWidth,
            adjustedValue: context.xScale.bandwidth,
          )
        : getBarWidth(barWidthProp, maxBarWidth);
    // `stringXAxis ? (bandwidth - _barWidth) / 2 : -_barWidth / 2`
    // (`:1002-1003`); both 2s centre the bar on its x.
    final translate = isBandX
        ? (context.xScale.bandwidth - barWidth) / 2
        : -barWidth / 2;
    final bottom = layout.margins.bottom ?? 0;
    final top = layout.margins.top ?? 0;
    final minMax = resolveYMinMax();
    // `_getAxisData` (`:403-404`) then `_getScales` (`:850-853`).
    //
    // parity gap: upstream reads `_yMin` and `_yMax` off the **resolved tick
    // domain**, which the shell writes back through `getAxisData`; the delegate
    // has no such channel, so the data extent stands in. The two agree whenever
    // the ticks land on the data, and diverge by the amount `prepareDatapoints`
    // rounds the ceiling outward.
    final yMin = math.min(minMax.startValue, yMinValue ?? kStackedBarYOrigin);
    final yMax = math.max(minMax.endValue, yMaxValue ?? kStackedBarYOrigin);
    final yBarScale = scaleLinear()
      ..domainOf(<double>[
        math.min(kStackedBarYOrigin, yMin),
        math.max(kStackedBarYOrigin, yMax),
      ])
      ..rangeOf(<double>[0, layout.size.height - bottom - top]);
    final dim = style.barOpacity!.resolve(<WidgetState>{WidgetState.disabled})!;
    // `_noLegendHighlighted` (`:424-426`).
    final noneHighlighted =
        selectedLegends.isEmpty &&
        (activeLegend == null || activeLegend!.isEmpty);

    final out = <FluentStackedBarSegmentLayout>[];
    for (var si = 0; si < stacks.length; si++) {
      final stack = stacks[si];
      // `barsToDisplay` (`:1006-1014`).
      final visible = stack.chartData
          .where((segment) => segment.data != 0 && segment.data != '')
          .toList(growable: false);
      if (visible.isEmpty) {
        // `:1016-1018` returns undefined, and `:1222` filters the stack out.
        continue;
      }
      final metrics = computeFluentStackedBarGapMetrics(
        bars: visible,
        yBarScale: yBarScale,
        isStringYAxis: false,
        barGapMax: barGapMax,
      );
      if (metrics.heightValueScale < 0) {
        // VerticalStackedBarChart.tsx:1021-1023.
        continue;
      }
      // `:1025-1028` — the pixel the stack grows out of, in both directions.
      final baseline =
          layout.size.height - bottom - (yBarScale(kStackedBarYOrigin) ?? 0);
      var positiveStart = baseline;
      var negativeStart = baseline;
      final x = context.xScale(stack.xAxisPoint)! + translate;
      for (var k = 0; k < visible.length; k++) {
        final value = (visible[k].data as num).toDouble();
        final gapOffset = k > 0 ? metrics.gapHeight : 0.0;
        // VerticalStackedBarChart.tsx:1068.
        var height = (metrics.heightValueScale * value).abs();
        // `max(heightValueScale * absStackTotal / 100, barMinimumHeight)`
        // (`:1070`); the 100 turns the stack total into one percent of itself.
        final minHeight = math.max(
          metrics.heightValueScale * metrics.absStackTotal / 100.0,
          barMinimumHeight,
        );
        if (height < minHeight) {
          height = minHeight;
        }
        final double topEdge;
        if (value >= kStackedBarYOrigin) {
          // VerticalStackedBarChart.tsx:1073-1075.
          positiveStart -= height + gapOffset;
          topEdge = positiveStart;
        } else {
          // VerticalStackedBarChart.tsx:1077-1078.
          topEdge = negativeStart + gapOffset;
          negativeStart = topEdge + height;
        }
        // `_isLegendHighlighted(...) || _noLegendHighlighted()` (`:1037`).
        final highlighted =
            noneHighlighted ||
            isLegendHighlightedMulti(
              visible[k].legend,
              selectedLegends: selectedLegends,
              activeLegend: activeLegend,
            );
        final isLast = k == visible.length - 1;
        out.add(
          FluentStackedBarSegmentLayout(
            rect: Rect.fromLTWH(x, topEdge, barWidth, height),
            colour: colors.flattenMark(segmentPaletteColour(visible[k], k)),
            opacity: highlighted ? 1 : dim,
            stackIndex: si,
            segmentIndex: k,
            isLast: isLast,
            // `barCornerRadius && barHeight > barCornerRadius &&
            // index === barsToDisplay.length - 1` (`:1089`).
            roundedTopPath:
                isLast && barCornerRadius > 0 && height > barCornerRadius
                ? roundedTopPath(
                    x: x,
                    y: topEdge,
                    width: barWidth,
                    height: height,
                    radius: barCornerRadius,
                  )
                : null,
          ),
        );
      }
    }
    return out;
  }

  @override
  FluentChartDomainRange resolveXDomainRange({
    required FluentChartMargins margins,
    required double containerWidth,
    required bool isRtl,
    required double? barWidth,
    required List<Object>? tickValues,
  }) => switch (xAxisType) {
    // VerticalStackedBarChart.tsx:501-517.
    FluentChartAxisType.numeric => domainRangeOfVSBCNumeric(
      dataset,
      margins,
      containerWidth,
      isRtl: isRtl,
    ),
    FluentChartAxisType.date =>
      domainRangeOfDateForAreaLineScatterVerticalBarCharts(
        dataset,
        margins,
        containerWidth,
        isRtl: isRtl,
        chartType: FluentChartType.verticalStackedBarChart,
        tickValues: tickValues?.cast<DateTime>() ?? const <DateTime>[],
      ),
    FluentChartAxisType.category => domainRangeOfXStringAxis(
      margins,
      containerWidth,
      isRtl: isRtl,
    ),
  };

  @override
  FluentChartMinMax resolveYMinMax({bool useSecondaryYScale = false}) {
    if (useSecondaryYScale) {
      // VerticalStackedBarChart.tsx:1234-1243 — only lines reach the secondary
      // scale in this chart.
      final values = <double>[
        for (final stack in stacks)
          for (final line
              in stack.lineData ?? const <FluentStackedBarLineDatum>[])
            if (line.useSecondaryYScale && line.y is num)
              (line.y as num).toDouble(),
      ];
      return FluentChartMinMax(
        startValue: d3.min<double>(values) ?? double.nan,
        endValue: d3.max<double>(values) ?? double.nan,
      );
    }
    // `findVSBCNumericMinMaxOfY` reads `y` alone (`utilities.ts:1620-1625`),
    // and [FluentChartXYPoint] rejects a [DateTime] x (`types/DataPoint.ts:64`)
    // which [dataset] may carry, so the stack's own index stands in for it.
    return findVSBCNumericMinMaxOfY(<Object>[
      for (final (index, stack) in stacks.indexed)
        FluentChartXYPoint(x: index, y: _stackTotal(stack)),
    ]);
  }

  @override
  FluentAxisSpec createYAxis(
    FluentYAxisParams params,
    FluentAxisData axisData, {
    required bool isRtl,
    required bool isIntegralDataset,
    bool useSecondaryYScale = false,
  }) => builders.createNumericYAxis(
    params,
    axisData,
    isRtl: isRtl,
    isIntegralDataset: isIntegralDataset,
    chartType: FluentChartType.verticalStackedBarChart,
    useSecondaryYScale: useSecondaryYScale,
  );

  @override
  FluentAxisSpec createStringYAxis(
    FluentYAxisParams params,
    List<String> dataPoints,
    FluentAxisData axisData, {
    required bool isRtl,
  }) =>
      // The VSBC arm of `createStringYAxis` forces `paddingInner(1)` and
      // `paddingOuter(0)`, collapsing the bandwidth to zero
      // (`utilities.ts:973-975`).
      builders.createStringYAxis(
        params,
        dataPoints,
        axisData,
        isRtl: isRtl,
        chartType: FluentChartType.verticalStackedBarChart,
      );

  @override
  void paintSeries(
    Canvas canvas,
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
    FluentChartColors colors,
  ) {
    for (final segment in segmentsFor(context, layout)) {
      final paint = Paint()
        ..color = segment.colour.withValues(
          alpha: segment.colour.a * segment.opacity,
        );
      final path = segment.roundedTopPath;
      if (path != null) {
        canvas.drawPath(path, paint);
        continue;
      }
      // `rx = props.roundCorners ? 3 : 0` (`VerticalStackedBarChart.tsx:1102`).
      final radius = roundCorners
          ? style.barCornerRadius!.resolve(const <WidgetState>{})!
          : 0.0;
      if (radius > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(segment.rect, Radius.circular(radius)),
          paint,
        );
      } else {
        canvas.drawRect(segment.rect, paint);
      }
    }
  }

  /// No regions yet.
  ///
  /// A [FluentChartHitRegion] carries a `FluentChartPopoverData`, which this
  /// chart composes out of its callout props — so the widget declares them.
  @override
  List<FluentChartHitRegion> buildHitRegions(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) => const <FluentChartHitRegion>[];
}
