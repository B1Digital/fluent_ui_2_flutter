// Corpus invariants for Oracle B (charts design spec §4.3). This file reads the
// JSON directly rather than through test/support/oracle_fixture.dart, because
// its whole job is to catch a corpus the loader would happily parse: an empty
// one, a half-captured one, or one whose skip register has quietly swallowed a
// component.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The corpus directory, found by walking up from [Directory.current] until the
/// manifest appears — so this passes whether `flutter test` started at the
/// package root or in a subdirectory of it, matching
/// `test/support/spec_fixture.dart`.
Directory corpusDirectory() {
  const relative = 'test/fixtures/charts/oracle_b';
  var directory = Directory.current;
  while (true) {
    final candidate = Directory('${directory.path}/$relative');
    if (File('${candidate.path}/_manifest.json').existsSync()) {
      return candidate;
    }
    final parent = directory.parent;
    // Reaching the filesystem root leaves parent == directory.
    if (parent.path == directory.path) {
      break;
    }
    directory = parent;
  }
  throw StateError(
    'No $relative/_manifest.json found in ${Directory.current.path} or any '
    'ancestor. Capture it with '
    '`cd crawlers/storybooks-fluentui && node capture_oracle.mjs` — see '
    '$relative/README.md.',
  );
}

Map<String, dynamic> _json(File file) =>
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

/// The one `@fluentui/react-charts` release this whole programme is ported
/// against, and therefore the only release this corpus may describe. It is the
/// same pin plan 01's d3 extractor uses. Re-capture needs the network, so CI can
/// verify these fixtures but never regenerate them: without this pin an upstream
/// release changes the live charts while the corpus goes on asserting the old
/// geometry, silently and for as long as nobody notices.
const kPinnedUpstreamVersion = '9.3.23';

/// The agreed ceiling on the whole corpus, in bytes: 8 MiB. Measured 2026-08-08,
/// the 90 fixtures total 3.17 MiB (largest single fixture 551 KB, which is
/// charts-linechart--line-chart-large-data.json), so the ceiling
/// is about twice the measurement — headroom for a legitimately richer story,
/// none for a capture that starts recording something enormous.
/// `test/goldens/README.md` holds its images to ~256 KB the same way.
const kCorpusCeilingBytes = 8 * 1024 * 1024;

void main() {
  final corpus = corpusDirectory();
  final manifest = _json(File('${corpus.path}/_manifest.json'));
  final fixtures = corpus
      .listSync()
      .whereType<File>()
      .where(
        (file) =>
            file.path.endsWith('.json') &&
            !file.uri.pathSegments.last.startsWith('_'),
      )
      .toList(growable: false);

  test('the corpus is not empty', () {
    // A capture that wrote nothing is the failure mode spec §4.3 names: it
    // reads as a passing test with zero fixtures.
    expect(
      fixtures,
      isNotEmpty,
      reason:
          'test/fixtures/charts/oracle_b holds no story fixtures. Re-run '
          'the capture rather than letting an empty corpus pass.',
    );
    expect(
      fixtures.length,
      manifest['capturedCount'],
      reason:
          'the manifest claims ${manifest['capturedCount']} captures but '
          '${fixtures.length} fixtures are on disk',
    );
  });

  test('the corpus is pinned to the same upstream version as the extractor', () {
    expect(
      manifest['upstreamVersion'],
      kPinnedUpstreamVersion,
      reason:
          'this corpus describes @fluentui/react-charts '
          '${manifest['upstreamVersion']}, but the programme is pinned to '
          '$kPinnedUpstreamVersion, the version plan 01 pins too. '
          'CI cannot re-capture, because storybooks.fluentui.dev is not '
          'reachable from a test run, so a mismatch here is the only thing '
          'standing between an upstream release and a corpus that goes on '
          'asserting superseded geometry indefinitely. Either re-capture '
          'against the new pin (bump UPSTREAM_VERSION in capture_oracle.mjs, '
          'then cd crawlers/storybooks-fluentui && node capture_oracle.mjs) or '
          'restore the old one. Moving this constant on its own is not a fix — '
          'see test/fixtures/charts/oracle_b/README.md.',
    );
  });

  test('the capture conditions match the ones the port is tested under', () {
    expect(
      manifest['deviceScaleFactor'],
      1,
      reason:
          'spec §5.5: deviceScaleFactor 1 is what pins d3-axis to '
          'offset 0.5, and flutter test runs at DPR 1',
    );
    expect(
      manifest['crispOffset'],
      0.5,
      reason: 'd3-axis/src/axis.js:38 — offset is 0.5 at DPR 1',
    );
    final viewport = manifest['viewport']! as Map<String, dynamic>;
    expect(
      viewport['width'],
      1024,
      reason:
          'the widest chart measured is 944px; a narrower viewport would '
          'reflow it and every captured x coordinate would be wrong',
    );
  });

  test('every enumerated story was either captured or skipped with a reason', () {
    final skipped = (manifest['skipped']! as List<Object?>)
        .cast<Map<String, dynamic>>();
    expect(
      (manifest['capturedCount']! as int) + skipped.length,
      manifest['storyCount'],
      reason:
          'stories vanished between enumeration and disk — every one of the '
          '${manifest['storyCount']} stories must be captured or registered as '
          'skipped, never silently dropped',
    );
    // 90 stories measured live on 2026-08-08; 80 is the floor below which the
    // index itself must have moved.
    expect(
      manifest['storyCount'],
      greaterThanOrEqualTo(80),
      reason:
          'index.json enumerated fewer than 80 stories, so the enumeration '
          'is broken rather than coverage being thin',
    );
    expect(
      skipped.length,
      lessThanOrEqualTo(4),
      reason:
          'more than four stories failed to render — look at the skip '
          'register before trusting the corpus:\n'
          '${skipped.map((e) => '${e['id']}: ${e['reason']}').join('\n')}',
    );
    for (final entry in skipped) {
      expect(
        (entry['reason']! as String).trim(),
        isNotEmpty,
        reason: '${entry['id']} was skipped with no reason recorded',
      );
    }
  });

  test('no component captured zero stories', () {
    final perComponent =
        manifest['storiesPerComponent']! as Map<String, dynamic>;
    final capturedPerComponent =
        manifest['capturedPerComponent']! as Map<String, dynamic>;
    for (final component in perComponent.keys) {
      expect(
        capturedPerComponent[component] ?? 0,
        greaterThan(0),
        reason:
            '$component has ${perComponent[component]} stories upstream and '
            'none of them captured, so every geometry number in that chart '
            'still rests on hand-derivation',
      );
    }
  });

  test('every Legends story is captured, HTML-only or not', () {
    // Upstream draws the legend in HTML apart from its shape svg
    // (`Legends.tsx`), and three of the five stories —
    // charts-legends--legends-overflow, --legends-styled and
    // --legends-wrap-lines — render their swatches as `fui-legend__rect` divs
    // and no svg at all. Their overflow and wrapping geometry has no other
    // oracle: plan 04's legend tasks would fall back to hand-derivation
    // without them, so a capture that drops them for lacking an svg is a
    // regression in the script, not thin upstream coverage.
    final perComponent =
        manifest['storiesPerComponent']! as Map<String, dynamic>;
    final capturedPerComponent =
        manifest['capturedPerComponent']! as Map<String, dynamic>;
    expect(
      capturedPerComponent['Legends'],
      perComponent['Legends'],
      reason:
          'only ${capturedPerComponent['Legends']} of '
          '${perComponent['Legends']} Legends stories are in the corpus. An '
          'HTML-only story — empty `svgs`, non-empty `htmlBoxes` — is a valid '
          'fixture, so re-capture with a script that writes one instead of '
          'registering the story as a skip.',
    );
  });

  test('the thin components are the ones the coverage report named', () {
    // Sanity anchor, measured live 2026-08-08: these eight have fewer than
    // three stories upstream, so their geometry leans on Oracle A and
    // hand-derivation. A diff here is a re-capture to review, not a regression.
    expect(
      (manifest['thinComponents']! as List<Object?>).cast<String>(),
      <String>[
        'ChartTable',
        'DeclarativeChart',
        'FunnelChart',
        'GanttChart',
        'HeatMapChart',
        'PolarChart',
        'Sparkline',
        'VegaDeclarativeChart',
      ],
      reason:
          'upstream story coverage changed — read the coverage report from '
          'the capture run and update this anchor deliberately',
    );
  });

  test('every fixture is complete and self-describing', () {
    for (final file in fixtures) {
      final name = file.uri.pathSegments.last;
      final story = _json(file);
      expect(
        '${story['id']}.json',
        name,
        reason:
            '$name holds story id ${story['id']}, so the file was renamed '
            'or the capture wrote to the wrong path',
      );
      expect(
        story['upstreamVersion'],
        manifest['upstreamVersion'],
        reason:
            '$name was captured from a different upstream version than the '
            'manifest claims — the corpus is mixed',
      );
      expect(
        story['deviceScaleFactor'],
        1,
        reason:
            '$name was captured at a device scale factor other than 1, so '
            'its crispness offset is not 0.5 (spec §5.5)',
      );
      final svgs = (story['svgs']! as List<Object?>)
          .cast<Map<String, dynamic>>();
      final htmlBoxes = (story['htmlBoxes']! as List<Object?>)
          .cast<Map<String, dynamic>>();
      // An HTML-only fixture is legitimate: Legends renders its swatches as
      // `fui-legend__rect` divs, so three of the five Legends stories have no
      // svg whatsoever, and their overflow and wrapping geometry is exactly
      // what plan 04 needs. What is never legitimate is a fixture with
      // neither, which records nothing and reads as a passing test — that
      // story belongs in the skip register with a reason.
      expect(
        svgs.isNotEmpty || htmlBoxes.isNotEmpty,
        isTrue,
        reason:
            '$name records neither an svg nor an html box, which is a partial '
            'capture. A story that renders nothing measurable belongs in the '
            "manifest's skip register with a reason, not on disk as an empty "
            'fixture.',
      );
      if (svgs.isNotEmpty) {
        expect(
          svgs.first['elements']! as List<Object?>,
          isNotEmpty,
          reason:
              '$name records an svg with no elements — a fixture with nothing '
              'in it reads as a passing test',
        );
      }
      expect(
        (story['width']! as num).toDouble(),
        greaterThan(0),
        reason: '$name records a zero-width chart',
      );
    }
  });

  test('no partial write was left behind', () {
    final leftovers = corpus
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.tmp'))
        .map((file) => file.uri.pathSegments.last)
        .toList(growable: false);
    expect(
      leftovers,
      isEmpty,
      reason:
          'the capture writes to <id>.json.tmp and renames on success, so a '
          'surviving .tmp is a crashed run: $leftovers',
    );
  });

  test('the corpus stays inside its agreed size ceiling', () {
    final bytes = fixtures.fold<int>(0, (sum, file) => sum + file.lengthSync());
    expect(
      bytes,
      lessThan(kCorpusCeilingBytes),
      reason:
          'the corpus is ${(bytes / 1024 / 1024).toStringAsFixed(1)} MiB, '
          'over the agreed ceiling of '
          '${kCorpusCeilingBytes ~/ (1024 * 1024)} MiB. It measured 3-5 MB for '
          '90 stories, so something is now being recorded that was not before. '
          'Coarsen what the capture records rather than committing it, exactly '
          'as test/goldens/README.md says to coarsen a grid rather than add a '
          'megabyte of PNG. Raising this ceiling is a decision, not a fix.',
    );
  });

  test('the README documents the corpus and the exact re-capture command', () {
    final readme = File('${corpusDirectory().path}/README.md');
    expect(
      readme.existsSync(),
      isTrue,
      reason:
          'crawlers/ is gitignored, so this README is the only tracked '
          'record of how to regenerate the corpus',
    );
    final text = readme.readAsStringSync();
    for (final required in <String>[
      // The command oracle_fixture.dart's StateError tells a reader to run.
      'node capture_oracle.mjs',
      'crawlers/storybooks-fluentui',
      // The two facts a consumer must not get wrong. `contains` is
      // case-sensitive, and the README writes this one capitalised.
      'deviceScaleFactor',
      'Never construct',
      // The ceiling, stated as plainly as test/goldens/README.md states its.
      'advisory',
      // The three Legends stories have no svg at all. A reader who does not
      // know that reaches for OracleStory.primary and gets a StateError, or
      // worse, counts all 17 fui-legend__rect boxes when only 6 are visible.
      'HTML-only',
      // The size budget, so the prose and kCorpusCeilingBytes cannot drift
      // apart: whoever raises one has to raise the other.
      '8 MiB',
      // The upstream pin, for the same reason. Bumping
      // kPinnedUpstreamVersion without re-capturing now fails two tests, and
      // one of them says so in words a maintainer can act on.
      kPinnedUpstreamVersion,
      // CI verifies the committed corpus and cannot regenerate it, because
      // re-capture needs storybooks.fluentui.dev. A reader who does not know
      // that will wait for a green CI run to catch upstream drift.
      'cannot regenerate',
    ]) {
      expect(
        text,
        contains(required),
        reason:
            'the README must state "$required" — a regeneration hint that '
            'drifts from the loader\'s error message is worse than none',
      );
    }
  });
}
