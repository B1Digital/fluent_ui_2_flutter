import 'dart:convert';
import 'dart:io';

import 'package:fluent_2_web_example/pages.dart';
import 'package:fluent_2_web_example/shell/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// Catches invented sample data.
///
/// The pages were authored in parallel from captured upstream sources, and the
/// characteristic failure of that is not a crash — it is a page that renders
/// beautifully with plausible data nobody upstream ever wrote. "Katri Athokas"
/// becomes "Jane Doe", `$1,299.00` becomes `$1299`, and the showroom quietly
/// stops being a reference.
///
/// So this reads each page file as *text* and asserts the strings upstream
/// renders are present. It is a heuristic — the extractor guesses at what
/// counts as sample data — which is why `storybook_adaptations.json` can waive
/// individual entries with `sampleStringsSkip`, and why a waiver needs a reason
/// beside it.
void main() {
  final Map<String, dynamic> contract =
      jsonDecode(
            File('test/fixtures/storybook_contract.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final Map<String, dynamic> adaptations =
      jsonDecode(
            File('test/fixtures/storybook_adaptations.json').readAsStringSync(),
          )
          as Map<String, dynamic>;

  final Map<String, Map<String, dynamic>> byId = <String, Map<String, dynamic>>{
    for (final Map<String, dynamic> p
        in (contract['pages'] as List<dynamic>).cast<Map<String, dynamic>>())
      (p['pageId'] as String).replaceAll('--docs', ''): p,
  };

  /// Entries a recorded adaptation explicitly waives for [storyId].
  Set<String> waived(String storyId) {
    final Object? entry = adaptations[storyId];
    if (entry is! Map<String, dynamic>) {
      return const <String>{};
    }
    final Object? skip = entry['sampleStringsSkip'];
    if (skip is! List<dynamic>) {
      return const <String>{};
    }
    return skip.cast<String>().toSet();
  }

  test('every page keeps upstream sample data verbatim', () {
    final List<String> problems = <String>[];

    for (final DocsPage page in allPages) {
      final Map<String, dynamic>? captured = byId[page.id];
      if (captured == null) {
        continue;
      }
      final String source = File(page.source).readAsStringSync();

      for (final Map<String, dynamic> section
          in (captured['sections'] as List<dynamic>)
              .cast<Map<String, dynamic>>()) {
        final String storyId = section['storyId'] as String;
        final Set<String> skip = waived(storyId);

        for (final String sample
            in (section['sampleStrings'] as List<dynamic>).cast<String>()) {
          if (skip.contains(sample)) {
            continue;
          }
          // Dart string literals escape a single quote; compare against both.
          final bool present =
              source.contains(sample) ||
              source.contains(sample.replaceAll("'", r"\'"));
          if (!present) {
            problems.add('$storyId: ${jsonEncode(sample)}');
          }
        }
      }
    }

    expect(
      problems,
      isEmpty,
      reason:
          '${problems.length} upstream sample strings are missing from the '
          'Dart. Either the port invented data, or the string genuinely does '
          'not apply and belongs in storybook_adaptations.json under '
          '"sampleStringsSkip" with a reason:\n  ${problems.join('\n  ')}',
    );
  });

  test('every recorded adaptation gives a reason and a known kind', () {
    const Set<String> kinds = <String>{
      'nearest-widget',
      'slot',
      'model',
      'composed',
      'local-state',
      'trigger-required',
      'reduced',
      'platform',
    };

    adaptations.forEach((String storyId, Object? value) {
      final Map<String, dynamic> entry = value! as Map<String, dynamic>;
      expect(
        kinds,
        contains(entry['kind']),
        reason: '$storyId: unknown adaptation kind ${entry['kind']}',
      );
      expect(
        (entry['why'] as String?) ?? '',
        isNotEmpty,
        reason:
            '$storyId: an adaptation without a reason is just an undocumented '
            'difference',
      );
    });
  });

  test('every adaptation names a section that exists', () {
    final Set<String> known = <String>{
      for (final Map<String, dynamic> p
          in (contract['pages'] as List<dynamic>).cast<Map<String, dynamic>>())
        for (final Map<String, dynamic> s
            in (p['sections'] as List<dynamic>).cast<Map<String, dynamic>>())
          s['storyId'] as String,
    };

    for (final String storyId in adaptations.keys) {
      expect(
        known,
        contains(storyId),
        reason:
            '$storyId is recorded as adapted but no longer exists upstream — '
            'stale reasoning, delete it',
      );
    }
  });
}
