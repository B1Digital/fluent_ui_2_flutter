import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
import 'package:flutter/widgets.dart';
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

  group('FluentDataVizPalette.resolve', () {
    test('hard-codes semantic.info, which has no fluent_2_core token', () {
      expect(
        FluentDataVizPalette.resolve(FluentDataVizToken.info).toARGB32(),
        0xFF015CDA,
        reason:
            "colors.ts:106 is '#015cda' and no fluent_2_core alias or shared "
            'ramp carries it (spec 5.8).',
      );
    });
    test(
      'semantic.info has no dark variant, so dark returns the same value',
      () {
        expect(
          FluentDataVizPalette.resolve(
            FluentDataVizToken.info,
            isDark: true,
          ).toARGB32(),
          0xFF015CDA,
          reason: 'colors.ts:106 declares a one-entry ramp.',
        );
      },
    );
    test('resolves the six two-entry semantic ramps both ways', () {
      expect(
        FluentDataVizPalette.resolve(FluentDataVizToken.error).toARGB32(),
        0xFFC50F1F,
        reason: 'colors.ts:109 light — cranberry.primary.',
      );
      expect(
        FluentDataVizPalette.resolve(
          FluentDataVizToken.error,
          isDark: true,
        ).toARGB32(),
        0xFFDC626D,
        reason: 'colors.ts:109 dark — cranberry.tint30.',
      );
      expect(
        FluentDataVizPalette.resolve(FluentDataVizToken.disabled).toARGB32(),
        0xFFDBDBDB,
        reason: 'colors.ts:107 light — grey 86.',
      );
      expect(
        FluentDataVizPalette.resolve(
          FluentDataVizToken.highSuccess,
          isDark: true,
        ).toARGB32(),
        0xFF218C21,
        reason: 'colors.ts:112 dark — green.tint10.',
      );
    });
    test('resolves a qualitative token to the same value as next', () {
      expect(
        FluentDataVizPalette.resolve(FluentDataVizToken.color7).toARGB32(),
        FluentDataVizPalette.next(6).toARGB32(),
        reason: "'qualitative.7' is the seventh ramp, index 6.",
      );
    });
  });

  group('fluentChartIsDarkTheme', () {
    test('compares HSL lightness, not Brightness', () {
      expect(
        fluentChartIsDarkTheme(const FluentColors()),
        isFalse,
        reason:
            'DeclarativeChart.tsx:348 — background lightness is above '
            'foreground lightness in the light theme.',
      );
      expect(
        fluentChartIsDarkTheme(const FluentColors(brightness: Brightness.dark)),
        isTrue,
        reason: 'DeclarativeChart.tsx:348, the other way round.',
      );
    });
    test('reports the high-contrast palette as dark', () {
      expect(
        fluentChartIsDarkTheme(const FluentHighContrastColors()),
        isTrue,
        reason:
            'Canvas is black and CanvasText is white in the package high '
            'contrast palette, so the lightness comparison holds.',
      );
    });
  });
}
