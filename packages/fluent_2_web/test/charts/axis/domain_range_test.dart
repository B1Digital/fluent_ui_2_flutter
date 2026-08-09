import 'package:fluent_2_web/src/charts/axis/domain_range.dart';
import 'package:fluent_2_web/src/charts/model/bar_data.dart';
import 'package:fluent_2_web/src/charts/model/cartesian_series.dart';
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:flutter_test/flutter_test.dart';

FluentLineChartSeries _series(String legend, List<(Object, double)> points) {
  return FluentLineChartSeries(
    legend: legend,
    data: <Object>[
      for (final (x, y) in points) FluentLineChartDataPoint(x: x, y: y),
    ],
  );
}

void main() {
  group('isValidDomainValue', () {
    test('accepts every non-number regardless of scale', () {
      expect(
        isValidDomainValue(DateTime.utc(2020), FluentAxisScaleType.log),
        isTrue,
        reason:
            'utilities.ts:2274 filters only numbers, so dates pass on a log scale.',
      );
    });

    test('accepts any number on a non-log scale', () {
      expect(
        isValidDomainValue(-5, FluentAxisScaleType.auto),
        isTrue,
        reason: "utilities.ts:2274 — scaleType !== 'log' short-circuits.",
      );
    });

    test('rejects a non-positive number on a log scale', () {
      expect(
        isValidDomainValue(0, FluentAxisScaleType.log),
        isFalse,
        reason: 'utilities.ts:2274 requires value > 0 on a log scale.',
      );
    });
  });

  group('getScatterXDomainExtent', () {
    test('takes the extent across every series', () {
      final extent = getScatterXDomainExtent(<Object>[
        _series('a', <(Object, double)>[(1, 10), (5, 20)]),
        _series('b', <(Object, double)>[(3, 30), (9, 40)]),
      ]);
      expect(
        extent.$1,
        1,
        reason: 'utilities.ts:2289-2291 nests d3Min over series then points.',
      );
      expect(
        extent.$2,
        9,
        reason: 'utilities.ts:2293-2297 nests d3Max the same way.',
      );
    });

    test('filters non-positive values on a log scale', () {
      final extent = getScatterXDomainExtent(<Object>[
        _series('a', <(Object, double)>[(0, 10), (4, 20)]),
      ], scaleType: FluentAxisScaleType.log);
      expect(
        extent.$1,
        4,
        reason:
            'utilities.ts:2286-2287 applies isValidDomainValue before the extent.',
      );
    });

    test('returns nulls when every point is filtered out', () {
      final extent = getScatterXDomainExtent(<Object>[
        _series('a', <(Object, double)>[(-1, 10)]),
      ], scaleType: FluentAxisScaleType.log);
      expect(
        extent.$1,
        isNull,
        reason:
            'upstream asserts non-null with `!` and lets NaN flow downstream; the '
            'port surfaces the null rather than throwing.',
      );
    });
  });

  group('getDomainPaddingForMarkers', () {
    test('pads both ends by a tenth of the range', () {
      final padding = getDomainPaddingForMarkers(0, 100);
      expect(
        padding.start,
        10,
        reason: 'utilities.ts:2251 — (max - min) * 0.1.',
      );
      expect(padding.end, 10, reason: 'the same value on both sides.');
    });

    test('suppresses the padding when the user bound is already close', () {
      final padding = getDomainPaddingForMarkers(0, 100, userMinVal: -5);
      expect(
        padding.start,
        0,
        reason:
            'utilities.ts:2254-2255 — the user floor is 5 below the data and the '
            'padding is 10, so 10 > 5 counts as already satisfied.',
      );
    });

    test('keeps the padding when the user bound is far away', () {
      final padding = getDomainPaddingForMarkers(0, 100, userMinVal: -50);
      expect(
        padding.start,
        10,
        reason: 'utilities.ts:2254 — 10 > 50 is false, so the padding stays.',
      );
    });

    test('takes the asymmetric log branch', () {
      final padding = getDomainPaddingForMarkers(
        2,
        200,
        scaleType: FluentAxisScaleType.log,
      );
      expect(padding.start, 1, reason: 'utilities.ts:2241 — minVal * 0.5.');
      expect(
        padding.end,
        200,
        reason:
            'utilities.ts:2242 returns the raw maximum as the end padding, not a '
            'delta. Odd, and ported as written.',
      );
    });
  });

  group('groupChartDataByYValue', () {
    test('keeps string keys in insertion order', () {
      final grouped = groupChartDataByYValue(<Object>[
        const FluentHorizontalBarChartWithAxisDataPoint(x: 1, y: 'beta'),
        const FluentHorizontalBarChartWithAxisDataPoint(x: 2, y: 'alpha'),
        const FluentHorizontalBarChartWithAxisDataPoint(x: 3, y: 'beta'),
      ]);
      expect(
        grouped.keys.toList(),
        <String>['beta', 'alpha'],
        reason:
            'utilities.ts:1398 returns Object.values, and JS enumerates string '
            'keys in insertion order.',
      );
      expect(
        grouped['beta']!.length,
        2,
        reason: 'two points share the y value beta.',
      );
    });

    test('sorts integer-like keys ascending, ahead of string keys', () {
      final grouped = groupChartDataByYValue(<Object>[
        const FluentHorizontalBarChartWithAxisDataPoint(x: 1, y: 'zeta'),
        const FluentHorizontalBarChartWithAxisDataPoint(x: 2, y: 10),
        const FluentHorizontalBarChartWithAxisDataPoint(x: 3, y: 2),
      ]);
      expect(
        grouped.keys.toList(),
        <String>['2', '10', 'zeta'],
        reason:
            'JS object enumeration puts integer-like keys first, in ascending '
            'numeric order, then the rest in insertion order. That ordering '
            'leaks into Object.values and therefore into the bar order.',
      );
    });

    test('keys a whole double the way JavaScript does', () {
      final grouped = groupChartDataByYValue(<Object>[
        const FluentHorizontalBarChartWithAxisDataPoint(x: 1, y: 'zeta'),
        const FluentHorizontalBarChartWithAxisDataPoint(x: 2, y: 2.0),
      ]);
      expect(
        grouped.keys.toList(),
        <String>['2', 'zeta'],
        reason:
            'utilities.ts:1389 uses the y value as an object key, so JS stringifies '
            '2.0 as "2" — which then counts as an array index and enumerates '
            "first. Dart's own 2.0.toString() would give \"2.0\" and lose both.",
      );
    });
  });

  group('computeLongestBars', () {
    test('totals positives and negatives separately per group', () {
      final grouped = groupChartDataByYValue(<Object>[
        const FluentHorizontalBarChartWithAxisDataPoint(x: 3, y: 'a'),
        const FluentHorizontalBarChartWithAxisDataPoint(x: -1, y: 'a'),
        const FluentHorizontalBarChartWithAxisDataPoint(x: 5, y: 'b'),
      ]);
      final bars = computeLongestBars(grouped, 0);
      expect(
        bars.$1,
        5,
        reason:
            'utilities.ts:1418-1421 totals the positives per group and '
            'utilities.ts:1427 keeps the largest across groups.',
      );
      expect(
        bars.$2,
        -1,
        reason:
            'utilities.ts:1422-1425 totals the negatives per group and '
            'utilities.ts:1428 keeps the smallest across groups.',
      );
    });

    test('seeds every total at the x origin', () {
      final grouped = groupChartDataByYValue(<Object>[
        const FluentHorizontalBarChartWithAxisDataPoint(x: 2, y: 'a'),
      ]);
      final bars = computeLongestBars(grouped, 10);
      expect(
        bars.$1,
        12,
        reason: 'utilities.ts:1420 passes X_ORIGIN as the reduce seed.',
      );
    });

    test('never returns a positive below zero or a negative above zero', () {
      final bars = computeLongestBars(<String, List<Object>>{}, 0);
      expect(
        bars.$1,
        0,
        reason: 'utilities.ts:1414 seeds longestPositiveBar at 0.',
      );
      expect(
        bars.$2,
        0,
        reason: 'utilities.ts:1415 seeds longestNegativeBar at 0.',
      );
    });
  });
}
