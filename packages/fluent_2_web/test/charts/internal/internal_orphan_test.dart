// Guards `lib/src/charts/internal/` against a symbol that is written, tested,
// and then never called — a helper whose whole cost is paid and whose value is
// zero, and which reads as shipped work in a wave report. It has happened four
// times, and every time it was found by hand rather than by CI:
//
//   * wave 5 — `FluentLineMarkerPainter` was complete and green, and LineChart
//     drew no data-point markers.
//   * wave 6 — the whole of `internal/scatter_polar.dart` was complete and
//     green, and `fill: 'toself'` never painted.
//   * wave 6 fixes — `scatterPolarCategoryLabels` survived the first fix,
//     because the fix wired its neighbours and nobody re-ran the sweep.
//   * after wave 6 — `FluentLineChartDelegate.singlePathFor` was complete and
//     mutation-proven, and engine B painted no lines at all. That one is the
//     ceiling below, not this gate: `singlePathFor` lives one directory up.
//
// A green suite is not evidence against this defect: every one of those four
// shipped green. Only a caller is.
//
// TWO REFINEMENTS make the signal usable, and both are load-bearing:
//
//  1. Scope to `lib/src/charts/internal/`, excluding `internal/d3/`. Sweeping
//     every public chart symbol returns 332 hits that are almost all false —
//     `FluentAreaChart` has no caller inside `lib/` because its callers are
//     users, and the d3 kernel is a transcription whose unused corners are
//     deliberate (see `test/charts/d3/kernel_boundaries_test.dart`).
//  2. Count references inside the declaring file too. Counting only *other*
//     files flags a same-file helper like `FluentSynthesisedLegendPainter`,
//     which `FluentChartImageExporter._renderLegend` uses correctly one screen
//     below its own declaration.
//
// With both, the scan reports 129 declarations and four orphans.
//
// KNOWN CEILINGS, so a later reader does not mistake silence for proof:
//   * This is a name-level scan, not a resolver. A member sharing a name with
//     anything else in `lib/` — a field called `label`, `width`, `height` — can
//     never be reported, because some other declaration's use of that word
//     counts as a reference. It under-reports; it does not invent.
//   * Enum constants are out of scope. `FluentDataVizToken.color2..color40` are
//     reached positionally (`FluentDataVizToken.values[number - 1]` at
//     `data_viz_palette.dart:308`, `_qualitative[token.index]` at `:291`) and
//     are never named, so scanning them produced 35 false positives that buried
//     the six real ones. Named here rather than dropped silently.
//   * The scan stops at `internal/`, so an orphan one directory up is invisible
//     to it. None is known today, and the two that were — both
//     `solveDomainMargin` declarations, and
//     `FluentLineChartDelegate.singlePathFor` — are what retired this map's
//     `isScalePaddingDefined` and `lineModeDrawsLines` entries. Neither was
//     reported by anything; both were found by reading. Nothing here proves a
//     third does not exist.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Public symbols under `lib/src/charts/internal/` that no `lib/` code calls,
/// each paired with why it is still committed and what would remove the entry.
///
/// An entry here is an admission, not a pass. It says the symbol is compiled,
/// documented and tested, and that nothing in the shipped widget tree reaches
/// it. Deleting an entry is the fix — wire the symbol, or delete the symbol —
/// and the second test below fails if this map drifts from the scan in either
/// direction, so an excuse cannot outlive the gap it excuses.
///
/// Four of 129 on 2026-08-10: two blocked on a consumer that is not ported,
/// and two deliberate non-`lib/` API. Every upstream line cited here was read
/// from `crawlers/fluentui-react-charts/out/charts/src` while writing it.
const Map<String, String> kChartInternalOrphanAllowlist = <String, String>{
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
      'caller and the reason this scan is scoped to internal/ at all. It is '
      'the non-throwing query for whether toImage will succeed, versus the '
      'StateError at image_export.dart:455.',

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
};

/// Files scanned for declarations: `lib/src/charts/internal/*.dart`, with the
/// `d3/` kernel excluded by taking only this directory's own entries.
List<File> internalSources() =>
    Directory('lib/src/charts/internal')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

/// [source] with `//`, `///` and `/* */` comments replaced by blank space.
///
/// Stripping is the whole point of the gate rather than a tidy-up. One of the
/// four orphans below — `fluentChartIsDarkTheme`, named from the `///` at
/// `data_viz_palette.dart:262` and from nowhere else — resolves, because
/// `comment_references` is an error in this workspace. A scan over raw text
/// therefore reports it as called. It is not called; it is described. Two
/// entries that were retired, `isScalePaddingDefined` and `lineModeDrawsLines`,
/// were the same shape.
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
final RegExp _memberDeclaration = RegExp(
  r'^  (?:@override *)?(?:static |const |final |late |external |covariant )*'
  r'(?:[A-Za-z_][A-Za-z0-9_<>,?\[\]. ]*[ >?\]] *)?(?:get +)?'
  r'([a-z][A-Za-z0-9_]*) *[(=;]',
);

/// Every public symbol declared in [internalSources], mapped to `file:line`.
///
/// Two symbols of the same name in different files collapse to one entry, which
/// is correct for a name-level scan: one name has one reference count. The
/// recorded location is the first declaration seen.
Map<String, String> declaredSymbols() {
  final declarations = <String, String>{};
  void record(String name, File file, int index) =>
      declarations.putIfAbsent(name, () => '${file.path}:${index + 1}');

  for (final file in internalSources()) {
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
          record(type.group(1)!, file, i);
          inClassBody = !line.startsWith('enum ');
          continue;
        }
        final topLevel = _topLevelDeclaration.firstMatch(line);
        if (topLevel != null) {
          record(topLevel.group(1)!, file, i);
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
        record(member.group(1)!, file, i);
      }
    }
  }
  return declarations;
}

void main() {
  final declarations = declaredSymbols();
  // The barrel is excluded because an `export` makes a symbol reachable, not
  // used, and re-exporting an orphan is exactly how one reaches a wave report
  // as shipped surface.
  const barrel = 'lib/fluent_2_web.dart';
  final corpus = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart') && file.path != barrel)
      .map((file) => stripDartComments(file.readAsStringSync()))
      .join('\n');

  // A declaration contributes one occurrence of its own name, so the first
  // reference is the second hit. 2 is that boundary and not a threshold.
  const firstReferenceIsHit = 2;
  final orphans = <String, String>{
    for (final entry in declarations.entries)
      if (RegExp('\\b${entry.key}\\b').allMatches(corpus).length <
          firstReferenceIsHit)
        entry.key: entry.value,
  };

  test('the scan read the sources it claims to read', () {
    // 129 declarations across nine files on 2026-08-10. The floor is the
    // failure this guards: a regex that stops matching reports zero orphans and
    // passes, which is the gate quietly deleting itself. `melos run ci` would
    // stay green through it, exactly as it did through all three defects above.
    expect(
      declarations.length,
      greaterThanOrEqualTo(100),
      reason:
          'only ${declarations.length} public symbols were found under '
          'lib/src/charts/internal — the declaration scan is broken, so a '
          'green result here means nothing was checked',
    );
    expect(
      internalSources().map((file) => file.uri.pathSegments.last),
      isNot(contains('d3')),
      reason:
          'the d3 kernel is a transcription with deliberate unused corners; '
          'listSync without recurse is what excludes it, so a switch to a '
          'recursive walk must be caught here',
    );
    expect(
      corpus,
      contains('class FluentLineChart'),
      reason:
          'the reference corpus does not contain a chart, so every symbol '
          'would read as uncalled and the allowlist would grow to cover the '
          'whole subsystem',
    );
  });

  test('every public symbol under internal/ is called, or excused here', () {
    final unexcused = <String>[
      for (final entry in orphans.entries)
        if (!kChartInternalOrphanAllowlist.containsKey(entry.key))
          '${entry.key}  (${entry.value})',
    ];
    expect(
      unexcused,
      isEmpty,
      reason:
          'these symbols are declared, documented and tested under '
          'lib/src/charts/internal, and no code in lib/ calls them — a doc '
          'comment naming one is not a caller:\n${unexcused.join('\n')}\n'
          'Wire it, delete it, or add it to kChartInternalOrphanAllowlist '
          'with the reason it stays. A tested helper nothing calls is the '
          'defect this gate exists to stop, and it has shipped four times '
          'under a green suite.',
    );
  });

  test('the allowlist carries no stale entry', () {
    for (final entry in kChartInternalOrphanAllowlist.entries) {
      expect(
        declarations,
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
