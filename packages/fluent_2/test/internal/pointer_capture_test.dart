import 'package:fluent_2/src/internal/pointer_capture.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// [FluentPointerCapture] is the single drag surface behind every colour
/// control, and the one place the gesture arena can be lost.
///
/// The bug it exists to prevent is invisible to a `tester.tap` or `tester.drag`
/// suite: those synthesise a perfectly still touch and a perfectly straight
/// line, with no arena competitor in the tree. Every test here therefore drives
/// a **real** pointer — `startGesture` / `moveBy` / `up` — and most of them
/// mount an ancestor `Scrollable`, because that is the competitor a colour area
/// actually meets on its own docs page.
void main() {
  const surface = Key('surface');

  /// Mounts a capture surface, optionally inside a scrollable, and returns the
  /// positions it reported.
  Future<List<Offset>> pump(
    WidgetTester tester, {
    bool enabled = true,
    bool scrollable = false,
    Size size = const Size(200, 200),
  }) async {
    final reported = <Offset>[];
    final Widget target = FluentPointerCapture(
      enabled: enabled,
      onPointer: reported.add,
      child: SizedBox.fromSize(
        key: surface,
        size: size,
        child: const SizedBox.expand(),
      ),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: scrollable
            // Taller than the 600px test viewport, so it really can scroll.
            ? SingleChildScrollView(
                child: Column(
                  children: <Widget>[target, const SizedBox(height: 1200)],
                ),
              )
            : Center(child: target),
      ),
    );
    return reported;
  }

  ScrollPosition positionOf(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable)).position;

  testWidgets('reports on pointer-down, before any movement', (tester) async {
    final reported = await pump(tester);

    final gesture = await tester.startGesture(
      tester.getTopLeft(find.byKey(surface)) + const Offset(30, 40),
    );
    await tester.pump();

    expect(
      reported,
      const <Offset>[Offset(30, 40)],
      reason:
          'upstream jumps the value to the click point from mousedown itself '
          '(useColorArea.ts, handleRootOnMouseDown) — waiting for a move would '
          'make a plain click do nothing',
    );
    await gesture.up();
  });

  testWidgets('keeps reporting after the pointer leaves the surface', (
    tester,
  ) async {
    final reported = await pump(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(surface)),
    );
    await gesture.moveBy(const Offset(400, 0));
    await gesture.up();

    expect(
      reported.last.dx,
      greaterThan(200),
      reason:
          'GestureBinding dispatches moves along the path cached at down, so a '
          'drag off the edge keeps arriving — upstream gets this from a '
          'document-level mousemove listener. The caller clamps, not this.',
    );
  });

  testWidgets('a zero-size box reports nothing', (tester) async {
    final reported = await pump(tester, size: Size.zero);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Center)),
    );
    await gesture.moveBy(const Offset(10, 10));
    await gesture.up();

    expect(
      reported,
      isEmpty,
      reason:
          'a box with no area hit-tests to nothing, so there is no '
          'coordinate to normalise and no division to guard',
    );
  });

  testWidgets('an ancestor Scrollable does not steal the pointer', (
    tester,
  ) async {
    final reported = await pump(tester, scrollable: true);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(surface)),
    );
    // Straight down, well past kTouchSlop — the drag a colour area's Y axis is.
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      positionOf(tester).pixels,
      0,
      reason:
          'EagerGestureRecognizer resolves accepted from addAllowedPointer, so '
          'the arena is swept during the down event and the Scrollable is '
          'rejected before any slop accumulates',
    );
    expect(
      reported.length,
      greaterThan(1),
      reason: 'the vertical drag reached the surface rather than the viewport',
    );
  });

  testWidgets('disabled mounts nothing, so the page still scrolls', (
    tester,
  ) async {
    final reported = await pump(tester, enabled: false, scrollable: true);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(surface)),
    );
    await gesture.moveBy(const Offset(0, -60));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(reported, isEmpty, reason: 'disabled reports nothing');
    expect(
      positionOf(tester).pixels,
      greaterThan(0),
      reason:
          'a disabled control that left its recogniser mounted would claim '
          'every pointer-down in its rectangle and make the page unscrollable '
          'through it — silently, with every "disabled ignores input" '
          'assertion still passing',
    );
    expect(
      // Scoped: `Scrollable` builds a RawGestureDetector of its own, and that
      // one is exactly the competitor this widget must not displace.
      find.descendant(
        of: find.byType(FluentPointerCapture),
        matching: find.byType(RawGestureDetector),
      ),
      findsNothing,
      reason: 'not a disabled recogniser — no recogniser',
    );
  });

  testWidgets('a secondary-button drag is not captured', (tester) async {
    final reported = await pump(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(surface)),
      buttons: kSecondaryButton,
    );
    await gesture.moveBy(const Offset(20, 20));
    await gesture.up();

    expect(
      reported,
      isEmpty,
      reason:
          'allowedButtonsFilter is primary-only: a right-drag must not scrub a '
          'colour, and must not take the arena from a context menu',
    );
  });
}
