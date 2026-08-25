import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// A split button is two controls in one container, and everything that can go
/// wrong with it is invisible to a render test: the halves share a fill, a
/// height and a hit rectangle, so a build in which the chevron fires the primary
/// action, or the primary action opens the menu, or one half swallows both,
/// mounts and screenshots perfectly. Every section below is therefore driven a
/// half at a time, and asserted on what the *other* half did not do.
void main() {
  const String page = 'components-button-splitbutton';

  group('default', () {
    final DocsSection section = sectionOf(
      'components-button-splitbutton--default',
    );

    testWidgets('the primary half runs the action and opens nothing', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Primary action button clicked.'), findsNothing);

      await tapAndSettle(
        tester,
        find.text('Example'),
        what: 'the primary half',
      );
      expect(find.text('Primary action button clicked.'), findsOneWidget);
      expect(
        find.text('Item a'),
        findsNothing,
        reason: 'the primary action must not open the menu',
      );
    });

    testWidgets('the chevron half opens the menu and runs nothing', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await openOverlay(tester, chevronOf(0));
      expect(find.text('Item a'), findsOneWidget);
      expect(
        find.text('Primary action button clicked.'),
        findsNothing,
        reason: 'the chevron must not fire the primary action',
      );

      await tapAndSettle(tester, find.text('Item b'), what: 'Item b');
      expect(find.text('Item b'), findsNothing);
    });

    testWidgets('both halves answer a real mouse, separately', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The two halves are adjacent hit targets 24px apart. A synthetic tap
      // lands dead centre; a hand drifts a couple of pixels between press and
      // release, which is exactly where a shared gesture arena or a mis-sized
      // divider would send the click to the wrong half.
      await mouseClick(tester, chevronOf(0));
      await settle(tester, frames: 10);
      expect(find.text('Item a'), findsOneWidget);
      expect(find.text('Primary action button clicked.'), findsNothing);

      await mouseClick(tester, find.text('Item a'));
      expect(find.text('Item a'), findsNothing);

      await mouseClick(tester, find.text('Example'));
      expect(find.text('Primary action button clicked.'), findsOneWidget);
    });

    testWidgets('the rule between the halves is a real boundary', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Rect menu = tester.getRect(menuHalfOf(0));

      // Two clicks two pixels apart, one either side of the 1px rule. The
      // centres already pass; this is where a half that over-reached — a
      // stretched hit box, a `Stack` that let one half paint over the other, a
      // divider drawn inside the wrong target — would send the click to the
      // neighbour, and a user aiming at the chevron would fire the action.
      await mouseClickAt(
        tester,
        Offset(menu.left - 2, menu.center.dy),
        what: "the primary half's inner edge",
      );
      expect(find.text('Primary action button clicked.'), findsOneWidget);
      expect(find.text('Item a'), findsNothing);

      await mouseClickAt(
        tester,
        Offset(menu.left + 2, menu.center.dy),
        what: "the chevron half's inner edge",
      );
      await settle(tester, frames: 10);
      expect(find.text('Item a'), findsOneWidget);
    });

    testWidgets('Tab reaches each half in turn, and Enter drives it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The halves are documented as separate focus stops. Nothing on screen
      // says so — they share a fill and a height — and a pair that collapsed to
      // one stop would leave the menu unreachable without a pointer.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(
        find.text('Primary action button clicked.'),
        findsOneWidget,
        reason: 'the first Tab stop is the primary action',
      );
      expect(find.text('Item a'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester, frames: 10);
      expect(
        find.text('Item a'),
        findsOneWidget,
        reason: 'the second Tab stop is the chevron, and it opens the menu',
      );
    });
  });

  group('shape', () {
    testWidgets('each shape rounds only the outer corners', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-button-splitbutton--shape'),
      );
      expect(find.byType(FluentSplitButton), findsNWidgets(3));

      // The pair reads as one container because each half squares off the two
      // corners it does not own. A half that kept all four would leave a notch
      // in the middle of every split button on the page.
      for (final String label in <String>['Rounded', 'Circular', 'Square']) {
        final BorderRadius primary = radiusOf(tester, primaryHalfOf(label));
        expect(primary.topRight, Radius.zero, reason: '$label, inner corner');
        expect(
          primary.bottomRight,
          Radius.zero,
          reason: '$label, inner corner',
        );
      }

      final BorderRadius rounded = radiusOf(tester, primaryHalfOf('Rounded'));
      final BorderRadius circular = radiusOf(tester, primaryHalfOf('Circular'));
      expect(radiusOf(tester, primaryHalfOf('Square')).topLeft, Radius.zero);
      expect(rounded.topLeft.x, greaterThan(0));
      expect(circular.topLeft.x, greaterThan(rounded.topLeft.x));

      // And the chevron half mirrors it: outer corners on the trailing edge.
      final BorderRadius menu = radiusOf(tester, menuHalfOf(0));
      expect(menu.topLeft, Radius.zero);
      expect(menu.topRight.x, greaterThan(0));
    });
  });

  group('appearance', () {
    testWidgets('each appearance paints a different surface and rule', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-button-splitbutton--appearance'),
      );
      expect(find.byType(FluentSplitButton), findsNWidgets(5));

      final BoxDecoration secondary = decorationUnder(
        tester,
        primaryHalfOf('Default'),
      );
      final BoxDecoration primary = decorationUnder(
        tester,
        primaryHalfOf('Primary'),
      );
      expect(secondary.color!.a, 1);
      expect(primary.color, isNot(secondary.color));
      expect(primary.color!.a, 1);
      for (final String label in <String>['Outline', 'Subtle', 'Transparent']) {
        expect(
          decorationUnder(tester, primaryHalfOf(label)).color!.a,
          0,
          reason: '$label must let the page through',
        );
      }

      // The 1px rule between the halves is not part of either half's
      // decoration — three sides plus two rounded corners is not a shape
      // `BoxDecoration` can express — so it is painted, and the painter is the
      // only place it can be read. Figma leaves subtle and transparent
      // undivided; everything else carries a rule.
      for (final String label in <String>['Default', 'Primary', 'Outline']) {
        expect(
          dividerColourOf(tester, primaryHalfOf(label)),
          isNotNull,
          reason: '$label lost the rule between its halves',
        );
      }
      for (final String label in <String>['Subtle', 'Transparent']) {
        expect(
          dividerColourOf(tester, primaryHalfOf(label)),
          isNull,
          reason: '$label draws a rule Figma has not got',
        );
      }
    });
  });

  group('icon', () {
    final DocsSection section = sectionOf(
      'components-button-splitbutton--icon',
    );

    testWidgets('iconPosition puts the glyph on the side it names', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      const IconData calendar = FluentIcons.calendar_month_20_regular;

      // Two split buttons differing in one enum value. `before` and `after` are
      // pure geometry — no widget property changes, no colour changes — so a
      // build that ignored the prop would look right in every other assertion.
      final Rect before = tester.getRect(
        find.descendant(of: splitButton(0), matching: find.byIcon(calendar)),
      );
      final Rect beforeLabel = tester.getRect(
        find.text('With calendar icon before contents'),
      );
      expect(before.right, lessThanOrEqualTo(beforeLabel.left));

      final Rect after = tester.getRect(
        find.descendant(of: splitButton(1), matching: find.byIcon(calendar)),
      );
      final Rect afterLabel = tester.getRect(
        find.text('With calendar icon after contents'),
      );
      expect(after.left, greaterThanOrEqualTo(afterLabel.right));
      expect(
        after.right,
        lessThan(tester.getRect(menuHalfOf(1)).left + 1),
        reason: 'the icon stays inside the primary half',
      );
    });

    testWidgets('menuIcon replaces the chevron on that button alone', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder filter = find.byIcon(FluentIcons.filter_20_regular);
      expect(filter, findsOneWidget);
      expect(
        find.descendant(of: splitButton(2), matching: filter),
        findsOneWidget,
      );
      expect(
        find.byIcon(FluentIcons.chevron_down_20_regular),
        findsNWidgets(3),
        reason: 'the other three buttons keep the default chevron',
      );
    });

    testWidgets('the icon-only button keeps both halves live', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // Its label is an empty `SizedBox`, so nothing but the semantic label and
      // the tooltip names it — and a primary half with no text is still a
      // primary half.
      final FluentSplitButton button = tester.widget<FluentSplitButton>(
        splitButton(3),
      );
      expect(button.semanticLabel, 'With calendar icon only');
      expect(button.onPressed, isNotNull);
      expect(button.onMenuPressed, isNotNull);

      await openOverlay(tester, chevronOf(3));
      expect(find.text('Item a'), findsOneWidget);
    });
  });

  group('size', () {
    testWidgets('the three ramps are three heights', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-button-splitbutton--size'),
      );
      // Ordering rather than three literals: a labelled half's height is its
      // label's line box plus the ramp's padding, and this harness mounts a bare
      // `FluentApp`, whose default typography is the 16/24 mobile ramp rather
      // than the 14/20 web one the showroom selects.
      final double small = tester.getSize(splitButton(0)).height;
      final double medium = tester.getSize(splitButton(1)).height;
      expect(medium, greaterThan(small));
      expect(tester.getSize(splitButton(2)).height, greaterThan(medium));
    });

    for (final ({String id, String label, double height}) ramp
        in <({String id, String label, double height})>[
          (id: 'size-small', label: 'Small', height: 24),
          (id: 'size-medium', label: 'Medium', height: 32),
          (id: 'size-large', label: 'Large', height: 40),
        ]) {
      testWidgets('${ramp.id} keeps the chevron 24 wide and half-height', (
        WidgetTester tester,
      ) async {
        await pumpSection(
          tester,
          sectionOf('components-button-splitbutton--${ramp.id}'),
        );
        expect(find.byType(FluentSplitButton), findsNWidgets(3));

        for (int i = 0; i < 3; i++) {
          // The chevron half has no size axis at all — Figma draws it from a
          // component that measures 24 in all 25 variants, which is also WCAG
          // 2.2's floor for a target adjacent to another one. A half that took
          // the button's size ramp would shrink below that at Small.
          expect(
            tester.getSize(menuHalfOf(i)).width,
            24,
            reason: 'button $i shrank its chevron on the ${ramp.label} ramp',
          );
          expect(
            tester.getSize(menuHalfOf(i)).height,
            tester.getSize(splitButton(i)).height,
            reason: 'button $i left its chevron floating',
          );
        }

        // The third button carries no label, so its height is the ramp's and
        // nothing else — the one reading no font can move.
        expect(tester.getSize(splitButton(2)).height, ramp.height);
      });
    }
  });

  group('disabled', () {
    final DocsSection section = sectionOf(
      'components-button-splitbutton--disabled',
    );

    testWidgets('a disabled button answers neither half', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      for (final int index in <int>[1, 2]) {
        await tapAndSettle(
          tester,
          splitButton(index),
          what: 'the disabled primary half',
          warnIfMissed: false,
        );
        await tapAndSettle(
          tester,
          chevronOf(index),
          what: 'the disabled chevron half',
          warnIfMissed: false,
        );
        expect(
          find.text('Item a'),
          findsNothing,
          reason: 'button $index has no callbacks and must open nothing',
        );
      }

      await openOverlay(tester, chevronOf(0));
      expect(find.text('Item a'), findsOneWidget);
    });

    testWidgets('a disabled button paints the disabled ramp on both halves', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Color? enabledFill = decorationUnder(
        tester,
        primaryHalfOf('Enabled state'),
      ).color;

      for (final String label in <String>[
        'Disabled state',
        'Disabled focusable state',
      ]) {
        expect(
          decorationUnder(tester, primaryHalfOf(label)).color,
          isNot(enabledFill),
          reason: '"$label" is painted as though it worked',
        );
      }
      // Both halves fall together, because both callbacks are null. A pair whose
      // chevron stayed live-looking beside a greyed action is the arrangement
      // the props exist to express, and it is not this one.
      expect(
        decorationUnder(tester, menuHalfOf(1)).color,
        decorationUnder(tester, primaryHalfOf('Disabled state')).color,
      );
    });
  });

  group('with long text', () {
    testWidgets('the wrapped label grows the pair and stretches the chevron', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-button-splitbutton--with-long-text'),
      );
      const String long =
          'Long text wraps after it hits the max width of the component';
      expect(tester.getSize(find.text(long)).width, 280);

      final double tall = tester.getSize(splitButton(1)).height;
      expect(tall, greaterThan(tester.getSize(splitButton(0)).height));

      // The reason `FluentSplitButton` measures itself with an `IntrinsicHeight`
      // rather than letting the Row size to its children: without it the wrapped
      // label makes the primary half taller and the chevron half is left
      // floating at the size ramp's height, which is the defect this very story
      // exists to show.
      expect(
        tester.getSize(menuHalfOf(1)).height,
        tall,
        reason: 'the chevron half did not stretch to the wrapped label',
      );
      expect(tester.getSize(menuHalfOf(1)).width, 24);
    });
  });

  group('every section', () {
    testWidgets('opens a menu from its first chevron', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        expect(
          find.text('Item a'),
          findsNothing,
          reason: '${section.id} opened unprompted',
        );

        await openOverlay(tester, chevronOf(0));
        expect(
          find.text('Item a'),
          findsOneWidget,
          reason: "${section.id}'s first chevron raised no menu",
        );
        await dismissOverlay(tester);
        expect(find.text('Item a'), findsNothing);
      }
    });

    testWidgets('unmounts without throwing, menu open', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await openOverlay(tester, chevronOf(0));
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// The [index]-th split button on the section, in declaration order.
Finder splitButton(int index) => find.byType(FluentSplitButton).at(index);

/// The chevron half of the [index]-th split button.
///
/// Located by its glyph rather than by its semantic label: the icon is inside
/// the half's own interaction surface, so a press on it lands where a user's
/// press would.
Finder menuHalfOf(int index) => find
    .ancestor(
      of: find.descendant(
        of: splitButton(index),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Icon &&
              (w.icon == FluentIcons.chevron_down_20_regular ||
                  w.icon == FluentIcons.filter_20_regular),
        ),
      ),
      matching: find.byType(FluentInteractive),
    )
    .first;

/// The chevron glyph of the [index]-th split button — what a user presses.
Finder chevronOf(int index) => find
    .descendant(
      of: splitButton(index),
      matching: find.byWidgetPredicate(
        (Widget w) =>
            w is Icon &&
            (w.icon == FluentIcons.chevron_down_20_regular ||
                w.icon == FluentIcons.filter_20_regular),
      ),
    )
    .first;

/// The primary half of the split button whose label reads [label].
Finder primaryHalfOf(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(FluentInteractive))
    .first;

/// The corner radius [half] painted.
BorderRadius radiusOf(WidgetTester tester, Finder half) =>
    decorationUnder(tester, half).borderRadius! as BorderRadius;

/// The colour of the rule [half] draws on its inner edge, or null for none.
///
/// The divider is a foreground painter rather than part of the decoration, so
/// its own field is the only honest answer to "is there a rule".
Color? dividerColourOf(WidgetTester tester, Finder half) {
  final List<FluentSplitButtonEdgePainter> painters = tester
      .widgetList<CustomPaint>(
        find.descendant(of: half, matching: find.byType(CustomPaint)),
      )
      .map((CustomPaint paint) => paint.foregroundPainter)
      .whereType<FluentSplitButtonEdgePainter>()
      .toList();
  return painters.isEmpty ? null : painters.first.dividerColor;
}
