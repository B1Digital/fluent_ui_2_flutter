/// The Plotly bar-family figure transformers.
///
/// Ports `PlotlySchemaAdapter.ts:1390-1608` (vertical stacked bar, which is
/// also the `fallback` route) and `:1610-1791` with `:1169-1243` (grouped
/// vertical bar). Internal to the package: nothing here is barrel-exported.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../axis/tick_format.dart';
import '../../cartesian/cartesian_chart_props.dart';
import '../../grouped_vertical_bar_chart.dart';
import '../../model/bar_data.dart';
import '../../model/chart_common.dart';
import '../../model/line_options.dart';
import '../../model/series_v2.dart';
import '../../vertical_stacked_bar_chart.dart';
import '../d3/color.dart' as d3;
import '../d3/format.dart' as d3;
import '../data_viz_palette.dart';
import 'annotations.dart';
import 'axis.dart';
import 'color_adapter.dart';
import 'common.dart';
import 'legends.dart';
import 'predicates.dart';

/// One group under construction, keyed by x while the traces are walked
/// (`PlotlySchemaAdapter.ts:1437-1441`).
typedef _Stack = ({
  List<FluentStackedBarDatum> bars,
  List<FluentStackedBarLineDatum> lines,
  Object xAxisPoint,
});

/// A resolved CSS colour string as a [Color].
///
/// **Deviation:** the plan names a public `parseCssColour` and assigns it to
/// task 17's `common.dart`; that task has not landed, so this is the same two
/// lines kept private here rather than a public symbol planted in another
/// task's file. `legends.dart` carries an identical private copy for the same
/// reason, and whoever lands `parseCssColour` deletes both.
///
/// Every string reaching it comes from [resolveColor], [extractColor] or
/// [applyOpacityHex8], all of which return `D3Rgb` output, so the unparseable
/// branch is defensive: it takes the first qualitative colour rather than
/// inventing a black swatch.
Color _parseCssColour(String colour, {required bool isDark}) {
  final rgb = d3.color(colour)?.rgb();
  if (rgb == null) return FluentDataVizPalette.next(0, isDark: isDark);
  int channel(double value) => value.isNaN ? 0 : value.round().clamp(0, 255);
  return Color.fromARGB(
    channel((rgb.a.isNaN ? 1.0 : rgb.a) * 255),
    channel(rgb.r),
    channel(rgb.g),
    channel(rgb.b),
  );
}

/// `Number(value)` (`PlotlySchemaAdapter.ts:1503`'s `yVal as number` cast,
/// which is a runtime coercion in the `Math.max` that consumes it).
///
/// A numeric string coerces, and anything else is `NaN` — which is exactly the
/// point of `:1503`, see the `// parity` note at its call site.
double _jsNumber(Object? value) {
  if (value is num) return value.toDouble();
  if (value is bool) return value ? 1 : 0;
  if (value == null) return 0;
  final text = '$value'.trim();
  // `Number('')` is 0 in JavaScript, not NaN.
  if (text.isEmpty) return 0;
  return double.tryParse(text) ?? double.nan;
}

/// The contiguous index ranges of [series] whose x and y are both plottable
/// (`PlotlySchemaAdapter.ts:3600-3630`).
///
/// Kept private because the plan gives `getValidXYRanges` no owner: task 24's
/// audit note records that it is "undefined anywhere in this plan" and that the
/// heatmap does not need it. Whoever declares it publicly deletes this.
///
/// [resolveX] is optional because `:1738` (the grouped transformer) omits it
/// where `:1425` supplies one — upstream's `typeof resolveX === 'function'`
/// guard at `:3615` is exactly this null check.
List<(int, int)> _validXYRanges(
  Map<String, Object?> series, [
  Object? Function(Object?)? resolveX,
]) {
  final x = series['x'];
  final y = series['y'];
  if (x is! List<Object?> || y is! List<Object?>) {
    // `:3605-3607`.
    return const <(int, int)>[];
  }
  final ranges = <(int, int)>[];
  var start = 0;
  var end = 0;
  for (; end < x.length; end++) {
    // `:3616` reads `series.y[end]` past the end of a shorter y column, which
    // is `undefined` and therefore invalid; the length guard here is the same
    // test spelt in Dart.
    final yValue = end < y.length ? y[end] : null;
    if (isInvalidValue(x[end]) ||
        (resolveX != null && isInvalidValue(resolveX(x[end]))) ||
        isInvalidValue(yValue)) {
      if (end - start > 0) {
        ranges.add((start, end));
      }
      start = end + 1;
    }
  }
  if (end - start > 0) {
    ranges.add((start, end));
  }
  return ranges;
}

/// Whether [series] is drawn against the right-hand y axis
/// (`PlotlySchemaAdapter.ts:300-302`).
bool _usesSecondaryYScale(
  Map<String, Object?> series,
  Map<String, Object?>? layout,
) {
  if (series['yaxis'] != 'y2') return false;
  final yaxis2 = layout?['yaxis2'];
  final declared = yaxis2 is Map<String, Object?> ? yaxis2 : null;
  return declared?['anchor'] == 'x' || declared?['side'] == 'right';
}

/// The secondary y axis title and bounds a figure declares
/// (`PlotlySchemaAdapter.ts:304-355`).
///
/// Both fields null is upstream's `return {}` at `:326-328`: no trace anchors
/// to `y2`, so nothing is injected and the shell keeps its own defaults.
({String? title, FluentSecondaryYScaleOptions? scaleOptions})
_getSecondaryYAxisValues(List<Object?> data, Map<String, Object?>? layout) {
  var containsSecondaryYAxis = false;
  double? yMinValue;
  double? yMaxValue;
  var allLineSeries = true;

  for (final entry in data) {
    if (entry is! Map<String, Object?>) continue;
    if (!_usesSecondaryYScale(entry, layout)) continue;
    containsSecondaryYAxis = true;

    final yValues = entry['y'];
    if (yValues is List<Object?> && yValues.isNotEmpty) {
      // `:316-317`: the LAST such trace wins, because both assignments
      // overwrite rather than accumulate. // parity
      final numbers = <double>[for (final v in yValues) _jsNumber(v)];
      yMinValue = numbers.reduce(math.min);
      yMaxValue = numbers.reduce(math.max);
    }

    // `:320-322`.
    if (entry['type'] != 'scatter' || isScatterAreaChart(entry)) {
      allLineSeries = false;
    }
  }

  if (!containsSecondaryYAxis) {
    return (title: null, scaleOptions: null);
  }

  if (!allLineSeries) {
    // `:330-337`: a bar on the secondary axis is measured from zero.
    yMinValue = yMinValue == null ? null : math.min(yMinValue, 0);
    yMaxValue = yMaxValue == null ? null : math.max(yMaxValue, 0);
  }
  final yaxis2 = layout?['yaxis2'];
  final range = yaxis2 is Map<String, Object?> ? yaxis2['range'] : null;
  if (range is List<Object?> && range.length >= 2) {
    // `:338-341`.
    yMinValue = _jsNumber(range[0]);
    yMaxValue = _jsNumber(range[1]);
  }

  return (
    // `:344-349`, which `getTitles` already reproduces including its null for
    // a missing title.
    title: getTitles(layout).secondaryYAxisTitle,
    // `:350-353`. The two shell defaults (0 and 100,
    // `cartesian_chart_props.dart:30-31`) stand in for upstream's `undefined`,
    // which `CartesianChart.tsx:344-345` reads as `|| 0` and `?? 100`.
    scaleOptions: FluentSecondaryYScaleOptions(
      yMinValue: yMinValue ?? 0,
      yMaxValue: yMaxValue ?? 100,
    ),
  );
}

/// The `template.layout.colorway` a figure declares, as strings.
List<String>? _colorway(Map<String, Object?>? layout) {
  final template = layout?['template'];
  final templateLayout = template is Map<String, Object?>
      ? template['layout']
      : null;
  final colorway = templateLayout is Map<String, Object?>
      ? templateLayout['colorway']
      : null;
  if (colorway is! List<Object?>) return null;
  return <String>[
    for (final entry in colorway)
      if (entry is String) entry,
  ];
}

/// Transforms a Plotly `bar` figure into a Fluent vertical stacked bar chart
/// (`PlotlySchemaAdapter.ts:1390-1608`).
///
/// This is also the `fallback` route's transformer, so every scatter trace that
/// cannot be drawn as a line lands here as a line overlay — that is what
/// [isFallback] switches on (upstream's `fallbackVSBC` at `:1396`).
///
/// The chart is returned bare, without the `SizedBox(height: 350)` this plan's
/// Step 3 block wrapped it in: the nine shell charts size to their
/// `BoxConstraints` (spec §2.2), and task 28 supplies the cell height from
/// `kPlotlyDefaultCellHeight`, whose `verticalStackedBar` entry is upstream's
/// `:1584` default.
FluentVerticalStackedBarChart transformPlotlyToVsbc(
  Map<String, Object?> input, {
  required bool isMultiPlot,
  required PlotlyColorMap colorMap,
  required FluentPlotlyColorway colorwayType,
  required bool isDark,
  bool isFallback = false,
}) {
  final rawData = input['data'];
  final data = rawData is List<Object?> ? rawData : const <Object?>[];
  final rawLayout = input['layout'];
  final layout = rawLayout is Map<String, Object?> ? rawLayout : null;
  final colorway = _colorway(layout);

  // `:1394`. Keyed by the x value's string form, which is what a JavaScript
  // object key is: `mapXToDataPoints[x]` collapses the number 1 and the string
  // '1' onto one group upstream, and onto one group here.
  final groups = <String, _Stack>{};

  // `:1399-1400`. // parity: a legitimate 0 is indistinguishable from "unset",
  // so an all-negative or all-positive stack is always drawn against a zero
  // baseline.
  var yMaxValue = 0.0;
  var yMinValue = 0.0;

  // `:1401`.
  final secondary = _getSecondaryYAxisValues(data, layout);
  // `:1402`.
  final legend = getLegendProps(data, layout, isMultiPlot: isMultiPlot);
  // `:1403`: threaded across traces, so a later trace with no numeric marker
  // colour keeps the previous trace's scale.
  String Function(double)? colorScale;
  // `:1405`.
  FluentPlotlyAxisObject? xAxisObject;
  for (final ax in getAxisObjects(data, layout)) {
    if (ax.letter == 'x') xAxisObject = ax;
  }
  final resolveXValue = getAxisValueResolver(getAxisType(data, xAxisObject));

  for (var index1 = 0; index1 < data.length; index1++) {
    final series = data[index1];
    if (series is! Map<String, Object?>) continue;

    // `:1407`.
    colorScale = createColorScale(layout, series, colorScale);
    final marker = series['marker'];
    final markerColor = marker is Map<String, Object?> ? marker['color'] : null;
    final line = series['line'];
    final lineColour = line is Map<String, Object?> ? line['color'] : null;

    // `:1409-1415` and `:1417-1423`: both extracted once per trace.
    final extractedBarColors = extractColor(
      colorway,
      colorwayType,
      markerColor,
      colorMap,
      isDark: isDark,
    );
    final extractedLineColors = extractColor(
      colorway,
      colorwayType,
      lineColour,
      colorMap,
      isDark: isDark,
    );

    // `:1425-1426`.
    final validRanges = _validXYRanges(series, resolveXValue);
    final xColumn = series['x']! as List<Object?>;
    final yColumn = series['y']! as List<Object?>;
    final text = series['text'];
    final texttemplate = series['texttemplate'];

    for (var rangeIdx = 0; rangeIdx < validRanges.length; rangeIdx++) {
      final (rangeStart, rangeEnd) = validRanges[rangeIdx];
      // `:1427-1428`.
      final rangeXValues = xColumn.sublist(rangeStart, rangeEnd);
      final rangeYValues = yColumn.sublist(rangeStart, rangeEnd);
      // `:1429-1433`: a list is sliced with the range, a bare string is shared
      // by every point, and anything else contributes no label.
      final textValues = text is List<Object?>
          ? text.sublist(rangeStart, rangeEnd)
          : (text is String ? text : null);

      for (var index2 = 0; index2 < rangeXValues.length; index2++) {
        final xValue = rangeXValues[index2];
        // `:1436-1442`.
        final group = groups.putIfAbsent(
          '$xValue',
          () => (
            bars: <FluentStackedBarDatum>[],
            lines: <FluentStackedBarLineDatum>[],
            xAxisPoint: resolveXValue(xValue)!,
          ),
        );

        // `:1443`.
        final legendTitle = index1 < legend.names.length
            ? legend.names[index1]
            : '';

        // `:1445-1461`.
        final String colour;
        if (colorScale != null) {
          final scaleInput =
              markerColor is List<Object?> && markerColor.isNotEmpty
              ? markerColor[index2 % markerColor.length]
              : 0;
          colour = colorScale(scaleInput is num ? scaleInput.toDouble() : 0);
        } else {
          colour = resolveColor(
            extractedBarColors,
            index2,
            legendTitle,
            colorMap,
            colorway,
            isDark: isDark,
          );
        }

        // `:1462`.
        final opacity = getOpacity(series, index2);
        // `:1463`.
        final yVal = rangeYValues[index2];

        // `:1465-1470`. `yAxisCalloutData` is deliberately absent: it comes
        // from `getFormattedCalloutYData` (`:253-261`), whose
        // `formatToLocaleString` has no owner in this plan and no landed port,
        // so the chart formats the raw value with its own locale instead.
        var barLabel = textValues is List<Object?>
            ? textValues[index2]
            : textValues;
        if (barLabel != null &&
            barLabel != '' &&
            barLabel != false &&
            texttemplate != null) {
          barLabel = formatTextWithTemplate(barLabel, texttemplate, index2);
        }

        if (series['type'] == 'bar') {
          // `:1472-1478`.
          group.bars.add(
            FluentStackedBarDatum(
              legend: legendTitle,
              // `:1474`: a string y is legal and makes the y axis a band
              // scale (`bar_data.dart:312-318`).
              data: yVal is num ? yVal.toDouble() : '$yVal',
              color: _parseCssColour(
                applyOpacityHex8(colour, opacity),
                isDark: isDark,
              ),
              barLabel: barLabel == null || barLabel == '' ? null : '$barLabel',
            ),
          );
          if (yVal is num) {
            // `:1480-1482`.
            yMaxValue = math.max(yMaxValue, yVal.toDouble());
          }
        } else if (series['type'] == 'scatter' || isFallback) {
          // `:1483-1490`: the LINE colour is indexed by the trace, not by the
          // point.
          final resolvedLineColour = resolveColor(
            extractedLineColors,
            index1,
            legendTitle,
            colorMap,
            colorway,
            isDark: isDark,
          );
          final mode = series['mode'];
          // `:1491`: a text mode drops the dash presets entirely.
          final lineOptions = mode is String && mode.contains('text')
              ? null
              : getLineOptions(line is Map<String, Object?> ? line : null);
          final usesSecondary = _usesSecondaryYScale(series, layout);
          group.lines.add(
            FluentStackedBarLineDatum(
              // `:1494`: a trace split into several valid ranges gets one
              // legend per range, suffixed from 1.
              legend:
                  legendTitle +
                  (validRanges.length > 1 ? '.${rangeIdx + 1}' : ''),
              legendShape: getLegendShape(series),
              y: yVal is num ? yVal.toDouble() : '$yVal',
              // `:1497`: the bar opacity, applied to the line colour.
              color: _parseCssColour(
                applyOpacityHex8(resolvedLineColour, opacity),
                isDark: isDark,
              ),
              // `:1498-1501`: `{...(lineOptions ?? {}), mode: series.mode}`.
              lineOptions: FluentLineOptions(
                strokeWidth: lineOptions?.strokeWidth,
                strokeDasharray: lineOptions?.strokeDasharray,
                strokeDashoffset: lineOptions?.strokeDashoffset,
                strokeLinecap: lineOptions?.strokeLinecap,
                lineBorderWidth: lineOptions?.lineBorderWidth,
                lineBorderColor: lineOptions?.lineBorderColor,
                curve: lineOptions?.curve,
                mode: mode is String ? FluentLineMode.parse(mode) : null,
                fill: lineOptions?.fill,
              ),
              useSecondaryYScale: usesSecondary,
            ),
          );
          if (!usesSecondary && yVal is num) {
            // `:1502-1505`.
            yMaxValue = math.max(yMaxValue, yVal.toDouble());
            yMinValue = math.min(yMinValue, yVal.toDouble());
          }
        }
        // `:1507`. // parity: `Math.max(yMaxValue, yVal as number)` runs for
        // EVERY point of EVERY trace type, including the ones the two branches
        // above skipped, and it coerces at runtime — so a non-numeric string y
        // poisons yMaxValue to NaN and the chart's whole y domain with it.
        yMaxValue = math.max(yMaxValue, _jsNumber(yVal));
      }
    }
  }

  final stacks = <FluentVerticalStackedBarGroup>[
    for (final group in groups.values)
      FluentVerticalStackedBarGroup(
        chartData: group.bars,
        xAxisPoint: group.xAxisPoint,
        lineData: group.lines,
      ),
  ];

  // `:1579`.
  final annotations = getChartAnnotationsFromLayout(
    layout,
    isMultiPlot: isMultiPlot,
  );
  // `:1599`.
  final titles = getTitles(layout);
  // `:1598` and `:1604`.
  final xRange = getXMinMaxValues(layout);
  final yRange = getYMinMaxValues(layout);
  // `:1602`, `:1603` and `:1605`.
  final categoryOrder = getAxisCategoryOrderProps(data, layout);
  final barProps = getBarProps(data, layout);
  final tickProps = getAxisTickProps(data, layout);
  // `:1601`: `getYAxisTickFormat` is `d3.format(layout.yaxis.tickformat)`
  // (`:211-220`).
  final yAxis = layout?['yaxis'];
  final tickformat = yAxis is Map<String, Object?> ? yAxis['tickformat'] : null;
  final yAxisTickFormat = tickformat is String && tickformat.isNotEmpty
      ? d3.format(tickformat)
      : null;

  return FluentVerticalStackedBarChart(
    data: stacks,
    // `:1599`.
    chartTitle: titles.chartTitle,
    // `:1585`, overwritten by `:1603` with the same literal when the layout
    // declares a bar geometry at all.
    barWidth: barProps.barWidth ?? 'auto',
    // `:1603`. The shell's own default is 24 (`VerticalStackedBarChart.tsx:90`).
    maxBarWidth: barProps.maxBarWidth ?? 24,
    xAxisInnerPadding: barProps.xAxisInnerPadding,
    xAxisOuterPadding: barProps.xAxisOuterPadding,
    // `:1591`.
    barGapMax: 2,
    // `:1593`.
    roundCorners: true,
    // `:1588`.
    mode: 'plotly',
    // `:1602`.
    xAxisCategoryOrder: categoryOrder.x ?? FluentAxisCategoryOrder.defaultOrder,
    yAxisCategoryOrder: categoryOrder.y ?? FluentAxisCategoryOrder.defaultOrder,
    props: FluentCartesianChartProps(
      xAxisTitle: titles.xAxisTitle,
      yAxisTitle: titles.yAxisTitle,
      // `:1589`.
      secondaryYAxisTitle: secondary.title,
      secondaryYScaleOptions: secondary.scaleOptions,
      // `:1592`.
      hideLegend: legend.hideLegend,
      // `:1590`.
      hideTickOverlap: true,
      // `:1586-1587` pass the seeds declared at `:1399-1400`; `:1604` spreads
      // getYMinMaxValues AFTER them, so a pinned `layout.yaxis.range` overrides
      // the seed and an absent one leaves it alone.
      yMaxValue: yRange.yMaxValue ?? yMaxValue,
      yMinValue: yRange.yMinValue ?? yMinValue,
      // `:1598`: getXMinMaxValues carries its own showRoundOffXTickValues.
      xMinValue: xRange.xMinValue,
      xMaxValue: xRange.xMaxValue,
      showRoundOffXTickValues: xRange.showRoundOffXTickValues,
      // `:1594`.
      showYAxisLables: true,
      // `:1595`.
      noOfCharsToTruncate: 20,
      // `:1596`.
      showYAxisLablesTooltip: true,
      // `:1597`.
      roundedTicks: true,
      // `:1601`.
      yAxisTickFormat: yAxisTickFormat,
      // `:1605`. Both counts are non-nullable with the shell's own defaults
      // (6 and 4, `cartesian_chart_props.dart:95-96`), so an absent `nticks`
      // keeps them.
      tickValues: tickProps.xAxisTickValues,
      yAxisTickValues: tickProps.yAxisTickValues,
      xAxisTickCount: tickProps.xAxisTickCount ?? 6,
      yAxisTickCount: tickProps.yAxisTickCount ?? 4,
      xAxis: FluentAxisConfig(
        tickStep: tickProps.xAxisTickStep,
        tick0: tickProps.xAxisTick0,
        tickText: tickProps.xAxisTickText,
        tickLayout: tickProps.xAxisTickLayout,
      ),
      yAxis: FluentAxisConfig(
        tickStep: tickProps.yAxisTickStep,
        tick0: tickProps.yAxisTick0,
        tickText: tickProps.yAxisTickText,
        tickLayout: tickProps.yAxisTickLayout,
      ),
      // `:1606`.
      annotations: annotations,
    ),
  );
}

/// The CSS-property key pattern at `PlotlySchemaAdapter.ts:501-507`.
///
/// Transcribed verbatim, including the bare `%` alternative and the vendor
/// prefixes, which are the second alternation group.
final RegExp _cssKeyPattern = RegExp(
  r'^(color|fill|stroke|border|background|font|shadow|outline|margin|padding'
  r'|gap|align|justify|display|flex|grid|'
  r'text|line|letter|word|vertical|horizontal|overflow|position|top|right'
  r'|bottom|left|zindex|z-index|opacity|'
  r'filter|clip|cursor|resize|transition|animation|transform|box|column|row'
  r'|direction|visibility|'
  r'content|width|height|aspect|image|user|pointer|caret|scroll|%)'
  r'|(-webkit-|-moz-|-ms-|-o-)',
  caseSensitive: false,
);

/// Whether [key] names styling rather than data
/// (`PlotlySchemaAdapter.ts:494-512`).
bool _shouldIgnoreKey(String key) {
  final lowerKey = key.toLowerCase();
  // `:495-497`. // parity: `lowerKey === 'style'` is unreachable behind
  // `includes('style')`, so the port keeps only the first test.
  if (lowerKey.contains('style')) return true;
  return _cssKeyPattern.hasMatch(lowerKey);
}

/// Splits an array of objects into one bar trace per numeric key
/// (`PlotlySchemaAdapter.ts:1169-1243`).
///
/// **Deviation from the plan:** its Step 1 calls this with a whole trace and
/// reads a `'__series__'` key off a `Map` return. Upstream returns
/// `{ traces, x }` and `:1625-1645` destructures `traces` to spread each entry
/// as a trace of its own, which a magic-keyed map cannot express, so the record
/// shape is kept.
///
/// **Deviation from upstream:** `:1193-1198` also accepts a primitive item —
/// a bare number becomes a one-key object, anything else contributes nothing.
/// The only call site is gated by `isObjectArray` (`:1629`), which demands
/// every item be an object, so those two arms are unreachable and are not
/// ported; the parameter type says so.
///
/// The numeric filter at `:1186-1191` parses once here where `:1218-1226`
/// re-tests the raw value. The set of surviving keys is identical, because both
/// gates are `isNumber`.
({List<Map<String, Object?>> traces, List<Object?> x})
normalizeObjectArrayForGvbc(
  List<Map<String, Object?>> data, [
  List<Object?>? xLabels,
]) {
  // `:1173-1175`.
  if (data.isEmpty) {
    return (traces: const <Map<String, Object?>>[], x: const <Object?>[]);
  }

  // `:1178`.
  final x = xLabels != null && xLabels.length == data.length
      ? xLabels
      : <Object?>[for (var i = 0; i < data.length; i++) 'Item ${i + 1}'];

  // `:1181-1200`.
  final flattened = <Map<String, double>>[
    for (final item in data)
      <String, double>{
        for (final entry in flattenObject(item).entries)
          if (!_shouldIgnoreKey(entry.key) && isPlotlyNumber(entry.value))
            entry.key: entry.value is num
                ? (entry.value! as num).toDouble()
                // `parseFloat` at `:1223`: a literal Dart cannot read is 0,
                // which is what `parseFloat('0x10')` returns too.
                : double.tryParse('${entry.value}') ?? 0,
      },
  ];

  // `:1203-1206`: first-seen key order, which is what a JavaScript `Set` and a
  // Dart `LinkedHashSet` both keep.
  final allKeys = <String>{for (final object in flattened) ...object.keys};

  final traces = <Map<String, Object?>>[];
  for (final key in allKeys) {
    // `:1216-1227`: a key absent from an object contributes NO entry, so a
    // ragged input yields a short y column rather than a hole. // parity
    final yValues = <double>[
      for (final object in flattened)
        if (object.containsKey(key)) object[key]!,
    ];
    // `:1230`.
    if (yValues.isNotEmpty) {
      // `:1231-1238`.
      traces.add(<String, Object?>{
        'type': 'bar',
        'name': key,
        'x': x,
        'y': yValues,
      });
    }
  }

  return (traces: traces, x: x);
}

/// `getFormattedCalloutYData` (`PlotlySchemaAdapter.ts:253-261`).
///
/// Task 18 left this out of the stacked transformer for want of a
/// `formatToLocaleString`; `axis/tick_format.dart:210` has since landed one, so
/// the grouped transformer calls it. The stacked transformer is another task's
/// file position and is left alone.
String _formattedCalloutYData(
  Object? yVal,
  String Function(double)? yAxisTickFormat,
) {
  // `:258`: the format is applied to a number only.
  if (yAxisTickFormat != null && yVal is num) {
    return yAxisTickFormat(yVal.toDouble());
  }
  return formatToLocaleString(yVal);
}

/// Transforms a Plotly grouped `bar` figure into a Fluent grouped vertical bar
/// chart (`PlotlySchemaAdapter.ts:1610-1791`).
///
/// The chart carries [FluentGroupedVerticalBarChart.dataV2] rather than
/// `data`: upstream fills `dataV2` too (`:1652` and `:1770`), and it is the
/// only input shape that carries the scatter overlay at `:1740-1763`. The
/// widget pivots it into one group per x value itself
/// (`GroupedVerticalBarChart.tsx:267-295`).
///
/// No `noOfCharsToTruncate` is injected. That is deliberate: `:1769-1789` has
/// no such entry where the stacked transformer's `:1595` sets 20, so the y
/// labels here keep the shell's own default rather than the stacked chart's.
///
/// As with the stacked transformer the chart is returned bare — the shell
/// charts size to their constraints (spec §2.2) and task 28 supplies `:1772`'s
/// 350 from `kPlotlyDefaultCellHeight`.
FluentGroupedVerticalBarChart transformPlotlyToGvbc(
  Map<String, Object?> input, {
  required bool isMultiPlot,
  required PlotlyColorMap colorMap,
  required FluentPlotlyColorway colorwayType,
  required bool isDark,
}) {
  final rawData = input['data'];
  final inputData = rawData is List<Object?> ? rawData : const <Object?>[];
  final rawLayout = input['layout'];
  // `:1618`: only `data` is replaced, so the processed layout the tail reads at
  // `:1781` and `:1784` is this same object.
  final layout = rawLayout is Map<String, Object?> ? rawLayout : null;
  final colorway = _colorway(layout);

  bool isObjectArrayBar(Object? series) =>
      series is Map<String, Object?> &&
      series['type'] == 'bar' &&
      isObjectArray(series['y']);

  // `:1621-1623`.
  final hasObjectArrayData = inputData.any(isObjectArrayBar);

  // `:1625-1645`.
  final data = <Object?>[];
  for (final entry in inputData) {
    if (hasObjectArrayData && isObjectArrayBar(entry)) {
      final series = entry! as Map<String, Object?>;
      final yObjects = (series['y']! as List<Object?>)
          .cast<Map<String, Object?>>();
      final xValues = series['x'];
      // `:1631-1634`.
      final normalised = normalizeObjectArrayForGvbc(
        yObjects,
        xValues is List<Object?> ? xValues : null,
      );
      for (final trace in normalised.traces) {
        // `:1637-1641`: the marker is copied onto every generated trace, and
        // an absent one is copied as absent.
        data.add(<String, Object?>{...trace, 'marker': series['marker']});
      }
    } else {
      data.add(entry);
    }
  }

  // `:1652`.
  final seriesV2 = <FluentDataSeries>[];
  // `:1653`.
  final secondary = _getSecondaryYAxisValues(data, layout);
  // `:1654`.
  final legend = getLegendProps(data, layout, isMultiPlot: isMultiPlot);
  // `:1656`: threaded across traces, exactly as in the stacked transformer.
  String Function(double)? colorScale;
  // `:1657`: `d3.format(layout.yaxis.tickformat)` (`:211-220`).
  final yAxis = layout?['yaxis'];
  final tickformat = yAxis is Map<String, Object?> ? yAxis['tickformat'] : null;
  final yAxisTickFormat = tickformat is String && tickformat.isNotEmpty
      ? d3.format(tickformat)
      : null;

  for (var index1 = 0; index1 < data.length; index1++) {
    final series = data[index1];
    if (series is! Map<String, Object?>) continue;

    // `:1659`.
    colorScale = createColorScale(layout, series, colorScale);
    // `:1660`.
    final legendTitle = index1 < legend.names.length
        ? legend.names[index1]
        : '';
    // `:1661`.
    final legendShape = getLegendShape(series);
    final marker = series['marker'];
    final markerColor = marker is Map<String, Object?> ? marker['color'] : null;
    final line = series['line'];
    final lineColour = line is Map<String, Object?> ? line['color'] : null;
    // `:1717`.
    final usesSecondary = _usesSecondaryYScale(series, layout);

    if (series['type'] == 'bar') {
      // `:1665-1671`: extracted once per trace.
      final extractedBarColors = extractColor(
        colorway,
        colorwayType,
        markerColor,
        colorMap,
        isDark: isDark,
      );

      final xColumn = series['x'];
      final yColumn = series['y'];
      final text = series['text'];
      final texttemplate = series['texttemplate'];
      final points = <FluentDataPointV2>[];
      // `:1677`'s `series.x as Datum[]` throws on a trace with no x column;
      // the guard is what stands in for that, because a figure that far off
      // spec is rejected by the router long before it reaches here.
      if (xColumn is List<Object?>) {
        for (var xIndex = 0; xIndex < xColumn.length; xIndex++) {
          final xValue = xColumn[xIndex];
          final yValue = yColumn is List<Object?> && xIndex < yColumn.length
              ? yColumn[xIndex]
              : null;
          // `:1679-1681`: the point is dropped, and `:1716` filters it out.
          if (isInvalidValue(xValue) || isInvalidValue(yValue)) continue;

          // `:1683-1697`.
          final String colour;
          if (colorScale != null) {
            final scaleInput =
                markerColor is List<Object?> && markerColor.isNotEmpty
                ? markerColor[xIndex % markerColor.length]
                : 0;
            colour = colorScale(scaleInput is num ? scaleInput.toDouble() : 0);
          } else {
            colour = resolveColor(
              extractedBarColors,
              xIndex,
              legendTitle,
              colorMap,
              colorway,
              isDark: isDark,
            );
          }
          // `:1698`.
          final opacity = getOpacity(series, xIndex);

          // `:1701-1706`.
          var barLabel = text is List<Object?> && xIndex < text.length
              ? text[xIndex]
              : (text is List<Object?> ? null : text);
          if (barLabel != null &&
              barLabel != '' &&
              barLabel != false &&
              texttemplate != null) {
            barLabel = formatTextWithTemplate(barLabel, texttemplate, xIndex);
          }

          points.add(
            FluentDataPointV2(
              // `:1709`.
              x: '$xValue',
              // `:1710`: a string y is legal at the type level and the pivot
              // at `GroupedVerticalBarChart.tsx:281` reads it as 0.
              y: yValue is num ? yValue.toDouble() : '$yValue',
              // `:1711`.
              yAxisCalloutData: _formattedCalloutYData(yValue, yAxisTickFormat),
              // `:1712`.
              color: _parseCssColour(
                applyOpacityHex8(colour, opacity),
                isDark: isDark,
              ),
              // `:1713` writes `barLabel`, which `DataPointV2`
              // (`types/DataPoint.ts:1134-1179`) does not declare and
              // `_processDataV2` (`.tsx:279-287`) does not copy, so upstream
              // computes a label no bar ever draws. `text` is the nearest
              // declared field and is dropped by the same pivot, so the
              // computation stays live and the outcome is unchanged.
              // parity
              text: barLabel == null || barLabel == '' ? null : '$barLabel',
            ),
          );
        }
      }

      seriesV2.add(
        FluentBarSeries(
          // `:1675-1676`.
          legend: legendTitle,
          key: legendTitle,
          data: points,
          // `:1717`.
          useSecondaryYScale: usesSecondary,
        ),
      );
    } else if (series['type'] == 'scatter') {
      // `:1721-1727`.
      final extractedLineColors = extractColor(
        colorway,
        colorwayType,
        lineColour,
        colorMap,
        isDark: isDark,
      );
      // `:1728-1735`: the LINE colour is indexed by the trace, not by the point.
      final resolvedLineColour = resolveColor(
        extractedLineColors,
        index1,
        legendTitle,
        colorMap,
        colorway,
        isDark: isDark,
      );
      // `:1736`. // parity: unlike the stacked transformer at `:1491` this one
      // keeps the dash presets whatever the mode is.
      final lineOptions = getLineOptions(
        line is Map<String, Object?> ? line : null,
      );
      // `:1737`: also indexed by the trace.
      final opacity = getOpacity(series, index1);
      final mode = series['mode'];
      // `:1738`: no resolver, so only the raw x and y are tested.
      final validRanges = _validXYRanges(series);
      final xColumn = series['x'];
      final yColumn = series['y'];

      for (final (rangeStart, rangeEnd) in validRanges) {
        // `:1741-1742`.
        final rangeXValues = (xColumn! as List<Object?>).sublist(
          rangeStart,
          rangeEnd,
        );
        final rangeYValues = (yColumn! as List<Object?>).sublist(
          rangeStart,
          rangeEnd,
        );
        seriesV2.add(
          FluentLineSeries(
            // `:1746`. // parity: a trace split into several ranges yields
            // several series under ONE legend name, where the stacked
            // transformer suffixes them at `:1494`.
            legend: legendTitle,
            // `:1747`.
            legendShape: legendShape,
            // `:1748-1755`.
            data: <FluentDataPointV2>[
              for (var i = 0; i < rangeXValues.length; i++)
                FluentDataPointV2(
                  x: '${rangeXValues[i]}',
                  y: rangeYValues[i] is num
                      ? (rangeYValues[i]! as num).toDouble()
                      : '${rangeYValues[i]}',
                  yAxisCalloutData: _formattedCalloutYData(
                    rangeYValues[i],
                    yAxisTickFormat,
                  ),
                ),
            ],
            // `:1756`.
            color: _parseCssColour(
              applyOpacityHex8(resolvedLineColour, opacity),
              isDark: isDark,
            ),
            // `:1757-1760`: `{...(lineOptions ?? {}), mode: series.mode}`.
            lineOptions: FluentLineOptions(
              strokeWidth: lineOptions?.strokeWidth,
              strokeDasharray: lineOptions?.strokeDasharray,
              strokeDashoffset: lineOptions?.strokeDashoffset,
              strokeLinecap: lineOptions?.strokeLinecap,
              lineBorderWidth: lineOptions?.lineBorderWidth,
              lineBorderColor: lineOptions?.lineBorderColor,
              curve: lineOptions?.curve,
              mode: mode is String ? FluentLineMode.parse(mode) : null,
              fill: lineOptions?.fill,
            ),
            // `:1761`.
            useSecondaryYScale: usesSecondary,
          ),
        );
      }
    }
  }

  // `:1767`.
  final annotations = getChartAnnotationsFromLayout(
    layout,
    isMultiPlot: isMultiPlot,
  );
  // `:1782`.
  final titles = getTitles(layout);
  // `:1781` and `:1784`. Absent ranges leave the shell defaults (0/0 for y,
  // null for x, true for the round-off) exactly as upstream's empty spread
  // does — this transformer seeds no y bounds of its own, so the range is the
  // only source there.
  final xRange = getXMinMaxValues(layout);
  final yRange = getYMinMaxValues(layout);
  // `:1783`, `:1787` and `:1788`.
  final categoryOrder = getAxisCategoryOrderProps(data, layout);
  final barProps = getBarProps(data, layout);
  final tickProps = getAxisTickProps(data, layout);

  return FluentGroupedVerticalBarChart(
    dataV2: seriesV2,
    // `:1782`.
    chartTitle: titles.chartTitle,
    // `:1773`, overwritten by `:1787` with the same literal when the layout
    // declares a bar geometry at all.
    barWidth: barProps.barWidth ?? 'auto',
    // `:1787`. The shell's own default is 24
    // (`GroupedVerticalBarChart.tsx:80`).
    maxBarWidth: barProps.maxBarWidth ?? 24,
    xAxisInnerPadding: barProps.xAxisInnerPadding,
    xAxisOuterPadding: barProps.xAxisOuterPadding,
    // `:1774`.
    mode: 'plotly',
    // `:1778`.
    roundCorners: true,
    // `:1783`. Only the x order is declared: the grouped chart's x axis is the
    // only categorical one it has.
    xAxisCategoryOrder: categoryOrder.x ?? FluentAxisCategoryOrder.defaultOrder,
    props: FluentCartesianChartProps(
      xAxisTitle: titles.xAxisTitle,
      yAxisTitle: titles.yAxisTitle,
      // `:1775`.
      secondaryYAxisTitle: secondary.title,
      secondaryYScaleOptions: secondary.scaleOptions,
      // `:1777`.
      hideLegend: legend.hideLegend,
      // `:1776`.
      hideTickOverlap: true,
      // `:1779`.
      showYAxisLables: true,
      // `:1780`.
      roundedTicks: true,
      // `:1781`.
      xMinValue: xRange.xMinValue,
      xMaxValue: xRange.xMaxValue,
      showRoundOffXTickValues: xRange.showRoundOffXTickValues,
      // `:1784`.
      yMinValue: yRange.yMinValue ?? 0,
      yMaxValue: yRange.yMaxValue ?? 0,
      // `:1786`.
      yAxisTickFormat: yAxisTickFormat,
      // `:1788`. Both counts are non-nullable with the shell's own defaults
      // (6 and 4, `cartesian_chart_props.dart:95-96`), so an absent `nticks`
      // keeps them.
      tickValues: tickProps.xAxisTickValues,
      yAxisTickValues: tickProps.yAxisTickValues,
      xAxisTickCount: tickProps.xAxisTickCount ?? 6,
      yAxisTickCount: tickProps.yAxisTickCount ?? 4,
      xAxis: FluentAxisConfig(
        tickStep: tickProps.xAxisTickStep,
        tick0: tickProps.xAxisTick0,
        tickText: tickProps.xAxisTickText,
        tickLayout: tickProps.xAxisTickLayout,
      ),
      yAxis: FluentAxisConfig(
        tickStep: tickProps.yAxisTickStep,
        tick0: tickProps.yAxisTick0,
        tickText: tickProps.yAxisTickText,
        tickLayout: tickProps.yAxisTickLayout,
      ),
      // `:1789`.
      annotations: annotations,
    ),
  );
}
