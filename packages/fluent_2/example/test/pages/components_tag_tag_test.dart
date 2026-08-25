import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Tag's page is nine static demos and one stateful one, because a `FluentTag`
/// is inert by design: it carries no knob, and its only interactive part is the
/// dismiss glyph. So two things are worth proving here. First, that the axis
/// each section is *named* after reaches the painted tag — a section titled
/// "Size" that renders three identical tags is the failure this page can have,
/// and only geometry and tokens can catch it. Second, that the Dismiss demo
/// removes what it says it removes and gives it all back.
void main() {
  const String page = 'components-tag-tag';

  group('default', () {
    testWidgets('renders one tag with nothing on it that can be pressed', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tag-tag--default'));

      expect(find.byType(FluentTag), findsOneWidget);
      expect(find.text('Primary text'), findsOneWidget);
      // No `onDismiss`, so no glyph. A stray affordance here would be the
      // component's whole premise — a tag labels, it does not act — going
      // missing.
      expect(find.byType(FluentTagDismissGlyph), findsNothing);
    });
  });

  group('content slots', () {
    testWidgets('the icon leads the label at the medium glyph size', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tag-tag--icon'));

      final Rect icon = tester.getRect(find.byType(Icon));
      expect(
        icon.right,
        lessThanOrEqualTo(tester.getRect(find.text('Primary text')).left),
      );
      // 20, the medium step of the glyph ramp. The icon takes its box from the
      // tag's IconTheme, so a size axis that stopped reaching it would show up
      // here and nowhere else.
      expect(icon.height, 20);
    });

    testWidgets('the media slot renders the avatar, initials and all', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tag-tag--media'));

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
        sectionOf('components-tag-tag--secondary-text'),
      );

      final Rect primary = tester.getRect(find.text('Primary text'));
      final Rect secondary = tester.getRect(find.text('Secondary text'));
      expect(secondary.top, greaterThanOrEqualTo(primary.bottom));
      expect(secondary.left, primary.left);
      // caption2 under caption1: a two-line medium tag drops its primary step
      // so the pair still fits, and the second line is smaller again. The
      // absolute heights are deliberately not asserted — `FluentApp` resolves
      // the mobile type ramp under the test binding's Android platform, where
      // the web ramp's 12/16 over 10/14 is 13/18 over 12/16.
      expect(secondary.height, lessThan(primary.height));
      // Exactly its two lines, with nothing padded on top: the tag is a fixed
      // 32 minimum and both lines have to fit inside the same box.
      expect(
        tester.getSize(find.byType(FluentTag)).height,
        primary.height + secondary.height,
      );
    });
  });

  group('dismiss', () {
    final DocsSection section = sectionOf('components-tag-tag--dismiss');

    testWidgets('each glyph removes its own tag and reset gives them back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentTag), findsNWidgets(3));

      final Finder reset = find.widgetWithText(
        FluentButton,
        'Reset the example',
      );
      // Disabled while anything is left to dismiss: the button is the focus
      // target this section's description is about, and it only becomes one
      // once the last tag is gone.
      expect(tester.widget<FluentButton>(reset).onPressed, isNull);

      // The middle one, not the first: an `onDismiss` closing over the wrong
      // index removes a neighbour, and dismissing from the top would never
      // notice.
      await tapAndSettle(
        tester,
        find.byType(FluentTagDismissGlyph).at(1),
        what: "Tag 2's dismiss glyph",
      );
      expect(find.text('Tag 2'), findsNothing);
      expect(find.text('Tag 1'), findsOneWidget);
      expect(find.text('Tag 3'), findsOneWidget);

      await tapAndSettle(tester, find.byType(FluentTagDismissGlyph).first);
      await tapAndSettle(tester, find.byType(FluentTagDismissGlyph).first);
      expect(find.byType(FluentTag), findsNothing);
      expect(tester.widget<FluentButton>(reset).onPressed, isNotNull);

      await tapAndSettle(tester, reset, what: 'the reset button');
      expect(find.byType(FluentTag), findsNWidgets(3));
      expect(find.text('Tag 2'), findsOneWidget);
    });

    testWidgets('a real mouse press dismisses', (WidgetTester tester) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.byType(FluentTagDismissGlyph).first);
      expect(
        find.text('Tag 1'),
        findsNothing,
        reason: 'the glyph took a synthetic tap but not a real click',
      );
      expect(find.byType(FluentTag), findsNWidgets(2));
    });

    testWidgets('the glyph is the one part that ramps under a pointer', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder tag = find.widgetWithText(FluentTag, 'Tag 1');
      final Finder glyph = find.descendant(
        of: tag,
        matching: find.byType(FluentTagDismissGlyph),
      );
      final FluentThemeData theme = FluentTheme.of(tester.element(tag));

      expect(_glyphColor(tester, glyph), theme.colors.neutralForeground2);
      final Color restingFill = fillOf(tester, tag)!.color!;

      final (Color, Color) hovered = await whileHovering(
        tester,
        glyph,
        () => (_glyphColor(tester, glyph), fillOf(tester, tag)!.color!),
      );
      expect(
        hovered.$1,
        theme.colors.neutralForeground2BrandHover,
        reason:
            "the glyph must take brand on hover — it is the whole of the "
            "Figma set's State axis",
      );
      expect(
        hovered.$2,
        restingFill,
        reason: 'a tag is inert: the surface must hold still under the pointer',
      );
    });
  });

  group('shape', () {
    testWidgets('only the styled tag goes circular, and it keeps its height', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tag-tag--shape'));

      // Two rows — plain, then dismissible — and the style has to reach both.
      for (int row = 0; row < 2; row++) {
        final Finder rounded = find
            .widgetWithText(FluentTag, 'Rounded')
            .at(row);
        final Finder circular = find
            .widgetWithText(FluentTag, 'Circular')
            .at(row);
        expect(fillOf(tester, rounded)!.borderRadius, FluentRadius.allMedium);
        expect(
          fillOf(tester, circular)!.borderRadius,
          FluentRadius.allCircular,
        );
        // Corner radius only: a `shape` that also moved the geometry would be
        // a different axis than the one this section claims.
        expect(tester.getSize(circular).height, tester.getSize(rounded).height);
      }
    });
  });

  group('size', () {
    testWidgets('each row renders its documented height and glyph ramp', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tag-tag--size'));

      // Figma's ramp, verbatim: 32 / 24 / 20 tall, with a 20 / 16 / 12 glyph.
      for (final (String label, double height, double glyph)
          in <(String, double, double)>[
            ('Medium', 32, 20),
            ('Small', 24, 16),
            ('Extra small', 20, 12),
          ]) {
        expect(
          tester.getSize(find.widgetWithText(FluentTag, label)).height,
          height,
          reason: '$label tag',
        );

        final Finder dismissible = find.widgetWithText(
          FluentTag,
          '$label dismissible',
        );
        expect(
          tester.getSize(dismissible).height,
          height,
          reason: 'the glyph must not grow the $label tag',
        );
        expect(
          tester
              .getSize(
                find.descendant(
                  of: dismissible,
                  matching: find.byType(FluentTagDismissGlyph),
                ),
              )
              .height,
          glyph,
          reason: '$label dismiss glyph',
        );
      }
    });
  });

  group('appearance', () {
    testWidgets('filled, outline and brand each paint their own surface', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tag-tag--appearance'));

      final Finder filled = find.widgetWithText(FluentTag, 'filled');
      final FluentThemeData theme = FluentTheme.of(tester.element(filled));
      final BoxDecoration filledBox = fillOf(tester, filled)!;
      final BoxDecoration outlineBox = fillOf(
        tester,
        find.widgetWithText(FluentTag, 'outline'),
      )!;
      final BoxDecoration brandBox = fillOf(
        tester,
        find.widgetWithText(FluentTag, 'brand'),
      )!;

      expect(filledBox.color, theme.colors.neutralBackground3);
      expect(brandBox.color, theme.colors.brandBackground2);
      // Outline paints no fill at all, in any state — the border is what names
      // it, and it is the only one of the three whose border is visible.
      expect(outlineBox.color, theme.colors.transparentBackground);
      expect(_borderColor(outlineBox), theme.colors.neutralStroke1);
      expect(_borderColor(filledBox), theme.colors.transparentStroke);
      expect(_borderColor(brandBox), theme.colors.transparentStroke);
    });
  });

  group('disabled', () {
    testWidgets('disabled greys the surface and every dismiss glyph', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tag-tag--disabled'));

      final Finder filled = find.widgetWithText(FluentTag, 'appearance=filled');
      final FluentThemeData theme = FluentTheme.of(tester.element(filled));
      expect(
        fillOf(tester, filled)!.color,
        theme.colors.neutralBackgroundDisabled,
      );

      // The glyph is drawn rather than imported, so the token it took is a
      // field on the painter rather than anything the widget tree records.
      final List<FluentTagDismissPainter> glyphs =
          paintersOf<FluentTagDismissPainter>(tester);
      expect(glyphs, hasLength(3));
      for (final FluentTagDismissPainter glyph in glyphs) {
        expect(glyph.color, theme.colors.neutralForegroundDisabled);
      }
    });
  });

  group('selected', () {
    testWidgets('selected erases all three appearances into the brand fill', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tag-tag--selected'));

      final FluentThemeData theme = FluentTheme.of(
        tester.element(find.byType(FluentTag).first),
      );
      for (final String appearance in <String>[
        'appearance=filled',
        'appearance=outline',
        'appearance=brand',
      ]) {
        expect(
          fillOf(tester, find.widgetWithText(FluentTag, appearance))!.color,
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

/// The tone the dismiss glyph under [glyph] is currently stroked in.
Color _glyphColor(WidgetTester tester, Finder glyph) =>
    paintersOf<FluentTagDismissPainter>(tester, glyph).single.color;

/// The colour of [box]'s uniform border, which Fluent always paints on all four
/// sides even when the token is transparent.
Color _borderColor(BoxDecoration box) => (box.border! as Border).top.color;
