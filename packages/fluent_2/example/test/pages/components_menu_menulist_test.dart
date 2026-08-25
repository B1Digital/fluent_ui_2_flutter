import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// MenuList is a *permanent* surface: unlike Menu, every row is on screen from
/// the first frame, so `render_test.dart` already sees them. What it cannot see
/// is whether any of them still works — these demos rebuild Fluent's menu out of
/// the package's recomposition functions by hand, so a row is only a row if the
/// `FluentInteractive` wrapped around it is wired up, the leading slot swaps the
/// icon for the tick, and the surface stays put while it happens.
void main() {
  const String page = 'components-menu-menulist';

  group('default', () {
    final DocsSection section = sectionOf('components-menu-menulist--default');

    testWidgets('the rows stretch to one column across the surface', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);

      // `buildFluentMenu` puts an `IntrinsicWidth` around a stretched Column so
      // every row is as wide as the widest one — that is what makes a hover fill
      // span the surface instead of hugging its own label. Three rows of three
      // different widths would look right at rest and wrong under the pointer.
      final double width = tester.getSize(rowOf('Cut')).width;
      expect(tester.getSize(rowOf('Paste')).width, width);
      expect(tester.getSize(rowOf('Edit')).width, width);
      expect(
        width,
        greaterThan(tester.getSize(find.text('Paste')).width),
        reason:
            'a row that only spans its label cannot paint a full-width fill',
      );
    });

    testWidgets('a row lights up under a real pointer', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder row = rowOf('Cut');
      final Color? rest = decorationUnder(tester, row).color;

      // The whole hover ramp is unreachable through `tester.tap`. These rows are
      // hand-composed rather than built by `FluentMenu`, so nothing but a real
      // pointer proves the `FluentInteractive` around each one is actually
      // reporting state into `buildFluentMenuItem`.
      final Color? hovered = await whileHovering(
        tester,
        row,
        () => decorationUnder(tester, row).color,
      );
      expect(
        hovered,
        isNot(rest),
        reason: 'the row painted its resting fill while hovered',
      );
      expect(
        decorationUnder(tester, rowOf('Paste')).color,
        rest,
        reason: 'only the row under the pointer may change',
      );
      expect(decorationUnder(tester, row).color, rest);
    });

    testWidgets('pressing a row leaves the permanent surface standing', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Rect before = tester.getRect(rowOf('Cut'));

      // The section exists because `FluentMenu` only ever renders into an
      // overlay. A list that dismissed itself on a press would be the Menu
      // component again, which is the one thing this page is not.
      await mouseClick(tester, find.text('Cut'));
      expect(find.text('Cut'), findsOneWidget);
      expect(tester.getRect(rowOf('Cut')), before);
    });
  });

  group('menu list with nested submenus', () {
    final DocsSection section = sectionOf(
      'components-menu-menulist--menu-list-with-nested-submenus',
    );

    testWidgets('only the Preferences row advertises a submenu', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder chevron = find.byIcon(fluentMenuSubmenuChevron);
      expect(chevron, findsOneWidget);
      expect(
        tester.getRect(chevron).center.dy,
        inInclusiveRange(
          tester.getRect(rowOf('Preferences')).top,
          tester.getRect(rowOf('Preferences')).bottom,
        ),
      );
    });

    testWidgets('the Preferences row opens a real menu under itself', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(CompositedTransformFollower), findsNothing);
      final Rect anchor = tester.getRect(rowOf('Preferences'));

      await tapAndSettle(tester, find.text('Preferences'), what: 'Preferences');
      await tester.pump(const Duration(milliseconds: 450));
      await settle(tester);
      expect(find.byType(CompositedTransformFollower), findsOneWidget);
      for (final String label in <String>['Cut', 'Paste', 'Edit']) {
        expect(
          find.text(label),
          findsNWidgets(2),
          reason: 'the submenu repeats the three commands',
        );
      }
      // `FluentMenu` anchors a root level under its trigger, and the trigger
      // here is the row — so the surface drops below Preferences rather than
      // beside it. The page says so; only geometry can check it.
      expect(
        tester.getRect(submenuSurface).top,
        greaterThanOrEqualTo(anchor.bottom - 1),
      );

      await tapAndSettle(
        tester,
        find.text('Preferences'),
        what: 'Preferences again',
        warnIfMissed: false,
      );
      expect(
        find.byType(CompositedTransformFollower),
        findsNothing,
        reason: 'the row is a toggle, and the barrier dismisses it either way',
      );
    });

    testWidgets('the Preferences row opens under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await mouseClick(tester, find.text('Preferences'));
      await settle(tester, frames: 10);
      expect(find.text('Cut'), findsNWidgets(2));
    });
  });

  group('checkbox items', () {
    final DocsSection section = sectionOf(
      'components-menu-menulist--checkbox-items',
    );

    testWidgets('a press ticks the row in place and accumulates', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byIcon(fluentMenuCheckmark), findsNothing);
      final Rect before = tester.getRect(rowOf('Cut'));

      await tapAndSettle(tester, find.text('Cut'), what: 'Cut');
      expectTicked(tester, ticked: <String>{'Cut'});
      expect(
        tester.getRect(rowOf('Cut')),
        before,
        reason: 'swapping the glyph must not relayout the row',
      );

      await tapAndSettle(tester, find.text('Edit'), what: 'Edit');
      expectTicked(tester, ticked: <String>{'Cut', 'Edit'});

      await tapAndSettle(tester, find.text('Cut'), what: 'Cut');
      expectTicked(tester, ticked: <String>{'Edit'});
    });

    testWidgets('a press ticks the row under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await mouseClick(tester, find.text('Paste'));
      expectTicked(tester, ticked: <String>{'Paste'});
    });
  });

  group('radio items', () {
    testWidgets('the tick moves rather than accumulating', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-menu-menulist--radio-items'),
      );
      expect(find.byIcon(fluentMenuCheckmark), findsNothing);

      await tapAndSettle(tester, find.text('Segoe'), what: 'Segoe');
      expectTicked(tester, ticked: <String>{'Segoe'}, labels: _fonts);

      await tapAndSettle(tester, find.text('Arial'), what: 'Arial');
      expectTicked(tester, ticked: <String>{'Arial'}, labels: _fonts);

      await tapAndSettle(tester, find.text('Arial'), what: 'Arial again');
      expect(
        find.byIcon(fluentMenuCheckmark),
        findsOneWidget,
        reason: 'a radio row cannot be pressed off, only replaced',
      );
    });
  });

  group('controlled checkbox items', () {
    testWidgets('the demo starts with Cut and Paste in the group', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-menu-menulist--controlled-checkbox-items'),
      );
      expectTicked(tester, ticked: <String>{'Cut', 'Paste'});

      await tapAndSettle(tester, find.text('Paste'), what: 'Paste');
      expectTicked(tester, ticked: <String>{'Cut'});

      await tapAndSettle(tester, find.text('Paste'), what: 'Paste');
      expectTicked(tester, ticked: <String>{'Cut', 'Paste'});
    });
  });

  group('controlled radio items', () {
    testWidgets('the demo starts on Calibri and moves off it', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-menu-menulist--controlled-radio-items'),
      );
      expectTicked(tester, ticked: <String>{'Calibri'}, labels: _fonts);

      await tapAndSettle(tester, find.text('Segoe'), what: 'Segoe');
      expectTicked(tester, ticked: <String>{'Segoe'}, labels: _fonts);
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// The rows of the checkbox lists, and the icon each one shows while unticked.
const Map<String, IconData> _edit = <String, IconData>{
  'Cut': FluentIcons.cut_20_regular,
  'Paste': FluentIcons.clipboard_paste_20_regular,
  'Edit': FluentIcons.edit_20_regular,
};

/// The same, for the radio lists.
const Map<String, IconData> _fonts = <String, IconData>{
  'Segoe': FluentIcons.cut_20_regular,
  'Calibri': FluentIcons.clipboard_paste_20_regular,
  'Arial': FluentIcons.edit_20_regular,
};

/// The interaction surface wrapping the row labelled [label].
Finder rowOf(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(FluentInteractive))
    .first;

/// The card the open submenu draws its rows on.
final Finder submenuSurface = find
    .descendant(
      of: find.byType(CompositedTransformFollower),
      matching: find.byType(DecoratedBox),
    )
    .first;

/// Asserts exactly the rows in [ticked] show the checkmark.
///
/// Read through the leading slot rather than by counting ticks: the slot holds
/// the icon **or** the checkmark and never both, so a row's own glyph vanishing
/// is what says which row was ticked. Counting alone would pass a list that
/// ticked the wrong row, and that is the failure a user actually sees.
void expectTicked(
  WidgetTester tester, {
  required Set<String> ticked,
  Map<String, IconData> labels = _edit,
}) {
  expect(find.byIcon(fluentMenuCheckmark), findsNWidgets(ticked.length));
  labels.forEach((String label, IconData icon) {
    expect(
      find.byIcon(icon),
      ticked.contains(label) ? findsNothing : findsOneWidget,
      reason: ticked.contains(label)
          ? '"$label" is ticked, so its glyph must be gone'
          : '"$label" is not ticked, so its glyph must be back',
    );
  });
}
