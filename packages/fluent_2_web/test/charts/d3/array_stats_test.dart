import 'package:fluent_2_web/src/charts/internal/d3/array_stats.dart' as d3;
import 'package:flutter_test/flutter_test.dart';

import 'golden_support.dart';

void main() {
  test('min and max return null on empty and skip null and NaN', () {
    expect(
      d3.min<num>(<Object?>[]),
      isNull,
      reason:
          'min.js:19 returns undefined; 32 upstream call sites use TS "!" '
          'and let the NaN propagate rather than throwing',
    );
    expect(
      d3.max<num>(<Object?>[null, 3, double.nan, 1]),
      3,
      reason: 'max.js:5-7 skips null, and `value >= value` rejects NaN',
    );
    expect(
      d3.min<num>(<Object?>[null, 3, double.nan, 1]),
      1,
      reason: 'min.js:5-7',
    );
  });

  test('extent returns a pair and both halves are null on empty', () {
    expect(
      d3.extent<num>(<Object?>[]),
      (null, null),
      reason: 'extent.js:28 returns [undefined, undefined]',
    );
    expect(d3.extent<num>(<Object?>[5, -2, 9]), (
      -2,
      9,
    ), reason: 'extent.js:10-11');
  });

  test('sum skips every falsy coerced value, including a legitimate 0', () {
    expect(
      d3.sum(<Object?>[1, 0, 2]),
      3.0,
      reason:
          'sum.js:5 is `if (value = +value)` — a zero is falsy and is '
          'skipped, which is indistinguishable from adding it, but a NaN is '
          'skipped too and that is not',
    );
    expect(
      d3.sum(<Object?>[1, double.nan, 2]),
      3.0,
      reason: 'sum.js:5 skips NaN, so the result is never NaN',
    );
    expect(d3.sum(<Object?>[]), 0.0, reason: 'sum.js:2 seeds with 0');
  });

  test('mean and median return null on empty', () {
    expect(d3.mean(<Object?>[]), isNull, reason: 'mean.js:18, `if (count)`');
    expect(d3.mean(<Object?>[1, 2, 4]), closeTo(7 / 3, 1e-15), reason: 'mean');
    expect(d3.median(<Object?>[3, 1, 2]), 2.0, reason: 'quantile(values, 0.5)');
    expect(
      d3.median(<Object?>[4, 1, 2, 3]),
      2.5,
      reason: 'R-7 interpolates between the two middles (quantile.js:20)',
    );
  });

  test('quantile uses R-7 interpolation over an already-sorted list', () {
    expect(
      d3.quantile(<double>[1, 2, 3, 4], 0.25),
      1.75,
      reason: 'quantile.js:16-20: i = 0.75, value0 = 1, value1 = 2',
    );
    expect(d3.quantile(<double>[], 0.5), isNull, reason: 'quantile.js:12');
    expect(d3.quantile(<double>[7], 0.9), 7.0, reason: 'quantile.js:13, n < 2');
  });

  test('range', () {
    expect(d3.range(0, 5), <double>[0, 1, 2, 3, 4], reason: 'range.js:8-10');
    expect(d3.range(5, 0, -1), <double>[
      5,
      4,
      3,
      2,
      1,
    ], reason: 'range.js:5 ceils (stop - start) / step');
    expect(d3.range(0, 0), isEmpty, reason: 'range.js:5 clamps n at 0');
  });

  test('ascending puts an incomparable value last', () {
    expect(d3.ascending(1, 2), -1, reason: 'ascending.js:2');
    expect(d3.ascending(2, 2), 0, reason: 'ascending.js:2');
    expect(
      d3.ascending(null, 2),
      0,
      reason:
          'ascending.js:2 returns NaN there, and Dart comparators must '
          'return an int; NaN is treated as 0 by V8 sort, so 0 it is',
    );
  });

  test('Bisector.left returns hi immediately for an incomparable needle', () {
    final b = d3.bisector<num>((num d) => d);
    expect(
      b.left(<num>[1, 2, 3, 4, 5], double.nan),
      5,
      reason: 'bisector.js:24 short-circuits when compare1(x, x) != 0',
    );
    expect(b.left(<num>[1, 2, 3, 4, 5], 3), 2, reason: 'bisector.js:22-32');
    expect(b.right(<num>[1, 2, 3, 4, 5], 3), 3, reason: 'bisector.js:34-44');
    expect(
      b.center(<num>[1, 2, 3, 4, 5], 2.4),
      1,
      reason: 'bisector.js:46-49 picks the nearer neighbour',
    );
  });

  test('against the d3 golden corpus', () async {
    final corpus = await loadD3Golden();
    for (final c in goldenCases(corpus, 'arrayStats')) {
      if (c.containsKey('values')) {
        final values = (c['values']! as List<Object?>)
            .map((Object? v) => v is String && v != 'NaN' ? v : jsNum(v))
            .toList();
        final numeric = values.whereType<double>().toList();
        if (numeric.length == values.length) {
          expect(d3.sum(values), closeToJs(c['sum']), reason: 'sum $values');
          expect(d3.mean(values), closeToJs(c['mean']), reason: 'mean $values');
          expect(
            d3.median(values),
            closeToJs(c['median']),
            reason: 'median $values',
          );
        }
      }
      if (c.containsKey('range')) {
        final args = jsNums(c['range']);
        expect(
          d3.range(args[0]!, args[1]!, args[2]!),
          orderedEquals(jsNums(c['out']).cast<double>()),
          reason: 'range(${args[0]}, ${args[1]}, ${args[2]})',
        );
      }
      if (c.containsKey('bisect')) {
        final array = jsNums(c['bisect']).cast<double>();
        final needles = <double>[0, 1, 2.5, 5, 6, double.nan];
        final b = d3.bisector<double>((double d) => d);
        final left = (c['left']! as List<Object?>).cast<int>();
        for (var i = 0; i < left.length; i++) {
          expect(
            b.left(array, needles[i]),
            left[i],
            reason: 'bisector.left($array, ${needles[i]})',
          );
        }
      }
    }
  });
}
