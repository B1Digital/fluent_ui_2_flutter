import 'package:flutter/widgets.dart';

import 'internal/chart_utils.dart';
import 'internal/d3/shape_stack.dart' as d3;
import 'internal/data_viz_palette.dart';
import 'model/callout_data.dart';
import 'model/cartesian_series.dart';

/// How an area layer's baseline is chosen.
enum FluentAreaChartMode {
  /// Every layer sits on zero (`AreaChart.tsx:296-310`).
  toZeroY,

  /// Layers stack on one another via `d3.stack` — the default (`:312-320`).
  toNextY,
}

/// One row of the reshaped dataset: an x value with one y per series.
@immutable
class FluentAreaChartRow {
  /// Creates a row.
  const FluentAreaChartRow({required this.xValue, required this.values});

  /// The shared x value. Dates are compared by their epoch milliseconds, which
  /// is the Dart equivalent of upstream's `toLocaleString()` key (`:358`).
  final Object xValue;

  /// One y per series, indexed by series position.
  final List<double> values;
}

/// The output of AreaChart's data pipeline.
@immutable
class FluentAreaChartDataSet {
  /// Creates a dataset.
  const FluentAreaChartDataSet({
    required this.rows,
    required this.layers,
    required this.colours,
    required this.opacities,
    required this.maxOfYVal,
    required this.isMultiStack,
    required this.hasDuplicateXValues,
    required this.hasMissingXValues,
    required this.calloutPoints,
  });

  /// One row per distinct x, ascending.
  final List<FluentAreaChartRow> rows;

  /// One layer per series; each entry is the `(lo, hi)` pair for a row.
  final List<List<d3.StackPoint>> layers;

  /// Resolved colour per series.
  final List<Color> colours;

  /// Resolved opacity per series — `singleChartPoint.opacity || 1` (`:352`).
  final List<double> opacities;

  /// The y-axis ceiling handed to the shell.
  final double maxOfYVal;

  /// Whether the multi-stack opacity table applies (`:328-330`).
  final bool isMultiStack;

  /// Whether any series repeats an x value; suppresses the popover (`:1093`).
  final bool hasDuplicateXValues;

  /// Whether the series disagree on their x sets; suppresses the popover and
  /// the click handlers (`:846-853`).
  final bool hasMissingXValues;

  /// The deduplicated hover index built by [calloutData].
  final List<FluentCustomizedCalloutData> calloutPoints;
}

/// Ports `_addDefaultColors` (`AreaChart.tsx:891-937`), `_createDataSet`
/// (`:340-467`) and `_getDataPoints` (`:292-338`) as one pure function.
///
/// Upstream mutates the caller's data when back-filling missing x values
/// (`:909-921`): it pushes a `y: 0` point for every x the series is missing and
/// re-sorts. This port keys the rows by x instead and reads a missing y as 0,
/// which produces the same rows in the same ascending order without copying or
/// mutating the caller's series. Recorded divergence.
FluentAreaChartDataSet buildFluentAreaChartDataSet({
  required List<FluentLineChartSeries> series,
  required FluentAreaChartMode mode,
  required bool hasSecondaryYScale,
  required bool hasSelectedLegends,
}) {
  var hasDuplicates = false;
  final keysPerSeries = <Set<Object>>[];
  // One key-to-y map per series. A repeated x keeps the FIRST point's y, which
  // is what upstream's `filter(...)[0]` reads at `:428-437`.
  final yPerSeries = <Map<Object, double>>[];
  final keyToX = <Object, Object>{};
  for (final s in series) {
    final keys = <Object>{};
    final ys = <Object, double>{};
    for (final datum in s.data.cast<FluentLineChartDataPoint>()) {
      final key = _xKey(datum.x);
      if (!keys.add(key)) {
        hasDuplicates = true;
      }
      ys.putIfAbsent(key, () => datum.y);
      keyToX[key] = datum.x;
    }
    keysPerSeries.add(keys);
    yPerSeries.add(ys);
  }

  final union = <Object>{for (final keys in keysPerSeries) ...keys};
  // `:1049-1060` — a series is missing an x as soon as it does not carry every
  // x in the union.
  final hasMissing = keysPerSeries.any((keys) => keys.length != union.length);

  final orderedKeys = union.toList(growable: false)
    ..sort((a, b) => _xOrder(keyToX[a]!).compareTo(_xOrder(keyToX[b]!)));
  final rows = <FluentAreaChartRow>[
    for (final key in orderedKeys)
      FluentAreaChartRow(
        xValue: keyToX[key]!,
        values: <double>[for (final ys in yPerSeries) ys[key] ?? 0],
      ),
  ];

  // `mode === 'tozeroy' || _shouldFillToZeroY()` (`:296`, `:1065-1067`).
  final toZero = mode == FluentAreaChartMode.toZeroY || hasSecondaryYScale;
  final List<List<d3.StackPoint>> layers;
  final double maxOfYVal;
  if (toZero) {
    layers = <List<d3.StackPoint>>[
      for (var i = 0; i < series.length; i++)
        <d3.StackPoint>[for (final r in rows) d3.StackPoint(0, r.values[i], r)],
    ];
    maxOfYVal = rows.isEmpty || series.isEmpty
        ? 0
        : rows.expand((r) => r.values).reduce((a, b) => a > b ? a : b);
  } else {
    layers = d3.stack(rows, <String>[
      for (var i = 0; i < series.length; i++) '$i',
    ], value: (d, key) => (d as FluentAreaChartRow).values[int.parse(key)]);
    maxOfYVal = layers.isEmpty || layers.last.isEmpty
        ? 0
        : layers.last.map((p) => p.hi).reduce((a, b) => a > b ? a : b);
  }

  return FluentAreaChartDataSet(
    rows: rows,
    layers: layers,
    colours: <Color>[
      for (var i = 0; i < series.length; i++)
        series[i].color ?? FluentDataVizPalette.next(i),
    ],
    opacities: <double>[
      // parity: `singleChartPoint.opacity || 1` (`:352`) swallows a real 0.
      for (final s in series)
        (s.opacity == null || s.opacity == 0) ? 1 : s.opacity!,
    ],
    maxOfYVal: maxOfYVal,
    // `selectedLegends ? layers.length >= 1 : layers.length > 1` (`:328-330`).
    isMultiStack: hasSelectedLegends ? layers.isNotEmpty : layers.length > 1,
    hasDuplicateXValues: hasDuplicates,
    hasMissingXValues: hasMissing,
    calloutPoints: calloutData(series),
  );
}

/// The map key an x value is grouped by (`AreaChart.tsx:358`).
Object _xKey(Object x) => x is DateTime ? x.millisecondsSinceEpoch : x;

/// The sort key an x value is ordered by (`AreaChart.tsx:918-919`).
num _xOrder(Object x) => x is DateTime ? x.millisecondsSinceEpoch : x as num;
