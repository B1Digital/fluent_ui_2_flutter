import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Avatar's fifteen sections carry no knobs at all: every one of them is a
/// claim about what a *prop* paints — this size is that many pixels, this
/// colour mode is that token, this shape is that radius, this status is that
/// glyph. A page like that rots silently, because "it still renders" is exactly
/// what a broken colour table also looks like. So each test below reads the
/// pixel-facing value rather than the widget's own field: the fill under the
/// avatar, the glyph the badge chose, the box the ladder laid out.
///
/// The one behavioural claim on the page is a negative — `FluentAvatar` is
/// documented as non-interactive, with no hover, press or focus of its own —
/// and it is driven with a real mouse, because a synthetic tap could not tell a
/// component that ignores the pointer apart from one that never sees it.
void main() {
  const String page = 'components-avatar';

  /// The theme the mounted section is actually rendering against.
  FluentThemeData themeOf(WidgetTester tester) =>
      FluentTheme.of(tester.element(find.byType(FluentAvatar).first));

  /// What assistive technology is handed for [avatar].
  ///
  /// Read off the widget rather than the semantics tree: the initials and the
  /// fallback glyph are wrapped in `ExcludeSemantics`, so the label is the only
  /// thing a screen reader gets and it must be the *name*, never the initials.
  String? labelOf(WidgetTester tester, Finder avatar) => tester
      .widget<Semantics>(
        find.descendant(of: avatar, matching: find.byType(Semantics)).first,
      )
      .properties
      .label;

  /// The presence badge's glyph colour, which is the status token itself.
  Color? badgeTone(WidgetTester tester, Finder badge) => tester
      .widget<Icon>(
        find.descendant(of: badge, matching: find.byType(Icon)).first,
      )
      .color;

  group('default', () {
    final DocsSection section = sectionOf('components-avatar--default');

    testWidgets('a name with no initials falls back to the person glyph', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder avatar = find.byType(FluentAvatar);
      // Content precedence is image, then initials, then icon. With only a name
      // the avatar must land on the glyph — and on the glyph Figma instances
      // for a 32 box, not on whatever the ambient IconTheme happens to say.
      expect(find.byIcon(FluentIcons.person_20_filled), findsOneWidget);
      expect(find.byType(Text), findsNothing);
      // Height only: an avatar is a `SizedBox.square`, and a square box under
      // the tight cross-axis constraint this harness mounts under is as wide as
      // it is told to be. The height is the half of the box the size axis still
      // owns here — the `size` section measures both, in a Wrap that loosens.
      expect(tester.getSize(avatar).height, 32);

      final IconThemeData icons = IconTheme.of(
        tester.element(find.byType(Icon)),
      );
      expect(icons.size, 20);
      expect(icons.color, themeOf(tester).colors.neutralForeground3);
      expect(labelOf(tester, avatar), 'Guest');

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('a real mouse press leaves the avatar exactly as it was', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder avatar = find.byType(FluentAvatar);

      final Color? before = fillOf(tester, avatar)?.color;
      final Rect box = tester.getRect(avatar);

      // `FluentAvatar` documents itself as non-interactive: no hover, no press,
      // no focus, no disabled. A synthetic tap cannot prove that — it delivers
      // no enter event, so a component that grew a hover ramp would still pass.
      // A real press with a real hover in front of it can.
      await mouseClick(tester, avatar);

      expect(fillOf(tester, avatar)?.color, before);
      expect(tester.getRect(avatar), box);
      expect(
        paintersOf<FluentAvatarRingPainter>(
          tester,
        ).every((FluentAvatarRingPainter ring) => ring.width == 0),
        isTrue,
        reason: 'pressing an avatar must not raise an activity ring',
      );
    });
  });

  group('name', () {
    testWidgets('the initials are drawn and the name is what is announced', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf('components-avatar--name');
      await pumpSection(tester, section);

      final Finder avatar = find.byType(FluentAvatar);
      expect(find.text('AM'), findsOneWidget);
      // The whole point of the section: the initials are decoration and the
      // name is the accessible text. Announcing "AM" would be the regression.
      expect(labelOf(tester, avatar), 'Ashley McCarthy');
      expect(find.text('Ashley McCarthy'), findsNothing);

      await expectCleanTeardown(tester, section.id);
    });
  });

  group('image', () {
    testWidgets('the photo is painted cover-fit into the avatar', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf('components-avatar--image');
      await pumpSection(tester, section);

      final Finder avatar = find.byType(FluentAvatar);
      final BoxDecoration? fill = fillOf(tester, avatar);
      final DecorationImage? photo = fill?.image;

      expect(photo, isNotNull, reason: 'the avatar must paint its image');
      expect(
        (photo!.image as AssetImage).assetName,
        'assets/storybook/KatriAthokas.jpg',
      );
      // Cover, not contain: a portrait cropped to fit would letterbox inside a
      // circle, which is the one thing an avatar must never do.
      expect(photo.fit, BoxFit.cover);
      expect(fill!.borderRadius, FluentRadius.allCircular);
      expect(labelOf(tester, avatar), 'Katri Athokas');

      await expectCleanTeardown(tester, section.id);
    });
  });

  group('icon', () {
    testWidgets('each tile keeps its own glyph and its own shape', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf('components-avatar--icon');
      await pumpSection(tester, section);

      final Finder avatars = find.byType(FluentAvatar);
      expect(avatars, findsNWidgets(7));

      // Shape is per-avatar here, so a shape axis that had stopped reaching the
      // decoration would show up as seven identical radii rather than as an
      // exception. Team, Tenant and Room are the square three.
      for (int i = 0; i < 7; i++) {
        final FluentAvatar avatar = tester.widget<FluentAvatar>(avatars.at(i));
        expect(
          fillOf(tester, avatars.at(i))?.borderRadius,
          avatar.shape == FluentAvatarShape.square
              ? FluentRadius.allSmall
              : FluentRadius.allCircular,
          reason: '${avatar.name} drew the wrong corner treatment',
        );
      }

      for (final IconData glyph in <IconData>[
        FluentIcons.guest_20_regular,
        FluentIcons.people_20_regular,
        FluentIcons.people_team_20_regular,
        FluentIcons.person_call_20_regular,
        FluentIcons.calendar_ltr_20_regular,
        FluentIcons.briefcase_20_regular,
        FluentIcons.conference_room_20_regular,
      ]) {
        expect(find.byIcon(glyph), findsOneWidget);
      }

      await expectCleanTeardown(tester, section.id);
    });
  });

  group('badge', () {
    final DocsSection section = sectionOf('components-avatar--badge');

    testWidgets('every avatar carries a badge pinned to its bottom corner', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder avatars = find.byType(FluentAvatar);
      expect(avatars, findsNWidgets(14));
      expect(find.byType(FluentPresenceBadge), findsNWidgets(14));

      final Rect avatar = tester.getRect(avatars.first);
      final Rect badge = tester.getRect(
        find.descendant(
          of: avatars.first,
          matching: find.byType(FluentPresenceBadge),
        ),
      );
      // `Positioned(right: 0, bottom: 0)` inside the avatar's own Stack. A badge
      // that had drifted to the middle would still be "present".
      expect(badge.right, avatar.right);
      expect(badge.bottom, avatar.bottom);
      // A 32 avatar takes the extraSmall badge — 10, not the badge default of
      // 16 — and every tile on this row is a 32.
      expect(badge.size, const Size(10, 10));

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('out of office changes away, and deliberately not offline', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder badges = find.byType(FluentPresenceBadge);
      final FluentColors colors = themeOf(tester).colors;

      // Index 3 is Robin (away) and index 10 is Daisy (away, out of office).
      // Away is the one status whose *colour* the flag replaces: marigold in
      // office, berry out of it. Reading the glyph tone rather than the widget's
      // `outOfOffice` field is the point — the flag reaching the field proves
      // nothing about the token that was painted.
      expect(badgeTone(tester, badges.at(3)), colors.statusAwayBackground3);
      expect(badgeTone(tester, badges.at(10)), colors.statusOofForeground3);

      // Index 4 is Tim (offline) and index 11 is Kevin (offline, out of office).
      // Offline is the documented no-op: same glyph, same neutral tone.
      expect(badgeTone(tester, badges.at(4)), colors.neutralForeground3);
      expect(
        badgeTone(tester, badges.at(11)),
        badgeTone(tester, badges.at(4)),
        reason: 'offline out of office must render exactly as offline does',
      );
    });
  });

  group('badge icon', () {
    testWidgets('a custom badge overhangs the avatar with its own glyph', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf('components-avatar--badge-icon');
      await pumpSection(tester, section, inset: const EdgeInsets.all(40));

      // The section's claim is the *icon*: `FluentAvatar.status` can only build
      // a presence badge, so a calendar glyph in the corner has to come from a
      // composed `FluentBadge` instead. A presence badge appearing here would
      // mean the demo quietly fell back to the slot it cannot use.
      expect(find.byType(FluentBadge), findsOneWidget);
      expect(find.byType(FluentPresenceBadge), findsNothing);
      expect(
        find.byIcon(FluentIcons.calendar_month_20_regular),
        findsOneWidget,
      );
      expect(find.text('JD'), findsOneWidget);

      // `bottom: -2` on the badge. The horizontal anchor is `right: -2` against
      // the Stack, which shrink-wraps to the avatar only under the loose
      // constraints the showroom's `Align` gives it, so the floor overhang is
      // the half of the offset that is honest to assert here.
      expect(
        tester.getRect(find.byType(FluentBadge)).bottom -
            tester.getRect(find.byType(FluentAvatar)).bottom,
        2,
      );

      await expectCleanTeardown(tester, section.id);
    });
  });

  group('square', () {
    testWidgets('the square shape flattens the radius to small', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf('components-avatar--square');
      await pumpSection(tester, section);

      final BoxDecoration? fill = fillOf(tester, find.byType(FluentAvatar));
      expect(fill?.borderRadius, FluentRadius.allSmall);
      expect(
        fill?.borderRadius,
        isNot(FluentRadius.allCircular),
        reason: 'a square avatar that still rounds fully is not square',
      );

      await expectCleanTeardown(tester, section.id);
    });
  });

  group('color brand', () {
    testWidgets('the brand mode paints the brand fill under its own text tone', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf('components-avatar--color-brand');
      await pumpSection(tester, section);

      final FluentColors colors = themeOf(tester).colors;
      expect(
        fillOf(tester, find.byType(FluentAvatar))?.color,
        colors.brandBackground,
      );
      // The foreground has to move with the fill: brand initials left on the
      // neutral tone are unreadable, and that is a contrast bug no widget-level
      // assertion about `color` would ever see.
      expect(
        textStyleOf(tester, find.text('BR'))?.color,
        colors.neutralForegroundOnBrand,
      );

      await expectCleanTeardown(tester, section.id);
    });
  });

  group('color colorful', () {
    testWidgets('the hash spreads the tiles, and reads the id not the name', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf(
        'components-avatar--color-colorful',
      );
      await pumpSection(tester, section);

      final Finder avatars = find.byType(FluentAvatar);
      expect(avatars, findsNWidgets(14));

      final List<Color?> fills = <Color?>[
        for (int i = 0; i < 14; i++) fillOf(tester, avatars.at(i))?.color,
      ];
      // A hash that stopped being applied — or a colour axis that stopped
      // reaching the fill — collapses the whole row to one tone. Eight is well
      // under what this data actually produces and well over one, so it fails
      // on the collapse without pinning the hash itself.
      expect(
        fills.toSet().length,
        greaterThanOrEqualTo(8),
        reason: 'the colourful row must not paint as one flat colour',
      );

      // The last four tiles are all named "Guest": their colours can only
      // differ if the demo hashed `idForColor` rather than the name, which is
      // exactly what the section says the fallback is for.
      expect(
        fills.sublist(10).toSet().length,
        greaterThan(1),
        reason: 'four identically named tiles must still be told apart by id',
      );

      await expectCleanTeardown(tester, section.id);
    });
  });

  group('color palette', () {
    testWidgets('every named colour paints its own palette token', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf('components-avatar--color-palette');
      await pumpSection(tester, section);

      final Finder avatars = find.byType(FluentAvatar);
      expect(avatars, findsNWidgets(30));
      final FluentPaletteColors palette = themeOf(tester).colors.palette;

      // Thirty tiles, thirty families. Comparing against the resolved token is
      // what makes this stronger than "they all look different": two families
      // whose Background/2/Rest happens to coincide would make a distinctness
      // check flap, and a colour axis wired to the *wrong* family would pass it.
      final Set<FluentAvatarColor> modes = <FluentAvatarColor>{};
      for (int i = 0; i < 30; i++) {
        final FluentAvatar avatar = tester.widget<FluentAvatar>(avatars.at(i));
        final FluentPaletteFamily family = avatar.color.family!;
        modes.add(avatar.color);
        expect(
          fillOf(tester, avatars.at(i))?.color,
          palette.background2Rest(family),
          reason: '${avatar.name} did not paint its own family background',
        );
      }
      // Thirty tiles for thirty modes. Two rows that had been copy-pasted onto
      // the same colour would still pass every assertion above — this is the
      // only thing that says the section covers the palette rather than merely
      // showing thirty avatars.
      expect(modes, hasLength(30));

      await expectCleanTeardown(tester, section.id);
    });
  });

  group('active', () {
    final DocsSection section = sectionOf('components-avatar--active');

    testWidgets('active rings the avatar and inactive collapses it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(40));

      final List<FluentAvatarRingPainter> rings =
          paintersOf<FluentAvatarRingPainter>(tester);
      expect(rings, hasLength(2));

      // The ring is a painter and not a decoration precisely because it draws
      // outside the avatar's box, so its resolved width is the only place the
      // active axis shows up at all. Zero width paints nothing.
      expect(
        rings.first.width,
        greaterThan(0),
        reason: 'active must draw the activity ring',
      );
      expect(rings.first.opacity, 1);
      expect(rings.first.color, themeOf(tester).colors.brandStroke1);

      expect(
        rings.last.width,
        0,
        reason: 'inactive must collapse the ring onto the avatar',
      );
      expect(rings.last.opacity, 0);
    });

    testWidgets('inactive also scales and fades the avatar itself', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(40));

      final List<double> opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((Opacity o) => o.opacity)
          .toList();
      expect(opacities, <double>[1, 0.8]);

      // Upstream's `inactive { transform: scale(0.875) }`. The transform sits
      // below the avatar's own Semantics node, so the widget still measures 32
      // and only the painted surface shrinks — which is why this reads the
      // decorated box rather than the avatar.
      final Finder avatars = find.byType(FluentAvatar);
      double surfaceWidth(int i) => tester
          .getRect(
            find
                .descendant(
                  of: avatars.at(i),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          )
          .width;
      expect(surfaceWidth(0), 32);
      expect(surfaceWidth(1), closeTo(28, 0.01));

      await expectCleanTeardown(tester, section.id);
    });
  });

  group('active appearance', () {
    testWidgets('all three appearances draw the ring', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf(
        'components-avatar--active-appearance',
      );
      await pumpSection(tester, section, inset: const EdgeInsets.all(40));

      // The page states the divergence in so many words: Figma draws the ring
      // only, so `shadow` and `ring-shadow` have no treatment of their own and
      // all three tiles are ringed. A tile that lost its ring would be the
      // regression — an unringed "active" avatar reads as inactive.
      final List<FluentAvatarRingPainter> rings =
          paintersOf<FluentAvatarRingPainter>(tester);
      expect(rings, hasLength(3));
      for (final FluentAvatarRingPainter ring in rings) {
        expect(ring.width, greaterThan(0));
        expect(ring.opacity, 1);
      }

      await expectCleanTeardown(tester, section.id);
    });
  });

  group('initials', () {
    testWidgets('three custom initials are drawn verbatim', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf('components-avatar--initials');
      await pumpSection(tester, section);

      // Three letters, not the two a name parser would produce, and not
      // truncated to fit — the section exists to show the prop overriding both.
      expect(find.text('CRF'), findsOneWidget);
      expect(labelOf(tester, find.byType(FluentAvatar)), 'Cecil Robin Folk');

      await expectCleanTeardown(tester, section.id);
    });
  });

  group('size', () {
    testWidgets('the ladder lays out at exactly the size it names', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf('components-avatar--size');
      await pumpSection(tester, section);

      final Finder avatars = find.byType(FluentAvatar);
      expect(avatars, findsNWidgets(14));

      // The 128 label is deliberately a second 120 — Figma never draws the 128
      // variant — so the last two must MATCH. A ladder that had lost its size
      // axis would also produce fourteen equal boxes, which is what the rest of
      // the list rules out.
      const List<double> ladder = <double>[
        16,
        20,
        24,
        28,
        32,
        36,
        40,
        48,
        56,
        64,
        72,
        96,
        120,
        120,
      ];
      for (int i = 0; i < ladder.length; i++) {
        expect(
          tester.getSize(avatars.at(i)),
          Size.square(ladder[i]),
          reason: 'tile $i laid out at the wrong edge',
        );
      }

      // The type ramp rides the same axis: caption2Strong at 16, title3 at 120.
      final double smallest = textStyleOf(tester, find.text('16'))!.fontSize!;
      final double largest = textStyleOf(tester, find.text('120'))!.fontSize!;
      expect(
        largest,
        greaterThan(smallest),
        reason: 'the initials must grow with the box, not float at one size',
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
