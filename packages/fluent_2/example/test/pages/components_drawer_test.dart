import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Drawer's nineteen sections split cleanly in two. An overlay drawer paints
/// nothing where it is written — the panel is in the [Overlay], over a scrim —
/// so the only proof it opened is that the panel is on screen and the scrim is
/// intercepting. An inline drawer paints in place and takes width from its
/// siblings, so the proof is that *the page beside it moved*.
///
/// That second half is what these tests lean on hardest: `type`, `size`,
/// `position` and the custom width field all end in geometry, and geometry is
/// the one thing a knob cannot fake.
void main() {
  const String page = 'components-drawer';

  /// The drawer transition is size-keyed — 250ms at small through 500ms at
  /// full — and the panel is only removed once it reaches zero, so a bare
  /// `settle` reads a half-open drawer.
  Future<void> settleDrawer(WidgetTester tester) async {
    await settle(tester);
    await tester.pump(const Duration(milliseconds: 600));
    await settle(tester);
  }

  group('default', () {
    final DocsSection section = sectionOf('components-drawer--default');

    testWidgets('the type radio swaps an overlay drawer for an inline one', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder group = find.byType(FluentRadioGroup<FluentDrawerType>);
      final double pageLeft = tester.getRect(group).left;

      // The page's primary knob, so it is driven with a pointer.
      await mouseClick(tester, find.text('Inline'));
      expect(
        tester.widget<FluentRadioGroup<FluentDrawerType>>(group).value,
        FluentDrawerType.inline,
      );
      expect(
        find.text('Toggle'),
        findsOneWidget,
        reason:
            'the trigger relabels itself: an inline drawer toggles where '
            'an overlay one opens',
      );
      expect(
        tester.getRect(group).left,
        pageLeft,
        reason: 'a closed inline drawer takes no width',
      );

      await tapAndSettle(tester, find.text('Toggle'));
      await settleDrawer(tester);
      expect(find.text('Drawer content'), findsOneWidget);
      expect(
        tester.getRect(group).left,
        greaterThan(pageLeft + 100),
        reason:
            'this is the whole difference between the two types: an inline '
            'drawer pushes the page beside it, an overlay one floats over it',
      );

      // Round trip, both halves: closing gives the width back, and switching
      // back to overlay stops the panel taking any.
      await tapAndSettle(tester, find.text('Toggle'));
      await settleDrawer(tester);
      expect(tester.getRect(group).left, pageLeft);
      await tapAndSettle(tester, find.text('Overlay (Default)'));
      expect(find.text('Open'), findsOneWidget);

      await tapAndSettle(tester, find.text('Open'));
      await settleDrawer(tester);
      expect(find.text('Drawer content'), findsOneWidget);
      expect(
        tester.getRect(group).left,
        pageLeft,
        reason: 'an open overlay drawer must not move the page at all',
      );
    });
  });

  group('overlay', () {
    final DocsSection section = sectionOf('components-drawer--overlay');

    testWidgets('the panel opens over the page behind a scrim', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Drawer content'), findsNothing);
      expect(scrims(tester), isEmpty);

      await tapAndSettle(tester, find.text('Open Drawer'));
      await settleDrawer(tester);
      expect(find.text('Overlay Drawer'), findsOneWidget);
      expect(
        scrims(tester).single.a,
        greaterThan(0),
        reason: 'an overlay drawer is modal, which means a dimmed scrim',
      );
      // Anchored to the leading edge and spanning the full viewport height,
      // which is what makes it an overlay rather than a card.
      final Rect panel = tester.getRect(find.text('Overlay Drawer'));
      expect(panel.left, lessThan(100));
      expect(
        tester.getRect(find.text('Drawer content')).bottom,
        closeTo(tester.view.physicalSize.height, 1),
      );
    });

    testWidgets('the close button, Escape and the scrim each dismiss it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      Future<void> reopen() async {
        await tapAndSettle(tester, find.text('Open Drawer'));
        await settleDrawer(tester);
        expect(find.text('Overlay Drawer'), findsOneWidget);
      }

      await reopen();
      await tapAndSettle(tester, find.byIcon(drawerCloseIcon));
      await settleDrawer(tester);
      expect(find.text('Overlay Drawer'), findsNothing, reason: 'close button');

      await reopen();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleDrawer(tester);
      expect(find.text('Overlay Drawer'), findsNothing, reason: 'Escape');

      await reopen();
      // Far past the panel's trailing edge: this can only be the scrim.
      await tester.tapAt(const Offset(1400, 700));
      await settleDrawer(tester);
      expect(find.text('Overlay Drawer'), findsNothing, reason: 'scrim press');
    });
  });

  group('overlay no modal', () {
    testWidgets('the scrim is cleared so the page behind still reads', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-drawer--overlay-no-modal'),
      );
      await tapAndSettle(tester, find.text('Toggle'));
      await settleDrawer(tester);
      expect(find.text('Overlay Drawer'), findsOneWidget);
      expect(
        scrims(tester).single.a,
        0,
        reason:
            'the section clears scrimColor, which is the only half of '
            'non-modal FluentDrawer can express',
      );

      // Closed from the header, not from the toggle: this drawer is anchored
      // to the leading edge and the toggle sits right behind it, so a press
      // aimed at the toggle lands on the panel.
      await tapAndSettle(tester, find.byIcon(drawerCloseIcon));
      await settleDrawer(tester);
      expect(find.text('Overlay Drawer'), findsNothing);

      // Round trip: the toggle is reachable again once the panel is gone.
      await tapAndSettle(tester, find.text('Toggle'));
      await settleDrawer(tester);
      expect(find.text('Overlay Drawer'), findsOneWidget);
    });
  });

  group('overlay inside container', () {
    testWidgets('the panel stays inside the container it was mounted in', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-drawer--overlay-inside-container'),
      );
      final Rect container = tester.getRect(
        find.text('Drawer will be rendered within this container'),
      );

      await tapAndSettle(tester, find.text('Open Drawer'));
      await settleDrawer(tester);
      expect(find.text('Overlay Drawer'), findsOneWidget);

      // The point of `mountNode`: the panel and its scrim are bounded by the
      // Overlay inside the box, not by the page. A panel that escaped to the
      // app's root overlay would run the full 1400 of viewport height.
      final Rect panel = tester.getRect(find.text('Drawer content'));
      expect(panel.left, greaterThanOrEqualTo(container.left - 1));
      expect(
        panel.bottom,
        lessThan(container.top + 300),
        reason: 'the container is 300 tall; the panel cannot outgrow it',
      );
    });
  });

  group('inline', () {
    final DocsSection section = sectionOf('components-drawer--inline');

    testWidgets('each toggle opens its own drawer and narrows the page', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Start Inline Drawer'), findsNothing);
      expect(find.text('End Inline Drawer'), findsNothing);
      final Rect page = tester.getRect(find.byType(ListView));

      await tapAndSettle(tester, find.text('Toggle start'));
      await settleDrawer(tester);
      expect(find.text('Start Inline Drawer'), findsOneWidget);
      expect(
        tester.getRect(find.byType(ListView)).left,
        greaterThan(page.left + 100),
        reason: 'a start drawer takes width off the leading edge of the page',
      );

      await tapAndSettle(tester, find.text('Toggle end'));
      await settleDrawer(tester);
      expect(find.text('End Inline Drawer'), findsOneWidget);
      expect(
        tester.getRect(find.byType(ListView)).right,
        lessThan(page.right - 100),
        reason: 'and an end drawer takes it off the trailing edge',
      );

      // Round trip: each drawer's own close button closes only itself.
      await tapAndSettle(tester, find.byIcon(drawerCloseIcon).first);
      await settleDrawer(tester);
      expect(find.text('Start Inline Drawer'), findsNothing);
      expect(find.text('End Inline Drawer'), findsOneWidget);
    });

    testWidgets('the bottom toggle is inert', (WidgetTester tester) async {
      await pumpSection(tester, section);
      // FluentDrawerPosition is start/end only — the drawer anchors to a
      // vertical edge in reading order — so upstream's third drawer has no
      // counterpart and the button that would open it must say so by being
      // disabled rather than by doing nothing when pressed.
      expect(
        tester
            .widget<FluentButton>(
              find.widgetWithText(FluentButton, 'Toggle bottom'),
            )
            .onPressed,
        isNull,
      );
    });
  });

  group('position', () {
    testWidgets('start and end anchor the drawer to opposite edges', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-drawer--position'));

      await tapAndSettle(tester, find.text('Open start'));
      await settleDrawer(tester);
      expect(find.text('Start Drawer'), findsOneWidget);
      final double atStart = tester.getRect(find.text('Drawer content')).left;
      expect(atStart, lessThan(200));

      await tester.tapAt(const Offset(1400, 700));
      await settleDrawer(tester);
      await tapAndSettle(tester, find.text('Open end'));
      await settleDrawer(tester);
      expect(
        find.text('End Drawer'),
        findsOneWidget,
        reason: 'the header retitles itself with the position',
      );
      expect(
        tester.getRect(find.text('Drawer content')).left,
        greaterThan(atStart + 1000),
        reason: 'end has to move the panel to the other side of the page',
      );

      expect(
        tester
            .widget<FluentButton>(
              find.widgetWithText(FluentButton, 'Open Bottom'),
            )
            .onPressed,
        isNull,
        reason: 'there is no bottom edge to anchor to',
      );
    });
  });

  group('size', () {
    testWidgets('each size widens the panel and retitles the header', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-drawer--size'));

      // Each size is picked *before* the drawer opens: an open overlay drawer
      // lays its scrim over the radio group, so a press aimed at a radio while
      // it is open lands on the scrim and dismisses instead.
      double? previous;
      for (final MapEntry<String, String> size in <String, String>{
        'Small (Default)': 'Small (Default) size',
        'Medium': 'Medium size',
        'Large': 'Large size',
        'Full': 'Full size',
      }.entries) {
        await tapAndSettle(tester, find.text(size.key));
        await tapAndSettle(tester, find.text('Open Drawer'));
        await settleDrawer(tester);

        expect(
          find.text(size.value),
          findsOneWidget,
          reason: '${size.key}: the header names the size it is drawn at',
        );
        // The drawer is anchored to the trailing edge, so a wider panel starts
        // further left. Strictly further, at every step of the ramp.
        final double left = tester.getRect(find.text('Drawer content')).left;
        if (previous != null) {
          expect(
            left,
            lessThan(previous),
            reason: '${size.key} must be wider than the size before it',
          );
        }
        previous = left;

        // Closed from the header rather than from the scrim: at `full` the
        // panel is the whole viewport, so there is no scrim left to press.
        await tapAndSettle(tester, find.byIcon(drawerCloseIcon));
        await settleDrawer(tester);
        expect(find.text(size.value), findsNothing);
      }
    });
  });

  group('custom size', () {
    testWidgets('the width field resizes the panel', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-drawer--custom-size'));
      await tapAndSettle(tester, find.text('Open Drawer'));
      await settleDrawer(tester);
      expect(find.text('Drawer with 600px size'), findsOneWidget);
      final double at600 = tester.getRect(find.text('Drawer content')).left;

      await tester.tapAt(const Offset(40, 700));
      await settleDrawer(tester);
      await tester.enterText(find.byType(FluentInput), '400');
      await settle(tester);
      expectClean(tester, 'typing a width');

      await tapAndSettle(tester, find.text('Open Drawer'));
      await settleDrawer(tester);
      expect(
        find.text('Drawer with 400px size'),
        findsOneWidget,
        reason: 'the header reads back what was typed',
      );
      expect(
        tester.getRect(find.text('Drawer content')).left,
        greaterThan(at600),
        reason:
            'a 400-wide panel on the trailing edge starts 200 further '
            'right than a 600-wide one — the field has to reach the style, '
            'not only the label',
      );
    });
  });

  group('separator', () {
    testWidgets('both drawers start open and each toggle closes its own', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-drawer--separator'));
      expect(
        find.text('Drawer with separator'),
        findsNWidgets(2),
        reason: 'this section opens both inline drawers up front',
      );

      await tapAndSettle(tester, find.text('Toggle start'));
      await settleDrawer(tester);
      expect(find.text('Drawer with separator'), findsOneWidget);

      await tapAndSettle(tester, find.text('Toggle end'));
      await settleDrawer(tester);
      expect(find.text('Drawer with separator'), findsNothing);

      // Round trip.
      await tapAndSettle(tester, find.text('Toggle start'));
      await settleDrawer(tester);
      expect(find.text('Drawer with separator'), findsOneWidget);
    });
  });

  group('with title', () {
    testWidgets('the three headings are announced at their own levels', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-drawer--with-title'));
      expect(find.text('Drawer with title'), findsOneWidget);
      expect(find.text('Drawer with custom tag'), findsOneWidget);
      expect(find.text('Drawer with title and action'), findsOneWidget);

      // Upstream's `heading` prop picks the HTML tag; what carries across is
      // the heading level, and the middle title is the one that overrides it.
      expect(headingLevelOf(tester, find.text('Drawer with title')), 2);
      expect(headingLevelOf(tester, find.text('Drawer with custom tag')), 1);
      expect(
        headingLevelOf(tester, find.text('Drawer with title and action')),
        2,
      );
      expect(
        find.byIcon(drawerCloseIcon),
        findsOneWidget,
        reason: 'only the third title carries an action',
      );
    });
  });

  group('with navigation', () {
    testWidgets('the toolbar rides in the header and closes the drawer', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-drawer--with-navigation'),
      );
      await tapAndSettle(tester, find.text('Open Drawer'));
      await settleDrawer(tester);

      expect(find.text('Title goes here'), findsOneWidget);
      expect(find.byType(FluentToolbar), findsOneWidget);
      for (final String label in <String>[
        'Back',
        'Reload content',
        'Settings',
        'Close panel',
      ]) {
        expect(
          find.bySemanticsLabel(label),
          findsWidgets,
          reason: '$label is icon-only, so its accessible name is all it has',
        );
      }

      await tapAndSettle(tester, find.bySemanticsLabel('Close panel'));
      await settleDrawer(tester);
      expect(find.text('Title goes here'), findsNothing);
    });
  });

  group('with scroll', () {
    testWidgets('the body scrolls while the header stays put', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-drawer--with-scroll'));
      expect(
        find.byType(FluentDrawer),
        findsNWidgets(4),
        reason: 'the section is the four header/footer combinations',
      );
      expect(find.text('Title goes here'), findsNWidgets(2));
      expect(find.text('Primary'), findsNWidgets(2));

      // The second drawer is the one with a header and no footer, so it is
      // where "the header stays put" can actually be observed.
      final Finder body = find.bySemanticsLabel('Example scrolling content');
      expect(body, findsNWidgets(4));
      final Finder copy = find.descendant(
        of: body.at(1),
        matching: find.byType(Text),
      );
      final double headerTop = tester
          .getRect(find.text('Title goes here').first)
          .top;
      final double before = tester.getRect(copy.first).top;

      await tester.drag(body.at(1), const Offset(0, -120));
      await settle(tester);
      expectClean(tester, 'scrolling the drawer body');
      expect(
        tester.getRect(copy.first).top,
        lessThan(before),
        reason: 'the body slot is what scrolls',
      );
      expect(
        tester.getRect(find.text('Title goes here').first).top,
        headerTop,
        reason: 'the header is outside it',
      );
    });
  });

  group('motion', () {
    testWidgets('the transition slides the panel in, disabled lands it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-drawer--motion-custom'));
      await tester.tap(find.text('Toggle Drawer'));
      // Two frames: one to run the post-frame callback, one to build.
      await tester.pump();
      await tester.pump();
      final double arriving = tester.getRect(find.text('Default Drawer')).left;
      await settleDrawer(tester);
      final double landed = tester.getRect(find.text('Default Drawer')).left;
      expect(
        arriving,
        lessThan(landed),
        reason:
            'the panel starts offscreen towards the edge it lives on and '
            'travels in — a drawer that simply appeared would read the same '
            'left on both frames',
      );

      await pumpSection(
        tester,
        sectionOf('components-drawer--motion-disabled'),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump();
      final Rect first = tester.getRect(find.text('Drawer content'));
      await settleDrawer(tester);
      expect(
        tester.getRect(find.text('Drawer content')),
        first,
        reason:
            'disableAnimations schedules no frames at all: the drawer is '
            'already where it is going on the frame it appears',
      );
    });

    testWidgets('the type radio still drives the motion-disabled drawer', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-drawer--motion-disabled'),
      );
      final Finder group = find.byType(FluentRadioGroup<FluentDrawerType>);
      final double pageLeft = tester.getRect(group).left;

      await tapAndSettle(tester, find.text('Inline'));
      expect(find.text('Toggle'), findsOneWidget);
      await tapAndSettle(tester, find.text('Toggle'));
      await settleDrawer(tester);
      expect(
        tester.getRect(group).left,
        greaterThan(pageLeft + 100),
        reason: 'inline still takes width from the page with motion off',
      );
    });
  });

  group('multiple levels', () {
    testWidgets('the calendar button and Next push level 2 in; Back returns', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-drawer--multiple-levels'),
      );
      await tapAndSettle(tester, find.text('Open Drawer'));
      await settleDrawer(tester);
      expect(find.text('Level 1 content'), findsOneWidget);
      expect(find.text('Level 2 content'), findsNothing);
      expect(
        tester
            .widget<FluentButton>(find.widgetWithText(FluentButton, 'Previous'))
            .onPressed,
        isNull,
        reason: 'there is nothing before level 1',
      );
      expect(find.bySemanticsLabel('Back'), findsNothing);

      await tapAndSettle(tester, find.text('Next'));
      await settleDrawer(tester);
      expect(find.text('Level 2 content'), findsOneWidget);
      expect(find.text('Level 1 content'), findsNothing);
      expect(
        find.bySemanticsLabel('Back'),
        findsWidgets,
        reason: 'the header toolbar grows a Back button at level 2',
      );
      expect(
        tester
            .widget<FluentButton>(find.widgetWithText(FluentButton, 'Next'))
            .onPressed,
        isNull,
        reason: 'and Next has nowhere left to go',
      );

      await tapAndSettle(tester, find.bySemanticsLabel('Back'));
      await settleDrawer(tester);
      expect(find.text('Level 1 content'), findsOneWidget);

      // The footer button is the other way in, and it has to agree.
      await tapAndSettle(tester, find.text('Next'));
      await settleDrawer(tester);
      expect(find.text('Level 2 content'), findsOneWidget);
      await tapAndSettle(tester, find.text('Previous'));
      await settleDrawer(tester);
      expect(find.text('Level 1 content'), findsOneWidget);
    });
  });

  group('keep rendered in the dom', () {
    testWidgets('a closed drawer leaves the tree entirely', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-drawer--keep-rendered-in-the-dom'),
      );
      await tapAndSettle(tester, find.text('Inline'));
      await tapAndSettle(tester, find.text('Toggle'));
      await settleDrawer(tester);
      expect(find.text('Default Drawer'), findsOneWidget);

      await tapAndSettle(tester, find.text('Toggle'));
      await settleDrawer(tester);
      // The section's own note: FluentDrawer has no `unmountOnClose`, and a
      // closed drawer is genuinely gone — no panel, no scrim, nothing for a
      // screen reader to walk past.
      expect(find.text('Default Drawer'), findsNothing);
      expect(find.text('Drawer content'), findsNothing);
    });
  });

  group('always open', () {
    testWidgets('nothing on the section can close it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-drawer--always-open'));
      expect(find.text('Always open'), findsOneWidget);
      expect(
        find.byIcon(drawerCloseIcon),
        findsNothing,
        reason: 'no onDismiss and no close button is what "always" means',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleDrawer(tester);
      expect(find.text('Always open'), findsOneWidget);

      await tester.tapAt(const Offset(1400, 200));
      await settleDrawer(tester);
      expect(find.text('Always open'), findsOneWidget);
    });
  });

  group('prevent close', () {
    testWidgets('Escape and the scrim are inert; the header button is not', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-drawer--prevent-close'));
      await tapAndSettle(tester, find.text('Open Drawer'));
      await settleDrawer(tester);
      final Finder body = find.textContaining('cannot be closed');
      expect(body, findsOneWidget);

      // Both dismissal paths route through onDismiss, and this section leaves
      // it null — which is upstream's `modalType="alert"` with no handler.
      await tester.tapAt(const Offset(40, 700));
      await settleDrawer(tester);
      expect(body, findsOneWidget, reason: 'the scrim must not close it');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleDrawer(tester);
      expect(body, findsOneWidget, reason: 'nor must Escape');

      await tapAndSettle(tester, find.byIcon(drawerCloseIcon));
      await settleDrawer(tester);
      expect(
        body,
        findsNothing,
        reason: 'the header button is the one way out, so it has to work',
      );
    });
  });

  group('responsive', () {
    testWidgets('inline on a wide viewport, overlay on a narrow one', (
      WidgetTester tester,
    ) async {
      final DocsSection section = sectionOf('components-drawer--responsive');

      await pumpSection(tester, section, size: const Size(1600, 900));
      await settleDrawer(tester);
      expect(
        tester.widget<FluentDrawer>(find.byType(FluentDrawer)).type,
        FluentDrawerType.inline,
      );
      final double wideHint = tester
          .getRect(find.text('Resize the window to see the change'))
          .left;

      await pumpSection(tester, section, size: const Size(600, 900));
      await settleDrawer(tester);
      expect(
        tester.widget<FluentDrawer>(find.byType(FluentDrawer)).type,
        FluentDrawerType.overlay,
        reason: 'the section reads MediaQuery.sizeOf and flips below 720',
      );
      expect(
        tester.getRect(find.text('Resize the window to see the change')).left,
        lessThan(wideHint - 200),
        reason:
            'an overlay drawer stops pushing the page, so the copy behind '
            'it slides back to the leading edge — the type change has to be '
            'visible, not only readable off the widget',
      );
    });
  });

  group('resizable', () {
    final DocsSection section = sectionOf('components-drawer--resizable');

    // Built inside each test, not beside the section: `bySemanticsLabel`
    // throws unless the semantics tree is live, and at group-collection time
    // it is not.
    Finder rule() => find.bySemanticsLabel('Resize drawer');

    testWidgets('dragging the rule resizes the drawer', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final double before = tester
          .getRect(find.text('Resizable content'))
          .width;
      // The panel starts at 320 and the body is inset inside it, so this is
      // what has to be added back to turn a content width into a panel width.
      final double chrome = 320 - before;

      await dragRule(tester, rule(), 120);
      expect(
        tester.getRect(find.text('Resizable content')).width,
        closeTo(before + 120, 1),
        reason: 'the drag delta is the width delta',
      );

      // Clamped at 240: dragging far past it must stop rather than invert.
      await dragRule(tester, rule(), -2000);
      expect(
        tester.getRect(find.text('Resizable content')).width + chrome,
        closeTo(240, 1),
        reason: 'the minimum width holds however far the pointer travels',
      );
    });

    testWidgets('the rule opens a width form that rejects anything under 240', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final double before = tester
          .getRect(find.text('Resizable content'))
          .width;

      await tester.tap(rule().first);
      await settle(tester);
      // The form's field label is 34 characters inside a 320-wide box, which
      // only overflows under the harness's square font — see
      // expectCleanExceptOverflow.
      expectCleanExceptOverflow(tester, 'opening the resize form');
      expect(find.text('Resize drawer'), findsOneWidget);

      await tester.enterText(find.byType(FluentInput), '100');
      await tester.tap(find.text('Resize'));
      await settle(tester);
      expectCleanExceptOverflow(tester, 'submitting 100');
      expect(
        find.textContaining('Recommended minimum width'),
        findsOneWidget,
        reason: 'under the minimum the form has to say so',
      );
      expect(
        tester.getRect(find.text('Resizable content')).width,
        before,
        reason: 'and must not resize the drawer',
      );

      await tester.enterText(find.byType(FluentInput), '500');
      await tester.tap(find.text('Resize'));
      await settle(tester);
      expectCleanExceptOverflow(tester, 'submitting 500');
      expect(
        find.text('Resize drawer'),
        findsNothing,
        reason: 'an accepted width closes the form',
      );
      expect(
        tester.getRect(find.text('Resizable content')).width,
        closeTo(before + (500 - 320), 1),
        reason: 'the typed width has to reach the panel',
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

    testWidgets('every section unmounts after its first affordance is used', (
      WidgetTester tester,
    ) async {
      // FluentDrawer owns an AnimationController, a FocusScopeNode and — for
      // an overlay drawer — an OverlayEntry, and none of them is exercised by
      // a section that was only mounted and dropped.
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        final Finder buttons = find.byType(FluentButton);
        if (buttons.evaluate().isNotEmpty) {
          await tester.tap(buttons.first, warnIfMissed: false);
          await settleDrawer(tester);
          expectCleanExceptOverflow(tester, 'using ${section.id}');
        }
        await expectCleanTeardown(tester, '${section.id} after use');
      }
    });

    testWidgets('a drawer closed mid-exit still tears down cleanly', (
      WidgetTester tester,
    ) async {
      // The exit removes the OverlayEntry on completion, so unmounting halfway
      // through it is the one moment the entry, the controller and the widget
      // can disagree about who is still alive.
      await pumpSection(tester, sectionOf('components-drawer--overlay'));
      await tapAndSettle(tester, find.text('Open Drawer'));
      await settleDrawer(tester);
      await tester.tap(find.byIcon(drawerCloseIcon));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await expectCleanTeardown(tester, 'a drawer mid-exit');
    });
  });
}

/// Drags [rule] horizontally by exactly [delta] logical pixels.
///
/// Hand-rolled rather than `tester.drag` because a drag recogniser does not
/// report the travel that *claims* the gesture — with `DragStartBehavior.start`
/// the pending offset is dropped — so `drag(offset)` hands the demo
/// `offset - touchSlop` and an assertion written against `offset` would be
/// measuring flutter_test's slop instead of the page's arithmetic. The first
/// move here buys the claim; the second is the whole of what the demo sees.
Future<void> dragRule(WidgetTester tester, Finder rule, double delta) async {
  final TestGesture drag = await tester.startGesture(
    tester.getCenter(rule.first),
  );
  await drag.moveBy(const Offset(40, 0));
  await tester.pump();
  await drag.moveBy(Offset(delta, 0));
  await tester.pump();
  await drag.up();
  await settle(tester);
  expectClean(tester, 'dragging the resize rule by $delta');
}

/// The glyph every drawer header on this page uses to close itself.
///
/// Preferred to `find.bySemanticsLabel('Close')` because two sections put a
/// `Close` *action* in the body as well, and one wraps its header row in a
/// heading annotation that swallows the button's own label.
const IconData drawerCloseIcon = FluentIcons.dismiss_24_regular;

/// Every backdrop currently painted, in tree order.
///
/// A scrim is the one [ColoredBox] an overlay drawer contributes, and its alpha
/// is the whole of "modal" versus "non-modal" here — a distinction no widget
/// property carries, since both are the same slot with a different token in it.
List<Color> scrims(WidgetTester tester) => tester
    .widgetList<ColoredBox>(find.byType(ColoredBox))
    .map((ColoredBox box) => box.color)
    .toList();

/// The heading level announced for [finder], or null when it is not a heading.
///
/// `header` is a plain list of widgets, so a drawer title is whatever the caller
/// put there — the only thing that makes it a *heading* is the [Semantics]
/// annotation wrapped round it, and that is what upstream's `heading` prop
/// actually ports to.
int? headingLevelOf(WidgetTester tester, Finder finder) {
  for (final Semantics wrapper in tester.widgetList<Semantics>(
    find.ancestor(of: finder, matching: find.byType(Semantics)),
  )) {
    final int? level = wrapper.properties.headingLevel;
    if (level != null) return level;
  }
  return null;
}
