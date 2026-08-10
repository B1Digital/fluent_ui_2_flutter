import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/d3/js_math.dart' as d3;
import 'model/bar_data.dart';

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
