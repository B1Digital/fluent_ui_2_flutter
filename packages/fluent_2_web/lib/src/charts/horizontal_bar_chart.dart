import 'package:flutter/widgets.dart';

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
