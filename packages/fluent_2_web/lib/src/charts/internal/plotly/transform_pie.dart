/// The Plotly `pie` transformer.
///
/// Ports `transformPlotlyJsonToDonutProps` (`PlotlySchemaAdapter.ts:1282-1388`).
/// Internal to the package: nothing here is barrel-exported.
library;

import 'dart:math' as math;

import '../../axis/axis_types.dart';
import '../../donut_chart.dart';
import '../../model/bar_data.dart';
import '../../model/cartesian_series.dart';
import '../d3/stable_sort.dart';
import 'color_adapter.dart';
import 'common.dart';
import 'predicates.dart';

/// One filtered `(label, value, colour)` triple, before the descending sort
/// (`PlotlySchemaAdapter.ts:1311-1316`).
typedef _Pair = ({String label, double value, String? colour});

/// Builds a donut chart from a Plotly `pie` figure
/// (`PlotlySchemaAdapter.ts:1282-1388`).
///
/// The colour map is **cleared** at the start, reproducing
/// `PlotlySchemaAdapter.ts:1305`: `getAllupLegendsProps` has already populated
/// it in unsorted label order, and the donut wants palette slot 0 to belong to
/// the largest slice. Clearing is why donut colours differ from the all-up
/// legend's in a multi-plot figure — that is upstream behaviour.
FluentDonutChart transformPlotlyToDonut(
  Map<String, Object?> input, {
  required bool isMultiPlot,
  required PlotlyColorMap colorMap,
  required FluentPlotlyColorway colorwayType,
  required bool isDark,
}) {
  final data = input['data']! as List<Object?>;
  final first = data.first! as Map<String, Object?>;
  final layout = input['layout'] is Map<String, Object?>
      ? input['layout']! as Map<String, Object?>
      : null;
  final template = layout?['template'];
  final templateColorway = template is Map<String, Object?>
      ? (template['layout'] is Map<String, Object?>
            ? (template['layout']! as Map<String, Object?>)['colorway']
            : null)
      : null;
  // `:1295` — `piecolorway` first, the template's `colorway` second.
  final colorwaySource = layout?['piecolorway'] ?? templateColorway;
  final colorway = colorwaySource is List<Object?>
      ? <String>[
          for (final c in colorwaySource)
            if (c is String) c,
        ]
      : null;
  final marker = first['marker'];
  final markerColors = marker is Map<String, Object?> ? marker['colors'] : null;
  final extracted = extractColor(
    colorway,
    colorwayType,
    // `:1297`.
    layout?['piecolorway'] ?? markerColors,
    colorMap,
    isDark: isDark,
    isDonut: true,
  );

  // `PlotlySchemaAdapter.ts:1305`.
  colorMap.clear();

  final points = <String, FluentChartDataPoint>{};
  final labels = first['labels'];
  final values = first['values'];
  // `:1308`.
  if (labels is List<Object?> && values is List<Object?>) {
    // `:1310`.
    final hasMarkerColors =
        markerColors is List<Object?> &&
        markerColors.length >= labels.length &&
        markerColors.every((c) => c is String);
    final pairs = <_Pair>[];
    for (var i = 0; i < labels.length; i++) {
      // `getNumberAtIndexOrDefault` (`:3588-3598`) is `undefined` for anything
      // that is not a finite number, and `:1318` then drops it; `raw is! num`
      // and [isInvalidValue] together are that pair of steps.
      final raw = i < values.length ? values[i] : null;
      if (raw is! num || isInvalidValue(raw)) continue;
      pairs.add((
        label: '${labels[i]}',
        value: raw.toDouble(),
        colour: hasMarkerColors ? markerColors[i]! as String : null,
      ));
    }
    // `:1320`: descending by value.
    //
    // Upstream's comparator returns 0 for a tie and `Array.prototype.sort` has
    // been stable since ES2019, so the tied slices keep their schema order
    // there. Dart's `List.sort` is an unstable introsort, so this goes through
    // [stableSort] to keep that order rather than to change it.
    final sorted = stableSort<_Pair>(
      pairs,
      (a, b) => b.value.compareTo(a.value),
    );
    for (var i = 0; i < sorted.length; i++) {
      final pair = sorted[i];
      // `:1323-1333`. Called for every pair, duplicates included, because the
      // colour map it advances is the point of the call as much as the return
      // value is.
      final colour =
          pair.colour ??
          resolveColor(
            extracted,
            i,
            pair.label,
            colorMap,
            colorway,
            isDark: isDark,
            isDonut: true,
          );
      final existing = points[pair.label];
      // `:1335-1343`. Assigning back to an existing key keeps its position in a
      // Dart `LinkedHashMap`, as it does in a JavaScript object.
      points[pair.label] = existing == null
          ? FluentChartDataPoint(
              legend: pair.label,
              data: pair.value,
              color: parseCssColour(colour),
            )
          : FluentChartDataPoint(
              legend: pair.label,
              data: (existing.data ?? 0) + pair.value,
              color: existing.color,
            );
    }
  }

  // `PlotlySchemaAdapter.ts:1347-1348`: the radius maths falls back to a
  // 440 x 220 box when the layout declares no size.
  final width = (layout?['width'] as num?)?.toDouble() ?? 440;
  final height = (layout?['height'] as num?)?.toDouble() ?? 220;
  final textinfo = first['textinfo'];
  // `:1349-1351`.
  final hideLabels = textinfo is String
      ? !const <String>[
          'value',
          'percent',
          'label+percent',
          'percent+label',
        ].contains(textinfo)
      : false;
  // `:1352-1353`: 0 or 80 horizontally, 40 or 80 vertically.
  final marginHorizontal = hideLabels ? 0.0 : 80.0;
  final marginVertical = 40.0 + (hideLabels ? 0.0 : 40.0);
  final hole = first['hole'];
  // `:1354-1356`. A `hole` of 0 is falsy upstream, so it takes the
  // [kMinDonutRadius] arm too — `hole is num && hole != 0` is that truthiness.
  final innerRadius = hole is num && hole != 0
      ? hole.toDouble() *
            (math.min(width - marginHorizontal, height - marginVertical) / 2)
      : kMinDonutRadius;

  final legends = points.keys.toList();
  // `:1358-1369`: keep the first, reverse the rest.
  final ordered = legends.length > 1
      ? <String>[legends.first, ...legends.skip(1).toList().reversed]
      : legends;
  final titles = getTitles(layout);

  return FluentDonutChart(
    data: FluentChartData(
      // `getTitles` gives `''` for an absent title (`:177`), which React draws
      // as nothing because `DonutChart.tsx:360` tests it for truthiness. The
      // port tests for null instead (`donut_chart.dart:605`, `:618`), so the
      // empty string has to become one or a titleless donut reserves title
      // height and draws an empty title.
      chartTitle: titles.chartTitle.isEmpty ? null : titles.chartTitle,
      chartData: <FluentChartDataPoint>[
        for (final key in ordered) points[key]!,
      ],
    ),
    // `:1376`.
    hideLegend: isMultiPlot || layout?['showlegend'] == false,
    // `:1377`: the declared width only, not the 440 the radius maths falls
    // back to.
    width: (layout?['width'] as num?)?.toDouble(),
    height: height,
    innerRadius: innerRadius,
    hideLabels: hideLabels,
    // `:1381-1383`.
    showLabelsInPercent: textinfo is String
        ? const <String>[
            'percent',
            'label+percent',
            'percent+label',
          ].contains(textinfo)
        : true,
    // `:1385`. Upstream's `order: 'sorted'` re-sorts the LEGEND descending and
    // leaves the arcs alone (`DonutChart.tsx:107-111`, `:331`), so it does not
    // undo the anticlockwise arc order built above.
    order: FluentDonutOrder.sorted,
    // AUDIT CORRECTION: upstream also passes `roundCorners: true` (`:1384`) and
    // `titleStyles` (`:1386`). FluentDonutChart takes neither — plan 06 records
    // that `DonutChart.tsx`'s own `roundCorners` never reaches an arc, and the
    // corner radius comes from FluentDonutChartStyle here — so dropping both is
    // not a fidelity loss at the arc, only a title-font one.
    // // parity: PlotlySchemaAdapter.ts:1384, :1386
  );
}
