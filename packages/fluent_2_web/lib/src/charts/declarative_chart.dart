import 'dart:convert';
import 'dart:typed_data';

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'chrome/legend.dart';
import 'declarative_chart_style.dart';
import 'internal/chart_utils.dart' show areArraysEqual;
import 'internal/data_viz_palette.dart' show fluentChartIsDarkTheme;
import 'internal/image_export.dart' show FluentChartImageExporter;
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

/// Drives image export for a [FluentDeclarativeChart]
/// (`DeclarativeChart.tsx:433-473`).
///
/// Attach one controller to one chart. The chart registers itself on mount and
/// deregisters on unmount, so [exportAsImage] throws rather than returning a
/// blank image when it is called before the first frame.
///
/// **One deliberate simplification, and it deletes the compositor.** Upstream
/// branches at `:445`: a single plot delegates to `chartRefs[0].compRef.toImage`
/// (`:446-450`) and a multi-plot figure hands every cell's DOM container to
/// `exportChartsAsImage` (`:453-462` → `image-export-utils.ts:31-80`), which
/// re-lays the cells out on one canvas and rebuilds the HTML legend as SVG.
/// It has to, because each cell is a separate SVG element and the legend is not
/// an SVG at all. A Flutter grid is already one layer tree with the real legend
/// painted inside it, so a single [RepaintBoundary] round the whole `Column`
/// captures what those 46 lines reassemble — and it captures a one-cell figure
/// just as well, so there is no branch left to write.
/// // ponytail: one boundary, no compositor and no cell registry; restore the
/// // per-cell path only if cells ever stop sharing a layer tree.
///
/// Two consequences worth stating rather than discovering:
///
///  * [FluentChartHandle] is not consulted. No shell chart implements it — the
///    ones that expose an export handle (`FluentPolarChart`, `FluentSankeyChart`)
///    do it through a `FluentChartController` parameter, and the transformers in
///    `internal/plotly/` construct their charts without one. A `_registerHandle`
///    type-test against the built widget would therefore have matched nothing,
///    ever, which is precisely the uncalled-helper defect this programme keeps
///    shipping.
///  * `FluentSynthesisedLegendPainter` (`internal/image_export.dart`) is not
///    reached from here, because the legend inside the boundary is the real one.
///    It is still live for a single chart whose legend sits outside its own
///    boundary — `FluentPolarChart` and `FluentSankeyChart` both go that way —
///    so it is not dead and must not be deleted as such.
class FluentDeclarativeChartController extends ChangeNotifier {
  /// Creates a detached controller.
  FluentDeclarativeChartController();

  _FluentDeclarativeChartState? _state;

  void _attach(_FluentDeclarativeChartState state) {
    _state = state;
    notifyListeners();
  }

  void _detach(_FluentDeclarativeChartState state) {
    if (identical(_state, state)) {
      _state = null;
    }
  }

  /// Rasterises the chart as PNG bytes.
  ///
  /// The defaults are the resolved style's
  /// [FluentDeclarativeChartStyle.exportBackgroundColor] and
  /// [FluentDeclarativeChartStyle.exportScale] (`DeclarativeChart.tsx:439-441`);
  /// [options], when given, replaces them. That is a narrow divergence from
  /// upstream's `{background, scale: 5, ...opts}` spread:
  /// [FluentChartImageExportOptions] has non-nullable `scale` and `background`,
  /// so an options object built without a scale carries 1 rather than "absent".
  /// A fully transparent `background` is still read as unset, because that is
  /// its own default and no caller asks for a transparent export deliberately.
  ///
  /// Throws a [StateError] carrying upstream's own message when nothing is
  /// registered (`DeclarativeChart.tsx:436`, `:447`).
  Future<Uint8List> exportAsImage({
    FluentChartImageExportOptions? options,
  }) async {
    final state = _state;
    if (state == null) {
      // `:436`'s null container and `:447`'s missing handle collapse to one
      // condition here, because a mounted state always has both.
      throw StateError('Chart cannot be exported as image');
    }
    return state.exportAsImage(options);
  }

  @override
  void dispose() {
    _state = null;
    super.dispose();
  }
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
/// `:1772` (GVBC), `:1892` (the histogram's vertical bar chart), `:2172`
/// (area, line, scatter), `:2263` (HBWA), `:2382` (gantt), `:2613` (heatmap)
/// and `:2709` (sankey). The shell-free kinds are absent because their
/// transformers take `height` directly.
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
      FluentPlotlyChartKind.verticalBar: 350,
      FluentPlotlyChartKind.verticalStackedBar: 350,
    };

/// Renders a Plotly figure as the Fluent chart it routes to
/// (`DeclarativeChart.tsx:357-637`).
///
/// The widget itself never paints. It sanitises the schema, routes it to one of
/// the chart kinds, groups the traces by axis key, lays the groups out in a
/// grid and hands each group to its transformer.
///
/// One upstream behaviour is not reproduced, recorded here rather than
/// silently dropped: `:412-420` builds a `legendProps` bag —
/// `canSelectMultipleLegends`, the selection and its change handler — and
/// `:598-603` spreads it into every non-annotation chart, so a **single**-plot
/// figure round-trips its legend selection through `onSchemaChange` too. Only
/// `FluentPolarChart` exposes `onLegendChange`, so no other shell can report a
/// selection back and the outbound half has nowhere to start. `selectedLegends`
/// is a different matter, and this note used to conflate the two: eight of the
/// ten shell charts already take it — all but `FluentLineChart` and
/// `FluentHeatMapChart` — and no transformer in either adapter passes it, so
/// the inbound half is unwired rather than unavailable. The all-up legend of a
/// multi-plot figure does round-trip, because this widget owns that legend.
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

  /// Wraps the whole grid, so any export is one rasterisation rather than a
  /// composite of several — see [FluentDeclarativeChartController].
  final GlobalKey _boundaryKey = GlobalKey();

  /// The last resolved style, so [exportAsImage] can read the export defaults
  /// without a [BuildContext] of its own.
  ///
  /// // ponytail: a build-time cache for the export path only; it is never read
  /// // during layout, so no `setState` is involved and no frame is scheduled.
  FluentDeclarativeChartStyle _style = const FluentDeclarativeChartStyle();

  @override
  void initState() {
    super.initState();
    _activeLegends = widget.chartSchema.selectedLegends;
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(FluentDeclarativeChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
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

  @override
  void dispose() {
    widget.controller?._detach(this);
    super.dispose();
  }

  /// `DeclarativeChart.tsx:433-465`.
  Future<Uint8List> exportAsImage(
    FluentChartImageExportOptions? options,
  ) async {
    const noStates = <WidgetState>{};
    // `:440`: `colorNeutralBackground1`, resolved from the theme rather than
    // from live CSS variables. Fully transparent black is what an unset
    // `background` computes to, here and in `FluentChartImageExportOptions`.
    const transparent = Color(0x00000000);
    final resolved = FluentChartImageExportOptions(
      width: options?.width,
      height: options?.height,
      // `:441`: the fallback is 5, applied only when the caller passes nothing.
      scale: options?.scale ?? _style.exportScale?.resolve(noStates) ?? 5,
      background: options == null || options.background.a == 0
          ? _style.exportBackgroundColor?.resolve(noStates) ?? transparent
          : options.background,
    );
    // `:445-461`, both arms collapsed onto the one boundary. The legend list is
    // empty because the on-screen legend is already inside it; passing
    // `allupLegends` here would draw a second, synthesised copy underneath.
    final dataUrl = await FluentChartImageExporter(
      boundaryKey: _boundaryKey,
      legends: const <FluentChartLegendItem>[],
    ).toImage(resolved);
    // `FluentChartImageExporter.toImage` returns `data:image/png;base64,…`;
    // this controller's contract is the raw bytes.
    final comma = dataUrl.indexOf(',');
    if (comma < 0) {
      throw StateError('Chart cannot be exported as image');
    }
    return base64Decode(dataUrl.substring(comma + 1));
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
      case FluentPlotlyChartKind.verticalBar:
        // `:303-306`: the one `chartMap` entry that bins, reached only by a
        // `histogram` trace (`PlotlySchemaConverter.ts:517-518`).
        return transformPlotlyToVbc(
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

  /// The degenerate-grid collapse.
  ///
  /// `DeclarativeChart.tsx:510-533`: when a multi-plot figure produces a
  /// one-by-one grid there is nowhere to put the other groups, so all but one
  /// is dropped — the LAST for a donut (`:516-523`, "picking the last one
  /// similar to plotly") and the FIRST for everything else (`:525-530`) — and
  /// `isMultiPlot` is forced back to false at `:532`, which is what suppresses
  /// the figure title at `:561` and the all-up legend at `:634`.
  ///
  /// **Port note:** `:513-514` compares the two formatted CSS strings against
  /// `SINGLE_REPEAT`, which is what [FluentPlotlyGridProperties.isSingleRepeat]
  /// carries. It is deliberately not `grid.rowCount == 1 && grid.columnCount ==
  /// 1`: that also reads true for a figure whose grid solved no domain at all,
  /// where both templates keep the `1fr` seeded at
  /// `PlotlySchemaAdapter.ts:3654-3655` and upstream renders every group.
  ({Map<String, List<int>> groups, bool isMultiPlot}) collapseDegenerateGrid(
    Map<String, List<int>> groups, {
    required bool isMultiPlot,
    required FluentPlotlyGridProperties grid,
    required FluentPlotlyChartKind kind,
  }) {
    if (!isMultiPlot || !grid.isSingleRepeat) {
      return (groups: groups, isMultiPlot: isMultiPlot);
    }
    final key = kind == FluentPlotlyChartKind.donut
        ? groups.keys.last
        : groups.keys.first;
    return (groups: <String, List<int>>{key: groups[key]!}, isMultiPlot: false);
  }

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
    _style = style;
    Widget body;
    try {
      body = _buildFigure(context, style, isDark: isDark);
    } on PlotlySchemaException catch (error) {
      // Upstream throws at `:364` and `:370`. The catch is wider than those two
      // sites on purpose: `getGridProperties` rejects a malformed layout
      // (`PlotlySchemaAdapter.ts:3670`) and every transformer re-validates its
      // own traces, and any of those inside `build()` is a red screen for the
      // whole application.
      body = _error(context, style, error.message);
    }
    // The boundary sits outside the try so it exists on the failure surface
    // too: an export of an unroutable figure then returns the rendered message
    // rather than reporting a missing container.
    return RepaintBoundary(key: _boundaryKey, child: body);
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
      // Fifteen of the sixteen renderers are `withResponsiveContainer(...)`
      // upstream (`:72-87`; `FunnelChart` is exempted at `:85-86`), and nothing
      // stands in for that HOC here. It has no work left to do: the box above
      // IS its container div (`ResponsiveContainer.tsx:97-103`), and the
      // measure-and-inject cycle it wraps that div in is Flutter's constraint
      // pass — see the design document, section 5.1.
      cells.add((cellProperties?.row ?? 1, cellProperties?.column ?? 1, sized));
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
      if (cells.length <= 1) {
        return cells.isEmpty ? const SizedBox.shrink() : cells.first.$3;
      }
      // parity: a figure whose grid solved no domain gives every group the
      // `row 1 / column 1` fallback at `DeclarativeChart.tsx:623-624`, and
      // `:162-165` turns that into the same one-cell grid area for all of
      // them — the same React `key` at `:160` included. CSS grid paints them
      // over one another rather than growing a row, and a `Stack` is that.
      // Only reachable since the collapse became `SINGLE_REPEAT`-exact; the
      // predicate it replaced folded this case away.
      return Stack(children: <Widget>[for (final cell in cells) cell.$3]);
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
