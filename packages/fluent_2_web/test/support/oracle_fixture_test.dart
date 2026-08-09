// The Oracle B loader's own gate. Every number quoted below was read out of
// `test/fixtures/charts/oracle_b/` on 2026-08-09 with the file:line of the
// upstream source that produces it, so a re-capture that moves an anchor fails
// here rather than silently in the six axis test files that consume the corpus.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'oracle_fixture.dart';

void main() {
  test('the manifest describes the capture conditions', () {
    final manifest = loadOracleManifest();
    expect(
      manifest.upstreamVersion,
      '9.3.23',
      reason: 'spec §4.3 pins the corpus to @fluentui/react-charts 9.3.23',
    );
    expect(
      manifest.deviceScaleFactor,
      1,
      reason: 'spec §5.5: the capture and flutter test must share DPR 1',
    );
    expect(
      manifest.crispOffset,
      kOracleCrispOffset,
      reason: 'd3-axis/src/axis.js:38 gives 0.5 at DPR 1',
    );
    expect(
      manifest.storyCount,
      greaterThanOrEqualTo(80),
      reason: '90 stories were enumerated live; below 80 the index moved',
    );
    expect(
      manifest.indexEntries,
      111,
      reason: 'upstream index.json had 111 entries, 21 of them docs pages',
    );
    expect(
      manifest.capturedCount,
      manifest.storyCount,
      reason:
          'every enumerated story produced a fixture, which is why '
          'manifest.skipped is empty',
    );
    expect(
      manifest.thinComponents,
      contains('Sparkline'),
      reason:
          'Sparkline has 2 stories upstream, under the 3 that spec §4.3 '
          'calls thin; a reviewer must be told rather than let the low count '
          'pass silently',
    );
  });

  test('story ids are enumerated from disk, never constructed', () {
    final ids = oracleStoryIds();
    expect(
      ids,
      isNotEmpty,
      reason:
          'an empty id list would let every consuming test pass with zero '
          'assertions, which is the failure mode spec §4.3 names',
    );
    expect(
      ids.length,
      loadOracleManifest().capturedCount,
      reason:
          'the ids on disk and the count the capture recorded must agree, '
          'or one of the two is stale',
    );
    expect(
      ids,
      contains('charts-areachart--area-chart-basic'),
      reason: 'the story spec §4.3 quotes must be in the corpus',
    );
    expect(
      ids,
      isNot(contains('_manifest')),
      reason: 'the manifest is not a story',
    );
    expect(
      oracleStoryIds(component: 'AreaChart').length,
      8,
      reason: 'AreaChart had eight stories when the corpus was captured',
    );
    expect(
      oracleStoryIds(component: 'AreaChart').length,
      loadOracleManifest().capturedPerComponent['AreaChart'],
      reason:
          'the per-component filter must agree with the recorded count, '
          'otherwise a component silently verifies nothing',
    );
  });

  test('a missing story names the capture command', () {
    expect(
      () => loadOracleStory('charts-notachart--nope'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(contains('capture_oracle.mjs'), contains('never construct')),
        ),
      ),
      reason:
          'a consumer that mistypes an id must be told to enumerate rather '
          'than shown an empty result',
    );
  });

  test('an unrendered story fails with its recorded reason, not "no fixture"', () {
    // The skip register is empty — capturedCount == storyCount — so the branch
    // of loadOracleStory that reads it cannot be reached from disk. The message
    // it throws is asserted directly instead, because a conditional assertion
    // on an empty register is a vacuous pass.
    expect(
      loadOracleManifest().skipped,
      isEmpty,
      reason:
          'all 90 stories captured; if one ever fails, the register '
          'records it and the assertions below become reachable',
    );
    expect(
      loadOracleManifest().skipReasonFor('charts-areachart--area-chart-basic'),
      isNull,
      reason: 'a captured story is not in the register',
    );
    final skipped = oracleSkippedStoryError(
      'charts-ganttchart--gantt-chart-basic',
      'Storybook rendered an empty root',
    );
    expect(
      skipped.message,
      allOf(
        contains('skip register'),
        contains('Storybook rendered an empty root'),
      ),
      reason:
          'a story that failed to render must fail loudly with its '
          'reason, never be treated as "nothing to check"',
    );
    expect(
      skipped.message,
      isNot(contains('never construct')),
      reason:
          'the skip message must be distinct from the missing-fixture one, '
          'or "no fixture" reads as "nothing to check"',
    );
  });

  test(
    'an element exposes its geometry, its resolved paint and its parent',
    () {
      final story = loadOracleStory('charts-areachart--area-chart-basic');
      expect(
        story.component,
        'AreaChart',
        reason: 'the fixture records the component it came from',
      );
      expect(
        story.crispOffset,
        kOracleCrispOffset,
        reason:
            'the offset is read out of the fixture, never hard-coded — this '
            'is the value the six axis test files must consume',
      );
      final axisGroup = story.elements.first;
      expect(
        axisGroup.tag,
        'g',
        reason: 'the x-axis group is the first child of the chart svg',
      );
      expect(
        axisGroup.translate,
        const Offset(0, 205),
        reason: 'measured: transform="translate(0, 205)"',
      );
      final domain = story.childrenOf(axisGroup).first;
      expect(
        domain.d,
        'M64.5,6V0.5H680.5V6',
        reason: 'spec §4.3 quotes this domain path verbatim',
      );
      expect(
        domain.stroke?.toARGB32(),
        0xFF242424,
        reason: 'measured: stroke resolved to rgb(36, 36, 36)',
      );
      expect(
        domain.fill,
        isNull,
        reason: 'fill: none is an absence, not a transparent colour',
      );
      expect(
        domain.strokeWidth,
        1,
        reason:
            'measured: stroke-width resolved to "1px"; the unit is stripped',
      );
      expect(
        story.parentOf(domain)?.index,
        axisGroup.index,
        reason: 'parent indexes let a consumer walk the transform chain',
      );
      expect(
        story.parentOf(axisGroup),
        isNull,
        reason:
            'the axis group is a direct child of the svg, recorded as '
            'parent -1',
      );
      final tickLine = story.byTag('line').first;
      expect(
        tickLine.end,
        const Offset(0, 6),
        reason:
            'measured: the tick line carries y2="6" and no x2, which SVG '
            'defines as 0. d3-axis/src/axis.js:100-101 sets only x+"2", and '
            'for a bottom axis x is "y" (axis.js:40)',
      );
      expect(
        tickLine.opacity,
        0.2,
        reason:
            'measured: opacity resolved to "0.2" on the tick line, and it is '
            'not inherited by its children',
      );
      expect(
        tickLine.effectiveStroke?.toARGB32(),
        0xFF242424 & 0x00FFFFFF | (51 << 24),
        reason:
            'effectiveStroke folds the 0.2 element opacity into the alpha: '
            'round(255 * 0.2) is 51',
      );
    },
  );

  test('a url() paint is an absence with the referenced id recorded', () {
    // LineChartMultiple paints two of its bars with a `<pattern>` def rather
    // than a colour (upstream renders a diagonal-stripe fill for the
    // colour-blind mode). Measured 2026-08-09: elements 46 and 47 of
    // charts-linechart--line-chart-multiple carry
    // fill="url(#colorFillBarPattern_r_6__1)".
    final story = loadOracleStory('charts-linechart--line-chart-multiple');
    final patterned = story.elements
        .where((element) => element.fillRef != null)
        .toList();
    expect(
      patterned.length,
      2,
      reason:
          'exactly two rects are pattern-filled; zero would mean the '
          'reference is being parsed as a colour and this test proves nothing',
    );
    expect(
      patterned.first.fillRef,
      'colorFillBarPattern_r_6__1',
      reason: 'the id is stripped of url(", # and ") so it can be looked up',
    );
    expect(
      patterned.first.fill,
      isNull,
      reason:
          'a pattern reference is not a colour; parsing it as one would '
          'throw while the story loads and take the whole corpus with it',
    );
    expect(
      patterned.first.strokeRef,
      isNull,
      reason: 'measured: stroke is none on both rects',
    );
  });

  test('absoluteTranslate composes attribute strings, not the float32 CTM', () {
    final story = loadOracleStory('charts-areachart--area-chart-basic');
    final tick = story.elements.firstWhere(
      (element) => element.transform == 'translate(64.5,0)',
      orElse: () => throw StateError('the first x tick group moved'),
    );
    expect(
      story.absoluteTranslate(tick),
      const Offset(64.5, 205),
      reason:
          'translate(64.5,0) inside translate(0, 205); composing the exact '
          'attribute strings avoids the float32 rounding getCTM() returns',
    );
    expect(
      story.absoluteTranslate(story.childrenOf(tick).first),
      const Offset(64.5, 205),
      reason:
          'a tick line carries no transform of its own, so it sits exactly '
          'where its group does',
    );
  });

  test('a rotated ancestor makes absoluteTranslate throw, never guess', () {
    final story = loadOracleStory('charts-areachart--area-chart-basic');
    final rotated = story.elements.firstWhere(
      (element) =>
          element.transform != null &&
          !element.transform!.startsWith('translate'),
      orElse: () => throw StateError('no non-translate transform to check'),
    );
    expect(
      rotated.translate,
      isNull,
      reason:
          'a rotate/scale/matrix transform is not a pure translate, so the '
          'parsed offset must be null rather than the first two numbers',
    );
    expect(
      () => story.absoluteTranslate(rotated),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('not a pure translate'),
        ),
      ),
      reason:
          'a rotated x-axis label must not be compared as if it were '
          'unrotated',
    );
  });

  test('the path tokeniser normalises separators but not values', () {
    expect(
      tokeniseSvgPath('M64.5,6V0.5H680.5V6'),
      <String>['M', '64.5', '6', 'V', '0.5', 'H', '680.5', 'V', '6'],
      reason: 'commas and implicit separators are not part of the geometry',
    );
    expect(
      tokeniseSvgPath('M-1.5e2 .5Z'),
      <String>['M', '-1.5e2', '.5', 'Z'],
      reason: 'd3-path emits exponent and leading-dot forms',
    );
    expect(
      svgPathNumbers('M64.5,6V0.5H680.5V6'),
      <double>[64.5, 6, 0.5, 680.5, 6],
      reason:
          'the numbers alone, in source order — the form the axis tests '
          'compare a domain path in, because the same path written from Dart '
          "doubles reads '6.0'",
    );
  });

  test(
    'expectOracleSvgPath ignores whitespace and fails on a real difference',
    () {
      expectOracleSvgPath(
        'domain path',
        'M64.5,6V0.5H680.5V6',
        'M 64.5 6 V 0.5 H 680.5 V 6',
      );
      expect(
        () => expectOracleSvgPath('domain path', 'M64.5,6V0.5', 'M64.5,6V1'),
        throwsA(isA<TestFailure>()),
        reason: 'a half-pixel crispness error is exactly what this must catch',
      );
      expect(
        () =>
            expectOracleSvgPath('domain path', 'M64.5,6V0.5', 'M64.5,6L0,0.5'),
        throwsA(isA<TestFailure>()),
        reason:
            'a different command is a different shape, whatever the numbers',
      );
    },
  );

  test('the tolerances are the ones the plan justifies', () {
    expect(
      kOracleGeometryTolerance,
      0.01,
      reason:
          'attribute values carry authored precision; 0.01 is far below '
          'the 0.5px crispness offset it must never hide',
    );
    expect(
      kOracleGeometryTolerance,
      lessThan(kOracleCrispOffset),
      reason:
          'a tolerance at or above the crispness offset would make spec '
          '§5.5 unverifiable',
    );
    expect(
      kOracleMeasuredTolerance,
      0.5,
      reason: 'getCTM and getBBox come back as float32',
    );
  });

  test('expectOracleColour compares as ARGB and reports hex on failure', () {
    expectOracleColour(
      'fill',
      const Color(0xFF242424),
      const Color(0xFF242424),
    );
    expectOracleColour('fill', null, null);
    expect(
      () => expectOracleColour(
        'fill',
        const Color(0xFF242424),
        const Color(0xFF252424),
      ),
      throwsA(
        isA<TestFailure>().having(
          (failure) => failure.message,
          'message',
          contains('#FF242424'),
        ),
      ),
      reason: 'a colour failure must print the hex, not a Color instance',
    );
    expect(
      () => expectOracleColour('fill', null, const Color(0xFF242424)),
      throwsA(
        isA<TestFailure>().having(
          (failure) => failure.message,
          'message',
          contains('no paint'),
        ),
      ),
      reason:
          'fill: none against a colour is a real difference, and the '
          'message must say which side had no paint',
    );
  });

  test('the number, offset and rect comparators name what disagreed', () {
    expectOracleNumber('rStart', 64.5, 64.505);
    expectOracleOffset('tick', const Offset(1, 2), const Offset(1.005, 2));
    expectOracleRect(
      'bar',
      const Rect.fromLTWH(0, 0, 10, 20),
      const Rect.fromLTWH(0, 0, 10.005, 20),
    );
    expect(
      () => expectOracleNumber('rStart', 64.5, 65),
      throwsA(
        isA<TestFailure>().having(
          (failure) => failure.message,
          'message',
          allOf(contains('rStart'), contains('64.5'), contains('65')),
        ),
      ),
      reason:
          'half a pixel is a failure at the geometry tolerance, and the '
          'message must carry both values',
    );
    expect(
      () => expectOracleOffset('tick', const Offset(1, 2), const Offset(1, 3)),
      throwsA(
        isA<TestFailure>().having(
          (failure) => failure.message,
          'message',
          contains('tick.dy'),
        ),
      ),
      reason: 'the axis that disagreed must be named, not just the offset',
    );
  });

  test('soleElement refuses to guess when several match', () {
    final story = loadOracleStory('charts-areachart--area-chart-basic');
    final domain = story.soleElement(
      'path',
      where: (element) => element.parent == 0,
    );
    expect(
      domain.d,
      'M64.5,6V0.5H680.5V6',
      reason:
          'the x axis has exactly one domain path, so it is selectable '
          'without an index',
    );
    expect(
      () => story.soleElement('g'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('<g> elements matching the predicate, not'),
        ),
      ),
      reason:
          'with 128 elements in one chart, silently taking the first '
          'would mean asserting against a shape nobody chose',
    );
  });

  test('a gradient carries its stops in order', () {
    final story = loadOracleStory('charts-sankeychart--sankey-chart-basic');
    final gradients = story.primary.gradients;
    expect(
      gradients,
      isNotEmpty,
      reason: 'SankeyChartBasic paints its links with 8 linearGradient defs',
    );
    expect(
      gradients.first.stops.length,
      2,
      reason: 'each link gradient runs from the source colour to the target',
    );
    expect(
      gradients.first.stops.first.offset,
      0,
      reason:
          'SankeyChart.tsx:755-756 authors offset="0" and offset="100%", '
          'not 0/1, so the offsets are not normalised',
    );
    expect(
      gradients.first.stops.last.offset,
      100,
      reason: 'the second stop is offset="100%", recorded as authored',
    );
    expect(
      gradients.first.stops.first.color.toARGB32(),
      isNot(gradients.first.stops.last.color.toARGB32()),
      reason: 'a gradient whose ends match would be a flat fill',
    );
  });

  test('legend boxes are captured because upstream draws them in HTML', () {
    final story = loadOracleStory('charts-legends--legends-basic');
    final texts = story.boxes('fui-legend__text');
    expect(
      texts,
      isNotEmpty,
      reason:
          'Legends.tsx:113-163 renders the legend as div elements apart '
          'from its shape svg, so an SVG-only capture would verify none of '
          'plan 04',
    );
    expect(
      texts.first.rect.width,
      greaterThan(0),
      reason: 'a zero-width legend label means the capture read a hidden node',
    );
    expect(
      texts.first.text,
      'Legend 1',
      reason: 'measured: the first legend label is "Legend 1"',
    );
    expect(
      texts.first.color?.toARGB32(),
      0xFF242424,
      reason: 'measured: color resolved to rgb(36, 36, 36)',
    );
  });

  test('an HTML-only story is usable through boxes() alone', () {
    // charts-legends--legends-overflow renders no svg whatsoever: its swatches
    // are `fui-legend__rect` divs. Measured 2026-08-08: 17 items of which the
    // first 6 fit the 944 x 32 legend root, pitch 86.890625 px, and the 11 that
    // overflow are recorded at the zero rect because upstream gives them
    // `display: none`.
    final story = loadOracleStory('charts-legends--legends-overflow');
    expect(
      story.hasSvg,
      isFalse,
      reason:
          'this story is the HTML-only case the schema exists to admit; if '
          'it now has an svg, upstream changed and the anchors below moved',
    );
    expect(
      story.width,
      944,
      reason:
          'with no svg, width/height are the widest fui- box — the legend '
          'root at [24, 48, 944, 32]',
    );
    final rects = story.boxes('fui-legend__rect');
    expect(
      rects.length,
      17,
      reason:
          'all 17 items are recorded, overflowed or not, so a consumer can '
          'see how many did not fit',
    );
    final visible = rects.where((box) => box.rect.width > 0).toList();
    expect(
      visible.length,
      6,
      reason:
          'six of the seventeen fit, which is the whole point of the '
          'story. An overflowed item is the zero rect at (-16, -16) because '
          'upstream hides it with display:none — filter on width, never count '
          'the list.',
    );
    expectOracleNumber(
      'legend item pitch',
      86.890625,
      visible[1].rect.left - visible[0].rect.left,
    );
    expect(
      () => story.primary,
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(contains('HTML-only'), contains('boxes(')),
        ),
      ),
      reason:
          'primary must name the HTML-only case and point at boxes(), not '
          'fail with Dart\'s bare "No element"',
    );
  });

  test('every story in the corpus loads', () {
    final ids = oracleStoryIds();
    expect(
      ids.length,
      greaterThanOrEqualTo(80),
      reason: 'a shrunken id list would make the loop below vacuous',
    );
    var withSvg = 0;
    for (final id in ids) {
      final story = loadOracleStory(id);
      expect(
        story.id,
        id,
        reason:
            'the id inside the fixture must match its file name, or a '
            'consumer asserting against story A is reading story B',
      );
      if (story.hasSvg) {
        withSvg++;
      }
    }
    expect(
      withSvg,
      ids.length - 3,
      reason:
          'exactly three Legends stories are HTML-only; every other story '
          'must parse an svg, and a paint or CSS value this loader cannot read '
          'throws while constructing the story rather than at assert time',
    );
  });
}
