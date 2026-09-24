// Pixel parity for FunnelChart's stacked story, against the live
// @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`. Nothing here is
// invented or rounded. FunnelChartBasic lives in
// `donut_and_funnel_parity_test.dart`.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/funnel_chart.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

/// One stage of `stackedData`: every stage carries the same four categories in
/// the same colours, only the values differ.
FluentFunnelDataPoint _stage(String stage, List<double> values) {
  const categories = <String>['A', 'B', 'C', 'D'];
  const tokens = <FluentDataVizToken>[
    FluentDataVizToken.color5,
    FluentDataVizToken.color6,
    FluentDataVizToken.color10,
    FluentDataVizToken.color3,
  ];
  return FluentFunnelDataPoint(
    stage: stage,
    subValues: <FluentFunnelSubValue>[
      for (var i = 0; i < 4; i++)
        FluentFunnelSubValue(
          category: categories[i],
          value: values[i],
          color: FluentDataVizPalette.resolve(tokens[i]),
        ),
    ],
  );
}

void main() {
  setUpAll(loadParityFonts);

  testWidgets('FunnelChartStacked', (tester) async {
    // `const stackedData` in charts-funnelchart--funnel-chart-stacked.tsx, with
    // every control at its initial state: width 600, height 500, hideLegend
    // false, orientation horizontal, legendMultiSelect false.
    await expectReactParity(
      tester,
      'charts-funnelchart--funnel-chart-stacked',
      FluentFunnelChart(
        data: <FluentFunnelDataPoint>[
          _stage('Visit', const <double>[100, 80, 50, 30]),
          _stage('Sign-Up', const <double>[60, 40, 20, 10]),
          _stage('Purchase', const <double>[30, 20, 10, 5]),
        ],
        chartTitle: 'Stacked Funnel Chart',
        width: 600,
        height: 500,
        orientation: FluentFunnelOrientation.horizontal,
      ),
      // Measured 0.509% — 1,593 of 312,906 px, aligned. Three causes, none of
      // them the segment geometry, which lands on upstream's everywhere:
      //
      //  * 992 px are the seams between categories inside a stage. Upstream
      //    paints each segment as its own source-over `<path>`
      //    (`FunnelChart.tsx:256-263`), so two half-covered pixels either side
      //    of a shared diagonal edge let the ground through: the reference
      //    reads (97,176,186) on the Visit/Sign-Up A|B seam at x 240, y 217.
      //    `FluentFunnelChartPainter` sums the fills into one `BlendMode.plus`
      //    layer precisely to remove that seam, and reads (41,156,128). Painted
      //    source-over in a scratch run, the plot drops from 1,049 to 57
      //    mismatched pixels.
      //  * 432 px are the legend strip sitting 4 px high (swatches y 505-518
      //    against 509-522) — the same as FunnelChartBasic: the port reserves
      //    `kMinLegendContainerHeight` (40) under the plot where upstream's
      //    legend div follows the 500px svg at its own 32px height
      //    (`FunnelChart.tsx:481-486`, `:528`).
      //  * 112 px are swatch edge columns: Chromium snaps each HTML swatch box
      //    to whole pixels (A at x 216.75 paints 217-230), the port paints it
      //    at the fractional x with antialiased edges.
      maxMismatch: 0.56,
    );
  });
}
