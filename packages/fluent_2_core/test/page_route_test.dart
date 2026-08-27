import 'dart:async';

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// [FluentPageRoute.buildTransitions] used to allocate its [CurvedAnimation]
/// inline.
///
/// That reads like a harmless one-liner and is not: `buildTransitions` is
/// driven by the route's own `AnimatedBuilder`, so it runs on *every frame* of
/// the transition, and each [CurvedAnimation] registers a status listener on
/// its parent that nothing ever removes. One push-and-pop leaked a dozen.
///
/// These tests pin the two halves of the fix — the animation is built once and
/// disposed with the route — and are written against
/// [FlutterMemoryAllocations] rather than a frame count, so they keep working
/// if the transition's duration or curve ever changes.
void main() {
  /// A [FluentApp] whose home can push a second page onto a [FluentPageRoute].
  Widget app({required GlobalKey<NavigatorState> navigator}) =>
      FluentApp(navigatorKey: navigator, home: const SizedBox.shrink());

  testWidgets('disposes the CurvedAnimation it builds', (tester) async {
    // `kFlutterMemoryAllocationsEnabled` is a const: without it the binding
    // publishes no events at all and the test would silently pass on zero.
    expect(
      kFlutterMemoryAllocationsEnabled,
      isTrue,
      reason:
          'run with --dart-define=flutter.memory_allocations=true, or in '
          'debug where it defaults on',
    );

    var created = 0;
    var disposed = 0;
    void listener(ObjectEvent event) {
      if (event is ObjectCreated && event.object is CurvedAnimation) created++;
      if (event is ObjectDisposed && event.object is CurvedAnimation) {
        disposed++;
      }
    }

    FlutterMemoryAllocations.instance.addListener(listener);
    addTearDown(
      () => FlutterMemoryAllocations.instance.removeListener(listener),
    );

    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(app(navigator: navigator));

    // `FluentApp` routes `home` through `onGenerateRoute` too, so one
    // FluentPageRoute already exists and is never popped. Only the delta from
    // the pushed route is under test.
    final before = created;

    unawaited(
      navigator.currentState!.push(
        FluentPageRoute<void>(builder: (_) => const SizedBox.shrink()),
      ),
    );
    // Pump *through* the transition rather than settling straight to the end,
    // so a per-frame allocation would actually happen.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(
      created - before,
      1,
      reason:
          'buildTransitions runs once per frame; the CurvedAnimation must '
          'be cached, not rebuilt',
    );

    final settled = disposed;
    navigator.currentState!.pop();
    await tester.pumpAndSettle();

    expect(
      disposed - settled,
      1,
      reason: 'the popped route must dispose the CurvedAnimation it built',
    );
  });

  testWidgets('still animates the page in', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(app(navigator: navigator));

    unawaited(
      navigator.currentState!.push(
        FluentPageRoute<void>(
          builder: (_) => const Text('page', textDirection: TextDirection.ltr),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Mid-transition the page is present but neither fully faded in nor still
    // at its start offset — caching the animation must not freeze it.
    final opacity = tester.widget<FadeTransition>(
      find.ancestor(
        of: find.text('page'),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(opacity.opacity.value, greaterThan(0.0));
    expect(opacity.opacity.value, lessThan(1.0));

    await tester.pumpAndSettle();
    expect(opacity.opacity.value, 1.0);
  });
}
