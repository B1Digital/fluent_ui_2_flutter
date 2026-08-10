import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'axis/axis_builders.dart' as builders;
import 'axis/axis_types.dart';
import 'axis/domain_range.dart';
import 'axis/tick_format.dart';
import 'cartesian/cartesian_chart.dart';
import 'cartesian/cartesian_chart_props.dart';
import 'cartesian/cartesian_layout.dart';
import 'cartesian/cartesian_series_delegate.dart';
import 'chrome/chart_popover.dart';
import 'chrome/legend.dart';
import 'grouped_vertical_bar_chart_style.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/chart_text_styles.dart';
import 'internal/chart_utils.dart';
import 'internal/d3/scale.dart' as d3;
import 'internal/d3/scale_band.dart' as d3;
import 'internal/data_viz_palette.dart';
import 'model/bar_data.dart';
import 'model/callout_data.dart';
import 'model/chart_common.dart';
import 'model/chart_value.dart';
import 'model/series_v2.dart';

/// The placement of one category's bar group.
@immutable
class FluentGroupedBarGroupLayout {
  /// Creates a group layout.
  const FluentGroupedBarGroupLayout({
    required this.category,
    required this.translateX,
    required this.effectiveGroupWidth,
    required this.barXByLegend,
  });

  /// The category this group belongs to.
  final String category;

  /// Absolute x the group's local coordinate space starts at.
  final double translateX;

  /// Width the group actually occupies, which shrinks when a legend is absent
  /// from this category (`GroupedVerticalBarChart.tsx:538`).
  final double effectiveGroupWidth;

  /// Bar x offsets relative to [translateX], keyed by legend title.
  final Map<String, double> barXByLegend;
}

/// Pure layout maths for the grouped vertical bar chart.
///
/// Upstream builds **three** band scales: `xScale0` over the categories,
/// `xScale1` over every legend, and a per-group `localScale` over just the
/// legends present in that category. `xScale1` is computed at `.tsx:476` and
/// handed to `_buildGraph`, which never reads it — that scale is dead and is
/// not ported.
abstract final class FluentGroupedVerticalBarChartGeometry {
  /// Inner padding of the per-group bar scale (`X1_INNER_PADDING`, `.tsx:58`).
  static const double kX1InnerPadding = 0.1;

  /// Gap between stacked bars inside one legend column (`VERTICAL_BAR_GAP`,
  /// `.tsx:59`).
  static const double kVerticalBarGap = 1;

  /// Height floor for a bar (`MIN_BAR_HEIGHT`, `.tsx:60`).
  static const double kMinBarHeight = 1;

  /// The default category-scale inner padding.
  ///
  /// `2 / (2 + calcTotalBandUnits(numLegends, 0.1))` (`.tsx:132-136`) — the
  /// comment at `.tsx:129-131` derives it from
  /// `space_between_groups = 2 * bar_width`, so both 2s are that comment's, and
  /// the docs' claim of a flat 2/3 is wrong.
  static double defaultInnerPadding(int legendCount) =>
      2 / (2 + calcTotalBandUnits(legendCount, kX1InnerPadding));

  /// Places one category's group.
  static FluentGroupedBarGroupLayout layOutGroup({
    required String category,
    required List<String> presentLegends,
    required d3.Scale xScale0,
    required double barWidth,
    required bool isRtl,
  }) {
    // GroupedVerticalBarChart.tsx:538.
    final effectiveGroupWidth = calcRequiredWidth(
      barWidth,
      presentLegends.length,
      kX1InnerPadding,
    );
    // GroupedVerticalBarChart.tsx:542-545. The rtl arm reverses the range
    // rather than the domain, so the first legend takes the trailing slot.
    final localScale = d3.scaleBand()
      ..domainOf(presentLegends)
      ..rangeOf(
        isRtl
            ? <double>[effectiveGroupWidth, 0]
            : <double>[0, effectiveGroupWidth],
      )
      ..paddingInner(kX1InnerPadding);
    return FluentGroupedBarGroupLayout(
      category: category,
      // `translate(xScale0(x) + (bandwidth - effectiveGroupWidth) / 2)`
      // (`.tsx:649`); the 2 halves the leftover band width across both sides.
      translateX:
          xScale0(category)! + (xScale0.bandwidth - effectiveGroupWidth) / 2,
      effectiveGroupWidth: effectiveGroupWidth,
      barXByLegend: <String, double>{
        for (final legend in presentLegends)
          // GroupedVerticalBarChart.tsx:551 — the 2 centres the bar in its own
          // slot, which is a no-op while the slot is exactly [barWidth] wide.
          legend:
              (localScale(legend) ?? 0) + (localScale.bandwidth - barWidth) / 2,
      },
    );
  }

  /// Ports `_getDomainMargins` (`GroupedVerticalBarChart.tsx:731-778`).
  ///
  /// Numeric and date x axes fall straight through at [kMinDomainMargin],
  /// because the whole body is inside the `XAxisTypes.StringAxis` guard at
  /// `.tsx:735` and GVBC effectively only supports a category x axis.
  static ({double barWidth, double domainMargin}) solveDomainMargin({
    required int categoryCount,
    required int legendCount,
    required double containerWidth,
    required FluentChartMargins margins,
    required Object? barWidthProp,
    required double? maxBarWidth,
    required double innerPadding,
    required bool isOuterPaddingDefined,
    required String? mode,
    required bool hideTickOverlap,
    required double longestLabelWidth,
  }) {
    var domainMargin = kMinDomainMargin;
    // GroupedVerticalBarChart.tsx:743.
    var barWidth = getBarWidth(barWidthProp, maxBarWidth);
    // GroupedVerticalBarChart.tsx:733.
    final totalWidth = calcTotalWidth(
      containerWidth,
      margins,
      kMinDomainMargin,
    );

    if (isOuterPaddingDefined) {
      // GroupedVerticalBarChart.tsx:736-739.
      domainMargin = 0;
    } else if (barWidthProp != 'auto') {
      // GroupedVerticalBarChart.tsx:744-746.
      final groupWidth = calcRequiredWidth(
        barWidth,
        legendCount,
        kX1InnerPadding,
      );
      final requiredWidth = calcRequiredWidth(
        groupWidth,
        categoryCount,
        innerPadding,
      );
      if (totalWidth >= requiredWidth) {
        // GroupedVerticalBarChart.tsx:750 — the 2 splits the slack evenly
        // across the two sides.
        domainMargin = kMinDomainMargin + (totalWidth - requiredWidth) / 2;
      }
      // GroupedVerticalBarChart.tsx:752 — the 1 is upstream's own guard
      // against a single-category plotly chart.
    } else if (mode == 'plotly' && categoryCount > 1) {
      // GroupedVerticalBarChart.tsx:754-757.
      final groupBandwidth = calcBandwidth(
        totalWidth,
        categoryCount,
        innerPadding,
      );
      final barBandwidth = calcBandwidth(
        groupBandwidth,
        legendCount,
        kX1InnerPadding,
      );
      barWidth = getBarWidth(
        barWidthProp,
        maxBarWidth,
        adjustedValue: barBandwidth,
      );
      final groupWidth = calcRequiredWidth(
        barWidth,
        legendCount,
        kX1InnerPadding,
      );
      // GroupedVerticalBarChart.tsx:758-759; the 2 is the same even split.
      final margin1 =
          (totalWidth -
              calcRequiredWidth(groupWidth, categoryCount, innerPadding)) /
          2;
      // `margin2` stays +infinity when hideTickOverlap is set
      // (`.tsx:761-767`), so the label term drops out of the `min` below. The
      // 20 is upstream's own inter-label gap at `.tsx:764`.
      final margin2 = hideTickOverlap
          ? double.infinity
          : (totalWidth -
                    (categoryCount - innerPadding) * (longestLabelWidth + 20)) /
                2;
      // GroupedVerticalBarChart.tsx:769 — the 0 floors a negative solve.
      domainMargin =
          kMinDomainMargin + math.max(0.0, math.min(margin1, margin2));
    }
    return (barWidth: barWidth, domainMargin: domainMargin);
  }
}

/// One resolved bar of a grouped vertical bar chart.
///
/// `pointIndex` is the bar's position inside its `(category, legend)` column,
/// counting the zero-valued points `barsFor` drops, so it indexes the series
/// the bar came from.
typedef FluentGroupedBarRect = ({
  Rect rect,
  Color colour,
  double opacity,
  String legend,
  String category,
  int pointIndex,
});

/// One resolved dot of a line series overlaid on the bars.
///
/// `dotId` is upstream's `_getDotId(seriesIdx, pointIdx)`
/// (`GroupedVerticalBarChart.tsx:987`) minus its per-instance prefix, which
/// only exists there to keep two charts' DOM ids apart.
typedef FluentGroupedLineDot = ({
  int seriesIndex,
  int pointIndex,
  Offset centre,
  String dotId,
  String category,
  String legend,
});

/// Every dot of [lineSeries], in series then point order.
///
/// Ports the `scaleLineX` walk at `GroupedVerticalBarChart.tsx:807-820`: a dot
/// sits on the **centre of the category band**, not over any one bar. Shared by
/// the painter, the hit regions and the widget's pointer handler, so the
/// enlarged dot and the popover can never disagree about where a dot is.
List<FluentGroupedLineDot> fluentGroupedLineDots(
  List<FluentLineSeries> lineSeries,
  FluentCartesianChildContext context,
) {
  final dots = <FluentGroupedLineDot>[];
  for (var s = 0; s < lineSeries.length; s++) {
    final series = lineSeries[s];
    // `.tsx:816` reads the flag off the series, not off a point.
    final yScale = series.useSecondaryYScale && context.yScaleSecondary != null
        ? context.yScaleSecondary!
        : context.yScalePrimary;
    for (var p = 0; p < series.data.length; p++) {
      final point = series.data[p];
      final category = '${point.x}';
      final x = context.xScale(category);
      final y = point.y is num ? yScale((point.y as num).toDouble()) : null;
      if (x == null || y == null) {
        continue;
      }
      dots.add((
        seriesIndex: s,
        pointIndex: p,
        centre: Offset(x + context.xScale.bandwidth / 2, y),
        dotId: '$s-$p',
        category: category,
        legend: series.legend,
      ));
    }
  }
  return dots;
}

/// Renders grouped, optionally stacked, vertical bars into the cartesian shell.
///
/// Ports `GroupedVerticalBarChart.tsx` (1034 lines). Unlike VerticalBarChart
/// and VerticalStackedBarChart, GVBC uses the shell's **position** y scale
/// directly (`.tsx:556`) rather than building its own magnitude scale.
class FluentGroupedVerticalBarChartDelegate
    extends FluentCartesianSeriesDelegate {
  /// Creates a delegate.
  const FluentGroupedVerticalBarChartDelegate({
    required this.data,
    this.lineSeries = const <FluentLineSeries>[],
    required this.style,
    required this.colors,
    required this.measurer,
    required this.textStyles,
    required this.selectedLegends,
    required this.legendColours,
    this.activeLegend,
    this.activeLinePoint,
    this.barWidthProp,
    this.maxBarWidth = 24,
    this.hideLabels = false,
    this.roundCorners = false,
    this.mode,
    double? xAxisInnerPadding,
    double? xAxisOuterPadding,
    this.hideTickOverlap = true,
    this.xAxisCategoryOrder = FluentAxisCategoryOrder.defaultOrder,
    this.yAxisTickFormat,
    this.culture,
    this.isCalloutForStack = false,
    // Both paddings are stored raw and resolved by the overrides below, which
    // is what the shell's band scale reads. A named parameter cannot be a
    // private initialising formal, hence the explicit assignment.
    // ignore: prefer_initializing_formals
  }) : _xAxisInnerPadding = xAxisInnerPadding,
       // ignore: prefer_initializing_formals
       _xAxisOuterPadding = xAxisOuterPadding;

  /// The categories, in author order.
  final List<FluentGroupedVerticalBarChartData> data;

  /// The line series drawn over the bars, in author order
  /// (`GroupedVerticalBarChart.tsx:797-912`).
  final List<FluentLineSeries> lineSeries;

  /// The resolved style.
  final FluentGroupedVerticalBarChartStyle style;

  /// Resolved chart colours.
  final FluentChartColors colors;

  /// The chart subtree's single text measurer.
  final FluentChartTextMeasurer measurer;

  /// Resolved chart text styles.
  final FluentChartTextStyles textStyles;

  /// Legend titles selected by the user.
  final List<String> selectedLegends;

  /// Legend colours resolved once by the widget's colour walk.
  final Map<String, Color> legendColours;

  /// Legend title currently hovered.
  final String? activeLegend;

  /// The x category or dot identifier whose line dot is enlarged.
  final String? activeLinePoint;

  /// `number | 'default' | 'auto'`.
  final Object? barWidthProp;

  /// Bar width ceiling — 24 (`.tsx:80`).
  final double maxBarWidth;

  /// Whether the per-legend total labels are suppressed.
  final bool hideLabels;

  /// Whether bars get a 3px corner radius.
  final bool roundCorners;

  /// `'plotly'` or null.
  final String? mode;

  /// Category-scale outer padding as the caller gave it, before
  /// [xAxisOuterPadding] resolves it. Raw because an explicit 0 and an absent
  /// value make different charts — see [isScalePaddingDefined].
  final double? _xAxisOuterPadding;

  /// The outer padding the **shell's** band scale is built with.
  ///
  /// Resolved, not raw. `.tsx:1013-1016` spreads `_xAxisOuterPadding` into
  /// `CartesianChart`, and `_adjustProps` sets it to
  /// `getScalePadding(props.xAxisOuterPadding)` — 0 by default (`.tsx:137`).
  /// Handing the raw null instead lets `createStringXAxis` fall back to its own
  /// `xAxisPadding = 0.1` (`utilities.ts:576`, ported at
  /// `axis_builders.dart:401`), which makes the band scale disagree with the
  /// domain-margin solve about how much room each group has.
  @override
  double? get xAxisOuterPadding => getScalePadding(_xAxisOuterPadding);

  /// Whether the shell prunes overlapping x ticks — default true.
  final bool hideTickOverlap;

  /// Ordering applied to the category x axis.
  final FluentAxisCategoryOrder xAxisCategoryOrder;

  /// Caller-supplied y tick formatter, reused for total labels.
  final String Function(double value)? yAxisTickFormat;

  /// BCP-47 locale the popover's readings are formatted in.
  ///
  /// Upstream hands `props.culture` to `ChartPopover` (`.tsx:445`), which
  /// formats there (`ChartPopover.tsx:80`); the frozen popover contract types
  /// its readings as strings, so the call moves here.
  @override
  final String? culture;

  /// Whether a hovered mark reports its whole category rather than itself
  /// (`.tsx:447`, `:984`).
  final bool isCalloutForStack;

  final double? _xAxisInnerPadding;

  @override
  FluentChartType get chartType => FluentChartType.groupedVerticalBarChart;

  @override
  FluentChartAxisType get xAxisType => FluentChartAxisType.category;

  @override
  FluentChartAxisType get yAxisType => FluentChartAxisType.numeric;

  /// The category-scale inner padding, defaulted the way `_createX0Scale`
  /// defaults it (`GroupedVerticalBarChart.tsx:132-136`).
  ///
  /// The caller's prop is resolved here rather than in the widget because the
  /// fallback depends on [barLegends], which only this delegate knows.
  @override
  double? get xAxisInnerPadding => getScalePadding(
    _xAxisInnerPadding,
    null,
    FluentGroupedVerticalBarChartGeometry.defaultInnerPadding(
      barLegends.length,
    ),
  );

  /// Every bar legend, in first-appearance order across every category.
  List<String> get barLegends => <String>{
    for (final category in data)
      for (final point in category.series) point.legend,
  }.toList(growable: false);

  /// The resolved colour of [legend].
  Color legendColour(String legend) =>
      legendColours[legend] ?? FluentDataVizPalette.next(0);

  /// Ports the label gate at `GroupedVerticalBarChart.tsx:620`.
  ///
  /// parity: this uses `ceil(_barWidth) >= 16` where VerticalBarChart uses
  /// `_barWidth < 16`, so a 15.2px bar is labelled here and not there.
  bool shouldPaintTotalLabel(double barWidth) =>
      !hideLabels &&
      barWidth.ceilToDouble() >=
          style.minBarLabelWidth!.resolve(const <WidgetState>{})!;

  @override
  List<String>? get datasetForXAxisDomain {
    if (xAxisCategoryOrder != FluentAxisCategoryOrder.defaultOrder) {
      return sortAxisCategories(<String, List<double>>{
        for (final category in data)
          category.name: <double>[
            for (final point in category.series) point.data,
          ],
      }, xAxisCategoryOrder);
    }
    return <String>[for (final category in data) category.name];
  }

  @override
  FluentChartDomainRange resolveXDomainRange({
    required FluentChartMargins margins,
    required double containerWidth,
    required bool isRtl,
    required double? barWidth,
    required List<Object>? tickValues,
  }) => domainRangeOfXStringAxis(margins, containerWidth, isRtl: isRtl);

  @override
  FluentChartMinMax resolveYMinMax({bool useSecondaryYScale = false}) {
    // `_getMinMaxOfYAxis` splits primary from secondary by useSecondaryYScale
    // (`GroupedVerticalBarChart.tsx:397-409`).
    var lo = 0.0;
    var hi = 0.0;
    for (final category in data) {
      for (final point in category.series) {
        if (point.useSecondaryYScale != useSecondaryYScale) {
          continue;
        }
        lo = math.min(lo, point.data);
        hi = math.max(hi, point.data);
      }
    }
    // `groupSeries` folds every line point in beside the bars (`.tsx:178-181`)
    // and `_getMinMaxOfYAxis` walks that array, so a line that overshoots the
    // tallest bar still lands inside the plot.
    for (final series in lineSeries) {
      if (series.useSecondaryYScale != useSecondaryYScale) {
        continue;
      }
      for (final point in series.data) {
        if (point.y is! num) {
          continue;
        }
        final value = (point.y as num).toDouble();
        lo = math.min(lo, value);
        hi = math.max(hi, value);
      }
    }
    return FluentChartMinMax(startValue: lo, endValue: hi);
  }

  @override
  double? get maxOfYVal => resolveYMinMax().endValue;

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
    chartType: FluentChartType.groupedVerticalBarChart,
    useSecondaryYScale: useSecondaryYScale,
  );

  @override
  FluentAxisSpec createStringYAxis(
    FluentYAxisParams params,
    List<String> dataPoints,
    FluentAxisData axisData, {
    required bool isRtl,
  }) => builders.createStringYAxis(
    params,
    dataPoints,
    axisData,
    isRtl: isRtl,
    chartType: FluentChartType.groupedVerticalBarChart,
  );

  @override
  FluentChartMargins? domainMargins(
    double containerWidth,
    FluentChartMargins margins,
  ) {
    final categories = datasetForXAxisDomain ?? const <String>[];
    final margin = FluentGroupedVerticalBarChartGeometry.solveDomainMargin(
      categoryCount: categories.length,
      legendCount: barLegends.length,
      containerWidth: containerWidth,
      margins: margins,
      barWidthProp: barWidthProp,
      maxBarWidth: maxBarWidth,
      innerPadding: xAxisInnerPadding!,
      // `GroupedVerticalBarChart.tsx:736`, one of upstream's four
      // `isScalePaddingDefined` sites. Note the single argument: GVBC passes no
      // shorthand, unlike VerticalBarChart.tsx:993.
      // Reads the RAW padding: the resolved [xAxisOuterPadding] is 0 whether
      // the caller named 0 or named nothing, and telling those apart is the
      // whole point of the helper.
      isOuterPaddingDefined: isScalePaddingDefined(_xAxisOuterPadding),
      mode: mode,
      hideTickOverlap: hideTickOverlap,
      // `calculateLongestLabelWidth(_xAxisLabels)` (`.tsx:764`) sits inside the
      // `!props.hideTickOverlap` guard at `:763`, so the measure is skipped
      // rather than paid on every solve when overlap hiding is on.
      longestLabelWidth: hideTickOverlap
          ? 0
          : measurer.longestWidth(categories, textStyles.axisTick),
    ).domainMargin;
    // `{..._margins, left: …, right: …}` (`.tsx:773-777`) — top and bottom
    // pass through untouched.
    return margins.copyWith(
      left: (margins.left ?? 0) + margin,
      right: (margins.right ?? 0) + margin,
    );
  }

  /// The bar width every group is laid out on
  /// (`GroupedVerticalBarChart.tsx:468-471`).
  double barWidthFor(d3.Scale xScale0) => getBarWidth(
    barWidthProp,
    maxBarWidth,
    adjustedValue: calcBandwidth(
      xScale0.bandwidth,
      barLegends.length,
      FluentGroupedVerticalBarChartGeometry.kX1InnerPadding,
    ),
  );

  /// Resolves every bar.
  ///
  /// Ports `_buildGraph` (`GroupedVerticalBarChart.tsx:520-618`). [layout] is
  /// read for its direction alone; every coordinate comes off the two scales.
  List<FluentGroupedBarRect> barsFor(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) {
    final legends = barLegends;
    final barWidth = barWidthFor(context.xScale);
    final dim = style.barOpacity!.resolve(<WidgetState>{WidgetState.disabled})!;
    final out = <FluentGroupedBarRect>[];

    for (final category in data) {
      final byLegend = <String, List<FluentGroupedBarSeriesPoint>>{};
      for (final point in category.series) {
        (byLegend[point.legend] ??= <FluentGroupedBarSeriesPoint>[]).add(point);
      }
      // `.tsx:536` — the legends this category actually carries, in the global
      // legend order.
      final present = legends
          .where(byLegend.containsKey)
          .toList(growable: false);
      if (present.isEmpty) {
        continue;
      }
      final group = FluentGroupedVerticalBarChartGeometry.layOutGroup(
        category: category.name,
        presentLegends: present,
        xScale0: context.xScale,
        barWidth: barWidth,
        isRtl: layout.isRtl,
      );
      for (final legend in present) {
        final column = byLegend[legend]!;
        // `.tsx:548` reads the flag off the column's first point only.
        final yScale =
            column.first.useSecondaryYScale && context.yScaleSecondary != null
            ? context.yScaleSecondary!
            : context.yScalePrimary;
        final baseline = yScale(0)!;
        var positiveStart = baseline;
        var negativeStart = baseline;
        final x = group.translateX + group.barXByLegend[legend]!;
        final highlighted = _isLegendActive(legend);
        for (var k = 0; k < column.length; k++) {
          final value = column[k].data;
          // parity: `if (!pointData.data)` (`.tsx:562`) — JS falsiness drops 0.
          if (value == 0 || value.isNaN) {
            continue;
          }
          final gap = k > 0
              ? FluentGroupedVerticalBarChartGeometry.kVerticalBarGap
              : 0.0;
          final height = math.max(
            baseline - yScale(value.abs())!,
            FluentGroupedVerticalBarChartGeometry.kMinBarHeight,
          );
          final double top;
          if (value >= 0) {
            positiveStart -= height + gap;
            top = positiveStart;
          } else {
            top = negativeStart + gap;
            negativeStart = top + height;
          }
          out.add((
            rect: Rect.fromLTWH(x, top, barWidth, height),
            colour: colors.flattenMark(column[k].color ?? legendColour(legend)),
            opacity: highlighted ? 1 : dim,
            legend: legend,
            category: category.name,
            pointIndex: k,
          ));
        }
      }
    }
    return out;
  }

  @override
  void paintSeries(
    Canvas canvas,
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
    FluentChartColors colors,
  ) {
    final bars = barsFor(context, layout);
    // `.tsx:588` — rx 3 when the prop is on, 0 when it is off.
    final radius = roundCorners
        ? style.barCornerRadius!.resolve(const <WidgetState>{})!
        : 0.0;
    for (final bar in bars) {
      final paint = Paint()
        ..color = bar.colour.withValues(alpha: bar.colour.a * bar.opacity);
      if (radius == 0) {
        canvas.drawRect(bar.rect, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(bar.rect, Radius.circular(radius)),
          paint,
        );
      }
    }
    _paintLabels(canvas, bars);
    _paintLines(canvas, context);
  }

  /// The line overlay (`_createLines`, `GroupedVerticalBarChart.tsx:797-912`).
  ///
  /// Three passes in upstream's own order — every halo, then every line, then
  /// every dot (`.tsx:909-911`) — so one series' line can never cross over
  /// another's dot.
  void _paintLines(Canvas canvas, FluentCartesianChildContext context) {
    if (lineSeries.isEmpty) {
      return;
    }
    final dots = fluentGroupedLineDots(lineSeries, context);
    final dim = style.barOpacity!.resolve(<WidgetState>{WidgetState.disabled})!;
    final full = style.barOpacity!.resolve(const <WidgetState>{})!;
    final strokeWidth = style.lineStrokeWidth!.resolve(const <WidgetState>{})!;
    final perSeries = <List<FluentGroupedLineDot>>[
      for (var s = 0; s < lineSeries.length; s++)
        dots.where((dot) => dot.seriesIndex == s).toList(growable: false),
    ];

    void strokeSegments(int s, Paint paint) {
      final points = perSeries[s];
      for (var i = 1; i < points.length; i++) {
        canvas.drawLine(points[i - 1].centre, points[i].centre, paint);
      }
    }

    for (var s = 0; s < lineSeries.length; s++) {
      final series = lineSeries[s];
      final border = series.lineOptions?.lineBorderWidth ?? 0;
      // `.tsx:827` gates the halo on a positive border width.
      if (border <= 0) {
        continue;
      }
      strokeSegments(
        s,
        Paint()
          ..style = PaintingStyle.stroke
          // The halo is what keeps the line off the marks under it, so its
          // stroke flattens to the canvas colour rather than to the system
          // foreground (design spec section 5.3).
          ..color = colors
              .flattenMarkStroke(
                series.lineOptions?.lineBorderColor ??
                    style.lineBorderColor!.resolve(const <WidgetState>{})!,
              )
              .withValues(alpha: _isLegendActive(series.legend) ? full : dim)
          // `3 + lineBorderWidth * 2` (`.tsx:837`): the 3 is a literal
          // upstream, not `lineOptions.strokeWidth`.
          ..strokeWidth = strokeWidth + border * 2
          // `strokeLinecap="round"` (`.tsx:838`).
          ..strokeCap = StrokeCap.round,
      );
    }

    for (var s = 0; s < lineSeries.length; s++) {
      final series = lineSeries[s];
      strokeSegments(
        s,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = colors
              .flattenMark(series.color ?? legendColour(series.legend))
              .withValues(alpha: _isLegendActive(series.legend) ? full : dim)
          // `.tsx:852-853`.
          ..strokeWidth = series.lineOptions?.strokeWidth ?? strokeWidth
          ..strokeCap = series.lineOptions?.strokeLinecap ?? StrokeCap.round,
      );
      // ponytail: `strokeDasharray` (`.tsx:854`) is dropped. Dashing a
      // three-segment polyline needs the same path-metrics walk LineChart
      // carries for its own dashes; lift that helper here if a caller asks.
    }

    final dotFill = style.lineDotFillColor!.resolve(const <WidgetState>{})!;
    final dotStroke = style.lineDotStrokeWidth!.resolve(const <WidgetState>{})!;
    for (final dot in dots) {
      final series = lineSeries[dot.seriesIndex];
      final highlighted = _isLegendActive(series.legend);
      final opacity = highlighted ? full : dim;
      final radius = style.lineDotRadius!.resolve(
        highlighted && isLinePointActive(dot)
            ? <WidgetState>{WidgetState.selected}
            : const <WidgetState>{},
      )!;
      canvas
        ..drawCircle(dot.centre, radius, Paint()..color = dotFill)
        ..drawCircle(
          dot.centre,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            // The ring is the marker's halo — it is what separates the dot
            // from the line beneath it — so it takes the stroke flattening.
            ..color = colors
                .flattenMarkStroke(series.color ?? legendColour(series.legend))
                .withValues(alpha: opacity)
            ..strokeWidth = dotStroke,
        );
    }
  }

  /// Whether [dot] is the enlarged one.
  ///
  /// `activeLinePoint === point.x || activeLinePoint === dotId`
  /// (`GroupedVerticalBarChart.tsx:863`): the category arm is what
  /// `isCalloutForStack` sets (`:984`), so a stack callout grows the dot of
  /// every line at that category.
  bool isLinePointActive(FluentGroupedLineDot dot) =>
      activeLinePoint != null &&
      (activeLinePoint == dot.category || activeLinePoint == dot.dotId);

  /// The square a line dot is hovered and focused through.
  ///
  /// Upstream's target is the dot itself, whose idle radius is 0.3
  /// (`.tsx:870`); a 0.6px hover target is not reachable with a pointer, so the
  /// region is the **active** dot's 8px radius, which is the size the dot takes
  /// the moment it is hit.
  Rect lineDotBounds(FluentGroupedLineDot dot) {
    final radius = style.lineDotRadius!.resolve(<WidgetState>{
      WidgetState.selected,
    })!;
    return Rect.fromCircle(center: dot.centre, radius: radius);
  }

  @override
  List<FluentChartHitRegion> buildHitRegions(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) {
    final regions = <FluentChartHitRegion>[];
    for (final bar in barsFor(context, layout)) {
      final point = _pointFor(bar);
      // `.tsx:596` gives a bar dimmed by another legend no tab index at all,
      // so it is not an interactive area.
      if (!_isLegendActive(bar.legend)) {
        continue;
      }
      // `getAriaLabel` (`.tsx:724-729`) and `_getCalloutContent` read the same
      // two overrides.
      final xValue = point.xAxisCalloutData ?? bar.category;
      final yValue = point.yAxisCalloutData ?? formatY(point.data);
      regions.add(
        FluentChartHitRegion(
          bounds: bar.rect,
          // The category, so a stack callout merges one group into one target
          // (`.tsx:447` sets `isCalloutForStack` on the popover, and the shell
          // coalesces on this index).
          index: _categoryIndex(bar.category),
          legend: bar.legend,
          popoverData: FluentChartPopoverData(
            xValue: xValue,
            yValue: yValue,
            legend: bar.legend,
            color: bar.colour,
            isCalloutForStack: isCalloutForStack,
            yValues: isCalloutForStack ? _yValuesOf(bar.category) : null,
          ),
          semanticsLabel:
              point.callOutSemantics?.label ??
              '$xValue. ${bar.legend}, $yValue.',
        ),
      );
    }
    // The dots come last, so the shell's backwards walk finds one over a bar —
    // which is the hit order the SVG gives them too (`.tsx:909-911`).
    for (final dot in fluentGroupedLineDots(lineSeries, context)) {
      final series = lineSeries[dot.seriesIndex];
      // `tabIndex={shouldHighlight ? 0 : undefined}` (`.tsx:877`).
      if (!_isLegendActive(series.legend)) {
        continue;
      }
      final point = series.data[dot.pointIndex];
      final xValue = point.xAxisCalloutData ?? dot.category;
      final yValue =
          point.yAxisCalloutData ??
          (point.y is num
              ? formatY((point.y as num).toDouble())
              : '${point.y}');
      regions.add(
        FluentChartHitRegion(
          bounds: lineDotBounds(dot),
          index: _categoryIndex(dot.category),
          legend: series.legend,
          popoverData: FluentChartPopoverData(
            xValue: xValue,
            yValue: yValue,
            legend: series.legend,
            color: colors.flattenMark(
              series.color ?? legendColour(series.legend),
            ),
            isCalloutForStack: isCalloutForStack,
            yValues: isCalloutForStack ? _yValuesOf(dot.category) : null,
          ),
          // `getAriaLabel` again, called on the line point at `.tsx:881-891`.
          semanticsLabel:
              point.callOutSemantics?.label ??
              '$xValue. ${series.legend}, $yValue.',
        ),
      );
    }
    return regions;
  }

  /// The position of [category] in [data], or the count when a line names a
  /// category no bar carries.
  int _categoryIndex(String category) {
    final index = data.indexWhere((candidate) => candidate.name == category);
    return index < 0 ? data.length : index;
  }

  /// The stack-wide readings of [category], filtered the way
  /// `setYValueHover` filters them (`GroupedVerticalBarChart.tsx:980-982`).
  List<FluentYValueHover> _yValuesOf(String category) => <FluentYValueHover>[
    for (final group in data)
      if (group.name == category)
        for (final point in group.series)
          if (_isLegendActive(point.legend))
            FluentYValueHover(
              legend: point.legend,
              y: point.data,
              color: colors.flattenMark(
                point.color ?? legendColour(point.legend),
              ),
              yAxisCalloutText: point.yAxisCalloutData,
            ),
  ];

  /// A popover reading, in [culture] when the caller named one.
  ///
  /// `formatToLocaleString` is what `ChartPopover.tsx:80` calls; the scientific
  /// fallback is the chart's own default when there is no locale to format in.
  String formatY(double value) => culture == null
      ? formatScientificLimitWidth(value)
      : formatToLocaleString(value, culture: culture);

  /// `_legendHighlighted(legend) || _noLegendHighlighted()`
  /// (`GroupedVerticalBarChart.tsx:552`).
  bool _isLegendActive(String legend) {
    final noneHighlighted =
        selectedLegends.isEmpty &&
        (activeLegend == null || activeLegend!.isEmpty);
    return noneHighlighted ||
        isLegendHighlightedMulti(
          legend,
          selectedLegends: selectedLegends,
          activeLegend: activeLegend,
        );
  }

  /// The point [bar] was resolved from.
  FluentGroupedBarSeriesPoint _pointFor(FluentGroupedBarRect bar) => data
      .firstWhere((category) => category.name == bar.category)
      .series
      .where((point) => point.legend == bar.legend)
      .elementAt(bar.pointIndex);

  /// The per-point labels (`.tsx:601-615`) and the per-column total labels
  /// (`.tsx:620-637`).
  void _paintLabels(Canvas canvas, List<FluentGroupedBarRect> bars) {
    final labelStyle =
        style.barLabelStyle!.resolve(const <WidgetState>{}) ??
        textStyles.barLabel;
    final gapAbove = style.barLabelGapAbove!.resolve(const <WidgetState>{})!;
    final gapBelow = style.barLabelGapBelow!.resolve(const <WidgetState>{})!;
    // Keyed by column: the running total, the top of its highest bar and the
    // bottom of its lowest, which are upstream's yPositiveStart and
    // yNegativeStart once the column has been walked.
    final columns =
        <(String, String), (double total, double top, double bottom)>{};

    for (final bar in bars) {
      if (!_isLegendActive(bar.legend)) {
        continue;
      }
      final point = _pointFor(bar);
      if (point.barLabel != null) {
        _paintLabel(
          canvas,
          point.barLabel!,
          labelStyle,
          bar.rect.center.dx,
          // `.tsx:607`.
          point.data >= 0
              ? bar.rect.top - gapAbove
              : bar.rect.bottom + gapBelow,
        );
      }
      final key = (bar.category, bar.legend);
      final running = columns[key];
      columns[key] = running == null
          ? (point.data, bar.rect.top, bar.rect.bottom)
          : (
              running.$1 + point.data,
              math.min(running.$2, bar.rect.top),
              math.max(running.$3, bar.rect.bottom),
            );
    }

    if (bars.isEmpty || !shouldPaintTotalLabel(bars.first.rect.width)) {
      return;
    }
    for (final column in columns.entries) {
      final total = column.value.$1;
      _paintLabel(
        canvas,
        yAxisTickFormat?.call(total) ?? formatScientificLimitWidth(total),
        labelStyle,
        // Every bar of a column shares an x, so the first one's centre is the
        // column's centre.
        bars
            .firstWhere(
              (bar) =>
                  bar.category == column.key.$1 && bar.legend == column.key.$2,
            )
            .rect
            .center
            .dx,
        // `.tsx:625` — the sign of the *total*, not of the last bar.
        total >= 0 ? column.value.$2 - gapAbove : column.value.$3 + gapBelow,
      );
    }
  }

  /// Paints [text] centred on [centreX] with its alphabetic baseline on
  /// [baselineY], which is what `<text text-anchor="middle" y=…>` does.
  void _paintLabel(
    Canvas canvas,
    String text,
    TextStyle style,
    double centreX,
    double baselineY,
  ) {
    final metrics = measurer.measure(text, style);
    final painter = measurer.layoutPainter(text, style);
    painter.paint(
      canvas,
      Offset(centreX - metrics.width / 2, baselineY - metrics.ascent),
    );
    painter.dispose();
  }
}

/// A Fluent 2 grouped vertical bar chart, optionally overlaid with lines.
///
/// Ports `GroupedVerticalBarChart.tsx`. Repeated `(category, legend)` pairs
/// stack inside one legend column, which is why the chart supports
/// stacked-within-grouped bars.
class FluentGroupedVerticalBarChart extends StatefulWidget {
  /// Creates a grouped bar chart.
  const FluentGroupedVerticalBarChart({
    super.key,
    this.data = const <FluentGroupedVerticalBarChartData>[],
    this.dataV2,
    this.props = const FluentCartesianChartProps(),
    this.barWidth,
    this.maxBarWidth = 24,
    this.chartTitle,
    this.culture,
    this.isCalloutForStack = false,
    this.hideLabels = false,
    this.roundCorners = false,
    this.mode,
    this.xAxisInnerPadding,
    this.xAxisOuterPadding,
    this.xAxisCategoryOrder = FluentAxisCategoryOrder.defaultOrder,
    this.style,
    this.legendSelectionMode = FluentChartLegendSelectionMode.single,
    this.focusNode,
  });

  /// The categories, in author order.
  final List<FluentGroupedVerticalBarChartData> data;

  /// The v2 input. When non-empty it **replaces** [data] entirely
  /// (`GroupedVerticalBarChart.tsx:296-304`) and is the only way to supply
  /// line series.
  final List<FluentDataSeries>? dataV2;

  /// Shell configuration.
  final FluentCartesianChartProps props;

  /// `number | 'default' | 'auto'`.
  final Object? barWidth;

  /// Bar width ceiling — 24.
  final double maxBarWidth;

  /// Human title, folded into the accessible description.
  final String? chartTitle;

  /// BCP-47 locale for popover formatting.
  final String? culture;

  /// Whether the popover lists every legend in the hovered category.
  final bool isCalloutForStack;

  /// Whether the per-legend total labels are suppressed.
  final bool hideLabels;

  /// Whether bars get a 3px corner radius.
  final bool roundCorners;

  /// `'plotly'` or null.
  final String? mode;

  /// Category-scale inner padding override.
  final double? xAxisInnerPadding;

  /// Category-scale outer padding override.
  final double? xAxisOuterPadding;

  /// Ordering applied to the category x axis.
  final FluentAxisCategoryOrder xAxisCategoryOrder;

  /// Style override, highest precedence.
  final FluentGroupedVerticalBarChartStyle? style;

  /// Whether the legend allows more than one selection.
  final FluentChartLegendSelectionMode legendSelectionMode;

  /// The chart's single focus node.
  final FocusNode? focusNode;

  @override
  State<FluentGroupedVerticalBarChart> createState() =>
      FluentGroupedVerticalBarChartState();
}

/// State for [FluentGroupedVerticalBarChart].
///
/// Public only so widget tests can reach [nearestLinePointIndex], the same
/// shape `FluentAreaChartState` uses for its hover helpers.
class FluentGroupedVerticalBarChartState
    extends State<FluentGroupedVerticalBarChart> {
  List<String> _selectedLegends = const <String>[];
  String? _activeLegend;
  String? _activeLinePoint;
  final FluentChartTextMeasurer _measurer = FluentChartTextMeasurer();

  List<FluentGroupedVerticalBarChartData> get _categories =>
      widget.dataV2 != null && widget.dataV2!.isNotEmpty
      ? _fromV2(widget.dataV2!)
      : widget.data;

  List<FluentLineSeries> get _lineSeries => <FluentLineSeries>[
    for (final series in widget.dataV2 ?? const <FluentDataSeries>[])
      if (series is FluentLineSeries) series,
  ];

  /// Ports `_processDataV2` (`GroupedVerticalBarChart.tsx:267-295`).
  ///
  /// Bar series lose `gradient`, `opacity`, `legendShape`, `onLegendClick`,
  /// `markerSize`, `text` and `callOutAccessibilityData` on the way through —
  /// deliberately, matching upstream.
  List<FluentGroupedVerticalBarChartData> _fromV2(
    List<FluentDataSeries> input,
  ) {
    final byCategory = <String, List<FluentGroupedBarSeriesPoint>>{};
    for (final series in input) {
      if (series is! FluentBarSeries) {
        continue;
      }
      for (final point in series.data) {
        (byCategory['${point.x}'] ??= <FluentGroupedBarSeriesPoint>[]).add(
          FluentGroupedBarSeriesPoint(
            key: series.key ?? series.legend,
            data: point.y is num ? (point.y as num).toDouble() : 0,
            legend: series.legend,
            // `point.color ?? series.color` (`.tsx:281`).
            color: point.color ?? series.color,
            xAxisCalloutData: point.xAxisCalloutData,
            yAxisCalloutData: point.yAxisCalloutData,
            onClick: point.onClick,
            useSecondaryYScale: series.useSecondaryYScale,
          ),
        );
      }
    }
    return <FluentGroupedVerticalBarChartData>[
      for (final entry in byCategory.entries)
        FluentGroupedVerticalBarChartData(name: entry.key, series: entry.value),
    ];
  }

  /// The colour walk at `GroupedVerticalBarChart.tsx:298-352`.
  ///
  /// The counter advances for **every point in every category**, then for every
  /// line series — but a legend keeps the colour it was first assigned, so
  /// three legends over four categories still take palette entries 0, 1 and 2.
  Map<String, Color> _legendColours(
    List<FluentGroupedVerticalBarChartData> categories,
  ) {
    final map = <String, Color>{};
    var index = 0;
    for (final category in categories) {
      for (final point in category.series) {
        map.putIfAbsent(
          point.legend,
          () => point.color ?? FluentDataVizPalette.next(index),
        );
        index++;
      }
    }
    for (final series in _lineSeries) {
      map.putIfAbsent(
        series.legend,
        () => series.color ?? FluentDataVizPalette.next(index),
      );
      index++;
    }
    return map;
  }

  /// Ports the nearest-dot search at `GroupedVerticalBarChart.tsx:916-937`.
  ///
  /// The comparison is strict `<`, so an exact midpoint keeps [currentIndex].
  int nearestLinePointIndex(
    List<double> dotXs,
    int currentIndex,
    double pointerX,
  ) {
    if (currentIndex <= 0) {
      return currentIndex;
    }
    return (dotXs[currentIndex - 1] - pointerX).abs() <
            (dotXs[currentIndex] - pointerX).abs()
        ? currentIndex - 1
        : currentIndex;
  }

  /// The style this chart resolves to, read by both [build] and the pointer
  /// handler — which needs the dot geometry the style defines.
  FluentGroupedVerticalBarChartStyle _resolveStyle() =>
      resolveFluentGroupedVerticalBarChartStyle(FluentTheme.of(context))
          .merge(FluentGroupedVerticalBarChartTheme.maybeOf(context))
          .merge(widget.style);

  /// Ports `_onLineHover` (`GroupedVerticalBarChart.tsx:916-933`).
  ///
  /// Upstream's target is the hovered `<line>` or `<circle>`, which fixes the
  /// series and one endpoint before the tie-break runs; here the pointer is
  /// tested against every series' dots, and the tie-break picks the endpoint of
  /// the segment it landed on exactly as upstream does.
  void _handlePointerMove(
    Offset position,
    FluentCartesianChildContext context,
  ) {
    if (_lineSeries.isEmpty) {
      return;
    }
    final dots = fluentGroupedLineDots(_lineSeries, context);
    final radius = _resolveStyle().lineDotRadius!.resolve(<WidgetState>{
      WidgetState.selected,
    })!;
    String? active;
    for (var s = 0; s < _lineSeries.length && active == null; s++) {
      final points = dots
          .where((dot) => dot.seriesIndex == s)
          .toList(growable: false);
      if (points.isEmpty) {
        continue;
      }
      final xs = <double>[for (final dot in points) dot.centre.dx];
      var index = xs.indexWhere((x) => x >= position.dx);
      index = index < 0 ? xs.length - 1 : index;
      final dot = points[nearestLinePointIndex(xs, index, position.dx)];
      if ((dot.centre - position).distance <= radius) {
        active = dot.dotId;
      }
    }
    if (active != _activeLinePoint) {
      setState(() => _activeLinePoint = active);
    }
  }

  @override
  void dispose() {
    _measurer.invalidate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    final lines = _lineSeries;
    // Emptiness: no category with a non-empty series AND no line data
    // (`GroupedVerticalBarChart.tsx:780-787`).
    if (categories.every((category) => category.series.isEmpty) &&
        lines.every((series) => series.data.isEmpty)) {
      return Semantics(
        container: true,
        liveRegion: true,
        label: 'Graph has no data to display',
        child: const SizedBox.shrink(),
      );
    }
    final theme = FluentTheme.of(context);
    final style = _resolveStyle();
    final colours = _legendColours(categories);
    final barLegends = <String>{
      for (final category in categories)
        for (final point in category.series) point.legend,
    };
    return FluentCartesianChart(
      focusNode: widget.focusNode,
      legendSelectionMode: widget.legendSelectionMode,
      selectedLegends: _selectedLegends,
      onLegendChange: (selected) => setState(() => _selectedLegends = selected),
      props: widget.props.copyWith(
        // GVBC forwards `props.tickPadding || 5`, which the shell's precedence
        // bug turns into a flat 5 (`.tsx:1006`, `CartesianChart.tsx:215`).
        tickPadding: widget.props.tickPadding ?? 5,
        chartTitleForSemantics:
            '${widget.chartTitle == null ? '' : '${widget.chartTitle}. '}'
            'Vertical bar chart with ${barLegends.length} grouped bar series'
            '${lines.isEmpty ? '. ' : ' and ${lines.length} line series. '}',
        // GVBC anchors the popover to the hovered element's rect, not to a
        // virtual element at the pointer (`.tsx:437`, `:970`).
        popoverAnchorsToRegion: true,
        // `isCalloutForStack` moves the callout onto the whole group
        // (`.tsx:447`, `:984`), which is the shell's group granularity.
        hitRegionGranularity: widget.isCalloutForStack
            ? FluentChartHitGranularity.group
            : FluentChartHitGranularity.mark,
      ),
      legends: <FluentChartLegendItem>[
        // Line legends first (`.tsx:252-253`) — the reverse of VSBC.
        for (final series in lines)
          FluentChartLegendItem(
            title: series.legend,
            color: colours[series.legend]!,
            shape: series.legendShape,
            onHoverAction: () => setState(() {
              // `hoverAction` clears the line hover first (`.tsx:240-243`).
              _activeLinePoint = null;
              _activeLegend = series.legend;
            }),
            onMouseOutAction: ({required bool isLegendFocused}) =>
                setState(() => _activeLegend = null),
          ),
        for (final legend in barLegends)
          FluentChartLegendItem(
            title: legend,
            color: colours[legend]!,
            onHoverAction: () => setState(() {
              _activeLinePoint = null;
              _activeLegend = legend;
            }),
            onMouseOutAction: ({required bool isLegendFocused}) =>
                setState(() => _activeLegend = null),
          ),
      ],
      delegate: FluentGroupedVerticalBarChartDelegate(
        data: categories,
        lineSeries: lines,
        style: style,
        colors: FluentChartColors.of(theme),
        measurer: _measurer,
        textStyles: FluentChartTextStyles.of(theme),
        selectedLegends: _selectedLegends,
        legendColours: colours,
        activeLegend: _activeLegend,
        activeLinePoint: _activeLinePoint,
        barWidthProp: widget.barWidth,
        maxBarWidth: widget.maxBarWidth,
        hideLabels: widget.hideLabels,
        roundCorners: widget.roundCorners,
        mode: widget.mode,
        xAxisInnerPadding: widget.xAxisInnerPadding,
        xAxisOuterPadding: widget.xAxisOuterPadding,
        hideTickOverlap: widget.props.hideTickOverlap,
        xAxisCategoryOrder: widget.xAxisCategoryOrder,
        yAxisTickFormat: widget.props.yAxisTickFormat,
        culture: widget.culture,
        isCalloutForStack: widget.isCalloutForStack,
      ),
      onPointerMoveInPlot: _handlePointerMove,
      onChartMouseLeave: () => setState(() {
        // `_handleChartMouseLeave` (`.tsx:507-517`).
        _activeLinePoint = null;
      }),
    );
  }
}

/// Applies a [FluentGroupedVerticalBarChartStyle] to every grouped vertical bar
/// chart below it.
class FluentGroupedVerticalBarChartTheme extends InheritedTheme {
  /// Applies [style] to every grouped vertical bar chart in `child`.
  const FluentGroupedVerticalBarChartTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the derived defaults.
  final FluentGroupedVerticalBarChartStyle style;

  /// The nearest grouped vertical bar chart style, or null.
  static FluentGroupedVerticalBarChartStyle? maybeOf(
    BuildContext context,
  ) => context
      .dependOnInheritedWidgetOfExactType<FluentGroupedVerticalBarChartTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentGroupedVerticalBarChartTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentGroupedVerticalBarChartTheme(style: style, child: child);
}
