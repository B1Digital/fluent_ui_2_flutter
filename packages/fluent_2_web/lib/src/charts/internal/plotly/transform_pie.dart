/// The Plotly `pie` transformer, and the three non-plot ones.
///
/// Ports `transformPlotlyJsonToDonutProps` (`PlotlySchemaAdapter.ts:1282-1388`)
/// and, because all three are short and none of them draws a cartesian cell,
/// `transformPlotlyJsonToSankeyProps` (`:2623-2715`),
/// `transformPlotlyJsonToGaugeProps` (`:2717-2838`) and
/// `transformPlotlyJsonToChartTableProps` (`:2908-3016`) with the four table
/// helpers they need (`:2849-2906`).
///
/// Internal to the package: nothing here is barrel-exported.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../axis/axis_types.dart';
import '../../axis/tick_format.dart';
import '../../chart_table.dart';
import '../../donut_chart.dart';
import '../../gauge_chart.dart';
import '../../model/bar_data.dart';
import '../../model/cartesian_series.dart';
import '../../model/sankey_data.dart';
import '../../sankey_chart.dart';
import '../d3/format.dart' as d3;
import '../d3/js_math.dart' as d3;
import '../d3/stable_sort.dart';
import '../data_viz_palette.dart';
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

/// The `template.layout.colorway` a figure declares, as strings.
///
/// `transform_bar.dart:204` holds the same fourteen lines. Both copies are
/// private to their file, so neither can call the other, and promoting one
/// would edit a file this task does not own.
// ponytail: duplicated rather than hoisted; fourteen private lines.
List<String>? _colorway(Map<String, Object?>? layout) {
  final template = layout?['template'];
  final templateLayout = template is Map<String, Object?>
      ? template['layout']
      : null;
  final colorway = templateLayout is Map<String, Object?>
      ? templateLayout['colorway']
      : null;
  if (colorway is! List<Object?>) return null;
  return <String>[
    for (final entry in colorway)
      if (entry is String) entry,
  ];
}

/// Reads [value] as a map, or null when it is anything else.
Map<String, Object?>? _map(Object? value) =>
    value is Map<String, Object?> ? value : null;

/// Reads [value] as a list, or an empty one — which is what indexing a missing
/// JavaScript array with `?.` gives.
List<Object?> _list(Object? value) =>
    value is List<Object?> ? value : const <Object?>[];

/// Element [index] of [value], or null: `arr?.[index]` when [value] is an
/// array, and the scalar itself otherwise.
Object? _at(Object? value, int index) => value is List<Object?>
    ? (index >= 0 && index < value.length ? value[index] : null)
    : null;

/// Trace 0 of [input], which is all three of the transformers below read
/// (`PlotlySchemaAdapter.ts:2630`, `:2724`, `:2915`).
Map<String, Object?> _firstTrace(Map<String, Object?> input) {
  final data = _list(input['data']);
  return (data.isEmpty ? null : _map(data.first)) ?? const <String, Object?>{};
}

/// [value] as a finite double, or null.
double? _num(Object? value) =>
    value is num && value.isFinite ? value.toDouble() : null;

/// Builds a sankey diagram from a Plotly `sankey` figure
/// (`PlotlySchemaAdapter.ts:2623-2715`).
///
/// **Not carried across:** `:2708`'s `width` and `:2709`'s `height` default of
/// 468. [FluentSankeyChart] takes neither — `sankey_chart.dart:606-608` records
/// that both props are dead upstream (`SankeyChart.tsx:36-48`) and that the
/// diagram sizes to its `BoxConstraints` instead (spec §2.2) — so the 468
/// belongs to the enclosing `SizedBox` that plan 09 Task 28 builds, alongside
/// the 350 the cartesian transformers leave for `kPlotlyDefaultCellHeight`.
/// // parity: PlotlySchemaAdapter.ts:2709
///
/// `:2712`'s `hideLegend` reaches [FluentSankeyChart.hideTitle]: upstream
/// spells the flag `hideLegend` on a chart that has no legend and gates the
/// title with it (`SankeyChart.tsx:1159`).
FluentSankeyChart transformPlotlyToSankey(
  Map<String, Object?> input, {
  required bool isMultiPlot,
  required PlotlyColorMap colorMap,
  required FluentPlotlyColorway colorwayType,
  required bool isDark,
}) {
  final layout = _map(input['layout']);
  final first = _firstTrace(input);
  // `:2630`.
  final link = _map(first['link']);
  final node = _map(first['node']);
  final colorway = _colorway(layout);

  // `:2631-2644`.
  final values = _list(link?['value']);
  final sources = link?['source'];
  final targets = link?['target'];
  final validLinks = <({double value, int source, int target})>[];
  for (var i = 0; i < values.length; i++) {
    final value = values[i];
    final source = _at(sources, i);
    final target = _at(targets, i);
    // `:2633` nulls the triple out; `:2644` then drops the null.
    if (isInvalidValue(value) ||
        isInvalidValue(source) ||
        isInvalidValue(target)) {
      continue;
    }
    // `:2644`'s three comparisons are numeric. A non-numeric endpoint could
    // not index the node list either, so it is dropped here rather than
    // carried to a `nodes[undefined]` upstream would resolve to `undefined`.
    if (value is! num || source is! num || target is! num) continue;
    if (source < 0 || target < 0 || source == target) continue;
    validLinks.add((
      value: value.toDouble(),
      // `FluentSankeyLink.source` is an `int` because it indexes the node list
      // (`types/DataPoint.ts:920`); a fractional endpoint indexes nothing
      // upstream either, so it truncates rather than throwing.
      source: source.toInt(),
      target: target.toInt(),
    ));
  }

  // `:2646-2659`.
  final extractedNodeColors = extractColor(
    colorway,
    colorwayType,
    node?['color'],
    colorMap,
    isDark: isDark,
  );
  final extractedLinkColors = extractColor(
    colorway,
    colorwayType,
    link?['color'],
    colorMap,
    isDark: isDark,
  );

  // `:2662-2677`: one node per label, the index as its id.
  final labels = _list(node?['label']);
  final nodes = <FluentSankeyNode>[
    for (var i = 0; i < labels.length; i++)
      FluentSankeyNode(
        nodeId: i,
        name: '${labels[i]}',
        color: parseCssColour(
          resolveColor(
            extractedNodeColors,
            i,
            '${labels[i]}',
            colorMap,
            colorway,
            isDark: isDark,
          ),
        ),
      ),
  ];

  // `:2679-2691`. The legend upstream hands `resolveColor` is the target
  // INDEX, a number, which it then uses as a `Map` key beside the string keys
  // every other call site supplies. `PlotlyColorMap` is keyed by `String`, so
  // the index is stringified — the one visible difference is that a node
  // literally named `'1'` would now share a palette slot with target 1.
  // // parity: PlotlySchemaAdapter.ts:2683
  final links = <FluentSankeyLink>[
    for (var i = 0; i < validLinks.length; i++)
      FluentSankeyLink(
        source: validLinks[i].source,
        target: validLinks[i].target,
        value: validLinks[i].value,
        color: parseCssColour(
          resolveColor(
            extractedLinkColors,
            i,
            d3.jsNumberToString(validLinks[i].target.toDouble()),
            colorMap,
            colorway,
            isDark: isDark,
          ),
        ),
      ),
  ];

  final titles = getTitles(layout);
  return FluentSankeyChart(
    // `:2704-2707`.
    data: FluentSankeyChartData(nodes: nodes, links: links),
    // `getTitles` gives `''` for an absent title (`:177`), which React draws as
    // nothing; `sankey_chart.dart` tests for null, so the empty string has to
    // become one or a titleless diagram reserves title height.
    chartTitle: titles.chartTitle.isEmpty ? null : titles.chartTitle,
    // `:2712`.
    hideTitle: isMultiPlot || layout?['showlegend'] == false,
    // AUDIT CORRECTION: `:2713` also spreads `titleStyles`, which
    // FluentSankeyChart does not take — only `titleFontSize`, and upstream's
    // record carries a whole font rather than a size. Dropped, as the donut
    // transformer drops the same record at `:1386`.
    // // parity: PlotlySchemaAdapter.ts:2713
  );
}

/// The colour a gauge axis declares, resolved through the figure's colourway
/// (`_getGaugeAxisColor`, `PlotlySchemaAdapter.ts:357-366`).
///
/// The legend it resolves against is the empty string, so every gauge in a
/// multi-plot figure shares one `colorMap` entry.
String getGaugeAxisColor(
  List<String>? colorway,
  FluentPlotlyColorway colorwayType,
  Object? color,
  PlotlyColorMap colorMap, {
  required bool isDark,
}) => resolveColor(
  // `:365`.
  extractColor(colorway, colorwayType, color, colorMap, isDark: isDark),
  0,
  '',
  colorMap,
  colorway,
  isDark: isDark,
);

/// Builds a gauge from a Plotly `indicator` figure
/// (`PlotlySchemaAdapter.ts:2717-2838`).
///
/// [isMultiPlot] is unused: upstream takes it at `:2719` and never reads it,
/// because a gauge has no legend to suppress. It stays so the parameter list is
/// uniform across every transformer.
FluentGaugeChart transformPlotlyToGauge(
  Map<String, Object?> input, {
  required bool isMultiPlot,
  required PlotlyColorMap colorMap,
  required FluentPlotlyColorway colorwayType,
  required bool isDark,
}) {
  final layout = _map(input['layout']);
  // `:2724`.
  final first = _firstTrace(input);
  final colorway = _colorway(layout);
  final gauge = _map(first['gauge']);
  final axis = _map(gauge?['axis']);
  final range = axis?['range'];
  // `:2826-2827`: a range endpoint counts only when it is literally a number.
  final rangeStart = _num(_at(range, 0));
  final rangeEnd = _num(_at(range, 1));
  final value = _num(first['value']);
  final stepsRaw = gauge?['steps'];
  final steps = stepsRaw is List<Object?> ? stepsRaw : null;

  // `:2725-2732`: the step colours, or nothing at all when there are no steps.
  final extractedColors = extractColor(
    colorway,
    colorwayType,
    steps == null
        ? null
        : <Object?>[for (final step in steps) _map(step)?['color']],
    colorMap,
    isDark: isDark,
  );

  final List<FluentGaugeChartSegment> segments;
  // `:2734` gates on `steps?.length`, so an empty array takes the else arm.
  if (steps != null && steps.isNotEmpty) {
    segments = <FluentGaugeChartSegment>[
      for (var i = 0; i < steps.length; i++)
        _gaugeStepSegment(
          _map(steps[i]),
          i,
          extractedColors,
          colorMap,
          colorway,
          isDark: isDark,
        ),
    ];
  } else {
    // parity: PlotlySchemaAdapter.ts:2755. Upstream writes
    // `firstData.value ?? 0 - (firstData.gauge?.axis?.range?.[0] ?? 0)`, and in
    // JavaScript `-` binds tighter than `??`, so this is
    // `value ?? (0 - rangeStart)` — the range start is subtracted only when the
    // value is absent. Reproduced; do not "fix" it to (value ?? 0) - rangeStart.
    final currentSize = value ?? (0 - (rangeStart ?? 0));
    segments = <FluentGaugeChartSegment>[
      // `:2753-2763`.
      FluentGaugeChartSegment(
        legend: 'Current',
        size: currentSize,
        color: parseCssColour(
          getGaugeAxisColor(
            colorway,
            colorwayType,
            axis?['color'],
            colorMap,
            isDark: isDark,
          ),
        ),
      ),
      // `:2764-2768`: 100 is upstream's fallback maximum.
      FluentGaugeChartSegment(
        legend: 'Target',
        size: (rangeEnd ?? 100) - (value ?? 0),
        color: FluentDataVizPalette.resolve(
          FluentDataVizToken.disabled,
          isDark: isDark,
        ),
      ),
    ];
  }

  final delta = _map(first['delta']);
  final reference = delta?['reference'];
  String? sublabel;
  // `:2773` gates on the truthiness of `delta.reference`, so 0, NaN and a
  // missing reference all skip the whole block.
  if (reference is num && reference != 0 && !reference.isNaN) {
    // `:2774`: `firstData.value - reference`, with no `?? 0` on the value, so
    // a valueless gauge with a delta gets NaN and takes the `▼` arm below.
    final diff = (value ?? double.nan) - reference.toDouble();
    // `:2775`. NaN fails `>= 0` in Dart as in JavaScript.
    sublabel = diff >= 0
        // `:2776`, U+25B2 and one space.
        ? '▲ ${d3.jsNumberToString(diff)}'
        // `:2794`, U+25BC and the absolute difference.
        : '▼ ${d3.jsNumberToString(diff.abs())}';
    // `:2777-2792` / `:2795-2810` then resolve a colour for the sublabel and
    // put it on `styles.sublabel` (`:2814-2816`). That slot is a CSS CLASS
    // NAME — `useGaugeChartStyles.styles.ts:138` feeds it to `mergeClasses` —
    // so a hex colour landing there names no class and paints nothing. The
    // colour is dead upstream and is dropped. The calls that produce it are
    // kept, because `resolveColor` assigns `colorMap['']` on its way
    // (`PlotlyColorAdapter.ts:107-132`) and that mutation is shared with every
    // other cell of a multi-plot figure.
    // // parity: PlotlySchemaAdapter.ts:2814
    final deltaSide = _map(delta?[diff >= 0 ? 'increasing' : 'decreasing']);
    getGaugeAxisColor(
      colorway,
      colorwayType,
      deltaSide?['color'],
      colorMap,
      isDark: isDark,
    );
  }

  final titles = getTitles(layout);
  return FluentGaugeChart(
    // `:2821-2822`.
    segments: segments,
    chartValue: value ?? 0,
    chartTitle: titles.chartTitle.isEmpty ? null : titles.chartTitle,
    sublabel: sublabel,
    // `:2826-2827`. FluentGaugeChart.minValue is non-nullable and defaults to
    // 0, which is the same value GaugeChart.types.ts gives the undefined prop.
    minValue: rangeStart ?? 0,
    maxValue: rangeEnd,
    // `:2828`: the raw value, so the centred text reads `30` rather than the
    // default `30%`. The two arguments the port's formatter takes are the
    // swept span and the total; upstream's closure takes none.
    chartValueFormat: (_, _) => value == null ? '' : d3.jsNumberToString(value),
    width: _num(layout?['width']),
    // `:2830`.
    height: _num(layout?['height']) ?? 220,
    // `:2833`.
    variant: steps != null && steps.isNotEmpty
        ? FluentGaugeChartVariant.multipleSegments
        : FluentGaugeChartVariant.singleSegment,
    // `:2835`.
    roundCorners: true,
    // AUDIT CORRECTION: `:2836` also spreads `titleStyles`, which
    // FluentGaugeChart does not take. Dropped, as at `:1386` and `:2713`.
    // // parity: PlotlySchemaAdapter.ts:2836
  );
}

/// One gauge band built from a `gauge.steps` entry
/// (`PlotlySchemaAdapter.ts:2736-2750`).
FluentGaugeChartSegment _gaugeStepSegment(
  Map<String, Object?>? step,
  int index,
  Object? extractedColors,
  PlotlyColorMap colorMap,
  List<String>? colorway, {
  required bool isDark,
}) {
  final name = step?['name'];
  // `:2737`: `step.name || \`Segment ${index + 1}\`` — a falsy name, the empty
  // string included, falls back to the one-based ordinal.
  final legend = name is String && name.isNotEmpty
      ? name
      : 'Segment ${index + 1}';
  final range = step?['range'];
  final start = _num(_at(range, 0));
  final end = _num(_at(range, 1));
  return FluentGaugeChartSegment(
    legend: legend,
    // `:2748`: `range[1] - range[0]`, which is NaN when either end is missing.
    // `GaugeChart.tsx:189` clamps a negative size but not a NaN one, so the
    // NaN is carried rather than defaulted.
    size: end == null || start == null ? double.nan : end - start,
    color: parseCssColour(
      // `:2738-2745`.
      resolveColor(
        extractedColors,
        index,
        legend,
        colorMap,
        colorway,
        isDark: isDark,
      ),
    ),
  );
}

/// Ports `formatValue` (`PlotlySchemaAdapter.ts:2849-2874`).
Object? _formatCellValue(
  Object? value,
  int colIndex,
  Map<String, Object?> cells,
) {
  // `:2854`: null and boolean pass through untouched, prefix and suffix
  // included.
  if (value == null || value is bool) return value;
  // `:2858-2860`: an array is indexed per column, a scalar applies to all.
  final formatStr = cells['format'] is List<Object?>
      ? _at(cells['format'], colIndex)
      : cells['format'];
  final prefix = cells['prefix'] is List<Object?>
      ? _at(cells['prefix'], colIndex)
      : cells['prefix'];
  final suffix = cells['suffix'] is List<Object?>
      ? _at(cells['suffix'], colIndex)
      : cells['suffix'];
  Object? formatted = value;
  if (value is num) {
    if (formatStr is String) {
      try {
        // `:2865`.
        formatted = d3.format(formatStr)(value);
      } on FormatException {
        // `:2867`. `formatSpecifier` (`d3/format_spec.dart:88`) is the only
        // throw on this path, so this catch is as narrow as the failure —
        // upstream's bare `catch` cannot be.
        formatted = formatScientificLimitWidth(value.toDouble());
      }
    } else {
      // `:2870`.
      formatted = formatScientificLimitWidth(value.toDouble());
    }
  }
  // `:2873`.
  return '${prefix ?? ''}$formatted${suffix ?? ''}';
}

/// Ports `resolveCellStyle` (`PlotlySchemaAdapter.ts:2876-2885`): a scalar
/// applies everywhere, a flat array is per column, a nested one is per column
/// then per row, and each level falls back to element 0.
Object? _resolveCellStyle(Object? raw, int rowIndex, int colIndex) {
  if (raw is! List<Object?>) return raw;
  // `:2878`.
  final rowEntry = _at(raw, colIndex) ?? _at(raw, 0);
  if (rowEntry is List<Object?>) {
    // `:2880`.
    return _at(rowEntry, rowIndex) ?? _at(rowEntry, 0);
  }
  return rowEntry;
}

/// Ports `mergeCells` (`PlotlySchemaAdapter.ts:2887-2906`): the trace's own
/// cell block over the template's, with `fill` and `font` merged key by key
/// and everything else replaced whole.
Map<String, Object?> _mergeCells(
  Map<String, Object?>? tableCells,
  Map<String, Object?>? templateCells,
) => <String, Object?>{
  'values':
      tableCells?['values'] ?? templateCells?['values'] ?? const <Object?>[],
  'align': tableCells?['align'] ?? templateCells?['align'],
  'fill': <String, Object?>{
    ...?_map(templateCells?['fill']),
    ...?_map(tableCells?['fill']),
  },
  'font': <String, Object?>{
    ...?_map(templateCells?['font']),
    ...?_map(tableCells?['font']),
  },
  'format': tableCells?['format'] ?? templateCells?['format'],
  'prefix': tableCells?['prefix'] ?? templateCells?['prefix'],
  'suffix': tableCells?['suffix'] ?? templateCells?['suffix'],
};

/// One table cell with its resolved inline style
/// (`PlotlySchemaAdapter.ts:2940-2947`, `:2969-2979`).
///
/// [rootFontSize] is `styles.root.fontSize` (`:2983-2987`). The port has no
/// root slot, so the CSS cascade is reproduced where it is observable: a cell
/// with no size of its own inherits the figure's, and a cell with one keeps it.
FluentChartTableCell _tableCell({
  required Object? value,
  required Object? fontColor,
  required Object? fontSize,
  required Object? backgroundColor,
  required double? rootFontSize,
}) {
  final size = fontSize is num ? fontSize.toDouble() : rootFontSize;
  final colour = fontColor is String && fontColor.isNotEmpty
      ? parseCssColour(fontColor)
      : null;
  return FluentChartTableCell(
    value: value,
    textStyle: size == null && colour == null
        ? null
        : TextStyle(color: colour, fontSize: size),
    backgroundColor: backgroundColor is String && backgroundColor.isNotEmpty
        ? parseCssColour(backgroundColor)
        : null,
    // NOT PORTED: `:2944` and `:2973` also carry a `textAlign`.
    // FluentChartTableCell models only the colour and the background, because
    // `chart_table.dart:9-13` records that those are the only two members
    // `ChartTable.tsx:137-139` and `:159-161` ever read.
    // // parity: PlotlySchemaAdapter.ts:2944
  );
}

/// Builds a chart table from a Plotly `table` figure
/// (`PlotlySchemaAdapter.ts:2908-3016`).
///
/// [isMultiPlot], [colorMap], [colorwayType] and [isDark] are all unused:
/// upstream takes the four at `:2910-2913` and reads none of them, because a
/// table paints no marks and takes every colour it uses from the trace's own
/// `font` and `fill` blocks. They stay so the parameter list is uniform across
/// every transformer.
FluentChartTable transformPlotlyToChartTable(
  Map<String, Object?> input, {
  required bool isMultiPlot,
  required PlotlyColorMap colorMap,
  required FluentPlotlyColorway colorwayType,
  required bool isDark,
}) {
  final layout = _map(input['layout']);
  // `:2915`.
  final tableData = _firstTrace(input);
  final tableCells = _map(tableData['cells']);
  final tableHeader = _map(tableData['header']);

  // `:2951`, `:2989`: `layout.template.data.table[0]`.
  final templateTables = _list(
    _map(_map(layout?['template'])?['data'])?['table'],
  );
  final templateTable = templateTables.isEmpty
      ? null
      : _map(templateTables.first);
  final templateCells = _map(templateTable?['cells']);
  final templateHeader = _map(templateTable?['header']);

  // `:2983-2987`: the layout font size, gated on truthiness so a 0 declares
  // none.
  final rootSize = _map(layout?['font'])?['size'];
  final rootFontSize = rootSize is num && rootSize != 0
      ? rootSize.toDouble()
      : null;

  // `:2992-3003`: the STYLES come from the trace's header merged over the
  // template's, but `:3008` passes only `tableData.header?.values` as the
  // values — so `:3002`'s template fallback is computed and never used, and a
  // figure whose header lives only in the template renders no header text.
  // Reproduced.
  // // parity: PlotlySchemaAdapter.ts:3008
  final headerFont = <String, Object?>{
    ...?_map(templateHeader?['font']),
    ...?_map(tableHeader?['font']),
  };
  final headerFill = <String, Object?>{
    ...?_map(templateHeader?['fill']),
    ...?_map(tableHeader?['fill']),
  };

  final headerValues = _list(tableHeader?['values']);
  // `:2921-2928`: a nested first element means each header is a ROW of
  // fragments, cleaned, emptied out and joined with a space; a flat one means
  // one header per entry. `cleanText` would throw on a non-string upstream, so
  // the interpolation here is the graceful equivalent of that crash.
  final cleanedValues = <String>[];
  if (headerValues.isNotEmpty && headerValues.first is List<Object?>) {
    for (final row in headerValues) {
      cleanedValues.add(
        <String>[
          for (final fragment in _list(row))
            if (cleanPlotlyText('$fragment').isNotEmpty)
              cleanPlotlyText('$fragment'),
        ].join(' '),
      );
    }
  } else {
    for (final entry in headerValues) {
      cleanedValues.add(cleanPlotlyText('$entry'));
    }
  }

  final headers = <FluentChartTableCell>[
    for (var colIndex = 0; colIndex < cleanedValues.length; colIndex++)
      _tableCell(
        value: cleanedValues[colIndex],
        // `:2932`: headers sit at row 0.
        fontColor: _resolveCellStyle(headerFont['color'], 0, colIndex),
        fontSize: _resolveCellStyle(headerFont['size'], 0, colIndex),
        backgroundColor: _resolveCellStyle(headerFill['color'], 0, colIndex),
        rootFontSize: rootFontSize,
      ),
  ];

  // `:2950-2951`.
  final columns = _list(tableCells?['values']);
  final cells = _mergeCells(tableCells, templateCells);
  final cellFont = _map(cells['font']) ?? const <String, Object?>{};
  final cellFill = _map(cells['fill']) ?? const <String, Object?>{};
  // `:2952` indexes `columns[0]` unguarded, so a table with no cell values
  // throws a TypeError upstream and would throw a RangeError here. An empty
  // body is the graceful equivalent and keeps a malformed figure from taking
  // the whole page down.
  // ponytail: guarded rather than reproduced; the upstream behaviour is a crash
  // on untrusted JSON, and there is nothing to gain by matching it.
  final firstColumn = columns.isEmpty
      ? const <Object?>[]
      : _list(columns.first);
  final rows = <List<FluentChartTableCell>>[];
  for (var rowIndex = 0; rowIndex < firstColumn.length; rowIndex++) {
    final row = <FluentChartTableCell>[];
    for (var colIndex = 0; colIndex < columns.length; colIndex++) {
      // `:2954-2960`.
      final cellValue = _at(columns[colIndex], rowIndex);
      final cleanValue = cellValue is String
          ? cleanPlotlyText(cellValue)
          : cellValue;
      row.add(
        _tableCell(
          value: cleanValue is String || cleanValue is num
              ? _formatCellValue(cleanValue, colIndex, cells)
              : cleanValue,
          // `:2962-2967`.
          fontColor: _resolveCellStyle(cellFont['color'], rowIndex, colIndex),
          fontSize: _resolveCellStyle(cellFont['size'], rowIndex, colIndex),
          backgroundColor: _resolveCellStyle(
            cellFill['color'],
            rowIndex,
            colIndex,
          ),
          rootFontSize: rootFontSize,
        ),
      );
    }
    rows.add(row);
  }

  final titles = getTitles(layout);
  return FluentChartTable(
    // `:3008-3009`.
    headers: headers,
    rows: rows,
    // `:3010-3011`. Unlike the nine shell charts this one really does take the
    // layout's own box: `chart_table.dart:204-212` keeps both props because
    // upstream's `'100%'` and 650 fallbacks live in the widget, not in a cell
    // wrapper.
    width: _num(layout?['width']),
    height: _num(layout?['height']),
    // `:3013`, with the same empty-string-to-null step the donut takes: an
    // empty title would otherwise reserve the style's 30px titleHeight.
    chartTitle: titles.chartTitle.isEmpty ? null : titles.chartTitle,
    // AUDIT CORRECTION: `:3014` also spreads `titleStyles`, which
    // FluentChartTable does not take. Dropped, as at `:1386`, `:2713` and
    // `:2836`.
    // // parity: PlotlySchemaAdapter.ts:3014
  );
}
