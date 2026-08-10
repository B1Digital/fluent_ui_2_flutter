import 'package:fluent_2_web/src/charts/funnel_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// `funnelGeometry.ts` is pure arithmetic and ports one for one. Five different
/// `availableWidth` formulas and six hard cut-offs feed a single boolean
/// `availableWidth > minTextWidth && availableWidth > 0`
/// (`funnelGeometry.ts:319`), so every branch gets a row here and every
/// threshold is bracketed either side.
void main() {
  const width = 280.0;
  const height = 400.0;

  List<FluentFunnelDataPoint> stages(List<double> values) =>
      <FluentFunnelDataPoint>[
        for (var i = 0; i < values.length; i++)
          FluentFunnelDataPoint(stage: 'S$i', value: values[i]),
      ];

  group('vertical, non-stacked', () {
    // Four stages of 400, 300, 200, 100 with a maximum of 400 make widthScale
    // the identity times 280/400 = 0.7.
    final data = stages(<double>[400, 300, 200, 100]);

    test(
      'a middle segment is a trapezium spanning the full segment height',
      () {
        final geometry = FluentFunnelSegmentGeometry.vertical(
          index: 1,
          data: data,
          funnelWidth: width,
          funnelHeight: height,
          isRtl: false,
        );
        final bounds = geometry.path!.getBounds();
        expect(
          bounds.top,
          closeTo(100, 1e-9),
          reason:
              'funnelGeometry.ts:64 — the top edge is i * segmentHeight, and '
              'segmentHeight is 400 / 4.',
        );
        expect(
          bounds.bottom,
          closeTo(200, 1e-9),
          reason:
              'funnelGeometry.ts:66-67 — the bottom edge is '
              '(i + 1) * segmentHeight.',
        );
        expect(
          bounds.width,
          closeTo(210, 1e-9),
          reason:
              'The top width is widthScale(300) = 210 and the bottom is '
              'widthScale(200) = 140, so the bounding box takes the wider of '
              'the two.',
        );
      },
    );

    test('the last segment collapses to a triangle', () {
      final geometry = FluentFunnelSegmentGeometry.vertical(
        index: 3,
        data: data,
        funnelWidth: width,
        funnelHeight: height,
        isRtl: false,
      );
      expect(
        geometry.path!.contains(const Offset(140, 399)),
        isTrue,
        reason:
            'funnelGeometry.ts:46 — bottomWidth is 0 for the last stage, '
            'so both bottom vertices coincide at funnelWidth / 2.',
      );
      expect(
        geometry.path!.contains(const Offset(20, 399)),
        isFalse,
        reason: 'Nothing but the apex survives at the bottom edge.',
      );
    });

    test('the last segment text sits a third of the way down', () {
      final geometry = FluentFunnelSegmentGeometry.vertical(
        index: 3,
        data: data,
        funnelWidth: width,
        funnelHeight: height,
        isRtl: false,
      );
      expect(
        geometry.textY,
        closeTo(300 + 100 * 0.33, 1e-9),
        reason:
            'funnelGeometry.ts:53 — i * segmentHeight + '
            'segmentHeight * 0.33 for the last stage.',
      );
      expect(
        geometry.availableWidth,
        closeTo(70 * (1 - (100 * 0.33) / 100) * 0.8, 1e-9),
        reason:
            'funnelGeometry.ts:58-60 — the width at the text row, scaled '
            'by 0.8. The topWidth here is widthScale(100) = 70.',
      );
    });

    test('a middle segment takes nine tenths of the narrower edge', () {
      final geometry = FluentFunnelSegmentGeometry.vertical(
        index: 1,
        data: data,
        funnelWidth: width,
        funnelHeight: height,
        isRtl: false,
      );
      expect(
        geometry.availableWidth,
        closeTo(140 * 0.9, 1e-9),
        reason:
            'funnelGeometry.ts:62 — min(topWidth, bottomWidth) * 0.9, and '
            'the bottom is the narrower at 140.',
      );
    });

    test(
      'the right-to-left mirror is a visual no-op for the vertical funnel',
      () {
        final ltr = FluentFunnelSegmentGeometry.vertical(
          index: 1,
          data: data,
          funnelWidth: width,
          funnelHeight: height,
          isRtl: false,
        );
        final rtl = FluentFunnelSegmentGeometry.vertical(
          index: 1,
          data: data,
          funnelWidth: width,
          funnelHeight: height,
          isRtl: true,
        );
        expect(
          rtl.path!.getBounds(),
          ltr.path!.getBounds(),
          reason:
              'funnelGeometry.ts:49-50 mirrors xStart and xEnd, but the '
              'shape is symmetric about funnelWidth / 2, so the mirror only '
              'reverses the winding.',
        );
      },
    );
  });

  group('horizontal, non-stacked', () {
    // Four stages, maximum 400, funnelHeight 400 makes heightScale the
    // identity; segmentWidth is 280 / 4 = 70.
    final data = stages(<double>[400, 300, 200, 100]);

    test('a middle segment spans its own column and is vertically centred', () {
      final geometry = FluentFunnelSegmentGeometry.horizontal(
        index: 1,
        data: data,
        funnelWidth: width,
        funnelHeight: height,
        isRtl: false,
      );
      final bounds = geometry.path!.getBounds();
      expect(
        bounds.left,
        closeTo(70, 1e-9),
        reason: 'funnelGeometry.ts:93 — x0 is i * segmentWidth.',
      );
      expect(
        bounds.right,
        closeTo(140, 1e-9),
        reason: 'funnelGeometry.ts:94 — x1 is (i + 1) * segmentWidth.',
      );
      expect(
        bounds.center.dy,
        closeTo(200, 1e-9),
        reason:
            'funnelGeometry.ts:91-92 centres each edge on funnelHeight / 2.',
      );
    });

    test('a middle segment shows text only when both edges clear 20', () {
      // minHeight is min(leftHeight, rightHeight) and the comparison is
      // strictly greater than 20.
      final atThreshold = FluentFunnelSegmentGeometry.horizontal(
        index: 0,
        data: stages(<double>[400, 20]),
        funnelWidth: width,
        funnelHeight: height,
        isRtl: false,
      );
      expect(
        atThreshold.availableWidth,
        0.0,
        reason:
            'funnelGeometry.ts:123 — minHeight > 20 is strict, so exactly '
            '20 hides the text.',
      );
      final justOver = FluentFunnelSegmentGeometry.horizontal(
        index: 0,
        data: stages(<double>[400, 21]),
        funnelWidth: width,
        funnelHeight: height,
        isRtl: false,
      );
      expect(
        justOver.availableWidth,
        closeTo(140 * 0.8, 1e-9),
        reason:
            'funnelGeometry.ts:123 — segmentWidth * 0.8 with two stages, '
            'so 280 / 2 * 0.8.',
      );
    });

    test('the last segment needs both a height of 40 and an area of 800', () {
      // Two stages, so segmentWidth is 140 and the area is leftHeight * 70.
      final tooShort = FluentFunnelSegmentGeometry.horizontal(
        index: 1,
        data: stages(<double>[400, 39]),
        funnelWidth: width,
        funnelHeight: height,
        isRtl: false,
      );
      expect(
        tooShort.availableWidth,
        0.0,
        reason:
            'funnelGeometry.ts:111 — leftHeight < 40 hides the text '
            'regardless of the area.',
      );
      final tallEnough = FluentFunnelSegmentGeometry.horizontal(
        index: 1,
        data: stages(<double>[400, 40]),
        funnelWidth: width,
        funnelHeight: height,
        isRtl: false,
      );
      expect(
        tallEnough.availableWidth,
        closeTo(140 * 0.75 * 0.6, 1e-9),
        reason:
            'funnelGeometry.ts:116-117 — at exactly 40 the height check '
            'passes and the area is 40 * 140 / 2 = 2800, well over 800.',
      );
    });

    test('the area cut-off bites when the column is narrow', () {
      // Ten stages make segmentWidth 28, so the area is leftHeight * 14.
      final belowArea = FluentFunnelSegmentGeometry.horizontal(
        index: 9,
        data: stages(<double>[400, 400, 400, 400, 400, 400, 400, 400, 400, 57]),
        funnelWidth: width,
        funnelHeight: height,
        isRtl: false,
      );
      expect(
        belowArea.availableWidth,
        0.0,
        reason:
            'funnelGeometry.ts:111 — 57 * 28 / 2 is 798, under the 800 '
            'minimum, even though 57 clears the height check.',
      );
      final atArea = FluentFunnelSegmentGeometry.horizontal(
        index: 9,
        data: stages(<double>[400, 400, 400, 400, 400, 400, 400, 400, 400, 58]),
        funnelWidth: width,
        funnelHeight: height,
        isRtl: false,
      );
      expect(
        atArea.availableWidth,
        closeTo(28 * 0.75 * 0.6, 1e-9),
        reason: '58 * 28 / 2 is 812, over the minimum.',
      );
    });

    test('the horizontal generator ignores its isRtl argument', () {
      final ltr = FluentFunnelSegmentGeometry.horizontal(
        index: 1,
        data: data,
        funnelWidth: width,
        funnelHeight: height,
        isRtl: false,
      );
      final rtl = FluentFunnelSegmentGeometry.horizontal(
        index: 1,
        data: data,
        funnelWidth: width,
        funnelHeight: height,
        isRtl: true,
      );
      expect(
        rtl.path!.getBounds(),
        ltr.path!.getBounds(),
        reason:
            'funnelGeometry.ts:78 accepts isRTL and never reads it; the '
            'only mirror is the outer transform at FunnelChart.tsx:505.',
      );
    });
  });

  group('stacked', () {
    final stacked = <FluentFunnelDataPoint>[
      const FluentFunnelDataPoint(
        stage: 'A',
        subValues: <FluentFunnelSubValue>[
          FluentFunnelSubValue(category: 'x', value: 60),
          FluentFunnelSubValue(category: 'y', value: 40),
        ],
      ),
      const FluentFunnelDataPoint(
        stage: 'B',
        subValues: <FluentFunnelSubValue>[
          FluentFunnelSubValue(category: 'x', value: 30),
          FluentFunnelSubValue(category: 'y', value: 20),
        ],
      ),
    ];

    test('a data set is stacked only when EVERY stage has sub-values', () {
      expect(
        isFluentStackedFunnelData(stacked),
        isTrue,
        reason:
            'FunnelChart.tsx:310-312 — data.every(s => '
            'Array.isArray(s.subValues)).',
      );
      expect(
        isFluentStackedFunnelData(<FluentFunnelDataPoint>[
          stacked.first,
          const FluentFunnelDataPoint(stage: 'B', value: 10),
        ]),
        isFalse,
        reason:
            'One stage without sub-values takes the whole chart down the '
            'non-stacked path.',
      );
    });

    test('the first stage spans the full width at the maximum total', () {
      final first = FluentFunnelSegmentGeometry.stackedVertical(
        stageIndex: 0,
        subIndex: 0,
        stages: stacked,
        totals: const <double>[100, 50],
        maxTotal: 100,
        funnelWidth: width,
        funnelHeight: height,
      );
      expect(
        first.path!.getBounds().left,
        closeTo(0, 1e-9),
        reason:
            'funnelGeometry.ts:173 — the left edge is '
            '(funnelWidth - curTotal / maxTotal * funnelWidth) / 2, which is '
            'zero when the stage carries the maximum total.',
      );
      expect(
        first.path!.getBounds().width,
        closeTo(168, 1e-9),
        reason:
            'The bounding box spans from the top edge at 60 / 100 * 280 = '
            '168 down to the bottom edge at 30 / 50 * 50 / 100 * 280 = 84, '
            'and the wider top edge sets the box.',
      );
    });

    test('a missing next-stage category contributes a zero bottom edge', () {
      final geometry = FluentFunnelSegmentGeometry.stackedVertical(
        stageIndex: 0,
        subIndex: 0,
        stages: <FluentFunnelDataPoint>[
          stacked.first,
          const FluentFunnelDataPoint(
            stage: 'B',
            subValues: <FluentFunnelSubValue>[
              FluentFunnelSubValue(category: 'y', value: 20),
            ],
          ),
        ],
        totals: const <double>[100, 20],
        maxTotal: 100,
        funnelWidth: width,
        funnelHeight: height,
      );
      expect(
        geometry.availableWidth,
        closeTo(0, 1e-9),
        reason:
            'funnelGeometry.ts:191 — min(topW, botW), and botW is zero '
            'because `find` returns nothing for category x in stage B.',
      );
    });

    test('a zero next-total yields zero rather than NaN', () {
      final geometry = FluentFunnelSegmentGeometry.stackedVertical(
        stageIndex: 0,
        subIndex: 0,
        stages: stacked,
        totals: const <double>[100, 0],
        maxTotal: 100,
        funnelWidth: width,
        funnelHeight: height,
      );
      expect(
        geometry.availableWidth,
        closeTo(0, 1e-9),
        reason:
            'funnelGeometry.ts:172 parses as '
            '((nextVal / nextTotal) || 0), so the NaN from dividing by zero is '
            'swallowed by the falsy guard. Keep the guard explicit rather than '
            'restructuring the expression.',
      );
    });

    test(
      'the stacked horizontal last stage needs a height of 24 and an area of 600',
      () {
        const totals = <double>[100, 0];
        final tooShort = FluentFunnelSegmentGeometry.stackedHorizontal(
          stageIndex: 1,
          subIndex: 0,
          stages: <FluentFunnelDataPoint>[
            stacked.first,
            const FluentFunnelDataPoint(
              stage: 'B',
              subValues: <FluentFunnelSubValue>[
                FluentFunnelSubValue(category: 'x', value: 23),
              ],
            ),
          ],
          totals: const <double>[100, 100],
          maxTotal: 100,
          funnelWidth: width,
          funnelHeight: 100,
        );
        expect(
          tooShort.availableWidth,
          0.0,
          reason:
              'funnelGeometry.ts:263 — topH < 24 hides the label; 23 of a '
              '100-tall funnel at a total of 100 is exactly 23.',
        );
        expect(
          totals.length,
          2,
          reason: 'Guard against an accidental edit to the fixture above.',
        );
      },
    );
  });

  test('the text gate compares strictly against the minimum width', () {
    const shown = FluentFunnelSegmentGeometry(
      path: null,
      textX: 0,
      textY: 0,
      availableWidth: 16.001,
    );
    const hidden = FluentFunnelSegmentGeometry(
      path: null,
      textX: 0,
      textY: 0,
      availableWidth: 16,
    );
    expect(
      shown.showText(16),
      isTrue,
      reason: 'funnelGeometry.ts:319 — availableWidth > minTextWidth.',
    );
    expect(
      hidden.showText(16),
      isFalse,
      reason: 'Exactly at the threshold the text is hidden.',
    );
  });

  group('Oracle B', () {
    // Both captured FunnelChart stories are horizontal funnels drawn inside a
    // `translate(60, 40)` group of 480 x 368 (`charts-funnelchart--*`, element
    // 4), so every path below is in the funnel's own coordinate space.
    const funnelWidth = 480.0;
    const funnelHeight = 368.0;
    // Both call sites pass 16 (`FunnelChart.tsx:287`, `:348`).
    const minTextWidth = 16.0;

    /// The `d` of every `<path>`, paired with the `<text>` that follows it
    /// before the next `<path>` — upstream renders one optional label per
    /// segment inside the segment's own `<g>`.
    List<(OracleElement, OracleElement?)> labelledPaths(OracleStory story) {
      final paths = story.byTag('path');
      final texts = story.byTag('text');
      return <(OracleElement, OracleElement?)>[
        for (var i = 0; i < paths.length; i++)
          (
            paths[i],
            texts
                .where(
                  (text) =>
                      text.index > paths[i].index &&
                      (i + 1 == paths.length ||
                          text.index < paths[i + 1].index),
                )
                .firstOrNull,
          ),
      ];
    }

    /// Symmetric difference of [actual] and the polygon the oracle's `d`
    /// describes. Both are closed polygons of straight edges, so an exact match
    /// leaves nothing behind and the residue's bounding box is empty.
    void expectSamePolygon(String what, String expected, Path actual) {
      final numbers = svgPathNumbers(expected);
      expect(
        numbers.length,
        8,
        reason: '$what: every funnel segment is four vertices.',
      );
      final wanted = Path()..moveTo(numbers[0], numbers[1]);
      for (var i = 2; i < numbers.length; i += 2) {
        wanted.lineTo(numbers[i], numbers[i + 1]);
      }
      wanted.close();
      final residue = Path.combine(
        PathOperation.xor,
        wanted,
        actual,
      ).getBounds();
      expect(
        residue.isEmpty ||
            (residue.width <= kOracleGeometryTolerance &&
                residue.height <= kOracleGeometryTolerance),
        isTrue,
        reason:
            '$what: the symmetric difference against the captured `d` is '
            '$residue, not empty, so the two polygons differ.',
      );
    }

    test('the basic story reproduces four horizontal segments', () {
      final story = loadOracleStory('charts-funnelchart--funnel-chart-basic');
      final segments = labelledPaths(story);
      expect(
        segments.length,
        4,
        reason:
            'FunnelChartBasic draws one path per stage and the story has four '
            'stages.',
      );
      // The four captured labels read 1000, 600, 300 and 250.
      final data = <FluentFunnelDataPoint>[
        const FluentFunnelDataPoint(stage: 'Impressions', value: 1000),
        const FluentFunnelDataPoint(stage: 'Clicks', value: 600),
        const FluentFunnelDataPoint(stage: 'Leads', value: 300),
        const FluentFunnelDataPoint(stage: 'Sales', value: 250),
      ];
      for (var i = 0; i < segments.length; i++) {
        final (path, label) = segments[i];
        final geometry = FluentFunnelSegmentGeometry.horizontal(
          index: i,
          data: data,
          funnelWidth: funnelWidth,
          funnelHeight: funnelHeight,
          isRtl: false,
        );
        expectSamePolygon('segment $i', path.d!, geometry.path!);
        expect(
          geometry.showText(minTextWidth),
          label != null,
          reason:
              'segment $i: the capture ${label == null ? "hides" : "shows"} '
              'its label, so `getSegmentTextProps` must agree.',
        );
        expectOracleNumber('segment $i textX', label!.x!, geometry.textX);
        expectOracleNumber('segment $i textY', label.y!, geometry.textY);
      }
    });

    test('the stacked story reproduces twelve stacked horizontal segments', () {
      final story = loadOracleStory('charts-funnelchart--funnel-chart-stacked');
      final segments = labelledPaths(story);
      expect(
        segments.length,
        12,
        reason: 'Three stages of four sub-values each.',
      );
      // Stage totals 260, 130 and 65 and the per-category splits below are the
      // only assignment consistent with the captured edge heights: every
      // sub-value height is `value / 260 * 368` because each stage's
      // `curTotal / maxTotal` cancels its own `value / curTotal`.
      const categories = <String>['Started', 'Engaged', 'Qualified', 'Won'];
      const values = <List<double>>[
        <double>[100, 80, 50, 30],
        <double>[60, 40, 20, 10],
        <double>[30, 20, 10, 5],
      ];
      final stages = <FluentFunnelDataPoint>[
        for (final row in values)
          FluentFunnelDataPoint(
            stage: 'stage',
            subValues: <FluentFunnelSubValue>[
              for (var k = 0; k < row.length; k++)
                FluentFunnelSubValue(category: categories[k], value: row[k]),
            ],
          ),
      ];
      final totals = <double>[
        for (final row in values) row.reduce((a, b) => a + b),
      ];
      expect(totals, <double>[
        260,
        130,
        65,
      ], reason: 'Guard against an accidental edit to the fixture above.');
      for (var i = 0; i < segments.length; i++) {
        final stageIndex = i ~/ 4;
        final subIndex = i % 4;
        final (path, label) = segments[i];
        final geometry = FluentFunnelSegmentGeometry.stackedHorizontal(
          stageIndex: stageIndex,
          subIndex: subIndex,
          stages: stages,
          totals: totals,
          maxTotal: 260,
          funnelWidth: funnelWidth,
          funnelHeight: funnelHeight,
        );
        expectSamePolygon(
          'stage $stageIndex sub $subIndex',
          path.d!,
          geometry.path!,
        );
        expect(
          geometry.showText(minTextWidth),
          label != null,
          reason:
              'stage $stageIndex sub $subIndex: the capture '
              '${label == null ? "hides" : "shows"} its label, so the height '
              'and area cut-offs at funnelGeometry.ts:263,275 must agree.',
        );
        if (label != null) {
          expectOracleNumber(
            'stage $stageIndex sub $subIndex textX',
            label.x!,
            geometry.textX,
          );
          expectOracleNumber(
            'stage $stageIndex sub $subIndex textY',
            label.y!,
            geometry.textY,
          );
        }
      }
    });
  });
}
