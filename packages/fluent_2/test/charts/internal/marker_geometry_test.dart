import 'package:fluent_2/src/charts/internal/d3/scale_linear.dart';
import 'package:fluent_2/src/charts/internal/d3/scale_time.dart';
import 'package:fluent_2/src/charts/internal/marker_geometry.dart';
import 'package:fluent_2/src/charts/model/cartesian_series.dart';
import 'package:fluent_2/src/charts/model/line_options.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';

void main() {
  group('calculateMarkerRadius', () {
    test('falls through to default/active when no marker size is given', () {
      expect(
        calculateMarkerRadius(
          minMarkerSize: 0,
          maxMarkerSize: 40,
          extraMaxPixels: 30,
          isContinuousXY: true,
        ),
        3.5,
        reason:
            'utilities.ts:2343 returns defaultRadius when pointMarkerSize is '
            'falsy',
      );
      expect(
        calculateMarkerRadius(
          minMarkerSize: 0,
          maxMarkerSize: 40,
          extraMaxPixels: 30,
          isContinuousXY: true,
          isActive: true,
        ),
        5.5,
        reason: 'utilities.ts:2343 returns activeRadius when active',
      );
    });

    test(
      'a zero marker size is falsy in JS, so it takes the default branch',
      () {
        expect(
          calculateMarkerRadius(
            pointMarkerSize: 0,
            minMarkerSize: 0,
            maxMarkerSize: 40,
            extraMaxPixels: 30,
            isContinuousXY: true,
          ),
          3.5,
          reason:
              '`if (!pointMarkerSize)` at utilities.ts:2342 treats 0 as absent',
        );
      },
    );

    test('continuous branch scales by extraMaxPixels when max exceeds it', () {
      expect(
        calculateMarkerRadius(
          pointMarkerSize: 20,
          minMarkerSize: 0,
          maxMarkerSize: 40,
          extraMaxPixels: 30,
          isContinuousXY: true,
        ),
        15,
        reason: '(20 / 40) * 30 == 15, utilities.ts:2349',
      );
    });

    test('continuous branch passes the raw size through below the budget', () {
      expect(
        calculateMarkerRadius(
          pointMarkerSize: 7,
          minMarkerSize: 0,
          maxMarkerSize: 10,
          extraMaxPixels: 30,
          isContinuousXY: true,
        ),
        7,
        reason:
            'maxMarkerSize < extraMaxPixels returns pointMarkerSize, '
            'utilities.ts:2349',
      );
    });

    test('categorical branch normalises into [4, 16]', () {
      expect(
        calculateMarkerRadius(
          pointMarkerSize: 5,
          minMarkerSize: 0,
          maxMarkerSize: 10,
          extraMaxPixels: 0,
          isContinuousXY: false,
        ),
        10,
        reason: '4 + (5 - 0) / (10 - 0) * (16 - 4) == 10, utilities.ts:2352',
      );
    });

    test('degenerate categorical spread falls through, not divide by zero', () {
      expect(
        calculateMarkerRadius(
          pointMarkerSize: 5,
          minMarkerSize: 5,
          maxMarkerSize: 5,
          extraMaxPixels: 0,
          isContinuousXY: false,
        ),
        3.5,
        reason:
            'maxMarkerSize == minMarkerSize takes the else branch, '
            'utilities.ts:2353-2356',
      );
    });

    test('the minRadius clamp is applied last', () {
      expect(
        calculateMarkerRadius(
          pointMarkerSize: 1,
          minMarkerSize: 0,
          maxMarkerSize: 100,
          extraMaxPixels: 30,
          isContinuousXY: true,
        ),
        4,
        reason:
            '(1 / 100) * 30 == 0.3, clamped up to minRadius 4 at '
            'utilities.ts:2359',
      );
    });

    test('ScatterChart overrides the two radii but not the clamp', () {
      expect(
        calculateMarkerRadius(
          minMarkerSize: 0,
          maxMarkerSize: 0,
          extraMaxPixels: 0,
          isContinuousXY: true,
          isActive: true,
          defaultRadius: 4,
          activeRadius: 6,
        ),
        6,
        reason:
            'ScatterChart.tsx:427-428 passes defaultRadius 4 and '
            'activeRadius 6',
      );
    });
  });

  group('calculateMarkerRadius against Oracle B', () {
    test('LineChartBasic markers are all the 3.5 default radius', () {
      final story = loadOracleStory('charts-linechart--line-chart-basic');
      // The story also carries two `opacity: 0` circles at the right edge —
      // the invisible callout anchors, not markers — so the drawn markers are
      // the visible ones.
      final circles = story
          .byTag('circle')
          .where((c) => c.opacity != 0)
          .toList();
      expect(
        circles.length,
        1,
        reason:
            'LineChartBasic captures one visible marker; a different count '
            'would mean the radius below is read off the wrong element.',
      );
      for (final circle in circles) {
        expectOracleNumber(
          'LineChartBasic marker radius at cx ${circle.cx}',
          circle.r!,
          calculateMarkerRadius(
            // No `markerSize` anywhere in the story data, so upstream reaches
            // the falsy branch with both size bounds at zero.
            minMarkerSize: 0,
            maxMarkerSize: 0,
            extraMaxPixels: 0,
            isContinuousXY: true,
          ),
        );
      }
    });

    test('ScatterChartDefault reproduces all eleven continuous-branch radii', () {
      final story = loadOracleStory(
        'charts-scatterchart--scatter-chart-default',
      );
      final radii = story.byTag('circle').map((c) => c.r!).toList()..sort();
      expect(
        radii.length,
        11,
        reason:
            'ScatterChartDefault captures eleven markers across two series; '
            'the marker-size table below is indexed against that count.',
      );
      // The largest marker is the one whose `pointMarkerSize == maxMarkerSize`,
      // so upstream's `(size / max) * extraMaxPixels` collapses to
      // `extraMaxPixels` for it. Reading the budget off the story rather than
      // recomputing it keeps the remaining ten radii an independent check.
      final extraMaxPixels = radii.last;
      // Recovered from the captured radii: every one is an exact multiple of
      // `extraMaxPixels / 50`, which fixes maxMarkerSize at 50 and gives these
      // eleven integral marker sizes.
      const sizes = <double>[12, 15, 18, 22, 25, 28, 30, 32, 35, 40, 50];
      for (var i = 0; i < sizes.length; i++) {
        expectOracleNumber(
          'ScatterChartDefault radius for markerSize ${sizes[i]}',
          radii[i],
          calculateMarkerRadius(
            pointMarkerSize: sizes[i],
            minMarkerSize: sizes.first,
            maxMarkerSize: sizes.last,
            extraMaxPixels: extraMaxPixels,
            isContinuousXY: true,
          ),
        );
      }
    });

    test('ScatterChartLogAxis shows the minRadius floor in real output', () {
      final story = loadOracleStory(
        'charts-scatterchart--scatter-chart-log-axis-example',
      );
      final radii = story.byTag('circle').map((c) => c.r!).toList();
      expect(
        radii.length,
        30,
        reason:
            'ScatterChartLogAxis captures thirty markers; the floor count '
            'below is meaningless without it.',
      );
      expect(
        radii.every((r) => r >= 4),
        isTrue,
        reason:
            'No captured radius may fall below minRadius, utilities.ts:2359',
      );
      expect(
        radii.where((r) => r == 4).length,
        4,
        reason:
            'Four markers sit exactly on the floor, i.e. off the linear ramp '
            'the other twenty-six lie on.',
      );
      // 24 is the largest marker size, recovered the same way as above: every
      // unclamped radius is an exact multiple of `maxRadius / 24`.
      final maxRadius = radii.reduce((a, b) => a > b ? a : b);
      expectOracleNumber(
        'a size-13 marker on the ramp',
        7.460466,
        calculateMarkerRadius(
          pointMarkerSize: 13,
          minMarkerSize: 1,
          maxMarkerSize: 24,
          extraMaxPixels: maxRadius,
          isContinuousXY: true,
        ),
      );
      expect(
        calculateMarkerRadius(
          pointMarkerSize: 6,
          minMarkerSize: 1,
          maxMarkerSize: 24,
          extraMaxPixels: maxRadius,
          isContinuousXY: true,
        ),
        4,
        reason:
            'A size-6 marker computes to 3.44 px on the same ramp and is '
            'clamped to the captured floor of 4.',
      );
    });
  });

  group('getRangeForScatterMarkerSize', () {
    test('takes the smaller of the x and y padding budgets', () {
      final series = <Object>[
        const FluentScatterChartSeries(
          legend: 'A',
          data: <FluentScatterChartDataPoint>[
            FluentScatterChartDataPoint(x: 0, y: 0),
            FluentScatterChartDataPoint(x: 10, y: 20),
          ],
        ),
      ];
      // x padding is ten per cent of [0, 10], i.e. 1 domain unit, and the scale
      // is 10 px per unit, so the x budget is 10 px. y padding is 2 units on a
      // scale of 200 px over 24 units, i.e. 16.67 px.
      final xScale = scaleLinear()
        ..domainOf(<double>[-1, 11])
        ..rangeOf(<double>[0, 120]);
      final yScale = scaleLinear()
        ..domainOf(<double>[-2, 22])
        ..rangeOf(<double>[200, 0]);
      expect(
        getRangeForScatterMarkerSize(
          points: series,
          xScale: xScale,
          yScalePrimary: yScale,
        ),
        closeTo(10, kOracleGeometryTolerance),
        reason:
            'Math.min(10, 16.67) == 10 — the x axis is the tighter budget, '
            'utilities.ts:2403',
      );
    });

    test('a date x axis pads in milliseconds and re-wraps as a DateTime', () {
      final start = DateTime.fromMillisecondsSinceEpoch(0);
      final end = DateTime.fromMillisecondsSinceEpoch(10000);
      final series = <Object>[
        FluentScatterChartSeries(
          legend: 'A',
          data: <FluentScatterChartDataPoint>[
            FluentScatterChartDataPoint(x: start, y: 0),
            FluentScatterChartDataPoint(x: end, y: 100),
          ],
        ),
      ];
      // 1000 ms of padding each side on a scale of 120 px per 12000 ms is 10 px.
      final xScale = scaleTime()
        ..domainOfDates(<DateTime>[
          DateTime.fromMillisecondsSinceEpoch(-1000),
          DateTime.fromMillisecondsSinceEpoch(11000),
        ])
        ..rangeOf(<double>[0, 120]);
      // y padding is 10 units on a scale of 1 px per unit, i.e. 10 px, so the
      // two budgets tie and the DateTime arm is what is under test.
      final yScale = scaleLinear()
        ..domainOf(<double>[-10, 110])
        ..rangeOf(<double>[120, 0]);
      expect(
        getRangeForScatterMarkerSize(
          points: series,
          xScale: xScale,
          yScalePrimary: yScale,
        ),
        closeTo(10, kOracleGeometryTolerance),
        reason:
            'The DateTime arm at utilities.ts:2394-2395 must pad in epoch '
            'milliseconds, not throw on the Date operand',
      );
    });

    test('empty data yields no budget rather than throwing', () {
      expect(
        getRangeForScatterMarkerSize(
          points: const <Object>[],
          xScale: scaleLinear(),
          yScalePrimary: scaleLinear(),
        ),
        0,
        reason:
            'getScatterXDomainExtent returns a pair of nulls, and with no '
            'points there is no marker to size',
      );
    });
  });

  group('mode predicates', () {
    test('isTextMode wants the exact string "text", not a superset', () {
      expect(
        isTextMode(<Object>[
          const FluentLineOptions(
            mode: FluentLineMode(lines: false, text: true),
          ),
        ]),
        isTrue,
        reason: 'utilities.ts:2219 matches mode === "text" exactly',
      );
      expect(
        isTextMode(<Object>[
          const FluentLineOptions(
            mode: FluentLineMode(lines: true, text: true),
          ),
        ]),
        isFalse,
        reason: '"lines+text" is not the literal "text" at utilities.ts:2219',
      );
    });

    test('lineModeDrawsLines is false only for the exact string "markers"', () {
      expect(
        lineModeDrawsLines(const FluentLineMode(lines: false, markers: true)),
        isFalse,
        reason: 'LineChart.tsx:698 tests lineMode !== "markers"',
      );
      expect(
        lineModeDrawsLines(
          const FluentLineMode(lines: false, markers: true, text: true),
        ),
        isTrue,
        reason: '"markers+text" is not the literal "markers"',
      );
      expect(
        lineModeDrawsLines(null),
        isTrue,
        reason: 'an absent mode never equals "markers"',
      );
    });
  });
}
