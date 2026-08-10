import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'axis/axis_builders.dart' as builders;
import 'axis/axis_types.dart';
import 'axis/domain_range.dart';
import 'axis/tick_format.dart';
import 'cartesian/cartesian_layout.dart';
import 'cartesian/cartesian_series_delegate.dart';
import 'chrome/chart_popover.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/chart_text_styles.dart';
import 'internal/chart_utils.dart';
import 'internal/d3/path_sink.dart' as d3;
import 'internal/d3/scale.dart';
import 'internal/d3/scale_linear.dart';
import 'internal/d3/shape_line_area.dart' as d3;
import 'model/bar_data.dart';
import 'model/chart_common.dart';
import 'model/chart_value.dart';
import 'vertical_bar_chart_style.dart';

/// One resolved vertical bar.
@immutable
class FluentVerticalBarRect {
  /// Creates a bar rect.
  const FluentVerticalBarRect({
    required this.rect,
    required this.colour,
    required this.opacity,
    required this.index,
    required this.isNegative,
    required this.labelAnchor,
  });

  /// The bar's rectangle in plot coordinates.
  final Rect rect;

  /// Resolved fill.
  final Color colour;

  /// 1 highlighted, 0.1 dimmed.
  final double opacity;

  /// Index of the source data point.
  final int index;

  /// Whether the bar hangs below the baseline.
  final bool isNegative;

  /// Where the bar's label baseline sits, already offset by 6 above or 12
  /// below (`VerticalBarChart.tsx:965`).
  final Offset labelAnchor;
}

/// Pure layout maths for the vertical bar chart.
///
/// Split out from the delegate so every literal below is asserted without a
/// canvas. Ports `VerticalBarChart.tsx:398-413`, `:626-632` and `:976-1064`.
abstract final class FluentVerticalBarChartGeometry {
  /// Ports `_calculateMinBarHeight` (`VerticalBarChart.tsx:626-632`).
  ///
  /// The result is a *pixel floor*: a bar shorter than this is stretched up to
  /// it so a tiny value stays visible. Note the ratio is against 100, not
  /// against the plot height, so it scales with the y range.
  ///
  /// [yBarScale] is the scale `_getScales` builds at
  /// `VerticalBarChart.tsx:584-586` — the data domain onto `[0, plotHeight]`,
  /// so it answers in pixels. Upstream feeds it a *magnitude* rather than a
  /// domain value, which for a domain that does not start at 0 extrapolates;
  /// that is reproduced, not corrected.
  static double minBarHeight({
    required double yMin,
    required double yMax,
    required double yReferencePoint,
    required Scale yBarScale,
  }) {
    // VerticalBarChart.tsx:627-630. The 0 is upstream's own `yMax < 0`.
    final maxHeightFromBaseline = yMax < 0
        ? (yMin - yReferencePoint).abs()
        : math.max(
            (yMax - yReferencePoint).abs(),
            (yMin - yReferencePoint).abs(),
          );
    // 100.0 is upstream's literal divisor at :631, not a percentage of
    // anything.
    return (yBarScale(maxHeightFromBaseline)! / 100.0).ceilToDouble();
  }

  /// Ports `_getDomainMargins` (`VerticalBarChart.tsx:976-1064`).
  ///
  /// Returns both outputs because upstream writes `_barWidth` and
  /// `_domainMargin` into the same closure and the two are mutually dependent:
  /// the bar width comes from the bandwidth, the bandwidth from the margin.
  ///
  /// [isOuterPaddingDefined] is `isScalePaddingDefined(props.xAxisOuterPadding,
  /// props.xAxisPadding)` (`:995`), hoisted to a flag because [outerPadding]
  /// alone cannot tell an explicit 0 from an absent value. [longestLabelWidth]
  /// is `calculateLongestLabelWidth(uniqueX)` (`:1020`), hoisted because it
  /// needs a text measurer this pure function must not own.
  static ({double barWidth, double domainMargin}) solveDomainMargin({
    required FluentChartAxisType xAxisType,
    required int uniqueXCount,
    required double containerWidth,
    required FluentChartMargins margins,
    required Object? barWidthProp,
    required double? maxBarWidth,
    required double innerPadding,
    required double outerPadding,
    required bool isOuterPaddingDefined,
    required String? mode,
    required double longestLabelWidth,
    required List<Object> sortedXValues,
  }) {
    // VerticalBarChart.tsx:977.
    var domainMargin = kMinDomainMargin;
    var barWidth = getBarWidth(barWidthProp, maxBarWidth, mode: mode);
    // vbc-utils.ts:46 via VerticalBarChart.tsx:990 — the two
    // MIN_DOMAIN_MARGINs are subtracted up front.
    final totalWidth = calcTotalWidth(
      containerWidth,
      margins,
      kMinDomainMargin,
    );

    if (xAxisType == FluentChartAxisType.category) {
      if (isOuterPaddingDefined) {
        // VerticalBarChart.tsx:996 — xAxisOuterPadding now does this job.
        domainMargin = 0;
      } else if (barWidthProp != 'auto' && mode != 'histogram') {
        // VerticalBarChart.tsx:1000.
        barWidth = getBarWidth(barWidthProp, maxBarWidth);
        final requiredWidth = calcRequiredWidth(
          barWidth,
          uniqueXCount,
          innerPadding,
        );
        // VerticalBarChart.tsx:1005-1006.
        if (totalWidth >= requiredWidth) {
          domainMargin = kMinDomainMargin + (totalWidth - requiredWidth) / 2;
        }
      } else if ((mode == 'plotly' || mode == 'histogram') &&
          uniqueXCount > 1) {
        // VerticalBarChart.tsx:1010-1025. The 1 is upstream's own
        // `uniqueX.length > 1`.
        final bandwidth = calcBandwidth(totalWidth, uniqueXCount, innerPadding);
        barWidth = getBarWidth(
          barWidthProp,
          maxBarWidth,
          adjustedValue: bandwidth,
          mode: mode,
        );
        final requiredWidth = calcRequiredWidth(
          barWidth,
          uniqueXCount,
          innerPadding,
        );
        final margin1 = (totalWidth - requiredWidth) / 2;
        // `Number.POSITIVE_INFINITY` at VerticalBarChart.tsx:1015, the seed a
        // `Math.min` fold needs.
        var margin2 = double.infinity;
        if (mode != 'histogram') {
          // +20 is the label breathing room at VerticalBarChart.tsx:1020.
          final step = longestLabelWidth + 20;
          margin2 = (totalWidth - (uniqueXCount - innerPadding) * step) / 2;
        }
        // VerticalBarChart.tsx:1025. The 0 is upstream's own floor.
        domainMargin =
            kMinDomainMargin + math.max(0.0, math.min(margin1, margin2));
      }
    } else {
      if (mode == 'histogram') {
        // VerticalBarChart.tsx:1030-1034. `props.maxBarWidth!` is asserted
        // non-null upstream; the fallback keeps a null caller off a crash.
        domainMargin += math.max(
          0.0,
          (totalWidth -
                  calcRequiredWidth(
                    maxBarWidth ?? kDefaultBarWidth,
                    uniqueXCount,
                    innerPadding,
                  )) /
              2,
        );
      }
      // VerticalBarChart.tsx:1045-1054.
      barWidth = getBarWidth(
        barWidthProp,
        maxBarWidth,
        adjustedValue: calculateAppropriateBarWidth(
          sortedXValues,
          calcTotalWidth(containerWidth, margins, domainMargin),
          innerPadding,
        ),
        mode: mode,
      );
      // parity: VerticalBarChart.tsx:1055-1056 are two identical lines, so the
      // margin grows by a whole bar width, not half of one.
      domainMargin += barWidth / 2;
      domainMargin += barWidth / 2;
    }
    return (barWidth: barWidth, domainMargin: domainMargin);
  }

  /// Ports `_createColors` (`VerticalBarChart.tsx:398-413`).
  ///
  /// Divergence, recorded: upstream builds `scaleLinear<string>()` whose range
  /// is CSS custom-property *strings*, which `d3-color` cannot parse, so d3
  /// falls back to `interpolateString` — an interpolation over the digits
  /// inside the token names, which the browser then resolves. Because Flutter
  /// has no CSS variables, this port resolves the tokens to concrete colours
  /// first and interpolates in sRGB, matching what the browser actually
  /// paints for the single-stop case and every stop boundary.
  static Color colourFor(
    double y, {
    required List<Color> palette,
    required double yMax,
  }) {
    // VerticalBarChart.tsx:399 — an increment of 1 collapses the domain, so a
    // ramp of one entry is constant. The 1 is upstream's own `length <= 1`.
    if (palette.length <= 1) {
      return palette.isEmpty ? const Color(0x00000000) : palette.first;
    }
    final increment = 1 / (palette.length - 1);
    // VerticalBarChart.tsx:407-410.
    final domain = <double>[
      for (var i = 0; i < palette.length; i++) increment * i * yMax,
    ];
    // d3-scale/src/continuous.js clamps nothing, but the range here is a
    // colour list, so beyond either end d3 returns the end stop.
    if (y <= domain.first) {
      return palette.first;
    }
    if (y >= domain.last) {
      return palette.last;
    }
    // 1 is the first interior stop: every y here is above domain.first.
    for (var i = 1; i < domain.length; i++) {
      if (y <= domain[i]) {
        final span = domain[i] - domain[i - 1];
        // The 0 keeps a zero-width segment off a division by zero, which
        // `yMax == 0` produces.
        final t = span == 0 ? 0.0 : (y - domain[i - 1]) / span;
        return Color.lerp(palette[i - 1], palette[i], t)!;
      }
    }
    return palette.last;
  }
}

/// Renders `VerticalBarChartDataPoint`s into the shared cartesian shell.
///
/// Ports `VerticalBarChart.tsx` (1212 lines). The y scale used for the bars is
/// a **magnitude** scale — `scaleLinear().domain([_yMin, _yMax]).range([0,
/// plotH])` (`:584-586`) — not the shell's position scale, so `yBarScale(v)` is
/// a height and every bar top is derived from `containerHeight -
/// margins.bottom`.
class FluentVerticalBarChartDelegate extends FluentCartesianSeriesDelegate {
  /// Creates a delegate over [points].
  const FluentVerticalBarChartDelegate({
    required this.points,
    required this.style,
    required this.colors,
    required this.measurer,
    required this.textStyles,
    required this.selectedLegends,
    this.activeLegend,
    this.activeXDataPoint,
    this.barWidthProp,
    this.maxBarWidth = 24,
    this.useSingleColor = false,
    this.hideLabels = false,
    this.roundCorners = false,
    this.mode,
    this.colorsOverride,
    this.lineLegendText,
    this.xAxisInnerPadding,
    this.xAxisOuterPadding,
    this.xAxisPadding,
    this.xAxisCategoryOrder = FluentAxisCategoryOrder.defaultOrder,
    this.yAxisTickFormat,
  });

  /// The data points, in author order.
  final List<FluentVerticalBarChartDataPoint> points;

  /// The resolved style.
  final FluentVerticalBarChartStyle style;

  /// Resolved chart colours, carrying the high-contrast flattening.
  final FluentChartColors colors;

  /// The chart subtree's single text measurer.
  final FluentChartTextMeasurer measurer;

  /// Resolved chart text styles.
  final FluentChartTextStyles textStyles;

  /// Legend titles selected by the user.
  final List<String> selectedLegends;

  /// Legend title currently hovered.
  final String? activeLegend;

  /// The x value whose line dot is enlarged.
  final Object? activeXDataPoint;

  /// `number | 'default' | 'auto'` (`VerticalBarChart.types.ts`).
  final Object? barWidthProp;

  /// Bar width ceiling — 24 (`VerticalBarChart.tsx:69`).
  final double maxBarWidth;

  /// Whether every bar takes the palette's first colour.
  final bool useSingleColor;

  /// Whether bar labels are suppressed.
  final bool hideLabels;

  /// Whether bars get a 3px corner radius.
  final bool roundCorners;

  /// `'plotly'`, `'histogram'` or null.
  final String? mode;

  /// A caller-supplied ramp that replaces the five default tokens.
  final List<Color>? colorsOverride;

  /// Legend title for the overlaid line, if any.
  final String? lineLegendText;

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

  /// Caller-supplied y tick formatter, reused for bar labels.
  final String Function(double value)? yAxisTickFormat;

  @override
  FluentChartType get chartType => FluentChartType.verticalBarChart;

  @override
  FluentChartAxisType get xAxisType => points.isEmpty
      // parity: VerticalBarChart.tsx:1102-1112 falls back to a category axis.
      ? FluentChartAxisType.category
      : getTypeOfAxis(points.first.x, isXAxis: true);

  @override
  FluentChartAxisType get yAxisType => FluentChartAxisType.numeric;

  /// Resolved inner padding: 2/3 on a category axis, 1/2 otherwise, 0 in
  /// histogram mode (`VerticalBarChart.tsx:1114-1121`).
  double get innerPadding => mode == 'histogram'
      ? 0
      : getScalePadding(
          xAxisInnerPadding,
          xAxisPadding,
          xAxisType == FluentChartAxisType.category ? 2 / 3 : 1 / 2,
        );

  /// Resolved outer padding, default 0 (`:1122`).
  double get outerPadding =>
      getScalePadding(xAxisOuterPadding, xAxisPadding, 0);

  List<Color> get _palette =>
      colorsOverride ?? style.palette!.resolve(<WidgetState>{})!;

  /// The domain the **bars** are measured against.
  ///
  /// `_yMax = Math.max(d3Max(...), props.yMaxValue || 0)` and the mirroring
  /// `_yMin` (`VerticalBarChart.tsx:1124-1125`): both ends are clamped through
  /// zero, so an all-positive series still measures from a zero baseline. This
  /// is **not** [resolveYMinMax], which feeds the y axis and stays the raw data
  /// extent (`utilities.ts:1633-1654`).
  ///
  /// Pinned by Oracle B: `charts-verticalbarchart--vertical-bar-default` has a
  /// data minimum of 10000, and its bars are only reproducible from a domain
  /// starting at 0.
  FluentChartMinMax get barDomain {
    final raw = resolveYMinMax();
    // The 0 is upstream's own `props.yMinValue || 0` / `yMaxValue || 0`.
    return FluentChartMinMax(
      startValue: math.min(raw.startValue, 0),
      endValue: math.max(raw.endValue, 0),
    );
  }

  @override
  FluentChartDomainRange resolveXDomainRange({
    required FluentChartMargins margins,
    required double containerWidth,
    required bool isRtl,
    required double? barWidth,
    required List<Object>? tickValues,
  }) => switch (xAxisType) {
    FluentChartAxisType.numeric => domainRangeOfVerticalNumeric(
      points,
      margins,
      containerWidth,
      isRtl: isRtl,
    ),
    FluentChartAxisType.date =>
      domainRangeOfDateForAreaLineScatterVerticalBarCharts(
        points,
        margins,
        containerWidth,
        isRtl: isRtl,
        tickValues: tickValues?.whereType<DateTime>().toList() ?? _noDates,
        chartType: FluentChartType.verticalBarChart,
      ),
    FluentChartAxisType.category => domainRangeOfXStringAxis(
      margins,
      containerWidth,
      isRtl: isRtl,
    ),
  };

  static const List<DateTime> _noDates = <DateTime>[];

  @override
  FluentChartMinMax resolveYMinMax({bool useSecondaryYScale = false}) =>
      findVerticalNumericMinMaxOfY(
        points,
        useSecondaryYScale: useSecondaryYScale,
      );

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
    chartType: FluentChartType.verticalBarChart,
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
    chartType: FluentChartType.verticalBarChart,
  );

  @override
  List<String>? get datasetForXAxisDomain =>
      xAxisType == FluentChartAxisType.category ? orderedCategories : null;

  /// The band domain, ordered per [xAxisCategoryOrder]
  /// (`VerticalBarChart.tsx:1128-1140`).
  List<String> get orderedCategories {
    if (xAxisCategoryOrder != FluentAxisCategoryOrder.defaultOrder) {
      return sortAxisCategories(<String, List<double>>{
        for (final point in points)
          if (point.x is String) '${point.x}': <double>[point.y],
      }, xAxisCategoryOrder);
    }
    return <String>{
      for (final point in points) '${point.x}',
    }.toList(growable: false);
  }

  /// Resolves every bar for [context].
  List<FluentVerticalBarRect> barsFor(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) {
    if (points.isEmpty) {
      return const <FluentVerticalBarRect>[];
    }
    final minMax = barDomain;
    final yBarScale = _magnitudeScale(layout, minMax);
    // `_yMax < 0 ? _yMax : 0` (VerticalBarChart.tsx:638).
    final yReference = minMax.endValue < 0 ? minMax.endValue : 0.0;
    final floor = FluentVerticalBarChartGeometry.minBarHeight(
      yMin: minMax.startValue,
      yMax: minMax.endValue,
      yReferencePoint: yReference,
      yBarScale: yBarScale,
    );
    final baseline =
        layout.size.height -
        (layout.margins.bottom ?? 0) -
        yBarScale(yReference)!;
    final isBand = xAxisType == FluentChartAxisType.category;
    // VerticalBarChart.tsx:716 re-derives the width from the live bandwidth;
    // the numeric and date creators keep the one `_getDomainMargins` solved.
    final barWidth = isBand
        ? getBarWidth(
            barWidthProp,
            maxBarWidth,
            adjustedValue: context.xScale.bandwidth,
            mode: mode,
          )
        : getBarWidth(barWidthProp, maxBarWidth, mode: mode);
    final dim = style.barOpacity!.resolve(<WidgetState>{WidgetState.disabled})!;
    final full = style.barOpacity!.resolve(<WidgetState>{})!;
    final gapAbove = style.barLabelGapAbove!.resolve(<WidgetState>{})!;
    final gapBelow = style.barLabelGapBelow!.resolve(<WidgetState>{})!;

    final out = <FluentVerticalBarRect>[];
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      var height = yBarScale(point.y)! - yBarScale(yReference)!;
      final isNegative = height < 0;
      height = height.abs();
      if (height == 0) {
        // parity: VerticalBarChart.tsx:648-651 renders an empty fragment, so
        // the bar is absent from the DOM entirely, not merely zero-height.
        continue;
      }
      final adjusted = height <= floor ? floor : height;
      final top = isNegative ? baseline : baseline - adjusted;
      final left = isBand
          ? context.xScale(point.x)! +
                0.5 * (context.xScale.bandwidth - barWidth)
          : context.xScale(point.x)! - barWidth / 2;
      final highlighted =
          isLegendHighlightedMulti(
            point.legend ?? '',
            selectedLegends: selectedLegends,
            activeLegend: activeLegend,
          ) ||
          // `_noLegendHighlighted` (`VerticalBarChart.tsx:915-917`), whose
          // activeLegend arm is an emptiness test rather than a null test.
          (selectedLegends.isEmpty &&
              (activeLegend == null || activeLegend!.isEmpty));
      out.add(
        FluentVerticalBarRect(
          rect: Rect.fromLTWH(left, top, barWidth, adjusted),
          colour: colors.flattenMark(
            point.color != null && !useSingleColor
                ? point.color!
                : useSingleColor
                ? (colorsOverride?.firstOrNull ??
                      style.singleColor!.resolve(<WidgetState>{})!)
                : FluentVerticalBarChartGeometry.colourFor(
                    point.y,
                    palette: _palette,
                    yMax: minMax.endValue,
                  ),
          ),
          opacity: highlighted ? full : dim,
          index: i,
          isNegative: isNegative,
          // `yPoint` is `containerHeight - bottom - (isNegative ?
          // -adjustedBarHeight : adjustedBarHeight) - yBarScale(ref)`
          // (`VerticalBarChart.tsx:658-663`), which for a negative bar is the
          // rect's BOTTOM, not its top; `:965` then offsets it by 12.
          labelAnchor: Offset(
            left + barWidth / 2,
            isNegative ? top + adjusted + gapBelow : top - gapAbove,
          ),
        ),
      );
    }
    return out;
  }

  /// Whether [bar]'s label is painted.
  ///
  /// Ports `_renderBarLabel`'s guard (`VerticalBarChart.tsx:950`): suppressed
  /// when labels are hidden, when the bar is under 16px wide, or when another
  /// legend owns the highlight.
  bool shouldPaintLabel(FluentVerticalBarRect bar) =>
      !hideLabels &&
      bar.rect.width >= style.minBarLabelWidth!.resolve(<WidgetState>{})! &&
      bar.opacity == style.barOpacity!.resolve(<WidgetState>{})!;

  /// The text drawn over [bar] (`VerticalBarChart.tsx:955-960`).
  String labelFor(FluentVerticalBarRect bar) {
    final point = points[bar.index];
    return point.barLabel ??
        (yAxisTickFormat?.call(point.y) ?? formatScientificLimitWidth(point.y));
  }

  List<FluentVerticalBarChartDataPoint> get _withLine => points
      .where((FluentVerticalBarChartDataPoint p) => p.lineData != null)
      .toList(growable: false);

  /// The overlaid line's path, or null when no point carries `lineData`.
  Path? linePathFor(FluentCartesianChildContext context) {
    final withLine = _withLine;
    if (withLine.isEmpty) {
      return null;
    }
    final sink = d3.UiPathSink();
    // Default curveLinear — VerticalBarChart never sets a curve (`:182`).
    d3.Line<FluentVerticalBarChartDataPoint>(
      x: (FluentVerticalBarChartDataPoint p, int i, _) => _lineX(context, p),
      y: (FluentVerticalBarChartDataPoint p, int i, _) => _lineY(context, p),
    )(withLine, sink);
    return sink.path;
  }

  /// The overlaid line's dot centres.
  List<Offset> lineDotsFor(FluentCartesianChildContext context) => <Offset>[
    for (final point in _withLine)
      Offset(_lineX(context, point), _lineY(context, point)),
  ];

  double _lineX(
    FluentCartesianChildContext context,
    FluentVerticalBarChartDataPoint p,
  ) => xAxisType == FluentChartAxisType.category
      // `xScale(d.x) + 0.5 * xScale.bandwidth()` (`:184`).
      ? context.xScale(p.x)! + 0.5 * context.xScale.bandwidth
      : context.xScale(p.x)!;

  double _lineY(
    FluentCartesianChildContext context,
    FluentVerticalBarChartDataPoint p,
  ) => (p.lineData!.useSecondaryYScale && context.yScaleSecondary != null
      ? context.yScaleSecondary!(p.lineData!.y)
      : context.yScalePrimary(p.lineData!.y))!;

  Scale _magnitudeScale(
    FluentCartesianLayout layout,
    FluentChartMinMax minMax,
  ) => scaleLinear()
    ..domainOf(<double>[minMax.startValue, minMax.endValue])
    ..rangeOf(<double>[
      0,
      layout.size.height -
          (layout.margins.bottom ?? 0) -
          (layout.margins.top ?? 0),
    ]);

  @override
  void paintSeries(
    Canvas canvas,
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
    FluentChartColors colours,
  ) {
    // 0 is upstream's own `rx={props.roundCorners ? 3 : 0}` (`:684`).
    final radius = roundCorners
        ? style.barCornerRadius!.resolve(<WidgetState>{})!
        : 0.0;
    final labelStyle = style.barLabelStyle!.resolve(<WidgetState>{})!;
    for (final bar in barsFor(context, layout)) {
      final paint = Paint()..color = bar.colour.withValues(alpha: bar.opacity);
      if (radius > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(bar.rect, Radius.circular(radius)),
          paint,
        );
      } else {
        canvas.drawRect(bar.rect, paint);
      }
      if (!shouldPaintLabel(bar)) {
        continue;
      }
      final text = labelFor(bar);
      // `text-anchor: middle` on an alphabetic baseline (`:963-969`).
      final painter = measurer.layoutPainter(text, labelStyle);
      final metrics = measurer.measure(text, labelStyle);
      painter.paint(
        canvas,
        Offset(
          bar.labelAnchor.dx - metrics.width / 2,
          bar.labelAnchor.dy - metrics.ascent,
        ),
      );
      painter.dispose();
    }
    _paintLine(canvas, context);
  }

  void _paintLine(Canvas canvas, FluentCartesianChildContext context) {
    final path = linePathFor(context);
    if (path == null) {
      return;
    }
    final lineHighlighted =
        lineLegendText == null ||
        isLegendHighlightedMulti(
          lineLegendText!,
          selectedLegends: selectedLegends,
          activeLegend: activeLegend,
        ) ||
        (selectedLegends.isEmpty &&
            (activeLegend == null || activeLegend!.isEmpty));
    final opacity = lineHighlighted
        ? style.barOpacity!.resolve(<WidgetState>{})!
        : style.barOpacity!.resolve(<WidgetState>{WidgetState.disabled})!;
    final strokeWidth = style.lineStrokeWidth!.resolve(<WidgetState>{})!;
    final rawLineColour = style.lineColor!.resolve(<WidgetState>{})!;
    // The line is a series mark, so its stroke flattens to the system
    // foreground under forced colours (design spec section 5.3).
    final lineColour = colors.flattenMark(rawLineColour);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        // strokeWidth 3, strokeLinecap "square" (`VerticalBarChart.tsx:213`).
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.square
        ..color = lineColour.withValues(alpha: opacity),
    );
    final dotFill = style.lineDotFillColor!.resolve(<WidgetState>{})!;
    // The dot's halo is what separates it from the line beneath it, so it
    // takes the stroke flattening rather than the mark one.
    final haloColour = colors.flattenMarkStroke(rawLineColour);
    final withLine = _withLine;
    final dots = lineDotsFor(context);
    for (var i = 0; i < dots.length; i++) {
      final active = activeXDataPoint == withLine[i].x;
      final r = style.lineDotRadius!.resolve(
        active ? <WidgetState>{WidgetState.hovered} : <WidgetState>{},
      )!;
      // 0 is `_getCircleVisibilityAndRadius`'s hidden radius (`:296`).
      if (r == 0) {
        continue;
      }
      canvas
        ..drawCircle(dots[i], r, Paint()..color = dotFill)
        ..drawCircle(
          dots[i],
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..color = haloColour.withValues(alpha: opacity),
        );
    }
  }

  @override
  List<FluentChartHitRegion> buildHitRegions(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) => <FluentChartHitRegion>[
    for (final bar in barsFor(context, layout))
      FluentChartHitRegion(
        bounds: bar.rect,
        index: bar.index,
        legend: points[bar.index].legend ?? '',
        popoverData: FluentChartPopoverData(
          xValue:
              points[bar.index].xAxisCalloutData ?? '${points[bar.index].x}',
          legend: points[bar.index].legend,
          color: bar.colour,
          yValue:
              points[bar.index].yAxisCalloutData ?? '${points[bar.index].y}',
        ),
        semanticsLabel: semanticsLabelFor(points[bar.index]),
      ),
  ];

  /// `_getAriaLabel` (`VerticalBarChart.tsx:922-940`).
  String semanticsLabelFor(FluentVerticalBarChartDataPoint p) {
    final label = p.callOutSemantics?.label;
    if (label != null) {
      return label;
    }
    final buffer = StringBuffer('${p.x}. ');
    if (p.legend != null) {
      buffer.write('${p.legend}, ');
    }
    buffer.write('${p.y}.');
    final lineData = p.lineData;
    if (lineData != null) {
      // The literal 'Line' fallback at VerticalBarChart.tsx:931.
      buffer.write(
        ' ${lineLegendText ?? 'Line'}, '
        '${lineData.yAxisCalloutData ?? lineData.y}.',
      );
    }
    return buffer.toString();
  }
}
