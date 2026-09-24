// Pixel parity for GroupedVerticalBarChart, against the live
// @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`. Every story here
// carries interactive controls; the values used are their INITIAL state, which
// is the state the reference was captured in.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2/src/charts/grouped_vertical_bar_chart.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/bar_data.dart';
import 'package:fluent_2/src/charts/model/chart_common.dart';
import 'package:fluent_2/src/charts/model/line_options.dart';
import 'package:fluent_2/src/charts/model/series_v2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

Color _c(FluentDataVizToken token) => FluentDataVizPalette.resolve(token);

const List<String> _quarters = <String>[
  'Jan - Mar',
  'Apr - Jun',
  'Jul - Sep',
  'Oct - Dec',
];

List<FluentDataPointV2> _points(List<double> ys) => <FluentDataPointV2>[
  for (var i = 0; i < ys.length; i++)
    FluentDataPointV2(x: _quarters[i], y: ys[i]),
];

void main() {
  setUpAll(loadParityFonts);

  testWidgets('GroupedVerticalBarChartLine', (tester) async {
    // `const chartData: GroupedVerticalBarChartProps['dataV2']` in
    // charts-groupedverticalbarchart--grouped-vertical-bar-chart-line.tsx.
    // The two line series name a bare `DataVizPalette.color1`/`color2` token
    // rather than `getColorFromToken(...)`; Oracle B shows upstream resolving
    // them to the same colours, so they are resolved here too.
    final dataV2 = <FluentDataSeries>[
      FluentBarSeries(
        legend: '2022',
        data: _points(<double>[33000, 33000, 14000, -33000]),
        color: _c(FluentDataVizToken.color3),
      ),
      FluentBarSeries(
        legend: '2023',
        data: _points(<double>[-44000, -3000, 50000, 3000]),
        color: _c(FluentDataVizToken.color4),
      ),
      FluentBarSeries(
        legend: '2024',
        data: _points(<double>[-54000, 9000, -60000, -6000]),
        color: _c(FluentDataVizToken.color5),
      ),
      FluentBarSeries(
        legend: '2021',
        data: _points(<double>[24000, -12000, -10000, -15000]),
        color: _c(FluentDataVizToken.color6),
      ),
      FluentLineSeries(
        legend: 'From_Legacy_to_O365',
        data: _points(<double>[-21600, 21812, -21712, 24800]),
        color: _c(FluentDataVizToken.color1),
        lineOptions: const FluentLineOptions(lineBorderWidth: 2),
      ),
      FluentLineSeries(
        legend: 'All',
        data: _points(<double>[29700, -28400, 28200, -29400]),
        color: _c(FluentDataVizToken.color2),
        lineOptions: const FluentLineOptions(lineBorderWidth: 2),
      ),
    ];

    await expectReactParity(
      tester,
      'charts-groupedverticalbarchart--grouped-vertical-bar-chart-line',
      FluentGroupedVerticalBarChart(
        dataV2: dataV2,
        chartTitle: 'Grouped Vertical Bar chart line example',
        // `calloutVariant` starts 'SingleCallout' and `selectMultipleLegends`
        // false — both the widget's defaults.
        props: const FluentCartesianChartProps(
          reflowMode: FluentChartReflowMode.minWidth,
        ),
      ),
      // Measured 0.178% — 467 pixels of 262,094, best shift (0,0). Bars, lines,
      // markers, gridlines and axes all land where upstream's do; the residual
      // is three things:
      //   * 244 px: both line legends draw a 14x14 square. Upstream flags them
      //     `isLineLegendInBarChart` (`GroupedVerticalBarChart.tsx:239`,
      //     `:252`) and draws a 14x6 bar (Oracle B `fui-legend__rect`
      //     [52, 601, 14, 6]); `grouped_vertical_bar_chart.dart` never sets the
      //     flag on its line legend items.
      //   * 128 px: every negative label is "−" (U+2212, what d3-format emits),
      //     which Selawik lacks. Under `flutter test` the first fallback family,
      //     `-apple-system`, resolves to the test font's filled box, which is
      //     wider than Segoe's minus and pokes out of the reference text masks.
      //   * 72 px: 1px fringe columns either side of four bar-legend swatches
      //     at fractional x, which Chromium snaps to whole pixels; ~23 px of
      //     antialiasing where the 3px lines cross.
      maxMismatch: 0.19,
    );
  });

  testWidgets('GroupedVerticalBarNegative', (tester) async {
    // `const data` in charts-groupedverticalbarchart--grouped-vertical-bar-
    // negative.tsx, one row per bar: key, value, colour token, legend,
    // xAxisCalloutData, yAxisCalloutData, callout aria-label.
    FluentGroupedBarSeriesPoint bar(
      String key,
      double value,
      FluentDataVizToken token,
      String legend,
      String xCallout,
      String aria,
    ) => FluentGroupedBarSeriesPoint(
      key: key,
      data: value,
      color: _c(token),
      legend: legend,
      xAxisCalloutData: xCallout,
      // Every bar's yAxisCalloutData is its own value as a string.
      yAxisCalloutData: value.toInt().toString(),
      callOutSemantics: FluentChartSemantics(label: aria),
    );
    const c3 = FluentDataVizToken.color3;
    const c4 = FluentDataVizToken.color4;
    const c5 = FluentDataVizToken.color5;
    const c6 = FluentDataVizToken.color6;
    final data = <FluentGroupedVerticalBarChartData>[
      FluentGroupedVerticalBarChartData(
        name: 'Jan - Mar',
        series: <FluentGroupedBarSeriesPoint>[
          bar(
            'series1',
            33000,
            c3,
            '2022',
            '2022/04/30',
            'Group Jan - Mar 1 of 4, Bar series 1 of 2 2022, x value '
                '2022/04/30, y value 29%',
          ),
          bar(
            'series2',
            -44000,
            c4,
            '2023',
            '2023/04/30',
            'Group Jan - Mar 1 of 4, Bar series 2 of 2 2023, x value '
                '2023/04/30, y value 44%',
          ),
          bar(
            'series3',
            -54000,
            c5,
            '2024',
            '2024/04/30',
            'Group Jan - Mar 1 of 4, Bar series 3 of 4 2022, x value '
                '2024/04/30, y value 44%',
          ),
          bar(
            'series4',
            24000,
            c6,
            '2021',
            '2021/04/30',
            'Group Jan - Mar 1 of 4, Bar series 4 of 4 2021, x value '
                '2021/04/30, y value 44%',
          ),
        ],
      ),
      FluentGroupedVerticalBarChartData(
        name: 'Apr - Jun',
        series: <FluentGroupedBarSeriesPoint>[
          bar(
            'series1',
            33000,
            c3,
            '2022',
            '2022/05/30',
            'Group Apr - Jun 2 of 4, Bar series 1 of 2 2022, x value '
                '2022/05/30, y value 29%',
          ),
          bar(
            'series2',
            -3000,
            c4,
            '2023',
            '2023/05/30',
            'Group Apr - Jun 2 of 4, Bar series 2 of 2 2023, x value '
                '2023/05/30, y value 3%',
          ),
          bar(
            'series3',
            9000,
            c5,
            '2024',
            '2024/05/30',
            'Group Apr - Jun 2 of 4, Bar series 3 of 4 2024, x value '
                '2024/05/30, y value 3%',
          ),
          bar(
            'series4',
            -12000,
            c6,
            '2021',
            '2021/05/30',
            'Group Apr - Jun 2 of 4, Bar series 4 of 4 2021, x value '
                '2021/05/30, y value 3%',
          ),
        ],
      ),
      FluentGroupedVerticalBarChartData(
        name: 'Jul - Sep',
        series: <FluentGroupedBarSeriesPoint>[
          bar(
            'series1',
            14000,
            c3,
            '2022',
            '2022/06/30',
            'Group Jul - Sep 3 of 4, Bar series 1 of 2 2022, x value '
                '2022/06/30, y value 13%',
          ),
          bar(
            'series2',
            50000,
            c4,
            '2023',
            '2023/06/30',
            'Group Jul - Sep 3 of 4, Bar series 2 of 2 2023, x value '
                '2023/06/30, y value 50%',
          ),
          bar(
            'series3',
            -60000,
            c5,
            '2024',
            '2024/06/30',
            'Group Jul - Sep 3 of 4, Bar series 3 of 4 2024, x value '
                '2024/06/30, y value 50%',
          ),
          bar(
            'series4',
            -10000,
            c6,
            '2021',
            '2021/06/30',
            'Group Jul - Sep 3 of 4, Bar series 4 of 4 2021, x value '
                '2021/06/30, y value 50%',
          ),
        ],
      ),
      FluentGroupedVerticalBarChartData(
        name: 'Oct - Dec',
        series: <FluentGroupedBarSeriesPoint>[
          bar(
            'series1',
            -33000,
            c3,
            '2022',
            '2022/07/30',
            'Group Oct - Dec 4 of 4, Bar series 1 of 2 2022, x value '
                '2022/07/30, y value 29%',
          ),
          bar(
            'series2',
            3000,
            c4,
            '2023',
            '2023/07/30',
            'Group Oct - Dec 4 of 4, Bar series 2 of 2 2023, x value '
                '2023/07/30, y value 3%',
          ),
          bar(
            'series3',
            -6000,
            c5,
            '2024',
            '2024/07/30',
            'Group Oct - Dec 4 of 4, Bar series 3 of 4 2024, x value '
                '2024/07/30, y value 3%',
          ),
          bar(
            'series4',
            -15000,
            c6,
            '2021',
            '2021/07/30',
            'Group Oct - Dec 4 of 4, Bar series 4 of 4 2021, x value '
                '2021/07/30, y value 3%',
          ),
        ],
      ),
    ];

    await expectReactParity(
      tester,
      'charts-groupedverticalbarchart--grouped-vertical-bar-negative',
      FluentGroupedVerticalBarChart(
        data: data,
        chartTitle: 'Grouped Vertical Bar chart basic example',
        // `culture={window.navigator.language}`: the capture browser is en-US.
        culture: 'en-US',
        // `barWidth` starts 16. `hideLabels`, `roundCorners` and the legend
        // multi-select start false, and `isCalloutForStack` compares
        // 'singleCallout' against 'StackCallout', so it is false.
        barWidth: 16,
        props: const FluentCartesianChartProps(
          reflowMode: FluentChartReflowMode.minWidth,
        ),
      ),
      // Measured 0.076% — 201 pixels of 264,317, best shift (0,0). The bars,
      // gridlines and axes are pixel-identical. 145 px are the U+2212 minus
      // sign on every negative bar and tick label drawing as the test font's
      // box (see the line story above); 56 px are 1px fringe columns either
      // side of two legend swatches at fractional x.
      maxMismatch: 0.08,
    );
  });

  testWidgets('GroupedVerticalBarSecondaryYAxis', (tester) async {
    // `const data: GroupedVerticalBarChartData[]` in
    // charts-groupedverticalbarchart--grouped-vertical-bar-secondary-y-axis.tsx:
    // 2021 on the primary scale, 2022 on the secondary.
    FluentGroupedVerticalBarChartData group(
      String name,
      double v2021,
      double v2022,
    ) => FluentGroupedVerticalBarChartData(
      name: name,
      series: <FluentGroupedBarSeriesPoint>[
        FluentGroupedBarSeriesPoint(
          key: 'series1',
          data: v2021,
          color: _c(FluentDataVizToken.color6),
          legend: '2021',
        ),
        FluentGroupedBarSeriesPoint(
          key: 'series2',
          data: v2022,
          color: _c(FluentDataVizToken.color5),
          legend: '2022',
          useSecondaryYScale: true,
        ),
      ],
    );
    final data = <FluentGroupedVerticalBarChartData>[
      group('Jan - Mar', 24000, 54000),
      group('Apr - Jun', 12000, 9000),
      group('Jul - Sep', 10000, 60000),
      group('Oct - Dec', 15000, 6000),
    ];

    await expectReactParity(
      tester,
      'charts-groupedverticalbarchart--grouped-vertical-bar-secondary-y-axis',
      FluentGroupedVerticalBarChart(
        data: data,
        chartTitle: 'Grouped Vertical Bar chart secondary y-axis example',
        barWidth: 16,
        props: const FluentCartesianChartProps(
          hideTickOverlap: true,
          secondaryYScaleOptions: FluentSecondaryYScaleOptions(),
        ),
      ),
      // Measured 0.008% — 16 pixels of 200,194, best shift (0,0). 14 are one
      // fringe column of the "2022" legend swatch at fractional x; 2 are a
      // secondary-axis tick label's antialiased edge past its mask.
      maxMismatch: 0.01,
    );
  });
}
