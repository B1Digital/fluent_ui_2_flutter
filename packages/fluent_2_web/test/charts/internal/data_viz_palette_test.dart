import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentDataVizToken', () {
    test('carries the 47 upstream identifiers in declaration order', () {
      expect(
        FluentDataVizToken.values.length,
        47,
        reason: 'colors.ts:4-52 — 40 qualitative plus 7 semantic.',
      );
      expect(
        FluentDataVizToken.values.first,
        FluentDataVizToken.color1,
        reason: "colors.ts:5 — 'qualitative.1' is the first entry.",
      );
      expect(
        FluentDataVizToken.values[39],
        FluentDataVizToken.color40,
        reason: "colors.ts:44 — 'qualitative.40' is the fortieth.",
      );
      expect(
        FluentDataVizToken.values[40],
        FluentDataVizToken.info,
        reason: "colors.ts:45 — 'semantic.info' follows immediately.",
      );
    });
  });

  group('FluentDataVizPalette.next', () {
    test('cycles at exactly 40', () {
      expect(
        FluentDataVizPalette.qualitativeCount,
        40,
        reason: 'colors.ts:62-103 declares forty qualitative ramps.',
      );
      expect(
        FluentDataVizPalette.next(0).toARGB32(),
        FluentDataVizPalette.next(40).toARGB32(),
        reason: 'colors.ts:135 `(index + offset) % QUALITATIVE_COLORS.length`.',
      );
    });

    test('returns the light entry when isDark is not passed', () {
      expect(
        FluentDataVizPalette.next(0).toARGB32(),
        0xFF637CEF,
        reason: "colors.ts:63 — qualitative.1 is '#637cef', cornflower.tint10.",
      );
      expect(
        FluentDataVizPalette.next(10).toARGB32(),
        0xFF3C51B4,
        reason: "colors.ts:73 — qualitative.11 light is '#3c51b4'.",
      );
    });

    test('returns the dark entry when the ramp has one', () {
      expect(
        FluentDataVizPalette.next(10, isDark: true).toARGB32(),
        0xFF93A4F4,
        reason: "colors.ts:73 — qualitative.11 dark is '#93a4f4'.",
      );
    });

    test('falls back to the light entry when the ramp has only one', () {
      expect(
        FluentDataVizPalette.next(0, isDark: true).toARGB32(),
        0xFF637CEF,
        reason:
            'colors.ts:127-131 — colorIdx 1 is out of range for a one-entry '
            'ramp, so index 0 is returned.',
      );
    });

    test('applies the offset before the modulo', () {
      expect(
        FluentDataVizPalette.next(38, offset: 3).toARGB32(),
        FluentDataVizPalette.next(1).toARGB32(),
        reason: '(38 + 3) % 40 == 1 (colors.ts:135).',
      );
    });

    test(
      'hard-codes qualitative 20 light, which has no fluent_2_core twin',
      () {
        expect(
          FluentDataVizPalette.next(19).toARGB32(),
          0xFF6D5700,
          reason:
              "colors.ts:82 is '#6d5700' while fluent_2_core's gold.shade30 is "
              '0xFF6C5700 — one unit of red apart (spec 5.8).',
        );
      },
    );
  });
}
