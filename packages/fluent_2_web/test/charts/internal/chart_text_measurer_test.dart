import 'package:fluent_2_web/src/charts/internal/chart_text_measurer.dart';
import 'package:flutter/widgets.dart';
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

  group('FluentChartTextMeasurer', () {
    // The axis tick slot: caption2Strong on the web ramp is 10/14/semibold
    // (typography.dart web ramp, `s(10, 14, sb)`), matching the canvas fallback
    // font '600 10px "Segoe UI"' at utilities.ts:1267.
    const style = TextStyle(
      fontSize: 10,
      height: 1.4,
      fontWeight: FontWeight.w600,
      fontFamily: 'Selawik',
    );

    test('drops the style height, so the box is ascent plus descent', () {
      final measurer = FluentChartTextMeasurer();
      final metrics = measurer.measure('Jan', style);
      expect(
        metrics.height,
        closeTo(metrics.ascent + metrics.descent, 1e-9),
        reason:
            'The painter is built with `height: null`, so the line box is the '
            "font's own ascent plus descent and not the token's 1.4 leading.",
      );
      expect(
        metrics.height,
        lessThan(14),
        reason:
            'A 1.4 line height at 10px would be 14; Selawik measures 12.0 from '
            'its hhea ascent 2027 and descent 431 over unitsPerEm 2048.',
      );
    });

    test('derives xHeight from the font size and the ratio', () {
      final measurer = FluentChartTextMeasurer();
      expect(
        measurer.measure('Jan', style).xHeight,
        closeTo(5, 1e-9),
        reason: '10 * FluentChartTextMetrics.xHeightRatio.',
      );
    });

    test('measures a wider string as wider', () {
      final measurer = FluentChartTextMeasurer();
      expect(
        measurer.width('September', style),
        greaterThan(measurer.width('May', style)),
        reason: 'A longer label advances further.',
      );
    });

    test('longestWidth is 0 for an empty list', () {
      final measurer = FluentChartTextMeasurer();
      expect(
        measurer.longestWidth(const <String>[], style),
        0,
        reason:
            'calculateLongestLabelWidth (utilities.ts:1253-1276) starts at 0 '
            'and never enters its loop.',
      );
    });

    test('longestWidth returns the maximum, not the last', () {
      final measurer = FluentChartTextMeasurer();
      expect(
        measurer.longestWidth(const <String>['May', 'September', 'Jun'], style),
        closeTo(measurer.width('September', style), 1e-9),
        reason: 'utilities.ts:1271 takes Math.max on every iteration.',
      );
    });

    test('caches on the text AND the resolved style', () {
      final measurer = FluentChartTextMeasurer();
      measurer.measure('Jan', style);
      expect(measurer.cachedCount, 1, reason: 'One entry so far.');
      measurer.measure('Jan', style);
      expect(measurer.cachedCount, 1, reason: 'The same key does not grow it.');
      measurer.measure('Jan', style.copyWith(fontSize: 12));
      expect(
        measurer.cachedCount,
        2,
        reason:
            'The key includes the resolved style, deliberately fixing '
            "utilities.ts:2178's `\${text}|\${cssSelector}` key — a Flutter "
            'theme swap is far more common than a CSS font swap.',
      );
    });

    test('a different style really returns a different width', () {
      final measurer = FluentChartTextMeasurer();
      expect(
        measurer.width('January', style.copyWith(fontSize: 20)),
        greaterThan(measurer.width('January', style)),
        reason:
            'If the cache key ignored the style, the second call would return '
            'the first size.',
      );
    });

    test('invalidate empties the cache', () {
      final measurer = FluentChartTextMeasurer();
      measurer.measure('Jan', style);
      measurer.invalidate();
      expect(
        measurer.cachedCount,
        0,
        reason: 'Called on a theme change, when every metric is stale.',
      );
    });

    test('evicts the oldest entry at the cache ceiling', () {
      final measurer = FluentChartTextMeasurer();
      expect(
        FluentChartTextMeasurer.cacheSize,
        2000,
        reason: 'CACHE_SIZE (utilities.ts:2170).',
      );
      for (var i = 0; i <= FluentChartTextMeasurer.cacheSize; i++) {
        measurer.measure('$i', style);
      }
      expect(
        measurer.cachedCount,
        FluentChartTextMeasurer.cacheSize,
        reason:
            'utilities.ts:2188-2192 deletes the first key once the map reaches '
            'CACHE_SIZE, which is first-in first-out and not '
            'least-recently-used.',
      );
    });
  });
}
