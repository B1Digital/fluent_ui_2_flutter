/// Transformers for this port's two extension kinds, which upstream's
/// `PlotlySchemaAdapter.ts` has no counterpart for: they are reached only
/// through `meta.fluentChart` (see `fluentChartExtensionKind` in `router.dart`).
///
/// Both read the same Plotly keys the neighbouring upstream transformers read
/// for the same trace shape — `x`/`y`/`name`/`marker.color`/`line.color`, the
/// template colourway, `layout.width`/`height`/`showlegend` — so a figure
/// written for them stays a valid Plotly figure everywhere else.
library;

import '../../horizontal_bar_chart.dart';
import '../../model/bar_data.dart';
import '../../model/cartesian_series.dart';
import '../../sparkline.dart';
import 'color_adapter.dart';
import 'common.dart';

Map<String, Object?>? _map(Object? value) =>
    value is Map<String, Object?> ? value : null;

List<Object?> _list(Object? value) =>
    value is List<Object?> ? value : const <Object?>[];

double? _num(Object? value) => value is num ? value.toDouble() : null;

List<String>? _colorway(Map<String, Object?>? layout) {
  final template = _map(layout?['template']);
  final colorway = _map(template?['layout'])?['colorway'];
  if (colorway is! List<Object?>) return null;
  return <String>[
    for (final entry in colorway)
      if (entry is String) entry,
  ];
}

/// The first trace of [input] as a `FluentSparkline`.
///
/// Extension, not upstream. One trace per sparkline, as each is its own
/// non-plot cell (`grid.dart`). Points are the numeric `y` values paired with
/// `x` (index when `x` is absent); non-numeric `y` points are skipped. The
/// legend and the value text are `name`, else the last point's `y`. Size is
/// `layout.width`/`height`, else the widget's own 80 x 20, and the legend is
/// shown only when `layout.showlegend` is `true`, as the widget defaults to.
FluentSparkline transformPlotlyToSparkline(
  Map<String, Object?> input, {
  required PlotlyColorMap colorMap,
  required FluentPlotlyColorway colorwayType,
  required bool isDark,
}) {
  final layout = _map(input['layout']);
  final trace = _map(_list(input['data']).firstOrNull) ?? <String, Object?>{};
  final xs = _list(trace['x']);
  final ys = _list(trace['y']);

  final points = <FluentLineChartDataPoint>[
    for (var i = 0; i < ys.length; i++)
      if (ys[i] is num)
        FluentLineChartDataPoint(
          x: i < xs.length && xs[i] != null ? xs[i]! : i,
          y: (ys[i]! as num).toDouble(),
        ),
  ];
  final name = trace['name'];
  final legend = name is String && name.isNotEmpty
      ? name
      : (points.isEmpty
            ? ''
            : cleanPlotlyText('${ys.lastWhere((y) => y is num)}'));

  final colorway = _colorway(layout);
  final extracted = extractColor(
    colorway,
    colorwayType,
    _map(trace['line'])?['color'] ?? _map(trace['marker'])?['color'],
    colorMap,
    isDark: isDark,
  );
  final colour = parseCssColour(
    resolveColor(extracted, 0, legend, colorMap, colorway, isDark: isDark),
  );

  return FluentSparkline(
    data: FluentChartData(
      chartTitle: legend,
      lineChartData: <FluentLineChartSeries>[
        FluentLineChartSeries(legend: legend, data: points, color: colour),
      ],
    ),
    width: _num(layout?['width']) ?? 80,
    height: _num(layout?['height']) ?? 20,
    showLegend: layout?['showlegend'] == true,
  );
}

/// Horizontal `bar` traces as the axis-free `FluentHorizontalBarChart`.
///
/// Extension, not upstream. Each distinct `y` (in first-seen order) is one
/// row; each trace contributes one segment per row, named by the trace `name`
/// (else `Series N`) and coloured per trace — the stacked-bar shape upstream
/// feeds `HorizontalBarChartWithAxis`, drawn part-to-whole instead. Only
/// numeric `x` values become segments.
///
/// The first trace's `meta` may also carry `variant` (`partToWhole`, the
/// default, or `absoluteScale`) and `totals`, one number per row in row order,
/// which becomes each segment's `total` (the "value of total" rows of the
/// widget's own stories).
FluentHorizontalBarChart transformPlotlyToHorizontalBarChart(
  Map<String, Object?> input, {
  required PlotlyColorMap colorMap,
  required FluentPlotlyColorway colorwayType,
  required bool isDark,
}) {
  final layout = _map(input['layout']);
  final traces = <Map<String, Object?>>[
    for (final entry in _list(input['data']))
      if (entry is Map<String, Object?>) entry,
  ];
  final meta = _map(traces.firstOrNull?['meta']);
  final totals = _list(meta?['totals']);
  final colorway = _colorway(layout);

  final rows = <String>[];
  final segments = <String, List<FluentChartDataPoint>>{};
  for (var t = 0; t < traces.length; t++) {
    final trace = traces[t];
    final name = trace['name'];
    final legend = name is String && name.isNotEmpty
        ? cleanPlotlyText(name)
        : 'Series ${t + 1}';
    final extracted = extractColor(
      colorway,
      colorwayType,
      _map(trace['marker'])?['color'],
      colorMap,
      isDark: isDark,
    );
    final colour = parseCssColour(
      resolveColor(extracted, t, legend, colorMap, colorway, isDark: isDark),
    );
    final ys = _list(trace['y']);
    final xs = _list(trace['x']);
    for (var i = 0; i < ys.length && i < xs.length; i++) {
      final value = xs[i];
      if (value is! num || ys[i] == null) continue;
      final row = cleanPlotlyText('${ys[i]}');
      if (!segments.containsKey(row)) {
        rows.add(row);
        segments[row] = <FluentChartDataPoint>[];
      }
      final rowIndex = rows.indexOf(row);
      segments[row]!.add(
        FluentChartDataPoint(
          legend: legend,
          color: colour,
          horizontalBarChartData: FluentHorizontalDataPoint(
            x: value.toDouble(),
            total: rowIndex < totals.length ? _num(totals[rowIndex]) : null,
          ),
        ),
      );
    }
  }

  return FluentHorizontalBarChart(
    data: <FluentChartData>[
      for (final row in rows)
        FluentChartData(chartTitle: row, chartData: segments[row]),
    ],
    variant: meta?['variant'] == 'absoluteScale'
        ? FluentHorizontalBarChartVariant.absoluteScale
        : FluentHorizontalBarChartVariant.partToWhole,
  );
}
