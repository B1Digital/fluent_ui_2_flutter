import 'package:fluent_2/src/charts/horizontal_bar_chart.dart';
import 'package:fluent_2/src/charts/model/bar_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// Two upstream defects meet in this arithmetic and partly cancel.
///
/// 1. `noOfBars` counts points whose `point.data` — the **benchmark** field,
///    not the bar value — exceeds zero (`HorizontalBarChart.tsx:219-221`). For
///    ordinary data every `point.data` is null, the reduce returns 0, and
///    `0 || 1` makes `noOfBars` 1, so `totalMarginPercent` is 0.
/// 2. The scaling is a **division** by `(sumOfPercent - totalMarginPercent) /
///    100` (`:262`, `:276`), which grows the bars when the margin is non-zero
///    instead of shrinking them as the comment at `:254-261` intends.
///
/// With defect 1 in play the margin is 0, the division degenerates to
/// `v * 100 / sum`, and the bars sum to exactly 100% — plus `(n-1) * 3` px of
/// gap that nothing subtracted, which is the visible overflow.
void main() {
  FluentChartDataPoint point(double x, {double? benchmark}) =>
      FluentChartDataPoint(
        legend: 'x$x',
        data: benchmark,
        horizontalBarChartData: FluentHorizontalDataPoint(x: x, total: 100),
      );

  group('the gap overflows the row by (n-1) * 3 px', () {
    final layout = FluentHorizontalBarRowLayout.compute(
      points: <FluentChartDataPoint>[point(30), point(40), point(30)],
      rowWidth: 400,
      barGap: 3,
      isRtl: false,
    );

    test('the gap is expressed as a percentage of the row width', () {
      expect(
        layout.gapPercent,
        closeTo(0.75, 1e-12),
        reason:
            'HorizontalBarChart.tsx:366 is (3 / svgWidth) * 100, and '
            '3 / 400 * 100 is 0.75.',
      );
    });

    test('noOfBars is 1 so no margin is subtracted', () {
      expect(
        layout.scalingRatio,
        closeTo(1, 1e-12),
        reason:
            'HorizontalBarChart.tsx:262 — sumOfPercent is 100 and '
            'totalMarginPercent is 0 because :219-221 counts point.data, which '
            'is null for ordinary data.',
      );
    });

    test('bar x positions are 0, 123 and 286 pixels', () {
      final xs = <double>[
        for (var i = 0; i < 3; i++) layout.rectOf(i, 12).left,
      ];
      expect(
        xs,
        <Matcher>[closeTo(0, 1e-9), closeTo(123, 1e-9), closeTo(286, 1e-9)],
        reason:
            'HorizontalBarChart.tsx:312 is '
            '`startingPoint[i] + i * barSpacingInPercent`, so the third bar '
            'starts at (70 + 1.5)% of 400.',
      );
    });

    test('the last bar ends six pixels outside the 400px row', () {
      // parity: HorizontalBarChart.tsx:222 computes a margin allowance the
      // noOfBars defect always makes 0, and the svg is overflow: visible
      // (useHorizontalBarChartStyles.styles.ts:49), so nothing clips it.
      expect(
        layout.rectOf(2, 12).right,
        closeTo(406, 1e-9),
        reason:
            'Three bars of 120, 160 and 120 plus two 3px gaps is 406 in a '
            '400px box — the (n-1) * 3 overflow the design spec names in '
            'section 5.2.',
      );
    });

    test('widths are 120, 160 and 120 pixels', () {
      expect(
        <double>[for (var i = 0; i < 3; i++) layout.rectOf(i, 12).width],
        <Matcher>[closeTo(120, 1e-9), closeTo(160, 1e-9), closeTo(120, 1e-9)],
        reason: r'HorizontalBarChart.tsx:315 sets width to `${value}%`.',
      );
    });
  });

  group('the sub-1% clamp and the stale-value accumulator', () {
    final layout = FluentHorizontalBarRowLayout.compute(
      points: <FluentChartDataPoint>[point(1), point(1), point(998)],
      rowWidth: 400,
      barGap: 3,
      isRtl: false,
    );

    test('pass one clamps each sub-1% share up to a flat 1', () {
      expect(
        layout.sumOfPercent,
        closeTo(101.8, 1e-9),
        reason:
            'HorizontalBarChart.tsx:243-249 — 0.1 and 0.1 both clamp to 1, '
            'and 99.8 passes through, so 1 + 1 + 99.8 is 101.8.',
      );
      expect(
        layout.scalingRatio,
        closeTo(1.018, 1e-12),
        reason: 'HorizontalBarChart.tsx:262 — (101.8 - 0) / 100.',
      );
    });

    test('pass two divides the clamp by the scaling ratio', () {
      expect(
        layout.segments.map((s) => s.widthPercent).toList(),
        <Matcher>[
          closeTo(0.9823182711198428, 1e-12),
          closeTo(0.9823182711198428, 1e-12),
          closeTo(98.03536345776031, 1e-12),
        ],
        reason:
            'HorizontalBarChart.tsx:274 uses `1 / scalingRatio` for the '
            'clamped points and :276 uses `value / scalingRatio` for the rest.',
      );
    });

    test('startingPoint lags by one iteration', () {
      expect(
        layout.segments.map((s) => s.startPercent).toList(),
        <Matcher>[
          closeTo(0, 1e-12),
          closeTo(0.9823182711198428, 1e-12),
          closeTo(1.9646365422396856, 1e-12),
        ],
        reason:
            "HorizontalBarChart.tsx:267-270 adds the PREVIOUS iteration's "
            'value through a closure variable before recomputing it, so the '
            'accumulator is always one step behind.',
      );
    });
  });

  test(
    'a negative share becomes zero and does not advance the accumulator',
    () {
      final layout = FluentHorizontalBarRowLayout.compute(
        points: <FluentChartDataPoint>[point(-5), point(100)],
        rowWidth: 400,
        barGap: 3,
        isRtl: false,
      );
      expect(
        layout.segments[0].widthPercent,
        closeTo(0, 1e-12),
        reason: 'HorizontalBarChart.tsx:271-272 zeroes a negative share.',
      );
      expect(
        layout.segments[1].startPercent,
        closeTo(0, 1e-12),
        reason:
            'The accumulator adds the previous value, which was zero, so the '
            'second bar starts at the origin too.',
      );
      expect(
        layout.segments[1].widthPercent,
        closeTo(100, 1e-9),
        reason:
            'The total is 95, so 100 is 105.263% before scaling and exactly '
            '100% after dividing by the ratio 1.0526315789473684.',
      );
    },
  );

  test(
    'a share of exactly one percent takes the else branch, not the clamp',
    () {
      final layout = FluentHorizontalBarRowLayout.compute(
        points: <FluentChartDataPoint>[point(1), point(99)],
        rowWidth: 400,
        barGap: 3,
        isRtl: false,
      );
      expect(
        layout.sumOfPercent,
        closeTo(100, 1e-12),
        reason:
            'HorizontalBarChart.tsx:246 is `value < 1 && value !== 0`, so a '
            'value of exactly 1.0 is not clamped.',
      );
      expect(
        layout.segments[0].widthPercent,
        closeTo(1, 1e-12),
        reason: 'A ratio of 1 leaves the value untouched.',
      );
    },
  );

  test('a benchmark value activates noOfBars and grows the bars', () {
    final layout = FluentHorizontalBarRowLayout.compute(
      points: <FluentChartDataPoint>[
        point(30, benchmark: 1),
        point(40, benchmark: 1),
        point(30, benchmark: 1),
      ],
      rowWidth: 400,
      barGap: 3,
      isRtl: false,
    );
    expect(
      layout.scalingRatio,
      closeTo(0.985, 1e-12),
      reason:
          'HorizontalBarChart.tsx:262 — (100 - 2 * 0.75) / 100 once '
          'noOfBars is 3.',
    );
    // parity: dividing by a ratio below 1 GROWS the bars, the opposite of the
    // intent stated in the comment at HorizontalBarChart.tsx:254-261.
    expect(
      layout.segments[1].widthPercent,
      closeTo(40.60913705583756, 1e-12),
      reason:
          'HorizontalBarChart.tsx:276 divides rather than multiplies, so '
          'making room for the gaps makes the bars wider, not narrower.',
    );
  });

  test('right-to-left mirrors the x expression, gaps included', () {
    final layout = FluentHorizontalBarRowLayout.compute(
      points: <FluentChartDataPoint>[point(30), point(40), point(30)],
      rowWidth: 400,
      barGap: 3,
      isRtl: true,
    );
    expect(
      <double>[for (var i = 0; i < 3; i++) layout.rectOf(i, 12).left],
      <Matcher>[closeTo(280, 1e-9), closeTo(117, 1e-9), closeTo(-6, 1e-9)],
      reason:
          'HorizontalBarChart.tsx:311 is '
          '`100 - startingPoint[i] - value - i * barSpacingInPercent`, so the '
          'overflow moves to the leading edge.',
    );
  });

  test(
    'a zero total leaves every bar at zero width without dividing by zero',
    () {
      final layout = FluentHorizontalBarRowLayout.compute(
        points: <FluentChartDataPoint>[point(0), point(0)],
        rowWidth: 400,
        barGap: 3,
        isRtl: false,
      );
      expect(
        layout.scalingRatio,
        closeTo(1, 1e-12),
        reason:
            'HorizontalBarChart.tsx:262 guards sumOfPercent !== 0 and '
            'returns 1.',
      );
      expect(
        layout.segments.map((s) => s.widthPercent),
        everyElement(closeTo(0, 1e-12)),
        reason:
            'HorizontalBarChart.tsx:242 reads `x ? x : 0`, so a zero x is a '
            'zero share; 0 / 0 is NaN in JavaScript too, but the falsy guard '
            'never lets it through.',
      );
    },
  );

  group('oracle B: the captured rows overflow their own svg', () {
    // Every HorizontalBarChart story whose rects sum to 100% of the row, which
    // is every one except the absolute-scale variant — there the placeholder
    // point renders as a <text> (`HorizontalBarChart.tsx:283-303`) rather than
    // a second rect, so its rect widths alone do not reconstruct the input.
    const storyIds = <String>[
      'charts-horizontalbarchart--horizontal-bar-basic',
      'charts-horizontalbarchart--horizontal-bar-benchmark',
      'charts-horizontalbarchart--horizontal-bar-stacked',
      'charts-horizontalbarchart--horizontal-bar-stacked-annotated-inline-legend',
    ];

    // `MARGIN_WIDTH_IN_PX` (`HorizontalBarChart.tsx:364`).
    const barGap = 3.0;

    test('every named story is in the corpus', () {
      expect(
        oracleStoryIds(component: 'HorizontalBarChart').toSet(),
        containsAll(storyIds),
        reason:
            'The loops below skip silently if a story id drifts; this guard '
            'is what fails instead.',
      );
    });

    for (final storyId in storyIds) {
      test('$storyId reproduces every rect x and width', () {
        final story = loadOracleStory(storyId);
        expect(
          story.svgs,
          isNotEmpty,
          reason: '$storyId must have captured at least one row svg.',
        );
        var rowsChecked = 0;
        for (final svg in story.svgs) {
          final rects = svg.elements
              .where((element) => element.tag == 'rect')
              .toList();
          expect(
            rects,
            isNotEmpty,
            reason: 'Every $storyId row draws at least one bar.',
          );
          // Upstream writes `x` and `width` as percentage strings
          // (`HorizontalBarChart.tsx:309-315`), so the captured attribute is
          // the share itself and the bbox is that share resolved against the
          // svg width.
          final shares = <double>[
            for (final rect in rects) rect.width ?? double.nan,
          ];
          expectOracleNumber(
            '$storyId row $rowsChecked: the shares sum to 100',
            100,
            shares.fold<double>(0, (sum, share) => sum + share),
          );

          // The scaling ratio is 1 for every captured row, so each share is
          // also the point's percentage of the total: feeding the shares back
          // in as x values with a total of 100 reconstructs the input exactly.
          final layout = FluentHorizontalBarRowLayout.compute(
            points: <FluentChartDataPoint>[
              for (final share in shares)
                FluentChartDataPoint(
                  horizontalBarChartData: FluentHorizontalDataPoint(
                    x: share,
                    total: 100,
                  ),
                ),
            ],
            rowWidth: svg.width,
            barGap: barGap,
            isRtl: false,
          );
          expectOracleNumber(
            '$storyId row $rowsChecked: the scaling ratio is 1',
            1,
            layout.scalingRatio,
          );
          for (var i = 0; i < rects.length; i++) {
            expectOracleNumber(
              '$storyId row $rowsChecked rect $i: x percent',
              rects[i].x ?? double.nan,
              layout.segments[i].xPercent,
            );
            expectOracleNumber(
              '$storyId row $rowsChecked rect $i: width percent',
              rects[i].width ?? double.nan,
              layout.segments[i].widthPercent,
            );
            expectOracleRect(
              '$storyId row $rowsChecked rect $i: painted pixels',
              rects[i].bbox!,
              layout.rectOf(i, rects[i].height ?? 12),
            );
          }

          // The <g> bbox is the union of the painted rects, so its right edge
          // is the overflow itself: `(n - 1) * 3` px past the svg for any row
          // whose last bar has width. A zero-width rect has an empty bbox and
          // Chromium leaves it out of the union, so it is excluded here too.
          final group = svg.elements.singleWhere(
            (element) => element.tag == 'g',
          );
          var paintedRight = 0.0;
          for (var i = 0; i < rects.length; i++) {
            final painted = layout.rectOf(i, rects[i].height ?? 12);
            if (painted.width > 0 && painted.right > paintedRight) {
              paintedRight = painted.right;
            }
          }
          expectOracleNumber(
            '$storyId row $rowsChecked: the group overflows to',
            group.bbox!.right,
            paintedRight,
          );
          rowsChecked++;
        }
        expect(
          rowsChecked,
          story.svgs.length,
          reason: 'Every captured row of $storyId must have been asserted.',
        );
      });
    }

    test('the three-bar row overflows its 600px svg by exactly six pixels', () {
      final story = loadOracleStory(
        'charts-horizontalbarchart--horizontal-bar-stacked',
      );
      final svg = story.svgs.firstWhere(
        (candidate) =>
            candidate.elements.where((e) => e.tag == 'rect').length == 3,
      );
      final group = svg.elements.singleWhere((element) => element.tag == 'g');
      expect(
        group.bbox!.right - svg.width,
        closeTo(2 * barGap, kOracleGeometryTolerance),
        reason:
            'Chromium measured the bar group at ${group.bbox!.right}px inside '
            'a ${svg.width}px svg — the (n - 1) * 3 overflow, unclipped '
            'because useHorizontalBarChartStyles.styles.ts:49 is '
            "`overflow: 'visible'`.",
      );
    });
  });
}
