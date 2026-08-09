import 'package:flutter/widgets.dart';

import '../model/callout_data.dart';
import '../model/cartesian_series.dart';

/// The colour a callout row falls back to when its series names none.
///
/// `utilities.ts:1050` writes `color: ele.color!`, a non-null assertion over a
/// value TypeScript cannot prove is set; at runtime it propagates `undefined`.
/// Every chart resolves its series colours before building callout data, so this
/// is unreachable in practice — and a fully transparent fill (alpha 0x00 over
/// black) makes a violation visible rather than painting a plausible-looking
/// black.
const Color _unresolvedSeriesColour = Color(0x00000000);

/// Groups every series' values by their x, ready for a callout.
///
/// Ports `calloutData` (`utilities.ts:1006-1069`).
///
/// Two rules that must be written down once, because thirteen call sites across
/// AreaChart, LineChart and ScatterChart depend on them:
///
/// * the map key is `x.getTime()` for a date and the raw value otherwise
///   (`:1046`);
/// * a point is dropped only when an existing point at that x matches on **both**
///   `legend` **and** `y` (`:1060-1062`) — the pair, not the legend alone.
///
/// The result is a list rather than a map: upstream's object is only ever read
/// by key through [findCalloutPoints], and a list keeps the entries in
/// first-seen order without depending on JavaScript's integer-key enumeration.
///
/// `FluentCustomizedCalloutDataPoint.index` is the series' position in [values].
/// Upstream reads `line.index` off the series itself (`utilities.ts:1053`), an
/// optional member its callers set from the same position; the port has no such
/// field, so the loop index carries it. Recorded divergence.
List<FluentCustomizedCalloutData> calloutData(
  List<FluentLineChartSeries> values,
) {
  final byKey = <Object, List<FluentCustomizedCalloutDataPoint>>{};
  final xForKey = <Object, Object>{};

  void add({
    required Object x,
    required double y,
    required String legend,
    required Color? colour,
    required int index,
    required bool hideCallout,
    String? xAxisCalloutData,
    String? yAxisCalloutText,
    Map<String, double>? yAxisCalloutBreakdown,
  }) {
    // utilities.ts:1017.
    if (hideCallout) {
      return;
    }
    // utilities.ts:1046.
    final key = x is DateTime ? x.millisecondsSinceEpoch : x;
    final existing = byKey[key];
    final point = FluentCustomizedCalloutDataPoint(
      legend: legend,
      y: y,
      color: colour ?? _unresolvedSeriesColour,
      xAxisCalloutData: xAxisCalloutData,
      yAxisCalloutText: yAxisCalloutText,
      yAxisCalloutBreakdown: yAxisCalloutBreakdown,
      index: index,
    );
    if (existing == null) {
      byKey[key] = <FluentCustomizedCalloutDataPoint>[point];
      xForKey[key] = x;
      return;
    }
    // utilities.ts:1060-1062 — the legend AND the y must both match.
    final duplicate = existing.any(
      (candidate) => candidate.legend == legend && candidate.y == y,
    );
    if (!duplicate) {
      existing.add(point);
    }
  }

  for (var index = 0; index < values.length; index++) {
    final series = values[index];
    for (final datum in series.data) {
      switch (datum) {
        case final FluentLineChartDataPoint point:
          add(
            x: point.x,
            y: point.y,
            legend: series.legend,
            colour: series.color,
            index: index,
            hideCallout: point.hideCallout,
            xAxisCalloutData: point.xAxisCalloutData,
            yAxisCalloutText: point.yAxisCalloutText,
            yAxisCalloutBreakdown: point.yAxisCalloutBreakdown,
          );
        case final FluentScatterChartDataPoint point:
          add(
            x: point.x,
            y: point.y,
            legend: series.legend,
            colour: series.color,
            index: index,
            hideCallout: point.hideCallout,
            xAxisCalloutData: point.xAxisCalloutData,
            yAxisCalloutText: point.yAxisCalloutText,
            yAxisCalloutBreakdown: point.yAxisCalloutBreakdown,
          );
        default:
          // types/DataPoint.ts:492 admits only those two point types.
          assert(
            false,
            'A series datum must be a FluentLineChartDataPoint or a '
            'FluentScatterChartDataPoint.',
          );
      }
    }
  }

  return <FluentCustomizedCalloutData>[
    for (final entry in byKey.entries)
      FluentCustomizedCalloutData(x: xForKey[entry.key]!, values: entry.value),
  ];
}

/// The callout rows at [x], or null when there are none.
///
/// Ports `findCalloutPoints` (`utilities.ts:2560-2577`), including the null
/// guard at `:2564`. Upstream returns `{ x, values }`, but its `x` is the
/// argument the caller already holds, so the port returns the rows alone.
/// Recorded divergence.
///
/// [isXAxisDate] is a port addition. Upstream's scale inverts to a `Date`, so
/// its `x instanceof Date` test is enough; a Flutter time scale inverts to a
/// double, so a caller on a date axis may hold epoch milliseconds. When
/// [isXAxisDate] is true a numeric [x] is read as milliseconds since epoch and
/// finds the same entry a [DateTime] would.
List<FluentCustomizedCalloutDataPoint>? findCalloutPoints(
  List<FluentCustomizedCalloutData> data,
  Object? x, {
  required bool isXAxisDate,
}) {
  if (x == null) {
    return null;
  }
  // utilities.ts:2568.
  final key = switch (x) {
    final DateTime value => value.millisecondsSinceEpoch,
    final num value when isXAxisDate => value.toInt(),
    _ => x,
  };
  for (final entry in data) {
    final entryX = entry.x;
    final entryKey = entryX is DateTime
        ? entryX.millisecondsSinceEpoch
        : entryX;
    if (entryKey == key) {
      return entry.values;
    }
  }
  // utilities.ts:2569-2571.
  return null;
}
