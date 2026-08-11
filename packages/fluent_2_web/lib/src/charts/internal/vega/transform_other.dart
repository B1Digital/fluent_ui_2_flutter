/// The Vega-Lite donut, heat map and polar transformers.
///
/// Ports `VegaLiteSchemaAdapter.ts:3244-3310` (donut), `:3322-3519` (heat map)
/// and `:3706-3861` (polar). Internal to the package: nothing here is
/// barrel-exported.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../cartesian/cartesian_chart_props.dart';
import '../../donut_chart.dart';
import '../../heat_map_chart.dart';
import '../../model/bar_data.dart';
import '../../model/cartesian_series.dart';
import '../../model/chart_common.dart';
import '../../model/heatmap_data.dart';
import '../../model/line_options.dart';
import '../../model/polar_data.dart';
import '../../polar_chart.dart';
import '../d3/js_math.dart' as d3;
import '../d3/stable_sort.dart';
import '../plotly/common.dart' show parseCssColour;
import '../plotly/predicates.dart' show isInvalidValue;
import 'color_adapter.dart' show getSequentialSchemeColors, getVegaColor;
import 'common.dart';
import 'context.dart';
import 'js_value.dart' show jsToNumber, jsToString;
import 'spec.dart' show VegaSpecException;
import 'transform_bar.dart' show kVegaDefaultTruncateChars;

/// The number of stops a quantitative heat-map colour scale carries
/// (`VegaLiteSchemaAdapter.ts:3465`).
const int _heatmapColorScaleSteps = 5;

/// `encoding.<channel>`, when it is an object.
Map<String, Object?>? _channel(Map<String, Object?> encoding, String name) {
  final definition = encoding[name];
  return definition is Map<String, Object?> ? definition : null;
}

/// Transforms a Vega-Lite `arc` spec into a donut chart
/// (`VegaLiteSchemaAdapter.ts:3244-3310`).
///
/// [spec] is mutated, for the reason [transformVegaToHeatmap] gives.
FluentDonutChart transformVegaToDonut(
  Map<String, Object?> spec,
  Map<String, String> colorMap, {
  required bool isDark,
}) {
  // `:3250`.
  final context = initializeTransformContext(spec);
  // `:3253`.
  final thetaField = context.thetaField;
  final colorField = context.colorField;

  if (thetaField == null) {
    // `:3256`, message verbatim.
    throw const VegaSpecException(
      'VegaLiteSchemaAdapter: Theta encoding is required for donut charts',
    );
  }

  // `:3263-3264`: only an OBJECT mark can carry a radius, so `mark: 'arc'`
  // always takes the 0. A `hole` on the Plotly side falls back to
  // `kMinDonutRadius` instead (`PlotlySchemaAdapter.ts:1356`); these two
  // defaults disagree deliberately.
  final mark = context.primarySpec['mark'];
  final markInnerRadius = mark is Map<String, Object?>
      ? mark['innerRadius']
      : null;
  final innerRadius = markInnerRadius is num ? markInnerRadius.toDouble() : 0.0;

  final chartData = <FluentChartDataPoint>[];
  final colorIndex = <String, int>{};

  for (final row in context.data) {
    final value = row[thetaField];
    // `:3272`: the colour value wins, and an absent one labels the slice with
    // its own magnitude. Upstream tests `!== undefined`, so an explicit JSON
    // null would be labelled `'null'` there; a missing key and a null are the
    // same absent value in this port, as they already are at `:1453`
    // (`context.dart:437`). // parity: VegaLiteSchemaAdapter.ts:3272
    final legend = colorField != null && row[colorField] != null
        ? jsToString(row[colorField])
        : jsToString(value);

    // `:3274`: `typeof value !== 'number'`, so a numeric STRING is dropped
    // rather than parsed.
    if (value is! num) continue;

    // `:3278-3280`: the index is assigned on FIRST sight of a legend, so two
    // slices sharing a legend share a colour.
    final index = colorIndex[legend] ??= colorIndex.length;

    chartData.add(
      FluentChartDataPoint(
        // `:3283-3284`.
        legend: legend,
        data: value.toDouble(),
        // `:3285-3294`: no explicit colour value and no mark colour, so the
        // scheme, the range and then the palette decide.
        color: parseCssColour(
          resolveVegaSeriesColour(
            legend,
            index,
            null,
            null,
            colorMap,
            isDark: isDark,
            colorScheme: context.colorScheme,
            colorRange: context.colorRange,
          ),
        ),
      ),
    );
  }

  // `:3298`.
  final titles = getVegaLiteTitles(spec);
  final width = spec['width'];
  final height = spec['height'];

  return FluentDonutChart(
    // `:3301-3304`.
    data: FluentChartData(chartTitle: titles.chartTitle, chartData: chartData),
    // `:3305`.
    innerRadius: innerRadius,
    // `:3306-3307`: a non-numeric width or height is dropped rather than
    // coerced.
    width: width is num ? width.toDouble() : null,
    height: height is num ? height.toDouble() : null,
    // NOT PORTED: `:3308` spreads `titles.titleStyles`, which
    // `getVegaLiteTitles` does not carry — the GAP its own doc comment records
    // (`common.dart:33-40`). A donut whose spec names a title font renders in
    // the theme default. // parity: VegaLiteSchemaAdapter.ts:3308
  );
}

/// Transforms a Vega-Lite `rect` spec into a heat map
/// (`VegaLiteSchemaAdapter.ts:3322-3519`).
///
/// [spec] is mutated: `initializeTransformContext` materialises a conditional
/// colour into the data rows. The clone that protects a caller's own object is
/// taken once by the widget (`internal/vega/spec.dart:63`), which is where
/// upstream's own single entry point is.
FluentHeatMapChart transformVegaToHeatmap(
  Map<String, Object?> spec,
  Map<String, String> colorMap, {
  required bool isDark,
}) {
  // `:3328`.
  final context = initializeTransformContext(spec);
  final encoding = context.encoding;
  // `:3331`.
  final xField = context.xField;
  final yField = context.yField;
  final colorField = context.colorField;

  if (xField == null || yField == null || colorField == null) {
    // `:3334`, message verbatim.
    throw const VegaSpecException(
      'VegaLiteSchemaAdapter: x, y, and color encodings are required for '
      'heatmap charts',
    );
  }

  final colorChannel = _channel(encoding, 'color');
  final colorType = colorChannel?['type'];
  // `:3342-3345`: a declared nominal or ordinal type, or ANY row whose colour
  // value is present and not a number. One string cell makes the whole scale
  // categorical.
  final isNominalColor =
      colorType == 'nominal' ||
      colorType == 'ordinal' ||
      context.data.any(
        (row) => row[colorField] != null && row[colorField] is! num,
      );
  final nominalColorMap = <String, int>{};

  var minValue = double.infinity;
  var maxValue = double.negativeInfinity;
  final cellValues = <String, double>{};
  final cellTexts = <String, Object>{};
  final xKeys = <String>{};
  final yKeys = <String>{};

  for (final row in context.data) {
    final xValue = row[xField];
    final yValue = row[yField];
    final colorValue = row[colorField];

    // `:3353`.
    if (isInvalidValue(xValue) ||
        isInvalidValue(yValue) ||
        isInvalidValue(colorValue)) {
      continue;
    }

    final double value;
    if (isNominalColor) {
      // `:3360-3364`: the category's first-seen position IS its value.
      value =
          (nominalColorMap[jsToString(colorValue)] ??= nominalColorMap.length)
              .toDouble();
    } else {
      // `:3366`: a non-number that survived the invalid-value filter — a bool,
      // say — becomes 0 rather than being dropped.
      value = colorValue is num ? colorValue.toDouble() : 0;
    }

    // `:3369-3370`.
    minValue = math.min(minValue, value);
    maxValue = math.max(maxValue, value);

    // `:3386-3387`, `:3393`: every key is stringified, so a numeric axis value
    // reaches the chart as a category. // parity: VegaLiteSchemaAdapter.ts:3386
    final xKey = jsToString(xValue);
    final yKey = jsToString(yValue);
    xKeys.add(xKey);
    yKeys.add(yKey);
    // `:3394-3395`: a later row silently replaces an earlier one on the same
    // cell.
    cellValues['$xKey|$yKey'] = value;
    // `:3376`: the nominal branch labels the cell with the category name and
    // the quantitative one with the number.
    cellTexts['$xKey|$yKey'] = isNominalColor ? jsToString(colorValue) : value;
  }

  if (cellValues.isEmpty) {
    // `:3381-3382`, message verbatim. Upstream counts the pushed points; an
    // empty point list and an empty cell map are the same condition, because
    // every point writes a cell.
    throw const VegaSpecException(
      'VegaLiteSchemaAdapter: Heatmap requires data points with x, y, and '
      'color values',
    );
  }

  var xValuesArray = xKeys.toList();
  final yValuesArray = yKeys.toList();

  // `:3404-3412`: a temporal or ORDINAL x whose first value parses as a date
  // sorts chronologically. `new Date('1')` is 2001 in JavaScript and
  // `DateTime.tryParse('1')` is null here, so an ordinal axis of bare numeric
  // strings sorts upstream and keeps its insertion order in this port —
  // the same divergence `context.dart:159` records for the `timeUnit` path,
  // and following it would mean reading a wall-clock field through a timezone
  // the spec never named. // parity: VegaLiteSchemaAdapter.ts:3407
  final xType = _channel(encoding, 'x')?['type'];
  if (xType == 'temporal' || xType == 'ordinal') {
    if (DateTime.tryParse(xValuesArray.first) != null) {
      // `:3410`: the comparator subtracts two timestamps, and an unparseable
      // one makes it NaN — which leaves the pair in place rather than ordering
      // it. `stableSort` says that with a 0 and keeps the insertion order the
      // JavaScript engine keeps.
      xValuesArray = stableSort<String>(xValuesArray, (a, b) {
        final left = DateTime.tryParse(a);
        final right = DateTime.tryParse(b);
        if (left == null || right == null) return 0;
        return left.compareTo(right);
      });
    }
  }

  // `:3414-3432`: y outer, x inner, so the grid is emitted row by row.
  final completeGrid = <FluentHeatMapChartDataPoint>[];
  for (final yVal in yValuesArray) {
    for (final xVal in xValuesArray) {
      final key = '$xVal|$yVal';
      // `:3417`.
      final value = cellValues[key] ?? 0;
      // `:3420`: a filled 0 does not move the extent, but a real 0 does.
      if (value != 0 || cellValues.containsKey(key)) {
        minValue = math.min(minValue, value);
        maxValue = math.max(maxValue, value);
      }
      completeGrid.add(
        FluentHeatMapChartDataPoint(
          // `:3426-3429`.
          x: xVal,
          y: yVal,
          value: value,
          rectText: cellTexts[key] ?? value,
        ),
      );
    }
  }

  // `:3434-3438`: one unnamed band holding the whole grid.
  final heatmapData = FluentHeatMapChartData(
    legend: '',
    data: completeGrid,
    value: 0,
  );

  // `:3440`.
  final titles = getVegaLiteTitles(spec);

  // `:3447-3448`. `FluentVegaTransformContext` carries the same pair.
  final colorScheme = context.colorScheme;
  final customRange = context.colorRange;

  final domainValues = <double>[];
  final rangeValues = <String>[];

  if (isNominalColor && nominalColorMap.isNotEmpty) {
    // `:3452-3453`.
    final numCategories = nominalColorMap.length;
    for (var i = 0; i < numCategories; i++) {
      domainValues.add(i.toDouble());
    }
    if (customRange != null && customRange.length >= numCategories) {
      // `:3455-3456`.
      rangeValues.addAll(customRange.take(numCategories));
    } else {
      // `:3459-3461`: the range is passed on as well, so a SHORT custom range
      // is cycled by `getVegaColor` rather than ignored.
      for (var i = 0; i < numCategories; i++) {
        rangeValues.add(
          getVegaColor(i, colorScheme, customRange, isDark: isDark),
        );
      }
    }
  } else {
    // `:3466-3469`.
    for (var i = 0; i < _heatmapColorScaleSteps; i++) {
      final t = i / (_heatmapColorScaleSteps - 1);
      domainValues.add(minValue + (maxValue - minValue) * t);
    }

    if (customRange != null && customRange.isNotEmpty) {
      // `:3471-3472`: a custom range wins outright, and a short one is taken
      // whole — so the range and the domain need not be the same length. The
      // chart draws what it is given, as upstream's does.
      // // parity: VegaLiteSchemaAdapter.ts:3472
      rangeValues.addAll(
        customRange.length >= _heatmapColorScaleSteps
            ? customRange.take(_heatmapColorScaleSteps)
            : customRange,
      );
    } else if (colorScheme != null && colorScheme.isNotEmpty) {
      // `:3474`: `getSequentialSchemeColors` answers a FRESH list, which is
      // what makes the in-place reverse below safe (`color_adapter.dart:236`).
      final schemeColors = getSequentialSchemeColors(
        colorScheme,
        steps: _heatmapColorScaleSteps,
      );
      if (schemeColors != null) {
        // `:3476-3477`: `sort` is read off the colour CHANNEL and `reverse`
        // off its scale, so either one flips the ramp.
        final isReversed =
            colorChannel?['sort'] == 'descending' ||
            (colorChannel?['scale'] is Map<String, Object?> &&
                (colorChannel!['scale']! as Map<String, Object?>)['reverse'] ==
                    true);
        rangeValues.addAll(isReversed ? schemeColors.reversed : schemeColors);
      }
    }

    // `:3483-3498`: the fallback fires when the scheme was unknown as well as
    // when none was named. Five stops at t = i / 4, emitted as CSS `rgb()`
    // strings upstream and as `Color` values here.
    if (rangeValues.isEmpty) {
      for (var i = 0; i < _heatmapColorScaleSteps; i++) {
        final t = i / (_heatmapColorScaleSteps - 1);
        // `:3487`, `:3492`: red climbs 0 to 255 in both themes.
        final r = d3.jsRound(255 * t);
        final g = isDark
            // `:3488`: 100 to 165, blue to orange.
            ? d3.jsRound(100 + (165 - 100) * t)
            // `:3493`: 150 to 0, blue to red.
            : d3.jsRound(150 - 150 * t);
        // `:3489`, `:3494`: blue falls 255 to 0 in both.
        final b = d3.jsRound(255 - 255 * t);
        rangeValues.add('rgb(${r.toInt()}, ${g.toInt()}, ${b.toInt()})');
      }
    }
  }

  // `:3515`: three rungs on the COLUMN count, and the middle two are the
  // narrow ones.
  final truncate = xValuesArray.length > 20
      ? 6
      : xValuesArray.length > 10
      ? 10
      : kVegaDefaultTruncateChars;

  return FluentHeatMapChart(
    // `:3503`: always exactly one band.
    data: <FluentHeatMapChartData>[heatmapData],
    // `:3504-3505`.
    domainValuesForColorScale: domainValues,
    rangeValuesForColorScale: <Color>[
      for (final colour in rangeValues) parseCssColour(colour),
    ],
    // `:3502`.
    chartTitle: titles.chartTitle,
    // `:3513` sends `sortOrder: 'none'` — the chart must not re-sort a grid
    // whose column order was just decided above. `HeatMapChart.tsx:648` reads
    // that as "leave the order alone", which is what `sortAlphabetically:
    // false` spells (`heat_map_chart.dart:667`).
    sortAlphabetically: false,
    // NOT PORTED: `:3509-3510`, `width` and `height ?? DEFAULT_CHART_HEIGHT`.
    // FluentHeatMapChart is a shell chart and takes its size from its
    // `BoxConstraints` (spec §2.2), so the 350 is applied by the declarative
    // widget as the cell's `SizedBox` — the same shape as
    // `kVegaStackedBarDefaultHeight`. Also NOT PORTED: `:3508`'s
    // `titleStyles`, the GAP `common.dart:33-40` records.
    // // parity: VegaLiteSchemaAdapter.ts:3510
    props: FluentCartesianChartProps(
      // `:3506-3507`.
      xAxisTitle: titles.xAxisTitle,
      yAxisTitle: titles.yAxisTitle,
      // `:3511`.
      hideLegend: true,
      // `:3512`.
      showYAxisLables: true,
      // `:3514`.
      hideTickOverlap: true,
      // `:3515`.
      noOfCharsToTruncate: truncate,
      // `:3516`.
      showYAxisLablesTooltip: true,
      // `:3517`.
      wrapXAxisLables: true,
    ),
  );
}

/// The line options a polar mark's properties imply
/// (`VegaLiteSchemaAdapter.ts:3794-3804`).
///
/// The same three keys, read the same way, as the line transformer's own
/// `_lineOptionsFrom` (`:1846-1855`, `transform_line.dart:362`). Copied rather
/// than shared: that one is private, and promoting it would make a public
/// symbol out of a helper with only private callers — the trade
/// `color_adapter.dart:120-125` already refuses for `_hex`.
///
/// Returns null when the mark declares none, because `:3812` and `:3821` spread
/// the object only once it has keys, and an empty `lineOptions` would otherwise
/// override the chart's own defaults.
FluentLineOptions? _polarLineOptions(
  FluentVegaMarkProperties markProps,
  FluentLineCurve? curve,
) {
  // `:3799-3800`: joined with a SPACE, and `Array.prototype.join` stringifies
  // `4` as `4` rather than Dart's `4.0`.
  final dash = markProps.strokeDash?.map(jsToString).join(' ');
  // `:3802`: `if (markProps.strokeWidth)`, so a width of 0 is treated as
  // absent.
  final width = markProps.strokeWidth == 0 ? null : markProps.strokeWidth;
  if (curve == null && dash == null && width == null) return null;
  return FluentLineOptions(
    strokeWidth: width,
    strokeDasharray: dash,
    curve: curve,
  );
}

/// Transforms a Vega-Lite spec with `theta` and `radius` encodings into a polar
/// chart (`VegaLiteSchemaAdapter.ts:3706-3861`).
///
/// [spec] is mutated, for the reason [transformVegaToHeatmap] gives.
FluentPolarChart transformVegaToPolar(
  Map<String, Object?> spec,
  Map<String, String> colorMap, {
  required bool isDark,
}) {
  // `:3712`.
  final context = initializeTransformContext(spec);
  // `:3715`.
  final thetaField = context.thetaField;
  final radiusField = context.radiusField;
  final colorField = context.colorField;

  if (thetaField == null || radiusField == null) {
    // `:3719`, message verbatim.
    throw const VegaSpecException(
      'VegaLiteSchemaAdapter: Both theta and radius encodings are required '
      'for polar charts',
    );
  }

  // `:3722-3723`.
  validateVegaDataArray(context.data, thetaField, 'PolarChart');
  validateVegaDataArray(context.data, radiusField, 'PolarChart');

  // `:3726-3730`: an `arc` with both polar channels is a rose chart, which is
  // an AREA series and not a pie — the one place the two arc readings diverge.
  final mark = context.primarySpec['mark'];
  final markType = mark is String
      ? mark
      : (mark is Map<String, Object?> ? mark['type'] : null);
  final isAreaMark = markType == 'area' || markType == 'arc';
  final isLineMark = markType == 'line';

  final seriesMap = <String, List<FluentPolarDataPoint>>{};
  final colorIndex = <String, int>{};

  for (final row in context.data) {
    final thetaValue = row[thetaField];
    final radiusValue = row[radiusField];

    // `:3745`.
    if (isInvalidValue(thetaValue) || isInvalidValue(radiusValue)) continue;

    // `:3749`: the literal `'default'`, which is also the legend a
    // single-series polar chart shows.
    final seriesName = colorField != null && row[colorField] != null
        ? jsToString(row[colorField])
        : 'default';
    // `:3751-3752`: assigned on first sight, so the palette follows the data
    // order.
    colorIndex[seriesName] ??= colorIndex.length;

    seriesMap
        .putIfAbsent(seriesName, () => <FluentPolarDataPoint>[])
        .add(
          FluentPolarDataPoint(
            // `:3770`: `Number(radiusValue)` for a non-number, so an
            // unparseable radius reaches the chart as NaN rather than being
            // dropped. // parity: VegaLiteSchemaAdapter.ts:3770
            r: radiusValue is num ? radiusValue : jsToNumber(radiusValue),
            // `:3761-3767`: a number is degrees, anything else a category.
            theta: thetaValue is num ? thetaValue : jsToString(thetaValue),
          ),
        );
  }

  // `:3792`: read once from the primary mark, so every series shares a curve.
  final curve = mapInterpolateToCurve(context.markProps.interpolate);
  final lineOptions = _polarLineOptions(context.markProps, curve);

  final polarData = <FluentPolarSeries>[];
  for (final entry in seriesMap.entries) {
    final seriesName = entry.key;
    // `:3782-3791`: the MARK colour is the second priority here, unlike the
    // donut which passes none.
    final colour = parseCssColour(
      resolveVegaSeriesColour(
        seriesName,
        colorIndex[seriesName]!,
        null,
        context.markProps.color,
        colorMap,
        isDark: isDark,
        colorScheme: context.colorScheme,
        colorRange: context.colorRange,
      ),
    );
    if (isAreaMark) {
      // `:3807-3813`.
      polarData.add(
        FluentAreaPolarSeries(
          legend: seriesName,
          color: colour,
          data: entry.value,
          lineOptions: lineOptions,
        ),
      );
    } else if (isLineMark) {
      // `:3816-3822`.
      polarData.add(
        FluentLinePolarSeries(
          legend: seriesName,
          color: colour,
          data: entry.value,
          lineOptions: lineOptions,
        ),
      );
    } else {
      // `:3826-3831`: a point mark, and every other mark, is a scatter — which
      // takes no line options at all.
      polarData.add(
        FluentScatterPolarSeries(
          legend: seriesName,
          color: colour,
          data: entry.value,
        ),
      );
    }
  }

  // `:3837`.
  final titles = getVegaLiteTitles(spec);

  // `:3844-3848`: a categorical theta names the wedge order outright. Upstream
  // casts the array into the category-order union without checking it; this
  // port has an arm for exactly that shape.
  final thetaType = _channel(context.encoding, 'theta')?['type'];
  final angularAxis = thetaType == 'nominal' || thetaType == 'ordinal'
      ? FluentPolarAxisConfig(
          categoryOrder: FluentAxisCategoryOrder.explicit(
            <String>{
              for (final row in context.data) jsToString(row[thetaField]),
            }.toList(),
          ),
        )
      // `:3841`: an empty object, which is every default.
      : const FluentPolarAxisConfig();

  final colorChannel = _channel(context.encoding, 'color');
  final legend = colorChannel?['legend'];
  final width = spec['width'];
  final height = spec['height'];

  return FluentPolarChart(
    // `:3852`.
    data: polarData,
    // `:3853`: spread only when truthy, so an empty title stays absent.
    chartTitle: (titles.chartTitle?.isEmpty ?? true) ? null : titles.chartTitle,
    // `:3855`.
    width: width is num ? width.toDouble() : null,
    // `:3856`: the only chart-level height default on the Vega side besides the
    // stacked bar's 350. FluentPolarChart is shell-free and takes it directly.
    height: height is num ? height.toDouble() : 400,
    // `:3857`: `?? false`, so only an explicit `disable` hides the legend.
    hideLegend: legend is Map<String, Object?> && legend['disable'] is bool
        ? legend['disable']! as bool
        : false,
    // `:3858`: an empty object, which is every default.
    radialAxis: const FluentPolarAxisConfig(),
    // `:3859`.
    angularAxis: angularAxis,
    // NOT PORTED: `:3854`'s `titleStyles`, the GAP `common.dart:33-40`
    // records. // parity: VegaLiteSchemaAdapter.ts:3854
  );
}
