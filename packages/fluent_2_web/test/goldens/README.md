# Golden images

## What these are

A **regression net**. Each image pins the current rendering of one component so
that an *unintended* visual change — a padding that moved, a token that stopped
resolving, a surface that went transparent — fails a test instead of shipping.

## What these are not

**Not proof of Figma fidelity.** The application bundles the open-source Selawik
substitute, but this test harness deliberately does not register application
fonts. `flutter test` therefore substitutes a placeholder font that draws every
glyph as an identical box. The icon font is not loaded either, so icons are
boxes too. An image that matches its golden says the component renders the same
as it did last commit — nothing more.

Fidelity against the design is asserted **numerically**, by
`test/support/spec_fixture.dart` against `test/fixtures/*.json`: resolved sizes,
paddings, radii, stroke widths and ARGB fills, compared to the values extracted
from the Figma file. That is the file to change if you want to know whether a
component is *correct*. This directory only knows whether it *changed*.

The placeholder font is a feature here, not a limitation — it is what makes the
images reproduce byte-for-byte across machines.

## Layout

One image per component per theme, not one per variant: `badge.light.png` holds
all 28 colour/appearance pairs plus the sizes and layouts. A reviewer diffs one
PNG and sees which cell moved, instead of scrolling 150 near-identical files.

Cells are **not labelled** — a caption would render as a row of boxes. The cell
order is the order of the list in the matching `*_golden_test.dart`, and that
file's header comment says what each row is.

Three themes each: `light`, `dark`, `high_contrast`. High contrast is not
garnish. It is the mode nobody looks at, and the one where a hardcoded
transparent surface silently disappears — see the findings below, both of which
this net caught on its first run.

Skeleton, Spinner and ProgressBar additionally get a `*.reduced_motion.png`
(light only — the code path is about motion, not tokens).

## Animation

Skeleton, Spinner and ProgressBar loop forever, so `pumpAndSettle` would time
out on them. Their tests pump a single frame at a **fixed elapsed time**
(750ms), which lands mid-cycle for all three: a quarter through the skeleton's
3000ms wave, three quarters through its 1000ms pulse, half a 1500ms spinner
rotation, a quarter of the 3000ms indeterminate sweep. Mid-cycle on purpose — at
an endpoint a stalled controller would look identical to a working one.

## Regenerating

```sh
cd packages/fluent_2_web
flutter test --update-goldens test/goldens/   # rewrite the images
flutter test test/goldens/                    # then verify a clean run passes
```

Never commit a `--update-goldens` run you have not looked at. The whole point is
that the diff is reviewable, and an unexamined regeneration converts a caught
regression into a committed one.

39 images, ~256 KB total. Keep it that way: coarsen a grid rather than adding a
megabyte of PNG.

## Known ceiling

Flutter goldens are only stable for a given engine build. A Flutter upgrade that
changes rasterisation or text layout will fail every image at once; that is a
regeneration, not a regression. A wholesale failure across all 39 is the signal.

## What the first run caught

Both of these are in `lib/`, not in the tests, and both are recorded here rather
than silently baked in — the goldens currently pin the broken rendering, so
fixing either one will (correctly) fail its image.

- **`FluentTooltipAppearance.inverted` is unreadable in high contrast.** Both
  `neutralBackgroundInverted` and `neutralForegroundInverted` resolve to
  `#000000` there, so the tooltip is black text on a black surface. Only the
  `transparentStroke` border — which becomes `canvasText` in high contrast —
  keeps the surface visible at all. See row 3 of `tooltip.high_contrast.png`.
- **`FluentBadgeColor.subtle` vanishes entirely in high contrast** at the
  `outline` and `ghost` appearances: no fill, no border, no visible label. The
  last row of `badge.high_contrast.png` has two cells where the other six
  colours have four.
