/// Reads the Dart that built a section, out of the section's own page file.
///
/// ## Why the source is an asset
///
/// "Show code" has one job: show the code that rendered the thing above it. Any
/// scheme that stores the snippet *separately* — a generated map, a string
/// constant beside the builder — can drift, and will, because nothing fails
/// when it does. So the page file is declared as an asset of itself and read
/// back at runtime. What the panel prints is literally the bytes the compiler
/// compiled.
///
/// This works because Flutter's asset pipeline neither filters by extension nor
/// excludes `lib/`: `flutter_tools/lib/src/asset.dart` lists every file in a
/// declared directory and uses the raw relative path as the bundle key. Two
/// halves of that are already load-bearing in this repository —
/// `fluent_2_fonts_web` ships `lib/fonts/*.ttf` as assets, and `flutter test`
/// builds the same bundle (`--test-assets` defaults on), which is why
/// `storybook_contract_test` can verify every region without a browser.
///
/// If a future Flutter ever does exclude source files, this is the only file
/// that changes: swap [loadPageSource] for a lookup into a generated map and
/// leave [sliceDocregion], the catalog and every call site alone. That is why
/// the loader is one function in its own library.
library;

import 'package:flutter/services.dart';

/// Cache keyed by asset path. [rootBundle] already caches the decoded string,
/// but slicing and highlighting are not free, and a page re-reads its own source
/// once per expanded section.
final Map<String, Future<String>> _cache = <String, Future<String>>{};

/// Loads a page's own source, e.g. `lib/pages/components_accordion.dart`.
Future<String> loadPageSource(String assetPath) =>
    _cache.putIfAbsent(assetPath, () => rootBundle.loadString(assetPath));

/// Returns the lines between `// #docregion <id>` and `// #enddocregion <id>`,
/// dedented by the region's own indent.
///
/// Matching is per-line and trimmed rather than by substring search: a raw
/// `indexOf('// #docregion sizes')` also matches `// #docregion sizes_large`,
/// which silently returns the wrong snippet for whichever region sorts first.
///
/// Throws [StateError] when the region is missing or unterminated, so a renamed
/// section fails in `storybook_contract_test` rather than shipping an empty
/// panel.
String sliceDocregion(String source, String id) {
  final List<String> lines = source.split('\n');
  final String open = '// #docregion $id';
  final String close = '// #enddocregion $id';

  final int start = lines.indexWhere((String l) => l.trim() == open);
  if (start < 0) {
    throw StateError('docregion "$id" not found');
  }
  final int end = lines.indexWhere((String l) => l.trim() == close, start + 1);
  if (end < 0) {
    throw StateError('docregion "$id" is not terminated');
  }

  final List<String> body = lines.sublist(start + 1, end);

  // Blank lines must not drag the common indent to zero.
  int indent = 1 << 30;
  for (final String line in body) {
    if (line.trim().isEmpty) {
      continue;
    }
    final int lead = line.length - line.trimLeft().length;
    if (lead < indent) {
      indent = lead;
    }
  }
  if (indent == 1 << 30) {
    indent = 0;
  }

  return body
      .map(
        (String l) => l.length >= indent ? l.substring(indent) : l.trimLeft(),
      )
      .join('\n')
      .trim();
}
