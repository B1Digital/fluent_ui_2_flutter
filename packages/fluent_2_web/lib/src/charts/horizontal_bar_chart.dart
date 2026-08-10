import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'axis/tick_format.dart';
import 'chrome/chart_popover.dart';
import 'chrome/legend.dart';
import 'horizontal_bar_chart_style.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/chart_utils.dart';
import 'internal/d3/js_math.dart' as d3;
import 'model/bar_data.dart';
import 'model/cartesian_series.dart';

/// One bar of one horizontal-bar row, in percentage units of the row width.
@immutable
class FluentHorizontalBarSegment {
  /// Creates a segment.
  const FluentHorizontalBarSegment({
    required this.index,
    required this.startPercent,
    required this.widthPercent,
    required this.xPercent,
  });

  /// Position in the row's `chartData` list.
  final int index;

  /// Upstream's `startingPoint[index]` — the cumulative width of the preceding
  /// bars, gaps excluded (`HorizontalBarChart.tsx:278`).
  final double startPercent;

  /// Upstream's `value` — the scaled share this bar occupies
  /// (`HorizontalBarChart.tsx:315`).
  final double widthPercent;

  /// The painted left edge, gaps included, already mirrored for the ambient
  /// text direction (`HorizontalBarChart.tsx:309-313`).
  final double xPercent;

  @override
  bool operator ==(Object other) =>
      other is FluentHorizontalBarSegment &&
      other.index == index &&
      other.startPercent == startPercent &&
      other.widthPercent == widthPercent &&
      other.xPercent == xPercent;

  @override
  int get hashCode => Object.hash(index, startPercent, widthPercent, xPercent);
}

/// The resolved geometry of one horizontal-bar row.
///
/// A literal port of `_createBars` (`HorizontalBarChart.tsx:218-333`), kept
/// pure so the two upstream defects it reproduces can be asserted numerically
/// without a widget tree.
@immutable
class FluentHorizontalBarRowLayout {
  const FluentHorizontalBarRowLayout._({
    required this.total,
    required this.sumOfPercent,
    required this.scalingRatio,
    required this.gapPercent,
    required this.rowWidth,
    required this.segments,
  });

  /// Runs both passes over [points].
  ///
  /// [barGap] is `MARGIN_WIDTH_IN_PX` (`HorizontalBarChart.tsx:364`) and
  /// [rowWidth] is the measured width of the row. Upstream reads that width
  /// from a `getBoundingClientRect` in an effect (`:361-368`), so its first
  /// paint runs with a gap of 0 and only the second has the real value; a
  /// `LayoutBuilder` gives Flutter the width on the first frame, which is a
  /// deliberate improvement and changes nothing after the first frame.
  static FluentHorizontalBarRowLayout compute({
    required List<FluentChartDataPoint> points,
    required double rowWidth,
    required double barGap,
    required bool isRtl,
  }) {
    // HorizontalBarChart.tsx:366 — the gap is converted to a percentage of the
    // same width every x is a percentage of, so it resolves back to exactly
    // `index * barGap` pixels.
    final gapPercent = rowWidth == 0 ? 0.0 : (barGap / rowWidth) * 100;

    // parity: HorizontalBarChart.tsx:219-221 counts `point.data`, which is the
    // BENCHMARK field (types/DataPoint.ts:112-159), not the bar value. For
    // ordinary data every `point.data` is null, the reduce yields 0, and the
    // `|| 1` makes this 1 — so `totalMarginPercent` below is always 0 and the
    // bars are never shrunk to make room for the gaps.
    var barCount = 0;
    for (final point in points) {
      if ((point.data ?? 0) > 0) barCount++;
    }
    if (barCount == 0) barCount = 1;
    final totalMarginPercent = gapPercent * (barCount - 1);

    // HorizontalBarChart.tsx:232-236 — a null or zero x contributes nothing.
    var total = 0.0;
    for (final point in points) {
      total += point.horizontalBarChartData?.x ?? 0;
    }

    // Pass one: the clamped sum (HorizontalBarChart.tsx:240-252).
    var sumOfPercent = 0.0;
    for (final point in points) {
      final pointData = point.horizontalBarChartData?.x ?? 0;
      var value = total == 0 ? 0.0 : (pointData / total) * 100;
      if (value < 0) {
        value = 0;
      } else if (value < 1 && value != 0) {
        // The clamp target in pass one is a flat 1, unlike pass two.
        value = 1;
      }
      sumOfPercent += value;
    }

    // parity: HorizontalBarChart.tsx:262 — the comment above it at :253-261
    // describes shrinking the bars to leave room for the margins, but the
    // value is then DIVIDED by this ratio at :274 and :276, which grows them
    // whenever the ratio is below 1. The noOfBars defect keeps the margin at 0
    // for ordinary data, where the division degenerates to `v * 100 / sum` and
    // the two errors cancel to exactly 100%.
    final scalingRatio = sumOfPercent != 0
        ? (sumOfPercent - totalMarginPercent) / 100
        : 1.0;

    // Pass two: positions (HorizontalBarChart.tsx:264-278).
    final segments = <FluentHorizontalBarSegment>[];
    var prevPosition = 0.0;
    var value = 0.0;
    for (var index = 0; index < points.length; index++) {
      // parity: the accumulator adds the PREVIOUS iteration's value before
      // this one is computed (HorizontalBarChart.tsx:267-269), so it lags by
      // one step. Reordering these two statements moves every bar.
      if (index > 0) prevPosition += value;
      final pointData = points[index].horizontalBarChartData?.x ?? 0;
      value = total == 0 ? 0.0 : (pointData / total) * 100;
      if (value < 0) {
        value = 0;
      } else if (value < 1 && value != 0) {
        value = 1 / scalingRatio;
      } else {
        value = value / scalingRatio;
      }
      final startPercent = prevPosition;
      segments.add(
        FluentHorizontalBarSegment(
          index: index,
          startPercent: startPercent,
          widthPercent: value,
          xPercent: isRtl
              // HorizontalBarChart.tsx:311.
              ? 100 - startPercent - value - index * gapPercent
              // HorizontalBarChart.tsx:312.
              : startPercent + index * gapPercent,
        ),
      );
    }

    return FluentHorizontalBarRowLayout._(
      total: total,
      sumOfPercent: sumOfPercent,
      scalingRatio: scalingRatio,
      gapPercent: gapPercent,
      rowWidth: rowWidth,
      segments: segments,
    );
  }

  /// Sum of every `horizontalBarChartData.x` in the row.
  final double total;

  /// Result of pass one.
  final double sumOfPercent;

  /// The divisor applied in pass two.
  final double scalingRatio;

  /// The inter-bar gap, as a percentage of [rowWidth].
  final double gapPercent;

  /// The measured row width in logical pixels.
  final double rowWidth;

  /// One entry per point, in data order.
  final List<FluentHorizontalBarSegment> segments;

  /// The painted rectangle of the bar at [index].
  ///
  /// The result may extend past [rowWidth] — that is the upstream overflow,
  /// and nothing clips it because the svg is `overflow: visible`
  /// (`useHorizontalBarChartStyles.styles.ts:49`).
  Rect rectOf(int index, double barHeight) {
    final segment = segments[index];
    return Rect.fromLTWH(
      segment.xPercent / 100 * rowWidth,
      0,
      segment.widthPercent / 100 * rowWidth,
      barHeight,
    );
  }
}

/// Which scale a horizontal bar chart draws against.
///
/// Upstream declares `HorizontalBarChartVariant` with `PartToWhole` documented
/// as the default (`HorizontalBarChart.types.ts:83`) but never assigns one;
/// every check is `=== AbsoluteScale`, so an unset variant behaves as
/// part-to-whole.
enum FluentHorizontalBarChartVariant {
  /// Bars share one row that sums to the whole.
  partToWhole,

  /// One value against an absolute maximum, with the value drawn as a label
  /// inside the row instead of beside it.
  absoluteScale,
}

/// How the number beside a row is rendered
/// (`HorizontalBarChart.tsx:143-190`).
enum FluentChartDataMode {
  /// The value alone. Upstream's `'default'`, renamed because `default` is a
  /// Dart keyword.
  byDefault,

  /// `value / total`, with the literal spaces upstream puts round the slash.
  fraction,

  /// The value as a whole percentage of the total.
  percentage,

  /// Nothing at all.
  hidden,
}

/// Paints one row's bars, and the absolute-scale label when there is one.
///
/// Bars are drawn in `chartData` order with no stroke, no corner radius and no
/// shadow (`HorizontalBarChart.tsx:306-330`), and the painter deliberately does
/// not clip: the last bar of a full row ends `(n - 1) * 3` px past the row edge
/// and upstream shows it, because the svg is `overflow: visible`
/// (`useHorizontalBarChartStyles.styles.ts:49`).
class FluentHorizontalBarStripPainter extends CustomPainter {
  /// Creates a strip painter.
  const FluentHorizontalBarStripPainter({
    required this.layout,
    required this.fills,
    required this.opacities,
    required this.barHeight,
    required this.textDirection,
    this.colors,
    this.absoluteLabel,
    this.absoluteLabelStyle,
    this.absoluteLabelOffset = 4,
    this.absoluteLabelIndex,
  });

  /// The one measurer, used for the absolute-scale label.
  ///
  /// Static because [FluentChartTextMeasurer.layoutPainter] keeps no
  /// per-instance state and the painter is const; a caller with its own
  /// measurer changes nothing about the result.
  static final FluentChartTextMeasurer _measurer = FluentChartTextMeasurer();

  /// The resolved row geometry.
  final FluentHorizontalBarRowLayout layout;

  /// One fill per segment, in segment order.
  final List<Color> fills;

  /// One opacity per segment — 1 or the style's dimmed value
  /// (`HorizontalBarChart.tsx:327`).
  final List<double> opacities;

  /// Height of each bar.
  final double barHeight;

  /// Ambient text direction, which selects the label's anchor and the sign of
  /// its translate (`HorizontalBarChart.tsx:294`, `:297`).
  final TextDirection textDirection;

  /// The resolved chart colours, or null to paint [fills] as given.
  ///
  /// Only [FluentChartColors.flattenMark] is read. A bar carries no
  /// `forced-color-adjust` upstream, so a forced-colours browser repaints every
  /// one of them in the system foreground and the forty-colour palette
  /// disappears (design spec section 5.3); Flutter does nothing there unless
  /// told to, so the flattening is explicit. Passing null is only correct when
  /// the caller has already flattened.
  final FluentChartColors? colors;

  /// The absolute-scale label, or null when the variant is part-to-whole or
  /// `hideLabels` is set.
  final String? absoluteLabel;

  /// Type for [absoluteLabel] — `caption1Strong`
  /// (`useHorizontalBarChartStyles.styles.ts:94-100`).
  final TextStyle? absoluteLabelStyle;

  /// The `translate(±4)` applied to the label
  /// (`HorizontalBarChart.tsx:297`).
  final double absoluteLabelOffset;

  /// Index of the placeholder segment the label is anchored to.
  final int? absoluteLabelIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final chartColors = colors;
    for (var i = 0; i < layout.segments.length; i++) {
      if (absoluteLabelIndex == i) continue;
      final fill = chartColors == null
          ? fills[i]
          : chartColors.flattenMark(fills[i]);
      canvas.drawRect(
        layout.rectOf(i, barHeight),
        Paint()..color = fill.withValues(alpha: opacities[i]),
      );
    }
    final label = absoluteLabel;
    final index = absoluteLabelIndex;
    if (label == null || index == null) return;
    final painter = _measurer.layoutPainter(
      label,
      absoluteLabelStyle ?? const TextStyle(),
    );
    final anchorPercent = textDirection == TextDirection.rtl
        // HorizontalBarChart.tsx:294.
        ? 100 - layout.segments[index].startPercent
        : layout.segments[index].startPercent;
    final signedOffset = textDirection == TextDirection.rtl
        ? -absoluteLabelOffset
        : absoluteLabelOffset;
    painter.paint(
      canvas,
      Offset(
        anchorPercent / 100 * layout.rowWidth + signedOffset,
        // HorizontalBarChart.tsx:295-296 — dominant-baseline "central" centres
        // the em box on `y = barHeight / 2`, which is
        // FluentChartTextMetrics.centralOffset: the measurer drops the type
        // token's leading, so the line box is exactly ascent + descent and that
        // offset is half the height.
        barHeight / 2 - painter.height / 2,
      ),
    );
    painter.dispose();
  }

  @override
  bool shouldRepaint(FluentHorizontalBarStripPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      !listEquals(oldDelegate.fills, fills) ||
      !listEquals(oldDelegate.opacities, opacities) ||
      oldDelegate.barHeight != barHeight ||
      oldDelegate.colors != colors ||
      oldDelegate.absoluteLabel != absoluteLabel ||
      oldDelegate.absoluteLabelStyle != absoluteLabelStyle ||
      oldDelegate.absoluteLabelOffset != absoluteLabelOffset ||
      oldDelegate.absoluteLabelIndex != absoluteLabelIndex ||
      oldDelegate.textDirection != textDirection;
}

/// Paints the downward-pointing benchmark marker above a row.
///
/// Upstream builds it out of CSS borders — 4px transparent on the left and
/// right, 7px coloured on top (`useHorizontalBarChartStyles.styles.ts:84-93`) —
/// which renders as an 8 x 7 triangle whose wide edge is the TOP and whose apex
/// is at the bottom centre.
class FluentBenchmarkTrianglePainter extends CustomPainter {
  /// Creates a benchmark painter.
  const FluentBenchmarkTrianglePainter({
    required this.ratio,
    required this.colour,
    required this.triangleWidth,
    required this.triangleHeight,
  });

  /// Upstream's `benchmarkRatio` as a fraction of the row width.
  ///
  /// `HorizontalBarChart.tsx:198` computes it as
  /// `Math.round(data / total * 100)`, an integer percentage, so the marker
  /// quantises to whole percentage points. A zero total is division by zero in
  /// JavaScript too — `Math.round(Infinity)` is `Infinity`, and the `left:
  /// calc(Infinity% - 4px)` that follows is an invalid declaration the browser
  /// drops — so the guard keeps the marker at the origin rather than feeding a
  /// non-finite offset to a [Path].
  static double ratioFor({required double benchmark, required double total}) =>
      total == 0 ? 0 : d3.jsRound(benchmark / total * 100) / 100;

  /// Horizontal position as a fraction of the painted width.
  final double ratio;

  /// Fill colour — `colorPaletteBlueBorderActive`.
  final Color colour;

  /// Base width, 8 (`useHorizontalBarChartStyles.styles.ts:87-88`).
  final double triangleWidth;

  /// Height, 7 (`useHorizontalBarChartStyles.styles.ts:89`).
  final double triangleHeight;

  /// The triangle, centred on [ratio] of [size]'s width.
  ///
  /// `left: calc(<ratio>% - 4px)` on a box 8 wide
  /// (`HorizontalBarChart.tsx:201`) puts the centre exactly on the ratio.
  Path buildPath(Size size) {
    final centre = ratio * size.width;
    final half = triangleWidth / 2;
    return Path()
      ..moveTo(centre - half, 0)
      ..lineTo(centre + half, 0)
      ..lineTo(centre, triangleHeight)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) =>
      canvas.drawPath(buildPath(size), Paint()..color = colour);

  @override
  bool shouldRepaint(FluentBenchmarkTrianglePainter oldDelegate) =>
      oldDelegate.ratio != ratio ||
      oldDelegate.colour != colour ||
      oldDelegate.triangleWidth != triangleWidth ||
      oldDelegate.triangleHeight != triangleHeight;
}

/// Applies a [FluentHorizontalBarChartStyle] to every
/// [FluentHorizontalBarChart] below it.
class FluentHorizontalBarChartTheme extends InheritedTheme {
  /// Applies [style] to every [FluentHorizontalBarChart] in [child].
  const FluentHorizontalBarChartTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the derived defaults.
  final FluentHorizontalBarChartStyle style;

  /// The nearest horizontal-bar-chart style, or null.
  static FluentHorizontalBarChartStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentHorizontalBarChartTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentHorizontalBarChartTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentHorizontalBarChartTheme(style: style, child: child);
}

/// A Fluent 2 horizontal bar chart: one titled strip per data entry, with an
/// optional benchmark marker and a shared legend below.
///
/// There is no d3 here — every position is percentage arithmetic over the row
/// width. See [FluentHorizontalBarRowLayout] for the two upstream defects that
/// arithmetic reproduces.
class FluentHorizontalBarChart extends StatefulWidget {
  /// Creates a horizontal bar chart.
  const FluentHorizontalBarChart({
    super.key,
    required this.data,
    this.barHeight,
    this.hideTooltip = false,
    this.chartDataMode = FluentChartDataMode.byDefault,
    this.variant = FluentHorizontalBarChartVariant.partToWhole,
    this.hideLabels = false,
    this.showTriangle = false,
    this.showLegendForSinglePointBar = false,
    this.culture,
    this.legendsOverflowText = 'more',
    this.style,
  });

  /// One entry per row.
  final List<FluentChartData> data;

  /// Bar height override. Null resolves to 12
  /// (`HorizontalBarChart.tsx:106`).
  final double? barHeight;

  /// Suppresses the hover popover (`HorizontalBarChart.tsx:318-321`).
  final bool hideTooltip;

  /// How the number beside a row is rendered.
  final FluentChartDataMode chartDataMode;

  /// Which scale the row draws against.
  final FluentHorizontalBarChartVariant variant;

  /// Hides the absolute-scale in-bar label (`HorizontalBarChart.tsx:285`).
  final bool hideLabels;

  /// Widens the row spacing to make room for a benchmark marker
  /// (`useHorizontalBarChartStyles.styles.ts:119-125`).
  final bool showTriangle;

  /// Keeps the legend and skips the placeholder synthesis for a single-point
  /// row (`HorizontalBarChart.tsx:400`).
  final bool showLegendForSinglePointBar;

  /// Locale tag for number formatting.
  final String? culture;

  /// Label on the legend overflow control.
  final String legendsOverflowText;

  /// Style layered over the derived defaults and the nearest
  /// [FluentHorizontalBarChartTheme].
  final FluentHorizontalBarChartStyle? style;

  @override
  State<FluentHorizontalBarChart> createState() =>
      _FluentHorizontalBarChartState();
}

class _FluentHorizontalBarChartState extends State<FluentHorizontalBarChart> {
  /// Single-select, toggling (`HorizontalBarChart.tsx:127`). Upstream models
  /// "nothing selected" as the empty string, and the predicate compares
  /// against it literally, so the empty string is kept rather than null.
  String _selectedLegend = '';
  String _activeLegend = '';
  FluentChartDataPoint? _hovered;
  Offset? _anchor;

  /// The chart's own box, so a hover reported in a bar's coordinate space can
  /// be re-expressed in the space the popover is laid out in. Upstream reads
  /// `event.pageX/pageY` (`HorizontalBarChart.tsx:71-72`), which is already
  /// one shared space; Flutter reports per-listener local offsets, so the
  /// conversion is explicit.
  final GlobalKey _plotKey = GlobalKey();

  bool _highlighted(String? legend) => isLegendHighlightedSingleGuarded(
    legend,
    selectedLegend: _selectedLegend,
    activeLegend: _activeLegend,
  );

  bool get _noneHighlighted => _selectedLegend.isEmpty && _activeLegend.isEmpty;

  Offset _toPlot(Offset global) {
    final box = _plotKey.currentContext?.findRenderObject() as RenderBox?;
    return box == null ? global : box.globalToLocal(global);
  }

  /// `HorizontalBarChart.tsx:400-413`. Upstream mutates `props.chartData[1]`
  /// in place; this port returns a new list, which is the same rendering
  /// without writing through the caller's data.
  // ponytail: no prop mutation — the upstream in-place write at :404 is a
  // React escape hatch, not a rendering rule.
  (List<FluentChartDataPoint>, bool) _pointsFor(
    FluentChartData row,
    Color placeholderColour,
  ) {
    final points = row.chartData ?? const <FluentChartDataPoint>[];
    final isSingleBar = widget.showLegendForSinglePointBar
        ? false
        : points.length == 1 || (points.length > 1 && points[1].legend == '');
    if (!isSingleBar || points.isEmpty) return (points, isSingleBar);
    final first = points.first;
    final total = first.horizontalBarChartData?.total ?? 0;
    final value = first.horizontalBarChartData?.x ?? 0;
    return (
      <FluentChartDataPoint>[
        first,
        FluentChartDataPoint(
          placeHolder: true,
          legend: '',
          color: placeholderColour,
          horizontalBarChartData: FluentHorizontalDataPoint(
            x: total - value,
            total: total,
          ),
        ),
        ...points.skip(2),
      ],
      true,
    );
  }

  /// `_getAriaLabel` (`HorizontalBarChart.tsx:335-343`).
  String _ariaLabel(FluentChartDataPoint point) {
    final legend = point.xAxisCalloutData ?? point.legend;
    final bar = point.horizontalBarChartData;
    // :340 is a template literal over raw numbers, not formatToLocaleString:
    // a JavaScript 30 prints as `30`, which is what jsNumberToString gives and
    // what Dart's own `toString` would render as `30.0`.
    final value =
        point.yAxisCalloutData ??
        (bar == null
            ? '0'
            : '${d3.jsNumberToString(bar.x)}/'
                  '${bar.total == null ? '' : d3.jsNumberToString(bar.total!)}');
    return '${legend == null || legend.isEmpty ? '' : '$legend, '}$value.';
  }

  /// `_getDefaultTextData` (`HorizontalBarChart.tsx:142-190`).
  Widget? _valueText(
    FluentChartData row,
    bool isSingleBar,
    FluentHorizontalBarChartStyle resolved,
  ) {
    if (widget.variant == FluentHorizontalBarChartVariant.absoluteScale) {
      // HorizontalBarChart.tsx:416-417.
      return null;
    }
    // HorizontalBarChart.tsx:145-147.
    if (widget.chartDataMode == FluentChartDataMode.hidden) return null;
    const states = <WidgetState>{};
    final valueStyle = resolved.valueTextStyle!.resolve(states);
    final points = row.chartData ?? const <FluentChartDataPoint>[];
    if (points.isEmpty) return null;
    final bar = points.first.horizontalBarChartData;
    final x = bar?.x ?? 0;
    final total = bar?.total;
    if (!isSingleBar) {
      // HorizontalBarChart.tsx:151-161 — a multi-segment row ignores the mode
      // and always shows the summed value.
      final sum = points.fold<double>(
        0,
        (acc, p) => acc + (p.horizontalBarChartData?.x ?? 0),
      );
      return Text(
        formatToLocaleString(sum, culture: widget.culture),
        style: valueStyle,
      );
    }
    return switch (widget.chartDataMode) {
      FluentChartDataMode.hidden => null,
      FluentChartDataMode.byDefault => Text(
        formatToLocaleString(x, culture: widget.culture),
        style: valueStyle,
      ),
      // HorizontalBarChart.tsx:176-181 — the spaces round the slash are
      // literal, and the two spans carry different type.
      FluentChartDataMode.fraction => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            formatToLocaleString(x, culture: widget.culture),
            style: valueStyle,
          ),
          Text(
            ' / ${formatToLocaleString(total, culture: widget.culture)}',
            style: resolved.denominatorTextStyle!.resolve(states),
          ),
        ],
      ),
      // HorizontalBarChart.tsx:183. A zero total is Infinity in JavaScript and
      // `Math.round(Infinity)` stays Infinity, which renders as the string
      // "∞%"; the guard shows 0% instead rather than feeding a non-finite
      // number to a formatter.
      FluentChartDataMode.percentage => Text(
        '${formatToLocaleString(total == null || total == 0 ? 0 : d3.jsRound(x / total * 100), culture: widget.culture)}%',
        style: valueStyle,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      // HorizontalBarChart.tsx:497 — a hidden role="alert".
      return Semantics(
        container: true,
        liveRegion: true,
        label: 'Graph has no data to display',
        child: const SizedBox.shrink(),
      );
    }

    final theme = FluentTheme.of(context);
    final resolved = resolveFluentHorizontalBarChartStyle(
      theme,
    ).merge(FluentHorizontalBarChartTheme.maybeOf(context)).merge(widget.style);
    const states = <WidgetState>{};
    final chartColours = FluentChartColors.of(theme);
    final direction = Directionality.of(context);
    final barHeight = widget.barHeight ?? resolved.barHeight!.resolve(states)!;
    final palette = resolved.defaultPalette!.resolve(states)!;
    final placeholderColour = resolved.placeholderColor!.resolve(states)!;

    var lastRowWasSingleBar = false;
    final rows = <Widget>[];
    for (final row in widget.data) {
      final (points, isSingleBar) = _pointsFor(row, placeholderColour);
      // Design spec §5.7 bounded-cardinality exemption: this chart mints one
      // `Focus` per bar (see `_buildRow`) instead of holding a roving index,
      // because a row's mark count is bounded by its category count — the row
      // is a handful of legends, and `HorizontalBarChart.tsx:219-221` sizes the
      // whole row off that same count. The exemption is only sound inside that
      // bound, so it is asserted rather than assumed. 32 is the ceiling: an
      // order of magnitude above any realistic row and an order of magnitude
      // below the 500-mark series §5.7 names as the reason the roving model
      // exists at all.
      assert(
        points.length <= 32,
        'FluentHorizontalBarChart mints one Focus per bar under design spec '
        '§5.7\'s bounded-cardinality exemption; ${points.length} bars in one '
        'row exceeds the 32-mark bound that exemption depends on. Use a '
        'cartesian bar chart for a series this long.',
      );
      lastRowWasSingleBar = isSingleBar;
      rows.add(
        _buildRow(
          row: row,
          points: points,
          isSingleBar: isSingleBar,
          resolved: resolved,
          chartColours: chartColours,
          palette: palette,
          barHeight: barHeight,
          direction: direction,
        ),
      );
    }

    final legendItems = <FluentChartLegendItem>[
      for (final row in widget.data)
        for (final point in row.chartData ?? const <FluentChartDataPoint>[])
          FluentChartLegendItem(
            title: point.legend ?? '',
            color: point.color ?? const Color(0x00000000),
            onAction: () => setState(() {
              // HorizontalBarChart.tsx:127 — toggle.
              _selectedLegend = _selectedLegend == point.legend
                  ? ''
                  : point.legend ?? '';
            }),
            onHoverAction: () => setState(() {
              // HorizontalBarChart.tsx:128-131 — the hover action closes the
              // popover first, then records the active legend.
              _hovered = null;
              _anchor = null;
              _activeLegend = point.legend ?? '';
            }),
            onMouseOutAction: ({required bool isLegendFocused}) =>
                setState(() => _activeLegend = ''),
          ),
    ];

    return Semantics(
      container: true,
      child: MouseRegion(
        // HorizontalBarChart.tsx:95-103, wired at :393 — the popover only
        // closes when the pointer leaves the whole chart. Leaving one bar for
        // another does nothing, because _hoverOff at :91-93 is an empty
        // function marked "ToDo. To fix".
        // parity: HorizontalBarChart.tsx:91-93.
        onExit: (_) => setState(() {
          _hovered = null;
          _anchor = null;
        }),
        child: Stack(
          key: _plotKey,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ...rows,
                if (!lastRowWasSingleBar)
                  // HorizontalBarChart.tsx:485 — the legend strip is gated on
                  // the value isSingleBar holds AFTER the last row was mapped,
                  // so a mixed data set is decided by its final row.
                  // parity: HorizontalBarChart.tsx:485.
                  Padding(
                    padding: EdgeInsets.only(
                      top: resolved.legendTopPadding!.resolve(states)!,
                    ),
                    child: FluentChartLegend(
                      legends: legendItems,
                      centerLegends: true,
                      overflowText: widget.legendsOverflowText,
                    ),
                  ),
              ],
            ),
            if (!widget.hideTooltip && _hovered != null && _anchor != null)
              Positioned.fill(
                child: FluentChartPopover(
                  data: FluentChartPopoverData(
                    // HorizontalBarChart.tsx:465-484 never passes XValue, so
                    // the popover's top row is empty upstream too.
                    // parity: HorizontalBarChart.tsx:465-484.
                    legend: _hovered!.xAxisCalloutData ?? _hovered!.legend,
                    yValue:
                        _hovered!.yAxisCalloutData ??
                        formatToLocaleString(
                          _hovered!.horizontalBarChartData?.x ?? 0,
                          culture: widget.culture,
                        ),
                    color: _hovered!.color,
                  ),
                  anchor: _anchor!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow({
    required FluentChartData row,
    required List<FluentChartDataPoint> points,
    required bool isSingleBar,
    required FluentHorizontalBarChartStyle resolved,
    required FluentChartColors chartColours,
    required List<Color> palette,
    required double barHeight,
    required TextDirection direction,
  }) {
    const states = <WidgetState>{};
    final isAbsolute =
        widget.variant == FluentHorizontalBarChartVariant.absoluteScale;
    final benchmark = points.isEmpty ? null : points.first.data;
    final total = points.isEmpty
        ? null
        : points.first.horizontalBarChartData?.total;

    return Padding(
      padding: EdgeInsets.only(
        bottom: widget.showTriangle || isAbsolute
            ? resolved.rowSpacingWithTriangle!.resolve(states)!
            : resolved.rowSpacing!.resolve(states)!,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = FluentHorizontalBarRowLayout.compute(
            points: points,
            rowWidth: constraints.maxWidth,
            barGap: resolved.barGap!.resolve(states)!,
            isRtl: direction == TextDirection.rtl,
          );
          final dimmed = resolved.dimmedOpacity!.resolve(states)!;
          // HorizontalBarChart.tsx:284 — only the absolute-scale variant swaps
          // the placeholder rect for a text.
          final placeholderIndex = isAbsolute
              ? points.indexWhere((p) => p.placeHolder)
              : -1;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(
                  bottom: isAbsolute
                      ? resolved.titleBottomSpacingAbsolute!.resolve(states)!
                      : resolved.titleBottomSpacing!.resolve(states)!,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        row.chartTitle ?? '',
                        style: resolved.titleTextStyle!.resolve(states),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    _valueText(row, isSingleBar, resolved) ??
                        const SizedBox.shrink(),
                  ],
                ),
              ),
              if (benchmark != null && benchmark > 0 && total != null)
                SizedBox(
                  // useHorizontalBarChartStyles.styles.ts:78-83 — the
                  // container is 7 tall with -3 top and -1 bottom margins, so
                  // it consumes 3 of vertical flow and overlaps its
                  // neighbours.
                  // parity: useHorizontalBarChartStyles.styles.ts:80-82.
                  height: 3,
                  child: OverflowBox(
                    maxHeight: resolved.benchmarkHeight!.resolve(states),
                    alignment: Alignment.topCenter,
                    child: CustomPaint(
                      painter: FluentBenchmarkTrianglePainter(
                        ratio: FluentBenchmarkTrianglePainter.ratioFor(
                          benchmark: benchmark,
                          total: total,
                        ),
                        colour: resolved.benchmarkColor!.resolve(states)!,
                        triangleWidth: resolved.benchmarkWidth!.resolve(
                          states,
                        )!,
                        triangleHeight: resolved.benchmarkHeight!.resolve(
                          states,
                        )!,
                      ),
                    ),
                  ),
                ),
              SizedBox(
                height: barHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    CustomPaint(
                      size: Size(constraints.maxWidth, barHeight),
                      painter: FluentHorizontalBarStripPainter(
                        layout: layout,
                        fills: <Color>[
                          for (var i = 0; i < points.length; i++)
                            chartColours.flattenMark(
                              points[i].color ??
                                  // parity: HorizontalBarChart.tsx:265 picks
                                  // defaultColors[floor(random() * 4 + 1)] — a
                                  // random index in 1..4 that never selects
                                  // entry 0. Randomness is one of the two
                                  // exceptions in design spec section 5.2, so
                                  // this is the same range made deterministic.
                                  palette[i % 4 + 1],
                            ),
                        ],
                        opacities: <double>[
                          for (final point in points)
                            _highlighted(point.legend) || _noneHighlighted
                                ? 1.0
                                : dimmed,
                        ],
                        barHeight: barHeight,
                        textDirection: direction,
                        absoluteLabelIndex: placeholderIndex == -1
                            ? null
                            : placeholderIndex,
                        absoluteLabel:
                            placeholderIndex == -1 || widget.hideLabels
                            ? null
                            : formatScientificLimitWidth(
                                points.first.horizontalBarChartData?.x ?? 0,
                              ),
                        absoluteLabelStyle: resolved.barLabelTextStyle!.resolve(
                          states,
                        ),
                        absoluteLabelOffset: resolved.barLabelOffset!.resolve(
                          states,
                        )!,
                      ),
                    ),
                    // One Focus per bar, not a roving index — design spec §5.7
                    // bounded-cardinality exemption, bound asserted in `build`
                    // at 32 marks per row.
                    for (var i = 0; i < points.length; i++)
                      if (!points[i].placeHolder)
                        Positioned.fromRect(
                          rect: layout.rectOf(i, barHeight),
                          child: Builder(
                            builder: (barContext) => Focus(
                              // HorizontalBarChart.tsx:322 gives every bar
                              // role="option"; the label is what a test and a
                              // debug dump identify the bar's own focus node
                              // by, against the legend's below it.
                              debugLabel: 'FluentHorizontalBarChart bar',
                              canRequestFocus:
                                  _highlighted(points[i].legend) ||
                                  _noneHighlighted,
                              onFocusChange: (hasFocus) {
                                // HorizontalBarChart.tsx:321 — onFocus is the
                                // same handler as onMouseOver.
                                if (!hasFocus ||
                                    widget.hideTooltip ||
                                    points[i].legend == '') {
                                  return;
                                }
                                final box =
                                    barContext.findRenderObject() as RenderBox?;
                                if (box == null) return;
                                setState(() {
                                  _hovered = points[i];
                                  _anchor = _toPlot(
                                    box.localToGlobal(
                                      box.size.center(Offset.zero),
                                    ),
                                  );
                                });
                              },
                              child: MouseRegion(
                                onHover: (event) {
                                  // HorizontalBarChart.tsx:318-320 — a bar
                                  // whose legend is the empty string, which is
                                  // every synthesised placeholder, has no
                                  // handler at all.
                                  if (widget.hideTooltip ||
                                      points[i].legend == '') {
                                    return;
                                  }
                                  // HorizontalBarChart.tsx:349-360 — the
                                  // popover only moves when the pointer
                                  // travels more than one pixel.
                                  final next = _toPlot(event.position);
                                  if (_anchor != null &&
                                      (_anchor! - next).distance <= 1) {
                                    return;
                                  }
                                  setState(() {
                                    _hovered = points[i];
                                    _anchor = next;
                                  });
                                },
                                child: Semantics(
                                  label: _ariaLabel(points[i]),
                                  button: points[i].onClick != null,
                                  onTap: points[i].onClick,
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
