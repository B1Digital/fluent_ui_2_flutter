import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Breadcrumb has no knobs — no dropdown, no switch, nothing to turn. Its four
/// sections are driven entirely by their own affordances, so what these tests
/// prove is the other half of the contract: that the trail folds where it says
/// it folds, that the overflow trigger opens and commits under a real mouse,
/// that a truncated crumb hands the whole name back on hover, and that the last
/// crumb really is a marker rather than a link.
void main() {
  const String page = 'components-breadcrumb';

  group('default', () {
    final DocsSection section = sectionOf('components-breadcrumb--default');

    testWidgets('the last crumb is the current page, not a link', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Three of the four crumbs carry an onPressed; the fourth is the page
      // the user is already on. A trail that wrapped all four in an interaction
      // surface would offer a link to nowhere and take a focus stop for it.
      expect(
        find.byType(FluentInteractive),
        findsNWidgets(3),
        reason: 'Item 4 is the current page and must not be interactive',
      );
      expect(
        textStyleOf(tester, find.text('Item 4'))?.fontWeight,
        isNot(textStyleOf(tester, find.text('Item 1'))?.fontWeight),
        reason: 'the current crumb takes the strong ramp, a link does not',
      );
    });

    testWidgets('a crumb answers the pointer before it is pressed', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The icon and the label take different ramps — brand on the glyph,
      // neutral on the text — so hover is the only state that separates them.
      // `tester.tap` synthesises no hover at all, which is why this is the one
      // assertion on this page that a synthetic gesture could never make.
      final Finder crumb = find.ancestor(
        of: find.text('Item 2'),
        matching: find.byType(FluentInteractive),
      );
      final Color? rest = _calendarGlyphColor(tester);
      expect(rest, isNotNull);

      final Color? hovered = await whileHovering(
        tester,
        crumb,
        () => _calendarGlyphColor(tester),
      );
      expect(
        hovered,
        isNot(rest),
        reason: "hovering a crumb must move its glyph off the rest token",
      );
      expect(
        _calendarGlyphColor(tester),
        rest,
        reason: 'and it must come back once the pointer leaves',
      );
    });

    testWidgets('a link crumb commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final String before = textSnapshot(tester);

      // Upstream navigates away from here; this port's callback is a no-op, so
      // what is asserted is that the press reaches the crumb and leaves the
      // trail whole rather than throwing or rebuilding it into something else.
      await mouseClick(tester, find.text('Item 1'));
      expect(textSnapshot(tester), before);
    });
  });

  group('breadcrumb size', () {
    final DocsSection section = sectionOf(
      'components-breadcrumb--breadcrumb-size',
    );

    testWidgets('the size axis is three different heights', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder trails = find.byType(FluentBreadcrumb);
      expect(trails, findsNWidgets(3));

      final double small = tester.getSize(trails.at(0)).height;
      final double medium = tester.getSize(trails.at(1)).height;
      final double large = tester.getSize(trails.at(2)).height;
      // 24 / 32 / 40 are the Figma minimums, and the type ramp on the host
      // platform can push a trail past its own floor — the Android ramp's
      // 24-high body box makes the medium trail 36. What the section promises
      // is three sizes, so the floors are asserted as floors and the ordering
      // is asserted strictly: two trails laying out identically would mean the
      // `size` argument reached nothing.
      expect(small, greaterThanOrEqualTo(24));
      expect(medium, greaterThanOrEqualTo(32));
      expect(large, greaterThanOrEqualTo(40));
      expect(small, lessThan(medium));
      expect(medium, lessThan(large));
    });

    testWidgets('every size renders its own type ramp', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Three trails, three `Item 1`s, in declaration order. Which ramp is
      // biggest is the platform's business — the Android ramp's `body2` is
      // *smaller* than its `body1` — but three sizes resolving to one ramp
      // would mean the size never reached the style.
      final Finder crumbs = find.text('Item 1');
      expect(crumbs, findsNWidgets(3));
      final Set<double?> sizes = <double?>{
        for (int i = 0; i < 3; i++) textStyleOf(tester, crumbs.at(i))?.fontSize,
      };
      expect(sizes, hasLength(3));
    });
  });

  group('breadcrumb with overflow', () {
    final DocsSection section = sectionOf(
      'components-breadcrumb--breadcrumb-with-overflow',
    );

    testWidgets('the middle of the trail is folded behind the trigger', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // `maxDisplayedItems: 5` over eight crumbs: the root stays pinned, the
      // last four stay visible, and 1..3 fold. Asserting the *absent* ones is
      // what makes this a test of the partition rather than of the row count.
      expect(find.text('Item 0'), findsOneWidget);
      for (final String folded in <String>['Item 1', 'Item 2', 'Item 3']) {
        expect(find.text(folded), findsNothing, reason: '$folded must fold');
      }
      for (final String shown in <String>[
        'Item 4',
        'Item 5',
        'Item 6',
        'Item 7',
      ]) {
        expect(find.text(shown), findsOneWidget, reason: '$shown must stay');
      }
    });

    testWidgets('the trigger opens the popup and a row commits under a mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder trigger = find.bySemanticsLabel('More');

      await mouseClick(tester, trigger);
      for (final String folded in <String>['Item 1', 'Item 2', 'Item 3']) {
        expect(
          find.text(folded),
          findsOneWidget,
          reason: 'the open popup must list $folded',
        );
      }

      // A popup can be dismissible-but-not-selectable under a real pointer: the
      // press lands on the scrim rather than the row and the popup closes
      // having chosen nothing. Selecting must close it *and* run the crumb's
      // own callback, so the row has to be the thing that was hit.
      await mouseClick(tester, find.text('Item 2'));
      for (final String folded in <String>['Item 1', 'Item 2', 'Item 3']) {
        expect(
          find.text(folded),
          findsNothing,
          reason: 'picking a row must close the popup',
        );
      }
    });

    testWidgets('a press outside the popup dismisses it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(
        tester,
        find.bySemanticsLabel('More'),
        what: 'the overflow trigger',
      );
      expect(find.text('Item 2'), findsOneWidget);

      // The open popup lays a full-viewport dismiss layer under itself, so a
      // press on inert scenery — here the pinned root crumb — reaches that
      // layer rather than the crumb. Without it a popup opened by a click on
      // nothing would have no way to close, since a click on scenery moves no
      // focus.
      await mouseClick(tester, find.text('Item 0'));
      expect(
        find.text('Item 2'),
        findsNothing,
        reason: 'a press outside the popup must close it',
      );
    });

    testWidgets('the disabled crumb is inert while its neighbours are not', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Item 5 carries `enabled: false` *and* an onPressed, which is the only
      // combination that can be got wrong: a trail that read only the callback
      // would leave it live.
      expect(_interactiveAround(tester, 'Item 5').enabled, isFalse);
      expect(_interactiveAround(tester, 'Item 4').enabled, isTrue);
      expect(_interactiveAround(tester, 'Item 6').enabled, isTrue);
    });
  });

  group('breadcrumb with tooltip', () {
    final DocsSection section = sectionOf(
      'components-breadcrumb--breadcrumb-with-tooltip',
    );

    testWidgets('a name past 30 characters is cut and ellipsed', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(find.text("Item 3 is long. Don't think ab..."), findsOneWidget);
      expect(find.text('Item 5 which is longer than 30...'), findsOneWidget);
      // The whole name is only in the tooltip, which is not up yet.
      expect(
        find.text('Item 5 which is longer than 30 characters'),
        findsNothing,
      );
    });

    testWidgets('hovering a truncated crumb hands back the whole name', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      const String whole = 'Item 5 which is longer than 30 characters';
      // The tooltip is on a 250ms hover delay and comes down again the moment
      // the pointer leaves, so the pointer has to still be resting on the crumb
      // when the assertion runs — which no synthetic tap can arrange.
      final TestGesture mouse = await mouseHover(
        tester,
        find.text('Item 5 which is longer than 30...'),
      );
      expect(
        find.text(whole),
        findsOneWidget,
        reason: 'truncation without the tooltip loses the name outright',
      );

      await mouseAway(tester, mouse);
      expect(
        find.text(whole),
        findsNothing,
        reason: 'the tooltip must come down when the pointer leaves',
      );
    });

    testWidgets('the folded trail keeps its own overflow trigger', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // `Item 6` belongs to the folded middle of the first trail and to no
      // other trail on the page, so it is the one label that answers "did the
      // popup open?" without colliding with the second trail's crumbs.
      expect(find.text('Item 6'), findsNothing);
      await mouseClick(tester, find.bySemanticsLabel('More'));
      expect(
        find.text('Item 6'),
        findsOneWidget,
        reason: 'the overflow popup must list the crumbs it swallowed',
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

    testWidgets('an open overflow popup unmounts without throwing', (
      WidgetTester tester,
    ) async {
      // The popup is an OverlayEntry in another branch of the tree; tearing the
      // trail down while it is inserted is the one order that can leave it
      // behind.
      await pumpSection(
        tester,
        sectionOf('components-breadcrumb--breadcrumb-with-overflow'),
      );
      await tapAndSettle(
        tester,
        find.bySemanticsLabel('More'),
        what: 'the overflow trigger',
      );
      expect(find.text('Item 2'), findsOneWidget);
      await expectCleanTeardown(tester, 'the trail with its popup open');
    });
  });
}

/// The interaction surface wrapping the crumb labelled [label].
FluentInteractive _interactiveAround(WidgetTester tester, String label) =>
    tester.widget<FluentInteractive>(
      find
          .ancestor(
            of: find.text(label),
            matching: find.byType(FluentInteractive),
          )
          .first,
    );

/// The colour the calendar glyph is actually painted in.
///
/// An icon resolves its colour through an inherited [IconTheme], so the `Icon`
/// widget's own `color` is null exactly where the answer lives — the glyph is a
/// paragraph, and its span carries what was resolved.
Color? _calendarGlyphColor(WidgetTester tester) => textStyleOf(
  tester,
  find.descendant(
    of: find.byIcon(FluentIcons.calendar_month_20_regular),
    matching: find.byType(RichText),
  ),
)?.color;
