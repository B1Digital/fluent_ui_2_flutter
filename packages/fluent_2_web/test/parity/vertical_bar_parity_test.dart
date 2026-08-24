// Pixel parity for VerticalBarChart and VerticalStackedBarChart, against the
// live @fluentui/react-charts render.
//
// Both stories are transcribed from their own source, recovered from the
// storybook runtime into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`. Every number,
// colour and string below is verbatim, and every interactive control is left in
// the initial state the reference was captured in.
//
// The assigned ids `--vertical-bar-basic` and `--vertical-stacked-bar-basic`
// are in neither the manifest nor the recovered story corpus; upstream calls
// both of these stories `Default`, and the exported symbols are
// `VerticalBarDefault` and `VerticalStackedBarDefault`.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2_web/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2_web/src/charts/model/bar_data.dart';
import 'package:fluent_2_web/src/charts/model/chart_common.dart';
import 'package:fluent_2_web/src/charts/model/line_options.dart';
import 'package:fluent_2_web/src/charts/vertical_bar_chart.dart';
import 'package:fluent_2_web/src/charts/vertical_stacked_bar_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

/// The CSS named colours the two stories spell as strings.
///
/// Transcribed from the CSS Color Module Level 4 keyword table, which is what
/// the browser resolved them against in the capture.
const Color _dodgerBlue = Color(0xFF1E90FF);
const Color _midnightBlue = Color(0xFF191970);
const Color _darkBlue = Color(0xFF00008B);
const Color _blue = Color(0xFF0000FF);
const Color _darkSlateBlue = Color(0xFF483D8B);
const Color _royalBlue = Color(0xFF4169E1);
const Color _slateBlue = Color(0xFF6A5ACD);
const Color _steelBlue = Color(0xFF4682B4);
const Color _brown = Color(0xFFA52A2A);

void main() {
  setUpAll(loadParityFonts);

  testWidgets('VerticalBarDefault', (tester) async {
    // `const points: VerticalBarChartDataPoint[]` in
    // charts-verticalbarchart--vertical-bar-default.tsx:78-172.
    const points = <FluentVerticalBarChartDataPoint>[
      FluentVerticalBarChartDataPoint(
        x: 0,
        y: 10000,
        legend: 'Oranges',
        color: _dodgerBlue,
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '4%',
        lineData: FluentBarLineDatum(y: 7000, yAxisCalloutData: '3%'),
      ),
      FluentVerticalBarChartDataPoint(
        x: 10000,
        y: 50000,
        legend: 'Dogs',
        color: _midnightBlue,
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '21%',
        lineData: FluentBarLineDatum(y: 30000, yAxisCalloutData: '12%'),
      ),
      FluentVerticalBarChartDataPoint(
        x: 25000,
        y: 30000,
        legend: 'Apples',
        color: _darkBlue,
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '12%',
        lineData: FluentBarLineDatum(y: 3000, yAxisCalloutData: '1%'),
      ),
      // The only bar with no lineData — the overlaid line skips it.
      FluentVerticalBarChartDataPoint(
        x: 40000,
        y: 13000,
        legend: 'Bananas',
        color: _blue,
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '5%',
      ),
      FluentVerticalBarChartDataPoint(
        x: 52000,
        y: 43000,
        legend: 'Giraffes',
        color: _darkSlateBlue,
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '18%',
        lineData: FluentBarLineDatum(y: 30000, yAxisCalloutData: '12%'),
      ),
      FluentVerticalBarChartDataPoint(
        x: 68000,
        y: 30000,
        legend: 'Cats',
        color: _royalBlue,
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '12%',
        lineData: FluentBarLineDatum(y: 5000, yAxisCalloutData: '2%'),
      ),
      FluentVerticalBarChartDataPoint(
        x: 80000,
        y: 20000,
        legend: 'Elephants',
        color: _slateBlue,
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '8%',
        lineData: FluentBarLineDatum(y: 16000, yAxisCalloutData: '7%'),
      ),
      FluentVerticalBarChartDataPoint(
        x: 92000,
        y: 45000,
        legend: 'Monkeys',
        color: _steelBlue,
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '19%',
        lineData: FluentBarLineDatum(y: 40000, yAxisCalloutData: '16%'),
      ),
    ];

    await expectReactParity(
      tester,
      'charts-verticalbarchart--vertical-bar-default',
      const FluentVerticalBarChart(
        data: points,
        // `showAxisTitles` starts false, so the reference is the `!showAxisTitles`
        // branch at :284-324: no axis titles, and `canSelectMultipleLegends`
        // false because `selectMultipleLegends` starts false too.
        // `useSingleColor` and `hideLabels` also start false, which are the
        // widget's own defaults.
        chartTitle: 'Vertical bar chart basic example ',
        culture: 'en-US',
        lineLegendText: 'just line',
        lineLegendColor: _brown,
        // `lineOptions={{ lineBorderWidth: '2' }}` (:174, :301) — the only
        // field `_createLine` reads (`VerticalBarChart.tsx:186-188`), sizing
        // the 7px halo under the 3px line.
        lineOptions: FluentLineOptions(lineBorderWidth: 2),
      ),
      // Measured 0.580% — 1,229 pixels of 211,831, down from 2.413% (5,111).
      // Two defects closed, both in `vertical_bar_chart.dart`:
      //
      //   * `lineLegendColor` reached only the legend swatch. `_createLine`
      //     destructures it once (`VerticalBarChart.tsx:165`) and strokes both
      //     the polyline (`:214`) and every dot ring (`:244`) with it, so the
      //     delegate now carries it and falls back to `style.lineColor`
      //     (colorPaletteYellowBackground1) only when the caller says nothing.
      //     The story asks for brown and the capture strokes rgb(165, 42, 42);
      //     the port was painting #FFFEF5, invisible except where it crossed a
      //     dark bar.
      //   * There was no `lineOptions` prop, so the 7px `colorNeutralBackground1`
      //     halo `3 + lineBorderWidth * 2` runs under the line (`:199`) was
      //     absent. `FluentLineOptions` now reaches the delegate the same way
      //     VerticalStackedBarChart takes it.
      //
      // A third closed since, in `chrome/legend.dart` rather than here, taking
      // 0.580% (1,229 px) to 0.245%: the strip used to render SEVEN legends and
      // `+2 more` where the capture renders six and `+3 more`. Two causes, both
      // in the width the overflow budget reserves.
      //
      //   * `OverflowMenu.tsx:59` is a MenuButton — a Button carrying
      //     `<ChevronDownRegular />` after its label — and the port built a bare
      //     `FluentButton`. The chevron is 12, not the button ramp's 20
      //     (`useMenuButtonStyles.styles.ts`), so the trigger was short by that
      //     plus its `sNudge` gap.
      //   * `Legends.tsx:137` wraps the strip in a bare `<Overflow>`, whose
      //     `padding` defaults to 10 in BOTH `useOverflowContainer` and
      //     `@fluentui/priority-overflow`'s `overflowManager`. Nothing overrides
      //     it, and the port reserved none of it. With rows measuring
      //     [83.1, 82.5, 65.6, 74.1, 81.9, 78.3, 60.7, …] against an available
      //     630 and a 99.4 trigger, a seventh row needs 526.3 and the budget is
      //     520.6 — the ten pixels ARE the seventh row.
      //
      // Six swatches now land on the reference's to the pixel (28, 111, 194,
      // 259, 333, 415 in both) and the trigger box lands within one
      // (485..582 against 486..581). What is left is that subpixel trigger
      // edge, antialiasing on the dot rings, and the documented font residual.
      maxMismatch: 0.30,
    );
  });

  testWidgets('VerticalStackedBarDefault', (tester) async {
    // `firstChartPoints` (:93-164). Reused by the first, fourth and sixth
    // stacks, exactly as the story reuses the same array.
    final firstChartPoints = <FluentStackedBarDatum>[
      FluentStackedBarDatum(
        legend: 'Metadata1',
        data: 40,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '40%',
      ),
      const FluentStackedBarDatum(
        legend: 'Metadata2',
        data: 5,
        color: _darkBlue,
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '5%',
      ),
      FluentStackedBarDatum(
        legend: 'Metadata3',
        data: 20,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '20%',
      ),
      FluentStackedBarDatum(
        legend: 'Metadata4',
        data: 10,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '10%',
      ),
      FluentStackedBarDatum(
        legend: 'Metadata5',
        data: 23,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '23%',
      ),
      FluentStackedBarDatum(
        legend: 'Metadata6',
        data: 0.4,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '0.4%',
      ),
      FluentStackedBarDatum(
        legend: 'Metadata7',
        data: 0.5,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color7),
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '0.5%',
      ),
      FluentStackedBarDatum(
        legend: 'Metadata8',
        data: 0.3,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color8),
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '0.3%',
      ),
      FluentStackedBarDatum(
        legend: 'Metadata9',
        data: 0.7,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color9),
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '0.7%',
      ),
      FluentStackedBarDatum(
        legend: 'Metadata10',
        data: 0.1,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '0.1%',
      ),
    ];
    // `secondChartPoints` (:166-188).
    final secondChartPoints = <FluentStackedBarDatum>[
      FluentStackedBarDatum(
        legend: 'Metadata1',
        data: 30,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '33%',
      ),
      const FluentStackedBarDatum(
        legend: 'Metadata2',
        data: 20,
        color: _darkBlue,
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '22%',
      ),
      FluentStackedBarDatum(
        legend: 'Metadata3',
        data: 40,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '45%',
      ),
    ];
    // `thirdChartPoints` (:190-212).
    final thirdChartPoints = <FluentStackedBarDatum>[
      FluentStackedBarDatum(
        legend: 'Metadata1',
        data: 44,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '43%',
      ),
      const FluentStackedBarDatum(
        legend: 'Metadata2',
        data: 28,
        color: _darkBlue,
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '27%',
      ),
      FluentStackedBarDatum(
        legend: 'Metadata3',
        data: 30,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '30%',
      ),
    ];
    // `fourthChartPoints` (:214-236).
    final fourthChartPoints = <FluentStackedBarDatum>[
      FluentStackedBarDatum(
        legend: 'Metadata1',
        data: 88,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color11),
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '63%',
      ),
      const FluentStackedBarDatum(
        legend: 'Metadata2',
        data: 22,
        color: _darkBlue,
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '16%',
      ),
      FluentStackedBarDatum(
        legend: 'Metadata3',
        data: 30,
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '21%',
      ),
    ];

    final supported = FluentDataVizPalette.resolve(FluentDataVizToken.color2);
    final recommended = FluentDataVizPalette.resolve(
      FluentDataVizToken.color17,
    );
    // `data: VerticalStackedChartProps[]` (:238-329). `showLine` starts true,
    // so every `...(showLine && { lineData })` spread is present; the sixth
    // stack has no lineData in the source at all.
    final data = <FluentVerticalStackedBarGroup>[
      FluentVerticalStackedBarGroup(
        chartData: firstChartPoints,
        xAxisPoint: 0,
        lineData: <FluentStackedBarLineDatum>[
          FluentStackedBarLineDatum(
            y: 42,
            legend: 'Supported Builds',
            color: supported,
          ),
          FluentStackedBarLineDatum(
            y: 10,
            legend: 'Recommended Builds',
            color: recommended,
          ),
        ],
      ),
      FluentVerticalStackedBarGroup(
        chartData: secondChartPoints,
        xAxisPoint: 20,
        lineData: <FluentStackedBarLineDatum>[
          FluentStackedBarLineDatum(
            y: 33,
            legend: 'Supported Builds',
            color: supported,
          ),
        ],
      ),
      FluentVerticalStackedBarGroup(
        chartData: thirdChartPoints,
        xAxisPoint: 40,
        lineData: <FluentStackedBarLineDatum>[
          FluentStackedBarLineDatum(
            y: 60,
            legend: 'Supported Builds',
            color: supported,
          ),
          FluentStackedBarLineDatum(
            y: 20,
            legend: 'Recommended Builds',
            color: recommended,
          ),
        ],
      ),
      FluentVerticalStackedBarGroup(
        chartData: firstChartPoints,
        xAxisPoint: 60,
        lineData: <FluentStackedBarLineDatum>[
          FluentStackedBarLineDatum(
            y: 41,
            legend: 'Supported Builds',
            color: supported,
          ),
          FluentStackedBarLineDatum(
            y: 10,
            legend: 'Recommended Builds',
            color: recommended,
          ),
        ],
      ),
      FluentVerticalStackedBarGroup(
        chartData: fourthChartPoints,
        xAxisPoint: 80,
        lineData: <FluentStackedBarLineDatum>[
          FluentStackedBarLineDatum(
            y: 100,
            legend: 'Supported Builds',
            color: supported,
          ),
          FluentStackedBarLineDatum(
            y: 70,
            legend: 'Recommended Builds',
            color: recommended,
          ),
        ],
      ),
      FluentVerticalStackedBarGroup(
        chartData: firstChartPoints,
        xAxisPoint: 100,
      ),
    ];

    await expectReactParity(
      tester,
      'charts-verticalstackedbarchart--vertical-stacked-bar-default',
      FluentVerticalStackedBarChart(
        data: data,
        chartTitle: 'Vertical stacked bar chart basic example',
        culture: 'en-US',
        // `barGapMax` starts at 2 (:35) and `roundCorners` at false (:44).
        barGapMax: 2,
        // `lineOptions={{ lineBorderWidth: '2' }}` (:331) — the only field
        // `_createLines` reads (`VerticalStackedBarChart.tsx:566-568`).
        lineOptions: const FluentLineOptions(lineBorderWidth: 2),
        props: const FluentCartesianChartProps(
          // `showAxisTitles` starts true (:37), so both titles are set and
          // `margins` is the wider of the two sets (:38-43).
          margins: FluentChartMargins(top: 20, bottom: 55, right: 40, left: 60),
          xAxisTitle: 'Number of days',
          yAxisTitle: 'Variation of number of sales',
          roundedTicks: true,
        ),
      ),
      // Measured 0.149% — 316 pixels of 212,435, down from 11.640% (24,727).
      // Three defects closed, all in `vertical_stacked_bar_chart.dart`:
      //
      //   * `_getDomainMargins` (`VerticalStackedBarChart.tsx:913-965`) had no
      //     port at all, so the x scale ran the whole plot, 60..610, where
      //     upstream insets it by `MIN_DOMAIN_MARGIN + _barWidth / 2` = 16 to
      //     76..594 — the exact range Oracle B records for the axis domain
      //     path (`M76.5,6V0.5H594.5V6`). Every stack sat at the wrong x: the
      //     port's centres were 60/170/…/610 against the capture's
      //     76/179.6/…/594.
      //   * The stacks' own y scale was solved from the raw data extent
      //     instead of the resolved axis domain. `_getAxisData` (`:400-406`)
      //     reads `yAxisDomainValues`, which is assigned `yAxisScale.domain()`
      //     (`utilities.ts:889`), so the two differ by whatever
      //     `prepareDatapoints` rounds outward — 140 against 150 here, making
      //     every segment 7% too tall. The delegate now reads the shell's own
      //     `yScalePrimary.domain`.
      //   * `hideLabels` and `yAxisTickFormat` were stored and never read:
      //     `paintSeries` had no label pass, so none of the six stack totals
      //     (100/90/102/100/140/100) was drawn.
      //
      // Bar widths were measured, not assumed: the capture's rects are 16 wide
      // and so are the port's, before and after. Only their x moved.
      //
      // 0.149% since: the trigger defect the VerticalBarChart story above
      // documents — no chevron glyph and no reserved `<Overflow>` padding — was
      // closed in `chrome/legend.dart`. What is left is antialiasing on the two
      // overlay lines and the subpixel trigger edge.
      maxMismatch: 0.18,
    );
  });
}
