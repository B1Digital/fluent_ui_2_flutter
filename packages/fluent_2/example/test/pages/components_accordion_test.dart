import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Accordion's page is thirteen sections of one widget, and almost every one of
/// them is a claim about the *open set*: how many panels may be open, whether
/// the last one can be closed, which one starts open. So the assertions below
/// are about which panel content is in the tree — a collapsed
/// `_FluentAccordionPanel` builds nothing at all, so presence is an honest
/// reading of what a reader can see — plus the three sections that are claims
/// about geometry instead, and the two live-but-dead motion knobs.
void main() {
  const String page = 'components-accordion';

  group('default', () {
    final DocsSection section = sectionOf('components-accordion--default');

    testWidgets('a mouse click opens one panel and closes the last', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Single expansion, nothing open: the story is the plainest accordion
      // there is, and a demo that pre-opened a panel would fail here.
      expect(find.text('Accordion Panel 1'), findsNothing);

      await mouseClick(tester, find.text('Accordion Header 1'));
      expect(find.text('Accordion Panel 1'), findsOneWidget);

      await tapAndSettle(tester, find.text('Accordion Header 2'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Accordion Panel 2'), findsOneWidget);
      expect(
        find.text('Accordion Panel 1'),
        findsNothing,
        reason: 'without `multiple`, opening one panel has to close the other',
      );
    });

    testWidgets('the last open panel cannot be closed', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(tester, find.text('Accordion Header 2'));
      expect(find.text('Accordion Panel 2'), findsOneWidget);

      // `collapsible` is false here, so upstream's `updateOpenItems` returns
      // the set unchanged rather than emptying it.
      await tapAndSettle(tester, find.text('Accordion Header 2'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Accordion Panel 2'), findsOneWidget);
    });
  });

  group('collapsible', () {
    final DocsSection section = sectionOf('components-accordion--collapsible');

    testWidgets('the open panel closes on a second click and comes back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.text('Accordion Header 1'));
      expect(find.text('Accordion Panel 1'), findsOneWidget);

      await tapAndSettle(tester, find.text('Accordion Header 1'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Accordion Panel 1'),
        findsNothing,
        reason: 'collapsible is the whole difference from the default story',
      );

      await tapAndSettle(tester, find.text('Accordion Header 1'));
      expect(find.text('Accordion Panel 1'), findsOneWidget);
    });
  });

  group('controlled', () {
    final DocsSection section = sectionOf('components-accordion--controlled');

    testWidgets('openItems drives the panels and onToggle feeds it back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The demo owns the set and seeds it with '1'.
      expect(find.text('Accordion Panel 1'), findsOneWidget);
      expect(find.text('Accordion Panel 2'), findsNothing);

      await mouseClick(tester, find.text('Accordion Header 2'));
      expect(
        find.text('Accordion Panel 1'),
        findsOneWidget,
        reason: 'multiple: two panels stay open at once',
      );
      expect(find.text('Accordion Panel 2'), findsOneWidget);

      await tapAndSettle(tester, find.text('Accordion Header 1'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Accordion Panel 1'), findsNothing);
      expect(find.text('Accordion Panel 2'), findsOneWidget);

      // collapsible as well as multiple, so the set can empty completely.
      await tapAndSettle(tester, find.text('Accordion Header 2'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Accordion Panel 2'), findsNothing);
    });
  });

  group('multiple', () {
    final DocsSection section = sectionOf('components-accordion--multiple');

    testWidgets('panels accumulate, and the last one refuses to close', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Accordion Panel 1'), findsNothing);

      await mouseClick(tester, find.text('Accordion Header 1'));
      await tapAndSettle(tester, find.text('Accordion Header 3'));
      expect(find.text('Accordion Panel 1'), findsOneWidget);
      expect(find.text('Accordion Panel 3'), findsOneWidget);
      expect(find.text('Accordion Panel 2'), findsNothing);

      await tapAndSettle(tester, find.text('Accordion Header 1'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Accordion Panel 1'), findsNothing);

      // Down to one open panel and `collapsible` is false, so this click is a
      // no-op — the story is multiple, not multiple-and-collapsible.
      await tapAndSettle(tester, find.text('Accordion Header 3'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Accordion Panel 3'), findsOneWidget);
    });
  });

  group('open items', () {
    final DocsSection section = sectionOf('components-accordion--open-items');

    testWidgets('defaultOpenItems opens exactly the panel it names', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(find.text('Accordion Panel 2'), findsOneWidget);
      expect(find.text('Accordion Panel 1'), findsNothing);
      expect(find.text('Accordion Panel 3'), findsNothing);

      // The default is a seed, not a pin: single expansion still moves off it.
      await mouseClick(tester, find.text('Accordion Header 3'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Accordion Panel 3'), findsOneWidget);
      expect(find.text('Accordion Panel 2'), findsNothing);
    });
  });

  group('sizes', () {
    final DocsSection section = sectionOf('components-accordion--sizes');

    testWidgets('the four size headers step up the type ramp', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentAccordionItem), findsNWidgets(4));

      final List<double?> ramp = <double?>[
        for (final String label in <String>[
          'Small Header',
          'Medium Header',
          'Large Header',
          'Extra-Large Header',
        ])
          textStyleOf(tester, find.text(label))?.fontSize,
      ];
      for (int i = 1; i < ramp.length; i++) {
        expect(ramp[i], isNotNull, reason: 'size $i resolved no type style');
        expect(
          ramp[i]!,
          greaterThan(ramp[i - 1]!),
          reason: 'size $i must sit above size ${i - 1} on the ramp: $ramp',
        );
      }

      // Deliberately NOT four heights. Figma pins all 24 accordion header
      // variants at 44, and `resolveFluentAccordionItemStyle` records React's
      // 32px small header as a divergence it does not take — so the size axis
      // shows up in the type and not in the box, and a test demanding four
      // heights would be asserting React's number against a Figma port.
      final Set<double> heights = <double>{
        for (int i = 0; i < 4; i++)
          tester.getRect(find.byType(FluentAccordionItem).at(i)).height,
      };
      expect(heights, hasLength(1), reason: 'header heights: $heights');
    });

    testWidgets('each of the four accordions toggles on its own', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.text('Large Header'));
      expect(
        find.text('Accordion Panel'),
        findsOneWidget,
        reason: 'four separate accordions share no open set',
      );
      expect(
        tester.getRect(find.byType(FluentAccordionItem).at(2)).height,
        greaterThan(
          tester.getRect(find.byType(FluentAccordionItem).at(3)).height,
        ),
        reason: 'the opened item is the one that grew, not its neighbour',
      );

      await tapAndSettle(tester, find.text('Large Header'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Accordion Panel'), findsNothing);
    });
  });

  group('heading levels', () {
    final DocsSection section = sectionOf(
      'components-accordion--heading-levels',
    );

    testWidgets('the four headers announce as h1 through h4', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Flutter has no element to swap, so upstream's `<h1>`..`<h4>` ride on
      // Semantics.headingLevel — which is the only place the claim in this
      // section's title is observable at all.
      final List<int> levels = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .map((Semantics node) => node.properties.headingLevel)
          .whereType<int>()
          .toList();
      expect(levels, <int>[1, 2, 3, 4]);
    });

    testWidgets('the headings are still ordinary accordion headers', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.text('Accordion Header as h3'));
      expect(find.text('Accordion Panel 3'), findsOneWidget);

      await tapAndSettle(tester, find.text('Accordion Header as h1'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Accordion Panel 1'), findsOneWidget);
      expect(find.text('Accordion Panel 3'), findsNothing);
    });
  });

  group('inline', () {
    final DocsSection section = sectionOf('components-accordion--inline');

    testWidgets('every chevron sits at the trailing edge of its header', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(chevrons, findsNWidgets(3));

      for (int i = 0; i < 3; i++) {
        final Rect item = tester.getRect(
          find.byType(FluentAccordionItem).at(i),
        );
        expect(
          tester.getRect(chevrons.at(i)).center.dx,
          greaterThan(item.center.dx),
          reason: 'item $i asks for expandIconPosition.end',
        );
      }

      await mouseClick(tester, find.text('Accordion Header 2'));
      expect(find.text('Accordion Panel 2'), findsOneWidget);
    });
  });

  group('disabled', () {
    final DocsSection section = sectionOf('components-accordion--disabled');

    testWidgets('no click opens anything and the header paints the dead ramp', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-accordion--default'));
      final Color? live = textStyleOf(
        tester,
        find.text('Accordion Header 1'),
      )?.color;

      await pumpSection(tester, section);
      expect(
        textStyleOf(tester, find.text('Accordion Header 1'))?.color,
        isNot(live),
        reason: '`enabled: false` has to reach the paint, not only the gesture',
      );

      for (int i = 1; i <= 3; i++) {
        await tapAndSettle(
          tester,
          find.text('Accordion Header $i'),
          what: 'the disabled header $i',
          warnIfMissed: false,
        );
      }
      await tester.pump(const Duration(milliseconds: 300));
      for (int i = 1; i <= 3; i++) {
        expect(
          find.text('Accordion Panel $i'),
          findsNothing,
          reason: 'a disabled item must not toggle',
        );
      }
    });
  });

  group('expand icon', () {
    final DocsSection section = sectionOf('components-accordion--expand-icon');

    testWidgets('the custom glyph tracks the open set', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(find.byIcon(FluentIcons.add_20_filled), findsNWidgets(3));
      expect(find.byIcon(FluentIcons.subtract_20_filled), findsNothing);

      await mouseClick(tester, find.text('Accordion Header 1'));
      expect(find.text('Accordion Panel 1'), findsOneWidget);
      expect(
        find.byIcon(FluentIcons.subtract_20_filled),
        findsOneWidget,
        reason: 'the open item swaps add for subtract',
      );
      expect(find.byIcon(FluentIcons.add_20_filled), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byType(FluentAccordionItem).first,
          matching: find.byIcon(FluentIcons.subtract_20_filled),
        ),
        findsOneWidget,
        reason: 'the swapped glyph belongs to the item that opened',
      );

      // Single expansion and not collapsible, so the round trip is through a
      // sibling rather than a second click on the same header.
      await tapAndSettle(tester, find.text('Accordion Header 2'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.descendant(
          of: find.byType(FluentAccordionItem).first,
          matching: find.byIcon(FluentIcons.add_20_filled),
        ),
        findsOneWidget,
      );
    });
  });

  group('expand icon position', () {
    final DocsSection section = sectionOf(
      'components-accordion--expand-icon-position',
    );

    testWidgets('the two items put their chevron on opposite sides', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(chevrons, findsNWidgets(2));

      final Rect first = tester.getRect(find.byType(FluentAccordionItem).at(0));
      final Rect second = tester.getRect(
        find.byType(FluentAccordionItem).at(1),
      );
      expect(
        tester.getRect(chevrons.at(0)).center.dx,
        greaterThan(first.center.dx),
        reason: 'item 1 asks for expandIconPosition.end',
      );
      expect(
        tester.getRect(chevrons.at(1)).center.dx,
        lessThan(second.center.dx),
        reason: 'item 2 takes the default, which is start',
      );

      // Upstream rotates one glyph rather than swapping two, and the start and
      // end variants rest at different angles — so the resting rotations must
      // differ as well as the positions.
      expect(
        chevronTurn(tester, chevrons.at(0)),
        isNot(closeTo(chevronTurn(tester, chevrons.at(1)), 0.001)),
      );
    });

    testWidgets('both positions still toggle their own panel', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final double resting = chevronTurn(tester, chevrons.at(0));

      await mouseClick(tester, find.text('Accordion Header 1'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Accordion Panel 1'), findsOneWidget);
      expect(
        chevronTurn(tester, chevrons.at(0)),
        isNot(closeTo(resting, 0.001)),
        reason: 'the chevron has to turn when its panel opens',
      );

      await tapAndSettle(tester, find.text('Accordion Header 2'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Accordion Panel 2'), findsOneWidget);
      expect(find.text('Accordion Panel 1'), findsNothing);
      expect(chevronTurn(tester, chevrons.at(0)), closeTo(resting, 0.001));
    });
  });

  group('with icon', () {
    final DocsSection section = sectionOf('components-accordion--with-icon');

    testWidgets('the icon sits between the chevron and the label', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byIcon(FluentIcons.rocket_20_regular), findsNWidgets(3));

      final Finder header = find.byType(FluentAccordionItem).first;
      final Rect chevron = tester.getRect(
        find.descendant(of: header, matching: chevrons),
      );
      final Rect icon = tester.getRect(
        find.descendant(
          of: header,
          matching: find.byIcon(FluentIcons.rocket_20_regular),
        ),
      );
      final Rect label = tester.getRect(
        find.descendant(of: header, matching: find.text('Accordion Header 1')),
      );
      expect(chevron.right, lessThanOrEqualTo(icon.left));
      expect(icon.right, lessThanOrEqualTo(label.left));

      await mouseClick(tester, find.text('Accordion Header 1'));
      expect(find.text('Accordion Panel 1'), findsOneWidget);
    });
  });

  group('motion custom', () {
    final DocsSection section = sectionOf(
      'components-accordion--motion-custom',
    );

    testWidgets('the panels open under the personas they name', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Kevin Sturgis'), findsNothing);

      await mouseClick(tester, find.text('Team A'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Kevin Sturgis'), findsWidgets);

      // multiple and collapsible, so Team B joins it and both can go away.
      await tapAndSettle(tester, find.text('Team B'));
      expect(find.byType(FluentPersona), findsNWidgets(12));

      await tapAndSettle(tester, find.text('Team A'));
      await tapAndSettle(tester, find.text('Team B'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(FluentPersona), findsNothing);
    });

    testWidgets('the duration slider changes how long a panel takes to open', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder slider = find.byType(FluentSlider);

      await dropSliderAt(tester, slider, 0);
      expect(find.text('Duration: 100ms'), findsOneWidget);
      final double fast = await heightPartWayOpen(tester);

      await dropSliderAt(tester, slider, 1);
      expect(find.text('Duration: 2000ms'), findsOneWidget);
      final double slow = await heightPartWayOpen(tester);

      // The slider is upstream's `collapseMotion.duration`. 150ms into the
      // opening it is the whole difference between a panel that has arrived and
      // one that has barely started, so a live knob cannot leave the two equal.
      expect(
        slow,
        lessThan(fast),
        reason:
            'the duration slider drives nothing: the panel animates over '
            'FluentMotionSpec.collapse whatever the slider reads',
      );
    });

    testWidgets('the animate-opacity switch stops the panel fading in', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder switchFinder = find.byType(FluentSwitch);

      final double fading = await opacityPartWayOpen(tester);
      expect(
        fading,
        lessThan(1),
        reason: 'with the switch on, the panel fades as it grows',
      );

      await tapAndSettle(tester, switchFinder, what: 'the opacity switch');
      expect(tester.widget<FluentSwitch>(switchFinder).checked, isFalse);

      expect(
        await opacityPartWayOpen(tester),
        1,
        reason:
            'the switch is upstream\'s `animateOpacity`: off, the panel '
            'must grow at full opacity instead of fading',
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
  });
}

/// Every accordion chevron in the tree, in order.
///
/// `_FluentAccordionChevron` never swaps its glyph — the start and end variants
/// are the same icon at different angles — so the icon is what identifies it and
/// the angle is what has to be read separately.
Finder get chevrons => find.byIcon(FluentIcons.chevron_right_20_regular);

/// Opens Team A, measures the panel 150ms in, then puts it back.
///
/// The panel's clip is the animation made visible: `_FluentAccordionPanel`
/// builds a `ClipRect` only while its value is above zero and gives it a height
/// factor, so a partly-open panel is a shorter clip.
Future<double> heightPartWayOpen(WidgetTester tester) async {
  await tester.tap(find.text('Team A'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
  final double height = tester.getRect(panelClip).height;
  await settleOpenThenClose(tester);
  return height;
}

/// Opens Team A, reads the panel's opacity 150ms in, then puts it back.
Future<double> opacityPartWayOpen(WidgetTester tester) async {
  await tester.tap(find.text('Team A'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
  final double opacity = tester
      .widget<Opacity>(
        find.descendant(of: panelClip, matching: find.byType(Opacity)).first,
      )
      .opacity;
  await settleOpenThenClose(tester);
  return opacity;
}

/// Lets the opening finish, closes Team A again and lets that finish too, so
/// the next measurement starts from a cold panel rather than a moving one.
Future<void> settleOpenThenClose(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.tap(find.text('Team A'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
}

/// The clip around the first accordion panel in the tree.
Finder get panelClip => find
    .descendant(
      of: find.byType(FluentAccordionItem).first,
      matching: find.byType(ClipRect),
    )
    .first;
