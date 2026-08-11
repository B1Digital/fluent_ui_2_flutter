/// The Vega-Lite bar-family transformers.
///
/// Ports `VegaLiteSchemaAdapter.ts:2141-2337` (vertical bar). Internal to the
/// package: nothing here is barrel-exported.
library;

import '../../cartesian/cartesian_chart_props.dart';
import '../../model/bar_data.dart';
import '../../model/chart_common.dart';
import '../../vertical_bar_chart.dart';
import '../plotly/common.dart' show parseCssColour;
import '../plotly/predicates.dart' show isInvalidValue;
import 'common.dart';
import 'context.dart';
import 'js_value.dart' show JsUndefined, jsToString;
import 'spec.dart' show VegaSpecException;

/// `DEFAULT_TRUNCATE_CHARS` (`VegaLiteSchemaAdapter.ts:76`), the bottom rung of
/// the bar charts' truncation ladder.
const int kVegaDefaultTruncateChars = 20;

/// `encoding.<channel>.type`, the declared Vega-Lite data type.
String? _channelType(Map<String, Object?> encoding, String channel) {
  final definition = encoding[channel];
  final type = definition is Map<String, Object?> ? definition['type'] : null;
  return type is String ? type : null;
}

/// `encoding.<channel>.axis.<key>`.
Object? _axisOption(Map<String, Object?> encoding, String channel, String key) {
  final definition = encoding[channel];
  final axis = definition is Map<String, Object?> ? definition['axis'] : null;
  return axis is Map<String, Object?> ? axis[key] : null;
}

/// Transforms a Vega-Lite `bar` spec into a vertical bar chart
/// (`VegaLiteSchemaAdapter.ts:2141-2337`).
///
/// [spec] is mutated: `initializeTransformContext` materialises a conditional
/// colour into the data rows and `validateVegaXYEncodings` rewrites a
/// mis-declared `type` in place. The clone that protects a caller's own object
/// is taken once by the widget (`internal/vega/spec.dart:63`), which is where
/// upstream's own single entry point is.
FluentVerticalBarChart transformVegaToVerticalBar(
  Map<String, Object?> spec,
  Map<String, String> colorMap, {
  required bool isDark,
}) {
  // `:2147`.
  final context = initializeTransformContext(spec);
  final data = context.data;
  final encoding = context.encoding;
  // `:2150`.
  final xField = context.xField;
  final yField = context.yField;
  final colourField = context.colorField;
  final yAggregate = context.yAggregate;

  // `:2154`: `!!yAggregate` — a `count` needs no field, every other op has one.
  final isAggregate = yAggregate != null;
  if (xField == null && !isAggregate) {
    // `:2157`, message verbatim.
    throw const VegaSpecException(
      'VegaLiteSchemaAdapter: x encoding is required for bar charts',
    );
  }

  // `:2161-2164`.
  final aggregatedData = isAggregate && xField != null
      ? computeAggregateData(data, xField, yField, yAggregate)
      : null;

  // `:2166-2169`: an aggregate chart skips validation entirely, which is what
  // lets a `count` over a string column through.
  if (!isAggregate && xField != null && yField != null) {
    validateVegaXYEncodings(
      data,
      xField,
      yField,
      _channelType(encoding, 'x'),
      _channelType(encoding, 'y'),
      'VerticalBarChart',
      encoding: encoding,
    );
  }

  // `:2173`.
  final colour = encoding['color'];
  final colourValueRaw = colour is Map<String, Object?>
      ? colour['value']
      : null;
  final colourValue = colourValueRaw is String ? colourValueRaw : null;

  // `:2175-2177`.
  final barData = <FluentVerticalBarChartDataPoint>[];
  final colourIndex = <String, int>{};
  var nextColourIndex = 0;

  /// `:2187-2200`, `:2221-2233` and `:2261-2274`, which are the same eleven
  /// lines three times: the legend takes the next per-chart ordinal the first
  /// time it is seen, and that ordinal — not the shared map's size — picks the
  /// colour (`:129`).
  String colourFor(String legend) {
    final index = colourIndex[legend] ??= nextColourIndex++;
    return resolveVegaSeriesColour(
      legend,
      index,
      colourValue,
      context.markProps.color,
      colorMap,
      isDark: isDark,
      colorScheme: context.colorScheme,
      colorRange: context.colorRange,
    );
  }

  // `:2180`.
  final useSingleLegend = colourField == null;

  if (aggregatedData != null) {
    // `:2182-2208`.
    for (final group in aggregatedData) {
      final category = group['category']! as String;
      // `:2185`: with a colour field the legend is the CATEGORY, not the
      // colour column's value — the aggregate branch never reads that column.
      final legend = useSingleLegend ? 'Bar' : category;
      barData.add(
        FluentVerticalBarChartDataPoint(
          x: category,
          y: group['value']! as double,
          legend: legend,
          color: parseCssColour(colourFor(legend)),
        ),
      );
    }
  } else if (xField != null && yField != null) {
    // `:2211`: `!== undefined`, so a row holding an explicit null IS the
    // sample and sends the whole chart down the counting branch; only a
    // missing key is skipped.
    Object? firstYValue;
    for (final row in data) {
      if (row.containsKey(yField) && row[yField] is! JsUndefined) {
        firstYValue = row[yField];
        break;
      }
    }
    // `:2212`: `typeof === 'number'`.
    final yIsNumeric = firstYValue is num;

    if (!yIsNumeric) {
      // `:2214-2235`: a non-numeric y column is counted per category rather
      // than rejected. // parity
      final counts = countByCategory(data, xField, null, '');
      for (final entry in counts.entries) {
        // `:2219`: the inner legend map is collapsed, because this branch
        // passes no colour field and every count therefore lands under `''`.
        final total = entry.value.values.fold<int>(0, (a, b) => a + b);
        // `:2220`: the x value is the legend here, which is the one place the
        // two non-aggregate branches disagree — `:2258` labels every bar
        // `'Bar'`.
        final legend = entry.key;
        barData.add(
          FluentVerticalBarChartDataPoint(
            x: entry.key,
            y: total.toDouble(),
            legend: legend,
            color: parseCssColour(colourFor(legend)),
          ),
        );
      }
    } else {
      // `:2242`.
      final yFormatter = createValueFormatter(
        _axisOption(encoding, 'y', 'format') as String?,
      );

      for (final row in data) {
        final xValue = row[xField];
        final yValue = row[yField];

        // `:2250`.
        if (isInvalidValue(xValue) ||
            isInvalidValue(yValue) ||
            yValue is! num) {
          continue;
        }

        // `:2254-2259`. The colour read is `!== undefined`, so a row whose
        // colour cell is an explicit null is legended `'null'` rather than
        // falling through. // parity: VegaLiteSchemaAdapter.ts:2255
        final String legend;
        if (colourField != null &&
            row.containsKey(colourField) &&
            row[colourField] is! JsUndefined) {
          legend = jsToString(row[colourField]);
        } else if (useSingleLegend) {
          legend = 'Bar';
        } else {
          legend = jsToString(xValue);
        }

        // `:2278`: a numeric x is stringified so the band scale positions it
        // as a category. A `Date` is cast rather than converted and reaches
        // the chart as one, which `FluentVerticalBarChartDataPoint.x` accepts.
        final xCategory = xValue is DateTime ? xValue : jsToString(xValue);

        final label = yFormatter == null ? null : yFormatter(yValue.toDouble());
        barData.add(
          FluentVerticalBarChartDataPoint(
            x: xCategory,
            y: yValue.toDouble(),
            legend: legend,
            color: parseCssColour(colourFor(legend)),
            // `:2285`: one formatter, both slots.
            yAxisCalloutData: label,
            barLabel: label,
          ),
        );
      }
    }
  }

  // `:2291`.
  final titles = getVegaLiteTitles(spec);
  // `:2294`.
  final categoryOrder = extractAxisCategoryOrderProps(encoding);
  // `:2297`.
  final tickConfig = extractTickConfig(spec);
  // `:2300`. Upstream forwards the d3 SPEC and the chart resolves it; this
  // port's `FluentCartesianChartProps.yAxisTickFormat` is the resolved
  // `String Function(double)`, so the formatter is built here instead.
  final yAxisTickFormat = createValueFormatter(
    _axisOption(encoding, 'y', 'format') as String?,
  );
  // `:2301`.
  final yRange = extractYMinMax(encoding, data);
  // `:2302`.
  final yAxisType = extractYAxisType(encoding);

  // `:2305`: the DISTINCT x count, so two rows sharing a category truncate as
  // one.
  final uniqueXCount = barData
      .map((point) => jsToString(point.x))
      .toSet()
      .length;
  // `:2305-2306`. Three rungs, evaluated on the distinct x count.
  final truncate = uniqueXCount > 20
      ? 6
      : uniqueXCount > 10
      ? 10
      : kVegaDefaultTruncateChars;

  // `:2325`: a colour field hands the decision to the encoding's own legend
  // block, and `legend: null` — which `initializeTransformContext` writes for a
  // materialised conditional colour (`:1197`) — reads as "not disabled".
  final legendBlock = colour is Map<String, Object?> ? colour['legend'] : null;
  final legendDisabled = legendBlock is Map<String, Object?>
      ? legendBlock['disable'] == true
      : false;

  return FluentVerticalBarChart(
    // `:2309`.
    data: barData,
    // `:2310`.
    chartTitle: titles.chartTitle,
    // `:2314`.
    roundCorners: true,
    // `:2323`. The order lands on the WIDGET field, not the identically named
    // `FluentCartesianChartProps` one: `vertical_bar_chart.dart:216` hands
    // `widget.xAxisCategoryOrder` to the delegate and never reads the prop.
    // The y order upstream spreads beside it has no reader on either side —
    // this chart's y axis is numeric.
    xAxisCategoryOrder: categoryOrder.x ?? FluentAxisCategoryOrder.defaultOrder,
    props: FluentCartesianChartProps(
      // `:2311-2312`.
      xAxisTitle: titles.xAxisTitle,
      yAxisTitle: titles.yAxisTitle,
      // `:2315`: `typeof barData[0]?.x === 'string'`. Every x that reached a
      // bar was stringified at `:2278` unless it was a `Date`, so this is on
      // for a numeric x as well and off only for an empty or temporal one.
      wrapXAxisLables: barData.isNotEmpty && barData.first.x is String,
      // `:2316`.
      hideTickOverlap: true,
      // `:2305-2306`, the ladder above.
      noOfCharsToTruncate: truncate,
      // `:2318`. Plan 05's shell resolves
      // `props.xAxis?.tickLayout ?? delegate.xAxisTickLayout` at
      // `CartesianChart.tsx:220`, `:282` and `:385`, so this is the only route
      // in.
      xAxis: const FluentAxisConfig(tickLayout: FluentTickLayout.auto),
      // `:2319`.
      yAxisTickFormat: yAxisTickFormat,
      // `:2320-2321`. An absent bound leaves the shell's own 0, which is what
      // upstream's empty spread leaves too.
      yMinValue: yRange.min ?? 0,
      yMaxValue: yRange.max ?? 0,
      // `:2322`.
      yScaleType: yAxisType ?? FluentAxisScaleType.auto,
      // `:2325`.
      hideLegend: colourField == null || legendDisabled,
      // `:2328-2333`: both are conditional spreads, and both props are
      // nullable or carry the shell's own default (6,
      // `cartesian_chart_props.dart:95`), so an absent one changes nothing.
      tickValues: tickConfig.tickValues,
      xAxisTickCount: tickConfig.xAxisTickCount ?? 6,
    ),
  );
}
