import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'internal/d3/scale.dart';
import 'model/bar_data.dart';

/// Fraction of a stack's height that may be spent on gaps
/// (`VerticalStackedBarChart.tsx:64`).
const double kBarGapMultiplier = 0.2;

/// Floor on a gap once gaps are enabled (`VerticalStackedBarChart.tsx:65`).
const double kBarGapMin = 1;

/// The y value a numeric stack is measured from — `Y_ORIGIN`, which upstream
/// fixes at 0 (`VerticalStackedBarChart.tsx:118`).
const double kStackedBarYOrigin = 0;

/// The output of the vertical stacked bar chart's gap-and-scale solve.
@immutable
class FluentStackedBarGapMetrics {
  /// Creates the metrics.
  const FluentStackedBarGapMetrics({
    required this.gapHeight,
    required this.heightValueScale,
    required this.absStackTotal,
  });

  /// Pixels between adjacent segments, 0 when `barGapMax` is 0.
  final double gapHeight;

  /// Pixels per data unit once the gaps have been deducted. Always 0 on a
  /// category y axis.
  final double heightValueScale;

  /// The sum of the segments' absolute values, 0 on a category y axis.
  final double absStackTotal;
}

/// Ports `_getBarGapAndScale` (`VerticalStackedBarChart.tsx:806-847`).
///
/// The subtle part is the one-percent floor: each segment's share is raised to
/// 1% **before** the shares are summed (`:829-835`), so `scalingRatio` can
/// exceed 1 and shrink every segment in the stack. A share of exactly 0 is
/// exempt, which is why the guard reads `v < 1 && v !== 0`.
///
/// [defaultTotalHeight] overrides the height measured through [yBarScale], as
/// upstream's `defaultTotalHeight ??` arms do (`:821-822`, `:827-828`).
FluentStackedBarGapMetrics computeFluentStackedBarGapMetrics({
  required List<FluentStackedBarDatum> bars,
  required Scale yBarScale,
  required bool isStringYAxis,
  required double barGapMax,
  double? defaultTotalHeight,
}) {
  double totalData = 0;
  final double totalHeight;
  double scalingRatio = 1;

  if (isStringYAxis) {
    totalHeight =
        defaultTotalHeight ??
        bars.fold<double>(
          0,
          (double acc, FluentStackedBarDatum b) =>
              acc + (yBarScale(b.data) ?? 0),
        );
  } else {
    for (final b in bars) {
      totalData += (b.data as num).toDouble().abs();
    }
    totalHeight =
        defaultTotalHeight ??
        ((yBarScale(totalData) ?? 0) - (yBarScale(kStackedBarYOrigin) ?? 0))
            .abs();
    double sumOfPercent = 0;
    for (final b in bars) {
      // `:830` — the share as a percentage, then the floor at `:831-833`.
      var value = ((b.data as num).toDouble().abs() / totalData) * 100;
      if (value < 1 && value != 0) {
        value = 1;
      }
      sumOfPercent += value;
    }
    scalingRatio = sumOfPercent != 0 ? sumOfPercent / 100 : 1;
  }

  // `gaps = barGapMax && bars.length - 1` (`:838`) — JS `&&` yields 0, not
  // false, when barGapMax is 0.
  final gaps = barGapMax == 0 ? 0.0 : (bars.length - 1).toDouble();
  final gapHeight = gaps == 0
      ? 0.0
      : math.max(
          kBarGapMin,
          math.min(barGapMax, (totalHeight * kBarGapMultiplier) / gaps),
        );
  return FluentStackedBarGapMetrics(
    gapHeight: gapHeight,
    heightValueScale: isStringYAxis
        ? 0
        : (totalHeight - gapHeight * gaps) / (totalData * scalingRatio),
    absStackTotal: totalData,
  );
}
