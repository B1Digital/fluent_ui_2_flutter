import 'package:fluent_2/src/charts/internal/chart_colors.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const black = Color(0xFF000000);
  const white = Color(0xFFFFFFFF);

  group('fluentColorContrast', () {
    test('is 21 for black against white', () {
      expect(
        fluentColorContrast(black, white),
        closeTo(21, 1e-9),
        reason:
            'colors.ts:165-169 — (1 + 0.05) / (0 + 0.05) is exactly 21, the '
            'WCAG maximum.',
      );
    });
    test('is symmetric', () {
      expect(
        fluentColorContrast(white, black),
        fluentColorContrast(black, white),
        reason: 'colors.ts:168 takes max and min, so order cannot matter.',
      );
    });
    test('is 1 for a colour against itself', () {
      const blue = Color(0xFF4F6BED);
      expect(
        fluentColorContrast(blue, blue),
        closeTo(1, 1e-12),
        reason: 'Equal luminances give (l + 0.05) / (l + 0.05).',
      );
    });
    test('agrees with the sRGB linearisation on a mid grey', () {
      // #808080 has channel 128/255 = 0.50196, which is above both
      // thresholds — Flutter's 0.03928 (colors.dart) and upstream's 0.04045
      // (colors.ts:150) — so both take the power branch and agree.
      const grey = Color(0xFF808080);
      expect(
        fluentColorContrast(grey, white),
        closeTo(3.9489, 1e-3),
        reason:
            'l(#808080) = 0.2158, so (1.05) / (0.2658) = 3.9489. The two '
            'thresholds only ever disagree for a channel strictly between '
            '10/255 and 10.31/255, which no 8-bit value occupies.',
      );
    });
  });

  group('fluentInvertedTextColor', () {
    test('flips foreground1 to background1 and everything else the other '
        'way', () {
      const colors = FluentColors();
      expect(
        fluentInvertedTextColor(colors.neutralForeground1, colors).toARGB32(),
        colors.neutralBackground1.toARGB32(),
        reason: 'colors.ts:172 — the equality arm.',
      );
      expect(
        fluentInvertedTextColor(const Color(0xFF4F6BED), colors).toARGB32(),
        colors.neutralForeground1.toARGB32(),
        reason: 'colors.ts:172 — the fallback arm, for any other colour.',
      );
    });
  });

  group('fluentContrastTextColor', () {
    test('keeps foreground1 when it reaches 3:1 on the background', () {
      const colors = FluentColors();
      expect(
        fluentContrastTextColor(white, colors).toARGB32(),
        colors.neutralForeground1.toARGB32(),
        reason:
            'colors.ts:176-181 — near-black foreground on white is far above '
            'the 3.0 threshold.',
      );
    });
    test('inverts when the contrast falls below 3', () {
      const colors = FluentColors();
      expect(
        fluentContrastTextColor(black, colors).toARGB32(),
        colors.neutralBackground1.toARGB32(),
        reason:
            'colors.ts:178-180 — near-black on black is below 3.0, so the '
            'inversion runs and returns background1.',
      );
    });
  });

  group('FluentChartColors.of', () {
    test('resolves the axis slots from the cartesian style sheet', () {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final chartColors = FluentChartColors.of(theme);
      expect(
        chartColors.axisText.toARGB32(),
        theme.colors.neutralForeground1.toARGB32(),
        reason:
            'useCartesianChartStyles.styles.ts:63 and :80 fill axis text with '
            'colorNeutralForeground1.',
      );
      expect(
        chartColors.axisTick.a,
        closeTo(0.2, 1e-6),
        reason:
            'useCartesianChartStyles.styles.ts:68 and :84 set opacity 0.2 on '
            'the axis line elements.',
      );
      expect(
        chartColors.gridLine.toARGB32(),
        chartColors.axisTick.toARGB32(),
        reason:
            'Upstream has one `& line` rule for both, at '
            'useCartesianChartStyles.styles.ts:67-72.',
      );
      expect(
        chartColors.axisTitle.toARGB32(),
        theme.colors.neutralForeground1.toARGB32(),
        reason:
            'Common.styles.ts:57 — the SVG `fill` wins over the `color` at :56 '
            'for a text element.',
      );
    });

    test('resolves the three surface slots to neutralBackground1', () {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final chartColors = FluentChartColors.of(theme);
      expect(
        chartColors.surface.toARGB32(),
        theme.colors.neutralBackground1.toARGB32(),
        reason: 'useCartesianChartStyles.styles.ts:107 svgTooltip fill.',
      );
      expect(
        chartColors.popoverSurface.toARGB32(),
        theme.colors.neutralBackground1.toARGB32(),
        reason: 'useChartPopoverStyles.styles.ts:36.',
      );
      expect(
        chartColors.tooltipSurface.toARGB32(),
        theme.colors.neutralBackground1.toARGB32(),
        reason: 'Common.styles.ts:44.',
      );
      expect(
        chartColors.legendDimmed.toARGB32(),
        theme.colors.neutralBackground1.toARGB32(),
        reason:
            'Legends.tsx:306 detects a dimmed legend by comparing its colour '
            'against colorNeutralBackground1.',
      );
    });

    test('reports high contrast from the palette type, not from brightness', () {
      final light = FluentChartColors.of(
        FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      );
      final dark = FluentChartColors.of(
        FluentThemeData.dark(fontPlatform: FluentFontPlatform.web),
      );
      final hc = FluentChartColors.of(
        FluentThemeData.highContrast(fontPlatform: FluentFontPlatform.web),
      );
      expect(light.isHighContrast, isFalse, reason: 'A normal light theme.');
      expect(
        dark.isHighContrast,
        isFalse,
        reason:
            'FluentHighContrastColors is itself Brightness.dark, so brightness '
            'cannot be the test — the package uses the palette type '
            '(acrylic.dart:56, rating.dart:230).',
      );
      expect(hc.isHighContrast, isTrue, reason: 'The high contrast palette.');
    });
  });

  group('FluentChartColors.flattenMark', () {
    test('is the identity outside high contrast', () {
      const seriesColour = Color(0xFF4F6BED);
      final chartColors = FluentChartColors.of(
        FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      );
      expect(
        chartColors.flattenMark(seriesColour).toARGB32(),
        0xFF4F6BED,
        reason:
            'Outside forced colours the browser leaves the fill alone, so the '
            'forty-colour palette is visible.',
      );
      expect(
        chartColors.flattenMarkStroke(seriesColour).toARGB32(),
        0xFF4F6BED,
        reason: 'Same rule for the stroke.',
      );
    });

    test('collapses every series colour under high contrast', () {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      final chartColors = FluentChartColors.of(theme);
      expect(
        chartColors.flattenMark(const Color(0xFF4F6BED)).toARGB32(),
        chartColors.flattenMark(const Color(0xFFE3008C)).toARGB32(),
        reason:
            'Spec 5.3 — upstream marks carry no forced-color-adjust, so the '
            'browser flattens every one of them to the same system colour.',
      );
      expect(
        chartColors.flattenMark(const Color(0xFF4F6BED)).toARGB32(),
        theme.colors.neutralForeground1.toARGB32(),
        reason:
            'Forced colours map an SVG `fill` to CanvasText, which is '
            'neutralForeground1 in the package high contrast palette.',
      );
      expect(
        chartColors.flattenMarkStroke(const Color(0xFF4F6BED)).toARGB32(),
        theme.colors.neutralBackground1.toARGB32(),
        reason:
            'Canvas-coloured hairlines keep adjacent flattened marks '
            'distinguishable. Forced colours would map the stroke to CanvasText '
            'too, merging every bar into one blob; that is an accessibility '
            'defect and spec 5.2 exempts those from bug fidelity.',
      );
    });
  });
}
