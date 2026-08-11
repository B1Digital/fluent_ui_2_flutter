// Guards `lib/src/charts/` against a symbol that is written, tested, and then
// never called — a helper whose whole cost is paid and whose value is zero, and
// which reads as shipped work in a wave report. It has happened seven times,
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
//
// A green suite is not evidence against this defect: every one of those shipped
// green. Only a caller is.
//
// This file began as a gate on `lib/src/charts/internal/` alone, and the last
// three defects above all lived one directory up, where it could not see them.
// The stated reason for the narrow scope was that a wider sweep returns 332
// hits that are almost all false, `FluentAreaChart` among them, because a
// published widget's callers are users rather than `lib/` code.
//
// That number was measured without the same-file refinement below. With it, the
// wider sweep reports 1509 declarations and 25 orphans, and every one of the 25
// was checked by hand against `grep`: not one has a `lib/` reference that is not
// a doc comment. The false-positive rate of the rule as written is 0 of 25.
//
// THREE REFINEMENTS make the signal usable, and all three are load-bearing.
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
//     of this rule's false-positive rate: 3 of 28 without this refinement, 0 of
//     25 with it. It is still counted as a declaration, so the subtraction in
//     refinement 2 stays correct.
//
// A REJECTED REFINEMENT, recorded with its numbers so it is not re-proposed as
// an improvement: also treating a constructor declaration as a declaration site
// rather than a reference, so that an entirely unused class is reportable. It
// was measured, and it adds exactly three findings — `FluentAnnotationOnlyChart`,
// `FluentChartTable` and `FluentSparkline` — and zero real orphans. All three
// are `StatelessWidget`, which is the only thing separating them from
// `FluentAreaChart`: a `StatefulWidget` is saved by the `State<T>` in its own
// file, a stateless one has no such back-reference. They are the exact
// consumer-facing shape this gate must not flag, so the refinement is off and
// the blind spot is a ceiling below instead. It would take the rule from 0 of 25
// to 3 of 28.
//
// KNOWN CEILINGS, so a later reader does not mistake silence for proof:
//   * This is a name-level scan, not a resolver. A member sharing a name with
//     anything else in `lib/` — a field called `label`, `width`, `height` — can
//     never be reported, because some other declaration's use of that word
//     counts as a reference. It under-reports; it does not invent.
//   * A class is effectively unreportable once it declares a constructor, per
//     the rejected refinement above. An unused *class* therefore hides; an
//     unused *member of it* does not, and neither does an unused free function,
//     which is what caught `internal/scatter_polar.dart`.
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
/// Twenty-five of 1509 on 2026-08-11. Every upstream line cited here was read
/// from `crawlers/fluentui-react-charts/out/charts/src` while writing it, and
/// every `lib/` line was read from the file named.
const Map<String, String> kChartOrphanAllowlist = <String, String>{
  // --- Deliberate: the caller is not in lib/ and never will be -------------
  'cachedCount':
      'Test and diagnostic observability on the measurer memo, declared as '
      'such at chart_text_measurer.dart:119. FluentChartTextMeasurer is the '
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
      '425-428, replacing upstream `componentRef` at hooks.ts:23-41). Its '
      'callers are consumers of the published package, which live outside '
      'lib/ by construction — the same reason FluentAreaChart has no lib/ '
      'caller. It is the non-throwing query for whether toImage will '
      'succeed, versus the StateError at image_export.dart:455.',

  // --- Blocked: the consumer is not ported --------------------------------
  'fluentChartIsDarkTheme':
      'Ports `useIsDarkTheme` (DeclarativeChart.tsx:340-351, twinned at '
      'VegaDeclarativeChartHooks.ts:12), which compares HSL lightness rather '
      'than reading a brightness flag. Both callers are the declarative '
      'adapters — DeclarativeChart and VegaDeclarativeChart, the two of '
      "upstream's twenty charts not yet ported. Every imperatively mounted "
      'chart leaves isDark false, which is upstream behaviour, so there is no '
      'other site that should be calling this. Unblocks when either adapter '
      'lands.',
  'tokenFromUpstreamName':
      'Ports the token-lookup arm of `getColorFromToken` (colors.ts:139-146) '
      '— the `TOKENS.indexOf(token)` branch at :140, with a null result '
      "standing in for upstream's `return token` pass-through at :145. The "
      'port types every series colour as `Color?` instead of a colour string, '
      'so a ported chart already holds a resolved colour or names a '
      'FluentDataVizToken and calls `FluentDataVizPalette.resolve`. A raw '
      'upstream token string only ever arrives from untyped JSON, i.e. in the '
      'same two unported declarative adapters. Unblocks with them.',

  // --- Unpainted geometry: VerticalStackedBarChart's line overlay ---------
  // The five below are one feature, not five oversights. `lineData` is public
  // on the series and the chart does read it — legend entries at :328, the
  // secondary-scale min/max at :577, the y domain at :656, the empty-state
  // check at :1138 and the hit regions at :1243 — so a consumer can supply a
  // line and see it in the legend. What is missing is the paint: `paintSeries`
  // (:954) is the delegate's only painting entry point and names none of these.
  // This is the `singlePathFor` defect exactly, one chart over, and it was
  // invisible until this gate was widened past `internal/`.
  'linePathsFor':
      'The line overlay geometry, vertical_stacked_bar_chart.dart:919. Called '
      'from test/charts/vertical_stacked_bar_chart_test.dart:1131 and :1185 '
      'and from nowhere in lib/. `paintSeries` (:954) is the only paint entry '
      'on this delegate and does not reference it, so the path is built for '
      'the tests and never for the canvas. Removing this entry means calling '
      'it from paintSeries — with lineDotFillColour, lineDotRadiusFor and '
      'lineSegmentColour, which are the rest of the same overlay.',
  'categorySegmentsFor':
      'vertical_stacked_bar_chart.dart:759, the per-category segment layout '
      'the line overlay needs to anchor its points. Reached only from '
      'test/charts/vertical_stacked_bar_chart_test.dart:1001 and :1040. Goes '
      'when linePathsFor is wired, or with it if the overlay is dropped.',
  'lineDotRadiusFor':
      'vertical_stacked_bar_chart.dart:860, the dot radius under the '
      'highlighted and active-x combinations. Four assertions in '
      'test/charts/vertical_stacked_bar_chart_test.dart (:1058, :1063, :1069, '
      ':1074) pin all four combinations of a value the canvas never asks for. '
      'Goes with the rest of the overlay.',
  'lineSegmentColour':
      'vertical_stacked_bar_chart.dart:886, the colour of the segment ending '
      'at a given index. Its own doc one line above proposes widening the '
      'signature, which is a design note on a method with no caller. Goes '
      'with the rest of the overlay.',
  'lineDotFillColour':
      'vertical_stacked_bar_chart.dart:896, the dot fill, correctly flattened '
      'through flattenMarkStroke per spec 5.3 — a spec rule applied to a '
      'colour that never reaches a canvas. Goes with the rest of the overlay.',

  // --- Ported constants nothing reads --------------------------------------
  'kMinDonutRadius':
      'Ports `MIN_DONUT_RADIUS` (utilities.ts:90), declared at '
      'axis/axis_types.dart:54. donut_chart.dart computes its radius through '
      '`layout.labelRadius` (:841) and clamps against nothing, so a donut '
      'given a tiny box is not floored at 1 the way upstream floors it. '
      'Either the donut layout clamps to this, or the constant goes.',
  'kDefaultDateString':
      'Ports `DEFAULT_DATE_STRING` (utilities.ts:91), declared at '
      'axis/axis_types.dart:61 with a note that JavaScript parses a bare '
      'YYYY-MM-DD as UTC midnight. The one place that wants it writes the '
      'epoch as a literal instead: domain_range.dart:491-492 builds '
      '`DateTime.utc(2000)` twice under a comment at :490 that says the port '
      '"falls back to `kDefaultDateString`". The comment is accurate about '
      'intent and wrong about the code. Substituting the constant at both '
      'sites removes this entry and the contradiction together.',
  'kLegendShapeViewportSize':
      'The 14×14 SVG viewport a legend swatch is drawn into, '
      'chrome/legend_shape.dart:79, verified against Oracle B as stated '
      'there. Named only by two doc comments in its own file (:86 and :239) '
      'and by seventeen lines of test/charts/chrome; no painting code reads '
      'it, so the swatch box arrives from the legend style instead and the '
      'two can drift apart silently. Goes when the swatch painter takes its '
      'viewport from here.',
  'kPointWidthRatios':
      'Ports `pointTypes[*].widthRatio` (utilities.ts:1747-1771), '
      'chrome/legend_shape.dart:93. Its own doc says it is "used by series '
      'markers, never by the legend swatch" — and no series marker uses it, '
      'so a pentagon, hexagon or octagon asked for a width of w is drawn at '
      'w rather than w / ratio and comes out too large. Goes when the marker '
      'painter divides by it.',
  'kDefaultForeignObjectWidth':
      'Ports `DEFAULT_FOREIGN_OBJECT_WIDTH` (ChartAnnotationLayer.tsx:28), '
      'model/chart_annotation.dart:191. Upstream needs it because a hidden '
      'div cannot be measured before first paint; the port measures '
      'synchronously through FluentChartTextMeasurer, so the fallback never '
      'binds — annotation_layer.dart:507 records exactly that as a contract '
      'deviation. What keeps this from being a clean deletion is '
      'chart_annotation.dart:269, whose doc tells a consumer that a null '
      'width "uses kDefaultForeignObjectWidth". Nothing implements that. '
      'Either the model applies it as the documented default, or the '
      'constant and that sentence go together.',
  'kDefaultForeignObjectHeight':
      'Ports `DEFAULT_FOREIGN_OBJECT_HEIGHT` (ChartAnnotationLayer.tsx:29), '
      'model/chart_annotation.dart:196. The height twin of the entry above, '
      'with the same synchronous-measurement reason and the same resolution.',

  // --- Ported helpers nothing routes through -------------------------------
  'createYAxisLabels':
      'Ports `createYAxisLabels` (utilities.ts:1196-1230), '
      'axis/axis_label_layout.dart:295, including a deliberate divergence: '
      'upstream sets the tspan text only inside the truncateLabel branch '
      '(:1226-1228), so `truncateLabel: false` renders an empty y axis, and '
      'the port fills the full label in instead as an accessibility fix '
      '(spec 5.2, exception 2). Upstream calls it from one place, '
      'CartesianChart.tsx:400-406. The port has no equivalent call: y labels '
      'come from the `orderedYAxisLabels` getters on the delegates '
      '(scatter_chart.dart:607, vertical_stacked_bar_chart.dart:680, '
      'gantt_chart.dart:406) and from the axis builders. So the truncation '
      'behaviour and the accessibility fix are both unreachable. Goes when '
      'the cartesian y-axis path routes through it.',
  'fluentChartTitleDefaultY':
      'Ports the default `y` of a painted chart title, `ChartTitle.tsx:80-87` '
      '— `max(fontSize + AXIS_TITLE_PADDING, CHART_TITLE_PADDING - '
      'AXIS_TITLE_PADDING)` with the literal 13 fallback at :83 — declared at '
      'chrome/chart_title.dart:229. Four assertions in test/charts reach it '
      'and no painter does, so a title with no explicit y is placed by '
      'whatever the title painter does instead. Goes when that painter asks '
      'this for its default.',
  'fluentChartStripePhase':
      'chrome/legend_shape.dart:354, the distance of a point along the 135° '
      'gradient axis that decides whether a pixel falls on a stripe. Its own '
      'file names it twice in comments (:378 and :382) describing how the '
      'stripe painter below works — the painter computes the phase inline '
      'rather than calling this, so the shared definition and the painted '
      'result are two expressions that must be kept equal by hand. Goes when '
      'the painter calls it.',
  'rectsFor':
      'horizontal_bar_chart_with_axis.dart:655, the geometry-only view of the '
      'bar rects. Its own doc at :662 explains that the painter and the hit '
      'regions need the richer point-carrying variant instead, and that '
      'running the layout twice would fold the running offsets twice — which '
      'is the reason nothing calls this one. It is a convenience overload '
      'with no consumer. The likely resolution is deletion with its four test '
      'references, not wiring.',
  'hoverValuesFor':
      'line_chart.dart:144, the popover rows for a hovered x. Declared public '
      'for the tests by its own doc at :102-103, which names '
      '`FluentAreaChartState` as the shape it copies — and area_chart.dart:163 '
      'calls `findCalloutPoints` directly rather than going through any such '
      'method. So the LineChart popover does not route through this either: '
      'the isCalloutForStack narrowing it implements '
      '(LineChart.tsx:1660-1668) is applied nowhere in lib/. Goes when the '
      'popover path calls it, or by deleting it and pointing the tests at '
      'findCalloutPoints the way the AreaChart already does.',

  // --- Predicates with no caller -------------------------------------------
  // chart_value.dart is where a value is classified before it reaches an axis.
  // Its neighbours are all called — chartAxisTypeOf, isInvalidChartValue,
  // isPlottable, isNumberLike — which is what makes these four stand out: they
  // are the same shape, in the same file, reached only from tests.
  'isChartAxisValue':
      'model/chart_value.dart:38, `value is num || String || DateTime`. No '
      'upstream citation on it, and no lib/ caller: nothing validates an '
      'incoming axis value against the three types the axis accepts, so an '
      'unsupported type reaches chartAxisTypeOf (:31) and is classified as a '
      'date by its `_` arm. Wiring this at the entry point would make that '
      'arm reachable only for real dates; deleting it accepts the '
      'fallthrough, which is itself a documented parity choice at :28-30.',
  'isNumericOrDate':
      'model/chart_value.dart:42, the continuous-axis predicate. Five test '
      'references, no lib/ caller. Goes with the group above.',
  'isNumericOrCategory':
      'model/chart_value.dart:45, the numeric-or-band predicate. Same shape '
      'and same resolution as isNumericOrDate.',
  'isDateLike':
      'model/chart_value.dart:89, the fullest of the four: it ports `isDate` '
      '(chart-utilities/PlotlySchemaConverter.ts:44-60) with both upstream '
      'guards, including the year-2000/2001 rule that keeps a bare month name '
      'such as "March" off a date axis. Its natural caller is axis-type '
      'inference over untyped input, which in this port is the two unported '
      'declarative adapters — so it may belong with '
      'fluentChartIsDarkTheme above rather than here, but unlike those two '
      'nothing in the port records that dependency, so it is listed on the '
      'evidence rather than on the guess.',
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
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!line.startsWith(' ')) {
        final type = _typeDeclaration.firstMatch(line);
        if (type != null) {
          record(type.group(1)!, file, i, reportable: true);
          inClassBody = !line.startsWith('enum ');
          continue;
        }
        final topLevel = _topLevelDeclaration.firstMatch(line);
        if (topLevel != null) {
          record(topLevel.group(1)!, file, i, reportable: true);
        }
        if (line.trim().isNotEmpty) {
          inClassBody = false;
        }
        continue;
      }
      // A trailing comma is a parameter in a wrapped signature or a switch
      // pattern arm, never a member.
      if (!inClassBody || line.trimRight().endsWith(',')) {
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
    // 1509 reportable declarations across 81 files on 2026-08-11. The floor is
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
          'gate exists to stop, and it has shipped seven times under a green '
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
