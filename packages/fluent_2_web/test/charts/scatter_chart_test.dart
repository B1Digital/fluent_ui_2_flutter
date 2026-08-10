import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/scatter_chart_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// The four captured ScatterChart stories. Every one of them passes a
/// `markerSize` on every point, so none of them witnesses the bare 4/6 radii —
/// those are asserted against `ScatterChart.tsx:427-428` instead. What they do
/// witness is the paint: the circle stroke width, and the dashed vertical hover
/// rule that upstream renders once per chart with `visibility: hidden`.
const List<String> _scatterStories = <String>[
  'charts-scatterchart--scatter-chart-default',
  'charts-scatterchart--scatter-chart-string',
  'charts-scatterchart--scatter-chart-date',
  'charts-scatterchart--scatter-chart-log-axis-example',
];

void main() {
  const states = <WidgetState>{};
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  group('FluentScatterChartStyle', () {
    test("resolves the ScatterChart marker radii, not LineChart's", () {
      final style = resolveFluentScatterChartStyle(theme);
      expect(
        style.markerRadius!.resolve(states),
        4.0,
        reason: 'ScatterChart.tsx:427 passes defaultRadius 4',
      );
      expect(
        style.markerRadius!.resolve(<WidgetState>{WidgetState.hovered}),
        6.0,
        reason: 'ScatterChart.tsx:428 passes activeRadius 6',
      );
    });

    test('dims a deselected marker to one tenth', () {
      final style = resolveFluentScatterChartStyle(theme);
      expect(
        style.markerOpacity!.resolve(<WidgetState>{WidgetState.disabled}),
        0.1,
        reason: 'ScatterChart.tsx:473 uses opacity 0.1 for a dimmed marker',
      );
      expect(
        style.markerOpacity!.resolve(states),
        1.0,
        reason: 'ScatterChart.tsx:473 — a selected marker is fully opaque',
      );
    });

    test('the hover rule is a hard-coded hex upstream, not a token', () {
      final style = resolveFluentScatterChartStyle(theme);
      expect(
        style.hoverLineColor!.resolve(states)!.toARGB32(),
        0xFF323130,
        reason: "ScatterChart.tsx:756 hard-codes stroke='#323130'",
      );
    });

    test('Oracle B: every captured story paints that same hover rule', () {
      final style = resolveFluentScatterChartStyle(theme);
      var asserted = 0;
      for (final id in _scatterStories) {
        final story = loadOracleStory(id);
        final rules = story
            .byTag('line')
            .where((e) => e.strokeDasharray != 'none')
            .toList();
        expect(
          rules,
          hasLength(1),
          reason:
              '$id must capture exactly one dashed line — the hover rule '
              'at ScatterChart.tsx:750-759',
        );
        final rule = rules.single;
        expectOracleColour(
          '$id hover rule stroke',
          rule.stroke,
          style.hoverLineColor!.resolve(states),
        );
        expectOracleNumber(
          '$id hover rule stroke width',
          rule.strokeWidth,
          style.hoverLineWidth!.resolve(states)!,
        );
        expect(
          rule.strokeDasharray,
          '5px, 5px',
          reason: '$id — ScatterChart.tsx:759 sets strokeDasharray 5,5',
        );
        expect(
          style.hoverLineDashPattern!.resolve(states),
          <double>[5, 5],
          reason: '$id — the port must carry that same dash pattern',
        );
        asserted++;
      }
      expect(
        asserted,
        _scatterStories.length,
        reason: 'every listed story must have been asserted, not skipped',
      );
    });

    test('Oracle B: a marker circle is stroked one pixel wide', () {
      final style = resolveFluentScatterChartStyle(theme);
      var asserted = 0;
      for (final id in _scatterStories) {
        final story = loadOracleStory(id);
        final circles = story.byTag('circle');
        expect(
          circles,
          isNotEmpty,
          reason: '$id must capture at least one marker circle',
        );
        for (final circle in circles) {
          expectOracleNumber(
            '$id marker stroke width',
            circle.strokeWidth,
            style.markerStrokeWidth!.resolve(states)!,
          );
          expectOracleNumber(
            '$id marker opacity',
            circle.opacity,
            style.markerOpacity!.resolve(states)!,
          );
          asserted++;
        }
      }
      expect(
        asserted,
        greaterThanOrEqualTo(_scatterStories.length),
        reason: 'at least one circle per story must have been asserted',
      );
    });

    test('the active marker inverts to the canvas colour', () {
      final style = resolveFluentScatterChartStyle(theme);
      expect(
        style.activeMarkerFillColor!.resolve(<WidgetState>{
          WidgetState.hovered,
        }),
        theme.colors.neutralBackground1,
        reason:
            'ScatterChart.tsx:356-358 returns colorNeutralBackground1 for '
            'the active point rather than growing a ring',
      );
    });

    test('merge lets the caller win field by field', () {
      final base = resolveFluentScatterChartStyle(theme);
      final merged = base.merge(
        FluentScatterChartStyle.from(markerStrokeWidth: 4),
      );
      expect(
        merged.markerStrokeWidth!.resolve(states),
        4.0,
        reason: 'the overriding style must win',
      );
      expect(
        merged.markerRadius!.resolve(states),
        4.0,
        reason: 'fields absent from the override must be inherited',
      );
    });

    test('equal styles compare equal and hash equal', () {
      final a = FluentScatterChartStyle.from(markerRadius: 4);
      final b = FluentScatterChartStyle.from(markerRadius: 4);
      expect(
        a,
        b,
        reason: 'value equality is part of the house style contract',
      );
      expect(a.hashCode, b.hashCode, reason: 'hashCode must agree with ==');
    });

    test('copyWith replaces only the named field', () {
      final base = resolveFluentScatterChartStyle(theme);
      final copy = base.copyWith(
        markerLabelGap: const WidgetStatePropertyAll<double?>(20),
      );
      expect(
        copy.markerLabelGap!.resolve(states),
        20.0,
        reason: 'the named field must be replaced',
      );
      expect(
        copy.markerLabelMinGap!.resolve(states),
        16.0,
        reason: 'ScatterChart.tsx:484 — the unnamed floor must survive',
      );
    });
  });
}
