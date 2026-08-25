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
      // Measured 0.026% — 56 pixels of 214,457, best shift (0,0). Every one of
      // them is a 1px column on the left and right edge of two legend
      // swatches: upstream paints the swatch on integer boundaries (156..169),
      // this paints the same 14px swatch half a pixel left, so both edges
      // antialias. The bars, gridlines and axes are pixel-identical.
      maxMismatch: 0.05,
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
      // Measured 0.034% — 73 pixels of 216,701, best shift (0,0). Same
      // residual as the grouped chart above: 1px fringe columns either side of
      // three legend swatches, plus a single pixel at the tip of the 40k bar
      // where it meets the plot's right edge. The bars themselves, the value
      // axis and the category gridlines are pixel-identical.
      maxMismatch: 0.06,
    );
  });
}
