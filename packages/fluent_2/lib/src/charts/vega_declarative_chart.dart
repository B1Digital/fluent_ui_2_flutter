import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'chrome/legend.dart';
import 'internal/chart_utils.dart' show areArraysEqual;
import 'internal/data_viz_palette.dart' show fluentChartIsDarkTheme;
import 'internal/vega/common.dart';
import 'internal/vega/expression.dart';
import 'internal/vega/js_value.dart' show jsTruthy;
import 'internal/vega/routing.dart';
import 'internal/vega/spec.dart';
import 'internal/vega/transform_bar.dart';
import 'internal/vega/transform_line.dart';
import 'internal/vega/transform_other.dart';
import 'vega_declarative_chart_style.dart';

/// A Vega-Lite specification plus the legend titles currently selected.
///
/// `vegaLiteSpec` is decoded JSON rather than a generated class hierarchy, for
/// the reason the Vega-Lite schema itself gives: it is hundreds of lines of
/// TypeScript declarations of which a few dozen keys are ever read, and
/// [autoCorrectEncodingTypes] rewrites the encoding in place.
@immutable
class FluentVegaSchema {
  /// Creates a schema wrapper.
  const FluentVegaSchema({
    required this.vegaLiteSpec,
    this.selectedLegends = const <String>[],
  });

  /// The decoded specification (`VegaDeclarativeChart.tsx:391`).
  final Map<String, Object?> vegaLiteSpec;

  /// The legend titles the user has selected (`VegaDeclarativeChart.tsx:391`,
  /// defaulted to `[]`).
  final List<String> selectedLegends;

  @override
  bool operator ==(Object other) =>
      other is FluentVegaSchema &&
      // Identity on the spec, matching `FluentPlotlySchema`: a deep comparison
      // of a spec holding thousands of rows on every rebuild is the wrong
      // trade.
      identical(other.vegaLiteSpec, vegaLiteSpec) &&
      areArraysEqual(other.selectedLegends, selectedLegends);

  @override
  int get hashCode =>
      Object.hash(identityHashCode(vegaLiteSpec), selectedLegends.length);
}

/// Supplies a default [FluentVegaDeclarativeChartStyle] to the subtree.
class FluentVegaDeclarativeChartTheme extends InheritedWidget {
  /// Creates a Vega declarative-chart theme.
  const FluentVegaDeclarativeChartTheme({
    required this.style,
    required super.child,
    super.key,
  });

  /// The style every descendant [FluentVegaDeclarativeChart] merges beneath its
  /// own.
  final FluentVegaDeclarativeChartStyle style;

  /// The nearest style, or null when no theme is in scope.
  static FluentVegaDeclarativeChartStyle? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<FluentVegaDeclarativeChartTheme>()
          ?.style;

  @override
  bool updateShouldNotify(FluentVegaDeclarativeChartTheme oldWidget) =>
      oldWidget.style != style;
}

/// The kinds whose cell is sized from the spec, and the height each falls back
/// to when the spec declares none.
///
/// Every shell chart takes its size from its `BoxConstraints` (spec §2.2), so
/// upstream's `height: spec.height ?? N` becomes this widget's `SizedBox` —
/// but only for the transformers that write a `height` at all. **Membership is
/// the whole point of this table**: a kind absent from it is a kind whose
/// props bag carries no dimensions, and sizing its cell from `spec.height`
/// invents a box upstream does not have.
///
/// `grep -nE '^\s*(width|height)[:,]'` over `VegaLiteSchemaAdapter.ts` returns
/// five pairs and no more:
///
///  * `:1953-1954`, line — and the area chart that spreads its props at
///    `:3053-3056` — pass a declared size straight through with NO default, so
///    both are present here with a null height.
///  * `:2711-2712` (stacked bar) and `:3509-3510` (heatmap) default to
///    `DEFAULT_CHART_HEIGHT`, 350 at `:74`.
///  * `:3306-3307` (donut) and `:3855-3856` (polar, whose 400 is the only
///    other literal) are not shell charts: each reads `height` inside its own
///    transformer, so neither belongs here.
///
/// The six that write neither are vertical bar (`:2141`), grouped vertical bar
/// (`:2741`), horizontal bar (`:2841`), scatter (`:3070`) and histogram
/// (`:3566`) — `ScatterChart.tsx:137-139` says so in as many words, "height and
/// width are not used to resize or set as dimesions of the chart" — and their
/// container div is `withResponsiveContainer`'s `height: props.height ?? '100%'`
/// (`ResponsiveContainer.tsx:96`), i.e. their parent's height. In Flutter that
/// is the incoming constraint, so their cell is handed through unwrapped.
const Map<FluentVegaChartKind, double?> kVegaDefaultCellHeight =
    <FluentVegaChartKind, double?>{
      FluentVegaChartKind.line: null,
      FluentVegaChartKind.area: null,
      FluentVegaChartKind.stackedBar: kVegaStackedBarDefaultHeight,
      FluentVegaChartKind.heatmap: 350,
    };

/// The kinds whose transformer reads `encoding.color.legend.disable`, and so
/// the kinds whose chart-owned legend this widget can suppress in favour of its
/// own.
///
/// Upstream suppresses generically: `VegaDeclarativeChart.tsx:238-239` writes
/// `hideLegend` into the transformed **props bag** after the transformer has
/// run, and only a concat sub-spec ever sets the `_hideLegend` flag it reads
/// (`:472`). This port's transformers return typed widgets rather than props,
/// so the only switch left is the one seven of them already read out of the
/// spec — `VegaLiteSchemaAdapter.ts:1975` (line, and the area chart built on
/// it), `:2325` (vertical bar), `:2713` (stacked bar), `:2989` (horizontal
/// bar), `:3212` (scatter) and `:3857` (polar), all of them
/// `encoding.color?.legend?.disable ?? false`.
///
/// GAP, recorded rather than papered over: `transformVegaToGroupedBar`
/// (`:2817-2827`), `transformVegaToHistogram` (`:3682-3694`) and
/// `transformVegaToDonut` (`:3300-3309`) return no `hideLegend` at all, and the
/// heatmap hard-codes `hideLegend: true` (`:3511`) so it has no legend to lift.
/// For those four the chart keeps whatever legend upstream's transformer gives
/// it, and the selection does not round-trip through
/// [FluentVegaDeclarativeChart.onSchemaChange]. Closing it means the
/// transformers taking the selection through to the shell charts, which is a
/// change to their signatures and to nine widgets, not to this file.
const Set<FluentVegaChartKind> kVegaLiftableLegendKinds = <FluentVegaChartKind>{
  FluentVegaChartKind.line,
  FluentVegaChartKind.area,
  FluentVegaChartKind.scatter,
  FluentVegaChartKind.bar,
  FluentVegaChartKind.stackedBar,
  FluentVegaChartKind.horizontalBar,
  FluentVegaChartKind.polar,
};

/// The gap between concat cells — `gap: '16px'`
/// (`VegaDeclarativeChart.tsx:451`).
const double kVegaConcatGap = 16;

/// The sub-specs of a concat spec and the axis they run along, or null when
/// [spec] declares neither concat (`VegaDeclarativeChart.tsx:100-145`).
///
/// `isHConcatSpec` and `isVConcatSpec` (`:100-110`) both demand a NON-EMPTY
/// array, and `getVegaConcatGridProperties` tests hconcat first (`:118`), so a
/// spec declaring both runs horizontally. The `templateRows`/`templateColumns`
/// halves of that function are CSS-grid track lists and map to nothing here: a
/// `Row` of `Expanded` cells already IS `repeat(n, 1fr)` and a `Column` of
/// intrinsic-height cells already IS `repeat(n, auto)`.
({List<Map<String, Object?>> specs, bool isHorizontal})? vegaConcatSpecs(
  Map<String, Object?> spec,
) {
  for (final (key, isHorizontal) in const <(String, bool)>[
    ('hconcat', true),
    ('vconcat', false),
  ]) {
    final raw = spec[key];
    if (raw is List<Object?> && raw.isNotEmpty) {
      return (
        specs: <Map<String, Object?>>[
          // A non-object entry keeps its cell rather than vanishing from the
          // grid, which is what upstream's `{...entry}` does with one.
          for (final sub in raw)
            if (sub is Map<String, Object?>) sub else const <String, Object?>{},
        ],
        isHorizontal: isHorizontal,
      );
    }
  }
  return null;
}

/// One concat sub-spec merged onto its parent
/// (`VegaDeclarativeChart.tsx:463-473`).
///
/// `_hideLegend` (`:472`) is not carried in the map: this port has no props bag
/// for `renderSingleChart` to write it into, so the caller applies the same
/// spec-level switch the single-chart path uses.
Map<String, Object?> mergeVegaConcatSubSpec(
  Map<String, Object?> parent,
  Map<String, Object?> sub,
) {
  final parentEncoding = parent['encoding'];
  final subEncoding = sub['encoding'];
  final parentHeight = parent['height'];
  final subHeight = sub['height'];
  return <String, Object?>{
    // `:464`. Shallow, as upstream's spread is: every channel object below is
    // shared with the parent and with the sibling cells, so
    // `autoCorrectEncodingTypes` corrects them once for all of them.
    ...sub,
    // `:465`: `||`, so a falsy `data` falls through to the parent's.
    'data': jsTruthy(sub['data']) ? sub['data'] : parent['data'],
    // `:466-469`: the parent first, so the child wins per channel.
    'encoding': <String, Object?>{
      if (parentEncoding is Map<String, Object?>) ...parentEncoding,
      if (subEncoding is Map<String, Object?>) ...subEncoding,
    },
    // `:456-461` folded into `:470`. The outer test is on the CHILD, and the
    // inner default reaches for the parent before its own final 300 (`:461`),
    // so the effective order is child, parent, 300 — never the routed kind's
    // entry in [kVegaDefaultCellHeight], because this key is always a number.
    'height': switch ((subHeight, parentHeight)) {
      (final num height, _) => height,
      (_, final num height) => height,
      _ => 300,
    },
  };
}

/// Renders a Vega-Lite specification as the Fluent chart it routes to
/// (`VegaDeclarativeChart.tsx:389-528`).
///
/// The widget never paints. It guards the spec's depth, clones it,
/// auto-corrects its encoding types, routes it to one of eleven chart kinds and
/// hands it to that kind's transformer.
///
/// An `hconcat` or `vconcat` spec (`:430-497`) is routed cell by cell instead,
/// each cell merged onto the parent by [mergeVegaConcatSubSpec], and one shared
/// legend is drawn below the grid.
class FluentVegaDeclarativeChart extends StatefulWidget {
  /// Creates a Vega declarative chart.
  const FluentVegaDeclarativeChart({
    required this.chartSchema,
    super.key,
    this.onSchemaChange,
    this.style,
    this.errorBuilder,
    this.semanticLabel,
  });

  /// The specification to render.
  final FluentVegaSchema chartSchema;

  /// Called with the new schema whenever the legend selection changes
  /// (`VegaDeclarativeChart.tsx:406-411`).
  final ValueChanged<FluentVegaSchema>? onSchemaChange;

  /// Overrides resolved style properties, highest precedence.
  final FluentVegaDeclarativeChartStyle? style;

  /// Renders the failure surface for an unroutable specification.
  ///
  /// Upstream re-throws (`VegaDeclarativeChart.tsx:394`, `:523`). A throw
  /// inside a Flutter `build()` is a red screen for the whole application, so
  /// the message is rendered instead — and unlike upstream's blanket re-throw
  /// the original stack is not discarded, because nothing is re-wrapped.
  final Widget Function(BuildContext context, String message)? errorBuilder;

  /// The accessibility label for the whole chart.
  ///
  /// Defaults to the spec's own `description` (`VegaLiteTypes.ts:697`), which
  /// the upstream adapter declares and never reads. Surfacing it is a real
  /// accessibility win and falls under spec §5.2's exception, so it is added
  /// rather than reproduced as a gap.
  final String? semanticLabel;

  @override
  State<FluentVegaDeclarativeChart> createState() =>
      _FluentVegaDeclarativeChartState();
}

class _FluentVegaDeclarativeChartState
    extends State<FluentVegaDeclarativeChart> {
  /// The shared legend-to-colour map. Created once per widget, because its
  /// contents are a cache keyed on the legend name
  /// (`VegaLiteColorAdapter.ts:275-283`) and every sub-chart of a concat must
  /// agree.
  final Map<String, String> _colorMap = <String, String>{};

  List<String> _activeLegends = const <String>[];

  /// Read by the widget test; a private State needs no doc comment, but this
  /// getter is deliberately part of the tested surface.
  List<String> get activeLegends => _activeLegends;

  @override
  void initState() {
    super.initState();
    _activeLegends = widget.chartSchema.selectedLegends;
  }

  @override
  void didUpdateWidget(FluentVegaDeclarativeChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `:413-415`: the effect depends on `props.chartSchema.selectedLegends`
    // ALONE, a narrower dependency than the Plotly widget's `props.chartSchema`
    // at `DeclarativeChart.tsx:410` — so a new spec with the same selection
    // does not reset here, and the colour map deliberately survives it.
    if (!areArraysEqual(
      oldWidget.chartSchema.selectedLegends,
      widget.chartSchema.selectedLegends,
    )) {
      setState(() => _activeLegends = widget.chartSchema.selectedLegends);
    }
  }

  void _onActiveLegendsChange(List<String> keys) {
    setState(() => _activeLegends = keys);
    // `:406-411`.
    widget.onSchemaChange?.call(
      FluentVegaSchema(
        vegaLiteSpec: widget.chartSchema.vegaLiteSpec,
        selectedLegends: keys,
      ),
    );
  }

  /// Dispatches one spec to its transformer
  /// (`VegaDeclarativeChart.tsx:189-210`).
  ///
  /// Exhaustive over [FluentVegaChartKind], so a new kind is a compile error
  /// rather than upstream's runtime `Unsupported chart type` at `:231`.
  Widget _buildChart(
    FluentVegaChartKind kind,
    Map<String, Object?> spec, {
    required bool isDark,
  }) => switch (kind) {
    // `:190`.
    FluentVegaChartKind.line => transformVegaToLine(
      spec,
      _colorMap,
      isDark: isDark,
    ),
    // `:191`.
    FluentVegaChartKind.bar => transformVegaToVerticalBar(
      spec,
      _colorMap,
      isDark: isDark,
    ),
    // `:192-195`.
    FluentVegaChartKind.stackedBar => transformVegaToStackedBar(
      spec,
      _colorMap,
      isDark: isDark,
    ),
    // `:196-199`.
    FluentVegaChartKind.groupedBar => transformVegaToGroupedBar(
      spec,
      _colorMap,
      isDark: isDark,
    ),
    // `:200-203`.
    FluentVegaChartKind.horizontalBar => transformVegaToHorizontalBar(
      spec,
      _colorMap,
      isDark: isDark,
    ),
    // `:204`.
    FluentVegaChartKind.area => transformVegaToArea(
      spec,
      _colorMap,
      isDark: isDark,
    ),
    // `:205`.
    FluentVegaChartKind.scatter => transformVegaToScatter(
      spec,
      _colorMap,
      isDark: isDark,
    ),
    // `:206`.
    FluentVegaChartKind.donut => transformVegaToDonut(
      spec,
      _colorMap,
      isDark: isDark,
    ),
    // `:207`.
    FluentVegaChartKind.heatmap => transformVegaToHeatmap(
      spec,
      _colorMap,
      isDark: isDark,
    ),
    // `:208`: the histogram shares the vertical bar renderer.
    FluentVegaChartKind.histogram => transformVegaToHistogram(
      spec,
      _colorMap,
      isDark: isDark,
    ),
    // `:209`.
    FluentVegaChartKind.polar => transformVegaToPolar(
      spec,
      _colorMap,
      isDark: isDark,
    ),
  };

  /// One routed cell, sized.
  ///
  /// `:151-160` wraps every renderer in `withResponsiveContainer`. Nothing
  /// stands in for that here and nothing needs to: the box below IS its
  /// container div (`ResponsiveContainer.tsx:97-103`) and the
  /// measure-and-inject cycle it wraps that div in is Flutter's constraint
  /// pass — spec §5.1.
  ///
  /// A kind outside [kVegaDefaultCellHeight] is handed through UNWRAPPED, and
  /// that is not a shortcut: its transformer forwards neither dimension, so the
  /// container div stays at `100%` and the chart's own shell decides. Sizing it
  /// from `spec.height` is what made the scatter story 400 tall against
  /// upstream's 350.
  Widget _buildCell(
    FluentVegaChartKind kind,
    Map<String, Object?> spec, {
    required bool isDark,
  }) {
    final chart = _buildChart(kind, spec, isDark: isDark);
    if (!kVegaDefaultCellHeight.containsKey(kind)) {
      return chart;
    }
    final rawWidth = spec['width'];
    final rawHeight = spec['height'];
    final width = rawWidth is num ? rawWidth.toDouble() : null;
    final height = rawHeight is num
        ? rawHeight.toDouble()
        : kVegaDefaultCellHeight[kind];
    if (width == null && height == null) {
      return chart;
    }
    // `Align` so the declared size actually survives: upstream lays the cell
    // out in normal flow, where a `height` shrinks the box, and a bare
    // `SizedBox` under this widget's tight incoming constraints is stretched
    // back to the parent's height instead. Align takes the tight box itself and
    // hands the child a loose one.
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(width: width, height: height, child: chart),
    );
  }

  /// Turns off the chart-owned legend of every colour channel in [spec].
  ///
  /// The port's stand-in for `VegaDeclarativeChart.tsx:238-240`, which sets
  /// `hideLegend` on the transformed props; see [kVegaLiftableLegendKinds] for
  /// why the switch has to travel in the spec instead. Every layer is written
  /// because `normalizeVegaSpec` (`VegaLiteSchemaAdapter.ts:578-585`) lets a
  /// layer's own channel win over the shared one, so writing only the top level
  /// would leave a layered spec's legend on. [spec] is always the clone.
  void _disableChartLegend(Map<String, Object?> spec) {
    final layer = spec['layer'];
    for (final unit in <Object?>[
      spec,
      ...?layer is List<Object?> ? layer : null,
    ]) {
      if (unit is! Map<String, Object?>) {
        continue;
      }
      final encoding = unit['encoding'];
      if (encoding is! Map<String, Object?>) {
        continue;
      }
      final colour = encoding['color'];
      if (colour is Map<String, Object?>) {
        colour['legend'] = <String, Object?>{'disable': true};
      }
    }
  }

  /// The routed chart with the lifted legend row beneath it, or the chart
  /// alone when there is nothing to lift.
  Widget _withSharedLegend(Widget chart, FluentVegaLegendProps? legendProps) {
    if (legendProps == null || legendProps.legends.isEmpty) {
      return chart;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // The row below stands in for the one the chart's own shell would have
        // drawn inside itself, so it has to come out of the same box:
        // `CartesianChart.tsx:499-508` subtracts the legend strip from the
        // container height before the svg is sized, and the shell's Column does
        // the same with an `Expanded` plot. `Flexible` rather than `Expanded`
        // because this Column is `min` and can be laid out unbounded — inside a
        // scroll view a flexible child is laid out as an inflexible one, where
        // an `Expanded` would throw.
        Flexible(child: chart),
        FluentChartLegend(
          // The items carry their RAW titles: `FluentChartLegend` title-cases
          // for display itself (`chrome/legend.dart:359`, matching
          // `useLegendsStyles.styles.ts:56`), and the selection it reports back
          // is keyed on the title, so capitalising here would break the
          // round-trip at `:406-411`.
          legends: legendProps.legends,
          // `:418`: `canSelectMultipleLegends: true`, which this port spells as
          // a selection mode.
          selectionMode: legendProps.canSelectMultipleLegends
              ? FluentChartLegendSelectionMode.multiple
              : FluentChartLegendSelectionMode.single,
          selectedLegends: _activeLegends,
          centerLegends: legendProps.centerLegends,
          enabledWrapLines: legendProps.enabledWrapLines,
          onChange: (selected, current) => _onActiveLegendsChange(selected),
        ),
      ],
    );
  }

  /// The single-spec path (`VegaDeclarativeChart.tsx:499-521`).
  Widget _buildSingle(Map<String, Object?> spec, {required bool isDark}) {
    // `:498-512`: a layered spec that is not a bar-plus-line combination is
    // detected and then deliberately left alone, so only the first layer is
    // rendered. Reproduced, including the absence of any user-visible
    // warning. // parity: VegaDeclarativeChart.tsx:506-511
    //
    // `getVegaChartType` runs `autoCorrectEncodingTypes` itself (`:1650`), so
    // there is no separate correction pass to write here.
    final route = getVegaChartType(spec);

    // `:227-243`: upstream spreads `legendProps` — the selection AND its
    // change handler — into the chart it renders (`:417-426`, `:243`), so
    // the chart's own legend both dims the marks and reports back. Only
    // `FluentPolarChart` exposes `onLegendChange`, so no other shell reports a
    // selection back and the round-trip through `onSchemaChange` is available
    // only from a legend this widget owns. The chart's own is suppressed first
    // so exactly one is drawn.
    //
    // GAP: the dimming upstream gets for free is lost with it, and it is a
    // wider gap than this note claimed twice. Re-measured 2026-08-12 by
    // grepping every widget constructor rather than every file: only
    // `FluentAreaChart` (`area_chart.dart:45`, added with the Plotly adapter's
    // dimming) and `FluentPolarChart` (`polar_chart.dart:1036`) declare a
    // `selectedLegends` parameter at all. The `selectedLegends` in the other
    // eight charts is on their DELEGATE, written only by their own shell's
    // `onLegendChange`, so a transformer has nowhere to put a caller's
    // selection. Closing the dimming is therefore the parameter on eight
    // widgets plus a pass-through in eleven transformers, not a change here.
    // NOT lifted on this path. `:494` renders the shared `<Legends>` inside the
    // CONCAT branch only, and `:472` is the sole writer of the `_hideLegend`
    // flag `:238` reads, so a single spec keeps the chart's own legend —
    // circular swatches for a scatter (`ScatterChart.tsx:279`), left-aligned,
    // and in the series order `Object.keys` produced. Lifting one here drew a
    // centred strip of square swatches in first-seen order instead.

    final chart = _buildCell(route.kind, spec, isDark: isDark);
    // AFTER the chart, unlike `:443`'s concat ordering: `getVegaColorFromMap`
    // is a cache seeded by whoever asks first (`VegaLiteColorAdapter.ts:275`)
    // and the shared-legend reader forwards neither the scheme nor the range
    // (`VegaLiteSchemaAdapter.ts:2029`). Asking it first would repaint a
    // `scheme: tableau10` chart in the plain qualitative cycle; asking it
    // second makes the lifted row agree with the marks.
    return chart;
  }

  /// The concat grid and the one legend shared by its cells
  /// (`VegaDeclarativeChart.tsx:430-497`).
  ///
  /// // ponytail: `minWidth: 0` at `:486` is a CSS-grid workaround for a
  /// min-content floor that Flutter's `Expanded` does not have, so it maps to
  /// nothing.
  ///
  /// // parity: VegaDeclarativeChart.tsx:423-426 spreads one componentRef
  /// across every concat sub-chart, so the last one to mount wins. Reproduced
  /// because nothing in this component reads the handle —
  /// `FluentVegaDeclarativeChart` exposes no componentRef and no image export,
  /// and no transformer takes one, so there is no handle here to share or to
  /// clobber.
  Widget _buildConcat(
    Map<String, Object?> spec,
    ({List<Map<String, Object?>> specs, bool isHorizontal}) concat, {
    required bool isDark,
  }) {
    // `:454`, in order, because each cell's transformer seeds `_colorMap` for
    // the next one.
    final merged = <Map<String, Object?>>[
      for (final sub in concat.specs) mergeVegaConcatSubSpec(spec, sub),
    ];
    final cells = <Widget>[];
    for (final cellSpec in merged) {
      final route = getVegaChartType(cellSpec);
      // `:472` marks EVERY sub-spec `_hideLegend`, which `:237-240` turns into
      // `hideLegend` on the props. This port's stand-in is the spec-level
      // switch the single path uses, so the four kinds outside
      // [kVegaLiftableLegendKinds] keep the legend their transformer gives
      // them — the gap that constant already records.
      if (kVegaLiftableLegendKinds.contains(route.kind)) {
        _disableChartLegend(cellSpec);
      }
      final cell = _buildCell(route.kind, cellSpec, isDark: isDark);
      // `:449-450` and `:475-476`: hconcat is `repeat(n, 1fr)` across one row,
      // vconcat one column of `auto` rows.
      cells.add(concat.isHorizontal ? Expanded(child: cell) : cell);
    }

    final grid = concat.isHorizontal
        ? Row(
            spacing: kVegaConcatGap,
            // The grid's default `align-items: stretch` puts every cell's top
            // on the row line; a cell keeps the height `:470` gave it, so the
            // alignment is `start` rather than Flutter's `stretch`, which
            // would force the cross axis tight and override that height.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cells,
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: kVegaConcatGap,
            children: cells,
          );

    // `:442`: the shared legend is read from sub-spec zero alone. Read after
    // the cells for the colour-map reason `_buildSingle` records, which is the
    // one place this port departs from `:442`'s ordering; `:434-441` differs
    // from the merge above only in the `height` key, which
    // `getVegaLiteLegendsProps` does not read.
    return _withSharedLegend(
      grid,
      getVegaLiteLegendsProps(merged.first, _colorMap, isDark: isDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final style = resolveFluentVegaDeclarativeChartStyle(
      theme,
      themeStyle: FluentVegaDeclarativeChartTheme.maybeOf(context),
      widgetStyle: widget.style,
    );
    // `VegaDeclarativeChartHooks.ts:1-29`: the HSL lightness of the neutral
    // tokens, not Flutter's `Brightness` — the same predicate the Plotly widget
    // uses.
    final isDark = fluentChartIsDarkTheme(theme.colors);

    final Widget body;
    try {
      // `:393-395`: an absent spec is fatal upstream. A `Map` cannot be absent
      // here, so the guard that survives is the depth one at `:398`.
      final rawSpec = widget.chartSchema.vegaLiteSpec;
      validateVegaJsonDepth(rawSpec);
      // `hardened:` `VegaLiteSchemaAdapter.ts:1553` and `:1606-1610` write the
      // corrected `type` and the flattened rows back into the spec they were
      // handed. Cloning first means the caller's own object survives a rebuild
      // unchanged, which a `const` spec in a widget tree requires.
      final spec = deepCloneVegaSpec(rawSpec);
      // `:429-430`: the concat test comes first, so a concat spec never reaches
      // `getChartType` at all — each of its cells is routed on its own merged
      // spec instead.
      final concat = vegaConcatSpecs(spec);
      body = concat == null
          ? _buildSingle(spec, isDark: isDark)
          : _buildConcat(spec, concat, isDark: isDark);
    } on VegaSpecException catch (error) {
      return _error(context, style, error.message);
    } on VegaExpressionException catch (error) {
      // A hostile or malformed `calculate`/`filter` expression surfaces the
      // same way rather than escaping as an unrelated crash.
      return _error(context, style, error.message);
    }

    // `VegaLiteTypes.ts:697`.
    final description = widget.chartSchema.vegaLiteSpec['description'];
    return Semantics(
      container: true,
      label:
          widget.semanticLabel ?? (description is String ? description : null),
      child: body,
    );
  }

  Widget _error(
    BuildContext context,
    FluentVegaDeclarativeChartStyle style,
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
