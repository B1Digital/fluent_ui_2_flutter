// Pixel parity for GroupedVerticalBarChart and HorizontalBarChartWithAxis,
// against the live @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`. Both stories carry
// interactive controls; the values used here are their INITIAL state, which is
// the state the reference was captured in.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/grouped_vertical_bar_chart.dart';
import 'package:fluent_2/src/charts/horizontal_bar_chart_with_axis.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/bar_data.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

void main() {
  setUpAll(loadParityFonts);

  testWidgets('GroupedVerticalBarDefault', (tester) async {
    // `const data` in charts-groupedverticalbarchart--grouped-vertical-bar-
    // default.tsx. The story's own id has no "basic" in it — the assignment's
    // `--grouped-vertical-bar-chart-basic` is not in the manifest; this is the
    // GroupedVerticalBarChart story whose chartTitle is
    // "Grouped Vertical Bar chart basic example".
    final data = <FluentGroupedVerticalBarChartData>[
      FluentGroupedVerticalBarChartData(
        name: 'Jan - Mar',
        series: <FluentGroupedBarSeriesPoint>[
          FluentGroupedBarSeriesPoint(
            key: 'series1',
            data: 33000,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
            legend: '2022',
            xAxisCalloutData: '2022/04/30',
            yAxisCalloutData: '29%',
          ),
          FluentGroupedBarSeriesPoint(
            key: 'series2',
            data: 44000,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
            legend: '2023',
            xAxisCalloutData: '2023/04/30',
            yAxisCalloutData: '44%',
          ),
          FluentGroupedBarSeriesPoint(
            key: 'series3',
            data: 54000,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
            legend: '2024',
            xAxisCalloutData: '2024/04/30',
            yAxisCalloutData: '44%',
          ),
          FluentGroupedBarSeriesPoint(
            key: 'series4',
            data: 24000,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
            legend: '2021',
            xAxisCalloutData: '2021/04/30',
            yAxisCalloutData: '44%',
          ),
        ],
      ),
      FluentGroupedVerticalBarChartData(
        name: 'Apr - Jun',
        series: <FluentGroupedBarSeriesPoint>[
          FluentGroupedBarSeriesPoint(
            key: 'series1',
            data: 33000,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
            legend: '2022',
            xAxisCalloutData: '2022/05/30',
            yAxisCalloutData: '29%',
          ),
          FluentGroupedBarSeriesPoint(
            key: 'series2',
            data: 3000,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
            legend: '2023',
            xAxisCalloutData: '2023/05/30',
            yAxisCalloutData: '3%',
          ),
          FluentGroupedBarSeriesPoint(
            key: 'series3',
            data: 9000,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
            legend: '2024',
            xAxisCalloutData: '2024/05/30',
            yAxisCalloutData: '3%',
          ),
          FluentGroupedBarSeriesPoint(
            key: 'series4',
            data: 12000,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
            legend: '2021',
            xAxisCalloutData: '2021/05/30',
            yAxisCalloutData: '3%',
          ),
        ],
      ),
      FluentGroupedVerticalBarChartData(
        name: 'Jul - Sep',
        series: <FluentGroupedBarSeriesPoint>[
          FluentGroupedBarSeriesPoint(
            key: 'series1',
            data: 14000,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
            legend: '2022',
            xAxisCalloutData: '2022/06/30',
            yAxisCalloutData: '13%',
          ),
          FluentGroupedBarSeriesPoint(
            key: 'series2',
            data: 50000,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
            legend: '2023',
            xAxisCalloutData: '2023/06/30',
            yAxisCalloutData: '50%',
          ),
          FluentGroupedBarSeriesPoint(
            key: 'series3',
            data: 60000,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
            legend: '2024',
            xAxisCalloutData: '2024/06/30',
            yAxisCalloutData: '50%',
          ),
          FluentGroupedBarSeriesPoint(
            key: 'series4',
            data: 10000,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
            legend: '2021',
            xAxisCalloutData: '2021/06/30',
            yAxisCalloutData: '50%',
          ),
        ],
      ),
      FluentGroupedVerticalBarChartData(
        name: 'Oct - Dec',
        series: <FluentGroupedBarSeriesPoint>[
          FluentGroupedBarSeriesPoint(
            key: 'series1',
            data: 33000,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
            legend: '2022',
            xAxisCalloutData: '2022/07/30',
            yAxisCalloutData: '29%',
          ),
          FluentGroupedBarSeriesPoint(
            key: 'series2',
            data: 3000,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
            legend: '2023',
            xAxisCalloutData: '2023/07/30',
            yAxisCalloutData: '3%',
          ),
          FluentGroupedBarSeriesPoint(
            key: 'series3',
            data: 6000,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
            legend: '2024',
            xAxisCalloutData: '2024/07/30',
            yAxisCalloutData: '3%',
          ),
          FluentGroupedBarSeriesPoint(
            key: 'series4',
            data: 15000,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
            legend: '2021',
            xAxisCalloutData: '2021/07/30',
            yAxisCalloutData: '3%',
          ),
        ],
      ),
    ];

    await expectReactParity(
      tester,
      'charts-groupedverticalbarchart--grouped-vertical-bar-default',
      FluentGroupedVerticalBarChart(
        data: data,
        // The story's only chart props besides width/height, which the harness
        // supplies from the manifest. `hideLabels` starts unchecked.
        chartTitle: 'Grouped Vertical Bar chart basic example',
        culture: 'en-US',
      ),
      // Measured 0.000% — not one of 214,457 unmasked pixels differs. Was
      // 0.026% (56 px) while two legend swatches were painted half a pixel
      // left of the whole-pixel boxes Chromium snaps them to (156..169), so
      // both edges antialiased. Pinned at 0: the floor check admits nothing
      // else.
      maxMismatch: 0,
    );
  });

  testWidgets('HorizontalBarWithAxisBasic', (tester) async {
    // `const points: HorizontalBarChartWithAxisDataPoint[]` in
    // charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-basic.tsx.
    final points = <FluentHorizontalBarChartWithAxisDataPoint>[
      FluentHorizontalBarChartWithAxisDataPoint(
        x: 10000,
        y: 5000,
        legend: 'Oranges',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
        yAxisCalloutData: '2020/04/30',
        xAxisCalloutData: '10%',
      ),
      FluentHorizontalBarChartWithAxisDataPoint(
        x: 20000,
        y: 50000,
        legend: 'Dogs',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
        yAxisCalloutData: '2020/04/30',
        xAxisCalloutData: '20%',
      ),
      FluentHorizontalBarChartWithAxisDataPoint(
        x: 25000,
        y: 30000,
        legend: 'Apples',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
        yAxisCalloutData: '2020/04/30',
        xAxisCalloutData: '37%',
      ),
      FluentHorizontalBarChartWithAxisDataPoint(
        x: 40000,
        y: 13000,
        legend: 'Bananas',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
        yAxisCalloutData: '2020/04/30',
        xAxisCalloutData: '88%',
      ),
    ];

    await expectReactParity(
      tester,
      'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-basic',
      FluentHorizontalBarChartWithAxis(
        data: points,
        // Every switch and checkbox on the story starts off: `useSingleColor`,
        // `enableGradient`, `roundCorners` and `canSelectMultipleLegends` are
        // all false at capture time, which is this widget's default for each.
        // The trailing space in the title is the story's own.
        chartTitle: 'Horizontal bar chart basic example ',
        culture: 'en-US',
      ),
      // Measured 0.00046% (printed 0.000%) — 1 pixel of 216,701, best shift
      // (0,0): the "k" of the Oranges bar's "10k" label, 12px/600 and wide in
      // Selawik Semibold, antialiasing one column past its mask. Bars, both
      // axes, gridlines and swatches are pixel-identical. Was 0.034% while
      // three legend swatches sat at fractional x, as the grouped chart above
      // did.
      maxMismatch: 0.0005,
    );
  });
}
