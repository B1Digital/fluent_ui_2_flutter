import 'package:flutter/widgets.dart';

import 'chart_common.dart';

/// The plain independent/dependent pair.
///
/// Ports `DataPoint` (`types/DataPoint.ts:59-77`). Its x is `number | string`
/// only; the stacked variant below is what widens it to admit a date.
@immutable
class FluentChartXYPoint {
  /// Creates a point.
  const FluentChartXYPoint({required this.x, required this.y, this.onClick})
    : assert(
        x is num || x is String,
        'types/DataPoint.ts:64 — `number | string`.',
      );

  /// The independent value. A number plots at its own coordinate; a string
  /// spaces evenly along the axis.
  final Object x;

  /// The dependent value.
  final double y;

  /// Invoked when this point is activated.
  final VoidCallback? onClick;
}

/// A stacked-bar point, whose x may also be a date.
///
/// Ports `VerticalStackedBarDataPoint` (`types/DataPoint.ts:82-90`), which is
/// `DataPoint` with `x` overridden to `number | string | Date`.
@immutable
class FluentVerticalStackedBarDataPoint {
  /// Creates a stacked-bar point.
  const FluentVerticalStackedBarDataPoint({
    required this.x,
    required this.y,
    this.onClick,
  }) : assert(
         x is num || x is String || x is DateTime,
         'types/DataPoint.ts:89 — `number | string | Date`.',
       );

  /// The independent value.
  final Object x;

  /// The dependent value.
  final double y;

  /// Invoked when this point is activated.
  final VoidCallback? onClick;
}

/// The single-bar datum a horizontal bar's total is read from.
///
/// Ports `HorizontalDataPoint` (`types/DataPoint.ts:95-107`).
@immutable
class FluentHorizontalDataPoint {
  /// Creates a horizontal-bar datum.
  const FluentHorizontalDataPoint({required this.x, this.total});

  /// The filled portion.
  final double x;

  /// The whole the bar is measured against.
  final double? total;
}

/// The donut and horizontal-bar datum.
///
/// Ports `ChartDataPoint` (`types/DataPoint.ts:112-159`). Every field is
/// optional upstream, which is why this class has no required parameter.
@immutable
class FluentChartDataPoint {
  /// Creates a datum.
  const FluentChartDataPoint({
    this.legend,
    this.data,
    this.horizontalBarChartData,
    this.onClick,
    this.color,
    this.placeHolder = false,
    this.xAxisCalloutData,
    this.yAxisCalloutData,
    this.callOutSemantics,
  });

  /// The legend text.
  final String? legend;

  /// The value (`types/DataPoint.ts:121`).
  final double? data;

  /// The filled/total pair a horizontal bar renders
  /// (`types/DataPoint.ts:126`, spelled `horizontalBarChartdata` upstream with a
  /// lower-case `d`).
  final FluentHorizontalDataPoint? horizontalBarChartData;

  /// Invoked when this datum is activated.
  final VoidCallback? onClick;

  /// The datum's colour. Null takes the next palette entry.
  final Color? color;

  /// Whether this datum only reserves space and draws nothing
  /// (`types/DataPoint.ts:139`).
  final bool placeHolder;

  /// Replacement text for the x value in the callout.
  final String? xAxisCalloutData;

  /// Replacement text for the y value in the callout.
  final String? yAxisCalloutData;

  /// Accessible naming for the callout.
  final FluentChartSemantics? callOutSemantics;
}

/// The line overlaid on a vertical bar chart, at one x.
///
/// Ports `LineDataInVerticalBarChart` (`types/DataPoint.ts:278-291`).
@immutable
class FluentBarLineDatum {
  /// Creates a line datum.
  const FluentBarLineDatum({
    required this.y,
    this.yAxisCalloutData,
    this.onClick,
    this.useSecondaryYScale = false,
  });

  /// The line's value at this bar's x.
  final double y;

  /// Replacement text for the value in the callout.
  final String? yAxisCalloutData;

  /// Invoked when this line point is activated.
  final VoidCallback? onClick;

  /// Whether the line is plotted against the secondary y scale.
  final bool useSecondaryYScale;
}

/// One bar of a vertical bar chart.
///
/// Ports `VerticalBarChartDataPoint` (`types/DataPoint.ts:164-219`).
@immutable
class FluentVerticalBarChartDataPoint {
  /// Creates a bar.
  const FluentVerticalBarChartDataPoint({
    required this.x,
    required this.y,
    this.legend,
    this.color,
    this.xAxisCalloutData,
    this.yAxisCalloutData,
    this.lineData,
    this.onClick,
    this.callOutSemantics,
    this.barLabel,
  }) : assert(
         x is num || x is String || x is DateTime,
         'types/DataPoint.ts:170 — `number | string | Date`.',
       );

  /// The independent value.
  final Object x;

  /// The bar height.
  final double y;

  /// The legend text this bar belongs to.
  final String? legend;

  /// The bar's colour.
  final Color? color;

  /// Replacement text for the x value in the callout.
  final String? xAxisCalloutData;

  /// Replacement text for the y value in the callout.
  final String? yAxisCalloutData;

  /// The overlaid line's value at this bar (`types/DataPoint.ts:200`).
  final FluentBarLineDatum? lineData;

  /// Invoked when this bar is activated.
  final VoidCallback? onClick;

  /// Accessible naming for the callout.
  final FluentChartSemantics? callOutSemantics;

  /// Text drawn on the bar, replacing the formatted value
  /// (`types/DataPoint.ts:218`).
  final String? barLabel;
}
