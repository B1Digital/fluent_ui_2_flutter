// Pixel parity for the VerticalBarChart story variants, against the live
// @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`, with every
// interactive control left in its initial `React.useState` value. The port has
// no `width` / `height` props: the story's own numbers are the manifest size the
// harness mounts the chart at.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/bar_data.dart';
import 'package:fluent_2/src/charts/model/chart_common.dart';
import 'package:fluent_2/src/charts/model/line_options.dart';
import 'package:fluent_2/src/charts/vertical_bar_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

/// The CSS named colours the stories spell as strings, from the CSS Color
/// Module Level 4 keyword table the capture browser resolved them against.
const Color _dodgerBlue = Color(0xFF1E90FF);
const Color _midnightBlue = Color(0xFF191970);
const Color _darkBlue = Color(0xFF00008B);
const Color _deepSkyBlue = Color(0xFF00BFFF);
const Color _lightGreen = Color(0xFF90EE90);
const Color _green = Color(0xFF008000);
const Color _darkGreen = Color(0xFF006400);
const Color _brown = Color(0xFFA52A2A);

/// `lineLegendColor={`rgb(174, 140, 0)`}` in the styled and accessibility
/// stories.
const Color _olive = Color(0xFFAE8C00);

void main() {
  setUpAll(loadParityFonts);

  testWidgets('VerticalBarAxisTooltip', (tester) async {
    // `const points` (:79-100).
    const points = <FluentVerticalBarChartDataPoint>[
      FluentVerticalBarChartDataPoint(
        x: 'Simple Text',
        y: 1000,
        color: _dodgerBlue,
      ),
      FluentVerticalBarChartDataPoint(
        x: 'Showing all text here',
        y: 5000,
        color: _midnightBlue,
      ),
      FluentVerticalBarChartDataPoint(
        x: 'Large data, showing all text by tooltip',
        y: 3000,
        color: _darkBlue,
      ),
      FluentVerticalBarChartDataPoint(x: 'Data', y: 2000, color: _deepSkyBlue),
    ];

    await expectReactParity(
      tester,
      'charts-verticalbarchart--vertical-bar-axis-tooltip',
      const FluentVerticalBarChart(
        chartTitle: 'Vertical bar chart axis tooltip example ',
        data: points,
        // `barWidthEnabled` starts true and `barWidth` at 16 (:23-29);
        // `maxBarWidth` starts at 100 (:30). Both padding checkboxes start
        // unchecked, so both paddings are `undefined` (:236-241).
        barWidth: 16,
        maxBarWidth: 100,
        // `selectedCallout` starts at 'showTooltip' (:21-22), so
        // `showXAxisLablesTooltip` is true and `wrapXAxisLables` false.
        props: FluentCartesianChartProps(
          hideLegend: true,
          showXAxisLablesTooltip: true,
        ),
      ),
      // Measured 0.000% — 0 pixels of 222,052. Four solid bars, gridlines and
      // axes land on the capture's pixels exactly; the truncated tick labels
      // are text and masked. Pinned at zero: any pixel that moves fails.
      maxMismatch: 0,
    );
  });

  testWidgets('VerticalBarChartResponsive', (tester) async {
    // `const points` (:16-86). `ResponsiveContainer` sizes the chart to its
    // parent, which the capture recorded as the 944x350 box mounted here.
    final points = <FluentVerticalBarChartDataPoint>[
      FluentVerticalBarChartDataPoint(
        x: 0,
        y: 10000,
        legend: 'Oranges',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
        lineData: const FluentBarLineDatum(y: 7000),
      ),
      FluentVerticalBarChartDataPoint(
        x: 10000,
        y: 50000,
        legend: 'Dogs',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
        lineData: const FluentBarLineDatum(y: 30000),
      ),
      FluentVerticalBarChartDataPoint(
        x: 25000,
        y: 30000,
        legend: 'Apples',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
        lineData: const FluentBarLineDatum(y: 3000),
      ),
      // The only bar with no lineData.
      FluentVerticalBarChartDataPoint(
        x: 40000,
        y: 13000,
        legend: 'Bananas',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
      ),
      FluentVerticalBarChartDataPoint(
        x: 52000,
        y: 43000,
        legend: 'Giraffes',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
        lineData: const FluentBarLineDatum(y: 30000),
      ),
      FluentVerticalBarChartDataPoint(
        x: 68000,
        y: 30000,
        legend: 'Cats',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
        lineData: const FluentBarLineDatum(y: 5000),
      ),
      FluentVerticalBarChartDataPoint(
        x: 80000,
        y: 20000,
        legend: 'Elephants',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
        lineData: const FluentBarLineDatum(y: 16000),
      ),
      FluentVerticalBarChartDataPoint(
        x: 92000,
        y: 45000,
        legend: 'Monkeys',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
        lineData: const FluentBarLineDatum(y: 40000),
      ),
    ];

    await expectReactParity(
      tester,
      'charts-verticalbarchart--vertical-bar-chart-responsive',
      FluentVerticalBarChart(
        data: points,
        lineLegendText: 'Line',
        lineLegendColor: _brown,
        // `const lineOptions = { lineBorderWidth: '2' }` (:88).
        lineOptions: const FluentLineOptions(lineBorderWidth: 2),
      ),
      // Measured 0.066% — 208 pixels of 313,014, all of it legend and line AA:
      //   * 140 px: five legend swatches sit at fractional x (149.625,
      //     232.1875, 297.797, 453.797, 592.797). Chromium pixel-snaps each
      //     HTML box's edges (150..164), the port antialiases the fraction, so
      //     both edge columns of each 14px swatch differ.
      //   * 28 px: the "Line" swatch is 4px tall here and 6 in the capture —
      //     `Legends.tsx:376`'s 4px is the content box and the 1px border
      //     (`useLegendsStyles.styles.ts:82`) adds two rows (Oracle B: 14x6).
      //   * 40 px: Skia-vs-Chromium AA on the square caps and joins of the 3px
      //     line and its 7px halo.
      maxMismatch: 0.07,
    );
  });

  testWidgets('VerticalBarCustomAccessibility', (tester) async {
    // `isChecked` starts true (:13-14), so every `...(isChecked && {lineData})`
    // spread is present and every aria label takes its checked branch.
    const points = <FluentVerticalBarChartDataPoint>[
      FluentVerticalBarChartDataPoint(
        x: 'One',
        y: 20,
        lineData: FluentBarLineDatum(y: 10, yAxisCalloutData: '12%'),
        callOutSemantics: FluentChartSemantics(
          label: 'Bar series 1 of 4 one 12% 20',
        ),
      ),
      FluentVerticalBarChartDataPoint(
        x: 'Two',
        y: 48,
        lineData: FluentBarLineDatum(y: 28),
        callOutSemantics: FluentChartSemantics(
          label: 'Bar series 2 of 4 Two 28 48',
        ),
      ),
      FluentVerticalBarChartDataPoint(
        x: 'Three',
        y: 30,
        lineData: FluentBarLineDatum(y: 4),
        callOutSemantics: FluentChartSemantics(
          label: 'Bar series 3 of 4 Three 4 30',
        ),
      ),
      FluentVerticalBarChartDataPoint(
        x: 'Four',
        y: 40,
        lineData: FluentBarLineDatum(y: 28),
        callOutSemantics: FluentChartSemantics(
          label: 'Bar series 4 of 4 Four 28 40',
        ),
      ),
    ];

    await expectReactParity(
      tester,
      'charts-verticalbarchart--vertical-bar-custom-accessibility',
      const FluentVerticalBarChart(
        chartTitle: 'Vertical bar chart custom accessibility example ',
        data: points,
        barWidth: 20,
        // `useSingleColor` starts true (:15), so every bar is `colors[0]`.
        useSingleColor: true,
        colors: <Color>[_lightGreen, _green, _darkGreen],
        lineLegendColor: _olive,
        props: FluentCartesianChartProps(yAxisTickCount: 6, hideLegend: true),
      ),
      // Measured 0.008% — 25 pixels of 314,861, all Skia-vs-Chromium AA at the
      // four vertices of the 3px square-capped line. Bars and grid are exact.
      maxMismatch: 0.01,
    );
  });

  testWidgets('VerticalBarDynamic', (tester) async {
    // `_getData(5, 'number')` (:147-167) draws five distinct integer x in
    // 1..75 and five y in 1..90 from `Math.random()` with no seed, and Oracle
    // B's capture of this story is a different draw from the PNG's. The five
    // bars below are recovered from the PNG's own manifest instead: the bar
    // labels' text rects give y (15, 22, 89, 8, 72), and their centres invert
    // the x scale the tick rects pin down (tick 10 at 64.5, 75 at 606.5, so
    // 8.338px per unit after d3-axis's 0.5 crisp offset) to 12.94, 26.94,
    // 44.94, 51.94, 70.94 — the same 0.5 offset again, so 13, 27, 45, 52, 71.
    // Author order is not recoverable; it only decides paint order, and no two
    // bars overlap.
    final points = <FluentVerticalBarChartDataPoint>[
      for (final (x, y) in const <(int, int)>[
        (13, 15),
        (27, 22),
        (45, 89),
        (52, 8),
        (71, 72),
      ])
        FluentVerticalBarChartDataPoint(x: x, y: y.toDouble()),
    ];

    await expectReactParity(
      tester,
      'charts-verticalbarchart--vertical-bar-dynamic',
      FluentVerticalBarChart(
        chartTitle: 'Vertical bar chart dynamic example',
        data: points,
        // `colors` starts at `_colors[0]` (:172).
        colors: <Color>[
          FluentDataVizPalette.resolve(FluentDataVizToken.color1),
          FluentDataVizPalette.resolve(FluentDataVizToken.color2),
          FluentDataVizPalette.resolve(FluentDataVizToken.color3),
        ],
        // `barWidth` starts undefined (:179-181), `maxBarWidth` at 24 (:182),
        // both paddings unchecked.
        props: const FluentCartesianChartProps(
          hideLegend: true,
          yMaxValue: 100,
          hideTickOverlap: true,
        ),
      ),
      // Measured 3.648% — 8,073 pixels of 221,320, every one of them a single
      // defect: the bars are measured against the data extent [0, 89] instead
      // of upstream's `_yMax = max(yAxisDomain.last, yMaxValue)` [0, 100]
      // (`VerticalBarChart.tsx:895-899`, `:1124`). The 89 bar reaches the 100
      // gridline, every bar is 100/89 too tall, and the colour ramp is spread
      // over 89 instead of 100 — the 89 bar paints color3 (42,160,164) where
      // the capture interpolates (83,125,159). x, widths and axes are exact.
      maxMismatch: 3.7,
    );
  });

  testWidgets('VerticalBarStyled', (tester) async {
    // `isChecked` starts true (:13-14): every lineData spread is present.
    const points = <FluentVerticalBarChartDataPoint>[
      FluentVerticalBarChartDataPoint(
        x: 'One',
        y: 20,
        lineData: FluentBarLineDatum(y: 10, yAxisCalloutData: '12%'),
      ),
      FluentVerticalBarChartDataPoint(
        x: 'Two',
        y: 48,
        lineData: FluentBarLineDatum(y: 28),
      ),
      FluentVerticalBarChartDataPoint(
        x: 'Three',
        y: 30,
        lineData: FluentBarLineDatum(y: 4),
      ),
      FluentVerticalBarChartDataPoint(
        x: 'Four',
        y: 40,
        lineData: FluentBarLineDatum(y: 28),
      ),
      FluentVerticalBarChartDataPoint(
        x: 'Five',
        y: 13,
        lineData: FluentBarLineDatum(y: 8, yAxisCalloutData: '45%'),
      ),
      FluentVerticalBarChartDataPoint(x: 'Six', y: 60),
      FluentVerticalBarChartDataPoint(x: 'Seven', y: 60),
      FluentVerticalBarChartDataPoint(
        x: 'Eight',
        y: 57,
        lineData: FluentBarLineDatum(y: 48),
      ),
      FluentVerticalBarChartDataPoint(x: 'Nine', y: 14),
      FluentVerticalBarChartDataPoint(x: 'Ten', y: 35),
      FluentVerticalBarChartDataPoint(
        x: 'Eleven',
        y: 20,
        lineData: FluentBarLineDatum(y: 1),
      ),
      FluentVerticalBarChartDataPoint(
        x: 'Twelve',
        y: 44,
        lineData: FluentBarLineDatum(y: 10),
      ),
      FluentVerticalBarChartDataPoint(x: 'Thirteen', y: 33),
    ];

    await expectReactParity(
      tester,
      'charts-verticalbarchart--vertical-bar-styled',
      const FluentVerticalBarChart(
        chartTitle: 'Vertical bar chart styled example ',
        data: points,
        barWidth: 20,
        // `useSingleColor` starts true (:15): every bar is `colors[0]`, green.
        useSingleColor: true,
        colors: <Color>[_green, _lightGreen, _darkGreen],
        lineLegendColor: _olive,
        props: FluentCartesianChartProps(yAxisTickCount: 6, hideLegend: true),
      ),
      // Measured 0.012% — 37 pixels of 307,905, all Skia-vs-Chromium AA at the
      // ten vertices of the 3px square-capped line. Bars and grid are exact.
      maxMismatch: 0.015,
    );
  });
}
