import 'package:fluent_2/src/charts/axis/tick_format.dart';
import 'package:fluent_2/src/charts/axis/tick_values.dart';
import 'package:fluent_2/src/charts/model/chart_common.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';

/// The rendered y-axis tick labels of a captured story, bottom to top.
///
/// `createNumericYAxis` hands `prepareDatapoints`' output straight to
/// `yAxis.tickValues` (`utilities.ts:860-862`), so these strings are that output
/// run through `defaultYAxisTickFormatter` (`:865-875`). The numeric y axis is
/// the only end-anchored text in each story read here: `d3AxisLeft` sets
/// `text-anchor: end` on its labels, while the x axis is middle-anchored and the
/// bar value labels carry no anchor of their own.
List<String> _yAxisTickLabels(OracleStory story) => <String>[
  for (final element in story.byTag('text'))
    if (element.textAnchor == 'end') element.text!,
];

void main() {
  group('handleFloatingPointPrecisionError', () {
    test('snaps a value within 1e-6 of an integer', () {
      expect(
        handleFloatingPointPrecisionError(2.9999999),
        3,
        reason:
            'utilities.ts:651-654 — |n - round(n)| < 1e-6 snaps to the integer.',
      );
    });

    test('leaves a value outside the epsilon alone', () {
      expect(
        handleFloatingPointPrecisionError(2.99999),
        2.99999,
        reason: '1e-5 is outside the 1e-6 window at utilities.ts:653.',
      );
    });
  });

  group('isPowerOf10', () {
    test('is true at a decade', () {
      expect(
        isPowerOf10(100),
        isTrue,
        reason: 'log10(100) % 1 == 0 (utilities.ts:645-648).',
      );
      expect(isPowerOf10(1), isTrue, reason: 'log10(1) == 0.');
    });

    test('is false off a decade', () {
      expect(isPowerOf10(50), isFalse, reason: 'log10(50) % 1 == 0.69897.');
    });

    test('is false at zero and for negatives — NaN never equals 0', () {
      expect(
        isPowerOf10(0),
        isFalse,
        reason:
            'log10(0) is -Infinity, and -Infinity % 1 is NaN '
            '(utilities.ts:647).',
      );
      expect(
        isPowerOf10(-10),
        isFalse,
        reason: 'log10 of a negative is NaN, so the % 1 == 0 test fails.',
      );
    });
  });

  group('calculatePrecision', () {
    test('returns a negative precision for trailing zeros', () {
      expect(
        calculatePrecision(100),
        -2,
        reason: "utilities.ts:2541-2542 — group 1 of '100' is '00'.",
      );
      expect(calculatePrecision(20), -1, reason: "group 1 of '20' is '0'.");
    });

    test('returns a positive precision for decimals', () {
      expect(
        calculatePrecision(0.25),
        2,
        reason: "utilities.ts:2544 — group 2 of '0.25' is '25'.",
      );
      expect(calculatePrecision(0.1), 1, reason: "group 2 of '0.1' is '1'.");
    });

    test('returns 0 when neither group matches', () {
      expect(
        calculatePrecision(1),
        0,
        reason: "'1' has no trailing zeros and no decimal point.",
      );
      expect(
        calculatePrecision(7),
        0,
        reason: 'utilities.ts:2547 falls through to 0.',
      );
    });

    test('stringifies like JavaScript, not like Dart', () {
      expect(
        calculatePrecision(100.0),
        -2,
        reason:
            "Dart's 100.0.toString() is '100.0', which would match group 2 and "
            "return 1. JS String(100) is '100', so the port must strip the "
            'trailing .0 before running the regex.',
      );
    });

    test('accepts a string, as the upstream union does', () {
      expect(
        calculatePrecision('0.125'),
        3,
        reason: 'utilities.ts:2530 takes number | string.',
      );
    });
  });

  group('precisionRoundValue', () {
    test('rounds to a positive precision', () {
      expect(
        precisionRoundValue(1.2345, 2),
        1.23,
        reason: 'utilities.ts:2555-2558 — round(1.2345 * 100) / 100.',
      );
    });

    test('rounds to a negative precision', () {
      expect(
        precisionRoundValue(1234, -2),
        1200,
        reason: 'round(1234 * 0.01) / 0.01 == 12 / 0.01 == 1200.',
      );
    });

    test('rounds half-up, as JavaScript does', () {
      expect(
        precisionRoundValue(-0.5, 0),
        0,
        reason:
            'JS Math.round(-0.5) is -0, so the result is 0. Bare Dart '
            'round() would give -1 (spec section 8).',
      );
    });
  });

  group('prepareDatapoints', () {
    test('walks up from the minimum for all-positive integral data', () {
      expect(
        prepareDatapoints(100, 0, 4, isIntegralDataset: true),
        <double>[0, 25, 50, 75, 100],
        reason:
            'utilities.ts:693-694 — val = ceil(100/4) = 25; :706-711 seeds at '
            'minVal and one interval, then :719-721 walks up to maxVal.',
      );
    });

    test('anchors on zero when the data straddles it', () {
      expect(
        prepareDatapoints(90, -30, 4, isIntegralDataset: true),
        <double>[-30, 0, 30, 60, 90],
        reason:
            'utilities.ts:706 starts the array at 0, :713-717 walks down to '
            'minVal and reverses, :719-721 walks up. 0 is always a tick.',
      );
    });

    test('uses a fractional interval when the span is under splitInto', () {
      expect(
        prepareDatapoints(1, 0, 4, isIntegralDataset: false),
        <double>[0, 0.25, 0.5, 0.75, 1],
        reason:
            'utilities.ts:695-697 — a non-integral dataset with (max-min)/split '
            'below 1 keeps the fractional step.',
      );
    });

    test('ceils the interval for an integral dataset even below 1', () {
      expect(
        prepareDatapoints(1, 0, 4, isIntegralDataset: true),
        <double>[0, 1],
        reason:
            'utilities.ts:693-694 — ceil(0.25) is 1, so one interval covers the '
            'span.',
      );
    });

    test('returns a degenerate pair when min equals max', () {
      expect(
        prepareDatapoints(5, 5, 4, isIntegralDataset: true),
        <double>[5, 5],
        reason:
            'utilities.ts:710-711 — val is 0, the seed pushes minVal + 0, and '
            'the walk-up loop at :719 never runs. Two elements, not an infinite '
            'loop.',
      );
    });

    test('overshoots the maximum rather than clipping it', () {
      expect(
        prepareDatapoints(90, 0, 4, isIntegralDataset: true),
        <double>[0, 23, 46, 69, 92],
        reason:
            'val = ceil(90/4) = 23, so the last tick is 92 and the domain top is '
            'stretched past the data (utilities.ts:719-721).',
      );
    });

    test('delegates to calculateRoundedTicks when roundedTicks is set', () {
      expect(
        prepareDatapoints(
          100,
          0,
          4,
          isIntegralDataset: true,
          roundedTicks: true,
        ),
        <double>[0, 20, 40, 60, 80, 100],
        reason: 'utilities.ts:690-692 short-circuits to calculateRoundedTicks.',
      );
    });
  });

  group('calculateRoundedTicks', () {
    test('nices the extent and then asks d3 for ticks', () {
      expect(
        calculateRoundedTicks(0, 100, 4),
        <double>[0, 20, 40, 60, 80, 100],
        reason:
            'utilities.ts:666-667 — d3 nice(0,100,4) gives [0,100] and '
            'd3 ticks(0,100,4) steps by 20.',
      );
    });

    test('drops a final tick that overshoots a decade maximum', () {
      expect(
        calculateRoundedTicks(0, 10, 3).last,
        lessThanOrEqualTo(10),
        reason:
            'utilities.ts:668-670 pops the last tick when it exceeds a maxVal '
            'that is itself a power of ten.',
      );
      // The case above never actually pops: nice(0,10,3) is [0,10] and the last
      // tick lands exactly on 10. This one does. nice(-25,10,2) widens to
      // [-40,20] because the step is 20, so d3 ticks ends at 20 — above a
      // finalYmax of 10, which isPowerOf10 accepts.
      expect(
        calculateRoundedTicks(-25, 10, 2),
        <double>[-40, -20, 0],
        reason:
            'utilities.ts:668-670 — the niced top of 20 exceeds finalYmax 10 and '
            '10 is a decade, so the last tick goes. Also proves the list d3 '
            'returns is growable: d3 ticks builds it with List.filled, which is '
            'fixed-length and would throw on removeLast.',
      );
    });

    test('floors a degenerate non-negative extent at zero', () {
      expect(
        calculateRoundedTicks(5, 5, 4).first,
        0,
        reason:
            'utilities.ts:664 — minVal >= 0 and minVal == maxVal makes '
            'finalYmin 0.',
      );
    });
  });

  // Oracle B: the numeric y axis of a captured story is literally
  // prepareDatapoints' output (`utilities.ts:824` feeds `:861`), so the rendered
  // tick labels pin the whole algorithm — the straddle walk, the reversal and the
  // overshoot — against the live React implementation rather than against this
  // port's own arithmetic. Every story below has integral data, so
  // CartesianChart.tsx:66-68 makes isIntegralDataset true, and none of them sets
  // roundOffTickValues.
  group('prepareDatapoints reproduces the captured y axes', () {
    /// Asserts that [maxVal] and [minVal] regenerate story [id]'s y-axis labels.
    void expectStoryAxis(
      String id,
      double maxVal,
      double minVal,
      int expectedTickCount,
    ) {
      final labels = _yAxisTickLabels(loadOracleStory(id));
      // Count guard: without it, a re-capture that stopped recording the y axis
      // would leave both sides empty and the comparison vacuous.
      expect(
        labels,
        hasLength(expectedTickCount),
        reason:
            '$id captured $expectedTickCount end-anchored y-axis tick labels; a '
            'different count means the fixture no longer describes the axis '
            'this test reads.',
      );
      expect(
        prepareDatapoints(
          maxVal,
          minVal,
          // 4 is the yAxisTickCount default at utilities.ts:811.
          4,
          isIntegralDataset: true,
        ).map(defaultYAxisTickFormatter).toList(growable: false),
        labels,
        reason:
            '$id renders these tick labels for the domain [$minVal, $maxVal].',
      );
    }

    test('all-positive data walks up from zero', () {
      // finalYmin is min(startValue, yMinValue) and so 0 for positive-only data
      // (utilities.ts:823); finalYmax is the largest bar, 50000, which the
      // captured '12.5k'/'25k'/'37.5k' labels pin exactly.
      expectStoryAxis(
        'charts-verticalbarchart--vertical-bar-default',
        50000,
        0,
        5,
      );
    });

    test('data straddling zero anchors a tick there and overshoots', () {
      // Bars run -50000 to 43000, so val = ceil(93000/4) = 23250 and the walk
      // down from 0 overshoots to -69750 — exactly the captured bottom label.
      expectStoryAxis(
        'charts-verticalbarchart--vertical-bar-negative',
        43000,
        -50000,
        6,
      );
    });

    test('all-negative data still keeps zero as the top tick', () {
      // finalYmax stays 0 because tempVal (-10000) is not greater than
      // yMaxValue's default of 0 (utilities.ts:821-822), so the axis is
      // [-50000, 0] and val is 12500. A finalYmax of -10000 would give val
      // 10000 and a top label of '−10k', which the capture does not show.
      expectStoryAxis(
        'charts-verticalbarchart--vertical-bar-all-negative',
        0,
        -50000,
        5,
      );
    });
  });

  group('generateLinearTicks', () {
    test('emits every step inside the domain', () {
      expect(
        generateLinearTicks(0, 0.25, <double>[0, 1]),
        <double>[0, 0.25, 0.5, 0.75, 1],
        reason:
            'utilities.ts:2406-2420 — precision 2, start ceil(0), end floor(4), '
            'then tick0 + i * tickStep rounded at that precision.',
      );
    });

    test('respects an offset anchor', () {
      expect(
        generateLinearTicks(1, 3, <double>[0, 10]),
        <double>[1, 4, 7, 10],
        reason: 'start = ceil((0-1)/3) = 0, end = floor((10-1)/3) = 3.',
      );
    });

    test('is empty when no step lands inside the domain', () {
      expect(
        generateLinearTicks(0, 0.25, <double>[0.3, 0.4]),
        isEmpty,
        reason:
            'precision is 2, so start = ceil(1.2) = 2 exceeds '
            'end = floor(1.6) = 1 and the loop at utilities.ts:2416 never runs.',
      );
    });

    test('rounds the domain bounds before ceiling and flooring them', () {
      expect(
        generateLinearTicks(0, 100, <double>[10, 20]),
        <double>[0],
        reason:
            'utilities.ts:2409 takes max(precision(0), precision(100)) = '
            'max(0, -2) = 0, so :2411-2412 round 0.1 and 0.2 to 0 before '
            'ceiling and flooring. Upstream therefore emits the single tick 0, '
            'which lies outside the domain — a quirk this port reproduces '
            'rather than corrects.',
      );
    });

    test('reads the domain unordered, taking min and max', () {
      expect(
        generateLinearTicks(0, 5, <double>[10, 0]),
        <double>[0, 5, 10],
        reason:
            'utilities.ts:2407-2408 uses d3Min/d3Max, not domain[0]/domain[1].',
      );
    });
  });

  group('generateNumericTicks', () {
    test('generates linear ticks on a default scale', () {
      expect(
        generateNumericTicks(null, 25, 0, <double>[0, 100]),
        <double>[0, 25, 50, 75, 100],
        reason: 'utilities.ts:2493-2494 — the non-log branch.',
      );
    });

    test('returns null for a non-positive step', () {
      expect(
        generateNumericTicks(null, 0, 0, <double>[0, 100]),
        isNull,
        reason: 'utilities.ts:2493 requires tickStep > 0.',
      );
    });

    test('treats tick0 as 0 when it is not a number', () {
      expect(
        generateNumericTicks(null, 25, DateTime.utc(2020), <double>[0, 50]),
        <double>[0, 25, 50],
        reason: 'utilities.ts:2471 — refTick is 0 unless tick0 is a number.',
      );
    });

    test('maps a numeric step through log space on a log scale', () {
      expect(
        generateNumericTicks(FluentAxisScaleType.log, 1, 0, <double>[1, 1000]),
        <double>[1, 10, 100, 1000],
        reason:
            'utilities.ts:2474-2479 — the domain is mapped through log10, ticks '
            'are generated linearly, then raised back through 10 ** t.',
      );
    });

    test("honours the 'L<f>' step form on a log scale", () {
      expect(
        generateNumericTicks(FluentAxisScaleType.log, 'L2', 0, <double>[0, 10]),
        <double>[0, 2, 4, 6, 8, 10],
        reason:
            "utilities.ts:2482-2487 — an 'L' prefix means linear-in-value ticks "
            'even on a log scale.',
      );
    });

    test('returns null for an unrecognised string step on a log scale', () {
      expect(
        generateNumericTicks(FluentAxisScaleType.log, 'M3', 0, <double>[
          1,
          100,
        ]),
        isNull,
        reason: "utilities.ts:2490 — only the 'L' prefix is accepted here.",
      );
    });

    test('returns null for an empty string step on a log scale', () {
      expect(
        generateNumericTicks(FluentAxisScaleType.log, '', 0, <double>[1, 100]),
        isNull,
        reason:
            "utilities.ts:2483 reads tickStep[0], which is undefined for '' in "
            'JavaScript and would throw a RangeError in Dart, so the port must '
            'guard the index.',
      );
    });

    test("treats 'L' with no number as no step", () {
      expect(
        generateNumericTicks(FluentAxisScaleType.log, 'L', 0, <double>[1, 100]),
        isNull,
        reason:
            "utilities.ts:2484 — isNumber('') is false "
            '(PlotlySchemaConverter.ts:41 requires a finite parseFloat), so num '
            'is 0 and the num > 0 test at :2485 fails.',
      );
    });

    test('rejects a non-finite step, as isNumber does', () {
      expect(
        generateNumericTicks(FluentAxisScaleType.log, 'LInfinity', 0, <double>[
          1,
          100,
        ]),
        isNull,
        reason:
            'PlotlySchemaConverter.ts:41 fails isFinite, so utilities.ts:2484 '
            "yields 0. Dart's double.tryParse would happily return infinity, "
            'which would make the tick set a single degenerate value.',
      );
    });
  });

  group('generateMonthlyTicks', () {
    test('snaps a month-end anchor back to the previous month end', () {
      expect(
        generateMonthlyTicks(DateTime.utc(2020, 1, 31), 1, <DateTime>[
          DateTime.utc(2020, 1, 1),
          DateTime.utc(2020, 4, 30),
        ], useUtc: true),
        <DateTime>[
          DateTime.utc(2020, 1, 31),
          DateTime.utc(2020, 2, 29),
          DateTime.utc(2020, 3, 31),
          DateTime.utc(2020, 4, 30),
        ],
        reason:
            'utilities.ts:2450-2452 — Jan 31 plus one month rolls to Mar 2, so '
            'setDate(0) snaps it back to Feb 29 in the 2020 leap year. Apr 31 '
            'rolls to May 1 and snaps to Apr 30.',
      );
    });

    test('walks backwards from the anchor to cover the domain start', () {
      expect(
        generateMonthlyTicks(DateTime.utc(2020, 6, 1), 3, <DateTime>[
          DateTime.utc(2020, 1, 1),
          DateTime.utc(2020, 12, 31),
        ], useUtc: true),
        <DateTime>[
          DateTime.utc(2020, 3, 1),
          DateTime.utc(2020, 6, 1),
          DateTime.utc(2020, 9, 1),
          DateTime.utc(2020, 12, 1),
        ],
        reason:
            'utilities.ts:2436-2440 steps back by tickStepInMonths until the '
            'first tick is at or before the domain minimum.',
      );
    });

    test('excludes a tick before the domain minimum', () {
      expect(
        generateMonthlyTicks(DateTime.utc(2020, 6, 15), 6, <DateTime>[
          DateTime.utc(2020, 6, 1),
          DateTime.utc(2020, 12, 31),
        ], useUtc: true),
        <DateTime>[DateTime.utc(2020, 6, 15), DateTime.utc(2020, 12, 15)],
        reason:
            'utilities.ts:2454-2459 breaks above domainMax and pushes only '
            'ticks at or after domainMin, so the Dec 2019 tick the backwards '
            'walk lands on is generated and then dropped.',
      );
    });
  });

  group('generateDateTicks', () {
    test('maps every step through epoch milliseconds and back', () {
      expect(
        generateDateTicks(
          // 86400001 rather than a round 86400000: see the next test. One day
          // plus one millisecond has no trailing zeros, so calculatePrecision
          // answers 0 and the index arithmetic at utilities.ts:2412-2413
          // survives the epoch's magnitude.
          const Duration(days: 1).inMilliseconds + 1,
          DateTime.utc(2020),
          <DateTime>[DateTime.utc(2020), DateTime.utc(2020, 1, 3)],
          useUtc: true,
        ),
        <DateTime>[
          DateTime.utc(2020),
          DateTime.utc(2020, 1, 2, 0, 0, 0, 1),
          DateTime.utc(2020, 1, 3, 0, 0, 0, 2),
        ],
        reason:
            'utilities.ts:2506-2511 maps the domain to epoch ms, generates '
            'linear ticks and reads each back as a date, so the step drifts one '
            'millisecond further per tick.',
      );
    });

    test('inherits the precision collapse for a round millisecond step', () {
      expect(
        generateDateTicks(
          const Duration(days: 1).inMilliseconds,
          DateTime.utc(2020),
          <DateTime>[DateTime.utc(2020), DateTime.utc(2020, 1, 3)],
          useUtc: true,
        ),
        <DateTime>[DateTime.utc(2019, 12, 31, 23, 59, 59, 999)],
        reason:
            'Verified against a transcription of utilities.ts:2406-2421 run '
            'under node: calculatePrecision(86400000) and '
            'calculatePrecision(1577836800000) are both -5, so :2412-2413 round '
            'the index bounds 0 and 2 to a single index 0, and :2417 divides by '
            'the inexact double 1e-5 to give 1577836799999.9998, which '
            "JavaScript's Date constructor truncates to 23:59:59.999. A round "
            'millisecond step therefore yields one tick a millisecond before '
            'the anchor, not three ticks a day apart. This is upstream '
            'behaviour and is reproduced rather than corrected.',
      );
    });

    test("honours the 'M<n>' step form", () {
      expect(
        generateDateTicks('M2', DateTime.utc(2020), <DateTime>[
          DateTime.utc(2020),
          DateTime.utc(2020, 5, 1),
        ], useUtc: true),
        <DateTime>[
          DateTime.utc(2020),
          DateTime.utc(2020, 3, 1),
          DateTime.utc(2020, 5, 1),
        ],
        reason:
            'utilities.ts:2514-2519 routes an M-prefixed step to monthly ticks.',
      );
    });

    test('falls back to the UTC epoch of 2000-01-01 when tick0 is absent', () {
      final ticks = generateDateTicks(
        const Duration(days: 1).inMilliseconds,
        null,
        <DateTime>[DateTime.utc(2000), DateTime.utc(2000, 1, 2)],
        useUtc: true,
      );
      expect(
        ticks!.first,
        DateTime.utc(1999, 12, 31, 23, 59, 59, 999),
        reason:
            "utilities.ts:2504 — new Date('2000-01-01') parses as UTC midnight "
            'in JavaScript, so the port must not use DateTime.parse, which is '
            'local: in any zone but UTC that would move this value by whole '
            'hours. The millisecond below midnight is the same precision '
            'collapse as the test above, measured under node.',
      );
    });

    test('returns null for a step it cannot interpret', () {
      expect(
        generateDateTicks('L3', null, <DateTime>[
          DateTime.utc(2000),
        ], useUtc: true),
        isNull,
        reason: "utilities.ts:2517 accepts only the 'M' prefix here.",
      );
    });

    test('returns null for a fractional month step', () {
      expect(
        generateDateTicks('M1.5', DateTime.utc(2020), <DateTime>[
          DateTime.utc(2020),
          DateTime.utc(2020, 5, 1),
        ], useUtc: true),
        isNull,
        reason:
            'utilities.ts:2517 also requires num === Math.round(num), so a '
            'fractional number of months is no step at all.',
      );
    });

    test('rejects a non-finite month step, as isNumber does', () {
      expect(
        generateDateTicks('MInfinity', DateTime.utc(2020), <DateTime>[
          DateTime.utc(2020),
          DateTime.utc(2020, 5, 1),
        ], useUtc: true),
        isNull,
        reason:
            'PlotlySchemaConverter.ts:41 fails isFinite, so utilities.ts:2516 '
            "yields 0. Dart's double.tryParse returns infinity instead, which "
            'passes both tests at :2517 and then throws an UnsupportedError on '
            'infinity.toInt(), so the port must guard finiteness itself.',
      );
    });
  });
}
