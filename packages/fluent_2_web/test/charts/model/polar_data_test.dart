import 'dart:ui';

import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:fluent_2_web/src/charts/model/line_options.dart';
import 'package:fluent_2_web/src/charts/model/polar_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentPolarDataPoint', () {
    test('takes r as any of three types and theta as two', () {
      const point = FluentPolarDataPoint(r: 3, theta: 'North');
      expect(
        point.r,
        3,
        reason: 'types/DataPoint.ts:1283 `string|number|Date`.',
      );
      expect(
        point.theta,
        'North',
        reason:
            'types/DataPoint.ts:1288 `string | number` — a category or degrees.',
      );
    });
    test('rejects a DateTime theta', () {
      expect(
        () => FluentPolarDataPoint(r: 1, theta: DateTime(2024)),
        throwsA(isA<AssertionError>()),
        reason: 'types/DataPoint.ts:1288 has no Date arm.',
      );
    });
  });

  group('FluentPolarLineOptions', () {
    test('carries axisLabel as a list, not a single string', () {
      const options = FluentPolarLineOptions(
        axisLabel: <String>['N', 'E', 'S', 'W'],
      );
      expect(
        options.axisLabel,
        <String>['N', 'E', 'S', 'W'],
        reason:
            'scatterpolar-utils.tsx:84 keeps the value only when '
            'Array.isArray, and the declared shape at :79-85 is string[]. The '
            "cross-plan contract's `String?` is a transcription slip.",
      );
    });
    test('carries the other three polar-only fields', () {
      const options = FluentPolarLineOptions(
        direction: 'clockwise',
        rotation: 90,
        originXOffset: 12,
      );
      expect(
        options.direction,
        'clockwise',
        reason:
            'scatterpolar-utils.tsx:80-83 keeps only clockwise and '
            'counterclockwise.',
      );
      expect(options.rotation, 90, reason: 'scatterpolar-utils.tsx:83.');
      expect(options.originXOffset, 12, reason: 'scatterpolar-utils.tsx:79.');
    });
    test('rejects a direction that is neither of the two literals', () {
      expect(
        () => FluentPolarLineOptions(direction: 'widdershins'),
        throwsA(isA<AssertionError>()),
        reason:
            'scatterpolar-utils.tsx:80-83 normalises anything else to '
            'undefined, so an unrecognised value must not reach a painter.',
      );
    });
  });

  group('FluentPolarSeries', () {
    test('scatter carries no line options', () {
      const series = FluentScatterPolarSeries(
        legend: 'Wind',
        data: <FluentPolarDataPoint>[],
      );
      expect(
        series.legend,
        'Wind',
        reason: 'types/DataPoint.ts:1193 on the shared DataSeries base.',
      );
      expect(
        series.useSecondaryYScale,
        isFalse,
        reason: 'types/DataPoint.ts:1209 documents the default.',
      );
    });
    test('line and area both carry both option bags', () {
      const line = FluentLinePolarSeries(
        legend: 'Wind',
        data: <FluentPolarDataPoint>[],
        lineOptions: FluentLineOptions(strokeWidth: 3),
        polarLineOptions: FluentPolarLineOptions(rotation: 45),
      );
      const area = FluentAreaPolarSeries(
        legend: 'Gust',
        data: <FluentPolarDataPoint>[],
        lineOptions: FluentLineOptions(fill: 'toself'),
      );
      expect(
        line.lineOptions!.strokeWidth,
        3,
        reason: 'PolarChart falls back to 3 when the series names nothing.',
      );
      expect(
        line.polarLineOptions!.rotation,
        45,
        reason: 'Split per spec 5.6.',
      );
      expect(
        area.lineOptions!.fill,
        'toself',
        reason: 'LineChart.tsx:1318 gates the closed fill on this literal.',
      );
    });
    test('gradient is an ordered colour pair', () {
      const series = FluentScatterPolarSeries(
        legend: 'Wind',
        data: <FluentPolarDataPoint>[],
        gradient: (Color(0xFF4F6BED), Color(0xFF93A4F4)),
      );
      expect(
        series.gradient!.$1.toARGB32(),
        0xFF4F6BED,
        reason: 'types/DataPoint.ts:1204 `[string, string]`.',
      );
    });
  });

  group('FluentPolarAxisConfig', () {
    test('extends the shared axis config with seven polar members', () {
      const config = FluentPolarAxisConfig(
        tickStep: 2,
        tickValues: <Object>[0, 90, 180, 270],
        tickFormat: '.0f',
        tickCount: 4,
        rangeStart: 0,
        rangeEnd: 360,
      );
      expect(config.tickStep, 2, reason: 'Inherited from AxisProps.');
      expect(
        config.tickValues!.length,
        4,
        reason: 'PolarChart.types.ts:22 `number[] | Date[] | string[]`.',
      );
      expect(config.tickFormat, '.0f', reason: 'PolarChart.types.ts:29.');
      expect(config.tickCount, 4, reason: 'PolarChart.types.ts:34.');
      expect(config.rangeStart, 0, reason: 'PolarChart.types.ts:51.');
      expect(config.rangeEnd, 360, reason: 'PolarChart.types.ts:56.');
      expect(
        config.categoryOrder,
        same(FluentAxisCategoryOrder.defaultOrder),
        reason: 'PolarChart.types.ts:40 is optional, so the preset wins.',
      );
      expect(
        config.scaleType,
        FluentAxisScaleType.auto,
        reason: "PolarChart.types.ts:46 is optional, so 'default' wins.",
      );
    });
  });
}
