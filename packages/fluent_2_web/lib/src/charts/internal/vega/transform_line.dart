import '../../area_chart.dart';
import '../../cartesian/cartesian_chart_props.dart';
import '../../chrome/legend_shape.dart';
import '../../line_chart.dart';
import '../../model/cartesian_series.dart';
import '../../model/chart_common.dart';
import '../../model/line_options.dart';
import '../../scatter_chart.dart';
import '../plotly/common.dart' show parseCssColour;
import 'common.dart'
    show
        FluentVegaMarkProperties,
        createValueFormatter,
        extractAxisCategoryOrderProps,
        extractTickConfig,
        extractYAxisType,
        extractYMinMax,
        getMarkProperties,
        getVegaLiteTitles,
        mapInterpolateToCurve,
        parseVegaValue,
        validateVegaXYEncodings;
import 'context.dart'
    show
        extractVegaAnnotations,
        extractVegaColorFillBars,
        groupDataBySeries,
        initializeTransformContext,
        resolveVegaSeriesColour;
import 'js_value.dart' show JsUndefined, jsToNumber, jsToString, jsTruthy;
import 'routing.dart' show normalizeVegaSpec;
import 'spec.dart' show VegaSpecException, extractVegaDataValues, getMarkType;
import 'transforms.dart' show applyVegaTransforms;

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

/// The layer a line or area chart actually plots
/// (`VegaLiteSchemaAdapter.ts:1515-1533`).
///
/// A `line`, `point` or `area` layer wins; failing that, the first layer with a
/// real field encoding; failing that, layer zero. The point is to skip the
/// `rect` layers that carry colour fill bars.
///
/// Module-private, exactly as upstream declares it: its only two callers are
/// [transformVegaToLine] (`:1764`) and [transformVegaToArea] (`:3039`).
Map<String, Object?>? _findPrimaryLineSpec(
  List<Map<String, Object?>> unitSpecs,
) {
  for (final spec in unitSpecs) {
    final markType = getMarkType(spec['mark']);
    if (markType == 'line' || markType == 'point' || markType == 'area') {
      return spec;
    }
  }
  // `:1526-1529`: a layer that names a field on either channel, so a `rule` or
  // `text` layer positioned by `datum` alone is still skipped.
  for (final spec in unitSpecs) {
    final encoding = spec['encoding'];
    if (encoding is! Map<String, Object?>) continue;
    final x = encoding['x'];
    final y = encoding['y'];
    final hasX = x is Map<String, Object?> && jsTruthy(x['field']);
    final hasY = y is Map<String, Object?> && jsTruthy(y['field']);
    if (hasX || hasY) return spec;
  }
  // `:1532`: `dataSpec || unitSpecs[0]`, and an empty list indexes to
  // `undefined`.
  return unitSpecs.isEmpty ? null : unitSpecs.first;
}

/// The SVG `stroke-dasharray` a mark's dash list spells
/// (`VegaLiteSchemaAdapter.ts:1851`, repeated at `:1920`).
///
/// Joined with a SPACE, and `Array.prototype.join` stringifies each entry the
/// way JavaScript does, so `4` renders as `4` rather than Dart's `4.0`. An
/// EMPTY dash list still produces the empty string, because `:1850` tests the
/// array for truthiness and `[]` is truthy in JavaScript.
/// // parity: VegaLiteSchemaAdapter.ts:1850
String? _dashArrayOf(FluentVegaMarkProperties markProps) =>
    markProps.strokeDash?.map(jsToString).join(' ');

/// The line options a mark's properties imply
/// (`VegaLiteSchemaAdapter.ts:1846-1855`, and `:1918-1924` without [curve]).
///
/// Returns null when the mark declares none, because upstream spreads the
/// object only when it has keys (`:1862`, `:1934`) and an empty `lineOptions`
/// would otherwise override the chart's own defaults.
FluentLineOptions? _lineOptionsFrom(
  FluentVegaMarkProperties markProps,
  FluentLineCurve? curve,
) {
  final dash = _dashArrayOf(markProps);
  // `:1853`: `if (markProps.strokeWidth)`, so a width of 0 is treated as
  // absent.
  final width = markProps.strokeWidth == 0 ? null : markProps.strokeWidth;
  if (curve == null && dash == null && width == null) return null;
  return FluentLineOptions(
    strokeWidth: width,
    strokeDasharray: dash,
    curve: curve,
  );
}

/// The sort key of an already-mapped x value, which is a `num` or a [DateTime].
///
/// `VegaLiteSchemaAdapter.ts:1891-1892` reduces with bare `<` and `>`, and
/// JavaScript's relational comparison takes each operand's numeric primitive —
/// a `Date`'s is its epoch millisecond count. `jsLess` cannot stand in here:
/// `Number(new Date())` is that count, while `jsToNumber` answers NaN for a
/// [DateTime], which would make every comparison between two dates false and
/// pin both extremes to the first point.
double _xOrder(Object x) =>
    x is DateTime ? x.millisecondsSinceEpoch.toDouble() : (x as num).toDouble();

/// Transforms a Vega-Lite line spec into a Fluent line chart
/// (`VegaLiteSchemaAdapter.ts:1751-1977`).
///
/// This path does **not** call `initializeTransformContext`. It re-derives
/// everything from [_findPrimaryLineSpec] (`:1757-1795`), so a layered spec's
/// `rect` colour-fill layers are skipped, and it therefore applies only the
/// TOP-LEVEL transforms (`:1776`) and never the layer's own. Both are
/// reproduced.
///
/// [FluentLineChart] is a shell chart, so every axis setting goes inside
/// `props` and `:1953-1954`'s `width` and `height` are not read — the nine
/// shell charts size to their `BoxConstraints` (spec section 2.2) and the
/// dimensions reach the chart as the box its caller wraps it in, the same rule
/// `internal/plotly/transform_bar.dart` and `transform_xy.dart` already follow.
///
/// `:1957`'s `tickFormat` — the d3 specifier for the X axis — is dropped, and
/// this is the one member of the return block that has nowhere to go:
/// `FluentCartesianChartProps` declares no counterpart, because the only
/// consumer of an x tick-format string in the port is `FluentTickParams`
/// (`axis/axis_types.dart:211`), which the shell fills from
/// `delegate.tickParams` (`cartesian/cartesian_chart.dart:750`) and no chart
/// overrides. The Plotly adapter drops the same value for the same reason —
/// `getXAxisTickFormat` (`PlotlySchemaAdapter.ts:200-208`) has no port.
/// // ponytail: goes when the shell grows a caller-facing x tick format.
FluentLineChart transformVegaToLine(
  Map<String, Object?> spec,
  Map<String, String> colorMap, {
  required bool isDark,
}) {
  // `:1757-1761`, message verbatim.
  final unitSpecs = normalizeVegaSpec(spec);
  if (unitSpecs.isEmpty) {
    throw const VegaSpecException(
      'VegaLiteSchemaAdapter: No valid unit specs found in specification',
    );
  }
  // `:1764-1767`, message verbatim.
  final primarySpec = _findPrimaryLineSpec(unitSpecs);
  if (primarySpec == null) {
    throw const VegaSpecException(
      'VegaLiteSchemaAdapter: No valid line/point layer found in specification',
    );
  }

  // `:1770-1772`: dots are shown only when the spec layers a point mark ON TOP
  // OF a line mark; a point-only spec routes to the scatter transformer
  // instead.
  var hasPointLayer = false;
  var hasLineLayer = false;
  for (final unitSpec in unitSpecs) {
    final markType = getMarkType(unitSpec['mark']);
    if (markType == 'point') hasPointLayer = true;
    if (markType == 'line') hasLineLayer = true;
  }
  final shouldShowPoints = hasPointLayer && hasLineLayer;

  // `:1774-1776`: only the TOP-LEVEL transforms, unlike
  // `initializeTransformContext`, which also applies the layer's own.
  // // parity: VegaLiteSchemaAdapter.ts:1776
  final dataValues = applyVegaTransforms(
    extractVegaDataValues(primarySpec['data']),
    spec['transform'] is List<Object?>
        ? spec['transform']! as List<Object?>
        : null,
  );
  final encodingRaw = primarySpec['encoding'];
  final encoding = encodingRaw is Map<String, Object?>
      ? encodingRaw
      : <String, Object?>{};
  final markProps = getMarkProperties(primarySpec['mark']);

  final x = encoding['x'] is Map<String, Object?>
      ? encoding['x']! as Map<String, Object?>
      : null;
  final y = encoding['y'] is Map<String, Object?>
      ? encoding['y']! as Map<String, Object?>
      : null;
  final color = encoding['color'] is Map<String, Object?>
      ? encoding['color']! as Map<String, Object?>
      : null;
  // `:1781`, through `extractEncodingFields` (`:1276-1288`).
  final xField = x?['field'] is String ? x!['field']! as String : null;
  final yField = y?['field'] is String ? y!['field']! as String : null;
  final colorField = color?['field'] is String
      ? color!['field']! as String
      : null;

  // `:1784-1795`: for a layered spec the size field may live on ANY layer — the
  // point layer of a line-plus-point combo — while a single spec reads its own.
  String? sizeField;
  if (unitSpecs.length > 1) {
    for (final unitSpec in unitSpecs) {
      final unitEncoding = unitSpec['encoding'];
      final size = unitEncoding is Map<String, Object?>
          ? unitEncoding['size']
          : null;
      final field = size is Map<String, Object?> ? size['field'] : null;
      // `:1788`: `if (unitEncoding.size?.field)`, a truthiness test, so the
      // empty string does not win the search.
      if (field is String && field.isNotEmpty) {
        sizeField = field;
        break;
      }
    }
  } else {
    final size = encoding['size'];
    final field = size is Map<String, Object?> ? size['field'] : null;
    sizeField = field is String && field.isNotEmpty ? field : null;
  }

  // `:1798-1800`, message verbatim.
  if (xField == null || yField == null) {
    throw const VegaSpecException(
      'VegaLiteSchemaAdapter: Line chart requires both x and y encodings with '
      'field names',
    );
  }

  final declaredXType = x?['type'] is String ? x!['type']! as String : null;
  final declaredYType = y?['type'] is String ? y!['type']! as String : null;
  // `:1802`: may rewrite `encoding.x.type` / `.y.type` in place, which is why
  // the two types below are read back AFTER it rather than reused.
  validateVegaXYEncodings(
    dataValues,
    xField,
    yField,
    declaredXType,
    declaredYType,
    'LineChart',
    encoding: encoding,
  );

  final xType = x?['type'] is String ? x!['type']! as String : null;
  final yType = y?['type'] is String ? y!['type']! as String : null;

  // `:1804-1818`.
  final grouped = groupDataBySeries(
    dataValues,
    xField,
    yField,
    colorField,
    isXTemporal: xType == 'temporal',
    isYTemporal: yType == 'temporal',
    xType: xType,
    sizeField: sizeField,
    yType: yType,
  );

  // `:1821`, through `extractColorConfig` (`:1396-1401`).
  final scale = color?['scale'] is Map<String, Object?>
      ? color!['scale']! as Map<String, Object?>
      : null;
  final scheme = scale?['scheme'];
  final rangeRaw = scale?['range'];
  final colorScheme = scheme is String ? scheme : null;
  final colorRange = rangeRaw is List<Object?>
      ? <String>[
          for (final entry in rangeRaw)
            if (entry is String) entry,
        ]
      : null;

  // `:1824-1864`: the colour index is the SERIES ORDINAL within this chart, not
  // the colour map's size — see `resolveVegaSeriesColour`'s doc.
  final lineChartData = <FluentLineChartSeries>[];
  var currentColorIndex = 0;
  final colorIndex = <String, int>{};
  // `:1843`: read once per series upstream, but off `markProps` alone, so the
  // answer cannot vary between them.
  final curve = mapInterpolateToCurve(markProps.interpolate);
  for (final series in grouped.seriesMap.entries) {
    final seriesName = series.key;
    colorIndex[seriesName] ??= currentColorIndex++;
    final colour = resolveVegaSeriesColour(
      seriesName,
      colorIndex[seriesName]!,
      null,
      markProps.color,
      colorMap,
      colorScheme: colorScheme,
      colorRange: colorRange,
      isDark: isDark,
    );
    lineChartData.add(
      FluentLineChartSeries(
        legend: seriesName,
        data: <FluentLineChartDataPoint>[
          for (final point in series.value)
            FluentLineChartDataPoint(
              x: point.x,
              y: point.y,
              markerSize: point.markerSize,
            ),
        ],
        color: parseCssColour(colour),
        // `:1861`: inverted — dots are hidden UNLESS the spec layered points.
        hideInactiveDots: !shouldShowPoints,
        lineOptions: _lineOptionsFrom(markProps, curve),
      ),
    );
  }

  // `:1867`.
  final title = spec['title'];
  final chartTitle = title is String
      ? title
      : (title is Map<String, Object?> && title['text'] is String
            ? title['text']! as String
            : null);

  // `:1870-1873`: this reads `axis.title` ONLY, not the channel's own `title`,
  // unlike `getVegaLiteTitles` at `:2125`, which the scatter path above uses.
  // // parity: VegaLiteSchemaAdapter.ts:1870
  final xAxis = x?['axis'] is Map<String, Object?>
      ? x!['axis']! as Map<String, Object?>
      : null;
  final yAxis = y?['axis'] is Map<String, Object?>
      ? y!['axis']! as Map<String, Object?>
      : null;
  final xAxisTitle = xAxis?['title'] is String
      ? xAxis!['title']! as String
      : null;
  final yAxisTitle = yAxis?['title'] is String
      ? yAxis!['title']! as String
      : null;
  final yAxisTickFormatSpec = yAxis?['format'] is String
      ? yAxis!['format']! as String
      : null;

  // `:1877`: `||`, so an ordinal axis's generated labels beat an explicit
  // `axis.values`.
  final declaredTickValues = xAxis?['values'];
  final tickValues = grouped.ordinalLabels != null
      ? <Object>[...grouped.ordinalLabels!]
      : (declaredTickValues is List<Object?>
            ? <Object>[for (final value in declaredTickValues) ?value]
            : null);
  // `:1878` then `:1960`: `&&`, so a declared tick count of 0 is dropped and
  // the shell's own default of 4 stands.
  final declaredYTickCount = yAxis?['tickCount'];
  final yAxisTickCount = declaredYTickCount is num && declaredYTickCount != 0
      ? declaredYTickCount.toInt()
      : null;

  // `:1881`.
  final bounds = extractYMinMax(encoding, dataValues);

  // `:1884-1885`.
  final annotations = extractVegaAnnotations(spec);
  final colorFillBars = extractVegaColorFillBars(
    spec,
    colorMap,
    isDark: isDark,
  );

  // `:1889-1937`: each horizontal `rule` layer becomes a two-point series
  // spanning the data's x extent.
  final layerRaw = spec['layer'];
  if (layerRaw is List<Object?> && lineChartData.isNotEmpty) {
    // `:1890-1892`: reduced over the ALREADY-MAPPED x values of every series,
    // so an ordinal axis compares indices and a temporal axis epoch millis.
    Object? xMin;
    Object? xMax;
    for (final series in lineChartData) {
      for (final point in series.data) {
        final value = (point as FluentLineChartDataPoint).x;
        if (xMin == null || _xOrder(value) < _xOrder(xMin)) xMin = value;
        if (xMax == null || _xOrder(value) > _xOrder(xMax)) xMax = value;
      }
    }
    // `:1891-1892`: the fallback is the number 0 when there are no points at
    // all, which a series list of empty series reaches.
    final resolvedXMin = xMin ?? 0;
    final resolvedXMax = xMax ?? 0;

    for (final layer in layerRaw) {
      if (layer is! Map<String, Object?>) continue;
      // `:1895-1898`.
      if (getMarkType(layer['mark']) != 'rule') continue;
      final ruleEncodingRaw = layer['encoding'];
      final ruleEncoding = ruleEncodingRaw is Map<String, Object?>
          ? ruleEncodingRaw
          : const <String, Object?>{};
      final ruleY = ruleEncoding['y'];
      final yDatum = ruleY is Map<String, Object?>
          ? (ruleY['datum'] ?? ruleY['value'])
          : null;
      // `:1902-1904`: a vertical rule is skipped entirely on this path — only
      // the annotation extractor sees it.
      // // parity: VegaLiteSchemaAdapter.ts:1902
      if (yDatum == null) continue;

      final ruleMarkProps = getMarkProperties(layer['mark']);
      // `:1907`: Vega's own reference-line red, `#d62728` — the fourth entry of
      // category10, hard-coded rather than taken from the scheme.
      final ruleColor = jsTruthy(ruleMarkProps.color)
          ? ruleMarkProps.color!
          : '#d62728';

      // `:1910-1916`: a companion text layer at the same y supplies the legend
      // name; otherwise it is `y=<value>`.
      final fallbackLegend = 'y=${jsToString(yDatum)}';
      var ruleLegend = fallbackLegend;
      for (final candidate in layerRaw) {
        if (candidate is! Map<String, Object?>) continue;
        if (getMarkType(candidate['mark']) != 'text') continue;
        final candidateEncoding = candidate['encoding'];
        if (candidateEncoding is! Map<String, Object?>) continue;
        final candidateY = candidateEncoding['y'];
        // `:1912`: `l.encoding?.y &&` first, then a STRICT equality on the
        // datum, so a `15` never matches a `'15'`.
        if (candidateY is! Map<String, Object?>) continue;
        if ((candidateY['datum'] ?? candidateY['value']) != yDatum) continue;
        final textChannel = candidateEncoding['text'];
        final label = textChannel is Map<String, Object?>
            ? (jsTruthy(textChannel['datum'])
                  ? textChannel['datum']
                  : (jsTruthy(textChannel['value'])
                        ? textChannel['value']
                        : null))
            : null;
        ruleLegend = label == null ? fallbackLegend : jsToString(label);
        break;
      }

      lineChartData.add(
        FluentLineChartSeries(
          legend: ruleLegend,
          // `:1928-1931`: exactly two points, at the data's x extremes.
          // `yDatum as number` upstream, which is `Number(…)` here so a
          // non-numeric datum plots as NaN rather than as a silent string.
          data: <FluentLineChartDataPoint>[
            FluentLineChartDataPoint(x: resolvedXMin, y: jsToNumber(yDatum)),
            FluentLineChartDataPoint(x: resolvedXMax, y: jsToNumber(yDatum)),
          ],
          color: parseCssColour(ruleColor),
          // `:1933`: a reference line never shows dots.
          hideInactiveDots: true,
          // `:1918-1924`: the rule block reads no `interpolate`, so it has no
          // curve of its own.
          lineOptions: _lineOptionsFrom(ruleMarkProps, null),
        ),
      );
    }
  }

  // `:1940`.
  final yAxisType = extractYAxisType(encoding);
  // `:1943`.
  final categoryOrder = extractAxisCategoryOrderProps(encoding);
  // `:1966-1973`, the same override the scatter path spreads at `:3204-3210`.
  final nominalY = _nominalYAxisProps(
    grouped.yOrdinalLabels,
    createValueFormatter(yAxisTickFormatSpec),
  );

  final legend = color?['legend'];
  final disable = legend is Map<String, Object?> ? legend['disable'] : null;

  return FluentLineChart(
    data: FluentChartData(
      // `:1946-1949`: the chart title lives on the DATA bundle, not the props.
      chartTitle: chartTitle,
      lineChartData: lineChartData,
    ),
    props: FluentCartesianChartProps(
      // `:1955` spreads `...(xAxisTitle && { chartTitle: xAxisTitle })`. The
      // key is `chartTitle`, not `xAxisTitle`, so upstream drops the x axis
      // label entirely and overwrites `props.chartTitle` — the narration prefix
      // `CartesianChart.tsx:553` reads — with it. `:1956` spreads `yAxisTitle`
      // correctly one line below, which is what shows the key to be a typo
      // rather than intent. Reproducing it would silently unlabel the x axis of
      // every Vega line and area chart, so the port assigns the field `:1956`
      // implies. // hardened: VegaLiteSchemaAdapter.ts:1955
      xAxisTitle: xAxisTitle,
      // `:1956`.
      yAxisTitle: yAxisTitle,
      // `:1959`.
      tickValues: tickValues,
      // `:1958` then `:1970`: the ordinal renamer wins over the format
      // specifier, because it is spread later.
      yAxisTickValues: nominalY.tickValues,
      yAxisTickFormat: nominalY.tickFormat,
      // `:1960`.
      yAxisTickCount: yAxisTickCount ?? 4,
      // `:1961-1962` then `:1971-1972`. The shell's own defaults are 0 and 0
      // (`cartesian/cartesian_chart_props.dart:91-92`), so an absent domain
      // keeps them.
      yMinValue: nominalY.min ?? bounds.min ?? 0,
      yMaxValue: nominalY.max ?? bounds.max ?? 0,
      // `:1963`: assigned only when non-empty, which an empty list matches.
      annotations: annotations,
      // `:1965`.
      yScaleType: yAxisType ?? FluentAxisScaleType.auto,
      // `:1974`.
      xAxisCategoryOrder:
          categoryOrder.x ?? FluentAxisCategoryOrder.defaultOrder,
      yAxisCategoryOrder:
          categoryOrder.y ?? FluentAxisCategoryOrder.defaultOrder,
      // `:1975`: `?? false`, so an absent `legend.disable` shows the legend.
      hideLegend: disable == true,
    ),
    // `:1964`.
    colorFillBars: colorFillBars,
  );
}

/// Transforms a Vega-Lite area spec into a Fluent area chart
/// (`VegaLiteSchemaAdapter.ts:3027-3058`).
///
/// Delegates to [transformVegaToLine] and overrides only the fill mode, because
/// the two charts share their entire data shape (`:3035`).
///
/// One member of the spread cannot survive the delegation: `FluentAreaChart`
/// declares no `colorFillBars`, so a `rect` fill layer that
/// [transformVegaToLine] resolves is dropped here. That is upstream's shape
/// too — `AreaChartProps` inherits `colorFillBars` from `CartesianChartProps`
/// but `AreaChart.tsx` never reads it, while `LineChart.tsx:1289` does.
/// // parity: AreaChart.tsx
FluentAreaChart transformVegaToArea(
  Map<String, Object?> spec,
  Map<String, String> colorMap, {
  required bool isDark,
}) {
  // `:3035`.
  final line = transformVegaToLine(spec, colorMap, isDark: isDark);

  // `:3037-3040`.
  final primarySpec = _findPrimaryLineSpec(normalizeVegaSpec(spec));
  final encodingRaw = primarySpec?['encoding'];
  final encoding = encodingRaw is Map<String, Object?>
      ? encodingRaw
      : const <String, Object?>{};
  // `:3044`: `!!encoding.color?.field`, a truthiness test, so an empty field
  // name does not count as a colour encoding.
  final color = encoding['color'];
  final hasColorEncoding =
      color is Map<String, Object?> && jsTruthy(color['field']);
  final y = encoding['y'];
  final hasStackKey = y is Map<String, Object?> && y.containsKey('stack');
  final stackConfig = y is Map<String, Object?> ? y['stack'] : null;

  // `:3047`: `stackConfig !== null && (stackConfig === 'zero' ||
  // hasColorEncoding)`. An explicit `stack: null` disables stacking even with a
  // colour encoding, which is why the key's PRESENCE has to be distinguished
  // from its absence — in JavaScript `undefined !== null` is true, so an absent
  // `stack` still stacks when a colour field is present.
  final isStacked =
      !(hasStackKey && stackConfig == null) &&
      (stackConfig == 'zero' || hasColorEncoding);

  return FluentAreaChart(
    data: line.data,
    props: line.props,
    // `:3050`: `tonexty` stacks each series on the one below, `tozeroy` fills
    // to the axis.
    mode: isStacked ? FluentAreaChartMode.toNextY : FluentAreaChartMode.toZeroY,
  );
}
