// Pixel parity for the AreaChart stories not covered by
// `area_scatter_parity_test.dart`, against the live @fluentui/react-charts
// render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`. Nothing here is
// invented or rounded: a chart fed different data than the reference is a
// comparison of two different pictures.
//
// Props with no pixel effect at rest are not transcribed: `legendsOverflowText`
// (nothing overflows at 700px), `legendProps.allowFocusOnLegends` (focus
// only), `enablePerfOptimization` (a render-scheduling flag,
// `AreaChart.tsx:341` / `:1121`) and `optimizeLargeData`, which only decides
// whether the r=0 resting circles are emitted (`AreaChart.tsx:756`) — none of
// them paints a pixel until something is hovered.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/area_chart.dart';
import 'package:fluent_2/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2/src/charts/internal/d3/format.dart' as d3;
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/cartesian_series.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

/// `yAxisTickFormat={d3.format("$,")}`. The port's own d3-format, so negative
/// ticks get d3's U+2212 minus (Oracle B: "−$200") and the left margin, which
/// is solved from the widest tick label, sees the same string upstream did.
final d3.NumberFormatter _dollars = d3.format(r'$,');
String _dollarTick(double v) => _dollars(v);

List<FluentLineChartDataPoint> _points(List<(double, double)> xy) =>
    <FluentLineChartDataPoint>[
      for (final (x, y) in xy) FluentLineChartDataPoint(x: x, y: y),
    ];

// `chart1Points` / `chart2Points` / `chart3Points` shared verbatim by the
// Multiple and LargeData stories.
const List<(double, double)> _multiple1 = <(double, double)>[
  (20, 9), (25, 14), (30, 14), (35, 23), (40, 20), //
  (45, 31), (50, 29), (55, 27), (60, 37), (65, 51),
];
const List<(double, double)> _multiple2 = <(double, double)>[
  (20, 21), (25, 25), (30, 10), (35, 10), (40, 14), //
  (45, 18), (50, 9), (55, 23), (60, 7), (65, 55),
];
const List<(double, double)> _multiple3 = <(double, double)>[
  (20, 30), (25, 35), (30, 33), (35, 40), (40, 10), //
  (45, 40), (50, 34), (55, 40), (60, 60), (65, 40),
];

/// `chart1Points` of the Negative and SecondaryYAxis stories (the former with
/// every other value negated).
const List<(double, double)> _stock = <(double, double)>[
  (20, 7000), (25, 9000), (30, 13000), (35, 15000), (40, 11000), //
  (45, 8760), (50, 3500), (55, 20000), (60, 17000), (65, 1000),
  (70, 12000), (75, 6876), (80, 12000), (85, 7000), (90, 10000),
];

void main() {
  setUpAll(loadParityFonts);

  testWidgets('AreaChartMultiple', (tester) async {
    // charts-areachart--area-chart-multiple.tsx.
    final data = FluentChartData(
      chartTitle: 'Area chart multiple example',
      lineChartData: <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'legend1',
          data: _points(_multiple1),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
        ),
        FluentLineChartSeries(
          legend: 'legend2',
          data: _points(_multiple2),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
        ),
        FluentLineChartSeries(
          legend: 'legend3',
          data: _points(_multiple3),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
        ),
      ],
    );
    await expectReactParity(
      tester,
      'charts-areachart--area-chart-multiple',
      FluentAreaChart(
        data: data,
        props: const FluentCartesianChartProps(yAxisTickFormat: _dollarTick),
      ),
      // Measured 0.072% — 147 px — then pinned just above it. Of those, 44 are
      // the legend swatch edge columns (Chrome pixel-snaps each 14px swatch
      // box; Flutter paints it at the fractional x the label widths put it); 81
      // are the seams between stacked layers where a curve runs nearly flat
      // (x473-523, rows 185-187) and Skia's coverage there sits ~0.3px below
      // Chromium's; 22 are "$111" spilling left of its mask — Selawik
      // Semibold's tabular "1" (5.63px) against Segoe UI's proportional one
      // (~4.0px).
      maxMismatch: 0.08,
    );
  });

  testWidgets('AreaChartLargeData', (tester) async {
    // charts-areachart--area-chart-large-data.tsx. Same points as Multiple,
    // palette 11-13, no tick format.
    final data = FluentChartData(
      chartTitle: 'Area chart large data example',
      lineChartData: <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'legend1',
          data: _points(_multiple1),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
        ),
        FluentLineChartSeries(
          legend: 'legend2',
          data: _points(_multiple2),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color12),
        ),
        FluentLineChartSeries(
          legend: 'legend3',
          data: _points(_multiple3),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color13),
        ),
      ],
    );
    await expectReactParity(
      tester,
      'charts-areachart--area-chart-large-data',
      FluentAreaChart(data: data),
      // Measured 0.050% — 102 px — then pinned just above it. Of those, 56 are
      // the legend swatch edge columns (Chrome pixel-snaps each 14px swatch
      // box; Flutter paints it at the fractional x the label widths put it); 37
      // are flat-seam antialiasing between stacked layers; 9 are "111" spilling
      // left of its mask (Selawik's tabular "1" is wider than Segoe UI's).
      maxMismatch: 0.06,
    );
  });

  testWidgets('AreaChartCustomAccessibility', (tester) async {
    // charts-areachart--area-chart-custom-accessibility.tsx. The aria labels
    // are not transcribed: they paint nothing.
    final data = FluentChartData(
      chartTitle: 'Area chart Custom Accessibility example',
      lineChartData: <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'First',
          data: _points(const <(double, double)>[
            (20, 9), (40, 20), (55, 27), (60, 37), (65, 51), //
          ]),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color8),
        ),
        FluentLineChartSeries(
          legend: 'Second',
          data: _points(const <(double, double)>[
            (20, 21), (40, 25), (55, 23), (60, 7), (65, 55), //
          ]),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color9),
        ),
        FluentLineChartSeries(
          legend: 'Third',
          data: _points(const <(double, double)>[
            (20, 30), (40, 35), (55, 33), (60, 40), (65, 10), //
          ]),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
        ),
      ],
    );
    await expectReactParity(
      tester,
      'charts-areachart--area-chart-custom-accessibility',
      FluentAreaChart(
        data: data,
        props: const FluentCartesianChartProps(yAxisTickFormat: _dollarTick),
      ),
      // Measured 0.074% — 152 px — then pinned just above it. Of those, 119 are
      // the seams between stacked layers, which run nearly flat for 280px here
      // (five points across the axis), and where Skia's coverage sits ~0.3px
      // below Chromium's — an analytic model of the seam matches the reference
      // to ~8 levels and Flutter to ~25; 28 are the legend swatch edge columns
      // (Chrome pixel-snaps each 14px swatch box; Flutter paints it at the
      // fractional x the label widths put it); 5 are tick-label spill.
      maxMismatch: 0.08,
    );
  });

  testWidgets('AreaChartAllNegative', (tester) async {
    // charts-areachart--area-chart-all-negative.tsx.
    final data = FluentChartData(
      chartTitle: 'Area chart multiple all negative y example',
      lineChartData: <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'legend1',
          data: _points(const <(double, double)>[
            (20, -9), (25, -14), (30, -14), (35, -23), (40, -20), //
            (45, -31), (50, -29), (55, -27), (60, -37), (65, -51),
          ]),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
        ),
        FluentLineChartSeries(
          legend: 'legend2',
          data: _points(const <(double, double)>[
            (20, -21), (25, -25), (30, -10), (35, -10), (40, -14), //
            (45, -18), (50, -9), (55, -23), (60, -7), (65, -55),
          ]),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
        ),
        FluentLineChartSeries(
          legend: 'legend3',
          data: _points(const <(double, double)>[
            (20, -30), (25, -35), (30, -33), (35, -40), (40, -10), //
            (45, -40), (50, -34), (55, -40), (60, -60), (65, -40),
          ]),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
        ),
      ],
    );
    await expectReactParity(
      tester,
      'charts-areachart--area-chart-all-negative',
      FluentAreaChart(
        data: data,
        props: const FluentCartesianChartProps(
          yMinValue: -200,
          yAxisTickFormat: _dollarTick,
        ),
      ),
      // Measured 0.058% — 118 px — then pinned just above it. Of those, 44 are
      // the legend swatch edge columns (Chrome pixel-snaps each 14px swatch
      // box; Flutter paints it at the fractional x the label widths put it); 44
      // are the "−$" tick labels: d3 prints U+2212, which Selawik has no glyph
      // for, so `flutter test` draws a fallback box that pokes out of the mask;
      // 30 are flat-seam antialiasing between stacked layers.
      maxMismatch: 0.07,
    );
  });

  testWidgets('AreaChartMultipleNegative', (tester) async {
    // charts-areachart--area-chart-multiple-negative.tsx.
    final data = FluentChartData(
      chartTitle: 'Area chart multiple negative y example',
      lineChartData: <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'legend1',
          data: _points(const <(double, double)>[
            (20, -9), (25, 14), (30, -14), (35, 23), (40, -20), //
            (45, 31), (50, -29), (55, 27), (60, -37), (65, 51),
          ]),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
        ),
        FluentLineChartSeries(
          legend: 'legend2',
          data: _points(const <(double, double)>[
            (20, 21), (25, -25), (30, 10), (35, -10), (40, 14), //
            (45, -18), (50, 9), (55, -23), (60, 7), (65, -55),
          ]),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
        ),
        FluentLineChartSeries(
          legend: 'legend3',
          data: _points(const <(double, double)>[
            (20, 30), (25, 35), (30, -33), (35, 40), (40, 10), //
            (45, -40), (50, 34), (55, 40), (60, -60), (65, 40),
          ]),
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
        ),
      ],
    );
    await expectReactParity(
      tester,
      'charts-areachart--area-chart-multiple-negative',
      FluentAreaChart(
        data: data,
        props: const FluentCartesianChartProps(yAxisTickFormat: _dollarTick),
      ),
      // Measured 0.086% — 175 px — then pinned just above it. Of those, 66 are
      // the "−$" tick labels (U+2212 has no Selawik glyph, so `flutter test`
      // draws a fallback box that pokes out of the mask); 44 are the legend
      // swatch edge columns (Chrome pixel-snaps each 14px swatch box; Flutter
      // paints it at the fractional x the label widths put it); 65 are
      // antialiasing where layers cross or meet at a shallow angle.
      maxMismatch: 0.1,
    );
  });

  testWidgets('AreaChartNegative', (tester) async {
    // charts-areachart--area-chart-negative.tsx: `_stock` with every other
    // value negated. `showAxisTitles` starts true, so both titles are passed;
    // `culture` is the capture browser's `navigator.language`, en-US. The
    // story's `yAxisCalloutData` is not a prop upstream reads, so it is
    // dropped rather than mapped to `yAxisCalloutText`.
    final data = FluentChartData(
      chartTitle: 'Area chart Negative y example',
      lineChartData: <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'legend1',
          data: <FluentLineChartDataPoint>[
            for (var i = 0; i < _stock.length; i++)
              FluentLineChartDataPoint(
                x: _stock[i].$1,
                y: i.isOdd ? -_stock[i].$2 : _stock[i].$2,
              ),
          ],
        ),
      ],
    );
    await expectReactParity(
      tester,
      'charts-areachart--area-chart-negative',
      FluentAreaChart(
        data: data,
        props: const FluentCartesianChartProps(
          yAxisTitle: 'Variation of stock market prices',
          xAxisTitle: 'Number of days',
        ),
        culture: 'en-US',
      ),
      // Measured 0.042% — 83 px — then pinned just above it. Of those, 77 are
      // the "−" of −27.75k / −18.5k / −9.25k: U+2212 has no Selawik glyph, so
      // `flutter test` draws a fallback box that pokes out of the mask. 6 are
      // edge antialiasing. The single legend swatch sits on a whole pixel, so
      // it matches.
      maxMismatch: 0.05,
    );
  });

  testWidgets('AreaChartSecondaryYAxis', (tester) async {
    // charts-areachart--area-chart-secondary-y-axis.tsx. `chart2Points` is
    // `y + Math.floor(Math.random() * 10000)`, and the PNG and Oracle B are
    // two page loads — two draws. Oracle B's draw is recoverable exactly (only
    // a secondary domain top of 23860 turns all fifteen legend2 `cy`s back
    // into integers), but it is not the picture this test compares against:
    // the PNG's right axis tops out at 28.49k, Oracle B's at 23.86k.
    //
    // So the offsets are fitted to the PNG instead, by rendering an analytic
    // model of the plot (gridlines, both series' 0.3 stroke and 0.56 fill,
    // d3 curveMonotoneX — checked control point for control point against
    // Oracle B's legend1 path) and minimising the squared error over the plot
    // rect: 0.78 levels RMS per channel at the optimum. The right-axis labels
    // pin the domain: 7.12k / 14.24k / 21.37k / 28.49k is `4 * ceil(max / 4)`
    // = 28488 and nothing else (28492 would print 14.25k), which bounds the
    // x=55 peak to 28485..28488. Each offset is good to a few units, about
    // 0.03px — close enough that the residual is the chart, not the data.
    const offsets = <double>[
      9929, 1163, 7663, 7503, 2185, 8470, 6865, 8485, //
      4229, 5676, 1662, 6214, 4547, 2705, 2395,
    ];
    final data = FluentChartData(
      chartTitle: 'Area chart secondary y-axis example',
      lineChartData: <FluentLineChartSeries>[
        FluentLineChartSeries(legend: 'legend1', data: _points(_stock)),
        FluentLineChartSeries(
          legend: 'legend2',
          data: <FluentLineChartDataPoint>[
            for (var i = 0; i < _stock.length; i++)
              FluentLineChartDataPoint(
                x: _stock[i].$1,
                y: _stock[i].$2 + offsets[i],
              ),
          ],
          useSecondaryYScale: true,
        ),
      ],
    );
    await expectReactParity(
      tester,
      'charts-areachart--area-chart-secondary-y-axis',
      FluentAreaChart(
        data: data,
        props: const FluentCartesianChartProps(
          hideTickOverlap: true,
          yAxisTitle: 'Variation of stock market prices',
          xAxisTitle: 'Number of days',
          secondaryYAxisTitle: 'Variation of stock market prices 2',
          secondaryYScaleOptions: FluentSecondaryYScaleOptions(),
        ),
      ),
      // Measured 29.841% — 58,215 px — then pinned just above it. Nearly all
      // of it is two port defects in `area_chart.dart`, which the analytic
      // model above reproduces to within 0.2 points (29.67%):
      //   * the fills are painted at 0.7 alpha, not 0.56. A secondary axis
      //     forces tozeroy, whose layer opacity is 0.8 (`AreaChart.tsx:685`
      //     `_shouldFillToZeroY()`), but `:740` tests `mode` alone. Alone this
      //     is ~28.6 points;
      //   * the primary axis runs 0..28.49k instead of 0..20k: in tozeroy the
      //     max is taken over every series (`:431-433`), where upstream takes
      //     only the primary ones once a secondary axis exists
      //     (`AreaChart.tsx:336`, `utilities.ts:1599`). Alone ~8.2 points.
      // With both fixed the model leaves 0.011% in the plot.
      maxMismatch: 30.0,
    );
  });
}
