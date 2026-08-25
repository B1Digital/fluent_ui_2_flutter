import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// CardFooter has one section and no knobs. What it does claim is a layout —
/// two actions at the leading edge and one pinned to the trailing edge by a
/// Spacer, inside a 300 wide slot — and three live buttons. Upstream's story
/// wires no handlers, so the only honest proof that a button still responds is
/// what it paints under a real pointer, which is what the interaction tests
/// read.
void main() {
  const String page = 'components-card-cardfooter';
  final DocsSection section = sectionOf('components-card-cardfooter--default');

  // Wider than the demo's own 300, deliberately. The harness's scroll view
  // hands the demo a TIGHT cross-axis constraint, so the root
  // `SizedBox(width: 300)` is stretched to the viewport and the Spacer takes up
  // the slack — which is the only width at which the relationships below can be
  // read without the overflow the 300 test pins separately.
  const Size viewport = Size(600, 400);

  Finder buttonNamed(String label) => find.widgetWithText(FluentButton, label);
  final Finder moreOptions = find.byWidgetPredicate(
    (Widget w) => w is FluentButton && w.semanticLabel == 'More options',
  );

  group('layout', () {
    testWidgets(
      'the actions lead and the overflow button is pinned to the trailing edge',
      (WidgetTester tester) async {
        await pumpSection(tester, section, size: viewport);

        // The nearest Row above Reply, not `find.byType(Row).first`: the app
        // shell above the demo contributes Rows of its own.
        final Rect row = tester.getRect(
          find
              .ancestor(of: buttonNamed('Reply'), matching: find.byType(Row))
              .first,
        );
        final Rect reply = tester.getRect(buttonNamed('Reply'));
        final Rect share = tester.getRect(buttonNamed('Share'));
        final Rect more = tester.getRect(moreOptions);

        expect(reply.left, row.left);
        expect(
          share.left - reply.right,
          8,
          reason: 'Reply and Share are separated by a single 8px gap',
        );
        // The Spacer is the whole point of the story: without it the overflow
        // button would sit flush against Share instead of at the far end.
        expect(more.right, row.right);
        expect(
          more.left - share.right,
          greaterThan(8),
          reason: 'the Spacer must push the overflow button clear of Share',
        );
      },
    );

    testWidgets('the footer fits the 300 wide slot it declares', (
      WidgetTester tester,
    ) async {
      // The demo's own declared width, which is what the showroom actually
      // renders it at: the shell aligns each story with LOOSE constraints, so
      // its `SizedBox(width: 300)` is honoured there and the row has 300 to
      // spend. Two 126 wide buttons, an 8 gap and a 44 wide overflow button
      // need 304, so the story overflows in the app while `render_test`'s
      // 1600-wide tight constraint hides it.
      await pumpSection(tester, section, size: const Size(300, 400));

      final Rect row = tester.getRect(
        find
            .ancestor(of: buttonNamed('Reply'), matching: find.byType(Row))
            .first,
      );
      expect(
        tester.getRect(moreOptions).right,
        lessThanOrEqualTo(row.right),
        reason: 'the overflow button must not hang out of the footer slot',
      );
    });

    testWidgets('all three actions are live', (WidgetTester tester) async {
      await pumpSection(tester, section, size: viewport);

      for (final Finder button in <Finder>[
        buttonNamed('Reply'),
        buttonNamed('Share'),
        moreOptions,
      ]) {
        expect(
          tester.widget<FluentButton>(button).onPressed,
          isNotNull,
          reason: 'a footer action with no callback is a dead affordance',
        );
      }
    });
  });

  group('interaction', () {
    testWidgets('a real mouse drives Reply through hover and press', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, size: viewport);
      final Finder reply = buttonNamed('Reply');
      Color? fill() => decorationUnder(tester, reply).color;

      final Color? resting = fill();
      final Offset target = tester.getCenter(reply);
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      // Hover and press are read inside one gesture rather than through
      // `mouseClick`, because both fills only exist mid-sequence: a click that
      // begins and ends between two frames is indistinguishable from a button
      // that never reacted at all.
      await mouse.addPointer(location: target);
      await settle(tester);
      final Color? hovered = fill();
      await mouse.down(target);
      await settle(tester);
      final Color? pressed = fill();
      await mouse.up();
      await settle(tester);
      await mouse.removePointer();
      await settle(tester);

      expect(
        hovered,
        isNot(resting),
        reason: 'Reply must react to the pointer',
      );
      expect(pressed, isNot(hovered), reason: 'Reply must react to the press');
      expect(fill(), resting, reason: 'the button must return to rest');
      expectClean(tester, 'driving Reply with a mouse');
    });

    testWidgets('the overflow button reacts to hover', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, size: viewport);
      final Finder glyph = find.descendant(
        of: moreOptions,
        matching: find.byType(Icon),
      );
      // The glyph colour, not the fill: a transparent button's hover token is
      // itself transparent by design, so its whole hover affordance is the icon
      // turning brand-coloured. Reading the fill here would assert nothing.
      Color? glyphColor() => IconTheme.of(tester.element(glyph)).color;

      final Color? resting = glyphColor();
      final Color? hovered = await whileHovering(
        tester,
        moreOptions,
        glyphColor,
      );
      expect(
        hovered,
        isNot(resting),
        reason: 'the overflow button must show it is a target under a mouse',
      );

      await mouseClick(tester, moreOptions);
      expect(glyphColor(), resting, reason: 'the glyph must return to rest');
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section, size: viewport);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}
