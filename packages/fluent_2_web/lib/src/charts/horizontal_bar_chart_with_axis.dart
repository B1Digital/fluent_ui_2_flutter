import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'internal/d3/scale.dart';
import 'model/bar_data.dart';
import 'model/chart_common.dart';

/// One placed segment inside a horizontal bar group.
@immutable
class FluentHorizontalBarWithAxisSegment {
  /// Creates a segment.
  const FluentHorizontalBarWithAxisSegment({
    required this.xStart,
    required this.width,
    required this.endX,
    required this.index,
    required this.isPositive,
    required this.showLabel,
  });

  /// Leading edge in plot coordinates.
  final double xStart;

  /// Width after the 2px inter-segment gap has been removed.
  final double width;

  /// Trailing edge in the value direction, where the group label anchors.
  final double endX;

  /// Index inside the group.
  final int index;

  /// Whether the point's value is at or above zero.
  final bool isPositive;

  /// Whether this segment carries the group's total label.
  final bool showLabel;
}

/// A set of points sharing a y category, drawn as one stacked bar.
@immutable
class FluentHorizontalBarGroup {
  /// Creates a group.
  const FluentHorizontalBarGroup({
    required this.yValue,
    required this.points,
    required this.total,
    required this.showLabel,
  });

  /// The shared y category.
  final Object yValue;

  /// The points, in insertion order.
  final List<FluentHorizontalBarChartWithAxisDataPoint> points;

  /// The plain sum of the group's x values.
  final double total;

  /// Whether the label goes on the last positive bar rather than the last
  /// negative one.
  final bool showLabel;
}

/// Pure layout maths for the horizontal bar chart with an axis, over
/// [FluentHorizontalBarChartWithAxisDataPoint] groups.
abstract final class FluentHorizontalBarChartGeometry {
  /// The inter-segment gap in pixels (`HorizontalBarChartWithAxis.tsx:438`,
  /// `:444`).
  static const double kSegmentGap = 2;

  /// The value the bars grow from — `X_ORIGIN`
  /// (`HorizontalBarChartWithAxis.tsx:80`).
  static const double kXOrigin = 0;

  /// Ports `_calculateBarTotals` (`HorizontalBarChartWithAxis.tsx:345-369`).
  ///
  /// Upstream sums the positive and the negative points separately and adds the
  /// two, which is the plain sum, and puts the group's label on the last bar of
  /// whichever side the sign of that sum names (`:352-353`, `:359-366`).
  static ({double total, bool showLabelOnLastPositive}) totalsFor(
    List<FluentHorizontalBarChartWithAxisDataPoint> group,
  ) {
    var total = 0.0;
    for (final point in group) {
      total += point.x;
    }
    return (total: total, showLabelOnLastPositive: total >= 0);
  }

  /// Ports the per-point block of `_createNumericBars` / `_createStringBars`
  /// (`HorizontalBarChartWithAxis.tsx:404-465`, `:583-640`).
  ///
  /// `prevPoint` deliberately lags one iteration: the accumulator is advanced
  /// from the *previous* point's value before `xStart` is computed, so the
  /// first segment contributes no offset. The two upstream variants assign
  /// `prevPoint` at different lines (`:455` after, `:626` before) yet agree,
  /// because `xStart` reads the accumulators rather than `prevPoint`.
  ///
  /// Only the x geometry lives here. The y placement differs between the two
  /// variants — the numeric one centres on `yBarScale(y)` (`:468`) while the
  /// string one adds half the leftover bandwidth (`:643`) — and belongs to the
  /// delegate that knows which scale it holds.
  static List<FluentHorizontalBarWithAxisSegment> layOutGroup({
    required List<FluentHorizontalBarChartWithAxisDataPoint> group,
    required Scale xBarScale,
    required double containerWidth,
    required FluentChartMargins margins,
    required bool isRtl,
  }) {
    final originPx = xBarScale(kXOrigin)!;
    final totalPositive = group.where((point) => point.x >= kXOrigin).length;
    final totalNegative = group.length - totalPositive;
    final totals = totalsFor(group);

    var prevWidthPositive = 0.0;
    var prevWidthNegative = 0.0;
    var prevPoint = 0.0;
    var currPositive = 0;
    var currNegative = 0;

    final out = <FluentHorizontalBarWithAxisSegment>[];
    for (var index = 0; index < group.length; index++) {
      final x = group[index].x;
      if (x >= kXOrigin) {
        currPositive++;
      }
      if (x < kXOrigin) {
        currNegative++;
      }
      // `.tsx:415-418`. The RTL arm mirrors the bar's leading edge about the
      // plot, so it is the only place the container width and the margins are
      // read.
      final barStartX = isRtl
          ? containerWidth -
                ((margins.right ?? 0) +
                    math.max(xBarScale(x)!, originPx) -
                    (margins.left ?? 0))
          : math.min(xBarScale(x)!, originPx);

      final prevBarWidth = (xBarScale(prevPoint)! - originPx).abs();
      if (prevPoint > kXOrigin) {
        prevWidthPositive += prevBarWidth;
      } else {
        prevWidthNegative += prevBarWidth;
      }
      final currentWidth = (xBarScale(x)! - originPx).abs();
      // `.tsx:436-442`: every positive bar but the last is trimmed, and a
      // negative bar is trimmed whenever anything can sit beside it.
      final gapLtr =
          currentWidth > kSegmentGap &&
              ((x > kXOrigin && currPositive != totalPositive) ||
                  (x < kXOrigin && (totalPositive != 0 || currNegative > 1)))
          ? kSegmentGap
          : 0.0;
      // `.tsx:443-448`: the mirror image — the negative side keeps its last bar
      // whole and the positive side is trimmed whenever anything can sit beside
      // it. Note this is *not* the LTR rule with the sides swapped: an RTL
      // group's last positive bar is trimmed, its LTR twin is not.
      final gapRtl =
          currentWidth > kSegmentGap &&
              ((x > kXOrigin && (totalNegative != 0 || currPositive > 1)) ||
                  (x < kXOrigin && currNegative != totalNegative))
          ? kSegmentGap
          : 0.0;
      // `.tsx:449-454`.
      final double xStart;
      if (isRtl) {
        xStart = x > kXOrigin
            ? barStartX - prevWidthPositive
            : barStartX + prevWidthNegative;
      } else {
        xStart = x > kXOrigin
            ? barStartX + prevWidthPositive
            : barStartX - prevWidthNegative;
      }
      prevPoint = x;
      final width = currentWidth - (isRtl ? gapRtl : gapLtr);
      final isPositive = x >= kXOrigin;
      // `.tsx:458-464`.
      final double endX;
      if (isRtl) {
        endX = isPositive ? xStart : xStart + width;
      } else {
        endX = isPositive ? xStart + width : xStart;
      }
      out.add(
        FluentHorizontalBarWithAxisSegment(
          xStart: xStart,
          width: width,
          endX: endX,
          index: index,
          isPositive: isPositive,
          // `shouldShowLabel` (`.tsx:359-366`), whose two counters are the ones
          // already advanced above.
          showLabel: totals.showLabelOnLastPositive
              ? isPositive && currPositive == totalPositive
              : !isPositive && currNegative == totalNegative,
        ),
      );
    }
    return out;
  }
}
