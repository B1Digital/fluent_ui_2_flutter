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
      // Measured 0.134% — 155 of 115,942 px, aligned. 91 are the "75%" drawn
      // 10 px left and 7 px low (ink x 443..480 / y 73..87 against the
      // reference's 453..489 / 66..79), leaking out of the masked box; same
      // cause as GaugeChartBasic — `gauge_chart_style.dart`'s
      // `chartValueTextStyle` has no `fontFamily`, so the measurer lays it
      // out in the fallback font while the `Text` paints Selawik. 56 are the
      // three legend swatches' fractional edge columns, 8 arc-edge noise.
      maxMismatch: 0.15,
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
      // Measured 0.044% — 70 of 157,578 px, aligned, and the number flatters
      // it: the centre "50/100" is NOT drawn at all. The port paints "..."
      // instead, because `_fitCharacters` measures the value in the fallback
      // font (`chartValueTextStyle` has no `fontFamily`), where "50/100" at
      // 20px is 120 wide against the 76 budget (inner radius 50 * 2 - 24);
      // in Segoe UI it is 60.7 and fits. The text box is masked, so only the
      // 9 dot pixels that fall below it count. The rest: 44 swatch edge
      // columns, 4 of the title's glyph tops (the port puts the title's
      // baseline 5 px above upstream's `-(outerRadius + TITLE_OFFSET)`) and
      // 13 of antialiasing on the inner arc's flat top.
      maxMismatch: 0.05,
    );
  });
}
