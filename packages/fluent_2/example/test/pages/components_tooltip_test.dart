import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Tooltip's twelve sections have no knobs at all: the trigger *is* the knob,
/// and every one of them is driven by a resting pointer. So these tests are
/// almost entirely real-mouse tests — `tester.tap` synthesises no enter event,
/// which means it cannot open a single demo on this page — and each asserts
/// where the surface landed as well as that it appeared, because a tooltip
/// pinned to the wrong edge is still a tooltip.
void main() {
  const String page = 'components-tooltip';

  // The surface is anchored above, before or after its trigger, so a trigger
  // flush against the viewport corner puts it at a negative coordinate where
  // nothing hit-tests. The inset is room, not behaviour.
  const EdgeInsets room = EdgeInsets.all(160);

  group('default', () {
    final DocsSection section = sectionOf('components-tooltip--default');

    testWidgets('a resting pointer raises the tip, and only after the dwell', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: room);
      final Finder trigger = find.byType(FluentButton);

      // 100ms is inside `useTooltipBase`'s 250ms showDelay: a tooltip that
      // flashes up while the pointer is merely crossing the control on its way
      // somewhere else is the defect the delay exists to prevent.
      final TestGesture mouse = await mouseHover(
        tester,
        trigger,
        dwell: const Duration(milliseconds: 100),
      );
      expect(find.text('Example tooltip'), findsNothing);

      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Example tooltip'),
        findsOneWidget,
        reason: 'the tip must appear once the pointer has dwelled',
      );
      // Default position is above, and nothing on this section asks for an
      // arrow.
      expect(
        surfaceOf(tester, 'Example tooltip').bottom,
        lessThanOrEqualTo(tester.getRect(trigger).top),
      );
      expect(paintersOf<FluentTooltipArrowPainter>(tester), isEmpty);

      await mouseAway(tester, mouse);
      expect(
        find.text('Example tooltip'),
        findsNothing,
        reason: 'the tip must come down once the pointer leaves',
      );
    });

    testWidgets('the tip can be raised again after it has been dismissed', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: room);

      for (int i = 0; i < 2; i++) {
        final TestGesture mouse = await mouseHover(
          tester,
          find.byType(FluentButton),
        );
        expect(
          find.text('Example tooltip'),
          findsOneWidget,
          reason:
              'hover $i raised nothing — the overlay entry is not being '
              'rebuilt after its first teardown',
        );
        await mouseAway(tester, mouse);
        expect(find.text('Example tooltip'), findsNothing);
      }
    });
  });

  group('relationship', () {
    testWidgets('each icon button raises its own label', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-tooltip--relationship-label'),
        inset: room,
      );

      final TestGesture mouse = await mouseHover(
        tester,
        find.byIcon(FluentIcons.text_italic_20_regular),
      );
      expect(find.text('Italic'), findsOneWidget);
      // The neighbours must stay silent: three tooltips sharing one hover
      // would be indistinguishable from one working tooltip on this section.
      expect(find.text('Bold'), findsNothing);
      expect(find.text('Underline'), findsNothing);
      await mouseAway(tester, mouse);
    });

    testWidgets('the description tooltip also announces itself', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-tooltip--relationship-description'),
        inset: room,
      );

      // `relationship="description"` is an accessibility contract, not a
      // visual one: a tip that only exists on screen is invisible to the
      // technology this section is about. Disposed inline rather than through
      // addTearDown, which runs after the framework's own end-of-test check
      // that no handle is still open.
      final SemanticsHandle handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.text('Button')).tooltip,
        'This is the description of the button',
      );
      handle.dispose();

      final TestGesture mouse = await mouseHover(
        tester,
        find.byType(FluentButton),
      );
      expect(find.text('This is the description of the button'), findsWidgets);
      await mouseAway(tester, mouse);
    });
  });

  group('appearance', () {
    testWidgets('inverted fills the surface with the inverted token', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf('components-tooltip--inverted');
      await pumpSection(tester, section, inset: room);

      final FluentColors colors = FluentTheme.of(
        tester.element(find.byType(FluentButton)),
      ).colors;
      final TestGesture mouse = await mouseHover(
        tester,
        find.byType(FluentButton),
      );

      expect(
        surfaceFill(tester, 'Example inverted tooltip'),
        colors.neutralBackgroundInverted,
        reason:
            'appearance: inverted must reach the painted fill, not just '
            'the constructor',
      );
      await mouseAway(tester, mouse);
    });

    testWidgets('the styled section overrides both tokens', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-tooltip--styled'),
        inset: room,
      );

      final FluentColors colors = FluentTheme.of(
        tester.element(find.byType(FluentButton)),
      ).colors;
      final TestGesture mouse = await mouseHover(
        tester,
        find.byType(FluentButton),
      );

      expect(surfaceFill(tester, 'Example tooltip'), colors.brandBackground);
      // The foreground half of the override only shows up in the text that was
      // actually laid out — a style merged into the wrong slot would leave the
      // fill brand and the text unreadable on it.
      expect(
        tester
            .renderObject<RenderParagraph>(find.text('Example tooltip'))
            .text
            .style
            ?.color,
        colors.neutralForegroundInverted,
      );
      await mouseAway(tester, mouse);
    });
  });

  group('with arrow', () {
    testWidgets('the arrow is drawn and points at the target', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-tooltip--with-arrow'),
        inset: room,
      );

      final TestGesture mouse = await mouseHover(
        tester,
        find.byType(FluentButton),
      );
      expect(find.text('Example tooltip with an arrow'), findsOneWidget);

      final List<FluentTooltipArrowPainter> painters =
          paintersOf<FluentTooltipArrowPainter>(tester);
      expect(painters, hasLength(1), reason: 'withArrow drew no arrow');
      // The surface is above the target, so the arrow has to point back down
      // at it — a painter that ignored the position would draw a triangle
      // pointing away from what it labels.
      expect(painters.single.position, FluentTooltipPosition.above);
      expect(
        painters.single.color,
        surfaceFill(tester, 'Example tooltip with an arrow'),
        reason:
            'the arrow takes the surface fill, or it reads as a detached '
            'shape',
      );
      await mouseAway(tester, mouse);
    });
  });

  group('custom mount', () {
    testWidgets('the surface mounts in the section\'s own overlay', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-tooltip--custom-mount'),
        inset: room,
      );

      // Two: the app's Navigator overlay and the one the demo puts inside its
      // own box. The nested one is deeper, so it comes second in tree order.
      expect(find.byType(Overlay), findsNWidgets(2));
      final TestGesture mouse = await mouseHover(
        tester,
        find.byType(FluentButton),
      );

      expect(
        find.descendant(
          of: find.byType(Overlay).last,
          matching: find.text('Example tooltip'),
        ),
        findsOneWidget,
        reason:
            'the whole point of this section is that the tip lands in the '
            'nearest Overlay, not the app root one',
      );
      await mouseAway(tester, mouse);
    });
  });

  group('controlled', () {
    final DocsSection section = sectionOf('components-tooltip--controlled');
    const String tip =
        'The checkbox controls whether the tooltip can show on hover or focus';

    testWidgets('the checkbox gates the tooltip both ways', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: room);
      final Finder checkbox = find.byType(FluentCheckbox);

      TestGesture mouse = await mouseHover(tester, checkbox);
      expect(
        find.text(tip),
        findsNothing,
        reason: 'unchecked, hover must raise nothing at all',
      );
      await mouseAway(tester, mouse);

      await tapAndSettle(tester, checkbox, what: 'the enable checkbox');
      expect(tester.widget<FluentCheckbox>(checkbox).checked, isTrue);

      mouse = await mouseHover(tester, checkbox);
      expect(
        find.text(tip),
        findsOneWidget,
        reason: 'checked, the same hover must now raise the tip',
      );
      await mouseAway(tester, mouse);

      await tapAndSettle(tester, checkbox, what: 'the enable checkbox');
      expect(tester.widget<FluentCheckbox>(checkbox).checked, isFalse);
      mouse = await mouseHover(tester, checkbox);
      expect(
        find.text(tip),
        findsNothing,
        reason: 'unchecking must close the gate again',
      );
      await mouseAway(tester, mouse);
    });

    testWidgets('disabling while the tip is up takes it down at once', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: room);
      final Finder checkbox = find.byType(FluentCheckbox);

      await tapAndSettle(tester, checkbox);
      final TestGesture mouse = await mouseHover(tester, checkbox);
      expect(find.text(tip), findsOneWidget);

      // Unchecking under the resting pointer: `enabled` is documented as a
      // real state rather than a visual one, so this must not wait out the
      // 250ms hide delay.
      await tester.tap(checkbox);
      await tester.pump();
      await tester.pump();
      expect(
        find.text(tip),
        findsNothing,
        reason:
            'a disabled tooltip must be torn down immediately, not after '
            'the hide delay',
      );
      await mouseAway(tester, mouse);
    });
  });

  group('positioning', () {
    testWidgets('each cell puts its surface on the side it names', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf('components-tooltip--positioning');

      // Each cell rotates the same glyph by a quarter turn per side, so the
      // rotation identifies the cell without depending on the order the Row
      // and Column happen to be built in.
      const Map<String, int> turnsByLabel = <String, int>{
        'above': 0,
        'after': 1,
        'below': 2,
        'before': 3,
      };

      for (final MapEntry<String, int> cell in turnsByLabel.entries) {
        await pumpSection(tester, section, inset: room);
        final Finder trigger = find.ancestor(
          of: find.byWidgetPredicate(
            (Widget w) => w is RotatedBox && w.quarterTurns == cell.value,
          ),
          matching: find.byType(FluentTooltip),
        );
        expect(trigger, findsOneWidget);

        final TestGesture mouse = await mouseHover(tester, trigger);
        expect(
          find.text(cell.key),
          findsOneWidget,
          reason: '${cell.key}: no tip appeared',
        );

        final Rect target = tester.getRect(trigger);
        final Rect surface = surfaceOf(tester, cell.key);
        switch (cell.key) {
          case 'above':
            expect(surface.bottom, lessThanOrEqualTo(target.top));
          case 'below':
            expect(surface.top, greaterThanOrEqualTo(target.bottom));
          case 'before':
            expect(surface.right, lessThanOrEqualTo(target.left));
          case 'after':
            expect(surface.left, greaterThanOrEqualTo(target.right));
        }
        await mouseAway(tester, mouse);
      }
    });
  });

  group('target', () {
    testWidgets('the surface points at the icon, not at the whole button', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-tooltip--target'),
        inset: room,
      );

      final Finder icon = find.byIcon(FluentIcons.arrow_routing_20_regular);
      final Rect button = tester.getRect(find.byType(FluentButton));
      final Rect target = tester.getRect(icon);

      final TestGesture mouse = await mouseHover(tester, icon);
      final Rect surface = surfaceOf(tester, 'This tooltip points to the icon');

      expect(
        surface.center.dx,
        closeTo(target.center.dx, 1),
        reason:
            'the surface is centred on its anchor, which this section says '
            'is the icon',
      );
      // The icon sits at the leading edge of a much wider button, so anchoring
      // to the button instead would be plainly visible here.
      expect((surface.center.dx - button.center.dx).abs(), greaterThan(20));
      await mouseAway(tester, mouse);
    });
  });

  group('icon', () {
    testWidgets('the info label opens its tip on a press', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-tooltip--icon'),
        inset: room,
      );

      // This section is the accessible alternative to a tooltip on a static
      // icon: the affordance is a real button, so it answers a press rather
      // than a hover.
      expect(find.text('Learn more'), findsNothing);
      await tapAndSettle(tester, find.byType(FluentInfoButton));
      expect(find.text('Learn more'), findsOneWidget);
    });
  });

  group('overflow hidden', () {
    testWidgets('the tip hides when its trigger scrolls out of the box', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-tooltip--overflow-hidden'),
        inset: room,
      );

      const String tip = 'I should hide when scrolled out of view';
      final Finder trigger = find.text('Hover me, then scroll');
      final TestGesture mouse = await mouseHover(tester, trigger);
      expect(find.text(tip), findsOneWidget);

      // The demo's own scroll view, not the harness's page scroller: the inner
      // one is the deeper of the two, so it comes second in tree order.
      final ScrollableState inner = tester.state<ScrollableState>(
        find.byType(Scrollable).last,
      );
      inner.position.jumpTo(180);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The surface lives in the app's Overlay, which sits above the clip and
      // is not bounded by it, so a tooltip that stays up follows its trigger
      // straight out of the container it was supposed to belong to.
      expect(
        find.text(tip),
        findsNothing,
        reason:
            'the tip must not outlive the trigger scrolling out of its '
            'clipped container',
      );
      await mouseAway(tester, mouse);
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

    testWidgets('a section unmounts with its tip still up', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf('components-tooltip--with-arrow');
      await pumpSection(tester, section, inset: room);

      final TestGesture mouse = await mouseHover(
        tester,
        find.byType(FluentButton),
      );
      expect(find.text('Example tooltip with an arrow'), findsOneWidget);

      // An OverlayEntry that outlives the widget that inserted it is a leak
      // the closed-tip teardown above cannot see.
      await expectCleanTeardown(tester, '${section.id} with its tip up');
      await mouse.removePointer();
      await tester.pump();
    });
  });
}

/// The rect of the tooltip surface carrying [text].
///
/// The nearest [DecoratedBox] above the content is the surface itself — the
/// fill, the border and the shadow — so its rect is what the reader sees,
/// padding included, where the text's own rect is not.
Rect surfaceOf(WidgetTester tester, String text) => tester.getRect(
  find.ancestor(of: find.text(text), matching: find.byType(DecoratedBox)).first,
);

/// The fill painted behind the tooltip carrying [text].
Color? surfaceFill(WidgetTester tester, String text) =>
    (tester
                .widget<DecoratedBox>(
                  find
                      .ancestor(
                        of: find.text(text),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration)
        .color;
