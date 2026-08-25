import 'dart:ui';

import 'package:fluent_2/src/charts/chrome/legend_shape.dart';
import 'package:fluent_2/src/charts/model/cartesian_series.dart';
import 'package:fluent_2/src/charts/model/line_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentLineChartDataPoint', () {
    test('accepts a num x and a DateTime x', () {
      const numeric = FluentLineChartDataPoint(x: 3, y: 10);
      final dated = FluentLineChartDataPoint(x: DateTime.utc(2024), y: 10);
      expect(numeric.x, 3, reason: 'types/DataPoint.ts:340 `number | Date`.');
      expect(
        dated.x,
        DateTime.utc(2024),
        reason: 'types/DataPoint.ts:340 Date arm.',
      );
    });

    test('rejects a String x, unlike every other chart datum', () {
      // The plan spelt this `const`, but an assert inside a `const`
      // constructor is evaluated during constant evaluation, so a const
      // invocation is a compile-time error rather than a catchable throw. The
      // non-const invocation is what makes the assertion observable.
      expect(
        () => FluentLineChartDataPoint(x: 'Jan', y: 10),
        throwsA(isA<AssertionError>()),
        reason:
            'LineChartDataPoint is the one x that excludes a string '
            '(types/DataPoint.ts:340 against ScatterChartDataPoint :366).',
      );
    });

    test('splits yAxisCalloutData into text and breakdown', () {
      const point = FluentLineChartDataPoint(
        x: 1,
        y: 2,
        yAxisCalloutBreakdown: <String, double>{'a': 1, 'b': 1},
      );
      expect(
        point.yAxisCalloutBreakdown!.length,
        2,
        reason: 'The `{[id]: number}` arm of types/DataPoint.ts:310.',
      );
      expect(point.yAxisCalloutText, isNull, reason: 'The other arm is unset.');
    });

    test('defaults hideCallout to false', () {
      const point = FluentLineChartDataPoint(x: 1, y: 2);
      expect(
        point.hideCallout,
        isFalse,
        reason:
            'types/DataPoint.ts:315 is optional and utilities.ts:1017 filters '
            'on `!point.hideCallout`, so absent means shown.',
      );
    });
  });

  group('FluentScatterChartDataPoint', () {
    test('accepts a String x, which the line point does not', () {
      const point = FluentScatterChartDataPoint(x: 'Jan', y: 1);
      expect(
        point.x,
        'Jan',
        reason: 'types/DataPoint.ts:366 `number | Date | string`.',
      );
    });
  });

  group('FluentLineChartSeries', () {
    test('defaults hideInactiveDots and useSecondaryYScale to false', () {
      const series = FluentLineChartSeries(legend: 'A', data: <Object>[]);
      expect(
        series.hideInactiveDots,
        isFalse,
        reason: 'types/DataPoint.ts:515 hideNonActiveDots is optional.',
      );
      expect(
        series.useSecondaryYScale,
        isFalse,
        reason: 'types/DataPoint.ts:532 documents "False by default".',
      );
    });

    test('collapses onLegendClick to a list of selected legends', () {
      var received = const <String>['sentinel'];
      final series = FluentLineChartSeries(
        legend: 'A',
        data: const <Object>[],
        onLegendClick: (selected) => received = selected,
      );
      series.onLegendClick!(const <String>[]);
      expect(
        received,
        isEmpty,
        reason:
            'types/DataPoint.ts:520 is `string | null | string[]`; the empty '
            'list is the Dart spelling of the null arm. Recorded divergence.',
      );
    });

    test('carries a legend shape and line options', () {
      const series = FluentLineChartSeries(
        legend: 'A',
        data: <Object>[],
        legendShape: FluentChartLegendShape.diamond,
        lineOptions: FluentLineOptions(strokeWidth: 4),
        color: Color(0xFF4F6BED),
      );
      expect(
        series.legendShape,
        FluentChartLegendShape.diamond,
        reason: 'types/DataPoint.ts:487.',
      );
      expect(
        series.lineOptions!.strokeWidth,
        4,
        reason: 'LineChart falls back to 4 when the series names nothing.',
      );
      expect(
        series.color!.toARGB32(),
        0xFF4F6BED,
        reason: 'types/DataPoint.ts:502.',
      );
    });
  });

  group('FluentLineChartGap', () {
    test('is a half-open index pair', () {
      const gap = FluentLineChartGap(startIndex: 2, endIndex: 5);
      expect(gap.startIndex, 2, reason: 'types/DataPoint.ts:396.');
      expect(gap.endIndex, 5, reason: 'types/DataPoint.ts:401.');
    });
  });

  group('FluentChartData', () {
    test('defaults markerRadius to null so the chart applies 8', () {
      const data = FluentChartData();
      expect(
        data.markerRadius,
        isNull,
        reason:
            'AreaChart.tsx:749 is `pointOptions && pointOptions.r ? Number(...) '
            ': 8`, so the fallback belongs to the chart, not to the bundle.',
      );
    });
    test('holds each series list independently', () {
      const data = FluentChartData(
        chartTitle: 'Revenue',
        lineChartData: <FluentLineChartSeries>[
          FluentLineChartSeries(legend: 'A', data: <Object>[]),
        ],
      );
      expect(data.chartTitle, 'Revenue', reason: 'types/DataPoint.ts:543.');
      expect(data.lineChartData!.length, 1, reason: 'types/DataPoint.ts:562.');
      expect(data.scatterChartData, isNull, reason: 'types/DataPoint.ts:567.');
      expect(data.sankeyData, isNull, reason: 'types/DataPoint.ts:572.');
    });
  });
}
