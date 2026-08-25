import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Popover's thirteen sections are all the same widget with a different job to
/// prove: that the surface opens where it was told to, that it dismisses on the
/// three paths it claims (outside press, Escape, the caller's own state), that
/// a press *inside* it does not, and that the content it was handed is the
/// content that renders.
///
/// Only two sections carry a knob — Controlling Open And Close has a checkbox
/// bound to the same bool as the trigger, and Internal Update Content swaps its
/// own body — so most of the work here is affordances rather than controls.
void main() {
  const String page = 'components-popover';

  /// Every surface on this page is anchored *above* its trigger, and every
  /// trigger is the first thing in its section. Without room overhead the
  /// surface lays out at a negative y, which is not merely invisible: a render
  /// box outside the view hit-tests to nothing, so its buttons would be
  /// unreachable and a passing test would be proving nothing. 400 clears the
  /// tallest of them, the 300-high autosize body.
  const EdgeInsets room = EdgeInsets.all(400);

  group('default', () {
    final DocsSection section = sectionOf('components-popover--default');

    testWidgets('the trigger opens the surface and an outside press closes it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: room);
      expect(find.text('Popover content'), findsNothing);

      await tapAndSettle(tester, find.text('Popover trigger'));
      expect(find.text('Popover content'), findsOneWidget);
      expect(find.text('This is some popover content'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);

      // Far from both the surface and the trigger: the light-dismiss barrier
      // covers the whole overlay, and this is the only thing under the pointer.
      await tester.tapAt(const Offset(1500, 1300));
      await settle(tester);
      expectClean(tester, 'pressing outside the popover');
      expect(find.text('Popover content'), findsNothing);
    });

    testWidgets('a real press inside the surface does not dismiss it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: room);
      await tapAndSettle(tester, find.text('Popover trigger'));

      // The bug this is hunting: the dismiss barrier is a Positioned.fill under
      // the surface, so a surface that failed to sit on top of it would be
      // dismissible but not usable — every press on a control inside it would
      // close the popover instead of pressing the control. A synthetic tap can
      // pass that while a pointer with travel does not, so this one is a mouse.
      await mouseClick(tester, find.text('Action'));
      expect(
        find.text('Popover content'),
        findsOneWidget,
        reason: 'pressing a button inside the popover must not dismiss it',
      );
    });

    testWidgets('Escape closes it', (WidgetTester tester) async {
      await pumpSection(tester, section, inset: room);
      await tapAndSettle(tester, find.text('Popover trigger'));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expectClean(tester, 'pressing Escape');
      expect(find.text('Popover content'), findsNothing);
    });
  });

  group('non interactive content', () {
    testWidgets('the surface is named for assistive technology', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-popover--non-interactive-content'),
        inset: room,
      );
      await tapAndSettle(tester, find.text('Popover trigger'));

      expect(
        find.text('This is some non-interactive popover content.'),
        findsOneWidget,
      );
      // `semanticLabel` is the whole point of this section: with nothing
      // focusable inside, the label is all a screen reader has to announce.
      expect(find.bySemanticsLabel('Popover content'), findsWidgets);
    });
  });

  group('with arrow', () {
    testWidgets('withArrow draws the arrow, and the default does not', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-popover--default'),
        inset: room,
      );
      await tapAndSettle(tester, find.text('Popover trigger'));
      expect(
        paintersOf<FluentPopoverArrowPainter>(tester),
        isEmpty,
        reason: 'withArrow defaults to false, matching React and Figma',
      );

      await pumpSection(
        tester,
        sectionOf('components-popover--with-arrow'),
        inset: room,
      );
      await tapAndSettle(tester, find.text('Popover trigger'));

      final List<FluentPopoverArrowPainter> arrows =
          paintersOf<FluentPopoverArrowPainter>(tester);
      expect(arrows, hasLength(1));
      expect(
        arrows.single.position,
        FluentPopoverPosition.above,
        // The painter draws a different path per side; the arrow has to point
        // back at the anchor, which for a surface above means downward.
        reason: 'the arrow must point at the trigger it is anchored to',
      );
      expect(
        arrows.single.color,
        surfaceFill(tester),
        reason: 'the arrow is filled with the surface tone, never its own',
      );
    });
  });

  group('with arrow autosize', () {
    testWidgets('the body scrolls inside a capped surface', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-popover--with-arrow-autosize'),
        inset: room,
      );
      await tapAndSettle(tester, find.text('Popover trigger'));

      final Finder body = find.descendant(
        of: popoverSurface,
        matching: find.byType(Scrollable),
      );
      expect(body, findsOneWidget);
      final ScrollableState scroll = tester.state<ScrollableState>(body);
      expect(
        scroll.position.maxScrollExtent,
        greaterThan(0),
        reason:
            'the point of the section is that the body overflows and '
            'scrolls rather than growing the surface',
      );

      final double before = tester.getRect(find.text('Popover content')).top;
      await tester.drag(body, const Offset(0, -120));
      await settle(tester);
      expectClean(tester, 'scrolling the popover body');
      expect(
        tester.getRect(find.text('Popover content')).top,
        lessThan(before),
        reason: 'dragging the body must move it, not the surface',
      );
      // The arrow is outside the scrolling box, which is what stops it being
      // clipped — upstream's whole reason for this story.
      expect(paintersOf<FluentPopoverArrowPainter>(tester), hasLength(1));
    });
  });

  group('trapping focus', () {
    testWidgets('focus moves into the surface and comes back on Escape', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-popover--trapping-focus'),
        inset: room,
      );
      // Focused first, because "focus returns to whatever held it" can only be
      // checked against something that held it — and a press moves no focus in
      // this package, so after a bare tap the root scope still has it.
      final Finder trigger = find.widgetWithText(
        FluentButton,
        'Popover trigger',
      );
      await focusOn(tester, trigger);

      await tapAndSettle(tester, find.text('Popover trigger'));
      expect(
        focusIsInside(tester, trigger),
        isFalse,
        reason: 'focus has to leave the page behind the surface',
      );
      expect(
        focusEncloses(tester, find.text('Action')),
        isTrue,
        // FluentPopover asks its own FocusScope for focus rather than reaching
        // for the first focusable child, so the node holding it is the scope —
        // which is still inside the surface, and is what makes Tab cycle
        // within it instead of walking off into the page.
        reason: 'the focused node must be the surface or something inside it',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expectClean(tester, 'pressing Escape');
      expect(
        focusIsInside(tester, trigger),
        isTrue,
        reason: 'closing must hand focus back to whatever held it',
      );
    });
  });

  group('controlling open and close', () {
    final DocsSection section = sectionOf(
      'components-popover--controlling-open-and-close',
    );

    testWidgets('the open checkbox opens and closes the surface', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: room);
      final Finder checkbox = find.byType(FluentCheckbox);
      expect(tester.widget<FluentCheckbox>(checkbox).checked, isFalse);

      // The page's only real knob, so this is the one driven with a pointer.
      await mouseClick(tester, checkbox);
      expect(tester.widget<FluentCheckbox>(checkbox).checked, isTrue);
      expect(
        find.text('This is some popover content'),
        findsOneWidget,
        reason: 'the checkbox is bound to the same bool as the trigger',
      );

      // Round trip. The checkbox is outside the surface, so the press has to
      // reach it past the light-dismiss barrier — which closes the popover on
      // the way through, leaving the box unticked either way. Both halves of
      // that have to hold.
      await tester.tapAt(const Offset(1500, 1300));
      await settle(tester);
      expectClean(tester, 'dismissing from outside');
      expect(tester.widget<FluentCheckbox>(checkbox).checked, isFalse);
      expect(find.text('This is some popover content'), findsNothing);
    });

    testWidgets('the trigger keeps the checkbox in sync', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: room);
      await tapAndSettle(tester, find.text('Controlled trigger'));
      expect(
        tester.widget<FluentCheckbox>(find.byType(FluentCheckbox)).checked,
        isTrue,
        reason: 'one bool drives both, so the trigger has to tick the box',
      );
    });
  });

  group('motion', () {
    testWidgets('the stock entrance fades in and motion disabled does not', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-popover--motion-custom'),
        inset: room,
      );
      await openWithoutSettling(tester, find.text('Open popover'));
      final double? fading = entranceOpacity(tester);
      expect(
        fading,
        isNotNull,
        reason: 'the surface should be in the overlay by the second frame',
      );
      expect(
        fading,
        lessThan(1),
        reason:
            'FluentPopoverEntrance fades the surface in over durationSlower',
      );
      // Let the entrance finish before the tree is torn down.
      await settle(tester);

      await pumpSection(
        tester,
        sectionOf('components-popover--motion-disabled'),
        inset: room,
      );
      await openWithoutSettling(tester, find.text('Open popover'));
      expect(
        entranceOpacity(tester),
        1,
        reason:
            'disableAnimations collapses the entrance to zero duration, so '
            'the first painted frame is already the end state',
      );
      expect(find.text('This popover has motion disabled'), findsOneWidget);
      await settle(tester);
    });
  });

  group('nested popovers', () {
    testWidgets('each level opens inside the one above and leaves it open', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-popover--nested-popovers'),
        inset: room,
      );

      await tapAndSettle(tester, find.text('Root trigger'));
      expect(find.text('Root button'), findsOneWidget);
      expect(find.text('First nested trigger'), findsOneWidget);

      await tapAndSettle(tester, find.text('First nested trigger'));
      expect(find.text('First nested button'), findsOneWidget);
      expect(
        find.text('Root button'),
        findsOneWidget,
        reason:
            'the nested trigger is inside the root surface, so opening it '
            'must not trip the root popover\'s own dismiss barrier',
      );
      expect(
        find.text('Second nested trigger'),
        findsNWidgets(2),
        reason: 'the first level holds two second-level triggers',
      );

      await tapAndSettle(tester, find.text('Second nested trigger').first);
      expect(find.text('Second nested button'), findsOneWidget);
      expect(find.text('First nested button'), findsOneWidget);
      expect(find.text('Root button'), findsOneWidget);
    });
  });

  group('anchor to custom target', () {
    testWidgets('the surface follows the custom target, not the opener', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-popover--anchor-to-custom-target'),
        inset: room,
      );
      final double opener = tester
          .getRect(find.widgetWithText(FluentButton, 'Popover trigger'))
          .center
          .dx;
      final double target = tester
          .getRect(find.widgetWithText(FluentButton, 'Custom target'))
          .center
          .dx;
      expect(
        target,
        isNot(closeTo(opener, 40)),
        reason:
            'the two have to be far enough apart for the test to mean '
            'anything',
      );

      await tapAndSettle(tester, find.text('Popover trigger'));
      // This is the whole retarget: `child` is the anchor, and the button that
      // flips the bool is a separate widget entirely.
      expect(tester.getRect(popoverSurface).center.dx, closeTo(target, 1));
    });
  });

  group('custom trigger', () {
    testWidgets('a caller-supplied widget opens the popover', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-popover--custom-trigger'),
        inset: room,
      );
      await tapAndSettle(tester, find.text('Custom Trigger'));
      expect(find.text('This is some popover content'), findsOneWidget);
      expect(
        find.text('Custom Trigger'),
        findsOneWidget,
        reason: 'the trigger is rendered in place and stays there',
      );
    });
  });

  group('without trigger', () {
    testWidgets('the toggle opens the surface and Escape returns focus to it', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-popover--without-trigger'),
        inset: room,
      );
      final Finder toggle = find.widgetWithText(FluentButton, 'Toggle popover');
      await focusOn(tester, toggle);
      await tapAndSettle(tester, find.text('Toggle popover'));
      expect(find.text('This is some popover content'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expectClean(tester, 'pressing Escape');
      // The section's claim: focus restoration is the popover's job, not the
      // caller's, even when the caller supplied no trigger of its own.
      expect(focusIsInside(tester, toggle), isTrue);
    });
  });

  group('internal update content', () {
    testWidgets('Action swaps in the second panel, and closing resets it', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-popover--internal-update-content'),
        inset: room,
      );
      await tapAndSettle(tester, find.text('Popover trigger'));
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('The second panel content'), findsNothing);

      await tapAndSettle(tester, find.text('Action'));
      expect(find.text('The second panel content'), findsOneWidget);
      expect(find.text('and a link'), findsOneWidget);
      expect(
        find.text('Action'),
        findsNothing,
        reason: 'the panel replaces the button rather than joining it',
      );

      await tester.tapAt(const Offset(1500, 1300));
      await settle(tester);
      expectClean(tester, 'dismissing from outside');
      await tapAndSettle(tester, find.text('Popover trigger'));
      expect(
        find.text('Action'),
        findsOneWidget,
        reason:
            'onOpenChanged(false) resets the panel, so a reopened popover '
            'starts on the first one',
      );
      expect(find.text('The second panel content'), findsNothing);
    });
  });

  group('appearance', () {
    testWidgets('each appearance fills the surface with its own token', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-popover--appearance'),
        inset: room,
      );

      final Map<String, Color?> fills = <String, Color?>{};
      for (final String label in <String>[
        'Default appearance Popover trigger',
        'Brand appearance Popover trigger',
        'Inverted appearance Popover trigger',
      ]) {
        await tapAndSettle(tester, find.text(label));
        expect(
          find.text('This is some popover content'),
          findsOneWidget,
          reason: '"$label" opened nothing',
        );
        fills[label] = surfaceFill(tester);
        // Dismissed between opens: the open surface's barrier covers the next
        // trigger, so a press aimed at it would land on the barrier instead.
        await tester.tapAt(const Offset(1500, 1300));
        await settle(tester);
        expectClean(tester, 'dismissing after "$label"');
      }

      expect(fills.values.whereType<Color>(), hasLength(3));
      expect(
        fills.values.toSet(),
        hasLength(3),
        reason:
            'normal, brand and inverted must be three different fills, not '
            'three labels over one: $fills',
      );
    });
  });

  group('affordances', () {
    testWidgets('every section opens a popover from its first button', (
      WidgetTester tester,
    ) async {
      // The contract the whole page rests on. Sections whose surface is only
      // reachable through a knob would fail here rather than pass quietly.
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section, inset: room);
        expect(
          find.text('Popover content'),
          findsNothing,
          reason: '${section.id} starts open',
        );

        await tapAndSettle(
          tester,
          find.byType(FluentButton).first,
          what: '${section.id} first button',
        );
        expect(
          find.text('Popover content'),
          findsWidgets,
          reason: '${section.id}: the first button opened nothing',
        );
        await expectCleanTeardown(tester, '${section.id} while open');
      }
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section, inset: room);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// The popover surface itself.
///
/// It is the one [DecoratedBox] in the tree that carries a shadow —
/// `resolveFluentPopoverStyle` gives it `shadow16`, and nothing in any of these
/// bodies has one — and it lives in the [Overlay] rather than under
/// `FluentPopover`, so no descendant finder can reach it from the widget.
final Finder popoverSurface = find.byWidgetPredicate((Widget widget) {
  if (widget is! DecoratedBox) return false;
  final Decoration decoration = widget.decoration;
  return decoration is BoxDecoration &&
      (decoration.boxShadow?.isNotEmpty ?? false);
}, description: 'the popover surface');

/// The fill of the surface itself, not of anything sitting on it.
///
/// Deliberately not [fillOf]: that walks *descendants*, and the first filled
/// box inside a popover is whichever button the body happens to start with —
/// which is the same neutral tone whatever the surface's appearance is, so a
/// descendant read would report all three appearances as identical.
Color? surfaceFill(WidgetTester tester) =>
    (tester.widget<DecoratedBox>(popoverSurface).decoration as BoxDecoration)
        .color;

/// Presses [trigger] and pumps exactly far enough for the overlay to build.
///
/// [settle] would run the entrance to completion, which is the one thing a
/// motion test must not do: the difference between the stock entrance and a
/// disabled one is only visible on the frame the surface arrives.
Future<void> openWithoutSettling(WidgetTester tester, Finder trigger) async {
  await tester.tap(trigger);
  // One frame to run the post-frame callback that inserts the OverlayEntry,
  // one more to build it.
  await tester.pump();
  await tester.pump();
}

/// The opacity [FluentPopoverEntrance] is currently applying, or null.
double? entranceOpacity(WidgetTester tester) {
  final Iterable<Opacity> layers = tester.widgetList<Opacity>(
    find.byType(Opacity),
  );
  return layers.isEmpty ? null : layers.first.opacity;
}
