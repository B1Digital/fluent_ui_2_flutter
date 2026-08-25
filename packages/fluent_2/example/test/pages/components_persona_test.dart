import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Persona's six sections are all layout claims — where the avatar sits, which
/// way the lines stack, how far apart they are, and which of the two components
/// a persona is composing at all. None of that is visible in the widget tree: a
/// persona whose `textPosition` never reached the Row still *has* a
/// `textPosition`, and a size axis that stopped ramping still renders six
/// personas. So every test below measures rects and reads resolved text styles.
///
/// The one section with a behavioural claim is Presence Previous Behavior,
/// which is really a claim about a subtree theme reaching a composed child —
/// and that only shows up in the glyph colour that was painted.
void main() {
  const String page = 'components-persona';

  /// The theme the mounted section is rendering against.
  FluentThemeData themeOf(WidgetTester tester) =>
      FluentTheme.of(tester.element(find.byType(FluentPersona).first));

  /// The badge's glyph colour, which is the status token itself.
  Color? badgeTone(WidgetTester tester, Finder badge) => tester
      .widget<Icon>(
        find.descendant(of: badge, matching: find.byType(Icon)).first,
      )
      .color;

  /// The glyph the badge chose for its status.
  IconData? badgeGlyph(WidgetTester tester, Finder badge) => tester
      .widget<Icon>(
        find.descendant(of: badge, matching: find.byType(Icon)).first,
      )
      .icon;

  group('default', () {
    final DocsSection section = sectionOf('components-persona--default');

    testWidgets('the name, the second line, the photo and the badge', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(textSnapshot(tester), 'Kevin Sturgis␟Available');
      // The persona composes a real avatar and a real badge rather than drawing
      // its own: `status` with `presenceOnly` false has to become the avatar's
      // corner badge, not replace it.
      expect(find.byType(FluentAvatar), findsOneWidget);
      expect(find.byType(FluentPresenceBadge), findsOneWidget);
      expect(
        (fillOf(tester, find.byType(FluentAvatar))?.image?.image as AssetImage?)
            ?.assetName,
        'assets/storybook/persona-male.png',
      );

      final FluentColors colors = themeOf(tester).colors;
      final TextStyle? primary = textStyleOf(
        tester,
        find.text('Kevin Sturgis'),
      );
      final TextStyle? secondary = textStyleOf(tester, find.text('Available'));
      // Two lines, two ramps, two tones. Both lines landing on one style is what
      // a persona looks like when the DefaultTextStyle merge stops happening,
      // and it still reads as "a persona rendered".
      expect(primary!.fontSize, greaterThan(secondary!.fontSize!));
      expect(primary.color, colors.neutralForeground1);
      expect(secondary.color, colors.neutralForeground2);

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('a real mouse press leaves the persona exactly as it was', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final String before = textSnapshot(tester);
      final Color? fill = fillOf(tester, find.byType(FluentAvatar))?.color;

      // A persona is documented as non-interactive — no hover, no press, no
      // focus — because the row or button around it owns the interaction. Only
      // a real device can prove that: `tester.tap` sends no enter event, so a
      // persona that had grown a hover fill would pass a synthetic test.
      await mouseClick(tester, find.byType(FluentPersona));

      expect(textSnapshot(tester), before);
      expect(fillOf(tester, find.byType(FluentAvatar))?.color, fill);
    });
  });

  group('text alignment', () {
    testWidgets('start tops the avatar out and center centres it', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf(
        'components-persona--text-alignment',
      );
      await pumpSection(tester, section);

      final Finder personas = find.byType(FluentPersona);
      expect(personas, findsNWidgets(2));

      Rect avatarIn(int i) => tester.getRect(
        find.descendant(
          of: personas.at(i),
          matching: find.byType(FluentAvatar),
        ),
      );

      // Four lines of text make the block far taller than the 32 avatar, which
      // is the only reason the two alignments can be told apart at all. Start
      // pins the avatar to the top of the block; center hangs it in the middle.
      final Rect start = tester.getRect(personas.at(0));
      final Rect centre = tester.getRect(personas.at(1));
      expect(avatarIn(0).top, start.top);
      expect(avatarIn(1).center.dy, closeTo(centre.center.dy, 0.01));
      expect(
        avatarIn(1).top,
        greaterThan(centre.top),
        reason: 'a centred avatar cannot also be flush with the top',
      );

      await expectCleanTeardown(tester, section.id);
    });
  });

  group('text position', () {
    testWidgets('after, below and before each put the avatar somewhere else', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf(
        'components-persona--text-position',
      );
      await pumpSection(tester, section);

      final Finder personas = find.byType(FluentPersona);
      expect(personas, findsNWidgets(3));

      Rect avatarIn(int i) => tester.getRect(
        find.descendant(
          of: personas.at(i),
          matching: find.byType(FluentAvatar),
        ),
      );
      Rect nameIn(int i) => tester.getRect(
        find.descendant(
          of: personas.at(i),
          matching: find.text('Kevin Sturgis'),
        ),
      );

      // after: avatar leads, beside the text rather than above it. The avatar
      // centres on the whole two-line block, not on the name — so the honest
      // check is that it overlaps the name's band and centres on the persona.
      expect(avatarIn(0).right, lessThanOrEqualTo(nameIn(0).left));
      expect(avatarIn(0).top, lessThan(nameIn(0).bottom));
      expect(
        avatarIn(0).center.dy,
        closeTo(tester.getRect(personas.at(0)).center.dy, 0.01),
      );

      // below: the row becomes a column, and both halves centre on each other.
      expect(avatarIn(1).bottom, lessThanOrEqualTo(nameIn(1).top));
      expect(
        avatarIn(1).center.dx,
        closeTo(tester.getRect(personas.at(1)).center.dx, 0.01),
      );

      // before: the same row read the other way. This is the one that catches a
      // `reversed` that never ran — it would look exactly like `after`.
      expect(avatarIn(2).left, greaterThanOrEqualTo(nameIn(2).right));
      expect(avatarIn(2).top, lessThan(nameIn(2).bottom));
      expect(
        avatarIn(2).center.dy,
        closeTo(tester.getRect(personas.at(2)).center.dy, 0.01),
      );

      await expectCleanTeardown(tester, section.id);
    });
  });

  group('presence previous behavior', () {
    final DocsSection section = sectionOf(
      'components-persona--presence-previous-behavior',
    );

    testWidgets('the restyled column really does repaint its badge', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(find.text('Current Behavior'), findsOneWidget);
      expect(find.text('Previous Behavior'), findsOneWidget);

      final Finder badges = find.byType(FluentPresenceBadge);
      expect(badges, findsNWidgets(4));
      final FluentColors colors = themeOf(tester).colors;

      // Away out of office is berry today and was marigold before. The previous
      // column reaches that by picking the status that draws the old glyph and
      // restyling the tone through `FluentPresenceBadgeTheme` — so if the
      // subtree theme stopped reaching the composed badge, both columns would
      // paint the same and the section would be making no point at all.
      expect(badgeTone(tester, badges.at(0)), colors.statusOofForeground3);
      expect(badgeTone(tester, badges.at(2)), colors.statusAwayBackground3);
      expect(
        badgeTone(tester, badges.at(2)),
        isNot(badgeTone(tester, badges.at(0))),
      );

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the offline row is deliberately identical in both columns', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder badges = find.byType(FluentPresenceBadge);
      // The page's own claim: offline "needs no override at all". Same glyph,
      // same tone — and an override that leaked out of the away row above would
      // land here first.
      expect(badgeTone(tester, badges.at(3)), badgeTone(tester, badges.at(1)));
      expect(
        badgeGlyph(tester, badges.at(3)),
        badgeGlyph(tester, badges.at(1)),
      );
      expect(
        badgeTone(tester, badges.at(1)),
        themeOf(tester).colors.neutralForeground3,
      );
    });
  });

  group('presence size', () {
    final DocsSection section = sectionOf('components-persona--presence-size');

    testWidgets('presence only draws a badge and no avatar at all', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // `presenceOnly` REPLACES the avatar. A persona that drew both would look
      // plausible in a screenshot and be wrong in exactly the way this flag
      // exists to prevent.
      expect(find.byType(FluentAvatar), findsNothing);
      expect(find.byType(FluentPresenceBadge), findsNWidgets(6));
      expect(find.text('Kevin Sturgis'), findsNWidgets(6));

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the badge ramps with the size and stops where Figma does', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder badges = find.byType(FluentPresenceBadge);
      // The badge ramp runs out before the avatar ramp does, so extraLarge and
      // huge SHARE a badge. A ramp wired straight to the size index would give
      // six different values and pass a monotonic check.
      const List<double> ladder = <double>[6, 10, 12, 16, 20, 20];
      for (int i = 0; i < ladder.length; i++) {
        expect(
          tester.getSize(badges.at(i)),
          Size.square(ladder[i]),
          reason: 'badge $i is the wrong diameter',
        );
      }

      // The type ramp moves on the same axis: the last two steps take subtitle2
      // where the first four take body1.
      final Finder names = find.text('Kevin Sturgis');
      expect(
        textStyleOf(tester, names.at(5))!.fontSize,
        greaterThan(textStyleOf(tester, names.at(0))!.fontSize!),
      );
    });
  });

  group('avatar size', () {
    final DocsSection section = sectionOf('components-persona--avatar-size');

    testWidgets('the composed avatar ramps and carries its own badge table', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder avatars = find.byType(FluentAvatar);
      expect(avatars, findsNWidgets(6));

      // Persona's size axis only *chooses* a FluentAvatarSize — 20, 28, 32, 36,
      // 40, 56 — and the avatar's own table then picks the badge. Asserting both
      // is what proves the choice was handed to the real component rather than
      // reimplemented next to it.
      const List<double> avatarLadder = <double>[20, 28, 32, 36, 40, 56];
      const List<double> badgeLadder = <double>[6, 10, 10, 10, 12, 16];
      for (int i = 0; i < avatarLadder.length; i++) {
        expect(
          tester.getSize(avatars.at(i)),
          Size.square(avatarLadder[i]),
          reason: 'avatar $i is the wrong edge',
        );
        expect(
          tester
              .getSize(
                find.descendant(
                  of: avatars.at(i),
                  matching: find.byType(FluentPresenceBadge),
                ),
              )
              .width,
          badgeLadder[i],
          reason: 'the badge on avatar $i is the wrong diameter',
        );
      }

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the gap between avatar and text grows with the size', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder personas = find.byType(FluentPersona);
      double gapIn(int i) {
        final Rect avatar = tester.getRect(
          find.descendant(
            of: personas.at(i),
            matching: find.byType(FluentAvatar),
          ),
        );
        return tester
                .getRect(
                  find.descendant(
                    of: personas.at(i),
                    matching: find.text('Kevin Sturgis'),
                  ),
                )
                .left -
            avatar.right;
      }

      // The size axis drives the Row's spacing too, not just the avatar's edge.
      // A 56 avatar with a 20's gap reads as a photo glued to its caption, and
      // nothing about the widget tree would say so.
      expect(
        gapIn(5),
        greaterThan(gapIn(0)),
        reason: 'the huge persona must breathe more than the extra-small one',
      );

      await expectCleanTeardown(tester, section.id);
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
