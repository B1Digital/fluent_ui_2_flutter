import 'package:fluent_2_web/src/charts/axis/domain_range.dart';
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
}
