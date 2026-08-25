// Pixel parity for the standalone Legends strip, against the live
// @fluentui/react-charts render.
//
// Every input below is transcribed from the story's own source, recovered from
// the storybook runtime by `capture_png.mjs` into
// `crawlers/storybooks-fluentui/out/stories/charts-legends--legends-basic.tsx`.
//
// The story's `action`, `hoverAction` and `onMouseOutAction` are `console.log`
// and `alert` side effects. They change no pixel of the initial render — the
// only state they feed is `activeLegend`, which is set on hover and starts as
// the empty string (`Legends.tsx:49`) — so they are named here and not stubbed.
//
// See `support/react_parity.dart` for why text is masked and why the tolerance
// is not zero.
import 'package:fluent_2/src/charts/chrome/legend.dart';
import 'package:fluent_2/src/charts/chrome/legend_shape.dart';
import 'package:fluent_2/src/charts/internal/data_viz_palette.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/react_parity.dart';

void main() {
  setUpAll(loadParityFonts);

  testWidgets('LegendsBasic', (tester) async {
    // `const legends: Legend[]` in charts-legends--legends-basic.tsx. Legends 1
    // and 2 carry no `shape`, so both miss `shape.tsx:34`'s nine-key table and
    // fall through to the plain bordered rectangle.
    final legends = <FluentChartLegendItem>[
      FluentChartLegendItem(
        title: 'Legend 1',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color1),
      ),
      FluentChartLegendItem(
        title: 'Legend 2',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color2),
      ),
      FluentChartLegendItem(
        title: 'Legend 3',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color3),
        shape: FluentChartLegendShape.diamond,
      ),
      FluentChartLegendItem(
        title: 'Legend 4',
        color: FluentDataVizPalette.resolve(FluentDataVizToken.color4),
        shape: FluentChartLegendShape.triangle,
      ),
    ];

    await expectReactParity(
      tester,
      'charts-legends--legends-basic',
      // The reference clip is `fui-legend__root` — `width: 100%` of the
      // storybook page, height its content's (`useLegendsStyles.styles.ts:38-44`
      // sets no height) — so 944x32 is one 32px legend row across the page.
      //
      // The harness mounts at a tight 944x32, and this port's strip is now 32
      // tall too, so the OverflowBox is currently a no-op. It stays because it
      // is what reproduces the browser: the block's width is imposed, its height
      // is its content's, and whatever falls below the clip is simply not
      // captured. Under the tight 32 the harness would instead squash a taller
      // strip to fit — measured, when the strip was 40 tall, that halved the
      // label height and *lowered* the mismatch to 3.417% purely because most of
      // the strip had ceased to exist.
      OverflowBox(
        alignment: Alignment.topLeft,
        maxHeight: double.infinity,
        child: FluentChartLegend(
          legends: legends,
          // `<Legends legends={legends} />` passes nothing else, so every other
          // prop is at its default: single selection (`Legends.tsx:101`),
          // focusable rows (`:101`), no wrapped lines (`:109`), not centred
          // (`:115`).
        ),
      ),
      // Measured 0.838% — 222 pixels of 26,482, down from 5.136% (1,360 px).
      // What moved: `legend.dart` now reproduces `classes.resizableArea`, the
      // box `Legends.tsx:115` and `:156` wrap the rows in. It is
      // `max-width: 800px` with `position: relative; left: 50%; transform:
      // translate(-50%, 0)` (`useLegendsStyles.styles.ts:109-116`) — 50% of the
      // parent's width right, 50% of its own back left, i.e. a box capped at 800
      // and centred. In this 944-wide root that is (944 - 800) / 2 = 72 of lead,
      // and the reference's first swatch sits at exactly 72 + 8 of row padding.
      // The port used to lay the rows straight into the incoming constraints and
      // start at the container edge, which the harness could not report as a
      // shift because its probe stops at ±3.
      //
      // Oracle B settles the box outright: `charts-legends--legends-wrap-lines`
      // records `fui-legend__resizableArea` itself at (72, 0, 800, 120) in the
      // same 944-wide root, and the corpus confirms the *rule* rather than the
      // one number — a left-aligned strip's first swatch is at
      // (rootWidth - 800) / 2 + 8 for every captured width over the cap (70 at
      // 924, 78 at 940, 80 at 944) and at plain 8 for every width under it
      // (`charts-linechart--line-chart-basic`, root 680, swatch at 8).
      //
      // The whole residual is three known things, none of them this file's and
      // none of them a tolerance to raise:
      //
      //  * 184 px — the Legend 3 diamond, which settles the origin question
      //    `legend_shape.dart:241-258` records as unverified. Intensity-weighted
      //    centroids, now that the strip is aligned: reference (260.993, 16.003)
      //    against this port's (253.773, 18.937), an offset of (-7.22, +2.93).
      //    That is rotating the 14x14 swatch's centre (7, 7) about the box
      //    corner instead of about its centre — a predicted (-7, +2.9). Chromium
      //    applies the `transform` attribute of an outermost `<svg>` in HTML flow
      //    about the CSS `transform-origin: 50% 50%`, not about SVG user-space
      //    (0, 0) as `FluentChartLegendShapePainter` does. The same reading
      //    predicts the pyramid swatch — which that comment says paints nothing
      //    today — renders normally upstream. Outside this task's file list.
      //  * 24 px — the Legend 4 triangle's diagonal edges. Its centroid is within
      //    0.36 px of the reference's ((350.776, 13.960) against
      //    (350.421, 13.903)), so the geometry is right and only the edge
      //    rasterisation differs.
      //  * 14 px — one column at the right edge of Legend 2's rectangle. The row
      //    pitch is 86.891, so the second swatch starts at a fractional x;
      //    Chromium snaps a border box to whole device pixels and Skia does not
      //    (measured 250,250,250 against 252,224,241, a partial coverage of
      //    `#E3008C`).
      //
      // Pinned just above the measured value so the number is recorded and any
      // drift — in either direction — fails and has to be re-pinned
      // deliberately.
      maxMismatch: 0.93,
    );
  });
}
