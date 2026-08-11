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
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2_web/src/charts/line_chart.dart';
import 'package:fluent_2_web/src/charts/model/cartesian_series.dart';
import 'package:fluent_2_web/src/charts/model/line_options.dart';
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
      // Measured, then pinned. The residual is the two series' strokes: a 4px
      // line over a 4px halo antialiases differently in Skia and Chromium, and
      // that shows as a red outline along both edges of both lines in
      // `test/parity/out/`. Everything else — plot rect, gridlines, ticks,
      // legend — lands inside the tolerance.
      //
      // It was 6.663% before the two defects this comparison found: axis titles
      // painted untruncated (`cartesian_painter.dart` ignoring the layout's
      // `yAxisTitleMaxHeight`) and the legend's container margin applied twice,
      // which cost the plot 8 of its 260 pixels. Pinned rather than loosened,
      // so a regression in either fails here.
      maxMismatch: 2.6,
    );
  });
}
