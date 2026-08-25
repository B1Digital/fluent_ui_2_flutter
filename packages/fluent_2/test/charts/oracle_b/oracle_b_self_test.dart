// Proves the Oracle B harness works end to end on ONE story before twenty
// chart plans depend on it (design spec §4.3). Every expected value here is
// either quoted in §4.3 or was measured live on 2026-08-08 in
// `test/fixtures/charts/oracle_b/charts-areachart--area-chart-basic.json`, and
// none of them comes from the Dart port — this file imports no port symbol, so
// it passes while plan 01 is still in flight and no chart plan can break it.
//
// There is no production code behind this file. The harness under test was
// implemented in `test/support/oracle_fixture.dart` and captured by
// `crawlers/storybooks-fluentui/capture_oracle.mjs`; a self-test that needed
// new production code to pass would be testing that code rather than the
// harness. If an expectation here fails, the harness is wrong and not the test.
// Two failures occur in practice and both are capture bugs:
//
// 1. `story.elements.length` differs from 128. Either the walk descends into
//    `<defs>` (it must skip `defs`, `linearGradient` and `stop`, which are
//    recorded under `gradients`), or the settle timeout fired before d3's enter
//    selection finished. Raise SETTLE_MS, do not lower the expectation.
//
// 2. `soleElement('path', where: parent == axisGroup.index)` throws with a
//    count other than 1. The `parent` index is being written relative to the
//    wrong list — `walk(el, index)` must pass the child's own index, and the
//    `defs` branch must pass `parentIndex` through unchanged so a gradient's
//    absence does not shift every later index.
//
// That is the debugging note the next person re-capturing the corpus needs, and
// it is cheaper than rediscovering both.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';

/// The story design spec §4.3 quotes verbatim.
const String _story = 'charts-areachart--area-chart-basic';

void main() {
  test('the corpus can be enumerated and the anchor story is in it', () {
    final ids = oracleStoryIds();
    expect(
      ids.length,
      // 90 stories were captured; 80 is a floor rather than the exact count so
      // this reads as "the capture did not half-fail", which the corpus test
      // asserts exactly.
      greaterThanOrEqualTo(80),
      reason:
          '90 stories were captured; a corpus of a handful means the '
          'capture half-failed and every consuming test is asserting nothing',
    );
    expect(
      ids,
      contains(_story),
      reason:
          'spec §4.3 quotes this story, so the harness must reach it '
          'without constructing an id',
    );
  });

  test('the anchor story renders at the size spec §4.3 records', () {
    final story = loadOracleStory(_story);
    // 700x260 is the svg CSS box spec §4.3 quotes.
    expectOracleNumber('svg width', 700, story.width);
    expectOracleNumber('svg height', 260, story.height);
    expect(
      story.svgs.length,
      1,
      reason:
          'AreaChartBasic renders one chart svg and no legend-shape svg; a '
          'second one would mean the icon filter let something through',
    );
    expect(
      story.elements.length,
      // Measured 2026-08-08: one axis group, 15 tick groups with a line and a
      // label each, the y axis and the three area series.
      128,
      reason:
          'measured 2026-08-08. A different count is a re-capture to '
          'review, not a regression — read the diff before updating it.',
    );
    expect(
      story.component,
      'AreaChart',
      reason:
          'the fixture records which component it came from, so a chart '
          'test cannot assert against the wrong family',
    );
  });

  test('the x-axis domain path matches the one spec §4.3 quotes', () {
    final story = loadOracleStory(_story);
    final axisGroup = story.elements.first;
    expect(
      axisGroup.tag,
      'g',
      reason: 'the x-axis group is the first child of the chart svg',
    );
    expectOracleOffset(
      'x-axis group translate',
      // `CartesianChart` translates the bottom axis down the plot height.
      const Offset(0, 205),
      axisGroup.translate!,
    );

    final domain = story.soleElement(
      'path',
      where: (element) => element.parent == axisGroup.index,
    );
    // The whitespace differs from the captured `M64.5,6V0.5H680.5V6` on
    // purpose: the comparator must normalise separators, or every consumer
    // would have to emit d3's exact formatting.
    expectOracleSvgPath(
      'x-axis domain path',
      'M 64.5 6 V 0.5 H 680.5 V 6',
      domain.d!,
    );
    expectOracleColour(
      // rgb(36, 36, 36) is Fluent's `neutralStroke1` at rest.
      'x-axis domain stroke',
      const Color(0xFF242424),
      domain.stroke,
    );
    expectOracleColour('x-axis domain fill', null, domain.fill);
    // 1px, the SVG default, which upstream does not override.
    expectOracleNumber('x-axis domain stroke width', 1, domain.strokeWidth);
  });

  test('the transform chain composes from attribute strings', () {
    final story = loadOracleStory(_story);
    final axisGroup = story.elements.first;
    final tickGroups = story
        .childrenOf(axisGroup)
        .where((element) => element.tag == 'g')
        .toList(growable: false);
    expect(
      tickGroups.length,
      // 15 were captured; 2 is the floor that proves the walk descended.
      greaterThan(2),
      reason:
          'AreaChartBasic draws several x ticks; one would mean the walk '
          'never descended',
    );
    expectOracleOffset(
      'first tick group translate',
      // The first tick sits at 64, plus the 0.5 crispness offset of §5.5.
      const Offset(64.5, 0),
      tickGroups.first.translate!,
    );
    expectOracleOffset(
      'first tick group absolute position',
      // translate(0, 205) composed with translate(64.5, 0).
      const Offset(64.5, 205),
      story.absoluteTranslate(tickGroups.first),
    );

    final tickLine = story.soleElement(
      'line',
      where: (element) => element.parent == tickGroups.first.index,
    );
    // `tickSizeInner` 6 (d3-axis/src/axis.js:41), written as y2.
    expectOracleNumber('tick line length', 6, tickLine.end.dy);
    expectOracleColour(
      'tick line stroke',
      const Color(0xFF242424),
      tickLine.stroke,
    );
    // Upstream fades the tick marks: opacity 0.2 on the line itself.
    expectOracleNumber('tick line opacity', 0.2, tickLine.opacity);
    // The stroke reaches the pixel at 20% alpha: 0xFF * 0.2 rounds to 0x33.
    expectOracleColour(
      'tick line effective stroke',
      const Color(0x33242424),
      tickLine.effectiveStroke,
    );

    final tickLabel = story.soleElement(
      'text',
      where: (element) => element.parent == tickGroups.first.index,
    );
    expect(
      tickLabel.text,
      '20',
      reason: 'the first x tick of AreaChartBasic is 20',
    );
    // `tickSizeInner` 6 plus `tickPadding` 10 (d3-axis/src/axis.js:41-42).
    expectOracleNumber('tick label baseline y', 16, tickLabel.y!);
    // 10px, the size upstream sets on the axis group.
    expectOracleNumber('tick label font size', 10, tickLabel.fontSize);
    expect(
      tickLabel.fontWeight,
      '600',
      reason:
          'measured: upstream draws tick labels semibold, which a port '
          'that assumes regular would get wrong',
    );
    expect(
      tickLabel.textAnchor,
      'middle',
      reason: 'd3-axis centres bottom-axis labels',
    );
  });

  test('the crispness offset of spec §5.5 is visible in the capture', () {
    final story = loadOracleStory(_story);
    expectOracleNumber(
      'recorded crisp offset',
      kOracleCrispOffset,
      story.crispOffset,
    );
    expect(
      story.deviceScaleFactor,
      // 1: `d3-axis` picks its offset off `devicePixelRatio > 1`.
      1,
      reason:
          'at deviceScaleFactor 2 d3-axis would use offset 0, every '
          'coordinate below would be whole, and this corpus would not '
          'describe what flutter test renders at DPR 1',
    );
    final tick = story.elements.firstWhere(
      (element) => element.transform == 'translate(64.5,0)',
      orElse: () => throw StateError('the first x tick group moved'),
    );
    final fraction = tick.translate!.dx - tick.translate!.dx.floorToDouble();
    expectOracleNumber('tick x fractional part', kOracleCrispOffset, fraction);
    expect(
      kOracleGeometryTolerance,
      lessThan(kOracleCrispOffset),
      reason:
          'a tolerance at or above 0.5 would let a port that forgets the '
          'offset pass, which would make this whole corpus decorative',
    );
  });

  test(
    'the legend is captured as HTML, because that is how upstream draws it',
    () {
      final story = loadOracleStory(_story);
      final rects = story.boxes('fui-legend__rect');
      final texts = story.boxes('fui-legend__text');
      expect(
        rects.length,
        texts.length,
        reason: 'every legend swatch has exactly one label',
      );
      expect(
        texts,
        isNotEmpty,
        reason:
            'AreaChartBasic renders a legend; plan 04 has nine Oracle B '
            'references and five of them are about it',
      );
      // 14x14 is the swatch `Legends/useLegendsStyles.styles.ts` sizes.
      expectOracleNumber('legend swatch width', 14, rects.first.rect.width);
      expectOracleNumber('legend swatch height', 14, rects.first.rect.height);
    },
  );

  test('the manifest names its own gaps rather than implying full coverage', () {
    final manifest = loadOracleManifest();
    expect(
      manifest.thinComponents,
      contains('PolarChart'),
      reason:
          'PolarChart has one story upstream, so plan 08 must lean on '
          'Oracle A and say so — a harness that hid this would be worse than '
          'none',
    );
    expect(
      manifest.capturedPerComponent['AreaChart'],
      manifest.storiesPerComponent['AreaChart'],
      reason: 'every AreaChart story rendered, so none may be missing',
    );
    expect(
      manifest.indexEntries,
      greaterThan(manifest.storyCount),
      reason:
          'index.json holds 111 entries and 90 of them are stories, the '
          'other 21 being docs pages (spec §4.3); the manifest records both so '
          'nobody reconciles them again',
    );
  });
}
