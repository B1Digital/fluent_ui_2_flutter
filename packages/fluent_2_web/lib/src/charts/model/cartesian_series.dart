import 'package:flutter/widgets.dart';

import '../chrome/legend_shape.dart';
import 'bar_data.dart';
import 'chart_common.dart';
import 'line_options.dart';
import 'polar_data.dart';
import 'sankey_data.dart';

/// One point of a line series.
///
/// Ports `LineChartDataPoint` (`types/DataPoint.ts:336-356`) together with the
/// `BaseDataPoint` members it extends (`:296-330`). Its [x] is the only one in
/// the library that excludes a string: `types/DataPoint.ts:340` is
/// `number | Date`, where the scatter point at `:366` also admits a string.
@immutable
class FluentLineChartDataPoint {
  /// Creates a line point.
  const FluentLineChartDataPoint({
    required this.x,
    required this.y,
    this.text,
    this.markerColor,
    this.markerSize,
    this.onDataPointClick,
    this.xAxisCalloutData,
    this.yAxisCalloutText,
    this.yAxisCalloutBreakdown,
    this.hideCallout = false,
    this.callOutSemantics,
    this.xAxisCalloutSemantics,
  }) : assert(
         x is num || x is DateTime,
         'types/DataPoint.ts:340 — `number | Date`. A category x belongs on a '
         'FluentScatterChartDataPoint.',
       );

  /// The independent value: a number or a [DateTime].
  final Object x;

  /// The dependent value.
  final double y;

  /// A label drawn beside the marker when the mode includes text.
  final String? text;

  /// A per-point marker colour, overriding the series colour.
  final Color? markerColor;

  /// A per-point marker radius, overriding the chart's.
  final double? markerSize;

  /// Invoked when this point is activated.
  final VoidCallback? onDataPointClick;

  /// Replacement text for the x value in the callout.
  final String? xAxisCalloutData;

  /// Replacement text for the y value — the `string` arm of
  /// `types/DataPoint.ts:310`.
  final String? yAxisCalloutText;

  /// A named breakdown shown instead of a single y — the `{[id]: number}` arm of
  /// `types/DataPoint.ts:310`.
  final Map<String, double>? yAxisCalloutBreakdown;

  /// Whether this point is left out of the callout entirely.
  ///
  /// `utilities.ts:1017` filters on `!point.hideCallout`, so an unset value
  /// means the point is shown.
  final bool hideCallout;

  /// Accessible naming for this point's callout.
  final FluentChartSemantics? callOutSemantics;

  /// Accessible naming for the x value in this point's callout.
  final FluentChartSemantics? xAxisCalloutSemantics;
}

/// One point of a scatter series.
///
/// Ports `ScatterChartDataPoint` (`types/DataPoint.ts:362-382`) plus the
/// `BaseDataPoint` members (`:296-330`).
@immutable
class FluentScatterChartDataPoint {
  /// Creates a scatter point.
  const FluentScatterChartDataPoint({
    required this.x,
    required this.y,
    this.text,
    this.markerColor,
    this.markerSize,
    this.onDataPointClick,
    this.xAxisCalloutData,
    this.yAxisCalloutText,
    this.yAxisCalloutBreakdown,
    this.hideCallout = false,
    this.callOutSemantics,
    this.xAxisCalloutSemantics,
  }) : assert(
         x is num || x is DateTime || x is String,
         'types/DataPoint.ts:366 — `number | Date | string`.',
       ),
       assert(
         y is num || y is String,
         'ScatterChart.tsx:126-132 and :410-412 branch on `typeof y === '
         "'string'`, so a category y is a live arm even though "
         'types/DataPoint.ts:376 narrows the declared type to `number`.',
       );

  /// The independent value: a number, a [DateTime] or a category.
  final Object x;

  /// The dependent value: a number, or a category on a band y axis.
  ///
  /// Declared `number` upstream (`types/DataPoint.ts:376`) but read as
  /// `typeof y === 'string'` in two places ScatterChart cannot reach otherwise
  /// — the y-axis type at `ScatterChart.tsx:126-132` and the band centring at
  /// `:410-412` — so the declaration is the narrower of the two and this is the
  /// one the port follows.
  final Object y;

  /// A label drawn beside the marker when the mode includes text.
  final String? text;

  /// A per-point marker colour, overriding the series colour.
  final Color? markerColor;

  /// A per-point marker radius, overriding the chart's.
  final double? markerSize;

  /// Invoked when this point is activated.
  final VoidCallback? onDataPointClick;

  /// Replacement text for the x value in the callout.
  final String? xAxisCalloutData;

  /// Replacement text for the y value.
  final String? yAxisCalloutText;

  /// A named breakdown shown instead of a single y.
  final Map<String, double>? yAxisCalloutBreakdown;

  /// Whether this point is left out of the callout entirely.
  final bool hideCallout;

  /// Accessible naming for this point's callout.
  final FluentChartSemantics? callOutSemantics;

  /// Accessible naming for the x value in this point's callout.
  final FluentChartSemantics? xAxisCalloutSemantics;
}

/// A run of indices a line is not drawn through.
///
/// Ports `LineChartGap` (`types/DataPoint.ts:392-402`).
@immutable
class FluentLineChartGap {
  /// Creates a gap.
  const FluentLineChartGap({required this.startIndex, required this.endIndex});

  /// The index the gap starts at.
  final int startIndex;

  /// The index the gap ends at.
  final int endIndex;
}

/// One line series.
///
/// Ports `LineChartPoints` (`types/DataPoint.ts:477-533`). Upstream's
/// `hideNonActiveDots` is spelled [hideInactiveDots] here, matching the name the
/// v2 series shape already uses (`types/DataPoint.ts:1268`).
@immutable
class FluentLineChartSeries {
  /// Creates a line series.
  const FluentLineChartSeries({
    required this.legend,
    required this.data,
    this.legendShape,
    this.gaps,
    this.color,
    this.opacity,
    this.lineOptions,
    this.polarLineOptions,
    this.hideInactiveDots = false,
    this.onLegendClick,
    this.onLineClick,
    this.useSecondaryYScale = false,
  });

  /// The series name, shown in the legend.
  final String legend;

  /// The points, each a [FluentLineChartDataPoint] or a
  /// [FluentScatterChartDataPoint] — upstream's
  /// `LineChartDataPoint[] | ScatterChartDataPoint[]` (`types/DataPoint.ts:492`).
  final List<Object> data;

  /// The legend swatch shape. Null draws the default rectangle.
  final FluentChartLegendShape? legendShape;

  /// Index runs the line skips.
  final List<FluentLineChartGap>? gaps;

  /// The series colour. Null takes the next palette entry.
  final Color? color;

  /// Fill opacity for the area under the line, where a chart draws one.
  final double? opacity;

  /// How the line is stroked.
  final FluentLineOptions? lineOptions;

  /// The four polar-only members `lineOptions` also carries upstream.
  ///
  /// `LineChart.tsx:1352` hands `_points[i].lineOptions` to
  /// `renderScatterPolarCategoryLabels`, which keeps exactly `direction`,
  /// `axisLabel`, `rotation` and `originXOffset` (`scatterpolar-utils.tsx:69-87`).
  /// Spec §5.6 splits them off [lineOptions] because none of them says anything
  /// about a stroke.
  final FluentPolarLineOptions? polarLineOptions;

  /// Whether markers on unhovered points are hidden.
  final bool hideInactiveDots;

  /// Invoked with the full selection after this legend is clicked.
  ///
  /// Upstream's parameter is `string | null | string[]`
  /// (`types/DataPoint.ts:520`); the empty list is the Dart spelling of the null
  /// arm. Recorded divergence.
  final void Function(List<String> selected)? onLegendClick;

  /// Invoked when the drawn line itself is activated.
  final VoidCallback? onLineClick;

  /// Whether this series is plotted against the secondary y scale.
  final bool useSecondaryYScale;
}

/// One scatter series.
///
/// Ports `ScatterChartPoints` (`types/DataPoint.ts:1033-1075`) — the line series
/// without [FluentLineChartSeries.gaps] or
/// [FluentLineChartSeries.onLineClick].
@immutable
class FluentScatterChartSeries {
  /// Creates a scatter series.
  const FluentScatterChartSeries({
    required this.legend,
    required this.data,
    this.legendShape,
    this.color,
    this.opacity,
    this.lineOptions,
    this.polarLineOptions,
    this.hideInactiveDots = false,
    this.onLegendClick,
    this.useSecondaryYScale = false,
  });

  /// The series name, shown in the legend.
  final String legend;

  /// The points.
  final List<FluentScatterChartDataPoint> data;

  /// The legend swatch shape.
  final FluentChartLegendShape? legendShape;

  /// The series colour.
  final Color? color;

  /// Marker fill opacity.
  final double? opacity;

  /// The mode bag ScatterChart reads through a cast.
  ///
  /// `ScatterChartPoints` (`types/DataPoint.ts:1033-1075`) declares no such
  /// member, yet `ScatterChart.tsx:243-244` hands `_points` to `isTextMode`
  /// (`utilities.ts:2219`) and `isScatterPolarSeries` (`:2207`), both of which
  /// reach it through `as any`, and `:501` casts to `Partial<LineChartPoints>`
  /// for the same reason. The one producer that fills it is the Plotly adapter,
  /// which builds scatter and line traces from the same function and returns
  /// them `as LineChartPoints` (`PlotlySchemaAdapter.ts:2067-2085`,
  /// `:1942-1957`). Declaring it is the typed spelling of that cast.
  final FluentLineOptions? lineOptions;

  /// The four polar-only members, as on [FluentLineChartSeries].
  ///
  /// Read at `ScatterChart.tsx:501` off the same casted bag as [lineOptions].
  final FluentPolarLineOptions? polarLineOptions;

  /// Whether markers on unhovered points are hidden.
  final bool hideInactiveDots;

  /// Invoked with the full selection after this legend is clicked.
  final void Function(List<String> selected)? onLegendClick;

  /// Whether this series is plotted against the secondary y scale.
  final bool useSecondaryYScale;
}

/// The data bundle every cartesian chart takes.
///
/// Ports `ChartProps` (`types/DataPoint.ts:539-583`), renamed because it is a
/// data bundle and not a widget's props: a chart takes it as one field.
/// Upstream's `pointOptions` and `pointLineOptions` are raw SVG attribute bags;
/// the only member either of them contributes is the marker radius, which
/// becomes [markerRadius].
@immutable
class FluentChartData {
  /// Creates a data bundle.
  const FluentChartData({
    this.chartTitle,
    this.chartTitleSemantics,
    this.chartData,
    this.chartDataSemantics,
    this.lineChartData,
    this.scatterChartData,
    this.sankeyData,
    this.markerRadius,
  });

  /// The chart title.
  final String? chartTitle;

  /// Accessible naming for the title.
  final FluentChartSemantics? chartTitleSemantics;

  /// Accessible naming for the data as a whole.
  final FluentChartSemantics? chartDataSemantics;

  /// Donut and horizontal-bar data (`types/DataPoint.ts:552`).
  final List<FluentChartDataPoint>? chartData;

  /// Line series (`types/DataPoint.ts:562`).
  final List<FluentLineChartSeries>? lineChartData;

  /// Scatter series (`types/DataPoint.ts:567`).
  final List<FluentScatterChartSeries>? scatterChartData;

  /// Sankey input. Upstream spells the field `SankeyChartData`, with a capital
  /// S (`types/DataPoint.ts:572`).
  final FluentSankeyChartData? sankeyData;

  /// Marker radius in logical pixels.
  ///
  /// Replaces upstream's `pointOptions.r`. Null lets the chart apply its own
  /// fallback, which is 8 for AreaChart (`AreaChart.tsx:749`).
  final double? markerRadius;
}
