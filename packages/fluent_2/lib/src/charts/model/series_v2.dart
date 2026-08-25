/// GroupedVerticalBarChart's second input shape.
///
/// `GroupedVerticalBarChart.tsx:298-304` prefers `dataV2` over `data`, but only
/// when `dataV2` is a non-empty list. `_processDataV2` (`:267-296`) then drops
/// `gradient`, `opacity`, `legendShape`, `onLegendClick`, `markerSize`, `text`
/// and `callOutAccessibilityData` for every bar series, so a caller that sets
/// them on a [FluentBarSeries] will not see them rendered — that is upstream
/// behaviour, not an omission here.
library;

import 'package:flutter/widgets.dart';

import '../chrome/legend_shape.dart';
import 'cartesian_series.dart';
import 'chart_common.dart';
import 'line_options.dart';

/// One point of a v2 series.
///
/// Ports `DataPointV2<X, Y>` (`types/DataPoint.ts:1134-1179`). Non-generic here:
/// both consumers read the coordinates as `Object` and immediately dispatch on
/// the runtime type, so two type parameters would buy nothing and would leak
/// into every signature that touches a series.
@immutable
class FluentDataPointV2 {
  /// Creates a v2 point.
  const FluentDataPointV2({
    required this.x,
    required this.y,
    this.onClick,
    this.xAxisCalloutData,
    this.yAxisCalloutData,
    this.callOutSemantics,
    this.markerSize,
    this.text,
    this.color,
  }) : assert(
         x is num || x is String || x is DateTime,
         'types/DataPoint.ts:1134 — `string | number | Date`.',
       ),
       assert(
         y is num || y is String || y is DateTime,
         'types/DataPoint.ts:1134 — `string | number | Date`.',
       );

  /// The independent value (`types/DataPoint.ts:1138`).
  final Object x;

  /// The dependent value (`types/DataPoint.ts:1143`).
  final Object y;

  /// Invoked when this point is activated (`types/DataPoint.ts:1148`).
  final VoidCallback? onClick;

  /// Replacement text for the x value in the callout
  /// (`types/DataPoint.ts:1153`).
  final String? xAxisCalloutData;

  /// Replacement text for the y value in the callout
  /// (`types/DataPoint.ts:1158`).
  final String? yAxisCalloutData;

  /// Accessible naming for the callout, upstream's
  /// `callOutAccessibilityData` (`types/DataPoint.ts:1163`).
  final FluentChartSemantics? callOutSemantics;

  /// A per-point marker radius (`types/DataPoint.ts:1168`).
  final double? markerSize;

  /// A label drawn beside the point (`types/DataPoint.ts:1173`).
  final String? text;

  /// A per-point colour, overriding the series colour
  /// (`types/DataPoint.ts:1178`).
  final Color? color;
}

/// One v2 series.
///
/// Ports `DataSeries` (`types/DataPoint.ts:1184-1214`). Sealed rather than
/// tagged: upstream's `type: 'bar' | 'line'` discriminator exists only so
/// TypeScript can narrow the union.
sealed class FluentDataSeries {
  /// Creates a v2 series.
  const FluentDataSeries({
    required this.legend,
    required this.data,
    this.legendShape,
    this.color,
    this.opacity,
    this.gradient,
    this.useSecondaryYScale = false,
    this.onLegendClick,
  });

  /// The series name, shown in the legend (`types/DataPoint.ts:1188`).
  final String legend;

  /// The points (`types/DataPoint.ts:1233` and `:1253`, which is where upstream
  /// declares `data` on each arm rather than on the base).
  final List<FluentDataPointV2> data;

  /// The legend swatch shape (`types/DataPoint.ts:1193`).
  final FluentChartLegendShape? legendShape;

  /// The series colour (`types/DataPoint.ts:1198`).
  final Color? color;

  /// The series opacity (`types/DataPoint.ts:1203`).
  final double? opacity;

  /// A two-stop gradient that overrides [color] when gradients are enabled
  /// (`types/DataPoint.ts:1208`).
  final (Color, Color)? gradient;

  /// Whether this series is plotted against the secondary y scale
  /// (`types/DataPoint.ts:1213`).
  ///
  /// False rather than null because `_processDataV2`
  /// (`GroupedVerticalBarChart.tsx:287`) copies the raw value onto every bar
  /// point, where an absent flag and a false flag are indistinguishable.
  final bool useSecondaryYScale;

  /// Invoked with the full selection after this legend is clicked
  /// (`types/DataPoint.ts:1218`).
  final void Function(List<String> selected)? onLegendClick;
}

/// `type: 'bar'` (`types/DataPoint.ts:1224-1239`).
final class FluentBarSeries extends FluentDataSeries {
  /// Creates a bar series.
  const FluentBarSeries({
    required super.legend,
    required super.data,
    this.key,
    super.legendShape,
    super.color,
    super.opacity,
    super.gradient,
    super.useSecondaryYScale,
    super.onLegendClick,
  });

  /// An optional group identifier (`types/DataPoint.ts:1238`).
  ///
  /// `_processDataV2` (`GroupedVerticalBarChart.tsx:279`) falls back to
  /// [FluentDataSeries.legend] when it is null.
  final String? key;
}

/// `type: 'line'` (`types/DataPoint.ts:1244-1274`).
final class FluentLineSeries extends FluentDataSeries {
  /// Creates a line series.
  const FluentLineSeries({
    required super.legend,
    required super.data,
    this.gaps,
    this.lineOptions,
    this.hideInactiveDots = false,
    this.onLineClick,
    super.legendShape,
    super.color,
    super.opacity,
    super.gradient,
    super.useSecondaryYScale,
    super.onLegendClick,
  });

  /// Index runs the line skips (`types/DataPoint.ts:1258`).
  final List<FluentLineChartGap>? gaps;

  /// How the line is stroked (`types/DataPoint.ts:1263`).
  final FluentLineOptions? lineOptions;

  /// Whether markers on unhovered points are hidden
  /// (`types/DataPoint.ts:1268`).
  final bool hideInactiveDots;

  /// Invoked when the drawn line itself is activated
  /// (`types/DataPoint.ts:1273`).
  final VoidCallback? onLineClick;
}
