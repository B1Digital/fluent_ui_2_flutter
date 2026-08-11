/// The value predicates every Plotly routing decision stands on.
///
/// Ports `PlotlySchemaConverter.ts:41-158`, `:172-174` and `:652-675`. Internal
/// to the package: nothing here is barrel-exported, exactly as `internal/d3/`
/// is not.
library;

import '../../model/chart_value.dart';

/// Full English month names, used by [isPlotlyMonth].
///
/// `PlotlySchemaConverter.ts:76` probes the system locale and then `en-US`. In a
/// Flutter test the system locale is undefined, so the port pins English, which
/// is what every upstream fixture and every `en-US` pass already resolve to.
/// // parity: PlotlySchemaConverter.ts:76
const List<String> kMonthNames = <String>[
  'january',
  'february',
  'march',
  'april',
  'may',
  'june',
  'july',
  'august',
  'september',
  'october',
  'november',
  'december',
];

/// Three-letter English month abbreviations (`PlotlySchemaConverter.ts:81`).
const List<String> kShortMonthNames = <String>[
  'jan',
  'feb',
  'mar',
  'apr',
  'may',
  'jun',
  'jul',
  'aug',
  'sep',
  'oct',
  'nov',
  'dec',
];

/// JavaScript `!isNaN(parseFloat(v)) && isFinite(v)` (`PlotlySchemaConverter.ts:41`).
///
/// This is [isNumberLike] under the name the Plotly router uses. The port keeps
/// one implementation: `model/chart_value.dart:72-77` already ports this exact
/// line, down to the reason the two halves of the upstream expression collapse
/// into the single `num.tryParse` at `:75`.
bool isPlotlyNumber(Object? value) => isNumberLike(value);

/// Whether [value] parses as a date under Plotly's rules
/// (`PlotlySchemaConverter.ts:44-60`).
///
/// This is [isDateLike] under the name the Plotly router uses. `model/
/// chart_value.dart:89` already ports the whole of it, including the
/// year-2000/2001 rule at `:56-58` that keeps `new Date('Jan 5')`'s invented
/// year off a date axis.
bool isPlotlyDate(Object? value) => isDateLike(value);

/// Whether [value] is an English month name, long or short
/// (`PlotlySchemaConverter.ts:64-91`).
bool isPlotlyMonth(Object? value) {
  if (value is! String) return false;
  final lower = value.toLowerCase();
  return kMonthNames.contains(lower) || kShortMonthNames.contains(lower);
}

/// Whether [value] is an integer year in 1900..2100
/// (`PlotlySchemaConverter.ts:93-99`).
bool isPlotlyYear(Object? value) {
  if (!isPlotlyNumber(value)) return false;
  final n = value is num ? value : num.parse((value! as String).trim());
  // 1900 and 2100 are the literal bounds at PlotlySchemaConverter.ts:96.
  return n == n.roundToDouble() && n >= 1900 && n <= 2100;
}

/// Applies [check] to every element, descending one level into 2-D arrays.
///
/// `PlotlySchemaConverter.ts:101-121`. An empty array is **false**, not true —
/// `:110-112` short-circuits before `every`, which would otherwise be vacuously
/// true and would route empty traces to the wrong chart.
///
/// `// parity break:` `:116` calls `innerArray.every` without checking that the
/// row is an array, so a ragged input throws there. The port returns false. The
/// input is untrusted JSON and a throw here would abort the whole conversion.
bool isArrayOfType(Object? data, bool Function(Object?) check) {
  if (data is! List<Object?>) return false;
  if (data.isEmpty) return false;
  if (data.first is List<Object?>) {
    return data.every((inner) => inner is List<Object?> && inner.every(check));
  }
  return data.every(check);
}

/// `PlotlySchemaConverter.ts:123-126`.
bool isDateArray(Object? data) =>
    isArrayOfType(data, (v) => isPlotlyDate(v) || v == null);

/// `PlotlySchemaConverter.ts:128-135`.
bool isNumberArray(Object? data) => isArrayOfType(
  data,
  (v) => (v is String && isPlotlyNumber(v)) || v is num || v == null,
);

/// `PlotlySchemaConverter.ts:137-140`.
bool isMonthArray(Object? data) =>
    isArrayOfType(data, (v) => isPlotlyMonth(v) || v == null);

/// `PlotlySchemaConverter.ts:142-145`.
bool isYearArray(Object? data) =>
    isArrayOfType(data, (v) => isPlotlyYear(v) || v == null);

/// `PlotlySchemaConverter.ts:147-150`.
bool isStringArray(Object? data) =>
    isArrayOfType(data, (v) => v is String || v == null);

/// `PlotlySchemaConverter.ts:152-158`.
///
/// Unlike its neighbours this one refuses null, because `:156` guards
/// `value !== null` before the `typeof value === 'object'` test.
bool isObjectArray(Object? data) =>
    isArrayOfType(data, (v) => v is Map<String, Object?>);

/// `PlotlySchemaConverter.ts:172-174`.
///
/// This is [isInvalidChartValue] under the name the Plotly router uses;
/// `model/chart_value.dart:53` already ports the line, including why the empty
/// string is not rejected.
bool isInvalidValue(Object? value) => isInvalidChartValue(value);

/// Rejects a trace whose `x` or `y` is a 2-D array
/// (`PlotlySchemaConverter.ts:160-169`).
bool validate2DSeries(Map<String, Object?> series) {
  for (final key in const <String>['x', 'y']) {
    final v = series[key];
    if (v is List<Object?> && v.isNotEmpty && v.first is List<Object?>) {
      return false;
    }
  }
  return true;
}

final RegExp _axisRef = RegExp(r'^([xy])(\d+)$');

/// The 1-based axis indices a trace is anchored to
/// (`PlotlySchemaConverter.ts:652-667`).
({int x, int y}) getAxisIds(Map<String, Object?> trace) {
  // `:654` matches /^x\d+$/ against `xaxis` and `:659` matches /^y\d+$/ against
  // `yaxis`, so the letter has to agree with the field it was read from.
  int read(String key, String letter) {
    final raw = trace[key];
    if (raw is! String) return 1;
    final match = _axisRef.firstMatch(raw);
    if (match == null || match.group(1) != letter) return 1;
    // A digit run wider than 64 bits makes `int.parse` throw where JS
    // `parseInt` would not; falling back to the default keeps hostile JSON
    // from aborting the conversion.
    return int.tryParse(match.group(2)!) ?? 1;
  }

  return (x: read('xaxis', 'x'), y: read('yaxis', 'y'));
}

/// The layout key for an axis (`PlotlySchemaConverter.ts:669-671`).
///
/// Axis 1 has no suffix, so `('y', 1)` is `yaxis` and `('y', 2)` is `yaxis2`.
String getAxisKey(String letter, int id) => '${letter}axis${id > 1 ? id : ''}';

/// Whether a scatter trace renders as an area (`PlotlySchemaConverter.ts:673-675`).
bool isScatterAreaChart(Map<String, Object?> trace) {
  final fill = trace['fill'];
  // `:674` reads `!!data.stackgroup` and `stackgroup` is typed `string`, so the
  // empty string is falsy — the same JS-truthiness rule `axis_builders.dart:951`
  // applies to `useUTC`.
  final stackgroup = trace['stackgroup'];
  return fill == 'tonexty' ||
      fill == 'tozeroy' ||
      (stackgroup != null && stackgroup != '');
}
