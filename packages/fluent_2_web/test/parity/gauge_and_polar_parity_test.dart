// Pixel parity for GaugeChart and PolarChart, against the live
// @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/<story-id>.tsx`.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2_web/src/charts/gauge_chart.dart';
import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
import 'package:fluent_2_web/src/charts/model/polar_data.dart';
import 'package:fluent_2_web/src/charts/polar_chart.dart';
import 'package:fluent_2_web/src/charts/polar_chart_scales.dart';
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
      // Measured 0.145%, down from 4.246%. The gauge used to be painted
      // against the LEFT edge of its box instead of centred: the `CustomPaint`
      // was `Positioned.fill` over the whole incoming 944, while the origin it
      // consumes is `size.width / 2` solved from the `width` PROP, so the arc
      // landed at x = 126 against the reference's 472. The chart area is now
      // the svg's own 252 and centred in the root, as
      // `useGaugeChartStyles.styles.ts:35-43` (`align-items: center`) does
      // upstream, while the legend keeps the full 944 (`:126-128`). The
      // capture's own html boxes settle it: `fui-gc__chartWrapper` at x 370 by
      // 252 wide, `fui-legend__root` at x 24 by 944 — a 346px inset that is
      // exactly (944 - 252) / 2.
      //
      // The 0.145% left is 152 pixels in two places, neither of them the arc,
      // which now lands on the reference to within its antialiased edge:
      //   * ~96px around the centred `50%`, which is drawn the right SIZE in
      //     the wrong PLACE — 38x16 of ink in both, at x 453..490 / y 65..80 in
      //     the reference against x 443..480 / y 72..87 in the port, so 10 left
      //     and 7 low. `gauge_chart_style.dart:365` builds `chartValueTextStyle`
      //     as a bare `TextStyle(fontWeight, color)` with no `fontFamily`,
      //     unlike every sibling in that resolver. `FluentChartTextMeasurer`
      //     lays out a bare `TextSpan`, so it measures that style in the
      //     FALLBACK font — a 60px advance and a 16px ascent for "50%" at 20px
      //     — while `_centredText`'s `Text` merges the `DefaultTextStyle` and
      //     paints Selawik at 38 and ~22.6. `left = origin.dx - width / 2` and
      //     `top = origin.dy - ascent` then miss by exactly the two deltas.
      //     Left here deliberately: the same one-line style fix moves the
      //     `charts_shell_free` goldens, which cannot be regenerated while
      //     another change already has them failing.
      //   * 56px on the three legend swatches' left and right edges, each one
      //     column wide (port 424..438 against the reference's 425..438).
      maxMismatch: 0.165,
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
      // Measured 0.027% — 56px, the four one-column swatch edges (x 248/262
      // and 312/326, rows 327..340) where Chrome pixel-snaps the legend div
      // and Skia antialiases the same fractional box. The plot is exact.
      maxMismatch: 0.03,
    );
  });
}
