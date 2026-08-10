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
import 'internal/d3/curves.dart' as d3;
import 'internal/d3/path_sink.dart' as d3;
import 'internal/d3/shape_line_area.dart' as d3;
import 'internal/d3/stable_sort.dart';
import 'internal/data_viz_palette.dart';
import 'line_chart_style.dart';
import 'model/cartesian_series.dart';
import 'model/chart_common.dart';
import 'model/chart_value.dart';

/// The eight LineChart marker shapes.
///
/// Ports `_getPointPath` (`LineChart.tsx:82-137`) verbatim, including all
/// twenty-four hand-tuned coefficients. The shapes are authored about the
/// centre `(x, y)` with a nominal box width `w`; the three wide shapes are
/// narrowed by their `widthRatio` at the call site (`LineChart.tsx:494`), not
/// here.
abstract final class FluentLineMarkerPainter {
  /// Box width of an active point (`PointSize.hoverSize`,
  /// `LineChart.tsx:64`).
  static const double kHoverSize = 11;

  /// Box width of an inactive point (`PointSize.invisibleSize`,
  /// `LineChart.tsx:65`).
  static const double kInvisibleSize = 1;

  /// "A shape must be 2.5 times bigger than the stroke width"
  /// (`LineChart.tsx:73`).
  static const double kPathMultiplySize = 2.5;

  /// The fallback stroke width (`DEFAULT_LINE_STROKE_SIZE`,
  /// `LineChart.tsx:71`).
  static const double kDefaultLineStrokeSize = 4;

  /// Builds the path for [shapeIndex] (0 circle … 7 octagon) centred on
  /// [centre] with box width [w].
  static Path pathFor(int shapeIndex, Offset centre, double w) {
    final x = centre.dx;
    final y = centre.dy;
    final p = Path();
    switch (shapeIndex) {
      case 0:
        // Two 180° arcs from x-w/2 to x+w/2 (`LineChart.tsx:85-88`). The chord
        // equals the diameter, so upstream's large-arc flag is degenerate and
        // only the sweep direction distinguishes the two halves.
        p
          ..moveTo(x - w / 2, y)
          ..arcToPoint(
            Offset(x + w / 2, y),
            radius: Radius.circular(w / 2),
            clockwise: false,
          )
          ..moveTo(x - w / 2, y)
          ..arcToPoint(Offset(x + w / 2, y), radius: Radius.circular(w / 2));
      case 1:
        // LineChart.tsx:91-95.
        p
          ..moveTo(x - w / 2, y - w / 2)
          ..lineTo(x + w / 2, y - w / 2)
          ..lineTo(x + w / 2, y + w / 2)
          ..lineTo(x - w / 2, y + w / 2)
          ..close();
      case 2:
        // 0.2886 and 0.5774 are the incentre offsets of an equilateral
        // triangle of side w (`LineChart.tsx:97-99`). Upstream's second segment
        // is an `H` command, which is a horizontal `lineTo`.
        p
          ..moveTo(x - w / 2, y - 0.2886 * w)
          ..lineTo(x + w / 2, y - 0.2886 * w)
          ..lineTo(x, y + 0.5774 * w)
          ..close();
      case 3:
        // LineChart.tsx:101-105.
        p
          ..moveTo(x, y - w / 2)
          ..lineTo(x + w / 2, y)
          ..lineTo(x, y + w / 2)
          ..lineTo(x - w / 2, y)
          ..close();
      case 4:
        // LineChart.tsx:107-109.
        p
          ..moveTo(x, y - 0.5774 * w)
          ..lineTo(x + w / 2, y + 0.2886 * w)
          ..lineTo(x - w / 2, y + 0.2886 * w)
          ..close();
      case 5:
        // 0.866 == sin(60°) (`LineChart.tsx:111-117`).
        p
          ..moveTo(x - 0.5 * w, y - 0.866 * w)
          ..lineTo(x + 0.5 * w, y - 0.866 * w)
          ..lineTo(x + w, y)
          ..lineTo(x + 0.5 * w, y + 0.866 * w)
          ..lineTo(x - 0.5 * w, y + 0.866 * w)
          ..lineTo(x - w, y)
          ..close();
      case 6:
        // LineChart.tsx:119-124.
        p
          ..moveTo(x, y - 0.851 * w)
          ..lineTo(x + 0.6884 * w, y - 0.2633 * w)
          ..lineTo(x + 0.5001 * w, y + 0.6884 * w)
          ..lineTo(x - 0.5001 * w, y + 0.6884 * w)
          ..lineTo(x - 0.6884 * w, y - 0.2633 * w)
          ..close();
      case 7:
        // 1.207 == (1 + sqrt(2)) / 2 (`LineChart.tsx:126-133`).
        p
          ..moveTo(x - 0.5001 * w, y - 1.207 * w)
          ..lineTo(x + 0.5001 * w, y - 1.207 * w)
          ..lineTo(x + 1.207 * w, y - 0.5001 * w)
          ..lineTo(x + 1.207 * w, y + 0.5001 * w)
          ..lineTo(x + 0.5001 * w, y + 1.207 * w)
          ..lineTo(x - 0.5001 * w, y + 1.207 * w)
          ..lineTo(x - 1.207 * w, y + 0.5001 * w)
          ..lineTo(x - 1.207 * w, y - 0.5001 * w)
          ..close();
      default:
        throw ArgumentError.value(shapeIndex, 'shapeIndex', 'must be 0..7');
    }
    return p;
  }

  /// Ports `_getBoxWidthOfShape` (`LineChart.tsx:463-480`).
  ///
  /// Note the asymmetry: the first/last exemption only exists inside the
  /// `allowMultipleShapesForPoints` branch (`LineChart.tsx:465-472`), so an
  /// ordinary line's points are 1px boxes until hovered.
  ///
  /// [isActive] is upstream's `activePoint === pointId`, [isFirstOrLast] its
  /// `pointIndex === 1 || isLastPoint`.
  static double boxWidthFor({
    required bool allowMultipleShapes,
    required bool isActive,
    required bool isFirstOrLast,
    required double strokeWidth,
  }) {
    if (isActive) {
      return kHoverSize;
    }
    if (allowMultipleShapes && isFirstOrLast) {
      return strokeWidth * kPathMultiplySize;
    }
    return kInvisibleSize;
  }
}

/// Applies a [FluentLineChartStyle] to every line chart below it.
class FluentLineChartTheme extends InheritedTheme {
  /// Applies [style] to every line chart in `child`.
  const FluentLineChartTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the derived defaults.
  final FluentLineChartStyle style;

  /// The nearest line chart style, or null.
  static FluentLineChartStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentLineChartTheme>()?.style;

  @override
  bool updateShouldNotify(FluentLineChartTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentLineChartTheme(style: style, child: child);
}

/// One drawn line segment in engine A.
@immutable
class FluentLineSegment {
  /// Creates a segment.
  const FluentLineSegment({
    required this.start,
    required this.end,
    required this.seriesIndex,
    required this.pointIndex,
    required this.colour,
    required this.opacity,
    required this.strokeWidth,
    this.dashPattern,
    this.borderWidth,
    this.borderColour,
  });

  /// Segment start in plot coordinates.
  final Offset start;

  /// Segment end in plot coordinates.
  final Offset end;

  /// Index of the owning series in author order.
  final int seriesIndex;

  /// Index of the segment's *end* point inside its series.
  final int pointIndex;

  /// Resolved series colour, already flattened for high contrast.
  final Color colour;

  /// 1 when the series is selected (`LineChart.tsx:1286`), 0.1 otherwise
  /// (`:1306`).
  final double opacity;

  /// Stroke width: `lineOptions.strokeWidth`, then the chart's, then 4
  /// (`LineChart.tsx:836`).
  final double strokeWidth;

  /// Parsed `strokeDasharray`, or null.
  final List<double>? dashPattern;

  /// Total width of the border stroke drawn underneath, or null when
  /// `lineBorderWidth` is zero (`LineChart.tsx:1222-1232`).
  final double? borderWidth;

  /// Border colour: `lineBorderColor` or `colorNeutralBackground1`
  /// (`LineChart.tsx:1233`), already flattened for high contrast.
  final Color? borderColour;
}

/// One x range of a colour-fill bar.
@immutable
class FluentColorFillBarRange {
  /// Creates a range.
  const FluentColorFillBarRange({required this.startX, required this.endX});

  /// Range start on the x axis, `num` or `DateTime`.
  final Object startX;

  /// Range end on the x axis, `num` or `DateTime`.
  final Object endX;
}

/// A shaded band drawn behind the lines.
///
/// Ports `ColorFillBarsProps` (`LineChart.types.ts`). Each bar contributes its
/// own legend entry, which participates in the same single-select highlight
/// model as the lines.
@immutable
class FluentColorFillBar {
  /// Creates a colour-fill bar.
  const FluentColorFillBar({
    required this.legend,
    required this.color,
    required this.data,
    this.applyPattern = false,
  });

  /// Legend title.
  final String legend;

  /// Fill colour.
  final Color color;

  /// One or more x ranges.
  final List<FluentColorFillBarRange> data;

  /// Whether the fill is a diagonal stripe pattern instead of a flat colour.
  final bool applyPattern;
}

/// Paints one 16×16 tile of the colour-fill-bar stripe pattern.
///
/// Ports `_getStripePattern` (`LineChart.tsx:1415-1430`): three diagonals at
/// 45°, drawn in `userSpaceOnUse` units so the pattern does not scale with the
/// rect it fills. The first and last diagonals overhang the tile so that the
/// stripes meet across a tile boundary; a caller therefore clips to the rect it
/// is tiling.
class FluentChartStripeTilePainter extends CustomPainter {
  /// Creates a tile painter.
  FluentChartStripeTilePainter({
    required this.color,
    required this.strokeWidth,
  });

  /// Stripe colour.
  final Color color;

  /// Stripe width — 1.25 (`LineChart.tsx:1427`).
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    // `M-4,4 l8,-8 M0,16 l16,-16 M12,20 l8,-8` (`LineChart.tsx:1418`), which is
    // three `moveTo` plus relative `lineTo` pairs.
    canvas
      ..drawLine(const Offset(-4, 4), const Offset(4, -4), paint)
      ..drawLine(const Offset(0, 16), const Offset(16, 0), paint)
      ..drawLine(const Offset(12, 20), const Offset(20, 12), paint);
  }

  @override
  bool shouldRepaint(FluentChartStripeTilePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Renders line series into the shared cartesian shell.
///
/// Ports `LineChart.tsx` (1972 lines). Two engines share this class:
/// **engine A** emits one `<line>` per adjacent pair (the default,
/// `:816-1313`), **engine B** emits a single `d3.line` path (`:671-815`)
/// whenever `optimizeLargeData` is set or any series names a curve. They differ
/// in more than shape — engine A dims markers to 0.01 (`:909`) and lines to 0.1
/// (`:1306`), engine B dims markers to 0.1 (`:804`) and pins the marker stroke
/// to 1 (`:803`) — so they are kept distinct rather than unified.
class FluentLineChartDelegate extends FluentCartesianSeriesDelegate {
  /// Creates a delegate.
  const FluentLineChartDelegate({
    required this.series,
    required this.style,
    required this.colors,
    required this.measurer,
    required this.textStyles,
    required this.selectedLegend,
    this.activeLegend,
    this.activePointId,
    this.nearestPoint,
    this.optimizeLargeData = false,
    this.allowMultipleShapesForPoints = false,
    this.strokeWidthOverride,
    this.xScaleType,
    this.yScaleType,
    this.xMinValue,
    this.xMaxValue,
    this.yMinValue = 0,
    this.colorFillBars = const <FluentColorFillBar>[],
  });

  /// The input series.
  final List<FluentLineChartSeries> series;

  /// The resolved style.
  final FluentLineChartStyle style;

  /// Resolved chart colours.
  final FluentChartColors colors;

  /// The chart subtree's single text measurer.
  final FluentChartTextMeasurer measurer;

  /// Resolved chart text styles.
  final FluentChartTextStyles textStyles;

  /// LineChart is single-select: it tracks one legend title, empty for none
  /// (`LineChart.tsx:186`).
  final String selectedLegend;

  /// Legend title currently hovered.
  final String? activeLegend;

  /// Identifier of the active point, `"<series>_<point>"`.
  final String? activePointId;

  /// `(seriesIndex, pointIndex)` nearest the pointer under engine B.
  final (int, int)? nearestPoint;

  /// Whether to use the single-path engine regardless of curve.
  final bool optimizeLargeData;

  /// Whether points cycle through the eight shapes (`LineChart.types.ts:71`).
  final bool allowMultipleShapesForPoints;

  /// `props.strokeWidth`, which falls back to the style's 4
  /// (`LineChart.tsx:836`).
  final double? strokeWidthOverride;

  /// Optional log scaling on x.
  final FluentAxisScaleType? xScaleType;

  /// Optional log scaling on y.
  ///
  /// `// parity:` upstream reads `props.secondaryYScaleType` for the secondary
  /// axis (`LineChart.tsx:320`); the ported props carry one y scale type, so
  /// both axes use this.
  final FluentAxisScaleType? yScaleType;

  /// User-supplied x domain floor.
  final double? xMinValue;

  /// User-supplied x domain ceiling.
  final double? xMaxValue;

  /// User-supplied y floor, used as the colour-fill-bar baseline.
  final double yMinValue;

  /// The shaded bands drawn behind the lines (`props.colorFillBars`).
  final List<FluentColorFillBar> colorFillBars;

  @override
  FluentChartType get chartType => FluentChartType.lineChart;

  @override
  FluentChartAxisType get xAxisType => getXAxisType(series)
      ? FluentChartAxisType.date
      : FluentChartAxisType.numeric;

  @override
  FluentChartAxisType get yAxisType => FluentChartAxisType.numeric;

  /// Whether the single-path engine is in force (`LineChart.tsx:671`).
  ///
  /// `// parity:` upstream tests this per series, together with
  /// `data.length > 1`; the port is chart-wide, because the two engines dim
  /// differently and a chart that mixed them would dim two of its lines
  /// unlike the rest.
  bool get usesSinglePathEngine =>
      optimizeLargeData ||
      series.any((series) => series.lineOptions?.curve != null);

  /// Whether any series asks for markers (`LineChart.tsx:271-272`).
  bool get hasMarkersMode =>
      series.any((series) => series.lineOptions?.mode?.markers ?? false);

  /// Ports `_legendHighlighted` (`LineChart.tsx:1817-1819`) — LineChart is the
  /// single-select model B, not the multi-select model A the bar charts use.
  bool highlighted(String legend) => isLegendHighlightedSingle(
    legend,
    selectedLegend: selectedLegend,
    activeLegend: activeLegend,
  );

  bool get _noneHighlighted =>
      selectedLegend.isEmpty && (activeLegend == null || activeLegend!.isEmpty);

  /// Marker opacity under engine A — **0.01**, not 0.1 (`LineChart.tsx:909`).
  double markerOpacityFor(String legend) =>
      highlighted(legend) || _noneHighlighted
      ? 1
      : style.pointOpacity!.resolve(<WidgetState>{WidgetState.disabled})!;

  /// Marker stroke width under engine B — a flat 1 (`LineChart.tsx:803`).
  double get markerStrokeWidthForEngineB =>
      style.markerStrokeWidthEngineB!.resolve(<WidgetState>{})!;

  /// Marker opacity under engine B — 0.1, unlike engine A's 0.01
  /// (`LineChart.tsx:804`).
  ///
  /// Engine B has no marker opacity of its own: it reuses the line's, which is
  /// why [FluentLineChartStyle.lineOpacity] and not `pointOpacity` is read
  /// here.
  double markerOpacityForEngineB(String legend) =>
      highlighted(legend) || _noneHighlighted
      ? 1
      : style.lineOpacity!.resolve(<WidgetState>{WidgetState.disabled})!;

  /// The engine-B path for [seriesIndex], or null when the series is too short.
  ///
  /// `defined` is a live parameter here: `isPlottable` breaks the path into
  /// sub-paths at every NaN rather than drawing straight through the gap
  /// (`LineChart.tsx:678`).
  Path? singlePathFor(int seriesIndex, FluentCartesianChildContext context) {
    final line = series[seriesIndex];
    final data = line.data.cast<FluentLineChartDataPoint>();
    // `:670` — the path branch is gated on data.length > 1.
    if (data.length <= 1) {
      return null;
    }
    final yScale = line.useSecondaryYScale && context.yScaleSecondary != null
        ? context.yScaleSecondary!
        : context.yScalePrimary;
    final sink = d3.UiPathSink();
    d3.Line<FluentLineChartDataPoint>(
      // A non-plottable coordinate is dropped by `defined` before it is ever
      // drawn, so the NaN these fall back to never reaches the sink.
      x: (FluentLineChartDataPoint d, _, _) =>
          context.xScale(d.x) ?? double.nan,
      y: (FluentLineChartDataPoint d, _, _) => yScale(d.y) ?? double.nan,
      defined: (FluentLineChartDataPoint d, _, _) =>
          isPlottable(context.xScale(d.x), yScale(d.y)),
      curve: getCurveFactory(line.lineOptions?.curve, d3.curveLinear),
    )(data, sink);
    return sink.path;
  }

  /// Resolves the colour-fill bar rects.
  ///
  /// Ports `_createColorFillBars` (`LineChart.tsx:1372-1413`).
  List<({Rect rect, Color colour, double opacity, bool patterned})>
  colorFillBarRectsFor(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) {
    // FILL_Y_PADDING (`LineChart.tsx:1381`).
    final pad = style.fillBarYPadding!.resolve(<WidgetState>{})!;
    final domainTop = context.yScalePrimary.domain.last;
    final yMax = domainTop is num ? domainTop.toDouble() : 0.0;
    // `:1404` — the band starts one padding above the top of the y extent.
    final top = context.yScalePrimary(yMax)! - pad;
    // `:1406` — and runs down to `props.yMinValue || 0`.
    final bottom = context.yScalePrimary(yMinValue)!;
    final out = <({Rect rect, Color colour, double opacity, bool patterned})>[];
    for (final bar in colorFillBars) {
      // `:1828-1830` — a patterned bar is opaque, a plain one 0.4; `:1396-1398`
      // overrides both with 0.1 once another legend is highlighted.
      final opacity = highlighted(bar.legend) || _noneHighlighted
          ? (bar.applyPattern
                ? kFluentLineFillBarPatternedOpacity
                : style.fillBarOpacity!.resolve(<WidgetState>{
                    WidgetState.selected,
                  })!)
          : style.fillBarOpacity!.resolve(<WidgetState>{WidgetState.disabled})!;
      for (final range in bar.data) {
        final x1 = context.xScale(range.startX)!;
        final x2 = context.xScale(range.endX)!;
        out.add((
          // `:1403` — RTL anchors the rect on endX instead.
          rect: Rect.fromLTWH(
            layout.isRtl ? x2 : x1,
            top,
            (x2 - x1).abs(),
            bottom - top,
          ),
          colour: colors.flattenMark(bar.color),
          opacity: opacity,
          patterned: bar.applyPattern,
        ));
      }
    }
    return out;
  }

  /// Whether point [pointIndex] of [seriesIndex] falls inside a declared gap.
  ///
  /// Ports `_checkInGap` (`LineChart.tsx:1432-1444`): the gap list is sorted
  /// ascending by `startIndex` first (`:667`), and the test is strictly
  /// `index > startIndex && index <= endIndex`, so the gap's own start point is
  /// still connected to what precedes it. Upstream walks the sorted list with a
  /// cursor that only ever advances, which for a sorted list of disjoint gaps
  /// answers exactly as this whole-list scan does.
  bool isInGap(int seriesIndex, int pointIndex) {
    final gaps = series[seriesIndex].gaps;
    if (gaps == null || gaps.isEmpty) {
      return false;
    }
    final sorted = stableSort<FluentLineChartGap>(
      gaps,
      (a, b) => a.startIndex.compareTo(b.startIndex),
    );
    for (final gap in sorted) {
      if (pointIndex > gap.startIndex && pointIndex <= gap.endIndex) {
        return true;
      }
    }
    return false;
  }

  /// Resolves every engine-A segment for [context].
  ///
  /// Series are walked from last to first so series 0 paints on top
  /// (`LineChart.tsx:535`), which means the returned list starts with the
  /// **last** series.
  List<FluentLineSegment> segmentsFor(FluentCartesianChildContext context) {
    if (usesSinglePathEngine) {
      return const <FluentLineSegment>[];
    }
    final dim = style.lineOpacity!.resolve(<WidgetState>{
      WidgetState.disabled,
    })!;
    final out = <FluentLineSegment>[];
    for (var i = series.length - 1; i >= 0; i--) {
      final line = series[i];
      // `!_hasMarkersMode || mode.includes('lines')` (`:1213`).
      if (hasMarkersMode && !(line.lineOptions?.mode?.lines ?? false)) {
        continue;
      }
      final data = line.data.cast<FluentLineChartDataPoint>();
      final yScale = line.useSecondaryYScale && context.yScaleSecondary != null
          ? context.yScaleSecondary!
          : context.yScalePrimary;
      final colour = colors.flattenMark(
        line.color ?? FluentDataVizPalette.next(i),
      );
      final strokeWidth =
          line.lineOptions?.strokeWidth ??
          strokeWidthOverride ??
          style.strokeWidth!.resolve(<WidgetState>{})!;
      final lineBorderWidth = line.lineOptions?.lineBorderWidth ?? 0;
      // `:1222` — a zero border is no border at all, not a hairline.
      final borderWidth = lineBorderWidth > 0
          ? strokeWidth + lineBorderWidth
          : null;
      final borderColour = borderWidth == null
          ? null
          // The halo flattens to the canvas colour so it stays distinct from
          // the line it sits behind (`:1233`).
          : colors.flattenMarkStroke(
              line.lineOptions?.lineBorderColor ??
                  style.lineBorderColor!.resolve(<WidgetState>{})!,
            );
      final dashPattern = _parseDashArray(line.lineOptions?.strokeDasharray);
      final opacity = highlighted(line.legend) || _noneHighlighted ? 1.0 : dim;
      // `:817` — j is the index of the segment's END point.
      for (var j = 1; j < data.length; j++) {
        if (isInGap(i, j)) {
          continue;
        }
        final x1 = context.xScale(data[j - 1].x);
        final y1 = yScale(data[j - 1].y);
        final x2 = context.xScale(data[j].x);
        final y2 = yScale(data[j].y);
        // `:1210-1212` — both endpoints, or no segment.
        if (!isPlottable(x1, y1) || !isPlottable(x2, y2)) {
          continue;
        }
        out.add(
          FluentLineSegment(
            start: Offset(x1!, y1!),
            end: Offset(x2!, y2!),
            seriesIndex: i,
            pointIndex: j,
            colour: colour,
            opacity: opacity,
            strokeWidth: strokeWidth,
            dashPattern: dashPattern,
            borderWidth: borderWidth,
            borderColour: borderColour,
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
    // LineChart.tsx:230-239.
    FluentChartAxisType.numeric => domainRangeOfNumericForAreaLineScatterCharts(
      series,
      margins,
      containerWidth,
      isRtl: isRtl,
      scaleType: xScaleType,
      hasMarkersMode: hasMarkersMode,
      xMinVal: xMinValue,
      xMaxVal: xMaxValue,
    ),
    // LineChart.tsx:241-250.
    FluentChartAxisType.date =>
      domainRangeOfDateForAreaLineScatterVerticalBarCharts(
        series,
        margins,
        containerWidth,
        isRtl: isRtl,
        chartType: FluentChartType.lineChart,
        tickValues: tickValues?.whereType<DateTime>().toList() ?? <DateTime>[],
        hasMarkersMode: hasMarkersMode,
      ),
    // LineChart.tsx:252 — a category x axis is all zeroes, because LineChart
    // never declares one.
    FluentChartAxisType.category => const FluentChartDomainRange(
      dStartValue: 0,
      dEndValue: 0,
      rStartValue: 0,
      rEndValue: 0,
    ),
  };

  /// Ports `_getNumericMinMaxOfY` (`LineChart.tsx:311-334`): the marker pad is
  /// applied only when some series is in markers mode.
  @override
  FluentChartMinMax resolveYMinMax({bool useSecondaryYScale = false}) {
    final raw = findNumericMinMaxOfY(
      series,
      useSecondaryYScale: useSecondaryYScale,
      scaleType: yScaleType,
    );
    if (!hasMarkersMode) {
      return raw;
    }
    final pad = getDomainPaddingForMarkers(
      raw.startValue,
      raw.endValue,
      scaleType: yScaleType,
    );
    return FluentChartMinMax(
      startValue: raw.startValue - pad.start,
      endValue: raw.endValue + pad.end,
    );
  }

  /// `createYAxis={createNumericYAxis}` (`LineChart.tsx:1917`).
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
    chartType: FluentChartType.lineChart,
    useSecondaryYScale: useSecondaryYScale,
    scaleType: yScaleType,
  );

  /// `createStringYAxis={createStringYAxis}` (`LineChart.tsx:1924`).
  ///
  /// Unreachable while [yAxisType] is numeric, which it always is; the shell
  /// only routes here for a category y axis.
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
    chartType: FluentChartType.lineChart,
  );

  @override
  bool get isIntegralDataset => !series.any(
    (series) => series.data.cast<FluentLineChartDataPoint>().any(
      (point) => point.y % 1 != 0,
    ),
  );

  @override
  void paintSeries(
    Canvas canvas,
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
    FluentChartColors colors,
  ) {
    // `:1363-1364` groups per series and renders every border of that series
    // before any of its lines, so a halo never covers its own neighbour.
    final grouped = <int, List<FluentLineSegment>>{};
    for (final segment in segmentsFor(context)) {
      (grouped[segment.seriesIndex] ??= <FluentLineSegment>[]).add(segment);
    }
    for (final group in grouped.values) {
      final cap =
          series[group.first.seriesIndex].lineOptions?.strokeLinecap ??
          // `:1231` — the cap defaults to round, not to SVG's butt.
          StrokeCap.round;
      for (final segment in group) {
        if (segment.borderWidth == null) {
          continue;
        }
        _stroke(
          canvas,
          segment,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = cap
            ..strokeWidth = segment.borderWidth!
            // `:1234` — the border is opaque even under a dimmed line.
            ..color = segment.borderColour!,
          dashed: false,
        );
      }
      for (final segment in group) {
        _stroke(
          canvas,
          segment,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = cap
            ..strokeWidth = segment.strokeWidth
            ..color = segment.colour.withValues(alpha: segment.opacity),
          dashed: true,
        );
      }
    }
  }

  /// Draws one segment, honouring [FluentLineSegment.dashPattern] when
  /// [dashed] is set.
  ///
  /// `Canvas` has no dash support, so a dashed segment is walked by hand. The
  /// border is never dashed: upstream puts `strokeDasharray` on the line only
  /// (`:1284`), so a dashed line shows its halo through the gaps.
  static void _stroke(
    Canvas canvas,
    FluentLineSegment segment,
    Paint paint, {
    required bool dashed,
  }) {
    final pattern = segment.dashPattern;
    if (!dashed || pattern == null) {
      canvas.drawLine(segment.start, segment.end, paint);
      return;
    }
    final total = (segment.end - segment.start).distance;
    if (total == 0) {
      return;
    }
    final unit = (segment.end - segment.start) / total;
    var travelled = 0.0;
    var index = 0;
    while (travelled < total) {
      final remaining = total - travelled;
      final dash = pattern[index % pattern.length];
      final length = dash < remaining ? dash : remaining;
      if (index.isEven) {
        canvas.drawLine(
          segment.start + unit * travelled,
          segment.start + unit * (travelled + length),
          paint,
        );
      }
      travelled += length;
      index++;
    }
  }

  /// LineChart declares no hit regions.
  ///
  /// Its hover is a nearest-point latch over the whole plot
  /// (`LineChart.tsx:1165`) rather than one region per mark, so the shell's
  /// region machinery has nothing to walk here.
  @override
  List<FluentChartHitRegion> buildHitRegions(
    FluentCartesianChildContext context,
    FluentCartesianLayout layout,
  ) => const <FluentChartHitRegion>[];

  /// Parses an SVG `stroke-dasharray` into a Flutter dash list.
  ///
  /// Comma and whitespace are both separators per the SVG spec; an odd-length
  /// list is repeated to make it even, which for the single number the gaps
  /// story authors means "on and off by that amount".
  static List<double>? _parseDashArray(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final parts = value
        .split(RegExp(r'[,\s]+'))
        .where((part) => part.isNotEmpty)
        .map(double.parse)
        .toList(growable: false);
    return parts.length.isOdd ? <double>[...parts, ...parts] : parts;
  }
}
