/// The Plotly scatter-trace core, and the heatmap transformer.
///
/// Ports `PlotlySchemaAdapter.ts:1908-2212`: one shared body (`:1979-2212`)
/// behind three thin wrappers (`:1908`, `:1925`, `:1942`) plus
/// `mapColorFillBars` (`:1959-1977`). Upstream builds line, area **and**
/// scatter traces from that single body and returns the result `as
/// LineChartProps` / `as AreaChartProps` / `as ScatterChartProps`; this file is
/// the typed spelling of those three casts.
///
/// It also ports `:2397-2621`, the heatmap and `histogram2d` transformer —
/// the largest single transformer upstream has, and the only one that builds a
/// colour-scale domain and range out of its own data.
///
/// It is also the producer of the `scatterpolar` mode literal and of the four
/// polar members `FluentPolarLineOptions` carries — `line_chart.dart:825` and
/// `scatter_chart.dart:452` read the first, `line_chart.dart:1077` and
/// `scatter_chart.dart:471` read the second.
///
/// Internal to the package: nothing here is barrel-exported.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../area_chart.dart';
import '../../axis/axis_types.dart';
import '../../axis/domain_range.dart';
import '../../axis/tick_format.dart';
import '../../cartesian/cartesian_chart_props.dart';
import '../../chrome/legend_shape.dart';
import '../../heat_map_chart.dart';
import '../../line_chart.dart';
import '../../model/cartesian_series.dart';
import '../../model/chart_common.dart';
import '../../model/heatmap_data.dart';
import '../../model/line_options.dart';
import '../../model/polar_data.dart';
import '../../scatter_chart.dart';
import '../d3/bin.dart' as d3;
import '../d3/format.dart' as d3;
import '../data_viz_palette.dart';
import 'annotations.dart';
import 'axis.dart';
import 'bins.dart';
import 'color_adapter.dart';
import 'common.dart';
import 'legends.dart';
import 'predicates.dart';
import 'transform_bar.dart' show getNumberAtIndexOrDefault;

/// Which of the three wrappers is asking (`PlotlySchemaAdapter.ts:1982`).
enum _ScatterKind {
  /// `transformPlotlyJsonToLineChartProps` (`PlotlySchemaAdapter.ts:1925`).
  line,

  /// `transformPlotlyJsonToAreaChartProps` (`PlotlySchemaAdapter.ts:1908`).
  area,

  /// `transformPlotlyJsonToScatterChartProps` (`PlotlySchemaAdapter.ts:1942`).
  scatter,
}

/// The eight modes that make a trace marker-coloured rather than line-coloured
/// (`PlotlySchemaAdapter.ts:1988-1996`).
const Set<String> _kScatterMarkerModes = <String>{
  'text',
  'markers',
  'text+markers',
  'markers+text',
  'lines+markers',
  'markers+line',
  'text+lines+markers',
  'lines+markers+text',
};

/// The index ranges of contiguous valid `(x, y)` pairs in a trace
/// (`PlotlySchemaAdapter.ts:3600-3630`).
///
/// Each range is a half-open `[start, end)`. A gap is any index where either
/// column is invalid, or where the axis resolver rejects it — which is how a
/// line chart breaks its path instead of drawing through a hole.
///
/// Plan 09 task 24 asks for this at the head of this file, so that the heatmap
/// transformer can reach it without a second copy.
List<(int, int)> getValidXYRanges(
  Map<String, Object?> series, [
  Object? Function(Object?)? resolveX,
  Object? Function(Object?)? resolveY,
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
    final xVal = x[end];
    final yVal = end < y.length ? y[end] : null;
    // `:3613-3618`. Note the y column is indexed with the x loop bound, so a
    // shorter y reads past its end and yields undefined — which is invalid, so
    // the range simply closes there. // parity: PlotlySchemaAdapter.ts:3616
    if (isInvalidValue(xVal) ||
        (resolveX != null && isInvalidValue(resolveX(xVal))) ||
        isInvalidValue(yVal) ||
        (resolveY != null && isInvalidValue(resolveY(yVal)))) {
      if (end - start > 0) {
        ranges.add((start, end));
      }
      start = end + 1;
    }
  }
  // `:3625-3627`.
  if (end - start > 0) {
    ranges.add((start, end));
  }
  return ranges;
}

/// The shaded x bands a layout's `rect` shapes describe
/// (`PlotlySchemaAdapter.ts:1959-1977`).
///
/// **Signature deviation, and the reason for it:** this plan declares
/// `List<FluentColorFillBar>`, but upstream maps a rect with a string edge to
/// `null` (`:1967-1970`) and the caller then drops the **whole** list when it
/// holds one (`:2208`, `bars && !bars.includes(null)`). A non-nullable list
/// cannot carry that signal, and silently keeping the numeric bars would draw
/// bands upstream does not. Null therefore means "a rect was unusable, inject
/// nothing"; an empty list means "no rect shapes at all", which upstream also
/// spreads as `colorFillBars: []`.
List<FluentColorFillBar>? mapColorFillBars(Map<String, Object?>? layout) {
  final shapes = layout?['shapes'];
  if (shapes is! List<Object?>) {
    // `:1960-1962`.
    return const <FluentColorFillBar>[];
  }

  final bars = <FluentColorFillBar>[];
  for (final shape in shapes) {
    if (shape is! Map<String, Object?> || shape['type'] != 'rect') {
      continue;
    }
    final x0 = shape['x0'];
    final x1 = shape['x1'];
    // `:1967-1970`: colorFillBars support neither string dates nor categories.
    if (x0 is String || x1 is String || x0 == null || x1 == null) {
      return null;
    }
    final fill = shape['fillcolor'];
    bars.add(
      FluentColorFillBar(
        // Upstream's object literal declares no `legend`, so the `as` cast at
        // `:2208` lands an `undefined` on a `legend: string` field
        // (`LineChart.types.ts:137`). The empty string is the Dart spelling of
        // that. // parity: PlotlySchemaAdapter.ts:1971-1975
        legend: '',
        // `:1972`. An absent fillcolor reaches `rgb(undefined!)` upstream,
        // whose NaN channels clamp to zero when formatted
        // (`d3-color/src/color.js:292-294`).
        color: fill is String ? parseCssColour(fill) : const Color(0xFF000000),
        data: <FluentColorFillBarRange>[
          FluentColorFillBarRange(startX: x0, endX: x1),
        ],
        // `:1974`.
        applyPattern: false,
      ),
    );
  }
  return bars;
}

/// Transforms a Plotly scatter figure into a Fluent line chart
/// (`PlotlySchemaAdapter.ts:1925-1940`).
FluentLineChart transformPlotlyToLine(
  Map<String, Object?> input, {
  required bool isMultiPlot,
  required PlotlyColorMap colorMap,
  required FluentPlotlyColorway colorwayType,
  required bool isDark,
}) {
  final result = _transformScatterTrace(
    input,
    _ScatterKind.line,
    isMultiPlot: isMultiPlot,
    colorMap: colorMap,
    colorwayType: colorwayType,
    isDark: isDark,
  );
  return FluentLineChart(
    data: result.data,
    props: result.props,
    // `:2176`. `FluentCartesianChartProps` has no such field — the flag is a
    // LineChart parameter (`line_chart.dart:49`) and neither AreaChart nor
    // ScatterChart declares one, so this is the only wrapper that can pass it.
    optimizeLargeData: result.optimizeLargeData,
    colorFillBars: result.colorFillBars ?? const <FluentColorFillBar>[],
  );
}

/// Transforms a Plotly scatter figure into a Fluent area chart
/// (`PlotlySchemaAdapter.ts:1908-1923`).
FluentAreaChart transformPlotlyToArea(
  Map<String, Object?> input, {
  required bool isMultiPlot,
  required PlotlyColorMap colorMap,
  required FluentPlotlyColorway colorwayType,
  required bool isDark,
}) {
  final result = _transformScatterTrace(
    input,
    _ScatterKind.area,
    isMultiPlot: isMultiPlot,
    colorMap: colorMap,
    colorwayType: colorwayType,
    isDark: isDark,
  );
  return FluentAreaChart(
    data: result.data,
    props: result.props,
    // `:2191`, the one member the area branch adds to commonProps.
    mode: result.mode,
  );
}

/// Transforms a Plotly scatter figure into a Fluent scatter chart
/// (`PlotlySchemaAdapter.ts:1942-1957`).
FluentScatterChart transformPlotlyToScatter(
  Map<String, Object?> input, {
  required bool isMultiPlot,
  required PlotlyColorMap colorMap,
  required FluentPlotlyColorway colorwayType,
  required bool isDark,
}) {
  final result = _transformScatterTrace(
    input,
    _ScatterKind.scatter,
    isMultiPlot: isMultiPlot,
    colorMap: colorMap,
    colorwayType: colorwayType,
    isDark: isDark,
  );
  return FluentScatterChart(data: result.data, props: result.props);
}

/// One built series, before it is materialised as a line or a scatter series.
///
/// Upstream has one `LineChartPoints[]` and casts it to `ScatterChartPoints[]`
/// on the scatter branch (`:2162-2164`). The two Fluent series types are
/// distinct classes, so the shared body builds this and each branch
/// materialises it.
class _Series {
  const _Series({
    required this.legend,
    required this.points,
    required this.color,
    required this.useSecondaryYScale,
    this.legendShape,
    this.lineOptions,
    this.polarLineOptions,
  });

  final String legend;
  final List<_Point> points;
  final Color color;
  final bool useSecondaryYScale;
  final FluentChartLegendShape? legendShape;
  final FluentLineOptions? lineOptions;
  final FluentPolarLineOptions? polarLineOptions;
}

/// One built point (`PlotlySchemaAdapter.ts:2041-2070`).
class _Point {
  const _Point({
    required this.x,
    required this.y,
    this.text,
    this.markerColor,
    this.markerSize,
    this.calloutText,
  });

  final Object x;
  final Object y;
  final String? text;
  final Color? markerColor;
  final double? markerSize;
  final String? calloutText;
}

/// Materialises the built series as line series.
///
/// A point whose x or y is neither a number nor a date takes the
/// `FluentScatterChartDataPoint` arm of `FluentLineChartSeries.data`, which is
/// upstream's `LineChartDataPoint[] | ScatterChartDataPoint[]`
/// (`types/DataPoint.ts:492`): a category x reaches a `LineChartPoints` datum
/// at `:2055` even though `types/DataPoint.ts:340` types it `number | Date`.
List<FluentLineChartSeries> _asLineSeries(List<_Series> series) =>
    <FluentLineChartSeries>[
      for (final entry in series)
        FluentLineChartSeries(
          legend: entry.legend,
          legendShape: entry.legendShape,
          color: entry.color,
          lineOptions: entry.lineOptions,
          polarLineOptions: entry.polarLineOptions,
          useSecondaryYScale: entry.useSecondaryYScale,
          data: <Object>[
            for (final point in entry.points)
              if (point.y is num && (point.x is num || point.x is DateTime))
                FluentLineChartDataPoint(
                  x: point.x,
                  y: (point.y as num).toDouble(),
                  text: point.text,
                  markerColor: point.markerColor,
                  markerSize: point.markerSize,
                  yAxisCalloutText: point.calloutText,
                )
              else
                _scatterPoint(point),
          ],
        ),
    ];

/// Materialises the built series as scatter series (`:2162-2164`).
List<FluentScatterChartSeries> _asScatterSeries(List<_Series> series) =>
    <FluentScatterChartSeries>[
      for (final entry in series)
        FluentScatterChartSeries(
          legend: entry.legend,
          legendShape: entry.legendShape,
          color: entry.color,
          lineOptions: entry.lineOptions,
          polarLineOptions: entry.polarLineOptions,
          useSecondaryYScale: entry.useSecondaryYScale,
          data: <FluentScatterChartDataPoint>[
            for (final point in entry.points) _scatterPoint(point),
          ],
        ),
    ];

/// One scatter datum. A y that is neither a number nor a string is stringified
/// rather than dropped, because `FluentScatterChartDataPoint` admits exactly
/// those two (`model/cartesian_series.dart:104-109`) and upstream would carry
/// the raw value onto a band axis.
FluentScatterChartDataPoint _scatterPoint(_Point point) =>
    FluentScatterChartDataPoint(
      x: point.x,
      y: point.y is num || point.y is String ? point.y : '${point.y}',
      text: point.text,
      markerColor: point.markerColor,
      markerSize: point.markerSize,
      yAxisCalloutText: point.calloutText,
    );

/// Whether a trace is drawn against the secondary y scale
/// (`PlotlySchemaAdapter.ts:300-302`).
bool _usesSecondaryYScale(
  Map<String, Object?> series,
  Map<String, Object?>? layout,
) {
  if (series['yaxis'] != 'y2') {
    return false;
  }
  final yaxis2 = layout?['yaxis2'];
  final axis = yaxis2 is Map<String, Object?> ? yaxis2 : null;
  return axis?['anchor'] == 'x' || axis?['side'] == 'right';
}

/// The secondary y axis title and bounds (`PlotlySchemaAdapter.ts:304-355`).
///
/// **Deviation from this plan's file layout, not from upstream:** plan 09 task
/// 18 names `getSecondaryYAxisValues` among its consumers but gives it no home
/// file, and the only landed axis helpers are `getXMinMaxValues` /
/// `getYMinMaxValues`. It is kept private here rather than planted as a public
/// symbol in `axis.dart`, which task 13 owns; whoever hoists it deletes this.
({String? title, FluentSecondaryYScaleOptions? scaleOptions})
_secondaryYAxisValues(List<Object?> data, Map<String, Object?>? layout) {
  var containsSecondaryYAxis = false;
  double? yMinValue;
  double? yMaxValue;
  var allLineSeries = true;

  for (final entry in data) {
    if (entry is! Map<String, Object?> ||
        !_usesSecondaryYScale(entry, layout)) {
      continue;
    }
    containsSecondaryYAxis = true;
    final yValues = entry['y'];
    if (yValues is List<Object?>) {
      // `:316-317`: each secondary trace OVERWRITES the bounds, so the last one
      // read wins rather than the extent accumulating over all of them.
      // // parity: PlotlySchemaAdapter.ts:316
      final numbers = <double>[
        for (final value in yValues)
          if (value is num) value.toDouble(),
      ];
      if (numbers.isNotEmpty) {
        yMinValue = numbers.reduce((a, b) => a < b ? a : b);
        yMaxValue = numbers.reduce((a, b) => a > b ? a : b);
      }
    }
    // `:320-322`.
    if (entry['type'] != 'scatter' || isScatterAreaChart(entry)) {
      allLineSeries = false;
    }
  }

  if (!containsSecondaryYAxis) {
    // `:326-328`.
    return (title: null, scaleOptions: null);
  }

  if (!allLineSeries) {
    // `:330-337`: a bar or an area on the secondary axis must include zero.
    if (yMinValue != null && yMinValue > 0) {
      yMinValue = 0;
    }
    if (yMaxValue != null && yMaxValue < 0) {
      yMaxValue = 0;
    }
  }

  final yaxis2 = layout?['yaxis2'];
  final axis = yaxis2 is Map<String, Object?> ? yaxis2 : null;
  final range = axis?['range'];
  if (range is List<Object?> && range.length >= 2) {
    // `:338-341`: a pinned range wins outright.
    final start = range[0];
    final end = range[1];
    yMinValue = start is num ? start.toDouble() : yMinValue;
    yMaxValue = end is num ? end.toDouble() : yMaxValue;
  }

  final title = axis?['title'];
  return (
    // `:344-349`.
    title: title is String
        ? title
        : title is Map<String, Object?> && title['text'] is String
        ? title['text']! as String
        : null,
    // `:350-353`. The two fallbacks are the shell's own reads of an undefined
    // bound: `|| 0` and `?? 100` (`CartesianChart.tsx:344-345`).
    scaleOptions: FluentSecondaryYScaleOptions(
      yMinValue: yMinValue ?? 0,
      yMaxValue: yMaxValue ?? 100,
    ),
  );
}

/// The y-axis number formatter a layout declares
/// (`PlotlySchemaAdapter.ts:211-221`).
///
/// **Hardening deviation:** upstream calls `d3Format(spec)` unguarded, so an
/// author typo throws out of the transformer and takes the whole figure with
/// it. An invalid specifier here leaves the axis unformatted instead. This is
/// author-supplied JSON, not a trust boundary, so the change is crash
/// avoidance rather than a security fix — but the upstream behaviour has no
/// value worth reproducing.
String Function(double)? _yAxisTickFormat(Map<String, Object?>? layout) {
  final yaxis = layout?['yaxis'];
  final spec = yaxis is Map<String, Object?> ? yaxis['tickformat'] : null;
  if (spec is! String || spec.isEmpty) {
    return null;
  }
  try {
    // `String Function(num)` is assignable to `String Function(double)`:
    // parameters are contravariant, so the formatter is handed over as is.
    return d3.format(spec);
  } on FormatException {
    // `format_spec.dart:88` is the only throw on this path.
    return null;
  }
}

/// The callout text for one y value (`PlotlySchemaAdapter.ts:253-261`).
String _formattedCalloutYData(Object? y, String Function(double)? tickFormat) =>
    tickFormat != null && y is num
    ? tickFormat(y.toDouble())
    : formatToLocaleString(y);

/// `layout.template.layout.colorway` (`PlotlySchemaAdapter.ts:2010`).
List<String>? _colorway(Map<String, Object?>? layout) {
  final template = layout?['template'];
  final templateLayout = template is Map<String, Object?>
      ? template['layout']
      : null;
  final colorway = templateLayout is Map<String, Object?>
      ? templateLayout['colorway']
      : null;
  return colorway is List<Object?>
      ? <String>[
          for (final entry in colorway)
            if (entry is String) entry,
        ]
      : null;
}

/// The distinct x values across every trace
/// (`PlotlySchemaAdapter.ts:468-487`).
List<Object> _extractXCategories(List<Object?> data) {
  final categories = <Object>{};
  for (final series in data) {
    final column = series is Map<String, Object?> ? series['x'] : null;
    if (column is! List<Object?>) {
      continue;
    }
    for (final value in column) {
      if (value != null) {
        categories.add(value);
      }
    }
  }
  return categories.toList();
}

/// Reads [value] as a map, or an empty one.
Map<String, Object?> _mapOf(Object? value) =>
    value is Map<String, Object?> ? value : const <String, Object?>{};

/// The shared body every one of the three wrappers runs
/// (`PlotlySchemaAdapter.ts:1979-2212`).
({
  FluentChartData data,
  FluentCartesianChartProps props,
  FluentAreaChartMode mode,
  bool optimizeLargeData,
  List<FluentColorFillBar>? colorFillBars,
})
_transformScatterTrace(
  Map<String, Object?> input,
  _ScatterKind kind, {
  required bool isMultiPlot,
  required PlotlyColorMap colorMap,
  required FluentPlotlyColorway colorwayType,
  required bool isDark,
}) {
  final rawData = input['data'];
  final data = rawData is List<Object?> ? rawData : const <Object?>[];
  final layoutRaw = input['layout'];
  final layout = layoutRaw is Map<String, Object?> ? layoutRaw : null;

  // `:1988-1996`: trace zero alone decides whether the colours are read off the
  // markers or off the line.
  final firstMode = data.isEmpty ? null : _mapOf(data.first)['mode'];
  final isScatterMarkers =
      firstMode is String && _kScatterMarkerModes.contains(firstMode);
  final isAreaChart = kind == _ScatterKind.area;
  final isScatterChart = kind == _ScatterKind.scatter;

  final secondary = _secondaryYAxisValues(data, layout);
  // `:2000`: the seed, overwritten by every trace in turn.
  var mode = FluentAreaChartMode.toNextY;
  final legend = getLegendProps(data, layout, isMultiPlot: isMultiPlot);
  final yTickFormat = _yAxisTickFormat(layout);
  final axisObjects = getAxisObjects(data, layout);
  final xAxisObject = axisObjects
      .where((axis) => axis.letter == 'x')
      .firstOrNull;
  // `:2003`.
  final resolveXValue = getAxisValueResolver(getAxisType(data, xAxisObject));
  final colorway = _colorway(layout);

  final angularAxis = _mapOf(_mapOf(layout?['polar'])['angularaxis']);
  final originX = layout?['__polarOriginX'];
  final rotation = angularAxis['rotation'];
  final direction = angularAxis['direction'];

  final chartData = <_Series>[];
  for (var index = 0; index < data.length; index++) {
    final series = data[index];
    if (series is! Map<String, Object?>) {
      continue;
    }
    final line = _mapOf(series['line']);
    final marker = _mapOf(series['marker']);
    final seriesMode = series['mode'];
    // `:2006-2010`: a marker mode reads `line.color` only when the mode also
    // mentions a line — note the substring is `line`, not `lines`.
    final colors = isScatterMarkers
        ? (seriesMode is String && seriesMode.contains('line')
              ? line['color']
              : marker['color'])
        : line['color'];
    final extracted = extractColor(
      colorway,
      colorwayType,
      colors,
      colorMap,
      isDark: isDark,
    );
    // `:2020`.
    final legendName = index < legend.names.length ? legend.names[index] : '';
    final seriesColor = resolveColor(
      extracted,
      index,
      legendName,
      colorMap,
      colorway,
      isDark: isDark,
    );
    final seriesOpacity = getOpacity(series, index);
    // `:2031`.
    mode = series['fill'] == 'tozeroy'
        ? FluentAreaChartMode.toZeroY
        : FluentAreaChartMode.toNextY;

    final isPolar = series['type'] == 'scatterpolar';
    // `:2033-2034`: a text mode prioritises the label over curving the line, and
    // a scatterpolar trace is drawn by the polar projection instead.
    final stroke =
        (seriesMode is String && seriesMode.contains('text')) || isPolar
        ? null
        : getLineOptions(series['line'] is Map<String, Object?> ? line : null);
    // `:2067-2083`: the object survives even when getLineOptions returned
    // undefined, because `mode` is written onto the spread unconditionally.
    final lineOptions = FluentLineOptions(
      strokeWidth: stroke?.strokeWidth,
      strokeDasharray: stroke?.strokeDasharray,
      strokeDashoffset: stroke?.strokeDashoffset,
      strokeLinecap: stroke?.strokeLinecap,
      lineBorderWidth: stroke?.lineBorderWidth,
      lineBorderColor: stroke?.lineBorderColor,
      curve: stroke?.curve,
      // `:2069`.
      mode: isPolar
          ? FluentLineMode.parse('scatterpolar')
          : (seriesMode is String ? FluentLineMode.parse(seriesMode) : null),
      // `:2080`, the scatterpolar arm only.
      fill: isPolar && series['fill'] is String
          ? series['fill']! as String
          : null,
    );
    final polarLineOptions = isPolar
        ? FluentPolarLineOptions(
            // `:2074`.
            originXOffset: originX is num ? originX.toDouble() : null,
            // `:2075`. Normalised to the two arms
            // `scatterpolar-utils.tsx:80-83` keeps, which is also what
            // FluentPolarLineOptions asserts.
            direction:
                direction == 'clockwise' || direction == 'counterclockwise'
                ? direction! as String
                : null,
            // `:2076`.
            rotation: rotation is num ? rotation.toDouble() : null,
            // `:2077-2079`: an absent `__axisLabel` becomes `{}` upstream, which
            // `scatterpolar-utils.tsx:84` then rejects for not being an array.
            axisLabel: series['__axisLabel'] is List<Object?>
                ? <String>[
                    for (final label in series['__axisLabel']! as List<Object?>)
                      '$label',
                  ]
                : null,
          )
        : null;
    final legendShape = getLegendShape(series);
    final useSecondaryYScale = _usesSecondaryYScale(series, layout);
    final color = parseCssColour(applyOpacityHex8(seriesColor, seriesOpacity));

    final xValues = series['x'] is List<Object?>
        ? series['x']! as List<Object?>
        : const <Object?>[];
    final yValues = series['y'] is List<Object?>
        ? series['y']! as List<Object?>
        : const <Object?>[];
    final markerSize = marker['size'];
    final markerColor = marker['color'];
    final texts = series['text'];

    // `:2037-2086`: one series per contiguous run of drawable points.
    for (final (rangeStart, rangeEnd) in getValidXYRanges(
      series,
      resolveXValue,
    )) {
      final points = <_Point>[];
      for (var i = rangeStart; i < rangeEnd; i++) {
        final resolvedX = resolveXValue(xValues[i]);
        final y = i < yValues.length ? yValues[i] : null;
        if (resolvedX == null || y == null) {
          continue;
        }
        points.add(
          _Point(
            x: resolvedX,
            y: y,
            // `:2057-2061`: a per-point size only from an array, a shared one
            // from a scalar.
            markerSize: markerSize is List<Object?>
                ? (i < markerSize.length && markerSize[i] is num
                      ? (markerSize[i]! as num).toDouble()
                      : null)
                : (markerSize is num ? markerSize.toDouble() : null),
            // `:2062`.
            markerColor: markerColor is List<Object?>
                ? (i < markerColor.length && markerColor[i] is String
                      ? parseCssColour(markerColor[i]! as String)
                      : null)
                : null,
            // `:2063`.
            text: texts is List<Object?>
                ? (i < texts.length && texts[i] != null ? '${texts[i]}' : null)
                : null,
            // `:2064`.
            calloutText: _formattedCalloutYData(y, yTickFormat),
          ),
        );
      }
      if (points.isEmpty) {
        continue;
      }
      chartData.add(
        _Series(
          legend: legendName,
          legendShape: legendShape,
          points: points,
          color: color,
          lineOptions: lineOptions,
          polarLineOptions: polarLineOptions,
          useSecondaryYScale: useSecondaryYScale,
        ),
      );
    }
  }

  // `:2090-2093`: the paper-coordinate anchors, read off the FIRST built series
  // alone.
  final anchor = chartData.isEmpty ? null : chartData.first.points;
  final xMinAnchor = anchor == null || anchor.isEmpty ? null : anchor.first.x;
  final xMaxAnchor = anchor == null || anchor.isEmpty ? null : anchor.last.x;
  final yMinAnchor = anchor == null || anchor.isEmpty ? null : anchor.first.y;
  final yMaxAnchor = anchor == null || anchor.isEmpty ? null : anchor.last.y;
  final xCategories = _extractXCategories(data);

  // `:2095-2148`: every `line` shape becomes a two-point reference series.
  final shapes = layout?['shapes'];
  final shapeList = shapes is List<Object?> ? shapes : const <Object?>[];
  var shapeIdx = -1;
  for (final entry in shapeList) {
    if (entry is! Map<String, Object?> || entry['type'] != 'line') {
      continue;
    }
    shapeIdx++;
    final shapeLine = _mapOf(entry['line']);
    final lineColor = shapeLine['color'];

    Object? resolveX(Object? value) {
      // `:2099-2106`: a numeric endpoint indexes the category list whenever one
      // exists — which it always does, so a numeric x axis has its reference
      // line silently moved onto a data value.
      // // parity: PlotlySchemaAdapter.ts:2100
      if (value is num) {
        final asIndex = value is int ? value : value.toInt();
        if (asIndex >= 0 && asIndex < xCategories.length && value == asIndex) {
          return xCategories[asIndex];
        }
        // `:2104`: out of range on both indices is `undefined` upstream, which
        // `resolveXValue` then turns into a null and the datum is undrawable.
        return shapeIdx < xCategories.length ? xCategories[shapeIdx] : null;
      }
      // `:2107-2119`: unreachable in practice. `xCategories` is always an
      // array, so every numeric endpoint has already returned above, and a
      // non-numeric one can equal neither 0 nor 1. Kept so the shape of the
      // branch matches. // parity: PlotlySchemaAdapter.ts:2107
      if (entry['xref'] == 'paper') {
        if (value == 0) {
          return xMinAnchor;
        }
        if (value == 1) {
          return xMaxAnchor;
        }
      }
      return value;
    }

    Object? resolveY(Object? value) {
      if (entry['yref'] != 'paper') {
        return value;
      }
      // `:2122-2136`.
      if (value == 0) {
        return yMinAnchor;
      }
      if (value == 1) {
        return yMaxAnchor;
      }
      if (value is num && yMinAnchor is num && yMaxAnchor is num) {
        return yMinAnchor + value * (yMaxAnchor - yMinAnchor);
      }
      return value;
    }

    final x0 = resolveXValue(resolveX(entry['x0']));
    final x1 = resolveXValue(resolveX(entry['x1']));
    final y0 = resolveY(entry['y0']);
    final y1 = resolveY(entry['y1']);
    // Upstream pushes the datum regardless and lets d3's `defined` guard drop
    // it; the Fluent data points require a non-null x and y, so an unresolvable
    // endpoint drops the whole reference line here instead.
    if (x0 == null || x1 == null || y0 == null || y1 == null) {
      continue;
    }
    chartData.add(
      _Series(
        // `:2139`.
        legend: 'Reference_$shapeIdx',
        points: <_Point>[
          _Point(x: x0, y: y0),
          _Point(x: x1, y: y1),
        ],
        // `:2144`.
        color: lineColor is String
            ? parseCssColour(lineColor)
            : const Color(0xFF000000),
        // `:2145`.
        lineOptions: getLineOptions(
          entry['line'] is Map<String, Object?> ? shapeLine : null,
        ),
        // `:2146`.
        useSecondaryYScale: false,
      ),
    );
  }

  final traceCount = chartData.length - (shapeIdx + 1);
  final traceSeries = chartData.take(traceCount < 0 ? 0 : traceCount).toList();
  final lineSeries = _asLineSeries(chartData);
  final scatterSeries = _asScatterSeries(chartData);

  // `:2150-2155`: a pinned `layout.yaxis.range` wins outright; with no range the
  // bounds come from the data. The extent is taken over the trace series alone,
  // because upstream reads `chartData` before the reference lines are
  // concatenated onto it at `:2159`.
  final yRange = getYMinMaxValues(layout);
  final yBounds = yRange.yMinValue == null && yRange.yMaxValue == null
      ? findNumericMinMaxOfY(
          isScatterChart
              ? _asScatterSeries(traceSeries)
              : _asLineSeries(traceSeries),
        )
      : FluentChartMinMax(
          startValue: yRange.yMinValue ?? 0,
          endValue: yRange.yMaxValue ?? 0,
        );

  // `:2156`: the reference lines are not counted.
  var numDataPoints = 0;
  for (final entry in traceSeries) {
    numDataPoints += entry.points.length;
  }

  final titles = getTitles(layout);
  final ticks = getAxisTickProps(data, layout);
  final scales = getAxisScaleTypeProps(data, layout);
  final categoryOrder = getAxisCategoryOrderProps(data, layout);
  // `:2166`.
  final annotations = getChartAnnotationsFromLayout(
    layout,
    isMultiPlot: isMultiPlot,
  );
  // `:2179`: the x range is part of commonProps, so all three wrappers honour
  // it — unlike the y range below.
  final xRange = getXMinMaxValues(layout);

  return (
    data: FluentChartData(
      chartTitle: titles.chartTitle,
      // `:2158-2164`.
      lineChartData: isScatterChart ? null : lineSeries,
      scatterChartData: isScatterChart ? scatterSeries : null,
    ),
    // `:2191`.
    mode: mode,
    // `:2176`.
    optimizeLargeData: numDataPoints > 1000,
    // `:2205-2209`: the colour-fill bars are line-and-area only.
    colorFillBars: isScatterChart ? null : mapColorFillBars(layout),
    props: FluentCartesianChartProps(
      // `:2174`.
      hideLegend: legend.hideLegend,
      // `:2173`.
      hideTickOverlap: true,
      // `:2175`: parseLocalDate builds local dates, so the axis must not
      // re-interpret them as UTC.
      useUTC: false,
      // `:2177`.
      showYAxisLables: true,
      // `:2178`.
      roundedTicks: true,
      xMinValue: xRange.xMinValue,
      xMaxValue: xRange.xMaxValue,
      showRoundOffXTickValues: xRange.showRoundOffXTickValues,
      // `:2180`.
      xAxisTitle: titles.xAxisTitle,
      yAxisTitle: titles.yAxisTitle,
      // `:2170` supplies this too, but `:2180` spreads getTitles after it and
      // both read `layout.yaxis2.title`, so the later one wins.
      secondaryYAxisTitle: titles.secondaryYAxisTitle ?? secondary.title,
      secondaryYScaleOptions: secondary.scaleOptions,
      // `:2182`.
      yAxisTickFormat: yTickFormat,
      // `:2183`.
      xScaleType: scales.x ?? FluentAxisScaleType.auto,
      yScaleType: scales.y ?? FluentAxisScaleType.auto,
      secondaryYScaleType: scales.secondaryY ?? FluentAxisScaleType.auto,
      // `:2184`. The two tick counts keep the shell's own defaults, 6 and 4
      // (`cartesian_chart_props.dart:95-96`), when `nticks` is absent.
      tickValues: ticks.xAxisTickValues,
      yAxisTickValues: ticks.yAxisTickValues,
      xAxisTickCount: ticks.xAxisTickCount ?? 6,
      yAxisTickCount: ticks.yAxisTickCount ?? 4,
      xAxis: FluentAxisConfig(
        tickStep: ticks.xAxisTickStep,
        tick0: ticks.xAxisTick0,
        tickText: ticks.xAxisTickText,
        tickLayout: ticks.xAxisTickLayout,
      ),
      yAxis: FluentAxisConfig(
        tickStep: ticks.yAxisTickStep,
        tick0: ticks.yAxisTick0,
        tickText: ticks.yAxisTickText,
        tickLayout: ticks.yAxisTickLayout,
      ),
      // `:2185`.
      annotations: annotations,
      // `:2188-2193`: the area branch returns commonProps alone and therefore
      // ignores `layout.yaxis.range` outright, even though it honours
      // `layout.xaxis.range` through commonProps.
      // // parity: PlotlySchemaAdapter.ts:2188-2193
      yMinValue: isAreaChart || yBounds.startValue.isNaN
          ? 0
          : yBounds.startValue,
      yMaxValue: isAreaChart || yBounds.endValue.isNaN ? 0 : yBounds.endValue,
      // `:2199-2204`: the scatter branch alone.
      showYAxisLablesTooltip: isScatterChart,
      xAxisCategoryOrder: isScatterChart
          ? categoryOrder.x ?? FluentAxisCategoryOrder.defaultOrder
          : FluentAxisCategoryOrder.defaultOrder,
      yAxisCategoryOrder: isScatterChart
          ? categoryOrder.y ?? FluentAxisCategoryOrder.defaultOrder
          : FluentAxisCategoryOrder.defaultOrder,
    ),
  );
}

/// One cell coordinate, narrowed to what `FluentHeatMapChartDataPoint` admits.
///
/// `types/DataPoint.ts:852-853` types both axes `string | Date | number` and
/// the Fluent point asserts exactly that; the Plotly schema's `Datum` is wider
/// and untrusted JSON can put a boolean or an object on an axis. Upstream
/// carries such a value straight onto a band scale, where it stringifies at
/// paint time — so stringifying it here is the same rendered result, and it is
/// the alternative to an assertion failure that takes the whole figure down in
/// debug. // parity: PlotlySchemaAdapter.ts:2542
Object _heatmapAxisKey(Object? value) =>
    value is num || value is String || value is DateTime ? value! : '$value';

/// Transforms a Plotly `heatmap` or `histogram2d` figure into a Fluent heat map
/// (`PlotlySchemaAdapter.ts:2397-2621`).
///
/// The largest single transformer, and the only one that builds a colour scale
/// domain and range from the data's own z extent.
///
/// [isMultiPlot], [colorMap] and [colorwayType] are unused: upstream takes all
/// three at `:2399-2401` and reads none of them, because a heat map colours
/// its cells from the z scale rather than from the figure's colourway. They
/// stay so the parameter list is uniform across every transformer.
///
/// `:2612`'s `width` and `:2613`'s `height` are not set here, for the same
/// reason as every other cartesian transformer in this plan: the nine shell
/// charts size to their `BoxConstraints` (spec §2.2), so the Plotly layout
/// dimensions become the grid cell's enclosing `SizedBox` and the 350 lives in
/// `kPlotlyDefaultCellHeight`.
FluentHeatMapChart transformPlotlyToHeatmap(
  Map<String, Object?> input, {
  required bool isMultiPlot,
  required PlotlyColorMap colorMap,
  required FluentPlotlyColorway colorwayType,
  required bool isDark,
}) {
  final rawData = input['data'];
  final data = rawData is List<Object?> ? rawData : const <Object?>[];
  final layoutRaw = input['layout'];
  final layout = layoutRaw is Map<String, Object?> ? layoutRaw : null;
  // `:2404`: everything below reads trace 0 only.
  final firstRaw = data.isEmpty ? null : data.first;
  final firstData = firstRaw is Map<String, Object?>
      ? firstRaw
      : const <String, Object?>{};

  final heatmapDataPoints = <FluentHeatMapChartDataPoint>[];
  // `:2406-2407`: the seeds are the infinities, so a figure with no numeric z
  // keeps them and the default domain at `:2563` becomes
  // `[Infinity, NaN, -Infinity]`. Reproduced.
  // // parity: PlotlySchemaAdapter.ts:2406
  var zMin = double.infinity;
  var zMax = double.negativeInfinity;

  // `:2409-2452`: the layout annotations are re-projected onto a grid indexed
  // by the RANK of each distinct x and y, not by the cell coordinates
  // themselves.
  final annotationGrid = <int, Map<int, String>>{};
  final rawAnnotations = layout?['annotations'];
  if (rawAnnotations != null) {
    // `:2414`: a lone object is wrapped.
    final annotationsArray = rawAnnotations is List<Object?>
        ? rawAnnotations
        : <Object?>[rawAnnotations];
    final xSet = <double>{};
    final ySet = <double>{};
    final validAnnotations = <({double x, double y, String text})>[];
    for (final entry in annotationsArray) {
      if (entry is! Map<String, Object?>) continue;
      final ax = entry['x'];
      final ay = entry['y'];
      final text = entry['text'];
      final xref = entry['xref'];
      final yref = entry['yref'];
      // `:2422-2429`: numeric coordinates, a string body, and either no ref or
      // the primary axis.
      if (ax is! num || ay is! num || text is! String) continue;
      if (!(xref == 'x' || xref == null)) continue;
      if (!(yref == 'y' || yref == null)) continue;
      xSet.add(ax.toDouble());
      ySet.add(ay.toDouble());
      validAnnotations.add((
        x: ax.toDouble(),
        y: ay.toDouble(),
        text: cleanPlotlyText(text),
      ));
    }

    if (validAnnotations.isNotEmpty) {
      // `:2438-2439`: an explicit numeric comparator, so this is a real numeric
      // sort and not JavaScript's lexicographic default.
      final xValues = xSet.toList()..sort();
      final yValues = ySet.toList()..sort();
      for (final annotation in validAnnotations) {
        final xIdx = xValues.indexOf(annotation.x);
        final yIdx = yValues.indexOf(annotation.y);
        // `:2445-2448`.
        (annotationGrid[yIdx] ??= <int, String>{})[xIdx] = annotation.text;
      }
    }
  }

  // `:2454`.
  String? getAnnotationByIndex(int xIdx, int yIdx) =>
      annotationGrid[yIdx]?[xIdx];

  // `:2511` and `:2545`: `||`, so an annotation that cleaned down to the empty
  // string falls through to the number, and so does a zero-length one.
  Object? rectTextOf(String? annotationText, Object? zVal) =>
      annotationText != null && annotationText.isNotEmpty
      ? annotationText
      // `types/DataPoint.ts:858` types rectText `string | number`; anything
      // else on the z grid is dropped rather than asserted against, for the
      // reason [_heatmapAxisKey] gives.
      : (zVal is num || zVal is String ? zVal : null);

  if (firstData['type'] == 'histogram2d') {
    // `:2456-2519`.
    final xColumn = firstData['x'];
    final yColumn = firstData['y'];
    final xValues = <Object>[];
    final yValues = <Object>[];
    final zValues = <double>[];
    if (xColumn is List<Object?>) {
      for (var index = 0; index < xColumn.length; index++) {
        final xVal = xColumn[index];
        final yVal = yColumn is List<Object?> && index < yColumn.length
            ? yColumn[index]
            : null;
        // `:2461`.
        final zVal = getNumberAtIndexOrDefault(firstData['z'], index) ?? 0;
        // `:2462-2464`.
        if (isInvalidValue(xVal) || isInvalidValue(yVal)) continue;
        xValues.add(xVal!);
        yValues.add(yVal!);
        zValues.add(zVal);
      }
    }

    final isXString = isStringArray(xValues);
    final isYString = isStringArray(yValues);
    final xbins = firstData['xbins'];
    final ybins = firstData['ybins'];
    final xbinsMap = xbins is Map<String, Object?>
        ? xbins
        : const <String, Object?>{};
    final ybinsMap = ybins is Map<String, Object?>
        ? ybins
        : const <String, Object?>{};
    // `:2473-2474`.
    final xBins = createBins(
      xValues,
      binStart: xbinsMap['start'],
      binEnd: xbinsMap['end'],
      binSize: xbinsMap['size'],
    );
    final yBins = createBins(
      yValues,
      binStart: ybinsMap['start'],
      binEnd: ybinsMap['end'],
      binSize: ybinsMap['size'],
    );

    // `:2475`: indexed `[y][x]`.
    final zBins = <List<List<double>>>[
      for (var yi = 0; yi < yBins.length; yi++)
        <List<double>>[for (var xi = 0; xi < xBins.length; xi++) <double>[]],
    ];

    // `:2478-2485`.
    for (var index = 0; index < xValues.length; index++) {
      final xBinIdx = findBinIndex(xBins, xValues[index], isString: isXString);
      final yBinIdx = findBinIndex(yBins, yValues[index], isString: isYString);
      if (xBinIdx != -1 && yBinIdx != -1) {
        zBins[yBinIdx][xBinIdx].add(zValues[index]);
      }
    }

    // `:2487-2493`: the whole nested map runs first, so `total` is complete
    // before the render loop below reads it.
    final histfunc = firstData['histfunc'];
    var total = 0.0;
    final z = <List<double>>[];
    for (final row in zBins) {
      final resolvedRow = <double>[];
      for (final bin in row) {
        final zVal = calculateHistFunc(
          histfunc is String ? histfunc : null,
          bin,
        );
        total += zVal;
        resolvedRow.add(zVal);
      }
      z.add(resolvedRow);
    }

    final histnorm = firstData['histnorm'];
    // `:2495-2519`: x outer, y inner.
    for (var xIdx = 0; xIdx < xBins.length; xIdx++) {
      final xBin = xBins[xIdx];
      for (var yIdx = 0; yIdx < yBins.length; yIdx++) {
        final yBin = yBins[yIdx];
        // `:2497-2503`: a two-dimensional normalisation, so `dy` is the y bin's
        // width rather than the default 1.
        final zVal = calculateHistNorm(
          histnorm is String ? histnorm : null,
          z[yIdx][xIdx],
          total,
          isXString
              ? (xBin as List<Object?>).length.toDouble()
              : getBinSize(xBin as d3.Bin),
          isYString
              ? (yBin as List<Object?>).length.toDouble()
              : getBinSize(yBin as d3.Bin),
        );
        final annotationText = getAnnotationByIndex(xIdx, yIdx);

        heatmapDataPoints.add(
          FluentHeatMapChartDataPoint(
            // `:2508-2509`.
            x: isXString
                ? (xBin as List<Object?>).map((e) => '$e').join(', ')
                : getBinCenter(xBin as d3.Bin),
            y: isYString
                ? (yBin as List<Object?>).map((e) => '$e').join(', ')
                : getBinCenter(yBin as d3.Bin),
            value: zVal,
            rectText: rectTextOf(annotationText, zVal),
          ),
        );

        // `:2514-2517`.
        zMin = math.min(zMin, zVal);
        zMax = math.max(zMax, zVal);
      }
    }
  } else {
    // `:2520-2554`.
    final zRaw = firstData['z'];
    final zArray = zRaw is List<Object?> ? zRaw : const <Object?>[];
    final xColumn = firstData['x'];
    final yColumn = firstData['y'];

    // `:2527-2528`.
    final yLength = zArray.length;
    final firstRow = zArray.isEmpty ? null : zArray.first;
    final xLength = firstRow is List<Object?> ? firstRow.length : 0;

    // `:2531-2532`: generated y indices count DOWN, because Plotly's z rows are
    // bottom-origin and the chart's are top-origin.
    final xData = xColumn is List<Object?>
        ? xColumn
        : <Object?>[for (var i = 0; i < xLength; i++) i];
    final yData = yColumn is List<Object?>
        ? yColumn
        : <Object?>[for (var i = 0; i < yLength; i++) yLength - 1 - i];

    for (var xIdx = 0; xIdx < xData.length; xIdx++) {
      for (var yIdx = 0; yIdx < yData.length; yIdx++) {
        final row = yIdx < zArray.length ? zArray[yIdx] : null;
        final zVal = row is List<Object?> && xIdx < row.length
            ? row[xIdx]
            : null;
        final annotationText = getAnnotationByIndex(xIdx, yIdx);

        heatmapDataPoints.add(
          FluentHeatMapChartDataPoint(
            // `:2542-2543`: the `as Date` casts erase at runtime, so both arms
            // pass the raw schema value through; only the `?? 0` differs, and
            // an absent coordinate renders nothing either way.
            // // parity: PlotlySchemaAdapter.ts:2542
            x: _heatmapAxisKey(xData[xIdx] ?? 0),
            y: _heatmapAxisKey(yData[yIdx] ?? 0),
            // `:2544`: upstream stores `undefined` for a hole and the chart's
            // arithmetic then yields NaN. NaN is the faithful stand-in for a
            // non-nullable double; 0 would paint a real colour.
            // // parity: PlotlySchemaAdapter.ts:2544
            value: zVal is num ? zVal.toDouble() : double.nan,
            rectText: rectTextOf(annotationText, zVal),
          ),
        );

        // `:2548-2551`.
        if (zVal is num) {
          zMin = math.min(zMin, zVal.toDouble());
          zMax = math.max(zMax, zVal.toDouble());
        }
      }
    }
  }

  // `:2556-2560`.
  final name = firstData['name'];
  final heatmapData = FluentHeatMapChartData(
    legend: name is String ? name : '',
    data: heatmapDataPoints,
    value: 0,
  );

  // `:2562-2568`.
  final defaultDomain = <double>[zMin, (zMax + zMin) / 2, zMax];
  final defaultRange = <Color>[
    FluentDataVizPalette.resolve(FluentDataVizToken.color1, isDark: isDark),
    FluentDataVizPalette.resolve(FluentDataVizToken.color2, isDark: isDark),
    FluentDataVizPalette.resolve(FluentDataVizToken.color3, isDark: isDark),
  ];

  // `:2570-2576`: six fallbacks in order. The fifth is guarded on the trace
  // type and reads `template.data.histogram2d[0]`, the sixth
  // `template.data.heatmap[0]`.
  Object? firstTemplateColorscale(String traceType) {
    final template = layout?['template'];
    final templateData = template is Map<String, Object?>
        ? template['data']
        : null;
    final traces = templateData is Map<String, Object?>
        ? templateData[traceType]
        : null;
    final first = traces is List<Object?> && traces.isNotEmpty
        ? traces.first
        : null;
    return first is Map<String, Object?> ? first['colorscale'] : null;
  }

  final template = layout?['template'];
  final templateLayout = template is Map<String, Object?>
      ? template['layout']
      : null;
  final coloraxis = layout?['coloraxis'];
  // DEVIATION, plan 09 task 24's Step 3 code over upstream `:2575-2576`: there
  // the fifth fallback is `(type === 'histogram2d' && …)`, which contributes
  // the boolean `false` for a heatmap trace, and `false ?? …` keeps the
  // `false` — so upstream's sixth fallback is dead for every trace that is not
  // a histogram2d, which is every heatmap. The plan writes the guard as a
  // conditional yielding null, which revives it. Following the plan.
  var colorscale =
      firstData['colorscale'] ??
      layout?['colorscale'] ??
      (coloraxis is Map<String, Object?> ? coloraxis['colorscale'] : null) ??
      (templateLayout is Map<String, Object?>
          ? templateLayout['colorscale']
          : null) ??
      (firstData['type'] == 'histogram2d'
          ? firstTemplateColorscale('histogram2d')
          : null) ??
      firstTemplateColorscale('heatmap');

  // `:2579-2595`: the template form is an object of three named ramps, selected
  // by the sign span of the data.
  if (colorscale is Map<String, Object?> &&
      (colorscale.containsKey('diverging') ||
          colorscale.containsKey('sequential') ||
          colorscale.containsKey('sequentialminus'))) {
    final isDivergent = zMin < 0 && zMax > 0;
    final isSequential = zMin >= 0;
    final isSequentialMinus = zMax <= 0;
    if (isDivergent) {
      colorscale = colorscale['diverging'];
    } else if (isSequential) {
      colorscale = colorscale['sequential'];
    } else if (isSequentialMinus) {
      colorscale = colorscale['sequentialminus'];
    }
  }

  // `:2597-2603`: each stop is `[position, cssColour]`; the position is
  // rescaled from 0..1 onto the data's own z extent.
  final List<double> domainValuesForColorScale;
  final List<Color> rangeValuesForColorScale;
  if (colorscale is List<Object?>) {
    domainValuesForColorScale = <double>[
      for (final stop in colorscale)
        if (stop is List<Object?> && stop.isNotEmpty && stop[0] is num)
          (stop[0]! as num).toDouble() * (zMax - zMin) + zMin,
    ];
    rangeValuesForColorScale = <Color>[
      for (final stop in colorscale)
        if (stop is List<Object?> && stop.length > 1 && stop[1] is String)
          parseCssColour(stop[1]! as String),
    ];
  } else {
    domainValuesForColorScale = defaultDomain;
    rangeValuesForColorScale = defaultRange;
  }

  final titles = getTitles(layout);
  // `:2618`: only trace 0, unlike `:2619` which passes the whole list.
  final categoryOrder = getAxisCategoryOrderProps(<Object?>[firstData], layout);
  final tickProps = getAxisTickProps(data, layout);
  // DEVIATION, plan 09 task 24 over upstream: `:2617-2619` spreads getTitles,
  // getAxisCategoryOrderProps and getAxisTickProps only — it does NOT spread
  // getAxisScaleTypeProps, so upstream's heat map keeps the shell's automatic
  // scale types even when the layout declares `xaxis.type`. The plan's Step 3
  // code reads them; following the plan.
  final scaleTypes = getAxisScaleTypeProps(data, layout);

  return FluentHeatMapChart(
    // `:2606`: always exactly one series.
    data: <FluentHeatMapChartData>[heatmapData],
    domainValuesForColorScale: domainValuesForColorScale,
    rangeValuesForColorScale: rangeValuesForColorScale,
    // `:2611` sends `sortOrder: 'none'` — the chart must not re-sort a grid.
    // `HeatMapChart.tsx:648` reads that as "leave the order alone", which is
    // what `sortAlphabetically: false` spells (`heat_map_chart.dart:667`).
    sortAlphabetically: false,
    // `:2617`.
    chartTitle: titles.chartTitle,
    props: FluentCartesianChartProps(
      xAxisTitle: titles.xAxisTitle,
      yAxisTitle: titles.yAxisTitle,
      // `:2609`: unconditional, so `isMultiPlot` is not consulted here.
      hideLegend: true,
      // `:2610`.
      showYAxisLables: true,
      // `:2614`.
      hideTickOverlap: true,
      // `:2615`: 20 characters before an ellipsis.
      noOfCharsToTruncate: 20,
      // `:2616`.
      showYAxisLablesTooltip: true,
      xAxisCategoryOrder:
          categoryOrder.x ?? FluentAxisCategoryOrder.defaultOrder,
      yAxisCategoryOrder:
          categoryOrder.y ?? FluentAxisCategoryOrder.defaultOrder,
      xScaleType: scaleTypes.x ?? FluentAxisScaleType.auto,
      yScaleType: scaleTypes.y ?? FluentAxisScaleType.auto,
      secondaryYScaleType: scaleTypes.secondaryY ?? FluentAxisScaleType.auto,
      // `:2619`. The two tick counts keep the shell's own defaults, 6 and 4
      // (`cartesian_chart_props.dart:95-96`), when `nticks` is absent.
      tickValues: tickProps.xAxisTickValues,
      yAxisTickValues: tickProps.yAxisTickValues,
      xAxisTickCount: tickProps.xAxisTickCount ?? 6,
      yAxisTickCount: tickProps.yAxisTickCount ?? 4,
      xAxis: FluentAxisConfig(
        tickStep: tickProps.xAxisTickStep,
        tick0: tickProps.xAxisTick0,
        tickText: tickProps.xAxisTickText,
        // The plan's Step 3 code omits the two tick layouts; `:2619` spreads
        // the whole of getAxisTickProps, which carries them.
        tickLayout: tickProps.xAxisTickLayout,
      ),
      yAxis: FluentAxisConfig(
        tickStep: tickProps.yAxisTickStep,
        tick0: tickProps.yAxisTick0,
        tickText: tickProps.yAxisTickText,
        tickLayout: tickProps.yAxisTickLayout,
      ),
    ),
  );
}
