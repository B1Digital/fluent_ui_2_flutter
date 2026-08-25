import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// [FluentScrollBehavior] once overrode `dragDevices` with
/// `PointerDeviceKind.values.toSet()`, which put the MOUSE in the set.
///
/// That is not a cosmetic difference. A scrollable's drag recogniser uses
/// `computeHitSlop`, and for a *precise* pointer that is `kPrecisePointerHitSlop`
/// — one pixel. A real mouse click travels two or three pixels between press and
/// release, so the drag recogniser won the gesture arena, scrolled nothing, and
/// ate the tap. Every button, dropdown row, switch and menu item inside a
/// scrolling page fired only on a pixel-perfect click, which is why the showroom
/// read as "the control does nothing".
///
/// These tests pin the behaviour a mouse must have: the wheel scrolls, a click
/// clicks, and a drag does neither.
void main() {
  /// A button at the top of a tall scroll view, under a real [FluentApp].
  Future<int Function()> pump(WidgetTester tester) async {
    var taps = 0;
    await tester.pumpWidget(
      FluentApp(
        debugShowCheckedModeBanner: false,
        home: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: const SizedBox(
                  key: Key('target'),
                  width: 200,
                  height: 60,
                ),
              ),
              const SizedBox(height: 3000),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return () => taps;
  }

  /// Presses, moves [jitter] pixels, releases — the shape of a human click.
  Future<void> click(
    WidgetTester tester,
    Offset at, {
    required double jitter,
    required PointerDeviceKind kind,
  }) async {
    final pointer = await tester.createGesture(kind: kind);
    await pointer.addPointer(location: at);
    await tester.pumpAndSettle();
    await pointer.down(at);
    await tester.pump(const Duration(milliseconds: 16));
    if (jitter != 0) {
      await pointer.moveTo(at + Offset(jitter, jitter));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await pointer.up();
    await tester.pumpAndSettle();
    await pointer.removePointer();
    await tester.pumpAndSettle();
  }

  testWidgets('a mouse is not a drag device', (WidgetTester tester) async {
    await pump(tester);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));

    expect(
      ScrollConfiguration.of(scrollable.context).dragDevices,
      isNot(contains(PointerDeviceKind.mouse)),
      reason: 'a mouse that can drag-scroll cannot reliably click',
    );
  });

  for (final jitter in <double>[0, 1, 2, 5, 12]) {
    testWidgets('a mouse click carrying ${jitter}px of travel still fires', (
      WidgetTester tester,
    ) async {
      final taps = await pump(tester);
      await click(
        tester,
        tester.getCenter(find.byKey(const Key('target'))),
        jitter: jitter,
        kind: PointerDeviceKind.mouse,
      );

      expect(
        taps(),
        1,
        reason:
            'a ${jitter}px mouse click inside a scroll view must reach the '
            'control, not the scrollable',
      );
    });
  }

  testWidgets('a touch click still fires through its own slop', (
    WidgetTester tester,
  ) async {
    final taps = await pump(tester);
    await click(
      tester,
      tester.getCenter(find.byKey(const Key('target'))),
      jitter: 5,
      kind: PointerDeviceKind.touch,
    );

    expect(taps(), 1);
  });

  testWidgets('a touch drag still scrolls', (WidgetTester tester) async {
    await pump(tester);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(
      scrollable.position.pixels,
      greaterThan(0),
      reason: 'removing the mouse must not have removed touch scrolling',
    );
  });

  testWidgets('the mouse wheel still scrolls', (WidgetTester tester) async {
    await pump(tester);
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));

    final wheel = TestPointer(1, PointerDeviceKind.mouse);
    final at = tester.getCenter(find.byType(SingleChildScrollView));
    await tester.sendEventToBinding(wheel.hover(at));
    await tester.sendEventToBinding(wheel.scroll(const Offset(0, 300)));
    await tester.pumpAndSettle();

    expect(
      scrollable.position.pixels,
      greaterThan(0),
      reason: 'the wheel is how a mouse scrolls, and it must keep working',
    );
  });
}
