// Pixel parity for Sparkline, against the live @fluentui/react-charts render.
// `charts-sparkline--sparkline-dimensions` lives in
// `sparkline_and_chart_table_parity_test.dart`; this is `sparkline-basic`.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

FluentChartData _sparkline(
  String chartTitle,
  String legend,
  FluentDataVizToken color,
  List<(Object, double)> points,
) => FluentChartData(
  chartTitle: chartTitle,
  lineChartData: <FluentLineChartSeries>[
    FluentLineChartSeries(
      legend: legend,
      // `getColorFromToken(DataVizPalette.colorN)` — the light-theme hex.
      color: FluentDataVizPalette.resolve(color),
      data: <Object>[
        for (final (x, y) in points) FluentLineChartDataPoint(x: x, y: y),
      ],
    ),
  ],
);

/// sl2..sl5 and sl7 share this series verbatim.
const List<(Object, double)> _shared = <(Object, double)>[
  (1, 29.13),
  (2, 70.98),
  (3, 60),
  (4, 89.7),
  (5, 19),
  (6, 49.44),
];

void main() {
  setUpAll(loadParityFonts);

  testWidgets('SparklineBasic', (tester) async {
    // `const sl1` .. `const sl8` in charts-sparkline--sparkline-basic.tsx.
    final sl1 = _sparkline('10.21', '19.64', FluentDataVizToken.color1, const [
      (1, 58.13),
      (2, 140.98),
      (3, 20),
      (4, 89.7),
      (5, 99),
      (6, 13.28),
      (7, 31.32),
      (8, 10.21),
    ]);
    final sl2 = _sparkline(
      '49.44',
      '19.64',
      FluentDataVizToken.color2,
      _shared,
    );
    final sl3 = _sparkline(
      '49.44',
      '19.64',
      FluentDataVizToken.color3,
      _shared,
    );
    final sl4 = _sparkline(
      '49.44',
      '464.64',
      FluentDataVizToken.color4,
      _shared,
    );
    final sl5 = _sparkline(
      '49.44',
      '46.49',
      FluentDataVizToken.color5,
      _shared,
    );
    final sl6 = _sparkline('49.44', '49.44', FluentDataVizToken.color6, [
      (DateTime.utc(2020, 3, 3), 29.13),
      (DateTime.utc(2020, 3, 4), 70.98),
      (DateTime.utc(2020, 3, 5), 60),
      (DateTime.utc(2020, 3, 7), 89.7),
      (DateTime.utc(2020, 3, 12), 19),
      (DateTime.utc(2020, 3, 15), 49.44),
    ]);
    final sl7 = _sparkline(
      '49.44',
      '49.44',
      FluentDataVizToken.color7,
      _shared,
    );
    final sl8 =
        _sparkline('541.44', '541.44', FluentDataVizToken.color8, const [
          (1, 291.13),
          (2, 170.98),
          (3, 260),
          (4, 89.7),
          (5, 664),
          (6, 66.44),
          (7, 541.44),
          (8, 32.44),
          (9, 499.14),
          (10, 350.48),
          (11, 32.44),
          (12, 400.44),
        ]);

    // The reference is a 228x359 window onto a page, not one chart: the
    // capture box is the union of all ten Sparkline roots, and the story lays
    // them out with inline prose and a `<table>`. Each root's position is
    // measured, not guessed:
    //
    //  * the table's sparkline column starts at clip x 0.078 (its six value
    //    texts sit at 88.078 = 0.078 + `dx` 8 + the 80px plot). The table's
    //    left edge, and the prose's, is therefore 0.078 - 38.078 ("Row 1" at
    //    14px) - 15 (`paddingRight`) - 2 x 2 (border-spacing) - 2 x 1 (UA td
    //    padding) = -59.0 — confirmed independently by correlating the
    //    "Below table shows…" glyphs, which peak at exactly -59.0.
    //  * sl1 follows "A sparkline " (71.852 wide) at -59 + 71.852 = 12.852;
    //    the manifest's text rect puts it at 100.859 - 88 = 12.859, the same
    //    to Chromium's 1/64 layout unit. sl2 follows "over time) in some
    //    measurement," (206.666) at 147.666.
    //  * Chromium paints an inline `<svg>` at its pixel-snapped origin — the
    //    reference's fills start crisply at columns 13, 148 and 0 and rows 0,
    //    25 and 115, 147, ... 339 — so the roots are mounted at those snapped
    //    positions. Table rows are 32 apart and the first sits at 114.5 +
    //    0.5.
    //
    // The prose between them is the story's own text, and the capture masks
    // only the chart's `<text>` boxes, so it is drawn here too — 14px/400
    // `colorNeutralForeground1`, on the baselines the reference's inline svgs
    // sit on (20, 45, and 85 after the two `<br />`s).
    const prose = TextStyle(
      fontFamily: FluentFontFamily.base,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Color(0xFF242424),
    );
    Widget text(double left, double baseline, String value) => Positioned(
      left: left,
      top: 0,
      child: Baseline(
        baseline: baseline,
        baselineType: TextBaseline.alphabetic,
        child: Text(value, style: prose, softWrap: false, maxLines: 1),
      ),
    );
    Widget at(
      double left,
      double top,
      FluentChartData data, {
      bool legend = false,
    }) => Positioned(
      left: left,
      top: top,
      child: FluentSparkline(data: data, showLegend: legend),
    );

    await expectReactParity(
      tester,
      'charts-sparkline--sparkline-basic',
      Stack(
        clipBehavior: Clip.hardEdge,
        children: <Widget>[
          text(-59, 20, 'A sparkline '),
          text(172.859, 20, ' - is a very small line chart, drawn without'),
          text(-59, 45, 'over time) in some measurement,'),
          text(-59, 85, 'Below table shows sparklines in one of its columns.'),
          // `<Sparkline data={sl1} showLegend={true} />` and
          // `<Sparkline data={sl2} />` inline in the prose.
          at(13, 0, sl1, legend: true),
          at(148, 25, sl2),
          // The table's eight rows, `showLegend` as the story sets each one.
          at(0, 115, sl1, legend: true),
          at(0, 147, sl2, legend: true),
          at(0, 179, sl3),
          at(0, 211, sl4),
          at(0, 243, sl5),
          at(0, 275, sl6, legend: true),
          at(0, 307, sl7, legend: true),
          at(0, 339, sl8, legend: true),
        ],
      ),
      // Measured 0.038% — 26 pixels of 69,084, aligned, all glyph edges of
      // the "ne" that "A sparkline " shows in columns 0-8. The corpus masks 3
      // of the story's 5 prose runs (react_png/README.md) and this one is
      // not among them, so its glyphs are compared, and Skia and Chromium
      // hint and antialias them differently. The ten sparklines match to the
      // pixel. It was 0.918% while none of the prose was masked and Skia
      // painted the stroke's fringe a column past the 80px plot, which the
      // browser's `<svg>` viewport clips; the sparkline now clips it too.
      maxMismatch: 0.04,
    );
  });
}
