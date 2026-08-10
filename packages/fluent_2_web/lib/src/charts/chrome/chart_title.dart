import '../internal/chart_text_measurer.dart';

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
