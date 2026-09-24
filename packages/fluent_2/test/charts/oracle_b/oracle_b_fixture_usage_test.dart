// Guards the corpus against a fixture that is captured, committed, and then
// never named by a test — dead weight that reads as coverage. It has happened
// twice: `charts-sankeychart--sankey-chart-rebalance` was reported as SankeyChart
// coverage in wave 6 while no test mentioned it.
//
// "Named" is the deliberate bar, and it is stricter than "loaded". Three files
// sweep the whole corpus — `test/charts/chrome/chart_title_test.dart`,
// `test/charts/axis/tick_format_test.dart` and
// `test/charts/chrome/legend_shape_test.dart` — so every fixture on disk is
// already loaded by something, and a test asking only "was it loaded" would
// pass for all 90 forever. Those sweeps assert one property across the corpus
// (a text line box, an SI label, a legend swatch path); they say nothing about
// the story's own layout. A story whose id appears nowhere has had nothing
// component-specific asserted about it, and that is the gap this file makes
// visible.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/oracle_fixture.dart';

/// Story ids that no test names, each paired with why the fixture is still
/// committed.
///
/// An entry here is an admission, not a pass: it says the capture is on disk
/// and nothing names it. Removing an entry is the fix — write the assertion —
/// and both tests below fail if this map drifts from the corpus in either
/// direction.
///
/// Twenty-eight of ninety on 2026-08-12, of which twenty are asserted by
/// nothing whatsoever. That ratio is the point of the map: a wave report that
/// counts ninety captured fixtures as ninety verified ones overstates the
/// verified count threefold.
///
/// It read thirty and twenty-two until `test/parity/` began comparing whole
/// renders against the captured PNGs. Both declarative stories left the map
/// that way — a pixel comparison of the story upstream draws is the
/// story-specific assertion this map exists to demand, and it is a stronger
/// one than a geometry probe of the elements somebody remembered to name.
///
/// It read twenty-nine and twenty-one until the final audit measured the one
/// false negative this scan can produce. `text.contains(id)` cannot tell an
/// assertion from prose, and `charts-vegadeclarativechart--default` was spelt
/// only inside a `reason:` string in `test/charts/chrome/legend_shape_test.dart`
/// — one of the three whole-corpus sweeps this file's header names as the bar
/// it is stricter than. So the corpus's one Vega capture read as covered on the
/// strength of a sentence. The sweep now describes that story without spelling
/// its id, which is what makes this list's own count true; the swatch-count
/// assertion it lives in is unchanged.
///
/// It reads zero since `test/parity/` gained a pixel comparison for every one of
/// the ninety captured stories (2026-09-24). The map and both tests stay: a
/// capture added without a comparison of its own has to be excused here, with
/// a reason, before the suite goes green again.
///
/// The Plotly adapter's only capture,
/// `charts-declarativechart--declarative-chart-basic-example`, is on this list
/// too. Twenty-seven tasks of declarative-adapter work landed without either
/// declarative story acquiring an assertion of its own geometry.
const Map<String, String> kOracleStoriesNoTestNames = <String, String>{};

/// The package root, found by walking up from [Directory.current] until the
/// Oracle B loader appears, so this passes whether `flutter test` started at the
/// package root or in a subdirectory of it — the same walk
/// `test/support/oracle_fixture.dart` uses to find the corpus.
Directory packageRoot() {
  const marker = 'test/support/oracle_fixture.dart';
  var directory = Directory.current;
  while (true) {
    if (File('${directory.path}/$marker').existsSync()) {
      return directory;
    }
    final parent = directory.parent;
    // Reaching the filesystem root leaves parent == directory.
    if (parent.path == directory.path) {
      break;
    }
    directory = parent;
  }
  throw StateError(
    'No $marker found in ${Directory.current.path} or any ancestor, so the '
    'test sources cannot be scanned for Oracle B story ids.',
  );
}

/// This file, excluded from the scan: [kOracleStoriesNoTestNames] names every
/// excused story, so counting it would report the whole corpus as claimed.
const String _selfFileName = 'oracle_b_fixture_usage_test.dart';

void main() {
  final sources = Directory('${packageRoot().path}/test')
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (file) =>
            file.path.endsWith('.dart') &&
            file.uri.pathSegments.last != _selfFileName,
      )
      .toList(growable: false);

  test('the scan actually read the test sources', () {
    // 250 .dart files under test/ on 2026-08-10, this one excluded. The floor
    // guards the failure mode that would make every other expectation in this
    // file vacuous in the wrong direction: a walk that finds nothing reports
    // the whole corpus as unclaimed, and one that silently finds one file
    // reports it as claimed only if that file happens to be a chart test.
    expect(
      sources.length,
      greaterThanOrEqualTo(200),
      reason:
          'only ${sources.length} .dart files were found under '
          '${packageRoot().path}/test, so the scan is broken rather than the '
          'suite being small',
    );
    expect(
      sources.map((file) => file.uri.pathSegments.last),
      isNot(contains(_selfFileName)),
      reason:
          'this file names every excused story, so scanning it would report '
          'the whole corpus as claimed',
    );
  });

  final text = sources.map((file) => file.readAsStringSync()).join('\n');
  final unnamed = oracleStoryIds()
      .where((id) => !text.contains(id))
      .toList(growable: false);

  test('every captured fixture is named by a test, or excused here', () {
    final unexcused = unnamed
        .where((id) => !kOracleStoriesNoTestNames.containsKey(id))
        .toList(growable: false);
    expect(
      unexcused,
      isEmpty,
      reason:
          'these Oracle B fixtures are committed and no test mentions them, so '
          'nothing component-specific is asserted about the geometry they '
          'record:\n${unexcused.join('\n')}\n'
          'Either assert against them — a captured story is the only oracle '
          'that story will ever have — or add each to '
          'kOracleStoriesNoTestNames with the reason it stays on disk '
          'unasserted. Counting a captured fixture as an asserted one is the '
          'reporting bug this test exists to stop.',
    );
  });

  test('the excuse list carries no stale entry', () {
    final ids = oracleStoryIds().toSet();
    for (final entry in kOracleStoriesNoTestNames.entries) {
      expect(
        ids,
        contains(entry.key),
        reason:
            '${entry.key} is excused here but is not in the corpus, so either '
            'the fixture was deleted or the id is misspelt — a typo excuses '
            'nothing and hides a real gap',
      );
      expect(
        unnamed,
        contains(entry.key),
        reason:
            '${entry.key} is excused here but a test now names it, so delete '
            'the entry: an excuse that outlives its gap makes the list read as '
            'longer than the gap really is',
      );
      expect(
        entry.value.trim(),
        isNotEmpty,
        reason:
            '${entry.key} is excused with no reason, which is the same silent '
            'omission as leaving it off the list',
      );
    }
  });
}
