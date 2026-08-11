/// The Vega-Lite bar-family transformers.
///
/// Ports `VegaLiteSchemaAdapter.ts:2141-2337` (vertical bar) and
/// `:3524-3695` (histogram). Internal to the package: nothing here is
/// barrel-exported.
library;

import 'dart:math' as math;

import '../../cartesian/cartesian_chart_props.dart';
import '../../model/bar_data.dart';
import '../../model/chart_common.dart';
import '../../vertical_bar_chart.dart';
import '../d3/array_stats.dart' as d3;
import '../d3/bin.dart' as d3;
import '../d3/js_math.dart' as d3;
import '../plotly/common.dart' show parseCssColour;
import '../plotly/predicates.dart' show isInvalidValue;
import 'common.dart';
import 'context.dart';
import 'js_value.dart'
    show JsUndefined, jsToNumber, jsToString, jsTruthy, jsTypeof;
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
