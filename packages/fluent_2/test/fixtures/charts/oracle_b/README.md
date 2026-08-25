# Oracle B — storybook geometry fixtures

## What these are

The geometry of the **live implementation**, captured once and committed. One
JSON per Storybook story from `@fluentui/react-charts` 9.3.23: every `path`'s
`d`, every `rect`'s x/y/width/height, every `circle`'s cx/cy/r, every `line`'s
endpoints, every `g`'s transform, every `text`'s content and position, plus the
**resolved** `fill`, `stroke`, `stroke-width`, opacity and font metrics from
`getComputedStyle`.

Charts have no Figma source, so `test/support/spec_fixture.dart` — which asserts
against numbers extracted from the Fluent Figma file — has nothing to read for
them. This directory is the replacement (design spec §4.3, "Oracle B"). Its
sibling is Oracle A at `test/charts/d3/d3_golden.json`, which pins the d3
primitives; Oracle B pins what upstream builds out of them.

`test/support/oracle_fixture.dart` reads these files. It selects elements, walks
the transform chain, and compares numbers, colours and path strings against
whatever a Flutter painter computed.

Legend boxes are captured too, even though the spec says "SVG geometry":
upstream draws the legend in **HTML** apart from its 14 px shape `svg`
(`Legends.tsx`), so an SVG-only capture would verify none of it. Those live
under `htmlBoxes`, keyed by Fluent slot class (`fui-legend__root`,
`fui-legend__rect`, `fui-legend__text`).

### HTML-only fixtures

Three of the five Legends stories — `charts-legends--legends-overflow`,
`--legends-styled` and `--legends-wrap-lines` — render **no `svg` at all**. Their
swatches are `fui-legend__rect` divs, so their fixtures carry `"svgs": []` and
everything they measured is in `htmlBoxes`. That is a valid fixture, not a
partial one: the geometry of legend overflow and legend wrapping has no other
oracle, and an svg-required schema would leave it with none.

Read one through `boxes(...)`, never through `primary`:

```dart
final story = loadOracleStory('charts-legends--legends-overflow');
if (!story.hasSvg) {
  final visible = story
      .boxes('fui-legend__rect')
      .where((box) => box.rect.width > 0);   // 6 of 17
}
```

`OracleStory.primary` throws a `StateError` naming this case rather than
returning an empty svg, because `byTag('rect')` on an empty svg comes back empty
and a test asserting a count would pass having measured nothing. Branch on
`hasSvg`, not on a `try`/`catch`.

Two things to know before you assert on one:

- **An overflowed item is the zero rect at the origin.** Upstream's `Overflow`
  gives an item that does not fit `display: none`, and a `display: none`
  element's `getBoundingClientRect()` is empty. `legends-overflow` therefore
  records 17 `fui-legend__rect` boxes of which **6 have a non-zero width** —
  filter on `rect.width > 0`; never take the length of the list as the item
  count.
- **The overflow indicator itself is not captured.** The `+N Overflow Items`
  button's only `fui-` token is `fui-Button`, which the slot filter rejects along
  with a story's own scaffolding controls. Its width is a measured glyph run and
  would be advisory even if it were recorded; widen the filter in the capture
  script if a test needs it.
- **The two overflow stories do not record their resizable area.** On
  `legends-overflow` and `legends-styled` the only slots recorded are
  `fui-legend__root`, `__rect` and `__text`: that element's first `fui-` token is
  `fui-Overflow`, so the slot filter rejects it. On `legends-wrap-lines`, which
  wraps instead of overflowing, the token order puts `fui-legend__resizableArea`
  first and it *is* recorded, at `[96, 48, 800, 120]` — the same 800 px both
  overflow stories must have, i.e. the 944 px root less 72 px of padding either
  side. Prefer the `fui-legend*` token over the first `fui-` token in the capture
  script if a test needs it recorded rather than derived, and re-capture the whole
  corpus when you do, so every fixture describes the same schema.

For an HTML-only story the top-level `width`/`height` are the **widest**
`htmlBoxes` entry rather than a primary svg's box: 944 × 32 for
`legends-overflow` and `legends-styled`, 944 × 120 for `legends-wrap-lines`,
which is the `fui-legend__root` in each case.

A story with **neither** an svg nor an html box is still not a fixture. It goes
into the skip register with its reason — see "A story that fails to render is
registered, not skipped quietly".

## What these are not

**Not images, and not comparable as pixels.** The capture browser resolves
Fluent's font stack against whatever fonts the capture machine has;
`flutter test` deliberately registers no application font and draws every glyph
as an identical box (see `test/goldens/README.md`). Skia's antialiasing does not
match Chromium's either. Geometry is therefore compared **numerically**, never as
a rasterised pixel — the same reasoning `test/fixtures/README.md` gives for the
Figma harness.

**Text extents are advisory, not assertable.** `bbox` on a `<text>` element, and
the `rect` of any `fui-legend__text` box, are measured glyph runs: they are a
property of the capture machine's fonts. Everything d3 computed — tick positions,
domain paths, band offsets, bar and arc geometry — is font-independent, and that
is what a test should assert. `fontFamilies` is recorded once per svg for
information and is never compared.

**Not self-updating, and not checked against anything live.** These files
describe `@fluentui/react-charts` 9.3.23 and no other release. Re-capture needs
`storybooks.fluentui.dev` and `flutter test` has no network, so CI verifies this
corpus but **cannot regenerate** it. An upstream release therefore fails nothing
here by itself — the version pin is what fails. See "When the pin moves".

**Not a complete record of the DOM.** Accessibility attributes, `<title>` and
`<desc>` nodes, `<canvas>` content, popover and overflow-menu markup, and any
HTML outside the `fui-legend*` / `fui-*chart*` slots are not captured. Add them to
the capture script if a test needs them; do not infer them.

**Not proof that a chart is correct.** It is proof that a chart agrees with
upstream, including upstream's defects. That is the point: design spec §5.2
requires the port to reproduce ~20 known upstream bugs, marked `// parity:`. Two
are exceptions and are *fixed*, so those two will legitimately disagree with
these fixtures: `VerticalStackedBarChart.tsx:167`'s `Math.random()` legend
colour, and anything that breaks accessibility or security.

## Shape

```jsonc
{
  "id": "charts-areachart--area-chart-basic",
  "component": "AreaChart",       // last segment of the Storybook title
  "name": "AreaChartBasic",       // the exported story name
  "title": "Charts/AreaChart",
  "upstreamVersion": "9.3.23",
  "deviceScaleFactor": 1,         // pins the crispness offset — see below
  "crispOffset": 0.5,
  "viewport": {"width": 1024, "height": 768},
  "width": 700,                   // the primary svg's CSS box: mount a
  "height": 260,                  // SizedBox of these two to compare
  "svgs": [ /* widest first; a legend-shape svg follows the chart.
               EMPTY for an HTML-only story — see above */ ],
  "htmlBoxes": [ /* fui-legend* and fui-*chart* boxes */ ]
}
```

One svg:

```jsonc
{
  "width": 700, "height": 260, "viewBox": null,
  "slot": "fui-cart__chart",      // the fui- class; upstream's own typo
  "fontFamilies": ["\"Segoe UI\", …, sans-serif"],
  "elements": [ /* document order, gradients excluded */ ],
  "gradients": [ /* linearGradient defs with their stops */ ]
}
```

One element — **keys whose value is null are omitted**, so absence means null.
This is the x-axis domain path of `charts-areachart--area-chart-basic`, verbatim:

```jsonc
{
  "tag": "path", "index": 1,
  "parent": 0,                    // index within this svg, -1 for a direct child
  "ctm": [1, 0, 0, 1, 0, 205],    // float32, see "Things that will bite you"
  "bbox": [0, 0, 0, 0],
  "d": "M64.5,6V0.5H680.5V6",
  "fill": "none", "fillOpacity": "1",
  "stroke": "rgb(36, 36, 36)", "strokeWidth": "1px", "strokeOpacity": "1",
  "strokeDasharray": "none", "strokeLinecap": "butt", "opacity": "1",
  "fontSize": "10px", "fontWeight": "400",
  "textAnchor": "middle", "dominantBaseline": "auto"
}
```

The inherited text properties are on the `path` too, because they are what
`getComputedStyle` resolved there — they mean nothing for a path and are only
read off a `text`.

`_manifest.json` carries the capture conditions, the per-component coverage, the
thin-coverage list and the **skip register**. `OracleManifest` exposes all of it.

### Field notes

| Field | Notes |
|---|---|
| `id` | Enumerated from `index.json`. **Never construct one** — see below. |
| `width` / `height` | The primary (widest) svg's CSS box, or the widest `htmlBoxes` entry when `svgs` is empty. Per design spec §2.2 a Flutter chart honours its `BoxConstraints`, so a comparison mounts the chart in a `SizedBox` of exactly this size. |
| `svgs` | May be **empty** — see "HTML-only fixtures". Use `hasSvg`, not `svgs.first`. |
| `slot` | The svg's `fui-` class. Null for 25 of the 135 captured svgs, all of them ChartTable's and Sparkline's, which upstream leaves unclassed. |
| `parent` | The index of the enclosing element within the same list. `OracleStory.parentOf` / `childrenOf` / `absoluteTranslate` walk it. |
| `transform` | The raw attribute. `OracleElement.translate` parses it **only** when it is a pure `translate`; a rotate or matrix leaves it null on purpose, so a rotated tick label cannot be compared as though it were unrotated. 41 elements in the corpus carry a rotate, 4 of them as a `translate(…)rotate(…)` compound. |
| `ctm` / `bbox` | Renderer-measured, therefore float32. Compare at `kOracleMeasuredTolerance` (0.5) or, better, use `absoluteTranslate`. |
| `fill` / `stroke` | Resolved to `rgb()`/`rgba()` by `getComputedStyle`, or `url(#id)` for a gradient — `OracleElement.fillRef` keeps the id. `"none"` becomes `null` on the Dart side: an absence of paint, **not** a transparent colour. |
| `opacity` | The element's own. CSS does not inherit it, so upstream's grid `line` at 0.2 inside a `g` at 1 is recorded exactly that way. |
| `gradients` | Sankey paints its links with `linearGradient` defs — `SankeyChartBasic` has 8 with 16 stops. Offsets are `0`/`100` as authored, not normalised to 0..1. |
| `htmlBoxes[].text` | Null when the element has element children, so `fui-legend__root` carries none. |
| `htmlBoxes[].forcedColorAdjust` | `auto` on all 902 boxes in the corpus. Upstream *does* opt the legend out of high-contrast flattening (design spec §5.3), but inside a `HighContrastSelector` block — `Legends/useLegendsStyles.styles.ts:60-62` and `:69-71` — and the capture did not run under forced colours. So this records what normal mode resolves, and the opt-out is **not** verifiable from this corpus. |

## Things that will bite you

### Never construct a story id

Upstream uses **five** naming conventions:

```text
charts-linechart--line-chart-basic                            slug repeated
charts-verticalstackedbarchart--vertical-stacked-bar-default  "Chart" dropped
charts-horizontalbarchart--horizontal-bar-basic               "Chart" dropped, "basic" kept
charts-declarativechart--declarative-chart-basic-example      "-example" suffix
charts-vegadeclarativechart--default                          no slug at all
```

A constructed id does not error — it renders Storybook's "Couldn't find story
matching …" page and captures **nothing**, which reads as a passing test with
zero assertions. Measured: `charts-horizontalbarchart--horizontal-bar-chart-basic`
is wrong; the real id is `charts-horizontalbarchart--horizontal-bar-basic`. Use
`oracleStoryIds()`.

### 111 index entries is 90 stories

`index.json` holds 111 **entries**, of which 21 are `type: "docs"` and 90 are
`type: "story"`. The capture filters on the type and expects 90; design spec §4.3
records both numbers, and so does `_manifest.json`, so nobody reconciles them
twice. Anything counted "per story" in this directory means 90.

### The crispness offset is why `deviceScaleFactor` is 1

`d3-axis` sets `offset = window.devicePixelRatio > 1 ? 0 : 0.5`
(`d3-axis/src/axis.js:38`) and adds it once to every tick transform and to both
ends of the domain path. The capture runs at `deviceScaleFactor: 1` and
`flutter test` runs at DPR 1, so both sides sit on 0.5 and agree — which is why
the domain path reads `M64.5,6V0.5H680.5V6` and not `M64,6V0H680V6`. Read it from
the fixture (`OracleStory.crispOffset`) rather than hard-coding it, so a
re-capture at a different DPR moves every consuming test at once. The geometry
tolerance is 0.01 px precisely so it can never hide a missing or halved offset
(design spec §5.5).

### Thin coverage is named, not hidden

Coverage is uneven: LineChart has 13 stories, VerticalBarChart 11, PolarChart 1,
and both declarative adapters 1 each. Components with fewer than three stories
are listed in `_manifest.json` under `thinComponents` — eight of the twenty, as
committed — and the capture prints them. Those charts lean on Oracle A and
hand-derivation from the TypeScript, and a reviewer must say so rather than
implying the oracle covered them.

### A story that fails to render is registered, not skipped quietly

If a story shows Storybook's error display, renders no children, or produces
**neither a chart svg nor a single `fui-` html box**, no fixture is written — not
a partial one — and the story goes into `_manifest.json`'s `skipped` list with its
reason. `loadOracleStory` on such an id throws `oracleSkippedStoryError`, whose
wording names that reason and is deliberately different from the missing-fixture
message, so a consuming test cannot read a missing fixture as "nothing to check
here". The corpus test fails if more than four stories are skipped.

Producing no svg is *not* on its own a reason to skip; see "HTML-only fixtures".
All 90 stories capture, and the skip register is empty as committed.

## Regenerating

```sh
cd crawlers/storybooks-fluentui
node capture_oracle.mjs                       # all 90 stories, ~5-8 minutes
node capture_oracle.mjs charts-areachart      # one component, no prune
```

The script lives in `crawlers/`, which is **gitignored** — the same arrangement as
plan 01's `crawlers/d3-golden/generate.mjs`. Nothing in git will bring it back, so
keep a copy outside the repository if you need to regenerate. Playwright is
vendored in that directory already (`playwright@1.62.1`); do not add a dependency.

A full run prunes fixtures whose story no longer exists and rewrites
`_manifest.json`. A filtered run does neither, so a partial capture cannot
silently shrink the manifest.

Then:

```sh
cd packages/fluent_2
flutter test test/charts/oracle_b/ test/support/oracle_fixture_test.dart
```

**Never commit a re-capture you have not read the coverage report for.** The whole
value of the corpus is that a disagreement is a real finding; an unexamined
regeneration converts a caught bug into a committed fixture. That is the same rule
`test/goldens/README.md` states for `--update-goldens`.

3.17 MiB for 90 stories, measured — the largest single fixture is
`charts-linechart--line-chart-large-data.json` at 551 KB, and it is large because
the story is. The agreed ceiling is **8 MiB**, and `oracle_b_corpus_test.dart`
fails the suite above it — about twice the measurement, which is room for a story
that is legitimately richer and none for a capture that has started recording
something enormous. Keep it that way: coarsen what is captured rather than adding
megabytes of JSON, the same rule `test/goldens/README.md` applies to its ~256 KB
of images. Raising the ceiling is a decision, taken in the test and in this
sentence together.

## When the pin moves

`flutter test` has no network, so **CI verifies this corpus; it cannot regenerate
it.** Nothing here notices an upstream release on its own — the version pin does.
`oracle_b_corpus_test.dart` asserts the manifest reports exactly
`kPinnedUpstreamVersion`, which is 9.3.23, the release plan 01's d3 extractor pins
as well. Bump one pin without the other and that test fails, which is the whole
point: the alternative is a corpus that goes on asserting superseded geometry
indefinitely, in silence, while every consuming test stays green.

To move to a new upstream release, all five steps in one commit:

1. Bump `UPSTREAM_VERSION` in `crawlers/storybooks-fluentui/capture_oracle.mjs`.
2. Re-capture: `node capture_oracle.mjs` — all 90 stories, ~5-8 minutes.
3. Bump `kPinnedUpstreamVersion` in
   `test/charts/oracle_b/oracle_b_corpus_test.dart` to the same string.
4. Update the version in this README, and the sanity anchors below if the geometry
   moved.
5. Read the fixture diff and the coverage report before you commit. A geometry
   change is either an upstream change worth knowing about or a broken capture,
   and in a green test run those two look identical.

## Sanity anchors

Confirmed against the committed capture of `charts-areachart--area-chart-basic`,
and quoted in design spec §4.3:

| Property | Value |
|---|---|
| chart svg | 700 × 260, one svg, 128 elements, slot `fui-cart__chart` |
| x-axis group | `transform="translate(0, 205)"`, element 0 |
| x-axis domain path | `M64.5,6V0.5H680.5V6`, element 1 |
| first x tick group | `transform="translate(64.5,0)"`, absolute `(64.5, 205)` |
| tick line | `y2="6"`, stroke `rgb(36, 36, 36)`, `opacity: 0.2` |
| tick label | `"20"`, `y="16"`, 10 px, weight 600, `text-anchor: middle` |

And of `charts-sankeychart--sankey-chart-basic`: 820 × 412, 8 `linearGradient`
defs, 16 stops, the first running `rgb(227, 0, 140)` → `rgb(60, 81, 180)` over
offsets 0 → 100.

And of `charts-legends--legends-basic`: no *chart* svg at all — two
`fui-legend__shape` svgs of 19.799011 and 14 px, which is why the 14–19.8 px
legend shapes are not filtered out as icons, plus `fui-legend__root` at
`[24, 48, 944, 32]` with `fui-legend__rect` / `fui-legend__text` pairs.

And of the three HTML-only Legends stories — no svg whatsoever:

| Story | `width` × `height` | `htmlBoxes` | `fui-legend__rect` |
|---|---|---|---|
| `charts-legends--legends-overflow` | 944 × 32 | 35 | 17 recorded, **6 visible**, pitch 86.890625 from x 104, all at y 57 |
| `charts-legends--legends-styled` | 944 × 32 | 35 | 17 recorded, **7 visible**, pitch 86.890625 from x 104, all at y 57 |
| `charts-legends--legends-wrap-lines` | 944 × 120 | 53 | 17 recorded, **all 17 visible**, wrapped 8 / 7 / 2 over three rows at y 61 / 101 / 141, each row starting at x 108, inside a `fui-legend__resizableArea` of `[96, 48, 800, 120]` |

The row pitch in `legends-wrap-lines` is 40 px (61 → 101 → 141) and the item pitch
is **not uniform**: 94.890625 throughout row one, but 94.890625 then 101.359375
within row two, and 101.359375 on row three, because each row distributes its own
slack. Read the boxes; do not multiply a pitch.
