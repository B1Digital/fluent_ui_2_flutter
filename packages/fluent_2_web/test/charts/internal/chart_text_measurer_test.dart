import 'package:fluent_2_web/src/charts/internal/chart_text_measurer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // A synthetic set with round numbers, so the four baseline formulas are
  // asserted rather than the font.
  const metrics = FluentChartTextMetrics(
    width: 40,
    height: 12,
    ascent: 10,
    descent: 2,
    xHeight: 5,
  );

  group('FluentChartTextMetrics baselines', () {
    test('alphabeticOffset is the ascent', () {
      expect(
        metrics.alphabeticOffset,
        10,
        reason:
            'SVG `dominant-baseline: auto` is the alphabetic baseline, which '
            'sits one ascent below the top of the line box.',
      );
    });

    test('centralOffset is the midpoint of the em box', () {
      expect(
        metrics.centralOffset,
        6,
        reason:
            '`central` is halfway between the text-over and text-under edges: '
            'ascent - (ascent - descent) / 2 = 10 - 4 = 6, which is also '
            'height / 2 whenever height == ascent + descent.',
      );
      expect(
        metrics.centralOffset,
        metrics.height / 2,
        reason:
            'The measurer builds its TextPainter with `height: null`, so the '
            'line box is exactly ascent + descent and the identity holds.',
      );
    });

    test('middleOffset is the midpoint of baseline and x-height', () {
      expect(
        metrics.middleOffset,
        7.5,
        reason:
            '`middle` is halfway between the alphabetic baseline and the '
            'x-height: ascent - xHeight / 2 = 10 - 2.5.',
      );
    });

    test('central and middle are NOT interchangeable', () {
      expect(
        metrics.centralOffset,
        isNot(metrics.middleOffset),
        reason:
            'Spec 8 — treating them as equal shifts every label by about half '
            'the gap between the ascent and the x-height.',
      );
    });

    test('hangingOffset is one fifth of the ascent below the top', () {
      expect(
        metrics.hangingOffset,
        closeTo(2, 1e-12),
        reason:
            'Neither Segoe UI nor Selawik carries a BASE table, so a browser '
            'places the hanging baseline at 0.8 of the ascent above the '
            'alphabetic baseline: ascent - 0.8 * ascent = 2.',
      );
    });
  });

  group('the two font ratios', () {
    test('xHeightRatio is exactly one half', () {
      expect(
        FluentChartTextMetrics.xHeightRatio,
        0.5,
        reason:
            "Selawik's OS/2 sxHeight is 1024 against unitsPerEm 2048, and "
            'Selawik is metric-compatible with the Segoe UI upstream measures '
            'against.',
      );
    });
    test('hangingBaselineRatio is 0.8', () {
      expect(
        FluentChartTextMetrics.hangingBaselineRatio,
        0.8,
        reason: 'The browser fallback when the font has no baseline table.',
      );
    });
  });
}
