// Pixel parity for ScatterChart, against the live @fluentui/react-charts
// render. `charts-scatterchart--scatter-chart-date` lives in
// `area_scatter_parity_test.dart`; these are the other three stories.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`. Nothing here is
// invented or rounded: a chart fed different data than the reference is a
// comparison of two different pictures.
//
// Each story's width/height sliders start at the values the harness mounts at
// (manifest `width`/`height`), so they are not transcribed separately. The
// `styles={{ svgTooltip }}` override only paints the hover tooltip, which the
// initial render does not show.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2/src/charts/chrome/legend_shape.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/cartesian_series.dart';
import 'package:fluent_2/src/charts/model/chart_common.dart';
import 'package:fluent_2/src/charts/scatter_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

void main() {
  setUpAll(loadParityFonts);

  testWidgets('ScatterChartDefault', (tester) async {
    // `const data: ChartProps` in
    // charts-scatterchart--scatter-chart-default.tsx.
    final data = FluentChartData(
      chartTitle: 'Project Revenue and Transactions Over Time',
      scatterChartData: <FluentScatterChartSeries>[
        FluentScatterChartSeries(
          legend: 'Phase 1',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          data: const <FluentScatterChartDataPoint>[
            FluentScatterChartDataPoint(x: 10, y: 50000, markerSize: 12),
            FluentScatterChartDataPoint(x: 20, y: 75000, markerSize: 15),
            FluentScatterChartDataPoint(x: 30, y: 90000, markerSize: 18),
            FluentScatterChartDataPoint(x: 40, y: 120000, markerSize: 22),
            FluentScatterChartDataPoint(x: 50, y: 150000, markerSize: 25),
          ],
        ),
        FluentScatterChartSeries(
          legend: 'Phase 2',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
          data: const <FluentScatterChartDataPoint>[
            FluentScatterChartDataPoint(x: 60, y: 180000, markerSize: 28),
            FluentScatterChartDataPoint(x: 70, y: 200000, markerSize: 30),
            FluentScatterChartDataPoint(x: 80, y: 220000, markerSize: 32),
            FluentScatterChartDataPoint(x: 90, y: 250000, markerSize: 35),
            FluentScatterChartDataPoint(x: 100, y: 300000, markerSize: 40),
          ],
        ),
        FluentScatterChartSeries(
          legend: 'Milestone',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
          data: const <FluentScatterChartDataPoint>[
            FluentScatterChartDataPoint(x: 75, y: 250000, markerSize: 50),
          ],
        ),
      ],
    );

    await expectReactParity(
      tester,
      'charts-scatterchart--scatter-chart-default',
      FluentScatterChart(
        data: data,
        // `culture={window.navigator.language}` — the capture browser's is
        // en-US. `selectMultipleLegends` starts false, which is the port's
        // default single selection.
        culture: 'en-US',
        props: const FluentCartesianChartProps(
          xAxisTitle: 'Days since project start',
          yAxisTitle: 'Revenue in dollars',
        ),
      ),
      // Measured 0.013% — 29 pixels of 216,656, aligned. 28 of them are two
      // 14px columns, x 185 and 199: the "Milestone" legend swatch, one column
      // left of upstream's. Oracle B puts it at x 185.5 inside the clip and
      // Chromium paints [186, 200); the port now snaps swatches to device
      // pixels as Chromium does, but the labels before it measure a fraction
      // of a pixel differently in Selawik and Segoe UI, so its x lands under
      // the .5 and rounds to [185, 199). The last pixel is one antialiased
      // marker edge. Every marker, gridline and tick matches. It was 0.026%
      // while the "Phase 2" swatch (x 106.75) was unsnapped too.
      maxMismatch: 0.015,
    );
  });

  testWidgets('ScatterChartString', (tester) async {
    // `const data: ChartProps` in
    // charts-scatterchart--scatter-chart-string.tsx.
    final data = FluentChartData(
      chartTitle: 'Sales Performance by Category',
      scatterChartData: <FluentScatterChartSeries>[
        FluentScatterChartSeries(
          legend: 'Region 1',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          data: const <FluentScatterChartDataPoint>[
            FluentScatterChartDataPoint(
              x: 'Electronics',
              y: 50000,
              markerSize: 25,
            ),
            FluentScatterChartDataPoint(
              x: 'Furniture',
              y: 30000,
              markerSize: 20,
            ),
            FluentScatterChartDataPoint(
              x: 'Clothing',
              y: 20000,
              markerSize: 15,
            ),
            FluentScatterChartDataPoint(x: 'Toys', y: 15000, markerSize: 10),
            FluentScatterChartDataPoint(x: 'Books', y: 10000, markerSize: 8),
          ],
        ),
        FluentScatterChartSeries(
          legend: 'Region 2',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
          data: const <FluentScatterChartDataPoint>[
            FluentScatterChartDataPoint(
              x: 'Electronics',
              y: 60000,
              markerSize: 30,
            ),
            FluentScatterChartDataPoint(
              x: 'Furniture',
              y: 25000,
              markerSize: 18,
            ),
            FluentScatterChartDataPoint(
              x: 'Clothing',
              y: 22000,
              markerSize: 16,
            ),
            FluentScatterChartDataPoint(x: 'Toys', y: 12000, markerSize: 12),
            FluentScatterChartDataPoint(x: 'Books', y: 8000, markerSize: 6),
          ],
        ),
      ],
    );

    await expectReactParity(
      tester,
      'charts-scatterchart--scatter-chart-string',
      FluentScatterChart(
        data: data,
        culture: 'en-US',
        props: const FluentCartesianChartProps(
          xAxisTitle: 'Product Category',
          yAxisTitle: 'Revenue in dollars',
        ),
      ),
      // Measured 0.000% — not one of 217,726 unmasked pixels differs. Both
      // legend swatches land within 1/64 px of a whole pixel here (Oracle B:
      // x 28 and 113.015625 inside the clip), so the swatch rounding that
      // costs scatter-default its "Milestone" columns does not arise. Pinned
      // at 0: the floor check (measured >= half the pin) admits nothing else.
      maxMismatch: 0,
    );
  });

  testWidgets('ScatterChartLogAxisExample', (tester) async {
    // `const data: ChartProps` in
    // charts-scatterchart--scatter-chart-log-axis-example.tsx.
    final data = FluentChartData(
      chartTitle: 'Scatter Chart',
      scatterChartData: <FluentScatterChartSeries>[
        FluentScatterChartSeries(
          legend: 'Trace 1',
          legendShape: FluentChartLegendShape.circle,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
          data: const <FluentScatterChartDataPoint>[
            FluentScatterChartDataPoint(
              x: 1.2589254117941673,
              y: 2.4236435587418756,
              markerSize: 7,
            ),
            FluentScatterChartDataPoint(
              x: 2.39095514427051,
              y: 3.209069828287282,
              markerSize: 8,
            ),
            FluentScatterChartDataPoint(
              x: 4.540909610972476,
              y: 6.700279261114452,
              markerSize: 13,
            ),
            FluentScatterChartDataPoint(
              x: 8.624109968952766,
              y: 15.657933357041166,
              markerSize: 6,
            ),
            FluentScatterChartDataPoint(
              x: 16.378937069540648,
              y: 26.410125335101004,
              markerSize: 8,
            ),
            FluentScatterChartDataPoint(
              x: 31.10692935198609,
              y: 21.628233443544943,
              markerSize: 8,
            ),
            FluentScatterChartDataPoint(
              x: 59.078379115879464,
              y: 71.08357068207286,
              markerSize: 8,
            ),
            FluentScatterChartDataPoint(
              x: 112.20184543019641,
              y: 95.45928375106901,
              markerSize: 12,
            ),
            FluentScatterChartDataPoint(
              x: 213.09410153667977,
              y: 175.17899348200768,
              markerSize: 5,
            ),
            FluentScatterChartDataPoint(
              x: 404.70899507597613,
              y: 367.05817591616454,
              markerSize: 6,
            ),
            FluentScatterChartDataPoint(
              x: 768.6246100397738,
              y: 616.3133732775369,
              markerSize: 14,
            ),
            FluentScatterChartDataPoint(
              x: 1459.7743028861687,
              y: 1533.9498528438594,
              markerSize: 14,
            ),
            FluentScatterChartDataPoint(
              x: 2772.4079967417756,
              y: 2371.497871143982,
              markerSize: 5,
            ),
            FluentScatterChartDataPoint(
              x: 5265.366081044865,
              y: 3617.6579249480537,
              markerSize: 9,
            ),
            FluentScatterChartDataPoint(
              x: 10000,
              y: 7149.749744738273,
              markerSize: 12,
            ),
          ],
        ),
        FluentScatterChartSeries(
          legend: 'Trace 2',
          legendShape: FluentChartLegendShape.circle,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.warning),
          data: const <FluentScatterChartDataPoint>[
            FluentScatterChartDataPoint(
              x: 3.1622776601683795,
              y: 2.1949926582336188,
              markerSize: 13,
            ),
            FluentScatterChartDataPoint(
              x: 6.1054022965853285,
              y: 4.772119103737707,
              markerSize: 16,
            ),
            FluentScatterChartDataPoint(
              x: 11.787686347935873,
              y: 5.594480133444149,
              markerSize: 17,
            ),
            FluentScatterChartDataPoint(
              x: 22.758459260747887,
              y: 22.975394675590913,
              markerSize: 21,
            ),
            FluentScatterChartDataPoint(
              x: 43.939705607607905,
              y: 14.632760823223153,
              markerSize: 24,
            ),
            FluentScatterChartDataPoint(
              x: 84.83428982440716,
              y: 49.97794497098575,
              markerSize: 12,
            ),
            FluentScatterChartDataPoint(
              x: 163.78937069540646,
              y: 88.37494969641493,
              markerSize: 21,
            ),
            FluentScatterChartDataPoint(
              x: 316.22776601683796,
              y: 259.59923251477073,
              markerSize: 10,
            ),
            FluentScatterChartDataPoint(
              x: 610.5402296585327,
              y: 486.6059651967493,
              markerSize: 24,
            ),
            FluentScatterChartDataPoint(
              x: 1178.7686347935867,
              y: 671.2364692543704,
              markerSize: 13,
            ),
            FluentScatterChartDataPoint(
              x: 2275.8459260747863,
              y: 1356.3898150565117,
              markerSize: 15,
            ),
            FluentScatterChartDataPoint(
              x: 4393.97056076079,
              y: 1697.3956575634736,
              markerSize: 22,
            ),
            FluentScatterChartDataPoint(
              x: 8483.428982440717,
              y: 1782.902150290326,
              markerSize: 19,
            ),
            FluentScatterChartDataPoint(
              x: 16378.937069540612,
              y: 7474.040318615067,
              markerSize: 20,
            ),
            FluentScatterChartDataPoint(
              x: 31622.776601683792,
              y: 16592.321174954774,
              markerSize: 14,
            ),
          ],
        ),
      ],
    );

    await expectReactParity(
      tester,
      'charts-scatterchart--scatter-chart-log-axis-example',
      FluentScatterChart(
        data: data,
        // `xScaleType` and `yScaleType` both start as 'log'
        // (`React.useState<string>("log")`). The story passes no culture and
        // no axis titles.
        props: const FluentCartesianChartProps(
          hideTickOverlap: true,
          xScaleType: FluentAxisScaleType.log,
          yScaleType: FluentAxisScaleType.log,
        ),
      ),
      // Measured 0.000% — not one of 205,005 unmasked pixels differs. It was
      // 11.195%, nearly all of it 38 missing horizontal gridlines: upstream's
      // `createNumericYAxis` never calls `tickValues` or `ticks(count)` on a
      // log scale (`utilities.ts:858-861`), so d3-axis asks for the scale's
      // DEFAULT ten ticks, and over 4.48 decades `log.js` returns every 1-9
      // mantissa (2, 3, ... 9, 10, 20, ... 30k), each a full-width gridline
      // with a blank label. The port asked for `yAxisTickCount` = 4 and kept
      // only the four decades; it now draws the default ticks too. The other
      // 17px, on the "Trace 2" legend circle's edge, are gone as well.
      maxMismatch: 0,
    );
  });
}
