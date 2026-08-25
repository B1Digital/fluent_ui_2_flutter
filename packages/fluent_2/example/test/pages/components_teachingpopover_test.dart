import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// TeachingPopover's five sections are one widget in three dresses: a single
/// step, a brand-filled single step, and three carousel tours. The page has no
/// knobs of its own — the popover *is* the control surface — so these tests
/// drive the trigger, the header's dismiss button, the two footer actions and
/// the dot strip, and assert the tour actually moved rather than that a
/// callback fired.
///
/// Every one of the three tours changes its own action labels as it walks
/// (`Close`/`Previous`, `Next`/`Finish`), which is the cheapest observable
/// proof that the step really advanced: the body text and the labels have to
/// agree.
void main() {
  const String page = 'components-teachingpopover';

  group('default', () {
    final DocsSection section = sectionOf(
      'components-teachingpopover--default',
    );

    testWidgets('the trigger opens the surface with all four content slots', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        find.text('Teaching Bubble Title'),
        findsNothing,
        reason: 'the popover starts closed',
      );

      await tester.tap(find.text('TeachingPopover trigger'));
      await settle(tester);
      expectCleanExceptOverflow(tester, 'opening the default teaching popover');

      // Header, media, title and body are four separate slots on
      // FluentTeachingPopover, and each is null-able: a port that dropped one
      // would still render a plausible-looking popover.
      expect(find.text('Tips'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Teaching Bubble Title'), findsOneWidget);
      expect(find.text('This is a teaching popover body'), findsOneWidget);
      expect(
        find.byIcon(fluentTeachingPopoverDismissIcon),
        findsOneWidget,
        reason: 'a non-null onDismiss is what draws the dismiss button',
      );
    });

    testWidgets('the dismiss button closes it under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tester.tap(find.text('TeachingPopover trigger'));
      await settle(tester);
      expectCleanExceptOverflow(tester, 'opening the default teaching popover');

      // The dismiss glyph is drawn by FluentInteractive rather than by a
      // FluentButton, and an interactive built by hand is exactly the kind of
      // target that answers a synthetic tap while being unreachable with a
      // pointer — so this one is clicked, not tapped.
      await mouseClick(tester, find.byIcon(fluentTeachingPopoverDismissIcon));
      expect(find.text('Teaching Bubble Title'), findsNothing);
    });

    testWidgets('either footer action closes the popover', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      for (final String label in <String>['Learn more', 'Got it']) {
        await tester.tap(find.text('TeachingPopover trigger'));
        await settle(tester);
        expectCleanExceptOverflow(tester, 'opening for "$label"');
        expect(find.text(label), findsOneWidget);

        await tester.tap(find.text(label));
        await settle(tester);
        expectCleanExceptOverflow(tester, 'pressing "$label"');
        expect(
          find.text('Teaching Bubble Title'),
          findsNothing,
          reason: '"$label" must close the popover',
        );
      }
    });
  });

  group('appearance brand', () {
    testWidgets('brand fills the surface with a different token to normal', (
      WidgetTester tester,
    ) async {
      // Both sections in one test on purpose: `appearance` is only meaningful
      // as a difference, and a single-section test could only assert whatever
      // colour happened to come out.
      await pumpSection(
        tester,
        sectionOf('components-teachingpopover--default'),
      );
      await tester.tap(find.text('TeachingPopover trigger'));
      await settle(tester);
      expectCleanExceptOverflow(tester, 'opening the normal popover');
      final Color? normal = surfaceFill(tester);
      expect(normal, isNotNull, reason: 'the surface must be filled');

      await pumpSection(
        tester,
        sectionOf('components-teachingpopover--appearance-brand'),
      );
      await tester.tap(find.text('TeachingPopover trigger'));
      await settle(tester);
      expectCleanExceptOverflow(tester, 'opening the brand popover');

      expect(
        surfaceFill(tester),
        isNot(normal),
        reason: 'brand must repaint the surface, not only re-tint the text',
      );
    });
  });

  group('carousel', () {
    final DocsSection section = sectionOf(
      'components-teachingpopover--carousel',
    );

    testWidgets('the trigger opens the tour under a real mouse', (
      WidgetTester tester,
    ) async {
      await mouseClick(tester, await triggerOf(tester, section));

      expect(find.text('This is page: 1'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('^Tip ')),
        findsNWidgets(3),
        reason: 'three cards means three dots',
      );
      // First step: the secondary action is the swap-in `Close`, not
      // `Previous`, and the primary is `Next`, not `Finish`.
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Next and Previous walk the tour and swap the labels', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tester.tap(find.text('TeachingPopover trigger'));
      await settle(tester);
      expectCleanExceptOverflow(tester, 'opening the tour');

      await tester.tap(find.text('Next'));
      await settle(tester);
      expectCleanExceptOverflow(tester, 'pressing Next');
      expect(find.text('This is page: 2'), findsOneWidget);
      expect(
        find.text('Previous'),
        findsOneWidget,
        reason: 'off the first step the secondary action stops being Close',
      );
      expect(find.text('Next'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await settle(tester);
      expectCleanExceptOverflow(tester, 'pressing Next again');
      expect(find.text('This is page: 3'), findsOneWidget);
      expect(
        find.text('Finish'),
        findsOneWidget,
        reason: 'the last step swaps Next for Finish',
      );

      // Round trip: walking back has to restore both the body and the labels.
      await tester.tap(find.text('Previous'));
      await settle(tester);
      expectCleanExceptOverflow(tester, 'pressing Previous');
      expect(find.text('This is page: 2'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('a dot jumps straight to its step', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tester.tap(find.text('TeachingPopover trigger'));
      await settle(tester);
      expectCleanExceptOverflow(tester, 'opening the tour');

      await tester.tap(find.bySemanticsLabel('Tip 3').first);
      await settle(tester);
      expectCleanExceptOverflow(tester, 'pressing the third dot');
      expect(
        find.text('This is page: 3'),
        findsOneWidget,
        reason: 'a dot is a jump, not a step — page 2 must be skipped',
      );
      expect(find.text('Finish'), findsOneWidget);

      // The active dot is a 16 x 8 pill where the others are 8-squares, so the
      // strip has to say which step is showing as well as accept the press.
      expect(activeDotIndex(tester), 2);
    });

    testWidgets('reopening the trigger restarts the tour at step one', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tester.tap(find.text('TeachingPopover trigger'));
      await settle(tester);
      expectCleanExceptOverflow(tester, 'opening the tour');
      await tester.tap(find.text('Next'));
      await settle(tester);
      expectCleanExceptOverflow(tester, 'pressing Next');
      expect(find.text('This is page: 2'), findsOneWidget);

      // Dismissed from outside rather than from the trigger: an open
      // FluentPopover lays a full-screen light-dismiss barrier under its
      // surface, so a press aimed at the trigger lands on that instead and the
      // trigger's own toggle never runs. Which is fine — it closes either way
      // — but the reset below has to survive the barrier's path too, and that
      // is the path a user actually takes.
      await tester.tapAt(const Offset(1500, 1300));
      await settle(tester);
      expectCleanExceptOverflow(tester, 'dismissing from outside');
      expect(find.text('This is page: 2'), findsNothing);

      await tester.tap(find.text('TeachingPopover trigger'));
      await settle(tester);
      expectCleanExceptOverflow(tester, 'reopening the tour');
      expect(
        find.text('This is page: 1'),
        findsOneWidget,
        reason: 'the trigger resets _step, so a reopened tour starts over',
      );
      expect(activeDotIndex(tester), 0);
    });

    testWidgets(
      'Close on the first step and Finish on the last both close it',
      (WidgetTester tester) async {
        await pumpSection(tester, section);
        await tester.tap(find.text('TeachingPopover trigger'));
        await settle(tester);
        expectCleanExceptOverflow(tester, 'opening the tour');
        await tester.tap(find.text('Close'));
        await settle(tester);
        expectCleanExceptOverflow(tester, 'pressing Close');
        expect(find.text('This is page: 1'), findsNothing);

        await tester.tap(find.text('TeachingPopover trigger'));
        await settle(tester);
        expectCleanExceptOverflow(tester, 'reopening the tour');
        await tester.tap(find.bySemanticsLabel('Tip 3').first);
        await settle(tester);
        expectCleanExceptOverflow(tester, 'jumping to the last step');
        await tester.tap(find.text('Finish'));
        await settle(tester);
        expectCleanExceptOverflow(tester, 'pressing Finish');
        expect(find.text('This is page: 3'), findsNothing);
      },
    );
  });

  group('carousel brand', () {
    testWidgets('the brand tour walks and keeps its brand fill', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf(
        'components-teachingpopover--carousel-brand',
      );
      await pumpSection(tester, section);
      await tester.tap(find.text('TeachingPopover trigger'));
      await settle(tester);
      expectCleanExceptOverflow(tester, 'opening the brand tour');
      final Color? fill = surfaceFill(tester);

      await tester.tap(find.text('Next'));
      await settle(tester);
      expectCleanExceptOverflow(tester, 'pressing Next');
      expect(find.text('This is page: 2'), findsOneWidget);
      expect(
        surfaceFill(tester),
        fill,
        reason: 'walking the tour must not disturb the appearance',
      );
      expect(activeDotIndex(tester), 1);
    });
  });

  group('carousel text', () {
    testWidgets('the page count tracks the active step', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf(
        'components-teachingpopover--carousel-text',
      );
      await pumpSection(tester, section);
      await tester.tap(find.text('TeachingPopover trigger'));
      await settle(tester);
      expectCleanExceptOverflow(tester, 'opening the counted tour');

      // The count is the whole point of this section: it is drawn *beside* the
      // dots rather than instead of them, so both have to move together.
      expect(find.text('1 of 3'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Tip ')), findsNWidgets(3));

      // Walked with the dots rather than with Next. The count is one more
      // child in an already-full 288-wide footer, and under the harness's
      // square font that pushes the primary action past the surface edge,
      // where RenderFlex clips it away and no pointer can reach it. The dots
      // sit at the leading end and stay inside either way.
      await tester.tap(find.bySemanticsLabel('Tip 2').first);
      await settle(tester);
      expectCleanExceptOverflow(tester, 'pressing the second dot');
      expect(find.text('2 of 3'), findsOneWidget);
      expect(find.text('1 of 3'), findsNothing);
      expect(find.text('This is page: 2'), findsOneWidget);
      expect(activeDotIndex(tester), 1);

      await tester.tap(find.bySemanticsLabel('Tip 1').first);
      await settle(tester);
      expectCleanExceptOverflow(tester, 'pressing the first dot');
      expect(find.text('1 of 3'), findsOneWidget);
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

    testWidgets('every section unmounts with its popover still open', (
      WidgetTester tester,
    ) async {
      // The interesting half: FluentPopover owns an OverlayEntry and a
      // FocusScopeNode, and both are torn down in dispose. Unmounting a closed
      // popover exercises neither.
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await tester.tap(find.text('TeachingPopover trigger'));
        await settle(tester);
        expectCleanExceptOverflow(tester, 'opening ${section.id}');
        expect(
          find.text('Teaching Bubble Title'),
          findsOneWidget,
          reason: '${section.id}: the trigger opened nothing',
        );
        await expectCleanTeardown(tester, '${section.id} while open');
      }
    });
  });
}

/// Mounts [section] and returns a finder for its trigger button.
Future<Finder> triggerOf(WidgetTester tester, DocsSection section) async {
  await pumpSection(tester, section);
  return find.text('TeachingPopover trigger');
}

/// The fill of the popover surface currently in the overlay, or null.
///
/// The surface is the only [DecoratedBox] in the tree carrying a shadow —
/// `resolveFluentPopoverStyle` gives it `shadow16` and nothing inside a
/// teaching popover has one — and it lives in the [Overlay] rather than under
/// the widget, so no descendant finder can reach it from `FluentTeachingPopover`.
Color? surfaceFill(WidgetTester tester) {
  for (final DecoratedBox box in tester.widgetList<DecoratedBox>(
    find.byType(DecoratedBox),
  )) {
    final Decoration decoration = box.decoration;
    if (decoration is BoxDecoration &&
        (decoration.boxShadow?.isNotEmpty ?? false)) {
      return decoration.color;
    }
  }
  return null;
}

/// Which dot the strip is currently drawing as active.
///
/// The dots carry no text and no selected flag a widget finder can read, but
/// the active one is a 16 x 8 pill where the rest are 8-squares — so geometry
/// is the honest answer to "which step is showing", and it is the one a user
/// actually sees.
int activeDotIndex(WidgetTester tester) {
  final Finder dots = find.bySemanticsLabel(RegExp('^Tip '));
  final List<double> widths = <double>[
    for (int i = 0; i < dots.evaluate().length; i++)
      tester.getSize(dots.at(i)).width,
  ];
  final double widest = widths.reduce((double a, double b) => a > b ? a : b);
  return widths.indexOf(widest);
}
