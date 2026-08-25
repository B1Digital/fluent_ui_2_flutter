import 'package:flutter/widgets.dart';

import '../chrome/legend_shape.dart';
import 'chart_common.dart';
import 'line_options.dart';

/// One point of a polar series.
///
/// Ports `PolarDataPoint` (`types/DataPoint.ts:1279-1317`).
@immutable
class FluentPolarDataPoint {
  /// Creates a polar point.
  const FluentPolarDataPoint({
    required this.r,
    required this.theta,
    this.onClick,
    this.radialAxisCalloutData,
    this.angularAxisCalloutData,
    this.callOutSemantics,
    this.markerSize,
    this.text,
    this.color,
  }) : assert(
         r is num || r is String || r is DateTime,
         'types/DataPoint.ts:1283 — `string | number | Date`.',
       ),
       assert(
         theta is num || theta is String,
         'types/DataPoint.ts:1288 — `string | number`, a category or degrees. '
         'There is no Date arm.',
       );

  /// The radial value.
  final Object r;

  /// The angular value: a category, or degrees.
  final Object theta;

  /// Invoked when this point is activated.
  final VoidCallback? onClick;

  /// Replacement text for the radial value in the callout.
  final String? radialAxisCalloutData;

  /// Replacement text for the angular value in the callout.
  final String? angularAxisCalloutData;

  /// Accessible naming for the callout.
  final FluentChartSemantics? callOutSemantics;

  /// A per-point marker radius.
  final double? markerSize;

  /// A label drawn beside the marker.
  final String? text;

  /// A per-point colour, overriding the series colour.
  final Color? color;
}

/// The polar-only members that reach a chart through `lineOptions` upstream.
///
/// `scatterpolar-utils.tsx:69-87` (`extractMaybeLineOptions`) pulls exactly
/// these four out of the raw `lineOptions` bag. Spec §5.6 moves them off
/// [FluentLineOptions], because none of them says anything about a stroke.
@immutable
class FluentPolarLineOptions {
  /// Creates a polar line configuration.
  const FluentPolarLineOptions({
    this.direction,
    this.axisLabel,
    this.rotation,
    this.originXOffset,
  }) : assert(
         direction == null ||
             direction == 'clockwise' ||
             direction == 'counterclockwise',
         "scatterpolar-utils.tsx:80-83 keeps 'clockwise' and "
         "'counterclockwise' and normalises anything else to undefined.",
       );

  /// `'clockwise'` or `'counterclockwise'` (`scatterpolar-utils.tsx:80-83`).
  final String? direction;

  /// Explicit angular-axis labels, one per category.
  ///
  /// A `List<String>` and not a single string: `scatterpolar-utils.tsx:84` keeps
  /// the value only when `Array.isArray` holds, and the declared shape at
  /// `:79-85` is `string[]`. Correcting the cross-plan contract, recorded in
  /// this plan's preamble.
  final List<String>? axisLabel;

  /// Rotation of the polar origin, in degrees (`scatterpolar-utils.tsx:83`).
  final double? rotation;

  /// Horizontal offset of the polar origin, in logical pixels
  /// (`scatterpolar-utils.tsx:79`).
  final double? originXOffset;
}

/// One polar series.
///
/// Ports `DataSeries` (`types/DataPoint.ts:1184-1215`) as specialised by
/// `ScatterPolarSeries` (`:1329-1341`), `LinePolarSeries` (`:1344-1361`) and
/// `AreaPolarSeries` (`:1364-1381`). Sealed rather than tagged, because the
/// upstream `type` discriminator exists only to make the union checkable.
sealed class FluentPolarSeries {
  /// Creates a polar series.
  const FluentPolarSeries({
    required this.legend,
    required this.data,
    this.legendShape,
    this.color,
    this.opacity,
    this.gradient,
    this.useSecondaryYScale = false,
    this.onLegendClick,
  });

  /// The series name, shown in the legend.
  final String legend;

  /// The points.
  final List<FluentPolarDataPoint> data;

  /// The legend swatch shape.
  final FluentChartLegendShape? legendShape;

  /// The series colour.
  final Color? color;

  /// The series opacity.
  final double? opacity;

  /// A two-stop gradient that overrides [color] when gradients are enabled.
  final (Color, Color)? gradient;

  /// Whether this series is plotted against the secondary scale.
  final bool useSecondaryYScale;

  /// Invoked with the full selection after this legend is clicked.
  final void Function(List<String> selected)? onLegendClick;
}

/// `'scatterpolar'` — markers only.
final class FluentScatterPolarSeries extends FluentPolarSeries {
  /// Creates a scatterpolar series.
  const FluentScatterPolarSeries({
    required super.legend,
    required super.data,
    super.legendShape,
    super.color,
    super.opacity,
    super.gradient,
    super.useSecondaryYScale,
    super.onLegendClick,
  });
}

/// `'linepolar'` — a stroked line through the points.
final class FluentLinePolarSeries extends FluentPolarSeries {
  /// Creates a linepolar series.
  const FluentLinePolarSeries({
    required super.legend,
    required super.data,
    this.lineOptions,
    this.polarLineOptions,
    super.legendShape,
    super.color,
    super.opacity,
    super.gradient,
    super.useSecondaryYScale,
    super.onLegendClick,
  });

  /// How the line is stroked.
  final FluentLineOptions? lineOptions;

  /// The four polar-only members split off by spec §5.6.
  final FluentPolarLineOptions? polarLineOptions;
}

/// `'areapolar'` — a closed, filled region.
final class FluentAreaPolarSeries extends FluentPolarSeries {
  /// Creates an areapolar series.
  const FluentAreaPolarSeries({
    required super.legend,
    required super.data,
    this.lineOptions,
    this.polarLineOptions,
    super.legendShape,
    super.color,
    super.opacity,
    super.gradient,
    super.useSecondaryYScale,
    super.onLegendClick,
  });

  /// How the boundary is stroked, including
  /// [FluentLineOptions.fill] — `'toself'` is what closes the path
  /// (`LineChart.tsx:1318-1343`).
  final FluentLineOptions? lineOptions;

  /// The four polar-only members split off by spec §5.6.
  final FluentPolarLineOptions? polarLineOptions;
}

/// Tick and range configuration for a polar axis.
///
/// Ports `PolarAxisProps` (`PolarChart.types.ts:18-57`), which is `AxisProps`
/// plus seven members.
@immutable
class FluentPolarAxisConfig extends FluentAxisConfig {
  /// Creates a polar axis configuration.
  const FluentPolarAxisConfig({
    super.tickStep,
    super.tick0,
    super.tickText,
    this.tickValues,
    this.tickFormat,
    this.tickCount,
    this.categoryOrder = FluentAxisCategoryOrder.defaultOrder,
    this.scaleType = FluentAxisScaleType.auto,
    this.rangeStart,
    this.rangeEnd,
  }) : assert(
         rangeStart == null || rangeStart is num || rangeStart is DateTime,
         'PolarChart.types.ts:51 — `number | Date`.',
       ),
       assert(
         rangeEnd == null || rangeEnd is num || rangeEnd is DateTime,
         'PolarChart.types.ts:56 — `number | Date`.',
       );

  /// Explicit tick positions (`PolarChart.types.ts:22`), each a number, a
  /// [DateTime] or a category.
  final List<Object>? tickValues;

  /// A d3-format specifier applied to each tick (`PolarChart.types.ts:29`).
  final String? tickFormat;

  /// The requested number of ticks (`PolarChart.types.ts:34`).
  final int? tickCount;

  /// How the categories on this axis are ordered (`PolarChart.types.ts:40`).
  final FluentAxisCategoryOrder categoryOrder;

  /// Which scale this axis is built with (`PolarChart.types.ts:46`).
  final FluentAxisScaleType scaleType;

  /// The start of the axis range (`PolarChart.types.ts:51`).
  final Object? rangeStart;

  /// The end of the axis range (`PolarChart.types.ts:56`).
  final Object? rangeEnd;
}
