import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// TabList's page is thirteen sections of a single widget: every demo is a
/// `FluentTabList` and the knob on all of them is the strip itself. So each
/// test drives a tab and then asserts what the *list* did — where the selection
/// bar was drawn, which panel is showing, how tall the row became, which tabs
/// the overflow menu handed back — rather than that a `selectedValue` field
/// moved. A list that flipped its state and painted the old selection is
/// exactly the failure these are shaped to catch.
void main() {
  const String page = 'components-tablist';

  group('default', () {
    final DocsSection section = sectionOf('components-tablist--default');

    testWidgets('a real mouse click moves the selection bar to the tab', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder list = find.byType(FluentTabList<String>);

      // The story opens with `selectedValue: null` — nothing chosen and no bar
      // anywhere. A list that quietly pre-selected its first tab fails here.
      expect(selectedOf(tester, list), isNull);
      expect(find.byType(Positioned), findsNothing);

      await mouseClick(tester, find.text('Third Tab'));
      // Past the 300ms indicator FLIP, so the bar is measured at rest rather
      // than mid-transform.
      await tester.pump(const Duration(milliseconds: 400));

      expect(selectedOf(tester, list), 'tab3');
      expect(
        indicatorIn(tabOf('Third Tab')),
        findsOneWidget,
        reason: 'the chosen tab must carry the selection bar',
      );
      expect(
        indicatorIn(tabOf('First Tab')),
        findsNothing,
        reason: 'an unselected transparent tab resolves no bar at rest',
      );
      expect(
        tester.getRect(indicatorIn(tabOf('Third Tab'))).center.dx,
        closeTo(tester.getRect(tabOf('Third Tab')).center.dx, 0.5),
        reason: 'the bar has to sit under the tab it belongs to',
      );
    });

    testWidgets('selection moves rather than accumulates', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder list = find.byType(FluentTabList<String>);

      await tapAndSettle(tester, find.text('Third Tab'));
      await tapAndSettle(tester, find.text('First Tab'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(selectedOf(tester, list), 'tab1');
      expect(
        find.byType(Positioned),
        findsOneWidget,
        reason: 'a single-select list must never leave two bars drawn',
      );
      expect(indicatorIn(tabOf('First Tab')), findsOneWidget);
    });
  });

  group('horizontal', () {
    final DocsSection section = sectionOf('components-tablist--horizontal');

    testWidgets('the tabs run in a row with the bar along the bottom edge', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Rect first = tester.getRect(tabOf('First Tab'));
      final Rect fourth = tester.getRect(tabOf('Fourth Tab'));
      expect(fourth.left, greaterThan(first.left));
      expect(fourth.top, closeTo(first.top, 0.5));

      // Horizontal is the orientation whose indicator runs along the bottom;
      // the vertical section asserts the leading-edge counterpart, and a list
      // that ignored `orientation` would draw the same bar in both.
      final Rect bar = tester.getRect(indicatorIn(tabOf('Second Tab')));
      final Rect tab = tester.getRect(tabOf('Second Tab'));
      expect(bar.bottom, closeTo(tab.bottom, 0.5));
      expect(bar.width, greaterThan(bar.height));
    });

    testWidgets('a click moves the bar sideways', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final double before = tester
          .getRect(indicatorIn(tabOf('Second Tab')))
          .left;

      await tapAndSettle(tester, find.text('Fourth Tab'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        tester.getRect(indicatorIn(tabOf('Fourth Tab'))).left,
        greaterThan(before),
      );
      expect(indicatorIn(tabOf('Second Tab')), findsNothing);
    });
  });

  group('vertical', () {
    final DocsSection section = sectionOf('components-tablist--vertical');

    testWidgets('the tabs stack with the bar along the leading edge', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Rect first = tester.getRect(tabOf('First Tab'));
      final Rect fourth = tester.getRect(tabOf('Fourth Tab'));
      expect(fourth.top, greaterThan(first.top));
      expect(fourth.left, closeTo(first.left, 0.5));
      // `IntrinsicWidth` + `stretch`: upstream measures all four tabs at one
      // common width however long their labels are.
      expect(fourth.width, closeTo(first.width, 0.5));

      final Rect bar = tester.getRect(indicatorIn(tabOf('Second Tab')));
      final Rect tab = tester.getRect(tabOf('Second Tab'));
      expect(bar.left, closeTo(tab.left, 0.5));
      expect(bar.height, greaterThan(bar.width));
    });

    testWidgets('a click moves the bar downwards', (WidgetTester tester) async {
      await pumpSection(tester, section);
      final double before = tester
          .getRect(indicatorIn(tabOf('Second Tab')))
          .top;

      await tapAndSettle(tester, find.text('Fourth Tab'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        tester.getRect(indicatorIn(tabOf('Fourth Tab'))).top,
        greaterThan(before),
      );
    });
  });

  group('appearance', () {
    final DocsSection section = sectionOf('components-tablist--appearance');

    testWidgets('the pill appearances fill instead of drawing a bar', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentTabList<String>), findsNWidgets(4));

      // transparent and subtle keep the rule under the strip...
      for (final int index in <int>[0, 1]) {
        expect(
          indicatorIn(tabOf('Third Tab', within: listAt(index))),
          findsOneWidget,
          reason: 'list $index is a flat appearance and must draw the bar',
        );
      }
      // ...while both circular ones pin the thickness to zero and paint the
      // selection as a pill instead.
      for (final int index in <int>[2, 3]) {
        expect(
          find.descendant(of: listAt(index), matching: find.byType(Positioned)),
          findsNothing,
          reason: 'list $index is a pill and must draw no bar at all',
        );
      }

      final Color? flat = decorationUnder(
        tester,
        tabOf('Third Tab', within: listAt(0)),
      ).color;
      final Color? filled = decorationUnder(
        tester,
        tabOf('Third Tab', within: listAt(3)),
      ).color;
      expect(
        filled,
        isNot(flat),
        reason:
            'filled-circular selects with a brand fill, transparent does '
            'not fill at all',
      );
      expect(
        decorationUnder(tester, tabOf('Fourth Tab', within: listAt(3))).color,
        isNot(filled),
        reason: 'the pill fill must belong to the selected tab, not the list',
      );
    });

    testWidgets('each list keeps its own selection', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(
        tester,
        find.descendant(of: listAt(3), matching: find.text('Fourth Tab')),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(selectedOf(tester, listAt(3)), 'tab4');
      for (final int index in <int>[0, 1, 2]) {
        expect(
          selectedOf(tester, listAt(index)),
          'tab3',
          reason: 'list $index shares no state with list 3',
        );
      }
    });

    testWidgets('the disabled tab refuses the click in every appearance', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      for (int index = 0; index < 4; index++) {
        await tapAndSettle(
          tester,
          find.descendant(of: listAt(index), matching: find.text('Second Tab')),
          what: 'the disabled tab of list $index',
          warnIfMissed: false,
        );
        expect(
          selectedOf(tester, listAt(index)),
          'tab3',
          reason: 'list $index selected a tab declared `enabled: false`',
        );
      }
    });
  });

  group('disabled', () {
    final DocsSection section = sectionOf('components-tablist--disabled');

    testWidgets('a list with no onSelect renders every tab disabled', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Upstream's list-wide `disabled` is our null `onSelect`, so the proof it
      // landed is the ramp the labels painted with — the demo has no state in
      // the first list to read instead.
      final Color? dead = textStyleOf(
        tester,
        find.descendant(of: listAt(0), matching: find.text('First Tab')),
      )?.color;
      final Color? live = textStyleOf(
        tester,
        find.descendant(of: listAt(1), matching: find.text('First Tab')),
      )?.color;
      expect(dead, isNotNull);
      expect(
        dead,
        isNot(live),
        reason: 'a list with no onSelect must paint the disabled ramp',
      );
      // Disabling the list must not hide which tab is chosen: Figma's disabled
      // selected variant keeps the rule and only drops it to the disabled ramp.
      expect(
        find.descendant(of: listAt(0), matching: find.byType(Positioned)),
        findsOneWidget,
      );
      expect(
        indicatorIn(tabOf('Second Tab', within: listAt(0))),
        findsOneWidget,
      );
    });

    testWidgets('per-tab enabled: false is honoured, its neighbours are not', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder live = listAt(1);

      for (final String label in <String>['Second Tab', 'Third Tab']) {
        await tapAndSettle(
          tester,
          find.descendant(of: live, matching: find.text(label)),
          what: 'the disabled $label',
          warnIfMissed: false,
        );
        expect(
          selectedOf(tester, live),
          'tab2',
          reason: '$label is declared `enabled: false`',
        );
      }

      await mouseClick(
        tester,
        find.descendant(of: live, matching: find.text('Fourth Tab')),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(selectedOf(tester, live), 'tab4');

      // The disabled ramp reaches the bar too, not only the label: the first
      // list's bar sits under a tab nothing can select, and must not read as
      // the same live brand rule as the tab that was just chosen.
      expect(
        decorationUnder(
          tester,
          indicatorIn(tabOf('Fourth Tab', within: live)),
        ).color,
        isNot(
          decorationUnder(
            tester,
            indicatorIn(tabOf('Second Tab', within: listAt(0))),
          ).color,
        ),
      );
    });
  });

  group('sizes', () {
    testWidgets('the size ramp changes how tall a tab is', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tablist--size-small'));
      final double smallHorizontal = tester
          .getRect(tabOf('First Tab', within: listAt(0)))
          .height;
      final double smallVertical = tester
          .getRect(tabOf('First Tab', within: listAt(1)))
          .height;

      await pumpSection(tester, sectionOf('components-tablist--size-medium'));
      final double mediumHorizontal = tester
          .getRect(tabOf('First Tab', within: listAt(0)))
          .height;
      final double mediumVertical = tester
          .getRect(tabOf('First Tab', within: listAt(1)))
          .height;

      expect(
        smallHorizontal,
        lessThan(mediumHorizontal),
        reason: 'the small horizontal ramp is 32 against medium\'s 44',
      );
      expect(
        smallVertical,
        lessThan(mediumVertical),
        reason: 'the small vertical ramp is 24 against medium\'s 32',
      );
      // Both orientations are on the same size axis, and Figma's vertical tab
      // is the shorter of the two at every step.
      expect(smallVertical, lessThan(smallHorizontal));
      expect(mediumVertical, lessThan(mediumHorizontal));

      // `FluentTabSize` ships medium and small only — Fluent 2 defines no large
      // tab — so this section renders medium on purpose, recorded upstream as
      // `reduced`. Asserting the equality keeps that deliberate and visible
      // rather than letting a future large ramp land here unnoticed.
      await pumpSection(tester, sectionOf('components-tablist--size-large'));
      expect(
        tester.getRect(tabOf('First Tab', within: listAt(0))).height,
        mediumHorizontal,
      );
    });

    testWidgets('every size section keeps its two lists independent', (
      WidgetTester tester,
    ) async {
      for (final String id in <String>[
        'components-tablist--size-small',
        'components-tablist--size-medium',
        'components-tablist--size-large',
      ]) {
        await pumpSection(tester, sectionOf(id));
        await tapAndSettle(
          tester,
          find.descendant(of: listAt(0), matching: find.text('Fourth Tab')),
          what: '$id horizontal Fourth Tab',
        );

        expect(selectedOf(tester, listAt(0)), 'tab4', reason: id);
        expect(
          selectedOf(tester, listAt(1)),
          'tab2',
          reason: '$id: the vertical list is keyed separately',
        );
        await expectCleanTeardown(tester, id);
      }
    });
  });

  group('with icon', () {
    final DocsSection section = sectionOf('components-tablist--with-icon');

    testWidgets('the icon leads the label and the lists stay independent', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(Icon), findsNWidgets(8));

      final Finder tab = tabOf('First Tab', within: listAt(0));
      expect(
        tester
            .getRect(find.descendant(of: tab, matching: find.byType(Icon)))
            .left,
        lessThan(
          tester
              .getRect(
                find.descendant(of: tab, matching: find.text('First Tab')),
              )
              .left,
        ),
        reason: 'the icon slot renders before the tab content',
      );

      await mouseClick(
        tester,
        find.descendant(of: listAt(1), matching: find.text('Fourth Tab')),
      );
      expect(selectedOf(tester, listAt(1)), 'tab4');
      expect(selectedOf(tester, listAt(0)), 'tab2');
    });
  });

  group('icon only', () {
    final DocsSection section = sectionOf('components-tablist--icon-only');

    testWidgets('the tabs carry an icon, no text, and still select', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // A tab with no `child` is an icon-only tab: the label upstream puts in
      // `aria-label` must not leak into the strip as visible text.
      expect(find.text('First Tab'), findsNothing);
      expect(find.byType(FluentTab<String>), findsNWidgets(8));
      expect(find.byType(Icon), findsNWidgets(8));

      final Finder third = find
          .descendant(of: listAt(0), matching: find.byType(FluentTab<String>))
          .at(2);
      await mouseClick(tester, third);
      await tester.pump(const Duration(milliseconds: 400));

      expect(selectedOf(tester, listAt(0)), 'tab3');
      expect(
        indicatorIn(third),
        findsOneWidget,
        reason: 'an icon-only tab still gets the selection bar',
      );
      expect(selectedOf(tester, listAt(1)), 'tab2');
    });
  });

  group('select tab on focus', () {
    final DocsSection section = sectionOf(
      'components-tablist--select-tab-on-focus',
    );

    testWidgets('the arrow keys move the selection, and Home and End jump', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder list = find.byType(FluentTabList<String>);

      // A pointer selection also focuses the tab — that is what makes the
      // keyboard reachable here without a synthetic focus request.
      await tapAndSettle(tester, find.text('First Tab'));
      expect(selectedOf(tester, list), 'tab1');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settle(tester);
      expect(
        selectedOf(tester, list),
        'tab2',
        reason: 'Fluent selects on arrow rather than only moving focus',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await settle(tester);
      expect(selectedOf(tester, list), 'tab1', reason: 'the round trip back');

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await settle(tester);
      expect(selectedOf(tester, list), 'tab4');

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await settle(tester);
      expect(selectedOf(tester, list), 'tab1');

      // The ends wrap: `useArrowNavigationGroup({ circular: true })`.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await settle(tester);
      expect(selectedOf(tester, list), 'tab4');
      await tester.pump(const Duration(milliseconds: 400));
      expect(indicatorIn(tabOf('Fourth Tab')), findsOneWidget);
    });
  });

  group('with overflow', () {
    final DocsSection section = sectionOf('components-tablist--with-overflow');

    testWidgets('the overflow menu hands a hidden tab back into the strip', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Five of the nine render, the other four live in the menu; the demo's
      // whole point is that picking one of the four swaps it into the strip.
      expect(visibleTabs(tester, listAt(0)), <String>[
        'today',
        'agenda',
        'day',
        'threeDay',
        'workWeek',
      ]);
      expect(find.text('Month'), findsNothing);

      await mouseClick(
        tester,
        find.byIcon(FluentIcons.more_horizontal_20_regular).first,
      );
      expect(
        find.text('Month'),
        findsOneWidget,
        reason: 'the overflow button must open the menu of hidden tabs',
      );

      // A real press on a menu row, not a synthetic tap: a popup that dismisses
      // under a mouse without committing is the exact bug this hunts.
      await mouseClick(tester, find.text('Month'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        selectedOf(tester, listAt(0)),
        'month',
        reason: 'a mouse press on a row must commit, not just dismiss',
      );
      expect(
        visibleTabs(tester, listAt(0)),
        contains('month'),
        reason: "upstream's `priority` pulls the selected tab back into view",
      );
      expect(
        visibleTabs(tester, listAt(0)),
        isNot(contains('workWeek')),
        reason: 'the strip is a fixed five wide, so one tab has to give way',
      );
      expect(
        find.text('Search'),
        findsNothing,
        reason: 'the menu must close once a row has committed',
      );
      expect(
        selectedOf(tester, listAt(1)),
        'today',
        reason: 'the vertical example keeps its own selection',
      );
    });

    testWidgets('the vertical example carries its own, longer strip', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(visibleTabs(tester, listAt(1)).length, 6);
      await tapAndSettle(
        tester,
        find.byIcon(FluentIcons.more_horizontal_20_regular).last,
        what: 'the vertical overflow button',
      );
      expect(find.text('Conversations'), findsOneWidget);

      await tapAndSettle(tester, find.text('Conversations'));
      expect(selectedOf(tester, listAt(1)), 'chat');
      expect(visibleTabs(tester, listAt(1)), contains('chat'));
      expect(selectedOf(tester, listAt(0)), 'today');
    });
  });

  group('with panels', () {
    final DocsSection section = sectionOf('components-tablist--with-panels');

    testWidgets('each tab swaps the panel under the strip', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The story opens on Conditions, whose panel is the label/value table.
      expect(find.text('Overcast'), findsOneWidget);
      expect(find.text('Origin'), findsNothing);

      await mouseClick(tester, find.text('Arrivals'));
      expect(find.text('Origin'), findsOneWidget);
      expect(find.text('DEN'), findsOneWidget);
      expect(
        find.text('Overcast'),
        findsNothing,
        reason: 'the outgoing panel has to be torn down, not stacked under',
      );

      await tapAndSettle(tester, find.text('Departures'));
      expect(find.text('Destination'), findsOneWidget);
      expect(find.text('MSP'), findsOneWidget);
      expect(find.text('DEN'), findsNothing);

      await tapAndSettle(tester, find.text('Conditions'));
      expect(find.text('Overcast'), findsOneWidget);
      expect(find.text('Destination'), findsNothing);
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

/// The [index]-th tab list in the demo, in tree order.
Finder listAt(int index) => find.byType(FluentTabList<String>).at(index);

/// The tab carrying [label], scoped to [within] where a section renders several
/// lists of identically labelled tabs.
Finder tabOf(String label, {Finder? within}) => find.ancestor(
  of: within == null
      ? find.text(label)
      : find.descendant(of: within, matching: find.text(label)),
  matching: find.byType(FluentTab<String>),
);

/// The selection bar drawn inside [tab], if the list drew one.
///
/// `buildFluentTab` only builds the Stack when the resolved indicator colour
/// and thickness are both live, so an unselected flat tab has no bar in the
/// tree at all and both pill appearances have none anywhere. Presence is
/// therefore the assertion; the colour is the library's own test's job.
Finder indicatorIn(Finder tab) =>
    find.descendant(of: tab, matching: find.byType(Positioned));

/// What [list] currently reports as its selected value.
String? selectedOf(WidgetTester tester, Finder list) =>
    tester.widget<FluentTabList<String>>(list).selectedValue;

/// The values of the tabs [list] is currently rendering, in order.
///
/// The overflow demo's whole behaviour is which tabs made it into the strip, so
/// the list has to be read as a list rather than by its selection.
List<String> visibleTabs(WidgetTester tester, Finder list) => tester
    .widget<FluentTabList<String>>(list)
    .tabs
    .map((FluentTab<String> tab) => tab.value)
    .toList();
