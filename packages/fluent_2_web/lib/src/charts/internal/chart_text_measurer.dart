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
