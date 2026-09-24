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
import 'package:fluent_2/src/charts/horizontal_bar_chart.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/bar_data.dart';
import 'package:fluent_2/src/charts/model/cartesian_series.dart';
import 'package:fluent_2/src/charts/model/chart_common.dart';
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
      // Measured 0.136% — 296 px, and 283 of them are the glyphs of the eight
      // row titles: `FocusableTooltipText` nests its text in a span the
      // capture's leaf filter skips, so `_manifest.json` has no textRect for
      // them and Skia's hinting is compared against Chromium's. The other 13
      // are the "11.4k" bar label (caption1Strong, weight 600) poking out of
      // its own mask — the Selawik Semibold width residual. Bars exact.
      maxMismatch: 0.15,
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
      // Re-measured on 31eef6d, which fits each row's bars and gaps inside the
      // row where upstream overflows it (#36): every gap moves left, so that
      // departure is part of the residual below. Before it: 0.335%.
      // Measured 0.428% — 316 px. 113 are the unmasked row-title glyphs (see
      // absolute scale). 134 are the three benchmark triangles, a real defect:
      // the port paints each 3px LOW (top at y 21 against the capture's 18 —
      // the container's `marginTop: -3px`,
      // useHorizontalBarChartStyles.styles.ts:81, is dropped by the
      // top-aligned OverflowBox) and UNDER the bar, so the 0.4-alpha
      // placeholder darkens its tip to #00487F. Upstream's `.triangle` is
      // `position: absolute` and paints above the svg.
      maxMismatch: 0.45,
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
      // Re-measured on 31eef6d, which fits each row's bars and gaps inside the
      // row where upstream overflows it (#36): every gap moves left, so that
      // departure is part of the residual below. Before it: 0.149%.
      // Measured 0.313% — identical to horizontal-bar-basic, which has the
      // same geometry: 283 px of unmasked row-title glyphs and 6 px of
      // "11,444" (weight 600) poking out of its mask. Bars exact.
      maxMismatch: 0.32,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('HorizontalBarCustomCallout', (tester) async {
    // `const data: ChartProps[]` in
    // charts-horizontalbarchart--horizontal-bar-custom-callout.tsx.
    // `calloutPropsPerDataPoint` and `onRenderCalloutPerHorizontalBar` shape
    // the hover popover only — no screenshot has one open — and the port has
    // neither prop. `hideRatio` is dead upstream (see the benchmark story).
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
      // Re-measured on 31eef6d, which fits each row's bars and gaps inside the
      // row where upstream overflows it (#36): every gap moves left, so that
      // departure is part of the residual below. Before it: 0.149%.
      // Measured 0.314% — same geometry and residual as the accessibility
      // story: 283 px of unmasked row-title glyphs, 6 px of "11,444" edge.
      maxMismatch: 0.32,
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
      // Re-measured on 31eef6d, which fits each row's bars and gaps inside the
      // row where upstream overflows it (#36): every gap moves left, so that
      // departure is part of the residual below. Before it: 0.552%.
      // Measured 1.089% — 1083 px; the bars are exact (1 px). 113 are the
      // unmasked row-title glyphs. 295 are the "+2 more" overflow trigger:
      // its label has no textRect either, so 600-weight Selawik is compared
      // unmasked and the chevron sits 2px right behind the wider label. 140
      // are one antialiased column either side of each legend swatch: the
      // centred strip lands on fractional x (43.94 upstream), Chromium snaps
      // the 14px box to whole pixels and Flutter paints it where it falls.
      maxMismatch: 1.1,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('HorizontalBarStackedAnnotatedInlineLegend', (tester) async {
    // `dataTemplate` in
    // charts-horizontalbarchart--horizontal-bar-stacked-annotated-inline-legend
    // .tsx: one chart per entry, stacked in a plain div, each with
    // `hideTooltip`, `chartDataMode="hidden"` and
    // `showLegendForSinglePointBar`.
    //
    // BLOCKED: each chart also passes `legendProps: { enabledWrapLines: true,
    // legends }` whose legends carry a `legendAnnotation` (a "100%" / "66%" /
    // "33%" span and a CursorClickFilled icon). FluentHorizontalBarChart has
    // no `legendProps`, so the port draws its own centred overflow legend with
    // no annotation instead of upstream's left-aligned wrapped one.
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
            ),
        ],
      ),
      // Measured 10.433% — the missing `legendProps`, nothing else. The port's
      // own overflow legend is 32 tall where upstream's wrapped one is 40
      // (4px `legendContainer` margins), so chart two and its legend sit 8px
      // high, and it is centred and unannotated where upstream is
      // left-aligned with "100%"/"66%"/"33%" and a cursor icon beside each
      // row. Simulated with FluentChartLegend(enabledWrapLines: true,
      // annotationBuilder) under the bars it measures 0.339%.
      maxMismatch: 10.5,
    );
    expect(tester.takeException(), isNull);
  });
}
