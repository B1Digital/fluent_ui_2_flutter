import 'dart:math' as math;

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

    // `:420-441`: regression — collapses the dataset to the two endpoints of a
    // least-squares line.
    if (transform.containsKey('regression') && transform.containsKey('on')) {
      final yField = transform['regression'];
      final xField = transform['on'];
      final xs = <double>[];
      final ys = <double>[];
      for (final row in result) {
        final x = jsToNumber(_read(row, xField));
        final y = jsToNumber(_read(row, yField));
        // `:425`: a point survives only when BOTH coordinates are numbers.
        if (!x.isNaN && !y.isNaN) {
          xs.add(x);
          ys.add(y);
        }
      }
      // `:426`. 2 is the smallest sample a slope can be fitted to.
      if (xs.length >= 2) {
        final n = xs.length;
        final sumX = d3.sum(xs);
        final sumY = d3.sum(ys);
        final sumXY = d3.sum(<double>[
          for (var i = 0; i < n; i++) xs[i] * ys[i],
        ]);
        final sumX2 = d3.sum(<double>[for (final x in xs) x * x]);
        // `VegaLiteSchemaAdapter.ts:432-433`. The textbook OLS denominator
        // n * sumX2 - sumX * sumX cancels catastrophically for large,
        // tightly-clustered x. Reproduced as written, because a
        // numerically-stable rewrite would give a different last ulp from the
        // browser. // parity: VegaLiteSchemaAdapter.ts:432
        final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
        final intercept = (sumY - slope * sumX) / n;
        // `:434-435`: 0 is upstream's own `?? 0`, unreachable here because the
        // list is known non-empty.
        final xMin = d3.min<double>(xs) ?? 0;
        final xMax = d3.max<double>(xs) ?? 0;
        // `:436-439`. The computed keys coerce with `String()`, and an x field
        // equal to the y field leaves only the y value — as the object literal
        // does.
        result = <Map<String, Object?>>[
          <String, Object?>{
            jsToString(xField): xMin,
            jsToString(yField): slope * xMin + intercept,
          },
          <String, Object?>{
            jsToString(xField): xMax,
            jsToString(yField): slope * xMax + intercept,
          },
        ];
      }
    }

    // `:444-458`: loess — a moving average that keeps one row per input row and
    // DROPS every column other than the two it names.
    if (transform.containsKey('loess') && transform.containsKey('on')) {
      final yField = transform['loess'];
      final xField = transform['on'];
      final xKey = jsToString(xField);
      final yKey = jsToString(yField);
      // `:447-449`: filter, then sort ascending by x. The comparator returns 0
      // for a tie, so the sort must be stable.
      final sorted = stableSort(
        <Map<String, Object?>>[
          for (final row in result)
            if (!jsToNumber(_read(row, xField)).isNaN &&
                !jsToNumber(_read(row, yField)).isNaN)
              row,
        ],
        (a, b) {
          final delta =
              jsToNumber(_read(a, xField)) - jsToNumber(_read(b, xField));
          // -1 and 1 are the sign of upstream's own subtraction (`:449`), which
          // Dart's comparator requires as an int.
          if (delta == 0) {
            return 0;
          }
          return delta < 0 ? -1 : 1;
        },
      );
      // `VegaLiteSchemaAdapter.ts:450`: windowSize = max(3, floor(n / 4));
      // `:452-453`: start = max(0, i - floor(w / 2)) and end = min(n, start + w),
      // so the window is asymmetric at both tails rather than centred.
      final windowSize = math.max(3, sorted.length ~/ 4);
      final smoothed = <Map<String, Object?>>[];
      for (var i = 0; i < sorted.length; i++) {
        final start = math.max(0, i - windowSize ~/ 2);
        final end = math.min(sorted.length, start + windowSize);
        final windowY = <double>[
          for (final row in sorted.getRange(start, end))
            jsToNumber(_read(row, yField)),
        ];
        // `:455`: the `??` falls back to this row's own y, which the filter at
        // `:448` has already proved is a number.
        final avgY = d3.mean(windowY) ?? jsToNumber(_read(sorted[i], yField));
        smoothed.add(<String, Object?>{xKey: sorted[i][xKey], yKey: avgY});
      }
      result = smoothed;
    }

    // `:461-496`: density — replaces the dataset with a sampled kernel estimate.
    if (transform.containsKey('density')) {
      final field = transform['density'];
      final groupby = _stringList(transform['groupby']);
      // `:467` uses the `'__all__'` fallback, and `:483` re-finds the sample row
      // by scanning for the first row of the group — which is `group.first`.
      final groups = _group(result, groupby, useAllFallback: true);
      final densityResult = <Map<String, Object?>>[];
      for (final group in groups.values) {
        // `:471` pushes `Number(row[field])` WITHOUT filtering, so a NaN still
        // counts towards `values.length` in the denominator at `:491`.
        final values = <double>[
          for (final row in group) jsToNumber(_read(row, field)),
        ];
        // `:476-477`: 0 is upstream's own `?? 0`, reached when every value is
        // NaN.
        final minValue = d3.min<double>(values) ?? 0;
        final maxValue = d3.max<double>(values) ?? 0;
        final span = maxValue - minValue;
        // `:478`: `|| 1`, so a zero-width (or NaN) range becomes 1.
        final range = span == 0 || span.isNaN ? 1.0 : span;
        // `VegaLiteSchemaAdapter.ts:479-492`. bins is 20 and the loop runs
        // i <= bins, so 21 points are emitted. The count uses a STRICT
        // |v - x| < bandwidth.
        const bins = 20;
        final bandwidth = range / bins;
        // `:481-487`: the group columns come from the first row of the group,
        // and are spread LAST at `:492` — so a group field named `value` or
        // `density` overwrites the estimate.
        final groupFields = <String, Object?>{
          for (final field in groupby) field: group.first[field],
        };
        for (var i = 0; i <= bins; i++) {
          final x = minValue + (i / bins) * range;
          var count = 0;
          for (final value in values) {
            if ((value - x).abs() < bandwidth) {
              count++;
            }
          }
          densityResult.add(<String, Object?>{
            'value': x,
            'density': count / (values.length * bandwidth),
            ...groupFields,
          });
        }
      }
      result = densityResult;
    }

    // `:499-512`: quantile — replaces the dataset with one row per probability.
    if (transform.containsKey('quantile')) {
      final field = transform['quantile'];
      final probsRaw = transform['probs'];
      // `:501`: `||`, so an absent `probs` takes the quartiles. A `probs` that
      // is present but not an array throws at upstream's `.map`; it is skipped
      // to the defaults here rather than crashing the whole chart.
      // // parity: VegaLiteSchemaAdapter.ts:501
      final probs = probsRaw is List<Object?>
          ? probsRaw
          : const <Object?>[0.25, 0.5, 0.75];
      final values = <double>[
        for (final row in result)
          if (!jsToNumber(_read(row, field)).isNaN)
            jsToNumber(_read(row, field)),
      ]..sort();
      if (values.isNotEmpty) {
        result = <Map<String, Object?>>[
          for (final prob in probs)
            <String, Object?>{
              // `:509`: the RAW probability is stringified, so an integer 1
              // renders as '1' and not '1.0'.
              'prob': jsToString(prob),
              'value': values[_quantileIndex(jsToNumber(prob), values.length)],
            },
        ];
      }
    }

    // `:515-535`: impute — adds a row for every integer key between the
    // smallest and the largest one present.
    if (transform.containsKey('impute') && transform.containsKey('key')) {
      final field = transform['impute'];
      final keyField = transform['key'];
      final keyName = jsToString(keyField);
      // `:518-519`: `||` on the method, `??` on the fill value — so an explicit
      // null value still becomes 0, and 0 is upstream's own default.
      final method = transform['method'] is String && transform['method'] != ''
          ? transform['method']
          : 'value';
      final fillValue = transform['value'] ?? 0;

      // `:521`: the RAW cell values, so a string '1' never matches the numeric
      // key 1 the loop walks.
      final existingKeys = <Object?>{for (final row in result) row[keyName]};
      final allKeyValues = <double>[
        for (final row in result)
          if (!jsToNumber(_read(row, keyField)).isNaN)
            jsToNumber(_read(row, keyField)),
      ];
      if (allKeyValues.isNotEmpty) {
        // `:524-525`: 0 is upstream's own `?? 0`, unreachable for a non-empty
        // list.
        final minKey = d3.min<double>(allKeyValues) ?? 0;
        final maxKey = d3.max<double>(allKeyValues) ?? 0;
        // `:526-532`. Upstream `push`es onto `result`, which on the first
        // transform is the caller's own array — mutating the input. A fresh
        // list is built instead; the returned data is identical.
        // // parity: VegaLiteSchemaAdapter.ts:530
        final imputed = <Map<String, Object?>>[...result];
        // 1 is upstream's own `k++` step (`:526`), which starts at a possibly
        // fractional minKey.
        for (var k = minKey; k <= maxKey; k += 1) {
          if (!existingKeys.contains(k)) {
            imputed.add(<String, Object?>{
              keyName: k,
              // `:529`: 0 for any method other than 'value'.
              jsToString(field): method == 'value' ? fillValue : 0,
            });
          }
        }
        // `:533`: ties keep their insertion order, so the sort must be stable.
        result = stableSort(imputed, (a, b) {
          final delta =
              jsToNumber(_read(a, keyField)) - jsToNumber(_read(b, keyField));
          // As in the loess comparator: the sign of upstream's subtraction.
          if (delta == 0 || delta.isNaN) {
            return 0;
          }
          return delta < 0 ? -1 : 1;
        });
      }
    }

    // `:538-562`: lookup — a left join against an inline dataset.
    final fromSpec = transform['from'];
    if (transform.containsKey('lookup') && fromSpec is Map<String, Object?>) {
      final lookupField = transform['lookup'];
      final fromData = fromSpec['data'];
      final fromValues = fromData is Map<String, Object?>
          ? fromData['values']
          : null;
      final fromKey = fromSpec['key'];
      final fromFields = fromSpec['fields'];
      // `:545`: a truthiness test, so an EMPTY values or fields array passes
      // while an empty `key` string does not.
      if (fromValues is List<Object?> &&
          fromKey is String &&
          fromKey.isNotEmpty &&
          fromFields is List<Object?>) {
        final lookupMap = <String, Map<String, Object?>>{};
        for (final row in fromValues) {
          if (row is Map<String, Object?>) {
            // `:548`: a later duplicate key overwrites an earlier one.
            lookupMap[jsToString(_read(row, fromKey))] = row;
          }
        }
        result = <Map<String, Object?>>[
          for (final row in result)
            if (lookupMap[jsToString(_read(row, lookupField))]
                case final lookupRow?)
              <String, Object?>{
                ...row,
                // `:553-556`: only the listed fields are copied, and the spread
                // at `:557` puts them AFTER the row — so a listed field the
                // lookup row lacks blanks the row's own value.
                for (final f in fromFields)
                  jsToString(f): lookupRow[jsToString(f)],
              }
            else
              // `:559`: an unmatched row passes through untouched.
              row,
        ];
      }
    }
  }

  return result;
}

/// `row[field]` with JavaScript's missing-property semantics
/// (`VegaLiteSchemaAdapter.ts:424`, `:448`, `:471`, `:503`, `:522`, `:551`).
///
/// A computed property name coerces with `String()`, and an ABSENT property is
/// `undefined` rather than `null` — which matters because `Number(undefined)`
/// is NaN whereas `Number(null)` is 0. Every numeric transform here filters on
/// NaN, so conflating the two would silently admit missing cells as zeroes.
Object? _read(Map<String, Object?> row, Object? field) {
  final key = jsToString(field);
  return row.containsKey(key) ? row[key] : JsUndefined.instance;
}

/// `VegaLiteSchemaAdapter.ts:508`: nearest rank, not interpolated.
///
/// `Math.floor(p * len)` is clamped rather than indexed raw: for a probability
/// outside `[0, 1]` — or a non-finite one — JavaScript reads past the array and
/// gets `undefined`, whereas Dart would throw. 0 is the lower bound the clamp
/// restores. // parity: VegaLiteSchemaAdapter.ts:508
int _quantileIndex(double p, int length) {
  final scaled = p * length;
  return scaled.isFinite ? scaled.floor().clamp(0, length - 1) : 0;
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
