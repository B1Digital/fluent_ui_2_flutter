import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// `FluentSparklineStyle` is the first chart style in the package, so this file
/// also pins the shape every later chart style copies: `from` fans one value
/// across every state, `merge` is per-property, and equal styles hash equally.
void main() {
  const states = <WidgetState>{};

  test('from fans a single value across every state', () {
    final style = FluentSparklineStyle.from(
      lineStrokeWidth: 2,
      areaFillOpacity: 0.2,
      topMargin: 2,
    );
    expect(
      style.lineStrokeWidth!.resolve(states),
      2.0,
      reason: 'Sparkline.tsx:94 draws the line path at strokeWidth 2.',
    );
    expect(
      style.areaFillOpacity!.resolve(states),
      0.2,
      reason: 'Sparkline.tsx:101 fills the area at fillOpacity 0.2.',
    );
    expect(
      style.topMargin!.resolve(states),
      2.0,
      reason:
          'Sparkline.tsx:21-26 sets margin.top to 2 and every other side '
          'to 0.',
    );
  });

  test('merge overrides only the properties the argument sets', () {
    final base = FluentSparklineStyle.from(lineStrokeWidth: 2, labelDx: 8);
    final merged = base.merge(FluentSparklineStyle.from(labelDx: 12));
    expect(
      merged.lineStrokeWidth!.resolve(states),
      2.0,
      reason:
          'merge is per-property: overriding labelDx must not drop the '
          'stroke width.',
    );
    expect(
      merged.labelDx!.resolve(states),
      12.0,
      reason: 'The argument wins for the property it sets.',
    );
  });

  test('merge with null returns the receiver unchanged', () {
    final base = FluentSparklineStyle.from(lineStrokeWidth: 2);
    expect(
      identical(base.merge(null), base),
      isTrue,
      reason: 'A null override is the identity, as FluentBadgeStyle.merge is.',
    );
  });

  test('copyWith replaces only the named properties', () {
    final base = FluentSparklineStyle.from(lineStrokeWidth: 2, labelDx: 8);
    final copy = base.copyWith(
      lineColor: const WidgetStatePropertyAll<Color?>(Color(0xFF0F6CBD)),
    );
    expect(
      copy.labelDx!.resolve(states),
      8.0,
      reason: 'copyWith keeps every property it was not given.',
    );
    expect(
      copy.lineColor!.resolve(states)!.toARGB32(),
      const Color(0xFF0F6CBD).toARGB32(),
      reason:
          'Sparkline.tsx:95 has no colour fallback, so the style-level '
          'override is the only way to supply one.',
    );
  });

  test('resolve produces the upstream defaults', () {
    final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
    final style = resolveFluentSparklineStyle(theme);
    expect(
      style.lineStrokeWidth!.resolve(states),
      2.0,
      reason: 'Sparkline.tsx:94.',
    );
    expect(
      style.areaFillOpacity!.resolve(states),
      0.2,
      reason: 'Sparkline.tsx:101.',
    );
    expect(
      style.topMargin!.resolve(states),
      2.0,
      reason: 'Sparkline.tsx:21-26 — margin.top.',
    );
    expect(
      style.minRenderSize!.resolve(states),
      const Size(50, 16),
      reason:
          'Sparkline.tsx:114 emits the chart svg only when '
          'width >= 50 && height >= 16.',
    );
    expect(
      style.labelDx!.resolve(states),
      8.0,
      reason: 'Sparkline.tsx:128 anchors the value text at x="0%" dx={8}.',
    );
    expect(
      style.labelBaselineFromBottom!.resolve(states),
      5.0,
      reason: 'Sparkline.tsx:128 places the baseline at y="100%" dy={-5}.',
    );
    expect(
      style.labelTextStyle!.resolve(states)!.fontSize,
      12.0,
      reason:
          'useSparklineStyles.styles.ts:23-27 uses typographyStyles.'
          'caption1, which is 12/16 regular.',
    );
    expect(
      style.labelTextStyle!.resolve(states)!.color!.toARGB32(),
      theme.colors.neutralForeground1.toARGB32(),
      reason:
          'useSparklineStyles.styles.ts:25 fills the value text with '
          'colorNeutralForeground1.',
    );
    expect(
      style.lineColor,
      isNull,
      reason:
          'Sparkline.tsx:95 passes the series colour straight through, so the '
          'derived defaults name no line colour.',
    );
  });

  test('equal styles compare and hash equally', () {
    final a = FluentSparklineStyle.from(lineStrokeWidth: 2, labelDx: 8);
    final b = FluentSparklineStyle.from(lineStrokeWidth: 2, labelDx: 8);
    expect(a, equals(b), reason: 'Value equality is required by the theme.');
    expect(
      a.hashCode,
      equals(b.hashCode),
      reason: 'A style is a map key in the widget-state resolution cache.',
    );
    expect(
      a,
      isNot(equals(FluentSparklineStyle.from(lineStrokeWidth: 3, labelDx: 8))),
      reason: 'A differing property must break equality.',
    );
  });

  group('against the captured Sparkline stories', () {
    final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
    final stories = <OracleStory>[
      loadOracleStory('charts-sparkline--sparkline-basic'),
      loadOracleStory('charts-sparkline--sparkline-dimensions'),
    ];

    test('the two Sparkline stories are both present', () {
      expect(
        oracleStoryIds(component: 'Sparkline'),
        <String>[
          'charts-sparkline--sparkline-basic',
          'charts-sparkline--sparkline-dimensions',
        ],
        reason:
            'The count guard: every assertion below filters the captured '
            'elements, so an empty corpus must fail here rather than pass '
            'vacuously.',
      );
    });

    test('every captured line path strokes at the styled width', () {
      final style = resolveFluentSparklineStyle(theme);
      final width = style.lineStrokeWidth!.resolve(states)!;
      var seen = 0;
      for (final story in stories) {
        for (final svg in story.svgs) {
          // The line is the path upstream leaves unfilled
          // (`Sparkline.tsx:92` fill="transparent"); the area beneath it is
          // filled with the series colour.
          for (final path in svg.elements.where(
            (e) => e.tag == 'path' && e.fillOpacity == 1,
          )) {
            expectOracleNumber(
              '${story.id} line stroke-width',
              width,
              path.strokeWidth,
            );
            seen++;
          }
        }
      }
      expect(
        seen,
        14,
        reason:
            'Ten line paths in the basic story and four in the dimensions '
            'story; a changed corpus must not silently shrink this loop.',
      );
    });

    test('every captured area path fills at the styled opacity', () {
      final style = resolveFluentSparklineStyle(theme);
      final opacity = style.areaFillOpacity!.resolve(states)!;
      var seen = 0;
      for (final story in stories) {
        for (final svg in story.svgs) {
          for (final path in svg.elements.where(
            (e) => e.tag == 'path' && e.fillOpacity != 1,
          )) {
            expectOracleNumber(
              '${story.id} area fill-opacity',
              opacity,
              path.fillOpacity,
            );
            seen++;
          }
        }
      }
      expect(
        seen,
        14,
        reason: 'One area path accompanies each of the fourteen line paths.',
      );
    });

    test('every captured value label matches the styled font and inset', () {
      final style = resolveFluentSparklineStyle(theme);
      final label = style.labelTextStyle!.resolve(states)!;
      final dx = style.labelDx!.resolve(states)!;
      var seen = 0;
      for (final story in stories) {
        for (final svg in story.svgs) {
          for (final text in svg.elements.where((e) => e.tag == 'text')) {
            expectOracleNumber(
              '${story.id} value-text font-size',
              label.fontSize!,
              text.fontSize,
            );
            expect(
              text.textAnchor,
              'start',
              reason:
                  'Sparkline.tsx:128 anchors at start outside RTL, which is '
                  'why labelDx is a leading inset rather than a signed offset.',
            );
            // textAnchor is start and x is 0%, so the ink starts at exactly dx.
            expectOracleNumber(
              '${story.id} value-text left edge',
              dx,
              text.bbox!.left,
              tolerance: kOracleMeasuredTolerance,
            );
            seen++;
          }
        }
      }
      expect(
        seen,
        10,
        reason:
            'Six labels in the basic story and four in the dimensions story.',
      );
    });

    test('nothing below the render gate was captured', () {
      final minimum = resolveFluentSparklineStyle(
        theme,
      ).minRenderSize!.resolve(states)!;
      var seen = 0;
      for (final story in stories) {
        for (final svg in story.svgs.where(
          (s) => s.elements.any((e) => e.tag == 'path'),
        )) {
          expect(
            svg.width >= minimum.width && svg.height >= minimum.height,
            isTrue,
            reason:
                'Sparkline.tsx:114 emits the plot svg only at width >= 50 and '
                'height >= 16, so a captured plot smaller than that would mean '
                'the gate is wrong. ${story.id} carries '
                '${svg.width}x${svg.height}.',
          );
          seen++;
        }
      }
      expect(seen, 14, reason: 'Fourteen plots across the two stories.');
    });

    test('the topMargin shows up as the highest ink in every plot', () {
      final top = resolveFluentSparklineStyle(
        theme,
      ).topMargin!.resolve(states)!;
      var seen = 0;
      for (final story in stories) {
        for (final svg in story.svgs) {
          for (final path in svg.elements.where((e) => e.tag == 'path')) {
            expectOracleNumber(
              '${story.id} plot top',
              top,
              path.bbox!.top,
              tolerance: kOracleMeasuredTolerance,
            );
            seen++;
          }
        }
      }
      expect(
        seen,
        28,
        reason:
            'Fourteen line paths and fourteen area paths; the y range ends at '
            'margin.top (Sparkline.tsx:68), so the series maximum lands there.',
      );
    });
  });

  test('the dark theme keeps the label on its own foreground token', () {
    final dark = FluentThemeData.dark(fontPlatform: FluentFontPlatform.web);
    expect(
      resolveFluentSparklineStyle(
        dark,
      ).labelTextStyle!.resolve(states)!.color!.toARGB32(),
      dark.colors.neutralForeground1.toARGB32(),
      reason:
          'useSparklineStyles.styles.ts:25 reads a token, so the resolved '
          'colour must follow the theme rather than being frozen light.',
    );
  });
}
