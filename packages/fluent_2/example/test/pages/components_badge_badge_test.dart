import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Badge's page carries seven demos and not a knob among them: every design
/// axis is spelled out as a row of variants rather than driven by a control.
/// That makes the failure worth hunting a different one from the knob pages —
/// an axis that *mounts* but reaches nothing, leaving four badges that are
/// supposed to differ painting one identical fill. `render_test.dart` waves
/// exactly that through, so every test below reads what was painted rather than
/// what the widget was configured with: a `FluentBadge.appearance` that never
/// arrives in the decoration is the defect, and the widget's own field cannot
/// see it.
void main() {
  const String page = 'components-badge-badge';

  group('default', () {
    final DocsSection section = sectionOf('components-badge-badge--default');

    testWidgets('the bare badge is a round-cornered dot at the medium stop', (
      WidgetTester tester,
    ) async {
      // `loose`, because this demo is one self-sizing widget: the story stage
      // aligns it, so its own 20-wide minimum is what decides its width. A tight
      // scroll-view width would stretch it to 1600 and measure the harness.
      await pumpSection(tester, section, loose: true);

      final Finder badge = find.byType(FluentBadge);
      expect(badge, findsOneWidget);
      // Neither label nor icon: the minimum size is the only thing giving this
      // badge extent at all, so a dropped `minimumSize` collapses it to the
      // padding and the demo silently renders an 8x0 sliver.
      expect(tester.getSize(badge), const Size(20, 20));
      expect(find.byType(Text), findsNothing);

      final BoxDecoration decoration = decorationUnder(tester, badge);
      expect(decoration.borderRadius, FluentRadius.allMedium);
      expect(
        decoration.color,
        FluentTheme.of(tester.element(badge)).colors.brandBackground,
        reason: 'the default badge is brand-filled',
      );
    });

    testWidgets('a real mouse leaves the badge exactly as it was', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, loose: true);
      final Finder badge = find.byType(FluentBadge);
      final BoxDecoration rest = decorationUnder(tester, badge);

      // Fluent ships no hover, pressed or disabled Badge tokens, and the widget
      // documents itself as a marker rather than a control. A badge that lights
      // up under the pointer is therefore a defect, and hover is unreachable
      // through `tester.tap` — only a real device can see it.
      final BoxDecoration hovered = await whileHovering(
        tester,
        badge,
        () => decorationUnder(tester, badge),
      );
      expect(
        hovered.color,
        rest.color,
        reason: 'a badge has no hover treatment to show',
      );

      await mouseClick(tester, badge);
      expect(decorationUnder(tester, badge).color, rest.color);
    });
  });

  group('appearance', () {
    testWidgets('each appearance paints its own fill, stroke and label', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-badge-badge--appearance'),
      );

      expect(find.byType(FluentBadge), findsNWidgets(4));
      expect(find.text('999+'), findsNWidgets(4));

      // Filled, subtle, outline and tint differ in *combinations* rather than in
      // any one property: subtle and outline share the transparent fill and
      // separate on the stroke, outline and subtle share a label colour and
      // separate on the fill. Comparing the triples is what makes "all four
      // arrived" answerable without asserting seven tokens by name.
      final Set<({Color? border, Color? fill, Color? label})> painted =
          <({Color? border, Color? fill, Color? label})>{
            for (int i = 0; i < 4; i++)
              (
                fill: _paint(tester, i).fill,
                border: _paint(tester, i).border,
                label: textStyleOf(tester, find.text('999+').at(i))?.color,
              ),
          };
      expect(
        painted,
        hasLength(4),
        reason:
            'two appearances painted identically, so one axis reached '
            'nothing',
      );

      final FluentThemeData theme = FluentTheme.of(
        tester.element(find.byType(FluentBadge).first),
      );
      // Figma paints no fill on outline and subtle, and the *token* rather than
      // a literal, because Fluent's transparent tokens turn opaque in high
      // contrast. A demo that hard-coded a transparent Color would pass a
      // "differs from filled" check and be wrong on a high-contrast surface.
      expect(_paint(tester, 1).fill, theme.colors.transparentBackground);
      expect(_paint(tester, 2).fill, theme.colors.transparentBackground);
      expect(
        _paint(tester, 1).border,
        isNull,
        reason: 'subtle is the one appearance with no stroke at all',
      );
      expect(_paint(tester, 2).border, isNotNull);
    });
  });

  group('sizes', () {
    testWidgets('the four size stops step 16, 20, 24, 32 and stay round', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-badge-badge--sizes'));

      expect(find.byType(FluentBadge), findsNWidgets(4));
      // The exact Figma geometry, not merely "ascending": these badges carry no
      // content, so their height IS the size token and a wrong stop is a wrong
      // number rather than a subtle shift.
      const List<double> stops = <double>[16, 20, 24, 32];
      for (int i = 0; i < stops.length; i++) {
        expect(
          tester.getSize(find.byType(FluentBadge).at(i)),
          Size(stops[i], stops[i]),
          reason: 'size stop $i is not ${stops[i]} square',
        );
      }
    });
  });

  group('shapes', () {
    testWidgets('the style hook gives each badge a different corner', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-badge-badge--shapes'));

      expect(find.byType(FluentBadge), findsNWidgets(3));
      // `FluentBadge` has no shape axis — the Figma set binds one 4px radius to
      // every size — so this section's entire claim rests on the public `style`
      // slot winning over the resolved default. If `merge` ever stopped letting
      // the caller's radius through, all three would render identically and
      // nothing else on the page would notice.
      const List<BorderRadius> corners = <BorderRadius>[
        BorderRadius.zero,
        FluentRadius.allMedium,
        FluentRadius.allCircular,
      ];
      for (int i = 0; i < corners.length; i++) {
        expect(
          decorationUnder(tester, find.byType(FluentBadge).at(i)).borderRadius,
          corners[i],
          reason: 'shape $i did not take the radius its style asked for',
        );
      }
    });
  });

  group('color', () {
    testWidgets('all seven colours are distinguishable', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-badge-badge--color'));

      expect(find.byType(FluentBadge), findsNWidgets(7));

      final List<({Color? fill, Color? label})> painted =
          <({Color? fill, Color? label})>[
            for (int i = 0; i < 7; i++)
              (
                fill: _paint(tester, i).fill,
                label: textStyleOf(tester, find.text('999+').at(i))?.color,
              ),
          ];
      expect(
        painted.toSet(),
        hasLength(7),
        reason: 'two colours render identically, so the colour axis is lossy',
      );

      // Deliberately not seven distinct *fills*: Figma binds informative and
      // subtle to the same `Neutral/Background/5/Rest` and separates them on the
      // label instead. Spelling that out here stops a future "seven fills"
      // tightening from reporting a token match as a bug.
      expect(painted[3].fill, painted[4].fill);
      expect(painted[3].label, isNot(painted[4].label));
    });
  });

  group('icon', () {
    testWidgets('the icon renders at the size stop and takes the label tone', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-badge-badge--icon'),
        loose: true,
      );

      final Finder icon = find.byIcon(FluentIcons.clipboard_paste_20_regular);
      expect(icon, findsOneWidget);
      // The glyph is named `_20_` but the medium stop draws it at 12: the badge
      // sizes its icon through `IconTheme`, so a demo that rendered it at the
      // icon's nominal 20 would burst its own 20-high badge.
      expect(tester.getSize(icon), const Size(12, 12));
      expect(
        IconTheme.of(tester.element(icon)).color,
        FluentTheme.of(
          tester.element(find.byType(FluentBadge)),
        ).colors.neutralForegroundOnBrand,
        reason: 'an icon-only badge must inherit the badge foreground',
      );
      expect(tester.getSize(find.byType(FluentBadge)), const Size(20, 20));
    });
  });

  group('color and appearance', () {
    testWidgets('every appearance renders all seven colours', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-badge-badge--color-and-appearance'),
      );

      for (final String heading in <String>[
        'Filled',
        'Ghost',
        'Outline',
        'Tint',
      ]) {
        expect(find.text(heading), findsOneWidget);
      }
      expect(find.byType(FluentBadge), findsNWidgets(28));
      expect(find.text('999+'), findsNWidgets(28));
      expect(
        find.byIcon(FluentIcons.clipboard_paste_20_regular),
        findsNWidgets(28),
        reason: 'this grid is the only place the icon slot is shown per colour',
      );

      // One badge per row, same colour. Fill *and* stroke, because ghost and
      // outline both paint the transparent token and separate on the border
      // alone — comparing fills would report a correct grid as a duplicate.
      final Set<({Color? border, Color? fill})> perRow =
          <({Color? border, Color? fill})>{
            for (int row = 0; row < 4; row++) _paint(tester, row * 7),
          };
      expect(
        perRow,
        hasLength(4),
        reason:
            'two rows painted identically, so `appearance` never left the '
            'row builder',
      );
    });

    testWidgets('the subtle colour is shown on brand where it needs to be', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-badge-badge--color-and-appearance'),
      );

      final FluentThemeData theme = FluentTheme.of(
        tester.element(find.byType(FluentBadge).first),
      );
      // Subtle-on-ghost and subtle-on-outline paint white on white; the section
      // exists to say so, and it only says it if the two brand backings are
      // actually there. Two, not four: filled and tint carry their own contrast.
      final Iterable<ColoredBox> backings = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .where((ColoredBox box) => box.color == theme.colors.brandBackground);
      expect(
        backings,
        hasLength(2),
        reason: 'the ghost and outline subtle badges lost their brand surface',
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

/// The fill and stroke the [index]-th badge in the tree actually painted.
///
/// The widget's own `appearance` and `color` record what was asked for; the
/// decoration records what arrived. Only the second is evidence that an axis is
/// wired up, which is the whole subject of this file.
({Color? border, Color? fill}) _paint(WidgetTester tester, int index) {
  final BoxDecoration decoration = decorationUnder(
    tester,
    find.byType(FluentBadge).at(index),
  );
  final BoxBorder? border = decoration.border;
  return (
    fill: decoration.color,
    border: border is Border ? border.top.color : null,
  );
}
