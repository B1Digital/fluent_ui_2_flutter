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
}
