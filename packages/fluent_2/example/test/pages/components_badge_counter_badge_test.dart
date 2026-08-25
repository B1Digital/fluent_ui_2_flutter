import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// fluent_2 ships no counter badge widget, so every demo on this page is a
/// `FluentBadge` reshaped through the public `style` slot: the circular corner,
/// the 6px dot and its dropped padding are all overrides, not defaults. That
/// makes this page unusually dependent on one library behaviour — that
/// `FluentBadgeStyle.merge` lets the caller's value win over the resolved one —
/// and if that ever stopped holding, every section here would quietly render
/// the *default* 4px rounded badge and still mount perfectly. These tests read
/// the painted radius and the measured box rather than the widget's `style`
/// field, because only those can tell the two apart.
void main() {
  const String page = 'components-badge-counter-badge';

  group('default', () {
    final DocsSection section = sectionOf(
      'components-badge-counter-badge--default',
    );

    testWidgets('the default counter is circular and holds its count', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, loose: true);

      final Finder badge = find.byType(FluentBadge);
      expect(badge, findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      // The page's own claim, and the one thing the style slot is here for: a
      // counter badge defaults to circular where a plain badge defaults to 4px.
      expect(
        decorationUnder(tester, badge).borderRadius,
        FluentRadius.allCircular,
      );
      // A single digit must not collapse the badge onto its padding — Figma
      // pins the minimum width to the height so the disc stays a disc.
      final Size size = tester.getSize(badge);
      expect(size.height, 20);
      expect(size.width, greaterThanOrEqualTo(size.height));
    });

    testWidgets('a real mouse leaves the counter exactly as it was', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, loose: true);
      final Finder badge = find.byType(FluentBadge);
      final BoxDecoration rest = decorationUnder(tester, badge);

      // A counter badge is a marker, not a control: Fluent ships no hover or
      // pressed Badge tokens at all. Hover is invisible to `tester.tap`, so a
      // stray interaction treatment could only ever be caught with a real
      // device resting on the badge.
      final BoxDecoration hovered = await whileHovering(
        tester,
        badge,
        () => decorationUnder(tester, badge),
      );
      expect(hovered.color, rest.color);
      expect(hovered.borderRadius, rest.borderRadius);

      await mouseClick(tester, badge);
      expect(decorationUnder(tester, badge).color, rest.color);
    });
  });

  group('appearance', () {
    testWidgets('filled and ghost differ in fill and in label tone', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-badge-counter-badge--appearance'),
      );

      expect(find.byType(FluentBadge), findsNWidgets(2));
      expect(find.text('5'), findsNWidgets(2));

      final FluentThemeData theme = FluentTheme.of(
        tester.element(find.byType(FluentBadge).first),
      );
      expect(
        decorationUnder(tester, find.byType(FluentBadge).at(0)).color,
        theme.colors.brandBackground,
      );
      // Ghost is `Appearance=Subtle` in Figma: no fill and no border, so the
      // label alone carries the colour. Two badges that both painted the brand
      // fill would still show two "5"s and pass any mount check.
      expect(
        decorationUnder(tester, find.byType(FluentBadge).at(1)).color,
        theme.colors.transparentBackground,
      );
      expect(
        textStyleOf(tester, find.text('5').at(0))?.color,
        isNot(textStyleOf(tester, find.text('5').at(1))?.color),
      );

      // Both are still counters, so both keep the circular corner the shapes
      // section introduces — appearance must not have quietly reset it.
      for (int i = 0; i < 2; i++) {
        expect(
          decorationUnder(tester, find.byType(FluentBadge).at(i)).borderRadius,
          FluentRadius.allCircular,
        );
      }
    });
  });

  group('shapes', () {
    testWidgets('circular and rounded take two different corners', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-badge-counter-badge--shapes'),
      );

      expect(find.byType(FluentBadge), findsNWidgets(2));
      // The whole section: one badge overrides the radius and one does not, so
      // a `merge` that dropped the override would render two identical badges
      // under a heading promising two shapes.
      expect(
        decorationUnder(tester, find.byType(FluentBadge).at(0)).borderRadius,
        FluentRadius.allCircular,
      );
      expect(
        decorationUnder(tester, find.byType(FluentBadge).at(1)).borderRadius,
        FluentRadius.allMedium,
      );
    });
  });

  group('sizes', () {
    testWidgets('the four stops grow and all stay circular', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-badge-counter-badge--sizes'),
      );

      expect(find.byType(FluentBadge), findsNWidgets(4));
      const List<double> heights = <double>[16, 20, 24, 32];
      for (int i = 0; i < heights.length; i++) {
        final Finder badge = find.byType(FluentBadge).at(i);
        expect(
          tester.getSize(badge).height,
          heights[i],
          reason: 'size stop $i is not ${heights[i]} high',
        );
        // Size and the style override are resolved by the same merge; a size
        // that reset the corner would be invisible in the height alone.
        expect(
          decorationUnder(tester, badge).borderRadius,
          FluentRadius.allCircular,
        );
      }

      // The type ramp moves with the box, not just the box: small and medium
      // share `caption2Strong` in Figma, but large and extraLarge step up to
      // `caption1Strong`, and the digit is where a reader sees it.
      expect(
        textStyleOf(tester, find.text('5').at(0))?.fontSize,
        isNot(textStyleOf(tester, find.text('5').at(3))?.fontSize),
      );
    });
  });

  group('color', () {
    testWidgets('all six colours are distinguishable', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-badge-counter-badge--color'),
      );

      // Six, not the seven the description names: `severe` is the one member
      // FluentBadgeColor does not have, because Fluent ships no
      // `Status/Severe/*` ramp. The count is asserted so that a colour dropped
      // from the section is a failure here rather than a quiet omission.
      expect(find.byType(FluentBadge), findsNWidgets(6));
      final Set<({Color? fill, Color? label})> painted =
          <({Color? fill, Color? label})>{
            for (int i = 0; i < 6; i++)
              (
                fill: decorationUnder(
                  tester,
                  find.byType(FluentBadge).at(i),
                ).color,
                label: textStyleOf(tester, find.text('5').at(i))?.color,
              ),
          };
      expect(
        painted,
        hasLength(6),
        reason: 'two colours render identically, so the colour axis is lossy',
      );
    });

    testWidgets('every colour the section names is actually shown', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-badge-counter-badge--color'),
      );

      final FluentThemeData theme = FluentTheme.of(
        tester.element(find.byType(FluentBadge).first),
      );
      final Set<Color?> fills = <Color?>{
        for (int i = 0; i < find.byType(FluentBadge).evaluate().length; i++)
          decorationUnder(tester, find.byType(FluentBadge).at(i)).color,
      };

      // The section's own description names brand, danger, important,
      // informative, severe, success and warning. `severe` genuinely cannot be
      // rendered — Fluent ships no `Status/Severe/*` ramp — and the Badge page
      // says exactly that in its source *and* in `storybook_adaptations.json`,
      // which is the repository's record of every section the API cannot
      // express. Success and warning are ordinary `FluentBadgeColor` values,
      // the Badge page's identical Color section renders both, and neither the
      // source here nor the adaptations file records their absence. Four
      // swatches under a heading promising seven is the section under-
      // documenting its own component.
      expect(
        fills,
        contains(theme.colors.statusSuccessBackground3),
        reason: 'the Color section names success and never renders it',
      );
      expect(
        fills,
        contains(theme.colors.statusWarningBackground3),
        reason: 'the Color section names warning and never renders it',
      );
    });
  });

  group('dot', () {
    final DocsSection section = sectionOf(
      'components-badge-counter-badge--dot',
    );

    testWidgets('the dot is a 6px circle, not a squashed badge', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, loose: true);

      final Finder badge = find.byType(FluentBadge);
      expect(badge, findsOneWidget);
      expect(find.byType(Text), findsNothing);
      // Both overrides have to land or the dot is wrong in a specific,
      // recognisable way: keep the medium minimum and it is a 20px blob, keep
      // the 4px horizontal padding and it is an 8x6 ellipse. Asserting the
      // square is what separates "the style slot works" from "it half works".
      expect(tester.getSize(badge), const Size(6, 6));
      expect(
        decorationUnder(tester, badge).borderRadius,
        FluentRadius.allCircular,
      );
    });

    testWidgets('the dot announces itself', (WidgetTester tester) async {
      await pumpSection(tester, section, loose: true);

      // A dot has no label, no icon and no text of any kind, so without the
      // semantic label it is literally nothing to a screen reader. That is why
      // the demo sets one, and why it is worth asserting rather than assuming.
      final Semantics semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(FluentBadge),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.label, 'Unread');
      expect(semantics.excludeSemantics, isTrue);
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
