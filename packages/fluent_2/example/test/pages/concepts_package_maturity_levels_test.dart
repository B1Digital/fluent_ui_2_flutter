import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/docs_metrics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Package Maturity Levels is the corpus's hardest markdown: two pipe tables,
/// three thematic breaks, four emoji headings and inline code in almost every
/// paragraph. It is on this page that a "renderer" which flattens everything to
/// prose still looks plausible — every word is present, the tables are simply
/// gone. So the tests below are about STRUCTURE: how many tables, how many
/// columns, which cell holds which value, and what a `---` became.
void main() {
  const String page = 'concepts-package-maturity-levels';

  /// The item text of every bullet, in document order.
  List<String> bullets(WidgetTester tester) {
    final Finder markers = find.text('•  ');
    return <String>[
      for (int i = 0; i < markers.evaluate().length; i++)
        tester
                .widgetList<Text>(
                  find.descendant(
                    of: find
                        .ancestor(of: markers.at(i), matching: find.byType(Row))
                        .first,
                    matching: find.byType(Text),
                  ),
                )
                .last
                .textSpan
                ?.toPlainText() ??
            '',
    ];
  }

  /// The cells of table [at], row by row.
  List<List<String>> tableCells(WidgetTester tester, int at) {
    final Table table = tester.widget<Table>(find.byType(Table).at(at));
    return <List<String>>[
      for (final TableRow row in table.children)
        <String>[
          for (final Widget cell in row.children)
            tester
                    .widgetList<Text>(
                      find.descendant(
                        of: find.byWidget(cell),
                        matching: find.byType(Text),
                      ),
                    )
                    .first
                    .textSpan
                    ?.toPlainText() ??
                '',
        ],
    ];
  }

  group('the document', () {
    testWidgets('drops its own leading heading, which the scaffold drew', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      expect(find.text('Package Maturity Levels'), findsNothing);
      expect(
        find.textContaining('This document explains the different maturity'),
        findsOneWidget,
      );
    });

    testWidgets('every section keeps the level its source gives it', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      for (final String heading in <String>[
        'Overview',
        'Package Categories',
        'Quick Reference',
      ]) {
        expect(
          textStyleOf(tester, find.text(heading))?.fontSize,
          DocsMetrics.h2.fontSize,
          reason: '$heading is an h2 in the source',
        );
      }
      // The emoji are part of the heading text, not decoration beside it: a
      // renderer that dropped them would leave four headings reading "Stable
      // Packages", "Preview Packages"… with the colour coding gone.
      for (final String level in <String>['🟢', '🟡', '🔵', '🔴']) {
        expect(
          textStyleOf(
            tester,
            find.text('$level ${_names[level]} Packages'),
          )?.fontSize,
          DocsMetrics.h3.fontSize,
          reason: '$level heading level',
        );
      }
    });

    testWidgets('the three thematic breaks render as rules', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      // `---` separates the four category sections. Dropped, the page becomes
      // one undifferentiated wall; rendered as text, it becomes three stray
      // dashes.
      final Finder rules = find.byWidgetPredicate(
        (Widget widget) =>
            widget is ColoredBox && widget.color == DocsMetrics.rule,
      );
      expect(rules, findsNWidgets(3));
      expect(find.text('---'), findsNothing);
      for (int i = 0; i < 3; i++) {
        expect(tester.getRect(rules.at(i)).height, 1);
      }
    });

    testWidgets('the Overview list is four bullets, one per level', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      const List<String> levels = <String>[
        '🟢 Stable',
        '🟡 Preview',
        '🔵 Compat',
        '🔴 Deprecated',
      ];
      final List<String> items = bullets(tester);
      for (final (int i, String level) in levels.indexed) {
        expect(
          items[i],
          startsWith(level),
          reason:
              'bullet $i must begin at its own label, not at whitespace: '
              '"${items[i]}"',
        );
      }
    });

    testWidgets('package names keep the monospace face', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      final Finder paragraph = find.textContaining(
        'Examples: @fluentui/react-button',
      );
      expect(
        inlineRuns(
          tester,
          paragraph,
          (TextStyle style) => style.fontFamily == FluentFontFamily.monospace,
        ).map((TextSpan span) => span.text),
        <String>['@fluentui/react-button', '@fluentui/react-text'],
        reason: 'the two package names are code, and the prose between is not',
      );
    });
  });

  group('the pipe tables', () {
    testWidgets('both render as tables rather than as pipes', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      expect(
        find.byType(Table),
        findsNWidgets(2),
        reason: 'the Migration Guide and the Quick Reference are both tables',
      );
      expect(
        find.textContaining('| --- |'),
        findsNothing,
        reason: 'a table rendered as text keeps its delimiter row',
      );
    });

    testWidgets('the migration guide pairs each package with its successor', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      expect(tableCells(tester, 0), <List<String>>[
        <String>['Deprecated Package', 'Stable Alternative'],
        <String>[
          '@fluentui/react-alert',
          '@fluentui/react-components (Toast, MessageBar)',
        ],
        <String>[
          '@fluentui/react-infobutton',
          '@fluentui/react-components (InfoLabel)',
        ],
      ]);
    });

    testWidgets('the quick reference keeps all five of its columns', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final List<List<String>> cells = tableCells(tester, 1);

      // Five columns is the point of this table: it is read across, and a
      // renderer that dropped or merged one would still print every word.
      expect(cells, hasLength(5));
      expect(cells.first, <String>[
        'Maturity Level',
        'Version Format',
        'Production Ready',
        'Breaking Changes',
        'Import Source',
      ]);
      expect(cells[1].first, '🟢 Stable');
      expect(cells[1][2], '✅ Yes');
      expect(cells.last.first, '🔴 Deprecated');
      expect(cells.last[2], '❌ No');
      for (final List<String> row in cells) {
        expect(row, hasLength(5), reason: 'a short row would break the grid');
      }
    });

    testWidgets('the header row is set apart from the body rows', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      // `th` and `td` differ only in weight and colour here, and that is the
      // only thing telling a reader where the data starts.
      final Finder header = find.text('Maturity Level');
      expect(
        inlineRuns(
          tester,
          header,
          (TextStyle style) =>
              style.fontWeight == FontWeight.w600 &&
              style.color == DocsMetrics.headingText,
        ),
        hasLength(1),
      );
      expect(
        inlineRuns(
          tester,
          find.text('Version Format'),
          (TextStyle style) => style.fontWeight == FontWeight.w600,
        ),
        hasLength(1),
      );
      expect(
        inlineRuns(
          tester,
          find.text('🟢 Stable'),
          (TextStyle style) => style.fontWeight == FontWeight.w600,
        ),
        isEmpty,
        reason: 'a body cell must not be dressed as a header',
      );
    });

    testWidgets('the columns line up down the table', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      // A `Table`, not a `Column` of `Row`s, is what makes the pipes' promise
      // true: every cell in a column shares a left edge whatever its neighbours
      // hold.
      final double headerLeft = tester.getRect(find.text('Import Source')).left;
      expect(
        tester
            .getRect(find.text('@fluentui/react-components/unstable').last)
            .left,
        headerLeft,
        reason: 'the last column is ragged',
      );
    });
  });

  group('lifecycle', () {
    testWidgets('a real click on the page changes nothing', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final String before = textSnapshot(tester);

      // A document viewer, not a control surface: nothing here takes a press,
      // and a synthetic tap could not tell that apart from an affordance that
      // only appears under a hovering pointer.
      await mouseClick(tester, find.text('Quick Reference'));
      expect(textSnapshot(tester), before);
    });

    testWidgets('the page unmounts without throwing', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      await expectCleanTeardown(tester, page);
    });
  });
}

/// The word between the emoji and "Packages" in each category heading.
const Map<String, String> _names = <String, String>{
  '🟢': 'Stable',
  '🟡': 'Preview',
  '🔵': 'Compat',
  '🔴': 'Deprecated',
};
