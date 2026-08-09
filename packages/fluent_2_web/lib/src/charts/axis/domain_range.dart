import 'dart:math' as math;

import '../internal/d3/array_stats.dart' as d3;
import '../model/bar_data.dart';
import '../model/cartesian_series.dart';
import '../model/chart_common.dart';
import 'axis_types.dart';

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

/// The domain and range of a numeric x axis for area, line and scatter charts.
///
/// Ports `domainRangeOfNumericForAreaLineScatterCharts`
/// (`utilities.ts:1353-1378`). Under RTL the **domain** is reversed and the range
/// is left alone, which is the opposite of the band axis.
///
/// [isScatterPolar] is supplied by the caller rather than derived here. Upstream
/// derives it from `isScatterPolarSeries` (`utilities.ts:1363`), which reads
/// `lineOptions.mode === 'scatterpolar'` (`utilities.ts:2204-2208`), and the
/// ported `FluentLineOptions.mode` is a three-flag set with no scatterpolar
/// member, so the axis engine takes the answer as a parameter instead of reaching
/// into a model it cannot express.
FluentChartDomainRange domainRangeOfNumericForAreaLineScatterCharts(
  List<Object> points,
  FluentChartMargins margins,
  double width, {
  required bool isRtl,
  FluentAxisScaleType? scaleType,
  bool hasMarkersMode = false,
  bool isScatterPolar = false,
  double? xMinVal,
  double? xMaxVal,
}) {
  final extent = getScatterXDomainExtent(points, scaleType: scaleType);
  // `utilities.ts:1364` casts the extent to `[number, number]` and lets an empty
  // series produce NaN, so the port names that not-a-number rather than throwing.
  var xMin = (extent.$1 as num?)?.toDouble() ?? double.nan;
  var xMax = (extent.$2 as num?)?.toDouble() ?? double.nan;

  if (hasMarkersMode) {
    final padding = getDomainPaddingForMarkers(
      xMin,
      xMax,
      scaleType: scaleType,
      userMinVal: xMinVal,
      userMaxVal: xMaxVal,
    );
    xMin = xMin - padding.start;
    xMax = xMax + padding.end;
  }

  final rStartValue = margins.left ?? 0;
  final rEndValue = width - (margins.right ?? 0);

  if (isRtl) {
    return FluentChartDomainRange(
      // The polar domain is the unit circle, reversed under RTL
      // (`utilities.ts:1376`). 1 and -1 are the circle's own bounds.
      dStartValue: isScatterPolar ? 1 : xMax,
      dEndValue: isScatterPolar ? -1 : xMin,
      rStartValue: rStartValue,
      rEndValue: rEndValue,
    );
  }
  return FluentChartDomainRange(
    // Ascending through the unit circle in LTR (`utilities.ts:1377`).
    dStartValue: isScatterPolar ? -1 : xMin,
    dEndValue: isScatterPolar ? 1 : xMax,
    rStartValue: rStartValue,
    rEndValue: rEndValue,
  );
}

/// The domain and range of the dependent (horizontal) axis of
/// HorizontalBarChartWithAxis and GanttChart.
///
/// Ports `domainRangeOfNumericForHorizontalBarChartWithAxis`
/// (`utilities.ts:1443-1459`). The low end is clamped to the smaller of the
/// longest negative bar and [xOrigin], so a chart whose bars all start at a
/// non-zero origin still shows that origin.
///
/// [xOrigin] defaults to zero because the sole caller passes its own `X_ORIGIN`,
/// which is the constant zero (`HorizontalBarChartWithAxis.tsx:80` and `:871`).
/// Upstream's parameter is optional and dereferenced with `!`, so omitting it
/// there would yield NaN; the port cannot reproduce a bug no caller can reach.
FluentChartDomainRange domainRangeOfNumericForHorizontalBarChartWithAxis(
  List<Object> points,
  FluentChartMargins margins,
  double containerWidth, {
  required bool isRtl,
  double xOrigin = 0,
}) {
  final bars = computeLongestBars(groupChartDataByYValue(points), xOrigin);
  final xMax = bars.$1;
  final xMin = math.min(bars.$2, xOrigin);
  final rMin = margins.left ?? 0;
  final rMax = containerWidth - (margins.right ?? 0);
  return isRtl
      ? FluentChartDomainRange(
          dStartValue: xMax,
          dEndValue: xMin,
          rStartValue: rMin,
          rEndValue: rMax,
        )
      : FluentChartDomainRange(
          dStartValue: xMin,
          dEndValue: xMax,
          rStartValue: rMin,
          rEndValue: rMax,
        );
}

/// The range of a band x axis.
///
/// Ports `domainRangeOfXStringAxis` (`utilities.ts:1472-1478`). The domain ends
/// are both `0` and unused — the band domain is the category list, applied later
/// by `createStringXAxis`. This is the only domain function that reverses the
/// **range** under RTL; every other one reverses the domain. The two idioms are
/// both live and must not be unified.
FluentChartDomainRange domainRangeOfXStringAxis(
  FluentChartMargins margins,
  double width, {
  required bool isRtl,
}) {
  final rMin = margins.left ?? 0;
  final rMax = width - (margins.right ?? 0);
  return isRtl
      ? FluentChartDomainRange(
          // 0 for both ends, as `utilities.ts:1476` sends.
          dStartValue: 0,
          dEndValue: 0,
          rStartValue: rMax,
          rEndValue: rMin,
        )
      : FluentChartDomainRange(
          // And again at `utilities.ts:1477`.
          dStartValue: 0,
          dEndValue: 0,
          rStartValue: rMin,
          rEndValue: rMax,
        );
}

/// The domain and range of VerticalStackedBarChart's numeric x axis.
///
/// Ports `domainRangeOfVSBCNumeric` (`utilities.ts:1490-1504`). The upstream
/// locals are named `rMax` for the left edge and `rMin` for the right
/// (`utilities.ts:1499-1500`), which is backwards; both branches nonetheless emit
/// left then `width - right`.
FluentChartDomainRange domainRangeOfVSBCNumeric(
  List<Object> points,
  FluentChartMargins margins,
  double width, {
  required bool isRtl,
}) {
  final xs = <double>[
    for (final point in points)
      if (point is FluentChartXYPoint && point.x is num)
        (point.x as num).toDouble(),
  ];
  final xMin = d3.min<double>(xs) ?? double.nan;
  final xMax = d3.max<double>(xs) ?? double.nan;
  final rStart = margins.left ?? 0;
  final rEnd = width - (margins.right ?? 0);
  return isRtl
      ? FluentChartDomainRange(
          dStartValue: xMax,
          dEndValue: xMin,
          rStartValue: rStart,
          rEndValue: rEnd,
        )
      : FluentChartDomainRange(
          dStartValue: xMin,
          dEndValue: xMax,
          rStartValue: rStart,
          rEndValue: rEnd,
        );
}

/// The domain and range of VerticalBarChart's numeric x axis.
///
/// Ports `domainRangeOfVerticalNumeric` (`utilities.ts:1568-1583`), which is
/// [domainRangeOfVSBCNumeric] over a different point type and with the range
/// locals named the right way round.
FluentChartDomainRange domainRangeOfVerticalNumeric(
  List<Object> points,
  FluentChartMargins margins,
  double containerWidth, {
  required bool isRtl,
}) {
  final xs = <double>[
    for (final point in points)
      if (point is FluentVerticalBarChartDataPoint && point.x is num)
        (point.x as num).toDouble(),
  ];
  final xMin = d3.min<double>(xs) ?? double.nan;
  final xMax = d3.max<double>(xs) ?? double.nan;
  final rMin = margins.left ?? 0;
  final rMax = containerWidth - (margins.right ?? 0);
  return isRtl
      ? FluentChartDomainRange(
          dStartValue: xMax,
          dEndValue: xMin,
          rStartValue: rMin,
          rEndValue: rMax,
        )
      : FluentChartDomainRange(
          dStartValue: xMin,
          dEndValue: xMax,
          rStartValue: rMin,
          rEndValue: rMax,
        );
}

/// The domain and range of a date x axis.
///
/// Ports `domainRangeOfDateForAreaLineScatterVerticalBarCharts`
/// (`utilities.ts:1517-1556`). Area, line and scatter charts union the data
/// extent with [tickValues] so a caller-supplied tick is never outside the
/// domain, and pad in milliseconds when markers are shown — ScatterChart takes
/// that branch unconditionally. Bar charts take neither: a plain min and max over
/// `point.x`.
FluentChartDomainRange domainRangeOfDateForAreaLineScatterVerticalBarCharts(
  List<Object> points,
  FluentChartMargins margins,
  double width, {
  required bool isRtl,
  required FluentChartType chartType,
  List<DateTime> tickValues = const <DateTime>[],
  bool hasMarkersMode = false,
}) {
  DateTime? sDate;
  DateTime? lDate;

  // The three series chart types of `utilities.ts:1529`.
  const seriesTypes = <FluentChartType>{
    FluentChartType.areaChart,
    FluentChartType.lineChart,
    FluentChartType.scatterChart,
  };

  if (seriesTypes.contains(chartType)) {
    final extent = getScatterXDomainExtent(points);
    // `utilities.ts:1535-1536` unions the tick values into BOTH ends, so a
    // caller-supplied tick outside the data still falls inside the domain.
    sDate = d3.min<DateTime>(<DateTime>[
      ...tickValues,
      if (extent.$1 is DateTime) extent.$1! as DateTime,
    ]);
    lDate = d3.max<DateTime>(<DateTime>[
      ...tickValues,
      if (extent.$2 is DateTime) extent.$2! as DateTime,
    ]);

    // `utilities.ts:1538` — markers mode, or a scatter chart whatever its mode.
    if ((hasMarkersMode || chartType == FluentChartType.scatterChart) &&
        sDate != null &&
        lDate != null) {
      final padding = getDomainPaddingForMarkers(
        sDate.millisecondsSinceEpoch.toDouble(),
        lDate.millisecondsSinceEpoch.toDouble(),
      );
      sDate = DateTime.fromMillisecondsSinceEpoch(
        (sDate.millisecondsSinceEpoch - padding.start).round(),
        isUtc: sDate.isUtc,
      );
      lDate = DateTime.fromMillisecondsSinceEpoch(
        (lDate.millisecondsSinceEpoch + padding.end).round(),
        isUtc: lDate.isUtc,
      );
    }
  } else {
    // `utilities.ts:1545-1547` reads `point.x` off an `any[]`, which at this
    // call site is either kind of bar point.
    final dates = <DateTime>[
      for (final point in points)
        if (point is FluentVerticalBarChartDataPoint && point.x is DateTime)
          point.x as DateTime
        else if (point is FluentVerticalStackedBarDataPoint &&
            point.x is DateTime)
          point.x as DateTime,
    ];
    sDate = d3.min<DateTime>(dates);
    lDate = d3.max<DateTime>(dates);
  }

  final rStartValue = margins.left ?? 0;
  final rEndValue = width - (margins.right ?? 0);
  // Upstream dereferences both dates with `!` and would throw on an empty chart;
  // the port falls back to `kDefaultDateString`, the same epoch every other date
  // fallback in this subsystem uses (`utilities.ts:91`).
  final start = sDate ?? DateTime.utc(2000);
  final end = lDate ?? DateTime.utc(2000);

  return isRtl
      ? FluentChartDomainRange(
          dStartValue: end,
          dEndValue: start,
          rStartValue: rStartValue,
          rEndValue: rEndValue,
        )
      : FluentChartDomainRange(
          dStartValue: start,
          dEndValue: end,
          rStartValue: rStartValue,
          rEndValue: rEndValue,
        );
}
