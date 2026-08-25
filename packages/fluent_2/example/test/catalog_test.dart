import 'package:fluent_2_example/pages.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:fluent_2_example/shell/source_loader.dart';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the one indirection in this app that can fail silently.
///
/// "Show code" reads each page's own `.dart` file back out of the asset bundle
/// and slices it on a `#docregion`. Nothing about that is checked by the
/// compiler: rename a file and the asset key still parses, rename a section and
/// the marker still looks like a comment. Both failures surface as an empty
/// panel at runtime, in one section, on one page.
///
/// These tests turn both into a red build.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('page ids and section ids are unique', () {
    final List<String> pageIds = allPages.map((DocsPage p) => p.id).toList();
    expect(
      pageIds.toSet().length,
      pageIds.length,
      reason: 'two pages share an id, so one is unreachable by route',
    );

    final List<String> sectionIds = allPages
        .expand((DocsPage p) => p.sections)
        .map((DocsSection s) => s.id)
        .toList();
    expect(
      sectionIds.toSet().length,
      sectionIds.length,
      reason:
          'section ids are docregion markers and anchors; they must be unique',
    );
  });

  test('every page declares its own file as its source', () {
    for (final DocsPage page in allPages) {
      expect(
        page.source,
        'lib/pages/${page.id.replaceAll('-', '_')}.dart',
        reason: '${page.id}: source path does not follow the naming convention',
      );
    }
  });

  testWidgets('every page source is bundled as an asset', (
    WidgetTester tester,
  ) async {
    final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(
      rootBundle,
    );
    final Set<String> bundled = manifest.listAssets().toSet();

    for (final DocsPage page in allPages) {
      expect(
        bundled,
        contains(page.source),
        reason:
            '${page.id}: ${page.source} is not in the asset bundle. Check the '
            '`assets:` block in pubspec.yaml — the wildcard is not recursive.',
      );
    }
  });

  // Reads from disk, not from rootBundle, and so is a plain `test`.
  //
  // `AssetBundle.loadString` hands decoding to `compute()` — a real isolate —
  // once a payload passes 50 KB, and isolates do not run under `flutter_test`,
  // so awaiting it there hangs until the ten-minute timeout rather than
  // failing. Several page files are past that threshold. Bundling is already
  // proven by the test above; this one is about the markers, and the bytes on
  // disk are the same bytes.
  test('every section resolves its docregion', () {
    for (final DocsPage page in allPages) {
      final String source = File(page.source).readAsStringSync();
      for (final DocsSection section in page.sections) {
        expect(
          () => sliceDocregion(source, section.id),
          returnsNormally,
          reason:
              '${page.id}: no `// #docregion ${section.id}` in ${page.source}',
        );
        expect(
          sliceDocregion(source, section.id),
          isNotEmpty,
          reason: '${page.id}: docregion ${section.id} is empty',
        );
      }
    }
  });

  group('sliceDocregion', () {
    const String sample = '''
// #docregion sizes
const int a = 1;
// #enddocregion sizes
// #docregion sizes_large
const int b = 2;
// #enddocregion sizes_large
''';

    test('matches whole lines, not prefixes', () {
      // A substring search for `// #docregion sizes` also finds
      // `// #docregion sizes_large`, which would return the wrong snippet.
      expect(sliceDocregion(sample, 'sizes'), 'const int a = 1;');
      expect(sliceDocregion(sample, 'sizes_large'), 'const int b = 2;');
    });

    test('dedents by the region indent, ignoring blank lines', () {
      const String indented = '''
  // #docregion x
      const int a = 1;

        const int b = 2;
  // #enddocregion x
''';
      expect(
        sliceDocregion(indented, 'x'),
        'const int a = 1;\n\n  const int b = 2;',
      );
    });

    test('throws on a missing or unterminated region', () {
      expect(() => sliceDocregion(sample, 'nope'), throwsStateError);
      expect(
        () => sliceDocregion('// #docregion x\nconst int a = 1;\n', 'x'),
        throwsStateError,
      );
    });
  });
}
