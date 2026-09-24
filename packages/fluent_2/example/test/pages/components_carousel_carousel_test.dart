import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Carousel's page carries four knob-driven demos — Alignment And Whitespace,
/// Autoplay, Controlled and Eventing — plus six that only have to move under
/// their own chevrons. Each test below drives one control and asserts the
/// *demo* changed, not just that the control did.
void main() {
  const String page = 'components-carousel-carousel';

  group('alignment and whitespace', () {
    final DocsSection section = sectionOf(
      'components-carousel-carousel--alignment-and-whitespace',
    );

    testWidgets('the alignment dropdown moves the card', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder dropdown = find.byType(FluentDropdown<String>);
      expect(dropdown, findsOneWidget);
      final Finder card = find.byType(FluentPersona);

      final double centred = tester.getRect(card.first).left;

      expect(await pickDropdown<String>(tester, dropdown, 'start'), 'start');
      final double atStart = tester.getRect(card.first).left;
      expect(
        atStart,
        lessThan(centred),
        reason: 'start must pull the card toward the leading edge',
      );

      expect(await pickDropdown<String>(tester, dropdown, 'end'), 'end');
      expect(
        tester.getRect(card.first).left,
        greaterThan(centred),
        reason: 'end must push the card toward the trailing edge',
      );

      expect(await pickDropdown<String>(tester, dropdown, 'center'), 'center');
      expect(tester.getRect(card.first).left, closeTo(centred, 0.5));
    });

    testWidgets('the alignment dropdown commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder dropdown = find.byType(FluentDropdown<String>);

      await mouseClick(tester, dropdown);
      expect(
        find.text('start'),
        findsWidgets,
        reason: 'a mouse press on the trigger must open the listbox',
      );

      await mouseClick(tester, find.text('start').last);
      expect(
        tester.widget<FluentDropdown<String>>(dropdown).value,
        'start',
        reason: 'a mouse press on a row must commit, not just dismiss',
      );
    });

    testWidgets('the whitespace switch insets the slide', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder switchFinder = find.byType(FluentSwitch);
      expect(switchFinder, findsOneWidget);
      final Finder card = find.byType(FluentPersona);
      final double before = tester.getRect(card.first).width;

      await tapAndSettle(tester, switchFinder, what: 'the whitespace switch');
      expect(tester.widget<FluentSwitch>(switchFinder).checked, isTrue);
      // The card is a fixed 350 wide, so whitespace cannot shrink it — what it
      // must do is narrow the slide the card sits in, which moves the card.
      expect(tester.getRect(card.first).width, before);

      await tapAndSettle(tester, switchFinder, what: 'the whitespace switch');
      expect(tester.widget<FluentSwitch>(switchFinder).checked, isFalse);
    });
  });

  group('navigation', () {
    testWidgets('the chevrons and the step dots move every carousel', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        if (find.byType(FluentCarousel).evaluate().isEmpty) continue;

        // The page index, not the rendered text: two of these carousels are
        // pure imagery and would compare equal on text alone.
        final double? before = pageOffset(tester);
        final Finder next = find.bySemanticsLabel(
          RegExp('next|forward', caseSensitive: false),
        );
        if (next.evaluate().isNotEmpty && before != null) {
          await tapAndSettle(
            tester,
            next,
            what: '${section.id} next chevron',
            warnIfMissed: false,
          );
          await tester.pump(const Duration(milliseconds: 400));
          expect(
            pageOffset(tester),
            isNot(closeTo(before, 0.01)),
            reason: '${section.id}: the next chevron changed nothing',
          );
        }
        await expectCleanTeardown(tester, section.id);
      }
    });
  });

  // The port's autoplay button has no pressed/toggled semantics (upstream's
  // CarouselAutoplayButton reports aria-pressed), so swapping playLabel for
  // pauseLabel is the only cue a screen reader gets for the playback state.
  group('autoplay button', () {
    testWidgets('every autoplay demo gives play and pause distinct labels', (
      WidgetTester tester,
    ) async {
      final List<String> same = <String>[];
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        for (final FluentCarousel carousel in tester.widgetList<FluentCarousel>(
          find.byType(FluentCarousel),
        )) {
          if (carousel.playLabel != null &&
              carousel.playLabel == carousel.pauseLabel) {
            same.add('${section.id}: "${carousel.playLabel}"');
          }
        }
        await expectCleanTeardown(tester, section.id);
      }
      expect(same, isEmpty, reason: 'identical play/pause labels:\n$same');
    });

    testWidgets('toggling autoplay renames the button', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final Finder toggle = find.byWidgetPredicate(
        (Widget w) =>
            w is Icon &&
            (w.icon == FluentIcons.play_20_regular ||
                w.icon == FluentIcons.pause_20_regular),
      );
      // Default drives the library's in-nav button; Controlled hand-builds
      // its own toggle beside a controlled carousel.
      for (final String id in <String>['default', 'controlled']) {
        await pumpSection(tester, sectionOf('$page--$id'));
        expect(toggle, findsOneWidget, reason: id);
        final IconData? icon = tester.widget<Icon>(toggle).icon;
        final String before = tester.getSemantics(toggle).label;

        await mouseClick(tester, toggle);
        expect(
          tester.widget<Icon>(toggle).icon,
          isNot(icon),
          reason: '$id: the click must toggle autoplay',
        );
        expect(
          tester.getSemantics(toggle).label,
          isNot(before),
          reason: '$id: the autoplay button is "$before" in both states',
        );
        await expectCleanTeardown(tester, id);
      }
      handle.dispose();
    });
  });

  group('first run experience', () {
    testWidgets('the nav takes the brand appearance', (
      WidgetTester tester,
    ) async {
      // The slide copy sits in a fixed 520px frame, and FlutterTest's square
      // glyphs, about twice Selawik's advance, wrap it past the bottom. Half
      // scale lays it out about as a real face does.
      tester.platformDispatcher.textScaleFactorTestValue = 0.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpSection(
        tester,
        sectionOf('components-carousel-carousel--first-run-experience'),
      );
      await mouseClick(tester, find.text('Open Dialog'));
      await settle(tester, frames: 10);

      // Upstream's `<CarouselNav appearance="brand">`: the selected pill is
      // compoundBrandBackground, where the neutral nav's is Foreground1.
      final Finder selected = find.byType(FluentCarouselStep).first;
      final Iterable<Color?> fills = tester
          .widgetList<DecoratedBox>(
            find.descendant(of: selected, matching: find.byType(DecoratedBox)),
          )
          .map((DecoratedBox box) => box.decoration)
          .whereType<BoxDecoration>()
          .where(
            (BoxDecoration d) => d.borderRadius == FluentRadius.allCircular,
          )
          .map((BoxDecoration d) => d.color);
      expect(fills, <Color?>[
        FluentTheme.of(tester.element(selected)).colors.compoundBrandBackground,
      ]);
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

/// Where the first carousel in the tree is scrolled to, in pages.
double? pageOffset(WidgetTester tester) {
  final Finder view = find.byType(PageView);
  if (view.evaluate().isEmpty) return null;
  final PageController? controller = tester
      .widget<PageView>(view.first)
      .controller;
  return controller != null && controller.hasClients ? controller.page : null;
}
