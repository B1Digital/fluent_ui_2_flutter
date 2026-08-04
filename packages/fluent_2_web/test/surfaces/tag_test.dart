import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentTag` and `FluentInteractionTag` share a style, a geometry ramp and a
/// renderer, so they share a test file. The two Figma sets are asserted
/// separately because their token tables genuinely differ: the plain tag is
/// inert and only its dismiss glyph reacts, while the interaction tag ramps
/// everything and does it twice, once per half.
void main() {
  const key = Key('tag');
  const dismissKey = Key('dismiss');

  FluentThemeData light() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(
    WidgetTester tester,
    Widget tag, {
    FluentThemeData? theme,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? light(),
      home: Center(child: tag),
    ),
  );

  /// Every decorated surface under [of], outermost first. A plain tag has one;
  /// a dismissible interaction tag has two — primary, then dismiss.
  List<BoxDecoration> surfaces(WidgetTester tester, {Finder? of}) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: of ?? find.byKey(key),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .where((d) => d.borderRadius != null)
      .toList();

  BoxDecoration primaryOf(WidgetTester tester) => surfaces(tester).first;
  BoxDecoration dismissOf(WidgetTester tester) => surfaces(tester).last;

  /// The rule between the two halves: the square-cornered overlay when there is
  /// one, and otherwise the primary half's own right border — which is what an
  /// outline tag uses, its border and its divider being the same tone.
  BorderSide seamOf(WidgetTester tester) {
    final overlay = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.borderRadius == null && d.border != null);
    if (overlay.isNotEmpty) return (overlay.first.border! as Border).right;
    return (primaryOf(tester).border! as Border).right;
  }

  EdgeInsets paddingOf(WidgetTester tester) => tester
      .widgetList<Padding>(
        find.descendant(of: find.byKey(key), matching: find.byType(Padding)),
      )
      .first
      .padding
      .resolve(TextDirection.ltr);

  /// The colour the dismiss glyph actually painted with.
  Color glyphColor(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((p) => p.painter)
      .whereType<FluentTagDismissPainter>()
      .first
      .color;

  /// A mouse that lives for the whole test, so a loop can hover one variant and
  /// then move off it again. A per-call gesture would leave the pointer parked
  /// on the next variant and light it at rest.
  Future<TestGesture> mouse(WidgetTester tester) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    return gesture;
  }

  Future<void> hover(WidgetTester tester, Finder target) async {
    final gesture = await mouse(tester);
    await gesture.moveTo(tester.getCenter(target));
    await tester.pump();
  }

  /// Asserts a resolved colour against the fixture, alpha only when the token
  /// is fully transparent — Figma stores those as `#00FFFFFF` and core as
  /// transparent black, and only the alpha is observable.
  void expectFill(Color actual, Color expected, {required String reason}) {
    if (expected.a == 0) {
      expect(actual.a, 0, reason: reason);
    } else {
      expect(actual.toARGB32(), expected.toARGB32(), reason: reason);
    }
  }

  const sizeNames = {
    FluentTagSize.extraSmall: 'Extra small',
    FluentTagSize.small: 'Small',
    FluentTagSize.medium: 'Medium',
  };
  const appearanceNames = {
    FluentTagAppearance.filled: 'Filled',
    FluentTagAppearance.outline: 'Outline',
    FluentTagAppearance.brand: 'Brand',
  };

  group('FluentTag against Figma', () {
    final spec = loadSpec('tag');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 60);
      expect(spec.properties.keys, [
        'Style',
        'Size',
        'Layout',
        'State',
        'Selected',
      ]);
    });

    testWidgets('geometry matches every size', (tester) async {
      for (final size in FluentTagSize.values) {
        final variant = spec.variant({
          'Style': 'Filled',
          'Size': sizeNames[size]!,
          'Layout': '1 line',
          'State': 'Rest',
          'Selected': 'False',
        });
        final content = variant.part('Content');

        await pump(
          tester,
          FluentTag(key: key, size: size, child: const Text('Tag')),
        );

        expect(
          tester.getSize(find.byKey(key)).height,
          variant.size.height,
          reason: '${size.name}: height',
        );
        expect(
          paddingOf(tester).left,
          content.padding!.left,
          reason: '${size.name}: content inset',
        );
        expect(
          primaryOf(tester).borderRadius,
          variant.radius,
          reason: '${size.name}: radius',
        );

        final text = variant.part('Primary').text!;
        final style = resolvedTextStyleOf(tester, of: find.byKey(key));
        expect(style.fontSize, text.fontSize, reason: '${size.name}: fontSize');
        expect(
          style.height! * style.fontSize!,
          text.lineHeight,
          reason: '${size.name}: lineHeight',
        );
      }
    });

    testWidgets('the item gap and glyph size match every size', (tester) async {
      for (final size in FluentTagSize.values) {
        final variant = spec.variant({
          'Style': 'Filled',
          'Size': sizeNames[size]!,
          'Layout': '1 line',
          'State': 'Rest',
          'Selected': 'False',
        });
        await pump(
          tester,
          FluentTag(
            key: key,
            size: size,
            onDismiss: () {},
            child: const Text('Tag'),
          ),
        );
        final row = tester.widget<Row>(
          find.descendant(of: find.byKey(key), matching: find.byType(Row)),
        );
        expect(row.spacing, variant.part('Content').gap, reason: size.name);

        // Figma draws the glyph's INK at 0.67 of its box; the box is what the
        // component sizes, and 12 / 16 / 20 is React's dismiss ramp too.
        final ink = variant.part('Shape').size.width;
        final box = tester.getSize(find.byType(FluentTagDismissGlyph));
        expect(
          box.width * FluentTagDismissPainter.inkRatio,
          closeTo(ink, 1.5),
          reason: '${size.name}: glyph ink',
        );
      }
    });

    testWidgets('resting fill and label match every appearance', (
      tester,
    ) async {
      for (final entry in appearanceNames.entries) {
        final variant = spec.variant({
          'Style': entry.value,
          'Size': 'Medium',
          'Layout': '1 line',
          'State': 'Rest',
          'Selected': 'False',
        });

        await pump(
          tester,
          FluentTag(key: key, appearance: entry.key, child: const Text('Tag')),
        );

        final fill = variant.fill;
        if (fill == null) {
          // Outline paints no fill at all in Figma; the port uses the
          // transparent token, which is the same pixel and survives a theme
          // that makes it opaque.
          expect(primaryOf(tester).color!.a, 0, reason: entry.value);
        } else {
          expectFill(
            primaryOf(tester).color!,
            fill,
            reason: '${entry.value}: fill',
          );
        }
        expectFill(
          resolvedTextStyleOf(tester, of: find.byKey(key)).color!,
          variant.part('Primary').fill!,
          reason: '${entry.value}: label',
        );
      }
    });

    testWidgets('selected erases the appearance in all three styles', (
      tester,
    ) async {
      for (final entry in appearanceNames.entries) {
        final variant = spec.variant({
          'Style': entry.value,
          'Size': 'Medium',
          'Layout': '1 line',
          'State': 'Rest',
          'Selected': 'True',
        });
        await pump(
          tester,
          FluentTag(
            key: key,
            appearance: entry.key,
            selected: true,
            child: const Text('Tag'),
          ),
        );
        expectFill(
          primaryOf(tester).color!,
          variant.fill!,
          reason: '${entry.value} selected: fill',
        );
        expectFill(
          resolvedTextStyleOf(tester, of: find.byKey(key)).color!,
          variant.part('Primary').fill!,
          reason: '${entry.value} selected: label',
        );
      }
      expect(
        spec
            .where({'State': 'Rest', 'Selected': 'True', 'Size': 'Medium'})
            .map((v) => v.fill!.toARGB32())
            .toSet()
            .length,
        1,
        reason: 'Figma binds one brand fill across all three styles',
      );
    });

    testWidgets('the two-line medium layout steps both lines down', (
      tester,
    ) async {
      final variant = spec.variant({
        'Style': 'Filled',
        'Size': 'Medium',
        'Layout': '2 line (Medium only)',
        'State': 'Rest',
        'Selected': 'False',
      });

      await pump(
        tester,
        const FluentTag(
          key: key,
          secondaryChild: Text('second'),
          child: Text('Tag'),
        ),
      );

      final texts = tester
          .widgetList<RichText>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(RichText),
            ),
          )
          .toList();
      expect(texts.length, 2);
      expect(
        texts.first.text.style!.fontSize,
        variant.part('Primary').text!.fontSize,
        reason: 'the primary drops to caption1 when a second line is present',
      );
      expect(
        texts.last.text.style!.fontSize,
        variant.part('Secondary').text!.fontSize,
      );
      expect(
        texts.last.text.style!.height! * texts.last.text.style!.fontSize!,
        variant.part('Secondary').text!.lineHeight,
      );
      expect(tester.getSize(find.byKey(key)).height, variant.size.height);
    });

    testWidgets('the surface is inert — only the dismiss glyph reacts', (
      tester,
    ) async {
      // All 45 unselected Figma variants bind the same fill in Rest, Hover and
      // Pressed. The State axis describes hovering the DISMISS glyph, which is
      // the only thing that moves.
      for (final style in appearanceNames.values) {
        final fills = ['Rest', 'Hover', 'Pressed']
            .map(
              (state) => spec
                  .variant({
                    'Style': style,
                    'Size': 'Medium',
                    'Layout': '1 line',
                    'State': state,
                    'Selected': 'False',
                  })
                  .tokens['fills']
                  ?.first,
            )
            .toSet();
        expect(fills.length, 1, reason: '$style: fill token across states');
      }

      var dismissed = 0;
      await pump(
        tester,
        FluentTag(
          key: key,
          onDismiss: () => dismissed++,
          child: const Text('Tag'),
        ),
      );
      final rest = primaryOf(tester).color;
      final restGlyph = glyphColor(tester);

      await hover(tester, find.byType(FluentTagDismissGlyph));
      expect(primaryOf(tester).color, rest, reason: 'the surface holds still');
      expect(
        glyphColor(tester),
        isNot(restGlyph),
        reason: 'the glyph takes brand colour',
      );
      expect(glyphColor(tester), light().colors.neutralForeground2BrandHover);
      expect(dismissed, 0);
    });

    testWidgets('the dismiss glyph ramp matches Figma per appearance', (
      tester,
    ) async {
      for (final entry in appearanceNames.entries) {
        for (final state in ['Rest', 'Hover', 'Pressed']) {
          final variant = spec.variant({
            'Style': entry.value,
            'Size': 'Medium',
            'Layout': '1 line',
            'State': state,
            'Selected': 'False',
          });
          final states = <WidgetState>{
            if (state == 'Hover') WidgetState.hovered,
            if (state == 'Pressed') WidgetState.pressed,
          };
          final resolved = resolveFluentTagStyle(
            resolveFluentTagState(appearance: entry.key),
            light(),
          );
          expectFill(
            resolved.dismissForegroundColor!.resolve(states)!,
            variant.part('Shape').fill!,
            reason: '${entry.value} $state: glyph',
          );
        }
      }
    });

    testWidgets('disabled is a real state, not a treatment', (tester) async {
      final variant = spec.variant({
        'Style': 'Filled',
        'Size': 'Medium',
        'Layout': '1 line',
        'State': 'Disabled',
        'Selected': 'False',
      });
      var dismissed = 0;
      await pump(
        tester,
        FluentTag(
          key: key,
          enabled: false,
          onDismiss: () => dismissed++,
          child: const Text('Tag'),
        ),
      );

      expectFill(primaryOf(tester).color!, variant.fill!, reason: 'fill');
      expectFill(
        glyphColor(tester),
        variant.part('Shape').fill!,
        reason: 'glyph',
      );

      await tester.tap(find.byType(FluentTagDismissGlyph), warnIfMissed: false);
      await tester.pump();
      expect(dismissed, 0, reason: 'a disabled tag cannot be dismissed');

      await hover(tester, find.byKey(key));
      expectFill(
        glyphColor(tester),
        variant.part('Shape').fill!,
        reason: 'and it does not report hover either',
      );
    });
  });

  group('FluentInteractionTag against Figma', () {
    final spec = loadSpec('interaction_tag');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 168);
      expect(spec.properties.keys, [
        'Style',
        'Size',
        'Layout',
        'State',
        'Selected',
        'Dismiss',
      ]);
    });

    testWidgets('the primary surface ramps through every state', (
      tester,
    ) async {
      final pointer = await mouse(tester);
      for (final entry in appearanceNames.entries) {
        for (final state in ['Rest', 'Hover', 'Pressed']) {
          final variant = spec.variant({
            'Style': entry.value,
            'Size': 'Medium',
            'Layout': '1 line',
            'State': state,
            'Selected': 'False',
            'Dismiss': 'False',
          });

          await pump(
            tester,
            FluentInteractionTag(
              key: key,
              appearance: entry.key,
              onPressed: () {},
              child: const Text('Tag'),
            ),
          );
          await pointer.moveTo(
            state == 'Rest' ? Offset.zero : tester.getCenter(find.byKey(key)),
          );
          await tester.pump();
          TestGesture? press;
          if (state == 'Pressed') {
            press = await tester.startGesture(
              tester.getCenter(find.byKey(key)),
            );
            await tester.pump();
          }

          expectFill(
            primaryOf(tester).color!,
            variant.fill!,
            reason: '${entry.value} $state: fill',
          );
          expectFill(
            resolvedTextStyleOf(tester, of: find.byKey(key)).color!,
            variant.part('Primary').fill!,
            reason: '${entry.value} $state: label',
          );
          await press?.up();
          await tester.pump();
        }
      }
    });

    testWidgets('selected ramps on the brand fill in all three styles', (
      tester,
    ) async {
      final pointer = await mouse(tester);
      for (final entry in appearanceNames.entries) {
        for (final state in ['Rest', 'Hover']) {
          final variant = spec.variant({
            'Style': entry.value,
            'Size': 'Medium',
            'Layout': '1 line',
            'State': state,
            'Selected': 'True',
            'Dismiss': 'False',
          });
          await pump(
            tester,
            FluentInteractionTag(
              key: key,
              appearance: entry.key,
              selected: true,
              onPressed: () {},
              child: const Text('Tag'),
            ),
          );
          await pointer.moveTo(
            state == 'Rest' ? Offset.zero : tester.getCenter(find.byKey(key)),
          );
          await tester.pump();
          expectFill(
            primaryOf(tester).color!,
            variant.fill!,
            reason: '${entry.value} selected $state',
          );
        }
      }
    });

    testWidgets('the divider takes its own token per appearance', (
      tester,
    ) async {
      for (final entry in appearanceNames.entries) {
        final variant = spec.variant({
          'Style': entry.value,
          'Size': 'Medium',
          'Layout': '1 line',
          'State': 'Rest',
          'Selected': 'False',
          'Dismiss': 'True',
        });

        await pump(
          tester,
          FluentInteractionTag(
            key: key,
            appearance: entry.key,
            onPressed: () {},
            onDismiss: () {},
            child: const Text('Tag'),
          ),
        );

        expectFill(
          seamOf(tester).color,
          variant.part('Primary action').stroke!,
          reason: '${entry.value}: divider',
        );
        expect(
          seamOf(tester).width,
          FluentStroke.thin,
          reason: '${entry.value}: divider width',
        );
        expect(
          primaryOf(tester).borderRadius,
          BorderRadius.only(
            topLeft: variant.radius.topLeft,
            bottomLeft: variant.radius.bottomLeft,
          ),
          reason: '${entry.value}: the primary half rounds one end only',
        );
      }
    });

    testWidgets('the dismiss half is sized and shaped from Figma', (
      tester,
    ) async {
      for (final size in FluentTagSize.values) {
        final variant = spec.variant({
          'Style': 'Filled',
          'Size': sizeNames[size]!,
          'Layout': '1 line',
          'State': 'Rest',
          'Selected': 'False',
          'Dismiss': 'True',
        });
        final expected = variant.part('Secondary action');

        await pump(
          tester,
          FluentInteractionTag(
            key: key,
            size: size,
            onPressed: () {},
            onDismiss: () {},
            child: const Text('Tag'),
          ),
        );

        final actual = tester.getSize(
          find
              .descendant(
                of: find.byKey(key),
                matching: find.byType(ConstrainedBox),
              )
              .last,
        );
        expect(
          actual.width,
          expected.size.width,
          reason: '${size.name}: width',
        );
        expect(
          actual.height,
          expected.size.height,
          reason: '${size.name}: height',
        );
        expect(
          dismissOf(tester).borderRadius,
          BorderRadius.only(
            topRight: variant.radius.topRight,
            bottomRight: variant.radius.bottomRight,
          ),
          reason: '${size.name}: the dismiss half rounds the other end',
        );
        expect(
          (dismissOf(tester).border! as Border).left.color.a,
          0,
          reason:
              'the dismiss half sits under the seam, so its own left border '
              'must be the transparent token and never a second rule',
        );
      }
    });

    testWidgets('the two halves hover independently', (tester) async {
      final rest = spec.variant({
        'Style': 'Filled',
        'Size': 'Medium',
        'Layout': '1 line',
        'State': 'Rest',
        'Selected': 'False',
        'Dismiss': 'True',
      });
      final hovered = spec.variant({
        'Style': 'Filled',
        'Size': 'Medium',
        'Layout': '1 line',
        'State': 'Hover',
        'Selected': 'False',
        'Dismiss': 'True',
      });

      await pump(
        tester,
        FluentInteractionTag(
          key: key,
          onPressed: () {},
          onDismiss: () {},
          child: const Text('Tag'),
        ),
      );
      await hover(tester, find.text('Tag'));

      expectFill(
        primaryOf(tester).color!,
        hovered.part('Primary action').fill!,
        reason: 'the hovered half',
      );
      expectFill(
        dismissOf(tester).color!,
        // Figma holds the dismiss half at its REST fill while the primary
        // hovers, which is the whole point of two surfaces.
        hovered.part('Secondary action').fill!,
        reason: 'the other half',
      );
      expect(
        hovered.part('Secondary action').fill!.toARGB32(),
        rest.part('Secondary action').fill!.toARGB32(),
      );
    });

    testWidgets('the two-line layout keeps the same height and dismiss half', (
      tester,
    ) async {
      final variant = spec.variant({
        'Style': 'Filled',
        'Size': 'Medium',
        'Layout': '2 line (Medium only)',
        'State': 'Rest',
        'Selected': 'False',
        'Dismiss': 'True',
      });
      // The dismissible frame nests one level deeper, so its text nodes fall
      // below the extractor's part depth; the type ramp is read off the
      // non-dismissible twin, which is the same two lines.
      final ramp = spec.variant({
        'Style': 'Filled',
        'Size': 'Medium',
        'Layout': '2 line (Medium only)',
        'State': 'Rest',
        'Selected': 'False',
        'Dismiss': 'False',
      });

      await pump(
        tester,
        FluentInteractionTag(
          key: key,
          secondaryChild: const Text('second'),
          onPressed: () {},
          onDismiss: () {},
          child: const Text('Tag'),
        ),
      );

      expect(tester.getSize(find.byKey(key)).height, variant.size.height);
      final texts = tester
          .widgetList<RichText>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(RichText),
            ),
          )
          .toList();
      expect(texts.length, 2);
      expect(
        texts.first.text.style!.fontSize,
        ramp.part('Primary').text!.fontSize,
      );
      expect(
        texts.last.text.style!.fontSize,
        ramp.part('Secondary').text!.fontSize,
      );
      expect(
        dismissOf(tester).borderRadius,
        BorderRadius.only(
          topRight: variant.radius.topRight,
          bottomRight: variant.radius.bottomRight,
        ),
      );
    });

    testWidgets('the outline border ramps and stays visible', (tester) async {
      final pointer = await mouse(tester);
      for (final state in ['Rest', 'Hover']) {
        final variant = spec.variant({
          'Style': 'Outline',
          'Size': 'Medium',
          'Layout': '1 line',
          'State': state,
          'Selected': 'False',
          'Dismiss': 'False',
        });
        await pump(
          tester,
          FluentInteractionTag(
            key: key,
            appearance: FluentTagAppearance.outline,
            onPressed: () {},
            child: const Text('Tag'),
          ),
        );
        await pointer.moveTo(
          state == 'Rest' ? Offset.zero : tester.getCenter(find.byKey(key)),
        );
        await tester.pump();
        expectFill(
          (primaryOf(tester).border! as Border).top.color,
          variant.stroke!,
          reason: 'outline $state',
        );
      }
    });
  });

  group('motion', () {
    testWidgets('the fill changes on the frame the pointer arrives', (
      tester,
    ) async {
      // Upstream declares NO transition in useTagStyles.styles.ts,
      // useInteractionTagPrimaryStyles.styles.ts or
      // useInteractionTagSecondaryStyles.styles.ts. Nothing tweens.
      await pump(
        tester,
        FluentInteractionTag(
          key: key,
          onPressed: () {},
          child: const Text('Tag'),
        ),
      );
      final rest = primaryOf(tester).color;

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pump();

      expect(
        primaryOf(tester).color,
        light().colors.neutralBackground3Hover,
        reason: 'the hover fill lands whole on the first frame',
      );
      expect(primaryOf(tester).color, isNot(rest));
    });

    testWidgets('reduced motion changes nothing, because nothing animated', (
      tester,
    ) async {
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: child!,
          ),
          home: Center(
            child: FluentInteractionTag(
              key: key,
              onPressed: () {},
              child: const Text('Tag'),
            ),
          ),
        ),
      );
      await hover(tester, find.byKey(key));
      expect(primaryOf(tester).color, light().colors.neutralBackground3Hover);
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
        FluentTagTheme(
          style: FluentTagStyle.from(backgroundColor: themed),
          child: FluentTag(
            key: key,
            style: FluentTagStyle.from(backgroundColor: explicit),
            child: const Text('Tag'),
          ),
        ),
      );
      expect(primaryOf(tester).color, explicit);
    });

    testWidgets('the subtree theme reaches the tag', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentTagTheme(
          style: FluentTagStyle.from(backgroundColor: themed),
          child: const FluentTag(key: key, child: Text('Tag')),
        ),
      );
      expect(primaryOf(tester).color, themed);
    });

    testWidgets('the interaction tag has its own subtree theme', (
      tester,
    ) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentInteractionTagTheme(
          style: FluentTagStyle.from(backgroundColor: themed),
          child: FluentInteractionTag(
            key: key,
            onPressed: () {},
            child: const Text('Tag'),
          ),
        ),
      );
      expect(primaryOf(tester).color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentTag(
          key: key,
          appearance: FluentTagAppearance.brand,
          style: FluentTagStyle.from(borderRadius: FluentRadius.allCircular),
          child: const Text('Tag'),
        ),
      );
      expect(primaryOf(tester).borderRadius, FluentRadius.allCircular);
      expect(
        primaryOf(tester).color,
        light().colors.brandBackground2,
        reason: 'overriding the radius must not drop the brand fill',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentTagBaseState(enabled: true, label: Text('Tag'));
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentTag(
            base,
            FluentTagStyle.from(
              backgroundColor: mine,
              borderRadius: FluentRadius.allLarge,
            ),
            const <WidgetState>{},
          ),
        ),
      );
      expect(primaryOf(tester).color, mine);
      expect(primaryOf(tester).borderRadius, FluentRadius.allLarge);
    });

    testWidgets('the interaction tag renderer takes the same base state', (
      tester,
    ) async {
      const base = FluentInteractionTagBaseState(
        enabled: true,
        dismissible: true,
        label: Text('Tag'),
      );
      final style = resolveFluentInteractionTagStyle(
        resolveFluentInteractionTagState(dismissible: true),
        light(),
      ).merge(FluentTagStyle.from(borderRadius: FluentRadius.allCircular));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentInteractionTag(base, style, const <WidgetState>{}),
        ),
      );
      expect(
        primaryOf(tester).borderRadius,
        const BorderRadius.only(
          topLeft: FluentRadius.circular,
          bottomLeft: FluentRadius.circular,
        ),
      );
      expect(primaryOf(tester).color, light().colors.neutralBackground3);
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches both components', (
      tester,
    ) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.brandBackground: magenta},
            child: Center(
              child: FluentInteractionTag(
                key: key,
                selected: true,
                onPressed: () {},
                child: const Text('Tag'),
              ),
            ),
          ),
        ),
      );
      expect(primaryOf(tester).color, magenta);
    });

    testWidgets('high contrast leaves no invisible border', (tester) async {
      final hc = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      for (final appearance in FluentTagAppearance.values) {
        await pump(
          tester,
          FluentInteractionTag(
            key: key,
            appearance: appearance,
            onPressed: () {},
            onDismiss: () {},
            child: const Text('Tag'),
          ),
          theme: hc,
        );
        // transparentStrokeInteractive turns opaque in high contrast, so the
        // border that is invisible in light is the only thing outlining a
        // filled tag here.
        for (final surface in [primaryOf(tester), dismissOf(tester)]) {
          final border = surface.border! as Border;
          expect(border.top.color.a, 1.0, reason: '${appearance.name}: top');
          expect(
            border.right.color.a,
            1.0,
            reason: '${appearance.name}: right',
          );
        }
      }

      await pump(
        tester,
        const FluentTag(key: key, child: Text('Tag')),
        theme: hc,
      );
      expect((primaryOf(tester).border! as Border).top.color.a, 1.0);
    });
  });

  group('behaviour', () {
    testWidgets('the primary half fires on tap and on Enter', (tester) async {
      var taps = 0;
      final node = FocusNode();
      addTearDown(node.dispose);

      await pump(
        tester,
        FluentInteractionTag(
          key: key,
          focusNode: node,
          onPressed: () => taps++,
          child: const Text('Tag'),
        ),
      );

      await tester.tap(find.byKey(key));
      await tester.pump();
      expect(taps, 1);

      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 2, reason: 'keyboard activation must work');
    });

    testWidgets('a focused primary half keeps its band at the seam', (
      tester,
    ) async {
      // `useInteractionTagPrimaryStyles` gives the primary half
      // `createCustomFocusIndicatorStyle({ outline: 2px strokeFocus2,
      // zIndex: 1 })`, and the live control shows a solid 2px bar between the
      // label and the ×. Flutter's Row paints siblings in order, so the dismiss
      // half's opaque fill swallows an outward ring on that edge; the band is
      // drawn inside the primary's own box instead. Figma models the seam as a
      // border side rather than a focus indicator, so it neither backs nor
      // contradicts this — the divergence is paint order.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );

      bool hasSeamBand() => tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(DecoratedBox),
            ),
          )
          .where((d) => d.position == DecorationPosition.foreground)
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.border)
          .whereType<Border>()
          .any(
            (b) =>
                b.right.color == light().colors.strokeFocus2 &&
                b.right.width == FluentStroke.thick,
          );

      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentInteractionTag(
          key: key,
          focusNode: node,
          onPressed: () {},
          onDismiss: () {},
          child: const Text('Tag'),
        ),
      );

      expect(hasSeamBand(), isFalse, reason: 'unfocused');
      node.requestFocus();
      await tester.pump();
      expect(hasSeamBand(), isTrue, reason: 'focused');

      // A tag with no dismiss half has no seam to defend — its ring is the
      // ordinary outward one all the way round.
      await pump(
        tester,
        FluentInteractionTag(
          key: key,
          focusNode: node,
          onPressed: () {},
          child: const Text('Tag'),
        ),
      );
      node.requestFocus();
      await tester.pump();
      expect(hasSeamBand(), isFalse, reason: 'not dismissible');
    });

    testWidgets('the dismiss half fires on its own, not the primary', (
      tester,
    ) async {
      var taps = 0;
      var dismissed = 0;
      await pump(
        tester,
        FluentInteractionTag(
          key: key,
          onPressed: () => taps++,
          onDismiss: () => dismissed++,
          child: const KeyedSubtree(key: dismissKey, child: Text('Tag')),
        ),
      );

      await tester.tap(find.byType(FluentTagDismissGlyph));
      await tester.pump();
      expect(dismissed, 1);
      expect(taps, 0, reason: 'dismissing must not also activate the tag');

      await tester.tap(find.byKey(dismissKey));
      await tester.pump();
      expect(taps, 1);
      expect(dismissed, 1);
    });

    testWidgets('null onPressed disables it for real', (tester) async {
      var dismissed = 0;
      await pump(
        tester,
        FluentInteractionTag(
          key: key,
          onDismiss: () => dismissed++,
          child: const Text('Tag'),
        ),
      );
      expect(primaryOf(tester).color, light().colors.neutralBackgroundDisabled);

      await tester.tap(find.byType(FluentTagDismissGlyph), warnIfMissed: false);
      await tester.pump();
      expect(dismissed, 0, reason: 'the dismiss half goes with it');

      await hover(tester, find.byKey(key));
      expect(
        primaryOf(tester).color,
        light().colors.neutralBackgroundDisabled,
        reason: 'a disabled tag must not adopt the hover fill',
      );
    });

    testWidgets('semantics announce a selected, dismissible control', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        FluentInteractionTag(
          key: key,
          selected: true,
          onPressed: () {},
          onDismiss: () {},
          child: const Text('Design'),
        ),
      );

      // Read from the label, not the widget key: the dismissible tag's
      // outermost render object is the row, which carries no semantics of its
      // own — each half is announced separately, which is the point.
      expect(
        tester.getSemantics(find.text('Design')),
        matchesSemantics(
          label: 'Design',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(
        find.bySemanticsLabel('Dismiss'),
        findsOneWidget,
        reason: 'the dismiss half names itself, having no text',
      );
      handle.dispose();
    });

    testWidgets('a plain tag announces itself as selected, not as a button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const FluentTag(key: key, selected: true, child: Text('Design')),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'Design',
          isSelected: true,
          hasSelectedState: true,
          isEnabled: true,
          hasEnabledState: true,
        ),
      );
      handle.dispose();
    });
  });
}
