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
/// the 90 fixtures total 3-5 MB (largest single fixture 55 KB), so the ceiling
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
      expect(
        svgs,
        isNotEmpty,
        reason: '$name records no svg at all, which is a partial capture',
      );
      expect(
        svgs.first['elements']! as List<Object?>,
        isNotEmpty,
        reason:
            '$name records an svg with no elements — a fixture with nothing '
            'in it reads as a passing test',
      );
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
}
