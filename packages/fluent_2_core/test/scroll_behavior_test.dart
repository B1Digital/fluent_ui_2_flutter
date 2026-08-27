import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/foundation.dart';
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

  // ---------------------------------------------------------------------------
  // The scrollbar itself.
  //
  // `buildScrollbar` used to return its child unchanged, on a doc comment
  // claiming Fluent drew its own scrollbar in the UI packages. It did not:
  // `fluent_2` shipped no scrollbar at all, `FluentColors.scrollbarOverlay` was
  // referenced by nothing, and the showroom hand-rolled a `RawScrollbar` with a
  // hardcoded colour to get one. Every consuming app inherited a scrollbar-less
  // UI with no way to opt back in short of replacing the class.
  // ---------------------------------------------------------------------------

  /// Runs [body] with [debugDefaultTargetPlatformOverride] set.
  ///
  /// Reset inside the body rather than from `addTearDown`: the binding verifies
  /// that no foundation debug variable is still set the moment the body
  /// returns, which is *before* tear-downs run.
  Future<void> withPlatform(
    TargetPlatform platform,
    Future<void> Function() body,
  ) async {
    debugDefaultTargetPlatformOverride = platform;
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  /// A scroller on [axis] under a real [FluentApp].
  ///
  /// Settled, not just pumped: on a platform whose font package needs loading
  /// `FluentApp` renders `SizedBox.shrink()` behind a `FutureBuilder` for the
  /// first frame, so a bare `pumpWidget` finds an empty tree.
  Future<void> pumpAxis(
    WidgetTester tester, {
    Axis axis = Axis.vertical,
    FluentThemeData? theme,
  }) async {
    await tester.pumpWidget(
      FluentApp(
        theme:
            theme ??
            FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: SingleChildScrollView(
          scrollDirection: axis,
          child: SizedBox(
            width: axis == Axis.horizontal ? 4000 : 100,
            height: axis == Axis.vertical ? 4000 : 100,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final platform in <TargetPlatform>[
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
  ]) {
    testWidgets('a vertical scroller gets a scrollbar on ${platform.name}', (
      tester,
    ) async {
      await withPlatform(platform, () async {
        await pumpAxis(tester);
        expect(find.byType(RawScrollbar), findsOneWidget);
      });
    });
  }

  for (final platform in <TargetPlatform>[
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.fuchsia,
  ]) {
    testWidgets(
      'a touch platform gets none — the OS draws its own (${platform.name})',
      (tester) async {
        await withPlatform(platform, () async {
          await pumpAxis(tester);
          expect(find.byType(RawScrollbar), findsNothing);
        });
      },
    );
  }

  testWidgets('a horizontal scroller gets none', (tester) async {
    // The thumb would sit on top of whatever the caller put along the bottom
    // edge. `FluentBreadcrumb` and the chart table are both horizontal.
    await withPlatform(TargetPlatform.macOS, () async {
      await pumpAxis(tester, axis: Axis.horizontal);
      expect(find.byType(RawScrollbar), findsNothing);
    });
  });

  testWidgets('the thumb takes colorScrollbarOverlay from the theme', (
    tester,
  ) async {
    final dark = FluentThemeData.dark(fontPlatform: FluentFontPlatform.web);
    await withPlatform(TargetPlatform.macOS, () async {
      await pumpAxis(tester, theme: dark);
      expect(
        tester.widget<RawScrollbar>(find.byType(RawScrollbar)).thumbColor,
        dark.colors.scrollbarOverlay,
        reason:
            'the token exists upstream as colorScrollbarOverlay; a hardcoded '
            'thumb would not follow a dark or high-contrast theme',
      );
    });
  });

  testWidgets('with no FluentTheme above it, RawScrollbar keeps its default', (
    tester,
  ) async {
    // `FluentScrollBehavior` is public and can be handed to a bare
    // `ScrollConfiguration`, so the colour must resolve through `maybeOf`.
    await withPlatform(TargetPlatform.macOS, () async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: MediaQueryData(),
            child: ScrollConfiguration(
              behavior: FluentScrollBehavior(),
              child: SingleChildScrollView(child: SizedBox(height: 4000)),
            ),
          ),
        ),
      );
      expect(
        tester.widget<RawScrollbar>(find.byType(RawScrollbar)).thumbColor,
        isNull,
        reason: 'null lets RawScrollbar fall back rather than throwing',
      );
    });
  });
}
