import 'package:flutter/widgets.dart';

import 'axis/axis_builders.dart' as builders;
import 'axis/axis_types.dart';
import 'axis/domain_range.dart';
import 'cartesian/cartesian_layout.dart';
import 'cartesian/cartesian_series_delegate.dart';
import 'chrome/chart_popover.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/chart_text_styles.dart';
import 'internal/chart_utils.dart';
import 'internal/data_viz_palette.dart';
import 'internal/marker_geometry.dart';
import 'model/callout_data.dart';
import 'model/cartesian_series.dart';
import 'model/chart_common.dart';
import 'model/chart_value.dart';
import 'scatter_chart_style.dart';

/// One painted scatter marker, resolved against the live scales.
///
/// Produced by [FluentScatterChartDelegate.marksFor] and consumed both by the
/// painter and by the hit-region builder, so the circle a user hovers is
/// guaranteed to be the circle that was painted.
@immutable
class FluentScatterMark {
  /// Creates a mark.
  const FluentScatterMark({
    required this.centre,
    required this.radius,
    required this.colour,
    required this.strokeColour,
    required this.opacity,
    required this.isActive,
    required this.seriesIndex,
    required this.pointIndex,
    required this.labelBaselineOffset,
    required this.semanticsLabel,
    this.label,
  });

  /// Circle centre in chart coordinates.
  final Offset centre;

  /// Circle radius from [calculateMarkerRadius].
  final double radius;

  /// The series colour, already flattened by [FluentChartColors.flattenMark].
  ///
  /// The point's own `markerColor` is deliberately ignored: ScatterChart reads
  /// only `series.color` (`ScatterChart.tsx:474`).
  final Color colour;

  /// The halo colour, flattened by [FluentChartColors.flattenMarkStroke].
  ///
  /// Upstream strokes the circle with the same series colour it fills with
  /// (`ScatterChart.tsx:475`); the two only diverge under forced colours, where
  /// sending both to the system foreground would erase the outline (spec
  /// section 5.3).
  final Color strokeColour;

  /// 1 when the mark's legend owns the highlight, 0.1 otherwise.
  final double opacity;

  /// Whether this is the active point, which inverts the fill.
  final bool isActive;

  /// Index of the owning series in the original, unreversed order.
  final int seriesIndex;

  /// Index of the point inside its series.
  final int pointIndex;

  /// `max(radius + 12, 16)` — the label baseline drop (`ScatterChart.tsx:484`).
  final double labelBaselineOffset;

  /// The accessible name for this mark.
  final String semanticsLabel;

  /// The point's own `text`, painted below the marker when present.
  final String? label;
}

/// Renders `data.scatterChartData` into the shared cartesian shell.
///
/// Ports `ScatterChart.tsx` (771 lines). The 3x2 axis-type matrix — x numeric,
/// date or category against y numeric or category — is resolved once in
/// [xAxisType] / [yAxisType] and then only changes two things: whether a half
/// bandwidth is added to a centre, and whether the marker sizes are scaled to
/// the plot (`isContinuousXY`) or normalised into `[4, 16]`.
class FluentScatterChartDelegate extends FluentCartesianSeriesDelegate {
  /// Creates a delegate over [data].
  const FluentScatterChartDelegate({
    required this.data,
    required this.style,
    required this.colors,
    required this.textStyles,
    required this.measurer,
    required this.selectedLegends,
    this.activeLegend,
    this.activePointId,
    this.xScaleType,
    this.yScaleType,
    this.xMinValue,
    this.xMaxValue,
    this.yAxisCategoryOrder = FluentAxisCategoryOrder.defaultOrder,
  });

  /// The chart's data bundle. Only [FluentChartData.scatterChartData] is read.
  final FluentChartData data;

  /// The resolved style.
  final FluentScatterChartStyle style;

  /// Resolved chart colours, which also carry the high-contrast flattening.
  final FluentChartColors colors;

  /// Resolved chart text styles.
  final FluentChartTextStyles textStyles;

  /// The chart subtree's single text measurer.
  final FluentChartTextMeasurer measurer;

  /// Legend titles selected by the user.
  final List<String> selectedLegends;

  /// Legend title currently hovered, if any.
  final String? activeLegend;

  /// Identifier of the active point, `"<series>_<point>"`.
  final String? activePointId;

  /// Optional log scaling on x.
  final FluentAxisScaleType? xScaleType;

  /// Optional log scaling on y.
  final FluentAxisScaleType? yScaleType;

  /// User-supplied x domain floor.
  final double? xMinValue;

  /// User-supplied x domain ceiling.
  final double? xMaxValue;

  /// Ordering applied to a category y axis.
  final FluentAxisCategoryOrder yAxisCategoryOrder;

  List<FluentScatterChartSeries> get _series =>
      data.scatterChartData ?? const <FluentScatterChartSeries>[];

  @override
  FluentChartType get chartType => FluentChartType.scatterChart;

  @override
  FluentChartAxisType get xAxisType =>
      _series.isEmpty || _series.first.data.isEmpty
      // parity: ScatterChart.tsx:116-122 falls back to a category axis.
      ? FluentChartAxisType.category
      : getTypeOfAxis(_series.first.data.first.x, isXAxis: true);

  @override
  FluentChartAxisType get yAxisType =>
      _series.isEmpty || _series.first.data.isEmpty
      // parity: ScatterChart.tsx:124-132 falls back to numeric, not category.
      ? FluentChartAxisType.numeric
      : _series.first.data.first.y is String
      ? FluentChartAxisType.category
      : FluentChartAxisType.numeric;

  /// Whether neither axis is a band scale (`ScatterChart.tsx:389`).
  bool get isContinuousXy =>
      xAxisType != FluentChartAxisType.category &&
      yAxisType != FluentChartAxisType.category;

  @override
  FluentChartDomainRange resolveXDomainRange({
    required FluentChartMargins margins,
    required double containerWidth,
    required bool isRtl,
    required double? barWidth,
    required List<Object>? tickValues,
  }) => switch (xAxisType) {
    FluentChartAxisType.numeric => domainRangeOfNumericForAreaLineScatterCharts(
      _series,
      margins,
      containerWidth,
      isRtl: isRtl,
      scaleType: xScaleType,
      // ScatterChart.tsx:205-212 hard-codes hasMarkersMode true, so the numeric
      // x domain ALWAYS carries the ten-percent marker pad.
      hasMarkersMode: true,
      xMinVal: xMinValue,
      xMaxVal: xMaxValue,
    ),
    FluentChartAxisType.date =>
      domainRangeOfDateForAreaLineScatterVerticalBarCharts(
        _series,
        margins,
        containerWidth,
        isRtl: isRtl,
        tickValues: tickValues?.whereType<DateTime>().toList() ?? _noDates,
        chartType: FluentChartType.scatterChart,
      ),
    FluentChartAxisType.category => domainRangeOfXStringAxis(
      margins,
      containerWidth,
      isRtl: isRtl,
    ),
  };

  static const List<DateTime> _noDates = <DateTime>[];

  @override
  FluentChartMinMax resolveYMinMax({bool useSecondaryYScale = false}) {
    final raw = findNumericMinMaxOfY(
      _series,
      useSecondaryYScale: useSecondaryYScale,
      scaleType: yScaleType,
    );
    final pad = getDomainPaddingForMarkers(
      raw.startValue,
      raw.endValue,
      scaleType: yScaleType,
    );
    // ponytail: exactly one pad, at `ScatterChart.tsx:181-190`.
    // `utilities.ts:825-831` computes a second one into locals that `:832`
    // never reads, so reproducing it would be a bug, not parity. Contract §1.
    return FluentChartMinMax(
      startValue: raw.startValue - pad.start,
      endValue: raw.endValue + pad.end,
    );
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
    chartType: FluentChartType.scatterChart,
    useSecondaryYScale: useSecondaryYScale,
    scaleType: yScaleType,
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
    chartType: FluentChartType.scatterChart,
  );

  @override
  List<String>? get datasetForXAxisDomain =>
      xAxisType == FluentChartAxisType.category ? xAxisCategories : null;

  @override
  List<String>? get stringDatasetForYAxisDomain =>
      yAxisType == FluentChartAxisType.category ? orderedYAxisLabels : null;

  @override
  bool get isIntegralDataset => !_series.any(
    (FluentScatterChartSeries series) => series.data.any(
      (FluentScatterChartDataPoint point) =>
          point.y is num && (point.y as num) % 1 != 0,
    ),
  );

  /// The unique category x values, in series-forward, point-forward order
  /// (`ScatterChart.tsx:709-714`).
  List<String> get xAxisCategories {
    final seen = <String>{};
    for (final series in _series) {
      for (final point in series.data) {
        if (point.x is String) {
          seen.add(point.x as String);
        }
      }
    }
    return seen.toList(growable: false);
  }

  /// The category y labels.
  ///
  /// With the default order upstream walks the **series backwards** and the
  /// points forwards, keeping first-seen order in that reversed traversal
  /// (`ScatterChart.tsx:303-315`); any other order delegates to
  /// [sortAxisCategories].
  List<String> get orderedYAxisLabels {
    if (yAxisCategoryOrder != FluentAxisCategoryOrder.defaultOrder) {
      return sortAxisCategories(_categoryToValues(), yAxisCategoryOrder);
    }
    final seen = <String>{};
    for (var i = _series.length - 1; i >= 0; i--) {
      for (final point in _series[i].data) {
        if (point.y is String) {
          seen.add(point.y as String);
        }
      }
    }
    return seen.toList(growable: false);
  }

  /// `_mapCategoryToValues` (`ScatterChart.tsx:319-336`): only a **numeric** x
  /// joins the bucket, so a category-against-category chart sorts on empty
  /// lists.
  Map<String, List<double>> _categoryToValues() {
    final out = <String, List<double>>{};
    for (final series in _series) {
      for (final point in series.data) {
        if (point.y is String) {
          final bucket = out[point.y as String] ??= <double>[];
          if (point.x is num) {
            bucket.add((point.x as num).toDouble());
          }
        }
      }
    }
    return out;
  }

  /// Resolves every marker for [context].
  ///
  /// Series are walked from last to first so that series 0 paints last and
  /// therefore sits on top (`ScatterChart.tsx:399`).
  List<FluentScatterMark> marksFor(FluentCartesianChildContext context) {
    // parity: ScatterChart.tsx:435 suppresses every circle and label in text
    // mode. `isTextMode` reads `lineOptions` through an `as any` cast
    // (`utilities.ts:2219`) and `ScatterChartPoints` declares no such member
    // (`types/DataPoint.ts:1033-1071`), so this can only fire if the model ever
    // grows one. It is kept because the widget's legend is gated on the same
    // predicate (`ScatterChart.tsx:680`).
    if (isTextMode(_series)) {
      return const <FluentScatterMark>[];
    }
    final xBandwidth = xAxisType == FluentChartAxisType.category
        ? context.xScale.bandwidth / 2
        : 0.0;
    final (minSize, maxSize) = _markerSizeExtent();
    final extraMaxPixels = isContinuousXy
        ? getRangeForScatterMarkerSize(
            points: _series,
            xScale: context.xScale,
            yScalePrimary: context.yScalePrimary,
            yScaleSecondary: context.yScaleSecondary,
            xScaleType: xScaleType,
            yScaleType: yScaleType,
          )
        : 0.0;
    final defaultRadius = style.markerRadius!.resolve(<WidgetState>{})!;
    final activeRadius = style.markerRadius!.resolve(<WidgetState>{
      WidgetState.hovered,
    })!;
    final dimOpacity = style.markerOpacity!.resolve(<WidgetState>{
      WidgetState.disabled,
    })!;
    final fullOpacity = style.markerOpacity!.resolve(<WidgetState>{})!;
    final labelGap = style.markerLabelGap!.resolve(<WidgetState>{})!;
    final labelMinGap = style.markerLabelMinGap!.resolve(<WidgetState>{})!;

    final marks = <FluentScatterMark>[];
    for (var i = _series.length - 1; i >= 0; i--) {
      final series = _series[i];
      final highlighted = isLegendHighlightedMulti(
        series.legend,
        selectedLegends: selectedLegends,
        activeLegend: activeLegend,
      );
      // `_noLegendHighlighted` (`ScatterChart.tsx:447`), whose activeLegend arm
      // is an emptiness test rather than a null test upstream.
      final noneHighlighted =
          selectedLegends.isEmpty &&
          (activeLegend == null || activeLegend!.isEmpty);
      final selected = highlighted || noneHighlighted;
      final rawColour = series.color ?? FluentDataVizPalette.next(i);
      final colour = colors.flattenMark(rawColour);
      final strokeColour = colors.flattenMarkStroke(rawColour);
      for (var j = 0; j < series.data.length; j++) {
        final point = series.data[j];
        final rawX = context.xScale(point.x);
        final scaledY = context.yScalePrimary(point.y);
        final rawY =
            yAxisType == FluentChartAxisType.category && scaledY != null
            ? scaledY + context.yScalePrimary.bandwidth / 2
            : scaledY;
        if (!isPlottable(rawX, rawY)) {
          continue;
        }
        final isActive = activePointId == '${i}_$j';
        final radius = calculateMarkerRadius(
          pointMarkerSize: point.markerSize,
          minMarkerSize: minSize,
          maxMarkerSize: maxSize,
          extraMaxPixels: extraMaxPixels,
          isContinuousXY: isContinuousXy,
          isActive: isActive,
          defaultRadius: defaultRadius,
          activeRadius: activeRadius,
        );
        // `currentPointHidden` (`ScatterChart.tsx:430`).
        final hidden = series.hideInactiveDots && !isActive;
        marks.add(
          FluentScatterMark(
            centre: Offset(rawX! + xBandwidth, rawY!),
            radius: radius,
            colour: colour,
            strokeColour: strokeColour,
            opacity: selected && !hidden ? fullOpacity : dimOpacity,
            isActive: isActive,
            seriesIndex: i,
            pointIndex: j,
            labelBaselineOffset: radius + labelGap > labelMinGap
                ? radius + labelGap
                : labelMinGap,
            semanticsLabel: _semanticsLabelFor(series, point),
            label: point.text,
          ),
        );
      }
    }
    return marks;
  }

  /// `_getAriaLabel` (`ScatterChart.tsx:647-656`).
  String _semanticsLabelFor(
    FluentScatterChartSeries series,
    FluentScatterChartDataPoint point,
  ) =>
      point.callOutSemantics?.label ??
      '${point.xAxisCalloutData ?? point.x}. ${series.legend}, '
          '${point.yAxisCalloutText ?? point.y}.';

  (double, double) _markerSizeExtent() {
    double? lo;
    double? hi;
    for (final series in _series) {
      for (final point in series.data) {
        final size = point.markerSize;
        if (size == null) {
          continue;
        }
        lo = lo == null || size < lo ? size : lo;
        hi = hi == null || size > hi ? size : hi;
      }
    }
    // `?? 0` reproduces `d3Min(...) ?? 0` at ScatterChart.tsx:376 and :386.
    return (lo ?? 0, hi ?? 0);
  }

  @override
  void paintSeries(
    Canvas canvas,
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
    FluentChartColors colours,
  ) {
    final strokeWidth = style.markerStrokeWidth!.resolve(<WidgetState>{})!;
    final activeFill = style.activeMarkerFillColor!.resolve(<WidgetState>{})!;
    final labelStyle = style.markerLabelStyle!.resolve(<WidgetState>{})!;
    for (final mark in marksFor(context)) {
      // `_getPointFill` (`ScatterChart.tsx:354-360`) inverts the active marker
      // to the canvas colour rather than growing a ring.
      canvas
        ..drawCircle(
          mark.centre,
          mark.radius,
          Paint()
            ..color = (mark.isActive ? activeFill : mark.colour).withValues(
              alpha: mark.opacity,
            ),
        )
        ..drawCircle(
          mark.centre,
          mark.radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..color = mark.strokeColour.withValues(alpha: mark.opacity),
        );
      final label = mark.label;
      if (label == null) {
        continue;
      }
      // `text-anchor: middle` on an alphabetic baseline
      // (`ScatterChart.tsx:481-488`, `Common.styles.ts:72-81`).
      final painter = measurer.layoutPainter(label, labelStyle);
      final metrics = measurer.measure(label, labelStyle);
      painter.paint(
        canvas,
        Offset(
          mark.centre.dx - metrics.width / 2,
          mark.centre.dy + mark.labelBaselineOffset - metrics.ascent,
        ),
      );
      painter.dispose();
    }
  }

  @override
  List<FluentChartHitRegion> buildHitRegions(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) => <FluentChartHitRegion>[
    for (final mark in marksFor(context))
      FluentChartHitRegion(
        bounds: Rect.fromCircle(center: mark.centre, radius: mark.radius),
        index: mark.pointIndex,
        legend: _series[mark.seriesIndex].legend,
        popoverData: popoverFor(mark),
        semanticsLabel: mark.semanticsLabel,
      ),
  ];

  /// The popover reading for [mark] (`ScatterChart.tsx:520-546`).
  FluentChartPopoverData popoverFor(FluentScatterMark mark) {
    final series = _series[mark.seriesIndex];
    final point = series.data[mark.pointIndex];
    return FluentChartPopoverData(
      xValue: point.xAxisCalloutData ?? '${point.x}',
      // ScatterChart.tsx:694 always sets isCalloutForStack, so the multi-value
      // popover body is used even for a single marker.
      isCalloutForStack: true,
      yValues: <FluentYValueHover>[
        FluentYValueHover(
          legend: series.legend,
          y: point.y is num ? (point.y as num).toDouble() : null,
          color: mark.colour,
          yAxisCalloutText:
              point.yAxisCalloutText ??
              (point.y is String ? point.y as String : null),
          yAxisCalloutBreakdown: point.yAxisCalloutBreakdown,
          index: mark.seriesIndex,
          shape: series.legendShape,
        ),
      ],
    );
  }
}
