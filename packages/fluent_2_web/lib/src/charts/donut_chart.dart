import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
// `listEquals` is not in the `show` list `widgets.dart` re-exports foundation
// with, so it has to be imported directly.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'axis/tick_format.dart';
import 'chrome/chart_popover.dart';
import 'chrome/chart_title.dart';
import 'chrome/legend.dart';
import 'donut_chart_style.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/chart_text_styles.dart';
import 'internal/chart_utils.dart';
import 'internal/d3/format.dart' as d3;
import 'internal/d3/js_math.dart' as d3;
import 'internal/d3/path_sink.dart' as d3;
import 'internal/d3/shape_arc.dart' as d3;
import 'internal/d3/shape_pie.dart' as d3;
import 'internal/data_viz_palette.dart';
import 'model/bar_data.dart';
import 'model/cartesian_series.dart';

/// Ordering applied to a donut's legend (`DonutChart.tsx:107-111`).
enum FluentDonutOrder {
  /// Input order. Upstream's `'default'`, renamed because `default` is a Dart
  /// keyword.
  byDefault,

  /// Descending by value.
  sorted,
}

/// One arc of a donut, after elevation, filtering and the pie layout.
@immutable
class FluentDonutSlice {
  /// Creates a slice.
  const FluentDonutSlice({
    required this.point,
    required this.index,
    required this.value,
    required this.startAngle,
    required this.endAngle,
    required this.padAngle,
    required this.colour,
  });

  /// The datum, with any elevation already applied.
  final FluentChartDataPoint point;

  /// Position in the filtered list the pie ran over.
  final int index;

  /// The value the layout used — the elevated one, not the caller's.
  final double value;

  /// Start angle in d3's convention: zero at twelve o'clock, increasing
  /// clockwise. `Arc` subtracts a further quarter turn internally.
  final double startAngle;

  /// End angle, same convention.
  final double endAngle;

  /// The pad angle carried on the datum, which is what `Arc`'s default
  /// accessor reads.
  final double padAngle;

  /// Resolved fill.
  final Color colour;
}

/// The resolved geometry of one donut.
///
/// Kept pure so the order of operations — colours, sort, elevate, filter, pie —
/// can be asserted without a widget. Getting that order wrong moves every
/// angle.
@immutable
class FluentDonutLayout {
  const FluentDonutLayout._({
    required this.slices,
    required this.legendPoints,
    required this.outerRadius,
    required this.innerRadius,
    required this.total,
    required this.centre,
  });

  /// Runs the full pipeline.
  static FluentDonutLayout compute({
    required List<FluentChartDataPoint> points,
    required FluentDonutOrder order,
    required Size size,
    required double innerRadius,
    required bool hideLabels,
    required double titleHeight,
    required double labelMarginHorizontal,
    required double labelMarginVertical,
    required double padAngle,
    required bool isDark,
  }) {
    // Step 1 — colours, by position in the ORIGINAL list
    // (`DonutChart.tsx:257-269`, `:327`).
    //
    // parity note: upstream writes the resolved colour to a `defaultColor`
    // field, but `Pie.tsx:61` reads `d.data.color`, so an uncoloured slice
    // renders with `fill: undefined` — SVG black. Reproducing that would make
    // every default donut monochrome, which is a total loss of information
    // rather than a pixel difference, so the colour is assigned to the field
    // the renderer actually reads.
    // ponytail: DonutChart.tsx:265 writes the wrong field; assigning the right
    // one is the whole point of the function.
    final coloured = <FluentChartDataPoint>[
      for (var i = 0; i < points.length; i++)
        points[i].color != null
            ? points[i]
            : points[i].copyWithColor(
                FluentDataVizPalette.next(i, isDark: isDark),
              ),
    ];

    // Step 2 — the legend list. `DonutChart.tsx:331` passes
    // `points.filter(d => d.data >= 0)`, which is a NEW list, and the
    // descending sort at `:108` mutates only that copy. The arcs below
    // therefore keep the input order even when `order` is sorted.
    final legendPoints = <FluentChartDataPoint>[
      for (final point in coloured)
        if ((point.data ?? 0) >= 0) point,
    ];
    if (order == FluentDonutOrder.sorted) {
      legendPoints.sort((a, b) => (b.data ?? 0).compareTo(a.data ?? 0));
    }

    // Step 3 — elevation (`DonutChart.tsx:85-105`). minPercent is 0.01 and the
    // comparison is strict, so a value exactly at the threshold is untouched.
    var sumOfData = 0.0;
    for (final point in coloured) {
      sumOfData += point.data ?? 0;
    }
    // `DonutChart.tsx:86`.
    const minPercent = 0.01;
    final elevated = <FluentChartDataPoint>[
      for (final point in coloured)
        if (minPercent * sumOfData > (point.data ?? 0) && (point.data ?? 0) > 0)
          point.copyWithElevatedData(
            minPercent * sumOfData,
            // `:98` — `item.data!.toLocaleString()`, which groups.
            point.yAxisCalloutData ?? formatToLocaleString(point.data),
          )
        else
          point,
    ];

    // Step 4 — the arc filter is `!== 0`, not `>= 0` (`Pie.tsx:90`), so a
    // negative value survives into the layout.
    final forPie = <FluentChartDataPoint>[
      for (final point in elevated)
        if ((point.data ?? 0) != 0) point,
    ];

    // Step 5 — d3.pie with sort(null) and the caller's pad angle
    // (`Pie.tsx:94-98`).
    final arcs = d3.Pie<FluentChartDataPoint>(
      value: (d) => d.data ?? 0,
      padAngle: padAngle,
    )(forPie);

    // DonutChart.tsx:332-335.
    final outerRadius =
        math.min(
          size.width - (hideLabels ? 0 : labelMarginHorizontal),
          size.height - (hideLabels ? 0 : labelMarginVertical) - titleHeight,
        ) /
        2;

    // `Pie.tsx:52-58` sums `props.data`, the list before the `!== 0` filter, so
    // zeroes are included — they contribute nothing, but the percentage labels
    // are documented against the full list.
    var total = 0.0;
    for (final point in elevated) {
      total += point.data ?? 0;
    }

    return FluentDonutLayout._(
      slices: <FluentDonutSlice>[
        for (var i = 0; i < arcs.length; i++)
          FluentDonutSlice(
            point: forPie[i],
            index: i,
            value: arcs[i].value,
            startAngle: arcs[i].startAngle,
            endAngle: arcs[i].endAngle,
            padAngle: arcs[i].padAngle,
            colour: forPie[i].color!,
          ),
      ],
      legendPoints: legendPoints,
      outerRadius: outerRadius,
      innerRadius: innerRadius,
      total: total,
      // Pie.tsx:99 — translate(width / 2, height / 2).
      centre: Offset(size.width / 2, size.height / 2),
    );
  }

  /// The arcs, in the order they are painted.
  final List<FluentDonutSlice> slices;

  /// The legend entries, which may disagree with [slices] in both membership
  /// and order.
  final List<FluentChartDataPoint> legendPoints;

  /// Outer radius in logical pixels.
  final double outerRadius;

  /// Inner radius in logical pixels — an absolute value, not a fraction
  /// (`DonutChart.tsx:34`).
  final double innerRadius;

  /// Sum over the slices the pie ran on.
  final double total;

  /// Centre of the plot in painter coordinates.
  final Offset centre;

  /// Radius at which arc labels sit — `max(inner, outer) + offset`
  /// (`Arc.tsx:79`, where the offset is the literal 2).
  double labelRadius(double offset) =>
      math.max(innerRadius, outerRadius) + offset;
}

/// The `debugLabel` every arc hit target carries.
///
/// The arcs are not the only focusable things inside a donut — the legend rows
/// are too — so the roving-tabindex rule at `Arc.tsx:148` can only be asserted
/// if the arc's own [Focus] nodes are identifiable. Exported rather than
/// private because that assertion lives in a test.
const String kFluentDonutArcFocusLabel = 'FluentDonutChart arc';

/// Builds one [Path] per slice of [layout], already translated onto
/// [FluentDonutLayout.centre].
///
/// `Arc`'s default `padAngle` accessor reads the datum's own pad angle, which
/// `Pie` set to 0.02, and its default `padRadius` is `sqrt(r0^2 + r1^2)` —
/// unlike GaugeChart, which sets one explicitly. Each ring is trimmed
/// independently by `asin(padRadius / r * sin(padAngle / 2))`, so the inner
/// ring loses more angle than the outer one.
List<Path> fluentDonutArcPaths(
  FluentDonutLayout layout, {
  required double cornerRadius,
}) {
  // Arc.tsx:123,136 — one generator, `cornerRadius` applied to every arc.
  final generator = d3.Arc(cornerRadius: cornerRadius);
  return <Path>[
    for (final slice in layout.slices)
      _arcPathOf(generator, slice, layout).shift(layout.centre),
  ];
}

Path _arcPathOf(
  d3.Arc generator,
  FluentDonutSlice slice,
  FluentDonutLayout layout,
) {
  final sink = d3.UiPathSink();
  generator(
    d3.ArcDatum(
      startAngle: slice.startAngle,
      endAngle: slice.endAngle,
      padAngle: slice.padAngle,
      innerRadius: layout.innerRadius,
      outerRadius: layout.outerRadius,
    ),
    sink,
  );
  return sink.path;
}

/// One arc label, already positioned and aligned.
@immutable
class FluentDonutArcLabel {
  /// Creates an arc label.
  const FluentDonutArcLabel({
    required this.text,
    required this.anchor,
    required this.align,
    required this.baseline,
    required this.style,
  });

  /// The rendered string.
  final String text;

  /// Anchor point, in painter coordinates.
  final Offset anchor;

  /// Horizontal anchoring. `Arc.tsx:87` picks `end` when the mid-angle exceeds
  /// PI, XOR the ambient right-to-left flag.
  final TextAlign align;

  /// Vertical anchoring. `Arc.tsx:88` picks `hanging` between PI/2 and 3*PI/2
  /// and `auto` — the alphabetic baseline — otherwise.
  final FluentChartTitleBaseline baseline;

  /// Type — `caption1Strong`.
  final TextStyle style;
}

/// Paints a donut: focus ring, then arcs, then labels.
///
/// The focus ring is drawn UNDER its arc (`Arc.tsx:118-131` emits it first),
/// so the arc's own 1px background-coloured stroke overlaps the inner half of
/// the 4px ring.
class FluentDonutChartPainter extends CustomPainter {
  /// Creates a donut painter.
  const FluentDonutChartPainter({
    required this.layout,
    required this.opacities,
    required this.arcPaths,
    required this.fills,
    required this.strokeColour,
    required this.strokeWidth,
    required this.focusRingColour,
    required this.focusRingWidth,
    required this.textDirection,
    required this.measurer,
    this.focusedIndex,
    this.labels = const <FluentDonutArcLabel>[],
  });

  /// The resolved geometry.
  final FluentDonutLayout layout;

  /// One opacity per slice — 1 or the style's dimmed value.
  final List<double> opacities;

  /// One path per slice, in slice order.
  final List<Path> arcPaths;

  /// One fill per slice, in slice order.
  ///
  /// Separate from [FluentDonutSlice.colour] because a mark's fill is flattened
  /// for high contrast on the way in — spec section 5.3, through
  /// [FluentChartColors.flattenMark] — while the legend, which reads the slice,
  /// keeps its palette.
  final List<Color> fills;

  /// Slice outline colour — `colorNeutralBackground1`.
  final Color strokeColour;

  /// Slice outline width — 1, SVG's default.
  final double strokeWidth;

  /// Focus ring colour — `colorStrokeFocus2`.
  final Color focusRingColour;

  /// Focus ring width — 4, `strokeWidthThickest`.
  final double focusRingWidth;

  /// Ambient text direction, which the arc labels are laid out in.
  final TextDirection textDirection;

  /// The chart's shared measurer. The one place a `TextPainter` may come from.
  final FluentChartTextMeasurer measurer;

  /// Index of the focused slice, or null.
  final int? focusedIndex;

  /// Arc labels, already filtered by the sweep and highlight gates.
  final List<FluentDonutArcLabel> labels;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < arcPaths.length; i++) {
      if (focusedIndex == i) {
        canvas.drawPath(
          arcPaths[i],
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = focusRingWidth
            ..color = focusRingColour,
        );
      }
      canvas
        ..drawPath(
          arcPaths[i],
          Paint()..color = fills[i].withValues(alpha: opacities[i]),
        )
        ..drawPath(
          arcPaths[i],
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..color = strokeColour.withValues(alpha: opacities[i]),
        );
    }
    for (final label in labels) {
      final metrics = measurer.measure(label.text, label.style);
      final painter = measurer.layoutPainter(label.text, label.style);
      // Arc.tsx:87 — `textAnchor` moves the box, it does not justify it.
      final dx = switch (label.align) {
        TextAlign.end => -metrics.width,
        TextAlign.center => -metrics.width / 2,
        _ => 0.0,
      };
      // The offset positions the ALPHABETIC baseline; TextPainter paints from
      // the top-left, so the ascent comes back off.
      final dy =
          fluentChartBaselineOffset(label.baseline, metrics) - metrics.ascent;
      painter.paint(canvas, label.anchor + Offset(dx, dy));
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(FluentDonutChartPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      !listEquals(oldDelegate.opacities, opacities) ||
      !listEquals(oldDelegate.fills, fills) ||
      oldDelegate.focusedIndex != focusedIndex ||
      oldDelegate.labels.length != labels.length ||
      oldDelegate.strokeColour != strokeColour;
}

/// Applies a [FluentDonutChartStyle] to every [FluentDonutChart] below it.
class FluentDonutChartTheme extends InheritedTheme {
  /// Applies [style] to every [FluentDonutChart] in `child`.
  const FluentDonutChartTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the derived defaults.
  final FluentDonutChartStyle style;

  /// The nearest donut chart style, or null.
  static FluentDonutChartStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentDonutChartTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentDonutChartTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentDonutChartTheme(style: style, child: child);
}

/// A Fluent 2 donut chart.
///
/// ```dart
/// FluentDonutChart(data: data, innerRadius: 40, valueInsideDonut: 'Total')
/// ```
///
/// Ports `DonutChart.tsx`, `Pie.tsx` and `Arc.tsx`. The pipeline that turns the
/// data into angles is [FluentDonutLayout.compute]; this widget owns the
/// selection, the hover, the focus ring and the chrome around the plot.
class FluentDonutChart extends StatefulWidget {
  /// Creates a donut chart.
  const FluentDonutChart({
    super.key,
    required this.data,
    // DonutChart.tsx:33 destructures `innerRadius = 0, hideLabels = true`.
    this.innerRadius = 0,
    this.hideLabels = true,
    this.showLabelsInPercent = false,
    this.valueInsideDonut,
    this.width,
    this.height,
    this.hideLegend = false,
    this.hideTooltip = false,
    this.culture,
    this.order = FluentDonutOrder.byDefault,
    this.canSelectMultipleLegends = false,
    // Legends.tsx:108 — `props.overflowText ? props.overflowText : 'more'`.
    this.legendsOverflowText = 'more',
    this.style,
  });

  /// The chart data. Only [FluentChartData.chartData] is read.
  final FluentChartData data;

  /// The hole's radius in logical pixels, not a fraction
  /// (`DonutChart.tsx:33`).
  final double innerRadius;

  /// Whether the per-arc value labels are suppressed (`DonutChart.tsx:33`).
  final bool hideLabels;

  /// Whether the arc labels read as percentages of the total
  /// (`Arc.tsx:92-93`).
  final bool showLabelsInPercent;

  /// The string drawn in the hole, shown only above
  /// [FluentDonutChartStyle.minDonutRadius] (`DonutChart.tsx:337-338`).
  final Object? valueInsideDonut;

  /// Plot width, or null to fill the incoming constraints.
  final double? width;

  /// Plot height, or null to fill the incoming constraints.
  final double? height;

  /// Whether the legend strip — and with it the title — is suppressed
  /// (`DonutChart.tsx:360`, `:415`).
  final bool hideLegend;

  /// Whether the hover popover is suppressed (`DonutChart.tsx:410`).
  final bool hideTooltip;

  /// Locale for the centre value (`DonutChart.tsx:225`).
  final String? culture;

  /// Legend ordering (`DonutChart.tsx:107-111`).
  final FluentDonutOrder order;

  /// Whether several legends may be selected at once
  /// (`DonutChart.tsx:146-150`).
  final bool canSelectMultipleLegends;

  /// The word in the legend overflow trigger.
  final String legendsOverflowText;

  /// Style layered over the derived defaults and the nearest
  /// [FluentDonutChartTheme].
  final FluentDonutChartStyle? style;

  @override
  State<FluentDonutChart> createState() => _FluentDonutChartState();
}

class _FluentDonutChartState extends State<FluentDonutChart> {
  /// `DonutChart.tsx:56`.
  List<String> _selectedLegends = const <String>[];

  /// `DonutChart.tsx:52`. Null is upstream's `undefined`, which `:238` tests
  /// for truthiness.
  String? _activeLegend;

  /// `DonutChart.tsx:57` — an id upstream, an index here.
  int? _focusedIndex;

  FluentChartDataPoint? _hovered;
  Offset? _anchor;

  /// Owned by the state so its cache survives a rebuild.
  final FluentChartTextMeasurer _measurer = FluentChartTextMeasurer();

  /// `_getHighlightedLegend` (`DonutChart.tsx:237-239`).
  List<String> get _highlighted => _selectedLegends.isNotEmpty
      ? _selectedLegends
      : (_activeLegend != null && _activeLegend!.isNotEmpty
            ? <String>[_activeLegend!]
            : const <String>[]);

  /// `_isLegendHighlighted` (`DonutChart.tsx:241-243`), which is model A.
  bool _isHighlighted(String? legend) => isLegendHighlightedMulti(
    legend ?? '',
    selectedLegends: _selectedLegends,
    activeLegend: _activeLegend,
  );

  /// `_shouldHighlightArc` (`Arc.tsx:60-64`) — an empty selection highlights
  /// everything, and so does a datum with no legend at all.
  bool _shouldHighlightArc(String? legend) =>
      _highlighted.isEmpty || legend == null || _highlighted.contains(legend);

  void _handleLegendChange(List<String> selected) {
    setState(() {
      // DonutChart.tsx:146-150 — single select keeps only the last entry.
      _selectedLegends = widget.canSelectMultipleLegends
          ? selected
          : selected
                .skip(math.max(0, selected.length - 1))
                .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.data.chartData ?? const <FluentChartDataPoint>[];
    // `_isChartEmpty` (`DonutChart.tsx:245-251`), rendered as the alert at
    // `:427-429`.
    if (!points.any((point) => (point.data ?? 0) > 0)) {
      return Semantics(
        container: true,
        liveRegion: true,
        label: 'Graph has no data to display',
        child: const SizedBox.shrink(),
      );
    }

    final theme = FluentTheme.of(context);
    final resolved = resolveFluentDonutChartStyle(
      theme,
    ).merge(FluentDonutChartTheme.maybeOf(context)).merge(widget.style);
    const states = <WidgetState>{};

    // `_getTitleHeight` (`DonutChart.tsx:276-284`). Reserved whenever there is
    // a title, whether or not the legend gate at `:360` lets it be drawn.
    final titleHeight = widget.data.chartTitle == null
        ? 0.0
        : math.max(
            resolved.titleFontFallbackSize!.resolve(states)! +
                kChartTitlePadding,
            resolved.titleHeightMin!.resolve(states)!,
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // DonutChart.tsx:360 — the title is gated on the LEGEND, not on
        // itself.
        if (!widget.hideLegend && widget.data.chartTitle != null)
          FluentChartTitle(
            title: widget.data.chartTitle!,
            // DonutChart.tsx:365 — `maxWidth={_width - 20}`.
            maxWidth: widget.width == null ? null : widget.width! - 20,
            textStyle: resolved.titleTextStyle!.resolve(states),
          ),
        Flexible(
          child: LayoutBuilder(
            builder: (context, constraints) => _buildPlot(
              context,
              constraints,
              theme,
              resolved,
              points,
              titleHeight,
            ),
          ),
        ),
        if (!widget.hideLegend) ...<Widget>[
          // useDonutChartStyles.styles.ts:42-45 — the legend container's
          // paddingTop.
          SizedBox(height: resolved.legendGap!.resolve(states)!),
          _buildLegend(points, resolved, theme),
        ],
      ],
    );
  }

  Widget _buildPlot(
    BuildContext context,
    BoxConstraints constraints,
    FluentThemeData theme,
    FluentDonutChartStyle resolved,
    List<FluentChartDataPoint> points,
    double titleHeight,
  ) {
    const states = <WidgetState>{};
    // DonutChart.tsx:50-51 — the width and height state both start at 200, so
    // an unmeasurable container falls back to a 200-pixel square.
    final plotWidth =
        widget.width ??
        (constraints.hasBoundedWidth ? constraints.maxWidth : 200.0);
    final plotHeight =
        widget.height ??
        (constraints.hasBoundedHeight ? constraints.maxHeight : 200.0);

    final layout = FluentDonutLayout.compute(
      points: points,
      order: widget.order,
      size: Size(plotWidth, plotHeight),
      innerRadius: widget.innerRadius,
      hideLabels: widget.hideLabels,
      titleHeight: titleHeight,
      labelMarginHorizontal: resolved.labelMarginHorizontal!.resolve(states)!,
      labelMarginVertical: resolved.labelMarginVertical!.resolve(states)!,
      padAngle: resolved.padAngle!.resolve(states)!,
      isDark: theme.brightness == Brightness.dark,
    );
    final colours = FluentChartColors.of(theme);
    final arcPaths = fluentDonutArcPaths(
      layout,
      cornerRadius: resolved.cornerRadius!.resolve(states)!,
    );
    final dimmed = resolved.dimmedOpacity!.resolve(states)!;
    final opacities = <double>[
      // Arc.tsx:112-113.
      for (final slice in layout.slices)
        _highlighted.isEmpty
            ? 1.0
            : (_isHighlighted(slice.point.legend) ? 1.0 : dimmed),
    ];

    final labels = _buildLabels(layout, resolved);
    final centreValue = _centreValue(layout, resolved);

    return SizedBox(
      width: plotWidth,
      height: plotHeight,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        // Pie.tsx:104 — the group is a listbox named for its slice count.
        label: 'Donut chart with ${layout.slices.length} slices',
        child: MouseRegion(
          // DonutChart.tsx:344 — onMouseLeave clears the popover.
          onExit: (_) => setState(() {
            _hovered = null;
            _anchor = null;
          }),
          onHover: (event) =>
              _handleHover(event.localPosition, layout, arcPaths),
          child: Stack(
            children: <Widget>[
              CustomPaint(
                size: Size(plotWidth, plotHeight),
                painter: FluentDonutChartPainter(
                  layout: layout,
                  opacities: opacities,
                  arcPaths: arcPaths,
                  fills: <Color>[
                    // Spec 5.3 — the mark is flattened, the legend is not.
                    for (final slice in layout.slices)
                      colours.flattenMark(slice.colour),
                  ],
                  strokeColour: resolved.arcStrokeColor!.resolve(states)!,
                  strokeWidth: resolved.arcStrokeWidth!.resolve(states)!,
                  focusRingColour: resolved.focusRingColor!.resolve(states)!,
                  focusRingWidth: resolved.focusRingWidth!.resolve(states)!,
                  textDirection: Directionality.of(context),
                  measurer: _measurer,
                  focusedIndex: _focusedIndex,
                  labels: labels,
                ),
              ),
              for (var i = 0; i < layout.slices.length; i++)
                Positioned.fromRect(
                  rect: arcPaths[i].getBounds(),
                  child: _buildArcTarget(
                    layout.slices[i],
                    i,
                    arcPaths[i].getBounds().center,
                  ),
                ),
              if (centreValue != null)
                _buildCentreValue(centreValue, layout, resolved),
              if (!widget.hideTooltip && _hovered != null && _anchor != null)
                FluentChartPopover(
                  anchor: _anchor!,
                  data: FluentChartPopoverData(
                    // ChartPopover.tsx:43-44 — the callout overrides win.
                    legend: _hovered!.xAxisCalloutData ?? _hovered!.legend,
                    yValue:
                        _hovered!.yAxisCalloutData ??
                        d3.jsNumberToString(_hovered!.data ?? 0),
                    color: _hovered!.color,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// One transparent focus and semantics target per slice.
  ///
  /// The box is the arc's bounding rect, so neighbouring targets overlap; they
  /// carry no gesture recogniser and no hit-testable render object of their
  /// own, which is why the pointer still reaches the [MouseRegion] underneath
  /// and the hover is resolved against the real path there.
  Widget _buildArcTarget(FluentDonutSlice slice, int index, Offset anchor) {
    // Arc.tsx:148 — tabIndex 0 only for an arc the selection has not dimmed.
    final focusable = _shouldHighlightArc(slice.point.legend);
    final point = slice.point;
    // Arc.tsx:53-58.
    final legend = point.xAxisCalloutData ?? point.legend;
    final value =
        point.yAxisCalloutData ?? d3.jsNumberToString(point.data ?? 0);
    return Focus(
      debugLabel: kFluentDonutArcFocusLabel,
      canRequestFocus: focusable,
      skipTraversal: !focusable,
      includeSemantics: false,
      onFocusChange: (focused) => setState(() {
        _focusedIndex = focused ? index : null;
        // DonutChart.tsx:155-169 — focus opens the popover on the focused arc.
        _hovered = focused ? point : null;
        _anchor = focused ? anchor : null;
      }),
      child: Semantics(
        container: true,
        selected: _selectedLegends.contains(point.legend),
        label:
            point.callOutSemantics?.label ??
            '${legend == null ? '' : '$legend, '}$value.',
        onTap: point.onClick,
        child: const SizedBox.expand(),
      ),
    );
  }

  void _handleHover(
    Offset position,
    FluentDonutLayout layout,
    List<Path> arcPaths,
  ) {
    for (var i = 0; i < arcPaths.length; i++) {
      if (!arcPaths[i].contains(position)) {
        continue;
      }
      final point = layout.slices[i].point;
      // DonutChart.tsx:170-186 — the popover only opens on an arc the
      // selection has not dimmed.
      if (!(_highlighted.isEmpty || _isHighlighted(point.legend))) {
        return;
      }
      if (!identical(_hovered, point)) {
        setState(() {
          _hovered = point;
          _anchor = position;
        });
      }
      return;
    }
    if (_hovered != null) {
      setState(() {
        _hovered = null;
        _anchor = null;
      });
    }
  }

  /// One label per slice that clears the three gates at `Arc.tsx:69-75`.
  List<FluentDonutArcLabel> _buildLabels(
    FluentDonutLayout layout,
    FluentDonutChartStyle resolved,
  ) {
    const states = <WidgetState>{};
    if (widget.hideLabels) {
      return const <FluentDonutArcLabel>[];
    }
    final minSweep = resolved.minLabelSweep!.resolve(states)!;
    final radius = layout.labelRadius(
      resolved.labelRadiusOffset!.resolve(states)!,
    );
    final style = resolved.arcLabelTextStyle!.resolve(states)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    // Arc.tsx:77 — the centroid is taken on the datum's own angles, so the
    // generator here carries neither corner nor pad radius.
    final generator = d3.Arc();
    final labels = <FluentDonutArcLabel>[];
    for (final slice in layout.slices) {
      if ((slice.endAngle - slice.startAngle).abs() < minSweep ||
          !_shouldHighlightArc(slice.point.legend)) {
        continue;
      }
      final centroid = generator.centroid(
        d3.ArcDatum(
          startAngle: slice.startAngle,
          endAngle: slice.endAngle,
          padAngle: slice.padAngle,
          innerRadius: layout.innerRadius,
          outerRadius: layout.outerRadius,
        ),
      );
      // Arc.tsx:78,85-86 — the centroid is projected onto the label circle,
      // and a zero-length centroid lands on the centre rather than dividing by
      // zero.
      final hyp = centroid.distance;
      final offset = hyp == 0
          ? Offset.zero
          : Offset(centroid.dx / hyp, centroid.dy / hyp) * radius;
      final angle = (slice.startAngle + slice.endAngle) / 2;
      labels.add(
        FluentDonutArcLabel(
          text: widget.showLabelsInPercent
              // Arc.tsx:93.
              ? d3.format('.0%')(
                  layout.total == 0 ? 0 : slice.value / layout.total,
                )
              // Arc.tsx:94.
              : formatScientificLimitWidth(slice.value),
          anchor: layout.centre + offset,
          // Arc.tsx:87.
          align: (angle > math.pi) != isRtl ? TextAlign.end : TextAlign.start,
          // Arc.tsx:88.
          baseline: angle > math.pi / 2 && angle < 3 * math.pi / 2
              ? FluentChartTitleBaseline.hanging
              : FluentChartTitleBaseline.alphabetic,
          style: style,
        ),
      );
    }
    return labels;
  }

  /// `_valueInsideDonut` (`DonutChart.tsx:200-222`), then `_toLocaleString`
  /// (`:224-230`), then the radius gate at `:337-338`.
  ///
  /// ponytail: the lookup runs over the slices rather than the full elevated
  /// list, so a highlighted zero-valued legend falls back to the caller's
  /// string instead of reading `0`. A zero point has no arc to highlight.
  String? _centreValue(
    FluentDonutLayout layout,
    FluentDonutChartStyle resolved,
  ) {
    const states = <WidgetState>{};
    if (widget.innerRadius <= resolved.minDonutRadius!.resolve(states)!) {
      return null;
    }
    final supplied = widget.valueInsideDonut;
    if (supplied == null) {
      return null;
    }
    final highlighted = _highlighted;
    Object? value = supplied;
    if (highlighted.length == 1 || _hovered != null) {
      // DonutChart.tsx:203-209.
      for (final slice in layout.slices) {
        if (_isHighlighted(slice.point.legend)) {
          value = slice.point.yAxisCalloutData ?? slice.point.data;
          break;
        }
      }
    } else if (highlighted.isNotEmpty) {
      // DonutChart.tsx:210-217.
      var total = 0.0;
      for (final slice in layout.slices) {
        if (highlighted.contains(slice.point.legend)) {
          total += slice.point.data ?? 0;
        }
      }
      value = total;
    }
    final formatted = formatToLocaleString(value, culture: widget.culture);
    // DonutChart.tsx:226-228 — an empty result falls back to the raw value.
    return formatted.isEmpty ? value.toString() : formatted;
  }

  /// The hole's string, wrapped and anchored on its middle baseline.
  ///
  /// `Pie.tsx:107` places it at `y = 5` with `dominant-baseline: middle`, and
  /// `wrapTextInsideDonut` (`utilities.ts:1848-1885`) greedily breaks it at
  /// `innerRadius * 2 - TEXT_PADDING` with a 1.1-em line height.
  Widget _buildCentreValue(
    String value,
    FluentDonutLayout layout,
    FluentDonutChartStyle resolved,
  ) {
    const states = <WidgetState>{};
    // utilities.ts:1855.
    const lineHeight = 1.1;
    final style = resolved.centreValueTextStyle!.resolve(states)!;
    final lines = _wrapInsideDonut(
      value,
      style,
      layout.innerRadius * 2 - resolved.centreTextPadding!.resolve(states)!,
    );
    final metrics = _measurer.measure(lines.first, style);
    // Flutter scales the ascent and descent to fill `fontSize * height`, so the
    // first line's baseline sits that far into the block rather than half a
    // leading below its top.
    final scale = metrics.height == 0
        ? 1.0
        : (style.fontSize ?? metrics.height) * lineHeight / metrics.height;
    final top =
        layout.centre.dy +
        resolved.centreTextBaselineOffset!.resolve(states)! -
        (metrics.ascent * scale - metrics.xHeight / 2);
    return Positioned(
      left: 0,
      top: top,
      width: layout.centre.dx * 2,
      child: Text(
        lines.join('\n'),
        // Pie.tsx:107 — textAnchor="middle".
        textAlign: TextAlign.center,
        style: style.copyWith(height: lineHeight),
      ),
    );
  }

  /// `wrapTextInsideDonut`'s greedy break (`utilities.ts:1866-1881`).
  ///
  /// Upstream measures `line.join(' ') + ' '` — the trailing space is part of
  /// the measured string — and only breaks when the line already holds more
  /// than one word, so a single over-long word overflows rather than being cut.
  List<String> _wrapInsideDonut(String text, TextStyle style, double maxWidth) {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final lines = <String>[];
    var line = <String>[];
    for (final word in words) {
      line.add(word);
      if (_measurer.width('${line.join(' ')} ', style) > maxWidth &&
          line.length > 1) {
        line.removeLast();
        lines.add(line.join(' '));
        line = <String>[word];
      }
    }
    lines.add(line.join(' '));
    return lines;
  }

  Widget _buildLegend(
    List<FluentChartDataPoint> points,
    FluentDonutChartStyle resolved,
    FluentThemeData theme,
  ) {
    // DonutChart.tsx:331 — the legend is built from a filtered COPY, which is
    // also what FluentDonutLayout.legendPoints holds.
    final legendPoints = FluentDonutLayout.compute(
      points: points,
      order: widget.order,
      size: Size.zero,
      innerRadius: widget.innerRadius,
      hideLabels: widget.hideLabels,
      titleHeight: 0,
      labelMarginHorizontal: 0,
      labelMarginVertical: 0,
      padAngle: 0,
      isDark: theme.brightness == Brightness.dark,
    ).legendPoints;
    return FluentChartLegend(
      // DonutChart.tsx:130 — `centerLegends` with no value is `true`.
      centerLegends: true,
      overflowText: widget.legendsOverflowText,
      selectionMode: widget.canSelectMultipleLegends
          ? FluentChartLegendSelectionMode.multiple
          : FluentChartLegendSelectionMode.single,
      selectedLegends: _selectedLegends,
      onChange: (selected, _) => _handleLegendChange(selected),
      legends: <FluentChartLegendItem>[
        for (final point in legendPoints)
          FluentChartLegendItem(
            title: point.legend ?? '',
            // Spec 5.3 — the legend keeps the palette under high contrast.
            color: point.color!,
            // DonutChart.tsx:116-121.
            onHoverAction: () => setState(() {
              _hovered = null;
              _anchor = null;
              _activeLegend = point.legend;
            }),
            // DonutChart.tsx:122-124.
            onMouseOutAction: ({required bool isLegendFocused}) =>
                setState(() => _activeLegend = null),
          ),
      ],
    );
  }
}
