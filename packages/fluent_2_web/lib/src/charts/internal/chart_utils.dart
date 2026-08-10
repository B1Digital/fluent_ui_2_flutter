import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../model/callout_data.dart';
import '../model/cartesian_series.dart';
import '../model/chart_common.dart';
import '../model/chart_value.dart';
import '../model/line_options.dart';
import 'd3/array_stats.dart' as d3;
import 'd3/curves.dart' as d3;
import 'd3/stable_sort.dart';

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
            // A scatter y is `num | String`. Upstream stores the raw value in
            // the callout (`utilities.ts:1049`) and lets React print it; the
            // ported reading is typed `double`, so a category y is carried by
            // `yAxisCalloutText` — which the popover prefers anyway
            // (`ChartPopover.tsx:44`) — and the number falls back to NaN.
            y: point.y is num ? (point.y as num).toDouble() : double.nan,
            legend: series.legend,
            colour: series.color,
            index: index,
            hideCallout: point.hideCallout,
            xAxisCalloutData: point.xAxisCalloutData,
            yAxisCalloutText:
                point.yAxisCalloutText ??
                (point.y is String ? point.y as String : null),
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

/// Whether [title] is highlighted under the multi-select model.
///
/// Model A, used by nine charts — GroupedVerticalBarChart, GanttChart,
/// VerticalBarChart, GaugeChart, HorizontalBarChartWithAxis, AreaChart,
/// VerticalStackedBarChart, ScatterChart and DonutChart. Ports
/// `_legendHighlighted` plus `_getHighlightedLegend`
/// (`VerticalBarChart.tsx:908-921`):
/// `selectedLegends.length > 0 ? selectedLegends : activeLegend ? [activeLegend] : []`,
/// then `.includes(title)`.
///
/// `activeLegend` is tested for **truthiness** upstream, so an empty string
/// counts as no hover.
///
/// The three models are kept apart deliberately. The 9 / 3 / 1 split is real
/// behaviour: it gates every opacity constant and every popover suppression in
/// the package, and unifying it would change what a chart highlights.
bool isLegendHighlightedMulti(
  String title, {
  required List<String> selectedLegends,
  String? activeLegend,
}) {
  // VerticalBarChart.tsx:920, the first arm of the conditional.
  if (selectedLegends.isNotEmpty) {
    return selectedLegends.contains(title);
  }
  if (activeLegend == null || activeLegend.isEmpty) {
    return false;
  }
  return activeLegend == title;
}

/// Whether [title] is highlighted under the single-select model.
///
/// Model B, used by HeatMapChart (`HeatMapChart.tsx:608-610`) and LineChart
/// (`LineChart.tsx:1817-1819`):
/// `selectedLegend === legend || (selectedLegend === '' && activeLegend === legend)`.
///
/// The hover arm is reachable only while nothing is selected, which is what
/// makes this model different from [isLegendHighlightedMulti] rather than a
/// special case of it.
bool isLegendHighlightedSingle(
  String title, {
  required String selectedLegend,
  String? activeLegend,
}) =>
    selectedLegend == title ||
    (selectedLegend.isEmpty && activeLegend == title);

/// Model B with HorizontalBarChart's absent-title guard.
///
/// Ports `_legendHighlighted` (`HorizontalBarChart.tsx:371-376`), whose first
/// statement returns false for an undefined bar legend before the comparison
/// runs. A null [selectedLegend] then matches nothing and does not open the
/// hover arm either, because it is not the empty string.
bool isLegendHighlightedSingleGuarded(
  String? title, {
  required String? selectedLegend,
  String? activeLegend,
}) {
  // HorizontalBarChart.tsx:372-374.
  if (title == null) {
    return false;
  }
  // HorizontalBarChart.tsx:375.
  return selectedLegend == title ||
      (selectedLegend == '' && activeLegend == title);
}

/// Whether [a] and [b] hold the same strings in the same order.
///
/// Ports `areArraysEqual` (`utilities.ts:1982-1996`), used by eight charts to
/// decide whether a legend selection actually changed. Note that a null is equal
/// only to another null, never to an empty list (`:1983`, `:1986`).
bool areArraysEqual(List<String>? a, List<String>? b) {
  // utilities.ts:1983.
  if (identical(a, b) || (a == null && b == null)) {
    return true;
  }
  // utilities.ts:1986.
  if (a == null || b == null || a.length != b.length) {
    return false;
  }
  // utilities.ts:1989-1993 — index by index, so order matters. The loop starts
  // at index 0 because upstream's `let i = 0` walks the whole array.
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// [label] with the first letter of each word in upper case.
///
/// Ports `text-transform: capitalize` (`useLegendsStyles.styles.ts:56`), which
/// is the only `textTransform` in the upstream package and which Flutter has no
/// equivalent for (spec §8). It must be applied before painting **and** before
/// measuring, because CSS applies it before layout.
///
/// Upstream is inconsistent about which measurement sees it, and the port
/// matches that: `measureTextWithDOM` copies `text-transform`
/// (`utilities.ts:2137-2144`) and is what the exported legend strip measures
/// with (`image-export-utils.ts:314`), while the canvas-based
/// `calculateLongestLabelWidth` (`utilities.ts:1253-1276`) does not. So the
/// exported legend is measured post-capitalisation and axis labels are measured
/// pre-capitalisation.
///
/// Note that CSS `capitalize` upper-cases the first letter and leaves the rest
/// of the word alone — `'GDP growth'` becomes `'GDP Growth'`, not
/// `'Gdp Growth'`.
///
/// `ponytail:` word boundaries are whitespace only, which matches Chrome for a
/// hyphen (`'north-east'` renders as `'North-east'`). Widen it if a real label
/// ever needs a different boundary.
String capitalizeLegendLabel(String label) {
  if (label.isEmpty) {
    return label;
  }
  final buffer = StringBuffer();
  var atWordStart = true;
  for (final rune in label.runes) {
    final character = String.fromCharCode(rune);
    if (character.trim().isEmpty) {
      atWordStart = true;
      buffer.write(character);
      continue;
    }
    buffer.write(atWordStart ? character.toUpperCase() : character);
    atWordStart = false;
  }
  return buffer.toString();
}

/// The bar width a chart falls back to, in logical pixels.
///
/// `DEFAULT_BAR_WIDTH` (`utilities.ts:1891`).
const double kDefaultBarWidth = 16;

/// The narrowest a bar may be, in logical pixels.
///
/// `MIN_BAR_WIDTH` (`utilities.ts:1892`).
const double kMinBarWidth = 1;

/// Resolves a bar width from the caller's prop and the computed fit.
///
/// Ports `getBarWidth` (`utilities.ts:1894-1913`). [barWidth] is upstream's
/// `number | 'default' | 'auto' | undefined`; [adjustedValue] is the width the
/// chart's own band maths produced, and [mode] is the owning chart's mode, of
/// which only `'histogram'` is significant here (`:1901`).
///
/// The order matters: pick, then cap with [maxBarWidth], then floor at
/// [kMinBarWidth].
double getBarWidth(
  Object? barWidth,
  double? maxBarWidth, {
  double adjustedValue = kDefaultBarWidth,
  String? mode,
}) {
  double width;
  if (barWidth == 'auto' || mode == 'histogram') {
    // utilities.ts:1901-1902.
    width = adjustedValue;
  } else if (barWidth is num) {
    // utilities.ts:1903-1904.
    width = barWidth.toDouble();
  } else {
    // utilities.ts:1906.
    width = math.min(adjustedValue, kDefaultBarWidth);
  }
  if (maxBarWidth != null) {
    // utilities.ts:1908-1910.
    width = math.min(width, maxBarWidth);
  }
  // utilities.ts:1911.
  return math.max(width, kMinBarWidth);
}

/// Resolves a band-scale padding, clamped into 0..1.
///
/// Ports `getScalePadding` (`utilities.ts:1915-1919`): the explicit [prop] wins,
/// then the [shorthand], then [defaultValue]; anything that is not a number is
/// skipped.
double getScalePadding(
  Object? prop, [
  Object? shorthand,
  double defaultValue = 0,
]) {
  final double padding;
  // utilities.ts:1916.
  if (prop is num) {
    padding = prop.toDouble();
  } else if (shorthand is num) {
    padding = shorthand.toDouble();
  } else {
    padding = defaultValue;
  }
  // utilities.ts:1917 — `Math.max(0, Math.min(padding, 1))`, which is a clamp
  // into the closed unit interval; the bounds are upstream's own 0 and 1.
  return padding.clamp(0, 1);
}

/// Whether the caller supplied a padding at all.
///
/// Ports `isScalePaddingDefined` (`utilities.ts:1921-1923`). Distinct from
/// [getScalePadding] returning 0, because an explicit 0 and an absent value make
/// different charts.
bool isScalePaddingDefined(Object? prop, [Object? shorthand]) =>
    prop is num || shorthand is num;

/// [str] cut to [maxLength] characters with [ellipsis] appended.
///
/// Ports `truncateString` (`utilities.ts:2036-2042`). The ellipsis is added
/// **after** the slice and is not counted against [maxLength], so a truncated
/// result is longer than [maxLength] — that is upstream behaviour and every
/// axis-label width calculation is built on it.
String truncateString(String str, int maxLength, {String ellipsis = '...'}) {
  // utilities.ts:2037-2039.
  if (str.length <= maxLength) {
    return str;
  }
  // utilities.ts:2041.
  return str.substring(0, maxLength) + ellipsis;
}

/// Orders the categories on a band axis.
///
/// Ports `sortAxisCategories` (`utilities.ts:2049-2110`), which is itself a port
/// of Plotly's `sortAxisCategoriesByValue`.
///
/// Three behaviours worth naming:
///
/// * an explicit order emits the named categories that the data carries, in the
///   caller's order and deduplicated, then appends everything else in insertion
///   order (`:2053-2072`);
/// * `'total'` and `'sum'` are the same aggregator (`:2087-2088`);
/// * `aggFn[...] || 0` at `:2103` turns an aggregate of `undefined` — which
///   happens for an empty value list — into 0. `// parity:` it also swallows a
///   real 0, which is harmless only because the replacement is the same number.
///
/// The comparator returns 0 for equal aggregates, and V8 has sorted stably since
/// ES2019 while Dart's `List.sort` is unstable, so this goes through
/// [stableSort] (spec §8).
List<String> sortAxisCategories(
  Map<String, List<double>> categoryToValues,
  FluentAxisCategoryOrder order,
) {
  if (order is FluentAxisCategoryOrderExplicit) {
    final result = <String>[];
    final seen = <String>{};
    // utilities.ts:2057-2063.
    for (final category in order.categories) {
      if (categoryToValues.containsKey(category) && seen.add(category)) {
        result.add(category);
      }
    }
    // utilities.ts:2065-2069.
    for (final category in categoryToValues.keys) {
      if (!seen.contains(category)) {
        result.add(category);
      }
    }
    return result;
  }

  final name = (order as FluentAxisCategoryOrderPreset).upstreamName;
  // utilities.ts:2044 —
  // /(category|total|sum|min|max|mean|median) (ascending|descending)/.
  final match = RegExp(
    r'(category|total|sum|min|max|mean|median) (ascending|descending)',
  ).firstMatch(name);
  // utilities.ts:2109 — 'default' and 'data' match nothing and fall through.
  if (match == null) {
    return categoryToValues.keys.toList();
  }

  final aggregator = match.group(1)!;
  final descending = match.group(2) == 'descending';

  if (aggregator == 'category') {
    // utilities.ts:2080-2083.
    final result = categoryToValues.keys.toList()..sort();
    return descending ? result.reversed.toList() : result;
  }

  // utilities.ts:2085-2091. The `?? 0` on every arm but `sum` is upstream's
  // `|| 0` at :2103; `d3.sum` already returns 0 for an empty input.
  double aggregate(List<double> values) => switch (aggregator) {
    'min' => d3.min<double>(values) ?? 0,
    'max' => d3.max<double>(values) ?? 0,
    'sum' || 'total' => d3.sum(values),
    'mean' => d3.mean(values) ?? 0,
    // The regex admits no eighth aggregator, so this arm is 'median'.
    _ => d3.median(values) ?? 0,
  };

  final decorated = <(String, double)>[
    for (final entry in categoryToValues.entries)
      (entry.key, aggregate(entry.value)),
  ];
  final sorted = stableSort<(String, double)>(
    decorated,
    // utilities.ts:2093-2098 — a[1] - b[1], or b[1] - a[1] when descending.
    (a, b) => descending ? b.$2.compareTo(a.$2) : a.$2.compareTo(b.$2),
  );
  return <String>[for (final entry in sorted) entry.$1];
}

/// The axis kind [value] drives.
///
/// Ports `getTypeOfAxis` (`utilities.ts:1686-1706`). [isXAxis] selects which of
/// upstream's two enums the answer is drawn from; because `XAxisTypes`
/// (`:110-114`) and `YAxisType` (`:116-120`) are byte-identical at the same
/// ordinals, both branches produce the same [FluentChartAxisType] and the
/// parameter is kept only so that call sites read like the original.
///
/// Named rather than positional, per `avoid_positional_boolean_parameters`.
FluentChartAxisType getTypeOfAxis(Object value, {required bool isXAxis}) =>
    chartAxisTypeOf(value);

/// Whether a line or area chart's x axis is a date axis.
///
/// Ports `getXAxisType` (`utilities.ts:1330-1341`).
///
/// `// parity:` the `return` at `:1336` sits inside a `forEach` callback, which
/// returns from the callback and not from the loop. The verdict therefore
/// reflects the **last** non-empty series rather than the first, so a numeric
/// series after a date series flips the answer. Reproduced verbatim.
bool getXAxisType(List<FluentLineChartSeries> points) {
  var isDate = false;
  if (points.isEmpty) return isDate;
  for (final series in points) {
    if (series.data.isEmpty) continue;
    final first = series.data.first;
    final x = switch (first) {
      final FluentLineChartDataPoint point => point.x,
      final FluentScatterChartDataPoint point => point.x,
      _ => null,
    };
    isDate = x is DateTime;
  }
  return isDate;
}

/// The d3 curve factory [curve] names.
///
/// Ports `getCurveFactory` (`utilities.ts:2012-2034`), including the
/// caller-supplied-factory arm at `:2016-2018`: upstream's `curve` prop is
/// `'linear' | 'natural' | 'step' | 'stepAfter' | 'stepBefore' | CurveFactory`
/// (`types/DataPoint.ts:448`), so this accepts either a [FluentLineCurve] or a
/// [d3.D3CurveFactory] and falls back to [defaultFactory] for anything else.
d3.D3CurveFactory getCurveFactory(
  Object? curve, [
  d3.D3CurveFactory defaultFactory = d3.curveLinear,
]) => switch (curve) {
  final d3.D3CurveFactory factory => factory,
  FluentLineCurve.linear => d3.curveLinear,
  FluentLineCurve.natural => d3.curveNatural,
  FluentLineCurve.step => d3.curveStep,
  FluentLineCurve.stepAfter => d3.curveStepAfter,
  FluentLineCurve.stepBefore => d3.curveStepBefore,
  _ => defaultFactory,
};

/// The width left for bars once the margins are taken out.
///
/// Ports `calcTotalWidth` (`vbc-utils.ts:43-45`). [extraMargin] is subtracted
/// from **both** sides.
double calcTotalWidth(
  double containerWidth,
  FluentChartMargins margins, [
  double extraMargin = 0,
]) =>
    containerWidth -
    (margins.left ?? 0) -
    (margins.right ?? 0) -
    // vbc-utils.ts:45 — one extra margin per side, hence the 2.
    extraMargin * 2;

/// The combined size of every band and every gap, measured in bandwidths.
///
/// Ports `calcTotalBandUnits` (`vbc-utils.ts:50-56`). d3's inner padding is
/// `gap / (gap + bandwidth)`, so `gap = (p / (1 - p)) * bandwidth` and
/// `n` bands carry `n - 1` gaps.
double calcTotalBandUnits(int numBands, double innerPadding) {
  // vbc-utils.ts:56. The 1 is the whole of the unit interval the padding is a
  // fraction of.
  final gapToBandRatio = innerPadding / (1 - innerPadding);
  // vbc-utils.ts:57 — n bands, and the 1 fewer gaps between them.
  return numBands + (numBands - 1) * gapToBandRatio;
}

/// The width needed to draw [numBands] bands of [bandwidth] with their gaps.
///
/// Ports `calcRequiredWidth` (`vbc-utils.ts:61-63`).
double calcRequiredWidth(double bandwidth, int numBands, double innerPadding) =>
    bandwidth * calcTotalBandUnits(numBands, innerPadding);

/// The bandwidth at which [numBands] bands and their gaps exactly fill
/// [totalWidth].
///
/// Ports `calcBandwidth` (`vbc-utils.ts:69-71`). The inverse of
/// [calcRequiredWidth].
double calcBandwidth(double totalWidth, int numBands, double innerPadding) =>
    totalWidth / calcTotalBandUnits(numBands, innerPadding);

/// The smallest gap between adjacent values in [data], and the whole span, or
/// null when there are fewer than two values.
///
/// Ports `getClosestPairDiffAndRange` (`vbc-utils.ts:3-23`). A [DateTime] is
/// measured in milliseconds since epoch, matching `getTime()`.
///
/// `// ponytail:` `vbc-utils.ts:8` sorts the caller's array in place and hands
/// it back rearranged. That side effect changes no rendered output, so this
/// copies rather than reproducing it.
(double, double)? getClosestPairDiffAndRange(List<Object> data) {
  // vbc-utils.ts:4-6. The 2 is upstream's own bound: one point has no pair.
  if (data.length < 2) return null;
  double asNumber(Object value) => value is DateTime
      ? value.millisecondsSinceEpoch.toDouble()
      : (value as num).toDouble();
  final sorted = data.map(asNumber).toList()..sort();
  // vbc-utils.ts:10 `Number.MAX_VALUE`, the seed a `Math.min` fold needs.
  var minDiff = double.maxFinite;
  // vbc-utils.ts:11 starts at the second element, so the 1 is the first gap.
  for (var i = 1; i < sorted.length; i++) {
    final diff = sorted[i] - sorted[i - 1];
    if (diff < minDiff) minDiff = diff;
  }
  // vbc-utils.ts:18-21.
  return (minDiff, sorted.last - sorted.first);
}

/// The bar width that stops bars overlapping on a continuous axis.
///
/// Ports `calculateAppropriateBarWidth` (`vbc-utils.ts:25-40`). The derivation
/// of the formula is at
/// <https://microsoft.github.io/fluentui-charting-contrib/docs/rfcs/fix-overlapping-bars-on-continuous-axes>.
///
/// 16 is the fallback when there are too few points or the whole span is zero,
/// and it is the same `DEFAULT_BAR_WIDTH` as [kDefaultBarWidth]
/// (`vbc-utils.ts:32`).
double calculateAppropriateBarWidth(
  List<Object> data,
  double totalWidth,
  double innerPadding,
) {
  final result = getClosestPairDiffAndRange(data);
  // vbc-utils.ts:31-33. The 0 is upstream's own `result[1] === 0`.
  if (result == null || result.$2 == 0) return kDefaultBarWidth;
  final (closestPairDiff, range) = result;
  // vbc-utils.ts:36-38. The 1 is the whole of the unit interval the inner
  // padding is a fraction of, so `1 - innerPadding` is the share of a band
  // step the band itself occupies.
  return ((totalWidth * closestPairDiff * (1 - innerPadding)) /
          (range + closestPairDiff * (1 - innerPadding)))
      .floorToDouble();
}
