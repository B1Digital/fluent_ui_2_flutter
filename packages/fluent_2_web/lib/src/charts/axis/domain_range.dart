import 'dart:math' as math;

import '../internal/d3/array_stats.dart' as d3;
import '../model/cartesian_series.dart';
import '../model/chart_common.dart';

/// The data points of a line or scatter series.
///
/// The two series types share no supertype in the data model, and the upstream
/// signatures are a TypeScript union (`utilities.ts:2283`), so the boundary is
/// untyped and this helper narrows it once instead of at each call site.
List<Object> _seriesData(Object series) => switch (series) {
  FluentLineChartSeries() => series.data,
  FluentScatterChartSeries() => series.data,
  _ => const <Object>[],
};

/// The x of a line or scatter data point.
Object? _pointX(Object point) => switch (point) {
  FluentLineChartDataPoint() => point.x,
  FluentScatterChartDataPoint() => point.x,
  _ => null,
};

/// Whether [v] may enter a scale's domain.
///
/// Ports `isValidDomainValue` (`utilities.ts:2273-2275`). Only numbers are ever
/// filtered, and only on a log scale — a [DateTime] on a log scale is never
/// filtered, which is upstream behaviour rather than an oversight worth fixing
/// here.
bool isValidDomainValue(Object? v, FluentAxisScaleType? scaleType) {
  if (v is! num) {
    return true;
  }
  if (scaleType != FluentAxisScaleType.log) {
    return true;
  }
  // Strictly positive, because a log scale is undefined at and below zero
  // (`utilities.ts:2274`).
  return v > 0;
}

/// The x extent across every series in [points], filtered for the scale.
///
/// Ports `getScatterXDomainExtent` (`utilities.ts:2282-2300`). Returns a pair of
/// `num` or [DateTime], or a pair of nulls when everything was filtered out.
/// Upstream asserts non-null with `!` and lets the resulting `NaN` propagate; the
/// port surfaces the null so the caller can decide, and no caller throws.
(Object?, Object?) getScatterXDomainExtent(
  List<Object> points, {
  FluentAxisScaleType? scaleType,
}) {
  final values = <Object>[];
  for (final series in points) {
    for (final point in _seriesData(series)) {
      final x = _pointX(point);
      if (x != null && isValidDomainValue(x, scaleType)) {
        values.add(x);
      }
    }
  }
  if (values.isEmpty) {
    return (null, null);
  }
  return (
    d3.min<Comparable<Object>>(values),
    d3.max<Comparable<Object>>(values),
  );
}

/// How much domain to add at each end of `[minVal, maxVal]` so that markers
/// drawn at the extremes are not clipped.
///
/// Ports `getDomainPaddingForMarkers` (`utilities.ts:2232-2266`). A user-supplied
/// bound that already sits further out than a tenth of the range suppresses the
/// padding on that side, so an explicit axis minimum does not get padded twice.
/// The log branch is deliberately asymmetric — `end` is the raw maximum rather
/// than a delta — and is ported as written.
({double start, double end}) getDomainPaddingForMarkers(
  double minVal,
  double maxVal, {
  FluentAxisScaleType? scaleType,
  double? userMinVal,
  double? userMaxVal,
}) {
  if (scaleType == FluentAxisScaleType.log) {
    // 0.5 is the log-scale start factor at `utilities.ts:2241`.
    return (start: minVal * 0.5, end: maxVal);
  }
  // 0.1 is the ten-per-cent padding at `utilities.ts:2251`.
  final rangePadding = (maxVal - minVal) * 0.1;
  // `utilities.ts:2254-2257`: an explicit bound counts as already padded when it
  // sits less than the padding away from the data.
  final satisfiedAtMin =
      userMinVal != null &&
      rangePadding > (minVal - math.min(minVal, userMinVal)).abs();
  final satisfiedAtMax =
      userMaxVal != null &&
      rangePadding > (maxVal - math.max(maxVal, userMaxVal)).abs();
  return (
    start: satisfiedAtMin ? 0 : rangePadding,
    end: satisfiedAtMax ? 0 : rangePadding,
  );
}
