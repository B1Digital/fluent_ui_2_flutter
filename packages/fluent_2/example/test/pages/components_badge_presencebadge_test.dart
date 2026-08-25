import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// A presence badge is pure colour and shape — no label, no icon slot, nothing
/// a text snapshot can see — and its whole subject is a glyph choice that is
/// deliberately *not* mechanical: away out of office swaps to the out-of-office
/// glyph outright, busy out of office borrows unknown's, and four statuses share
/// one danger colour. A page that dropped `outOfOffice` from a row, or reused
/// one status eight times, would mount cleanly and look plausible. So every test
/// below reads the drawn glyph, the painter's resolved tones and the announced
/// label, because those are the only three places the axes actually surface.
void main() {
  const String page = 'components-badge-presencebadge';

  /// The eight statuses in the order both grid sections declare them.
  const List<FluentPresenceStatus> statuses = <FluentPresenceStatus>[
    FluentPresenceStatus.available,
    FluentPresenceStatus.away,
    FluentPresenceStatus.busy,
    FluentPresenceStatus.doNotDisturb,
    FluentPresenceStatus.offline,
    FluentPresenceStatus.outOfOffice,
    FluentPresenceStatus.blocked,
    FluentPresenceStatus.unknown,
  ];

  group('default', () {
    final DocsSection section = sectionOf(
      'components-badge-presencebadge--default',
    );

    testWidgets('the default badge is a 16px available disc with its glyph', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, loose: true);

      final Finder badge = find.byType(FluentPresenceBadge);
      expect(badge, findsOneWidget);
      expect(tester.getSize(badge), const Size(16, 16));
      expect(find.byIcon(FluentIcons.presence_available_16_filled), findsOne);

      final FluentThemeData theme = FluentTheme.of(tester.element(badge));
      expect(
        _icon(tester, 0)?.color,
        theme.colors.statusAvailableForeground3,
        reason: 'the glyph, not the disc, is what carries the status colour',
      );

      final FluentPresenceBadgePainter painter = _painter(tester, 0);
      // The disc is `Neutral/Background/1/Rest` — the surface the hollow
      // out-of-office glyphs read against — and the ring is the same token
      // painted outside the box so the badge can sit on an avatar. `dot` is the
      // fallback for the sizes with no glyph, so it must be null here: a badge
      // that painted both would show a solid disc with a glyph on top of it.
      expect(painter.disc, theme.colors.neutralBackground1);
      expect(painter.ring, theme.colors.neutralBackground1);
      expect(painter.ringWidth, FluentStroke.thick);
      expect(painter.dot, isNull);
    });

    testWidgets('a real mouse leaves the badge exactly as it was', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, loose: true);
      final Finder badge = find.byType(FluentPresenceBadge);
      final FluentPresenceBadgePainter rest = _painter(tester, 0);

      // Non-interactive, like `FluentBadge`: Fluent ships no hover or pressed
      // presence tokens. `shouldRepaint` compares exactly the four fields
      // asserted here, so an equal painter is the same statement the framework
      // makes — and hover cannot be reached through `tester.tap` at all.
      final FluentPresenceBadgePainter hovered = await whileHovering(
        tester,
        badge,
        () => _painter(tester, 0),
      );
      expect(hovered.shouldRepaint(rest), isFalse);

      await mouseClick(tester, badge);
      expect(_painter(tester, 0).shouldRepaint(rest), isFalse);
      expect(find.byIcon(FluentIcons.presence_available_16_filled), findsOne);
    });
  });

  group('sizes', () {
    testWidgets('the six stops step 6, 10, 12, 16, 20, 28', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-badge-presencebadge--sizes'),
      );

      expect(find.byType(FluentPresenceBadge), findsNWidgets(6));
      const List<double> diameters = <double>[6, 10, 12, 16, 20, 28];
      for (int i = 0; i < diameters.length; i++) {
        expect(
          tester.getSize(find.byType(FluentPresenceBadge).at(i)),
          Size(diameters[i], diameters[i]),
          reason: 'size stop $i is not ${diameters[i]} across',
        );
      }
    });

    testWidgets('tiny is a bare dot and the rest step through the icon set', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-badge-presencebadge--sizes'),
      );

      // Five glyphs, not six. Fluent draws no presence icon at 6px, so tiny has
      // to paint the status colour as the disc itself — a demo that rendered a
      // glyph there would be showing something the design system does not have.
      expect(find.byType(Icon), findsNWidgets(5));
      expect(_icon(tester, 0), isNull);

      final FluentThemeData theme = FluentTheme.of(
        tester.element(find.byType(FluentPresenceBadge).first),
      );
      final FluentPresenceBadgePainter tiny = _painter(tester, 0);
      expect(
        tiny.dot,
        theme.colors.statusAvailableForeground3,
        reason: 'with no glyph, the disc is the only thing left to colour',
      );
      // 1 against 2 everywhere else: at 6px a 2px ring would eat the dot.
      expect(tiny.ringWidth, FluentStroke.thin);
      for (int i = 1; i < 6; i++) {
        expect(_painter(tester, i).ringWidth, FluentStroke.thick);
        expect(_painter(tester, i).dot, isNull);
      }

      // The icon set stops at 24 while the badge goes to 28, so the last two
      // rows are 20 and 24 rather than 20 and 28 — the nominal glyph and the
      // rendered diameter are different numbers and the mapping between them is
      // hand-written.
      for (final IconData glyph in <IconData>[
        FluentIcons.presence_available_10_filled,
        FluentIcons.presence_available_12_filled,
        FluentIcons.presence_available_16_filled,
        FluentIcons.presence_available_20_filled,
        FluentIcons.presence_available_24_filled,
      ]) {
        expect(find.byIcon(glyph), findsOne, reason: 'no $glyph in the row');
      }
    });
  });

  group('status', () {
    testWidgets('all eight statuses draw a different glyph', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-badge-presencebadge--status'),
      );

      expect(find.byType(FluentPresenceBadge), findsNWidgets(8));
      final Set<IconData?> glyphs = <IconData?>{
        for (int i = 0; i < 8; i++) _icon(tester, i)?.icon,
      };
      expect(
        glyphs,
        hasLength(8),
        reason: 'two statuses share a glyph, so one of them is unreadable',
      );
    });

    testWidgets('the colour groups are the ones Figma actually specifies', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-badge-presencebadge--status'),
      );

      final FluentThemeData theme = FluentTheme.of(
        tester.element(find.byType(FluentPresenceBadge).first),
      );
      // Deliberately not eight distinct colours. Busy, do-not-disturb, blocked
      // and unknown all take `Status/Danger/Background/3/Rest` — unknown being
      // red is Figma's reading where React uses a neutral — so a "all eight
      // differ" assertion would report the correct mapping as a bug. What has to
      // hold is that the four *specified* families arrived.
      expect(_icon(tester, 0)?.color, theme.colors.statusAvailableForeground3);
      expect(_icon(tester, 1)?.color, theme.colors.statusAwayBackground3);
      expect(_icon(tester, 4)?.color, theme.colors.neutralForeground3);
      expect(_icon(tester, 5)?.color, theme.colors.statusOofForeground3);
      for (final int i in <int>[2, 3, 6, 7]) {
        expect(
          _icon(tester, i)?.color,
          theme.colors.statusDangerBackground3,
          reason: 'status $i left the danger family',
        );
      }
    });

    testWidgets('each badge announces its own status', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-badge-presencebadge--status'),
      );

      // The badge draws no text at all, so the semantic label is the only thing
      // a screen reader gets. Eight identical announcements would be as broken
      // as eight identical glyphs and just as invisible on screen.
      for (int i = 0; i < statuses.length; i++) {
        expect(
          _announced(tester, i),
          fluentPresenceStatusLabel(
            statuses[i],
            outOfOffice: false,
            l10n: fluentLocalizationsFallback,
          ),
          reason: 'badge $i announced the wrong status',
        );
      }
    });
  });

  group('out of office', () {
    testWidgets('the flag reaches every badge in the row', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-badge-presencebadge--out-of-office'),
      );

      expect(find.byType(FluentPresenceBadge), findsNWidgets(8));
      // Four of the eight statuses render identically in and out of office, so
      // the glyph cannot prove the flag was passed for those rows. The
      // announcement can: `presenceOutOfOfficeStatus` wraps the status name for
      // every status except out-of-office itself, which would otherwise say it
      // twice.
      for (int i = 0; i < statuses.length; i++) {
        expect(
          _announced(tester, i),
          fluentPresenceStatusLabel(
            statuses[i],
            outOfOffice: true,
            l10n: fluentLocalizationsFallback,
          ),
          reason: 'badge $i was not given the out-of-office flag',
        );
      }
    });

    testWidgets('out of office changes exactly the four glyphs it should', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-badge-presencebadge--status'),
      );
      final List<({Color? colour, IconData? glyph})> inOffice =
          <({Color? colour, IconData? glyph})>[
            for (int i = 0; i < 8; i++)
              (glyph: _icon(tester, i)?.icon, colour: _icon(tester, i)?.color),
          ];

      await pumpSection(
        tester,
        sectionOf('components-badge-presencebadge--out-of-office'),
      );
      final List<({Color? colour, IconData? glyph})> away =
          <({Color? colour, IconData? glyph})>[
            for (int i = 0; i < 8; i++)
              (glyph: _icon(tester, i)?.icon, colour: _icon(tester, i)?.color),
          ];

      // The point of having both sections on one page: available hollows out,
      // away substitutes the out-of-office glyph *and* berry for marigold, busy
      // borrows unknown's glyph while keeping danger red, and do-not-disturb
      // hollows out. The other four are specified to be identical, which is why
      // a blanket "everything changed" assertion would be wrong here.
      for (final int i in <int>[0, 1, 2, 3]) {
        expect(
          away[i].glyph,
          isNot(inOffice[i].glyph),
          reason: 'status $i kept its in-office glyph',
        );
      }
      for (final int i in <int>[4, 5, 6, 7]) {
        expect(
          away[i].glyph,
          inOffice[i].glyph,
          reason: 'status $i has no out-of-office variant to switch to',
        );
      }
      // Away is the one status where the flag moves the colour too.
      expect(away[1].colour, isNot(inOffice[1].colour));
      expect(
        away[2].colour,
        inOffice[2].colour,
        reason: 'busy out of office borrows unknown’s glyph, not its colour',
      );
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section, loose: true);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// The painter behind the [index]-th presence badge in the tree.
///
/// The disc, ring and dot are drawn on a canvas rather than composed from
/// widgets — the ring is stroke-aligned outside, which no decoration can do — so
/// the painter's own fields are the only readable record of what was painted.
FluentPresenceBadgePainter _painter(WidgetTester tester, int index) =>
    paintersOf<FluentPresenceBadgePainter>(
      tester,
      find.byType(FluentPresenceBadge).at(index),
    ).single;

/// The glyph widget the [index]-th badge drew, or null at the tiny stop, which
/// has no icon in the Fluent set at all.
Icon? _icon(WidgetTester tester, int index) {
  final Finder glyph = find.descendant(
    of: find.byType(FluentPresenceBadge).at(index),
    matching: find.byType(Icon),
  );
  return glyph.evaluate().isEmpty ? null : tester.widget<Icon>(glyph.first);
}

/// What the [index]-th badge announces.
///
/// Read off the `Semantics` widget rather than through `find.bySemanticsLabel`,
/// which needs the semantics tree switched on for the whole test; the widget's
/// own properties are the same answer with no handle to keep alive.
String _announced(WidgetTester tester, int index) =>
    tester
        .widget<Semantics>(
          find
              .descendant(
                of: find.byType(FluentPresenceBadge).at(index),
                matching: find.byType(Semantics),
              )
              .first,
        )
        .properties
        .label ??
    '';
