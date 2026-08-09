import 'dart:ui';

import 'package:fluent_2_web/src/charts/internal/chart_utils.dart';
import 'package:fluent_2_web/src/charts/model/cartesian_series.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const blue = Color(0xFF4F6BED);
  const pink = Color(0xFFE3008C);

  group('calloutData', () {
    test('groups every series value that shares an x', () {
      final result = calloutData(const <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'A',
          color: blue,
          data: <Object>[
            FluentLineChartDataPoint(x: 1, y: 10),
            FluentLineChartDataPoint(x: 2, y: 20),
          ],
        ),
        FluentLineChartSeries(
          legend: 'B',
          color: pink,
          data: <Object>[FluentLineChartDataPoint(x: 1, y: 15)],
        ),
      ]);
      expect(result.length, 2, reason: 'Two distinct x values.');
      expect(
        result.first.values.map((v) => v.legend),
        <String>['A', 'B'],
        reason:
            'utilities.ts:1015-1022 flattens every series in order, so the '
            'stack at x = 1 lists A before B.',
      );
      expect(
        result.first.values.first.color.toARGB32(),
        0xFF4F6BED,
        reason: 'utilities.ts:1019 copies the series colour onto each point.',
      );
    });

    test('keys a DateTime x by its epoch milliseconds', () {
      final x = DateTime.utc(2024, 3, 5);
      final result = calloutData(<FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'A',
          color: blue,
          data: <Object>[FluentLineChartDataPoint(x: x, y: 1)],
        ),
        FluentLineChartSeries(
          legend: 'B',
          color: pink,
          data: <Object>[
            FluentLineChartDataPoint(
              x: DateTime.fromMillisecondsSinceEpoch(
                x.millisecondsSinceEpoch,
                isUtc: true,
              ),
              y: 2,
            ),
          ],
        ),
      ]);
      expect(
        result.length,
        1,
        reason:
            'utilities.ts:1046 `ele.x instanceof Date ? ele.x.getTime() : ele.x` '
            '— two equal instants share one key.',
      );
      expect(result.single.values.length, 2, reason: 'Both series contribute.');
    });

    test('drops a point only when BOTH legend and y already match', () {
      final result = calloutData(const <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'A',
          color: blue,
          data: <Object>[
            FluentLineChartDataPoint(x: 1, y: 10),
            FluentLineChartDataPoint(x: 1, y: 10),
            FluentLineChartDataPoint(x: 1, y: 11),
          ],
        ),
      ]);
      expect(
        result.single.values.map((v) => v.y),
        <double>[10, 11],
        reason:
            'utilities.ts:1060-1062 finds an existing point with the same '
            'legend AND the same y; the second 10 matches on both and is '
            'dropped, the 11 matches on legend alone and is kept.',
      );
    });

    test('keeps two series with the same y at the same x', () {
      final result = calloutData(const <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'A',
          color: blue,
          data: <Object>[FluentLineChartDataPoint(x: 1, y: 10)],
        ),
        FluentLineChartSeries(
          legend: 'B',
          color: pink,
          data: <Object>[FluentLineChartDataPoint(x: 1, y: 10)],
        ),
      ]);
      expect(
        result.single.values.length,
        2,
        reason:
            'The dedup is on the legend/y PAIR (utilities.ts:1061), not on the '
            'legend alone.',
      );
    });

    test('omits a point whose hideCallout is set', () {
      final result = calloutData(const <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'A',
          color: blue,
          data: <Object>[
            FluentLineChartDataPoint(x: 1, y: 10, hideCallout: true),
            FluentLineChartDataPoint(x: 2, y: 20),
          ],
        ),
      ]);
      expect(
        result.map((d) => d.x),
        <Object>[2],
        reason: 'utilities.ts:1017 filters on `!point.hideCallout`.',
      );
    });

    test('carries the series index through for the popover swatch', () {
      final result = calloutData(const <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'A',
          color: blue,
          data: <Object>[FluentLineChartDataPoint(x: 1, y: 10)],
        ),
        FluentLineChartSeries(
          legend: 'B',
          color: pink,
          data: <Object>[FluentLineChartDataPoint(x: 1, y: 11)],
        ),
      ]);
      expect(
        result.single.values.map((v) => v.index),
        <int>[0, 1],
        reason:
            'utilities.ts:1053 copies the series index; ChartPopover.tsx:216 '
            'turns it into a swatch shape.',
      );
    });

    test('handles a scatter point in the same series list', () {
      final result = calloutData(const <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'A',
          color: blue,
          data: <Object>[FluentScatterChartDataPoint(x: 'Jan', y: 3)],
        ),
      ]);
      expect(
        result.single.x,
        'Jan',
        reason:
            'types/DataPoint.ts:492 — a series `data` is '
            'LineChartDataPoint[] | ScatterChartDataPoint[].',
      );
    });
  });

  group('findCalloutPoints', () {
    final data = calloutData(<FluentLineChartSeries>[
      FluentLineChartSeries(
        legend: 'A',
        color: blue,
        data: <Object>[
          FluentLineChartDataPoint(x: DateTime.utc(2024, 3, 5), y: 7),
        ],
      ),
    ]);

    test('returns null for a null x', () {
      expect(
        findCalloutPoints(data, null, isXAxisDate: true),
        isNull,
        reason: 'utilities.ts:2564-2566.',
      );
    });

    test('finds a date x by identity of instant', () {
      expect(
        findCalloutPoints(
          data,
          DateTime.utc(2024, 3, 5),
          isXAxisDate: true,
        )!.single.y,
        7,
        reason: 'utilities.ts:2568 keys on getTime().',
      );
    });

    test('accepts epoch milliseconds when the axis is a date axis', () {
      expect(
        findCalloutPoints(
          data,
          DateTime.utc(2024, 3, 5).millisecondsSinceEpoch,
          isXAxisDate: true,
        )!.single.y,
        7,
        reason:
            'A Flutter chart inverts a time scale to a number, so a numeric x '
            'on a date axis has to reach the same entry. Upstream never needs '
            'this because its scale inverts to a Date object.',
      );
    });

    test('does not coerce a number when the axis is not a date axis', () {
      final numeric = calloutData(const <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'A',
          color: blue,
          data: <Object>[FluentLineChartDataPoint(x: 1, y: 7)],
        ),
      ]);
      expect(
        findCalloutPoints(numeric, 1, isXAxisDate: false)!.single.y,
        7,
        reason: 'A numeric axis keys on the raw value (utilities.ts:2568).',
      );
    });

    test('returns null for an x with no entry', () {
      expect(
        findCalloutPoints(data, DateTime.utc(2020), isXAxisDate: true),
        isNull,
        reason: 'utilities.ts:2569-2571.',
      );
    });
  });
}
