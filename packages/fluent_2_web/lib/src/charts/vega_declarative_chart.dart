import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'chrome/legend.dart';
import 'internal/chart_utils.dart' show areArraysEqual;
import 'internal/data_viz_palette.dart' show fluentChartIsDarkTheme;
import 'internal/vega/common.dart';
import 'internal/vega/expression.dart';
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

/// The height a routed kind falls back to when the spec declares none.
///
/// Every shell chart takes its size from its `BoxConstraints` (spec §2.2), so
/// upstream's `height: spec.height ?? N` becomes this widget's `SizedBox`. Only
/// two shell kinds have a default at all: stacked bar
/// (`VegaLiteSchemaAdapter.ts:2712`) and heatmap (`:3510`). The other cartesian
/// kinds leave `height` undefined at `:1954`, `:3307` and `:3695`, so they size
/// to their constraints, and donut (`:3306-3307`) and polar (`:3856`) read
/// `height` inside their own transformers because neither is a shell chart.
const Map<FluentVegaChartKind, double> kVegaDefaultCellHeight =
    <FluentVegaChartKind, double>{
      FluentVegaChartKind.stackedBar: kVegaStackedBarDefaultHeight,
      FluentVegaChartKind.heatmap: 350,
    };

/// The kinds whose transformer reads `encoding.color.legend.disable`, and so
/// the kinds whose chart-owned legend this widget can suppress in favour of its
/// own.
///
/// Upstream suppresses generically: `VegaDeclarativeChart.tsx:238-240` writes
/// `hideLegend` into the transformed **props bag** after the transformer has
/// run. This port's transformers return typed widgets rather than props, so the
/// only switch left is the one every transformer already reads out of the spec
/// — `VegaLiteSchemaAdapter.ts:2325` (vertical bar), `:2713` (stacked bar),
/// `:2986` (horizontal bar), `:2213` (line and area), `:1938` (scatter) and
/// `:3855` (polar).
///
/// GAP, recorded rather than papered over: `transformVegaToGroupedBar`
/// (`:2819-2828`), `transformVegaToHistogram` (`:1954`) and
/// `transformVegaToDonut` (`:3301-3308`) pass no `hideLegend` at all, and the
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

/// Renders a Vega-Lite specification as the Fluent chart it routes to
/// (`VegaDeclarativeChart.tsx:389-528`).
///
/// The widget never paints. It guards the spec's depth, clones it,
/// auto-corrects its encoding types, routes it to one of eleven chart kinds and
/// hands it to that kind's transformer.
///
/// `hconcat` and `vconcat` (`:430-497`) are not read here: a concat spec falls
/// through to [getVegaChartType] like any other, which is what keeps it
/// rendering rather than crashing until the grid lands.
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
  /// container div (`ResponsiveContainer.tsx:97-103`) and the measure-and-inject
  /// cycle it wraps that div in is Flutter's constraint pass — spec §5.1.
  Widget _buildCell(
    FluentVegaChartKind kind,
    Map<String, Object?> spec, {
    required bool isDark,
  }) {
    final chart = _buildChart(kind, spec, isDark: isDark);
    final rawWidth = spec['width'];
    final rawHeight = spec['height'];
    final width = rawWidth is num ? rawWidth.toDouble() : null;
    final height = rawHeight is num
        ? rawHeight.toDouble()
        : kVegaDefaultCellHeight[kind];
    if (width == null && height == null) {
      return chart;
    }
    return SizedBox(width: width, height: height, child: chart);
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
      // `:500-512`: a layered spec that is not a bar-plus-line combination is
      // detected and then deliberately left alone, so only the first layer is
      // rendered. Reproduced, including the absence of any user-visible
      // warning. // parity: VegaDeclarativeChart.tsx:508-511
      //
      // `getVegaChartType` runs `autoCorrectEncodingTypes` itself (`:1650`), so
      // there is no separate correction pass to write here.
      final route = getVegaChartType(spec);

      // `:227-243`: upstream spreads `legendProps` — the selection AND its
      // change handler — into the chart it renders (`:417-426`), so the chart's
      // own legend both dims the marks and reports back. No shell chart in this
      // port takes a controlled selection except `FluentPolarChart`, and no
      // transformer passes one, so the round-trip through `onSchemaChange` is
      // only available from a legend this widget owns. The chart's own is
      // suppressed first so exactly one is drawn.
      //
      // GAP: the dimming upstream gets for free is lost with it. Closing it is
      // a `selectedLegends` parameter on the nine shell charts and on the
      // eleven transformers, not a change here.
      final canLift = kVegaLiftableLegendKinds.contains(route.kind);
      if (canLift) {
        _disableChartLegend(spec);
      }
      final chart = _buildCell(route.kind, spec, isDark: isDark);
      // AFTER the chart, unlike `:443`'s concat ordering: `getVegaColorFromMap`
      // is a cache seeded by whoever asks first (`VegaLiteColorAdapter.ts:275`)
      // and the shared-legend reader forwards neither the scheme nor the range
      // (`VegaLiteSchemaAdapter.ts:2029`). Asking it first would repaint a
      // `scheme: tableau10` chart in the plain qualitative cycle; asking it
      // second makes the lifted row agree with the marks.
      final legendProps = canLift
          ? getVegaLiteLegendsProps(spec, _colorMap, isDark: isDark)
          : null;
      body = legendProps == null || legendProps.legends.isEmpty
          ? chart
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                chart,
                FluentChartLegend(
                  // The items carry their RAW titles: `FluentChartLegend`
                  // title-cases for display itself (`chrome/legend.dart:359`,
                  // matching `useLegendsStyles.styles.ts:56`), and the
                  // selection it reports back is keyed on the title, so
                  // capitalising here would break the round-trip at `:406-411`.
                  legends: legendProps.legends,
                  // `:417`: `canSelectMultipleLegends: true`, which this port
                  // spells as a selection mode.
                  selectionMode: legendProps.canSelectMultipleLegends
                      ? FluentChartLegendSelectionMode.multiple
                      : FluentChartLegendSelectionMode.single,
                  selectedLegends: _activeLegends,
                  centerLegends: legendProps.centerLegends,
                  enabledWrapLines: legendProps.enabledWrapLines,
                  onChange: (selected, current) =>
                      _onActiveLegendsChange(selected),
                ),
              ],
            );
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
