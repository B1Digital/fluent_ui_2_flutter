// Pixel parity for the DonutChart stories other than Basic (which lives in
// `donut_and_funnel_parity_test.dart`), against the live
// @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/donut_chart.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/bar_data.dart';
import 'package:fluent_2/src/charts/model/cartesian_series.dart';
import 'package:fluent_2/src/charts/model/chart_common.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

Color _token(FluentDataVizToken token) => FluentDataVizPalette.resolve(token);

void main() {
  setUpAll(loadParityFonts);

  testWidgets('DonutChartCustomAccessibility', (tester) async {
    // `const points` / `const data` in
    // charts-donutchart--donut-chart-custom-accessibility.tsx. The aria labels
    // draw nothing; they are carried so the inputs are the story's.
    final data = FluentChartData(
      chartTitle: 'Donut chart custom accessibility example',
      chartTitleSemantics: const FluentChartSemantics(
        label: 'Bar chart depicting about Donut chart',
      ),
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'first',
          data: 20000,
          color: _token(FluentDataVizToken.color16),
          xAxisCalloutData: '2020/04/30',
          callOutSemantics: const FluentChartSemantics(
            label: 'Pia chart 1 of 2 2020/04/30',
          ),
        ),
        FluentChartDataPoint(
          legend: 'second',
          data: 39000,
          color: _token(FluentDataVizToken.color3),
          xAxisCalloutData: '2020/04/20',
          callOutSemantics: const FluentChartSemantics(
            label: 'Pia chart 2 of 2 2020/04/20',
          ),
        ),
      ],
    );

    await expectReactParity(
      tester,
      'charts-donutchart--donut-chart-custom-accessibility',
      // `href` has no Flutter equivalent and draws nothing. No `culture`: the
      // story passes none, so the centre value uses the default locale.
      FluentDonutChart(
        data: data,
        innerRadius: 55,
        legendsOverflowText: 'overflow Items',
        hideLegend: false,
        height: 220,
        valueInsideDonut: 39000,
      ),
      // Measured 0.096% — 222 of 230,602 px, aligned. 56 are the two legend
      // swatches' outer columns (x 411/425, 471/485, rows 227-240): Chromium
      // pixel-snaps the `fui-legend__rect` div at x 411.39 to 411..424 while
      // Skia antialiases the fractional box, so each swatch gets a 61%/39%
      // column either side. The other 166 are one-to-four-pixel runs on the
      // ring's antialiased outer and inner circles (worst channel delta 54,
      // no systematic radius bias) — rasteriser noise, as in DonutChartBasic.
      maxMismatch: 0.11,
    );
  });

  testWidgets('DonutChartCustomCallout', (tester) async {
    // `const points` / `const data` in
    // charts-donutchart--donut-chart-custom-callout.tsx. `useCustomPopover`
    // starts false and `calloutPropsPerDataPoint` /
    // `onRenderCalloutPerDataPoint` only shape the HOVER popover, which the
    // static capture does not show — the port has neither hook (hover-only
    // gap, invisible here). The `Switch` above the chart is outside the
    // captured box (its label rect sits at y=-36).
    final data = FluentChartData(
      chartTitle: 'Donut chart custom callout example',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'first',
          data: 20000,
          color: _token(FluentDataVizToken.color9),
          xAxisCalloutData: '2020/04/30',
          callOutSemantics: const FluentChartSemantics(
            label: 'Custom XVal Custom Legend 20000h',
          ),
        ),
        FluentChartDataPoint(
          legend: 'second',
          data: 39000,
          color: _token(FluentDataVizToken.color10),
          xAxisCalloutData: '2020/04/20',
          callOutSemantics: const FluentChartSemantics(
            label: 'Custom XVal Custom Legend 39000h',
          ),
        ),
      ],
    );

    await expectReactParity(
      tester,
      'charts-donutchart--donut-chart-custom-callout',
      FluentDonutChart(
        data: data,
        innerRadius: 55,
        legendsOverflowText: 'overflow Items',
        hideLegend: false,
        height: 220,
        valueInsideDonut: 39000,
      ),
      // Measured 0.110% — 253 of 230,535 px, aligned: 56 on the two legend
      // swatches' fractional edge columns (Chromium snaps the div, Skia
      // antialiases it) and 197 of ring-edge antialiasing noise.
      maxMismatch: 0.125,
    );
  });

  testWidgets('DonutChartDynamic', (tester) async {
    // The INITIAL `React.useState` values in
    // charts-donutchart--donut-chart-dynamic.tsx: the 40/20/30/10 data (the
    // `Math.random` paths only run on a button click), hideLabels false,
    // showLabelsInPercent false, innerRadius 35. `legendProps.
    // allowFocusOnLegends` only affects keyboard focus. The checkboxes above
    // and the buttons below are outside the captured box.
    final data = FluentChartData(
      chartTitle: 'Donut chart dynamic example',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'first',
          data: 40,
          color: _token(FluentDataVizToken.color1),
        ),
        FluentChartDataPoint(
          legend: 'second',
          data: 20,
          color: _token(FluentDataVizToken.color2),
        ),
        FluentChartDataPoint(
          legend: 'third',
          data: 30,
          color: _token(FluentDataVizToken.color3),
        ),
        FluentChartDataPoint(
          legend: 'fourth',
          data: 10,
          color: _token(FluentDataVizToken.color4),
        ),
      ],
    );

    await expectReactParity(
      tester,
      'charts-donutchart--donut-chart-dynamic',
      FluentDonutChart(
        data: data,
        innerRadius: 35,
        hideLabels: false,
        showLabelsInPercent: false,
        height: 248,
      ),
      // Measured 0.063% — 163 of 257,301 px, aligned. 84 are swatch edge
      // columns (three of the four swatches sit on fractional x; Chromium
      // snaps them, Skia does not) and 79 ring-edge antialiasing. The four
      // arc labels land inside the reference's text boxes, so they are right.
      maxMismatch: 0.075,
    );
  });

  testWidgets('DonutChartStyled', (tester) async {
    // charts-donutchart--donut-chart-styled.tsx. The `className` rule — a 2px
    // color11 border, `border-radius: 50%`, 10px padding and a `disabled`
    // background — lands on upstream's ROOT, which is `width: 100%` in
    // content-box sizing (`useDonutChartStyles.styles.ts:28-35`). The port has
    // no root-style hook, so the decoration is composed around the chart here,
    // exactly where the browser put it.
    //
    // The capture box is the chartWrapper (Oracle B htmlBoxes: x=36, y=60,
    // 944 wide), so the root's border box is at (-12, -12) in it: 968 wide
    // (944 + 2*12) and 298 tall (to the legend's bottom at 286, plus 12).
    //
    // `_fitParentContainer` (`DonutChart.tsx:290-324`) measures that border
    // box, padding and border included, so upstream's `_width`/`_height` are
    // 968 and 244 rather than the content box and the story's `height: 220`:
    // Oracle B's svg is 968x262 (= 244 + 36/2) with the pie at
    // `translate(484, 122)` and an A104 outer arc = min(968, 244 - 36) / 2.
    // Those solved numbers are passed as `width`/`height`, because the port's
    // chart cannot see a decoration its parent paints.
    final data = FluentChartData(
      chartTitle: 'Donut chart styled example',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'first',
          data: 20000,
          color: _token(FluentDataVizToken.color1),
          xAxisCalloutData: '2020/04/30',
        ),
        FluentChartDataPoint(
          legend: 'second',
          data: 39000,
          color: _token(FluentDataVizToken.color2),
          xAxisCalloutData: '2020/04/20',
        ),
      ],
    );

    await expectReactParity(
      tester,
      'charts-donutchart--donut-chart-styled',
      Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            left: -12,
            top: -12,
            width: 968,
            height: 298,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _token(FluentDataVizToken.disabled),
                border: Border.all(
                  color: _token(FluentDataVizToken.color11),
                  width: 2,
                ),
                // `border-radius: 50%` on a 968x298 box is an ellipse.
                borderRadius: const BorderRadius.all(
                  Radius.elliptical(484, 149),
                ),
              ),
            ),
          ),
          // The legend is laid out in the root's 944 CONTENT box
          // (`fui-legend__root` at x=36, 944 wide) while the svg is 968, so
          // the chart gets the content box and the solved svg width as its
          // `width` prop, overflowing it by 24 exactly as the browser does.
          Positioned(
            left: 0,
            top: 0,
            width: 944,
            child: FluentDonutChart(
              // `window.navigator.language` in the capture browser.
              culture: 'en-US',
              data: data,
              innerRadius: 55,
              legendsOverflowText: 'overflow Items',
              hideLegend: false,
              width: 968,
              height: 244,
              valueInsideDonut: 39000,
            ),
          ),
        ],
      ),
      // Measured 0.131% — 333 of 253,506 px, aligned: 56 swatch edge columns
      // (fractional x, snapped by Chromium only), 254 ring-edge antialiasing
      // and 23 on the antialiased ellipse border and the title's backing-rect
      // corners, which this test composes. Before the chart was given the
      // 944 content box it measured 0.355%: a 968-wide chart centres its
      // legend on 484, 12 px right of upstream's.
      maxMismatch: 0.15,
    );
  });

  testWidgets('DonutChartResponsive', (tester) async {
    // charts-donutchart--donut-chart-responsive.tsx. `ResponsiveContainer`
    // hands the chart its measured box; the port fills its constraints when
    // `width` and `height` are null, which is the same thing. The captured
    // box is 944x230, and the svg is 944x218 — upstream's `_height` 200.
    final data = FluentChartData(
      chartTitle: 'Donut chart basic example',
      chartData: <FluentChartDataPoint>[
        for (final (legend, value, token)
            in <(String, double, FluentDataVizToken)>[
              ('first', 20000, FluentDataVizToken.color1),
              ('second', 39000, FluentDataVizToken.color2),
              ('third', 12000, FluentDataVizToken.color3),
              ('fourth', 2000, FluentDataVizToken.color4),
              ('fifth', 5000, FluentDataVizToken.color5),
              ('sixth', 6000, FluentDataVizToken.color6),
              ('seventh', 7000, FluentDataVizToken.color7),
              ('eighth', 8000, FluentDataVizToken.color8),
              ('ninth', 9000, FluentDataVizToken.color9),
              ('tenth', 10000, FluentDataVizToken.color10),
            ])
          FluentChartDataPoint(
            legend: legend,
            data: value,
            color: _token(token),
            xAxisCalloutData: legend == 'first' ? '2020/04/30' : '2020/04/20',
          ),
      ],
    );

    await expectReactParity(
      tester,
      'charts-donutchart--donut-chart-responsive',
      FluentDonutChart(data: data, innerRadius: 55, valueInsideDonut: 39000),
      // Measured 0.151% — 313 of 207,126 px, aligned. 240 of them (77%) are
      // legend swatch edge columns: ten swatches, most on a fractional x that
      // Chromium snaps to whole pixels and Skia antialiases. The other 73 are
      // ring-edge antialiasing noise; the plot height the port inverts from
      // the 230 box (200, an A82 outer arc) matches Oracle B exactly.
      maxMismatch: 0.17,
    );
  });
}
