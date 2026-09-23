import 'package:fluent_2/src/charts/horizontal_bar_chart.dart';
import 'package:fluent_2/src/charts/model/bar_data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// Two upstream defects meet in this arithmetic, and the port fixes both.
///
/// 1. `noOfBars` counts points whose `point.data` — the **benchmark** field,
///    not the bar value — exceeds zero (`HorizontalBarChart.tsx:219-221`). For
///    ordinary data every `point.data` is null, the reduce returns 0, and
///    `0 || 1` makes `noOfBars` 1, so `totalMarginPercent` is 0.
/// 2. The scaling is a **division** by `(sumOfPercent - totalMarginPercent) /
///    100` (`:262`, `:276`), which grows the bars when the margin is non-zero
///    instead of shrinking them as the comment at `:254-261` intends.
///
/// Upstream's bars therefore sum to exactly 100%, plus `(n-1) * 3` px of gap
/// that nothing subtracted, which is the visible overflow. The port counts the
/// bars that paint and divides by `sumOfPercent / (100 - totalMarginPercent)`,
/// so the bars and their gaps fill the row exactly.
void main() {
  FluentChartDataPoint point(double x, {double? benchmark}) =>
      FluentChartDataPoint(
        legend: 'x$x',
        data: benchmark,
        horizontalBarChartData: FluentHorizontalDataPoint(x: x, total: 100),
      );

  // Issue #36: upstream, and the port before it, painted this row at 0-120,
  // 123-283 and 286-406 in LTR, and from -6 under RTL.
  group('three bars and two 3px gaps fit the 400px row', () {
    FluentHorizontalBarRowLayout layout({bool isRtl = false}) =>
        FluentHorizontalBarRowLayout.compute(
          points: <FluentChartDataPoint>[point(30), point(40), point(30)],
          rowWidth: 400,
          barGap: 3,
          isRtl: isRtl,
        );

    test('the gap is expressed as a percentage of the row width', () {
      expect(
        layout().gapPercent,
        closeTo(0.75, 1e-12),
        reason:
            'HorizontalBarChart.tsx:366 is (3 / svgWidth) * 100, and '
            '3 / 400 * 100 is 0.75.',
      );
    });

    test('the bars shrink into the 98.5% the two gaps leave', () {
      expect(
        layout().scalingRatio,
        closeTo(100 / 98.5, 1e-12),
        reason:
            'sumOfPercent is 100 and the three bars have two 0.75% gaps. '
            'HorizontalBarChart.tsx:262 divides by (100 - 0) / 100 = 1, '
            'because :219-221 counts point.data, which is null here.',
      );
    });

    test('widths are 118.2, 157.6 and 118.2 pixels', () {
      expect(
        <double>[for (var i = 0; i < 3; i++) layout().rectOf(i, 12).width],
        <Matcher>[
          closeTo(118.2, 1e-9),
          closeTo(157.6, 1e-9),
          closeTo(118.2, 1e-9),
        ],
        reason: '120, 160 and 120, scaled by 394 / 400 to make room for 6px.',
      );
    });

    for (final isRtl in <bool>[false, true]) {
      test('every bar lies inside the row, 3px apart (rtl: $isRtl)', () {
        final rects = <Rect>[
          for (var i = 0; i < 3; i++) layout(isRtl: isRtl).rectOf(i, 12),
        ];
        // Data order runs from the leading edge.
        final ordered = isRtl ? rects.reversed.toList() : rects;
        expect(ordered.first.left, closeTo(0, 1e-9), reason: '$rects');
        expect(
          ordered.last.right,
          closeTo(400, 1e-9),
          reason:
              'HorizontalBarChart.tsx:311-312 ends this row at 406, or starts '
              'it at -6 under RTL: $rects',
        );
        for (var i = 1; i < 3; i++) {
          expect(
            ordered[i].left - ordered[i - 1].right,
            closeTo(3, 1e-9),
            reason: 'MARGIN_WIDTH_IN_PX (HorizontalBarChart.tsx:364): $rects',
          );
        }
      });
    }
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
        closeTo(101.8 / 98.5, 1e-12),
        reason:
            'The clamped sum over the 98.5% that two 0.75% gaps leave; '
            'HorizontalBarChart.tsx:262 is (101.8 - 0) / 100.',
      );
    });

    test('pass two divides the clamp by the scaling ratio', () {
      expect(
        layout.segments.map((s) => s.widthPercent).toList(),
        <Matcher>[
          closeTo(0.9675834970530451, 1e-12),
          closeTo(0.9675834970530451, 1e-12),
          closeTo(96.5648330058939, 1e-12),
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
          closeTo(0.9675834970530451, 1e-12),
          closeTo(1.9351669941060903, 1e-12),
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
      expect(
        layout.segments[1].xPercent,
        closeTo(0, 1e-12),
        reason:
            'The zeroed bar paints nothing, so no gap follows it. '
            'HorizontalBarChart.tsx:312 offsets by `index * '
            'barSpacingInPercent` and pushes this bar 3px past the row.',
      );
    },
  );

  test('a row narrower than its gaps paints zero-width bars', () {
    final layout = FluentHorizontalBarRowLayout.compute(
      points: <FluentChartDataPoint>[point(30), point(40), point(30)],
      rowWidth: 4,
      barGap: 3,
      isRtl: false,
    );
    expect(
      layout.segments.map((s) => s.widthPercent),
      everyElement(closeTo(0, 1e-12)),
      reason:
          'Two 3px gaps take 150% of a 4px row, which leaves the bars no '
          'room. A negative width would reach Positioned.fromRect.',
    );
  });

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
        closeTo(0.9925, 1e-12),
        reason: 'The value scaled into the 99.25% that one 0.75% gap leaves.',
      );
    },
  );

  test('a benchmark value leaves the bar geometry alone', () {
    List<FluentHorizontalBarSegment> segments({double? benchmark}) =>
        FluentHorizontalBarRowLayout.compute(
          points: <FluentChartDataPoint>[
            point(30, benchmark: benchmark),
            point(40, benchmark: benchmark),
            point(30, benchmark: benchmark),
          ],
          rowWidth: 400,
          barGap: 3,
          isRtl: false,
        ).segments;
    expect(
      segments(benchmark: 1),
      segments(),
      reason:
          'HorizontalBarChart.tsx:219-221 counts bars from point.data, the '
          'benchmark field, so a benchmark on every point switched the margin '
          'on and, through the division at :276, grew the middle bar to '
          '40.609%. The port counts the bars that paint.',
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
      <Matcher>[closeTo(281.8, 1e-9), closeTo(121.2, 1e-9), closeTo(0, 1e-9)],
      reason:
          'HorizontalBarChart.tsx:311 is '
          '`100 - startingPoint[i] - value - i * barSpacingInPercent`, which '
          'puts the last bar at -6; shrunk to fit, it starts at the edge.',
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

  group('oracle B: the captured rows, fitted inside their own svg', () {
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
      test('$storyId keeps every rect, gap and proportion', () {
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

          // Upstream paints the bars at their full shares and lets the gaps
          // run past the svg; the port shrinks the painted bars, all by one
          // factor, into the room the gaps leave. So every captured rect maps
          // onto the port's with its start and width scaled and the 3px gaps
          // before it kept. A zero-width rect paints nothing and takes no gap.
          final painted = rects.where((rect) => rect.bbox!.width > 0).length;
          final shrink = (svg.width - (painted - 1) * barGap) / svg.width;
          var gaps = 0;
          var paintedRight = 0.0;
          for (var i = 0; i < rects.length; i++) {
            final captured = rects[i].bbox!;
            final actual = layout.rectOf(i, rects[i].height ?? 12);
            expectOracleRect(
              '$storyId row $rowsChecked rect $i: painted pixels, fitted',
              Rect.fromLTWH(
                (captured.left - i * barGap) * shrink + gaps * barGap,
                captured.top,
                captured.width * shrink,
                captured.height,
              ),
              actual,
            );
            if (captured.width > 0) {
              gaps++;
              if (actual.right > paintedRight) paintedRight = actual.right;
            }
          }

          // The <g> bbox is the union of the painted rects, so its right edge
          // is upstream's overflow: `(n - 1) * 3` px past the svg for any row
          // whose last bar has width. The port's row ends at the edge.
          final group = svg.elements.singleWhere(
            (element) => element.tag == 'g',
          );
          expectOracleNumber(
            '$storyId row $rowsChecked: the row ends at the svg edge, where '
            'upstream overflows to ${group.bbox!.right}',
            svg.width,
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

    test('the three-bar row upstream overflows by six pixels fits its svg', () {
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
      final layout = FluentHorizontalBarRowLayout.compute(
        points: <FluentChartDataPoint>[
          for (final rect in svg.elements.where((e) => e.tag == 'rect'))
            FluentChartDataPoint(
              horizontalBarChartData: FluentHorizontalDataPoint(
                x: rect.width!,
                total: 100,
              ),
            ),
        ],
        rowWidth: svg.width,
        barGap: barGap,
        isRtl: false,
      );
      expect(
        layout.rectOf(2, 12).right,
        closeTo(svg.width, 1e-9),
        reason: 'The port makes room for both gaps inside the svg.',
      );
    });
  });
}
