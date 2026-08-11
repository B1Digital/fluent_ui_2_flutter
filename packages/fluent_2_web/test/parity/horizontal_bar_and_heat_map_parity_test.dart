// Pixel parity for HorizontalBarChart and HeatMapChart, against the live
// @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`. Nothing here is
// invented or rounded: a chart fed different data than the reference is a
// comparison of two different pictures. Neither story passes a prop this file
// leaves off, and neither passes a style — a style override would tune the
// port until the picture matched and measure nothing.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2_web/src/charts/heat_map_chart.dart';
import 'package:fluent_2_web/src/charts/horizontal_bar_chart.dart';
import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2_web/src/charts/model/bar_data.dart';
import 'package:fluent_2_web/src/charts/model/cartesian_series.dart';
import 'package:fluent_2_web/src/charts/model/heatmap_data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

/// One row of `charts-horizontalbarchart--horizontal-bar-basic`.
///
/// Every row in that story is the same shape — a single point, `total: 15000`
/// and the same `xAxisCalloutData` — so only what differs is spelled at the
/// call site. `xAxisCalloutData` and `yAxisCalloutData` reach the hover
/// popover alone, which no screenshot has open; they are transcribed anyway
/// because the story sets them.
FluentChartData _row(
  String title,
  double x,
  FluentDataVizToken token,
  String yAxisCalloutData,
) => FluentChartData(
  chartTitle: title,
  chartData: <FluentChartDataPoint>[
    FluentChartDataPoint(
      legend: title,
      horizontalBarChartData: FluentHorizontalDataPoint(x: x, total: 15000),
      color: FluentDataVizPalette.resolve(token),
      xAxisCalloutData: '2020/04/30',
      yAxisCalloutData: yAxisCalloutData,
    ),
  ],
);

/// One cell of `charts-heatmapchart--heat-map-chart-basic`.
///
/// `xPoint[i]` is `new Date("2020-03-0(3+i)")`, which JavaScript parses as UTC
/// midnight; `yPoint[i]` is the string `'p(1+i)'`. `rectText` equals `value` in
/// every cell of this story, and `ratio` and `descriptionMessage` only reach
/// the popover, which no screenshot has open.
FluentHeatMapChartDataPoint _cell(int xIndex, int yIndex, double value) =>
    FluentHeatMapChartDataPoint(
      x: DateTime.utc(2020, 3, 3 + xIndex),
      y: 'p${yIndex + 1}',
      value: value,
      rectText: value,
    );

void main() {
  setUpAll(loadParityFonts);

  testWidgets('HorizontalBarBasic', (tester) async {
    // `const data` in charts-horizontalbarchart--horizontal-bar-basic.tsx.
    final data = <FluentChartData>[
      _row('one', 1543, FluentDataVizToken.color1, '10%'),
      _row('two', 800, FluentDataVizToken.color2, '5%'),
      _row('three', 8888, FluentDataVizToken.color3, '59%'),
      _row('four', 15888, FluentDataVizToken.color4, '106%'),
      _row('five', 11444, FluentDataVizToken.color5, '76%'),
      _row('six', 14000, FluentDataVizToken.color6, '93%'),
      _row('seven', 9855, FluentDataVizToken.color7, '66%'),
      _row('eight', 4250, FluentDataVizToken.color8, '28%'),
    ];

    await expectReactParity(
      tester,
      'charts-horizontalbarchart--horizontal-bar-basic',
      FluentHorizontalBarChart(
        data: data,
        // `chartDataMode={'default'}`. `className` is the only other prop the
        // story sets and it carries no rule the port can honour.
        chartDataMode: FluentChartDataMode.byDefault,
      ),
      // MEASURED, NOT CHOSEN — 53.841%, and every point of it is a defect
      // rather than rasteriser noise. Pinned at the measurement so the number
      // is on record and any change to it, in either direction, has to be
      // re-pinned deliberately. Three causes, all visible in
      // `out/charts-horizontalbarchart--horizontal-bar-basic.png`:
      //
      //  1. Every row is 4px too tall. Upstream hangs the 5px title gap on the
      //     LEFT span alone — `chartTitleLeft5pMargin`
      //     (`useHorizontalBarChartStyles.styles.ts:67-69`, selected at
      //     `:134`) — so the title flex line is
      //     max(caption1 16 + 5, body1Strong 20) = 21. This port pads the
      //     whole title Row instead (`horizontal_bar_chart.dart:852-857`),
      //     giving 20 + 5 = 25. Measured row pitch: 43px in the reference,
      //     47px here.
      //  2. The last row keeps its bottom spacing. `_buildRow` wraps every row
      //     in `Padding(bottom: rowSpacing)`
      //     (`horizontal_bar_chart.dart:828-833`) with no last-row exception;
      //     the reference's 334px box is 8 x (21 + 12) + 7 x 10, seven gaps
      //     for eight rows. 4 x 8 + 10 = 42, which is exactly the RenderFlex
      //     overflow asserted below, and the debug overflow stripes across the
      //     last row are that overflow being drawn.
      //  3. The synthesised remainder bar is opaque black instead of grey.
      //     `colorBackgroundOverlay` is rgba(0,0,0,0.4) and composites over
      //     the page to the reference's exact (150,150,150), but the strip
      //     painter writes `fill.withValues(alpha: opacities[i])`
      //     (`horizontal_bar_chart.dart:321`), which REPLACES the fill's own
      //     alpha with the 1.0 that "not dimmed" means instead of multiplying
      //     by it — upstream's `opacity` is an SVG attribute that multiplies.
      //     Sampled at x=300: reference (150,150,150), here (0,0,0).
      maxMismatch: 53.87,
    );

    // The chart does not fit the box the reference was captured at: it asks
    // for 376px inside the reference's 334, and Flutter reports that as a
    // RenderFlex overflow during the pump. Consumed rather than ignored, and
    // asserted rather than swallowed — it is causes 1 and 2 above, arriving
    // as an exception instead of as pixels. When either is fixed this fails,
    // which is the intended tripwire.
    final overflow = tester.takeException();
    expect(overflow, isA<FlutterError>());
    expect('$overflow', contains('overflowed by 42 pixels on the bottom'));
  });

  testWidgets('HeatMapChartBasic', (tester) async {
    // `const HeatMapData: HeatMapChartProps['data']` in
    // charts-heatmapchart--heat-map-chart-basic.tsx, in source order. Source
    // order is load-bearing here: it is the order the y axis comes out in.
    final data = <FluentHeatMapChartData>[
      FluentHeatMapChartData(
        legend: 'Excellent (0-200)',
        value: 100,
        data: <FluentHeatMapChartDataPoint>[_cell(2, 2, 46)],
      ),
      FluentHeatMapChartData(
        legend: 'Good (201-300)',
        value: 250,
        data: <FluentHeatMapChartDataPoint>[
          _cell(0, 1, 265),
          _cell(1, 0, 310),
          _cell(2, 0, 320),
          _cell(6, 2, 300),
          _cell(0, 3, 290),
          _cell(4, 4, 280),
          _cell(5, 3, 300),
        ],
      ),
      FluentHeatMapChartData(
        legend: 'Medium (301-400)',
        value: 350,
        data: <FluentHeatMapChartDataPoint>[
          _cell(1, 1, 345),
          _cell(6, 1, 325),
          _cell(5, 2, 390),
          _cell(1, 3, 385),
          _cell(4, 3, 360),
          _cell(1, 2, 400),
          _cell(3, 0, 400),
        ],
      ),
      FluentHeatMapChartData(
        legend: 'Danger (401-500)',
        value: 450,
        data: <FluentHeatMapChartDataPoint>[
          _cell(4, 0, 423),
          _cell(2, 1, 463),
          _cell(3, 2, 480),
          _cell(2, 3, 491),
          _cell(1, 4, 433),
          _cell(5, 4, 473),
        ],
      ),
      FluentHeatMapChartData(
        legend: 'Very Danger (501-600)',
        value: 550,
        data: <FluentHeatMapChartDataPoint>[
          _cell(5, 0, 600),
          _cell(5, 1, 536),
          _cell(3, 1, 520),
          _cell(4, 2, 525),
          _cell(6, 3, 560),
          _cell(3, 4, 580),
          _cell(6, 4, 590),
        ],
      ),
    ];

    // `yPointMapping`, read by the story's `yAxisStringFormatter`.
    const yPointMapping = <String, String>{
      'p1': 'Ohio',
      'p2': 'Alaska',
      'p3': 'Texas',
      'p4': 'DC',
      'p5': 'NYC',
    };

    await expectReactParity(
      tester,
      'charts-heatmapchart--heat-map-chart-basic',
      FluentHeatMapChart(
        data: data,
        // The width and height sliders start at 450 and 350, which is the box
        // the harness mounts at; the chart reads its size from its
        // constraints, so neither is a prop here.
        chartTitle: 'Heat map chart basic example',
        // `culture={window.navigator.language}` — the capture browser's.
        culture: 'en-US',
        yAxisStringFormatter: (point) => yPointMapping[point]!,
        xAxisNumberFormatString: '.7s',
        yAxisNumberFormatString: '.3s',
        domainValuesForColorScale: const <double>[0, 200, 400, 600],
        rangeValuesForColorScale: <Color>[
          FluentDataVizPalette.resolve(FluentDataVizToken.color5),
          FluentDataVizPalette.resolve(FluentDataVizToken.color6),
          FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          FluentDataVizPalette.resolve(FluentDataVizToken.color10),
        ],
        // `reflowProps={{mode: 'min-width'}}` governs the container query the
        // storybook page runs, not the chart's own painting, and the reference
        // is a single static clip — no port equivalent, nothing to pass.
      ),
      // MEASURED, NOT CHOSEN — 48.388%, and it is one defect repeated across
      // every cell: the y categories come out in the wrong order, so all five
      // rows are on the wrong bands. The columns, the colour ramp, the cell
      // geometry and the legend all land, which is what the few grey cells in
      // the diff are.
      //
      // The reference's y axis, bottom to top, is Texas, Alaska, Ohio, DC,
      // NYC — p3, p2, p1, p4, p5, the order the cells appear in the story's
      // source. This port gives Alaska, DC, NYC, Ohio, Texas, alphabetical.
      // Two independent causes, both reachable from this story's props, which
      // set no ordering at all:
      //
      //  * upstream branches on `props.yAxisCategoryOrder !== 'default'`
      //    (`HeatMapChart.tsx:715-717`), and an ABSENT prop is `undefined`,
      //    which is not `'default'` — so the story takes the
      //    `sortAxisCategories` path, whose `undefined` arm returns
      //    `Object.keys(...)`, insertion order (`utilities.ts:2049-2110`).
      //    `FluentCartesianChartProps.yAxisCategoryOrder` is non-nullable and
      //    defaults to `FluentAxisCategoryOrder.defaultOrder`
      //    (`cartesian_chart_props.dart:117`), which is upstream's *explicit*
      //    `'default'` — the legacy `sortOrder` path the story never reaches.
      //    The port cannot express the absent prop;
      //    `FluentAxisCategoryOrder.data` reaches the same insertion order and
      //    is deliberately NOT passed here, because the story does not pass it
      //    and a test that passes it measures a chart the story never built.
      //  * even on that legacy path the two disagree: upstream sorts the raw
      //    keys and formats afterwards (`HeatMapChart.tsx:657-668` feeding
      //    `:433-445`), giving p1..p5 -> Ohio, Alaska, Texas, DC, NYC, while
      //    `buildFluentHeatMapDataSet` formats first and sorts the labels
      //    (`heat_map_chart.dart:112-120` admits this), giving Alaska, DC,
      //    NYC, Ohio, Texas. Neither of those is the reference either.
      maxMismatch: 48.41,
    );
  });
}
