import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// InteractionTag is a tag that is also a control, and everything worth testing
/// here follows from that one sentence: the surface has to move under a
/// pointer where `FluentTag`'s holds still, the two halves have to light
/// independently, and a null `onPressed` has to stop both of them. The Dismiss
/// and Has Primary Action sections are the two that actually *do* something,
/// so they get driven with a real mouse rather than a synthetic tap.
void main() {
  const String page = 'components-tag-interactiontag';

  group('default', () {
    final DocsSection section = sectionOf(
      'components-tag-interactiontag--default',
    );

    testWidgets('the surface lights under a real mouse and settles back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder tag = find.byType(FluentInteractionTag);
      final FluentThemeData theme = FluentTheme.of(tester.element(tag));
      expect(fillOf(tester, tag)!.color, theme.colors.neutralBackground3);

      final Color hovered = await whileHovering(
        tester,
        tag,
        () => fillOf(tester, tag)!.color!,
      );
      expect(
        hovered,
        theme.colors.neutralBackground3Hover,
        reason:
            'this is the whole difference from FluentTag: an interaction tag '
            'reports the pointer',
      );
      // The pointer is gone by the time whileHovering returns, so this is the
      // round trip — a hover that never cleared would leave the page looking
      // permanently pressed.
      expect(fillOf(tester, tag)!.color, theme.colors.neutralBackground3);
    });

    testWidgets('the surface takes the pressed token while held', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder tag = find.byType(FluentInteractionTag);
      final FluentThemeData theme = FluentTheme.of(tester.element(tag));

      final TestGesture press = await tester.startGesture(
        tester.getCenter(tag),
      );
      await settle(tester);
      expect(
        fillOf(tester, tag)!.color,
        theme.colors.neutralBackground3Pressed,
      );

      await press.up();
      await settle(tester);
      expect(fillOf(tester, tag)!.color, theme.colors.neutralBackground3);
      expectClean(tester, 'pressing the tag');
    });
  });

  group('content slots', () {
    testWidgets('the icon leads the label', (WidgetTester tester) async {
      await pumpSection(
        tester,
        sectionOf('components-tag-interactiontag--icon'),
      );

      expect(
        tester.getRect(find.byType(Icon)).right,
        lessThanOrEqualTo(tester.getRect(find.text('Primary text')).left),
      );
    });

    testWidgets('the media slot renders the avatar, initials and all', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-tag-interactiontag--media'),
      );

      expect(find.byType(FluentAvatar), findsOneWidget);
      expect(find.text('KA'), findsOneWidget);
      expect(
        tester.getRect(find.byType(FluentAvatar)).right,
        lessThanOrEqualTo(tester.getRect(find.text('Primary text')).left),
      );
    });

    testWidgets('the second line stacks under the first on a smaller ramp', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-tag-interactiontag--secondary-text'),
      );

      final Rect primary = tester.getRect(find.text('Primary text'));
      final Rect secondary = tester.getRect(find.text('Secondary text'));
      expect(secondary.top, greaterThanOrEqualTo(primary.bottom));
      expect(secondary.left, primary.left);
      expect(secondary.height, lessThan(primary.height));
    });
  });

  group('dismiss', () {
    final DocsSection section = sectionOf(
      'components-tag-interactiontag--dismiss',
    );

    testWidgets('each dismiss half removes its own tag, and reset restores', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentInteractionTag), findsNWidgets(3));

      final Finder reset = find.widgetWithText(
        FluentButton,
        'Reset the example',
      );
      expect(tester.widget<FluentButton>(reset).onPressed, isNull);

      // The middle tag: an `onDismiss` closing over a stale index removes a
      // neighbour instead, and dismissing from the top would never notice.
      await tapAndSettle(
        tester,
        find.byType(FluentTagDismissGlyph).at(1),
        what: "Tag 2's dismiss half",
      );
      expect(find.text('Tag 2'), findsNothing);
      expect(find.text('Tag 1'), findsOneWidget);
      expect(find.text('Tag 3'), findsOneWidget);

      await tapAndSettle(tester, find.byType(FluentTagDismissGlyph).first);
      await tapAndSettle(tester, find.byType(FluentTagDismissGlyph).first);
      expect(find.byType(FluentInteractionTag), findsNothing);
      expect(tester.widget<FluentButton>(reset).onPressed, isNotNull);

      await tapAndSettle(tester, reset, what: 'the reset button');
      expect(find.byType(FluentInteractionTag), findsNWidgets(3));
      expect(find.text('Tag 2'), findsOneWidget);
    });

    testWidgets('a real mouse press on the dismiss half removes that tag', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.byType(FluentTagDismissGlyph).first);
      expect(
        find.text('Tag 1'),
        findsNothing,
        reason: 'the dismiss half took a synthetic tap but not a real click',
      );
      expect(find.byType(FluentInteractionTag), findsNWidgets(2));
    });

    testWidgets('hovering one half leaves the other alone', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder tag = find.widgetWithText(FluentInteractionTag, 'Tag 1');
      final FluentThemeData theme = FluentTheme.of(tester.element(tag));
      final Color rest = theme.colors.neutralBackground3;
      expect(_halfFills(tester, tag), <Color>[rest, rest]);

      final List<Color> hovered = await whileHovering(
        tester,
        find.descendant(of: tag, matching: find.byType(FluentTagDismissGlyph)),
        () => _halfFills(tester, tag),
      );
      // The independence is the point: each half owns its interaction state,
      // which is why they are two FluentInteractives rather than one surface.
      expect(hovered, <Color>[rest, theme.colors.neutralBackground3Hover]);
    });
  });

  group('shape', () {
    testWidgets(
      'circular rounds the ends, and only the dismissible row splits',
      (WidgetTester tester) async {
        await pumpSection(
          tester,
          sectionOf('components-tag-interactiontag--shape'),
        );

        // Row one has no dismiss half, so its primary keeps all four corners.
        expect(
          fillOf(
            tester,
            find.widgetWithText(FluentInteractionTag, 'Rounded').first,
          )!.borderRadius,
          FluentRadius.allMedium,
        );
        expect(
          fillOf(
            tester,
            find.widgetWithText(FluentInteractionTag, 'Circular').first,
          )!.borderRadius,
          FluentRadius.allCircular,
        );

        // Row two does, so its primary half squares off the edge the seam runs
        // down and keeps its rounding on the leading edge only.
        final BorderRadius split =
            fillOf(
                  tester,
                  find.widgetWithText(FluentInteractionTag, 'Circular').at(1),
                )!.borderRadius!
                as BorderRadius;
        expect(split.topLeft, FluentRadius.circular);
        expect(split.topRight, Radius.zero);
        expect(split.bottomRight, Radius.zero);
      },
    );
  });

  group('size', () {
    testWidgets('each row renders its documented height and dismiss box', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-tag-interactiontag--size'),
      );

      // Figma's ramp: 32 / 24 / 20 tall, with a 20 / 16 / 12 glyph, and a
      // dismiss half that is 32 / 24 / 24 wide — the extra-small half is the
      // one that does not shrink with its row.
      for (final (String label, double height, double glyph, double half)
          in <(String, double, double, double)>[
            ('Medium', 32, 20, 32),
            ('Small', 24, 16, 24),
            ('Extra small', 20, 12, 24),
          ]) {
        expect(
          tester
              .getSize(find.widgetWithText(FluentInteractionTag, label))
              .height,
          height,
          reason: '$label tag',
        );

        final Finder dismissible = find.widgetWithText(
          FluentInteractionTag,
          '$label dismissible',
        );
        final Finder mark = find.descendant(
          of: dismissible,
          matching: find.byType(FluentTagDismissGlyph),
        );
        expect(tester.getSize(dismissible).height, height);
        expect(tester.getSize(mark).height, glyph, reason: '$label glyph');
        expect(
          tester
              .getSize(
                find
                    .ancestor(of: mark, matching: find.byType(DecoratedBox))
                    .first,
              )
              .width,
          half,
          reason: '$label dismiss half',
        );
      }
    });
  });

  group('appearance', () {
    testWidgets('filled, outline and brand each paint their own surface', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-tag-interactiontag--appearance'),
      );

      final Finder filled = find.widgetWithText(FluentInteractionTag, 'filled');
      final FluentThemeData theme = FluentTheme.of(tester.element(filled));
      final BoxDecoration filledBox = fillOf(tester, filled)!;
      final BoxDecoration outlineBox = fillOf(
        tester,
        find.widgetWithText(FluentInteractionTag, 'outline'),
      )!;
      final BoxDecoration brandBox = fillOf(
        tester,
        find.widgetWithText(FluentInteractionTag, 'brand'),
      )!;

      expect(filledBox.color, theme.colors.neutralBackground3);
      expect(brandBox.color, theme.colors.brandBackground2);
      // Outline's fill is the subtle ramp — transparent at rest, but a real
      // token, so it can still light on hover where the inert tag's cannot.
      expect(outlineBox.color, theme.colors.subtleBackground);
      expect(_borderColor(outlineBox), theme.colors.neutralStroke1);
      expect(
        _borderColor(filledBox),
        theme.colors.transparentStrokeInteractive,
      );
      expect(_borderColor(brandBox), theme.colors.transparentStrokeInteractive);
    });
  });

  group('disabled', () {
    testWidgets('a null onPressed greys the tag and stops it responding', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-tag-interactiontag--disabled'),
      );

      final Finder filled = find.widgetWithText(
        FluentInteractionTag,
        'appearance=filled',
      );
      final FluentThemeData theme = FluentTheme.of(tester.element(filled));
      expect(
        fillOf(tester, filled)!.color,
        theme.colors.neutralBackgroundDisabled,
      );
      for (final FluentTagDismissPainter glyph
          in paintersOf<FluentTagDismissPainter>(tester)) {
        expect(glyph.color, theme.colors.neutralForegroundDisabled);
      }

      // Disabled has to beat hover, not merely paint grey at rest: the surface
      // must not move under a pointer that a live tag would light.
      final Color hovered = await whileHovering(
        tester,
        filled,
        () => fillOf(tester, filled)!.color!,
      );
      expect(hovered, theme.colors.neutralBackgroundDisabled);
    });
  });

  group('has primary action', () {
    // The surface opens ABOVE its trigger, so the demo is padded away from the
    // top of the viewport: a popover at a negative y hit-tests to nothing and
    // its link could not be clicked at all.
    final DocsSection section = sectionOf(
      'components-tag-interactiontag--has-primary-action',
    );

    testWidgets('the tag opens its popover under a real mouse, and closes', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(400));
      expect(find.text('Find out more on wiki'), findsNothing);

      await mouseClick(tester, find.text('Golden retriever'));
      expect(
        find.text('Find out more on wiki'),
        findsOneWidget,
        reason: 'the primary half must open the popover it is the trigger for',
      );
      expect(find.textContaining('Luxurious double coat'), findsOneWidget);

      await mouseClick(tester, find.text('Golden retriever'));
      expect(find.text('Find out more on wiki'), findsNothing);
    });

    testWidgets('the surface is clickable, not just a dismiss barrier', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(400));
      await tapAndSettle(tester, find.text('Golden retriever'));

      // The popover lays an invisible full-screen dismiss barrier under its
      // surface. If the surface ever landed below that barrier, every control
      // inside it would close the popover instead of firing — so the link
      // staying put is what proves the content is reachable.
      await mouseClick(tester, find.text('Find out more on wiki'));
      expect(find.text('Find out more on wiki'), findsOneWidget);
    });
  });

  group('selected', () {
    testWidgets('selected erases all three appearances into the brand fill', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-tag-interactiontag--selected'),
      );

      final FluentThemeData theme = FluentTheme.of(
        tester.element(find.byType(FluentInteractionTag).first),
      );
      for (final String appearance in <String>[
        'appearance=filled',
        'appearance=outline',
        'appearance=brand',
      ]) {
        expect(
          fillOf(
            tester,
            find.widgetWithText(FluentInteractionTag, appearance),
          )!.color,
          theme.colors.brandBackground,
          reason: 'selected must beat $appearance',
        );
      }
      for (final FluentTagDismissPainter glyph
          in paintersOf<FluentTagDismissPainter>(tester)) {
        expect(glyph.color, theme.colors.neutralForegroundOnBrand);
      }
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

/// Every filled surface under [tag], in tree order: the primary half, then the
/// dismiss half when there is one.
///
/// The two halves resolve the same colour ramp against interaction states of
/// their own, so reading only the first would call an independent pair a
/// single surface.
List<Color> _halfFills(WidgetTester tester, Finder tag) => tester
    .widgetList<DecoratedBox>(
      find.descendant(of: tag, matching: find.byType(DecoratedBox)),
    )
    .map((DecoratedBox box) => box.decoration)
    .whereType<BoxDecoration>()
    .map((BoxDecoration box) => box.color)
    .whereType<Color>()
    .toList();

/// The colour of [box]'s uniform border, which Fluent always paints on all four
/// sides even when the token is transparent.
Color _borderColor(BoxDecoration box) => (box.border! as Border).top.color;
