/// Axis resolution for the Plotly figure adapters.
///
/// Ports `PlotlySchemaAdapter.ts:4103-4232`. Internal to the package: nothing
/// here is barrel-exported, exactly as `internal/d3/` is not.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../axis/axis_types.dart';
import '../../model/chart_common.dart';
import '../../model/polar_data.dart';
import '../d3/js_math.dart' as d3;
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

/// The tick configuration a Plotly layout implies for a cartesian chart
/// (`PlotlySchemaAdapter.ts:3956-3959`).
///
/// Upstream returns a `Pick<>` of six `CartesianChartProps` keys, two of which
/// (`xAxis`, `yAxis`) are themselves objects. Flattened here into twelve
/// nullable fields so the transformers can spread them into
/// `FluentCartesianChartProps` without a second unwrap.
@immutable
class FluentPlotlyTickProps {
  /// Creates a tick-props record. Every field null means "inject nothing".
  const FluentPlotlyTickProps({
    this.xAxisTickValues,
    this.xAxisTickText,
    this.xAxisTickCount,
    this.xAxisTickStep,
    this.xAxisTick0,
    this.xAxisTickLayout = FluentTickLayout.defaultLayout,
    this.yAxisTickValues,
    this.yAxisTickText,
    this.yAxisTickCount,
    this.yAxisTickStep,
    this.yAxisTick0,
    this.yAxisTickLayout = FluentTickLayout.defaultLayout,
  });

  /// Explicit x tick positions (`PlotlySchemaAdapter.ts:3986`).
  ///
  /// `DateTime` entries on a date axis, raw schema values otherwise.
  final List<Object>? xAxisTickValues;

  /// Explicit x tick labels (`PlotlySchemaAdapter.ts:3989`).
  final List<String>? xAxisTickText;

  /// The requested x tick count from `nticks` (`PlotlySchemaAdapter.ts:4023`).
  final int? xAxisTickCount;

  /// The cleaned `dtick` for x (`PlotlySchemaAdapter.ts:4008`).
  final Object? xAxisTickStep;

  /// The cleaned `tick0` for x (`PlotlySchemaAdapter.ts:4009`).
  final Object? xAxisTick0;

  /// `auto` only for a category x axis (`PlotlySchemaAdapter.ts:3976-3980`).
  final FluentTickLayout xAxisTickLayout;

  /// Explicit y tick positions (`PlotlySchemaAdapter.ts:3992`).
  final List<Object>? yAxisTickValues;

  /// Explicit y tick labels (`PlotlySchemaAdapter.ts:3995`).
  final List<String>? yAxisTickText;

  /// The requested y tick count from `nticks` (`PlotlySchemaAdapter.ts:4025`).
  final int? yAxisTickCount;

  /// The cleaned `dtick` for y (`PlotlySchemaAdapter.ts:4014`).
  final Object? yAxisTickStep;

  /// The cleaned `tick0` for y (`PlotlySchemaAdapter.ts:4015`).
  final Object? yAxisTick0;

  /// Always [FluentTickLayout.defaultLayout]; upstream never sets a y tick
  /// layout (`PlotlySchemaAdapter.ts:3976` tests `axId === 'x'`). Present so the
  /// record is symmetric and a transformer can spread it unconditionally.
  final FluentTickLayout yAxisTickLayout;
}

/// JavaScript truthiness for the two falsy shapes a `tickmode` or `dtick` can
/// take in a decoded schema (`PlotlySchemaAdapter.ts:3982`, `:4001`, `:4021`).
bool _isFalsy(Object? value) =>
    value == null || value == '' || value == 0 || value == false;

/// Derives the tick props for the x and first y axis
/// (`PlotlySchemaAdapter.ts:3964-4031`).
///
/// The `y2` slot upstream is iterated at `:3968` but has no write arm — neither
/// `:4005` nor `:4011` matches `'y2'` — so a secondary y axis contributes no
/// ticks at all. // parity: PlotlySchemaAdapter.ts:4005-4026
FluentPlotlyTickProps getAxisTickProps(
  List<Object?> data,
  Map<String, Object?>? layout,
) {
  List<Object>? xAxisTickValues;
  List<Object>? yAxisTickValues;
  List<String>? xAxisTickText;
  List<String>? yAxisTickText;
  int? xAxisTickCount;
  int? yAxisTickCount;
  Object? xAxisTickStep;
  Object? yAxisTickStep;
  Object? xAxisTick0;
  Object? yAxisTick0;
  var xAxisTickLayout = FluentTickLayout.defaultLayout;

  var seenY = false;
  for (final ax in getAxisObjects(data, layout)) {
    final isX = ax.letter == 'x';
    final isFirstY = ax.letter == 'y' && !seenY;
    if (ax.letter == 'y') {
      seenY = true;
    }
    if (!isX && !isFirstY) {
      continue;
    }

    final axType = getAxisType(data, ax);

    if (isX && axType == FluentPlotlyAxisType.category) {
      // `PlotlySchemaAdapter.ts:3976-3980`.
      xAxisTickLayout = FluentTickLayout.auto;
    }

    final tickmode = ax.layoutAxis['tickmode'];
    final tickvals = ax.layoutAxis['tickvals'];
    if ((_isFalsy(tickmode) || tickmode == 'array') &&
        tickvals is List<Object?>) {
      // `PlotlySchemaAdapter.ts:3982-3998`.
      final values = axType == FluentPlotlyAxisType.date
          ? <Object>[for (final value in tickvals) ?_jsNewDate(value)]
          : <Object>[for (final value in tickvals) ?value];
      final ticktext = ax.layoutAxis['ticktext'];
      final text = ticktext is List<Object?>
          ? <String>[for (final entry in ticktext) '$entry']
          : null;
      if (isX) {
        xAxisTickValues = values;
        xAxisTickText = text;
      } else {
        yAxisTickValues = values;
        yAxisTickText = text;
      }
      continue;
    }

    final declaredDtick = ax.layoutAxis['dtick'];
    if ((_isFalsy(tickmode) || tickmode == 'linear') &&
        !_isFalsy(declaredDtick)) {
      // `PlotlySchemaAdapter.ts:4001-4018`.
      final dtick = plotlyDtick(declaredDtick, axType)!;
      final tick0 = plotlyTick0(ax.layoutAxis['tick0'], axType, dtick);
      if (isX) {
        xAxisTickStep = dtick;
        xAxisTick0 = tick0;
      } else {
        yAxisTickStep = dtick;
        yAxisTick0 = tick0;
      }
      continue;
    }

    final nticks = ax.layoutAxis['nticks'];
    if ((_isFalsy(tickmode) || tickmode == 'auto') &&
        nticks is num &&
        nticks >= 0) {
      // `PlotlySchemaAdapter.ts:4021-4027`.
      if (isX) {
        xAxisTickCount = nticks.toInt();
      } else {
        yAxisTickCount = nticks.toInt();
      }
    }
  }

  return FluentPlotlyTickProps(
    xAxisTickValues: xAxisTickValues,
    xAxisTickText: xAxisTickText,
    xAxisTickCount: xAxisTickCount,
    xAxisTickStep: xAxisTickStep,
    xAxisTick0: xAxisTick0,
    xAxisTickLayout: xAxisTickLayout,
    yAxisTickValues: yAxisTickValues,
    yAxisTickText: yAxisTickText,
    yAxisTickCount: yAxisTickCount,
    yAxisTickStep: yAxisTickStep,
    yAxisTick0: yAxisTick0,
  );
}

/// Cleans a `dtick` (`PlotlySchemaAdapter.ts:4036-4086`, itself a port of
/// plotly.js `clean_ticks.js#L16`).
///
/// Never returns null; the nullable return type is the one this plan's
/// Interfaces block declares, and it keeps the value assignable straight into
/// [FluentPlotlyTickProps.xAxisTickStep].
Object? plotlyDtick(Object? dtick, FluentPlotlyAxisType type) {
  final isLogAx = type == FluentPlotlyAxisType.log;
  final isDateAx = type == FluentPlotlyAxisType.date;
  final isCatAx = type == FluentPlotlyAxisType.category;
  // `PlotlySchemaAdapter.ts:4040`: 86_400_000 is one day in milliseconds.
  final Object dtickDflt = isDateAx ? 86400000 : 1;

  // `PlotlySchemaAdapter.ts:4042-4044`: JavaScript truthiness, so 0 and the
  // empty string both take the default.
  if (_isFalsy(dtick)) {
    return dtickDflt;
  }

  if (isPlotlyNumber(dtick)) {
    // `PlotlySchemaAdapter.ts:4047`: `Number(dtick)`, which accepts a numeric
    // string.
    final value = dtick is num ? dtick.toDouble() : double.parse('$dtick');
    if (value <= 0) {
      // `PlotlySchemaAdapter.ts:4048-4050`.
      return dtickDflt;
    }
    if (isCatAx) {
      // `PlotlySchemaAdapter.ts:4051-4053`: a category step is a positive
      // integer. `Math.round` is half-up, hence `d3.jsRound`.
      return math.max(1.0, d3.jsRound(value));
    }
    if (isDateAx) {
      // `PlotlySchemaAdapter.ts:4055-4057`: 0.1 ms is Plotly's stated precision
      // floor.
      return math.max(0.1, value);
    }
    // `PlotlySchemaAdapter.ts:4059`.
    return value;
  }

  if (dtick is! String || !(isDateAx || isLogAx)) {
    // `PlotlySchemaAdapter.ts:4062-4064`.
    return dtickDflt;
  }

  final prefix = dtick[0];
  final suffix = dtick.substring(1);
  // `PlotlySchemaAdapter.ts:4067`.
  final dtickNum = isPlotlyNumber(suffix) ? double.parse(suffix) : 0.0;

  // `PlotlySchemaAdapter.ts:4069-4080`, negated: `M<n>` months on a date axis
  // with an integer n, `L<f>` on a log axis, and `D1` / `D2` on a log axis.
  final accepted =
      (isDateAx && prefix == 'M' && dtickNum == d3.jsRound(dtickNum)) ||
      (isLogAx && prefix == 'L') ||
      (isLogAx && prefix == 'D' && (dtickNum == 1 || dtickNum == 2));
  if (dtickNum <= 0 || !accepted) {
    // `PlotlySchemaAdapter.ts:4081-4083`.
    return dtickDflt;
  }
  // `PlotlySchemaAdapter.ts:4085`.
  return dtick;
}

/// Cleans a `tick0` (`PlotlySchemaAdapter.ts:4091-4101`, plotly.js
/// `clean_ticks.js#L70`).
///
/// The date fallback is [kDefaultDateString] (`'2000-01-01'`,
/// `utilities.ts:91`). Upstream's `new Date('2000-01-01')` is UTC midnight while
/// [DateTime.parse] is local midnight; local is the right value here because the
/// charts render with `useUTC` false (`PlotlySchemaAdapter.ts:2175`, with the
/// rationale at `:4212`) and every
/// downstream formatter therefore reads local fields.
/// // parity: PlotlySchemaAdapter.ts:4093
Object? plotlyTick0(Object? tick0, FluentPlotlyAxisType type, Object dtick) {
  if (type == FluentPlotlyAxisType.date) {
    // `PlotlySchemaAdapter.ts:4092-4093`.
    return isPlotlyDate(tick0)
        ? _jsNewDate(tick0)
        : DateTime.parse(kDefaultDateString);
  }
  if (dtick == 'D1' || dtick == 'D2') {
    // `PlotlySchemaAdapter.ts:4095-4097`: both modes ignore tick0 entirely.
    return null;
  }
  // `PlotlySchemaAdapter.ts:4100`: off a date axis, tick0 must be numeric.
  if (!isPlotlyNumber(tick0)) {
    return 0;
  }
  return tick0 is num ? tick0.toDouble() : double.parse('$tick0');
}

/// Maps declared `type: 'log'` axes onto Fluent scale types
/// (`PlotlySchemaAdapter.ts:3938-3954`).
///
/// The `x` member is an addition to this plan's Interfaces block, which listed
/// only `y` and `secondaryY`: upstream sets `xScaleType` at `:3943-3945` and
/// `FluentCartesianChartProps` has the field, so dropping it would lose a log x
/// axis outright. Note that the test is the *declared* layout type, not the
/// inferred one from [getAxisType].
({
  FluentAxisScaleType? x,
  FluentAxisScaleType? y,
  FluentAxisScaleType? secondaryY,
})
getAxisScaleTypeProps(List<Object?> data, Map<String, Object?>? layout) {
  FluentAxisScaleType? x;
  FluentAxisScaleType? y;
  FluentAxisScaleType? secondaryY;
  var seenY = false;
  for (final ax in getAxisObjects(data, layout)) {
    final isLog = ax.layoutAxis['type'] == 'log';
    if (ax.letter == 'x') {
      if (isLog) {
        x = FluentAxisScaleType.log;
      }
    } else if (!seenY) {
      seenY = true;
      if (isLog) {
        y = FluentAxisScaleType.log;
      }
    } else {
      if (isLog) {
        secondaryY = FluentAxisScaleType.log;
      }
    }
  }
  return (x: x, y: y, secondaryY: secondaryY);
}

/// Derives the category order for the x and y axes
/// (`PlotlySchemaAdapter.ts:3837-3881`, plotly.js
/// `category_order_defaults.js#L50`).
///
/// Reads `layout.xaxis` / `layout.yaxis` directly (`:3840-3843`), so a trace
/// anchored to `yaxis2` is silently ordered by the primary axis's settings.
/// // parity: PlotlySchemaAdapter.ts:3840
({FluentAxisCategoryOrder? x, FluentAxisCategoryOrder? y})
getAxisCategoryOrderProps(List<Object?> data, Map<String, Object?>? layout) {
  FluentAxisCategoryOrder? resolve(String letter) {
    final declared = layout?['${letter}axis'];
    final ax = declared is Map<String, Object?> ? declared : null;

    // `PlotlySchemaAdapter.ts:3849-3856`: every trace's column on this letter,
    // with no axis filtering at all.
    final values = <Object?>[];
    for (final series in data) {
      final column = series is Map<String, Object?> ? series[letter] : null;
      if (column is! List<Object?>) {
        continue;
      }
      for (final value in column) {
        if (!isInvalidValue(value)) {
          values.add(value);
        }
      }
    }

    // `PlotlySchemaAdapter.ts:3858-3859`.
    final isAxisTypeCategory =
        ax?['type'] == 'category' ||
        (isStringArray(values) &&
            !isNumberArray(values) &&
            !isDateArray(values));
    if (!isAxisTypeCategory) {
      // `PlotlySchemaAdapter.ts:3861`.
      return FluentAxisCategoryOrder.data;
    }

    final categoryArray = ax?['categoryarray'];
    final categoryOrder = ax?['categoryorder'];
    final reversed = ax?['autorange'] == 'reversed';
    final isValidArray =
        categoryArray is List<Object?> && categoryArray.isNotEmpty;

    if (isValidArray && (_isFalsy(categoryOrder) || categoryOrder == 'array')) {
      // `PlotlySchemaAdapter.ts:3865-3868`. `slice().reverse()` copies first, so
      // the layout's own array is not mutated.
      final categories = <String>[for (final entry in categoryArray) '$entry'];
      return FluentAxisCategoryOrder.explicit(
        reversed ? categories.reversed.toList() : categories,
      );
    }

    if (_isFalsy(categoryOrder) ||
        categoryOrder == 'trace' ||
        categoryOrder == 'array') {
      // `PlotlySchemaAdapter.ts:3871-3873`. `Array.from(new Set(...))` keeps
      // first-seen order, and so does a Dart `LinkedHashSet`.
      final categories = <String>{
        for (final value in values) '$value',
      }.toList();
      return FluentAxisCategoryOrder.explicit(
        reversed ? categories.reversed.toList() : categories,
      );
    }

    // `PlotlySchemaAdapter.ts:3877`: one of the twelve plotly.js preset names.
    return categoryOrder is String
        ? FluentAxisCategoryOrder.parse(categoryOrder)
        : null;
  }

  return (x: resolve('x'), y: resolve('y'));
}

/// The default polar subplot key (`PlotlySchemaAdapter.ts:4244`).
const String kDefaultPolarSubplot = 'polar';

/// One resolved polar axis (`PlotlySchemaAdapter.ts:4235-4238`).
class _PolarAxis {
  const _PolarAxis({
    required this.dataKey,
    required this.type,
    required this.axis,
  });

  final String dataKey;
  final FluentPlotlyAxisType type;
  final Map<String, Object?> axis;
}

/// `PlotlySchemaAdapter.ts:4246-4252`: the subplot the first trace names, or
/// [kDefaultPolarSubplot].
Map<String, Object?> _polarLayout(Object? trace, Map<String, Object?>? layout) {
  final declared = trace is Map<String, Object?> ? trace['subplot'] : null;
  final subplotId = declared is String && declared.isNotEmpty
      ? declared
      : kDefaultPolarSubplot;
  final polar = layout?[subplotId];
  return polar is Map<String, Object?> ? polar : const <String, Object?>{};
}

/// `PlotlySchemaAdapter.ts:4254-4266`.
List<Object?> _validPolarValues(List<Object?> data, String dataKey) {
  final values = <Object?>[];
  for (final series in data) {
    final column = series is Map<String, Object?> ? series[dataKey] : null;
    if (column is! List<Object?>) {
      continue;
    }
    for (final value in column) {
      if (!isInvalidValue(value)) {
        values.add(value);
      }
    }
  }
  return values;
}

/// `PlotlySchemaAdapter.ts:4268-4281` — the same inference ladder as
/// [getAxisType], on a polar data key instead of an axis letter.
FluentPlotlyAxisType _polarAxisType(
  List<Object?> data,
  String dataKey,
  Object? declaredType,
) {
  switch (declaredType) {
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
  final values = _validPolarValues(data, dataKey);
  if (isNumberArray(values) && !isYearArray(values)) {
    return FluentPlotlyAxisType.linear;
  }
  if (isDateArray(values)) {
    return FluentPlotlyAxisType.date;
  }
  return FluentPlotlyAxisType.category;
}

/// `PlotlySchemaAdapter.ts:4283-4291`. `r` reads `radialaxis`, `theta` reads
/// `angularaxis` (`:4240-4243`, lower-cased at `:4285`).
_PolarAxis _polarAxis(
  List<Object?> data,
  String dataKey,
  Map<String, Object?>? layout,
) {
  final polarLayout = _polarLayout(data.isEmpty ? null : data.first, layout);
  final key = dataKey == 'r' ? 'radialaxis' : 'angularaxis';
  final declared = polarLayout[key];
  final axis = declared is Map<String, Object?>
      ? declared
      : const <String, Object?>{};
  return _PolarAxis(
    dataKey: dataKey,
    type: _polarAxisType(data, dataKey, axis['type']),
    axis: axis,
  );
}

/// The type one polar data key resolves to (`PlotlySchemaAdapter.ts:4283-4291`,
/// returning only the `_type` field of `getPolarAxis`).
///
/// [getPolarAxisProps] needs the whole axis record; the polar transformer at
/// `PlotlySchemaAdapter.ts:3186` needs the type alone, to build its radial
/// value resolver — `getAxisValueResolver(getPolarAxis(data, 'r', layout)._type)`
/// — so this exposes that one field rather than the private record.
FluentPlotlyAxisType getPolarAxisType(
  List<Object?> data,
  String dataKey,
  Map<String, Object?>? layout,
) => _polarAxis(data, dataKey, layout).type;

/// `PlotlySchemaAdapter.ts:4293-4318` — the same three-branch ladder as
/// [getAxisTickProps], minus the category tick-layout arm.
({
  List<Object>? tickValues,
  List<String>? tickText,
  Object? tickStep,
  Object? tick0,
  int? tickCount,
})
_polarTickProps(_PolarAxis ax) {
  final tickmode = ax.axis['tickmode'];
  final tickvals = ax.axis['tickvals'];
  if ((_isFalsy(tickmode) || tickmode == 'array') &&
      tickvals is List<Object?>) {
    // `PlotlySchemaAdapter.ts:4296-4302`.
    final values = ax.type == FluentPlotlyAxisType.date
        ? <Object>[for (final value in tickvals) ?_jsNewDate(value)]
        : <Object>[for (final value in tickvals) ?value];
    final ticktext = ax.axis['ticktext'];
    return (
      tickValues: values,
      tickText: ticktext is List<Object?>
          ? <String>[for (final entry in ticktext) '$entry']
          : null,
      tickStep: null,
      tick0: null,
      tickCount: null,
    );
  }

  final declaredDtick = ax.axis['dtick'];
  if ((_isFalsy(tickmode) || tickmode == 'linear') &&
      !_isFalsy(declaredDtick)) {
    // `PlotlySchemaAdapter.ts:4304-4311`.
    final dtick = plotlyDtick(declaredDtick, ax.type)!;
    return (
      tickValues: null,
      tickText: null,
      tickStep: dtick,
      tick0: plotlyTick0(ax.axis['tick0'], ax.type, dtick),
      tickCount: null,
    );
  }

  final nticks = ax.axis['nticks'];
  if ((_isFalsy(tickmode) || tickmode == 'auto') &&
      nticks is num &&
      nticks >= 0) {
    // `PlotlySchemaAdapter.ts:4313-4315`.
    return (
      tickValues: null,
      tickText: null,
      tickStep: null,
      tick0: null,
      tickCount: nticks.toInt(),
    );
  }

  return (
    tickValues: null,
    tickText: null,
    tickStep: null,
    tick0: null,
    tickCount: null,
  );
}

/// `PlotlySchemaAdapter.ts:4320-4337`.
///
/// The array branch at `:4327` returns `categoryarray` **unreversed** even when
/// `autorange` is `reversed`, unlike the cartesian twin at `:3867`. Reproduced.
/// // parity: PlotlySchemaAdapter.ts:4327
FluentAxisCategoryOrder _polarCategoryOrder(List<Object?> data, _PolarAxis ax) {
  if (ax.type != FluentPlotlyAxisType.category) {
    // `PlotlySchemaAdapter.ts:4321-4323`.
    return FluentAxisCategoryOrder.data;
  }
  final categoryArray = ax.axis['categoryarray'];
  final categoryOrder = ax.axis['categoryorder'];
  final isValidArray =
      categoryArray is List<Object?> && categoryArray.isNotEmpty;
  if (isValidArray && (_isFalsy(categoryOrder) || categoryOrder == 'array')) {
    return FluentAxisCategoryOrder.explicit(<String>[
      for (final entry in categoryArray) '$entry',
    ]);
  }
  if (_isFalsy(categoryOrder) ||
      categoryOrder == 'trace' ||
      categoryOrder == 'array') {
    final categories = <String>{
      for (final value in _validPolarValues(data, ax.dataKey)) '$value',
    }.toList();
    return FluentAxisCategoryOrder.explicit(
      ax.axis['autorange'] == 'reversed'
          ? categories.reversed.toList()
          : categories,
    );
  }
  return categoryOrder is String
      ? FluentAxisCategoryOrder.parse(categoryOrder) ??
            FluentAxisCategoryOrder.data
      : FluentAxisCategoryOrder.data;
}

/// The radial and angular axis configuration a polar layout implies
/// (`PlotlySchemaAdapter.ts:4339-4361`).
@immutable
class FluentPlotlyPolarAxisProps {
  /// Creates a polar axis record.
  const FluentPlotlyPolarAxisProps({
    required this.radialAxis,
    required this.angularAxis,
    this.angularUnit,
    this.direction,
  });

  /// `props.radialAxis` (`PlotlySchemaAdapter.ts:4346`, key from `:4241`).
  final FluentPolarAxisConfig radialAxis;

  /// `props.angularAxis` (`PlotlySchemaAdapter.ts:4346`, key from `:4242`).
  final FluentPolarAxisConfig angularAxis;

  /// `thetaunit`, `'radians'` or `'degrees'` (`PlotlySchemaAdapter.ts:4355`).
  ///
  /// Lives here rather than on [angularAxis] because upstream assigns it after
  /// the object literal and `FluentPolarAxisConfig` has no such field.
  final String? angularUnit;

  /// `angularaxis.direction`, `'clockwise'` or `'counterclockwise'`
  /// (`PlotlySchemaAdapter.ts:4356`).
  final String? direction;
}

/// Builds both polar axes (`PlotlySchemaAdapter.ts:4339-4361`).
FluentPlotlyPolarAxisProps getPolarAxisProps(
  List<Object?> data,
  Map<String, Object?>? layout,
) {
  FluentPolarAxisConfig configFor(_PolarAxis ax) {
    final ticks = _polarTickProps(ax);
    final range = ax.axis['range'];
    // `PlotlySchemaAdapter.ts:4351`: a range is spread only when it is an array.
    final hasRange = range is List<Object?> && range.length >= 2;
    final tickFormat = ax.axis['tickformat'];
    // A Plotly polar range is always numeric, so both endpoints coerce to
    // double rather than staying `Datum`. A `is num` test rather than a cast:
    // the range comes from author-supplied JSON, and `as num?` would turn a
    // string endpoint into an uncaught throw on the render path.
    final start = hasRange ? range[0] : null;
    final end = hasRange ? range[1] : null;
    return FluentPolarAxisConfig(
      // `PlotlySchemaAdapter.ts:4347`: `'default'` is `FluentAxisScaleType.auto`.
      scaleType: ax.type == FluentPlotlyAxisType.log
          ? FluentAxisScaleType.log
          : FluentAxisScaleType.auto,
      categoryOrder: _polarCategoryOrder(data, ax),
      tickFormat: tickFormat is String ? tickFormat : null,
      tickValues: ticks.tickValues,
      tickText: ticks.tickText,
      tickStep: ticks.tickStep,
      tick0: ticks.tick0,
      tickCount: ticks.tickCount,
      rangeStart: start is num ? start.toDouble() : null,
      rangeEnd: end is num ? end.toDouble() : null,
    );
  }

  final radial = _polarAxis(data, 'r', layout);
  final angular = _polarAxis(data, 'theta', layout);
  final thetaunit = angular.axis['thetaunit'];
  final direction = angular.axis['direction'];
  return FluentPlotlyPolarAxisProps(
    radialAxis: configFor(radial),
    angularAxis: configFor(angular),
    // `PlotlySchemaAdapter.ts:4354-4357`: both only for the angular axis.
    angularUnit: thetaunit is String ? thetaunit : null,
    direction: direction is String ? direction : null,
  );
}

/// The two numeric endpoints of `layout[axisKey].range`, or null when the layout
/// pins no usable range (`PlotlySchemaAdapter.ts:223-224` and `:234-235`).
(double, double)? _axisRange(Map<String, Object?>? layout, String axisKey) {
  final axis = layout?[axisKey];
  if (axis is! Map<String, Object?>) {
    return null;
  }
  final range = axis['range'];
  // `:224` and `:235`: exactly two entries. A one- or three-entry range is
  // ignored outright rather than padded or truncated.
  if (range is! List<Object?> || range.length != 2) {
    return null;
  }
  final start = range[0];
  final end = range[1];
  return start is num && end is num ? (start.toDouble(), end.toDouble()) : null;
}

/// The explicit x domain a Plotly layout pins through `layout.xaxis.range`
/// (`PlotlySchemaAdapter.ts:233-243`).
///
/// Upstream also takes the first trace, which `getXAxisProperties` (`:249-251`)
/// then ignores — it returns `layout.xaxis` and reads nothing off the series — so
/// this port takes the layout alone.
///
/// `showRoundOffXTickValues` is false whenever a range is present (`:239`),
/// because `nice()` would widen a domain the author chose (`utilities.ts:283`).
/// With no range upstream spreads an empty object (`:242`), leaving the shell's
/// own default of true in place, so that is what this returns.
///
/// Only numeric endpoints survive. `FluentCartesianChartProps.xMinValue` is a
/// `double?` (contract §7.1) and the value is read only by the numeric x scale
/// (`utilities.ts:278-279`, where it *widens* the data domain via `Math.min` /
/// `Math.max` rather than clipping it), so a date or category endpoint has
/// nowhere to land upstream either: it reaches a `number` prop as a string and
/// the numeric branch drops it.
///
/// ponytail: numeric endpoints only — the same observable result as upstream, one
/// coercion instead of a union type.
({double? xMinValue, double? xMaxValue, bool showRoundOffXTickValues})
getXMinMaxValues(Map<String, Object?>? layout) {
  final range = _axisRange(layout, 'xaxis');
  return range == null
      ? (xMinValue: null, xMaxValue: null, showRoundOffXTickValues: true)
      : (
          xMinValue: range.$1,
          xMaxValue: range.$2,
          showRoundOffXTickValues: false,
        );
}

/// The explicit y domain a Plotly layout pins through `layout.yaxis.range`
/// (`PlotlySchemaAdapter.ts:222-231`).
///
/// Null on both fields is upstream's empty spread at `:230`, which means "inject
/// nothing": a caller that seeded its own bounds keeps them. The same
/// numeric-only rule as [getXMinMaxValues] applies.
({double? yMinValue, double? yMaxValue}) getYMinMaxValues(
  Map<String, Object?>? layout,
) {
  final range = _axisRange(layout, 'yaxis');
  return range == null
      ? (yMinValue: null, yMaxValue: null)
      : (yMinValue: range.$1, yMaxValue: range.$2);
}
