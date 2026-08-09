import 'package:flutter/widgets.dart';

import 'chart_common.dart';

/// One cell of a heat map.
///
/// Ports `HeatMapChartDataPoint` (`types/DataPoint.ts:851-875`).
@immutable
class FluentHeatMapChartDataPoint {
  /// Creates a cell.
  const FluentHeatMapChartDataPoint({
    required this.x,
    required this.y,
    required this.value,
    this.rectText,
    this.ratio,
    this.descriptionMessage,
    this.onClick,
    this.callOutSemantics,
  }) : assert(
         x is num || x is String || x is DateTime,
         'types/DataPoint.ts:852 — `string | Date | number`.',
       ),
       assert(
         y is num || y is String || y is DateTime,
         'types/DataPoint.ts:853 — `string | Date | number`.',
       ),
       assert(
         rectText == null || rectText is num || rectText is String,
         'types/DataPoint.ts:858 — `string | number`.',
       );

  /// The column this cell sits in.
  ///
  /// A `num`, a [String] or a [DateTime] (`types/DataPoint.ts:852`).
  final Object x;

  /// The row this cell sits in.
  ///
  /// A `num`, a [String] or a [DateTime] (`types/DataPoint.ts:853`).
  final Object y;

  /// The value the cell's colour is interpolated from
  /// (`types/DataPoint.ts:854`).
  final double value;

  /// The text drawn inside the cell, when it differs from [value].
  ///
  /// A `num` or a [String] (`types/DataPoint.ts:855-858`).
  final Object? rectText;

  /// A numerator/denominator pair shown in the callout
  /// (`types/DataPoint.ts:862`).
  final (double, double)? ratio;

  /// An extra line of text in the callout (`types/DataPoint.ts:867`).
  final String? descriptionMessage;

  /// Invoked when this cell is activated (`types/DataPoint.ts:872`).
  final VoidCallback? onClick;

  /// Accessible naming for the callout (`types/DataPoint.ts:874`).
  final FluentChartSemantics? callOutSemantics;
}

/// One legend band of a heat map, with the cells that belong to it.
///
/// Ports `HeatMapChartData` (`types/DataPoint.ts:881-891`).
@immutable
class FluentHeatMapChartData {
  /// Creates a band.
  const FluentHeatMapChartData({
    required this.legend,
    required this.data,
    required this.value,
  });

  /// The band's name (`types/DataPoint.ts:885`).
  final String legend;

  /// The cells in the band (`types/DataPoint.ts:886`).
  final List<FluentHeatMapChartDataPoint> data;

  /// The value the band's legend colour is chosen from
  /// (`types/DataPoint.ts:888-890`).
  final double value;
}
