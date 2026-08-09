import 'dart:ui';

import 'package:fluent_2_web/src/charts/internal/chart_utils.dart';
import 'package:fluent_2_web/src/charts/internal/d3/curves.dart' as d3;
import 'package:fluent_2_web/src/charts/model/cartesian_series.dart';
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:fluent_2_web/src/charts/model/chart_value.dart';
import 'package:fluent_2_web/src/charts/model/line_options.dart';
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

  group('getBarWidth', () {
    test("'auto' takes the adjusted value outright", () {
      expect(
        getBarWidth('auto', null, adjustedValue: 40),
        40,
        reason: 'utilities.ts:1901-1902.',
      );
    });
    test("mode 'histogram' does the same, whatever the width prop says", () {
      expect(
        getBarWidth('default', null, adjustedValue: 40, mode: 'histogram'),
        40,
        reason:
            "utilities.ts:1901 `barWidthProp === 'auto' || modeProp === "
            "'histogram'`.",
      );
    });
    test('a number is taken as given', () {
      expect(
        getBarWidth(24, null),
        24,
        reason: "utilities.ts:1903-1904 `typeof barWidthProp === 'number'`.",
      );
    });
    test('anything else clamps the adjusted value to the 16px default', () {
      expect(
        getBarWidth(null, null, adjustedValue: 40),
        16,
        reason:
            'utilities.ts:1906 `Math.min(adjustedValue, DEFAULT_BAR_WIDTH)` '
            'with DEFAULT_BAR_WIDTH 16 (:1891).',
      );
      expect(
        getBarWidth('default', null, adjustedValue: 9),
        9,
        reason: 'The min picks the adjusted value when it is the smaller.',
      );
    });
    test('maxBarWidth caps the result', () {
      expect(getBarWidth(24, 20), 20, reason: 'utilities.ts:1908-1910.');
    });
    test('the 1px floor is applied last', () {
      expect(
        getBarWidth(0, null),
        1,
        reason:
            'utilities.ts:1911 `Math.max(barWidth, MIN_BAR_WIDTH)` with '
            'MIN_BAR_WIDTH 1 (:1892).',
      );
      expect(
        getBarWidth(24, 0),
        1,
        reason: 'The cap runs before the floor, so 0 becomes 1.',
      );
    });
    test('exports the two constants', () {
      expect(kDefaultBarWidth, 16, reason: 'utilities.ts:1891.');
      expect(kMinBarWidth, 1, reason: 'utilities.ts:1892.');
    });
  });

  group('getScalePadding', () {
    test('prefers the prop, then the shorthand, then the default', () {
      expect(getScalePadding(0.3, 0.6, 0.9), 0.3, reason: 'utilities.ts:1916.');
      expect(
        getScalePadding(null, 0.6, 0.9),
        0.6,
        reason: 'utilities.ts:1916.',
      );
      expect(
        getScalePadding(null, null, 0.9),
        0.9,
        reason: 'utilities.ts:1916.',
      );
      expect(getScalePadding(null), 0, reason: 'defaultValue defaults to 0.');
    });
    test('clamps into 0..1', () {
      expect(
        getScalePadding(-3),
        0,
        reason: 'utilities.ts:1917 Math.max(0, …).',
      );
      expect(
        getScalePadding(4),
        1,
        reason: 'utilities.ts:1917 Math.min(…, 1).',
      );
    });
    test('ignores a non-numeric prop', () {
      expect(
        getScalePadding('0.5', 0.25),
        0.25,
        reason: "utilities.ts:1916 tests `typeof prop === 'number'`.",
      );
    });
  });

  group('isScalePaddingDefined', () {
    test('is true when either side is a number', () {
      expect(
        isScalePaddingDefined(0),
        isTrue,
        reason:
            'utilities.ts:1922 — 0 is a number, so the falsy trap does '
            'not apply here.',
      );
      expect(
        isScalePaddingDefined(null, 0.5),
        isTrue,
        reason: 'utilities.ts:1922.',
      );
      expect(
        isScalePaddingDefined(null, null),
        isFalse,
        reason: 'Neither is set.',
      );
      expect(
        isScalePaddingDefined('0.5'),
        isFalse,
        reason: 'A string is not a number (utilities.ts:1922).',
      );
    });
  });

  group('truncateString', () {
    test('leaves a short-enough string alone', () {
      expect(
        truncateString('Jan', 4),
        'Jan',
        reason: 'utilities.ts:2037-2039 `str.length <= maxLength`.',
      );
      expect(
        truncateString('Janu', 4),
        'Janu',
        reason: 'The comparison is inclusive.',
      );
    });
    test('appends the ellipsis AFTER the slice, so the result grows', () {
      expect(
        truncateString('January', 4),
        'Janu...',
        reason:
            'utilities.ts:2041 `str.slice(0, maxLength) + ellipsis` — the '
            'ellipsis is not counted against maxLength.',
      );
    });
    test('honours a custom ellipsis', () {
      expect(
        truncateString('January', 4, ellipsis: '…'),
        'Janu…',
        reason: 'utilities.ts:2036 default parameter.',
      );
    });
  });
  group('sortAxisCategories', () {
    const values = <String, List<double>>{
      'b': <double>[3, 1],
      'a': <double>[2, 2],
      'c': <double>[5],
    };

    test('an unrecognised order keeps insertion order', () {
      expect(
        sortAxisCategories(values, FluentAxisCategoryOrder.data),
        <String>['b', 'a', 'c'],
        reason:
            "utilities.ts:2109 — 'data' matches no aggregator regex, so the "
            'function falls through to Object.keys.',
      );
      expect(
        sortAxisCategories(values, FluentAxisCategoryOrder.defaultOrder),
        <String>['b', 'a', 'c'],
        reason: "'default' also falls through (utilities.ts:2109).",
      );
    });

    test('category ascending sorts the keys as strings', () {
      expect(
        sortAxisCategories(values, FluentAxisCategoryOrder.categoryAscending),
        <String>['a', 'b', 'c'],
        reason: 'utilities.ts:2080-2081 `Object.keys(...).sort()`.',
      );
      expect(
        sortAxisCategories(values, FluentAxisCategoryOrder.categoryDescending),
        <String>['c', 'b', 'a'],
        reason: 'utilities.ts:2082 `.reverse()`.',
      );
    });

    test('total and sum are the same aggregator', () {
      expect(
        sortAxisCategories(values, FluentAxisCategoryOrder.totalAscending),
        sortAxisCategories(values, FluentAxisCategoryOrder.sumAscending),
        reason: 'utilities.ts:2087-2088 maps both to d3Sum.',
      );
      expect(
        sortAxisCategories(values, FluentAxisCategoryOrder.totalAscending),
        <String>['b', 'a', 'c'],
        reason:
            'Sums are b 4, a 4, c 5; b precedes a because the sort is stable.',
      );
    });

    test('min, max, mean and median each pick their own aggregator', () {
      expect(
        sortAxisCategories(values, FluentAxisCategoryOrder.minAscending),
        <String>['b', 'a', 'c'],
        reason: 'Minima are b 1, a 2, c 5 (utilities.ts:2085).',
      );
      expect(
        sortAxisCategories(values, FluentAxisCategoryOrder.maxDescending),
        <String>['c', 'b', 'a'],
        reason: 'Maxima are c 5, b 3, a 2 (utilities.ts:2086, :2098).',
      );
      expect(
        sortAxisCategories(values, FluentAxisCategoryOrder.medianDescending),
        <String>['c', 'b', 'a'],
        reason:
            'Medians are c 5, b 2, a 2 (utilities.ts:2090, :2098); the two '
            'twos keep insertion order.',
      );
    });

    test('a stable sort keeps ties in insertion order', () {
      expect(
        sortAxisCategories(values, FluentAxisCategoryOrder.meanAscending),
        <String>['b', 'a', 'c'],
        reason:
            'Means are b 2, a 2, c 5. V8 sorts stably, Dart does not, so this '
            'goes through stableSort (spec 8).',
      );
    });

    test('an empty value list aggregates to 0, not to null', () {
      expect(
        sortAxisCategories(const <String, List<double>>{
          'x': <double>[],
          'y': <double>[-1],
        }, FluentAxisCategoryOrder.sumAscending),
        <String>['y', 'x'],
        reason:
            'utilities.ts:2103 `aggFn[aggregator](...) || 0` — an undefined '
            'aggregate becomes 0, which sorts above -1.',
      );
    });

    test('an aggregate of 0 is also coerced to 0, harmlessly', () {
      expect(
        sortAxisCategories(const <String, List<double>>{
          'x': <double>[0],
          'y': <double>[-1],
        }, FluentAxisCategoryOrder.maxAscending),
        <String>['y', 'x'],
        reason:
            '// parity: the `|| 0` at utilities.ts:2103 also swallows a real 0, '
            'which happens to be the same value.',
      );
    });

    test('an explicit order emits the named categories first', () {
      expect(
        sortAxisCategories(
          values,
          const FluentAxisCategoryOrder.explicit(<String>['c', 'a']),
        ),
        <String>['c', 'a', 'b'],
        reason:
            'utilities.ts:2053-2072 — named categories that exist, in the '
            "caller's order, then everything else in insertion order.",
      );
    });

    test('an explicit order ignores names the data does not carry', () {
      expect(
        sortAxisCategories(
          values,
          const FluentAxisCategoryOrder.explicit(<String>['z', 'c']),
        ),
        <String>['c', 'b', 'a'],
        reason:
            "utilities.ts:2058 skips 'z' because categoryToValues has no such "
            'key, then :2065-2069 appends b and a in insertion order.',
      );
    });

    test('an explicit order deduplicates its own entries', () {
      expect(
        sortAxisCategories(
          values,
          const FluentAxisCategoryOrder.explicit(<String>['c', 'c', 'a']),
        ),
        <String>['c', 'a', 'b'],
        reason: 'utilities.ts:2058 `!seen.has(category)`.',
      );
    });
  });

  group('getTypeOfAxis', () {
    test(
      'gives the same answer on both axes, which is why the enums collapse',
      () {
        expect(
          getTypeOfAxis('Jan', isXAxis: true),
          getTypeOfAxis('Jan', isXAxis: false),
          reason:
              'utilities.ts:1687-1705 — the two branches return members of two '
              'byte-identical enums at the same ordinals (:110-120).',
        );
        expect(
          getTypeOfAxis(1, isXAxis: true),
          FluentChartAxisType.numeric,
          reason: 'utilities.ts:1691.',
        );
        expect(
          getTypeOfAxis(DateTime(2024), isXAxis: false),
          FluentChartAxisType.date,
          reason: 'utilities.ts:1701 default arm.',
        );
      },
    );
  });

  group('getXAxisType', () {
    test('is false for no series and for empty series', () {
      expect(
        getXAxisType(const <FluentLineChartSeries>[]),
        isFalse,
        reason: 'utilities.ts:1331 guards on length.',
      );
      expect(
        getXAxisType(const <FluentLineChartSeries>[
          FluentLineChartSeries(legend: 'A', data: <Object>[]),
        ]),
        isFalse,
        reason: 'utilities.ts:1333 skips a series with no data.',
      );
    });

    test('reads the first point of the LAST non-empty series', () {
      final result = getXAxisType(<FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'A',
          data: <Object>[FluentLineChartDataPoint(x: DateTime.utc(2024), y: 1)],
        ),
        const FluentLineChartSeries(
          legend: 'B',
          data: <Object>[FluentLineChartDataPoint(x: 1, y: 1)],
        ),
      ]);
      expect(
        result,
        isFalse,
        reason:
            '// parity: the `return` inside the forEach at utilities.ts:1336 '
            'does NOT break the loop, so the last non-empty series wins and a '
            'date first series is overwritten by a numeric second one.',
      );
    });

    test('an empty trailing series does not clear an earlier date verdict', () {
      final result = getXAxisType(<FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'A',
          data: <Object>[FluentLineChartDataPoint(x: DateTime.utc(2024), y: 1)],
        ),
        const FluentLineChartSeries(legend: 'B', data: <Object>[]),
      ]);
      expect(
        result,
        isTrue,
        reason: 'utilities.ts:1333 only assigns for a non-empty series.',
      );
    });
  });

  group('getCurveFactory', () {
    test('maps each named curve', () {
      expect(
        identical(getCurveFactory(FluentLineCurve.natural), d3.curveNatural),
        isTrue,
        reason: 'utilities.ts:2021-2022.',
      );
      expect(
        identical(getCurveFactory(FluentLineCurve.step), d3.curveStep),
        isTrue,
        reason: 'utilities.ts:2023-2024.',
      );
      expect(
        identical(
          getCurveFactory(FluentLineCurve.stepAfter),
          d3.curveStepAfter,
        ),
        isTrue,
        reason: 'utilities.ts:2025-2026.',
      );
      expect(
        identical(
          getCurveFactory(FluentLineCurve.stepBefore),
          d3.curveStepBefore,
        ),
        isTrue,
        reason: 'utilities.ts:2027-2028.',
      );
      expect(
        identical(getCurveFactory(FluentLineCurve.linear), d3.curveLinear),
        isTrue,
        reason: 'utilities.ts:2019-2020.',
      );
    });

    test('passes a caller-supplied factory straight through', () {
      expect(
        identical(getCurveFactory(d3.curveNatural), d3.curveNatural),
        isTrue,
        reason: "utilities.ts:2016-2018 `typeof curve === 'function'`.",
      );
    });

    test('falls back to linear, and to a named default when given one', () {
      expect(
        identical(getCurveFactory(null), d3.curveLinear),
        isTrue,
        reason: 'utilities.ts:2014 default parameter.',
      );
      expect(
        identical(getCurveFactory(null, d3.curveStep), d3.curveStep),
        isTrue,
        reason: 'utilities.ts:2029-2030 default arm.',
      );
    });
  });
}
