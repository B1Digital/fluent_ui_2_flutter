import 'package:flutter/widgets.dart';

import '../internal/chart_text_measurer.dart';
import '../internal/d3/axis_geometry.dart';

/// The four SVG `dominant-baseline` values chart chrome actually uses.
///
/// Nine painted text sites across the port choose between them;
/// `ChartTitle.tsx:67-74` is the one that names all four in a single
/// expression. The other eight are `Pie.tsx:107`, `Arc.tsx:88`,
/// `HeatMapChart.tsx:236`, `PolarChart.tsx:377` and `:404`,
/// `HorizontalBarChart.tsx:296`, `HorizontalBarChartWithAxis.tsx:804` and
/// `GaugeChart.tsx:692`. `TextPainter` exposes `alphabetic` and `ideographic`
/// only, so the other three are computed from font metrics by
/// [fluentChartBaselineOffset].
enum FluentChartTitleBaseline {
  /// Text hangs below the given y. `ChartTitle.tsx:68-69`,
  /// `titleYAnchor: 'top'`.
  hanging,

  /// The em box's midpoint sits on the given y. `ChartTitle.tsx:72-73`,
  /// `titleYAnchor: 'middle'`.
  central,

  /// The midpoint between the alphabetic baseline and the x-height sits on the
  /// given y. Not selected by `ChartTitle` but used by the donut's inside
  /// string (`Pie.tsx:107`), the heat map's cell labels
  /// (`HeatMapChart.tsx:236`) and the polar chart's spoke labels
  /// (`PolarChart.tsx:377`, `:404`).
  middle,

  /// The alphabetic baseline sits on the given y. `ChartTitle.tsx:70-71` for
  /// `titleYAnchor: 'bottom'`, and `:74`'s `'auto'` fallback resolves here too,
  /// because `auto` means `alphabetic` for horizontal Latin text.
  alphabetic,
}

/// How far below `y` the alphabetic baseline sits for [baseline].
///
/// The one place all four `dominant-baseline` values are resolved. Add the
/// result to the requested `y` and hand it to `TextPainter.paint` as the
/// baseline, or subtract [FluentChartTextMetrics.ascent] from the sum to get a
/// top-left paint origin.
///
/// * `alphabetic` — zero. `TextPainter` already draws there.
/// * `central` — `(ascent − descent) / 2`, the em-box midpoint.
/// * `middle` — `xHeight / 2`, the midpoint of baseline and x-height.
/// * `hanging` — the browsers' `0.8 × ascent` fallback, which is what applies
///   because neither Segoe UI nor Selawik carries an OpenType `BASE` table.
///
/// `central` and `middle` are **not** interchangeable: they differ by
/// `(ascent − descent − xHeight) / 2`, about 1.4 logical pixels at 10px Segoe
/// UI and 4.5 at the donut's 28px inside string, which the Oracle B capture of
/// `charts-donutchart--donut-chart-basic` shows outright.
///
/// The three non-trivial offsets are computed by [FluentChartTextMetrics],
/// their contracted owner (contract §4.3), so this only turns them round: each
/// of those is measured **down from the top of the line box**, whereas a
/// painter needs the distance **down from the requested y**, and the two are
/// separated by exactly one ascent. Nothing here re-derives a formula.
double fluentChartBaselineOffset(
  FluentChartTitleBaseline baseline,
  FluentChartTextMetrics metrics,
) =>
    metrics.ascent -
    switch (baseline) {
      FluentChartTitleBaseline.hanging => metrics.hangingOffset,
      FluentChartTitleBaseline.central => metrics.centralOffset,
      FluentChartTitleBaseline.middle => metrics.middleOffset,
      FluentChartTitleBaseline.alphabetic => metrics.alphabeticOffset,
    };

/// The `PADDING` constant inside `SVGTooltipText`. `SVGTooltipText.tsx:43`.
const double kChartTitleBackgroundPadding = 3;

/// The rect painted behind a chart title when `showBackground` is set.
///
/// `SVGTooltipText.tsx:169-179`:
///
/// ```text
/// x = anchor.dx - width / 2  - PADDING
/// y = anchor.dy - height / 2 - 2 * PADDING
/// w = width  + 2 * PADDING
/// h = height +     PADDING
/// ```
///
/// [textSize] is the text's own `getBBox()` — its ascent-plus-descent box, per
/// `SVGTooltipText.tsx:58-63` — which is what [FluentChartTextMetrics] measures.
///
/// Asymmetric on purpose, and reproduced rather than corrected: the rect is
/// lifted by six but grows by only three, so it sits high of the text's centre,
/// and the horizontal centring assumes a middle anchor regardless of the
/// actual one. Both are visible in every chart title that carries a backdrop —
/// the Oracle B capture of `charts-gaugechart--gauge-chart-single-segment`
/// pins them, its 75.21875 × 14 title box backed by an 81.21875 × 17 rect that
/// starts six pixels above the box and ends three below its baseline.
Rect fluentChartTitleBackgroundRect(Offset anchor, Size textSize) =>
    Rect.fromLTWH(
      anchor.dx - textSize.width / 2 - kChartTitleBackgroundPadding,
      anchor.dy - textSize.height / 2 - 2 * kChartTitleBackgroundPadding,
      textSize.width + 2 * kChartTitleBackgroundPadding,
      textSize.height + kChartTitleBackgroundPadding,
    );

/// Paints a chart title, and optionally the rect behind it.
///
/// The `SVGTooltipText` equivalent (`SVGTooltipText.tsx`) reduced to its
/// painting half: the truncation loop is `shrinkToFit` in
/// `axis/axis_label_layout.dart` (its contracted owner) and the tooltip is the
/// axis label tooltip widget, because neither belongs in a painter.
///
/// [rotationRadians] carries the y-axis title's `rotate(-90, cx, cy)`
/// (`CartesianChart.tsx:879`, `:895`); the rotation is about [anchor], which is
/// the `(cx, cy)` of that transform.
class FluentChartTitlePainter extends CustomPainter {
  /// Creates a title painter.
  const FluentChartTitlePainter({
    required this.text,
    required this.style,
    required this.anchor,
    required this.textAnchor,
    required this.baseline,
    required this.rotationRadians,
    required this.showBackground,
    required this.backgroundColor,
    required this.measurer,
  });

  /// The title, already truncated by `shrinkToFit` if it had to be.
  final String text;

  /// Resolved text style. `FluentChartTextStyles.chartTitle` by default, which
  /// is `caption2Strong` per `Common.styles.ts:85`.
  final TextStyle style;

  /// The `(x, y)` the title is positioned against, and the centre of
  /// [rotationRadians].
  final Offset anchor;

  /// Horizontal alignment, from `titleXAnchor` (`ChartTitle.tsx:61`).
  final FluentAxisTextAnchor textAnchor;

  /// Vertical alignment, from `titleYAnchor` (`ChartTitle.tsx:67-74`).
  final FluentChartTitleBaseline baseline;

  /// Clockwise rotation about [anchor], in radians.
  final double rotationRadians;

  /// Whether the backing rect is painted. `ChartTitle.tsx:91` always passes
  /// true; axis titles do not.
  final bool showBackground;

  /// Backing rect fill — `colorNeutralBackground1`, or `Canvas` in high
  /// contrast (`useCartesianChartStyles.styles.ts:105-110`).
  final Color backgroundColor;

  /// The chart's shared measurer, so the title's metrics come from the same
  /// cache as everything else.
  final FluentChartTextMeasurer measurer;

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty) {
      return;
    }
    final metrics = measurer.measure(text, style);
    // The one configuration: `measure` read the numbers above off exactly this
    // painter, so drawing through the same factory cannot drift from them.
    final painter = measurer.layoutPainter(text, style);

    // ChartTitle.tsx:61 — start, middle or end.
    final dx = switch (textAnchor) {
      FluentAxisTextAnchor.start => 0.0,
      FluentAxisTextAnchor.middle => -metrics.width / 2,
      FluentAxisTextAnchor.end => -metrics.width,
    };
    // The baseline offset positions the ALPHABETIC baseline; TextPainter paints
    // from the top-left, so the ascent comes back off.
    final dy = fluentChartBaselineOffset(baseline, metrics) - metrics.ascent;

    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.rotate(rotationRadians);

    if (showBackground) {
      // The rect is computed in unrotated title space around the origin,
      // because SVGTooltipText.tsx:180 inherits the text's own transform.
      canvas.drawRect(
        fluentChartTitleBackgroundRect(
          Offset.zero,
          Size(metrics.width, metrics.height),
        ),
        Paint()..color = backgroundColor,
      );
    }
    painter.paint(canvas, Offset(dx, dy));
    canvas.restore();
    painter.dispose();
  }

  @override
  bool shouldRepaint(FluentChartTitlePainter oldDelegate) =>
      oldDelegate.text != text ||
      oldDelegate.style != style ||
      oldDelegate.anchor != anchor ||
      oldDelegate.textAnchor != textAnchor ||
      oldDelegate.baseline != baseline ||
      oldDelegate.rotationRadians != rotationRadians ||
      oldDelegate.showBackground != showBackground ||
      oldDelegate.backgroundColor != backgroundColor;
}
