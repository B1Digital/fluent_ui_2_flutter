import 'package:flutter/foundation.dart';

import '../../chrome/legend.dart';
import '../../model/chart_common.dart';
import '../../model/line_options.dart';
import '../d3/array_stats.dart' as d3;
import '../d3/format.dart' as d3;
import '../plotly/common.dart' show parseCssColour;
import 'color_adapter.dart';
import 'js_value.dart';
import 'routing.dart';
import 'spec.dart';

/// The three titles a Vega-Lite spec supplies
/// (`VegaLiteSchemaAdapter.ts:2047-2129`).
@immutable
class FluentVegaTitles {
  /// Creates a title record.
  const FluentVegaTitles({this.chartTitle, this.xAxisTitle, this.yAxisTitle});

  /// `spec.title`, or `spec.title.text` for the object form (`:2063`).
  final String? chartTitle;

  /// `encoding.x.title`, falling back to `encoding.x.axis.title` (`:2125`).
  final String? xAxisTitle;

  /// `encoding.y.title`, falling back to `encoding.y.axis.title` (`:2126`).
  final String? yAxisTitle;
}

/// Reads the titles out of a spec (`VegaLiteSchemaAdapter.ts:2047-2129`).
///
/// **GAP:** `:2066-2120` also builds a `titleStyles` record — font family, size,
/// weight (with the four named weights mapped to 400/700/300/600 at
/// `:2082-2088`), colour, an anchor map of start/middle/end to left/centre/right,
/// and a `titlePad` from `offset` and `subtitlePadding`. This task's Produces line
/// declares only the three strings, so all of that is currently dropped. The
/// Plotly side keeps its equivalent as `FluentPlotlyTitles.titleStyle`, so the
/// asymmetry is an omission rather than a decision: add a `titleStyle` field
/// here, or a Vega title with a declared font renders in the theme default.
///
/// Neither axis title falls back to the field name: `:2125-2126` are
/// `encoding.x?.title ?? encoding.x?.axis?.title ?? undefined`, so a channel
/// carrying only a `field` has no axis title at all and the chart labels its
/// axis with whatever its own default is.
/// // parity: VegaLiteSchemaAdapter.ts:2125
FluentVegaTitles getVegaLiteTitles(Map<String, Object?> spec) {
  // `:2053`, then `:2059`: the titles come off the FIRST unit spec's encoding,
  // which for a layered spec is the shared encoding with layer zero's merged
  // over it.
  final unitSpecs = normalizeVegaSpec(spec);
  if (unitSpecs.isEmpty) {
    // `:2055-2056`, which drops the chart title along with the axis ones.
    return const FluentVegaTitles();
  }
  final encodingRaw = unitSpecs.first['encoding'];
  final encoding = encodingRaw is Map<String, Object?>
      ? encodingRaw
      : const <String, Object?>{};

  final title = spec['title'];
  final String? chartTitle;
  if (title is String) {
    chartTitle = title;
  } else if (title is Map<String, Object?> && title['text'] is String) {
    chartTitle = title['text']! as String;
  } else {
    chartTitle = null;
  }

  String? axisTitle(String channel) {
    final definition = encoding[channel];
    if (definition is! Map<String, Object?>) {
      return null;
    }
    // `:2125`: `??`, so an empty-string title survives and only null falls
    // through to the axis's own.
    final direct = definition['title'];
    if (direct is String) {
      return direct;
    }
    final axis = definition['axis'];
    final axisTitleValue = axis is Map<String, Object?> ? axis['title'] : null;
    return axisTitleValue is String ? axisTitleValue : null;
  }

  return FluentVegaTitles(
    chartTitle: chartTitle,
    xAxisTitle: axisTitle('x'),
    yAxisTitle: axisTitle('y'),
  );
}

/// Coerces one datum for an axis (`VegaLiteSchemaAdapter.ts:606-624`).
///
/// Returns the EMPTY STRING for null and undefined (`:607-608`), not null — so a
/// hole in the data becomes a category named `''` rather than being skipped.
/// A numeric STRING stays a string: `:619` tests `typeof value === 'number'`, so
/// only a real number survives as one.
/// // parity: VegaLiteSchemaAdapter.ts:608
Object parseVegaValue(Object? value, {required bool isTemporal}) {
  if (value == null || value is JsUndefined) {
    return '';
  }
  if (isTemporal) {
    // `:613-615`: `new Date(value)`. A number is epoch milliseconds; an
    // unparseable string falls through to the two arms below.
    if (value is DateTime) {
      return value;
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  // `:619-620`.
  if (value is num) {
    return value;
  }
  // `:623`.
  return jsToString(value);
}

/// Maps a Vega-Lite `interpolate` onto a Fluent curve
/// (`VegaLiteSchemaAdapter.ts:630-655`).
///
/// Two lossy mappings, both upstream's: `monotone` becomes `linear` (`:649-650`)
/// and `basis`, `cardinal` and `catmull-rom` fall through the `default` arm to
/// `linear` (`:652-653`). Only an ABSENT interpolate returns null; an unknown
/// name still becomes linear. // parity: VegaLiteSchemaAdapter.ts:650
FluentLineCurve? mapInterpolateToCurve(String? interpolate) {
  if (interpolate == null || interpolate.isEmpty) {
    // `:633-634`.
    return null;
  }
  switch (interpolate) {
    case 'linear':
    case 'linear-closed':
      return FluentLineCurve.linear;
    case 'step':
      return FluentLineCurve.step;
    case 'step-before':
      return FluentLineCurve.stepBefore;
    case 'step-after':
      return FluentLineCurve.stepAfter;
    case 'natural':
      return FluentLineCurve.natural;
    default:
      return FluentLineCurve.linear;
  }
}

/// The five mark properties a `{type: …}` mark can carry
/// (`VegaLiteSchemaAdapter.ts:660-677`).
@immutable
class FluentVegaMarkProperties {
  /// Creates a mark-properties record. Every field null means "not declared".
  const FluentVegaMarkProperties({
    this.color,
    this.interpolate,
    this.strokeWidth,
    this.strokeDash,
    this.point,
  });

  /// `mark.color`, a CSS colour string (`:671`).
  final String? color;

  /// `mark.interpolate`, fed to [mapInterpolateToCurve] (`:672`).
  final String? interpolate;

  /// `mark.strokeWidth` (`:673`).
  final double? strokeWidth;

  /// `mark.strokeDash`, a dash-array in logical pixels (`:674`).
  final List<double>? strokeDash;

  /// `mark.point` — `true`, `false`, or `{filled, size}` (`:675`). Kept as the
  /// raw JSON value because all three forms are meaningful downstream.
  final Object? point;
}

/// Reads mark properties (`VegaLiteSchemaAdapter.ts:660-677`).
///
/// A bare string mark carries none (`:667-668`).
FluentVegaMarkProperties getMarkProperties(Object? mark) {
  if (mark is! Map<String, Object?>) {
    return const FluentVegaMarkProperties();
  }
  final color = mark['color'];
  final interpolate = mark['interpolate'];
  final strokeWidth = mark['strokeWidth'];
  final strokeDash = mark['strokeDash'];
  return FluentVegaMarkProperties(
    color: color is String ? color : null,
    interpolate: interpolate is String ? interpolate : null,
    strokeWidth: strokeWidth is num ? strokeWidth.toDouble() : null,
    strokeDash: strokeDash is List<Object?>
        ? <double>[
            for (final entry in strokeDash)
              if (entry is num) entry.toDouble(),
          ]
        : null,
    point: mark['point'],
  );
}

/// The tick settings an encoding's `axis` blocks declare
/// (`VegaLiteSchemaAdapter.ts:852-881`).
@immutable
class FluentVegaTickConfig {
  /// Creates a tick-config record.
  const FluentVegaTickConfig({
    this.tickValues,
    this.xAxisTickCount,
    this.yAxisTickCount,
  });

  /// `encoding.x.axis.values` (`:867`). Only the x channel is read.
  final List<Object>? tickValues;

  /// `encoding.x.axis.tickCount` (`:870`).
  final int? xAxisTickCount;

  /// `encoding.y.axis.tickCount` (`:876`).
  final int? yAxisTickCount;
}

/// Reads the tick configuration (`VegaLiteSchemaAdapter.ts:852-881`).
///
/// Reads `spec.encoding` directly (`:863`), NOT the normalised or merged
/// encoding, so a layered spec's tick settings are ignored entirely.
/// // parity: VegaLiteSchemaAdapter.ts:863
///
/// A `tickCount` of 0 is falsy in JavaScript (`:869`, `:875`) and is therefore
/// treated as absent rather than as "no ticks".
FluentVegaTickConfig extractTickConfig(Map<String, Object?> spec) {
  final encodingRaw = spec['encoding'];
  final encoding = encodingRaw is Map<String, Object?>
      ? encodingRaw
      : const <String, Object?>{};

  List<Object>? tickValues;
  int? xAxisTickCount;
  int? yAxisTickCount;

  final x = encoding['x'];
  final xAxis = x is Map<String, Object?> ? x['axis'] : null;
  if (xAxis is Map<String, Object?>) {
    final values = xAxis['values'];
    if (values is List<Object?>) {
      // `:867` assigns the array as it stands; a null entry has no axis value
      // to be, so it is dropped rather than carried as a hole.
      tickValues = <Object>[for (final value in values) ?value];
    }
    final tickCount = xAxis['tickCount'];
    if (tickCount is num && jsTruthy(tickCount)) {
      xAxisTickCount = tickCount.toInt();
    }
  }

  final y = encoding['y'];
  final yAxis = y is Map<String, Object?> ? y['axis'] : null;
  if (yAxis is Map<String, Object?>) {
    final tickCount = yAxis['tickCount'];
    if (tickCount is num && jsTruthy(tickCount)) {
      yAxisTickCount = tickCount.toInt();
    }
  }

  return FluentVegaTickConfig(
    tickValues: tickValues,
    xAxisTickCount: xAxisTickCount,
    yAxisTickCount: yAxisTickCount,
  );
}

/// The y scale type (`VegaLiteSchemaAdapter.ts:1031-1034`).
///
/// Only `log` is recognised; every other declared scale type, `pow` and `sqrt`
/// included, resolves to null and renders linear.
/// // parity: VegaLiteSchemaAdapter.ts:1033
FluentAxisScaleType? extractYAxisType(Map<String, Object?> encoding) {
  final y = encoding['y'];
  final scale = y is Map<String, Object?> ? y['scale'] : null;
  final type = scale is Map<String, Object?> ? scale['type'] : null;
  return type == 'log' ? FluentAxisScaleType.log : null;
}

/// The y bounds an encoding implies (`VegaLiteSchemaAdapter.ts:1040-1070`).
///
/// An explicit `scale.domain` wins (`:1048-1052`). Otherwise `scale.zero: false`
/// computes a padded minimum from the data — and returns **no maximum at all**
/// (`:1064`), so the chart still auto-scales its top.
/// // parity: VegaLiteSchemaAdapter.ts:1064
({double? min, double? max}) extractYMinMax(
  Map<String, Object?> encoding,
  List<Map<String, Object?>> data,
) {
  final y = encoding['y'];
  final scale = y is Map<String, Object?> ? y['scale'] : null;
  final domain = scale is Map<String, Object?> ? scale['domain'] : null;

  if (domain is List<Object?>) {
    // `:1050-1051`: an unchecked cast upstream, so a two-string domain becomes
    // NaN rather than being rejected. Here a non-numeric bound is simply
    // absent, which is the same "let the chart decide" outcome without the NaN.
    return (
      min: domain.isNotEmpty && domain[0] is num
          ? (domain[0]! as num).toDouble()
          : null,
      max: domain.length > 1 && domain[1] is num
          ? (domain[1]! as num).toDouble()
          : null,
    );
  }

  if (scale is Map<String, Object?> && scale['zero'] == false) {
    final field = y is Map<String, Object?> ? y['field'] : null;
    if (field is String && jsTruthy(field)) {
      // `:1059`: `Number(row[field])` for every row, then drop the NaNs.
      final values = data
          .map((row) => jsToNumber(row[field]))
          .where((value) => !value.isNaN)
          .toList();
      if (values.isNotEmpty) {
        final dataMin = d3.min<double>(values) ?? 0;
        final dataMax = d3.max<double>(values) ?? 0;
        // `:1063`: five per cent of the data span, so the lowest mark is not
        // flush against the axis.
        final padding = (dataMax - dataMin) * 0.05;
        return (min: dataMin - padding, max: null);
      }
    }
  }

  // `:1069`.
  return (min: null, max: null);
}

/// Builds a number formatter from a d3-format specifier
/// (`VegaLiteSchemaAdapter.ts:1076-1086`).
///
/// An invalid specifier yields null rather than throwing (`:1083-1085`);
/// `d3.format` throws `FormatException` for one.
String Function(double)? createValueFormatter(String? formatSpec) {
  if (formatSpec == null || formatSpec.isEmpty) {
    return null;
  }
  try {
    return d3.format(formatSpec).call;
  } on FormatException {
    return null;
  }
}

/// Converts a Vega-Lite `sort` to a Fluent category order
/// (`VegaLiteSchemaAdapter.ts:1094-1123`).
///
/// Four accepted forms: the two direction strings, an explicit array, and an
/// `{op, order}` object whose `average` is renamed to `mean` (`:1117`). Anything
/// else — including `sort: null`, which Vega-Lite uses to mean "leave the data
/// order alone" — returns null. // parity: VegaLiteSchemaAdapter.ts:1095
///
/// One narrowing: `:1119` casts `'${op} ${order}'` to the ordering union without
/// checking it, so an op the union does not spell reaches the chart as a string
/// no sorter matches. Here it resolves through
/// [FluentAxisCategoryOrder.parse] and an unspellable op is null, which is the
/// same "no ordering" the chart would have applied.
FluentAxisCategoryOrder? convertVegaSortToAxisCategoryOrder(Object? sort) {
  // `:1095`: `!sort`, so `null`, `false`, `0` and `''` all mean "no sort".
  if (!jsTruthy(sort)) {
    return null;
  }

  if (sort is String) {
    if (sort == 'ascending') {
      return FluentAxisCategoryOrder.categoryAscending;
    }
    if (sort == 'descending') {
      return FluentAxisCategoryOrder.categoryDescending;
    }
    // `:1107`: a field name such as `'-y'` is not supported.
    return null;
  }

  if (sort is List<Object?>) {
    // `:1112`: the array IS the order.
    return FluentAxisCategoryOrder.explicit(<String>[
      for (final entry in sort) jsToString(entry),
    ]);
  }

  if (sort is Map<String, Object?>) {
    final op = sort['op'];
    final order = sort['order'];
    // `:1116`: BOTH must be present and truthy.
    if (jsTruthy(op) && jsTruthy(order)) {
      final resolvedOp = op == 'average' ? 'mean' : jsToString(op);
      final resolvedOrder = order == 'ascending' ? 'ascending' : 'descending';
      // `:1119` builds the name at runtime, which is why
      // [FluentAxisCategoryOrder.parse] exists.
      return FluentAxisCategoryOrder.parse('$resolvedOp $resolvedOrder');
    }
  }

  return null;
}

/// The x and y category orders an encoding declares
/// (`VegaLiteSchemaAdapter.ts:1129-1153`).
({FluentAxisCategoryOrder? x, FluentAxisCategoryOrder? y})
extractAxisCategoryOrderProps(Map<String, Object?> encoding) {
  FluentAxisCategoryOrder? orderFor(String channel) {
    final definition = encoding[channel];
    final sort = definition is Map<String, Object?> ? definition['sort'] : null;
    // `:1138` and `:1145` both gate on truthiness first, so `sort: null` and
    // `sort: 0` never reach the converter.
    return jsTruthy(sort) ? convertVegaSortToAxisCategoryOrder(sort) : null;
  }

  return (x: orderFor('x'), y: orderFor('y'));
}

/// Rejects a dataset that cannot render (`VegaLiteSchemaAdapter.ts:890-899`).
///
/// Both messages are verbatim; they surface through the widget's error builder
/// and are the only diagnostics a spec author sees.
void validateVegaDataArray(
  List<Map<String, Object?>> data,
  String field,
  String chartType,
) {
  if (data.isEmpty) {
    // `:892`.
    throw VegaSpecException(
      'VegaLiteSchemaAdapter: Empty data array for $chartType',
    );
  }
  // `:895`: a single non-null row is enough.
  final hasValidValues = data.any((row) {
    final value = row[field];
    return value != null && value is! JsUndefined;
  });
  if (!hasValidValues) {
    // `:897`.
    throw VegaSpecException(
      "VegaLiteSchemaAdapter: No valid values found for field '$field' "
      'in $chartType',
    );
  }
}

/// Rejects a nested array in a data column (`VegaLiteSchemaAdapter.ts:907-914`).
///
/// Message verbatim, including the sentence break and the trailing full stop:
/// upstream concatenates two string literals at `:911`, which produces
/// `"… for field 'f'. Use flat data structures only."`.
void validateVegaNoNestedArrays(List<Map<String, Object?>> data, String field) {
  final hasNestedArrays = data.any((row) => row[field] is List<Object?>);
  if (hasNestedArrays) {
    throw VegaSpecException(
      "VegaLiteSchemaAdapter: Nested arrays not supported for field '$field'. "
      'Use flat data structures only.',
    );
  }
}

/// Validates one channel's declared type against its data, auto-correcting a
/// string column declared quantitative (`VegaLiteSchemaAdapter.ts:934-992`).
///
/// Returns the corrected type, or null when nothing changed. **Mutates
/// [encoding]** at `:962-963`, so pass the cloned spec's encoding.
///
/// Note the asymmetry the two throws create: a string column declared
/// quantitative is silently corrected to nominal (`:957-966`, matching Plotly's
/// behaviour), while any other non-numeric type is fatal (`:970-972`).
///
/// `:976` is `Date.parse`, which V8 answers for `'Jan 1 2024'` and
/// `DateTime.tryParse` does not, so a handful of loose date strings that V8
/// routes as temporal are rejected here with the `:986` message. Recorded rather
/// than papered over: a lenient parser for a format Vega-Lite's own docs do not
/// endorse is a new surface for no fixture. // ponytail
String? validateVegaEncodingType(
  List<Map<String, Object?>> data,
  String field,
  String? expectedType, {
  Map<String, Object?>? encoding,
  String? channelName,
}) {
  if (expectedType == null ||
      expectedType == 'nominal' ||
      expectedType == 'ordinal' ||
      expectedType == 'geojson') {
    // `:941-942`.
    return null;
  }

  // `:946`.
  Object? sampleValue;
  for (final row in data) {
    final value = row[field];
    if (value != null && value is! JsUndefined) {
      sampleValue = value;
      break;
    }
  }
  // `:948-949`: `!sampleValue`, so a sample of `0`, `''` or `false` also skips
  // validation. // parity: VegaLiteSchemaAdapter.ts:948
  if (!jsTruthy(sampleValue)) {
    return null;
  }

  if (expectedType == 'quantitative') {
    if (sampleValue is! num && !jsToNumber(sampleValue).isFinite) {
      final actualType = jsTypeof(sampleValue);
      if (actualType == 'string') {
        // `:962-966`.
        final channel = channelName == null ? null : encoding?[channelName];
        if (channel is Map<String, Object?>) {
          channel['type'] = 'nominal';
        }
        return 'nominal';
      }
      // `:970-972`.
      throw VegaSpecException(
        "VegaLiteSchemaAdapter: Field '$field' marked as quantitative but "
        'contains non-numeric values ($actualType).',
      );
    }
  } else if (expectedType == 'temporal') {
    final isValidDate =
        sampleValue is DateTime ||
        (sampleValue is String && DateTime.tryParse(sampleValue) != null);
    if (!isValidDate) {
      // `:978-983`, both suggestions verbatim including the leading space.
      var suggestion = '';
      if (sampleValue is num) {
        suggestion =
            ' The data contains numbers. Change the type to "quantitative" '
            'instead.';
      } else if (sampleValue is String) {
        suggestion =
            ' The data contains strings that are not valid dates '
            '(e.g., "$sampleValue"). Ensure dates are in ISO format '
            '(YYYY-MM-DD) or valid date strings.';
      }
      // `:985-987`.
      throw VegaSpecException(
        "VegaLiteSchemaAdapter: Field '$field' marked as temporal but contains "
        'invalid date values.$suggestion',
      );
    }
  }

  return null;
}

/// The four-step validation every two-axis chart runs
/// (`VegaLiteSchemaAdapter.ts:1008-1025`).
void validateVegaXYEncodings(
  List<Map<String, Object?>> data,
  String xField,
  String yField,
  String? xType,
  String? yType,
  String chartType, {
  Map<String, Object?>? encoding,
}) {
  validateVegaDataArray(data, xField, chartType);
  validateVegaDataArray(data, yField, chartType);
  validateVegaNoNestedArrays(data, xField);
  validateVegaNoNestedArrays(data, yField);
  validateVegaEncodingType(
    data,
    xField,
    xType,
    encoding: encoding,
    channelName: 'x',
  );
  validateVegaEncodingType(
    data,
    yField,
    yType,
    encoding: encoding,
    channelName: 'y',
  );
}

/// The shared legend a concat spec renders below its grid
/// (`VegaLiteSchemaAdapter.ts:1988-2042`).
///
/// Deliberately not a `FluentChartLegend`: the widget is built by task 53, which
/// merges these with its own selection callbacks. Splitting the data from the
/// widget is what lets the same props be asserted in a unit test without pumping
/// anything. The shape mirrors `FluentPlotlyLegendProps`
/// (`internal/plotly/legends.dart:44-66`) field for field, which is why it
/// carries no `operator ==` either — see the note on [legends].
@immutable
class FluentVegaLegendProps {
  /// Creates a set of shared-legend properties.
  const FluentVegaLegendProps({
    required this.legends,
    required this.centerLegends,
    required this.enabledWrapLines,
    required this.canSelectMultipleLegends,
  });

  /// One entry per distinct colour value, in first-seen row order (`:2028-2034`).
  ///
  /// `FluentChartLegendItem` declares no `operator ==`, so any value equality
  /// written over this list would compare its elements by identity and read as
  /// a value comparison while behaving as an identity one. None is written.
  final List<FluentChartLegendItem> legends;

  /// Always true (`:2038`, and again at `:1999` and `:2013` on the two early
  /// returns).
  final bool centerLegends;

  /// Always true (`:2039`).
  final bool enabledWrapLines;

  /// Always true (`:2040`).
  final bool canSelectMultipleLegends;
}

/// The empty result both early returns share (`:1996-2003`, `:2010-2017`).
const FluentVegaLegendProps _emptyVegaLegendProps = FluentVegaLegendProps(
  legends: <FluentChartLegendItem>[],
  centerLegends: true,
  enabledWrapLines: true,
  canSelectMultipleLegends: true,
);

/// Builds the shared legend for a multi-plot Vega spec
/// (`VegaLiteSchemaAdapter.ts:1988-2042`).
///
/// Read from **sub-spec zero only** (`:2005`), so a concat whose second cell
/// introduces further colour values shows an incomplete legend. That is
/// upstream's behaviour and is reproduced.
/// // parity: VegaLiteSchemaAdapter.ts:2005
FluentVegaLegendProps getVegaLiteLegendsProps(
  Map<String, Object?> spec,
  Map<String, String> colorMap, {
  required bool isDark,
}) {
  // `:1993`.
  final unitSpecs = normalizeVegaSpec(spec);
  // `:1996-2003`: an unroutable spec still returns the three flags, so the
  // caller never has to null-check them.
  if (unitSpecs.isEmpty) {
    return _emptyVegaLegendProps;
  }

  // `:2005-2008`. Note that NO transforms run here — a `fold` that materialises
  // the colour column would be invisible to the shared legend.
  // parity: VegaLiteSchemaAdapter.ts:2006
  final primarySpec = unitSpecs.first;
  final dataValues = extractVegaDataValues(primarySpec['data']);
  final encodingRaw = primarySpec['encoding'];
  final encoding = encodingRaw is Map<String, Object?>
      ? encodingRaw
      : const <String, Object?>{};
  final color = encoding['color'];
  final colorField = color is Map<String, Object?> && color['field'] is String
      ? color['field']! as String
      : null;

  // `:2010-2017`.
  if (colorField == null) {
    return _emptyVegaLegendProps;
  }

  // `:2020-2025`: a `Set`, so the order is first-seen insertion order and
  // duplicates collapse. `:2022` is `!== undefined`, which an absent key is and
  // an explicit null is not, so a null cell becomes a legend titled `'null'`.
  final seriesNames = <String>{};
  for (final row in dataValues) {
    if (!row.containsKey(colorField) || row[colorField] is JsUndefined) {
      continue;
    }
    seriesNames.add(jsToString(row[colorField]));
  }

  // `:2028-2034`.
  final legends = <FluentChartLegendItem>[
    for (final seriesName in seriesNames)
      FluentChartLegendItem(
        title: seriesName,
        // `:2029`: `getVegaColorFromMap(name, colorMap, undefined, undefined,
        // isDarkTheme)` — NEITHER the scheme nor the range is forwarded, so
        // `getVegaColor` falls all the way through to the plain qualitative
        // cycle at `VegaLiteColorAdapter.ts:254`. A spec whose colour scale
        // names `tableau10` therefore gets hotPink for its second series here
        // while its sub-charts draw it pumpkin. The colour map hides this
        // whenever a sub-chart has already been transformed and seeded it,
        // which is why it survived upstream.
        // parity: VegaLiteSchemaAdapter.ts:2029
        color: parseCssColour(
          getVegaColorFromMap(seriesName, colorMap, null, null, isDark: isDark),
        ),
      ),
  ];

  // `:2036-2041`.
  return FluentVegaLegendProps(
    legends: legends,
    centerLegends: true,
    enabledWrapLines: true,
    canSelectMultipleLegends: true,
  );
}
