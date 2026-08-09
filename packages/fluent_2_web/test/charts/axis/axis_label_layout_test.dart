import 'dart:convert';
import 'dart:io';

import 'package:fluent_2_web/src/charts/axis/axis_label_layout.dart';
import 'package:fluent_2_web/src/charts/internal/chart_text_measurer.dart';
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
}
