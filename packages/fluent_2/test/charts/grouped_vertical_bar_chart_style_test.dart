import 'package:fluent_2/src/charts/grouped_vertical_bar_chart_style.dart';
import 'package:fluent_2/src/charts/internal/chart_text_styles.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// The defaults are checked against the captured GVBC stories wherever the
/// capture records them: the bar-label gaps and the idle line-marker geometry
/// are all read off `charts-groupedverticalbarchart--*` rather than
/// hand-copied from the source a second time.
void main() {
  const idle = <WidgetState>{};
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  test('the resolved defaults match the source', () {
    final style = resolveFluentGroupedVerticalBarChartStyle(theme);
    expect(
      style.barCornerRadius!.resolve(idle),
      3.0,
      reason: 'GroupedVerticalBarChart.tsx:588 — rx when roundCorners is on.',
    );
    expect(
      style.barLabelStyle!.resolve(idle),
      FluentChartTextStyles.of(theme).barLabel,
      reason:
          'useGroupedVerticalBarChartStyles.styles.ts:35 uses the shared '
          'getBarLabelStyle, which FluentChartTextStyles.barLabel resolves.',
    );
    expect(
      style.minBarLabelWidth!.resolve(idle),
      16.0,
      reason:
          'GroupedVerticalBarChart.tsx:620 gates the total label on '
          'Math.ceil(_barWidth) >= 16.',
    );
    expect(
      style.lineStrokeWidth!.resolve(idle),
      3.0,
      reason: 'GroupedVerticalBarChart.tsx:852.',
    );
    expect(
      style.lineDotFillColor!.resolve(idle),
      theme.colors.neutralBackground1,
      reason: 'GroupedVerticalBarChart.tsx:871.',
    );
    expect(
      style.lineBorderColor!.resolve(idle),
      theme.colors.neutralBackground1,
      reason: 'GroupedVerticalBarChart.tsx:836.',
    );
  });

  test('the two-armed properties carry both arms of their ternary', () {
    final style = resolveFluentGroupedVerticalBarChartStyle(theme);
    expect(
      style.barOpacity!.resolve(idle),
      1.0,
      reason:
          'GroupedVerticalBarChart.tsx:553 emits no opacity attribute for an '
          'active bar.',
    );
    expect(
      style.barOpacity!.resolve(<WidgetState>{WidgetState.disabled}),
      0.1,
      reason:
          'GroupedVerticalBarChart.tsx:553 dims a bar to 0.1 while another '
          'legend is highlighted.',
    );
    expect(
      style.lineDotRadius!.resolve(<WidgetState>{WidgetState.selected}),
      8.0,
      reason: 'GroupedVerticalBarChart.tsx:870 — the highlighted point.',
    );
  });

  test('the captured line story pins the idle marker geometry', () {
    const storyId =
        'charts-groupedverticalbarchart--grouped-vertical-bar-chart-line';
    final story = loadOracleStory(storyId);
    final circles = story.byTag('circle');
    expect(
      circles,
      isNotEmpty,
      reason: '$storyId must capture the line series point markers',
    );
    final style = resolveFluentGroupedVerticalBarChartStyle(theme);
    for (final circle in circles) {
      expectOracleNumber(
        'idle marker radius',
        circle.r!,
        style.lineDotRadius!.resolve(idle)!,
      );
      expectOracleNumber(
        'idle marker stroke width',
        circle.strokeWidth,
        style.lineDotStrokeWidth!.resolve(idle)!,
      );
      expectOracleColour(
        'idle marker fill',
        circle.fill,
        style.lineDotFillColor!.resolve(idle),
      );
    }
  });

  test('the captured bar labels pin both gaps', () {
    const positiveId =
        'charts-groupedverticalbarchart--grouped-vertical-bar-default';
    const negativeId =
        'charts-groupedverticalbarchart--grouped-vertical-bar-negative';
    final style = resolveFluentGroupedVerticalBarChartStyle(theme);

    for (final entry in <String, bool>{
      positiveId: false,
      negativeId: true,
    }.entries) {
      final story = loadOracleStory(entry.key);
      final rects = story.byTag('rect');
      final texts = story.byTag('text').where((e) => e.parent >= 0).toList();
      expect(rects, isNotEmpty, reason: '${entry.key} must capture bar rects');
      // A group holds its rects first and its labels after, one for one.
      final groups = rects.map((e) => e.parent).toSet();
      var checked = 0;
      for (final group in groups) {
        final groupRects = rects.where((e) => e.parent == group).toList();
        final groupTexts = texts.where((e) => e.parent == group).toList();
        if (groupRects.length != groupTexts.length) {
          continue;
        }
        for (var i = 0; i < groupRects.length; i++) {
          // U+2212 MINUS SIGN is what formatScientificLimitWidth emits.
          final isNegative = groupTexts[i].text!.startsWith('−');
          if (isNegative != entry.value) {
            continue;
          }
          expectOracleNumber(
            '${entry.key} bar label baseline',
            groupTexts[i].y!,
            isNegative
                ? groupRects[i].y! +
                      groupRects[i].height! +
                      style.barLabelGapBelow!.resolve(idle)!
                : groupRects[i].y! - style.barLabelGapAbove!.resolve(idle)!,
          );
          checked++;
        }
      }
      expect(
        checked,
        greaterThan(0),
        reason:
            '${entry.key} must contain at least one '
            '${entry.value ? "negative" : "positive"} bar label',
      );
    }
  });

  test('the five template members behave', () {
    final base = FluentGroupedVerticalBarChartStyle.from(
      barCornerRadius: 3,
      lineStrokeWidth: 3,
    );
    expect(
      identical(base.merge(null), base),
      isTrue,
      reason: 'A null override is the identity.',
    );
    final merged = base.merge(
      FluentGroupedVerticalBarChartStyle.from(lineStrokeWidth: 5),
    );
    expect(
      merged.barCornerRadius!.resolve(idle),
      3.0,
      reason: 'merge is per-property.',
    );
    expect(
      merged.lineStrokeWidth!.resolve(idle),
      5.0,
      reason: 'The argument wins for the property it sets.',
    );
    expect(
      base
          .copyWith(barLabelGapAbove: const WidgetStatePropertyAll<double?>(9))
          .barLabelGapAbove!
          .resolve(idle),
      9.0,
      reason: 'copyWith replaces exactly the named property.',
    );
    expect(
      FluentGroupedVerticalBarChartStyle.from(barCornerRadius: 3) ==
          FluentGroupedVerticalBarChartStyle.from(barCornerRadius: 3),
      isTrue,
      reason: 'WidgetStatePropertyAll compares by value, so styles do too.',
    );
    expect(
      FluentGroupedVerticalBarChartStyle.from(barCornerRadius: 3).hashCode,
      FluentGroupedVerticalBarChartStyle.from(barCornerRadius: 3).hashCode,
      reason: 'Equal styles hash equally.',
    );
  });
}
