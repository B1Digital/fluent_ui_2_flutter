# Oracle C — the React render, as pixels

90 PNGs, one per storybook story at `https://storybooks.fluentui.dev/charts`,
plus `_manifest.json`. This is what `@fluentui/react-charts@9.3.23` actually
draws. Oracle B, next door in `../oracle_b/`, is the same 90 stories as SVG
geometry; this is the same 90 stories as an image.

## Why both

Oracle B compares numbers, and `test/support/oracle_fixture.dart` explains why
it does not compare pixels: two renderers disagree about fonts and
antialiasing, so a naive pixel diff fails on a machine that is perfectly
correct. That reasoning still holds and this corpus does not overturn it — see
`test/parity/support/react_parity.dart`, which removes both causes rather than
ignoring them.

What it buys is coverage a numeric oracle cannot have. **A geometry assertion
only checks what somebody thought to assert.** 22 of these 90 stories are
asserted by nothing story-specific at all (the `kOracleStoriesNoTestNames` map
in `test/charts/oracle_b/oracle_b_fixture_usage_test.dart`), and even an
asserted story only covers the elements its test names. The first story
compared this way turned up two defects that the whole numeric suite passed:

- every axis title painted untruncated, because `cartesian_painter.dart` never
  read the `xAxisTitleMaxWidth` and `yAxisTitleMaxHeight` its own layout had
  already solved;
- the legend's container margin applied twice — once by the legend, once by the
  shell — so every cartesian chart drew its plot 252px tall where upstream
  draws 260, and every mark sat progressively higher than upstream's.

Neither is a wrong number in a formula. Both are a picture that does not match.

## The manifest

`_manifest.json` carries, per story:

| field | meaning |
|---|---|
| `width`, `height` | the chart's own box, in logical px at DPR 1. **Mount the Flutter chart at exactly this size** or the two images are of different layouts. |
| `textRects` | the text to mask, relative to the clip, as `[x, y, w, h]`. Masked on *both* images before comparing — see below. |
| `svgSize` | the chart svg's own box, where there is one. |
| `sourceFile` | the story's module, upstream. |

and once, at the top level, `textRectsRemeasured` — which stories' `textRects`
were re-measured after capture, and how (see below). The harness reads only the
per-story fields, so older readers are unaffected.

Text is excluded from every comparison. The reference's own glyphs are genuine
Segoe UI, loaded by the page as a webfont from `c.s-microsoft.com`; Flutter
draws the metric-compatible open-source Selawik, and even at identical metrics
Skia and Chromium hint glyphs differently. The mask is the **reference's**
rectangles, so a chart that draws a label upstream does not is still caught —
those glyphs fall outside the mask.

What `textRects` records, per story, is three passes of `capture_png.mjs`'s
`MEASURE`:

1. every svg `<text>` and `<tspan>`, by its element box;
2. every *leaf* `fui-` element outside svg that carries text (legend labels),
   by its element box;
3. every other non-blank **text node**, by `Range.getClientRects()` — one rect
   per rendered line, the glyph run itself — including HTML inside an svg
   `<foreignObject>`. Each rect is cut to the clip and to every ancestor that
   clips its overflow (so an ellipsised label masks what paints, not the whole
   string), and text hidden by `visibility` or `opacity: 0` is skipped, since a
   mask over nothing only excuses a Flutter chart that paints something there.

Pass 3 was added on 2026-09-24. Passes 1 and 2 missed ChartTable's cells (a
`<table>` inside a `<foreignObject>`), the legend overflow button's `+N more`
(a text node beside an icon, so not a leaf), annotation-layer HTML,
HorizontalBarChart row titles (nested inside `FocusableTooltipText`) and the
story's own prose where a clip is the union of several chart roots (Sparkline
basic). All of it was compared glyph for glyph: ChartTable measured 4.07%
mismatch with nothing wrong in its layout but the text.

### Re-measured without re-capturing (2026-09-24)

The PNGs were **not** re-captured: the live storybook has moved past 9.3.23
(deployed 2026-09-23 19:03 UTC; the latest `@fluentui/react-charts` on npm is
then 9.3.27), and a fresh corpus would silently swap the reference under every
pinned figure. Instead every story was loaded live in Chrome 153.0.8010.53, at
the capture's viewport, DPR, motion and colour-scheme settings, measured with
all three passes, and screenshotted at the same clip, and the new rects were
only adopted where that live render provably is the committed one:

- **Whole image** — the live screenshot is the committed PNG's size and
  identical to it outside the union of the old and new text rects (each grown
  by the harness's 1px slop), with at most 2 levels per channel of glyph AA
  inside. The new rects replace the old: ChartTable basic, Legends wrap lines.
- **Per rect** — for a story that fails the above only because of renderer
  drift elsewhere (1-3 levels on faint antialiased pixels across most of the
  corpus: a different Chrome and a newer build), the old rects are all kept and
  each new rect is added only if the committed and live pixels inside it (with
  the slop) agree to within 2 levels per channel — the same glyphs in the same
  place — and the committed PNG has visible ink there. 19 stories: every
  HorizontalBarChart story (row titles), heat map basic, both overflowing
  Legends stories, line chart multiple, the vertical bar and stacked bar
  stories with a `+N more` button, sparkline basic (3 of its 5 prose runs) and
  line chart annotations (6 of 13 annotation runs — the rest sit on box fills
  and connectors that drifted, so they stay unmasked).

The other 69 stories are unchanged: in 64 pass 3 finds no text outside the
committed mask; in gauge basic it finds only a sliver of story-control text on
the clip's top edge, with no ink; and in the four stories whose data is
`Math.random` at render time (horizontal-bar-with-axis category order and
dynamic, vertical-bar dynamic, vertical-stacked-bar category order) the only
new rects are svg labels at the new random positions, which the check rejects.
None of those four has HTML text to recover. The record, with both lists, is
`textRectsRemeasured` in the manifest.

## Regenerating

```sh
node crawlers/storybooks-fluentui/capture_png.mjs           # all 90, prunes ghosts
node crawlers/storybooks-fluentui/capture_png.mjs charts-donutchart   # id-prefix filter
```

`crawlers/` is gitignored by the same convention that keeps `capture_oracle.mjs`
out of the tree, so **this README is the only committed record of where these
came from.** The script also writes each story's own source — the input data a
Flutter port has to reproduce — to `crawlers/storybooks-fluentui/out/stories/`.

The script launches the installed Chrome (`channel: 'chrome'`); Playwright's
bundled browsers are not installed on the capture machine. A full run rewrites
every PNG and its `textRects` together, so it drops `textRectsRemeasured`: the
new corpus is measured with all three passes from the start.

Story ids are enumerated from the live `index.json` and never constructed: five
naming conventions are in use upstream, and a constructed id renders
storybook's error page and captures a screenshot of nothing.

The box is the chart's own outermost non-empty container, **not** the union of
everything it draws. A legend label can render past the edge of the component
that owns it, and unioning that overflow in made 22 of these 90 references
wider than the chart they show — enough to stretch a mounted chart's x scale by
2%, which reads as a growing error along the axis rather than as the capture
bug it is. Anything overflowing the chart's box is cropped, exactly as it would
be for a consumer who sized the chart that way.

## Ceilings

- **Light theme only.** The capture pins `colorScheme: 'light'`.
- **Not reproducible without the network.** CI can compare against the
  committed PNGs but cannot regenerate them, exactly as with Oracle B.
- **Version-locked.** These PNGs are 9.3.23 (the re-measure above changed
  rectangles only, never a pixel). Re-capturing against a different
  upstream and not bumping `kPinnedUpstreamVersion` will fail Oracle B's corpus
  test, which is the intended tripwire for both corpora.
- 90 images, ~1.9 MB.
