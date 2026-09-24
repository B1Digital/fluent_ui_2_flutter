// Pixel parity for HorizontalBarChart, against the live @fluentui/react-charts
// render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`. Nothing here is
// invented or rounded: a chart fed different data than the reference is a
// comparison of two different pictures. No story passes a style.
//
// `charts-horizontalbarchart--horizontal-bar-basic` lives in
// `horizontal_bar_and_heat_map_parity_test.dart`.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/chrome/legend.dart';
import 'package:fluent_2/src/charts/horizontal_bar_chart.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/bar_data.dart';
import 'package:fluent_2/src/charts/model/cartesian_series.dart';
import 'package:fluent_2/src/charts/model/chart_common.dart';
import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

/// One single-point row: `chartTitle` and `legend` are the same string in
/// every story that uses this shape.
FluentChartData _row(
  String title,
  double x,
  double total,
  FluentDataVizToken token, {
  double? benchmark,
  String? xAxisCalloutData,
  String? yAxisCalloutData,
  String? titleLabel,
  String? dataLabel,
  String? calloutLabel,
}) => FluentChartData(
  chartTitle: title,
  chartTitleSemantics: titleLabel == null
      ? null
      : FluentChartSemantics(label: titleLabel),
  chartDataSemantics: dataLabel == null
      ? null
      : FluentChartSemantics(label: dataLabel),
  chartData: <FluentChartDataPoint>[
    FluentChartDataPoint(
      legend: title,
      data: benchmark,
      horizontalBarChartData: FluentHorizontalDataPoint(x: x, total: total),
      color: FluentDataVizPalette.resolve(token),
      xAxisCalloutData: xAxisCalloutData,
      yAxisCalloutData: yAxisCalloutData,
      callOutSemantics: calloutLabel == null
          ? null
          : FluentChartSemantics(label: calloutLabel),
    ),
  ],
);

/// One segment of a stacked row: no `total`, so no placeholder is synthesised.
FluentChartDataPoint _segment(String legend, double x, FluentDataVizToken t) =>
    FluentChartDataPoint(
      legend: legend,
      horizontalBarChartData: FluentHorizontalDataPoint(x: x),
      color: FluentDataVizPalette.resolve(t),
    );

void main() {
  setUpAll(loadParityFonts);

  testWidgets('HorizontalBarAbsoluteScale', (tester) async {
    // `const data: ChartProps[]` in
    // charts-horizontalbarchart--horizontal-bar-absolute-scale.tsx.
    // `hideLabels` is `React.useState(false)`; the checkbox sits outside the
    // captured box.
    final data = <FluentChartData>[
      _row('one', 1543, 15000, FluentDataVizToken.color17),
      _row('two', 800, 15000, FluentDataVizToken.color18),
      _row('three', 8888, 15000, FluentDataVizToken.color19),
      _row('four', 15888, 15000, FluentDataVizToken.color20),
      _row('five', 11444, 15000, FluentDataVizToken.color21),
      _row('six', 14000, 15000, FluentDataVizToken.color22),
      _row('seven', 9855, 15000, FluentDataVizToken.color23),
      _row('eight', 4250, 15000, FluentDataVizToken.color24),
    ];

    await expectReactParity(
      tester,
      'charts-horizontalbarchart--horizontal-bar-absolute-scale',
      FluentHorizontalBarChart(
        data: data,
        variant: FluentHorizontalBarChartVariant.absoluteScale,
      ),
      // Measured 0.006% — 13 of 214,363 px, aligned, and none of them is a
      // bar. All 13 are the trailing edges of two bar labels poking out of
      // their masks, "11.4k" (11 px) and "1.5k" (2 px): caption1Strong is
      // weight 600, which Selawik Semibold sets wider than Segoe UI Semibold
      // (see `support/react_parity.dart`). No row carries a remainder bar,
      // so the #36 row-fit departure does not show here. Was 0.136% while
      // the eight row titles had no textRect; the capture's text-node pass
      // now masks them.
      maxMismatch: 0.01,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('HorizontalBarBenchmark', (tester) async {
    // `const data: ChartProps[]` in
    // charts-horizontalbarchart--horizontal-bar-benchmark.tsx. `data` on each
    // point is the benchmark. `hideRatio={[true, false]}` has no port and no
    // effect upstream either: HorizontalBarChart.tsx never reads it (it exists
    // only at HorizontalBarChart.types.ts:36). The story does NOT pass
    // `showTriangle`, so the rows keep the 10px gap — the box is
    // 3 x (21 + 3 + 12) + 2 x 10 = 128.
    final data = <FluentChartData>[
      _row('one', 10, 100, FluentDataVizToken.color25, benchmark: 50),
      _row('two', 30, 200, FluentDataVizToken.color26, benchmark: 30),
      _row('three', 15, 50, FluentDataVizToken.color27, benchmark: 5),
    ];

    await expectReactParity(
      tester,
      'charts-horizontalbarchart--horizontal-bar-benchmark',
      FluentHorizontalBarChart(
        data: data,
        chartDataMode: FluentChartDataMode.fraction,
      ),
      // Measured 0.099% — 72 of 72,490 px, aligned, and every one is the
      // deliberate #36 row-fit departure (31eef6d): upstream's bars fill the
      // row and its 3px gap pushes the remainder bar past the svg, where the
      // port fits both bars and the gap inside the row, so each row's gap
      // lands a column or two left — two 12px columns per row. The triangles
      // and bars are otherwise exact. Was 0.428% while the row titles were
      // unmasked and the three triangles sat 3px low, under the bar
      // (`.triangle` is absolutely positioned above the svg upstream,
      // useHorizontalBarChartStyles.styles.ts:78-93; fixed in d89c3d2).
      maxMismatch: 0.1,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('HorizontalBarCustomAccessibility', (tester) async {
    // `const data: ChartProps[]` in
    // charts-horizontalbarchart--horizontal-bar-custom-accessibility.tsx. The
    // three `{ ariaLabel }` bags are `FluentChartSemantics(label:)` on the
    // same three slots; none of them paints.
    final data = <FluentChartData>[
      for (final (title, x, token, date, pct)
          in <(String, double, FluentDataVizToken, String, String)>[
            ('one', 1543, FluentDataVizToken.color9, '2021/06/10', '10%'),
            ('two', 800, FluentDataVizToken.color10, '2021/06/11', '5%'),
            ('three', 8888, FluentDataVizToken.color11, '2021/06/12', '59%'),
            ('four', 15888, FluentDataVizToken.color12, '2021/06/13', '105%'),
            ('five', 11444, FluentDataVizToken.color13, '2021/06/14', '76%'),
            ('six', 14000, FluentDataVizToken.color14, '2021/06/15', '93%'),
            ('seven', 9855, FluentDataVizToken.color15, '2021/06/16', '65%'),
            ('eight', 4250, FluentDataVizToken.color16, '2021/06/17', '28%'),
          ])
        _row(
          title,
          x,
          15000,
          token,
          xAxisCalloutData: date,
          yAxisCalloutData: pct,
          titleLabel: 'Bar chart depicting about $title',
          dataLabel: 'Data ${x.toInt()} of 15000',
          calloutLabel: 'Bar series 1 of chart $title $date $pct',
        ),
    ];

    await expectReactParity(
      tester,
      'charts-horizontalbarchart--horizontal-bar-custom-accessibility',
      FluentHorizontalBarChart(data: data),
      // Measured 0.171% — 325 of 190,598 px, identical to horizontal-bar-basic,
      // which has the same geometry: 319 px are the bar gaps of the
      // deliberate #36 row-fit departure (31eef6d; see that story) and 6 the
      // leading edge of "11,444" (weight 600) poking out of its mask. The
      // `shift(-2,0)` diagnostic is those moved gaps, not a layout offset.
      // Was 0.313% while the row titles were compared unmasked (283 px).
      maxMismatch: 0.18,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('HorizontalBarCustomCallout', (tester) async {
    // `const data: ChartProps[]` in
    // charts-horizontalbarchart--horizontal-bar-custom-callout.tsx.
    // `calloutPropsPerDataPoint` and `onRenderCalloutPerHorizontalBar` shape
    // the hover popover only, which no screenshot has open, so they are not
    // passed here; the port takes both as `calloutPropsPerDataPoint`, whose
    // `customContentBuilder` replaces the body. `hideRatio` is dead upstream
    // (see the benchmark story).
    // The `Switch` above the chart is outside the captured box.
    final data = <FluentChartData>[
      for (final (title, x, token, y)
          in <(String, double, FluentDataVizToken, String)>[
            ('one', 1543, FluentDataVizToken.color28, '1.5K'),
            ('two', 800, FluentDataVizToken.color29, '800'),
            ('three', 8888, FluentDataVizToken.color30, '8.8K'),
            ('four', 15888, FluentDataVizToken.color31, '16K'),
            ('five', 11444, FluentDataVizToken.color32, '11K'),
            ('six', 14000, FluentDataVizToken.color33, '14K'),
            ('seven', 9855, FluentDataVizToken.color34, '9.9K'),
            ('eight', 4250, FluentDataVizToken.color35, '4.3K'),
          ])
        _row(
          title,
          x,
          15000,
          token,
          xAxisCalloutData: '2020/04/30',
          yAxisCalloutData: y,
        ),
    ];

    await expectReactParity(
      tester,
      'charts-horizontalbarchart--horizontal-bar-custom-callout',
      FluentHorizontalBarChart(data: data),
      // Measured 0.171% — 325 of 190,443 px, the same geometry and residual as
      // the accessibility story: 319 px of #36 row-fit bar gaps (deliberate,
      // 31eef6d) and 6 px of the "11,444" leading edge. Was 0.314% while the
      // row titles were compared unmasked.
      maxMismatch: 0.18,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('HorizontalBarStacked', (tester) async {
    // `const data` in charts-horizontalbarchart--horizontal-bar-stacked.tsx.
    // `chartDataMode={'default'}`; `className` carries no rule.
    final data = <FluentChartData>[
      FluentChartData(
        chartTitle: 'one',
        chartData: <FluentChartDataPoint>[
          _segment('One.One', 1543, FluentDataVizToken.color1),
          _segment('One.Two', 1000, FluentDataVizToken.color2),
          _segment('One.Three', 547, FluentDataVizToken.color3),
        ],
      ),
      FluentChartData(
        chartTitle: 'two',
        chartData: <FluentChartDataPoint>[
          _segment('Two.One', 987, FluentDataVizToken.color4),
          _segment('Two.Two', 1987, FluentDataVizToken.color5),
        ],
      ),
      FluentChartData(
        chartTitle: 'three',
        chartData: <FluentChartDataPoint>[
          _segment('Three.One', 872, FluentDataVizToken.color6),
          _segment('Three.Two', 128, FluentDataVizToken.color7),
        ],
      ),
    ];

    await expectReactParity(
      tester,
      'charts-horizontalbarchart--horizontal-bar-stacked',
      FluentHorizontalBarChart(data: data),
      // Measured 0.391% — 379 of 96,925 px, aligned. 312 are the 3px gaps
      // between segments, moved left by the deliberate #36 row-fit departure
      // (31eef6d): upstream lets each row overflow the svg, the port fits
      // every segment and gap inside it. 56 are the One.Two and Two.Two
      // swatches, each one column left of the capture's: both sides snap the
      // swatch to the rounded pixel, but the fractional x the Selawik labels
      // leave falls on the other side of .5 from Segoe UI's. 10 are the
      // "+2 more" chevron, a fraction of a column right behind the wider
      // Selawik Semibold label, and 1 the leading edge of "1000". Was 1.089%
      // while the row titles and the "+2 more" label were unmasked and every
      // swatch had two antialiased edge columns (61c1a1c).
      maxMismatch: 0.4,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('HorizontalBarStackedAnnotatedInlineLegend', (tester) async {
    // `dataTemplate` in
    // charts-horizontalbarchart--horizontal-bar-stacked-annotated-inline-legend
    // .tsx: one chart per entry, stacked in a plain div, each with
    // `hideTooltip`, `chartDataMode="hidden"` and
    // `showLegendForSinglePointBar`, and a `legendProps` built below.
    final dataTemplate = <FluentChartData>[
      FluentChartData(
        chartTitle: 'one',
        chartData: <FluentChartDataPoint>[
          _segment('One.One', 100, FluentDataVizToken.color1),
        ],
      ),
      FluentChartData(
        chartTitle: 'two',
        chartData: <FluentChartDataPoint>[
          _segment('Two.One', 66, FluentDataVizToken.color10),
          _segment('Two.Two', 33, FluentDataVizToken.color20),
        ],
      ),
    ];

    await expectReactParity(
      tester,
      'charts-horizontalbarchart--horizontal-bar-stacked-annotated-inline-legend',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final bar in dataTemplate)
            FluentHorizontalBarChart(
              data: <FluentChartData>[bar],
              hideTooltip: true,
              chartDataMode: FluentChartDataMode.hidden,
              showLegendForSinglePointBar: true,
              // `legendProps: { enabledWrapLines: true, legends }`, each
              // legend carrying the story's AnnotationPopover: a `{value}%`
              // span and a 16x16 button round CursorClickFilled at 1em of the
              // UA's 13.333px button font, in a 4px-gap flex row. The button
              // sets no colour, so the icon's currentColor is the UA's
              // `buttontext`, black (the capture reads #000000).
              enabledWrapLines: true,
              legends: <FluentChartLegendItem>[
                for (final point in bar.chartData!)
                  FluentChartLegendItem(
                    title: point.legend!,
                    color: point.color!,
                    annotationBuilder: (context) => Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: <Widget>[
                        Text(
                          '${point.horizontalBarChartData!.x.round()}%',
                          style: FluentTheme.of(context).typography.body1,
                        ),
                        const SizedBox.square(
                          dimension: 16,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Icon(
                              FluentIcons.cursor_click_20_filled,
                              size: 40 / 3,
                              color: Color(0xFF000000),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      // Measured 0.141% — 160 of 113,365 px, aligned. 112 are the three
      // cursor icons' outlines: the port draws fluentui_system_icons' font
      // glyph where upstream rasterises @fluentui/react-icons' SVG path, so
      // the rays and the arrow's antialiased edge differ by a pixel. 48 are
      // chart two's gap between Two.One and Two.Two, the deliberate #36
      // row-fit departure (31eef6d); the annotation text is masked. Was
      // 10.433% before the chart took `legendProps` (d89c3d2): the port drew
      // its own centred overflow legend, 8px shorter and unannotated. With
      // the icon in neutralForeground1 (#242424) rather than the button's
      // black it measured 0.158%.
      maxMismatch: 0.15,
    );
    expect(tester.takeException(), isNull);
  });
}
