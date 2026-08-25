// The layout keeps `xAxisReferenceHeight` and `plotContentHeight` apart on
// purpose. Upstream computes `XAxisParams.containerHeight` with the label
// reserve at zero (`CartesianChart.tsx:209`, under an acknowledged FIXME at
// `:203-208`) while `YAxisParams` uses the real reserve (`:298`). Unifying
// them moves HorizontalBarChartWithAxis and GanttChart gridlines off their
// upstream lengths.
import 'package:fluent_2/src/charts/cartesian/cartesian_layout.dart';
import 'package:fluent_2/src/charts/model/chart_common.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';

void main() {
  const size = Size(700, 260);
  const margins = FluentChartMargins(left: 40, right: 20, top: 20, bottom: 35);

  FluentCartesianLayout resolve({
    double reserve = 0,
    bool isRtl = false,
    FluentChartMargins m = margins,
  }) => FluentCartesianLayout.resolve(
    size: size,
    margins: m,
    xAxisLabelReserve: reserve,
    isRtl: isRtl,
    startFromX: 0,
  );

  test('the plot rect is the box inset by the margins and the reserve', () {
    expect(
      resolve().plotRect,
      const Rect.fromLTWH(40, 20, 640, 205),
      reason: 'CartesianChart.tsx:453-461',
    );
    expect(
      resolve(reserve: 18).plotRect,
      const Rect.fromLTWH(40, 20, 640, 187),
      reason: 'plotHeight subtracts _removalValueForTextTuncate at :454',
    );
  });

  test('the plot rect never goes negative', () {
    final layout = FluentCartesianLayout.resolve(
      size: const Size(30, 20),
      margins: margins,
      xAxisLabelReserve: 0,
      isRtl: false,
      startFromX: 0,
    );
    expect(
      layout.plotRect.width,
      0,
      reason: 'Math.max(0, ...) at CartesianChart.tsx:453',
    );
    expect(layout.plotRect.height, 0, reason: 'Math.max(0, ...) at :454');
  });

  test(
    'the two container heights stay distinct once the reserve is non-zero',
    () {
      final layout = resolve(reserve: 18);
      expect(
        layout.xAxisReferenceHeight,
        260,
        reason:
            'XAxisParams.containerHeight is computed before the reserve exists, '
            'so it is always the full height (CartesianChart.tsx:209)',
      );
      expect(
        layout.plotContentHeight,
        242,
        reason: 'YAxisParams.containerHeight uses the real reserve (:298)',
      );
      expect(
        layout.xAxisReferenceHeight == layout.plotContentHeight,
        isFalse,
        reason: 'design spec section 3.3 forbids unifying them',
      );
    },
  );

  test('title geometry matches the source expressions', () {
    final layout = resolve();
    expect(
      layout.xAxisTitleMaxWidth,
      624,
      reason: 'width - left - right - AXIS_TITLE_PADDING * 2, :476',
    );
    expect(
      layout.yAxisTitleMaxHeight,
      189,
      reason: 'height - bottom - top - reserve - AXIS_TITLE_PADDING * 2, :477',
    );
    expect(
      layout.yAxisTitleCenterY,
      122.5,
      reason: 'top + AXIS_TITLE_PADDING + yAxisTitleMaxHeight / 2, :479',
    );
    expect(
      layout.yAxisTitleCenterX,
      16,
      reason:
          'HORIZONTAL_MARGIN_FOR_YAXIS_TITLE - AXIS_TITLE_PADDING in LTR, :482',
    );
    expect(
      layout.secondaryYAxisTitleCenterX,
      692,
      reason: 'width - AXIS_TITLE_PADDING in LTR, :485',
    );
  });

  test('right-to-left mirrors the two title anchors', () {
    final layout = resolve(isRtl: true);
    expect(
      layout.yAxisTitleCenterX,
      692,
      reason: 'CartesianChart.tsx:480-482 flips to width - 8',
    );
    expect(
      layout.secondaryYAxisTitleCenterX,
      16,
      reason: 'CartesianChart.tsx:483-485 flips the other way',
    );
  });

  test('the axis group translates match the transform attributes', () {
    final ltr = resolve(reserve: 18);
    expect(
      ltr.xAxisTranslateY,
      207,
      reason: 'translate(0, height - bottom - reserve), :768',
    );
    expect(
      ltr.yAxisTranslateX,
      40,
      reason: 'translate(margins.left, 0) in LTR, :841',
    );
    expect(
      ltr.secondaryYAxisTranslateX,
      680,
      reason: 'translate(width - margins.right, 0) in LTR, :851',
    );

    final rtl = resolve(reserve: 18, isRtl: true);
    expect(
      rtl.yAxisTranslateX,
      680,
      reason: 'the primary flips to width - margins.right in RTL, :841',
    );
    expect(
      rtl.secondaryYAxisTranslateX,
      40,
      reason: 'the secondary flips to margins.left in RTL, :851',
    );
  });

  test('equality covers the fields the painter repaints on', () {
    expect(
      resolve() == resolve(),
      isTrue,
      reason: 'two identical solves must compare equal for shouldRepaint',
    );
    expect(
      resolve().hashCode,
      resolve().hashCode,
      reason: 'hashCode must agree with ==',
    );
    expect(
      resolve() == resolve(reserve: 1),
      isFalse,
      reason: 'a changed reserve moves the x axis and must force a repaint',
    );
  });

  group('Oracle B', () {
    // Chosen because it is the one captured story that renders all three axis
    // groups: the primary y at `translate(40, 0)`, the secondary y at
    // `translate(660, 0)` and the x at `translate(0, 225)`. Between them they
    // pin both branches of the LTR mirror and the vertical drop in one solve.
    const storyId = 'charts-linechart--line-chart-secondary-y-axis';

    // The margin solve is Task 2's, already covered by
    // cartesian_margin_solver_test.dart; this test takes its output as the
    // input it is. Left and right are the defaults for a chart that has a
    // secondary y scale (`CartesianChart.tsx:677-681`); top and bottom are the
    // unconditional 20 and 35.
    const storyMargins = FluentChartMargins(
      left: 40,
      right: 40,
      top: 20,
      bottom: 35,
    );

    /// The direct children of the svg that are axis groups, in document order:
    /// x first, then the primary y. `<g>` #0 is the x axis (`:762-769`), and
    /// the primary y `<g>` is the next unrotated top-level group (`:836-842`).
    OracleElement axisGroup(OracleStory story, int ordinal) {
      final groups = story
          .byTag('g')
          .where((g) => g.parent == -1 && g.translate != null)
          .toList();
      expect(
        groups.length,
        greaterThan(ordinal),
        reason:
            '$storyId must expose at least ${ordinal + 1} translated top-level '
            '<g> groups; a filtered loop that matched fewer would assert '
            'nothing',
      );
      return groups[ordinal];
    }

    test('the axis group translates land on the captured transforms', () {
      final story = loadOracleStory(storyId);
      final layout = FluentCartesianLayout.resolve(
        size: Size(story.width, story.height),
        margins: storyMargins,
        // No wrap and no rotation in this story, so
        // `_removalValueForTextTuncate` never leaves zero.
        xAxisLabelReserve: 0,
        isRtl: false,
        startFromX: 0,
      );

      final xAxis = axisGroup(story, 0);
      expectOracleNumber(
        '$storyId xAxisGElement translate y',
        story.absoluteTranslate(xAxis).dy,
        layout.xAxisTranslateY,
      );
      final yAxis = axisGroup(story, 1);
      expectOracleNumber(
        '$storyId yAxisGElement translate x',
        story.absoluteTranslate(yAxis).dx,
        layout.yAxisTranslateX,
      );
      // The secondary y group is wrapped in a bare, transformless `<g>`
      // (`:845-851`), so it is not a direct child of the svg. That wrapper is
      // what distinguishes it from the tick groups, which hang off the two
      // translated axis groups.
      final secondary = story.soleElement(
        'g',
        where: (g) {
          final parent = story.parentOf(g);
          return g.translate != null &&
              parent != null &&
              parent.transform == null &&
              parent.parent == -1;
        },
      );
      expectOracleNumber(
        '$storyId yAxisGElementSecondary translate x',
        story.absoluteTranslate(secondary).dx,
        layout.secondaryYAxisTranslateX,
      );
    });

    test('the plot rect height spans the captured y tick range', () {
      final story = loadOracleStory(storyId);
      final layout = FluentCartesianLayout.resolve(
        size: Size(story.width, story.height),
        margins: storyMargins,
        xAxisLabelReserve: 0,
        isRtl: false,
        startFromX: 0,
      );
      final yAxis = axisGroup(story, 1);
      final ticks = story
          .childrenOf(yAxis)
          .where((g) => g.tag == 'g' && g.translate != null)
          .map((g) => story.absoluteTranslate(g).dy)
          .toList();
      expect(
        ticks.length,
        greaterThanOrEqualTo(2),
        reason:
            '$storyId must capture at least two y ticks for the span to mean '
            'anything',
      );
      ticks.sort();
      // d3-axis translates each tick by the crispness offset, which cancels
      // across a difference — but the top of the range still carries it, so the
      // first tick sits at margins.top + crispOffset.
      expectOracleNumber(
        '$storyId first y tick',
        layout.plotRect.top + story.crispOffset,
        ticks.first,
      );
      expectOracleNumber(
        '$storyId y tick span',
        layout.plotRect.height,
        ticks.last - ticks.first,
      );
      // Same drop, reached independently: the last tick is the x axis line.
      expectOracleNumber(
        '$storyId last y tick vs xAxisTranslateY',
        layout.xAxisTranslateY + story.crispOffset,
        ticks.last,
      );
    });
  });
}
