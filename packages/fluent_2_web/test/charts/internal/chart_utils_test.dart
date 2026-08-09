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

  group('isLegendHighlightedMulti — model A, nine charts', () {
    test('uses the selection when there is one', () {
      expect(
        isLegendHighlightedMulti(
          'A',
          selectedLegends: const <String>['A', 'B'],
          activeLegend: 'C',
        ),
        isTrue,
        reason:
            'VerticalBarChart.tsx:920 — a non-empty selectedLegends wins over '
            'activeLegend outright.',
      );
      expect(
        isLegendHighlightedMulti(
          'C',
          selectedLegends: const <String>['A', 'B'],
          activeLegend: 'C',
        ),
        isFalse,
        reason: 'activeLegend is ignored once a selection exists (:920).',
      );
    });

    test('falls back to the hovered legend when nothing is selected', () {
      expect(
        isLegendHighlightedMulti(
          'C',
          selectedLegends: const <String>[],
          activeLegend: 'C',
        ),
        isTrue,
        reason:
            'VerticalBarChart.tsx:920 `activeLegend ? [activeLegend] : []`.',
      );
    });

    test(
      'treats an empty activeLegend as no hover, matching the falsy test',
      () {
        expect(
          isLegendHighlightedMulti(
            '',
            selectedLegends: const <String>[],
            activeLegend: '',
          ),
          isFalse,
          reason:
              "VerticalBarChart.tsx:920 uses a truthiness test, so '' produces "
              'the empty array and nothing is highlighted.',
        );
      },
    );

    test('is false when nothing is selected and nothing is hovered', () {
      expect(
        isLegendHighlightedMulti('A', selectedLegends: const <String>[]),
        isFalse,
        reason: 'The empty array contains nothing (VerticalBarChart.tsx:909).',
      );
    });
  });

  group('isLegendHighlightedSingle — model B, HeatMap and LineChart', () {
    test('matches the selected legend', () {
      expect(
        isLegendHighlightedSingle('A', selectedLegend: 'A'),
        isTrue,
        reason: 'LineChart.tsx:1818, HeatMapChart.tsx:609.',
      );
    });
    test('matches the hovered legend only when nothing is selected', () {
      expect(
        isLegendHighlightedSingle('B', selectedLegend: '', activeLegend: 'B'),
        isTrue,
        reason: "LineChart.tsx:1818 `selectedLegend === '' && …`.",
      );
      expect(
        isLegendHighlightedSingle('B', selectedLegend: 'A', activeLegend: 'B'),
        isFalse,
        reason: 'A selection suppresses the hover arm entirely (:1818).',
      );
    });
  });

  group('isLegendHighlightedSingleGuarded — HorizontalBarChart', () {
    test('is false for a null title, before anything else is tested', () {
      expect(
        isLegendHighlightedSingleGuarded(null, selectedLegend: ''),
        isFalse,
        reason: 'HorizontalBarChart.tsx:372-374 returns early.',
      );
    });
    test('otherwise behaves exactly as model B', () {
      expect(
        isLegendHighlightedSingleGuarded('A', selectedLegend: 'A'),
        isTrue,
        reason: 'HorizontalBarChart.tsx:375.',
      );
      expect(
        isLegendHighlightedSingleGuarded(
          'A',
          selectedLegend: '',
          activeLegend: 'A',
        ),
        isTrue,
        reason: 'HorizontalBarChart.tsx:375, the hover arm.',
      );
    });
    test('a null selectedLegend never equals a real title', () {
      expect(
        isLegendHighlightedSingleGuarded('A', selectedLegend: null),
        isFalse,
        reason:
            'HorizontalBarChart.tsx:375 compares with ===, so an undefined '
            'selectedLegend matches nothing and does not open the hover arm '
            "either, because it is not ''.",
      );
    });
  });

  group('areArraysEqual', () {
    test('two nulls are equal', () {
      expect(
        areArraysEqual(null, null),
        isTrue,
        reason: 'utilities.ts:1983 `!arr1 && !arr2`.',
      );
    });
    test('identical contents are equal', () {
      expect(
        areArraysEqual(const <String>['a', 'b'], const <String>['a', 'b']),
        isTrue,
        reason: 'utilities.ts:1989-1993 element by element.',
      );
    });
    test('a different order is not equal', () {
      expect(
        areArraysEqual(const <String>['a', 'b'], const <String>['b', 'a']),
        isFalse,
        reason: 'utilities.ts:1990 compares by index.',
      );
    });
    test('null against a list is not equal, even against an empty one', () {
      expect(
        areArraysEqual(null, const <String>[]),
        isFalse,
        reason:
            'utilities.ts:1986 — `!arr1 || !arr2` returns false once one side '
            'is defined.',
      );
    });
    test('different lengths are not equal', () {
      expect(
        areArraysEqual(const <String>['a'], const <String>['a', 'b']),
        isFalse,
        reason: 'utilities.ts:1986 length check.',
      );
    });
  });

  group('capitalizeLegendLabel', () {
    test('uppercases the first letter of each whitespace-separated word', () {
      expect(
        capitalizeLegendLabel('first half'),
        'First Half',
        reason:
            "useLegendsStyles.styles.ts:56 `textTransform: 'capitalize'`, "
            'which Flutter has no equivalent for.',
      );
    });
    test('leaves the rest of each word untouched', () {
      expect(
        capitalizeLegendLabel('GDP growth'),
        'GDP Growth',
        reason:
            'CSS capitalize titlecases the first letter of each word and does '
            'not lowercase the remainder.',
      );
    });
    test('is a no-op on an already-capitalised label', () {
      expect(
        capitalizeLegendLabel('Sales'),
        'Sales',
        reason: 'Idempotent, which matters because it runs on every paint.',
      );
    });
    test('handles an empty string and leading whitespace', () {
      expect(capitalizeLegendLabel(''), '', reason: 'Nothing to capitalise.');
      expect(
        capitalizeLegendLabel('  q1  '),
        '  Q1  ',
        reason: 'Runs of whitespace are preserved so widths do not shift.',
      );
    });
    test('does not treat a hyphen as a word boundary', () {
      expect(
        capitalizeLegendLabel('north-east'),
        'North-east',
        reason:
            'ponytail: whitespace-only word splitting, matching Chrome for a '
            'hyphen. Refine if a label ever needs a different boundary.',
      );
    });
  });
}
