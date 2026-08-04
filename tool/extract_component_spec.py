#!/usr/bin/env python3
"""Extract a Fluent component set from Figma into a pixel-fidelity spec fixture.

We do not diff golden images: Segoe UI is not installed in CI and Skia's
antialiasing does not match Figma's renderer, so a glyph-level diff would be
permanently flaky. Instead we assert *resolved numbers* — sizes, paddings,
radii, stroke widths, ARGB fills, and text metrics — pulled straight out of the
Figma document.

This script cannot call Figma on its own. The Figma Plugin API is only reachable
through the `use_figma` MCP tool, which runs JavaScript inside the file. So the
tool is a two-stroke engine:

  1. `--emit-js` prints the traversal to run through `use_figma`. The agent (or
     a human with the plugin console) runs it and saves the returned JSON.
  2. `--build` merges those raw chunks, expands the compact wire format into the
     readable fixture shape, validates it, and writes `<component>.json`.

Each variant carries the numbers of its own frame *and* a `parts` list: the
children under it that actually draw. Reading only the frame is not enough — a
Divider paints nothing on its own frame, so it extracted as all-null until the
traversal learned to walk down. See `PART_DEPTH` below.

Chunking is not optional: the MCP response is truncated at 20 KB, which is about
25 Button variants even with the compact wire format. `parts` makes a variant
several times heavier, so a deep component needs a much smaller chunk — shrink
the `--start`/`--end` window until the response comes back whole. Run
`--emit-js` once per chunk and pass every chunk to `--build`.

Regenerating the Button fixture (150 variants, 6 chunks of 25):

    for s in 0 25 50 75 100 125; do
      python3 tool/extract_component_spec.py --emit-js \\
        --page-id 8911:3188 --set-id 9026:430 --start $s --end $((s+25))
    done
    # run each through use_figma, save the returned JSON as raw-0.json ...
    python3 tool/extract_component_spec.py --build \\
      --component button --raw raw-*.json \\
      --out packages/fluent_2_web/test/fixtures/button.json

READ-ONLY. The emitted JavaScript never writes to the Figma file.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import sys

FILE_KEY = "Heyk4N9SnwfIzupHlk3l7s"

# Figma marks the default value of a variant property with a " (Default)"
# suffix, so the same variant is called "Medium (Default)" here and "Medium"
# everywhere else. Strip it: a fixture lookup should read
# `{'Size': 'Medium'}`, not `{'Size': 'Medium (Default)'}`. The untouched Figma
# name is kept on every row as `figmaName` so a disagreement can be traced back.
DEFAULT_SUFFIX = " (Default)"

# Keys the traversal collapses when all four corners/sides agree, which they do
# on every Fluent component shipped so far. If one ever disagrees the four
# original keys survive untouched rather than being averaged into a lie.
_CORNER_KEYS = ("topLeftRadius", "topRightRadius", "bottomLeftRadius", "bottomRightRadius")
_STROKE_KEYS = ("strokeTopWeight", "strokeRightWeight", "strokeBottomWeight", "strokeLeftWeight")

# How far under each variant frame the traversal looks for painted parts.
#
# Reading only the variant frame is not enough: a Divider paints nothing on its
# own frame — the rule is a child RECTANGLE and the 12px inset lives on a child
# FRAME — so the fixture came back all-null and useless. Card, ListItem, Menu,
# DataGrid, Nav and Tree are built the same way.
#
# 3 is where every Fluent component shipped so far stops saying anything: a
# variant frame holds a content frame (1) holding a label or an icon instance
# (2) holding that icon's vector (3). Below that is artwork, not spec. Depth is
# recorded on every part so a reader can see the nesting in a flat list.
PART_DEPTH = 3

# The traversal below is validated against the Button set (component set
# 9026:430, 150 variants). It returns a COMPACT wire format — single-letter keys,
# hex colours, positional arrays — purely to fit inside the 20 KB MCP response
# limit. `--build` expands it into the readable fixture. Do not hand-edit the
# expanded output; regenerate it.
TRAVERSAL_JS = """\
const page = await figma.getNodeByIdAsync('{page_id}');
await figma.setCurrentPageAsync(page);
const set = await figma.getNodeByIdAsync('{set_id}');
const START = {start}, END = {end}, DEPTH = {part_depth};

const cache = new Map();
// Every variable id the traversal touched, and every collection whose mode this
// component pins on itself. Together they find the component-scoped variables
// worth resolving one hop further — see the alias pass at the bottom.
const seenVars = new Set();
const localColls = new Set();

async function varName(id) {{
  if (!cache.has(id)) {{
    const v = await figma.variables.getVariableByIdAsync(id);
    cache.set(id, v ? v.name : id);
  }}
  return cache.get(id);
}}

// Every bound variable, resolved from opaque VariableID to its human name. This
// is the payload a component author actually needs: it names the exact Fluent
// token to reach for, so nobody has to reverse-engineer #0F6CBD back into
// brandBackground1.
async function tokensOf(node) {{
  const out = {{}};
  for (const [k, ref] of Object.entries(node.boundVariables || {{}})) {{
    const refs = Array.isArray(ref) ? ref : [ref];
    const names = [];
    for (const r of refs) if (r && r.id) {{ seenVars.add(r.id); names.push(await varName(r.id)); }}
    out[k] = names;
  }}
  // Collapse the four identical corner/side keys, then unwrap single-element
  // arrays. Both are pure size reductions to stay under the response limit.
  const fold = (keys, name) => {{
    const vals = keys.map(k => out[k]);
    if (vals.some(v => v === undefined)) return;
    const first = JSON.stringify(vals[0]);
    if (!vals.every(v => JSON.stringify(v) === first)) return;
    for (const k of keys) delete out[k];
    out[name] = vals[0];
  }};
  fold({corner_keys}, 'radius');
  fold({stroke_keys}, 'strokeWidth');
  for (const k of Object.keys(out)) if (out[k].length === 1) out[k] = out[k][0];
  return out;
}}

// figma.mixed is a Symbol and would silently vanish through JSON. Surface it as
// a string so --build can refuse to write a fixture built on a guess.
const n = x => (typeof x === 'symbol' ? 'MIXED' : x);

// Figma nodes are proxies that throw on properties their type does not carry —
// a RECTANGLE has no itemSpacing, a TEXT has no cornerRadius. Every optional
// property is read through here so the walker never needs a type table.
const get = (node, key, dflt) => {{
  try {{ const value = node[key]; return value === undefined ? dflt : value; }}
  catch (e) {{ return dflt; }}
}};

const hx = v => Math.round(v * 255).toString(16).toUpperCase().padStart(2, '0');
// Figma keeps paint alpha in `opacity`, separate from the RGB triple. Fold it
// into the ARGB word so the fixture carries one comparable number. A fully
// transparent Fluent token is a real token with a real value (#00FFFFFF) — it
// is NOT Colors.transparent, and in high contrast it turns opaque.
function argb(paints) {{
  if (paints === 'MIXED' || !paints) return null;
  for (const p of paints) {{
    if (p.type !== 'SOLID' || p.visible === false) continue;
    const a = p.opacity === undefined ? 1 : p.opacity;
    return '#' + hx(a) + hx(p.color.r) + hx(p.color.g) + hx(p.color.b);
  }}
  return null;
}}

// One node's geometry in the compact wire format. Shared by the variant frame
// and by every painted part under it, so both are validated by the same code.
async function geom(node) {{
  const rawFills = get(node, 'fills', []);
  const rawStrokes = get(node, 'strokes', []);
  const fills = typeof rawFills === 'symbol' ? 'MIXED' : rawFills;
  const strokes = typeof rawStrokes === 'symbol' ? 'MIXED' : rawStrokes;
  // strokeWeight is whatever was last authored even when the node has no stroke
  // at all — a Primary button reports 2 with an empty strokes array. Reporting
  // that verbatim would spec a 2px border onto every filled button, so the
  // width is zero unless a stroke is actually painted.
  //
  // `strokeWeight` is figma.mixed exactly when the four sides disagree, which is
  // not an edge case: a split button's chevron half is stroked on three sides
  // and bare on the fourth, because the divider is the OTHER half's border. A
  // node like that is emitted as [top, right, bottom, left] rather than refused.
  const uni = n(get(node, 'strokeWeight', 0));
  const sides = ['strokeTopWeight', 'strokeRightWeight', 'strokeBottomWeight', 'strokeLeftWeight']
    .map(k => n(get(node, k, uni)));
  const sw = (strokes === 'MIXED' || strokes.length === 0) ? 0 : (uni === 'MIXED' ? sides : uni);
  // Padding and gap exist only on an auto-layout frame; radius only on a shape.
  // null means "this node has no such property", which is not the same claim as
  // zero and must not be written into the fixture as one.
  const auto = get(node, 'layoutMode', 'NONE') !== 'NONE';
  const tl = get(node, 'topLeftRadius', null);
  return {{
    s: [node.width, node.height],
    p: auto ? [node.paddingTop, node.paddingRight, node.paddingBottom, node.paddingLeft] : null,
    g: auto ? node.itemSpacing : null,
    r: tl === null ? null : [n(tl), n(get(node, 'topRightRadius', 0)),
                             n(get(node, 'bottomRightRadius', 0)), n(get(node, 'bottomLeftRadius', 0))],
    w: sw,
    f: argb(fills),
    k: argb(strokes),
    // Fill/stroke counts let --build refuse a component that stacks paints,
    // where a single resolved colour would be a fiction.
    c: [fills === 'MIXED' ? -1 : fills.length, strokes === 'MIXED' ? -1 : strokes.length],
    v: await tokensOf(node),
  }};
}}

// Walk the variant subtree and record the children that actually draw.
//
// A node is worth recording when it paints (a visible fill or stroke) OR when
// it binds a variable — the Divider's "Content" frame paints nothing at all yet
// carries the 12px inset and the label gap, which is exactly the number a
// component test needs. Everything else is skipped so the fixture stays small.
//
// An invisible node, or one at zero opacity, is skipped along with its whole
// subtree: nothing under it reaches a pixel.
async function partsOf(root) {{
  const parts = [];
  const walk = async (node, depth) => {{
    if (depth > DEPTH || node.visible === false || get(node, 'opacity', 1) === 0) return;
    for (const k of Object.keys(get(node, 'explicitVariableModes', {{}}))) localColls.add(k);
    const fills = get(node, 'fills', []);
    const strokes = get(node, 'strokes', []);
    const paints = typeof fills === 'symbol' || typeof strokes === 'symbol'
      || fills.some(p => p.visible !== false) || strokes.some(p => p.visible !== false);
    if (paints || Object.keys(node.boundVariables || {{}}).length > 0) {{
      const part = Object.assign({{ n: node.name, i: node.id, y: node.type, d: depth }}, await geom(node));
      // A TEXT part carries its own ramp: a component with two independently
      // ramped lines is not described by the variant's first text node alone.
      if (node.type === 'TEXT') {{
        const plh = n(node.lineHeight), pfn = n(node.fontName);
        part.t = [n(node.fontSize), plh && plh.unit === 'PIXELS' ? plh.value : null,
                  pfn === 'MIXED' ? 'MIXED' : pfn.family, pfn === 'MIXED' ? 'MIXED' : pfn.style,
                  await tokensOf(node)];
      }}
      parts.push(part);
    }}
    for (const c of get(node, 'children', [])) await walk(c, depth + 1);
  }};
  for (const c of get(root, 'children', [])) await walk(c, 1);
  return parts;
}}

const rows = [];
for (const v of set.children.slice(START, END)) {{
  for (const k of Object.keys(get(v, 'explicitVariableModes', {{}}))) localColls.add(k);
  const t = v.findAllWithCriteria({{ types: ['TEXT'] }})[0];
  const fn = t ? n(t.fontName) : null;
  const lh = t ? n(t.lineHeight) : null;
  rows.push(Object.assign({{ n: v.name, i: v.id }}, await geom(v), {{
    // Text is size + line height + family + style only. Never a glyph box:
    // Segoe UI is absent from CI and Skia will not reproduce Figma's raster.
    t: t ? [n(t.fontSize), lh && lh.unit === 'PIXELS' ? lh.value : null,
            fn === 'MIXED' ? 'MIXED' : fn.family, fn === 'MIXED' ? 'MIXED' : fn.style,
            await tokensOf(t)] : null,
    x: await partsOf(v),
  }}));
}}

// A component-scoped variable is one from a collection whose MODE the component
// pins on itself — Divider's `Stroke color` (collection "Divider appearance")
// and `Horizontal padding` (collection "Divider padding"). Those names mean
// nothing outside this one component set: each is an alias, one hop, to the
// real Fluent token. Resolve the hop per mode so the fixture names a token a
// reader can find in core, keyed by the local name so both survive.
//
// The gate is deliberately the pinned mode and not "does this variable alias
// anything": every Fluent token aliases the global palette one hop further, and
// resolving those would turn `Brand/Background/1/Rest` into `Colors/Brand/80`.
//
// Matched on the collection NAME, not its id: Figma hands out two different id
// encodings for one collection — `explicitVariableModes` keys it by the long
// library form (`VariableCollectionId:<hash>/320758:36`) and a variable by the
// short local one (`VariableCollectionId:9002:374`) — so comparing ids finds
// nothing and silently returns no aliases at all.
const collCache = new Map();
async function collection(id) {{
  if (!collCache.has(id)) collCache.set(id, await figma.variables.getVariableCollectionByIdAsync(id));
  return collCache.get(id);
}}

const localNames = new Set();
for (const id of localColls) {{
  const c = await collection(id);
  if (c) localNames.add(c.name);
}}

const aliases = {{}};
for (const id of seenVars) {{
  const va = await figma.variables.getVariableByIdAsync(id);
  if (!va || aliases[va.name]) continue;
  const coll = await collection(va.variableCollectionId);
  if (!coll || !localNames.has(coll.name)) continue;
  const modes = {{}};
  for (const m of coll.modes) {{
    const value = va.valuesByMode[m.modeId];
    // null: the mode holds a literal, so there is no Fluent token to name.
    modes[m.name] = (value && value.type === 'VARIABLE_ALIAS') ? await varName(value.id) : null;
  }}
  aliases[va.name] = {{ collection: coll.name, modes }};
}}

return {{
  fileKey: '{file_key}',
  pageId: '{page_id}',
  nodeId: '{set_id}',
  setName: set.name,
  properties: set.variantGroupProperties,
  total: set.children.length,
  range: [START, END],
  aliases,
  rows,
}};
"""


def emit_js(page_id: str, set_id: str, start: int, end: int, part_depth: int = PART_DEPTH) -> str:
    """Render the read-only traversal for one chunk of variants.

    `part_depth` overrides how far under the variant frame the walk goes. The
    Slider needed 4: its progress fill and thumb disc — the two nodes carrying
    the brand tokens — sit one level below where 3 stops.
    """
    return TRAVERSAL_JS.format(
        page_id=page_id,
        set_id=set_id,
        start=start,
        end=end,
        file_key=FILE_KEY,
        part_depth=part_depth,
        corner_keys=json.dumps(list(_CORNER_KEYS)),
        stroke_keys=json.dumps(list(_STROKE_KEYS)),
    )


def strip_default(value: str) -> str:
    """Drop Figma's " (Default)" marker from a variant property value."""
    return value[: -len(DEFAULT_SUFFIX)] if value.endswith(DEFAULT_SUFFIX) else value


def parse_props(figma_name: str) -> dict[str, str]:
    """Split "Style=Primary, State=Rest" into a property map, defaults stripped."""
    props = {}
    for part in figma_name.split(", "):
        key, _, value = part.partition("=")
        props[key.strip()] = strip_default(value.strip())
    return props


def check_no_mixed(value: object, where: str) -> None:
    """Refuse to write a fixture containing an unresolved figma.mixed value."""
    if value == "MIXED":
        raise SystemExit(
            f"{where}: Figma reports this property as mixed. A single number "
            f"cannot describe it — extend the traversal to emit the per-side "
            f"values before regenerating."
        )


def geometry(row: dict, where: str) -> dict:
    """Expand the numeric block a variant frame and a painted part share.

    `padding`, `gap` and `radius` come back as null for a node that has no such
    property — a RECTANGLE has no auto-layout, a TEXT has no corners. That is a
    different claim from zero and is written as a different value.
    """
    stroke_width = row["w"]
    if isinstance(stroke_width, list):
        for value, label in zip(stroke_width, ("top", "right", "bottom", "left")):
            check_no_mixed(value, f"{where}: strokeWidth.{label}")
        top, right, bottom, left = stroke_width
        stroke_width = {"top": top, "right": right, "bottom": bottom, "left": left}
    else:
        check_no_mixed(stroke_width, f"{where}: strokeWidth")
    check_no_mixed(row["g"], f"{where}: gap")
    corners = row["r"]
    if corners is not None:
        for corner, label in zip(corners, ("topLeft", "topRight", "bottomRight", "bottomLeft")):
            check_no_mixed(corner, f"{where}: radius.{label}")

    fill_count, stroke_count = row["c"]
    if fill_count < 0 or stroke_count < 0:
        raise SystemExit(
            f"{where}: Figma reports mixed paints on this node, so neither the "
            f"resolved colour nor the paint count can be trusted. Split the "
            f"node in Figma or extend the traversal before regenerating."
        )
    if fill_count > 1 or stroke_count > 1:
        raise SystemExit(
            f"{where}: {fill_count} fills / {stroke_count} strokes. The "
            f"fixture stores one resolved colour each; stacked paints need a "
            f"richer shape before this component can be extracted."
        )

    radius = None
    if corners is not None:
        tl, tr, br, bl = corners
        # Uniform corners collapse to a single number, which is what every
        # Fluent component uses and what a human reading the fixture expects.
        radius = tl if tl == tr == br == bl else {"topLeft": tl, "topRight": tr, "bottomRight": br, "bottomLeft": bl}

    return {
        "size": {"width": row["s"][0], "height": row["s"][1]},
        "padding": None
        if row["p"] is None
        else {"top": row["p"][0], "right": row["p"][1], "bottom": row["p"][2], "left": row["p"][3]},
        "gap": row["g"],
        "radius": radius,
        "strokeWidth": stroke_width,
        "fill": row["f"],
        "stroke": row["k"],
    }


def expand_part(row: dict, where: str) -> dict:
    """Expand one painted child of a variant."""
    out = {"name": row["n"], "nodeId": row["i"], "type": row["y"], "depth": row["d"]}
    out.update(geometry(row, f"{where} > {row['n']}"))
    out["tokens"] = relist(row["v"])
    # A TEXT part carries its own ramp. The variant-level `text` block describes
    # only the FIRST text node found, which is not enough for a component with
    # two independently ramped lines — a compound button's second line is a
    # different size, weight and colour from its first.
    if row.get("t") is not None:
        out["text"] = expand_text(row["t"], f"{where} > {row['n']}")
    return out


def expand_text(row: list, where: str) -> dict:
    """Expand the shared text block of a variant or of a TEXT part."""
    size, line_height, family, style, tokens = row
    check_no_mixed(size, f"{where}: text.fontSize")
    check_no_mixed(family, f"{where}: text.fontFamily")
    if line_height is None:
        raise SystemExit(
            f"{where}: text line height is not in pixels. Fluent "
            f"specifies it explicitly; an AUTO line height means the Figma "
            f"layer lost its type style."
        )
    return {
        "fontFamily": family,
        "fontStyle": style,
        "fontSize": size,
        "lineHeight": line_height,
        "tokens": relist(tokens),
    }


def expand(row: dict) -> dict:
    """Expand one compact wire row into the readable fixture shape."""
    figma_name = row["n"]
    props = parse_props(figma_name)
    name = ", ".join(f"{k}={v}" for k, v in props.items())

    # `padding` stays null when the variant frame carries no auto-layout — a
    # Radio "Icon only" frame is a bare wrapper around one child, and claiming
    # zero padding for it would be a different statement from "there is none".
    # The Dart side reads `SpecVariant.padding` as nullable and skips the
    # assertion; the real inset lives on the child, in `parts`.
    geom = geometry(row, figma_name)

    out: dict = {
        "name": name,
        "figmaName": figma_name,
        "nodeId": row["i"],
        "props": props,
        **geom,
        "text": None,
        "tokens": relist(row["v"]),
    }

    if row["t"] is not None:
        out["text"] = expand_text(row["t"], figma_name)
    if "x" not in row:
        # An empty `parts` would read as "nothing under this variant paints",
        # which for most components is false. A chunk captured before the
        # subtree walk existed cannot say either way, so it says nothing.
        raise SystemExit(
            f"{figma_name}: this raw chunk predates `parts`. Re-emit the "
            f"traversal with --emit-js, run it through use_figma again, and "
            f"build from the new chunks."
        )
    out["parts"] = [expand_part(p, name) for p in row["x"]]
    return out


def relist(tokens: dict) -> dict:
    """Re-wrap the wire format's unwrapped single tokens back into lists.

    Figma's `boundVariables` are genuinely per-property lists (a node can carry
    one alias per fill). Keeping one shape means the Dart side never branches on
    `String` vs `List`.
    """
    return {k: (v if isinstance(v, list) else [v]) for k, v in tokens.items()}


def build(component: str, raw_paths: list[pathlib.Path], out_path: pathlib.Path) -> None:
    """Merge raw chunks into the fixture and validate before writing."""
    chunks = [json.loads(p.read_text()) for p in raw_paths]
    if not chunks:
        raise SystemExit("--build needs at least one --raw chunk")

    head = chunks[0]
    for chunk, path in zip(chunks, raw_paths):
        if chunk["nodeId"] != head["nodeId"]:
            raise SystemExit(f"{path}: node {chunk['nodeId']} != {head['nodeId']} — chunks are from different component sets")

    rows = [row for chunk in chunks for row in chunk["rows"]]
    variants = sorted((expand(r) for r in rows), key=lambda v: v["name"])

    names = [v["name"] for v in variants]
    duplicates = {n for n in names if names.count(n) > 1}
    if duplicates:
        raise SystemExit(f"duplicate variants across chunks: {sorted(duplicates)} — the --start/--end ranges overlap")
    if len(variants) != head["total"]:
        raise SystemExit(
            f"got {len(variants)} variants but the set has {head['total']} — "
            f"a chunk is missing. Ranges covered: "
            f"{sorted(tuple(c['range']) for c in chunks)}"
        )

    fixture = {
        "component": component,
        "source": {
            "fileKey": head["fileKey"],
            "pageId": head["pageId"],
            "nodeId": head["nodeId"],
            "setName": head["setName"],
        },
        "properties": {
            key: [strip_default(v) for v in spec["values"]]
            for key, spec in head["properties"].items()
        },
        # Component-scoped variables resolved one hop to the Fluent token they
        # alias, per mode. Chunks cannot disagree: a variable's modes are a
        # property of the file, not of the range of variants that was walked.
        "aliases": {k: v for chunk in chunks for k, v in chunk.get("aliases", {}).items()},
        "variants": variants,
    }
    out_path.write_text(dump(fixture))
    print(f"{out_path}: {len(variants)} variants", file=sys.stderr)


def dump(fixture: dict) -> str:
    """Serialise the fixture with one variant per line.

    Fully pretty-printing 150 variants spreads every single-element token list
    over three lines, so a regeneration after a Figma change lands as thousands
    of diff lines nobody reads. One variant per line means one changed variant
    is one changed line.
    """
    variants = fixture.pop("variants")
    head = json.dumps(fixture, indent=2)  # ends with "\n}"
    rows = ",\n    ".join(json.dumps(v) for v in variants)
    return f'{head[:-2]},\n  "variants": [\n    {rows}\n  ]\n}}\n'


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--emit-js", action="store_true", help="print the read-only traversal for one chunk")
    mode.add_argument("--build", action="store_true", help="merge raw chunks into a fixture")

    parser.add_argument("--page-id", default="8911:3188", help="Figma page node id (default: the Button page)")
    parser.add_argument("--set-id", default="9026:430", help="Figma component set node id (default: Button)")
    parser.add_argument("--start", type=int, default=0, help="first variant index in this chunk")
    parser.add_argument("--end", type=int, default=25, help="one past the last variant index (25 keeps a chunk under the 20 KB MCP response limit)")
    parser.add_argument("--part-depth", type=int, default=PART_DEPTH, help=f"how deep under each variant to record painted parts (default {PART_DEPTH}; Slider needs 4)")

    parser.add_argument("--component", help="fixture name, e.g. button")
    parser.add_argument("--raw", nargs="+", type=pathlib.Path, help="raw chunk JSON returned by use_figma")
    parser.add_argument("--out", type=pathlib.Path, help="fixture path to write")

    args = parser.parse_args()
    if args.emit_js:
        print(emit_js(args.page_id, args.set_id, args.start, args.end, args.part_depth))
        return
    if not (args.component and args.raw and args.out):
        raise SystemExit("--build needs --component, --raw and --out")
    build(args.component, args.raw, args.out)


if __name__ == "__main__":
    main()
