#!/usr/bin/env python3
"""Merge the per-collection Figma variable dumps into one resolved token file.

The `Mode` collection (alias layer) stores its values as references into the
` Global` collection rather than as literals, so a raw dump is unusable for
porting. This walks those references to their leaves and emits a flat file
where every value is a concrete hex string or number.

Inputs  (produced by the MCP extraction, one per collection chunk):
    figma_mode.json               Mode              359 vars, Light/Dark
    figma_global_core.json        ' Global'         163 vars, single 'Value' mode
    figma_global_shared.json      ' Global'         588 vars, single 'Value' mode
    figma_shape_layout_brand.json Shape/Layout/' Brand'

Output:
    figma_tokens.json  {collection: {var: {mode: value}}} with aliases resolved,
                       plus a "_unresolved" list that MUST be empty.

Run:  python3 packages/fluent_2_core/tool/merge_figma_tokens.py
"""

import json
import pathlib
import sys

HERE = pathlib.Path(__file__).parent
MAX_ALIAS_DEPTH = 16


def load(name):
    with open(HERE / name) as f:
        return json.load(f)


def collect_sources():
    """Return {collection_name: {var_name: {mode: raw_value}}}."""
    out = {}

    for fname in ("figma_mode.json", "figma_global_core.json",
                  "figma_global_shared.json"):
        d = load(fname)
        coll = d["collection"]
        out.setdefault(coll, {})
        for name, entry in d["variables"].items():
            out[coll][name] = entry["values"]

    multi = load("figma_shape_layout_brand.json")
    for coll, d in multi.items():
        out.setdefault(coll, {})
        for name, entry in d.get("variables", {}).items():
            out[coll][name] = entry["values"]

    return out


# The token layers, most semantic first. An alias resolves ONLY into a layer
# strictly below its own, which is what disambiguates the deliberate name
# collisions: Layout defines `Corner radius/None` whose value is an alias to the
# identically-named primitive in ' Global', and Layout's semantic
# `Corner radius/Medium` is what Shape references rather than Global's numeric
# `Corner radius/40`. A flat all-collections index resolves the first to itself
# and cycles; a primitives-only index cannot find the second at all.
LAYER_ORDER = ("Mode", "Shape", "Layout", " Global", " Brand")


def build_index(sources):
    """(collection, name) lookup plus the layer rank used to pick a target."""
    for coll in sources:
        if coll not in LAYER_ORDER:
            print(f"FAIL: collection {coll!r} has no declared layer rank; add it "
                  f"to LAYER_ORDER", file=sys.stderr)
            sys.exit(1)
    return {coll: sources[coll] for coll in LAYER_ORDER if coll in sources}


def find_target(name, from_coll, index):
    """First collection strictly below `from_coll` that defines `name`."""
    start = LAYER_ORDER.index(from_coll) + 1
    for coll in LAYER_ORDER[start:]:
        if coll in index and name in index[coll]:
            return coll, index[coll][name]
    return None, None


def resolve(value, mode, from_coll, index, unresolved, trail):
    """Follow alias references down the layers to a literal.

    An alias may point at a variable whose own collection has different mode
    names (Mode has Light/Dark, ' Global' has only 'Value'), so fall back to the
    target's single mode when the requested one is absent.
    """
    depth = 0
    while isinstance(value, dict) and "alias" in value:
        depth += 1
        if depth > MAX_ALIAS_DEPTH:
            unresolved.append({"trail": trail, "reason": "alias cycle or too deep"})
            return None
        target_name = value["alias"]
        target_coll, target = find_target(target_name, from_coll, index)
        if target is None:
            unresolved.append(
                {"trail": trail,
                 "reason": f"no collection below {from_coll!r} defines "
                           f"{target_name!r}"})
            return None
        trail = f"{trail} -> {target_coll}/{target_name}"
        from_coll = target_coll
        if mode in target:
            value = target[mode]
        elif len(target) == 1:
            value = next(iter(target.values()))
        else:
            unresolved.append(
                {"trail": trail, "reason": f"mode {mode!r} absent in target, "
                                           f"has {list(target)}"})
            return None
    return value


def main():
    sources = collect_sources()
    index = build_index(sources)
    unresolved = []

    resolved = {}
    for coll, vars_ in sources.items():
        resolved[coll] = {}
        for name, modes in vars_.items():
            resolved[coll][name] = {
                mode: resolve(raw, mode, coll, index, unresolved,
                              f"{coll}/{name}[{mode}]")
                for mode, raw in modes.items()
            }

    resolved["_unresolved"] = unresolved

    out = HERE / "figma_tokens.json"
    with open(out, "w") as f:
        json.dump(resolved, f, indent=2, sort_keys=True)
        f.write("\n")

    total = sum(len(v) for k, v in resolved.items() if k != "_unresolved")
    print(f"wrote {out.name}: {total} variables across "
          f"{len(resolved) - 1} collections")
    for coll, vars_ in resolved.items():
        if coll != "_unresolved":
            print(f"  {coll!r}: {len(vars_)}")

    if unresolved:
        print(f"\nFAIL: {len(unresolved)} unresolved references", file=sys.stderr)
        for u in unresolved[:10]:
            print(f"  {u['trail']}: {u['reason']}", file=sys.stderr)
        return 1

    print("\nall alias references resolved to literals")
    return 0


if __name__ == "__main__":
    sys.exit(main())
