import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/internal/chart_colors.dart';
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
}
