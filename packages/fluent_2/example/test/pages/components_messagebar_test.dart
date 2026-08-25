import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// MessageBar's page is four static demos and four with moving parts — Dismiss,
/// Animation, Reflow and Manual Layout. The static four still have to prove the
/// axis they exist to show reached the paint: an intent that moves no fill and
/// a shape that rounds nothing are exactly what a mount-only test waves
/// through.
void main() {
  const String page = 'components-messagebar';

  group('default', () {
    testWidgets('the bar carries its title, actions and dismiss affordance', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-messagebar--default'));

      expect(find.byType(FluentMessageBar), findsOneWidget);
      // The title is flowed inline before the body rather than stacked above
      // it, so it reaches the tree as a span of the body's own paragraph.
      expect(
        find.textContaining('Descriptive title'),
        findsOneWidget,
        reason: 'the title slot is not rendering',
      );
      expect(find.text('Action'), findsNWidgets(2));
      expect(find.byIcon(FluentIcons.dismiss_20_regular), findsOneWidget);

      // Nothing here is wired to state — the section's callbacks are all
      // no-ops — so the assertion is that pressing them is safe, which is what
      // an exception on a null callback would break.
      await tapAndSettle(tester, find.text('Action').first);
      await tapAndSettle(
        tester,
        find.byIcon(FluentIcons.dismiss_20_regular),
        what: 'the dismiss button',
      );
      await tapAndSettle(tester, find.text('Link'), what: 'the inline link');
    });
  });

  group('intent', () {
    testWidgets('each intent paints its own surface and glyph', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-messagebar--intent'));

      final Finder bars = find.byType(FluentMessageBar);
      expect(bars, findsNWidgets(4));

      final FluentColors colors = FluentTheme.of(
        tester.element(bars.first),
      ).colors;
      // Declaration order on the page: info, warning, error, success. Error
      // binds the DANGER family, which is the one pairing a reader is most
      // likely to get wrong.
      final List<Color> expected = <Color>[
        colors.neutralBackground3,
        colors.statusWarningBackground1,
        colors.statusDangerBackground1,
        colors.statusSuccessBackground1,
      ];
      for (int i = 0; i < expected.length; i++) {
        expect(
          fillOf(tester, bars.at(i))?.color,
          expected[i],
          reason: 'bar $i is not wearing its intent',
        );
      }

      for (final IconData glyph in <IconData>[
        FluentIcons.info_20_regular,
        FluentIcons.warning_20_filled,
        FluentIcons.error_circle_20_filled,
        FluentIcons.checkmark_circle_20_filled,
      ]) {
        expect(find.byIcon(glyph), findsOneWidget, reason: 'missing $glyph');
      }
    });
  });

  group('shape', () {
    testWidgets('square really squares the corners', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-messagebar--shape'));

      final Finder bars = find.byType(FluentMessageBar);
      expect(bars, findsNWidgets(2));
      // Corner radius is the entire difference between these two demos, and it
      // is invisible to any assertion about text or geometry.
      expect(
        fillOf(tester, bars.first)?.borderRadius,
        isNot(BorderRadius.zero),
      );
      expect(fillOf(tester, bars.last)?.borderRadius, BorderRadius.zero);
    });
  });

  group('actions', () {
    testWidgets('the actions sit inline with the body', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-messagebar--actions'));

      final Rect body = tester.getRect(
        find.textContaining('Descriptive title'),
      );
      final Rect action = tester.getRect(find.text('Action').first);
      // The single-line layout puts the actions in the body's own row; the
      // multi-line one gives them a row of their own, which the Reflow and
      // Manual Layout sections below drive.
      expect(action.center.dy, closeTo(body.center.dy, body.height));
      expect(action.left, greaterThan(body.left));
    });
  });

  group('dismiss', () {
    final DocsSection section = sectionOf('components-messagebar--dismiss');

    testWidgets('add stacks bars, dismiss removes one, clear removes all', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder bars = find.byType(FluentMessageBar);
      expect(bars, findsNothing);

      for (int i = 1; i <= 3; i++) {
        await tapAndSettle(tester, find.text('Add message'));
        expect(bars, findsNWidgets(i), reason: 'add $i did not stack a bar');
      }

      // Newest first, cycling info, warning, error: the middle bar's own
      // dismiss must take that bar and no other, which a demo keying its list
      // by index rather than by id would get wrong.
      final FluentColors colors = FluentTheme.of(
        tester.element(bars.first),
      ).colors;
      expect(
        fillOf(tester, bars.at(1))?.color,
        colors.statusWarningBackground1,
      );
      await tapAndSettle(
        tester,
        find.byIcon(FluentIcons.dismiss_20_regular).at(1),
        what: 'the middle bar\'s dismiss button',
      );
      expect(bars, findsNWidgets(2));
      expect(fillOf(tester, bars.at(0))?.color, colors.statusDangerBackground1);
      expect(fillOf(tester, bars.at(1))?.color, colors.neutralBackground3);

      await tapAndSettle(tester, find.text('Clear'));
      expect(bars, findsNothing, reason: 'Clear left bars behind');
    });

    testWidgets('add stacks a bar under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.text('Add message'));
      expect(
        find.byType(FluentMessageBar),
        findsOneWidget,
        reason:
            'a mouse press on Add message must reach the button, not the '
            'scroll view under it',
      );
    });
  });

  group('animation', () {
    final DocsSection section = sectionOf('components-messagebar--animation');

    testWidgets('the animation radio decides whether entering bars fade in', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      Finder fade() => find.ancestor(
        of: find.byType(FluentMessageBar),
        matching: find.byType(Opacity),
      );

      // One frame, not `settle`: the entry fade is one FluentDuration.normal
      // long, so anything that pumps past it can no longer tell a fade from a
      // bar that simply appeared.
      await tester.tap(find.text('Add message'));
      await tester.pump();
      expect(
        fade(),
        findsOneWidget,
        reason: '"both" must fade an entering bar in',
      );
      expect(
        tester.widget<Opacity>(fade()).opacity,
        lessThan(1),
        reason: 'the fade has to start below full opacity, or it is not a fade',
      );
      await tester.pump(FluentDuration.normal);
      expect(tester.widget<Opacity>(fade()).opacity, closeTo(1, 0.001));
      expectClean(tester, 'fading a bar in');

      await tapAndSettle(tester, find.text('exit-only'));
      expect(
        tester
            .widget<FluentRadioGroup<String>>(
              find.byType(FluentRadioGroup<String>),
            )
            .value,
        'exit-only',
      );
      // The knob has to reach the bars themselves, not just the radio: with no
      // entry animation there is no opacity wrapper left to animate.
      expect(
        fade(),
        findsNothing,
        reason: '"exit-only" must not wrap bars in an entry fade',
      );

      await tapAndSettle(tester, find.text('both'));
      expect(fade(), findsOneWidget, reason: 'the knob must round-trip');
    });

    testWidgets('the radio commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.text('exit-only'));
      expect(
        tester
            .widget<FluentRadioGroup<String>>(
              find.byType(FluentRadioGroup<String>),
            )
            .value,
        'exit-only',
        reason: 'a mouse press on a radio row must commit, not just light it',
      );
    });
  });

  group('reflow', () {
    final DocsSection section = sectionOf('components-messagebar--reflow');

    testWidgets('the width switch reflows the bar', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder switcher = find.byType(FluentSwitch);
      final Finder bar = find.byType(FluentMessageBar);
      expect(tester.widget<FluentSwitch>(switcher).checked, isTrue);
      expect(find.text('Compact width'), findsOneWidget);

      // 600 minus the demo's own padding is under upstream's compact
      // breakpoint, so the bar starts reflowed.
      expect(
        tester.widget<FluentMessageBar>(bar).layout,
        FluentMessageBarLayout.multiLine,
      );
      final double compactWidth = tester.getRect(bar).width;
      final double compactHeight = tester.getRect(bar).height;
      final Rect wrappedAction = tester.getRect(find.text('Action').first);
      final Rect wrappedBody = tester.getRect(
        find.textContaining('Descriptive title'),
      );
      expect(
        wrappedAction.top,
        greaterThanOrEqualTo(wrappedBody.bottom),
        reason: 'the reflowed layout gives the actions a row of their own',
      );

      await tapAndSettle(tester, switcher, what: 'the width switch');
      expect(tester.widget<FluentSwitch>(switcher).checked, isFalse);
      expect(find.text('Full width'), findsOneWidget);
      expect(
        tester.getRect(bar).width,
        greaterThan(compactWidth),
        reason:
            'the switch has to widen the resizable area, not just relabel '
            'itself',
      );
      expect(
        tester.widget<FluentMessageBar>(bar).layout,
        FluentMessageBarLayout.singleLine,
        reason: 'past the breakpoint the bar must stop reflowing',
      );
      expect(
        tester.getRect(bar).height,
        lessThan(compactHeight),
        reason: 'a single-line bar is shorter than the wrapped one',
      );

      await tapAndSettle(tester, switcher, what: 'the width switch');
      expect(tester.widget<FluentSwitch>(switcher).checked, isTrue);
      expect(tester.getRect(bar).width, compactWidth);
      expect(tester.getRect(bar).height, compactHeight);
    });

    testWidgets('the width switch commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.byType(FluentSwitch));
      expect(
        tester.widget<FluentMessageBar>(find.byType(FluentMessageBar)).layout,
        FluentMessageBarLayout.singleLine,
        reason: 'a mouse press on the switch must reflow the bar',
      );
    });
  });

  group('manual layout', () {
    testWidgets('the layout switch moves every bar\'s actions', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-messagebar--manual-layout'),
      );

      final Finder switcher = find.byType(FluentSwitch);
      final Finder bars = find.byType(FluentMessageBar);
      expect(bars, findsNWidgets(4));
      expect(find.text('Single line layout'), findsOneWidget);

      final List<double> singleHeights = <double>[
        for (int i = 0; i < 4; i++) tester.getRect(bars.at(i)).height,
      ];
      final Rect inlineAction = tester.getRect(find.text('Action').first);
      final Rect inlineBody = tester.getRect(
        find.textContaining('Descriptive title').first,
      );
      expect(inlineAction.center.dy, closeTo(inlineBody.center.dy, 12));

      await tapAndSettle(tester, switcher, what: 'the layout switch');
      expect(find.text('Multi line layout'), findsOneWidget);
      for (int i = 0; i < 4; i++) {
        expect(
          tester.widget<FluentMessageBar>(bars.at(i)).layout,
          FluentMessageBarLayout.multiLine,
        );
        expect(
          tester.getRect(bars.at(i)).height,
          greaterThan(singleHeights[i]),
          reason:
              'bar $i did not grow the second row the multi-line layout '
              'gives its actions',
        );
      }
      expect(
        tester.getRect(find.text('Action').first).top,
        greaterThanOrEqualTo(
          tester.getRect(find.textContaining('Descriptive title').first).bottom,
        ),
      );

      await tapAndSettle(tester, switcher, what: 'the layout switch');
      expect(find.text('Single line layout'), findsOneWidget);
      for (int i = 0; i < 4; i++) {
        expect(tester.getRect(bars.at(i)).height, singleHeights[i]);
      }
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

    testWidgets('a section with bars in it unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final String id in <String>[
        'components-messagebar--dismiss',
        'components-messagebar--animation',
      ]) {
        await pumpSection(tester, sectionOf(id));
        await tapAndSettle(tester, find.text('Add message'));
        // Mid-fade, deliberately: a TweenAnimationBuilder torn down while it is
        // still running is where an entry animation would leak its ticker.
        await expectCleanTeardown(tester, '$id with a bar entering');
      }
    });
  });
}
