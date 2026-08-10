import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'axis/tick_format.dart';
import 'chrome/chart_popover.dart';
import 'chrome/chart_title.dart';
import 'chrome/legend.dart';
import 'internal/chart_colors.dart';
import 'internal/chart_text_measurer.dart';
import 'internal/chart_text_styles.dart';
import 'internal/chart_utils.dart';
import 'internal/d3/array_stats.dart' as d3;
import 'internal/d3/curves.dart' as d3;
import 'internal/d3/path_sink.dart' as d3;
import 'internal/d3/shape_radial.dart' as d3;
import 'internal/d3/stable_sort.dart' as d3;
import 'internal/data_viz_palette.dart';
import 'internal/image_export.dart';
import 'model/chart_common.dart';
import 'model/chart_value.dart';
import 'model/line_options.dart';
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

/// One radial tick: its mark, its label position and its anchor.
@immutable
class FluentPolarRadialTick {
  /// Creates a radial tick.
  const FluentPolarRadialTick({
    required this.markStart,
    required this.markEnd,
    required this.labelAnchor,
    required this.anchor,
    required this.label,
  });

  /// Where the tick mark meets the radial axis.
  final Offset markStart;

  /// Free end of the tick mark.
  final Offset markEnd;

  /// Anchor point of the label.
  final Offset labelAnchor;

  /// How the label is aligned about [labelAnchor].
  final FluentPolarTextAnchor anchor;

  /// The rendered label.
  final String label;
}

/// One angular tick label.
@immutable
class FluentPolarAngularTick {
  /// Creates an angular tick.
  const FluentPolarAngularTick({
    required this.labelAnchor,
    required this.anchor,
    required this.label,
  });

  /// Anchor point of the label.
  final Offset labelAnchor;

  /// How the label is aligned about [labelAnchor].
  final FluentPolarTextAnchor anchor;

  /// The rendered label.
  final String label;
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

  /// JavaScript `===` for the value space a polar domain can hold.
  ///
  /// `PolarChart.tsx:280` and `:284` compare with `!==`, which is *value*
  /// equality for a number or a string but *reference* equality for a `Date`.
  /// That asymmetry is why a date radial axis always grows an extra outer ring,
  /// and it must be preserved.
  static bool _strictEquals(Object? a, Object? b) {
    if (a is num && b is num) {
      return a == b;
    }
    if (a is String && b is String) {
      return a == b;
    }
    return identical(a, b);
  }

  /// The values the grid rings are drawn at, outermost last.
  ///
  /// Ports `PolarChart.tsx:278-286`. The domain start is prepended only when
  /// there is a hole, and the domain end is appended whenever it is not already
  /// the final tick.
  List<Object> gridRingValues() {
    final domain = radial.scale.domain;
    final ticks = radial.tickValues;
    final result = <Object>[];
    if (domain.isEmpty) {
      return ticks;
    }
    if (innerRadius > 0 &&
        (ticks.isEmpty || !_strictEquals(domain.first, ticks.first))) {
      result.add(domain.first);
    }
    result.addAll(ticks);
    if (ticks.isEmpty || !_strictEquals(domain.last, ticks.last)) {
      result.add(domain.last);
    }
    return result;
  }

  /// The path of one grid ring at [radius], centred on the origin.
  ///
  /// A polygon ring has one vertex per angular tick and is closed
  /// (`PolarChart.tsx:294-303`); a circular ring is a plain circle (`:307`).
  Path ringPath(double radius, FluentPolarShape shape) {
    final path = Path();
    if (shape == FluentPolarShape.polygon) {
      for (var i = 0; i < angular.tickValues.length; i++) {
        final p = d3.pointRadial(
          angular.radiansOf(angular.tickValues[i]),
          radius,
        );
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      return path;
    }
    path.addOval(Rect.fromCircle(center: Offset.zero, radius: radius));
    return path;
  }

  /// The spokes, one per angular tick (`PolarChart.tsx:311-321`).
  List<(Offset, Offset)> spokes() => <(Offset, Offset)>[
    for (final a in angular.tickValues)
      (
        d3.pointRadial(angular.radiansOf(a), innerRadius),
        d3.pointRadial(angular.radiansOf(a), outerRadius),
      ),
  ];

  /// The radial axis line (`PolarChart.tsx:340-341, :348-351`).
  (Offset, Offset) radialAxisLine() => (
    d3.pointRadial(radialAxisAngle, innerRadius),
    d3.pointRadial(radialAxisAngle, outerRadius),
  );

  /// The radial ticks (`PolarChart.tsx:352-385`).
  ///
  /// The mark direction deliberately uses plain `cos`/`sin` of [radialAxisAngle]
  /// times [tickSign], while the position uses `pointRadial`'s `(sin, -cos)`.
  /// The two conventions disagree by a quarter turn and that is what ships: at
  /// `pi/2` the axis runs right and its ticks run *down*. Do not "fix" it.
  ///
  /// [tickSize] is the mark length and [labelOffset] the further gap to the
  /// label.
  List<FluentPolarRadialTick> radialTicks({
    required double tickSize,
    required double labelOffset,
  }) {
    final cos = math.cos(radialAxisAngle) * tickSign;
    final sin = math.sin(radialAxisAngle) * tickSign;
    final anchor = _radialLabelAnchor();
    final result = <FluentPolarRadialTick>[];
    for (var i = 0; i < radial.tickValues.length; i++) {
      final radius = radial.radiusOf(radial.tickValues[i]);
      if (radius == null || !radius.isFinite) {
        continue;
      }
      final p = d3.pointRadial(radialAxisAngle, radius);
      result.add(
        FluentPolarRadialTick(
          markStart: p,
          markEnd: Offset(p.dx + tickSize * cos, p.dy + tickSize * sin),
          // `:364-365` — the label sits one further LABEL_OFFSET out.
          labelAnchor: Offset(
            p.dx + (tickSize + labelOffset) * cos,
            p.dy + (tickSize + labelOffset) * sin,
          ),
          anchor: anchor,
          label: i < radial.tickLabels.length ? radial.tickLabels[i] : '',
        ),
      );
    }
    return result;
  }

  /// `PolarChart.tsx:366-376` — four epsilon comparisons, evaluated once.
  FluentPolarTextAnchor _radialLabelAnchor() {
    if ((radialAxisAngle - math.pi / 2).abs() < kPolarEpsilon ||
        (radialAxisAngle - 3 * math.pi / 2).abs() < kPolarEpsilon) {
      return FluentPolarTextAnchor.middle;
    }
    if ((radialAxisAngle > kPolarEpsilon &&
            radialAxisAngle - math.pi / 2 < -kPolarEpsilon) ||
        (radialAxisAngle - math.pi > kPolarEpsilon &&
            radialAxisAngle - 3 * math.pi / 2 < -kPolarEpsilon)) {
      return FluentPolarTextAnchor.start;
    }
    return FluentPolarTextAnchor.end;
  }

  /// The angular tick labels (`PolarChart.tsx:388-411`).
  ///
  /// [labelOffset] is the gap between the outer ring and the label anchor.
  List<FluentPolarAngularTick> angularTicks({required double labelOffset}) {
    final result = <FluentPolarAngularTick>[];
    for (var i = 0; i < angular.tickValues.length; i++) {
      final angle = angular.radiansOf(angular.tickValues[i]);
      if (!angle.isFinite) {
        continue;
      }
      result.add(
        FluentPolarAngularTick(
          labelAnchor: d3.pointRadial(angle, outerRadius + labelOffset),
          // `:397-403` — top and bottom centre, the right half starts, the left
          // ends.
          anchor:
              angle.abs() < kPolarEpsilon ||
                  (angle - math.pi).abs() < kPolarEpsilon
              ? FluentPolarTextAnchor.middle
              : angle > math.pi
              ? FluentPolarTextAnchor.end
              : FluentPolarTextAnchor.start,
          label: i < angular.tickLabels.length ? angular.tickLabels[i] : '',
        ),
      );
    }
    return result;
  }

  /// The filled ring of an area series (`PolarChart.tsx:443-450`).
  ///
  /// The inner radius is the constant hole radius, not a data value
  /// (`:445`), and the fallback curve is `curveLinearClosed` (`:448`) — an
  /// omitted `curve` therefore closes both rings while an explicit `'linear'`
  /// leaves them open (`utilities.ts:2017`).
  ///
  /// `:450` sets `.defined(isPlottable)`, and the reverse-baseline replay
  /// inside `Area` honours it, so a gap breaks the ring on both edges.
  Path areaPath(FluentPolarResolvedSeries series) {
    final options = _lineOptionsOf(series.series);
    final sink = d3.UiPathSink();
    d3.AreaRadial<FluentPolarResolvedPoint>(
      angle: (d, i, data) => angular.radiansOf(d.point.theta),
      innerRadius: (d, i, data) => innerRadius,
      outerRadius: (d, i, data) => radial.radiusOf(d.point.r) ?? double.nan,
      defined: (d, i, data) => isPlottable(
        angular.radiansOf(d.point.theta),
        radial.radiusOf(d.point.r),
      ),
      curve: getCurveFactory(options?.curve, d3.curveLinearClosed),
    )(series.points, sink);
    return sink.path;
  }

  /// The stroked outline of an area or line series (`PolarChart.tsx:467-473`).
  ///
  /// The fallback here is the OPEN `curveLinear` (`:471`), which is why an
  /// area's outline does not close even though its fill does.
  Path linePath(FluentPolarResolvedSeries series) {
    final options = _lineOptionsOf(series.series);
    final sink = d3.UiPathSink();
    d3.LineRadial<FluentPolarResolvedPoint>(
      angle: (d, i, data) => angular.radiansOf(d.point.theta),
      radius: (d, i, data) => radial.radiusOf(d.point.r) ?? double.nan,
      defined: (d, i, data) => isPlottable(
        angular.radiansOf(d.point.theta),
        radial.radiusOf(d.point.r),
      ),
      curve: getCurveFactory(options?.curve),
    )(series.points, sink);
    return sink.path;
  }

  /// The line options of the two series kinds that carry them.
  static FluentLineOptions? _lineOptionsOf(FluentPolarSeries series) =>
      switch (series) {
        FluentAreaPolarSeries(:final lineOptions) => lineOptions,
        FluentLinePolarSeries(:final lineOptions) => lineOptions,
        _ => null,
      };

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

/// Paints the polar grid: the rings and the spokes.
///
/// Kept apart from the series layer because the grid is static across every
/// hover and legend change, so it repaints only when the layout itself changes.
class FluentPolarGridPainter extends CustomPainter {
  /// Creates a grid painter.
  FluentPolarGridPainter({
    required this.layout,
    required this.shape,
    required this.gridColor,
    required this.gridWidth,
    required this.innerOpacity,
    required this.outerOpacity,
  });

  /// The solved layout.
  final FluentPolarLayout layout;

  /// Whether the rings are circles or polygons.
  final FluentPolarShape shape;

  /// Stroke colour of every grid line.
  final Color gridColor;

  /// Stroke width of every grid line.
  final double gridWidth;

  /// Opacity of an inner ring and of every spoke.
  final double innerOpacity;

  /// Opacity of the outermost ring.
  final double outerOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..translate(layout.centre.dx, layout.centre.dy);
    final rings = layout.gridRingValues();
    for (var i = 0; i < rings.length; i++) {
      final radius = layout.radial.radiusOf(rings[i]);
      if (radius == null || !radius.isFinite) {
        continue;
      }
      // `:292` — only the last ring takes the opaque outer style.
      final opacity = i == rings.length - 1 ? outerOpacity : innerOpacity;
      canvas.drawPath(
        layout.ringPath(radius, shape),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = gridWidth
          ..color = gridColor.withValues(alpha: gridColor.a * opacity),
      );
    }
    final spokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = gridWidth
      ..color = gridColor.withValues(alpha: gridColor.a * innerOpacity);
    for (final (start, end) in layout.spokes()) {
      canvas.drawLine(start, end, spokePaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FluentPolarGridPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.shape != shape ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.gridWidth != gridWidth ||
      oldDelegate.innerOpacity != innerOpacity ||
      oldDelegate.outerOpacity != outerOpacity;
}

/// Paints the areas, lines and markers.
///
/// Its own painter because this is the only layer that repaints on a hover or a
/// legend change; the grid and the ticks stay put.
class FluentPolarSeriesPainter extends CustomPainter {
  /// Creates a series painter.
  FluentPolarSeriesPainter({
    required this.layout,
    required this.activeLegends,
    required this.activePointId,
    required this.style,
    required this.states,
    required this.colors,
  });

  /// The solved layout.
  final FluentPolarLayout layout;

  /// Legends currently selected or hovered; empty means everything is
  /// highlighted.
  final Set<String> activeLegends;

  /// Identity of the marker under the cursor, or the empty string.
  final String activePointId;

  /// The resolved style.
  final FluentPolarChartStyle style;

  /// States the style properties resolve against.
  final Set<WidgetState> states;

  /// The theme's resolved chart colours, which is where the forced-colours
  /// flattening comes from (spec section 5.3).
  final FluentChartColors colors;

  /// `legendHighlighted` (`PolarChart.tsx:433-439`) — note that an empty active
  /// set highlights everything, which is also what keeps the popover open on a
  /// cold chart.
  bool _highlighted(String legend) =>
      activeLegends.isEmpty || activeLegends.contains(legend);

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..translate(layout.centre.dx, layout.centre.dy);
    final dimmed = style.dimmedOpacity!.resolve(states)!;
    final areaOpacity = style.areaFillOpacity!.resolve(states)!;
    final defaultStroke = style.lineStrokeWidth!.resolve(states)!;

    for (final series in layout.series) {
      final highlighted = _highlighted(series.series.legend);
      final isArea = series.series is FluentAreaPolarSeries;
      if (isArea) {
        // `:457` — 0.7 highlighted, 0.1 dimmed.
        final opacity = highlighted ? areaOpacity : dimmed;
        final fill = colors.flattenMark(series.color);
        canvas.drawPath(
          layout.areaPath(series),
          Paint()
            ..style = PaintingStyle.fill
            ..color = fill.withValues(alpha: fill.a * opacity),
        );
      }
      if (isArea || series.series is FluentLinePolarSeries) {
        final options = FluentPolarLayout._lineOptionsOf(series.series);
        // `:480` — the stroke dims to 0.1 as well, but from a full 1.
        final opacity = highlighted ? 1.0 : dimmed;
        // An area's outline sits on its own flattened fill, so under forced
        // colours it takes the canvas colour to stay distinct — the reasoning
        // `area_chart.dart` records for its top edge. A standalone line has no
        // fill beneath it and IS the mark, so it flattens like one
        // (`line_chart.dart:923`).
        final stroke = isArea
            ? colors.flattenMarkStroke(series.color)
            : colors.flattenMark(series.color);
        canvas.drawPath(
          layout.linePath(series),
          Paint()
            ..style = PaintingStyle.stroke
            // `:481` — the series width, else the chart-level 3.
            ..strokeWidth = options?.strokeWidth ?? defaultStroke
            ..strokeCap = options?.strokeLinecap ?? StrokeCap.butt
            ..color = stroke.withValues(alpha: stroke.a * opacity),
        );
      }
    }

    // `:563` inverts the active marker to the canvas colour. Deliberately not
    // flattened: under forced colours `flattenMark` would send it to the same
    // system foreground as the marker it is meant to invert, which is the
    // reasoning `line_chart.dart:1015-1019` records (spec section 5.3).
    final activeFill = style.activeMarkerFill!.resolve(states)!;
    final activeStroke = style.activeMarkerStrokeWidth!.resolve(states)!;
    for (final marker in layout.markers) {
      // `:566` — the whole marker, fill and stroke together, drops to 0.1.
      final opacity = _highlighted(marker.legend) ? 1.0 : dimmed;
      final isActive = marker.id == activePointId;
      final fill = isActive ? activeFill : colors.flattenMark(marker.color);
      canvas.drawCircle(
        marker.position,
        marker.radius,
        Paint()
          ..style = PaintingStyle.fill
          ..color = fill.withValues(alpha: fill.a * opacity),
      );
      if (isActive) {
        // `:564-565` — a 2px ring in the point colour replaces the fill.
        final ring = colors.flattenMarkStroke(marker.color);
        canvas.drawCircle(
          marker.position,
          marker.radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = activeStroke
            ..color = ring.withValues(alpha: ring.a * opacity),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FluentPolarSeriesPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.activePointId != activePointId ||
      oldDelegate.style != style ||
      // `FluentChartColors` carries no `==`, so compare the three slots the
      // flattening actually reads; comparing the identity would repaint on
      // every rebuild and defeat this layer's repaint boundary.
      oldDelegate.colors.isHighContrast != colors.isHighContrast ||
      oldDelegate.colors.axisText != colors.axisText ||
      oldDelegate.colors.surface != colors.surface ||
      !setEquals(oldDelegate.states, states) ||
      !setEquals(oldDelegate.activeLegends, activeLegends);
}

/// Paints the radial axis, its tick marks and both label sets.
///
/// Drawn last, over the data, exactly as `PolarChart.tsx:671` does.
class FluentPolarTickPainter extends CustomPainter {
  /// Creates a tick painter.
  FluentPolarTickPainter({
    required this.layout,
    required this.measurer,
    required this.labelStyle,
    required this.gridColor,
    required this.gridWidth,
    required this.outerOpacity,
    required this.tickSize,
    required this.labelOffset,
  });

  /// The solved layout.
  final FluentPolarLayout layout;

  /// Text measurer used to place the labels about their anchors.
  final FluentChartTextMeasurer measurer;

  /// Tick label text style.
  final TextStyle labelStyle;

  /// Stroke colour of the axis and its marks.
  final Color gridColor;

  /// Stroke width of the axis and its marks.
  final double gridWidth;

  /// Opacity of the axis and its marks — these carry the outer style.
  final double outerOpacity;

  /// Length of a tick mark.
  final double tickSize;

  /// Gap between the mark and its label.
  final double labelOffset;

  void _paintLabel(
    Canvas canvas,
    String text,
    Offset anchorPoint,
    FluentPolarTextAnchor anchor,
  ) {
    if (text.isEmpty) {
      return;
    }
    final metrics = measurer.measure(text, labelStyle);
    // `dominant-baseline="middle"` (`:377`, `:404`) is the midpoint between the
    // alphabetic baseline and the x-height — not the em-box centre (spec §8).
    // [fluentChartBaselineOffset] turns that round into the distance below the
    // requested `y`; subtracting the ascent moves it again to the top of the
    // line box, which is where a [TextPainter] origin sits.
    final dy =
        fluentChartBaselineOffset(FluentChartTitleBaseline.middle, metrics) -
        metrics.ascent;
    final dx = switch (anchor) {
      FluentPolarTextAnchor.start => 0.0,
      FluentPolarTextAnchor.middle => -metrics.width / 2,
      FluentPolarTextAnchor.end => -metrics.width,
    };
    measurer.layoutPainter(text, labelStyle)
      ..paint(canvas, Offset(anchorPoint.dx + dx, anchorPoint.dy + dy))
      ..dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..translate(layout.centre.dx, layout.centre.dy);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = gridWidth
      ..color = gridColor.withValues(alpha: gridColor.a * outerOpacity);
    final (axisStart, axisEnd) = layout.radialAxisLine();
    canvas.drawLine(axisStart, axisEnd, linePaint);
    for (final tick in layout.radialTicks(
      tickSize: tickSize,
      labelOffset: labelOffset,
    )) {
      canvas.drawLine(tick.markStart, tick.markEnd, linePaint);
      _paintLabel(canvas, tick.label, tick.labelAnchor, tick.anchor);
    }
    for (final tick in layout.angularTicks(labelOffset: labelOffset)) {
      _paintLabel(canvas, tick.label, tick.labelAnchor, tick.anchor);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FluentPolarTickPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.labelStyle != labelStyle ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.gridWidth != gridWidth ||
      oldDelegate.outerOpacity != outerOpacity ||
      oldDelegate.tickSize != tickSize ||
      oldDelegate.labelOffset != labelOffset;
}

/// A Fluent 2 polar chart: radial area, line and scatter series on a polar grid.
///
/// Ports `PolarChart` (`PolarChart.tsx:47-693`). Unlike upstream this widget
/// honours its [BoxConstraints] instead of measuring a DOM node; [width] and
/// [height] remain as hard overrides for the declarative adapters, and an
/// unbounded constraint falls back to [kPolarDefaultSize], which is the size
/// upstream paints before its first measurement (`PolarChart.tsx:54-55`).
class FluentPolarChart extends StatefulWidget {
  /// Creates a polar chart.
  const FluentPolarChart({
    required this.data,
    super.key,
    this.width,
    this.height,
    this.margins = const FluentChartMargins(),
    this.hideLegend = false,
    this.hideTooltip = false,
    this.chartTitle,
    this.hole = 0,
    this.shape = FluentPolarShape.circle,
    this.direction = FluentPolarDirection.counterclockwise,
    this.radialAxis,
    this.angularAxis,
    this.angularUnit = FluentPolarAngularUnit.degrees,
    this.culture,
    this.useUtc = false,
    this.canSelectMultipleLegends = false,
    this.selectedLegends,
    this.onLegendChange,
    this.controller,
    this.style,
  });

  /// The series to draw, discriminated by their runtime type.
  final List<FluentPolarSeries> data;

  /// Hard width override. Null means the chart takes its constraint.
  final double? width;

  /// Hard height override, applied before the legend strip is subtracted
  /// (`PolarChart.tsx:102-104`).
  final double? height;

  /// Per-side overrides of [kPolarDefaultMargins].
  final FluentChartMargins margins;

  /// Whether the legend strip is omitted (`PolarChart.tsx:608`).
  final bool hideLegend;

  /// Whether the hover popover is suppressed (`PolarChart.tsx:676`).
  final bool hideTooltip;

  /// Accessible title. Upstream never draws it (`PolarChart.tsx:649`).
  final String? chartTitle;

  /// Hole radius as a fraction of the outer radius (`PolarChart.tsx:110-113`).
  final double hole;

  /// Whether the grid rings are circles or polygons.
  final FluentPolarShape shape;

  /// Sweep direction of the angular axis.
  final FluentPolarDirection direction;

  /// Radial axis configuration.
  final FluentPolarAxisConfig? radialAxis;

  /// Angular axis configuration.
  final FluentPolarAxisConfig? angularAxis;

  /// Unit the angular tick labels are formatted in.
  final FluentPolarAngularUnit angularUnit;

  /// BCP 47 locale used by the number and date formatters.
  final String? culture;

  /// Whether dates are interpreted and formatted in UTC.
  final bool useUtc;

  /// Whether more than one legend may be selected at once.
  final bool canSelectMultipleLegends;

  /// Controlled legend selection. Copied into state on every change
  /// (`PolarChart.tsx:86-88`, which has no equality guard).
  final List<String>? selectedLegends;

  /// Called with the new selection when a legend is toggled.
  final void Function(List<String> selected)? onLegendChange;

  /// Imperative handle exposing `toImage`. Ports `componentRef`
  /// (`PolarChart.tsx:49`).
  final FluentChartController? controller;

  /// Style override, layered over the theme's.
  final FluentPolarChartStyle? style;

  @override
  State<FluentPolarChart> createState() => FluentPolarChartState();
}

/// State of a [FluentPolarChart].
///
/// Public so that a `GlobalKey<FluentPolarChartState>` can reach the imperative
/// image-export handle, which is upstream's `componentRef`
/// (`PolarChart.tsx:49`).
class FluentPolarChartState extends State<FluentPolarChart> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'FluentPolarChart');
  final GlobalKey _boundaryKey = GlobalKey();
  final FluentChartTextMeasurer _measurer = FluentChartTextMeasurer();
  late List<String> _selectedLegends =
      widget.selectedLegends ?? const <String>[];
  String _hoveredLegend = '';
  String _activePointId = '';
  int _rovingIndex = -1;
  FluentPolarMarker? _popoverMarker;
  FluentPolarLayout? _layout;

  /// The layout the chart last painted. Exposed for tests and for the export
  /// handle.
  FluentPolarLayout get layout => _layout!;

  /// Identity of the marker under the cursor or the keyboard, or the empty
  /// string.
  String get activePointId => _activePointId;

  @override
  void didUpdateWidget(FluentPolarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `:86-88` copies the prop into state on every change, unconditionally.
    if (widget.selectedLegends != oldWidget.selectedLegends) {
      _selectedLegends = widget.selectedLegends ?? const <String>[];
    }
  }

  @override
  void dispose() {
    widget.controller?.detach();
    _focusNode.dispose();
    _measurer.invalidate();
    super.dispose();
  }

  /// `getActiveLegends` (`PolarChart.tsx:429-431`).
  Set<String> get _activeLegends => _selectedLegends.isNotEmpty
      ? _selectedLegends.toSet()
      : _hoveredLegend.isNotEmpty
      ? <String>{_hoveredLegend}
      : const <String>{};

  void _showPopover(FluentPolarMarker marker) {
    setState(() {
      _activePointId = marker.id;
      // `:505` — the popover only opens when the marker's legend is
      // highlighted, which an empty active set satisfies (`:435`).
      final active = _activeLegends;
      _popoverMarker = active.isEmpty || active.contains(marker.legend)
          ? marker
          : null;
    });
  }

  void _hidePopover() {
    if (_activePointId.isEmpty && _popoverMarker == null) {
      return;
    }
    setState(() {
      _activePointId = '';
      _popoverMarker = null;
    });
  }

  void _onHover(Offset local) {
    final l = _layout;
    if (l == null) {
      return;
    }
    final p = local - l.centre;
    for (final marker in l.markers) {
      if ((marker.position - p).distance <= marker.radius) {
        _showPopover(marker);
        return;
      }
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final markers = _layout?.markers ?? const <FluentPolarMarker>[];
    if (markers.isEmpty) {
      return KeyEventResult.ignored;
    }
    final delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight => 1,
      LogicalKeyboardKey.arrowLeft => -1,
      _ => 0,
    };
    if (delta == 0) {
      return KeyEventResult.ignored;
    }
    // `:638` — axis 'horizontal' WITHOUT circular, so the traversal clamps.
    // Entering the group lands on the first marker, so an unroved chart steps
    // off index 0.
    final next = ((_rovingIndex < 0 ? 0 : _rovingIndex) + delta).clamp(
      0,
      markers.length - 1,
    );
    _rovingIndex = next;
    _showPopover(markers[next]);
    return KeyEventResult.handled;
  }

  void _onLegendChange(List<String> selected, FluentChartLegendItem? current) {
    setState(() {
      // `:595-599` — single-select keeps only the last entry, `slice(-1)`.
      _selectedLegends = widget.canSelectMultipleLegends
          ? selected
          : selected.isEmpty
          ? const <String>[]
          : <String>[selected.last];
    });
    widget.onLegendChange?.call(selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final style = resolveFluentPolarChartStyle(
      theme,
    ).merge(FluentPolarChartTheme.maybeOf(context)).merge(widget.style);
    const states = <WidgetState>{};
    final chartColors = FluentChartColors.of(theme);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKey,
      child: GestureDetector(
        // A canvas chart has nothing focusable of its own, so a click on the
        // plot is what hands the roving group its focus.
        behavior: HitTestBehavior.opaque,
        onTap: _focusNode.requestFocus,
        child: MouseRegion(
          // `:641` — the root div hides the popover on mouse leave.
          onExit: (_) => _hidePopover(),
          onHover: (event) => _onHover(event.localPosition),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // `:102-104` — the legend strip is subtracted from the height
              // before the plot is sized, whether that height came from the
              // prop or from the measured container.
              final legendHeight = widget.hideLegend ? 0.0 : kPolarLegendHeight;
              final size = Size(
                widget.width ??
                    (constraints.hasBoundedWidth
                        ? constraints.maxWidth
                        : kPolarDefaultSize),
                (widget.height ??
                        (constraints.hasBoundedHeight
                            ? constraints.maxHeight
                            : kPolarDefaultSize)) -
                    legendHeight,
              );
              final l = _solve(size);
              _layout = l;
              // `hooks.ts:23-41` — the handle is rebuilt whenever the legend
              // set or the selection changes, because `cloneLegendsToSVG` reads
              // both. Attached here rather than in `build` because the legend
              // colours only exist once the layout has been solved, and the
              // solve needs the constraints.
              widget.controller?.attach(
                FluentChartImageExporter(
                  boundaryKey: _boundaryKey,
                  legends: widget.hideLegend
                      ? const <FluentChartLegendItem>[]
                      : <FluentChartLegendItem>[
                          for (final entry in l.legendColors.entries)
                            FluentChartLegendItem(
                              title: entry.key,
                              color: entry.value,
                            ),
                        ],
                  measurer: _measurer,
                  legendTextStyle: FluentChartTextStyles.of(theme).legendLabel,
                  selectedLegends: _selectedLegends.toSet(),
                  // `PolarChart.tsx:629` passes centerLegends unconditionally.
                  centerLegends: true,
                  isRtl: Directionality.of(context) == TextDirection.rtl,
                ),
              );
              return RepaintBoundary(
                key: _boundaryKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildPlot(l, size, style, states, chartColors),
                    if (!widget.hideLegend)
                      SizedBox(height: legendHeight, child: _buildLegend(l)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// `renderLegends` (`PolarChart.tsx:607-635`).
  Widget _buildLegend(FluentPolarLayout l) => FluentChartLegend(
    legends: <FluentChartLegendItem>[
      // `:612` — the keys of the colour map, in insertion order.
      for (final entry in l.legendColors.entries)
        FluentChartLegendItem(
          title: entry.key,
          color: entry.value,
          onHoverAction: () => setState(() => _hoveredLegend = entry.key),
          onMouseOutAction: ({required bool isLegendFocused}) =>
              setState(() => _hoveredLegend = ''),
        ),
    ],
    // `:629` passes `centerLegends` unconditionally.
    centerLegends: true,
    selectionMode: widget.canSelectMultipleLegends
        ? FluentChartLegendSelectionMode.multiple
        : FluentChartLegendSelectionMode.single,
    selectedLegends: _selectedLegends,
    onChange: _onLegendChange,
  );

  FluentPolarLayout _solve(Size size) => FluentPolarLayout.compute(
    size: size,
    data: widget.data,
    margins: widget.margins,
    hole: widget.hole,
    direction: widget.direction,
    radialAxis: widget.radialAxis,
    angularAxis: widget.angularAxis,
    angularUnit: widget.angularUnit,
    useUtc: widget.useUtc,
    culture: widget.culture,
  );

  Widget _buildPlot(
    FluentPolarLayout l,
    Size size,
    FluentPolarChartStyle style,
    Set<WidgetState> states,
    FluentChartColors chartColors,
  ) {
    final gridColour = chartColors.isHighContrast
        ? chartColors.gridLine
        : style.gridLineColor!.resolve(states)!;
    return Semantics(
      container: true,
      label: _semanticsLabel(l),
      child: SizedBox.fromSize(
        size: size,
        child: Stack(
          children: <Widget>[
            // `:653` — the grid group, under everything.
            CustomPaint(
              size: size,
              painter: FluentPolarGridPainter(
                layout: l,
                shape: widget.shape,
                gridColor: gridColour,
                gridWidth: style.gridLineWidth!.resolve(states)!,
                innerOpacity: style.gridLineInnerOpacity!.resolve(states)!,
                outerOpacity: style.gridLineOuterOpacity!.resolve(states)!,
              ),
            ),
            // Only this layer repaints on a hover or a legend change.
            RepaintBoundary(
              child: CustomPaint(
                size: size,
                painter: FluentPolarSeriesPainter(
                  layout: l,
                  activeLegends: _activeLegends,
                  activePointId: _activePointId,
                  style: style,
                  states: states,
                  colors: chartColors,
                ),
              ),
            ),
            // `:671` — the ticks last, over the data.
            CustomPaint(
              size: size,
              painter: FluentPolarTickPainter(
                layout: l,
                measurer: _measurer,
                labelStyle: style.tickLabelStyle!.resolve(states)!,
                gridColor: gridColour,
                gridWidth: style.gridLineWidth!.resolve(states)!,
                outerOpacity: style.gridLineOuterOpacity!.resolve(states)!,
                tickSize: style.tickSize!.resolve(states)!,
                labelOffset: style.labelOffset!.resolve(states)!,
              ),
            ),
            // `:676` gates the whole popover on `!hideTooltip`.
            if (!widget.hideTooltip && _popoverMarker != null)
              Positioned.fill(
                // The popover follows the cursor, so letting it take the
                // pointer would pull the pointer off the marker that opened it.
                child: IgnorePointer(
                  child: FluentChartPopover(
                    data: FluentChartPopoverData(
                      xValue: _popoverMarker!.popoverXValue,
                      legend: _popoverMarker!.legend,
                      color: _popoverMarker!.color,
                      yValue: _popoverMarker!.popoverYValue,
                    ),
                    anchor: l.centre + _popoverMarker!.position,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// `PolarChart.tsx:647-650`, plus the roved marker's own label so that a
  /// canvas traversal announces something (spec section 5.7).
  String _semanticsLabel(FluentPolarLayout l) {
    final base =
        '${widget.chartTitle != null ? '${widget.chartTitle}. ' : ''}'
        'Polar chart with ${l.series.length} data series.';
    if (_rovingIndex < 0 || _rovingIndex >= l.markers.length) {
      return base;
    }
    return '$base ${l.markers[_rovingIndex].semanticLabel}';
  }
}
