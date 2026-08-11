/// The Plotly scatter-trace core.
///
/// Ports `PlotlySchemaAdapter.ts:1908-2212`: one shared body (`:1979-2212`)
/// behind three thin wrappers (`:1908`, `:1925`, `:1942`) plus
/// `mapColorFillBars` (`:1959-1977`). Upstream builds line, area **and**
/// scatter traces from that single body and returns the result `as
/// LineChartProps` / `as AreaChartProps` / `as ScatterChartProps`; this file is
/// the typed spelling of those three casts.
///
/// It is also the producer of the `scatterpolar` mode literal and of the four
/// polar members `FluentPolarLineOptions` carries — `line_chart.dart:825` and
/// `scatter_chart.dart:452` read the first, `line_chart.dart:1077` and
/// `scatter_chart.dart:471` read the second.
///
/// Internal to the package: nothing here is barrel-exported.
library;

import 'package:flutter/widgets.dart';

import '../../area_chart.dart';
import '../../axis/axis_types.dart';
import '../../axis/domain_range.dart';
import '../../axis/tick_format.dart';
import '../../cartesian/cartesian_chart_props.dart';
import '../../chrome/legend_shape.dart';
import '../../line_chart.dart';
import '../../model/cartesian_series.dart';
import '../../model/chart_common.dart';
import '../../model/line_options.dart';
import '../../model/polar_data.dart';
import '../../scatter_chart.dart';
import '../d3/format.dart' as d3;
import 'annotations.dart';
import 'axis.dart';
import 'color_adapter.dart';
import 'common.dart';
import 'legends.dart';
import 'predicates.dart';

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
