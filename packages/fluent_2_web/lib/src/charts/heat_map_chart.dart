import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'internal/chart_utils.dart';
import 'internal/d3/format.dart' as d3;
import 'internal/d3/stable_sort.dart';
import 'internal/d3/time_format.dart' as d3;
import 'model/chart_common.dart';
import 'model/heatmap_data.dart';

/// One heat-map cell, matched or synthesised.
@immutable
class FluentHeatMapCell {
  /// Creates a cell.
  const FluentHeatMapCell({
    required this.x,
    required this.y,
    required this.value,
    required this.rectText,
    required this.legend,
    required this.isPlaceholder,
    this.ratio,
    this.descriptionMessage,
    this.onTap,
    this.semantics,
  });

  /// The formatted x label.
  final String x;

  /// The formatted y label.
  final String y;

  /// The cell value, `double.nan` for a placeholder.
  final double value;

  /// The painted text — a `num` or a [String]
  /// (`types/DataPoint.ts:855-858`).
  final Object rectText;

  /// The owning series legend, empty for a placeholder.
  final String legend;

  /// Whether this cell is a synthesised miss (`HeatMapChart.tsx:250-278`).
  final bool isPlaceholder;

  /// Optional numerator/denominator shown in the popover.
  final (double, double)? ratio;

  /// Optional trailing popover paragraph.
  final String? descriptionMessage;

  /// Tap handler.
  final VoidCallback? onTap;

  /// Accessible overrides.
  final FluentChartSemantics? semantics;
}

/// The reshaped heat-map grid.
@immutable
class FluentHeatMapDataSet {
  /// Creates a data set.
  const FluentHeatMapDataSet({
    required this.rows,
    required this.xAxisPoints,
    required this.yAxisPoints,
  });

  /// Cells keyed by formatted y label, then by formatted x label.
  final Map<String, Map<String, FluentHeatMapCell>> rows;

  /// Ordered, formatted x labels.
  final List<String> xAxisPoints;

  /// Ordered, formatted y labels.
  final List<String> yAxisPoints;

  /// The cell at ([x], [y]), or null when neither a match nor a placeholder
  /// exists.
  FluentHeatMapCell? cellAt(String x, String y) => rows[y]?[x];
}

/// Ports `_createNewDataSet` (`HeatMapChart.tsx:466-590`) plus the ordering
/// pipeline at `:641-731`.
///
/// Upstream keys a mutable map, re-keys it with the formatted label while
/// leaving the original key in place (`:553-561`) and then walks it with an
/// index cursor that only advances on a match (`:197`). This port builds the
/// grid up front and looks cells up by key, which is observationally identical
/// and cannot mis-align — the cursor's only purpose was to avoid an O(n²) scan
/// over a list that was already sorted.
///
/// `// parity:` upstream keys, sorts and only then formats, so a date or
/// numeric axis sorts on the raw value (`+a - +b`, `:645-646` and `:660-661`)
/// and [alphabeticalSort] — upstream's `sortOrder` — applies to a string axis
/// alone (`:711-717`). This port formats first and applies [alphabeticalSort]
/// to the formatted label on both axes, because the axis type is not one of
/// its inputs. The two agree wherever a format is order-preserving, which the
/// `%b/%d` labels of the captured story are; they diverge across a month
/// boundary ('Apr/01' sorts before 'Mar/15') and on `.2~s` numbers ('1.5k'
/// sorts before '900').
FluentHeatMapDataSet buildFluentHeatMapDataSet({
  required List<FluentHeatMapChartData> data,
  required FluentAxisCategoryOrder xAxisCategoryOrder,
  required FluentAxisCategoryOrder yAxisCategoryOrder,
  required bool alphabeticalSort,
  String? xAxisDateFormat,
  String? yAxisDateFormat,
  String? xAxisNumberFormat,
  String? yAxisNumberFormat,
  String Function(String)? xAxisStringFormatter,
  String Function(String)? yAxisStringFormatter,
}) {
  String formatKey(
    Object raw, {
    required String? dateFormat,
    required String? numberFormat,
    required String Function(String)? stringFormatter,
  }) {
    if (raw is DateTime) {
      // The '%b/%d' default at HeatMapChart.tsx:595.
      return d3.timeFormat(dateFormat ?? '%b/%d')(raw);
    }
    if (raw is num) {
      // The '.2~s' default at HeatMapChart.tsx:599.
      return d3.format(numberFormat ?? '.2~s')(raw);
    }
    return (stringFormatter ?? (String s) => s)(raw as String);
  }

  final rows = <String, Map<String, FluentHeatMapCell>>{};
  // `_mapCategoryToValues` (HeatMapChart.tsx:719-731). Dart maps enumerate in
  // insertion order, so `keys` is also upstream's `uniqueXPoints` /
  // `uniqueYPoints` key order (`:498-499`) and no separate list is needed.
  final xValues = <String, List<double>>{};
  final yValues = <String, List<double>>{};

  for (final series in data) {
    for (final point in series.data) {
      final xKey = formatKey(
        point.x,
        dateFormat: xAxisDateFormat,
        numberFormat: xAxisNumberFormat,
        stringFormatter: xAxisStringFormatter,
      );
      final yKey = formatKey(
        point.y,
        dateFormat: yAxisDateFormat,
        numberFormat: yAxisNumberFormat,
        stringFormatter: yAxisStringFormatter,
      );
      (xValues[xKey] ??= <double>[]).add(point.value);
      (yValues[yKey] ??= <double>[]).add(point.value);
      (rows[yKey] ??= <String, FluentHeatMapCell>{})[xKey] = FluentHeatMapCell(
        x: xKey,
        y: yKey,
        value: point.value,
        rectText: point.rectText ?? point.value,
        legend: series.legend,
        isPlaceholder: false,
        ratio: point.ratio,
        descriptionMessage: point.descriptionMessage,
        onTap: point.onClick,
        semantics: point.callOutSemantics,
      );
    }
  }

  List<String> order(
    Map<String, List<double>> values,
    FluentAxisCategoryOrder categoryOrder,
  ) {
    // `props.xAxisCategoryOrder !== 'default'` (HeatMapChart.tsx:712).
    if (categoryOrder is! FluentAxisCategoryOrderPreset ||
        categoryOrder.upstreamName != 'default') {
      return sortAxisCategories(values, categoryOrder);
    }
    // `sortOrder === 'none' ? 0 : a.toLowerCase() > b.toLowerCase() ? 1 : -1`
    // (`HeatMapChart.tsx:648`). A stable sort is required so that a comparator
    // returning 0 preserves insertion order.
    return stableSort<String>(
      values.keys.toList(),
      (a, b) => alphabeticalSort
          ? (a.toLowerCase().compareTo(b.toLowerCase()) > 0 ? 1 : -1)
          : 0,
    );
  }

  final xAxisPoints = order(xValues, xAxisCategoryOrder);
  final yAxisPoints = order(yValues, yAxisCategoryOrder);

  for (final y in yAxisPoints) {
    final row = rows[y] ??= <String, FluentHeatMapCell>{};
    for (final x in xAxisPoints) {
      row[x] ??= FluentHeatMapCell(
        x: x,
        y: y,
        value: double.nan,
        // The literal at HeatMapChart.tsx:255.
        rectText: 'No data available',
        legend: '',
        isPlaceholder: true,
      );
    }
  }

  return FluentHeatMapDataSet(
    rows: rows,
    xAxisPoints: xAxisPoints,
    yAxisPoints: yAxisPoints,
  );
}

/// The heat-map colour ramp.
///
/// Ports `_getColorScale` (`HeatMapChart.tsx:351-356`): a `scaleLinear` whose
/// range is colour strings, which d3 dispatches to `interpolateRgb` (gamma 1),
/// piecewise for more than two stops and **unclamped**, so values outside the
/// domain extrapolate rather than saturate.
Color fluentHeatMapColourAt(
  double value, {
  required List<double> domain,
  required List<Color> range,
}) {
  if (range.isEmpty) {
    return const Color(0x00000000);
  }
  if (range.length == 1 || domain.length < 2) {
    return range.first;
  }
  var i = 1;
  while (i < domain.length - 1 && value > domain[i]) {
    i++;
  }
  final span = domain[i] - domain[i - 1];
  final t = span == 0 ? 0.0 : (value - domain[i - 1]) / span;
  final a = range[i - 1];
  final b = range[math.min(i, range.length - 1)];
  // Unclamped lerp: t may fall outside [0, 1], so the clamp is on the channel
  // and not on t. `roundToDouble` rounds half away from zero, which is what
  // JavaScript's `Math.round` does for the non-negative channels d3-color
  // serialises.
  double channel(double lo, double hi) =>
      (lo + (hi - lo) * t).clamp(0, 255).roundToDouble();
  return Color.fromARGB(
    255,
    channel(a.r * 255, b.r * 255).toInt(),
    channel(a.g * 255, b.g * 255).toInt(),
    channel(a.b * 255, b.b * 255).toInt(),
  );
}
