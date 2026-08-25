// Pixel parity for Sparkline and ChartTable, against the live
// @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/chart_table.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/cartesian_series.dart';
import 'package:fluent_2/src/charts/sparkline.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

void main() {
  setUpAll(loadParityFonts);

  testWidgets('SparklineDimensions', (tester) async {
    // `const sampleData` in charts-sparkline--sparkline-dimensions.tsx. One
    // series, shared by all four sparklines the story renders.
    final sampleData = FluentChartData(
      chartTitle: '89.7',
      lineChartData: <FluentLineChartSeries>[
        FluentLineChartSeries(
          legend: '89.7',
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
          data: const <Object>[
            FluentLineChartDataPoint(x: 1, y: 58.13),
            FluentLineChartDataPoint(x: 2, y: 140.98),
            FluentLineChartDataPoint(x: 3, y: 20),
            FluentLineChartDataPoint(x: 4, y: 89.7),
            FluentLineChartDataPoint(x: 5, y: 99),
            FluentLineChartDataPoint(x: 6, y: 13.28),
            FluentLineChartDataPoint(x: 7, y: 31.32),
            FluentLineChartDataPoint(x: 8, y: 89.7),
          ],
        ),
      ],
    );

    // The reference is not one chart: the story stacks four Sparklines, and the
    // capture's box is the union of the four component roots — the `<span>`
    // labels beside them belong to the story's own flex row, not to the chart,
    // and fall outside it. The stack below reproduces that union, and every
    // number in it is measured off the reference rather than guessed:
    //
    //   * width 280 = the widest root, 200 (plot) + 80 (the value-text svg,
    //     `valueTextWidth`'s default). The manifest's four textRects sit at
    //     x = 88, 158, 88, 208 — each one `width + 8`, which is upstream's
    //     `x="0%" dx={8}` inside that strip.
    //   * the four roots' tops are 0, 45, 90 and 155 and their heights are 20,
    //     20, 40 and 60 — read straight off the PNG's non-background row runs,
    //     (0,19) (45,64) (90,129) (155,214) — so the roots are separated by a
    //     uniform 25px and the last one ends exactly on the reference's 215th
    //     row.
    const gap = SizedBox(height: 25);
    await expectReactParity(
      tester,
      'charts-sparkline--sparkline-dimensions',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // <Sparkline data={sampleData} showLegend={true} /> — 80x20 default.
          FluentSparkline(data: sampleData, showLegend: true),
          gap,
          // width={150}
          FluentSparkline(data: sampleData, width: 150, showLegend: true),
          gap,
          // height={40}
          FluentSparkline(data: sampleData, height: 40, showLegend: true),
          gap,
          // width={200} height={60}
          FluentSparkline(
            data: sampleData,
            width: 200,
            height: 60,
            showLegend: true,
          ),
        ],
      ),
      // Measured 0.009% — 5 pixels of 58,400. All five are the antialiased
      // half-pixel where the last vertex meets the plot's right edge: (80, 9)
      // and (80, 106) are the 80-wide plots' final column, (197..200, 178..181)
      // the 200-wide one's. Chromium's svg clip drops that fringe and Skia
      // paints it. Nothing else in the four charts differs at all.
      maxMismatch: 0.015,
    );
  });

  testWidgets('ChartTableBasic', (tester) async {
    // `basicHeaders` in charts-charttable--chart-table-basic.tsx.
    const headers = <FluentChartTableCell>[
      FluentChartTableCell(value: 'Product'),
      FluentChartTableCell(value: 'Q1 Sales'),
      FluentChartTableCell(value: 'Q2 Sales'),
      FluentChartTableCell(value: 'Q3 Sales'),
      FluentChartTableCell(value: 'Q4 Sales'),
      FluentChartTableCell(value: 'Total'),
    ];

    // `basicRows`. The story's `showStyledCells` Switch starts false and its
    // `tableVariant` RadioGroup starts on "basic", so `getCurrentData()`
    // returns these rows verbatim — no per-cell style, and not `styledRows`.
    const rows = <List<FluentChartTableCell>>[
      <FluentChartTableCell>[
        FluentChartTableCell(value: 'Product A'),
        FluentChartTableCell(value: 25000),
        FluentChartTableCell(value: 30000),
        FluentChartTableCell(value: 28000),
        FluentChartTableCell(value: 35000),
        FluentChartTableCell(value: 118000),
      ],
      <FluentChartTableCell>[
        FluentChartTableCell(value: 'Product B'),
        FluentChartTableCell(value: 18000),
        FluentChartTableCell(value: 22000),
        FluentChartTableCell(value: 25000),
        FluentChartTableCell(value: 27000),
        FluentChartTableCell(value: 92000),
      ],
      <FluentChartTableCell>[
        FluentChartTableCell(value: 'Product C'),
        FluentChartTableCell(value: 32000),
        FluentChartTableCell(value: 28000),
        FluentChartTableCell(value: 31000),
        FluentChartTableCell(value: 29000),
        FluentChartTableCell(value: 120000),
      ],
      <FluentChartTableCell>[
        FluentChartTableCell(value: 'Product D'),
        FluentChartTableCell(value: 15000),
        FluentChartTableCell(value: 19000),
        FluentChartTableCell(value: 21000),
        FluentChartTableCell(value: 23000),
        FluentChartTableCell(value: 78000),
      ],
    ];

    // The story's injected `.chart-table` stylesheet is not reproduced, because
    // it does not reach the reference either. It asks for 1px
    // `colorNeutralStroke1` borders and `8px 12px` cell padding; the PNG has
    // 2px `#e0e0e0` (`colorNeutralStroke2`) grid lines — verticals at
    // x = 0/1, 129/130, 243/244, 360/361, 477/478, 595/596, 698/699 — and a
    // 34px row pitch, which is 8 + 16 + 8 + 2. Those are ChartTable's own
    // `useChartTableStyles` defaults, so the port's defaults are the faithful
    // input and a style override here would be a divergence, not a transcript.
    await expectReactParity(
      tester,
      'charts-charttable--chart-table-basic',
      const FluentChartTable(
        // width={width} height={height}, both React.useState initial values.
        width: 700,
        height: 200,
        headers: headers,
        rows: rows,
      ),
      // Measured 4.070% — 7,684 pixels of 188,800 — down from 12.476%. Both
      // of the geometry defects that made up the old number are gone:
      //
      //  1. The grid is 700 wide, not 376. `width` now lands on the grid the
      //     way `ChartTable.tsx:130` lands it on the <table>, and the columns
      //     take the surplus in proportion to their content the way CSS auto
      //     layout does.
      //  2. The row pitch is 34, not 32, and the grid is 172 tall, not 160.
      //     The collapsed 2px line is laid out as a real Border on each cell
      //     instead of stroked over the top by TableBorder, so it occupies the
      //     space `border-collapse` gives it.
      //
      // Measured off the two PNGs, every horizontal line now lands exactly:
      // rows 0/34/68/102/136/170 in both. The verticals land on
      // 0/128/245/362/479/596/698 against the capture's
      // 0/129/243/360/477/595/698 — pitches 128/117/117/117/117/102 against
      // 129/114/117/117/118/103.
      //
      // That last 1-2px is the documented font residual and nothing else.
      // Chromium sizes the four "Qn Sales" headers differently from one
      // another (114/117/117/118); Selawik Semibold makes all four identical
      // (117/117/117/117), and back-solving the proportional split puts
      // Selawik's "Q1 Sales" 3.3% wide of Segoe UI Semibold's — inside the
      // 3.87% that `support/react_parity.dart` measured for weight 600. CSS
      // auto layout then amplifies each of those by 698/388, so a 1.5px metric
      // error becomes a 3px column error.
      //
      // The story has no textRects, so unlike every other parity story its
      // glyphs are compared unmasked, and there is no layout fix below about
      // 1.7%: shifting each column of the Flutter render by its own measured
      // offset before comparing still leaves 3,219 mismatched pixels of pure
      // Skia-versus-Chromium glyph rasterisation (the reference carries 4,730
      // dark pixels, 2.51%). Of the 7,684 that remain, 896 are the four
      // misplaced vertical lines and the other 6,788 are text.
      maxMismatch: 4.48,
    );
  });
}
