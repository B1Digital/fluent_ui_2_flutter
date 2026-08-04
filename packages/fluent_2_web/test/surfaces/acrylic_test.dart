import 'dart:ui' as ui;

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentAcrylicSurface` is a *material*, not a control: it has no interaction
/// states, no transition and no disabled treatment. These tests therefore prove
/// as much about what it must NOT do — animate, focus, absorb pointers, stay
/// translucent in high contrast — as about the numbers it must reproduce.
void main() {
  const key = Key('acrylic');

  Future<void> pump(
    WidgetTester tester,
    Widget surface, {
    FluentThemeData? theme,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(child: surface),
    ),
  );

  /// Every coloured [BoxDecoration] the surface paints, outermost first: the
  /// `Background/Secondary` tint, then `Background/Primary` stacked on it.
  List<BoxDecoration> tintsOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .where((d) => d.color != null)
      .toList();

  /// The hairline painter, whose inputs are public fields precisely so a test
  /// can read the three stops back instead of diffing pixels.
  FluentAcrylicStrokePainter strokeOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((p) => p.foregroundPainter)
      .whereType<FluentAcrylicStrokePainter>()
      .single;

  List<BackdropFilter> blursOf(WidgetTester tester) => tester
      .widgetList<BackdropFilter>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(BackdropFilter),
        ),
      )
      .toList();

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('acrylic');
    final variant = spec.variant(const {'Material': 'Acrylic'});

    test('the fixture covers the whole component set', () {
      // "Material acrylic" is a one-variant set: the material has no design
      // axes at all. Its light/dark split lives in the variable modes, which
      // the theme carries, not in a Figma variant.
      expect(spec.variants.length, 1);
      expect(spec.properties, {
        'Material': ['Acrylic'],
      });
    });

    test('the fixture names the tokens the resolver must select', () {
      expect(variant.tokens['fills'], [
        'Material/Acrylic/Background/Secondary',
        'Material/Acrylic/Background/Primary',
      ]);
      expect(variant.tokens['strokes'], [
        'Material/Acrylic/Stroke/Stop 2',
        'Material/Acrylic/Stroke/Stop 3',
        'Material/Acrylic/Stroke/Stop 1',
      ]);
      expect(variant.token('strokeWidth'), 'Stroke width/Thin');
      expect(variant.token('paddingLeft'), 'Spacing/Horizontal/L');
      expect(variant.token('radius'), 'material-radius');
    });

    testWidgets('geometry matches the extracted variant', (tester) async {
      await pump(
        tester,
        const FluentAcrylicSurface(key: key, child: SizedBox(width: 40)),
      );

      final padding = tester
          .widget<Padding>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(Padding),
            ),
          )
          .padding
          .resolve(TextDirection.ltr);
      expect(padding.left, variant.padding!.left);
      expect(padding.top, variant.padding!.top);
      expect(padding.right, variant.padding!.right);
      expect(padding.bottom, variant.padding!.bottom);

      // `material-radius` is a remote MaterialShape variable and the shipped
      // file resolves it to the None mode, so the default is square.
      expect(tintsOf(tester).first.borderRadius, variant.radius);
      expect(strokeOf(tester).strokeWidth, variant.strokeWidth);
      expect(strokeOf(tester).borderRadius, variant.radius);

      // Hugs its child plus the 16px inset on every side.
      expect(tester.getSize(find.byKey(key)).width, 40 + 32);
    });

    testWidgets('the two tints stack Secondary under Primary', (tester) async {
      await pump(tester, const FluentAcrylicSurface(key: key));
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final tints = tintsOf(tester);

      expect(tints.length, 2, reason: 'Figma paints two stacked fills');
      // Order is load-bearing: swapping them changes the composite. The fixture
      // records the sampled render that settles it.
      expect(tints[0].color, theme.colors.acrylic.backgroundSecondary);
      expect(tints[1].color, theme.colors.acrylic.backgroundPrimary);

      // Core against Figma, so a regenerated token table cannot drift silently.
      // Values from test/fixtures/acrylic.json → variants[0].material.fills.
      expect(tints[0].color, const Color(0xB2E7ECF3));
      expect(tints[1].color, const Color(0x80FFFFFF));
    });

    testWidgets('the hairline is the three acrylic stroke stops', (
      tester,
    ) async {
      await pump(tester, const FluentAcrylicSurface(key: key));
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final stroke = strokeOf(tester);

      expect(stroke.stop1, theme.colors.acrylic.strokeStop1);
      expect(stroke.stop2, theme.colors.acrylic.strokeStop2);
      expect(stroke.stop3, theme.colors.acrylic.strokeStop3);

      // Values from test/fixtures/acrylic.json → material.stroke.stops.
      expect(stroke.stop1, const Color(0x33FFFFFF));
      expect(stroke.stop2, const Color(0x33CFE4FA));
      expect(stroke.stop3, const Color(0x33FFFFFF));
    });

    testWidgets('backgroundBlur is a RADIUS, so the sigma is half it', (
      tester,
    ) async {
      // The whole point of this test. Figma stores `Material/Acrylic/
      // Background/Blur` = 60 as a CSS `filter: blur()` radius;
      // ImageFilter.blur takes a Gaussian sigma. Passing 60 straight through
      // doubles the blur and nobody notices until it is compared side by side.
      await pump(tester, const FluentAcrylicSurface(key: key));
      final filter = blursOf(tester).single.filter;

      expect(filter, ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30));
      expect(
        filter,
        isNot(ui.ImageFilter.blur(sigmaX: 60, sigmaY: 60)),
        reason: 'the radius must not be passed through as a sigma',
      );
    });

    testWidgets('the hairline gradient spans the whole surface', (
      tester,
    ) async {
      // Guards the shader matrix, which nothing else can catch: Figma evaluates
      // a linear gradient in the node's normalised box space, so the painter
      // hands `ui.Gradient.linear` unit-square endpoints and scales them onto
      // the surface. Drop that matrix and all three stops collapse into the
      // top-left pixel, leaving a flat border that still satisfies every colour
      // assertion above.
      //
      // Stops are swapped for primaries and the tints for opaque black so the
      // sampled pixels say which stop landed where. Figma's transform puts t=0
      // at the top-left corner and t=1 past the bottom-right, so the left edge
      // must travel from Stop 1 towards Stop 2 on the way down — matching the
      // 282x76 Figma render, which is lighter at (0,5) and bluer at (0,70).
      const boundary = Key('acrylic-raster');
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: Center(
            child: RepaintBoundary(
              key: boundary,
              child: SizedBox(
                width: 282,
                height: 76,
                child: FluentAcrylicSurface(
                  style: FluentAcrylicSurfaceStyle.from(
                    backgroundBlur: 0,
                    backgroundSecondary: const Color(0xFF000000),
                    backgroundPrimary: const Color(0x00000000),
                    strokeStop1: const Color(0xFFFF0000),
                    strokeStop2: const Color(0xFF00FF00),
                    strokeStop3: const Color(0xFF0000FF),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final pixels = (await tester.runAsync(() async {
        final render = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(boundary),
        );
        final image = await render.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data;
      }))!;
      int red(int x, int y) => pixels.getUint8((y * 282 + x) * 4);
      int green(int x, int y) => pixels.getUint8((y * 282 + x) * 4 + 1);

      expect(
        red(0, 5),
        greaterThan(green(0, 5)),
        reason: 'the top of the left edge is still Stop 1',
      );
      expect(
        green(0, 70),
        greaterThan(red(0, 70)),
        reason: 'the bottom of the left edge has travelled towards Stop 2',
      );
    });

    testWidgets('dark flips every acrylic token', (tester) async {
      final theme = FluentThemeData.dark(fontPlatform: FluentFontPlatform.web);
      await pump(tester, const FluentAcrylicSurface(key: key), theme: theme);

      expect(
        tintsOf(tester)[0].color,
        theme.colors.acrylic.backgroundSecondary,
      );
      expect(tintsOf(tester)[1].color, theme.colors.acrylic.backgroundPrimary);
      expect(strokeOf(tester).stop2, theme.colors.acrylic.strokeStop2);
      // The documented asymmetry: Stop 2 is fully opaque in dark while its two
      // siblings stay at 0x33. See doc/token-divergences.md.
      expect(strokeOf(tester).stop2!.a, 1.0);
      expect(strokeOf(tester).stop1!.a, lessThan(1.0));
    });
  });

  group('motion', () {
    testWidgets('a material has no transition, so the change is INSTANT', (
      tester,
    ) async {
      // Figma gives the acrylic material no transition and upstream ships no
      // acrylic component at all, so there is nothing to tween. This mirrors
      // Checkbox and Tooltip, which FluentMotionSpec also deliberately omits.
      await pump(tester, const FluentAcrylicSurface(key: key));
      expect(
        find.byType(FluentAnimatedStyle<Color>),
        findsNothing,
        reason: 'no animated style may sit in a material',
      );

      const mine = Color(0xFF123456);
      await pump(
        tester,
        FluentAcrylicSurface(
          key: key,
          style: FluentAcrylicSurfaceStyle.from(backgroundSecondary: mine),
        ),
      );
      await tester.pump();
      expect(
        tintsOf(tester)[0].color,
        mine,
        reason: 'the new tint must land on the first frame, not tween in',
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
        FluentAcrylicSurfaceTheme(
          style: FluentAcrylicSurfaceStyle.from(backgroundSecondary: themed),
          child: FluentAcrylicSurface(
            key: key,
            style: FluentAcrylicSurfaceStyle.from(
              backgroundSecondary: explicit,
            ),
          ),
        ),
      );
      expect(tintsOf(tester)[0].color, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentAcrylicSurfaceTheme(
          style: FluentAcrylicSurfaceStyle.from(backgroundSecondary: themed),
          child: const FluentAcrylicSurface(key: key),
        ),
      );
      expect(tintsOf(tester)[0].color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentAcrylicSurface(
          key: key,
          style: FluentAcrylicSurfaceStyle.from(
            borderRadius: FluentRadius.allXLarge,
          ),
        ),
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      expect(tintsOf(tester)[0].borderRadius, FluentRadius.allXLarge);
      expect(strokeOf(tester).borderRadius, FluentRadius.allXLarge);
      expect(
        tintsOf(tester)[0].color,
        theme.colors.acrylic.backgroundSecondary,
        reason: 'overriding the radius must not drop the tint',
      );
    });

    testWidgets('overriding the blur to zero drops the BackdropFilter', (
      tester,
    ) async {
      await pump(
        tester,
        FluentAcrylicSurface(
          key: key,
          style: FluentAcrylicSurfaceStyle.from(backgroundBlur: 0),
        ),
      );
      // A zero-sigma blur still forces a saveLayer, so it is skipped outright.
      expect(blursOf(tester), isEmpty);
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(ClipRRect)),
        findsOneWidget,
        reason: 'the corner clip survives; only the filter goes',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build takes a style, so styling can be substituted', (
      tester,
    ) async {
      const mine = Color(0xFF00FF00);
      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentAcrylicSurface(
            FluentAcrylicSurfaceStyle.from(
              backgroundSecondary: mine,
              backgroundBlur: 0,
              borderRadius: FluentRadius.allLarge,
            ),
            const <WidgetState>{},
          ),
        ),
      );
      expect(tintsOf(tester)[0].color, mine);
      expect(tintsOf(tester)[0].borderRadius, FluentRadius.allLarge);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final adjusted = resolveFluentAcrylicSurfaceStyle(theme).merge(
        FluentAcrylicSurfaceStyle.from(borderRadius: FluentRadius.allCircular),
      );

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentAcrylicSurface(adjusted, const <WidgetState>{}),
        ),
      );
      expect(
        tintsOf(tester)[0].color,
        theme.colors.acrylic.backgroundSecondary,
      );
      expect(tintsOf(tester)[0].borderRadius, FluentRadius.allCircular);
    });
  });

  group('theming', () {
    testWidgets('high contrast drops translucency and blur entirely', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentAcrylicSurface(key: key),
        theme: FluentThemeData.highContrast(
          fontPlatform: FluentFontPlatform.web,
        ),
      );
      const colors = FluentHighContrastColors();

      // A translucent, blurred surface is exactly what high contrast forbids —
      // and the raw acrylic tokens would be worse than useless here: the two
      // outer stroke stops are 0x33 black, i.e. invisible on the black canvas.
      expect(blursOf(tester), isEmpty, reason: 'no backdrop blur');
      final tints = tintsOf(tester);
      expect(tints[0].color, colors.neutralBackground1);
      expect(tints[0].color!.a, 1.0, reason: 'the surface must be opaque');
      expect(tints[1].color!.a, 0.0, reason: 'the second tint drops out');

      final stroke = strokeOf(tester);
      for (final stop in [stroke.stop1, stroke.stop2, stroke.stop3]) {
        expect(stop, colors.neutralStroke1);
        expect(stop!.a, 1.0, reason: 'no invisible border in high contrast');
      }
      expect(stroke.strokeWidth, greaterThan(0));
    });

    testWidgets('a subtree token override reaches the surface', (tester) async {
      // The acrylic material tokens have no FluentColorToken identity, so they
      // cannot be overridden. The tokens this surface DOES reach for by
      // identity are its high-contrast fallbacks, which is where an override
      // has to be provable.
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.highContrast(
            fontPlatform: FluentFontPlatform.web,
          ),
          home: const FluentThemeOverride(
            colors: {FluentColorToken.neutralStroke1: magenta},
            child: Center(child: FluentAcrylicSurface(key: key)),
          ),
        ),
      );
      expect(strokeOf(tester).stop1, magenta);
      expect(strokeOf(tester).stop2, magenta);
      expect(strokeOf(tester).stop3, magenta);
    });
  });

  group('behaviour', () {
    testWidgets('a material is not interactive, so there is no disabled', (
      tester,
    ) async {
      var taps = 0;
      await pump(
        tester,
        FluentAcrylicSurface(
          key: key,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      );

      // No interaction surface of its own: no hover, press, focus or disabled
      // state exists to model, so the widget takes no onPressed and adds no
      // focus node. Content underneath still gets the pointer.
      expect(find.byType(FluentInteractive), findsNothing);
      expect(find.byType(FocusableActionDetector), findsNothing);

      await tester.tap(find.byType(GestureDetector).last);
      await tester.pump();
      expect(taps, 1, reason: 'the surface must not swallow taps');
    });

    testWidgets('the child paints above both tints', (tester) async {
      await pump(
        tester,
        const FluentAcrylicSurface(key: key, child: Text('Acrylic')),
      );
      expect(find.text('Acrylic'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DecoratedBox).last,
          matching: find.text('Acrylic'),
        ),
        findsOneWidget,
      );
    });
  });
}
