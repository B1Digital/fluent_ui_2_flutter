import 'dart:math' as math;

import '../axis/domain_range.dart';
import '../model/cartesian_series.dart';
import '../model/chart_common.dart';
import '../model/line_options.dart';
import 'd3/scale.dart';

/// Lower bound of the categorical marker pixel range (`utilities.ts:2338`).
const double kMarkerMinPixel = 4;

/// Upper bound of the categorical marker pixel range (`utilities.ts:2339`).
const double kMarkerMaxPixel = 16;

/// The radius of one marker, in logical pixels.
///
/// Ports `calculateMarkerRadius` (`utilities.ts:2317-2360`).
///
/// The cross-plan contract homes `getScatterXDomainExtent` and
/// `getDomainPaddingForMarkers` in `axis/domain_range.dart` but leaves this
/// function and [getRangeForScatterMarkerSize] unowned; ScatterChart, LineChart
/// and PolarChart all call both, so they live here rather than being written
/// three times.
///
/// [pointMarkerSize] is deliberately nullable AND checked for zero, because
/// upstream's `if (!pointMarkerSize)` (`utilities.ts:2342`) treats `0` as
/// absent.
double calculateMarkerRadius({
  double? pointMarkerSize,
  required double minMarkerSize,
  required double maxMarkerSize,
  required double extraMaxPixels,
  required bool isContinuousXY,
  bool isActive = false,
  // 3.5 and 5.5 are the destructured defaults at `utilities.ts:2324-2325`.
  double defaultRadius = 3.5,
  double activeRadius = 5.5,
  // The visibility floor at `utilities.ts:2326`.
  double minRadius = 4,
}) {
  // parity: utilities.ts:2342 — JS falsiness means 0 and undefined behave alike.
  if (pointMarkerSize == null || pointMarkerSize == 0) {
    return isActive ? activeRadius : defaultRadius;
  }
  final double radius;
  if (isContinuousXY && maxMarkerSize != 0) {
    // utilities.ts:2349 — a marker table that already fits the pixel budget is
    // used as written; otherwise the whole table is scaled down to fit.
    radius = maxMarkerSize < extraMaxPixels
        ? pointMarkerSize
        : (pointMarkerSize / maxMarkerSize) * extraMaxPixels;
  } else if (!isContinuousXY && maxMarkerSize != minMarkerSize) {
    // utilities.ts:2352 — a band scale has no spare domain to measure, so the
    // sizes are normalised into a fixed pixel range instead.
    radius =
        kMarkerMinPixel +
        ((pointMarkerSize - minMarkerSize) / (maxMarkerSize - minMarkerSize)) *
            (kMarkerMaxPixel - kMarkerMinPixel);
  } else {
    // utilities.ts:2353-2356.
    return isActive ? activeRadius : defaultRadius;
  }
  // utilities.ts:2359. `math.max` rather than a comparison so that a NaN radius
  // propagates exactly as `Math.max` lets it.
  return math.max(radius, minRadius);
}

/// The pixel budget one marker may spend without leaving the plot area.
///
/// Ports `getRangeForScatterMarkerSize` (`utilities.ts:2362-2404`). It is
/// measured through the *live* scales, so it changes whenever the widget is
/// laid out at a different size: callers must recompute it per paint and must
/// never cache it across a resize.
///
/// [points] holds `FluentLineChartSeries` or `FluentScatterChartSeries`, which
/// have no common supertype in this port, so it is typed `List<Object>` exactly
/// as `getScatterXDomainExtent` is.
double getRangeForScatterMarkerSize({
  required List<Object> points,
  required Scale xScale,
  required Scale yScalePrimary,
  Scale? yScaleSecondary,
  bool useSecondaryYScale = false,
  FluentAxisScaleType? xScaleType,
  FluentAxisScaleType? yScaleType,
  FluentAxisScaleType? secondaryYScaleType,
}) {
  final (xMin, xMax) = getScatterXDomainExtent(points, scaleType: xScaleType);
  if (xMin == null || xMax == null) {
    // Upstream asserts non-null here and lets the resulting NaN reach every
    // marker (`utilities.ts:2391`). With no valid x there is no marker to size,
    // so the port returns no budget rather than propagating NaN or throwing.
    return 0;
  }
  final xMinNum = _toDouble(xMin);
  final xMaxNum = _toDouble(xMax);
  final xPadding = getDomainPaddingForMarkers(
    xMinNum,
    xMaxNum,
    scaleType: xScaleType,
  );
  final scaleXMin = xMin is DateTime
      ? DateTime.fromMillisecondsSinceEpoch((xMinNum - xPadding.start).round())
      : xMinNum - xPadding.start;
  final scaleXMax = xMax is DateTime
      ? DateTime.fromMillisecondsSinceEpoch((xMaxNum + xPadding.end).round())
      : xMaxNum + xPadding.end;
  final extraXPixels = math.min(
    ((xScale(xMin) ?? 0) - (xScale(scaleXMin) ?? 0)).abs(),
    ((xScale(scaleXMax) ?? 0) - (xScale(xMax) ?? 0)).abs(),
  );

  final effectiveYScaleType = useSecondaryYScale
      ? secondaryYScaleType
      : yScaleType;
  final minMax = findNumericMinMaxOfY(
    points,
    useSecondaryYScale: useSecondaryYScale,
    scaleType: effectiveYScaleType,
  );
  final yPadding = getDomainPaddingForMarkers(
    minMax.startValue,
    minMax.endValue,
    scaleType: effectiveYScaleType,
  );
  // `utilities.ts:2401` asserts the secondary scale non-null; the port falls
  // back to the primary rather than throwing at paint time.
  final yScale = useSecondaryYScale
      ? yScaleSecondary ?? yScalePrimary
      : yScalePrimary;
  final extraYPixels = math.min(
    ((yScale(minMax.startValue - yPadding.start) ?? 0) -
            (yScale(minMax.startValue) ?? 0))
        .abs(),
    ((yScale(minMax.endValue) ?? 0) -
            (yScale(minMax.endValue + yPadding.end) ?? 0))
        .abs(),
  );
  return math.min(extraXPixels, extraYPixels);
}

/// Whether any series in [points] is drawn as text and nothing else.
///
/// Ports `isTextMode` (`utilities.ts:2216-2221`). Upstream tests
/// `lineOptions.mode === 'text'` — the whole string, not a substring — so a
/// series in `'lines+text'` mode is NOT text mode. The three flags on
/// [FluentLineMode] carry that faithfully: text mode is text and nothing else.
///
/// [points] is typed as for [getRangeForScatterMarkerSize].
bool isTextMode(List<Object> points) =>
    points.map(_lineOptionsOf).any((FluentLineOptions? options) {
      final mode = options?.mode;
      return mode != null && mode.text && !mode.markers && !mode.lines;
    });

/// Whether a series in [mode] draws its connecting line.
///
/// Ports `const shouldDrawLines = lineMode !== 'markers'` (`LineChart.tsx:698`).
/// Only the bare literal suppresses the line, so `'markers+text'` still draws
/// one.
bool lineModeDrawsLines(FluentLineMode? mode) =>
    mode == null || !(mode.markers && !mode.lines && !mode.text);

FluentLineOptions? _lineOptionsOf(Object series) => switch (series) {
  FluentLineOptions() => series,
  FluentLineChartSeries() => series.lineOptions,
  // `utilities.ts:2219` and `:2207` both read `lineOptions` off a scatter
  // series through `as any`; the port declares it instead
  // (`FluentScatterChartSeries.lineOptions`).
  FluentScatterChartSeries() => series.lineOptions,
  _ => null,
};

double _toDouble(Object value) => switch (value) {
  final num n => n.toDouble(),
  final DateTime d => d.millisecondsSinceEpoch.toDouble(),
  _ => double.nan,
};
