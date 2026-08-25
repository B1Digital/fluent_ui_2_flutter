import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Nav's five sections carry eleven knobs between them — two drawer-type radio
/// groups, two density radio groups, six switches and a Navigate button — plus
/// the affordances the nav itself owns: category headers that expand, pins that
/// toggle, and per-row overflow menus. Each test below drives one of them and
/// asserts the *drawer* moved, not just the control.
///
/// Two of those knobs are documented as deliberately partial ports, and the
/// tests say so where they land: `Links` drives `onPressed`, which on a
/// `FluentNavItem` is called *in addition to* selecting, so the only row it can
/// change is the app item — the one row that is a plain label when it has
/// nothing to invoke.
void main() {
  const String page = 'components-nav';

  group('basic', () {
    final DocsSection section = sectionOf('components-nav--basic');

    testWidgets('the type radio lifts the drawer out of the layout', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // An inline drawer takes 260 of the row's width from its sibling; an
      // overlay drawer paints nothing where it is written and floats the same
      // panel over the page. So the content pane's own left edge is what tells
      // the two apart — the panel is present either way.
      final double inline = tester.getTopLeft(find.text('Type')).dx;
      expect(find.text('Dashboard'), findsOneWidget);

      await mouseClick(
        tester,
        find.widgetWithText(FluentRadio<FluentDrawerType>, 'Overlay (Default)'),
      );
      expect(
        tester.getTopLeft(find.text('Type')).dx,
        lessThan(inline - 200),
        reason: 'an overlay drawer must stop reserving width in the row',
      );
      expect(
        find.text('Dashboard'),
        findsOneWidget,
        reason: 'the panel moved to the overlay; it did not disappear',
      );
    });

    testWidgets('the hamburger closes the pane and opens it again', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Dashboard'), findsOneWidget);

      await tapAndSettle(
        tester,
        find.bySemanticsLabel('Toggle navigation pane'),
        what: 'the hamburger',
      );
      // The close runs for 250ms and the panel is only unbuilt once it lands,
      // so four frames of the default settle would read it mid-flight.
      await settle(tester, frames: 8);
      expect(
        find.text('Dashboard'),
        findsNothing,
        reason: 'a closed inline drawer is unbuilt, not merely hidden',
      );

      await tapAndSettle(
        tester,
        find.bySemanticsLabel('Toggle navigation pane'),
        what: 'the hamburger',
      );
      await settle(tester, frames: 8);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('the header hamburger closes the pane from inside it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The drawer's own header slot: pressing it takes the panel — and
      // therefore the button itself — off screen, so it is the one control here
      // that has to survive being unmounted by its own callback. Found
      // structurally rather than by its label, because the label is not
      // reachable on an inline drawer — see the test below.
      final Finder headerHamburger = find.descendant(
        of: find.byType(FluentNavDrawer),
        matching: find.byType(FluentHamburger),
      );
      expect(headerHamburger, findsOneWidget);
      await tapAndSettle(tester, headerHamburger, what: 'the header hamburger');
      await settle(tester, frames: 8);
      expect(find.text('Dashboard'), findsNothing);
      expect(headerHamburger, findsNothing);

      // And the pane's own hamburger is what brings it back.
      await tapAndSettle(
        tester,
        find.bySemanticsLabel('Toggle navigation pane'),
        what: 'the hamburger',
      );
      await settle(tester, frames: 8);
      expect(headerHamburger, findsOneWidget);
    });

    testWidgets('the header hamburger keeps its own accessible name', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // FAILS — `drawer.dart:862` wraps the inline panel in
      // `Semantics(container: true, label: semanticLabel)` and, unlike the
      // overlay branch at :784, does not pass `explicitChildNodes: true`. A
      // `Semantics` annotation that is not a boundary merges upward, so every
      // control in the header and footer slots loses its own node: the panel is
      // announced as "Contoso HR\nClose Navigation" and the button that carries
      // the name has none. Switching this very demo to Overlay restores it,
      // which is what makes it a defect rather than a design decision.
      expect(
        find.bySemanticsLabel('Close Navigation'),
        findsOneWidget,
        reason:
            'a header button given a semanticLabel must keep it; the inline '
            'drawer swallows it into the panel node',
      );
    });

    testWidgets('the links switch makes the app item a plain label', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The one row this knob can move. Every `FluentNavItem` keeps its own
      // press — selecting the row is not the caller's callback — so a nav whose
      // links are off still navigates within itself. The app item has nothing
      // else to do, so losing the callback is what turns it into upstream's
      // `AppItemStatic`.
      expect(_rowSurface('Contoso HR'), findsOneWidget);

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentSwitch, 'Enabled'),
        what: 'the links switch',
      );
      expect(find.text('Disabled'), findsOneWidget);
      expect(
        _rowSurface('Contoso HR'),
        findsNothing,
        reason: 'a static app item takes no hover, no press and no focus',
      );

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentSwitch, 'Disabled'),
        what: 'the links switch',
      );
      expect(_rowSurface('Contoso HR'), findsOneWidget);
    });

    testWidgets('the categories switch collapses the one that was open', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await _toggleCategory(tester, 'Job Postings');
      expect(
        find.text('Lorem ipsum dolor sit amet, consectetuer adipiscing elit'),
        findsNWidgets(2),
        reason: 'a category header must reveal its sub-items',
      );

      await _toggleCategory(tester, 'Retirement');
      expect(
        find.text('Plan Information'),
        findsOneWidget,
        reason: 'Multiple must leave the first category open',
      );
      expect(
        find.text('Lorem ipsum dolor sit amet, consectetuer adipiscing elit'),
        findsNWidgets(2),
      );

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentSwitch, 'Multiple'),
        what: 'the categories switch',
      );
      await _toggleCategory(tester, 'Career Development');
      expect(find.text('Career Paths'), findsOneWidget);
      expect(
        find.text('Plan Information'),
        findsNothing,
        reason: 'Single must close every other category as one opens',
      );
      expect(
        find.text('Lorem ipsum dolor sit amet, consectetuer adipiscing elit'),
        findsNothing,
      );
    });
  });

  group('variable density items', () {
    final DocsSection section = sectionOf(
      'components-nav--variable-density-items',
    );

    testWidgets('the density radio changes the row height and the logo', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Small is the section's starting density, so the 24 logo is the one on
      // screen and the rows are on the 32 ramp.
      final double small = tester
          .getSize(_rowSurface('Dashboard').first)
          .height;
      expect(find.byIcon(FluentIcons.person_circle_24_regular), findsOneWidget);

      await mouseClick(
        tester,
        find.widgetWithText(FluentRadio<FluentNavSize>, 'Medium'),
      );
      final double medium = tester
          .getSize(_rowSurface('Dashboard').first)
          .height;
      expect(
        medium,
        greaterThan(small),
        reason: 'Medium must give every row more height than Small',
      );
      expect(
        find.byIcon(FluentIcons.person_circle_32_regular),
        findsOneWidget,
        reason: 'the app item swaps to the 32 logo at Medium',
      );
      expect(find.byIcon(FluentIcons.person_circle_24_regular), findsNothing);

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentRadio<FluentNavSize>, 'Small'),
        what: 'the density radio',
      );
      expect(tester.getSize(_rowSurface('Dashboard').first).height, small);
      expect(find.byIcon(FluentIcons.person_circle_24_regular), findsOneWidget);
    });

    testWidgets('the app item switch turns the header into a button', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        _rowSurface('Contoso HR'),
        findsNothing,
        reason: 'the section opens on Static, which is a label and no more',
      );

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentSwitch, 'Static'),
        what: 'the app item switch',
      );
      expect(find.text('Href'), findsOneWidget);
      expect(_rowSurface('Contoso HR'), findsOneWidget);

      // And with the app item on Href, Links is the knob that owns it: the two
      // together are the only path to a live app item.
      await tapAndSettle(
        tester,
        find.widgetWithText(FluentSwitch, 'Enabled'),
        what: 'the links switch',
      );
      expect(
        _rowSurface('Contoso HR'),
        findsNothing,
        reason: 'Links off leaves an Href app item with nothing to invoke',
      );
    });

    testWidgets('the app item icon switch removes the logo', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byIcon(FluentIcons.person_circle_24_regular), findsOneWidget);

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentSwitch, 'Present'),
        what: 'the app item icon switch',
      );
      expect(find.text('Absent'), findsOneWidget);
      expect(
        find.byIcon(FluentIcons.person_circle_24_regular),
        findsNothing,
        reason: 'Absent must take the glyph out, not merely blank it',
      );
      expect(find.byIcon(FluentIcons.person_circle_32_regular), findsNothing);

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentSwitch, 'Absent'),
        what: 'the app item icon switch',
      );
      expect(find.byIcon(FluentIcons.person_circle_24_regular), findsOneWidget);
    });

    testWidgets('the category that starts open is the one that starts open', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // `defaultOpenCategories: {'6'}` with `defaultSelectedValue: '7'` — the
      // selected row is inside the open category, so a nav that ignored the
      // default open set would open on a selection nobody can see.
      expect(find.text('Openings'), findsOneWidget);
      expect(
        find.text('Plan Information'),
        findsNothing,
        reason: 'Retirement is not in the default open set',
      );
      expect(
        textStyleOf(tester, find.text('Openings'))?.fontWeight,
        isNot(textStyleOf(tester, find.text('Submissions'))?.fontWeight),
        reason: 'the selected sub-item takes the strong ramp',
      );
    });
  });

  group('controlled', () {
    final DocsSection section = sectionOf('components-nav--controlled');

    testWidgets('Navigate moves the selection off the row that had it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final FontWeight? selected = textStyleOf(
        tester,
        find.text('Openings'),
      )?.fontWeight;
      final FontWeight? plain = textStyleOf(
        tester,
        find.text('Announcements'),
      )?.fontWeight;
      expect(selected, isNot(plain));

      await mouseClick(tester, find.widgetWithText(FluentButton, 'Navigate'));
      expect(
        textStyleOf(tester, find.text('Announcements'))?.fontWeight,
        selected,
        reason: 'the first Navigate lands on the second nav value',
      );
      expect(
        textStyleOf(tester, find.text('Openings'))?.fontWeight,
        plain,
        reason: 'and must take the selection away from the row that had it',
      );
    });

    testWidgets('Navigate opens the category the destination lives in', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        find.text('Career Paths'),
        findsNothing,
        reason: 'Career Development starts closed',
      );

      // The eleventh destination is a sub-item of a closed category. Selecting
      // it without opening its parent would leave the selection somewhere the
      // user cannot see — which is the whole reason this demo tracks the open
      // set alongside the value.
      final Finder navigate = find.widgetWithText(FluentButton, 'Navigate');
      for (int i = 0; i < 11; i++) {
        await tapAndSettle(tester, navigate, what: 'Navigate');
      }
      await settle(tester, frames: 8);
      expect(find.text('Career Paths'), findsOneWidget);
      expect(
        textStyleOf(tester, find.text('Planning'))?.fontWeight,
        isNot(textStyleOf(tester, find.text('Career Paths'))?.fontWeight),
        reason: 'the eleventh destination is Planning, and it must be selected',
      );
    });

    testWidgets('the categories switch drops back to a single open group', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Openings'), findsOneWidget);
      expect(find.text('Plan Information'), findsOneWidget);

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentSwitch, 'Multiple'),
        what: 'the categories switch',
      );
      await settle(tester, frames: 8);
      expect(
        find.text('Openings'),
        findsOneWidget,
        reason: 'Single keeps the first category',
      );
      expect(
        find.text('Plan Information'),
        findsNothing,
        reason: 'Single must close the second one',
      );

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentSwitch, 'Single'),
        what: 'the categories switch',
      );
      await settle(tester, frames: 8);
      expect(find.text('Plan Information'), findsOneWidget);
    });
  });

  group('split nav items', () {
    final DocsSection section = sectionOf('components-nav--split-nav-items');

    testWidgets('the pin toggles its own glyph and nothing else', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        find.byIcon(FluentIcons.pin_20_filled),
        findsNothing,
        reason: 'nothing is pinned to start with',
      );

      final Finder pin = find.descendant(
        of: _rowSurface('Performance Reviews').first,
        matching: find.byIcon(FluentIcons.pin_20_regular),
      );
      expect(pin, findsOneWidget);
      await mouseClick(tester, pin);

      expect(
        find.byIcon(FluentIcons.pin_20_filled),
        findsOneWidget,
        reason: 'the pressed pin must fill, and only that one',
      );
      expect(
        find.descendant(
          of: _rowSurface('Interviews').first,
          matching: find.byIcon(FluentIcons.pin_20_regular),
        ),
        findsOneWidget,
        reason: 'a pin on one row must not move its neighbours',
      );

      await tapAndSettle(
        tester,
        find.descendant(
          of: _rowSurface('Performance Reviews').first,
          matching: find.byIcon(FluentIcons.pin_20_filled),
        ),
        what: 'the pin',
      );
      expect(find.byIcon(FluentIcons.pin_20_filled), findsNothing);
    });

    testWidgets("a sub-item's overflow menu opens", (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The menus hang off sub-items, so the category has to be opened before
      // there is one to press — which is also the honest order for a user.
      await _toggleCategory(tester, 'Job Postings');
      expect(find.text('Openings'), findsOneWidget);
      expect(find.text('New Window'), findsNothing);

      await mouseClick(
        tester,
        find.descendant(
          of: _rowSurface('Openings').first,
          matching: find.bySemanticsLabel('More options'),
        ),
      );
      expect(
        find.text('New Window'),
        findsOneWidget,
        reason: 'the trigger must open the menu it was built with',
      );

      // Both rows are captions rather than commands — upstream's story gives
      // them no handler either — so pressing one is correctly inert and leaves
      // the menu up. What has to work is the way out: a press on the nav behind
      // the menu reaches the dismiss layer.
      await mouseClick(tester, find.text('Dashboard'));
      expect(
        find.text('New Window'),
        findsNothing,
        reason: 'a press outside the menu must close it',
      );
    });

    testWidgets('the app item, icon and links switches drive the header', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_rowSurface('Contoso HR'), findsNothing);
      expect(find.byIcon(FluentIcons.person_circle_24_regular), findsOneWidget);

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentSwitch, 'Static'),
        what: 'the app item switch',
      );
      expect(_rowSurface('Contoso HR'), findsOneWidget);

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentSwitch, 'Enabled'),
        what: 'the links switch',
      );
      expect(
        _rowSurface('Contoso HR'),
        findsNothing,
        reason: 'Links off leaves an Href app item with nothing to invoke',
      );

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentSwitch, 'Present'),
        what: 'the app item icon switch',
      );
      expect(find.byIcon(FluentIcons.person_circle_24_regular), findsNothing);
    });

    testWidgets('the density radio changes the row height', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final double small = tester
          .getSize(_rowSurface('Dashboard').first)
          .height;

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentRadio<FluentNavSize>, 'Medium'),
        what: 'the density radio',
      );
      expect(
        tester.getSize(_rowSurface('Dashboard').first).height,
        greaterThan(small),
      );

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentRadio<FluentNavSize>, 'Small'),
        what: 'the density radio',
      );
      expect(tester.getSize(_rowSurface('Dashboard').first).height, small);
    });
  });

  group('custom motion', () {
    final DocsSection section = sectionOf('components-nav--custom-motion');

    testWidgets('the type radio lifts the drawer out of the layout', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final double inline = tester.getTopLeft(find.text('Type')).dx;

      await mouseClick(
        tester,
        find.widgetWithText(FluentRadio<FluentDrawerType>, 'Overlay (Default)'),
      );
      expect(
        tester.getTopLeft(find.text('Type')).dx,
        lessThan(inline - 200),
        reason: 'the section without a header still has to move its drawer',
      );
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('the links and categories switches drive the same pane', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_rowSurface('Contoso HR'), findsOneWidget);

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentSwitch, 'Enabled'),
        what: 'the links switch',
      );
      expect(_rowSurface('Contoso HR'), findsNothing);

      await _toggleCategory(tester, 'Job Postings');
      expect(find.text('Openings'), findsOneWidget);

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentSwitch, 'Multiple'),
        what: 'the categories switch',
      );
      await _toggleCategory(tester, 'Retirement');
      expect(find.text('Plan Information'), findsOneWidget);
      expect(
        find.text('Openings'),
        findsNothing,
        reason: 'Single must close Job Postings as Retirement opens',
      );
    });

    testWidgets('the hamburger runs the drawer transition both ways', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(
        tester,
        find.bySemanticsLabel('Toggle navigation pane'),
        what: 'the hamburger',
      );
      // Mid-transition: the panel is still built but narrower than it was, so
      // this frame proves the close is animated rather than a swap.
      await tester.pump(const Duration(milliseconds: 80));
      final double? midway = rectOrNull(
        tester,
        find.byType(FluentNavDrawer),
      )?.width;
      expect(midway, isNotNull);
      expect(midway, lessThan(fluentNavDrawerWidth));

      await settle(tester, frames: 8);
      expect(find.text('Dashboard'), findsNothing);

      await tapAndSettle(
        tester,
        find.bySemanticsLabel('Toggle navigation pane'),
        what: 'the hamburger',
      );
      await settle(tester, frames: 8);
      expect(find.text('Dashboard'), findsOneWidget);
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

    testWidgets('a drawer in the overlay unmounts without throwing', (
      WidgetTester tester,
    ) async {
      // The panel lives in an OverlayEntry in another branch of the tree, and a
      // focus scope inside it holds the primary focus. Unmounting with it open
      // is the order that leaves an entry behind or restores focus to a dead
      // node.
      await pumpSection(tester, sectionOf('components-nav--basic'));
      await tapAndSettle(
        tester,
        find.widgetWithText(FluentRadio<FluentDrawerType>, 'Overlay (Default)'),
        what: 'the type radio',
      );
      expect(find.text('Dashboard'), findsOneWidget);
      await expectCleanTeardown(tester, 'the overlay drawer');
    });
  });
}

/// The interaction surface of the nav row labelled [label].
///
/// Empty when the row has nothing to invoke: a static app item builds no
/// interaction surface at all, which is exactly what the Links and App Item
/// switches are asserted on.
Finder _rowSurface(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(FluentInteractive),
);

/// Presses the category header labelled [label] and waits out the collapse.
///
/// The group animates over `durationNormal` and is not built at all once it
/// lands, so a shorter wait would read a half-open group and call it open.
Future<void> _toggleCategory(WidgetTester tester, String label) async {
  await tapAndSettle(tester, find.text(label), what: 'the $label category');
  await settle(tester, frames: 8);
}
