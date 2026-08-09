import 'dart:convert';
import 'dart:io';

import 'package:fluent_2_web/src/charts/axis/axis_types.dart';
import 'package:fluent_2_web/src/charts/axis/domain_range.dart';
import 'package:fluent_2_web/src/charts/internal/d3/ticks.dart' as d3;
import 'package:fluent_2_web/src/charts/model/bar_data.dart';
import 'package:fluent_2_web/src/charts/model/cartesian_series.dart';
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:fluent_2_web/src/charts/model/chart_value.dart';
import 'package:flutter_test/flutter_test.dart';

FluentLineChartSeries _series(String legend, List<(Object, double)> points) {
  return FluentLineChartSeries(
    legend: legend,
    data: <Object>[
      for (final (x, y) in points) FluentLineChartDataPoint(x: x, y: y),
    ],
  );
}

/// Reads one Oracle B story fixture.
///
/// `test/support/oracle_fixture.dart` does not exist on disk yet, so this walks
/// up from [Directory.current] to the corpus the same way
/// `test/charts/oracle_b/oracle_b_corpus_test.dart` does, and should be replaced
/// by the shared loader once that lands.
Map<String, dynamic> _loadOracleStory(String id) {
  const relative = 'test/fixtures/charts/oracle_b';
  var directory = Directory.current;
  while (true) {
    final candidate = File('${directory.path}/$relative/$id.json');
    if (candidate.existsSync()) {
      return jsonDecode(candidate.readAsStringSync()) as Map<String, dynamic>;
    }
    final parent = directory.parent;
    // Reaching the filesystem root leaves parent == directory.
    if (parent.path == directory.path) {
      throw StateError(
        'No $relative/$id.json found in ${Directory.current.path} or any '
        'ancestor.',
      );
    }
    directory = parent;
  }
}

/// The `<svg>` children of the first captured chart in [story].
List<Map<String, dynamic>> _svgElements(Map<String, dynamic> story) {
  final svg = (story['svgs'] as List<dynamic>).first as Map<String, dynamic>;
  return (svg['elements'] as List<dynamic>).cast<Map<String, dynamic>>();
}

/// Maps [value] from `[dStart, dEnd]` onto `[rStart, rEnd]`.
///
/// The one line of `d3-scale/src/continuous.js:20-24` that every one of these
/// domain-and-range bags is fed into, reproduced here so a captured pixel can be
/// checked against a computed domain without pulling in the scale under
/// construction by another task.
double _project(
  double value,
  double dStart,
  double dEnd,
  double rStart,
  double rEnd,
) => rStart + (value - dStart) / (dEnd - dStart) * (rEnd - rStart);

/// The tolerance every Oracle B comparison uses, matching the corpus-wide
/// `kOracleGeometryTolerance`. The captures were taken at a device scale factor
/// of one, so a hundredth of a logical pixel is far tighter than any rounding
/// either implementation performs.
const double _oracleTolerance = 0.01;

/// Reads a captured y-axis tick label back to the number it formats.
///
/// The inverse of the thousands abbreviation `formatToLocaleString` emits, which
/// is all these two axes use: a group separator and a `k` suffix.
double _parseAxisLabel(String text) {
  final cleaned = text.replaceAll(',', '');
  if (cleaned.endsWith('k')) {
    return double.parse(cleaned.substring(0, cleaned.length - 1)) * 1000;
  }
  return double.parse(cleaned);
}

void main() {
  group('isValidDomainValue', () {
    test('accepts every non-number regardless of scale', () {
      expect(
        isValidDomainValue(DateTime.utc(2020), FluentAxisScaleType.log),
        isTrue,
        reason:
            'utilities.ts:2274 filters only numbers, so dates pass on a log scale.',
      );
    });

    test('accepts any number on a non-log scale', () {
      expect(
        isValidDomainValue(-5, FluentAxisScaleType.auto),
        isTrue,
        reason: "utilities.ts:2274 — scaleType !== 'log' short-circuits.",
      );
    });

    test('rejects a non-positive number on a log scale', () {
      expect(
        isValidDomainValue(0, FluentAxisScaleType.log),
        isFalse,
        reason: 'utilities.ts:2274 requires value > 0 on a log scale.',
      );
    });
  });

  group('getScatterXDomainExtent', () {
    test('takes the extent across every series', () {
      final extent = getScatterXDomainExtent(<Object>[
        _series('a', <(Object, double)>[(1, 10), (5, 20)]),
        _series('b', <(Object, double)>[(3, 30), (9, 40)]),
      ]);
      expect(
        extent.$1,
        1,
        reason: 'utilities.ts:2289-2291 nests d3Min over series then points.',
      );
      expect(
        extent.$2,
        9,
        reason: 'utilities.ts:2293-2297 nests d3Max the same way.',
      );
    });

    test('filters non-positive values on a log scale', () {
      final extent = getScatterXDomainExtent(<Object>[
        _series('a', <(Object, double)>[(0, 10), (4, 20)]),
      ], scaleType: FluentAxisScaleType.log);
      expect(
        extent.$1,
        4,
        reason:
            'utilities.ts:2286-2287 applies isValidDomainValue before the extent.',
      );
    });

    test('returns nulls when every point is filtered out', () {
      final extent = getScatterXDomainExtent(<Object>[
        _series('a', <(Object, double)>[(-1, 10)]),
      ], scaleType: FluentAxisScaleType.log);
      expect(
        extent.$1,
        isNull,
        reason:
            'upstream asserts non-null with `!` and lets NaN flow downstream; the '
            'port surfaces the null rather than throwing.',
      );
    });
  });

  group('getDomainPaddingForMarkers', () {
    test('pads both ends by a tenth of the range', () {
      final padding = getDomainPaddingForMarkers(0, 100);
      expect(
        padding.start,
        10,
        reason: 'utilities.ts:2251 — (max - min) * 0.1.',
      );
      expect(padding.end, 10, reason: 'the same value on both sides.');
    });

    test('suppresses the padding when the user bound is already close', () {
      final padding = getDomainPaddingForMarkers(0, 100, userMinVal: -5);
      expect(
        padding.start,
        0,
        reason:
            'utilities.ts:2254-2255 — the user floor is 5 below the data and the '
            'padding is 10, so 10 > 5 counts as already satisfied.',
      );
    });

    test('keeps the padding when the user bound is far away', () {
      final padding = getDomainPaddingForMarkers(0, 100, userMinVal: -50);
      expect(
        padding.start,
        10,
        reason: 'utilities.ts:2254 — 10 > 50 is false, so the padding stays.',
      );
    });

    test('takes the asymmetric log branch', () {
      final padding = getDomainPaddingForMarkers(
        2,
        200,
        scaleType: FluentAxisScaleType.log,
      );
      expect(padding.start, 1, reason: 'utilities.ts:2241 — minVal * 0.5.');
      expect(
        padding.end,
        200,
        reason:
            'utilities.ts:2242 returns the raw maximum as the end padding, not a '
            'delta. Odd, and ported as written.',
      );
    });
  });

  group('groupChartDataByYValue', () {
    test('keeps string keys in insertion order', () {
      final grouped = groupChartDataByYValue(<Object>[
        const FluentHorizontalBarChartWithAxisDataPoint(x: 1, y: 'beta'),
        const FluentHorizontalBarChartWithAxisDataPoint(x: 2, y: 'alpha'),
        const FluentHorizontalBarChartWithAxisDataPoint(x: 3, y: 'beta'),
      ]);
      expect(
        grouped.keys.toList(),
        <String>['beta', 'alpha'],
        reason:
            'utilities.ts:1398 returns Object.values, and JS enumerates string '
            'keys in insertion order.',
      );
      expect(
        grouped['beta']!.length,
        2,
        reason: 'two points share the y value beta.',
      );
    });

    test('sorts integer-like keys ascending, ahead of string keys', () {
      final grouped = groupChartDataByYValue(<Object>[
        const FluentHorizontalBarChartWithAxisDataPoint(x: 1, y: 'zeta'),
        const FluentHorizontalBarChartWithAxisDataPoint(x: 2, y: 10),
        const FluentHorizontalBarChartWithAxisDataPoint(x: 3, y: 2),
      ]);
      expect(
        grouped.keys.toList(),
        <String>['2', '10', 'zeta'],
        reason:
            'JS object enumeration puts integer-like keys first, in ascending '
            'numeric order, then the rest in insertion order. That ordering '
            'leaks into Object.values and therefore into the bar order.',
      );
    });

    test('keys a whole double the way JavaScript does', () {
      final grouped = groupChartDataByYValue(<Object>[
        const FluentHorizontalBarChartWithAxisDataPoint(x: 1, y: 'zeta'),
        const FluentHorizontalBarChartWithAxisDataPoint(x: 2, y: 2.0),
      ]);
      expect(
        grouped.keys.toList(),
        <String>['2', 'zeta'],
        reason:
            'utilities.ts:1389 uses the y value as an object key, so JS stringifies '
            '2.0 as "2" — which then counts as an array index and enumerates '
            "first. Dart's own 2.0.toString() would give \"2.0\" and lose both.",
      );
    });
  });

  group('computeLongestBars', () {
    test('totals positives and negatives separately per group', () {
      final grouped = groupChartDataByYValue(<Object>[
        const FluentHorizontalBarChartWithAxisDataPoint(x: 3, y: 'a'),
        const FluentHorizontalBarChartWithAxisDataPoint(x: -1, y: 'a'),
        const FluentHorizontalBarChartWithAxisDataPoint(x: 5, y: 'b'),
      ]);
      final bars = computeLongestBars(grouped, 0);
      expect(
        bars.$1,
        5,
        reason:
            'utilities.ts:1418-1421 totals the positives per group and '
            'utilities.ts:1427 keeps the largest across groups.',
      );
      expect(
        bars.$2,
        -1,
        reason:
            'utilities.ts:1422-1425 totals the negatives per group and '
            'utilities.ts:1428 keeps the smallest across groups.',
      );
    });

    test('seeds every total at the x origin', () {
      final grouped = groupChartDataByYValue(<Object>[
        const FluentHorizontalBarChartWithAxisDataPoint(x: 2, y: 'a'),
      ]);
      final bars = computeLongestBars(grouped, 10);
      expect(
        bars.$1,
        12,
        reason: 'utilities.ts:1420 passes X_ORIGIN as the reduce seed.',
      );
    });

    test('never returns a positive below zero or a negative above zero', () {
      final bars = computeLongestBars(<String, List<Object>>{}, 0);
      expect(
        bars.$1,
        0,
        reason: 'utilities.ts:1414 seeds longestPositiveBar at 0.',
      );
      expect(
        bars.$2,
        0,
        reason: 'utilities.ts:1415 seeds longestNegativeBar at 0.',
      );
    });
  });

  const margins = FluentChartMargins(left: 40, right: 20, top: 20, bottom: 35);

  group('domainRangeOfXStringAxis', () {
    test('swaps the range, not the domain, under RTL', () {
      final ltr = domainRangeOfXStringAxis(margins, 700, isRtl: false);
      final rtl = domainRangeOfXStringAxis(margins, 700, isRtl: true);
      expect(ltr.rStartValue, 40, reason: 'utilities.ts:1473 — margins.left.');
      expect(
        ltr.rEndValue,
        680,
        reason: 'utilities.ts:1474 — width - margins.right.',
      );
      expect(
        rtl.rStartValue,
        680,
        reason:
            'utilities.ts:1476 — the band axis is the ONE function that swaps the '
            'range; every other one swaps the domain. Do not unify them.',
      );
      expect(
        rtl.rEndValue,
        40,
        reason: 'the descending range is what makes the band RTL.',
      );
      expect(
        ltr.dStartValue,
        0,
        reason: 'utilities.ts:1476 sends 0 for both domain ends.',
      );
    });
  });

  group('domainRangeOfVSBCNumeric', () {
    test('swaps the domain and keeps the range under RTL', () {
      final points = <Object>[
        const FluentChartXYPoint(x: 1, y: 10),
        const FluentChartXYPoint(x: 5, y: 20),
      ];
      final ltr = domainRangeOfVSBCNumeric(points, margins, 700, isRtl: false);
      final rtl = domainRangeOfVSBCNumeric(points, margins, 700, isRtl: true);
      expect(
        ltr.dStartValue,
        1,
        reason: 'utilities.ts:1497 — d3Min of point.x, emitted at :1503.',
      );
      expect(
        rtl.dStartValue,
        5,
        reason: 'utilities.ts:1502 swaps the domain ends.',
      );
      expect(
        rtl.rStartValue,
        40,
        reason:
            'utilities.ts:1499-1503 — the locals are misnamed rMax/rMin but both '
            'branches emit left then width - right.',
      );
    });
  });

  group('domainRangeOfVerticalNumeric', () {
    test('mirrors VSBC but with its own local naming', () {
      final points = <Object>[
        const FluentVerticalBarChartDataPoint(x: 2, y: 1),
        const FluentVerticalBarChartDataPoint(x: 8, y: 3),
      ];
      final ltr = domainRangeOfVerticalNumeric(
        points,
        margins,
        700,
        isRtl: false,
      );
      expect(
        ltr.dStartValue,
        2,
        reason: 'utilities.ts:1576 — d3Min of point.x.',
      );
      expect(ltr.dEndValue, 8, reason: 'utilities.ts:1575 — d3Max of point.x.');
      expect(
        ltr.rEndValue,
        680,
        reason: 'utilities.ts:1578 — containerWidth - right.',
      );
    });
  });

  group('domainRangeOfNumericForAreaLineScatterCharts', () {
    test('takes the plain extent with no markers', () {
      final range = domainRangeOfNumericForAreaLineScatterCharts(
        <Object>[
          _series('a', <(Object, double)>[(1, 10), (9, 20)]),
        ],
        margins,
        700,
        isRtl: false,
      );
      expect(
        range.dStartValue,
        1,
        reason: 'utilities.ts:1364 — the scatter extent.',
      );
      expect(range.dEndValue, 9, reason: 'the other end of the same extent.');
    });

    test('pads both ends in markers mode', () {
      final range = domainRangeOfNumericForAreaLineScatterCharts(
        <Object>[
          _series('a', <(Object, double)>[(0, 10), (100, 20)]),
        ],
        margins,
        700,
        isRtl: false,
        hasMarkersMode: true,
      );
      expect(
        range.dStartValue,
        -10,
        reason:
            'utilities.ts:1366-1370 subtracts the ten-per-cent start padding.',
      );
      expect(range.dEndValue, 110, reason: 'and adds the end padding.');
    });

    test('overrides the domain to the unit circle for scatterpolar', () {
      final range = domainRangeOfNumericForAreaLineScatterCharts(
        <Object>[
          _series('a', <(Object, double)>[(1, 10), (9, 20)]),
        ],
        margins,
        700,
        isRtl: false,
        isScatterPolar: true,
      );
      expect(
        range.dStartValue,
        -1,
        reason: 'utilities.ts:1377 — the polar domain is [-1, 1].',
      );
      expect(range.dEndValue, 1, reason: 'the other end of the polar domain.');
    });
  });

  group('domainRangeOfNumericForHorizontalBarChartWithAxis', () {
    test('clamps the low end at the x origin', () {
      final range = domainRangeOfNumericForHorizontalBarChartWithAxis(
        <Object>[
          const FluentHorizontalBarChartWithAxisDataPoint(x: 30, y: 'a'),
        ],
        margins,
        700,
        isRtl: false,
        xOrigin: 5,
      );
      expect(
        range.dStartValue,
        0,
        reason:
            'utilities.ts:1458 — Math.min(longestNegativeBar, X_ORIGIN) with a '
            'zero negative total and an origin of 5.',
      );
      expect(
        range.dEndValue,
        35,
        reason: 'the positive total is seeded at the origin.',
      );
    });
  });

  group('domainRangeOfDateForAreaLineScatterVerticalBarCharts', () {
    test('unions the extent with the supplied tick values', () {
      final range = domainRangeOfDateForAreaLineScatterVerticalBarCharts(
        <Object>[
          _series('a', <(Object, double)>[
            (DateTime.utc(2020, 6), 10),
            (DateTime.utc(2020, 6, 30), 20),
          ]),
        ],
        margins,
        700,
        isRtl: false,
        chartType: FluentChartType.lineChart,
        tickValues: <DateTime>[DateTime.utc(2020)],
      );
      expect(
        range.dStartValue,
        DateTime.utc(2020),
        reason:
            'utilities.ts:1535-1536 unions the tick values into the extent.',
      );
    });

    test('ignores tick values for a bar chart', () {
      final range = domainRangeOfDateForAreaLineScatterVerticalBarCharts(
        <Object>[
          FluentVerticalBarChartDataPoint(x: DateTime.utc(2020, 6), y: 10),
          FluentVerticalBarChartDataPoint(x: DateTime.utc(2020, 6, 30), y: 20),
        ],
        margins,
        700,
        isRtl: false,
        chartType: FluentChartType.verticalBarChart,
        tickValues: <DateTime>[DateTime.utc(2020)],
      );
      expect(
        range.dStartValue,
        DateTime.utc(2020, 6),
        reason:
            'utilities.ts:1545-1547 — the bar branch takes a plain d3Min over '
            'point.x with no union and no padding.',
      );
    });

    test('always pads a scatter chart, markers mode or not', () {
      final range = domainRangeOfDateForAreaLineScatterVerticalBarCharts(
        <Object>[
          _series('a', <(Object, double)>[
            (DateTime.utc(2020), 10),
            (DateTime.utc(2020, 1, 11), 20),
          ]),
        ],
        margins,
        700,
        isRtl: false,
        chartType: FluentChartType.scatterChart,
      );
      expect(
        range.dStartValue,
        DateTime.utc(2019, 12, 31),
        reason:
            'utilities.ts:1538-1542 — a ten-day span pads by one day in '
            'milliseconds on each side, and ScatterChart takes that branch '
            'unconditionally.',
      );
    });
  });

  group('the domain functions against Oracle B', () {
    // Both captures supply their own margins by way of the two ported defaults:
    // the tick-bearing side is `kDefaultMarginWithTicks` and the bare side is
    // `kDefaultMarginNoTicks` (`CartesianChart.tsx:41-42`), so the range
    // endpoints asserted below are not read back out of the fixture that is
    // meant to be checking them.
    //
    // The three date branches and the two band branches have no oracle in this
    // corpus: no captured story is RTL, and no captured story's x axis is both a
    // date axis and readable back to a raw domain endpoint, because a date axis
    // rounds to a time interval before it reaches a tick. Their geometry rests
    // on the hand-written cases above.

    test('reproduces the captured horizontal-bar x axis', () {
      const storyId =
          'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-basic';
      final story = _loadOracleStory(storyId);
      final width = (story['width'] as num).toDouble();
      final crispOffset = (story['crispOffset'] as num).toDouble();
      final rects = _svgElements(
        story,
      ).where((element) => element['tag'] == 'rect').toList(growable: false);

      // Count guard: this capture holds exactly four <rect> elements and all
      // four are bars, so a re-capture that changed the story would otherwise
      // leave the loop below asserting nothing.
      expect(
        rects,
        hasLength(4),
        reason:
            '$storyId captured four bars; a different count means the fixture no '
            'longer describes the chart this test reads.',
      );

      // The bar values, in captured order, read off each bar's own rendered data
      // label ('10k', '40k', '25k', '20k' at the four <text> siblings of the
      // rects). They are cross-checked below: each one has to reproduce its
      // captured rect width through the domain this function returns.
      const values = <double>[10000, 40000, 25000, 20000];
      final points = <Object>[
        for (var index = 0; index < values.length; index++)
          FluentHorizontalBarChartWithAxisDataPoint(
            x: values[index],
            y: 'category $index',
          ),
      ];

      final range = domainRangeOfNumericForHorizontalBarChartWithAxis(
        points,
        const FluentChartMargins(
          // The y axis carries tick labels and the right edge carries none.
          left: kDefaultMarginWithTicks,
          right: kDefaultMarginNoTicks,
        ),
        width,
        isRtl: false,
      );

      // The captured domain path is 'M40.5,6V0.5H630.5V6': the horizontal
      // stroke runs the width of the range, offset by the half pixel that makes
      // a one-pixel line crisp.
      expect(
        range.rStartValue + crispOffset,
        closeTo(40.5, _oracleTolerance),
        reason:
            'the live axis drew its domain path from x=40.5, so utilities.ts:1453 '
            'resolved margins.left to 40.',
      );
      expect(
        range.rEndValue + crispOffset,
        closeTo(630.5, _oracleTolerance),
        reason:
            'and to x=630.5, so utilities.ts:1454 resolved containerWidth - '
            'margins.right to 630.',
      );
      expect(
        range.dStartValue,
        0,
        reason:
            'every bar is positive, so utilities.ts:1458 clamps the low end to '
            'the default x origin of zero — which is exactly where the live axis '
            'put its first tick label, at the range start.',
      );

      // The live scale is niced before it is drawn (`utilities.ts:283`, whose
      // `nice()` takes d3-scale's default count of ten,
      // `d3-scale/src/linear.js:73`). The captured ticks run 0 to 40,000, so
      // nicing must be a no-op here, which pins dEndValue at the longest bar.
      final niced = d3.nice(
        (range.dStartValue as num).toDouble(),
        (range.dEndValue as num).toDouble(),
        10,
      );
      expect(
        niced,
        <double>[0, 40000],
        reason:
            'the last captured tick label is 40,000 and it sits at the range end, '
            'so the domain the live chart scaled with was [0, 40000].',
      );

      for (var index = 0; index < rects.length; index++) {
        final rect = rects[index];
        expect(
          (rect['x'] as num).toDouble(),
          closeTo(range.rStartValue, _oracleTolerance),
          reason:
              'bar $index starts at the domain origin, which the range maps to '
              'rStartValue.',
        );
        expect(
          (rect['width'] as num).toDouble(),
          closeTo(
            _project(
                  values[index],
                  niced.first,
                  niced.last,
                  range.rStartValue,
                  range.rEndValue,
                ) -
                range.rStartValue,
            _oracleTolerance,
          ),
          reason:
              'bar $index rendered ${rect['width']}px wide for ${values[index]}, '
              'which only holds if the domain really is [0, 40000] over the '
              'range this function returned.',
        );
      }
    });

    test('reproduces the captured scatter x axis, padding included', () {
      const storyId = 'charts-scatterchart--scatter-chart-default';
      final story = _loadOracleStory(storyId);
      final width = (story['width'] as num).toDouble();
      final crispOffset = (story['crispOffset'] as num).toDouble();
      final circles = _svgElements(
        story,
      ).where((element) => element['tag'] == 'circle').toList(growable: false);

      // Count guard: eleven markers, one per data point across the three series.
      expect(
        circles,
        hasLength(11),
        reason:
            '$storyId captured eleven markers; a different count means the '
            'fixture no longer describes the chart this test reads.',
      );

      // The three series' x values, in captured marker order: one point at 75,
      // then 60 to 100, then 10 to 50. Each is checked against its own captured
      // cx below, so a misread value cannot pass.
      const xs = <double>[75, 60, 70, 80, 90, 100, 10, 20, 30, 40, 50];
      final points = <Object>[
        for (final group in <List<double>>[
          xs.sublist(0, 1),
          xs.sublist(1, 6),
          xs.sublist(6),
        ])
          FluentScatterChartSeries(
            legend: 'series ${group.first}',
            data: <FluentScatterChartDataPoint>[
              for (final x in group) FluentScatterChartDataPoint(x: x, y: 0),
            ],
          ),
      ];

      final range = domainRangeOfNumericForAreaLineScatterCharts(
        points,
        const FluentChartMargins(
          // The y axis carries both tick labels and a rotated axis title
          // (`CartesianChart.tsx:38`), so the left margin is 40 + 24.
          left: kDefaultMarginWithTicks + kHorizontalMarginForYAxisTitle,
          right: kDefaultMarginNoTicks,
        ),
        width,
        isRtl: false,
        // ScatterChart.tsx:210 passes hasMarkersMode unconditionally.
        hasMarkersMode: true,
      );

      // The captured domain path is 'M64.5,6V0.5H630.5V6'.
      expect(
        range.rStartValue + crispOffset,
        closeTo(64.5, _oracleTolerance),
        reason: 'utilities.ts:1372 — margins.left, and the live axis agrees.',
      );
      expect(
        range.rEndValue + crispOffset,
        closeTo(630.5, _oracleTolerance),
        reason: 'utilities.ts:1373 — width - margins.right.',
      );
      expect(
        range.dStartValue,
        closeTo(1, _oracleTolerance),
        reason:
            'utilities.ts:1368 pads a [10, 100] extent by a tenth of its span, so '
            'the raw domain starts at 1.',
      );
      expect(
        range.dEndValue,
        closeTo(109, _oracleTolerance),
        reason: 'and ends at 109.',
      );

      // Nicing that padded domain with d3-scale's default count of ten
      // (`utilities.ts:283`) is what produced the captured 0 and 110 tick
      // labels sitting exactly on the range ends. An unpadded [10, 100] would
      // nice to [10, 100] and no tick would land on either end, so this is the
      // assertion that the padding really happened in the live chart.
      final niced = d3.nice(
        (range.dStartValue as num).toDouble(),
        (range.dEndValue as num).toDouble(),
        10,
      );
      expect(
        niced,
        <double>[0, 110],
        reason:
            'the first and last captured tick labels are 0 and 110, and both sit '
            'on a range endpoint.',
      );

      for (var index = 0; index < circles.length; index++) {
        expect(
          (circles[index]['cx'] as num).toDouble(),
          closeTo(
            _project(
              xs[index],
              niced.first,
              niced.last,
              range.rStartValue,
              range.rEndValue,
            ),
            _oracleTolerance,
          ),
          reason:
              'marker $index rendered at cx=${circles[index]['cx']} for x='
              '${xs[index]}, which the padded and niced domain over this range '
              'reproduces.',
        );
      }
    });
  });

  group('findNumericMinMaxOfY', () {
    test('reads only the series on the requested scale', () {
      final result = findNumericMinMaxOfY(<Object>[
        _series('primary', <(Object, double)>[(1, 5), (2, 15)]),
        const FluentLineChartSeries(
          legend: 'secondary',
          useSecondaryYScale: true,
          data: <Object>[FluentLineChartDataPoint(x: 1, y: 900)],
        ),
      ]);
      expect(
        result.startValue,
        5,
        reason: 'utilities.ts:1599 compares the two flags.',
      );
      expect(
        result.endValue,
        15,
        reason:
            'the secondary series contributes nothing to the primary extent.',
      );
    });

    test('gives NaN when everything is filtered out', () {
      final result = findNumericMinMaxOfY(<Object>[
        _series('a', <(Object, double)>[(1, -5)]),
      ], scaleType: FluentAxisScaleType.log);
      expect(
        result.startValue.isNaN,
        isTrue,
        reason:
            'utilities.ts:1608-1611 asserts non-null on an empty array, which is '
            'undefined in TypeScript and NaN once it reaches arithmetic.',
      );
    });
  });

  test('findVSBCNumericMinMaxOfY takes a plain extent over y', () {
    final result = findVSBCNumericMinMaxOfY(<Object>[
      const FluentChartXYPoint(x: 'a', y: -2),
      const FluentChartXYPoint(x: 'b', y: 7),
    ]);
    expect(result.startValue, -2, reason: 'utilities.ts:1622.');
    expect(result.endValue, 7, reason: 'utilities.ts:1621.');
  });

  group('findVerticalNumericMinMaxOfY', () {
    test('includes bar values only on the primary pass', () {
      final points = <Object>[
        const FluentVerticalBarChartDataPoint(x: 'a', y: 3),
        const FluentVerticalBarChartDataPoint(x: 'b', y: 7),
      ];
      final primary = findVerticalNumericMinMaxOfY(points);
      final secondary = findVerticalNumericMinMaxOfY(
        points,
        useSecondaryYScale: true,
      );
      expect(
        primary.endValue,
        7,
        reason: 'utilities.ts:1643-1644 pushes point.y.',
      );
      expect(
        secondary.endValue.isNaN,
        isTrue,
        reason:
            'utilities.ts:1643 gates the bar push on !useSecondaryYScale alone, '
            'so the secondary pass never sees a bar value. Asymmetric, and ported '
            'as written.',
      );
    });

    test('includes line data on whichever scale it declares', () {
      final result = findVerticalNumericMinMaxOfY(<Object>[
        const FluentVerticalBarChartDataPoint(
          x: 'a',
          y: 3,
          lineData: FluentBarLineDatum(y: 40, useSecondaryYScale: true),
        ),
      ], useSecondaryYScale: true);
      expect(
        result.endValue,
        40,
        reason: 'utilities.ts:1646-1650 compares the two flags for lineData.',
      );
    });
  });

  group('findHBCWANumericMinMaxOfY', () {
    test('reads y only on a numeric axis', () {
      final points = <Object>[
        const FluentHorizontalBarChartWithAxisDataPoint(x: 10, y: 2),
        const FluentHorizontalBarChartWithAxisDataPoint(x: 20, y: 8),
      ];
      final numeric = findHBCWANumericMinMaxOfY(
        points,
        FluentChartAxisType.numeric,
      );
      expect(numeric.startValue, 2, reason: 'utilities.ts:1665-1675.');
      expect(numeric.endValue, 8, reason: 'the other end of the same extent.');
    });

    test('returns a zero extent on any other axis type', () {
      final result = findHBCWANumericMinMaxOfY(<Object>[
        const FluentHorizontalBarChartWithAxisDataPoint(x: 10, y: 2),
      ], FluentChartAxisType.category);
      expect(
        result.startValue,
        0,
        reason: 'utilities.ts:1677 returns { 0, 0 }.',
      );
      expect(result.endValue, 0, reason: 'the same zero extent.');
    });
  });

  group('the y extents against Oracle B', () {
    test('the two scales of VerticalBarChartSecondaryYAxis separate exactly as '
        'utilities.ts:1643 says they do', () {
      final story = _loadOracleStory(
        'charts-verticalbarchart--vertical-bar-secondary-y-axis',
      );
      final crispOffset = (story['crispOffset'] as num).toDouble();
      final elements = _svgElements(story);

      // Each tick label carries its tick's translate in its CTM, so the
      // fifth and sixth CTM entries are the axis position. The primary axis
      // is translated to x=64 and the secondary to x=660 in this capture.
      List<Map<String, dynamic>> axisLabels(double tx) =>
          elements
              .where(
                (e) =>
                    e['tag'] == 'text' &&
                    e['ctm'] != null &&
                    ((e['ctm'] as List<dynamic>)[4] as num).toDouble() == tx,
              )
              .toList()
            ..sort(
              (a, b) =>
                  ((b['ctm'] as List<dynamic>)[5] as num).toDouble().compareTo(
                    ((a['ctm'] as List<dynamic>)[5] as num).toDouble(),
                  ),
            );

      final primaryLabels = axisLabels(64);
      final secondaryLabels = axisLabels(660);
      expect(
        primaryLabels.length,
        5,
        reason:
            'the default y-axis tick count is four intervals, so five labels; '
            'a different count would mean this filter found the wrong texts.',
      );
      expect(
        secondaryLabels.length,
        5,
        reason: 'the secondary axis is built with the same tick count.',
      );

      // The tick CTMs include the crispness offset the axis path is drawn
      // with; the bars and the line are positioned by the raw scale, so the
      // offset comes back off before either is inverted.
      final rangeBottom =
          ((primaryLabels.first['ctm'] as List<dynamic>)[5] as num).toDouble() -
          crispOffset;
      final rangeTop =
          ((primaryLabels.last['ctm'] as List<dynamic>)[5] as num).toDouble() -
          crispOffset;
      final primaryTop = _parseAxisLabel(primaryLabels.last['text'] as String);
      final secondaryTop = _parseAxisLabel(
        secondaryLabels.last['text'] as String,
      );
      expect(
        primaryTop,
        50000,
        reason: "the topmost primary label reads '50k' in the capture.",
      );
      expect(
        secondaryTop,
        40000,
        reason: "the topmost secondary label reads '40k' in the capture.",
      );

      double valueAt(double py, double domainTop) =>
          (rangeBottom - py) / (rangeBottom - rangeTop) * domainTop;

      // The bars are the only rects sixteen pixels wide; the axis-title
      // backplates are far wider.
      final barTops = <double>[
        for (final e in elements)
          if (e['tag'] == 'rect' && (e['width'] as num).toDouble() == 16)
            (e['y'] as num).toDouble(),
      ];
      final lineTops = <double>[
        for (final e in elements)
          if (e['tag'] == 'circle') (e['cy'] as num).toDouble(),
      ];
      expect(
        barTops.length,
        8,
        reason: 'the story plots eight bars, one per category.',
      );
      expect(
        lineTops.length,
        7,
        reason: 'the overlaid line has a point on seven of the eight bars.',
      );

      final barValues = <double>[
        for (final py in barTops) valueAt(py, primaryTop),
      ];
      final lineValues = <double>[
        for (final py in lineTops) valueAt(py, secondaryTop),
      ];
      // Inverting the two captured scales must give back round data values;
      // anything else would mean the inversion, not the extent, is wrong.
      // A hundredth of a pixel inverts to under three data units here, so
      // this tolerance is far tighter than the corpus one.
      const inversionTolerance = 1e-6;
      for (final (index, expected) in <double>[
        10000,
        50000,
        30000,
        13000,
        43000,
        30000,
        20000,
        45000,
      ].indexed) {
        expect(
          barValues[index],
          closeTo(expected, inversionTolerance),
          reason:
              'bar $index is labelled ${expected ~/ 1000}k in the capture and '
              'inverts to that through the primary scale.',
        );
      }
      for (final (index, expected) in <double>[
        7000,
        30000,
        3000,
        30000,
        5000,
        16000,
        40000,
      ].indexed) {
        expect(
          lineValues[index],
          closeTo(expected, inversionTolerance),
          reason:
              'line point $index inverts to $expected through the secondary '
              'scale.',
        );
      }

      final points = <Object>[
        for (var index = 0; index < barValues.length; index++)
          FluentVerticalBarChartDataPoint(
            x: 'category $index',
            y: barValues[index],
            lineData: index < lineValues.length
                ? FluentBarLineDatum(
                    y: lineValues[index],
                    useSecondaryYScale: true,
                  )
                : null,
          ),
      ];

      final primary = findVerticalNumericMinMaxOfY(points);
      expect(
        primary.endValue,
        closeTo(primaryTop, inversionTolerance),
        reason:
            'the tallest bar fills the whole plot height, so the primary '
            'domain ends exactly at the bar extent this function returns.',
      );

      final secondary = findVerticalNumericMinMaxOfY(
        points,
        useSecondaryYScale: true,
      );
      expect(
        secondary.endValue,
        closeTo(secondaryTop, inversionTolerance),
        reason:
            'the secondary domain ends at the line extent, so the secondary '
            'pass must return the line values and nothing else.',
      );
      expect(
        secondary.endValue,
        lessThan(primary.endValue),
        reason:
            'the live implementation puts 40k at the top of the secondary '
            'axis while a 50k bar exists, which is only possible because '
            'utilities.ts:1643 keeps every bar value out of the secondary '
            'pass. The parity defect is upstream behaviour, captured here.',
      );
    });
  });
}
