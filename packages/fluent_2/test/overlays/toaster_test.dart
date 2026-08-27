import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/internal/input_modality.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `FluentToaster` is the queue, the corner, the stack, the clock and the
/// motion. `FluentToast` — the surface — is covered in `toast_test.dart`.
///
/// The three things most likely to be quietly broken about an overlay component
/// each get their own group here:
///
/// * **the theme crossing the boundary.** The toasts build inside the
///   `Overlay`, in a different branch of the tree, so a `FluentThemeOverride`
///   wrapping the toaster only reaches them because `InheritedTheme.capture` is
///   taken from the toaster's own context. Resolving inside the overlay's
///   builder would silently pick up the app root's theme and nothing else would
///   fail.
/// * **reduced motion.** Every entrance and exit here is animated, and a
///   600ms `CollapseDelayed` that ignores `MediaQuery.disableAnimations` is a
///   600ms accessibility bug.
/// * **focus.** A toast must not steal focus, must be reachable, must go away
///   on Escape, and must hand focus back to its trigger when it does.
void main() {
  const triggerKey = Key('trigger');
  const bodyKey = Key('body');

  late FluentToastController controller;
  setUp(() => controller = FluentToastController());
  tearDown(() => controller.dispose());

  /// A realistic arrangement: the toaster sits inside `home`, so it is below
  /// the `Navigator` whose `Overlay` it inserts into, and a real focusable
  /// trigger sits under it.
  Future<void> pump(
    WidgetTester tester, {
    FluentThemeData? theme,
    FluentToastStyle? style,
    Widget Function(Widget child)? wrap,
    bool reducedMotion = false,
    VoidCallback? onPressed,
  }) {
    Widget toaster = FluentToaster(
      controller: controller,
      style: style,
      child: Center(
        child: FluentButton(
          key: triggerKey,
          onPressed: onPressed ?? () {},
          child: const Text('Show'),
        ),
      ),
    );
    if (wrap != null) toaster = wrap(toaster);
    return tester.pumpWidget(
      FluentApp(
        theme:
            theme ??
            FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        builder: reducedMotion
            ? (context, child) => MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: child!,
              )
            : null,
        home: toaster,
      ),
    );
  }

  Object show({
    FluentToastPosition position = FluentToastPosition.bottomEnd,
    Duration timeout = Duration.zero,
    bool pauseOnHover = true,
    Object? id,
    String title = 'Toast',
  }) => controller.show(
    (context, toastId) => FluentToast(
      title: Text(title),
      body: const Text('Body', key: bodyKey),
      onDismiss: () => controller.dismiss(toastId),
    ),
    id: id,
    position: position,
    timeout: timeout,
    pauseOnHover: pauseOnHover,
  );

  /// The collapsing box's current height factor, `0` collapsed to `1` open.
  double sizeFactorOf(WidgetTester tester, {int at = 0}) => tester
      .widget<Align>(
        find
            .ancestor(
              of: find.byType(FluentToast).at(at),
              matching: find.byType(Align),
            )
            .first,
      )
      .heightFactor!;

  double opacityOf(WidgetTester tester, {int at = 0}) => tester
      .widget<Opacity>(
        find
            .ancestor(
              of: find.byType(FluentToast).at(at),
              matching: find.byType(Opacity),
            )
            .first,
      )
      .opacity;

  /// The focus node the toast's own container owns — the closest `Focus`
  /// *above* the toast, which is the tab stop the toaster installs.
  FocusNode containerFocusOf(WidgetTester tester, {int at = 0}) => tester
      .widget<Focus>(
        find
            .ancestor(
              of: find.byType(FluentToast).at(at),
              matching: find.byType(Focus),
            )
            .first,
      )
      .focusNode!;

  BoxDecoration decorationOf(WidgetTester tester) =>
      tester
              .widgetList<DecoratedBox>(
                find.descendant(
                  of: find.byType(FluentToast),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .first
              .decoration
          as BoxDecoration;

  group('the queue', () {
    testWidgets('show puts a toast in the overlay, dismiss takes it out', (
      tester,
    ) async {
      await pump(tester);
      expect(find.byType(FluentToast), findsNothing);

      final id = show();
      await tester.pump();
      expect(find.byType(FluentToast), findsOneWidget);
      // It really is in the Overlay, not in the toaster's own child.
      expect(
        find.ancestor(
          of: find.byType(FluentToast),
          matching: find.byType(Overlay),
        ),
        findsWidgets,
      );

      controller.dismiss(id);
      await tester.pumpAndSettle();
      expect(find.byType(FluentToast), findsNothing);
      expect(controller.entries, isEmpty);
    });

    testWidgets('the overlay entry is removed once the queue empties', (
      tester,
    ) async {
      await pump(tester);
      final id = show();
      await tester.pump();
      final before = tester.widgetList(find.byType(FluentToast)).length;
      expect(before, 1);
      controller.dismiss(id);
      await tester.pumpAndSettle();
      // Nothing left behind: a second show must build cleanly.
      show();
      await tester.pump();
      expect(find.byType(FluentToast), findsOneWidget);
      controller.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('dismissAll starts every visible toast leaving', (
      tester,
    ) async {
      await pump(tester);
      show();
      show(position: FluentToastPosition.topStart);
      await tester.pump();
      expect(find.byType(FluentToast), findsNWidgets(2));
      controller.dismissAll();
      expect(controller.entries.every((e) => !e.visible), isTrue);
      await tester.pumpAndSettle();
      expect(find.byType(FluentToast), findsNothing);
    });

    testWidgets('showing an id that is already queued replaces it in place', (
      tester,
    ) async {
      await pump(tester);
      show(id: 'a', title: 'First');
      show(id: 'b', title: 'Second');
      show(id: 'a', title: 'Updated');
      await tester.pump();
      expect(controller.entries, hasLength(2));
      // Position is kept, which is upstream's updateToast, not a re-queue.
      expect(controller.entries.first.id, 'a');
      expect(find.text('Updated'), findsOneWidget);
      expect(find.text('First'), findsNothing);
      controller.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('dismissing an unknown or already-leaving id is a no-op', (
      tester,
    ) async {
      await pump(tester);
      final id = show();
      await tester.pump();
      controller
        ..dismiss('nope')
        ..dismiss(id)
        ..dismiss(id);
      expect(controller.entries, hasLength(1));
      await tester.pumpAndSettle();
      expect(controller.entries, isEmpty);
    });
  });

  group('motion — CollapseDelayed', () {
    test('the specs are the ones CollapseDelayed names', () {
      // sizeDuration: durationNormal, opacityDuration: durationSlower,
      // staggerDelay: durationNormal — all on curveEasyEase, NOT the plain
      // Collapse's curveEasyEaseMax.
      expect(fluentToastSizeEnter.duration, FluentDuration.normal);
      expect(fluentToastSizeEnter.curve, FluentCurve.easyEase);
      expect(fluentToastFadeEnter.duration, FluentDuration.slower);
      expect(fluentToastFadeEnter.curve, FluentCurve.easyEase);
      expect(fluentToastEnterStagger, FluentDuration.normal);
      // exitSizeDuration: durationNormal, exitOpacityDuration: durationSlower,
      // exitStaggerDelay: durationSlower.
      expect(fluentToastSizeExit.duration, FluentDuration.normal);
      expect(fluentToastFadeExit.duration, FluentDuration.slower);
      expect(fluentToastExitStagger, FluentDuration.slower);
      // The stagger is what makes both directions 600ms rather than 400.
      expect(
        fluentToastEnterDuration,
        fluentToastEnterStagger + fluentToastFadeEnter.duration,
      );
      expect(
        fluentToastExitDuration,
        fluentToastExitStagger + fluentToastSizeExit.duration,
      );
      expect(fluentToastTimeout, const Duration(milliseconds: 3000));
    });

    testWidgets('entrance expands first, then fades', (tester) async {
      await pump(tester);
      show();
      await tester.pump();

      // Frame 0: collapsed and invisible.
      expect(sizeFactorOf(tester), 0);
      expect(opacityOf(tester), 0);

      // 200ms — the size duration — is exactly where the expansion finishes and
      // the fade has not started. That gap IS the "Delayed" in CollapseDelayed.
      await tester.pump(FluentDuration.normal);
      expect(sizeFactorOf(tester), moreOrLessEquals(1, epsilon: 0.001));
      expect(opacityOf(tester), moreOrLessEquals(0, epsilon: 0.001));

      // Halfway through the 400ms fade the curve is symmetric, so 0.5.
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacityOf(tester), moreOrLessEquals(0.5, epsilon: 0.02));
      expect(sizeFactorOf(tester), 1);

      await tester.pump(const Duration(milliseconds: 200));
      expect(opacityOf(tester), moreOrLessEquals(1, epsilon: 0.001));

      controller.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('exit fades first, then collapses', (tester) async {
      await pump(tester);
      final id = show();
      await tester.pumpAndSettle();
      expect(sizeFactorOf(tester), 1);
      expect(opacityOf(tester), 1);

      controller.dismiss(id);
      await tester.pump();
      expect(sizeFactorOf(tester), 1);
      expect(opacityOf(tester), 1);

      // 400ms — the fade duration — is where the fade ends and the collapse
      // begins. Reversed from the entrance, which is upstream's asymmetry.
      await tester.pump(FluentDuration.slower);
      expect(opacityOf(tester), moreOrLessEquals(0, epsilon: 0.001));
      expect(sizeFactorOf(tester), moreOrLessEquals(1, epsilon: 0.001));

      // Once the collapse has run, the toast is dropped. The exact frame it
      // leaves on is asserted by the 599ms test below; here the point is the
      // fade-then-collapse ORDER, which the two assertions above pin.
      await tester.pumpAndSettle();
      expect(find.byType(FluentToast), findsNothing);
    });

    testWidgets('a toast is still on screen 599ms into its exit', (
      tester,
    ) async {
      await pump(tester);
      final id = show();
      await tester.pumpAndSettle();
      controller.dismiss(id);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 599));
      expect(find.byType(FluentToast), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(FluentToast), findsNothing);
    });
  });

  group('reduced motion', () {
    testWidgets('an entering toast is already at its end state', (
      tester,
    ) async {
      await pump(tester, reducedMotion: true);
      show();
      await tester.pump();
      // No 600ms ramp: full height and full opacity on the very first frame.
      expect(sizeFactorOf(tester), 1);
      expect(opacityOf(tester), 1);
      // And nothing is left scheduled — pump() would throw on a pending frame
      // if a ticker were still running.
      expect(tester.hasRunningAnimations, isFalse);
      controller.dismissAll();
      await tester.pump();
      await tester.pump();
    });

    testWidgets('a dismissed toast is gone on the next frame', (tester) async {
      await pump(tester, reducedMotion: true);
      final id = show();
      await tester.pump();
      controller.dismiss(id);
      // Three zero-length frames, so NO simulated time passes at all: the
      // overlay rebuild, the deferred removal and the overlay teardown are each
      // a setState on a different branch of the tree. The point is that none of
      // the 600ms exit runs.
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.byType(FluentToast), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('turning reduced motion on mid-flight lands the animation', (
      tester,
    ) async {
      await pump(tester);
      show();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacityOf(tester), lessThan(1));

      await pump(tester, reducedMotion: true);
      await tester.pump();
      expect(sizeFactorOf(tester), 1);
      expect(opacityOf(tester), 1);
      controller.dismissAll();
      await tester.pump();
      await tester.pump();
    });
  });

  group('the clock', () {
    /// Advances by [step] without `pumpAndSettle`, which would run the
    /// countdown out — it is a ticker, so a scheduled frame is always pending
    /// while a timed toast is up.
    Future<void> advance(WidgetTester tester, Duration step) =>
        tester.pump(step);

    testWidgets('a toast dismisses itself after its timeout', (tester) async {
      await pump(tester);
      show(timeout: const Duration(milliseconds: 3000));
      await tester.pump();
      await advance(tester, fluentToastEnterDuration);
      expect(find.byType(FluentToast), findsOneWidget);

      // 2999 of the 3000 served.
      await advance(tester, const Duration(milliseconds: 2399));
      expect(find.byType(FluentToast), findsOneWidget);

      await advance(tester, const Duration(milliseconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(FluentToast), findsNothing);
    });

    testWidgets('Duration.zero never auto-dismisses', (tester) async {
      await pump(tester);
      show();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 30));
      expect(find.byType(FluentToast), findsOneWidget);
      controller.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('hover pauses the clock and un-hovering resumes it where it '
        'left off', (tester) async {
      await pump(tester);
      show(timeout: const Duration(milliseconds: 3000));
      await tester.pump();
      await advance(tester, fluentToastEnterDuration);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();

      // 1s of the 3s served, then the pointer arrives.
      await advance(tester, const Duration(milliseconds: 400));
      await mouse.moveTo(tester.getCenter(find.byType(FluentToast)));
      await tester.pump();

      // Ten seconds under the pointer and it is still there.
      await advance(tester, const Duration(seconds: 10));
      expect(find.byType(FluentToast), findsOneWidget);

      await mouse.moveTo(const Offset(2000, 2000));
      await tester.pump();

      // Resumed, not restarted: 2s remained, so 1.9s is not enough...
      await advance(tester, const Duration(milliseconds: 1900));
      expect(find.byType(FluentToast), findsOneWidget);
      // ...and the balance is.
      await advance(tester, const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.byType(FluentToast), findsNothing);
    });

    testWidgets('pauseOnHover: false keeps the clock running under the '
        'pointer', (tester) async {
      await pump(tester);
      show(timeout: const Duration(milliseconds: 3000), pauseOnHover: false);
      await tester.pump();
      await advance(tester, fluentToastEnterDuration);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(FluentToast)));
      await tester.pump();

      await advance(tester, const Duration(milliseconds: 2401));
      await tester.pumpAndSettle();
      expect(find.byType(FluentToast), findsNothing);
    });
  });

  group('theming across the overlay boundary', () {
    testWidgets('a FluentThemeOverride wrapping the toaster reaches the '
        'toast', (tester) async {
      // The toast builds inside the Overlay, outside the toaster's own subtree,
      // so this only passes because FluentTheme is an InheritedTheme and the
      // capture is taken from the toaster's context rather than the overlay's.
      const magenta = Color(0xFF780510);
      await pump(
        tester,
        wrap: (child) => FluentThemeOverride(
          colors: const <FluentColorToken, Color>{
            FluentColorToken.neutralBackground1: magenta,
          },
          child: child,
        ),
      );
      show();
      await tester.pumpAndSettle();
      expect(decorationOf(tester).color, magenta);
      controller.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('a FluentToastTheme wrapping the toaster reaches the toast', (
      tester,
    ) async {
      const cyan = Color(0xFF00B7C3);
      await pump(
        tester,
        wrap: (child) => FluentToastTheme(
          style: FluentToastStyle.from(backgroundColor: cyan),
          child: child,
        ),
      );
      show();
      await tester.pumpAndSettle();
      expect(decorationOf(tester).color, cyan);
      controller.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('the toaster\'s own style applies to every toast it renders', (
      tester,
    ) async {
      const cyan = Color(0xFF00B7C3);
      await pump(tester, style: FluentToastStyle.from(backgroundColor: cyan));
      show();
      await tester.pumpAndSettle();
      expect(decorationOf(tester).color, cyan);
      controller.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('a theme swap repaints a live toast', (tester) async {
      await pump(tester);
      show();
      await tester.pumpAndSettle();
      final light = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      expect(decorationOf(tester).color, light.colors.neutralBackground1);

      final dark = FluentThemeData.dark(fontPlatform: FluentFontPlatform.web);
      await pump(tester, theme: dark);
      await tester.pumpAndSettle();
      expect(decorationOf(tester).color, dark.colors.neutralBackground1);
      controller.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('high contrast keeps the toast outlined in the overlay', (
      tester,
    ) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await pump(tester, theme: theme);
      show();
      await tester.pumpAndSettle();
      final border = decorationOf(tester).border! as Border;
      expect(border.top.color, theme.colors.transparentStroke);
      expect(border.top.color.a, 1.0);
      controller.dismissAll();
      await tester.pumpAndSettle();
    });
  });

  group('focus and keyboard', () {
    testWidgets('a toast does not steal focus when it appears', (tester) async {
      await pump(tester);
      final trigger = Focus.of(tester.element(find.text('Show')));
      trigger.requestFocus();
      await tester.pump();
      expect(trigger.hasFocus, isTrue);

      show();
      await tester.pumpAndSettle();
      // A notification that grabbed focus mid-typing would be a bug, and
      // upstream does not do it either.
      expect(trigger.hasFocus, isTrue);
      expect(containerFocusOf(tester).hasFocus, isFalse);
      controller.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('Escape dismisses the focused toast', (tester) async {
      await pump(tester);
      show();
      await tester.pumpAndSettle();

      containerFocusOf(tester).requestFocus();
      await tester.pump();
      expect(containerFocusOf(tester).hasFocus, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(FluentToast), findsNothing);
    });

    testWidgets('Escape with focus elsewhere leaves the toast alone', (
      tester,
    ) async {
      await pump(tester);
      show();
      await tester.pumpAndSettle();
      Focus.of(tester.element(find.text('Show'))).requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(FluentToast), findsOneWidget);
      controller.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('dismissing a focused toast hands focus back to its trigger', (
      tester,
    ) async {
      // Torn off directly: every parameter of `show` is optional, so it is
      // already a VoidCallback.
      await pump(tester, onPressed: show);
      final trigger = Focus.of(tester.element(find.text('Show')));
      trigger.requestFocus();
      await tester.pump();

      // Raised from the trigger's own callback, which is what lets the
      // controller capture the node to return focus to.
      await tester.tap(find.byKey(triggerKey));
      await tester.pumpAndSettle();

      containerFocusOf(tester).requestFocus();
      await tester.pump();
      expect(trigger.hasFocus, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(FluentToast), findsNothing);
      expect(trigger.hasFocus, isTrue);
    });

    testWidgets('dismissing an unfocused toast leaves focus where it is', (
      tester,
    ) async {
      await pump(tester);
      final trigger = Focus.of(tester.element(find.text('Show')));
      trigger.requestFocus();
      await tester.pump();

      final id = show();
      await tester.pumpAndSettle();
      controller.dismiss(id);
      await tester.pumpAndSettle();
      expect(trigger.hasFocus, isTrue);
    });

    testWidgets('the toast\'s own dismiss button works from the overlay', (
      tester,
    ) async {
      await pump(tester);
      show();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FluentButton).last);
      await tester.pumpAndSettle();
      expect(find.byType(FluentToast), findsNothing);
    });

    testWidgets('a focused toast raises the Fluent focus ring', (tester) async {
      // Keyboard-visible focus only: the ring follows the input MODALITY, not
      // bare focus, exactly as FluentInteractive does. The key is sent before
      // focus arrives, so the container reads a settled flag.
      FluentInputModality.debugReset();
      addTearDown(FluentInputModality.debugReset);
      await pump(tester);
      show();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      containerFocusOf(tester).requestFocus();
      await tester.pumpAndSettle();
      // Scoped to the toast's own ancestors: the trigger button in `home` has a
      // focus ring of its own and sits earlier in the tree.
      final ring = tester.widget<FluentFocusRing>(
        find
            .ancestor(
              of: find.byType(FluentToast),
              matching: find.byType(FluentFocusRing),
            )
            .first,
      );
      expect(ring.visible, isTrue);
      controller.dismissAll();
      await tester.pumpAndSettle();
    });
  });

  group('position and stacking', () {
    /// 800x600 is the default test surface; the toaster insets 20/16.
    const width = 800.0;
    const height = 600.0;
    const stackGap = FluentSpacing.l;

    testWidgets('bottomEnd anchors to the bottom trailing corner', (
      tester,
    ) async {
      await pump(tester);
      show();
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byType(FluentToast));
      expect(rect.right, width - FluentSpacing.xl);
      expect(rect.bottom, height - FluentSpacing.l);
      expect(rect.width, 292);
      controller.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('an RTL toaster mirrors the corner and the toast', (
      tester,
    ) async {
      // The stacks build inside the Overlay, outside the toaster's subtree, so
      // this only passes because toaster.dart re-provides the direction —
      // `InheritedTheme.capture` carries themes and Directionality is not one.
      await pump(
        tester,
        wrap: (child) =>
            Directionality(textDirection: TextDirection.rtl, child: child),
      );
      show();
      await tester.pumpAndSettle();
      expect(
        Directionality.of(tester.element(find.byKey(bodyKey))),
        TextDirection.rtl,
      );
      // `PositionedDirectional` now resolves against RTL, so the trailing
      // corner is the LEFT one.
      expect(tester.getRect(find.byType(FluentToast)).left, FluentSpacing.xl);
      controller.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('bottomStart anchors to the bottom leading corner', (
      tester,
    ) async {
      await pump(tester);
      show(position: FluentToastPosition.bottomStart);
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byType(FluentToast));
      expect(rect.left, FluentSpacing.xl);
      expect(rect.bottom, height - FluentSpacing.l);
      controller.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('topEnd anchors to the top trailing corner, gap included', (
      tester,
    ) async {
      await pump(tester);
      show(position: FluentToastPosition.topEnd);
      await tester.pumpAndSettle();
      final rect = tester.getRect(find.byType(FluentToast));
      expect(rect.right, width - FluentSpacing.xl);
      // The vertical offset plus the stack gap the container carries, which is
      // exactly what the browser produces from `top: 16` + `margin-top: 16`.
      expect(rect.top, FluentSpacing.l + stackGap);
      controller.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('topStart anchors to the top leading corner', (tester) async {
      await pump(tester);
      show(position: FluentToastPosition.topStart);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(FluentToast)).left, FluentSpacing.xl);
      controller.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('top and bottom centre horizontally, ignoring the horizontal '
        'offset', (tester) async {
      for (final position in <FluentToastPosition>[
        FluentToastPosition.top,
        FluentToastPosition.bottom,
      ]) {
        await pump(tester);
        show(position: position);
        await tester.pumpAndSettle();
        expect(
          tester.getCenter(find.byType(FluentToast)).dx,
          width / 2,
          reason: '${position.name} must be centred',
        );
        controller.dismissAll();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('every position renders in its own stack', (tester) async {
      await pump(tester);
      for (final position in FluentToastPosition.values) {
        show(position: position);
      }
      await tester.pumpAndSettle();
      expect(find.byType(FluentToast), findsNWidgets(6));
      controller.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('toasts stack in insertion order, newest nearest the edge', (
      tester,
    ) async {
      await pump(tester);
      show(title: 'First');
      show(title: 'Second');
      await tester.pumpAndSettle();
      final first = tester.getRect(find.text('First'));
      final second = tester.getRect(find.text('Second'));
      // bottom-anchored: the block grows upward, so the newest is lower.
      expect(second.top, greaterThan(first.top));
      // The 16 gap rides with the toast that owns it.
      expect(second.top - first.bottom, greaterThanOrEqualTo(stackGap));
      controller.dismissAll();
      await tester.pumpAndSettle();
    });

    testWidgets('the mirrored corner is used in RTL', (tester) async {
      // The Directionality here sits ABOVE the Navigator, so the Overlay's own
      // branch carries it — the case that worked even before toaster.dart
      // re-provided the direction. 'an RTL toaster mirrors the corner and the
      // toast' in this group covers the case that did not: a Directionality
      // BELOW the Navigator, which the captured themes never carry across.
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: FluentToaster(
            controller: controller,
            child: const SizedBox.shrink(),
          ),
        ),
      );
      show(position: FluentToastPosition.bottomStart);
      await tester.pumpAndSettle();
      // `start` is the RIGHT edge in RTL, which a left/right Positioned pair
      // would have got backwards.
      expect(
        tester.getRect(find.byType(FluentToast)).right,
        width - FluentSpacing.xl,
      );
      controller.dismissAll();
      await tester.pumpAndSettle();
    });
  });

  group('lifecycle', () {
    testWidgets('disposing the toaster tears its overlay entry down', (
      tester,
    ) async {
      await pump(tester);
      show();
      await tester.pumpAndSettle();
      expect(find.byType(FluentToast), findsOneWidget);

      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: const SizedBox.shrink(),
        ),
      );
      await tester.pump();
      expect(find.byType(FluentToast), findsNothing);
      // The controller outlives the widget; nothing here should have thrown.
      expect(controller.entries, hasLength(1));
    });

    testWidgets('swapping controllers moves the queue', (tester) async {
      await pump(tester);
      show();
      await tester.pumpAndSettle();

      final second = FluentToastController();
      addTearDown(second.dispose);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: FluentToaster(
            controller: second,
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FluentToast), findsNothing);

      second.show(
        (context, id) => const FluentToast(title: Text('Second controller')),
        // Duration.zero, or pumpAndSettle below would run the countdown out and
        // dismiss the toast before it could be found.
        timeout: Duration.zero,
      );
      await tester.pumpAndSettle();
      expect(find.text('Second controller'), findsOneWidget);
      second.dismissAll();
      await tester.pumpAndSettle();
    });

    test('entries is an unmodifiable view', () {
      controller.show((context, id) => const SizedBox.shrink());
      expect(() => controller.entries.clear(), throwsUnsupportedError);
    });

    test('dismissed keeps everything but visible', () {
      const entry = FluentToastEntry(
        id: 'a',
        builder: _noToast,
        position: FluentToastPosition.top,
        timeout: Duration(seconds: 1),
        pauseOnHover: false,
      );
      final gone = entry.dismissed;
      expect(gone.visible, isFalse);
      expect(gone.id, entry.id);
      expect(gone.position, entry.position);
      expect(gone.timeout, entry.timeout);
      expect(gone.pauseOnHover, entry.pauseOnHover);
    });
  });
}

Widget _noToast(BuildContext context, Object id) => const SizedBox.shrink();
