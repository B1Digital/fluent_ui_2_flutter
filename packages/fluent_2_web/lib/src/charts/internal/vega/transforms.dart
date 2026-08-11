import '../d3/array_stats.dart' as d3;
import '../d3/stable_sort.dart';
import 'expression.dart';
import 'js_value.dart';

/// Unpivots wide-format rows into long format
/// (`VegaLiteSchemaAdapter.ts:174-204`).
///
/// Each input row becomes one output row per folded field that is actually
/// present (`:193`), carrying every non-folded column forward.
List<Map<String, Object?>> applyFoldTransform(
  List<Map<String, Object?>> data,
  List<String> fields,
  List<String> asFields,
) {
  // `:177`, `:179`: the destructured names, with the defaults the parameter's
  // own initialiser supplies. 0 and 1 are the two positions that initialiser
  // spells.
  final keyField = asFields.isNotEmpty ? asFields[0] : 'key';
  final valueField = asFields.length > 1 ? asFields[1] : 'value';
  final result = <Map<String, Object?>>[];

  for (final row in data) {
    // `:184-189`.
    final baseRow = <String, Object?>{
      for (final entry in row.entries)
        if (!fields.contains(entry.key)) entry.key: entry.value,
    };
    // `:192-200`.
    for (final field in fields) {
      if (!row.containsKey(field)) {
        continue;
      }
      result.add(<String, Object?>{
        ...baseRow,
        keyField: field,
        valueField: row[field],
      });
    }
  }

  return result;
}

/// The group key a `groupby` list produces (`VegaLiteSchemaAdapter.ts:267`).
///
/// `String(undefined)` is the literal `'undefined'`, so a row missing a group
/// field joins the same group as every other row missing it — and a *different*
/// group from a row whose value is a real `null`, which stringifies to
/// `'null'`.
String _groupKey(Map<String, Object?> row, List<String> groupby) => groupby
    .map(
      (field) => jsToString(
        row.containsKey(field) ? row[field] : JsUndefined.instance,
      ),
    )
    .join('|');

/// The numeric column an aggregate op reads
/// (`VegaLiteSchemaAdapter.ts:281`, `:387`).
///
/// An op with no `field` reads the EMPTY list, which is why `sum` with no field
/// is 0 and `min` with no field falls through to its `?? 0`.
List<double> _numericValues(List<Map<String, Object?>> rows, Object? field) {
  if (field is! String) {
    return const <double>[];
  }
  final values = <double>[];
  for (final row in rows) {
    final value = jsToNumber(row[field]);
    if (!value.isNaN) {
      values.add(value);
    }
  }
  return values;
}

/// One aggregate op applied to one group (`VegaLiteSchemaAdapter.ts:282-301`,
/// and the identical switch at `:388-407`).
///
/// The `default` arm is the row **count**, so an unrecognised op silently
/// becomes a count rather than failing. // parity: VegaLiteSchemaAdapter.ts:299
double _aggregate(
  Object? op,
  List<Map<String, Object?>> rows,
  List<double> values,
) {
  switch (op) {
    case 'count':
      return rows.length.toDouble();
    case 'sum':
      return d3.sum(values);
    case 'mean':
    case 'average':
      // 0 is upstream's own `?? 0` at `:291`, reached for an empty column.
      return d3.mean(values)?.toDouble() ?? 0;
    case 'min':
      // `:294`.
      return d3.min<num>(values)?.toDouble() ?? 0;
    case 'max':
      // `:297`.
      return d3.max<num>(values)?.toDouble() ?? 0;
    default:
      return rows.length.toDouble();
  }
}

/// Groups rows, preserving first-seen group order.
///
/// Dart's map literal is already a `LinkedHashMap`, so the iteration order
/// matches V8's `Map.forEach` without any extra type.
Map<String, List<Map<String, Object?>>> _group(
  List<Map<String, Object?>> rows,
  List<String> groupby, {
  required bool useAllFallback,
}) {
  final groups = <String, List<Map<String, Object?>>>{};
  for (final row in rows) {
    // `:267` builds the key unconditionally, so an empty `groupby` yields `''`;
    // `:316` and `:376` instead substitute `'__all__'`. Both produce exactly one
    // group, and the difference is not observable — reproduced anyway so the two
    // code paths read the same as upstream's.
    final key = useAllFallback && groupby.isEmpty
        ? '__all__'
        : _groupKey(row, groupby);
    (groups[key] ??= <Map<String, Object?>>[]).add(row);
  }
  return groups;
}

/// Reads a transform's `groupby` list, dropping any entry that is not a name
/// (`:263`, `:311`, `:371`, each of which casts without checking).
List<String> _stringList(Object? value) => value is List<Object?>
    ? <String>[
        for (final entry in value)
          if (entry is String) entry,
      ]
    : const <String>[];

/// Applies a spec's `transform` array to its data
/// (`VegaLiteSchemaAdapter.ts:214-417`, continued at `:419-562`).
///
/// Every op is an independent `if`, **not** an `else if`, so one transform
/// object carrying both `fold` and `filter` fires both, in source order.
List<Map<String, Object?>> applyVegaTransforms(
  List<Map<String, Object?>> data,
  List<Object?>? transforms,
) {
  // `:218-220`.
  if (transforms == null || transforms.isEmpty) {
    return data;
  }

  var result = data;

  for (final entry in transforms) {
    if (entry is! Map<String, Object?>) {
      continue;
    }
    final transform = entry;

    // `:226-230`: fold.
    final fold = transform['fold'];
    if (transform.containsKey('fold') && fold is List<Object?>) {
      final asRaw = transform['as'];
      result = applyFoldTransform(
        result,
        _stringList(fold),
        // `:228`: `||`, so an absent `as` takes the defaults.
        asRaw is List<Object?>
            ? _stringList(asRaw)
            : const <String>['key', 'value'],
      );
    }

    // `:233-244`: filter.
    if (transform.containsKey('filter')) {
      final filterExpr = transform['filter'];
      if (filterExpr is String) {
        result = <Map<String, Object?>>[
          for (final row in result)
            // `:237-241`: a throwing expression KEEPS the row. A rejected
            // identifier is therefore invisible rather than fatal.
            if (_filterKeeps(filterExpr, row)) row,
        ];
      }
    }

    // `:247-258`: calculate.
    if (transform.containsKey('calculate') && transform.containsKey('as')) {
      final expr = transform['calculate'];
      final asField = transform['as'];
      if (expr is String && asField is String) {
        result = <Map<String, Object?>>[
          for (final row in result) _calculated(expr, asField, row),
        ];
      }
    }

    // `:261-305`: aggregate — replaces every row with one row per group.
    final aggregate = transform['aggregate'];
    if (transform.containsKey('aggregate') && aggregate is List<Object?>) {
      final groupby = _stringList(transform['groupby']);
      final groups = _group(result, groupby, useAllFallback: false);
      result = <Map<String, Object?>>[
        for (final group in groups.values)
          <String, Object?>{
            // `:276-278`: the group columns come from the FIRST row of the
            // group.
            for (final field in groupby) field: group.first[field],
            for (final spec in aggregate)
              if (spec is Map<String, Object?> && spec['as'] is String)
                spec['as']! as String: _aggregate(
                  spec['op'],
                  group,
                  _numericValues(group, spec['field']),
                ),
          },
      ];
    }

    // `:308-366`: window — keeps every row and adds columns.
    final window = transform['window'];
    if (transform.containsKey('window') && window is List<Object?>) {
      final groupby = _stringList(transform['groupby']);
      final sortRaw = transform['sort'];
      final sortFields = <Map<String, Object?>>[
        if (sortRaw is List<Object?>)
          for (final field in sortRaw)
            if (field is Map<String, Object?>) field,
      ];
      final groups = _group(result, groupby, useAllFallback: true);
      final newResult = <Map<String, Object?>>[];

      for (final group in groups.values) {
        var rows = group;
        if (sortFields.isNotEmpty) {
          // `:327-337`: the comparator returns 0 for a tie, so the sort must be
          // stable. Dart's `List.sort` is not; V8's has been since ES2019.
          rows = stableSort(List<Map<String, Object?>>.of(group), (a, b) {
            for (final sortField in sortFields) {
              final field = sortField['field'];
              if (field is! String) {
                continue;
              }
              // `:329-330`: `Number(x) || 0`, so NaN AND 0 both become 0.
              final va = _numberOrZero(a[field]);
              final vb = _numberOrZero(b[field]);
              final cmp = sortField['order'] == 'descending'
                  ? vb - va
                  : va - vb;
              // -1 and 1 are the sign of upstream's own subtraction (`:333`),
              // which Dart's comparator requires as an int.
              if (cmp != 0) {
                return cmp < 0 ? -1 : 1;
              }
            }
            return 0;
          });
        }

        // `:340`: ONE accumulator per group, declared inside the `groups.forEach`
        // that opens at `:324` — so it RESETS between groups, and is shared by
        // every op in the window list. Two `sum` ops in the same transform
        // therefore both read the combined running total, and a `sum` op after a
        // `rank` op still sees the sum of every preceding row. Reproduced.
        // // parity: VegaLiteSchemaAdapter.ts:340
        var runningSum = 0.0;
        for (var idx = 0; idx < rows.length; idx++) {
          final row = rows[idx];
          final newRow = <String, Object?>{...row};
          for (final op in window) {
            if (op is! Map<String, Object?>) {
              continue;
            }
            final asField = op['as'];
            if (asField is! String) {
              continue;
            }
            switch (op['op']) {
              case 'sum':
                runningSum += _numberOrZero(row[op['field']]);
                newRow[asField] = runningSum;
              default:
                // `:349-359`: `rank`, `row_number`, `count` and the `default`
                // arm are ALL `idx + 1`, so `count` is really a row number and
                // `rank` does not share a rank between ties. Collapsed into one
                // arm because four identical bodies would only invite one of
                // them to drift. 1 is upstream's own offset from a zero-based
                // index to a one-based rank.
                // // parity: VegaLiteSchemaAdapter.ts:355
                newRow[asField] = idx + 1;
            }
          }
          newResult.add(newRow);
        }
      }
      result = newResult;
    }

    // `:369-417`: joinaggregate — computes per group, then joins back onto every
    // row, so the row count is unchanged.
    final joinaggregate = transform['joinaggregate'];
    if (transform.containsKey('joinaggregate') &&
        joinaggregate is List<Object?>) {
      final groupby = _stringList(transform['groupby']);
      final groups = _group(result, groupby, useAllFallback: true);
      final aggResults = <String, Map<String, Object?>>{};
      for (final group in groups.entries) {
        aggResults[group.key] = <String, Object?>{
          for (final spec in joinaggregate)
            if (spec is Map<String, Object?> && spec['as'] is String)
              spec['as']! as String: _aggregate(
                spec['op'],
                group.value,
                _numericValues(group.value, spec['field']),
              ),
        };
      }
      result = <Map<String, Object?>>[
        for (final row in result)
          <String, Object?>{
            ...row,
            // `:415`: `|| {}` — a row whose key is missing gains nothing.
            ...?aggResults[groupby.isEmpty
                ? '__all__'
                : _groupKey(row, groupby)],
          },
      ];
    }
  }

  return result;
}

/// `Number(x) || 0` (`VegaLiteSchemaAdapter.ts:329-330`, `:346`).
///
/// 0 is the right-hand operand of upstream's own `||`.
double _numberOrZero(Object? value) {
  final number = jsToNumber(value);
  return number.isNaN ? 0 : number;
}

/// `:236-242`.
///
/// [jsTruthy] is what makes this a filter rather than a cast: upstream's
/// `safeEvaluateExpression` result is handed straight to
/// `Array.prototype.filter` at `:238`, which applies JavaScript truthiness, so
/// a raw `0` or `''` drops the row.
bool _filterKeeps(String expr, Map<String, Object?> row) {
  try {
    return jsTruthy(evaluateVegaExpression(expr, row));
  } on VegaExpressionException {
    // A rejected identifier or a parse failure keeps the row.
    return true;
  }
}

/// `:250-257`.
Map<String, Object?> _calculated(
  String expr,
  String asField,
  Map<String, Object?> row,
) {
  try {
    return <String, Object?>{
      ...row,
      asField: evaluateVegaExpression(expr, row),
    };
  } on VegaExpressionException {
    // `:254-256`: the row passes through unchanged, WITHOUT the new column, so a
    // downstream read of `asField` sees undefined rather than a default.
    return row;
  }
}
