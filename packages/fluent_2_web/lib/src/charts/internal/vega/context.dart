import 'package:flutter/foundation.dart';

import '../../line_chart.dart';
import '../../model/chart_annotation.dart';
import '../d3/array_stats.dart' as d3;
import '../plotly/common.dart' show parseCssColour;
import '../plotly/predicates.dart' show isInvalidValue;
import 'color_adapter.dart' show getVegaColor, getVegaColorFromMap;
import 'common.dart'
    show FluentVegaMarkProperties, getMarkProperties, parseVegaValue;
import 'expression.dart' show VegaExpressionException, evaluateVegaExpression;
import 'js_value.dart' show jsToNumber, jsToString, jsTruthy;
import 'routing.dart' show normalizeVegaSpec;
import 'spec.dart' show VegaSpecException, extractVegaDataValues, getMarkType;
import 'transforms.dart' show applyVegaTransforms;

/// Everything a Vega transformer needs about a spec, computed once
/// (`VegaLiteSchemaAdapter.ts:1162-1268`, `:1276-1288`, `:1396-1401`).
@immutable
class FluentVegaTransformContext {
  /// Creates a transform context.
  const FluentVegaTransformContext({
    required this.unitSpecs,
    required this.primarySpec,
    required this.data,
    required this.encoding,
    required this.markProps,
    this.xField,
    this.yField,
    this.x2Field,
    this.colorField,
    this.sizeField,
    this.thetaField,
    this.radiusField,
    this.xAggregate,
    this.yAggregate,
    this.colorScheme,
    this.colorRange,
  });

  /// The flattened layers (`:1163`).
  final List<Map<String, Object?>> unitSpecs;

  /// `unitSpecs[0]` (`:1169`).
  final Map<String, Object?> primarySpec;

  /// The rows after both transform passes, the conditional-colour
  /// materialisation and any `timeUnit` aggregation (`:1264`).
  final List<Map<String, Object?>> data;

  /// The primary layer's encoding, possibly rewritten in place (`:1265`).
  final Map<String, Object?> encoding;

  /// The primary layer's mark properties (`:1259`).
  final FluentVegaMarkProperties markProps;

  /// `encoding.x.field` (`:1278`).
  final String? xField;

  /// `encoding.y.field` (`:1279`).
  final String? yField;

  /// `encoding.x2.field` (`:1280`).
  final String? x2Field;

  /// `encoding.color.field` (`:1281`), or `__conditional_color__` when a
  /// conditional colour was materialised (`:1194`).
  final String? colorField;

  /// `encoding.size.field` (`:1282`), the scatter marker size.
  final String? sizeField;

  /// `encoding.theta.field` (`:1283`).
  final String? thetaField;

  /// `encoding.radius.field` (`:1284`).
  final String? radiusField;

  /// `encoding.x.aggregate` (`:1285`).
  final String? xAggregate;

  /// `encoding.y.aggregate` (`:1286`), cleared by the `timeUnit` branch at
  /// `:1254-1256`.
  final String? yAggregate;

  /// `encoding.color.scale.scheme` (`:1398`).
  final String? colorScheme;

  /// `encoding.color.scale.range` (`:1399`).
  final List<String>? colorRange;
}

/// The field name a materialised conditional colour is written to
/// (`VegaLiteSchemaAdapter.ts:1181`).
const String _conditionalColorField = '__conditional_color__';

/// The colour a conditional encoding falls back to
/// (`VegaLiteSchemaAdapter.ts:1180`).
const String _conditionalElseColor = '#999';

/// `toLocaleString('en', {month: 'short'})` (`VegaLiteSchemaAdapter.ts:1223`),
/// indexed by `DateTime.month - 1`.
///
/// The twelve names are the constant upstream's hard-coded `'en'` produces, so
/// they are written out rather than fetched: `DateFormat.MMM('en')` throws
/// `LocaleDataException` until a caller has run `initializeDateFormatting`,
/// which a transform helper cannot do, and it would answer a different string
/// the moment that call named another locale.
const List<String> _shortMonthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String? _fieldOf(Map<String, Object?> encoding, String channel) {
  final definition = encoding[channel];
  final field = definition is Map<String, Object?> ? definition['field'] : null;
  return field is String && field.isNotEmpty ? field : null;
}

String? _aggregateOf(Map<String, Object?> encoding, String channel) {
  final definition = encoding[channel];
  final aggregate = definition is Map<String, Object?>
      ? definition['aggregate']
      : null;
  return aggregate is String && aggregate.isNotEmpty ? aggregate : null;
}

/// `new Date(value)` for the two forms a data cell can hold
/// (`VegaLiteSchemaAdapter.ts:1210`, `:826-827`).
///
/// A date-only string is parsed as LOCAL midnight here and as UTC midnight by
/// `new Date`, so west of Greenwich upstream buckets `'2024-01-01'` under the
/// previous year and this port does not. Following upstream would mean reading
/// a wall-clock field through a timezone the spec never named, which changes
/// the axis labels; the divergence is deliberate.
/// // parity: VegaLiteSchemaAdapter.ts:1210
DateTime? _asDate(Object? value) {
  if (value is DateTime) return value;
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Builds the transform context (`VegaLiteSchemaAdapter.ts:1162-1268`).
///
/// Pass the **cloned** spec: the conditional-colour branch writes a new column
/// into every data row (`:1183-1190`) and replaces `encoding.color` outright
/// (`:1193-1198`), and the `timeUnit` branch rewrites `encoding.x.type` and
/// deletes two keys (`:1252-1256`).
FluentVegaTransformContext initializeTransformContext(
  Map<String, Object?> spec,
) {
  final unitSpecs = normalizeVegaSpec(spec);
  if (unitSpecs.isEmpty) {
    // `:1166`, message verbatim.
    throw const VegaSpecException(
      'VegaLiteSchemaAdapter: No valid unit specs found in specification',
    );
  }

  final primarySpec = unitSpecs.first;
  // `:1170-1173`: the TOP-LEVEL transforms run first, then the layer's own.
  var data = applyVegaTransforms(
    extractVegaDataValues(primarySpec['data']),
    spec['transform'] is List<Object?>
        ? spec['transform']! as List<Object?>
        : null,
  );
  data = applyVegaTransforms(
    data,
    primarySpec['transform'] is List<Object?>
        ? primarySpec['transform']! as List<Object?>
        : null,
  );

  final encodingRaw = primarySpec['encoding'];
  final encoding = encodingRaw is Map<String, Object?>
      ? encodingRaw
      : <String, Object?>{};

  // `:1177-1199`: a conditional colour is evaluated once per row and baked into
  // a synthetic column, because the chart layer has no notion of a predicate.
  final colorEnc = encoding['color'];
  final condition = colorEnc is Map<String, Object?>
      ? colorEnc['condition']
      : null;
  if (condition is Map<String, Object?> && condition['test'] is String) {
    final test = condition['test']! as String;
    final trueValue = condition['value'];
    final elseRaw = (colorEnc! as Map<String, Object?>)['value'];
    // `:1180`: `||`, so an empty-string else colour also takes the fallback.
    final elseValue = elseRaw is String && elseRaw.isNotEmpty
        ? elseRaw
        : _conditionalElseColor;

    for (final row in data) {
      Object? resolved;
      try {
        // `:1186`: JavaScript truthiness on the result.
        resolved = jsTruthy(evaluateVegaExpression(test, row))
            ? trueValue
            : elseValue;
      } on VegaExpressionException {
        // `:1187-1189`.
        resolved = elseValue;
      }
      row[_conditionalColorField] = resolved;
    }

    // `:1193-1198`: the scale's domain and range are BOTH the two colours, and
    // the legend is suppressed.
    encoding['color'] = <String, Object?>{
      'field': _conditionalColorField,
      'type': 'nominal',
      'scale': <String, Object?>{
        'domain': <Object?>[trueValue, elseValue],
        'range': <Object?>[trueValue, elseValue],
      },
      'legend': null,
    };
  }

  // `:1202-1257`: a `timeUnit` on x collapses the rows into one per time bucket.
  final x = encoding['x'];
  final xTimeUnit = x is Map<String, Object?> ? x['timeUnit'] : null;
  final xField = _fieldOf(encoding, 'x');
  if (xTimeUnit is String && xTimeUnit.isNotEmpty && xField != null) {
    final yField = _fieldOf(encoding, 'y');
    // `:1206`: `||`, so an absent aggregate is `mean` with a y field and `count`
    // without one.
    final yAgg =
        _aggregateOf(encoding, 'y') ?? (yField != null ? 'mean' : 'count');

    final groups = <String, List<Map<String, Object?>>>{};
    for (final row in data) {
      final dateVal = _asDate(row[xField]);
      // `:1211-1213`: an unparseable date drops the row entirely.
      if (dateVal == null) continue;
      final String key;
      switch (xTimeUnit) {
        case 'year':
          key = '${dateVal.year}';
        case 'quarter':
          // `:1220`: `Math.floor(getMonth() / 3) + 1` over a zero-based month,
          // so the three months of a quarter share one key and the count is 1-4.
          key = 'Q${(dateVal.month - 1) ~/ 3 + 1}';
        case 'month':
          // `:1223`: `toLocaleString('en', {month: 'short'})`. The `'en'` is
          // UPSTREAM'S OWN hard-coding, not this port's; following the ambient
          // locale here would change the group keys and therefore the axis
          // labels, which is a divergence rather than an improvement.
          key = _shortMonthNames[dateVal.month - 1];
        case 'day':
          // `:1226`: `getDate()`, the day of the month, not the weekday.
          key = '${dateVal.day}';
        case 'hours':
          key = '${dateVal.hour}';
        default:
          // `:1232`: `String(date)`, so an unknown unit groups by the whole
          // instant and collapses nothing. // parity: VegaLiteSchemaAdapter.ts:1232
          key = dateVal.toString();
      }
      (groups[key] ??= <Map<String, Object?>>[]).add(row);
    }

    // `:1240-1249`.
    data = <Map<String, Object?>>[
      for (final group in groups.entries)
        <String, Object?>{
          xField: group.key,
          if (yField != null && yAgg != 'count')
            yField: () {
              final values = <double>[
                for (final row in group.value)
                  if (!jsToNumber(row[yField]).isNaN) jsToNumber(row[yField]),
              ];
              // `:1244`: only `sum` and everything-else-as-mean; `min` and `max`
              // are not honoured on this path.
              // // parity: VegaLiteSchemaAdapter.ts:1244
              return yAgg == 'sum' ? d3.sum(values) : (d3.mean(values) ?? 0);
            }()
          else
            // `:1246`: `yField || '__count'`.
            yField ?? '__count': group.value.length,
        },
    ];

    // `:1252-1256`: the x channel is now categorical and the aggregate has been
    // consumed, so both markers are cleared.
    (encoding['x']! as Map<String, Object?>)
      ..['type'] = 'ordinal'
      ..remove('timeUnit');
    final y = encoding['y'];
    if (y is Map<String, Object?>) y.remove('aggregate');
  }

  final color = encoding['color'];
  final scale = color is Map<String, Object?> ? color['scale'] : null;
  final scheme = scale is Map<String, Object?> ? scale['scheme'] : null;
  final range = scale is Map<String, Object?> ? scale['range'] : null;

  return FluentVegaTransformContext(
    unitSpecs: unitSpecs,
    primarySpec: primarySpec,
    data: data,
    encoding: encoding,
    // `:1259`.
    markProps: getMarkProperties(primarySpec['mark']),
    xField: _fieldOf(encoding, 'x'),
    yField: _fieldOf(encoding, 'y'),
    x2Field: _fieldOf(encoding, 'x2'),
    colorField: _fieldOf(encoding, 'color'),
    sizeField: _fieldOf(encoding, 'size'),
    thetaField: _fieldOf(encoding, 'theta'),
    radiusField: _fieldOf(encoding, 'radius'),
    xAggregate: _aggregateOf(encoding, 'x'),
    yAggregate: _aggregateOf(encoding, 'y'),
    colorScheme: scheme is String ? scheme : null,
    colorRange: range is List<Object?>
        ? <String>[
            for (final entry in range)
              if (entry is String) entry,
          ]
        : null,
  );
}

/// The colour for one series (`VegaLiteSchemaAdapter.ts:109-133`).
///
/// Four priorities: an explicit `colorValue` from the encoding, then the mark's
/// own colour, then the shared cache, then a new colour.
///
/// The new colour uses **[index], not the map's size** — reproduced verbatim
/// from the comment at `:129`: "Use local index (not colorMap.size) for
/// deterministic per-chart color assignment". This is deliberately unlike the
/// Plotly adapter, where `plotlyGetColor` keys on `map.length`; the two must not
/// be unified.
String resolveVegaSeriesColour(
  String legend,
  int index,
  String? colorValue,
  String? markColor,
  Map<String, String> colorMap, {
  required bool isDark,
  String? colorScheme,
  List<String>? colorRange,
}) {
  // `:119-121`.
  if (colorValue != null && colorValue.isNotEmpty) return colorValue;
  // `:122-124`.
  if (markColor != null && markColor.isNotEmpty) return markColor;
  // `:126-127`.
  final cached = colorMap[legend];
  if (cached != null) return cached;
  // `:130-131`.
  final colour = getVegaColor(index, colorScheme, colorRange, isDark: isDark);
  colorMap[legend] = colour;
  return colour;
}

/// Splits rows into series and, for a categorical axis, maps each distinct label
/// to a sequential index (`VegaLiteSchemaAdapter.ts:1407-1506`).
///
/// The ordinal indices ARE the plotted x values, and the returned labels are the
/// tick text that renames them, so the two must travel together.
({
  Map<String, List<({Object x, double y, double? markerSize})>> seriesMap,
  Map<String, int>? ordinalMapping,
  List<String>? ordinalLabels,
  List<String>? yOrdinalLabels,
})
groupDataBySeries(
  List<Map<String, Object?>> data,
  String? xField,
  String? yField,
  String? colorField, {
  required bool isXTemporal,
  required bool isYTemporal,
  String? xType,
  String? sizeField,
  String? yType,
}) {
  final seriesMap =
      <String, List<({Object x, double y, double? markerSize})>>{};
  if (xField == null || yField == null) {
    // `:1425-1427`.
    return (
      seriesMap: seriesMap,
      ordinalMapping: null,
      ordinalLabels: null,
      yOrdinalLabels: null,
    );
  }

  final isXOrdinal = xType == 'ordinal' || xType == 'nominal';
  final ordinalMapping = isXOrdinal ? <String, int>{} : null;
  final ordinalLabels = <String>[];
  final isYOrdinal = yType == 'ordinal' || yType == 'nominal';
  final yOrdinalMapping = isYOrdinal ? <String, int>{} : null;
  final yOrdinalLabels = <String>[];

  for (final row in data) {
    final xValue = parseVegaValue(row[xField], isTemporal: isXTemporal);
    final yValue = parseVegaValue(row[yField], isTemporal: isYTemporal);

    // `:1444-1446`.
    if (isInvalidValue(xValue) || isInvalidValue(yValue)) continue;
    // `:1449-1451`: the empty string is what `parseVegaValue` returns for a hole,
    // so this is the real null filter.
    if (xValue == '' || yValue == '') continue;
    if (yValue is! num && yValue is! String) continue;

    // `:1453`: the literal `'default'`, which is also the legend title a
    // single-series chart shows.
    final seriesName = colorField != null && row[colorField] != null
        ? jsToString(row[colorField])
        : 'default';
    final series = seriesMap[seriesName] ??=
        <({Object x, double y, double? markerSize})>[];

    // `:1460-1477`.
    final Object numericX;
    if (isXOrdinal && xValue is String) {
      final existing = ordinalMapping![xValue];
      if (existing == null) {
        ordinalMapping[xValue] = ordinalMapping.length;
        ordinalLabels.add(xValue);
      }
      numericX = ordinalMapping[xValue]!;
    } else if (xValue is String) {
      // `:1470-1474`: `parseFloat`, which unlike `Number` accepts a trailing
      // remainder, and a NaN drops the row.
      final parsed = _parseFloat(xValue);
      if (parsed == null) continue;
      numericX = parsed;
    } else {
      numericX = xValue;
    }

    // `:1479`.
    final markerSizeRaw = sizeField != null && row[sizeField] != null
        ? jsToNumber(row[sizeField])
        : null;

    // `:1482-1491`.
    final double numericY;
    if (isYOrdinal && yValue is String) {
      final existing = yOrdinalMapping![yValue];
      if (existing == null) {
        yOrdinalMapping[yValue] = yOrdinalMapping.length;
        yOrdinalLabels.add(yValue);
      }
      numericY = yOrdinalMapping[yValue]!.toDouble();
    } else {
      // `:1490`: a non-ordinal string y becomes 0, not a dropped row.
      // // parity: VegaLiteSchemaAdapter.ts:1490
      numericY = yValue is num ? yValue.toDouble() : 0;
    }

    series.add((
      x: numericX,
      y: numericY,
      // `:1496`: the key is omitted for a NaN size, so the chart's own default
      // radius applies.
      markerSize: markerSizeRaw == null || markerSizeRaw.isNaN
          ? null
          : markerSizeRaw,
    ));
  }

  return (
    seriesMap: seriesMap,
    ordinalMapping: ordinalMapping,
    // `:1503-1504`: an empty list becomes null, so a caller can test one thing.
    ordinalLabels: ordinalLabels.isEmpty ? null : ordinalLabels,
    yOrdinalLabels: yOrdinalLabels.isEmpty ? null : yOrdinalLabels,
  );
}

/// `parseFloat` — a leading number with any trailing remainder
/// (`VegaLiteSchemaAdapter.ts:1470`).
double? _parseFloat(String text) {
  final match = RegExp(
    r'^\s*[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?',
  ).firstMatch(text);
  return match == null ? null : double.tryParse(match.group(0)!.trim());
}

/// Aggregates rows into one `{category, value}` map per group
/// (`VegaLiteSchemaAdapter.ts:1300-1361`).
///
/// A `count` collects a 1 per row (`:1317`), so a row whose value field is null
/// still counts; every other op drops such a row before aggregating (`:1318`).
List<Map<String, Object?>> computeAggregateData(
  List<Map<String, Object?>> data,
  String groupField,
  String? valueField,
  String aggregate,
) {
  final groups = <String, List<double>>{};
  for (final row in data) {
    final category = jsToString(row[groupField]);
    if (aggregate == 'count') {
      // `:1317`: the pushed value is never read, only counted.
      (groups[category] ??= <double>[]).add(1);
    } else if (valueField != null && row[valueField] != null) {
      final value = jsToNumber(row[valueField]);
      if (!value.isNaN) (groups[category] ??= <double>[]).add(value);
    }
  }

  return <Map<String, Object?>>[
    for (final group in groups.entries)
      <String, Object?>{
        'category': group.key,
        'value': switch (aggregate) {
          // `:1338`.
          'count' => group.value.length.toDouble(),
          // `:1341`: a hand-rolled reduce with a 0 seed, so an empty group is 0
          // rather than `d3.sum`'s falsy-skipping behaviour.
          'sum' => group.value.fold<double>(0, (a, b) => a + b),
          // `:1345`: divided by the length with NO empty guard, so an empty group
          // is NaN. Cannot happen — a group only exists once a value was pushed —
          // but reproduced rather than defended.
          // // parity: VegaLiteSchemaAdapter.ts:1345
          'mean' || 'average' =>
            group.value.fold<double>(0, (a, b) => a + b) / group.value.length,
          // `:1348`.
          'min' => d3.min<num>(group.value)?.toDouble() ?? 0,
          // `:1351`.
          'max' => d3.max<num>(group.value)?.toDouble() ?? 0,
          // `:1354`: the default is a count.
          _ => group.value.length.toDouble(),
        },
      },
  ];
}

/// Counts rows per x category, split by the colour field
/// (`VegaLiteSchemaAdapter.ts:1367-1388`).
///
/// Returns upstream's nested shape: outer key the x value, inner key the legend.
/// A row with an absent x is dropped (`:1376-1378`); a row with an absent colour
/// value falls back to [defaultLegend] (`:1380`).
Map<String, Map<String, int>> countByCategory(
  List<Map<String, Object?>> data,
  String xField,
  String? colorField,
  String defaultLegend,
) {
  final countMap = <String, Map<String, int>>{};
  for (final row in data) {
    final xValue = row[xField];
    if (xValue == null) continue;
    final xKey = jsToString(xValue);
    final legend = colorField != null && row[colorField] != null
        ? jsToString(row[colorField])
        : defaultLegend;
    final legendMap = countMap[xKey] ??= <String, int>{};
    // `:1385`: `(legendMap.get(legend) || 0) + 1`.
    legendMap[legend] = (legendMap[legend] ?? 0) + 1;
  }
  return countMap;
}

/// The first truthy value among [keys] on [channel] (`:696-698`, `:817-818`).
///
/// The upstream chains are `||`, so `0`, `''` and `false` fall through to the
/// next key rather than being taken.
Object? _channelValue(Map<String, Object?>? channel, List<String> keys) {
  if (channel == null) return null;
  for (final key in keys) {
    final value = channel[key];
    if (jsTruthy(value)) return value;
  }
  return null;
}

/// Turns `text` and `rule` layers into chart annotations
/// (`VegaLiteSchemaAdapter.ts:683-782`).
///
/// A horizontal rule looks for a companion `text` layer at the same y value and
/// borrows its label (`:730-740`); a vertical rule does not, and is labelled with
/// its own coordinate (`:765`). // parity: VegaLiteSchemaAdapter.ts:765
List<FluentChartAnnotation> extractVegaAnnotations(Map<String, Object?> spec) {
  final annotations = <FluentChartAnnotation>[];
  final layerRaw = spec['layer'];
  if (layerRaw is! List<Object?>) {
    // `:686-688`.
    return annotations;
  }

  for (var index = 0; index < layerRaw.length; index++) {
    final layer = layerRaw[index];
    if (layer is! Map<String, Object?>) continue;
    final mark = getMarkType(layer['mark']);
    final markObject = layer['mark'] is Map<String, Object?>
        ? layer['mark']! as Map<String, Object?>
        : null;
    final encodingRaw = layer['encoding'];
    final encoding = encodingRaw is Map<String, Object?>
        ? encodingRaw
        : const <String, Object?>{};
    final x = encoding['x'] is Map<String, Object?>
        ? encoding['x']! as Map<String, Object?>
        : null;
    final y = encoding['y'] is Map<String, Object?>
        ? encoding['y']! as Map<String, Object?>
        : null;

    // `:695-718`: a text mark with both positional channels.
    if (mark == 'text' && x != null && y != null) {
      final text = encoding['text'];
      final textValue = _channelValue(
        text is Map<String, Object?> ? text : null,
        const <String>['datum', 'value', 'field'],
      );
      final xValue = _channelValue(x, const <String>[
        'datum',
        'value',
        'field',
      ]);
      final yValue = _channelValue(y, const <String>[
        'datum',
        'value',
        'field',
      ]);
      // `:700-704`: the text must be truthy, but a coordinate only has to be
      // DEFINED — `xValue !== undefined || encoding.x.datum !== undefined` — so
      // a `datum` of 0 keeps the annotation the `||` chain above dropped.
      final hasX = xValue != null || x.containsKey('datum');
      final hasY = yValue != null || y.containsKey('datum');
      if (textValue != null && hasX && hasY) {
        final markColour = markObject?['color'];
        annotations.add(
          FluentChartAnnotation(
            // `:706`.
            id: 'text-annotation-$index',
            // `:707`.
            text: jsToString(textValue),
            // `:710-711`: `datum` wins again over the already-resolved value,
            // and 0 is the last arm of both chains.
            coordinates: FluentDataCoordinate(
              x: jsTruthy(x['datum']) ? x['datum']! : (xValue ?? 0),
              y: jsTruthy(y['datum']) ? y['datum']! : (yValue ?? 0),
            ),
            style: FluentChartAnnotationStyle(
              // `:714`.
              textColor: markColour is String
                  ? parseCssColour(markColour)
                  : null,
            ),
          ),
        );
      }
    }

    // `:721-778`.
    if (mark == 'rule') {
      // `:722-723`: the defaults apply only to a STRING mark, which cannot carry
      // a colour at all, so a `{type: 'rule'}` object with no colour yields null
      // rather than black. Reproduced. // parity: VegaLiteSchemaAdapter.ts:722
      final markColourRaw = markObject == null ? '#000' : markObject['color'];
      final markColour = markColourRaw is String ? markColourRaw : null;
      final strokeWidthRaw = markObject?['strokeWidth'];
      // `:723`: `layer.mark.strokeWidth || 1`, so a 0 width also takes the 1.
      final markStrokeWidth = strokeWidthRaw is num && strokeWidthRaw != 0
          ? strokeWidthRaw.toDouble()
          : 1.0;
      // `:724-725`.
      final markStrokeDash = markObject?['strokeDash'];

      final yConstant = y != null && (y['value'] != null || y['datum'] != null);
      final xConstant = x != null && (x['value'] != null || x['datum'] != null);

      if (yConstant) {
        // `:728-758`: a horizontal reference line.
        final yValue = y['value'] ?? y['datum'];
        Object? companionText;
        for (var i = 0; i < layerRaw.length; i++) {
          // `:732-734`.
          if (i == index) continue;
          final candidate = layerRaw[i];
          if (candidate is! Map<String, Object?>) continue;
          if (getMarkType(candidate['mark']) != 'text') continue;
          final candidateEncoding = candidate['encoding'];
          final candidateY = candidateEncoding is Map<String, Object?>
              ? candidateEncoding['y']
              : null;
          if (candidateY is! Map<String, Object?>) continue;
          // `:736`: `datum ?? value` here, the other way round from `:729`.
          if ((candidateY['datum'] ?? candidateY['value']) == yValue) {
            companionText = candidate;
            break;
          }
        }
        var ruleText = jsToString(yValue);
        if (companionText is Map<String, Object?>) {
          final companionEncoding = companionText['encoding'];
          final companionTextChannel = companionEncoding is Map<String, Object?>
              ? companionEncoding['text']
              : null;
          // `:739`: the companion's own value falls back to the rule's y.
          final label = _channelValue(
            companionTextChannel is Map<String, Object?>
                ? companionTextChannel
                : null,
            const <String>['datum', 'value'],
          );
          ruleText = jsToString(label ?? yValue);
        }

        annotations.add(
          FluentChartAnnotation(
            // `:743`.
            id: 'rule-h-$index',
            // `:744`.
            text: ruleText,
            // `:747-748`: x is pinned to 0, so the label sits at the axis origin.
            coordinates: FluentDataCoordinate(x: 0, y: yValue ?? 0),
            style: FluentChartAnnotationStyle(
              // `:751-753`.
              textColor: markColour == null ? null : parseCssColour(markColour),
              borderColor: markColour == null
                  ? null
                  : parseCssColour(markColour),
              borderWidth: markStrokeWidth,
              // `:754-756`: a stroke dash sets `borderRadius: 0` as a marker.
              // `FluentChartAnnotationStyle.borderStyle` says the same thing
              // properly, so the dashed intent is carried there instead of
              // through a radius that means nothing.
              borderStyle: markStrokeDash is List<Object?>
                  ? FluentChartAnnotationBorderStyle.dashed
                  : null,
            ),
          ),
        );
      } else if (xConstant) {
        // `:761-777`: a vertical reference line. `else if`, so a rule with BOTH
        // constants is only ever horizontal.
        final xValue = x['value'] ?? x['datum'];
        annotations.add(
          FluentChartAnnotation(
            // `:764-765`.
            id: 'rule-v-$index',
            text: jsToString(xValue),
            // `:768-769`: y is pinned to 0 here instead.
            coordinates: FluentDataCoordinate(x: xValue ?? 0, y: 0),
            style: FluentChartAnnotationStyle(
              // `:772-774`.
              textColor: markColour == null ? null : parseCssColour(markColour),
              borderColor: markColour == null
                  ? null
                  : parseCssColour(markColour),
              borderWidth: markStrokeWidth,
            ),
          ),
        );
      }
    }
  }

  return annotations;
}

/// Turns `rect` layers with `x` and `x2` into background regions
/// (`VegaLiteSchemaAdapter.ts:787-847`).
///
/// Temporality is decided ONCE, from whether any NON-rect layer declares a
/// temporal x (`:795-802`), and then applied to every region.
List<FluentColorFillBar> extractVegaColorFillBars(
  Map<String, Object?> spec,
  Map<String, String> colorMap, {
  required bool isDark,
}) {
  final colorFillBars = <FluentColorFillBar>[];
  final layerRaw = spec['layer'];
  if (layerRaw is! List<Object?>) {
    // `:790-792`.
    return colorFillBars;
  }

  var isXTemporal = false;
  for (final layer in layerRaw) {
    if (layer is! Map<String, Object?>) continue;
    // `:798-800`.
    if (getMarkType(layer['mark']) == 'rect') continue;
    final encoding = layer['encoding'];
    final x = encoding is Map<String, Object?> ? encoding['x'] : null;
    if (x is Map<String, Object?> && x['type'] == 'temporal') {
      isXTemporal = true;
      break;
    }
  }

  for (var index = 0; index < layerRaw.length; index++) {
    final layer = layerRaw[index];
    if (layer is! Map<String, Object?>) continue;
    if (getMarkType(layer['mark']) != 'rect') continue;
    final encodingRaw = layer['encoding'];
    final encoding = encodingRaw is Map<String, Object?>
        ? encodingRaw
        : const <String, Object?>{};
    final x = encoding['x'];
    final x2 = encoding['x2'];
    // `:809`.
    if (x is! Map<String, Object?> || x2 is! Map<String, Object?>) continue;

    // `:810`.
    final legend = 'region-$index';
    final markObject = layer['mark'] is Map<String, Object?>
        ? layer['mark']! as Map<String, Object?>
        : null;
    final declared = markObject?['color'];
    // `:811-814`: the mark colour, else a fresh colour with NO scheme and NO
    // range, so the region takes the plain qualitative cycle.
    final colour = declared is String && declared.isNotEmpty
        ? declared
        : getVegaColorFromMap(legend, colorMap, null, null, isDark: isDark);

    // `:817-818`: plain `||`, so a `datum` of 0 or `''` falls through to `value`.
    final rawStartX = _channelValue(x, const <String>['datum', 'value']);
    final rawEndX = _channelValue(x2, const <String>['datum', 'value']);
    // `:820`.
    if (rawStartX == null || rawEndX == null) continue;

    // `:822-834`: a parse failure leaves the raw value in place.
    var startX = rawStartX;
    var endX = rawEndX;
    if (isXTemporal) {
      final parsedStart = _asDate(rawStartX);
      final parsedEnd = _asDate(rawEndX);
      if (parsedStart != null) startX = parsedStart;
      if (parsedEnd != null) endX = parsedEnd;
    }

    colorFillBars.add(
      FluentColorFillBar(
        // `:837-839`.
        legend: legend,
        color: parseCssColour(colour),
        data: <FluentColorFillBarRange>[
          FluentColorFillBarRange(startX: startX, endX: endX),
        ],
        // `:840`.
        applyPattern: false,
      ),
    );
  }

  return colorFillBars;
}
