import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'axis/axis_builders.dart' as builders;
import 'axis/axis_types.dart';
import 'axis/domain_range.dart';
import 'axis/tick_format.dart';
import 'cartesian/cartesian_layout.dart';
import 'cartesian/cartesian_series_delegate.dart';
import 'chrome/chart_popover.dart';
import 'grouped_vertical_bar_chart_style.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/chart_text_styles.dart';
import 'internal/chart_utils.dart';
import 'internal/d3/scale.dart' as d3;
import 'internal/d3/scale_band.dart' as d3;
import 'internal/data_viz_palette.dart';
import 'model/bar_data.dart';
import 'model/chart_common.dart';
import 'model/chart_value.dart';

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
    this.xAxisOuterPadding,
    this.hideTickOverlap = true,
    this.xAxisCategoryOrder = FluentAxisCategoryOrder.defaultOrder,
    this.yAxisTickFormat,
    // The inner padding is stored raw and resolved by [xAxisInnerPadding],
    // which needs a legend count the caller does not have. A named parameter
    // cannot be a private initialising formal, hence the explicit assignment.
    // ignore: prefer_initializing_formals
  }) : _xAxisInnerPadding = xAxisInnerPadding;

  /// The categories, in author order.
  final List<FluentGroupedVerticalBarChartData> data;

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

  /// Category-scale outer padding override.
  @override
  final double? xAxisOuterPadding;

  /// Whether the shell prunes overlapping x ticks — default true.
  final bool hideTickOverlap;

  /// Ordering applied to the category x axis.
  final FluentAxisCategoryOrder xAxisCategoryOrder;

  /// Caller-supplied y tick formatter, reused for total labels.
  final String Function(double value)? yAxisTickFormat;

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
  FluentChartMargins? domainMargins(double containerWidth) => null;

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
      final yValue =
          point.yAxisCalloutData ?? formatScientificLimitWidth(point.data);
      regions.add(
        FluentChartHitRegion(
          bounds: bar.rect,
          index: regions.length,
          legend: bar.legend,
          popoverData: FluentChartPopoverData(
            xValue: xValue,
            yValue: yValue,
            legend: bar.legend,
            color: bar.colour,
          ),
          semanticsLabel:
              point.callOutSemantics?.label ??
              '$xValue. ${bar.legend}, $yValue.',
        ),
      );
    }
    return regions;
  }

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
