// Pixel parity for HorizontalBarChartWithAxis, against the live
// @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`. Every story here
// carries interactive controls; the values used are their INITIAL state, which
// is the state the reference was captured in.
//
// Two of the stories draw their data from `Math.random()` with no seed. Those
// values are not guessed: they are read back out of the reference PNG by
// inverting the scales its axes show, and each one is shown to land on an
// integer — which is what the story's `Math.floor` guarantees — before it is
// used. Oracle B cannot supply them: it was captured on a different page load
// and holds a different random draw.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2/src/charts/horizontal_bar_chart_with_axis.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/bar_data.dart';
import 'package:fluent_2/src/charts/model/chart_common.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

Color _c(FluentDataVizToken token) => FluentDataVizPalette.resolve(token);

void main() {
  setUpAll(loadParityFonts);

  testWidgets('HorizontalBarWithAxisCategoryOrder', (tester) async {
    // `_colors` in charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-
    // category-order.tsx.
    final colors = <Color>[
      _c(FluentDataVizToken.color1),
      _c(FluentDataVizToken.color2),
      _c(FluentDataVizToken.color3),
      _c(FluentDataVizToken.color4),
      _c(FluentDataVizToken.color5),
    ];
    // `_getData(5)` is `Math.random()` per point, and the PNG and Oracle B
    // were captured on different page loads, so they drew different data —
    // Oracle B's Label 1/2/4 at 251/67/97 is not this picture. The five points
    // are read back from the reference PNG itself. Sub-pixel bar ends, from
    // each end pixel's antialiased coverage, fit `x = 52.37 + 4.4432 * value`
    // (0..130 across the plot) to within 0.02 px for every one of them at the
    // integers the story's `Math.floor` guarantees: Label 1 ends its first
    // segment at 450.27 (+2 px gap = 90) and its total at 590.0 (121, as
    // printed), Label 2 at 332.30 (63), Label 3 its first segment at 312.52
    // (+2 = 59) and its total at 572.24 (117).
    //
    // Which point is which is fixed by the story's own arithmetic. `yIdx` and
    // `legendIdx` are `floor(random * i)`, so points 0 and 1 are always
    // Label 1 / Legend 1; point 2 can only reach Label 2, so the Label 3 bars
    // are points 3 and 4; and only point 4 can reach legend index 3, which is
    // the color4 fill on Label 3's second segment. Everything else is filled
    // color1, i.e. legend index 0.
    final data = <FluentHorizontalBarChartWithAxisDataPoint>[
      FluentHorizontalBarChartWithAxisDataPoint(
        x: 90,
        y: 'Label 1',
        legend: 'Legend 1',
        color: colors[0],
      ),
      FluentHorizontalBarChartWithAxisDataPoint(
        x: 31,
        y: 'Label 1',
        legend: 'Legend 1',
        color: colors[0],
      ),
      FluentHorizontalBarChartWithAxisDataPoint(
        x: 63,
        y: 'Label 2',
        legend: 'Legend 1',
        color: colors[0],
      ),
      FluentHorizontalBarChartWithAxisDataPoint(
        x: 59,
        y: 'Label 3',
        legend: 'Legend 1',
        color: colors[0],
      ),
      FluentHorizontalBarChartWithAxisDataPoint(
        x: 58,
        y: 'Label 3',
        legend: 'Legend 4',
        color: colors[3],
      ),
    ];

    await expectReactParity(
      tester,
      'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-category-order',
      FluentHorizontalBarChartWithAxis(
        data: data,
        colors: colors,
        // The dropdown's initial state is the explicit string 'default'.
        yAxisCategoryOrder: FluentAxisCategoryOrder.defaultOrder,
        props: const FluentCartesianChartProps(
          hideLegend: true,
          hideTickOverlap: true,
          showYAxisLables: true,
        ),
      ),
      // Measured 0.228% — 504 pixels, best shift (0,0). The plot's left edge
      // sits 0.4px right of upstream's: the margin is the widest y label plus
      // 20 (`CartesianChart.tsx:679`), and Selawik Semibold measures "Label 3"
      // at 32.79px at 10px where the capture's Segoe UI Semibold measured
      // 32.37. That moves the zero gridline (315 px, the whole column), the
      // tick stubs and every bar edge in proportion to its distance from the
      // right end (166 px); 20 px more are the "121"/"117" bar labels, set
      // 600-weight too, spilling past their masks. Every bar value, colour and
      // band position is otherwise exact.
      maxMismatch: 0.25,
    );
  });

  testWidgets('HorizontalBarWithAxisDynamic', (tester) async {
    // `_colors` in charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-
    // dynamic.tsx.
    final colors = <Color>[
      _c(FluentDataVizToken.color1),
      _c(FluentDataVizToken.color2),
      _c(FluentDataVizToken.color3),
    ];
    // `_getData(5, 'number')` is `Math.random()`, and the PNG and Oracle B
    // drew on different page loads, so the points are read back from the
    // reference PNG. Bars are 6 rows tall; their antialiased top and bottom
    // rows put the centres at 31.0, 67.67, 79.89, 153.24 and 299.92, which on
    // a y axis of 0 at 304 to 67 at 31 (4.0746 px per unit) are 67, 58, 55,
    // 37 and 1 to within 0.01. The right ends, on 0 at x 40 to 80 at 630
    // (7.375 px per unit), are 71, 77, 36, 45 and 59 to within 0.01. Every y is
    // 1 mod 3, which is why every bar is `_colors[1]`.
    //
    // What the capture cannot say is the insertion order, and so which bar was
    // "Label n": numeric keys come back ascending from `Object.values`
    // (`groupChartDataByYValue`, `utilities.ts:1386-1399`) whatever order they
    // went in. With `hideLegend` the legend text appears nowhere in the
    // picture, so ascending order is used and only a hover callout would
    // differ.
    FluentHorizontalBarChartWithAxisDataPoint point(double x, int y, int n) =>
        FluentHorizontalBarChartWithAxisDataPoint(
          x: x,
          y: y,
          legend: 'Label $n',
          color: colors[y % colors.length],
        );
    final data = <FluentHorizontalBarChartWithAxisDataPoint>[
      point(59, 1, 1),
      point(45, 37, 2),
      point(36, 55, 3),
      point(77, 58, 4),
      point(71, 67, 5),
    ];

    await expectReactParity(
      tester,
      'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-dynamic',
      FluentHorizontalBarChartWithAxis(
        data: data,
        colors: colors,
        chartTitle: 'Horizontal bar chart dynamic example',
        // `yAxisPaddingEnabled` starts false, so upstream passes `undefined`
        // and lands on the widget's own 0.5 default. `roundCorners` starts
        // false.
        props: const FluentCartesianChartProps(
          hideLegend: true,
          hideTickOverlap: true,
        ),
      ),
      // Measured 0.000% — not one of 224,576 unmasked pixels differs. The
      // numeric y axis leaves the left margin at its 40px floor, so no label
      // width enters the layout. Pinned at 0: the floor check admits nothing
      // else.
      maxMismatch: 0,
    );
  });

  testWidgets('HorizontalBarWithAxisNegative', (tester) async {
    // `_generateData()` in charts-horizontalbarchartwithaxis--horizontal-bar-
    // with-axis-negative.tsx: eight runs over categories A-E, concatenated in
    // this order, each series once positive and once negative.
    const categories = <String>['A', 'B', 'C', 'D', 'E'];
    const series = <String>['Series 1', 'Series 2', 'Series 3', 'Series 4'];
    final colors = <Color>[
      _c(FluentDataVizToken.color1),
      _c(FluentDataVizToken.color2),
      _c(FluentDataVizToken.color3),
      _c(FluentDataVizToken.color4),
    ];
    List<FluentHorizontalBarChartWithAxisDataPoint> run(
      List<double> values,
      int s,
    ) => <FluentHorizontalBarChartWithAxisDataPoint>[
      for (var i = 0; i < categories.length; i++)
        FluentHorizontalBarChartWithAxisDataPoint(
          x: values[i],
          y: categories[i],
          legend: series[s],
          color: colors[s],
          yAxisCalloutData: '2020/04/30',
          xAxisCalloutData: '10%',
        ),
    ];
    final data = <FluentHorizontalBarChartWithAxisDataPoint>[
      ...run(<double>[10, 20, 30, 40, 50], 0),
      ...run(<double>[-10, -20, -30, -40, -50], 0),
      ...run(<double>[20, 30, 40, 50, 60], 1),
      ...run(<double>[-20, -30, -40, -50, -60], 1),
      ...run(<double>[30, 40, 50, 60, 70], 2),
      ...run(<double>[-30, -40, -50, -60, -70], 2),
      ...run(<double>[40, 50, 60, 70, 80], 3),
      ...run(<double>[-40, -50, -60, -70, -80], 3),
    ];

    await expectReactParity(
      tester,
      'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-negative',
      FluentHorizontalBarChartWithAxis(
        data: data,
        // The trailing space is the story's own.
        chartTitle: 'Horizontal bar chart axis tooltip example ',
        // `selectedCallout` starts 'showTooltip', so the tooltip flag is on and
        // the expand flag off. `enableGradient` and `roundCorners` start false;
        // the port has no gradient, which is the false arm.
        props: const FluentCartesianChartProps(
          hideLegend: true,
          showYAxisLablesTooltip: true,
        ),
      ),
      // Measured 0.000% — not one of 221,262 unmasked pixels differs. With
      // `showYAxisLables` off, `startFromX` stays 0 and the left margin is the
      // 40px floor (`CartesianChart.tsx:96`, `:679`), so no label width enters
      // the layout. Pinned at 0: the floor check admits nothing else.
      maxMismatch: 0,
    );
  });

  testWidgets('HorizontalBarWithAxisStringAxisTooltip', (tester) async {
    // `const points` in charts-horizontalbarchartwithaxis--horizontal-bar-with-
    // axis-string-axis-tooltip.tsx.
    final data = <FluentHorizontalBarChartWithAxisDataPoint>[
      FluentHorizontalBarChartWithAxisDataPoint(
        y: 'String One',
        x: 1000,
        color: _c(FluentDataVizToken.color1),
      ),
      FluentHorizontalBarChartWithAxisDataPoint(
        y: 'String Two',
        x: 5000,
        color: _c(FluentDataVizToken.color2),
      ),
      FluentHorizontalBarChartWithAxisDataPoint(
        y: 'String Three',
        x: 3000,
        color: _c(FluentDataVizToken.color3),
      ),
      FluentHorizontalBarChartWithAxisDataPoint(
        y: 'String Four',
        x: 2000,
        color: _c(FluentDataVizToken.color4),
      ),
    ];

    await expectReactParity(
      tester,
      'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-string-axis-tooltip',
      FluentHorizontalBarChartWithAxis(
        data: data,
        chartTitle: 'Horizontal bar chart axis tooltip example ',
        // `selectedCallout` starts 'showTooltip' — the RadioGroup's
        // `defaultValue="basicExample"` matches no radio and does not feed the
        // state. The switches start off.
        props: const FluentCartesianChartProps(
          hideLegend: true,
          showYAxisLablesTooltip: true,
        ),
      ),
      // Measured 0.000% — not one of 220,154 unmasked pixels differs, for the
      // same reason as the negative story: `showYAxisLables` is off, so the
      // left margin is the 40px floor. Pinned at 0.
      maxMismatch: 0,
    );
  });
}
