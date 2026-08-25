import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// InfoLabel's page is four static demos with one moving part between them: the
/// info button, which raises a tip into the overlay and takes it back down.
/// Every test below drives that trigger and asserts the *tip* appeared, since a
/// trigger that swaps its own glyph and opens nothing is exactly the failure a
/// mount-only test would wave through.
void main() {
  const String page = 'components-infolabel';

  group('default', () {
    final DocsSection section = sectionOf('components-infolabel--default');

    testWidgets('the info button opens and closes the tip', (
      WidgetTester tester,
    ) async {
      // The tip is anchored above its trigger, so a trigger flush against the
      // top of the viewport puts the surface off-screen where nothing can be
      // hit-tested. The inset is room, not behaviour.
      await pumpSection(tester, section, inset: const EdgeInsets.all(120));

      final Finder trigger = find.byType(FluentInfoButton);
      expect(trigger, findsOneWidget);
      // The tip's only plain Text — its body is a Text.rich, which find.text
      // cannot see — and it exists nowhere else on the section.
      expect(find.text('Learn more'), findsNothing);

      await tapAndSettle(tester, trigger, what: 'the info button');
      expect(
        find.text('Learn more'),
        findsOneWidget,
        reason: 'the trigger must raise the tip it was given',
      );

      await tapAndSettle(tester, trigger, what: 'the info button');
      expect(
        find.text('Learn more'),
        findsNothing,
        reason: 'a second press must take the tip back down',
      );
    });

    testWidgets('the info button opens the tip under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(120));

      await mouseClick(tester, find.byType(FluentInfoButton));
      expect(
        find.text('Learn more'),
        findsOneWidget,
        reason:
            'a mouse press on the trigger must open the tip, not just '
            'light it',
      );
    });

    testWidgets('the open trigger swaps to its filled glyph', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(120));

      expect(find.byIcon(FluentIcons.info_16_regular), findsOneWidget);
      expect(find.byIcon(FluentIcons.info_16_filled), findsNothing);

      await tapAndSettle(tester, find.byType(FluentInfoButton));
      // Upstream renders two icon components and shows one; the swap is the
      // only thing that says "open" on a trigger that draws no chrome at rest.
      expect(find.byIcon(FluentIcons.info_16_filled), findsOneWidget);
      expect(find.byIcon(FluentIcons.info_16_regular), findsNothing);
    });

    testWidgets('the tip survives a press on its own link', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(120));
      await tapAndSettle(tester, find.byType(FluentInfoButton));

      await tapAndSettle(tester, find.text('Learn more'), what: 'the tip link');
      // The trigger and the surface share a TapRegion group precisely so that
      // reaching for the link does not dismiss what the link is inside of.
      expect(
        find.text('Learn more'),
        findsOneWidget,
        reason: 'pressing inside the tip must not count as pressing outside it',
      );
    });

    testWidgets('a press outside dismisses the tip', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(120));
      await tapAndSettle(tester, find.byType(FluentInfoButton));
      expect(find.text('Learn more'), findsOneWidget);

      await tester.tapAt(const Offset(20, 20));
      await settle(tester);
      expect(
        find.text('Learn more'),
        findsNothing,
        reason:
            'a tip with no dismiss affordance of its own must close on an '
            'outside press',
      );
    });
  });

  group('required', () {
    testWidgets('the label carries its asterisk before the trigger', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-infolabel--required'),
        inset: const EdgeInsets.all(120),
      );

      expect(find.text('*'), findsOneWidget);
      // The section's whole claim: the indicator is placed *before* the
      // InfoButton, not after it.
      expect(
        tester.getRect(find.text('*')).right,
        lessThanOrEqualTo(tester.getRect(find.byType(FluentInfoButton)).left),
      );

      await tapAndSettle(tester, find.byType(FluentInfoButton));
      expect(find.text('Example info'), findsOneWidget);
    });
  });

  group('size', () {
    final DocsSection section = sectionOf('components-infolabel--size');

    testWidgets('size ramps the label and the trigger together', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(120));

      double heightOf(String label) => tester.getRect(find.text(label)).height;
      // Three distinct line boxes, not three ascending ones. `FluentLabel` maps
      // its size axis onto ramp *names* — caption1, body1, body2 — and Fluent's
      // native ramps order body1 and body2 the other way round from the web one
      // (Android is 16/24 against 14/20), so "large is taller than medium" is
      // true of the web ramp this page deploys on and false of the ramp a VM
      // test resolves. What is platform-independent is that the knob moved all
      // three, which is what this section claims.
      final Set<double> heights = <double>{
        heightOf('Small label'),
        heightOf('Medium label'),
        heightOf('Large label'),
      };
      expect(
        heights,
        hasLength(3),
        reason: 'two rows sharing a line box means size reached neither',
      );

      // "size affects the size of the Label AND InfoButton" — three different
      // glyph components, one per row.
      expect(find.byIcon(FluentIcons.info_12_regular), findsOneWidget);
      expect(find.byIcon(FluentIcons.info_16_regular), findsOneWidget);
      expect(find.byIcon(FluentIcons.info_20_regular), findsOneWidget);
    });

    testWidgets('each row opens its own tip', (WidgetTester tester) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(120));

      const List<String> tips = <String>[
        'Example small InfoLabel',
        'Example medium InfoLabel',
        'Example large InfoLabel',
      ];
      for (int i = 0; i < tips.length; i++) {
        await tapAndSettle(tester, find.byType(FluentInfoButton).at(i));
        expect(
          find.text(tips[i]),
          findsOneWidget,
          reason: 'row $i raised the wrong tip, or none',
        );
        await tapAndSettle(tester, find.byType(FluentInfoButton).at(i));
        expect(find.text(tips[i]), findsNothing);
      }
    });
  });

  group('in a field', () {
    final DocsSection section = sectionOf('components-infolabel--in-field');

    testWidgets('the field keeps its input while the tip is open', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, inset: const EdgeInsets.all(120));

      final Finder input = find.byType(FluentInput);
      await tester.enterText(input, 'typed');
      await settle(tester);

      await tapAndSettle(tester, find.byType(FluentInfoButton));
      expect(find.text('Example info'), findsOneWidget);
      // The label's trigger sits in the field's own layout; raising the tip
      // must not rebuild the control out from under what was typed into it.
      expect(editedText(tester, input), 'typed');
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section, inset: const EdgeInsets.all(120));
        await expectCleanTeardown(tester, section.id);
      }
    });

    testWidgets('a section with its tip open unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section, inset: const EdgeInsets.all(120));
        if (find.byType(FluentInfoButton).evaluate().isEmpty) continue;
        await tapAndSettle(tester, find.byType(FluentInfoButton));
        // An overlay entry outliving the widget that inserted it is a leak the
        // closed-tip teardown above cannot see.
        await expectCleanTeardown(tester, '${section.id} with an open tip');
      }
    });
  });
}
