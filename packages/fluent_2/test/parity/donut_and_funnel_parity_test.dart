// Pixel parity for DonutChart and FunnelChart, against the live
// @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/donut_chart.dart';
import 'package:fluent_2/src/charts/funnel_chart.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/bar_data.dart';
import 'package:fluent_2/src/charts/model/cartesian_series.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

void main() {
  setUpAll(loadParityFonts);

  testWidgets('DonutChartBasic', (tester) async {
    // `const points` in charts-donutchart--donut-chart-basic.tsx.
    final data = FluentChartData(
      chartTitle: 'Donut chart basic example',
      chartData: <FluentChartDataPoint>[
        FluentChartDataPoint(
          legend: 'first',
          data: 20000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
          xAxisCalloutData: '2020/04/30',
        ),
        FluentChartDataPoint(
          legend: 'second',
          data: 35000,
          color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
          xAxisCalloutData: '2020/04/20',
        ),
      ],
    );

    await expectReactParity(
      tester,
      'charts-donutchart--donut-chart-basic',
      FluentDonutChart(
        data: data,
        innerRadius: 55,
        hideLegend: false,
        height: 220,
        valueInsideDonut: 35000,
        legendsOverflowText: 'overflow Items',
        // `window.navigator.language` in the capture browser. `href` has no
        // Flutter equivalent and draws nothing.
        culture: 'en-US',
      ),
      // Measured 0.086% — 199 of 230,866 unmasked px, aligned, all of it
      // rasteriser noise on the ring's antialiased edges (below). Was 0.110%
      // while the two legend swatches were painted at their fractional x
      // (56 px of antialiased edge columns) where Chromium snaps them to whole
      // pixels (61c1a1c), and 5.701% (13,162 px) before that, while the title
      // band was charged twice: `build` stacked `FluentChartTitle` above the
      // plot as a Column child, which cost 22 px of flow that upstream never
      // spends, so the ring sat 22 px low (top y=40 against the capture's 18)
      // in a band 180 px tall instead of 202 and its bottom was amputated at
      // y=201.
      //
      // Upstream pays for the band exactly once, into the radius
      // (`DonutChart.tsx:335`, `(220 - 36) / 2 = 92`, which was already right).
      // The title itself is an SVG `<text>` at `y={0}` INSIDE the svg
      // (`:360-370`, and `ChartTitle.tsx:80` keeps a given y), so it consumes
      // no flow and paints above the component: the manifest's first textRect
      // is y=-11 h=14 and only its descenders are in the picture. The svg is
      // `_height + titleHeight / 2` = 238 tall (`:358`) — this story's own
      // `svgSize` — and `:421` pulls the legend container up by a whole
      // `titleHeight`, netting a 202-px plot band, which is what the port now
      // lays out. The Oracle B capture pins every number of it: chartWrapper
      // 944x238 at page y=48, `fui-legend__root` at y=266, `translate(472,
      // 110)` on the pie.
      //
      // The residual is on the ring's outer and inner circles — one to six
      // pixels per spot, rows 18-201 only. The three ink bands are identical
      // in both images: rows 0-2 (title descenders), 18-201 (ring) and
      // 227-240 (legend, swatches exact), x 380-563.
      maxMismatch: 0.09,
    );
  });

  testWidgets('FunnelChartBasic', (tester) async {
    // `const basicData` in charts-funnelchart--funnel-chart-basic.tsx, with
    // every control at its initial state: width 600, height 500, hideLegend
    // false, orientation horizontal, legendMultiSelect false.
    await expectReactParity(
      tester,
      'charts-funnelchart--funnel-chart-basic',
      FluentFunnelChart(
        data: <FluentFunnelDataPoint>[
          FluentFunnelDataPoint(
            stage: 'Visitors',
            value: 1000,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
          ),
          FluentFunnelDataPoint(
            stage: 'Signups',
            value: 600,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color6),
          ),
          FluentFunnelDataPoint(
            stage: 'Trials',
            value: 300,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color10),
          ),
          FluentFunnelDataPoint(
            stage: 'Customers',
            value: 250,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
          ),
        ],
        chartTitle: 'Basic Funnel Chart',
        width: 600,
        height: 500,
        hideLegend: false,
        orientation: FluentFunnelOrientation.horizontal,
      ),
      // Measured 0.002% — 5 of 311,994 px, aligned: single antialiased
      // pixels on the Signups stage's shallow diagonals, four on its top edge
      // (x 205-215) and one on its bottom. Every fill, stage boundary and
      // legend swatch lands on upstream's. Pinned at 0.003 rather than 0,
      // which with the floor is a band of 5-9 px. Was 0.251% while the
      // legend strip sat 6 px right of upstream's (`legend.dart` padded a
      // centred strip), then 0.145% while it sat 4 px high under a reserved
      // 40px strip upstream does not have (b60009d).
      maxMismatch: 0.003,
    );
  });
}
