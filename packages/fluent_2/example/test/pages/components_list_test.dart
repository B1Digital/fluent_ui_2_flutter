import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// List has no knobs at all — every one of its eleven sections is driven by the
/// rows themselves. So what these tests prove is the thing a mounting test
/// cannot: that a row's one gesture reaches the callback the section wired to
/// it, that a disabled row refuses that gesture, that the checkbox a row draws
/// tracks the selection rather than merely existing, and that the buttons and
/// menus sitting *inside* a row's tap target win the hit test instead of being
/// swallowed by it.
void main() {
  const String page = 'components-list';

  group('default', () {
    final DocsSection section = sectionOf('components-list--default');

    testWidgets('a list with no callback is inert, not disabled', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentListItem<String>), findsNWidgets(7));

      // `onSelectionChange` is null here, so every row is read-only. That is
      // not the same as `enabled: false`: the row must keep its own token ramp
      // and simply have nothing to invoke.
      final FluentInteractive surface = tester.widget<FluentInteractive>(
        find
            .descendant(
              of: _row('Asia'),
              matching: find.byType(FluentInteractive),
            )
            .first,
      );
      expect(surface.onPressed, isNull);

      final String before = textSnapshot(tester);
      await mouseClick(tester, find.text('Antarctica'));
      expect(
        textSnapshot(tester),
        before,
        reason: 'a read-only row must not select on click',
      );
    });
  });

  group('single action', () {
    final DocsSection section = sectionOf('components-list--single-action');

    testWidgets('a row runs the custom action under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Triggered custom action!'), findsNothing);

      await mouseClick(tester, find.text('Israel Rabin'));
      expect(
        find.text('Triggered custom action!'),
        findsOneWidget,
        reason: "the list's own gesture is this section's action hook",
      );
    });

    testWidgets('the action keeps nothing selected', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // `selection` is `none`, so no row may draw an affordance — the section
      // is about the action, not about picking anything.
      expect(find.byType(FluentCheckbox), findsNothing);

      await tapAndSettle(tester, find.text('Melda Bevel'), what: 'a row');
      await tapAndSettle(tester, find.text('Sonya Farner'), what: 'a row');
      expect(find.text('Triggered custom action!'), findsOneWidget);
    });
  });

  group('single action selection', () {
    final DocsSection section = sectionOf(
      'components-list--single-action-selection',
    );

    testWidgets('a row toggles its checkbox and toggles it back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(_checked(tester, 'Melda Bevel'), isFalse);
      expect(
        _checked(tester, 'Demetra Manwaring'),
        isTrue,
        reason: 'the section opens with two rows already selected',
      );

      await mouseClick(tester, find.text('Melda Bevel'));
      expect(_checked(tester, 'Melda Bevel'), isTrue);
      expect(
        _checked(tester, 'Demetra Manwaring'),
        isTrue,
        reason: 'checkbox selection is additive; it must not replace',
      );

      await tapAndSettle(tester, find.text('Melda Bevel'), what: 'the row');
      expect(_checked(tester, 'Melda Bevel'), isFalse);
    });

    testWidgets('the disabled rows refuse the gesture in both directions', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Rows 5 and 6 carry `enabled: false`, and one of them starts *selected*
      // — which is the case a list that only refused to add would get wrong.
      expect(_checked(tester, 'Bart Merrill'), isTrue);
      await tapAndSettle(
        tester,
        find.text('Bart Merrill'),
        what: 'a disabled selected row',
        warnIfMissed: false,
      );
      expect(
        _checked(tester, 'Bart Merrill'),
        isTrue,
        reason: 'a disabled row must not be deselectable either',
      );

      expect(_checked(tester, 'Sonya Farner'), isFalse);
      await tapAndSettle(
        tester,
        find.text('Sonya Farner'),
        what: 'a disabled row',
        warnIfMissed: false,
      );
      expect(_checked(tester, 'Sonya Farner'), isFalse);
    });
  });

  group('single action selection controlled', () {
    final DocsSection section = sectionOf(
      'components-list--single-action-selection-controlled',
    );

    testWidgets('Select all checks every row, and a row can still be undone', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_checked(tester, 'Melda Bevel'), isFalse);

      await mouseClick(tester, find.widgetWithText(FluentButton, 'Select all'));
      for (final String name in _people) {
        expect(
          _checked(tester, name),
          isTrue,
          reason: 'Select all must reach $name',
        );
      }

      await tapAndSettle(tester, find.text('Israel Rabin'), what: 'a row');
      expect(_checked(tester, 'Israel Rabin'), isFalse);
      expect(
        _checked(tester, 'Melda Bevel'),
        isTrue,
        reason: 'undoing one row must leave the rest of the set alone',
      );
    });
  });

  group('single action selection different primary', () {
    final DocsSection section = sectionOf(
      'components-list--single-action-selection-different-primary',
    );

    testWidgets('the custom action names the row it fired on', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.text('Melda Bevel'));
      expect(
        find.text('Triggered custom action on Melda Bevel'),
        findsOneWidget,
      );
      expect(_checked(tester, 'Melda Bevel'), isTrue);

      // Deselecting is the same gesture, and it is still an action: the message
      // must follow the row that changed, not the row that is now selected.
      await tapAndSettle(tester, find.text('Melda Bevel'), what: 'the row');
      expect(
        find.text('Triggered custom action on Melda Bevel'),
        findsOneWidget,
      );
      expect(_checked(tester, 'Melda Bevel'), isFalse);
    });

    testWidgets('the disabled row fires nothing at all', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(
        tester,
        find.text('Eusebia Stufflebeam'),
        what: 'the disabled row',
        warnIfMissed: false,
      );
      expect(
        find.textContaining('Triggered custom action'),
        findsNothing,
        reason: 'a disabled row must not reach the action either',
      );
    });
  });

  group('multiple actions with primary', () {
    final DocsSection section = sectionOf(
      'components-list--multiple-actions-with-primary',
    );

    testWidgets("the Install button wins the row's own tap target", (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Installing!'), findsNothing);

      // The button sits inside the row, so the row's gesture and the button's
      // are competing for the same press. Reporting the row's action here would
      // mean the button is decorative.
      await mouseClick(
        tester,
        find.widgetWithText(FluentButton, 'Install').first,
      );
      expect(find.text('Installing!'), findsOneWidget);
      expect(find.text('Triggered custom action!'), findsNothing);
    });

    testWidgets('the Install button announces its name once', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // FAILS — the node reads "Install\nInstall", so a screen reader says the
      // name twice and no tool can match the button by its declared label.
      // `button.dart:540` wraps the button in `Semantics(label: semanticLabel)`
      // and leaves the child's own text semantics in place, so the two
      // concatenate. `FluentButton.icon`, which requires the same parameter and
      // has no text child, comes out right — the two constructors disagree
      // about what `semanticLabel` means. This package already has the fix
      // written down: `breadcrumb.dart:865` wraps a crumb's label in
      // `ExcludeSemantics` exactly when a semanticLabel was supplied.
      expect(
        find.bySemanticsLabel('Install'),
        findsWidgets,
        reason: 'a declared semanticLabel must be the name, not a prefix',
      );
    });

    testWidgets('the overflow menu opens and its rows report', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Uninstall'), findsNothing);

      await tapAndSettle(
        tester,
        find.bySemanticsLabel('More actions').first,
        what: 'the overflow trigger',
      );
      expect(find.text('Uninstall'), findsOneWidget);

      // Under a real pointer, not a synthetic tap: a menu row can be
      // dismissible-but-not-selectable — the press lands on the dismiss layer,
      // the menu closes, and nothing was chosen. Asserting the *report* is what
      // separates the two.
      await mouseClick(tester, find.text('Uninstall'));
      expect(find.text('Clicked menu item'), findsOneWidget);
      expect(
        find.text('Uninstall'),
        findsNothing,
        reason: 'picking a menu row must close the menu',
      );
    });

    testWidgets("the card body still runs the list's own action", (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(
        tester,
        find.text('You created 53m ago').first,
        what: 'the card body',
      );
      expect(find.text('Triggered custom action!'), findsOneWidget);
      expect(find.text('Installing!'), findsNothing);
    });
  });

  group('multiple actions selection', () {
    final DocsSection section = sectionOf(
      'components-list--multiple-actions-selection',
    );

    testWidgets('a card toggles its own checkbox and no other', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder boxes = find.byType(FluentCheckbox);
      expect(boxes, findsNWidgets(9));
      expect(tester.widget<FluentCheckbox>(boxes.first).checked, isFalse);

      await mouseClick(tester, find.text('You created 53m ago').first);
      expect(tester.widget<FluentCheckbox>(boxes.first).checked, isTrue);
      expect(
        tester.widget<FluentCheckbox>(boxes.at(1)).checked,
        isFalse,
        reason: 'one card selecting must not take its neighbours with it',
      );

      await tapAndSettle(
        tester,
        find.text('You created 53m ago').first,
        what: 'the card',
      );
      expect(tester.widget<FluentCheckbox>(boxes.first).checked, isFalse);
    });

    testWidgets('the buttons inside a selectable card still fire', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentButton, 'Install').first,
        what: 'the Install button',
      );
      expect(find.text('Installing!'), findsOneWidget);
      expect(
        tester
            .widget<FluentCheckbox>(find.byType(FluentCheckbox).first)
            .checked,
        isFalse,
        reason: 'a press on the button must not also select the row',
      );
    });
  });

  group('multiple actions different primary', () {
    final DocsSection section = sectionOf(
      'components-list--multiple-actions-different-primary',
    );

    testWidgets('the card reports the value it changed', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.text('You created 53m ago').first);
      expect(find.text('Triggered custom action on card-1'), findsOneWidget);
      expect(
        tester
            .widget<FluentCheckbox>(find.byType(FluentCheckbox).first)
            .checked,
        isTrue,
        reason: 'this section runs the action alongside the selection',
      );
    });
  });

  group('virtualized list', () {
    final DocsSection section = sectionOf('components-list--virtualized-list');

    testWidgets('the whole country list is there and it scrolls', (
      WidgetTester tester,
    ) async {
      // Not wrapped in the harness's own scroller: the demo brings its own
      // 400-high viewport, and two nested scrollables would make "which one
      // moved?" unanswerable.
      await pumpSection(tester, section, scroll: false);

      expect(find.byType(FluentListItem<String>), findsNWidgets(196));
      final double top = tester.getTopLeft(find.text('Afghanistan')).dy;

      await tester.drag(find.text('Afghanistan'), const Offset(0, -300));
      await settle(tester);
      expect(
        tester.getTopLeft(find.text('Afghanistan')).dy,
        lessThan(top - 200),
        reason: 'the 400-high viewport is what stands in for virtualisation',
      );
    });

    testWidgets('its rows are read-only', (WidgetTester tester) async {
      await pumpSection(tester, section, scroll: false);
      final String before = textSnapshot(tester);
      await tapAndSettle(tester, find.text('Albania'), what: 'a country row');
      expect(textSnapshot(tester), before);
    });
  });

  group('virtualized list with actionable items', () {
    final DocsSection section = sectionOf(
      'components-list--virtualized-list-with-actionable-items',
    );

    testWidgets('a country row reports itself', (WidgetTester tester) async {
      await pumpSection(tester, section, scroll: false);
      expect(find.text('Albania'), findsOneWidget);

      await mouseClick(tester, find.text('Albania'));
      expect(
        find.text('Albania'),
        findsNWidgets(2),
        reason: 'the row and the line under the list must both read Albania',
      );

      await tapAndSettle(tester, find.text('Andorra'), what: 'another row');
      expect(find.text('Andorra'), findsNWidgets(2));
      expect(
        find.text('Albania'),
        findsOneWidget,
        reason: 'the report is the last row pressed, not a growing list',
      );
    });
  });

  group('list active element', () {
    final DocsSection section = sectionOf(
      'components-list--list-active-element',
    );

    testWidgets('the panel follows the active row', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        find.text('Melda Bevel'),
        findsNWidgets(2),
        reason: 'the row and the "Currently selected" line',
      );

      await mouseClick(tester, find.text('Israel Rabin'));
      expect(find.text('Israel Rabin'), findsNWidgets(2));
      expect(
        find.text('Melda Bevel'),
        findsOneWidget,
        reason: 'a `none` list selecting additively would keep both',
      );
    });

    testWidgets('pressing the active row again keeps it active', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The underlying toggle is additive, so re-pressing the selected row
      // hands back an empty set. The demo has to refuse it — an empty selection
      // would make `_selectedItems.first` throw on the very next build.
      await tapAndSettle(
        tester,
        find.text('Melda Bevel').first,
        what: 'the already-active row',
      );
      expect(find.text('Melda Bevel'), findsNWidgets(2));
    });

    testWidgets("the trailing mute button beats the row's own gesture", (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.bySemanticsLabel('Mute Sonya Farner'));
      expect(find.text('Muting Sonya Farner'), findsOneWidget);
      expect(
        find.text('Sonya Farner'),
        findsOneWidget,
        reason: 'a press on the mute button must not also activate the row',
      );
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

    testWidgets('an open row menu unmounts without throwing', (
      WidgetTester tester,
    ) async {
      // The menu is an overlay entry rooted outside the list; unmounting the
      // list while it is up is the order that can leave it behind.
      await pumpSection(
        tester,
        sectionOf('components-list--multiple-actions-with-primary'),
      );
      await tapAndSettle(
        tester,
        find.bySemanticsLabel('More actions').first,
        what: 'the overflow trigger',
      );
      expect(find.text('Uninstall'), findsOneWidget);
      await expectCleanTeardown(tester, 'the list with its menu open');
    });
  });
}

/// The six people every selection section on this page is built from.
const List<String> _people = <String>[
  'Melda Bevel',
  'Demetra Manwaring',
  'Eusebia Stufflebeam',
  'Israel Rabin',
  'Bart Merrill',
  'Sonya Farner',
];

/// The row whose persona reads [name].
Finder _row(String name) => find.ancestor(
  of: find.text(name),
  matching: find.byType(FluentListItem<String>),
);

/// Whether the checkbox the row for [name] draws is ticked.
///
/// The affordance, not the demo's own set: a row that kept its state and drew
/// the wrong box is exactly the failure a `selectedValues` assertion would miss.
bool? _checked(WidgetTester tester, String name) => tester
    .widget<FluentCheckbox>(
      find.descendant(of: _row(name), matching: find.byType(FluentCheckbox)),
    )
    .checked;
