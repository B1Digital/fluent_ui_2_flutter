import 'package:fluent_2_web/src/internal/input_modality.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(FluentInputModality.debugReset);
  tearDown(FluentInputModality.debugReset);

  /// Subscribes for the duration of a test.
  ///
  /// The flag's global hooks are installed while — and only while — something
  /// is listening, because `PointerRouter`'s add and remove both assert and a
  /// latched "installed" bool goes stale when the test binding clears the
  /// router between tests. Every real consumer listens (that is the point: the
  /// modality can flip without focus moving), so a test that only read
  /// `.value` would be exercising a state no widget is ever in.
  void listen() {
    void noop() {}
    FluentInputModality.keyboard.addListener(noop);
    addTearDown(() => FluentInputModality.keyboard.removeListener(noop));
  }

  test('starts pointer-first, matching keyborg', () {
    expect(FluentInputModality.keyboard.value, isFalse);
  });

  testWidgets('the hooks are re-armed for every test, not latched once', (
    tester,
  ) async {
    // Guards the exact regression this design exists for: the FIRST test in a
    // file installed the hooks, the binding cleared them at teardown, and
    // every later test silently observed nothing. If subscribing did not
    // re-install, this would fail while the identical assertion above passes.
    listen();
    await tester.pumpWidget(const SizedBox());
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(FluentInputModality.keyboard.value, isTrue);
  });

  testWidgets('a key press raises it and a pointer down clears it', (
    tester,
  ) async {
    listen();
    await tester.pumpWidget(const SizedBox());
    expect(FluentInputModality.keyboard.value, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(FluentInputModality.keyboard.value, isTrue);

    // A real pointer-down, routed the way GestureBinding delivers it.
    final gesture = await tester.createGesture();
    await gesture.down(Offset.zero);
    await gesture.up();
    expect(FluentInputModality.keyboard.value, isFalse);
  });

  testWidgets('typing does not flip it — keyborg ignores character keys', (
    tester,
  ) async {
    listen();
    await tester.pumpWidget(const SizedBox());
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    expect(FluentInputModality.keyboard.value, isFalse);
  });

  testWidgets('notifies listeners so a focused widget can re-evaluate', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox());
    var notifications = 0;
    void listener() => notifications++;
    FluentInputModality.keyboard.addListener(listener);
    addTearDown(() => FluentInputModality.keyboard.removeListener(listener));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    expect(notifications, 1);

    // Idempotent: the same modality twice must not rebuild the world.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(notifications, 1);
  });
}
