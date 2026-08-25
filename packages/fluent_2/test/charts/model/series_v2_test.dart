import 'dart:ui';

import 'package:fluent_2/src/charts/model/cartesian_series.dart';
import 'package:fluent_2/src/charts/model/line_options.dart';
import 'package:fluent_2/src/charts/model/series_v2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentDataPointV2', () {
    test('is non-generic and asserts both coordinate types', () {
      final point = FluentDataPointV2(x: 'Q1', y: DateTime.utc(2024));
      expect(
        point.x,
        'Q1',
        reason:
            'types/DataPoint.ts:1134 is generic over `string | number | Date`; '
            'the Dart port asserts instead of parameterising, because the '
            'chart reads both coordinates as Objects anyway.',
      );
      expect(point.y, DateTime.utc(2024), reason: 'The Date arm.');
      expect(
        () => FluentDataPointV2(x: const <int>[], y: 1),
        throwsA(isA<AssertionError>()),
        reason: 'Nothing outside the three types is admissible.',
      );
    });
    test('carries the optional per-point extras', () {
      const point = FluentDataPointV2(
        x: 1,
        y: 2,
        markerSize: 6,
        text: 'six',
        color: Color(0xFF13A10E),
      );
      expect(point.markerSize, 6, reason: 'types/DataPoint.ts:1168.');
      expect(point.text, 'six', reason: 'types/DataPoint.ts:1173.');
      expect(
        point.color!.toARGB32(),
        0xFF13A10E,
        reason: 'types/DataPoint.ts:1178.',
      );
    });
  });

  group('FluentBarSeries', () {
    test('carries an optional group key and no line-only members', () {
      const series = FluentBarSeries(
        legend: 'Sales',
        data: <FluentDataPointV2>[],
        key: 'group-a',
      );
      expect(series.key, 'group-a', reason: 'types/DataPoint.ts:1238.');
      expect(
        series.useSecondaryYScale,
        isFalse,
        reason: 'types/DataPoint.ts:1213 on the DataSeries base.',
      );
    });
  });

  group('FluentLineSeries', () {
    test('carries gaps, line options, hideInactiveDots and onLineClick', () {
      const series = FluentLineSeries(
        legend: 'Trend',
        data: <FluentDataPointV2>[],
        gaps: <FluentLineChartGap>[
          FluentLineChartGap(startIndex: 1, endIndex: 2),
        ],
        lineOptions: FluentLineOptions(strokeWidth: 3),
        hideInactiveDots: true,
      );
      expect(series.gaps!.length, 1, reason: 'types/DataPoint.ts:1258.');
      expect(
        series.lineOptions!.strokeWidth,
        3,
        reason: 'types/DataPoint.ts:1263.',
      );
      expect(
        series.hideInactiveDots,
        isTrue,
        reason:
            'types/DataPoint.ts:1268 — the v2 shape already spells it this way.',
      );
      expect(
        series.onLineClick,
        isNull,
        reason: 'types/DataPoint.ts:1273 optional.',
      );
    });
  });
}
