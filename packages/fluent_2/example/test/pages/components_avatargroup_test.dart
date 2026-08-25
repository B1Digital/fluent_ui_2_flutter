import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// AvatarGroup's seven sections have no controls, but they are not static: the
/// overflow tile at the end of every group owns a popover, and five of the
/// sections stand or fall on geometry — spread gaps, stacked overlap, a pie cut
/// from one circle, and the same three at fourteen sizes.
///
/// So the tests split in two. The layout ones measure the group against the
/// other layouts rather than against a transcribed spacing table, because a
/// table copied into the test is a table that agrees with itself. The overflow
/// ones drive the trigger, and drive it with a real mouse: the tile is a bare
/// `GestureDetector` inside a scrollable, which is exactly the arrangement
/// where a two-pixel pointer travel can be stolen by the page instead of
/// reaching the control.
void main() {
  const String page = 'components-avatargroup';

  /// The seven names the overflow popover is supposed to hold.
  const List<String> hidden = <String>[
    'Johnie McConnell',
    'Allan Munger',
    'Erik Nason',
    'Kristin Patterson',
    'Daisy Phillips',
    'Carole Poland',
    'Carlos Slattery',
  ];

  // A popover anchored above its trigger lands at a negative y when the trigger
  // sits at the top of the viewport, and a box outside the view hit-tests to
  // nothing. The inset is room, not behaviour.
  const EdgeInsets room = EdgeInsets.all(200);

  /// The stack separator drawn around each member, ignoring the ring every
  /// avatar carries whether or not it paints.
  ///
  /// A `FluentAvatarRingPainter` at zero width paints nothing at all, so
  /// counting painters would say "stack" about a spread group too.
  int outlines(WidgetTester tester, Finder group) =>
      paintersOf<FluentAvatarRingPainter>(
        tester,
        group,
      ).where((FluentAvatarRingPainter ring) => ring.width > 0).length;

  /// The pie's divider rules.
  ///
  /// Not [paintersOf]: the pie draws its seams as a `foregroundPainter`, over
  /// the slices, and the harness reads `painter` — where the avatars' own rings
  /// live — on purpose.
  List<FluentAvatarPiePainter> rules(WidgetTester tester, Finder group) =>
      tester
          .widgetList<CustomPaint>(
            find.descendant(of: group, matching: find.byType(CustomPaint)),
          )
          .map((CustomPaint paint) => paint.foregroundPainter)
          .whereType<FluentAvatarPiePainter>()
          .toList();

  group('default', () {
    final DocsSection section = sectionOf('components-avatargroup--default');

    testWidgets('four members sit in a row with the overflow tile last', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: room);

      final Finder avatars = find.byType(FluentAvatar);
      expect(avatars, findsNWidgets(5));

      // `partitionAvatarGroupItems`: four names inline, seven behind the tile.
      expect(find.text('+7'), findsOneWidget);
      expect(
        tester.widget<FluentAvatar>(avatars.at(4)).color,
        FluentAvatarColor.overflow,
      );

      // Spread is the only layout with a positive gap, and the gap is what
      // separates it from a stack. Measuring the step between neighbours proves
      // it without restating Figma's spacing table here.
      final double step =
          tester.getRect(avatars.at(1)).left -
          tester.getRect(avatars.at(0)).left;
      expect(step, greaterThan(tester.getSize(avatars.first).width));
      for (int i = 1; i < 5; i++) {
        expect(
          tester.getRect(avatars.at(i)).left -
              tester.getRect(avatars.at(i - 1)).left,
          closeTo(step, 0.01),
          reason: 'the spread gap must be even across the row',
        );
      }

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the overflow tile opens and closes its roster', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: room);

      expect(find.byType(FluentPersona), findsNothing);
      await tapAndSettle(
        tester,
        find.text('+7'),
        what: 'the overflow tile',
        warnIfMissed: false,
      );

      // The count on the tile is a promise about what is behind it: seven rows,
      // and the seven names that are NOT already inline.
      expect(find.byType(FluentPersona), findsNWidgets(7));
      for (final String name in hidden) {
        expect(find.text(name), findsOneWidget, reason: '$name is missing');
      }

      await tester.tapAt(const Offset(20, 20));
      await settle(tester);
      expect(
        find.byType(FluentPersona),
        findsNothing,
        reason: 'a press outside the surface must dismiss it again',
      );

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the overflow tile opens under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: room);

      // The travel between press and release is the point: a scrollable that
      // claimed the mouse as a drag device would swallow this click whole, and
      // `tester.tap` — which never moves — could not tell.
      await mouseClick(tester, find.text('+7'));
      expect(
        find.byType(FluentPersona),
        findsNWidgets(7),
        reason: 'a mouse press on the tile must open the roster',
      );
    });
  });

  group('layout', () {
    final DocsSection section = sectionOf('components-avatargroup--layout');

    testWidgets('spread spreads, stack overlaps, and the pie is one circle', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: room);

      final Finder groups = find.byType(FluentAvatarGroup);
      expect(groups, findsNWidgets(3));
      final double spread = tester.getSize(groups.at(0)).width;
      final double stack = tester.getSize(groups.at(1)).width;
      final double pie = tester.getSize(groups.at(2)).width;

      // Five 32s side by side is 160. Above that is a positive gap, below it an
      // overlap, and a pie is one avatar wide however many people are in it.
      expect(spread, greaterThan(160));
      expect(stack, lessThan(160));
      expect(pie, 32);

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('only the stack outlines its members', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: room);

      final Finder groups = find.byType(FluentAvatarGroup);
      // Overlapping avatars with no separator are an unreadable smear, so the
      // outline is what makes a stack legible — and it must not appear on the
      // spread row, where it would read as a stray halo.
      expect(outlines(tester, groups.at(0)), 0);
      expect(outlines(tester, groups.at(1)), 5);

      expect(rules(tester, groups.at(2)), hasLength(1));
      final FluentAvatarPiePainter rule = rules(tester, groups.at(2)).single;
      expect(rule.width, greaterThan(0));
      expect(
        rule.quartered,
        isTrue,
        reason: 'a three-member pie splits its right half in two',
      );
    });

    testWidgets('each row keeps its own overflow popover', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: room);

      // Two triggers with identical labels, one per row. Opening the second
      // must not open the first: they are separate `_LayoutOverflow` states, and
      // a shared one would show fourteen rows here.
      final Finder tiles = find.text('+7');
      expect(tiles, findsNWidgets(2));

      await mouseClick(tester, tiles.at(1));
      expect(find.byType(FluentPersona), findsNWidgets(7));
    });
  });

  group('indicator', () {
    final DocsSection section = sectionOf('components-avatargroup--indicator');

    testWidgets('the count row and the icon row differ only in the tile', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: room);

      final Finder groups = find.byType(FluentAvatarGroup);
      expect(groups, findsNWidgets(2));

      Finder within(int row, Finder what) =>
          find.descendant(of: groups.at(row), matching: what);

      // The whole of upstream's `indicator` axis: a count, or the ellipsis.
      // Each row must carry exactly one and never the other.
      expect(within(0, find.text('+7')), findsOneWidget);
      expect(
        within(0, find.byIcon(FluentIcons.more_horizontal_20_regular)),
        findsNothing,
      );
      expect(within(1, find.text('+7')), findsNothing);
      expect(
        within(1, find.byIcon(FluentIcons.more_horizontal_20_regular)),
        findsOneWidget,
      );

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the icon tile opens the same roster the count tile does', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: room);

      // The glyph is a different *indicator*, not a different affordance. A
      // tile that only responded when it was showing a number would be a real
      // regression, and only pressing this one catches it.
      await mouseClick(
        tester,
        find.byIcon(FluentIcons.more_horizontal_20_regular),
      );
      expect(find.byType(FluentPersona), findsNWidgets(7));
      for (final String name in hidden) {
        expect(find.text(name), findsOneWidget);
      }
    });
  });

  group('size spread', () {
    final DocsSection section = sectionOf(
      'components-avatargroup--size-spread',
    );

    testWidgets('every row lays out at its own size, and none overlap', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(40));

      final Finder groups = find.byType(FluentAvatarGroup);
      expect(groups, findsNWidgets(14));

      // Upstream's ladder ends 120, 128 and Figma never draws the 128 variant,
      // so the last two rows must MATCH. The strictly growing prefix is what
      // stops that from being satisfied by a size axis that does nothing.
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
        final Rect row = tester.getRect(groups.at(i));
        expect(row.height, ladder[i], reason: 'row $i is the wrong height');
        expect(
          row.width,
          greaterThan(5 * ladder[i]),
          reason: 'row $i lost its spread gap',
        );
        if (i > 0 && ladder[i] != ladder[i - 1]) {
          expect(
            row.width,
            greaterThan(tester.getRect(groups.at(i - 1)).width),
            reason: 'row $i is no wider than the smaller row above it',
          );
        }
      }
      expect(
        tester.getRect(groups.at(13)).width,
        tester.getRect(groups.at(12)).width,
      );

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the tiles under 24 swap the count for the glyph', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(40));

      // "When size is less than 24, then icon will be used by default" — so
      // exactly the 16 and 20 rows, and exactly those. A "+7" that does not fit
      // its tile is the failure this rule exists to prevent, and a rule wired to
      // the wrong comparison would show up here as 0 or 14 glyphs, never 2.
      expect(
        find.byIcon(FluentIcons.more_horizontal_20_regular),
        findsNWidgets(2),
      );
      expect(find.text('+7'), findsNWidgets(12));

      final Finder groups = find.byType(FluentAvatarGroup);
      for (int i = 0; i < 2; i++) {
        expect(
          find.descendant(
            of: groups.at(i),
            matching: find.byIcon(FluentIcons.more_horizontal_20_regular),
          ),
          findsOneWidget,
          reason: 'row $i is under 24 and must use the glyph',
        );
      }
    });
  });

  group('size stack', () {
    final DocsSection section = sectionOf('components-avatargroup--size-stack');

    testWidgets('every row overlaps and outlines its members', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(40));

      final Finder groups = find.byType(FluentAvatarGroup);
      expect(groups, findsNWidgets(14));

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
        final Rect row = tester.getRect(groups.at(i));
        expect(row.height, ladder[i], reason: 'row $i is the wrong height');
        // Five members narrower than five members side by side: the stack gap is
        // the one that is negative, and a sign flip would read as a spread.
        expect(
          row.width,
          lessThan(5 * ladder[i]),
          reason: 'row $i is not overlapping',
        );
        expect(
          outlines(tester, groups.at(i)),
          5,
          reason: 'row $i left its members without a separator',
        );
      }

      await expectCleanTeardown(tester, section.id);
    });
  });

  group('size pie', () {
    final DocsSection section = sectionOf('components-avatargroup--size-pie');

    testWidgets('each pie is one avatar wide and cut into three', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(40));

      final Finder groups = find.byType(FluentAvatarGroup);
      expect(groups, findsNWidgets(14));

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
          tester.getSize(groups.at(i)),
          Size.square(ladder[i]),
          reason: 'pie $i is not a single avatar square',
        );
        // Three people in the space of one, so the seams are the only thing
        // that tells them apart. A pie that stopped drawing them is three
        // avatars silently overlapping.
        final List<FluentAvatarPiePainter> seams = rules(tester, groups.at(i));
        expect(seams, hasLength(1), reason: 'pie $i has no divider');
        expect(seams.single.width, greaterThan(0));
        expect(seams.single.quartered, isTrue);
      }

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('a pie member drops its own rounding', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(40));

      // The circle is the group's clip. A member that kept its own circular
      // radius would leave a bite of background out of every slice, so the pie
      // squares its members through a subtree theme — and that override is
      // invisible on the widget, which still says `circular`.
      final Finder members = find.descendant(
        of: find.byType(FluentAvatarGroup).at(4),
        matching: find.byType(FluentAvatar),
      );
      expect(members, findsNWidgets(3));
      for (int i = 0; i < 3; i++) {
        expect(
          fillOf(tester, members.at(i))?.borderRadius,
          BorderRadius.zero,
          reason: 'pie member $i is still rounding its own corners',
        );
      }
    });
  });

  group('tooltip', () {
    final DocsSection section = sectionOf('components-avatargroup--tooltip');

    testWidgets('a resting pointer raises the custom tip and drops it again', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: room);

      // Hover is the only way in: `tester.tap` synthesises no enter event, so a
      // tooltip is unreachable without a real device.
      final TestGesture mouse = await mouseHover(tester, find.text('+7'));
      expect(
        find.text('My custom tooltip'),
        findsOneWidget,
        reason: 'the overridden tooltip content must be what is shown',
      );

      await mouseAway(tester, mouse);
      expect(find.text('My custom tooltip'), findsNothing);

      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the tile still opens while its tooltip is up', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: room);

      final Offset spot = tester.getCenter(find.text('+7'));
      final TestGesture mouse = await mouseHover(tester, find.text('+7'));
      expect(find.text('My custom tooltip'), findsOneWidget);

      // The real sequence a mouse produces: dwell, then press without leaving.
      // A tooltip surface that took hits would eat this press, and the tile
      // would be permanently unopenable for anyone using a pointer — while a
      // plain `tester.tap`, which never raises the tip at all, sailed through.
      await mouse.down(spot);
      await tester.pump(const Duration(milliseconds: 16));
      await mouse.moveTo(spot + const Offset(2, 2));
      await tester.pump(const Duration(milliseconds: 16));
      await mouse.up();
      await settle(tester);

      expect(
        find.byType(FluentPersona),
        findsNWidgets(7),
        reason: 'the roster must open from a press that began as a hover',
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
  });
}
