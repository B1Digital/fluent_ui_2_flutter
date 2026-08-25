/// The Vega-Lite bar-family transformers.
///
/// Ports `VegaLiteSchemaAdapter.ts:2141-2337` (vertical bar),
/// `:2349-2729` (vertical stacked bar), `:2741-2829` (grouped vertical bar),
/// `:2841-3009` (horizontal bar) and `:3524-3695` (histogram).
/// Internal to the package: nothing here is barrel-exported.
library;

import 'dart:math' as math;

import '../../cartesian/cartesian_chart_props.dart';
import '../../chrome/legend_shape.dart';
import '../../grouped_vertical_bar_chart.dart';
import '../../horizontal_bar_chart_with_axis.dart';
import '../../model/bar_data.dart';
import '../../model/chart_common.dart';
import '../../model/line_options.dart';
import '../../vertical_bar_chart.dart';
import '../../vertical_stacked_bar_chart.dart';
import '../d3/array_stats.dart' as d3;
import '../d3/bin.dart' as d3;
import '../d3/js_math.dart' as d3;
import '../plotly/common.dart' show parseCssColour;
import '../plotly/predicates.dart' show isInvalidValue;
import 'common.dart';
import 'context.dart';
import 'js_value.dart'
    show JsUndefined, jsToNumber, jsToString, jsTruthy, jsTypeof;
import 'spec.dart' show VegaSpecException, extractVegaDataValues, getMarkType;
import 'transforms.dart' show applyVegaTransforms;

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

/// The mid-point of a bin, which is where its bar is plotted
/// (`VegaLiteSchemaAdapter.ts:3524-3526`).
double _vegaBinCentre(d3.Bin bin) => (bin.x0 + bin.x1) / 2;

/// One aggregate over the values that fell in a bin
/// (`VegaLiteSchemaAdapter.ts:3535-3553`).
///
/// `mean` and `average` are the same op (`:3542-3544`), `median` is DECLARED in
/// the parameter type at `:3536` but has no case, so it falls through to the
/// default and returns a count.
/// // parity: VegaLiteSchemaAdapter.ts:3536
double _vegaHistogramAggregate(String? aggregate, List<double> bin) =>
    switch (aggregate) {
      // `:3540-3541`.
      'sum' => d3.sum(bin),
      // `:3542-3544`: guarded against an empty bin, unlike
      // `computeAggregateData`'s `mean` at `:1345`.
      'mean' || 'average' => bin.isEmpty ? 0 : (d3.mean(bin) ?? 0),
      // `:3545-3546`.
      'min' => d3.min<num>(bin)?.toDouble() ?? 0,
      // `:3547-3548`.
      'max' => d3.max<num>(bin)?.toDouble() ?? 0,
      // `:3549-3551`: `count` and everything unrecognised.
      _ => bin.length.toDouble(),
    };

/// Transforms a binned Vega-Lite bar spec into a Fluent vertical bar chart
/// (`VegaLiteSchemaAdapter.ts:3566-3695`).
///
/// The routing predicate is `encoding.x.bin` (`:3577`, and `:1698` on the
/// routing side), so this is the only Vega transformer that reads a bin
/// configuration; every other bar path treats x as a category.
FluentVerticalBarChart transformVegaToHistogram(
  Map<String, Object?> spec,
  Map<String, String> colorMap, {
  required bool isDark,
}) {
  // `:3572`.
  final context = initializeTransformContext(spec);
  final dataValues = context.data;
  final encoding = context.encoding;

  final y = encoding['y'] is Map<String, Object?>
      ? encoding['y']! as Map<String, Object?>
      : null;
  final colour = encoding['color'] is Map<String, Object?>
      ? encoding['color']! as Map<String, Object?>
      : null;

  // `:3575`.
  final xField = context.xField;
  // `:3576`: `||`, so the default aggregate is a count and `y` may be absent
  // entirely. `context.yAggregate` is not used here because the `timeUnit`
  // branch at `:1254-1256` clears it, and upstream reads `encoding.y.aggregate`
  // back off the encoding at this point rather than off the context.
  final yAggregate =
      y?['aggregate'] is String && (y!['aggregate']! as String).isNotEmpty
      ? y['aggregate']! as String
      : 'count';
  // `:3577`.
  final binConfig = (encoding['x'] is Map<String, Object?>
      ? encoding['x']! as Map<String, Object?>
      : null)?['bin'];

  // `:3579-3581`: `!binConfig`, so `bin: false` and `bin: 0` both fail here.
  if (xField == null || !jsTruthy(binConfig)) {
    throw const VegaSpecException(
      'VegaLiteSchemaAdapter: Histogram requires x encoding with bin property',
    );
  }

  // `:3584-3585`.
  validateVegaDataArray(dataValues, xField, 'Histogram');
  validateVegaNoNestedArrays(dataValues, xField);

  // `:3588-3589`: two passes — every valid value, then only the numbers.
  final allValues = <Object?>[
    for (final row in dataValues)
      if (!isInvalidValue(row[xField])) row[xField],
  ];
  final values = <double>[
    for (final value in allValues)
      if (value is num) value.toDouble(),
  ];

  if (values.isEmpty) {
    // `:3591-3618`: the diagnostic is the only user-facing output of this
    // branch, so all three suggestions are reproduced verbatim, including the
    // leading space each one carries.
    final sampleValue = allValues.isEmpty ? null : allValues.first;
    // `:3594`: `typeof allValues[0]`. An empty list indexes past the end, which
    // in JavaScript is `undefined` rather than `null`, so the name is written
    // out rather than asked of [jsTypeof].
    final actualType = allValues.isEmpty ? 'undefined' : jsTypeof(sampleValue);
    var suggestion = '';
    if (actualType == 'string') {
      // `:3599`: any decimal digit anywhere in any string value.
      final hasEmbeddedNumbers = allValues.any(
        (value) => value is String && RegExp(r'\d').hasMatch(value),
      );
      if (hasEmbeddedNumbers) {
        // `:3601-3603`.
        suggestion =
            ' The data contains strings with embedded numbers (e.g., "40 '
            'salads"). Consider extracting the numeric values first, or change '
            'the encoding type to "nominal" or "ordinal" for a categorical bar '
            'chart.';
      } else {
        // `:3605-3608`.
        suggestion =
            ' The data contains categorical strings (e.g., '
            '"${jsToString(sampleValue)}"). Change the x encoding type to '
            '"nominal" or "ordinal" for a categorical bar chart, or remove '
            'bin: true to create a simple bar chart.';
      }
    } else if (actualType == 'undefined') {
      // `:3610-3612`.
      suggestion = ' The field may not exist in the data.';
    }
    // `:3614-3617`.
    throw VegaSpecException(
      'VegaLiteSchemaAdapter: No numeric values found for histogram binning on '
      'field "$xField". Found $actualType values instead.$suggestion',
    );
  }

  // `:3621-3634`.
  final (low, high) = d3.extent<num>(values);
  final binner = d3.bin()
    ..domain((low ?? 0).toDouble(), (high ?? 0).toDouble());
  var hasExplicitThresholds = false;
  if (binConfig is Map<String, Object?>) {
    // `:3626-3628`: `maxbins` is passed to `thresholds` as a COUNT, so it is a
    // target rather than a ceiling once d3 nices the domain. A non-finite count
    // would be `Infinity` or `NaN` upstream, where the tick generator answers an
    // empty array; `int` has no such value, so it is skipped instead of cast.
    final maxbins = binConfig['maxbins'];
    if (jsTruthy(maxbins) && jsToNumber(maxbins).isFinite) {
      binner.thresholdCount(jsToNumber(maxbins).toInt());
      hasExplicitThresholds = true;
    }
    // `:3629-3631`: an explicit extent REPLACES the data extent set above.
    // Upstream destructures a two-element tuple; a shorter list reads
    // `undefined` there and would range-error here, so the pair is required.
    final declaredExtent = binConfig['extent'];
    if (jsTruthy(declaredExtent) &&
        declaredExtent is List<Object?> &&
        declaredExtent.length >= 2) {
      binner.domain(
        jsToNumber(declaredExtent[0]),
        jsToNumber(declaredExtent[1]),
      );
    }
  }
  if (!hasExplicitThresholds) {
    // `:3623` leaves d3-bin's default threshold function in place, which is
    // Sturges' rule (`d3-array/src/bin.js:13`). This port's `Binner` states at
    // `internal/d3/bin.dart:30-34` that the automatic path is unported and
    // throws on a null count, so the rule is applied here — as
    // `internal/plotly/bins.dart:196-200` already does for the Plotly
    // histogram. `d3-array/src/threshold/sturges.js:4` is
    // `max(1, ceil(log(count(values)) / LN2) + 1)`, where `count` skips
    // non-numeric data, which `values` has already dropped. 1 is the floor, and
    // 1 is also the constant Sturges adds.
    binner.thresholdCount(
      math.max(1, (math.log(values.length) / math.ln2).ceil() + 1),
    );
  }
  final bins = binner.call(values);

  // `:3637`: the legend is the FIRST row's colour value, for every bar — a
  // histogram has one series whatever the colour field says. With no colour
  // field it is the literal `'Frequency'`.
  final colourField = colour?['field'] is String
      ? colour!['field']! as String
      : null;
  final legend = colourField != null
      ? jsToString(dataValues.isEmpty ? null : dataValues.first[colourField])
      : 'Frequency';
  // `:3638`: index 0, and neither the scheme nor the range is forwarded.
  // // parity: VegaLiteSchemaAdapter.ts:3638
  final barColour = parseCssColour(
    resolveVegaSeriesColour(legend, 0, null, null, colorMap, isDark: isDark),
  );
  // `:3639`.
  final yField = y?['field'] is String ? y!['field']! as String : null;

  // `:3641-3676`.
  final histogramData = <FluentVerticalBarChartDataPoint>[];
  for (final bin in bins) {
    final double barY;
    if (yAggregate != 'count' && yField != null) {
      // `:3645-3661`: the rows are re-selected from the WHOLE data set with a
      // half-open interval, then the maximum is added back to the final bin so
      // it is not lost.
      final yValues = <double>[
        for (final row in dataValues)
          if (() {
                // `:3649-3650`: `!isNaN(xVal) && xVal >= x0 && xVal < x1`.
                final xVal = jsToNumber(row[xField]);
                return !xVal.isNaN && xVal >= bin.x0 && xVal < bin.x1;
              }() &&
              // `:3653`: the y value is filtered separately, AFTER mapping.
              !jsToNumber(row[yField]).isNaN)
            jsToNumber(row[yField]),
      ];
      if (identical(bin, bins.last)) {
        // `:3655-3661`: exact equality with the final upper bound.
        for (final row in dataValues) {
          if (jsToNumber(row[xField]) == bin.x1 &&
              !jsToNumber(row[yField]).isNaN) {
            yValues.add(jsToNumber(row[yField]));
          }
        }
      }
      barY = _vegaHistogramAggregate(yAggregate, yValues);
    } else {
      // `:3664`: the bin's own members, which for a count is just its length.
      barY = _vegaHistogramAggregate(yAggregate, bin.values.cast<double>());
    }

    histogramData.add(
      FluentVerticalBarChartDataPoint(
        // `:3642`.
        x: _vegaBinCentre(bin),
        y: barY,
        legend: legend,
        color: barColour,
        // `:3667`: the half-open interval, written exactly as upstream writes
        // it — a square bracket, a spaced hyphen, and a closing round bracket.
        // Rendered with JavaScript's number formatting so an integral edge has
        // no `.0`.
        xAxisCalloutData:
            '[${d3.jsNumberToString(bin.x0)} - ${d3.jsNumberToString(bin.x1)})',
      ),
    );
  }

  // `:3678-3680`.
  final titles = getVegaLiteTitles(spec);
  final annotations = extractVegaAnnotations(spec);
  final yAxis = y?['axis'] is Map<String, Object?>
      ? y!['axis']! as Map<String, Object?>
      : null;
  final yAxisTickFormatSpec = yAxis?['format'] is String
      ? yAxis!['format']! as String
      : null;

  return FluentVerticalBarChart(
    // `:3683`.
    data: histogramData,
    // `:3684`: `FluentVerticalBarChart` takes the title as a named parameter
    // rather than through a `FluentChartData` bundle — task 45's tail block
    // makes the same call.
    chartTitle: titles.chartTitle,
    // `:3688`.
    roundCorners: true,
    // `:3690`: `DEFAULT_MAX_BAR_WIDTH` is 50 logical pixels at `:75`.
    maxBarWidth: 50,
    // `:3693`: a render mode, not a chart type. `vertical_bar_chart.dart:193`
    // is the only reader.
    mode: 'histogram',
    props: FluentCartesianChartProps(
      // `:3685-3686`: `||`, so an EMPTY axis title also falls back — to the
      // field name for x and to the aggregate's own name for y.
      xAxisTitle: titles.xAxisTitle == null || titles.xAxisTitle!.isEmpty
          ? xField
          : titles.xAxisTitle,
      yAxisTitle: titles.yAxisTitle == null || titles.yAxisTitle!.isEmpty
          ? yAggregate
          : titles.yAxisTitle,
      // `:3691`: a conditional spread upstream, and an empty list here is the
      // prop's own default (`cartesian_chart_props.dart:98`).
      annotations: annotations,
      // `:3692`, likewise conditional upstream; `createValueFormatter` answers
      // null for an absent spec.
      yAxisTickFormat: createValueFormatter(yAxisTickFormatSpec),
      // `:3689`.
      hideTickOverlap: true,
    ),
  );
}

/// The height a stacked bar falls back to when the spec declares none
/// (`VegaLiteSchemaAdapter.ts:2712`, whose `DEFAULT_CHART_HEIGHT` is 350 at
/// `:74`).
///
/// `FluentVerticalStackedBarChart` is a shell chart and takes its size from its
/// `BoxConstraints` (spec §2.2), so the value is applied by the declarative
/// widget as the cell's `SizedBox` rather than passed in here.
const double kVegaStackedBarDefaultHeight = 350;

/// `encoding.<channel>`, the channel definition itself.
Map<String, Object?>? _channel(Map<String, Object?> encoding, String name) {
  final definition = encoding[name];
  return definition is Map<String, Object?> ? definition : null;
}

/// `channel.field`, absent when it is missing or empty.
///
/// Upstream reads the raw value (`VegaLiteSchemaAdapter.ts:1276-1288`) and
/// every consumer in the stacked-bar transformer then tests it with `!` or a
/// ternary — `:2383`, `:2479`, `:2538`, `:2542` — so an empty string is as
/// absent as a missing key.
String? _channelField(Map<String, Object?>? channel) {
  final field = channel?['field'];
  return field is String && field.isNotEmpty ? field : null;
}

/// The colour scheme and explicit range an encoding declares
/// (`VegaLiteSchemaAdapter.ts:1396-1404`).
///
/// `FluentVegaTransformContext` carries the same pair, but only for
/// `unitSpecs[0]`; `:2368` picks the first BAR layer, which need not be layer
/// zero, so the stacked-bar transformer re-reads it from that layer's encoding.
({String? scheme, List<String>? range}) _colorConfig(
  Map<String, Object?> encoding,
) {
  final scale = _channel(encoding, 'color')?['scale'];
  final scheme = scale is Map<String, Object?> ? scale['scheme'] : null;
  final range = scale is Map<String, Object?> ? scale['range'] : null;
  return (
    scheme: scheme is String ? scheme : null,
    range: range is List<Object?>
        ? <String>[
            for (final entry in range)
              if (entry is String) entry,
          ]
        : null,
  );
}

/// The dash-and-width options a mark declares, or null when it declares neither
/// (`VegaLiteSchemaAdapter.ts:2601-2606` for a line, `:2627-2633` for a rule,
/// which spell the same two tests in the other order).
///
/// `:2603` and `:2631` both read `if (markProps.strokeWidth)`, so a width of 0
/// is as absent as no width at all. `strokeDash` is tested the same way, but an
/// array is truthy however short it is, so an EMPTY dash array yields the empty
/// `stroke-dasharray` string rather than no options.
/// // parity: VegaLiteSchemaAdapter.ts:2602
///
/// `:2604` joins with a SPACE, which is the SVG `stroke-dasharray` syntax.
FluentLineOptions? _markLineOptions(FluentVegaMarkProperties markProps) {
  final width = markProps.strokeWidth == 0 ? null : markProps.strokeWidth;
  final dash = markProps.strokeDash;
  if (width == null && dash == null) {
    return null;
  }
  return FluentLineOptions(
    strokeWidth: width,
    strokeDasharray: dash?.map(d3.jsNumberToString).join(' '),
  );
}

/// `value as number`, the unchecked cast at `VegaLiteSchemaAdapter.ts:2592` and
/// `:2646`.
///
/// The cast converts nothing, and `LineDataInVerticalStackedBarChart.y` is
/// `number | string` (`types/DataPoint.ts:686`), so a string y reaches the
/// chart as a string and drives its band scale. Only a value the model cannot
/// hold at all is coerced, which is where this stops being a pure cast.
Object _asLineY(Object? value) {
  if (value is num || value is String) {
    return value!;
  }
  return jsToNumber(value);
}

/// Transforms a Vega-Lite bar spec into a Fluent vertical stacked bar chart
/// (`VegaLiteSchemaAdapter.ts:2349-2729`).
///
/// The largest Vega transformer: it stacks bars per x value, folds `line` and
/// `point` layers into per-group line overlays, resolves a secondary y axis and
/// replicates every `rule` layer across every x point as a flat reference line.
///
/// [spec] is mutated, for the reason [transformVegaToVerticalBar] gives.
FluentVerticalStackedBarChart transformVegaToStackedBar(
  Map<String, Object?> spec,
  Map<String, String> colorMap, {
  required bool isDark,
}) {
  // `:2355`: only `unitSpecs` is taken from the context. Everything below
  // re-derives from the primary layer, because the bar layer is not
  // necessarily layer zero.
  final unitSpecs = initializeTransformContext(spec).unitSpecs;

  // `:2358-2365`. A `point` mark counts as a line layer here, unlike the line
  // transformer, where it switches the dots on instead.
  final barSpecs = <Map<String, Object?>>[];
  final lineSpecs = <Map<String, Object?>>[];
  final ruleSpecs = <Map<String, Object?>>[];
  for (final unitSpec in unitSpecs) {
    switch (getMarkType(unitSpec['mark'])) {
      case 'bar':
        barSpecs.add(unitSpec);
      case 'line':
      case 'point':
        lineSpecs.add(unitSpec);
      case 'rule':
        ruleSpecs.add(unitSpec);
      default:
        break;
    }
  }

  // `:2368`: a bar layer wins; failing that, layer zero.
  final primarySpec = barSpecs.isNotEmpty ? barSpecs.first : unitSpecs.first;
  // `:2369-2372`: BOTH transform lists, top-level first. `transformVegaToLine`
  // applies only the top-level ones; this one does not.
  final topLevelTransforms = spec['transform'];
  var dataValues = applyVegaTransforms(
    extractVegaDataValues(primarySpec['data']),
    topLevelTransforms is List<Object?> ? topLevelTransforms : null,
  );
  final primaryTransforms = primarySpec['transform'];
  dataValues = applyVegaTransforms(
    dataValues,
    primaryTransforms is List<Object?> ? primaryTransforms : null,
  );

  // `:2373-2374`.
  final encodingRaw = primarySpec['encoding'];
  final encoding = encodingRaw is Map<String, Object?>
      ? encodingRaw
      : <String, Object?>{};
  final markProps = getMarkProperties(primarySpec['mark']);

  // `:2377`.
  final yChannel = _channel(encoding, 'y');
  final colorChannel = _channel(encoding, 'color');
  final xField = _channelField(_channel(encoding, 'x'));
  final yField = _channelField(yChannel);
  final colorField = _channelField(colorChannel);
  final yAggregateRaw = yChannel?['aggregate'];
  final yAggregate = yAggregateRaw is String && yAggregateRaw.isNotEmpty
      ? yAggregateRaw
      : null;
  // `:2378`: a static colour on the encoding, which outranks the scheme.
  final colorValueRaw = colorChannel?['value'];
  final colorValue = colorValueRaw is String ? colorValueRaw : null;

  // `:2383-2385`, message verbatim.
  if (xField == null) {
    throw const VegaSpecException(
      'VegaLiteSchemaAdapter: x encoding is required for stacked bar charts',
    );
  }

  // `:2381`, `:2389-2393`.
  final aggregatedData = yAggregate != null
      ? computeAggregateData(dataValues, xField, yField, yAggregate)
      : null;
  if (aggregatedData == null && yField == null) {
    throw const VegaSpecException(
      'VegaLiteSchemaAdapter: y encoding is required for stacked bar charts',
    );
  }

  // `:2396`.
  final colorConfig = _colorConfig(encoding);

  // `:2399-2401`: insertion order of this map IS the x-axis order, and `:2656`
  // is `Object.values` of it. The groups are built with growable lists and
  // filled in place, exactly as upstream fills its own object literals — the
  // record-of-lists an earlier draft used carried no information the group
  // itself does not.
  final mapXToDataPoints = <String, FluentVerticalStackedBarGroup>{};
  final colorIndex = <String, int>{};
  var currentColorIndex = 0;

  // The two lists are explicitly growable because the branches below fill them
  // in place; a `<T>[]` literal here would be lint-corrected to a `const` one
  // and throw on the first `add`.
  FluentVerticalStackedBarGroup groupFor(String key, Object xAxisPoint) =>
      mapXToDataPoints[key] ??= FluentVerticalStackedBarGroup(
        xAxisPoint: xAxisPoint,
        chartData: List<FluentStackedBarDatum>.empty(growable: true),
        lineData: List<FluentStackedBarLineDatum>.empty(growable: true),
      );

  String colourFor(String legend) {
    final index = colorIndex[legend] ??= currentColorIndex++;
    return resolveVegaSeriesColour(
      legend,
      index,
      colorValue,
      markProps.color,
      colorMap,
      colorScheme: colorConfig.scheme,
      colorRange: colorConfig.range,
      isDark: isDark,
    );
  }

  if (aggregatedData != null) {
    // `:2403-2437`: an aggregate spec produces exactly one stack per x value,
    // and the legend is the literal `'Bar'` for all of them.
    for (final entry in aggregatedData) {
      final category = entry['category']! as String;
      // `:2407`.
      const legend = 'Bar';
      groupFor(category, category).chartData.add(
        FluentStackedBarDatum(
          legend: legend,
          data: entry['value']! as double,
          color: parseCssColour(colourFor(legend)),
        ),
      );
    }
  } else {
    // `:2440-2441`: the FIRST row that HAS the y column decides whether the
    // whole column is numeric, so a row holding an explicit null is the sample
    // and sends every row down the counting branch.
    Object? firstYValue;
    for (final row in dataValues) {
      if (row.containsKey(yField) && row[yField] is! JsUndefined) {
        firstYValue = row[yField];
        break;
      }
    }
    final yIsNumeric = firstYValue is num;

    if (!yIsNumeric) {
      // `:2443-2473`: a non-numeric y column — typically a `quantitative` type
      // auto-corrected to `nominal` — falls back to counting rows per category.
      final counts = countByCategory(dataValues, xField, colorField, 'Bar');
      for (final xEntry in counts.entries) {
        final group = groupFor(xEntry.key, xEntry.key);
        for (final legendEntry in xEntry.value.entries) {
          group.chartData.add(
            FluentStackedBarDatum(
              legend: legendEntry.key,
              data: legendEntry.value.toDouble(),
              color: parseCssColour(colourFor(legendEntry.key)),
            ),
          );
        }
      }
    } else {
      // `:2476-2521`: the normal numeric path.
      final formatSpec = _axisOption(encoding, 'y', 'format');
      // `:2517`, and `:2699` reads the same spec for the axis itself.
      final yFormatter = createValueFormatter(
        formatSpec is String ? formatSpec : null,
      );
      for (final row in dataValues) {
        final xValue = row[xField];
        final yValue = row[yField];

        // `:2481-2483`: a non-numeric y on the numeric path drops the row.
        if (isInvalidValue(xValue) ||
            isInvalidValue(yValue) ||
            yValue is! num) {
          continue;
        }

        // `:2486`: `!== undefined`, so an absent colour column falls back to
        // `'Bar'` while an explicit null is legended `'null'`.
        // // parity: VegaLiteSchemaAdapter.ts:2479
        final String legend;
        if (colorField != null &&
            row.containsKey(colorField) &&
            row[colorField] is! JsUndefined) {
          legend = jsToString(row[colorField]);
        } else {
          legend = 'Bar';
        }

        // `:2489-2492`: a bar x axis is categorical even when the values are
        // numbers, so a number is stringified for the axis point. A `Date` is
        // cast rather than converted and reaches the chart as one, which
        // `FluentVerticalStackedBarGroup.xAxisPoint` accepts.
        final xKey = jsToString(xValue);
        final label = yFormatter == null ? null : yFormatter(yValue.toDouble());
        groupFor(xKey, xValue is DateTime ? xValue : xKey).chartData.add(
          FluentStackedBarDatum(
            legend: legend,
            data: yValue.toDouble(),
            color: parseCssColour(colourFor(legend)),
            // `:2519`: one formatted string for the callout and the on-bar
            // label alike, and both are set only when a format exists.
            yAxisCalloutData: label,
            barLabel: label,
          ),
        );
      }
    }
  }

  // `:2588`: read off the TOP-LEVEL spec, not off a layer.
  final resolve = spec['resolve'];
  final resolveScale = resolve is Map<String, Object?>
      ? resolve['scale']
      : null;
  final hasIndependentYScales =
      resolveScale is Map<String, Object?> &&
      resolveScale['y'] == 'independent';

  // `:2526-2610`: every line and point layer folds into the groups.
  for (var lineIndex = 0; lineIndex < lineSpecs.length; lineIndex++) {
    final lineSpec = lineSpecs[lineIndex];
    // `:2527-2530`: again both transform lists.
    var lineDataValues = applyVegaTransforms(
      extractVegaDataValues(lineSpec['data']),
      topLevelTransforms is List<Object?> ? topLevelTransforms : null,
    );
    final lineTransforms = lineSpec['transform'];
    lineDataValues = applyVegaTransforms(
      lineDataValues,
      lineTransforms is List<Object?> ? lineTransforms : null,
    );

    final lineEncodingRaw = lineSpec['encoding'];
    final lineEncoding = lineEncodingRaw is Map<String, Object?>
        ? lineEncodingRaw
        : const <String, Object?>{};
    final lineMarkProps = getMarkProperties(lineSpec['mark']);

    final lineY = _channel(lineEncoding, 'y');
    final lineXField = _channelField(_channel(lineEncoding, 'x'));
    final lineYField = _channelField(lineY);
    final lineColorField = _channelField(_channel(lineEncoding, 'color'));

    // `:2538-2540`.
    if (lineXField == null || lineYField == null) {
      continue;
    }

    // `:2542`: note the inversion — a colour FIELD gives the bare `'Line'` and
    // no colour field gives the numbered `'Line 1'`, because the per-row
    // legend below replaces the base whenever the field exists.
    final lineLegendBase = lineColorField != null
        ? 'Line'
        : 'Line ${lineIndex + 1}';

    // `:2589`: a secondary axis needs the independent resolve AND a line y
    // field that differs from the bars'.
    final useSecondaryYScale = hasIndependentYScales && lineYField != yField;

    // `:2601-2606`.
    final lineOptions = _markLineOptions(lineMarkProps);

    for (final row in lineDataValues) {
      final xValue = row[lineXField];
      final yValue = row[lineYField];
      // `:2548-2550`.
      if (isInvalidValue(xValue) || isInvalidValue(yValue)) {
        continue;
      }

      final xKey = jsToString(xValue);
      // `:2555-2556`, the same `!== undefined` read as the bar branch.
      final lineLegend =
          lineColorField != null &&
              row.containsKey(lineColorField) &&
              row[lineColorField] is! JsUndefined
          ? jsToString(row[lineColorField])
          : lineLegendBase;

      // `:2557-2563`: a line x value with no bar of its own still creates a
      // group, and its axis point is the RAW value rather than the stringified
      // one the bar branch writes at `:2490`.
      // // parity: VegaLiteSchemaAdapter.ts:2559
      final Object xAxisPoint;
      if (xValue is num || xValue is String || xValue is DateTime) {
        xAxisPoint = xValue!;
      } else {
        xAxisPoint = xKey;
      }

      // `:2566-2584`: the mark's own colour wins outright; otherwise the shared
      // resolver runs with NEITHER the scheme nor the range, so a line overlay
      // ignores a declared `scale.scheme`.
      // // parity: VegaLiteSchemaAdapter.ts:2574-2583
      final String lineColour;
      if (lineMarkProps.color != null && lineMarkProps.color!.isNotEmpty) {
        lineColour = lineMarkProps.color!;
      } else {
        final index = colorIndex[lineLegend] ??= currentColorIndex++;
        lineColour = resolveVegaSeriesColour(
          lineLegend,
          index,
          null,
          null,
          colorMap,
          isDark: isDark,
        );
      }

      groupFor(xKey, xAxisPoint).lineData!.add(
        FluentStackedBarLineDatum(
          // `:2592`.
          y: _asLineY(yValue),
          color: parseCssColour(lineColour),
          legend: lineLegend,
          // `:2595`: a line overlay on a stacked bar always draws a triangle.
          legendShape: FluentChartLegendShape.triangle,
          // `:2596`: `data` carries the value only when it really is a number.
          data: yValue is num ? yValue : null,
          useSecondaryYScale: useSecondaryYScale,
          lineOptions: lineOptions,
        ),
      );
    }
  }

  // `:2614-2654`: each rule layer with a constant y becomes a flat line on
  // EVERY existing group. Note the ordering consequence: a rule is replicated
  // only across the groups that exist by now, so a rule cannot create an x
  // point.
  for (var ruleIndex = 0; ruleIndex < ruleSpecs.length; ruleIndex++) {
    final ruleSpec = ruleSpecs[ruleIndex];
    final ruleEncodingRaw = ruleSpec['encoding'];
    final ruleEncoding = ruleEncodingRaw is Map<String, Object?>
        ? ruleEncodingRaw
        : const <String, Object?>{};
    final ruleMarkProps = getMarkProperties(ruleSpec['mark']);
    final ruleY = _channel(ruleEncoding, 'y');
    final yDatum = ruleY == null ? null : ruleY['datum'] ?? ruleY['value'];
    // `:2619`: a rule without a constant y is skipped here; only
    // `extractVegaAnnotations` sees it.
    if (yDatum == null) {
      continue;
    }

    // `:2620`: the colour-map KEY, deliberately not the legend.
    final ruleColourKey = 'Reference_$ruleIndex';
    // `:2621`: Vega's reference-line red, the fourth entry of category10,
    // hard-coded rather than taken from the scheme — the same literal
    // `transformVegaToLine` carries at `:1907`.
    final ruleColour =
        ruleMarkProps.color == null || ruleMarkProps.color!.isEmpty
        ? '#d62728'
        : ruleMarkProps.color!;
    // `:2623-2625`: the key still consumes a palette index even though the
    // colour above never uses it. // parity: VegaLiteSchemaAdapter.ts:2623
    colorIndex[ruleColourKey] ??= currentColorIndex++;

    final ruleLineOptions = _markLineOptions(ruleMarkProps);

    // `:2636-2641`: a companion `text` layer at the same y supplies the label;
    // otherwise it is the datum's own string form. This — not `Reference_$i` —
    // is what lands in `legend`.
    var ruleText = jsToString(yDatum);
    for (final candidate in unitSpecs) {
      if (getMarkType(candidate['mark']) != 'text') {
        continue;
      }
      final candidateEncoding = candidate['encoding'];
      if (candidateEncoding is! Map<String, Object?>) {
        continue;
      }
      final candidateY = _channel(candidateEncoding, 'y');
      if (candidateY == null ||
          (candidateY['datum'] ?? candidateY['value']) != yDatum) {
        continue;
      }
      final textChannel = _channel(candidateEncoding, 'text');
      // `:2640`: `datum || value || yDatum`, so a falsy label falls through.
      final Object? label;
      if (textChannel == null) {
        label = yDatum;
      } else if (jsTruthy(textChannel['datum'])) {
        label = textChannel['datum'];
      } else if (jsTruthy(textChannel['value'])) {
        label = textChannel['value'];
      } else {
        label = yDatum;
      }
      ruleText = jsToString(label);
      break;
    }

    // `:2644-2652`.
    for (final group in mapXToDataPoints.values) {
      group.lineData!.add(
        FluentStackedBarLineDatum(
          // `:2646`.
          y: _asLineY(yDatum),
          legend: ruleText,
          color: parseCssColour(ruleColour),
          lineOptions: ruleLineOptions,
          // `:2650`: a reference line never uses the secondary axis.
          useSecondaryYScale: false,
        ),
      );
    }
  }

  // `:2656-2657`.
  final chartData = mapXToDataPoints.values.toList(growable: false);
  final titles = getVegaLiteTitles(spec);

  // `:2660`.
  final hasSecondaryYAxis = chartData.any(
    (group) => group.lineData?.any((line) => line.useSecondaryYScale) ?? false,
  );

  // `:2663-2693`.
  String? secondaryYAxisTitle;
  FluentSecondaryYScaleOptions? secondaryYScaleOptions;
  if (hasSecondaryYAxis && lineSpecs.isNotEmpty) {
    // `:2665`: the FIRST line layer supplies the title and the domain, whichever
    // layer actually drove the secondary axis. // parity
    final lineEncodingRaw = lineSpecs.first['encoding'];
    final lineEncoding = lineEncodingRaw is Map<String, Object?>
        ? lineEncodingRaw
        : const <String, Object?>{};
    final lineY = _channel(lineEncoding, 'y');
    final lineYAxis = lineY?['axis'];
    // `:2669-2671`.
    if (lineYAxis is Map<String, Object?> && lineYAxis['title'] is String) {
      secondaryYAxisTitle = lineYAxis['title']! as String;
    }

    // `:2674-2681`: `typeof line.y === 'number'`, which is why `y` is not
    // coerced on the way in.
    final allLineYValues = <double>[
      for (final group in chartData)
        for (final line
            in group.lineData ?? const <FluentStackedBarLineDatum>[])
          if (line.useSecondaryYScale && line.y is num)
            (line.y as num).toDouble(),
    ];
    if (allLineYValues.isNotEmpty) {
      // `:2685-2691`: an explicit `scale.domain` on the line layer wins over
      // the data extent, and the fallback for an empty extent is 0.
      final lineScale = lineY?['scale'];
      final lineDomain = lineScale is Map<String, Object?>
          ? lineScale['domain']
          : null;
      final domain = lineDomain is List<Object?> ? lineDomain : null;
      secondaryYScaleOptions = FluentSecondaryYScaleOptions(
        yMinValue: domain != null && domain.isNotEmpty
            ? jsToNumber(domain.first)
            : d3.min<num>(allLineYValues)?.toDouble() ?? 0,
        yMaxValue: domain != null && domain.length > 1
            ? jsToNumber(domain[1])
            : d3.max<num>(allLineYValues)?.toDouble() ?? 0,
      );
    }
  }

  // `:2696`.
  final yAxisType = extractYAxisType(encoding);
  // `:2699`, the same spec the bar labels above were formatted with.
  final yAxisTickFormatSpec = _axisOption(encoding, 'y', 'format');
  // `:2700`.
  final bounds = extractYMinMax(encoding, dataValues);
  // `:2703`.
  final categoryOrder = extractAxisCategoryOrderProps(encoding);
  // `:2713`.
  final legendConfig = colorChannel?['legend'];
  final legendDisabled =
      legendConfig is Map<String, Object?> && legendConfig['disable'] == true;

  return FluentVerticalStackedBarChart(
    // `:2706`.
    data: chartData,
    // `:2707`. `FluentVerticalStackedBarChart` takes the chart title as a named
    // parameter rather than through a props bag.
    chartTitle: titles.chartTitle,
    // `:2715`.
    roundCorners: true,
    // `:2717`: the bar-gap ceiling, a multiplier and not a pixel count.
    barGapMax: 2,
    // `:2727`. Both orders land on the WIDGET, not on the identically named
    // `FluentCartesianChartProps` fields: `vertical_stacked_bar_chart.dart:1340`
    // and `:1341` hand `widget.xAxisCategoryOrder` and
    // `widget.yAxisCategoryOrder` to the delegate and the props are never read.
    xAxisCategoryOrder: categoryOrder.x ?? FluentAxisCategoryOrder.defaultOrder,
    yAxisCategoryOrder: categoryOrder.y ?? FluentAxisCategoryOrder.defaultOrder,
    props: FluentCartesianChartProps(
      // `:2708-2709`.
      xAxisTitle: titles.xAxisTitle,
      yAxisTitle: titles.yAxisTitle,
      // `:2713`: `?? false`.
      hideLegend: legendDisabled,
      // `:2714`.
      showYAxisLables: true,
      // `:2716`.
      hideTickOverlap: true,
      // `:2718`: `DEFAULT_TRUNCATE_CHARS`, the constant this file already holds.
      noOfCharsToTruncate: kVegaDefaultTruncateChars,
      // `:2719`.
      showYAxisLablesTooltip: true,
      // `:2720`: only a String axis point wraps; a numeric or temporal one does
      // not.
      wrapXAxisLables:
          chartData.isNotEmpty && chartData.first.xAxisPoint is String,
      // `:2721`. Plan 05's shell resolves
      // `props.xAxis?.tickLayout ?? delegate.xAxisTickLayout`
      // (`CartesianChart.tsx:220`), so this is the only route in.
      xAxis: const FluentAxisConfig(tickLayout: FluentTickLayout.auto),
      // `:2722`. Upstream forwards the d3 SPEC and the chart resolves it; this
      // port's prop is the resolved formatter, so it is built here.
      yAxisTickFormat: createValueFormatter(
        yAxisTickFormatSpec is String ? yAxisTickFormatSpec : null,
      ),
      // `:2723-2724`: both are conditional spreads upstream, and the shell's
      // own defaults are 0 and 0 — which is what an absent domain leaves.
      yMinValue: bounds.min ?? 0,
      yMaxValue: bounds.max ?? 0,
      // `:2725`.
      yScaleType: yAxisType ?? FluentAxisScaleType.auto,
      // `:2726`.
      secondaryYAxisTitle: secondaryYAxisTitle,
      secondaryYScaleOptions: secondaryYScaleOptions,
    ),
  );
}

/// Transforms a Vega-Lite bar spec with a colour field into a Fluent grouped
/// vertical bar chart (`VegaLiteSchemaAdapter.ts:2741-2829`).
///
/// The only transformer in the Vega set that requires all three of x, y and
/// colour (`:2752-2754`); a spec missing any one of them is a hard error rather
/// than a fallback to a simpler chart.
///
/// [spec] is mutated, for the reason [transformVegaToVerticalBar] gives.
FluentGroupedVerticalBarChart transformVegaToGroupedBar(
  Map<String, Object?> spec,
  Map<String, String> colorMap, {
  required bool isDark,
}) {
  // `:2747`.
  final context = initializeTransformContext(spec);
  final dataValues = context.data;
  final encoding = context.encoding;

  // `:2750`.
  final xField = context.xField;
  final yField = context.yField;
  final colorField = context.colorField;

  // `:2752-2754`.
  if (xField == null || yField == null || colorField == null) {
    throw const VegaSpecException(
      'VegaLiteSchemaAdapter: x, y, and color encodings are required for '
      'grouped bar charts',
    );
  }

  // `:2757`.
  final colorConfig = _colorConfig(encoding);

  // `:2760-2785`: a NESTED map, so a repeated (x, legend) pair OVERWRITES
  // rather than accumulating — two rows with the same category and group keep
  // only the last y. // parity: VegaLiteSchemaAdapter.ts:2780
  //
  // `:2788` then walks it with `Object.keys`, which lists integer-like keys
  // first in ascending numeric order; a Dart map is insertion-ordered
  // throughout, so a spec whose categories are bare digit strings groups in a
  // different order here. The same divergence `transform_other.dart:247`
  // records for the heatmap axes. // parity: VegaLiteSchemaAdapter.ts:2788
  final groupedData = <String, Map<String, double>>{};
  final colorIndex = <String, int>{};
  var currentColorIndex = 0;
  for (final row in dataValues) {
    final xValue = row[xField];
    final yValue = row[yField];
    final groupValue = row[colorField];
    // `:2769-2771`.
    if (isInvalidValue(xValue) ||
        isInvalidValue(yValue) ||
        yValue is! num ||
        isInvalidValue(groupValue)) {
      continue;
    }
    final xKey = jsToString(xValue);
    final legend = jsToString(groupValue);
    (groupedData[xKey] ??= <String, double>{})[legend] = yValue.toDouble();
    colorIndex[legend] ??= currentColorIndex++;
  }

  // `:2788-2809`.
  final chartData = <FluentGroupedVerticalBarChartData>[
    for (final group in groupedData.entries)
      FluentGroupedVerticalBarChartData(
        name: group.key,
        series: <FluentGroupedBarSeriesPoint>[
          for (final entry in group.value.entries)
            FluentGroupedBarSeriesPoint(
              // `:2790`: the key and the legend are the same string.
              key: entry.key,
              data: entry.value,
              legend: entry.key,
              // `:2793-2802`: the scheme and the range ARE forwarded here,
              // unlike on the scatter and line-overlay paths.
              color: parseCssColour(
                resolveVegaSeriesColour(
                  entry.key,
                  colorIndex[entry.key]!,
                  null,
                  null,
                  colorMap,
                  colorScheme: colorConfig.scheme,
                  colorRange: colorConfig.range,
                  isDark: isDark,
                ),
              ),
            ),
        ],
      ),
  ];

  // `:2811`.
  final titles = getVegaLiteTitles(spec);
  // `:2814`.
  final yAxisTickFormatSpec = _axisOption(encoding, 'y', 'format');
  // `:2815`.
  final bounds = extractYMinMax(encoding, dataValues);
  // `:2816`.
  final yAxisType = extractYAxisType(encoding);

  return FluentGroupedVerticalBarChart(
    // `:2819`.
    data: chartData,
    // `:2820`. `FluentGroupedVerticalBarChart` takes the chart title as a named
    // parameter rather than through the props bag.
    chartTitle: titles.chartTitle,
    props: FluentCartesianChartProps(
      // `:2821-2822`.
      xAxisTitle: titles.xAxisTitle,
      yAxisTitle: titles.yAxisTitle,
      // `:2824`. Upstream forwards the d3 SPEC and the chart resolves it; this
      // port's prop is the resolved formatter, so it is built here.
      yAxisTickFormat: createValueFormatter(
        yAxisTickFormatSpec is String ? yAxisTickFormatSpec : null,
      ),
      // `:2825-2826`: conditional spreads upstream, so the shell's own 0 and 0
      // stand when no domain is declared.
      yMinValue: bounds.min ?? 0,
      yMaxValue: bounds.max ?? 0,
      // `:2827`.
      yScaleType: yAxisType ?? FluentAxisScaleType.auto,
    ),
  );
}

/// Transforms a Vega-Lite bar spec with a categorical y axis into a Fluent
/// horizontal bar chart (`VegaLiteSchemaAdapter.ts:2841-3009`).
///
/// Three mutually exclusive data paths, in upstream's order: an x aggregate
/// (`:2871-2897`), an `x`/`x2` range that makes the bars a Gantt-style span
/// (`:2898-2939`), and the plain row-per-bar case (`:2940-2976`). Note that the
/// axes are INVERTED relative to every other cartesian chart — `x` is the
/// dependent value and `y` the independent category (spec §3.5).
///
/// [spec] is mutated, for the reason [transformVegaToVerticalBar] gives.
FluentHorizontalBarChartWithAxis transformVegaToHorizontalBar(
  Map<String, Object?> spec,
  Map<String, String> colorMap, {
  required bool isDark,
}) {
  // `:2847`.
  final context = initializeTransformContext(spec);
  final dataValues = context.data;
  final encoding = context.encoding;
  final markProps = context.markProps;

  // `:2850`.
  final xField = context.xField;
  final yField = context.yField;
  final colorField = context.colorField;
  final x2Field = context.x2Field;
  final xAggregate = context.xAggregate;

  // `:2854`: `!!xAggregate`, so an empty string is as absent as no aggregate.
  final isAggregate = xAggregate != null && xAggregate.isNotEmpty;

  // `:2856-2858`.
  if (yField == null && !isAggregate) {
    throw const VegaSpecException(
      'VegaLiteSchemaAdapter: y encoding is required for horizontal bar charts',
    );
  }

  // `:2861-2864`: note the argument order — the CATEGORY is the y field and the
  // aggregated value is the x field, the reverse of the stacked bar's call.
  final aggregatedData = isAggregate && yField != null
      ? computeAggregateData(dataValues, yField, xField, xAggregate)
      : null;

  final colorChannel = _channel(encoding, 'color');
  // `:2866`.
  final colorValue = colorChannel?['value'];

  final barData = <FluentHorizontalBarChartWithAxisDataPoint>[];
  final colorIndex = <String, int>{};
  var currentColorIndex = 0;

  // Every one of the three branches resolves its colour with NEITHER the scheme
  // nor the range (`:2886-2887`, `:2934-2935`, `:2964-2965`), so a declared
  // `scale.scheme` is ignored on this chart entirely.
  // // parity: VegaLiteSchemaAdapter.ts:2886
  String colourFor(String legend) {
    colorIndex[legend] ??= currentColorIndex++;
    return resolveVegaSeriesColour(
      legend,
      colorIndex[legend]!,
      colorValue is String ? colorValue : null,
      markProps.color,
      colorMap,
      isDark: isDark,
    );
  }

  if (aggregatedData != null) {
    // `:2871-2897`: one bar per aggregated category, legend equal to the
    // category.
    for (final entry in aggregatedData) {
      final category = jsToString(entry['category']);
      barData.add(
        FluentHorizontalBarChartWithAxisDataPoint(
          x: jsToNumber(entry['value']),
          y: category,
          legend: category,
          color: parseCssColour(colourFor(category)),
        ),
      );
    }
  } else if (x2Field != null && xField != null && yField != null) {
    // `:2898-2939`: an `x`/`x2` pair makes each bar a span, and the bar's x is
    // the span WIDTH rather than either endpoint.
    // `:2900`.
    final isXTemporal = _channelType(encoding, 'x') == 'temporal';
    for (final row in dataValues) {
      final startVal = row[xField];
      final endVal = row[x2Field];
      final yValue = row[yField];
      // `:2905-2907`: `=== undefined` only, so an explicit null reaches the
      // arithmetic below and becomes 0 through `Number(null)`.
      // // parity: VegaLiteSchemaAdapter.ts:2905
      if (!row.containsKey(xField) ||
          startVal is JsUndefined ||
          !row.containsKey(x2Field) ||
          endVal is JsUndefined ||
          !row.containsKey(yField) ||
          yValue is JsUndefined) {
        continue;
      }

      final double xNumeric;
      if (isXTemporal) {
        // `:2911-2915`.
        final startDate = parseVegaDateValue(startVal);
        final endDate = parseVegaDateValue(endVal);
        if (startDate == null || endDate == null) {
          continue;
        }
        // `:2916`: whole days, rounded with JavaScript's half-up rule — never
        // Dart's `.round()`, which rounds a negative half away from zero.
        // `1000 * 60 * 60 * 24` is one day in milliseconds, written as the
        // product upstream writes rather than as 86400000.
        xNumeric = d3.jsRound(
          (endDate.millisecondsSinceEpoch - startDate.millisecondsSinceEpoch) /
              (1000 * 60 * 60 * 24),
        );
      } else {
        // `:2918-2921`.
        xNumeric = jsToNumber(endVal) - jsToNumber(startVal);
        if (xNumeric.isNaN) {
          continue;
        }
      }

      // `:2924`: with no colour field the legend is the CATEGORY, not `'Bar'` —
      // the plain branch below differs on exactly this point.
      final legend =
          colorField != null &&
              row.containsKey(colorField) &&
              row[colorField] is! JsUndefined
          ? jsToString(row[colorField])
          : jsToString(yValue);
      barData.add(
        FluentHorizontalBarChartWithAxisDataPoint(
          x: xNumeric,
          // `:2938`: the raw y value, `number | string`.
          y: yValue is num || yValue is String ? yValue! : jsToString(yValue),
          legend: legend,
          color: parseCssColour(colourFor(legend)),
        ),
      );
    }
  } else if (xField != null && yField != null) {
    // `:2940-2976`: the plain path. A non-numeric x drops the row outright.
    for (final row in dataValues) {
      final xValue = row[xField];
      final yValue = row[yField];
      // `:2946-2948`.
      if (isInvalidValue(xValue) || isInvalidValue(yValue) || xValue is! num) {
        continue;
      }

      // `:2951-2952`: three arms. A present colour value wins; with NO colour
      // field at all every bar is labelled `'Bar'`, which is what stops the
      // tooltip repeating the y-axis label; and a colour field whose value is
      // absent on this row falls back to the y value.
      final String legend;
      if (colorField != null &&
          row.containsKey(colorField) &&
          row[colorField] is! JsUndefined) {
        legend = jsToString(row[colorField]);
      } else if (colorField == null) {
        legend = 'Bar';
      } else {
        legend = jsToString(yValue);
      }

      barData.add(
        FluentHorizontalBarChartWithAxisDataPoint(
          x: xValue.toDouble(),
          // `:2971`.
          y: yValue is num || yValue is String ? yValue! : jsToString(yValue),
          legend: legend,
          color: parseCssColour(colourFor(legend)),
        ),
      );
    }
  }

  // `:2978-2980`.
  final titles = getVegaLiteTitles(spec);
  final annotations = extractVegaAnnotations(spec);
  final tickConfig = extractTickConfig(spec);
  // `:2989`.
  final legendConfig = colorChannel?['legend'];
  final legendDisabled =
      legendConfig is Map<String, Object?> && legendConfig['disable'] == true;

  return FluentHorizontalBarChartWithAxis(
    // `:2983`.
    data: barData,
    // `:2984`. `FluentHorizontalBarChartWithAxis` takes the chart title as a
    // named parameter rather than through the props bag.
    chartTitle: titles.chartTitle,
    props: FluentCartesianChartProps(
      // `:2985-2986`.
      xAxisTitle: titles.xAxisTitle,
      yAxisTitle: titles.yAxisTitle,
      // `:2989`: no colour field hides the legend unconditionally; with one,
      // the encoding's own `legend.disable` decides, defaulting to `false`.
      hideLegend: colorField == null || legendDisabled,
      // `:2992-2994`: assigned only when non-empty, and the shell's own default
      // is the empty list — which is what an empty list leaves.
      annotations: annotations,
      // `:2996-3006`: each assigned only when truthy, so a declared 0 keeps the
      // shell's defaults of 6 and 4.
      tickValues: tickConfig.tickValues,
      xAxisTickCount: tickConfig.xAxisTickCount ?? 6,
      yAxisTickCount: tickConfig.yAxisTickCount ?? 4,
    ),
  );
}
