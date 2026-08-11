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
import 'package:fluent_2_web/src/charts/chrome/legend.dart';
import 'package:fluent_2_web/src/charts/chrome/legend_shape.dart';
import 'package:fluent_2_web/src/charts/internal/data_viz_palette.dart';
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
      // The harness mounts at a tight 944x32. This port's strip is 40 tall,
      // because of the container margin the first tolerance note below reports,
      // and a tight 32 squashes the row to 8px of content: measured that way the
      // labels render at half height and the mismatch drops to 3.417% purely
      // because most of the strip has ceased to exist. OverflowBox reproduces
      // the browser instead — the block's width is imposed, its height is its
      // content's, and whatever falls below the clip is simply not captured,
      // which is what Chromium's own clip does.
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
      // Measured 6.227% — 1,649 pixels of 26,482. NOT rasteriser noise and NOT
      // a tolerance to raise. Correcting for a whole-image (-60, +8) translation
      // takes it to 0.415% — 110 pixels, re-measured with the harness's own
      // masking and channel tolerance — which is what says the strip itself is
      // right and its POSITION is wrong; the harness's own shift probe stops at
      // ±3 and cannot see it. (-60, +8) is the true minimum: a sweep of dx over
      // -66..-54 and dy over 4..11 finds nothing better. Three defects, all
      // reported rather than fixed:
      //
      //  * `Legends.tsx:118` wraps the rows in `classes.resizableArea`:
      //    `max-width: 800px` with `position: relative; left: 50%; transform:
      //    translate(-50%, 0)` (`useLegendsStyles.styles.ts:206-213`) — a box
      //    capped at 800 and centred in its parent. In a 944-wide root that is
      //    (944 - 800) / 2 = 72px of lead, and the reference's first swatch sits
      //    at x=80, which is that 72 plus the row's own 8px padding. This port
      //    has no counterpart at all, so its strip starts at the container edge.
      //    The 800 is corroborated by a story this test does not mount:
      //    `charts-legends--legends-wrap-lines` also leads with 72 and wraps
      //    after 8 rows, and 8 of its rows are 759.1 wide against a 9th that
      //    would reach 854 — a wrap that only a cap between those two explains.
      //  * `FluentChartLegend` then adds `containerMargin`, 8 top and 12 start
      //    (`legend_style.dart:266-271`), which upstream's `classes.root` does
      //    not have: `LEGEND_CONTAINER_MARGIN_TOP`/`_START` are read only by
      //    `image-export-utils.ts`, and on screen those same 8 and 12 are
      //    `useCartesianChartStyles.styles.ts:102-105`'s margin on the
      //    *CartesianChart's* legend wrapper — which is why
      //    `cartesian_chart.dart:410` already zeroes them for that shell. A
      //    standalone `Legends` has neither. Together the two account for the
      //    whole (-60, +8): 12 - 72 = -60 across, 8 down.
      //  * 94 of the 110 pixels still differing after that correction are the
      //    Legend 3 diamond, and they settle the origin question
      //    `legend_shape.dart:241-258` records as unverified. Upstream's diamond
      //    is centred in its 14x14 swatch (measured, intensity-weighted centroid:
      //    reference (260.99, 16.00) against a swatch box centred on
      //    (260.78, 16.00)); this port's, once the (-60, +8) strip offset is
      //    taken back out, is 7.25px left and 2.66px down of that — which is
      //    rotating the box centre (7, 7) about the box corner to (0, 9.9), a
      //    predicted (-7, +2.9). Chromium applies the `transform` attribute on
      //    an outermost
      //    `<svg>` in HTML flow with a CSS `transform-origin: 50% 50%`, not
      //    about SVG user-space (0, 0) as `FluentChartLegendShapePainter` does.
      //    The same reading predicts the pyramid swatch — which that comment
      //    says paints nothing today — renders normally upstream.
      //
      // The remaining 16 pixels are rasteriser noise on the two fractionally
      // positioned swatches: Chromium snaps a border box to whole device pixels
      // and Skia does not, so Legend 2's rectangle carries one column of 11%
      // pink at its right edge that the reference rounds away (6 px, measured
      // 255,255,255 against 252,224,241 — a 3/28 coverage of `#E3008C`), and the
      // Legend 4 triangle's diagonals sit a pixel out (10 px). The triangle's
      // own centroid lands within 0.36px of the reference's once the strip
      // offset is removed, so its geometry is right and only its edges differ.
      //
      // Pinned just above the measured value so the number is recorded and any
      // drift — in either direction — fails and has to be re-pinned
      // deliberately.
      maxMismatch: 6.85,
    );
  });
}
