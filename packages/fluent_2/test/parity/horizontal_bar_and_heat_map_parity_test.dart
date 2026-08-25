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
import 'package:fluent_2/src/charts/heat_map_chart.dart';
import 'package:fluent_2/src/charts/horizontal_bar_chart.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/bar_data.dart';
import 'package:fluent_2/src/charts/model/cartesian_series.dart';
import 'package:fluent_2/src/charts/model/heatmap_data.dart';
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
      // MEASURED, NOT CHOSEN — 0.149%, down from 53.841%. Pinned at the
      // measurement so the number is on record and any change to it, in either
      // direction, has to be re-pinned deliberately.
      //
      // What moved (all three were one chart, not three):
      //
      //  1. Row pitch was 47 against the reference's 43. Upstream hangs the
      //     5px title gap on the LEFT span alone — `chartTitleLeft5pMargin`
      //     (`useHorizontalBarChartStyles.styles.ts:67-69`, selected at
      //     `:129-136`) — inside a `display: flex` row, so the flex line is
      //     max(caption1 16 + 5, body1Strong 20) = 21. The port padded the
      //     whole title Row instead, giving max(16, 20) + 5 = 25. The gap now
      //     hangs on the title `Text` and the Row is `crossAxisAlignment
      //     .start`, which is the same 21 with both spans at its top — the two
      //     boxes Oracle B measures at `[24, 48, 600, 21]` and
      //     `[24, 48, 20.109375, 16]`.
      //  2. The last row kept its bottom spacing, so the chart asked for 376px
      //     inside the reference's 334 and Flutter reported a 42px RenderFlex
      //     overflow, drawn as stripes across the last row. The reference box
      //     is 8 x (21 + 12) + 7 x 10 — seven gaps for eight rows, because
      //     `capture_png.mjs` clips to the union of the `fui-hbc__chartTitle`
      //     and `fui-hbc__chart` boxes and the trailing `items` margin is
      //     outside every one of them. The gap now lives on the enclosing
      //     `Column`'s `spacing`, which also reproduces upstream's 10 + 16
      //     between the last row and a legend strip.
      //  3. The synthesised remainder bar was opaque black.
      //     `colorBackgroundOverlay` is rgba(0,0,0,0.4), but the strip painter
      //     wrote `fill.withValues(alpha: opacities[i])`, REPLACING the fill's
      //     own alpha with the 1.0 that "not dimmed" means. Upstream's
      //     `opacity` is an SVG presentation attribute, which multiplies.
      //     Sampled at (300, 26): reference (150,150,150), now (153,153,153).
      //
      // The 0.149% left is 289 pixels and none of it is geometry. 283 are the
      // glyphs of the eight left-hand row titles, which `_manifest.json`
      // records no textRect for — `FocusableTooltipText` nests a span inside
      // `fui-hbc__chartTitleLeft`, so the capture's leaf-element filter skips
      // it and Skia's hinting is compared against Chromium's. The other 6 are
      // the leading edge of "11,444" poking two pixels out of its own mask,
      // which is the Selawik-Semibold-against-Segoe-UI-Semibold width residual
      // `support/react_parity.dart` documents.
      maxMismatch: 0.17,
    );

    // The chart now fits the box the reference was captured at exactly, so the
    // pump raises nothing. Asserted rather than assumed: a RenderFlex overflow
    // is consumed by `takeException` and would otherwise be invisible here
    // while it painted debug stripes into the comparison above.
    expect(tester.takeException(), isNull);
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
      // MEASURED, NOT CHOSEN — 2.713%, down from 48.388%. Pinned at the
      // measurement so the number is on record and any change to it, in either
      // direction, has to be re-pinned deliberately.
      //
      // What moved. The old 48% was every cell in the wrong row: the reference
      // y axis reads Texas, Alaska, Ohio, DC, NYC bottom to top — p3, p2, p1,
      // p4, p5, the order the cells appear in the story's source — and the
      // port gave Alaska, DC, NYC, Ohio, Texas, alphabetical. Two causes, both
      // in one function, and both reachable from this story's props, which set
      // no ordering at all:
      //
      //  1. Upstream branches on `props.yAxisCategoryOrder !== 'default'`
      //     (`HeatMapChart.tsx:715-717`), and an ABSENT prop is `undefined`,
      //     which is not `'default'` — HeatMapChart's
      //     `props = { yAxisCategoryOrder: 'default', … }` (`:49-56`) is a
      //     parameter default that fires only when React passes no props
      //     object, which it never does. So the story takes the
      //     `sortAxisCategories` path, whose `undefined` arm returns
      //     `Object.keys(...)`, insertion order (`utilities.ts:2049-2110`).
      //     `FluentCartesianChartProps.yAxisCategoryOrder` was non-nullable and
      //     defaulted to `FluentAxisCategoryOrder.defaultOrder`, which is
      //     upstream's *explicit* `'default'` and the legacy `sortOrder` path
      //     the story never reaches. It is now `FluentAxisCategoryOrder?` and
      //     null is the absent prop, so this story says nothing and gets the
      //     insertion order the reference has.
      //  2. That alone moved 48.388% to 37.494% and flipped the defect onto the
      //     x axis, because `buildFluentHeatMapDataSet` did not know the axis
      //     type: upstream gates the whole `sortAxisCategories` branch behind
      //     `_xAxisType.current === XAxisTypes.StringAxis` (`:711-717`), so this
      //     story's DATE x axis stays on the legacy arm and sorts `+a - +b` over
      //     the epoch-millisecond index keys. The port sent both axes down the
      //     same path and produced Mar/05, Mar/03, Mar/04, Mar/09, … The
      //     function now derives the axis types the way `:744-746` does and
      //     sorts the legacy arm on the raw value, which also retires the
      //     `// parity:` note that used to sit on it.
      //
      // 0.217% since, and the 2.713% it replaced was never this chart's fault.
      // 3,129 of those pixels were ten scanlines at the five row boundaries —
      // the port's cell band measured 49.976 on a 50.996 pitch against the
      // capture's 49.781 on 50.797 — and the cause was the HARNESS, not the
      // cell geometry. Oracle B records the root box at y 125.21875, height
      // 350, so the screenshot spans 351 device rows for a 350px box; the
      // harness sized the chart to the PNG and handed it a pixel the browser
      // never had, which the y band scale then divided out across all five
      // rows. `logicalSize` gives it the browser's 350 and the band comes out
      // at 49.781, Oracle's number exactly. The x axis was always right
      // (41.111111 / 54.444444 in both, unchanged).
      //
      // The rest was the legend's overflow trigger, closed in
      // `chrome/legend.dart` — see the VerticalBarChart story for that one.
      logicalSize: const Size(450, 350),
      maxMismatch: 0.24,
    );
  });
}
