// Pixel parity for LineChart, against the live @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`. Nothing here is
// invented or rounded: a chart fed different data than the reference is a
// comparison of two different pictures.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/line_chart.dart';
import 'package:fluent_2/src/charts/model/cartesian_series.dart';
import 'package:fluent_2/src/charts/model/line_options.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

void main() {
  setUpAll(loadParityFonts);

  testWidgets('LineChartBasic', (tester) async {
    // `const data: ChartProps` in charts-linechart--line-chart-basic.tsx.
    final data = FluentChartData(
      chartTitle: 'Line Chart Basic Example',
      lineChartData: <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: 'From_Legacy_to_O365',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          lineOptions: const FluentLineOptions(lineBorderWidth: 4),
          data: <Object>[
            FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3, 0), y: 216000),
            FluentLineChartDataPoint(
              x: DateTime.utc(2020, 3, 3, 10),
              y: 218123,
            ),
            FluentLineChartDataPoint(
              x: DateTime.utc(2020, 3, 3, 11),
              y: 217124,
            ),
            FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 4), y: 248000),
            FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5), y: 252000),
            FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 6), y: 274000),
            FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 7), y: 260000),
            FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 8), y: 304000),
            FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 9), y: 218000),
          ],
        ),
        FluentLineChartSeries(
          legend: 'All',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
          lineOptions: const FluentLineOptions(lineBorderWidth: 4),
          data: <Object>[
            FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 3), y: 297000),
            FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 4), y: 284000),
            FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 5), y: 282000),
            FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 6), y: 294000),
            FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 7), y: 224000),
            FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 8), y: 300000),
            FluentLineChartDataPoint(x: DateTime.utc(2020, 3, 9), y: 298000),
          ],
        ),
        FluentLineChartSeries(
          legend: 'single point',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
          data: <Object>[
            FluentLineChartDataPoint(
              x: DateTime.utc(2020, 3, 5, 12),
              y: 232000,
            ),
          ],
        ),
      ],
    );

    await expectReactParity(
      tester,
      'charts-linechart--line-chart-basic',
      FluentLineChart(
        data: data,
        // The story's defaults: `showAxisTitles` and `useUTC` both start
        // checked, `allowMultipleShapes` starts false.
        props: const FluentCartesianChartProps(
          yMinValue: 200,
          yMaxValue: 301,
          xAxisTickCount: 10,
          useUTC: true,
          xAxisTitle: 'Values of each category',
          yAxisTitle:
              'Different categories of mail flow each of which are '
              'categorized into different categories',
        ),
        culture: 'en-US',
      ),
      // Measured 0.028% — 54 pixels of 191,179 — then pinned just above it.
      // Skia and Chromium genuinely agree on this chart: the residual is a
      // handful of pixels where a 4px line crosses another at a shallow angle.
      //
      // It was 6.663% at first, and the whole of that gap was defects rather
      // than rasteriser noise:
      //   * axis titles painted untruncated, because `cartesian_painter.dart`
      //     read neither bound its own layout had solved (6.663 -> 6.392);
      //   * the legend's container margin applied twice, costing the plot 8 of
      //     its 260 pixels (6.392 -> 2.482);
      //   * and the last 2.482 was this harness's own bug — the capture clipped
      //     to the union of everything drawn, so an overflowing legend label
      //     made the reference 714px wide and stretched the mounted chart's x
      //     scale by 2%.
      //
      // Pinned tight rather than loosened: an improvement has to be re-pinned
      // deliberately, and a regression of even a tenth of a percent fails here.
      maxMismatch: 0.05,
    );
  });
}
