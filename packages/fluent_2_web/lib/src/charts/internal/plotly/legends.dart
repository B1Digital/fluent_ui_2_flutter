/// The Plotly legend helpers.
///
/// Ports `PlotlySchemaAdapter.ts:3479-3487` (`getLegendShape`), `:3489-3567`
/// (`getAllupLegendsProps`) and `:3569-3586` (`getLegendProps`). Internal to
/// the package: nothing here is barrel-exported.
library;

import 'package:flutter/widgets.dart';

import '../../chrome/legend.dart';
import '../../chrome/legend_shape.dart';
import '../d3/color.dart' as d3;
import '../data_viz_palette.dart';
import 'color_adapter.dart';
import 'grid.dart';
import 'router.dart';

/// A resolved `#rrggbb` colour string as a [Color].
///
/// **Deviation:** the plan names `parseCssColour`, a `d3.color(...)` helper it
/// assigns to task 17 in `common.dart`; that task has not landed, so this is
/// the same two lines kept private here rather than a public symbol planted in
/// another task's file. Whoever lands `parseCssColour` deletes this.
///
/// Every string reaching it comes from [resolveColor] or [extractColor], which
/// return `D3Rgb.formatHex()` output, so the unparseable branch is defensive:
/// it takes the first qualitative colour rather than inventing a black swatch.
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

/// Chooses the swatch a legend entry draws (`PlotlySchemaAdapter.ts:3479-3487`).
///
/// Only the three short dash presets become a dotted-line swatch;
/// `PlotlySchemaAdapter.ts:3481` never lists `longdash` or `longdashdot`, so
/// both fall through to the marker test. // parity: PlotlySchemaAdapter.ts:3481
FluentChartLegendShape getLegendShape(Map<String, Object?> series) {
  final line = series['line'];
  final declaredDash = line is Map<String, Object?> ? line['dash'] : null;
  // `PlotlySchemaAdapter.ts:3480` defaults an absent or empty dash to `solid`.
  final dash = declaredDash is String && declaredDash.isNotEmpty
      ? declaredDash
      : 'solid';
  if (dash == 'dot' || dash == 'dash' || dash == 'dashdot') {
    return FluentChartLegendShape.dottedLine;
  }
  final mode = series['mode'];
  if (mode is String && mode.contains('markers')) {
    // `PlotlySchemaAdapter.ts:3483-3484`.
    return FluentChartLegendShape.circle;
  }
  // `PlotlySchemaAdapter.ts:3486`, upstream's literal `'default'`.
  return FluentChartLegendShape.defaultShape;
}

/// The legend configuration a multi-plot figure renders beneath its grid
/// (`PlotlySchemaAdapter.ts:3561-3566`).
@immutable
class FluentPlotlyLegendProps {
  /// Creates an all-up legend record.
  const FluentPlotlyLegendProps({
    required this.legends,
    required this.centerLegends,
    required this.enabledWrapLines,
    required this.canSelectMultipleLegends,
  });

  /// One entry per distinct legend title, in first-seen order
  /// (`PlotlySchemaAdapter.ts:3562`).
  final List<FluentChartLegendItem> legends;

  /// Always true upstream (`PlotlySchemaAdapter.ts:3563`).
  final bool centerLegends;

  /// Always true upstream (`PlotlySchemaAdapter.ts:3564`).
  final bool enabledWrapLines;

  /// Always true upstream (`PlotlySchemaAdapter.ts:3565`).
  final bool canSelectMultipleLegends;
}

/// Reads the `colorway` a layout template declares, if any.
///
/// `PlotlySchemaAdapter.ts:3509` and `:3544` both reach through
/// `layout.template.layout.colorway`.
List<String>? _templateColorway(Map<String, Object?>? layout) {
  final template = layout?['template'];
  final templateLayout = template is Map<String, Object?>
      ? template['layout']
      : null;
  final colorway = templateLayout is Map<String, Object?>
      ? templateLayout['colorway']
      : null;
  return _colorwayList(colorway);
}

/// Coerces a JSON colourway to `List<String>`, or null when it is not one.
List<String>? _colorwayList(Object? colorway) {
  if (colorway is! List<Object?>) return null;
  final out = <String>[];
  for (final entry in colorway) {
    if (entry is! String) return null;
    out.add(entry);
  }
  return out;
}

/// Builds the all-up legend for a multi-plot figure
/// (`PlotlySchemaAdapter.ts:3489-3567`).
///
/// Runs *before* every transformer (`DeclarativeChart.tsx:535` precedes the
/// render loop at `:571`), so the order in which this function touches
/// [colorMap] is the order every downstream chart then inherits. Do not add a
/// colour lookup that upstream does not make.
FluentPlotlyLegendProps getAllupLegendsProps(
  List<Object?> data,
  Map<String, Object?>? layout,
  List<FluentPlotlyTraceInfo> traces,
  PlotlyColorMap colorMap, {
  required FluentPlotlyColorway colorwayType,
  required bool isDark,
}) {
  final allupLegends = <FluentChartLegendItem>[];

  // `PlotlySchemaAdapter.ts:3498-3502`: a fold over every trace where one
  // `showlegend` that is true — or simply absent — draws the legend.
  var toShowLegend = false;
  for (final series in data) {
    final show = series is Map<String, Object?> ? series['showlegend'] : null;
    final declared =
        series is Map<String, Object?> && series.containsKey('showlegend');
    toShowLegend = toShowLegend || show == true || !declared;
  }

  if (toShowLegend) {
    final templateColorway = _templateColorway(layout);
    // `PlotlySchemaAdapter.ts:3509`: `piecolorway` wins over the template's.
    final pieColorway =
        _colorwayList(layout?['piecolorway']) ?? templateColorway;

    for (var index = 0; index < data.length && index < traces.length; index++) {
      final series = data[index];
      if (series is! Map<String, Object?>) continue;
      final kind = traces[index].kind;
      if (kind == FluentPlotlyChartKind.donut) {
        // `PlotlySchemaAdapter.ts:3506-3537`.
        final marker = series['marker'];
        final markerColors = marker is Map<String, Object?>
            ? marker['colors']
            : null;
        final colors = extractColor(
          pieColorway,
          colorwayType,
          layout?['piecolorway'] ?? markerColors,
          colorMap,
          isDark: isDark,
          isDonut: true,
        );
        final labels = series['labels'];
        if (labels is! List<Object?>) continue;
        for (var labelIndex = 0; labelIndex < labels.length; labelIndex++) {
          final legend = '${labels[labelIndex]}';
          // `PlotlySchemaAdapter.ts:3521-3529`: resolve before the dedupe test,
          // because resolving is what seeds `colorMap`.
          final colour = resolveColor(
            colors,
            labelIndex,
            legend,
            colorMap,
            pieColorway,
            isDark: isDark,
            isDonut: true,
          );
          if (legend.isEmpty ||
              allupLegends.any((group) => group.title == legend)) {
            // `PlotlySchemaAdapter.ts:3530`.
            continue;
          }
          allupLegends.add(
            FluentChartLegendItem(
              title: legend,
              color: _parseCssColour(colour, isDark: isDark),
            ),
          );
        }
      } else if (!isNonPlotType(kind)) {
        // `PlotlySchemaAdapter.ts:3538-3556`. The kind test is `grid.dart`'s
        // `isNonPlotType`, which is the same seven names upstream's own
        // `isNonPlotType` lists at `:3637-3639` — the plan wrote an exhaustive
        // switch here to avoid importing a file task 14 had not yet created,
        // but task 14 has landed and one of that switch's arms
        // (`FluentPlotlyChartKind.funnel`) is not a value the router's enum
        // spells, so the switch could not compile.
        final line = series['line'];
        final marker = series['marker'];
        final lineColor = line is Map<String, Object?> ? line['color'] : null;
        final markerColor = marker is Map<String, Object?>
            ? marker['color']
            : null;
        // `PlotlySchemaAdapter.ts:3541`: `||`, so an empty string falls to the
        // marker colour.
        final declared = lineColor == null || lineColor == ''
            ? markerColor
            : lineColor;
        final name = series['legendgroup'];
        final resolved = extractColor(
          templateColorway,
          colorwayType,
          declared,
          colorMap,
          isDark: isDark,
        );
        if (name is! String ||
            name.isEmpty ||
            allupLegends.any((group) => group.title == name)) {
          // `PlotlySchemaAdapter.ts:3550`: no `legendgroup`, no all-up entry.
          continue;
        }
        allupLegends.add(
          FluentChartLegendItem(
            title: name,
            // `PlotlySchemaAdapter.ts:3553` casts a possibly-undefined result
            // to `string`, so a trace with no declared colour and no schema
            // colourway pushes `color: undefined` and the swatch renders
            // unpainted. A Dart `Color` cannot be null, so the swatch takes
            // the qualitative cycle at the legend's own index — which is what
            // the chart beneath it will pick anyway — WITHOUT touching
            // `colorMap`, because touching it here would shift every
            // downstream colour by one. // parity: PlotlySchemaAdapter.ts:3553
            color: resolved is String
                ? _parseCssColour(resolved, isDark: isDark)
                : FluentDataVizPalette.next(
                    allupLegends.length,
                    isDark: isDark,
                  ),
            shape: getLegendShape(series),
          ),
        );
      }
    }
  }

  return FluentPlotlyLegendProps(
    legends: allupLegends,
    // `PlotlySchemaAdapter.ts:3563-3565`: all three are unconditional literals.
    centerLegends: true,
    enabledWrapLines: true,
    canSelectMultipleLegends: true,
  );
}

/// The per-chart legend decision for one grid cell
/// (`PlotlySchemaAdapter.ts:3569-3586`).
@immutable
class FluentPlotlyPerChartLegend {
  /// Creates a per-chart legend record.
  const FluentPlotlyPerChartLegend({
    required this.hideLegend,
    required this.names,
  });

  /// True when this chart must not draw its own legend
  /// (`PlotlySchemaAdapter.ts:3584`).
  final bool hideLegend;

  /// One name per trace, in trace order (`PlotlySchemaAdapter.ts:3570-3577`).
  final List<String> names;
}

/// Derives the per-chart legend names and visibility
/// (`PlotlySchemaAdapter.ts:3569-3586`).
FluentPlotlyPerChartLegend getLegendProps(
  List<Object?> data,
  Map<String, Object?>? layout, {
  required bool isMultiPlot,
}) {
  final names = <String>[];
  if (data.length == 1) {
    // `PlotlySchemaAdapter.ts:3572`: `data[0].name || ''`, so an empty or absent
    // name stays empty rather than becoming `Series 1`.
    final first = data.first;
    final name = first is Map<String, Object?> ? first['name'] : null;
    names.add(name is String && name.isNotEmpty ? name : '');
  } else {
    for (var index = 0; index < data.length; index++) {
      final series = data[index];
      final name = series is Map<String, Object?> ? series['name'] : null;
      // `PlotlySchemaAdapter.ts:3575`: one-based `Series N`.
      names.add(
        name is String && name.isNotEmpty ? name : 'Series ${index + 1}',
      );
    }
  }

  // `PlotlySchemaAdapter.ts:3579`: `every` on an empty list is true in both
  // languages, so an empty figure hides its legend.
  final hideLegendsData = data.every(
    (series) => series is Map<String, Object?> && series['showlegend'] == false,
  );
  final showLegend = layout?['showlegend'];
  // `PlotlySchemaAdapter.ts:3580`: an explicit false always hides; otherwise a
  // single legend hides unless `showlegend` is explicitly true.
  final hideLegendsInferred =
      showLegend == false || (showLegend != true && names.length < 2);

  return FluentPlotlyPerChartLegend(
    // `PlotlySchemaAdapter.ts:3584`.
    hideLegend: isMultiPlot || hideLegendsInferred || hideLegendsData,
    names: names,
  );
}
