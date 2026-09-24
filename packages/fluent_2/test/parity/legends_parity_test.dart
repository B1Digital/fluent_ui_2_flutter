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
      // Measured 0.008% — 2 of 26,482 px, aligned, in every zone: the two top
      // corners of the Legend 4 triangle (x 340 and 355, row 9). Chromium
      // fills the flat top edge on columns 341-354 and leaves both neighbours
      // empty; Skia antialiases the diagonals' ends into them at about 45%
      // coverage. Every swatch, including the diamond, lands on the capture.
      //
      // History: 5.136% before `legend.dart` reproduced `classes.resizableArea`
      // (`max-width: 800px`, centred by `left: 50%; translate(-50%, 0)`,
      // `useLegendsStyles.styles.ts:109-116`: (944 - 800) / 2 = 72 of lead,
      // which Oracle B records for legends-wrap-lines at (72, 0, 800, 120));
      // 0.838% before the diamond turned about its box centre, as Chromium
      // turns an outermost `<svg>`, and every swatch snapped to whole device
      // pixels (the triangle's edges and Legend 2's fractional right column).
      maxMismatch: 0.01,
    );
  });

  testWidgets('LegendsControlled', (tester) async {
    // `const legends: Legend[]` in charts-legends--legends-controlled.tsx — the
    // same four rows as legends-basic, including the diamond and triangle.
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
      'charts-legends--legends-controlled',
      // The three "Select …" buttons and the "Selected legends:" line are the
      // story's own chrome outside `fui-legend__root`, so the 944x32 clip
      // holds the strip alone; see LegendsBasic for the OverflowBox.
      OverflowBox(
        alignment: Alignment.topLeft,
        maxHeight: double.infinity,
        child: FluentChartLegend(
          legends: legends,
          // `canSelectMultipleLegends`, and `selectedLegends` from
          // `React.useState<string[]>([])` — controlled, nothing selected.
          selectionMode: FluentChartLegendSelectionMode.multiple,
          selectedLegends: const <String>[],
          onChange: (_, _) {},
        ),
      ),
      // Measured 0.008% — 2 of 26,482 px, aligned, in every zone: the same
      // picture as LegendsBasic above, the Legend 4 triangle's two top corners
      // (was 0.838% for the same reasons as LegendsBasic).
      maxMismatch: 0.01,
    );
  });

  // legends-overflow, -styled and -wrap-lines pass
  // `overflowText="Overflow Items"`, `allowFocusOnLegends` and
  // `canSelectMultipleLegends={false}` (the port's defaults for the last two)
  // over seventeen plain rectangles. Their `action`/`hoverAction`/
  // `onMouseOutAction` are console/alert side effects that change no pixel.
  List<FluentChartLegendItem> seventeen(int firstColor) =>
      <FluentChartLegendItem>[
        for (var i = 0; i < 17; i++)
          FluentChartLegendItem(
            title: 'Legend ${i + 1}',
            color: FluentDataVizPalette.resolve(
              FluentDataVizToken.values[firstColor - 1 + i],
            ),
          ),
      ];

  testWidgets('LegendsOverflow', (tester) async {
    await expectReactParity(
      tester,
      'charts-legends--legends-overflow',
      OverflowBox(
        alignment: Alignment.topLeft,
        maxHeight: double.infinity,
        child: FluentChartLegend(
          // charts-legends--legends-overflow.tsx: Legend N is
          // `DataVizPalette.color(N + 4)`, color5 .. color21.
          legends: seventeen(5),
          overflowText: 'Overflow Items',
        ),
      ),
      // Measured 0.509% — 107 of 21,028 px, aligned, in every zone, all of it
      // the "+10 Overflow Items" trigger's right end. Selawik Semibold sets
      // the label 127.62 wide against Segoe UI Semibold's 123.58 (the
      // capture's line box, x 693.23-816.81), so the button ends 4 px right
      // of the reference's (its left edge, 680, matches):
      //
      //  * 64 px — the right border and its rounded corners, at x 848-849
      //    where the reference has them at 844-846.
      //  * 27 px — the chevron, inked at x 827-834 against 823-830.
      //  * 16 px — the label's last glyph, which runs 3 columns (x 818-820)
      //    past the reference label's masked rect.
      //
      // Every swatch, the row count and the break before the trigger match.
      // History: 4.401% while the capture left the MenuButton label unmasked
      // and the swatches sat at fractional x; 0.499% before the chevron moved
      // into the MenuButton's `menuIcon` slot, which puts it on upstream's
      // rows but, with the wider label, reshuffles 2 px of its antialiasing.
      maxMismatch: 0.51,
    );
  });

  testWidgets('LegendsStyled', (tester) async {
    await expectReactParity(
      tester,
      'charts-legends--legends-styled',
      OverflowBox(
        alignment: Alignment.topLeft,
        maxHeight: double.infinity,
        child: FluentChartLegend(
          // charts-legends--legends-styled.tsx: Legend N is `colorN`. Despite
          // the name, the story passes no `styles`.
          legends: seventeen(1),
          overflowText: 'Overflow Items',
        ),
      ),
      // Measured 0.509% — 107 of 21,028 px, aligned, in every zone: the same
      // 107 trigger pixels as LegendsOverflow above (right border 64, chevron
      // 27, the label's last glyph 16), and nothing from the swatches (was
      // 4.461%, the extra 0.06 point Legend 2's fractional right column).
      maxMismatch: 0.51,
    );
  });

  testWidgets('LegendsWrapLines', (tester) async {
    await expectReactParity(
      tester,
      'charts-legends--legends-wrap-lines',
      OverflowBox(
        alignment: Alignment.topLeft,
        maxHeight: double.infinity,
        child: FluentChartLegend(
          // charts-legends--legends-wrap-lines.tsx: Legend N is `colorN`,
          // with `enabledWrapLines`.
          legends: seventeen(1),
          overflowText: 'Overflow Items',
          enabledWrapLines: true,
        ),
      ),
      // Measured 0.000% — not one of 96,486 unmasked pixels differs, in any
      // zone. Pinned at 0: the floor check admits nothing else. Line breaks,
      // row pitch (40), the 800px resizable area, every swatch colour and
      // every swatch edge match (was 0.336%, 324 px of 14px columns at the
      // fourteen swatches Oracle B puts at fractional x, until the swatches
      // snapped to whole device pixels as Chromium's border boxes do).
      maxMismatch: 0,
    );
  });
}
