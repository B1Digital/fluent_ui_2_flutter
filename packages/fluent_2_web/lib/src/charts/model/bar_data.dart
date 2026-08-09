import 'package:flutter/widgets.dart';

import '../chrome/legend_shape.dart';
import 'chart_common.dart';
import 'line_options.dart';

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

/// One bar of a horizontal bar chart with an axis.
///
/// Ports `HorizontalBarChartWithAxisDataPoint` (`types/DataPoint.ts:224-273`).
/// The axis roles are inverted relative to every other bar chart: `x` is the
/// **dependent** value (`:228`) and `y` is the independent one (`:235`).
@immutable
class FluentHorizontalBarChartWithAxisDataPoint {
  /// Creates a bar.
  const FluentHorizontalBarChartWithAxisDataPoint({
    required this.x,
    required this.y,
    this.legend,
    this.color,
    this.xAxisCalloutData,
    this.yAxisCalloutData,
    this.barLabel,
    this.onClick,
    this.callOutSemantics,
  }) : assert(
         y is num || y is String,
         'types/DataPoint.ts:235 — `number | string`. There is no Date arm.',
       );

  /// The bar length — the dependent value, drawn along x.
  final double x;

  /// The category or coordinate the bar sits at — the independent value.
  final Object y;

  /// The legend text this bar belongs to.
  final String? legend;

  /// The bar's colour.
  final Color? color;

  /// Replacement text for the x value in the callout.
  final String? xAxisCalloutData;

  /// Replacement text for the y value in the callout.
  final String? yAxisCalloutData;

  /// Text drawn on the bar.
  final String? barLabel;

  /// Invoked when this bar is activated.
  final VoidCallback? onClick;

  /// Accessible naming for the callout.
  final FluentChartSemantics? callOutSemantics;
}

/// One segment of a stacked bar.
///
/// Ports `VSChartDataPoint` (`types/DataPoint.ts:608-651`).
@immutable
class FluentStackedBarDatum {
  /// Creates a segment.
  const FluentStackedBarDatum({
    required this.data,
    required this.legend,
    this.color,
    this.xAxisCalloutData,
    this.yAxisCalloutData,
    this.callOutSemantics,
    this.culture,
    this.barLabel,
  }) : assert(
         data is num || data is String,
         'types/DataPoint.ts:612 — `number | string`.',
       );

  /// The segment's value.
  ///
  /// Stays an [Object] because the runtime type changes the chart's geometry: a
  /// number is a linear height (`VerticalStackedBarChart.tsx:1068`), a string
  /// makes the y axis a band scale (`:1012`, `:1060`), and `''` means "no bar"
  /// (`:1008-1009`).
  final Object data;

  /// The legend text this segment belongs to.
  final String legend;

  /// The segment's colour.
  final Color? color;

  /// Replacement text for the x value in the callout.
  final String? xAxisCalloutData;

  /// Replacement text for the y value in the callout.
  final String? yAxisCalloutData;

  /// Accessible naming for the callout.
  final FluentChartSemantics? callOutSemantics;

  /// The locale numbers in this segment's callout are formatted with
  /// (`types/DataPoint.ts:643`).
  final String? culture;

  /// Text drawn on the segment.
  final String? barLabel;
}

/// One point of a line overlaid on a stacked bar chart.
///
/// Ports `LineDataInVerticalStackedBarChart` (`types/DataPoint.ts:685-708`).
@immutable
class FluentStackedBarLineDatum {
  /// Creates a line point.
  const FluentStackedBarLineDatum({
    required this.y,
    required this.color,
    required this.legend,
    this.legendShape,
    this.data,
    this.yAxisCalloutData,
    this.useSecondaryYScale = false,
    this.lineOptions,
  }) : assert(
         y is num || y is String,
         'types/DataPoint.ts:686 — `number | string`.',
       ),
       assert(
         data == null || data is num || data is String,
         'types/DataPoint.ts:697 — `number | string`.',
       );

  /// The line's value at this stack.
  final Object y;

  /// The line's colour.
  final Color color;

  /// The legend text.
  final String legend;

  /// The legend swatch shape.
  final FluentChartLegendShape? legendShape;

  /// The value shown in the callout, when it differs from [y].
  final Object? data;

  /// Replacement text for the value in the callout.
  final String? yAxisCalloutData;

  /// Whether the line is plotted against the secondary y scale.
  final bool useSecondaryYScale;

  /// How the line is stroked.
  final FluentLineOptions? lineOptions;

  /// [data] when it is truthy, and [y] otherwise.
  ///
  /// `VerticalStackedBarChart.tsx:276` is `item.data = item.data || item.y`,
  /// which mutates the caller's object upstream. It is a getter here instead.
  ///
  /// `// parity:` the `||` swallows a legitimate `0` and a legitimate `''`, and
  /// that is reproduced rather than fixed.
  Object get resolvedData {
    final value = data;
    if (value == null) return y;
    // Zero is falsy in JavaScript, so upstream's `||` discards it.
    if (value is num && value == 0) return y;
    if (value is String && value.isEmpty) return y;
    return value;
  }
}

/// One stack of a vertical stacked bar chart.
///
/// Ports `VerticalStackedChartProps` (`types/DataPoint.ts:656-680`).
@immutable
class FluentVerticalStackedBarGroup {
  /// Creates a stack.
  const FluentVerticalStackedBarGroup({
    required this.chartData,
    required this.xAxisPoint,
    this.xAxisCalloutData,
    this.lineData,
    this.stackCallOutSemantics,
  }) : assert(
         xAxisPoint is num || xAxisPoint is String || xAxisPoint is DateTime,
         'types/DataPoint.ts:665 — `number | string | Date`.',
       );

  /// The segments, bottom to top.
  final List<FluentStackedBarDatum> chartData;

  /// The x this stack sits at.
  final Object xAxisPoint;

  /// Replacement text for the x value in the callout.
  final String? xAxisCalloutData;

  /// Line points drawn over this stack.
  final List<FluentStackedBarLineDatum>? lineData;

  /// Accessible naming for the whole-stack callout.
  final FluentChartSemantics? stackCallOutSemantics;
}
