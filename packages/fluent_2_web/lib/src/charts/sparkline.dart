import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'internal/chart_colors.dart';
import 'internal/d3/curves.dart' as d3;
import 'internal/d3/path_sink.dart' as d3;
import 'internal/d3/scale_linear.dart' as d3;
import 'internal/d3/shape_line_area.dart' as d3;
import 'model/cartesian_series.dart';
import 'sparkline_style.dart';

/// The resolved geometry of one sparkline.
///
/// Pure and widget-free so the vertex table can be asserted without a widget
/// tree. Upstream computes its two scales inside a `useEffect` with an empty
/// dependency list (`Sparkline.tsx:53-72`) and captures them in a `useMemo`
/// whose dependencies are both `undefined` on every render (`:38-51`), so the
/// generators permanently close over the first render's scales and the chart
/// never re-scales when `data` changes.
///
/// This port recomputes on every build. That is a deliberate divergence, not an
/// oversight: a stale scale is not a rendering rule anyone specified, it is a
/// React dependency-array bug, and reproducing it in Flutter would mean caching
/// state in a widget that has none.
// ponytail: recompute per build; upstream's frozen scales are a useEffect([])
// defect at Sparkline.tsx:53-72, not a design decision.
@immutable
class FluentSparklineLayout {
  const FluentSparklineLayout._({
    required this.vertices,
    required this.linePath,
    required this.areaPath,
  });

  /// Builds the line and area geometry for [points] inside [size].
  ///
  /// [topMargin] is the only non-zero component of upstream's margin
  /// (`Sparkline.tsx:21-26`); right, bottom and left are all zero, so the x
  /// range is the full width and the y range bottom is the full height.
  static FluentSparklineLayout compute({
    required List<FluentLineChartDataPoint> points,
    required Size size,
    required double topMargin,
  }) {
    final xs = points.map(_asDouble).toList(growable: false);
    final ys = points.map((p) => p.y).toList(growable: false);
    // d3Extent over x (Sparkline.tsx:58) and d3Max over y (:67). The y domain
    // minimum is the literal 0, not the data minimum.
    final xMin = xs.reduce((a, b) => a < b ? a : b);
    final xMax = xs.reduce((a, b) => a > b ? a : b);
    final yMax = ys.reduce((a, b) => a > b ? a : b);

    final x = d3.scaleLinear().domainOf(<double>[xMin, xMax]).rangeOf(<double>[
      0,
      size.width,
    ]);
    final y = d3.scaleLinear().domainOf(<double>[0, yMax]).rangeOf(<double>[
      size.height,
      topMargin,
    ]);

    // A continuous scale returns null for a value that does not coerce to a
    // number — only a NaN can reach it here, and JavaScript would place that
    // datum at NaN too rather than drop it.
    double xAt(double value) => x(value) ?? double.nan;
    double yAt(double value) => y(value) ?? double.nan;

    final vertices = <Offset>[
      for (var i = 0; i < points.length; i++) Offset(xAt(xs[i]), yAt(ys[i])),
    ];

    final lineSink = d3.UiPathSink();
    d3.Line<FluentLineChartDataPoint>(
      x: (d, i, data) => xAt(_asDouble(d)),
      y: (d, i, data) => yAt(d.y),
      curve: d3.curveLinear,
    )(points, lineSink);

    final areaSink = d3.UiPathSink();
    d3.Area<FluentLineChartDataPoint>(
      x0: (d, i, data) => xAt(_asDouble(d)),
      // Sparkline.tsx:48 — the baseline is the raw pixel height, not y(0).
      // With margin.bottom at 0 the two coincide today; they are different
      // quantities and only this one survives a non-zero bottom margin.
      y0: (d, i, data) => size.height,
      y1: (d, i, data) => yAt(d.y),
      curve: d3.curveLinear,
    )(points, areaSink);

    return FluentSparklineLayout._(
      vertices: vertices,
      linePath: lineSink.path,
      areaPath: areaSink.path,
    );
  }

  /// A `DateTime` x is compared by its epoch milliseconds, which is what
  /// JavaScript's implicit `valueOf` does inside `d3Extent`.
  static double _asDouble(FluentLineChartDataPoint point) {
    final x = point.x;
    return x is DateTime
        ? x.millisecondsSinceEpoch.toDouble()
        : (x as num).toDouble();
  }

  /// One point per datum, in data order, in painter coordinates.
  final List<Offset> vertices;

  /// The stroked polyline.
  final Path linePath;

  /// The filled area, closed along the bottom edge of the plot.
  final Path areaPath;
}

/// Paints a sparkline: the line first, then the area on top of it.
///
/// The order matters and is reproduced deliberately. `Sparkline.tsx:89-105`
/// emits the line path before the area path, and SVG paints in document order,
/// so the 20%-opacity fill tints the lower half of the 2px stroke.
class FluentSparklinePainter extends CustomPainter {
  /// Creates a painter over a pre-resolved [layout].
  const FluentSparklinePainter({
    required this.layout,
    required this.colour,
    required this.strokeWidth,
    required this.areaOpacity,
  });

  /// The geometry to paint.
  final FluentSparklineLayout layout;

  /// The series colour, used for both the stroke and the fill.
  ///
  /// Already flattened for high contrast by the widget: see
  /// [FluentChartColors.flattenMark].
  final Color colour;

  /// Stroke width of the line path.
  final double strokeWidth;

  /// Opacity applied to the area fill.
  final double areaOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      layout.linePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = colour,
    );
    canvas.drawPath(
      layout.areaPath,
      Paint()
        ..style = PaintingStyle.fill
        ..color = colour.withValues(alpha: areaOpacity),
    );
  }

  @override
  bool shouldRepaint(FluentSparklinePainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.colour != colour ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.areaOpacity != areaOpacity;
}

/// Applies a [FluentSparklineStyle] to every [FluentSparkline] below it.
class FluentSparklineTheme extends InheritedTheme {
  /// Applies [style] to every [FluentSparkline] in `child`.
  const FluentSparklineTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the derived defaults.
  final FluentSparklineStyle style;

  /// The nearest sparkline style, or null.
  static FluentSparklineStyle? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FluentSparklineTheme>()?.style;

  @override
  bool updateShouldNotify(FluentSparklineTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentSparklineTheme(style: style, child: child);
}

/// A Fluent 2 sparkline: one line series with a translucent area under it, and
/// optionally its legend text beside it.
///
/// ```dart
/// FluentSparkline(data: series, showLegend: true)
/// ```
///
/// Only `data.lineChartData[0]` is ever read, exactly as upstream does
/// (`Sparkline.tsx:55`, `:95`, `:102`, `:118`, `:129`). There are no
/// interactions: no hover, no click, no popover and no animation. The whole
/// widget is a single tab stop with an accessible name.
class FluentSparkline extends StatelessWidget {
  /// Creates a sparkline.
  const FluentSparkline({
    super.key,
    required this.data,
    this.width = 80,
    this.height = 20,
    this.valueTextWidth = 80,
    this.showLegend = false,
    this.style,
  });

  /// The chart data. Only the first line series is read.
  final FluentChartData data;

  /// Preferred plot width. Upstream's default is 80 (`Sparkline.tsx:34`).
  final double width;

  /// Preferred plot height. Upstream's default is 20 (`Sparkline.tsx:35`).
  final double height;

  /// Width of the value-text strip. Upstream's default is 80
  /// (`Sparkline.tsx:36`).
  final double valueTextWidth;

  /// Whether to render the series legend beside the plot
  /// (`Sparkline.tsx:126`).
  final bool showLegend;

  /// Style layered over the derived defaults and the nearest
  /// [FluentSparklineTheme].
  final FluentSparklineStyle? style;

  /// Upstream's `_isChartEmpty` (`Sparkline.tsx:75-82`): empty unless there is
  /// at least one series and no series has an empty data list.
  bool get _isEmpty {
    final series = data.lineChartData;
    return series == null ||
        series.isEmpty ||
        series.any((s) => s.data.isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    if (_isEmpty) {
      return Semantics(
        container: true,
        liveRegion: true,
        label: 'Graph has no data to display',
        child: const SizedBox.shrink(),
      );
    }

    final theme = FluentTheme.of(context);
    final resolved = resolveFluentSparklineStyle(
      theme,
    ).merge(FluentSparklineTheme.maybeOf(context)).merge(style);
    const states = <WidgetState>{};

    final series = data.lineChartData!.first;
    // A line series is typed `LineChartDataPoint[] | ScatterChartDataPoint[]`
    // (`types/DataPoint.ts:492`) and upstream casts the union away at
    // `Sparkline.tsx:70`. A scatter point can carry a string x, which has no
    // place on a linear scale, so it is filtered out rather than cast.
    // ponytail: an all-scatter series simply draws nothing, as the gate below
    // is written over the filtered list.
    final points = series.data.whereType<FluentLineChartDataPoint>().toList(
      growable: false,
    );
    final colour = FluentChartColors.of(theme).flattenMark(
      resolved.lineColor?.resolve(states) ??
          series.color ??
          theme.colors.brandBackground,
    );
    final minSize = resolved.minRenderSize!.resolve(states)!;

    final plot =
        points.isNotEmpty && width >= minSize.width && height >= minSize.height
        ? CustomPaint(
            size: Size(width, height),
            painter: FluentSparklinePainter(
              layout: FluentSparklineLayout.compute(
                points: points,
                size: Size(width, height),
                topMargin: resolved.topMargin!.resolve(states)!,
              ),
              colour: colour,
              strokeWidth: resolved.lineStrokeWidth!.resolve(states)!,
              areaOpacity: resolved.areaFillOpacity!.resolve(states)!,
            ),
          )
        // Sparkline.tsx:114 — below the gate the chart svg is replaced by an
        // empty fragment, which occupies no space at all.
        : const SizedBox.shrink();

    final label = showLegend && series.legend.isNotEmpty
        ? SizedBox(
            width: valueTextWidth,
            height: height,
            child: Padding(
              // Sparkline.tsx:128 — x="0%" dx={8}, with textAnchor flipping to
              // "end" under RTL, which in Flutter is a directional inset plus
              // the directional alignment below.
              padding: EdgeInsetsDirectional.only(
                start: resolved.labelDx!.resolve(states)!,
              ),
              child: Align(
                // Sparkline.tsx:128 — y="100%" dy={-5}. The port bottom-aligns
                // the line box instead of placing the alphabetic baseline five
                // pixels above the strip: at caption1's 12/16 metrics Flutter's
                // proportional leading already leaves 3.2px of descent below
                // the baseline, so honouring the -5 would lift the text clear
                // of the strip's bottom edge rather than sit on it.
                alignment: AlignmentDirectional.bottomStart,
                child: Text(
                  series.legend,
                  style: resolved.labelTextStyle!.resolve(states),
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ),
          )
        : const SizedBox.shrink();

    return Semantics(
      container: true,
      label: 'Sparkline with label ${series.legend}',
      child: Focus(
        child: Row(
          // Not the ambient direction: upstream's container is `display:
          // inline` (`useSparklineStyles.styles.ts:21`), so under RTL the two
          // svgs would swap and the value text would land on the far side of
          // the plot. The label stays trailing, and only its own anchor flips
          // — which is what `textAnchor={_isRTL ? 'end' : 'start'}` at
          // `Sparkline.tsx:128` is for.
          textDirection: TextDirection.ltr,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[plot, label],
        ),
      ),
    );
  }
}
