// Pixel parity for Sparkline and ChartTable, against the live
// @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2_web/src/charts/chart_table.dart';
import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2_web/src/charts/model/cartesian_series.dart';
import 'package:fluent_2_web/src/charts/sparkline.dart';
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
      maxMismatch: 0.03,
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
      // Measured 12.476% — 23,554 pixels of 188,800 — and NOT rasteriser
      // noise. Pinned at the measured value so the number is recorded, not
      // because the number is acceptable. Two defects, both visible in
      // `out/charts-charttable--chart-table-basic.png`:
      //
      //  1. The table is 376px wide against upstream's 700. `width` is applied
      //     to the outer SizedBox (`chart_table.dart:345`) while the grid keeps
      //     `IntrinsicColumnWidth`, so it never fills the box. Upstream puts
      //     `width` on the *table* element — the capture proves it: the root
      //     box is 944 (100% of the parent less the 12px margins) and the table
      //     inside it is exactly 700 — and CSS auto layout spreads the surplus
      //     across the columns in proportion to their content, giving pitches
      //     of 129/114/117/117/118/103. 7,473 of the mismatched pixels (3.96 of
      //     the 12.48) are at x >= 376, i.e. beyond where this table stops.
      //  2. The row pitch is 32 against upstream's 34, and the whole grid is
      //     160 tall against 172. `TableBorder` strokes the 2px line centred on
      //     a boundary that takes no space of its own, but `border-collapse`
      //     adds the collapsed border to the table's box. Every boundary is 2px
      //     short, in both axes.
      //
      // The story has no textRects, so unlike every other parity story its
      // glyphs are compared unmasked. That is a small part of the number: the
      // reference has 3,423 dark pixels in total (1.81%), so text can account
      // for at most ~3.6 points even fully displaced, and the remaining ~9 is
      // grid geometry.
      maxMismatch: 13.73,
    );
  });
}
