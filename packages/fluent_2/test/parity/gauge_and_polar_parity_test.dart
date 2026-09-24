// Pixel parity for GaugeChart and PolarChart, against the live
// @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/gauge_chart.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2/src/charts/model/polar_data.dart';
import 'package:fluent_2/src/charts/polar_chart.dart';
import 'package:fluent_2/src/charts/polar_chart_scales.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

void main() {
  setUpAll(loadParityFonts);

  testWidgets('GaugeChartBasic', (tester) async {
    await expectReactParity(
      tester,
      'charts-gaugechart--gauge-chart-basic',
      // The manifest's box is 944x128: upstream's root is a full-width block
      // and only the svg inside it is 252 wide, centred. Both the svg and the
      // legend row in the reference sit on x = 472 = 944 / 2 (measured: the
      // arc spans x 411..532, centre 471.5). The port is given the story's own
      // `width: 252` inside that captured box, which is exactly what upstream
      // is given; passing 944 instead would lay a completely different gauge
      // out, because the outer radius is solved from the width.
      FluentGaugeChart(
        // The three sliders start at width 252, height 128, value 50; the
        // checkbox and all three Switches start off, so hideMinMax,
        // enableGradient, roundCorners and legendMultiSelect are all false.
        chartValue: 50,
        width: 252,
        height: 128,
        variant: FluentGaugeChartVariant.multipleSegments,
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
      ),
      // Measured 0.004% — 5 of 115,520 px, aligned: one antialiased row
      // along the Medium Risk arc's inner edge where it meets the needle
      // (x 462-466, y 30). The arc, needle, centred "50%" and legend land on
      // the capture.
      //
      // Was 4.246% while the gauge was painted against the LEFT edge of its
      // box: the `CustomPaint` filled the incoming 944 while the origin it
      // consumes is `size.width / 2` of the `width` prop, so the arc landed
      // at x = 126 against the reference's 472. The chart area is now the
      // svg's own 252, centred in the root as `useGaugeChartStyles.styles.ts:
      // 35-43` (`align-items: center`) does, while the legend keeps the full
      // 944 (`:126-128`) — the capture's `fui-gc__chartWrapper` at x 370 by
      // 252 and `fui-legend__root` at x 24 by 944 settle it. Then 0.145%
      // while `chartValueTextStyle` had no `fontFamily`, so the measurer laid
      // "50%" out in the fallback font and it was drawn 10 px left and 7 px
      // low (6bb4129), and the swatches were painted at their fractional x
      // where Chromium snaps them (61c1a1c).
      maxMismatch: 0.005,
    );
  });

  testWidgets('PolarChartBasic', (tester) async {
    // `const data: PolarChartProps["data"]` in
    // charts-polarchart--polar-chart-basic.tsx. Both series are `areapolar`.
    const data = <FluentPolarSeries>[
      FluentAreaPolarSeries(
        legend: 'Mike',
        color: Color(0xFF8884D8),
        data: <FluentPolarDataPoint>[
          FluentPolarDataPoint(r: 120, theta: 'Math'),
          FluentPolarDataPoint(r: 98, theta: 'Chinese'),
          FluentPolarDataPoint(r: 86, theta: 'English'),
          FluentPolarDataPoint(r: 99, theta: 'Geography'),
          FluentPolarDataPoint(r: 85, theta: 'Physics'),
          FluentPolarDataPoint(r: 65, theta: 'History'),
        ],
      ),
      FluentAreaPolarSeries(
        legend: 'Lily',
        color: Color(0xFF82CA9D),
        data: <FluentPolarDataPoint>[
          FluentPolarDataPoint(r: 110, theta: 'Math'),
          FluentPolarDataPoint(r: 130, theta: 'Chinese'),
          FluentPolarDataPoint(r: 130, theta: 'English'),
          FluentPolarDataPoint(r: 100, theta: 'Geography'),
          FluentPolarDataPoint(r: 90, theta: 'Physics'),
          FluentPolarDataPoint(r: 85, theta: 'History'),
        ],
      ),
    ];

    await expectReactParity(
      tester,
      'charts-polarchart--polar-chart-basic',
      // Both sliders start at 600 x 350, which is the captured box.
      const FluentPolarChart(
        data: data,
        width: 600,
        height: 350,
        shape: FluentPolarShape.polygon,
        direction: FluentPolarDirection.clockwise,
      ),
      // Measured 0.000% — not one of 204,726 unmasked pixels differs. Was
      // 0.027% while the two legend swatches were painted at their
      // fractional x where Chromium snaps the div (56 px; 61c1a1c).
      maxMismatch: 0,
    );
  });
}
