import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// [FluentFocusRing] follows React v9, which draws **one** ring, over the Figma
/// file, which draws two on most (not all) components. See
/// `doc/token-divergences.md`.
///
/// [FluentFocusRing.twoTone] keeps Figma's double ring reachable, and the tone
/// assertions still belong to both: `strokeFocus1` and `strokeFocus2` swap
/// between light and dark, so asserting `light.outer == dark.inner` is what
/// proves the tokens were swapped rather than merely recoloured.
void main() {
  const childWidth = 60.0;
  const childHeight = 30.0;
  const childSize = Size(childWidth, childHeight);

  FluentFocusRingPainter painterOf(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.descendant(
                  of: find.byType(FluentFocusRing),
                  matching: find.byType(CustomPaint),
                ),
              )
              .foregroundPainter!
          as FluentFocusRingPainter;

  Future<void> pumpRing(
    WidgetTester tester, {
    required FluentThemeData theme,
    bool visible = true,
    bool twoTone = false,
    BorderRadius borderRadius = FluentRadius.allMedium,
  }) {
    const child = SizedBox(width: childWidth, height: childHeight);
    return tester.pumpWidget(
      FluentTheme(
        data: theme,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: twoTone
                ? FluentFocusRing.twoTone(
                    visible: visible,
                    borderRadius: borderRadius,
                    child: child,
                  )
                : FluentFocusRing(
                    visible: visible,
                    borderRadius: borderRadius,
                    child: child,
                  ),
          ),
        ),
      ),
    );
  }

  group('visibility', () {
    testWidgets('paints nothing while not visible', (tester) async {
      await pumpRing(tester, theme: FluentThemeData.light(), visible: false);
      expect(painterOf(tester).visible, isFalse);
      expect(find.byType(FluentFocusRing), paintsNothing);
    });

    testWidgets('paints the ring as soon as it becomes visible', (
      tester,
    ) async {
      await pumpRing(tester, theme: FluentThemeData.light(), visible: false);
      await pumpRing(tester, theme: FluentThemeData.light());
      // A single zero-duration pump, deliberately: upstream has no transition
      // on focus, so there is no frame in which the ring is half-drawn — and
      // therefore nothing for reduced motion to disable either.
      expect(
        find.byType(FluentFocusRing),
        paints..rrect(strokeWidth: FluentStroke.thick),
      );
    });
  });

  group('tones', () {
    testWidgets('invert between light and dark rather than being recoloured', (
      tester,
    ) async {
      await pumpRing(tester, theme: FluentThemeData.light());
      final light = painterOf(tester);
      final lightOuter = light.outer;
      final lightInner = light.inner;

      await pumpRing(tester, theme: FluentThemeData.dark());
      final dark = painterOf(tester);

      expect(lightOuter, isNot(lightInner));
      expect(
        lightOuter,
        dark.inner,
        reason: 'strokeFocus1/2 swap between themes; they do not shift',
      );
      expect(lightInner, dark.outer);
    });

    testWidgets('takes the outer tone from strokeFocus2 and inner from 1', (
      tester,
    ) async {
      final theme = FluentThemeData.light();
      await pumpRing(tester, theme: theme);
      final painter = painterOf(tester);
      expect(painter.outer, theme.colors.strokeFocus2);
      expect(painter.inner, theme.colors.strokeFocus1);
    });

    testWidgets('keeps both rings fully opaque in high contrast', (
      tester,
    ) async {
      // High contrast has no translucency to spend: a ring at partial alpha
      // would composite against the canvas and stop being a system colour.
      await pumpRing(tester, theme: FluentThemeData.highContrast());
      final painter = painterOf(tester);
      expect(painter.outer.a, 1.0);
      expect(painter.inner.a, 1.0);
      expect(painter.outer, isNot(painter.inner));
    });
  });

  group('geometry', () {
    testWidgets('is 2 outside and nothing inside, and does not affect layout', (
      tester,
    ) async {
      await pumpRing(tester, theme: FluentThemeData.light());
      final painter = painterOf(tester);
      expect(painter.outerWidth, 2.0);
      expect(painter.innerWidth, 0.0);
      expect(
        tester.getSize(find.byType(FluentFocusRing)),
        childSize,
        reason: 'a foreground painter must not grow the child',
      );

      // strokeAlign OUTSIDE == a 2px stroke centred one pixel out, and the
      // radius moves out with it, so a 2px ring around a radius-4 component
      // has an outer corner radius of 6 — the same growth CSS applies to a
      // `box-shadow` spread, which is how Tab and Button draw theirs.
      final theme = FluentThemeData.light();
      final rect = Offset.zero & childSize;
      expect(
        find.byType(FluentFocusRing),
        paints..rrect(
          rrect: RRect.fromRectAndRadius(
            rect.inflate(1),
            const Radius.circular(5),
          ),
          color: theme.colors.strokeFocus2,
          strokeWidth: 2.0,
        ),
      );
      expect(
        find.byType(FluentFocusRing),
        isNot(paints..rrect(strokeWidth: FluentStroke.thin)),
        reason: 'React v9 never draws the inner strokeFocus1 ring',
      );
    });

    testWidgets('never lets an adjusted radius go negative', (tester) async {
      await pumpRing(
        tester,
        theme: FluentThemeData.light(),
        twoTone: true,
        borderRadius: BorderRadius.zero,
      );
      final rect = Offset.zero & childSize;
      expect(
        find.byType(FluentFocusRing),
        paints
          ..rrect(
            rrect: RRect.fromRectAndRadius(
              rect.inflate(1),
              const Radius.circular(1),
            ),
          )
          ..rrect(
            rrect: RRect.fromRectAndRadius(rect.deflate(0.5), Radius.zero),
          ),
      );
    });
  });

  group('twoTone', () {
    testWidgets('adds the inner ring, reproducing Figma exactly', (
      tester,
    ) async {
      final theme = FluentThemeData.light();
      await pumpRing(tester, theme: theme, twoTone: true);
      final painter = painterOf(tester);
      expect(painter.outerWidth, 2.0);
      expect(painter.innerWidth, 1.0);

      // strokeAlign INSIDE == a 1px stroke centred half a pixel in. The radii
      // move by the same deltas as the rects, so the arcs stay concentric.
      final rect = Offset.zero & childSize;
      expect(
        find.byType(FluentFocusRing),
        paints
          ..rrect(
            rrect: RRect.fromRectAndRadius(
              rect.inflate(1),
              const Radius.circular(5),
            ),
            color: theme.colors.strokeFocus2,
            strokeWidth: 2.0,
          )
          ..rrect(
            rrect: RRect.fromRectAndRadius(
              rect.deflate(0.5),
              const Radius.circular(3.5),
            ),
            color: theme.colors.strokeFocus1,
            strokeWidth: 1.0,
          ),
      );
    });
  });

  group('shouldRepaint', () {
    const outer = Color(0xFF000001);
    const inner = Color(0xFF000002);
    const base = FluentFocusRingPainter(
      visible: true,
      outer: outer,
      inner: inner,
      borderRadius: FluentRadius.allMedium,
    );

    test('repaints on any change to the fields the tests assert', () {
      expect(base.shouldRepaint(base), isFalse);
      expect(
        base.shouldRepaint(
          const FluentFocusRingPainter(
            visible: false,
            outer: outer,
            inner: inner,
            borderRadius: FluentRadius.allMedium,
          ),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const FluentFocusRingPainter(
            visible: true,
            outer: inner,
            inner: inner,
            borderRadius: FluentRadius.allMedium,
          ),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const FluentFocusRingPainter(
            visible: true,
            outer: outer,
            inner: outer,
            borderRadius: FluentRadius.allMedium,
          ),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const FluentFocusRingPainter(
            visible: true,
            outer: outer,
            inner: inner,
            borderRadius: FluentRadius.allMedium,
            outerWidth: FluentStroke.thicker,
          ),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const FluentFocusRingPainter(
            visible: true,
            outer: outer,
            inner: inner,
            borderRadius: FluentRadius.allMedium,
            innerWidth: FluentStroke.thin,
          ),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const FluentFocusRingPainter(
            visible: true,
            outer: outer,
            inner: inner,
            borderRadius: FluentRadius.allLarge,
          ),
        ),
        isTrue,
      );
    });
  });
}
