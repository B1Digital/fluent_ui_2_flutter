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
| `width`, `height` | the clip, in logical px at DPR 1. **Mount the Flutter chart at exactly this size** or the two images are of different layouts. |
| `textRects` | every `<text>` and HTML label box, relative to the clip. Masked on *both* images before comparing — see below. |
| `svgSize` | the chart svg's own box, where there is one. |
| `sourceFile` | the story's module, upstream. |

Text is excluded from every comparison. The reference's own glyphs are genuine
Segoe UI, loaded by the page as a webfont from `c.s-microsoft.com`; Flutter
draws the metric-compatible open-source Selawik, and even at identical metrics
Skia and Chromium hint glyphs differently. The mask is the **reference's**
rectangles, so a chart that draws a label upstream does not is still caught —
those glyphs fall outside the mask.

## Regenerating

```sh
node crawlers/storybooks-fluentui/capture_png.mjs           # all 90, prunes ghosts
node crawlers/storybooks-fluentui/capture_png.mjs charts-donutchart   # id-prefix filter
```

`crawlers/` is gitignored by the same convention that keeps `capture_oracle.mjs`
out of the tree, so **this README is the only committed record of where these
came from.** The script also writes each story's own source — the input data a
Flutter port has to reproduce — to `crawlers/storybooks-fluentui/out/stories/`.

Story ids are enumerated from the live `index.json` and never constructed: five
naming conventions are in use upstream, and a constructed id renders
storybook's error page and captures a screenshot of nothing.

## Ceilings

- **Light theme only.** The capture pins `colorScheme: 'light'`.
- **Not reproducible without the network.** CI can compare against the
  committed PNGs but cannot regenerate them, exactly as with Oracle B.
- **Version-locked.** These are 9.3.23. Re-capturing against a different
  upstream and not bumping `kPinnedUpstreamVersion` will fail Oracle B's corpus
  test, which is the intended tripwire for both corpora.
- 90 images, ~1.9 MB.
