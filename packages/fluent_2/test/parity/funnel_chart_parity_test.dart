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
      // Measured 0.018% — 57 of 312,906 px, aligned, all of it antialiasing
      // on shallow diagonals: 36 px on the A|B and C|D seams where Visit
      // narrows into Sign-Up (x 156-216), 21 px on the Purchase stage's
      // outline and thin band edges near the apex (x 447-492). Each segment
      // is its own source-over path in both, so both show the same light
      // seam; only single pixels along it differ. The legend lands on the
      // capture, swatches included.
      //
      // Was 0.509% (1,593 px) before b60009d: the port summed the fills into
      // one `BlendMode.plus` layer and so painted no seam where upstream's
      // separate `<path>`s (`FunnelChart.tsx:256-263`) let the ground through
      // (992 px), reserved a 40px legend strip upstream does not have, which
      // put the legend 4 px high (432 px), and painted swatches at fractional
      // x where Chromium snaps them (112 px, 61c1a1c).
      maxMismatch: 0.02,
    );
  });
}
