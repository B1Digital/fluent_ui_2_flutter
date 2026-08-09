import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final kernel = Directory('lib/src/charts/internal/d3');

  List<File> sources() =>
      kernel
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('the kernel has all 28 files', () {
    expect(
      sources().map((f) => f.uri.pathSegments.last).toList(),
      orderedEquals(<String>[
        'array_stats.dart',
        'axis_geometry.dart',
        'bin.dart',
        'color.dart',
        'curves.dart',
        'format.dart',
        'format_spec.dart',
        'interpolate.dart',
        'js_math.dart',
        'path_sink.dart',
        'sankey.dart',
        'scale.dart',
        'scale_band.dart',
        'scale_continuous.dart',
        'scale_linear.dart',
        'scale_log.dart',
        'scale_tick_format.dart',
        'scale_time.dart',
        'shape_arc.dart',
        'shape_line_area.dart',
        'shape_pie.dart',
        'shape_radial.dart',
        'shape_stack.dart',
        'stable_sort.dart',
        'ticks.dart',
        'time_format.dart',
        'time_interval.dart',
        'time_ticks.dart',
      ]),
      reason:
          'the contract enumerates 28 files in §2.1-2.28; a missing one is '
          'a plan that stopped early',
    );
  });

  test('no file in the kernel imports package:flutter', () {
    // The plan spelled this as `contains('package:flutter/')` over the whole
    // file, but `axis_geometry.dart:37` and `curves.dart:9` both *name*
    // package:flutter in prose explaining why they do not import it, so the
    // literal check false-positives on its own documentation. The boundary
    // lives in the directives, so only those are read.
    for (final file in sources()) {
      final directives = file
          .readAsLinesSync()
          .where(
            (line) => line.startsWith('import ') || line.startsWith('export '),
          )
          .toList();
      expect(
        directives.where((line) => line.contains('package:flutter/')),
        isEmpty,
        reason:
            '${file.path} — internal/d3 is pure maths so the riskiest '
            '5,500 lines in the subsystem are testable without a widget tree '
            '(design spec §3.1). dart:ui and dart:math are allowed',
      );
    }
  });

  test('nothing in the kernel is exported from the barrel', () {
    // Anchored to real `export`/`import` directives, not a raw substring scan.
    // The barrel *documents* this boundary in a comment, and a substring scan
    // fails on that prose — the guard tripping over the sentence explaining
    // the guard. `melos run no-material` anchors the same way, for the same
    // reason.
    final directives = File('lib/fluent_2_web.dart')
        .readAsLinesSync()
        .where((line) => RegExp(r'^\s*(export|import)\s').hasMatch(line))
        .toList(growable: false);
    expect(
      directives.where((line) => line.contains('charts/internal/d3')),
      isEmpty,
      reason:
          'contract §0.3 — d3\'s unprefixed names (ticks, format, line, '
          'arc, min, max) must not reach a consumer namespace. Tests deep '
          'import instead',
    );
    expect(
      directives,
      isNotEmpty,
      reason:
          'a directive filter that matched nothing would let the assertion '
          'above pass vacuously',
    );
  });

  test('every public declaration carries a doc comment', () {
    // public_member_api_docs is an analyzer info and `dart analyze
    // --fatal-infos` already fails on it, but the kernel is unexported and it
    // is worth failing loudly here too rather than at CI.
    final undocumented = <String>[];
    for (final file in sources()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final isPublicDeclaration = RegExp(
          r'^(abstract |final |sealed |base )*(class|enum|typedef|mixin) [A-Z]',
        ).hasMatch(line);
        if (!isPublicDeclaration) {
          continue;
        }
        final previous = i > 0 ? lines[i - 1].trimLeft() : '';
        if (!previous.startsWith('///')) {
          undocumented.add('${file.path}:${i + 1}  $line');
        }
      }
    }
    expect(
      undocumented,
      isEmpty,
      reason: 'public_member_api_docs is enforced package-wide',
    );
  });
}
