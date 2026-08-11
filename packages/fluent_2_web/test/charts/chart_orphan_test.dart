// Guards `lib/src/charts/` against a symbol that is written, tested, and then
// never called — a helper whose whole cost is paid and whose value is zero, and
// which reads as shipped work in a wave report. It has happened eight times,
// and every time it was found by hand rather than by CI:
//
//   * wave 5 — `FluentLineMarkerPainter` was complete and green, and LineChart
//     drew no data-point markers.
//   * wave 6 — the whole of `internal/scatter_polar.dart` was complete and
//     green, and `fill: 'toself'` never painted.
//   * wave 6 fixes — `scatterPolarCategoryLabels` survived the first fix,
//     because the fix wired its neighbours and nobody re-ran the sweep.
//   * after wave 6 — `FluentLineChartDelegate.singlePathFor` was complete and
//     mutation-proven, and engine B painted no lines at all.
//   * after wave 6 — `solveDomainMargin` on both bar charts, twice over.
//   * wave 7 — `FluentResponsiveChartHost` was mounted per grid cell by
//     `declarative_chart.dart`, and its builder was handed the metrics it
//     existed to compute and returned a child built outside the builder. It
//     had a call site, so THIS GATE CERTIFIED IT AS WIRED.
//
// A green suite is not evidence against this defect: every one of those shipped
// green. A caller is the floor, and the eighth is why it is only the floor —
// see the called-but-discarded ceiling below, which this file does not cover.
//
// This file began as a gate on `lib/src/charts/internal/` alone, and the last
// three defects above all lived one directory up, where it could not see them.
// The stated reason for the narrow scope was that a wider sweep returns 332
// hits that are almost all false, `FluentAreaChart` among them, because a
// published widget's callers are users rather than `lib/` code.
//
// That number was measured without the same-file refinement below. With it, the
// wider sweep reported 1509 declarations and 25 orphans, and every one of the 25
// was checked by hand against `grep`: not one had a `lib/` reference that was
// not a doc comment. It read 1661 declarations and 18 orphans on the morning of
// 2026-08-11; after the batch that resolved thirteen of those — nine of them by
// deleting the symbol — and the fourteenth, `tokenFromUpstreamName`, deleted the
// same day, it reports 1652 declarations across 97 files and 4 orphans, which
// are the 4 excused below. The false-positive rate of the rule as written is
// 0 of 4, and was 0 of 18 at the wider count.
//
// FOUR REFINEMENTS make the signal usable, and all four are load-bearing.
// Each is stated with what it costs, because the next reader will be tempted to
// drop one:
//
//  1. Count references inside the declaring file too. Counting only *other*
//     files flags a same-file helper like `FluentSynthesisedLegendPainter`,
//     which `FluentChartImageExporter._renderLegend` uses correctly one screen
//     below its own declaration. This is also what retires the `FluentAreaChart`
//     false positive at no cost: `class _FluentAreaChartState extends
//     State<FluentAreaChart>` names the widget in its own file.
//  2. Subtract the number of declarations, not one. `solveDomainMargin` is
//     declared once in `vertical_bar_chart.dart` and once in
//     `grouped_vertical_bar_chart.dart` and was called from neither. Under a
//     fixed `< 2` threshold the two declarations counted each other as
//     references and the pair hid, which is precisely how both shipped.
//  3. Do not report `@override` members. They are dispatched by a base class or
//     by the framework and can have no caller by name — the three
//     `SingleChildLayoutDelegate` overrides on `FluentChartPopoverLayoutDelegate`
//     are called by `RenderCustomSingleChildLayoutBox` for a delegate that
//     `chart_popover.dart:600` really does install. Reporting them was the whole
//     of this rule's false-positive rate when it was measured: 3 of 28 without
//     this refinement, 0 of 25 with it. It is still counted as a declaration, so
//     the subtraction in refinement 2 stays correct.
//
//  4. Count a constructor line as a declaration of its class. `const Foo({`
//     spells `Foo`, so without this it read as a reference and every class
//     cleared the threshold on the strength of its own constructor — no class
//     was reportable, used or not. Verified by planting an unused public class
//     under `lib/src/charts/` and watching the gate stay green; verified again
//     after, by watching the same plant fail.
//
//     This refinement was measured once and REJECTED, on numbers that showed it
//     adding three findings and no real orphans: `FluentAnnotationOnlyChart`,
//     `FluentChartTable` and `FluentSparkline`, all `StatelessWidget`, the
//     consumer-facing shape this gate must not flag. Re-measured on 2026-08-11
//     it adds exactly one, because the first two acquired `lib/` callers in the
//     meantime — `transform_pie.dart:1381` returns a `FluentAnnotationOnlyChart`
//     and `:874` a `FluentChartTable`. `FluentSparkline` is the one left and is
//     excused below, for the same reason `isAttached` is. One allowlist entry is
//     the whole price of seeing a category that contains every painter,
//     delegate, layout and style class in the subsystem.
//
// KNOWN CEILINGS, so a later reader does not mistake silence for proof:
//   * This is a name-level scan, not a resolver. A member sharing a name with
//     anything else in `lib/` — a field called `label`, `width`, `height` — can
//     never be reported, because some other declaration's use of that word
//     counts as a reference. It under-reports; it does not invent.
//   * CALLED-BUT-DISCARDED IS NOT COVERED, and this gate certified exactly that
//     defect once — `FluentResponsiveChartHost`, the eighth instance above. A
//     name-frequency scan sees that a name is written in `lib/`; that is not the
//     same claim as its value being read. Three detectors were measured against
//     this tree on 2026-08-11 before the ceiling was accepted rather than
//     closed, and all three are recorded here so they are not re-proposed:
//       - a closure parameter never named in the closure's own body: 31 hits,
//         0 defects. Eleven are `(context, ...)` builders that need no context;
//         seventeen are the d3 accessor signature `(d, i, data)` used for `d`
//         alone (`sparkline.dart:74`, `polar_chart.dart:632`,
//         `sankey_chart.dart:330`); three are `onChange: (selected, current)`
//         (`declarative_chart.dart:783`). The discarded `metrics` was textually
//         indistinguishable from all thirty-one.
//       - a returned value assigned to nothing: 19 hits, 0 defects. Every one is
//         a wrapped `=>` body, not a statement — `getTypeOfAxis` at
//         `internal/chart_utils.dart:498-499` is `=>` then a newline then
//         `chartAxisTypeOf(value);` — and separating the two needs the preceding
//         token, which is a parser, not a regex.
//       - a `_`-named parameter where the API implies use: 23 sites, and `_` is
//         the language's own marker for deliberate non-use, so the rule would
//         flag the idiom that states the opposite of the defect.
//     0 of 73 across the three, so none was adopted. A builder or callback
//     parameter that arrives and is dropped is a human's job at review; this
//     file does not check it and must not be read as though it did.
//   * Enum constants are out of scope. `FluentDataVizToken.color2..color40` are
//     reached positionally (`FluentDataVizToken.values[number - 1]` at
//     `data_viz_palette.dart:308`, `_qualitative[token.index]` at `:291`) and
//     are never named, so scanning them produced 35 false positives that buried
//     the six real ones. Named here rather than dropped silently.
//   * `internal/d3/` is excluded. It is a transcription whose unused corners are
//     deliberate; see `test/charts/d3/kernel_boundaries_test.dart`.
//   * A test is not a caller. Every one of the 21 findings this widening added
//     is reached from `test/`, which is what made them look finished.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Public symbols under `lib/src/charts/` that no `lib/` code calls, each
/// paired with why it is still committed and what would remove the entry.
///
/// An entry here is an admission, not a pass. It says the symbol is compiled,
/// documented and tested, and that nothing in the shipped widget tree reaches
/// it. Deleting an entry is the fix — wire the symbol, or delete the symbol —
/// and the last test below fails if this map drifts from the scan in either
/// direction, so an excuse cannot outlive the gap it excuses.
///
/// Four on 2026-08-11, after a batch that resolved fourteen of the eighteen
/// this file carried that morning — each one wired or deleted, none re-worded
/// into a fresher deferral. Eighteen, in turn, was down from thirty-five and up
/// by the one that
/// refinement 4 made visible, `FluentSparkline`: plan 09 Task 28 landed
/// `declarative_chart.dart` and took eighteen entries with it in one go, every
/// one of which had named that widget as the caller it was waiting for. The
/// list before that was twenty-one, itself down from twenty-four when
/// VerticalStackedBarChart's line overlay took five entries with it as
/// `paintSeries` started painting it. Every upstream line cited here was read
/// from
/// `crawlers/fluentui-react-charts/out/charts/src` while writing it, and every
/// `lib/` line was read from the file named.
const Map<String, String> kChartOrphanAllowlist = <String, String>{
  // --- Deliberate: the caller is not in lib/ and never will be -------------
  'FluentSparkline':
      'sparkline.dart:206, a published StatelessWidget. Its callers are '
      'consumers of the package, which live outside lib/ by construction — the '
      'same reason isAttached is on this list, and the reason FluentAreaChart '
      'is not: a StatefulWidget is named by the `State<T>` in its own file and '
      'a stateless one has no such back-reference. It is the entire measured '
      'cost of refinement 4, and it does not hide a gap. Upstream has no '
      'declarative route to a sparkline either — `grep -rn Sparkline` over '
      'crawlers/fluentui-react-charts/out/charts/src hits only Sparkline.ts, '
      'index.ts and components/Sparkline/, never DeclarativeChart — so no '
      'unported adapter is going to arrive and call it. Removing this entry '
      'means the package grows a lib/ consumer of its own sparkline.',
  'cachedCount':
      'Test and diagnostic observability on the measurer memo, declared as '
      'such at chart_text_measurer.dart:120. FluentChartTextMeasurer is the '
      "subsystem's only TextPainter owner — `melos run chart-invariants` "
      'fails if a second one appears — and the memo is what keeps a metric '
      'consistent with the painter it was measured from. Six assertions in '
      'test/charts/internal/chart_text_measurer_test.dart and '
      'test/charts/chrome/legend_test.dart read this to prove the memo hits '
      'and that a theme swap misses. Removing this entry means deleting the '
      'getter and those assertions together; there is no lib/ caller to add.',
  'isAttached':
      'Public state on FluentChartController, the imperative handle a user '
      "attaches through a chart's `controller` parameter (image_export.dart:"
      '426-429, replacing upstream `componentRef` at hooks.ts:23-41). Its '
      'callers are consumers of the published package, which live outside '
      'lib/ by construction — the same reason FluentAreaChart has no lib/ '
      'caller. It is the non-throwing query for whether toImage will '
      'succeed, versus the StateError at image_export.dart:455.',

  // --- Retired: the blocker did not exist ---------------------------------
  // `tokenFromUpstreamName` was here, the one entry excused as blocked on an
  // unported consumer, and its own re-audit had already found that blocker
  // false and named deletion as the resolution. Re-verified against the source
  // before deleting rather than taken on the entry's word: `grep -rn
  // getColorFromToken` over crawlers/fluentui-react-charts/out/charts/src
  // returns exactly one hit in the Vega tree, VegaLiteColorAdapter.ts:250,
  // whose argument is `schemeMapping[index % schemeMapping.length]` (:249) off
  // getSchemeMapping (:192-209), and whose four tables — CATEGORY10 at
  // :95-106 and the CATEGORY20, TABLEAU10 and TABLEAU20 tables beside it —
  // hold DataVizPalette constants and nothing else. A consumer-supplied Vega
  // colour never reaches the function at all: getVegaColor returns its custom
  // `range` entry directly at :243. Plan 09 Task 39, which was starting as
  // this was written, types that branch the same way — its Produces line
  // spells "the four `List<FluentDataVizToken>` mappings", so the Vega adapter
  // holds tokens and resolves them through FluentDataVizPalette.resolve,
  // exactly as color_adapter.dart:162 already does for Plotly. Deleted with
  // the three tests and six assertions at data_viz_palette_test.dart:159-198,
  // which were the only code of any kind that reached it.
  // `shouldResize` was here, and it named its own resolution: "the likely
  // resolution when the adapters land is deletion with that test, not wiring".
  // The adapter landed and took the wiring instead — `declarative_chart.dart`
  // mounted a `FluentResponsiveChartHost` per grid cell whose `metrics`
  // parameter was never read and whose child was built outside the builder, so
  // THIS GATE SCORED THE WHOLE FILE AS WIRED on the strength of one call site
  // that discarded everything it was handed. That is the eighth instance of the
  // defect this file exists to catch, and the first the file itself certified.
  // Recorded as the rule the ninth will break: a name appearing in `lib/` is
  // what this scan can see, and it is not the same claim as the value being
  // used. `internal/responsive.dart` is now deleted — spec §5.1 carries why.

  // Eighteen entries were here until plan 09 Task 28 landed
  // `lib/src/charts/declarative_chart.dart`, the one widget every one of them
  // named as the caller that did not exist yet: `mapFluentChart`,
  // `getAllupLegendsProps`, `fluentChartIsDarkTheme` and fifteen of the sixteen
  // `transformPlotlyTo*` functions. `_FluentDeclarativeChartState._buildChart`
  // dispatches each transformer from its own arm, `_buildFigure` calls the
  // router at the `DeclarativeChart.tsx:362` position and the legend builder at
  // the `:535` position, and `build` reads the dark-theme test at `:340-351`.
  //
  // The sixteenth, `transformPlotlyToVbc`, outlived them by one task because
  // its entry named a second blocker: `FluentPlotlyChartKind` spelled no
  // `verticalBar`, so `internal/plotly/router.dart` sent `histogram` to
  // `verticalStackedBar` and the binning transformer — with plan 09 Task 16's
  // `histfunc`/`histnorm` behind it — was reachable from nothing but that
  // entry's own prose. The enum now spells it (`PlotlySchemaConverter.ts:518`),
  // the router returns it, `_buildChart` dispatches `transformPlotlyToVbc` from
  // its own arm and `kPlotlyDefaultCellHeight` carries the 350 at
  // `PlotlySchemaAdapter.ts:1892`. The route is pinned end to end by
  // `declarative/router_corpus_test.dart` ('a histogram routes to the vertical
  // bar chart') and by two mounted-widget tests in
  // `declarative/declarative_chart_test.dart` that read the bins back off the
  // rendered `FluentVerticalBarChart`.
  //
  // `getChartAnnotationsFromLayout` was here until plan 09 Task 18 landed the
  // first transformer that calls it: internal/plotly/transform_bar.dart writes
  // `getChartAnnotationsFromLayout(layout, isMultiPlot: isMultiPlot)` at the
  // `PlotlySchemaAdapter.ts:1579` position, which is what its own entry said
  // would remove it.
  // `getPolarAxisProps` was here until plan 09 Task 26 landed. Its entry said
  // "the moment transformPlotlyToPolar exists it must read this", and it does:
  // internal/plotly/transform_pie.dart calls it once, where
  // PlotlySchemaAdapter.ts:3277 spreads it. The excuse outlived its gap and
  // went with it. getPolarAxisType, added to axis.dart by the same task to
  // expose the one field PlotlySchemaAdapter.ts:3186 needs, needs no entry
  // either: the polar transformer is its caller.
  // --- Ported constants nothing reads --------------------------------------
  // `kMinDonutRadius` was here until plan 09 Task 17 landed: the Plotly pie
  // transformer is upstream's own `: MIN_DONUT_RADIUS` fallback
  // (PlotlySchemaAdapter.ts:1356) and now reads the constant, so the excuse
  // outlived its gap and the entry went with it. The gap it described is still
  // open and is not this list's to hold — `donut_chart.dart` computes its
  // radius through `layout.labelRadius` (:841) and floors it at nothing, so an
  // imperatively mounted donut in a tiny box is still not floored at 1.
  // `kDefaultDateString` was here until plan 09 Task 13 landed
  // `internal/plotly/axis.dart`, whose `plotlyTick0` reads
  // `DateTime.parse(kDefaultDateString)` at :582 — a real caller, so the excuse
  // outlived its gap and the test below was failing on it. The gap the entry
  // described is still open and is not this list's to hold:
  // domain_range.dart:491-492 still writes `DateTime.utc(2000)` twice under a
  // comment at :490 claiming it falls back to the constant.
  // `kLegendShapeViewportSize` was here, excused as "no painting code reads it,
  // so the swatch box arrives from the legend style instead and the two can
  // drift apart silently", and it named its own exit: "goes when the swatch
  // painter takes its viewport from here". The painter now does. A viewBox maps
  // its own width onto the rendered one — `shape.tsx:39-41` is `width={14}` over
  // `viewBox="-1 -1 14 14"` — and `FluentChartLegendShapePainter.paint` computes
  // that quotient instead of asserting in a comment that it is 1, so a swatch
  // box the legend style sizes differently now scales the shape with it rather
  // than leaving a 14-unit marker adrift in it. `chart_popover.dart:369-370`
  // reads it as well: `ChartPopover.tsx:211-217` renders the same `<Shape>`, so
  // the popover swatch box is that svg's own 14 and not the legend row's
  // border box, which is a different upstream number that merely coincides.
  //
  // `kPointWidthRatios` was here, excused as "a pentagon, hexagon or octagon
  // asked for a width of w is drawn at w rather than w / ratio and comes out too
  // large. Goes when the marker painter divides by it." The marker painter
  // already divides by it — by the other copy. `grep -rn widthRatio` over
  // crawlers/fluentui-react-charts/out/charts/src returns the table
  // (`utilities.ts:1738`, `:1749-1770`), one use (`LineChart.tsx:493-494`) and an
  // unrelated local in `funnelGeometry.ts:187`. That one use is inside `_getPath`
  // and feeds `_getPointPath` (`LineChart.tsx:82-137`), the data-point marker
  // builder, which `FluentLineMarkerPainter.kWidthRatios` transcribes in the
  // same `Points` order and `FluentLineChartDelegate.markersFor` divides by,
  // pinned per shape by line_chart_test's 'a wide shape is narrowed by its
  // width ratio, a narrow one is not'. The legend swatch is `shape.tsx:32-54`: one
  // ratio-free code path for all nine authored `d` strings. Applying a ratio
  // there would have HALVED a hexagon swatch against the box Chromium measured,
  // not corrected it. So the entry was excusing a second transcription of a
  // table already transcribed and wired, and the constant is deleted rather than
  // wired — two copies of one table kept equal by hand is the defect, not the
  // fix.
  // `kDefaultForeignObjectWidth` and `kDefaultForeignObjectHeight` were here
  // until the constant and that sentence went together, which is the second of
  // the two resolutions their entries offered. The first — applying 180 as the
  // documented default for a null `maxWidth` — was checked against upstream
  // and rejected: `ChartAnnotationLayer.tsx:493` writes `maxWidth:
  // layout?.maxWidth` onto the container, so an absent one emits no
  // `max-width` and the box takes its text's natural width. 180 is third in
  // the `measuredSize?.width ?? layout?.maxWidth ?? 180` chain at `:535`,
  // reachable only in the frame before the hidden measurement div reports, and
  // `:536` reads 60 in the same never-taken branch. Implementing the doc would
  // therefore have been a regression against upstream, not a fix; the doc was
  // the wrong half. `chart_annotation.dart` now states what a null maxWidth
  // does, and two tests in test/charts/chrome/annotation_layer_test.dart pin
  // it behaviourally — the port already answered 334.96 where the doc promised
  // no more than 180.

  // --- Ported helpers nothing routes through -------------------------------
  // `createYAxisLabels` was here until the cartesian y-axis path routed through
  // it, which is what its own entry asked for. The claim that the delegates'
  // `orderedYAxisLabels` getters were the y-label source was a half-truth: those
  // getters feed the band *domain*, and the text that reaches the screen is
  // `FluentAxisSpec.tickLabels` read by `FluentAxisPainter`. Nothing truncated
  // it, while the shell's `startFromX` solve (cartesian_chart.dart:670-686,
  // porting CartesianChart.tsx:150-160) had always sized the left margin off
  // `truncateString(label, noOfCharsToTruncate)` — so every chart with
  // `showYAxisLablesTooltip` reserved the truncated width and painted the full
  // label into it. HorizontalBarChartWithAxis, heat map, gantt and scatter all
  // ship that flag on from the Plotly transforms
  // (transform_bar.dart:641, :1412, :1929 and transform_xy.dart:940, :1369),
  // and their first y label started 66.99 logical pixels off the chart's left
  // edge. cartesian_painter.dart:220-226 now calls the helper,
  // unconditionally,
  // with `truncateLabel: props.showYAxisLablesTooltip` — which also makes the
  // spec 5.2 exception 2 arm the default path rather than dead code, since
  // upstream's own guard at CartesianChart.tsx:396 and its `truncateLabel`
  // argument at :404 are the same flag and its blank-axis branch is therefore
  // unreachable on both sides. Pinned by
  // test/charts/cartesian/cartesian_y_axis_labels_test.dart.
  // `fluentChartTitleDefaultY` was here, excused as "a title with no explicit
  // y is placed by whatever the title painter does instead. Goes when that
  // painter asks this for its default." The painter now asks it. The constant
  // was the authoritative half: `sankey_chart.dart` was the one painter that
  // reaches this default — every other `<ChartTitle>` caller either passes an
  // explicit `y` (`GaugeChart.tsx:604`, `DonutChart.tsx:364`) or is laid out
  // as a widget — and it wrote the literal 21 with the formula in a comment,
  // so `FluentSankeyChart.titleFontSize` moved the reserved band
  // (`SankeyChart.tsx:554-560`, via `sankeyTitleHeight`) while the title
  // stayed pinned at the default's value and floated high of its own band.
  // The same prop is upstream's `titleStyles.titleFont.size`, which
  // `ChartTitle.tsx:106` also hands to `getChartTitleInlineStyles`
  // (`Common.styles.ts:113`), so it now sizes the glyphs too — it had been
  // wired to neither. The default is pinned against the capture rather than
  // re-derived: `charts-sankeychart--sankey-chart-basic` puts its title `<text>`
  // at y 21 while rendering it at 10px, which is exactly why the placement
  // cannot be read off the title's own text style. Three tests in
  // test/charts/sankey_chart_test.dart.
  // `fluentChartStripePhase` was here, excused because "the painter computes
  // the phase inline rather than calling this, so the shared definition and the
  // painted result are two expressions that must be kept equal by hand. Goes
  // when the painter calls it." It calls it: `FluentChartStripePainter.paint`
  // takes the phase of the box's own far corner as its loop bound, so the band
  // the painter draws last is the one the shared definition says the box
  // reaches, and the two expressions are one. The identity the painter's
  // comment used to assert by hand — pixel (x, y) is coloured iff
  // `fluentChartStripePhase(Offset(x, y))` falls in a clamped colour band — is
  // now asserted per pixel over two box shapes in
  // `test/charts/chrome/legend_shape_test.dart`.
  // `rectsFor` was here, excused as "a convenience overload with no consumer"
  // whose "likely resolution is deletion with its four test references". It is
  // deleted. Its own doc said why nothing could ever call it: the painter and
  // the hit regions need the point-carrying `placeBars`, and taking the
  // geometry-only view of a `placeBars` pass they have already made costs a
  // second fold of the running offsets. Upstream has no counterpart either: the
  // bar geometry is built once inside `sortedBars.map` at
  // `HorizontalBarChartWithAxis.tsx:404-495`, where the `<rect>` at `:470-489`
  // and the datum it came from are the same closure. Nothing in plan 09's Vega
  // half (Tasks 31-57) names it. Its four assertions did NOT go with it — each
  // one pins real parity (the `:419-422` position guard, and two oracle
  // stories) and each reached it only to strip `.rect` off the list `placeBars`
  // returns, so they now call `placeBars` directly and the count is unchanged.
  // `hoverValuesFor` was here, excused as "the isCalloutForStack narrowing it
  // implements (LineChart.tsx:1660-1668) is applied nowhere in lib/". The entry
  // understated its own gap: `FluentLineChartDelegate.buildHitRegions` returned
  // `const <FluentChartHitRegion>[]`, so the LineChart declared no hover target,
  // no keyboard stop and no popover AT ALL, and `isCalloutForStack` — a public
  // prop of `FluentLineChart` — chose between two popover bodies that nothing
  // ever rendered. The delegate now cuts one region per marker at upstream's own
  // magnetic-latch radius (`LineChart.tsx:1162-1168`) and fills a
  // `FluentChartPopoverData` per point, which is what `ChartPopover.tsx:56-60`
  // switches on: the stacked body lists every series at the hovered x
  // (`:1657`, `:1681`), the single-value body the hovered line alone.
  //
  // The method is deleted rather than wired, because the value it computed is
  // upstream's `hoverDp`, and `hoverDp` reaches NEITHER body — it is passed to
  // `calloutPropsPerDataPoint` (`:1898`) and `onRenderCalloutPerDataPoint`
  // (`:307`), two consumer hooks the ported props bag does not carry. The
  // single-value body's legend, reading and colour come from the hovered circle
  // instead (`:1682-1684` into `:1877-1879`), which is where the port now reads
  // them, and which is also correct on the tie the `find` at `:1661` resolves to
  // the wrong series. `_calloutPoints` and its `didUpdateWidget` memo went with
  // the method: `buildHitRegions` calls `calloutData` beside the `markersFor`
  // pass it already makes. Covered by three mounted-hover tests in
  // test/charts/line_chart_test.dart that read the popover off the widget tree.

  // --- Predicates with no caller -------------------------------------------
  // chart_value.dart is where a value is classified before it reaches an axis.
  // Its neighbours are all called — chartAxisTypeOf, isInvalidChartValue,
  // isPlottable, isNumberLike.
  //
  // `isChartAxisValue`, `isNumericOrDate` and `isNumericOrCategory` were the
  // fourth, fifth and sixth, excused on the claim that "nothing validates an
  // incoming axis value against the three types the axis accepts, so an
  // unsupported type reaches chartAxisTypeOf (:31) and is classified as a date
  // by its `_` arm". That claim was false. Every one of the eight
  // `getTypeOfAxis` call sites in lib/ — `vertical_bar_chart.dart:674`,
  // `vertical_stacked_bar_chart.dart:302`, `:308`, `:315`,
  // `horizontal_bar_chart_with_axis.dart:482`, `gantt_chart.dart:364`, `:369`,
  // `scatter_chart.dart:429` — reads a field whose own constructor already
  // asserts the union, each citing the `types/DataPoint.ts` line that declares
  // it (`bar_data.dart:205`, `:421`, `:308`, `:359`, `:260`, `:525`, `:558`,
  // `cartesian_series.dart:101`). The port validates; the three helpers were a
  // second copy of that predicate with no caller, and are deleted.
  //
  // They could not have been wired in the form the design asked for.
  // `kernel/shared-data-model.md:575` specifies them as "predicates used by the
  // const-constructor asserts across the model", and a const constructor's
  // assert condition must be a potentially constant expression: `assert(x is
  // num || x is String || x is DateTime)` compiles, `assert(isChartAxisValue(x))`
  // is `const_eval_method_invocation`, "Methods can't be invoked in constant
  // expressions". The inline form in the model IS the wiring, and it is the only
  // legal one. Verified by compiling both.
  //
  // Deleting them also loses nothing in release, where the asserts are stripped:
  // a predicate consumed inside an assert is stripped with it. Tightening the
  // `_` arm for real would mean an unconditional throw, and upstream has no
  // runtime check at all to port — `getTypeOfAxis` (`utilities.ts:1686`) takes
  // `p: string | number | Date`, a compile-time union.
  //
  // Plan 09's Vega tasks were checked for a future consumer before deleting:
  // its validators (`internal/vega/common.dart`) are `validateVegaDataArray`,
  // `validateVegaNoNestedArrays`, `validateVegaEncodingType` — field-presence
  // and declared-encoding-type checks against `VegaLiteSchemaAdapter.ts:890-992`,
  // none of them a `num | String | DateTime` test. No task in plan 09 names any
  // of the three.
  //
  // `isDateLike` (model/chart_value.dart:89) was the seventh of this group and
  // has been deleted from the list rather than re-worded: the entry predicted
  // that its natural caller was "axis-type inference over untyped input, which
  // in this port is the two unported declarative adapters", and the Plotly
  // adapter now calls it — `internal/plotly/predicates.dart:62` is `isPlotlyDate`
  // delegating to it, which is what stopped plan 09 Task 5 from transcribing
  // `PlotlySchemaConverter.ts:44-60` a second time.

  // --- Plotly ports with no caller, verified against upstream --------------
  // The two below were left behind by plan 09's thirty tasks, each reported by
  // a later task as "not mine". They are excused here rather than in a task
  // file because no single task owns both, and a red gate blocks the Vega
  // half. Each was checked against upstream before being written down.
  //
  // `kSingleRepeat` (internal/plotly/grid.dart) was the third, excused on the
  // claim that `collapseDegenerateGrid`'s `rowCount != 1 || columnCount != 1`
  // was "the same predicate one step earlier". It was not. Upstream seeds both
  // CSS templates with `1fr` at PlotlySchemaAdapter.ts:3654-3655 and only
  // overwrites them inside the `:3762`/`:3793` guards, so a multi-plot figure
  // that solves no domain ends on `1fr` — not the `repeat(1, 1fr)` that
  // DeclarativeChart.tsx:513-514 collapses on — while both counts still read 1.
  // The entry is deleted rather than re-worded: the constant now has a caller,
  // `FluentPlotlyGridProperties.isSingleRepeat`, and the figures the wrong
  // predicate was silently collapsing are covered by
  // test/charts/declarative/declarative_collapse_test.dart.
  // `resolveXAxisPoint` was here, excused as an orphan UPSTREAM TOO whose
  // "honest resolution is deletion with its five assertions". It is deleted.
  // The upstream claim was re-verified: `grep -rn resolveXAxisPoint` over
  // crawlers/fluentui-react-charts/out/charts/src still returns exactly one
  // hit, the `export const` at PlotlySchemaAdapter.ts:368, with no call at any
  // line of any file. Every landed transformer types its x column as a whole
  // and coerces in bulk, and no Vega task (31-57) mentions it. Deleting it also
  // retires the signature deviation its doc carried — this port dropped
  // upstream's `isXYearCategory` arm (`:378-380`), so a year category came back
  // unstringified and the first caller would have inherited that.
  'isSafePlotlyUrl':
      'internal/plotly/json_guard.dart:159, the URL-scheme allowlist hardened '
      'under spec §5.2 exception 2. Upstream has exactly one caller — '
      'VerticalStackedBarChart.tsx:308, `if (props.href && isSafeUrl('
      'props.href)) { window.location.href = props.href; }` — and this port '
      'deliberately has no navigation surface to guard: '
      'cartesian_chart_props.dart:76 records that `href` is declared upstream '
      'and never read by the shell, so no chart carries an href and no code '
      'path reaches a URL. This is the ONE entry on this list that must not be '
      'resolved by deletion. The moment any task adds an href, a link '
      'annotation or a tappable label, that call site is this function and '
      'wiring it is not optional. Its tests stay green in the meantime so the '
      'guard is correct on the day it is needed: the two rejection tests at '
      'test/charts/declarative/json_guard_test.dart:117 and :135, and the '
      'acceptance test at :153 that keeps them from passing by rejecting '
      'everything. Re-audited 2026-08-11 — the entry used to call :117-168 '
      '"its negative tests", a range whose second half is that acceptance '
      'test.',

  // --- Vega ports whose consumer is a later task in this same plan ---------
  // Empty, and that is the point of the section. Fourteen entries stood here
  // until Task 52 landed `vega_declarative_chart.dart`, and every one of them
  // named it as the exit it was waiting for: `deepCloneVegaSpec`
  // (internal/vega/spec.dart:63), `getVegaChartType` (routing.dart:227),
  // `getVegaLiteLegendsProps` (common.dart:674), `kVegaStackedBarDefaultHeight`
  // (transform_bar.dart:614) and the ten `transformVegaTo*` transformers.
  // `_FluentVegaDeclarativeChartState.build` validates the spec's depth
  // (`:591`), clones it (`:596`) — that order, because a clone that ran first
  // would recurse as deep as the attacker asked before anything counted the
  // levels — routes it and dispatches through an exhaustive switch whose arms
  // RETURN the widget that is mounted — not a value computed and dropped, the
  // ceiling this file cannot see. `transformVegaToLine` never needed an entry:
  // `transformVegaToArea` calls it at transform_line.dart:814.
  //
  // Two of the fourteen are wired by something narrower than a switch arm, so
  // they are named rather than counted: `kVegaStackedBarDefaultHeight` is the
  // stacked-bar arm of `kVegaDefaultCellHeight`, and `getVegaLiteLegendsProps`
  // feeds the lifted legend row the widget draws when it has suppressed the
  // chart's own. Both are asserted in test/charts/vega/vega_chart_test.dart by
  // a test that would still pass if the routing worked and they did not.
  //
  // Task 53's concat grid should add NO entry here. It replaces the body of the
  // same build method, and every symbol it needs is already called.
};

/// Files scanned for declarations: every `.dart` file under
/// `lib/src/charts/`, with the `d3/` kernel excluded by path segment.
List<File> chartSources() =>
    Directory('lib/src/charts')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.dart') &&
              !file.uri.pathSegments.contains('d3'),
        )
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

/// [source] with `//`, `///` and `/* */` comments replaced by blank space.
///
/// Stripping is the whole point of the gate rather than a tidy-up. One of the
/// orphans below — `fluentChartIsDarkTheme`, named from the `///` at
/// `data_viz_palette.dart:262` and from nowhere else — resolves, because
/// `comment_references` is an error in this workspace. A scan over raw text
/// therefore reports it as called. It is not called; it is described. Of the 25
/// findings, 8 have a doc-comment reference and no other, so without this the
/// gate would report 17 and call the rest wired.
///
/// String literals are not tracked, so a `//` inside one would truncate the
/// rest of that line. Verified inapplicable: `lib/` contains no such literal,
/// and the failure mode is a false orphan, which is loud, not a missed one.
String stripDartComments(String source) {
  final out = StringBuffer();
  var inBlock = false;
  for (final rawLine in source.split('\n')) {
    var line = rawLine;
    if (inBlock) {
      final end = line.indexOf('*/');
      if (end < 0) {
        out.writeln();
        continue;
      }
      line = line.substring(end + 2);
      inBlock = false;
    }
    while (true) {
      final block = line.indexOf('/*');
      final lineComment = line.indexOf('//');
      if (block >= 0 && (lineComment < 0 || block < lineComment)) {
        final end = line.indexOf('*/', block + 2);
        if (end < 0) {
          line = line.substring(0, block);
          inBlock = true;
          break;
        }
        line = line.substring(0, block) + line.substring(end + 2);
        continue;
      }
      if (lineComment >= 0) {
        line = line.substring(0, lineComment);
      }
      break;
    }
    out.writeln(line);
  }
  return out.toString();
}

/// A type declared at column 0: `class`, `enum`, `mixin`, `extension`,
/// `extension type` or `typedef`, public by its leading capital.
final RegExp _typeDeclaration = RegExp(
  r'^(?:abstract |base |final |sealed |interface |mixin )*'
  r'(?:class|enum|mixin|extension type|extension|typedef) +([A-Z][A-Za-z0-9_]*)',
);

/// A function or variable declared at column 0, public by its leading
/// lowercase. The trailing `(`, `=` or `;` is what separates a declaration from
/// a continuation line.
final RegExp _topLevelDeclaration = RegExp(
  r'^(?:const |final |late |external )*'
  r'[A-Za-z_][A-Za-z0-9_<>,?\[\]. ]*[ >?\]] *([a-z][A-Za-z0-9_]*) *[(=;]',
);

/// A constructor declared at exactly two spaces of indent: `const Foo({`,
/// `Foo._(`, `factory Foo.fromJson(`.
///
/// This line spells the class name, so a scan that does not know it is a
/// declaration reads it as a reference — which is what made a class
/// unreportable regardless of whether anything used it. The capitalised name
/// must be followed by an optional `.named` and then `(`, which is what keeps a
/// method off the pattern: `Foo copyWith({` has a word between the two.
///
/// The `(?:\.[A-Za-z0-9_]+)?` arm reports no orphan on today's tree, and is
/// kept because it is the difference between seeing and not seeing a class
/// whose only constructor is named — `FluentSparklineLayout._` at
/// `sparkline.dart:29` is the house idiom. Proven by planting a class with a
/// private named constructor and nothing else: the gate fails with the arm and
/// passes without it. Over-matching here is loud rather than silent — an extra
/// subtraction reports a false orphan — so the pattern is deliberately narrow
/// on what precedes the name and permissive after it.
final RegExp _constructorDeclaration = RegExp(
  r'^  (?:const |factory |external )*([A-Z][A-Za-z0-9_]*)(?:\.[A-Za-z0-9_]+)?'
  r' *\(',
);

/// A member declared at exactly two spaces of indent — `dart format` puts every
/// class member there and every statement inside one at four or more, so the
/// indent alone separates a field from a local. Named constructors are skipped:
/// they lead with a capital and are reached through the class name, which the
/// type scan already covers.
///
/// The `\([^()]*\)\??` arm is a record return type, and it is why both
/// `solveDomainMargin` declarations are visible. Without it the return type
/// `({double barWidth, double domainMargin})` matches no arm, the modifier
/// group gives up its match, and the pattern captures the word `static` as the
/// member name — so the real name was never scanned at all and the gate could
/// not have reported it however the threshold was set. The floor assertion
/// below cannot see this class of failure, because losing a handful of
/// declarations out of 1509 leaves the count healthy; the named-symbol
/// assertion is what covers it.
final RegExp _memberDeclaration = RegExp(
  r'^  (?:@override *)?(?:static |const |final |late |external |covariant )*'
  r'(?:(?:\([^()]*\)\??|[A-Za-z_][A-Za-z0-9_<>,?\[\]. ]*[ >?\]]) *)?(?:get +)?'
  r'([a-z][A-Za-z0-9_]*) *[(=;]',
);

/// Whether the member declared on `lines[index]` carries an `@override`.
///
/// `dart format` puts the annotation on its own line above the member, so the
/// nearest preceding non-blank line is where it lives; the same-line form is
/// checked too because the member pattern permits it.
bool _isOverride(List<String> lines, int index) {
  if (lines[index].contains('@override')) {
    return true;
  }
  for (var i = index - 1; i >= 0; i--) {
    if (lines[i].trim().isNotEmpty) {
      return lines[i].contains('@override');
    }
  }
  return false;
}

/// Every public symbol declared in [chartSources].
///
/// `sites` maps a reportable symbol to the `file:line` of its first
/// declaration; `counts` maps every symbol, reportable or not, to how many
/// times it is declared. The two differ only for `@override` members, which are
/// counted so that the subtraction in the orphan scan stays honest but are
/// never reported, because nothing calls them by name.
///
/// Two symbols of the same name in different files collapse to one entry, which
/// is correct for a name-level scan: one name has one reference count, and the
/// count of declarations is what the scan subtracts.
({Map<String, String> sites, Map<String, int> counts}) declaredSymbols() {
  final sites = <String, String>{};
  final counts = <String, int>{};
  void record(String name, File file, int index, {required bool reportable}) {
    counts[name] = (counts[name] ?? 0) + 1;
    if (reportable) {
      sites.putIfAbsent(name, () => '${file.path}:${index + 1}');
    }
  }

  for (final file in chartSources()) {
    final lines = stripDartComments(file.readAsStringSync()).split('\n');
    // Members are only read inside a class body. A top-level function body sits
    // at the same two-space indent, so without this its locals — `final double
    // radius;` at `marker_geometry.dart:45` — read as fields.
    var inClassBody = false;
    // Enum bodies are excluded from the member scan above and included here: a
    // constant like `  color1,` must not read as a field, but `  const
    // FluentFoo(this.x);` is still the enum's constructor spelling its own name.
    var inTypeBody = false;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!line.startsWith(' ')) {
        final type = _typeDeclaration.firstMatch(line);
        if (type != null) {
          record(type.group(1)!, file, i, reportable: true);
          inClassBody = !line.startsWith('enum ');
          inTypeBody = true;
          continue;
        }
        final topLevel = _topLevelDeclaration.firstMatch(line);
        if (topLevel != null) {
          record(topLevel.group(1)!, file, i, reportable: true);
        }
        if (line.trim().isNotEmpty) {
          inClassBody = false;
          inTypeBody = false;
        }
        continue;
      }
      // A trailing comma is a parameter in a wrapped signature or a switch
      // pattern arm, never a member.
      if (line.trimRight().endsWith(',')) {
        continue;
      }
      if (inTypeBody) {
        final constructor = _constructorDeclaration.firstMatch(line);
        if (constructor != null) {
          // Counted, never reported: the site of a class is its `class` line,
          // and a constructor has no name of its own to report.
          record(constructor.group(1)!, file, i, reportable: false);
          continue;
        }
      }
      if (!inClassBody) {
        continue;
      }
      final member = _memberDeclaration.firstMatch(line);
      if (member != null) {
        record(member.group(1)!, file, i, reportable: !_isOverride(lines, i));
      }
    }
  }
  return (sites: sites, counts: counts);
}

void main() {
  final declarations = declaredSymbols();
  // The barrel is excluded because an `export` makes a symbol reachable, not
  // used, and re-exporting an orphan is exactly how one reaches a wave report
  // as shipped surface. All 201 export lines are whole-file, so no symbol is
  // named there anyway; excluding it costs nothing and states the intent.
  const barrel = 'lib/fluent_2_web.dart';
  final corpus = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart') && file.path != barrel)
      .map((file) => stripDartComments(file.readAsStringSync()))
      .join('\n');

  // A declaration contributes one occurrence of its own name, so a name
  // declared n times needs n + 1 occurrences before one of them is a call. 1 is
  // that boundary and not a threshold.
  const oneRealReference = 1;
  final orphans = <String, String>{
    for (final entry in declarations.sites.entries)
      if (RegExp('\\b${entry.key}\\b').allMatches(corpus).length -
              declarations.counts[entry.key]! <
          oneRealReference)
        entry.key: entry.value,
  };

  test('the scan read the sources it claims to read', () {
    // 1661 reportable declarations across 97 files on 2026-08-11. The floor is
    // the failure this guards: a regex that stops matching reports zero orphans
    // and passes, which is the gate quietly deleting itself. `melos run ci`
    // would stay green through it, exactly as it did through all seven defects
    // above. 1200 sits far below today's count and far above what any partial
    // regex failure would leave.
    expect(
      declarations.sites.length,
      greaterThanOrEqualTo(1200),
      reason:
          'only ${declarations.sites.length} public symbols were found under '
          'lib/src/charts — the declaration scan is broken, so a green result '
          'here means nothing was checked',
    );
    expect(
      chartSources().map((file) => file.path),
      everyElement(isNot(contains('/d3/'))),
      reason:
          'the d3 kernel is a transcription with deliberate unused corners; '
          'the path-segment filter is what excludes it, so a change that lets '
          'it back in must be caught here rather than answered with 35 new '
          'allowlist entries',
    );
    // `extends StatefulWidget` is load-bearing in this string. Asserting on
    // `class FluentLineChart` alone passes on a corpus narrowed to
    // `lib/src/charts/model/`, because `class FluentLineChartSeries` contains
    // it — the guard read as proof that a chart was present while proving only
    // that a model of one was. Found by mutating the corpus root and watching
    // this assertion stay green.
    expect(
      corpus,
      contains('class FluentLineChart extends StatefulWidget'),
      reason:
          'the reference corpus does not contain a chart widget, so every '
          'symbol would read as uncalled and the allowlist would grow to '
          'cover the whole subsystem',
    );
    // A constructor line spells its own class name, and reading it as a
    // reference is what kept every class with a constructor off this report —
    // the gate stayed green on a planted unused public class. `FluentSparkline`
    // declares `class` at sparkline.dart:206 and `const FluentSparkline({` at
    // :208, so two is the count that proves the constructor arm is still on.
    // Nothing else fails if it is dropped: the scan would simply stop finding
    // classes, silently, exactly as it did before.
    expect(
      declarations.counts['FluentSparkline'],
      greaterThanOrEqualTo(2),
      reason:
          'the scan counted ${declarations.counts['FluentSparkline']} '
          'declarations of FluentSparkline, which declares a class and a '
          'constructor — the constructor arm has been dropped, so every class '
          'that declares a constructor is unreportable again and this gate is '
          'blind to painters, delegates, layouts and styles as a category',
    );
    // A record return type is the one declaration shape this scan was blind to,
    // and that blindness is why both `solveDomainMargin` declarations were
    // invisible rather than merely unreported. Anchoring on the symbol that was
    // missed is the only assertion that fails if the arm is dropped again.
    expect(
      declarations.sites,
      contains('solveDomainMargin'),
      reason:
          'solveDomainMargin returns a record, and it is missing from the '
          'scan — the record arm of the member pattern has been dropped, so '
          'every record-returning helper is now unscannable and this gate '
          'cannot report the exact defect it was widened to catch',
    );
  });

  test('every public symbol under lib/src/charts is called, or excused', () {
    final unexcused = <String>[
      for (final entry in orphans.entries)
        if (!kChartOrphanAllowlist.containsKey(entry.key))
          '${entry.key}  (${entry.value})',
    ];
    expect(
      unexcused,
      isEmpty,
      reason:
          'these symbols are declared, documented and tested under '
          'lib/src/charts, and no code in lib/ calls them — a doc comment '
          'naming one is not a caller, and neither is a test:\n'
          '${unexcused.join('\n')}\n'
          'Wire it, delete it, or add it to kChartOrphanAllowlist with the '
          'reason it stays. A tested helper nothing calls is the defect this '
          'gate exists to stop, and it has shipped eight times under a green '
          'suite.',
    );
  });

  test('the allowlist carries no stale entry', () {
    for (final entry in kChartOrphanAllowlist.entries) {
      expect(
        declarations.sites,
        contains(entry.key),
        reason:
            '${entry.key} is excused here but the scan does not declare it, so '
            'either it was deleted or the name is misspelt — a typo excuses '
            'nothing and hides a real orphan',
      );
      expect(
        orphans,
        contains(entry.key),
        reason:
            '${entry.key} is excused here but lib/ now calls it, so delete the '
            'entry: an excuse that outlives its gap makes this list read as '
            'longer than the real debt',
      );
      expect(
        entry.value.trim(),
        isNotEmpty,
        reason:
            '${entry.key} is excused with no reason, which is the same silent '
            'skip as leaving it off the list',
      );
    }
  });
}
