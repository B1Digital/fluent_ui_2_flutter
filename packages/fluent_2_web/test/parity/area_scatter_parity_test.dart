// Pixel parity for AreaChart and ScatterChart, against the live
// @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`. Nothing here is
// invented or rounded: a chart fed different data than the reference is a
// comparison of two different pictures.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2_web/src/charts/area_chart.dart';
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2_web/src/charts/model/cartesian_series.dart';
import 'package:fluent_2_web/src/charts/scatter_chart.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

void main() {
  setUpAll(loadParityFonts);

  testWidgets('AreaChartBasic', (tester) async {
    // `chart1Points` in charts-areachart--area-chart-basic.tsx.
    const chart1Points = <FluentLineChartDataPoint>[
      FluentLineChartDataPoint(
        x: 20,
        y: 7000,
        xAxisCalloutData: '2018/01/01',
        yAxisCalloutText: '35%',
      ),
      FluentLineChartDataPoint(
        x: 25,
        y: 9000,
        xAxisCalloutData: '2018/01/15',
        yAxisCalloutText: '45%',
      ),
      FluentLineChartDataPoint(
        x: 30,
        y: 13000,
        xAxisCalloutData: '2018/01/28',
        yAxisCalloutText: '65%',
      ),
      FluentLineChartDataPoint(
        x: 35,
        y: 15000,
        xAxisCalloutData: '2018/02/01',
        yAxisCalloutText: '75%',
      ),
      FluentLineChartDataPoint(
        x: 40,
        y: 11000,
        xAxisCalloutData: '2018/03/01',
        yAxisCalloutText: '55%',
      ),
      FluentLineChartDataPoint(
        x: 45,
        y: 8760,
        xAxisCalloutData: '2018/03/15',
        yAxisCalloutText: '43%',
      ),
      FluentLineChartDataPoint(
        x: 50,
        y: 3500,
        xAxisCalloutData: '2018/03/28',
        yAxisCalloutText: '18%',
      ),
      FluentLineChartDataPoint(
        x: 55,
        y: 20000,
        xAxisCalloutData: '2018/04/04',
        yAxisCalloutText: '100%',
      ),
      FluentLineChartDataPoint(
        x: 60,
        y: 17000,
        xAxisCalloutData: '2018/04/15',
        yAxisCalloutText: '85%',
      ),
      FluentLineChartDataPoint(
        x: 65,
        y: 1000,
        xAxisCalloutData: '2018/05/05',
        yAxisCalloutText: '5%',
      ),
      FluentLineChartDataPoint(
        x: 70,
        y: 12000,
        xAxisCalloutData: '2018/06/01',
        yAxisCalloutText: '60%',
      ),
      FluentLineChartDataPoint(
        x: 75,
        y: 6876,
        xAxisCalloutData: '2018/01/15',
        yAxisCalloutText: '34%',
      ),
      FluentLineChartDataPoint(
        x: 80,
        y: 12000,
        xAxisCalloutData: '2018/04/30',
        yAxisCalloutText: '60%',
      ),
      FluentLineChartDataPoint(
        x: 85,
        y: 7000,
        xAxisCalloutData: '2018/05/04',
        yAxisCalloutText: '35%',
      ),
      FluentLineChartDataPoint(
        x: 90,
        y: 10000,
        xAxisCalloutData: '2018/06/01',
        yAxisCalloutText: '50%',
      ),
    ];

    // The story derives series 2 and 3 from series 1 with `.map`, so this does
    // too rather than restating fifteen sums that could be mistyped.
    List<Object> offsetBy(double dy) => <Object>[
      for (final p in chart1Points)
        FluentLineChartDataPoint(
          x: p.x,
          y: p.y + dy,
          xAxisCalloutData: p.xAxisCalloutData,
          yAxisCalloutText: p.yAxisCalloutText,
        ),
    ];

    final data = FluentChartData(
      chartTitle: 'Area chart basic example',
      lineChartData: <FluentLineChartSeries>[
        const FluentLineChartSeries(legend: 'legend1', data: chart1Points),
        FluentLineChartSeries(legend: 'legend2', data: offsetBy(5000)),
        FluentLineChartSeries(legend: 'legend3', data: offsetBy(7000)),
      ],
    );

    await expectReactParity(
      tester,
      'charts-areachart--area-chart-basic',
      FluentAreaChart(
        data: data,
        // The story's controls all start at their default: `showAxisTitles`
        // checked (so both titles are passed), `legendMultiSelect` false, and
        // `changeChartMode` false — which is `mode="tonexty"`, the widget's
        // own default. No colours are given, so the palette assigns by index.
        props: const FluentCartesianChartProps(
          xAxisTitle: 'Number of days',
          yAxisTitle: 'Variation of stock market prices',
        ),
        culture: 'en-US',
      ),
      // Measured 0.032% — 64 pixels of 198,369 — then pinned just above it.
      // The whole residual is antialiasing, in two places:
      //   * 4 columns of 14px in the legend row (x=111/125 and x=195/209),
      //     which are the left and right edge columns of the legend1 and
      //     legend2 swatches. The reference has x=125 at full magenta and
      //     x=111 at background; Flutter has both at partial coverage, so its
      //     swatch sits under a pixel to the left of upstream's. Sub-pixel
      //     rounding of the same rect, not a different rect.
      //   * 8 loose pixels on the stacked bands' outlines, where a curve
      //     crosses at a shallow angle and Skia and Chromium disagree by one
      //     level of coverage.
      // Nothing else differs: the bands, the baseline, the gridlines and the
      // axis ticks land on identical pixels.
      //
      // Pinned tight rather than loosened: an improvement has to be re-pinned
      // deliberately, and a regression of even a tenth of a percent fails.
      maxMismatch: 0.06,
    );
  });

  testWidgets('ScatterChartDate', (tester) async {
    // `const data: ChartProps` in charts-scatterchart--scatter-chart-date.tsx.
    final data = FluentChartData(
      chartTitle: 'Website Traffic and Sales Performance',
      scatterChartData: <FluentScatterChartSeries>[
        FluentScatterChartSeries(
          legend: 'Website Traffic',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          data: <FluentScatterChartDataPoint>[
            FluentScatterChartDataPoint(
              x: DateTime.utc(2023, 3, 1),
              y: 5000,
              markerSize: 15,
            ),
            FluentScatterChartDataPoint(
              x: DateTime.utc(2023, 3, 2),
              y: 7000,
              markerSize: 20,
            ),
            FluentScatterChartDataPoint(
              x: DateTime.utc(2023, 3, 3),
              y: 6500,
              markerSize: 18,
            ),
            FluentScatterChartDataPoint(
              x: DateTime.utc(2023, 3, 4),
              y: 8000,
              markerSize: 25,
            ),
            FluentScatterChartDataPoint(
              x: DateTime.utc(2023, 3, 5),
              y: 9000,
              markerSize: 30,
            ),
            FluentScatterChartDataPoint(
              x: DateTime.utc(2023, 3, 6),
              y: 8500,
              markerSize: 28,
            ),
            FluentScatterChartDataPoint(
              x: DateTime.utc(2023, 3, 7),
              y: 9500,
              markerSize: 35,
            ),
          ],
        ),
        FluentScatterChartSeries(
          legend: 'Sales Performance',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
          data: <FluentScatterChartDataPoint>[
            FluentScatterChartDataPoint(
              x: DateTime.utc(2023, 3, 1),
              y: 2000,
              markerSize: 10,
            ),
            FluentScatterChartDataPoint(
              x: DateTime.utc(2023, 3, 2),
              y: 3000,
              markerSize: 15,
            ),
            FluentScatterChartDataPoint(
              x: DateTime.utc(2023, 3, 3),
              y: 2500,
              markerSize: 12,
            ),
            FluentScatterChartDataPoint(
              x: DateTime.utc(2023, 3, 4),
              y: 4000,
              markerSize: 20,
            ),
            FluentScatterChartDataPoint(
              x: DateTime.utc(2023, 3, 5),
              y: 4500,
              markerSize: 22,
            ),
            FluentScatterChartDataPoint(
              x: DateTime.utc(2023, 3, 6),
              y: 4200,
              markerSize: 18,
            ),
            FluentScatterChartDataPoint(
              x: DateTime.utc(2023, 3, 7),
              y: 5000,
              markerSize: 25,
            ),
          ],
        ),
        FluentScatterChartSeries(
          legend: 'Promotional Campaign',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
          data: <FluentScatterChartDataPoint>[
            FluentScatterChartDataPoint(
              x: DateTime.utc(2023, 3, 5, 12),
              y: 6000,
              markerSize: 40,
            ),
          ],
        ),
      ],
    );

    await expectReactParity(
      tester,
      'charts-scatterchart--scatter-chart-date',
      FluentScatterChart(
        data: data,
        // The story passes only the two titles; it has no `useUTC` control, so
        // the prop stays unset exactly as upstream leaves it.
        props: const FluentCartesianChartProps(
          xAxisTitle: 'Date',
          yAxisTitle: 'Number of visitors',
        ),
        culture: 'en-US',
      ),
      // Measured 0.013% — 28 pixels of 212,803 — then pinned just above it.
      // Every one of them is the same sub-pixel legend-swatch offset the area
      // chart shows: two 14px columns at x=144 and x=158, the edges of the
      // "Sales Performance" swatch. Upstream has x=158 at solid #9373C0 and
      // x=144 at background; Flutter has partial coverage at both, so its
      // swatch spans roughly [144.2, 158.3] against upstream's [145, 159].
      //
      // Not one marker differs. All fifteen circles — including the 40px
      // promotional bubble at a half-day x — sit on the same pixels, in the
      // same colours, in the same paint order, and the date ticks the
      // reference chose (Feb 28 - Mar 08) are the ticks Flutter chose.
      maxMismatch: 0.04,
    );
  });
}
