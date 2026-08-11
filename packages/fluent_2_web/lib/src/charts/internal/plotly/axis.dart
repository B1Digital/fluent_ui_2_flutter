/// Axis resolution for the Plotly figure adapters.
///
/// Ports `PlotlySchemaAdapter.ts:4103-4232`. Internal to the package: nothing
/// here is barrel-exported, exactly as `internal/d3/` is not.
library;

import 'package:flutter/foundation.dart';

import 'predicates.dart';

/// The Plotly axis types this port understands.
///
/// `PlotlySchemaAdapter.ts:4146` only ever *accepts* the first four from the
/// schema; a declared `multicategory` falls through to inference and is never
/// returned by [getAxisType]. The value exists so a declared axis type survives
/// being read back out of a layout without becoming a null.
enum FluentPlotlyAxisType {
  /// A numeric axis (`PlotlySchemaAdapter.ts:4164`).
  linear,

  /// A logarithmic axis, resolved exactly like [linear]
  /// (`PlotlySchemaAdapter.ts:4184-4186` shares one arm).
  log,

  /// A time axis (`PlotlySchemaAdapter.ts:4167`).
  date,

  /// A string axis (`PlotlySchemaAdapter.ts:4169`).
  category,

  /// Declared-only; resolves every value to null through the `default` arm at
  /// `PlotlySchemaAdapter.ts:4200-4201`.
  multicategory,
}

/// The ISO 8601 subset upstream calls "experimental"
/// (`PlotlySchemaAdapter.ts:4209`).
///
/// Group 3 is the whole `T…` time part and group 6 is a trailing `Z`; both are
/// read by [parseLocalDate] at `PlotlySchemaAdapter.ts:4224-4228`.
final RegExp isoDateRegex = RegExp(
  r'^\d{4}(-\d{2}(-\d{2})?)?(T\d{2}:\d{2}(:\d{2}(\.\d{1,9})?)?(Z)?)?$',
);

/// Reads a datetime as **local** time (`PlotlySchemaAdapter.ts:4220-4232`).
///
/// Charts render localised datetimes with `useUTC` false, which upstream works
/// around by rewriting the string before handing it to `new Date`: a date with
/// no time part gains `T00:00`, and a trailing `Z` is stripped. Returns null
/// where upstream returns an Invalid Date, which is the same thing every caller
/// does with it (`:4175`).
///
/// `// parity break:` `new Date` also accepts a handful of non-ISO spellings
/// such as `'March 5, 2024'`, which `DateTime.tryParse` refuses. The ceiling is
/// the same one `model/chart_value.dart:92` already carries for `isDateLike`,
/// so a value that cannot be parsed here was never classified as a date either.
DateTime? parseLocalDate(Object? value) {
  if (value is num) {
    // `new Date(number)` is milliseconds since the epoch.
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is! String) return null;
  var text = value;
  final match = isoDateRegex.firstMatch(text);
  if (match != null) {
    if (match.group(3) == null) {
      // `PlotlySchemaAdapter.ts:4224-4225`.
      text = '${text}T00:00';
    } else if (match.group(6) != null) {
      // `PlotlySchemaAdapter.ts:4226-4227`.
      text = text.replaceFirst('Z', '');
    }
  }
  // A year-only or year-month string becomes `2024T00:00` / `2024-01T00:00`,
  // which V8 also rejects as an Invalid Date, so null is parity here.
  return DateTime.tryParse(text);
}

/// JavaScript's bare `new Date(value)` (`PlotlySchemaAdapter.ts:4174`).
///
/// [getAxisValueResolver] is called without a `dateParser` at
/// `PlotlySchemaAdapter.ts:1405`, `:2003` and `:3186`, and *with*
/// [parseLocalDate] at `:2307`. The two disagree: a date-only ISO string is
/// UTC midnight under `new Date` and local midnight under [parseLocalDate], so
/// the distinction is load-bearing and both paths are kept. The non-ISO ceiling
/// noted on [parseLocalDate] applies here too.
DateTime? _jsNewDate(Object? value) {
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is! String) return null;
  final match = isoDateRegex.firstMatch(value);
  if (match != null && match.group(3) == null) {
    // `DateTime.parse` reads a date-only string as local, JavaScript as UTC.
    // Pad the absent month and day so both languages name the same instant.
    final parts = value.split('-');
    // Index 1 is the month and index 2 the day of a `YYYY-MM-DD` split; each
    // defaults to `'01'` because that is what `new Date('2024')` invents.
    final month = parts.length > 1 ? parts[1] : '01';
    final day = parts.length > 2 ? parts[2] : '01';
    return DateTime.tryParse('${parts[0]}-$month-${day}T00:00:00Z');
  }
  return DateTime.tryParse(value);
}

/// One resolved axis of a figure (`PlotlySchemaAdapter.ts:4103-4105`).
@immutable
class FluentPlotlyAxisObject {
  /// Creates an axis object.
  const FluentPlotlyAxisObject({
    required this.letter,
    required this.id,
    required this.key,
    required this.layoutAxis,
    required this.traceIndices,
  });

  /// `'x'` or `'y'` (`PlotlySchemaAdapter.ts:4119`).
  final String letter;

  /// The one-based axis id, so `y2` is 2 and a bare `y` is 1
  /// (`predicates.dart`'s `getAxisIds`).
  final int id;

  /// The layout key this axis reads, `xaxis` / `yaxis` / `yaxis2`
  /// (`PlotlySchemaAdapter.ts:4120`, via `getAxisKey`).
  final String key;

  /// The layout slice for [key], empty when the layout declares none
  /// (`PlotlySchemaAdapter.ts:4120` spreads `undefined` to `{}`).
  final Map<String, Object?> layoutAxis;

  /// Indices into `data` of every trace anchored to this axis.
  ///
  /// Replaces upstream's re-scan of `series['${letter}axis'] === ax._id`
  /// at `PlotlySchemaAdapter.ts:4154`; `getAxisIds` already normalises an
  /// absent anchor to 1, so comparing ids is exactly that test.
  final List<int> traceIndices;
}

/// Collects the x axis and up to two y axes a group of traces anchors to
/// (`PlotlySchemaAdapter.ts:4107-4139`).
///
/// The returned list is ordered x, then the lowest y, then the second-lowest —
/// upstream's `axisObjects.x` / `.y` / `.y2` insertion order at `:4127-4135`.
/// Every trace in a group shares one x axis (`:4108-4110`), so the last trace
/// read wins, exactly as `xAxisId` is reassigned at `:4115`.
///
/// `PlotlySchemaAdapter.ts:4130` sorts the y ids with a bare `Array.sort()`,
/// which is lexicographic in JavaScript. Here the ids are `int`, and Dart's
/// `List<int>.sort()` is numeric — for one-digit axis ids the two orders agree,
/// so no `// parity:` marker is warranted. A figure with `yaxis2` … `yaxis11`
/// would diverge, and Plotly caps subplot axes well below that.
List<FluentPlotlyAxisObject> getAxisObjects(
  List<Object?> data,
  Map<String, Object?>? layout,
) {
  int? xAxisId;
  final yAxisIds = <int>{};
  final xTraces = <int, List<int>>{};
  final yTraces = <int, List<int>>{};
  for (var index = 0; index < data.length; index++) {
    final series = data[index];
    if (series is! Map<String, Object?>) continue;
    final axisIds = getAxisIds(series);
    xAxisId = axisIds.x;
    yAxisIds.add(axisIds.y);
    (xTraces[axisIds.x] ??= <int>[]).add(index);
    (yTraces[axisIds.y] ??= <int>[]).add(index);
  }

  FluentPlotlyAxisObject makeAxisObject(
    String letter,
    int id,
    List<int> indices,
  ) {
    final key = getAxisKey(letter, id);
    final declared = layout?[key];
    return FluentPlotlyAxisObject(
      letter: letter,
      id: id,
      key: key,
      layoutAxis: declared is Map<String, Object?>
          ? declared
          : const <String, Object?>{},
      traceIndices: indices,
    );
  }

  final axisObjects = <FluentPlotlyAxisObject>[];
  if (xAxisId != null) {
    // `PlotlySchemaAdapter.ts:4126-4128`.
    axisObjects.add(
      makeAxisObject('x', xAxisId, xTraces[xAxisId] ?? const <int>[]),
    );
  }
  final sortedYAxisIds = yAxisIds.toList()..sort();
  if (sortedYAxisIds.isNotEmpty) {
    // `PlotlySchemaAdapter.ts:4131-4133`: index 0 is the lowest y axis id.
    final id = sortedYAxisIds[0];
    axisObjects.add(makeAxisObject('y', id, yTraces[id] ?? const <int>[]));
  }
  if (sortedYAxisIds.length > 1) {
    // `PlotlySchemaAdapter.ts:4134-4136`: index 1 is the secondary y axis, and
    // a third is dropped.
    final id = sortedYAxisIds[1];
    axisObjects.add(makeAxisObject('y', id, yTraces[id] ?? const <int>[]));
  }
  return axisObjects;
}

/// Decides how one axis reads its data (`PlotlySchemaAdapter.ts:4141-4170`).
///
/// [ax] is nullable because [getAxisObjects] can return no x axis at all for an
/// empty group, which is the case upstream guards at `:4142-4144` — the
/// signature in this plan's Interfaces block omits the `?`, and it is restored
/// here so that guard has somewhere to live.
///
/// The inference order is upstream's, and it is **not** the order this task's
/// prose described: numeric-but-not-a-year wins first (`:4163`), then a date
/// array (`:4166`), and everything else — strings, months, years — is a
/// category (`:4169`).
FluentPlotlyAxisType getAxisType(
  List<Object?> data,
  FluentPlotlyAxisObject? ax,
) {
  if (ax == null) {
    // `PlotlySchemaAdapter.ts:4142-4144`.
    return FluentPlotlyAxisType.category;
  }

  // `PlotlySchemaAdapter.ts:4146-4148`: only these four are honoured, so a
  // declared `multicategory` is inferred instead.
  switch (ax.layoutAxis['type']) {
    case 'linear':
      return FluentPlotlyAxisType.linear;
    case 'log':
      return FluentPlotlyAxisType.log;
    case 'date':
      return FluentPlotlyAxisType.date;
    case 'category':
      return FluentPlotlyAxisType.category;
    default:
      break;
  }

  final values = <Object?>[];
  for (final index in ax.traceIndices) {
    final series = data[index];
    if (series is! Map<String, Object?>) continue;
    final column = series[ax.letter];
    if (column is! List<Object?>) continue;
    for (final value in column) {
      // `PlotlySchemaAdapter.ts:4156-4158`.
      if (!isInvalidValue(value)) values.add(value);
    }
  }

  if (isNumberArray(values) && !isYearArray(values)) {
    // `PlotlySchemaAdapter.ts:4163-4165`.
    return FluentPlotlyAxisType.linear;
  }
  if (isDateArray(values)) {
    // `PlotlySchemaAdapter.ts:4166-4168`.
    return FluentPlotlyAxisType.date;
  }
  // `PlotlySchemaAdapter.ts:4169`.
  return FluentPlotlyAxisType.category;
}

/// Builds the per-axis value coercion (`PlotlySchemaAdapter.ts:4172-4204`).
///
/// [dateParser] is upstream's optional second argument. Omitted, a date axis
/// uses JavaScript's bare `new Date` (`:4174`, the three call sites at `:1405`,
/// `:2003` and `:3186`); supplied, it is [parseLocalDate] (`:2307`). The plan's
/// Interfaces block lists the one-argument form; the parameter is optional, so
/// that call form still compiles.
Object? Function(Object?) getAxisValueResolver(
  FluentPlotlyAxisType type, {
  DateTime? Function(Object?)? dateParser,
}) {
  DateTime? toDate(Object? value) =>
      dateParser == null ? _jsNewDate(value) : dateParser(value);

  return (Object? value) {
    if (isInvalidValue(value)) {
      // `PlotlySchemaAdapter.ts:4179-4181`.
      return null;
    }
    switch (type) {
      case FluentPlotlyAxisType.linear:
      case FluentPlotlyAxisType.log:
        // `PlotlySchemaAdapter.ts:4184-4186`: unary `+` on a numeric string.
        if (!isPlotlyNumber(value)) return null;
        return value is num ? value.toDouble() : double.tryParse('$value');
      case FluentPlotlyAxisType.date:
        if (isPlotlyNumber(value)) {
          // `PlotlySchemaAdapter.ts:4189-4190`.
          final ms = value is num
              ? value.toDouble()
              : double.tryParse('$value');
          return ms == null ? null : toDate(ms);
        }
        if (value is String) {
          // `PlotlySchemaAdapter.ts:4192-4193`.
          return toDate(value);
        }
        return null;
      case FluentPlotlyAxisType.category:
        // `PlotlySchemaAdapter.ts:4197-4198`.
        return '$value';
      case FluentPlotlyAxisType.multicategory:
        // `PlotlySchemaAdapter.ts:4200-4201`, the `default` arm.
        return null;
    }
  };
}
