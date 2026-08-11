import 'dart:io';

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter_test/flutter_test.dart';

/// The programme's final sweep. Three invariants that no single component test
/// can see, because each of them is a property of the tree as a whole.
///
/// Two corrections to the plan's Step 1 code, both forced by what actually
/// landed rather than by preference:
///
/// 1. The plan asked for `barrel.contains('src/charts/internal/plotly/')` over
///    the barrel's raw text. That check cannot pass and should not: the barrel
///    names `src/charts/internal/responsive.dart` inside an explanatory comment
///    recording why the file was deleted, and it exports exactly one symbol
///    from `internal/plotly/color_adapter.dart` — `FluentPlotlyColorway`, the
///    `colorwayType` widget prop of `FluentDeclarativeChart`
///    (`DeclarativeChart.tsx:132`), which a consumer cannot set without naming.
///    The invariant the rule is really defending is that no adapter internal
///    arrives *unfiltered*, so this file scans `export` directives and demands a
///    `show` clause on any that reaches into an adapter tree.
///
/// 2. The plan's `parity:` regex demanded `file.tsx:NNN` on the marker's own
///    line. The house form, used consistently from task 2 onward, puts the
///    citation on a neighbouring comment line and shortens it to a bare
///    `` `:NNN` `` once the doc block has named the file. Fifty-three of the
///    hundred and seventy-eight markers are written that way and every one of
///    them cites correctly. The plan's own code also *passed* any line ending
///    in `parity:` unconditionally, so a marker with no citation anywhere would
///    have slipped through — the exact failure the rule exists to catch. The
///    check below reads a window instead, which fails that case and accepts the
///    house form.
void main() {
  /// Lines within which a marker's citation may sit. The house form puts the
  /// citation on the line before the marker (`internal/plotly/legends.dart:222`
  /// has it on the line after), and a doc block's file name may precede a
  /// marker by two lines (`internal/vega/transform_line.dart:800-807`), so
  /// three either way covers every shape in the tree without spanning into a
  /// neighbouring statement.
  const window = 3;

  /// A full citation: an upstream TypeScript file and a line number.
  final qualified = RegExp(r'[\w./-]+\.tsx?:\d+');

  /// The house shorthand for "the file this doc block already named", written
  /// as `` `:1399` ``, `` `:1399-1400` `` or — inside a chart's own file, where
  /// the component name is the file name — `` `.tsx:819-829` ``.
  final shorthand = RegExp(r'`(\.tsx?)?:\d+(-\d+)?`');

  List<File> chartSources(String root) => Directory(root)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  List<String> uncitedMarkers(String marker) {
    final offenders = <String>[];
    for (final file in chartSources('lib/src/charts')) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains(marker)) continue;
        final from = i - window < 0 ? 0 : i - window;
        final to = i + window + 1 > lines.length
            ? lines.length
            : i + window + 1;
        final context = lines.sublist(from, to).join(' ');
        if (qualified.hasMatch(context) || shorthand.hasMatch(context)) {
          continue;
        }
        offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
      }
    }
    return offenders;
  }

  test('all twenty charts reach a barrel consumer', () {
    // Compile-time references: a chart dropped from the barrel fails this list
    // to compile rather than failing the assertion inside it. The count is the
    // 20 top-level chart widgets under lib/src/charts — every `class Fluent…
    // extends Stat…` there, less the four `State` subclasses. It is also the
    // component count of the Oracle B manifest, where the two names that differ
    // are Legends (chrome, not a chart) standing in for AnnotationOnlyChart
    // (a chart upstream publishes no story for).
    expect(
      <Type>{
        FluentAnnotationOnlyChart,
        FluentAreaChart,
        FluentChartTable,
        FluentDeclarativeChart,
        FluentDonutChart,
        FluentFunnelChart,
        FluentGanttChart,
        FluentGaugeChart,
        FluentGroupedVerticalBarChart,
        FluentHeatMapChart,
        FluentHorizontalBarChart,
        FluentHorizontalBarChartWithAxis,
        FluentLineChart,
        FluentPolarChart,
        FluentSankeyChart,
        FluentScatterChart,
        FluentSparkline,
        FluentVegaDeclarativeChart,
        FluentVerticalBarChart,
        FluentVerticalStackedBarChart,
      },
      hasLength(20),
      reason:
          'Twenty distinct chart types must be reachable through the barrel. A '
          'duplicate entry would collapse the set and a chart added to '
          'lib/src/charts but never exported would not appear here at all, so '
          'the count is checked as well as the compilation.',
    );
  });

  test('no adapter internal reaches the barrel unfiltered', () {
    // Comments go first, then the text is split on the statement terminator
    // rather than on newlines: a narrowed export wraps its `show` clause onto a
    // second line, and a line-based scan would read the two halves as an
    // unfiltered export plus an orphan.
    final directives = File('lib/fluent_2_web.dart')
        .readAsLinesSync()
        .where((line) => !line.trimLeft().startsWith('//'))
        .join(' ')
        .split(';')
        .map((statement) => statement.trim())
        .where((statement) => statement.startsWith('export '))
        .toList();
    expect(
      directives,
      isNotEmpty,
      reason:
          'A barrel that parsed to zero export directives would make every '
          'assertion below vacuously true, so the scan is guarded before it '
          'is filtered.',
    );

    final internals = <String>[
      'src/charts/internal/plotly/',
      'src/charts/internal/vega/',
      'src/charts/internal/d3/',
    ];
    for (final directive in directives) {
      for (final internal in internals) {
        if (!directive.contains(internal)) continue;
        expect(
          directive.contains(' show '),
          isTrue,
          reason:
              'An unfiltered export of $internal would put unprefixed helper '
              'names such as applyVegaTransforms, resolveColor and jsTruthy '
              'into every consumer namespace. The one permitted entry narrows '
              'to FluentPlotlyColorway, a documented widget prop. Offending '
              'directive: $directive',
        );
      }
    }

    expect(
      directives.where((line) => line.contains('internal/responsive.dart')),
      isEmpty,
      reason:
          'internal/responsive.dart was deleted rather than hidden after the '
          'upstream analysis in the design document, section 5.1, showed the '
          'port needs nothing from withResponsiveContainer. A barrel line '
          'naming it would mean the file came back.',
    );
  });

  test('every parity marker cites an upstream file and line', () {
    expect(
      uncitedMarkers('parity:'),
      isEmpty,
      reason:
          'The bug-fidelity rule requires every reproduced defect to cite the '
          'upstream file and line it reproduces, so the code reads as intent '
          'rather than as ignorance.',
    );
  });

  test('no hardened marker is unexplained', () {
    expect(
      uncitedMarkers('hardened:'),
      isEmpty,
      reason:
          'A security or accessibility fix must name the upstream weakness it '
          'corrects, per the design document section 5.2 exceptions.',
    );
  });

  test('exactly one TextPainter is constructed under lib/src/charts', () {
    final sites = <String>[];
    for (final file in chartSources('lib/src/charts')) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].contains('TextPainter(')) {
          sites.add('${file.path}:${i + 1}');
        }
      }
    }
    expect(
      sites,
      <String>['lib/src/charts/internal/chart_text_measurer.dart:137'],
      reason:
          'Text measurement funnels through FluentChartTextMeasurer so that a '
          'single cache, a single textScaler and a single locale govern every '
          'label in the library. A second construction site is how a chart '
          'starts measuring in a different text scale from the one it paints.',
    );
  });
}
