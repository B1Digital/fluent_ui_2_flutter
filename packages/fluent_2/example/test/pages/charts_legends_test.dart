import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Legends' page is five strips of one component under five configurations, and
/// the component ships no separate knobs — the rows *are* the controls. So the
/// tests below press a row, or one of the controlled demo's three buttons, and
/// read the answer off [FluentChartLegendRow]: `selected` is where "this series
/// is chosen" reaches the paint and `dimmed` is where "every other series is
/// filtered out" does. A strip that moved its own `_selected` set without
/// re-rendering a row would satisfy neither.
void main() {
  const String page = 'charts-legends';

  group('legends basic', () {
    final DocsSection section = sectionOf('charts-legends--legends-basic');

    testWidgets('pressing a legend selects it, dims the rest and reports it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_rows(tester), hasLength(4));
      expect(_selectedTitles(tester), isEmpty);
      expect(_dimmedTitles(tester), isEmpty);

      await tapAndSettle(tester, find.text('Legend 1'), what: 'Legend 1');
      expect(_selectedTitles(tester), <String>['Legend 1']);
      expect(
        _dimmedTitles(tester),
        <String>['Legend 2', 'Legend 3', 'Legend 4'],
        reason: 'selecting one series must filter out every other one',
      );
      // Upstream raises a browser alert here; the port writes the same sentence
      // under the strip, so this is the row's `onAction` reaching the demo.
      expect(find.text('Legend1 clicked'), findsOneWidget);

      await tapAndSettle(tester, find.text('Legend 1'), what: 'Legend 1');
      expect(
        _selectedTitles(tester),
        isEmpty,
        reason: 'pressing the selected legend again must clear the selection',
      );
      expect(_dimmedTitles(tester), isEmpty);
    });

    testWidgets('a second legend replaces the first in single-select mode', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(tester, find.text('Legend 1'), what: 'Legend 1');
      await tapAndSettle(tester, find.text('Legend 3'), what: 'Legend 3');
      expect(
        _selectedTitles(tester),
        <String>['Legend 3'],
        reason: 'single-select must swap the selection, not accumulate it',
      );
      expect(find.text('Legend3 clicked'), findsOneWidget);
      expect(find.text('Legend1 clicked'), findsNothing);
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('a real mouse press selects a legend', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The primary affordance of the whole page, driven the way a browser
      // drives it: a row is a `FluentInteractive` inside a `MouseRegion` that
      // also reports hover, and the press travels two pixels — enough for a
      // scrollable's drag recogniser to claim it and for the click never to
      // land, which `tester.tap` cannot see.
      await mouseClick(tester, find.text('Legend 2'));
      expect(
        _selectedTitles(tester),
        <String>['Legend 2'],
        reason: 'a mouse press on a row must select it, not merely hover it',
      );
      expect(find.text('Legend2 clicked'), findsOneWidget);
    });
  });

  group('legends overflow', () {
    final DocsSection section = sectionOf('charts-legends--legends-overflow');

    testWidgets('the tail of the strip collapses into a counted trigger', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Not a hard row count: the visible tally is solved from measured label
      // widths, and `flutter_test`'s square-glyph font measures nothing like
      // Selawik. What must hold at any font is that the strip gave way, that it
      // kept at least one row, and that the trigger counts exactly the rows it
      // swallowed.
      final int visible = _rows(tester).length;
      expect(visible, greaterThan(0));
      expect(
        visible,
        lessThan(17),
        reason: 'seventeen legends cannot fit the 800px strip',
      );
      expect(find.text('+${17 - visible} Overflow Items'), findsOneWidget);
      expect(
        find.text('Legend 17'),
        findsNothing,
        reason: 'a legend in the overflow menu must not also be on the strip',
      );
    });

    testWidgets('the overflow trigger opens a menu that still selects', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final int visible = _rows(tester).length;

      await openOverlay(tester, find.textContaining('Overflow Items'));
      expect(
        find.text('Legend 17'),
        findsOneWidget,
        reason: 'the menu must hold the legends the strip could not show',
      );

      await tapAndSettle(tester, find.text('Legend 17'), what: 'Legend 17');
      expect(
        _selectedTitles(tester),
        isEmpty,
        reason: 'the selected legend is in the menu, not on the strip',
      );
      expect(
        _dimmedTitles(tester),
        hasLength(visible),
        reason:
            'selecting a hidden legend must filter out every visible row — a '
            'menu row that only closed the menu would leave the strip lit',
      );
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the trigger opens under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.textContaining('Overflow Items'));
      await tester.pump(const Duration(milliseconds: 450));
      await settle(tester);
      expect(
        find.text('Legend 17'),
        findsOneWidget,
        reason: 'a mouse press on the trigger must open the overflow menu',
      );
    });
  });

  group('legends styled', () {
    final DocsSection section = sectionOf('charts-legends--legends-styled');

    testWidgets('the styled strip carries its own palette', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The one thing that separates this section from Legends Overflow, which
      // is otherwise the same seventeen rows under the same props: it starts at
      // the first data-viz colour where the overflow story starts at the fifth.
      expect(
        _rows(tester).first.item.color,
        FluentDataVizPalette.resolve(FluentDataVizToken.color1),
      );
    });

    testWidgets('a real mouse press selects a row and dims its neighbours', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final int visible = _rows(tester).length;

      await mouseClick(tester, find.text('Legend 2'));
      expect(_selectedTitles(tester), <String>['Legend 2']);
      expect(_dimmedTitles(tester), hasLength(visible - 1));

      await mouseClick(tester, find.text('Legend 2'));
      expect(
        _selectedTitles(tester),
        isEmpty,
        reason: 'a second press must clear the selection again',
      );
      expect(_dimmedTitles(tester), isEmpty);
    });
  });

  group('legends wrap lines', () {
    final DocsSection section = sectionOf('charts-legends--legends-wrap-lines');

    testWidgets('wrapping shows every legend and retires the trigger', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        _rows(tester),
        hasLength(17),
        reason: 'enabledWrapLines has no overflow branch at all',
      );
      expect(find.textContaining('Overflow Items'), findsNothing);
      expect(find.byType(FluentButton), findsNothing);
      // The rows must actually be on more than one line; a `Wrap` that laid its
      // children out in a single clipped row would still report seventeen.
      expect(
        _rowTops(tester).length,
        greaterThan(1),
        reason: 'seventeen rows in an 800px strip must occupy several lines',
      );
    });

    testWidgets('a wrapped row still selects under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // A row on the second line, so this also proves the wrapped branch's rows
      // are hit-testable where they were laid out rather than where the first
      // line put them.
      await mouseClick(tester, find.text('Legend 12'));
      expect(_selectedTitles(tester), <String>['Legend 12']);
      expect(_dimmedTitles(tester), hasLength(16));
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('legends controlled', () {
    final DocsSection section = sectionOf('charts-legends--legends-controlled');

    testWidgets('each button drives both the strip and the readout', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Selected legends: '), findsOneWidget);

      await tapAndSettle(tester, find.text('Select 1 and 3'));
      expect(_selectedTitles(tester), <String>['Legend 1', 'Legend 3']);
      expect(_dimmedTitles(tester), <String>['Legend 2', 'Legend 4']);
      expect(find.text('Selected legends: Legend 1, Legend 3'), findsOneWidget);

      await tapAndSettle(tester, find.text('Select 2 and 4'));
      expect(
        _selectedTitles(tester),
        <String>['Legend 2', 'Legend 4'],
        reason: 'a controlled strip must adopt whatever the parent hands it',
      );
      expect(find.text('Selected legends: Legend 2, Legend 4'), findsOneWidget);

      await tapAndSettle(tester, find.text('Select all'));
      expect(_selectedTitles(tester), hasLength(4));
      expect(
        _dimmedTitles(tester),
        isEmpty,
        reason: 'nothing is filtered out when everything is selected',
      );
    });

    testWidgets('pressing a row round-trips through the parent', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tapAndSettle(tester, find.text('Select all'));

      // The controlled path proper: `_handlePressed` deliberately does not
      // update the widget's own state, so the row can only change if `onChange`
      // reached the parent and the parent handed a new list back down.
      await mouseClick(tester, find.text('Legend 1'));
      expect(
        _selectedTitles(tester),
        <String>['Legend 2', 'Legend 3', 'Legend 4'],
        reason: 'deselecting one of four must leave the other three selected',
      );
      expect(
        find.text('Selected legends: Legend 2, Legend 3, Legend 4'),
        findsOneWidget,
      );
      expect(_dimmedTitles(tester), <String>['Legend 1']);
    });

    testWidgets('multi-select accumulates from an empty selection', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(tester, find.text('Legend 1'), what: 'Legend 1');
      await tapAndSettle(tester, find.text('Legend 2'), what: 'Legend 2');
      expect(
        _selectedTitles(tester),
        <String>['Legend 1', 'Legend 2'],
        reason: 'this strip is multi-select; the second press must add',
      );
      expect(find.text('Selected legends: Legend 1, Legend 2'), findsOneWidget);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection each in sectionsOf(page)) {
        await pumpSection(tester, each);
        await expectCleanTeardown(tester, each.id);
      }
    });
  });
}

/// Every legend row on the strip, in strip order.
///
/// Rows in the overflow menu are [FluentMenuItem]s rather than rows, so this
/// counts exactly what the strip itself is showing.
List<FluentChartLegendRow> _rows(WidgetTester tester) => tester
    .widgetList<FluentChartLegendRow>(find.byType(FluentChartLegendRow))
    .toList();

/// The titles the strip is rendering as selected.
List<String> _selectedTitles(WidgetTester tester) => <String>[
  for (final FluentChartLegendRow row in _rows(tester))
    if (row.selected) row.item.title,
];

/// The titles the strip is rendering in its filtered-out treatment.
///
/// Selection and dimming are separate props for a reason — a selected legend
/// stays lit while another is hovered — so a suite that only read `selected`
/// would pass on a strip that never dimmed anything.
List<String> _dimmedTitles(WidgetTester tester) => <String>[
  for (final FluentChartLegendRow row in _rows(tester))
    if (row.dimmed) row.item.title,
];

/// The distinct baselines the rows were laid out on.
///
/// Every row carries a `ValueKey` of its own title, which is what makes one
/// row's box findable without a positional index into the strip.
Set<double> _rowTops(WidgetTester tester) => <double>{
  for (final FluentChartLegendRow row in _rows(tester))
    tester.getTopLeft(find.byKey(row.key!)).dy,
};
