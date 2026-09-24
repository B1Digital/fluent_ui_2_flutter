// Pixel parity for the GaugeChart stories other than Basic (which lives in
// `gauge_and_polar_parity_test.dart`), against the live
// @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/gauge_chart.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

void main() {
  setUpAll(loadParityFonts);

  testWidgets('GaugeChartResponsive', (tester) async {
    // charts-gaugechart--gauge-chart-responsive.tsx. `ResponsiveContainer
    // height={128}` hands the chart the page's 944 and 128; the port fills its
    // constraints when `width`/`height` are null, which is the same box. The
    // segment colours are raw `DataVizPalette` tokens there, which
    // `GaugeChart` resolves itself (Oracle B: rgb(16, 124, 16) etc.).
    await expectReactParity(
      tester,
      'charts-gaugechart--gauge-chart-responsive',
      FluentGaugeChart(
        segments: <FluentGaugeChartSegment>[
          FluentGaugeChartSegment(
            size: 33,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.success),
            legend: 'Low Risk',
          ),
          FluentGaugeChartSegment(
            size: 34,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.warning),
            legend: 'Medium Risk',
          ),
          FluentGaugeChartSegment(
            size: 33,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.error),
            legend: 'High Risk',
          ),
        ],
        chartValue: 75,
        variant: FluentGaugeChartVariant.multipleSegments,
      ),
      // Measured 0.007% — 8 of 115,942 px, aligned: 7 antialiased pixels
      // along the Medium Risk arc's inner edge at the top of the gauge
      // (x 462-468, y 30) and 1 on its outer edge (x 469, y 18). The needle,
      // the "75%" and the legend land on the capture. Was 0.134% while
      // `chartValueTextStyle` had no `fontFamily`, so "75%" was measured in
      // the fallback font and drawn 10 px left and 7 px low (91 px;
      // 6bb4129), and the swatches were painted at their fractional x where
      // Chromium snaps them (56 px; 61c1a1c).
      maxMismatch: 0.01,
    );
  });

  testWidgets('GaugeChartSingleSegment', (tester) async {
    // charts-gaugechart--gauge-chart-single-segment.tsx with every control at
    // its initial state: width 252, height 173, chartValue 50, both Switches
    // off (enableGradient, roundCorners false). "Used" has no colour, so it
    // takes `getNextColor(0)` — Oracle B paints it rgb(99, 124, 239).
    //
    // As in GaugeChartBasic, the captured box is upstream's full-width root
    // (944) and the `width` prop is the svg's own 252, centred inside it.
    await expectReactParity(
      tester,
      'charts-gaugechart--gauge-chart-single-segment',
      FluentGaugeChart(
        width: 252,
        height: 173,
        segments: <FluentGaugeChartSegment>[
          const FluentGaugeChartSegment(size: 50, legend: 'Used'),
          FluentGaugeChartSegment(
            size: 100 - 50,
            color: FluentDataVizPalette.resolve(FluentDataVizToken.color5),
            legend: 'Available',
          ),
        ],
        chartValue: 50,
        chartTitle: 'Storage capacity',
        sublabel: 'used',
        chartValueFormat: FluentGaugeValueFormat.fraction,
        variant: FluentGaugeChartVariant.singleSegment,
      ),
      // Measured 0.008% — 13 of 157,578 px, aligned, all antialiasing on
      // the "Used" arc beside the needle: 12 on its inner edge (x 454-466,
      // y 55-58) and 1 on its outer (x 454, y 45). "50/100", the title, the
      // sublabel and the legend land on the capture. Was 0.044% — and
      // flattering — while `chartValueTextStyle` had no `fontFamily`:
      // `_fitCharacters` measured "50/100" in the fallback font (120 wide
      // against a 76 budget) and painted "..." instead, the title's baseline
      // sat 5 px above upstream's `-(outerRadius + TITLE_OFFSET)` (both
      // 6bb4129), and the swatches were painted at their fractional x (44 px;
      // 61c1a1c).
      maxMismatch: 0.01,
    );
  });
}
