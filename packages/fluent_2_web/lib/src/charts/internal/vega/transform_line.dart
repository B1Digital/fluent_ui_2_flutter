import '../../cartesian/cartesian_chart_props.dart';
import '../../chrome/legend_shape.dart';
import '../../model/cartesian_series.dart';
import '../../model/chart_common.dart';
import '../../scatter_chart.dart';
import '../plotly/common.dart' show parseCssColour;
import 'common.dart'
    show
        createValueFormatter,
        extractAxisCategoryOrderProps,
        extractTickConfig,
        extractYAxisType,
        extractYMinMax,
        getVegaLiteTitles,
        parseVegaValue;
import 'context.dart'
    show
        extractVegaAnnotations,
        initializeTransformContext,
        resolveVegaSeriesColour;
import 'js_value.dart' show JsUndefined, jsToNumber, jsToString;
import 'spec.dart' show VegaSpecException;

/// The tick values, tick format and bounds a categorical y axis needs
/// (`VegaLiteSchemaAdapter.ts:1967-1973`, duplicated verbatim at `:3206-3210`).
///
/// A nominal or ordinal y axis is plotted at integer indices, so the bounds sit
/// half a category outside them and the format function renames each index back
/// to its label. When [labels] is null or empty nothing is overridden and
/// [fallbackFormat] survives, which is exactly upstream's `yOrdinalLabels &&
/// yOrdinalLabels.length > 0` guard.
({
  List<Object>? tickValues,
  String Function(double)? tickFormat,
  double? min,
  double? max,
})
_nominalYAxisProps(
  List<String>? labels,
  String Function(double)? fallbackFormat,
) {
  if (labels == null || labels.isEmpty) {
    return (tickValues: null, tickFormat: fallbackFormat, min: null, max: null);
  }
  return (
    // `:1969` / `:3206`: one tick per label, at its own index.
    tickValues: <Object>[for (var i = 0; i < labels.length; i++) i],
    // `:1970` / `:3207`: `yOrdinalLabels[val] ?? String(val)`. A JavaScript
    // array read with a fractional or out-of-range index answers `undefined`,
    // so only a whole number that indexes the list renames the tick.
    tickFormat: (double value) {
      final index = value.toInt();
      return value == index && index >= 0 && index < labels.length
          ? labels[index]
          : jsToString(value);
    },
    // `:1971-1972` / `:3208-3209`: half a category either side, so the first and
    // last rows are not flush against the plot edges. 0.5 is half of the unit
    // step between two consecutive integer indices.
    min: -0.5,
    max: labels.length - 0.5,
  );
}

/// Transforms a Vega-Lite point spec into a Fluent scatter chart
/// (`VegaLiteSchemaAdapter.ts:3070-3232`).
///
/// This path uses [initializeTransformContext], so a conditional colour
/// encoding and a `timeUnit` aggregation are both applied before the points are
/// grouped (`:3076`).
///
/// [FluentScatterChart] is a shell chart, so every axis setting goes inside
/// `props`. The spec's own `width` and `height` are not read here — upstream's
/// `ScatterChartProps` carries neither at `:3191-3231` — and reach the chart as
/// the box its caller wraps it in.
FluentScatterChart transformVegaToScatter(
  Map<String, Object?> spec,
  Map<String, String> colorMap, {
  required bool isDark,
}) {
  // `:3076`.
  final context = initializeTransformContext(spec);
  final dataValues = context.data;
  final encoding = context.encoding;
  final markProps = context.markProps;

  // `:3079`.
  final xField = context.xField;
  final yField = context.yField;
  final colorField = context.colorField;
  final sizeField = context.sizeField;

  // `:3081-3083`, message verbatim.
  if (xField == null || yField == null) {
    throw const VegaSpecException(
      'VegaLiteSchemaAdapter: Both x and y encodings are required for scatter '
      'charts',
    );
  }

  final x = encoding['x'] is Map<String, Object?>
      ? encoding['x']! as Map<String, Object?>
      : null;
  final y = encoding['y'] is Map<String, Object?>
      ? encoding['y']! as Map<String, Object?>
      : null;
  final color = encoding['color'] is Map<String, Object?>
      ? encoding['color']! as Map<String, Object?>
      : null;

  // `:3085-3086`.
  final isXTemporal = x?['type'] == 'temporal';
  final isYTemporal = y?['type'] == 'temporal';

  // `:3089-3105`: a nominal or ordinal y is plotted at integer indices, and the
  // labels are collected in FIRST-SEEN row order, never sorted.
  final yType = y?['type'];
  final yIsNominal = yType == 'nominal' || yType == 'ordinal';
  final yOrdinalMap = <String, int>{};
  final yOrdinalLabels = <String>[];
  if (yIsNominal) {
    for (final row in dataValues) {
      // `:3097`: `yVal !== undefined`, so an ABSENT column is skipped but an
      // explicit JSON null becomes the label `'null'`.
      if (!row.containsKey(yField) || row[yField] is JsUndefined) continue;
      final key = jsToString(row[yField]);
      if (!yOrdinalMap.containsKey(key)) {
        yOrdinalMap[key] = yOrdinalMap.length;
        yOrdinalLabels.add(key);
      }
    }
  }

  // `:3108-3118`: one series per distinct colour value, keyed in first-seen
  // order; a spec with no colour field gets the single series `'default'`
  // (`:3111`).
  final groupedData = <String, List<Map<String, Object?>>>{};
  for (final row in dataValues) {
    final seriesName =
        colorField != null &&
            row.containsKey(colorField) &&
            row[colorField] is! JsUndefined
        ? jsToString(row[colorField])
        : 'default';
    (groupedData[seriesName] ??= <Map<String, Object?>>[]).add(row);
  }

  final scale = color?['scale'] is Map<String, Object?>
      ? color!['scale']! as Map<String, Object?>
      : null;
  final rangeRaw = scale?['range'];

  // `:3120-3175`.
  final colorIndex = <String, int>{};
  var currentColorIndex = 0;
  final scatterChartData = <FluentScatterChartSeries>[];
  final seriesEntries = groupedData.entries.toList();
  for (var index = 0; index < seriesEntries.length; index++) {
    final seriesName = seriesEntries[index].key;
    // `:3125-3127`: the colour index is the series ordinal within this chart.
    colorIndex[seriesName] ??= currentColorIndex++;

    final points = <FluentScatterChartDataPoint>[];
    for (final row in seriesEntries[index].value) {
      final xValue = parseVegaValue(row[xField], isTemporal: isXTemporal);
      final yValue = parseVegaValue(row[yField], isTemporal: isYTemporal);
      // `:3132`: only a present size column produces a marker size.
      final markerSize =
          sizeField != null &&
              row.containsKey(sizeField) &&
              row[sizeField] is! JsUndefined
          ? jsToNumber(row[sizeField])
          : null;

      // `:3135-3141`: a categorical y is replaced by its index, and anything
      // that is not a number at this point plots at 0 rather than being dropped.
      final double numericY;
      if (yIsNominal && yValue is String) {
        numericY = (yOrdinalMap[yValue] ?? 0).toDouble();
      } else {
        numericY = yValue is num ? yValue.toDouble() : 0;
      }

      points.add(
        FluentScatterChartDataPoint(
          // `:3144`: a value that is neither a number nor a date is stringified.
          x: xValue is num || xValue is DateTime ? xValue : jsToString(xValue),
          y: numericY,
          markerSize: markerSize,
        ),
      );
    }

    // `:3148-3151`: an explicit `color.scale.range` is indexed by the SERIES
    // ORDINAL. An index past the end of that array reads `undefined` upstream,
    // which fails the string test below and falls through to the resolver — it
    // does NOT fall back to the mark colour, because the mark colour is the
    // other arm of this conditional and not a second fallback inside it.
    final Object? colourValue;
    if (colorField != null && rangeRaw is List<Object?>) {
      colourValue = index < rangeRaw.length ? rangeRaw[index] : null;
    } else {
      colourValue = markProps.color;
    }
    final colour = colourValue is String
        ? colourValue
        // `:3155-3164`: both the scheme and the range arguments are `undefined`
        // here, so a named `scale.scheme` is ignored on the scatter path even
        // though `scale.range` above is honoured.
        // // parity: VegaLiteSchemaAdapter.ts:3155-3164
        : resolveVegaSeriesColour(
            seriesName,
            colorIndex[seriesName]!,
            null,
            null,
            colorMap,
            isDark: isDark,
          );

    scatterChartData.add(
      FluentScatterChartSeries(
        legend: seriesName,
        data: points,
        color: parseCssColour(colour),
        // `:3173`: every scatter series draws a circular swatch, whatever the
        // mark's own shape.
        legendShape: FluentChartLegendShape.circle,
      ),
    );
  }

  // `:3177-3179`.
  final titles = getVegaLiteTitles(spec);
  final annotations = extractVegaAnnotations(spec);
  final tickConfig = extractTickConfig(spec);

  // `:3182`.
  final yAxisType = extractYAxisType(encoding);
  // `:3185`.
  final yAxis = y?['axis'] is Map<String, Object?>
      ? y!['axis']! as Map<String, Object?>
      : null;
  final yAxisTickFormatSpec = yAxis?['format'] is String
      ? yAxis!['format']! as String
      : null;
  // `:3186`.
  final bounds = extractYMinMax(encoding, dataValues);
  // `:3189`.
  final categoryOrder = extractAxisCategoryOrderProps(encoding);

  // `:3204-3210`.
  final nominalY = _nominalYAxisProps(
    yIsNominal ? yOrdinalLabels : null,
    createValueFormatter(yAxisTickFormatSpec),
  );

  final legend = color?['legend'];
  final disable = legend is Map<String, Object?> ? legend['disable'] : null;

  return FluentScatterChart(
    data: FluentChartData(
      // `:3191-3194`: the chart title travels on the data bundle.
      chartTitle: titles.chartTitle,
      scatterChartData: scatterChartData,
    ),
    props: FluentCartesianChartProps(
      // `:3195-3196`.
      xAxisTitle: titles.xAxisTitle,
      yAxisTitle: titles.yAxisTitle,
      // `:3198` and `:3207`: the ordinal renamer wins over the format
      // specifier, because it is spread later.
      yAxisTickFormat: nominalY.tickFormat,
      yAxisTickValues: nominalY.tickValues,
      // `:3200-3201` then `:3208-3209`. The shell's own defaults are 0 and 0
      // (`cartesian_chart_props.dart:91-92`), so an absent domain keeps them.
      yMinValue: nominalY.min ?? bounds.min ?? 0,
      yMaxValue: nominalY.max ?? bounds.max ?? 0,
      // `:3202`.
      yScaleType: yAxisType ?? FluentAxisScaleType.auto,
      // `:3211`.
      xAxisCategoryOrder:
          categoryOrder.x ?? FluentAxisCategoryOrder.defaultOrder,
      yAxisCategoryOrder:
          categoryOrder.y ?? FluentAxisCategoryOrder.defaultOrder,
      // `:3215-3217`: assigned only when non-empty, which an empty list
      // matches.
      annotations: annotations,
      // `:3219-3221`.
      tickValues: tickConfig.tickValues,
      // `:3223-3229`: each count is spread only when truthy, so a declared 0
      // keeps the shell's default of 6 and 4.
      xAxisTickCount: tickConfig.xAxisTickCount ?? 6,
      yAxisTickCount: tickConfig.yAxisTickCount ?? 4,
      // `:3212`: `?? false`, so an absent `legend.disable` shows the legend.
      hideLegend: disable == true,
    ),
  );
}
