import 'dart:ui';

import 'package:fluent_2_web/src/charts/chrome/legend_shape.dart';
import 'package:fluent_2_web/src/charts/model/callout_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const blue = Color(0xFF4F6BED);

  group('FluentCustomizedCalloutDataPoint', () {
    test('splits the yAxisCalloutData union into two fields', () {
      const text = FluentCustomizedCalloutDataPoint(
        legend: 'Sales',
        y: 12,
        color: blue,
        yAxisCalloutText: '12 units',
      );
      const breakdown = FluentCustomizedCalloutDataPoint(
        legend: 'Sales',
        y: 12,
        color: blue,
        yAxisCalloutBreakdown: <String, double>{'EMEA': 7, 'APAC': 5},
      );
      expect(
        text.yAxisCalloutText,
        '12 units',
        reason: 'The `string` arm of types/DataPoint.ts:310.',
      );
      expect(
        text.yAxisCalloutBreakdown,
        isNull,
        reason: 'The two arms are mutually exclusive upstream.',
      );
      expect(
        breakdown.yAxisCalloutBreakdown!['EMEA'],
        7,
        reason: 'The `{[id]: number}` arm of types/DataPoint.ts:310.',
      );
    });

    test('carries the series index the popover swatch is gated on', () {
      const point = FluentCustomizedCalloutDataPoint(
        legend: 'Sales',
        y: 12,
        color: blue,
        index: 3,
      );
      expect(
        point.index,
        3,
        reason:
            'utilities.ts:1053 copies `index` into every callout point and '
            'ChartPopover.tsx:188 gates the shape swatch on it being neither '
            'undefined nor -1.',
      );
    });

    test('defaults the index to null, which suppresses the swatch', () {
      const point = FluentCustomizedCalloutDataPoint(
        legend: 'Sales',
        y: 12,
        color: blue,
      );
      expect(
        point.index,
        isNull,
        reason:
            'ChartPopover.tsx:188 `xValue.index !== undefined` — a series with '
            'no index draws no swatch.',
      );
    });
  });

  group('FluentCustomizedCalloutData', () {
    test('holds a heterogeneous x alongside its stack of values', () {
      final data = FluentCustomizedCalloutData(
        x: DateTime.utc(2024, 3, 5),
        values: const <FluentCustomizedCalloutDataPoint>[
          FluentCustomizedCalloutDataPoint(legend: 'A', y: 1, color: blue),
        ],
      );
      expect(
        data.x,
        DateTime.utc(2024, 3, 5),
        reason: 'types/DataPoint.ts:829 `number | string | Date`.',
      );
      expect(data.values.length, 1, reason: 'One stacked value.');
    });
  });

  group('FluentYValueHover', () {
    test('is entirely optional, matching the upstream shape', () {
      const hover = FluentYValueHover();
      expect(hover.legend, isNull, reason: 'types/DataPoint.ts:17 legend?.');
      expect(hover.y, isNull, reason: 'types/DataPoint.ts:17 y?.');
      expect(hover.color, isNull, reason: 'types/DataPoint.ts:17 color?.');
      expect(hover.index, isNull, reason: 'Optional.');
      expect(hover.shape, isNull, reason: 'Optional.');
    });
    test('accepts a legend shape for the popover swatch', () {
      const hover = FluentYValueHover(shape: FluentChartLegendShape.diamond);
      expect(
        hover.shape,
        FluentChartLegendShape.diamond,
        reason: 'ChartPopover.tsx:216 passes a shape down to the swatch.',
      );
    });
  });
}
