import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Card's page has no dropdowns or switches: its knobs are the cards
/// themselves. Orientation, size and appearance are each rendered once per
/// value, so the "knob" is the difference *between* the demos, and the tests
/// below read that difference off the geometry and the painted fill rather than
/// off the widget's own field — a card that took `size: large` and laid out at
/// medium would satisfy the field and fail the page.
///
/// The rest of the page is behaviour: a selectable card toggles from its
/// surface and from its floating checkbox, a disabled one refuses both, and the
/// action cards report through a callback the demo prints back on screen.
void main() {
  const String page = 'components-card-card';

  Finder cardAt(int index) => find.byType(FluentCard).at(index);
  FluentCard card(WidgetTester tester, int index) =>
      tester.widget<FluentCard>(cardAt(index));
  Color? fillAt(WidgetTester tester, int index) =>
      decorationUnder(tester, cardAt(index)).color;
  // Every card draws a border, including the three appearances that look like
  // they have none: their resting token is `transparentStrokeInteractive`,
  // which is invisible in light and dark and opaque in high contrast. So the
  // honest question is never "is there a border" but "which token is in it".
  BorderSide sideAt(WidgetTester tester, int index) =>
      decorationUnder(tester, cardAt(index), at: 1).border!.top;
  FluentColors colorsOf(WidgetTester tester) =>
      FluentTheme.of(tester.element(cardAt(0))).colors;

  group('default', () {
    final DocsSection section = sectionOf('components-card-card--default');
    // The demo's own declared width: the harness's scroll view hands the demo a
    // tight cross-axis constraint, so a root `SizedBox(width: 720)` under a
    // wider viewport is stretched past the width the shell would give it.
    const Size viewport = Size(720, 1000);

    testWidgets('the preview bleeds and the other slots are inset by 12', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, size: viewport);

      final Rect cardRect = tester.getRect(cardAt(0));
      final Rect preview = tester.getRect(find.byType(Image));
      // The header row, not the avatar inside it: the avatar is centred against
      // two lines of text, so its own top is short of the slot's by a few px.
      final Rect header = tester.getRect(
        find
            .ancestor(of: find.byType(FluentAvatar), matching: find.byType(Row))
            .first,
      );
      final Rect reply = tester.getRect(
        find.widgetWithText(FluentButton, 'Reply'),
      );

      // The whole anatomy of a card in five numbers: media to the edge, header
      // and footer inside the padding. An inset preview or an un-inset footer
      // are the two ways this arrangement is usually got wrong.
      expect(preview.left, cardRect.left);
      expect(preview.right, cardRect.right);
      expect(preview.top, cardRect.top);
      expect(preview.height, 240);
      expect(header.left, cardRect.left + 12);
      expect(header.top - preview.bottom, 12);
      expect(cardRect.bottom - reply.bottom, 12);
    });

    testWidgets('the mention line and both footer actions are live', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, size: viewport);

      expect(find.text('5h ago · About us - Overview'), findsOneWidget);
      expect(
        tester.widget<FluentAvatar>(find.byType(FluentAvatar)).initials,
        'EA',
      );
      for (final String label in <String>['Reply', 'Share']) {
        expect(
          tester
              .widget<FluentButton>(find.widgetWithText(FluentButton, label))
              .onPressed,
          isNotNull,
        );
      }
    });

    testWidgets('the card is inert under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, size: viewport);

      // This story gives the card no `onPressed`, and an inert card is
      // documented as a different component from an interactive one rather than
      // a disabled one: it must keep its resting fill under a pointer. Only a
      // real mouse enters the MouseRegion that would prove otherwise.
      final Color? resting = fillAt(tester, 0);
      expect(
        await whileHovering(tester, cardAt(0), () => fillAt(tester, 0)),
        resting,
      );
      await mouseClick(tester, cardAt(0));
      expect(fillAt(tester, 0), resting);
    });
  });

  group('orientation', () {
    final DocsSection section = sectionOf('components-card-card--orientation');

    testWidgets('vertical stacks its slots and horizontal lays them in a row', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(card(tester, 0).orientation, FluentCardOrientation.vertical);
      expect(card(tester, 1).orientation, FluentCardOrientation.horizontal);

      // The vertical card: header over body, both on the card's own leading
      // inset. The header ROW, not its title — the title sits behind the logo.
      final Rect header = tester.getRect(
        find
            .ancestor(
              of: find.text('App Name').at(0),
              matching: find.byType(Row),
            )
            .first,
      );
      final Rect body = tester.getRect(
        find.textContaining('Donut chocolate bar').first,
      );
      expect(body.top, greaterThanOrEqualTo(header.bottom));
      expect(body.left, header.left);
      expect(header.left, tester.getRect(cardAt(0)).left + 12);

      // The horizontal card: preview before the slots on the main axis, and
      // centred on the cross axis — which is the only thing `orientation`
      // changes, so it is the only honest test of it.
      final Rect horizontal = tester.getRect(cardAt(1));
      final Rect logo = tester.getRect(find.byType(Container).last);
      final Rect title = tester.getRect(find.text('App Name').at(1));
      expect(logo.right, lessThanOrEqualTo(title.left));
      expect(logo.center.dy, closeTo(horizontal.center.dy, 0.5));
      expect(
        title.top,
        greaterThan(logo.top - logo.height),
        reason: 'a horizontal card must not stack its slots',
      );
    });

    testWidgets('the overflow buttons in both cards are live', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder more = find.byWidgetPredicate(
        (Widget w) => w is FluentButton && w.semanticLabel == 'More options',
      );

      expect(more, findsNWidgets(2));
      for (final FluentButton button in tester.widgetList<FluentButton>(more)) {
        expect(button.onPressed, isNotNull);
      }
      // The horizontal card's action is the one most likely to end up
      // unreachable: it sits at the end of a `MainAxisSize.min` row that hugs
      // its content, so a mis-sized parent clips it out of the hit test.
      await mouseClick(tester, more.last);
    });
  });

  group('size', () {
    final DocsSection section = sectionOf('components-card-card--size');

    testWidgets('each step drives its own inset, gap and corner radius', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      const List<(FluentCardSize, double, BorderRadius)> steps =
          <(FluentCardSize, double, BorderRadius)>[
            (FluentCardSize.small, 8, FluentRadius.allSmall),
            (FluentCardSize.medium, 12, FluentRadius.allMedium),
            (FluentCardSize.large, 16, FluentRadius.allLarge),
          ];

      for (final (
            int index,
            (FluentCardSize size, double inset, BorderRadius radius),
          )
          entry
          in steps.indexed) {
        final (FluentCardSize size, double inset, BorderRadius radius) =
            entry.$2;
        final int index = entry.$1;
        expect(card(tester, index).size, size);

        final Rect cardRect = tester.getRect(cardAt(index));
        final Rect header = tester.getRect(
          find
              .descendant(of: cardAt(index), matching: find.byType(Container))
              .first,
        );
        final Rect body = tester.getRect(
          find.descendant(
            of: cardAt(index),
            matching: find.textContaining('Alert in Teams'),
          ),
        );
        final Rect footer = tester.getRect(
          find.descendant(of: cardAt(index), matching: find.text('Automated')),
        );

        // Upstream drives the inset and the gap from one variable, so all three
        // numbers move together. A size knob wired to the radius alone — the
        // usual half-implementation — passes on the radius line and fails here.
        expect(header.left - cardRect.left, inset, reason: '$size inset');
        expect(header.top - cardRect.top, inset, reason: '$size top inset');
        expect(cardRect.bottom - footer.bottom, inset, reason: '$size bottom');
        expect(body.top - header.bottom, inset, reason: '$size gap');
        expect(
          decorationUnder(tester, cardAt(index)).borderRadius,
          radius,
          reason: '$size radius',
        );
      }
    });
  });

  group('appearance', () {
    final DocsSection section = sectionOf('components-card-card--appearance');

    testWidgets('each appearance paints its own resting surface', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = colorsOf(tester);

      expect(
        <FluentCardAppearance>[
          for (int i = 0; i < 4; i++) card(tester, i).appearance,
        ],
        <FluentCardAppearance>[
          FluentCardAppearance.filled,
          FluentCardAppearance.filledAlternative,
          FluentCardAppearance.outline,
          FluentCardAppearance.subtle,
        ],
      );

      expect(fillAt(tester, 0), colors.neutralBackground1);
      expect(fillAt(tester, 1), colors.neutralBackground2);
      expect(fillAt(tester, 2), colors.transparentBackground);
      expect(fillAt(tester, 3), colors.subtleBackground);

      // Outline and subtle share a transparent fill, so the fill alone cannot
      // tell them apart: the border and the elevation are what carry the
      // difference, and they are what a broken appearance switch loses.
      expect(sideAt(tester, 2).color, colors.neutralStroke1);
      expect(sideAt(tester, 3).color, colors.transparentStrokeInteractive);
      expect(decorationUnder(tester, cardAt(0)).boxShadow, isNotNull);
      expect(decorationUnder(tester, cardAt(3)).boxShadow, isNull);
    });

    testWidgets('an interactive card reacts to a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = colorsOf(tester);

      // Every card in this story has an `onPressed`, which is what earns it the
      // hover tokens. `tester.tap` never enters the MouseRegion, so this is the
      // only test on the page that can prove the interactive set was merged.
      final (Color?, Color) hovered = await whileHovering(
        tester,
        cardAt(0),
        () => (fillAt(tester, 0), sideAt(tester, 2).color),
      );
      expect(hovered.$1, colors.neutralBackground1Hover);
      expect(
        hovered.$2,
        colors.neutralStroke1,
        reason: 'hovering one card must not restyle another',
      );

      expect(fillAt(tester, 0), colors.neutralBackground1);
    });

    testWidgets('hovering the outline card moves its border, not its fill', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = colorsOf(tester);

      final (Color?, Color) hovered = await whileHovering(
        tester,
        cardAt(2),
        () => (fillAt(tester, 2), sideAt(tester, 2).color),
      );
      // An outline card deliberately keeps a transparent fill in every state —
      // its border is the whole signal, and asserting the fill changed would be
      // asserting the opposite of the documented behaviour.
      expect(hovered.$1, colors.transparentBackground);
      expect(hovered.$2, colors.neutralStroke1Hover);
    });
  });

  group('selectable', () {
    final DocsSection section = sectionOf('components-card-card--selectable');

    testWidgets('a click selects one card and leaves the other alone', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = colorsOf(tester);
      final Color? resting = fillAt(tester, 0);

      // The page's primary knob, driven with a real mouse: the whole card
      // surface is the toggle, and a surface that only responds to a synthetic
      // tap is a card nobody can select in a browser.
      await mouseClick(tester, cardAt(0));
      expect(card(tester, 0).selected, isTrue);
      expect(
        fillAt(tester, 0),
        colors.neutralBackground1Selected,
        reason: 'selection must reach the painted fill, not just the field',
      );
      expect(card(tester, 1).selected, isFalse);
      expect(fillAt(tester, 1), resting);

      await tapAndSettle(tester, cardAt(0), what: 'the first selectable card');
      expect(card(tester, 0).selected, isFalse);
      expect(fillAt(tester, 0), resting);
    });

    testWidgets('the overflow button does not select the card', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder more = find.byWidgetPredicate(
        (Widget w) => w is FluentButton && w.semanticLabel == 'More actions',
      );

      // A button inside a clickable card must win the gesture arena outright.
      // If the card also fires, every menu press silently toggles selection —
      // the classic nested-tap defect, invisible until someone selects a card
      // they only meant to open a menu on.
      await tapAndSettle(tester, more.first, what: 'the overflow button');
      expect(card(tester, 0).selected, isFalse);

      // The control for the assertion above: the same card, pressed anywhere
      // else, does select. Without it a tap that missed the tree entirely would
      // look exactly like a button that correctly swallowed it.
      await tapAndSettle(tester, cardAt(0), what: 'the card surface');
      expect(card(tester, 0).selected, isTrue);
    });
  });

  group('selectable indicator', () {
    final DocsSection section = sectionOf(
      'components-card-card--selectable-indicator',
    );

    testWidgets('the floating checkbox and the card surface share one state', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder boxes = find.byType(FluentCheckbox);
      expect(boxes, findsNWidgets(4));

      // The checkbox is composed over the card rather than owned by it, so the
      // two can drift apart in either direction. Both directions are driven
      // here: box first, then surface.
      await mouseClick(tester, boxes.at(0));
      expect(tester.widget<FluentCheckbox>(boxes.at(0)).checked, isTrue);
      expect(
        card(tester, 0).selected,
        isTrue,
        reason: "the checkbox must select the card it labels",
      );
      expect(card(tester, 1).selected, isFalse);
      expect(tester.widget<FluentCheckbox>(boxes.at(1)).checked, isFalse);

      await tapAndSettle(tester, cardAt(0), what: 'the first card surface');
      expect(card(tester, 0).selected, isFalse);
      expect(
        tester.widget<FluentCheckbox>(boxes.at(0)).checked,
        isFalse,
        reason: 'clicking the card must move its indicator too',
      );
    });

    testWidgets('the document cards select independently', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder boxes = find.byType(FluentCheckbox);

      await tapAndSettle(tester, boxes.at(2), what: 'the third checkbox');
      expect(card(tester, 2).selected, isTrue);
      for (final int other in <int>[0, 1, 3]) {
        expect(
          card(tester, other).selected,
          isFalse,
          reason: 'card $other shares state with card 2',
        );
      }
    });
  });

  group('disabled', () {
    final DocsSection section = sectionOf('components-card-card--disabled');

    testWidgets('the disabled cards paint the disabled surface', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = colorsOf(tester);

      // Indices follow the four groups: default, interactive, selectable,
      // outline — with the disabled member of each pair second.
      for (final int index in <int>[1, 3, 5, 7]) {
        expect(card(tester, index).disabled, isTrue);
        expect(
          fillAt(tester, index),
          colors.neutralBackgroundDisabled,
          reason: 'card $index is disabled and must look it',
        );
      }
      expect(card(tester, 9).disabled, isTrue);
      expect(
        fillAt(tester, 9),
        colors.transparentBackground,
        reason: 'a disabled outline card keeps its transparent fill',
      );
      expect(sideAt(tester, 9).color, colors.neutralStrokeDisabled);
      expect(fillAt(tester, 0), colors.neutralBackground1);
    });

    testWidgets('a disabled card refuses the click its neighbour accepts', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Card 5 is disabled and still carries an `onPressed`, which is the exact
      // shape a "disabled means null callback" implementation gets wrong: the
      // callback exists, and only the disabled flag stands between it and the
      // pointer.
      final String before = textSnapshot(tester);
      await mouseClick(tester, cardAt(5));
      expect(card(tester, 4).selected, isFalse);
      expect(textSnapshot(tester), before);

      await tapAndSettle(tester, cardAt(4), what: 'the selectable card');
      expect(
        card(tester, 4).selected,
        isTrue,
        reason: 'the enabled card in the same group must still toggle',
      );
    });

    testWidgets('a disabled card disables its own slot contents', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // A card does not propagate `disabled` into its slots — the page has to
      // disable the buttons itself, and upstream says so in the story text.
      // This is the assertion that keeps that comment honest.
      VoidCallback? replyIn(int index) => tester
          .widget<FluentButton>(
            find.descendant(
              of: cardAt(index),
              matching: find.widgetWithText(FluentButton, 'Reply'),
            ),
          )
          .onPressed;

      expect(replyIn(0), isNotNull);
      for (final int index in <int>[1, 3, 5, 7, 9]) {
        expect(replyIn(index), isNull, reason: 'card $index is disabled');
      }
      expect(
        tester
            .widget<FluentCheckbox>(find.byType(FluentCheckbox).last)
            .onChanged,
        isNull,
        reason: "the disabled card's floating checkbox must be disabled too",
      );
    });

    testWidgets('the floating checkbox drives its selectable card', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder boxes = find.byType(FluentCheckbox);

      await tapAndSettle(tester, boxes.first, what: 'the live checkbox');
      expect(card(tester, 6).selected, isTrue);
      expect(card(tester, 4).selected, isFalse);
    });
  });

  group('with action', () {
    final DocsSection section = sectionOf('components-card-card--with-action');
    const String opened = 'Opened Classroom Collaboration app';
    const String link = 'https://www.microsoft.com/';

    testWidgets('the surface, the link and the Open button each report', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text(opened), findsNothing);

      // Three affordances, driven in an order where each one has to CHANGE the
      // reported message. Firing them in any order that repeats a message would
      // pass on an affordance that did nothing at all, because the previous
      // one's report is still on screen.
      //
      // The body text, not the card's centre: the centre of this card is its
      // preview, and pressing the body proves the whole surface is the target
      // rather than one image.
      await tapAndSettle(
        tester,
        find.textContaining('Donut chocolate bar'),
        what: 'the card body',
      );
      expect(find.text(opened), findsOneWidget);

      // The second card's title is a link, and upstream's whole point is that
      // it is the keyboard-reachable twin of the card's own click handler.
      await tapAndSettle(
        tester,
        find.byType(FluentLink),
        what: 'the card title link',
      );
      expect(find.text(link), findsOneWidget);
      expect(find.text(opened), findsNothing);

      // The story pairs the root handler with a button that does the same
      // thing, so the button has to be provably reachable on its own — and
      // under a real mouse, since that is how it is reached.
      await mouseClick(tester, find.widgetWithText(FluentButton, 'Open'));
      expect(find.text(opened), findsOneWidget);
      expect(find.text(link), findsNothing);
    });

    testWidgets('a keyboard activates the focused card', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Upstream calls keyboard access the reason the story exists. Tab moves
      // onto the first card — cards come before their own contents in traversal
      // order — and Enter must fire the same handler the pointer does.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);

      expect(find.text(opened), findsOneWidget);
    });
  });

  group('focus mode', () {
    final DocsSection section = sectionOf('components-card-card--focus-mode');

    testWidgets('a card takes keyboard focus and raises a ring', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final FluentColors colors = colorsOf(tester);
      expect(sideAt(tester, 0).color, colors.transparentStrokeInteractive);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await settle(tester);
      // The ring is drawn INSIDE the card's own box, reusing the border slot,
      // so "focused" and "outlined" are the same pixel here: a card that took
      // focus without repainting would be indistinguishable from one that never
      // took focus at all.
      expect(sideAt(tester, 0).color, colors.strokeFocus2);
      expect(sideAt(tester, 0).width, FluentStroke.thick);
      expect(
        sideAt(tester, 1).color,
        colors.transparentStrokeInteractive,
        reason: 'only the focused card may draw a ring',
      );

      // The round trip is a pointer, not another Tab: Fluent's focus-visible is
      // keyboard-only, and a pointer press is what clears the flag. A ring that
      // survived the click would be on screen for a user who never touched a
      // key — the exact case `FluentInputModality` exists to prevent.
      await mouseClick(tester, cardAt(1));
      expect(
        sideAt(tester, 0).color,
        colors.transparentStrokeInteractive,
        reason: 'a pointer press must put the ring away',
      );
      expect(sideAt(tester, 1).color, colors.transparentStrokeInteractive);
    });

    testWidgets('every card in the story is focusable and actionable', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(find.byType(FluentCard), findsNWidgets(4));
      for (int i = 0; i < 4; i++) {
        expect(
          card(tester, i).onPressed,
          isNotNull,
          reason: 'card $i must be focusable, which needs a handler',
        );
      }
      // The pointer must NOT raise the ring: Fluent's focus-visible is
      // keyboard-only, and a mouse press that leaves a ring behind is the
      // defect `FluentInputModality` exists to prevent.
      await mouseClick(tester, cardAt(0));
      expect(
        sideAt(tester, 0).color,
        FluentTheme.of(
          tester.element(cardAt(0)),
        ).colors.transparentStrokeInteractive,
      );
    });
  });

  group('templates', () {
    final DocsSection section = sectionOf('components-card-card--templates');

    testWidgets('each task checkbox ticks on its own', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder boxes = find.byType(FluentCheckbox);
      expect(boxes, findsNWidgets(2));

      bool checked(int index) =>
          tester.widget<FluentCheckbox>(boxes.at(index)).checked ?? false;

      await mouseClick(tester, boxes.at(0));
      expect(checked(0), isTrue);
      expect(
        checked(1),
        isFalse,
        reason: 'the two tasks must not share one flag',
      );

      await tapAndSettle(tester, boxes.at(0), what: 'the first task');
      expect(checked(0), isFalse);
    });

    testWidgets('the template cards render their own chrome', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Five cards: the task card, the bare image card and three list rows.
      expect(find.byType(FluentCard), findsNWidgets(5));
      expect(find.byType(FluentBadge), findsNWidgets(3));
      expect(find.text('Team Budget'), findsOneWidget);
      expect(
        card(tester, 2).size,
        FluentCardSize.small,
        reason: 'the list rows are the small size',
      );
      // The bare preview card carries no slots at all, so it is the one card
      // that would silently render as an empty box if the preview slot broke.
      expect(
        find.descendant(of: cardAt(1), matching: find.byType(Image)),
        findsOneWidget,
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
