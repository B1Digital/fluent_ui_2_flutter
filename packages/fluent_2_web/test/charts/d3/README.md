# d3 golden vectors

`d3_golden.json` is **Oracle A** from the charts design (`§4.2`): the outputs of
the real Node d3 modules, dumped once and committed, so the Dart port under
`lib/src/charts/internal/d3/` can be diffed against them instead of against a
reading of the JavaScript.

## Why it is committed before any Dart

The three highest risks in the whole chart port are silent wrong-answer bugs
that no code review catches and every axis in the library sits on:

1. `Math.log10` is exact at decade boundaries; `math.log(1000) / math.ln10` is
   `2.9999999999999996`.
2. JS `Math.round` is half-**up**; Dart's `num.round()` is half-away-from-zero.
   They disagree on every negative `.5`.
3. `d3.ticks` stores a **negated reciprocal** in the fractional branch and
   divides by it (`d3-array/src/ticks.js:12-17,40`). A port that multiplies by a
   fractional step differs in the last ulp on almost every chart.

The vector that pins risk 3 is `ticks(0.001, 0.009, 4)`: d3 stores
`inc = -500` and emits `3 / 500 == 0.006`, where a port multiplying by
`tickStep == 0.002` emits `0.006000000000000001`.

## Regeneration

The generator is **not** in git: `crawlers/` is gitignored (`.gitignore:45`),
the same position the repository takes on `test/fixtures`' scrapers. Keep a copy
outside the repository if you need it.

```bash
cd crawlers/d3-golden && npm install && node generate.mjs
```

Pinned versions, asserted by the generator and by
`golden_support_test.dart`: d3-array 3.2.4, d3-color 3.1.0, d3-format 3.1.2,
d3-interpolate 3.0.1, d3-path 3.1.0, d3-sankey 0.12.3, d3-scale 4.0.2,
d3-shape 3.2.0, d3-time 3.1.0, d3-time-format **3.0.0**.

d3-time-format is pinned at 3.0.0 rather than the 4.1.0 that npm resolves by
default, because `@fluentui/react-charts` declares `^3.0.0`. Design spec §11
open item 1 raised this; the corpus closes it.

`d3-scale` 4.0.2 declares `d3-time-format: "2 - 4"`, so npm dedupes it onto the
same 3.0.0 and the `scaleTime` vectors' `tickFormat` output is produced by
3.0.0 as well — the corpus is internally consistent on that point. The only
version skew inside the tree is transitive and behaviourally inert:
`d3-time-format` 3.0.0 carries its own `d3-time` 2.1.1 (used for `%j`, `%U`,
`%V`, `%W` day and week counting) and `d3-sankey` 0.12.3 carries `d3-shape`
1.3.7 plus `d3-array` 2.12.1 (used only for `min`, `max`, `sum`).

## Encoding

JSON has no `NaN` or `Infinity` literal. The generator writes those as the
strings `"NaN"`, `"Infinity"` and `"-Infinity"`; `jsNum` in
`golden_support.dart` converts them back. A JavaScript `null` or `undefined` —
an absent datum, or d3 returning "no result" for an empty input — is written as
JSON `null` and `jsNum` returns `null` for it.

## Sections

520 cases across eighteen sections: `ticks` (29), `arrayStats` (16),
`format` (78), `formatSpecifier` (50), `precision` (45), `color` (22),
`interpolate` (7), `timeInterval` (51), `timeTicks` (8), `timeFormat` (48),
`scaleLinear` (9), `scaleBand` (7), `scaleLog` (7), `scaleTime` (7),
`scaleTickFormat` (10), `shape` (115), `sankey` (6), `bin` (5). The generator
asserts every section holds more than four cases before it writes the file, so
a section cannot silently shrink into a test with no assertions.

## What is deliberately absent

**Local-time interval vectors.** `timeDay`, `timeHour` and friends depend on the
generating machine's zone, so a committed vector would fail everywhere else.
Local intervals are covered by hand-written assertions in
`time_interval_test.dart` that construct their own `DateTime` values and assert
DST behaviour relative to the running zone.
