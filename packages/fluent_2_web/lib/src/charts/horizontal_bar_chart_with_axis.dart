import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'axis/axis_builders.dart';
import 'axis/axis_types.dart';
import 'axis/domain_range.dart';
import 'cartesian/cartesian_layout.dart';
import 'cartesian/cartesian_series_delegate.dart';
import 'chrome/chart_popover.dart';
import 'horizontal_bar_chart_with_axis_style.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/chart_text_styles.dart';
import 'internal/chart_utils.dart';
import 'internal/d3/scale.dart';
import 'internal/d3/stable_sort.dart';
import 'internal/data_viz_palette.dart';
import 'model/bar_data.dart';
import 'model/chart_common.dart';
import 'model/chart_value.dart';

/// One placed segment inside a horizontal bar group.
@immutable
class FluentHorizontalBarWithAxisSegment {
  /// Creates a segment.
  const FluentHorizontalBarWithAxisSegment({
    required this.xStart,
    required this.width,
    required this.endX,
    required this.index,
    required this.isPositive,
    required this.showLabel,
  });

  /// Leading edge in plot coordinates.
  final double xStart;

  /// Width after the 2px inter-segment gap has been removed.
  final double width;

  /// Trailing edge in the value direction, where the group label anchors.
  final double endX;

  /// Index inside the group.
  final int index;

  /// Whether the point's value is at or above zero.
  final bool isPositive;

  /// Whether this segment carries the group's total label.
  final bool showLabel;
}

/// A set of points sharing a y category, drawn as one stacked bar.
@immutable
class FluentHorizontalBarGroup {
  /// Creates a group.
  const FluentHorizontalBarGroup({
    required this.yValue,
    required this.points,
    required this.total,
    required this.showLabel,
  });

  /// The shared y category.
  final Object yValue;

  /// The points, in insertion order.
  final List<FluentHorizontalBarChartWithAxisDataPoint> points;

  /// The plain sum of the group's x values.
  final double total;

  /// Whether the label goes on the last positive bar rather than the last
  /// negative one.
  final bool showLabel;
}

/// Pure layout maths for the horizontal bar chart with an axis, over
/// [FluentHorizontalBarChartWithAxisDataPoint] groups.
abstract final class FluentHorizontalBarChartGeometry {
  /// The inter-segment gap in pixels (`HorizontalBarChartWithAxis.tsx:438`,
  /// `:444`).
  static const double kSegmentGap = 2;

  /// The value the bars grow from — `X_ORIGIN`
  /// (`HorizontalBarChartWithAxis.tsx:80`).
  static const double kXOrigin = 0;

  /// Ports `_calculateBarTotals` (`HorizontalBarChartWithAxis.tsx:345-369`).
  ///
  /// Upstream sums the positive and the negative points separately and adds the
  /// two, which is the plain sum, and puts the group's label on the last bar of
  /// whichever side the sign of that sum names (`:352-353`, `:359-366`).
  static ({double total, bool showLabelOnLastPositive}) totalsFor(
    List<FluentHorizontalBarChartWithAxisDataPoint> group,
  ) {
    var total = 0.0;
    for (final point in group) {
      total += point.x;
    }
    return (total: total, showLabelOnLastPositive: total >= 0);
  }

  /// Ports the per-point block of `_createNumericBars` / `_createStringBars`
  /// (`HorizontalBarChartWithAxis.tsx:404-465`, `:583-640`).
  ///
  /// `prevPoint` deliberately lags one iteration: the accumulator is advanced
  /// from the *previous* point's value before `xStart` is computed, so the
  /// first segment contributes no offset. The two upstream variants assign
  /// `prevPoint` at different lines (`:455` after, `:626` before) yet agree,
  /// because `xStart` reads the accumulators rather than `prevPoint`.
  ///
  /// Only the x geometry lives here. The y placement differs between the two
  /// variants — the numeric one centres on `yBarScale(y)` (`:468`) while the
  /// string one adds half the leftover bandwidth (`:643`) — and belongs to the
  /// delegate that knows which scale it holds.
  static List<FluentHorizontalBarWithAxisSegment> layOutGroup({
    required List<FluentHorizontalBarChartWithAxisDataPoint> group,
    required Scale xBarScale,
    required double containerWidth,
    required FluentChartMargins margins,
    required bool isRtl,
  }) {
    final originPx = xBarScale(kXOrigin)!;
    final totalPositive = group.where((point) => point.x >= kXOrigin).length;
    final totalNegative = group.length - totalPositive;
    final totals = totalsFor(group);

    var prevWidthPositive = 0.0;
    var prevWidthNegative = 0.0;
    var prevPoint = 0.0;
    var currPositive = 0;
    var currNegative = 0;

    final out = <FluentHorizontalBarWithAxisSegment>[];
    for (var index = 0; index < group.length; index++) {
      final x = group[index].x;
      if (x >= kXOrigin) {
        currPositive++;
      }
      if (x < kXOrigin) {
        currNegative++;
      }
      // `.tsx:415-418`. The RTL arm mirrors the bar's leading edge about the
      // plot, so it is the only place the container width and the margins are
      // read.
      final barStartX = isRtl
          ? containerWidth -
                ((margins.right ?? 0) +
                    math.max(xBarScale(x)!, originPx) -
                    (margins.left ?? 0))
          : math.min(xBarScale(x)!, originPx);

      final prevBarWidth = (xBarScale(prevPoint)! - originPx).abs();
      if (prevPoint > kXOrigin) {
        prevWidthPositive += prevBarWidth;
      } else {
        prevWidthNegative += prevBarWidth;
      }
      final currentWidth = (xBarScale(x)! - originPx).abs();
      // `.tsx:436-442`: every positive bar but the last is trimmed, and a
      // negative bar is trimmed whenever anything can sit beside it.
      final gapLtr =
          currentWidth > kSegmentGap &&
              ((x > kXOrigin && currPositive != totalPositive) ||
                  (x < kXOrigin && (totalPositive != 0 || currNegative > 1)))
          ? kSegmentGap
          : 0.0;
      // `.tsx:443-448`: the mirror image — the negative side keeps its last bar
      // whole and the positive side is trimmed whenever anything can sit beside
      // it. Note this is *not* the LTR rule with the sides swapped: an RTL
      // group's last positive bar is trimmed, its LTR twin is not.
      final gapRtl =
          currentWidth > kSegmentGap &&
              ((x > kXOrigin && (totalNegative != 0 || currPositive > 1)) ||
                  (x < kXOrigin && currNegative != totalNegative))
          ? kSegmentGap
          : 0.0;
      // `.tsx:449-454`.
      final double xStart;
      if (isRtl) {
        xStart = x > kXOrigin
            ? barStartX - prevWidthPositive
            : barStartX + prevWidthNegative;
      } else {
        xStart = x > kXOrigin
            ? barStartX + prevWidthPositive
            : barStartX - prevWidthNegative;
      }
      prevPoint = x;
      final width = currentWidth - (isRtl ? gapRtl : gapLtr);
      final isPositive = x >= kXOrigin;
      // `.tsx:458-464`.
      final double endX;
      if (isRtl) {
        endX = isPositive ? xStart : xStart + width;
      } else {
        endX = isPositive ? xStart + width : xStart;
      }
      out.add(
        FluentHorizontalBarWithAxisSegment(
          xStart: xStart,
          width: width,
          endX: endX,
          index: index,
          isPositive: isPositive,
          // `shouldShowLabel` (`.tsx:359-366`), whose two counters are the ones
          // already advanced above.
          showLabel: totals.showLabelOnLastPositive
              ? isPositive && currPositive == totalPositive
              : !isPositive && currNegative == totalNegative,
        ),
      );
    }
    return out;
  }
}

/// Renders horizontal bars with a numeric value axis on x.
///
/// Ports `HorizontalBarChartWithAxis.tsx` (946 lines). The axes are transposed
/// relative to every other bar chart — the value axis is x, the category axis
/// is y — but the internal vocabulary keeps the vertical names, matching
/// upstream's own comment at `.tsx:769-775`.
class FluentHorizontalBarChartWithAxisDelegate
    extends FluentCartesianSeriesDelegate {
  /// Creates a delegate.
  const FluentHorizontalBarChartWithAxisDelegate({
    required this.points,
    required this.style,
    required this.colors,
    required this.measurer,
    required this.textStyles,
    required this.selectedLegends,
    this.selectedLegendTitle,
    this.barHeightProp,
    this.maxBarHeight,
    this.yAxisPadding = 0.5,
    this.useSingleColor = false,
    this.hideLabels = false,
    this.roundCorners = false,
    this.colorsOverride,
    this.yAxisCategoryOrder = FluentAxisCategoryOrder.defaultOrder,
    this.xMaxValue,
  });

  /// The data points, in author order.
  final List<FluentHorizontalBarChartWithAxisDataPoint> points;

  /// The resolved style.
  final FluentHorizontalBarChartWithAxisStyle style;

  /// Resolved chart colours.
  final FluentChartColors colors;

  /// The chart subtree's single text measurer.
  final FluentChartTextMeasurer measurer;

  /// Resolved chart text styles.
  final FluentChartTextStyles textStyles;

  /// Legend titles selected by the user.
  final List<String> selectedLegends;

  /// The legacy single-title highlight HBWA keeps alongside [selectedLegends]
  /// (`.tsx:84-92`, `:747-749`).
  final String? selectedLegendTitle;

  /// `props.barHeight`, which overrides the auto value before clamping.
  final double? barHeightProp;

  /// Optional ceiling on the auto bar height.
  final double? maxBarHeight;

  /// Band padding, default 0.5 (`.tsx:77`), coerced to 0.99 when exactly 1.
  @override
  final double yAxisPadding;

  /// Whether every bar takes a single colour.
  final bool useSingleColor;

  /// Whether the group total labels are suppressed.
  final bool hideLabels;

  /// Whether bars get a corner radius (`.tsx:475`).
  final bool roundCorners;

  /// A caller-supplied ramp.
  final List<Color>? colorsOverride;

  /// Ordering applied to a category y axis.
  final FluentAxisCategoryOrder yAxisCategoryOrder;

  /// User-supplied value-axis ceiling.
  final double? xMaxValue;

  @override
  FluentChartType get chartType => FluentChartType.horizontalBarChartWithAxis;

  @override
  FluentChartAxisType get xAxisType => FluentChartAxisType.numeric;

  @override
  FluentChartAxisType get yAxisType => points.isEmpty
      ? FluentChartAxisType.category
      : getTypeOfAxis(points.first.y, isXAxis: false);

  /// The points grouped by y value, in insertion order.
  List<FluentHorizontalBarGroup> get groups {
    final grouped = groupChartDataByYValue(points);
    return <FluentHorizontalBarGroup>[
      for (final entry in grouped.entries)
        () {
          final group = entry.value
              .cast<FluentHorizontalBarChartWithAxisDataPoint>()
              .toList(growable: false);
          final totals = FluentHorizontalBarChartGeometry.totalsFor(group);
          return FluentHorizontalBarGroup(
            yValue: group.first.y,
            points: group,
            total: totals.total,
            showLabel: totals.showLabelOnLastPositive,
          );
        }(),
    ];
  }

  @override
  List<String>? get stringDatasetForYAxisDomain {
    if (yAxisType != FluentChartAxisType.category) {
      return null;
    }
    if (yAxisCategoryOrder != FluentAxisCategoryOrder.defaultOrder) {
      // `_mapCategoryToValues` (`.tsx:832-838`) pushes every x onto its
      // category's list, so a category that appears twice contributes twice to
      // the aggregate the sort reads.
      final categoryToValues = <String, List<double>>{};
      for (final point in points) {
        (categoryToValues['${point.y}'] ??= <double>[]).add(point.x);
      }
      return sortAxisCategories(categoryToValues, yAxisCategoryOrder);
    }
    // parity: `[...points].reverse().map(p => p.y)` at `.tsx:819-829` does NOT
    // de-duplicate. d3's own ordinal domain setter does
    // (`d3-scale/src/ordinal.js`), so the band range is sized for the distinct
    // categories either way; the repeats survive only in the tick list.
    //
    // parity: the Oracle B captures place the *first* data group at the band
    // the *last* label names, which is the opposite of what this reversal
    // produces. The reversal is what the cited source does, so it is what this
    // ports; see the test note in
    // `test/charts/horizontal_bar_chart_with_axis_test.dart`.
    return <String>[for (final point in points.reversed) '${point.y}'];
  }

  /// Ports `_calculateAppropriateBarHeight` (`.tsx:508-525`).
  ///
  /// A near copy of `calculateAppropriateBarWidth` with one extra step: the
  /// range is widened by the data maximum before the formula runs.
  double appropriateBarHeight(
    List<Object> uniqueY,
    double totalHeight,
    double innerPadding,
  ) {
    final pair = getClosestPairDiffAndRange(uniqueY);
    if (pair == null || pair.$2 == 0) {
      // The 16 fallback at `vbc-utils.ts:37`.
      return kDefaultBarWidth;
    }
    final closest = pair.$1;
    var range = pair.$2;
    for (final y in uniqueY) {
      if (y is num && y.toDouble() > range) {
        range = y.toDouble();
      }
    }
    // The 1 is the whole of the unit interval the padding is a fraction of.
    return (totalHeight *
            closest *
            (1 - innerPadding) /
            (range + closest * (1 - innerPadding)))
        .floorToDouble();
  }

  /// Ports `_getDomainMarginsForHorizontalBarChart` (`.tsx:527-558`).
  ({double barHeight, FluentChartMargins margins}) solveYDomainMargins(
    double containerHeight,
  ) {
    // Upstream reads margins off the closure; the shell hands them in, so the
    // defaults are spelled out here: top 20, bottom 35
    // (`CartesianChart.tsx:41`).
    const marginTop = 20.0;
    const marginBottom = 35.0;
    var domainMargin = kMinDomainMargin;
    // `_yAxisPadding === 1 ? 0.99 : _yAxisPadding` (`.tsx:531`).
    final padding = yAxisPadding == 1 ? 0.99 : yAxisPadding;
    final uniqueY = <Object>{
      for (final point in points) point.y,
    }.toList(growable: false);
    // `.tsx:533-534`. The 1 is the unit interval the padding is a fraction of.
    final barGapRate = padding / (1 - padding);
    final numBars = uniqueY.length + (uniqueY.length - 1) * barGapRate;
    final totalHeight =
        containerHeight -
        (marginTop + kMinDomainMargin) -
        (marginBottom + kMinDomainMargin);

    double barHeight;
    if (yAxisType != FluentChartAxisType.category) {
      barHeight =
          barHeightProp ?? appropriateBarHeight(uniqueY, totalHeight, padding);
      // `.tsx:540` — 1px is upstream's floor on a computed bar height.
      barHeight = math.max(barHeight, 1);
      // The 2 halves the bar across the band centre it is drawn about.
      domainMargin += barHeight / 2;
    } else {
      barHeight = barHeightProp ?? totalHeight / numBars;
      final requiredHeight = numBars * barHeight;
      if (totalHeight >= requiredHeight) {
        // `.tsx:552` — the 2 splits the slack evenly across the two ends.
        domainMargin = kMinDomainMargin + (totalHeight - requiredHeight) / 2;
      }
    }
    return (
      barHeight: barHeight,
      margins: FluentChartMargins(
        top: marginTop + domainMargin,
        bottom: marginBottom + domainMargin,
      ),
    );
  }

  @override
  FluentChartMargins? yDomainMargins(double containerHeight) =>
      solveYDomainMargins(containerHeight).margins;

  @override
  FluentChartDomainRange resolveXDomainRange({
    required FluentChartMargins margins,
    required double containerWidth,
    required bool isRtl,
    required double? barWidth,
    required List<Object>? tickValues,
  }) => domainRangeOfNumericForHorizontalBarChartWithAxis(
    points,
    margins,
    containerWidth,
    isRtl: isRtl,
  );

  @override
  FluentChartMinMax resolveYMinMax({bool useSecondaryYScale = false}) =>
      findHBCWANumericMinMaxOfY(points, yAxisType);

  @override
  FluentAxisSpec createYAxis(
    FluentYAxisParams params,
    FluentAxisData axisData, {
    required bool isRtl,
    required bool isIntegralDataset,
    bool useSecondaryYScale = false,
  }) =>
      createYAxisForHorizontalBarChartWithAxis(params, axisData, isRtl: isRtl);

  @override
  FluentAxisSpec createStringYAxis(
    FluentYAxisParams params,
    List<String> dataPoints,
    FluentAxisData axisData, {
    required bool isRtl,
  }) => createStringYAxisForHorizontalBarChartWithAxis(
    params,
    dataPoints,
    axisData,
    isRtl: isRtl,
  );

  /// Every bar rectangle, group by group.
  List<Rect> rectsFor(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) => <Rect>[for (final bar in placeBars(context, layout)) bar.rect];

  /// Every bar rectangle with the point and segment it came from.
  ///
  /// [rectsFor] is the geometry-only view of this; the painter and the hit
  /// regions need the point as well, and running the layout twice would run
  /// the running-offset fold twice.
  List<
    ({
      Rect rect,
      FluentHorizontalBarChartWithAxisDataPoint point,
      int indexInGroup,
      FluentHorizontalBarWithAxisSegment segment,
    })
  >
  placeBars(FluentCartesianChildContext context, FluentCartesianLayout layout) {
    final barHeight = solveYDomainMargins(layout.size.height).barHeight;
    final isBand = yAxisType == FluentChartAxisType.category;
    final out =
        <
          ({
            Rect rect,
            FluentHorizontalBarChartWithAxisDataPoint point,
            int indexInGroup,
            FluentHorizontalBarWithAxisSegment segment,
          })
        >[];
    for (final group in groups) {
      // The numeric variant sorts each group by y descending first
      // (`:383-388`).
      final ordered = isBand
          ? group.points
          : stableSort<FluentHorizontalBarChartWithAxisDataPoint>(
              group.points,
              (a, b) => (b.y as num).compareTo(a.y as num),
            );
      final segments = FluentHorizontalBarChartGeometry.layOutGroup(
        group: ordered,
        xBarScale: context.xScale,
        containerWidth: layout.size.width,
        margins: layout.margins,
        isRtl: layout.isRtl,
      );
      for (final segment in segments) {
        final point = ordered[segment.index];
        final bandTop = context.yScalePrimary(point.y);
        if (bandTop == null) {
          continue;
        }
        // parity: `.tsx:419-422` guards on the scaled POSITION, not the height,
        // so a category within 1px of the canvas top vanishes entirely. The 1
        // is upstream's own literal.
        if (math.max(bandTop, 0) < 1) {
          continue;
        }
        // `.tsx:643` for the band arm, `:473` for the numeric one; the 2
        // centres the bar in its band, respectively about its coordinate.
        final top = isBand
            ? bandTop + 0.5 * (context.yScalePrimary.bandwidth - barHeight)
            : bandTop - barHeight / 2;
        out.add((
          rect: Rect.fromLTWH(segment.xStart, top, segment.width, barHeight),
          point: point,
          indexInGroup: segment.index,
          segment: segment,
        ));
      }
    }
    return out;
  }

  /// The bar fill before the high-contrast flatten.
  ///
  /// Ports the `startColor` block at `.tsx:423-429`. [index] is the point's
  /// index **inside its group**, which is the `index` upstream's `.map` hands
  /// it, so a chart of one point per category paints every bar the first
  /// palette colour.
  ///
  /// `// ponytail:` the `props.colors` arm builds a d3 linear colour ramp over
  /// the x extent; until a caller needs it, [colorsOverride] is indexed
  /// directly. Upgrade path: replace the lookup with the ramp when the
  /// declarative adapter starts passing continuous colour scales.
  Color barColour(FluentHorizontalBarChartWithAxisDataPoint point, int index) {
    final ramp = colorsOverride;
    if (ramp != null && ramp.isNotEmpty) {
      // 1 is upstream's own index into the ramp for the single-colour case.
      return ramp[(useSingleColor ? 1 : index) % ramp.length];
    }
    return point.color ?? FluentDataVizPalette.next(useSingleColor ? 1 : index);
  }

  /// The narration for one bar.
  ///
  /// Ports `_getAriaLabel` (`.tsx:776-781`), whose `||` chain means an empty
  /// override falls through to the composed sentence.
  String ariaLabelFor(FluentHorizontalBarChartWithAxisDataPoint point) {
    final override = point.callOutSemantics?.label;
    if (override != null && override.isNotEmpty) {
      return override;
    }
    final legend = point.legend;
    final prefix = legend == null || legend.isEmpty ? '' : '$legend, ';
    final yValue = point.yAxisCalloutData ?? '${point.y}';
    final xValue = point.xAxisCalloutData ?? '${point.x}';
    return '$yValue. $prefix$xValue.';
  }

  @override
  void paintSeries(
    Canvas canvas,
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
    FluentChartColors chartColors,
  ) {
    const states = <WidgetState>{};
    const dimmed = <WidgetState>{WidgetState.disabled};
    final radius = roundCorners
        ? (style.barCornerRadius?.resolve(states) ?? 0)
        : 0.0;
    for (final bar in placeBars(context, layout)) {
      final highlighted =
          selectedLegends.isEmpty ||
          isLegendHighlightedMulti(
            bar.point.legend ?? '',
            selectedLegends: selectedLegends,
            activeLegend: selectedLegendTitle,
          );
      final paint = Paint()
        ..color = chartColors
            .flattenMark(barColour(bar.point, bar.indexInGroup))
            .withValues(
              alpha: style.barOpacity?.resolve(highlighted ? states : dimmed),
            );
      if (radius > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(bar.rect, Radius.circular(radius)),
          paint,
        );
      } else {
        canvas.drawRect(bar.rect, paint);
      }
    }
  }

  @override
  List<FluentChartHitRegion> buildHitRegions(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) {
    final placed = placeBars(context, layout);
    return <FluentChartHitRegion>[
      for (final (index, bar) in placed.indexed)
        FluentChartHitRegion(
          bounds: bar.rect,
          index: index,
          legend: bar.point.legend ?? '',
          popoverData: FluentChartPopoverData(
            // `.tsx:259-260` — HBWA swaps the axes, so the popover's x line
            // carries the category and its y line the bar length.
            xValue: bar.point.yAxisCalloutData ?? '${bar.point.y}',
            yValue: bar.point.xAxisCalloutData ?? '${bar.point.x}',
            legend: bar.point.legend,
            color: barColour(bar.point, bar.indexInGroup),
          ),
          semanticsLabel: ariaLabelFor(bar.point),
        ),
    ];
  }
}
