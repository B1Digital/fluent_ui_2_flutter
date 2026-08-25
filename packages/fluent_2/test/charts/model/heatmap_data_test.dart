import 'package:fluent_2/src/charts/model/heatmap_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentHeatMapChartDataPoint', () {
    test('takes all three coordinate types on both axes', () {
      final point = FluentHeatMapChartDataPoint(
        x: 'Mon',
        y: DateTime.utc(2024),
        value: 3,
      );
      expect(point.x, 'Mon', reason: 'types/DataPoint.ts:852 string arm.');
      expect(
        point.y,
        DateTime.utc(2024),
        reason: 'types/DataPoint.ts:853 Date arm.',
      );
      expect(point.value, 3, reason: 'types/DataPoint.ts:854.');
    });

    test('rejects a coordinate that is none of the three types', () {
      expect(
        () => FluentHeatMapChartDataPoint(x: const <int>[], y: 1, value: 0),
        throwsA(isA<AssertionError>()),
        reason: 'types/DataPoint.ts:852 — `string | Date | number`.',
      );
    });

    test('rectText may be a number or a string', () {
      const numeric = FluentHeatMapChartDataPoint(
        x: 1,
        y: 1,
        value: 1,
        rectText: 5,
      );
      const textual = FluentHeatMapChartDataPoint(
        x: 1,
        y: 1,
        value: 1,
        rectText: 'high',
      );
      expect(numeric.rectText, 5, reason: 'types/DataPoint.ts:858 number arm.');
      expect(
        textual.rectText,
        'high',
        reason: 'types/DataPoint.ts:858 string arm.',
      );
    });

    test('ratio is an ordered pair', () {
      const point = FluentHeatMapChartDataPoint(
        x: 1,
        y: 1,
        value: 1,
        ratio: (3, 4),
      );
      expect(
        point.ratio!.$1,
        3,
        reason: 'types/DataPoint.ts:862 `[number, number]` numerator.',
      );
      expect(point.ratio!.$2, 4, reason: 'The denominator.');
    });
  });

  group('FluentHeatMapChartData', () {
    test('names a legend and the value its colour is chosen from', () {
      const series = FluentHeatMapChartData(
        legend: 'Utilisation',
        data: <FluentHeatMapChartDataPoint>[],
        value: 42,
      );
      expect(series.legend, 'Utilisation', reason: 'types/DataPoint.ts:885.');
      expect(
        series.value,
        42,
        reason:
            'types/DataPoint.ts:890 — "This number will be used to get the '
            'color for the legend".',
      );
    });
  });
}
