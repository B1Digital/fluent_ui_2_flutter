import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

/// A click the way a real mouse makes one: press, dwell, drift a pixel and a
/// half, release.
///
/// Deliberately NOT `tester.tap`, which synthesises a perfectly still touch and
/// so passes even when a control is dead to the pointer people actually use. A
/// `SelectableRegion` puts a pan recogniser over its whole subtree, and for a
/// mouse a pan is claimed after only ONE pixel (`kPrecisePointerHitSlop`) — so
/// every control inside the article's selection region once lost every real
/// click while every `tester.tap` test stayed green. The 90ms dwell is a human
/// press; the 1.5px drift is the hand moving while it presses.
///
/// The pointer is removed afterwards, as a mouse leaving the window would be.
/// Every mouse `TestPointer` shares one device, and `MouseTracker` asserts that
/// added and removed events alternate, so a pointer left added here would trip
/// the next [mouseHover] in the same test.
Future<void> mouseClick(WidgetTester tester, Finder target) async {
  final TestGesture gesture = await tester.startGesture(
    tester.getCenter(target),
    kind: PointerDeviceKind.mouse,
  );
  await tester.pump(const Duration(milliseconds: 90));
  await gesture.moveBy(const Offset(1.5, 1.5));
  await tester.pump(const Duration(milliseconds: 10));
  await gesture.up();
  await gesture.removePointer();
  await tester.pumpAndSettle();
}

/// Rests a mouse pointer on the centre of [target] and pumps one frame.
///
/// Hover only exists for a pointer the tracker has seen *added* — a touch has no
/// hover at all — so this goes through `createGesture(kind: mouse)` and
/// `addPointer` rather than a down/up pair. Returns the gesture so the caller
/// can `removePointer()` it; a pointer left behind keeps hovering whatever sits
/// under it in the next test's tree.
Future<TestGesture> mouseHover(WidgetTester tester, Finder target) async {
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  await gesture.addPointer();
  await gesture.moveTo(tester.getCenter(target));
  await tester.pump();
  return gesture;
}
