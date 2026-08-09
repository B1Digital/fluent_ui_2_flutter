import 'dart:math' as math;

import '../internal/d3/array_stats.dart' as d3;
import '../model/bar_data.dart';
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

/// Whether [key] is what JavaScript calls an array index — a canonical
/// non-negative integer string, which an object enumerates before its string
/// keys.
bool _isIntegerLikeKey(String key) {
  final parsed = int.tryParse(key);
  return parsed != null && parsed >= 0 && parsed.toString() == key;
}

/// Renders a number the way JavaScript does when it becomes an object key.
///
/// A whole double loses its fractional part, so `2.0` keys as `'2'` and then
/// counts as an array index for the ordering below. `1e21` is where JavaScript
/// switches to exponential notation, beyond which no key is an array index
/// anyway, so the plain conversion is enough.
String _jsKeyOfNumber(num value) {
  if (value is int) {
    return value.toString();
  }
  final asDouble = value.toDouble();
  if (asDouble == asDouble.truncateToDouble() && asDouble.abs() < 1e21) {
    return asDouble.toStringAsFixed(0);
  }
  return asDouble.toString();
}

/// Groups horizontal-bar points by their y value, for the stacked case.
///
/// Ports `groupChartDataByYValue` (`utilities.ts:1386-1399`), which returns
/// `Object.values(map)`. JavaScript enumerates integer-like keys first in
/// ascending numeric order and every other key in insertion order, and that
/// ordering reaches the rendered bar order, so the port reproduces it here
/// rather than relying on Dart's pure insertion-ordered map. Points that are not
/// horizontal-bar points are skipped, because the boundary is untyped where
/// upstream has a TypeScript signature.
Map<String, List<Object>> groupChartDataByYValue(List<Object> points) {
  final buckets = <String, List<Object>>{};
  for (final point in points) {
    if (point is! FluentHorizontalBarChartWithAxisDataPoint) {
      continue;
    }
    final key = point.y is num
        ? _jsKeyOfNumber(point.y as num)
        : point.y.toString();
    buckets.putIfAbsent(key, () => <Object>[]).add(point);
  }
  final integerKeys = buckets.keys.where(_isIntegerLikeKey).toList()
    ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
  final otherKeys = buckets.keys.where((k) => !_isIntegerLikeKey(k));
  return <String, List<Object>>{
    for (final key in integerKeys) key: buckets[key]!,
    for (final key in otherKeys) key: buckets[key]!,
  };
}

/// The longest positive and longest negative stacked bar.
///
/// Ports `computeLongestBars` (`utilities.ts:1407-1431`). The record is
/// `(longestPositiveBar, longestNegativeBar)`, matching the field order of the
/// upstream object. Both totals are seeded at [xOrigin] per group
/// (`utilities.ts:1420` and `utilities.ts:1424`) and then reduced across groups
/// with `max` and `min` seeded at zero (`utilities.ts:1414-1415`), so a chart
/// with no data yields `(0, 0)`.
(double, double) computeLongestBars(
  Map<String, List<Object>> grouped,
  double xOrigin,
) {
  var longestPositiveBar = 0.0;
  var longestNegativeBar = 0.0;
  for (final group in grouped.values) {
    var positiveTotal = xOrigin;
    var negativeTotal = xOrigin;
    for (final point in group) {
      if (point is! FluentHorizontalBarChartWithAxisDataPoint) {
        continue;
      }
      if (point.x > 0) {
        positiveTotal += point.x;
      }
      if (point.x < 0) {
        negativeTotal += point.x;
      }
    }
    longestPositiveBar = math.max(longestPositiveBar, positiveTotal);
    longestNegativeBar = math.min(longestNegativeBar, negativeTotal);
  }
  return (longestPositiveBar, longestNegativeBar);
}
