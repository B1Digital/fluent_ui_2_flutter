# Spec fixtures

Resolved numbers extracted from the official Fluent 2 Figma file, one JSON per
component set. `test/support/spec_fixture.dart` reads them; every component test
asserts against them.

## Why numbers and not golden images

Segoe UI is not installed in CI, and Skia's antialiasing does not match Figma's
renderer. A pixel diff would fail on machines that are perfectly correct, so
every component would ship with a stale golden and a `// TODO: regenerate`.

So we compare resolved numbers instead: size, padding, corner radius, stroke
width, ARGB fills, and text metrics. **Text is compared as font size and line
height only, never as a rendered glyph box** — which is why the label string in
a component test is irrelevant and no font has to be installed.

## Shape

```jsonc
{
  "component": "button",
  "source": {
    "fileKey": "Heyk4N9SnwfIzupHlk3l7s",
    "pageId":  "8911:3188",
    "nodeId":  "9026:430",     // the COMPONENT_SET
    "setName": "Button"
  },
  // Every variant property, in Figma's own order, " (Default)" stripped.
  "properties": {
    "Style":  ["Primary", "Secondary", "Outline", "Subtle", "Transparent"],
    "State":  ["Rest", "Hover", "Pressed", "Selected", "Disabled"],
    "Size":   ["Large", "Medium", "Small"],
    "Layout": ["Icon and label", "Icon only"]
  },
  // Component-scoped variables, resolved one hop — see "Aliases" below. `{}`
  // for a component that binds only Fluent tokens directly, such as Button.
  "aliases": { },
  "variants": [ /* one per line, sorted by name */ ]
}
```

One variant:

```jsonc
{
  "name":      "Style=Primary, State=Rest, Size=Medium, Layout=Icon and label",
  "figmaName": "Style=Primary, State=Rest, Size=Medium (Default), Layout=Icon and label (Default)",
  "nodeId":    "9026:1179",
  "props":     {"Style": "Primary", "State": "Rest", "Size": "Medium", "Layout": "Icon and label"},
  "size":      {"width": 94, "height": 32},
  "padding":   {"top": 6, "right": 12, "bottom": 6, "left": 12},
  "gap":       6,
  "radius":    4,
  "strokeWidth": 0,
  "fill":      "#FF0F6CBD",
  "stroke":    null,
  "text": {
    "fontFamily": "Segoe UI",
    "fontStyle":  "Semibold",
    "fontSize":   14,
    "lineHeight": 20,
    "tokens": {"fills": ["Neutral/Foreground/On Brand/Rest"], "fontSize": ["Typography/Font size/300"], "…": []}
  },
  "tokens": {
    "fills":         ["Brand/Background/1/Rest"],
    "radius":        ["Button/Container"],
    "paddingLeft":   ["Spacing/Horizontal/M"],
    "paddingTop":    ["Spacing/Vertical/SNudge"],
    "itemSpacing":   ["Spacing/Horizontal/SNudge"]
  },
  "parts": [ /* the children that actually draw — see below */ ]
}
```

### Field notes

| Field | Notes |
|---|---|
| `name` | Figma's ` (Default)` marker stripped, so a lookup reads `{'Size': 'Medium'}`. This string prefixes every failure message. |
| `figmaName` / `nodeId` | Untouched, so a disagreeing number can be traced straight back to the layer. |
| `size` | The frame size **with Figma's own placeholder content**. For a hug-content component only the height is a real constraint; pin your own content and assert height. |
| `padding` | Measured from the *outer* frame edge — see "Borders" below. |
| `gap` | Auto-layout `itemSpacing`. **Not asserted by `expectSpec`** — see below. |
| `radius` | A number when all four corners agree (always, so far); otherwise `{topLeft, topRight, bottomRight, bottomLeft}`. |
| `strokeWidth` | `0` when nothing is stroked, regardless of what Figma reports — see "Stroke width" below. A number when all four sides agree; otherwise `{top, right, bottom, left}`, which is what a split button's chevron half needs — three sides stroked and the fourth bare, because the divider is the other half's border. `SpecVariant.strokeWidth` is null in that case and `SpecVariant.strokeWidths` is always populated. |
| `fill` / `stroke` | `#AARRGGBB`, or `null` when the node carries no paint at all. |
| `text` | `null` for icon-only variants. `lineHeight` is in **pixels**, as Figma states it; Flutter's `TextStyle.height` is a multiplier, so use `SpecText.heightMultiplier`. |
| `tokens` | Always lists, even of one — Figma's `boundVariables` are genuinely per-property lists, and one shape means the Dart side never branches. `SpecVariant.token('fills')` returns the first. |
| `parts` | The children of the variant frame that actually draw. See below. A `TEXT` part also carries its own `text` block: `text` at the top level describes only the *first* text node, which is not enough for a component with two independently ramped lines. |

`tokens` is the half of the fixture that matters most. It names the exact Fluent
token to select, so nobody reverse-engineers `#0F6CBD` back into
`brandBackground1`, and nobody computes a hover colour from a rest colour.

The four identical `topLeftRadius` / `topRightRadius` / … keys are collapsed to
`radius`, and the four `strokeTopWeight` / … keys to `strokeWidth`. If they ever
genuinely disagree, all four survive under their original names.

## `parts` — the children that actually draw

The top-level fields above describe the **variant frame only**, and on plenty of
components that frame paints nothing at all. Divider is the clean example: every
pixel lives on two child `RECTANGLE` "Divider line" nodes and a child "Content"
`FRAME`, so the frame honestly reports `fill: null`, `strokeWidth: 0`,
`radius: 0`, `padding: 0`, `gap: 0` — six variants of nothing. Card, ListItem,
Menu, DataGrid, Nav and Tree are built the same way.

`parts` is the fix. Every variant carries a flat list of the nodes under it that
draw, so a component test can assert against the layer that produces the pixel:

```jsonc
"parts": [
  {
    "name":   "Divider line",   // Figma's layer name, untouched
    "nodeId": "9000:6133",
    "type":   "RECTANGLE",
    "depth":  1,                // 1 = direct child of the variant frame
    "size":        {"width": 8, "height": 1},
    "padding":     null,        // null, not 0 — see below
    "gap":         null,
    "radius":      0,
    "strokeWidth": 0,
    "fill":        "#FFE0E0E0",
    "stroke":      null,
    "tokens":      {"fills": ["Stroke color"]}
  },
  {
    "name": "Content", "nodeId": "9000:6134", "type": "FRAME", "depth": 1,
    "size": {"width": 45, "height": 20},
    "padding": {"top": 0, "right": 12, "bottom": 0, "left": 12},
    "gap": 6, "radius": 0, "strokeWidth": 0, "fill": null, "stroke": null,
    "tokens": {
      "itemSpacing": ["Spacing/Horizontal/SNudge"],
      "paddingLeft": ["Spacing/Horizontal/M"],
      "paddingRight": ["Spacing/Horizontal/M"]
    }
  }
]
```

Same field names and same meanings as the variant itself, plus `type` and
`depth`. `parts` is flat, in document order; `depth` is the only record of the
nesting, so read it rather than assuming siblings.

| Rule | Why |
|---|---|
| **Recorded when the node paints _or_ binds a variable.** | A visible fill or stroke makes a node worth specifying. So does a bound variable, even with no paint: the Divider's "Content" frame paints nothing yet owns the 12px inset and the 6px gap, which is exactly the number a test needs. |
| **Invisible or zero-opacity nodes are skipped, subtree and all.** | Nothing under them reaches a pixel. This is what keeps the Divider's hidden icon `Placeholder` out of the fixture. |
| **Depth is capped at 3.** | A variant frame holds a content frame (1) holding a label or icon instance (2) holding that icon's vector (3). Below that is artwork, not spec. Divider only reaches 2. The cap is `PART_DEPTH` in the extractor. `card.json` was extracted at depth **2**: its depth-3 parts are the interiors of the Button instances inside `.Card header` and `.Card footer`, which are Button's spec and are already pinned by `button.json`. Re-emit with `DEPTH = 2` to reproduce it. |
| **`padding`, `gap` and `radius` may be `null`.** | A `RECTANGLE` has no auto-layout and a `TEXT` has no corners. `null` means *this node has no such property*, which is a different claim from `0` and is not written as one. This holds on a **variant frame** too — Radio's `Icon only` frame is a bare wrapper around one child, so it states no padding and no gap, and the real 8-all-round inset lives on its `.RadioBase` part. `SpecVariant.padding` and `SpecVariant.gap` are therefore nullable, and `expectSpec` skips the padding assertion when they are null. |

`SpecVariant` does not expose `parts` yet, and neither `expectSpec` nor any
other resolver reads it — the fixture carries it, the Dart harness ignores it.
Today it is documentation you can trust: the numbers a component test hardcodes
(`FluentStroke.thin` for the rule, `FluentSpacing.s` for the stub,
`FluentSpacing.m` for the inset) are checkable against a named Figma node id
instead of against somebody's memory. Add a `SpecPart` to
`test/support/spec_fixture.dart` when a test wants to loop over them.

## Aliases — component-scoped variables resolved one hop

A fixture's `tokens` map does not always name a Fluent token. Divider binds
`Stroke color` and `Horizontal padding`, which are variables in **component-
scoped collections** — `Divider appearance` (modes Default / Subtle / Strong /
Brand) and `Divider padding` (Full / Inset). Those names exist nowhere in core,
so `"tokens": {"fills": ["Stroke color"]}` on its own is a dead end.

Each such variable is one alias hop from the real token, per mode. `aliases`
resolves that hop and keeps the local name as the key:

```jsonc
"aliases": {
  "Stroke color": {
    "collection": "Divider appearance",
    "modes": {
      "Default": "Neutral/Stroke/2/Rest",
      "Subtle":  "Neutral/Stroke/3/Rest",
      "Strong":  "Neutral/Stroke/1/Rest",
      "Brand":   "Brand/Stroke/1/Rest"
    }
  },
  "Horizontal padding": {
    "collection": "Divider padding",
    "modes": {"Full": "Spacing/Horizontal/None", "Inset": "Spacing/Horizontal/M"}
  }
}
```

That table *is* the component's API: those four modes are why `FluentDivider`
ships an `appearance` enum and an `inset` flag, and it names the token each one
must select. A mode holding a literal rather than an alias resolves to `null`.

A collection counts as component-scoped when the variant frame **pins its mode
explicitly**, which is how a designer configures a component-local collection.
The gate is deliberately not "does this variable alias anything": every Fluent
token aliases the global palette one hop further, and resolving those would turn
`Brand/Background/1/Rest` into `Colors/Brand/80`. A component that binds only
Fluent tokens directly — Button, Badge, Link — gets `"aliases": {}`.

Fixtures generated before `parts` and `aliases` existed have neither key.

## Things that will bite you

### Stroke width

Figma keeps whatever `strokeWeight` was last authored on a node **even when the
node has no stroke at all** — every Primary button reports `2` with an empty
`strokes` array. Recording that verbatim would spec a 2px border onto every
filled button, so the extractor reports `0` unless a stroke is actually painted.

### Transparent is a value, not an absence

Fluent's transparent tokens are real tokens with real values. Figma models
`Neutral/Background/Transparent/Rest` as white at 0% paint opacity, which the
extractor folds into the alpha channel: `#00FFFFFF`. It is **not**
`Colors.transparent` — in high contrast these tokens become opaque, so a
component must select the token, not hardcode a transparent colour.

### Borders and the box model

Figma measures `padding` from the outer frame edge and draws an inside stroke
*over* it, matching CSS `border-box`: on an Outline button, content starts 12px
from the edge, not 13.

Flutter is the other way round. `BoxDecoration.border` adds to a `Container`'s
effective padding, so `Container(padding: horizontal 12, decoration: … border
width 1)` starts content at 13 and `expectSpec` will report
`padding.left expected 12, got 13`. That failure is correct — subtract the
border, or paint it without letting it consume layout.

### Figma authoring slips, preserved

The fixture is faithful, not corrected. Two known oddities in the Button set:

- `Style=Transparent, State=Disabled` binds `Neutral/Stroke/Transparent/Rest`
  (a *stroke* token) as its **fill**, where every other Transparent state binds
  `Neutral/Background/Transparent/…`. Both resolve to `#00FFFFFF`, so nothing
  renders differently — but do not copy the token name.
- `Style=Subtle, State=Disabled` has no fill at all (`"fill": null`), not a
  transparent one.

### What `expectSpec` does not assert

`gap` is in the fixture but is not asserted, because there is no widget every
component is guaranteed to express spacing through — a `Row.spacing`, a
`SizedBox`, and a `CustomPaint` are all legitimate. Assert it against your own
layout widget:

```dart
expect(tester.widget<Row>(find.byType(Row)).spacing, variant.gap);
```

Same reasoning applies to any component that paints its surface with a
`CustomPaint` instead of a `DecoratedBox`: `expectSpec` reads the widget tree,
so such a component should use `surfaceColorOf` / `resolvedRadiusOf` /
`resolvedTextStyleOf` where it can and assert the rest directly.

## Regenerating

`tool/extract_component_spec.py` is a two-stroke engine, because the Figma
Plugin API is only reachable through the `use_figma` MCP tool and its response
is truncated at 20 KB.

1. Emit the read-only traversal, one call per chunk. Divider is six variants, so
   it is one chunk:

   ```sh
   python3 tool/extract_component_spec.py --emit-js \
     --page-id 8911:3192 --set-id 9000:6131 --start 0 --end 6
   ```

   Button needs six chunks of 25:

   ```sh
   for s in 0 25 50 75 100 125; do
     python3 tool/extract_component_spec.py --emit-js \
       --page-id 8911:3188 --set-id 9026:430 --start $s --end $((s+25))
   done
   ```

   **Pick the chunk size against the response, not the variant count.** 25 was
   measured before `parts` existed; a variant that carries four painted parts is
   several times heavier. If a response comes back truncated, halve the
   `--start`/`--end` window and re-emit — `--build` will refuse anyway if a
   chunk goes missing.

2. Run each through `use_figma` (file key `Heyk4N9SnwfIzupHlk3l7s`, load the
   `figma-use` skill first) and save each returned JSON to its own file. The
   traversal only reads — it never writes to the Figma file.

3. Merge, validate and write:

   ```sh
   python3 tool/extract_component_spec.py --build \
     --component divider --raw raw-*.json \
     --out packages/fluent_2_web/test/fixtures/divider.json
   ```

   `--build` refuses to write if a chunk is missing, if ranges overlap, if the
   chunks come from different component sets, if any value came back as
   `figma.mixed`, if a node stacks more than one fill or stroke, if a variant
   frame reports no padding at all, or if a text layer lost its explicit pixel
   line height.

4. Run the tests. `test/support/spec_fixture_test.dart` asserts the sanity
   anchors below on every run — if the component set moved or was re-authored,
   that is what catches it before 150 component tests start lying.

### Sanity anchors

Confirmed against a live Figma read of Button
`Style=Primary, State=Rest, Size=Medium, Layout=Icon and label`:

| Property | Value |
|---|---|
| size | 94 × 32 |
| padding | 6 / 12 / 6 / 12 |
| gap | 6 |
| radius | 4 |
| fill | `#FF0F6CBD` (`Brand/Background/1/Rest`) |
| text | Segoe UI Semibold 14 / 20 |

And of Divider, whose numbers all live in `parts` — the variant frame's own
fields are genuinely all zero and null:

| Property | Value |
|---|---|
| rule thickness | 1 on every variant, both rules (`Divider line`, node 9000:6133) |
| rule colour | `#FFE0E0E0`, bound to `Stroke color` → `Neutral/Stroke/2/Rest` in mode Default |
| short rule | 8 on the leading rule for `Layout=Start`, on the trailing rule for `Layout=End`, equal on `Center` |
| content inset | 12 (`Content` frame, `Spacing/Horizontal/M`; `Spacing/Vertical/M` when vertical) |
| content gap | 6 (`Spacing/Horizontal/SNudge`) |
| text | Segoe UI Regular 12 / 16 |
