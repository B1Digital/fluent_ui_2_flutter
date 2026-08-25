import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Colors is the only Theme page with controls on it — the other six are
/// specimen sheets. It renders one 228-row alias table and puts two knobs above
/// it: a family menu and a free-text field. Both narrow the same table, so
/// every test below turns one of them and counts what survived. A filter that
/// leaves the table at 228 rows, or a query the table ignores, is the whole
/// defect this page can have.
void main() {
  const String page = 'theme-colors';

  /// The React name printed in every row of the table's first column.
  ///
  /// Read off the rendered `Text` widgets rather than off the catalog, because
  /// the question these suites ask is what the *table* is showing after a knob
  /// moved — the catalog never changes.
  List<String> tokenNames(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((Text text) => text.data ?? '')
      .where((String data) => data.startsWith('color'))
      .toList();

  /// Every token whose name begins with [prefix] — the page's own definition of
  /// a family, stated independently of the page's implementation of it.
  List<FluentColorToken> family(String prefix) => FluentColorToken.values
      .where((FluentColorToken token) => token.name.startsWith(prefix))
      .toList();

  group('the table', () {
    testWidgets('prints a row per alias token', (WidgetTester tester) async {
      await pumpPageBody(tester, page);

      expect(
        tokenNames(tester),
        hasLength(FluentColorToken.values.length),
        reason: 'the unfiltered table must show all 228 alias tokens',
      );
      for (final String label in <String>[
        'Design Token',
        'Light',
        'Dark',
        'Teams Light',
        'Teams Dark',
        'Teams High Contrast',
      ]) {
        expect(find.text(label), findsOneWidget, reason: 'header "$label"');
      }
    });

    testWidgets('each row paints the five themes it names', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      // One row is enough to prove the columns are wired to the themes their
      // headers name: a transposed pair would paint Teams Light's brand in the
      // Dark column, which no count of rows could ever catch.
      final Finder row = find
          .ancestor(
            of: find.text('colorBrandBackground'),
            matching: find.byType(Row),
          )
          .first;
      final List<Container> cells = tester
          .widgetList<Container>(
            find.descendant(of: row, matching: find.byType(Container)),
          )
          .toList();
      expect(cells, hasLength(5));

      const List<FluentColors> columns = <FluentColors>[
        FluentColors(),
        FluentColors(brightness: Brightness.dark),
        FluentColors(brand: FluentBrandRamp.teams),
        FluentTeamsDarkColors(),
        FluentHighContrastColors(),
      ];
      for (final (int i, FluentColors colors) in columns.indexed) {
        expect(
          cells[i].color,
          colors.resolve(FluentColorToken.brandBackground),
          reason: 'column $i must paint its own theme\'s brandBackground',
        );
      }
    });
  });

  group('the family filter', () {
    testWidgets('picking a family drops every other family, under a mouse', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      expect(tokenNames(tester), hasLength(FluentColorToken.values.length));

      // A real press, not a synthetic tap: the trigger is a transparent
      // FluentButton wrapped by FluentMenu, and a menu that opens under `tap`
      // can still be unreachable with a pointer that travels between press and
      // release.
      await mouseClick(tester, find.text('Filter'));
      expect(
        find.text('All tokens'),
        findsOneWidget,
        reason: 'a press on the trigger must open the family menu',
      );

      await mouseClick(tester, find.text('Status'));
      final List<String> filtered = tokenNames(tester);
      expect(
        filtered,
        hasLength(family('status').length),
        reason: 'Status must leave exactly the status* tokens',
      );
      expect(
        filtered.every((String name) => name.startsWith('colorStatus')),
        isTrue,
        reason: 'a non-status token survived the Status filter: $filtered',
      );
      expect(
        find.text('Filter'),
        findsNothing,
        reason: 'the trigger must name the family in force',
      );
      expect(find.text('Status'), findsOneWidget);
    });

    testWidgets('All tokens restores the whole table', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      await tapAndSettle(tester, find.text('Filter'), warnIfMissed: false);
      await tapAndSettle(tester, find.text('Brand'), warnIfMissed: false);
      expect(tokenNames(tester), hasLength(family('brand').length));

      // The trigger now reads "Brand", so this is also the proof that the menu
      // reopens from its own filtered label rather than only from "Filter".
      await tapAndSettle(tester, find.text('Brand'), warnIfMissed: false);
      await tapAndSettle(tester, find.text('All tokens'), warnIfMissed: false);
      expect(
        tokenNames(tester),
        hasLength(FluentColorToken.values.length),
        reason: 'All tokens must round-trip back to the full table',
      );
      expect(find.text('Filter'), findsOneWidget);
    });

    testWidgets('the open menu checks the family in force', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      await tapAndSettle(tester, find.text('Filter'), warnIfMissed: false);
      final Finder checkmark = find.byIcon(fluentMenuCheckmark);
      expect(
        checkmark,
        findsOneWidget,
        reason: 'exactly one row is checked, and at rest it is All tokens',
      );
      // Four pixels, not one: the 16px glyph centres two pixels above the
      // label's 20px line box. Menu rows are ~32 apart, so this tolerance
      // still cannot confuse one row for its neighbour.
      expect(
        tester.getRect(checkmark).center.dy,
        closeTo(tester.getRect(find.text('All tokens')).center.dy, 4),
        reason: 'the checkmark must sit on the row it claims to check',
      );

      await tapAndSettle(tester, find.text('Neutral'), warnIfMissed: false);
      await tapAndSettle(tester, find.text('Neutral'), warnIfMissed: false);
      expect(find.byIcon(fluentMenuCheckmark), findsOneWidget);
      expect(
        tester.getRect(find.byIcon(fluentMenuCheckmark)).center.dy,
        closeTo(tester.getRect(find.text('Neutral').last).center.dy, 4),
        reason: 'the check must move to Neutral once Neutral is in force',
      );
    });
  });

  group('the search box', () {
    testWidgets('a name query narrows the table to the names that match', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      await tester.enterText(find.byType(EditableText), 'ForegroundLink');
      await settle(tester);
      final List<String> matched = tokenNames(tester);
      expect(matched, isNotEmpty);
      expect(
        matched.length,
        lessThan(FluentColorToken.values.length),
        reason: 'a query that matches everything is a query that does nothing',
      );
      expect(
        matched.every(
          (String name) => name.toLowerCase().contains('foregroundlink'),
        ),
        isTrue,
        reason: 'the query is matched case-insensitively against the name',
      );
    });

    testWidgets('a hex query matches on the colour rather than the name', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      await tester.enterText(find.byType(EditableText), '#ffffff');
      await settle(tester);
      final List<String> matched = tokenNames(tester);
      expect(matched, isNotEmpty);
      expect(
        matched.length,
        lessThan(FluentColorToken.values.length),
        reason: 'white is not every token',
      );
      // The point of the hex leg: none of these names contain the query, so a
      // page that only searched names would show an empty table here.
      expect(
        matched.every((String name) => !name.toLowerCase().contains('ffffff')),
        isTrue,
      );
      for (final String name in matched) {
        final Finder row = find
            .ancestor(of: find.text(name), matching: find.byType(Row))
            .first;
        // The printed hex, not the `Color`: an alpha token prints `#rrggbbaa`,
        // so `colorNeutralForegroundInvertedDisabled` legitimately answers this
        // query with `#ffffff5c` — a cell whose colour is not white.
        final Iterable<String> printed = tester
            .widgetList<Text>(
              find.descendant(of: row, matching: find.byType(Text)),
            )
            .map((Text cell) => cell.data ?? '')
            .where((String data) => data.startsWith('#'));
        expect(
          printed.any((String hex) => hex.startsWith('#ffffff')),
          isTrue,
          reason: '$name matched "#ffffff" with no white cell in its row',
        );
      }
    });

    testWidgets('clearing the query restores every row', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final String before = textSnapshot(tester);

      await tester.enterText(find.byType(EditableText), 'brandStroke');
      await settle(tester);
      expect(
        tokenNames(tester).length,
        lessThan(FluentColorToken.values.length),
      );

      await tester.enterText(find.byType(EditableText), '');
      await settle(tester);
      expect(
        textSnapshot(tester),
        before,
        reason: 'an emptied field must leave the table exactly as it was',
      );
    });

    testWidgets('the query and the family filter compose', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      await tapAndSettle(tester, find.text('Filter'), warnIfMissed: false);
      await tapAndSettle(tester, find.text('Status'), warnIfMissed: false);
      await tester.enterText(find.byType(EditableText), 'danger');
      await settle(tester);

      final List<String> matched = tokenNames(tester);
      expect(matched, isNotEmpty);
      expect(
        matched.every((String name) => name.startsWith('colorStatusDanger')),
        isTrue,
        reason:
            'a row must satisfy the family AND the query, not either: '
            '$matched',
      );
      expect(
        matched.length,
        lessThan(family('status').length),
        reason: 'the query must narrow what the family filter left',
      );
    });
  });

  group('lifecycle', () {
    testWidgets('the page unmounts without throwing', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      await expectCleanTeardown(tester, page);
    });

    testWidgets('it unmounts with the menu still open', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      await tapAndSettle(tester, find.text('Filter'), warnIfMissed: false);
      expect(find.text('All tokens'), findsOneWidget);
      // The overlay outlives the widget that raised it, so tearing down while a
      // menu is up is a different code path from tearing down at rest.
      await expectCleanTeardown(tester, '$page with its menu open');
    });
  });
}
