import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';
import 'axis/tick_format.dart';
import 'chrome/chart_popover.dart';
import 'chrome/legend.dart';
import 'horizontal_bar_chart_style.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/chart_utils.dart';
import 'internal/d3/js_math.dart' as d3;
import 'internal/overlay_chart_popover.dart';
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
/// A port of `_createBars` (`HorizontalBarChart.tsx:218-333`), kept pure so
/// its arithmetic can be asserted numerically without a widget tree. It departs
/// from upstream only where upstream overflows the row; see [compute].
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
  ///
  /// Upstream means to shrink the bars into the room the gaps leave
  /// (`:253-261`), but two errors turn that into an overflow. It counts its
  /// bars from `point.data` (`:219-221`), which is the BENCHMARK field
  /// (types/DataPoint.ts:112-159), so an ordinary row counts one bar and
  /// reserves no room. It then DIVIDES by the scaling ratio (`:274`, `:276`),
  /// which would grow the bars as soon as there was room to reserve. The bars
  /// always fill 100%, and the gaps push a row of n bars `(n - 1) * barGap` px
  /// past its edge (past its leading edge under RTL). This port counts the bars
  /// that paint, shrinks them into the room the gaps leave, and offsets each
  /// one by the gaps before it, so the row ends at [rowWidth].
  ///
  /// [absoluteLabelIndex] is the placeholder that the absolute-scale variant
  /// draws as a label instead of a bar (`:284`). It takes no gap, so the value
  /// bar keeps its exact share of the scale.
  static FluentHorizontalBarRowLayout compute({
    required List<FluentChartDataPoint> points,
    required double rowWidth,
    required double barGap,
    required bool isRtl,
    int? absoluteLabelIndex,
  }) {
    // HorizontalBarChart.tsx:366 — the gap is converted to a percentage of the
    // same width every x is a percentage of, so it resolves back to exactly
    // `barGap` pixels between neighbouring bars.
    final gapPercent = rowWidth == 0 ? 0.0 : (barGap / rowWidth) * 100;

    // A bar is spaced from the next when it paints: its share is positive (a
    // zero or negative share is zero wide) and it is not the label.
    bool takesGap(int index, double share) =>
        share > 0 && index != absoluteLabelIndex;

    // HorizontalBarChart.tsx:232-236 — a null or zero x contributes nothing.
    var total = 0.0;
    for (final point in points) {
      total += point.horizontalBarChartData?.x ?? 0;
    }

    // Pass one: the clamped sum (HorizontalBarChart.tsx:240-252), and the bars
    // that upstream's `noOfBars` (:219-221) means to count.
    var sumOfPercent = 0.0;
    var barCount = 0;
    for (var index = 0; index < points.length; index++) {
      final pointData = points[index].horizontalBarChartData?.x ?? 0;
      var value = total == 0 ? 0.0 : (pointData / total) * 100;
      if (takesGap(index, value)) barCount++;
      if (value < 0) {
        value = 0;
      } else if (value < 1 && value != 0) {
        // The clamp target in pass one is a flat 1, unlike pass two.
        value = 1;
      }
      sumOfPercent += value;
    }
    final totalMarginPercent = barCount < 2 ? 0.0 : gapPercent * (barCount - 1);

    // HorizontalBarChart.tsx:262, inverted: pass two divides by this ratio, so
    // the bars scale down to the `100 - totalMarginPercent` the gaps leave.
    // ponytail: a row narrower than its own gaps paints zero-width bars; shrink
    // the gap instead if such rows ever matter.
    final scalingRatio = sumOfPercent != 0
        ? sumOfPercent / (100 - totalMarginPercent).clamp(0.0, 100.0)
        : 1.0;

    // Pass two: positions (HorizontalBarChart.tsx:264-278).
    final segments = <FluentHorizontalBarSegment>[];
    var prevPosition = 0.0;
    var value = 0.0;
    var gaps = 0;
    for (var index = 0; index < points.length; index++) {
      // parity: the accumulator adds the PREVIOUS iteration's value before
      // this one is computed (HorizontalBarChart.tsx:267-269), so it lags by
      // one step. Reordering these two statements moves every bar.
      if (index > 0) prevPosition += value;
      final pointData = points[index].horizontalBarChartData?.x ?? 0;
      value = total == 0 ? 0.0 : (pointData / total) * 100;
      final spaced = takesGap(index, value);
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
          // HorizontalBarChart.tsx:311-312 offset by `index` gaps, which also
          // counts the gap after a zero-width bar; this counts only the gaps
          // after the painted bars before this one.
          xPercent: isRtl
              ? 100 - startPercent - value - gaps * gapPercent
              : startPercent + gaps * gapPercent,
        ),
      );
      if (spaced) gaps++;
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
  /// No bar extends past [rowWidth]: [compute] makes room for the gaps that
  /// upstream lets overflow.
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
/// not clip: the absolute-scale label of a full bar starts past the row edge
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
        // `opacity` is an SVG presentation attribute (HorizontalBarChart.tsx
        // :327): it composites the element at that factor, so it MULTIPLIES
        // the fill's own alpha rather than replacing it. The synthesised
        // remainder bar is `colorBackgroundOverlay`, rgba(0, 0, 0, 0.4)
        // (:411) — replacing its alpha with the 1.0 that "not dimmed" means
        // paints it solid black instead of the grey upstream shows.
        Paint()..color = fill.withValues(alpha: fill.a * opacities[i]),
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
/// width. See [FluentHorizontalBarRowLayout.compute] for where that arithmetic
/// departs from upstream.
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
    this.legendsOverflowText,
    this.legends,
    this.enabledWrapLines = false,
    this.calloutPropsPerDataPoint,
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
  ///
  /// Null takes the wording from the ambient [FluentLocalizations],
  /// which falls back to English when no delegate is installed.
  final String? legendsOverflowText;

  /// The legend rows, in place of the ones the chart derives from [data] —
  /// `legendProps.legends`.
  ///
  /// `HorizontalBarChart.tsx:138` spreads `props.legendProps` after its own
  /// props, so these replace the derived rows outright, select-and-dim wiring
  /// included: a row here only dims the bars if it carries its own
  /// [FluentChartLegendItem.onAction]. Null keeps the derived rows.
  final List<FluentChartLegendItem>? legends;

  /// Whether the legend wraps onto further lines instead of collapsing into an
  /// overflow menu — `legendProps.enabledWrapLines`, spread the same way as
  /// [legends]. Only a wrapped legend renders a row's
  /// [FluentChartLegendItem.annotationBuilder] (`Legends.tsx:163`).
  final bool enabledWrapLines;

  /// Overrides for the hover popover of one bar — `calloutPropsPerDataPoint`
  /// (`HorizontalBarChart.tsx:479-481`).
  ///
  /// `ChartPopover.tsx:41` spreads the result over the chart's own props, so
  /// every non-null field of the returned data wins, except that the point's
  /// `xAxisCalloutData` and `yAxisCalloutData` still take the legend and value
  /// lines (`:43-44`). A [FluentChartPopoverData.customContentBuilder] replaces
  /// the body, which is what `onRenderCalloutPerHorizontalBar` does upstream
  /// (`:54`). Returning null keeps the default popover for that bar.
  final FluentChartPopoverData? Function(FluentChartDataPoint point)?
  calloutPropsPerDataPoint;

  /// Style layered over the derived defaults and the nearest
  /// [FluentHorizontalBarChartTheme].
  final FluentHorizontalBarChartStyle? style;

  @override
  State<FluentHorizontalBarChart> createState() =>
      _FluentHorizontalBarChartState();
}

class _FluentHorizontalBarChartState extends State<FluentHorizontalBarChart> {
  /// The benchmark container is 7 tall with a -3 top and a -1 bottom margin
  /// (useHorizontalBarChartStyles.styles.ts:80-82): 3 of vertical flow, and a
  /// box that starts 3 above it.
  static const double _benchmarkFlow = 3;
  static const double _benchmarkMarginTop = 3;

  /// Single-select, toggling (`HorizontalBarChart.tsx:127`). Upstream models
  /// "nothing selected" as the empty string, and the predicate compares
  /// against it literally, so the empty string is kept rather than null.
  String _selectedLegend = '';
  String _activeLegend = '';

  /// The point the popover reads from, `barCalloutProps`
  /// (`HorizontalBarChart.tsx:44`).
  FluentChartDataPoint? _hovered;

  /// `clickPosition` (`HorizontalBarChart.tsx:47`), in global coordinates like
  /// the `clientX`/`clientY` it is set from, or null once the popover closes.
  ///
  /// Upstream keeps it across a close, so a pointer or a focus that comes back
  /// within a pixel of it fails updatePosition's threshold (:356) and opens
  /// nothing at all: a bar focused, left and focused again stays silent. The
  /// port forgets it instead.
  Offset? _anchor;

  /// `isPopoverOpen` (`HorizontalBarChart.tsx:46`).
  ///
  /// The popover floats in the app's [Overlay]. `ChartPopover.tsx:47-51` is an
  /// inline Popover positioned against its clipping ancestors, and nothing in
  /// `fui-hbc__root` clips (`useHorizontalBarChartStyles.styles.ts:33-38`), so
  /// its boundary is the viewport: over the basic story's first bar the
  /// surface opens at x 11, 29px left of the chart.
  final OverlayPortalController _popover = OverlayPortalController();

  bool _highlighted(String? legend) => isLegendHighlightedSingleGuarded(
    legend,
    selectedLegend: _selectedLegend,
    activeLegend: _activeLegend,
  );

  bool get _noneHighlighted => _selectedLegend.isEmpty && _activeLegend.isEmpty;

  /// `_hoverOn` (`HorizontalBarChart.tsx:55-89`), which a bar runs when the
  /// pointer enters it (`onMouseOver`) and when it takes focus, at [position].
  void _hoverOn(FluentChartDataPoint point, Offset position) {
    // :60-64. Upstream also skips the point `_calloutAnchorPoint` holds, but
    // that is a plain `let` every render declares afresh, so the test never
    // holds by the time an event reads it.
    if ((_popover.isShowing && _hovered?.legend == point.legend) ||
        !(_highlighted(point.legend) || _noneHighlighted)) {
      return;
    }
    setState(() {
      _hovered = point;
      // updatePosition (:349-360): the anchor moves, and the popover opens,
      // only once the position is more than a pixel from the last one.
      final anchor = _anchor;
      if (anchor == null || (position - anchor).distance > 1) {
        _anchor = position;
        _popover.show();
      }
    });
  }

  /// `_handleChartMouseLeave` (`HorizontalBarChart.tsx:95-103`).
  void _closePopover() {
    _anchor = null;
    if (_popover.isShowing) _popover.hide();
  }

  /// The popover's reading for [point], with [FluentHorizontalBarChart
  /// .calloutPropsPerDataPoint] spread over it (`ChartPopover.tsx:41`).
  FluentChartPopoverData _popoverData(FluentChartDataPoint point) {
    final custom = widget.calloutPropsPerDataPoint?.call(point);
    // JavaScript truthiness: `ChartPopover.tsx:43-44` skip an empty string.
    String? truthy(String? value) =>
        value == null || value.isEmpty ? null : value;
    final culture = custom?.culture ?? widget.culture;
    return FluentChartPopoverData(
      // HorizontalBarChart.tsx:465-484 passes no XValue, so only a custom one
      // shows a heading.
      xValue: custom?.xValue,
      yValues: custom?.yValues,
      // :43, formatted at :80.
      legend: formatToLocaleString(
        truthy(point.xAxisCalloutData) ?? custom?.legend ?? point.legend,
        culture: culture,
      ),
      // :44, formatted at :89. YValue is the bar's x (:319, :81).
      yValue: formatToLocaleString(
        truthy(point.yAxisCalloutData) ??
            custom?.yValue ??
            point.horizontalBarChartData?.x ??
            0,
        culture: culture,
      ),
      color: custom?.color ?? point.color,
      ratio: custom?.ratio,
      descriptionMessage: custom?.descriptionMessage,
      isCalloutForStack: custom?.isCalloutForStack ?? false,
      customContentBuilder: custom?.customContentBuilder,
      culture: culture,
      // :483. Kept even under custom data, whose own default is the cartesian
      // `true` rather than a value the caller chose.
      isCartesian: false,
      contentMaxWidth: custom?.contentMaxWidth,
    );
  }

  Widget _buildPopover(BuildContext context) {
    final point = _hovered;
    final anchor = _anchor;
    // Upstream's ChartPopover (HorizontalBarChart.tsx:465) is not gated on
    // hideTooltip, so turning it on leaves an open popover up until the
    // pointer leaves. Read here, it empties at once. The controller cannot be
    // hidden from didUpdateWidget instead, which runs during build.
    if (widget.hideTooltip || point == null || anchor == null) {
      return const SizedBox.shrink();
    }
    // The anchor is the pointer on the screen. Transparent to the pointer, so
    // a surface laid over the bars neither swallows their hover nor reads as
    // the pointer leaving the chart.
    return buildFluentOverlayChartPopover(
      context,
      anchorRect: Rect.fromLTWH(anchor.dx, anchor.dy, 0, 0),
      data: _popoverData(point),
    );
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
    // :342 heads the chain with `point.callOutAccessibilityData?.ariaLabel ||`,
    // so an author's label replaces the composed sentence outright and an empty
    // one falls through to it — the same `||` reading as `ariaLabelFor` in
    // `horizontal_bar_chart_with_axis.dart`.
    final override = point.callOutSemantics?.label;
    if (override != null && override.isNotEmpty) {
      return override;
    }
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

  /// `getAccessibleDataObject` (`utilities.ts:1780-1799`), spread onto the row
  /// title at `HorizontalBarChart.tsx:436` and onto the row value at `:150`.
  ///
  /// It hangs `role="text"` beside the `aria-label`, so the element announces
  /// the author's string INSTEAD of the text inside it — hence
  /// [Semantics.excludeSemantics]. The container matters just as much: without
  /// one the annotation is absorbed into the chart's own node and concatenated
  /// with the visible string rather than replacing it. `aria-describedby`
  /// (:1797) is dropped for the same reason `FluentChartMarkSemantics` drops
  /// `aria-labelledby` — these two slots are named, not described.
  Widget _labelled(String? label, Widget child) =>
      label == null || label.isEmpty
      ? child
      : Semantics(
          container: true,
          label: label,
          excludeSemantics: true,
          child: child,
        );

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
        label: fluentL10n(context).chartNoData,
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
              _closePopover();
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
        onExit: (_) => _closePopover(),
        child: OverlayPortal(
          controller: _popover,
          overlayChildBuilder: _buildPopover,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            // `items` carries the gap as a margin-BOTTOM
            // (useHorizontalBarChartStyles.styles.ts:39-44, selected at
            // :119-125 off two chart-level props), so upstream's gap sits
            // between rows and once more between the last row and the legend
            // container's own 16px padding-top. A `spacing` on the Column
            // reproduces both and, unlike a per-row Padding, leaves no
            // trailing margin below the last row — which is exactly the box
            // the reference is captured at: 8 x 33 + 7 x 10 = 334, seven gaps
            // for eight rows.
            spacing:
                widget.showTriangle ||
                    widget.variant ==
                        FluentHorizontalBarChartVariant.absoluteScale
                ? resolved.rowSpacingWithTriangle!.resolve(states)!
                : resolved.rowSpacing!.resolve(states)!,
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
                  // HorizontalBarChart.tsx:138 — `legendProps` is spread
                  // last, so its rows and wrapping win.
                  child: FluentChartLegend(
                    legends: widget.legends ?? legendItems,
                    centerLegends: true,
                    enabledWrapLines: widget.enabledWrapLines,
                    overflowText: widget.legendsOverflowText,
                  ),
                ),
            ],
          ),
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
    final showBenchmark = benchmark != null && benchmark > 0 && total != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // HorizontalBarChart.tsx:284 — only the absolute-scale variant swaps
        // the placeholder rect for a text.
        final placeholderIndex = isAbsolute
            ? points.indexWhere((p) => p.placeHolder)
            : -1;
        final layout = FluentHorizontalBarRowLayout.compute(
          points: points,
          rowWidth: constraints.maxWidth,
          barGap: resolved.barGap!.resolve(states)!,
          isRtl: direction == TextDirection.rtl,
          absoluteLabelIndex: placeholderIndex == -1 ? null : placeholderIndex,
        );
        final dimmed = resolved.dimmedOpacity!.resolve(states)!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // `chartTitle` is a `display: flex` row
            // (useHorizontalBarChartStyles.styles.ts:52-56) and the title gap
            // hangs on the LEFT span alone — `chartTitleLeft5pMargin`, or 4
            // for absolute-scale (:64-69, selected at :129-136). So the flex
            // line is max(caption1 16 + gap, body1Strong 20) = 21, not
            // max(16, 20) + gap = 25, and both spans sit at its top. Oracle B
            // measures the `fui-hbc__chartTitle` box at 21 tall with
            // `chartTitleLeft` 16 tall at the same y, and the row pitch at
            // 43 = 21 + svg 12 + items margin 10.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                // HorizontalBarChart.tsx:432 — an absent title renders no
                // left span at all, and `space-between` then leaves the value
                // at the start of the line.
                if (row.chartTitle != null && row.chartTitle!.isNotEmpty)
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: isAbsolute
                            ? resolved.titleBottomSpacingAbsolute!.resolve(
                                states,
                              )!
                            : resolved.titleBottomSpacing!.resolve(states)!,
                      ),
                      child: _labelled(
                        row.chartTitleSemantics?.label,
                        Text(
                          row.chartTitle!,
                          style: resolved.titleTextStyle!.resolve(states),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                // :150 hangs the accessible data on the value element itself,
                // so a row that renders no value — absolute scale, or the
                // hidden mode — carries no label either.
                if (_valueText(row, isSingleBar, resolved) case final value?)
                  _labelled(row.chartDataSemantics?.label, value)
                else
                  const SizedBox.shrink(),
              ],
            ),
            if (showBenchmark)
              // useHorizontalBarChartStyles.styles.ts:78-83 — the container
              // is 7 tall with -3 top and -1 bottom margins, so it consumes 3
              // of vertical flow. The triangle is painted with the bar below.
              // parity: useHorizontalBarChartStyles.styles.ts:80-82.
              const SizedBox(height: _benchmarkFlow),
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
                      absoluteLabel: placeholderIndex == -1 || widget.hideLabels
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
                              // same handler as onMouseOver, anchored at the
                              // bar's centre (:73-77).
                              if (!hasFocus ||
                                  widget.hideTooltip ||
                                  points[i].legend == '') {
                                return;
                              }
                              final box =
                                  barContext.findRenderObject() as RenderBox?;
                              if (box == null) return;
                              _hoverOn(
                                points[i],
                                box.localToGlobal(box.size.center(Offset.zero)),
                              );
                            },
                            child: MouseRegion(
                              // HorizontalBarChart.tsx:318-320 — onMouseOver,
                              // which fires as the pointer enters the bar and
                              // not as it moves on inside, so the popover
                              // stays where it opened. A bar whose legend is
                              // the empty string, which is every synthesised
                              // placeholder, has no handler at all.
                              onEnter: (event) {
                                if (widget.hideTooltip ||
                                    points[i].legend == '') {
                                  return;
                                }
                                // :69-72 — `clientX`/`clientY`, whole pixels.
                                _hoverOn(
                                  points[i],
                                  Offset(
                                    event.position.dx.floorToDouble(),
                                    event.position.dy.floorToDouble(),
                                  ),
                                );
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
                  if (showBenchmark)
                    // `.triangle` is `position: absolute`
                    // (useHorizontalBarChartStyles.styles.ts:92), so it paints
                    // over the svg after it, placeholder bar included. It sits
                    // at the top of its container, whose -3 top margin puts
                    // it 3 above the flow slot: 6 above the bar, its tip 1px
                    // into it.
                    Positioned(
                      left: 0,
                      right: 0,
                      top: -(_benchmarkFlow + _benchmarkMarginTop),
                      height: resolved.benchmarkHeight!.resolve(states),
                      child: IgnorePointer(
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
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
