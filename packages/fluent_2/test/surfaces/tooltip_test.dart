import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2/src/internal/input_modality.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentTooltip` is the first overlay-positioned component in the package, so
/// these tests cover two things beyond the usual token fidelity: that the
/// surface reaches the `Overlay` with the ambient `FluentTheme` intact, and that
/// it does so with **no** transition — upstream ships none on master and the old
/// slide path is explicitly deprecated.
void main() {
  const trigger = Key('trigger');
  const tip = Key('tip');

  /// [alignment] parks the trigger against an edge of the 800 x 600 test view;
  /// the default centre leaves room on every side.
  Future<void> pump(
    WidgetTester tester,
    Widget tooltip, {
    FluentThemeData? theme,
    TextDirection? direction,
    Alignment alignment = Alignment.center,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      // Deliberately *inside* `home`, which puts it below the Navigator's
      // Overlay: the tooltip surface therefore builds in an LTR context even
      // here, which is exactly the case `Directionality` is not an
      // InheritedTheme guards against.
      home: direction == null
          ? Align(alignment: alignment, child: tooltip)
          : Directionality(
              textDirection: direction,
              child: Align(alignment: alignment, child: tooltip),
            ),
    ),
  );

  // One mouse per test: MouseTracker asserts if a second pointer is added for
  // the same device before the first is removed, and several tests hover more
  // than once.
  TestGesture? mouse;
  setUp(() {
    mouse = null;
  });

  /// `useTooltipBase`'s `showDelay`/`hideDelay`, which hover — but not focus —
  /// waits out. Kept here rather than imported because the constant is private
  /// to the implementation; the delay itself is asserted in `behaviour`.
  const hoverDelay = Duration(milliseconds: 250);

  /// Moves the test mouse over [target], waits out the show delay and settles
  /// the frame the overlay lands on.
  Future<void> hover(WidgetTester tester, Finder target) async {
    var gesture = mouse;
    if (gesture == null) {
      gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      mouse = gesture;
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
    }
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
    await tester.pump(hoverDelay);
  }

  /// Moves the test mouse off everything and waits out the hide delay.
  Future<void> unhover(WidgetTester tester) async {
    await mouse?.moveTo(const Offset(2000, 2000));
    await tester.pump();
    await tester.pump(hoverDelay);
  }

  /// The tooltip's own decorated surface, found through its content rather than
  /// through the trigger — the surface lives in the overlay, not under the
  /// widget that owns it.
  BoxDecoration decorationOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.ancestor(of: find.byKey(tip), matching: find.byType(DecoratedBox)),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((d) => d.borderRadius != null);

  /// The surface's own box — the [ConstrainedBox] that carries `maxWidth`,
  /// which is the outermost thing [buildFluentTooltip] returns for the surface
  /// itself, with the arrow (when there is one) as its sibling.
  Rect surfaceRect(WidgetTester tester) => tester.getRect(
    find
        .ancestor(of: find.byKey(tip), matching: find.byType(ConstrainedBox))
        .first,
  );

  final arrowFinder = find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is FluentTooltipArrowPainter,
  );

  FluentTooltipArrowPainter arrowOf(WidgetTester tester) =>
      tester.widget<CustomPaint>(arrowFinder).painter!
          as FluentTooltipArrowPainter;

  /// The triangle the arrow painter actually draws, in the arrow's own box.
  /// Recorded rather than golden-diffed, the way the chart painter tests do it
  /// (`test/charts/gauge_needle_test.dart:13`).
  Path arrowPathOf(WidgetTester tester) {
    final canvas = _RecordingCanvas();
    arrowOf(tester).paint(canvas, tester.getSize(arrowFinder));
    return canvas.paths.single;
  }

  // Two probes inside the arrow's 6 x 12 horizontal box, each falling inside
  // exactly one of the two triangles: the apex-right one spans {y >= x,
  // y <= 12 - x}, its mirror {x + y >= 6, y <= x + 6}.
  const apexRight = Offset(1, 3);
  const apexLeft = Offset(5, 3);

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('tooltip');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 3);
      expect(spec.properties['Style'], ['Default', 'Brand', 'Inverted']);
    });

    testWidgets('the surface matches every appearance', (tester) async {
      const names = {
        FluentTooltipAppearance.normal: 'Default',
        FluentTooltipAppearance.brand: 'Brand',
        FluentTooltipAppearance.inverted: 'Inverted',
      };

      for (final entry in names.entries) {
        final variant = spec.variant({'Style': entry.value});

        await pump(
          tester,
          FluentTooltip(
            appearance: entry.key,
            content: const Text('Tip', key: tip),
            child: const Text('trigger', key: trigger),
          ),
        );
        await hover(tester, find.byKey(trigger));

        final decoration = decorationOf(tester);
        expect(
          decoration.color,
          variant.fill,
          reason: '${entry.value}: fill (token ${variant.token('fills')})',
        );
        expect(
          decoration.borderRadius,
          variant.radius,
          reason: '${entry.value}: radius',
        );

        final border = decoration.border!.top;
        expect(
          border.width,
          variant.strokeWidth,
          reason: '${entry.value}: strokeWidth',
        );
        final expectedStroke = variant.stroke!;
        if (expectedStroke.a == 0) {
          // Figma stores a fully transparent token as #00FFFFFF; core stores
          // CSS `transparent`, which is rgba(0,0,0,0). Both are invisible, so
          // only the alpha is observable — see doc/token-divergences.md.
          expect(
            border.color.a,
            0,
            reason: '${entry.value}: resting stroke alpha',
          );
        } else {
          expect(
            border.color,
            expectedStroke,
            reason:
                '${entry.value}: stroke (token ${variant.token('strokes')})',
          );
        }

        final padding = tester
            .widget<Padding>(
              find
                  .ancestor(of: find.byKey(tip), matching: find.byType(Padding))
                  .first,
            )
            .padding
            .resolve(TextDirection.ltr);
        expect(
          padding.left,
          variant.padding!.left,
          reason: '${entry.value}: padding.left',
        );
        expect(
          padding.top,
          variant.padding!.top,
          reason: '${entry.value}: padding.top',
        );

        final text = variant.text!;
        final style = resolvedTextStyleOf(tester, of: find.byKey(tip));
        expect(
          style.fontSize,
          text.fontSize,
          reason: '${entry.value}: text.fontSize',
        );
        expect(
          style.height! * style.fontSize!,
          text.lineHeight,
          reason: '${entry.value}: text.lineHeight',
        );

        await unhover(tester);
      }
    });

    testWidgets('the surface wraps at the 240 max width', (tester) async {
      // Figma pins maxWidth=240 on the component frame with horizontal sizing
      // HUG, so the surface hugs short content and stops growing at 240.
      await pump(
        tester,
        const FluentTooltip(
          content: Text(
            'Tooltip will wrap text to next line when max width is reached '
            'at 240px.',
            key: tip,
          ),
          child: Text('trigger', key: trigger),
        ),
      );
      await hover(tester, find.byKey(trigger));

      final box = tester.widget<ConstrainedBox>(
        find
            .ancestor(
              of: find.byKey(tip),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(box.constraints.maxWidth, 240);
      expect(tester.getSize(find.byKey(tip)).width, lessThanOrEqualTo(240));

      // ...and hugs anything narrower, which is Figma's HUG sizing.
      await unhover(tester);
      await pump(
        tester,
        const FluentTooltip(
          content: Text('Tip', key: tip),
          child: Text('trigger', key: trigger),
        ),
      );
      await hover(tester, find.byKey(trigger));
      expect(tester.getSize(find.byKey(tip)).width, lessThan(240));
    });

    testWidgets('the arrow is the Figma triangle, and is opt-in', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentTooltip(
          content: Text('Tip', key: tip),
          child: Text('trigger', key: trigger),
        ),
      );
      await hover(tester, find.byKey(trigger));
      expect(
        arrowFinder,
        findsNothing,
        reason:
            'every Figma arrow layer ships hidden; withArrow defaults false',
      );
      await unhover(tester);

      // `react-tooltip`'s `arrowHeight = 6` gives a 12 x 6 visible triangle
      // (a 8.49px square rotated 45°), which a live probe of
      // `components-tooltip--with-arrow` confirms. `tooltip.json` carries no
      // arrow part at all, so React is the only authority on this one.
      for (final position in FluentTooltipPosition.values) {
        await pump(
          tester,
          FluentTooltip(
            position: position,
            withArrow: true,
            content: const Text('Tip', key: tip),
            child: const Text('trigger', key: trigger),
          ),
        );
        await hover(tester, find.byKey(trigger));

        final vertical =
            position == FluentTooltipPosition.above ||
            position == FluentTooltipPosition.below;
        expect(
          tester.getSize(arrowFinder),
          vertical ? const Size(12, 6) : const Size(6, 12),
          reason: '${position.name}: arrow size',
        );
        expect(
          arrowOf(tester).color,
          decorationOf(tester).color,
          reason: '${position.name}: the arrow carries the surface fill',
        );
        expect(arrowOf(tester).position, position);
        await unhover(tester);
      }
    });

    testWidgets('the surface stands 4 off its target, 10 with an arrow', (
      tester,
    ) async {
      // `useTooltipBase.tsx` states `offset: 4` and then, with an arrow,
      // `positioningOptions.offset = mergeArrowOffset(4, arrowHeight)` =
      // `{ mainAxis: 10 }` — the base gap is *kept* and the arrow's height is
      // added to it, so the tip stops ~4 short of the target instead of
      // touching it. Live: `components-tooltip--default` surface bottom 76 vs
      // trigger top 80; `--with-arrow` surface bottom 70, arrow bottom ~75.
      // Figma is silent — it draws its arrow flush at the surface edge, but a
      // frame cannot state a positioning offset.
      await pump(
        tester,
        const FluentTooltip(
          content: Text('Tip', key: tip),
          child: Text('trigger', key: trigger),
        ),
      );
      await hover(tester, find.byKey(trigger));
      expect(
        tester.getRect(find.byKey(trigger)).top - surfaceRect(tester).bottom,
        FluentSpacing.xs,
      );
      await unhover(tester);

      await pump(
        tester,
        const FluentTooltip(
          withArrow: true,
          content: Text('Tip', key: tip),
          child: Text('trigger', key: trigger),
        ),
      );
      await hover(tester, find.byKey(trigger));
      final triggerTop = tester.getRect(find.byKey(trigger)).top;
      expect(
        triggerTop - surfaceRect(tester).bottom,
        10,
        reason: 'offset 4 plus the arrow\'s own 6',
      );
      expect(
        triggerTop - tester.getRect(arrowFinder).bottom,
        FluentSpacing.xs,
        reason: 'the tip stops short of the trigger, it does not touch it',
      );
    });
  });

  group('motion', () {
    testWidgets('there is none — the tooltip is fully painted on frame one', (
      tester,
    ) async {
      // Upstream's tooltip has no transition on master, and the deprecated
      // slide path is not being resurrected here. The frame the surface lands
      // on must carry the final colour — the 250ms hover delay is a wait
      // *before* it appears, not a tween — and nothing may still be ticking
      // afterwards.
      await pump(
        tester,
        const FluentTooltip(
          appearance: FluentTooltipAppearance.inverted,
          content: Text('Tip', key: tip),
          child: Text('trigger', key: trigger),
        ),
      );
      await hover(tester, find.byKey(trigger));

      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      expect(
        decorationOf(tester).color,
        theme.colors.neutralBackgroundInverted,
        reason: 'must be final, not mid-tween',
      );
      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'no animation may be scheduled',
      );
    });
  });

  group('style resolution order', () {
    testWidgets('the widget style beats the subtree theme beats the defaults', (
      tester,
    ) async {
      const themed = Color(0xFF111111);
      const explicit = Color(0xFF222222);

      await pump(
        tester,
        FluentTooltipTheme(
          style: FluentTooltipStyle.from(backgroundColor: themed),
          child: FluentTooltip(
            style: FluentTooltipStyle.from(backgroundColor: explicit),
            content: const Text('Tip', key: tip),
            child: const Text('trigger', key: trigger),
          ),
        ),
      );
      await hover(tester, find.byKey(trigger));
      expect(decorationOf(tester).color, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentTooltipTheme(
          style: FluentTooltipStyle.from(backgroundColor: themed),
          child: const FluentTooltip(
            content: Text('Tip', key: tip),
            child: Text('trigger', key: trigger),
          ),
        ),
      );
      await hover(tester, find.byKey(trigger));
      expect(decorationOf(tester).color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentTooltip(
          appearance: FluentTooltipAppearance.brand,
          style: FluentTooltipStyle.from(
            borderRadius: FluentRadius.allCircular,
          ),
          content: const Text('Tip', key: tip),
          child: const Text('trigger', key: trigger),
        ),
      );
      await hover(tester, find.byKey(trigger));

      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      expect(decorationOf(tester).borderRadius, FluentRadius.allCircular);
      expect(
        decorationOf(tester).color,
        theme.colors.brandBackground,
        reason: 'overriding radius must not drop the brand fill',
      );
    });
  });

  group('theming', () {
    testWidgets('a subtree override reaches the surface in the overlay', (
      tester,
    ) async {
      // The surface builds inside the Overlay, outside the widget's own
      // subtree, so this only passes because FluentTheme is an InheritedTheme
      // and the resolved style is computed against the trigger's context.
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: const FluentThemeOverride(
            colors: {FluentColorToken.brandBackground: magenta},
            child: Center(
              child: FluentTooltip(
                appearance: FluentTooltipAppearance.brand,
                content: Text('Tip', key: tip),
                child: Text('trigger', key: trigger),
              ),
            ),
          ),
        ),
      );
      await hover(tester, find.byKey(trigger));
      expect(decorationOf(tester).color, magenta);
    });

    testWidgets('high contrast draws a visible border', (tester) async {
      await pump(
        tester,
        const FluentTooltip(
          content: Text('Tip', key: tip),
          child: Text('trigger', key: trigger),
        ),
        theme: FluentThemeData.highContrast(
          fontPlatform: FluentFontPlatform.web,
        ),
      );
      await hover(tester, find.byKey(trigger));

      // transparentStroke resolves to canvasText in high contrast, so the
      // border that is invisible in light mode has to read here. A hardcoded
      // Colors.transparent would silently stay invisible.
      final border = decorationOf(tester).border;
      expect(border, isNotNull);
      expect(border!.top.color.a, 1.0);
      expect(border.top.width, greaterThan(0));
    });
  });

  group('behaviour', () {
    testWidgets('shows on hover and hides on exit', (tester) async {
      await pump(
        tester,
        const FluentTooltip(
          content: Text('Tip', key: tip),
          child: Text('trigger', key: trigger),
        ),
      );
      expect(find.byKey(tip), findsNothing);

      await hover(tester, find.byKey(trigger));
      expect(find.byKey(tip), findsOneWidget);

      await unhover(tester);
      expect(find.byKey(tip), findsNothing);
    });

    testWidgets('hover waits out the show and hide delays', (tester) async {
      // `useTooltipBase.tsx` states `showDelay = 250, hideDelay = 250`, and a
      // live probe needs a >250ms dwell after `page.hover` before
      // `[role=tooltip]` has a rect. Without it, a pointer crossing the trigger
      // on its way somewhere else flashes the surface for one frame.
      await pump(
        tester,
        const FluentTooltip(
          content: Text('Tip', key: tip),
          child: Text('trigger', key: trigger),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      mouse = gesture;
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.byKey(trigger)));
      await tester.pump();
      expect(
        find.byKey(tip),
        findsNothing,
        reason: 'the frame after entering is too early',
      );
      await tester.pump(const Duration(milliseconds: 249));
      expect(find.byKey(tip), findsNothing, reason: '249ms is still too early');
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byKey(tip), findsOneWidget);

      await gesture.moveTo(const Offset(2000, 2000));
      await tester.pump();
      expect(
        find.byKey(tip),
        findsOneWidget,
        reason: 'leaving is delayed too, so a one-pixel gap cannot flicker it',
      );
      await tester.pump(hoverDelay);
      expect(find.byKey(tip), findsNothing);
    });

    testWidgets('a pointer passing through never raises the surface', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentTooltip(
          content: Text('Tip', key: tip),
          child: Text('trigger', key: trigger),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      mouse = gesture;
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.byKey(trigger)));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(const Offset(2000, 2000));
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.byKey(tip),
        findsNothing,
        reason: 'the pending show must be dropped, not merely deferred',
      );
    });

    testWidgets('shows on keyboard focus and hides on blur', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      FluentInputModality.debugReset();
      addTearDown(FluentInputModality.debugReset);

      await pump(
        tester,
        FluentTooltip(
          content: const Text('Tip', key: tip),
          child: Focus(
            focusNode: node,
            child: const Text('trigger', key: trigger),
          ),
        ),
      );

      // Pointer focus must not raise a tooltip, exactly as it must not raise a
      // focus ring — WidgetState.focused means keyboard-visible focus, and the
      // modality flag starts pointer-first.
      node.requestFocus();
      await tester.pump();
      expect(find.byKey(tip), findsNothing);

      // One pump, no delay: upstream passes `delay: 0` on blur, and a tooltip
      // trailing a quarter second behind the focus ring reads as a fault. The
      // 250ms wait is hover's alone. The key flips the flag without moving
      // focus, which the tooltip has to honour mid-flight.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(find.byKey(tip), findsOneWidget);

      node.unfocus();
      // unfocus resolves in a microtask, so the frame that tears the overlay
      // down is only scheduled once that has run — hence settle, not pump.
      await tester.pumpAndSettle();
      expect(find.byKey(tip), findsNothing);
    });

    testWidgets('a mouse click does not count as keyboard navigation', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      FluentInputModality.debugReset();
      addTearDown(FluentInputModality.debugReset);

      await pump(
        tester,
        FluentTooltip(
          content: const Text('Tip', key: tip),
          child: Focus(
            focusNode: node,
            child: const Text('trigger', key: trigger),
          ),
        ),
      );

      // A mouse — not a finger: `FocusHighlightMode` reads a mouse as
      // `traditional`, the very same value a key press produces, which is why
      // it cannot be the signal. keyborg clears its flag on `mousedown`.
      // Away from the trigger on purpose: a mouse-down over it enters the
      // MouseRegion too, and this test is about focus, not hover.
      await tester.tapAt(const Offset(5, 5), kind: PointerDeviceKind.mouse);
      node.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(
        find.byKey(tip),
        findsNothing,
        reason: 'pointer focus must not open a tooltip the way a key does',
      );
    });

    testWidgets('disabled is a real state, not a visual treatment', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentTooltip(
          enabled: false,
          content: Text('Tip', key: tip),
          child: Text('trigger', key: trigger),
        ),
      );
      await hover(tester, find.byKey(trigger));
      expect(
        find.byKey(tip),
        findsNothing,
        reason: 'a disabled tooltip never reaches the overlay at all',
      );
    });

    testWidgets('disabling while visible tears the surface down', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentTooltip(
          content: Text('Tip', key: tip),
          child: Text('trigger', key: trigger),
        ),
      );
      await hover(tester, find.byKey(trigger));
      expect(find.byKey(tip), findsOneWidget);

      await pump(
        tester,
        const FluentTooltip(
          enabled: false,
          content: Text('Tip', key: tip),
          child: Text('trigger', key: trigger),
        ),
      );
      await tester.pump();
      expect(find.byKey(tip), findsNothing);
    });

    testWidgets('the trigger carries the tooltip semantics', (tester) async {
      await pump(
        tester,
        const FluentTooltip(
          semanticLabel: 'Saves the document',
          content: Text('Saves the document', key: tip),
          child: Text('trigger', key: trigger),
        ),
      );
      expect(
        tester.getSemantics(find.byType(FluentTooltip)).tooltip,
        'Saves the document',
      );
    });

    testWidgets('the surface is announced once, not twice', (tester) async {
      // `IgnorePointer` does NOT drop its subtree from the semantics tree:
      // `RenderIgnorePointer.visitChildrenForSemantics` only returns early on
      // the deprecated `ignoringSemantics` (proxy_box.dart:3802), and it is
      // never set here. Without an `ExcludeSemantics` beside it the overlay
      // publishes a second, floating node saying the very thing the trigger's
      // own `tooltip` already says.
      // Disposed inline, not via addTearDown: the framework verifies no handle
      // is outstanding *before* tear-downs run.
      final semantics = tester.ensureSemantics();

      await pump(
        tester,
        const FluentTooltip(
          semanticLabel: 'Saves the document',
          content: Text('Saves the document', key: tip),
          child: Text('trigger', key: trigger),
        ),
      );
      await hover(tester, find.byKey(trigger));

      expect(
        find.byKey(tip),
        findsOneWidget,
        reason: 'the surface is visible — this is not a vacuous pass',
      );
      expect(
        tester.getSemantics(find.byType(FluentTooltip)).tooltip,
        'Saves the document',
        reason: 'the trigger is still the one thing that announces it',
      );
      expect(
        find.bySemanticsLabel('Saves the document'),
        findsNothing,
        reason: 'the overlay copy must not reach the semantics tree at all',
      );
      semantics.dispose();
    });
  });

  group('reading direction', () {
    testWidgets('before and after are reading-order sides, arrow and all', (
      tester,
    ) async {
      // Three things have to agree that `before`/`after` are logical: the
      // follower's anchors (typed `Alignment`, which is not direction-aware —
      // basic.dart:2054, 2062 — so they only flip because they are resolved
      // first), the `Row` in `buildFluentTooltip`, which flips on its own, and
      // the arrow's `Path`, which cannot flip at all without being told. Miss
      // any one and the surface lands on the far side of the trigger with its
      // arrow pointing back into its own fill.
      const cases = <(TextDirection, FluentTooltipPosition, bool)>[
        // (direction, position, surface sits to the trigger's physical left)
        (TextDirection.ltr, FluentTooltipPosition.before, true),
        (TextDirection.ltr, FluentTooltipPosition.after, false),
        (TextDirection.rtl, FluentTooltipPosition.before, false),
        (TextDirection.rtl, FluentTooltipPosition.after, true),
      ];

      for (final (direction, position, onTheLeft) in cases) {
        await pump(
          tester,
          FluentTooltip(
            position: position,
            withArrow: true,
            content: const Text('Tip', key: tip),
            child: const Text('trigger', key: trigger),
          ),
          direction: direction,
        );
        await hover(tester, find.byKey(trigger));

        final target = tester.getRect(find.byKey(trigger));
        final surface = surfaceRect(tester);
        final arrow = tester.getRect(arrowFinder);
        final path = arrowPathOf(tester);
        final label = '${direction.name}/${position.name}';

        expect(
          onTheLeft ? surface.right : surface.left,
          onTheLeft
              ? lessThanOrEqualTo(target.left)
              : greaterThanOrEqualTo(target.right),
          reason: '$label: the surface is on the wrong side of the trigger',
        );
        expect(
          onTheLeft ? arrow.left : arrow.right,
          onTheLeft
              ? greaterThanOrEqualTo(surface.right)
              : lessThanOrEqualTo(surface.left),
          reason: '$label: the arrow is on the wrong edge of the surface',
        );
        expect(
          path.contains(onTheLeft ? apexRight : apexLeft),
          isTrue,
          reason: '$label: the apex must point at the trigger',
        );
        expect(
          path.contains(onTheLeft ? apexLeft : apexRight),
          isFalse,
          reason: '$label: ...and not back into the surface',
        );

        await unhover(tester);
      }
    });

    testWidgets('above and below never mirror', (tester) async {
      // Vertical has no reading order — the same rule that keeps the vertical
      // arrow keys unmirrored in `inputs/slider.dart:700-716`. The arrow's own
      // apex is at width / 2, so it is symmetric and mirrors to itself.
      await pump(
        tester,
        const FluentTooltip(
          withArrow: true,
          content: Text('Tip', key: tip),
          child: Text('trigger', key: trigger),
        ),
        direction: TextDirection.rtl,
      );
      await hover(tester, find.byKey(trigger));

      final target = tester.getRect(find.byKey(trigger));
      final surface = surfaceRect(tester);
      expect(surface.center.dx, closeTo(target.center.dx, 0.01));
      expect(target.top - surface.bottom, 10, reason: 'offset 4 plus arrow 6');
    });
  });

  group('staying inside the overlay', () {
    // Fluent React v9's tooltip positions through `usePositioning`, whose
    // middleware chain runs `flip` and then `shift` unless `pinned` is set
    // (`react-positioning/.../usePositioningOptions.ts:159-168`), and
    // `useTooltipBase.tsx:91-99` never pins. Both measure overflow against
    // floating-ui's defaults — the clipping ancestors inside the viewport,
    // padding 0 (`detectOverflow.ts:56-60`) — whose analogue is the Overlay.
    // A 28px square is a toolbar button; the surface around this content is
    // about 103 wide, so centring it on the square overhangs any edge.
    const square = SizedBox.square(key: trigger, dimension: 28);
    const content = Text('Toolbar tooltip', key: tip);

    Rect overlayRect(WidgetTester tester) =>
        Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;

    // Two probes inside the vertical arrow's 12 x 6 box, each falling inside
    // exactly one triangle: the apex-up one spans x in [6 - y, 6 + y], the
    // apex-down one x in [y, 12 - y].
    const apexUp = Offset(2, 5);
    const apexDown = Offset(2, 1);

    testWidgets('a side with no room flips to the opposite side', (
      tester,
    ) async {
      const cases = <(Alignment, FluentTooltipPosition)>[
        (Alignment.topCenter, FluentTooltipPosition.above),
        (Alignment.bottomCenter, FluentTooltipPosition.below),
      ];
      for (final (alignment, position) in cases) {
        await pump(
          tester,
          FluentTooltip(position: position, content: content, child: square),
          alignment: alignment,
        );
        await hover(tester, find.byKey(trigger));

        final target = tester.getRect(find.byKey(trigger));
        final surface = surfaceRect(tester);
        final flippedBelow = position == FluentTooltipPosition.above;
        expect(
          flippedBelow
              ? surface.top - target.bottom
              : target.top - surface.bottom,
          FluentSpacing.xs,
          reason: '${position.name}: flipped, at the same 4px offset',
        );
        expect(
          tester.binding.transientCallbackCount,
          0,
          reason: 'the flip is decided in layout, not over later frames',
        );
        await unhover(tester);
      }
    });

    testWidgets('a short side is kept when the opposite side is shorter', (
      tester,
    ) async {
      // floating-ui's `bestFit` fallback (`flip.ts:180-209`): when neither
      // side fits, the one that overflows least wins. A 572-tall surface fits
      // neither 515 above nor 57 below, so it stays above.
      await pump(
        tester,
        const FluentTooltip(
          content: SizedBox(key: tip, width: 40, height: 560),
          child: square,
        ),
        alignment: const Alignment(0, 0.8),
      );
      await hover(tester, find.byKey(trigger));

      final target = tester.getRect(find.byKey(trigger));
      expect(target.top - surfaceRect(tester).bottom, FluentSpacing.xs);
    });

    testWidgets('the surface shifts along its edge to stay inside', (
      tester,
    ) async {
      // A toolbar at y = 0 with its end buttons against the window edges —
      // the case `below` alone does not fix.
      for (final alignment in <Alignment>[
        Alignment.topRight,
        Alignment.topLeft,
      ]) {
        await pump(
          tester,
          const FluentTooltip(
            position: FluentTooltipPosition.below,
            content: content,
            child: square,
          ),
          alignment: alignment,
        );
        await hover(tester, find.byKey(trigger));

        final bounds = overlayRect(tester);
        final target = tester.getRect(find.byKey(trigger));
        final surface = surfaceRect(tester);
        final label = '$alignment';
        expect(
          surface.top,
          target.bottom + FluentSpacing.xs,
          reason: '$label: still below',
        );
        expect(
          surface.left,
          greaterThanOrEqualTo(bounds.left),
          reason: '$label: inside the left edge',
        );
        expect(
          surface.right,
          lessThanOrEqualTo(bounds.right),
          reason: '$label: inside the right edge',
        );
        // `shift` clamps and no more: padding 0, so the surface lands flush.
        expect(
          alignment.x > 0 ? surface.right : surface.left,
          alignment.x > 0 ? bounds.right : bounds.left,
          reason: '$label: shifted exactly as far as needed',
        );
        await unhover(tester);
      }
    });

    testWidgets('before and after flip to the other reading side', (
      tester,
    ) async {
      const cases =
          <
            (
              TextDirection,
              Alignment,
              FluentTooltipPosition,
              FluentTooltipPosition,
            )
          >[
            // (direction, edge, preferred, resolved)
            (
              TextDirection.ltr,
              Alignment.centerLeft,
              FluentTooltipPosition.before,
              FluentTooltipPosition.after,
            ),
            (
              TextDirection.ltr,
              Alignment.centerRight,
              FluentTooltipPosition.after,
              FluentTooltipPosition.before,
            ),
            (
              TextDirection.rtl,
              Alignment.centerRight,
              FluentTooltipPosition.before,
              FluentTooltipPosition.after,
            ),
            (
              TextDirection.rtl,
              Alignment.centerLeft,
              FluentTooltipPosition.after,
              FluentTooltipPosition.before,
            ),
          ];

      for (final (direction, alignment, preferred, resolved) in cases) {
        await pump(
          tester,
          FluentTooltip(
            position: preferred,
            withArrow: true,
            content: content,
            child: square,
          ),
          direction: direction,
          alignment: alignment,
        );
        await hover(tester, find.byKey(trigger));

        final target = tester.getRect(find.byKey(trigger));
        final surface = surfaceRect(tester);
        final arrow = tester.getRect(arrowFinder);
        final path = arrowPathOf(tester);
        // Pushed off the right edge, so it lands on the trigger's left.
        final onTheLeft = alignment.x > 0;
        final label = '${direction.name}/${preferred.name}';

        expect(
          arrowOf(tester).position,
          resolved,
          reason: '$label: the arrow is drawn for the side it landed on',
        );
        expect(
          onTheLeft ? arrow.right : arrow.left,
          onTheLeft
              ? target.left - FluentSpacing.xs
              : target.right + FluentSpacing.xs,
          reason: '$label: the arrow stands 4 off the trigger',
        );
        expect(
          onTheLeft ? surface.right : surface.left,
          onTheLeft ? arrow.left : arrow.right,
          reason: '$label: the surface sits behind its arrow',
        );
        expect(
          path.contains(onTheLeft ? apexRight : apexLeft),
          isTrue,
          reason: '$label: the apex must point at the trigger',
        );
        expect(
          path.contains(onTheLeft ? apexLeft : apexRight),
          isFalse,
          reason: '$label: ...and not back into the surface',
        );
        await unhover(tester);
      }
    });

    testWidgets('the arrow follows a flip and keeps pointing at the trigger', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentTooltip(withArrow: true, content: content, child: square),
        alignment: Alignment.topRight,
      );
      await hover(tester, find.byKey(trigger));

      final target = tester.getRect(find.byKey(trigger));
      final surface = surfaceRect(tester);
      final arrow = tester.getRect(arrowFinder);
      final path = arrowPathOf(tester);

      expect(arrowOf(tester).position, FluentTooltipPosition.below);
      expect(arrow.top, target.bottom + FluentSpacing.xs);
      expect(surface.top, arrow.bottom, reason: 'the arrow sits on top');
      expect(path.contains(apexUp), isTrue, reason: 'apex up, at the trigger');
      expect(path.contains(apexDown), isFalse);
      expect(surface.right, overlayRect(tester).right, reason: 'shifted');
      // floating-ui's `arrow` middleware centres the arrow on the reference,
      // not on the floating element (`arrow.ts:72-86`), so a shifted surface
      // still points at its trigger.
      expect(arrow.center.dx, target.center.dx);
    });

    testWidgets('the surface still follows a trigger that moves', (
      tester,
    ) async {
      // The placement is decided against the trigger as the entry builds; the
      // CompositedTransformFollower is what keeps it glued afterwards. The
      // translate repaints only, so nothing rebuilds or relays the entry.
      final nudge = ValueNotifier<Offset>(Offset.zero);
      addTearDown(nudge.dispose);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Center(
            child: ValueListenableBuilder<Offset>(
              valueListenable: nudge,
              builder: (context, value, child) =>
                  Transform.translate(offset: value, child: child),
              child: const FluentTooltip(content: content, child: square),
            ),
          ),
        ),
      );
      await hover(tester, find.byKey(trigger));
      final before = surfaceRect(tester);

      nudge.value = const Offset(30, 20);
      await tester.pump();
      expect(surfaceRect(tester), before.shift(const Offset(30, 20)));
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentTooltipBaseState(
        position: FluentTooltipPosition.above,
        withArrow: true,
        content: Text('Tip', key: tip),
      );
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        buildFluentTooltip(
          base,
          FluentTooltipStyle.from(
            backgroundColor: mine,
            borderRadius: FluentRadius.allLarge,
          ),
          const <WidgetState>{},
        ),
      );
      await tester.pump();
      expect(decorationOf(tester).color, mine);
      expect(decorationOf(tester).borderRadius, FluentRadius.allLarge);
      expect(arrowOf(tester).color, mine);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentTooltipState(
        appearance: FluentTooltipAppearance.brand,
        content: const Text('Tip', key: tip),
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final adjusted = resolveFluentTooltipStyle(
        state,
        theme,
      ).merge(FluentTooltipStyle.from(borderRadius: FluentRadius.allCircular));

      await pump(
        tester,
        buildFluentTooltip(state, adjusted, const <WidgetState>{}),
      );
      await tester.pump();
      expect(decorationOf(tester).color, theme.colors.brandBackground);
      expect(decorationOf(tester).borderRadius, FluentRadius.allCircular);
    });
  });
}

/// Captures what a painter draws so the arrow's apex can be probed directly.
/// Same shape as the chart painter tests use — see
/// `test/charts/gauge_needle_test.dart:13`.
class _RecordingCanvas implements Canvas {
  final List<Path> paths = <Path>[];

  @override
  void drawPath(Path path, Paint paint) => paths.add(path);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
