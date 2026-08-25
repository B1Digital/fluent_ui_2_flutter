import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// TagGroup has no widget of its own here — upstream's flex container is a
/// `Wrap`, and every setting it would have pushed down is spelled out on each
/// tag. That is exactly what makes this page worth testing: nothing enforces
/// that the tags in one group agree with each other, so "the group is a
/// certain size", "the group is disabled" and "the group dismisses" are claims
/// about a handful of independent widgets rather than about one parent.
///
/// Each section also pairs an inert `FluentTag` row with a `FluentInteractionTag`
/// row, and the two must not be confused for one another: the whole point of
/// the pairing is that one responds to a pointer and the other does not.
void main() {
  const String page = 'components-tag-taggroup';

  group('default', () {
    testWidgets('the Tag row stays inert while the InteractionTag row lights', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tag-taggroup--default'));
      expect(find.byType(FluentTag), findsNWidgets(3));
      expect(find.byType(FluentInteractionTag), findsNWidgets(3));

      final Finder inert = find.widgetWithText(FluentTag, 'Tag 1');
      final Finder live = find.widgetWithText(FluentInteractionTag, 'Tag 1');
      final FluentThemeData theme = FluentTheme.of(tester.element(inert));

      expect(
        await whileHovering(tester, inert, () => fillOf(tester, inert)!.color),
        theme.colors.neutralBackground3,
        reason: 'a Tag is a label: its surface must hold still under a pointer',
      );
      expect(
        await whileHovering(tester, live, () => fillOf(tester, live)!.color),
        theme.colors.neutralBackground3Hover,
        reason: 'an InteractionTag is a control: its surface must report one',
      );
    });
  });

  group('dismiss', () {
    final DocsSection section = sectionOf('components-tag-taggroup--dismiss');

    testWidgets('the two groups dismiss and reset independently', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentTag), findsNWidgets(3));
      expect(find.byType(FluentInteractionTag), findsNWidgets(3));

      final Finder tagReset = find
          .widgetWithText(FluentButton, 'Reset the example')
          .first;
      final Finder interactionReset = find
          .widgetWithText(FluentButton, 'Reset the example')
          .at(1);

      await tapAndSettle(
        tester,
        _dismissOf(find.widgetWithText(FluentTag, 'Tag 2')),
        what: "the Tag group's Tag 2",
      );
      expect(find.byType(FluentTag), findsNWidgets(2));
      // Untouched: the two groups keep separate state, and a shared list would
      // empty both at once.
      expect(find.byType(FluentInteractionTag), findsNWidgets(3));
      expect(tester.widget<FluentButton>(tagReset).onPressed, isNotNull);

      for (final String label in <String>['Tag 1', 'Tag 2', 'Tag 3']) {
        await tapAndSettle(
          tester,
          _dismissOf(find.widgetWithText(FluentInteractionTag, label)),
          what: "the InteractionTag group's $label",
        );
      }
      expect(find.byType(FluentInteractionTag), findsNothing);
      expect(find.byType(FluentTag), findsNWidgets(2));
      expect(
        tester.widget<FluentButton>(interactionReset).onPressed,
        isNotNull,
      );

      await tapAndSettle(tester, tagReset, what: "the Tag group's reset");
      await tapAndSettle(
        tester,
        interactionReset,
        what: "the InteractionTag group's reset",
      );
      expect(find.byType(FluentTag), findsNWidgets(3));
      expect(find.byType(FluentInteractionTag), findsNWidgets(3));
    });

    testWidgets('a real mouse press dismisses from either group', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(
        tester,
        _dismissOf(find.widgetWithText(FluentTag, 'Tag 1')),
      );
      expect(find.byType(FluentTag), findsNWidgets(2));

      await mouseClick(
        tester,
        _dismissOf(find.widgetWithText(FluentInteractionTag, 'Tag 3')),
      );
      expect(find.byType(FluentInteractionTag), findsNWidgets(2));
      expect(find.text('Tag 3'), findsOneWidget);
    });
  });

  group('sizes', () {
    testWidgets('every tag in a row takes that row\'s height', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tag-taggroup--sizes'));

      // Figma's ramp, and the claim the section title makes: the size reaches
      // all three tags in the row, not only the first.
      for (final (String label, double height) in <(String, double)>[
        ('medium', 32),
        ('small', 24),
        ('extra-small', 20),
      ]) {
        final Finder row = find.widgetWithText(FluentInteractionTag, label);
        expect(row, findsNWidgets(3), reason: '$label row');
        for (int i = 0; i < 3; i++) {
          expect(
            tester.getSize(row.at(i)).height,
            height,
            reason: '$label tag $i',
          );
        }
        // The middle tag is the one upstream marks `shape="circular"`; here
        // that is a border radius handed down through the style.
        expect(
          fillOf(tester, row.at(1))!.borderRadius,
          FluentRadius.allCircular,
          reason: '$label circular tag',
        );
      }
    });
  });

  group('with overflow', () {
    testWidgets('the +n tag opens the overflow menu and a real click picks', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-tag-taggroup--with-overflow'),
        inset: const EdgeInsets.all(80),
      );

      // Five tags render and six live behind the counter, which is the whole
      // of upstream's Overflow/OverflowItem pair as it survives here.
      expect(find.byType(FluentInteractionTag), findsNWidgets(6));
      expect(find.text('Johnie McConnell'), findsOneWidget);
      expect(find.text('Carole Poland'), findsNothing);

      await mouseClick(tester, find.text('+6'));
      expect(
        find.text('Carole Poland'),
        findsOneWidget,
        reason: 'the counter tag must open the menu holding the rest',
      );
      expect(find.text('Elliot Woodward'), findsOneWidget);

      // A menu row that dismisses under a real pointer without ever firing is
      // the failure this catches: the click has to reach the row, not the
      // barrier behind it.
      await mouseClick(tester, find.text('Carole Poland'));
      expect(find.text('Carole Poland'), findsNothing);
      expect(find.byType(FluentInteractionTag), findsNWidgets(6));
    });
  });

  group('disabled', () {
    testWidgets('neither group responds to a pointer', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-tag-taggroup--disabled'));

      final Finder inert = find.widgetWithText(FluentTag, 'Tag 1');
      final Finder live = find.widgetWithText(FluentInteractionTag, 'Tag 1');
      final FluentThemeData theme = FluentTheme.of(tester.element(inert));
      final Color grey = theme.colors.neutralBackgroundDisabled;

      expect(fillOf(tester, inert)!.color, grey);
      expect(fillOf(tester, live)!.color, grey);
      // Disabled has to beat hover rather than merely paint grey at rest: the
      // InteractionTag row would otherwise light under the pointer and read as
      // pressable while doing nothing.
      expect(
        await whileHovering(tester, live, () => fillOf(tester, live)!.color),
        grey,
      );
    });
  });

  group('select', () {
    final DocsSection section = sectionOf('components-tag-taggroup--select');

    testWidgets('pressing a tag toggles it into the read-out and back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Selected values: '), findsNWidgets(2));

      final Finder tag = find
          .widgetWithText(FluentInteractionTag, 'Tag 1')
          .first;
      final FluentThemeData theme = FluentTheme.of(tester.element(tag));

      await mouseClick(tester, tag);
      expect(
        find.text('Selected values: 1'),
        findsOneWidget,
        reason: 'the press must reach the state the read-out prints',
      );
      expect(
        fillOf(tester, tag)!.color,
        theme.colors.brandBackground,
        reason: 'a selected tag renders brand-filled whatever its appearance',
      );

      await mouseClick(tester, tag);
      expect(find.text('Selected values: '), findsNWidgets(2));
      expect(fillOf(tester, tag)!.color, theme.colors.neutralBackground3);
    });

    testWidgets('dismissing a selected tag drops it from the read-out', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      const ValueKey<String> second = ValueKey<String>('select-2');
      await tapAndSettle(tester, find.byKey(second), what: 'the second tag');
      expect(find.text('Selected values: 2'), findsOneWidget);

      await tapAndSettle(
        tester,
        _dismissOf(find.byKey(second)),
        what: "the second tag's dismiss half",
      );
      expect(find.byKey(second), findsNothing);
      // Dismissal has to unselect as well as remove: a value left behind in
      // the selection would keep printing under a tag that is gone.
      expect(find.text('Selected values: '), findsNWidgets(2));

      final Finder reset = find.widgetWithText(
        FluentButton,
        'Reset the example',
      );
      expect(tester.widget<FluentButton>(reset).onPressed, isNull);
      for (final String value in <String>['select-1', 'select-3']) {
        await tapAndSettle(
          tester,
          _dismissOf(find.byKey(ValueKey<String>(value))),
          what: 'the $value dismiss half',
        );
      }
      expect(tester.widget<FluentButton>(reset).onPressed, isNotNull);

      await tapAndSettle(tester, reset, what: 'the reset button');
      expect(find.byKey(second), findsOneWidget);
      expect(find.text('Selected values: '), findsNWidgets(2));
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

/// The dismiss affordance belonging to [tag].
///
/// Every section here draws six of them at once, so an unscoped
/// `find.byType(FluentTagDismissGlyph).at(n)` would silently dismiss from the
/// other group when a row disappears and the indices shift.
Finder _dismissOf(Finder tag) =>
    find.descendant(of: tag, matching: find.byType(FluentTagDismissGlyph));
