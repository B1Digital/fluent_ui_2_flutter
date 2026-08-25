import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentButton` is the reference implementation every other component copies.
/// These tests therefore cover the *contract*, not just the button: the
/// three-rung style resolution, the three-function recomposition split, and
/// pixel fidelity against the Figma extraction.
void main() {
  const key = Key('button');

  Future<void> pump(
    WidgetTester tester,
    Widget button, {
    FluentThemeData? theme,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(child: button),
    ),
  );

  /// The button's own decorated surface, skipping the focus ring's CustomPaint.
  BoxDecoration decorationOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .firstWhere((d) => d.borderRadius != null);

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('button');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 150);
    });

    testWidgets('geometry matches every size', (tester) async {
      for (final size in FluentButtonSize.values) {
        final variant = spec.variant({
          'Style': 'Primary',
          'State': 'Rest',
          'Size': switch (size) {
            FluentButtonSize.small => 'Small',
            FluentButtonSize.medium => 'Medium',
            FluentButtonSize.large => 'Large',
          },
          'Layout': 'Icon and label',
        });

        await pump(
          tester,
          FluentButton(
            key: key,
            appearance: FluentButtonAppearance.primary,
            size: size,
            icon: const SizedBox(width: 20, height: 20),
            onPressed: () {},
            child: const Text('Button'),
          ),
        );

        final padding = tester
            .widgetList<Padding>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(Padding),
              ),
            )
            .first
            .padding
            .resolve(TextDirection.ltr);

        expect(
          padding.left,
          variant.padding!.left,
          reason: '${size.name}: padding.left',
        );
        expect(
          padding.top,
          variant.padding!.top,
          reason: '${size.name}: padding.top',
        );
        expect(
          decorationOf(tester).borderRadius,
          variant.radius,
          reason: '${size.name}: radius',
        );
        expect(
          tester.getSize(find.byKey(key)).height,
          variant.size.height,
          reason: '${size.name}: height',
        );
      }
    });

    testWidgets('resting fill matches every appearance', (tester) async {
      const names = {
        FluentButtonAppearance.primary: 'Primary',
        FluentButtonAppearance.secondary: 'Secondary',
        FluentButtonAppearance.outline: 'Outline',
        FluentButtonAppearance.subtle: 'Subtle',
        FluentButtonAppearance.transparent: 'Transparent',
      };

      for (final entry in names.entries) {
        final variant = spec.variant({
          'Style': entry.value,
          'State': 'Rest',
          'Size': 'Medium',
          'Layout': 'Icon and label',
        });

        await pump(
          tester,
          FluentButton(
            key: key,
            appearance: entry.key,
            onPressed: () {},
            child: const Text('Button'),
          ),
        );
        await tester.pumpAndSettle();

        final resolved = decorationOf(tester).color!;
        final expected = variant.fill!;
        if (expected.a == 0) {
          // Figma cannot store a colour without an RGB triple, so it records
          // fully transparent tokens as #00FFFFFF. Upstream's TypeScript says
          // `colorTransparentBackground: 'transparent'`, and CSS `transparent`
          // IS rgba(0,0,0,0) — which is what core stores. Both are invisible;
          // only the alpha is observable, so only the alpha is asserted.
          expect(resolved.a, 0, reason: '${entry.value}: resting fill alpha');
        } else {
          expect(resolved, expected, reason: '${entry.value}: resting fill');
        }
      }
    });

    testWidgets('borders appear on exactly the bordered appearances', (
      tester,
    ) async {
      for (final appearance in FluentButtonAppearance.values) {
        await pump(
          tester,
          FluentButton(
            key: key,
            appearance: appearance,
            onPressed: () {},
            child: const Text('Button'),
          ),
        );
        final bordered =
            appearance == FluentButtonAppearance.secondary ||
            appearance == FluentButtonAppearance.outline;
        expect(
          decorationOf(tester).border != null,
          bordered,
          reason: '${appearance.name} border',
        );
      }
    });
  });

  // One number the Figma fixture cannot state, because its Large icon slot is
  // an instance rather than a token. It comes from
  // `react-button/library/src/components/Button/useButtonStyles.styles.ts` and
  // was confirmed against a live probe of the React storybook.
  group('geometry Figma cannot express', () {
    testWidgets('the width stays content-driven, against React\'s 96 floor', (
      tester,
    ) async {
      // DIVERGENCE, reported rather than followed. `useButtonStyles.styles.ts`
      // floors a labelled button at `minWidth: '96px'` (64 at small) and a live
      // probe renders a text-only Medium at exactly 96x32. Figma states no
      // floor, so the two do not strictly conflict — but React can only afford
      // 96 because its TeachingPopover surface is 320 wide. Figma's is 288, and
      // two floored buttons plus the carousel overflow it. The floor and that
      // width are one decision; until it is made, the width hugs the label.
      const reactFloors = <FluentButtonSize, double>{
        FluentButtonSize.small: 64,
        FluentButtonSize.medium: 96,
        FluentButtonSize.large: 96,
      };

      for (final entry in reactFloors.entries) {
        await pump(
          tester,
          FluentButton(
            key: key,
            size: entry.key,
            onPressed: () {},
            child: const Text('Go'),
          ),
        );
        expect(
          tester.getSize(find.byKey(key)).width,
          lessThan(entry.value),
          reason:
              '${entry.key.name}: a short label is not padded out to '
              'React\'s ${entry.value} floor',
        );
        expect(
          resolveFluentButtonStyle(
            resolveFluentButtonState(size: entry.key, label: const Text('Go')),
            FluentThemeData.light(),
          ).minimumSize!.resolve(const <WidgetState>{})!.width,
          0,
          reason: '${entry.key.name}: no width floor is declared',
        );
      }
    });

    testWidgets('an icon-only button is not floored at 96', (tester) async {
      // Guards the same decision from the other side: should the label floor
      // ever land, it must not reach an icon-only button. Upstream's
      // `useRootIconOnlyStyles` replaces the floor with `minWidth == maxWidth
      // == 24/32/40`, and the split button's chevron half is an icon-only
      // button that must stay 24 wide whatever happens to the label ramp.
      await pump(
        tester,
        FluentButton.icon(
          key: key,
          icon: const SizedBox(width: 20, height: 20),
          semanticLabel: 'Add',
          onPressed: () {},
        ),
      );
      expect(tester.getSize(find.byKey(key)).width, lessThan(96));
      expect(
        resolveFluentButtonStyle(
          resolveFluentButtonState(icon: const SizedBox()),
          FluentThemeData.light(),
        ).minimumSize!.resolve(const <WidgetState>{})!.width,
        0,
      );
    });

    testWidgets('the Large glyph is 24, not the 20 the other sizes take', (
      tester,
    ) async {
      // `useIconStyles`: base 20, `large { fontSize/height/width: '24px' }`.
      // Live probe of "Large with calendar icon": a 24x24 icon slot.
      const glyphs = <FluentButtonSize, double>{
        FluentButtonSize.small: FluentSize.size200,
        FluentButtonSize.medium: FluentSize.size200,
        FluentButtonSize.large: FluentSize.size240,
      };

      for (final entry in glyphs.entries) {
        expect(
          resolveFluentButtonStyle(
            resolveFluentButtonState(
              size: entry.key,
              icon: const SizedBox(),
              label: const Text('Button'),
            ),
            FluentThemeData.light(),
          ).iconSize!.resolve(const <WidgetState>{}),
          entry.value,
          reason: '${entry.key.name}: glyph',
        );
      }

      await pump(
        tester,
        FluentButton(
          key: key,
          size: FluentButtonSize.large,
          icon: const Icon(FluentIcons.add_20_regular),
          onPressed: () {},
          child: const Text('Button'),
        ),
      );
      expect(
        tester
            .widget<IconTheme>(
              find
                  .descendant(
                    of: find.byKey(key),
                    matching: find.byType(IconTheme),
                  )
                  .last,
            )
            .data
            .size,
        FluentSize.size240,
      );
    });
  });

  group('motion', () {
    testWidgets('the surface tweens on hover at 100ms easyEase', (
      tester,
    ) async {
      // Upstream: transitionProperty 'background, border, color',
      // durationFaster (100ms), curveEasyEase — useButtonStyles.styles.ts.
      await pump(
        tester,
        FluentButton(key: key, onPressed: () {}, child: const Text('B')),
      );
      await tester.pumpAndSettle();
      final rest = decorationOf(tester).color;

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        decorationOf(tester).color,
        isNot(rest),
        reason: 'must be mid-tween, not instant',
      );

      await tester.pumpAndSettle();
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      expect(decorationOf(tester).color, theme.colors.neutralBackground1Hover);
    });

    testWidgets('reduced motion applies the hover fill immediately', (
      tester,
    ) async {
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: child!,
          ),
          home: Center(
            child: FluentButton(
              key: key,
              onPressed: () {},
              child: const Text('B'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pump();
      await tester.pump();

      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      expect(decorationOf(tester).color, theme.colors.neutralBackground1Hover);
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
        FluentButtonTheme(
          style: FluentButtonStyle.from(backgroundColor: themed),
          child: FluentButton(
            key: key,
            style: FluentButtonStyle.from(backgroundColor: explicit),
            onPressed: () {},
            child: const Text('B'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(decorationOf(tester).color, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentButtonTheme(
          style: FluentButtonStyle.from(backgroundColor: themed),
          child: FluentButton(
            key: key,
            onPressed: () {},
            child: const Text('B'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(decorationOf(tester).color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentButton(
          key: key,
          appearance: FluentButtonAppearance.primary,
          style: FluentButtonStyle.from(borderRadius: FluentRadius.allCircular),
          onPressed: () {},
          child: const Text('B'),
        ),
      );
      await tester.pumpAndSettle();
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      expect(decorationOf(tester).borderRadius, FluentRadius.allCircular);
      expect(
        decorationOf(tester).color,
        theme.colors.brandBackground,
        reason: 'overriding radius must not drop the brand fill',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      // The point of typing buildFluentButton against FluentButtonBaseState:
      // Fluent's state and rendering, entirely custom styling, no fork.
      const base = FluentButtonBaseState(
        enabled: true,
        iconPosition: FluentButtonIconPosition.before,
        label: Text('B'),
      );
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentButton(
            base,
            FluentButtonStyle.from(
              backgroundColor: mine,
              borderRadius: FluentRadius.allLarge,
            ),
            const <WidgetState>{},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(decorationOf(tester).color, mine);
      expect(decorationOf(tester).borderRadius, FluentRadius.allLarge);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentButtonState(
        appearance: FluentButtonAppearance.primary,
        label: const Text('B'),
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final adjusted = resolveFluentButtonStyle(
        state,
        theme,
      ).merge(FluentButtonStyle.from(borderRadius: FluentRadius.allCircular));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentButton(state, adjusted, const <WidgetState>{}),
        ),
      );
      await tester.pumpAndSettle();
      expect(decorationOf(tester).color, theme.colors.brandBackground);
      expect(decorationOf(tester).borderRadius, FluentRadius.allCircular);
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the button', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.brandBackground: magenta},
            child: Center(
              child: FluentButton(
                key: key,
                appearance: FluentButtonAppearance.primary,
                onPressed: () {},
                child: const Text('B'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(decorationOf(tester).color, magenta);
    });

    testWidgets('high contrast resolves without transparent surfaces', (
      tester,
    ) async {
      await pump(
        tester,
        FluentButton(
          key: key,
          appearance: FluentButtonAppearance.outline,
          onPressed: () {},
          child: const Text('B'),
        ),
        theme: FluentThemeData.highContrast(
          fontPlatform: FluentFontPlatform.web,
        ),
      );
      await tester.pumpAndSettle();
      // transparentStroke becomes canvasText in high contrast, so a border that
      // is invisible in light must be visible here.
      expect(decorationOf(tester).border, isNotNull);
      expect(decorationOf(tester).border!.top.color.a, 1.0);
    });

    // The mirror of the test above, and the reason it is not redundant: the
    // very property that makes transparentStroke right for a BORDER in high
    // contrast — it turns opaque canvasText — makes it catastrophic as a FILL.
    // Using it for the disabled stop painted the button solid in the text
    // colour, so the label vanished into its own background. Nothing failed:
    // light and dark both resolve the two tokens to the same clear value, so
    // only high contrast can catch this.
    for (final appearance in <FluentButtonAppearance>[
      FluentButtonAppearance.outline,
      FluentButtonAppearance.transparent,
      FluentButtonAppearance.subtle,
    ]) {
      testWidgets(
        'high contrast keeps a disabled ${appearance.name} button unfilled',
        (tester) async {
          final theme = FluentThemeData.highContrast(
            fontPlatform: FluentFontPlatform.web,
          );
          await pump(
            tester,
            FluentButton(
              key: key,
              appearance: appearance,
              child: const Text('B'),
            ),
            theme: theme,
          );
          await tester.pumpAndSettle();
          final fill = decorationOf(tester).color;
          expect(
            fill?.a ?? 0.0,
            0.0,
            reason:
                '${appearance.name}: a disabled button paints no fill upstream; '
                'an opaque one here means a stroke token leaked into the '
                'background ramp',
          );
          expect(
            fill,
            isNot(theme.colors.neutralForegroundDisabled),
            reason: '${appearance.name}: the fill must not equal its own label',
          );
        },
      );
    }
  });

  group('behaviour', () {
    testWidgets('fires on tap and on Enter', (tester) async {
      var taps = 0;
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(
        tester,
        FluentButton(
          key: key,
          focusNode: node,
          onPressed: () => taps++,
          child: const Text('B'),
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

    testWidgets('null onPressed disables it for real', (tester) async {
      await pump(tester, const FluentButton(key: key, child: Text('B')));
      await tester.pumpAndSettle();
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      expect(
        decorationOf(tester).color,
        theme.colors.neutralBackgroundDisabled,
      );

      await tester.tap(find.byKey(key), warnIfMissed: false);
      await tester.pump();
      // No callback to assert, so assert the state instead: a disabled button
      // must not adopt the hover fill.
      expect(
        decorationOf(tester).color,
        theme.colors.neutralBackgroundDisabled,
      );
    });

    testWidgets('icon-only carries a semantic label', (tester) async {
      await pump(
        tester,
        FluentButton.icon(
          key: key,
          icon: const SizedBox(width: 20, height: 20),
          semanticLabel: 'Add item',
          onPressed: () {},
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'Add item',
          isButton: true,
          isEnabled: true,
          isFocusable: true,
          hasEnabledState: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
    });
  });
}
