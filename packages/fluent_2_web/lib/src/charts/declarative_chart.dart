import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'chrome/legend.dart';
import 'declarative_chart_style.dart';
import 'internal/chart_utils.dart' show areArraysEqual;
import 'internal/data_viz_palette.dart' show fluentChartIsDarkTheme;
import 'internal/plotly/axis.dart' show kDefaultPolarSubplot;
import 'internal/plotly/base64_data.dart';
import 'internal/plotly/color_adapter.dart';
import 'internal/plotly/common.dart';
import 'internal/plotly/grid.dart';
import 'internal/plotly/json_guard.dart';
import 'internal/plotly/legends.dart';
import 'internal/plotly/predicates.dart';
import 'internal/plotly/router.dart';
import 'internal/plotly/transform_bar.dart';
import 'internal/plotly/transform_pie.dart';
import 'internal/plotly/transform_xy.dart';
import 'internal/responsive.dart';
import 'model/chart_common.dart';

/// A Plotly figure plus the legend titles currently selected.
///
/// `plotlySchema` is decoded JSON, not a generated class hierarchy: Plotly's own
/// schema is thousands of lines of TypeScript declarations of which roughly 120
/// keys are ever read, and `decodeBase64Fields` rewrites the map wholesale. A
/// `Map<String, Object?>` is the exact shape both facts want.
@immutable
class FluentPlotlySchema {
  /// Creates a schema wrapper.
  const FluentPlotlySchema({
    required this.plotlySchema,
    this.selectedLegends = const <String>[],
  });

  /// The decoded Plotly figure: `data`, `layout`, and nothing else is read.
  final Map<String, Object?> plotlySchema;

  /// The legend titles the user has selected
  /// (`DeclarativeChart.tsx:382`, defaulted to `[]` at `:391-393` when the
  /// caller passes a non-array).
  final List<String> selectedLegends;

  @override
  bool operator ==(Object other) =>
      other is FluentPlotlySchema &&
      // Identity on the map, because `didUpdateWidget` upstream keys its reset
      // on the `props.chartSchema` reference (`DeclarativeChart.tsx:410`), not
      // on a deep comparison of a figure that can hold thousands of points.
      identical(other.plotlySchema, plotlySchema) &&
      areArraysEqual(other.selectedLegends, selectedLegends);

  @override
  int get hashCode =>
      Object.hash(identityHashCode(plotlySchema), selectedLegends.length);
}

/// Holds the exported-image handle for a [FluentDeclarativeChart].
///
/// The image export itself is a later task; this one declares only what
/// [FluentDeclarativeChart.controller] needs in order to compile and to record
/// the branch the export path reads.
class FluentDeclarativeChartController extends ChangeNotifier {
  /// Creates a detached controller.
  FluentDeclarativeChartController();

  /// The chart handles of the rendered cells, in row-major order
  /// (`DeclarativeChart.tsx:385`, `:615-621`).
  final List<({FluentChartHandle handle, int row, int col})> cells =
      <({FluentChartHandle handle, int row, int col})>[];

  /// True when the figure resolved to more than one plot
  /// (`DeclarativeChart.tsx:501`); the export path branches on it at `:445`.
  bool isMultiPlot = false;
}

/// Supplies a default [FluentDeclarativeChartStyle] to the subtree.
class FluentDeclarativeChartTheme extends InheritedWidget {
  /// Creates a declarative-chart theme.
  const FluentDeclarativeChartTheme({
    required this.style,
    required super.child,
    super.key,
  });

  /// The style every descendant [FluentDeclarativeChart] merges beneath its own.
  final FluentDeclarativeChartStyle style;

  /// The nearest style, or null when no theme is in scope.
  static FluentDeclarativeChartStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentDeclarativeChartTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentDeclarativeChartTheme oldWidget) =>
      oldWidget.style != style;
}

/// The default cell height per routed chart kind, in logical pixels.
///
/// Every shell chart takes its size from its `BoxConstraints` (spec §2.2), so
/// upstream's `height: input.layout?.height ?? N` becomes the cell's `SizedBox`.
/// The defaults are `PlotlySchemaAdapter.ts:1584` (VSBC and the fallback),
/// `:1772` (GVBC), `:2172` (area, line, scatter), `:2263` (HBWA), `:2382`
/// (gantt), `:2613` (heatmap) and `:2709` (sankey). The shell-free kinds are
/// absent because their transformers take `height` directly.
///
/// `:1892`'s 350 for the vertical bar chart has no entry, because
/// [FluentPlotlyChartKind] spells no `verticalBar` — see
/// [FluentDeclarativeChart] for why that route is still closed.
const Map<FluentPlotlyChartKind, double> kPlotlyDefaultCellHeight =
    <FluentPlotlyChartKind, double>{
      FluentPlotlyChartKind.area: 350,
      FluentPlotlyChartKind.fallback: 350,
      FluentPlotlyChartKind.gantt: 350,
      FluentPlotlyChartKind.groupedVerticalBar: 350,
      FluentPlotlyChartKind.heatmap: 350,
      FluentPlotlyChartKind.horizontalBar: 450,
      FluentPlotlyChartKind.line: 350,
      FluentPlotlyChartKind.sankey: 468,
      FluentPlotlyChartKind.scatter: 350,
      FluentPlotlyChartKind.verticalStackedBar: 350,
    };

/// Renders a Plotly figure as the Fluent chart it routes to
/// (`DeclarativeChart.tsx:357-637`).
///
/// The widget itself never paints. It sanitises the schema, routes it to one of
/// the chart kinds, groups the traces by axis key, lays the groups out in a
/// grid and hands each group to its transformer.
///
/// Two upstream behaviours are not reproduced, both recorded here rather than
/// silently dropped:
///
/// * `:412-420` builds a `legendProps` bag — `canSelectMultipleLegends`, the
///   selection and its change handler — and `:598-603` spreads it into every
///   non-annotation chart, so a **single**-plot figure round-trips its legend
///   selection through `onSchemaChange` too. In this port only the polar chart
///   exposes `selectedLegends`/`onLegendChange` as widget parameters; the other
///   shells keep the selection in private state, so there is nothing to pass it
///   to. The all-up legend of a multi-plot figure does round-trip, because this
///   widget owns that legend.
/// * `:518` routes a `histogram` trace to `'verticalbar'`, which
///   [FluentPlotlyChartKind] does not spell — `internal/plotly/router.dart:707`
///   records that divergence and sends a histogram to the stacked bar instead.
///   There is therefore no `verticalBar` arm below.
class FluentDeclarativeChart extends StatefulWidget {
  /// Creates a declarative chart.
  const FluentDeclarativeChart({
    required this.chartSchema,
    super.key,
    this.onSchemaChange,
    this.colorwayType = FluentPlotlyColorway.byDefault,
    this.controller,
    this.style,
    this.errorBuilder,
  });

  /// The figure to render.
  final FluentPlotlySchema chartSchema;

  /// Called with the new schema whenever the legend selection changes
  /// (`DeclarativeChart.tsx:396-401`).
  final ValueChanged<FluentPlotlySchema>? onSchemaChange;

  /// How schema colours are translated (`DeclarativeChart.tsx:360` defaults to
  /// `'default'`).
  final FluentPlotlyColorway colorwayType;

  /// Exposes the rendered cells for image export.
  final FluentDeclarativeChartController? controller;

  /// Overrides resolved style properties, highest precedence.
  final FluentDeclarativeChartStyle? style;

  /// Renders the failure surface for an unroutable schema.
  ///
  /// Upstream throws (`DeclarativeChart.tsx:364`, `:370`). A throw inside a
  /// Flutter `build()` is a red screen for the whole application, which is a
  /// robustness regression rather than parity, so the message is rendered.
  final Widget Function(BuildContext context, String message)? errorBuilder;

  @override
  State<FluentDeclarativeChart> createState() => _FluentDeclarativeChartState();
}

class _FluentDeclarativeChartState extends State<FluentDeclarativeChart> {
  /// The shared legend-to-colour map. Created once, because its insertion order
  /// IS the palette index (`PlotlyColorAdapter.ts:127`).
  final PlotlyColorMap _colorMap = <String, String>{};

  List<String> _activeLegends = const <String>[];

  /// Read by the widget test; a private State class needs no doc comment, but
  /// the getter is deliberately part of the tested surface.
  List<String> get activeLegends => _activeLegends;

  @override
  void initState() {
    super.initState();
    _activeLegends = widget.chartSchema.selectedLegends;
  }

  @override
  void didUpdateWidget(FluentDeclarativeChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `DeclarativeChart.tsx:403-410`: the effect depends on `props.chartSchema`,
    // so a new schema identity re-reads `selectedLegends` and resets to `[]`
    // when it is absent.
    if (!identical(oldWidget.chartSchema, widget.chartSchema)) {
      setState(() {
        _activeLegends = widget.chartSchema.selectedLegends;
        _colorMap.clear();
      });
    }
  }

  void _onActiveLegendsChange(List<String> keys) {
    setState(() => _activeLegends = keys);
    // `DeclarativeChart.tsx:396-401`.
    widget.onSchemaChange?.call(
      FluentPlotlySchema(
        plotlySchema: widget.chartSchema.plotlySchema,
        selectedLegends: keys,
      ),
    );
  }

  /// `DeclarativeChart.tsx:170-189`, the `line`/`area`/`scatter` pre-transform:
  /// a month-name x column is rewritten to real dates before transforming.
  Map<String, Object?> _lineAreaPreTransform(Map<String, Object?> input) {
    final data = input['data'];
    if (data is! List<Object?> || data.isEmpty) {
      return input;
    }
    final first = data.first;
    final xValues = first is Map<String, Object?> ? first['x'] : null;
    if (!isMonthArray(xValues)) {
      return input;
    }
    return <String, Object?>{
      ...input,
      'data': <Object?>[
        for (final series in data)
          if (series is Map<String, Object?>)
            <String, Object?>{...series, 'x': correctYearMonth(series['x'])}
          else
            series,
      ],
    };
  }

  /// Dispatches one group to its transformer (`DeclarativeChart.tsx:262-338`).
  ///
  /// `FluentPlotlyChartKind.composite` never arrives from a populated cell:
  /// each cell resolves its own kind from its first trace at `:578-581`, so the
  /// composite marker only ever describes the whole figure — and when it does
  /// reach here it lands on the same fallback arm upstream's missing `chartMap`
  /// entry would.
  Widget _buildChart(
    FluentPlotlyChartKind kind,
    Map<String, Object?> group, {
    required bool isMultiPlot,
    required bool isDark,
  }) {
    final colorMap = _colorMap;
    final colorwayType = widget.colorwayType;
    switch (kind) {
      case FluentPlotlyChartKind.annotation:
        return transformPlotlyToAnnotationOnly(
          group,
          isMultiPlot: isMultiPlot,
          colorMap: colorMap,
          colorwayType: colorwayType,
          isDark: isDark,
        );
      case FluentPlotlyChartKind.donut:
        return transformPlotlyToDonut(
          group,
          isMultiPlot: isMultiPlot,
          colorMap: colorMap,
          colorwayType: colorwayType,
          isDark: isDark,
        );
      case FluentPlotlyChartKind.sankey:
        return transformPlotlyToSankey(
          group,
          isMultiPlot: isMultiPlot,
          colorMap: colorMap,
          colorwayType: colorwayType,
          isDark: isDark,
        );
      case FluentPlotlyChartKind.table:
        return transformPlotlyToChartTable(
          group,
          isMultiPlot: isMultiPlot,
          colorMap: colorMap,
          colorwayType: colorwayType,
          isDark: isDark,
        );
      case FluentPlotlyChartKind.horizontalBar:
        return transformPlotlyToHbwa(
          group,
          isMultiPlot: isMultiPlot,
          colorMap: colorMap,
          colorwayType: colorwayType,
          isDark: isDark,
        );
      case FluentPlotlyChartKind.groupedVerticalBar:
        return transformPlotlyToGvbc(
          group,
          isMultiPlot: isMultiPlot,
          colorMap: colorMap,
          colorwayType: colorwayType,
          isDark: isDark,
        );
      case FluentPlotlyChartKind.heatmap:
        return transformPlotlyToHeatmap(
          group,
          isMultiPlot: isMultiPlot,
          colorMap: colorMap,
          colorwayType: colorwayType,
          isDark: isDark,
        );
      case FluentPlotlyChartKind.gauge:
        return transformPlotlyToGauge(
          group,
          isMultiPlot: isMultiPlot,
          colorMap: colorMap,
          colorwayType: colorwayType,
          isDark: isDark,
        );
      case FluentPlotlyChartKind.area:
        return transformPlotlyToArea(
          _lineAreaPreTransform(group),
          isMultiPlot: isMultiPlot,
          colorMap: colorMap,
          colorwayType: colorwayType,
          isDark: isDark,
        );
      case FluentPlotlyChartKind.line:
        return transformPlotlyToLine(
          _lineAreaPreTransform(group),
          isMultiPlot: isMultiPlot,
          colorMap: colorMap,
          colorwayType: colorwayType,
          isDark: isDark,
        );
      case FluentPlotlyChartKind.scatter:
        return transformPlotlyToScatter(
          _lineAreaPreTransform(group),
          isMultiPlot: isMultiPlot,
          colorMap: colorMap,
          colorwayType: colorwayType,
          isDark: isDark,
        );
      case FluentPlotlyChartKind.gantt:
        return transformPlotlyToGantt(
          group,
          isMultiPlot: isMultiPlot,
          colorMap: colorMap,
          colorwayType: colorwayType,
          isDark: isDark,
        );
      case FluentPlotlyChartKind.funnel:
        return transformPlotlyToFunnel(
          group,
          isMultiPlot: isMultiPlot,
          colorMap: colorMap,
          colorwayType: colorwayType,
          isDark: isDark,
        );
      case FluentPlotlyChartKind.scatterPolar:
        return transformPlotlyToPolar(
          group,
          isMultiPlot: isMultiPlot,
          colorMap: colorMap,
          colorwayType: colorwayType,
          isDark: isDark,
        );
      case FluentPlotlyChartKind.verticalStackedBar:
      case FluentPlotlyChartKind.fallback:
      case FluentPlotlyChartKind.composite:
        // `:334-337`: the fallback renders as a VSBC, and so does a composite.
        return transformPlotlyToVsbc(
          group,
          isMultiPlot: isMultiPlot,
          colorMap: colorMap,
          colorwayType: colorwayType,
          isDark: isDark,
          // `:335` binds the fallback entry to `transformPlotlyJsonToVSBCProps`
          // and PlotlySchemaAdapter.ts:1461 keys its scatter reading on this.
          isFallback: kind == FluentPlotlyChartKind.fallback,
        );
    }
  }

  /// The degenerate-grid collapse, a pass-through until the task that owns it
  /// lands.
  ///
  /// `DeclarativeChart.tsx:510-533`: when a multi-plot figure produces a
  /// one-by-one grid, all but one group is dropped — the LAST for a donut
  /// (`:516-523`) and the FIRST for everything else (`:525-530`) — and
  /// `isMultiPlot` is forced back to false at `:532`.
  ({Map<String, List<int>> groups, bool isMultiPlot}) collapseDegenerateGrid(
    Map<String, List<int>> groups, {
    required bool isMultiPlot,
    required FluentPlotlyGridProperties grid,
    required FluentPlotlyChartKind kind,
  }) => (groups: groups, isMultiPlot: isMultiPlot);

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final style = resolveFluentDeclarativeChartStyle(
      theme,
      themeStyle: FluentDeclarativeChartTheme.maybeOf(context),
      widgetStyle: widget.style,
    );
    // `DeclarativeChart.tsx:340-351`: the HSL lightness of the two neutral
    // tokens, NOT Flutter's `Brightness`.
    final isDark = fluentChartIsDarkTheme(theme.colors);
    try {
      return _buildFigure(context, style, isDark: isDark);
    } on PlotlySchemaException catch (error) {
      // Upstream throws at `:364` and `:370`. The catch is wider than those two
      // sites on purpose: `getGridProperties` rejects a malformed layout
      // (`PlotlySchemaAdapter.ts:3670`) and every transformer re-validates its
      // own traces, and any of those inside `build()` is a red screen for the
      // whole application.
      return _error(context, style, error.message);
    }
  }

  Widget _buildFigure(
    BuildContext context,
    FluentDeclarativeChartStyle style, {
    required bool isDark,
  }) {
    // `:361`.
    final sanitized = sanitizePlotlyJson(widget.chartSchema.plotlySchema);
    final schema = sanitized is Map<String, Object?>
        ? sanitized
        : const <String, Object?>{};
    // `:362-365`.
    final route = mapFluentChart(schema);
    if (!route.isValid) {
      return _error(
        context,
        style,
        route.errorMessage ??
            'Invalid chart '
                'schema',
      );
    }
    // `:367-371`.
    final plotlyInput = decodeBase64Fields(schema);

    // `:372-380`: the data list is reduced to the valid traces, and the trace
    // info is re-indexed against that reduced list.
    final rawData = plotlyInput['data'];
    final allData = rawData is List<Object?> ? rawData : const <Object?>[];
    final validData = <Object?>[
      for (final trace in route.traces)
        if (trace.index < allData.length) allData[trace.index],
    ];
    final input = <String, Object?>{...plotlyInput, 'data': validData};
    final traces = <FluentPlotlyTraceInfo>[
      for (var i = 0; i < route.traces.length; i++)
        FluentPlotlyTraceInfo(index: i, kind: route.traces[i].kind),
    ];
    final layoutRaw = input['layout'];
    final layout = layoutRaw is Map<String, Object?> ? layoutRaw : null;

    // `:475-498`: group by axis key. A non-plot kind gets its own synthetic key
    // so two donuts never share a cell; a polar trace groups by subplot.
    var groupedTraces = <String, List<int>>{};
    var nonCartesianTraceCount = 0;
    if (route.kind == FluentPlotlyChartKind.annotation) {
      // `:479-480`.
      groupedTraces[kDefaultXAxisKey] = <int>[];
    } else {
      for (
        var index = 0;
        index < validData.length && index < traces.length;
        index++
      ) {
        final trace = validData[index];
        final kind = traces[index].kind;
        final String traceKey;
        if (isNonPlotType(kind)) {
          nonCartesianTraceCount++;
          traceKey = '$kNonPlotKeyPrefix$nonCartesianTraceCount';
        } else if (kind == FluentPlotlyChartKind.scatterPolar) {
          final subplot = trace is Map<String, Object?>
              ? trace['subplot']
              : null;
          traceKey = subplot is String && subplot.isNotEmpty
              ? subplot
              : kDefaultPolarSubplot;
        } else {
          final xaxis = trace is Map<String, Object?> ? trace['xaxis'] : null;
          traceKey = xaxis is String && xaxis.isNotEmpty
              ? xaxis
              : kDefaultXAxisKey;
        }
        (groupedTraces[traceKey] ??= <int>[]).add(index);
      }
    }

    // `:501-507`.
    var isMultiPlot = groupedTraces.length > 1;
    final grid = getGridProperties(
      input,
      isMultiPlot: isMultiPlot,
      traces: traces,
    );
    final collapsed = collapseDegenerateGrid(
      groupedTraces,
      isMultiPlot: isMultiPlot,
      grid: grid,
      kind: route.kind ?? FluentPlotlyChartKind.fallback,
    );
    groupedTraces = collapsed.groups;
    isMultiPlot = collapsed.isMultiPlot;
    widget.controller?.isMultiPlot = isMultiPlot;

    // `:535-541`: BEFORE the render loop, because this is what seeds
    // `_colorMap`.
    final allupLegends = getAllupLegendsProps(
      validData,
      layout,
      traces,
      _colorMap,
      colorwayType: widget.colorwayType,
      isDark: isDark,
    );

    // `:571-631`: one cell per group, positioned by the grid layout.
    final cells = <(int row, int col, Widget child)>[];
    // `:585-588`: read once over the whole figure, not per cell.
    final figureKinds = <FluentPlotlyChartKind>{
      for (final trace in traces) trace.kind,
    };
    final mixesLineAndScatter =
        figureKinds.contains(FluentPlotlyChartKind.line) &&
        figureKinds.contains(FluentPlotlyChartKind.scatter);
    for (final entry in groupedTraces.entries) {
      final indices = entry.value;
      final group = <String, Object?>{
        ...input,
        'data': <Object?>[for (final index in indices) validData[index]],
      };
      // `:578-588`: the whole figure's kind wins for `fallback` and
      // `groupedVerticalBar`; otherwise the cell's first trace decides. A figure
      // mixing line and scatter renders entirely as a line chart.
      var kind =
          route.kind == FluentPlotlyChartKind.fallback ||
              route.kind == FluentPlotlyChartKind.groupedVerticalBar
          ? route.kind!
          : (indices.isEmpty
                ? route.kind ?? FluentPlotlyChartKind.fallback
                : traces[indices.first].kind);
      if (mixesLineAndScatter) {
        kind = FluentPlotlyChartKind.line;
      }

      final cellProperties = grid.layout[entry.key];
      final chart = _buildChart(
        kind,
        group,
        isMultiPlot: isMultiPlot,
        isDark: isDark,
      );
      final defaultHeight = kPlotlyDefaultCellHeight[kind];
      // The layout dimensions and the per-kind default reach a shell chart as a
      // `SizedBox`, per spec §2.2; the shell-free kinds are absent from the
      // table and size themselves.
      final sized = defaultHeight == null
          ? chart
          : SizedBox(
              width: (layout?['width'] as num?)?.toDouble(),
              height: (layout?['height'] as num?)?.toDouble() ?? defaultHeight,
              child: chart,
            );
      cells.add((
        cellProperties?.row ?? 1,
        cellProperties?.column ?? 1,
        // Every one of the renderers is wrapped upstream except `FunnelChart`
        // (`:85-86`). In Flutter the distinction has no effect — both paths
        // honour the same `BoxConstraints` — so funnel is wrapped too rather
        // than special-cased.
        FluentResponsiveChartHost(builder: (context, metrics) => sized),
      ));
    }

    final titles = getTitles(layout);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // `:561`: the figure title is drawn above the grid ONLY in a multi-plot
        // figure; a single plot draws its own title inside the chart.
        // `:552`'s `textAlign: 'center'` is applied here, because `TextStyle`
        // cannot carry an alignment.
        if (isMultiPlot && titles.chartTitle.isNotEmpty) ...<Widget>[
          Text(
            titles.chartTitle,
            textAlign: TextAlign.center,
            style: style.titleTextStyle?.resolve(const <WidgetState>{}),
          ),
          SizedBox(
            height: style.titleBottomSpacing?.resolve(const <WidgetState>{}),
          ),
        ],
        // `:562-569`: `display: grid` with `repeat(N, 1fr)` on both axes and no
        // gap. // ponytail: nested `Expanded` IS `1fr`; a
        // `CustomMultiChildLayout` would be a delegate for a job `Flex` does.
        _grid(grid, cells),
        // `:634`.
        if (isMultiPlot)
          FluentChartLegend(
            // `:412-413`: `canSelectMultipleLegends: true`, which this port
            // spells as a selection mode.
            selectionMode: allupLegends.canSelectMultipleLegends
                ? FluentChartLegendSelectionMode.multiple
                : FluentChartLegendSelectionMode.single,
            // The items carry their raw titles: `FluentChartLegend` title-cases
            // for display itself (`chrome/legend.dart:359`, matching
            // `useLegendsStyles.styles.ts:56`), and the selection this reports
            // back is keyed on `FluentChartLegendItem.title`, so capitalising
            // here would break the round-trip at `:396-401`.
            legends: allupLegends.legends,
            selectedLegends: _activeLegends,
            centerLegends: allupLegends.centerLegends,
            enabledWrapLines: allupLegends.enabledWrapLines,
            onChange: (selected, current) => _onActiveLegendsChange(selected),
          ),
      ],
    );
  }

  Widget _grid(
    FluentPlotlyGridProperties grid,
    List<(int, int, Widget)> cells,
  ) {
    if (grid.rowCount <= 1 && grid.columnCount <= 1) {
      return cells.isEmpty ? const SizedBox.shrink() : cells.first.$3;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var row = 1; row <= grid.rowCount; row++)
          Row(
            // Deliberately not `stretch`. Every cell already carries its own
            // height from `kPlotlyDefaultCellHeight`, and a stretched row
            // demands a bounded height it does not have inside a scroll view.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (var col = 1; col <= grid.columnCount; col++)
                Expanded(
                  child: _cellAt(cells, row, col) ?? const SizedBox.shrink(),
                ),
            ],
          ),
      ],
    );
  }

  Widget? _cellAt(List<(int, int, Widget)> cells, int row, int col) {
    for (final cell in cells) {
      if (cell.$1 == row && cell.$2 == col) {
        return cell.$3;
      }
    }
    return null;
  }

  Widget _error(
    BuildContext context,
    FluentDeclarativeChartStyle style,
    String message,
  ) {
    final builder = widget.errorBuilder;
    if (builder != null) {
      return builder(context, message);
    }
    return Text(
      message,
      style: style.errorTextStyle?.resolve(const <WidgetState>{}),
    );
  }
}
