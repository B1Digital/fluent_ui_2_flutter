import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentPopover` is the foundation of the overlay wave, so these tests cover
/// three things beyond token fidelity: that the surface reaches the `Overlay`
/// with the ambient `FluentTheme` intact, that it plays upstream's **enter
/// only** motion and collapses it under reduced motion, and that dismissal
/// hands focus back to the trigger.
void main() {
  const trigger = Key('trigger');
  const body = Key('body');

  /// Drives a popover whose `open` starts at [open] and is thereafter owned by
  /// this setter, so a test can watch the widget close *itself*.
  late void Function({required bool show}) setOpen;
  late List<bool> changes;

  /// The `open` the popover was last built with, so a test trigger can *toggle*
  /// rather than only ever close.
  late bool currentOpen;

  Future<void> pump(
    WidgetTester tester, {
    bool open = false,
    bool enabled = true,
    FluentThemeData? theme,
    FluentPopoverAppearance appearance = FluentPopoverAppearance.normal,
    FluentPopoverSize size = FluentPopoverSize.medium,
    FluentPopoverPosition position = FluentPopoverPosition.above,
    FluentPopoverAlign align = FluentPopoverAlign.center,
    bool withArrow = false,
    FluentPopoverStyle? style,
    FluentPopoverStyle? themeStyle,
    Widget content = const Text('Body', key: body),
    Widget child = const Text('trigger', key: trigger),
    String? semanticLabel,
    bool reducedMotion = false,
    TextDirection? textDirection,
    Widget? behind,
  }) {
    changes = <bool>[];
    return tester.pumpWidget(
      FluentApp(
        theme:
            theme ??
            FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reducedMotion),
          child: StatefulBuilder(
            builder: (context, setState) {
              setOpen = ({required bool show}) => setState(() => open = show);
              currentOpen = open;
              Widget popover = FluentPopover(
                open: open,
                onOpenChanged: enabled
                    ? (value) {
                        changes.add(value);
                        setState(() => open = value);
                      }
                    : null,
                appearance: appearance,
                size: size,
                position: position,
                align: align,
                withArrow: withArrow,
                style: style,
                semanticLabel: semanticLabel,
                content: content,
                child: child,
              );
              if (themeStyle != null) {
                popover = FluentPopoverTheme(style: themeStyle, child: popover);
              }
              // Deliberately *inside* `home`, which is below the Navigator that
              // owns the Overlay: the entry therefore does not inherit this, and
              // an RTL run only passes if the widget carries the direction
              // across the boundary itself.
              Widget centred = Center(child: popover);
              if (behind != null) {
                // Pinned to the top-left corner, well clear of the centred
                // trigger and of the surface above it, so `tapAt(5, 5)` is
                // unambiguously a tap on the page *behind* an open popover.
                // `Alignment.topLeft` rather than the default
                // `AlignmentDirectional.topStart` so the Stack needs no
                // ambient [Directionality] on the LTR runs.
                centred = Stack(
                  alignment: Alignment.topLeft,
                  children: <Widget>[
                    Positioned(
                      left: 0,
                      top: 0,
                      width: 80,
                      height: 40,
                      child: behind,
                    ),
                    centred,
                  ],
                );
              }
              return textDirection == null
                  ? centred
                  : Directionality(
                      textDirection: textDirection,
                      child: centred,
                    );
            },
          ),
        ),
      ),
    );
  }

  /// Opens the popover and settles the two frames it takes to reach the
  /// overlay: one to rebuild this widget, one for the entry the post-frame
  /// callback inserted. Motion is deliberately *not* settled.
  Future<void> open(WidgetTester tester) async {
    setOpen(show: true);
    await tester.pump();
    await tester.pump();
  }

  /// The popover's own decorated surface, found through its content rather than
  /// through the trigger — the surface lives in the overlay.
  BoxDecoration decorationOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.ancestor(
          of: find.byKey(body),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((d) => d.borderRadius != null);

  EdgeInsets paddingOf(WidgetTester tester) => tester
      .widget<Padding>(
        find
            .ancestor(of: find.byKey(body), matching: find.byType(Padding))
            .first,
      )
      .padding
      .resolve(TextDirection.ltr);

  final arrowFinder = find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is FluentPopoverArrowPainter,
  );

  FluentPopoverArrowPainter arrowOf(WidgetTester tester) =>
      tester.widget<CustomPaint>(arrowFinder).painter!
          as FluentPopoverArrowPainter;

  double opacityOf(WidgetTester tester) => tester
      .widget<Opacity>(
        find
            .ancestor(of: find.byKey(body), matching: find.byType(Opacity))
            .first,
      )
      .opacity;

  /// The entrance slide still outstanding, read off the `Transform` the
  /// entrance builds rather than off a controller nobody can reach.
  Offset slideOf(WidgetTester tester) {
    final transform = tester
        .widget<Transform>(
          find
              .ancestor(of: find.byKey(body), matching: find.byType(Transform))
              .first,
        )
        .transform;
    return Offset(transform.storage[12], transform.storage[13]);
  }

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('popover');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 3);
      expect(spec.properties['Style'], ['Default', 'Inverted', 'Brand']);
    });

    testWidgets('the surface matches every appearance', (tester) async {
      const names = {
        FluentPopoverAppearance.normal: 'Default',
        FluentPopoverAppearance.brand: 'Brand',
        FluentPopoverAppearance.inverted: 'Inverted',
      };

      for (final entry in names.entries) {
        final variant = spec.variant({'Style': entry.value});

        await pump(tester, appearance: entry.key);
        await open(tester);
        await tester.pumpAndSettle();

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
          expect(border.color.a, 0, reason: '${entry.value}: stroke alpha');
        } else {
          expect(
            border.color,
            expectedStroke,
            reason:
                '${entry.value}: stroke (token ${variant.token('strokes')})',
          );
        }

        final padding = paddingOf(tester);
        expect(
          padding,
          variant.padding,
          reason: '${entry.value}: padding — Popover size mode Medium',
        );

        // The variant frame's own shadow: Shadow/Ambient (0,0) blur 2 plus
        // Shadow/Key (0,8) blur 16, which is FluentElevation.shadow16.
        expect(
          decoration.boxShadow,
          FluentThemeData.light(
            fontPlatform: FluentFontPlatform.web,
          ).shadow(FluentElevation.shadow16),
          reason: '${entry.value}: elevation',
        );
      }
    });

    testWidgets('the size ramp is the Popover size collection', (tester) async {
      // Small / Medium / Large bind Spacing/{M,L,XL} on BOTH axes, which is
      // also usePopoverSurfaceStyles' 12px / 16px / 20px padding. The Medium
      // number is the one the variant frame itself carries, asserted above.
      const expected = <FluentPopoverSize, double>{
        FluentPopoverSize.small: FluentSpacing.m,
        FluentPopoverSize.medium: FluentSpacing.l,
        FluentPopoverSize.large: FluentSpacing.xl,
      };
      expect(
        expected[FluentPopoverSize.medium],
        spec.variant({'Style': 'Default'}).padding!.left,
      );

      for (final entry in expected.entries) {
        await pump(tester, size: entry.key);
        await open(tester);
        await tester.pumpAndSettle();
        expect(
          paddingOf(tester),
          EdgeInsets.all(entry.value),
          reason: '${entry.key.name}: padding',
        );
      }
    });

    testWidgets('the content takes body1, not the placeholder ramp', (
      tester,
    ) async {
      // The fixture's `text` block describes the "SWAP AREA WITH YOUR
      // COMPONENT" placeholder instance — Font size/100, 10/14, in a brand
      // tone — not the popover's own type. Its ramp is React's
      // `typographyStyles.body1`, and Figma is silent on it.
      final spec = loadSpec('popover');
      expect(spec.variant({'Style': 'Default'}).text!.fontSize, 10);

      await pump(tester);
      await open(tester);
      await tester.pumpAndSettle();

      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final style = resolvedTextStyleOf(tester, of: find.byKey(body));
      expect(style.fontSize, theme.typography.body1.fontSize);
      expect(style.height, theme.typography.body1.height);
      expect(style.color, theme.colors.neutralForeground1);
    });

    testWidgets('the arrow is the Figma triangle, and is opt-in', (
      tester,
    ) async {
      await pump(tester);
      await open(tester);
      expect(
        arrowFinder,
        findsNothing,
        reason:
            'every Figma arrow layer ships hidden; withArrow defaults false',
      );

      // Every one of the twelve hidden layers is a 16 x 8 unstroked triangle,
      // filled with the same background token as the surface. Upstream's
      // arrowHeights agree: medium and large are 8.
      for (final position in FluentPopoverPosition.values) {
        await pump(tester, position: position, withArrow: true);
        await open(tester);
        await tester.pumpAndSettle();

        final vertical =
            position == FluentPopoverPosition.above ||
            position == FluentPopoverPosition.below;
        expect(
          tester.getSize(arrowFinder),
          vertical ? const Size(16, 8) : const Size(8, 16),
          reason: '${position.name}: arrow size',
        );
        expect(
          arrowOf(tester).color,
          decorationOf(tester).color,
          reason: '${position.name}: the arrow carries the surface fill',
        );
        expect(arrowOf(tester).position, position);
      }

      // Small drops to a 6-tall arrow, upstream's arrowHeights.small.
      await pump(tester, size: FluentPopoverSize.small, withArrow: true);
      await open(tester);
      await tester.pumpAndSettle();
      expect(tester.getSize(arrowFinder), const Size(12, 6));
    });

    testWidgets('an aligned arrow is inset by the surface padding', (
      tester,
    ) async {
      // Figma pins `Top edge - left` at x = 16 on a 282-wide medium surface and
      // `Top edge - right` at 250 — the same 16 in from either edge. React's
      // arrowPadding is 2 * borderRadius = 8; Figma wins.
      for (final align in <FluentPopoverAlign, double>{
        FluentPopoverAlign.start: 1,
        FluentPopoverAlign.end: -1,
      }.entries) {
        await pump(
          tester,
          align: align.key,
          withArrow: true,
          content: const SizedBox(key: body, width: 200, height: 20),
        );
        await open(tester);
        await tester.pumpAndSettle();

        final surface = tester.getRect(find.byKey(body));
        final arrow = tester.getRect(arrowFinder);
        final gap = align.value > 0
            ? arrow.left - (surface.left - FluentSpacing.l)
            : (surface.right + FluentSpacing.l) - arrow.right;
        expect(
          gap,
          FluentSpacing.l,
          reason: '${align.key.name}: arrow inset from the surface edge',
        );
      }
    });
  });

  group('motion', () {
    // PopoverSurfaceMotion.ts: enter is [fadeAtom, slideAtom] at
    // durationSlower / curveDecelerateMid with distance = 10, and exit is a
    // literal empty list.
    testWidgets('enters with a fade and a 10px direction-aware slide', (
      tester,
    ) async {
      const towards = <FluentPopoverPosition, Offset>{
        FluentPopoverPosition.above: Offset(0, 10),
        FluentPopoverPosition.below: Offset(0, -10),
        FluentPopoverPosition.before: Offset(10, 0),
        FluentPopoverPosition.after: Offset(-10, 0),
      };

      for (final entry in towards.entries) {
        await pump(tester, position: entry.key);
        await open(tester);

        expect(opacityOf(tester), 0, reason: '${entry.key.name}: first frame');
        expect(
          slideOf(tester),
          entry.value,
          reason: '${entry.key.name}: starts 10px towards the anchor',
        );

        await tester.pump(const Duration(milliseconds: 200));
        expect(
          opacityOf(tester),
          greaterThan(0),
          reason: '${entry.key.name}: mid-flight',
        );
        expect(opacityOf(tester), lessThan(1));

        await tester.pump(const Duration(milliseconds: 200));
        expect(opacityOf(tester), 1, reason: '${entry.key.name}: settled');
        expect(slideOf(tester), Offset.zero);
      }
    });

    testWidgets('the spec is durationSlower on curveDecelerateMid', (
      tester,
    ) async {
      expect(FluentMotionSpec.popover.duration, FluentDuration.slower);
      expect(FluentMotionSpec.popover.curve, FluentCurve.decelerateMid);

      await pump(tester);
      await open(tester);
      // One millisecond short of the full 400 must still be in flight.
      await tester.pump(const Duration(milliseconds: 399));
      expect(opacityOf(tester), lessThan(1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(opacityOf(tester), 1);
    });

    testWidgets('there is no exit — a closed popover is simply gone', (
      tester,
    ) async {
      await pump(tester);
      await open(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(body), findsOneWidget);

      setOpen(show: false);
      await tester.pump();
      await tester.pump();
      expect(
        find.byKey(body),
        findsNothing,
        reason: 'upstream ships exit: [] — nothing fades out',
      );
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('reduced motion jumps straight to the end state', (
      tester,
    ) async {
      await pump(tester, reducedMotion: true);
      await open(tester);

      expect(
        opacityOf(tester),
        1,
        reason: 'the first painted frame is already opaque',
      );
      expect(slideOf(tester), Offset.zero, reason: 'and already in place');
      expect(
        tester.binding.transientCallbackCount,
        0,
        reason: 'no ticker may be started at all',
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
        themeStyle: FluentPopoverStyle.from(backgroundColor: themed),
        style: FluentPopoverStyle.from(backgroundColor: explicit),
      );
      await open(tester);
      expect(decorationOf(tester).color, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        themeStyle: FluentPopoverStyle.from(backgroundColor: themed),
      );
      await open(tester);
      expect(decorationOf(tester).color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        appearance: FluentPopoverAppearance.brand,
        style: FluentPopoverStyle.from(borderRadius: FluentRadius.allCircular),
      );
      await open(tester);

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
      var open = false;
      late StateSetter setState;

      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.brandBackground: magenta},
            child: StatefulBuilder(
              builder: (context, setter) {
                setState = setter;
                return Center(
                  child: FluentPopover(
                    open: open,
                    onOpenChanged: (value) => setState(() => open = value),
                    appearance: FluentPopoverAppearance.brand,
                    content: const Text('Body', key: body),
                    child: const Text('trigger', key: trigger),
                  ),
                );
              },
            ),
          ),
        ),
      );
      setState(() => open = true);
      await tester.pump();
      await tester.pump();

      expect(decorationOf(tester).color, magenta);
    });

    testWidgets('high contrast draws a visible border', (tester) async {
      await pump(
        tester,
        theme: FluentThemeData.highContrast(
          fontPlatform: FluentFontPlatform.web,
        ),
      );
      await open(tester);

      // transparentStroke resolves to canvasText in high contrast, so the
      // border that is invisible in light mode has to read here. A hardcoded
      // Colors.transparent would silently stay invisible.
      final border = decorationOf(tester).border;
      expect(border, isNotNull);
      expect(border!.top.color.a, 1.0);
      expect(border.top.width, greaterThan(0));
    });

    testWidgets('high contrast keeps a visible border on every appearance', (
      tester,
    ) async {
      for (final appearance in FluentPopoverAppearance.values) {
        await pump(
          tester,
          appearance: appearance,
          theme: FluentThemeData.highContrast(
            fontPlatform: FluentFontPlatform.web,
          ),
        );
        await open(tester);
        final border = decorationOf(tester).border!.top;
        expect(border.color.a, 1.0, reason: '${appearance.name}: border alpha');
        if (appearance != FluentPopoverAppearance.brand) {
          // The neutral and inverted surfaces bind `transparentStroke`, which
          // is the only thing separating them from the page in high contrast,
          // so it has to differ from the fill. Brand does not need it: its own
          // fill already contrasts with the high-contrast canvas, and every
          // brand token collapses onto the same tone there.
          expect(
            border.color,
            isNot(decorationOf(tester).color),
            reason: '${appearance.name}: border must not vanish into the fill',
          );
        }
      }
    });

    testWidgets('the inverted content stays readable in high contrast', (
      tester,
    ) async {
      // Regression: neutralForegroundInverted mapped to `highlightText`, which
      // is canvas's own colour — so an inverted popover painted its text into
      // its own fill. Outlined, but empty. High contrast has no notion of an
      // inverted surface; everything collapses onto the canvas pair, so the
      // readable foreground is `canvasText`. Fixed in FluentHighContrastColors,
      // which is why FluentTooltip stopped being invisible at the same time.
      await pump(
        tester,
        appearance: FluentPopoverAppearance.inverted,
        theme: FluentThemeData.highContrast(
          fontPlatform: FluentFontPlatform.web,
        ),
      );
      await open(tester);
      await tester.pumpAndSettle();

      expect(
        resolvedTextStyleOf(tester, of: find.byKey(body)).color,
        isNot(decorationOf(tester).color),
        reason: 'the label must not paint into the surface it sits on',
      );
      expect(decorationOf(tester).border!.top.color.a, 1.0);
    });
  });

  group('reading order', () {
    // `position` and `align` are documented in reading order, and the surface
    // builds in an OverlayEntry hanging off the Navigator — a branch the
    // trigger's own Directionality never reaches, and one InheritedTheme.capture
    // cannot carry it into. Both halves are asserted here: where the surface
    // lands, and what its content inherits.
    testWidgets('`before` opens on the reading-start side either way', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        await pump(
          tester,
          textDirection: direction,
          position: FluentPopoverPosition.before,
          withArrow: true,
          content: const SizedBox(key: body, width: 60, height: 20),
          child: const SizedBox(key: trigger, width: 40, height: 20),
        );
        await open(tester);
        await tester.pumpAndSettle();

        final anchor = tester.getRect(find.byKey(trigger));
        final surface = tester.getRect(find.byKey(body));
        if (direction == TextDirection.rtl) {
          expect(
            surface.left,
            greaterThan(anchor.right),
            reason: 'reading runs right to left, so `before` is the right side',
          );
        } else {
          expect(
            surface.right,
            lessThan(anchor.left),
            reason: '`before` is the left side in LTR',
          );
        }
        expect(
          Directionality.of(tester.element(find.byKey(body))),
          direction,
          reason:
              '$direction: the content sees the direction at the trigger, '
              'not the one at the Navigator',
        );
        expect(
          arrowOf(tester).textDirection,
          direction,
          reason: '$direction: the apex mirrors with the Row carrying it',
        );
      }
    });

    testWidgets('`align: start` pins the edge reading starts at', (
      tester,
    ) async {
      // A surface wider than its anchor hangs off the end, so flush `start`
      // means the left edges line up in LTR and the right edges in RTL. What is
      // measured is the content's edge, one surface padding inside the
      // surface's own.
      for (final direction in TextDirection.values) {
        await pump(
          tester,
          textDirection: direction,
          align: FluentPopoverAlign.start,
          content: const SizedBox(key: body, width: 200, height: 20),
          child: const SizedBox(key: trigger, width: 40, height: 20),
        );
        await open(tester);
        await tester.pumpAndSettle();

        final anchor = tester.getRect(find.byKey(trigger));
        final surface = tester.getRect(find.byKey(body));
        expect(
          direction == TextDirection.rtl
              ? anchor.right - surface.right
              : surface.left - anchor.left,
          moreOrLessEquals(FluentSpacing.l),
          reason: '$direction: the start edges are flush',
        );
      }
    });
  });

  group('behaviour', () {
    testWidgets('open drives the overlay', (tester) async {
      await pump(tester);
      expect(find.byKey(body), findsNothing);

      await open(tester);
      expect(find.byKey(body), findsOneWidget);

      setOpen(show: false);
      await tester.pump();
      await tester.pump();
      expect(find.byKey(body), findsNothing);
    });

    testWidgets('a popover that starts open reaches the overlay', (
      tester,
    ) async {
      await pump(tester, open: true);
      await tester.pump();
      expect(find.byKey(body), findsOneWidget);
    });

    testWidgets('disabled is a real state, not a visual treatment', (
      tester,
    ) async {
      await pump(tester, open: true, enabled: false);
      await tester.pump();
      await tester.pump();
      expect(
        find.byKey(body),
        findsNothing,
        reason: 'a disabled popover never reaches the overlay at all',
      );
    });

    testWidgets('disabling while open tears the surface down', (tester) async {
      await pump(tester);
      await open(tester);
      expect(find.byKey(body), findsOneWidget);

      await pump(tester, open: true, enabled: false);
      await tester.pump();
      expect(find.byKey(body), findsNothing);
    });

    testWidgets('an outside tap dismisses', (tester) async {
      await pump(tester);
      await open(tester);
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      await tester.pump();
      expect(changes, <bool>[false]);
      expect(find.byKey(body), findsNothing);
    });

    testWidgets('a tap inside does not dismiss', (tester) async {
      await pump(tester);
      await open(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(body));
      await tester.pump();
      expect(changes, isEmpty);
      expect(find.byKey(body), findsOneWidget);
    });

    testWidgets('a tap on the surface\'s own padding does not dismiss', (
      tester,
    ) async {
      // The barrier used to catch anything that fell through the surface.
      // Now the surface has to answer the hit test itself or the tap reads as
      // "outside" — it does, because `RenderDecoratedBox.hitTestSelf` covers
      // the whole rounded rect, padding included.
      await pump(tester);
      await open(tester);
      await tester.pumpAndSettle();

      final surface = tester.getRect(
        find
            .ancestor(of: find.byKey(body), matching: find.byType(Padding))
            .first,
      );
      await tester.tapAt(surface.topLeft + const Offset(4, 4));
      await tester.pump();
      await tester.pump();
      expect(changes, isEmpty);
      expect(find.byKey(body), findsOneWidget);
    });

    testWidgets('an outside tap lands on the control behind it', (
      tester,
    ) async {
      // The defect this replaced: a full-screen `HitTestBehavior.opaque`
      // barrier over the page dismissed *and* ate the click, so a button behind
      // an open popover took two clicks. Upstream's document-level
      // `useOnClickOutside` dismisses without consuming, and so does a
      // TapRegion group.
      var behind = 0;
      await pump(
        tester,
        behind: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => behind++,
          child: const SizedBox.expand(),
        ),
      );
      await open(tester);
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      await tester.pump();
      expect(behind, 1, reason: 'the click dismisses and still lands');
      expect(changes, <bool>[false]);
      expect(find.byKey(body), findsNothing);
    });

    testWidgets('a tap on a toggling trigger while open closes it once', (
      tester,
    ) async {
      // A path that could not run before: the barrier sat above the trigger, so
      // the trigger's own handler never fired while the popover was open. Now
      // it does — and because the trigger shares the surface's group, the
      // outside-tap path stays quiet, so the popover closes once rather than
      // closing here and reopening in the handler.
      var taps = 0;
      await pump(
        tester,
        child: GestureDetector(
          key: trigger,
          behavior: HitTestBehavior.opaque,
          onTap: () {
            taps++;
            setOpen(show: !currentOpen);
          },
          child: const SizedBox(width: 60, height: 24),
        ),
      );
      await open(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(trigger));
      await tester.pump();
      await tester.pump();
      expect(taps, 1, reason: 'the barrier used to swallow this click whole');
      expect(
        changes,
        isEmpty,
        reason: 'the trigger is inside the group, so no outside tap fires',
      );
      expect(find.byKey(body), findsNothing);
    });
  });

  group('keyboard and focus', () {
    testWidgets('Escape closes and focus returns to the trigger', (
      tester,
    ) async {
      final node = FocusNode(debugLabel: 'trigger');
      addTearDown(node.dispose);

      await pump(
        tester,
        child: Focus(
          focusNode: node,
          child: const SizedBox(key: trigger, width: 40, height: 20),
        ),
      );
      node.requestFocus();
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);

      await open(tester);
      await tester.pumpAndSettle();
      expect(
        node.hasPrimaryFocus,
        isFalse,
        reason: 'the surface takes focus while it is open',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump();
      expect(changes, <bool>[false]);
      expect(find.byKey(body), findsNothing);
      expect(
        node.hasPrimaryFocus,
        isTrue,
        reason: 'closing hands focus back to whatever held it',
      );
    });

    testWidgets('focus returns after an outside tap too', (tester) async {
      final node = FocusNode(debugLabel: 'trigger');
      addTearDown(node.dispose);

      await pump(
        tester,
        child: Focus(
          focusNode: node,
          child: const SizedBox(key: trigger, width: 40, height: 20),
        ),
      );
      node.requestFocus();
      await tester.pump();

      await open(tester);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      await tester.pump();
      expect(node.hasPrimaryFocus, isTrue);
    });

    testWidgets('an outside tap onto a focusable control keeps it focused', (
      tester,
    ) async {
      // Only reachable now that no barrier is drawn over the page: the tap
      // dismisses *and* lands, so the control behind takes focus. Handing
      // focus back to the trigger at that point would undo the click the user
      // just made, so the restore is guarded on the surface having held focus.
      final node = FocusNode(debugLabel: 'trigger');
      addTearDown(node.dispose);
      final behindNode = FocusNode(debugLabel: 'behind');
      addTearDown(behindNode.dispose);

      await pump(
        tester,
        child: Focus(
          focusNode: node,
          child: const SizedBox(key: trigger, width: 40, height: 20),
        ),
        behind: Focus(
          focusNode: behindNode,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: behindNode.requestFocus,
            child: const SizedBox.expand(),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();

      await open(tester);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      await tester.pump();
      expect(changes, <bool>[false], reason: 'it still dismisses');
      expect(
        behindNode.hasPrimaryFocus,
        isTrue,
        reason: 'the control the tap landed on keeps the focus it just took',
      );
      expect(node.hasPrimaryFocus, isFalse);
    });

    testWidgets('Escape reaches an ancestor while the popover is closed', (
      tester,
    ) async {
      // The DismissIntent action lives inside the overlay, so it exists only
      // while there is something to dismiss.
      var dismissed = false;
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Actions(
            actions: <Type, Action<Intent>>{
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) {
                  dismissed = true;
                  return null;
                },
              ),
            },
            child: Center(
              child: FluentPopover(
                open: false,
                onOpenChanged: (_) {},
                content: const Text('Body', key: body),
                child: const Focus(
                  autofocus: true,
                  child: SizedBox(key: trigger, width: 40, height: 20),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(dismissed, isTrue);
    });

    testWidgets('Tab stays inside the open surface', (tester) async {
      final first = FocusNode(debugLabel: 'first');
      final second = FocusNode(debugLabel: 'second');
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      await pump(
        tester,
        content: Column(
          key: body,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Focus(
              focusNode: first,
              child: const SizedBox(width: 40, height: 20),
            ),
            Focus(
              focusNode: second,
              child: const SizedBox(width: 40, height: 20),
            ),
          ],
        ),
      );
      await open(tester);
      await tester.pumpAndSettle();

      first.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(second.hasPrimaryFocus, isTrue);

      // ...and wraps rather than escaping into the page behind.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(first.hasPrimaryFocus, isTrue);
    });
  });

  group('semantics', () {
    testWidgets('the surface carries its label and keeps its content', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, semanticLabel: 'More about pricing');
      await open(tester);
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('More about pricing'),
        findsOneWidget,
        reason: 'the popover names itself',
      );
      expect(
        find.bySemanticsLabel('Body'),
        findsOneWidget,
        reason: 'explicitChildNodes keeps the content announceable',
      );
      handle.dispose();
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentPopoverBaseState(
        position: FluentPopoverPosition.above,
        align: FluentPopoverAlign.center,
        withArrow: true,
        content: Text('Body', key: body),
      );
      const mine = Color(0xFF00FF00);

      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Center(
            child: buildFluentPopover(
              base,
              FluentPopoverStyle.from(
                backgroundColor: mine,
                borderRadius: FluentRadius.allLarge,
              ),
              const <WidgetState>{},
            ),
          ),
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
      final state = resolveFluentPopoverState(
        appearance: FluentPopoverAppearance.brand,
        content: const Text('Body', key: body),
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final adjusted = resolveFluentPopoverStyle(
        state,
        theme,
      ).merge(FluentPopoverStyle.from(borderRadius: FluentRadius.allCircular));

      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: Center(
            child: buildFluentPopover(state, adjusted, const <WidgetState>{}),
          ),
        ),
      );
      await tester.pump();
      expect(decorationOf(tester).color, theme.colors.brandBackground);
      expect(decorationOf(tester).borderRadius, FluentRadius.allCircular);
    });

    test(
      'merge is per-property and copyWith replaces only what it is given',
      () {
        const a = FluentPopoverStyle(
          backgroundColor: WidgetStatePropertyAll<Color?>(Color(0xFF000001)),
          arrowInset: WidgetStatePropertyAll<double?>(4),
        );
        const b = FluentPopoverStyle(
          backgroundColor: WidgetStatePropertyAll<Color?>(Color(0xFF000002)),
        );
        final merged = a.merge(b);
        expect(
          merged.backgroundColor!.resolve(const <WidgetState>{}),
          const Color(0xFF000002),
        );
        expect(merged.arrowInset!.resolve(const <WidgetState>{}), 4);
        expect(a.merge(null), a);
        expect(
          a.copyWith(arrowInset: const WidgetStatePropertyAll<double?>(9)) == a,
          isFalse,
        );
        expect(a == a.copyWith(), isTrue);
        expect(a.hashCode, a.copyWith().hashCode);
      },
    );
  });
}
