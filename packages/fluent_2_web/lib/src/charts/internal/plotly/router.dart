import 'package:flutter/foundation.dart';

import 'base64_data.dart';
import 'json_guard.dart';
import 'predicates.dart';

/// The 18 chart kinds a Plotly figure can route to.
///
/// The 16 of the `FluentChart` union at `PlotlySchemaConverter.ts:4-20`, plus
/// [funnel] and [verticalBar] — which the union omits but `:546` and `:518`
/// return; see their docs.
enum FluentPlotlyChartKind {
  /// Layout annotations with no traces (`PlotlySchemaConverter.ts:499`).
  annotation,

  /// Filled scatter (`PlotlySchemaConverter.ts:571`).
  area,

  /// More than one distinct kind survived (`PlotlySchemaConverter.ts:633`).
  composite,

  /// `pie` traces (`PlotlySchemaConverter.ts:508`).
  donut,

  /// A scatter that cannot be drawn as a line and falls back to a stacked bar
  /// (`PlotlySchemaConverter.ts:576`).
  fallback,

  /// `funnel` or `funnelarea` (`PlotlySchemaConverter.ts:544-546`).
  ///
  /// Absent from the `FluentChart` union at `PlotlySchemaConverter.ts:4-20`,
  /// which the `as TraceInfo` cast at `:602` lets through; `:546` is the branch
  /// that returns it and `DeclarativeChart.tsx:248-251` renders a `FunnelChart`
  /// for it, so the union is what is incomplete, not the branch.
  funnel,

  /// `indicator` or `gauge` (`PlotlySchemaConverter.ts:516`).
  gauge,

  /// Grouped bars (`PlotlySchemaConverter.ts:533`).
  groupedVerticalBar,

  /// `heatmap` or `histogram2d` (`PlotlySchemaConverter.ts:511`).
  heatmap,

  /// Horizontal bars (`PlotlySchemaConverter.ts:529`).
  horizontalBar,

  /// Line scatter (`PlotlySchemaConverter.ts:571`).
  line,

  /// Marker scatter (`PlotlySchemaConverter.ts:565`).
  scatter,

  /// `scatterpolar` (`PlotlySchemaConverter.ts:520`).
  scatterPolar,

  /// `sankey` (`PlotlySchemaConverter.ts:513`).
  sankey,

  /// `table` (`PlotlySchemaConverter.ts:522`).
  table,

  /// `histogram`, the one type that bins (`PlotlySchemaConverter.ts:518`).
  ///
  /// Absent from the `FluentChart` union at `PlotlySchemaConverter.ts:4-20`
  /// for the same reason [funnel] is — the `as TraceInfo` cast at `:602` lets
  /// it through — yet `:518` is the branch that returns it and
  /// `DeclarativeChart.tsx:303-306` binds it to `transformPlotlyJsonToVBCProps`
  /// in `chartMap`, so the union is what is incomplete, not the branch. A
  /// `bar` trace never arrives here: `:542` sends a plain vertical bar to
  /// [verticalStackedBar].
  verticalBar,

  /// Stacked bars, the default vertical bar route
  /// (`PlotlySchemaConverter.ts:542`).
  verticalStackedBar,

  /// Horizontal bars with a `base`, or the plotly.py scatter form
  /// (`PlotlySchemaConverter.ts:527`, `:553`).
  gantt,
}

/// The lower-case wire name upstream uses for [kind].
///
/// Kept because `DeclarativeChart.tsx:578-588` compares chart types as strings
/// and the storybook fixtures record them that way.
String plotlyChartKindName(FluentPlotlyChartKind kind) => switch (kind) {
  FluentPlotlyChartKind.annotation => 'annotation',
  FluentPlotlyChartKind.area => 'area',
  FluentPlotlyChartKind.composite => 'composite',
  FluentPlotlyChartKind.donut => 'donut',
  FluentPlotlyChartKind.fallback => 'fallback',
  FluentPlotlyChartKind.funnel => 'funnel',
  FluentPlotlyChartKind.gauge => 'gauge',
  FluentPlotlyChartKind.groupedVerticalBar => 'groupedverticalbar',
  FluentPlotlyChartKind.heatmap => 'heatmap',
  FluentPlotlyChartKind.horizontalBar => 'horizontalbar',
  FluentPlotlyChartKind.line => 'line',
  FluentPlotlyChartKind.scatter => 'scatter',
  FluentPlotlyChartKind.scatterPolar => 'scatterpolar',
  FluentPlotlyChartKind.sankey => 'sankey',
  FluentPlotlyChartKind.table => 'table',
  FluentPlotlyChartKind.verticalBar => 'verticalbar',
  FluentPlotlyChartKind.verticalStackedBar => 'verticalstackedbar',
  FluentPlotlyChartKind.gantt => 'gantt',
};

/// `UNSUPPORTED_MSG_PREFIX` at `PlotlySchemaConverter.ts:38`.
const String _unsupportedPrefix = 'Unsupported chart - type :';

/// The four scatter modes that render as discrete marks
/// (`PlotlySchemaConverter.ts:292-294`).
bool _isScatterMarkers(String mode) => const <String>[
  'markers',
  'text+markers',
  'markers+text',
  'text',
].contains(mode);

/// The `mode` of [trace] as upstream's `data.mode ?? ''`
/// (`PlotlySchemaConverter.ts:297`).
String _mode(Map<String, Object?> trace) {
  final mode = trace['mode'];
  return mode is String ? mode : '';
}

/// Whether a horizontal bar carries a usable `base`
/// (`PlotlySchemaConverter.ts:648-650`).
bool canMapToGantt(Map<String, Object?> trace) {
  final base = trace['base'];
  return isDateArray(base) ||
      isNumberArray(base) ||
      isPlotlyDate(base) ||
      isPlotlyNumber(base);
}

/// Whether either of [trace]'s two axes is declared `log` in [layout]
/// (`PlotlySchemaConverter.ts:322-328`).
bool _invalidateLogAxis(
  Map<String, Object?> trace,
  Map<String, Object?>? layout,
) {
  final ids = getAxisIds(trace);
  for (final entry in <(String, int)>[('x', ids.x), ('y', ids.y)]) {
    final axis = layout?[getAxisKey(entry.$1, entry.$2)];
    if (axis is Map<String, Object?> && axis['type'] == 'log') {
      return true;
    }
  }
  return false;
}

/// Whether a scatter trace can be drawn by the line chart
/// (`PlotlySchemaConverter.ts:677-696`).
///
/// A year array is deliberately *not* a date and *not* a continuous number —
/// upstream's comment at `:680-683` explains that a year is a point in time
/// whose timezone handling the library does not want.
bool supportedScatterInLineChart(
  Map<String, Object?> trace,
  Map<String, Object?>? layout,
) {
  final x = trace['x'];
  final isXDate = isDateArray(x);
  final isXNumber = isNumberArray(x);
  final isXYear = isYearArray(x);
  final isXMonth = isMonthArray(x);
  final isYString = isStringArray(trace['y']);
  final xAxis = layout?[getAxisKey('x', getAxisIds(trace).x)];
  final isCategoryX =
      xAxis is Map<String, Object?> && xAxis['type'] == 'category';
  return (isXDate || isXNumber || isXMonth) &&
      !isXYear &&
      !isYString &&
      !isCategoryX;
}

/// Whether a scatter trace has to be redrawn as a stacked bar
/// (`PlotlySchemaConverter.ts:698-703`).
bool doesScatterNeedFallback(
  Map<String, Object?> trace,
  Map<String, Object?>? layout,
) {
  if (_isScatterMarkers(_mode(trace))) {
    return false;
  }
  return !supportedScatterInLineChart(trace, layout);
}

/// Whether a scatter trace is one of plotly.py's gantt shapes.
///
/// `PlotlySchemaConverter.ts:708-741`. The first branch walks `x` with **stride
/// 5** — the rectangle plus its `null` separator — and checks that each group of
/// five is a closed corner set. The second recognises the invisible marker trace
/// plotly.py emits alongside, which is only a gantt once a corner trace has
/// already been seen in the same figure.
bool isScatterGanttChart(
  Map<String, Object?> trace, {
  required bool foundScatterGantt,
}) {
  if (trace['mode'] == 'none' && trace['fill'] == 'toself') {
    final x = trace['x'];
    final y = trace['y'];
    // `:712` dereferences `data.x!` and `data.y!` unguarded; the port tests
    // them because the schema is untrusted JSON and a throw here would abort
    // the whole conversion rather than reject one trace.
    if (x is List<Object?> && y is List<Object?>) {
      // Reading past the end yields `null`, which is what JS's out-of-bounds
      // index returns at `:714-718` for a trailing partial group.
      Object? at(List<Object?> list, int index) =>
          index < list.length ? list[index] : null;
      var corners = true;
      // 5 = the four rectangle corners plus the `null` that separates one bar
      // from the next (`_gantt.py` emits exactly that shape).
      for (var i = 0; i < x.length; i += 5) {
        if (at(x, i) != at(x, i + 3) ||
            at(x, i + 1) != at(x, i + 2) ||
            at(y, i) != at(y, i + 1) ||
            at(y, i + 2) != at(y, i + 3) ||
            (i > 0 && at(y, i - 1) != null)) {
          corners = false;
          break;
        }
      }
      if (corners) {
        return true;
      }
    }
  }
  final marker = trace['marker'];
  return trace['mode'] == 'markers' &&
      marker is Map<String, Object?> &&
      marker['size'] == 1 &&
      marker['opacity'] == 0 &&
      trace['name'] == '' &&
      trace['showlegend'] == false &&
      foundScatterGantt;
}

/// Whether a sankey trace's link graph contains a cycle
/// (`PlotlySchemaConverter.ts:336-383`).
bool findSankeyCycles(Map<String, Object?> trace) {
  final graph = <int, List<int>>{};
  final node = trace['node'];
  final labels = node is Map<String, Object?> ? node['label'] : null;
  if (labels is List<Object?>) {
    for (var i = 0; i < labels.length; i++) {
      graph[i] = <int>[];
    }
  }
  final link = trace['link'];
  if (link is Map<String, Object?>) {
    final values = link['value'];
    final sources = link['source'];
    final targets = link['target'];
    if (values is List<Object?> &&
        sources is List<Object?> &&
        targets is List<Object?>) {
      for (var i = 0; i < values.length; i++) {
        final s = i < sources.length ? sources[i] : null;
        final t = i < targets.length ? targets[i] : null;
        if (isInvalidValue(values[i]) ||
            isInvalidValue(s) ||
            isInvalidValue(t)) {
          continue;
        }
        // `isInvalidValue` (`:172-174`) admits any non-null that is not a
        // non-finite number, so a string index reaches `:343` — where JS
        // coerces it to an object key and the port would throw on the cast.
        // Skipping is the same outcome as upstream's `graph[...]` being
        // `undefined`, which throws there and invalidates the trace at `:454`.
        if (s is! num || t is! num) {
          continue;
        }
        graph[s.toInt()]?.add(t.toInt());
      }
    }
  }

  final visited = <int>{};
  final stack = <int>{};

  bool dfs(int n) {
    final edges = graph[n];
    if (edges == null) {
      return false;
    }
    if (stack.contains(n)) {
      return true;
    }
    if (visited.contains(n)) {
      return false;
    }
    visited.add(n);
    stack.add(n);
    for (final next in edges) {
      if (dfs(next)) {
        return true;
      }
    }
    stack.remove(n);
    return false;
  }

  for (var i = 0; i < graph.length; i++) {
    if (dfs(i)) {
      return true;
    }
  }
  return false;
}

/// `PlotlySchemaConverter.ts:250-257`.
void _validateSeriesData(Map<String, Object?> trace, {required bool numericY}) {
  if (!validate2DSeries(trace)) {
    throw const PlotlySchemaException('Invalid 2D series encountered.');
  }
  if (numericY && !isNumberArray(trace['y'])) {
    throw const PlotlySchemaException('Non numeric Y values encountered.');
  }
}

/// `PlotlySchemaConverter.ts:259-291`.
void _validateBar(Map<String, Object?> trace) {
  final x = trace['x'];
  final y = trace['y'];
  final xEmpty = x is List<Object?> && x.isEmpty;
  final yEmpty = y is List<Object?> && y.isEmpty;
  if (xEmpty || yEmpty) {
    final what = xEmpty && yEmpty
        ? 'both x and y arrays are empty.'
        : xEmpty
        ? 'x array is empty.'
        : 'y array is empty.';
    throw PlotlySchemaException('Bar chart: $what');
  }
  if (trace['orientation'] == 'h') {
    if (!isNumberArray(x) && !isDateArray(x)) {
      throw PlotlySchemaException(
        '$_unsupportedPrefix ${trace['type']}, orientation: h, '
        'string x values not supported.',
      );
    }
    if (!canMapToGantt(trace) && isDateArray(x)) {
      throw PlotlySchemaException(
        '$_unsupportedPrefix ${trace['type']}, orientation: h, '
        'date x values not supported in HBWA.',
      );
    }
    _validateSeriesData(trace, numericY: false);
  } else if (!isNumberArray(y) && !isStringArray(y) && !isObjectArray(y)) {
    // parity break: upstream prints JavaScript's `typeof data.y`, which is
    // `'object'` for every array and therefore says nothing. The Dart runtime
    // type is the same field, named usefully.
    throw PlotlySchemaException(
      'Non numeric, string, or object Y values encountered, '
      'type: ${y?.runtimeType}',
    );
  }
}

/// `PlotlySchemaConverter.ts:296-320`.
void _validateScatter(
  Map<String, Object?> trace,
  Map<String, Object?>? layout,
) {
  final mode = _mode(trace);
  final x = trace['x'];
  if (!isNumberArray(x) && !isStringArray(x) && !isDateArray(x)) {
    throw PlotlySchemaException(
      '$_unsupportedPrefix ${trace['type']}, mode: $mode, xAxisType',
    );
  }
  if (!isNumberArray(trace['y']) && !isStringArray(trace['y'])) {
    throw PlotlySchemaException(
      '$_unsupportedPrefix ${trace['type']}, mode: $mode, yAxisType',
    );
  }
  final isArea = isScatterAreaChart(trace);
  final needsFallback = doesScatterNeedFallback(trace, layout);
  if (isArea && needsFallback) {
    throw PlotlySchemaException(
      '$_unsupportedPrefix ${trace['type']}, Fallback to '
      'VerticalStackedBarChart is not allowed for Area Charts.',
    );
  }
  if (isArea && _invalidateLogAxis(trace, layout)) {
    throw PlotlySchemaException(
      '$_unsupportedPrefix ${trace['type']}, log axis type not supported for '
      'AreaChart.',
    );
  }
  if (needsFallback && _invalidateLogAxis(trace, layout)) {
    throw PlotlySchemaException(
      '$_unsupportedPrefix ${trace['type']}, log axis type not supported for '
      'VSBC fallback.',
    );
  }
}

/// Runs every validator registered for [trace]'s type.
///
/// `PlotlySchemaConverter.ts:385-445`. A type with no entry in the table is
/// waved through; the router rejects it later on the `default` branch of the
/// mapping switch.
void validatePlotlyTrace(
  Map<String, Object?> trace,
  Map<String, Object?>? layout,
) {
  switch (trace['type']) {
    case 'indicator':
      final mode = trace['mode'];
      if (mode is! String || !mode.contains('gauge')) {
        throw PlotlySchemaException(
          '$_unsupportedPrefix indicator, mode: $mode',
        );
      }
    case 'histogram':
      if (_invalidateLogAxis(trace, layout)) {
        throw const PlotlySchemaException(
          '$_unsupportedPrefix histogram, log axis type not supported.',
        );
      }
      _validateSeriesData(trace, numericY: false);
    case 'bar':
      if (_invalidateLogAxis(trace, layout)) {
        throw const PlotlySchemaException(
          '$_unsupportedPrefix bar, log axis type not supported.',
        );
      }
      _validateBar(trace);
    case 'sankey':
      if (findSankeyCycles(trace)) {
        throw const PlotlySchemaException(
          '$_unsupportedPrefix sankey, Cycles in Sankey chart not supported',
        );
      }
    case 'scatter':
    case 'scattergl':
      _validateScatter(trace, layout);
    case 'scatterpolar':
      if (!isNumberArray(trace['theta']) && !isStringArray(trace['theta'])) {
        throw const PlotlySchemaException(
          '$_unsupportedPrefix scatterpolar, theta values must be array of '
          'numbers or strings',
        );
      }
      if (!isNumberArray(trace['r'])) {
        throw const PlotlySchemaException(
          '$_unsupportedPrefix scatterpolar, Non numeric r values',
        );
      }
    case 'funnel':
      _validateSeriesData(trace, numericY: false);
    case 'histogram2d':
    case 'heatmap':
      if (_invalidateLogAxis(trace, layout)) {
        throw PlotlySchemaException(
          '$_unsupportedPrefix ${trace['type']}, log axis type not supported.',
        );
      }
  }
}

/// One surviving trace and the kind it maps to.
@immutable
class FluentPlotlyTraceInfo {
  /// Creates a trace record.
  const FluentPlotlyTraceInfo({required this.index, required this.kind});

  /// Index into the **original** `data` array, not the filtered one
  /// (`PlotlySchemaConverter.ts:600`).
  final int index;

  /// The chart kind this trace alone maps to.
  final FluentPlotlyChartKind kind;

  @override
  bool operator ==(Object other) =>
      other is FluentPlotlyTraceInfo &&
      other.index == index &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(index, kind);

  @override
  String toString() =>
      'FluentPlotlyTraceInfo($index, ${plotlyChartKindName(kind)})';
}

/// The result of routing a Plotly figure.
///
/// `OutputChartType` at `PlotlySchemaConverter.ts:28-36`.
@immutable
class FluentPlotlyRoute {
  /// Creates a route.
  const FluentPlotlyRoute({
    required this.isValid,
    this.errorMessage,
    this.kind,
    this.traces = const <FluentPlotlyTraceInfo>[],
  });

  /// Whether at least one trace survived validation.
  final bool isValid;

  /// The joined validator messages when [isValid] is false.
  final String? errorMessage;

  /// The figure-level chart kind, null when invalid.
  final FluentPlotlyChartKind? kind;

  /// Per-trace kinds, in original-index order.
  final List<FluentPlotlyTraceInfo> traces;
}

/// `hasAnnotationContent` at `PlotlySchemaConverter.ts:207-213`.
///
/// A non-array is content, because `:212` only counts the length of something
/// that is one.
bool _hasAnnotationContent(Object? annotations) {
  if (annotations == null) {
    return false;
  }
  if (annotations is! List<Object?>) {
    return true;
  }
  return annotations.isNotEmpty;
}

/// Validates the top-level shape of a figure (`PlotlySchemaConverter.ts:215-248`).
///
/// A figure with no traces is admitted when the layout carries annotations,
/// because `AnnotationOnlyChart` is a legitimate output.
Map<String, Object?> getValidSchema(Object? input) {
  if (input == null) {
    throw const PlotlySchemaException(
      'Invalid plotly schema: Plotly input is null or undefined',
    );
  }
  if (input is! Map<String, Object?>) {
    throw PlotlySchemaException(
      'Invalid plotly schema: Plotly input is not an object. '
      'Input type: ${input.runtimeType}',
    );
  }
  final layout = input['layout'];
  final hasAnnotations =
      layout is Map<String, Object?> &&
      _hasAnnotationContent(layout['annotations']);
  final data = input['data'];
  if (data is! List<Object?>) {
    if (hasAnnotations) {
      return <String, Object?>{...input, 'data': <Object?>[]};
    }
    throw const PlotlySchemaException(
      'Invalid plotly schema: Plotly input data is not a valid array or '
      'typed array',
    );
  }
  if (data.isEmpty) {
    if (hasAnnotations) {
      return <String, Object?>{...input, 'data': <Object?>[]};
    }
    throw const PlotlySchemaException(
      'Invalid plotly schema: Plotly input data is empty',
    );
  }
  return input;
}

/// The `bar` arm of the mapping switch (`PlotlySchemaConverter.ts:523-543`).
///
/// Null is the `{isValid: false}` return at `:538`, the one arm of the switch
/// that rejects a trace it has already validated.
FluentPlotlyChartKind? _mapBar(
  Map<String, Object?> trace,
  Map<String, Object?>? layout,
) {
  if (trace['orientation'] == 'h') {
    return canMapToGantt(trace)
        ? FluentPlotlyChartKind.gantt
        : FluentPlotlyChartKind.horizontalBar;
  }
  if (isObjectArray(trace['y'])) {
    return FluentPlotlyChartKind.groupedVerticalBar;
  }
  if (const <String>['group', 'overlay'].contains(layout?['barmode'])) {
    // `PlotlySchemaConverter.ts:537-539` rejects a non-numeric y for GVBC.
    if (!isNumberArray(trace['y'])) {
      return null;
    }
    return FluentPlotlyChartKind.groupedVerticalBar;
  }
  return FluentPlotlyChartKind.verticalStackedBar;
}

/// The `scatter`/`scattergl` arm (`PlotlySchemaConverter.ts:547-576`).
///
/// [foundScatterGantt] is read and written, because `:552` latches it for the
/// invisible companion trace plotly.py emits after the corner trace.
FluentPlotlyChartKind _mapScatter(
  Map<String, Object?> trace,
  Map<String, Object?>? layout, {
  required bool foundScatterGantt,
  required void Function() onScatterGantt,
}) {
  if (isScatterGanttChart(trace, foundScatterGantt: foundScatterGantt)) {
    onScatterGantt();
    return FluentPlotlyChartKind.gantt;
  }
  if (_isScatterMarkers(_mode(trace))) {
    final shapes = layout?['shapes'];
    final hasLineShape =
        shapes is List<Object?> &&
        shapes.any((s) => s is Map<String, Object?> && s['type'] == 'line');
    return hasLineShape && supportedScatterInLineChart(trace, layout)
        ? FluentPlotlyChartKind.line
        : FluentPlotlyChartKind.scatter;
  }
  if (!doesScatterNeedFallback(trace, layout)) {
    return isScatterAreaChart(trace)
        ? FluentPlotlyChartKind.area
        : FluentPlotlyChartKind.line;
  }
  // `:574-575` notes that an area chart can never reach here: validateScatter
  // throws when both isScatterAreaChart and doesScatterNeedFallback hold.
  return FluentPlotlyChartKind.fallback;
}

/// Routes a Plotly figure to one chart kind and a per-trace kind list.
///
/// `PlotlySchemaConverter.ts:477-646`, branch for branch. Three composite rules
/// run after the per-trace switch, in this order (`:605-642`): lines plus bars
/// resolve to grouped-vertical-bar unless any stacked bar is present, in which
/// case fallback; lines plus a fallback resolve to fallback; more than one
/// surviving kind resolves to composite.
FluentPlotlyRoute mapFluentChart(Object? input) {
  // `:479` calls `sanitizeJson` for its throw alone and discards the result,
  // so only the depth guard is observable here. The escaping half of
  // `sanitizePlotlyJson` is a fresh copy in the port rather than upstream's
  // in-place rewrite, and this function returns a route, not a schema — the
  // transformers escape the copy they read.
  try {
    validatePlotlyJsonDepth(input);
  } on PlotlySchemaException catch (e) {
    return FluentPlotlyRoute(
      isValid: false,
      errorMessage: 'Invalid JSON: ${e.message}',
    );
  }

  final Map<String, Object?> schema;
  try {
    schema = decodeBase64Fields(getValidSchema(input));
  } on PlotlySchemaException catch (e) {
    return FluentPlotlyRoute(isValid: false, errorMessage: e.message);
  }

  final layout = schema['layout'] is Map<String, Object?>
      ? schema['layout']! as Map<String, Object?>
      : null;
  final data = schema['data']! as List<Object?>;
  final hasAnnotations = _hasAnnotationContent(layout?['annotations']);

  if (data.isEmpty) {
    // `:494-499`. getValidSchema only returns an empty data array when the
    // layout carries annotations, so the second arm is unreachable through it
    // and is kept for a caller that hands this an already-validated schema.
    if (hasAnnotations) {
      return const FluentPlotlyRoute(
        isValid: true,
        kind: FluentPlotlyChartKind.annotation,
      );
    }
    return const FluentPlotlyRoute(
      isValid: false,
      errorMessage: 'Plotly input data is empty',
    );
  }

  // `getValidTraces` at `:448-475`: one pass that validates and keeps the
  // original index.
  final errors = <String>[];
  final valid = <(int, Map<String, Object?>)>[];
  for (var i = 0; i < data.length; i++) {
    final trace = data[i];
    if (trace is! Map<String, Object?>) {
      continue;
    }
    try {
      validatePlotlyTrace(trace, layout);
      valid.add((i, trace));
    } on PlotlySchemaException catch (e) {
      errors.add('data[$i] - type: ${trace['type']}, ${e.message}');
    }
  }
  if (valid.isEmpty) {
    return FluentPlotlyRoute(isValid: false, errorMessage: errors.join('; '));
  }

  var foundScatterGantt = false;
  final mapped = <FluentPlotlyTraceInfo>[];
  final mapErrors = <String>[];
  for (final (index, trace) in valid) {
    final FluentPlotlyChartKind? kind;
    switch (trace['type']) {
      case 'pie':
        kind = FluentPlotlyChartKind.donut;
      case 'histogram2d':
      case 'heatmap':
        kind = FluentPlotlyChartKind.heatmap;
      case 'sankey':
        kind = FluentPlotlyChartKind.sankey;
      case 'indicator':
      case 'gauge':
        kind = FluentPlotlyChartKind.gauge;
      case 'histogram':
        // `PlotlySchemaConverter.ts:518`. The kind is absent from the
        // `FluentChart` union at `:4-20` but carries its own `chartMap` entry
        // and its own binning transformer (`DeclarativeChart.tsx:303-306`),
        // and it is the only route to that transformer.
        kind = FluentPlotlyChartKind.verticalBar;
      case 'scatterpolar':
        kind = FluentPlotlyChartKind.scatterPolar;
      case 'table':
        kind = FluentPlotlyChartKind.table;
      case 'bar':
        kind = _mapBar(trace, layout);
        if (kind == null) {
          mapErrors.add('GVBC does not support string y-axis.');
        }
      case 'funnel':
      case 'funnelarea':
        kind = FluentPlotlyChartKind.funnel;
      case 'scatter':
      case 'scattergl':
        kind = _mapScatter(
          trace,
          layout,
          foundScatterGantt: foundScatterGantt,
          onScatterGantt: () => foundScatterGantt = true,
        );
      default:
        kind = null;
        mapErrors.add('$_unsupportedPrefix ${trace['type']}');
    }
    if (kind != null) {
      mapped.add(FluentPlotlyTraceInfo(index: index, kind: kind));
    }
  }

  if (mapped.isEmpty) {
    // `:586-590` de-duplicates the messages and keeps first-seen order, which
    // is what a LinkedHashSet does.
    return FluentPlotlyRoute(
      isValid: false,
      errorMessage: mapErrors.toSet().join('; '),
    );
  }

  final kinds = mapped.map((t) => t.kind).toSet();
  final containsBars =
      kinds.contains(FluentPlotlyChartKind.groupedVerticalBar) ||
      kinds.contains(FluentPlotlyChartKind.verticalStackedBar);
  final containsLines =
      kinds.contains(FluentPlotlyChartKind.line) ||
      kinds.contains(FluentPlotlyChartKind.fallback);
  if (containsLines) {
    if (containsBars) {
      final useGvbc = !kinds.contains(FluentPlotlyChartKind.verticalStackedBar);
      return FluentPlotlyRoute(
        isValid: true,
        kind: useGvbc
            ? FluentPlotlyChartKind.groupedVerticalBar
            : FluentPlotlyChartKind.fallback,
        traces: mapped,
      );
    }
    if (kinds.contains(FluentPlotlyChartKind.fallback)) {
      return FluentPlotlyRoute(
        isValid: true,
        kind: FluentPlotlyChartKind.fallback,
        traces: mapped,
      );
    }
  }
  return FluentPlotlyRoute(
    isValid: true,
    kind: kinds.length > 1 ? FluentPlotlyChartKind.composite : kinds.first,
    traces: mapped,
  );
}
