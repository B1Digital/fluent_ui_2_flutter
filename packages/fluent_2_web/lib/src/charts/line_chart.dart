import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'axis/axis_builders.dart' as builders;
import 'axis/axis_types.dart';
import 'axis/domain_range.dart';
import 'cartesian/cartesian_chart.dart';
import 'cartesian/cartesian_chart_props.dart';
import 'cartesian/cartesian_layout.dart';
import 'cartesian/cartesian_series_delegate.dart';
import 'chrome/event_annotation.dart';
import 'chrome/legend.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/chart_text_styles.dart';
import 'internal/chart_utils.dart';
import 'internal/d3/curves.dart' as d3;
import 'internal/d3/path_sink.dart' as d3;
import 'internal/d3/shape_line_area.dart' as d3;
import 'internal/d3/stable_sort.dart';
import 'internal/data_viz_palette.dart';
import 'internal/marker_geometry.dart';
import 'internal/scatter_polar.dart';
import 'line_chart_style.dart';
import 'model/callout_data.dart';
import 'model/cartesian_series.dart';
import 'model/chart_annotation.dart';
import 'model/chart_common.dart';
import 'model/chart_value.dart';

/// A Fluent 2 line chart.
///
/// Ports `LineChart.tsx`, the largest chart in the package. Two render engines
/// live behind [FluentLineChartDelegate]; this widget owns the legend state
/// (single-select, unlike every bar chart), the hover model and the optional
/// event-annotation band.
class FluentLineChart extends StatefulWidget {
  /// Creates a line chart over [data].
  const FluentLineChart({
    super.key,
    required this.data,
    this.props = const FluentCartesianChartProps(),
    this.eventAnnotations = const <FluentEventAnnotation>[],
    this.eventAnnotationMergedLabel,
    this.colorFillBars = const <FluentColorFillBar>[],
    this.allowMultipleShapesForPoints = false,
    this.optimizeLargeData = false,
    this.isCalloutForStack = true,
    this.culture,
    this.style,
    this.legendSelectionMode = FluentChartLegendSelectionMode.single,
    this.focusNode,
  });

  /// The data bundle. Only [FluentChartData.lineChartData] and
  /// [FluentChartData.chartTitle] are read.
  final FluentChartData data;

  /// Shell configuration.
  final FluentCartesianChartProps props;

  /// Dated rules drawn across the plot with a label band above it.
  final List<FluentEventAnnotation> eventAnnotations;

  /// Label used when several annotations collapse into one
  /// (`EventAnnotation.tsx:61-119`). Required when [eventAnnotations] is not
  /// empty.
  final String Function(int count)? eventAnnotationMergedLabel;

  /// Shaded x ranges drawn behind the lines.
  final List<FluentColorFillBar> colorFillBars;

  /// Whether points cycle through the eight marker shapes. Also makes the
  /// first and last point of every series permanently visible.
  final bool allowMultipleShapesForPoints;

  /// Forces the single-path engine.
  final bool optimizeLargeData;

  /// Whether the popover lists every series at the hovered x. Defaults to
  /// true (`LineChart.tsx:147`).
  final bool isCalloutForStack;

  /// BCP-47 locale for popover formatting.
  final String? culture;

  /// Style override, highest precedence.
  final FluentLineChartStyle? style;

  /// Whether the legend allows more than one selection.
  final FluentChartLegendSelectionMode legendSelectionMode;

  /// The chart's single focus node.
  final FocusNode? focusNode;

  @override
  State<FluentLineChart> createState() => FluentLineChartState();
}

/// State for [FluentLineChart]. Public only so widget tests can reach
/// [hoverValuesFor], which is the shape `FluentAreaChartState` already uses.
class FluentLineChartState extends State<FluentLineChart> {
  /// LineChart tracks ONE selected legend, not a list (`LineChart.tsx:186`).
  final String _selectedLegend = '';
  String? _activeLegend;
  String? _activePointId;
  (int, int)? _nearestPoint;
  late final FluentChartTextMeasurer _measurer = FluentChartTextMeasurer();
  late List<FluentCustomizedCalloutData> _calloutPoints;

  List<FluentLineChartSeries> get _series =>
      widget.data.lineChartData ?? const <FluentLineChartSeries>[];

  @override
  void initState() {
    super.initState();
    _calloutPoints = calloutData(_series);
  }

  @override
  void didUpdateWidget(FluentLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _calloutPoints = calloutData(_series);
    }
  }

  @override
  void dispose() {
    _measurer.invalidate();
    super.dispose();
  }

  /// The popover rows for the hovered x value.
  ///
  /// With `isCalloutForStack` false the stack is narrowed to the single datum
  /// whose y matches the latched point (`LineChart.tsx:1660-1668`). Upstream's
  /// `find` returns the FIRST match, and it can only run from a circle whose y
  /// it already knows; the port is reachable before any point is latched, so
  /// with none latched the first row stands in — either way the answer is at
  /// most one row, which is the whole meaning of the flag.
  List<FluentCustomizedCalloutDataPoint> hoverValuesFor(Object x) {
    final found =
        findCalloutPoints(_calloutPoints, x, isXAxisDate: x is DateTime) ??
        const <FluentCustomizedCalloutDataPoint>[];
    if (widget.isCalloutForStack) {
      return found;
    }
    final nearest = _nearestPoint;
    final matching = nearest == null
        ? found
        : found.where(
            (point) =>
                point.y ==
                (_series[nearest.$1].data[nearest.$2]
                        as FluentLineChartDataPoint)
                    .y,
          );
    return matching.take(1).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final style = resolveFluentLineChartStyle(
      theme,
    ).merge(FluentLineChartTheme.maybeOf(context)).merge(widget.style);
    // Upstream always reserves 36 (`LineChart.tsx:166`); with no band to draw
    // there is nothing to reserve, so the field is assigned explicitly rather
    // than left null.
    final eventLabelHeight = widget.eventAnnotations.isEmpty
        ? 0.0
        : style.eventLabelHeight!.resolve(<WidgetState>{})!;
    return FluentCartesianChart(
      focusNode: widget.focusNode,
      legendSelectionMode: widget.legendSelectionMode,
      props: widget.props.copyWith(
        eventLabelHeight: eventLabelHeight,
        chartTitleForSemantics: widget.data.chartTitle == null
            ? null
            // `${chartTitle}. Line chart with ${n} lines. ` (`:1843-1846`).
            : '${widget.data.chartTitle}. Line chart with '
                  '${_series.length} lines. ',
      ),
      legends: <FluentChartLegendItem>[
        for (var i = 0; i < _series.length; i++)
          FluentChartLegendItem(
            title: _series[i].legend,
            color: _series[i].color ?? FluentDataVizPalette.next(i),
            shape: _series[i].legendShape,
            onHoverAction: () => setState(() {
              // `hoverAction` clears the hover first (`:432-435`).
              _nearestPoint = null;
              _activePointId = null;
              _activeLegend = _series[i].legend;
            }),
            onMouseOutAction: ({required bool isLegendFocused}) =>
                setState(() => _activeLegend = null),
          ),
        // Colour-fill bar legends follow the lines (`LineChart.tsx:451`).
        for (final bar in widget.colorFillBars)
          FluentChartLegendItem(
            title: bar.legend,
            color: bar.color,
            stripePattern: bar.applyPattern,
            onHoverAction: () => setState(() => _activeLegend = bar.legend),
            onMouseOutAction: ({required bool isLegendFocused}) =>
                setState(() => _activeLegend = null),
          ),
      ],
      delegate: FluentLineChartDelegate(
        series: _series,
        style: style,
        colors: FluentChartColors.of(theme),
        measurer: _measurer,
        textStyles: FluentChartTextStyles.of(theme),
        selectedLegend: _selectedLegend,
        activeLegend: _activeLegend,
        activePointId: _activePointId,
        nearestPoint: _nearestPoint,
        optimizeLargeData: widget.optimizeLargeData,
        allowMultipleShapesForPoints: widget.allowMultipleShapesForPoints,
        colorFillBars: widget.colorFillBars,
        // The plan reads `props.strokeWidth` here, but plan 05 dropped that
        // field from the props bag (`cartesian_chart_props.dart:75`), so the
        // override comes from `lineOptions.strokeWidth` or the style alone.
        xScaleType: widget.props.xScaleType,
        yScaleType: widget.props.yScaleType,
        xMinValue: widget.props.xMinValue,
        xMaxValue: widget.props.xMaxValue,
        yMinValue: widget.props.yMinValue,
      ),
      overlayBuilder: widget.eventAnnotations.isEmpty
          ? null
          : (context, child, layout) => FluentEventAnnotationLayer(
              events: widget.eventAnnotations,
              xScale: child.xScale,
              // chartYTop / chartYBottom (`LineChart.tsx:1958-1959`).
              chartTop: (layout.margins.top ?? 0) + eventLabelHeight,
              chartBottom:
                  layout.size.height - kFluentLineEventAnnotationBottomInset,
              mergedLabel:
                  widget.eventAnnotationMergedLabel ??
                  (count) => '$count events',
            ),
      onChartMouseLeave: () => setState(() {
        // `_handleChartMouseLeave` clears the hover (`:1195-1200`).
        _activePointId = null;
        _nearestPoint = null;
      }),
    );
  }
}

/// The gap kept below the event-annotation rules.
///
/// `chartYBottom={props.containerHeight! - 35}` (`LineChart.tsx:1959`); the
/// Oracle B capture of `LineChartEvents` ends its rules at y=225 in a 260px
/// container, which is the same 35.
const double kFluentLineEventAnnotationBottomInset = 35;

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

  /// How much wider than its nominal box each shape is drawn.
  ///
  /// The `widthRatio` column of `pointTypes` (`utilities.ts:1747-1771`), in
  /// the `Points` enum's order — the same order [pathFor] switches on. A
  /// hexagon reaches `x ± w` and an octagon `x ± 1.207w`, so
  /// their boxes have to be divided back down at the call site
  /// (`LineChart.tsx:493-494`); the other five are drawn inside their box and
  /// carry a ratio of 1. Its length is also upstream's
  /// `Object.keys(pointTypes).length`, the modulus of the shape cycle
  /// (`LineChart.tsx:492`).
  static const List<double> kWidthRatios = <double>[
    1,
    1,
    1,
    1,
    1,
    2,
    1.168,
    2.414,
  ];

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

/// One painted data-point marker, resolved against the live scales.
///
/// Produced by [FluentLineChartDelegate.markersFor]. Upstream emits two
/// different elements for a marker — a `<path>` through `_getPointPath`
/// (`LineChart.tsx:936`, `:1101`) and a plain `<circle>` (`:577`, `:851`,
/// `:1018`, `:784`) — and the choice changes how the mark is *sized*, so
/// [shapeIndex] carries the distinction rather than two mark classes.
@immutable
class FluentLineMark {
  /// Creates a mark.
  const FluentLineMark({
    required this.centre,
    required this.shapeIndex,
    required this.size,
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
    required this.opacity,
    required this.seriesIndex,
    required this.pointIndex,
  });

  /// Marker centre in plot coordinates.
  final Offset centre;

  /// The shape 0..7 of a `<path>` marker, or null for a plain `<circle>`.
  ///
  /// Upstream draws the circle whenever the series mode includes `markers` or
  /// `text` (`LineChart.tsx:850`, `:1016`), for a one-point series (`:577`)
  /// and for every engine-B marker (`:784`); every other marker is a shape.
  final int? shapeIndex;

  /// The box width of a `<path>` marker, already divided by its
  /// [FluentLineMarkerPainter.kWidthRatios] entry (`LineChart.tsx:494`), or the
  /// radius of a `<circle>` from [calculateMarkerRadius].
  ///
  /// One field rather than two nullable ones: exactly one number sizes a
  /// marker, and which number it is follows from [shapeIndex].
  final double size;

  /// Fill colour, already flattened by [FluentChartColors.flattenMark].
  final Color fill;

  /// Stroke colour, already flattened by
  /// [FluentChartColors.flattenMarkStroke].
  ///
  /// Upstream strokes a marker with the same colour it fills it with
  /// (`LineChart.tsx:911`); the two only diverge under forced colours, where
  /// sending both to the system foreground would erase the outline
  /// (spec section 5.3), exactly as ScatterChart does it.
  final Color stroke;

  /// Stroke width: the series' own under engine A (`LineChart.tsx:912`), a
  /// flat 1 under engine B (`:803`), and 0 for an inactive one-point marker
  /// (`:624`), which is upstream's way of not stroking it at all.
  final double strokeWidth;

  /// 1 when this mark's legend owns the highlight; otherwise 0.01 under
  /// engine A (`LineChart.tsx:909`) and 0.1 both for a one-point marker
  /// (`:591`) and under engine B (`:804`).
  final double opacity;

  /// Index of the owning series in author order.
  final int seriesIndex;

  /// Index of the point inside its series.
  final int pointIndex;

  /// The outline this mark paints, in plot coordinates.
  Path get path => shapeIndex == null
      ? (Path()..addOval(Rect.fromCircle(center: centre, radius: size)))
      : FluentLineMarkerPainter.pathFor(shapeIndex!, centre, size);
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

  /// Whether this is a scatterpolar chart (`LineChart.tsx:273`).
  ///
  /// Ports `isScatterPolarSeries` (`utilities.ts:2204-2209`), which compares
  /// the **whole** mode literal instead of testing for a substring the way
  /// every other mode consumer does. `'scatterpolar'` contains none of
  /// `lines`, `markers` or `text`, so `FluentLineMode.upstreamName` and not the
  /// three flags is what carries it.
  bool get isScatterPolar => series.any(
    (series) => series.lineOptions?.mode?.upstreamName == 'scatterpolar',
  );

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

  /// The closed `fill: 'toself'` areas, one per qualifying series.
  ///
  /// Ports `LineChart.tsx:1315-1344`, which sits **outside** the engine A / B
  /// branch that closes at `:1313` and so runs under both. All five upstream
  /// conditions are answered here or by [scatterPolarFillPath]:
  ///
  /// 1. `fillMode === 'toself'` (`:1318`) — any other value, including null,
  ///    paints nothing;
  /// 2. `data.length >= 3` (`:1318`), which is [kScatterPolarMinFillPoints]
  ///    inside the helper;
  /// 3. `isLegendSelected` (`:1317`), the same
  ///    `_legendHighlighted || _noLegendHighlighted` pair [markerOpacityFor]
  ///    reads. Upstream's third arm, `isSelectedLegend`, is
  ///    `legendProps.selectedLegends.length > 0` (`:191-193`), a prop the port
  ///    does not carry;
  /// 4. `_isScatterPolar` (`:1318`) — [isScatterPolar];
  /// 5. `if (fillPath)` (`:1330`), the helper's null for a run with no
  ///    plottable point.
  ///
  /// Series are walked last to first so series 0 lands on top, exactly as
  /// [segmentsFor] and [markersFor] do (`:535`).
  List<({int seriesIndex, Path path, Color fill, Color stroke})>
  scatterPolarFillsFor(FluentCartesianChildContext context) {
    if (!isScatterPolar) {
      return const <({int seriesIndex, Path path, Color fill, Color stroke})>[];
    }
    final out = <({int seriesIndex, Path path, Color fill, Color stroke})>[];
    for (var i = series.length - 1; i >= 0; i--) {
      final line = series[i];
      if (line.lineOptions?.fill != 'toself') {
        continue;
      }
      if (!highlighted(line.legend) && !_noneHighlighted) {
        continue;
      }
      final data = line.data.cast<FluentLineChartDataPoint>();
      final yScale = line.useSecondaryYScale && context.yScaleSecondary != null
          ? context.yScaleSecondary!
          : context.yScalePrimary;
      final path = scatterPolarFillPath(
        // A non-plottable coordinate is dropped by the helper's `defined`
        // before it is drawn, so the NaN these fall back to never reaches the
        // sink — the same shape [singlePathFor] uses.
        points: <Offset>[
          for (final point in data)
            Offset(
              context.xScale(point.x) ?? double.nan,
              yScale(point.y) ?? double.nan,
            ),
        ],
        // `:1325` reads the series' own curve, the one `:668` resolved.
        curve: getCurveFactory(line.lineOptions?.curve, d3.curveLinear),
      );
      if (path == null) {
        continue;
      }
      // `:1335` and `:1337` both spell `lineColor`; spec section 5.3 splits
      // them under forced colours, or an area and its outline would flatten to
      // the same system colour and the outline would vanish.
      final rawColour = line.color ?? FluentDataVizPalette.next(i);
      out.add((
        seriesIndex: i,
        path: path,
        fill: colors.flattenMark(rawColour),
        stroke: colors.flattenMarkStroke(rawColour),
      ));
    }
    return out;
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

  /// The largest `markerSize` anywhere in [series], or 0.
  ///
  /// `d3Max(_points, point => d3Max(point.data, item => item.markerSize))`
  /// (`LineChart.tsx:530-534`). `d3Max` of an all-undefined list is
  /// `undefined`, which upstream asserts away with a `!`; it can only reach
  /// [calculateMarkerRadius] alongside an equally absent `pointMarkerSize`,
  /// which returns on its falsy branch before reading it. 0 is therefore the
  /// same answer, and it is the `?? 0` ScatterChart already spells out.
  double get maxMarkerSize {
    var largest = 0.0;
    for (final line in series) {
      for (final point in line.data.cast<FluentLineChartDataPoint>()) {
        final size = point.markerSize;
        if (size != null && size > largest) {
          largest = size;
        }
      }
    }
    return largest;
  }

  /// Resolves every data-point marker for [context].
  ///
  /// Series are walked last to first so series 0 paints on top, exactly as
  /// [segmentsFor] does (`LineChart.tsx:535`).
  ///
  /// Markers are **not** gated on the mode the way lines are. Engine A draws
  /// one at every plottable point whatever the mode is, and lets the mode pick
  /// between a `<circle>` and a `<path>` (`LineChart.tsx:850`); engine B draws
  /// them only in markers mode (`:773`). [lineModeDrawsLines] — upstream's
  /// `shouldDrawLines` (`:698`) — therefore has no say here, and a
  /// `'markers'`-only series draws its markers while drawing no line at all.
  /// A gap suppresses only the line: `_checkInGap`'s answer is read at `:1215`
  /// and nowhere near the marker pushes, which is why the gaps story captures
  /// a marker on both sides of every gap.
  List<FluentLineMark> markersFor(FluentCartesianChildContext context) {
    final out = <FluentLineMark>[];
    final largestMarker = maxMarkerSize;
    // `_getPointFill` inverts an active marker to the canvas colour
    // (`LineChart.tsx:498-521`). Deliberately not flattened: under forced
    // colours `flattenMark` would send it to the same system foreground as the
    // marker it is meant to invert, which is the reasoning ScatterChart's
    // `activeMarkerFillColor` records (spec section 5.3).
    final activeFill = colors.markStroke;
    final dimPoint = style.pointOpacity!.resolve(<WidgetState>{
      WidgetState.disabled,
    })!;
    for (var i = series.length - 1; i >= 0; i--) {
      final line = series[i];
      final data = line.data.cast<FluentLineChartDataPoint>();
      final useSecondary =
          line.useSecondaryYScale && context.yScaleSecondary != null;
      final yScale = useSecondary
          ? context.yScaleSecondary!
          : context.yScalePrimary;
      final rawColour = line.color ?? FluentDataVizPalette.next(i);
      final colour = colors.flattenMark(rawColour);
      // `:545-556` — the pixel budget is measured per series, because the
      // secondary y scale changes it, and is not measured at all outside
      // markers mode.
      final extraMaxPixels = hasMarkersMode
          ? getRangeForScatterMarkerSize(
              points: series,
              xScale: context.xScale,
              yScalePrimary: context.yScalePrimary,
              yScaleSecondary: context.yScaleSecondary,
              useSecondaryYScale: useSecondary,
              xScaleType: xScaleType,
              yScaleType: yScaleType,
              // parity: upstream reads `props.secondaryYScaleType` here
              // (`:554`); the ported props carry one y scale type, the same
              // divergence [yScaleType] already records.
              secondaryYScaleType: yScaleType,
            )
          : 0.0;

      Offset? centreOf(int index) {
        final x = context.xScale(data[index].x);
        final y = yScale(data[index].y);
        return isPlottable(x, y) ? Offset(x!, y!) : null;
      }

      double radiusOf(int index, {required bool isActive}) =>
          calculateMarkerRadius(
            pointMarkerSize: data[index].markerSize,
            // `:582` and `:788` both pass a zero floor.
            minMarkerSize: 0,
            maxMarkerSize: largestMarker,
            extraMaxPixels: extraMaxPixels,
            // `:585` — LineChart never passes false, unlike ScatterChart.
            isContinuousXY: true,
            isActive: isActive,
          );

      // `:556` — a one-point series is a bare circle, drawn ahead of the
      // engine branch. Neither engine can add to it: engine B is gated on
      // `data.length > 1` (`:670`) and engine A's loop starts at 1.
      if (data.length == 1) {
        final centre = centreOf(0);
        if (centre == null) {
          continue;
        }
        final isActive = activePointId == '${i}_0';
        out.add(
          FluentLineMark(
            centre: centre,
            shapeIndex: null,
            size: radiusOf(0, isActive: isActive),
            // `:590` — this branch reads no `markerColor`.
            fill: isActive ? activeFill : colour,
            stroke: colors.flattenMarkStroke(rawColour),
            // `:623-624` — stroked only while active, and at the constant
            // rather than at the series' own width.
            strokeWidth: isActive
                ? FluentLineMarkerPainter.kDefaultLineStrokeSize
                : 0,
            // `:591` — 0.1, not engine A's 0.01.
            opacity: markerOpacityForEngineB(line.legend),
            seriesIndex: i,
            pointIndex: 0,
          ),
        );
        continue;
      }

      if (usesSinglePathEngine) {
        // `:773` — engine B draws markers only in markers mode.
        if (!(line.lineOptions?.mode?.markers ?? false)) {
          continue;
        }
        for (var j = 0; j < data.length; j++) {
          final centre = centreOf(j);
          if (centre == null) {
            continue;
          }
          final markerColour = data[j].markerColor ?? rawColour;
          out.add(
            FluentLineMark(
              centre: centre,
              shapeIndex: null,
              // `:792` compares `activePoint` against the id *prefix* rather
              // than against this marker's own id, so it never matches and an
              // engine-B marker never grows on hover. Reproduced, not
              // repaired.
              size: radiusOf(j, isActive: false),
              fill: colors.flattenMark(markerColour),
              stroke: colors.flattenMarkStroke(markerColour),
              strokeWidth: markerStrokeWidthForEngineB,
              opacity: markerOpacityForEngineB(line.legend),
              seriesIndex: i,
              pointIndex: j,
            ),
          );
        }
        continue;
      }

      // Engine A (`:844-1160`) walks j from 1, drawing the point *before* j
      // and, once j is the last index, the point at j as well. That is one
      // marker per point, which is what this loop says directly.
      final shape = allowMultipleShapesForPoints
          // `:492` — the cycle runs over the series index, not the point
          // index; `:284` pins that index to -1, i.e. unused, when the flag is
          // off.
          ? i % FluentLineMarkerPainter.kWidthRatios.length
          : 0;
      final ratio = FluentLineMarkerPainter.kWidthRatios[shape];
      final strokeWidth =
          line.lineOptions?.strokeWidth ??
          strokeWidthOverride ??
          style.strokeWidth!.resolve(<WidgetState>{})!;
      // `:850` and `:1016` — markers or text mode replaces the shape with a
      // plain circle sized by `calculateMarkerRadius`.
      final mode = line.lineOptions?.mode;
      final isCircle = (mode?.markers ?? false) || (mode?.text ?? false);
      for (var j = 0; j < data.length; j++) {
        final centre = centreOf(j);
        if (centre == null) {
          continue;
        }
        final isActive = activePointId == '${i}_$j';
        final isLast = j == data.length - 1;
        // `:1147` reads the point's own `markerColor`, but the last point's
        // *circle* at `:1073-1074` does not. Reproduced rather than tidied.
        final markerColour = isCircle && isLast ? null : data[j].markerColor;
        // `_getBoxWidthOfShape` (`:463-480`), whose `pointIndex === 1` names
        // the point before j == 1 — the first one.
        final box = FluentLineMarkerPainter.boxWidthFor(
          allowMultipleShapes: allowMultipleShapesForPoints,
          isActive: isActive,
          isFirstOrLast: j == 0 || isLast,
          strokeWidth: strokeWidth,
        );
        out.add(
          FluentLineMark(
            centre: centre,
            shapeIndex: isCircle ? null : shape,
            size: isCircle
                ? radiusOf(j, isActive: isActive)
                // `:494` — only a shape wider than its box is narrowed.
                : (ratio > 1 ? box / ratio : box),
            // `markerColor || _getPointFill(…)` (`:910`): the per-point colour
            // short-circuits ahead of the active inversion, so a marker that
            // names its own colour keeps it while hovered.
            fill: markerColour != null
                ? colors.flattenMark(markerColour)
                : (isActive ? activeFill : colour),
            stroke: colors.flattenMarkStroke(markerColour ?? rawColour),
            strokeWidth: strokeWidth,
            // `currentPointHidden` (`:841`) dims a marker of a series that
            // hides its inactive dots, on top of the legend dimming.
            opacity: line.hideInactiveDots && !isActive
                ? dimPoint
                : markerOpacityFor(line.legend),
            seriesIndex: i,
            pointIndex: j,
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
    // `:1357-1367` wraps each series in its own `<g>` holding that series'
    // borders, then its lines, then its points — so a halo never covers its
    // own neighbour and a marker is never buried under the next series' line.
    final grouped = <int, List<FluentLineSegment>>{};
    for (final segment in segmentsFor(context)) {
      (grouped[segment.seriesIndex] ??= <FluentLineSegment>[]).add(segment);
    }
    final marks = <int, List<FluentLineMark>>{};
    for (final mark in markersFor(context)) {
      (marks[mark.seriesIndex] ??= <FluentLineMark>[]).add(mark);
    }
    // `:1331` pushes the scatterpolar area onto `linesForLine`, so it sits
    // above that series' own segments and below its markers.
    final fills = <int, List<({Path path, Color fill, Color stroke})>>{};
    for (final area in scatterPolarFillsFor(context)) {
      (fills[area.seriesIndex] ??= <({Path path, Color fill, Color stroke})>[])
          .add((path: area.path, fill: area.fill, stroke: area.stroke));
    }
    // `:535` pushes the groups last series first, so series 0's `<g>` is last
    // in the document and lands on top.
    for (var i = series.length - 1; i >= 0; i--) {
      final group = grouped[i] ?? const <FluentLineSegment>[];
      final cap =
          series[i].lineOptions?.strokeLinecap ??
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
      for (final area
          in fills[i] ?? const <({Path path, Color fill, Color stroke})>[]) {
        canvas
          // `:1335-1336` — fill={lineColor} fillOpacity={0.5}.
          ..drawPath(
            area.path,
            Paint()
              ..color = area.fill.withValues(alpha: kScatterPolarFillOpacity),
          )
          // `:1337-1339` — stroke={lineColor} strokeWidth={2}
          // strokeOpacity={0.8}. The area carries no `pointerEvents` of its own
          // (`:1340`) because it is painted onto the canvas and declares no
          // region in [buildHitRegions], so it cannot be hit in the first place.
          ..drawPath(
            area.path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = kScatterPolarFillStrokeWidth
              ..color = area.stroke.withValues(
                alpha: kScatterPolarFillStrokeOpacity,
              ),
          );
      }
      for (final mark in marks[i] ?? const <FluentLineMark>[]) {
        final path = mark.path;
        canvas.drawPath(
          path,
          Paint()..color = mark.fill.withValues(alpha: mark.opacity),
        );
        // `:624` strokes an inactive one-point marker at width 0, which is
        // SVG for "no outline"; Flutter would draw a hairline instead.
        if (mark.strokeWidth == 0) {
          continue;
        }
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = mark.strokeWidth
            ..color = mark.stroke.withValues(alpha: mark.opacity),
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
