import 'dart:ui';

import 'package:fluent_2_web/src/charts/model/bar_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentChartXYPoint', () {
    test('takes a numeric or a category x only', () {
      const numeric = FluentChartXYPoint(x: 1, y: 2);
      const category = FluentChartXYPoint(x: 'Jan', y: 2);
      expect(numeric.x, 1, reason: 'types/DataPoint.ts:64 `number | string`.');
      expect(category.x, 'Jan', reason: 'types/DataPoint.ts:64 string arm.');
      expect(
        () => FluentChartXYPoint(x: DateTime(2024), y: 2),
        throwsA(isA<AssertionError>()),
        reason:
            'types/DataPoint.ts:64 excludes Date; the stacked variant at :82-90 '
            'is the one that widens it.',
      );
    });
  });

  group('FluentVerticalStackedBarDataPoint', () {
    test('widens x to admit a DateTime', () {
      final dated = FluentVerticalStackedBarDataPoint(
        x: DateTime.utc(2024),
        y: 2,
      );
      expect(
        dated.x,
        DateTime.utc(2024),
        reason:
            'types/DataPoint.ts:82-90 overrides DataPoint.x to '
            '`number | string | Date`.',
      );
    });
  });

  group('FluentChartDataPoint', () {
    test('is the donut and horizontal-bar datum, with everything optional', () {
      const point = FluentChartDataPoint();
      expect(point.legend, isNull, reason: 'types/DataPoint.ts:116 optional.');
      expect(point.data, isNull, reason: 'types/DataPoint.ts:121 optional.');
      expect(point.color, isNull, reason: 'types/DataPoint.ts:134 optional.');
      expect(
        point.placeHolder,
        isFalse,
        reason: 'types/DataPoint.ts:139 is optional, so absent means false.',
      );
    });
    test('carries the single-bar total separately from the bar value', () {
      const point = FluentChartDataPoint(
        legend: 'Used',
        data: 40,
        horizontalBarChartData: FluentHorizontalDataPoint(x: 40, total: 100),
      );
      expect(point.data, 40, reason: 'types/DataPoint.ts:121.');
      expect(
        point.horizontalBarChartData!.total,
        100,
        reason: 'types/DataPoint.ts:105 total on HorizontalDataPoint.',
      );
    });
  });

  group('FluentVerticalBarChartDataPoint', () {
    test('accepts all three x types and carries an optional line datum', () {
      const point = FluentVerticalBarChartDataPoint(
        x: 'Jan',
        y: 12,
        legend: 'Sales',
        barLabel: '12',
        lineData: FluentBarLineDatum(y: 30),
      );
      expect(point.x, 'Jan', reason: 'types/DataPoint.ts:170.');
      expect(point.barLabel, '12', reason: 'types/DataPoint.ts:218.');
      expect(point.lineData!.y, 30, reason: 'types/DataPoint.ts:200 lineData.');
      expect(
        point.lineData!.useSecondaryYScale,
        isFalse,
        reason: 'types/DataPoint.ts:290 documents "False by default".',
      );
    });
    test('rejects an x that is none of the three types', () {
      expect(
        () => FluentVerticalBarChartDataPoint(x: const <int>[], y: 1),
        throwsA(isA<AssertionError>()),
        reason: 'types/DataPoint.ts:170 `number | string | Date`.',
      );
    });
    test('takes a colour', () {
      const point = FluentVerticalBarChartDataPoint(
        x: 1,
        y: 2,
        color: Color(0xFF13A10E),
      );
      expect(
        point.color!.toARGB32(),
        0xFF13A10E,
        reason: 'types/DataPoint.ts:180.',
      );
    });
  });

  group('FluentHorizontalBarChartWithAxisDataPoint', () {
    test('inverts the usual roles: x is dependent, y is independent', () {
      const point = FluentHorizontalBarChartWithAxisDataPoint(x: 42, y: 'Jan');
      expect(
        point.x,
        42,
        reason:
            'types/DataPoint.ts:228 — "Dependent value of the data point, '
            'rendered along the x-axis".',
      );
      expect(
        point.y,
        'Jan',
        reason: 'types/DataPoint.ts:235 — the independent value.',
      );
    });
    test('rejects a DateTime y', () {
      expect(
        () =>
            FluentHorizontalBarChartWithAxisDataPoint(x: 1, y: DateTime(2024)),
        throwsA(isA<AssertionError>()),
        reason:
            'types/DataPoint.ts:235 is `number | string`, with no Date arm.',
      );
    });
  });

  group('FluentStackedBarDatum', () {
    test('keeps data as an Object because a String changes the y scale', () {
      const numeric = FluentStackedBarDatum(data: 12, legend: 'A');
      const categorical = FluentStackedBarDatum(data: 'High', legend: 'A');
      expect(
        numeric.data,
        12,
        reason:
            'VerticalStackedBarChart.tsx:1068 uses a number as a linear height.',
      );
      expect(
        categorical.data,
        'High',
        reason:
            'VerticalStackedBarChart.tsx:1012 and :1060 turn a string into a '
            'band scale on the y axis.',
      );
    });
    test('admits the empty string, which means "no bar"', () {
      const blank = FluentStackedBarDatum(data: '', legend: 'A');
      expect(
        blank.data,
        '',
        reason: "VerticalStackedBarChart.tsx:1008-1009 treats '' as no bar.",
      );
    });
    test('rejects anything that is neither a num nor a String', () {
      expect(
        () => FluentStackedBarDatum(data: DateTime(2024), legend: 'A'),
        throwsA(isA<AssertionError>()),
        reason: 'types/DataPoint.ts:612 — `number | string`.',
      );
    });
  });

  group('FluentStackedBarLineDatum', () {
    test('resolvedData prefers data and falls back to y', () {
      const withData = FluentStackedBarLineDatum(
        y: 5,
        color: Color(0xFF13A10E),
        legend: 'Target',
        data: 9,
      );
      const withoutData = FluentStackedBarLineDatum(
        y: 5,
        color: Color(0xFF13A10E),
        legend: 'Target',
      );
      expect(
        withData.resolvedData,
        9,
        reason:
            'VerticalStackedBarChart.tsx:276 `item.data = item.data || item.y`.',
      );
      expect(
        withoutData.resolvedData,
        5,
        reason: 'The `|| item.y` arm of VerticalStackedBarChart.tsx:276.',
      );
    });
    test('a data of 0 falls through to y, reproducing the falsy check', () {
      const zero = FluentStackedBarLineDatum(
        y: 5,
        color: Color(0xFF13A10E),
        legend: 'Target',
        data: 0,
      );
      expect(
        zero.resolvedData,
        5,
        reason:
            '// parity: VerticalStackedBarChart.tsx:276 uses `||`, so a '
            'legitimate 0 is swallowed by the fallback.',
      );
    });
  });

  group('FluentVerticalStackedBarGroup', () {
    test('bundles a stack with its x and its optional lines', () {
      const group = FluentVerticalStackedBarGroup(
        chartData: <FluentStackedBarDatum>[
          FluentStackedBarDatum(data: 3, legend: 'A'),
          FluentStackedBarDatum(data: 4, legend: 'B'),
        ],
        xAxisPoint: 'Jan',
        lineData: <FluentStackedBarLineDatum>[
          FluentStackedBarLineDatum(
            y: 9,
            color: Color(0xFFCA5010),
            legend: 'T',
          ),
        ],
      );
      expect(group.chartData.length, 2, reason: 'types/DataPoint.ts:660.');
      expect(group.xAxisPoint, 'Jan', reason: 'types/DataPoint.ts:665.');
      expect(group.lineData!.length, 1, reason: 'types/DataPoint.ts:676.');
    });
  });
}
