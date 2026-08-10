import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'axis/tick_format.dart';
import 'internal/chart_utils.dart';
import 'internal/d3/array_stats.dart' as d3;
import 'internal/d3/shape_radial.dart' as d3;
import 'internal/d3/stable_sort.dart' as d3;
import 'internal/data_viz_palette.dart';
import 'model/chart_common.dart';
import 'model/chart_value.dart';
import 'model/polar_data.dart';
import 'polar_chart_scales.dart';
import 'polar_chart_style.dart';

/// SVG `text-anchor` values the polar tick labels use.
enum FluentPolarTextAnchor {
  /// The label starts at the anchor point.
  start,

  /// The label is centred on the anchor point.
  middle,

  /// The label ends at the anchor point.
  end,
}

/// The chart margins before any user override (`PolarChart.tsx:92-95`).
const FluentChartMargins kPolarDefaultMargins = FluentChartMargins(
  // LABEL_OFFSET 10 + LABEL_WIDTH 36.
  left: kPolarLabelOffset + kPolarLabelWidth,
  right: kPolarLabelOffset + kPolarLabelWidth,
  // LABEL_OFFSET 10 + LABEL_HEIGHT 16.
  top: kPolarLabelOffset + kPolarLabelHeight,
  bottom: kPolarLabelOffset + kPolarLabelHeight,
);

/// Smallest marker radius when the chart also draws lines or areas.
///
/// `MIN_MARKER_SIZE_PX` (`PolarChart.tsx:43`).
const double kPolarMinMarkerSize = 2;

/// Largest marker radius (`MAX_MARKER_SIZE_PX`, `PolarChart.tsx:44`).
const double kPolarMaxMarkerSize = 16;

/// Smallest marker radius when the chart draws nothing but markers.
///
/// `MIN_MARKER_SIZE_PX_MARKERS_ONLY` (`PolarChart.tsx:45`). Markers carry the
/// whole chart in that mode, so the floor is doubled.
const double kPolarMinMarkerSizeMarkersOnly = 4;

/// A data point with its resolved colour (`PolarChart.tsx:131-136`).
@immutable
class FluentPolarResolvedPoint {
  /// Creates a resolved point.
  const FluentPolarResolvedPoint({required this.point, required this.color});

  /// The caller's data point.
  final FluentPolarDataPoint point;

  /// The point's own colour, falling back to the series colour.
  final Color color;
}

/// A series with its resolved colour and points (`PolarChart.tsx:121-138`).
@immutable
class FluentPolarResolvedSeries {
  /// Creates a resolved series.
  const FluentPolarResolvedSeries({
    required this.series,
    required this.color,
    required this.points,
  });

  /// The caller's series.
  final FluentPolarSeries series;

  /// The colour every mark in this series paints with unless a point overrides
  /// it.
  final Color color;

  /// The series' points, each carrying its resolved colour.
  final List<FluentPolarResolvedPoint> points;
}

/// One placed, plottable marker (`PolarChart.tsx:527-573`).
@immutable
class FluentPolarMarker {
  /// Creates a placed marker.
  const FluentPolarMarker({
    required this.position,
    required this.radius,
    required this.color,
    required this.id,
    required this.legend,
    required this.semanticLabel,
    required this.popoverXValue,
    required this.popoverYValue,
    required this.point,
  });

  /// Centre of the marker, relative to the chart centre.
  final Offset position;

  /// Marker radius in device pixels.
  final double radius;

  /// Fill colour when the marker is not active.
  final Color color;

  /// `seriesIndex-pointIndex`, the identity the active-marker state compares.
  final String id;

  /// Legend title of the owning series.
  final String legend;

  /// Screen-reader label (`PolarChart.tsx:555`).
  final String semanticLabel;

  /// Popover heading — the angle (`PolarChart.tsx:506`).
  final String popoverXValue;

  /// Popover value — the radius (`PolarChart.tsx:509-511`).
  final String popoverYValue;

  /// The caller's data point, for the popover's accessibility overrides.
  final FluentPolarDataPoint point;
}

/// Everything a polar chart needs to paint, computed once per layout pass.
///
/// Ports the memoised block at `PolarChart.tsx:90-142` and `:492-548`. Pure: no
/// [BuildContext], no state, so it is testable without mounting anything.
@immutable
class FluentPolarLayout {
  /// Creates a layout. Prefer [compute].
  const FluentPolarLayout({
    required this.centre,
    required this.outerRadius,
    required this.innerRadius,
    required this.series,
    required this.legendColors,
    required this.radial,
    required this.angular,
    required this.markers,
    required this.markersOnly,
    required this.radialAxisAngle,
    required this.tickSign,
  });

  /// Centre of the plot, in the painter's coordinate space.
  final Offset centre;

  /// Radius of the outermost ring.
  final double outerRadius;

  /// Radius of the hole (`PolarChart.tsx:110-113`).
  final double innerRadius;

  /// Series in paint order: areas, then lines, then scatters.
  final List<FluentPolarResolvedSeries> series;

  /// Legend title to swatch colour, in order of first appearance.
  final Map<String, Color> legendColors;

  /// The resolved radial axis.
  final FluentPolarRadialScale radial;

  /// The resolved angular axis.
  final FluentPolarAngularScale angular;

  /// Every plottable marker, in paint order.
  final List<FluentPolarMarker> markers;

  /// Whether the chart draws markers only (`PolarChart.tsx:522-525`).
  final bool markersOnly;

  /// Angle the radial axis is drawn at (`PolarChart.tsx:339`).
  final double radialAxisAngle;

  /// Direction multiplier applied to the tick marks (`PolarChart.tsx:343`).
  final double tickSign;

  /// Solves the whole layout.
  static FluentPolarLayout compute({
    required Size size,
    required List<FluentPolarSeries> data,
    required FluentChartMargins margins,
    required double hole,
    required FluentPolarDirection direction,
    FluentPolarAxisConfig? radialAxis,
    FluentPolarAxisConfig? angularAxis,
    FluentPolarAngularUnit angularUnit = FluentPolarAngularUnit.degrees,
    bool useUtc = false,
    String? culture,
  }) {
    final m = kPolarDefaultMargins.mergeOverride(margins);
    // `:107` — the plot is a circle, so the tighter free axis wins. Halved
    // because a diameter is being turned into a radius.
    final outerRadius =
        math.min(
          size.width - (m.left! + m.right!),
          size.height - (m.top! + m.bottom!),
        ) /
        2;
    // `:111` — abs, then clamp into [0, 1], then scale.
    final innerRadius = math.max(0.0, math.min(hole.abs(), 1.0)) * outerRadius;

    // `:115-138` — colours are assigned in INPUT order, before the paint sort.
    final legendColors = <String, Color>{};
    var colorIndex = 0;
    final resolved = <FluentPolarResolvedSeries>[];
    for (final s in data) {
      // `:123` — the increment lives in the else branch, so an explicitly
      // coloured series does not consume a palette slot.
      final seriesColor = s.color ?? FluentDataVizPalette.next(colorIndex++);
      legendColors.putIfAbsent(s.legend, () => seriesColor);
      resolved.add(
        FluentPolarResolvedSeries(
          series: s,
          color: seriesColor,
          points: <FluentPolarResolvedPoint>[
            for (final p in s.data)
              FluentPolarResolvedPoint(point: p, color: p.color ?? seriesColor),
          ],
        ),
      );
    }
    // `:119` and `:139-141` — areas paint first so lines and markers land on
    // top. The three ranks are upstream's `renderingOrder` array indices.
    const order = <Type, int>{
      FluentAreaPolarSeries: 0,
      FluentLinePolarSeries: 1,
      FluentScatterPolarSeries: 2,
    };
    final sorted = d3.stableSort<FluentPolarResolvedSeries>(
      resolved,
      // `indexOf` returns -1 for a type the array never names; the sealed
      // hierarchy has no fourth member, so this arm is unreachable in practice.
      (a, b) =>
          (order[a.series.runtimeType] ?? -1) -
          (order[b.series.runtimeType] ?? -1),
    );

    final rValues = <Object?>[
      for (final s in sorted)
        for (final p in s.points) p.point.r,
    ];
    final rKind = polarScaleTypeOf(
      rValues,
      scaleType: radialAxis?.scaleType,
      supportsLog: true,
    );
    final rDomain = rKind == FluentPolarScaleKind.category
        ? sortAxisCategories(
            _categoryToValues(sorted, isAngular: false),
            radialAxis?.categoryOrder ?? FluentAxisCategoryOrder.defaultOrder,
          ).cast<Object>()
        : polarContinuousDomain(
            rKind,
            rValues,
            rangeStart: radialAxis?.rangeStart,
            rangeEnd: radialAxis?.rangeEnd,
          );
    final radial = createPolarRadialScale(
      rKind,
      rDomain,
      <double>[innerRadius, outerRadius],
      useUtc: useUtc,
      tickCount: radialAxis?.tickCount,
      tickValues: radialAxis?.tickValues,
      tickText: radialAxis?.tickText,
      tickFormat: radialAxis?.tickFormat,
      culture: culture,
      tickStep: radialAxis?.tickStep,
      tick0: radialAxis?.tick0,
    );

    final aValues = <Object?>[
      for (final s in sorted)
        for (final p in s.points) p.point.theta,
    ];
    final aKind = polarScaleTypeOf(aValues, scaleType: angularAxis?.scaleType);
    final aDomain = aKind == FluentPolarScaleKind.category
        ? sortAxisCategories(
            _categoryToValues(sorted, isAngular: true),
            angularAxis?.categoryOrder ?? FluentAxisCategoryOrder.defaultOrder,
          ).cast<Object>()
        // `:240` passes no options: rangeStart/rangeEnd are never read here.
        : polarContinuousDomain(aKind, aValues);
    final angular = createPolarAngularScale(
      aKind,
      aDomain,
      tickCount: angularAxis?.tickCount,
      tickValues: angularAxis?.tickValues,
      tickText: angularAxis?.tickText,
      tickFormat: angularAxis?.tickFormat,
      tickStep: angularAxis?.tickStep,
      tick0: angularAxis?.tick0,
      direction: direction,
      unit: angularUnit,
    );

    // `:492-495` — the extent spans EVERY series, including the ones with no
    // sizes.
    final (num? minSize, num? maxSize) = d3.extent<num>(<Object>[
      for (final s in sorted)
        for (final p in s.points)
          if (p.point.markerSize != null) p.point.markerSize!,
    ]);
    final markersOnly = !sorted.any(
      (s) =>
          s.series is FluentAreaPolarSeries ||
          s.series is FluentLinePolarSeries,
    );
    final minPx = markersOnly
        ? kPolarMinMarkerSizeMarkersOnly
        : kPolarMinMarkerSize;

    final markers = <FluentPolarMarker>[];
    for (var si = 0; si < sorted.length; si++) {
      final s = sorted[si];
      for (var pi = 0; pi < s.points.length; pi++) {
        final p = s.points[pi];
        final angle = angular.radiansOf(p.point.theta);
        final radius = radial.radiusOf(p.point.r);
        // `:534-536` — a point that fails the predicate renders nothing.
        if (!isPlottable(angle, radius)) {
          continue;
        }
        var r = minPx;
        final ms = p.point.markerSize;
        // `:544` compares two possibly-null extents; equal (including both
        // null) means every marker keeps the floor.
        if (ms != null && minSize != maxSize) {
          r =
              minPx +
              ((ms - minSize!) / (maxSize! - minSize)) *
                  (kPolarMaxMarkerSize - minPx);
        }
        final xValue =
            p.point.radialAxisCalloutData ??
            formatToLocaleString(p.point.r, culture: culture, useUtc: useUtc);
        final yValue =
            p.point.angularAxisCalloutData ??
            formatPolarAngle(p.point.theta, angularUnit);
        markers.add(
          FluentPolarMarker(
            position: d3.pointRadial(angle, radius!),
            radius: r,
            color: p.color,
            id: '$si-$pi',
            legend: s.series.legend,
            // `:551-555` — radius first, then legend, then angle.
            semanticLabel:
                p.point.callOutSemantics?.label ??
                '$xValue. ${s.series.legend}, $yValue.',
            // `:506` and `:509-511` swap the two relative to the aria string.
            popoverXValue: yValue,
            popoverYValue: xValue,
            point: p.point,
          ),
        );
      }
    }

    // `:339` — pi/2 unless the chart sweeps clockwise.
    final radialAxisAngle = direction == FluentPolarDirection.clockwise
        ? 0.0
        : math.pi / 2;
    // `:343` — the half-open interval (0, pi].
    final tickSign =
        radialAxisAngle > kPolarEpsilon &&
            radialAxisAngle - math.pi < kPolarEpsilon
        ? 1.0
        : -1.0;

    return FluentPolarLayout(
      // `:652` translates the whole plot to the centre of the svg.
      centre: Offset(size.width / 2, size.height / 2),
      outerRadius: outerRadius,
      innerRadius: innerRadius,
      series: sorted,
      legendColors: legendColors,
      radial: radial,
      angular: angular,
      markers: markers,
      markersOnly: markersOnly,
      radialAxisAngle: radialAxisAngle,
      tickSign: tickSign,
    );
  }

  /// Builds the `categoryToValues` map [sortAxisCategories] consumes.
  ///
  /// Ports `mapCategoryToValues` (`PolarChart.tsx:144-161`): the key is the
  /// axis' own coordinate stringified, and the value list holds the *other*
  /// coordinate whenever it is numeric.
  static Map<String, List<double>> _categoryToValues(
    List<FluentPolarResolvedSeries> series, {
    required bool isAngular,
  }) {
    final result = <String, List<double>>{};
    for (final s in series) {
      for (final p in s.points) {
        final key = (isAngular ? p.point.theta : p.point.r).toString();
        final value = isAngular ? p.point.r : p.point.theta;
        final bucket = result.putIfAbsent(key, () => <double>[]);
        if (value is num) {
          bucket.add(value.toDouble());
        }
      }
    }
    return result;
  }
}
