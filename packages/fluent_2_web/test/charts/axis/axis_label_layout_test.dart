import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:fluent_2_web/src/charts/axis/axis_label_layout.dart';
import 'package:fluent_2_web/src/charts/axis/axis_types.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_measurer.dart';
import 'package:fluent_2_web/src/charts/model/chart_value.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A deterministic stand-in for a real font: every code unit is six pixels wide.
double _sixPerChar(String text) => text.length * 6.0;

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

/// Replays the glyph metrics Chrome recorded for one Oracle B story.
///
/// This is a fixture replay, not a second measurer: the production measurer is
/// the only thing that ever measures text, and it cannot reproduce Segoe UI
/// under `flutter test` because the font is not installed. Feeding it the
/// captured widths and ascents is what lets the rotation geometry be checked
/// against the live browser rather than against itself.
class _ReplayedMeasurer extends FluentChartTextMeasurer {
  _ReplayedMeasurer(this.captured);

  /// Metrics by label text.
  final Map<String, FluentChartTextMetrics> captured;

  @override
  FluentChartTextMetrics measure(String text, TextStyle style) {
    final metrics = captured[text];
    if (metrics == null) {
      throw StateError('No captured metrics for "$text".');
    }
    return metrics;
  }
}

void main() {
  group('truncateTextToFitWidth', () {
    test('returns the text untouched when it already fits', () {
      expect(
        truncateTextToFitWidth('short', 100, _sixPerChar),
        'short',
        reason: 'utilities.ts:2697-2699 short-circuits before the search.',
      );
    });

    test('binary-searches the longest prefix that fits with an ellipsis', () {
      expect(
        truncateTextToFitWidth('abcdefghij', 48, _sixPerChar),
        'abcde...',
        reason:
            'utilities.ts:2701-2712 — 8 code units at 6px each is exactly 48, so '
            'five characters plus the ellipsis is the widest candidate that fits.',
      );
    });

    test('never returns fewer than one character before the ellipsis', () {
      expect(
        truncateTextToFitWidth('abcdefghij', 1, _sixPerChar),
        'a...',
        reason:
            'utilities.ts:2702 seeds lo at 1, so the minimum output is one '
            'character plus the ellipsis even when that still overflows.',
      );
    });
  });

  group('createYAxisLabels', () {
    test('appends the ellipsis in LTR', () {
      final labels = createYAxisLabels(
        <String>['Australia'],
        4,
        truncateLabel: true,
        isRtl: false,
      );
      expect(
        labels.single.lines.single.text,
        'Aust...',
        reason: 'utilities.ts:1211-1213 — slice then ellipsis.',
      );
      expect(
        labels.single.fullText,
        'Australia',
        reason:
            'utilities.ts:1220 stashes the original on data-full for the tooltip.',
      );
      expect(
        labels.single.truncated,
        isTrue,
        reason: 'the label was shortened.',
      );
    });

    test('prepends the ellipsis in RTL', () {
      final labels = createYAxisLabels(
        <String>['Australia'],
        4,
        truncateLabel: true,
        isRtl: true,
      );
      expect(
        labels.single.lines.single.text,
        '...Aust',
        reason: 'utilities.ts:1211 puts the ellipsis first under RTL.',
      );
    });

    test('leaves a short label alone', () {
      final labels = createYAxisLabels(
        <String>['UK'],
        4,
        truncateLabel: true,
        isRtl: false,
      );
      expect(
        labels.single.lines.single.text,
        'UK',
        reason:
            'utilities.ts:1227 keeps the whole word when it is short enough.',
      );
      expect(labels.single.truncated, isFalse, reason: 'nothing was cut.');
    });

    test('keeps the full text when truncation is off', () {
      final labels = createYAxisLabels(
        <String>['Australia'],
        4,
        truncateLabel: false,
        isRtl: false,
      );
      expect(
        labels.single.lines.single.text,
        'Australia',
        reason:
            'utilities.ts:1226 only sets the tspan text inside the truncateLabel '
            'branch, leaving the element empty otherwise. An empty y axis is an '
            'accessibility regression, so the port renders the full label — spec '
            'section 5.2 exception 2.',
      );
    });
  });

  group('createYAxisLabels against Oracle B', () {
    // The one captured story whose y axis is a truncated string axis:
    // showYAxisLablesTooltip routes through createYAxisLabels
    // (CartesianChart.tsx:400-406) with the default noOfCharsToTruncate of 4
    // (`:403`).
    const storyId =
        'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-string-axis-tooltip';
    const noOfCharsToTruncate = 4;

    test('reproduces every rendered y-axis tspan', () {
      final story = _loadOracleStory(storyId);
      final elements =
          (story['svgs'] as List<dynamic>).first as Map<String, dynamic>;
      final tspans = (elements['elements'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .where((element) => element['tag'] == 'tspan')
          .toList(growable: false);

      // Count guard: the capture holds exactly four y-axis ticks, and the x axis
      // of this story renders bare <text> with no tspan child, so a rename or a
      // re-capture that lost the y axis would otherwise leave this loop
      // asserting nothing.
      expect(
        tspans,
        hasLength(4),
        reason:
            '$storyId captured four y-axis tick tspans; a different count means '
            'the fixture no longer describes the axis this test reads.',
      );

      // The capture records the rendered tspan text but not the data-full
      // attribute, so the originals come from the story's own category names.
      // Only their first four code units and their length matter here, both of
      // which the rendered 'Stri...' pins.
      const fullLabels = <String>[
        'String One',
        'String Two',
        'String Three',
        'String Four',
      ];
      final labels = createYAxisLabels(
        fullLabels,
        noOfCharsToTruncate,
        truncateLabel: true,
        isRtl: false,
      );

      for (var index = 0; index < tspans.length; index++) {
        expect(
          labels[index].lines,
          hasLength(1),
          reason:
              'utilities.ts:1218-1224 appends exactly one tspan per tick, and '
              'the fixture has one tspan per <text>.',
        );
        expect(
          labels[index].lines.single.text,
          tspans[index]['text'],
          reason:
              'the live axis rendered ${tspans[index]['text']} for '
              '${fullLabels[index]}: four code units of the label followed by '
              'three ASCII full stops, not a leading ellipsis and not a U+2026.',
        );
      }
    });
  });

  group('wrapXLabels', () {
    testWidgets('truncates rather than wrapping when the tooltip is on', (
      tester,
    ) async {
      final layout = wrapXLabels(
        <String>['Western Australia'],
        measurer: FluentChartTextMeasurer(),
        style: const TextStyle(fontSize: 10),
        noOfCharsToTruncate: 4,
        showXAxisLabelsTooltip: true,
      );
      expect(
        layout.labels.single.lines.single.text,
        'West...',
        reason:
            'utilities.ts:1156-1157 — one tspan holding the truncated word.',
      );
      expect(
        layout.reserveHeight,
        0,
        reason:
            'utilities.ts:1180 skips the height computation entirely in tooltip '
            'mode, so nothing is removed from the plot.',
      );
    });

    testWidgets('breaks on whitespace once a line exceeds the width', (
      tester,
    ) async {
      final layout = wrapXLabels(
        <String>['New South Wales'],
        measurer: FluentChartTextMeasurer(),
        style: const TextStyle(fontSize: 10),
        noOfCharsToTruncate: 100,
        showXAxisLabelsTooltip: false,
        // 20 logical pixels admits roughly four characters at 10px Segoe.
        width: 20.0,
      );
      expect(
        layout.labels.single.lines.length,
        greaterThan(1),
        reason: 'utilities.ts:1159-1177 greedily wraps on the /\\s+/ split.',
      );
      expect(
        layout.labels.single.lines.first.dyEm,
        0.71,
        reason: 'the first tspan keeps the axis base dy (utilities.ts:1147).',
      );
      expect(
        layout.labels.single.lines[1].dyEm,
        closeTo(0.71 + 1.1, 1e-9),
        reason: 'utilities.ts:1145 and :1173 — each new line adds 1.1 ems.',
      );
    });

    testWidgets('never breaks a single word', (tester) async {
      final layout = wrapXLabels(
        <String>['Australia'],
        measurer: FluentChartTextMeasurer(),
        style: const TextStyle(fontSize: 10),
        noOfCharsToTruncate: 100,
        showXAxisLabelsTooltip: false,
        width: 1.0,
      );
      expect(
        layout.labels.single.lines.length,
        1,
        reason:
            'utilities.ts:1165 requires line.length > 1 before breaking, so one '
            'long word overflows rather than splitting.',
      );
    });

    testWidgets('reserves twelve pixels per extra line at minimum', (
      tester,
    ) async {
      final layout = wrapXLabels(
        <String>['New South Wales'],
        measurer: FluentChartTextMeasurer(),
        style: const TextStyle(fontSize: 10),
        noOfCharsToTruncate: 100,
        showXAxisLabelsTooltip: false,
        width: 20.0,
      );
      expect(
        layout.reserveHeight,
        greaterThanOrEqualTo(12),
        reason:
            'utilities.ts:1181 seeds maxHeight at 12 and :1187 multiplies by '
            '(maxLines - 1), so two lines reserve at least 12.',
      );
    });

    testWidgets('accepts a per-tick width list', (tester) async {
      final layout = wrapXLabels(
        <String>['New South Wales', 'Victoria'],
        measurer: FluentChartTextMeasurer(),
        style: const TextStyle(fontSize: 10),
        noOfCharsToTruncate: 100,
        showXAxisLabelsTooltip: false,
        width: <double>[20, 400],
      );
      expect(
        layout.labels[1].lines.length,
        1,
        reason:
            'utilities.ts:1159 indexes the width array by tick, so the second '
            'label gets 400px and never wraps.',
      );
    });
  });

  group('wrapXLabels against Oracle B', () {
    // The captured story whose *x* axis routes through createWrapOfXLabels with
    // showXAxisLablesTooltip on (CartesianChart.tsx:390-397), which is the
    // truncating branch at utilities.ts:1156-1157, with the default
    // noOfCharsToTruncate of four.
    //
    // No captured story sets wrapXAxisLabels, so the wrapping branch
    // (utilities.ts:1159-1177) has no oracle: none of the 90 fixtures holds a
    // <text> with more than one <tspan> child. The count guard below therefore
    // pins the tooltip branch only, and the wrapping geometry rests on the
    // hand-written cases above.
    const storyId = 'charts-verticalbarchart--vertical-bar-axis-tooltip';
    const noOfCharsToTruncate = 4;

    testWidgets('reproduces every rendered x-axis tspan', (tester) async {
      final story = _loadOracleStory(storyId);
      final elements =
          ((story['svgs'] as List<dynamic>).first
                  as Map<String, dynamic>)['elements']
              as List<dynamic>;
      final tspans = elements
          .cast<Map<String, dynamic>>()
          .where((element) => element['tag'] == 'tspan')
          .toList(growable: false);

      // Count guard: the capture holds exactly four x-axis ticks, and this
      // story's y axis renders bare <text> with no tspan child, so a re-capture
      // that lost the x axis would otherwise leave the loop below asserting
      // nothing.
      expect(
        tspans,
        hasLength(4),
        reason:
            '$storyId captured four x-axis tick tspans; a different count means '
            'the fixture no longer describes the axis this test reads.',
      );

      // The capture records the rendered tspan text but not the data-full
      // attribute, so the originals are reconstructed from the story's own
      // category names. Only each label's first four code units and whether its
      // length exceeds four are load-bearing, and both are pinned by the
      // rendered text asserted below — in particular 'Data' is exactly four code
      // units and came back whole.
      const fullLabels = <String>[
        'Simple Text',
        'Showing Truncation',
        'Large Text Value',
        'Data',
      ];
      final layout = wrapXLabels(
        fullLabels,
        measurer: FluentChartTextMeasurer(),
        style: const TextStyle(fontSize: 10),
        noOfCharsToTruncate: noOfCharsToTruncate,
        showXAxisLabelsTooltip: true,
      );

      expect(
        layout.reserveHeight,
        0,
        reason:
            'the live axis reserved nothing: every captured tick is a single '
            'tspan, so utilities.ts:1180 never ran the height computation.',
      );

      for (var index = 0; index < tspans.length; index++) {
        expect(
          layout.labels[index].lines,
          hasLength(1),
          reason:
              'utilities.ts:1148-1157 appends exactly one tspan per tick in '
              'tooltip mode, and the fixture has one tspan per <text>.',
        );
        expect(
          layout.labels[index].lines.single.text,
          tspans[index]['text'],
          reason:
              'the live axis rendered ${tspans[index]['text']} for '
              '${fullLabels[index]}: four code units followed by three ASCII '
              'full stops, and no ellipsis at all once the label is exactly '
              'four code units long.',
        );
      }
    });
  });

  group('shrinkToFit', () {
    testWidgets('drops one code unit at a time and reports overflow', (
      tester,
    ) async {
      final measurer = FluentChartTextMeasurer();
      const style = TextStyle(fontSize: 10);
      final result = shrinkToFit('Fluent charts', style, 1, measurer);
      expect(
        result.overflowed,
        isTrue,
        reason: 'utilities.ts:1241-1246 sets isOverflowing on the first cut.',
      );
      expect(
        result.text.length,
        lessThan('Fluent charts'.length),
        reason: 'the loop shortens the string until it fits or empties.',
      );
    });
  });

  group('rotateXAxisLabels', () {
    testWidgets('rotates by minus forty-five degrees', (tester) async {
      final layout = rotateXAxisLabels(
        <String>['Queensland'],
        measurer: FluentChartTextMeasurer(),
        style: const TextStyle(fontSize: 10),
      );
      expect(
        layout.rotationRadians,
        closeTo(-math.pi / 4, 1e-12),
        reason:
            'utilities.ts:1820 and :1839 always rotate by -45, with no RTL case.',
      );
    });

    testWidgets('reserves the vertical extent of the rotated box', (
      tester,
    ) async {
      final short = rotateXAxisLabels(
        <String>['NSW'],
        measurer: FluentChartTextMeasurer(),
        style: const TextStyle(fontSize: 10),
      );
      final long = rotateXAxisLabels(
        <String>['New South Wales and Victoria'],
        measurer: FluentChartTextMeasurer(),
        style: const TextStyle(fontSize: 10),
      );
      expect(
        long.reserveHeight,
        greaterThan(short.reserveHeight),
        reason:
            'utilities.ts:1845 returns floor(maxHeight / 1.414) where maxHeight '
            'is the rotated bounding box, so a longer label costs more height.',
      );
      expect(
        short.reserveHeight,
        short.reserveHeight.floorToDouble(),
        reason: 'utilities.ts:1845 floors the result.',
      );
    });

    testWidgets('keeps every label on one line', (tester) async {
      final layout = rotateXAxisLabels(
        <String>['New South Wales'],
        measurer: FluentChartTextMeasurer(),
        style: const TextStyle(fontSize: 10),
      );
      expect(
        layout.labels.single.lines.length,
        1,
        reason:
            'rotation never wraps — utilities.ts:1801-1846 only sets transforms.',
      );
    });
  });

  group('rotateXAxisLabels against Oracle B', () {
    // The one captured story that sets rotateXAxisLables. Its four x-axis tick
    // groups carry `translate(x, maxHeight / 2)rotate(-45)`
    // (utilities.ts:1836-1841), so the capture pins both the rotation and the
    // maxHeight that utilities.ts:1845 divides by 1.414.
    const storyId = 'charts-verticalbarchart--vertical-bar-rotate-labels';

    testWidgets('reproduces the rotation and the reserved height', (
      tester,
    ) async {
      final story = _loadOracleStory(storyId);
      final elements =
          (((story['svgs'] as List<dynamic>).first
                      as Map<String, dynamic>)['elements']
                  as List<dynamic>)
              .cast<Map<String, dynamic>>();
      final byIndex = <int, Map<String, dynamic>>{
        for (final element in elements) element['index'] as int: element,
      };

      bool isRotated(Map<String, dynamic>? element) =>
          (element?['transform'] as String? ?? '').contains('rotate(-45)');

      final tickTexts = elements
          .where(
            (element) =>
                element['tag'] == 'text' &&
                isRotated(byIndex[element['parent'] as int]),
          )
          .toList(growable: false);

      // Count guard: the story has four categories, so a re-capture that lost
      // the rotated x axis would otherwise leave the metric replay below empty
      // and every assertion vacuous.
      expect(
        tickTexts,
        hasLength(4),
        reason:
            '$storyId captured four rotated x-axis tick labels; a different '
            'count means the fixture no longer describes the axis this test '
            'reads.',
      );

      // The tick text's `y` is d3-axis's `spacing` and its `dy` is 0.71em
      // (d3-axis/src/axis.js:46, :72), so the alphabetic baseline sits at
      // `y + 0.71 * fontSize` and the captured getBBox top and bottom give the
      // ascent and descent Chrome resolved for 10px Segoe UI.
      const fontSize = 10.0;
      const baseDyEm = 0.71;
      final captured = <String, FluentChartTextMetrics>{};
      final labels = <String>[];
      for (final text in tickTexts) {
        final label = text['text'] as String;
        final bbox = (text['bbox'] as List<dynamic>).cast<num>();
        final baseline = (text['y'] as num).toDouble() + baseDyEm * fontSize;
        final top = bbox[1].toDouble();
        final height = bbox[3].toDouble();
        labels.add(label);
        captured[label] = FluentChartTextMetrics(
          width: bbox[2].toDouble(),
          height: height,
          ascent: baseline - top,
          descent: top + height - baseline,
          xHeight: fontSize * FluentChartTextMetrics.xHeightRatio,
        );
      }

      final layout = rotateXAxisLabels(
        labels,
        measurer: _ReplayedMeasurer(captured),
        style: const TextStyle(fontSize: fontSize),
      );

      // Every tick group's CTM is the live rotation matrix; a = cos(theta) and
      // b = sin(theta).
      final tickGroup = byIndex[tickTexts.first['parent'] as int]!;
      final ctm = (tickGroup['ctm'] as List<dynamic>).cast<num>();
      expect(
        layout.rotationRadians,
        closeTo(math.atan2(ctm[1].toDouble(), ctm[0].toDouble()), 1e-5),
        reason:
            'the live tick group rotated by ${ctm[0]}, ${ctm[1]}, which is -45 '
            'degrees (utilities.ts:1839).',
      );

      // utilities.ts:1839 translates y by maxHeight / 2, so the captured
      // translation recovers the maxHeight upstream measured.
      final translateY = double.parse(
        (tickGroup['transform'] as String)
            .substring(
              (tickGroup['transform'] as String).indexOf('(') + 1,
              (tickGroup['transform'] as String).indexOf(')'),
            )
            .split(',')[1],
      );
      final capturedMaxHeight = 2 * translateY;
      expect(
        capturedMaxHeight,
        closeTo(145.16018676757812, 1e-9),
        reason:
            'guards the fixture itself: the rotated bounding box of the widest '
            'tick was 145.16 logical pixels, and the assertion below is only '
            'meaningful while that is the number the browser produced.',
      );
      expect(
        layout.reserveHeight,
        (capturedMaxHeight / 1.414).floorToDouble(),
        reason:
            'utilities.ts:1845 returns floor(maxHeight / 1.414), which for the '
            'captured $capturedMaxHeight is 102. Reaching it requires the local '
            'box to be the tick group getBBox *rectangle* — the captured group '
            'bbox is [-89.59375, 0, 179.1875, 26.1] — mapped through the CTM, '
            'because getBoundingClientRect transforms the object bounding box '
            'rather than each child box.',
      );
    });
  });

  group('calcMaxLabelWidthWithTransform', () {
    testWidgets('shrinks by cos(pi/4) for rotated band labels', (tester) async {
      final measurer = FluentChartTextMeasurer();
      const style = TextStyle(fontSize: 10);
      final plain = calcMaxLabelWidthWithTransform(
        <String>['Queensland'],
        measurer: measurer,
        style: style,
        xAxisType: FluentChartAxisType.category,
      );
      final rotated = calcMaxLabelWidthWithTransform(
        <String>['Queensland'],
        measurer: measurer,
        style: style,
        xAxisType: FluentChartAxisType.category,
        rotateXAxisLabels: true,
      );
      expect(
        rotated,
        (plain * math.cos(math.pi / 4)).ceilToDouble(),
        reason:
            'CartesianChart.tsx:578-581 multiplies the longest width by '
            'cos(pi/4) and ceils it.',
      );
    });

    testWidgets('measures the truncated form in tooltip mode', (tester) async {
      final measurer = FluentChartTextMeasurer();
      const style = TextStyle(fontSize: 10);
      final full = calcMaxLabelWidthWithTransform(
        <String>['Queensland'],
        measurer: measurer,
        style: style,
        xAxisType: FluentChartAxisType.category,
      );
      final truncated = calcMaxLabelWidthWithTransform(
        <String>['Queensland'],
        measurer: measurer,
        style: style,
        xAxisType: FluentChartAxisType.category,
        showXAxisLabelsTooltip: true,
      );
      expect(
        truncated,
        lessThan(full),
        reason:
            "CartesianChart.tsx:584-592 measures 'Quee...' rather than the whole "
            'word.',
      );
    });

    testWidgets('measures words and floors at ten when wrapping', (
      tester,
    ) async {
      final width = calcMaxLabelWidthWithTransform(
        <String>['a b'],
        measurer: FluentChartTextMeasurer(),
        style: const TextStyle(fontSize: 10),
        xAxisType: FluentChartAxisType.category,
        wrapXAxisLabels: true,
      );
      expect(
        width,
        kDefaultWrapWidth,
        reason:
            'CartesianChart.tsx:595-607 measures the longest WORD and takes '
            'max(ceil(longest), DEFAULT_WRAP_WIDTH), so a single narrow letter '
            'still yields 10.',
      );
    });

    testWidgets('ignores rotation on a numeric axis', (tester) async {
      final measurer = FluentChartTextMeasurer();
      const style = TextStyle(fontSize: 10);
      final numeric = calcMaxLabelWidthWithTransform(
        <String>['1234'],
        measurer: measurer,
        style: style,
        xAxisType: FluentChartAxisType.numeric,
        rotateXAxisLabels: true,
      );
      final plain = calcMaxLabelWidthWithTransform(
        <String>['1234'],
        measurer: measurer,
        style: style,
        xAxisType: FluentChartAxisType.numeric,
      );
      expect(
        numeric,
        plain,
        reason:
            'CartesianChart.tsx:578 gates the rotation branch on '
            'xAxisType === StringAxis.',
      );
    });
  });
}
