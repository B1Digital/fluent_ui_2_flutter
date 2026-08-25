import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Toolbar's page is fifteen sections of the same row of buttons, so almost
/// nothing here can be read off a widget's own fields: fluent_2 ships no toggle
/// button and no radio button, and every one of those sections builds its
/// checked state by re-resolving a `FluentButton`'s style with
/// `WidgetState.selected` folded in. The only honest answer to "is this button
/// on" is therefore the fill it painted, which is what most of these assert —
/// plus the three sections that are claims about padding, and the overlays.
void main() {
  const String page = 'components-toolbar';

  group('default', () {
    final DocsSection section = sectionOf('components-toolbar--default');

    testWidgets('the primary button reads apart from its subtle neighbours', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentToolbarDivider), findsOneWidget);

      final Color? primary = fillOfButton(
        tester,
        FluentIcons.font_increase_24_regular,
      );
      final Color? subtle = fillOfButton(
        tester,
        FluentIcons.font_decrease_24_regular,
      );
      expect(
        primary,
        isNot(subtle),
        reason: 'appearance has to reach the paint, not only the constructor',
      );
      expect(
        fillOfButton(tester, FluentIcons.text_font_24_regular),
        subtle,
        reason: 'the two subtle buttons resolve the same rest fill',
      );
    });

    testWidgets('the trailing menu opens under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('New Window'), findsNothing);

      await mouseClick(
        tester,
        find.byIcon(FluentIcons.more_horizontal_24_filled),
      );
      expect(
        find.text('New Window'),
        findsOneWidget,
        reason: 'a mouse press on the trigger must raise the menu',
      );
      expect(find.text('Open Folder'), findsOneWidget);

      await dismissOverlay(tester);
      expect(find.text('New Window'), findsNothing);
    });
  });

  group('sizes', () {
    testWidgets(
      'the three sizes inset their items by three different amounts',
      (WidgetTester tester) async {
        final List<Offset> insets = <Offset>[
          for (final String id in <String>[
            'components-toolbar--small',
            'components-toolbar--medium',
            'components-toolbar--large',
          ])
            await itemInset(tester, sectionOf(id)),
        ];

        // Upstream states the horizontal ramp in the section descriptions
        // themselves: 4px small, 8px medium, 20px large. The 2px border every
        // one of the three sections draws is common to all of them, so the
        // differences are the padding and nothing else.
        expect(
          insets[1].dx - insets[0].dx,
          closeTo(4, 0.5),
          reason: 'medium is 8px horizontal against small\'s 4: $insets',
        );
        expect(
          insets[2].dx - insets[1].dx,
          closeTo(12, 0.5),
          reason: 'large is 20px horizontal against medium\'s 8: $insets',
        );

        // Vertically the ramp is 0 / 4 / 8. Asserted as a strict order rather
        // than three numbers: `buildFluentToolbar` takes Figma's ramp, which
        // gives large 8 where upstream's prose says 4.
        expect(insets[0].dy, lessThan(insets[1].dy));
        expect(insets[1].dy, lessThan(insets[2].dy));
      },
    );
  });

  group('overflow items', () {
    final DocsSection section = sectionOf('components-toolbar--overflow-items');

    testWidgets('every command is on the strip and in the More items menu', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // FluentToolbar models no overflow, so this section keeps all eleven
      // buttons visible and repeats them in the menu — recorded as `reduced`.
      // The claim worth testing is that nothing was dropped on either side.
      expect(find.byType(FluentToolbarDivider), findsNWidgets(2));
      expect(find.text('Increase Font Size'), findsNothing);

      await mouseClick(
        tester,
        find.byIcon(FluentIcons.more_horizontal_20_filled),
      );
      expect(
        find.text('Increase Font Size'),
        findsNWidgets(4),
        reason: "upstream's three groups carry four increases between them",
      );
      expect(find.text('Reset Font Size'), findsNWidgets(2));
    });
  });

  group('with tooltip', () {
    final DocsSection section = sectionOf('components-toolbar--with-tooltip');

    testWidgets('resting on a button raises its tooltip', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(120));
      expect(find.text('Makes selected text Bold'), findsNothing);

      // The pointer is parked rather than clicked: a tooltip is a 250ms hover
      // affordance and `tester.tap` synthesises no hover at all, so this is the
      // one gesture that can reach it.
      final TestGesture mouse = await mouseHover(
        tester,
        buttonFor(FluentIcons.text_bold_20_regular),
      );
      expect(
        find.text('Makes selected text Bold'),
        findsWidgets,
        reason: 'the tooltip must be up while the pointer rests on the button',
      );
      await mouseAway(tester, mouse);
      expect(find.text('Makes selected text Bold'), findsNothing);
    });

    testWidgets('the toggles under the tooltips still latch', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(120));
      final Color? off = fillOfButton(tester, FluentIcons.text_bold_20_regular);

      await mouseClick(tester, buttonFor(FluentIcons.text_bold_20_regular));
      expect(
        fillOfButton(tester, FluentIcons.text_bold_20_regular),
        isNot(off),
        reason:
            'a checked toggle re-resolves its own style with '
            'WidgetState.selected folded in',
      );
      expect(
        fillOfButton(tester, FluentIcons.text_italic_20_regular),
        off,
        reason: 'the neighbour in the same group is not a radio',
      );

      await tapAndSettle(
        tester,
        buttonFor(FluentIcons.text_bold_20_regular),
        what: 'Bold again',
      );
      expect(fillOfButton(tester, FluentIcons.text_bold_20_regular), off);
    });
  });

  group('with popover', () {
    final DocsSection section = sectionOf('components-toolbar--with-popover');

    testWidgets('each button opens its own surface and Close shuts it', (
      WidgetTester tester,
    ) async {
      // Inset, because a popover anchored above a toolbar sitting at y=0 lands
      // at a negative y, where it hit-tests to nothing and its Close button
      // cannot be pressed at all.
      await pumpSection(tester, section, inset: const EdgeInsets.all(200));
      expect(find.text('Insert Image'), findsNothing);

      await openOverlay(tester, buttonFor(FluentIcons.image_24_regular));
      expect(find.text('Insert Image'), findsOneWidget);
      expect(find.text('Insert Table'), findsNothing);

      await tapAndSettle(tester, find.text('Close'), what: 'the popover Close');
      expect(
        find.text('Insert Image'),
        findsNothing,
        reason: 'Close writes null back into the demo\'s own open state',
      );

      await openOverlay(tester, buttonFor(FluentIcons.table_24_filled));
      expect(find.text('Insert Table'), findsOneWidget);
      expect(
        find.text('Insert Image'),
        findsNothing,
        reason: 'the four popovers share one state: only one is ever open',
      );
    });

    testWidgets('the fourth trigger is a labelled button, not an icon', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(200));

      await openOverlay(tester, find.text('Quick Actions').first);
      expect(
        find.text('Quick Actions'),
        findsNWidgets(2),
        reason: 'the trigger keeps its label while the surface repeats it',
      );
      await tapAndSettle(tester, find.text('Close'), what: 'the popover Close');
      expect(find.text('Quick Actions'), findsOneWidget);
    });
  });

  group('subtle and transparent toggles', () {
    testWidgets('a subtle toggle latches with a fill and a foreground', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-toolbar--subtle'));
      final Color? offFill = fillOfButton(
        tester,
        FluentIcons.text_italic_24_regular,
      );
      final Color? offGlyph = glyphColour(
        tester,
        FluentIcons.text_italic_24_regular,
      );

      await mouseClick(tester, buttonFor(FluentIcons.text_italic_24_regular));
      expect(
        fillOfButton(tester, FluentIcons.text_italic_24_regular),
        isNot(offFill),
      );
      expect(
        glyphColour(tester, FluentIcons.text_italic_24_regular),
        isNot(offGlyph),
      );
      expect(
        fillOfButton(tester, FluentIcons.text_bold_24_regular),
        offFill,
        reason: 'a toggle group is not a radio group',
      );

      await tapAndSettle(
        tester,
        buttonFor(FluentIcons.text_italic_24_regular),
        what: 'Italic again',
      );
      expect(fillOfButton(tester, FluentIcons.text_italic_24_regular), offFill);
      expect(glyphColour(tester, FluentIcons.text_italic_24_regular), offGlyph);
    });

    testWidgets('a transparent toggle latches on its foreground alone', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-toolbar--transparent'));
      final Color? offGlyph = glyphColour(
        tester,
        FluentIcons.text_italic_24_regular,
      );

      await mouseClick(tester, buttonFor(FluentIcons.text_italic_24_regular));
      expect(
        glyphColour(tester, FluentIcons.text_italic_24_regular),
        isNot(offGlyph),
        reason: 'a checked transparent button has to read as checked somehow',
      );
      // And deliberately not on a fill: every stop of Fluent's transparent
      // background family, `colorTransparentBackgroundSelected` included, is
      // literally transparent — upstream too — so demanding a fill here would
      // be demanding a token the design system does not define.
      expect(
        fillOfButton(tester, FluentIcons.text_italic_24_regular)?.a ?? 0,
        0,
      );

      await tapAndSettle(
        tester,
        buttonFor(FluentIcons.text_italic_24_regular),
        what: 'Italic again',
      );
      expect(glyphColour(tester, FluentIcons.text_italic_24_regular), offGlyph);
    });
  });

  group('controlled toggle button', () {
    final DocsSection section = sectionOf(
      'components-toolbar--controlled-toggle-button',
    );

    testWidgets('the seeded pair starts checked and unlatches', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Upstream seeds `checkedValues` with bold and italic, so two of the
      // three buttons have to be painted on before anything is clicked.
      final Color? rest = fillOfButton(
        tester,
        FluentIcons.text_underline_24_regular,
      );
      expect(
        fillOfButton(tester, FluentIcons.text_bold_24_regular),
        isNot(rest),
      );
      expect(
        fillOfButton(tester, FluentIcons.text_italic_24_regular),
        isNot(rest),
      );

      await mouseClick(tester, buttonFor(FluentIcons.text_bold_24_regular));
      expect(
        fillOfButton(tester, FluentIcons.text_bold_24_regular),
        rest,
        reason: 'the round trip through setState has to clear the fill',
      );
      expect(
        fillOfButton(tester, FluentIcons.text_italic_24_regular),
        isNot(rest),
        reason: 'italic was never touched',
      );
    });
  });

  group('radio', () {
    testWidgets('a radio group moves its check instead of adding one', (
      WidgetTester tester,
    ) async {
      for (final String id in <String>[
        'components-toolbar--radio',
        'components-toolbar--controlled-radio',
      ]) {
        await pumpSection(tester, sectionOf(id));

        final Color? rest = fillOfButton(
          tester,
          FluentIcons.align_left_24_regular,
        );
        final Color? checked = fillOfButton(
          tester,
          FluentIcons.align_center_horizontal_24_regular,
        );
        expect(
          checked,
          isNot(rest),
          reason: '$id: the demo seeds textOptions with center',
        );

        await mouseClick(tester, buttonFor(FluentIcons.align_left_24_regular));
        expect(
          fillOfButton(tester, FluentIcons.align_left_24_regular),
          checked,
        );
        expect(
          fillOfButton(tester, FluentIcons.align_center_horizontal_24_regular),
          rest,
          reason: '$id: single select is the whole difference from a toggle',
        );

        await tapAndSettle(
          tester,
          buttonFor(FluentIcons.align_right_24_regular),
          what: '$id Align Right',
        );
        expect(
          fillOfButton(tester, FluentIcons.align_right_24_regular),
          checked,
        );
        expect(fillOfButton(tester, FluentIcons.align_left_24_regular), rest);
        await expectCleanTeardown(tester, id);
      }
    });
  });

  group('vertical', () {
    final DocsSection section = sectionOf('components-toolbar--vertical');

    testWidgets('the three buttons stack and each still latches', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // FluentToolbar has no vertical axis, so this section is a Semantics
      // labelled Column of the same buttons — which is exactly why the layout
      // has to be asserted here rather than taken on trust from a `size` prop.
      expect(find.byType(FluentToolbar), findsNothing);
      final Rect bold = tester.getRect(
        buttonFor(FluentIcons.text_bold_24_regular),
      );
      final Rect italic = tester.getRect(
        buttonFor(FluentIcons.text_italic_24_regular),
      );
      final Rect underline = tester.getRect(
        buttonFor(FluentIcons.text_underline_24_regular),
      );
      expect(italic.top, greaterThanOrEqualTo(bold.bottom));
      expect(underline.top, greaterThanOrEqualTo(italic.bottom));
      expect(italic.left, closeTo(bold.left, 0.5));

      final Color? rest = fillOfButton(
        tester,
        FluentIcons.text_underline_24_regular,
      );
      await mouseClick(
        tester,
        buttonFor(FluentIcons.text_underline_24_regular),
      );
      expect(
        fillOfButton(tester, FluentIcons.text_underline_24_regular),
        isNot(rest),
      );
      expect(fillOfButton(tester, FluentIcons.text_bold_24_regular), rest);
    });
  });

  group('vertical button', () {
    final DocsSection section = sectionOf(
      'components-toolbar--vertical-button',
    );

    testWidgets('each button stacks its glyph over its label', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentToolbar), findsOneWidget);

      final Finder increase = buttonFor(FluentIcons.font_increase_20_regular);
      final Rect glyph = tester.getRect(
        find.descendant(
          of: increase,
          matching: find.byIcon(FluentIcons.font_increase_20_regular),
        ),
      );
      final Rect label = tester.getRect(
        find.descendant(of: increase, matching: find.text('Increase')),
      );
      expect(
        glyph.bottom,
        lessThanOrEqualTo(label.top),
        reason:
            'FluentButton.iconPosition is before/after only, so the '
            'vertical button is built as a stacked label',
      );
      expect(glyph.center.dx, closeTo(label.center.dx, 1));

      // Still one row of three: the stacking is inside each button.
      expect(
        tester.getRect(buttonFor(FluentIcons.text_font_20_regular)).left,
        greaterThan(tester.getRect(increase).right - 1),
      );

      // The stacked glyph reads the button's own resolved foreground, so the
      // primary button's icon must not come out the same colour as a subtle
      // one's — that is the whole reason `_stacked` resolves a style at all.
      expect(
        tester
            .widget<Icon>(find.byIcon(FluentIcons.font_increase_20_regular))
            .color,
        isNot(
          tester
              .widget<Icon>(find.byIcon(FluentIcons.text_font_20_regular))
              .color,
        ),
      );
    });
  });

  group('far group', () {
    final DocsSection section = sectionOf('components-toolbar--far-group');

    testWidgets('the two groups are pushed to opposite ends', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentToolbar), findsNWidgets(2));

      final Rect near = tester.getRect(find.byType(FluentToolbar).at(0));
      final Rect far = tester.getRect(find.byType(FluentToolbar).at(1));
      expect(
        far.left - near.right,
        greaterThan(100),
        reason:
            'FluentToolbar hugs its content, so the spread belongs to the '
            'Row that holds the two of them',
      );
      expect(
        find.byType(FluentToolbarDivider),
        findsOneWidget,
        reason: 'only the near group carries a divider',
      );
      expect(
        far.right,
        closeTo(tester.getRect(find.byType(Row).first).right, 1),
        reason: 'the far group has to reach the trailing edge',
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

/// The [FluentButton] drawing [icon].
///
/// Every toolbar demo builds its buttons from `FluentButton.icon` with a
/// `semanticLabel` and no text, so the glyph is the only thing that tells one
/// button from another without turning the semantics tree on.
Finder buttonFor(IconData icon) => find
    .ancestor(of: find.byIcon(icon), matching: find.byType(FluentButton))
    .first;

/// The fill the button drawing [icon] actually painted.
///
/// fluent_2 ships no toggle button: a checked one is a `FluentButton` whose own
/// style has been re-resolved with `WidgetState.selected` folded in. So there is
/// no `checked` field to read anywhere on this page, and the painted fill is the
/// only place a latched button differs from a resting one.
Color? fillOfButton(WidgetTester tester, IconData icon) =>
    decorationUnder(tester, buttonFor(icon)).color;

/// Mounts [section] and measures how far its first item sits inside the toolbar.
///
/// The `Size` axis on a toolbar changes exactly one thing — the padding — so the
/// gap between the surface's own edge and its first button is the whole of what
/// the small, medium and large sections are demonstrating.
Future<Offset> itemInset(WidgetTester tester, DocsSection section) async {
  await pumpSection(tester, section);
  final Rect surface = tester.getRect(find.byType(FluentToolbar));
  final Rect first = tester.getRect(
    buttonFor(FluentIcons.font_increase_24_regular),
  );
  final Offset inset = Offset(
    first.left - surface.left,
    first.top - surface.top,
  );
  await expectCleanTeardown(tester, section.id);
  return inset;
}

/// The colour the glyph of the button drawing [icon] actually painted.
///
/// An [Icon] paints as a one-character paragraph, so its resolved colour is
/// readable exactly where a label's is. On the transparent appearance this is
/// the *only* place a checked button differs from a resting one: every stop of
/// Fluent's transparent background family resolves to transparent.
Color? glyphColour(WidgetTester tester, IconData icon) => textStyleOf(
  tester,
  // Down to the paragraph itself: an `Icon` wraps its glyph in Semantics, so
  // the first render object under the icon finder is an annotation, not the
  // text.
  find.descendant(of: find.byIcon(icon), matching: find.byType(RichText)),
)?.color;
