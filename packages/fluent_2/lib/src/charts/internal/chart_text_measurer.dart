import 'package:flutter/widgets.dart';

/// One measured line of chart text.
///
/// The three baseline offsets exist because SVG's `dominant-baseline` is used at
/// nine sites with four values — `auto`, `central`, `middle` and `hanging` — and
/// `TextPainter` exposes only the alphabetic and ideographic baselines (spec §8).
///
/// Every offset is **the distance below the top of the painted line box at which
/// that baseline sits**, so a caller that wants a given baseline on `y` paints
/// its origin at `y - offset`.
@immutable
class FluentChartTextMetrics {
  /// Creates a measured line.
  const FluentChartTextMetrics({
    required this.width,
    required this.height,
    required this.ascent,
    required this.descent,
    required this.xHeight,
  });

  /// The x-height of the Fluent web font family, as a fraction of the font size.
  ///
  /// Selawik's OS/2 `sxHeight` is 1024 against a `unitsPerEm` of 2048 — exactly
  /// half an em — and Selawik is metric-compatible with Segoe UI, which upstream
  /// measures against. Flutter exposes no font-table access, so this is a named
  /// constant rather than a read; change it if the package ever ships a family
  /// with a different x-height.
  static const double xHeightRatio = 0.5;

  /// Where the SVG hanging baseline sits, as a fraction of the ascent above the
  /// alphabetic baseline.
  ///
  /// Neither Segoe UI nor Selawik carries an OpenType `BASE` table, so a browser
  /// falls back to four fifths of the ascent. 0.8 is that fallback.
  static const double hangingBaselineRatio = 0.8;

  /// The line's advance width in logical pixels.
  final double width;

  /// The line box's height in logical pixels.
  final double height;

  /// The distance from the top of the line box to the alphabetic baseline.
  final double ascent;

  /// The distance from the alphabetic baseline to the bottom of the line box.
  final double descent;

  /// The x-height in logical pixels.
  final double xHeight;

  /// `dominant-baseline: auto` — the alphabetic baseline.
  double get alphabeticOffset => ascent;

  /// `dominant-baseline: central` — the midpoint of the em box.
  ///
  /// `ascent - (ascent - descent) / 2`, which is `height / 2` whenever the line
  /// box is exactly `ascent + descent` — which it is, because the measurer
  /// builds its painter with `height: null`.
  double get centralOffset => ascent - (ascent - descent) / 2;

  /// `dominant-baseline: middle` — the midpoint between the alphabetic baseline
  /// and the x-height.
  ///
  /// Not interchangeable with [centralOffset]: at 10px Selawik the two differ by
  /// about 1.4 logical pixels, and treating them as equal shifts every affected
  /// label (spec §8).
  double get middleOffset => ascent - xHeight / 2;

  /// `dominant-baseline: hanging` — [hangingBaselineRatio] of the ascent above
  /// the alphabetic baseline.
  double get hangingOffset => ascent - hangingBaselineRatio * ascent;
}

/// The one text measurer in the charts subsystem.
///
/// Upstream has three — `measureTextWithDOM` (`utilities.ts:2146-2168`),
/// `getTextSize` (`:2173-2202`) and the canvas-based
/// `calculateLongestLabelWidth` (`:1253-1276`) — and the recon proposed three
/// Dart ports of them. There is one here, because margins, tick-count
/// reduction, wrap/rotate/stagger, truncation and image export all feed from it
/// and three implementations means three pixel results (spec §10, risk 3).
///
/// One instance lives per chart subtree, created by the chart and invalidated
/// on a theme change.
///
/// **Capitalisation.** Upstream is inconsistent and the port matches it:
/// `measureTextWithDOM` copies `text-transform` (`utilities.ts:2137-2144`) and
/// is what the exported legend strip measures with
/// (`image-export-utils.ts:314`), while `calculateLongestLabelWidth` does not.
/// So a legend label is measured **after** `capitalizeLegendLabel` and an axis
/// label is measured **before**. This class does not capitalise anything; the
/// caller decides.
class FluentChartTextMeasurer {
  /// Creates an empty measurer.
  FluentChartTextMeasurer();

  /// The number of entries kept before the oldest is evicted.
  ///
  /// `CACHE_SIZE` (`utilities.ts:2170`).
  static const int cacheSize = 2000;

  /// Insertion-ordered, which is what makes the eviction below first-in
  /// first-out — matching `utilities.ts:2188-2192`, which deletes
  /// `textSizeCache.keys().next().value`. A Dart `Map` literal is a
  /// `LinkedHashMap`, so the order is guaranteed.
  ///
  /// The key is a record of the text and the resolved style. Records have
  /// structural equality and [TextStyle] has value equality, so this is a real
  /// composite key — deliberately unlike upstream's `${text}|${cssSelector}`
  /// (`utilities.ts:2178`), which is blind to the font. A Flutter theme swap is
  /// far more common than a CSS font swap, so that bug is fixed rather than
  /// reproduced.
  final Map<(String, TextStyle), FluentChartTextMetrics> _cache =
      <(String, TextStyle), FluentChartTextMetrics>{};

  /// How many measurements are currently cached. For tests and diagnostics.
  int get cachedCount => _cache.length;

  /// A laid-out [TextPainter] for [text] in [style], configured the one way
  /// this subsystem configures them.
  ///
  /// [measure] reads its metrics from exactly this painter, so a chart painter
  /// that needs to *draw* the string must build it the same way or it will
  /// paint at a width the margin solver never reserved. Before this existed the
  /// axis painter carried a second, identical construction kept in step by a
  /// comment — and `chrome/` is about to add four more painters, each of which
  /// would have copied it. One factory, one configuration.
  ///
  /// The caller owns the result and must call [TextPainter.dispose].
  ///
  /// The rationale for each argument is on [measure]; in short, the line box is
  /// the font's own ascent and descent because SVG `<text>` has none, and
  /// geometry is computed unscaled and left-to-right, then mirrored.
  TextPainter layoutPainter(String text, TextStyle style) => TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textScaler: TextScaler.noScaling,
    textDirection: TextDirection.ltr,
    textHeightBehavior: const TextHeightBehavior(
      applyHeightToFirstAscent: false,
      applyHeightToLastDescent: false,
    ),
  )..layout();

  /// Measures [text] in [style].
  ///
  /// The line box is the font's own ascent and descent rather than the type
  /// token's leading, because SVG `<text>` has no line box and every upstream
  /// vertical offset is measured from the glyphs. [TextStyle.copyWith] cannot
  /// express that — it resolves `height` as `height ?? this.height`, so passing
  /// null keeps the token's multiplier — so the leading is dropped with
  /// [TextHeightBehavior] instead: with `maxLines: 1` the only line is both the
  /// first and the last, so refusing the multiplier on the first ascent and the
  /// last descent leaves the raw font metrics.
  ///
  /// [TextScaler.noScaling] and [TextDirection.ltr], because chart geometry is
  /// computed in an unscaled left-to-right space and mirrored afterwards.
  FluentChartTextMetrics measure(String text, TextStyle style) {
    final key = (text, style);
    final cached = _cache[key];
    if (cached != null) {
      return cached;
    }

    final painter = layoutPainter(text, style);
    final ascent = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final metrics = FluentChartTextMetrics(
      width: painter.width,
      height: painter.height,
      ascent: ascent,
      descent: painter.height - ascent,
      // fontSize is null only when the caller passes a style with no size at
      // all; 10 is the axis-tick size (`utilities.ts:1267`, the canvas fallback
      // font '600 10px "Segoe UI"'), which is the only slot that could
      // plausibly reach here unset.
      xHeight: (style.fontSize ?? 10) * FluentChartTextMetrics.xHeightRatio,
    );
    painter.dispose();

    if (_cache.length >= cacheSize) {
      // utilities.ts:2188-2192. Upstream guards the evicted key with
      // `isInvalidValue`, which can never be true for a string key; the guard
      // is not ported.
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = metrics;
    return metrics;
  }

  /// The advance width of [text] in [style].
  double width(String text, TextStyle style) => measure(text, style).width;

  /// The widest of [labels] in [style], or 0 when there are none.
  ///
  /// Ports `calculateLongestLabelWidth` (`utilities.ts:1253-1276`). Callers
  /// ceil the result themselves, exactly as `CartesianChart.tsx:158` and `:579`
  /// do.
  double longestWidth(Iterable<String> labels, TextStyle style) {
    var longest = 0.0;
    for (final label in labels) {
      final measured = width(label, style);
      if (measured > longest) {
        longest = measured;
      }
    }
    return longest;
  }

  /// Drops every cached measurement.
  ///
  /// Called when the theme changes, because every metric was taken against the
  /// old type ramp.
  void invalidate() => _cache.clear();
}
