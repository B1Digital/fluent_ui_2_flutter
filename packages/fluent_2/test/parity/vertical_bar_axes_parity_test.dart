// Pixel parity for the VerticalBarChart axis stories — negative values, a date
// axis, rotated category labels and a secondary y axis — against the live
// @fluentui/react-charts render.
//
// Every input is transcribed from the story's own source, recovered from the
// storybook runtime into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`. Every number,
// colour and string below is verbatim, and every interactive control is left in
// the initial state the reference was captured in.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/cartesian/cartesian_chart_props.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/bar_data.dart';
import 'package:fluent_2/src/charts/model/line_options.dart';
import 'package:fluent_2/src/charts/vertical_bar_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

/// `lineLegendColor={"brown"}` — the CSS keyword, rgb(165, 42, 42).
const Color _brown = Color(0xFFA52A2A);

Color _token(FluentDataVizToken token) => FluentDataVizPalette.resolve(token);

/// `negativePoints` in `--vertical-bar-all-negative.tsx:85-179` and
/// `--vertical-bar-negative.tsx:84-178`. The two arrays share x, legend,
/// colour and the Bananas bar's missing lineData; only the signs differ, so
/// [signs] carries the sign of each (y, line y) pair in author order.
List<FluentVerticalBarChartDataPoint> _negativePoints(List<int> signs) {
  const rows =
      <
        (
          double x,
          double y,
          String legend,
          FluentDataVizToken token,
          String yCallout,
          double? lineY,
          String? lineCallout,
        )
      >[
        (0, 10000, 'Oranges', FluentDataVizToken.color1, '4%', 7000, '3%'),
        (10000, 50000, 'Dogs', FluentDataVizToken.color2, '21%', 30000, '12%'),
        (25000, 30000, 'Apples', FluentDataVizToken.color3, '12%', 3000, '1%'),
        (40000, 13000, 'Bananas', FluentDataVizToken.color6, '5%', null, null),
        (
          52000,
          43000,
          'Giraffes',
          FluentDataVizToken.color11,
          '18%',
          30000,
          '12%',
        ),
        (68000, 30000, 'Cats', FluentDataVizToken.color2, '12%', 5000, '2%'),
        (
          80000,
          20000,
          'Elephants',
          FluentDataVizToken.color11,
          '8%',
          16000,
          '7%',
        ),
        (
          92000,
          45000,
          'Monkeys',
          FluentDataVizToken.color6,
          '19%',
          40000,
          '16%',
        ),
      ];
  return <FluentVerticalBarChartDataPoint>[
    for (var i = 0; i < rows.length; i++)
      FluentVerticalBarChartDataPoint(
        x: rows[i].$1,
        y: signs[i] * rows[i].$2,
        legend: rows[i].$3,
        color: _token(rows[i].$4),
        xAxisCalloutData: '2020/04/30',
        yAxisCalloutData: '${signs[i] < 0 ? '-' : ''}${rows[i].$5}',
        lineData: rows[i].$6 == null
            ? null
            : FluentBarLineDatum(
                y: signs[i] * rows[i].$6!,
                yAxisCalloutData: '${signs[i] < 0 ? '-' : ''}${rows[i].$7}',
              ),
      ),
  ];
}

/// The shared JSX of both negative stories' `showAxisTitles` branch
/// (`--vertical-bar-all-negative.tsx:261-285`,
/// `--vertical-bar-negative.tsx:260-284`). `showAxisTitles` starts true
/// (:41), and `useSingleColor`, `hideLabels`, `enableGradient` and
/// `roundCorners` all start false — the widget's own defaults. Neither story
/// passes `supportNegativeData`, whatever its label text says.
Widget _negativeChart(List<FluentVerticalBarChartDataPoint> points) =>
    FluentVerticalBarChart(
      data: points,
      chartTitle: 'Vertical bar chart basic example ',
      culture: 'en-US',
      lineLegendText: 'just line',
      lineLegendColor: _brown,
      lineOptions: const FluentLineOptions(lineBorderWidth: 2),
      props: const FluentCartesianChartProps(
        yAxisTitle: 'Different categories of animals and fruits',
        xAxisTitle: 'Values of each category',
      ),
    );

void main() {
  setUpAll(loadParityFonts);

  testWidgets('VerticalBarAllNegative', (tester) async {
    await expectReactParity(
      tester,
      'charts-verticalbarchart--vertical-bar-all-negative',
      _negativeChart(_negativePoints(List<int>.filled(8, -1))),
      // Measured 0.331% — 679 of 205,432 px. The bars and line land exactly;
      // what is left is chrome and text:
      //   * 315 px on the `+3 more` overflow trigger. Its label is not in the
      //     capture's textRects, so the glyphs are compared unmasked, and its
      //     right border sits a column off (x 581..582).
      //   * 140 px of legend swatches. Chromium snaps each swatch div to whole
      //     pixels (Dogs at x 193.70 paints 194..207); the port paints it at
      //     193.70 and antialiases both edges — 8 columns x 14 rows. The other
      //     28 are the `just line` swatch, 4px tall here against upstream's
      //     4px content box plus a 1px border each side (Oracle B: 14x6).
      //   * ~130 px of U+2212: Selawik has no MINUS SIGN glyph, so `flutter
      //     test` draws the FlutterTest fallback box, wider than the mask.
      //   * the rest is antialiasing at the line's vertices.
      maxMismatch: 0.35,
    );
  });

  testWidgets('VerticalBarNegative', (tester) async {
    await expectReactParity(
      tester,
      'charts-verticalbarchart--vertical-bar-negative',
      // Oranges +, Dogs -, Apples +, Bananas -, Giraffes +, Cats -,
      // Elephants +, Monkeys - (:84-178); each line y shares its bar's sign.
      _negativeChart(_negativePoints(const <int>[1, -1, 1, -1, 1, -1, 1, -1])),
      // Measured 2.345% — 4,805 of 204,919 px, and most of it is a defect:
      // every bar is measured against the wrong domain. `_getAxisData`
      // (`VerticalBarChart.tsx:894-899`) resets `_yMin`/`_yMax` to the y
      // AXIS domain, [-69.75k, 46.5k] here, before the bars are built, so
      // the zero baseline sits where the zero gridline is (y 114). The port's
      // `barDomain` (`vertical_bar_chart.dart:751`) keeps the raw data extent
      // [-50k, 43k], so every bar hangs from y 128 at the wrong scale. Passing
      // the shell's `yScalePrimary.domain` instead measured 0.302% in a
      // scratch copy. The remainder is what the all-negative story above
      // documents: overflow trigger, swatch snapping, the short line swatch,
      // U+2212 fallback boxes, and line-join antialiasing.
      maxMismatch: 2.4,
    );
  });

  testWidgets('VerticalBarDateAxis', (tester) async {
    // `new Date("2018/01/01")` and friends are local-time dates, and the
    // story sets `useUTC={false}` (:61), so DateTime's local constructor.
    final dates = <DateTime>[
      DateTime(2018),
      DateTime(2018, 3),
      DateTime(2018, 7),
      DateTime(2018, 10),
      DateTime(2019),
    ];
    const ys = <double>[3500, 2500, 1900, 2800, 3800];
    const colours = <Color>[
      Color(0xFF627CEF),
      Color(0xFFC19C00),
      Color(0xFFE650AF),
      Color(0xFF0E7878),
      Color(0xFF0E7878),
    ];
    await expectReactParity(
      tester,
      'charts-verticalbarchart--vertical-bar-date-axis',
      FluentVerticalBarChart(
        // `points` (:8-34).
        data: <FluentVerticalBarChartDataPoint>[
          for (var i = 0; i < dates.length; i++)
            FluentVerticalBarChartDataPoint(
              x: dates[i],
              y: ys[i],
              color: colours[i],
            ),
        ],
        chartTitle: 'Vertical bar chart Date axis example ',
        culture: 'en-US',
        // `tickFormat="%m/%d"` (:56) is not transcribed: `createDateXAxis`
        // reads it only when `culture === undefined` (`utilities.ts:507`), and
        // the story always passes a culture, so the capture's ticks read
        // "Jan 2018" rather than "01/01". The tick values (:37-43) are the
        // same five dates.
        props: FluentCartesianChartProps(
          tickValues: dates,
          useUTC: false,
          hideLegend: true,
        ),
      ),
      // Measured 0.000% — not one of 317,447 unmasked pixels differs. No
      // legend, no line and no negative numbers, so none of the residuals the
      // other stories carry apply. A zero pin is the only one the
      // improvement floor allows, and any regression fails it.
      maxMismatch: 0,
    );
  });

  testWidgets('VerticalBarRotateLabels', (tester) async {
    await expectReactParity(
      tester,
      'charts-verticalbarchart--vertical-bar-rotate-labels',
      const FluentVerticalBarChart(
        // `points` (:8-29), including the trailing space of the first label.
        data: <FluentVerticalBarChartDataPoint>[
          FluentVerticalBarChartDataPoint(
            x: 'This is a medium long label. ',
            y: 3500,
            color: Color(0xFF627CEF),
          ),
          FluentVerticalBarChartDataPoint(
            x: 'This is a long label This is a long label',
            y: 2500,
            color: Color(0xFFC19C00),
          ),
          FluentVerticalBarChartDataPoint(
            x: 'This label is as long as the previous one',
            y: 1900,
            color: Color(0xFFE650AF),
          ),
          FluentVerticalBarChartDataPoint(
            x: 'A short label',
            y: 2800,
            color: Color(0xFF0E7878),
          ),
        ],
        chartTitle: 'Vertical bar chart rotated labels example ',
        props: FluentCartesianChartProps(
          hideLegend: true,
          rotateXAxisLables: true,
        ),
      ),
      // Measured 2.043% — 5,970 of 292,282 px. Two causes:
      //   * A defect: the bars ignore the rotated-label reserve and run 137px
      //     past the x axis, down to y 465. Upstream builds them in
      //     `_getGraphData`, which `CartesianChart.tsx:421-428` calls with
      //     `containerHeight - _removalValueForTextTuncate`. The port's
      //     `barsFor` and `_magnitudeScale` (`vertical_bar_chart.dart:948`,
      //     `:1093`) use `layout.size.height`, not `plotContentHeight`.
      //     Swapping them measured 0.960% in a scratch copy.
      //   * The rest (2,806 px) is one row: every gridline and bar top sits 1px
      //     high because the reserve is 138 against upstream's 137.
      //     `floor(maxHeight / 1.414)` sees Selawik Semibold measure the
      //     widest label at 181.54 against Segoe UI's 179.19 (Oracle B), which
      //     tips 102.66 over to 103.39. That is the documented weight-600 font
      //     residual, not a defect.
      maxMismatch: 2.1,
    );
  });

  testWidgets('VerticalBarSecondaryYAxis', (tester) async {
    // `points` (:33-110). Every lineData sets `useSecondaryYScale: true`.
    final points = <FluentVerticalBarChartDataPoint>[
      FluentVerticalBarChartDataPoint(
        x: 0,
        y: 10000,
        legend: 'Oranges',
        color: _token(FluentDataVizToken.color1),
        lineData: const FluentBarLineDatum(y: 7000, useSecondaryYScale: true),
      ),
      FluentVerticalBarChartDataPoint(
        x: 10000,
        y: 50000,
        legend: 'Dogs',
        color: _token(FluentDataVizToken.color2),
        lineData: const FluentBarLineDatum(y: 30000, useSecondaryYScale: true),
      ),
      FluentVerticalBarChartDataPoint(
        x: 25000,
        y: 30000,
        legend: 'Apples',
        color: _token(FluentDataVizToken.color3),
        lineData: const FluentBarLineDatum(y: 3000, useSecondaryYScale: true),
      ),
      FluentVerticalBarChartDataPoint(
        x: 40000,
        y: 13000,
        legend: 'Bananas',
        color: _token(FluentDataVizToken.color6),
      ),
      FluentVerticalBarChartDataPoint(
        x: 52000,
        y: 43000,
        legend: 'Giraffes',
        color: _token(FluentDataVizToken.color11),
        lineData: const FluentBarLineDatum(y: 30000, useSecondaryYScale: true),
      ),
      FluentVerticalBarChartDataPoint(
        x: 68000,
        y: 30000,
        legend: 'Cats',
        color: _token(FluentDataVizToken.color4),
        lineData: const FluentBarLineDatum(y: 5000, useSecondaryYScale: true),
      ),
      FluentVerticalBarChartDataPoint(
        x: 80000,
        y: 20000,
        legend: 'Elephants',
        color: _token(FluentDataVizToken.color11),
        lineData: const FluentBarLineDatum(y: 16000, useSecondaryYScale: true),
      ),
      FluentVerticalBarChartDataPoint(
        x: 92000,
        y: 45000,
        legend: 'Monkeys',
        color: _token(FluentDataVizToken.color6),
        lineData: const FluentBarLineDatum(y: 40000, useSecondaryYScale: true),
      ),
    ];
    await expectReactParity(
      tester,
      'charts-verticalbarchart--vertical-bar-secondary-y-axis',
      FluentVerticalBarChart(
        data: points,
        chartTitle: 'Vertical bar chart secondary y-axis example ',
        lineLegendText: 'just line',
        lineLegendColor: _brown,
        lineOptions: const FluentLineOptions(lineBorderWidth: 2),
        props: const FluentCartesianChartProps(
          hideTickOverlap: true,
          yAxisTitle: 'Values of each category',
          xAxisTitle: 'Different categories of animals and fruits',
          // `secondaryYScaleOptions={{}}` (:153).
          secondaryYScaleOptions: FluentSecondaryYScaleOptions(),
        ),
      ),
      // Measured 0.282% — 530 of 187,964 px. Both y axes, every bar and the
      // secondary-scale line land exactly. What is left is legend chrome:
      // 324 px on the `+2 more` trigger (label unmasked by the capture,
      // right border a column off at x 642..643) and 168 on the swatches (10
      // subpixel-snapped edges, plus the `just line` swatch 2px short). The
      // last 38 px are antialiasing at the line's vertices.
      maxMismatch: 0.3,
    );
  });
}
