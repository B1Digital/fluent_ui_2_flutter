import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentSkeleton` is the first component in the package whose motion is a
/// repeating loop rather than a transition, so these tests carry more of the
/// motion contract than a `FluentAnimatedStyle` component needs to: the wave's
/// five Figma keyframes, the pulse's opacity ramp, and the hard requirement that
/// neither runs under reduced motion.
void main() {
  const key = Key('skeleton');

  // Figma writes this set's default marker in lower case — "Rectangle
  // (default)" — where the Button set writes " (Default)". The extractor strips
  // only the capitalised form, so the marker survives into the fixture and has
  // to be spelled out in every lookup here.
  const rectangle = 'Rectangle (default)';

  Future<void> pump(
    WidgetTester tester,
    Widget skeleton, {
    FluentThemeData? theme,
    bool reducedMotion = false,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      builder: reducedMotion
          ? (context, child) => MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: child!,
            )
          : null,
      home: Center(child: skeleton),
    ),
  );

  /// The skeleton paints with a [CustomPaint] rather than a [DecoratedBox], so
  /// `expectSpec` cannot read it back — the painter's public fields are the
  /// resolved values instead.
  FluentSkeletonPainter painterOf(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.descendant(
                  of: find.byKey(key),
                  matching: find.byType(CustomPaint),
                ),
              )
              .painter!
          as FluentSkeletonPainter;

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('skeleton');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 12);
      expect(spec.properties['Shape'], [rectangle, 'Circle']);
      expect(spec.properties['Animated'], ['True', 'False']);
      expect(spec.properties['Frame'], ['1', '2', '3', '4', '5']);
    });

    testWidgets('the stencil surface matches every shape', (tester) async {
      const shapes = {
        FluentSkeletonShape.rectangle: rectangle,
        FluentSkeletonShape.circle: 'Circle',
      };

      for (final entry in shapes.entries) {
        // Animated=False, because the Animated=True rectangle carries a stale
        // radius — see the divergence test below.
        final variant = spec.variant({
          'Shape': entry.value,
          'Animated': 'False',
          'Frame': '1',
        });

        await pump(
          tester,
          FluentSkeleton(
            key: key,
            shape: entry.key,
            width: variant.size.width,
            height: variant.size.height,
          ),
        );

        final painter = painterOf(tester);
        expect(
          painter.backgroundColor,
          variant.fill,
          reason: '${entry.value}: fill (token ${variant.token('fills')})',
        );
        expect(
          painter.borderRadius,
          variant.radius,
          reason: '${entry.value}: radius (token ${variant.token('radius')})',
        );
        expect(
          tester.getSize(find.byKey(key)),
          variant.size,
          reason: '${entry.value}: size',
        );
      }
    });

    test('the Animated axis does not change the rectangle radius', () {
      // Figma's own numbers disagree across the Animated axis: the static
      // rectangle stores 4 and binds `Corner radius/Medium`, while all five
      // animated rectangles store 0 and bind `Corner-radius/Image/Default`.
      // That variable resolves — through `Corner radius/Medium` and
      // `Web/Corner Radius/Medium` — to `Corner-radius/40`, which is 4; it is a
      // remote variable whose mode does not resolve in this file, so the stored
      // raw value is stale. An animation toggle cannot change a corner radius,
      // so both ship as `borderRadiusMedium`. Asserted rather than silently
      // corrected, so a fixture regeneration that fixes Figma trips this.
      expect(
        spec.variant({
          'Shape': rectangle,
          'Animated': 'True',
          'Frame': '1',
        }).radius,
        BorderRadius.zero,
      );
      expect(
        spec.variant({
          'Shape': rectangle,
          'Animated': 'False',
          'Frame': '1',
        }).radius,
        FluentRadius.allMedium,
      );
    });

    testWidgets('the shipped rectangle radius ignores the stale value', (
      tester,
    ) async {
      for (final animation in FluentSkeletonAnimation.values) {
        await pump(
          tester,
          FluentSkeleton(
            key: key,
            animation: animation,
            width: 132,
            height: 132,
          ),
        );
        expect(
          painterOf(tester).borderRadius,
          FluentRadius.allMedium,
          reason: '${animation.name}: radius',
        );
      }
    });

    test('the wave reproduces all five Figma Frame keyframes', () {
      // Frame is Figma showing keyframes, not a widget property. The five
      // `Shimmer` frames of the animated variants sit at x = 0, -132, -264,
      // -396 and +132 over a 132-wide component, i.e. -3W … +W in even steps —
      // and the two extremes (-3W, +W) are exactly the positions at which the
      // band is entirely outside the clip.
      const width = 132.0;
      expect(
        [
          for (final t in [0.0, 0.25, 0.5, 0.75, 1.0])
            fluentSkeletonWaveOffset(t) * width,
        ],
        [-396.0, -264.0, -132.0, 0.0, 132.0],
      );
    });
  });

  group('motion', () {
    testWidgets('the wave runs a 3s ease-in-out loop', (tester) async {
      // Upstream, verbatim: 3s ease-in-out infinite, translate(-100%) to
      // translate(100%). Neither 3s nor `ease-in-out` exists in the Fluent
      // ramps, so both are literals here.
      final style = resolveFluentSkeletonStyle(
        resolveFluentSkeletonState(),
        FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      );
      expect(
        style.motion,
        const FluentMotionSpec(
          duration: Duration(seconds: 3),
          curve: Curves.easeInOut,
        ),
      );

      await pump(
        tester,
        const FluentSkeleton(key: key, width: 132, height: 132),
      );
      final start = painterOf(tester).bandOffsetFactor;

      await tester.pump(const Duration(milliseconds: 750));
      expect(
        painterOf(tester).bandOffsetFactor,
        isNot(start),
        reason: 'the band must move',
      );
      expect(tester.binding.hasScheduledFrame, isTrue, reason: 'must repeat');

      await tester.pump(const Duration(milliseconds: 2250));
      expect(
        painterOf(tester).bandOffsetFactor,
        moreOrLessEquals(start),
        reason: 'the loop must close after exactly 3s',
      );
    });

    test('the pulse ramps opacity 1 to 0.4 to 1 over 1s', () {
      final style = resolveFluentSkeletonStyle(
        resolveFluentSkeletonState(animation: FluentSkeletonAnimation.pulse),
        FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      );
      expect(
        style.motion,
        const FluentMotionSpec(
          duration: Duration(seconds: 1),
          curve: Curves.easeInOut,
        ),
      );

      expect(fluentSkeletonPulseOpacity(0), 1.0);
      expect(fluentSkeletonPulseOpacity(0.5), moreOrLessEquals(0.4));
      expect(fluentSkeletonPulseOpacity(1), 1.0);
      // Eased, not linear: the midpoint of each half sits at the curve's own
      // half, which for a symmetric ease-in-out is 0.5 of the 1 → 0.4 span.
      expect(
        fluentSkeletonPulseOpacity(0.25),
        moreOrLessEquals(0.7, epsilon: 0.01),
      );
    });

    testWidgets('the pulse fades the whole surface, not the token', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentSkeleton(
          key: key,
          animation: FluentSkeletonAnimation.pulse,
          width: 132,
          height: 132,
        ),
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

      await tester.pump(const Duration(milliseconds: 500));
      final opacity = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(opacity.opacity.value, moreOrLessEquals(0.4));
      // The token itself is untouched — a pulse is an opacity animation, not a
      // recomputed colour.
      expect(painterOf(tester).backgroundColor, theme.colors.neutralStencil1);
      expect(painterOf(tester).waveColor, isNull, reason: 'pulse has no band');
    });

    testWidgets('the Animated axis selects the band Figma draws', (
      tester,
    ) async {
      // Animated=True: a 3x-wide band with the five-stop plateau
      // (0, 0.3385…, 0.5, 0.6510…, 1). Animated=False: a component-wide band
      // with three stops, centred and still.
      await pump(
        tester,
        const FluentSkeleton(key: key, width: 132, height: 132),
      );
      expect(painterOf(tester).bandWidthFactor, 3);
      expect(painterOf(tester).bandStops, [
        0,
        0.3385416567325592,
        0.5,
        0.6510416865348816,
        1,
      ]);

      await pump(
        tester,
        const FluentSkeleton(
          key: key,
          animation: FluentSkeletonAnimation.none,
          width: 132,
          height: 132,
        ),
      );
      expect(painterOf(tester).bandWidthFactor, 1);
      expect(painterOf(tester).bandStops, [0, 0.5, 1]);
      expect(painterOf(tester).bandOffsetFactor, 0);
      await tester.pumpAndSettle();
    });

    testWidgets('reduced motion renders the wave as Figma Animated=False', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentSkeleton(key: key, width: 132, height: 132),
        reducedMotion: true,
      );
      // pumpAndSettle would time out against a repeating controller, so this
      // settling at all is the assertion that nothing is running.
      await tester.pumpAndSettle();

      final painter = painterOf(tester);
      expect(painter.bandWidthFactor, 1);
      expect(painter.bandStops, [0, 0.5, 1]);
      expect(painter.bandOffsetFactor, 0);
    });

    testWidgets('reduced motion holds the pulse fully opaque', (tester) async {
      await pump(
        tester,
        const FluentSkeleton(
          key: key,
          animation: FluentSkeletonAnimation.pulse,
          width: 132,
          height: 132,
        ),
        reducedMotion: true,
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FadeTransition>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(FadeTransition),
              ),
            )
            .opacity
            .value,
        1.0,
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
        FluentSkeletonTheme(
          style: FluentSkeletonStyle.from(backgroundColor: themed),
          child: FluentSkeleton(
            key: key,
            style: FluentSkeletonStyle.from(backgroundColor: explicit),
            animation: FluentSkeletonAnimation.none,
            width: 132,
            height: 132,
          ),
        ),
      );
      expect(painterOf(tester).backgroundColor, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentSkeletonTheme(
          style: FluentSkeletonStyle.from(backgroundColor: themed),
          child: const FluentSkeleton(
            key: key,
            animation: FluentSkeletonAnimation.none,
            width: 132,
            height: 132,
          ),
        ),
      );
      expect(painterOf(tester).backgroundColor, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentSkeleton(
          key: key,
          animation: FluentSkeletonAnimation.none,
          style: FluentSkeletonStyle.from(
            borderRadius: FluentRadius.allCircular,
          ),
          width: 132,
          height: 132,
        ),
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      expect(painterOf(tester).borderRadius, FluentRadius.allCircular);
      expect(
        painterOf(tester).backgroundColor,
        theme.colors.neutralStencil1,
        reason: 'overriding radius must not drop the stencil fill',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentSkeletonBaseState(
        animation: FluentSkeletonAnimation.none,
      );
      const mine = Color(0xFF00FF00);
      const highlight = Color(0xFF0000FF);

      await pump(
        tester,
        SizedBox(
          key: key,
          width: 132,
          height: 132,
          child: buildFluentSkeleton(
            base,
            FluentSkeletonStyle.from(
              backgroundColor: mine,
              waveColor: highlight,
              borderRadius: FluentRadius.allLarge,
            ),
            const <WidgetState>{},
          ),
        ),
      );
      expect(painterOf(tester).backgroundColor, mine);
      expect(painterOf(tester).waveColor, highlight);
      expect(painterOf(tester).borderRadius, FluentRadius.allLarge);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentSkeletonState(
        shape: FluentSkeletonShape.circle,
        animation: FluentSkeletonAnimation.none,
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final adjusted = resolveFluentSkeletonStyle(
        state,
        theme,
      ).merge(FluentSkeletonStyle.from(borderRadius: FluentRadius.allSmall));

      await pump(
        tester,
        SizedBox(
          key: key,
          width: 132,
          height: 132,
          child: buildFluentSkeleton(state, adjusted, const <WidgetState>{}),
        ),
      );
      expect(painterOf(tester).backgroundColor, theme.colors.neutralStencil1);
      expect(painterOf(tester).borderRadius, FluentRadius.allSmall);
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the skeleton', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: const FluentThemeOverride(
            colors: {FluentColorToken.neutralStencil1: magenta},
            child: Center(
              child: FluentSkeleton(
                key: key,
                animation: FluentSkeletonAnimation.none,
                width: 132,
                height: 132,
              ),
            ),
          ),
        ),
      );
      expect(painterOf(tester).backgroundColor, magenta);
    });

    testWidgets('high contrast paints an opaque surface', (tester) async {
      await pump(
        tester,
        const FluentSkeleton(
          key: key,
          animation: FluentSkeletonAnimation.none,
          width: 132,
          height: 132,
        ),
        theme: FluentThemeData.highContrast(
          fontPlatform: FluentFontPlatform.web,
        ),
      );
      final painter = painterOf(tester);
      // A skeleton has no border to lose, but it must not go invisible: high
      // contrast maps BOTH stencil tokens to canvasText, so the surface is
      // fully opaque and the band deliberately vanishes into it.
      expect(painter.backgroundColor.a, 1.0);
      expect(painter.waveColor!.a, 1.0);
      expect(
        painter.waveColor,
        painter.backgroundColor,
        reason: 'both stencils are canvasText in high contrast',
      );
    });
  });

  group('behaviour', () {
    testWidgets('it is decorative, not interactive', (tester) async {
      await pump(
        tester,
        const FluentSkeleton(
          key: key,
          animation: FluentSkeletonAnimation.none,
          width: 132,
          height: 132,
        ),
      );
      // Disabled is not applicable: a skeleton is a placeholder, never a
      // control, so it carries no interaction surface to disable.
      expect(find.byType(FluentInteractive), findsNothing);
      expect(tester.getSemantics(find.byKey(key)), matchesSemantics());
    });

    testWidgets('a semantic label is announced', (tester) async {
      await pump(
        tester,
        const FluentSkeleton(
          key: key,
          animation: FluentSkeletonAnimation.none,
          semanticLabel: 'Loading',
          width: 132,
          height: 132,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(label: 'Loading'),
      );
    });

    testWidgets('it fills the space when no size is given', (tester) async {
      await pump(
        tester,
        const SizedBox(
          width: 200,
          height: 40,
          child: FluentSkeleton(
            key: key,
            animation: FluentSkeletonAnimation.none,
          ),
        ),
      );
      expect(tester.getSize(find.byKey(key)), const Size(200, 40));
    });
  });
}
