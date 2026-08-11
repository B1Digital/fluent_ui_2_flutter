import 'package:flutter/foundation.dart';

import 'js_value.dart';
import 'spec.dart';

/// The eleven chart kinds a Vega-Lite spec can route to
/// (`VegaLiteSchemaAdapter.ts:1630-1641`).
enum FluentVegaChartKind {
  /// The default arm (`:1748`), and where `trail`, `errorbar` and `errorband`
  /// also land.
  line,

  /// A plain bar chart, one bar per distinct x (`:1727`).
  bar,

  /// `'stacked-bar'` upstream (`:1714`), and the bar-plus-line layer combo
  /// (`:1663-1665`).
  stackedBar,

  /// `'grouped-bar'` upstream (`:1712`), selected by an `xOffset` channel.
  groupedBar,

  /// `'horizontal-bar'` upstream (`:1706`).
  horizontalBar,

  /// An `area` mark (`:1731`).
  area,

  /// `point`, `circle`, `square` or `tick` (`:1735`).
  scatter,

  /// An `arc` mark with `theta` but no `radius` (`:1683`).
  donut,

  /// A `rect` mark with x, y and colour fields (`:1693`).
  heatmap,

  /// A `bar` mark whose x channel declares a `bin` (`:1699`).
  histogram,

  /// `theta` **and** `radius`, with or without an `arc` mark (`:1678`, `:1688`).
  polar,
}

/// The routing decision for one spec (`VegaLiteSchemaAdapter.ts:1629-1643`).
@immutable
class FluentVegaChartTypeResult {
  /// Creates a routing result.
  const FluentVegaChartTypeResult({required this.kind, required this.mark});

  /// The chart to build.
  final FluentVegaChartKind kind;

  /// The mark that decided it. Upstream's type is a non-optional `string`, and
  /// the default arm substitutes `'line'` when the spec declares no mark at all
  /// (`:1748`).
  final String mark;
}

/// The first layer of [layer], or null when there is no readable one.
///
/// `spec.layer[0]` in JavaScript is `undefined` both for an empty array and for
/// a `layer` that is not an array at all, and neither reaches a `.mark` — so
/// both answer null here.
Map<String, Object?>? _firstLayer(Object? layer) {
  if (layer is! List<Object?> || layer.isEmpty) {
    return null;
  }
  final first = layer.first;
  return first is Map<String, Object?> ? first : null;
}

/// True when [value] is a JavaScript object — a map or a list, but not a
/// `DateTime`, which `typeof` also reports as `'object'`.
bool _isJsObject(Object? value) =>
    value is Map<String, Object?> || value is List<Object?>;

/// `sample instanceof Date || (typeof sample === 'string' &&
/// !isNaN(Date.parse(sample)))` (`VegaLiteSchemaAdapter.ts:1577`).
///
/// `DateTime.tryParse` accepts ISO 8601 and a little either side of it, where
/// `Date.parse` also accepts the legacy `'March 5, 2020'` shapes. The
/// difference only decides between `'nominal'` and a surviving `'temporal'` for
/// a date string no other part of this port can read either — `parseValue`
/// (`:606`) reaches for the same parser.
bool _parsesAsDate(Object? sample) {
  if (sample is DateTime) {
    return true;
  }
  if (sample is! String) {
    return false;
  }
  return DateTime.tryParse(sample) != null;
}

/// The first non-null, non-undefined value of a column
/// (`VegaLiteSchemaAdapter.ts:1568`).
///
/// Returns [JsUndefined.instance] when the column holds no such value, because
/// `:1569` distinguishes "no sample" from "a sample that happens to be falsy".
Object? _sample(List<Map<String, Object?>> data, String field) {
  for (final row in data) {
    final value = row[field];
    if (value != null && value is! JsUndefined) {
      return value;
    }
  }
  return JsUndefined.instance;
}

/// The non-empty `field` of a channel definition, or null.
///
/// Upstream tests `!!encoding.x?.field` (`:1567`, `:1692`, `:1674`), so an
/// empty string is as absent as a missing key.
String? _fieldOf(Map<String, Object?>? channel) {
  final field = channel?['field'];
  return field is String && field.isNotEmpty ? field : null;
}

/// Reads a channel definition off an encoding map.
Map<String, Object?>? _channel(Map<String, Object?>? encoding, String name) {
  final definition = encoding?[name];
  return definition is Map<String, Object?> ? definition : null;
}

/// Rewrites declared encoding types that the data contradicts
/// (`VegaLiteSchemaAdapter.ts:1553-1627`).
///
/// **Mutates [spec] in place, and at `:1606-1611` mutates the data rows too.**
/// Callers must pass the clone from `deepCloneVegaSpec`, never the widget's own
/// `chartSchema` — see the `hardened:` note on that function.
void autoCorrectEncodingTypes(Map<String, Object?> spec) {
  // `:1554`: a layered spec is corrected through its FIRST layer only, so a
  // second layer's wrong type survives. An empty `layer` array is truthy in
  // JavaScript, so `{layer: []}` returns at `:1555` rather than falling back to
  // the top-level spec. // parity: VegaLiteSchemaAdapter.ts:1554
  final layer = spec['layer'];
  final unitSpec = jsTruthy(layer) ? _firstLayer(layer) : spec;
  if (unitSpec == null) {
    return;
  }

  final encodingRaw = unitSpec['encoding'];
  final encoding = encodingRaw is Map<String, Object?> ? encodingRaw : null;
  // `:1560`: the layer's own data, else the shared data.
  final data = extractVegaDataValues(unitSpec['data'] ?? spec['data']);
  if (encoding == null || data.isEmpty) {
    // `:1562-1564`.
    return;
  }

  // `:1567-1583`: the x channel.
  final x = _channel(encoding, 'x');
  final xField = _fieldOf(x);
  if (x != null && xField != null) {
    final sample = _sample(data, xField);
    if (sample is! JsUndefined) {
      if (x['type'] == 'quantitative') {
        if (sample is String && !jsToNumber(sample).isFinite) {
          // `:1571-1572`: a string that is not a finite number is a category.
          x['type'] = 'nominal';
        } else if (_isJsObject(sample) || sample is DateTime) {
          // `:1573-1574`: `typeof sample === 'object'` also catches a Date.
          x['type'] = 'nominal';
        }
      } else if (x['type'] == 'temporal') {
        if (!_parsesAsDate(sample)) {
          // `:1579`.
          x['type'] = sample is num ? 'quantitative' : 'nominal';
        }
      }
    }
  }

  // `:1586-1626`: the y channel, which has one extra arm the x channel lacks.
  final y = _channel(encoding, 'y');
  final yField = _fieldOf(y);
  if (y != null && yField != null) {
    final sample = _sample(data, yField);
    if (sample is! JsUndefined) {
      if (y['type'] == 'quantitative') {
        if (sample is String && !jsToNumber(sample).isFinite) {
          // `:1590-1591`.
          y['type'] = 'nominal';
        } else if (sample is Map<String, Object?>) {
          // `:1592-1615`: a plain object — not a list and not a Date. If it has
          // exactly ONE numeric property, every row's value is REPLACED by that
          // property and the type stays quantitative. This is the branch that
          // rewrites data.
          final numericKeys = <String>[
            for (final entry in sample.entries)
              if (entry.value is num) entry.key,
          ];
          // `:1602`: exactly one, so a two-number object is ambiguous rather
          // than resolved by key order.
          if (numericKeys.length == 1) {
            final numericKey = numericKeys.first;
            for (final row in data) {
              final object = row[yField];
              if (object is Map<String, Object?>) {
                row[yField] = object[numericKey];
              }
            }
          } else {
            // `:1614`.
            y['type'] = 'nominal';
          }
        } else if (_isJsObject(sample) || sample is DateTime) {
          // `:1616-1617`: a list or a Date.
          y['type'] = 'nominal';
        }
      } else if (y['type'] == 'temporal') {
        if (!_parsesAsDate(sample)) {
          // `:1622`.
          y['type'] = sample is num ? 'quantitative' : 'nominal';
        }
      }
    }
  }
}

/// Routes a spec to a chart kind (`VegaLiteSchemaAdapter.ts:1648-1749`).
///
/// Calls [autoCorrectEncodingTypes] first (`:1650`), so the type tests below see
/// the corrected types — which is why the two cannot be reordered or split. Pass
/// the cloned spec.
FluentVegaChartTypeResult getVegaChartType(Map<String, Object?> spec) {
  // `:1650`.
  autoCorrectEncodingTypes(spec);

  final layerRaw = spec['layer'];
  final hasLayer = jsTruthy(layerRaw);
  final layerList = layerRaw is List<Object?> ? layerRaw : null;

  // `:1653-1667`: a bar-plus-line layer combo becomes a stacked bar, because the
  // stacked bar chart is the one that supports line overlays. Both arms of
  // `:1662-1665` return the same thing — the `color.field` test has no effect and
  // is reproduced only as a comment, since branching on it would be dead code.
  // // parity: VegaLiteSchemaAdapter.ts:1662
  //
  // 1 is upstream's own `spec.layer.length > 1`: a single-layer spec falls
  // through to the mark cascade below.
  if (layerList != null && layerList.length > 1) {
    final marks = <String?>[
      for (final entry in layerList)
        if (entry is Map<String, Object?>) getMarkType(entry['mark']) else null,
    ];
    final hasBar = marks.contains('bar');
    final hasLine = marks.contains('line') || marks.contains('point');
    if (hasBar && hasLine) {
      return const FluentVegaChartTypeResult(
        kind: FluentVegaChartKind.stackedBar,
        mark: 'bar',
      );
    }
  }

  // `:1670-1674`: everything below reads the FIRST layer.
  final first = _firstLayer(layerRaw);
  // The parentheses are load-bearing: `a ? b?[c] : d` parses `?[` as the start
  // of a conditional expression, not as a null-aware index.
  final mark = hasLayer ? (first?['mark']) : spec['mark'];
  // `getMarkType` answers null for both an absent mark and the empty string
  // (`:96`), and upstream's own `markType || 'line'` at `:1748` collapses the
  // two the same way — so the empty string is the one absent value here, and a
  // `String?` that Dart would refuse to promote through `markType === 'arc'`
  // never arises.
  final markType = getMarkType(mark) ?? '';
  final encodingRaw = hasLayer ? (first?['encoding']) : spec['encoding'];
  final encoding = encodingRaw is Map<String, Object?> ? encodingRaw : null;
  final hasColorEncoding = _fieldOf(_channel(encoding, 'color')) != null;
  final hasTheta = jsTruthy(encoding?['theta']);
  final hasRadius = jsTruthy(encoding?['radius']);
  final x = _channel(encoding, 'x');
  final y = _channel(encoding, 'y');

  // `:1677-1679`: arc with both angular channels.
  if (markType == 'arc' && hasTheta && hasRadius) {
    return FluentVegaChartTypeResult(
      kind: FluentVegaChartKind.polar,
      mark: markType,
    );
  }
  // `:1682-1684`: arc with theta alone.
  if (markType == 'arc' && hasTheta) {
    return FluentVegaChartTypeResult(
      kind: FluentVegaChartKind.donut,
      mark: markType,
    );
  }
  // `:1687-1689`: any other mark with both angular channels. Upstream asserts
  // `markType!` here, so a spec with theta, radius and NO mark yields
  // `mark: undefined` cast to string; `''` is the honest Dart stand-in, and is
  // what `markType` already holds in that case.
  // // parity: VegaLiteSchemaAdapter.ts:1688
  if (hasTheta && hasRadius) {
    return FluentVegaChartTypeResult(
      kind: FluentVegaChartKind.polar,
      mark: markType,
    );
  }
  // `:1692-1694`.
  if (markType == 'rect' &&
      _fieldOf(x) != null &&
      _fieldOf(y) != null &&
      hasColorEncoding) {
    return FluentVegaChartTypeResult(
      kind: FluentVegaChartKind.heatmap,
      mark: markType,
    );
  }

  // `:1697-1728`: the bar ladder.
  if (markType == 'bar') {
    if (jsTruthy(x?['bin'])) {
      // `:1698-1700`: `bin` is truthy — `true`, or a `{maxbins: n}` object.
      return FluentVegaChartTypeResult(
        kind: FluentVegaChartKind.histogram,
        mark: markType,
      );
    }

    // `:1702-1703`.
    final isXNominal = x?['type'] == 'nominal' || x?['type'] == 'ordinal';
    final isYNominal = y?['type'] == 'nominal' || y?['type'] == 'ordinal';

    // `:1705-1707`: a categorical y with a numeric x is horizontal.
    if (isYNominal && !isXNominal) {
      return FluentVegaChartTypeResult(
        kind: FluentVegaChartKind.horizontalBar,
        mark: markType,
      );
    }

    if (hasColorEncoding) {
      // `:1710-1714`: an `xOffset` channel groups, its absence stacks. Note the
      // test is on the channel's PRESENCE, not on its field.
      return FluentVegaChartTypeResult(
        kind: jsTruthy(encoding?['xOffset'])
            ? FluentVegaChartKind.groupedBar
            : FluentVegaChartKind.stackedBar,
        mark: markType,
      );
    }

    // `:1717-1725`: with no colour channel, a repeated x still means several
    // series stacked on one category. Reads `spec.data.values` directly, so a
    // LAYER's own data is not consulted here even though the encoding above was.
    // // parity: VegaLiteSchemaAdapter.ts:1718
    final xField = _fieldOf(x);
    final specData = spec['data'];
    final dataValues = specData is Map<String, Object?>
        ? specData['values']
        : null;
    if (xField != null &&
        dataValues is List<Object?> &&
        dataValues.isNotEmpty) {
      final xValues = <Object?>[
        for (final row in dataValues)
          row is Map<String, Object?> ? row[xField] : null,
      ];
      if (xValues.toSet().length < xValues.length) {
        return FluentVegaChartTypeResult(
          kind: FluentVegaChartKind.stackedBar,
          mark: markType,
        );
      }
    }

    // `:1727`.
    return FluentVegaChartTypeResult(
      kind: FluentVegaChartKind.bar,
      mark: markType,
    );
  }

  // `:1730-1732`.
  if (markType == 'area') {
    return FluentVegaChartTypeResult(
      kind: FluentVegaChartKind.area,
      mark: markType,
    );
  }
  // `:1734-1736`.
  if (markType == 'point' ||
      markType == 'circle' ||
      markType == 'square' ||
      markType == 'tick') {
    return FluentVegaChartTypeResult(
      kind: FluentVegaChartKind.scatter,
      mark: markType,
    );
  }
  // `:1739-1746`: a trail carries its size encoding as a marker size, and the two
  // error marks lose their intervals entirely — both render as a plain line, and
  // both rewrite `mark` to `'line'`.
  if (markType == 'trail' ||
      markType == 'errorbar' ||
      markType == 'errorband') {
    return const FluentVegaChartTypeResult(
      kind: FluentVegaChartKind.line,
      mark: 'line',
    );
  }
  // `:1748`: the default, which keeps an unrecognised mark name. `markType ||
  // 'line'` is a truthiness test upstream, so the empty string falls back too.
  return FluentVegaChartTypeResult(
    kind: FluentVegaChartKind.line,
    mark: markType.isEmpty ? 'line' : markType,
  );
}

/// Flattens a spec into one unit spec per layer
/// (`VegaLiteSchemaAdapter.ts:572-601`).
///
/// A layered spec merges the shared `data` and `encoding` into each layer, with
/// the layer's own values winning per key (`:578-585`). A unit spec yields one
/// entry carrying only `mark`, `encoding` and `data` — every other key, including
/// `transform`, is **dropped** on this path (`:590-596`).
/// // parity: VegaLiteSchemaAdapter.ts:590
///
/// An unsupported structure yields the empty list (`:600`), which is what makes a
/// spec with a mark but no encoding render nothing rather than throwing.
List<Map<String, Object?>> normalizeVegaSpec(Map<String, Object?> spec) {
  if (isVegaLayerSpec(spec)) {
    final layer = spec['layer']! as List<Object?>;
    final sharedData = spec['data'];
    final sharedEncoding = spec['encoding'];
    return <Map<String, Object?>>[
      for (final entry in layer)
        if (entry is Map<String, Object?>)
          <String, Object?>{
            ...entry,
            // `:580`: `||`, so a layer with `data: null` inherits the shared one.
            'data': entry['data'] ?? sharedData,
            'encoding': <String, Object?>{
              if (sharedEncoding is Map<String, Object?>) ...sharedEncoding,
              if (entry['encoding'] is Map<String, Object?>)
                ...entry['encoding']! as Map<String, Object?>,
            },
          },
    ];
  }

  if (isVegaUnitSpec(spec)) {
    return <Map<String, Object?>>[
      <String, Object?>{
        'mark': spec['mark'],
        'encoding': spec['encoding'],
        'data': spec['data'],
      },
    ];
  }

  return const <Map<String, Object?>>[];
}
